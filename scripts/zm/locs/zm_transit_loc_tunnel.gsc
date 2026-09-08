#include maps\mp\zombies\_zm_game_module;
#include maps\mp\zombies\_zm_utility;
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm;
#include maps\mp\zombies\_zm_zonemgr;

// ============================================================================
//  TRANZIT SURVIVAL - THE TUNNEL                                    (v2.14.30)
// ----------------------------------------------------------------------------
//  Ported from BO2-Reimagined's scripts\zm\locs\zm_transit_loc_tunnel.gsc.
//  First shipped pre-v1.15.0 and verified in game 2026-08-02, stripped in
//  v1.15.0, restored 2026-09-02, REMOVED in v2.14.0 (2026-09-06, "remove
//  tunnel survival") and put back on 2026-09-08 at the user's request: *"add
//  back tunnel survival i dont know why you removed it, it was fine, and add a
//  mystery box to it."*
//
//  Everything below treasure_chest_init() is the pre-removal file (git
//  88b714e^), byte for byte. The mystery box is the one new thing, and it is
//  new for a reason the old file hid:
//
//  🛑 THE OLD TUNNEL NEVER HAD A BOX, AND THE OLD CODE COULD NOT SAY SO.
//  Reimagined's treasure_chest_init() - copied verbatim into the old file -
//  does getstruct( "tunnel_chest", "script_noteworthy" ). That struct exists
//  ONLY in Reimagined's modified zm_transit.d3dbsp (their mapents line 26760,
//  with a zbarrier_zmcore_MagicBox entity "tunnel_chest_zbarrier" beside it).
//  This mod's maps\mp\zm_transit.d3dbsp is the STOCK entity list (git d630e08
//  reverted the wholesale Reimagined import; grep'd 2026-09-08: six chests,
//  depot / farm / pow / start / town / town_chest_2, no tunnel_chest). So
//  getstruct() returned undefined, `level.chests[0] = undefined` left the
//  array empty, and _zm_magicbox::treasure_chest_init() took its
//  `if ( level.chests.size == 0 ) return;` exit - silently, as T6 does.
//
//  Adding the two entities to the mod's mapents was rejected: _zm_magicbox::
//  init() builds CLASSIC's box list with getstructarray( "treasure_chest_use" )
//  over the whole map, so a seventh chest struct would enter classic TranZit's
//  box rotation. Reimagined accepts that (it changes classic); this mod does
//  not. Instead one of the stock chests is MOVED into the tunnel from script,
//  which is exactly what The Crazy Place does on Origins
//  (zm_tomb_loc_crazy_place::zmqol_cp_bring_chest_into_arena, booted and
//  confirmed 2026-09-08). Classic never runs this file.
// ============================================================================

struct_init()
{
	scripts\zm\replaced\utility::register_perk_struct("specialty_armorvest", "zombie_vending_jugg", (-11541, -2630, 194), (0, -180, 0));
	scripts\zm\replaced\utility::register_perk_struct("specialty_quickrevive", "zombie_vending_quickrevive", (-10780, -2565, 224), (0, 274, 0));
	scripts\zm\replaced\utility::register_perk_struct("specialty_fastreload", "zombie_vending_sleight", (-11373, -1674, 192), (0, -89, 0));
	scripts\zm\replaced\utility::register_perk_struct("specialty_rof", "zombie_vending_doubletap2", (-10660, -756, 195), (0, 262, 0));
	scripts\zm\replaced\utility::register_perk_struct("specialty_longersprint", "zombie_vending_marathon", (-11681, -734, 228), (0, -19, 0));
	scripts\zm\replaced\utility::register_perk_struct("specialty_weapupgrade", "p6_anim_zm_buildable_pap_on", (-11301, -2096, 184), (0, 115, 0));

	zone = "zone_amb_tunnel";
	scripts\zm\replaced\utility::register_map_spawn_group((-11246, -1695, 220), zone, 1000);
	scripts\zm\replaced\utility::register_map_spawn((-11406, -667, 220), (0, -6, 0), zone, 1);
	scripts\zm\replaced\utility::register_map_spawn((-11568, -1179, 220), (0, 0, 0), zone, 1);
	scripts\zm\replaced\utility::register_map_spawn((-11473, -1924, 220), (0, -15, 0), zone, 1);
	scripts\zm\replaced\utility::register_map_spawn((-11457, -2400, 220), (0, 2, 0), zone, 1);
	scripts\zm\replaced\utility::register_map_spawn((-10971, -770, 220), (0, 164, 0), zone, 2);
	scripts\zm\replaced\utility::register_map_spawn((-11009, -1126, 220), (0, 179, 0), zone, 2);
	scripts\zm\replaced\utility::register_map_spawn((-11028, -1996, 220), (0, -176, 0), zone, 2);
	scripts\zm\replaced\utility::register_map_spawn((-11017, -2384, 220), (0, -176, 0), zone, 2);
	scripts\zm\replaced\utility::register_map_spawn((-10916, -408, 220), (0, -100, 0), zone);
	scripts\zm\replaced\utility::register_map_spawn((-10965, -2987, 220), (0, 95, 0), zone);

	// zm_qol: the tunnel's M16 wallbuy is tagged "zclassic_transit" in the stock
	// map. Confirmed to sit in zone_amb_tunnel (its nearest neighbours in the
	// mapents dump are zone_amb_tunnel_spawners and a zone_amb_tunnel respawn
	// point), so it belongs to this location.
	// 🛑 EXACT TWIN in scripts\zm\zm_expanded.csc::zmqol_enable_wallbuys() -
	// the clientfield is named "<weapon>_<origin>" on both sides.
	a_wallbuys = [];
	a_wallbuys[a_wallbuys.size] = ( -11839, -1695.1, 287 );  // m16_zm
	scripts\zm\locs\loc_common::enable_wallbuys( a_wallbuys );
}

