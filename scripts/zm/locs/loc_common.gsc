#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include common_scripts\utility;

init()
{
	// zm_qol diagnostic marker. Every ported location script threads this from its
	// main(), so this line appearing in console_zm.log proves the location's precache
	// and main both completed. If a location crashes, the ABSENCE of this line is the
	// signal that it died earlier (precache / struct_init / main).
	println( "[zm_qol] loc_common::init reached - location=" + getdvar( "ui_zm_mapstartlocation" ) );

	// Do not rewrite live AI distances here. Origins survival removes its
	// barriers and the capture-zone replacement leaves find_flesh running.
	// The old one-second repair loop also changed undefined fields on healthy
	// zombies, which made ordinary attacks inconsistent.

	level.enemy_location_override_func = ::enemy_location_override;
	flag_wait("initial_blackscreen_passed");
	maps\mp\zombies\_zm_game_module::turn_power_on_and_open_doors();
	flag_wait("start_zombie_round_logic");
	wait 1;
	level notify("revive_on");
	wait_network_frame();
	level notify("doubletap_on");
	wait_network_frame();
	level notify("marathon_on");
	wait_network_frame();
	level notify("juggernog_on");
	wait_network_frame();
	level notify("sleight_on");
	wait_network_frame();
	level notify("tombstone_on");
	wait_network_frame();
	level notify("additionalprimaryweapon_on");
	wait_network_frame();
	level notify("Pack_A_Punch_on");
}

enemy_location_override(zombie, enemy)
{
	location = enemy.origin;

	if (is_true(self.reroute))
	{
		if (isDefined(self.reroute_origin))
		{
			location = self.reroute_origin;
		}
	}

	return location;
}

// ============================================================================
//  WALLBUYS ON NON-STOCK START LOCATIONS
// ----------------------------------------------------------------------------
//  Stock maps\mp\zombies\_zm_weapons::init_spawnable_weapon_upgrade() decides
//  which wallbuys exist by string-matching each wallbuy struct's
//  script_noteworthy against "<ui_gametype>_<start location>". A struct with NO
//  script_noteworthy always spawns; a tagged one spawns ONLY for the pairs it
//  lists.
//
//  Nothing in the stock maps tags the locations this mod adds, so a tagged
//  wallbuy standing in a new location's play area silently never appears. That
//  is the whole reason Diner survival had no wallbuys: the two that stand in the
//  diner - MP5K inside, Galvaknuckles on the roof - are tagged
//  "zclassic_transit" and nothing else.
//
//  Which maps this actually affects was checked, not assumed, by dumping every
//  map's entity list with OAT's Unlinker
//  (Unlinker.exe --include-assets mapents <map>.ff) and reading the
//  weapon_upgrade / bowie_upgrade / sickle_upgrade / tazer_upgrade /
//  claymore_purchase / buildable_wallbuy structs:
//
//    zm_highrise, zm_prison, zm_tomb - EVERY wallbuy is untagged, so Shopping
//        Mall, Dragon Rooftop, Sweatshop, Docks, Trenches, Excavation Site,
//        Church and The Crazy Place already get all of them. Nothing to do.
//    zm_transit - almost all tagged. Diner and Tunnel each have wallbuys of
//        their own that need re-tagging (below). Power's AK74u is untagged and
//        already works.
//    zm_buried - all tagged. Borough/street needs re-tagging.
//
//  Cornfield (TranZit) and Maze (Buried) have NO wallbuy struct anywhere in
//  their play area in the stock map, so there is nothing to enable - they are
//  magic-box-only by design. Reimagined does not add any there either.
//
//  ORDERING: this must be called from a location's struct_init(), which runs
//  inside struct_class_init() in _load::main(). _zm_weapons::init() runs later,
//  from _zm::main(). Re-tagging any later than struct_init is too late - the
//  spawn list has already been built and level._spawned_wallbuys is fixed.
//
//  🛑 THIS HAS A CLIENT-SIDE TWIN THAT MUST BE KEPT IN SYNC.
//  _zm_weapons registers a "world" clientfield per matching wallbuy on BOTH the
//  server (_zm_weapons.gsc) and the client (_zm_weapons.csc). Re-tagging here
//  only changes the server's count, so the two disagree and the engine drops
//  the connection with EXE_CLIENT_FIELD_MISMATCH before the map starts. Every
//  origin passed to this function must also appear in
//  scripts\zm\zm_expanded.csc::zmqol_enable_wallbuys(). A .csc cannot #include
//  a .gsc, so that list is necessarily a duplicate of the ones here.
// ============================================================================
enable_wallbuys( a_origins )
{
	str_match = wallbuy_match_string();

	// The same set init_spawnable_weapon_upgrade() gathers. Walked one
	// targetname at a time rather than arraycombine'd: arraycombine is not
	// defined in any stock script in the reference dump, so it is an engine
	// builtin, and there is no reason to depend on that here.
	a_targetnames = [];
	a_targetnames[a_targetnames.size] = "weapon_upgrade";
	a_targetnames[a_targetnames.size] = "bowie_upgrade";
	a_targetnames[a_targetnames.size] = "sickle_upgrade";
	a_targetnames[a_targetnames.size] = "tazer_upgrade";
	a_targetnames[a_targetnames.size] = "claymore_purchase";

	//  🛑 v2.10.10 - "buildable_wallbuy" IS DELIBERATELY NOT IN THIS LIST,
	//  even though init_spawnable_weapon_upgrade() gathers it. Those six structs
	//  are Buried's chalk-draw spots, and the prison one sits 8.1 units from
	//  Borough's Olympia (measured in the zm_buried mapents dump) - inside the
	//  16-unit radius below, so it was matched as a FOURTH struct for three
	//  requested origins. That is the "tagged 4 of 3 requested" line the
	//  2026-09-02 Borough boot log printed on both the server and the client.
	//
	//  What the stray tag did: stock's own spawn list then contained it, and
	//  clientscripts\mp\zombies\_zm_weapons.csc::wallbuy_player_connect plays
	//  level._effect["dynamic_wallbuy_fx"] (maps/zombie/fx_zmb_wall_buy_question)
	//  for any buildable_wallbuy in that list - the glowing "?" the user
	//  photographed sitting on top of the Olympia chalk drawing.
	//
	//  Tagging one could never HELP, either: the weapon is only ever drawn by
	//  builddynamicwallbuy(), which tests the TARGET struct's script_noteworthy
	//  ("zclassic_processing" on all six chalk spots, verified in the dump), not
	//  this struct's. So the tag bought a stray FX and two stray clientfields.

	n_tagged = 0;

	foreach ( str_targetname in a_targetnames )
	{
		a_structs = getstructarray( str_targetname, "targetname" );

		if ( !isdefined( a_structs ) )
			continue;

		foreach ( s_struct in a_structs )
		{
			if ( !isdefined( s_struct.origin ) )
				continue;

			foreach ( v_origin in a_origins )
			{
				// 16 units. The origins passed in are copied verbatim out of
				// the map ents dump, so this only has to absorb float printing
				// error, never "near enough" guessing.
				if ( distancesquared( s_struct.origin, v_origin ) > 256 )
					continue;

				// No tag already means "spawns everywhere" - leave it alone
				// rather than narrowing it.
				if ( isdefined( s_struct.script_noteworthy ) && s_struct.script_noteworthy != "" )
				{
					s_struct.script_noteworthy = s_struct.script_noteworthy + "," + str_match;
					n_tagged++;
				}

				break;
			}
		}
	}

	println( "[zm_qol] enable_wallbuys - " + str_match + ": tagged " + n_tagged + " of " + a_origins.size + " requested" );
}

// Rebuilds the exact match string init_spawnable_weapon_upgrade() will use.
// It reads level.scr_zm_ui_gametype / level.scr_zm_map_start_location, but
// _zm::main() has NOT assigned those yet when struct_init runs, so read the two
// dvars they are initialised from instead - same values, available earlier.
wallbuy_match_string()
{
	str_gametype = getdvar( "ui_gametype" );
	str_location = getdvar( "ui_zm_mapstartlocation" );

	if ( ( str_location == "default" || str_location == "" ) && isdefined( level.default_start_location ) )
		str_location = level.default_start_location;

	if ( str_location == "" )
		return str_gametype;

	return str_gametype + "_" + str_location;
}

