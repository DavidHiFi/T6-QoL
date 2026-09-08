#include maps\mp\zombies\_zm_utility;
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_zonemgr;

// ============================================================================
//  ORIGINS SURVIVAL - THE CRAZY PLACE                               (v2.14.0)
// ----------------------------------------------------------------------------
//  User, 2026-09-06: *"add crazy place survival for origins from the reimagined
//  mod into my mod"*.
//
//  Ported from BO2-Reimagined's scripts\zm\locs\zm_tomb_loc_crazy_place.gsc.
//  The arena is Origins' elemental chamber - the nine zone_chamber_* zones you
//  normally only reach through the four elemental teleporters - sealed off and
//  played as a standalone survival map.
//
//  ============================================================================
//  🛑 THE ONE REAL DIFFERENCE FROM REIMAGINED, AND WHY
//  ----------------------------------------------------------------------------
//  Reimagined does not do this in script at all. It ships a MODIFIED
//  zm_tomb.d3dbsp (its mapents), and the 13 entities that make this arena
//  playable are baked into it - four wall-buys, four perk machines and a
//  Pack-a-Punch, each tagged "zstandard_crazy_place, zgrief_crazy_place".
//  Parsed out of their file and diffed against the stock mapents, so these are
//  their coordinates verbatim, not eyeballed ones.
//
//  This mod does NOT ship an Origins mapents file, and adding one would put
//  those entities into CLASSIC Origins as well. Everything is registered from
//  script instead, in struct_init(), which runs inside struct_class_init() -
//  before _zm_perks::init() and _zm_weapons::init_spawnable_weapon_upgrade()
//  read the struct lists - and only for this gametype+location. Classic Origins
//  never sees any of it. The same technique already ships in this mod for
//  Borough's seven perk machines and the Diner's semtex and claymore wall-buys.
//
//  ⚠️ ONE THING THAT COULD NOT COME WITH IT: Reimagined SHUFFLES the four
//  wall-buys between the four pillars on every match (weapon_fx() in their
//  copy). That only works because their mapents tag those structs
//  "disable_clientfield" and their own _zm_weapons replacement then skips the
//  client half entirely and draws the gun server-side. Stock registers one
//  "world" clientfield per wall-buy NAMED "<weapon>_<origin>" on BOTH sides
//  (_zm_weapons.gsc:1290 / _zm_weapons.csc:225), so a server-side shuffle would
//  leave the client registering four different names - EXE_CLIENT_FIELD_MISMATCH
//  at load, the exact failure class in ERROR_CATALOGUE. The four wall-buys are
//  therefore fixed to Reimagined's four pillar positions. The PERK shuffle is
//  pure server-side entity work and IS ported, untouched.
//  ============================================================================
//
//  NOT PORTED, and stated rather than hidden:
//    * level.perk_require_look_at_func and level.pap_rotate_on_trigger. Both
//      are Reimagined-only extension points that live inside their own copy of
//      _zm_perks.gsc (:664, :1112, :1335). Setting them here without that file
//      would be two lines that do nothing. Making them real means replacing
//      _zm_perks::vending_trigger_think (235 lines) and vending_weapon_upgrade
//      on Origins for CLASSIC play too, to spare the player having to look at a
//      floating perk bottle they are standing inside of. Not worth that trade;
//      see the hand-off notes.
//    * (v2.14.22 - NO LONGER TRUE) There used to be no mystery box inside the
//      arena: Origins' six chests are all outside the chamber, and Reimagined's
//      treasure_chest_init(), ported verbatim, handed the box those six
//      unreachable positions. User, 2026-09-08: *"add a mystery box to this
//      survival map ... make sure it's the origins mystery box ... not too far
//      away from these pillars, not too close/clipping into them"*. One of
//      Treyarch's own chests is now MOVED into the chamber - see
//      zmqol_cp_bring_chest_into_arena() - and it is the only chest the box
//      logic knows about, so it never leaves. The two stock chamber wall-buys
//      (mp44_zm at (9450, -7284, -330) and ak74u_zm at (11188, -8379, -358),
//      both untagged in the stock mapents) still spawn here as before.
//    * (v2.14.22 - NO LONGER TRUE) The mod's Der Wunderfizz used to mirror
//      Origins' six native machine positions, all outside the chamber. On this
//      location scripts\zm\wunderfizz.gsc now places ONE machine inside the
//      arena instead (v2.14.23) - see the crazy_place branch inside its
//      zm_tomb block, and zmqol_wf_place() for the adjusters it now runs.
//    * (v2.14.23, redone v2.14.25) The Pack-a-Punch machine stands BUILT - the
//      six stone pieces up, as on classic Origins once every generator is
//      captured. The pose is drawn the way stock draws it: by a CLIENT model
//      (scripts\zm\zm_tomb\zm_tomb.csc::zmqol_cp_pap_client_model), with the
//      server's own machine ghosted - see zmqol_cp_pap_built_pose() below for
//      why the v2.14.23 server-side animation could not work. And it is the
//      ONLY Pack-a-Punch on the location: the map's own struct is dropped from
//      the struct index in struct_init() (zmqol_cp_drop_map_pap_structs),
//      which is what makes the INSTANT PAP switch land on this machine instead
//      of the one at the Excavation Site.
//    * (v2.14.25) The box has COLLISION (two collision_geo_64x64x64_standard
//      clips, spawned with it - stock's box collision is world clip that stays
//      in the bunker), its light is GREEN (the powered look every captured-
//      generator box has on classic Origins: zbarrier state "player_controlled"
//      + magicbox_runes), and its wall is found by a nine-ray fan fitted to a
//      line instead of one ray's normal. `.boxhere` moves it live for tuning.
//
//  Panzer Soldat: nothing to do. Reimagined has to return early from
//  mechz_round_tracker() on this location because their copy skips the
//  flag_wait; STOCK's tracker (_zm_ai_mechz.gsc:317) waits on
//  flag "activate_zone_nml", which no chamber game ever sets, so the Panzer
//  round simply never arrives. Verified in the stock source, not assumed.
// ============================================================================

