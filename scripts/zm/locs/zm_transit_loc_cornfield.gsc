#include maps\mp\zombies\_zm_game_module;
#include maps\mp\zombies\_zm_utility;
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm;
#include maps\mp\zombies\_zm_zonemgr;

struct_init()
{
	scripts\zm\replaced\utility::register_perk_struct("", "", (0, 0, 0), (0, 0, 0)); // need this for pap to work
	scripts\zm\replaced\utility::register_perk_struct("specialty_weapupgrade", "p6_anim_zm_buildable_pap_on", (10460, -564, -220), (0, -35, 0));

	// ========================================================================
	//  🛑 v2.16.10 - PERK MACHINES. Cornfield had NONE.
	//
	//  Every other location this mod adds registers four to six perks here -
	//  Tunnel six, Power six, Diner five, Docks three. Cornfield registered
	//  Pack-a-Punch and stopped, so the arena shipped with no perks at all,
	//  which is not a design choice anybody made: it is the same "registered but
	//  never finished" gap as the missing box and the missing lobby caption.
	//  Found by audit, 2026-09-15, after the user asked for "full integrity
	//  checks ... because it's obviously not right".
	//
	//  🌟 THESE ARE TREYARCH'S OWN CORNFIELD POSITIONS, NOT PICKED BY THIS MOD.
	//  The stock TranZit mapents has a zm_perk_machine struct set tagged
	//  script_string "znml_perks_cornfield" - the perks NML mode puts in this
	//  field. Read out with the Unlinker, 2026-09-15:
	//        zombie_vending_jugg     (10355.1, -1507.9, -213.3)  yaw 260.2
	//        zombie_vending_sleight  ( 9944.8,  -121.7, -211.0)  yaw  21.8
	//  Same geometry, same floor, authored by the people who built the field -
	//  which is a stronger claim than any coordinate this mod could invent, and
	//  the same reasoning the Origins branch of wunderfizz.gsc uses for taking
	//  vanilla machine origins unmodified.
	//
	//  Registered here rather than reused in place because that script_string
	//  binds them to NML; a zstandard game never spawns them. register_perk_struct
	//  is how every other location in this mod puts a machine down.
	//
	//  📝 ONLY TWO, AND THAT IS THE HONEST NUMBER. Those are the only perk
	//  machines the stock map places in this field. The rest of the mod's perk
	//  list is still reachable here through the Wunderfizz that v2.16.10 adds
	//  beside the microbus (scripts\zm\wunderfizz.gsc, the zm_transit branch) -
	//  so the arena has Jugg, Speed Cola, Pack-a-Punch and a spinner for
	//  everything else, rather than six positions this mod made up.
	// ========================================================================
	scripts\zm\replaced\utility::register_perk_struct("specialty_armorvest", "zombie_vending_jugg", (10355.1, -1507.9, -213.3), (0, 260.2, 0));
	scripts\zm\replaced\utility::register_perk_struct("specialty_fastreload", "zombie_vending_sleight", (9944.8, -121.7, -211), (0, 21.8, 0));

	structs = getstructarray("player_respawn_point", "targetname");
	respawn_point = undefined;
	zone = "zone_cornfield_prototype";

	foreach (struct in structs)
	{
		if (isdefined(struct.script_noteworthy) && struct.script_noteworthy == zone)
		{
			respawn_point = struct;
			break;
		}
	}

	respawn_point2 = undefined;
	zone = "zone_amb_cornfield";
	target = "cornfield_nml_player_spawns";

	foreach (struct in structs)
	{
		if (isdefined(struct.script_noteworthy) && struct.script_noteworthy == zone)
		{
			if (isdefined(struct.target) && struct.target == target)
			{
				respawn_point2 = struct;
				break;
			}
		}
	}

	level.struct_class_names["targetname"]["player_respawn_point"] = [];
	level.struct_class_names["script_noteworthy"]["initial_spawn"] = [];

	if (isdefined(respawn_point))
	{
		scripts\zm\replaced\utility::register_map_spawn_group(respawn_point.origin, zone, respawn_point.script_int);

		respawn_array = getstructarray(respawn_point.target, "targetname");

		foreach (respawn in respawn_array)
		{
			scripts\zm\replaced\utility::register_map_spawn(respawn.origin + (150, -150, 0), respawn.angles + (0, 180, 0), zone, respawn.script_int);
		}
	}

	if (isdefined(respawn_point2))
	{
		scripts\zm\replaced\utility::register_map_spawn_group(respawn_point2.origin, zone, respawn_point2.script_int);

		scripts\zm\replaced\utility::register_map_spawn((11986, -1858, -132), (0, 80, 0), zone);
		scripts\zm\replaced\utility::register_map_spawn((12158, -61, -141), (0, -85, 0), zone);
		scripts\zm\replaced\utility::register_map_spawn((11366, 20, -193), (0, -5, 0), zone);
		scripts\zm\replaced\utility::register_map_spawn((11199, -1768, -156), (0, -5, 0), zone);
		scripts\zm\replaced\utility::register_map_spawn((10448, 90, -189), (0, -5, 0), zone);
		scripts\zm\replaced\utility::register_map_spawn((10255, -1698, -186), (0, -5, 0), zone);
		scripts\zm\replaced\utility::register_map_spawn((10046, -591, -192), (0, 0, 0), zone);
		scripts\zm\replaced\utility::register_map_spawn((10036, -967, -186), (0, 0, 0), zone);
	}

	structs = getstructarray("game_mode_object", "targetname");

	foreach (struct in structs)
	{
		if (isDefined(struct.script_noteworthy) && struct.script_noteworthy == "cornfield")
		{
			struct.script_string = "zstandard zgrief";
		}
	}

	intermission_cam = spawnStruct();
	intermission_cam.origin = (10266, 470, -90);
	intermission_cam.angles = (0, -90, 0);
	intermission_cam.targetname = "intermission";
	intermission_cam.script_string = "cornfield";
	intermission_cam.speed = 30;
	intermission_cam.target = "intermission_cornfield_end";
	scripts\zm\replaced\utility::add_struct(intermission_cam);

	intermission_cam_end = spawnStruct();
	intermission_cam_end.origin = (10216, -1224, -199);
	intermission_cam_end.angles = (0, -90, 0);
	intermission_cam_end.targetname = "intermission_cornfield_end";
	scripts\zm\replaced\utility::add_struct(intermission_cam_end);
}