increase_pap_collision()
{
	pap_triggers = getentarray("specialty_weapupgrade", "script_noteworthy");

	foreach (pap_trigger in pap_triggers)
	{
		if (isdefined(pap_trigger.clip))
		{
			move_amount = 8;

			if (isdefined(pap_trigger.machine) && pap_trigger.machine.model == "p6_zm_tm_packapunch")
			{
				move_amount = 12;
			}

			collision = spawn("script_model", pap_trigger.clip.origin + anglestoforward(pap_trigger.clip.angles) * move_amount * -1, 1);
			collision.angles = pap_trigger.clip.angles;
			collision setmodel("zm_collision_perks1");
			collision.script_noteworthy = "clip";
			collision disconnectpaths();
			pap_trigger.clip2 = collision;

			pap_trigger.clip.origin += anglestoforward(pap_trigger.clip.angles) * move_amount;
		}
	}
}

barrier(model, origin, angles, disconnect_paths = 0)
{
	barrier = undefined;

	if (disconnect_paths)
	{
		barrier = spawn("script_model", origin, 1);
	}
	else
	{
		barrier = spawn("script_model", origin);
	}

	barrier.angles = angles;
	barrier setModel(model);

	if (disconnect_paths)
	{
		barrier disconnectPaths();
	}
}
// ============================================================================
//  Buildable-stub swapping - used by zm_highrise_loc_sweatshop.
// ----------------------------------------------------------------------------
//  🛑 WHY THESE LIVE HERE instead of being called from the stock script:
//  Reimagined calls scripts\zm\replaced\_zm_buildables_pooled::swap_buildable_fields.
//  zm_qol does not port that file, because it #includes the stock module
//  maps\mp\zombies\_zm_buildables_pooled - and that module ships ONLY in Buried's
//  fastfile. Referencing it from a Die Rise script would be an unresolved
//  external and would crash the map (AI_CONTEXT rule 2).
//
//  Pointing at the stock function directly has the same problem, and stock's
//  version also does not swap .cost. So the three functions are carried here
//  verbatim from Reimagined instead. They call only engine builtins (getent,
//  anglesTo*, worldtolocalcoords, localtoworldcoords), so this file stays safe
//  to load on every map.
// ============================================================================
find_bench(bench_name)
{
	return getent(bench_name, "targetname");
}

swap_buildable_fields(stub1, stub2)
{
	temp = stub2.buildablezone;
	stub2.buildablezone = stub1.buildablezone;
	stub2.buildablezone.stub = stub2;
	stub1.buildablezone = temp;
	stub1.buildablezone.stub = stub1;
	temp = stub2.buildablestruct;
	stub2.buildablestruct = stub1.buildablestruct;
	stub1.buildablestruct = temp;
	temp = stub2.equipname;
	stub2.equipname = stub1.equipname;
	stub1.equipname = temp;
	temp = stub2.hint_string;
	stub2.hint_string = stub1.hint_string;
	stub1.hint_string = temp;
	temp = stub2.trigger_hintstring;
	stub2.trigger_hintstring = stub1.trigger_hintstring;
	stub1.trigger_hintstring = temp;
	temp = stub2.persistent;
	stub2.persistent = stub1.persistent;
	stub1.persistent = temp;
	temp = stub2.onbeginuse;
	stub2.onbeginuse = stub1.onbeginuse;
	stub1.onbeginuse = temp;
	temp = stub2.oncantuse;
	stub2.oncantuse = stub1.oncantuse;
	stub1.oncantuse = temp;
	temp = stub2.onenduse;
	stub2.onenduse = stub1.onenduse;
	stub1.onenduse = temp;
	temp = stub2.target;
	stub2.target = stub1.target;
	stub1.target = temp;
	temp = stub2.targetname;
	stub2.targetname = stub1.targetname;
	stub1.targetname = temp;
	temp = stub2.weaponname;
	stub2.weaponname = stub1.weaponname;
	stub1.weaponname = temp;
	temp = stub2.cost;
	stub2.cost = stub1.cost;
	stub1.cost = temp;
	temp = stub2.original_prompt_and_visibility_func;
	stub2.original_prompt_and_visibility_func = stub1.original_prompt_and_visibility_func;
	stub1.original_prompt_and_visibility_func = temp;
	bench1 = undefined;
	bench2 = undefined;
	transfer_pos_as_is = 1;

	if (isdefined(stub1.model.target) && isdefined(stub2.model.target))
	{
		bench1 = find_bench(stub1.model.target);
		bench2 = find_bench(stub2.model.target);

		if (isdefined(bench1) && isdefined(bench2))
		{
			transfer_pos_as_is = 0;
			temp = [];
			temp[0] = bench1 worldtolocalcoords(stub1.model.origin);
			temp[1] = stub1.model.angles - bench1.angles;
			temp[2] = bench2 worldtolocalcoords(stub2.model.origin);
			temp[3] = stub2.model.angles - bench2.angles;
			stub1.model.origin = bench2 localtoworldcoords(temp[0]);
			stub1.model.angles = bench2.angles + temp[1];
			stub2.model.origin = bench1 localtoworldcoords(temp[2]);
			stub2.model.angles = bench1.angles + temp[3];
		}

		temp = stub2.model.target;
		stub2.model.target = stub1.model.target;
		stub1.model.target = temp;
	}

	temp = stub2.model;
	stub2.model = stub1.model;
	stub1.model = temp;

	if (transfer_pos_as_is)
	{
		temp = [];
		temp[0] = stub2.model.origin;
		temp[1] = stub2.model.angles;
		stub2.model.origin = stub1.model.origin;
		stub2.model.angles = stub1.model.angles;
		stub1.model.origin = temp[0];
		stub1.model.angles = temp[1];

		swap_buildable_fields_model_offset(stub1, stub2);
	}
}

swap_buildable_fields_model_offset(stub1, stub2)
{
	origin_offset = (0, 0, 0);
	angle_offset = (0, 0, 0);

	if (stub1.weaponname == "equip_turbine_zm")
	{
		if (stub2.weaponname == "riotshield_zm")
		{
			origin_offset = (6, -6, -27);
			angle_offset = (0, -180, 0);
		}
		else if (stub2.weaponname == "equip_turret_zm")
		{
			origin_offset = (-7, -5, 0);
			angle_offset = (0, -90, 0);
		}
		else if (stub2.weaponname == "equip_electrictrap_zm")
		{
			origin_offset = (-2, 8, 0);
			angle_offset = (0, 90, 0);
		}
		else if (stub2.weaponname == "jetgun_zm")
		{
			origin_offset = (-3, -4, -24);
			angle_offset = (0, -90, 0);
		}
	}
	else if (stub1.weaponname == "riotshield_zm")
	{
		if (stub2.weaponname == "equip_turbine_zm")
		{
			origin_offset = (-6, 6, 27);
			angle_offset = (0, 180, 0);
		}
		else if (stub2.weaponname == "equip_turret_zm")
		{
			origin_offset = (-1, 1, 27);
			angle_offset = (0, 90, 0);
		}
		else if (stub2.weaponname == "equip_electrictrap_zm")
		{
			origin_offset = (2, -4, 27);
			angle_offset = (0, -90, 0);
		}
		else if (stub2.weaponname == "jetgun_zm")
		{
			origin_offset = (-2, 5, 3);
			angle_offset = (0, 90, 0);
		}
	}
	else if (stub1.weaponname == "equip_turret_zm")
	{
		if (stub2.weaponname == "equip_turbine_zm")
		{
			origin_offset = (7, 5, 0);
			angle_offset = (0, 90, 0);
		}
		else if (stub2.weaponname == "riotshield_zm")
		{
			origin_offset = (1, -1, -27);
			angle_offset = (0, -90, 0);
		}
		else if (stub2.weaponname == "equip_electrictrap_zm")
		{
			origin_offset = (2, -2, 0);
			angle_offset = (0, -180, 0);
		}
		else if (stub2.weaponname == "jetgun_zm")
		{
			origin_offset = (4, 0, -24);
			angle_offset = (0, 0, 0);
		}
	}
	else if (stub1.weaponname == "equip_electrictrap_zm")
	{
		if (stub2.weaponname == "equip_turbine_zm")
		{
			origin_offset = (2, -8, 0);
			angle_offset = (0, -90, 0);
		}
		else if (stub2.weaponname == "riotshield_zm")
		{
			origin_offset = (-2, 4, -27);
			angle_offset = (0, 90, 0);
		}
		else if (stub2.weaponname == "equip_turret_zm")
		{
			origin_offset = (-2, 2, 0);
			angle_offset = (0, 180, 0);
		}
		else if (stub2.weaponname == "jetgun_zm")
		{
			origin_offset = (-6, 3, -24);
			angle_offset = (0, 180, 0);
		}
	}
	else if (stub1.weaponname == "jetgun_zm")
	{
		if (stub2.weaponname == "equip_turbine_zm")
		{
			origin_offset = (3, 4, 24);
			angle_offset = (0, 90, 0);
		}
		else if (stub2.weaponname == "riotshield_zm")
		{
			origin_offset = (2, -5, -3);
			angle_offset = (0, -90, 0);
		}
		else if (stub2.weaponname == "equip_turret_zm")
		{
			origin_offset = (-4, 0, 24);
			angle_offset = (0, 0, 0);
		}
		else if (stub2.weaponname == "equip_electrictrap_zm")
		{
			origin_offset = (6, -3, 24);
			angle_offset = (0, -180, 0);
		}
	}
	else if (stub1.weaponname == "equip_springpad_zm")
	{
		if (stub2.weaponname == "slipgun_zm")
		{
			origin_offset = (-14, 2, -2);
			angle_offset = (64.2, 90, 0);
		}
	}
	else if (stub1.weaponname == "slipgun_zm")
	{
		if (stub2.weaponname == "equip_springpad_zm")
		{
			origin_offset = (14, -2, 2);
			angle_offset = (-64.2, -90, 0);
		}
	}

	stub1.model.angles += angle_offset;
	stub2.model.angles -= angle_offset;

	model1_angle = (0, stub1.model.angles[1], 0);
	model2_angle = (0, stub2.model.angles[1], 0);

	if (angle_offset[1] < 0)
	{
		model1_angle -= (0, angle_offset[1], 0);
	}
	else
	{
		model2_angle += (0, angle_offset[1], 0);
	}

	stub1.model.origin += (anglesToForward(model1_angle) * origin_offset[0]) + (anglesToRight(model1_angle) * origin_offset[1]) + (anglesToUp(model1_angle) * origin_offset[2]);
	stub2.model.origin -= (anglesToForward(model2_angle) * origin_offset[0]) + (anglesToRight(model2_angle) * origin_offset[1]) + (anglesToUp(model2_angle) * origin_offset[2]);
}

