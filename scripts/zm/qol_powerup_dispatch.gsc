// ============================================================================
//  qol_powerup_dispatch  -  Death Machine and Zombie Blood pickups (issue 13)
//
//  Stock powerup_grab() handles its own names in a switch and sends every
//  other name down level._zombiemode_powerup_grab (_zm_powerups.gsc:1071-1073,
//  the `default:` branch). "deathmachine" and, off Origins, "zombie_blood" only
//  ever work if that pointer reaches this mod.
//
//  The old install lived in quality_of_life.gsc's dm_onplayerspawned(): one
//  player's spawn thread claimed a level latch, waited 2 seconds and only then
//  wrote the pointer. That thread ends on its player's "disconnect", so a
//  disconnect inside the wait left the latch set and the hook never installed
//  for the rest of the match. It also wrote once: anything that assigned the
//  pointer afterwards removed the hook for good.
//
//  This module owns the pointer from init() instead:
//    - it installs immediately and re-asserts every half second, so a later
//      writer (a game mode postinit, a map script) cannot strand it;
//    - it chains to the handler it displaced, never to itself, so Origins'
//      ::tomb_powerup_grab and grief's ::meat_stink_powerup_grab still run;
//    - each power-up is dispatched once. A third-party wrapper that saved this
//      handler and chains back into it cannot loop, because the second entry
//      sees the mark the first one left on the power-up.
//
//  The Death Machine runtime moved here from quality_of_life.gsc as well,
//  which keeps that file under its compiled-bytecode ceiling. Registration,
//  the drop predicate, the damage callback and the state flags stay there.
// ============================================================================
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;

main()
{
}

init()
{
    zmqol_pd_hook();
    level thread zmqol_pd_hook_watch();
    level thread zmqol_pd_onplayerconnect();
}

// Returns 1 when it had to (re)install. The displaced handler becomes the
// chain target only when it is not this module's own handler.
zmqol_pd_hook()
{
    f_cur = level._zombiemode_powerup_grab;

    if ( isdefined( f_cur ) && f_cur == ::zmqol_pd_grab )
        return 0;

    level.zmqol_pd_next = f_cur;
    level._zombiemode_powerup_grab = ::zmqol_pd_grab;
    return 1;
}

zmqol_pd_hook_watch()
{
    level endon( "end_game" );

    for ( ;; )
    {
        wait 0.5;

        if ( zmqol_pd_hook() )
            println( "[zm_qol] power-up dispatch: level._zombiemode_powerup_grab was replaced - hook re-installed, previous handler chained" );

        //  v2.15.42 - per-player watcher re-arm. The watcher is armed from
        //  level "connected" only, and the A04 probe cycle (2026-10-07,
        //  modding-jobs\merge-a04-pipeline-001) measured that player entity
        //  fields reset and script threads die across an engine restart while
        //  init() re-runs - so a Death Machine picked up after a restart
        //  could lose its downed quiet-end: the switch watcher returns
        //  silently in last stand and can_revive() stays refusing until the
        //  holder bleeds out. Walk the players here and arm any that carry
        //  no marker. Safe under all three cases: fields persist (marker
        //  set, no re-arm), fields reset + threads die (marker cleared,
        //  re-arms), fields reset + threads survive (re-arms once; the end
        //  notify and the clear are idempotent).
        a_players = get_players();

        if ( !isdefined( a_players ) )
            continue;

        for ( i = 0; i < a_players.size; i++ )
        {
            if ( !isdefined( a_players[i] ) || isdefined( a_players[i].zmqol_pd_watching ) )
                continue;

            a_players[i].zmqol_pd_watching = 1;
            a_players[i] thread zmqol_pd_player_watch();
        }
    }
}

zmqol_pd_grab( s_powerup, e_player )
{
    str_name = undefined;

    if ( isdefined( s_powerup ) )
    {
        if ( isdefined( s_powerup.zmqol_pd_seen ) )
            return;

        s_powerup.zmqol_pd_seen = 1;
        str_name = s_powerup.powerup_name;
    }

    if ( isdefined( str_name ) && str_name == "deathmachine" )
    {
        level thread zmqol_dm_powerup( s_powerup, e_player );
        return;
    }

    // Origins registers Zombie Blood itself and zmqol_zombie_blood_enabled()
    // returns 0 there, so its own ::tomb_powerup_grab receives the name below.
    // Buried and Mob are excluded by the same gate for their clientfield budget.
    if ( isdefined( str_name ) && str_name == "zombie_blood" && scripts\zm\quality_of_life::zmqol_zombie_blood_enabled() )
    {
        level thread scripts\zm\quality_of_life::zmqol_zb_powerup( s_powerup, e_player );
        return;
    }

    f_next = level.zmqol_pd_next;

    if ( isdefined( f_next ) && f_next != ::zmqol_pd_grab )
        level thread [[ f_next ]]( s_powerup, e_player );
}

