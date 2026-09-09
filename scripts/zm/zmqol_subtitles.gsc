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
//    * NAMES. hud_subtitles 2 puts "[Name] " in front of EVERY displayed
//      chunk, including later chunks of a long quote and your own lines; 1
//      shows bare text in both slots (the slot's row and colour
//      already say whose it is). Nothing else reads the value: any non-zero is
//      "on" to zmqol_subs_enabled(), so a config holding the old 1 still
//      works.
// ============================================================================
//
//  ============================================================================
//  v2.14.31 (2026-09-08) - EVERY VOICE, AND A STACK OF ROWS.
//  ----------------------------------------------------------------------------
//  User: *"Make subtitles also work for announcer lines too not just playable
//  characters, so like maxis with the radios in origins, or buried stuff, or
//  like when you get a death machine or any power up, or when you get a hell
//  hound round and it says 'fetch me their souls' or when Brutus speaks in mob
//  of the dead, or when in die rise the zombies say they lie they lie,
//  basically subtitles works both solo and multiplayer with stacks subtitles
//  if multiple lines are playing at once and not just for the players, for
//  all dialogue."*
//
//  WHERE THE NON-PLAYER TEXT COMES FROM. 888 more clips - every vox_* alias
//  that is not vox_plr_* in the six English tables, minus the MP sniper
//  breathing (vox_gen_sinper), exerts and the riot-shield hit - pulled out of
//  the banks and transcribed with the same Whisper pipeline (`zm_qol - dev\
//  subtitles\extract_npc_clips.py`, `transcribe.py`). They ship in the same
//  six tables, which gained a FOURTH column: the alias's own DistMaxDry, read
//  straight out of its sound-alias row, so a line is shown to exactly the
//  players who can hear it (5000 = the 2D announcer / Samantha / bus lines,
//  everyone; 1250 = Buried's Maxis spot, Origins' radios; 625 = the bus,
//  Nuketown's transmission).
//
//  HOW THE NON-PLAYER LINES ARE CAUGHT - three roads, measured in the dump:
//    1. The ANNOUNCER (power-ups, the box leaving, the dog round's "fetch me
//       their souls") is _zm_audio_announcer::playleaderdialogonplayer(): per
//       player, `self playlocalsound( prefix + "_" + name + "_" + variant )`.
//       Threaded from leaderdialogonplayer(), so replaceFunc reaches it (7a).
//       scripts/zm/zmqol_subs_npc_common.gsc carries the copy; the announcer
//       is "vox_zmba" on four maps (Richtofen; `level.sndannouncerisrich`,
//       _zm_utility.gsc:4478), "vox_zmba_sam" after Maxis' ending and on
//       Nuketown, and Samantha's own clips on Mob (the alias table's
//       FileSource is vox_zmba_sam_powerup_*) and Origins.
//    2. The DIALOGUE SYSTEM with a non-player speaker: TranZit's bus
//       (zm_transit_automaton.gsc:107 zmbvoxinitspeaker( "automaton",
//       "vox_bus_" )) talks through create_and_play_dialog() like a player
//       does, so the same level._audio_custom_player_playvox pointer already
//       sees it - zmqol_subs_playvox() no longer returns on !isplayer( self ).
//    3. Everything else is a map script playing a builtin on an entity, a
//       position or a player: Maxis and Richtofen through each map's
//       maxissay()/richtofensay() (TranZit, Die Rise, Buried), Samantha and
//       Maxis through zm_tomb_vo's samanthasayvoplay()/maxissayvoplay() and
//       the audio logs, Brutus through _zm_ai_brutus::sndbrutusvox(), the
//       Die Rise whispers through zm_highrise::custom_zombie_audio_func(), the
//       ghost, the TVs, the station PA, the Nuketown transmissions. Those
//       stock functions are copied verbatim with one zmqol_subs_npc() call
//       beside each play builtin, by `zm_qol - dev\subtitles\gen_subs_npc.py`,
//       into scripts/zm/<map>/qol_subs_npc_<map>.gsc. The builtin decides who
//       hears the line, so its arguments decide who reads it.
//
//  📝 NOT REACHABLE, stated rather than hidden: Brutus' 38 "arrives /
//  attacks / taunts" clips are referenced by no script, no client script and
//  no animation notetrack in zm_prison.ff (all 1,435 xanims dumped and
//  grepped 2026-09-08) - Treyarch shipped them unused. TranZit's twenty
//  vox_zmba_player_* lines are registered to an "announcer" speaker that is
//  never given a line (_zm_audio.gsc:204, no zmbvoxadd). Neither can be heard,
//  so neither is captioned.
//
//  THE STACK. Rows are no longer OWN / OTHER slots: there are N rows
//  (zmqol_subs_rows, default 2) from y -17 upward in 13-unit steps, and each
//  new line takes the lowest FREE row; if none is free it replaces the OLDEST
//  line on screen. Your own character's line is white, every other voice grey,
//  and the NAMES setting puts "[Name] " in front of any of them. Two rows is
//  what fits under the velocity meter (-45) and, on Origins, the generator
//  dial above it (quality_of_life.gsc's meter banner has the measurement);
//  a third row (-43) would sit inside the meter's box. The dvar is there for
//  anyone who runs without the meter.
//  ============================================================================
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

    //  Fallback range for a row with no 4th column: DistMaxDry of the
    //  vox_plr_* rows, 1600 in zmb_tomb.english, 1250 in the other five
    //  tables (measured). Every shipped row now carries its own.
    if ( level.script == "zm_tomb" )
        level.zmqol_subs_range_sq = 1600 * 1600;
    else
        level.zmqol_subs_range_sq = 1250 * 1250;

    if ( getdvar( "zmqol_subs_rows" ) == "" )
        setdvar( "zmqol_subs_rows", "2" );

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

    //  v2.14.31 - an NPC speaker (the bus is the one stock registers): its
    //  line went out through playsoundontag() on itself, so it is heard within
    //  the alias's range of it, name from the alias prefix.
    if ( !isplayer( self ) )
    {
        zmqol_subs_npc( str_alias, self, undefined, undefined );
        return;
    }

    self zmqol_subs_caption( str_alias, zmqol_subs_speaker_name( index ), undefined );
}

