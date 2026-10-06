// Round tracking is independent of the main script's bytecode budget.
#include common_scripts\utility;
#include maps\mp\_utility;

main() {}

init()
{
    cs_boot();
}

cs_boot()
{
    // One instance only
    if (isDefined(level.cs_loaded) && level.cs_loaded)
        return;
    level.cs_loaded = 1;

    // Try to disable the older "CRS" script if it was installed before
    setDvar("ct_round_summary", "0");
    setDvar("ct_rs_show_session_best", "0");
    setDvar("ct_rs_show_round_pb", "0");

    // Defaults
    if (getDvar("cs_enabled") == "") setDvar("cs_enabled", "1");
    if (getDvar("cs_x") == "") setDvar("cs_x", "0");
    if (getDvar("cs_y") == "") setDvar("cs_y", "-60");
    if (getDvar("cs_seconds") == "") setDvar("cs_seconds", "10");
    if (getDvar("cs_cooldown_ms") == "") setDvar("cs_cooldown_ms", "2500");

    level thread cs_on_connect();
}

cs_on_connect()
{
    level endon("end_game");
    for (;;)
    {
        level waittill("connected", player);

        player setClientDvar("zmqol_round_summary", "");

        // Best-effort: tell older scripts to stop their popup threads
        player notify("crs_summary_kill");
        player notify("cs_popup_kill");
        player notify("cs_popup_kill2");

        // Best-effort: destroy any old HUD elements the older scripts created
        player thread cs_kill_legacy_hud();
        player thread cs_player_thread();
    }
}

cs_kill_legacy_hud()
{
    self endon("disconnect");

    // Run a few times in case the old popup was mid-fade
    for (i = 0; i < 10; i++)
    {
        if (isDefined(self.crs_title)) self.crs_title destroy();
        if (isDefined(self.crs_line2)) self.crs_line2 destroy();
        if (isDefined(self.crs_line3)) self.crs_line3 destroy();
        if (isDefined(self.crs_line4)) self.crs_line4 destroy();
        if (isDefined(self.cs_title_old)) self.cs_title_old destroy();
        if (isDefined(self.cs_line2_old)) self.cs_line2_old destroy();
        if (isDefined(self.cs_line3_old)) self.cs_line3_old destroy();
        if (isDefined(self.cs_line4_old)) self.cs_line4_old destroy();
        if (isDefined(self.crs_summary)) self.crs_summary destroy();
        wait 0.1;
    }
}

cs_player_thread()
{
    self endon("disconnect");
    level endon("end_game");

    if (isDefined(self.cs_running) && self.cs_running)
        return;
    self.cs_running = 1;

    flag_wait("initial_blackscreen_passed");

    while (!isDefined(level.round_number))
        wait 0.1;

    self.cs_last_round = level.round_number;
    self.cs_round_start_time = getTime();
    self.cs_kills_start = cs_get_kills();

    // Prevent instant spam during early init
    self.cs_last_popup_time = getTime();

    for (;;)
    {
        if (!getDvarInt("cs_enabled"))
        {
            wait 0.5;
            continue;
        }

        r = level.round_number;
        if (r != self.cs_last_round && r > 1)
            cs_on_round_change(r);

        wait 0.2;
    }
}

cs_on_round_change(new_round)
{
    kills_now = cs_get_kills();
    completed_round = self.cs_last_round;
    round_time = int((getTime() - self.cs_round_start_time) / 1000);
    if (round_time < 0) round_time = 0;

    round_kills = kills_now - self.cs_kills_start;
    if (round_kills < 0) round_kills = 0;

    // Personal best per round (persist via seta)
    pb_time_key = "cs_personal_best_time_round_" + completed_round;
    pb_kills_key = "cs_personal_best_kills_round_" + completed_round;

    old_pb_time = getDvarInt(pb_time_key);
    old_pb_kills = getDvarInt(pb_kills_key);

    new_pb_time = 0;
    new_pb_kills = 0;

    if (round_time > 0 && (old_pb_time <= 0 || round_time < old_pb_time))
    {
        old_pb_time = round_time;
        setDvar(pb_time_key, round_time);
        cmdexec("seta " + pb_time_key + " " + round_time + "\n");
        new_pb_time = 1;
    }

    if (round_kills > old_pb_kills)
    {
        old_pb_kills = round_kills;
        setDvar(pb_kills_key, round_kills);
        cmdexec("seta " + pb_kills_key + " " + round_kills + "\n");
        new_pb_kills = 1;
    }

    // Cooldown to stop rapid re-trigger / flicker
    cooldown = getDvarInt("cs_cooldown_ms");
    if (cooldown < 500) cooldown = 500;
    if (cooldown > 10000) cooldown = 10000;

    now = getTime();
    if (isDefined(self.cs_last_popup_time) && (now - self.cs_last_popup_time) < cooldown)
    {
        self.cs_last_round = new_round;
        self.cs_round_start_time = getTime();
        self.cs_kills_start = kills_now;
        return;
    }

    self.cs_last_popup_time = now;

    //  v1.95.0 - `round_summary` console dvar / QUALITY OF LIFE menu row. User
    //  request, 2026-08-14: "add an option to toggle the brief pop-up after each
    //  completed wave/round that shows stats in the middle of the screen."
    //
    //  🛑 GATED AT THE POPUP, NOT AT THE TRACKER. Everything above this line
    //  still runs - round time, kill count and both personal bests are recorded
    //  and written to the profile exactly as before - so turning the popup off
    //  loses no history and turning it back on shows correct numbers straight
    //  away. The three bookkeeping writes below run either way for the same
    //  reason.
    if ( (getdvar("round_summary") == "" || getdvarint("round_summary")) )
    {
        self notify("cs_popup_kill3");
        self thread cs_popup(completed_round, round_time, round_kills, old_pb_time, old_pb_kills, new_pb_time, new_pb_kills);
    }

    self.cs_last_round = new_round;
    self.cs_round_start_time = getTime();
    self.cs_kills_start = kills_now;
}

cs_popup(round_num, round_time, round_kills, pb_time, pb_kills, new_pb_time, new_pb_kills)
{
    self endon("disconnect");
    level endon("end_game");
    self endon("cs_popup_kill3");

    // One reliable command per card. LUI text does not allocate server configstrings.
    x = cs_clamp(getDvarInt("cs_x"), -300, 300);
    y = cs_clamp(getDvarInt("cs_y"), -220, 160);
    show_for = cs_clamp(getDvarInt("cs_seconds"), 3, 30);
    payload = round_num + " " + round_time + " " + round_kills + " " + pb_time + " " + pb_kills + " " + new_pb_time + " " + new_pb_kills + " " + x + " " + y + " " + show_for;
    self setClientDvar("zmqol_round_summary", payload);
    wait show_for;
    self setClientDvar("zmqol_round_summary", "");
}

cs_get_kills()
{
    if (isDefined(self.kills)) return self.kills;
    if (isDefined(self.pers) && isDefined(self.pers["kills"])) return self.pers["kills"];
    return 0;
}

cs_clamp(v, mn, mx)
{
    if (v < mn) return mn;
    if (v > mx) return mx;
    return v;
}
