#include maps\mp\zombies\_zm_utility;
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_zonemgr;

// ============================================================================
//  THE CHURCH PACK-A-PUNCH COORDINATE  -  ONE COPY, AND A BUILD CHECK
//
//  🛑 v2.17.24 - THIS EXISTS BECAUSE THE NUMBER WAS WRITTEN DOWN THREE TIMES
//  AND THE THREE COPIES DISAGREED. struct_init() registered the machine,
//  main() told pap_built_pose() where to find it, and zm_tomb.csc drew the
//  built model - each with its own literal. struct_init drifted to
//  (478,-2535) while the other two stayed at (528,-2697), 170 units away.
//
//  pap_built_pose() only ghosts a machine within 128 units of the origin it is
//  given, so at 170 it ghosts NOTHING: the unbuilt stone heap keeps drawing at
//  the real machine while the client's assembled model stands somewhere else
//  entirely. Two Pack-a-Punches, one of them visibly broken. Every one of the
//  five bad placements on this arena has been some version of this.
//
//  Now there is one function. struct_init() and main() both call it, so they
//  cannot disagree. zm_tomb.csc cannot call GSC, so it keeps its own literals -
//  and tools\check-perk-guard.ps1 fails the build if they differ from these.
//
//  🌟 THE VALUE IS MEASURED, FROM THE MAP, NOT REASONED ABOUT.
//
//  Every previous attempt derived a coordinate from the user's `.where` line by
//  argument - treating it as a destination, then as a sighting, then stepping
//  170 units down a ray - and all five were wrong. So this one was traced.
//
//  The user's screenshot HUD gives the sighting exactly:
//      zm_tomb / church / zstandard   x 651  y -2754  z 50   yaw 128
//  with a red arrow drawn down the crosshair at the wooden crates. A probe
//  stood at that point, fired the same bullettrace the Wunderfizz has used
//  since v1.41.1 (wunderfizz.gsc:1587), and the engine answered:
//
//      wall hit   (476,-2530,110)   283 units out
//      face yaw   285               <- trace["normal"], flattened
//      floor      z 47              <- traced down from the back-off point
//      place      (484,-2559,47)    <- hit + 29 along the face normal
//
//  ---------------------------------------------------------------------------
//  🛑 THE YAW IS NOT THE WALL NORMAL. IT IS THE WALL NORMAL MINUS 90.
//
//  This is the part that took five tries, and it is a property of the MODEL,
//  not of the room. p6_zm_tm_packapunch does not face its +X.
//
//  The crate face was traced with fifteen parallel rays at three heights and a
//  thirteen-ray heading fan. They agree: the plane's normal is 285, and the hit
//  points lie on a line running 194.8 degrees, whose perpendicular is 284.8.
//  There is no ambiguity about the wall.
//
//  The machine was ALREADY set to 285 and still stood visibly skewed. So the
//  model's own axes were measured instead, from the client's assembly-joint
//  dump (zm_tomb.csc prints part1_jnt..part6_jnt in world space). Un-rotating
//  those six joints out of yaw 285 gives, in model space:
//
//      X span 53.8      <- the broad face runs along model X
//      Y span 27.4      <- so the front/back axis is model +/-Y
//
//  A model whose face runs along X has its facing normal along Y, and model +Y
//  is 90 degrees off placement yaw. At yaw 285 the machine's face therefore
//  pointed at world 15 - ninety degrees off the crates. That is the whole of
//  "it's sideways", through five placements.
//
//      front = placement yaw - 90        ->  placement yaw = 285 + 90 = 15
//
//  📝 The Wunderfizz hit this same class of bug and solved it the same way -
//  see zmqol_wf_yaw_off in wunderfizz.gsc:1686, which is +90 for ITS model -
//  a different model, a different sign, which is exactly the point.
//  The lesson worth keeping: a model's facing offset is not derivable from the
//  room, and no amount of re-measuring the wall will produce it.
//
//  📝 An attempt to calibrate this against Treyarch's own Excavation Site
//  machine failed cleanly and is worth recording so nobody repeats it: rays
//  fired all round (-5,-8,335) came back OPEN on all eight headings. That
//  machine stands in an open pit with no wall behind it, so it cannot tell you
//  which side its back is.
//
//  CLEARANCE, measured at the spot: solid at 30 units toward yaw 90, 27 toward
//  135, 29 toward 105 (the back direction), and OPEN toward 0, 225 and 315.
//  With the broad axis facing the crates the machine had ~37 of half-width
//  against 29 of gap, which is the reported clipping. Rotated to 15 the narrow
//  axis takes that gap instead, so the same origin now clears.
//
//  The dvars stay, for nudging from a known-good spot from console without a
//  rebuild. They are not for re-deriving the spot: get another trace instead.
// ============================================================================
zmqol_church_pap_origin()
{
	return ( getdvarintdefault( "zmqol_pap_church_x", 484 ),
	         getdvarintdefault( "zmqol_pap_church_y", -2559 ),
	         getdvarintdefault( "zmqol_pap_church_z", 47 ) );
}

