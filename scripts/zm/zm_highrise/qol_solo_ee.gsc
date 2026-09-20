// ============================================================================
//  qol_solo_ee.gsc  (Die Rise)  -  SOLO EASTER EGGS
// ----------------------------------------------------------------------------
//  LOCATION INSIDE mod.iwd:
//      scripts/zm/zm_highrise/qol_solo_ee.gsc
//
//  Adapted from Hadi77KSA's "Plutonium T6 Any Player EE Scripts" v2.4.1
//  (die_rise_any_player_ee.gsc), on the user's instruction of 2026-09-06.
//
//  WHAT IT CHANGES, step by step:
//
//    NAV TABLE. Built automatically if nobody in the lobby has ever started
//      Die Rise's quest, because both branches below are unreachable without
//      it. Turn it off with `set any_player_ee_highrise_nav 0`.
//
//    ELEVATOR STEP ("An Ascending Fate"). Wants one player per elevator symbol
//      - four of them - which one player cannot stand on. Now wants exactly as
//      many as there are players. Dvar: any_player_ee_highrise_elevators.
//
//    DRAGON PUZZLE (the floor symbols). Same: as many symbols as players, and
//      it resets back to that count rather than to four when failed. Dvar:
//      any_player_ee_highrise_drg_puzzle.
//
//    TRAMPLE STEAM STEP, MAXIS SIDE. Solo (and 3-player once the first ball is
//      already flinging) needs only ONE Trample Steam to place a ball; below
//      four players both balls may go on the same set of symbols. Dvars:
//      any_player_ee_highrise_maxis_pts_1p / _3p / _ignore_has_ball.
//
//    TRAMPLE STEAM STEP, RICHTOFEN SIDE. Needs Trample Steams on as many
//      symbols as there are players instead of all four. Dvar:
//      any_player_ee_highrise_rich_pts.
//
//  IT DOES NOTHING UNLESS THE LOBBY ROW SAYS SO. `solo_ee` is written by the
//  SOLO EASTER EGGS row in ui_mp/t6/menus/privategamelobby_project.lua and
//  defaults to 0, so a player who never touches the row gets stock behaviour.
//
//  ============================== THE TWO TRAPS ==============================
//
//  1. NO #define (AI_CONTEXT.md golden rule 1). The source script is built out
//     of SEVEN macros - CHECK_OVERRIDE, NOOP, SQ_2_PLACE_BALL_TRIGGER_CLEANUP,
//     SQ_2_PLACE_BALL_THINK, SQ_2_TRAMPLE_STEAM_CREATE_TRIGS,
//     SQ_2_TRAMPLE_STEAM_BUDDY_ELSE_LOGIC and SQ_2_TRAMPLE_STEAM_CHECKS, the
//     last of which takes two more macros as ARGUMENTS. Every one is expanded
//     by hand below and the expansion sites are commented, because the two
//     call sites of SQ_2_TRAMPLE_STEAM_CHECKS pass different macros and
//     therefore compile to genuinely different code:
//         qol_pts_should_player_create_trigs   passes NOOP, NOOP
//         qol_pts_should_springpad_create_trigs passes the buddy-else block
//                                              and the buddy place-ball think
//     Only CHECK_OVERRIDE's iPrintLn debug spam is dropped; the live re-read of
//     each tuning dvar is kept, so console tuning still works mid-match.
//
//  2. EVERY LOCAL FUNCTION IS PREFIXED qol_, AND THAT IS LOAD-BEARING. This
//     file includes maps\mp\zm_highrise_sq_pts, and SEVEN of the source
//     script's function names also exist in it: place_ball_think,
//     pts_putdown_trigs_create_for_spot, pts_watch_springpad_use,
//     is_springpad_in_place, wait_for_all_springpads_placed,
//     pts_should_player_create_trigs and pts_should_springpad_create_trigs -
//     several with DIFFERENT argument counts. The source relies on a local
//     definition shadowing the included one, while still reaching the stock
//     copies of two of them through explicit maps\mp\zm_highrise_sq_pts::
//     calls. Prefixing makes each of those choices explicit rather than
//     positional. Deliberately NOT prefixed, because they are stock and only
//     stock: sq_pts_create_use_trigger, pts_putdown_trigs_remove_for_spot and
//     pts_putdown_trigs_springpad_delete_watcher.
//
//  The dvar is read after flag_wait( "initial_players_connected" ) - three
//  seconds ahead of "start_zombie_round_logic", which is what every thread
//  here waits on - so the lobby's write has certainly landed. See the TranZit
//  copy of this file for the measurement.
// ============================================================================

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zm_highrise_sq_pts;

