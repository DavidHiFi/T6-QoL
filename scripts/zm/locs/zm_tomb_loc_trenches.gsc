#include maps\mp\zombies\_zm_utility;
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_zonemgr;

struct_init()
{
	zone = "zone_bunker_5a";
	scripts\zm\replaced\utility::register_map_spawn((-472, 2852, -256), (0, 270, 0), zone, 1);
	scripts\zm\replaced\utility::register_map_spawn((-844, 2924, -256), (0, 0, 0), zone, 1);
	scripts\zm\replaced\utility::register_map_spawn((-906, 2548, -256), (0, 90, 0), zone, 1);
	scripts\zm\replaced\utility::register_map_spawn((-543, 2498, -256), (0, 180, 0), zone, 1);
	scripts\zm\replaced\utility::register_map_spawn((-472, 2548, -256), (0, 90, 0), zone, 2);
	scripts\zm\replaced\utility::register_map_spawn((-543, 2924, -256), (0, 180, 0), zone, 2);
	scripts\zm\replaced\utility::register_map_spawn((-906, 2852, -256), (0, 270, 0), zone, 2);
	scripts\zm\replaced\utility::register_map_spawn((-844, 2498, -256), (0, 0, 0), zone, 2);

	level.struct_class_names["targetname"]["intermission"] = [];

	intermission_cam = spawnStruct();
	intermission_cam.origin = (-59, 2854, 42);
	intermission_cam.angles = (15, 45, 0);
	intermission_cam.targetname = "intermission";
	intermission_cam.script_string = "trenches";
	intermission_cam.speed = 30;
	intermission_cam.target = "intermission_trenches_end";
	scripts\zm\replaced\utility::add_struct(intermission_cam);

	intermission_cam_end = spawnStruct();
	intermission_cam_end.origin = (-30, 3412, 24);
	intermission_cam_end.angles = (15, 315, 0);
	intermission_cam_end.targetname = "intermission_trenches_end";
	scripts\zm\replaced\utility::add_struct(intermission_cam_end);
}

// zm_qol: populated - see the note in zm_transit_loc_diner.gsc::precache.
precache()
{
	precachemodel( "collision_wall_128x128x10_standard" );
	precachemodel( "p6_zm_buildable_bench_tarp" );
	precachemodel( "p6_zm_tm_barricade_wall_01" );
	precachemodel( "p6_zm_tm_barricade_wall_02" );
	precachemodel( "zm_collision_perks1" );   // loc_common::increase_pap_collision
}

main()
{
	treasure_chest_init();
	random_perk_machine_init();
	init_barriers();
	generatebuildabletarps();
	open_doors();
	disable_zones();
	disable_zombie_spawn_locations();
	scripts\zm\locs\loc_common::increase_pap_collision();
	level thread scripts\zm\locs\loc_common::init();
}

// ============================================================================
//  zm_qol: the box and the Wunderfizz spots available on Trenches.
//
//  🛑 CORRECTION, 2026-08-02. An earlier version of this file trimmed both pools
//  to the two trench spots on the reasoning that "the start bunker (generator 1)
//  is walled off on this arena". THAT WAS WRONG - the doors into the spawn area
//  are purchasable, reported in game by the user. disable_zones() ten lines above
//  says the same thing and was not read carefully enough: its valid_zones list
//  contains "zone_start", "zone_start_a" and "zone_start_b", so the start bunker
//  has always been a reachable part of the Trenches arena. Both entities are
//  really there, verified in the shipped mapents (T6-Data-Archive zm_tomb.d3dbsp):
//      bunker_start_chest  script_struct       (2900, 5520, -368)
//      starting_bunker     random_perk_machine (2968, 5368, -368)
//  The Wunderfizz had been deleted outright by the loop below, which is why it
//  went missing from that room.
//
//  Both pools are now back to the stock/Reimagined arrays - all three spots.
//
//  🛑 The two "start_" arrays below are a DIFFERENT thing and stay trimmed to the
//  two trench spots, matching Reimagined. They pick where the box and Wunderfizz
//  BEGIN, not where they can move to, so leaving the start bunker out of them
//  keeps round one from opening with the box behind a door nobody can afford yet.
//
//  Consequence for the move pattern: with three entries neither strictly
//  alternates any more, which reverses checkpoint 11 item 4 on purpose - that
//  request was made on the same "unreachable third spot" premise this note
//  corrects.
//    Box        maps\mp\zombies\_zm_magicbox::default_box_move_logic() walks
//               level.chests by index and re-randomises on wrap.
//    Wunderfizz maps\mp\zombies\_zm_perk_random::machine_selector() re-reads
//               getentarray("random_perk_machine") each move; its do/while only
//               re-rolls while the pick equals the CURRENT machine, so with three
//               it picks randomly between the other two.
//
//  level.chests is not just the move pool - zm_tomb_capture_zones::
//  get_mystery_box_from_script_noteworthy() searches it. Restoring
//  bunker_start_chest makes register_mystery_box_for_zone(
//  "generator_start_bunker", "bunker_start_chest") a HIT rather than the
//  guaranteed miss it used to be; that is fine, and it is why
//  scripts\zm\replaced\zm_tomb_capture_zones.gsc already registers this zone for
//  trenches. The box ends up owned by generator_start_bunker and unlocked anyway,
//  because zm_tomb\zm_tomb.gsc::zmqol_power_up_all_generators() force-captures
//  every zone at round start.
// ============================================================================
treasure_chest_init()
{
	chest_names = array("bunker_start_chest", "bunker_cp_chest", "bunker_tank_chest");
	level.chests = [];

	foreach (chest_name in chest_names)
	{
		chest = getstruct(chest_name, "script_noteworthy");
		level.chests[level.chests.size] = chest;
	}

	start_chest_names = array("bunker_cp_chest", "bunker_tank_chest");
	maps\mp\zombies\_zm_magicbox::treasure_chest_init(random(start_chest_names));
}

