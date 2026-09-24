#include maps\mp\zombies\_zm_utility;
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_zonemgr;

struct_init()
{
	zone = "zone_nml_2";
	scripts\zm\replaced\utility::register_map_spawn((1373, 879, 97), (0, 285, 0), zone, 1);
	scripts\zm\replaced\utility::register_map_spawn((1638, 284, 138), (0, 315, 0), zone, 1);
	scripts\zm\replaced\utility::register_map_spawn((1975, -43, 125), (0, 135, 0), zone, 1);
	scripts\zm\replaced\utility::register_map_spawn((2090, -398, 120), (0, 110, 0), zone, 1);
	scripts\zm\replaced\utility::register_map_spawn((-988, 820, 106), (0, 265, 0), zone, 2);
	scripts\zm\replaced\utility::register_map_spawn((-985, 521, 104), (0, 235, 0), zone, 2);
	scripts\zm\replaced\utility::register_map_spawn((-1286, 108, 102), (0, 55, 0), zone, 2);
	scripts\zm\replaced\utility::register_map_spawn((-1473, -474, 104), (0, 80, 0), zone, 2);
	//  Fix 8: untagged spares (never half-filtered) — midpoints of nearby same-side points.
	scripts\zm\replaced\utility::register_map_spawn((1506, 582, 118), (0, 315, 0), zone);
	scripts\zm\replaced\utility::register_map_spawn((-987, 671, 105), (0, 235, 0), zone);

	// --- perk machines: Reimagined's own mapents positions -------------------
	//  This mod ships no zm_tomb mapents and the stock machines are tagged
	//  "zclassic_perks_tomb", which never matches "zstandard_excavation_site",
	//  so without these three No Man's Land has no perks and no Pack-a-Punch.
	//  Same script-registration technique as Church, Trenches, Borough, Docks
	//  and Crazy Place (MOD_CATALOGUE.md §37c).
	//
	//  Origins/angles verbatim from BO2-Reimagined's zm_tomb.d3dbsp, entities
	//  tagged "zstandard_perks_excavation_site" (extract_tomb_perks.py). Float
	//  noise in their angles (1.00179e-005, -4.43583e-012) written as 0; the
	//  225 and 270 yaws are real and kept.
	//
	//  All three models are Origins' own and present in zm_tomb.ff (checked with
	//  Unlinker --list, not assumed - a precachemodel of something the level
	//  lacks is fatal at load).
	scripts\zm\replaced\utility::register_perk_struct( "specialty_armorvest", "zombie_vending_jugg", (2328, -232, 139), (0, 180, 0) );
	scripts\zm\replaced\utility::register_perk_struct( "specialty_longersprint", "zombie_vending_marathon", (-2355, -36, 240), (0, 225, 0) );
	//  PaP through loc_common so it draws BUILT, not the "please wait" pose -
	//  see the banner on loc_common::register_pap_struct_built.
	//  Origins' dig sites are staff/quest furniture - dropped from the struct
	//  index before dig_spots_init() reads it, so none ever spawns.
	scripts\zm\locs\loc_common::remove_dig_site_structs();

	//  🛑 BEFORE registering ours: drop Origins' own PaP struct. This arena's
	//  machine sits at the same spot as the map's, so without this there are two
	//  overlapping structs and Instant PaP / the fx bind to the wrong one.
	scripts\zm\locs\loc_common::drop_map_pap_structs();
	scripts\zm\locs\loc_common::register_pap_struct_built( "p6_zm_tm_packapunch", (-5.5, -8.5, 335.5), (0, 270, 0) );
}

// zm_qol: populated - see the note in zm_transit_loc_diner.gsc::precache.
precache()
{
	precachemodel( "collision_wall_128x128x10_standard" );
	precachemodel( "collision_wall_256x256x10_standard" );
	precachemodel( "collision_wall_512x512x10_standard" );
	precachemodel( "p6_zm_buildable_bench_tarp" );
	precachemodel( "p6_zm_tm_barbedwire_128" );
	precachemodel( "p6_zm_tm_barbedwire_256" );
	precachemodel( "p6_zm_tm_barbedwire_gate" );
	precachemodel( "p6_zm_tm_crate_01" );
	precachemodel( "p6_zm_tm_crate_02" );
	precachemodel( "p6_zm_tm_wood_wall_64x96_lft" );
	// loc_common::spawn_wallbuy_plywood
	precachemodel( "p6_pak_old_plywood_small" );
	precachemodel( "p6_zm_tm_wood_post_thin_01_tall" );
}

