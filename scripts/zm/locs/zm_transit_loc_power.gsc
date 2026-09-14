#include maps\mp\zombies\_zm_game_module;
#include maps\mp\zombies\_zm_utility;
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm;
#include maps\mp\zombies\_zm_zonemgr;

struct_init()
{
	scripts\zm\replaced\utility::register_perk_struct("specialty_armorvest", "zombie_vending_jugg", (10952, 8055, -565), (0, 270, 0));
	scripts\zm\replaced\utility::register_perk_struct("specialty_quickrevive", "zombie_vending_quickrevive", (11855, 7308, -758), (0, 220, 0));
	scripts\zm\replaced\utility::register_perk_struct("specialty_fastreload", "zombie_vending_sleight", (11571, 7723, -757), (0, 0, 0));
	scripts\zm\replaced\utility::register_perk_struct("specialty_rof", "zombie_vending_doubletap2", (11414, 8930, -352), (0, 0, 0));
	scripts\zm\replaced\utility::register_perk_struct("specialty_scavenger", "zombie_vending_tombstone", (10946, 8308.77, -408), (0, 270, 0));
	scripts\zm\replaced\utility::register_perk_struct("specialty_weapupgrade", "p6_anim_zm_buildable_pap_on", (12333, 8158, -752), (0, 180, 0));

	structs = getstructarray("player_respawn_point", "targetname");
	respawn_point = undefined;
	zone = "zone_prr";

	foreach (struct in structs)
	{
		if (isdefined(struct.script_noteworthy) && struct.script_noteworthy == zone)
		{
			respawn_point = struct;
			break;
		}
	}

	if (isdefined(respawn_point))
	{
		scripts\zm\replaced\utility::register_map_spawn_group(respawn_point.origin, zone, respawn_point.script_int);

		respawn_array = getstructarray(respawn_point.target, "targetname");

		foreach (respawn in respawn_array)
		{
			angles = respawn.angles;

			if (respawn.origin[0] < 12200)
			{
				angles += (0, 90, 0);
			}
			else
			{
				angles += (0, -90, 0);
			}

			scripts\zm\replaced\utility::register_map_spawn(respawn.origin, angles, zone);
		}
	}

	zone = "zone_pow";
	scripts\zm\replaced\utility::register_map_spawn_group((10160, 7820, -541), zone, 6000);

	scripts\zm\replaced\utility::register_map_spawn((10160, 8060, -541), (0, 0, 0), zone, 1);
	scripts\zm\replaced\utility::register_map_spawn((10160, 7996, -541), (0, 0, 0), zone, 1);
	scripts\zm\replaced\utility::register_map_spawn((10160, 7932, -541), (0, 0, 0), zone, 1);
	scripts\zm\replaced\utility::register_map_spawn((10160, 7868, -541), (0, 0, 0), zone, 1);
	scripts\zm\replaced\utility::register_map_spawn((10160, 7772, -541), (0, 0, 0), zone, 2);
	scripts\zm\replaced\utility::register_map_spawn((10160, 7708, -541), (0, 0, 0), zone, 2);
	scripts\zm\replaced\utility::register_map_spawn((10160, 7644, -541), (0, 0, 0), zone, 2);
	scripts\zm\replaced\utility::register_map_spawn((10160, 7580, -541), (0, 0, 0), zone, 2);

	zone = "zone_pow_warehouse";
	scripts\zm\replaced\utility::register_map_spawn_group((11033, 8587, -387), zone, 6000);

	scripts\zm\replaced\utility::register_map_spawn((11341, 8300, -459), (0, 90, 0), zone);
	scripts\zm\replaced\utility::register_map_spawn((11341, 8587, -387), (0, 90, 0), zone);
	scripts\zm\replaced\utility::register_map_spawn((11341, 8846, -322), (0, 180, 0), zone);
	scripts\zm\replaced\utility::register_map_spawn((10630, 8846, -323), (0, -90, 0), zone);
	scripts\zm\replaced\utility::register_map_spawn((10630, 8451, -379), (0, 0, 0), zone);
	scripts\zm\replaced\utility::register_map_spawn((10884, 8192, -379), (0, 180, 0), zone);
	scripts\zm\replaced\utility::register_map_spawn((11359, 8774, -548), (0, -90, 0), zone);
	scripts\zm\replaced\utility::register_map_spawn((11719, 8608, -547), (0, -90, 0), zone);
}

