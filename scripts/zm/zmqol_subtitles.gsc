// ============================================================================
//  SUBTITLES  -  your character's spoken lines as text   (v2.14.16, v2.14.24)
// ----------------------------------------------------------------------------
//  User, 2026-09-08: *"add an option in the HUD tab for my mod called
//  SUBTITLES, this'll be quite a task since zombies never had subtitles for
//  player dialogue, so make sure to implement this option cleanly, and so that
//  it doesn't interfere with any other hud elements."*  And, when told the game
//  carries no text at all: *"do the speech to text route for subtitles."*
//
//  WHERE THE TEXT COMES FROM. Measured first: the English alias tables
//  (zone\english\en_<map>.ff, 2,334 dialogue rows on Green Run, 2,465 on
//  Buried) have an empty Subtitle column on every row, and no localize asset
//  carries dialogue. So the 10,722 character clips were pulled out of the
//  English sound banks by id and transcribed offline with Whisper large-v3
//  (the pipeline is `zm_qol - dev\subtitles\`). The result ships as one
//  stringtable per map, zm/zmqol_subs_<map>.csv, read here with tablelookup()
//  - the same route stock's own weapon tables take, and the one this mod
//  already uses for zm/pap_attach_qol.csv.
//
//  🛑 THE TEXT IS MACHINE-TRANSCRIBED. Names and zombies jargon were fed to
//  the model as a vocabulary prompt and a short correction list runs over the
//  output, but no line was checked by ear. A wrong word is a table row to
//  fix, not code.
//
//  HOW A LINE IS CAUGHT. _zm_audio::create_and_play_dialog() - the one road
//  every reactive quote takes (perks, kills, the box, doors, power-ups, the
//  bus, ...) - ends with
//        if ( isdefined( level._audio_custom_player_playvox ) )
//            self thread [[ level._audio_custom_player_playvox ]]( prefix, index, sound_to_play, waittime, category, type, override );
//        else
//            self thread do_player_or_npc_playvox( ..., isresponse );
//  (_zm_audio.gsc:521). That pointer is Treyarch's own hand-off, nothing in
//  the stock dump or this mod sets it, and it needs no replaceFunc to take
//  (STOCK_REFERENCE 7a's failure modes 1-4 do not apply to a level.* pointer
//  we set ourselves). zmqol_subs_playvox() threads stock's own player function
//  so the audio path is byte-for-byte what it was, then reads the state stock
//  leaves behind: do_player_or_npc_playvox() runs synchronously up to its
//  wait( playbacktime ), and by then it has either set self.isspeaking = 1
//  and self.speakingline = sound_to_play and called playsoundontag(), or
//  returned without playing (someone nearby is speaking, or this player
//  already is). So "is the line playing right now" is one field compare, no
//  race, no timer.
//
//  📝 The pointer drops stock's eighth argument, isresponse. It matters:
//  stock returns before the response-line logic when it is set, and without
//  it a hero/rival response could answer a response. The only caller that
//  ever passes a response is setup_hero_rival() (_zm_audio.gsc:658-661),
//  with the prefixes "hr_" and "riv_", and every response alias in the six
//  tables is vox_plr_N_hr_resp_* / vox_plr_N_riv_resp_*. So it is rebuilt
//  from the alias itself.
//
//  THE OTHER ROAD (v2.14.21): the quest lines that map scripts play straight
//  through playsoundwithnotify() / playsoundontag() / playsoundtoplayer() on
//  the player, never touching the dialogue system. Those are builtins on the
//  speaker entity with no generic hook, so the stock functions that make the
//  calls are replaced verbatim in scripts/zm/<map>/qol_subs_<map>.gsc with one
//  zmqol_subs_raw_line() beside each line - Origins (zm_tomb_vo, zm_tomb_giant_
//  robot), Mob (zm_alcatraz_sq, zm_alcatraz_sq_vo, zm_prison_sq_final) and
//  Buried (zm_buried_sq_bt). The old note here counted "3 on Origins"; the real
//  count is the whole round 5-7 Samantha intro plus the soul-box, beacon, drone
//  and robot-crush lines. Grunts and exerts (playerexert()) are not dialogue
//  and have no text.
//
//  WHO SEES IT. The speaker's own screen, and any team-mate close enough to
//  hear it - the alias tables put DistMaxDry at 1250 on five maps and 1600 on
//  Origins - with the character's name in front. Explicit vs clean take: the
//  engine picks the row by the "mature" sound context, which is
//  cg_allow_mature; the table carries both and the host's value picks the
//  column.
//
//  NUKETOWN is the exception to all of the above: its players are the CIA/CDC
//  pair, who never get a voice id (zm_nuked.gsc's character switch calls no
//  zmbvoxinitspeaker), so create_and_play_dialog() returns at its first
//  check and this hook never fires there. The map's only spoken lines are
//  Marlton's from inside the bunker, played by POSITION from
//  zm_nuked::marlton_vo_inside_bunker(); scripts/zm/zm_nuked/zm_nuked.gsc
//  replaces that function and feeds zmqol_subs_from_position() below.
//
//  THE HUD (v2.14.24 - TWO SLOTS, NOT TWO LINES). User, 2026-09-08: a subtle
//  outline, your own line white on the bottom row with another speaker's line
//  greyed on the row above, and the HUD row cycling OFF / SUBTITLES /
//  SUBTITLES + NAMES with a [Name] prefix.
//    * Two rows, centred, anchored to the bottom of the safe area at y -30
//      and -17: under the velocity meter (-45), above the safe line that the
//      bottom-left bars and name row sit below (+2..+29), and between the
//      stock points/perks column on the left and the ammo block on the right.
//      The footprint is unchanged from v2.14.21; only what the rows MEAN is.
//    * The bottom row (-17) is the OWN slot: this viewer's own character,
//      white. The row above (-30) is the OTHER slot: any other player's line
//      (or a line played by position - Nuketown's Marlton), grey. The two run
//      independently, so a team-mate's line never pushes your own off screen;
//      a new line in a slot replaces the old one in that slot only.
//    * The outline is the face, not a glow: the "small" face is what draws the
//      name/area rows and the zombie counter outlined (v2.14.21 measured that
//      .glowcolor/.glowalpha do nothing on "default"). Scale is the dvar
//      zmqol_subs_scale (default 1.2, the name row's) so the size can be set
//      from console against a screenshot without a rebuild.
//    * One row is 58 characters. Long lines are pre-paged in the table
//      (2 x 58 per page, pages split by "|", rows by "~"); a slot shows ONE
//      row at a time, so a page's rows are shown in turn, each for its share
//      of the clip's real length from soundgetplaybacktime(), never under
//      1.2 s. settext() only on a new row, never on a tick; the hide is a
//      fade. Two hudelems per player, created on first use.
//    * NAMES. hud_subtitles 2 puts "[Name] " in front of EVERY line, your own
//      included; 1 shows bare text in both slots (the slot's row and colour
//      already say whose it is). Nothing else reads the value: any non-zero is
//      "on" to zmqol_subs_enabled(), so a config holding the old 1 still
//      works.
// ============================================================================
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\gametypes_zm\_hud_util;