//  THE ONE PLACE A PLAYER'S CAPTION IS ISSUED, for both roads.     (v2.14.21)
//  self is the speaking player. str_name is what a team-mate sees in front of
//  the line. e_listener, when given, is the ONE player who hears it (a
//  playsoundtoplayer() line - Mob's free-fall screams are played to each
//  player's own ears); otherwise it goes to the speaker and everyone within
//  the alias's range, as before.
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
        str_kind = "other";

        if ( e_listener == self )
            str_kind = "own";

        e_listener thread zmqol_subs_show( str_text, zmqol_subs_prefix( str_name ), n_ms * 0.001, str_kind );
        return;
    }

    level thread zmqol_subs_broadcast( self, str_name, str_text, n_ms * 0.001, self.origin, zmqol_subs_range_sq( str_alias ) );
}

//  THE RAW ROAD. A character line the map script plays straight through a
//  sound builtin on the player - playsoundwithnotify(), playsoundontag(),
//  playsoundtoplayer() - never touching _zm_audio's dialogue system, so the
//  hook above never sees it. The per-map files scripts/zm/<map>/qol_subs_<map>.gsc
//  replace those stock functions verbatim and add one call to this beside each
//  such line. self is the speaking player; the alias itself says who
//  ("vox_plr_N_..."). e_listener as in zmqol_subs_caption().
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