init()
{
    if ( !maps\mp\zombies\_zm_sidequests::is_sidequest_allowed( "zclassic" ) )
        return;

    thread qol_solo_ee_gate();
}

qol_solo_ee_gate()
{
    flag_wait( "initial_players_connected" );

    if ( getdvarintdefault( "solo_ee", 0 ) != 1 )
    {
        println( "[zm_qol] SOLO EASTER EGGS: off (Die Rise)" );
        return;
    }

    println( "[zm_qol] SOLO EASTER EGGS: on (Die Rise - nav table, elevators, dragon puzzle, trample steams)" );

    if ( set_dvar_int_if_unset( "any_player_ee_highrise_nav", "1" ) )
        thread qol_spawn_navcomputer();

    thread qol_sidequest_main();
}

//  Force-build the Nav Table. Skipped if anybody in the lobby has already
//  started the quest on their own account, so a legitimate build is never
//  short-circuited.
qol_spawn_navcomputer()
{
    level.navcomputer_spawned = true;
    flag_wait( "start_zombie_round_logic" );
    waittillframeend;
    b_spawn_navcomputer = false;
    players = get_players();

    for ( i = players.size - 1; i >= 0; i-- )
    {
        if ( !players[i] maps\mp\zombies\_zm_stats::get_global_stat( "sq_highrise_started" ) )
        {
            b_spawn_navcomputer = true;
            break;
        }
    }

    if ( !b_spawn_navcomputer )
        return;

    gethostplayer() maps\mp\zombies\_zm_buildables::player_finish_buildable( level.sq_buildable.buildablezone );

    if ( isdefined( level.sq_buildable ) && isdefined( level.sq_buildable.model ) )
    {
        buildable = level.sq_buildable.buildablezone;

        for ( i = 0; i < buildable.pieces.size; i++ )
        {
            if ( isdefined( buildable.pieces[i].model ) )
            {
                buildable.pieces[i].model delete();
                maps\mp\zombies\_zm_unitrigger::unregister_unitrigger( buildable.pieces[i].unitrigger );
            }

            if ( isdefined( buildable.pieces[i].part_name ) )
            {
                buildable.stub.model notsolid();
                buildable.stub.model show();
                buildable.stub.model showpart( buildable.pieces[i].part_name );
            }
        }
    }
}

qol_sidequest_main()
{
    flag_wait( "start_zombie_round_logic" );
    waittillframeend;

    if ( level.maxcompleted && level.richcompleted )
        return;

    flag_wait( "power_on" );
    flag_wait( "sq_nav_built" );
    thread qol_atd();
    level waittill( "sq_slb_over" );

    if ( !level.richcompleted )
        thread qol_sq_1();

    if ( !level.maxcompleted )
        thread qol_sq_2();
}

//  The number of players, capped at four. is_generator 0 uses the snapshot
//  taken when the Richtofen step began, so a mid-step disconnect cannot make
//  the requirement rise.
qol_num_player_valid( is_generator )
{
    numplayers = level.players.size;

    if ( isdefined( is_generator ) && !is_generator && isdefined( level.pts_ghoul ) )
        numplayers = level.pts_ghoul;

    return int( min( numplayers, 4 ) );
}

qol_atd()
{
    qol_sq_atd_elevators();
    flag_wait( "sq_atd_elevator_activated" );

    while ( !isdefined( level.sq_atd_cur_drg ) )
    {
        wait 0.25;
        waittillframeend;
    }

    qol_sq_atd_drg_puzzle();

    if ( getdvarintdefault( "any_player_ee_highrise_drg_puzzle", qol_num_player_valid() ) < 4 )
    {
        remove = false;

        if ( !flag( "sq_atd_drg_puzzle_1st_error" ) )
        {
            flag_set( "sq_atd_drg_puzzle_1st_error" );
            remove = true;
        }

        a_puzzle_trigs = getentarray( "trig_atd_drg_puzzle", "targetname" );

        for ( i = a_puzzle_trigs.size - 1; i >= 0; i-- )
        {
            if ( !a_puzzle_trigs[i].drg_active )
            {
                m_unlit = getent( a_puzzle_trigs[i].target, "targetname" );
                v_hidden = m_unlit.lit_icon.origin;
                m_unlit.lit_icon.origin = m_unlit.origin;
                m_unlit.origin = v_hidden;
                a_puzzle_trigs[i] notify( "trigger", gethostplayer() );
                waittillframeend;
                level.sq_atd_cur_drg = 4;
            }
        }

        if ( remove )
            flag_clear( "sq_atd_drg_puzzle_1st_error" );
    }
}