main()
{
}

init()
{
    if ( !zmqol_subs_map_has_table() )
    {
        println( "[zm_qol] subtitles: no table for " + level.script + ", not installed" );
        return;
    }

    if ( isdefined( level._audio_custom_player_playvox ) )
    {
        println( "[zm_qol] subtitles: _audio_custom_player_playvox already taken, not installed" );
        return;
    }

    level._audio_custom_player_playvox = ::zmqol_subs_playvox;
    level.zmqol_subs_table = "zm/zmqol_subs_" + level.script + ".csv";

    //  DistMaxDry of the vox_plr_* rows: 1600 in zmb_tomb.english, 1250 in the
    //  other five tables (measured, not the alias's DistMin or a guess).
    if ( level.script == "zm_tomb" )
        level.zmqol_subs_range_sq = 1600 * 1600;
    else
        level.zmqol_subs_range_sq = 1250 * 1250;

    println( "[zm_qol] subtitles: installed, " + level.zmqol_subs_table );
}

//  The six maps that ship a table. tablelookup() on a table that does not
//  exist is an engine warning per call, so the pointer is only installed
//  where a lookup can succeed.
zmqol_subs_map_has_table()
{
    switch ( level.script )
    {
        case "zm_transit":
        case "zm_highrise":
        case "zm_buried":
        case "zm_nuked":
        case "zm_prison":
        case "zm_tomb":
            return 1;
    }

    return 0;
}

