#include maps\mp\zm_buried_gamemodes;
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_game_module;
#include maps\mp\gametypes_zm\_zm_gametype;
#include maps\mp\zombies\_zm_buildables;
#include maps\mp\zm_buried;
#include maps\mp\zm_buried_classic;
#include maps\mp\zm_buried_turned_street;
#include maps\mp\zm_buried_grief_street;
#include maps\mp\zombies\_zm_zonemgr;
#include maps\mp\zombies\_zm_weapons;
#include maps\mp\zombies\_zm_unitrigger;

// ============================================================================
//  Replaces maps\mp\zm_buried_gamemodes::init to register BOROUGH ("street")
//  as a SURVIVAL start. Stock Buried registers NO zstandard gamemode at all
//  (verified against the stock zm_buried_gamemodes dump: only zclassic,
//  zcleansed and zgrief), so survival on Borough is entirely an addition here.
//
//  Restored 2026-09-02 from the pre-strip copy (git d722590), minus the Maze
//  location (excluded from the restoration by the user's request). Borough
//  never got a working boot pre-strip - zombies spawned but stood frozen.
//  What is NEW this time, and is the suspected missing piece: the buried
//  zombie XANIM assets are now declared in zone_source\mod_locations.zone.
//  The pre-strip build declared the aitypes, characters and xmodels but not
//  one xanim, and the animations live only in so_zclassic_zm_buried.ff /
//  so_zencounter_zm_buried.ff - neither of which a zstandard run loads. An AI
//  whose animations do not exist cannot play its locomotion. BO2-Reimagined's
//  own zone (zone_source\includes\zm_buried.zone) declares 433 xanims; the
//  pre-strip zone declared zero. See the zone file for the measured list.
// ============================================================================
init()
{
	add_map_gamemode("zclassic", maps\mp\zm_buried::zclassic_preinit, undefined, undefined);
	add_map_gamemode("zstandard", ::zstandard_preinit, undefined, undefined);
	add_map_gamemode("zgrief", maps\mp\zm_buried::zgrief_preinit, undefined, undefined);
	add_map_gamemode("zcleansed", maps\mp\zm_buried::zcleansed_preinit, undefined, undefined);

	add_map_location_gamemode("zclassic", "processing", maps\mp\zm_buried_classic::precache, maps\mp\zm_buried_classic::main);

	add_map_location_gamemode("zstandard", "street", maps\mp\zm_buried_grief_street::precache, ::borough_survival_main);

	add_map_location_gamemode("zgrief", "street", maps\mp\zm_buried_grief_street::precache, maps\mp\zm_buried_grief_street::main);

	add_map_location_gamemode("zcleansed", "street", maps\mp\zm_buried_turned_street::precache, maps\mp\zm_buried_turned_street::main);

	// zm_qol: Borough's wallbuys. The three wallbuys standing in the street are
	// tagged "zgrief_street" only, which never matches "zstandard_street".
	// Without this, Borough survival has no wallbuys. Grief is untouched: it
	// already matches.
	scripts\zm\replaced\utility::add_struct_location_gamemode_func("zstandard", "street", ::street_struct_init);

	// ========================================================================
	//  v2.17.0 - MAZE (Buried's hedge maze), restored.
	//
	//  Cut in v1.15.0 with the rest of the ported locations. The loc script
	//  never left scripts\zm\locs\ and already carries its zm_qol adaptation
	//  (precache list populated, _zm_race_utility include dropped because that
	//  script is in no fastfile, zone_mansion guarded).
	//
	//  🌟 UNLIKE BOROUGH, MAZE NEEDS NO RE-TAGGING struct_init OF ITS OWN.
	//  Borough's wallbuys are tagged "zgrief_street" only, which is why
	//  street_struct_init above exists. This mod's own zm_buried.d3dbsp already
	//  carries 21 "zstandard_maze" + 4 "zstandard_perks_maze" entities - the
	//  same counts as BO2-Reimagined's copy - so the stock match works and the
	//  loc script's own struct_init is all that is required.
	//
	//  Box and Wunderfizz are both already inside the arena and needed no new
	//  placement: maze_treasure_chest_init() pins level.chests to maze_chest1 /
	//  maze_chest2 (both present in the mapents) and starts the box at one of
	//  them, and the mod's Buried Wunderfizz at (4910,725,2) sits 148 units
	//  from an arena spawn point.
	// ========================================================================
	add_map_location_gamemode("zstandard", "maze", scripts\zm\locs\zm_buried_loc_maze::precache, scripts\zm\locs\zm_buried_loc_maze::main);
	add_map_location_gamemode("zgrief", "maze", scripts\zm\locs\zm_buried_loc_maze::precache, scripts\zm\locs\zm_buried_loc_maze::main);

	scripts\zm\replaced\utility::add_struct_location_gamemode_func("zstandard", "maze", scripts\zm\locs\zm_buried_loc_maze::struct_init);
	scripts\zm\replaced\utility::add_struct_location_gamemode_func("zgrief", "maze", scripts\zm\locs\zm_buried_loc_maze::struct_init);
}

