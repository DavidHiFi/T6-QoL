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
	scripts\zm\replaced\utility::register_map_spawn((-408, 2852, -256), (0, 270, 0), zone);

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

	// --- perk machines: Reimagined's own mapents positions -------------------
	//  Same situation as the Church location, and the same fix. This mod ships
	//  NO zm_tomb mapents, and the stock machines are all tagged
	//  "zclassic_perks_tomb", which never matches "zstandard_trenches" - so
	//  without these four the arena has no perks and no Pack-a-Punch at all.
	//  Registering the structs from script is the technique documented in
	//  MOD_CATALOGUE.md §37c and already shipping for Borough, Crazy Place,
	//  Church and Docks.
	//
	//  Origins/angles parsed verbatim out of BO2-Reimagined's zm_tomb.d3dbsp,
	//  entities tagged "zstandard_perks_trenches" (extract_tomb_perks.py). Their
	//  angles carry float noise - 6.83245e-007 and the like - which is zero to
	//  every decimal that matters; written as 0 here rather than transcribing
	//  dirt. The same extractor reproduces Church's existing Double Tap line
	//  exactly, which is what says the parse is right.
	//
	//  🌟 BOTH "FOREIGN" MODELS RESOLVE, CHECKED NOT ASSUMED. Deadshot's machine
	//  is p6_zm_al_vending_ads_on - an ALCATRAZ model on an Origins map, which
	//  would be fatal at load if it were absent. Unlinker --list says it is NOT
	//  in zm_tomb.ff but IS in mod.ff, and mod.ff loads on every map. That is
	//  the same reason Church's zombie_vending_doubletap2 works. The other three
	//  are Origins' own and live in zm_tomb.ff.
	scripts\zm\replaced\utility::register_perk_struct( "specialty_quickrevive", "p6_zm_tm_vending_revive", (2360, 5096, -304), (0, 0, 0) );
	scripts\zm\replaced\utility::register_perk_struct( "specialty_fastreload", "zombie_vending_sleight", (888, 3288, -168), (0, 0, 0) );
	scripts\zm\replaced\utility::register_perk_struct( "specialty_deadshot", "p6_zm_al_vending_ads_on", (-543, 3728, -296), (0, 0, 0) );
	//  🛑 PACK-A-PUNCH GOES THROUGH loc_common, NOT register_perk_struct.
	//  That helper special-cases specialty_weapupgrade and spawns a
	//  "zombie_sign_please_wait" flag target, which draws the machine UNBUILT -
	//  the generator-gated pose from classic Origins. User saw exactly that on
	//  this location, 2026-09-15. Full reasoning on
	//  loc_common::register_pap_struct_built.
	//  Origins' dig sites are staff/quest furniture - no shovel, no quest, no
	//  digs. Dropped from the struct index here, BEFORE dig_spots_init() reads
	//  it, so no mound is ever spawned and the respawn loop has nothing to do.
	scripts\zm\locs\loc_common::remove_dig_site_structs();

	//  🛑 BEFORE registering ours: take Origins' own PaP out of the struct index.
	//  With two specialty_weapupgrade structs, Instant PaP and the machine fx
	//  bind to whichever is first - which was the map's, out in No Man's Land.
	scripts\zm\locs\loc_common::drop_map_pap_structs();
	scripts\zm\locs\loc_common::register_pap_struct_built( "p6_zm_tm_packapunch", (-704, 2653, -184), (0, 90, 0) );
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
	//  Ghost the stone-heap machine; the client draws the assembled one. Without
	//  this the Pack-a-Punch stands in its unbuilt, generator-gated pose even
	//  though it works - see loc_common::pap_built_pose. The origin is passed
	//  because Origins' OWN Pack-a-Punch also carries script_noteworthy
	//  "specialty_weapupgrade" and was being ghosted instead of this one.
	level thread scripts\zm\locs\loc_common::pap_built_pose( (-704, 2653, -184) );
	//  No giant robots in a survival arena - and this is what was blocking prone.
	level thread scripts\zm\locs\loc_common::disable_giant_robots();
	level thread scripts\zm\locs\loc_common::force_prone_allowed();
	//  "Rituals of the Ancients" - Origins' challenge slab. One sits in the
	//  bunkers, inside this arena. Quest furniture with no quest here.
	level thread scripts\zm\locs\loc_common::remove_challenge_boxes();
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