//  Runs as `self thread [[ level._audio_custom_player_playvox ]]( ... )` from
//  create_and_play_dialog(); self is the speaker (a player, or an NPC such as
//  the bus). Same seven arguments stock hands over, in stock's order.
zmqol_subs_playvox( prefix, index, sound_to_play, waittime, category, type, override )
{
    self endon( "disconnect" );

    isresponse = 0;

    if ( isdefined( sound_to_play ) && sound_to_play.size > 4 )
    {
        if ( getsubstr( sound_to_play, 0, 3 ) == "hr_" || getsubstr( sound_to_play, 0, 4 ) == "riv_" )
            isresponse = 1;
    }

    //  Stock's isspeaking gate, read BEFORE the call: a speaker already
    //  mid-line has the new line refused, and if the refused line happens to
    //  be the same alias as the one still playing, the compare below could
    //  not tell the two apart and would restart the text under the old audio.
    b_was_speaking = is_true( self.isspeaking );

    //  Stock's own function, on its own thread exactly as stock threads it.
    //  It runs up to its wait( playbacktime ) before this line returns.
    self thread maps\mp\zombies\_zm_audio::do_player_or_npc_playvox( prefix, index, sound_to_play, waittime, category, type, override, isresponse );

    if ( !isplayer( self ) )
        return;

    //  v2.14.21 - EVERY EXIT IS LOGGED, with the reason. User, 2026-09-08:
    //  *"the subtitles kinda worked, but not all the time"*. The two "stock
    //  declined" exits below mean the AUDIO did not play either, so a line that
    //  was heard but never captioned cannot have left through them - if the log
    //  shows a heard line under one of these, the compare itself is wrong. A
    //  heard line with no log line at all took a road that never reaches this
    //  function; the per-map qol_subs_<map>.gsc files cover the ones the stock
    //  scripts play straight through playsoundwithnotify() / playsoundontag() /
    //  playsoundtoplayer().
    if ( b_was_speaking )
    {
        println( "[zm_qol] subtitles: skipped " + prefix + sound_to_play + " - speaker already talking (stock refused the audio too)" );
        return;
    }

    if ( !is_true( self.isspeaking ) || !isdefined( self.speakingline ) || self.speakingline != sound_to_play )
    {
        println( "[zm_qol] subtitles: skipped " + prefix + sound_to_play + " - stock did not start it (nearby speaker, skit override, or no playback time)" );
        return;
    }

    if ( !zmqol_subs_enabled() )
        return;

    str_alias = prefix + sound_to_play;
    self zmqol_subs_caption( str_alias, zmqol_subs_speaker_name( index ), undefined );
}

//  THE ONE PLACE A CAPTION IS ISSUED, for both roads.             (v2.14.21)
//  self is the speaking player. str_name is what a team-mate sees in front of
//  the line. e_listener, when given, is the ONE player who hears it (a
//  playsoundtoplayer() line - Mob's free-fall screams are played to each
//  player's own ears); otherwise it goes to the speaker and everyone within
//  the alias's DistMaxDry, as before.
zmqol_subs_caption( str_alias, str_name, e_listener )
{
    n_ms = soundgetplaybacktime( str_alias );

    if ( !isdefined( n_ms ) || n_ms <= 0 )
    {
        println( "[zm_qol] subtitles: skipped " + str_alias + " - no playback time (alias not in any loaded bank)" );
        return;
    }

    str_text = zmqol_subs_lookup( str_alias );

    if ( str_text == "" )
    {
        //  a line the table has no row for - the log is how those get found
        println( "[zm_qol] subtitles: no text for " + str_alias );
        return;
    }

    println( "[zm_qol] subtitles: " + str_alias + " -> shown for " + ( n_ms * 0.001 ) + "s" );

    if ( isdefined( e_listener ) )
    {
        str_slot = "other";

        if ( e_listener == self )
            str_slot = "own";

        e_listener thread zmqol_subs_show( str_text, zmqol_subs_prefix( str_name ), n_ms * 0.001, str_slot );
        return;
    }

    level thread zmqol_subs_broadcast( self, str_name, str_text, n_ms * 0.001, self.origin, level.zmqol_subs_range_sq );
}

