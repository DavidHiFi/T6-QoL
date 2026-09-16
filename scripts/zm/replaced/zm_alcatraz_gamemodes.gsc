#include maps\mp\zm_alcatraz_gamemodes;
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_game_module;
#include maps\mp\gametypes_zm\_zm_gametype;
#include maps\mp\zm_prison;
#include maps\mp\zm_alcatraz_grief_cellblock;
#include maps\mp\zm_alcatraz_classic;

// ============================================================================
//  Replaces maps\mp\zm_alcatraz_gamemodes::init to register CELL BLOCK as a
//  SURVIVAL start. Stock registers cellblock for zgrief only; the zstandard
//  lines reuse the stock grief location scripts, which is exactly what
//  BO2-Reimagined does (its replaced zm_alcatraz_gamemodes registers the same
//  pair). Cell Block survival was verified in game 2026-08-02 (checkpoint 12),
//  stripped in v1.15.0, and restored 2026-09-02 at the user's request.
//  The Docks location from the pre-strip copy stays out (excluded from the
//  restoration by the same request).
// ============================================================================
init()
{
	level.custom_vending_precaching = maps\mp\zm_prison::custom_vending_precaching;

	add_map_gamemode("zclassic", maps\mp\zm_prison::zclassic_preinit, undefined, undefined);
	add_map_gamemode("zstandard", ::zstandard_preinit, undefined, undefined);
	add_map_gamemode("zgrief", maps\mp\zm_alcatraz_grief_cellblock::zgrief_preinit, undefined, undefined);

	add_map_location_gamemode("zclassic", "prison", maps\mp\zm_alcatraz_classic::precache, maps\mp\zm_alcatraz_classic::main);

	add_map_location_gamemode("zstandard", "cellblock", maps\mp\zm_alcatraz_grief_cellblock::precache, maps\mp\zm_alcatraz_grief_cellblock::main);

	add_map_location_gamemode("zgrief", "cellblock", maps\mp\zm_alcatraz_grief_cellblock::precache, maps\mp\zm_alcatraz_grief_cellblock::main);

	// ========================================================================
	//  v2.17.4 - THE DOCKS (Mob of the Dead survival), restored.
	//
	//  Cut in v1.15.0 with the other ported locations; the loc script stayed in
	//  scripts\zm\locs\ and already carries its zm_qol adaptation - populated
	//  precache list, and the character fix noted in its own header (the MotD
	//  grief models a zstandard run never loads are no longer set, which is what
	//  the old invisibility bug was).
	//
	//  Its struct_init registers Juggernog, Electric Cherry and Pack-a-Punch
	//  from script, and the loc script itself disables the gondola call
	//  triggers, the craftable (plane-part) triggers and the afterlife props,
	//  then inits Brutus properly for a non-classic run.
	//
	//  🌟 THE ESCAPE QUEST CANNOT FIRE HERE. Unlike Origins and Buried, MotD's
	//  sidequest is not gated by is_sidequest_allowed() at all - it is threaded
	//  from zm_alcatraz_classic.gsc:59, and a survival location runs
	//  zm_prison_loc_docks::main instead, so start_alcatraz_sidequest() is never
	//  reached. Structural, not a flag.
	//
	//  The dock_chest struct and its zbarrier are both stock and ungated:
	//  script_gameobjectname does not appear ANYWHERE in zm_prison's mapents
	//  (0 occurrences), so the Maze box failure cannot happen on this map.
	// ========================================================================
	add_map_location_gamemode("zstandard", "docks", scripts\zm\locs\zm_prison_loc_docks::precache, scripts\zm\locs\zm_prison_loc_docks::main);
	add_map_location_gamemode("zgrief", "docks", scripts\zm\locs\zm_prison_loc_docks::precache, scripts\zm\locs\zm_prison_loc_docks::main);

	scripts\zm\replaced\utility::add_struct_location_gamemode_func("zstandard", "docks", scripts\zm\locs\zm_prison_loc_docks::struct_init);
	scripts\zm\replaced\utility::add_struct_location_gamemode_func("zgrief", "docks", scripts\zm\locs\zm_prison_loc_docks::struct_init);
}

// ============================================================================
//  🛑 Fixes: SURVIVAL ON MOB - INVISIBLE PLAYER MODEL, INVISIBLE VIEW ARMS AND
//     WEAPON, AND ZOMBIES THAT CANNOT DAMAGE YOU.
//
//  Not a logic bug - the script state was verified correct in game
//  (2026-08-02 probe: health=100, afterlife=UNDEF, model=c_zom_player_grief_guard_fb,
//  weap=m1911_zm). It is an ASSET-AVAILABILITY bug.
//
//  This function used to point givecustomcharacters at ::give_team_characters,
//  which resolves through #include maps\mp\zm_alcatraz_grief_cellblock to the
//  stock GRIEF character setup:
//      setmodel( "c_zom_player_grief_guard_fb" / "c_zom_player_grief_inmate_fb" )
//      setviewmodel( "c_zom_grief_guard_viewhands" / "c_zom_oleary_shortsleeve_viewhands" )
//
//  Those grief xmodels are NOT in any fastfile a zstandard game loads. Verified
//  with the OAT Unlinker: Alcatraz ships only so_zclassic_zm_prison.ff and
//  so_zencounter_zm_prison.ff - there is no so_zsurvival_zm_prison.ff at all
//  (TranZit is the ONLY map that has one), and a zstandard run loads just
//  zm_prison_patch + zm_prison. setmodel/setviewmodel on an xmodel that was
//  never loaded silently renders nothing: no body, no view arms, and no weapon
//  (it hangs off the viewhands tag). A player entity with no model also has no
//  hit geometry, which is why zombie melee could never connect.
//
//  Fix: use Mob of the Dead's OWN characters, which live in zm_prison_patch.ff
//  and are therefore actually loaded (the log confirms
//  "character/c_zom_oleary.gsc (zm_prison_patch)"). maps\mp\zm_prison::init_characters
//  is exactly what stock zclassic_preinit calls - it sets has_weasel,
//  givecustomloadout, precachecustomcharacters (::precache_personality_characters),
//  givecustomcharacters (::give_personality_characters) and
//  setupcustomcharacterexerts, then does the same flag_wait this function ended
//  on. All five symbols verified present in the SHIPPED zm_prison.gsc bytecode,
//  not just in the script dump.
//
//  level.force_team_characters / level.should_use_cia were dropped: nothing in
//  stock or in this project ever reads them (they are Reimagined's own flags,
//  and Reimagined's reader was never ported), so they were inert here.
// ============================================================================
zstandard_preinit()
{
	level.gamemode_post_spawn_logic = ::give_player_shiv;

	// Ends with flag_wait( "start_zombie_round_logic" ), same as before.
	maps\mp\zm_prison::init_characters();
}