// zm_qol: populated - see the note in zm_transit_loc_diner.gsc::precache.
precache()
{
	precachemodel( "collision_wall_128x128x10_standard" );
	precachemodel( "collision_wall_512x512x10_standard" );
	precachemodel( "veh_t6_civ_microbus_dead" );
	precachemodel( "veh_t6_civ_smallwagon_dead" );
	precachemodel( "zm_collision_perks1" );   // loc_common::increase_pap_collision

	// The play area's outer boundary volume. This was previously removed on the
	// belief that the model did not exist in the stock game - it does, in
	// so_zsurvival_zm_transit.ff, and it is now pulled into mod.ff by
	// zone_source/mod_locations.zone, so it is registered on every map and mode.
	precachemodel( "zm_collision_transit_cornfield_survival" );

	//  v2.16.10 - the moved mystery box's own collision
	//  (zmqol_cornfield_box_collision). common_zm.ff carries this model
	//  (parsed\retail_lists\common_zm.list.txt, Unlinker --list), so it is
	//  loaded on every zombies map and costs mod.ff nothing. Same line Tunnel
	//  has carried since v2.14.30, for the same reason.
	precachemodel( "collision_geo_32x32x32_standard" );
}

main()
{
	treasure_chest_init();
	init_barriers();
	disable_zombie_spawn_locations();
	maps\mp\gametypes_zm\_zm_gametype::setup_standard_objects("cornfield");
	scripts\zm\locs\loc_common::increase_pap_collision();
	level thread scripts\zm\locs\loc_common::init();
}

