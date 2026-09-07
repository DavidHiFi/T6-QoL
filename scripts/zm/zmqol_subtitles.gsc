// ============================================================================
//  SUBTITLES  -  your character's spoken lines as text          (v2.14.16)
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
//  WHAT IS NOT COVERED, so nobody has to rediscover it: a handful of quest
//  lines that map scripts play straight through playsoundwithnotify() /
//  playsoundontag() instead of the dialogue system - 3 on Buried
//  (zm_buried_sq_bt), 12 on Mob (zm_alcatraz_sq), 3 on Origins. Those are
//  builtins on the speaker entity; there is no generic hook, and rewriting
//  three quest functions to add one is a separate decision. Grunts and exerts
//  (playerexert()) are not dialogue and have no text.
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
//  THE HUD. Two lines, centred, anchored to the bottom of the safe area at
//  y -34 and -21: under the velocity meter (-62), above the safe line that
//  the bottom-left bars and name row sit below (+2..+29), and between the
//  stock points/perks column on the left and the ammo block on the right -
//  a 58-character line at this font is ~330 units wide, x 155..485. Long
//  lines are pre-paged in the table (2 x 58 characters per page, pages split
//  by "|", lines by "~") and each page stays up for its share of the clip's
//  real length from soundgetplaybacktime(). settext() only on a new page,
//  never on a tick; the hide is an alpha write. Two hudelems per player,
//  created on first use.
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

    if ( b_was_speaking )
        return;     //  stock declined it - this player was already talking

    if ( !is_true( self.isspeaking ) || !isdefined( self.speakingline ) || self.speakingline != sound_to_play )
        return;     //  stock declined to play it - a nearby speaker, or the skit override

    if ( !zmqol_subs_enabled() )
        return;

    str_alias = prefix + sound_to_play;
    n_ms = soundgetplaybacktime( str_alias );

    if ( !isdefined( n_ms ) || n_ms <= 0 )
        return;

    str_text = zmqol_subs_lookup( str_alias );

    if ( str_text == "" )
    {
        //  a line the table has no row for - the log is how those get found
        println( "[zm_qol] subtitles: no text for " + str_alias );
        return;
    }

    level thread zmqol_subs_broadcast( self, zmqol_subs_speaker_name( index ), str_text, n_ms * 0.001, self.origin, level.zmqol_subs_range_sq );
}

//  The host's HUD switches: the master, then ALL or this row. Read per line,
//  so the row toggles live like every other HUD row.
zmqol_subs_enabled()
{
    if ( !getdvarintdefault( "hud_master", 1 ) )
        return 0;

    return getdvarintdefault( "hud_all", 0 ) || getdvarintdefault( "hud_subtitles", 0 );
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
        return;     //  no such alias in any loaded bank - nothing played either

    str_text = zmqol_subs_lookup( str_alias );

    if ( str_text == "" )
    {
        println( "[zm_qol] subtitles: no text for " + str_alias );
        return;
    }

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

//  e_speaker is the player whose line it is (their own screen gets it with no
//  name, wherever they are) or undefined for a line played by position; every
//  other player gets it, name in front, only within n_range_sq of v_pos.
zmqol_subs_broadcast( e_speaker, str_name, str_text, n_secs, v_pos, n_range_sq )
{
    a_players = get_players();

    for ( i = 0; i < a_players.size; i++ )
    {
        e_player = a_players[i];

        if ( !isdefined( e_player ) )
            continue;

        if ( isdefined( e_speaker ) && e_player == e_speaker )
        {
            e_player thread zmqol_subs_show( str_text, "", n_secs );
            continue;
        }

        if ( !isdefined( v_pos ) || distancesquared( e_player.origin, v_pos ) > n_range_sq )
            continue;

        str_prefix = "";

        if ( str_name != "" )
            str_prefix = str_name + ": ";

        e_player thread zmqol_subs_show( str_text, str_prefix, n_secs );
    }
}

zmqol_subs_ensure_hud()
{
    if ( isdefined( self.zmqol_subs_hud ) && self.zmqol_subs_hud.size == 2 )
        return;

    self.zmqol_subs_hud = [];

    for ( i = 0; i < 2; i++ )
    {
        e_line = self createfontstring( "default", 1.1 );
        e_line setpoint( "CENTER", "BOTTOM", 0, -34 + i * 13 );
        e_line.color = ( 1, 1, 1 );
        e_line.glowcolor = ( 0, 0, 0 );
        e_line.glowalpha = 1;
        e_line.alpha = 0;
        e_line.hidewheninmenu = 1;
        e_line.sort = 20;
        self.zmqol_subs_hud[i] = e_line;
    }
}

//  One line on screen at a time per viewer: a new line replaces the old one
//  the moment it starts, which is also what the ear hears (stock refuses to
//  start a line while a nearby speaker is still going, so overlap is rare).
zmqol_subs_show( str_text, str_prefix, n_secs )
{
    self endon( "disconnect" );
    self notify( "zmqol_subs_new" );
    self endon( "zmqol_subs_new" );

    self zmqol_subs_ensure_hud();

    a_pages = strtok( str_text, "|" );

    if ( !isdefined( a_pages ) || a_pages.size == 0 )
        return;

    n_total = 0;

    for ( i = 0; i < a_pages.size; i++ )
        n_total += a_pages[i].size;

    if ( n_total <= 0 )
        return;

    for ( i = 0; i < a_pages.size; i++ )
    {
        a_lines = strtok( a_pages[i], "~" );
        str_l1 = "";
        str_l2 = "";

        if ( isdefined( a_lines ) && a_lines.size > 0 )
            str_l1 = a_lines[0];

        if ( isdefined( a_lines ) && a_lines.size > 1 )
            str_l2 = a_lines[1];

        if ( i == 0 && str_prefix != "" )
            str_l1 = str_prefix + str_l1;

        //  a one-line page sits on the lower row so it hugs the same baseline
        if ( str_l2 == "" )
        {
            self.zmqol_subs_hud[0] settext( "" );
            self.zmqol_subs_hud[1] settext( str_l1 );
        }
        else
        {
            self.zmqol_subs_hud[0] settext( str_l1 );
            self.zmqol_subs_hud[1] settext( str_l2 );
        }

        self.zmqol_subs_hud[0].alpha = 1;
        self.zmqol_subs_hud[1].alpha = 1;

        n_show = n_secs * a_pages[i].size / n_total;

        if ( n_show < 1.2 )
            n_show = 1.2;

        wait n_show;
    }

    wait 0.3;
    self.zmqol_subs_hud[0].alpha = 0;
    self.zmqol_subs_hud[1].alpha = 0;
}
