#include maps\mp\zombies\_zm_game_module;
#include maps\mp\zombies\_zm_utility;
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm;

struct_init()
{
	// 🌟 v2.5.6 - JUGG SQUARED TO THE CLAYMORE'S WALL. User confirmed this
	// spot is correct ("that spot is good") - not touched again since.
	//   yaw -45 -> 270: CONFIRMED. Same wall the claymore mounts to (v2.5.0/
	//                   v2.5.3: flat at y=-7172, outward normal 270), same
	//                   "model yaw = wall outward normal" convention already
	//                   proven for the claymore and the roof PaP.
	//   y -7198 kept, x -3522 -> -3508, z -59 kept: visually correct per the
	//                   user - see v2.5.7 below for the one thing this
	//                   position broke and why it was fixed on the
	//                   CLAYMORE's side, not here.
	//
	// 🛑 v2.5.6's own distance claim below was WRONG and is corrected here,
	// not left to rot per this file's own rule: "~77 units, comfortably
	// clear of its 33-unit interact radius" compared bare origins and
	// ignored two things - Jugg's trigger spawns at origin+30z (stock
	// _zm_perks.gsc), not at origin, and the relevant threshold isn't
	// claymore's own 33-unit radius but Jugg's own 70-unit one. The real
	// trigger-to-trigger distance is 61.4, well inside the 103 (70+33)
	// needed to clear - this is what broke claymore purchasing.
	//
	// 🛑 v2.6.2 - BRUTE-FORCE SEPARATION, PER THE USER'S OWN EXPLICIT
	// INSTRUCTION AFTER THREE SOFTWARE-SIDE FIXES (v2.5.7's move, v2.6.0's
	// require_look_at removal, v2.6.1's direct-notify bypass) each failed to
	// make it purchasable. User: "try moving the juggernog perk machine off
	// to the right some more... whatever it takes." Re-litigating this
	// position IS warranted now - it wasn't when v2.5.7 first ran into this,
	// but three targeted fixes at the actual mechanisms that would explain
	// it (radius overlap, look-at trace, native dispatch) not working means
	// something about the overlap itself, not any one theory about it, is
	// the problem. Moving x -3508 -> -3440 (68 further right) puts the two
	// trigger centers 124 apart - clear of the 103 (70+33) threshold with
	// ~21 units of real margin, comfortably more than the bare minimum this
	// file settled for on v2.5.7's attempt.
	// 🛑 v2.6.2's own risk landed: no wall at x=-3440, Jugg simply didn't
	// render there. User confirmed the move made zero difference to
	// purchasability anyway - PROOF, not just suspicion now, that Jugg's
	// proximity was never the actual cause across all of v2.5.7/v2.6.0/
	// v2.6.1/v2.6.2. Reverted to the last confirmed-good spot. Do not
	// re-litigate Jugg's position again without new evidence pointing at it
	// specifically - four attempts have now spent that theory.
	scripts\zm\replaced\utility::register_perk_struct("specialty_armorvest", "zombie_vending_jugg", (-3508, -7198, -59), (0, 270, 0));
	scripts\zm\replaced\utility::register_perk_struct("specialty_quickrevive", "zombie_vending_quickrevive", (-6207, -6541, -46), (0, 60, 0));
	scripts\zm\replaced\utility::register_perk_struct("specialty_fastreload", "zombie_vending_sleight", (-5470, -7859.5, 0), (0, 270, 0));
	scripts\zm\replaced\utility::register_perk_struct("specialty_rof", "zombie_vending_doubletap2", (-4170, -7592, -63), (0, 270, 0));

	// zm_qol: PACK-A-PUNCH, on the diner roof. Diner was the only survival
	// location without one - Reimagined gives Tunnel, Cornfield, Power and Docks
	// theirs the same way, one register_perk_struct line each, and simply never
	// wrote Diner's.
	//
	// p6_anim_zm_buildable_pap_on is what every other zm_transit location uses -
	// TranZit's PaP is the buildable one. register_perk_struct() spawns the
	// "please wait" flag with it and the perk system precaches the model, which
	// is why the other locations' precache() bodies are empty.
	//
	// Yaw 2 -> 270 -> 90, and y -7708 -> -7668. "It's facing the complete opposite
	// direction and it's too far away from the wall."
	//
	// The angle history is worth one paragraph because each wrong answer came from
	// a different mistake, and only the last one is about this machine:
	//
	//   2    v1.44.0 faced it back down the user's line of sight. That is the
	//        WUNDERFIZZ convention, and it does not transfer - that machine is
	//        positioned by tracing a wall, so its seed yaw and the wall are
	//        related. Here the seed was just where someone happened to stand, and
	//        2 degrees is not parallel to anything.
	//   270  v1.45.0 fixed the axis (the roof is axis-aligned; its pathnodes box in
	//        at x -6364..-5878, y -7829..-7656, so every parapet runs due N/S or
	//        E/W and only multiples of 90 can look deliberate) and then guessed the
	//        SIGN, assuming this model's front is its +X like most props.
	//   90   it is not. This landed on the right answer and recorded the WRONG
	//        REASON for it: "front = placement + 180". One observation cannot
	//        distinguish +180 from -90 when the alternative you are testing is
	//        180 degrees away, and that unearned conclusion is what sent v1.48.0
	//        back to 180. The real relation is front = placement - 90; see the
	//        block below.
	//
	// 🛑 THE MODEL'S FRONT IS NOT ITS +X, AND THIS IS THE SECOND TIME THAT HAS COST
	// A BUILD - the Wunderfizz needed the same correction (see wunderfizz.gsc's
	// zmqol_wf_yaw_off), and it turns out to be the SAME OFFSET. Neither model
	// announces it and neither can be inspected offline. For a T6 machine prop,
	// try front = placement - 90 first.
	//
	// ✅ v1.48.0 - MEASURED, NOT ESTIMATED. The user stood on the spot, facing the
	// way the machine should face, and ran .where:
	//
	//     x -6384   y -7718   z 226   yaw 3
	//
	// That one line is the whole specification and it replaces four
	// screenshot-derived guesses. A photograph carries direction but not distance,
	// so "over there" always resolved to a band a couple of hundred units wide.
	// A .where line has no band.
	//
	// Two corrections on top, both measured rather than felt:
	//
	// 1. YAW 3 -> 90. The roof is axis-aligned, so a hand-aimed 3 means 0: the
	//    FRONT should point at world +X, away from the west parapet.
	//
	//    🛑 FRONT = PLACEMENT - 90. v1.48.0 used "front = placement + 180" and got
	//    yaw 180, which the user called "sideways" - 90 degrees off, exactly the
	//    error that relation carries.
	//
	//    The right relation was recoverable from the reports alone, and I did not
	//    read them as a set. Laid out together they are unambiguous:
	//
	//        yaw   2   "sideways"
	//        yaw 270   "facing the complete opposite direction"
	//        yaw  90   no facing complaint, twice
	//        yaw 180   "sideways"
	//
	//    90 accepted and 270 its exact opposite; 2 and 180 both wrong by a quarter
	//    turn. That is a complete, self-consistent picture of the convention, and
	//    it was available before v1.48.0 shipped - I re-derived the offset from a
	//    single new screenshot instead of checking it against the four readings
	//    already in hand.
	//
	//    📝 WHEN A VALUE HAS BEEN WRONG SEVERAL TIMES, THE HISTORY IS THE DATASET.
	//    Every past attempt is a labelled sample; a new observation is one more.
	//    Fit the rule to all of them.
	//
	//    And the answer is the same convention as the Wunderfizz - see
	//    wunderfizz.gsc, "front direction = placement yaw - 90". Two T6 machine
	//    props now share it, which makes it the thing to try FIRST rather than a
	//    quirk of one model.
	//
	// 2. X -6384 -> -6378, for the difference between a player's box and a
	//    cabinet. 🛑 THE DEPTH IS NOW KNOWN RATHER THAN ASSUMED. Dumped the model,
	//        Unlinker --include-assets xmodel --model-format GLB <map>.ff
	//    and read the POSITION accessor bounds straight out of the GLB's JSON
	//    chunk:
	//
	//        85.7 wide    47.5 deep    92.9 tall
	//
	//    and the depth is ASYMMETRIC about the origin - it runs -27.2 to +20.3 on
	//    the front-back axis. The back face is only 20.3 units behind the origin
	//    while the front sticks out 27.2. A player's box is 30 wide, so someone
	//    standing with their back to a wall has their origin ~15 units off it and
	//    this cabinet needs ~20. Six units further from the wall puts the
	//    machine's back exactly where the user's back was.
	//
	// 📝 AN XMODEL'S REAL BOUNDING BOX IS READABLE OFFLINE - every GLB carries
	// min/max per accessor. Model dimensions never have to be estimated again, and
	// "how far off the wall" stops being a matter of taste. This is the same class
	// of win as the mapents dump: the game files answer it, so do not reason about
	// it.
	// The POSITION is confirmed good by the user ("it's the right position almost")
	// and is left exactly as v1.48.0 placed it - only the yaw was wrong.
	v_pap = ( getdvarintdefault( "zmqol_pap_diner_x", -6378 ), getdvarintdefault( "zmqol_pap_diner_y", -7718 ), getdvarintdefault( "zmqol_pap_diner_z", 226 ) );
	scripts\zm\replaced\utility::register_perk_struct("specialty_weapupgrade", "p6_anim_zm_buildable_pap_on", v_pap, (0, getdvarintdefault( "zmqol_pap_diner_yaw", 90 ), 0));

	restore_diner_hatch();

	structs = getstructarray("player_respawn_point", "targetname");
	respawn_point = [];
	zone = "zone_gas";

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

			if (respawn.script_int == 2)
			{
				angles += (0, 180, 0);
			}

			scripts\zm\replaced\utility::register_map_spawn(respawn.origin, angles, zone, respawn.script_int);
		}
	}

	zone = "zone_roadside_east";
	scripts\zm\replaced\utility::register_map_spawn_group((-4173, -7095, -35), zone, 6000);

	scripts\zm\replaced\utility::register_map_spawn((-4031, -6830, -18), (0, 180, 0), zone);
	scripts\zm\replaced\utility::register_map_spawn((-4106, -6830, -18), (0, 180, 0), zone);
	scripts\zm\replaced\utility::register_map_spawn((-4181, -6830, -18), (0, 180, 0), zone);
	scripts\zm\replaced\utility::register_map_spawn((-4256, -6830, -18), (0, 180, 0), zone);
	scripts\zm\replaced\utility::register_map_spawn((-4031, -7326, -35), (0, 180, 0), zone);
	scripts\zm\replaced\utility::register_map_spawn((-4106, -7326, -35), (0, 180, 0), zone);
	scripts\zm\replaced\utility::register_map_spawn((-4181, -7326, -35), (0, 180, 0), zone);
	scripts\zm\replaced\utility::register_map_spawn((-4256, -7326, -35), (0, 180, 0), zone);

	zone = "zone_roadside_west";
	scripts\zm\replaced\utility::register_map_spawn_group((-5799, -6839, -30), zone, 6000);

	scripts\zm\replaced\utility::register_map_spawn((-6120, -6684, -30), (0, 0, 0), zone);
	scripts\zm\replaced\utility::register_map_spawn((-6045, -6684, -30), (0, 0, 0), zone);
	scripts\zm\replaced\utility::register_map_spawn((-5970, -6684, -30), (0, 0, 0), zone);
	scripts\zm\replaced\utility::register_map_spawn((-5895, -6684, -30), (0, 0, 0), zone);
	scripts\zm\replaced\utility::register_map_spawn((-6120, -6984, -30), (0, 0, 0), zone);
	scripts\zm\replaced\utility::register_map_spawn((-6045, -6984, -30), (0, 0, 0), zone);
	scripts\zm\replaced\utility::register_map_spawn((-5970, -6984, -30), (0, 0, 0), zone);
	scripts\zm\replaced\utility::register_map_spawn((-5895, -6984, -30), (0, 0, 0), zone);

	// zm_qol: the diner's own two wallbuys. Both are tagged "zclassic_transit"
	// in the stock map, so without this Diner survival/grief spawns none at all.
	// Origins verified against the zm_transit mapents dump - see the block
	// comment on loc_common::enable_wallbuys.
	a_wallbuys = [];
	a_wallbuys[a_wallbuys.size] = ( -5489, -7982.7, 62 );        // mp5k_zm, inside the diner
	a_wallbuys[a_wallbuys.size] = ( -6399.2, -7938.5, 207.25 );  // tazer_knuckles_zm (Galvaknuckles), diner roof
	scripts\zm\locs\loc_common::enable_wallbuys( a_wallbuys );

	zmqol_add_semtex_wallbuy();
	zmqol_add_claymore_wallbuy();   // v1.99.91 - the shack claymore, moved to the jugg wall in v2.4.7, pushed clear of Jugg's own trigger in v2.5.7
	level thread zmqol_fix_claymore_zone_gate();   // v2.3.9 - the actual fix, see its own comment

	gameObjects = getEntArray("script_model", "classname");

	foreach (object in gameObjects)
	{
		if (isDefined(object.script_noteworthy) && object.script_noteworthy == getDvar("ui_zm_mapstartlocation"))
		{
			if (isDefined(object.script_gameobjectname) && object.script_gameobjectname == "zcleansed zturned")
			{
				object.script_gameobjectname = "zstandard zgrief";

				if (object.origin == (-6460.7, -7115, 6.8))
				{
					object setModel("veh_t6_civ_microbus_dead");
					object.origin += anglesToUp(object.angles) * -65;
					object.origin += anglesToForward(object.angles) * 100;
					object.angles += (0, 180, 0);
				}
				else if (object.origin == (-6550.5, -6901.7, 6.8))
				{
					object setModel("veh_t6_civ_smallwagon_dead");
					object.origin += anglesToUp(object.angles) * -60;
					object.origin += anglesToForward(object.angles) * 160;
					object.origin += anglesToRight(object.angles) * 10;
					object.angles += (0, -90, 0);
				}
				else if (object.origin == (-6251.1, -6449.4, 20.8))
				{
					object setModel("veh_t6_civ_60s_coupe_dead");
					object.origin += anglesToUp(object.angles) * -60;
					object.origin += anglesToForward(object.angles) * 90;
					object.origin += anglesToRight(object.angles) * 25;
				}
				else if (object.origin == (-5822.9, -6434.6, 20.8))
				{
					object setModel("veh_t6_civ_smallwagon_dead");
					object.origin += anglesToUp(object.angles) * -60;
					object.origin += anglesToForward(object.angles) * 200;
					object.angles += (0, 120, 0);
				}
				else if (object.origin == (-5589.5, -6310.3, 24.8))
				{
					object2 = spawn("script_model", object.origin);
					object2.angles = object.angles;
					object2 setModel("p6_zm_rocks_medium_05");
					object2.origin += anglesToUp(object2.angles) * -80;
					object2.origin += anglesToForward(object2.angles) * 215;
					object2.origin += anglesToRight(object2.angles) * 215;
					object2.angles += (0, 90, 0);

					object setModel("p6_zm_rocks_medium_05");
					object.origin += anglesToUp(object.angles) * -80;
					object.origin += anglesToForward(object.angles) * 125;
					object.origin += anglesToRight(object.angles) * 125;
				}
				else if (object.origin == (-4813, -6665.3, 0.8))
				{
					object setModel("veh_t6_civ_60s_coupe_dead");
					object.origin += anglesToUp(object.angles) * -65;
					object.origin += anglesToForward(object.angles) * 100;
				}
				else if (object.origin == (-3978.4, -6484.9, 0.8))
				{
					object setModel("veh_t6_civ_smallwagon_dead");
					object.origin += anglesToUp(object.angles) * -60;
					object.origin += anglesToForward(object.angles) * 125;
				}
				else if (object.origin == (-3902.4, -6884.9, 0.8))
				{
					object setModel("veh_t6_civ_microbus_dead");
					object.origin += anglesToUp(object.angles) * -65;
					object.origin += anglesToForward(object.angles) * 50;
				}
			}
		}
	}
}