zmqol_church_pap_yaw()
{
	return getdvarintdefault( "zmqol_pap_church_yaw", 15 );
}

struct_init()
{
	//  Origins' dig sites are staff/quest furniture - dropped from the struct
	//  index before dig_spots_init() reads it, so none ever spawns.
	scripts\zm\locs\loc_common::remove_dig_site_structs();

	//  Origins' own Pack-a-Punch out of the struct index BEFORE this arena
	//  registers its own below - otherwise the singular
	//  getent( "vending_packapunch" ) lookups in new_pap_trigger() and
	//  _zm_perks::vending_weapon_upgrade() can bind the map's machine out in No
	//  Man's Land instead of ours, which is what broke Instant PaP on Trenches.
	scripts\zm\locs\loc_common::drop_map_pap_structs();

	zone = "zone_village_1";
	scripts\zm\replaced\utility::register_map_spawn((710, -2538, 37), (0, 285, 0), zone, 1);
	scripts\zm\replaced\utility::register_map_spawn((565, -2577, 37), (0, 285, 0), zone, 1);
	scripts\zm\replaced\utility::register_map_spawn((420, -2616, 37), (0, 285, 0), zone, 1);
	scripts\zm\replaced\utility::register_map_spawn((275, -2654, 37), (0, 285, 0), zone, 1);
	scripts\zm\replaced\utility::register_map_spawn((736, -2635, 37), (0, 105, 0), zone, 2);
	scripts\zm\replaced\utility::register_map_spawn((591, -2673, 37), (0, 105, 0), zone, 2);
	scripts\zm\replaced\utility::register_map_spawn((446, -2712, 37), (0, 105, 0), zone, 2);
	scripts\zm\replaced\utility::register_map_spawn((301, -2751, 37), (0, 105, 0), zone, 2);

	// --- perk machine: Double Tap, Reimagined's own mapents position ----------
	//  This mod ships no zm_tomb mapents, so the stock mapents' machines (all
	//  tagged "zclassic_perks_tomb") never match "zstandard_church" and none
	//  spawns here. Registering the struct from script is the same technique the
	//  Borough and Crazy Place locations use. Origin/angles from Reimagined's
	//  zm_tomb.d3dbsp (its church struct is tagged zstandard_perks_church).
	//  Church deliberately has no Pack-a-Punch and no wall-buys, same as
	//  Reimagined.
	scripts\zm\replaced\utility::register_perk_struct( "specialty_rof", "zombie_vending_doubletap2", (165, -2417, 302), (0, 15, 0) );

	// ========================================================================
	//  v2.17.15 - CHURCH GETS A PACK-A-PUNCH. User: *"church survival was
	//  missing a Pack-a-Punch, put one somewhere that makes sense and isn't in
	//  a wonky position or colliding with anything."*
	//
	//  🛑 THIS IS A DEPARTURE FROM REIMAGINED, ON PURPOSE. Their Church has no
	//  Pack-a-Punch and no wall-buys - the note above this function says so, and
	//  it was correct to port it that way. The user has now asked for one, so
	//  this is the mod's own addition rather than a port, and the coordinate is
	//  ours to defend.
	//
	//  🌟 WHERE IT GOES AND WHY: the banner on zmqol_church_pap_origin() at the
	//  top of this file. It carries the traced reading the coordinate came from
	//  and the history of the five placements that missed.
	//
	//  The reasoning that used to sit here - a pathnode sweep, a lopsided-
	//  neighbour score, a pathnode-to-floor calibration, then three readings of
	//  one `.where` line - produced five wrong answers in a row and is not worth
	//  preserving. It was all inference about geometry nobody had traced. The
	//  engine was asked directly instead.
	//
	//  drop_map_pap_structs() above has already removed Origins' own PaP from
	//  the index, so this is the only specialty_weapupgrade in the arena and the
	//  singular getent( "vending_packapunch" ) lookups cannot bind the wrong one.
	// ========================================================================
	scripts\zm\locs\loc_common::register_pap_struct_built(
	        "p6_zm_tm_packapunch",
	        zmqol_church_pap_origin(),
	        ( 0, zmqol_church_pap_yaw(), 0 ) );

	level.struct_class_names["targetname"]["intermission"] = [];

	intermission_cam = spawnStruct();
	intermission_cam.origin = (1332, -3279, 650);
	intermission_cam.angles = (30, 150, 0);
	intermission_cam.targetname = "intermission";
	intermission_cam.script_string = "church";
	intermission_cam.speed = 30;
	intermission_cam.target = "intermission_church_end";
	scripts\zm\replaced\utility::add_struct(intermission_cam);

	intermission_cam_end = spawnStruct();
	intermission_cam_end.origin = (573, -3263, 650);
	intermission_cam_end.angles = (30, 60, 0);
	intermission_cam_end.targetname = "intermission_church_end";
	scripts\zm\replaced\utility::add_struct(intermission_cam_end);
}