// See loc_common::enable_wallbuys for why re-tagging has to happen here, in a
// struct_init, rather than later. Origins copied verbatim from the zm_buried
// mapents dump.
street_struct_init()
{
	a_wallbuys = [];
	a_wallbuys[a_wallbuys.size] = ( -926.25, 510.5, 68 );   // rottweil72_zm
	a_wallbuys[a_wallbuys.size] = ( 609.5, 772.75, 54 );    // m14_zm
	a_wallbuys[a_wallbuys.size] = ( 1.1, 1201.9, 68 );      // mp5k_zm
	scripts\zm\locs\loc_common::enable_wallbuys( a_wallbuys );

	// ========================================================================
	//  v2.10.8 - THE BOROUGH PERK LAYOUT IS BO2-REIMAGINED'S CURRENT ONE.
	//
	//  User, 2026-09-02: "Update the Borough layout to match JBleazy's updated
	//  BO2 Reimagined setup (including the Pack-a-Punch machine location)."
	//
	//  Measured, not copied by eye: Reimagined's shipped maps\mp\zm_buried.d3dbsp
	//  carries seven zm_perk_machine structs tagged "zstandard_perks_street
	//  zgrief_perks_street" (parsed 2026-09-02). This mod's own copy of that file
	//  is an older Reimagined revision with NO street-tagged struct at all, so
	//  the seven are registered here through the same struct system the
	//  previous six used; nothing about classic Buried changes. The mule-kick
	//  struct is the stock classic one retagged in Reimagined's file - same
	//  origin as before. Vulture Aid's machine is gone (Reimagined puts Quick
	//  Revive on that pad); the perk itself stays on Borough through the
	//  Wunderfizz - zmqol_enable_vulture_on_borough() is unchanged.
	//
	//  Every model below is in zm_buried.ff (Unlinker --list, 2026-09-02).
	// ========================================================================
	scripts\zm\replaced\utility::register_perk_struct( "specialty_fastreload", "zombie_vending_sleight", ( -170.5, -328.25, 144 ), ( 0, 90, 0 ) );
	scripts\zm\replaced\utility::register_perk_struct( "specialty_rof", "zombie_vending_doubletap2", ( 2328, 936.5, 88 ), ( 0, 180, 0 ) );
	scripts\zm\replaced\utility::register_perk_struct( "specialty_longersprint", "zombie_vending_marathon", ( 761.63, 1542.25, 0 ), ( 0, 0, 0 ) );
	scripts\zm\replaced\utility::register_perk_struct( "specialty_quickrevive", "zombie_vending_revive", ( 1443, 2303.5, 16 ), ( 0, 340, 0 ) );
	scripts\zm\replaced\utility::register_perk_struct( "specialty_armorvest", "zombie_vending_jugg", ( -665.13, 1069.13, 9.49 ), ( 0, 0, 0 ) );
	scripts\zm\replaced\utility::register_perk_struct( "specialty_additionalprimaryweapon", "zombie_vending_three_gun", ( -711, -1249.5, 140.5 ), ( 0, 180, 0 ) );
	scripts\zm\replaced\utility::register_perk_struct( "specialty_weapupgrade", "p6_anim_zm_buildable_pap", ( 1205.61, 698.608, -17.68 ), ( 0, 191.4, 0 ) );
}