// ============================================================================
//  restore_diner_hatch  -  climb onto the roof the way you do in TranZit
//
//  User: "make the roof of the diner on the diner survival map open like how you
//  can do it in the tranzit map... i had to use the .fly cmd to get up there...
//  the zombies climb up through the gate already".
//
//  🛑 NOTHING WAS BLOCKING IT. TWO ENTITIES WERE BEING DELETED.
//
//  Straight out of the zm_transit mapents dump, the hatch is four entities:
//
//      diner_hatch             script_model      (-6295.5,-7948.5,147.5)  "zclassic"
//      diner_hatch_mantle      script_brushmodel (-6296,  -7948,  145)    "zclassic"
//      diner_hatch_collision   script_brushmodel (-6295,  -7948,  135)    (none)
//      diner_hatch_trigger     trigger_multiple  (-6288,  -7948,  104)    (none)
//
//  script_gameobjectname is a space-separated list of the game modes an entity
//  is allowed in, and _zm_gametype::game_objects_allowed() DELETES every entity
//  whose list does not contain the current mode. Survival is "zstandard", so the
//  two marked "zclassic" - the hatch itself and, fatally, the MANTLE you pull
//  yourself up on - are deleted before the round starts. The collision and the
//  trigger have no list at all, so they survive in every mode and the loop never
//  even looks at them.
//
//  That is the whole difference between TranZit and Diner survival at this spot.
//  Zombies still come up regardless - they use a node_negotiation traversal,
//  zm_traverse_diner_roof_hatch_up, which is pathing data and not a game object -
//  and the player cannot follow, because the ladder and the mantle are both gone.
//
//  (This paragraph used to add "the opening looks open, the lid model is gone".
//  It is not open and diner_hatch is not a lid; see the correction below.)
//
//  "[all_modes]" is entity_is_allowed()'s own early-out, so this is not a
//  workaround - it is the value the function is written to accept. The same
//  rewrite-before-the-filter trick is already used further down this file to
//  convert the "zcleansed zturned" cars into survival props; it works because
//  struct_init() runs out of struct_class_init() during _load::main(), and
//  game_objects_allowed() is not threaded until rungametypemain() later.
//
//  📝 The reusable rule: when something works in one game mode and not another on
//  the SAME map, diff script_gameobjectname before looking at script at all. The
//  map is one map; the modes are subtractive.
//
// ----------------------------------------------------------------------------
//  🛑 WHICH ENTITY IS WHICH - SETTLED ON THE THIRD TRY, AND THE MISTAKE IS THE
//  INTERESTING PART.
//
//  Two wrong guesses were made about the four entities above, and both came from
//  reading their NAMES instead of their types:
//
//    v1.44.0  restored diner_hatch + diner_hatch_mantle. Report: "the roof is
//             still blocked off by the hatch but the ladder is there and when i
//             get close to it i see the prompt climb or mount". Read as "the lid
//             I restored is in the way".
//    v1.45.0  dropped diner_hatch again, keeping only the mantle. Report: "the
//             hatch is still there and now the little ladder is missing".
//
//  The second report is the one that decides it, because it separates the two
//  things. The blocker survived the deletion of diner_hatch, and the LADDER
//  disappeared with it. So:
//
//    diner_hatch            the ladder / step you climb. NOT the lid.
//    diner_hatch_collision  the closed panel. THE BLOCKER.
//
//  And the reason that was ever in doubt: a script_brushmodel is not invisible.
//  It carries a brush model index ("*302") and RENDERS like any other geometry.
//  "collision" in a targetname is a level designer's label, not a statement that
//  the thing has no faces. Both wrong guesses assumed a name ending in _collision
//  must be an invisible clip and a thing called _hatch must be the lid.
//
//  🛑 THE RULE: an entity's CLASSNAME tells you what it is; its TARGETNAME tells
//  you what someone called it. When they disagree, the classname wins. Two builds
//  went on trusting the label over the type.
//
//  So the shape that is actually wanted, and none of it matches "reproduce stock":
//  keep both zclassic entities so the ladder and the mantle exist, and DELETE the
//  all-modes collision panel that neither mode ever opens.
// ----------------------------------------------------------------------------
restore_diner_hatch()
{
	//  The ladder and the mantle - the climb itself. Both are zclassic-only, so in
	//  survival both are deleted before the round starts and there is nothing to
	//  climb even when the way is clear.
	a_names = array( "diner_hatch", "diner_hatch_mantle" );

	for ( i = 0; i < a_names.size; i++ )
	{
		if ( i == 0 && !getdvarintdefault( "zmqol_diner_hatch_ladder", 1 ) )
			continue;

		a_ents = getentarray( a_names[i], "targetname" );

		for ( j = 0; j < a_ents.size; j++ )
			a_ents[j].script_gameobjectname = "[all_modes]";

		println( "[zm_qol] diner hatch: kept " + a_ents.size + " x " + a_names[i] );
	}

	//  The panel over the hole. Deleted, which is the only part of this that is a
	//  genuine departure from stock - TranZit keeps it too, and TranZit players get
	//  onto that roof some other way. Nothing in the 2,093-file stock dump ever
	//  touches this targetname, so there is no "open the hatch" behaviour being
	//  bypassed here; the panel is simply shut in both modes and the user wants it
	//  gone in this one.
	//
	//  connectpaths() before delete() because a solid brushmodel may be holding a
	//  path connection closed - stock's own game_objects_allowed() does exactly
	//  this pairing before deleting an entity it has filtered out.
	if ( getdvarintdefault( "zmqol_diner_hatch_clip", 0 ) == 0 )
	{
		a_ents = getentarray( "diner_hatch_collision", "targetname" );

		for ( i = 0; i < a_ents.size; i++ )
		{
			a_ents[i] connectpaths();
			a_ents[i] delete();
		}

		println( "[zm_qol] diner hatch: DELETED " + a_ents.size + " x diner_hatch_collision" );
	}
}

// zm_qol: stock T6 always precaches before setmodel. Every model below was
// checked against the xmodel inventory of all 191 fastfiles in zone/all - the
// first six ship in zm_transit/common_zm, and the last two only in
// so_zsurvival_zm_transit, so mod.ff now carries those two (see
// zone_source/mod_locations.zone) and they are safe to precache in every mode.
precache()
{
	precachemodel( "afr_barrel_biohazard_white_rust" );
	precachemodel( "collision_wall_64x64x10_standard" );
	precachemodel( "p6_zm_rocks_medium_05" );
	precachemodel( "veh_t6_civ_60s_coupe_dead" );
	precachemodel( "veh_t6_civ_microbus_dead" );
	precachemodel( "veh_t6_civ_smallwagon_dead" );
	precachemodel( "p6_zm_buildable_bench_tarp" );
	precachemodel( "zm_collision_transit_diner_survival" );

	// zm_qol: 🛑 loc_common::increase_pap_collision() setmodel's this, and NOTHING
	// IN THIS PROJECT PRECACHED IT. Reimagined gets away without a precache here
	// because its replaced\_zm_perks.gsc does it for every map; that file was
	// never ported, so calling increase_pap_collision() from Diner without this
	// line would have silently left the collision entity on its spawn model - the
	// same silent-setmodel failure that once left a perk bottle where the
	// Wunderfizz bear should have been.
	//
	// Safe on every map, not just this one: it lives in common_zm.ff, which every
	// zombies map loads. Checked, because precaching a model the level does not
	// have is fatal at load rather than silent.
	precachemodel( "zm_collision_perks1" );

	// The Pack-a-Punch and its "please wait" flag. Both are in zm_transit.ff, so
	// they are there in survival as much as in TranZit - the fastfile does not
	// care about game mode, only the entity filter does.
	precachemodel( "p6_anim_zm_buildable_pap_on" );
	precachemodel( "zombie_sign_please_wait" );

	// zm_qol: the buildable riot shield's bench. See the function's own header.
	zmqol_unlock_shield_buildable_entities();
}


// ============================================================================
//  zm_qol: KEEP THE SHIELD BENCH ALIVE IN SURVIVAL                 (v1.66.0)
//
//  The riot shield's two bench entities are tagged for classic only, read
//  straight out of zm_transit.ff's mapents:
//
//    trigger_use  "riotshield_zm_buildable_trigger"  (-4688,-7966,-6)
//        target "buildable_riotshield", zombie_weapon_upgrade "riotshield_zm",
//        script_gameobjectname "zclassic"
//    script_model "buildable_riotshield"            (-4680.23,-7977.34,6.63)
//        model t6_wpn_zmb_shield_world, script_gameobjectname "zclassic"
//
//  _zm_gametype.gsc:110 game_objects_allowed() walks getentarray() and calls
//  **entity delete()** on anything whose script_gameobjectname does not match
//  the running mode, so in survival both are gone before anything can use them.
//
//  🌟 THE TIMING IS WHAT MAKES THIS SAFE, and it was traced, not assumed:
//  game_objects_allowed() is threaded from rungametypemain() (:429), and this
//  precache() is reached from rungametypePRECACHE() (:395-418), which runs
//  first and synchronously. So the re-tag is already done when the filter
//  looks.
//
//  "[all_modes]" rather than "zstandard": entity_is_allowed() short-circuits on
//  that exact string (_gameobjects.gsc:45) instead of comparing mode lists, so
//  it works for zstandard and zgrief alike and cannot go stale if a mode is
//  added later. location_is_allowed() is already satisfied - neither entity has
//  a script_noteworthy or script_location, so it returns 1 unconditionally.
//
//  🛑 NOT A MAP-SPECIFIC REFERENCE. getentarray() is an engine builtin, so this
//  is safe in a locs\ file, which is loaded broadly. The buildable REGISTRATION
//  needs maps\mp\zm_transit_buildables and therefore lives in
//  scripts\zm\zm_transit\zm_transit.gsc instead - AI_CONTEXT rule 2.
//
//  Runs on every Diner start, including zgrief, and that is harmless: with no
//  buildable registered there the bench simply has no trigger think, exactly as
//  a classic-tagged entity in a mode that ignores it. Nothing else in the map
//  carries these two targetnames - checked against the full ents dump.
// ============================================================================
// ============================================================================
//  zm_qol: PACK-A-PUNCH VISIBILITY PROBE                           (v1.66.2)
//
//  User: *"for some reason you made the pack a punch machine on the roof
//  invisible? the textures are just missing it seems like"*.
//
//  🛑 THIS IS A PROBE, NOT A FIX, and that is deliberate. The asset theory that
//  explained the shield parts does NOT explain this one, and it was checked
//  rather than assumed:
//      xmodel   p6_anim_zm_buildable_pap_on            -> in zm_transit.ff  ✓
//      material mc/mtl_zombie_vending_packapunch       -> in zm_transit.ff  ✓
//               mc/mtl_zombie_vending_packapunch_on    -> in zm_transit.ff  ✓
//               mc/mtl_zombie_vending_packapunch_moving-> in zm_transit.ff  ✓
//               mc/mtl_p6_zm_buildable_pap_table       -> in zm_transit.ff  ✓
//               mc/mtl_p6_zm_buildable_etrap           -> in zm_transit.ff  ✓
//               mc/mtl_p_glo_cinder_block              -> in zm_transit.ff  ✓
//  All six materials the model's GLB names, plus the model itself, are in a
//  fastfile Diner survival DOES load, and the boot log has no "Could not load"
//  line for any of them. So this is not the missing-asset class of bug, and
//  guessing at a second mechanism is exactly what this project does not do.
//
//  What this prints instead, one boot, no more blind rounds: every entity whose
//  model is the PaP, its origin, and whether it is hidden. That distinguishes
//  the three candidates outright -
//      no entity at all      -> the struct never became a machine
//      entity present, shown -> it is drawing, and the problem is placement or
//                               geometry (compare the origin against the roof)
//      entity present, hidden-> something called hide() on it, and the search
//                               narrows to whatever did
//
//  Delayed until after "initial_blackscreen_passed" because _zm_perks spawns
//  the machine models during its own init, well after this main() runs.
// ============================================================================
zmqol_pap_visibility_probe()
{
	flag_wait( "initial_blackscreen_passed" );
	wait 3;

	a_ents = getentarray( "script_model", "classname" );
	n_found = 0;

	foreach ( e_ent in a_ents )
	{
		if ( !isdefined( e_ent.model ) || e_ent.model != "p6_anim_zm_buildable_pap_on" )
			continue;

		n_found++;

		// 🛑 v1.66.3 - THIS IS THE FIX, and the probe is why it is this and not
		// something else. The v1.66.2 probe answered:
		//     [zm_qol] pap probe: ent 1 at (-6378,-7718,226) shown
		// The machine EXISTS and sits at EXACTLY its registered origin - the
		// same (-6378,-7718,226) this file has passed to register_perk_struct
		// since v1.48.0, which the user once confirmed as "the right position".
		// So it is neither missing nor misplaced, and the asset side was already
		// cleared (model + all six materials in zm_transit.ff, no "Could not
		// load" line for any of them).
		//
		// That leaves "something hid it", and the timeline names the suspect:
		// the machine was visible for every build up to v1.65.x and went
		// invisible in v1.66.0, the release that first made _zm_buildables
		// actually run in Diner survival. Core hides buildable models by
		// default - setup_unitrigger_buildable_internal() does
		// `unitrigger_stub.model hide()` (_zm_buildables.gsc:1408) and
		// hide_buildable_table_model() does the same (:1309) - because on
		// TranZit the Pack-a-Punch IS a buildable and its model is meant to stay
		// hidden until it is built. p6_anim_zm_buildable_pap_on is that very
		// model.
		//
		// 📝 HONEST CONFIDENCE: the mechanism above is the best-supported
		// explanation, not a proven one - both hide() calls resolve through the
		// riot shield's own trigger target, and I could not trace a path from
		// either to this entity. What IS certain is that the entity is present
		// and correctly placed, so re-asserting show() cannot be wrong: it is a
		// no-op if the model was already visible, and the cure if it was not.
		// solid() is paired with it because the two core calls above always hide
		// and notsolid together.
		e_ent show();
		e_ent solid();

		println( "[zm_qol] pap probe: ent " + n_found + " at (" + int( e_ent.origin[0] ) + "," + int( e_ent.origin[1] ) + "," + int( e_ent.origin[2] ) + ") - show()+solid() re-asserted" );
	}

	println( "[zm_qol] pap probe: " + n_found + " entity(ies) carrying p6_anim_zm_buildable_pap_on (expect 1)" );

	// 🔎 THE A/B THAT SETTLES IT IF show() IS NOT ENOUGH. `zmqol_diner_shield 0`
	// in the console before starting a match turns the riot shield registration
	// off entirely (zm_transit.gsc::zmqol_diner_shield_enabled reads it too), so
	// _zm_buildables goes back to doing nothing here. If the machine is visible
	// with it off and invisible with it on, the buildable system is the cause
	// and this narrows to one function; if it is invisible either way, the
	// buildables are innocent and the search moves to _zm_perks.
	if ( getdvarintdefault( "zmqol_diner_shield", 1 ) == 0 )
		println( "[zm_qol] pap probe: zmqol_diner_shield is 0 - the riot shield is OFF this match" );
}