// zm_qol: populated - see the note in zm_transit_loc_diner.gsc::precache.
precache()
{
	precachemodel( "collision_wall_512x512x10_standard" );
	precachemodel( "veh_t6_civ_60s_coupe_dead" );
	precachemodel( "veh_t6_civ_movingtrk_cab_dead" );
	precachemodel( "veh_t6_civ_smallwagon_dead" );
	precachemodel( "zm_collision_perks1" );   // loc_common::increase_pap_collision

	//  v2.14.30 - the moved box's own collision (zmqol_tunnel_box_collision).
	//  common_zm.ff carries the model (parsed\retail_lists\common_zm.list.txt,
	//  Unlinker --list), so it is loaded on every zombies map.
	precachemodel( "collision_geo_32x32x32_standard" );

	//  v2.14.32 - what the box STANDS on (zmqol_tunnel_box_bricks). zm_transit.ff
	//  OWNS this model - parsed\retail_lists\zm_transit.list.txt line 3792,
	//  "xmodel, p_glo_cinder_block" with no leading comma, the same form as
	//  veh_t6_civ_60s_coupe_dead two lines below it, which this precache has
	//  been asking for since the location shipped. Nothing added to mod.ff.
	precachemodel( "p_glo_cinder_block" );
}

main()
{
	treasure_chest_init();
	init_barriers();
	disable_zombie_spawn_locations();
	scripts\zm\locs\loc_common::increase_pap_collision();
	level thread scripts\zm\locs\loc_common::init();

	//  `.boxhere` - placement probe, see zmqol_tunnel_box_here().
	level.zmqol_box_here_func = ::zmqol_tunnel_box_here;
}

