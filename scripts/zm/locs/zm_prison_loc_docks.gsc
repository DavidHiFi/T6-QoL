#include maps\mp\zombies\_zm_utility;
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zm_prison;
#include maps\mp\zombies\_zm_zonemgr;

struct_init()
{
	level.struct_class_names["targetname"]["zm_perk_machine"] = [];

	scripts\zm\replaced\utility::register_perk_struct("specialty_armorvest", "zombie_vending_jugg", (473.92, 6638.99, 208), (0, 102, 0));
	scripts\zm\replaced\utility::register_perk_struct("specialty_grenadepulldeath", "p6_zm_vending_electric_cherry_off", (-627, 6982, 63), (0, 100, 0));
	//  PaP through loc_common so it draws BUILT, not the "please wait" pose -
	//  see the banner on loc_common::register_pap_struct_built.
	scripts\zm\locs\loc_common::register_pap_struct_built("p6_zm_al_vending_pap_on", (-1769, 5395, -72), (0, 100, 0));

	level.struct_class_names["script_noteworthy"]["initial_spawn"] = [];

	player_respawn_points = [];

	foreach (player_respawn_point in level.struct_class_names["targetname"]["player_respawn_point"])
	{
		if (player_respawn_point.script_noteworthy == "zone_dock")
		{
			i = 0;
			respawn_array = getstructarray(player_respawn_point.target, "targetname");

			foreach (respawn in respawn_array)
			{
				if (respawn.origin == (-664, 5944, 0))
				{
					continue;
				}

				script_int = int(i / 2) + 1;

				origin = respawn.origin + (anglesToRight(respawn.angles) * 32);
				angles = respawn.angles;

				scripts\zm\replaced\utility::register_map_spawn(origin, angles, player_respawn_point.script_noteworthy, script_int);

				origin = respawn.origin + (anglesToRight(respawn.angles) * -32);
				angles = respawn.angles;

				scripts\zm\replaced\utility::register_map_spawn(origin, angles, player_respawn_point.script_noteworthy, script_int);

				i++;
			}

			player_respawn_points[player_respawn_points.size] = player_respawn_point;
		}
		else if (player_respawn_point.script_noteworthy == "zone_dock_gondola")
		{
			player_respawn_points[player_respawn_points.size] = player_respawn_point;
		}
		//  v2.17.9 - the Pack-a-Punch side of the 2000 gate. It was dropped here
		//  for as long as zone_dock_puzzle could never be enabled, which made it
		//  dead weight; the zone edge restored in
		//  scripts\zm\replaced\zm_prison.gsc::working_zone_init() now opens that
		//  zone when the gate is bought, and enable_zone() unlocks exactly the
		//  respawn points whose script_noteworthy matches the zone it opened
		//  (_zm_zonemgr.gsc:459-468). Keeping this one is what gives a player who
		//  goes down at Pack-a-Punch somewhere on that side to come back.
		//  Locked until then, so it changes nothing before the purchase.
		else if (player_respawn_point.script_noteworthy == "zone_dock_puzzle")
		{
			player_respawn_points[player_respawn_points.size] = player_respawn_point;
		}
		else if (player_respawn_point.script_noteworthy == "zone_studio")
		{
			player_respawn_points[player_respawn_points.size] = player_respawn_point;
		}
		else if (player_respawn_point.script_noteworthy == "zone_citadel_basement_building")
		{
			player_respawn_points[player_respawn_points.size] = player_respawn_point;
		}
	}

	level.struct_class_names["targetname"]["player_respawn_point"] = player_respawn_points;

	level.struct_class_names["targetname"]["intermission"] = [];

	intermission_cam = spawnStruct();
	intermission_cam.origin = (402, 6197, 142);
	intermission_cam.angles = (0, 190, 0);
	intermission_cam.targetname = "intermission";
	intermission_cam.script_string = "docks";
	intermission_cam.speed = 30;
	intermission_cam.target = "intermission_docks_end";
	scripts\zm\replaced\utility::add_struct(intermission_cam);

	intermission_cam_end = spawnStruct();
	intermission_cam_end.origin = (-1043, 5931, -47);
	intermission_cam_end.angles = (0, 190, 0);
	intermission_cam_end.targetname = "intermission_docks_end";
	scripts\zm\replaced\utility::add_struct(intermission_cam_end);
}