// ============================================================================
//  treasure_chest_init  -  ONE of TranZit's six stock chests, moved into the
//                          cornfield.                              (v2.16.10)
// ----------------------------------------------------------------------------
//  🛑 CORNFIELD HAD NO MYSTERY BOX AT ALL, and had not since it was registered.
//  User, 2026-09-15: *"i also forgot about that, the no mystery box - just add a
//  mystery box in a location that makes sense, like in the cornfield in one of
//  the pathways or something, and make sure the positioning is correct."*
//
//  WHY IT WAS MISSING. This function used to read:
//        chest = getstruct( "cornfield_chest", "script_noteworthy" );
//        level.chests[0] = chest;
//        maps\mp\zombies\_zm_magicbox::treasure_chest_init( "cornfield_chest" );
//  There IS no cornfield_chest struct. The stock TranZit mapents carries exactly
//  six chest names - depot / farm / pow / start / town / town_chest_2 - and
//  cornfield_chest is not among them (Unlinker mapents dump, grep'd 2026-09-15;
//  the same check zm_transit_loc_tunnel.gsc ran for tunnel_chest in v2.14.30 and
//  got the same answer). getstruct() returned undefined, assigning undefined
//  left level.chests EMPTY, and _zm_magicbox::treasure_chest_init() took its
//  `if ( level.chests.size == 0 ) return;` exit - silently, as T6 does. No box,
//  no error, nothing in the log.
//
//  THE FIX IS TUNNEL'S, because Tunnel hit this first and it is proven in game:
//  do not ADD a seventh chest struct - classic TranZit builds its own box list
//  with getstructarray( "treasure_chest_use" ) over the whole map, so a new
//  struct would leak into classic. MOVE a stock one instead, for this location
//  only, and take its zbarrier with it.
//
//  📝 NO CINDER BLOCKS HERE, unlike Tunnel. Tunnel's box origin came out of
//  Reimagined's map and floated over stock road, so that file stacks blocks
//  under it. This one traces its own floor (see zmqol_cornfield_box_origin) and
//  the box's underside IS its origin - p6_anim_zm_magic_box measures z 0..19.2,
//  measured in the v2.14.32 session - so it sits ON the dirt with nothing to
//  pack under it.
// ============================================================================
treasure_chest_init()
{
	level.chests = getstructarray( "treasure_chest_use", "targetname" );

	s_chest = zmqol_cornfield_bring_chest_in();

	if ( isdefined( s_chest ) )
	{
		level.chests = [];
		level.chests[0] = s_chest;

		maps\mp\zombies\_zm_magicbox::treasure_chest_init( s_chest.script_noteworthy );

		println( "[zm_qol] cornfield: magic box list = " + level.chests.size + " chest(s) - " + s_chest.script_noteworthy + " moved into the field" );
		return;
	}

	//  Nothing to move. Leave the stock map-wide list alone rather than shipping
	//  an empty one, and say so - a silent no-box is what this whole block exists
	//  to stop happening again.
	println( "[zm_qol] cornfield: NO chest moved - see above. Box list left at " + level.chests.size );

	maps\mp\zombies\_zm_magicbox::treasure_chest_init( "start_chest" );
}