// ----------------------------------------------------------------------------
//  ELEVATOR STAND STEP  -  as many symbols as players, not four
// ----------------------------------------------------------------------------
qol_sq_atd_elevators()
{
    a_elevator_flags = array( "sq_atd_elevator0", "sq_atd_elevator1", "sq_atd_elevator2", "sq_atd_elevator3" );
    n_required = getdvarintdefault( "any_player_ee_highrise_elevators", -1 );

    while ( flag( a_elevator_flags[0] ) + flag( a_elevator_flags[1] ) + flag( a_elevator_flags[2] ) + flag( a_elevator_flags[3] ) < ( ( n_required > -1 ) ? n_required : qol_num_player_valid() ) )
    {
        flag_wait_any_array( a_elevator_flags );
        wait 0.5;
        n_required = getdvarintdefault( "any_player_ee_highrise_elevators", -1 );
    }

    for ( i = a_elevator_flags.size - 1; i >= 0; i-- )
    {
        if ( !flag( a_elevator_flags[i] ) )
            flag_set( a_elevator_flags[i] );
    }
}

// ----------------------------------------------------------------------------
//  DRAGON PUZZLE  -  as many floor symbols as players, and it resets to that
// ----------------------------------------------------------------------------
qol_sq_atd_drg_puzzle()
{
    level endon( "sq_atd_drg_puzzle_complete" );

    for (;;)
    {
        n_required = getdvarintdefault( "any_player_ee_highrise_drg_puzzle", -1 );
        level.sq_atd_cur_drg = 4 - ( ( n_required > -1 ) ? n_required : qol_num_player_valid() );
        level waittill( "drg_puzzle_reset" );
    }
}

// ----------------------------------------------------------------------------
//  TRAMPLE STEAM STEPS
// ----------------------------------------------------------------------------
qol_sq_1()
{
    level endon( "sq_ball_picked_up" );
    level waittill( "sq_1" + "_" + "pts_1" + "_started" );
    players = get_players();
    level.pts_ghoul = players.size;

    for ( i = players.size - 1; i >= 0; i-- )
        players[i] thread qol_on_player_disconnect( 0 );

    qol_wait_for_all_springpads_placed();
    level.pts_ghoul = undefined;
}

qol_sq_2()
{
    level waittill( "sq_2" + "_" + "pts_2" + "_started" );
    players = get_players();
    level.pts_lion = players.size;

    for ( i = players.size - 1; i >= 0; i-- )
    {
        players[i] thread qol_on_player_disconnect( 1 );
        players[i] thread qol_pts_watch_springpad_use();
    }

    thread qol_on_pick_up();
}

qol_on_player_disconnect( is_generator )
{
    if ( !is_generator )
        level endon( "pts_1_springpads_placed" );

    self waittill( "disconnect" );

    if ( is_generator )
    {
        if ( isdefined( level.pts_lion ) )
            level.pts_lion--;
    }
    else
    {
        if ( isdefined( level.pts_ghoul ) )
            level.pts_ghoul--;
    }
}