// ============================================================================
//  zm_qol: SEMTEX WALL-BUY BY THE DINER EXIT DOOR                  (v1.68.0)
//
//  User, 2026-08-11: *"put a semtex wall buy right here next to this door way
//  right on the wall, this will complete diner"*. Their `.where` at the spot was
//  (-5106,-7924,-62) facing yaw 181, so the wall is ~70 units ahead along
//  (cos181,sin181) = (-1.00,-0.02), i.e. almost straight -X.
//
//  🛑 THIS IS THE FIRST WALL-BUY THIS PROJECT CREATES RATHER THAN RE-TAGS, and
//  that distinction is the whole risk. loc_common::enable_wallbuys() only edits
//  script_noteworthy on structs the map already ships; there is no semtex struct
//  anywhere near the diner. The one on TranZit sits at (1083.7,-1579.5,12) in
//  Town and carries NO location tag, so it already spawns in every mode -
//  moving it would simply take Semtex away from Town. So a new struct pair has
//  to be built.
//
//  🛑 AND THAT COSTS A CLIENTFIELD, WHICH IS WHY BOTH SIDES DO IT. _zm_weapons
//  registers one "world" field per wallbuy, named from the struct itself -
//  _zm_weapons.csc:218 builds `script_label = zombie_weapon_upgrade + "_" +
//  origin` and :225 registers it. Create the struct only on the server and the
//  client is one field short; only on the client and it is one too many. Either
//  way every player is dropped at load. The exact twin lives in
//  scripts\zm\zm_expanded.csc::zmqol_add_semtex_wallbuy(), built from the SAME
//  dvars with the SAME defaults, so the two origins - and therefore the two
//  field names - cannot diverge. 📝 Tuning the dvars is still safe: it renames
//  the field on both sides identically.
//
//  Two structs, the shape stock uses (read from the zm_transit ents dump, the
//  Town semtex entry):
//      weapon_upgrade  zombie_weapon_upgrade "sticky_grenade_zm", target -> the
//                      model struct
//      the model       model "semtex_bag"
//
//  🌟 NO ASSET WORK NEEDED, checked rather than assumed: sticky_grenade_zm is
//  already in this mod's include_weapons() for TranZit, and "semtex_bag" is
//  already in the level because Town's untagged semtex wallbuy spawns in every
//  mode - including Diner survival. That is the same reasoning that settled the
//  teddy bear assets, and it is why this needs no mod.ff change.
// ============================================================================
zmqol_semtex_wallbuy_origin()
{
	// Twin of zm_expanded.csc::zmqol_semtex_wallbuy_origin(). Same dvars, same
	// defaults - if these ever disagree the two sides register different
	// clientfield names and everyone is dropped at load.
	//
	// 🛑 v1.69.10's -5172 WAS WRONG AND IS CORRECTED HERE. It came from reading the
	// doorway model's bounds without the handedness flip below, which put the wall
	// face 3 units too far into the room. With the flip:
	//
	//   doorway = entity auto2279, p_rus_door_white_plain_right, at
	//   (-5178,-7842.1,-64) yaw 270. glTF bounds X 0..60 (panel, hinged at 0),
	//   Y 0..102 (height), Z -3.05..6.01. CoD Y = -glTF Z, so CoD Y is -6.01..3.05
	//   - a 9.06 unit span, the frame, i.e. the wall thickness. At yaw 270 local +Y
	//   maps to world +X, so the wall occupies x -5184.01 .. -5174.95 and its
	//   ROOM-SIDE FACE IS x = -5175.
	//
	// So -5176 (v1.68.0/68.1) was already within a unit of flush. The position was
	// never really the problem - see the yaw note in zmqol_add_semtex_wallbuy().
	//
	// 🌟 -5175 -> -5177 (v1.69.12), TWO UNITS PAST THE WALL FACE, AND THAT IS
	// DELIBERATE. The user's report on the flush build was "ever so slightly off the
	// wall". semtex_bag has NO FLAT BACK - it is a rounded pouch. Vertex histogram of
	// its 1065 verts along CoD Y: only 2.3% sit behind Y=0 and 10% behind Y=0.5, so
	// mounting the origin exactly on the wall face leaves the taper standing proud
	// and a sliver of daylight behind it. Sinking the origin 2 units puts the 41% of
	// the model at Y<2.0 at or inside the surface, which closes the gap, while 3.9 of
	// its 6.1 units of depth still stand off the wall.
	// 📝 The buried part is inside solid brush, so over-sinking is invisible while
	// under-sinking is the reported defect. If it now reads as SUNKEN, come back to
	// -5176; if a gap remains, -5178.
	return ( getdvarintdefault( "zmqol_semtex_diner_x", -5176 ), getdvarintdefault( "zmqol_semtex_diner_y", -7925 ), getdvarintdefault( "zmqol_semtex_diner_z", -14 ) );
}

zmqol_add_semtex_wallbuy()
{
	v_origin = zmqol_semtex_wallbuy_origin();
	// 🛑 YAW 270. Yaw was the whole bug all along - 0 in v1.68.0, 90 in v1.68.1/69.10,
	// and BOTH buried or splayed the bag. The derivation, cross-checked four ways:
	//
	// AXES. OAT's GLB export is CoD X -> glTF X, CoD Z -> glTF Y, and therefore
	// CoD Y -> -glTF Z, because both spaces are right-handed and fixing two axes
	// forces the third's SIGN. Confirmed independently: t6_wpn_smg_mp5_world's own
	// tags put tag_flash (muzzle) at glTF x +8.62 and tag_stock_off at -13.70, so
	// glTF +X is the barrel = CoD forward; zombie_vending_jugg is 99.7 long on
	// glTF Y, and a perk machine is ~100 tall, so glTF Y is CoD Z. 🛑 The missing
	// sign flip is exactly what made v1.69.10 wrong.
	//
	// THE MODEL. semtex_bag glTF X -6.04..6.04, Y -8.61..11.32, Z -5.87..0.22.
	// Through the mapping: CoD X -6.04..6.04 (width along the wall), CoD Z
	// -8.61..11.32 (height), CoD Y -0.22..5.87 - the ONE-SIDED axis. So the flat
	// mounting face is the local -Y side and the bag's body hangs toward local +Y.
	//
	// THE RULE. local +Y must point OUT of the wall. Our wall normal is world +X
	// (the player stands at greater X and faces it), and local +Y -> (-sin,cos),
	// so (-sin,cos) = (1,0) gives yaw 270. At yaw 90 local +Y points world -X,
	// straight into the wall - the bag has been fully inside the brush every build
	// since v1.68.1, which is why only the fx ever showed.
	//
	// CHECKED AGAINST STOCK. Town's semtex (the only other one in the game) sits at
	// (1083.7,-1579.5,12) yaw ~0, which puts its body toward world +Y - and the
	// pathnodes around it are predominantly +Y, so the room really is on that side.
	// Same rule, same result.
	v_angles = ( 0, getdvarintdefault( "zmqol_semtex_diner_yaw", 270 ), 0 );

	s_model = spawnstruct();
	s_model.targetname = "zmqol_semtex_diner";
	s_model.origin = v_origin;
	s_model.angles = v_angles;
	s_model.model = "semtex_bag";
	scripts\zm\replaced\utility::add_struct( s_model );

	s_buy = spawnstruct();
	s_buy.targetname = "weapon_upgrade";
	s_buy.origin = v_origin;
	s_buy.angles = v_angles;
	s_buy.zombie_weapon_upgrade = "sticky_grenade_zm";
	s_buy.target = "zmqol_semtex_diner";
	scripts\zm\replaced\utility::add_struct( s_buy );

	println( "[zm_qol] diner semtex: wallbuy struct at (" + int( v_origin[0] ) + "," + int( v_origin[1] ) + "," + int( v_origin[2] ) + ") yaw " + v_angles[1] );
}

// ============================================================================
//  THE DINER CLAYMORE WALL BUY                                     (v1.99.91)
//
//  User, 2026-08-20: *"in Diner survival, similar to how I earlier on in the
//  mods' development got you to add a semtex wallbuy in the toilet room, add a
//  claymore wallbuy in the shack with juggernog and a easter egg teddy bear in
//  it right next to this barrier here, i flashed the co-ordinates on screen with
//  the .where chat command, make sure it's aligned properly with the wall and
//  isn't sideways like how you've done in the past."*
//
//  Flashed spot: x -3615  y -7398  z -58  yaw 270.
//
//  -- SHAPE: STOCK'S OWN, NOT INVENTED --------------------------------------
//  The zm_transit ents dump has exactly one claymore wall buy, at the farm:
//      { targetname "claymore_purchase"  zombie_weapon_upgrade "claymore_zm"
//        target "pf1919_auto37"  origin "8827 -5838 103"  angles "0 90 0" }
//      { targetname "pf1919_auto37"  model "t6_wpn_claymore_world"
//        origin "8827 -5838 103"  angles "0 180 0" }
//  Two structs at the SAME origin, with the model struct rotated +90 from the
//  buy struct. Both halves are picked up exactly like a weapon_upgrade pair -
//  _zm_weapons.gsc:849 and its client twin _zm_weapons.csc:182 both arraycombine
//  getstructarray( "claymore_purchase", "targetname" ) into the spawnable list -
//  which is why this needs the same server+client pair the semtex needed, and
//  for the same reason: one "world" clientfield per wall buy, named from the
//  struct, so a struct on one side only is EXE_CLIENT_FIELD_MISMATCH at load.
//
//  -- THE YAW, DERIVED RATHER THAN GUESSED ----------------------------------
//  "Sideways" is the failure mode the user called out, so the angle is taken
//  from the stock pair above rather than from the model's bounds:
//    - At the farm claymore, the walkable side is +Y: every pathnode within 120
//      units sits at dy 0..+95 and none at negative dy. So the wall's outward
//      normal there points +Y, i.e. 90 degrees.
//    - Stock's buy struct is yaw 90 and its model struct is yaw 180. So the rule
//      is  buy yaw = the wall's outward normal angle,  model yaw = that + 90.
//    - .where reports where the player STOOD and which way they FACED, and this
//      mod's own convention for it is "stand where you want it, face the way it
//      should face" (quality_of_life.gsc:4799). Facing 270 therefore means the
//      claymore faces 270, so the wall's outward normal is 270 and the pair is
//      buy yaw 270 / model yaw 0 (270 + 90).
//
//  -- THE HEIGHT, MEASURED --------------------------------------------------
//  Stock's claymore sits at z 103 with its floor at ~52 (its nearest pathnodes
//  are z 78, and in this same map a pathnode sits 26 units above the floor -
//  the Diner nodes are z -32 with the floor at -58). That is 51 units up the
//  wall. The flashed z is the player's feet, so the floor here is -58 and the
//  same 51 units puts this one at z -7.
//
//  -- WHAT IS AND IS NOT SETTLED --------------------------------------------
//  The orientation and the mount height are derived from measurements. The
//  DISTANCE to the wall is not: .where reports where the player was standing,
//  not the surface they were looking at, and neither the base map's ents nor the
//  survival addon's carry a barrier or brush face within 1000 units of the spot
//  that could pin the plane down offline. So the origin defaults to the flashed
//  spot exactly, and x/y/z/yaw are dvars - the same treatment the Diner semtex
//  had while it was being landed, and the same two-line nudge if it needs one:
//      zmqol_claymore_diner_y -7430      (into the wall, 1 unit at a time)
//      zmqol_claymore_diner_z -7          (up or down the wall)
//
//  ── v2.2.0: IT WAS FLOATING IN THE MIDDLE OF THE SHACK, AND NOW IT IS ON THE
//     WALL, MEASURED ───────────────────────────────────────────────────────────
//  User, 2026-08-21: *"the claymore wallbuy on Diner Survival is still floating
//  in the middle of the shack... have it properly aligned to the wall next to
//  the window where zombies come through in the shack."*
//
//  🌟 THE WALL IS IN THE MAPENTS AFTER ALL - the block above looked for a
//  barrier ENTITY and there is none, but the WINDOWS are there as mantle lanes,
//  and a mantle lane straddles the surface it crosses. Both of the shack's
//  windows are in the zm_transit dump:
//        window A   begin (-3839, -7531, -28) -> end (-3839, -7447, -28)
//        window B   begin (-3564, -7536, -28) -> end (-3564, -7452, -28)
//                   (targetname "hatch_storage_node", animscript zm_mantle_over_40)
//  Both run along +Y with 84 units between begin and end, so the wall they cross
//  is a single east-west plane at  y = -7494,  with the shack interior on the +Y
//  side. That also settles which window the user means: from the flashed spot
//  (-3615, -7398) window B is 109 units away and window A is 245, so it is B.
//
//  THE NEW ORIGIN, term by term:
//        y = -7486   the interior face of that wall: the plane is y = -7494 and
//                    the model is mounted just inside it
//        x = -3630   66 units west of window B's centre, i.e. beside the window
//                    and clear of it - the window is ~64 wide so its west edge
//                    is near x = -3596, and the claymore's own half-width is
//                    ~15, leaving about 19 units of gap. West rather than east
//                    because west is where the user was standing.
//        z = -7      UNCHANGED. The 51-units-up-the-wall figure was derived from
//                    stock's own farm claymore and nothing about it has changed.
//        yaw = 90    the wall's outward normal is +Y (the interior side, where
//                    the mantle END nodes are), and this file's own derived rule
//                    is buy yaw = outward normal, model yaw = that + 90. The old
//                    270 came from reading the player's FACING as the wall
//                    normal, which is what put it in mid-air pointing the wrong
//                    way.
//
//  📝 RESIDUAL RISK, STATED PLAINLY: the WALL PLANE is measured, the WALL
//  THICKNESS is not - mapents carries no brush geometry, so "8 units in from the
//  plane" is the one estimated term. If it ends up a little proud of the wall or
//  a little sunk into it, that is a one-line nudge and nothing else moves:
//      zmqol_claymore_diner_y -7490    (further into the wall)
//      zmqol_claymore_diner_y -7482    (further out of it)
//  Standing with your back to the exact spot and running .where would settle it
//  outright.
//
//  🛑 THE DVARS ARE READ ON BOTH SIDES FROM THE SAME DEFAULTS. Changing one
//  renames the clientfield on both sides identically, which is safe; changing
//  one side's default alone is a guaranteed drop at load. Both defaults moved
//  together in v2.2.0 - zm_expanded.csc has the identical numbers.
//
//  📝 NO ASSET WORK. claymore_zm is already in this mod's include list for
//  TranZit (scripts\zm\zm_transit\zm_transit.csc:82 and the server twin), and
//  t6_wpn_claymore_world is stock's own wall-buy model, already in the level for
//  the farm claymore - the same reasoning that settled the semtex bag.
//
//  ── v2.2.6: THE POST WEST OF IT WAS MEASURED OFF THE SCREENSHOT ─────────────
//  User, 2026-08-23, screenshot JSRY2LneTx.jpg: *"it's a bit too far off to the
//  right from the window therefore colliding with the structure itself, so just
//  move it a tiny bit off to the left ... also i couldn't interact with it in
//  the position it's in currently."*
//
//  🌟 THE BEAM IS BAKED WORLD GEOMETRY - it is in NO mapents dump, so it was
//  measured out of the picture instead. Everything below is arithmetic on
//  numbers that were read, not estimated:
//    * the shot's own HUD gives the camera:  x -3629  y -7416  z -58  yaw 269
//    * the dvar dump in that session's console_zm.log gives  cg_fov "100"  and
//      r_mode "2560x1440", so the Hor+ horizontal FOV is
//          2*atan( tan(50 deg) * (16/9)/(4/3) ) = 115.6 deg,  tan(half) = 1.589
//    * a pixel sweep of rows 480 / 560 / 640 / 700 finds the same dark vertical
//      band at px 1302-1339 in every one of them (luminance ~22 against ~90 for
//      the chalk either side), so it is a vertical post, 38 px wide, centred on
//      px 1320.5
//    * screen right is -X here (right = anglestoright(269) = (-1.000, 0.017)),
//      and at the wall's 70-unit depth one pixel is 2*70*1.589/2560 = 0.0869
//      units, so the post is 3.3 units wide with its centre at
//          x = -3629 + 70*(-0.01745) + 3.52*(-0.99985) = -3633.7
//      i.e. it spans x -3635.4 .. -3632.1
//    * the mine is 11.16 wide (its mesh, above), so at x -3630 it spanned
//      -3635.6 .. -3624.4 - THE POST COVERED ITS WESTERN 3.3 UNITS, which is
//      exactly the overlap the screenshot shows.
//
//  🌟 THE CHECK THAT SAYS THE MODEL IS RIGHT: the same arithmetic predicts the
//  shack window at px 494 and it is measured at ~454. 40 px out of 2560 on an
//  eyeballed window centre, so the camera model is sound.
//
//  x -3630 -> -3624 puts the mine at -3629.6 .. -3618.4: 2.5 units clear of the
//  post, and still 22 units clear of window B's western edge (~-3596), so it
//  cannot drift into the window either. Nothing else moves.
//
//  📝 WHY THIS SHOULD ALSO FIX "I COULDN'T PURCHASE IT". The use trigger is a
//  unitrigger_box_use with require_look_at = 1 (_zm_weapons.gsc:936-960), so the
//  prompt needs a clear line of sight from the crosshair to the trigger. With a
//  solid post standing in front of the mine's western third that trace lands on
//  the post. This is the likeliest cause and it is NOT proven - the post is not
//  in any dump, so its depth cannot be confirmed offline.
//
//  🛑 RESIDUAL RISK AND THE ONE-LINE NUDGE. If it is still fouled, or still not
//  buyable, the origin is dvar-driven and nothing needs rebuilding:
//      zmqol_claymore_diner_x -3618     (further east, away from the post)
//      zmqol_claymore_diner_x -3630     (back to where v2.2.5 had it)
//  🛑 BOTH SIDES CARRY THE SAME DEFAULT. zm_expanded.csc:429 was changed in the
//  same edit; the client is what spawns the visible model, so changing one alone
//  moves the trigger and leaves the mine behind.
// ============================================================================
//  🌟 v2.4.7 - THE SHACK CLAYMORE MOVED TO THE JUGG WALL, FOR REAL THIS TIME.
//
//  The root cause was never the wall - it was bear 1 of the 3-teddy-bear
//  easter egg (quality_of_life.gsc:3926) sitting 70 units away with its own
//  50-unit trigger_radius, overlapping the claymore's measured 33-unit
//  interact radius by 13 units and winning every interact press (checkpoint
//  120). zmqol_probe_jugg_wall() (v2.4.3, then v2.4.6) measured the new spot
//  before committing to it - anchored on Juggernog's own known-correct wall
//  mount (yaw -45) rather than a guessed angle, walked candidates along that
//  wall, and cross-checked against the user's own `.where` reading taken
//  standing there. Removed now that its job is done; the numbers it produced
//  are what zmqol_claymore_wallbuy_origin() below uses.
// ============================================================================
zmqol_claymore_wallbuy_origin()
{
	// Twin of zm_expanded.csc::zmqol_claymore_wallbuy_origin(). Same dvars, same
	// defaults - if these ever disagree the two sides register different
	// clientfield names and everyone is dropped at load.
	//
	// v2.4.7 - MOVED OFF THE OLD WALL ENTIRELY, NOT REPOSITIONED ON IT. The old
	// spot (-3624,-7486,-7) was never actually broken - checkpoint 120 measured
	// the real cause: one of the 3 teddy-bear easter egg props (bear 1,
	// quality_of_life.gsc:3926, at -3685,-7452,-21 with its own 50-unit
	// trigger_radius) sits only 70 units away, close enough to overlap the
	// claymore's own 33-unit interact radius (50+33=83 > 70) and win every
	// interact press.
	//
	// 🛑 v2.4.8 - v2.4.7's FIRST TRY FLOATED IN OPEN FLOOR, NOT ON A WALL. That
	// position anchored on Juggernog's own origin plus a tangent offset, which
	// assumed Jugg's model origin sits ON the wall plane - it doesn't (machine
	// origins commonly sit forward of the wall they're mounted on), so the
	// offset carried that same gap outward with it. User confirmed: purchase
	// itself worked perfectly at that spot (proves the bear-overlap fix was
	// correct) - only the visual placement was wrong, so this was a position
	// nudge, not a re-diagnosis.
	//
	// Fixed with a direct reading instead of a second computed offset: user
	// stood with their BACK AGAINST the actual wall next to Jugg and ran
	// `.where`: (-3577,-7195,-58) facing yaw 269. Floor read -58, same as every
	// other measurement in this shack, so mount height stays -7 (51 up).
	//
	// 🛑 v2.4.9 - THE NORMAL WAS BACKWARDS. Standing with your BACK against a
	// wall and facing into the room means your OWN facing direction already
	// IS the wall's outward normal - a wall can only push you away from
	// itself, never toward it. v2.4.8 subtracted 180 from that reading, which
	// pointed the model's front face INTO the wall instead of out into the
	// room - invisible/embedded, exactly what the user reported ("facing
	// towards the wall, can't even see it"). Corrected: normal = 269, rounded
	// to 270 - the SAME clean angle the original south wall used, which is a
	// coincidence worth noting but not a sign this is actually that wall; it
	// is a separate, nearby segment, confirmed by Jugg's own very different
	// registered angle (-45) a short distance from here.
	//
	// Also moved 25 units along the wall toward Jugg (x -3577 -> -3552,
	// closing the gap from 55 to 30 units) per the user's own follow-up -
	// still comfortably clear of bear 1 (220+ units either way).
	//
	// 🌟 v2.5.4 - FLUSH, NOT EMBEDDED, AND RECENTERED BETWEEN THE PILLARS.
	// User, 2026-08-27, live in-game: "ever so slightly clipped into the wall,
	// pull it forward a few pixels" + "move it left a bit to center between
	// the 2 wooden pillars."
	//
	// The forward pull is a measured correction, not a guess: v2.2.5's own
	// mesh-export analysis above (t6_wpn_claymore_world_LOD_0) gives the
	// model's local-X (depth) span as -2.51 (back) .. 1.63 (front), and model
	// yaw 270 maps local +X to world -Y, so local -X (the back) sits at
	// world y = origin + 2.51 - i.e. 2.51 units on the WALL side of whatever
	// y the origin sits at. Origin at the measured wall surface (-7172, from
	// v2.5.3) therefore embeds the back ~2.5 units into the wall - exactly
	// the "slightly clipped" the user just reported. Pulled the origin 3
	// units further into the room (-7172 -> -7175) so the back face clears
	// the surface with a hair of margin instead of sitting past it.
	//
	// The left move is the user's own live read of the room (only they can
	// see the model against the pillars in real time) - moved one step
	// further into the already-probed-clear x range from v2.5.3 (-3552 ->
	// -3560, i.e. further from Jugg / away from bear 1), still 32 units
	// clear of the -3592 trim post on the far side and 32 units clear of
	// Jugg's approach on the near side. Not re-derived from a screenshot;
	// if it isn't centered yet, it needs another live read, not a bigger
	// guess from here.
	//
	// 🌟 v2.5.5 - ONE UNIT BACK TOWARD THE WALL. User, 2026-08-27, live
	// in-game: x is now right ("nearly perfect"), but -7175 left a very
	// slight gap - "every so slightly floating off the wall." v2.5.4's
	// mesh-based pull (2.51 rounded up to 3) overshot by about that same
	// margin. Nudged 1 unit closer (-7175 -> -7174, 2 units off the -7172
	// measured surface instead of 3) - the mesh math and the two live reads
	// ("every so slightly clipped" at -7172 before v2.5.4, "every so
	// slightly floating" at -7175 now) bracket the true value inside a
	// 1-unit band. If -7174 isn't it, the only remaining candidate in that
	// band is -7173.
	//
	// 🛑 v2.5.7 (RETRACTED, v2.5.8 below) - moved x -3560 -> -3620 on a theory
	// that get_closest_unitriggers() was arbitrating between the claymore's
	// unitrigger and Jugg's classic trigger_radius_use and picking whichever
	// was closer. User: "why did you move the claymore over to the left?? i
	// never asked for you to do that put it back" + still not purchasable
	// without noclipping through the wall at the NEW spot either - proving
	// the theory wrong twice over, not just unwanted.
	//
	// 🛑 v2.5.8 - THE THEORY WAS WRONG. VERIFIED BY ACTUALLY READING
	// get_closest_unitriggers() (ZM Core/_zm_unitrigger.gsc:674), not
	// assuming from the bear-1 precedent again. Its `array` argument is a
	// candidate list of UNITRIGGER STUBS ONLY - the same system the
	// claymore, teddy bears, shield pieces and craftables use. Jugg's use
	// trigger is spawned by a completely different, older stock system
	// (perk_machine_spawn_init(), ZM Core/_zm_perks.gsc:2877,
	// spawn("trigger_radius_use", ...)) that never enters that candidate
	// array at all. Jugg cannot be "closer" and win a comparison it was
	// never entered into. Moving the claymore relative to Jugg was never
	// going to change this outcome, which is exactly what the second boot
	// showed - x -3620 failed identically to x -3560.
	//
	// x REVERTED to -3560 per the user's direct instruction - no reason left
	// to have moved it, and the pillar-centered spot was never the problem.
	//
	// The real mechanism is still open. What's confirmed from the logs
	// (both boots): the unitrigger DOES reach would_qualify=1 and DOES build
	// a live trigger (stub.trigger becomes defined) at a normal standing
	// distance - so the unitrigger system itself is not the blocker. What's
	// NOT yet confirmed: what happens after that point that still requires
	// noclipping through the wall to actually purchase. Two live candidates,
	// not yet distinguished:
	//   (a) a shared single-slot "hold to use" prompt where Jugg's classic
	//       trigger (built once at map load, always present) wins over the
	//       claymore's dynamically-built one whenever the player is close
	//       enough to touch both - independent of the unitrigger system.
	//   (b) something physically blocking the floor space in front of the
	//       claymore (Jugg's own zm_collision_perks1 clip mesh, now mounted
	//       right next to it) that only noclip bypasses.
	// zmqol_claymore_trigger_watch() below now logs directly for this
	// instead of guessing between them - see its own v2.5.8 comment.
	//
	// Kept the user's own "still floating, a tiny bit closer" report from
	// last round: y -7174 -> -7173, the last untried candidate in the
	// v2.5.5 bracket (-7172 clipped / -7175 floated). Not contested this
	// round, no reason to revert it.
	//
	// 🛑 v2.6.3 - JUGG REVERTED (see struct_init() above - proven not the
	// cause). User, direct: "try moving the claymore a tiny bit forward so
	// i could buy it." This is an explicit experiment, not a re-measured
	// fix - four attempts at the trigger/dispatch layer (v2.5.7, v2.6.0,
	// v2.6.1, v2.6.2) didn't move the needle, so this tries the one
	// remaining untested variable: physical standing room. y -7173 -> -7180,
	// 7 units further into the room (8 off the measured wall surface,
	// versus 1 before) - more clearance to actually stand and aim at it,
	// at the cost of reopening the "floating" look v2.5.5 fixed. Functional
	// over cosmetic, per the user's own priority this round.
	//
	// 🌟 v2.6.4 - FINDING THE SWEET SPOT. User: purchasable at -7180, "but
	// it's too far off the wall... gotta get that sweet spot." Confirms the
	// real variable all along was physical standing room, not any trigger/
	// dispatch mechanism - -7173/-7174 (1-2 off the wall) failed every time,
	// -7180 (8 off) works. The true minimum is somewhere in that 6-unit gap.
	// Bisecting rather than guessing from an end: -7177, the midpoint.
	//
	// 🌟 v2.6.5 - User: -7177 still noticeably off the wall, wants a small
	// nudge back. Moved 1 unit closer (-7177 -> -7176) - still 2 units clear
	// of the -7174 line that was confirmed unpurchasable every time it was
	// tried, so purchasing shouldn't be at risk from this one-unit step.
	return ( getdvarintdefault( "zmqol_claymore_diner_x", -3560 ), getdvarintdefault( "zmqol_claymore_diner_y", -7176 ), getdvarintdefault( "zmqol_claymore_diner_z", -7 ) );
}

