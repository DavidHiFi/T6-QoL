// ============================================================================
//  qol_solo_ee.gsc  (Mob of the Dead)  -  SOLO EASTER EGGS, the FINAL FLIGHT
// ----------------------------------------------------------------------------
//  LOCATION INSIDE mod.iwd:
//      scripts/zm/zm_prison/qol_solo_ee.gsc
//
//  User, 2026-09-08: *"the solo easter egg option shows in the pre game menu for
//  all the classic maps except mob of the dead, make sure to enable that for
//  motd as well so every maps easter egg can be solo'd and make sure it works"*.
//
//  This is the file the v2.14.3 lobby-row comment said did not exist yet. The
//  source mod this project adapted for the other four maps (Hadi77KSA's "Any
//  Player EE Scripts") does not cover Mob, so nothing was ported and zm_prison
//  was left off the row's map list. It is now written from Treyarch's own
//  scripts, and BO2-Reimagined is the working precedent - it lifts the same two
//  gates, in the same two functions, by the same replaceFunc route
//  (t6\reference\BO2-Reimagined\scripts\zm\zm_prison\zm_prison_reimagined.gsc:43-44).
//
//  ⭐ IT DOES NOTHING UNLESS THE LOBBY ROW SAYS SO. `solo_ee` is written by the
//  SOLO EASTER EGGS row in ui_mp/t6/menus/privategamelobby_project.lua and
//  defaults to 0, so a player who never touches the row gets stock Black Ops II
//  behaviour exactly. Both replacements below are byte-for-byte stock in that
//  case - see the per-function proofs.
//
// ----------------------------------------------------------------------------
//  🌟 WHAT ACTUALLY BLOCKS SOLO ON MOB - MEASURED, NOT ASSUMED
//
//  The three quest cycles, the Golden Spoon, the Warden's Blundergat, the three
//  nixie tubes and the seven audio logs have NO player-count gate anywhere; all
//  of that is already soloable in stock. Every player-count test in every Mob
//  quest script was read (zm_alcatraz_sq, zm_alcatraz_sq_nixie,
//  zm_alcatraz_weap_quest, zm_prison_spoon, zm_prison_sq_bg, zm_prison_sq_wth,
//  zm_prison_sq_fc, zm_prison_achievement, zm_prison_sq_final) and exactly two
//  of them stop a lone player, both in the FINAL FLIGHT - the last step, the one
//  that ends the quest:
//
//    1. maps\mp\zm_prison_sq_final::stage_two - after the audio logs, the
//       "plane_fly_afterlife_trigger" is turned on only while
//       `getplayers().size > 1` AND somebody is playing Arlington. Solo, the
//       size test is false forever, so the trigger is never switched on.
//
//    2. maps\mp\zm_prison_sq_final::final_flight_trigger - even if the trigger
//       were on, the use handler does `if ( players.size < 2 ) continue;`, so a
//       solo press is swallowed silently, with no message and no sound.
//
//  Verified identical in three independent dumps of the stock script:
//    t6\reference\t6 modding starter kit\reference\gsc-dump\...\zm_prison_sq_final.gsc:267,386
//    t6\reference\t6-scripts\...\zm_prison_sq_final.gsc:267,386            (md5-identical to the above)
//    t6\reference\COD-GSC-Source\BO2-GSC\maps\mp\zm_prison_sq_final.gsc:255,358
//  and in the patch zone's own copy (t6\reference\BO2-Raw-files\Decompiled\
//  zm_prison_patch\...:275,406 - rendered as `while (...) { continue; }` there,
//  which is the decompiler's shape for `if (...) continue;`, per CLAUDE.md's
//  rule about branch-mangled decompiles).
//
//  🛑 THE THIRD PIECE IS NOT A GATE, IT IS A SILENT LOSS - and it is why this
//  file exists at all rather than just two replaceFuncs. stage_final() only
//  fires `level notify( "pop_goes_the_weasel_achieved" )` inside its showdown
//  branch, which needs an Arlington AND at least one other player:
//
//      if ( isdefined( p_weasel ) && a_player_team.size > 0 )   <- showdown, achievement
//      else if ( isdefined( p_weasel ) )  level.winner = "weasel";  <- good ending, NO achievement
//      else                              level.winner = "team";    <- bad ending,  NO achievement
//
//  So a solo player who lifts gates 1 and 2 reaches a real ending - Treyarch's
//  own else-branches, complete with the ZM_PRISON_GOOD / ZM_PRISON_BAD screen,
//  the ending music and the prison_ee_good_ending / prison_ee_bad_ending client
//  stat, all of which sit OUTSIDE the branch - but never gets the achievement
//  that the same quest hands a four-player team. zmqol_solo_ee_final_reward()
//  below closes that, and closes it without touching stage_final at all.
//
//  📝 WHICH ENDING SOLO GETS IS TREYARCH'S RULE, NOT A CHOICE MADE HERE. Play
//  as Arlington (the Weasel) and the lone-weasel branch gives the GOOD ending;
//  play as Sal, Billy or Finn and the no-weasel branch gives the BAD one. The
//  CHARACTER row in the same lobby screen is how a solo player picks. Nothing
//  here overrides it - inventing a winner would be exactly the kind of quiet
//  compromise this project does not ship.
//
//  📝 The final showdown itself is Weasel-versus-team PvP and has no solo form.
//  It is not faked here: solo skips it the way stock skips it.
//
//  🛑 ONE STATED TRADE-OFF, not hidden: with the row ON, the Arlington-presence
//  requirement in stage_two is lifted for EVERY lobby size, not just solo. A
//  four-player game with the row on and nobody playing Arlington can therefore
//  board the final flight and take the bad ending, where stock would have kept
//  the trigger dark. That is the row doing what it says ("finished with fewer
//  than four players"); with the row OFF - the default - the loop below is
//  provably stock, transition for transition.
// ============================================================================