precache()
{
	setdvar("disableLookAtEntityLogic", 1);
	level.chests = [];
	level.chests[0] = getstruct("dock_chest", "script_noteworthy");

	// zm_qol: added - see the note in zm_transit_loc_diner.gsc::precache.
	precachemodel( "afr_corrugated_metal4x8_holes" );
	precachemodel( "collision_wall_128x128x10_standard" );
	precachemodel( "p6_zm_al_desk_small" );
	precachemodel( "p6_zm_al_horrific_bed_mattress_3" );
	precachemodel( "p6_zm_al_infirmary_case" );

	//  🛑 p6_zm_al_shock_box_on IS NOT LOADED IN SURVIVAL - see the banner on
	//  zmqol_docks_shockbox_on_loaded(). Precaching it anyway is what put the
	//  engine's black placeholder model next to Juggernog.
	if ( zmqol_docks_shockbox_on_loaded() )
	{
		precachemodel( "p6_zm_al_shock_box_on" );
	}

	precachemodel( "p6_zm_buildable_bench_tarp" );
	precachemodel( "zm_al_kitchen_table_01" );
	precachemodel( "zm_collision_perks1" );   // loc_common::increase_pap_collision
}

main()
{
	flag_set("gondola_roof_to_dock");
	init_barriers();
	generatebuildabletarps();
	set_box_weapons();
	disable_zombie_spawn_locations();
	disable_gondola_call_triggers();
	disable_craftable_triggers();
	disable_afterlife_props();
	disable_wolf_hurt_triggers();
	create_key_door_unitrigger(4, 98, 112, 108);
	level thread open_inner_gate();
	level thread turn_afterlife_interacts_on();
	maps\mp\gametypes_zm\_zm_gametype::setup_standard_objects("cellblock");
	maps\mp\zombies\_zm_magicbox::treasure_chest_init("dock_chest");
	precacheshader("zm_al_wth_zombie");
	array_thread(level.zombie_spawners, ::add_spawn_function, maps\mp\zm_alcatraz_grief_cellblock::remove_zombie_hats_for_grief);
	maps\mp\zombies\_zm_ai_brutus::precache();
	maps\mp\zombies\_zm_ai_brutus::init();
	scripts\zm\locs\loc_common::increase_pap_collision();
	level thread scripts\zm\locs\loc_common::init();
	level thread maps\mp\zm_alcatraz_traps::init_tower_trap_trigs();
	level thread report_docks_state();
}