struct_init()
{
	zone = "zone_chamber_4";

	// --- player spawns: Reimagined's eight, verbatim -------------------------
	scripts\zm\replaced\utility::register_map_spawn( (10479, -7963, -420), (0, 157.5, 0), zone, 1 );
	scripts\zm\replaced\utility::register_map_spawn( (10479, -7849, -420), (0, 202.5, 0), zone, 1 );
	scripts\zm\replaced\utility::register_map_spawn( (10397, -7767, -420), (0, 247.5, 0), zone, 1 );
	scripts\zm\replaced\utility::register_map_spawn( (10283, -7767, -420), (0, 292.5, 0), zone, 1 );
	scripts\zm\replaced\utility::register_map_spawn( (10201, -7849, -420), (0, 337.5, 0), zone, 2 );
	scripts\zm\replaced\utility::register_map_spawn( (10201, -7963, -420), (0, 22.5, 0), zone, 2 );
	scripts\zm\replaced\utility::register_map_spawn( (10283, -8045, -420), (0, 67.5, 0), zone, 2 );
	scripts\zm\replaced\utility::register_map_spawn( (10397, -8045, -420), (0, 112.5, 0), zone, 2 );

	// ========================================================================
	//  The respawn GROUP is this mod's addition, not Reimagined's.
	//
	//  The eight structs above are "initial_spawn" structs, which is what
	//  _zm_gametype::onspawnplayer uses for the FIRST spawn. A player who dies
	//  and comes back goes through _zm::check_for_valid_spawn_near_team, and
	//  that walks player_respawn_point GROUPS. Origins' own chamber group
	//  carries script_noteworthy "zone_chamber" - and there is no zone by that
	//  name (the zones are zone_chamber_0..8), so enable_zone() can never
	//  unlock it and it stays locked for the whole match.
	//
	//  This is the same shape as the fault that killed Tunnel and Power Station
	//  survival on TranZit (scripts\zm\replaced\zm_transit.gsc's header has the
	//  full chain). Registering a group whose script_noteworthy IS a real zone
	//  means enable_zone( "zone_chamber_4" ) unlocks it. Origin and radius are
	//  the stock chamber group's own values, read from the mapents dump.
	// ========================================================================
	scripts\zm\replaced\utility::register_map_spawn_group( (10368, -7936, -356), zone, 1024 );

	// --- perk machines: Reimagined's four, at their mapents coordinates ------
	scripts\zm\replaced\utility::register_perk_struct( "specialty_armorvest",   "zombie_vending_jugg",       (9459, -8557, -398),  (0, 75, 0) );
	scripts\zm\replaced\utility::register_perk_struct( "specialty_quickrevive", "p6_zm_tm_vending_revive",   (11229, -7052, -346), (0, -30, 0) );
	scripts\zm\replaced\utility::register_perk_struct( "specialty_fastreload",  "zombie_vending_sleight",    (11254, -8662, -408), (0, 240, 0) );
	scripts\zm\replaced\utility::register_perk_struct( "specialty_rof",         "zombie_vending_doubletap2", (9627, -7008, -346),  (0, -15, 0) );

	// ========================================================================
	//  Pack-a-Punch is built by hand rather than through register_perk_struct,
	//  for one reason: that helper gives a specialty_weapupgrade struct a
	//  "please wait" flag target, and _zm_perks::perk_machine_spawn_init then
	//  setmodel()s zombie_sign_please_wait. Origins' own Pack-a-Punch has no
	//  such flag and nothing on this map precaches that model. With no .target
	//  the stock branch's isdefined( flag_pos ) guard simply skips it.
	//
	//  🛑 v2.14.23 - ORIGINS' OWN PACK-A-PUNCH STRUCT IS DROPPED FIRST, so this
	//  machine is the ONLY Pack-a-Punch on the location. User, 2026-09-08:
	//  *"instant pap doesn't work with this machine ... make sure the instant
	//  pap toggle works as well"*. Measured from the 8:14 AM and 9:02 AM logs:
	//  "crazy place pap: trigger 1 machine at (-5,-8,335)" - the map's own
	//  machine at the Excavation Site was being spawned alongside this one, and
	//  every stock lookup is written for a map with ONE machine:
	//    * quality_of_life.gsc::new_pap_trigger() takes trigger [0] and
	//      getent( "vending_packapunch", "targetname" ) and builds the instant
	//      radius trigger there - i.e. at the Excavation Site, outside the arena.
	//    * _zm_perks::vending_weapon_upgrade() (stock mode) does
	//      getent( self.target ) = getent( "vending_packapunch" ) on EACH
	//      trigger, so both triggers' threads bind whichever of the two models
	//      the engine hands back.
	//  The map's struct is not needed here - nothing on a survival arena can
	//  reach the Excavation Site - so it is taken out of the struct index before
	//  _zm_perks::perk_machine_spawn_init() reads it (zm_tomb.gsc main():
	//  _load::main() at :141 runs struct_class_init and this hook; _zm::init()
	//  at :218 spawns the machines). The client-side "pap_cs" model the map
	//  places at the same spot is a static client entity and stays; it is
	//  outside the arena. See zmqol_cp_drop_map_pap_structs().
	// ========================================================================
	zmqol_cp_drop_map_pap_structs();

	s_pap = spawnstruct();
	s_pap.targetname = "zm_perk_machine";
	s_pap.script_noteworthy = "specialty_weapupgrade";
	s_pap.model = "p6_zm_tm_packapunch";
	s_pap.origin = (10340, -7906, -412);
	s_pap.angles = (0, 0, 0);
	scripts\zm\replaced\utility::add_struct( s_pap );


	// --- the four pillar wall-buys ------------------------------------------
	//  🛑 EVERY ORIGIN AND ANGLE HERE HAS AN EXACT TWIN in
	//  scripts\zm\zm_expanded.csc::zmqol_add_crazy_place_wallbuys(). The
	//  clientfield each one registers is named "<weapon>_<origin>", so the two
	//  sides must build the same four structs or the engine drops every player
	//  at load. Change one, change both.
	zmqol_add_wallbuy( "evoskorpion_zm", "t6_wpn_smg_scorpion_world", (10576, -8142, -383), (0, 315, 0) );
	zmqol_add_wallbuy( "scar_zm",        "t6_wpn_ar_scarh_world",     (10104, -8142, -383), (0, 225, 0) );
	zmqol_add_wallbuy( "mg08_zm",        "t6_wpn_zmb_mg08_world",     (10104, -7670, -383), (0, 135, 0) );
	zmqol_add_wallbuy( "ksg_zm",         "t6_wpn_shotty_ksg_world",   (10576, -7670, -383), (0, 45, 0) );
}