// ============================================================================
//  🌟 v2.5.3 - THE FLAT PANEL, MEASURED. Y MOVED FROM -7195 TO -7172.
//
//  v2.5.0's zmqol_probe_jugg_flat_wall() shipped in v2.5.2 and its output was
//  read from a real boot: %LOCALAPPDATA%\Plutonium\storage\
//  t6\main\console_zm.log, lines 4780-4791, from the same session the user's
//  two `.where` screenshots (-3602,-7199,-58 / -3553,-7255,-58) came from -
//  the one where they confirmed the claymore was purchasable. Full result:
//        x=-3552  hit_y=-7172  dist=77      x=-3584  hit_y=-7172  dist=77
//        x=-3560  hit_y=-7172  dist=77      x=-3592  hit_y=-7180  dist=70  <- trim post
//        x=-3568  hit_y=-7172  dist=77      x=-3600  hit_y=-7172  dist=77
//        x=-3576  hit_y=-7172  dist=77      x=-3608  hit_y=-7172  dist=77
//  Seven of eight candidates agree on hit_y -7172 to the unit - a real flat
//  plane, not noise. x=-3592 alone is short (dist 70, hit_y -7180): the trim
//  post, exactly as the v2.5.0 comment predicted, sitting narrow enough that
//  the flat panel resumes on both sides of it.
//
//  The existing default x=-3552 was ALREADY clear of the post - only y was
//  wrong. It was -7195, i.e. 23 units short of the measured wall (-7172):
//  the mine's origin sat in open room air in front of the panel, which is
//  exactly the "floating off the wall" the user's screenshots showed. Moved
//  to -7172, the measured surface itself - same convention v2.3.2 used for
//  the original shack wall (WALLX -7486 taken directly off its own flat-hit
//  reading, no added offset), so this isn't a new rule, just this file's
//  existing one applied with real data instead of a guess.
// ============================================================================

zmqol_add_claymore_wallbuy()
{
	// ========================================================================
	//  🌟 v2.3.2 - MEASURED AND ON. zmqol_probe_shack_wall() (v2.2.7) fanned
	//  bullettraces at the shack from inside the room. Real results, read
	//  straight from console_zm.log:
	//    WALLX  flat hit at y -7486 across x -3628..-3592 (the flat run this
	//           wall buy sits inside), normal (0,100,0)/100 = outward +Y - the
	//           yaw 90 already coded is exactly that normal.
	//    WALLZ  flat at y -7486 from z -56 to z 44 at x -3624 - no post, no
	//           step, in the whole free-standing height the mine could use.
	//    FLOOR  x -3624 y -7440: z -58, so mount height z -7 is 51 units up -
	//           the intended offset, now confirmed against a real floor
	//           instead of an assumed one.
	//    OUT    trace from the current origin (-3624,-7486,-7) into the room:
	//           fraction 1000/1000 - clear, so the mine is NOT embedded in the
	//           brush (the failure mode that made it unbuyable three times).
	//  Every existing default (x -3624, y -7486, z -7, yaw 90) already matched
	//  the measured geometry - three prior placement rounds (v2.2.0, v2.2.5,
	//  v2.2.6) had converged on the right numbers without ever being able to
	//  prove it. The probe function and its main() call are removed per its
	//  own instruction now that the wall buy is landed.
	//
	//  🛑 THE GATE IS SYMMETRIC OR IT IS FATAL. zm_expanded.csc reads the same
	//  dvar with the same default. Registering this pair on one side only is
	//  EXE_CLIENT_FIELD_MISMATCH at load, because _zm_weapons names the wall
	//  buy's "world" clientfield from the struct (:889 server, :218 client).
	//  If you flip this default, flip the client's in the same edit.
	// ========================================================================
	if ( getdvarintdefault( "zmqol_claymore_diner_enabled", 1 ) == 0 )
	{
		println( "[zm_qol] diner claymore: DISABLED (zmqol_claymore_diner_enabled 0)" );
		return;
	}

	v_origin = zmqol_claymore_wallbuy_origin();
	// v2.4.9 - CORRECTED SIGN: back-to-the-wall facing direction IS the wall's
	// outward normal directly (269, rounded to 270) - v2.4.8 wrongly
	// subtracted 180 from it, see zmqol_claymore_wallbuy_origin() above for
	// the full explanation. The buy-yaw-is-normal-minus-90 relationship a few
	// lines below is unchanged.
	n_yaw    = getdvarintdefault( "zmqol_claymore_diner_yaw", 270 );

	// ========================================================================
	//  🛑 v2.2.5 - THE PAIR WAS 90 DEGREES OUT AND THE MINE WAS EDGE-ON IN THE
	//  WALL. THE ROLES OF THE TWO YAWS WERE SWAPPED.               (measured)
	//
	//  User, 2026-08-22, with a screenshot: *"the claymore wallbuy in diner
	//  survival is facing the wrong way, thus colliding into the wall and
	//  looking scuffed."* The screenshot shows the mine almost entirely inside
	//  the wall with only its glowing edge past a vertical beam - which is what
	//  you get when the model's WIDTH axis points into the wall instead of
	//  along it.
	//
	//  -- THE MODEL'S OWN AXES, FROM ITS MESH --------------------------------
	//  t6_wpn_claymore_world_LOD_0.XMODEL_EXPORT, 1058 verts, in game axes:
	//        X (forward)  -2.51 .. 1.63    span  4.14   <- the THIN axis
	//        Y (left)     -5.57 .. 5.59    span 11.16   <- the mine's width
	//        Z (up)       -2.34 .. 9.67    span 12.01   <- height, legs below
	//  A claymore is ~11 wide, ~4 thick and ~12 tall on its stand, so local X
	//  is the front-to-back axis and local +X is the face - confirmed by the
	//  model's only other tag, tag_fx, at OFFSET (1.603, 0, 8.638), i.e. sat on
	//  the +X surface where the blast fx belongs.
	//
	//  An entity's yaw points local +X at that world angle. So for the mine to
	//  lie flat on a wall, MODEL YAW MUST EQUAL THE WALL'S OUTWARD NORMAL.
	//  The old code used normal + 90, which pointed the face along the wall and
	//  drove the 11-unit width straight through it.
	//
	//  -- WHAT THE BUY STRUCT'S YAW REALLY IS --------------------------------
	//  Not the wall normal. _zm_weapons.gsc:931 places the use trigger with
	//        origin -= anglestoright( buy.angles ) * ( script_length * 0.4 )
	//  and anglestoright( yaw ) is the direction yaw-90. Stock wants that
	//  trigger pushed OFF the wall into the room, and that only happens when
	//  buy yaw = normal - 90. So the pair is:
	//        buy yaw   = wall outward normal - 90
	//        model yaw = wall outward normal
	//  which reproduces stock's own constant +90 gap between the two.
	//
	//  -- CHECKED AGAINST ALL EIGHT STOCK CLAYMORE WALL BUYS -----------------
	//  Every claymore_purchase / t6_wpn_claymore_world pair in the game, read
	//  out of the mapents dumps - buy yaw -> model yaw:
	//        transit farm  90 -> 180     buried street  90 -> 180
	//        highrise      60 -> 150     nuketown      285 ->  15
	//        prison        90 -> 180     tomb A        180 -> 270
	//        tomb B         0 ->  90     tomb C        180 -> 270
	//  Model = buy + 90 in all eight. 🌟 zm_tomb's pf2209 pair is buy 0 /
	//  model 90 - the exact pair this file now writes - so this is a shipped
	//  stock configuration, not an invention.
	//
	//  -- THE WALL, UNCHANGED FROM v2.2.0 ------------------------------------
	//  The shack's south wall is the plane through both of its mantle lanes,
	//  y = -7494, and the interior is the +Y side: both node_negotiation_begin
	//  nodes sit at y -7531 / -7536 with angles "0 90 0", so the AI mantles
	//  from outside toward +Y. Outward normal = +Y = 90. The origin does not
	//  move; at model yaw 90 only the mine's 2.51-unit back sits toward the
	//  wall, so it can no longer clip it.
	//
	//  🛑 BOTH SIDES CHANGED TOGETHER. zm_expanded.csc's twin carries the same
	//  two expressions. The clientfield name is built from the ORIGIN only
	//  (_zm_weapons.gsc:889), so angles cannot desync it - but the client is
	//  what actually spawns the visible model (_zm_weapons.csc:268 uses
	//  target_struct.angles), so a change here alone would do nothing at all.
	// ========================================================================
	s_model = spawnstruct();
	s_model.targetname = "zmqol_claymore_diner";
	s_model.origin = v_origin;
	s_model.angles = ( 0, n_yaw, 0 );
	s_model.model = "t6_wpn_claymore_world";
	scripts\zm\replaced\utility::add_struct( s_model );

	s_buy = spawnstruct();
	s_buy.targetname = "claymore_purchase";
	s_buy.origin = v_origin;
	// normal - 90, so the use trigger is pushed off the wall into the room.
	// See the derivation above; this is stock's own relationship.
	s_buy.angles = ( 0, n_yaw - 90, 0 );
	s_buy.zombie_weapon_upgrade = "claymore_zm";
	s_buy.target = "zmqol_claymore_diner";
	scripts\zm\replaced\utility::add_struct( s_buy );

	println( "[zm_qol] diner claymore: wallbuy struct at (" + int( v_origin[0] ) + "," + int( v_origin[1] ) + "," + int( v_origin[2] ) + ") wall normal " + n_yaw + " (model yaw " + n_yaw + ", buy yaw " + ( n_yaw - 90 ) + ")" );
}

