#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;

// ============================================================================
//  zmqol_barriers.gsc  -  SURVIVAL BARRIERS BEHAVE LIKE STOCK CLASSIC
//
//  User, 2026-09-26, on Docks and the Origins arenas: *"the barriers should all
//  be built at the start of the game ... make sure you're able to build them
//  ... the zombies behave completely normally stock base game"*, *"make sure
//  that carpenter works on each map"*, and on Origins survival *"zombies would
//  just climb straight through the barriers without breaking them first"*.
//
//  Three rules, every survival location on every map with window barriers:
//
//    1. Every window starts with all its boards up.
//    2. An inside path node is disabled while boards remain. Zombies can
//       reach the outside attack spots and must tear boards before entering.
//    3. Carpenter can drop once a window is broken.
//
//  Classic modes are untouched: init() returns unless ui_zm_gamemodegroup is
//  zsurvival. Record: modding-jobs\survival-barriers-001\FINDINGS.md.
//
//  Its own root script, not quality_of_life.gsc, which is full (AGENTS.md 1b).
// ============================================================================

init()
{
    if ( getdvar( "ui_zm_gamemodegroup" ) != "zsurvival" )
        return;

    level thread zmqol_barriers_build_all();
    level thread zmqol_barriers_gate_inside_nodes();
    level thread zmqol_barriers_carpenter_rule();
}

//  Boards still standing: every piece that is not "open" or "opening". This is
//  _zm_utility::all_chunks_destroyed()'s own test turned into a count.
zmqol_barriers_boards_up( e_zb )
{
    n = e_zb getnumzbarrierpieces();
    n = n - e_zb getzbarrierpieceindicesinstate( "open" ).size;
    n = n - e_zb getzbarrierpieceindicesinstate( "opening" ).size;
    return n;
}

//  Every exterior_goal that still has its zbarrier and its traversal pair.
//  Cell Block's grief setup deletes the zbarriers outside its arena; a deleted
//  entity reads undefined, so those windows drop out here.
zmqol_barriers_windows()
{
    a_win = [];

    if ( !isdefined( level.exterior_goals ) )
        return a_win;

    for ( i = 0; i < level.exterior_goals.size; i++ )
    {
        s_goal = level.exterior_goals[i];

        if ( !isdefined( s_goal ) || !isdefined( s_goal.zbarrier ) )
            continue;

        a_win[a_win.size] = s_goal;
    }

    return a_win;
}

// ============================================================================
//  RULE 1 - EVERY WINDOW STARTS BUILT.
//
//  Two things knocked the boards down at game start:
//
//    - Mob (Docks, Cell Block): stock zm_prison::main() threads
//      zm_alcatraz_utility::drop_all_barriers() in every mode. It opens and
//      hides every board outside zone_start / zone_library - the classic intro,
//      where the prison is meant to look wrecked. zm_prison.gsc now replaces it
//      with a version that does nothing in survival (BO2-Reimagined empties it
//      for the same reason).
//    - Origins (Church, Trenches, Excavation Site, The Crazy Place):
//      zm_tomb.gsc::zmqol_disable_survival_barriers() opened every board and
//      set level.no_board_repair. It is removed.
//
//  This is the belt to those braces: after round logic starts it closes any
//  window that is still open. The repair is stock's own per-window body of
//  _zm_powerups::repair_far_boards() - the Carpenter power-up - for an
//  un-upgraded Carpenter. Collision, attack spots and the rebuild trigger were
//  already set up for every window by _zm_blockers::blocker_init().
//
//  Measured before the change, Church 2026-09-26: all 12 windows 0/6 at round
//  1, never rebuilt (survival-barriers-001\probe-church-01.txt).
// ============================================================================
zmqol_barriers_build_all()
{
    flag_wait( "start_zombie_round_logic" );
    wait 2;

    a_win = zmqol_barriers_windows();
    n_rebuilt = 0;

    for ( i = 0; i < a_win.size; i++ )
    {
        e_zb = a_win[i].zbarrier;
        a_open = e_zb getzbarrierpieceindicesinstate( "open" );

        if ( a_open.size > 0 )
            n_rebuilt++;

        for ( j = 0; j < a_open.size; j++ )
        {
            e_zb zbarrierpieceusedefaultmodel( a_open[j] );

            if ( isdefined( e_zb.chunk_health ) )
                e_zb.chunk_health[ a_open[j] ] = 0;
        }

        for ( j = 0; j < e_zb getnumzbarrierpieces(); j++ )
        {
            e_zb setzbarrierpiecestate( j, "closed" );
            e_zb showzbarrierpiece( j );
        }

        if ( i % 4 == 0 )
            wait_network_frame();
    }

    wait 1;

    //  Read the boards back rather than report intent.
    n_full = 0;

    for ( i = 0; i < a_win.size; i++ )
    {
        if ( zmqol_barriers_boards_up( a_win[i].zbarrier ) == a_win[i].zbarrier getnumzbarrierpieces() )
            n_full++;
    }

    println( "[zm_qol] BARRIERS: " + getdvar( "ui_zm_mapstartlocation" ) + " - " + n_full + " of " + a_win.size + " windows fully boarded at start (rebuilt " + n_rebuilt + " that were open)" );
}

