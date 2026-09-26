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
//    2. A zombie cannot path through a window that still has a board up. It
//       has to tear the boards off first, the way stock's tear_into_building()
//       intends.
//    3. Carpenter can drop once a window is broken (see rule 3's banner).
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
    level thread zmqol_barriers_gate_windows();
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
//  RULE 2 - NO ZOMBIE PATHS THROUGH A WINDOW THAT STILL HAS A BOARD UP.
//
//  🌟 THE CAUSE, READ OFF STOCK. A window is a traversal link in the path
//  network: node_negotiation_begin outside, node_negotiation_end inside, joined
//  by the zm_mantle_over_40 vault (blocker_init() keeps them on the goal as
//  neg_start / neg_end). The boards never break that link: stock's
//  _zm_blockers::blocker_disconnect_paths() and blocker_connect_paths(), which
//  it calls every time a board is repaired or torn, are empty on T6.
//
//  So nothing but script flow keeps a zombie out of a boarded window. A zombie
//  sent anywhere on the far side of one - find_flesh on a player, a relocation,
//  Origins' capture-zone and escape goals - paths straight through the live
//  link and vaults past standing boards. The boards are not a wall either:
//  bullet traces pass 84-100% of the way through a fully boarded Church window
//  (2026-09-16).
//
//  🌟 THE FIX IS THE HALF STOCK LEFT EMPTY: while a window has any board up,
//  its traversal link is cut with unlinknodes(); when the last board comes off
//  it is relinked with linknodes(). With the link cut the only way in is
//  stock's - walk to the window, tear every board, climb.
//
//  🛑 THE CLIMB DOES NOT NEED THE LINK. zombie_goto_entrance()'s
//  zm_barricade_enter vault is animscripted() against the zbarrier, not a path
//  traversal, and it only runs after tear_into_building() returns - after the
//  last board is gone, which is exactly when the link comes back.
//
//  🛑 A WINDOW THAT A SPAWN POINT NEEDS IS NEVER CUT. Cutting a link that is
//  the only route from some zombie spawn to the players would strand that
//  zombie. zmqol_barriers_exempt() tests it with findpath() from every live
//  spawn location to a player, all windows cut against all linked, and exempts
//  the windows whose cut strands anything. It reruns whenever the set of live
//  spawn locations changes (a door or gate opens a zone). Church, measured:
//  14 spawns, 14 reach the player with all 12 windows cut - no exemptions.
// ============================================================================
zmqol_barriers_gate_windows()
{
    level endon( "end_game" );

    flag_wait( "start_zombie_round_logic" );
    wait 3;

    a_win = [];
    a_all = zmqol_barriers_windows();

    for ( i = 0; i < a_all.size; i++ )
    {
        if ( isdefined( a_all[i].neg_start ) && isdefined( a_all[i].neg_end ) )
            a_win[a_win.size] = a_all[i];
    }

    n_spawns_seen = -1;
    n_cut = 0;
    n_opened = 0;

    for ( ;; )
    {
        n_spawns = 0;

        if ( isdefined( level.zombie_spawn_locations ) )
            n_spawns = level.zombie_spawn_locations.size;

        if ( n_spawns != n_spawns_seen )
        {
            n_spawns_seen = n_spawns;
            zmqol_barriers_exempt( a_win );
        }

        for ( i = 0; i < a_win.size; i++ )
        {
            s_goal = a_win[i];

            if ( !isdefined( s_goal.zbarrier ) )
                continue;

            b_linked = nodesarelinked( s_goal.neg_start, s_goal.neg_end );
            b_cut = zmqol_barriers_boards_up( s_goal.zbarrier ) > 0 && !is_true( s_goal.zmqol_exempt );

            if ( b_cut && is_true( b_linked ) )
            {
                unlinknodes( s_goal.neg_start, s_goal.neg_end );
                n_cut++;
            }
            else if ( !b_cut && !is_true( b_linked ) )
            {
                linknodes( s_goal.neg_start, s_goal.neg_end );
                n_opened++;

                if ( n_opened <= 5 || n_opened % 25 == 0 )
                    println( "[zm_qol] BARRIERS: last board off " + s_goal.target + " - window open to zombies (" + n_opened + " so far, " + n_cut + " cuts)" );
            }
        }

        wait 0.5;
    }
}