//  Below four players, keeps the place-a-ball trigger alive on the Trample
//  Steam a ball was just placed on AND on the one opposite it. At three
//  players, also lets anyone already carrying a ball use the lone Trample
//  Steam if it was placed correctly before the first ball launched.
qol_place_ball_think( t_place_ball, s_lion_spot )
{
    t_place_ball endon( "delete" );
    which_ball = s_lion_spot.which_ball;
    which_generator = s_lion_spot.which_generator;
    t_place_ball waittill( "trigger" );
    remove = false;

    if ( !isdefined( s_lion_spot.springpad_buddy.springpad ) )
    {
        s_lion_spot.springpad_buddy.springpad = s_lion_spot.springpad;
        remove = true;
    }

    waittillframeend;

    if ( remove )
        s_lion_spot.springpad_buddy.springpad = undefined;

    if ( isdefined( which_ball ) && isdefined( level.pts_lion ) && ( level.pts_lion < 4 || level.pts_lion == getdvarintdefault( "any_player_ee_highrise_maxis_pts_1p", 1 ) || level.pts_lion == getdvarintdefault( "any_player_ee_highrise_maxis_pts_3p", 3 ) ) )
    {
        s_lion_spot.springpad_buddy.which_ball = which_ball;
        s_lion_spot.springpad_buddy.which_generator = which_generator;
        m_ball_anim = getentarray( "trample_gen_" + s_lion_spot.script_noteworthy, "targetname" )[0];
        m_ball_anim.targetname = "trample_gen_" + s_lion_spot.springpad_buddy.script_noteworthy;
    }

    level thread qol_pts_should_springpad_create_trigs( s_lion_spot );

    //  Once a ball is flinging, give every player still carrying one the
    //  ability to place it on the Trample Steam on the OTHER set of symbols.
    if ( isdefined( level.pts_lion ) && level.pts_lion == getdvarintdefault( "any_player_ee_highrise_maxis_pts_3p", 3 ) && isdefined( s_lion_spot.springpad_buddy.springpad ) )
    {
        a_lion_spots = getstructarray( "pts_lion", "targetname" );

        for ( i = a_lion_spots.size - 1; i >= 0; i-- )
        {
            if ( a_lion_spots[i] != s_lion_spot && a_lion_spots[i].springpad_buddy != s_lion_spot && !isdefined( a_lion_spots[i].springpad_buddy.springpad ) )
            {
                //  --- SQ_2_PLACE_BALL_TRIGGER_CLEANUP( a_lion_spots[i] ) ---
                if ( isdefined( a_lion_spots[i].pts_putdown_trigs ) && a_lion_spots[i].pts_putdown_trigs.size > 0 )
                {
                    foreach ( t_putdown in a_lion_spots[i].pts_putdown_trigs )
                        t_putdown notify( "delete" );

                    pts_putdown_trigs_remove_for_spot( a_lion_spots[i] );
                }
                //  --- end expansion ---

                level thread qol_pts_should_springpad_create_trigs( a_lion_spots[i] );
                break;
            }
        }
    }
}

//  RICHTOFEN SIDE: as many Trample Steams as players, not all four.
qol_wait_for_all_springpads_placed()
{
    a_spots = getstructarray( "pts_ghoul", "targetname" );
    n_required = getdvarintdefault( "any_player_ee_highrise_rich_pts", -1 );

    while ( !flag( "pts_1_springpads_placed" ) )
    {
        is_clear = 0;
        n_required = getdvarintdefault( "any_player_ee_highrise_rich_pts", -1 );

        for ( i = a_spots.size - 1; i >= 0; i-- )
        {
            if ( !isdefined( a_spots[i].springpad ) )
                is_clear++;
        }

        if ( is_clear <= 4 - ( ( n_required > -1 ) ? n_required : qol_num_player_valid( 0 ) ) )
            flag_set( "pts_1_springpads_placed" );

        wait 1;
    }
}

qol_pts_watch_springpad_use()
{
    self endon( "death" );
    self endon( "disconnect" );

    while ( !flag( "sq_branch_complete" ) )
    {
        self waittill( "equipment_placed", weapon, weapname );

        if ( weapname == level.springpad_name )
            self qol_is_springpad_in_place( weapon );
    }
}

qol_is_springpad_in_place( m_springpad )
{
    a_lion_spots = getstructarray( "pts_lion", "targetname" );

    for ( i = a_lion_spots.size - 1; i >= 0; i-- )
    {
        if ( distance2dsquared( m_springpad.origin, a_lion_spots[i].origin ) < 1024 )
        {
            v_spot_forward = vectornormalize( anglestoforward( a_lion_spots[i].angles ) );
            v_pad_forward = vectornormalize( anglestoforward( m_springpad.angles ) );
            n_dot = vectordot( v_spot_forward, v_pad_forward );

            if ( n_dot > 0.98 )
            {
                //  --- SQ_2_PLACE_BALL_TRIGGER_CLEANUP( a_lion_spots[i] ) ---
                if ( isdefined( a_lion_spots[i].pts_putdown_trigs ) && a_lion_spots[i].pts_putdown_trigs.size > 0 )
                {
                    foreach ( t_putdown in a_lion_spots[i].pts_putdown_trigs )
                        t_putdown notify( "delete" );

                    pts_putdown_trigs_remove_for_spot( a_lion_spots[i] );
                }

                //  --- SQ_2_PLACE_BALL_TRIGGER_CLEANUP( a_lion_spots[i].springpad_buddy ) ---
                if ( isdefined( a_lion_spots[i].springpad_buddy.pts_putdown_trigs ) && a_lion_spots[i].springpad_buddy.pts_putdown_trigs.size > 0 )
                {
                    foreach ( t_putdown_buddy in a_lion_spots[i].springpad_buddy.pts_putdown_trigs )
                        t_putdown_buddy notify( "delete" );

                    pts_putdown_trigs_remove_for_spot( a_lion_spots[i].springpad_buddy );
                }
                //  --- end expansions ---

                wait 0.1;
                level thread qol_pts_should_springpad_create_trigs( a_lion_spots[i] );
                break;
            }
        }
    }
}