// ============================================================================
//  report_docks_state  -  three lines, print-only, no entities touched.
//
//  Each one is the load-time evidence for a v2.17.9 fix, so a log tail says
//  whether the build in front of you has them without needing a playthrough:
//
//    pap zone     registered=1 is what the "death barrier" fix buys. Before it,
//                 nothing ever called zone_init("zone_dock_puzzle"), so the zone
//                 did not exist, its player_volume counted for nothing and
//                 _zm.gsc's out-of-area monitor killed anyone through the gate.
//                 enabled=0 here is CORRECT - it opens on the 2000 purchase.
//    shock box    loaded=0 means the run skipped the classic-only
//                 p6_zm_al_shock_box_on, i.e. no black placeholder props.
//    (the Wunderfizz line is printed by zmqol_wf_place() itself.)
// ============================================================================
report_docks_state()
{
	//  🛑 THREADED WITH A BOUNDED WAIT, because this runs at map-load time and
	//  the answer is only meaningful after the zone manager has built the zones.
	//  manage_zones() is threaded from maps\mp\zm_prison::main() and calls
	//  working_zone_init() before its first wait, but nothing guarantees that
	//  lands before this location's main() - and a report that prints 0 because
	//  it asked too early is worse than no report. Five seconds is far longer
	//  than it has ever taken; the same shape as the waits in wunderfizz.gsc.
	n_wait = 0;

	while ( n_wait < 100 )
	{
		if ( isdefined( level.zones ) && isdefined( level.zones[ "zone_dock" ] ) )
		{
			break;
		}

		wait 0.05;
		n_wait++;
	}

	//  📝 No ternaries anywhere in this file - T6 GSC has no ?: operator.
	n_registered = 0;
	n_enabled = 0;
	n_box = 0;

	if ( isdefined( level.zones ) && isdefined( level.zones[ "zone_dock_puzzle" ] ) )
	{
		n_registered = 1;

		if ( zone_is_enabled( "zone_dock_puzzle" ) )
		{
			n_enabled = 1;
		}
	}

	if ( zmqol_docks_shockbox_on_loaded() )
	{
		n_box = 1;
	}

	println( "[zm_qol] docks: pap zone_dock_puzzle registered=" + n_registered +
	         " enabled=" + n_enabled + " (enabled turns 1 when the 2000 gate is bought)" );
	println( "[zm_qol] docks: shock_box_on loaded=" + n_box +
	         " - 0 keeps the map's own _off boxes instead of the black placeholder" );
}

//  📝 The v1.12.x zmqol_docks_probe() diagnostic that used to sit here was
//  deleted before shipping. The Docks invisibility bug it measured is fixed at
//  the source - replaced\zm_alcatraz_gamemodes.gsc points givecustomcharacters
//  at maps\mp\zm_prison::init_characters, so the MotD grief models that a
//  zstandard run never loads are no longer set. Reads-only probe, nothing
//  gameplay depended on it.

set_box_weapons()
{
	if (isDefined(level.zombie_weapons["thompson_zm"]))
	{
		level.zombie_weapons["thompson_zm"].is_in_box = 0;
	}

	if (isDefined(level.zombie_weapons["beretta93r_zm"]))
	{
		level.zombie_weapons["beretta93r_zm"].is_in_box = 1;
	}
}

init_barriers()
{
	// citadel basement left
	scripts\zm\locs\loc_common::barrier("collision_wall_128x128x10_standard", (-106.911, 7636.47, 64.125), (0, 0, 0), 1);
	scripts\zm\locs\loc_common::barrier("p6_zm_al_horrific_bed_mattress_3", (-90.4585, 7669.56, 114.511), (90, -10, 55));
	scripts\zm\locs\loc_common::barrier("zm_al_kitchen_table_01", (-111.549, 7667.96, 97.125), (0, 0, 90));
	scripts\zm\locs\loc_common::barrier("afr_corrugated_metal4x8_holes", (-113.959, 7638.7, 75.0369), (6, 0, -6));

	// citadel basement right
	scripts\zm\locs\loc_common::barrier("collision_wall_128x128x10_standard", (43.2479, 7606.2, 66.125), (0, -45, 0), 1);
	scripts\zm\locs\loc_common::barrier("p6_zm_al_infirmary_case", (48.6213, 7639.88, 74.125), (22, -44, 0));
	scripts\zm\locs\loc_common::barrier("afr_corrugated_metal4x8_holes", (44.9895, 7601.56, 81.125), (-5, -41, -8));
	scripts\zm\locs\loc_common::barrier("p6_zm_al_desk_small", (98.769, 7602.89, 64.125), (0, -142, 0));
}

generatebuildabletarps()
{
	model = spawn("script_model", (432.836, 6238.03, 55.997));
	model.angles = (0, 100, 0);
	model setmodel("p6_zm_buildable_bench_tarp");
}

disable_zombie_spawn_locations()
{
	for (z = 0; z < level.zone_keys.size; z++)
	{
		zone = level.zones[level.zone_keys[z]];

		i = 0;

		while (i < zone.spawn_locations.size)
		{
			if (zone.spawn_locations[i].origin == (615.8, 7875.9, 95))
			{
				zone.spawn_locations[i].is_enabled = false;
			}
			else if (zone.spawn_locations[i].origin == (663.8, 7827.9, 95))
			{
				zone.spawn_locations[i].is_enabled = false;
			}

			i++;
		}
	}
}