// ============================================================================
//  treasure_chest_init  -  ONE of TranZit's six stock chests, moved into the
//  tunnel.                                                          (v2.14.30)
// ----------------------------------------------------------------------------
//  HOW A CHEST IS BUILT on this map, measured from the stock zm_transit
//  mapents dump and _zm_magicbox.gsc, not assumed:
//    * a script_struct "treasure_chest_use" (origin, angles, zombie_cost 950,
//      script_noteworthy "<name>") - the thing level.chests holds;
//    * a "zbarrier_zmcore_MagicBox" ENTITY with script_noteworthy
//      "<name>_zbarrier". _zm_magicbox::get_chest_pieces() finds it by that
//      name and it IS the box - model, lid, gun rise, teddy, glow all hang
//      off it. 🛑 On THIS map the zbarrier carries the SAME yaw as its struct
//      (start_chest 0/0, depot_chest 180/180 - stock mapents 26536-26570),
//      unlike Origins where it is struct + 180. Reimagined's tunnel pair is
//      89/89, the same convention, so both writes below use one yaw.
//    * the use prompt is a unitrigger _zm_magicbox builds at
//      origin + anglestoright( struct.angles ) * -22.5, i.e. on the struct's
//      LEFT-hand side. That fixes the facing: the side players use is the
//      -right vector. At yaw 89 that is world -x, west, INTO the tunnel; the
//      wall is at +right, east.
//
//  WHERE: (-10803, -1897, 208) / (0, 89, 0) - Reimagined's own tunnel_chest
//  entity, verbatim (their zm_transit.d3dbsp, lines 26757-26792). Shipped and
//  played in their mod, which is the only measured placement there is; the
//  `.boxhere` probe below is the correction path if it sits wrong here.
//
//  The move is two writes - the struct and its zbarrier - done BEFORE
//  _zm_magicbox::treasure_chest_init() reads either. With ONE chest in
//  level.chests that function takes its size == 1 branch: chest_index 0,
//  no_fly_away = 1, no teddy, no "moving_chest_enabled" - the box stays put.
//  Same single-chest shape as Power Station's pow_chest and the Crazy Place.
//
//  Which chest: start_chest (the Bus Depot's) by preference - it is the one
//  farthest from any TranZit survival arena and nothing non-classic ever
//  references it by name (grep'd this mod and the stock dump) - else the
//  first chest in the list. Nothing else in the stock mapents shares a
//  chest's origin (only the pair itself), so no collision brush is left
//  behind at the old spot; and a moved zbarrier has NO collision of its own
//  (the Crazy Place lesson - stock's is world clip baked at each chest's
//  spot), hence zmqol_tunnel_box_collision().
// ============================================================================
treasure_chest_init()
{
	level.chests = getstructarray( "treasure_chest_use", "targetname" );

	s_chest = zmqol_tunnel_bring_chest_in();

	if ( isdefined( s_chest ) )
	{
		level.chests = [];
		level.chests[0] = s_chest;
	}

	maps\mp\zombies\_zm_magicbox::treasure_chest_init( "start_chest" );

	if ( isdefined( s_chest ) )
		println( "[zm_qol] tunnel: magic box list = " + level.chests.size + " chest(s) - " + s_chest.script_noteworthy + " moved into the tunnel" );
	else
		println( "[zm_qol] tunnel: magic box list = " + level.chests.size + " chest(s), NONE moved - see above" );
}

zmqol_tunnel_bring_chest_in()
{
	//  Reimagined's tunnel_chest, verbatim.
	v_box = ( -10803, -1897, 208 );
	n_yaw = 89;

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
		println( "[zm_qol] tunnel box: no treasure_chest_use struct to move" );
		return undefined;
	}

	e_zb = getent( s_chest.script_noteworthy + "_zbarrier", "script_noteworthy" );

	if ( !isdefined( e_zb ) )
	{
		println( "[zm_qol] tunnel box: " + s_chest.script_noteworthy + " has no _zbarrier entity - not moved" );
		return undefined;
	}

	v_was = s_chest.origin;
	zmqol_tunnel_place_box( s_chest, e_zb, v_box, n_yaw );

	println( "[zm_qol] tunnel box: " + s_chest.script_noteworthy + " moved from (" + int( v_was[0] ) + "," + int( v_was[1] ) + "," + int( v_was[2] ) + ") to (" + int( v_box[0] ) + "," + int( v_box[1] ) + "," + int( v_box[2] ) + ") yaw " + n_yaw + " - zbarrier reads back at (" + int( e_zb.origin[0] ) + "," + int( e_zb.origin[1] ) + "," + int( e_zb.origin[2] ) + ") yaw " + int( e_zb.angles[1] ) );

	return s_chest;
}

//  Struct and zbarrier at the same origin and the same yaw - this map's own
//  convention (see the banner). Then what it stands on, then the collision.
//
//  🛑 BRICKS BEFORE CLIPS, and it matters: zmqol_tunnel_box_bricks() traces
//  DOWN for the floor, and the clips zmqol_tunnel_box_collision() spawns are
//  solid script_models filling box z .. box z + 32. The trace starts 2 units
//  UNDER the box origin, below them either way, but running the bricks first
//  keeps the first placement clear of them entirely.
zmqol_tunnel_place_box( s_chest, e_zb, v_box, n_yaw )
{
	while ( n_yaw < 0 )
		n_yaw += 360;
	while ( n_yaw >= 360 )
		n_yaw -= 360;

	s_chest.origin = v_box;
	s_chest.angles = ( 0, n_yaw, 0 );
	s_chest.start_exclude = undefined;

	e_zb.origin = v_box;
	e_zb.angles = ( 0, n_yaw, 0 );

	zmqol_tunnel_box_bricks( v_box, n_yaw );
	zmqol_tunnel_box_collision( v_box, n_yaw );
}