qol_on_pick_up()
{
    for (;;)
    {
        level waittill( "zm_ball_picked_up", player );
        thread qol_pts_should_player_create_trigs( player );
    }
}

//  MAXIS SIDE, solo or 3p: once the player picks up a ball, let them place it
//  on an already correctly placed Trample Steam without one on the opposite
//  end. At 3p this only applies while a ball is already flinging.
//
//  --- SQ_2_TRAMPLE_STEAM_CHECKS( player, a_lion_spots[i], NOOP, NOOP ) ---
//  Both macro arguments are NOOP here, so the buddy-side branches expand to
//  nothing. Compare qol_pts_should_springpad_create_trigs below, which passes
//  real macros into the same two slots.
qol_pts_should_player_create_trigs( player )
{
    waittillframeend;
    a_lion_spots = getstructarray( "pts_lion", "targetname" );
    n_1p = getdvarintdefault( "any_player_ee_highrise_maxis_pts_1p", 1 );
    n_3p = getdvarintdefault( "any_player_ee_highrise_maxis_pts_3p", 3 );

    for ( i = a_lion_spots.size - 1; i >= 0; i-- )
    {
        if ( !isdefined( a_lion_spots[i].springpad ) )
            continue;

        s_lion_spot = a_lion_spots[i];

        if ( isdefined( level.pts_lion ) && ( level.pts_lion < 4 || level.pts_lion == n_1p || level.pts_lion == n_3p ) )
        {
            if ( isdefined( s_lion_spot.springpad_buddy.springpad ) || level.pts_lion == n_1p || ( level.pts_lion == n_3p && flag( "pts_2_generator_1_started" ) && !isdefined( s_lion_spot.which_ball ) && !isdefined( s_lion_spot.springpad_buddy.which_ball ) ) )
            {
                if ( !isdefined( s_lion_spot.springpad_buddy.springpad ) )
                    maps\mp\zm_highrise_sq_pts::pts_putdown_trigs_create_for_spot( s_lion_spot, player );

                //  NOOP - no buddy-else branch at this call site.

                qol_pts_putdown_trigs_create_for_spot( s_lion_spot, player );

                if ( isdefined( s_lion_spot.pts_putdown_trigs[player.characterindex] ) )
                    player thread qol_place_ball_think( s_lion_spot.pts_putdown_trigs[player.characterindex], s_lion_spot );
            }
        }
        else if ( isdefined( s_lion_spot.springpad_buddy.springpad ) && !isdefined( s_lion_spot.which_ball ) && !isdefined( s_lion_spot.springpad_buddy.which_ball ) )
        {
            if ( isdefined( s_lion_spot.pts_putdown_trigs[player.characterindex] ) )
                player thread qol_place_ball_think( s_lion_spot.pts_putdown_trigs[player.characterindex], s_lion_spot );

            //  NOOP - no buddy place-ball think at this call site.
        }
    }
}

