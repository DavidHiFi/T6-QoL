#include maps\mp\zm_tomb_gamemodes;
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_game_module;
#include maps\mp\gametypes_zm\_zm_gametype;
#include maps\mp\zm_tomb;
#include maps\mp\zm_tomb_classic;

// ============================================================================
//  ORIGINS SURVIVAL - THE CRAZY PLACE                               (v2.14.0)
// ----------------------------------------------------------------------------
//  User, 2026-09-06: *"add crazy place survival for origins from the reimagined
//  mod into my mod"*.
//
//  Stock maps\mp\zm_tomb_gamemodes::init registers exactly two things - the
//  zclassic gamemode and its one location, "tomb" (dumped and read, not
//  assumed). Origins ships NO survival mode of any kind, so every line below
//  that mentions crazy_place is an addition and the two zclassic lines are
//  stock verbatim.
//
//  🛑 ONLY THE CRAZY PLACE. BO2-Reimagined ships four Origins arenas (Trenches,
//  Excavation Site, Church, The Crazy Place); this is the one the user asked
//  for, and the other three are deliberately not registered - each needs its
//  own zone set, spawn set and generator handling.
//
//  --- zstandard_preinit is STOCK'S OWN, and that is deliberate ---------------
//  Reimagined points both new gamemodes at a local survival_init() that sets
//  level.force_team_characters and rolls level.should_use_cia. Measured before
//  copying it:
//    * force_team_characters is ASSIGNED in five stock map scripts and READ
//      NOWHERE in the entire 2,093-file dump. It does nothing.
//    * Origins' own give_personality_characters() switches on
//      self.characterindex only - it never looks at should_use_cia - so the
//      roll would not change a single model.
//    * But THIS mod reads should_use_cia: quality_of_life.gsc's
//      zmqol_team_emblem_watch() paints the scoreboard emblem CDC or CIA from
//      it. Copying the roll would stamp a CDC/CIA badge on a team of Dempsey,
//      Nikolai, Richtofen and Takeo.
//  So both new modes take maps\mp\zm_tomb::zstandard_preinit - stock's own,
//  empty - and Origins survival keeps the four heroes and the `.character`
//  picker that already works on this map.
// ============================================================================
init()
{
	println( "[zm_qol] zm_tomb_gamemodes::init - location=" + getdvar( "ui_zm_mapstartlocation" ) );

	add_map_gamemode( "zclassic", maps\mp\zm_tomb::zstandard_preinit, undefined, undefined );
	add_map_gamemode( "zstandard", maps\mp\zm_tomb::zstandard_preinit, undefined, undefined );
	add_map_gamemode( "zgrief", maps\mp\zm_tomb::zstandard_preinit, undefined, undefined );

	add_map_location_gamemode( "zclassic", "tomb", maps\mp\zm_tomb_classic::precache, maps\mp\zm_tomb_classic::main );

	add_map_location_gamemode( "zstandard", "crazy_place", scripts\zm\locs\zm_tomb_loc_crazy_place::precache, scripts\zm\locs\zm_tomb_loc_crazy_place::main );
	add_map_location_gamemode( "zgrief", "crazy_place", scripts\zm\locs\zm_tomb_loc_crazy_place::precache, scripts\zm\locs\zm_tomb_loc_crazy_place::main );

	scripts\zm\replaced\utility::add_struct_location_gamemode_func( "zstandard", "crazy_place", scripts\zm\locs\zm_tomb_loc_crazy_place::struct_init );
	scripts\zm\replaced\utility::add_struct_location_gamemode_func( "zgrief", "crazy_place", scripts\zm\locs\zm_tomb_loc_crazy_place::struct_init );

	// ========================================================================
	//  v2.17.4 - ORIGINS' OTHER THREE SURVIVAL ARENAS, restored.
	//
	//  Trenches, Excavation Site (No Man's Land) and Church went out in v1.15.0
	//  with the rest of the ported locations. Their loc scripts never left
	//  scripts\zm\locs\ and already carried their zm_qol adaptation (precache
	//  lists populated, zm_tomb_reimagined -> loc_common namespace fixes, zone
	//  and spawn handling).
	//
	//  Each registers its own perk machines from script in struct_init, because
	//  this mod ships no zm_tomb mapents and the stock machines are all tagged
	//  "zclassic_perks_tomb" - Church 1 (already shipped), Trenches 4 and
	//  Excavation Site 3 (both added in this change, coordinates verbatim from
	//  Reimagined's zm_tomb.d3dbsp).
	//
	//  🌟 THE EE SURFACE NEEDED NOTHING NEW. zm_tomb.gsc's
	//  zmqol_remove_survival_ee_props() and replaced\zm_tomb_capture_zones.gsc's
	//  five functions all guard on is_classic() ALONE, not on location, so the
	//  tank removal and the generator ungating these three need were already
	//  written by the Crazy Place work and apply here for free. Stock's own
	//  quest self-gates at zm_tomb_ee_main.gsc:43 on
	//  is_sidequest_allowed("zclassic"), which is false in zstandard.
	// ========================================================================
	add_map_location_gamemode( "zstandard", "trenches", scripts\zm\locs\zm_tomb_loc_trenches::precache, scripts\zm\locs\zm_tomb_loc_trenches::main );
	add_map_location_gamemode( "zgrief", "trenches", scripts\zm\locs\zm_tomb_loc_trenches::precache, scripts\zm\locs\zm_tomb_loc_trenches::main );

	add_map_location_gamemode( "zstandard", "excavation_site", scripts\zm\locs\zm_tomb_loc_excavation_site::precache, scripts\zm\locs\zm_tomb_loc_excavation_site::main );
	add_map_location_gamemode( "zgrief", "excavation_site", scripts\zm\locs\zm_tomb_loc_excavation_site::precache, scripts\zm\locs\zm_tomb_loc_excavation_site::main );

	add_map_location_gamemode( "zstandard", "church", scripts\zm\locs\zm_tomb_loc_church::precache, scripts\zm\locs\zm_tomb_loc_church::main );
	add_map_location_gamemode( "zgrief", "church", scripts\zm\locs\zm_tomb_loc_church::precache, scripts\zm\locs\zm_tomb_loc_church::main );

	scripts\zm\replaced\utility::add_struct_location_gamemode_func( "zstandard", "trenches", scripts\zm\locs\zm_tomb_loc_trenches::struct_init );
	scripts\zm\replaced\utility::add_struct_location_gamemode_func( "zgrief", "trenches", scripts\zm\locs\zm_tomb_loc_trenches::struct_init );

	scripts\zm\replaced\utility::add_struct_location_gamemode_func( "zstandard", "excavation_site", scripts\zm\locs\zm_tomb_loc_excavation_site::struct_init );
	scripts\zm\replaced\utility::add_struct_location_gamemode_func( "zgrief", "excavation_site", scripts\zm\locs\zm_tomb_loc_excavation_site::struct_init );

	scripts\zm\replaced\utility::add_struct_location_gamemode_func( "zstandard", "church", scripts\zm\locs\zm_tomb_loc_church::struct_init );
	scripts\zm\replaced\utility::add_struct_location_gamemode_func( "zgrief", "church", scripts\zm\locs\zm_tomb_loc_church::struct_init );
}