// ============================================================================
//  spawn_wallbuy_plywood  -  the boarded-up backing behind a wall-buy
//
//  🛑 v2.17.5 - THIS FUNCTION WAS MISSING AND IT CRASHED THE WHOLE MAP.
//
//  zm_tomb_loc_excavation_site.gsc calls it twice. Upstream it lives in
//  scripts\zm\zm_tomb\zm_tomb_reimagined.gsc:1142, a file this mod does not
//  ship; the port re-pointed the two call sites at loc_common (the right call)
//  and then never brought the body across. The reference sat harmless only
//  because the location was unregistered. The moment excavation_site was
//  registered, the engine hit:
//
//      **** Unresolved external : "spawn_wallbuy_plywood" with 2 parameters
//           in "scripts/zm/locs/zm_tomb_loc_excavation_site.gsc" ****
//      SV_Shutdown: **** 1 script error(s)
//
//  🛑 AND IT TOOK DOWN A LOCATION THAT DOES NOT EVEN CALL IT. The crash landed
//  on CHURCH, because GSC resolves every script in the zone at map load, not
//  lazily at the call. One dangling reference in any registered loc script is
//  fatal for EVERY location on that map. That is why this class of bug has to
//  be caught before the build, not in game - see tools\check-loc-refs.ps1,
//  added with this fix and wired into the pre-build checks.
//
//  Body is upstream's verbatim. Both models are already in this location's
//  precache list, which is how the port got half-way and stopped.
// ============================================================================
// ============================================================================
//  register_pap_struct_built  -  a Pack-a-Punch that is BUILT, not "please wait"
//
//  🛑 v2.17.7 - USE THIS FOR EVERY SURVIVAL PACK-A-PUNCH. Never
//  register_perk_struct( "specialty_weapupgrade", ... ).
//
//  User, 2026-09-15, on Trenches: *"the Pack-a-Punch machine was like unbuilt,
//  like when you don't have all six generators on Origins ... make sure it's
//  the built one, look at Crazy Place, that had a workaround for that exact
//  issue."* Correct on every point.
//
//  WHY IT HAPPENS, from the helper's own source. replaced\utility.gsc's
//  register_perk_struct() has a special case: when the perk name is
//  "specialty_weapupgrade" it ALSO spawns a second struct,
//      targetname "weapupgrade_flag_targ", model "zombie_sign_please_wait"
//  and points the machine's .target at it. Stock then draws that sign, which is
//  the unbuilt/"PLEASE WAIT" pose. That is right for classic Origins, where the
//  machine really is gated behind the staffs; it is wrong for a survival arena,
//  which has no generator quest to finish.
//
//  THE WORKAROUND IS CRAZY PLACE'S AND IT IS SIMPLY NOT TO USE THE HELPER -
//  zm_tomb_loc_crazy_place.gsc:168-174 hand-builds the struct with no .target
//  at all. MOD_CATALOGUE.md §37c: "With no .target the stock branch's own
//  isdefined( flag_pos ) guard skips it." Same technique, named and shared here
//  so the next arena does not have to rediscover it.
//
//  tools\check-perk-guard.ps1 fails the build if any loc script registers a
//  specialty_weapupgrade through register_perk_struct, so this cannot regress.
// ============================================================================
// ============================================================================
//  pap_built_pose  -  ghost the stone heap so the client's built model shows
//
//  🛑 v2.17.8 - THE SIGN WAS ONLY HALF OF IT. v2.17.7 stopped the "please
//  wait" flag spawning and the machine STILL drew broken: *"the Pack-a-Punch
//  machine is still like broken up as if it was unpowered, but the
//  functionality still works."* Correct - and the model is why.
//
//  On Origins the Pack-a-Punch IS a heap of stone until the generators are
//  captured, and the assembly is a CLIENT animation on a client-only model
//  ("pap_cs"), driven by zm_tomb_capture_zones.csc::play_pap_anim(). The
//  server's own machine is ghost()ed and nobody ever sees it. A survival arena
//  has no generators, so nothing ever plays that animation and the heap is all
//  there is.
//
//  Crazy Place solved this in v2.14.25 and this is that solution, lifted out of
//  zm_tomb_loc_crazy_place.gsc::zmqol_cp_pap_built_pose() so every Origins
//  arena can use it:
//     SERVER (here)  ghost the machine so the heap does not draw through.
//     CLIENT         zm_tomb.csc::zmqol_cp_pap_client_model() spawns its own
//                    p6_zm_tm_packapunch and snaps the six assembly anims to
//                    their last frame (rate 0, setanimtime 1.0) - the same
//                    thing stock does to pap_cs.
//
//  🛑 DO NOT "FIX" THIS BY ANIMATING THE SERVER MACHINE. v2.14.23 tried exactly
//  that at rate 1; the log said all six anims played and the heap never
//  changed. Stock never does it that way.
//
//  ghost() hides and KEEPS collision, which is wanted - the model is often the
//  only thing stopping a player walking through the machine.
// ============================================================================
//  🛑 v2.17.9 - TAKES THE EXPECTED ORIGIN, because "the first one" was wrong.
//  v2.17.8 ghosted whichever specialty_weapupgrade machine it found first. On
//  Trenches that was ORIGINS' OWN Pack-a-Punch at (-5,-8,335) - the log said so
//  in as many words - so the arena's real machine was never ghosted and its
//  stone heap kept drawing next to the client's built model. User: *"the built
//  version is there, but these broken pieces are still there on the side."*
//  Pass the origin the loc script registered and the nearest machine to it wins.
pap_built_pose( v_expected )
{
	level endon( "intermission" );

	m_pap = undefined;
	n_wait = 0;

	while ( !isdefined( m_pap ) && n_wait < 600 )
	{
		a_pap = getentarray( "specialty_weapupgrade", "script_noteworthy" );
		n_best = 99999;

		for ( i = 0; i < a_pap.size; i++ )
		{
			if ( !isdefined( a_pap[i] ) || !isdefined( a_pap[i].machine ) )
				continue;

			if ( !isdefined( v_expected ) )
			{
				m_pap = a_pap[i].machine;
				break;
			}

			n_d = distance( a_pap[i].machine.origin, v_expected );

			//  128 units: comfortably inside one machine, far short of the next.
			if ( n_d < n_best && n_d <= 128 )
			{
				n_best = n_d;
				m_pap = a_pap[i].machine;
			}
		}

		if ( !isdefined( m_pap ) )
		{
			wait 0.05;
			n_wait++;
		}
	}

	if ( !isdefined( m_pap ) )
	{
		println( "[zm_qol] pap built pose: no machine after 30s - server machine NOT ghosted, the heap will draw through the client's built model" );
		return;
	}

	m_pap ghost();

	//  ------------------------------------------------------------------
	//  🛑 v2.17.24 - THE fx_ent DELETION IS OFF. IT WAS EATING THE STOCK FX.
	//
	//  v2.17.11 deleted m_pap.fx_ent on sight and then kept deleting it in a
	//  forever loop. Read what that entity actually is, in stock
	//  _zm_perks.gsc:357-366:
	//
	//      perk_machine.fx_ent = spawn( "script_model", origin_base
	//                                   + origin_offset + (0,1,-34) );
	//      ...
	//      playFXOnTag( level._effect["packapunch_fx"], perk_machine.fx_ent,
	//                   "tag_origin" );
	//
	//  It is created INSIDE third_person_weapon_upgrade(), at
	//  machine origin + (0,0,35) + (0,1,-34) - i.e. one unit off the machine's
	//  own base - and it is the only thing packapunch_fx ever plays on. So a
	//  standing deletion does not remove "orphaned orbs"; it removes the
	//  Pack-a-Punch's entire upgrade effect, every time anyone packs a gun.
	//
	//  User, 2026-09-15, on Church: *"all the visual effects for the pack a
	//  punch machine are missing ... I put it in the machine and it was missing
	//  visual effects."* That is this line, and it is worth noting the v2.17.11
	//  request said *"just keep the main stock visual effects"* - the deletion
	//  went past what was asked for on the same day it was written.
	//
	//  WHAT THE ORBS ACTUALLY WERE. fx_ent is placed from the SERVER machine's
	//  origin and linkto()d to it, while the built model the player sees is the
	//  CLIENT's own copy (zm_tomb.csc). When those two origins disagree the
	//  effect plays in mid-air wherever the invisible server machine is - which
	//  is exactly "electric balls hovering around the side of the thing". The
	//  cure is co-locating them, not deleting the effect; Church had drifted
	//  170 units apart and is fixed in zm_tomb_loc_church.gsc.
	//
	//  Left as a dvar rather than ripped out, because if loose orbs ever show up
	//  again on an arena I have not booted, console settles it without a build:
	//      zmqol_pap_drop_fx 1
	//  Default 0 - stock effects, which is what a Pack-a-Punch should have.
	//  ------------------------------------------------------------------
	b_drop_fx = getdvarintdefault( "zmqol_pap_drop_fx", 0 );

	//  v_expected is optional - the caller may pass nothing and take the first
	//  machine found - so the drift figure is only printed when there is one.
	str_drift = "";

	if ( isdefined( v_expected ) )
		str_drift = ", " + int( distance( m_pap.origin, v_expected ) ) + " from the expected origin";

	println( "[zm_qol] pap built pose: server machine at (" + int( m_pap.origin[0] ) + "," + int( m_pap.origin[1] ) + "," + int( m_pap.origin[2] ) + ") ghosted after " + ( n_wait * 0.05 ) + "s" + str_drift + " - built pose is the client's own model (zm_tomb.csc), stock packapunch_fx kept=" + ( !b_drop_fx ) );

	if ( !b_drop_fx )
		return;

	//  fx_ent is created lazily by the upgrade path, so it never exists at ghost
	//  time - the watch loop is the only thing that can catch it.
	for ( ;; )
	{
		wait 1;

		if ( !isdefined( m_pap ) )
			return;

		if ( isdefined( m_pap.fx_ent ) )
		{
			m_pap.fx_ent delete();
			println( "[zm_qol] pap built pose: zmqol_pap_drop_fx is on - deleted the machine's fx_ent" );
		}
	}
}