// ============================================================================
//  zmqol_subs_npc  -  THE NON-PLAYER ROAD.                          (v2.14.31)
//
//  Level-scope, called from the generated per-map copies (and from
//  zmqol_subs_playvox for an NPC dialogue speaker) with the same facts the
//  sound builtin had:
//      e_source    the entity the sound plays ON  (playsound / playsoundontag /
//                  playsoundwithnotify) - heard within the alias's range of it
//      v_pos       a playsoundatposition() position - same rule
//      e_listener  a playsoundtoplayer() / playlocalsound() target - that one
//                  player, wherever they stand
//  Neither source nor position given -> everyone (a 2D line).
//
//  A vox_plr_* alias arriving here (Origins' Samantha "promises" conversation
//  mixes the player's own answers into the same loop) is a CHARACTER line and
//  takes the player road, so it is white on that player's screen and named
//  like every other character line.
// ============================================================================
zmqol_subs_npc( str_alias, e_source, v_pos, e_listener )
{
    if ( !isdefined( level.zmqol_subs_table ) )
        return;

    if ( !isdefined( str_alias ) || str_alias == "" )
        return;

    if ( !zmqol_subs_enabled() )
        return;

    if ( str_alias.size > 8 && getsubstr( str_alias, 0, 8 ) == "vox_plr_" )
    {
        if ( isdefined( e_listener ) && isplayer( e_listener ) )
        {
            e_listener zmqol_subs_raw_line( str_alias, e_listener );
            return;
        }

        if ( isdefined( e_source ) && isplayer( e_source ) )
        {
            e_source zmqol_subs_raw_line( str_alias, undefined );
            return;
        }
    }

    n_ms = soundgetplaybacktime( str_alias );

    if ( !isdefined( n_ms ) || n_ms <= 0 )
    {
        println( "[zm_qol] subtitles: skipped " + str_alias + " - no playback time (alias not in any loaded bank)" );
        return;
    }

    str_text = zmqol_subs_lookup( str_alias );

    if ( str_text == "" )
    {
        println( "[zm_qol] subtitles: no text for " + str_alias );
        return;
    }

    str_name = zmqol_subs_npc_name( str_alias );
    n_secs = n_ms * 0.001;

    if ( isdefined( e_listener ) )
    {
        println( "[zm_qol] subtitles: " + str_alias + " (" + str_name + ") -> shown for " + n_secs + "s to one player" );
        e_listener thread zmqol_subs_show( str_text, zmqol_subs_prefix( str_name ), n_secs, "other" );
        return;
    }

    if ( !isdefined( v_pos ) && isdefined( e_source ) )
        v_pos = e_source.origin;

    n_range_sq = zmqol_subs_range_sq( str_alias );

    //  A 2D line (DistMaxDry 5000 in every table for the announcer, Samantha,
    //  the whispers) reaches every player wherever they stand.
    if ( n_range_sq >= 4000 * 4000 )
        v_pos = undefined;

    if ( isdefined( v_pos ) )
        println( "[zm_qol] subtitles: " + str_alias + " (" + str_name + ") -> shown for " + n_secs + "s within " + int( sqrt( n_range_sq ) ) + " of (" + int( v_pos[0] ) + "," + int( v_pos[1] ) + "," + int( v_pos[2] ) + ")" );
    else
        println( "[zm_qol] subtitles: " + str_alias + " (" + str_name + ") -> shown for " + n_secs + "s to everyone" );

    level thread zmqol_subs_broadcast( undefined, str_name, str_text, n_secs, v_pos, n_range_sq );
}