disable_gondola_call_triggers()
{
	t_call_triggers = getentarray("gondola_call_trigger", "targetname");

	foreach (trigger in t_call_triggers)
	{
		trigger delete();
	}
}

disable_craftable_triggers()
{
	t_crafting_table = getentarray("open_craftable_trigger", "targetname");

	foreach (trigger in t_crafting_table)
	{
		trigger delete();
	}
}

// ============================================================================
//  disable_wolf_hurt_triggers  -  the instant death on the way to Pack-a-Punch
//
//  🛑 v2.17.7 - USER DIED WALKING TO THE PACK-A-PUNCH. 2026-09-15, after paying
//  2000 for the gate: *"there was like a death zone just before the Pack-a-Punch
//  machine and I instantly died."*
//
//  MEASURED, NOT GUESSED. zm_prison's mapents carry five trigger_hurt volumes.
//  Taking each one's distance to the nearest Docks arena spawn point, exactly
//  one is inside the arena:
//        wolf_hurt_trigger_docks   (19, 6252, 129)   410 units from a spawn
//  The other four are up at the cellblock/warden end, 4000+ away.
//  (Audit: modding-jobs\locs-restore-001\death_zones.py. The same sweep finds
//  ZERO trigger_hurt on zm_tomb and zm_buried, so Trenches, Church, Excavation
//  Site and Maze cannot have this bug - that is checked, not assumed.)
//
//  WHY IT IS LIVE IN SURVIVAL. It belongs to Hell's Retriever:
//  maps\mp\zm_alcatraz_weap_quest::soul_catcher_state_manager() hide()s it at
//  start and show()s it again after "first_zombie_killed_in_zone". That manager
//  only runs on the classic quest path, so in a survival run NOTHING ever hides
//  it and it is hot from the moment the map loads.
//
//  Deleted rather than hidden, matching the gondola/craftable/afterlife
//  disables above: with no quest there is no legitimate state in which this
//  trigger should ever fire on this location.
//
//  📝 Scoped to the Docks loc script on purpose. wolf_hurt_trigger (the other
//  one) sits by the cellblock and is left alone - Cell Block is a separately
//  shipped location and this change must not alter it.
// ============================================================================
disable_wolf_hurt_triggers()
{
	// ------------------------------------------------------------------------
	//  🛑 v2.17.8 - WIDENED FROM ONE TRIGGER TO ALL OF THEM, AFTER THE NARROW
	//  FIX DID NOT HOLD.
	//
	//  v2.17.7 deleted only wolf_hurt_trigger_docks. The log confirms that ran
	//  ("removed 1 wolf_hurt_trigger_docks") and the user died anyway, in the
	//  gated area on the way to Pack-a-Punch, at full health. So the killer was
	//  one of the OTHER four, or a second one of the same class, and picking
	//  them off one boot at a time is not a fix - it is a guessing loop.
	//
	//  🌟 SO: EVERY trigger_hurt ON THE MAP GOES, and the count is logged.
	//  zm_prison ships exactly five and not one of them can legitimately fire in
	//  a survival run - every one belongs to a mechanic this gametype does not
	//  have:
	//        wolf_hurt_trigger / wolf_hurt_trigger_docks   Hell's Retriever,
	//            hidden and shown by zm_alcatraz_weap_quest::
	//            soul_catcher_state_manager(), which only runs on the classic
	//            quest path - so in survival nothing ever hides them
	//        pulley_hurt_trigger_west / _east              the plane-build pulley
	//        warden_fence_damage                           warden's-house fence
	//
	//  With no quest and no plane build, there is no state in which any of them
	//  should hurt a player here, so "delete them all" is the correct scope
	//  rather than a blunt one.
	//
	//  📝 SCOPED TO THIS LOC SCRIPT, so Cell Block - a separately shipped
	//  location that uses the same map - is untouched. Nothing here runs unless
	//  the Docks location is the one that loaded.
	// ------------------------------------------------------------------------
	a_hurt = getentarray("trigger_hurt", "classname");
	n_removed = 0;

	foreach (trigger in a_hurt)
	{
		if (isdefined(trigger))
		{
			println("[zm_qol] docks: deleting trigger_hurt '" + trigger.targetname + "' at (" + int(trigger.origin[0]) + "," + int(trigger.origin[1]) + "," + int(trigger.origin[2]) + ")");
			trigger delete();
			n_removed++;
		}
	}

	println("[zm_qol] docks: removed " + n_removed + " trigger_hurt volume(s) - quest/trap kills that are never gated in survival (expect 5)");
}