// ============================================================================
//  drop_map_pap_structs  -  Origins' OWN Pack-a-Punch leaves the struct index
//
//  🛑 v2.17.10 - THIS IS WHY INSTANT PAP DID NOT WORK AND THE MACHINE LOOKED
//  DEAD. User, on Trenches: *"I have instant PaP turned on and it didn't work
//  ... and the visual effects from the machine are missing, I put it in and it
//  was just blank."* Both are the same cause and Crazy Place already fixed it.
//
//  Origins' stock Pack-a-Punch struct sits at (-5.5, -8.5, 335.5) with
//  script_noteworthy "specialty_weapupgrade". When an arena registers its OWN
//  PaP, the index holds TWO - and everything downstream takes the first one it
//  finds:
//    * quality_of_life.gsc::new_pap_trigger() builds the Instant PaP radius
//      around trigger [0], which was the map's machine out in No Man's Land,
//      nowhere near the player. Hence "instant PaP doesn't work".
//    * the use trigger, the rising-weapon model and the machine fx all key off
//      whichever machine won, so the one in front of the player did nothing
//      visible. Hence "blank, no machine effects".
//
//  Lifted from zm_tomb_loc_crazy_place.gsc::zmqol_cp_drop_map_pap_structs()
//  (v2.14.23), which is the copy that has been in the user's hands and working.
//  The index is level.struct_class_names[key][name], built by
//  replaced\utility::struct_class_init before it calls this location's
//  struct_init - so rebuilding the two arrays the PaP sits in removes it from
//  every consumer at once.
//
//  🛑 CALL IT FROM struct_init AND BEFORE register_pap_struct_built(), so
//  "every specialty_weapupgrade struct" still means the MAP'S and not ours.
// ============================================================================
drop_map_pap_structs()
{
	n_dropped = 0;

	a_keys = [];
	a_keys[0] = "targetname";
	a_keys[1] = "script_noteworthy";
	a_names = [];
	a_names[0] = "zm_perk_machine";
	a_names[1] = "specialty_weapupgrade";

	for ( k = 0; k < a_keys.size; k++ )
	{
		if ( !isdefined( level.struct_class_names[a_keys[k]] ) || !isdefined( level.struct_class_names[a_keys[k]][a_names[k]] ) )
			continue;

		a_old = level.struct_class_names[a_keys[k]][a_names[k]];
		a_new = [];

		for ( i = 0; i < a_old.size; i++ )
		{
			if ( isdefined( a_old[i].script_noteworthy ) && a_old[i].script_noteworthy == "specialty_weapupgrade" )
			{
				if ( k == 0 )
				{
					n_dropped++;
					println( "[zm_qol] pap: dropped the map's own pack-a-punch struct at (" + int( a_old[i].origin[0] ) + "," + int( a_old[i].origin[1] ) + "," + int( a_old[i].origin[2] ) + ") from the struct index" );
				}

				continue;
			}

			a_new[a_new.size] = a_old[i];
		}

		level.struct_class_names[a_keys[k]][a_names[k]] = a_new;
	}

	println( "[zm_qol] pap: " + n_dropped + " map pack-a-punch struct(s) dropped (expect 1) - instant PaP and the machine fx now key off this arena's machine" );
}