//  Who a non-player alias is, from its prefix. Measured against the alias
//  tables and the scripts that play them (2026-09-08):
//    vox_zmba_*       SPLIT BY CATEGORY since v2.15.4, because this prefix
//    vox_zmba_sam_*   carries two different speakers:
//                       powerup / qol_powerup / event / grief -> "Announcer",
//                         the role. Who fills it changes MID-MATCH
//                         (sndswitchannouncervox), so no name is derivable.
//                       everything else (sidequest / stuhlinger / end / dr /
//                         zombie possession / player / first / anim) -> the
//                         character: Richtofen on TranZit / Die Rise / Buried,
//                         Samantha on Mob and Origins.
//    vox_maxi_*       Maxis          vox_sam_*     Samantha
//    vox_brutus_*     Brutus         vox_bus_*     T.E.D.D. (the bus driver)
//    vox_fg_*         the ghost      vox_zombie_*  the zombies (Die Rise)
//    vox_stat_*       the station PA vox_radi_*    the radio
//    vox_surN_*       the TV         vox_guar_*    the guard's audio logs
//    vox_nuked_*      the transmission
zmqol_subs_npc_name( str_alias )
{
    a_tok = strtok( str_alias, "_" );

    if ( !isdefined( a_tok ) || a_tok.size < 2 )
        return "";

    str_who = a_tok[1];

    switch ( str_who )
    {
        case "zmba":
            //  🛑 v2.15.4 - THE ANNOUNCER IS A ROLE, NOT A PERSON.
            //
            //  User, 2026-09-09, with a screenshot: a Blood Money pickup was
            //  captioned "[Richtofen] Blood money." while SAMANTHA spoke it -
            //  *"make sure bonfire sale and death machine power ups say
            //  [Announcer] or any other power up or other subtitle that doesn't
            //  have a specific voice to it. don't just default to assuming its
            //  richtofen or whatever."*
            //
            //  🌟 WHY NO NAME CAN BE DERIVED HERE, measured: who the announcer
            //  IS changes at RUNTIME. _zm_utility::sndswitchannouncervox("sam")
            //  repoints the announcer alias prefix mid-match - it is what runs
            //  after Maxis' ending on any map - so the same bare vox_zmba_
            //  alias is Richtofen before it and Samantha after it. A prefix test
            //  cannot see that, and neither can a per-map table. The role name
            //  is correct in every one of those states, which is exactly why it
            //  is the right label.
            //
            //  These four second tokens are the announcer/overseer speaking as
            //  the announcer, read off the shipped CSVs (2026-09-09):
            //      powerup      "Insta-Kill!", "Double Points!"
            //      qol_powerup  this mod's four added drops
            //      event        "Fetch me their souls!" (dogs), "Bye-bye." (box)
            //      grief        "One of them is down!"
            //  Everything else under vox_zmba_ is the CHARACTER talking in the
            //  ether or through Stuhlinger - sidequest, end, stuhlinger, dr,
            //  zombie (possession), player, first, anim - and those keep a real
            //  name, because a person really is saying them.
            str_zmba = str_who;
            if ( a_tok.size > 2 && a_tok[2] == "sam" )
                str_zmba = "sam";

            if ( a_tok.size > 2 )
            {
                //  the category token: a_tok[2] normally, a_tok[3] behind "sam"
                str_cat = a_tok[2];
                if ( str_zmba == "sam" && a_tok.size > 3 )
                    str_cat = a_tok[3];

                if ( str_cat == "powerup" || str_cat == "event" || str_cat == "grief" )
                    return "Announcer";

                //  qol_powerup_* - this mod's own drops, two tokens
                if ( str_cat == "qol" )
                    return "Announcer";
            }

            if ( str_zmba == "sam" )
                return "Samantha";

            if ( level.script == "zm_prison" || level.script == "zm_tomb" )
                return "Samantha";

            return "Richtofen";
        case "maxi":
        case "maxis":
            return "Maxis";
        case "sam":
            return "Samantha";
        case "brutus":
            return "Brutus";
        case "bus":
            return "T.E.D.D.";
        case "fg":
            return "Ghost";
        case "zombie":
            return "Zombie";
        case "stat":
            return "Station PA";
        case "radi":
            return "Radio";
        case "sur1":
        case "sur2":
        case "sur3":
        case "sur4":
        case "sur5":
            return "TV";
        case "guar":
            return "Guard";
        case "nuked":
            return "Transmission";
    }

    return "";
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

//  Column 3 (v2.14.31) is the alias's own DistMaxDry from its sound-alias row,
//  squared here for distancesquared(). A row without one (none shipped) takes
//  the map's vox_plr default.
zmqol_subs_range_sq( str_alias )
{
    str_range = tablelookup( level.zmqol_subs_table, 0, str_alias, 3 );

    if ( !isdefined( str_range ) || str_range == "" )
        return level.zmqol_subs_range_sq;

    n_range = int( str_range );

    if ( n_range <= 0 )
        return level.zmqol_subs_range_sq;

    return n_range * n_range;
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

//  e_speaker is the player whose line it is (their own screen gets it white,
//  wherever they are) or undefined for a non-player line; every other player
//  gets it grey, only within n_range_sq of v_pos - and everyone when v_pos is
//  undefined (a 2D line). The name goes in front on every screen when names
//  are on.
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

        if ( isdefined( v_pos ) && distancesquared( e_player.origin, v_pos ) > n_range_sq )
            continue;

        e_player thread zmqol_subs_show( str_text, str_prefix, n_secs, "other" );
    }
}