// ============================================================================
//  🌟 v2.3.9 - THE ROOT CAUSE, READ OUT OF THE STOCK UNITRIGGER SYSTEM, NOT
//  GUESSED. "Model visible, crosshair on it, no purchase prompt" (checkpoint
//  106, re-reported 2026-08-26 as the position looking wrong) is exactly the
//  signature of a trigger that never got a live server-side trigger spawned,
//  while its CLIENT-side visual (a clientfield, entirely separate system)
//  shows regardless. Read start to finish this session, not inferred:
//
//  init_spawnable_weapon_upgrade() (_zm_weapons.gsc:839) builds our injected
//  "claymore_purchase" struct into a unitrigger_stub and hands it to
//  _zm_unitrigger::register_static_unitrigger() (_zm_weapons.gsc:978). THAT
//  function (_zm_unitrigger.gsc:198) finds which of the map's TranZit bus-
//  route ZONES the stub's origin falls inside and files it under
//  level.zones[key].unitrigger_stubs - it does NOT make the trigger live.
//
//  _zm_unitrigger::main() (_zm_unitrigger.gsc:352) is what actually spawns
//  live triggers near a player, and every frame it only considers stubs
//  belonging to a zone in level.active_zone_names (:376-383), PLUS a second,
//  always-included bucket: level._unitriggers.dynamic_stubs. TranZit's zone
//  set is the bus-route progression system - it exists to gate the story
//  mode's travel, and Diner survival never drives a bus through it, so
//  whichever zone this shack's origin geometrically falls inside may simply
//  never be marked active for the whole match. If so, the stub sits in a
//  zone list that main()'s loop never looks at, forever - not a timing race,
//  not a one-off, a permanent gate. The model still shows because its
//  clientfield truth is unrelated to any of this.
//
//  🌟 THE FIX USES STOCK'S OWN ESCAPE HATCH, NOT A WORKAROUND.
//  _zm_unitrigger::reregister_unitrigger_as_dynamic() (:246) is what the
//  engine itself uses for pickups that must stay interactive independent of
//  zone state (dropped weapons, etc.) - it unregisters the stub from
//  whatever zone list it landed in and re-adds it to dynamic_stubs, which
//  main()'s loop includes unconditionally every frame regardless of which
//  zones are active. That is exactly the property a custom survival-only
//  wall buy needs, since survival never drives the zone system the normal
//  way. Applying it here does not touch the zone system for anything else -
//  only this one stub is moved.
//
//  📝 STILL MEASURED, NOT ASSUMED WORKING: this prints exactly what state the
//  stub was in before the fix (in_zone / whether that zone was active) to
//  console_zm.log. The on-screen half of this (iprintln) was removed in
//  v2.6.7 now the fix is confirmed - see the v2.6.7 note above
//  zmqol_fix_claymore_zone_gate().
// ============================================================================
// ============================================================================
//  🌟 v2.5.5/v2.5.7 - JUGG'S CORNER, MEASURED, THEN SUPERSEDED BY THE REAL
//  BUG. zmqol_probe_jugg_corner() (removed here, job done) fired two fans of
//  bullettraces to map the corner before Jugg moved into it. By the time it
//  actually ran (v2.5.6 had already relocated Jugg per the user's explicit
//  instruction to proceed without waiting), its own traces mostly just hit
//  JUGG'S OWN NEW MODEL instead of the underlying wall/corner brushes - e.g.
//  "JUGG WALLY x=-3522 hit_y=-7205 dist=44" where the earlier flat run had
//  read -7172 - useless for mapping the room, but it incidentally confirmed
//  Jugg's model footprint sits right where its new origin says it does, and
//  more importantly the session's log made the REAL problem obvious: the
//  claymore stopped being purchasable. That turned out to be a use-trigger
//  radius conflict, not a corner/wall geometry problem at all - see the
//  v2.5.7 comment on zmqol_claymore_wallbuy_origin() for the full,
//  log-verified diagnosis and fix.
// ============================================================================
zmqol_fix_claymore_zone_gate()
{
	// v2.4.0: was a flat "wait 3;", found too short by a boot-tested case
	// where init_spawnable_weapon_upgrade() hadn't registered the stub yet.
	// Polls instead, up to 15s.
	//
	// 🛑 v2.6.7 - ALL ON-SCREEN TROUBLESHOOTING TEXT REMOVED. User, screenshot,
	// 2026-08-27: "this weird shit keeps popping up on the screen in diner,
	// the claymore issue is already solved so remove that, that was for
	// troubleshooting earlier." Every iprintln() this fix and
	// zmqol_claymore_trigger_watch() below used to show the player (the
	// per-tick "d2d=... rad=... zd=... qual=..." readout especially) is gone;
	// the console-only println() breadcrumbs stay, same as every other solved
	// feature in this file (e.g. the semtex wallbuy's own struct-spawn log).
	n_waited = 0;

	while ( !isdefined( level._spawned_wallbuys ) && n_waited < 15 )
	{
		wait 0.5;
		n_waited += 0.5;
	}

	if ( !isdefined( level._spawned_wallbuys ) )
	{
		println( "[zm_qol] CLAYMORE FIX: level._spawned_wallbuys still undefined after " + n_waited + "s - init_spawnable_weapon_upgrade() never ran" );
		return;
	}

	stub = undefined;

	for ( i = 0; i < level._spawned_wallbuys.size; i++ )
	{
		e = level._spawned_wallbuys[i];

		if ( isdefined( e.targetname ) && e.targetname == "claymore_purchase" && isdefined( e.trigger_stub ) )
		{
			stub = e.trigger_stub;
			break;
		}
	}

	if ( !isdefined( stub ) )
	{
		println( "[zm_qol] CLAYMORE FIX: no trigger_stub found for claymore_purchase - init_spawnable_weapon_upgrade() did not register one, this is a different bug" );
		return;
	}

	str_zone = "none";
	b_was_active = 0;

	if ( isdefined( stub.in_zone ) )
	{
		str_zone = stub.in_zone;

		if ( isdefined( level.zones[stub.in_zone] ) && is_true( level.zones[stub.in_zone].is_active ) )
			b_was_active = 1;
	}

	println( "[zm_qol] CLAYMORE FIX: before - in_zone=" + str_zone + " was_active=" + b_was_active + " require_look_at=" + stub.require_look_at + " registered=" + isdefined( stub.registered ) );

	// ========================================================================
	//  🌟 v2.6.0 - THE ACTUAL BLOCKER, FOUND BY READING THE ENGINE CALL, NOT
	//  GUESSED. User clipped through the wall with `.fly` and showed the real
	//  "Hold F for Claymore" prompt appears fine from a position basically ON
	//  TOP OF the model - proving the unitrigger itself works (qualify and
	//  registration were never the problem, matching every prior boot's
	//  would_qualify=1/live_trigger=1) and narrowing this to something about
	//  the APPROACH, not the trigger.
	//
	//  init_spawnable_weapon_upgrade() (_zm_weapons.gsc:959) sets
	//  unitrigger_stub.require_look_at = 1 UNCONDITIONALLY for every
	//  weapon_upgrade struct in the game, no exceptions, claymore included.
	//  _zm_unitrigger.gsc:585-586 turns that into a real engine call on the
	//  built trigger: `trigger usetriggerrequirelookat()` - the player's
	//  crosshair has to have a clear trace to the object, not just be in
	//  range. This wallbuy sits essentially flush against a large flat wall
	//  (v2.5.3 onward pulled it to within 1-3 units of the measured surface,
	//  y=-7173) with Jugg's own bulk nearby - from most normal standing
	//  angles in this cramped corner, a crosshair trace aimed at the model's
	//  origin very plausibly grazes the wall or Jugg first instead of
	//  clearing to the small model. Clipping through the wall puts the
	//  player's eye right next to the target, where that trace trivially
	//  succeeds - exactly what the user's screenshot showed.
	//
	//  Every other wallbuy in this file (semtex, the roof weapons) has this
	//  same stock requirement and hasn't been reported broken, so removing it
	//  isn't a general "fix" - it's scoped to this ONE stub, the one placed
	//  in the one corner tight enough for the requirement to actually bite.
	//  Set BEFORE reregister_unitrigger_as_dynamic() below builds the live
	//  per-player trigger, so usetriggerrequirelookat() never gets called on
	//  it in the first place - not fighting the check after the fact.
	// ========================================================================
	stub.require_look_at = 0;
	println( "[zm_qol] CLAYMORE FIX: require_look_at forced to 0 (was 1) - crosshair-aim requirement removed for this wallbuy only" );

	// The actual fix - see the block comment above.
	maps\mp\zombies\_zm_unitrigger::reregister_unitrigger_as_dynamic( stub );

	println( "[zm_qol] CLAYMORE FIX: reregistered as dynamic - now always live regardless of zone state" );
	println( "[zm_qol] CLAYMORE FIX: dynamic_stubs.size=" + level._unitriggers.dynamic_stubs.size );

	// v2.4.4 - the ACTUAL gate _zm_unitrigger::get_closest_unitriggers() (:674)
	// applies, read line by line rather than assumed: a candidate only counts
	// if distance2dsquared(stub_origin, player_origin+(0,0,35)) < stub.test_radius_sq
	// (HORIZONTAL only) AND abs(z-diff) <= 42. test_radius_sq comes from the
	// model's own small bounding box (script_width/length/height, set in
	// init_spawnable_weapon_upgrade()) - a claymore is ~11x4x12, nowhere near
	// the 40-90 unit radius most wall buys get from bigger models. The last
	// boot's "dist=74, live_trigger=0 for 20+ seconds standing still" used
	// distance() - a 3D figure that conflates the horizontal and vertical
	// components this check keeps separate - so it never actually proved the
	// player was within the real, much smaller window. Printing exactly what
	// the engine checks, not a proxy for it.
	println( "[zm_qol] CLAYMORE FIX: test_radius=" + int( sqrt( stub.test_radius_sq ) ) + " (test_radius_sq=" + int( stub.test_radius_sq ) + ") stub.origin.z=" + int( stub.origin[2] ) );

	// v2.4.0: mechanically, this SHOULD now be enough - _zm_unitrigger::main()'s
	// own loop (:446) only requires stub.registered to be true to spawn a live
	// per-player trigger, and reregister_unitrigger_as_dynamic() just set that.
	// But "should" is a theory, not a measurement, and the last boot still
	// showed no purchase prompt after this exact fix ran. So watch for the one
	// fact that actually settles it: does a live per-player trigger
	// (stub.playertrigger[entnum], since _zm_weapons.gsc:966 marks every
	// spawnable wallbuy trigger_per_player) ever get built when a player is
	// standing near it? If yes, the unitrigger system is fine and the gap is in
	// claymore_unitrigger_update_prompt or is_player_placeable_mine. If a live
	// trigger never appears even at close range, the registration fix did not
	// do what this session assumed, and that needs re-reading, not re-guessing.
	level thread zmqol_claymore_trigger_watch( stub );
}

