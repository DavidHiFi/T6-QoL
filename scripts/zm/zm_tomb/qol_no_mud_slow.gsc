// ============================================================================
//  qol_no_mud_slow.gsc  (Origins)  -  NO MUD SLOWDOWN, the GAME 3 tab row
// ----------------------------------------------------------------------------
//  LOCATION INSIDE mod.iwd:
//      scripts/zm/zm_tomb/qol_no_mud_slow.gsc
//
//  User, 2026-09-15: *"add an option in game 3 where you can turn on or off the
//  mud slow down in origins ... a lot of people hate that the mud slows you
//  down ... add an option so that the mud doesn't affect you in origins and any
//  maps so even the survival maps as well, that way players can run their
//  normal speed and walk their normal speed in mud."*
//
//  OFF (0) = stock: the mud drags you to 0.6 move speed, 0.7 with Stamin-Up.
//  ON  (1) = the mud is scenery. Full run and walk speed, no struggle VO, no
//            squelch loop.
//
//  ⭐ MUD IS ORIGINS AND ONLY ORIGINS. Grepping the whole 2,093-file stock
//  script dump for "player_slow_area" returns exactly one line, and grepping
//  for setmovespeedscale finds no other mud-like volume on any map. So "any
//  maps ... even the survival maps" is already satisfied by a file that loads
//  on Origins alone: every Origins survival and grief location runs this same
//  zm_tomb script and reads this same array. Nothing is missing on the other
//  maps - there is no mud on them to switch off.
//
//  🌟 IT EMPTIES THE LIST OF MUD VOLUMES RATHER THAN FIGHTING THE SPEED.
//  Stock's per-player monitor is maps\mp\zm_tomb_utility.gsc:233,
//  player_slow_movement_speed_monitor(), threaded for every player from
//  zm_tomb.gsc:466 on_player_connect(). Every 0.1s it walks
//  level.a_e_slow_areas, and when the player is touching none of them it takes
//  its own release path:
//
//      self setclientfieldtoplayer( "sndMudSlow", 0 );
//      self notify( "mud_slowdown_cleared" );
//      n_new_move_scale = 1.0;
//
//  Handing it an empty array therefore does not just skip the slow - it makes
//  stock itself undo the slow, clear the client field that drives the squelch
//  loop (registered in zm_tomb_craftables.gsc:377, consumed by
//  zm_tomb_amb.csc:203) and fire the notify that zm_tomb_vo.gsc:639 is waiting
//  on to end the struggle VO. One switch, and all four of the mud's effects go
//  with it, through the map's own code.
//
//  🛑 DELIBERATELY NOT A replaceFunc ON THE MONITOR. Copying that function to
//  add one `if` would fork the Stamin-Up branch, the ramp-down deltas and the
//  VO gating into this mod forever, for a row whose whole job is to make the
//  loop find nothing. The array is the seam; the function is not.
//
//  🌟 THE ARRAY HAS EXACTLY TWO READERS IN THE GAME, both quoted above - the
//  one write at zm_tomb.gsc:243 and the one read in the monitor. That was
//  checked before choosing this seam, not assumed: nothing else in the stock
//  dump or in this mod touches level.a_e_slow_areas, so emptying it has no
//  second effect to inherit.
//
//  📝 LIVE IN BOTH DIRECTIONS, like every other row in this menu. The monitor
//  re-reads the array every 0.1s, so switching the row on frees a player who is
//  already stuck in mud within a tenth of a second, and switching it back off
//  slows them again where they stand. The original array is kept in
//  level.zmqol_mud_areas and put back untouched - the volumes are never
//  deleted, so nothing has to be respawned to restore stock behaviour.
// ============================================================================

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;

init()
{
    thread qol_no_mud_slow_watch();
}

qol_no_mud_slow_watch()
{
    level endon( "end_game" );

    //  zm_tomb::main() fills the array at its line 243, long before any player
    //  connects, so by this flag the real list is always in hand.
    flag_wait( "initial_players_connected" );

    if ( !isdefined( level.a_e_slow_areas ) )
    {
        println( "[zm_qol] NO MUD SLOWDOWN: no mud volumes on this map - nothing to do" );
        return;
    }

    level.zmqol_mud_areas = level.a_e_slow_areas;

    n_applied = -1;

    for ( ;; )
    {
        n_want = 0;

        if ( getdvarintdefault( "no_mud_slow", 0 ) != 0 )
            n_want = 1;

        if ( n_want != n_applied )
        {
            n_applied = n_want;

            if ( n_want )
                level.a_e_slow_areas = [];
            else
                level.a_e_slow_areas = level.zmqol_mud_areas;

            println( "[zm_qol] no mud slowdown -> " + n_want + " (" + level.a_e_slow_areas.size + " mud volumes live)" );
        }

        wait 1;
    }
}