// ============================================================================
//  borough_survival_main  -  Borough survival, laid out like BO2-Reimagined
//  (v2.10.8). Ported from scripts\zm\replaced\zm_buried_grief_street.gsc::main
//  and zm_buried_reimagined.gsc::player_initial_spawn_override, diffed against
//  stock zm_buried_grief_street.gsc::main line by line:
//
//    stock main (still run below)     what Reimagined adds, now ported
//    ------------------------------   ---------------------------------------
//    pap pre-built, team pickup       zone_mansion disabled
//    think_buildables                 disable_tunnels(): 5 collision walls +
//    setup_standard_objects           2 sloth blockers + planks/couch/bench
//    chests, tarps, sloth barricades  in the bank tunnel, 7 tunnel/bank zones
//    powerswitch, map collision       off, zone_start + tunnel player spawns
//    12 chalk wallbuys, 3 buildables  locked
//    turnperkon x7                    initial spawns = the stables respawn set
//                                     zone_toy_store <-> zone_candy_store edge
//                                     magic box list: 4 chests (no tunnels_chest)
//
//  NOT ported, on purpose (Reimagined balance, not layout): its 5-gun chalk
//  set replacing stock's 12, its head-chopper buildable (needs a client twin
//  this mod does not ship), and its mapents-level wallbuy weapon swaps.
//
//  🛑 Stock main precaches/spawns zm_collision_buried_street_grief and
//  p6_zm_bu_buildable_bench_tarp, which exist ONLY in so_zencounter_zm_buried.ff
//  (all-fastfile xmodel sweep, 2026-09-02) - a zstandard run never loads it.
//  Both are now declared in zone_source\mod_locations.zone so mod.ff carries
//  them; without that, spawnmapcollision() had nothing to spawn on Borough.
// ============================================================================
borough_survival_main()
{
	level thread borough_remove_chalk();
	borough_restrict_zones();
	borough_zone_edges();
	borough_player_initial_spawn_override();
	borough_disable_tunnels();
	maps\mp\zm_buried_grief_street::main();
	borough_chest_list();
}

// Reimagined zm_buried.gsc::buried_zone_init adds exactly one edge to stock's
// list (normalised diff, 2026-09-02). Zones exist here: manage_zones() ran
// zone_manager_init_func from the map's main before this location main.
borough_zone_edges()
{
	if ( !isDefined( level.zones ) || !isDefined( level.zones["zone_toy_store"] ) || !isDefined( level.zones["zone_candy_store"] ) )
		return;

	maps\mp\zombies\_zm_zonemgr::add_adjacent_zone( "zone_toy_store", "zone_candy_store", "always_on" );
}

// Reimagined street_treasure_chest_init drops the tunnels chest (it is behind
// the blockers now). Stock's init already ran inside grief_street::main with the
// 5-chest list, box at start_chest (index 0); this re-points level.chests to
// the same four Reimagined keeps, start_chest still index 0 so level.chest_index
// stays valid. Reimagined also randomises the START chest; that needs a box
// move this project has no verified call for, so the start stays stock's.
borough_chest_list()
{
	start_chest = getstruct( "start_chest", "script_noteworthy" );
	court_chest = getstruct( "courtroom_chest1", "script_noteworthy" );
	jail_chest = getstruct( "jail_chest1", "script_noteworthy" );
	gun_chest = getstruct( "gunshop_chest", "script_noteworthy" );

	level.chests = [];
	level.chests[level.chests.size] = start_chest;
	level.chests[level.chests.size] = court_chest;
	level.chests[level.chests.size] = jail_chest;
	level.chests[level.chests.size] = gun_chest;

	println( "[zm_qol] borough: magic box list = 4 chests (tunnels_chest dropped)" );
}