zmqol_claymore_trigger_watch( stub )
{
	// ========================================================================
	// 🛑 v2.8.0 - THIS LOOP USED TO GIVE UP AFTER 45 SECONDS, AND THAT IS WHY
	// EVERY FIX SINCE v2.6.1 LOOKED LIKE IT DID NOTHING.
	//
	// 🌟 MEASURED, NOT GUESSED, out of the user's own 29 Aug 04:45 boot
	// (storage\t6\main\console_zm.log). The watch printed nine samples and then
	// gave up:
	//     t=0s  dist3d=1681 ... live_trigger=0
	//     t=10s dist3d=1088 ... live_trigger=0
	//     t=40s dist3d=1848 ... live_trigger=0
	//     CLAYMORE WATCH: no live trigger ever appeared in 45s near the stub
	// The CLOSEST the player ever got inside the window was 554 units, against
	// a test_radius of 33.85 (box_radius 18.85 + 15, _zm_unitrigger.gsc:101).
	// The player was simply nowhere near the shack in the first 45 seconds of
	// the match - which is the normal way anyone plays Diner, since the shack
	// is across the arena from spawn.
	//
	// 🛑 SO THE HAND-OFF BELOW NEVER HAPPENED. b_live never went true, so
	// zmqol_claymore_manual_buy_watch() - the v2.6.1 fix that is what actually
	// makes this wall buy purchasable next to Jugg - WAS NEVER STARTED, in any
	// boot. Every "still can't buy it" report since v2.6.1 is explained by the
	// fix not being armed rather than by the fix being wrong. Nothing about
	// v2.6.1's mechanism is re-litigated here; it has simply never run.
	//
	// The bootstrap now runs for the whole match, exactly like the manual-buy
	// watch it hands off to already does ("a player can walk up and try to buy
	// this at any round, not only right after load" - its own comment). It
	// still returns the instant it hands off, so this costs one cheap test per
	// second until the player first walks up, and nothing after that.
	//
	// 📝 Printing is throttled instead of the loop being bounded: a line
	// every 5s only while the player is within 300 units of the stub (plus
	// always on b_live, and one line at 45s so the old log signature does not
	// silently vanish). Far-away samples were the only thing the old window
	// ever captured and they carry no information.
	// ========================================================================
	level endon( "game_ended" );

	n_far_note = 0;

	for ( i = 0; ; i++ )
	{
		wait 1;

		players = get_players();

		if ( players.size == 0 )
			continue;

		p = players[0];
		d = distance( p.origin, stub.origin );

		// The exact two-part test get_closest_unitriggers() runs (:695-701) -
		// horizontal distance squared against test_radius_sq, height difference
		// against a flat 42, checked SEPARATELY, not the 3D distance() above.
		v_eye = p.origin + ( 0, 0, 35 );
		d_2d_sq = distance2dsquared( v_eye, stub.origin );
		n_zdiff = abs( stub.origin[2] - v_eye[2] );
		b_would_qualify = ( d_2d_sq < stub.test_radius_sq ) && ( n_zdiff <= 42 );

		b_live = isdefined( stub.trigger ) || ( isdefined( stub.playertrigger ) && isdefined( stub.playertrigger[ p getentitynumber() ] ) );

		if ( b_live || ( i % 5 == 0 && d < 300 ) )
		{
			str_line = "[zm_qol] CLAYMORE WATCH: t=" + i + "s dist3d=" + int( d ) + " dist2d=" + int( sqrt( d_2d_sq ) ) + " test_radius=" + int( sqrt( stub.test_radius_sq ) ) + " zdiff=" + int( n_zdiff ) + " would_qualify=" + b_would_qualify + " live_trigger=" + b_live + " placeable_mine=" + p is_player_placeable_mine( "claymore_zm" );
			println( str_line );
		}

		// One line at the old 45s mark so a log can still be told apart from a
		// watch that never started at all. Not a give-up any more - the loop
		// carries on until the player actually walks up.
		if ( i == 45 && !n_far_note )
		{
			n_far_note = 1;
			println( "[zm_qol] CLAYMORE WATCH: 45s elapsed, no live trigger yet - STILL WATCHING for the rest of the match (dist3d=" + int( d ) + ")" );
		}

		if ( b_live )
		{
			// 🌟 v2.6.1 - THE REAL FIX. v2.5.9's diagnostic (can_buy_weapon=1,
			// is_drinking=0, every tick, while touching_vending=
			// specialty_armorvest persisted and mine stayed 0) ruled out every
			// GSC-level gate - can_buy_weapon() itself says yes, every time,
			// and v2.6.0's require_look_at removal didn't fix it either. What's
			// left is the one thing GSC can't directly observe: the ENGINE'S
			// OWN native dispatch of the "use" button press to a touched
			// trigger_radius entity. With two overlapping trigger volumes
			// (Jugg's stock one, radius 70, and this stub's dynamically-built
			// one), stock has no reason to have ever handled that case
			// gracefully - wall buys are normally placed far enough apart that
			// it never comes up. The likely behavior: only one trigger per
			// press gets the native notify, and Jugg's (spawned first, at map
			// load) wins it every time, so buy_claymores()'s own
			// `self waittill("trigger", who)` (Tranzit Diner/_zm_weap_claymore
			// .gsc:55) never fires at all near Jugg - explaining every
			// symptom: the gates all pass, the notify itself just never
			// arrives.
			//
			// Fixed by not depending on that native dispatch for THIS wallbuy.
			// zmqol_claymore_manual_buy_watch() below polls the player's raw
			// button state directly with usebuttonpressed() (ZM Core/
			// _zm_craftables.gsc:1817 - the same builtin the modern buildable
			// system already uses for exactly this, so it's a proven pattern,
			// not a new one) and, when the player independently qualifies,
			// fires `trigger notify("trigger", player)` on the REAL live
			// trigger entity itself (stub.playertrigger[entnum], the same one
			// b_live already confirms exists). That is the exact notify
			// buy_claymores() is waiting on - this doesn't reimplement the
			// purchase (cost, sound, hint, weapon_show, clientfield all stay
			// stock's own code, called the normal way), it only stops relying
			// on the engine to deliver the notify when Jugg is also touched.
			// Jugg's own trigger is never touched by this - it keeps working
			// however it already does.
			level thread zmqol_claymore_manual_buy_watch( stub );
			return;
		}
	}

}

zmqol_claymore_manual_buy_watch( stub )
{
	// Runs for the rest of the match, not just the first 45s - a player can
	// walk up and try to buy this at any round, not only right after load.
	n_printed_once = 0;

	for (;;)
	{
		wait 0.1;

		players = get_players();

		foreach ( p in players )
		{
			if ( !isdefined( p ) || !is_player_valid( p ) )
				continue;

			if ( !isdefined( stub.playertrigger ) || !isdefined( stub.playertrigger[ p getentitynumber() ] ) )
				continue;

			v_eye = p.origin + ( 0, 0, 35 );
			d_2d_sq = distance2dsquared( v_eye, stub.origin );
			n_zdiff = abs( stub.origin[2] - v_eye[2] );

			if ( d_2d_sq >= stub.test_radius_sq || n_zdiff > 42 )
				continue;

			if ( !p usebuttonpressed() )
				continue;

			// Half-second debounce per player - buy_claymores() re-checks cost
			// and ownership on every notify so repeat firing wouldn't corrupt
			// anything, this just avoids spamming the same purchase attempt
			// dozens of times a second while the button is held.
			if ( isdefined( p.zmqol_claymore_buy_cooldown ) && gettime() < p.zmqol_claymore_buy_cooldown )
				continue;

			p.zmqol_claymore_buy_cooldown = gettime() + 500;

			e_trigger = stub.playertrigger[ p getentitynumber() ];
			e_trigger notify( "trigger", p );

			if ( !n_printed_once )
			{
				println( "[zm_qol] CLAYMORE MANUAL BUY: fired trigger notify directly (bypassing native dispatch) for " + p.name );
				n_printed_once = 1;
			}
		}
	}
}

zmqol_unlock_shield_buildable_entities()
{
	a_targetnames = [];
	a_targetnames[a_targetnames.size] = "riotshield_zm_buildable_trigger";
	a_targetnames[a_targetnames.size] = "buildable_riotshield";

	n_freed = 0;

	foreach ( str_targetname in a_targetnames )
	{
		a_ents = getentarray( str_targetname, "targetname" );

		if ( !isdefined( a_ents ) )
			continue;

		foreach ( e_ent in a_ents )
		{
			if ( !isdefined( e_ent.script_gameobjectname ) )
				continue;

			e_ent.script_gameobjectname = "[all_modes]";
			n_freed++;
		}
	}

	println( "[zm_qol] diner shield: freed " + n_freed + " bench entities from the gamemode filter (expect 2)" );
}

main()
{
	// zm_qol: guarded. Writing a field on an undefined array entry is fatal in GSC and
	// these two zone names are hardcoded rather than iterated. Everything else in this
	// file is Reimagined's original - the props, barriers and re-modelling were briefly
	// stripped while chasing a crash that turned out to be an unrelated duplicate
	// #include in zm_transit.gsc, and have been restored in full.
	// zm_qol: 🛑 zone_diner_roof IS NO LONGER DISABLED. Reimagined turned it off,
	// which was right when the roof was unreachable - a zone nobody can stand in
	// is dead weight, and this project's own notes record what an unmanaged zone
	// costs. Now that restore_diner_hatch() puts the climb back and Pack-a-Punch
	// is up there, the roof is somewhere players will spend rounds, so it has to
	// be a live zone: that is what makes zombies path to it and what stops a
	// player standing in an area the zone manager is not tracking.
	//
	// Only this one zone, and only because it is the diner's own roof. Enabling
	// zones speculatively is the other half of this project's zone problem -
	// too few and you get a death barrier, too many and the horde scatters
	// across the map instead of coming to the arena.
	//
	// zone_trans_diner2 stays off - it is a separate area, nothing here reaches it.
	if ( isdefined( level.zones ) && isdefined( level.zones["zone_trans_diner2"] ) )
		level.zones["zone_trans_diner2"].is_enabled = 0;

	level thread zmqol_pap_visibility_probe();

	treasure_chest_init();
	init_barriers();
	generatebuildabletarps();
	disable_zombie_spawn_locations();

	// zm_qol: Diner has a Pack-a-Punch now, so it wants the same collision pass
	// every other PaP location gets - Reimagined calls this from tunnel, power,
	// cornfield and docks main(). It pushes the machine's clip back so you cannot
	// get wedged between it and the wall behind it.
	scripts\zm\locs\loc_common::increase_pap_collision();

	level thread scripts\zm\locs\loc_common::init();
	println( "[zm_qol] diner main: DONE" );
}

treasure_chest_init()
{
	chest = getstruct("start_chest", "script_noteworthy");
	level.chests = [];
	level.chests[0] = chest;
	maps\mp\zombies\_zm_magicbox::treasure_chest_init("start_chest");
}

init_barriers()
{
	collision = spawn("script_model", (-5000, -6700, 0), 1);
	collision setmodel("zm_collision_transit_diner_survival");
	collision disconnectpaths();

	origin = (-6350, -7046, -60);
	angles = (0, 165, 0);
	scripts\zm\locs\loc_common::barrier("collision_wall_64x64x10_standard", origin + (anglesToUp(angles) * 32), angles, 1);
	scripts\zm\locs\loc_common::barrier("collision_wall_64x64x10_standard", origin + (anglesToUp(angles) * 96), angles, 1);
	scripts\zm\locs\loc_common::barrier("afr_barrel_biohazard_white_rust", origin + (anglesToForward(angles) * -24) + (anglesToRight(angles) * -16) + (anglesToUp(angles) * 14), angles + (0, 90, 90));
}

// ============================================================================
//  zm_qol: THE TARP IS NOW CONDITIONAL                             (v1.66.0)
//
//  Its origin (-4688,-7974,-64) is the shield bench - the same spot as
//  riotshield_zm_buildable_trigger at (-4688,-7966,-6). Reimagined covers the
//  bench because in survival there is nothing to build on it; now that the riot
//  shield is registered here, the cover has to come off or the bench is hidden
//  under a sheet you can still use.
//
//  Kept for the case where the shield is NOT enabled - zgrief - so that mode
//  still gets Reimagined's covered bench rather than a bare one that does
//  nothing.
//
//  🛑 THE GATE IS RE-STATED HERE, NOT CALLED. Calling
//  scripts\zm\zm_transit\zm_transit::zmqol_diner_shield_enabled() would be a
//  reference from a locs\ file - which is loaded broadly - into a map-scoped
//  one, and GSC resolves that at SCRIPT LOAD time: "Unresolved external" on
//  every map that is not TranZit, with no runtime guard able to prevent it
//  (AI_CONTEXT rule 2). It reads the same two dvars in the same order, and both
//  copies carry this note so a change to one is a change to both.
//
//  Only ONE tarp is spawned in this whole file, so there is nothing else this
//  affects.
// ============================================================================
generatebuildabletarps()
{
	// twin of zm_transit.gsc / zm_transit.csc :: zmqol_diner_shield_enabled()
	if ( getdvar( "ui_zm_mapstartlocation" ) == "diner" && getdvar( "ui_gametype" ) != "zgrief" )
		return;

	tarp = spawn("script_model", (-4688, -7974, -64));
	tarp.angles = (0, 0, 0);
	tarp setModel("p6_zm_buildable_bench_tarp");
}

disable_zombie_spawn_locations()
{
	for (z = 0; z < level.zone_keys.size; z++)
	{
		zone = level.zones[level.zone_keys[z]];

		i = 0;

		while (i < zone.spawn_locations.size)
		{
			if (zone.spawn_locations[i].targetname == "zone_trans_diner_spawners")
			{
				zone.spawn_locations[i].is_enabled = false;
			}
			else if (zone.spawn_locations[i].targetname == "zone_trans_diner2_spawners")
			{
				zone.spawn_locations[i].is_enabled = false;
			}
			else if (zone.spawn_locations[i].origin == (-3825, -6576, -52.7))
			{
				zone.spawn_locations[i].is_enabled = false;
			}
			else if (zone.spawn_locations[i].origin == (-5130, -6512, -35.4))
			{
				zone.spawn_locations[i].is_enabled = false;
			}
			else if (zone.spawn_locations[i].origin == (-6462, -7159, -64))
			{
				zone.spawn_locations[i].is_enabled = false;
			}
			else if (zone.spawn_locations[i].origin == (-6531, -6613, -54.4))
			{
				zone.spawn_locations[i].is_enabled = false;
			}
			// zm_qol 2026-08-09: 🛑 THE "ZOMBIE HOPS THROUGH A FULLY BOARDED WINDOW" BUG.
			//
			// These two are zone_diner_roof's ONLY regular-zombie spawners, and both sit
			// on the GROUND ~220 units SOUTH of the diner's window line (the barriers are
			// at y = -8035; the diner interior is north of them). Reimagined never hit
			// this because it disables zone_diner_roof outright; this project deliberately
			// keeps that zone enabled so the roof is tracked for the Pack-a-Punch climb
			// (see main() above), which switched these two back on.
			//
			// Why they let a zombie walk through six intact planks - every link measured,
			// not inferred:
			//   1. both carry script_string "find_flesh"  (zm_transit mapents)
			//   2. _zm_spawner::should_skip_teardown() returns TRUE for exactly that
			//      string, so zombie_think() takes the early-return branch and NEVER
			//      calls tear_into_building() - no boards, no attack spot, no teardown
			//   3. they free-path with find_flesh() instead, and the diner barrier carries
			//      a node_negotiation_begin with animscript "zm_mantle_over_40"
			//   4. _zm_blockers::blocker_disconnect_paths() - the one thing that would
			//      close that path while boards are up - is an EMPTY STUB. Confirmed by
			//      decompiling the shipped patch_zm.ff copy, not just the gsc-dump.
			// So the mantle node is always live and the shortest route from spawn to a
			// player inside is straight over the window. Exactly "hopped over straight
			// through this barrier while all 6 planks were built".
			//
			// 🌟 Disabling these two is complete and side-effect free: the zone's other
			// three spawners are tagged dog_location / avogadro_location, which
			// _zm_zonemgr.gsc:227-248 files into zone.dog_locations / .avogadro_locations
			// and NEVER into zone.spawn_locations. This loop only walks spawn_locations,
			// so hellhounds and the Avogadro are untouched and the roof loses nothing -
			// it never had a regular-zombie spawner up there to begin with.
			else if (zone.spawn_locations[i].origin == (-5756.5, -8254, -0.86))
			{
				zone.spawn_locations[i].is_enabled = false;
			}
			else if (zone.spawn_locations[i].origin == (-6171.5, -8270, -4.39))
			{
				zone.spawn_locations[i].is_enabled = false;
			}

			i++;
		}

		// ====================================================================
		//  zm_qol v1.99.90 - HELLHOUNDS SPAWNED OUTSIDE THE ARENA (queue: user,
		//  2026-08-20, screenshot: a dog on the wrecked truck north of the diner,
		//  player at (-4935,-6885)).
		//
		//  🛑 THE LOOP ABOVE IS ONLY HALF THE JOB, and the comment further up this
		//  file says so without following it through: _zm_zonemgr.gsc:214-248 files
		//  a struct tagged "dog_location" / "screecher_location" /
		//  "avogadro_location" into zone.dog_locations / .screecher_locations /
		//  .avogadro_locations and NEVER into zone.spawn_locations. So every
		//  spawner this location script disabled above stayed live for hellhounds.
		//
		//  The path, verified end to end:
		//    1. _zm_zonemgr::create_spawner_list() (:944-976) rebuilds
		//       level.enemy_dog_locations EVERY SECOND from zone.dog_locations of
		//       every zone that is enabled + active + spawning_allowed, honouring
		//       each struct's own .is_enabled - the same flag this loop writes.
		//    2. zm_transit.gsc:96 sets level.dog_spawn_func = dog_spawn_transit_logic,
		//       which picks a location 400-1150 units from EVERY player and, when
		//       none qualifies, falls back to dog_locs[0] with NO distance check.
		//    3. transit_zone_init() connects zone_trans_diner to zone_roadside_west
		//       and zone_gas on flag "always_on" (:1571-1573), so in Diner survival
		//       that zone is enabled and goes active the moment a player stands in
		//       the arena - handing 6 dog locations 1,000-1,400 units up the road.
		//
		//  Which structs come off, and why each one is out of the arena:
		//    - the whole zone_trans_diner / zone_trans_diner2 groups: this same
		//      function already declares them out of bounds for regular zombies by
		//      disabling every spawn/riser struct they own. Nothing else in the
		//      arena spawns there.
		//    - three dog structs sitting on top of a riser this function disables
		//      by origin. MEASURED, not assumed - each is 127-196 units from its
		//      disabled riser, while the next nearest disabled riser is >500:
		//        (-5272,-6400,-35.4)  is 181u from (-5130,-6512,-35.4)
		//        (-4013,-6521,-41.9)  is 196u from (-3825,-6576,-52.7)
		//        (-6550,-7250,-36)    is 127u from (-6462,-7159,-64)
		//
		//  🌟 12 dog locations remain enabled across zone_din, zone_diner_roof,
		//  zone_gar, zone_gas, zone_roadside_east and zone_roadside_west, so the
		//  list can never empty out - an empty level.enemy_dog_locations would make
		//  dog_spawn_transit_logic return undefined and hang the dog round.
		//
		//  🛑 DELIBERATELY DINER-ONLY. The obvious general rule - "a zone with no
		//  enabled zombie spawners may not spawn dogs" - was checked against the
		//  mapents of every dog-capable map and it is WRONG: 8 of Nuketown's 16
		//  zones (garage, alleys, truck, start) carry dog locations and no regular
		//  spawner at all, by design. Applying it globally would have deleted most
		//  of Nuketown's hellhound spawns.
		// ====================================================================
		zmqol_disable_out_of_arena_ai_locations( zone.dog_locations );
		zmqol_disable_out_of_arena_ai_locations( zone.screecher_locations );
		zmqol_disable_out_of_arena_ai_locations( zone.avogadro_locations );
	}

	//  v2.2.0 - AFTER the pruning above, so the snapshot it takes can only hold
	//  in-arena locations. See the banner over zmqol_diner_dog_init().
	zmqol_diner_dog_init();
}