//  zmqol_subs_rows: how many rows the stack may use, 1..4. Two fit under the
//  velocity meter; see the v2.14.31 banner.
zmqol_subs_row_count()
{
    n_rows = getdvarintdefault( "zmqol_subs_rows", 2 );

    if ( n_rows < 1 )
        n_rows = 1;

    if ( n_rows > 4 )
        n_rows = 4;

    return n_rows;
}

zmqol_subs_ensure_hud()
{
    n_rows = zmqol_subs_row_count();

    if ( isdefined( self.zmqol_subs_hud ) && self.zmqol_subs_hud.size == n_rows )
        return;

    //  a row-count change from console: drop the old elements and rebuild
    if ( isdefined( self.zmqol_subs_hud ) )
    {
        self notify( "zmqol_subs_reset" );

        for ( i = 0; i < self.zmqol_subs_hud.size; i++ )
        {
            if ( isdefined( self.zmqol_subs_hud[i] ) )
                self.zmqol_subs_hud[i] destroy();
        }
    }

    self.zmqol_subs_hud = [];
    self.zmqol_subs_st_text = [];
    self.zmqol_subs_st_kind = [];
    self.zmqol_subs_st_id = [];
    self.zmqol_subs_st_fade = [];
    self.zmqol_subs_st_fade_end = [];
    self.zmqol_subs_st_key = [];

    if ( !isdefined( self.zmqol_subs_next_id ) )
        self.zmqol_subs_next_id = 1;

    //  The face carries the outline (see the header); the scale is a dvar so it
    //  can be matched to a screenshot from console. 1.2 is the name row's.
    if ( getdvar( "zmqol_subs_scale" ) == "" )
        setdvar( "zmqol_subs_scale", "1.2" );

    n_scale = getdvarfloat( "zmqol_subs_scale" );

    if ( n_scale <= 0 )
        n_scale = 1.2;

    for ( i = 0; i < n_rows; i++ )
    {
        e_line = self createfontstring( "small", n_scale );
        //  Row 0 is the bottom row at -17 (v2.14.21: ink ends ~4 units above
        //  the safe line); each row above it is 13 units higher. Row 1 is the
        //  old OTHER row at -30, under the velocity meter (-45).
        e_line setpoint( "CENTER", "BOTTOM", 0, -17 - i * 13 );
        e_line.color = ( 0.75, 0.75, 0.75 );
        e_line.alpha = 0;
        e_line.hidewheninmenu = 1;
        e_line.sort = 20;
        self.zmqol_subs_hud[i] = e_line;
    }
}

//  ============================================================================
//  THE STACK.  Slot 0 is the BOTTOM line and the OLDEST; every new line is
//  pushed on top of it and drawn one row higher. When a line ends, its slot is
//  removed and every line above slides DOWN one row to close the gap.
//
//  User, 2026-09-09, after taking a Zombie Blood and an Insta-Kill together and
//  seeing one caption: *"if multiple subtitles would occur simultaneously, the
//  next one shows up above, and when the original first one below fades away the
//  next one then takes its place, so therefore multiple subtitles can appear on
//  the screen"*.
//
//  Slot i is ALWAYS drawn by HUD element i, so the redraw IS the shift: the
//  elements never move, the text moves between them. That is what makes a line
//  "take the place" of the one under it without re-laying out the HUD.
//
//  🛑 WHY THAT USER REPORT IS NOT FIXED BY THIS ALONE - stated, not hidden.
//  Two power-ups grabbed together only ever produce ONE announcer line, and the
//  drop is stock's, upstream of every subtitle path: _zm_powerups.gsc:1147 calls
//  leaderdialog( powerup_name, team ) with `queue` UNDEFINED, and
//  _zm_audio_announcer.gsc:324 reads
//        if ( !self.zmbdialogactive )        play
//        else if ( isdefined( queue ) && queue )  enqueue
//  - with no queue argument the second line is silently DISCARDED. It is never
//  played, so there is no second caption to stack. This file captions what is
//  spoken; making both appear means either captioning a line the player cannot
//  hear, or passing queue = 1 so the second is spoken ~4 s later. Both change
//  audible behaviour and are the user's call, so neither is done here.
//  ============================================================================
zmqol_subs_stack_index( n_id )
{
    if ( !isdefined( self.zmqol_subs_st_id ) )
        return -1;

    for ( i = 0; i < self.zmqol_subs_st_id.size; i++ )
    {
        if ( self.zmqol_subs_st_id[i] == n_id )
            return i;
    }

    return -1;
}