disable_afterlife_props()
{
	a_afterlife_props = getentarray("afterlife_show", "targetname");

	foreach (m_prop in a_afterlife_props)
	{
		m_prop delete();
	}
}

turn_afterlife_interacts_on()
{
	a_afterlife_interact = getentarray("afterlife_interact", "targetname");

	foreach (model in a_afterlife_interact)
	{
		if (model.script_string == "juggernog_on" || model.script_string == "additionalprimaryweapon_on")
		{
			model turn_afterlife_interact_on();
			wait 0.1;
		}
	}

	m_docks_shockbox = getent("docks_panel", "targetname");
	m_docks_shockbox turn_afterlife_interact_on();

	//  Read the models BACK off the entities rather than reporting what this
	//  function meant to do. The engine draws whatever setmodel() last set, so
	//  "_off" on every line is the direct evidence that no classic-only
	//  placeholder can be on screen - which is the whole of the black-box fix.
	//  Three boxes, all in the Docks arena: Juggernog (472, 6596, 208), the
	//  three-gun one (-637, 6931, 65) and the panel by the 2000 gate
	//  (-1476, 5345, -72).
	foreach (model in a_afterlife_interact)
	{
		if (!isdefined(model))
		{
			continue;
		}

		//  Only the two this function actually switched. getentarray picks up all
		//  18 afterlife_interact props on the map, most of them up at the
		//  cellblock end and none of this location's business.
		if (model.script_string != "juggernog_on" && model.script_string != "additionalprimaryweapon_on")
		{
			continue;
		}

		println("[zm_qol] docks: shock box '" + model.script_string + "' model=" + model.model);
	}

	if (isdefined(m_docks_shockbox))
	{
		println("[zm_qol] docks: shock box 'docks_panel' model=" + m_docks_shockbox.model);
	}
}

// ============================================================================
//  zmqol_docks_shockbox_on_loaded  -  does THIS gametype load the "on" box?
//
//  🛑 v2.17.9 - THE BLACK BOX NEXT TO JUGGERNOG. User, 2026-09-16, with a
//  screenshot taken at (564, 6616, 216) yaw 193 pitch 35: *"there's this weird
//  black box to the left of it ... that's a weird bug."* The crosshair in that
//  shot lands 2 units off the afterlife shock box at (472.3, 6595.9, 208) - the
//  juggernog_on one - so the black rectangle IS that prop.
//
//  🌟 IT IS AN ASSET-OWNERSHIP BUG, MEASURED WITH THE OAT UNLINKER, not a
//  material or lighting one. Listing the four Alcatraz fastfiles:
//
//      p6_zm_al_shock_box_off   xmodel + mc/mtl_..._off   zm_prison.ff
//      p6_zm_al_shock_box_ON    xmodel + mc/mtl_..._on    so_zclassic_zm_prison.ff
//                                                         so_zencounter_zm_prison.ff
//
//  There is no so_zsurvival_zm_prison.ff (TranZit is the only map with one, as
//  the banner in scripts\zm\replaced\zm_alcatraz_gamemodes.gsc already
//  established), so a zstandard run loads zm_prison + zm_prison_patch and the
//  "on" model is simply not there. precachemodel() on a missing xmodel does not
//  fail on Plutonium - it hands back the engine's placeholder, and setmodel()
//  then draws that placeholder: an untextured black box.
//
//  Same class as the invisible-character bug this location already fixed, just
//  the other way round: that one setmodel()'d a missing model WITHOUT
//  precaching and drew nothing; this one precached first and drew the
//  placeholder.
//
//  📝 THE ANIMS ARE FINE and are deliberately left alone - fxanim_zom_al_shock
//  _box_on_anim / _off_anim both live in zm_prison.ff, so they load in every
//  mode. Only the two "on" assets are classic/grief-only.
//
//  Gating on is_classic() || is_encounter() is gating on exactly the two
//  gamemodegroups whose so_* fastfile carries the model ("zclassic" /
//  "zencounter", maps\mp\zombies\_zm_utility.gsc:19 and :429), which is why
//  this is a fastfile test written as a gametype test and not a guess.
// ============================================================================
zmqol_docks_shockbox_on_loaded()
{
	return ( is_classic() || is_encounter() );
}