// ============================================================================
//  RULE 2 - KEEP THE INSIDE PATH NODE CLOSED WHILE BOARDS STAND.
//
//  T6's blocker_disconnect_paths() does nothing, and unlinknodes() did not
//  disconnect the window pair in the live Church test. Disabling both nodes
//  blocked the outside approach to the window. The inside node alone worked:
//  findpath(outside, inside) changed from 1 to 0 while the outside goal and
//  all three attack spots stayed reachable. The temporary endgate probe then
//  observed normal board tears and zero-board vault entries on Church and
//  Docks. See survival-barriers-001/live-*-endgate-final.log.
//
//  Stock zombie_goto_entrance() calls tear_into_building() before its scripted
//  vault. The vault does not use the path node. Re-enable the inside node as
//  soon as the last board opens, and close it again when Carpenter or a player
//  rebuilds the window.
// ============================================================================
zmqol_barriers_gate_inside_nodes()
{
    level endon( "end_game" );
    flag_wait( "start_zombie_round_logic" );
    wait 2;

    a_win = [];
    a_all = zmqol_barriers_windows();

    for ( i = 0; i < a_all.size; i++ )
    {
        if ( !isdefined( a_all[i].neg_end ) )
            continue;

        a_all[i].zmqol_inside_node_disabled = 0;
        a_win[a_win.size] = a_all[i];
    }

    println( "[zm_qol] BARRIERS: gating inside nodes on " + a_win.size + " windows in " + getdvar( "ui_zm_mapstartlocation" ) );

    for ( ;; )
    {
        for ( i = 0; i < a_win.size; i++ )
        {
            s_goal = a_win[i];

            if ( !isdefined( s_goal.zbarrier ) )
            {
                if ( s_goal.zmqol_inside_node_disabled )
                {
                    setenablenode( s_goal.neg_end, 1 );
                    s_goal.zmqol_inside_node_disabled = 0;
                }

                continue;
            }

            n_up = zmqol_barriers_boards_up( s_goal.zbarrier );

            if ( n_up > 0 && !s_goal.zmqol_inside_node_disabled )
            {
                setenablenode( s_goal.neg_end, 0 );
                s_goal.zmqol_inside_node_disabled = 1;
            }
            else if ( n_up == 0 && s_goal.zmqol_inside_node_disabled )
            {
                setenablenode( s_goal.neg_end, 1 );
                s_goal.zmqol_inside_node_disabled = 0;
            }
        }

        wait 0.1;
    }
}

// ============================================================================
//  RULE 3 - CARPENTER DROPS IN SURVIVAL.
//
//  Stock's rule, _zm_powerups::func_should_drop_carpenter(), is "at least five
//  windows fully torn" across the WHOLE map. A survival arena reaches only the
//  windows around it - Church two, Docks two - so on those arenas five can
//  never happen and Carpenter never drops. Survival asks for one: as soon as
//  any window is fully open, Carpenter is in the random pool like any other
//  power-up. Classic keeps stock's five.
//
//  Registration is the maps' job, not this file's: TranZit, Die Rise and
//  Buried register it natively; Origins (zm_tomb.gsc) and Mob (zm_prison.gsc)
//  register it from their map scripts. Nuketown has no window barriers and no
//  Carpenter. This only swaps the drop rule, the same way quality_of_life.gsc
//  swaps Fire Sale's.
// ============================================================================
zmqol_barriers_carpenter_rule()
{
    flag_wait( "start_zombie_round_logic" );

    if ( !isdefined( level.zombie_powerups ) || !isdefined( level.zombie_powerups["carpenter"] ) )
    {
        println( "[zm_qol] CARPENTER: not registered on " + getdvar( "mapname" ) + " - no barriers to repair here" );
        return;
    }

    level.zombie_powerups["carpenter"].func_should_drop_with_regular_powerups = ::zmqol_barriers_should_drop_carpenter;
    println( "[zm_qol] CARPENTER: registered on " + getdvar( "mapname" ) + "/" + getdvar( "ui_zm_mapstartlocation" ) + ", drops once any window is fully broken" );
}

zmqol_barriers_should_drop_carpenter()
{
    return maps\mp\zombies\_zm_powerups::get_num_window_destroyed() >= 1;
}