// ============================================================================
//  remove_dig_sites  -  Origins' shovel digs are quest furniture, not survival
//
//  User, 2026-09-15: *"get rid of the dig sites in this map because this isn't
//  Origins, this is a standalone survival map."* Right - the digs exist to feed
//  the staff/quest chain and the Golden Shovel, none of which a survival arena
//  has. Stock zm_tomb.d3dbsp carries 28 "dig_spot" and 16
//  "zombie_blood_dig_spot" entities (counted from the mapents dump).
//
//  Deleted rather than hidden: with no shovel to buy and no quest to advance,
//  there is no state in which a dig should be usable here.
//
//  🛑 Survival only - called from the loc scripts, never on zclassic, so
//  classic Origins keeps every dig it has always had.
// ============================================================================
//  🛑 v2.17.11 - DROPPED FROM THE STRUCT INDEX, NOT DELETED AT ROUND START.
//
//  v2.17.10 waited for start_zombie_round_logic and deleted what it found. The
//  log said "removed 44" - the exact 28 + 16 the map ships - and the user still
//  had a mound with "Need shovel to dig" in front of them. Deleting the structs
//  after the fact achieves nothing, because:
//
//    * dig_spot entries are script_STRUCTS. zm_tomb_dig::dig_spots_init() has
//      already copied them into level.a_dig_spots by then, and that array is
//      what everything downstream uses.
//    * dig_spots_respawn() then loops for the whole match bringing mounds back,
//      so even a perfect one-shot delete only buys a few seconds. The robots
//      taught the same lesson an hour earlier.
//    * the visible mound is not the struct. dig_spot_spawn() spawns a separate
//      script_model (p6_zm_tm_dig_mound) plus a look-at trigger whose hint is
//      ZM_TOMB_NS, "Need shovel to dig" - exactly what the screenshot shows.
//
//  So take them out of the index BEFORE dig_spots_init() ever reads it. Called
//  from struct_init(), which runs inside struct_class_init() long before the
//  map's main(), getstructarray("dig_spot") then returns nothing,
//  level.a_dig_spots is empty, and neither the initial spawn nor the respawn
//  loop has anything to work with. No mound, no trigger, no watchdog needed.
//
//  Same shape as drop_map_pap_structs() above, and the same reasoning: the
//  struct index is the single source every consumer reads.
remove_dig_site_structs()
{
	//  🛑 v2.17.27 - AND THE SHOVELS THEMSELVES. User, 2026-09-16: *"there's
	//  still shovels spawning in on these survival variants of these Origins
	//  maps ... obviously you can't do easter eggs, so get rid of the shovels
	//  from Church"* and the other three arenas.
	//
	//  The mounds and the shovel are two different systems and dropping
	//  dig_spot never touched the second one. zm_tomb_dig::init_shovel() reads
	//  getstructarray( "shovel_location", "targetname" ), groups them by zone,
	//  and for each zone spawns a p6_zm_tm_shovel script_model PLUS a static
	//  unitrigger (generate_shovel_unitrigger). Deleting the model afterwards
	//  would leave that unitrigger behind - the same trap remove_challenge_boxes
	//  had to learn about the hard way - so it goes out of the index here
	//  instead, before init_shovel ever reads it. No struct, no model, no
	//  trigger, nothing to prompt on.
	n_dropped = 0;
	a_names = [];
	a_names[0] = "dig_spot";
	a_names[1] = "zombie_blood_dig_spot";
	a_names[2] = "shovel_location";

	for ( i = 0; i < a_names.size; i++ )
	{
		if ( !isdefined( level.struct_class_names["targetname"] ) || !isdefined( level.struct_class_names["targetname"][a_names[i]] ) )
			continue;

		n_dropped += level.struct_class_names["targetname"][a_names[i]].size;
		level.struct_class_names["targetname"][a_names[i]] = [];
	}

	println( "[zm_qol] dig sites: " + n_dropped + " dig/shovel struct(s) dropped from the index before dig_spots_init and init_shovel read it (stock zm_tomb ships 28 dig_spot + 16 zombie_blood_dig_spot + the shovel_location set) - no mounds, no shovels, no triggers" );
}

// ============================================================================
//  remove_challenge_boxes  -  "Rituals of the Ancients" is quest furniture
//
//  User, 2026-09-15, with the slab on screen reading RITUALS OF THE ANCIENTS /
//  RICHTOFEN DEMPSEY TAKEO NIKOLAI and the prompt "Look at medal to view
//  challenge": *"make sure the challenges on Origins are disabled for the
//  survival maps - not Origins itself of course - because the box still glows
//  when you get near it."*
//
//  The system is maps\mp\zm_tomb_challenges::challenges_init() ->
//  _zm_challenges::init(), which picks up `challenge_box` entities and threads
//  box_init() on each. box_init() is what sets the "foot_print_box_glow"
//  clientfield, i.e. the glow that was reported.
//
//  Counted from the stock mapents, Origins ships exactly TWO, each with a
//  p6_zm_tm_challenge_slab_2 board as its .target:
//      (2706, 4660, -312)   in the bunkers   -> the Trenches arena
//      (1324, -3712,  302)  in the village   -> the Church arena
//  Excavation Site and the Crazy Place have none, so this is a no-op there and
//  is still called for consistency.
//
//  Both the box and its board go. The challenge rewards are tied to Origins'
//  own progression - zone captures, soul boxes - none of which a survival arena
//  has, so there is no state in which these should be usable here.
//
//  🛑 BO2-Reimagined does NOT do this. Their replaced\_zm_challenges.gsc keeps
//  challenges in survival and only raises the cost to 9000 (its
//  update_box_prompt, `if ( !is_classic() ) self.cost = 9000`). This is a
//  deliberate departure on the user's instruction, not a port.
//
//  🛑 SURVIVAL ONLY - called from the loc scripts, never on zclassic, so
//  classic Origins keeps its challenges exactly as they are.
// ============================================================================
remove_challenge_boxes()
{
	level endon( "intermission" );

	flag_wait( "start_zombie_round_logic" );

	n_boxes = 0;
	n_boards = 0;
	n_stubs = 0;

	a_boxes = getentarray( "challenge_box", "targetname" );

	//  Remember where they were - the watchdog at the end of this function needs
	//  the positions after the entities themselves are gone.
	a_origins = [];

	foreach ( box in a_boxes )
	{
		if ( isdefined( box ) )
			a_origins[a_origins.size] = box.origin;
	}

	//  ------------------------------------------------------------------
	//  🛑 v2.17.16 - THE UNITRIGGER MUST GO FIRST, AND IT IS A SEPARATE THING.
	//
	//  v2.17.15 deleted the box and the slab and logged "removed 2 challenge_box
	//  and 2 slab(s)" - it genuinely ran - and the user still walked into an
	//  invisible wall with "Look at medal to view challenge" on screen.
	//
	//  Because the prompt is not the model. _zm_challenges::box_init() builds a
	//  unitrigger stub (origin, 64x64x64 box, prompt func) and hands it to
	//  _zm_unitrigger::register_static_unitrigger(). That stub is stored in
	//  level._unitriggers.trigger_stubs and OUTLIVES the entity it was made
	//  from - deleting the model removes the thing you can see and leaves the
	//  thing you can touch.
	//
	//  The stub keeps a .m_box pointer back to its box, which is how each one is
	//  matched here. Unregister BEFORE deleting, while .m_box is still valid;
	//  once the box is gone the pointer is undefined and there is nothing left
	//  to match on.
	//
	//  📝 Checked the mapents for a separate clip brush at both boxes first -
	//  there is none, nothing but pathnodes and a screecher-hole struct within
	//  160 units - so the unitrigger IS the invisible wall, not a clip I missed.
	//  ------------------------------------------------------------------
	//  🛑 v2.17.17 - FOUR PLACES, NOT ONE. v2.17.16 searched only
	//  level._unitriggers.trigger_stubs and logged "unregistered 0" while the
	//  prompt and the invisible wall were both still there.
	//
	//  register_static_unitrigger() does NOT put the stub in trigger_stubs.
	//  Reading it (_zm_unitrigger.gsc:198-243) it lands in one of:
	//      level._unitriggers._deferredinitlist   if zones are not set up yet
	//      level.zones[<zone>].unitrigger_stubs   the normal path for a static
	//      level._unitriggers.dynamic_stubs       fallback when no zone matched
	//  and trigger_stubs is the DYNAMIC register_unitrigger() path, which a
	//  challenge box never takes. Searching only there was guaranteed to find
	//  nothing. All four are swept now.
	//  🛑 v2.17.19 - USE THE CHALLENGE SYSTEM'S OWN LIST. STOP GUESSING AT
	//  _zm_unitrigger INTERNALS.
	//
	//  Two attempts were spent hunting the stub through _zm_unitrigger's private
	//  arrays: v2.17.16 searched trigger_stubs (wrong list, "unregistered 0"),
	//  v2.17.17 added dynamic_stubs, _deferredinitlist and every
	//  level.zones[].unitrigger_stubs (found them, "unregistered 2" - and the
	//  user still walked into the trigger).
	//
	//  _zm_challenges::init() keeps its own array. Line 16 creates it, line 405
	//  appends every stub box_init() makes:
	//        level.a_uts_challenge_boxes[...] = s_unitrigger_stub;
	//  That is the authoritative handle on exactly these triggers and nothing
	//  else, and it does not care which internal list the engine filed them in.
	//  Unregister those, then clear the array so nothing can walk it later and
	//  re-spawn from a stale stub.
	//
	//  The positional watchdog below stays as the backstop - between the two,
	//  a trigger has to survive being unregistered by its own owner AND being
	//  deleted on sight once a second.
	if ( isdefined( level.a_uts_challenge_boxes ) )
	{
		for ( i = level.a_uts_challenge_boxes.size - 1; i >= 0; i-- )
		{
			s_stub = level.a_uts_challenge_boxes[i];

			if ( !isdefined( s_stub ) )
				continue;

			//  Kill the spawned trigger directly as well as unregistering the
			//  stub - unregister_unitrigger() is threaded and returns before it
			//  has done anything, which is how a re-spawn raced it last time.
			if ( isdefined( s_stub.trigger ) )
			{
				s_stub.trigger notify( "kill_trigger" );
				s_stub.trigger delete();
			}

			if ( isdefined( s_stub.playertrigger ) )
			{
				a_keys = getarraykeys( s_stub.playertrigger );

				foreach ( key in a_keys )
				{
					t_p = s_stub.playertrigger[key];

					if ( isdefined( t_p ) )
					{
						t_p notify( "kill_trigger" );
						t_p delete();
					}
				}

				s_stub.playertrigger = [];
			}

			maps\mp\zombies\_zm_unitrigger::unregister_unitrigger( s_stub );
			n_stubs++;
		}

		level.a_uts_challenge_boxes = [];
	}

	foreach ( box in a_boxes )
	{
		if ( !isdefined( box ) )
			continue;

		if ( isdefined( box.target ) )
		{
			m_board = getent( box.target, "targetname" );

			if ( isdefined( m_board ) )
			{
				m_board delete();
				n_boards++;
			}
		}

		box delete();
		n_boxes++;
	}

	println( "[zm_qol] challenges: removed " + n_boxes + " challenge_box, " + n_boards + " slab(s) and unregistered " + n_stubs + " unitrigger stub(s) on " + getdvar( "ui_zm_mapstartlocation" ) + " (the stub is what draws 'Look at medal to view challenge' and blocks you, not the model)" );

	//  ------------------------------------------------------------------
	//  🛑 v2.17.18 - AND NOW A WATCHDOG, BECAUSE UNREGISTERING WAS NOT ENOUGH.
	//
	//  v2.17.17 found the stubs in level.zones[<zone>].unitrigger_stubs and
	//  logged "unregistered 2". Verified the running game had that exact build
	//  (mod.iwd deployed 16:28:22, engine started 16:28:31) - and the user still
	//  walked into an invisible wall with the medal prompt on screen.
	//
	//  So the trigger comes back. _zm_unitrigger re-spawns a stub's trigger when
	//  a player enters its zone, and unregister_unitrigger() is THREADED - it
	//  returns before it has done anything, so a re-spawn can race it. Chasing
	//  the exact ordering costs another boot each time it is wrong; deleting the
	//  trigger on sight does not.
	//
	//  Same shape as disable_giant_robots(): sweep every second for the match.
	//  A stub whose .m_box is now undefined AND which sits within 96 units of a
	//  position a challenge box used to occupy is one of ours - that pairing is
	//  what stops it touching any other unitrigger on the map (wall-buys, the
	//  mystery box, doors all have live .m_box-less stubs of their own, so
	//  position alone would be far too broad).
	//  ------------------------------------------------------------------
	a_spots = [];

	foreach ( v in a_origins )
		a_spots[a_spots.size] = v;

	if ( a_spots.size == 0 )
		return;

	n_killed = 0;

	for ( ;; )
	{
		wait 1;

		a_trigs = getentarray( "trigger_radius_use", "classname" );
		a_trigs = arraycombine( a_trigs, getentarray( "trigger_box_use", "classname" ), 0, 0 );
		a_trigs = arraycombine( a_trigs, getentarray( "trigger_radius", "classname" ), 0, 0 );

		foreach ( trig in a_trigs )
		{
			if ( !isdefined( trig ) )
				continue;

			//  🛑 v2.17.20 - POSITION ONLY. No stub condition any more.
			//
			//  v2.17.18 required trig.stub to exist AND trig.stub.m_box to be
			//  undefined. That was too clever: a re-spawned trigger may carry no
			//  .stub back-reference at all, so the filter skipped the very
			//  thing it was written to kill and the user kept walking into it.
			//
			//  Position alone is SAFE HERE and that is measured, not hoped: a
			//  sweep of the mapents around both challenge boxes found nothing
			//  within 160 units except pathnodes and one screecher-hole struct.
			//  No wall-buy, no mystery box, no door. So anything trigger-shaped
			//  within 96 of where a challenge box used to stand is the challenge
			//  trigger, and the box itself is already deleted by this point.
			foreach ( v_spot in a_spots )
			{
				if ( distance( trig.origin, v_spot ) <= 96 )
				{
					trig notify( "kill_trigger" );
					trig delete();
					n_killed++;

					if ( n_killed <= 6 )
						println( "[zm_qol] challenges: killed a re-spawned challenge trigger at (" + int( v_spot[0] ) + "," + int( v_spot[1] ) + "," + int( v_spot[2] ) + ") - watchdog, " + n_killed + " so far" );

					break;
				}
			}
		}
	}
}