main()
{
	treasure_chest_init();
	random_perk_machine_init();
	init_barriers();
	init_wallbuy_plywood();
	generatebuildabletarps();
	disable_doors();
	enable_zones();
	disable_zones();
	disable_zombie_spawn_locations();
	disable_player_spawn_locations();
	level thread scripts\zm\locs\loc_common::init();
	//  Ghost the stone-heap machine; the client draws the assembled one.
	//  See loc_common::pap_built_pose. This arena's Pack-a-Punch happens to sit
	//  at Origins' own PaP spot, so the origin still disambiguates correctly.
	level thread scripts\zm\locs\loc_common::pap_built_pose( (-5.5, -8.5, 335.5) );
	//  No giant robots in a survival arena - and this is what was blocking prone.
	level thread scripts\zm\locs\loc_common::disable_giant_robots();
	level thread scripts\zm\locs\loc_common::force_prone_allowed();
	//  No challenge slab is inside No Man's Land (both sit in the bunkers and
	//  the village), so this is a no-op here - called for consistency so a
	//  future arena cannot inherit the gap.
	level thread scripts\zm\locs\loc_common::remove_challenge_boxes();
}

treasure_chest_init()
{
	chest_names = array("nml_open_chest", "nml_farm_chest");
	level.chests = [];

	foreach (chest_name in chest_names)
	{
		chest = getstruct(chest_name, "script_noteworthy");
		level.chests[level.chests.size] = chest;
	}

	start_chest_names = array("nml_open_chest", "nml_farm_chest");
	maps\mp\zombies\_zm_magicbox::treasure_chest_init(random(start_chest_names));
}

random_perk_machine_init()
{
	machine_names = array("nml", "farmhouse");
	machines = getentarray("random_perk_machine", "targetname");

	foreach (machine in machines)
	{
		if (!isinarray(machine_names, machine.script_string))
		{
			machine delete();
		}
	}

	start_machine_names = array("nml", "farmhouse");
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
	scripts\zm\locs\loc_common::barrier("collision_wall_256x256x10_standard", (-771, 1373, 199), (0, 0, 0), 1);
	scripts\zm\locs\loc_common::barrier("p6_zm_tm_barbedwire_128", (-771, 1388, 51), (0, 0, -15));

	scripts\zm\locs\loc_common::barrier("collision_wall_512x512x10_standard", (-1206, 1187, 358), (0, 0, 0), 1);
	scripts\zm\locs\loc_common::barrier("p6_zm_tm_barbedwire_256", (-1271, 1202, 102), (0, 0, 0));
	scripts\zm\locs\loc_common::barrier("p6_zm_tm_crate_02", (-1391, 1212, 109), (0, 90, 0));
	scripts\zm\locs\loc_common::barrier("p6_zm_tm_crate_02", (-1031, 1212, 104), (0, 90, 0));

	scripts\zm\locs\loc_common::barrier("collision_wall_512x512x10_standard", (1331, 1181, 329), (0, 0, 0), 1);
	scripts\zm\locs\loc_common::barrier("p6_zm_tm_barbedwire_256", (1266, 1200, 71), (0, 0, -5));
	scripts\zm\locs\loc_common::barrier("p6_zm_tm_crate_01", (1171, 1210, 85), (5, 90, 0));
	scripts\zm\locs\loc_common::barrier("p6_zm_tm_crate_01", (1481, 1210, 77), (5, 90, 0));

	scripts\zm\locs\loc_common::barrier("collision_wall_128x128x10_standard", (-2432, 587, 270), (0, 0, 0), 1);
	scripts\zm\locs\loc_common::barrier("p6_zm_tm_barbedwire_gate", (-2432, 587, 221), (0, 0, 0));

	scripts\zm\locs\loc_common::barrier("collision_wall_128x128x10_standard", (1997, 802, 181), (0, 90, 0), 1);
	scripts\zm\locs\loc_common::barrier("p6_zm_tm_barbedwire_gate", (1997, 802, 117), (0, 90, 0));

	scripts\zm\locs\loc_common::barrier("collision_wall_128x128x10_standard", (91, -141, 388), (0, 135, 0), 1);
	scripts\zm\locs\loc_common::barrier("p6_zm_tm_wood_wall_64x96_lft", (88, -144, 333), (90, 135, 0));
}

init_wallbuy_plywood()
{
	scripts\zm\locs\loc_common::spawn_wallbuy_plywood((-2432, 591, 265), (0, -90, 0));
	scripts\zm\locs\loc_common::spawn_wallbuy_plywood((1993, 802, 169), (0, 0, 0));
}