random_perk_machine_init()
{
	machine_names = array("starting_bunker", "trenches_left", "trenches_right");
	machines = getentarray("random_perk_machine", "targetname");

	foreach (machine in machines)
	{
		if (!isinarray(machine_names, machine.script_string))
		{
			machine delete();
		}
	}

	start_machine_names = array("trenches_left", "trenches_right");
	machines = getentarray("random_perk_machine", "targetname");

	foreach (machine in machines)
	{
		if (isinarray(start_machine_names, machine.script_string))
		{
			machine.script_noteworthy = "start_machine";
		}
		else
		{
			machine.script_noteworthy = undefined;
		}
	}
}

init_barriers()
{
	if (getdvarint("ui_gametype_pro"))
	{
		scripts\zm\locs\loc_common::barrier("collision_wall_128x128x10_standard", (-686, 2653, -120), (0, 90, 0), 1);
		scripts\zm\locs\loc_common::barrier("p6_zm_tm_barricade_wall_02", (-686, 2653, -184), (0, 0, 0));
	}

	// ========================================================================
	//  🛑 zm_qol: this barricade shipped with NO collision partner.
	//
	//  loc_common::barrier()'s 4th argument is `disconnect_paths`, and it is the
	//  ONLY thing in that function that blocks anything - it spawns the model with
	//  the collision flag and calls disconnectPaths(). Without it a barrier() call
	//  is decoration and nothing more.
	//
	//  Every other barrier block in all 14 loc scripts is a collision_wall_* /
	//  collision_geo_* call carrying that flag, followed by props laid on top.
	//  This line was the single exception in the whole project: a lone
	//  p6_zm_tm_barricade_wall_02 - a wall of wooden planks - with no collision
	//  and no path disconnect, ~740 units from generator_tank_trench
	//  (-351.5, 3448, -282.5) and right on the edge of the Trenches spawn ring.
	//  Zombies pathed straight through the boards without touching them.
	//
	//  Inherited as-is from BO2-Reimagined; its init_barriers() is identical here,
	//  so this is an upstream gap rather than something the port introduced.
	//
	//  Placement follows the rule the other three pairs in this file already obey:
	//      collision yaw    = prop yaw + 90 (mod 180)   -90 + 90 -> 0
	//      collision origin = prop origin, z + 64       -112 + 64 -> -48
	//  and 128x128 matches the other two trench barricades.
	//
	//  🛑 If zombies now fail to REACH the arena instead, this disconnectPaths is
	//  the first thing to back out - checkpoint 11 §3.6, the two opposite zone
	//  failure modes. Deleting just the collision line below restores the old
	//  behaviour exactly.
	// ========================================================================
	scripts\zm\locs\loc_common::barrier("collision_wall_128x128x10_standard", (-749, 2820, -48), (0, 0, 0), 1);
	scripts\zm\locs\loc_common::barrier("p6_zm_tm_barricade_wall_02", (-749, 2820, -112), (0, -90, 0));

	scripts\zm\locs\loc_common::barrier("collision_wall_128x128x10_standard", (80, 4509, -288), (0, 0, 0), 1);
	scripts\zm\locs\loc_common::barrier("p6_zm_tm_barricade_wall_01", (75, 4514, -352), (0, 270, 0));

	scripts\zm\locs\loc_common::barrier("collision_wall_128x128x10_standard", (2305, 4128, -280), (0, 90, 0), 1);
	scripts\zm\locs\loc_common::barrier("p6_zm_tm_barricade_wall_01", (2310, 4138, -344), (0, 180, 0));
}

generatebuildabletarps()
{
	tarp = spawn("script_model", (-893, 2312, -256));
	tarp.angles = (0, 0, 0);
	tarp setModel("p6_zm_buildable_bench_tarp");
}

open_doors()
{
	doors = getentarray("zombie_door", "targetname");

	foreach (door in doors)
	{
		if (isdefined(door.script_flag))
		{
			if (door.script_flag == "activate_zone_bunker_3b" || door.script_flag == "activate_zone_bunker_4b")
			{
				door maps\mp\zombies\_zm_blockers::door_opened(self.zombie_cost);
			}
		}
	}
}

disable_zones()
{
	valid_zones = array("zone_start", "zone_start_a", "zone_start_b", "zone_bunker_1", "zone_bunker_1a", "zone_bunker_2", "zone_bunker_2a", "zone_bunker_3a", "zone_bunker_3b", "zone_bunker_4a", "zone_bunker_4b", "zone_bunker_4c", "zone_bunker_4d", "zone_bunker_4f", "zone_bunker_5a", "zone_bunker_6");
	spawn_points = maps\mp\gametypes_zm\_zm_gametype::get_player_spawns_for_gametype();

	foreach (index, zone in level.zones)
	{
		if (!isinarray(valid_zones, index))
		{
			level.zones[index].is_enabled = 0;
			level.zones[index].is_spawning_allowed = 0;

			foreach (spawn_point in spawn_points)
			{
				if (spawn_point.script_noteworthy == index)
				{
					spawn_point.locked = 1;
					break;
				}
			}
		}
	}
}

disable_zombie_spawn_locations()
{
	foreach (index, zone in level.zones)
	{
		if (index == "zone_bunker_4c")
		{
			foreach (spawn_location in zone.spawn_locations)
			{
				if (spawn_location.origin == (256, 4864, -296))
				{
					spawn_location.is_enabled = false;
				}
			}
		}
	}
}