// ============================================================================
//  disable_giant_robots  -  Origins' robots do not belong in a survival arena
//
//  🛑 v2.17.9 - AND THIS IS ALSO WHY PRONE WAS BROKEN. User, on Trenches:
//  *"one of the giant robots is still walking through the map, but this is a
//  survival map, you can't even get the wind staff"* and, separately, *"for
//  some reason I can't prone."* One cause, both symptoms.
//
//  🌟 THE ONLY THING ON THE WHOLE MAP THAT DISABLES PRONE IS THE ROBOT.
//  Grepping every Origins script for allowprone( 0 ) returns exactly one hit:
//  zm_tomb_giant_robot.gsc:1181, inside the head/eject sequence, which pairs
//  with allowprone( 1 ) at :1238 on the way out. In a survival arena that
//  sequence has no quest to complete, so a player who gets caught by it can be
//  left standing with prone switched off and nothing to switch it back. Take
//  the robots away and the switch is never touched.
//
//  WHAT IS REMOVED, and what is deliberately NOT:
//    * the three ai_giant_robot_N actors               deleted
//    * trig_stomp_kill_left_N / _right_N               deleted - these are the
//      foot-stomp kill triggers, linked to the robot's feet; with the robot
//      gone they would otherwise sit wherever they were last moved
//    * the clientfields init_giant_robot() registers   LEFT ALONE. They are
//      registered on both sides; removing them here would be an
//      EXE_CLIENT_FIELD_MISMATCH, which is a far worse bug than a robot.
//
//  🛑 CLASSIC ORIGINS IS UNTOUCHED. This is called only from the survival loc
//  scripts, which never run on zclassic - the robots, the staffs and the quest
//  all behave exactly as they always have there.
// ============================================================================
// ============================================================================
//  ⭐ fix_stuck_fight_distance  -  THE ZOMBIES THAT WALK INTO YOU AND NEVER SWING
//
//  User, 2026-09-16, across a long session: *"some of them are attacking me
//  some of them are not"*, *"they're coming after me ... they're just walking
//  into me and not attacking"*, *"one of the zombies that was attacking me just
//  literally froze for like two to three seconds"*. Nuketown and Town are fine;
//  Origins is not.
//
//  🌟 EVERY AI FIELD ON A BROKEN ZOMBIE READS HEALTHY, WHICH IS THE WHOLE CLUE.
//  A per-zombie audit of ones standing 31-70 units from the player, refusing to
//  attack, printed:
//      ai_state=find_flesh  ignoreme=0  enemy=THIS-PLAYER  goalradius=32
//  i.e. find_flesh alive, target acquired, stock goal radius. Nothing in the
//  GSC AI layer is wrong, so the fault is not a targeting or state problem and
//  no amount of work on failsafes, capture zones or robots could ever fix it.
//
//  🛑 IT IS ONE ENGINE FIELD: pathenemyfightdist, the distance at which the AI
//  stops closing and starts fighting. Stock _zm_spawner::zombie_goto_entrance,
//  the barricade-climb path, at lines 513-518:
//
//      self zombie_setup_attack_properties();
//      self thread find_flesh();
//      self.pathenemyfightdist = 4;                        <- 4 for the climb
//      self zombie_complete_emerging_into_playable_area();
//      self.pathenemyfightdist = 64;                       <- restored here
//      self.barricade_enter = 0;
//
//  Two lines apart. A zombie whose thread is interrupted in that window keeps
//  pathenemyfightdist = 4 for the rest of its life: it will only fight from
//  FOUR units, which it can never reach through the player's own collision, so
//  it presses into the player forever and never swings. Everything else about
//  it is fine, which is exactly what the audit showed.
//
//  📝 The tell in the audit data was completed_emerging_into_playable_area
//  reading `undef` on the stuck ones - line 516 is what sets it, so those
//  zombies provably never got past it, and therefore never got line 517.
//
//  📝 This mod already repairs these same two fields for hellhounds that lose
//  their setup - zm_transit_loc_diner.gsc:2194 sets pathenemyfightdist and
//  meleeattackdist to 64 verbatim. Same fix, same values, applied to zombies.
//
//  Only ever WIDENS a broken value back to stock's own 64. A zombie that is
//  mid-climb right now is left alone (barricade_enter is still 1), so this
//  cannot cut a barrier animation short.
// ============================================================================
fix_stuck_fight_distance()
{
	level endon( "intermission" );

	n_fight = 0;
	n_flesh = 0;

	for ( ;; )
	{
		wait 1;

		a_ai = getaiarray( level.zombie_team );

		for ( i = 0; i < a_ai.size; i++ )
		{
			ai = a_ai[i];

			if ( !isdefined( ai ) || !isalive( ai ) )
				continue;

			if ( isdefined( ai.isdog ) && ai.isdog )
				continue;

			//  ---------------------------------------------------------------
			//  🛑 STOCK OWNS THE WHOLE BARRIER ENTRY. TWO GUARDS, NOT ONE.
			//
			//  v2.17.31 guarded on completed_emerging_into_playable_area, which
			//  looked safe and was in fact a switch that turned this entire
			//  function off: stock sets that flag on the LAST line of the entry
			//  sequence, so every zombie this function exists to repair reads
			//  undef there forever and was skipped. Zero repairs fired in the
			//  2026-09-16 13:52 boot - the log has not one "fight distance" line
			//  across a Church match and a Trenches match.
			//
			//  The right test is the BOARDS, and it is below: a zombie standing
			//  at its own window with pieces still up is mid-teardown and is not
			//  touched. barricade_enter covers the climb animation itself.
			//  ---------------------------------------------------------------
			if ( is_true( ai.barricade_enter ) )
				continue;

			if ( ai zmqol_at_own_barrier() )
				continue;

			if ( !ai scripts\zm\qol_options::zmqol_nb_near_player() )
				continue;

			//  ---------------------------------------------------------------
			//  REPAIR 1 - find_flesh IS NOT RUNNING (ignoreme stuck at 1).
			//
			//  _zm_ai_basic::find_flesh():24 is the only line in the whole tree
			//  that clears ignoreme, and the function opens with
			//      self endon( "stop_find_flesh" );
			//  so a zombie holding ignoreme = 1 next to a living player is a
			//  zombie whose find_flesh thread has been killed and never
			//  restarted. It keeps its old goal, so it still walks into the
			//  player and shoves them, and it will never swing again.
			//
			//  Origins alone notifies "stop_find_flesh" from the capture-zone
			//  loop, and zm_highrise does it too, but this does not care which
			//  one did it - it repairs the measurable end state.
			//  ---------------------------------------------------------------
			if ( is_true( ai.ignoreme ) && !is_true( ai.zmqol_flesh_restarting ) )
			{
				ai thread zmqol_restart_find_flesh();
				n_flesh++;

				if ( n_flesh <= 5 || n_flesh % 25 == 0 )
					println( "[zm_qol] zombie AI: restarted find_flesh on a zombie holding ignoreme=1 beside a player (total " + n_flesh + ") - it was walking into the player without ever swinging" );
			}

			//  ---------------------------------------------------------------
			//  REPAIR 2 - pathenemyfightdist STUCK BELOW STOCK'S 64.
			//
			//  _zm_spawner::zombie_goto_entrance:542 drops it to 4 for the climb
			//  and line 544 puts it back. A zombie whose thread dies in between
			//  keeps 4 - four units is inside the player's own collision, so it
			//  can never reach its fight distance and presses into the player
			//  instead. Only ever widens a value back to stock's own number.
			//  ---------------------------------------------------------------
			if ( !isdefined( ai.pathenemyfightdist ) || ai.pathenemyfightdist < 64 )
			{
				ai.pathenemyfightdist = 64;
				n_fight++;

				if ( n_fight <= 5 || n_fight % 25 == 0 )
					println( "[zm_qol] zombie AI: restored pathenemyfightdist to 64 on a zombie stuck mid barricade-entry (total " + n_fight + ") - it can now fight instead of pressing into the player" );
			}

			if ( !isdefined( ai.meleeattackdist ) || ai.meleeattackdist < 64 )
				ai.meleeattackdist = 64;
		}
	}
}