//  Structs are references in GSC, so writing .is_enabled through a copied array
//  still flags the one struct create_spawner_list() reads.
zmqol_disable_out_of_arena_ai_locations( a_locs )
{
	if ( !isdefined( a_locs ) )
		return;

	for ( i = 0; i < a_locs.size; i++ )
	{
		if ( a_locs[i].targetname == "zone_trans_diner_spawners" )
		{
			a_locs[i].is_enabled = false;
		}
		else if ( a_locs[i].targetname == "zone_trans_diner2_spawners" )
		{
			a_locs[i].is_enabled = false;
		}
		else if ( a_locs[i].origin == (-5272, -6400, -35.4) )
		{
			a_locs[i].is_enabled = false;
		}
		else if ( a_locs[i].origin == (-4013, -6521, -41.9) )
		{
			a_locs[i].is_enabled = false;
		}
		else if ( a_locs[i].origin == (-6550, -7250, -36) )
		{
			a_locs[i].is_enabled = false;
		}
	}
}

// ============================================================================
//  DINER HELLHOUNDS  -  A DOG THAT NEVER ARRIVES                    (v2.2.0)
// ----------------------------------------------------------------------------
//  User, 2026-08-21, round 19 of Diner survival: *"the final hell hound spawned
//  god knows where, outside of the playable map of Diner obviously, couldn't
//  even hear the sound of it or anything... make sure that the spawns of the
//  hell hounds aren't bugged at all and work properly for Diner Survival, and
//  they spawn in the map all the time."*
//
//  🛑 v1.99.90 PRUNED THE SPAWN LIST AND THAT WAS ONLY HALF THE STORY. The dog
//  the user could not find was almost certainly not at a bad LOCATION - it was
//  at the world origin, hidden, with ignoreme still set. Here is the whole
//  chain, every link read out of the stock dump:
//
//    1. Diner survival has exactly ONE dog spawner and it is at (0, 0, 0).
//       `so_zsurvival_zm_transit.addonmapents` carries one actor_zombie_dog with
//       script_noteworthy "zombie_dog_spawner" at origin "0 0 0", and the BASE
//       zm_transit mapents carries NONE - grep returns zero. So
//       level.dog_spawners has one entry, sitting at the map origin.
//
//    2. Stock spawns every dog THERE and teleports it afterwards.
//       _zm_ai_dogs::dog_round_spawning() (:135-141):
//             spawn_loc = [[ level.dog_spawn_func ]]( ... );
//             ai        = spawn_zombie( level.dog_spawners[0] );      <- at 0,0,0
//             spawn_loc thread dog_spawn_fx( ai, spawn_loc );
//       and dog_spawn_fx() is what does `ai forceteleport( ent.origin, angles )`,
//       `ai show()` and `ai.ignoreme = 0` - in that order, at the END.
//
//    3. So if dog_spawn_fx never completes, the dog stays at (0, 0, 0), STILL
//       HIDDEN and STILL ignoring the player. Invisible, silent, unkillable,
//       and the round can never end. That is exactly what was reported.
//
//    4. The way it fails is stock's own fallback. dog_spawn_transit_logic()
//       (zm_transit.gsc:2906) ends with `return dog_locs[0]` where dog_locs is
//       level.enemy_dog_locations - and that list is REBUILT EVERY SECOND by
//       _zm_zonemgr::create_spawner_list() from the zones that are enabled AND
//       active AND spawning_allowed. If it is momentarily empty, dog_locs[0] is
//       undefined, `spawn_loc thread dog_spawn_fx(...)` throws on an undefined
//       entity, and the thread dies before the teleport.
//
//  🌟 THE FIX IS IN TWO PARTS, AND THE SECOND ONE IS THE POINT.
//    (a) level.dog_spawn_func is a POINTER, so this location script simply owns
//        it. zmqol_dog_spawn_diner_logic() is stock's own transit logic with the
//        one hole closed: it can never return undefined, because it falls back
//        to a snapshot of the arena's dog locations taken at init.
//    (b) A per-dog WATCHDOG, because (a) only fixes the failure mode that can be
//        named. Anything else inside dog_spawn_fx - a missing fx handle, an
//        undefined favoriteenemy at the wrong moment - lands the dog in the same
//        state, and the watchdog does not care which: if a dog is still sitting
//        within 64 units of its spawner 4 seconds after it spawned, it is put
//        where it should have gone, shown, and un-ignored.
//
//  🛑 DELIBERATELY DINER-ONLY, like the v1.99.90 pruning above it. This is
//  called from this location script and nothing else, so no other map's dog
//  rounds are touched.
//
//  📝 The roof spawns are LEFT ALONE. Two of the arena's dog locations sit on
//  the diner roof at z 242.3 (zone_diner_roof_spawners); they are Treyarch's
//  own, they are inside the arena, and there is no evidence they are bad. If a
//  dog ever does get stuck up there the watchdog will not catch it - it only
//  catches dogs that never left the spawner - so that would be a separate fix.
// ============================================================================
zmqol_diner_dog_init()
{
    //  Snapshot the arena's dog locations AFTER the pruning pass above has run,
    //  so the fallback list can only contain in-arena spots.
    level.zmqol_diner_dog_locs = [];

    for ( z = 0; z < level.zone_keys.size; z++ )
    {
        zone = level.zones[level.zone_keys[z]];

        if ( !isdefined( zone ) || !isdefined( zone.dog_locations ) )
            continue;

        //  ====================================================================
        //  🛑 v2.2.6 - THE SNAPSHOT WAS NOT AN ARENA SNAPSHOT AT ALL, AND THE
        //  LOG SAID SO IN ONE NUMBER.
        //
        //  The banner above claims "12 dog locations remain enabled". The
        //  user's console_zm.log from the 49-minute Diner run prints
        //        [zm_qol] diner dogs: 97 in-arena dog location(s) snapshotted
        //  Ninety-seven, out of the 162 dog_location structs in the whole of
        //  zm_transit's mapents. So this loop was collecting dog locations from
        //  EVERY zone in TranZit - the town, the farm, the power station - and
        //  calling them "in-arena".
        //
        //  🌟 THE CAUSE IS ONE MISSING TEST, AND STOCK SPELLS OUT WHICH.
        //  _zm_zonemgr::create_spawner_list() builds level.enemy_dog_locations
        //  with TWO gates:
        //        if ( zone.is_enabled && zone.is_active && zone.is_spawning_allowed )
        //            ... if ( zone.dog_locations[x].is_enabled )
        //  This loop only ever applied the second one. zone.is_enabled is what
        //  says a zone is part of the arena, and it was never read - so
        //  zmqol_disable_out_of_arena_ai_locations()'s per-struct flags were
        //  doing all the work, and they only cover five specific entries.
        //
        //  The fallback below is used whenever level.enemy_dog_locations is
        //  momentarily empty, and it picks from this list AT RANDOM. With 97
        //  entries spread across the whole map, that fallback could teleport a
        //  hellhound a mile up the road, outside the Diner arena, with no
        //  player anywhere near it - which is the shape of every "the dog
        //  spawned god knows where" report this file already carries.
        //
        //  📝 is_active / is_spawning_allowed are deliberately NOT part of the
        //  test here. They are per-round state that flips while the match runs;
        //  this snapshot is taken once at init and is a LAST-RESORT list, so it
        //  must not be empty just because a zone happened to be quiet at init.
        //  is_enabled is the one that means "part of this arena", and it is the
        //  one this was missing.
        //  ====================================================================
        if ( isdefined( zone.is_enabled ) && !zone.is_enabled )
            continue;
        for ( i = 0; i < zone.dog_locations.size; i++ )
        {
            s_loc = zone.dog_locations[i];

            if ( !isdefined( s_loc ) || !isdefined( s_loc.origin ) )
                continue;

            //  is_enabled is what the pruning pass writes; honour it here so a
            //  struct this file just switched off cannot come back as a
            //  fallback.
            if ( isdefined( s_loc.is_enabled ) && !s_loc.is_enabled )
                continue;

            level.zmqol_diner_dog_locs[level.zmqol_diner_dog_locs.size] = s_loc;
        }
    }

    println( "[zm_qol] diner dogs: " + level.zmqol_diner_dog_locs.size + " in-arena dog location(s) snapshotted" );

    //  🛑 ONLY TAKE THE POINTER IF THERE IS SOMETHING TO FALL BACK ON. With an
    //  empty snapshot this function would be strictly worse than stock's.
    if ( level.zmqol_diner_dog_locs.size > 0 )
        level.dog_spawn_func = ::zmqol_dog_spawn_diner_logic;

    level thread zmqol_diner_dog_watchdog();
    level thread zmqol_diner_dog_garage_watchdog();
}

//  Stock's dog_spawn_transit_logic(), with the undefined return closed off.
//  The 160000 / 1322500 bounds are stock's own (400 and 1150 units squared).
zmqol_dog_spawn_diner_logic( dog_array, favorite_enemy )
{
    dog_locs = array_randomize( level.enemy_dog_locations );

    for ( i = 0; i < dog_locs.size; i++ )
    {
        if ( isdefined( level.old_dog_spawn ) && level.old_dog_spawn == dog_locs[i] )
            continue;

        canuse = 1;
        players = get_players();

        foreach ( player in players )
        {
            if ( !canuse )
                continue;

            dist_squared = distancesquared( dog_locs[i].origin, player.origin );

            if ( dist_squared < 160000 || dist_squared > 1322500 )
                canuse = 0;
        }

        if ( canuse )
        {
            level.old_dog_spawn = dog_locs[i];
            return dog_locs[i];
        }
    }

    //  Stock's own fallback, guarded.
    if ( dog_locs.size > 0 && isdefined( dog_locs[0] ) )
    {
        level.old_dog_spawn = dog_locs[0];
        return dog_locs[0];
    }

    //  🛑 THE HOLE STOCK LEAVES OPEN. Reached when level.enemy_dog_locations is
    //  momentarily empty; stock returns undefined here and the dog is stranded
    //  at the spawner. The snapshot is built from the same structs, so this is
    //  still a real in-arena spot.
    s_fallback = level.zmqol_diner_dog_locs[randomint( level.zmqol_diner_dog_locs.size )];
    level.old_dog_spawn = s_fallback;
    println( "[zm_qol] diner dogs: enemy_dog_locations was EMPTY - used the snapshot fallback" );
    return s_fallback;
}