//  MAXIS SIDE, solo or 3p: once a Trample Steam is placed correctly, give every
//  player already carrying a ball the ability to place it without one on the
//  opposite end. At 3p this only applies while a ball is already flinging.
//
//  --- SQ_2_TRAMPLE_STEAM_CHECKS( level.players[i], s_lion_spot,
//        SQ_2_TRAMPLE_STEAM_BUDDY_ELSE_LOGIC, SQ_2_PLACE_BALL_THINK ) ---
//  Unlike the call site above, BOTH buddy slots carry real code here: the
//  else-branch creates the buddy's triggers, and the second slot threads a
//  place-ball think on the buddy spot.
qol_pts_should_springpad_create_trigs( s_lion_spot )
{
    waittillframeend;

    if ( !isdefined( s_lion_spot.springpad ) || !isdefined( s_lion_spot.springpad_buddy ) )
        return;

    n_1p = getdvarintdefault( "any_player_ee_highrise_maxis_pts_1p", 1 );
    n_3p = getdvarintdefault( "any_player_ee_highrise_maxis_pts_3p", 3 );

    for ( i = level.players.size - 1; i >= 0; i-- )
    {
        if ( !isdefined( level.players[i].zm_sq_has_ball ) || !level.players[i].zm_sq_has_ball )
            continue;

        player = level.players[i];
        s_buddy = s_lion_spot.springpad_buddy;

        if ( isdefined( level.pts_lion ) && ( level.pts_lion < 4 || level.pts_lion == n_1p || level.pts_lion == n_3p ) )
        {
            if ( isdefined( s_buddy.springpad ) || level.pts_lion == n_1p || ( level.pts_lion == n_3p && flag( "pts_2_generator_1_started" ) && !isdefined( s_lion_spot.which_ball ) && !isdefined( s_buddy.which_ball ) ) )
            {
                if ( !isdefined( s_buddy.springpad ) )
                    maps\mp\zm_highrise_sq_pts::pts_putdown_trigs_create_for_spot( s_lion_spot, player );
                else
                {
                    //  SQ_2_TRAMPLE_STEAM_BUDDY_ELSE_LOGIC( player, s_buddy )
                    qol_pts_putdown_trigs_create_for_spot( s_buddy, player );

                    if ( isdefined( s_buddy.pts_putdown_trigs[player.characterindex] ) )
                        player thread qol_place_ball_think( s_buddy.pts_putdown_trigs[player.characterindex], s_buddy );
                }

                qol_pts_putdown_trigs_create_for_spot( s_lion_spot, player );

                if ( isdefined( s_lion_spot.pts_putdown_trigs[player.characterindex] ) )
                    player thread qol_place_ball_think( s_lion_spot.pts_putdown_trigs[player.characterindex], s_lion_spot );
            }
        }
        else if ( isdefined( s_buddy.springpad ) && !isdefined( s_lion_spot.which_ball ) && !isdefined( s_buddy.which_ball ) )
        {
            if ( isdefined( s_lion_spot.pts_putdown_trigs[player.characterindex] ) )
                player thread qol_place_ball_think( s_lion_spot.pts_putdown_trigs[player.characterindex], s_lion_spot );

            //  SQ_2_PLACE_BALL_THINK( player, s_buddy )
            if ( isdefined( s_buddy.pts_putdown_trigs[player.characterindex] ) )
                player thread qol_place_ball_think( s_buddy.pts_putdown_trigs[player.characterindex], s_buddy );
        }
    }
}

//  Three players or fewer: once a ball is picked up, allow a SECOND ball on a
//  set of Trample Steams that already has one flinging from it.
//
//  sq_pts_create_use_trigger(), maps\mp\zm_highrise_sq_pts::place_ball_think()
//  and pts_putdown_trigs_springpad_delete_watcher() are all STOCK and are
//  called as stock on purpose - only the trigger book-keeping is ours.
qol_pts_putdown_trigs_create_for_spot( s_lion_spot, player )
{
    b_ignore_has_ball = getdvarintdefault( "any_player_ee_highrise_maxis_pts_ignore_has_ball", 1 );

    if ( !( isdefined( s_lion_spot.which_ball ) || isdefined( s_lion_spot.springpad_buddy ) && isdefined( s_lion_spot.springpad_buddy.which_ball ) ) || !b_ignore_has_ball )
        return;

    t_place_ball = sq_pts_create_use_trigger( s_lion_spot.origin, 16, 70, &"ZM_HIGHRISE_SQ_PUTDOWN_BALL" );
    player clientclaimtrigger( t_place_ball );
    t_place_ball.owner = player;
    player thread maps\mp\zm_highrise_sq_pts::place_ball_think( t_place_ball, s_lion_spot );

    if ( !isdefined( s_lion_spot.pts_putdown_trigs ) )
        s_lion_spot.pts_putdown_trigs = [];

    s_lion_spot.pts_putdown_trigs[player.characterindex] = t_place_ball;
    level thread pts_putdown_trigs_springpad_delete_watcher( player, s_lion_spot );
}