// zm_qol: populated - see the note in zm_transit_loc_diner.gsc::precache.
precache()
{
	precachemodel( "collision_wall_512x512x10_standard" );
	precachemodel( "p6_zm_buildable_bench_tarp" );
	precachemodel( "p6_zm_buildable_pswitch_body" );
	precachemodel( "p6_zm_buildable_pswitch_hand" );
	precachemodel( "p6_zm_buildable_pswitch_lever" );
	precachemodel( "p6_zm_rocks_large_cluster_01" );
	precachemodel( "p6_zm_rocks_medium_05" );
	precachemodel( "veh_t6_civ_60s_coupe_dead" );
	precachemodel( "veh_t6_civ_microbus_dead" );
	precachemodel( "zm_collision_perks1" );   // loc_common::increase_pap_collision
}

main()
{
	treasure_chest_init();
	init_barriers();
	show_powerswitch();
	activate_core();
	generatebuildabletarps();
	disable_zombie_spawn_locations();
	disable_player_spawn_locations();
	scripts\zm\locs\loc_common::increase_pap_collision();
	level thread scripts\zm\locs\loc_common::init();

	level thread maps\mp\zm_transit::falling_death_init();
}

treasure_chest_init()
{
	chest = getstruct("pow_chest", "script_noteworthy");
	level.chests = [];
	level.chests[0] = chest;
	maps\mp\zombies\_zm_magicbox::treasure_chest_init("pow_chest");
}

init_barriers()
{
	// fog before power station
	origin = (10215, 7275, -570);
	angles = (0, 5, 0);
	scripts\zm\locs\loc_common::barrier("collision_wall_512x512x10_standard", origin + (anglesToUp(angles) * 256), angles, 1);
	scripts\zm\locs\loc_common::barrier("veh_t6_civ_microbus_dead", origin + (anglesToForward(angles) * 90) + (anglesToRight(angles) * 48), angles);
	scripts\zm\locs\loc_common::barrier("veh_t6_civ_60s_coupe_dead", origin + (anglesToForward(angles) * -105) + (anglesToRight(angles) * 48), angles);

	// fog after power station
	origin = (10215, 8720, -579);
	angles = (0, 15, 0);
	scripts\zm\locs\loc_common::barrier("collision_wall_512x512x10_standard", origin + (anglesToForward(angles) * -128) + (anglesToUp(angles) * 256), angles, 1);
	scripts\zm\locs\loc_common::barrier("collision_wall_512x512x10_standard", origin + (anglesToForward(angles) * 104) + (anglesToUp(angles) * 256), angles, 1);
	scripts\zm\locs\loc_common::barrier("p6_zm_rocks_large_cluster_01", origin + (anglesToForward(angles) * -176) + (anglesToRight(angles) * -368) + (anglesToUp(angles) * 256), angles + (0, -15, 0));
	scripts\zm\locs\loc_common::barrier("p6_zm_rocks_medium_05", origin + (anglesToForward(angles) * -600) + (anglesToRight(angles) * -50) + (anglesToUp(angles) * -10), angles + (0, 15, 0));
}

show_powerswitch()
{
	body = spawn("script_model", (12237.4, 8512, -749.9));
	body.angles = (0, 0, 0);
	body setModel("p6_zm_buildable_pswitch_body");

	lever = spawn("script_model", (12237.4, 8503, -703.65));
	lever.angles = (0, 0, 0);
	lever setModel("p6_zm_buildable_pswitch_lever");

	hand = spawn("script_model", (12237.7, 8503.1, -684.55));
	hand.angles = (0, 270, 0);
	hand setModel("p6_zm_buildable_pswitch_hand");
}

activate_core()
{
	reactor_core_mover = getent("core_mover", "targetname");

	maps\mp\zm_transit_power::linkentitiestocoremover(reactor_core_mover);

	reactor_core_mover thread maps\mp\zm_transit_power::coremove(0.05);
}

generatebuildabletarps()
{
	// trap
	tarp = spawn("script_model", (11325, 8170, -488));
	tarp.angles = (0, 0, 0);
	tarp setModel("p6_zm_buildable_bench_tarp");
}