// ----------------------------------------------------------------------------
//  zmqol_at_own_barrier  -  IS THIS ZOMBIE STANDING AT ITS OWN WINDOW WITH
//  BOARDS STILL UP? If so, stock's tear_into_building() is mid-teardown on it
//  and nothing here may touch it - that is how a previous pass let zombies
//  climb through barriers that still had all six boards.
//
//  The piece test is _zm_utility::all_chunks_destroyed()'s own test, verbatim:
//  "open" plus "opening" against getnumzbarrierpieces().
// ----------------------------------------------------------------------------
zmqol_at_own_barrier()
{
	if ( !isdefined( self.first_node ) || !isdefined( self.first_node.zbarrier ) )
		return false;

	//  128 units from its own entrance struct. Past that it cannot be at the
	//  attack spot, which stock reaches with goalradius 2.
	if ( distancesquared( self.origin, self.first_node.origin ) > 16384 )
		return false;

	zbarrier = self.first_node.zbarrier;
	n_pieces = zbarrier getnumzbarrierpieces();

	if ( n_pieces < 1 )
		return false;

	a_open = arraycombine( zbarrier getzbarrierpieceindicesinstate( "open" ), zbarrier getzbarrierpieceindicesinstate( "opening" ), 1, 0 );

	//  boards still standing at its own window - leave the zombie to stock
	return a_open.size < n_pieces;
}