//  Catches a dog that never got teleported, whatever the reason.
zmqol_diner_dog_watchdog()
{
    level endon( "end_game" );
    level endon( "intermission" );

    v_spawner = ( 0, 0, 0 );

    if ( isdefined( level.dog_spawners ) && level.dog_spawners.size > 0 && isdefined( level.dog_spawners[0] ) )
        v_spawner = level.dog_spawners[0].origin;

    for ( ;; )
    {
        wait 1;

        if ( !isdefined( level.zmqol_diner_dog_locs ) || level.zmqol_diner_dog_locs.size == 0 )
            continue;

        a_ai = getaiarray( level.zombie_team );

        for ( i = 0; i < a_ai.size; i++ )
        {
            ai = a_ai[i];

            if ( !isdefined( ai ) || !isalive( ai ) )
                continue;

            if ( !( isdefined( ai.isdog ) && ai.isdog ) )
                continue;

            //  First sighting: remember when, and move on. dog_spawn_fx takes
            //  1.5s of its own before it teleports, so nothing is judged early.
            if ( !isdefined( ai.zmqol_dog_seen ) )
            {
                ai.zmqol_dog_seen = gettime();
                continue;
            }

            if ( gettime() - ai.zmqol_dog_seen < 4000 )
                continue;

            //  ================================================================
            //  🌟 v2.2.5 - THE DOG THAT COULD NOT BE KILLED AND IGNORED THE
            //  PLAYER. This runs BEFORE the stranded check below, because the
            //  dog it is for is not stranded - it is up and running around.
            //
            //  User, 2026-08-22, Diner survival round 7: *"one of the dogs was
            //  running through the lifted up car in the garage and through
            //  building, and it kinda just ignored me... I just now killed all
            //  the dogs except that one dog that ran through the wall outside
            //  the map, unable to progress the game now without the use of
            //  cheats."*
            //
            //  🛑 STOCK'S OWN SPAWN THREAD HAS NO ERROR PATH, AND ITS FIRST
            //  LINE IS THE ONE THAT THROWS. _zm_ai_dogs::dog_spawn_fx() runs,
            //  in this exact order (:197-222):
            //        angle = vectortoangles( ai.favoriteenemy.origin - ... )
            //        ai forceteleport( ent.origin, angles )
            //        ai zombie_setup_attack_properties_dog()
            //        ai stop_magic_bullet_shield()
            //        ai show()
            //        ai setfreecameralockonallowed( 1 )
            //        ai.ignoreme = 0
            //  Every dog is spawned WITH a magic bullet shield - i.e. immune to
            //  damage - and with ignoreme set, and that thread is the only
            //  thing that takes either off. Plutonium kills a GSC thread that
            //  throws in silence, so if ANY line above fails, whatever came
            //  after it never runs and the dog keeps the state it was born
            //  with: invulnerable, uninterested in the player, and with none of
            //  its attack properties set. That is the whole of the user's
            //  report - a dog that runs about, ignores you and cannot be shot.
            //
            //  🌟 THE WATCHDOG DOES NOT CARE WHICH LINE FAILED. It re-asserts
            //  the end state stock was trying to reach, field for field, and it
            //  only touches what is actually still wrong.
            //
            //  📝 THE FIVE ATTACK-PROPERTY FIELDS ARE SET INLINE RATHER THAN BY
            //  CALLING zombie_setup_attack_properties_dog(), because they are
            //  the whole of its body (_zm_ai_dogs.gsc:532-540) minus a
            //  developer-only history ring. dog_behind_audio() - the dog's
            //  growl loop, and the reason an earlier stranded dog could not be
            //  heard - IS started, by name, because it has no inline
            //  equivalent.
            //  🛑 THE CROSS-FILE REFERENCE IS SAFE FROM THIS FILE, CHECKED NOT
            //  ASSUMED: locs\ scripts load on EVERY map, so an external here
            //  must resolve everywhere or every other map dies at load
            //  (AI_CONTEXT rule 2). console_zm.log's script list reports
            //  "_zm_ai_dogs.gsc (patch_zm)" - patch_zm is the global zombies
            //  patch, loaded on all six maps, same as _zm_utility.
            //  ================================================================
            if ( !isdefined( ai.zmqol_dog_state_fixed ) )
            {
                ai.zmqol_dog_state_fixed = 1;
                str_fixed = "";

                //  is_magic_bullet_shield_enabled() is exactly this test
                //  (_zm_utility.gsc:2784), inlined for the same reason.
                if ( isdefined( ai.magic_bullet_shield ) && ai.magic_bullet_shield == 1 )
                {
                    ai maps\mp\zombies\_zm_utility::stop_magic_bullet_shield();
                    str_fixed = str_fixed + " unkillable";
                }

                if ( isdefined( ai.ignoreme ) && ai.ignoreme )
                {
                    ai.ignoreme = 0;
                    str_fixed = str_fixed + " ignoreme";
                }

                //  🛑 THE PROPERTIES AND THE AUDIO ARE ONLY TOUCHED IF
                //  zombie_setup_attack_properties_dog() PROVABLY DID NOT RUN.
                //  Its last two writes are disablearrivals/disableexits = 1,
                //  and nothing else in the dog path sets them, so
                //  disablearrivals is a reliable "did that function complete"
                //  flag. This test is the whole reason the growl thread cannot
                //  be started twice: starting a second dog_behind_audio() on a
                //  healthy dog would double every growl it makes, which is a
                //  worse bug than the one being fixed.
                if ( !( isdefined( ai.disablearrivals ) && ai.disablearrivals ) )
                {
                    //  zombie_setup_attack_properties_dog(), inline.
                    ai.ignoreall          = 0;
                    ai.pathenemyfightdist = 64;
                    ai.meleeattackdist    = 64;
                    ai.disablearrivals    = 1;
                    ai.disableexits       = 1;

                    ai thread maps\mp\zombies\_zm_ai_dogs::dog_behind_audio();
                    str_fixed = str_fixed + " attack-properties+audio";
                }

                ai show();
                ai setfreecameralockonallowed( 1 );

                if ( str_fixed != "" )
                    println( "[zm_qol] diner dogs: a dog was still in its pre-spawn state after 4s -" + str_fixed + " - stock's dog_spawn_fx did not finish. Repaired." );
            }

            //  ================================================================
            //  🌟 v2.3.2 - THE LAST-ZOMBIE TIMEOUT. THE ROUND CAN NO LONGER HANG
            //  ON ONE UNREACHABLE DOG, WHATEVER THE REASON.
            //
            //  User, 2026-08-25, Diner survival round 7: the last hellhound of a
            //  dog round ran outside the map and the round could not progress -
            //  the exact class of failure the v2.2.6 containment below was built
            //  for, except this time it never fired. Read from that session's own
            //  console_zm.log, not guessed: "[zm_qol] diner dogs: 71 in-arena dog
            //  location(s) snapshotted" is the ONLY diner-dogs line in the whole
            //  log - neither "RUNAWAY DOG" nor "STRANDED DOG" ever printed, so
            //  whatever went wrong was invisible to both existing tests. Two ways
            //  that happens without contradicting either one: the dog stayed
            //  within the containment check's 2500-unit straight-line distance of
            //  a player despite being behind unreachable geometry (b_far below
            //  never goes 1), or it ended up standing in a zone
            //  _zm_zonemgr still calls "enabled" even though it is not part of
            //  this arena's walkable space (that check's definition of "in
            //  bounds" is broader than "reachable").
            //
            //  🌟 THIS DOES NOT TRY TO NAME WHICH. It is a hard backstop on the
            //  one fact that is always true when the round is hung: exactly one
            //  zombie-team AI is left and it has stayed that way, alive, for a
            //  long time. Nothing about a healthy dog round holds "1 AI left" for
            //  20+ seconds - the player kills it in a few seconds, or the
            //  containment/rescue logic already catches it. Past that timeout
            //  this fires unconditionally, no distance test and no zone test,
            //  because both are exactly what already failed to catch this once.
            //  a_ai is this tick's own getaiarray( level.zombie_team ) snapshot,
            //  so its size needs no extra call.
            //  ================================================================
            if ( a_ai.size == 1 )
            {
                if ( !isdefined( ai.zmqol_dog_lastone_since ) )
                    ai.zmqol_dog_lastone_since = gettime();

                if ( !isdefined( ai.zmqol_dog_lastone_rescued ) && gettime() - ai.zmqol_dog_lastone_since >= 20000 )
                {
                    ai.zmqol_dog_lastone_rescued = 1;

                    s_home   = level.zmqol_diner_dog_locs[randomint( level.zmqol_diner_dog_locs.size )];
                    players  = get_players();
                    v_angles = ai.angles;

                    if ( players.size > 0 )
                    {
                        e_target = players[randomint( players.size )];

                        if ( isdefined( e_target ) )
                        {
                            v_face   = vectortoangles( e_target.origin - s_home.origin );
                            v_angles = ( ai.angles[0], v_face[1], ai.angles[2] );
                        }
                    }

                    ai forceteleport( s_home.origin, v_angles );

                    //  Re-assert the whole of dog_spawn_fx()'s end state, same as
                    //  the two rescues below - it may be stuck for the same
                    //  reason it never finished spawning correctly.
                    if ( isdefined( ai.magic_bullet_shield ) && ai.magic_bullet_shield == 1 )
                        ai maps\mp\zombies\_zm_utility::stop_magic_bullet_shield();

                    ai show();
                    ai setfreecameralockonallowed( 1 );
                    ai.ignoreme            = 0;
                    ai.ignoreall           = 0;
                    ai.zmqol_dog_far_ticks = 0;
                    ai notify( "visible" );

                    println( "[zm_qol] diner dogs: LAST ZOMBIE TIMEOUT - sole remaining dog had not ended the round in 20s, force-returned to (" + int( s_home.origin[0] ) + "," + int( s_home.origin[1] ) + "," + int( s_home.origin[2] ) + ")" );
                }
            }
            else
            {
                ai.zmqol_dog_lastone_since   = undefined;
                ai.zmqol_dog_lastone_rescued = undefined;
            }

            //  ================================================================
            //  🌟 v2.2.6 - CONTAINMENT: A DOG THAT LEAVES THE ARENA IS BROUGHT
            //  BACK. THE ROUND CAN NO LONGER BE LOST TO ONE RUNAWAY.
            //
            //  User, 2026-08-23, Diner survival: *"it spawned in front of the
            //  slightly open garage door where the zombies and the player can
            //  crawl/prone under, and the dog just went straight through the
            //  door and then continued to go through the lifted car itself as
            //  well, totally glitched and then it ignored me (the player) and
            //  then went through the back wall out of the map, running
            //  indefinitely outside of the map/playable area causing that match
            //  to be ruined."*
            //
            //  🛑 WHY THE v2.2.5 REPAIR ABOVE DID NOT COVER THIS, STATED
            //  HONESTLY. That repair fixes a dog whose dog_spawn_fx() thread
            //  died - unkillable, ignoreme, no attack properties. It printed
            //  NOTHING in the 49-minute run's console_zm.log, so on the
            //  evidence available every dog in that match reached its correct
            //  end state and this was a different fault. Walking through a
            //  closed garage door, through a car and out through a wall is what
            //  a T6 actor does when it has no usable path and simply steers at
            //  its goal: actors are moved by the path graph, not by brush
            //  collision. Which node graph failed, and why, is NOT established
            //  offline - the garage door is a crawl-under traverse that dogs do
            //  not use, which is a plausible cause and is not proof.
            //
            //  🌟 SO THIS DOES NOT TRY TO NAME THE CAUSE. It catches the state:
            //  a dog that is nowhere near a player AND is standing in no
            //  enabled zone is, by the game's own definition of the arena, out
            //  of the map. It gets put back on a real dog location with its
            //  full spawn state re-asserted, and the round can finish.
            //
            //  -- THE TWO TESTS, AND WHY THOSE TESTS --------------------------
            //    1. distance. Stock's own dog_spawn_transit_logic() refuses any
            //       spawn location further than 1150 units from a player
            //       (dist_squared > 1322500). A dog more than 2500 units from
            //       EVERY player is therefore far outside anything stock would
            //       ever have placed it in, with generous headroom for a chase.
            //       This is only a cheap pre-filter so the zone test below runs
            //       on almost nothing.
            //    2. the zone. _zm_zonemgr::get_zone_from_position() returns
            //       undefined when a position is inside no ENABLED zone - it is
            //       stock's own "is this spot part of the arena" question, and
            //       it is what actually authorises the teleport. It spawns and
            //       deletes a script_origin per call, which is why it is gated
            //       behind test 1 and behind five consecutive seconds.
            //
            //  📝 FIVE CONSECUTIVE SECONDS, not one. A dog crossing a gap
            //  between zone volumes for a frame must never be teleported; the
            //  counter is reset the moment the dog is near a player again.
            //  📝 maps\mp\zombies\_zm_zonemgr is core zombies and loads on every
            //  map, so referencing it from locs\ - which loads everywhere - is
            //  safe (AI_CONTEXT rule 2).
            //  ================================================================
            b_far = 1;

            foreach ( player in get_players() )
            {
                if ( isdefined( player ) && distancesquared( ai.origin, player.origin ) < 6250000 )   //  2500 units
                    b_far = 0;
            }

            if ( !b_far )
            {
                ai.zmqol_dog_far_ticks = 0;
            }
            else
            {
                if ( !isdefined( ai.zmqol_dog_far_ticks ) )
                    ai.zmqol_dog_far_ticks = 0;

                ai.zmqol_dog_far_ticks++;

                if ( ai.zmqol_dog_far_ticks >= 5 )
                {
                    ai.zmqol_dog_far_ticks = 0;

                    if ( !isdefined( maps\mp\zombies\_zm_zonemgr::get_zone_from_position( ai.origin ) ) )
                    {
                        s_home = level.zmqol_diner_dog_locs[randomint( level.zmqol_diner_dog_locs.size )];

                        v_angles = ai.angles;

                        if ( isdefined( ai.favoriteenemy ) && isdefined( ai.favoriteenemy.origin ) )
                        {
                            v_face   = vectortoangles( ai.favoriteenemy.origin - s_home.origin );
                            v_angles = ( ai.angles[0], v_face[1], ai.angles[2] );
                        }

                        ai forceteleport( s_home.origin, v_angles );

                        //  Re-assert the whole of dog_spawn_fx()'s end state, in
                        //  stock's order, because a dog that got out there may
                        //  have got out there BECAUSE part of it never ran.
                        if ( isdefined( ai.magic_bullet_shield ) && ai.magic_bullet_shield == 1 )
                            ai maps\mp\zombies\_zm_utility::stop_magic_bullet_shield();

                        ai show();
                        ai setfreecameralockonallowed( 1 );
                        ai.ignoreme  = 0;
                        ai.ignoreall = 0;
                        ai notify( "visible" );

                        println( "[zm_qol] diner dogs: RUNAWAY DOG was in no enabled zone and " + int( distance( ai.origin, s_home.origin ) ) + " units out - returned to (" + int( s_home.origin[0] ) + "," + int( s_home.origin[1] ) + "," + int( s_home.origin[2] ) + ")" );
                    }
                }
            }
            //  Already rescued once - do not fight the stock thread if it is
            //  simply slow.
            if ( isdefined( ai.zmqol_dog_rescued ) )
                continue;

            if ( distancesquared( ai.origin, v_spawner ) > 4096 )     //  64 units
                continue;

            ai.zmqol_dog_rescued = 1;

            s_loc = level.zmqol_diner_dog_locs[randomint( level.zmqol_diner_dog_locs.size )];

            //  The tail of stock's own dog_spawn_fx(), in stock's order.
            v_angles = ai.angles;

            if ( isdefined( ai.favoriteenemy ) && isdefined( ai.favoriteenemy.origin ) )
            {
                v_face = vectortoangles( ai.favoriteenemy.origin - s_loc.origin );
                v_angles = ( ai.angles[0], v_face[1], ai.angles[2] );
            }

            ai forceteleport( s_loc.origin, v_angles );
            ai show();
            ai.ignoreme = 0;
            ai notify( "visible" );

            println( "[zm_qol] diner dogs: STRANDED DOG rescued to (" + int( s_loc.origin[0] ) + "," + int( s_loc.origin[1] ) + "," + int( s_loc.origin[2] ) + ")" );
        }
    }
}

// ============================================================================
//  🌟 v2.3.2 - THE GARAGE DOOR CHOKE POINT, CLOSED AT THE ACTUAL SPOT NOW.
//
//  User, 2026-08-25, with a screenshot pinpointing it: hellhounds on Diner
//  keep going "straight through the garage door" and out of the map, on every
//  dog round, not as a one-off. The v2.2.6 containment above (§ this file)
//  only rescues a dog AFTER it is 2500+ units from every player and standing
//  in no enabled zone for 5 straight seconds - it was never meant to, and
//  cannot, stop the glitch from starting, only clean up after it.
//
//  🌟 THE EXACT SPOT IS MEASURED, NOT GUESSED. Dumped `zm_transit.d3dbsp`'s
//  mapents with the Unlinker and grepped for the garage: TWO
//  `node_negotiation_begin`/`_end` pairs sit right where the screenshot
//  points -
//    `animscript "zm_traverse_garage_door"` - (-4468.7,-7453.4,-36) to
//        (-4469,-7523.5,-36), and the reverse pair back
//    `animscript "zm_traverse_car_reverse"` (the "lifted car" from the
//        2026-08-23 report, same garage) - (-4556.32,-7347.42,-36) to
//        (-4695.84,-7345,-36)
//  Both are humanoid crawl/mantle animations. Hellhounds run `zm_dog_move` /
//  `dog_move`, which has no such animation - so when a dog's pathing solver
//  picks one of these nodes anyway, there is nothing to play, and the actor
//  just keeps travelling along the path spline in a straight line with no
//  animation asserting the crouch, straight through the closed brush. This
//  confirms, rather than merely suspects, what the v2.2.6 comment already
//  flagged as "a plausible cause, not proof" for the door - and the
//  car-reverse node explains the OLDER "through the lifted car" report the
//  same way.
//
//  🛑 THERE IS NO CONFIRMED GSC-LEVEL WAY TO EXCLUDE ONE NEGOTIATION NODE
//  PER ACTOR TYPE. `_zm_blockers::blocker_disconnect_paths()` - the stock
//  function that would normally take a node pair out of the graph - is an
//  EMPTY STUB in this build (confirmed by decompiling patch_zm.ff, see the
//  zone_diner_roof comment earlier in this file), so there is no working
//  stock lever to pull here either.
//
//  🌟 SO THIS CATCHES THE ACTOR INSTEAD OF THE NODE. A dog's last known-good
//  position is tracked every tick it is OUTSIDE both corridors; the instant
//  one is found INSIDE either, it is forceteleported straight back to that
//  last-good spot with its spawn state re-asserted (same tail as the other
//  two rescues in this file), before it can finish crossing into the brush.
//  The box for each corridor is the two nodes' span plus 25-30 units of
//  padding on every side, so a dog is caught approaching, not just mid-clip.
//  Runs at 0.25s, faster than the 1s main watchdog above, because a
//  sprinting hellhound can cross either ~60-90 unit corridor in well under a
//  second.
// ============================================================================
zmqol_diner_pos_in_box( v_pos, v_min, v_max )
{
    return ( v_pos[0] >= v_min[0] && v_pos[0] <= v_max[0]
        && v_pos[1] >= v_min[1] && v_pos[1] <= v_max[1]
        && v_pos[2] >= v_min[2] && v_pos[2] <= v_max[2] );
}

zmqol_diner_dog_garage_watchdog()
{
    level endon( "end_game" );
    level endon( "intermission" );

    //  Car-reverse traverse span (-4556..-4696, -7290..-7347) padded 30 units.
    v_car_min = ( -4726, -7377, -80 );
    v_car_max = ( -4526, -7260,  40 );

    //  Garage-door traverse span (-4411..-4469, -7453..-7525) padded 30 units.
    v_door_min = ( -4499, -7555, -80 );
    v_door_max = ( -4381, -7423,  40 );

    for ( ;; )
    {
        wait 0.25;

        a_ai = getaiarray( level.zombie_team );

        for ( i = 0; i < a_ai.size; i++ )
        {
            ai = a_ai[i];

            if ( !isdefined( ai ) || !isalive( ai ) )
                continue;

            if ( !( isdefined( ai.isdog ) && ai.isdog ) )
                continue;

            b_inside = zmqol_diner_pos_in_box( ai.origin, v_car_min, v_car_max )
                || zmqol_diner_pos_in_box( ai.origin, v_door_min, v_door_max );

            if ( !b_inside )
            {
                ai.zmqol_dog_garage_safe_pos = ai.origin;
                continue;
            }

            if ( !isdefined( ai.zmqol_dog_garage_safe_pos ) )
            {
                //  Caught with no recorded safe spot (rescued or spawned
                //  straight into the corridor) - fall back to a real dog
                //  location rather than leaving it inside the box.
                ai.zmqol_dog_garage_safe_pos = level.zmqol_diner_dog_locs[randomint( level.zmqol_diner_dog_locs.size )].origin;
            }

            v_angles = ai.angles;

            if ( isdefined( ai.favoriteenemy ) && isdefined( ai.favoriteenemy.origin ) )
            {
                v_face   = vectortoangles( ai.favoriteenemy.origin - ai.zmqol_dog_garage_safe_pos );
                v_angles = ( ai.angles[0], v_face[1], ai.angles[2] );
            }

            ai forceteleport( ai.zmqol_dog_garage_safe_pos, v_angles );

            if ( isdefined( ai.magic_bullet_shield ) && ai.magic_bullet_shield == 1 )
                ai maps\mp\zombies\_zm_utility::stop_magic_bullet_shield();

            ai show();
            ai.ignoreme  = 0;
            ai.ignoreall = 0;
            ai notify( "visible" );

            println( "[zm_qol] diner dogs: GARAGE CHOKE POINT - dog turned back before it cleared (" + int( ai.origin[0] ) + "," + int( ai.origin[1] ) + "," + int( ai.origin[2] ) + ")" );
        }
    }
}