#include common_scripts\utility;
#include maps\mp\_utility;

main()
{
    //  🛑 THE HOOKS ARE INSTALLED UNCONDITIONALLY, AND THAT IS DELIBERATE.
    //  main() runs long before the lobby's `solo_ee` write can be read (the
    //  other four map files read it after flag_wait( "initial_players_connected" )
    //  for that reason), so the dvar cannot be tested here. Both replacements
    //  therefore read it themselves at the moment they run, and reproduce stock
    //  exactly when it is 0.
    //
    //  📝 Timing is safe: zm_alcatraz_sq::start_alcatraz_sidequest() does not
    //  call final_flight_setup() - the thing that threads final_flight_trigger()
    //  onto the trigger entity - until after flag_wait( "start_zombie_round_logic" ),
    //  and stage_two() is not called until the nixie tubes and audio logs are
    //  done, many rounds later. Both are long after every mod main().
    replaceFunc( maps\mp\zm_prison_sq_final::stage_two, ::zmqol_stage_two );
    replaceFunc( maps\mp\zm_prison_sq_final::final_flight_trigger, ::zmqol_final_flight_trigger );
}

init()
{
    if ( !maps\mp\zombies\_zm_sidequests::is_sidequest_allowed( "zclassic" ) )
        return;

    thread qol_solo_ee_gate();
}

//  Same shape as the other four maps: one dvar read, after the lobby's write has
//  certainly landed, and one log line either way so a boot report can quote it.
qol_solo_ee_gate()
{
    flag_wait( "initial_players_connected" );

    if ( getdvarintdefault( "solo_ee", 0 ) != 1 )
    {
        println( "[zm_qol] SOLO EASTER EGGS: off (Mob of the Dead)" );
        return;
    }

    println( "[zm_qol] SOLO EASTER EGGS: on (Mob of the Dead - final flight boardable alone, ending achievement restored)" );
    level thread zmqol_solo_ee_final_reward();
}

zmqol_solo_ee_on()
{
    return getdvarintdefault( "solo_ee", 0 ) == 1;
}

// ============================================================================
//  zmqol_stage_two  (replaces maps\mp\zm_prison_sq_final::stage_two)
//
//  GATE 1. Everything down to `t_plane_fly_afterlife playsound(...)` is stock
//  verbatim - the seven audio logs, their order, and the headphones prop. Only
//  the trigger loop differs, and only in what it computes as "should the trigger
//  be on":
//
//      stock : size > 1 ? arlington_is_present : 0
//      here  : b_solo_ee ? 1 : ( size > 1 ? arlington_is_present : 0 )
//
//  With b_solo_ee == 0 the two expressions are equal for every input, and the
//  on/off transitions around them are stock's own, so the row being off leaves
//  this function behaviourally identical to the one it replaced.
// ============================================================================
zmqol_stage_two()
{
    audio_logs = [];
    audio_logs[0] = [];
    audio_logs[0][0] = "vox_guar_tour_vo_1_0";
    audio_logs[0][1] = "vox_guar_tour_vo_2_0";
    audio_logs[0][2] = "vox_guar_tour_vo_3_0";
    audio_logs[2] = [];
    audio_logs[2][0] = "vox_guar_tour_vo_4_0";
    audio_logs[3] = [];
    audio_logs[3][0] = "vox_guar_tour_vo_5_0";
    audio_logs[3][1] = "vox_guar_tour_vo_6_0";
    audio_logs[4] = [];
    audio_logs[4][0] = "vox_guar_tour_vo_7_0";
    audio_logs[5] = [];
    audio_logs[5][0] = "vox_guar_tour_vo_8_0";
    audio_logs[6] = [];
    audio_logs[6][0] = "vox_guar_tour_vo_9_0";
    audio_logs[6][1] = "vox_guar_tour_vo_10_0";
    maps\mp\zm_prison_sq_final::play_sq_audio_log( 0, audio_logs[0], 0 );

    for ( i = 2; i <= 6; i++ )
        maps\mp\zm_prison_sq_final::play_sq_audio_log( i, audio_logs[i], 1 );

    level.m_headphones delete();
    t_plane_fly_afterlife = getent( "plane_fly_afterlife_trigger", "script_noteworthy" );
    t_plane_fly_afterlife playsound( "zmb_easteregg_laugh" );
    trigger_is_on = 0;

    b_solo_ee = zmqol_solo_ee_on();

    if ( b_solo_ee )
        println( "[zm_qol] SOLO EASTER EGGS (Mob): audio logs done, final flight trigger unlocked for any lobby size" );

    while ( true )
    {
        players = getplayers();
        b_should_be_on = 0;

        if ( players.size > 1 )
        {
            arlington_is_present = 0;

            foreach ( player in players )
            {
                if ( isdefined( player ) && player.character_name == "Arlington" )
                    arlington_is_present = 1;
            }

            b_should_be_on = arlington_is_present;
        }

        if ( b_solo_ee )
            b_should_be_on = 1;

        if ( b_should_be_on && !trigger_is_on )
        {
            t_plane_fly_afterlife trigger_on();
            trigger_is_on = 1;
        }
        else if ( !b_should_be_on && trigger_is_on )
        {
            t_plane_fly_afterlife trigger_off();
            trigger_is_on = 0;
        }

        wait 0.1;
    }
}