// ============================================================================
//  zmqol_cornfield_box_origin  -  where the box stands, floored by a trace.
//
//  WHERE: (10900, -150) by default, the open lane along the north of the field.
//  Picked off the stock mapents rather than by eye:
//    - nothing of any class is within 190 units of it, so it is not being put
//      inside something that is already there;
//    - a stock cornfield_standard_player_respawns struct sits 223 away and a
//      zone_amb_cornfield_spawners riser_location 199 away, and BOTH are proof
//      of walkable ground - players stand on one and zombies climb out of the
//      other;
//    - it is roughly mid-field between the Pack-a-Punch cluster in the west
//      (10460,-564) and the open east half, so it is on the way rather than in
//      a corner.
//
//  🛑 THE Z IS TRACED, NEVER WRITTEN DOWN. The cornfield floor is not flat and
//  its pathnode grid sits ~120 units above the props where every other TranZit
//  region has the usual ~30 (measured against the stock dump, 2026-09-15), so
//  no hand-written height for this field is trustworthy. The ray starts 200
//  above the seed and runs 400 down, which straddles every floor height the
//  field's own props record (-131 at the east end to -218 at the west).
//
//  The three dvars are for live tuning only - set them before the map loads.
//  They default to the shipped position, so a normal boot reads nothing.
// ============================================================================
zmqol_cornfield_box_origin()
{
	n_x = getdvarintdefault( "zmqol_cornfield_box_x", 10900 );
	n_y = getdvarintdefault( "zmqol_cornfield_box_y", -150 );

	v_seed = ( n_x, n_y, -195 );

	trace = bullettrace( v_seed + ( 0, 0, 200 ), v_seed - ( 0, 0, 200 ), 0, undefined );

	if ( trace["fraction"] >= 1 )
	{
		println( "[zm_qol] cornfield box: NO floor found at (" + n_x + "," + n_y + ") - using the seed height " + v_seed[2] );
		return v_seed;
	}

	v_at = ( n_x, n_y, trace["position"][2] );

	println( "[zm_qol] cornfield box: floor at (" + n_x + "," + n_y + ") is " + int( v_at[2] ) + " (seed was " + int( v_seed[2] ) + ")" );

	return v_at;
}

// ============================================================================
//  zmqol_cornfield_bring_chest_in  -  same shape as the Tunnel's, and for the
//  same reason. Prefers start_chest (the Bus Depot's), which no other survival
//  location on this map uses, and falls back to whatever is first in the list.
//
//  A chest is TWO entities: the script_struct "treasure_chest_use" that
//  level.chests holds, and a zbarrier_zmcore_MagicBox entity found by
//  script_noteworthy "<name>_zbarrier". Both have to move or the box's lid
//  animates somewhere the player is not standing.
// ============================================================================
zmqol_cornfield_bring_chest_in()
{
	v_box = zmqol_cornfield_box_origin();
	n_yaw = getdvarintdefault( "zmqol_cornfield_box_yaw", 90 );

	s_chest = undefined;

	for ( i = 0; i < level.chests.size; i++ )
	{
		if ( isdefined( level.chests[i].script_noteworthy ) && level.chests[i].script_noteworthy == "start_chest" )
		{
			s_chest = level.chests[i];
			break;
		}
	}

	if ( !isdefined( s_chest ) && level.chests.size > 0 )
		s_chest = level.chests[0];

	if ( !isdefined( s_chest ) || !isdefined( s_chest.script_noteworthy ) )
	{
		println( "[zm_qol] cornfield box: no treasure_chest_use struct to move" );
		return undefined;
	}

	e_zb = getent( s_chest.script_noteworthy + "_zbarrier", "script_noteworthy" );

	if ( !isdefined( e_zb ) )
	{
		println( "[zm_qol] cornfield box: " + s_chest.script_noteworthy + " has no _zbarrier entity - not moved" );
		return undefined;
	}

	while ( n_yaw < 0 )
		n_yaw += 360;
	while ( n_yaw >= 360 )
		n_yaw -= 360;

	v_was = s_chest.origin;

	s_chest.origin = v_box;
	s_chest.angles = ( 0, n_yaw, 0 );
	s_chest.start_exclude = undefined;

	e_zb.origin = v_box;
	e_zb.angles = ( 0, n_yaw, 0 );

	zmqol_cornfield_box_collision( v_box, n_yaw );

	println( "[zm_qol] cornfield box: " + s_chest.script_noteworthy + " moved from (" + int( v_was[0] ) + "," + int( v_was[1] ) + "," + int( v_was[2] ) + ") to (" + int( v_box[0] ) + "," + int( v_box[1] ) + "," + int( v_box[2] ) + ") yaw " + n_yaw + " - zbarrier reads back at (" + int( e_zb.origin[0] ) + "," + int( e_zb.origin[1] ) + "," + int( e_zb.origin[2] ) + ")" );

	return s_chest;
}