// ----------------------------------------------------------------------------
//  Per-player lifecycle. A spawn (first spawn, respawn after bleedout, a
//  restart) clears any leftover Death Machine state. Going down ends a running
//  Death Machine at once: stock's can_revive() refuses while has_powerup_weapon
//  is set, so a downed holder would otherwise block revives for the rest of
//  the timer, and the weapon-switch watcher would pull a primary out during
//  last stand.
// ----------------------------------------------------------------------------
zmqol_pd_onplayerconnect()
{
    level endon( "end_game" );

    for ( ;; )
    {
        level waittill( "connected", player );

        //  v2.15.42 - the marker check is shared with zmqol_pd_hook_watch()'s
        //  re-arm walk, so whichever path reaches the player first arms the
        //  watcher and the other is a no-op.
        if ( !isdefined( player.zmqol_pd_watching ) )
        {
            player.zmqol_pd_watching = 1;
            player thread zmqol_pd_player_watch();
        }
    }
}

zmqol_pd_player_watch()
{
    self endon( "disconnect" );
    level endon( "end_game" );

    //  "death" has to be in the list, not just handled. waittill_any_return()
    //  calls self endon( "death" ) unless "death" is one of its named events
    //  (common_scripts/utility.gsc:477-478 in the stock decompile), which
    //  would kill this thread permanently on the player's first death and
    //  leave every later spawn and down without its cleanup: a Death Machine
    //  picked up after that death would stay active through the holder's next
    //  last stand, and has_powerup_weapon would keep the holder from reviving
    //  anyone.
    for ( ;; )
    {
        str_event = self waittill_any_return( "spawned_player", "player_downed", "death" );

        if ( is_true( self.deathmachine_active ) )
        {
            self.zmqol_dm_quiet = 1;
            self notify( "end_deathmachine" );
        }

        if ( str_event == "spawned_player" )
            scripts\zm\quality_of_life::deathmachine_clear_powerup_state( self );
    }
}

// ----------------------------------------------------------------------------
//  Death Machine run
// ----------------------------------------------------------------------------
zmqol_dm_powerup( m_powerup, e_player )
{
    if ( !isdefined( e_player ) || !isplayer( e_player ) )
        return;

    if ( e_player maps\mp\zombies\_zm_laststand::player_is_in_laststand() )
        return;

    n_duration = getdvarintdefault( "sv_deathmachine_duration", 30 );
    level.deathmachine_duration = n_duration;

    // Played directly rather than through stock's leaderdialog queue; see
    // zmqol_play_announcer_line() in quality_of_life.gsc.
    level thread scripts\zm\quality_of_life::zmqol_play_announcer_line( "qol_powerup_death_machine" );

    // A second pickup while the gun is out extends the run, as stock's minigun
    // does. Restarting it would capture the Death Machine itself, or "none"
    // mid-switch, as the weapon to return to.
    if ( is_true( e_player.deathmachine_active ) && e_player hasweapon( scripts\zm\quality_of_life::get_deathmachine_weapon() ) )
    {
        e_player notify( "zmqol_dm_refresh" );
        e_player.zmqol_deathmachine_end_time = gettime() + ( n_duration * 1000 );
        e_player thread zmqol_dm_hud();
        e_player thread zmqol_dm_timer();
        return;
    }

    e_player notify( "end_deathmachine" );
    wait 0.05;

    if ( !isdefined( e_player ) || e_player maps\mp\zombies\_zm_laststand::player_is_in_laststand() )
        return;

    // The power-up timer HUD and zmqol_dm_timer() read this one end time, so
    // the countdown and the end of the run cannot drift apart.
    e_player.zmqol_deathmachine_end_time = gettime() + ( n_duration * 1000 );
    e_player thread zmqol_dm_hud();
    e_player thread zmqol_dm_start();
    e_player thread zmqol_dm_timer();
}

zmqol_dm_hud()
{
    if ( getdvarintdefault( "zmqol_minimal", 0 ) )
        return;

    level endon( "end_game" );
    self endon( "disconnect" );
    self endon( "end_deathmachine" );
    self endon( "zmqol_dm_refresh" );

    self setclientdvar( "deathmachine_powerup_state", 1 );

    while ( isdefined( self.zmqol_deathmachine_end_time ) && self.zmqol_deathmachine_end_time - gettime() > 10000 )
        wait 0.05;

    flash_on = 1;

    while ( isdefined( self.zmqol_deathmachine_end_time ) && self.zmqol_deathmachine_end_time > gettime() )
    {
        if ( flash_on )
            self setclientdvar( "deathmachine_powerup_state", 3 );
        else
            self setclientdvar( "deathmachine_powerup_state", 2 );

        flash_on = !flash_on;

        if ( self.zmqol_deathmachine_end_time - gettime() <= 5000 )
            wait 0.1;
        else
            wait 0.2;
    }
}