// ============================================================================
//  zmqol_add_wallbuy  -  a wall-buy pair (visible model + purchase struct).
//
//  Same two-struct shape stock's mapents use and the same one this mod already
//  ships for the Diner's semtex and claymore. The script_noteworthy tag is
//  Reimagined's own string: init_spawnable_weapon_upgrade() strtoks it on ","
//  and compares each token against "<gametype>_<location>" AND against that
//  with a leading space, which is why the space after the comma is harmless.
// ============================================================================
zmqol_add_wallbuy( str_weapon, str_model, v_origin, v_angles )
{
	str_target = "zmqol_cp_" + str_weapon;

	s_model = spawnstruct();
	s_model.targetname = str_target;
	s_model.origin = v_origin;
	s_model.angles = v_angles;
	s_model.model = str_model;
	s_model.script_noteworthy = "zstandard_crazy_place, zgrief_crazy_place";
	scripts\zm\replaced\utility::add_struct( s_model );

	s_buy = spawnstruct();
	s_buy.targetname = "weapon_upgrade";
	s_buy.origin = v_origin;
	s_buy.angles = v_angles;
	s_buy.zombie_weapon_upgrade = str_weapon;
	s_buy.target = str_target;
	s_buy.script_noteworthy = "zstandard_crazy_place, zgrief_crazy_place";
	scripts\zm\replaced\utility::add_struct( s_buy );

	println( "[zm_qol] crazy place wallbuy: " + str_weapon + " at (" + int( v_origin[0] ) + "," + int( v_origin[1] ) + "," + int( v_origin[2] ) + ") yaw " + int( v_angles[1] ) );
}

// ============================================================================
//  zmqol_cp_drop_map_pap_structs  -  Origins' own Pack-a-Punch struct leaves
//  the struct index, so only the chamber machine is ever spawned.  (v2.14.23)
//
//  The index is level.struct_class_names[key][name], built by struct_class_init
//  (the mod's scripts\zm\replaced\utility.gsc copy of stock's, which then calls
//  this location's struct_init). getstructarray() / getstruct() read nothing
//  else, so rebuilding the two arrays the Pack-a-Punch struct sits in - the
//  "zm_perk_machine" targetname list perk_machine_spawn_init() walks, and the
//  "specialty_weapupgrade" noteworthy list - removes it from every consumer at
//  once. Runs BEFORE the chamber's own struct is add_struct()ed, so "every
//  specialty_weapupgrade struct" here means the map's, and the map has one
//  (mapents dump: script_struct at (-5.5, -8.5, 335.5), target "pap_cs").
//  Nothing in the Origins dump or this mod looks the struct up by any other
//  key (grep'd for specialty_weapupgrade / zm_perk_machine / pap_cs).
// ============================================================================
zmqol_cp_drop_map_pap_structs()
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
					println( "[zm_qol] crazy place pap: dropped the map's own pack-a-punch struct at (" + int( a_old[i].origin[0] ) + "," + int( a_old[i].origin[1] ) + "," + int( a_old[i].origin[2] ) + ") from the struct index" );
				}

				continue;
			}

			a_new[a_new.size] = a_old[i];
		}

		level.struct_class_names[a_keys[k]][a_names[k]] = a_new;
	}

	println( "[zm_qol] crazy place pap: " + n_dropped + " map pack-a-punch struct(s) dropped (expect 1)" );
}