//  THE RAW ROAD. A character line the map script plays straight through a
//  sound builtin on the player - playsoundwithnotify(), playsoundontag(),
//  playsoundtoplayer() - never touching _zm_audio's dialogue system, so the
//  hook above never sees it. The per-map files scripts/zm/<map>/qol_subs_<map>.gsc
//  replace those stock functions verbatim and add one call to this beside each
//  such line. self is the speaking player; the alias itself says who
//  ("vox_plr_N_..."). e_listener as in zmqol_subs_caption().
//  Origins: the round 5-7 Samantha intro, the soul-box and beacon exchanges
//  with Richtofen, the drone's first build, the robot-crush line. Mob: the
//  electric-chair lines, the free-fall screams, the showdown exchange. Buried:
//  Stuhlinger's three answers to Richtofen. Measured 2026-09-08 by grepping the
//  six maps' scripts for every sound builtin fed a vox_plr alias; Maxis,
//  Samantha and Richtofen-in-your-head lines are NPC voices with no table row
//  and are not the character's own, so they stay uncaptioned.
zmqol_subs_raw_line( str_alias, e_listener )
{
    if ( !isdefined( level.zmqol_subs_table ) )
        return;

    if ( !isdefined( self ) || !isplayer( self ) )
        return;

    if ( !zmqol_subs_enabled() )
        return;

    self zmqol_subs_caption( str_alias, zmqol_subs_speaker_name( zmqol_subs_index_from_alias( str_alias ) ), e_listener );
}

//  "vox_plr_N_..." -> N; anything else -> undefined (no name shown).
zmqol_subs_index_from_alias( str_alias )
{
    if ( !isdefined( str_alias ) || str_alias.size < 10 )
        return undefined;

    if ( getsubstr( str_alias, 0, 8 ) != "vox_plr_" )
        return undefined;

    //  a switch rather than int() on a one-character string, so nothing here
    //  depends on how the engine casts text
    switch ( getsubstr( str_alias, 8, 9 ) )
    {
        case "0":
            return 0;
        case "1":
            return 1;
        case "2":
            return 2;
        case "3":
            return 3;
    }

    return undefined;
}

//  The host's HUD switches: the master, then ALL or this row. Read per line,
//  so the row toggles live like every other HUD row.
zmqol_subs_enabled()
{
    if ( !getdvarintdefault( "hud_master", 1 ) )
        return 0;

    return getdvarintdefault( "hud_all", 0 ) || getdvarintdefault( "hud_subtitles", 0 );
}

//  hud_subtitles: 0 OFF, 1 SUBTITLES, 2 SUBTITLES + NAMES (v2.14.24). Only 2
//  puts a name in front; hud_all turns the text on but adds no names.
zmqol_subs_names_on()
{
    return getdvarintdefault( "hud_subtitles", 0 ) == 2;
}

//  "[Name] " when names are on and there is a name, else nothing.
zmqol_subs_prefix( str_name )
{
    if ( !isdefined( str_name ) || str_name == "" )
        return "";

    if ( !zmqol_subs_names_on() )
        return "";

    return "[" + str_name + "] ";
}