// zm_qol: populated - see the note in zm_transit_loc_diner.gsc::precache.
precache()
{
	precachemodel( "collision_wall_128x128x10_standard" );
	precachemodel( "collision_wall_512x512x10_standard" );
	precachemodel( "p6_zm_buildable_bench_tarp" );
	precachemodel( "p6_zm_tm_barbedwire_128" );
	precachemodel( "p6_zm_tm_barricade_wall_02" );
	precachemodel( "p6_zm_tm_crate_01" );
}

main()
{
	treasure_chest_init();
	random_perk_machine_init();
	init_barriers();
	generatebuildabletarps();
	enable_zones();
	disable_zones();
	disable_zombie_spawn_locations();
	disable_player_spawn_locations();
	level thread scripts\zm\locs\loc_common::init();
	//  No giant robots in a survival arena - and this is what was blocking prone
	//  on Trenches. Church gets it too: same map, same robots walking through.
	//  v2.17.15 - Church now HAS a Pack-a-Punch (see struct_init), so it needs
	//  the built pose like the other Origins arenas: ghost the stone-heap server
	//  machine, and zm_tomb.csc draws the assembled one. The origin must match
	//  the struct_init coordinate, dvars included.
	level thread scripts\zm\locs\loc_common::pap_built_pose( zmqol_church_pap_origin() );
	level thread scripts\zm\locs\loc_common::disable_giant_robots();
	level thread scripts\zm\locs\loc_common::force_prone_allowed();
	//  "Rituals of the Ancients" - the village slab sits inside this arena.
	level thread scripts\zm\locs\loc_common::remove_challenge_boxes();
}

// ============================================================================
//  disable_tank() USED TO LIVE HERE and has moved to
//  scripts\zm\zm_tomb\zm_tomb.gsc::zmqol_remove_survival_ee_props().
//
//  Two reasons, both in that function's header: the tank is in the TRENCHES and
//  NO MAN'S LAND arenas as well as this one so the removal belongs somewhere all
//  four locations share, and this file runs ~11 lines of zm_tomb::main() BEFORE
//  maps\mp\zm_tomb_tank::init(), so deleting the vehicle from here left tank::init
//  calling tank_setup() on an undefined level.vh_tank. The new home waits for
//  start_zombie_round_logic, which is after tank::init.
// ============================================================================

treasure_chest_init()
{
	chest_names = array("village_church_chest");
	level.chests = [];

	foreach (chest_name in chest_names)
	{
		chest = getstruct(chest_name, "script_noteworthy");
		level.chests[level.chests.size] = chest;
	}

	start_chest_names = array("village_church_chest");
	maps\mp\zombies\_zm_magicbox::treasure_chest_init(random(start_chest_names));
}