// ============================================================================
//  zmqol_cp_pap_built_pose  -  the chamber's Pack-a-Punch stands ASSEMBLED.
//                                                  (v2.14.23, redone v2.14.25)
// ----------------------------------------------------------------------------
//  On classic Origins the machine starts as a heap of stone and its pieces
//  rise one per captured generator. That is a CLIENT animation on a CLIENT-ONLY
//  map model: zm_tomb_capture_zones.csc::play_pap_anim() drives the entity
//  "pap_cs" (mapents: script_model, spawnflags 2, at the Excavation Site) from
//  the "packapunch_anim" clientfield - setanim( anim, 1.0, 0.0, RATE 0 ) then
//  setanimtime( anim, 1.0 ): a snap to the last frame that never plays and so
//  never ends. The SERVER's machine, meanwhile, is ghost()ed and notsolid()ed
//  from pack_a_punch_init() and nobody ever sees it.
//
//  🛑 v2.14.23 played the same six anims on the SERVER machine instead, at
//  rate 1. Booted 2:10 PM 2026-09-08: the log said all six played (2.1 s each,
//  "after 0s", before any client existed) and the machine still stood as the
//  heap. Whatever the exact mechanism (a finished non-looping anim released,
//  or an anim that ended before the first client connected never reaching
//  it), stock never does it that way and it is not done that way any more.
//
//  v2.14.25 mirrors stock instead: scripts\zm\zm_tomb\zm_tomb.csc::
//  zmqol_cp_pap_client_model() spawns, per local client, its own
//  p6_zm_tm_packapunch at this machine's exact origin and angles and snaps the
//  six anims to their last frame exactly as play_pap_anim() does for pap_cs
//  (rate 0, setanimtime 1.0, the same useanimtree + mapshaderconstant pair
//  get_pack_a_punch_model() applies). No clientfield is needed for a pose that
//  never changes, so nothing is registered on either side.
//
//  This server half only GHOSTS the machine, so the heap does not draw through
//  the built one. ghost() hides and keeps collision - stock calls ghost() and
//  notsolid() as two separate steps, and here the solid one is wanted: the
//  chamber has no clip brush for this spot, so the server model is the only
//  thing stopping a player walking through the machine. Everything else about
//  the machine (trigger, INSTANT PAP radius, the rising weapon model, sounds)
//  keys off the trigger and the machine's origin, exactly as it does for the
//  ghosted machine on classic. 🛑 pap_probe() used to show() every machine 3 s
//  after round logic; that would undo this, so it only prints now.
// ============================================================================
zmqol_cp_pap_built_pose()
{
	level endon( "intermission" );

	m_pap = undefined;
	n_wait = 0;

	while ( !isdefined( m_pap ) && n_wait < 600 )
	{
		a_pap = getentarray( "specialty_weapupgrade", "script_noteworthy" );

		for ( i = 0; i < a_pap.size; i++ )
		{
			if ( isdefined( a_pap[i] ) && isdefined( a_pap[i].machine ) )
			{
				m_pap = a_pap[i].machine;
				break;
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
		println( "[zm_qol] crazy place pap: no machine after 30s - server machine NOT ghosted, the client's built model will draw through the heap" );
		return;
	}

	m_pap ghost();

	println( "[zm_qol] crazy place pap: server machine at (" + int( m_pap.origin[0] ) + "," + int( m_pap.origin[1] ) + "," + int( m_pap.origin[2] ) + ") ghosted after " + ( n_wait * 0.05 ) + "s, collision kept - the built pose is the client's own model (zm_tomb.csc)" );
}

precache()
{
	//  pap_fx() setmodel()s two script_models with it.
	precachemodel( "tag_origin" );

	//  The five machine models. All five are Origins' own and are precached by
	//  the map already (four perk machines it ships in classic, plus
	//  p6_zm_tm_packapunch from zm_tomb_capture_zones::precache_everything,
	//  which runs on every gametype) - repeated here so this location does not
	//  depend on that staying true.
	precachemodel( "zombie_vending_jugg" );
	precachemodel( "p6_zm_tm_vending_revive" );
	precachemodel( "zombie_vending_sleight" );
	precachemodel( "zombie_vending_doubletap2" );
	precachemodel( "p6_zm_tm_packapunch" );

	//  v2.14.25 - the box's own collision (zmqol_cp_box_collision). Stock's
	//  own perk-machine clip is spawned the same way (_zm_perks.gsc:2898).
	//  common_zm.ff carries the model (Unlinker --list, 2026-09-08).
	precachemodel( "collision_geo_64x64x64_standard" );
}

main()
{
	treasure_chest_init();
	enable_zones();
	disable_zones();

	level thread perk_fx();
	level thread pap_probe();
	level thread zmqol_cp_pap_built_pose();
	level thread zmqol_cp_box_power_look();

	//  `.boxhere` (quality_of_life.gsc's chat commands) reaches this location
	//  through the pointer, never by a qualified reference - that file loads on
	//  every map and this one only on Origins (ERROR_CATALOGUE §3).
	level.zmqol_box_here_func = ::zmqol_cp_box_here;
	level thread pap_fx();
	level thread set_ee_ending();
	level thread scripts\zm\locs\loc_common::init();
}

// ============================================================================
//  enable_zones
//
//  Reimagined sets the adjacency flag and leaves it there. This copy ALSO
//  zone_init()s and enable_zone()s all nine chamber zones outright, because the
//  flag alone is a race: _zm_zonemgr::zone_flag_wait() is what turns an
//  adjacency flag into enabled zones, and it only enables a pair when its
//  thread reaches the flag. A zone that is not enabled is not part of the
//  playable area either - _zm::in_enabled_playable_area() only counts a
//  player_volume whose zone is enabled - and that is precisely what killed
//  Power Station survival on TranZit until v2.10.x.
//
//  zone_init() returns early on a zone it has already made and enable_zone()
//  no-ops on an enabled one, so doing both is safe and idempotent.
// ============================================================================
enable_zones()
{
	//  The location's main() is threaded from _zm_gametype::rungametypemain,
	//  which runs after the map's own main() has threaded manage_zones - but
	//  "after it was threaded" is not "after it has run", and zone_init() needs
	//  level.zones to exist. Bounded wait rather than an assumption; the count
	//  printed at the end says which way it went.
	n_waited = 0;

	while ( !isdefined( level.zones ) && n_waited < 100 )
	{
		wait 0.05;
		n_waited++;
	}

	if ( !isdefined( level.zones ) )
	{
		println( "[zm_qol] crazy place: level.zones never appeared - the chamber cannot be enabled" );
		return;
	}

	a_zones = chamber_zones();

	for ( i = 0; i < a_zones.size; i++ )
	{
		zone_init( a_zones[i] );
		enable_zone( a_zones[i] );
	}

	flag_set( "activate_zone_chamber" );

	println( "[zm_qol] crazy place: " + a_zones.size + " chamber zone(s) enabled, activate_zone_chamber set" );
}

chamber_zones()
{
	a_zones = [];
	a_zones[a_zones.size] = "zone_chamber_0";
	a_zones[a_zones.size] = "zone_chamber_1";
	a_zones[a_zones.size] = "zone_chamber_2";
	a_zones[a_zones.size] = "zone_chamber_3";
	a_zones[a_zones.size] = "zone_chamber_4";
	a_zones[a_zones.size] = "zone_chamber_5";
	a_zones[a_zones.size] = "zone_chamber_6";
	a_zones[a_zones.size] = "zone_chamber_7";
	a_zones[a_zones.size] = "zone_chamber_8";
	return a_zones;
}

//  Reimagined's, verbatim apart from the zone list coming from the helper above
//  and the diagnostic line.
disable_zones()
{
	valid_zones = chamber_zones();
	spawn_points = maps\mp\gametypes_zm\_zm_gametype::get_player_spawns_for_gametype();
	n_off = 0;

	foreach ( index, zone in level.zones )
	{
		if ( !isinarray( valid_zones, index ) )
		{
			level.zones[index].is_enabled = 0;
			level.zones[index].is_spawning_allowed = 0;
			n_off++;

			foreach ( spawn_point in spawn_points )
			{
				if ( spawn_point.script_noteworthy == index )
				{
					spawn_point.locked = 1;
					break;
				}
			}
		}
	}

	println( "[zm_qol] crazy place: " + n_off + " zone(s) outside the chamber disabled" );
}

// ============================================================================
//  treasure_chest_init  -  ONE of Origins' chests, moved into the arena.
//                                                                   (v2.14.22)
// ----------------------------------------------------------------------------
//  Was Reimagined's verbatim: all six chests, every one outside the chamber,
//  so the box was never reachable here. User, 2026-09-08: *"add a mystery box
//  to this survival map ... make sure it's the origins mystery box, and it
//  doesn't have to be pixel perfect just not too far away from these pillars,
//  not too close/clipping into them, make sure it's aligned well"*.
//
//  HOW A CHEST IS BUILT, measured from the zm_tomb mapents dump and
//  _zm_magicbox.gsc, not assumed:
//    * a script_struct "treasure_chest_use" (origin, angles, zombie_cost 950,
//      script_noteworthy "<name>") - the thing level.chests holds;
//    * a "zbarrier_zmtomb_magicbox" ENTITY at the SAME origin with
//      script_noteworthy "<name>_zbarrier" and yaw = struct yaw +/- 180 (every
//      one of the six pairs: struct 180 / zbarrier 0, 270 / 90, 105 / 285).
//      _zm_magicbox::get_chest_pieces() finds it by that name (line 173) and
//      it IS the box - model, lid, gun rise, teddy, glow all hang off it;
//    * the use prompt is a unitrigger _zm_magicbox builds at
//      origin + anglestoright( struct.angles ) * -22.5 (line 182), i.e. on
//      the struct's LEFT-hand side. That fixes the facing convention: the side
//      players use is the -right vector, so a box with its back to a wall
//      whose inward normal points along yaw N takes struct yaw N - 90 and
//      zbarrier yaw N + 90.
//
//  So the move is two writes - the struct and its zbarrier - done BEFORE
//  _zm_magicbox::treasure_chest_init() reads either. Nothing else in the
//  stock mapents shares a chest's origin (grep'd: only the pair itself), so
//  there is no collision brush left behind. With ONE chest in level.chests,
//  treasure_chest_init() takes its size == 1 branch: chest_index 0,
//  no_fly_away = 1, no teddy, no "moving_chest_enabled" - the box stays put.
//  Same single-chest shape as the mod's Dragon Rooftop / Reimagined's Church.
//
//  WHERE. The user's screenshot carried the mod's own ".where" line:
//  x 10536 y -8383 z -463 yaw 259, arrow on the floor at the foot of the
//  pillars straight ahead. The placement TRACES that wall rather than guessing
//  a distance off a screenshot.
//
//  🛑 v2.14.25 - A FAN OF NINE RAYS, FITTED TO A LINE, not one ray's normal.
//  v2.14.23 fired ONE bullettrace along yaw 259 and faced the box off the
//  normal it got back: "wall hit at (10499,-8568), 189 out, wall normal yaw 30"
//  (2:10 PM log). The user was looking at the pillars nearly square-on (a wall
//  facing them squarely reads normal 79), so 30 was one pillar's curved face
//  or a carved facet, 49 degrees off the row. The box was then turned 49
//  degrees to that row and pushed 80 out along the wrong line - which is the
//  screenshot the user sent: "clipping into the wall ... on its side ... align
//  it with those pillars". The Wunderfizz's own snap has the same single-ray
//  shape and got away with it because its wall happened to return a flat face.
//
//  Now: nine traces 8 degrees apart across the user's yaw (259 +- 32), every
//  hit between 100 and 600 out is kept, and a least-squares LINE is fitted
//  through those hit points (principal axis of their 2-D scatter, eigenvector
//  by hand - no atan in GSC, the direction goes through vectortoangles). A row
//  of round pillars returns hits on crests and in gaps; the line through them
//  is the row, and its perpendicular towards the standing point is the facing.
//  The box sits on that line at the foot of the centre ray, n_gap out: 25 is
//  the model's own back face (p6_anim_zm_tm_magic_box, dumped from zm_tomb.ff:
//  local y -36.8 .. +25.0, x +-60, z +-24) and 31 is clearance for a pillar
//  crest standing proud of the fitted line. Fewer than three usable hits falls
//  back to the single-ray placement, logged as such.
//
//  Every hit, the fitted normal and the final spot are in the log. If it is
//  still off, `.boxhere` moves the box live (zmqol_cp_box_here) and prints the
//  numbers to bake.
//
//  A zbarrier is a map entity; assigning .origin/.angles moved it in the 9:02 AM
//  boot (the log read the new origin back and the box drew there), so that
//  question is settled.
// ============================================================================
treasure_chest_init()
{
	level.chests = getstructarray( "treasure_chest_use", "targetname" );

	s_chest = zmqol_cp_bring_chest_into_arena();

	if ( isdefined( s_chest ) )
	{
		level.chests = [];
		level.chests[0] = s_chest;
	}

	maps\mp\zombies\_zm_magicbox::treasure_chest_init( "start_chest" );

	if ( isdefined( s_chest ) )
		println( "[zm_qol] crazy place: magic box list = " + level.chests.size + " chest(s) - " + s_chest.script_noteworthy + " moved into the arena" );
	else
		println( "[zm_qol] crazy place: magic box list = " + level.chests.size + " chest(s), all outside the arena - the move FAILED, see above" );
}

zmqol_cp_bring_chest_into_arena()
{
	//  The user's standing point and facing, from the ".where" line in their
	//  screenshot (2026-09-08).
	v_stand = ( 10536, -8383, -463 );
	n_yaw   = 259;
	n_gap   = 56;

	v_from = v_stand + ( 0, 0, 40 );

	//  --- the fan ------------------------------------------------------------
	a_hit = [];
	v_aim = undefined;

	for ( k = -4; k <= 4; k++ )
	{
		n_k = n_yaw + k * 8;
		v_d = anglestoforward( ( 0, n_k, 0 ) );
		v_t = v_from + ( v_d[0] * 900, v_d[1] * 900, 0 );

		tr = bullettrace( v_from, v_t, 0, undefined );

		if ( tr["fraction"] >= 1 )
		{
			println( "[zm_qol] crazy place box: fan yaw " + n_k + " - no hit within 900" );
			continue;
		}

		n_d = distance( v_from, tr["position"] );

		if ( n_d < 100 || n_d > 600 )
		{
			println( "[zm_qol] crazy place box: fan yaw " + n_k + " hit " + int( n_d ) + " out - outside 100..600, ignored" );
			continue;
		}

		a_hit[a_hit.size] = tr["position"];

		if ( k == 0 )
			v_aim = tr["position"];

		println( "[zm_qol] crazy place box: fan yaw " + n_k + " hit (" + int( tr["position"][0] ) + "," + int( tr["position"][1] ) + "," + int( tr["position"][2] ) + ") " + int( n_d ) + " out" );
	}

	n_out = undefined;
	v_box = undefined;

	if ( a_hit.size >= 3 )
	{
		//  --- least-squares line through the hits (2-D) ----------------------
		n_mx = 0;
		n_my = 0;

		for ( i = 0; i < a_hit.size; i++ )
		{
			n_mx += a_hit[i][0];
			n_my += a_hit[i][1];
		}

		n_mx = n_mx / a_hit.size;
		n_my = n_my / a_hit.size;

		n_sxx = 0;
		n_syy = 0;
		n_sxy = 0;

		for ( i = 0; i < a_hit.size; i++ )
		{
			n_dx = a_hit[i][0] - n_mx;
			n_dy = a_hit[i][1] - n_my;
			n_sxx += n_dx * n_dx;
			n_syy += n_dy * n_dy;
			n_sxy += n_dx * n_dy;
		}

		//  Largest eigenvalue of [[sxx, sxy], [sxy, syy]] and its eigenvector,
		//  taken from whichever row is better conditioned.
		n_l1 = ( ( n_sxx + n_syy ) + sqrt( ( n_sxx - n_syy ) * ( n_sxx - n_syy ) + 4 * n_sxy * n_sxy ) ) * 0.5;

		v_line = ( n_sxy, n_l1 - n_sxx, 0 );

		if ( length( v_line ) < 0.001 || abs( n_l1 - n_syy ) > abs( n_l1 - n_sxx ) )
			v_line = ( n_l1 - n_syy, n_sxy, 0 );

		if ( length( v_line ) < 0.001 )
			v_line = ( 1, 0, 0 );

		v_line = vectornormalize( v_line );

		//  Perpendicular, pointing back at the standing point.
		v_n = ( 0 - v_line[1], v_line[0], 0 );
		v_to_stand = ( v_stand[0] - n_mx, v_stand[1] - n_my, 0 );

		if ( vectordot( v_n, v_to_stand ) < 0 )
			v_n = ( 0 - v_n[0], 0 - v_n[1], 0 );

		n_out = vectortoangles( v_n )[1];

		//  Foot of the centre ray on the line (or the mean if that ray missed).
		if ( !isdefined( v_aim ) )
			v_aim = ( n_mx, n_my, v_stand[2] );

		n_along = ( v_aim[0] - n_mx ) * v_line[0] + ( v_aim[1] - n_my ) * v_line[1];
		v_foot = ( n_mx + v_line[0] * n_along, n_my + v_line[1] * n_along, v_stand[2] );

		v_box = ( v_foot[0] + v_n[0] * n_gap, v_foot[1] + v_n[1] * n_gap, v_stand[2] );

		println( "[zm_qol] crazy place box: line fit through " + a_hit.size + " hit(s) - row yaw " + int( vectortoangles( v_line )[1] ) + ", facing (normal) yaw " + int( n_out ) + ", foot (" + int( v_foot[0] ) + "," + int( v_foot[1] ) + "), box " + n_gap + " out" );
	}
	else
	{
		//  --- fallback: the v2.14.23 single ray ------------------------------
		v_dir = anglestoforward( ( 0, n_yaw, 0 ) );
		v_to  = v_from + ( v_dir[0] * 1200, v_dir[1] * 1200, 0 );

		trace = bullettrace( v_from, v_to, 0, undefined );

		n_out = n_yaw + 180;

		if ( trace["fraction"] < 1 && distance( v_from, trace["position"] ) >= 150 )
		{
			v_hit = trace["position"];

			if ( isdefined( trace["normal"] ) )
			{
				v_flat = ( trace["normal"][0], trace["normal"][1], 0 );

				if ( length( v_flat ) > 0.1 )
					n_out = vectortoangles( vectornormalize( v_flat ) )[1];
			}

			v_out = anglestoforward( ( 0, n_out, 0 ) );
			v_box = ( v_hit[0] + v_out[0] * n_gap, v_hit[1] + v_out[1] * n_gap, v_stand[2] );

			println( "[zm_qol] crazy place box: only " + a_hit.size + " fan hit(s) - single-ray fallback, wall hit at (" + int( v_hit[0] ) + "," + int( v_hit[1] ) + "," + int( v_hit[2] ) + "), normal yaw " + int( n_out ) );
		}
		else
		{
			v_box = ( v_stand[0] + v_dir[0] * 320, v_stand[1] + v_dir[1] * 320, v_stand[2] );

			println( "[zm_qol] crazy place box: only " + a_hit.size + " fan hit(s) and no usable wall along yaw " + n_yaw + " - using the fixed fallback 320 out" );
		}
	}

	while ( n_out < 0 )
		n_out += 360;
	while ( n_out >= 360 )
		n_out -= 360;

	//  Onto the floor. Same trace the Wunderfizz uses.
	trace_floor = bullettrace( v_box + ( 0, 0, 72 ), v_box - ( 0, 0, 160 ), 0, undefined );

	if ( trace_floor["fraction"] < 1 )
		v_box = ( v_box[0], v_box[1], trace_floor["position"][2] );

	//  Which chest: the bunker start chest by preference (it is the one classic
	//  Origins opens with), else whichever is first.
	s_chest = undefined;

	for ( i = 0; i < level.chests.size; i++ )
	{
		if ( isdefined( level.chests[i].script_noteworthy ) && level.chests[i].script_noteworthy == "bunker_start_chest" )
		{
			s_chest = level.chests[i];
			break;
		}
	}

	if ( !isdefined( s_chest ) && level.chests.size > 0 )
		s_chest = level.chests[0];

	if ( !isdefined( s_chest ) || !isdefined( s_chest.script_noteworthy ) )
	{
		println( "[zm_qol] crazy place box: no treasure_chest_use struct to move" );
		return undefined;
	}

	e_zb = getent( s_chest.script_noteworthy + "_zbarrier", "script_noteworthy" );

	if ( !isdefined( e_zb ) )
	{
		println( "[zm_qol] crazy place box: " + s_chest.script_noteworthy + " has no _zbarrier entity - not moved" );
		return undefined;
	}

	v_was = s_chest.origin;

	zmqol_cp_place_box( s_chest, e_zb, v_box, n_out );

	println( "[zm_qol] crazy place box: " + s_chest.script_noteworthy + " moved from (" + int( v_was[0] ) + "," + int( v_was[1] ) + "," + int( v_was[2] ) + ") to (" + int( v_box[0] ) + "," + int( v_box[1] ) + "," + int( v_box[2] ) + ") front yaw " + int( n_out ) + " (struct yaw " + int( s_chest.angles[1] ) + ", zbarrier yaw " + int( e_zb.angles[1] ) + ") - zbarrier reads back at (" + int( e_zb.origin[0] ) + "," + int( e_zb.origin[1] ) + "," + int( e_zb.origin[2] ) + ")" );

	return s_chest;
}

// ============================================================================
//  zmqol_cp_place_box  -  put the chest struct, its zbarrier and the box's
//  collision at v_box with the box's FRONT (the side you use) facing n_out.
//
//  The side players use is the struct's -right, which is yaw + 90 (stock's
//  unitrigger sits at origin + anglestoright( struct.angles ) * -22.5,
//  _zm_magicbox.gsc:182). So struct yaw = front - 90, and every stock chest
//  pairs its zbarrier at struct yaw + 180 (all seven, zm_tomb mapents).
// ============================================================================
zmqol_cp_place_box( s_chest, e_zb, v_box, n_out )
{
	n_struct_yaw = n_out - 90;

	while ( n_struct_yaw < 0 )
		n_struct_yaw += 360;
	while ( n_struct_yaw >= 360 )
		n_struct_yaw -= 360;

	n_zb_yaw = n_struct_yaw + 180;

	while ( n_zb_yaw >= 360 )
		n_zb_yaw -= 360;

	s_chest.origin = v_box;
	s_chest.angles = ( 0, n_struct_yaw, 0 );
	s_chest.start_exclude = undefined;

	e_zb.origin = v_box;
	e_zb.angles = ( 0, n_zb_yaw, 0 );

	zmqol_cp_box_collision( v_box, n_zb_yaw );
}

// ============================================================================
//  zmqol_cp_box_collision  -  the box blocks players (and paths zombies).
//
//  Stock's boxes are stopped by clip brushes baked into the map at each
//  chest's spot; nothing in the mapents near the bunker chest is a movable
//  collision entity (checked 2026-09-08), so a moved box has none - the user
//  ran straight through it. Two collision_geo_64x64x64_standard script_models
//  cover the model's footprint: p6_anim_zm_tm_magic_box is x +-60 along the
//  zbarrier's forward, y -36.8..+25 (centre -6, i.e. 6 along anglestoright),
//  z +-24 - so the pair sits at +-32 along forward, 6 along right, 32 up, each
//  spanning 64 x 64 x 64 about its origin (the family is centred: Reimagined's
//  maze stacks collision_wall_128x128x10 at up*64/192/320). Spawned the way
//  stock spawns a perk machine's clip (_zm_perks.gsc:2898: spawn(...,1) +
//  disconnectpaths) and ghost()ed like Buried's ffotd clips.
// ============================================================================
zmqol_cp_box_collision( v_box, n_zb_yaw )
{
	v_fwd = anglestoforward( ( 0, n_zb_yaw, 0 ) );
	v_rgt = anglestoright( ( 0, n_zb_yaw, 0 ) );
	v_mid = v_box + ( v_rgt[0] * 6, v_rgt[1] * 6, 32 );

	a_at = [];
	a_at[0] = v_mid + ( v_fwd[0] * 32, v_fwd[1] * 32, 0 );
	a_at[1] = v_mid - ( v_fwd[0] * 32, v_fwd[1] * 32, 0 );

	if ( !isdefined( level.zmqol_cp_box_clips ) )
	{
		level.zmqol_cp_box_clips = [];

		for ( i = 0; i < a_at.size; i++ )
		{
			clip = spawn( "script_model", a_at[i], 1 );
			clip.angles = ( 0, n_zb_yaw, 0 );
			clip setmodel( "collision_geo_64x64x64_standard" );
			clip.script_noteworthy = "zmqol_cp_box_clip";
			clip ghost();
			clip disconnectpaths();
			level.zmqol_cp_box_clips[i] = clip;
		}

		println( "[zm_qol] crazy place box: 2 collision clips spawned at (" + int( a_at[0][0] ) + "," + int( a_at[0][1] ) + "," + int( a_at[0][2] ) + ") and (" + int( a_at[1][0] ) + "," + int( a_at[1][1] ) + "," + int( a_at[1][2] ) + ")" );
		return;
	}

	for ( i = 0; i < a_at.size; i++ )
	{
		clip = level.zmqol_cp_box_clips[i];

		if ( !isdefined( clip ) )
			continue;

		clip connectpaths();
		clip.origin = a_at[i];
		clip.angles = ( 0, n_zb_yaw, 0 );
		clip disconnectpaths();
	}
}

// ============================================================================
//  zmqol_cp_box_here  -  `.boxhere`: move the box to where the player is
//  looking, live, and print the numbers to bake.
//
//  Stand where you would USE the box, face the wall, type .boxhere. The box
//  goes 64 units in front of you with its front facing you (so the wall is
//  behind it), on the floor there, with its collision. The use prompt and the
//  light stay where the box was placed at load - both are fixed at map start
//  (the unitrigger by _zm_magicbox, the light fx by the client) - so this is a
//  placement PROBE, not a working relocation: look, read the numbers off the
//  console, and they get baked into zmqol_cp_bring_chest_into_arena.
// ============================================================================
zmqol_cp_box_here( player )
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

	n_out = n_face + 180;

	while ( n_out >= 360 )
		n_out -= 360;

	zmqol_cp_place_box( s_chest, e_zb, v_at, n_out );

	player iprintln( "^2[zm_qol] box ^7at x " + int( v_at[0] ) + "  y " + int( v_at[1] ) + "  z " + int( v_at[2] ) + "  ^2front yaw ^7" + n_out + " ^7(prompt + light stay put until restart)" );
	println( "[zm_qol] BOXHERE zm_tomb crazy place: box at (" + v_at[0] + ", " + v_at[1] + ", " + v_at[2] + ") front yaw " + n_out + " (struct yaw " + int( s_chest.angles[1] ) + ", zbarrier yaw " + int( e_zb.angles[1] ) + ") - player stood at (" + int( player.origin[0] ) + "," + int( player.origin[1] ) + "," + int( player.origin[2] ) + ") yaw " + n_face );
}

// ============================================================================
//  zmqol_cp_box_power_look  -  the box's light is GREEN, not red.
//
//  User, 2026-09-08: *"that light on the front of the box is supposed to be
//  green not red"*. Measured, not guessed: the light is the magicbox_amb_fx
//  clientfield (_zm_magicbox_tomb.csc:96) - value 1 plays fx_tomb_magicbox_off
//  (the red one), value 2 fx_tomb_magicbox_on. A chest goes 1 on "initial"
//  (_zm_magicbox_tomb.gsc::magic_box_initial, 1 s after init) and only ever
//  reaches 2 through zm_tomb_capture_zones::enable_mystery_boxes_in_zone(),
//  when its generator's zone becomes player-controlled: zbarrier state
//  "player_controlled" (showzbarrierpiece(2) + amb_fx 2, :2076) and
//  magicbox_runes 1. Survival never registers a chest to a zone (the mod's
//  replaced register_elements_powered_by_zone_capture_generators returns on
//  !is_classic()), so this box stayed on 1 for ever. This does exactly what
//  that stock function does, once the box is in its "close" state (the tomb
//  handler sets .state "close" on "initial") and after round logic has started
//  - which is also after setup_capture_zones() has installed the capture
//  handler and after magic_box_initial()'s 1 s write of amb_fx 1.
//  magicbox_runes is registered on every gametype by both sides
//  (zm_tomb.gsc:225/:317, zm_tomb.csc:64). The direct call to the
//  capture-zones handler is deliberate: it is the one that knows
//  "player_controlled"; the _zm_magicbox wrapper only forwards to whichever
//  handler is installed, and this location file loads on Origins only.
// ============================================================================
zmqol_cp_box_power_look()
{
	level endon( "intermission" );

	flag_wait( "start_zombie_round_logic" );

	n_wait = 0;

	while ( n_wait < 300 )
	{
		if ( isdefined( level.chests ) && level.chests.size > 0 && isdefined( level.chests[0].zbarrier ) && isdefined( level.chests[0].zbarrier.state ) && level.chests[0].zbarrier.state == "close" )
			break;

		wait 0.1;
		n_wait++;
	}

	if ( !isdefined( level.chests ) || level.chests.size < 1 || !isdefined( level.chests[0].zbarrier ) )
	{
		println( "[zm_qol] crazy place box: no zbarrier after " + ( n_wait * 0.1 ) + "s - powered look NOT applied" );
		return;
	}

	e_zb = level.chests[0].zbarrier;
	str_state = "undefined";

	if ( isdefined( e_zb.state ) )
		str_state = e_zb.state;

	if ( str_state != "close" )
	{
		println( "[zm_qol] crazy place box: zbarrier state is '" + str_state + "' after " + ( n_wait * 0.1 ) + "s, not 'close' - powered look NOT applied" );
		return;
	}

	e_zb notify( "zbarrier_state_change" );
	e_zb maps\mp\zm_tomb_capture_zones::set_magic_box_zbarrier_state( "player_controlled" );
	e_zb setclientfield( "magicbox_runes", 1 );
	level.chests[0].is_locked = 0;

	println( "[zm_qol] crazy place box: powered look applied after " + ( n_wait * 0.1 ) + "s - zbarrier state player_controlled (piece 2, magicbox_amb_fx 2 = fx_tomb_magicbox_on), magicbox_runes 1, is_locked 0" );
}

// ============================================================================
//  perk_fx  -  Reimagined's, verbatim.
//
//  The four perk machines lose their model, their collision and their bump
//  trigger; the four use-triggers then swap positions with each other, and a
//  slowly rotating perk BOTTLE is spawned at each. Pack-a-Punch keeps its
//  machine and only loses its collision clip, so players can walk through the
//  middle of the platform.
//
//  Server-side entity work only - no clientfield, nothing the client has to
//  agree about - which is why the shuffle is safe here and the wall-buy one is
//  not (see the header).
// ============================================================================
perk_fx()
{
	flag_wait( "power_on" );

	wait 1;

	random_perk_trigs = [];
	trigs = getentarray( "zombie_vending", "targetname" );

	foreach ( trig in trigs )
	{
		if ( !isdefined( trig.script_noteworthy ) )
			continue;

		if ( trig.script_noteworthy == "specialty_armorvest" || trig.script_noteworthy == "specialty_quickrevive" || trig.script_noteworthy == "specialty_fastreload" || trig.script_noteworthy == "specialty_rof" )
		{
			random_perk_trigs[random_perk_trigs.size] = trig;

			if ( isdefined( trig.clip ) )
				trig.clip delete();

			if ( isdefined( trig.machine ) )
				trig.machine delete();

			if ( isdefined( trig.bump ) )
				trig.bump delete();
		}

		if ( trig.script_noteworthy == "specialty_weapupgrade" )
		{
			if ( isdefined( trig.clip ) )
				trig.clip delete();
		}
	}

	foreach ( trig in random_perk_trigs )
	{
		random_trig = random( random_perk_trigs );

		temp_origin = trig.origin;
		trig.origin = random_trig.origin;
		random_trig.origin = temp_origin;

		temp_angles = trig.angles;
		trig.angles = random_trig.angles;
		random_trig.angles = temp_angles;
	}

	foreach ( trig in random_perk_trigs )
	{
		model = maps\mp\zombies\_zm_perk_random::get_perk_weapon_model( trig.script_noteworthy );
		origin = trig.origin;
		angles = trig.angles + (0, 0, 10);

		ent = spawn( "script_model", origin );
		ent.angles = angles;
		ent setmodel( model );

		ent thread rotate_loop();
	}

	println( "[zm_qol] crazy place: " + random_perk_trigs.size + " perk machine(s) replaced with floating bottles (expect 4)" );
}

rotate_loop()
{
	while ( 1 )
	{
		self rotateyaw( 360, 1.5 );

		wait 1.5;
	}
}

// ============================================================================
//  pap_probe  -  zm_qol's, not Reimagined's.
//
//  Counts the Pack-a-Punch triggers 3 s into round logic and prints where each
//  machine is - the way the first boots proved the map's own Excavation Site
//  machine was being spawned beside ours. (Until v2.14.25 it also show()ed
//  each machine; the server machine is ghosted on purpose now, see
//  zmqol_cp_pap_built_pose.)
// ============================================================================
pap_probe()
{
	flag_wait( "start_zombie_round_logic" );

	wait 3;

	a_pap = getentarray( "specialty_weapupgrade", "script_noteworthy" );

	for ( i = 0; i < a_pap.size; i++ )
	{
		if ( !isdefined( a_pap[i] ) || !isdefined( a_pap[i].machine ) )
			continue;

		//  v2.14.25 - no show() here any more: zmqol_cp_pap_built_pose() ghosts
		//  the server machine on purpose (the client draws the built one).
		println( "[zm_qol] crazy place pap: trigger " + ( i + 1 ) + " machine at (" + int( a_pap[i].machine.origin[0] ) + "," + int( a_pap[i].machine.origin[1] ) + "," + int( a_pap[i].machine.origin[2] ) + ")" );
	}

	println( "[zm_qol] crazy place pap: " + a_pap.size + " pack-a-punch trigger(s) on the map (expect 1 - ours in the chamber; Origins' own struct was dropped from the index in struct_init, v2.14.23)" );
}

// ============================================================================
//  pap_fx / set_ee_ending  -  Reimagined's, verbatim.
//
//  The sky beam over the portal while someone is Pack-a-Punching, and the
//  end-of-game camera moved to the chamber's own portal shot. "ee_sam_portal"
//  is registered by zm_tomb_ee_main::init() BEFORE its is_sidequest_allowed
//  early return, so it exists on every gametype - checked, not assumed.
// ============================================================================
pap_fx()
{
	level endon( "intermission" );

	level thread pap_fx_delete_on_intermission();

	s_pos = getstruct( "player_portal_final", "targetname" );

	if ( !isdefined( s_pos ) )
		return;

	while ( 1 )
	{
		flag_wait( "pack_machine_in_use" );

		level.ee_ending_beam_fx = spawn( "script_model", s_pos.origin + vectorscale( (0, 0, -1), 300.0 ) );
		level.ee_ending_beam_fx.angles = vectorscale( (0, 1, 0), 90.0 );
		level.ee_ending_beam_fx setmodel( "tag_origin" );
		playfxontag( level._effect["ee_beam"], level.ee_ending_beam_fx, "tag_origin" );
		level.ee_ending_beam_sound = spawn( "script_model", s_pos.origin + vectorscale( (0, 0, -1), 800.0 ) );
		level.ee_ending_beam_sound.angles = vectorscale( (0, 1, 0), 90.0 );
		level.ee_ending_beam_sound setmodel( "tag_origin" );
		level.ee_ending_beam_sound playsound( "zmb_squest_crystal_sky_pillar_start" );
		level.ee_ending_beam_sound playloopsound( "zmb_squest_crystal_sky_pillar_loop", 3 );

		flag_waitopen( "pack_machine_in_use" );

		level.ee_ending_beam_fx delete();
		level.ee_ending_beam_sound playsound( "zmb_squest_crystal_sky_pillar_stop" );
		level.ee_ending_beam_sound delete();
	}
}

pap_fx_delete_on_intermission()
{
	level waittill( "intermission" );

	if ( isdefined( level.ee_ending_beam_fx ) )
	{
		level.ee_ending_beam_fx delete();
	}

	if ( isdefined( level.ee_ending_beam_sound ) )
	{
		level.ee_ending_beam_sound playsound( "zmb_squest_crystal_sky_pillar_stop" );
		level.ee_ending_beam_sound delete();
	}
}

set_ee_ending()
{
	flag_wait( "start_zombie_round_logic" );

	level setclientfield( "ee_sam_portal", 3 );

	points = getstructarray( "ee_cam", "targetname" );

	foreach ( point in points )
	{
		if ( !isdefined( point.target ) )
			continue;

		target_point = getstruct( point.target, "targetname" );

		if ( !isdefined( target_point ) )
			continue;

		point.angles += (180, 0, 0);
		target_point.angles += (180, 0, 0);
	}

	level.custom_intermission = maps\mp\zm_tomb_ee_main::player_intermission_ee;
}