//  A line played by POSITION instead of by a speaker: Nuketown's Marlton in
//  the bunker, playsoundatposition() from zm_nuked::marlton_vo_inside_bunker,
//  hooked in scripts/zm/zm_nuked/zm_nuked.gsc. Shown, name in front, to every
//  player within n_range of v_pos - the caller passes the alias's DistMaxDry.
zmqol_subs_from_position( str_alias, str_name, v_pos, n_range )
{
    if ( !isdefined( level.zmqol_subs_table ) )
        return;

    if ( !zmqol_subs_enabled() )
        return;

    n_ms = soundgetplaybacktime( str_alias );

    if ( !isdefined( n_ms ) || n_ms <= 0 )
    {
        println( "[zm_qol] subtitles: skipped " + str_alias + " - no playback time (alias not in any loaded bank)" );
        return;     //  no such alias in any loaded bank - nothing played either
    }

    str_text = zmqol_subs_lookup( str_alias );

    if ( str_text == "" )
    {
        println( "[zm_qol] subtitles: no text for " + str_alias );
        return;
    }

    println( "[zm_qol] subtitles: " + str_alias + " -> shown for " + ( n_ms * 0.001 ) + "s (by position)" );
    level thread zmqol_subs_broadcast( undefined, str_name, str_text, n_ms * 0.001, v_pos, n_range * n_range );
}

//  Column 1 is the explicit take, column 2 the clean one; an alias with a
//  single take carries the same text in both. cg_allow_mature is what the
//  engine's "mature" sound context reads (it is in the boot dvar dump), so it
//  is what decides here too.
zmqol_subs_lookup( str_alias )
{
    n_col = 1;

    if ( !getdvarintdefault( "cg_allow_mature", 1 ) )
        n_col = 2;

    str_text = tablelookup( level.zmqol_subs_table, 0, str_alias, n_col );

    if ( !isdefined( str_text ) )
        return "";

    return str_text;
}

//  Voice index -> the name a team-mate sees. Measured from each map's
//  character switch: zm_highrise.gsc's viewhands (0 oldman, 1 reporter,
//  2 farmgirl, 3 engineer - and Buried's vox_plr_1_respond_richtofen agrees
//  that 1 is the one who hears Richtofen), zm_prison.gsc (0 oleary, 1 deluca,
//  2 handsome, 3 arlington), zm_tomb.gsc (0 dempsey, 1 nikolai, 2 richtofen,
//  3 takeo). Nuketown's fourteen lines are all vox_plr_3 - Marlton.
zmqol_subs_speaker_name( n_index )
{
    if ( !isdefined( n_index ) )
        return "";

    a_names = [];

    switch ( level.script )
    {
        case "zm_prison":
            a_names[0] = "Finn";
            a_names[1] = "Sal";
            a_names[2] = "Billy";
            a_names[3] = "Weasel";
            break;
        case "zm_tomb":
            a_names[0] = "Dempsey";
            a_names[1] = "Nikolai";
            a_names[2] = "Richtofen";
            a_names[3] = "Takeo";
            break;
        default:
            a_names[0] = "Russman";
            a_names[1] = "Stuhlinger";
            a_names[2] = "Misty";
            a_names[3] = "Marlton";
            break;
    }

    if ( n_index < 0 || n_index >= a_names.size )
        return "";

    return a_names[n_index];
}

//  e_speaker is the player whose line it is (their own screen gets it in the
//  OWN slot, wherever they are) or undefined for a line played by position;
//  every other player gets it in the OTHER slot, only within n_range_sq of
//  v_pos. The name goes in front on every screen when names are on.
zmqol_subs_broadcast( e_speaker, str_name, str_text, n_secs, v_pos, n_range_sq )
{
    a_players = get_players();
    str_prefix = zmqol_subs_prefix( str_name );

    for ( i = 0; i < a_players.size; i++ )
    {
        e_player = a_players[i];

        if ( !isdefined( e_player ) )
            continue;

        if ( isdefined( e_speaker ) && e_player == e_speaker )
        {
            e_player thread zmqol_subs_show( str_text, str_prefix, n_secs, "own" );
            continue;
        }

        if ( !isdefined( v_pos ) || distancesquared( e_player.origin, v_pos ) > n_range_sq )
            continue;

        e_player thread zmqol_subs_show( str_text, str_prefix, n_secs, "other" );
    }
}

