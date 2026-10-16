#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include common_scripts\utility;

// ============================================================================
//  zmqol_ai_fightdist.gsc  -  THE FIGHT-DISTANCE REPAIR ON EVERY MAP
//
//  🛑 User, 2026-10-11, on TranZit Farm survival: *"some zombies are attacking
//  me then some are just like walking into me and like they acknowledge my
//  existence but then they just won't attack"*. The repair for that
//  (loc_common::fix_stuck_fight_distance, v2.17.30) was threaded from
//  loc_common::init() only, and loc scripts exist for fourteen replaced
//  locations: Diner, Power, Tunnel, Cornfield, Church, Trenches, Crazy Place,
//  Excavation Site, Docks, Shopping Mall, Dragon Rooftop, Sweatshop and the
//  Buried Maze. Farm, Town, Bus Depot and every classic gamemode have NO loc
//  script, so on those the walk-into-you bug was never repaired at all. The
//  2026-10-11 console log proves it: the Farm session has zero "zombie AI:"
//  repair lines while the user is reporting the exact symptom the watchdog
//  exists for. This is not a regression of the code - it is a coverage hole.
//
//  Root script on purpose (own init(), per AGENTS.md 1b): quality_of_life.gsc
//  is on its compiled-bytecode ceiling and gets nothing added to it. This file
//  adds no new repair logic - it runs the SAME proven function that has been
//  live on the arenas since v2.17.30, on every map from now on:
//
//      REPAIR 1  find_flesh dead + ignoreme=1 beside a player -> restart it.
//      REPAIR 2  pathenemyfightdist stuck below stock's 64 (the
//                _zm_spawner::zombie_goto_entrance:540-542 climb window) -> 64.
//      REPAIR 3  meleeattackdist below 64 -> 64.
//
//  SINGLE FLIGHT: loc_common::init() honours the same level flag, so on the
//  fourteen replaced locations exactly one copy of the watchdog runs - the
//  loc_common one - and everywhere else this installer's copy runs. Whoever
//  gets there first wins; both paths thread the identical function body.
//
//  The install waits for "start_zombie_round_logic" so the first
//  getaiarray( level.zombie_team ) pass sees a populated team, exactly like
//  the loc-driven copy effectively does (its init runs after map spawn).
// ============================================================================

init()
{
	thread zmqol_fightdist_install();
}

zmqol_fightdist_install()
{
	flag_wait( "start_zombie_round_logic" );

	if ( isdefined( level.zmqol_fightdist_watchdog ) )
		return;

	level.zmqol_fightdist_watchdog = 1;

	level thread scripts\zm\locs\loc_common::fix_stuck_fight_distance();
}