// ============================================================================
//  zmqol_tunnel_box_collision  -  the box blocks players (and paths zombies).
//
//  p6_anim_zm_magic_box, the box this map uses (zm_transit.list.txt), dumped
//  with the Unlinker (glb lod0 accessor bounds, 2026-09-06 session, re-read
//  2026-09-08): length x -47.8..+47.8 along the zbarrier's forward, width
//  -12.3 (front, the use side) .. +14.3 (back, where j_hinge sits at -12.26)
//  along its right, height 0..19.2. So three collision_geo_32x32x32_standard
//  script_models at -32 / 0 / +32 along forward, +1 along right, +16 up cover
//  the footprint (-48..+48 by -15..+17) with 3 units to spare on the use side
//  - tight enough that the unitrigger (origin -22.5 along right, length 45)
//  still wraps a player standing against the clip (player bbox 15: centre at
//  30, trigger spans 0..45). Spawned the way stock spawns a perk machine's
//  clip (_zm_perks.gsc:2898: spawn(...,1) + disconnectpaths) and ghost()ed
//  like Buried's ffotd clips. Centre-origin convention: the same one the
//  Crazy Place's 64-cubes use, booted and accepted 2026-09-08.
// ============================================================================
zmqol_tunnel_box_collision( v_box, n_yaw )
{
	v_fwd = anglestoforward( ( 0, n_yaw, 0 ) );
	v_rgt = anglestoright( ( 0, n_yaw, 0 ) );
	v_mid = v_box + ( v_rgt[0] * 1, v_rgt[1] * 1, 16 );

	a_at = [];
	a_at[0] = v_mid + ( v_fwd[0] * 32, v_fwd[1] * 32, 0 );
	a_at[1] = v_mid;
	a_at[2] = v_mid - ( v_fwd[0] * 32, v_fwd[1] * 32, 0 );

	if ( !isdefined( level.zmqol_tunnel_box_clips ) )
	{
		level.zmqol_tunnel_box_clips = [];

		for ( i = 0; i < a_at.size; i++ )
		{
			clip = spawn( "script_model", a_at[i], 1 );
			clip.angles = ( 0, n_yaw, 0 );
			clip setmodel( "collision_geo_32x32x32_standard" );
			clip.script_noteworthy = "zmqol_tunnel_box_clip";
			clip ghost();
			clip disconnectpaths();
			level.zmqol_tunnel_box_clips[i] = clip;
		}

		println( "[zm_qol] tunnel box: 3 collision clips spawned, centre (" + int( a_at[1][0] ) + "," + int( a_at[1][1] ) + "," + int( a_at[1][2] ) + ") yaw " + n_yaw );
		return;
	}

	for ( i = 0; i < a_at.size; i++ )
	{
		clip = level.zmqol_tunnel_box_clips[i];

		if ( !isdefined( clip ) )
			continue;

		clip connectpaths();
		clip.origin = a_at[i];
		clip.angles = ( 0, n_yaw, 0 );
		clip disconnectpaths();
	}
}