#using_animtree("fxanim_props");

turn_afterlife_interact_on()
{
	if (!isDefined(level.shockbox_anim))
	{
		level.shockbox_anim["on"] = %fxanim_zom_al_shock_box_on_anim;
		level.shockbox_anim["off"] = %fxanim_zom_al_shock_box_off_anim;
	}

	if (issubstr(self.model, "p6_zm_al_shock_box"))
	{
		//  🛑 SURVIVAL LEAVES THE PROP COMPLETELY ALONE, and that is the whole
		//  fix. The map's own p6_zm_al_shock_box_off is already standing there
		//  and already renders correctly; the only thing this function was
		//  adding in zstandard was the placeholder.
		//
		//  📝 NOT "off model + on anim". The _on_anim is authored against the
		//  _on model's rig - stock only ever plays it after swapping the model
		//  (zm_alcatraz_grief_cellblock.gsc:547-552) - so driving it on the
		//  _off rig risks trading a black box for a deformed one. There is
		//  nothing to gain: this whole function is cosmetic here. The perks
		//  come from register_perk_struct(), not from an afterlife switch, and
		//  disable_afterlife_props() has already deleted the afterlife dressing.
		if (!zmqol_docks_shockbox_on_loaded())
		{
			return;
		}

		self useanimtree(#animtree);
		self setmodel("p6_zm_al_shock_box_on");
		self setanim(level.shockbox_anim["on"]);
	}
}

create_key_door_unitrigger(piece_num, width, height, length)
{
	t_key_door = getstruct("key_door_" + piece_num + "_trigger", "targetname");
	t_key_door.unitrigger_stub = spawnstruct();
	t_key_door.unitrigger_stub.origin = t_key_door.origin;
	t_key_door.unitrigger_stub.angles = t_key_door.angles;
	t_key_door.unitrigger_stub.script_unitrigger_type = "unitrigger_box_use";
	t_key_door.unitrigger_stub.hint_string = &"ZM_PRISON_KEY_DOOR_LOCKED";
	t_key_door.unitrigger_stub.cursor_hint = "HINT_NOICON";
	t_key_door.unitrigger_stub.script_width = width;
	t_key_door.unitrigger_stub.script_height = height;
	t_key_door.unitrigger_stub.script_length = length;
	t_key_door.unitrigger_stub.n_door_index = piece_num;
	t_key_door.unitrigger_stub.require_look_at = 0;
	t_key_door.unitrigger_stub.ignore_player_valid = 1;
	t_key_door.unitrigger_stub.prompt_and_visibility_func = ::key_door_trigger_visibility;
	t_key_door.unitrigger_stub.cost = 2000;
	maps\mp\zombies\_zm_unitrigger::register_static_unitrigger(t_key_door.unitrigger_stub, ::master_key_door_trigger_thread);
}

key_door_trigger_visibility(player)
{
	self sethintstring(&"ZOMBIE_BUTTON_BUY_OPEN_DOOR_2000");

	return 1;
}

master_key_door_trigger_thread()
{
	self endon("death");
	self endon("kill_trigger");
	n_door_index = self.stub.n_door_index;
	b_door_open = 0;

	while (!b_door_open)
	{
		self waittill("trigger", e_triggerer);

		if (is_player_valid(e_triggerer) || is_true(e_triggerer.is_zombie))
		{
			if (!is_true(e_triggerer.is_zombie))
			{
				if (e_triggerer.score >= self.stub.cost)
				{
					e_triggerer maps\mp\zombies\_zm_score::minus_to_player_score(self.stub.cost);
					e_triggerer play_sound_on_ent("purchase");
				}
				else
				{
					play_sound_at_pos("no_purchase", self.stub.origin);
					continue;
				}
			}

			self.stub.master_key_door_opened = 1;
			self.stub maps\mp\zombies\_zm_unitrigger::run_visibility_function_for_all_triggers();
			level thread open_custom_door_master_key(n_door_index, e_triggerer);
			self playsound("evt_quest_door_open");
			b_door_open = 1;
		}
	}

	level thread maps\mp\zombies\_zm_unitrigger::unregister_unitrigger(self.stub);
}

open_custom_door_master_key(n_door_index, e_triggerer)
{
	m_lock = getent("masterkey_lock_" + n_door_index, "targetname");
	m_lock playsound("zmb_quest_key_unlock");
	playfxontag(level._effect["fx_alcatraz_unlock_door"], m_lock, "tag_origin");
	wait 0.5;
	m_lock delete();

	m_gate_01 = getent("cable_puzzle_gate_01", "targetname");
	m_gate_01 moveto(m_gate_01.origin + (-16, 80, 0), 0.5);
	m_gate_01 connectpaths();
	gate_1_monsterclip = getent("docks_gate_1_monsterclip", "targetname");
	gate_1_monsterclip.origin += vectorscale((0, 0, 1), 256.0);
	gate_1_monsterclip disconnectpaths();
	gate_1_monsterclip.origin -= vectorscale((0, 0, 1), 256.0);

	if (isdefined(e_triggerer))
	{
		e_triggerer door_rumble_on_open();
	}

	m_gate_01 playsound("zmb_chainlink_open");
	flag_set("docks_inner_gate_unlocked");
	flag_set("docks_inner_gate_open");

	//  The other half of report_docks_state(): "docks_inner_gate_unlocked" is the
	//  flag the restored zone edge waits on, and zone_flag_wait() enables the
	//  zone on the next pass, so give it one frame before reading it back.
	//  enabled=1 here is the proof that the Pack-a-Punch side is now playable
	//  area; enabled=0 would mean the out-of-area kill is still armed.
	wait 0.05;
	n_enabled = 0;

	if ( isdefined( level.zones ) && isdefined( level.zones[ "zone_dock_puzzle" ] ) && zone_is_enabled( "zone_dock_puzzle" ) )
	{
		n_enabled = 1;
	}

	println( "[zm_qol] docks: 2000 gate bought - zone_dock_puzzle enabled=" + n_enabled );
}

door_rumble_on_open()
{
	self endon("disconnect");
	level endon("end_game");
	self setclientfieldtoplayer("rumble_door_open", 1);
	wait_network_frame();
	self setclientfieldtoplayer("rumble_door_open", 0);
}

open_inner_gate()
{
	m_gate_02 = getent("cable_puzzle_gate_02", "targetname");

	m_gate_02 moveto(m_gate_02.origin + (-16, 80, 0), 0.5);
	wait(0.75);
	m_gate_02 connectpaths();
	gate_2_monsterclip = getent("docks_gate_2_monsterclip", "targetname");
	gate_2_monsterclip.origin += vectorscale((0, 0, 1), 256.0);
	gate_2_monsterclip disconnectpaths();
	gate_2_monsterclip.origin -= vectorscale((0, 0, 1), 256.0);
}