disable_zombie_spawn_locations()
{
	level.zones["zone_trans_8"].is_spawning_allowed = 0;

	// v2.10.3 - THE RISER IN THE WRECKED COUPE (user: a zombie clipping through
	// a barrier car ~30 s in). Measured, not guessed: the POWERSPAWN probe below
	// printed zone_pow's seven enabled spawn locations on the 2026-09-02 boot,
	// and zm_transit.d3dbsp (T6-Data-Archive mapents, guid D3905FC0) names the
	// one at (10010, 7243, -561.3) as a "riser_location" struct of
	// zone_pow_spawners. init_barriers() puts the "fog before power station"
	// wall at (10215, 7275, -570) yaw 5 and the dead coupe at forward*-105 /
	// right*48 of it, i.e. centred near (10110, 7218) - so that riser sits
	// ~14 units on the bus-route side of the wall, inside the coupe's
	// footprint, and every zombie it raises climbs out through the car. The
	// other six zone_pow spawns and the prr / warehouse ones are inside the
	// arena (all origins in checkpoint 191).
	//
	// Same mechanism BO2-Reimagined's zm_prison_loc_docks uses for its two
	// stray docks spawns (spawn_locations[i].is_enabled = false). _zm_zonemgr
	// sets is_enabled in zone_init and enable_zone never resets it; main() runs
	// after transit_zone_init (see scripts\zm\replaced\zm_transit.gsc), so
	// this sticks. The probe thread below prints the result 3 s later.
	zmqol_disable_spawn_location_at( "zone_pow", ( 10010, 7243, -561.3 ) );

	// 2026-09-14 - the two spawn sources that are NOT the arena's own:
	//   * zone_pri (Bus Depot). The replacement in replaced\zm_transit.gsc gives
	//     the zone_trans_8 strip a connected edge to the arena so the stock
	//     initial-zone fallback can no longer reach the Bus Depot - this is the
	//     second lock on the same door. zone_pri is unreachable from the arena's
	//     zones, so its dead spots are simply switched off for this location.
	//   * any spawn location in any of the five arena zones that sits inside a
	//     lava volume. Measured per spot with the game's own brush test, not an
	//     origin guess; the sweep prints whatever it disables.
	zmqol_disable_zone_spawn_locations( "zone_pri" );
	zmqol_disable_lava_spawn_locations();

	level thread zmqol_log_active_spawn_locations();
}

zmqol_disable_spawn_location_at( str_zone, v_origin )
{
	if ( !isdefined( level.zones ) || !isdefined( level.zones[str_zone] ) || !isdefined( level.zones[str_zone].spawn_locations ) )
	{
		println( "[zm_qol] POWERSPAWN disable: " + str_zone + " has no spawn_locations yet" );
		return;
	}

	zone = level.zones[str_zone];
	n_hit = 0;

	for ( i = 0; i < zone.spawn_locations.size; i++ )
	{
		if ( distancesquared( zone.spawn_locations[i].origin, v_origin ) < 64 )
		{
			zone.spawn_locations[i].is_enabled = 0;
			n_hit++;
		}
	}

	println( "[zm_qol] POWERSPAWN disable: " + str_zone + " " + v_origin + " -> " + n_hit + " location(s) disabled" );
}

zmqol_disable_zone_spawn_locations( str_zone )
{
	if ( !isdefined( level.zones ) || !isdefined( level.zones[str_zone] ) || !isdefined( level.zones[str_zone].spawn_locations ) )
	{
		println( "[zm_qol] POWERSPAWN zone off: " + str_zone + " has no spawn_locations" );
		return;
	}

	zone = level.zones[str_zone];
	n_off = 0;

	for ( i = 0; i < zone.spawn_locations.size; i++ )
	{
		if ( isdefined( zone.spawn_locations[i].is_enabled ) && !zone.spawn_locations[i].is_enabled )
			continue;

		zone.spawn_locations[i].is_enabled = 0;
		n_off++;
	}

	println( "[zm_qol] POWERSPAWN zone off: " + str_zone + " -> " + n_off + " location(s) disabled" );
}