// Verbatim from Reimagined scripts\zm\replaced\zm_buried_grief_street.gsc::
// disable_tunnels, 2026-09-02. Models: collision_* are in common_zm.ff;
// p6_zm_bu_sloth_blocker_medium, p6_zm_bu_wood_planks_106x171,
// p6_zm_bu_victorian_couch, p6_zm_work_bench are in zm_buried.ff (Unlinker).
borough_disable_tunnels()
{
	// main tunnel saloon side
	origin = ( 770, -863, 320 );
	angles = ( 0, 180, -35 );
	model = spawn( "script_model", origin + anglesToUp( angles ) * 128, 1 );
	model.angles = angles;
	model setmodel( "collision_wall_256x256x10_standard" );
	model disconnectpaths();
	model = spawn( "script_model", origin );
	model.angles = angles;
	model setmodel( "p6_zm_bu_sloth_blocker_medium" );

	// main tunnel courthouse side
	origin = ( 349, 579, 240 );
	angles = ( 0, 0, -10 );
	model = spawn( "script_model", origin + anglesToUp( angles ) * 64, 1 );
	model.angles = angles;
	model setmodel( "collision_wall_128x128x10_standard" );
	model disconnectpaths();
	model = spawn( "script_model", origin );
	model.angles = angles;
	model setmodel( "p6_zm_bu_sloth_blocker_medium" );

	// main tunnel above general store
	origin = ( -123, -801, 326 );
	angles = ( 0, 0, 90 );
	model = spawn( "script_model", origin, 1 );
	model.angles = angles;
	model setmodel( "collision_wall_128x128x10_standard" );
	model disconnectpaths();

	// main tunnel above jail
	origin = ( -852, 408, 379 );
	angles = ( 0, 0, 90 );
	model = spawn( "script_model", origin, 1 );
	model.angles = angles;
	model setmodel( "collision_wall_512x512x10_standard" );
	model disconnectpaths();

	// main tunnel above stables
	origin = ( -713, -313, 287 );
	angles = ( 0, 0, 90 );
	model = spawn( "script_model", origin, 1 );
	model.angles = angles;
	model setmodel( "collision_wall_128x128x10_standard" );
	model disconnectpaths();

	// bank top
	model = spawn( "script_model", ( -381.252, -443.056, 144.125 ), 1 );
	model.angles = ( 0, 0, 0 );
	model setmodel( "collision_wall_128x128x10_standard" );
	model disconnectpaths();
	model = spawn( "script_model", ( -371.839, -448.016, 224.125 ) );
	model.angles = ( 0, 180, -90 );
	model setmodel( "p6_zm_bu_wood_planks_106x171" );

	// bank tunnel
	model = spawn( "script_model", ( -53.4637, -1165.89, 8.125 ), 1 );
	model.angles = ( 0, 0, 0 );
	model setmodel( "collision_geo_64x64x128_standard" );
	model disconnectpaths();
	model = spawn( "script_model", ( -54.6069, -1129.47, 6.125 ) );
	model.angles = ( 0, 0, 0 );
	model setmodel( "p6_zm_bu_wood_planks_106x171" );
	model = spawn( "script_model", ( -92.6853, -1075.92, 8.125 ) );
	model.angles = ( 0, 140, 0 );
	model setmodel( "p6_zm_bu_sloth_blocker_medium" );
	model = spawn( "script_model", ( -40.3028, -1158.31, 3.125 ) );
	model.angles = ( 0, -90, -15 );
	model setmodel( "p6_zm_bu_victorian_couch" );
	model = spawn( "script_model", ( -75.4725, -1156.37, 52.125 ) );
	model.angles = ( 0, 0, 180 );
	model setmodel( "p6_zm_work_bench" );

	// player spawns: the start zone and the three tunnel spawns are locked
	invalid_zones = array( "zone_start", "zone_tunnels_center", "zone_tunnels_north", "zone_tunnels_south" );
	spawn_points = maps\mp\gametypes_zm\_zm_gametype::get_player_spawns_for_gametype();

	foreach ( spawn_point in spawn_points )
	{
		if ( isDefined( spawn_point.script_noteworthy ) && isinarray( invalid_zones, spawn_point.script_noteworthy ) )
			spawn_point.locked = 1;
	}
}