zmqol_subs_ensure_hud()
{
    if ( isdefined( self.zmqol_subs_hud ) && isdefined( self.zmqol_subs_hud["own"] ) && isdefined( self.zmqol_subs_hud["other"] ) )
        return;

    self.zmqol_subs_hud = [];

    //  The face carries the outline (see the header); the scale is a dvar so it
    //  can be matched to a screenshot from console. 1.2 is the name row's.
    if ( getdvar( "zmqol_subs_scale" ) == "" )
        setdvar( "zmqol_subs_scale", "1.2" );

    n_scale = getdvarfloat( "zmqol_subs_scale" );

    if ( n_scale <= 0 )
        n_scale = 1.2;

    a_slots = [];
    a_slots[0] = "other";
    a_slots[1] = "own";

    for ( i = 0; i < a_slots.size; i++ )
    {
        e_line = self createfontstring( "small", n_scale );
        //  v2.14.21 rows: -30 (OTHER, above) and -17 (OWN, bottom). Under the
        //  velocity meter (-45); the lower row's ink ends ~4 units above the safe
        //  line, and nothing else draws bottom-centre.
        e_line setpoint( "CENTER", "BOTTOM", 0, -30 + i * 13 );

        if ( a_slots[i] == "own" )
            e_line.color = ( 1, 1, 1 );
        else
            e_line.color = ( 0.75, 0.75, 0.75 );

        e_line.alpha = 0;
        e_line.hidewheninmenu = 1;
        e_line.sort = 20;
        self.zmqol_subs_hud[a_slots[i]] = e_line;
    }
}

//  One line per SLOT per viewer: a new line in a slot replaces the old one in
//  that slot the moment it starts (which is also what the ear hears - stock
//  refuses to start a line while a nearby speaker is still going). The other
//  slot is untouched. str_slot is "own" or "other".
zmqol_subs_show( str_text, str_prefix, n_secs, str_slot )
{
    self endon( "disconnect" );

    if ( !isdefined( str_slot ) )
        str_slot = "own";

    self notify( "zmqol_subs_new_" + str_slot );
    self endon( "zmqol_subs_new_" + str_slot );

    self zmqol_subs_ensure_hud();

    e_line = self.zmqol_subs_hud[str_slot];

    //  Pages ("|") of rows ("~") flattened to rows; a slot is one row.
    a_rows = [];
    a_pages = strtok( str_text, "|" );

    if ( !isdefined( a_pages ) || a_pages.size == 0 )
        return;

    for ( i = 0; i < a_pages.size; i++ )
    {
        a_split = strtok( a_pages[i], "~" );

        if ( !isdefined( a_split ) )
            continue;

        for ( j = 0; j < a_split.size; j++ )
        {
            if ( a_split[j] == "" )
                continue;

            a_rows[a_rows.size] = a_split[j];
        }
    }

    n_total = 0;

    for ( i = 0; i < a_rows.size; i++ )
        n_total += a_rows[i].size;

    if ( n_total <= 0 )
        return;

    for ( i = 0; i < a_rows.size; i++ )
    {
        str_row = a_rows[i];

        if ( i == 0 && isdefined( str_prefix ) && str_prefix != "" )
            str_row = str_prefix + str_row;

        e_line settext( str_row );
        e_line.alpha = 1;

        n_show = n_secs * a_rows[i].size / n_total;

        if ( n_show < 1.2 )
            n_show = 1.2;

        wait n_show;
    }

    //  v2.14.21 - a 0.25 s fade instead of a hard cut, user 2026-09-08:
    //  *"make sure they're persistent and smooth"*. The show path still writes
    //  alpha 1 directly, which snaps and cancels any fade still running when the
    //  next line starts in this slot. Same single owner per slot as before.
    wait 0.3;
    e_line fadeovertime( 0.25 );
    e_line.alpha = 0;
}