generatebuildabletarps()
{
	tarp = spawn("script_model", (2307, 704, -20));
	tarp.angles = (0, 0, 0);
	tarp setModel("p6_zm_buildable_bench_tarp");
}

disable_doors()
{
	debris_trigs = getentarray("zombie_debris", "targetname");

	foreach (debris_trig in debris_trigs)
	{
		if (debris_trig.script_flag == "activate_zone_village_0")
		{
			debris_trig delete();
		}
	}
}

// ============================================================================
//  🛑 v2.17.13 - activate_zone_farm ADDED. Same disconnected-arena bug as
//  Trenches and Church.
//
//  activate_zone_nml covers 58 of the No Man's Land links and was already set,
//  so most of this arena was fine. But valid_zones (below) also lists
//  zone_nml_farm and zone_nml_farm_1, and every link to those is gated on
//  activate_zone_farm:
//      zone_nml_0    --activate_zone_farm--> zone_nml_farm
//      zone_nml_5    --activate_zone_farm--> zone_nml_farm
//      zone_nml_farm --activate_zone_farm--> zone_nml_farm_1
//
//  Two enabled-but-unreachable zones, which is the same freeze-then-vanish
//  shape: spawn, no path to the player, idle, distance-cleaned.
//
//  📝 The farm chain also reaches zone_nml_celllar and the bolt stairs, which
//  are NOT in valid_zones - disable_zones() below switches those off, so
//  setting this flag does not widen the arena past its intended edge.
// ============================================================================
//  🛑 v2.17.14 - activate_zone_farm REVERTED, untested, for safety. Same
//  reasoning as Church: the identical change on Trenches produced an instant
//  "GAME OVER, Zombies: 0" at full health, and the farm chain reaches
//  zone_nml_celllar and the bolt stairs which disable_zones() switches off
//  immediately afterwards - exactly the activate-then-disable shape that is
//  suspected there. The two farm zones stay unreachable rather than risk the
//  arena.
enable_zones()
{
	flag_set("activate_zone_nml");
}

disable_zones()
{
	valid_zones = array("zone_nml_0", "zone_nml_1", "zone_nml_2", "zone_nml_2b", "zone_nml_3", "zone_nml_4", "zone_nml_5", "zone_nml_6", "zone_nml_7", "zone_nml_7a", "zone_nml_8", "zone_nml_9", "zone_nml_9a", "zone_nml_10", "zone_nml_10a", "zone_nml_11", "zone_nml_11a", "zone_nml_12", "zone_nml_12a", "zone_nml_13", "zone_nml_14", "zone_nml_15", "zone_nml_15a", "zone_nml_16", "zone_nml_16a", "zone_nml_17", "zone_nml_17a", "zone_nml_18", "zone_nml_20", "zone_nml_farm", "zone_nml_farm_1");
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
		if (index == "zone_nml_1")
		{
			foreach (spawn_location in zone.spawn_locations)
			{
				if (spawn_location.origin == (-960, 1408, 121.75))
				{
					spawn_location.is_enabled = false;
				}
			}
		}
	}
}

disable_player_spawn_locations()
{
	respawn_points = getstructarray("player_respawn_point", "targetname");

	foreach (respawn_point in respawn_points)
	{
		if (respawn_point.script_noteworthy == "zone_nml_2")
		{
			respawn_array = getstructarray(respawn_point.target, "targetname");

			foreach (respawn in respawn_array)
			{
				if (respawn.origin == (-768, 2048, -96))
				{
					arrayremovevalue(respawn_array, respawn);
					break;
				}
			}
		}
		else if (respawn_point.script_noteworthy == "zone_nml_18")
		{
			respawn_array = getstructarray(respawn_point.target, "targetname");

			foreach (respawn in respawn_array)
			{
				if (respawn.origin == (320, 0, 147.65))
				{
					arrayremovevalue(respawn_array, respawn);
					break;
				}
			}

			foreach (respawn in respawn_array)
			{
				if (respawn.origin == (-128, 256, 51.65))
				{
					arrayremovevalue(respawn_array, respawn);
					break;
				}
			}
		}
		else if (respawn_point.script_noteworthy == "zone_nml_farm")
		{
			respawn_array = getstructarray(respawn_point.target, "targetname");

			foreach (respawn in respawn_array)
			{
				if (respawn.origin == (-2752, 64, 64))
				{
					arrayremovevalue(respawn_array, respawn);
					break;
				}
			}
		}
	}
}