// Verbatim from Reimagined zm_buried_reimagined.gsc::player_initial_spawn_override
// (street branch), 2026-09-02: the initial spawns become the zone_stables
// respawn set, with Reimagined's per-point facing angles.
borough_player_initial_spawn_override()
{
	level.struct_class_names["script_noteworthy"]["initial_spawn"] = [];

	ind = 0;
	respawn_points = maps\mp\gametypes_zm\_zm_gametype::get_player_spawns_for_gametype();

	for ( i = 0; i < respawn_points.size; i++ )
	{
		if ( isDefined( respawn_points[i].script_noteworthy ) && respawn_points[i].script_noteworthy == "zone_stables" )
		{
			ind = i;
			break;
		}
	}

	if ( !isDefined( respawn_points[ind] ) || !isDefined( respawn_points[ind].target ) )
	{
		println( "[zm_qol] borough: no zone_stables respawn point - initial spawns left as stock" );
		return;
	}

	respawn_array = getstructarray( respawn_points[ind].target, "targetname" );

	foreach ( respawn in respawn_array )
	{
		struct = spawnStruct();
		struct.origin = respawn.origin;
		struct.angles = respawn.angles;
		struct.radius = respawn.radius;
		struct.script_int = respawn.script_int;
		struct.script_noteworthy = "initial_spawn";
		struct.script_string = "zstandard_street zgrief_street";

		if ( struct.origin == ( -875.5, -33.85, 139.25 ) )
			struct.angles = ( 0, 10, 0 );
		else if ( struct.origin == ( -910.13, -90.16, 139.59 ) )
			struct.angles = ( 0, 20, 0 );
		else if ( struct.origin == ( -921.9, -134.67, 140.62 ) )
			struct.angles = ( 0, 30, 0 );
		else if ( struct.origin == ( -891.27, -209.95, 137.94 ) )
		{
			struct.angles = ( 0, 55, 0 );
			struct.script_int = 2;
		}
		else if ( struct.origin == ( -836.66, -257.92, 133.16 ) )
			struct.angles = ( 0, 65, 0 );
		else if ( struct.origin == ( -763, -259.07, 127.72 ) )
			struct.angles = ( 0, 90, 0 );
		else if ( struct.origin == ( -737.98, -212.92, 125.4 ) )
			struct.angles = ( 0, 85, 0 );
		else if ( struct.origin == ( -722.02, -151.75, 124.14 ) )
		{
			struct.angles = ( 0, 80, 0 );
			struct.script_int = 1;
		}

		size = level.struct_class_names["script_noteworthy"][struct.script_noteworthy].size;
		level.struct_class_names["script_noteworthy"][struct.script_noteworthy][size] = struct;
	}

	println( "[zm_qol] borough: initial spawns = " + respawn_array.size + " stables respawn points" );
}

borough_restrict_zones()
{
	// Origins of this list: BO2-Reimagined scripts\zm\replaced\
	// zm_buried_grief_street::disable_tunnels, minus its collision-wall models
	// (stock already seals the arena with zm_collision_buried_street_grief).
	a_zones = [];
	a_zones[a_zones.size] = "zone_tunnels_center";
	a_zones[a_zones.size] = "zone_tunnels_north";
	a_zones[a_zones.size] = "zone_tunnels_north2";
	a_zones[a_zones.size] = "zone_tunnels_south";
	a_zones[a_zones.size] = "zone_tunnels_south2";
	a_zones[a_zones.size] = "zone_tunnels_south3";
	a_zones[a_zones.size] = "zone_bank";
	a_zones[a_zones.size] = "zone_mansion";

	foreach ( str_zone in a_zones )
	{
		if ( !isDefined( level.zones ) || !isDefined( level.zones[str_zone] ) )
		{
			continue;
		}

		level.zones[str_zone].is_enabled = 0;
		level.zones[str_zone].is_spawning_allowed = 0;
	}
}

borough_remove_chalk()
{
	level endon( "end_game" );

	flag_wait( "start_zombie_round_logic" );

	// stock main does builddynamicwallbuys() at start_zombie_round_logic + 1s;
	// stay clear of it.
	wait 4;

	maps\mp\zm_buried_gamemodes::deletechalktriggers();
}

zstandard_preinit()
{
	survival_init();
}

survival_init()
{
	level.force_team_characters = 1;
	level.should_use_cia = 0;

	if (randomint(100) >= 50)
	{
		level.should_use_cia = 1;
	}

	level.precachecustomcharacters = ::precache_team_characters;
	level.givecustomcharacters = ::give_team_characters;
	zm_buried_common_init();
	flag_wait("start_zombie_round_logic");
	trig_removal = getentarray("zombie_door", "targetname");

	foreach (trig in trig_removal)
	{
		if (isdefined(trig.script_parameters) && trig.script_parameters == "grief_remove")
		{
			trig delete();
		}
	}
}