zmqol_dm_timer()
{
    level endon( "end_game" );
    self endon( "disconnect" );
    self endon( "end_deathmachine" );
    self endon( "zmqol_dm_refresh" );

    while ( isdefined( self.zmqol_deathmachine_end_time ) && self.zmqol_deathmachine_end_time > gettime() )
        wait 0.05;

    self playsound( "zmb_insta_kill" );
    self notify( "end_deathmachine" );
}

zmqol_dm_start()
{
    level endon( "end_game" );
    self endon( "disconnect" );
    self endon( "end_deathmachine" );

    weapon = scripts\zm\quality_of_life::get_deathmachine_weapon();
    self.zmqol_dm_quiet = undefined;
    self.weapon_before_deathmachine = self getcurrentweapon();
    self.deathmachine_had_weapon_before = self hasweapon( weapon );

    // The end handler is armed before the first wait, so an end_deathmachine
    // during the give below still takes the weapon and clears the state.
    self thread zmqol_dm_end();
    scripts\zm\quality_of_life::set_powerup_state( self );

    if ( !self.deathmachine_had_weapon_before )
    {
        self notify( "replace_weapon_powerup" );
        self giveweapon( weapon );
        wait 0.05;
    }

    self setweaponammoclip( weapon, 150 );
    self setweaponammostock( weapon, 300 );
    self switchtoweapon( weapon );
    self thread zmqol_dm_infinite_ammo( weapon );
    self thread zmqol_dm_switch_watch( weapon );
}

zmqol_dm_infinite_ammo( weapon )
{
    level endon( "end_game" );
    self endon( "disconnect" );
    self endon( "end_deathmachine" );

    for ( ;; )
    {
        if ( self hasweapon( weapon ) )
        {
            self setweaponammoclip( weapon, 150 );
            self setweaponammostock( weapon, 300 );
        }

        wait 0.05;
    }
}

// Switching away from the Death Machine ends the run. Last stand is left to
// zmqol_pd_player_watch(), which ends it without a weapon switch.
zmqol_dm_switch_watch( weapon )
{
    level endon( "end_game" );
    self endon( "disconnect" );
    self endon( "end_deathmachine" );

    while ( self getcurrentweapon() != weapon )
        wait 0.05;

    wait 0.1;

    for ( ;; )
    {
        if ( !self hasweapon( weapon ) )
            return;

        if ( self maps\mp\zombies\_zm_laststand::player_is_in_laststand() )
            return;

        if ( self getcurrentweapon() != weapon )
        {
            self notify( "end_deathmachine" );
            return;
        }

        wait 0.05;
    }
}

zmqol_dm_end()
{
    level endon( "end_game" );

    str_event = self waittill_any_return( "end_deathmachine", "disconnect", "death" );

    if ( str_event == "disconnect" || !isdefined( self ) )
        return;

    weapon = scripts\zm\quality_of_life::get_deathmachine_weapon();
    b_quiet = is_true( self.zmqol_dm_quiet ) || self maps\mp\zombies\_zm_laststand::player_is_in_laststand() || self.sessionstate != "playing";
    self.zmqol_dm_quiet = undefined;

    if ( !is_true( self.deathmachine_had_weapon_before ) )
    {
        if ( self hasweapon( weapon ) )
            self takeweapon( weapon );

        if ( !b_quiet )
            self zmqol_dm_switch_back( weapon );
    }
    else if ( !b_quiet && self getcurrentweapon() == weapon )
        self zmqol_dm_switch_back( weapon );

    scripts\zm\quality_of_life::deathmachine_clear_powerup_state( self );
    self.deathmachine_had_weapon_before = undefined;
    self.weapon_before_deathmachine = undefined;
}

zmqol_dm_switch_back( weapon )
{
    str_before = self.weapon_before_deathmachine;

    if ( isdefined( str_before ) && str_before != "none" && str_before != weapon && self hasweapon( str_before ) )
    {
        self switchtoweapon( str_before );
        return;
    }

    primaryweapons = self getweaponslistprimaries();

    for ( i = 0; i < primaryweapons.size; i++ )
    {
        if ( primaryweapons[i] != weapon )
        {
            self switchtoweapon( primaryweapons[i] );
            return;
        }
    }

    self maps\mp\zombies\_zm_weapons::give_fallback_weapon();
}
