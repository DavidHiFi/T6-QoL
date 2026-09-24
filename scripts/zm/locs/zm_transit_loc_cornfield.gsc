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
	//  🛑 NO PERK MACHINES HERE, AND THAT IS CORRECT. DO NOT ADD THEM BACK.
	//
	//  v2.16.10 briefly registered Juggernog and Speed Cola at the positions the
	//  stock mapents tags "znml_perks_cornfield". Both were WRONG and both are
	//  reverted, in the same session they were added (user, 2026-09-15, with a
	//  screenshot of the Speed Cola machine wedged between two wrecked cars:
	//  *"you put this speed cola machine inside of this car here, it's all
	//  bugged ... was that even in the reimagined mod to begin with?"*).
	//
	//  TWO SEPARATE FAULTS, BOTH WORTH RECORDING SO NOBODY REPEATS THEM:
	//
	//  1. IT IS NOT IN THE SOURCE THIS LOCATION IS PORTED FROM. Checked against
	//     Jbleezy/BO2-Reimagined master, 2026-09-15: their
	//     scripts\zm\locs\zm_transit_loc_cornfield.gsc struct_init registers the
	//     empty placeholder and Pack-a-Punch, and NOTHING else. Cornfield has no
	//     perk machines in Reimagined. The "every other location registers four
	//     to six" reasoning that added them was an argument from symmetry, not
	//     evidence, and symmetry is not how this file's other positions were won.
	//
	//  2. THE STOCK NML SPOT IS INSIDE THIS MOD'S OWN BARRIERS. Speed Cola's
	//     znml position is (9944.8, -121.7, -211). init_barriers() below spawns
	//     veh_t6_civ_microbus_dead at (9900, -232, -217) and a second
	//     veh_t6_civ_smallwagon_dead at (9982, -142, -217) to wall off the west
	//     exit - so the machine lands BETWEEN two cars that do not exist in NML,
	//     which is why Treyarch's spot was clear and ours was not. Any future
	//     placement in this arena has to be checked against init_barriers(), not
	//     just against the stock mapents.
	//
	//  The perk list stays reachable through the Wunderfizz that v2.16.10 adds
	//  (scripts\zm\wunderfizz.gsc, the zm_transit branch), which is how this
	//  arena is meant to hand out perks.
	// ========================================================================

	structs = getstructarray("player_respawn_point", "targetname");
	respawn_point = undefined;
	//  🛑 SEPARATE LOCALS. Reusing one `zone` and reassigning it meant the
	//  prototype block at the second register call ran with the field zone
	//  still in scope, so both groups emitted the same target and all 16
	//  points joined one ~3,400-unit pool. Solo never hits the path; co-op
	//  respawns had ~50% odds of landing at the far end of the arena.
	zone_proto = "zone_cornfield_prototype";

	foreach (struct in structs)
	{
		if (isdefined(struct.script_noteworthy) && struct.script_noteworthy == zone_proto)
		{
			respawn_point = struct;
			break;
		}
	}

	respawn_point2 = undefined;
	zone_field = "zone_amb_cornfield";
	target = "cornfield_nml_player_spawns";

	foreach (struct in structs)
	{
		if (isdefined(struct.script_noteworthy) && struct.script_noteworthy == zone_field)
		{
			if (isdefined(struct.target) && struct.target == target)
			{
				respawn_point2 = struct;
				break;
			}
		}
	}

	//  Wipe only when at least one group will be re-registered, so an empty
	//  match cannot blank the stock pool first (same shape as the Borough bug).
	if (isdefined(respawn_point) || isdefined(respawn_point2))
	{
		level.struct_class_names["targetname"]["player_respawn_point"] = [];
		level.struct_class_names["script_noteworthy"]["initial_spawn"] = [];
	}

	if (isdefined(respawn_point))
	{
		scripts\zm\replaced\utility::register_map_spawn_group(respawn_point.origin, zone_proto, respawn_point.script_int);

		respawn_array = getstructarray(respawn_point.target, "targetname");

		foreach (respawn in respawn_array)
		{
			scripts\zm\replaced\utility::register_map_spawn(respawn.origin + (150, -150, 0), respawn.angles + (0, 180, 0), zone_proto, respawn.script_int);
		}
	}

	if (isdefined(respawn_point2))
	{
		scripts\zm\replaced\utility::register_map_spawn_group(respawn_point2.origin, zone_field, respawn_point2.script_int);

		scripts\zm\replaced\utility::register_map_spawn((11986, -1858, -132), (0, 80, 0), zone_field);
		scripts\zm\replaced\utility::register_map_spawn((12158, -61, -141), (0, -85, 0), zone_field);
		scripts\zm\replaced\utility::register_map_spawn((11366, 20, -193), (0, -5, 0), zone_field);
		scripts\zm\replaced\utility::register_map_spawn((11199, -1768, -156), (0, -5, 0), zone_field);
		scripts\zm\replaced\utility::register_map_spawn((10448, 90, -189), (0, -5, 0), zone_field);
		scripts\zm\replaced\utility::register_map_spawn((10255, -1698, -186), (0, -5, 0), zone_field);
		scripts\zm\replaced\utility::register_map_spawn((10046, -591, -192), (0, 0, 0), zone_field);
		scripts\zm\replaced\utility::register_map_spawn((10036, -967, -186), (0, 0, 0), zone_field);
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

	//  v2.16.13 - what the box STANDS on (zmqol_cornfield_box_bricks).
	//  zm_transit.ff OWNS this model - parsed\retail_lists\zm_transit.list.txt
	//  line 3792, "xmodel, p_glo_cinder_block" - so nothing is added to mod.ff.
	//  Same line Tunnel has carried since v2.14.32.
	precachemodel( "p_glo_cinder_block" );
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
//  WHERE: (13337, 72) - REIMAGINED'S OWN cornfield_chest, by the Nacht der
//  Untoten building at the east end of the arena.
//
//  🛑 THE FIRST ATTEMPT PUT IT AT (10900,-150) AND THAT WAS WRONG. User,
//  2026-09-15, with a screenshot of the box standing in dense corn: *"the
//  mystery box is in the middle of the field, make sure that the positions are
//  correct and they're in the correct area"*, having asked for it *"in one of
//  the pathways"*. That seed was chosen for being EMPTY in the stock mapents,
//  which is not the same thing as being somewhere a player would walk - an
//  uncut cornfield is empty of entities everywhere.
//
//  🌟 REIMAGINED ALREADY ANSWERED THIS AND THE ANSWER WAS FINDABLE. Their
//  treasure_chest_init() is byte-identical to the one this file used to carry,
//  including the getstruct( "cornfield_chest" ) that finds nothing - because
//  THEY SHIP A MODIFIED MAP. Jbleezy/BO2-Reimagined master,
//  maps\mp\zm_transit.d3dbsp line 26796, carries a treasure_chest_use struct
//  script_noteworthy "cornfield_chest" at origin (13337, 72, -179) angles
//  (0,180,0), plus its cornfield_chest_zbarrier twin at the same spot. That is
//  the position the script this location was ported from was written against,
//  and the reason the port looked complete while doing nothing.
//
//  🌟 THE STOCK MAP DATA AGREES IT IS REAL GROUND, which the old seed's did
//  not. Within 130 units of it the stock mapents has a pathnode at z -167.8, a
//  cornfield_standard_player_respawns initial_spawn at z -165.4 and a
//  zone_cornfield_prototype_spawners riser_location at z -197.3 - so nodes sit
//  the usual ~10-30 above the props here. Out in the open field they sat ~120
//  above, which is the measurement that should have warned against (10900,-150)
//  in the first place.
//
//  🛑 THE Z IS TRACED ACROSS THE WHOLE FOOTPRINT, NOT AT ONE POINT.
//
//  v2.16.12 traced a single ray at the box's centre and sat the box on whatever
//  it hit. User, 2026-09-15, with a screenshot of the box in the Nacht
//  building: *"move it up a little bit, because right now it's too far into the
//  ground - the right side of the box is like in the ground ... it just needs to
//  be pushed upwards so it's not clipping into the ground as much."*
//
//  A centre trace cannot do this. p6_anim_zm_magic_box is ~96 units long
//  (-47.8..+47.8 along its forward) and the dirt under it is not level, so the
//  centre's floor height buries whichever end sits on higher ground. The fix is
//  to trace SIX columns along the box's length and take the HIGHEST floor of
//  them: the box then rests on the high point and every other column has air
//  under it, which is the gap the cinder blocks below fill.
//
//  🌟 AND YES, THERE ARE BRICKS - the user remembered correctly: *"doesn't it
//  have like bricks underneath it that hold the box up? i could have sworn."*
//  Reimagined's _zm_reimagined::spawn_mystery_box_blocks_and_collision() stacks
//  four p_glo_cinder_block_big under BOTH their tunnel_chest and their
//  cornfield_chest, and this mod's own Tunnel has carried a stock-block version
//  since v2.14.32. Cornfield shipped without them in v2.16.12 on the reasoning that a
//  floor trace made them unnecessary. It did not, and they are back - see
//  zmqol_cornfield_box_bricks().
//
//  The three dvars are for live tuning only - set them before the map loads.
//  They default to the shipped position, so a normal boot reads nothing.
//  zmqol_cornfield_box_lift is a final nudge on top of the traced height, for
//  the same reason Tunnel keeps one: the ground is the ground.
// ============================================================================
zmqol_cornfield_box_origin( n_yaw )
{
	n_x = getdvarintdefault( "zmqol_cornfield_box_x", 13337 );
	n_y = getdvarintdefault( "zmqol_cornfield_box_y", 72 );

	v_seed = ( n_x, n_y, -179 );
	v_fwd  = anglestoforward( ( 0, n_yaw, 0 ) );

	//  Along the box's own length, the same six columns the bricks use.
	a_along = array( 40, 24, 8, -8, -24, -40 );

	n_high = undefined;
	s_floors = "";

	for ( i = 0; i < a_along.size; i++ )
	{
		v_col = ( v_seed[0] + v_fwd[0] * a_along[i], v_seed[1] + v_fwd[1] * a_along[i], v_seed[2] );

		trace = bullettrace( v_col + ( 0, 0, 200 ), v_col - ( 0, 0, 200 ), 0, undefined );

		if ( trace["fraction"] >= 1 )
		{
			s_floors = s_floors + " none";
			continue;
		}

		n_floor = trace["position"][2];
		s_floors = s_floors + " " + int( n_floor );

		if ( !isdefined( n_high ) || n_floor > n_high )
			n_high = n_floor;
	}

	if ( !isdefined( n_high ) )
	{
		println( "[zm_qol] cornfield box: NO floor under any column at (" + n_x + "," + n_y + ") - using the seed height " + int( v_seed[2] ) );
		return v_seed;
	}

	n_lift = getdvarintdefault( "zmqol_cornfield_box_lift", 2 );

	v_at = ( n_x, n_y, n_high + n_lift );

	println( "[zm_qol] cornfield box: floor per column:" + s_floors + "  -> highest " + int( n_high ) + " + lift " + n_lift + " = z " + int( v_at[2] ) );

	return v_at;
}

// ============================================================================
//  zmqol_cornfield_box_bricks  -  the box stands on cinder blocks, not in the
//                                 dirt.                             (v2.16.13)
//
//  Same shape as zmqol_tunnel_box_bricks, which booted 2026-09-09, and the same
//  thing Reimagined does under their own copy of this chest. Six columns along
//  the box's length; each one bullettraces ITS OWN floor and stacks as many
//  8-high courses as that column needs, so a sloped or rubble-strewn floor gets
//  a stepped stack rather than a flat one and the bottom course beds INTO the
//  ground instead of hovering over it.
//
//  MEASURED (v2.14.32 session, Unlinker GLB dump, lod0 accessor bounds - those
//  GLBs are Y-UP, checked against com_trafficcone01 in the same dump):
//      p_glo_cinder_block   16 long x 8 HIGH x 8 deep, centred on its origin
//      p6_anim_zm_magic_box +-47.8 along forward, -12.3..+14.3 along right,
//                           0..19.2 up - so the box's UNDERSIDE is its origin's
//                           z exactly, and everything below it is air.
//
//  This mod uses the STOCK p_glo_cinder_block, not Reimagined's 1.5x rescale:
//  that model is theirs, shipped raw in their model_export\, and is in no retail
//  fastfile. The stock one is owned by zm_transit.ff, so it costs mod.ff
//  nothing - the same reasoning Tunnel's copy records.
// ============================================================================
zmqol_cornfield_box_bricks( v_box, n_yaw )
{
	v_fwd = anglestoforward( ( 0, n_yaw, 0 ) );
	v_rgt = anglestoright( ( 0, n_yaw, 0 ) );

	a_along  = array( 40, 24, 8, -8, -24, -40 );
	a_jitter = array( -7, 5, -3, 8, -6, 4 );

	if ( isdefined( level.zmqol_cornfield_bricks ) )
		return;

	level.zmqol_cornfield_bricks = [];

	s_floors = "";
	n_blind = 0;

	for ( i = 0; i < a_along.size; i++ )
	{
		//  +1 along right is the box's own width centre (-12.3..+14.3), the same
		//  offset its collision clips use.
		v_col = v_box + ( v_fwd[0] * a_along[i], v_fwd[1] * a_along[i], 0 ) + ( v_rgt[0], v_rgt[1], 0 );

		trace = bullettrace( v_col - ( 0, 0, 2 ), v_col - ( 0, 0, 160 ), 0, undefined );

		if ( trace["fraction"] < 1 )
		{
			n_floor = trace["position"][2];
			s_floors = s_floors + " " + int( n_floor );
		}
		else
		{
			//  No floor within 160 units. Do not build a tower into a hole: one
			//  course, so the box is not bare, and say so in the log.
			n_floor = v_box[2] - 8;
			n_blind++;
			s_floors = s_floors + " none";
		}

		//  Courses, rounded UP so the bottom one beds into the ground. int()
		//  truncates and T6 has no integer ceil worth trusting here, hence +7.99.
		n_courses = int( ( ( v_box[2] - n_floor ) + 7.99 ) / 8 );

		if ( n_courses < 1 )
			n_courses = 1;

		if ( n_courses > 4 )
			n_courses = 4;

		for ( c = 0; c < n_courses; c++ )
		{
			brick = spawn( "script_model", v_col - ( 0, 0, 4 + c * 8 ) );
			brick.angles = ( 0, n_yaw + 90 + a_jitter[i] + c * 3, 0 );
			brick setmodel( "p_glo_cinder_block" );
			brick.script_noteworthy = "zmqol_cornfield_box_brick";
			level.zmqol_cornfield_bricks[ level.zmqol_cornfield_bricks.size ] = brick;
		}
	}

	s_blind = "";

	if ( n_blind > 0 )
		s_blind = "  (" + n_blind + " column(s) found NO floor within 160)";

	println( "[zm_qol] cornfield box bricks: " + level.zmqol_cornfield_bricks.size + " cinder blocks under a box at z " + int( v_box[2] ) + " - floor per column:" + s_floors + s_blind );
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
	//  180 is Reimagined's own angle for this chest, from the same struct.
	n_yaw = getdvarintdefault( "zmqol_cornfield_box_yaw", 180 );

	//  The yaw is needed BEFORE the origin: the height comes from six columns
	//  traced along the box's own length, which depends on which way it faces.
	v_box = zmqol_cornfield_box_origin( n_yaw );

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

	zmqol_cornfield_box_bricks( v_box, n_yaw );
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