// ============================================================================
//  zmqol_cornfield_box_collision  -  the box blocks players and paths zombies.
//
//  A stock chest's solidity is world clip baked into the map at ITS spot; move
//  the chest and the clip stays behind, leaving a box players walk through.
//  Three collision_geo_32x32x32_standard models at -32 / 0 / +32 along the
//  box's forward, +1 along its right and +16 up cover p6_anim_zm_magic_box's
//  footprint (-47.8..+47.8 by -12.3..+14.3, measured in the v2.14.32 session)
//  while leaving the use-side unitrigger room to wrap a player standing against
//  it. Identical to zmqol_tunnel_box_collision, which booted 2026-09-08.
// ============================================================================
zmqol_cornfield_box_collision( v_box, n_yaw )
{
	if ( isdefined( level.zmqol_cornfield_box_clips ) )
		return;

	v_fwd = anglestoforward( ( 0, n_yaw, 0 ) );
	v_rgt = anglestoright( ( 0, n_yaw, 0 ) );
	v_mid = v_box + ( v_rgt[0] * 1, v_rgt[1] * 1, 16 );

	a_at = [];
	a_at[0] = v_mid + ( v_fwd[0] * 32, v_fwd[1] * 32, 0 );
	a_at[1] = v_mid;
	a_at[2] = v_mid - ( v_fwd[0] * 32, v_fwd[1] * 32, 0 );

	level.zmqol_cornfield_box_clips = [];

	for ( i = 0; i < a_at.size; i++ )
	{
		clip = spawn( "script_model", a_at[i], 1 );
		clip.angles = ( 0, n_yaw, 0 );
		clip setmodel( "collision_geo_32x32x32_standard" );
		clip.script_noteworthy = "zmqol_cornfield_box_clip";
		clip ghost();
		clip disconnectpaths();

		level.zmqol_cornfield_box_clips[ level.zmqol_cornfield_box_clips.size ] = clip;
	}

	println( "[zm_qol] cornfield box: " + level.zmqol_cornfield_box_clips.size + " collision clip(s) spawned at yaw " + n_yaw );
}

init_barriers()
{
	// Restored: the invisible wall that keeps players inside the cornfield.
	collision = spawn("script_model", (10500, -850, 0), 1);
	collision setmodel("zm_collision_transit_cornfield_survival");
	collision disconnectpaths();

	// cornfield left
	origin = (9720, -1090, -212);
	angles = (0, 90, 0);
	scripts\zm\locs\loc_common::barrier("collision_wall_512x512x10_standard", origin + (anglesToRight(angles) * 24) + (anglesToUp(angles) * 256), angles, 1);
	scripts\zm\locs\loc_common::barrier("veh_t6_civ_smallwagon_dead", origin, angles);

	// cornfield right
	origin = (9900, -232, -217);
	angles = (0, -90, 0);
	scripts\zm\locs\loc_common::barrier("collision_wall_512x512x10_standard", origin + (anglesToRight(angles) * -48) + (anglesToUp(angles) * 256), angles, 1);
	scripts\zm\locs\loc_common::barrier("collision_wall_512x512x10_standard", origin + (anglesToForward(angles) * 256) + (anglesToRight(angles) * -48) + (anglesToUp(angles) * 256), angles, 1);
	scripts\zm\locs\loc_common::barrier("veh_t6_civ_microbus_dead", origin, angles);

	// cornfield right corner
	origin = (9982, -142, -217);
	angles = (0, 35, 0);
	scripts\zm\locs\loc_common::barrier("collision_wall_128x128x10_standard", origin + (anglesToUp(angles) * 64), angles, 1);
	scripts\zm\locs\loc_common::barrier("veh_t6_civ_smallwagon_dead", origin + (anglesToForward(angles) * 15) + (anglesToRight(angles) * -50), angles + (0, 165, 0));
}

disable_zombie_spawn_locations()
{
	for (z = 0; z < level.zone_keys.size; z++)
	{
		if (level.zone_keys[z] != "zone_amb_cornfield")
		{
			continue;
		}

		zone = level.zones[level.zone_keys[z]];

		i = 0;

		while (i < zone.spawn_locations.size)
		{
			if (zone.spawn_locations[i].origin[0] <= 9700)
			{
				zone.spawn_locations[i].is_enabled = false;
			}

			i++;
		}
	}
}