//  Drop one slot and close the gap - the shift-down, in one place.
zmqol_subs_stack_remove( n_id )
{
    n_at = self zmqol_subs_stack_index( n_id );

    if ( n_at < 0 )
        return;

    a_text = [];
    a_kind = [];
    a_id = [];
    a_fade = [];
    a_fade_end = [];
    a_key = [];

    for ( i = 0; i < self.zmqol_subs_st_id.size; i++ )
    {
        if ( i == n_at )
            continue;

        a_text[a_text.size] = self.zmqol_subs_st_text[i];
        a_kind[a_kind.size] = self.zmqol_subs_st_kind[i];
        a_id[a_id.size] = self.zmqol_subs_st_id[i];
        a_fade[a_fade.size] = self.zmqol_subs_st_fade[i];
        a_fade_end[a_fade_end.size] = self.zmqol_subs_st_fade_end[i];
        a_key[a_key.size] = self.zmqol_subs_st_key[i];
    }

    self.zmqol_subs_st_text = a_text;
    self.zmqol_subs_st_kind = a_kind;
    self.zmqol_subs_st_id = a_id;
    self.zmqol_subs_st_fade = a_fade;
    self.zmqol_subs_st_fade_end = a_fade_end;
    self.zmqol_subs_st_key = a_key;
}

//  Bottom-up: slot i into element i, blank every element with no slot.
//
//  A slot part-way through its fade is left alone - writing alpha 1 over it
//  would cancel the fade (the show path relies on exactly that behaviour when
//  it reuses an element, see below), so a line starting while another fades
//  must not drag the fading one back to full.
zmqol_subs_redraw()
{
    if ( !isdefined( self.zmqol_subs_hud ) || !isdefined( self.zmqol_subs_st_id ) )
        return;

    n_now = gettime();

    for ( i = 0; i < self.zmqol_subs_hud.size; i++ )
    {
        e_line = self.zmqol_subs_hud[i];

        if ( !isdefined( e_line ) )
            continue;

        if ( i >= self.zmqol_subs_st_id.size )
        {
            e_line.alpha = 0;
            continue;
        }

        if ( self.zmqol_subs_st_kind[i] == "own" )
            e_line.color = ( 1, 1, 1 );
        else
            e_line.color = ( 0.75, 0.75, 0.75 );

        e_line settext( self.zmqol_subs_st_text[i] );

        if ( !self.zmqol_subs_st_fade[i] )
        {
            e_line.alpha = 1;
            continue;
        }

        // A fading caption can move down when an older row disappears. Resume
        // the same fade on its new HUD element for the exact time remaining;
        // otherwise the fade stays behind on the vacated row and the caption
        // vanishes early.
        n_left = self.zmqol_subs_st_fade_end[i] - n_now;

        if ( n_left <= 0 )
        {
            e_line.alpha = 0;
            continue;
        }

        n_alpha = n_left / 250.0;

        if ( n_alpha > 1 )
            n_alpha = 1;

        e_line.alpha = n_alpha;
        e_line fadeovertime( n_left * 0.001 );
        e_line.alpha = 0;
    }
}