// ============================================================================
//  zmqol_final_flight_trigger
//  (replaces maps\mp\zm_prison_sq_final::final_flight_trigger)
//
//  GATE 2. Stock verbatim except for one clause: `players.size < 2` becomes
//  `players.size < 2 && !zmqol_solo_ee_on()`. With the row off that is the same
//  test, so the row off is stock.
//
//  🛑 EVERY CALL IS FULLY QUALIFIED. An unqualified final_flight_player_thread()
//  here would resolve against THIS file at load time and throw "Unresolved
//  external" (AI_CONTEXT.md hard rule 2), so the stock passenger thread is named
//  in full - it is untouched, and the whole flight, crash, bridge teleport and
//  stage_final hand-off below it are stock's own code, not a copy.
//
//  📝 level.custom_plane_validation is preserved: it is _zm_ai_brutus::check_plane_valid,
//  which is how a Brutus locks the plane, and it still gets the first word.
//  📝 The everyone-is-ready test is preserved too. Solo it is a test of one, so a
//  player who is down or in the Afterlife still cannot board - which is right,
//  and is also what stops the trigger firing during a bleedout.
// ============================================================================
zmqol_final_flight_trigger()
{
    t_plane_fly = getent( "plane_fly_trigger", "targetname" );
    self setcursorhint( "HINT_NOICON" );
    self sethintstring( "" );

    while ( isdefined( self ) )
    {
        self waittill( "trigger", e_triggerer );

        if ( isplayer( e_triggerer ) )
        {
            if ( isdefined( level.custom_plane_validation ) )
            {
                valid = self [[ level.custom_plane_validation ]]( e_triggerer );

                if ( !valid )
                    continue;
            }

            players = getplayers();

            if ( players.size < 2 && !zmqol_solo_ee_on() )
                continue;

            b_everyone_is_ready = 1;

            foreach ( player in players )
            {
                if ( !isdefined( player ) || player.sessionstate == "spectator" || player maps\mp\zombies\_zm_laststand::player_is_in_laststand() )
                    b_everyone_is_ready = 0;
            }

            if ( !b_everyone_is_ready )
                continue;

            if ( flag( "plane_is_away" ) )
                continue;

            flag_set( "plane_is_away" );
            t_plane_fly trigger_off();

            if ( players.size < 2 )
                println( "[zm_qol] SOLO EASTER EGGS (Mob): final flight boarded solo" );

            foreach ( player in players )
            {
                if ( isdefined( player ) )
                    player thread maps\mp\zm_prison_sq_final::final_flight_player_thread();
            }

            return;
        }
    }
}

// ============================================================================
//  zmqol_solo_ee_final_reward  -  the achievement stage_final drops on the floor
//
//  stage_final() notifies "stage_final" as its very first statement and sets
//  level.winner exactly once, on every path, before the ending screen. Nothing
//  else in any Zombies script writes level.winner (grepped across the whole
//  stock ZM dump), so it is a clean one-shot signal that an ending was decided.
//
//  Re-firing "pop_goes_the_weasel_achieved" cannot double up: the listener,
//  zm_prison_achievement::achievement_pop_goes_the_weasel(), is a single
//  `level waittill` that returns after the first one, so on a four-player
//  showdown - where stock already fired it - this notify lands on nothing.
//
//  Timing margin is wide: level.winner is set, then stage_final waits 2s and a
//  further 5s before `level notify( "end_game" )`, which is this thread's endon.
// ============================================================================
zmqol_solo_ee_final_reward()
{
    level endon( "end_game" );

    level waittill( "stage_final" );

    while ( !isdefined( level.winner ) )
        wait 0.05;

    println( "[zm_qol] SOLO EASTER EGGS (Mob): ending reached, winner=" + level.winner + " - giving Pop Goes the Weasel" );
    level notify( "pop_goes_the_weasel_achieved" );
}