zmqol_disable_lava_spawn_locations()
{
	a_volumes = getentarray( "lava_volume", "script_noteworthy" );

	if ( !isdefined( a_volumes ) || a_volumes.size == 0 )
	{
		println( "[zm_qol] POWERSPAWN lava sweep: no lava volumes in this map - skipped" );
		return;
	}

	a_zones = array( "zone_prr", "zone_pow", "zone_pow_warehouse", "zone_pcr", "zone_trans_8" );
	n_off = 0;

	foreach ( str_zone in a_zones )
	{
		if ( !isdefined( level.zones ) || !isdefined( level.zones[str_zone] ) || !isdefined( level.zones[str_zone].spawn_locations ) )
			continue;

		zone = level.zones[str_zone];

		for ( i = 0; i < zone.spawn_locations.size; i++ )
		{
			s_loc = zone.spawn_locations[i];

			if ( !isdefined( s_loc ) || !isdefined( s_loc.origin ) )
				continue;

			if ( isdefined( s_loc.is_enabled ) && !s_loc.is_enabled )
				continue;

			//  A spawn struct is not a solid entity, so the brush test is made
			//  from a throwaway script_origin at the spot - the same call Die
			//  Rise's classic script makes on one (zm_highrise_classic.gsc:409).
			e_probe = spawn( "script_origin", s_loc.origin );

			foreach ( v_volume in a_volumes )
			{
				if ( e_probe istouching( v_volume ) )
				{
					s_loc.is_enabled = 0;
					n_off++;
					println( "[zm_qol] POWERSPAWN lava: " + str_zone + " (" + int( s_loc.origin[0] ) + "," + int( s_loc.origin[1] ) + "," + int( s_loc.origin[2] ) + ") is inside lava - disabled" );
					break;
				}
			}

			e_probe delete();
		}
	}

	println( "[zm_qol] POWERSPAWN lava sweep: " + a_volumes.size + " volume(s) checked, " + n_off + " location(s) disabled" );
}

// ============================================================================
//  zm_qol DIAGNOSTIC - kept one boot past v2.10.3 to prove the coupe riser
//  above now prints enabled=0; delete after that.
//
//  Enabling zone_prr / zone_pow / zone_pow_warehouse (needed to stop the instant
//  death - see scripts\zm\replaced\zm_transit.gsc) also activates every zombie
//  spawn location inside them, and at least one sits behind the barrier cars that
//  fence the arena off from the bus route: the user saw a zombie spawn clipping
//  through a wrecked car ~30s in.
//
//  Fixing that needs the exact origins, and the only per-location disabling this
//  loc script does is the single zone_trans_8 line above. This prints every
//  enabled spawn location in the three arena zones ONCE, so the offending ones
//  can be turned off by origin next round - the same way
//  zm_prison_loc_docks::disable_zombie_spawn_locations does it.
//
//  Read-only. Runs once, then stops.
// ============================================================================
zmqol_log_active_spawn_locations()
{
	level endon( "end_game" );
	wait 3;

	a_zones = array( "zone_prr", "zone_pow", "zone_pow_warehouse" );

	foreach ( str_zone in a_zones )
	{
		if ( !isdefined( level.zones ) || !isdefined( level.zones[str_zone] ) )
		{
			println( "[zm_qol] POWERSPAWN " + str_zone + " = NOZONE" );
			continue;
		}

		zone = level.zones[str_zone];

		if ( !isdefined( zone.spawn_locations ) )
		{
			println( "[zm_qol] POWERSPAWN " + str_zone + " = no spawn_locations" );
			continue;
		}

		for ( i = 0; i < zone.spawn_locations.size; i++ )
		{
			s = "[zm_qol] POWERSPAWN " + str_zone + " [" + i + "] org=" + zone.spawn_locations[i].origin;

			if ( isdefined( zone.spawn_locations[i].is_enabled ) )
				s += " enabled=" + zone.spawn_locations[i].is_enabled;
			else
				s += " enabled=UNDEF";

			println( s );
		}
	}
}

disable_player_spawn_locations()
{
	respawnpoints = maps\mp\gametypes_zm\_zm_gametype::get_player_spawns_for_gametype();

	foreach (respawnpoint in respawnpoints)
	{
		if (respawnpoint.script_noteworthy == "zone_pow_warehouse")
		{
			level thread lock_and_unlock_player_spawn_location(respawnpoint, "OnPowDoorWH");
		}
	}
}

lock_and_unlock_player_spawn_location(respawnpoint, flag_str)
{
	respawnpoint.locked = 1;

	flag_wait(flag_str);

	respawnpoint.locked = 0;
}