// ----------------------------------------------------------------------------
//  zmqol_restart_find_flesh  -  put a zombie back on the player.
//
//  The notify first is what makes this safe to call on a zombie that might
//  still have a live find_flesh: it kills any running copy before the new one
//  starts, so there is never a second find_flesh fighting the first for the
//  zombie's goal. The frame of wait is for that kill to land.
// ----------------------------------------------------------------------------
zmqol_restart_find_flesh()
{
	self endon( "death" );

	self.zmqol_flesh_restarting = 1;

	self notify( "stop_find_flesh" );
	wait 0.05;

	self.ignoreme  = 0;
	self.ignoreall = 0;

	self thread maps\mp\zombies\_zm_ai_basic::find_flesh();

	//  A short cooldown so a zombie that is legitimately ignoreme for another
	//  reason cannot be re-threaded every single second.
	wait 3;
	self.zmqol_flesh_restarting = undefined;
}
disable_giant_robots()
{
	level endon( "intermission" );

	// ====================================================================
	//  🛑 v2.17.28 - LIVE SWITCH, FOR BISECTING THE ORIGINS AI BUG.
	//
	//      zmqol_no_robots 0     this function does nothing (robots stay)
	//      zmqol_no_robots 1     current behaviour (default)
	//
	//  WHY. BO2-Reimagined is where these Origins survival arenas were
	//  ported from, and its zombies behave. Diffing its Church loc script
	//  against ours, its main() is EIGHT calls and ours adds four threads
	//  on top - pap_built_pose, disable_giant_robots, force_prone_allowed,
	//  remove_challenge_boxes. Of those, this is the only one that touches
	//  the AI at all, let alone every second for the whole match: it walks
	//  getaiarray() and deletes.
	//
	//  Robots are also deleted roughly a second AFTER they spawn (the live
	//  log reads "deleted 1 this pass, 3 total on church"), i.e. mid
	//  behaviour, which is the kind of thing that leaves whatever they were
	//  interacting with in a half-finished state.
	//
	//  That makes it the first thing to rule in or out, and a dvar does it
	//  in one map reload instead of a rebuild. If the AI comes good with
	//  this off, the fix belongs here - stop the robots SPAWNING rather
	//  than deleting them after the fact.
	// ====================================================================
	if ( !getdvarintdefault( "zmqol_no_robots", 1 ) )
	{
		println( "[zm_qol] giant robots: zmqol_no_robots is 0 - sweep DISABLED, robots left alone (AI bisect)" );
		return;
	}

	flag_wait( "start_zombie_round_logic" );

	//  ------------------------------------------------------------------
	//  🛑 v2.17.10 - A ONE-SHOT SWEEP LOSES THE RACE. IT MUST BE A WATCHDOG.
	//
	//  v2.17.9 waited on this flag, slept 1s, then swept getaiarray() once.
	//  The log said it plainly: "removed 0 robot(s) and 6 stomp-kill
	//  trigger(s)" - the triggers are map entities and were there, the robots
	//  were not in getaiarray() at that instant. The user still had one
	//  walking through and shaking the screen.
	//
	//  Two reasons one pass cannot work:
	//    * giant_robot_initial_spawns() waits on the SAME flag, so whether its
	//      three spawnactor() calls have happened when we look is a coin toss.
	//    * robot_cycling() (threaded from that same function) keeps bringing
	//      robots in round after round, and giant_robot_intro_walk() is what
	//      walks one across the map. Deleting whatever exists at t+1s does
	//      nothing about round 4.
	//
	//  So: sweep every second for the whole match, and read level.a_giant_robots
	//  as well as getaiarray() - line 169 of the stock script is what fills it,
	//  and it is the handle the rest of the robot code uses.
	//  ------------------------------------------------------------------
	n_trigs = 0;

	for ( i = 0; i < 3; i++ )
	{
		t_right = getent( "trig_stomp_kill_right_" + i, "targetname" );
		t_left = getent( "trig_stomp_kill_left_" + i, "targetname" );

		if ( isdefined( t_right ) )
		{
			t_right delete();
			n_trigs++;
		}

		if ( isdefined( t_left ) )
		{
			t_left delete();
			n_trigs++;
		}
	}

	println( "[zm_qol] giant robots: " + n_trigs + " stomp-kill trigger(s) deleted (expect 6); robot watchdog now running for the match" );

	n_total = 0;

	for ( ;; )
	{
		n_this_pass = 0;

		if ( isdefined( level.a_giant_robots ) )
		{
			foreach ( robot in level.a_giant_robots )
			{
				if ( isdefined( robot ) )
				{
					robot delete();
					n_this_pass++;
				}
			}

			level.a_giant_robots = [];
		}

		a_ai = getaiarray();
		a_players = get_players();
		n_unfroze = 0;

		foreach ( ai in a_ai )
		{
			if ( !isdefined( ai ) )
				continue;

			if ( is_true( ai.is_giant_robot ) )
			{
				ai delete();
				n_this_pass++;
				continue;
			}

			// ------------------------------------------------------------
			//  🛑 v2.17.27 - UNFREEZE ANY ZOMBIE THE ROBOT TOUCHED.
			//
			//  User, 2026-09-16, on Church: *"the zombie like halfway swinged
			//  at me ... then stopped midway through and then just started
			//  walking towards me and it's not attacking me."* An attack that
			//  starts and is cut off is a zombie whose GOAL changed mid-swing.
			//
			//  maps\mp\zm_tomb_giant_robot::activate_kill_trigger walks every
			//  zombie within 600 units of a foot trigger and does BOTH:
			//        zombie.marked_for_death = 1;
			//        zombie setgoalpos( <its own origin> );
			//  i.e. "stand still and be crushed". The rest of the AI then
			//  treats a marked zombie as a corpse, and a zombie whose goal is
			//  where it already stands has arrived - it stops closing and
			//  never swings.
			//
			//  This arena DELETES the robots, so no zombie here should ever
			//  carry that mark - but the robots exist for up to a second
			//  before this watchdog reaches them (the log shows 3 deleted on
			//  Church), and that is long enough to mark everything nearby.
			//  Deleting the robot does not undo what it already did.
			//
			//  So: clear the mark and hand the goal back, every pass. Cheap,
			//  and it cannot affect a zombie that was never marked.
			// ------------------------------------------------------------
			if ( !is_true( ai.marked_for_death ) )
				continue;

			ai.marked_for_death = undefined;

			e_near = undefined;
			n_best = 0;

			for ( j = 0; j < a_players.size; j++ )
			{
				if ( !isdefined( a_players[j] ) || !isalive( a_players[j] ) )
					continue;

				n_d = distancesquared( ai.origin, a_players[j].origin );

				if ( !isdefined( e_near ) || n_d < n_best )
				{
					e_near = a_players[j];
					n_best = n_d;
				}
			}

			if ( isdefined( e_near ) )
				ai setgoalpos( e_near.origin );

			n_unfroze++;
		}

		if ( n_unfroze > 0 )
			println( "[zm_qol] giant robots: un-froze " + n_unfroze + " zombie(s) the robot had marked for death and re-targeted them at a player" );

		if ( n_this_pass > 0 )
		{
			n_total += n_this_pass;
			println( "[zm_qol] giant robots: deleted " + n_this_pass + " this pass, " + n_total + " total on " + getdvar( "ui_zm_mapstartlocation" ) );
		}

		wait 1;
	}
}

// ============================================================================
//  force_prone_allowed  -  belt and braces on top of disable_giant_robots
//
//  Removing the robots removes the only allowprone( 0 ) on the map, but the
//  user hit this bug once before (over a month ago, their words) and a switch
//  that is only ever turned off by code we deleted is cheap to turn back on.
//  Re-asserted on every spawn so a mid-match edge case cannot leave it stuck.
// ============================================================================
//  🛑 v2.17.12 - THE FIRST VERSION NEVER RAN FOR THE PLAYER WHO WAS ALREADY
//  THERE, WHICH IN SOLO IS EVERY PLAYER.
//
//  User: *"I was able to prone at one point, now I'm back to not being able to
//  ... you undid that fix."* The wiring was never undone - all four arenas still
//  call this - it simply never did anything. Two ordering mistakes, both mine:
//
//    * `level waittill( "connected", player )` only fires for a player who
//      connects AFTER the thread starts. The loc script's main() runs after the
//      player is already in, so in a solo match that notify never comes.
//    * `self waittill( "spawned_player" )` has the same problem - by the time
//      the thread exists the spawn has happened, so it waits for the NEXT one.
//
//  Prone appeared to work in the earlier build only because the robots were
//  being deleted before they got the chance to call allowprone( 0 ); it was
//  never this function doing it. Now: assert it for everyone already here,
//  keep listening for late joiners, and re-assert on a short loop so nothing
//  can leave it stuck off for more than a second.
force_prone_allowed()
{
	level endon( "intermission" );

	//  Everyone already connected - the case the old version missed entirely.
	a_players = get_players();

	foreach ( player in a_players )
	{
		if ( isdefined( player ) )
			player thread force_prone_allowed_for_player();
	}

	for ( ;; )
	{
		level waittill( "connected", player );

		if ( isdefined( player ) )
			player thread force_prone_allowed_for_player();
	}
}

force_prone_allowed_for_player()
{
	self endon( "disconnect" );

	//  Guard against double-threading: force_prone_allowed() seeds every player
	//  present and then also catches "connected", and a reconnect could land in
	//  both paths.
	if ( is_true( self.zmqol_prone_watch ) )
		return;

	self.zmqol_prone_watch = 1;

	//  Immediately, not on the next spawn - see the banner.
	self allowprone( 1 );

	for ( ;; )
	{
		wait 1;

		//  Not while the robot-head/eject path legitimately owns the stance.
		//  With the robots deleted that flag never gets set, but if some other
		//  sequence ever does, this must not fight it.
		if ( is_true( self.giant_robot_transition ) )
			continue;

		self allowprone( 1 );
	}
}

register_pap_struct_built( model, origin, angles )
{
	s_pap = spawnstruct();
	s_pap.targetname = "zm_perk_machine";
	s_pap.script_noteworthy = "specialty_weapupgrade";
	s_pap.model = model;
	s_pap.origin = origin;
	s_pap.angles = angles;

	//  No .target - that is the whole fix. See the banner.
	scripts\zm\replaced\utility::add_struct( s_pap );
}

spawn_wallbuy_plywood( origin, angles )
{
	model1 = spawn( "script_model", origin );
	model1.angles = angles + ( -90, 0, 0 );
	model1 setmodel( "p6_pak_old_plywood_small" );

	model2 = spawn( "script_model", origin + anglestoforward( angles ) * 2 + anglestoup( angles ) * -15 );
	model2.angles = angles + ( 0, 90, 0 );
	model2 setmodel( "p6_zm_tm_wood_post_thin_01_tall" );

	model3 = spawn( "script_model", origin + anglestoforward( angles ) * 1 + anglestoright( angles ) * -25 + anglestoup( angles ) * -15 );
	model3.angles = angles;
	model3 setmodel( "p6_zm_tm_wood_post_thin_01_tall" );

	model4 = spawn( "script_model", origin + anglestoforward( angles ) * 1 + anglestoright( angles ) * 25 + anglestoup( angles ) * -15 );
	model4.angles = angles + ( 0, 180, 0 );
	model4 setmodel( "p6_zm_tm_wood_post_thin_01_tall" );
}