// ============================================================================
//  zmqol_tunnel_box_bricks  -  the box stands on cinder blocks, not on air.
//                                                                    (v2.14.32)
//  User, 2026-09-09, with a screenshot: *"i like the location for the box,
//  however the bricks underneath box itself are missing so it's just floating
//  right now"*. The box's stock spot had map geometry under it; the tunnel spot
//  is bare road, and a zbarrier brings nothing of its own with it.
//
//  PRECEDENT: Reimagined hit this first. Their tunnel_chest and cornfield_chest
//  float in their own map too, so _zm_reimagined::spawn_mystery_box_blocks_and_
//  collision() spawns four p_glo_cinder_block_big under each - block yaw = box
//  yaw + 90 (the block's long axis lies ACROSS the box's width), four columns
//  25 apart along its length, 5 to the box's -right and 6 DOWN, which is exactly
//  half that model's height: the blocks' top face flush with the box's underside.
//
//  This mod cannot use their block. p_glo_cinder_block_big is THEIR asset - a
//  1.5x rescale of the stock one, shipped raw in their model_export\ + xmodel\ -
//  and it is in NO retail fastfile: measured 2026-09-09 with Unlinker --list over
//  zm_transit, zm_transit_patch, all three transit gumps, zm_buried, zm_buried_
//  patch, so_zclassic/so_zencounter_zm_buried, the so_z* transit zones, zm_prison,
//  zm_tomb, zm_highrise and common_zm. The STOCK p_glo_cinder_block is owned by
//  zm_transit.ff (zm_transit.list.txt line 3792), so it costs mod.ff nothing.
//
//  MEASURED, Unlinker GLB dump, lod0 accessor bounds, 2026-09-09. Those GLBs are
//  Y-UP, not game axes - checked against com_trafficcone01 in the same dump,
//  which reads y 0..27.6, i.e. a cone standing on its origin:
//      p_glo_cinder_block       16 long x 8 HIGH x 8 deep, centred on its origin
//      p_glo_cinder_block_big   24 x 12 x 12 - the same mesh at 1.5x
//      p6_anim_zm_magic_box     +-47.8 along forward, -12.3..+14.3 along right,
//                               0..19.2 up - so the box's UNDERSIDE is its
//                               origin's z exactly, and everything below is air.
//
//  So a course of stock blocks is 8 high where theirs is 12, and the drop to the
//  floor is not a number this mod may assume: the box origin came from THEIR map,
//  the floor under it is stock geometry. Each column therefore bullettraces its
//  OWN floor and stacks as many 8-high courses as that column needs - the bottom
//  course beds INTO the ground instead of hovering over it, and a sloped or
//  rubble-strewn floor gets a stepped stack instead of a flat one. The trace is
//  the Crazy Place's, which booted 2026-09-08: bullettrace(from, to, 0, undefined)
//  and read ["fraction"] < 1 before ["position"].
//
//  Six columns 16 apart: a block is 8 thick along the box's length, so that is
//  block-gap-block, the same half-covered look Reimagined's four 12-thick blocks
//  give at 25. The yaw jitter is small and deterministic (no randomness - the
//  same stack every boot, so a screenshot can be compared against the next one),
//  and it is BOUNDED: at 17 degrees, the worst case here, a 16-long block turned
//  across a 26.6-wide box reaches -7.8..+9.8 of its -12.3..+14.3, and 12.3 of the
//  16 a column has along the length. Nothing can poke out past the box's edge.
//
//  Decorative only - spawn() with no collision flag, exactly as Reimagined spawns
//  theirs. The box's own clips sit ABOVE the origin and are not touched.
// ============================================================================
zmqol_tunnel_box_bricks( v_box, n_yaw )
{
	v_fwd = anglestoforward( ( 0, n_yaw, 0 ) );
	v_rgt = anglestoright( ( 0, n_yaw, 0 ) );

	//  Along the box's length, and the yaw each column is turned by.
	a_along = array( 40, 24, 8, -8, -24, -40 );
	a_jitter = array( -7, 5, -3, 8, -6, 4 );

	//  `.boxhere` can call this again at a new spot with a different floor under
	//  it, so the stack is rebuilt rather than nudged - the course count changes.
	if ( isdefined( level.zmqol_tunnel_bricks ) )
	{
		for ( i = 0; i < level.zmqol_tunnel_bricks.size; i++ )
		{
			if ( isdefined( level.zmqol_tunnel_bricks[i] ) )
				level.zmqol_tunnel_bricks[i] delete();
		}
	}

	level.zmqol_tunnel_bricks = [];

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
			brick.script_noteworthy = "zmqol_tunnel_box_brick";
			level.zmqol_tunnel_bricks[ level.zmqol_tunnel_bricks.size ] = brick;
		}
	}

	s_blind = "";

	if ( n_blind > 0 )
		s_blind = "  (" + n_blind + " column(s) found NO floor within 160)";

	println( "[zm_qol] tunnel box bricks: " + level.zmqol_tunnel_bricks.size + " cinder blocks under a box at z " + int( v_box[2] ) + " - floor per column:" + s_floors + s_blind );
}