//  One line per viewer per call. str_kind "own" is this viewer's own character
//  (white); anything else - another player, an NPC, the announcer - is grey.
//  A line shows one 58-character chunk at a time for its share of the clip's
//  real length, never under 1.2 s; then fades and frees its slot.
zmqol_subs_show( str_text, str_prefix, n_secs, str_kind )
{
    self endon( "disconnect" );

    if ( !isdefined( str_kind ) )
        str_kind = "own";

    // Build/reset the HUD before subscribing this thread to the reset notify.
    // If the row-count dvar changed, ensure_hud() must be allowed to finish the
    // rebuild while its notify ends only the older caption threads.
    self zmqol_subs_ensure_hud();
    self endon( "zmqol_subs_reset" );

    //  🛑 v2.15.13 - DE-DUP THE SAME CAPTION. A power-up
    //  like Blood Money is announced twice: once by stock's leaderdialog
    //  (bonus_points -> vox_zmba_powerup_blood_money, captioned by the
    //  playleaderdialogonplayer hook) and once by this mod's own guaranteed line
    //  (vox_zmba_qol_powerup_blood_money, added because stock's AUDIO drops when
    //  busy). Both resolve to the identical text "Blood Money." and fire in the
    //  same grab, so the player saw it twice. Collapsing an EXACT text match
    //  within 1.5 s shows it once; the window is short enough that a genuinely
    //  repeated line a moment later is unaffected. The active-stack check also
    //  prevents an identical long caption from occupying two visible rows even
    //  when the second delivery arrives after the short time window.
    for ( i = 0; i < self.zmqol_subs_st_key.size; i++ )
    {
        if ( self.zmqol_subs_st_key[i] == str_text )
            return;
    }

    n_now = gettime();
    if ( isdefined( self.zmqol_subs_dedup_text ) && self.zmqol_subs_dedup_text == str_text &&
         isdefined( self.zmqol_subs_dedup_ms ) && ( n_now - self.zmqol_subs_dedup_ms ) < 1500 )
        return;
    self.zmqol_subs_dedup_text = str_text;
    self.zmqol_subs_dedup_ms = n_now;

    //  Pages ("|") of rows ("~") flattened to chunks; a chunk is one screenful.
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

    //  The stack is full: the OLDEST line on screen gives up its slot, which is
    //  what the fixed-row version did when no row was free.
    if ( self.zmqol_subs_st_id.size >= self.zmqol_subs_hud.size )
        self zmqol_subs_stack_remove( self.zmqol_subs_st_id[0] );

    n_id = self.zmqol_subs_next_id;
    self.zmqol_subs_next_id = n_id + 1;

    str_first = a_rows[0];

    if ( isdefined( str_prefix ) && str_prefix != "" )
        str_first = str_prefix + str_first;

    n_slot = self.zmqol_subs_st_id.size;
    self.zmqol_subs_st_text[n_slot] = str_first;
    self.zmqol_subs_st_kind[n_slot] = str_kind;
    self.zmqol_subs_st_id[n_slot] = n_id;
    self.zmqol_subs_st_fade[n_slot] = 0;
    self.zmqol_subs_st_fade_end[n_slot] = 0;
    self.zmqol_subs_st_key[n_slot] = str_text;

    self zmqol_subs_redraw();

    for ( i = 0; i < a_rows.size; i++ )
    {
        n_show = n_secs * a_rows[i].size / n_total;

        if ( n_show < 1.2 )
            n_show = 1.2;

        wait n_show;

        //  Evicted by a newer line while we waited - stop, the slot is gone.
        n_at = self zmqol_subs_stack_index( n_id );

        if ( n_at < 0 )
            return;

        if ( i + 1 < a_rows.size )
        {
            str_row = a_rows[i + 1];

            if ( isdefined( str_prefix ) && str_prefix != "" )
                str_row = str_prefix + str_row;

            self.zmqol_subs_st_text[n_at] = str_row;
            self zmqol_subs_redraw();
        }
    }

    //  v2.14.21 - a 0.25 s fade instead of a hard cut, user 2026-09-08:
    //  *"make sure they're persistent and smooth"*. Marked fading first so a
    //  line starting underneath cannot snap this one back to full alpha.
    //
    //  Fade deadline is stored with the slot. If the slot slides down during
    //  these 250 ms, redraw resumes the remaining fade on its new HUD element.
    wait 0.3;

    n_at = self zmqol_subs_stack_index( n_id );

    if ( n_at < 0 )
        return;

    self.zmqol_subs_st_fade[n_at] = 1;
    self.zmqol_subs_st_fade_end[n_at] = gettime() + 250;
    self zmqol_subs_redraw();

    wait 0.25;

    //  Now drop the slot: everything above slides down one row into its place.
    self zmqol_subs_stack_remove( n_id );
    self zmqol_subs_redraw();
}
