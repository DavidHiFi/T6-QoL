#include maps\mp\zm_tomb_chamber;
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;

// ============================================================================
//  CRAZY PLACE SURVIVAL - the chamber walls rise instead of snapping.
//                                                        (feature, 2026-09-12)
// ----------------------------------------------------------------------------
//  User, 2026-09-12: *"when you load into the crazy place survival map ... you
//  spawn in the middle of the map, right next to the pack-a-punch machine, and
//  the walls just kind of disappear, they just instantly disappear. i feel like
//  you should make it so that the walls fly up and then disappear, so that
//  looks more clean"*.
//
//  WHAT THE WALLS ARE. Four map entities with script_noteworthy "chamber_wall"
//  (maps\mp\zm_tomb_chamber::inits), parked at their map origins - DOWN, inside
//  the chamber - until the round starts. Stock then raises every one of them
//  1000 units with
//        e_wall moveto( e_wall.up_origin, 0.05 );
//  a 50-millisecond move. On classic Origins nobody is in the chamber when it
//  fires, so it reads as scenery. On this location the player SPAWNS in the
//  middle of the chamber, watches the four walls, and then they "boom, in one
//  instant just disappear" - the 0.05s moveto.
//
//  THE CHANGE. Outside classic the four walls fly to their up position over
//  2 seconds instead, then connect their paths - the same shape as stock's own
//  move_wall_up() (maps\mp\zm_tomb_chamber.gsc:164), just slower. Nothing else
//  moves: same entities, same up_origin, same trigger point, same 3s wait
//  after start_zombie_round_logic.
//
//  🛑 NO hide() CALL, DELIBERATELY. The walls are NOT hidden after the stock
//  raise either - up_origin is already out of the chamber view (that is why
//  the stock snap reads as "they disappear"). Hiding them would also break
//  the element wall-change cycle (chamber_change_walls moves a wall back DOWN
//  on every crystal pickup - a hidden wall would come down invisible), so the
//  rise is the whole change.
//
//  Classic Origins takes the stock 0.05s snap, byte for byte.
// ============================================================================
inits()
{
    a_walls = getentarray( "chamber_wall", "script_noteworthy" );

    foreach ( e_wall in a_walls )
    {
        e_wall.down_origin = e_wall.origin;
        e_wall.up_origin = ( e_wall.origin[0], e_wall.origin[1], e_wall.origin[2] + 1000 );
    }

    level.n_chamber_wall_active = 0;
    flag_wait( "start_zombie_round_logic" );
    wait 3.0;

    if ( is_classic() )
    {
        foreach ( e_wall in a_walls )
        {
            e_wall moveto( e_wall.up_origin, 0.05 );
            e_wall connectpaths();
        }

        return;
    }

    n_rising = 0;

    foreach ( e_wall in a_walls )
    {
        if ( !isdefined( e_wall ) )
            continue;

        e_wall thread zmqol_wall_rise();
        n_rising++;
    }

    println( "[zm_qol] crazy place walls: " + n_rising + " wall(s) rising over 2s (survival - stock snap suppressed)" );
}

//  Stock's move_wall_up(), 2 seconds instead of 1. Called only from the
//  non-classic branch above.
zmqol_wall_rise()
{
    self moveto( self.up_origin, 2 );
    self waittill( "movedone" );
    self connectpaths();
}