random_perk_machine_init()
{
	machine_names = array("church");
	machines = getentarray("random_perk_machine", "targetname");

	foreach (machine in machines)
	{
		if (!isinarray(machine_names, machine.script_string))
		{
			machine delete();
		}
	}

	start_machine_names = array("church");
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
	scripts\zm\locs\loc_common::barrier("collision_wall_512x512x10_standard", (-595, -2085, 441), (0, 45, 0), 1);
	scripts\zm\locs\loc_common::barrier("p6_zm_tm_barbedwire_128", (-607, -2062, 191), (0, 45, 0));
	scripts\zm\locs\loc_common::barrier("p6_zm_tm_crate_01", (-684, -2133, 183), (0, 135, 0));
	scripts\zm\locs\loc_common::barrier("p6_zm_tm_crate_01", (-541, -1990, 190), (0, 135, 0));

	scripts\zm\locs\loc_common::barrier("collision_wall_512x512x10_standard", (1371, -1856, 441), (0, -45, 0), 1);
	scripts\zm\locs\loc_common::barrier("p6_zm_tm_barbedwire_128", (1391, -1834, 209), (0, -45, 15));
	scripts\zm\locs\loc_common::barrier("p6_zm_tm_crate_01", (1324, -1760, 213), (-15, 45, 0));
	scripts\zm\locs\loc_common::barrier("p6_zm_tm_crate_01", (1463, -1899, 207), (-15, 45, 0));

	scripts\zm\locs\loc_common::barrier("collision_wall_128x128x10_standard", (763, -1956, 281), (0, 90, 0), 1);
	scripts\zm\locs\loc_common::barrier("p6_zm_tm_barbedwire_128", (743, -1956, 230), (0, 90, 5));

	scripts\zm\locs\loc_common::barrier("collision_wall_128x128x10_standard", (1241, -2951, 306), (0, 0, 0), 1);
	scripts\zm\locs\loc_common::barrier("p6_zm_tm_barricade_wall_02", (1241, -2941, 237), (-30, -90, 0));
}

generatebuildabletarps()
{
	tarp = spawn("script_model", (127, -2987, 48));
	tarp.angles = (0, -75, 0);
	tarp setModel("p6_zm_buildable_bench_tarp");
}

// ============================================================================
//  🛑 v2.17.13 - activate_zone_village_1 ADDED. Same disconnected-arena bug
//  that produced the "zombies freeze then vanish" report on Trenches.
//
//  This arena's valid_zones (below) includes zone_village_2, _3, _3a and _3b,
//  but every link that reaches them is gated on activate_zone_village_1, which
//  was never set:
//      zone_village_1  --activate_zone_village_1--> zone_village_2
//      zone_village_2  --activate_zone_village_1--> zone_village_3
//      zone_village_3  --activate_zone_village_1--> zone_village_3a
//      zone_village_3a --activate_zone_village_1--> zone_village_3b
//
//  So four of the ten zones were enabled for spawning but unreachable from
//  zone_village_1 where the player starts. A zombie spawning in one of them has
//  no path to the player, idles, and is then deleted by stock's distance
//  cleanup for being far and out of view.
//
//  village_1a / 4b / 5b / 6 / 6a all link under activate_zone_village_0 and
//  were already fine - checked against zm_tomb.gsc's add_adjacent_zone list,
//  not assumed.
// ============================================================================
//  🛑 v2.17.14 - activate_zone_village_1 REVERTED, untested, for safety.
//  The same change shape on Trenches (opening the extra zone flags) produced an
//  instant "GAME OVER, Zombies: 0" at full health on the very next boot. Church
//  was never booted with the extra flag, so it is not known to be broken - but
//  it is also not known to be safe, and shipping the identical pattern that
//  just bricked another arena is not a trade worth making. The adjacency gap
//  described above is real; fixing it needs the activate/disable ordering
//  understood first.
enable_zones()
{
	flag_set("activate_zone_village_0");
}