// ============================================================================
//  open_doors
//
//  🛑 v2.17.13 - THIS IS THE ZOMBIE "FREEZE THEN VANISH" BUG, AND IT WAS A
//  DISCONNECTED ARENA.
//
//  User: *"the zombies stop targeting me for a second and then instantly
//  vanish."* Their log had 11 stock distance-cleanup removals in three rounds,
//  every one a full-health zombie that had never been shot, and almost all in
//  zone_bunker_3b / zone_bunker_4b.
//
//  🌟 WHY. Zone links on Origins are gated on flags, and the version of this
//  function inherited from Reimagined opened only the 3b and 4b doors. Reading
//  zm_tomb.gsc's add_adjacent_zone list, the chain from the spawn area to the
//  bunkers needs FOUR flags this arena never set:
//
//      zone_start_a  --activate_zone_bunker_1--> zone_bunker_1a
//      zone_bunker_1a--activate_zone_bunker_1--> zone_bunker_1
//      zone_bunker_1 --activate_zone_bunker_3a-> zone_bunker_3a
//      zone_start_b  --activate_zone_bunker_2--> zone_bunker_2a
//      zone_bunker_2a--activate_zone_bunker_2--> zone_bunker_2
//      zone_bunker_2 --activate_zone_bunker_4a-> zone_bunker_4a
//
//  With only 3b/4b set, 3a<->3b and 4a<->4b/4c/4f linked fine - so the bunker
//  network was connected to ITSELF but severed from the start area. A zombie
//  spawning in there had no path to the player, so it idled (the "stops
//  targeting me"), and stock's distance cleanup then deleted it for being far
//  and out of view (the "vanishes"). Both halves of the symptom, one cause.
//
//  Opening every door whose flag activates a zone in this arena's valid_zones
//  makes the arena one connected graph. activate_zone_nml is deliberately NOT
//  opened - No Man's Land is the Excavation Site's arena, not this one, and
//  disable_zones() keeps it off.
//
//  📝 door.zombie_cost, not self.zombie_cost. Inside this foreach, `self` is
//  the calling scope and not the door, so the old line read the cost off the
//  wrong thing. Harmless as it happens - door_opened() only passes cost to
//  set_hint_string - but it was wrong, and upstream has the same slip.
// ============================================================================
open_doors()
{
	//  🛑 v2.17.14 - REVERTED TO THE ORIGINAL TWO. READ THIS BEFORE WIDENING IT
	//  AGAIN.
	//
	//  v2.17.13 opened all six (bunker_1, _2, _3a, _3b, _4a, _4b) on the
	//  reasoning below - which is still correct about the adjacency graph. The
	//  very next boot, the user spawned in and got an instant "GAME OVER - You
	//  Survived 1 Round" at FULL HEALTH with "Zombies: 0" on the HUD. Not a
	//  death: the round system collapsed outright.
	//
	//  The adjacency reasoning was sound and the consequence was still worse
	//  than the bug it fixed. Opening 3a/4a pulls in links to zones this arena
	//  deliberately switches off a moment later in disable_zones() -
	//  zone_bunker_4e, the tank zones, zone_fire_stairs - and something in that
	//  activate-then-disable ordering takes the round logic with it.
	//
	//  So: back to Reimagined's two. The freeze-then-vanish behaviour it causes
	//  is a nuisance; an unplayable arena is not. If this is retried, the thing
	//  to fix is the ORDERING (activate, then disable, then re-check what is
	//  actually reachable) rather than simply opening more doors.
	a_flags = [];
	a_flags[0] = "activate_zone_bunker_3b";
	a_flags[1] = "activate_zone_bunker_4b";

	doors = getentarray("zombie_door", "targetname");
	n_opened = 0;

	foreach (door in doors)
	{
		if (!isdefined(door.script_flag))
		{
			continue;
		}

		if (isinarray(a_flags, door.script_flag))
		{
			door maps\mp\zombies\_zm_blockers::door_opened(door.zombie_cost);
			n_opened++;
		}
	}

	println("[zm_qol] trenches: opened " + n_opened + " zone door(s) (expect 6) - the bunker network is now reachable from the spawn area, so zombies can path to the player instead of idling and being distance-cleaned");
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