// ============================================================================
//  zmqol_tunnel_box_here  -  `.boxhere`: move the box to where the player is
//  looking, live, and print the numbers to bake.
//
//  Stand where you would USE the box, face the wall, type .boxhere. The box
//  goes 64 units in front of you with its use side facing you (so the wall is
//  behind it), on the floor there, with its collision. The use prompt and the
//  light stay where the box was placed at load - both are fixed at map start
//  (the unitrigger by _zm_magicbox, the light fx by the client) - so this is
//  a placement PROBE, not a working relocation: look, read the numbers off
//  the console, and they get baked into zmqol_tunnel_bring_chest_in().
//
//  Yaw: the use side is the struct's -right, which is yaw + 90. The player
//  faces yaw F towards the wall; the box must face F + 180 back at them, so
//  struct yaw = F + 180 - 90 = F + 90. (The Crazy Place's copy of this then
//  adds 180 for its zbarrier; this map's zbarrier takes the struct yaw.)
// ============================================================================
zmqol_tunnel_box_here( player )
{
	if ( !isdefined( level.chests ) || level.chests.size < 1 || !isdefined( level.chests[0].zbarrier ) )
	{
		player iprintln( "^1[zm_qol] .boxhere ^7- no chest/zbarrier to move" );
		return;
	}

	s_chest = level.chests[0];
	e_zb = s_chest.zbarrier;

	v_ang = player getplayerangles();
	n_face = int( v_ang[1] );

	while ( n_face < 0 )
		n_face += 360;
	while ( n_face >= 360 )
		n_face -= 360;

	v_f = anglestoforward( ( 0, n_face, 0 ) );
	v_at = player.origin + ( v_f[0] * 64, v_f[1] * 64, 0 );

	trace_floor = bullettrace( v_at + ( 0, 0, 40 ), v_at - ( 0, 0, 160 ), 0, undefined );

	if ( trace_floor["fraction"] < 1 )
		v_at = ( v_at[0], v_at[1], trace_floor["position"][2] );

	n_yaw = n_face + 90;

	while ( n_yaw >= 360 )
		n_yaw -= 360;

	zmqol_tunnel_place_box( s_chest, e_zb, v_at, n_yaw );

	player iprintln( "^2[zm_qol] box ^7at x " + int( v_at[0] ) + "  y " + int( v_at[1] ) + "  z " + int( v_at[2] ) + "  ^2yaw ^7" + n_yaw + " ^7(prompt + light stay put until restart)" );
	println( "[zm_qol] BOXHERE zm_transit tunnel: box at (" + v_at[0] + ", " + v_at[1] + ", " + v_at[2] + ") yaw " + n_yaw + " - player stood at (" + int( player.origin[0] ) + "," + int( player.origin[1] ) + "," + int( player.origin[2] ) + ") facing " + n_face );
}

init_barriers()
{
	origin = (-11270, -500, 192);
	angles = (0, 195, 0);
	scripts\zm\locs\loc_common::barrier("collision_wall_512x512x10_standard", origin + (anglesToForward(angles) * 150) + (anglesToRight(angles) * -24) + (anglesToUp(angles) * 256), angles, 1);
	scripts\zm\locs\loc_common::barrier("veh_t6_civ_60s_coupe_dead", origin + (anglesToForward(angles) * 125) + (anglesToRight(angles) * 25), angles);
	scripts\zm\locs\loc_common::barrier("veh_t6_civ_smallwagon_dead", origin + (anglesToForward(angles) * -30) + (anglesToRight(angles) * 50), angles + (0, -90, 0));

	origin = (-10750, -3275, 192);
	angles = (0, 195, 0);
	scripts\zm\locs\loc_common::barrier("collision_wall_512x512x10_standard", origin + (anglesToRight(angles) * 59) + (anglesToUp(angles) * 256), angles, 1);
	scripts\zm\locs\loc_common::barrier("veh_t6_civ_movingtrk_cab_dead", origin + (anglesToUp(angles) * 63), angles);
}

disable_zombie_spawn_locations()
{
	for (z = 0; z < level.zone_keys.size; z++)
	{
		zone = level.zones[level.zone_keys[z]];

		i = 0;

		while (i < zone.spawn_locations.size)
		{
			if (zone.spawn_locations[i].origin == (-11447, -3424, 254.2))
			{
				zone.spawn_locations[i].is_enabled = false;
			}
			else if (zone.spawn_locations[i].origin == (-11093, 393, 192))
			{
				zone.spawn_locations[i].is_enabled = false;
			}
			else if (zone.spawn_locations[i].origin == (-10944, -3846, 221.14))
			{
				zone.spawn_locations[i].is_enabled = false;
			}
			else if (zone.spawn_locations[i].origin == (-10836, 1195, 209.7))
			{
				zone.spawn_locations[i].is_enabled = false;
			}
			else if (zone.spawn_locations[i].origin == (-11251, -4397, 200.02))
			{
				zone.spawn_locations[i].is_enabled = false;
			}
			else if (zone.spawn_locations[i].origin == (-11334, -5280, 212.7))
			{
				zone.spawn_locations[i].is_enabled = false;
			}
			else if (zone.spawn_locations[i].origin == (-11347, -3134, 283.9))
			{
				zone.spawn_locations[i].is_enabled = false;
			}

			i++;
		}
	}
}