disable_zones()
{
	// ========================================================================
	//  🛑 v2.17.24 - zone_village_2 / _3 / _3a / _3b REMOVED. THEY WERE
	//  SPAWNING ZOMBIES THAT COULD NEVER REACH A PLAYER.
	//
	//  User, 2026-09-15: *"the zombies are acting really sporadic ... they
	//  shouldn't be just like randomly stopping targeting the player and just
	//  walking away to set locations and then just like disappearing."*
	//
	//  🌟 THIS IS ARITHMETIC, NOT A THEORY. Stock's own adjacency table
	//  (maps\mp\zm_tomb.gsc:1376-1394) plus the one flag enable_zones() sets:
	//
	//      under activate_zone_village_0   (SET by this arena)
	//          village_1  <-> village_1a
	//          village_1  <-> village_4b
	//          village_1  <-> village_5b
	//          village_5a <-> village_5b
	//          village_6  <-> village_5b
	//          village_6  <-> village_6a
	//
	//      under activate_zone_village_1   (NEVER SET by this arena)
	//          village_1  <-> village_2        <- the only way in to 2
	//          village_2  <-> village_3
	//          village_3  <-> village_3a
	//          village_3a <-> village_3b
	//
	//  Walking that graph from zone_village_1, where the player starts:
	//      REACHABLE    1, 1a, 4b, 5b, 6, 6a
	//      UNREACHABLE  2, 3, 3a, 3b        <- and all four were in this list
	//
	//  Every route into 2/3/3a/3b is gated on a flag this arena never sets, so
	//  four of the ten zones were enabled for SPAWNING while being cut off from
	//  the player entirely. A zombie that spawns in one has no path to anybody:
	//  it wanders, never targets, and is then culled - by the playspace timeout,
	//  or by stock's distance cleanup for being far and out of view. The live
	//  log shows the cull happening on ROUND 1:
	//      no_bleedout: DEATH WITH NO PLAYER ATTACKER - by=worldspawn/
	//      weapon=none zone=zone_village_4b round=1 left=5
	//
	//  🛑 WHY REMOVE THE ZONES RATHER THAN SET THE FLAG. v2.17.13 set
	//  activate_zone_village_1 and v2.17.14 reverted it untested, because the
	//  same change shape on Trenches produced an instant "GAME OVER, Zombies: 0"
	//  on the next boot. Setting the flag OPENS four new areas and changes what
	//  the arena is. Removing them from this list only stops spawning where a
	//  zombie could never have reached anyone - it cannot open anything, and the
	//  player could not walk to those zones either, for exactly the same missing
	//  links. They are dead space either way.
	//
	//  📝 The adjacency gap has been in the file's comments since v2.17.13 and
	//  was described as "real" then. What was missing was the consequence: the
	//  zones stayed in valid_zones, so the gap was not inert, it was spawning
	//  into it.
	// ========================================================================
	//  🛑 v2.17.28 - REVERTED TO REIMAGINED'S FULL LIST. v2.17.24 removed
	//  zone_village_2/3/3a/3b on the reasoning that every link into them is
	//  gated behind activate_zone_village_1, which this arena never sets.
	//  The arithmetic was right and the conclusion was wrong: BO2-Reimagined -
	//  the source this whole arena was ported from - ships the SAME ten zones
	//  with the SAME single flag, and its zombies behave. So the zone list is
	//  not the defect, and trimming it only removed spawn capacity.
	//  reference\BO2-Reimagined\scripts\zm\locs\zm_tomb_loc_church.gsc:131.
	valid_zones = array("zone_village_1", "zone_village_1a", "zone_village_2", "zone_village_3", "zone_village_3a", "zone_village_3b", "zone_village_4b", "zone_village_5b", "zone_village_6", "zone_village_6a");
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
		if (index == "zone_village_5b")
		{
			foreach (spawn_location in zone.spawn_locations)
			{
				if (spawn_location.origin == (-576, -2048, 192))
				{
					spawn_location.is_enabled = false;
				}
				else if (spawn_location.origin == (-672, -2112, 184))
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
		if (respawn_point.script_noteworthy == "zone_village_5")
		{
			respawn_array = getstructarray(respawn_point.target, "targetname");

			foreach (respawn in respawn_array)
			{
				if (respawn.origin == (-640, -1920, 216))
				{
					arrayremovevalue(respawn_array, respawn);
					break;
				}
			}
		}
		else if (respawn_point.script_noteworthy == "zone_village_3")
		{
			respawn_array = getstructarray(respawn_point.target, "targetname");

			foreach (respawn in respawn_array)
			{
				if (respawn.origin == (1248, -2752, 152))
				{
					arrayremovevalue(respawn_array, respawn);
					break;
				}
			}
		}
	}
}