//  Can zombies at every live spawn still reach a player? One flag per spawn.
zmqol_barriers_reach( a_spots, v_player )
{
    a_ok = [];

    for ( i = 0; i < a_spots.size; i++ )
    {
        a_ok[i] = 0;

        if ( isdefined( a_spots[i] ) && isdefined( a_spots[i].origin ) && findpath( a_spots[i].origin, v_player ) )
            a_ok[i] = 1;

        if ( i % 8 == 7 )
            wait 0.05;
    }

    return a_ok;
}

//  Number of spawns reachable in a_before that are not in a_after.
zmqol_barriers_lost( a_before, a_after )
{
    n = 0;

    for ( i = 0; i < a_before.size; i++ )
    {
        if ( a_before[i] && !a_after[i] )
            n++;
    }

    return n;
}

zmqol_barriers_set_links( a_win, s_only )
{
    for ( i = 0; i < a_win.size; i++ )
    {
        b_cut = !isdefined( s_only ) || a_win[i] == s_only;
        b_linked = is_true( nodesarelinked( a_win[i].neg_start, a_win[i].neg_end ) );

        if ( b_cut && b_linked )
            unlinknodes( a_win[i].neg_start, a_win[i].neg_end );
        else if ( !b_cut && !b_linked )
            linknodes( a_win[i].neg_start, a_win[i].neg_end );
    }
}

zmqol_barriers_link_all( a_win )
{
    for ( i = 0; i < a_win.size; i++ )
    {
        if ( !is_true( nodesarelinked( a_win[i].neg_start, a_win[i].neg_end ) ) )
            linknodes( a_win[i].neg_start, a_win[i].neg_end );
    }
}

zmqol_barriers_exempt( a_win )
{
    a_players = get_players();
    e_player = undefined;

    for ( i = 0; i < a_players.size; i++ )
    {
        if ( isdefined( a_players[i] ) && isalive( a_players[i] ) )
        {
            e_player = a_players[i];
            break;
        }
    }

    if ( !isdefined( e_player ) || !isdefined( level.zombie_spawn_locations ) || level.zombie_spawn_locations.size == 0 )
        return;

    a_spots = level.zombie_spawn_locations;
    v_player = e_player.origin;

    for ( i = 0; i < a_win.size; i++ )
        a_win[i].zmqol_exempt = undefined;

    //  Baseline with every window open to pathing, then with every one cut.
    zmqol_barriers_link_all( a_win );
    a_before = zmqol_barriers_reach( a_spots, v_player );
    zmqol_barriers_set_links( a_win, undefined );
    a_after = zmqol_barriers_reach( a_spots, v_player );

    n_reach = 0;

    for ( i = 0; i < a_before.size; i++ )
        n_reach = n_reach + a_before[i];

    n_lost = zmqol_barriers_lost( a_before, a_after );
    n_exempt = 0;

    //  Only if cutting everything strands someone: find the windows that do it
    //  on their own and leave those open to pathing.
    if ( n_lost > 0 )
    {
        for ( i = 0; i < a_win.size; i++ )
        {
            zmqol_barriers_set_links( a_win, a_win[i] );
            a_one = zmqol_barriers_reach( a_spots, v_player );

            if ( zmqol_barriers_lost( a_before, a_one ) > 0 )
            {
                a_win[i].zmqol_exempt = 1;
                n_exempt++;
                println( "[zm_qol] BARRIERS: " + a_win[i].target + " left open to pathing - a zombie spawn needs it to reach the player" );
            }
        }
    }

    //  The gate loop sets each link from board state on its next pass.
    zmqol_barriers_link_all( a_win );

    println( "[zm_qol] BARRIERS: " + getdvar( "ui_zm_mapstartlocation" ) + " - gating " + ( a_win.size - n_exempt ) + " of " + a_win.size + " windows on their boards; " + a_spots.size + " live spawns, " + n_reach + " reach a player, cutting every window would strand " + n_lost + ", exempt " + n_exempt );
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
