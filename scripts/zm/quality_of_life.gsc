// ============================================================================
//  quality_of_life.gsc  -  merged root-level QoL/gameplay scripts
// ----------------------------------------------------------------------------
//  Single-file merge of what used to be 17 separate loose root scripts
//  (BO2DD, bo4maxammo, bocw_round, buried_animated_camo + animated_camo,
//  counterszm, custom_summary, deathmachine_powerup, high_round_fix,
//  instant_pap, No_Fog, noperklimit, perkbonuspoints, secretsongsurvival,
//  zm_expanded, zm_hitmarkers, zm_wallbuy_fills_clip,
//  areanotifier) plus the perk pop-up HUD - originally from
//  custom_perkanimuncompiled, REPLACED 2026-07-30 by the "Vanguard Perk
//  Animation" HUD (techboy04gaming / NewMartinLag), which lives in its own
//  section below (search "Vanguard Perk Animation") and no longer hooks
//  give_perk() at all.
//
//  NOTE (2026-07-30): Disable_Fog_Transition was briefly merged into this
//  file, then moved back OUT to the TranZit-scoped script
//  scripts/zm/zm_transit/disable_fog_transition.gsc. Its reference to
//  maps\mp\zm_transit_fx::precache_createfx_fx is resolved by T6 at script
//  LOAD time (not at the replaceFunc call site), so a root script holding it
//  threw "Unresolved external: precache_createfx_fx" on every non-TranZit
//  map even behind an if(mapname == "zm_transit") guard.
//
//  Every function keeps its original body. Only names that collided across
//  files (init, main, onplayerconnect, onplayerspawned, and the two competing
//  get_pack_a_punch_weapon_options overrides) were renamed/merged - see the
//  per-module comments for the mapping back to the original file.
// ============================================================================

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\_demo;
#include maps\mp\_visionset_mgr;
#include maps\mp\gametypes_zm\_hud_util;
#include maps\mp\gametypes_zm\_hud_message;
#include maps\mp\gametypes_zm\_zm_gametype;
#include maps\mp\gametypes_zm\_spectating;
#include maps\mp\gametypes_zm\_weapons;
#include maps\mp\animscripts\zm_death;
#include maps\mp\zombies\_zm;
#include maps\mp\zombies\_zm_ai_basic;
#include maps\mp\zombies\_zm_ai_dogs;
#include maps\mp\zombies\_zm_audio;
#include maps\mp\zombies\_zm_audio_announcer;
#include maps\mp\zombies\_zm_blockers;
#include maps\mp\zombies\_zm_bot;
#include maps\mp\zombies\_zm_buildables;
#include maps\mp\zombies\_zm_clone;
#include maps\mp\zombies\_zm_devgui;
#include maps\mp\zombies\_zm_equipment;
#include maps\mp\zombies\_zm_ffotd;
#include maps\mp\zombies\_zm_game_module;
#include maps\mp\zombies\_zm_gump;
#include maps\mp\zombies\_zm_laststand;
#include maps\mp\zombies\_zm_magicbox;
#include maps\mp\zombies\_zm_melee_weapon;
#include maps\mp\zombies\_zm_net;
#include maps\mp\zombies\_zm_perk_divetonuke;
//  Buried's, but shipped as raw GSC in mod.iwd at maps\mp\zombies\_zm_perk_vulture.gsc
//  so this resolves on every map. Same arrangement as _zm_perk_divetonuke above -
//  see AI_CONTEXT rule 2 on why a map-only path here would crash the other five.
#include maps\mp\zombies\_zm_perk_vulture;
#include maps\mp\zombies\_zm_perks;
#include maps\mp\zombies\_zm_pers_upgrades;
#include maps\mp\zombies\_zm_pers_upgrades_functions;
#include maps\mp\zombies\_zm_pers_upgrades_system;
#include maps\mp\zombies\_zm_playerhealth;
#include maps\mp\zombies\_zm_power;
#include maps\mp\zombies\_zm_powerups;
#include maps\mp\zombies\_zm_score;
#include maps\mp\zombies\_zm_sidequests;
#include maps\mp\zombies\_zm_spawner;
#include maps\mp\zombies\_zm_stats;
#include maps\mp\zombies\_zm_timer;
#include maps\mp\zombies\_zm_tombstone;
#include maps\mp\zombies\_zm_traps;
#include maps\mp\zombies\_zm_unitrigger;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_weapons;
#include maps\mp\zombies\_zm_zonemgr;

// ============================================================================
//  main() - combined from: zm_expanded, buried_animated_camo, animated_camo,
//           zm_wallbuy_fills_clip, secretsongsurvival, custom_summary
// ============================================================================
main()
{
    // --- zm_expanded ---
    replaceFunc( maps\mp\zombies\_zm_perks::perks_register_clientfield, ::perks_register_clientfield );
    replaceFunc( maps\mp\zombies\_zm::init_client_flags, ::init_client_flags );
    replaceFunc( maps\mp\zombies\_zm_perks::give_perk, ::give_perk );
    replaceFunc( maps\mp\zombies\_zm_perks::default_vending_precaching, ::default_vending_precaching );

    // --- animated_camo + buried_animated_camo (combined override, see notes on
    //     get_pack_a_punch_weapon_options() below) ---
    replacefunc( maps\mp\zombies\_zm_weapons::get_pack_a_punch_weapon_options, ::get_pack_a_punch_weapon_options );

    // --- zm_wallbuy_fills_clip ---
    replaceFunc( maps\mp\zombies\_zm_weapons::ammo_give, ::new_ammo_give );

    // --- THE STORM PSR'S CHARGE CHAIN (v2.12.7) - see zmqol_get_nonalternate_weapon() ---
    replaceFunc( maps\mp\zombies\_zm_weapons::get_nonalternate_weapon, ::zmqol_get_nonalternate_weapon );

    // --- INSTANT NUKE (v1.99.48, user request 2026-08-18) ---
    //  See zmqol_nuke_powerup() for the whole of it. Hooked in main() next to
    //  the others; the target only ever runs when a nuke is picked up, long
    //  after either entry point would have registered.
    replaceFunc( maps\mp\zombies\_zm_powerups::nuke_powerup, ::zmqol_nuke_powerup );
    replaceFunc( maps\mp\zombies\_zm_powerups::bonus_points_player_powerup, ::zmqol_bonus_points_player_powerup );  // BLOOD MONEY's announcer line (v2.8.8)

    // Keep a real four-drop round count that boss scripts cannot reduce to
    // force a fifth drop. See zmqol_powerup_drop().
    replaceFunc( maps\mp\zombies\_zm_powerups::powerup_round_start, ::zmqol_powerup_round_start );
    replaceFunc( maps\mp\zombies\_zm_powerups::powerup_drop, ::zmqol_powerup_drop );

    // --- NO BLEEDOUT PATCH  (v2.2.0, PATCHES tab) ---
    //  See the banner over zmqol_round_spawn_failsafe(). With the row OFF this
    //  is byte-exact stock; with it ON only the "has not moved" kill is skipped.
    replaceFunc( maps\mp\zombies\_zm::round_spawn_failsafe, ::zmqol_round_spawn_failsafe );

    //  🛑 AND THE POINTER, BECAUSE THE replaceFunc ALONE ONLY COVERS TWO OF THE
    //  THREE ROUTES. Stock reaches this function three ways:
    //        _zm.gsc:3068           ai thread round_spawn_failsafe();
    //        _zm_ai_dogs.gsc:431    self thread maps\mp\zombies\_zm::round_spawn_failsafe();
    //        _zm_gametype.gsc:1766  array_thread( level.zombie_spawners,
    //                                   ::add_spawn_function,
    //                                   level._zombies_round_spawn_failsafe );
    //  The third takes a POINTER captured in _zm::init at :88-89 - and that line
    //  is `if ( !isdefined( level._zombies_round_spawn_failsafe ) )`, so setting
    //  it here, in main(), means stock leaves ours alone. A half-covered patch
    //  would look like it worked and still let some zombies die on their own.
    level._zombies_round_spawn_failsafe = ::zmqol_round_spawn_failsafe;

    //  v2.9.15 - AND THE SECOND AUTOMATIC KILL, WHICH v2.2.0 MISSED ENTIRELY.
    //  _zm_spawner::zombie_assure_node() kills a zombie that could not path to
    //  any entrance node, ~1 minute after it spawned. See its banner. Both of
    //  stock's call sites (_zm_spawner.gsc:426 and :458) are threaded, which is
    //  the case STOCK_REFERENCE 7a records as measured-hookable.
    replaceFunc( maps\mp\zombies\_zm_spawner::zombie_assure_node, ::zmqol_zombie_assure_node );

    // --- BETTER SPEED COLA  (v2.2.0, GAME tab) ---
    //  Two halves of one feature: the board-closing animation scalar and the
    //  pause between boards. See the banner over zmqol_replace_chunk().
    replaceFunc( maps\mp\zombies\_zm_blockers::replace_chunk, ::zmqol_replace_chunk );
    replaceFunc( maps\mp\zombies\_zm_blockers::do_post_chunk_repair_delay, ::zmqol_do_post_chunk_repair_delay );
    //  v2.14.15 - part two, the perk bottles: stock's post-purchase drink with
    //  the fast-switch perk set around it. Threaded call site; it prints when it
    //  runs, and a per-player watcher covers the drink whether or not it does.
    replaceFunc( maps\mp\zombies\_zm_perks::vending_trigger_post_think, ::zmqol_vending_trigger_post_think );

    perks();
    zmqol_enable_fire_sale();
    zmqol_enable_bonfire_sale();    // BONFIRE SALE (v2.12.0)

    // --- secretsongsurvival ---
    precachemodel( "zombie_teddybear" );

    // --- custom_summary ---

    // --- instant_start ---
    // Both hooks are core _zm functions, identical on every map, so this applies
    // to all maps and to solo, custom and co-op games alike.
    replaceFunc( maps\mp\zombies\_zm::onallplayersready, ::onallplayersready_instant );
    replaceFunc( maps\mp\zombies\_zm::fade_out_intro_screen_zm, ::fade_out_intro_screen_zm_instant );

    // --- custom survival start locations (ported from BO2-Reimagined) ---
    // Extends stock struct_class_init() so that, after the map's structs are indexed,
    // any struct_init() registered for the active gametype+location runs. That is how
    // a new start location injects its own player spawns, perk machines and wallbuys
    // into a map that has no map-data for them.
    //
    // Safe from this root script: scripts\zm\replaced\utility only #includes globally
    // available modules (common_scripts\utility, maps\mp\_utility, maps\mp\zombies\_zm*,
    // maps\mp\gametypes_zm\_zm_gametype), so it resolves on every map (AI_CONTEXT rule 2).
    // The per-map hooks that reference map-specific code live in the map subfolder
    // scripts instead. Ordering is safe: stock <map>::main() calls <map>_gamemodes::init()
    // (which registers the locations) before _load::main() calls struct_class_init().
    replaceFunc( common_scripts\utility::struct_class_init, scripts\zm\replaced\utility::struct_class_init );

    //  v2.3.4 - hellhounds dropped from Diner. See zmqol_enable_dog_rounds()
    //  below for why this is the right hook and why it is safe globally.
    replaceFunc( maps\mp\zombies\_zm_ai_dogs::enable_dog_rounds, ::zmqol_enable_dog_rounds );

    //  🛑 POWER-UP TIMERS: the v1.99.0 replaceFunc that used to live here was
    //  REMOVED in v1.99.1 - it could never have fired. See
    //  zmqol_powerup_timer_think() below for the mechanism and the evidence.
}

// ============================================================================
//  Four regular power-ups per round, including boss drops
//
//  Stock caps powerup_drop() at four, but the Panzer and Brutus death scripts
//  lower level.powerup_drop_count from four to three before requesting their
//  guaranteed drop. That makes the boss reward a fifth physical power-up.
//  Keep an independent count which those scripts do not modify. Scripted
//  specific_powerup_drop() rewards remain outside the regular-drop pool, as in
//  stock.
// ============================================================================
zmqol_powerup_round_start()
{
    level.zombie_vars["zombie_powerup_drop_max_per_round"] = 4;
    level.powerup_drop_count = 0;
    level.zmqol_powerup_drop_count = 0;
}

zmqol_powerup_drop( drop_point )
{
    if ( !isdefined( level.zmqol_powerup_drop_count ) )
        level.zmqol_powerup_drop_count = 0;

    if ( level.zmqol_powerup_drop_count >= 4 )
        return;

    if ( !isdefined( level.zombie_include_powerups ) || level.zombie_include_powerups.size == 0 )
        return;

    rand_drop = randomint( 100 );

    if ( rand_drop > 2 )
    {
        if ( !level.zombie_vars["zombie_drop_item"] )
            return;

        debug = "score";
    }
    else
        debug = "random";

    playable_area = getentarray( "player_volume", "script_noteworthy" );
    level.powerup_drop_count++;
    level.zmqol_powerup_drop_count++;
    powerup = maps\mp\zombies\_zm_net::network_safe_spawn( "powerup", 1, "script_model", drop_point + vectorscale( ( 0, 0, 1 ), 40.0 ) );
    valid_drop = 0;

    for ( i = 0; i < playable_area.size; i++ )
    {
        if ( powerup istouching( playable_area[i] ) )
            valid_drop = 1;
    }

    if ( valid_drop && level.rare_powerups_active )
    {
        pos = ( drop_point[0], drop_point[1], drop_point[2] + 42 );

        if ( check_for_rare_drop_override( pos ) )
        {
            level.zombie_vars["zombie_drop_item"] = 0;
            valid_drop = 0;
        }
    }

    if ( !valid_drop )
    {
        level.powerup_drop_count--;
        level.zmqol_powerup_drop_count--;
        powerup delete();
        return;
    }

    powerup powerup_setup();
    print_powerup_drop( powerup.powerup_name, debug );
    powerup thread powerup_timeout();
    powerup thread powerup_wobble();
    powerup thread powerup_grab();
    powerup thread powerup_move();
    powerup thread powerup_emp();
    level.zombie_vars["zombie_drop_item"] = 0;
    level notify( "powerup_dropped", powerup );
}

// ============================================================================
//  zmqol_enable_dog_rounds  -  HELLHOUNDS ON EVERY MAP THAT CAN SPAWN THEM
//                                                    (reworked v2.16.7)
// ----------------------------------------------------------------------------
//  🛑 THE v2.3.4 SQUELCH DESCRIBED BELOW IS SUPERSEDED AND NO LONGER SHIPS.
//  User, 2026-09-14: *"make sure hellhounds work for all the maps that don't
//  have them natively ... get hellhounds working for diner ... every single
//  map."* Diner and Nuketown are enabled again. The v2.3.4-v2.3.8 history
//  below is kept as the record of why they were dropped and what the
//  Diner-specific handler involved; the function itself carries the current
//  contract. The Diner location's own logic is untouched and still owns Diner.
// ----------------------------------------------------------------------------
//  User, 2026-08-25: *"because of how much of a hassle it's been to get
//  hellhounds working on Diner survival, and Nuketown survival, just drop it
//  at this point ... leave the regular vanilla stock game hellhound supported
//  maps eg. bus depot, farm, town ... exactly as they are."*
//
//  🛑 v2.3.4 GOT NUKETOWN WRONG: it hid the lobby row and assumed that was
//  enough, leaving this function's stock body running unchanged for Nuketown.
//  It was never verified against the tweakable's own default. It is not
//  enabled=0: `_tweakables.gsc:342`, `registertweakable( "killstreak",
//  "allowdogs", "scr_hardpoint_allowdogs", 1 )` - the trailing 1 IS the
//  default. With the lobby row gone, nothing ever writes this setting, so
//  `getgametypesetting( "allowdogs" )` in zstandard.gsc resolves to that
//  default of 1 (ON) - hiding the toggle made hellhounds unconditionally ON,
//  the opposite of "drop it". User confirmed 2026-08-26 they still see them.
//  Fixed by folding Nuketown into this same no-op, keyed on `mapname` (its
//  own map file, unlike Diner which is a location inside zm_transit).
//
//  🛑 THE LOBBY ROW COULD NOT BE REMOVED FOR DINER ALONE, AND THIS IS WHY.
//  Nuketown's row WAS its own mod-only addition and its removal
//  (privategamelobby_project.lua) is correct to keep - it just was not
//  sufficient by itself, per above. Diner's row is NOT its own - there is no
//  Diner-specific entry in GameTypeSettings[5].maps anywhere in that file.
//  Every TranZit survival location (Diner, Farm, Town, Bus Depot) shares the
//  SAME stock row, `maps[1] = "zm_transit"`, because the lobby's map
//  whitelist works by MAP FILE, not by location - Diner has no map file of
//  its own, it is a location inside zm_transit's. Removing that row to hide
//  it from Diner would ALSO hide it from Bus Depot / Farm / Town, which the
//  user explicitly wants kept exactly as they are. So the lobby option stays
//  VISIBLE on Diner - this is a real, reported limitation, not silently
//  dropped - and this hook is what makes it functionally inert there instead.
//
//  🌟 THE HOOK POINT, AND WHY zstandard_main() ITSELF CANNOT BE ONE. Every
//  TranZit survival location runs the same shared
//  maps\mp\gametypes_zm\zstandard.gsc::zstandard_main():
//        level.dog_rounds_allowed = getgametypesetting( "allowdogs" );
//        if ( level.dog_rounds_allowed )
//            maps\mp\zombies\_zm_ai_dogs::enable_dog_rounds();
//  zstandard_main itself is called through an UNQUALIFIED same-file pointer
//  (`rungametypemain( "zstandard", ::zstandard_main )`), which AI_CONTEXT's
//  replaceFunc rule 1 rules out - replaceFunc cannot see a caller that never
//  goes through the qualified name. enable_dog_rounds() one line down IS
//  called fully qualified, so it is the earliest hookable point in the chain.
//  Nuketown's own zstandard.gsc runs the identical three lines (verified,
//  `Nuketown\maps\mp\gametypes_zm\zstandard.gsc:39`), so the same hook point
//  covers it with no separate registration needed.
//
//  🌟 THIS REPRODUCES STOCK'S ENTIRE FUNCTION BODY FOR EVERY MAP EXCEPT
//  DINER AND NUKETOWN - read from _zm_ai_dogs.gsc:49-57, copied verbatim
//  below the checks, not reinvented. Bus Depot, Farm, Town, and every other
//  hellhound map (Die Rise, Mob, Buried, Origins) call this exact same
//  function and get the exact same behaviour they always have; only the
//  Diner and Nuketown branches differ.
// ============================================================================
zmqol_enable_dog_rounds()
{
    //  ========================================================================
    //  🛑 v2.16.7 - THE v2.3.4 "DROP HELLHOUNDS FROM DINER AND NUKETOWN" HOOK
    //  IS REVERSED. User, 2026-09-14: *"make sure hellhounds work for all the
    //  maps that don't have them natively ... get hellhounds working for diner
    //  ... every single map ... the spawns are really buggy, one spawned inside
    //  the car and then it just disappeared."*
    //
    //  Diner and Nuketown both ship the FULL hellhound asset set and are
    //  re-enabled here. The Diner-specific arena pruning + garage choke point in
    //  zm_transit_loc_diner.gsc are left in place and still own that map (see
    //  zmqol_dog_owns_this_map() below) - this hook only takes over the maps
    //  that had no fix of their own.
    //
    //  🌟 THE PLACEMENT FIX IS THE POINT. Stock spawns every hellhound at
    //  level.dog_spawners[0] (one actor at the world origin) then dog_spawn_fx()
    //  teleports it to a point from level.enemy_dog_locations - the map's
    //  scattered `dog_location` structs. Those sit wherever the level designer
    //  tagged them, which on Tunnel is a car body. level.zombie_spawn_locations
    //  is the list the regular zombies rise from: ground level, in the active
    //  arena, already filtered by _zm_zonemgr to enabled+active zones.
    //  zmqol_dog_spawn_logic() prefers it and only falls back to the dog structs.
    //
    //  🛑 THE EMPTY-SPAWNER HANG, STOCK'S OWN BLIND SPOT. A map with
    //  dog_location structs but no `zombie_dog_spawner` actor gets an empty
    //  level.dog_spawners from _zm_ai_dogs::dog_spawner_init(), and
    //  dog_round_spawning() then calls spawn_zombie( level.dog_spawners[0] ) =
    //  spawn_zombie( undefined ), which returns undefined WITHOUT incrementing
    //  `count`. The dog round's while loop never terminates and the match is
    //  lost. Stock has no guard; this hook refuses to start a round it cannot
    //  populate and says so in the log instead.
    //  ========================================================================
    //  ------------------------------------------------------------------
    //  v2.16.9 - PARKED ON THE MOD'S OWN SURVIVAL LOCATIONS.
    //  User, 2026-09-15, live on Tunnel at round 2: *"they're spawning
    //  outside of the tunnel, like inside of the tunnel through the walls,
    //  none in the actual playable area ... if they do manage to get to me
    //  they'll run at me, start attacking me for like 15 seconds, and then
    //  just teleport away or despawn ... then run through the walls and
    //  glitch the hell out."* Then: *"make sure the option to enable
    //  hellhounds is disabled on maps that don't work with it, just keep it
    //  on the regular maps that are in the base game that already have
    //  hellhounds that work normally."*
    //
    //  The despawn is the engine deleting an actor it cannot path: the four
    //  locations below are survival arenas this mod adds to maps whose zone
    //  data was never authored for dog rounds, so the spawn list legitimately
    //  contains points outside the arena's walls. This is not fixable by
    //  filtering the list here. The proper fix needs the placement validation
    //  that v2.16.9 prototyped, and that cannot ship in THIS file: it is on a
    //  compiled-bytecode ceiling (see item 1b in the workspace AGENTS.md), and
    //  +944 bytes of code took 14 unrelated imports down with it. When the
    //  work resumes, it belongs in its own raw script under scripts\zm\.
    //
    //  Stock dog maps are untouched and keep stock behaviour. Bus Depot is
    //  deliberately NOT named: its location token is not confirmed here, so
    //  the test denies the four known mod locations rather than allow-listing
    //  stock ones, and no stock start can be switched off by accident.
    //  ------------------------------------------------------------------
    //  Only the four survival arenas this mod adds to zm_transit need naming.
    //  The mod's other added locations live on zm_highrise, zm_prison, zm_tomb
    //  and zm_buried, none of which ship a zombie_dog_spawner, so the existing
    //  guard below already turns dog rounds off there. Nothing stock is named,
    //  so no base-game start can be switched off by accident.
    s_dog_loc = getdvar( "ui_zm_mapstartlocation" );

    if ( s_dog_loc == "tunnel" || s_dog_loc == "diner" || s_dog_loc == "cornfield" || s_dog_loc == "power" )
    {
        println( "[zm_qol] hellhounds: location has no authored dog arena - dog rounds left off" );
        return;
    }

    if ( !isdefined( level.dog_spawners ) || level.dog_spawners.size == 0 )
    {
        println( "[zm_qol] hellhounds: no zombie_dog_spawner on this map - dog rounds left off (stock would hang the round)" );
        return;
    }

    level.dog_rounds_enabled = 1;

    //  Stock _zm_ai_dogs::enable_dog_rounds(), unchanged - EXCEPT the tracker
    //  pointer, which has to be qualified here. Stock writes it as a bare
    //  ::dog_round_tracker because IT lives in _zm_ai_dogs.gsc, where that
    //  resolves to _zm_ai_dogs::dog_round_tracker by same-file default. This
    //  function lives in quality_of_life.gsc instead, where a bare
    //  ::dog_round_tracker would look for that name in THIS file and fail to
    //  resolve at load - qualifying it is not a style choice, it is required.
    //  An override somebody else already set still wins, exactly as stock.
    if ( !isdefined( level.dog_round_track_override ) )
        level.dog_round_track_override = maps\mp\zombies\_zm_ai_dogs::dog_round_tracker;

    //  The Diner location script installs its own spawn logic and two watchdogs
    //  from its own main(); when it has, it owns this map and none of the
    //  generic machinery below runs. Otherwise this hook owns every map.
    //  v2.16.9 - the generic placement override is NOT installed any more.
    //  It existed to make hellhounds usable on arenas this mod adds, and that
    //  is the work the user parked on 2026-09-15. Dog rounds now only reach
    //  this line on maps the base game already authored for them, where stock
    //  placement is what "works normally", so stock keeps the wheel. The
    //  functions below are left defined: zm_transit_loc_diner.gsc:2017 still
    //  points level.dog_spawn_func at zmqol_dog_spawn_logic for its own arena,
    //  and deleting them would break that file's link.
    level thread [[ level.dog_round_track_override ]]();
}

//  True when a location script has taken over this map's dog behaviour itself
//  (currently only Diner). Keyed on the snapshot the location script publishes
//  in zmqol_diner_dog_init(), which every generic entry point checks.
zmqol_dog_owns_this_map()
{
    return ( isdefined( level.zmqol_diner_dog_locs ) && level.zmqol_diner_dog_locs.size > 0 );
}

// ============================================================================
//  Generic hellhound support - the spawn placement, the fallback snapshot and
//  the repair watchdog, for every map except the one a location script owns.
// ----------------------------------------------------------------------------
//  Everything here is referenced only from quality_of_life.gsc, which loads on
//  every map, and only calls _zm_ai_dogs / _zm_utility / _zm_zonemgr - all core
//  zombies modules that ship in patch_zm.ff / common_zm.ff on all six maps, so
//  no map-specific external is named (AI_CONTEXT rule 2).
// ============================================================================

//  zmqol_dog_snapshot_locations() was deleted in v2.16.9. It filled
//  level.zmqol_dog_locs as a last-resort fallback list for the generic
//  placement override, and with that override no longer installed its only
//  caller was gone. It is recoverable from commit de340cb if the parked
//  custom-arena work resumes, and that is where it should be rebuilt: in a
//  separate raw script, not here. This file is on a compiled-bytecode ceiling
//  (workspace AGENTS.md item 1b) and deleting this function is what paid
//  for the location gate above.
//
//  zmqol_dog_spawn_logic below is now reached only through
//  zm_transit_loc_diner.gsc:2017, which sets level.dog_spawn_func itself.
//  Picks the spawn point for one hellhound. Stock's dog_spawn_func contract is
//  ( dog_array, favorite_enemy ) -> an entity whose .origin the dog is
//  teleported to. dog_array is level.dog_spawners (the actor spawners at the
//  world origin) and is deliberately ignored, exactly as stock's own
//  dog_spawn_transit_logic() ignores it.
zmqol_dog_spawn_logic( dog_array, favorite_enemy )
{
    //  Pass 1 - ground zombie spawn locations, stock's own 400-1150 unit window
    //  (160000 and 1322500 are 400^2 and 1150^2, read from zm_transit.gsc:2925).
    loc = zmqol_dog_pick_from( level.zombie_spawn_locations, 160000, 1322500, 1 );

    //  Pass 2 - same ground list, window relaxed rather than giving up.
    if ( !isdefined( loc ) )
        loc = zmqol_dog_pick_from( level.zombie_spawn_locations, 90000, 2250000, 0 );

    //  Pass 3 - the map's own dog structs, relaxed.
    if ( !isdefined( loc ) )
        loc = zmqol_dog_pick_from( level.enemy_dog_locations, 90000, 2250000, 0 );

    //  Pass 4 - the init snapshot, no distance test. On a map a location script
    //  owns, that script's own snapshot is the better list - Diner's is pruned
    //  to its arena - so prefer it when it exists (v2.16.8, when Diner started
    //  using this picker instead of its own).
    if ( !isdefined( loc ) )
        loc = zmqol_dog_pick_from( level.zmqol_diner_dog_locs, 0, 0, 0 );

    if ( !isdefined( loc ) )
        loc = zmqol_dog_pick_from( level.zmqol_dog_locs, 0, 0, 0 );

    //  Pass 5 - anything at all, so dog_spawn_fx is never handed undefined.
    if ( !isdefined( loc ) )
        loc = zmqol_dog_pick_from( level.zombie_spawn_locations, 0, 0, 0 );

    if ( isdefined( loc ) )
    {
        level.old_dog_spawn = loc;
        println( "[zm_qol] hellhounds: spawn point (" + int( loc.origin[0] ) + "," + int( loc.origin[1] ) + "," + int( loc.origin[2] ) + ")" );
    }
    else
    {
        println( "[zm_qol] hellhounds: WARNING no spawn location available at all - dog may be stranded" );
    }

    return loc;
}

//  A location that is i_min2..i_max2 units-squared from EVERY player (b_strict),
//  or any valid location when not strict. Randomised so consecutive dogs differ.
zmqol_dog_pick_from( a_locs, i_min2, i_max2, b_strict )
{
    if ( !isdefined( a_locs ) || a_locs.size == 0 )
        return undefined;

    a_shuffled = array_randomize( a_locs );

    for ( i = 0; i < a_shuffled.size; i++ )
    {
        s = a_shuffled[i];

        if ( !isdefined( s ) || !isdefined( s.origin ) )
            continue;

        if ( b_strict )
        {
            if ( isdefined( level.old_dog_spawn ) && level.old_dog_spawn == s )
                continue;

            b_ok = 1;

            foreach ( player in get_players() )
            {
                if ( !b_ok )
                    continue;

                d2 = distancesquared( s.origin, player.origin );

                if ( d2 < i_min2 || d2 > i_max2 )
                    b_ok = 0;
            }

            if ( !b_ok )
                continue;
        }

        return s;
    }

    return undefined;
}

//  Runs for the life of the match. Re-asserts level.dog_spawn_func whenever a
//  per-map script (TranZit's survival_init) has re-pointed it, so every dog
//  round - and every mid-round special_dog_spawn() - uses the ground picker.
zmqol_dog_spawn_director()
{
    level endon( "end_game" );

    for ( ;; )
    {
        wait 1;

        if ( zmqol_dog_owns_this_map() )
            return;

        level.dog_spawn_func = ::zmqol_dog_spawn_logic;
    }
}

//  Repairs a dog whose stock dog_spawn_fx() thread died partway (invisible,
//  invulnerable, ignoreme), returns a stranded or runaway dog to a real spawn
//  point, and force-returns the sole remaining dog after 20s so a dog round can
//  never hang. A condensed, map-agnostic port of zmqol_diner_dog_watchdog().
zmqol_dog_watchdog()
{
    level endon( "end_game" );

    v_spawner = ( 0, 0, 0 );

    if ( isdefined( level.dog_spawners ) && level.dog_spawners.size > 0 && isdefined( level.dog_spawners[0] ) )
        v_spawner = level.dog_spawners[0].origin;

    for ( ;; )
    {
        wait 1;

        if ( zmqol_dog_owns_this_map() )
            return;

        a_ai = getaiarray( level.zombie_team );

        for ( i = 0; i < a_ai.size; i++ )
        {
            ai = a_ai[i];

            if ( !isdefined( ai ) || !isalive( ai ) )
                continue;

            if ( !( isdefined( ai.isdog ) && ai.isdog ) )
                continue;

            if ( !isdefined( ai.zmqol_dog_seen ) )
            {
                ai.zmqol_dog_seen = gettime();
                continue;
            }

            //  dog_spawn_fx takes 1.5s of its own before it teleports.
            if ( gettime() - ai.zmqol_dog_seen < 4000 )
                continue;

            //  ------------------------------------------------ pre-spawn repair
            if ( !isdefined( ai.zmqol_dog_state_fixed ) )
            {
                ai.zmqol_dog_state_fixed = 1;
                str_fixed = "";

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

                //  disablearrivals is the last write of stock's
                //  zombie_setup_attack_properties_dog(), so it doubles as a
                //  "did that function complete" flag - and gating the growl
                //  thread on it stops a healthy dog growling twice.
                if ( !( isdefined( ai.disablearrivals ) && ai.disablearrivals ) )
                {
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
                    println( "[zm_qol] hellhounds: a dog was still in its pre-spawn state after 4s -" + str_fixed + " - stock's dog_spawn_fx did not finish. Repaired." );
            }

            //  ------------------------------------------------ last-dog timeout
            if ( a_ai.size == 1 )
            {
                if ( !isdefined( ai.zmqol_dog_lastone_since ) )
                    ai.zmqol_dog_lastone_since = gettime();

                if ( !isdefined( ai.zmqol_dog_lastone_rescued ) && gettime() - ai.zmqol_dog_lastone_since >= 20000 )
                {
                    ai.zmqol_dog_lastone_rescued = 1;
                    s_home = zmqol_dog_home_point( ai );
                    ai forceteleport( s_home.origin, ai.angles );
                    zmqol_dog_reassert( ai );
                    println( "[zm_qol] hellhounds: LAST ZOMBIE TIMEOUT - sole remaining dog force-returned to a spawn point" );
                }
            }
            else
            {
                ai.zmqol_dog_lastone_since   = undefined;
                ai.zmqol_dog_lastone_rescued = undefined;
            }

            //  ------------------------------------------------ out-of-arena rescue
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
                        s_home = zmqol_dog_home_point( ai );
                        ai forceteleport( s_home.origin, ai.angles );
                        zmqol_dog_reassert( ai );
                        println( "[zm_qol] hellhounds: RUNAWAY DOG was in no enabled zone - returned to a spawn point" );
                    }
                }
            }

            //  ------------------------------------------------ stranded at spawner
            if ( isdefined( ai.zmqol_dog_rescued ) )
                continue;

            if ( distancesquared( ai.origin, v_spawner ) > 4096 )     //  64 units
                continue;

            ai.zmqol_dog_rescued = 1;
            s_loc = zmqol_dog_home_point( ai );
            ai forceteleport( s_loc.origin, ai.angles );
            zmqol_dog_reassert( ai );
            println( "[zm_qol] hellhounds: STRANDED DOG rescued to a spawn point" );
        }
    }
}

//  Nearest ground zombie spawn location to a dog, so a rescue drops it back into
//  the fight rather than across the map. Falls back to the snapshot, then the
//  map's dog structs, then the spawner itself.
zmqol_dog_home_point( ai )
{
    best  = undefined;
    //  🛑 NOT 9999999999 - a GSC int literal is parsed with the engine's stoi(),
    //  and anything above INT_MAX (2147483647) throws "stoi argument out of
    //  range", which is a fatal COM_ERROR at script load. This is the largest
    //  valid int, and distancesquared() is clamped well below it in practice.
    bestd = 2147483647;

    if ( isdefined( level.zombie_spawn_locations ) )
    {
        for ( i = 0; i < level.zombie_spawn_locations.size; i++ )
        {
            s = level.zombie_spawn_locations[i];

            if ( !isdefined( s ) || !isdefined( s.origin ) )
                continue;

            d = distancesquared( ai.origin, s.origin );

            if ( d < bestd )
            {
                bestd = d;
                best  = s;
            }
        }
    }

    if ( isdefined( best ) )
        return best;

    if ( isdefined( level.zmqol_dog_locs ) && level.zmqol_dog_locs.size > 0 )
        return level.zmqol_dog_locs[randomint( level.zmqol_dog_locs.size )];

    if ( isdefined( level.enemy_dog_locations ) && level.enemy_dog_locations.size > 0 )
        return level.enemy_dog_locations[randomint( level.enemy_dog_locations.size )];

    return level.dog_spawners[0];
}

//  The tail of stock's dog_spawn_fx(), in stock's order, used by every rescue.
zmqol_dog_reassert( ai )
{
    if ( isdefined( ai.magic_bullet_shield ) && ai.magic_bullet_shield == 1 )
        ai maps\mp\zombies\_zm_utility::stop_magic_bullet_shield();

    ai show();
    ai setfreecameralockonallowed( 1 );
    ai.ignoreme  = 0;
    ai.ignoreall = 0;
    ai notify( "visible" );
}

// ============================================================================
//  init() - combined from all 17 modules + the Vanguard Perk Animation
//           connect loop. Each module's original init() body runs from here;
//           per-player connect/spawn loops were renamed with a short module
//           prefix to avoid name collisions (every module used to be its own
//           file, so they could all be called init()/onplayerconnect()/
//           onplayerspawned() without conflict).
// ============================================================================
// ============================================================================
//  zmqol_restore_perk_bottles_on_survival
//
//  🛑 Fixes: drinking a perk from the Wunderfizz on any custom survival location
//     plays no animation and leaves the player permanently unable to sprint,
//     shoot or melee. Reported on Origins/Trenches 2026-08-02.
//
//  THE CHAIN, traced end to end:
//
//  1. maps\mp\zombies\_zm_perks::perk_machine_spawn_init() only spawns a perk
//     machine when a "zm_perk_machine" struct's script_string contains
//     "<ui_gametype>_perks_<start location>". Dumping every shipped mapents with
//     OAT's Unlinker shows NO struct is tagged for any location this mod adds:
//         zm_tomb  - 6 structs, 5 tagged "zclassic_perks_tomb", 1 untagged (the
//                    Pack-a-Punch). Nothing for trenches/excavation_site/church/
//                    crazy_place. (zm_qol ships no zm_tomb mapents at all.)
//         zm_highrise 8/8 tagged, zm_prison 11/11, zm_transit 43/43, zm_buried
//                    14/14 - none tagged for Diner, Tunnel, Power, Docks, or the
//                    three Die Rise locations.
//     So those locations spawn ZERO perk machines.
//
//  2. _zm_perks::init() then does (stock line ~52):
//         vending_triggers = getentarray( "zombie_vending", "targetname" );
//         ...move every "specialty_weapupgrade" trigger OUT of that array...
//         if ( vending_triggers.size < 1 )
//             return;                       <-- BAILS
//     Origins' one untagged machine IS the Pack-a-Punch, so it gets moved out and
//     the array is empty. init() returns early on every custom survival location.
//
//  3. Everything that builds the perk-bottle system lives AFTER that return:
//         level.machine_assets = [];
//         [[ level.custom_vending_precaching ]]();   <- precacheitem() of every
//                                                       "zombie_perk_bottle_*"
//                                                       and the machine_assets
//                                                       lookup table
//
//  4. The Wunderfizz still works and still hands out perks, because
//     _zm_perk_random is a separate system. On grab it calls
//     _zm_perks::perk_give_bottle_begin( perk ), which does:
//         self increment_is_drinking();
//         self disable_player_move_states( 1 );      <- sprint/fire/melee OFF
//         weapon = level.machine_assets["juggernog"].weapon;   <- undefined table
//         self giveweapon( weapon ); self switchtoweapon( weapon );
//     With no weapon to switch to, "weapon_change_complete" never fires, so
//     _zm_perk_random::grab_check() blocks forever on its waittill_any_return and
//     perk_give_bottle_end() - the ONLY caller of enable_player_move_states() -
//     never runs. That is the reported soft-lock exactly.
//
//  THE FIX
//
//  Do what the bail skipped: create level.machine_assets and run the map's own
//  vending precache. custom_vending_precaching touches no entities - it is purely
//  precacheitem/precachemodel/loadfx plus building machine_assets - so calling it
//  without any machines present is safe. Its first block also walks
//  level._custom_perks[*].precache_func, which is what precaches
//  "zombie_perk_bottle_cherry" for Electric Cherry (specialty_grenadepulldeath is
//  in Origins' Wunderfizz rotation but has no case in perk_give_bottle_begin's
//  switch - it resolves through level._custom_perks[perk].perk_bottle instead).
//
//  Root script on purpose: the same bail hits Origins x4, Die Rise x3, Docks,
//  Diner, Tunnel and Power. Nothing referenced here is map-specific -
//  level.custom_vending_precaching is a level var and _zm_perks is globally safe
//  per AI_CONTEXT rule 2 - so this is legal in quality_of_life.gsc.
//
//  Guards:
//    - is_classic() -> never touches a classic map, where init() does not bail.
//    - isdefined( level.machine_assets ) -> no-ops wherever _zm_perks::init()
//      completed normally, so any location that already worked is untouched. This
//      is also what makes it safe if perk machines are ever added to a loc script
//      or the mapents get patched: the fix simply stops applying.
//    - level.custom_vending_precaching is defaulted here because stock only
//      defaults it AFTER the bail; maps that do not set it themselves would
//      otherwise have it undefined. (Origins sets it in zm_tomb::main().)
//
//  Must run in init(): level.custom_vending_precaching and level._custom_perks are
//  populated by the map's main(), which runs after this mod's main(). init() is
//  still inside the precache window - the precacheitem() calls immediately below
//  in this same function have always worked.
//
//  🛑 NOT verified in game yet.
// ============================================================================
zmqol_restore_perk_bottles_on_survival()
{
    if ( is_classic() )
        return;

    // _zm_perks::init() got past its bail - nothing to repair.
    if ( isdefined( level.machine_assets ) )
        return;

    level.machine_assets = [];

    if ( !isdefined( level.custom_vending_precaching ) )
        level.custom_vending_precaching = maps\mp\zombies\_zm_perks::default_vending_precaching;

    [[ level.custom_vending_precaching ]]();

    //  v1.99.30 - THE SAME BAIL ALSO SKIPS STOCK'S PACK-A-PUNCH THREAD.
    //  _zm_perks::init() reaches `if ( vending_triggers.size < 1 ) return;`
    //  BEFORE its `array_thread( vending_weapon_upgrade_trigger,
    //  ::vending_weapon_upgrade )`, so on every location listed above there is no
    //  stock Pack-a-Punch machine logic running at all - the mod's own trigger is
    //  the only Pack-a-Punch those locations have ever had.
    //
    //  So the INSTANT PAP switch has nothing to hand the machine back TO here,
    //  and qol_instant_pap.gsc::qol_ipap_mode_watch() keeps instant mode on
    //  when it sees this. Turning it off would otherwise leave the location
    //  with no working Pack-a-Punch.
    level.qol_pap_stock_missing = 1;
}

// ============================================================================
//  zm_qol: SOLO INTRO CUTSCENE PROBE
//
//  The menu LUI (ui/t6/menus/privateonlinegamelobby.lua, zmQolForceSoloPartySize)
//  stashes what it saw into "zmqol_loadmovie_probe" just before the match
//  launches. The loading-movie decision itself happens in LUI, before any map
//  loads, so no GSC hook can observe it directly - but the dvar survives into
//  the game, and this prints it to console_zm.log.
//
//  Why a probe at all: the recent boot logs' dvar dumps are TRUNCATED (337
//  lines, alphabetically short of party_*), so party_maxplayers cannot be read
//  back from them. Without this, a failed boot tells us nothing.
//
//  Reads "before=" (what the party system had) and "after=" (what we set).
//  Diagnostic only - delete once the cutscene is confirmed working.
// ============================================================================
zmqol_loadmovie_probe()
{
    probe = getdvar( "zmqol_loadmovie_probe" );

    if ( isdefined( probe ) && probe != "" )
        println( "[zm_qol] loadmovie probe: " + probe );
    else
        println( "[zm_qol] loadmovie probe: <unset> - the menu hook did not run" );
}

// ============================================================================
//  zm_qol: DISCORD RICH PRESENCE - THE MOD'S NAME ON THE PLAYER'S PROFILE
//
//  User request, 2026-09-05: *"add custom discord rpc just like how the bo2
//  reimagined mod does, but for my Quality of life mod ... this way if someone
//  is using my mod people can see based off viewing their profile on discord."*
//
//  There is NO Discord API in GSC and none in LUI, and Plutonium's own rich
//  presence cannot be replaced by a mod. What it CAN be fed is the server name.
//  Measured 2026-09-05 out of plutonium-bootstrapper-win32.exe: the presence
//  code's string block is
//        cl_enableStreamerMode | mapname | g_gametype | sv_hostname |
//        sv_maxclients | cl_ingame | \^\d|\^:|\^; | %s on %s | loopback | Main menu
//  - five dvars, a colour-code stripper, and "<gametype> on <map>". The line
//  UNDER that one on a Discord profile is sv_hostname, so writing the mod's
//  name there is what puts "Quality Of Life" in front of anyone who looks.
//
//  🌟 THE WORKING PRECEDENT, and the mod the user pointed at:
//  BO2-Reimagined\scripts\zm\_zm_reimagined.gsc:855-856, set_dvars(), called
//  from that file's own init():
//        setDvar( "sv_hostname", "Reimagined" );
//        makedvarserverinfo( "sv_hostname" );
//  No Discord code anywhere in that repo - this dvar IS its "custom RPC".
//
//  Why the guard: three values mean "nobody chose this name", and only those are
//  replaced.
//        ""               nothing set yet
//        "CoDHost"        stock gametypes_zm\_serversettings.gsc:6-11, which
//                         writes it whenever sv_hostname is empty
//        "Private Match"  🌟 what PLUTONIUM itself puts there for a private
//                         match - measured 2026-09-05 in the user's own dvar
//                         dump (console_zm.log: sv_hostname "Private Match")
//  Anything else is a server owner's or a player's own name and is left alone,
//  which doubles as the opt-out. Stock's 5-second updateserversettings() loop
//  only READS sv_hostname (:64-68), so nothing fights this back.
//
//  🛑 v2.12.2 SHIPPED WITHOUT THE "Private Match" CASE AND DID NOTHING AT ALL.
//  The user's profile still read "Private Match" and the log said
//  `sv_hostname is already 'Private Match' - left alone`. That log line is also
//  the proof this route works: the third line of a Discord profile is
//  sv_hostname VERBATIM - "Private Match" was never a Discord label, it was the
//  dvar's value. Write the mod's name there and the mod's name is what shows.
// ============================================================================
zmqol_discord_presence()
{
    if ( zmqol_presence_set() )
        println( "[zm_qol] discord presence: sv_hostname = '" + getdvar( "sv_hostname" ) + "'" );
    else
        println( "[zm_qol] discord presence: sv_hostname is already '" + getdvar( "sv_hostname" ) + "' - left alone" );

    level thread zmqol_presence_watch();
}

//  Writes the name only over the three "nobody chose this" values, and reports
//  whether it wrote. Once the name IS "Quality Of Life" this returns 0 without
//  touching anything, so the watcher below costs one string compare every five
//  seconds and never spams the log.
zmqol_presence_set()
{
    host = getdvar( "sv_hostname" );

    if ( isdefined( host ) && host != "" && host != "CoDHost" && host != "Private Match" )
        return 0;

    setdvar( "sv_hostname", "Quality Of Life" );
    makedvarserverinfo( "sv_hostname" );
    return 1;
}

//  Why a watcher and not just the one write: "Private Match" is PLUTONIUM's
//  value, not the game's, and nothing on this machine can prove when it is
//  assigned relative to this script's init() - the dvar dump in the 2026-09-05
//  log sits BEFORE the mod's own line, so it only proves the value was there
//  first, never that it cannot be written again. Five seconds of re-assert
//  closes that whole question; a name the user or a server owner set still
//  wins, because zmqol_presence_set() refuses to overwrite it.
zmqol_presence_watch()
{
    level endon( "end_game" );

    for ( ;; )
    {
        wait 5;

        if ( zmqol_presence_set() )
            println( "[zm_qol] discord presence: sv_hostname was overwritten - re-set to 'Quality Of Life'" );
    }
}

init()
{
    zmqol_loadmovie_probe();
    zmqol_discord_presence();   // mod name on the Discord profile (v2.12.2)
    zmqol_restore_perk_bottles_on_survival();
    zmqol_register_divetonuke_visionset();
    zmqol_arm_divetonuke_explosion();   // v2.15.53 - PhD dive explodes without a machine
    zmqol_register_vulture_visionset();
    zmqol_register_zombie_blood_visionsets();
    zmqol_box_wonder_weapon_weights_init();
    zmqol_mp_weapons_init();
    zmqol_wallbuy_box_init();
    level thread zmqol_wallbuy_box_reassert();
    level thread zmqol_wallbuy_variant_keep();   // wall buy = the box's variant (v1.99.91)
    level thread zmqol_stranded_zombie_probe();
    level thread zmqol_round_dvar_watch();
    level thread zmqol_credits_banner();
    level thread zmqol_team_emblem_watch();     // scoreboard CDC/CIA emblem (v1.99.61)
    level thread zmqol_perk_slot_connect();
    level thread zmqol_blood_money_natural_drop();
    level thread zmqol_fire_sale_custom_gate();  // FIRE SALE under CUSTOM POWER-UPS (v2.0.5)
    level thread zmqol_bonfire_sale_custom_gate();  // BONFIRE SALE under CUSTOM POWER-UPS (v2.12.0)
    level thread zmqol_bs_announcer_watch();     // ...and the announcer line stock never wired (v2.12.6)
    level thread zmqol_register_announcer_vox();
    level thread zmqol_dof_repoint_spawnintermission();  // DOF full fix, item 48
    level thread zmqol_dof_onplayerconnect();            // DOF full fix, item 48
    level thread zmqol_perma_perks_watch();              // PERMA-PERKS, queue item 29
    level thread zmqol_no_walkers_watch();               // NO WALKERS, user request 2026-08-30
    level thread zmqol_no_limited_weapons_watch();        // NO BOX LIMITS reaches the ported wonder weapons (v2.9.15)
    level thread zmqol_dim_cherry_arcs();                // Electric Cherry kill arc -> secondary (v2.9.30)

    // --- zm_expanded: weapon precache + weapon-limit monitor hook ---
    precacheitem( "uzi_zm" );
    precacheitem( "uzi_upgraded_zm" );
    precacheitem( "thompson_zm" );
    precacheitem( "thompson_upgraded_zm" );
    precacheitem( "ak47_zm" );
    precacheitem( "ak47_upgraded_zm" );
    precacheitem( "mp40_stalker_zm" );
    precacheitem( "mp40_stalker_upgraded_zm" );
    precacheitem( "scar_zm" );
    precacheitem( "scar_upgraded_zm" );
    precacheitem( "mg08_zm" );
    precacheitem( "mg08_upgraded_zm" );
    precacheitem( "minigun_alcatraz_zm" );
    precacheitem( "minigun_alcatraz_upgraded_zm" );
    precacheitem( "evoskorpion_zm" );
    precacheitem( "evoskorpion_upgraded_zm" );
    precacheitem( "hk416_zm" );
    precacheitem( "hk416_upgraded_zm" );
    precacheitem( "ksg_zm" );
    precacheitem( "ksg_upgraded_zm" );
    precacheitem( "pdw57_zm" );
    precacheitem( "pdw57_upgraded_zm" );
    precacheitem( "mp44_zm" );
    precacheitem( "mp44_upgraded_zm" );
    precacheitem( "ballista_zm" );
    precacheitem( "ballista_upgraded_zm" );
    precacheitem( "rnma_zm" );
    precacheitem( "rnma_upgraded_zm" );
    precacheitem( "an94_zm" );
    precacheitem( "an94_upgraded_zm" );
    precacheitem( "lsat_zm" );
    precacheitem( "lsat_upgraded_zm" );
    precacheitem( "svu_zm" );
    precacheitem( "svu_upgraded_zm" );
    precacheitem( "c96_zm" );
    precacheitem( "c96_upgraded_zm" );

    // Tranzit weapons
    precacheitem( "beretta93r_extclip_zm" );
    precacheitem( "beretta93r_extclip_upgraded_zm" );
    precacheitem( "ak74u_extclip_zm" );
    precacheitem( "ak74u_extclip_upgraded_zm" );
    precacheitem( "qcw05_zm" );
    precacheitem( "qcw05_upgraded_zm" );
    precacheitem( "sf_qcw05_upgraded_zm" );
    precacheitem( "type95_zm" );
    precacheitem( "type95_upgraded_zm" );
    precacheitem( "gl_type95_zm" );
    precacheitem( "xm8_zm" );
    precacheitem( "xm8_upgraded_zm" );
    precacheitem( "gl_xm8_zm" );
    precacheitem( "python_zm" );
    precacheitem( "python_upgraded_zm" );
    precacheitem( "saritch_zm" );
    precacheitem( "saritch_upgraded_zm" );
    precacheitem( "dualoptic_saritch_upgraded_zm" );
    precacheitem( "m16_zm" );
    precacheitem( "m16_gl_upgraded_zm" );
    precacheitem( "gl_m16_upgraded_zm" );
    precacheitem( "srm1216_zm" );
    precacheitem( "srm1216_upgraded_zm" );
    precacheitem( "kard_zm" );
    precacheitem( "kard_upgraded_zm" );
    //  m32_zm/_upgraded came out with the War Machine swap (gunswap.gsc,
    //  2026-10-07): a precache here would have kept both slots spent on every
    //  map, include_weapon ban or not. The rpd, hamr and barretm82 pairs joined
    //  them the same day (round 2: the M60, MK48 and Dragunov take their slots,
    //  and the stock saiga12/fiveseven pairs were never precached here).
    precacheitem( "m1911_zm" );
    precacheitem( "m1911_upgraded_zm" );
    precacheitem( "m1911lh_upgraded_zm" );
    level.player_too_many_weapons_monitor_func = ::player_too_many_weapons_monitor;

    // --- BO2DD ---
    level thread bo2dd_onplayerconnect();

    // --- bocw_round ---
    precacheshader( "hud_chalk_1" );
    precacheshader( "hud_chalk_2" );
    precacheshader( "hud_chalk_3" );
    precacheshader( "hud_chalk_4" );
    precacheshader( "hud_chalk_5" );
    level.round_think_func = ::round_think;
    thread round_hud();

    level thread zmqol_spawn_baseline_probe();   // DIAGNOSTIC - remove once Buried spawns

    // --- counterszm ---
    precacheshader( "specialty_chugabud_zombies" );
    precacheshader( "specialty_electric_cherry_zombie" );
    precacheshader( "specialty_vulture_zombies" );
    //  v2.8.1 - two precacheshader() calls were removed here:
    //      precacheshader( "minimap_icon_chugabud" );
    //      precacheshader( "minimap_icon_electric_cherry" );
    //  NO material called minimap_icon_* exists anywhere - not in any of the 132
    //  retail fastfiles and not in mod.ff (Unlinker --list over the whole
    //  zone\all set: 28,263 game materials + 920 mod materials, zero matches).
    //  Nothing else in the mod referenced either name, so they precached two
    //  assets that could never resolve and were never drawn. The three
    //  specialty_* icons above them are real and are kept.
    precacheshader( "zm_riotshield_tomb_icon" );
    precacheshader( "zm_riotshield_hellcatraz_icon" );
    precacheshader( "menu_mp_fileshare_custom" );
    level.navcards = undefined;
    level thread counters_onplayerconnect();

    // --- deathmachine weapon ---
    //  Bo2-VN: the Death Machine POWER-UP is removed. The weapon stays precached
    //  for `.give minigun` and for zm_prison.gsc's loadout scrub.
    precacheitem( "deathmachine_zm" );
    level.deathmachine_weapon = "deathmachine_zm";

    // --- high_round_fix ---
    //  🛑 v1.99.51 - THE THREE MOVEMENT-SPEED DVARS MOVED OUT OF HERE.
    //  They used to be written unconditionally on this line:
    //      player_backSpeedScale / player_strafeSpeedScale /
    //      player_sprintStrafeSpeedScale, all forced to 1.
    //  They are now owned by qol_options::qol_opt_move_speed(), so the new
    //  GAME > BACKSPEED PATCH row can turn them back to stock live. Writing
    //  them here as well would give the value two owners and the watcher's
    //  "off" would be overwritten on the next map load - the same
    //  single-owner rule the HUD elements follow.
    level thread zombie_health();
    level thread hrf_onplayerconnect();

    // --- instant_pap ---
    //  Moved to scripts/zm/qol_instant_pap.gsc, which creates pap_price,
    //  repap_price and instant_pap and starts the trigger from its own init().

    // --- No_Fog ---
    // (Disable_Fog_Transition moved OUT of this file on 2026-07-30 - it now
    //  lives at scripts/zm/zm_transit/disable_fog_transition.gsc; see the
    //  note at the top of this file for why a root script can't hold it.)
    level thread nofog_onplayerconnect();

    // --- noperklimit ---
    //  v2.15.50 - default 4 = the vanilla limit. 0 still means "as many as this
    //  map offers" and is the lobby row's MAP MAX choice, now opt-in.
    //  Set from the pre-game lobby's PERK LIMIT row; read in remove_perk_limit().
    create_dvar( "perk_limit", 4 );
    level thread remove_perk_limit();
    level thread perklimit_onplayerconnect();

    // --- secretsongsurvival ---
    level thread setteddybears();
    level thread sss_onplayerconnect();

    // --- areanotifier ---
    level thread an_onplayerconnect();

    // --- Vanguard Perk Animation (perk pop-up HUD; added 2026-07-30, replaces
    //     the old custom_perkanimuncompiled perkHUD). Icon shaders precached
    //     here because the pop-up now shows an icon + name + description for
    //     every perk; the chugabud / electric cherry / vulture icons are
    //     already precached up in the counterszm block.
    //     (Upstream's init() also printed a "created by techboy04gaming"
    //     iprintln at match start - REMOVED 2026-07-30 per user request;
    //     author credit stays in the source comments at the module below.) ---
    precacheshader( "specialty_juggernaut_zombies" );
    precacheshader( "specialty_quickrevive_zombies" );
    precacheshader( "specialty_fastreload_zombies" );
    precacheshader( "specialty_doubletap_zombies" );
    precacheshader( "specialty_marathon_zombies" );
    precacheshader( "specialty_divetonuke_zombies" );
    precacheshader( "specialty_ads_zombies" );
    precacheshader( "specialty_additionalprimaryweapon_zombies" );
    precacheshader( "specialty_tombstone_zombies" );

    //  v1.85.0 - stock's solo_tombstone_removal(), applied on every map rather
    //  than the two TranZit scripts that call it. See zmqol_tombstone_allowed().
    level thread zmqol_solo_tombstone_removal();

    // ".dm" used to be its own listener here. It is now one of the power-up chat
    // commands in zmqol_dev_command_listener() - see zmqol_powerup_alias(). Two
    // listeners both consuming "say" would have spawned two Death Machines.
}

// ============================================================================
//  BO2DD  (was BO2DD.gsc)
// ============================================================================
bo2dd_onplayerconnect()
{
    for (;;)
    {
        level waittill( "connected", player );
        player thread bo2dd_onplayerspawned();
        player setclientdvar( "r_lodBiasRigid", "-1000" );
        player setclientdvar( "r_lodBiasSkinned", "-1000" );
        //  🛑 v1.99.54 - r_dof_enable 0 removed, same reason as the identical
        //  line that used to sit in nofog_onplayerconnect(): the ADVANCED tab's
        //  DEPTH OF FIELD row owns that dvar now. The r_lodBias / r_lodScale
        //  lines around it are untouched - they are what this module is for.
        player setclientdvar( "r_lodScaleSkinned", "1" );
        player setclientdvar( "r_lodScaleRigid", "1" );
    }
}

bo2dd_onplayerspawned()
{
    self endon( "disconnect" );
    for (;;)
        self waittill( "spawned_player" );
}

// ============================================================================
//  zmqol_nuke_powerup  -  v1.99.48. INSTANT NUKE.
//
//  User request, 2026-08-18: "instead of the typical stock/vanilla effect of the
//  nuke where it sequentially kills the zombies one after another and takes a
//  little bit to finish and then give the points... it'll skip the sequence of
//  killing zombies, and just kill all the zombies at once that it normally
//  would, not any more or any less zombies though stock amount of zombies die to
//  the nuke it just is instant same with the points."
//
//  🌟 THIS IS STOCK'S OWN FUNCTION WITH ONE LINE GATED, AND NOTHING ELSE.
//  _zm_powerups::nuke_powerup() (:1445-1505) is straight-line code with no
//  branching to lose, so it can be reproduced exactly. The ONLY difference is
//  the first line of the kill loop:
//
//        wait( randomfloatrange( 0.1, 0.7 ) );      <- stock, per zombie
//
//  which is what staggers the deaths and is the whole of what the user is asking
//  to skip. Everything else is byte-for-byte stock's:
//    - the same `wait 0.5` before any killing, so the flash and its sound keep
//      their stock timing;
//    - the same four skip tests (ignore_nuke, marked_for_death,
//      nuke_damage_func, magic bullet shield), so **exactly the stock set of
//      zombies dies - no more, no fewer**, which the user asked for twice;
//    - the same `i < 5` cap on flame_death_fx, the same head gib, the same
//      "evt_nuked" per zombie, the same dodamage( health + 666, origin ) with no
//      attacker (which is why a nuke gives no hitmarkers, stock behaviour kept);
//    - the same 400 points to every player on the team, through stock's own
//      _zm_score::player_add_points.
//
//  🛑 THE DVAR IS READ ONCE, HERE, NOT PER ZOMBIE. Reading it inside the loop
//  would let a mid-nuke toggle strand half a wave, which is a state no stock
//  path can produce. One read at the top means a nuke behaves one way from start
//  to finish.
//
//  📝 DEFAULT ON. Same call as the power-up timers in v1.99.0: the user asked
//  for the feature, not merely for a switch. `instant_nuke 0` is exact vanilla -
//  the same function, taking the same wait stock takes.
//
//  📝 replaceFunc on a same-file unqualified call is safe HERE and it is not a
//  guess: _zm_powerups.gsc:1007 calls it as `level thread nuke_powerup(...)`,
//  and the threaded form is the case verified hookable in this project - the
//  mod's own new_full_ammo_powerup() below hooks :1014, the very next line of
//  the same switch, and has worked in game for many releases.
// ============================================================================
zmqol_nuke_powerup( drop_item, player_team )
{
    b_instant = getdvarintdefault( "instant_nuke", 1 );

    location = drop_item.origin;
    playfx( drop_item.fx, location );
    level thread maps\mp\zombies\_zm_powerups::nuke_flash( player_team );
    wait 0.5;
    zombies = getaiarray( level.zombie_team );
    zombies = arraysort( zombies, location );
    zombies_nuked = [];

    for ( i = 0; i < zombies.size; i++ )
    {
        if ( isdefined( zombies[i].ignore_nuke ) && zombies[i].ignore_nuke )
            continue;

        if ( isdefined( zombies[i].marked_for_death ) && zombies[i].marked_for_death )
            continue;

        if ( isdefined( zombies[i].nuke_damage_func ) )
        {
            zombies[i] thread [[ zombies[i].nuke_damage_func ]]();
            continue;
        }

        if ( is_magic_bullet_shield_enabled( zombies[i] ) )
            continue;

        zombies[i].marked_for_death = 1;
        zombies[i].nuked = 1;
        zombies_nuked[zombies_nuked.size] = zombies[i];
    }

    for ( i = 0; i < zombies_nuked.size; i++ )
    {
        //  The one line this whole feature is.
        if ( !b_instant )
            wait( randomfloatrange( 0.1, 0.7 ) );

        if ( !isdefined( zombies_nuked[i] ) )
            continue;

        if ( is_magic_bullet_shield_enabled( zombies_nuked[i] ) )
            continue;

        if ( i < 5 && !zombies_nuked[i].isdog )
            zombies_nuked[i] thread maps\mp\animscripts\zm_death::flame_death_fx();

        if ( !zombies_nuked[i].isdog )
        {
            if ( !( isdefined( zombies_nuked[i].no_gib ) && zombies_nuked[i].no_gib ) )
                zombies_nuked[i] maps\mp\zombies\_zm_spawner::zombie_head_gib();

            zombies_nuked[i] playsound( "evt_nuked" );
        }

        zombies_nuked[i] dodamage( zombies_nuked[i].health + 666, zombies_nuked[i].origin );
    }

    players = get_players( player_team );

    for ( i = 0; i < players.size; i++ )
        players[i] maps\mp\zombies\_zm_score::player_add_points( "nuke_powerup", 400 );
}

// ============================================================================
//  bocw_round  (was bocw_round.gsc)
// ============================================================================
round_hud()
{
    if ( zmqol_minimal() )
        return;

    level waittill( "start_of_round" );
    switch ( level.round_number )
    {
        case 1:
            roundcounter destroyelem();
            roundcounter = createservericon( "hud_chalk_1", 50, 50 );
            break;
        case 2:
            roundcounter destroyelem();
            roundcounter = createservericon( "hud_chalk_2", 50, 50 );
            break;
        case 3:
            roundcounter destroyelem();
            roundcounter = createservericon( "hud_chalk_3", 50, 50 );
            break;
        case 4:
            roundcounter destroyelem();
            roundcounter = createservericon( "hud_chalk_4", 50, 50 );
            break;
        case 5:
            roundcounter destroyelem();
            roundcounter = createservericon( "hud_chalk_5", 50, 50 );
            break;
        default:
            roundcounter destroyelem();
            roundcounter = createserverfontstring( "default", 25 );
            roundcounter setvalue( level.round_number );
            break;
    }
    roundcounter.vertalign = "top";
    zmqol_hud_round_anchor( roundcounter );   // v2.0.8 - HUD tab: ROUND COUNTER LEFT
    roundcounter.y = -10;
    roundcounter.alpha = 0;
    roundcounter.color = ( 1, 1, 0.25 );
    roundcounter fadeovertime( 0.5 );
    roundcounter.color = ( 0.75, 0, 0 );
    roundcounter.alpha = 1;
    roundcounter.hidewheninmenu = 1;

    //  v1.87.1 - stashed so the ".hud off" enforcement thread can reach it.
    //  This is a SERVER hudelem (createservericon/createserverfontstring), shared
    //  by everyone, so it is stashed on level rather than on a player - the
    //  per-player watcher in qol_options cannot own it.
    level.zmqol_roundcounter = roundcounter;

    //  ========================================================================
    //  v2.8.3 - WHY THIS LOOP WATCHES THE NUMBER INSTEAD OF THE NOTIFY.
    //
    //  It used to open with `level waittill( "end_of_round" )`. The body below
    //  it is an ANIMATION that takes about 4 seconds ( 0.3 + 0.4 + 2.5 + 0.3 ),
    //  and a waittill only catches a notify while it is actually waiting. With
    //  ROUND DELAY OFF the next round can begin and end inside those 4 seconds,
    //  so "end_of_round" fired with nothing listening, the loop then blocked on
    //  a "between_round_over" that had ALREADY passed, and the counter sat a
    //  full round behind for the rest of the match - exactly what the user saw
    //  on 2026-08-29: round 3 displayed as 2, then a jump straight to 4.
    //
    //  🌟 A missed notify is gone forever; a changed NUMBER is still true when
    //  we get round to looking. Polling level.round_number therefore cannot
    //  drop a round no matter how fast rounds turn over, and it needs no
    //  cooperation from round_think(). The 0.05s tick is only the resync
    //  latency, not a delay - the animation below is unchanged.
    //
    //  🛑 This is NOT setroundsplayed(). That call drives STOCK's round HUD and
    //  putting it back gave the user two counters on screen at once; see the
    //  note in round_think(). This mod's counter is the one drawn here.
    //  ========================================================================
    n_shown = level.round_number;

    while ( true )
    {
        while ( level.round_number == n_shown )
            wait 0.05;

        n_shown = level.round_number;
        roundcounter.color = ( 1, 1, 0.25 );
        roundcounter moveovertime( 0.3 );
        roundcounter scaleovertime( 0.3, 80, 80 );
        roundcounter.horzalign = "center";
        if ( level.round_number == 2 || level.round_number == 3 )
            roundcounter.x = 7 + level.round_number;
        else
            roundcounter.x = 0;
        wait 0.3;
        roundcounter fadeovertime( 0.3 );
        roundcounter.alpha = 0;
        wait 0.4;
        switch ( level.round_number )
        {
            case 1:
                roundcounter setshader( "hud_chalk_1", 80, 80 );
                break;
            case 2:
                roundcounter setshader( "hud_chalk_2", 80, 80 );
                break;
            case 3:
                roundcounter setshader( "hud_chalk_3", 80, 80 );
                break;
            case 4:
                roundcounter setshader( "hud_chalk_4", 80, 80 );
                break;
            case 5:
                roundcounter setshader( "hud_chalk_5", 80, 80 );
                break;
            default:
                roundcounter destroyelem();
                roundcounter = createserverfontstring( "default", 25 );
                roundcounter setvalue( level.round_number );
                roundcounter.color = ( 1, 1, 0.25 );
                break;
        }
        //  Re-stashed: the default branch above DESTROYS and re-creates the
        //  element, so the level handle would otherwise point at a dead one.
        level.zmqol_roundcounter = roundcounter;

        roundcounter fadeovertime( 0.8 );
        roundcounter.alpha = 1;
        roundcounter.color = ( 0.75, 0, 0 );
        wait 2.5;
        roundcounter scaleovertime( 0.3, 50, 50 );
        roundcounter moveovertime( 0.3 );
        zmqol_hud_round_anchor( roundcounter );   // v2.0.8 - twin of the resting anchor above
        roundcounter.hidewheninmenu = 1;

        //  v2.8.3 - the trailing `level waittill( "between_round_over" )` is
        //  gone with the notify it partnered. It is what actually wedged the
        //  loop for a round when the notify was missed, and the number-watch at
        //  the top now paces the loop on its own.
    }
}

// ============================================================================
//  zmqol_wait_out_intro_cutscene  -  THE SOLO INTRO CUTSCENE GATE, server half
// ----------------------------------------------------------------------------
//  User, 2026-08-30, on Origins solo: they skipped the intro part-way through
//  and *"when i spawned in the zombies were right near me already and had
//  already broke through the barrier"*.
//
//  🛑 ROUND DELAY OFF IS NOT THE CAUSE, and that is checked rather than
//  assumed. Both halves of that switch are guarded:
//      round_one_up()   `&& !level.first_round`   - round one always blocks for
//                       its full 6.25 + 2 seconds, threaded on no other round
//      zombie_between_round_time = 0   - read by round_over(), which round one
//                       never reaches until it is over
//  Neither can move a single frame of round one. The switch is innocent.
//
//  🌟 WHAT ACTUALLY OVERLAPS IS THIS MOD'S OWN CUTSCENE. ui_mp/t6/hud/loading.lua
//  plays video/<map>_load.webm only when party_maxplayers == 1, and stock never
//  reaches that on a Plutonium private match - zm_qol turns it on deliberately
//  by forcing the party size (privateonlinegamelobby.lua::zmQolForceSoloPartySize).
//  So there is no vanilla behaviour to restore here: the mod added a video and
//  never told the match to wait for it. Measured lengths, read out of each
//  file's Matroska Duration element x TimecodeScale:
//      zm_tomb_load     196.2s      zm_prison_load    170.6s
//      zm_buried_load   158.0s      zm_highrise_load   78.6s
//  Against that, round one's whole grace is 8.25 seconds.
//
//  🌟 THE SIGNAL IS EXACT, NOT A TIMER. loading.lua's own skip handler - the
//  only thing anywhere that calls Engine.Stop3DCinematic, and what both the
//  SKIP button and the mouse-click path run - now writes `zmqol_cutscene` 0,
//  and the movie branch writes 1. Solo is the only case that can reach that
//  branch, and solo on Plutonium is a listen server, so the LUI writing the
//  dvar and this function reading it are the same process. That channel is not
//  new or hopeful: zmQolForceSoloPartySize already hands `zmqol_loadmovie_probe`
//  to init() exactly this way and it arrives (see zmqol_loadmovie_probe()).
//
//  🛑 THREE THINGS STOP THIS EVER HANGING A MATCH, because a gate that sticks
//  would be far worse than the bug it fixes:
//    1. loading.lua clears the dvar to 0 at the TOP of every loading screen, so
//       a game quit mid-cutscene cannot leave it set for the next one.
//    2. the map test below - only the four maps that own a *_load.webm can gate
//       at all, so a stale 1 is inert on Diner, TranZit, Nuketown and Grief.
//    3. the deadline - 210s, comfortably past the longest video, after which it
//       gives up and plays on regardless.
// ============================================================================
zmqol_wait_out_intro_cutscene()
{
    //  The four maps loading.lua can play a video for. Anywhere else there is
    //  nothing to wait on and a leftover dvar must not be able to bite.
    if ( !isdefined( level.script ) )
        return;

    if ( level.script != "zm_tomb" && level.script != "zm_prison" &&
         level.script != "zm_buried" && level.script != "zm_highrise" )
        return;

    if ( getdvarintdefault( "zmqol_cutscene", 0 ) != 1 )
        return;

    println( "[zm_qol] intro cutscene on screen - holding round 1 until it is skipped or ends" );

    //  ------------------------------------------------------------------
    //  THREE WAYS OUT, because relying on one would be relying on a guess.
    //
    //    1. the dvar clears  - the exact signal, written by loading.lua's own
    //       Stop3DCinematic handler (the SKIP button and the click path).
    //    2. the player looks around - while the video is up the client is in a
    //       menu and no view input reaches the server, so the first change in
    //       view angles is proof they are actually in the world. This is the
    //       one that covers a video ENDING BY ITSELF: nothing in loading.lua
    //       says the engine runs the skip handler in that case, so the dvar
    //       might never clear, and waiting out the full deadline with the
    //       player already in the world and frozen would be its own bug.
    //    3. the deadline - 210s, past the longest video (zm_tomb_load, 196.2s).
    //
    //  Any one of the three is enough. The worst case is that only the last
    //  fires, which is still bounded and still leaves round 1 unstarted, i.e.
    //  the thing being fixed stays fixed.
    //  ------------------------------------------------------------------
    n_deadline = gettime() + 210000;
    v_start = undefined;
    a_players = get_players();

    if ( isdefined( a_players ) && a_players.size > 0 && isdefined( a_players[0] ) )
        v_start = a_players[0] getplayerangles();

    while ( getdvarintdefault( "zmqol_cutscene", 0 ) == 1 && gettime() < n_deadline )
    {
        if ( isdefined( v_start ) )
        {
            a_players = get_players();

            if ( isdefined( a_players ) && a_players.size > 0 && isdefined( a_players[0] ) )
            {
                v_now = a_players[0] getplayerangles();

                //  A degree of movement in any axis - far more than drift, far
                //  less than a deliberate turn.
                if ( abs( angleclamp180( v_now[0] - v_start[0] ) ) > 1 ||
                     abs( angleclamp180( v_now[1] - v_start[1] ) ) > 1 )
                {
                    println( "[zm_qol] player is looking around - treating the cutscene as over" );
                    break;
                }
            }
        }

        wait 0.25;
    }

    //  Owned from here on either way, so nothing downstream can re-trigger.
    setdvar( "zmqol_cutscene", "0" );

    println( "[zm_qol] intro cutscene over - starting round 1" );
}

round_think( restart )
{
    if ( !isdefined( restart ) )
        restart = 0;
    level endon( "end_round_think" );

    if ( !is_true( restart ) )
    {
        //  Before anything else in the first-round path: the player may still be
        //  watching the solo intro video. See zmqol_wait_out_intro_cutscene().
        zmqol_wait_out_intro_cutscene();

        if ( isdefined( level.initial_round_wait_func ) )
            [[ level.initial_round_wait_func ]]();
        players = get_players();
        foreach ( player in players )
        {
            if ( is_true( player.hostmigrationcontrolsfrozen ) )
                player freezecontrols( 0 );
            player maps\mp\zombies\_zm_stats::set_global_stat( "rounds", level.round_number );
        }
    }
    for (;;)
    {
        maxreward = 50 * level.round_number;
        if ( maxreward > 500 )
            maxreward = 500;
        level.zombie_vars["rebuild_barrier_cap_per_round"] = maxreward;
        level.pro_tips_start_time = gettime();
        level.zombie_last_run_time = gettime();
        if ( isdefined( level.zombie_round_change_custom ) )
            [[ level.zombie_round_change_custom ]]();
        else
        {
            level thread maps\mp\zombies\_zm_audio::change_zombie_music( "round_start" );

            //  ================================================================
            //  v2.8.2 - ROUND DELAY OFF (PATCHES tab), half one of two.
            //
            //  🌟 round_one_up() is stock's round-announce beat and everything
            //  it does after the announcer is a WAIT: 2.5s on an ordinary round,
            //  6.25 + 2 on the very first one, then reportmtu() ( _zm.gsc,
            //  round_one_up ). Nothing downstream reads a value it produces.
            //  Threading it therefore removes the pause from the round loop
            //  while keeping the announcer line, the music cue and the round
            //  HUD exactly as they are - nothing is skipped, it just stops
            //  blocking the spawner.
            //
            //  🛑 NEVER ON THE FIRST ROUND. That path is the map intro and it is
            //  the one that fires level notify( "intro_hud_done" ), which the
            //  intro HUD waits on. Threading it there would start the game
            //  underneath the intro sequence.
            //  ================================================================

            if ( getdvarintdefault( "round_delay_off", 0 ) && !level.first_round )
                level thread round_one_up();
            else
                round_one_up();
        }
        maps\mp\zombies\_zm_powerups::powerup_round_start();
        players = get_players();
        array_thread( players, ::rebuild_barrier_reward_reset );
        if ( !is_true( level.headshots_only ) && !restart )
            level thread award_grenades_for_survivors();
        level.round_start_time = gettime();
        while ( level.zombie_spawn_locations.size <= 0 )
            wait 0.1;
        level thread [[ level.round_spawn_func ]]();
        level notify( "start_of_round" );
        recordzombieroundstart();
        players = getplayers();
        for ( index = 0; index < players.size; index++ )
        {
            zonename = players[index] get_current_zone();
            if ( isdefined( zonename ) )
                players[index] recordzombiezone( "startingZone", zonename );
        }
        if ( isdefined( level.round_start_custom_func ) )
            [[ level.round_start_custom_func ]]();
        [[ level.round_wait_func ]]();
        level.first_round = 0;
        level notify( "end_of_round" );
        level thread maps\mp\zombies\_zm_audio::change_zombie_music( "round_end" );
        uploadstats();
        if ( isdefined( level.round_end_custom_logic ) )
            [[ level.round_end_custom_logic ]]();
        players = get_players();
        if ( is_true( level.no_end_game_check ) )
        {
            level thread last_stand_revive();
            level thread spectators_respawn();
        }
        else if ( players.size != 1 )
            level thread spectators_respawn();
        players = get_players();
        timer = level.zombie_vars["zombie_spawn_delay"];
        if ( timer > 0.08 )
            level.zombie_vars["zombie_spawn_delay"] = timer * 0.95;
        else if ( timer < 0.08 )
            level.zombie_vars["zombie_spawn_delay"] = 0.08;
        if ( level.gamedifficulty == 0 )
            level.zombie_move_speed = level.round_number * level.zombie_vars["zombie_move_speed_multiplier_easy"];
        else
            level.zombie_move_speed = level.round_number * level.zombie_vars["zombie_move_speed_multiplier"];
        level.round_number++;

        //  ====================================================================
        //  REMOVE ROUND CAP  (v1.99.93, PATCHES tab row `remove_round_cap`)
        //
        //  🌟 THE CAP IS ALREADY GONE HERE AND THAT IS WHY THE ROW DEFAULTS ON.
        //  Stock's round_think() clamps with `if ( 255 < level.round_number )
        //  level.round_number = 255;` ( _zm.gsc:3516 ). This copy - which the
        //  mod installs for the Cold War round HUD - never carried that clamp,
        //  so ON is exactly what the mod has always done and OFF is the switch
        //  that changes something: it puts stock's clamp back.
        //
        //  🛑 setroundsplayed() STAYS OUT, and here is the measured reason.
        //  Stock's round_think() calls it twice ( _zm.gsc:3428 and :3519 ) and
        //  this copy carries neither. v2.8.3 restored both, on the theory that
        //  it was what fed the round display - and the user immediately got TWO
        //  round counters on screen, which is the proof that it drives STOCK's
        //  own round HUD. This mod draws its own chalk counter in round_hud()
        //  above, so stock's must stay switched off. Reverted the same session.
        //  📝 The round-counter LAG that sent us here was never this call. It is
        //  round_hud()'s ~4s end-of-round animation missing "end_of_round"
        //  notifies once ROUND DELAY OFF makes rounds change faster than the
        //  animation runs - fixed with a resync at the bottom of that loop.
        //  ====================================================================
        if ( !getdvarintdefault( "remove_round_cap", 1 ) && level.round_number > 255 )
            level.round_number = 255;

        matchutctime = getutc();
        players = get_players();
        foreach ( player in players )
        {
            if ( level.curr_gametype_affects_rank && level.round_number > 3 + level.start_round )
                player maps\mp\zombies\_zm_stats::add_client_stat( "weighted_rounds_played", level.round_number );
            player maps\mp\zombies\_zm_stats::set_global_stat( "rounds", level.round_number );
            player maps\mp\zombies\_zm_stats::update_playing_utc_time( matchutctime );
        }
        check_quickrevive_for_hotjoin();

        //  ====================================================================
        //  v2.8.2 - ROUND DELAY OFF (PATCHES tab), half two of two.
        //
        //  🌟 Stock's round_over() reads level.zombie_vars["zombie_between_
        //  round_time"] into a LOCAL and only then waits on it ( _zm.gsc:3369
        //  and :3391 ). So zeroing the var immediately before the call and
        //  putting it back immediately after removes the ten-second gap and
        //  leaves the shared variable exactly as the map or gametype set it -
        //  the restore cannot race the wait, because the wait already holds its
        //  own copy of the number.
        //
        //  📝 Together with the round_one_up() half above this is the whole of
        //  the between-round pause. What remains is round_wait()'s 1.0s poll
        //  interval ( _zm.gsc, round_wait ), which is not a delay - it is how
        //  often the last-zombie check runs.
        //  ====================================================================
        n_zmqol_brt = level.zombie_vars[ "zombie_between_round_time" ];

        if ( getdvarintdefault( "round_delay_off", 0 ) )
            level.zombie_vars[ "zombie_between_round_time" ] = 0;

        level round_over();
        level.zombie_vars[ "zombie_between_round_time" ] = n_zmqol_brt;
        level notify( "between_round_over" );

        //  ====================================================================
        //  v2.11.12 - ROUND DELAY OFF, half three: GIVE THE SPECIAL-ROUND
        //  TRACKERS THEIR FRAME BACK.
        //
        //  🛑 THE BUG (user, 2026-09-04, Die Rise round 6): "i heard the sound
        //  for the jumping jacks round but instead zombies spawned".
        //
        //  Every special round in T6 installs itself on THIS notify and nowhere
        //  else. _zm_ai_leaper.gsc:547 (Die Rise) and _zm_ai_dogs.gsc:320 (the
        //  hellhound maps) are the same eight lines: `level waittill(
        //  "between_round_over" )`, then leaper_round_start() /
        //  dog_round_start() - which is what plays the music and the callout -
        //  and only THEN `level.round_spawn_func = ::leaper_round_spawning`.
        //  The END of a special round restores `old_spawn_func` on the same
        //  notify, so both edges depend on this ordering.
        //
        //  Stock round_think() never races that, because the only thing between
        //  this notify and `level thread [[ level.round_spawn_func ]]()` at the
        //  top of the loop is round_one_up()'s `wait 2.5` ( _zm.gsc:3358 ):
        //  powerup_round_start() is a single assignment ( _zm_powerups.gsc ),
        //  everything else up there is `level thread` / array_thread, and the
        //  zombie_spawn_locations loop does not spin once locations exist.
        //  Half one of ROUND DELAY OFF threads round_one_up(), which deletes
        //  that 2.5s - so the loop reached the spawn-func read in the SAME
        //  frame as the notify, read the ORDINARY spawner, and the tracker
        //  installed the leaper spawner a moment too late. The round sounded
        //  like a jumping jacks round and spawned normal zombies, exactly as
        //  reported.
        //
        //  One frame is the whole fix: nothing on the tracker's path to that
        //  assignment waits ( flag_set, level thread, level notify,
        //  clientnotify ), so the swap is done by the time we resume. 0.05s
        //  against stock's 2.5s - the round change stays instant.
        //  ====================================================================
        if ( getdvarintdefault( "round_delay_off", 0 ) )
            wait 0.05;

        restart = 0;
    }
}

// ============================================================================
//  animated_camo + buried_animated_camo  (COMBINED)
// ----------------------------------------------------------------------------
//  Both original files replaced the SAME stock function
//  (_zm_weapons::get_pack_a_punch_weapon_options) with a function of the same
//  name but different bodies. Two replaceFunc calls on one stock target can't
//  both take effect, so only one of the two was ever actually live - this
//  merge combines both authors' intent into a single override instead of
//  silently keeping one and dropping the other:
//    - animated_camo.gsc: camo 40 on zm_prison, zm_buried, or zm_tomb.
//    - buried_animated_camo.gsc: on zm_buried specifically, camo 40 EXCEPT
//      slowgun/rnma stay at 39.
//  Combined below: zm_buried uses the more specific slowgun/rnma exception;
//  zm_prison and zm_tomb keep flat camo 40; every other map is unaffected
//  (camo 39, same as both originals agreed).
// ============================================================================
get_pack_a_punch_weapon_options( weapon )
{
    if ( !isdefined( self.pack_a_punch_weapon_options ) )
        self.pack_a_punch_weapon_options = [];
    if ( !is_weapon_upgraded( weapon ) )
    {
        //  v2.11.3 probe - this is the silent "no camo at all" path (see below).
        zmqol_papcamo_probe( weapon, 0, 0, 0 );
        return self calcweaponoptions( 0, 0, 0, 0 );
    }
    // ------------------------------------------------------------------------
    //  🛑 v2.17.38 - THE CACHE MADE THE ANIMATED CAMOS ROW A DEAD SWITCH, AND
    //  THE EARLY RETURN THAT USED TO SIT HERE HAS MOVED DOWN THE FUNCTION.
    //
    //  User, 2026-09-24, on Origins: packed the L96A1 with ANIMATED CAMOS on
    //  and got the animated camo, turned the row OFF in Options, swapped the
    //  gun away, re-gave it with .give and packed it again - and it came back
    //  animated. Not an L96 problem; every gun behaved that way.
    //
    //  The cache is keyed on the WEAPON NAME ALONE and was never invalidated,
    //  so the first pack of a weapon decided its camo for the rest of the match
    //  and every later pack returned that stored answer without re-reading the
    //  dvar. Re-giving the gun does not help - the cache lives on the PLAYER.
    //  The note further down claiming the row "changes every gun PaP'd from
    //  then on" was simply untrue for any weapon already packed once.
    //
    //  THE FIX: decide camo_index FIRST, then return the cached options only if
    //  the cached camo still matches. Reticle and lens stay cached, so a gun
    //  keeps its look across packs; only a real settings change re-rolls it.
    //
    //  🛑 WHY IT IS SHAPED LIKE THIS AND NOT AS A DVAR FINGERPRINT. The first
    //  attempt read the seven anim_pap_camo* dvars up here to fingerprint them,
    //  and that KILLED EVERY MAP: "Unresolved external getdvarintdefault with 2
    //  parameters in scripts/zm/quality_of_life.gsc" -> 11 script errors ->
    //  SV_Shutdown -> the fatal LUI_ERROR process_events crash. getdvarintdefault
    //  is NOT an engine builtin, it is a script function, so every call site is
    //  an IMPORT REFERENCE - and this file is at its ceiling with 216 of them
    //  already. Seven more overflowed the table. Measured 2026-09-24, boot log
    //  console_zm.log:1316.
    //  So this version adds NO new cross-file call at all: it reuses the
    //  getdvarintdefault the function was already making below, and needs only
    //  isdefined, which IS a builtin. Keep it that way - see
    //  [[qol-symbol-table-not-size]].
    // ------------------------------------------------------------------------
    if ( !isdefined( self.zmqol_camo_index ) )
        self.zmqol_camo_index = [];

    smiley_face_reticle_index = 1;
    base = get_base_name( weapon );
    camo_index = 39;

    //  anim_pap_camo_buried / _mob / _origins, all defaulting to 1 so the
    //  behaviour is unchanged unless someone turns one off at the console.
    //
    //  🛑🛑 v2.11.8 - THE CAMO INDEX IS A LOOKUP TABLE, NOT ARITHMETIC. Read out
    //  of the engine and its data, not inferred: at startup t6zm.exe (the
    //  weapon-options loader, VA 0x689920) reads the stringtable
    //  mp/weaponoptions_zm.csv - owned by patch_zm.ff and by NOTHING else, so it
    //  is the same table on all six maps - and for every row whose column 1 is
    //  "camo" stores { column 4 = slot + 1, column 3 = 1 for a camoMaterials
    //  slot / 0 for a camoSets pattern } under the row's index. The rows:
    //
    //      39  mtl_weapon_camo_zombies   material  slot 3    (stock default)
    //      40  camo_zmb_dlc2             material  slot 8    (stock Mob: THE ANIMATED ONE)
    //      41  camo_doll_dempsey         PATTERN   set 31
    //      42  camo_doll_nikolai         PATTERN   set 32
    //      43  camo_doll_richtofen       PATTERN   set 33
    //      44  camo_doll_takeo           PATTERN   set 34
    //      45  camo_zmb_dlc4             material  slot 12   (stock Origins)
    //      46  camo_zmb_crystal          material  slot 13
    //
    //  No other index is a camo at all. So the "slot = index - 36" rule this
    //  file carried from v2.10.15 to v2.11.7 (and the "- 32" before it) was
    //  wrong, and index 44 - shipped as "the animated camo" - is the Takeo doll
    //  PATTERN camo, camoSets[34]: on the mod's 36-set tables that is a
    //  green-grey military pattern (Mob, 2026-09-03), on the eight 40-set
    //  tables it is whatever MP pattern sits at 34 (the XPR-50 on Origins,
    //  2026-09-04), and on the thirty-six 30-set tables it is past the end and
    //  draws nothing (M1911, Wave Gun). The dlc2 material - and so the Dark
    //  Matter textures that repaint it - had never once been selected by this
    //  mod. 40, the value both original scripts used, was right all along.
    //
    //  Validation is per table (t6zm.exe 0x61e150): a material row needs
    //  slot < numCamoMaterials and a populated slot. Every table mod.ff owns
    //  has 12-15 material slots with slot 8 populated (audited 2026-09-03), so
    //  40 is valid on all of them. Stock's own 4-slot (Green Run, Nuketown) and
    //  7-slot (Die Rise) tables fail it, which is what the camo_qol retarget
    //  below exists for.
    //
    //  OFF = stock's own value on every map (_zm_weapons.gsc:2286-2291): 39,
    //  40 on Mob, 45 on Origins. Mob's stock camo IS the dlc2 material, so on
    //  Mob the switch changes nothing - and with the Dark Matter pack
    //  installed, Mob's stock look is Dark Matter, because the pack replaces
    //  the pixels of the stock material. That is inherent to a texture pack.
    //
    //  v1.99.83, queue item 11 - ANIMATED CAMO PATCH on the GAME tab. The
    //  master dvar anim_pap_camo gates all three maps at once; the per-map
    //  dvars are untouched and still work from the console, so anyone who had
    //  set one keeps it.
    //
    //  🛑 v2.7.2 - "Master OFF = camo 39 everywhere = exact stock" WAS WRONG,
    //  and it is what let the Origins bug below ship unnoticed. Stock's own
    //  camo_index is NOT 39 everywhere - see _zm_weapons.gsc:2286-2291 in the
    //  gsc-dump: 39 default, 40 on zm_prison, 45 on zm_tomb. Origins now uses
    //  45 when the option is off, matching stock exactly.
    //
    //  🛑 THE ROW AFFECTS THE NEXT PACK-A-PUNCH, NOT GUNS ALREADY UPGRADED, and
    //  that is stock's own doing, not a shortcut here: the four lines above
    //  cache the result in self.pack_a_punch_weapon_options[weapon] and return
    //  the cached value forever after, so a weapon's camo is decided once, when
    //  it comes out of the machine. Clearing that cache mid-match would not
    //  restyle the gun in the player's hands either - the options are baked
    //  into the weapon the player is carrying and only a re-give would change
    //  them. Flipping this row therefore changes every gun PaP'd from then on.
    anim_camo_master = getdvarintdefault( "anim_pap_camo", 1 );
    anim_camo_on   = 0;

    //  📝 v2.10.11's SLOWGUN / RNMA EXCEPTION IS STILL GONE, and v2.11.0 finally
    //  makes that true rather than merely intended. User, 2026-09-02: "paralyzer
    //  is missing animated pap camo, make sure every gun in the game has animated
    //  pap camos if the option is set to enabled." v2.10.11 dropped the exception
    //  and shipped a fixed camo_slowgun in mod.ff - but §50 then measured that
    //  Buried's OWN camo_slowgun (12 slots, slot 8 empty) is the copy that draws,
    //  so mod.ff's fix never reached the renderer. Both guns are in the retarget
    //  list below, which is what actually fixes them: they now read
    //  camo_qol_slowgun / camo_qol_rnma, names Buried does not define.
    //  🌟🌟 v2.11.0 - THE ANIMATED CAMO NOW REACHES EVERY GUN ON EVERY MAP, and
    //  the three-map ceiling §50 measured is GONE. User, 2026-09-03: "make sure
    //  the animated pap camo you grabbed from the ezz mod is applied to every
    //  weapon once they're papped so long as the animated camo patch option is
    //  enabled."
    //
    //  §50's ceiling was real and its measurement still stands - a MAP's copy of
    //  a camo asset beats mod.ff's, so on Green Run, Die Rise and Nuketown index
    //  40 asked for slot 8 of a FOUR-slot table and drew nothing. What §50 got
    //  right in its closing line is the way out: "give a weapon a camo table no
    //  map defines." A weapon def names its camo asset in a plain `camo\<name>`
    //  field, so 48 guns now name camo_qol_<x> - a name that exists in NO retail
    //  fastfile, which makes mod.ff the only owner and its 13-slot table the one
    //  that draws, on every map, every time. See zone_source\mod_locations.zone
    //  for the two delivery routes and why each gun is on the one it is on.
    //
    //  So the per-map index split is gone: 40 everywhere the option is on.
    //  Measured before shipping - all 38 camo_qol tables carry slot 3 (index 39,
    //  the OFF path) and slot 8 (index 40, animated) live, and each slot 8 is a
    //  SUPERSET of that table's slot 3, so no gun can come out with LESS camo
    //  than it has today.
    if ( level.script == "zm_buried" )
        anim_camo_on = anim_camo_master && getdvarintdefault( "anim_pap_camo_buried", 1 );
    else if ( level.script == "zm_prison" )
    {
        anim_camo_on = anim_camo_master && getdvarintdefault( "anim_pap_camo_mob", 1 );

        //  Stock Mob is 40 (_zm_weapons.gsc:2289) - the same dlc2 material the
        //  animated option selects, so OFF changes nothing on this map.
        if ( !anim_camo_on )
            camo_index = 40;
    }
    else if ( level.script == "zm_transit" )
        anim_camo_on = anim_camo_master && getdvarintdefault( "anim_pap_camo_transit", 1 );
    else if ( level.script == "zm_highrise" )
        anim_camo_on = anim_camo_master && getdvarintdefault( "anim_pap_camo_highrise", 1 );
    else if ( level.script == "zm_nuked" )
        anim_camo_on = anim_camo_master && getdvarintdefault( "anim_pap_camo_nuked", 1 );
    else if ( level.script == "zm_tomb" )
    {
        anim_camo_on = anim_camo_master && getdvarintdefault( "anim_pap_camo_origins", 1 );

        //  v2.7.2 (user, 2026-08-28): OFF on Origins must be Origins' own blue
        //  camo, not the green one. Stock is 45 there (_zm_weapons.gsc:2291) =
        //  camo_zmb_dlc4, slot 12 = 3layer / zmb_dlc4_alt, live in every table
        //  mod.ff owns except camo_slowgun (Buried-only). v2.11.8 puts the stock
        //  value back; the 48 that replaced it in v2.10.15 is not a camo row at
        //  all and drew nothing.
        if ( !anim_camo_on )
            camo_index = 45;
    }
    else
        anim_camo_on = anim_camo_master;

    if ( anim_camo_on )
    {
        camo_index = 40;

        //  🛑 THE ONE THING THAT COULD NOT BE SETTLED OFFLINE, AND ITS FAIL-SAFE.
        //  35 of the 48 retargeted guns are weapons mod.ff ALREADY owns, and
        //  their new camo field only reaches the renderer if mod.ff's copy of the
        //  def is the live one rather than the map's. Every piece of evidence
        //  says it is - the M1911 was SILENT for weeks because mod.ff's donor def
        //  asked for wpn_m1911_* aliases no bank declares (CLAUDE.md, the sound
        //  section), which only happens if that def is the one the engine reads;
        //  and Plutonium refuses a raw weapons\zm\ file for any name mod.ff owns
        //  (checkpoint 149), which is the same authority from the other side.
        //  But "every piece of evidence says so" is not "measured", so this
        //  CHECKS rather than assumes, and falls back to exactly today's index if
        //  the check says otherwise. Nothing can come out worse than v2.10.18.
        //
        //  The discriminator is free - it already exists in the shipped files:
        //  mod.ff's m1911_upgraded_zm carries startAmmo 56 (it is zm_nuked's copy,
        //  put there by build_wpnfix.bat), every map's own copy carries 50.
        if ( !isdefined( level.zmqol_modff_weapon_defs ) )
        {
            n_probe = weaponstartammo( "m1911_upgraded_zm" );
            level.zmqol_modff_weapon_defs = ( n_probe == 56 );
            println( "[zm_qol] camo: m1911_upgraded_zm startAmmo=" + n_probe + " (56=mod.ff def is live, 50=the map's is) -> mod.ff weapon defs live = " + level.zmqol_modff_weapon_defs );
        }

        //  Only the three 4-slot maps can be hurt by getting this wrong; Buried,
        //  Mob and Origins render index 40 out of their OWN tables anyway.
        if ( !level.zmqol_modff_weapon_defs && zmqol_camo_rides_on_modff( base )
             && ( level.script == "zm_transit" || level.script == "zm_highrise" || level.script == "zm_nuked" ) )
            camo_index = 39;
    }
    //  v2.17.38 - THE CACHE READ, moved down here from the top of the function
    //  so it can see the camo this pack would actually use. Same weapon and the
    //  same camo means the stored options are still right, so the gun keeps its
    //  reticle and lens. A different camo means the player changed the ANIMATED
    //  CAMOS row (or a per-map anim_pap_camo_* dvar) since this weapon was last
    //  packed, so fall through and rebuild. isdefined is a builtin; nothing
    //  here adds an import reference to this symbol-full file.
    if ( isdefined( self.pack_a_punch_weapon_options[weapon] )
         && isdefined( self.zmqol_camo_index[weapon] )
         && self.zmqol_camo_index[weapon] == camo_index )
        return self.pack_a_punch_weapon_options[weapon];

    lens_index = randomintrange( 0, 6 );
    reticle_index = randomintrange( 0, 16 );
    reticle_color_index = randomintrange( 0, 6 );
    plain_reticle_index = 16;
    r = randomint( 10 );
    use_plain = r < 3;
    if ( base == "saritch_upgraded_zm" )
        reticle_index = smiley_face_reticle_index;
    else if ( use_plain )
        reticle_index = plain_reticle_index;
    scary_eyes_reticle_index = 8;
    purple_reticle_color_index = 3;
    if ( reticle_index == scary_eyes_reticle_index )
        reticle_color_index = purple_reticle_color_index;
    letter_a_reticle_index = 2;
    pink_reticle_color_index = 6;
    if ( reticle_index == letter_a_reticle_index )
        reticle_color_index = pink_reticle_color_index;
    letter_e_reticle_index = 7;
    green_reticle_color_index = 1;
    if ( reticle_index == letter_e_reticle_index )
        reticle_color_index = green_reticle_color_index;
    self.pack_a_punch_weapon_options[weapon] = self calcweaponoptions( camo_index, lens_index, reticle_index, reticle_color_index );
    //  v2.17.38 - remember WHICH camo this entry was built for, so the read
    //  above can tell a still-valid cache from one the player has invalidated
    //  by changing the ANIMATED CAMOS row.
    self.zmqol_camo_index[weapon] = camo_index;
    zmqol_papcamo_probe( weapon, 1, camo_index, self.pack_a_punch_weapon_options[weapon] );
    return self.pack_a_punch_weapon_options[weapon];
}

// ============================================================================
//  zmqol_papcamo_probe  -  v2.11.3. ONE LINE PER WEAPON, THEN QUIET.
// ----------------------------------------------------------------------------
//  User, 2026-09-03, with a screenshot of the Pack-a-Punched Zap Guns: both
//  halves are drawing their STOCK BO1 base textures and no Pack-a-Punch camo.
//  That much is measured, not guessed - the two colour maps were pulled out of
//  mod.iwd and converted (~-gt5_weapon_zom_moon_raygun_front_clr is the blue
//  half with the atom decal, _rear_c is the red half with the "07"), and they
//  are pixel-for-pixel what the screenshot shows.
//
//  THE ENTIRE ASSET CHAIN WAS THEN VERIFIED AND IS INNOCENT. Every link was
//  dumped out of the SHIPPED mod.ff and checked by hand, so none of it is the
//  suspect any more:
//    - t5_weapn_raygun_moon_front_vm / _rear_vm really do use materials
//      mc/mtl_raygun_moon_front and mc/mtl_raygun_moon_rear (XMODEL_EXPORT
//      dump: MATERIAL 0 of each). They are also the ONLY two materials in the
//      whole of mod.ff built on a _dlc5 techset, so nothing else can be meant.
//    - camo_microwavegun carries 13 camoMaterials and slots 3 / 8 / 12 (camo
//      index 39 / 44 / 48) are all live and each maps BOTH gun materials.
//    - the three camo materials those slots name - mtl_weapon_camo_zombies,
//      mtl_weapon_camo_zmb_dlc2, mtl_weapon_camo_3layer - are all in mod.ff, so
//      they resolve on Nuketown, which owns only the first of the three.
//    - camo_microwavegun exists in NO retail fastfile, so the "map's copy wins"
//      ceiling of ERROR_CATALOGUE 50 cannot apply to it.
//  So on Nuketown a camo index of EITHER 44 or 39 had a live slot to land on
//  and a material to swap to, and nothing was drawn. The break is not in the
//  assets, which is why this ships a probe instead of an asset change.
//
//  WHAT THE PROBE SEPARATES, in one line at the moment the options are built:
//    upgraded=0            is_weapon_upgraded() said no, so the camo index is
//                          FORCED to 0 and no camo was ever possible. That is a
//                          real and now-fixed defect for two of the three
//                          upgraded Wave Gun forms (zapgun.gsc, v2.11.3) - but
//                          the form the user was holding, microwavegundw_-
//                          upgraded_zm, IS registered and should print
//                          upgraded=1, so it does NOT explain the screenshot.
//    upgraded=1, index=44  the script did everything right and the engine did
//    (or 39), options!=0   not draw it, so the fault is below GSC: either
//                          Plutonium raw weapons\zm\ loader does not resolve a
//                          def camo field, or a dual-wield / alt form does not
//                          inherit its parent weapon options.
//
//  THE ONE-BOOT EXPERIMENT THAT DECIDES IT: in a single game, .pack an ORDINARY
//  box gun (an AK-74u, say - mod.ff owns its def) and then .pack the Zap Guns,
//  and compare. If the ordinary gun shows the camo and the Zap Guns do not,
//  while BOTH print upgraded=1 with the same camo index, then the difference is
//  the raw-def route itself - which would also mean the 13 guns v2.11.0 moved
//  onto weapons\zm\ lost their camo, and that is the next thing to fix. If
//  neither shows it, the camo option itself is off, or index 44 is not landing
//  where ERROR_CATALOGUE 50 concluded.
//
//  Capped at 24 lines a session and one per weapon name, so packing through a
//  whole game cannot flood the log. Delete this function and its two call sites
//  once the question is answered.
// ============================================================================
zmqol_papcamo_probe( weapon, b_upgraded, n_index, n_options )
{
    if ( !isdefined( level.zmqol_papcamo_probe ) )
    {
        level.zmqol_papcamo_probe = [];
        level.zmqol_papcamo_probe_count = 0;
    }

    if ( level.zmqol_papcamo_probe_count >= 24 )
        return;

    if ( isdefined( level.zmqol_papcamo_probe[ weapon ] ) )
        return;

    level.zmqol_papcamo_probe[ weapon ] = 1;
    level.zmqol_papcamo_probe_count++;

    println( "[zm_qol] papcamo: " + weapon + "  upgraded=" + b_upgraded + "  camo_index=" + n_index + "  options=" + n_options + "  map=" + level.script );
}

//  v2.11.0 - the 35 guns whose retargeted camo field rides in mod.ff rather than
//  in a raw weapons\zm\ file, and therefore depends on mod.ff's copy of the def
//  being the live one. Exactly the weapons `Unlinker --list mod.ff` reports that
//  a map also ships; the other 13 go out as raw defs in mod.iwd, which is proven
//  to beat the map's copy, so they are deliberately NOT in this list.
//
//  🛑 KEEP THIS IN STEP WITH zone_assets\weapons\. One entry per file there.
zmqol_camo_rides_on_modff( str_base )
{
    if ( !isdefined( level.zmqol_modff_camo_guns ) )
    {
        a = [];
        a["ak74u_upgraded_zm"]              = 1;  a["ak74u_extclip_upgraded_zm"]   = 1;
        a["an94_upgraded_zm"]               = 1;  a["barretm82_upgraded_zm"]       = 1;
        a["beretta93r_extclip_upgraded_zm"] = 1;  a["c96_upgraded_zm"]             = 1;
        a["dualoptic_saritch_upgraded_zm"]  = 1;  a["gl_m16_upgraded_zm"]          = 1;
        a["hamr_upgraded_zm"]               = 1;  a["hk416_upgraded_zm"]           = 1;
        a["judge_upgraded_zm"]              = 1;  a["kard_upgraded_zm"]            = 1;
        a["knife_ballistic_upgraded_zm"]    = 1;  a["lsat_upgraded_zm"]            = 1;
        a["m16_gl_upgraded_zm"]             = 1;  a["m1911_upgraded_zm"]           = 1;
        a["m1911lh_upgraded_zm"]            = 1;  a["m32_upgraded_zm"]             = 1;
        a["mg08_upgraded_zm"]               = 1;  a["mp5k_upgraded_zm"]            = 1;
        a["pdw57_upgraded_zm"]              = 1;  a["python_upgraded_zm"]          = 1;
        a["qcw05_upgraded_zm"]              = 1;  a["rnma_upgraded_zm"]            = 1;
        a["rottweil72_upgraded_zm"]         = 1;  a["rpd_upgraded_zm"]             = 1;
        a["saiga12_upgraded_zm"]            = 1;  a["saritch_upgraded_zm"]         = 1;
        a["sf_qcw05_upgraded_zm"]           = 1;  a["srm1216_upgraded_zm"]         = 1;
        a["svu_upgraded_zm"]                = 1;  a["tar21_upgraded_zm"]           = 1;
        a["type95_upgraded_zm"]             = 1;  a["usrpg_upgraded_zm"]           = 1;
        a["xm8_upgraded_zm"]                = 1;
        //  v2.11.4 - the four added by the Mob-of-the-Dead camo fix. Their defs are
        //  mod.ff's and now name camo_qol_<x>, so they ride on mod.ff exactly like
        //  the 35 above and need the same fail-safe.
        a["ak47_upgraded_zm"]               = 1;  a["uzi_upgraded_zm"]             = 1;
        a["thompson_upgraded_zm"]           = 1;  a["minigun_alcatraz_upgraded_zm"] = 1;
        level.zmqol_modff_camo_guns = a;
    }

    return isdefined( level.zmqol_modff_camo_guns[str_base] );
}

// ============================================================================
//  counterszm  (was counterszm.gsc)
// ============================================================================
counters_onplayerconnect()
{
    while ( true )
    {
        level waittill( "connected", player );
        player thread counters_onplayerspawned();
    }
}

counters_onplayerspawned()
{
    level endon( "end_game" );
    self endon( "disconnect" );
    first_spawn = 1;
    while ( true )
    {
        self waittill( "spawned_player" );
        if ( is_true( first_spawn ) )
        {
            first_spawn = 0;
            self thread zombiecounter();
        }
    }
}

// ============================================================================
//  zmqol_perf_probe  -  A DIAGNOSTIC SWITCH, NOT A FEATURE          (v1.65.4)
//
//  User, 2026-08-11: *"its still framey as hell, started happening with the mod
//  earlier i just wasnt sure"* - after v1.65.3 removed three sources of redundant
//  per-tick HUD traffic and it made no difference.
//
//  🛑 THIS SHIPS INSTEAD OF A THIRD GUESS. Two rounds of "likely cause" have not
//  moved it, and stacking a third unverified fix is exactly what
//  .agents\QUEUE.md's one-at-a-time rule exists to prevent. CLAUDE.md's
//  pre-mortem section prescribes the alternative directly: *"If something
//  genuinely cannot be settled offline, ship a probe that distinguishes the
//  outcomes rather than a fix built on the likeliest one."*
//
//  WHAT IT DOES. `qol_perf_probe 1` puts EVERY always-on per-player loop this mod
//  runs to sleep and stops its per-bullet HUD work:
//      first_spawn              health bar/text   10Hz  (elements destroyed)
//      zombiecounter            zombie count       4Hz
//      shield_hud               shield value      20Hz
//      zmqol_perk_slot_watcher  perk slots        20Hz
//      updatedamagefeedback     hitmarkers        PER DAMAGE EVENT
//  Nothing else in the mod changes - perks, power-ups, weapons, the Wunderfizz
//  and every gameplay hook keep running exactly as they do now.
//
//  🌟 WHY THIS IS WORTH A SESSION: IT HALVES THE SEARCH SPACE EITHER WAY.
//      still framey with it ON  -> the mod's per-frame SCRIPTS are not the cause,
//                                  and the whole HUD/reliable-command theory is
//                                  dead. Look at mod.ff instead: 3,870 assets and
//                                  776 header-only images that load ahead of every
//                                  map, or the 48MB sound bank.
//      smooth with it ON        -> it IS the scripts, and the five loops above
//                                  are the entire remaining suspect list.
//
//  It reads the dvar live, so it can be toggled mid-game from the console with no
//  map reload: `qol_perf_probe 1` / `qol_perf_probe 0`.
//
//  📝 Default 0. getdvarintdefault() handles the dvar being absent, so nothing
//  needs registering and a player who never types it is unaffected.
//  📝 REMOVE THIS once the cause is known - it is scaffolding, not a setting, and
//  it is deliberately not in the README or the options menu.
// ============================================================================
zmqol_perf_probe()
{
    return getdvarintdefault( "qol_perf_probe", 0 );
}

zombiecounter()
{
    if ( zmqol_minimal() )
        return;

    self endon( "disconnect" );
    level endon( "end_game" );
    flag_wait( "initial_blackscreen_passed" );
    //  🛑 v2.2.5 - "hudsmall" -> "small". "hudsmall" IS NOT A T6 FONT and the
    //  engine had been rejecting it on every one of the five createfontstring()
    //  calls in this mod, every match, since they were written. Found in the
    //  crash dumps rather than the console, because Plutonium does not surface
    //  it: BOTH of this install's dumps (2026-08-21 and 2026-08-22) carry it as
    //  the last recorded GSC error, word for word -
    //        "hudsmall" is not a valid value for hudelem field "font"
    //        Should be one of: default bigfixed smallfixed objective big small
    //                          extrabig extrasmall
    //  The assignment is the third line of stock's createfontstring()
    //  (_hud_util.gsc:310), so the element was built and then silently kept the
    //  default font - the row worked, it just never had the font it asked for.
    //  "small" is the name from the engine's own list. Changed with the user's
    //  explicit approval, 2026-08-22, because it alters how the text looks.
    self.zombietext = createfontstring( "small", 1.2 );
    self.zombietext.archived = 0;   // v2.17.41 - see qol_health_hud_create()

    //  y -7 -> -12, v1.77.0. The shield bar (v1.75.0) now occupies -0.5..4.5,
    //  which used to be the empty clearance under this counter, so the text was
    //  sitting on top of it. THE MOVE IS EXACTLY THE BAR'S OWN HEIGHT, NOT AN
    //  EYEBALLED NUDGE: qol_shield_hud_create()'s background is setshader(
    //  "white", 104, 5 ) at y 2 with aligny "middle", so it is 5 units tall and
    //  flush on the player bar (y 7, same 5 tall, 4.5..9.5). Shifting every
    //  element above the bars up by that same 5 preserves every pre-existing gap
    //  exactly, whatever the font's real pixel height turns out to be - which is
    //  why this needs no measurement of the text itself.
    //  🛑 The optional zone readout below the counter moves with it, in
    //  qol_options.gsc::qol_opt_zone_hud() (-19 -> -24). If only one of the two
    //  moves they collide.
    self.zombietext setpoint( "LEFT", "BOTTOM_LEFT", -45, -12 );
    self.zombietext.hidewheninmenu = 1;

    //  🛑 PERF, v1.65.3 - THE LABEL WAS SET INSIDE THE LOOP, FOUR TIMES A SECOND,
    //  BY AN if/else WHOSE TWO BRANCHES WERE IDENTICAL. Both assigned
    //  &"Zombies: ^1", so the condition decided nothing - but evaluating it cost
    //  a SECOND full get_round_enemy_array() walk every tick, on top of the one
    //  feeding setvalue(). The label never changes, so it is set once, here.
    self.zombietext.label = &"Zombies: ^1";

    while ( true )
    {
        //  DIAGNOSTIC, v1.65.4 - see zmqol_perf_probe(). Hides the element and
        //  skips the array walk entirely.
        if ( zmqol_perf_probe() )
        {
            self.zombietext.alpha = 0;
            wait 0.5;
            continue;
        }

        // ====================================================================
        //  🛑 THIS LOOP OWNS THIS ELEMENT'S ALPHA. NOTHING ELSE MAY WRITE IT.
        //
        //  v1.87.1 - the user reported the zombie counter "flashing on and off"
        //  after ".hud off". Two threads were fighting over it 4x a second:
        //  qol_options' watcher wrote alpha 0, and the `alpha = 1` that used to
        //  sit here wrote it straight back.
        //
        //  This is the SAME failure the health HUD already carries a warning
        //  about ("Two threads writing the same five elements is what produced
        //  the white bar, so there is exactly one owner now"), and the fix is
        //  the same: the loop that repaints the element every tick reads the
        //  dvars itself, and qol_opt_hud_watcher no longer touches it.
        //
        //  📝 It was never purely a .hud bug - setting `hud_remaining 0` would
        //  have flashed it in exactly the same way on any build since the
        //  watcher existed. .hud off simply made it easy to hit.
        // ====================================================================
        if ( !self scripts\zm\zmqol_playeropt::zmqol_popt_hud_on( "hud_remaining", 1 ) )
        {
            self.zombietext.alpha = 0;
            wait 0.25;
            continue;
        }

        self.zombietext.alpha = 1;

        //  One array walk per tick instead of two, and the value is only pushed
        //  when it actually moves - between kills it is the same number.
        n_zombies_left = get_round_enemy_array().size + level.zombie_total;

        if ( !isdefined( self.zombietext.qol_last_value ) || self.zombietext.qol_last_value != n_zombies_left )
        {
            self.zombietext setvalue( n_zombies_left );
            self.zombietext.qol_last_value = n_zombies_left;
        }

        wait 0.25;
    }
}

// ============================================================================
//  custom_summary  (was custom_summaryuncompiled.gsc, by Astroolean)
// ----------------------------------------------------------------------------
//  Dvars (console / config):
//    set cs_enabled 1          // 1 = enabled, 0 = disabled
//    set cs_x 0                // Horizontal offset from center
//    set cs_y -60              // Vertical offset from center
//    set cs_seconds 10         // How long the summary stays visible (seconds)
//    set cs_cooldown_ms 2500   // Minimum time between summaries (milliseconds)
// ============================================================================
// ============================================================================
//  DEBUG: ".dm" chat command (added 2026-07-26, generalised 2026-08-03)
// ----------------------------------------------------------------------------
//  debug_chat_listener() lived here. It was a second "say" listener that only
//  understood the literal ".dm" - no "!"/"/" prefix, no other power-up.
//
//  It is now folded into the single dispatcher: zmqol_dev_command_listener()
//  routes ".dm" through zmqol_powerup_alias() -> zmqol_spawn_powerup(), which
//  is the same code path every other power-up uses. The drop call and the
//  70-unit forward offset are carried over unchanged.
// ============================================================================

// ============================================================================
//  high_round_fix  (was high_round_fix.gsc)
// ----------------------------------------------------------------------------
//  Pre-existing quirk from the original author (not something we introduced):
//  stats() preloads a hardcoded zm_transit weaponLocker weapon
//  (an94_upgraded_zm+reflex, 1023 ammo) plus persistent-stat unlocks, on
//  EVERY map regardless of which one is loaded.
// ============================================================================
hrf_onplayerconnect()
{
    for (;;)
    {
        level waittill( "connected", player );
        player thread hrf_onplayerspawned();
    }
}

hrf_onplayerspawned()
{
    self endon( "disconnect" );
    self.zm_fix = 1;
    for (;;)
    {
        self waittill( "spawned_player" );
        if ( self.zm_fix == 1 )
        {
            self.zm_fix = 0;
            self thread stats();
        }
    }
}

zombie_health()
{
    for (;;)
    {
        level waittill( "start_of_round" );
        if ( level.zombie_health > maps\mp\zombies\_zm::ai_zombie_health( 155 ) )
            level.zombie_health = maps\mp\zombies\_zm::ai_zombie_health( 155 );
    }
}

stats()
{
    flag_wait( "initial_blackscreen_passed" );
    self.account_value = 250;
    self setdstat( "PlayerStatsByMap", "zm_transit", "weaponLocker", "name", "an94_upgraded_zm+reflex" );
    self setdstat( "PlayerStatsByMap", "zm_transit", "weaponLocker", "clip", 1023 );
    self setdstat( "PlayerStatsByMap", "zm_transit", "weaponLocker", "stock", 1023 );
    self setdstat( "PlayerStatsByMap", "zm_transit", "weaponLocker", "lh_clip", 1023 );
    self setdstat( "PlayerStatsByMap", "zm_transit", "weaponLocker", "alt_clip", 1023 );
    self setdstat( "PlayerStatsByMap", "zm_transit", "weaponLocker", "alt_stock", 1023 );
    self set_client_stat( "pers_boarding", 74 );
    self set_client_stat( "pers_revivenoperk", 17 );
    self set_client_stat( "pers_multikill_headshots", 5 );
    self set_client_stat( "pers_cash_back_bought", 50 );
    self set_client_stat( "pers_cash_back_prone", 15 );
    self set_client_stat( "pers_insta_kill", 2 );
    self set_client_stat( "pers_jugg", 3 );
    self set_client_stat( "pers_flopper_counter", 1 );
    self set_client_stat( "pers_pistol_points_counter", 1 );
    self set_client_stat( "pers_double_points_counter", 1 );
    self set_client_stat( "pers_perk_lose_counter", 3 );
    self set_client_stat( "pers_sniper_counter", 1 );
    self set_client_stat( "pers_box_weapon_counter", 5 );
    self set_client_stat( "pers_nube_counter", 1 );
}

create_dvar( dvar, set )
{
    if( getDvar( dvar ) == "" )
        setDvar( dvar, set );
}

// ============================================================================
//  No_Fog  (was No_Fog.gsc)
// ----------------------------------------------------------------------------
//  NOTE (2026-07-30): Disable_Fog_Transition was briefly merged in here,
//  then moved back OUT to the TranZit-scoped script
//  scripts/zm/zm_transit/disable_fog_transition.gsc - a root script can't
//  hold its zm_transit_fx reference (see the note at the top of this file).
//  What stays here is No_Fog's client-dvar part (r_fog 0, r_dof_enable 0).
// ============================================================================
nofog_onplayerconnect()
{
    for (;;)
    {
        level waittill( "connected", player );
        player thread nofog_onplayerspawned();

        //  🛑 v1.59.2 - FOG IS ON BY DEFAULT AGAIN. r_fog 0 is NOT forced here
        //  any more.
        //
        //  User, 2026-08-07: "make it so that fog by default is enabled because
        //  of the visual inconsistencies that are present when disabling the fog
        //  with r_fog set to 0, but keep the fog cloud textures off, that's the
        //  real issue."
        //
        //  Those are two different things and only one of them was ever the
        //  problem:
        //    - r_fog 0 kills the map's ATMOSPHERIC fog. Turning it off is what
        //      exposes the world edge and the flat, wrong-looking distance.
        //    - the fog CLOUD sprites are separate FX entities, suppressed on
        //      TranZit by scripts\zm\zm_transit\disable_fog_transition.gsc,
        //      which comments out the three fx_zmb_fog_transition_* loads so
        //      they are never registered and never spawn.
        //  That suppression is untouched and stays. Only the dvar changes.
        //
        //  Set to 1 EXPLICITLY rather than just not touching it. Every previous
        //  build forced r_fog 0 on this line, and a client that has been running
        //  those builds can be sitting on a persisted 0 - "stop setting it"
        //  would leave those players with no fog and no idea why. This makes the
        //  default deterministic instead of inherited.
        //
        // ====================================================================
        //  🌟 v1.99.91 - AND IT IS NO LONGER A HARDCODED 1. THIS LINE IS WHY THE
        //  FOG ROW NEVER SAVED.
        //
        //  User, 2026-08-20: *"make sure the-game menu options' selections save
        //  even after restarting the game, same as actual settings from the
        //  standard settings menu."*
        //
        //  Measured: of the 40 rows the mod's options tabs add, 39 are already
        //  written to %LOCALAPPDATA%\Plutonium\storage\t6\players\mods\zm_qol\
        //  plutonium_zm.cfg as `seta` lines and come back correctly - the ten
        //  that are not are the CHEATS rows, deliberately excluded by
        //  CoD.OptionsSettings.QolNoArchive. The ONE genuine failure was FOG,
        //  and it had two causes stacked:
        //    1. r_fog is cheat-protected and Plutonium never archives it, so the
        //       `seta` the menu runs for every other row does nothing for it.
        //    2. this line then forced it back to 1 on every single connect, so
        //       even a hand-edited config could not have survived.
        //  The row now drives `fog_enabled`, an ordinary mod dvar that archives
        //  like the other 39, and this line applies it. r_fog remains the thing
        //  the renderer reads, so typing `r_fog 0` at the console still works
        //  until the next spawn.
        // ====================================================================
        player setclientdvar( "r_fog", getdvarintdefault( "fog_enabled", 1 ) );
        player thread zmqol_fog_dvar_watch();

        //  v2.9.31 - explicit zeros on every connect, for the same reason the
        //  fog line above sets 1 explicitly: zmqol_raygun_hand_watch() below
        //  writes these while a Ray Gun is held, and a match that ends mid-hold
        //  would otherwise leave the whole viewmodel shifted for every gun in
        //  the player's next game. Deterministic, not inherited.
        player setclientdvar( "cg_gun_ofs_f", 0 );
        player setclientdvar( "cg_gun_ofs_r", 0 );
        player setclientdvar( "cg_gun_ofs_u", 0 );
        player thread zmqol_raygun_hand_watch();

        //  🛑 v1.99.54 - r_dof_enable IS NO LONGER FORCED TO 0 HERE, and this
        //  line has to go for the new ADVANCED-tab DEPTH OF FIELD row to mean
        //  anything. That row is the single owner of r_dof_enable now (see
        //  CoD.OptionsSettings.QolDofCallback in ui\t6\menus\optionssettings.lua);
        //  forcing 0 on every connect would silently undo LOW / MEDIUM / HIGH at
        //  the start of every match and the row would look broken.
        //
        //  Nothing changes for anyone who has not touched the row: the mod has
        //  archived r_dof_enable at 0 in the player's config since v1.99.45, and
        //  the new row's own dvar dof_quality defaults to its FIRST choice,
        //  which is DISABLED. Off stays off, it is just no longer compulsory.

        //  Bindable fly toggle - see zmqol_fly_key_bind(). Installed here
        //  because this is a per-player connect hook that always runs, and the
        //  bind must exist before the first flight, not after it.
        player zmqol_fly_key_bind();
    }
}

// ============================================================================
//  zmqol_fog_dvar_watch  -  v1.99.91, the FOG row's live half
//
//  The ADVANCED tab's FOG row writes `fog_enabled` (an ordinary mod dvar, so it
//  archives to the per-mod config like every other row); the renderer only ever
//  reads r_fog. This carries one to the other the moment it changes, so the row
//  still applies instantly the way it did when it wrote r_fog directly.
//
//  🛑 ONE WRITER, AND ONLY ON CHANGE. setclientdvar every quarter second would
//  fight anyone typing `r_fog 0` at the console and would spend a reliable
//  command each time ([[t6-reliable-command-ring]]); this writes only when
//  fog_enabled actually moves.
// ============================================================================
zmqol_fog_dvar_watch()
{
    if ( zmqol_minimal() )
        return;

    self endon( "disconnect" );
    level endon( "game_ended" );

    //  Seeded with the value already applied by the connect hook, so the first
    //  pass is a no-op.
    n_prev = getdvarintdefault( "fog_enabled", 1 );

    for ( ;; )
    {
        wait 0.25;

        n_now = getdvarintdefault( "fog_enabled", 1 );

        if ( n_now != n_prev )
        {
            n_prev = n_now;
            self setclientdvar( "r_fog", n_now );
        }
    }
}

nofog_onplayerspawned()
{
    self endon( "disconnect" );
    for (;;)
        self waittill( "spawned_player" );
}

// ============================================================================
//  zmqol_raygun_hand_watch  -  v2.9.31, the Ray Gun floating-left-hand PROBE
// ----------------------------------------------------------------------------
//  User, 2026-09-01: at high FOV the character's left hand floats in view while
//  the Ray Gun is held. Measured before writing this: the floating hand is the
//  player's view-arms model posed by viewmodel_raygun_t6_idle, NOT part of the
//  gun (t6_wpn_zmb_raygun_view's glb dump holds only gun bones - j_gun,
//  tag_battery_*, no arm geometry), and stock hideTags only ever hide gun parts
//  (sights/rails/mags - surveyed across every zm_nuked.ff weapon def). A true
//  fix means re-authoring the xanim, and no tool that can do that exists - the
//  same tooling wall as the Winter's Howl frozen pose.
//
//  What CAN move is the whole viewmodel: cg_gun_ofs_f/r/u exist in this game's
//  own dvar dump (all 0 stock). They are client dvars, driven here through
//  setclientdvar exactly like the FOG row drives cheat-protected r_fog. Whether
//  the renderer still honours them is the one thing not answerable offline -
//  which is why this ships as a TUNABLE, OFF BY DEFAULT:
//
//      zmqol_raygun_hand_ofs "0 0 0"     (forward right up; "0 0 0" = stock)
//
//  Set it at the console while holding a Ray Gun and the offsets apply live;
//  switch guns and they reset to 0. Once values that hide the hand are known
//  they become the shipped default. If no values change anything on screen,
//  the lever is dead and the honest answer is "engine limit" - either way the
//  boot settles it.
//
//  v2.9.34 - the front-end is now the `.rayhand` chat command (a preset
//  cycler; see its branch in the command dispatcher), because vector-typing
//  at the console went unused for two sessions on a pad. This watch is
//  unchanged - it is the single writer either way.
//
//  🛑 ONE WRITER, ONLY ON CHANGE - same reliable-command-ring rule as
//  zmqol_fog_dvar_watch above. Writes happen only on equip/unequip/retune.
// ============================================================================
zmqol_raygun_hand_watch()
{
    if ( zmqol_minimal() )
        return;

    self endon( "disconnect" );
    level endon( "game_ended" );

    //  "" means the stock zeros are in place (the connect hook just wrote them).
    str_applied = "";

    for ( ;; )
    {
        wait 0.25;

        str_want = "";
        str_weapon = self getcurrentweapon();

        if ( str_weapon == "ray_gun_zm" || str_weapon == "ray_gun_upgraded_zm" )
        {
            str_ofs = getdvar( "zmqol_raygun_hand_ofs" );

            //  Malformed or all-zero input counts as OFF, so a bad console set
            //  can never strand a stale offset on the client.
            if ( str_ofs != "" && str_ofs != "0 0 0" && strtok( str_ofs, " " ).size >= 3 )
                str_want = str_ofs;
        }

        if ( str_want == str_applied )
            continue;

        str_applied = str_want;

        if ( str_want == "" )
        {
            self setclientdvar( "cg_gun_ofs_f", 0 );
            self setclientdvar( "cg_gun_ofs_r", 0 );
            self setclientdvar( "cg_gun_ofs_u", 0 );
            continue;
        }

        a_ofs = strtok( str_want, " " );
        self setclientdvar( "cg_gun_ofs_f", string_to_float( a_ofs[0] ) );
        self setclientdvar( "cg_gun_ofs_r", string_to_float( a_ofs[1] ) );
        self setclientdvar( "cg_gun_ofs_u", string_to_float( a_ofs[2] ) );
    }
}

// ============================================================================
//  zmqol_dof_fix  -  DEPTH OF FIELD "DISABLED" was not actually disabled
// ----------------------------------------------------------------------------
//  Item 48. Found via the 2026-08-26 boot report (checkpoint 110 §4): the
//  ADVANCED tab's DEPTH OF FIELD row (dof_quality) only ever writes CLIENT
//  dvars (r_dof_enable / r_dofHDR - see QolDofCallback in optionssettings.lua).
//  Stock calls the engine method setdepthoffield() directly from SERVER-side
//  GSC in several places, completely independent of those client dvars, and
//  a scripted blur curve from the server overrides the renderer's own
//  r_dof_enable state.
//
//  🌟 EVERY REAL CALLER, MEASURED against the stock dump
//  (t6 modding starter kit\reference\gsc-dump\ZM\Core), not assumed:
//    _zm.gsc::onplayerconnect_clientdvars() / onplayerspawned(), and
//    _globallogic_spawn.gsc's per-player respawn path - all already call
//        setdepthoffield( 0, 0, ... ), the "no blur" tuple. Nothing to fix.
//    _globallogic_spawn.gsc::spawnintermission()            - REAL BLUR
//        ( 0, 128, ... ). Every round-end / match-end intermission spawn.
//    _globallogic_spawn.gsc::spawninterroundintermission()  - REAL BLUR, but
//        has NO CALLER anywhere in the whole ZM script dump (an MP-gametype
//        leftover) - confirmed by a directory-wide grep, not a single missed
//        file. Unreachable in zombies, so left alone.
//    _globallogic.gsc::roundenddof()                        - REAL BLUR.
//        Threaded once per player from endgame() at round/match end - the
//        "game-over sequence" from the checkpoint's own diagnosis.
//    _zm.gsc::set_third_person() and
//    _globallogic_spawn.gsc::setthirdperson()                - REAL BLUR in
//        their "on" branches, but BOTH are unreached on this platform: the
//        second opens with `if ( !level.console ) return;` (console-only,
//        dead on Plutonium PC), and the first's only caller anywhere in the
//        dump, spectator_toggle_3rd_person(), itself has NO caller anywhere
//        in the dump either - same whole-dump grep. 🛑 NOT FIXED, and not
//        guessed at: nothing found here justifies shipping a change for a
//        path nothing can reach. If blur is ever seen while toggling
//        third-person spectator view, this is the first place to look.
//
//  🛑 WHY NEITHER TRUE CALLER CAN BE replaceFunc'D - VERIFIED, NOT ASSUMED
//  (starter-kit replaceFunc failure mode 1 - unqualified same-file call):
//    - roundenddof() is invoked as `player thread roundenddof(4.0);` from
//      INSIDE _globallogic.gsc itself (endgame(), same file, unqualified) -
//      a replaceFunc on it would never see that call.
//    - endgame(), the function that calls it, is ~150 lines of real,
//      safety-critical branching (ranked-match promotion popups, next-round
//      vs match-end, exitlevel) reached from EIGHT call sites across three
//      files - and TWO of those eight (_globallogic.gsc:365 and :397) are
//      themselves unqualified same-file calls. Replicating all 150 lines by
//      hand would still only redirect 6 of 8 paths - a worse, silently
//      partial fix - and hand-copying match-ending logic is exactly the
//      kind of guess this project does not ship.
//
//  🌟 THE FIX THAT ACTUALLY COVERS EVERY PATH: `level notify( "game_ended" )`
//  fires unconditionally inside endgame() (_globallogic.gsc:1086), BEFORE
//  its roundenddof() calls, on every one of the eight paths that can reach
//  endgame() - so a level-notify watcher catches all of them uniformly,
//  where no replaceFunc could. This is a ONE-SHOT correction keyed to a real
//  engine event, not a per-frame fight against the renderer - the earlier
//  "not the watcher-mitigation fallback" instruction was about a continuous
//  poll overriding the engine every frame; this fires once, after the one
//  real event that can add the blur, with a short wait to land after it.
//
//  spawnintermission() IS reachable cleanly: every one of its 5 call sites
//  goes through the `level.spawnintermission` FUNCTION POINTER, never called
//  by name directly (failure mode 3 - re-point, don't replaceFunc), so
//  zmqol_dof_repoint_spawnintermission() waits for stock to set that pointer
//  (in map init) and then takes it over. The wrapper calls stock's real
//  function FIRST, by its qualified name (not through the pointer, so no
//  recursion), letting every branch of stock's own logic - including the
//  ranked-match promotion popup loop - run completely untouched, then
//  corrects only the trailing DOF call. Nothing about stock's control flow
//  is replicated or guessed at.
//
//  Both fixes are additive-only when the row is not DISABLED: dof_quality
//  != 0 skips the correction in both places and stock's blur plays exactly
//  as before, so LOW / MEDIUM / HIGH keep working unchanged.
// ============================================================================
zmqol_dof_off_tuple()
{
    self setdepthoffield( 0, 0, 512, 4000, 4, 0 );
}

zmqol_dof_repoint_spawnintermission()
{
    for ( i = 0; i < 1200; i++ )
    {
        if ( isdefined( level.spawnintermission ) )
        {
            level.spawnintermission = ::zmqol_spawnintermission_dof;
            return;
        }

        wait 0.05;
    }
}

zmqol_spawnintermission_dof( usedefaultcallback )
{
    self maps\mp\gametypes_zm\_globallogic_spawn::spawnintermission( usedefaultcallback );

    if ( !getdvarintdefault( "dof_quality", 0 ) )
        self zmqol_dof_off_tuple();
}

// ============================================================================
//  zmqol_dof_apply / zmqol_dof_quality_watch  -  DISABLED NOW ACTUALLY DISABLES
// ----------------------------------------------------------------------------
//  User, 2026-08-30, with a screenshot of the ADVANCED tab reading DEPTH OF
//  FIELD: DISABLED: *"i can still see depth of field when aiming/zooming in,
//  make sure that when it's set to disabled it actually disables all the depth
//  of field as intended."*
//
//  🌟 THE CAUSE, READ OUT OF THEIR OWN CONFIG RATHER THAN GUESSED.
//  storage	6\players\mods\zm_qol\plutonium_zm.cfg contains
//      seta dof_quality "0"
//      seta r_dofHDR    "2"
//  and NO r_dof_enable line at all. Plutonium does not archive that dvar. So on
//  every fresh launch:
//      dof_quality      comes back 0  -> the row correctly displays DISABLED
//      r_dof_enable     is the ENGINE DEFAULT, which is 1 -> blur is on
//  and the only thing that ever wrote r_dof_enable was QolDofCallback in
//  optionssettings.lua, which runs only when someone actually moves the
//  selector. Leave the row alone - as anyone who has already set it to DISABLED
//  would - and it is never written. The row was telling the truth about the
//  mod's own dvar and nothing had told the renderer.
//
//  🛑 v1.99.54 DELIBERATELY REMOVED THE CONNECT-TIME WRITE, and its reasoning
//  ("that row is the single owner of r_dof_enable now") had one hole: a menu row
//  can only own a value while the menu is open. Its own comment claimed "the mod
//  has archived r_dof_enable at 0 in the player's config since v1.99.45" - the
//  config above shows that is no longer true, which is why this is fixed by
//  measuring the file rather than by trusting the comment.
//
//  🌟 THE SHAPE IS FOG'S, WHICH ALREADY WORKS. v1.99.91 hit exactly this for
//  r_fog - cheat-protected, never archived - and solved it by making an ordinary
//  mod dvar the source of truth and carrying it to the renderer on connect plus
//  on change. dof_quality is already that dvar, so this is the same two-part
//  fix: apply it on connect, and watch it for changes. Nothing about the row,
//  its four choices, or their meanings changes.
//
//  📝 r_dof_tweak IS SET TO 0 AND THAT IS NOT DEFENSIVE PADDING. Plutonium's own
//  dvar_descriptions.json documents it as *"Use dvars to set the depth of field
//  effect; overrides r_dof_enable"* - it is the one documented way for
//  r_dof_enable 0 to be ignored, so a disable that does not clear it is not a
//  disable. Nothing in this mod turns it on; this makes sure nothing else can
//  leave it on either.
//
//  📝 dof_quality 0 = DISABLED, 1/2/3 = LOW/MEDIUM/HIGH, and r_dofHDR wants
//  0/1/2 for those three - the same mapping QolDofSettings uses in the Lua, kept
//  identical on purpose so the two front-ends can never disagree.
// ============================================================================
zmqol_dof_apply( n_quality )
{
    //  Never let the documented override stand between the row and the renderer.
    self setclientdvar( "r_dof_tweak", "0" );

    if ( n_quality <= 0 )
    {
        self setclientdvar( "r_dof_enable", "0" );
        return;
    }

    self setclientdvar( "r_dof_enable", "1" );
    self setclientdvar( "r_dofHDR", n_quality - 1 );
}

//  Edge-triggered, one writer, and only on change - the same contract as
//  zmqol_fog_dvar_watch(). Writing every quarter second would fight anyone
//  typing r_dof_enable at the console and would spend a reliable command each
//  time.
zmqol_dof_quality_watch()
{
    self endon( "disconnect" );
    level endon( "game_ended" );

    n_prev = getdvarintdefault( "dof_quality", 0 );

    for ( ;; )
    {
        wait 0.25;

        n_now = getdvarintdefault( "dof_quality", 0 );

        if ( n_now != n_prev )
        {
            n_prev = n_now;
            self zmqol_dof_apply( n_now );
        }
    }
}

zmqol_dof_onplayerconnect()
{
    for ( ;; )
    {
        level waittill( "connected", player );
        player thread zmqol_dof_roundend_watch();
        player thread zmqol_dof_connect_apply();
    }
}

//  Applied twice on purpose: once as soon as the player is connected, and again
//  on their first spawn. The connect-time write can land before the engine has
//  finished applying the archived config over the top, and the spawn is the
//  first moment the value is certainly the last word. Both are one-shot.
zmqol_dof_connect_apply()
{
    self endon( "disconnect" );

    self zmqol_dof_apply( getdvarintdefault( "dof_quality", 0 ) );

    self waittill( "spawned_player" );

    self zmqol_dof_apply( getdvarintdefault( "dof_quality", 0 ) );
    self thread zmqol_dof_quality_watch();
}

zmqol_dof_roundend_watch()
{
    self endon( "disconnect" );

    for ( ;; )
    {
        level waittill( "game_ended" );

        //  Lets roundenddof()'s own thread (spawned the same frame, no wait
        //  in its body) land first, then overwrites it. 0.1s is several
        //  server frames of margin, not a guess at exact timing.
        wait 0.1;

        if ( !getdvarintdefault( "dof_quality", 0 ) )
            self zmqol_dof_off_tuple();
    }
}

// ============================================================================
//  noperklimit  (was noperklimit.gsc)
// ============================================================================
// 🛑 THIS USED TO HARDCODE 9, IN A FUNCTION CALLED remove_perk_limit().
// Reported in game: spinning the Wunderfizz repeatedly could never yield the
// last perk - it stopped at nine with "You Can Only Hold 9 Perks". The perk
// that went missing (Stamin-Up, in the report) is simply whichever one was not
// rolled first; it was never Stamin-Up-specific, and marathon IS enabled on
// TranZit (see perks() below), so getPerks() was offering it correctly.
//
// The mod has grown past nine perks - wunderfizz::getPerks() can offer twelve
// once Electric Cherry, Vulture Aid, PhD and Deadshot are added to a map - so a
// literal 9 became a cap rather than the removal of one.
//
// Now derived from the same list the Wunderfizz actually offers, so adding a
// perk later cannot silently reintroduce the cap. Both files are ROOT scripts
// that load on every map, so this cross-file call is safe under AI_CONTEXT
// rule 2 (only MAP-SPECIFIC references break other maps).
remove_perk_limit()
{
    level waittill( "start_of_round" );
    wait 0.05;

    // 🛑 THE FLOOR IS 12, NOT 11, AND NOT 9. User, on Origins: "it says i can only
    // get 9 perks make sure that every map with the real actual wunderfizz machine
    // let's you get all the perks in bo2 zombies."
    //
    // Deriving the cap from getPerks().size was supposed to make the cap follow
    // the mod, and it does - on the maps where the mod PLACES a machine. Origins
    // has its own machines and no added one, so nothing here grew past nine and
    // the old floor became the cap again, which is the exact failure this function
    // was rewritten to stop.
    //
    // 📝 v1.55.4: the floor was 11 and 11 was WRONG. Black Ops II Zombies has
    // TWELVE perks, and the count is not a matter of opinion - it is exactly the
    // twelve specialties zmqol_perk_from_alias() maps, which is the same twelve
    // zmqol_map_perks() enumerates:
    //     armorvest (Jugger-Nog)      fastreload (Speed Cola)
    //     rof (Double Tap 2.0)        quickrevive (Quick Revive)
    //     longersprint (Stamin-Up)    additionalprimaryweapon (Mule Kick)
    //     flakjacket (PhD Flopper)    deadshot (Deadshot Daiquiri)
    //     scavenger (Tombstone)       finalstand (Who's Who)
    //     grenadepulldeath (Electric Cherry)   nomotionsensor (Vulture Aid)
    // The user hit this by getting all twelve out of the Diner machine and
    // counting them. On a map where the mod places its own machine the max()
    // below already raised the cap to 12 on its own, so Diner behaved; the stale
    // floor only bit on maps using their OWN machine - which is Origins, the very
    // map the comment above was written for.
    n_limit = 12;
    a_perks = scripts\zm\wunderfizz::getPerks();

    if ( isdefined( a_perks ) && a_perks.size > n_limit )
        n_limit = a_perks.size;

    //  v2.15.50 - PERK LIMIT is choosable from the pre-game lobby and defaults
    //  to 4, the vanilla limit (user, 2026-09-14). Older builds ran MAP MAX by
    //  default; that is now the opt-in first choice, value 0.
    //
    //  🛑 0 MEANS "AS MANY AS THIS MAP OFFERS". It is still supported exactly as
    //  before - the long comment above is the record of the two in-game bugs
    //  caused by a wrong number, and none of that logic changed.
    //
    //  📝 A chosen limit is NOT clamped up to 12. Picking 4 is the whole point of
    //  the option - it is how you play stock rules - so it is honoured as given.
    //  It IS clamped down to the derived maximum, because offering more slots
    //  than the map has perks would just be a number that can never be reached.
    n_choice = getdvarintdefault( "perk_limit", 4 );

    if ( n_choice > 0 )
    {
        if ( n_choice > n_limit )
            n_choice = n_limit;

        n_limit = n_choice;
    }

    level.perk_purchase_limit = n_limit;
}

perklimit_onplayerconnect()
{
    for (;;)
    {
        level waittill( "connected", player );
        player thread perklimit_welcome();
    }
}

perklimit_welcome()
{
    self endon( "disconnect" );
    level endon( "game_ended" );
    for (;;)
        self waittill( "spawned_player" );
}

// ============================================================================
//  perkbonuspoints  -  prone in front of a perk machine = bonus points
// ============================================================================
//  secretsongsurvival  (was secretsongsurvival.gsc)
// ============================================================================
sss_onplayerconnect()
{
    for (;;)
    {
        level waittill( "connected", player );
        player thread sss_onplayerspawned();
    }
}

sss_onplayerspawned()
{
    self endon( "disconnect" );
    level endon( "game_ended" );
    for (;;)
        self waittill( "spawned_player" );
}

// spawnteddybear() / setteddybears() reworked 2026-07-26 against the stock
// zm_transit.gsc reference (maps\mp\zm_transit.gsc :: sndsetupmusiceasteregg /
// sndmusicegg / sndplaymusicegg - the native Tranzit "3 teddy bears -> secret
// song" easter egg, which only ever runs in zclassic mode; this is a
// zstandard-only reimplementation with its own local per-start-zone origins):
//   - teddymodel now plays a "zmb_meteor_loop" beacon so players can hear a
//     bear before they see it (stock does this on its own helper entity).
//   - the 3-bear count is now a LEVEL-scoped counter (level.sss_teddybear_count),
//     not a per-player one - matching stock's level.meteor_counter so co-op
//     players collectively complete it, and so a single player triggering all
//     3 actually reaches 3 (the old i.teddybears was already correct for solo
//     play; the real reason the song never played is the missing loop below).
//   - the secret song now plays via a dedicated threaded function mirroring
//     stock's sndplaymusicegg(), instead of a bare playsound() call inline.
// v1.67.1: pitch and roll are OPTIONAL trailing parameters. The teddy bear model
// has no sitting pose - it is a single rigid stand-up mesh - so "sitting on a
// shelf" can only be done by laying it over, which needs roll. Town, Bus Depot
// and Farm all call this with four arguments, so both default to 0 and their
// bears are bit-for-bit unchanged.
//
// 📝 The model measures 26.1 tall (y -3.46..22.66 in its GLB), 10.6 across and
// 17.4 deep, read from the bounding box in zombie_teddybear_lod0.glb rather than
// estimated. Rolled onto its side the 5.32 half-width becomes the lowest point
// instead of the 3.46 base, so a laid-down bear sinks ~1.9 units - which is why
// the Diner z values below are lifted a few units rather than reused as-is.
// v1.67.4: `snap` is a fourth optional parameter. When set, the bear's HEIGHT is
// measured in game with a downward bullettrace instead of being supplied, and z
// becomes only a starting guess. Three rounds of "still floating" on the shelf
// bear is three rounds too many - the engine knows exactly where that board is
// and script can just ask it.
//
// 🛑 IT FAILS SAFE. Two ways the trace can mislead, both rejected rather than
// trusted: no hit at all (fraction 1, e.g. a decorative shelf with no
// collision), or a hit far below the seed - which would mean it punched through
// the shelf and found the floor, dropping the bear to ground level. Either way
// the supplied z is kept, so the worst case is exactly the behaviour before this
// change. Which branch ran is printed, so one boot says whether the surface is
// solid.
// ============================================================================
//  zm_qol: LIVE BEAR TUNING  -  `zmqol_bear_live 1`                (v1.67.8)
//
//  🛑 THIS EXISTS BECAUSE SEVEN ROUNDS OF INFERRING A POSITION FROM SCREENSHOTS
//  IS SEVEN TOO MANY. Every placement so far has been me reading an arrow in an
//  image, converting it to a bearing, and shipping a build - and the shelf bear
//  has now cost six of them. The dvars were meant to avoid that but still need a
//  match restart to take effect, because setteddybears() reads them once.
//
//  With `zmqol_bear_live 1` a tagged bear re-reads its six dvars four times a
//  second and moves immediately, so the console becomes a direct manipulator:
//
//      zmqol_bear_live 1
//      zmqol_bear2_diner_yaw 200      <- the bear turns as you type it
//      zmqol_bear2_diner_x -4838
//
//  Dial it until it looks right, read the numbers back, and they become the
//  defaults. No build, no restart, no more arrows.
//
//  Default OFF, so a normal game never runs the loop. Only the three Diner bears
//  pass a tune id at all - Town, Bus Depot and Farm cannot reach this code.
//  📝 REMOVE once the Diner placements are settled; this is scaffolding.
// ============================================================================
zmqol_bear_live_tune( str_prefix, e_trigger )
{
    level endon( "end_game" );

    for ( ;; )
    {
        wait 0.25;

        if ( getdvarintdefault( "zmqol_bear_live", 0 ) != 1 )
            continue;

        v_origin = ( getdvarintdefault( str_prefix + "_x", int( self.origin[0] ) ), getdvarintdefault( str_prefix + "_y", int( self.origin[1] ) ), getdvarintdefault( str_prefix + "_z", int( self.origin[2] ) ) );

        self.origin = v_origin;
        self.angles = ( getdvarintdefault( str_prefix + "_pitch", 0 ), getdvarintdefault( str_prefix + "_yaw", 0 ), getdvarintdefault( str_prefix + "_roll", 0 ) );

        if ( isdefined( e_trigger ) )
            e_trigger.origin = v_origin;
    }
}

spawnteddybear( x, y, z, angle, pitch, roll, snap, tune )
{
    if ( !isdefined( pitch ) )
        pitch = 0;

    if ( !isdefined( roll ) )
        roll = 0;

    if ( isdefined( snap ) && snap )
    {
        // How far the origin must sit above the surface, straight off
        // zombie_teddybear_lod0.glb's bounds - the origin is near the feet, not
        // centred, so the pose decides which half-extent is vertical.
        n_lift = 3.46;

        if ( pitch != 0 )
            n_lift = 8.69;
        else if ( roll != 0 )
            n_lift = 5.32;

        v_start = ( x, y, z + 40 );
        a_trace = bullettrace( v_start, ( x, y, z - 80 ), 0, undefined );

        if ( isdefined( a_trace ) && isdefined( a_trace["position"] ) && a_trace["fraction"] < 1 && a_trace["position"][2] > ( z - 30 ) )
        {
            z = a_trace["position"][2] + n_lift;
            println( "[zm_qol] bear snap: surface at " + a_trace["position"][2] + ", lift " + n_lift + " -> z " + z );
        }
        else
            println( "[zm_qol] bear snap: NO usable surface under (" + x + "," + y + ") - keeping z " + z );
    }

    teddytrigger = spawn( "trigger_radius", ( x, y, z ), 1, 50, 50 );
    teddymodel = spawn( "script_model", ( x, y, z ), 1, 50, 50 );
    teddymodel setmodel( "zombie_teddybear" );
    teddymodel rotateto( ( pitch, angle, roll ), 0.1 );
    teddymodel playloopsound( "zmb_meteor_loop" );

    if ( isdefined( tune ) )
        teddymodel thread zmqol_bear_live_tune( tune, teddytrigger );

    while ( true )
    {
        teddytrigger waittill( "trigger", i );
        if ( i usebuttonpressed() )
        {
            teddymodel stoploopsound( 1 );
            i playsound( "zmb_meteor_activate" );
            if ( !isdefined( level.sss_teddybear_count ) )
                level.sss_teddybear_count = 0;
            level.sss_teddybear_count++;
            if ( level.sss_teddybear_count == 3 )
                level thread play_secret_song( teddymodel );
            break;
        }
    }
}

// Mirrors stock sndplaymusicegg(): plays the secret song on the bear that
// completed the set, then holds the thread open until end_game so stopsounds
// has something to clean up (matches stock's cleanup pattern).
play_secret_song( ent )
{
    level endon( "end_game" );
    wait 1;
    ent playsound( "mus_zmb_secret_song" );
    level waittill( "end_game" );
    ent stopsounds();
}

setteddybears()
{
    level.sss_teddybear_count = 0;
    if ( getdvar( "g_gametype" ) == "zstandard" )
    {
        if ( getdvar( "mapname" ) == "zm_transit" )
        {
            if ( getdvar( "ui_zm_mapstartlocation" ) == "town" )
            {
                thread spawnteddybear( 430, -570, -61, 26 );
                thread spawnteddybear( 2312, 579, -55, -137 );
                thread spawnteddybear( 699, -1387, 128, -48 );
            }
            else if ( getdvar( "ui_zm_mapstartlocation" ) == "transit" )
            {
                thread spawnteddybear( -7645, 5377, -58, -177 );
                thread spawnteddybear( -6656, 4408, -63, -120 );
                thread spawnteddybear( -6380, 5625, -45, -132 );
            }
            else if ( getdvar( "ui_zm_mapstartlocation" ) == "farm" )
            {
                thread spawnteddybear( 8512, -5913, 52, -134 );
                thread spawnteddybear( 8449, -5350, 48, 127 );
                thread spawnteddybear( 8125, -6730, 117, 19 );
            }
            // ================================================================
            //  DINER  -  v1.67.0, the last survival location without the egg
            //
            //  User, 2026-08-11: *"add the 3 teddy bears around the map in Diner
            //  survival same as the ones that were added to bus depot, farm and
            //  town ... This way all the standalone survival maps will have the
            //  3 teddy bear interact easter egg song."*
            //
            //  🌟 NOTHING HAD TO BE BUILT OR SHIPPED, and that was verified per
            //  asset rather than assumed - the four things this easter egg needs
            //  are all already loaded on Diner survival:
            //      xmodel zombie_teddybear   -> zm_transit.ff          (loaded)
            //      zmb_meteor_loop           -> zmb_survival_transit.all
            //      zmb_meteor_activate       -> zmb_survival_transit.all
            //      mus_zmb_secret_song       -> zmb_patch.all, i.e. patch_zm.ff,
            //                                   which loads on EVERY map
            //  That last one was worth checking rather than trusting: the song
            //  is in NO transit bank, classic or survival. It resolves only
            //  because patch_zm carries it - as "carrion", TranZit's own secret
            //  song. Diner therefore gets the same track as Bus Depot, Farm and
            //  Town, which is the parity the request asks for.
            //
            //  So this is three coordinates on a system that already works, not
            //  a port. The proximity loop, the interact sound, the level-scoped
            //  3-of-3 counter and the song all come from spawnteddybear() and
            //  play_secret_song() above, untouched.
            //
            //  🛑 THE POSITIONS ARE DERIVED, NOT MEASURED, AND ARE TUNABLE.
            //  The user gave a `.where` and a screenshot arrow per bear, but
            //  `.where` reports where the PLAYER stood, not where the bear goes.
            //  Each default below is that reading pushed forward along the yaw
            //  they were facing, onto the surface the arrow pointed at:
            //
            //    1 workshop table   player (-3679,-7392,-58) yaw 264 -> ~60 fwd
            //    2 shelf by the riot-shield bench
            //                       player (-4830,-7918,-62) yaw 270 -> ~60 fwd
            //    3 roof corner      player (-5661,-7913,227) yaw 323 -> ~85 fwd
            //
            //  Each bear faces back toward where the player stood (yaw + 180).
            //  Heights are the surface the bear sits ON, so they are the numbers
            //  most likely to want a nudge - a shelf especially, where a
            //  downward trace would snap to the wrong tier.
            //
            //  Every value is a dvar with the derived default, exactly the
            //  pattern the Diner Pack-a-Punch uses (zmqol_pap_diner_*), which
            //  took three rounds of nudging to settle. Anything off can be fixed
            //  from the console in seconds instead of costing a rebuild:
            //      zmqol_bear1_diner_x / _y / _z / _yaw   (workshop table)
            //      zmqol_bear2_diner_*                    (shelf)
            //      zmqol_bear3_diner_*                    (roof corner)
            // ================================================================
            else if ( getdvar( "ui_zm_mapstartlocation" ) == "diner" )
            {
                // v1.67.1, after the user saw all three in game:
                //   1 workshop table - *"lie this one on it's side as well"*
                //   2 shelf          - *"just lie it down flat on the shelf on
                //                       it's side"* (the model T-poses; there is
                //                       no sitting pose to use)
                //   3 roof corner    - *"seems fine maybe just move it back a
                //                       tiny bit"*, so orientation is untouched
                //                       and only the origin moves
                //
                // Bears 1 and 2 take roll 90. Their z is lifted 4 units over the
                // standing value that already looked right in the screenshots,
                // to cover the ~1.9 the model sinks when the 5.32 half-width
                // becomes its lowest point instead of the 3.46 base.
                //
                // Bear 3 moves 14 units further along the exact bearing the user
                // was facing when they framed it (yaw 318 -> 0.743,-0.669),
                // which is "back" from where they stood. Confirmed that bearing
                // is right: their .where (-5672,-7893) to the bear's spawn
                // (-5593,-7964) is (79,-71), i.e. the same heading.
                // v1.67.2, second pass. Both corrections are height/orientation
                // only - neither bear moved horizontally.
                //
                // 🌟 THE ARITHMETIC, from zombie_teddybear_lod0.glb's real
                // bounds (x -5.32..5.32, y -3.46..22.66 up, z -8.69..8.71):
                // whatever axis ends up vertical decides how far the origin has
                // to sit above the surface, because the origin is NOT centred.
                //     upright      bottom is the 3.46 base   -> origin = S + 3.46
                //     on its side  the 5.32 half-width       -> origin = S + 5.32
                //     flat on back the 8.69 half-depth       -> origin = S + 8.69
                // Both standing heights were confirmed correct in game on
                // v1.67.0, so each surface S is known exactly and the laid-down
                // origins fall straight out of it - no estimating.
                //
                // BEAR 1, workshop table - *"on the wrong angle, lay it down
                // flat not on it's side like that floating. Make it asymetric
                // and not looking all funky."* Flat on its back is PITCH, not
                // roll: roll tips it sideways, which is what looked funky. So
                // pitch -90, roll back to 0. Table surface S = -24 - 3.46 =
                // -27.46, so flat-on-back origin = -27.46 + 8.69 = -18.8 -> -19.
                // Yaw goes 84 -> 110 so it lies at a casual angle to the table
                // edge rather than square to it - the "asymmetric" ask.
                //
                // BEAR 2, shelf - *"floating inside the box room, it needs to be
                // sitting properly on the shelf"*. Orientation was right, height
                // was not: v1.67.1 lifted it 4 when the roll only costs 1.86.
                // Shelf surface S = -18 - 3.46 = -21.46, so on-its-side origin =
                // -21.46 + 5.32 = -16.1. Set to -17 rather than -16: a bear
                // sunk one unit into a shelf board is invisible, one floating a
                // unit above it is not.
                // v1.67.3, third pass. 🛑 THE SURFACE HEIGHTS ARE RE-CALIBRATED
                // FROM WHAT THE USER SEES, because the earlier ones were derived
                // from an assumption that turned out to be wrong.
                //
                // v1.67.2 solved for each surface S by assuming the v1.67.0
                // STANDING bears rested on it exactly. They did not - the user
                // only ever said their positions were fine, never that they were
                // seated, and both are now reported floating. So S is lower than
                // assumed, and the two reports give the correction directly:
                //     bear 1  flat on back at -19, bottom -19-8.69 = -27.69,
                //             "slightly floating" -> table  S ~= -30
                //     bear 2  on its side at -17, bottom -17-5.32 = -22.32,
                //             "still floating"    -> shelf  S ~= -24
                // i.e. both standing heights were ~2.5 high all along.
                //
                // ⚠️ BEAR 2's Z GOES UP, -17 -> -16, AND THAT IS NOT A MISTAKE.
                // It changes pose. The origin is not centred, so how far it must
                // sit above the surface depends on which axis is vertical:
                // 3.46 upright, 5.32 on its side, 8.69 flat on its back. Going
                // from side to back needs +3.37 on top of the -2.5 correction.
                // Bottom lands at -16-8.69 = -24.69, a hair under S, on purpose -
                // sunk slightly reads as resting, floating never does.
                //
                // BEAR 1 - *"slightly floating, push it down just a smidge"*:
                // -19 -> -21, orientation untouched.
                //
                // BEAR 2 - *"still floating and colliding with another object,
                // fit it between the two props slightly on an angle lying flat
                // not on its side"*: pitch -90 / roll 0 like bear 1, and it
                // moves 12 units along the player's RIGHT to clear the jerry can
                // it was clipping and sit in the gap between the two. Facing yaw
                // 270, right is -X (right = (sin y, -cos y)), so x -4830 ->
                // -4842. Yaw 115 gives the "slightly on an angle" instead of
                // square to the shelf.
                thread spawnteddybear( getdvarintdefault( "zmqol_bear1_diner_x", -3685 ),
                                       getdvarintdefault( "zmqol_bear1_diner_y", -7452 ),
                                       getdvarintdefault( "zmqol_bear1_diner_z", -21 ),
                                       getdvarintdefault( "zmqol_bear1_diner_yaw", 110 ),
                                       getdvarintdefault( "zmqol_bear1_diner_pitch", -90 ),
                                       getdvarintdefault( "zmqol_bear1_diner_roll", 0 ), 0, "zmqol_bear1_diner" );

                // 🌟 v1.67.4's TRACE ANSWERED THE HEIGHT QUESTION FOR GOOD, and
                // the answer was "you cannot measure it". The log read:
                //     [zm_qol] bear snap: NO usable surface under (-4850,-7978)
                //                         - keeping z -27
                // so that shelf is a DECORATIVE prop with no collision - a
                // bullettrace passes straight through it. The fail-safe kept the
                // estimated -27, and the user confirmed that height: *"it seems
                // to be flat on the shelf"*. So z is settled at -27 by
                // measurement of the outcome, and snap is turned back OFF here -
                // it can only ever print that same line for this bear.
                //
                // 📝 Worth keeping: a shelf a player can see props resting on is
                // not necessarily solid to a trace. Auto-snapping placement only
                // works against world brushes and collision-bearing models, so
                // for prop shelving the height still has to be dialled in.
                //
                // v1.67.6 - *"still too far off to the right, move it a bit to
                // the left so it's not colliding with other objects."*
                //
                // 🛑 MOVING THE ORIGIN ALONE HAS NOT BEEN ENOUGH, and the reason
                // is the POSE, not the position. Flat on its back the bear's
                // 26-unit length lies HORIZONTALLY, pointing along its yaw. At
                // yaw 115 that is (cos115,sin115) = (-0.42,0.91) - almost
                // straight along +Y, which is INTO the shelf's ~20-unit depth.
                // So most of the body was sprawling across the shelf rather than
                // along it, and no amount of sliding x fixes an overhang in y.
                //
                // Yaw 115 -> 155 lays the length along the shelf instead:
                // (cos155,sin155) = (-0.91,0.42), mostly -X with a slight tilt,
                // which is still the "slightly on an angle" the user asked for
                // rather than square to the boards. x also moves 14 further left
                // (+X is left at yaw 270), -4840 -> -4826.
                //
                // v1.67.7, and this one is BRACKETED rather than guessed:
                // *"turned off to the left diagonally a lil too much,
                // horizontally is a bit too far off to the left, move it back to
                // the right so it fits perfectly inbetween the 2 petrol cans."*
                //   x  -4840 was too far RIGHT (into the lying can)
                //      -4826 is too far LEFT
                //   -> -4833, the midpoint of a bracket both ends of which the
                //      user has now seen, so this is interpolation, not another
                //      estimate.
                //   yaw 155 -> 170. 115 sprawled across the shelf, 155 is "a lil
                //      too much" diagonal; 170 is (cos170,sin170) =
                //      (-0.98,0.17), near-parallel to the boards with just
                //      enough tilt to stay off square.
                //
                // 🛑 v1.67.9 - THE 155/170/190 EXPERIMENT WAS THE WRONG AXIS AND
                // IS REVERTED. *"right now it's horizontally aligned but it needs
                // to be like vertical so it's not sideways, line it up so it fits
                // but keep it flat"*. A zombie-blood screenshot finally showed
                // the model clearly: its length was running LEFT-RIGHT, along the
                // shelf face, so it spanned the whole gap between the two cans
                // and touched both. The gap is narrow in X and deep in Y, so the
                // body has to run INTO the shelf, not across the front of it -
                // a 90 degree turn.
                //
                // yaw 190 -> 100: (cos100,sin100) = (-0.17,0.98), almost straight
                // +Y, into the shelf. 280 would align the same axis but point the
                // body -Y, out over the shelf edge, since the origin sits at the
                // feet end.
                //
                // 📝 This lands back beside yaw 115, which is where v1.67.3 had
                // it - and re-reading the reports, THAT ORIENTATION WAS NEVER THE
                // COMPLAINT. Image #19 was "still floating", height only. I read
                // a height complaint as an angle complaint and spent v1.67.6
                // through v1.67.8 rotating away from an orientation that was
                // already right. The lesson: when a report names one axis, do not
                // change a different one.
                //
                // 📝 Both are dvars, so this is dialable in game without waiting
                // on a build: set zmqol_bear2_diner_x / _yaw and restart the
                // match - setteddybears() reads them when the bears spawn.
                thread spawnteddybear( getdvarintdefault( "zmqol_bear2_diner_x", -4830 ),
                                       getdvarintdefault( "zmqol_bear2_diner_y", -7972 ),
                                       getdvarintdefault( "zmqol_bear2_diner_z", -27 ),
                                       getdvarintdefault( "zmqol_bear2_diner_yaw", 100 ),
                                       getdvarintdefault( "zmqol_bear2_diner_pitch", -90 ),
                                       getdvarintdefault( "zmqol_bear2_diner_roll", 0 ),
                                       getdvarintdefault( "zmqol_bear2_diner_snap", 0 ), "zmqol_bear2_diner" );

                thread spawnteddybear( getdvarintdefault( "zmqol_bear3_diner_x", -5583 ),
                                       getdvarintdefault( "zmqol_bear3_diner_y", -7973 ),
                                       getdvarintdefault( "zmqol_bear3_diner_z", 227 ),
                                       getdvarintdefault( "zmqol_bear3_diner_yaw", 143 ),
                                       getdvarintdefault( "zmqol_bear3_diner_pitch", 0 ),
                                       getdvarintdefault( "zmqol_bear3_diner_roll", 0 ), 0, "zmqol_bear3_diner" );

                // Printed so a bad placement is diagnosable from the log without
                // another screenshot round: compare these against the .where the
                // user reads standing next to each bear.
                println( "[zm_qol] diner bears: 1(" + getdvarintdefault( "zmqol_bear1_diner_x", -3685 ) + "," + getdvarintdefault( "zmqol_bear1_diner_y", -7452 ) + "," + getdvarintdefault( "zmqol_bear1_diner_z", -21 ) + " pitch " + getdvarintdefault( "zmqol_bear1_diner_pitch", -90 ) + ") 2(" + getdvarintdefault( "zmqol_bear2_diner_x", -4830 ) + "," + getdvarintdefault( "zmqol_bear2_diner_y", -7972 ) + "," + getdvarintdefault( "zmqol_bear2_diner_z", -27 ) + " pitch " + getdvarintdefault( "zmqol_bear2_diner_pitch", -90 ) + ") 3(" + getdvarintdefault( "zmqol_bear3_diner_x", -5583 ) + "," + getdvarintdefault( "zmqol_bear3_diner_y", -7973 ) + "," + getdvarintdefault( "zmqol_bear3_diner_z", 227 ) + ")" );
            }
        }
    }
}

// ============================================================================
//  zm_expanded  -  perk / clientfield / vending hub
// ============================================================================
player_too_many_weapons_monitor()
{
    if( level.script == "zm_prison" )
    {
        self notify( "stop_player_too_many_weapons_monitor" );
        self endon( "stop_player_too_many_weapons_monitor" );
        self endon( "disconnect" );
        level endon( "end_game" );
        scalar = self.characterindex;
        if ( !isdefined( scalar ) )
            scalar = self getentitynumber();
        wait( 0.15 * scalar );
        while ( true )
        {
            if ( self has_powerup_weapon() || self maps\mp\zombies\_zm_laststand::player_is_in_laststand() || self.sessionstate == "spectator" )
            {
                wait( get_player_too_many_weapons_monitor_wait_time() );
                continue;
            }
            weapon_limit = get_player_weapon_limit( self );
            primaryweapons = self getweaponslistprimaries();
            if ( primaryweapons.size > weapon_limit )
            {
                self maps\mp\zombies\_zm_weapons::take_fallback_weapon();
                primaryweapons = self getweaponslistprimaries();
            }
            primary_weapons_to_take = [];
            for ( i = 0; i < primaryweapons.size; i++ )
            {
                if ( maps\mp\zombies\_zm_weapons::is_weapon_included( primaryweapons[i] ) || maps\mp\zombies\_zm_weapons::is_weapon_upgraded( primaryweapons[i] ) )
                    primary_weapons_to_take[primary_weapons_to_take.size] = primaryweapons[i];
            }
            if ( primary_weapons_to_take.size > weapon_limit )
            {
                if ( !isdefined( level.player_too_many_weapons_monitor_callback ) || self [[ level.player_too_many_weapons_monitor_callback ]]( primary_weapons_to_take ) )
                {
                    self maps\mp\zombies\_zm_stats::increment_map_cheat_stat( "cheat_too_many_weapons" );
                    self maps\mp\zombies\_zm_stats::increment_client_stat( "cheat_too_many_weapons", 0 );
                    self maps\mp\zombies\_zm_stats::increment_client_stat( "cheat_total", 0 );
                    self takeweapon(primary_weapons_to_take[primary_weapons_to_take.size - 1]);
                    // self thread player_too_many_weapons_monitor_takeaway_sequence( primary_weapons_to_take );
                    // self waittill( "player_too_many_weapons_monitor_takeaway_sequence_done" );
                }
            }
            wait( get_player_too_many_weapons_monitor_wait_time() );
        }
    }
}

// ============================================================================
//  zmqol_dev_commands  -  in-chat developer commands
//
//  📝 The code moved to scripts\zm\zmqol_playeropt.gsc (co-op host gate and
//  the bytecode ceiling); this banner stays as its history.
//
//  Requested 2026-08-02 for dev testing, matching the setup the user's friend
//  runs:
//      !p <amount>   give yourself that many points (default 1000 if the amount
//                    is missing or not a number). Negative values are allowed so
//                    you can take points away too.
//      !god          toggle invulnerability on/off, with feedback either way.
//
//  sv_cheats is forced to 1 here so the commands behave consistently and the
//  usual Plutonium console cheats keep working alongside them.
//
//  Mechanism: T6 fires a level notify "say" carrying the speaker and the raw
//  message. Verified against a known-working release rather than guessed -
//  BO2-GSC-Releases\Zombies Mods\Give Points Command uses exactly
//  level waittill( "say", player, message ). Builtins used were checked against
//  the stock dump too: enableinvulnerability/disableinvulnerability appear in
//  _hostmigration.gsc and add_to_player_score is _zm_score.gsc:311. iprintlnbold
//  is used for feedback because tell() does not exist in T6.
//
//  This lives in quality_of_life.gsc (a ROOT script) so it is available on every
//  map, and every reference is to a core script, so AI_CONTEXT rule 2 is safe.
// ============================================================================
// ============================================================================
//  zmqol_credits_banner
//
//  Prints the mod's own banner once per player at the start of a game.
//
//  "^5" is BO2's LIGHT blue / cyan (^1 red, ^2 green, ^3 yellow, ^4 blue,
//  ^5 light blue, ^6 pink, ^7 white) - same convention the chat commands below
//  use. It was ^4 (dark blue) up to v1.18.2; the user asked for the lighter one.
//
//  Waits on "initial_blackscreen_passed" for the same reason every other HUD
//  thread in this file does: printing before it puts the line behind the loading
//  screen where nobody sees it. The extra second lets the round-start text clear
//  first. iprintln (bottom-left feed) rather than iprintlnbold, so it does not
//  sit across the middle of the screen while you are playing.
// ============================================================================

// ============================================================================
//  zmqol_team_emblem_watch  -  the scoreboard emblem follows your TEAM
//                                                                  (v1.99.61)
//
//  🛑 THE USER'S PREMISE WAS HALF RIGHT AND THE HALF THAT IS WRONG MATTERS.
//  User, 2026-08-18: *"i set my character as cia in the pre game menu for
//  nuketown, it worked and im the cia player model, but when i open the
//  scoreboard it says CDC which obviously makes no sense"*. It IS wrong on
//  screen - but the mod did not cause it, and stock does exactly the same thing
//  whenever its own random roll picks CIA. Proof, not opinion:
//
//      maps\mp\gametypes_zm\_scoreboard.gsc:17-21
//          if ( sessionmodeiszombiesgame() )
//          {
//              setdvar( "g_TeamIcon_Axis",   "faction_cia" );
//              setdvar( "g_TeamIcon_Allies", "faction_cdc" );
//          }
//
//  In zombies that pair is HARDCODED - the `game["icons"][...]` values the
//  teamset script sets up (_teamset_cdc.gsc:24,36) are read only on the MP
//  branch. Every zombies player is on `allies`, so the scoreboard emblem is
//  faction_cdc on every map, in every mode, no matter which model you wear.
//  zm_nuked.gsc:41-44 rolls `should_use_cia` at random, so a STOCK Nuketown
//  game shows a CIA player under a CDC emblem about half the time.
//
//  🌟 THE FIX IS ONE DVAR, AND IT IS THE ONE STOCK ALREADY TRUSTS. The material
//  is not in doubt either: stock itself writes "faction_cia" into
//  g_TeamIcon_Axis two lines above, in the same zombies branch, so the asset is
//  loaded and valid. All this does is point the ALLIES icon at whichever
//  faction the level actually dressed the players in.
//
//  level.should_use_cia is the single source of that answer on every CDC/CIA
//  map in the game - zm_buried:60, zm_nuked:41, zm_tomb:72, zm_transit:89,
//  zm_transit_dr:59 - and it is the same variable the lobby CHARACTER picker
//  writes (qol_options.gsc), so the emblem tracks the picker for free.
//
//  🛑 GRIEF AND CLEANSED ARE EXCLUDED, DELIBERATELY. Those modes have two real
//  player teams: allies IS CDC and axis IS CIA, and the stock pair is correct.
//  Repointing the allies icon there would put a CIA emblem on both teams.
//
//  It re-checks rather than firing once, because the picker can change teams
//  from the lobby row mid-session and because _scoreboard::init() must have run
//  first - it would otherwise overwrite this.
// ============================================================================
zmqol_team_emblem_watch()
{
    level endon( "end_game" );

    if ( isdefined( level.scr_zm_ui_gametype ) )
    {
        if ( level.scr_zm_ui_gametype == "zgrief" || level.scr_zm_ui_gametype == "zcleansed" )
            return;
    }

    //  🛑 v1.99.65 - THE LATCH COMPARED AGAINST ITSELF, NOT THE DVAR.
    //  str_last remembered what this loop last WROTE, so anything that wrote
    //  g_TeamIcon_Allies afterwards - _scoreboard::init() is the obvious one,
    //  and it runs late - stuck permanently, because str_want still equalled
    //  str_last and the loop never wrote again. Comparing against the live dvar
    //  makes it self-healing at no cost.
    //
    //  📝 The println is deliberate and stays. The user reported a CDC badge on
    //  a CIA player after changing character mid-game, and the two candidate
    //  causes - "this never wrote" versus "the scoreboard caches the icon when
    //  it is built" - cannot be told apart from a screenshot. One line in
    //  console_zm.log settles it on the next boot.
    for ( ;; )
    {
        if ( isdefined( level.should_use_cia ) )
        {
            str_want = "faction_cdc";

            if ( level.should_use_cia )
                str_want = "faction_cia";

            if ( getdvar( "g_TeamIcon_Allies" ) != str_want )
            {
                setdvar( "g_TeamIcon_Allies", str_want );
                println( "[zm_qol] scoreboard emblem -> " + str_want + " (should_use_cia=" + level.should_use_cia + ")" );
            }
        }

        wait 0.5;
    }
}
zmqol_credits_banner()
{
    level endon( "end_game" );

    for ( ;; )
    {
        level waittill( "connected", player );
        player thread zmqol_credits_banner_print();
    }
}

zmqol_credits_banner_print()
{
    if ( zmqol_minimal() )
        return;

    self endon( "disconnect" );
    level endon( "end_game" );

    flag_wait( "initial_blackscreen_passed" );
    wait 1;

    //  v1.95.0 - `intro_credits` console dvar. Menu row FLASH CREDITS, on the
    //  HUD tab since v1.99.61 (it was INTRO CREDITS on the GAME tab before
    //  that; the dvar name is deliberately unchanged - see the note in
    //  optionssettings.lua). User request, 2026-08-14: "add an option to
    //  disable auto flashing credits". On by default.
    //
    //  🌟 v2.14.14 - ONE DVAR NOW GATES BOTH FLASHES: flash_intro, the GAME
    //  tab's FLASH MESSAGES row. User, 2026-09-08: *"combine them into 1 option
    //  to save space for another option ... just flash credits, just flashing
    //  help, flashing both, or nothing popping up at all (Disabled)"*.
    //
    //      1 = both (the shipped default)   2 = credits only
    //      3 = help only                    0 = off
    //
    //  The value is seeded from the two old dvars by qol_options.gsc's
    //  qol_opt_flash_seed() (and by the menu's QolMigrateFlash), so a player
    //  who had switched one flash off keeps exactly that. This is the ONLY
    //  reader; intro_credits and flash_help are migration input now, nothing
    //  else.
    //
    //  🌟 THE SOURCE LINE. User, 2026-09-08: *"for the flash credits option,
    //  make sure to add underneath 'Source: (Link to the github repo for my
    //  mod)' same as how the B2OP patch gsc script does it."* B2OP's own line
    //  (T6-B2OP-PATCH/b2op.gsc, the welcome print) is
    //        self iprintln("Source: ^1github.com/B2ORG/T6-B2OP-PATCH");
    //  - a plain "Source:" label, the repo address with no scheme, coloured, on
    //  its own line under the banner. Same shape here, in this mod's palette.
    //  The address is the public repo (`git remote -v` -> DavidHiFi/T6-QoL) and
    //  the same one installer\README.txt prints, so it names nothing that is
    //  specific to the dev's machine (the v2.3.4 rule below).
    n_flash = getdvarintdefault( "flash_intro", 1 );

    if ( n_flash == 1 || n_flash == 2 )
    {
        self iprintln( "^5Quality Of Life Mod | Credits: DavidHiFi & Synarxis" );
        wait 0.25;
        self iprintln( "^5Source: ^3github.com/DavidHiFi/T6-QoL" );
    }

    // ========================================================================
    //  v1.99.61 - FLASH HELP, user request 2026-08-18: *"another bit of text
    //  that'll flash at the games start same as the flash credits one, but this
    //  option shows a small guide for players to access the list of commands,
    //  so basically briefly guide them on how to open the chat and do
    //  .help/!help"*.
    //
    //  🛑 v2.3.4 - "PRESS ;" NAMED THE MOD AUTHOR'S OWN KEYBIND, AND THAT IS A
    //  PUBLIC-MOD BUG, NOT A COSMETIC ONE.
    //
    //  User, 2026-08-25: *"it says ; but that's just my personal keybind for
    //  opening chat and is not the default key for opening chat, so if someone
    //  else is using my mod it's gonna be the wrong key ... make sure to
    //  globalize everything ... no text in this mod may ever display a keybind
    //  read from my machine."*
    //
    //  🌟 RE-VERIFIED, NOT JUST RE-TRUSTED. This line's own prior comment
    //  claimed semicolon was BO2's stock PC default (not a personal rebind),
    //  citing %LOCALAPPDATA%\Plutonium\storage\t6\players\bindings_zm.bdg. That
    //  claim was checked again this session, live: the SAME file, the mod's own
    //  per-profile copy in \players\mods\zm_qol\, and a separate untouched-
    //  looking backup under \backups\mod\settings\ all agree byte-for-byte -
    //  `bind SEMICOLON "chatmodepublic"`, `bind T "+smoke"`, `bind Y
    //  "chatmodeteam"`. Three independent copies matching, one of them a
    //  pre-session backup, is real evidence this IS the stock BO2 PC default
    //  and not something the user personally rebound.
    //
    //  🛑 BUT THAT DOES NOT MAKE THE OLD LINE SAFE TO SHIP. "Stock default"
    //  only means it is correct for a player who never rebound chat - any
    //  player who did is told the wrong key regardless, and GSC has no way to
    //  read a client's live binds to tell the two cases apart. The user's own
    //  instruction settles which risk to take: never name a specific key at
    //  all. The line below is now fully generic; the console route on the next
    //  line already was (help 1 cannot be rebound out from under it).
    //
    //  Separate dvar from intro_credits so either can be turned off alone. The
    //  short wait keeps the two banners from landing in the same frame and
    //  reads as two lines rather than one wrapped one.
    //  v2.14.14 - "separate dvar" is now the 3 and 1 values of flash_intro;
    //  see the note above. Either half can still be silenced alone.
    // ========================================================================
    if ( n_flash != 1 && n_flash != 3 )
        return;

    wait 0.25;
    self iprintln( "^5Open your chat key and type ^3.help ^5or ^3!help" );
    wait 0.25;
    self iprintln( "^5...for every command in this mod. From the console: ^3help 1" );
}



// ============================================================================
//  v2.11.0 - keeps ".nozmspawns off" off.
//
//  🛑 THE FLAG IS NOT OURS ALONE. maps\mp\gametypes_zm\_hostmigration.gsc clears
//  "spawn_zombies" for the duration of a host migration and SETS it again when
//  the migration finishes - it does not remember that something else had it
//  cleared. Without this thread a migration silently turns spawning back on and
//  the player sees zombies appear with no command typed, which is the shape of
//  the bug that was reported. Half a second is plenty: round_spawning() waits on
//  the flag once per zombie, so the worst case is a single extra spawn.
//
//  Costs nothing when unused - the thread only exists between an OFF and the
//  next ON, and ends on the notify rather than polling forever.
// ============================================================================
zmqol_nospawns_keeper()
{
    level endon( "zmqol_nospawns_off" );
    level endon( "end_game" );

    //  One keeper at a time, however many times the command is typed.
    level notify( "zmqol_nospawns_keeper" );
    level endon( "zmqol_nospawns_keeper" );

    while ( isdefined( level.zmqol_nospawns ) && level.zmqol_nospawns )
    {
        if ( flag( "spawn_zombies" ) )
            flag_clear( "spawn_zombies" );

        wait 0.5;
    }
}

// ============================================================================
//  .giveperks / .removeperks
//
//  🛑 level._custom_perks IS NOT THE PERK LIST. Both commands used to walk only
//  that array, and the user's report shows exactly what that costs:
//  ".removeperks ... said it removed 2 perks but i still have 7". T6 keeps perks
//  in two places and _custom_perks is the smaller one:
//
//    - the NINE core perks are flags:  level.zombiemode_using_<name>_perk.
//      _zm_perks::init() turns each on with its own turn_<name>_on() thread and
//      never puts them in _custom_perks (see _zm_perks.gsc:75-99, where the core
//      perks are nine explicit if-blocks and the _custom_perks loop is separate).
//    - only perks registered through register_perk_basic_info land in
//      _custom_perks: Electric Cherry, PhD Flopper, Vulture Aid.
//
//  So on a map with two customs it removed two and left the seven core ones -
//  precisely what was reported. zmqol_map_perks() below reads BOTH, and is the
//  same enumeration wunderfizz.gsc::getPerks() already uses to decide what the
//  machine may hand out, so the two agree on what "every perk on this map"
//  means.
//
//  give_perk( perk, bought ) is the stock entry point (_zm_perks.gsc:1982), and
//  is also the function this mod already replaceFuncs for the perk pop-up HUD,
//  so perks handed out here animate and count exactly like bought ones.
//
//  🛑 REMOVAL IS A NOTIFY, NOT A CALL. There is no stock "remove a perk"
//  function - unsetperk() sits inside perk_think(), which is a waiting loop:
//        perk_str = perk + "_stop";
//        result = self waittill_any_return( "fake_death", "death",
//                                           "player_downed", perk_str );
//  Notifying "<perk>_stop" is therefore the supported way out, and it runs the
//  whole stock teardown - unsetperk, num_perks--, and the per-perk switch that
//  puts Juggernog's max health back. Calling unsetperk() directly would skip all
//  of that and leave the player on 250 health with no Jugg.
// ============================================================================
//  Every perk this map actually has: the nine core flags plus whatever is in
//  level._custom_perks. Mirrors wunderfizz.gsc::getPerks(), minus its Buried
//  PhD exclusion - that exists because Buried's Wunderfizz must not OFFER a perk
//  the map cannot support, which is not a reason to refuse to strip it if the
//  player somehow has it.
zmqol_map_perks()
{
    a_perks = [];

    if ( isdefined( level.zombiemode_using_juggernaut_perk ) && level.zombiemode_using_juggernaut_perk )
        a_perks[a_perks.size] = "specialty_armorvest";

    if ( isdefined( level.zombiemode_using_doubletap_perk ) && level.zombiemode_using_doubletap_perk )
        a_perks[a_perks.size] = "specialty_rof";

    if ( isdefined( level.zombiemode_using_marathon_perk ) && level.zombiemode_using_marathon_perk )
        a_perks[a_perks.size] = "specialty_longersprint";

    if ( isdefined( level.zombiemode_using_sleightofhand_perk ) && level.zombiemode_using_sleightofhand_perk )
        a_perks[a_perks.size] = "specialty_fastreload";

    if ( isdefined( level.zombiemode_using_revive_perk ) && level.zombiemode_using_revive_perk )
        a_perks[a_perks.size] = "specialty_quickrevive";

    if ( isdefined( level.zombiemode_using_additionalprimaryweapon_perk ) && level.zombiemode_using_additionalprimaryweapon_perk )
        a_perks[a_perks.size] = "specialty_additionalprimaryweapon";

    if ( isdefined( level.zombiemode_using_deadshot_perk ) && level.zombiemode_using_deadshot_perk )
        a_perks[a_perks.size] = "specialty_deadshot";

    //  v1.85.0 - and not in solo; see zmqol_tombstone_allowed().
    if ( isdefined( level.zombiemode_using_tombstone_perk ) && level.zombiemode_using_tombstone_perk && zmqol_tombstone_allowed() )
        a_perks[a_perks.size] = "specialty_scavenger";

    if ( isdefined( level.zombiemode_using_chugabud_perk ) && level.zombiemode_using_chugabud_perk )
        a_perks[a_perks.size] = "specialty_finalstand";

    if ( isdefined( level._custom_perks ) )
    {
        a_keys = getarraykeys( level._custom_perks );

        for ( i = 0; i < a_keys.size; i++ )
        {
            if ( !isinarray( a_perks, a_keys[i] ) )
                a_perks[a_perks.size] = a_keys[i];
        }
    }

    return a_perks;
}

// ============================================================================
//  .give<perk> / .remove<perk>  -  one perk at a time
//
//  Parsed as a PREFIX rather than 24 explicit commands, so ".givejug" and
//  ".removejug" come out of the same two blocks in the chat handler. The alias
//  table below is deliberately generous - the whole point is not having to
//  remember whether it is "stam" or "staminup" mid-round.
//
//  🛑 THE SPECIALTY NAMES ARE THE TRAP, NOT THE ALIASES. Several read like the
//  wrong perk and models routinely guess them backwards, so they are taken from
//  getPerkName() below, which is already the shipped mapping:
//      specialty_armorvest              Jugger-Nog       (NOT flak/armor)
//      specialty_rof                    Double Tap 2.0
//      specialty_longersprint           Stamin-Up        (NOT marathon-the-perk)
//      specialty_additionalprimaryweapon Mule Kick
//      specialty_flakjacket             PhD Flopper      (NOT Jugger-Nog)
//      specialty_scavenger              Tombstone        (NOT a scavenger perk)
//      specialty_finalstand             Who's Who        (NOT last stand)
//      specialty_nomotionsensor         Vulture Aid
//      specialty_grenadepulldeath       Electric Cherry
//
//  Returns undefined for anything unrecognised, which is what lets the chat
//  handler use it as the test for "is this a perk command at all" - so a typo
//  falls through to the normal unknown-command path instead of doing something
//  surprising.
// ============================================================================
// ============================================================================
//  zmqol_ghost_enforce  -  .ghost / .afk stay on until YOU turn them off
//
//  🛑 THE BUG, root-caused rather than guessed. Reported: "ghost is still kinda
//  inconsistent, I find myself having to constantly disable and re-enable it
//  because the zombies will sometimes start targeting me again."
//
//  .ghost sets self.ignoreme = 1 exactly once. Stock sets it back to 0 in at
//  least five places, none of which know this mod exists:
//
//      _zm.gsc:1381  player_spawn_protection()  loops 60 frames setting
//                    ignoreme = 1, then UNCONDITIONALLY ends with ignoreme = 0.
//                    This is the big one - it runs on spawn, so every respawn
//                    silently cancels ghost about three seconds in.
//      _zm.gsc:2598  the respawn path, ignoreme = 0 alongside reviveplayer()
//      _zm_laststand.gsc:445, :984, :1053   revive / laststand exit
//
//  That is the whole symptom: not a flicker, a hard cancel that persists until
//  the command is toggled. Nothing was wrong with the flag itself.
//
//  🌟 WHY THIS RE-ASSERTS INSTEAD OF PATCHING THOSE FIVE SITES. Patching them
//  means either five replaceFuncs on core stock functions or reimplementing
//  player_spawn_protection - and it would only cover the reset paths I managed
//  to find. Re-asserting cannot miss one. It is also strictly safer: every
//  writer above sets ignoreme to a literal, so there is no state to corrupt by
//  writing 1 over it, and stock's own spawn protection is *also* setting it to 1
//  for those three seconds, so the two never disagree while it matters.
//
//  Zombie target selection reads ignoreme live every time it picks - stock
//  _zm.gsc:5105 and _zm_utility::is_player_valid( player, checkignoremeflag )
//  both test the current value - so restoring it within a frame restores the
//  behaviour with it. There is no cached "this zombie has chosen you" state
//  keyed off the old value.
//
//  Self-replacing: the first act is to notify its own endon, so re-issuing
//  .ghost or .afk swaps the thread rather than stacking a second copy. It exits
//  on its own the moment both flags are off, so an un-ghosted player runs
//  nothing.
// ============================================================================
zmqol_ghost_enforce()
{
    self endon( "disconnect" );
    self notify( "zmqol_ghost_enforce" );
    self endon( "zmqol_ghost_enforce" );

    while ( isdefined( self ) )
    {
        b_ghost = isdefined( self.zmqol_ghost ) && self.zmqol_ghost;
        b_afk   = isdefined( self.zmqol_afk )   && self.zmqol_afk;

        if ( !b_ghost && !b_afk )
            return;

        if ( !isdefined( self.ignoreme ) || !self.ignoreme )
            self.ignoreme = 1;

        wait 0.05;
    }
}

zmqol_perk_from_alias( str_alias )
{
    switch ( str_alias )
    {
        case "jug":
        case "jugg":
        case "juggernog":
        case "juggernaut":
            return "specialty_armorvest";
        case "speed":
        case "speedcola":
        case "sleight":
            return "specialty_fastreload";
        case "dtap":
        case "doubletap":
        case "double":
            return "specialty_rof";
        case "stam":
        case "stamin":
        case "staminup":
            return "specialty_longersprint";
        case "mule":
        case "mulekick":
            return "specialty_additionalprimaryweapon";
        case "revive":
        case "quickrevive":
            return "specialty_quickrevive";
        case "deadshot":
        case "ads":
            return "specialty_deadshot";
        case "phd":
        case "flopper":
        case "phdflopper":
            return "specialty_flakjacket";
        case "tombstone":
        case "tomb":
            return "specialty_scavenger";
        case "whoswho":
        case "who":
            return "specialty_finalstand";
        case "cherry":
        case "electriccherry":
            return "specialty_grenadepulldeath";
        case "vulture":
        case "vultureaid":
            return "specialty_nomotionsensor";
    }

    return undefined;
}

//  Give one perk. Refuses perks the MAP does not have, because give_perk() on an
//  unregistered perk sets the specialty without any of the machinery behind it -
//  no clientfield, no perk_think loop - which looks like it worked and is not
//  removable afterwards. zmqol_map_perks() is the same enumeration .giveperks
//  and the Wunderfizz both use, so the three agree on what this map supports.
zmqol_give_one_perk( perk )
{
    str_name = getPerkName( perk );

    if ( self hasperk( perk ) )
    {
        self iprintln( "^3[zm_qol] ^7you already have ^3" + str_name );
        return;
    }

    if ( !zmqol_perk_on_this_map( perk ) )
    {
        self iprintln( "^1[zm_qol] ^3" + str_name + " ^7is not available on this map" );
        return;
    }

    self maps\mp\zombies\_zm_perks::give_perk( perk, 0 );
    self iprintln( "^2[zm_qol] ^7gave ^2" + str_name );
}

//  Remove one perk. Same notify teardown .removeperks uses - see the block above
//  zmqol_map_perks() for why this is a notify and not a call to unsetperk().
zmqol_remove_one_perk( perk )
{
    str_name = getPerkName( perk );

    if ( !self hasperk( perk ) )
    {
        self iprintln( "^3[zm_qol] ^7you do not have ^3" + str_name );
        return;
    }

    self notify( perk + "_stop" );
    self iprintln( "^1[zm_qol] ^7removed ^1" + str_name );
}

//  Is this perk registered on the current map?
zmqol_perk_on_this_map( perk )
{
    a_perks = zmqol_map_perks();

    for ( i = 0; i < a_perks.size; i++ )
    {
        if ( a_perks[i] == perk )
            return 1;
    }

    return 0;
}

zmqol_give_all_perks()
{
    a_perks = zmqol_map_perks();
    n_given = 0;

    for ( i = 0; i < a_perks.size; i++ )
    {
        if ( self hasperk( a_perks[i] ) )
            continue;

        self maps\mp\zombies\_zm_perks::give_perk( a_perks[i], 0 );
        n_given++;

        //  0.1, not 0.05, on purpose: zmqol_perk_slot_watcher() samples every
        //  0.05s, so two perks handed out inside one tick would be appended in
        //  scan order rather than the order the HUD received them. Two server
        //  frames between grants guarantees the watcher sees each one alone.
        wait 0.1;
    }

    return n_given;
}

//  The perks the player is holding, in acquisition order, newest LAST. This is
//  a read-time ordered filter of self.zmqol_perk_slots (appended by give_perk),
//  which makes it an exact model of the perk-row LUI's own slot array - see the
//  banner over zmqol_remove_all_perks() for what that is for.
//
//  Paused perks are INCLUDED on purpose. perk_pause() calls unsetperk() and
//  writes clientfield value 2 (_zm_perks.gsc:2650), so hasperk() goes false
//  while the icon stays on screen: stock's hudperkszombie.lua carries both
//  STATE_PAUSED and PausedAlpha (read out of the shipped bytecode's string
//  table), i.e. a paused perk is DIMMED in its slot, not removed from the row.
//  Dropping them here would mis-identify the last slot during a blackout.
// ============================================================================
//  🛑 THE give_perk HOOK DOES NOT FIRE. MEASURED, 2026-08-08.
//
//  v1.62.1 tracked acquisition order from inside our give_perk() override. The
//  probe it shipped said, after a ".giveperks" that the log itself records:
//
//      [zm_qol] perk slots: tracked=0 held=12 total=12
//
//  Zero. And .giveperks reaches give_perk by a FULLY QUALIFIED external call
//  (maps\mp\zombies\_zm_perks::give_perk), the case replaceFunc is least
//  supposed to miss - so this is not the unqualified-same-file question at all.
//  replaceFunc( _zm_perks::give_perk, ::give_perk ) in main() simply is not
//  taking, and it never has: our override is byte-equivalent to stock's, so
//  nothing has ever depended on it and nothing ever looked broken.
//
//  📝 That also RETRACTS what v1.62.1's comments inferred from BO2-Reimagined
//  (that a synchronous same-file call is hookable). The inference was reasoned
//  from a shipped mod's design; this is a direct measurement of this mod, and
//  the measurement wins. The hook question is now irrelevant here either way -
//  nothing below reads give_perk.
//
//  🌟 SO ORDER IS OBSERVED, NOT REPORTED. zmqol_perk_slot_watcher() samples the
//  perks the player is holding and maintains the list itself:
//      - a perk that has appeared is APPENDED
//      - a perk that has gone is deleted, PRESERVING ORDER
//  which is exactly what CoD.Perks.Update and CoD.Perks.RemovePerkIcon do to
//  the LUI's slot array. Same two operations, same result, and it cannot miss
//  an acquisition path because it never looks at one.
// ============================================================================
zmqol_perk_slot_connect()
{
    level endon( "end_game" );

    for ( ;; )
    {
        level waittill( "connected", player );
        player thread zmqol_perk_slot_spawn();
    }
}

zmqol_perk_slot_spawn()
{
    self endon( "disconnect" );

    for ( ;; )
    {
        self waittill( "spawned_player" );
        self thread zmqol_perk_slot_watcher();
    }
}

//  A perk occupies a HUD slot while it is held OR paused. perk_pause() calls
//  unsetperk() and writes clientfield value 2 (_zm_perks.gsc:2650), so hasperk()
//  goes false while the icon stays on screen - stock's hudperkszombie.lua
//  carries both STATE_PAUSED and PausedAlpha (read out of the shipped bytecode's
//  string table), i.e. a paused perk is DIMMED in its slot, not removed from the
//  row. Testing hasperk() alone would drop a perk out of the list during a
//  blackout and then re-append it on power-up, in the wrong place.
zmqol_holds_perk( perk )
{
    if ( self hasperk( perk ) )
        return 1;

    if ( self maps\mp\zombies\_zm_perks::has_perk_paused( perk ) )
        return 1;

    return 0;
}

zmqol_perk_slot_watcher()
{
    self endon( "disconnect" );
    self notify( "zmqol_perk_slot_watcher" );
    self endon( "zmqol_perk_slot_watcher" );

    if ( !isdefined( self.zmqol_perk_slots ) )
        self.zmqol_perk_slots = [];

    a_all = zmqol_all_specialties();

    for ( ;; )
    {
        wait 0.05;

        //  DIAGNOSTIC, v1.65.4 - see zmqol_perf_probe(). 20Hz per player, and
        //  each pass walks every specialty in the game, so it is the mod's
        //  heaviest pure-CPU per-player loop even though it writes no HUD.
        if ( zmqol_perf_probe() )
        {
            wait 0.45;
            continue;
        }

        //  1. ORDERED delete of anything no longer in a slot. This is the same
        //     operation as the LUI's shift-down, which is the whole reason the
        //     two arrays stay in agreement.
        a_next = [];

        for ( i = 0; i < self.zmqol_perk_slots.size; i++ )
        {
            if ( self zmqol_holds_perk( self.zmqol_perk_slots[i] ) )
                a_next[a_next.size] = self.zmqol_perk_slots[i];
        }

        //  2. Append whatever is newly held. The LUI puts a new icon in its
        //     first free slot, and because its removals shift everything down,
        //     its free slots are always a contiguous tail - so "first free" is
        //     always the end, same as this append.
        //
        //  🛑 TWO PERKS CAN ARRIVE IN ONE FRAME, and then this scan order is NOT
        //  the HUD's order. Measured cause, 2026-08-08: Who's Who's revive
        //  (_zm_chugabud.gsc:295-335) and Mob's afterlife (_zm_afterlife.gsc:
        //  1327-1345) both re-hand the whole loadout back through give_perk() in
        //  one loop with NO waits, so the whole batch lands inside a single
        //  server frame and the sampler below cannot separate them. That is the
        //  "sometimes" in the user's report - .giveperks spaces its grants 0.1s
        //  apart and is exactly tracked, a Who's Who revive is not.
        //
        //  🌟 So the batch is ranked by stock's OWN acquisition list. give_perk()
        //  does `self.perks_active[self.perks_active.size] = perk` six lines
        //  after `self set_perk_clientfield( perk, 1 )` (_zm_perks.gsc:2045 and
        //  2060) - same function, no wait between them - and give_perk is the
        //  ONLY place in the stock dump that writes a perk clientfield to 1 for
        //  a perk the player did not already have (2688 is the unpause, which
        //  writes 1 for a perk the row already holds). So perks_active' append
        //  order IS the order the LUI received the icons.
        a_new = [];

        for ( i = 0; i < a_all.size; i++ )
        {
            if ( self zmqol_holds_perk( a_all[i] ) && !isinarray( a_next, a_all[i] ) )
                a_new[a_new.size] = a_all[i];
        }

        if ( a_new.size > 1 )
            a_new = self zmqol_order_by_acquisition( a_new );

        for ( i = 0; i < a_new.size; i++ )
            a_next[a_next.size] = a_new[i];

        self.zmqol_perk_slots = a_next;
    }
}

//  Put a_in into the order stock recorded the perks being acquired, newest LAST.
//
//  Reads self.perks_active, which give_perk() appends to in the same breath as
//  the clientfield write that makes the LUI place the icon - see the banner in
//  zmqol_perk_slot_watcher() for why that makes it the HUD's own order.
//
//  🛑 ONLY THE APPENDS ARE TRUSTED. perk_think()'s teardown removes from the
//  same array with `arrayremovevalue( self.perks_active, perk, 0 )`, and that
//  builtin's third parameter is NOT documented anywhere in the workspace - the
//  stock dump has no definition for it (it is engine-side) and the GSC reference
//  lists only the two-argument form. Whether it preserves the order of the
//  surviving entries is therefore UNKNOWN, so nothing here depends on it: this
//  is only ever called to rank perks that have just appeared, whose entries were
//  appended at the tail moments earlier with no removal in between. Anything
//  perks_active does not mention keeps the caller's order, at the end.
zmqol_order_by_acquisition( a_in )
{
    a_out = [];

    if ( isdefined( self.perks_active ) )
    {
        for ( i = 0; i < self.perks_active.size; i++ )
        {
            perk = self.perks_active[i];

            if ( !isdefined( perk ) || !isinarray( a_in, perk ) )
                continue;

            //  Last occurrence wins. A perk bought again after being lost goes
            //  to the END of the LUI's row too - Update() fills the first free
            //  slot, and free slots are always a contiguous tail.
            a_keep = [];

            for ( j = 0; j < a_out.size; j++ )
            {
                if ( a_out[j] != perk )
                    a_keep[a_keep.size] = a_out[j];
            }

            a_keep[a_keep.size] = perk;
            a_out = a_keep;
        }
    }

    for ( i = 0; i < a_in.size; i++ )
    {
        if ( !isinarray( a_out, a_in[i] ) )
            a_out[a_out.size] = a_in[i];
    }

    return a_out;
}

zmqol_perk_slot_order()
{
    a_order = [];

    if ( isdefined( self.zmqol_perk_slots ) )
    {
        for ( i = 0; i < self.zmqol_perk_slots.size; i++ )
        {
            if ( self zmqol_holds_perk( self.zmqol_perk_slots[i] ) )
                a_order[a_order.size] = self.zmqol_perk_slots[i];
        }
    }

    n_tracked = a_order.size;

    //  Backstop, kept from v1.62.1: anything held that the watcher has not seen
    //  yet (it samples on a 0.05s tick, and .removeperks could in principle be
    //  typed inside one). Order for these is unknown, which is why the log
    //  reports the count - tracked == held is the healthy reading.
    a_held = self zmqol_perks_still_held();
    a_miss = [];

    for ( i = 0; i < a_held.size; i++ )
    {
        if ( !isinarray( a_order, a_held[i] ) )
            a_miss[a_miss.size] = a_held[i];
    }

    //  Ranked the same way the watcher ranks a batch, so even the backstop path
    //  hands back the HUD's order rather than scan order.
    if ( a_miss.size > 1 )
        a_miss = self zmqol_order_by_acquisition( a_miss );

    for ( i = 0; i < a_miss.size; i++ )
        a_order[a_order.size] = a_miss[i];

    println( "[zm_qol] perk slots: tracked=" + n_tracked + " held=" + a_held.size + " total=" + a_order.size );

    return a_order;
}

// ============================================================================
//  🛑 THE NEWEST PERK COMES OFF FIRST, AND THAT ORDERING IS THE WHOLE FIX
//
//  Reported 2026-08-08 with a screenshot: ".giveperks then .removeperks" strips
//  every perk's EFFECT correctly but leaves the HUD showing twelve copies of
//  PhD Flopper. The chat command is the trigger; the defect is stock's, in
//  CoD.Perks.RemovePerkIcon (readable at
//  BO2-Reimagined\ui_mp\t6\zombie\hudperkszombie.lua:170-207, and stock's own
//  bytecode string table confirms the function set is unmodified there):
//
//      local PerkWidget, NextPerkWidget = nil, nil
//      for PerkIndex = OwnedPerkIndex, 12, 1 do
//          PerkWidget = Menu.perks[PerkIndex]
//          if not PerkWidget.perkId then break
//          elseif PerkIndex ~= 12 then
//              NextPerkWidget = Menu.perks[PerkIndex + 1]
//          end                    -- no else: on slot 12 this is still slot 12
//
//  Removing a perk shifts every icon down one slot. On the LAST slot there is
//  no next slot, so NextPerkWidget still points at slot 12 from the previous
//  pass - slot 12 copies ITSELF and never clears. Every removal then duplicates
//  the tail, and once all twelve perkIds are non-nil the row can never be
//  filled or emptied again, so it is stuck until the HUD is rebuilt.
//
//  🌟 THE CONDITION IS NARROW, WHICH IS WHY THIS IS FIXABLE FROM GSC. It fires
//  ONLY when the row is 12/12 full AND the removed perk is below slot 12. With
//  even one slot free the loop reaches the empty slot and clears correctly -
//  that is why stock never sees it, and why this mod does: no perk limit.
//  Two consequences:
//      - removing the perk in slot 12 is always safe (NextPerkWidget is a
//        function-local, freshly nil, so the first pass takes the clear path)
//      - once slot 12 is empty the row is no longer full, so every REMAINING
//        removal is safe in any order
//  So clearing the newest perk first is sufficient. Nothing else here changes.
//
// ============================================================================
//  🛑 v1.62.5 - THE ORDER OF THE NOTIFIES WAS NEVER THE ORDER THE HUD SAW
//
//  Reported back 2026-08-08 after v1.62.2 was confirmed working once: the row
//  still collapses to one icon SOMETIMES (the friend's run showed twelve Vulture
//  Aids). Two measured reasons the notify-ordering alone cannot be enough, both
//  fixed by clearing the clientfields here directly instead:
//
//  1. A NOTIFY IS NOT A WRITE. "<perk>_stop" only wakes perk_think, and what the
//     LUI reacts to is perk_think's set_perk_clientfield( perk, 0 ) further down
//     (_zm_perks.gsc:2204). perk_think returns EARLY - before that write - when
//     self._retain_perks or self._retain_perks_array[perk] is set (2166-2171),
//     which is exactly the Tombstone / Who's Who / afterlife state. A retained
//     perk therefore keeps its icon no matter what order it was notified in, and
//     the row never empties. That is the user's actual request: ".removeperks
//     should also make sure to remove any and all of the perk shaders."
//
//  2. TWELVE WRITES IN ONE FRAME HAVE NO ORDER. Clientfield changes ride one
//     snapshot per server frame, so a batch that lands in a single frame reaches
//     the LUI in the engine's field order, not the script's. Every write below
//     is therefore spaced 0.1s - the same spacing zmqol_give_all_perks() already
//     uses, which is the spacing that produced twelve distinct icons in the
//     user's confirmed v1.62.2 screenshot.
//
//  🌟 WHY THE SWEEP IS SAFE IN ANY ORDER. Stock's off-by-one needs the row to be
//  FULL: with a free slot the loop reaches it and takes the clearing branch. So
//  only the FIRST removal is order-critical, and phase 1 spends it on the last
//  slot. Everything after it runs against a row of at most eleven.
//
//  🛑 set_perk_clientfield IS ONLY CALLED FOR PERKS THIS MAP REGISTERED. Stock
//  registers the twelve fields conditionally (perks_register_clientfield,
//  _zm_perks.gsc:3091, gated on level.zombiemode_using_<perk>_perk, plus each
//  custom perk's own clientfield_register), and zmqol_map_perks() reads those
//  same flags and the same level._custom_perks keys - so the two lists are the
//  same list. Anything outside it is left alone rather than written blind.
//
//  ⚠️ STILL NOT COVERED, and not claimed to be: going down while holding all
//  twelve. Who's Who's revive and Mob's afterlife clear every perk clientfield
//  in ONE frame (_zm_chugabud.gsc:316-321, _zm_afterlife.gsc:1329-1334), so by
//  reason 2 above that batch has no script-visible order at all. The real repair
//  is one `else NextPerkWidget = nil` in the LUI - see QUEUE.md §A1.
// ============================================================================
zmqol_remove_all_perks()
{
    a_perks = zmqol_map_perks();
    n_taken = 0;

    a_order = self zmqol_perk_slot_order();

    //  PHASE 1 - empty the HUD row, LAST SLOT FIRST.
    for ( i = a_order.size - 1; i >= 0; i-- )
    {
        if ( !zmqol_perk_on_this_map( a_order[i] ) )
            continue;

        self maps\mp\zombies\_zm_perks::set_perk_clientfield( a_order[i], 0 );
        wait 0.1;
    }

    //  PHASE 2 - and any icon this map can show that the order above missed.
    n_swept = 0;

    for ( i = 0; i < a_perks.size; i++ )
    {
        if ( isinarray( a_order, a_perks[i] ) )
            continue;

        self maps\mp\zombies\_zm_perks::set_perk_clientfield( a_perks[i], 0 );
        n_swept++;
        wait 0.1;
    }

    println( "[zm_qol] removeperks: cleared " + a_order.size + " perk icon(s) newest-first, swept " + n_swept + " more" );

    //  PHASE 3 - the functional teardown. Unchanged, and its order no longer
    //  matters to the HUD: every icon is already gone, and perk_think's own
    //  write of 0 is a no-op on a field that is already 0.
    for ( i = 0; i < a_perks.size; i++ )
    {
        //  Notified even when hasperk() is false: a PAUSED perk is not "held"
        //  but its perk_think is still parked on the "<perk>_stop" wait, and
        //  leaving it parked would resurrect the perk when power came back.
        //  Only counted when it was really held, so the total the player is
        //  shown stays honest.
        if ( !self zmqol_holds_perk( a_perks[i] ) )
            continue;

        if ( self hasperk( a_perks[i] ) )
            n_taken++;

        self notify( a_perks[i] + "_stop" );
        wait 0.05;
    }

    // Anything the map-perk list did not cover - a perk from a source we do not
    // enumerate - would survive the loop above and leave the count wrong again.
    // hasperk() is the ground truth, so sweep whatever is left by the same
    // notify, and report the honest total.
    wait 0.1;

    a_left = zmqol_perks_still_held();

    for ( i = 0; i < a_left.size; i++ )
    {
        self notify( a_left[i] + "_stop" );
        n_taken++;
        wait 0.05;
    }

    return n_taken;
}

//  The full specialty set a T6 zombies player can be holding. Only used as a
//  backstop for .removeperks, so a perk added by some path zmqol_map_perks()
//  does not know about still comes off.
//  The full specialty set a T6 zombies player can be holding - one entry per
//  slot in the perk row's LUI, which registers exactly twelve
//  (CoD.Perks.ClientFieldNames[1..12]). Shared by zmqol_perks_still_held() and
//  by zmqol_perk_slot_watcher(), so the two can never disagree on what "every
//  perk" means.
zmqol_all_specialties()
{
    a_all = [];
    a_all[a_all.size] = "specialty_armorvest";
    a_all[a_all.size] = "specialty_rof";
    a_all[a_all.size] = "specialty_longersprint";
    a_all[a_all.size] = "specialty_fastreload";
    a_all[a_all.size] = "specialty_quickrevive";
    a_all[a_all.size] = "specialty_additionalprimaryweapon";
    a_all[a_all.size] = "specialty_deadshot";
    a_all[a_all.size] = "specialty_scavenger";
    a_all[a_all.size] = "specialty_finalstand";
    a_all[a_all.size] = "specialty_grenadepulldeath";
    a_all[a_all.size] = "specialty_flakjacket";
    a_all[a_all.size] = "specialty_nomotionsensor";

    return a_all;
}

zmqol_perks_still_held()
{
    a_all = [];
    a_all[a_all.size] = "specialty_armorvest";
    a_all[a_all.size] = "specialty_rof";
    a_all[a_all.size] = "specialty_longersprint";
    a_all[a_all.size] = "specialty_fastreload";
    a_all[a_all.size] = "specialty_quickrevive";
    a_all[a_all.size] = "specialty_additionalprimaryweapon";
    a_all[a_all.size] = "specialty_deadshot";
    a_all[a_all.size] = "specialty_scavenger";
    a_all[a_all.size] = "specialty_finalstand";
    a_all[a_all.size] = "specialty_grenadepulldeath";
    a_all[a_all.size] = "specialty_flakjacket";
    a_all[a_all.size] = "specialty_nomotionsensor";

    a_held = [];

    for ( i = 0; i < a_all.size; i++ )
    {
        if ( self hasperk( a_all[i] ) )
            a_held[a_held.size] = a_all[i];
    }

    return a_held;
}

// ============================================================================
//  .help
//
//  🛑 REWRITTEN FROM iprintln TO A HUD PANEL. The old version pushed 14 lines
//  into the bottom-left feed 0.1s apart. The user's report: "it scrolls through
//  all the commands ... so quickly and you can't even read them in time" - the
//  feed is only a few lines deep and expires each line on a timer, so the list
//  was always scrolling itself off before it finished printing. Staggering the
//  writes could never fix that; the feed is the wrong widget.
//
//  This draws a real panel instead: one hud element per line, set ONCE and left
//  alone (per CLAUDE.md section 6 - re-settext every frame floods reliable
//  commands with EXE_SERVERCOMMANDOVERFLOW).
//
//  PURELY TOGGLED - the 20-second auto-close v1.19.1 shipped with is gone, at
//  the user's request: "make the .help command be toggable so when it shows up
//  on screen i have to do .help or !help again to hide it". It now stays until
//  a second .help / !help, and nothing else takes it down.
//
//  🛑 THE LIST IS NOW THE REAL COMMAND SET. The user asked that it show only the
//  dot commands actually added. It had drifted: ".dm  spawn a Death Machine" was
//  listed but has no handler in zmqol_dev_command_listener() - the Death Machine
//  is a power-up, not a chat command - and ".infiniteammo" was the only entry
//  that did not show its short form. Verified against every `cmd == "..."` branch
//  in the listener: p, god, ghost, afk, fly, infiniteammo/infammo, reload,
//  nozmspawns, where, pack, unpack, giveperks, removeperks, help. Fourteen, and
//  fourteen are listed. If a command is added, add it here in the same pass.
// ============================================================================
// ============================================================================
//  .pack / .unpack
//
//  Pack-a-Punch the held weapon, or put it back to stock, with no machine, no
//  cost and no animation.
//
//  Modelled on the instant-Pack-a-Punch path already in this file (see the
//  Trigger loop around line 1760) - same stock calls, minus the trigger, the
//  score deduction and the fx:
//      switch_from_alt_weapon()  first, so packing while holding the alt form of
//                                a dual-mode weapon does not strand you on it
//      get_upgrade_weapon()      base -> upgraded
//      get_base_weapon_name( w, 0 )  upgraded -> base. The second argument is
//                                "return the input if it is NOT upgraded"; we
//                                pass 0 so an un-upgraded weapon comes back
//                                undefined and we can say so instead of
//                                re-giving the same gun.
//      get_pack_a_punch_weapon_options()  the camo/reticle blob, so a packed
//                                gun looks packed. This file overrides that
//                                function (see main()); it is the merged
//                                animated-camo version, which is what we want.
//
//  Ammo is carried across rather than reset, clamped to the new clip size the
//  same way the machine does it.
//
//  can_upgrade_weapon() is the stock gate (_zm_weapons.gsc:1786) and screens out
//  the riotshield, equipment, placeable mines and the revive tool, so those are
//  not re-tested here.
// ============================================================================
zmqol_pack( b_upgrade )
{
    str_weapon = self getcurrentweapon();

    if ( !isdefined( str_weapon ) || str_weapon == "none" || str_weapon == "zombie_fists_zm" )
    {
        self iprintln( "^1[zm_qol] ^7nothing in your hands to do that to" );
        return;
    }

    b_is_upgraded = is_weapon_upgraded( str_weapon );

    // 🛑 can_upgrade_weapon() IS THE WRONG GATE FOR .unpack, and gating both
    //    directions on it is what the user hit: ".unpack ... only seems to be
    //    working for some weapons" - fine on the DSR-50 and the PDW, refused on
    //    Mustang & Sally and Hades.
    //
    //    _zm_weapons.gsc:1786 - for a weapon that is ALREADY upgraded it returns
    //        level.zombiemode_reusing_pack_a_punch && weapon_supports_attachments( w )
    //    i.e. "can this be RE-packed for a different attachment". The DSR-50 and
    //    PDW take attachments so it said yes; Mustang & Sally and Hades are
    //    unique Pack-a-Punch weapons with no attachment options, so it said no
    //    and .unpack refused a weapon it could have reverted perfectly well.
    //
    //    Reverting only needs the upgraded -> base mapping, and every upgraded
    //    weapon has one by construction: add_zombie_weapon() writes
    //    level.zombie_weapons_upgraded[upgrade_name] = weapon_name (:546), which
    //    is the same table is_weapon_upgraded() reads. So .unpack asks only
    //    "is it upgraded", and can_upgrade_weapon() is left to guard .pack,
    //    where it is the correct question.
    if ( b_upgrade )
    {
        if ( b_is_upgraded )
        {
            self iprintln( "^1[zm_qol] ^7already Pack-a-Punched - use ^3.unpack" );
            return;
        }

        if ( !can_upgrade_weapon( str_weapon ) )
        {
            self iprintln( "^1[zm_qol] ^7that weapon cannot be Pack-a-Punched" );
            return;
        }
    }
    else if ( !b_is_upgraded )
    {
        self iprintln( "^1[zm_qol] ^7that weapon is not Pack-a-Punched" );
        return;
    }

    n_clip = self getweaponammoclip( str_weapon );
    n_stock = self getweaponammostock( str_weapon );

    str_weapon = self maps\mp\zombies\_zm_weapons::switch_from_alt_weapon( str_weapon );

    if ( b_upgrade )
        str_new = maps\mp\zombies\_zm_weapons::get_upgrade_weapon( str_weapon, will_upgrade_weapon_as_attachment( str_weapon ) );
    else
        str_new = maps\mp\zombies\_zm_weapons::get_base_weapon_name( str_weapon, 0 );

    if ( !isdefined( str_new ) || str_new == "" || str_new == str_weapon )
    {
        // No ternary in T6 GSC - spell it out.
        if ( b_upgrade )
            self iprintln( "^1[zm_qol] ^7no upgraded version of that weapon exists" );
        else
            self iprintln( "^1[zm_qol] ^7no stock version of that weapon exists" );

        return;
    }

    self takeweapon( str_weapon );

    if ( b_upgrade )
        self giveweapon( str_new, 0, self maps\mp\zombies\_zm_weapons::get_pack_a_punch_weapon_options( str_new ) );
    else
        self giveweapon( str_new );

    n_clip_size = weaponclipsize( str_new );

    if ( n_clip > n_clip_size )
        n_clip = n_clip_size;

    self setweaponammoclip( str_new, n_clip );
    self setweaponammostock( str_new, n_stock );
    self switchtoweapon( str_new );

    if ( b_upgrade )
    {
        self playsound( "zmb_perks_packa_ready" );
        self iprintln( "^2[zm_qol] ^7Pack-a-Punched" );
    }
    else
    {
        self iprintln( "^2[zm_qol] ^7back to stock" );
    }
}

zmqol_help_lines()
{
    //  🛑 LINE COUNT IS A HARD BUDGET, NOT A STYLE CHOICE. The user's screenshot
    //  shows this panel stopping dead after ".removeperks" - the 12th line - with
    //  everything below it, power-ups included, simply absent. Nothing errored:
    //  a client has a fixed HUD-element allowance and this mod already spends
    //  ~13 of it on permanent elements (health bar, name, timer, zombie counter,
    //  shield, the perk pop-up's three, the notifier). One createfontstring per
    //  command line ran the budget out mid-list, and every extra command added
    //  since has been invisible.
    //
    //  So commands are GROUPED. Grouping is what keeps the whole list inside the
    //  allowance; do not expand this back to one line per command, and if you
    //  add commands, add them to an existing line.
    a_lines = [];
    a_lines[a_lines.size] = "^5Quality Of Life ^7- chat commands (prefix ^3.^7 ^3!^7 or ^3/^7)";
    a_lines[a_lines.size] = "^3.help ^7show/hide   ^3.p <n> ^7points   ^3.where ^7coords";
    a_lines[a_lines.size] = "^3.god ^7god   ^3.ghost ^7ignored   ^3.afk ^7both   ^3.nightmode ^7on/off";
    a_lines[a_lines.size] = "^3.fly ^7noclip (WASD, jump/stance, melee stops)   ^3.fog ^7on/off";
    //  v2.3.4 - .round already existed but was never listed anywhere in this
    //  panel; .endround is new this version. Folded onto this line rather than
    //  a new one - the panel has a hard line budget, see the note above.
    a_lines[a_lines.size] = "^3.round <n>^7/^3.endround";
    a_lines[a_lines.size] = "^3.give <weapon> [pap] ^7any gun on this map   ^3.give list ^7show/hide";
    a_lines[a_lines.size] = "^3.brutus^7/^3.panzer^7/^3.jumpingjacks ^7(amount) ^8- Mob / Origins / Die Rise";
    a_lines[a_lines.size] = "^3.machines ^7drop every remaining machine ^8- Nuketown";
    a_lines[a_lines.size] = "^3.infammo ^7reserves   ^3.bclip ^7never reload   ^3.infsprint ^7never tire   ^3.reload ^7refill";
    //  v2.13.0 - .character folded onto this line rather than given its own,
    //  for the line budget noted above. It is the ONE command a non-host player
    //  needs to know exists, because the menu row cannot reach the server for
    //  them - see the command's own block in zmqol_dev_command_listener().
    a_lines[a_lines.size] = "^3.pack ^7/ ^3.unpack ^7Pack-a-Punch   ^3.character <1-4> ^7yours alone";
    a_lines[a_lines.size] = "^3.giveperks^7/^3.removeperks ^7  ^3.nozmspawns ^7spawns";
    //  v1.99.25 - the six ported commands. Two lines, not six, because of the
    //  line budget noted above; .movespeed is called that and not .speed
    //  because .speed already means the velocity HUD two lines up.
    a_lines[a_lines.size] = "^3.pay <player> <n> ^7give points   ^3.bring ^7all to you   ^3.killall";
    a_lines[a_lines.size] = "^3.shield ^7map's shield   ^3.staff <fire/ice/lightning/wind> ^8Origins   ^3.movespeed";
    //  One line, not two - see the budget note above. The alias list has to be
    //  discoverable somewhere or the per-perk commands may as well not exist,
    //  so it rides on the same line as the syntax rather than getting its own.
    a_lines[a_lines.size] = "^3.give^7/^3.remove^7 + ^3jug speed dtap stam mule revive deadshot phd tombstone whoswho cherry vulture";
    a_lines[a_lines.size] = "^3.powerups ^7list   ^3.powerup <name> ^7/ ^3.drop <name> ^7spawn one";
    a_lines[a_lines.size] = "^5console: ^3fly night_mode rapid_fire character no_power lod_fix wwfx";
    a_lines[a_lines.size] = "^5console: ^3give_weapon \"titus\" ^7or ^3\"titus pap\" ^8- bindable, self-clearing";
    a_lines[a_lines.size] = "^5console: ^3spawn_brutus ^7n ^3spawn_panzer ^7n ^3spawn_jumpingjacks ^7n";
    //  Chat commands are console dvars too - folded onto the line below rather
    //  than given its own, because this panel has a hard line budget and has
    //  been silently truncated before. See zmqol_console_command_watcher().

    //  v2.1.3 - hud_timer and hud_round_timer were merged into hud_timers
    //  (0 off, 1 both, 2 game only, 3 round only). The two old names still
    //  exist so an old config line is harmless, but nothing reads them any
    //  more, so listing them here would be advertising a dead switch.
    a_lines[a_lines.size] = "^5console: ^3hud_remaining hud_zone crosshair";
    a_lines[a_lines.size] = "^5chat cmds are dvars: ^3round 100^7 ^3pack 1";

    // 🛑 The tail of this panel is GENERATED, not typed - user: "make sure that
    // the .help command always is updated to show all the custom added chat
    // commands that are in my mod". A hand-written list is a second copy of the
    // truth and drifts the moment a command is added; every power-up is its own
    // command, so the hand-written version could never have been complete.
    //
    // level.zombie_powerups is the same runtime source .powerup itself resolves
    // against, and stock only populates it with power-ups the map actually
    // included (_zm_powerups.gsc:419 early-returns otherwise). So this prints
    // exactly the set that will work HERE - Origins shows zombie_blood, Buried
    // does not - and a power-up added later shows up with no edit to this
    // function.
    if ( isdefined( level.zombie_powerups ) )
    {
        a_keys = getarraykeys( level.zombie_powerups );

        if ( isdefined( a_keys ) && a_keys.size > 0 )
        {
            a_lines[a_lines.size] = "^5every power-up is also its own command ^7(" + a_keys.size + " here):";

            //  Six per line, for the budget reason above - at four per line a map
            //  with a dozen power-ups would cost three lines and push the tail of
            //  the list back off the screen, which is the bug this is fixing.
            str_line = "";
            for ( i = 0; i < a_keys.size; i++ )
            {
                if ( str_line != "" )
                    str_line = str_line + "^7 ";

                str_line = str_line + "^3." + a_keys[i];

                if ( ( i % 6 ) == 5 || i == a_keys.size - 1 )
                {
                    a_lines[a_lines.size] = "  " + str_line;
                    str_line = "";
                }
            }

            //  v2.15.4 - .bonfire added. The run-together spelling of every
            //  name printed above also works now (.bonfiresale, .thecure), so
            //  this line only needs the forms that are SHORTER than the key.
            a_lines[a_lines.size] = "^7short forms: ^3.dm ^3.nuke ^3.maxammo ^3.insta ^3.dp ^3.carp ^3.sale ^3.bonfire";
        }
    }

    return a_lines;
}

zmqol_print_help()
{
    self endon( "disconnect" );

    if ( isdefined( self.zmqol_help_hud ) )
    {
        self zmqol_help_close();
        return;
    }

    //  One panel at a time - the two share a HUD-element budget and the same
    //  top-left anchor. See zmqol_give_list_toggle().
    self zmqol_give_list_close();

    a_lines = zmqol_help_lines();
    self.zmqol_help_hud = [];

    //  🛑 Hard cap. The client HUD-element allowance is what silently ate the
    //  bottom of this panel before (see zmqol_help_lines), and a generated
    //  power-up section means the length now varies by map - so a map with an
    //  unusually long list must drop a line ON PURPOSE and SAY SO, rather than
    //  vanish and look like the earlier bug all over again.
    n_max = 14;

    if ( a_lines.size > n_max )
    {
        n_dropped = a_lines.size - n_max + 1;
        a_trimmed = [];

        for ( i = 0; i < n_max - 1; i++ )
            a_trimmed[a_trimmed.size] = a_lines[i];

        a_trimmed[a_trimmed.size] = "^1...and " + n_dropped + " more - see ^3.powerups";
        a_lines = a_trimmed;
    }

    for ( i = 0; i < a_lines.size; i++ )
    {
        e_line = self createfontstring( "small", 1.1 );

        //  Tucked into the very top-left, tight line spacing: the user's
        //  screenshot had the chat feed cutting straight through the middle of
        //  the list. Chat sits well below this now.
        e_line setpoint( "TOP_LEFT", "TOP_LEFT", 8, 18 + ( i * 12 ) );
        e_line.hidewheninmenu = 1;
        e_line.foreground = 1;
        e_line settext( a_lines[i] );
        self.zmqol_help_hud[ self.zmqol_help_hud.size ] = e_line;
    }
}

zmqol_help_close()
{
    if ( !isdefined( self.zmqol_help_hud ) )
        return;

    for ( i = 0; i < self.zmqol_help_hud.size; i++ )
    {
        if ( isdefined( self.zmqol_help_hud[i] ) )
            self.zmqol_help_hud[i] destroy();
    }

    self.zmqol_help_hud = undefined;
}

// ============================================================================
//  .powerup / .drop  -  spawn any power-up registered on this map
//  (added 2026-08-03, replaces the standalone ".dm" listener)
// ----------------------------------------------------------------------------
//  🛑 THE LIST IS NOT HARDCODED, ON PURPOSE.
//
//  maps\mp\zombies\_zm_powerups::add_zombie_powerup() early-returns when
//  level.zombie_include_powerups is defined and does not contain the powerup
//  (stock _zm_powerups.gsc:419-420). So level.zombie_powerups ends up holding
//  exactly the set the current map included - no more, no less. Iterating it
//  is therefore the only correct answer to "what can I spawn here", and it
//  picks up:
//    - the per-map ones a fixed list would miss ("zombie_blood" is Origins
//      only, "blue_monkey"/"the_cure" are likewise map-specific),
//    - this mod's own custom "deathmachine", with no special case.
//
//  Spawning goes through the stock specific_powerup_drop( name, origin )
//  (stock _zm_powerups.gsc:545), which is what the game itself calls. That one
//  call does powerup_setup + timeout + wobble + grab + move + emp. Spawning
//  the model directly would give a prop that just sits there.
//
//  The 70-unit forward offset is carried over verbatim from the old ".dm"
//  handler, which came from this file's own powerup_test() debug function.
// ============================================================================
zmqol_spawn_powerup( str_name )
{
    if ( !isdefined( str_name ) || str_name == "" )
        return;

    if ( !isdefined( level.zombie_powerups ) || !isdefined( level.zombie_powerups[ str_name ] ) )
    {
        self iprintln( "^1[zm_qol] ^7no power-up ^3" + str_name + "^7 on this map - try ^3.powerups" );
        return;
    }

    v_drop = self.origin + vectorscale( anglestoforward( self.angles ), 70 );
    level thread maps\mp\zombies\_zm_powerups::specific_powerup_drop( str_name, v_drop );
    self iprintln( "^2[zm_qol] ^7dropped ^3" + str_name );
}

// ----------------------------------------------------------------------------
//  Short forms. A bare command word is checked against the registered keys
//  FIRST, so every real powerup name works as its own command (".nuke",
//  ".carpenter", ".tesla", ".full_ammo") with nothing to maintain. The table
//  below only exists for the names people actually type instead.
//
//  Returns undefined when the word is not a powerup - the listener relies on
//  that to leave unknown commands alone.
// ----------------------------------------------------------------------------
//  v2.15.4 - the generic run-together matcher described in the default: branch
//  below. ".bonfiresale" -> "bonfire_sale", ".thecure" -> "the_cure", and so on
//  for anything this or a later version registers. Compares against the LIVE
//  key set, so it is correct per map with nothing to maintain.
zmqol_powerup_squashed( str_cmd )
{
    if ( !isdefined( str_cmd ) || str_cmd == "" || !isdefined( level.zombie_powerups ) )
        return undefined;

    a_keys = getarraykeys( level.zombie_powerups );

    if ( !isdefined( a_keys ) )
        return undefined;

    for ( i = 0; i < a_keys.size; i++ )
    {
        //  strtok on "_" then rejoined is this language's replace(). A key with
        //  no underscore comes back unchanged, which is harmless - the caller
        //  already tested the exact key before reaching here.
        a_parts  = strtok( a_keys[i], "_" );
        str_flat = "";

        for ( j = 0; j < a_parts.size; j++ )
            str_flat = str_flat + a_parts[j];

        if ( str_flat == str_cmd )
            return a_keys[i];
    }

    return undefined;
}

zmqol_powerup_alias( str_cmd )
{
    if ( !isdefined( str_cmd ) || !isdefined( level.zombie_powerups ) )
        return undefined;

    if ( isdefined( level.zombie_powerups[ str_cmd ] ) )
        return str_cmd;

    str_canon = undefined;

    switch ( str_cmd )
    {
        case "dm":
        case "deathmachine":
        case "minigun":          str_canon = "minigun";              break;
        case "ammo":
        case "maxammo":
        case "fullammo":         str_canon = "full_ammo";            break;
        case "ik":
        case "insta":
        case "instakill":        str_canon = "insta_kill";           break;
        case "dp":
        case "x2":
        case "doublepoints":     str_canon = "double_points";        break;
        case "sale":
        case "firesale":         str_canon = "fire_sale";            break;
        //  v2.15.4 - "bonfiresale" WAS MISSING AND IT WAS THE ONLY ONE OF THIS
        //  MOD'S OWN FIVE POWER-UPS WITH THE GAP. User, 2026-09-09: *"the
        //  bonfire sale powerup is missing a chat command, .bonfiresale"*.
        //  ".bonfire" and ".bonfire_sale" already worked (the latter free,
        //  because a bare registered key is checked before this table), so this
        //  adds the spelling people actually type. Every other two-word power-up
        //  here already carried its run-together form - fire_sale has
        //  "firesale", zombie_blood has "zombieblood", free_perk has "freeperk".
        case "bonfiresale":
        case "bonfire":          str_canon = "bonfire_sale";         break;
        case "carp":             str_canon = "carpenter";            break;
        case "perk":
        case "freeperk":         str_canon = "free_perk";            break;
        case "blood":
        case "zombieblood":      str_canon = "zombie_blood";         break;
        case "cure":             str_canon = "the_cure";             break;
        case "monkey":
        case "bluemonkey":       str_canon = "blue_monkey";          break;
        case "gun":
        case "randomgun":
        case "randomweapon":     str_canon = "random_weapon";        break;
        case "meat":
        case "meatstink":        str_canon = "meat_stink";           break;
        case "emptyclip":        str_canon = "empty_clip";           break;
        case "loseperk":         str_canon = "lose_perk";            break;
        case "losepoints":       str_canon = "lose_points_team";     break;
        //  v1.99.57 - BLOOD MONEY. User, 2026-08-18: *"you forgot to add a chat
        //  command to give the bloodmoney powerup, make it .bloodmoney/!bloodmoney"*.
        //  They are right that the friendly name was missing; the power-up itself
        //  was always reachable, because "bonuspoints" already resolved to
        //  it, and zmqol_enable_blood_money() includes exactly this name:
        //  maps\mp\zombies\_zm_utility::include_powerup( "bonus_points_player" ).
        //  So this adds names, not behaviour - the spawn path is unchanged.
        //  🛑 NOT to be confused with "blood" / "zombieblood" further down, which
        //  is zombie_blood, a completely different power-up.
        case "bloodmoney":
        case "blood_money":
        case "bonuspoints":      str_canon = "bonus_points_player";  break;
        case "teampoints":       str_canon = "bonus_points_team";    break;
        case "teller":
        case "withdrawl":        str_canon = "teller_withdrawl";     break;
        default:
            //  v2.15.4 - AND THE SAME GAP CANNOT HAPPEN AGAIN. The user's ask
            //  was "make sure the chat commands are up to date always", so the
            //  run-together spelling is no longer a per-power-up table entry
            //  that someone has to remember: zmqol_powerup_squashed() matches
            //  the typed word against every REGISTERED key with its underscores
            //  removed. That is what makes ".bonfiresale" work above, and it is
            //  also why ".thecure" and ".losepointsteam" now work without ever
            //  being listed - and why the next power-up added to this mod gets
            //  its run-together name for free.
            //
            //  🛑 STILL RETURNS undefined FOR A NON-POWER-UP WORD. The listener
            //  depends on that to leave unknown commands alone (and, since
            //  v2.11.0, to report a typo instead of silently doing nothing), so
            //  this only ever matches a key the map really registered.
            return zmqol_powerup_squashed( str_cmd );
    }

    // 🛑 "dm" is the interesting case. This mod's custom Death Machine registers
    // as "deathmachine", but stock's own minigun powerup is "minigun" and some
    // maps have that instead. Try the mod's name first, then fall back, so ".dm"
    // does the obvious thing on every map rather than erroring where the custom
    // powerup was never registered.
    if ( str_cmd == "dm" || str_cmd == "deathmachine" )
    {
        if ( isdefined( level.zombie_powerups[ "deathmachine" ] ) )
            return "deathmachine";
    }

    if ( isdefined( level.zombie_powerups[ str_canon ] ) )
        return str_canon;

    // Known short form, but this map did not register it. Return the canonical
    // name anyway so zmqol_spawn_powerup() prints the "not on this map" hint
    // instead of the command silently doing nothing.
    return str_canon;
}

zmqol_list_powerups()
{
    self endon( "disconnect" );

    if ( !isdefined( level.zombie_powerups ) )
    {
        self iprintln( "^1[zm_qol] ^7this map registers no power-ups" );
        return;
    }

    a_keys = getarraykeys( level.zombie_powerups );

    if ( !isdefined( a_keys ) || a_keys.size == 0 )
    {
        self iprintln( "^1[zm_qol] ^7this map registers no power-ups" );
        return;
    }

    self iprintln( "^5[zm_qol] ^3.powerup <name>^7 - " + a_keys.size + " on this map:" );

    // Batched three to a line, with a beat between writes. CLAUDE.md section 6:
    // one iprintln per entry would push ~20 reliable commands in a frame and the
    // feed expires lines on a timer anyway, so the top of the list scrolls off
    // before the bottom arrives - the exact problem the .help panel was built to
    // solve.
    str_line = "";
    n_per_line = 3;

    for ( i = 0; i < a_keys.size; i++ )
    {
        if ( str_line != "" )
            str_line = str_line + "^7, ";

        str_line = str_line + "^3" + a_keys[i];

        if ( ( i % n_per_line ) == ( n_per_line - 1 ) || i == ( a_keys.size - 1 ) )
        {
            self iprintln( str_line );
            str_line = "";
            wait 0.05;
        }
    }
}

// ============================================================================
//  Chat-command helpers
// ============================================================================

//  getweaponslist( 1 ) is what stock Max Ammo uses (_zm_powerups.gsc:1585) and it
//  covers offhand too - the stock code right below it tests is_lethal_grenade()
//  on the results - so grenades, claymores and equipment all refill from this one
//  call. weaponclipsize() returns 0 for weapons with no clip (grenades), so the
//  setweaponammoclip is guarded rather than applied blindly.
zmqol_fill_all_ammo()
{
    a_weapons = self getweaponslist( 1 );

    if ( !isdefined( a_weapons ) )
        return;

    foreach ( str_weapon in a_weapons )
    {
        self givemaxammo( str_weapon );

        n_clip = weaponclipsize( str_weapon );

        if ( n_clip > 0 )
            self setweaponammoclip( str_weapon, n_clip );

        str_alt = weaponaltweaponname( str_weapon );

        if ( isdefined( str_alt ) && str_alt != "none" )
        {
            self givemaxammo( str_alt );

            n_altclip = weaponclipsize( str_alt );

            if ( n_altclip > 0 )
                self setweaponammoclip( str_alt, n_altclip );
        }
    }
}

//  v2.15.53 - the same sweep as zmqol_fill_all_ammo() with every clip call
//  removed, for INFINITE AMMO. givemaxammo() tops up the RESERVE and leaves the
//  magazine alone, which is precisely stock Max Ammo's behaviour, so the reload
//  the player asked to keep still plays - it just always has stock to draw from.
zmqol_fill_all_reserves()
{
    a_weapons = self getweaponslist( 1 );

    if ( !isdefined( a_weapons ) )
        return;

    foreach ( str_weapon in a_weapons )
    {
        self givemaxammo( str_weapon );

        str_alt = weaponaltweaponname( str_weapon );

        if ( isdefined( str_alt ) && str_alt != "none" )
            self givemaxammo( str_alt );
    }
}

//  Infinite sprint, for .infsprint / .infinitesprint.
//
//  specialty_unlimitedsprint is the engine's own "the sprint meter never empties"
//  flag, not something scripted on top of the meter, so there is no drain loop to
//  fight and no HUD to hide. It is verified stock and verified ZM-side:
//  _zm_turned.gsc:117 sets it on a turned player and :191 unsets it again, which
//  is also where the clean off-switch comes from.
//
//  🛑 IT IS RE-APPLIED ON EVERY SPAWN rather than set once. A specialty lives on
//  the player entity, and going down and being revived - or bleeding out into a
//  respawn - hands you a player whose specialties have been rebuilt from the perks
//  you actually hold. Set once, the toggle would read ON in the player's own state
//  while the engine had quietly dropped it, which is worse than not having it. The
//  loop costs one notify per spawn.
zmqol_infinite_sprint_think()
{
    self endon( "disconnect" );
    self endon( "zmqol_infsprint_off" );
    level endon( "game_ended" );

    for ( ;; )
    {
        self setperk( "specialty_unlimitedsprint" );
        self waittill( "spawned_player" );
    }
}

// ============================================================================
//  BOTTOMLESS CLIP vs INFINITE AMMO - TWO CHEATS, NOT ONE
//
//  User request 2026-09-14: *"keep the infinite ammo option that's just like
//  bottomless clip basically, so rename that to bottomless clip... and then make
//  a separate [row] called infinite ammo where you still have to reload, but
//  your reserves are infinite, and so they're separated."*
//
//  🌟 THE SPLIT IS THE ENGINE'S OWN, AND IT COSTS NOTHING TO HONOUR. A T6 weapon
//  carries two counters: the CLIP (what is in the gun) and the STOCK (the
//  reserve). givemaxammo() fills only the stock - that is why grabbing a stock
//  Max Ammo drop never tops up the magazine you are holding - and
//  setweaponammoclip() is the separate call that fills the clip. The old single
//  cheat did both, so the magazine was never observed empty and the reload never
//  played. Dropping the clip call is therefore the whole of INFINITE AMMO:
//
//      BOTTOMLESS CLIP  stock + clip  ->  you never reload
//      INFINITE AMMO    stock only    ->  you reload normally, forever
//
//  🛑 THEY ARE INDEPENDENT, AND BOTTOMLESS CLIP WINS WHEN BOTH ARE ON. Each has
//  its own dvar, field, notify and thread, so neither can switch the other off.
//  With both armed the clip refill simply happens as well, which is bottomless
//  clip's behaviour - a superset, not a conflict, so no interlock is needed.
// ============================================================================
zmqol_bottomless_clip_think()
{
    self endon( "disconnect" );
    self endon( "zmqol_bclip_off" );
    level endon( "game_ended" );

    // The half-second sweep keeps stock, alt weapons and equipment topped up.
    self thread zmqol_bottomless_clip_on_fire();

    for ( ;; )
    {
        self zmqol_fill_all_ammo();
        wait 0.5;
    }
}

//  Reserves only. No setweaponammoclip anywhere on this path and no
//  "weapon_fired" subscriber either: the point of this cheat is that the reload
//  still happens, so there is no 1-round-magazine race to win here - the sweep
//  refills the stock the reload will draw from, and a half-second poll is far
//  faster than any reload animation.
zmqol_infinite_ammo_think()
{
    self endon( "disconnect" );
    self endon( "zmqol_infammo_off" );
    level endon( "game_ended" );

    for ( ;; )
    {
        self zmqol_fill_all_reserves();
        wait 0.5;
    }
}

// ============================================================================
//  zmqol_bottomless_clip_on_fire  -  🛑 A HALF-SECOND SWEEP CANNOT BEAT A 1-ROUND
//  MAGAZINE
//
//  User: "it works but sometimes for some weapons with low magazine counts like
//  a balistic knife which has 1 or an RPG which has 1 it automatically reloads
//  but the whole point of infinite ammo is so there's no reload."
//
//  The sweep refills every 0.5s, which is fine for a 30-round magazine - you
//  cannot empty one between ticks. On a 1-round weapon the magazine is empty the
//  instant you fire, and the engine starts the auto-reload on the NEXT FRAME,
//  long before the sweep comes round. The refill then lands mid-animation and you
//  watch a reload for ammo you already have.
//
//  So the refill has to happen on the SHOT, not on a timer. "weapon_fired" is the
//  notify the engine raises on the firing player, and refilling the clip in that
//  same frame means the magazine is never observed empty and the auto-reload is
//  never triggered at all - rather than being interrupted, which is not something
//  script can do.
//
//  📝 The general shape: a POLLING fix cannot cover an event that resolves faster
//  than the poll. When the thing you are correcting is edge-triggered, subscribe
//  to the edge.
// ============================================================================
zmqol_bottomless_clip_on_fire()
{
    self endon( "disconnect" );
    self endon( "zmqol_bclip_off" );
    level endon( "game_ended" );

    for ( ;; )
    {
        self waittill( "weapon_fired" );

        str_weapon = self getcurrentweapon();

        if ( !isdefined( str_weapon ) || str_weapon == "none" )
            continue;

        n_clip = weaponclipsize( str_weapon );

        if ( n_clip > 0 )
            self setweaponammoclip( str_weapon, n_clip );

        self givemaxammo( str_weapon );

        // The alt weapon too, so an underbarrel launcher behaves the same way.
        str_alt = weaponaltweaponname( str_weapon );

        if ( isdefined( str_alt ) && str_alt != "none" )
        {
            n_altclip = weaponclipsize( str_alt );

            if ( n_altclip > 0 )
                self setweaponammoclip( str_alt, n_altclip );

            self givemaxammo( str_alt );
        }
    }
}

//  T6 has no player noclip builtin a script can call - traversemode( "noclip" ) is
//  AI traversal, and the real "noclip"/"ufo" move modes are client debug commands
//  (stock only ever READS them, via player isinmovemode( "ufo", "noclip" ) in
//  _zm_devgui.gsc:1128). So flight has to be hand-rolled.
//
//  🛑 v1.18.2 hand-rolled it with setorigin() every 0.05s and the user reported it
//  "just kinda bugs out my player movement" - correctly. setorigin does not turn
//  off player physics: between our calls the engine still runs gravity, ground
//  trace and world collision on a normal walking player, then we teleport it back.
//  The two fight every frame, which is the stutter, and collision is never
//  disabled, so it is not noclip at all - you cannot pass through geometry.
//
//  The mechanism that DOES work is linking the player to a mover entity.
//  playerlinkto() hands position control to that entity outright: no gravity, no
//  world collision, view left free. Stock precedent, both shapes:
//      _qrdrone.gsc:350-352      spawn( "script_origin" ) -> hide() -> playerlinkto
//      zm_alcatraz_travel.gsc:770-774  the MOTD gondola - players ride a linked
//                                      script_origin and still look around and shoot
//  so a linked player is not a frozen one.
//
//  🛑 v1.22.0 PROBE RESULT - WASD IS NOT READABLE, AND THAT IS SETTLED.
//  v1.21.2 shipped a probe printing getnormalizedmovement() for the first ~3s of a
//  flight. Every single line in console_zm.log came back:
//      [zm_qol] fly: getnormalizedmovement UNDEFINED
//  Not "0 0" - UNDEFINED. The builtin returns nothing at all, so the movement
//  branch guarded on it could never run. That, and not the mover or the link, is
//  why flight was "stuck in place": the link held the player, and nothing ever
//  moved the mover.
//
//  Why: in the ZM script dump getnormalizedmovement() appears ONLY inside /# ... #/
//  developer blocks (_createfx.gsc:1272, 2721). It is a dev-build builtin and is
//  not exposed by the retail/Plutonium ZM build. The starter kit's GSC reference
//  lists it as a normal player function - that entry is wrong for this build, and
//  the runtime is the authority. Do not reintroduce it.
//
//  What every working T6 UFO mod does instead is read BUTTONS, never WASD, and
//  steer with the view. Two independent shipped implementations in this workspace
//  agree, and neither touches getnormalizedmovement:
//      Plutonium-T6-Scripts\chat_commands\chat_command_ufo_mode.gsc:83-117
//          MeleeButtonPressed() -> PlayerLinkTo + MoveTo( ... AnglesToForward ... )
//      littlegods-mod\funciones.gsc:1880-1921
//          fragButtonPressed() -> moveTo( origin + AnglesToForward * 20 )
//  So movement is: hold a button, fly the way you are looking. anglestoforward()
//  carries view PITCH, so looking up and holding forward climbs - jump/stance are
//  only there for fine vertical trim.
// ============================================================================
//  zmqol_fly_bind_wasd  -  REAL WASD, without reading movement state
//
//  getnormalizedmovement() is undefined in this build (see the block above
//  zmqol_fly_think), so WASD cannot be POLLED. But it can be SUBSCRIBED to:
//  notifyonplayercommand( notify, command ) fires a GSC notify when the client
//  issues a console command, and the movement keys are bound to the ordinary
//  console commands +forward / +back / +moveleft / +moveright.
//
//  🛑 The RELEASE form works too, and that is what makes held-state possible -
//  "-forward" fires on key-up. Confirmed in shipped code, not assumed:
//  Plutonium-T6-Scripts uses notifyonplayercommand("close_scores", "-scores")
//  alongside ("open_scores", "+scores"). Other shipped binds in the workspace
//  cover "+attack", "+melee", "+gostand", "+activate", "+speed_throw".
//
//  So each axis gets two one-line watcher threads - one sets the flag on press,
//  one clears it on release. Two separate watchers rather than a single
//  down-then-up loop on purpose: a loop that waits for "down" then "up" can
//  desync permanently if either notify is ever missed, and then the key sticks.
//
//  Bound once per player and guarded, because re-registering the same command
//  on every .fly toggle would stack duplicate notifies.
// ============================================================================
zmqol_fly_bind_wasd()
{
    if ( isdefined( self.zmqol_fly_bound ) )
        return;

    self.zmqol_fly_bound = 1;
    self.zmqol_fly_keys = [];
    self.zmqol_fly_keys["f"] = 0;
    self.zmqol_fly_keys["b"] = 0;
    self.zmqol_fly_keys["l"] = 0;
    self.zmqol_fly_keys["r"] = 0;

    self notifyonplayercommand( "zmqol_fly_f_dn", "+forward" );
    self notifyonplayercommand( "zmqol_fly_f_up", "-forward" );
    self notifyonplayercommand( "zmqol_fly_b_dn", "+back" );
    self notifyonplayercommand( "zmqol_fly_b_up", "-back" );
    self notifyonplayercommand( "zmqol_fly_l_dn", "+moveleft" );
    self notifyonplayercommand( "zmqol_fly_l_up", "-moveleft" );
    self notifyonplayercommand( "zmqol_fly_r_dn", "+moveright" );
    self notifyonplayercommand( "zmqol_fly_r_up", "-moveright" );

    //  🛑 v1.59.2 - RESYNC THE MOMENT THE CHAT BOX OPENS. This is the real fix
    //  for "it keeps moving on its own".
    //
    //  User, 2026-08-07: "sometimes after i stop pressing anything my character
    //  while in fly mode will keep moving on it's own in a certain direction,
    //  and the only way i have been able to fix it is by pressing the key that
    //  goes which ever direction that is being moved."
    //
    //  That last detail identifies the fault exactly. Pressing the drifting
    //  direction fixes it because press-then-release delivers the "-" notify
    //  that never arrived - so the state is a flag STUCK ON, not bad movement
    //  maths.
    //
    //  And the swallowed key-up has one dominant cause: opening chat takes
    //  keyboard focus, so a key held at that instant sends "+moveleft" and never
    //  "-moveleft". Every command in this mod is typed in chat, and flying is
    //  when the user types the most (.where, .fog, .fly itself), which is why it
    //  keeps happening mid-flight.
    //
    //  v1.5x already re-zeroed at takeoff and landing, which cannot help a
    //  release lost DURING a flight. Binding the chat-open commands themselves
    //  closes that window: the flags are wiped at the exact moment focus is
    //  taken, before the client can drop anything.
    //
    //  Both binds because T and Y are separate commands, and the mod's own
    //  commands are typed in either. These are ordinary console commands, the
    //  same class as the +forward binds above.
    self notifyonplayercommand( "zmqol_fly_chat", "chatmodepublic" );
    self notifyonplayercommand( "zmqol_fly_chat", "chatmodeteam" );

    self thread zmqol_fly_chat_resync();

    //  v1.59.3 - A BINDABLE FLY TOGGLE, so flying no longer requires opening
    //  chat. User: "make the .fly mode a dvar or whatever it's called,
    //  something i can enter in the console as well not just a chat command,
    //  this way i can bind it to a specific key."
    //
    //  GSC cannot register a new console command, so this rides an existing one
    //  the game already accepts and Zombies never uses. "+actionslot 7" is on
    //  the authoritative subscribable list
    //  (T6-Data-Archive-main\MPZM\Script\User Input\
    //   NOTIFYONPLAYERCOMMAND_NOTIFIES.txt, which is also where chatmodepublic
    //  was confirmed) and slots 5-7 have no Zombies binding to collide with.
    //
    //      bind x "+actionslot 7"
    //
    //  🌟 And it fixes the drift by construction for anyone who uses it: the
    //  whole reason keys get stuck is that opening chat swallows a key-up. A
    //  key bind never opens chat, so the failure cannot occur in the first
    //  place. Toggling this way is strictly safer than typing .fly.
    //  (The bind itself is installed at CONNECT, not here - see
    //  zmqol_fly_key_bind(). This function only runs on the first takeoff, so
    //  binding here would mean the key did nothing until you had already flown
    //  once by typing .fly, which defeats the point of having a bind.)

    self thread zmqol_fly_key_watch( "zmqol_fly_f_dn", "f", 1 );
    self thread zmqol_fly_key_watch( "zmqol_fly_f_up", "f", 0 );
    self thread zmqol_fly_key_watch( "zmqol_fly_b_dn", "b", 1 );
    self thread zmqol_fly_key_watch( "zmqol_fly_b_up", "b", 0 );
    self thread zmqol_fly_key_watch( "zmqol_fly_l_dn", "l", 1 );
    self thread zmqol_fly_key_watch( "zmqol_fly_l_up", "l", 0 );
    self thread zmqol_fly_key_watch( "zmqol_fly_r_dn", "r", 1 );
    self thread zmqol_fly_key_watch( "zmqol_fly_r_up", "r", 0 );
}

zmqol_fly_key_watch( str_notify, str_key, n_val )
{
    self endon( "disconnect" );
    level endon( "game_ended" );

    for ( ;; )
    {
        self waittill( str_notify );
        self.zmqol_fly_keys[str_key] = n_val;
    }
}

// ============================================================================
//  zmqol_fly_chat_resync  -  wipe the held-key flags whenever chat opens.
//
//  See the block in zmqol_fly_bind_wasd(). Opening chat takes keyboard focus,
//  so a movement key held at that instant can have its key-up swallowed and the
//  flag sticks on for the rest of the flight - which is the drift the user
//  reported and which pressing that same direction manually clears.
//
//  Runs for the whole match, not just while flying, because the flags are set
//  by watchers that also run for the whole match: a key stuck while walking
//  around would otherwise be waiting to bite at the next takeoff.
//
//  Wiping on chat-open cannot cost a real input. Movement is suspended while
//  the chat box has focus anyway, and any key still physically down re-arms
//  itself on its next press - one keystroke against a permanent drift, the same
//  trade the takeoff resync already makes.
// ============================================================================
zmqol_fly_chat_resync()
{
    self endon( "disconnect" );
    level endon( "game_ended" );

    for ( ;; )
    {
        self waittill( "zmqol_fly_chat" );
        self zmqol_fly_clear_keys();
    }
}

// ============================================================================
//  zmqol_fly_key_toggle  -  the bindable half of .fly
//
//      bind x "+actionslot 7"
//
//  Same toggle the chat command performs, minus the chat box. Bound once per
//  player in zmqol_fly_bind_wasd(), which is called on every takeoff and guards
//  itself, so the bind exists from the first flight onward.
//
//  The keys are wiped on every toggle whichever way it was triggered - takeoff
//  and landing were already resync points and this keeps that true for the
//  bind.
// ============================================================================
// ============================================================================
//  zmqol_fly_key_bind  -  install the bindable fly toggle, once, at connect.
//
//      bind x "+actionslot 7"
//
//  User, 2026-08-07: "make the .fly mode a dvar or whatever it's called,
//  something i can enter in the console as well not just a chat command, this
//  way i can bind it to a specific key so i dont have to keep opening chat."
//
//  GSC cannot register a new console command, so this rides one the game
//  already accepts and Zombies never uses. "+actionslot 7" is on the
//  authoritative subscribable list (T6-Data-Archive-main\MPZM\Script\
//  User Input\NOTIFYONPLAYERCOMMAND_NOTIFIES.txt - the same file that confirmed
//  chatmodepublic), and actionslots 5-7 have no Zombies binding to collide
//  with. Typing "+actionslot 7" straight into the console works too.
//
//  🌟 It also sidesteps the drift entirely. Keys get stuck because opening chat
//  swallows a key-up; a key bind never opens chat, so with this bound the
//  failure cannot happen at all. It is strictly safer than typing .fly.
//
//  At CONNECT rather than at takeoff, or the bind would not exist until after
//  the first chat-typed flight. Guarded so it cannot stack duplicate notifies.
// ============================================================================
zmqol_fly_key_bind()
{
    if ( isdefined( self.zmqol_fly_key_bound ) )
        return;

    self.zmqol_fly_key_bound = 1;

    //  Co-op: these act on server dvars, so only the host's copy may run.
    if ( !self scripts\zm\zmqol_playeropt::zmqol_popt_is_host() )
        return;

    self notifyonplayercommand( "zmqol_fly_key", "+actionslot 7" );
    self thread zmqol_fly_key_toggle();
    self thread zmqol_fly_dvar_watch();
    self thread zmqol_ww_give_dvar_watch();
    self thread zmqol_give_weapon_dvar_watch();   // v1.93.0 - give_weapon "<name> [pap]"
    self thread zmqol_toggle_dvar_watch();        // v1.94.0 - god/ghost/infinite_ammo/infinite_sprint
    self thread zmqol_boss_spawn_dvar_watch();
    self thread zmqol_set_points_watch();          // v1.99.93 - CHEATS > SET POINTS
    self thread zmqol_teleport_watch();            // v1.99.93 - CHEATS > TELEPORT
}

// ============================================================================
//  BOSS SPAWN COMMANDS                                             (v1.90.0)
//
//      .brutus (amount)        Mob of the Dead   zm_prison
//      .panzer (amount)        Origins           zm_tomb
//      .jumpingjacks (amount)  Die Rise          zm_highrise    (alias .jacks)
//
//      spawn_brutus <n> / spawn_panzer <n> / spawn_jumpingjacks <n>
//          console twins. The dvar carries the AMOUNT and is reset to 0 on
//          consumption, so it is a trigger and a keybind fires on every press -
//          the same shape as give_thundergun (zmqol_ww_give_dvar_watch).
//
//  🛑 EVERYTHING MAP-SPECIFIC LIVES IN THE MAP'S OWN SCRIPT. This file only
//  holds the parsing, the clamp and the dispatch; scripts\zm\<map>\<map>.gsc
//  installs level.zmqol_boss_spawn_func and level.zmqol_boss_name in its init().
//  See the note in the chat branch for why that split is mandatory rather than
//  stylistic.
//
//  📝 Each map's spawn function returns the number it actually started, or 0 if
//  that map's spawner is not up (grief/survival variants do not always run the
//  boss logic), so the message can tell the difference between "spawning 3" and
//  "this map is not ready" instead of silently doing nothing.
// ============================================================================
zmqol_boss_spawn_request( str_boss, n_amount )
{
    if ( str_boss == "jacks" )
        str_boss = "jumpingjacks";

    if ( n_amount < 1 )
        n_amount = 1;

    //  A cap, and it SAYS so rather than silently clamping. Eight of any of these
    //  three is already far past what the round logic ever spawns at once.
    if ( n_amount > 8 )
    {
        n_amount = 8;
        self iprintln( "^3[zm_qol] amount capped at ^78" );
    }

    if ( !isdefined( level.zmqol_boss_spawn_func ) || !isdefined( level.zmqol_boss_name ) )
    {
        self iprintln( "^1[zm_qol] this map has no boss ^8(.brutus Mob / .panzer Origins / .jumpingjacks Die Rise)" );
        return;
    }

    if ( str_boss != level.zmqol_boss_name )
    {
        self iprintln( "^1[zm_qol] ^7." + str_boss + " ^1is not this map's boss ^7- try ^3." + level.zmqol_boss_name );
        return;
    }

    n_done = level [[ level.zmqol_boss_spawn_func ]]( n_amount );

    if ( isdefined( n_done ) && n_done > 0 )
        self iprintln( "^2[zm_qol] spawning ^7" + n_done + " ^2" + level.zmqol_boss_name );
    else
        self iprintln( "^1[zm_qol] the " + level.zmqol_boss_name + " spawner is not running on this map" );
}

zmqol_boss_spawn_dvar_watch()
{
    if ( zmqol_minimal() )
        return;

    self endon( "disconnect" );
    level endon( "game_ended" );

    if ( getdvar( "spawn_brutus" ) == "" )
        setdvar( "spawn_brutus", "0" );

    if ( getdvar( "spawn_panzer" ) == "" )
        setdvar( "spawn_panzer", "0" );

    if ( getdvar( "spawn_jumpingjacks" ) == "" )
        setdvar( "spawn_jumpingjacks", "0" );

    for ( ;; )
    {
        wait 0.25;

        n_want = getdvarintdefault( "spawn_brutus", 0 );

        if ( n_want > 0 )
        {
            setdvar( "spawn_brutus", "0" );
            self zmqol_boss_spawn_request( "brutus", n_want );
        }

        n_want = getdvarintdefault( "spawn_panzer", 0 );

        if ( n_want > 0 )
        {
            setdvar( "spawn_panzer", "0" );
            self zmqol_boss_spawn_request( "panzer", n_want );
        }

        n_want = getdvarintdefault( "spawn_jumpingjacks", 0 );

        if ( n_want > 0 )
        {
            setdvar( "spawn_jumpingjacks", "0" );
            self zmqol_boss_spawn_request( "jumpingjacks", n_want );
        }
    }
}

// ============================================================================
//  zmqol_fly_dvar_watch  -  the "fly" console dvar.
//
//  User, 2026-08-07: "add my custom fly command as a dvar/console command so i
//  can also open up the console and do fly so i can bind it to a key."
//
//      fly 1              turn it on
//      fly 0              turn it off
//      bind x "toggle fly 0 1"
//
//  🌟 THE SAME MECHANISM night_mode USES, and that one is now confirmed working
//  from the console by the user. This mod runs through Plutonium's Mods menu,
//  where the host IS the client - one process - so a dvar typed at the console
//  is readable by getdvar() here. That is why night_mode works, and it is the
//  reason to copy its shape rather than invent a second one.
//
//  🛑 COMPARED AGAINST THE ACTUAL FLY STATE, never against the dvar's previous
//  value. The other two front-ends (.fly in chat, the +actionslot 7 bind) write
//  the dvar back when they toggle, so all three stay in agreement; a
//  previous-value comparison would fight them - toggling by chat would leave
//  the dvar reading 0 while flying, and the next poll would land the player.
//  Comparing to reality makes every path idempotent.
//
//  📝 The dvar is global rather than per-player, which is right for the Mods
//  menu (host plays alone or hosts) but would toggle every player at once on a
//  server. The chat command and the key bind are both per-player and remain the
//  correct choice there.
// ============================================================================
// ============================================================================
//  zm_qol: GIVE A WONDER WEAPON                                    (v1.73.0)
//
//  User, 2026-08-11: "instead of me having to spin the box a fuck load of times,
//  give me a console command to give each of the imported wonder weapons, one
//  for each (3 commands)."
//
//      chat        .thundergun          .wunderwaffe  (.dg2, .tesla)
//                  .wintershowl         (.winters, .freezegun)
//                  .wavegun             (.zapgun, .zapguns, .microwave, .mgun)   v2.10.14
//      console     give_thundergun 1    give_wunderwaffe 1    give_wintershowl 1    give_wavegun 1
//
//  Per the standing rule that every chat command must ALSO be a bindable console
//  command, each has a dvar front-end polled by zmqol_ww_give_dvar_watch(). The
//  dvar is a TRIGGER, not a state: it is reset to 0 the moment it is consumed,
//  so binding it to a key gives the gun on every press.
//
//  🛑 GATED ON zmqol_ww, and the check mirrors the three gate scripts exactly
//  (thundergun.gsc:25, teslagun.gsc:26, freeze.gsc:25). If a gun's init never
//  ran, its weapon was never precacheitem'd, and giveweapon on an unprecached
//  weapon is not a no-op - it is a script error. Unset means ON, matching the
//  scripts' own "" test.
// ============================================================================
zmqol_ww_gate_allows( str_which )
{
    str_ww = getdvar( "zmqol_ww" );
    return ( str_ww == "" || str_ww == "1" || str_ww == str_which );
}

zmqol_give_wonder_weapon( str_weapon, str_which, str_name )
{
    if ( !zmqol_ww_gate_allows( str_which ) )
    {
        self iprintln( "^1[zm_qol] " + str_name + " is off ^7- zmqol_ww is " + getdvar( "zmqol_ww" ) );
        return;
    }

    // 🛑 weapon_give(), NOT giveweapon(). User, 2026-08-11: "for some reason i have
    // 4 weapons, the m1911 you spawn in with, and the 3 wonder weapons."
    //
    // giveweapon() is the raw engine builtin - it hands over a weapon and nothing
    // else. It does not know about the zombies weapon limit, so three calls stacked
    // three guns on top of the starting pistol. maps\mp\zombies\_zm_weapons::
    // weapon_give() is the path the mystery box itself uses (:2331): it reads
    // get_player_weapon_limit( self ) - 2 normally, 3 with Mule Kick - takes the
    // current weapon when the player is at the limit, gives start ammo, switches,
    // and plays the pickup sound. Routing through it makes the console command
    // behave exactly like pulling the gun out of the box, which is the whole point.
    //
    // 📝 maps\mp\zombies\_zm* is globally safe to reference from a root
    // script (AI_CONTEXT rule 2), so this is legal from quality_of_life.gsc.
    //
    // 🛑 v2.15.5 - THROUGH zmqol_give_or_refill(), not weapon_give() raw. The
    // note that used to sit here said weapon_give "handles the already-holding
    // case itself" - it does, but only on an EXACT name match, so asking for the
    // base gun while holding the Pack-a-Punched one handed over a second copy.
    // See the banner over zmqol_held_twin().
    if ( self zmqol_give_or_refill( str_weapon ) )
        self iprintln( "^2[zm_qol] refilled ^7" + str_name );
    else
        self iprintln( "^2[zm_qol] gave ^7" + str_name );
}

// ============================================================================
//  .give <weapon> [pap]   /   give_weapon "<weapon>"        (v1.93.0)
//
//  User, 2026-08-14: "make sure that all the added weapons have console commands
//  to give myself the weapons, so i can instead of spamming the box for half an
//  hour and praying i get the weapon i wanna test, i can just give myself it
//  with the console to make sure it even works properly in zombies."
//
//  Covers every weapon this mod adds: the 11 ported MP/campaign guns and the
//  three BO1 wonder weapons. The wonder weapons keep their own dedicated
//  commands as well (.thundergun / .wunderwaffe / .wintershowl) - those route
//  through zmqol_give_wonder_weapon(), which additionally respects the zmqol_ww
//  gate, so this generic path defers to it for those three rather than handing
//  out a gun the gate has switched off.
//
//  🛑 THE TABLE IS BUILT FROM THE SAME NAMES zmqol_mp_weapons_init() REGISTERS.
//  If a weapon is added there and not here, .give simply will not know it - the
//  two lists are meant to be edited together, and .give list is what shows the
//  drift.
//
//  Per the standing "every chat command is also a dvar" rule, the console twin
//  is give_weapon:
//      give_weapon "titus"        gives the Titus-6
//      give_weapon "titus pap"    gives the Pack-a-Punched one
//      bind p "set give_weapon titus"
//  zmqol_give_weapon_dvar_watch() consumes it and blanks it again, so the same
//  bind fires every time rather than once.
// ============================================================================
zmqol_weapon_give_table()
{
    a = [];

    //  keys | base weapon | upgraded weapon | display name
    a[a.size] = zmqol_give_row( "swat swat556 sig556",              "sig556_zm",      "SWAT-556" );
    a[a.size] = zmqol_give_row( "falosw sa58 osw",                  "sa58_zm",        "FAL OSW" );
    a[a.size] = zmqol_give_row( "mk48",                             "mk48_zm",        "Mk 48" );
    a[a.size] = zmqol_give_row( "qbb qbb95 lsw",                    "qbb95_zm",       "QBB LSW" );
    a[a.size] = zmqol_give_row( "mp7",                              "mp7_zm",         "MP7" );
    a[a.size] = zmqol_give_row( "vector k10",                       "vector_zm",      "Vector K10" );
    a[a.size] = zmqol_give_row( "msmc insas",                       "insas_zm",       "MSMC" );
    a[a.size] = zmqol_give_row( "peacekeeper pk",                   "peacekeeper_zm", "Peacekeeper" );
    a[a.size] = zmqol_give_row( "crossbow bow",                     "crossbow_zm",    "Crossbow" );
    a[a.size] = zmqol_give_row( "xpr xpr50 as50 sniper",            "as50_zm",        "XPR-50" );
    a[a.size] = zmqol_give_row( "dragunov svd",                    "dragunov_zm",    "Dragunov" );
    a[a.size] = zmqol_give_row( "betty betties bouncingbetty",     "bouncingbetty_zm", "Bouncing Betty" );
    a[a.size] = zmqol_give_row( "titus titus6 dart",                "titus6_zm",      "Titus-6" );
    //  v1.99.13 - the Tac-45. The def is `fnp45`, so both names are accepted keys.
    //  `.give tac45 pap` hands over fnp45_upgraded_zm, and the engine brings the
    //  left-hand half with it off the def's DualWieldWeapon field - no separate
    //  give for fnp45lh_upgraded_zm, which is not a weapon a player may hold on
    //  its own.
    a[a.size] = zmqol_give_row( "tac45 tac-45 tac fnp45 fnp",       "fnp45_zm",       "Tac-45" );

    //  v1.99.25 - the six guns the ezz_server release exposed as their own
    //  commands (!galil !an94 !ms !monkeys !raygun !mk2). They ride the EXISTING
    //  .give table rather than becoming six more chat commands, because that is
    //  the "no duplicates" the user asked for: one give path, one help entry,
    //  and `pap` already works on all of them for free.
    //
    //  🛑 These are STOCK guns, unlike every row above, so they depend on the
    //  map having included them - weapon_give() is the box's own path and will
    //  simply do nothing where a weapon was never included. That is the honest
    //  behaviour and it is why they are not advertised as universal.
    //
    //  📝 m1911's upgrade IS Mustang & Sally, which is why `ms`/`mustang` are
    //  keys on the base row - `.give ms pap` hands over m1911_upgraded_zm.
    //  zmqol_give_row() derives every `upgraded` name by swapping the "_zm"
    //  suffix, and all six resolve: galil_upgraded_zm, an94_upgraded_zm,
    //  m1911_upgraded_zm, ray_gun_upgraded_zm, raygun_mark2_upgraded_zm.
    //  cymbal_monkey has no upgrade and `pap` on it is a no-op, same as stock.
    a[a.size] = zmqol_give_row( "galil",                            "galil_zm",         "Galil" );
    a[a.size] = zmqol_give_row( "an94 an-94",                       "an94_zm",          "AN-94" );
    a[a.size] = zmqol_give_row( "m1911 1911 ms mustang sally",      "m1911_zm",         "M1911 (pap = Mustang & Sally)" );
    a[a.size] = zmqol_give_row( "raygun ray rg",                    "ray_gun_zm",       "Ray Gun" );
    a[a.size] = zmqol_give_row( "mk2 mark2 markii raygun2",         "raygun_mark2_zm",  "Ray Gun Mark II" );
    a[a.size] = zmqol_give_row( "monkey monkeys cymbal",            "cymbal_monkey_zm", "Cymbal Monkey" );

    return a;
}

//  One row. The upgraded name is always base with "_upgraded" spliced in before
//  "_zm", which is the naming every one of these defs follows - checked against
//  weapons\zm\ rather than assumed.
// ============================================================================
//  .pay / .bring / .killall / .shield / .staff / .movespeed      (v1.99.25)
// ----------------------------------------------------------------------------
//  Ported from the ezz_server GSC release the user supplied. Only the commands
//  this mod did not already have, per their instruction to avoid duplicates.
//  Every stock name below was checked against the 2,093-file stock dump before
//  it was written - minus_to_player_score, getaispeciesarray, setmovespeedscale
//  and setactionslot all exist, as do all eleven weapon names used here.
// ============================================================================

//  Points transfer. Costs the sender, so it is the one command here that is
//  useful in co-op rather than just a cheat.
//  🛑 Deducts BEFORE granting and re-checks the balance at the moment of the
//  transfer, so two .pay calls in the same frame cannot mint points.
zmqol_pay_points( str_target, n_amount )
{
    if ( !isdefined( n_amount ) || n_amount <= 0 )
    {
        zmqol_iprintln_safe( self, "^1[zm_qol] amount must be a positive number" );
        return;
    }

    if ( self.score < n_amount )
    {
        zmqol_iprintln_safe( self, "^1[zm_qol] you only have ^7" + self.score + "^1 points" );
        return;
    }

    e_target = zmqol_player_by_name( str_target );

    if ( !isdefined( e_target ) )
    {
        zmqol_iprintln_safe( self, "^1[zm_qol] no player matching ^7" + str_target );
        return;
    }

    if ( e_target == self )
    {
        zmqol_iprintln_safe( self, "^1[zm_qol] you cannot pay yourself" );
        return;
    }

    //  🛑 The second argument is `ignore_double_points_upgrade` and it MUST be 1.
    //  Stock's minus_to_player_score( points ) runs the amount through
    //  pers_upgrade_double_points_set_score() when the persistent Double Points
    //  upgrade is active (_zm_score.gsc:333-337), so the sender would be charged
    //  MORE than the receiver gains. add_to_player_score has no such multiplier
    //  (:311-326), so only this side needed the flag. The donor script omits it
    //  and silently overcharges; found by reading the signature, not assumed.
    self maps\mp\zombies\_zm_score::minus_to_player_score( n_amount, 1 );
    e_target maps\mp\zombies\_zm_score::add_to_player_score( n_amount );

    zmqol_iprintln_safe( self, "^2[zm_qol] sent ^7" + n_amount + "^2 to ^7" + e_target.name );
    zmqol_iprintln_safe( e_target, "^2[zm_qol] ^7" + self.name + "^2 sent you ^7" + n_amount + "^2 points" );
}

//  Case-insensitive, and matches on a PREFIX so a partial name works - typing
//  a full name exactly is not realistic mid-round. An exact match always wins
//  over a prefix match, so a short name can never be shadowed by a longer one.
zmqol_player_by_name( str_name )
{
    if ( !isdefined( str_name ) )
        return undefined;

    str_name = tolower( str_name );
    a_players = get_players();

    for ( i = 0; i < a_players.size; i++ )
    {
        if ( isdefined( a_players[i].name ) && tolower( a_players[i].name ) == str_name )
            return a_players[i];
    }

    for ( i = 0; i < a_players.size; i++ )
    {
        if ( !isdefined( a_players[i].name ) )
            continue;

        str_have = tolower( a_players[i].name );

        if ( str_name.size <= str_have.size && getsubstr( str_have, 0, str_name.size ) == str_name )
            return a_players[i];
    }

    return undefined;
}

//  Teleport everyone else to you.
zmqol_bring_players()
{
    a_players = get_players();
    n = 0;

    for ( i = 0; i < a_players.size; i++ )
    {
        if ( a_players[i] == self || !isalive( a_players[i] ) )
            continue;

        a_players[i] setorigin( self.origin );
        a_players[i] setplayerangles( self.angles );
        n++;
    }

    zmqol_iprintln_safe( self, "^2[zm_qol] brought ^7" + n + "^2 player(s)" );
}

//  Kill every live zombie.
//  🛑 dodamage() rather than kill() or a health write, so the stock death path
//  runs in full - the round counter decrements, power-ups can drop and the
//  kill is attributed. Setting health to 0 skips all of that and desyncs the
//  round's zombie count, which is the classic way this command breaks a game.
zmqol_kill_all_zombies()
{
    a_zombies = getaispeciesarray( "axis", "all" );

    if ( !isdefined( a_zombies ) || a_zombies.size == 0 )
    {
        zmqol_iprintln_safe( self, "^3[zm_qol] no zombies alive" );
        return;
    }

    n = 0;

    for ( i = 0; i < a_zombies.size; i++ )
    {
        if ( !isdefined( a_zombies[i] ) || !isalive( a_zombies[i] ) )
            continue;

        a_zombies[i] dodamage( a_zombies[i].health + 666, a_zombies[i].origin, self );
        n++;
    }

    zmqol_iprintln_safe( self, "^2[zm_qol] killed ^7" + n + "^2 zombie(s)" );
}

//  The map's own buildable shield, straight to the shield slot.
//  🛑 Named by string, and the map test is a level VARIABLE - no map-specific
//  function is referenced, so this is safe in a root script.
//  Use native ownership, health reset, watchers and cleanup for debug grants.
zmqol_give_shield()
{
    str_shield = "";

    if ( level.script == "zm_tomb" )
        str_shield = "tomb_shield_zm";
    else if ( level.script == "zm_prison" )
        str_shield = "alcatraz_shield_zm";
    else if ( level.script == "zm_transit" )
        str_shield = "riotshield_zm";

    if ( str_shield == "" )
    {
        zmqol_iprintln_safe( self, "^1[zm_qol] this map has no shield" );
        return;
    }

    if ( self hasweapon( str_shield ) )
    {
        zmqol_iprintln_safe( self, "^3[zm_qol] you already have the shield" );
        return;
    }

    self maps\mp\zombies\_zm_equipment::equipment_buy( str_shield );
    zmqol_iprintln_safe( self, "^2[zm_qol] shield equipped" );
}

//  Origins' four upgraded staffs.
//  🌟 staff_revive_zm is the point of this command. It is "Sekhmet's Vigor",
//  the hidden melee half of a staff, and without it in the inventory the staff
//  viewmodel has no revive animation to fall back on - the reason handing a
//  staff over with a plain giveweapon bugs the player's hands. Given FIRST.
zmqol_give_staff( tokens )
{
    if ( level.script != "zm_tomb" )
    {
        zmqol_iprintln_safe( self, "^1[zm_qol] staffs are Origins only" );
        return;
    }

    if ( !isdefined( tokens ) || tokens.size < 2 )
    {
        zmqol_iprintln_safe( self, "^3[zm_qol] usage: ^7.staff <fire/ice/lightning/wind>" );
        return;
    }

    str_type = tolower( tokens[1] );
    str_weapon = "";

    if ( str_type == "fire" )
        str_weapon = "staff_fire_upgraded_zm";
    else if ( str_type == "ice" || str_type == "water" )
        str_weapon = "staff_water_upgraded_zm";
    else if ( str_type == "lightning" || str_type == "electric" )
        str_weapon = "staff_lightning_upgraded_zm";
    else if ( str_type == "wind" || str_type == "air" )
        str_weapon = "staff_air_upgraded_zm";

    if ( str_weapon == "" )
    {
        zmqol_iprintln_safe( self, "^1[zm_qol] use fire, ice, lightning or wind" );
        return;
    }

    if ( !self hasweapon( "staff_revive_zm" ) )
        self giveweapon( "staff_revive_zm" );

    self maps\mp\zombies\_zm_weapons::weapon_give( str_weapon );
    self switchtoweapon( str_weapon );
    zmqol_iprintln_safe( self, "^2[zm_qol] " + str_type + " staff equipped" );
}

//  🛑 NOT called .speed - that name already belongs to the velocity HUD in this
//  mod (see the .help panel), and quietly repurposing an existing command is a
//  worse outcome than a slightly longer name.
zmqol_toggle_movespeed()
{
    if ( !isdefined( self.zmqol_movespeed_on ) )
        self.zmqol_movespeed_on = 0;

    if ( self.zmqol_movespeed_on )
    {
        self.zmqol_movespeed_on = 0;
        self setmovespeedscale( 1 );
        zmqol_iprintln_safe( self, "^1[zm_qol] move speed: normal" );
        return;
    }

    self.zmqol_movespeed_on = 1;
    self setmovespeedscale( 1.5 );
    zmqol_iprintln_safe( self, "^2[zm_qol] move speed: ^71.5x" );
}

//  One place that checks the entity is still around before printing to it -
//  .pay prints to a SECOND player, who can disconnect between the lookup and
//  the print.
zmqol_iprintln_safe( e_player, str_msg )
{
    if ( isdefined( e_player ) && isplayer( e_player ) )
        e_player iprintln( str_msg );
}

// ============================================================================
//  zmqol_held_twin / zmqol_give_or_refill  -  ONE GUN, ONE COPY      (v2.15.5)
//
//  User, 2026-09-09, with a screenshot of an unpacked RPG-7 AND a packed Rocket
//  Propelled Grievance held at the same time: *"i gave myself the rpg twice and
//  i had the packed one and an unpacked one, make sure you cant have 2 of the
//  same weapon, grabbing the same weapon from the box is meant to just be an
//  ammo refill for the weapon."*
//
//  🌟 WHERE THE BUG ACTUALLY WAS - MEASURED, AND IT IS NOT THE BOX.
//  The box has been correct since v1.63.3: _zm_magicbox::treasure_chest_give_
//  weapon() (this mod's own copy) intercepts a re-pull, finds the held copy with
//  get_weapon_with_attachments() and calls givemaxammo() instead of handing over
//  a second gun. That path was never broken.
//
//  The `.give` commands never reach it. They call _zm_weapons::weapon_give()
//  directly, and stock's own "already holding it" branch there is
//      if ( self hasweapon( weapon ) ) { givestartammo(); switchtoweapon(); return; }
//  - an EXACT-NAME test. Hold "rpg_upgraded_zm+<att>" and ask for "rpg_zm" and it
//  is false, so the give falls through and you end up holding both. Stock never
//  hits this because its box gate (has_weapon_or_upgrade) blocks the re-pull long
//  before the give; this mod lifts that gate on purpose for NO BOX LIMITS, which
//  is what makes the `.give` hole reachable.
//
//  🛑 THE THREE CASES, AND WHY THE THIRD IS NOT A REFILL:
//    A  given what you hold          -> refill        (stock already did this)
//    B  given the BASE, holding PaP  -> refill the PaP copy. Never downgrade -
//                                       the same rule treasure_chest_give_weapon
//                                       and Origins' custom_swap_weapon follow.
//    C  given the PaP, holding BASE  -> a real upgrade, so take the base away and
//                                       hand over the packed gun. NOT a refill:
//                                       `.give <w> pap` is an explicit request
//                                       for the packed version and must deliver
//                                       it, it just must not leave you holding
//                                       both halves.
//
//  📝 get_weapon_with_attachments(), never hasweapon(). This mod sets
//  level.zombiemode_reusing_pack_a_punch = 1, so a packed gun is really held as
//  "<name>+<attachment>" and every exact-name test silently fails - the v1.63.3
//  case history in _zm_magicbox.gsc is the same trap, found the hard way on the
//  KSG and the LSAT.
// ============================================================================
zmqol_held_twin( str_weapon )
{
    if ( !isdefined( str_weapon ) || str_weapon == "" )
        return "";

    //  the weapon itself, attachments and all
    str_held = self maps\mp\zombies\_zm_weapons::get_weapon_with_attachments( str_weapon );

    if ( isdefined( str_held ) )
        return str_held;

    str_base = maps\mp\zombies\_zm_weapons::get_base_name( str_weapon );

    //  case B - asked for the base, already holding its Pack-a-Punched copy
    if ( isdefined( level.zombie_weapons ) && isdefined( level.zombie_weapons[ str_base ] ) &&
         isdefined( level.zombie_weapons[ str_base ].upgrade_name ) )
    {
        str_held = self maps\mp\zombies\_zm_weapons::get_weapon_with_attachments( level.zombie_weapons[ str_base ].upgrade_name );

        if ( isdefined( str_held ) )
            return str_held;
    }

    return "";
}

//  The base gun whose upgrade is str_weapon, or "" - stock's own reverse index,
//  set by add_zombie_weapon( base, upgrade, ... ).
zmqol_base_of_upgrade( str_weapon )
{
    if ( !isdefined( str_weapon ) || str_weapon == "" || !isdefined( level.zombie_weapons_upgraded ) )
        return "";

    str_base = maps\mp\zombies\_zm_weapons::get_base_name( str_weapon );

    if ( isdefined( level.zombie_weapons_upgraded[ str_base ] ) )
        return level.zombie_weapons_upgraded[ str_base ];

    return "";
}

//  Every `.give` route funnels through here instead of calling weapon_give()
//  raw. Returns 1 if it refilled rather than gave, so the caller can say so.
zmqol_give_or_refill( str_weapon )
{
    str_held = self zmqol_held_twin( str_weapon );

    if ( str_held != "" )
    {
        //  cases A and B - top the held copy up and put it in your hands. Stock's
        //  own refill is givestartammo(); the box uses givemaxammo(). Take the box's
        //  behaviour: this is the "grabbing the same weapon is an ammo refill" the
        //  request asks for, and a start-ammo refill on a gun you already carry
        //  would often be LESS ammo than you had.
        self givemaxammo( str_held );

        if ( !maps\mp\zombies\_zm_utility::is_offhand_weapon( str_held ) )
            self switchtoweapon( str_held );

        return 1;
    }

    //  case C - handing over the packed gun while the base is still held. Drop the
    //  base first so the two can never sit in the list together.
    //  unacquire_weapon_toggle() keeps the weapon-toggle bookkeeping straight,
    //  exactly as stock's own weapon_give does when it evicts a gun at the limit.
    str_base = self zmqol_base_of_upgrade( str_weapon );

    if ( str_base != "" )
    {
        str_have_base = self maps\mp\zombies\_zm_weapons::get_weapon_with_attachments( str_base );

        if ( isdefined( str_have_base ) )
        {
            self takeweapon( str_have_base );
            self maps\mp\zombies\_zm_weapons::unacquire_weapon_toggle( str_have_base );
        }
    }

    self maps\mp\zombies\_zm_weapons::weapon_give( str_weapon );
    return 0;
}

zmqol_give_row( str_keys, str_base, str_name )
{
    s = spawnstruct();
    s.keys = strtok( str_keys, " " );
    s.base = str_base;
    s.upgraded = getsubstr( str_base, 0, str_base.size - 3 ) + "_upgraded_zm";
    s.name = str_name;
    return s;
}

// ============================================================================
//  .give  -  v2.8.2: EVERY weapon on THIS map, equipment included
// ----------------------------------------------------------------------------
//  User, 2026-08-29: *".give for every weapon, not the current partial list.
//  Must be map-aware: only weapons that exist on the current map (no staffs on
//  Diner), and must include tactical/lethal equipment."*
//
//  🌟 THE MAP-AWARENESS IS NOT A TABLE THIS FILE MAINTAINS - IT IS THE GAME'S
//  OWN REGISTRY, READ AT RUNTIME. level.zombie_weapons is built by
//  maps\mp\zombies\_zm_weapons::add_zombie_weapon() (_zm_weapons.gsc:521-564),
//  keyed by weapon name, and that function opens with
//        if ( isdefined( level.zombie_include_weapons ) &&
//             !isdefined( level.zombie_include_weapons[weapon_name] ) ) return;
//  so the array contains EXACTLY the weapons this map included and nothing
//  else. No static per-map list can drift out of date against it, and the mod's
//  own added guns are in there too because zmqol_wallbuy_box_add() registers
//  them the same way.
//
//  🌟 EQUIPMENT IS ALREADY IN THAT SAME REGISTRY - measured, not assumed.
//  zm_transit.gsc:2011-2017 registers frag_grenade_zm, sticky_grenade_zm,
//  claymore_zm, cymbal_monkey_zm and emp_grenade_zm through add_zombie_weapon()
//  exactly like a gun, and every other map does the same with whichever subset
//  it ships. Cross-checked against the retail fastfiles themselves
//  (zm_qol - dev\parsed\sound_alias_universe\ff_weapons.txt):
//        zm_transit    frag claymore cymbal_monkey emp_grenade sticky
//        zm_nuked      frag claymore cymbal_monkey sticky
//        zm_highrise   frag claymore cymbal_monkey sticky
//        zm_prison     frag claymore willy_pete
//        zm_buried     frag claymore cymbal_monkey
//        zm_tomb       frag claymore cymbal_monkey sticky
//  So ".give monkey" works on Origins and correctly refuses on Mob, with no
//  per-map branch written here at all.
//
//  🌟 AND weapon_give() ALREADY KNOWS WHAT TO DO WITH EQUIPMENT. Stock's
//  weapon_give() (_zm_weapons.gsc) branches on is_lethal_grenade /
//  is_tactical_grenade / is_placeable_mine / is_equipment and swaps out the old
//  one, calls set_player_lethal_grenade(), gives start ammo and plays the
//  pickup. Nothing about handing over a grenade needs writing here.
//
//  🛑 THE UPGRADE NAME COMES FROM THE REGISTRY, NOT FROM STRING SURGERY.
//  zmqol_give_row() derives it by splicing "_upgraded" before "_zm", which is
//  right for the mod's own rows and WRONG for anything that breaks the pattern.
//  level.zombie_weapons[name].upgrade_name is what add_zombie_weapon was handed,
//  so it is the authority - and it is undefined for equipment, which is exactly
//  how ".give monkey pap" learns to say so instead of asking for a weapon that
//  does not exist.
//
//  📝 The curated alias table is kept and is tried BEFORE the loose match, so
//  every name that worked before still works ("swat", "msmc", "ms", "mk2"...).
//  What is new is that unknown names now fall through to the registry instead
//  of being rejected.
// ============================================================================

//  Lower-case, and with every underscore removed, so "ray_gun_zm", "ray gun"
//  and "raygun" all compare equal. Written as a character loop because GSC has
//  no string replace.
zmqol_give_squash( str_in )
{
    str_out = "";

    for ( i = 0; i < str_in.size; i++ )
    {
        c = str_in[i];

        if ( c != "_" && c != "-" )
            str_out = str_out + c;
    }

    return tolower( str_out );
}

//  Returns the registered weapon name, or "" when this map has nothing by that
//  name. Every return value is a key of level.zombie_weapons, so the caller
//  never has to re-check.
zmqol_give_resolve( str_arg )
{
    if ( !isdefined( level.zombie_weapons ) )
        return "";

    //  1. the exact registered name -   .give ray_gun_zm
    if ( isdefined( level.zombie_weapons[ str_arg ] ) )
        return str_arg;

    //  2. the name without its suffix - .give ray_gun
    if ( isdefined( level.zombie_weapons[ str_arg + "_zm" ] ) )
        return str_arg + "_zm";

    //  2b. THE NAME THE GAME ITSELF USES -  .give mauser, .give chicom,
    //      .give olympia, .give paralyzer, .give sliquifier.   (v2.9.0)
    //      Read out of the retail English string tables, not written from
    //      memory - see zmqol_give_names_table() for the dump command and for
    //      why this runs ahead of rules 3-5 without changing any older name.
    a_named = zmqol_give_names_table();

    foreach ( row in a_named )
    {
        if ( !isdefined( level.zombie_weapons[ row.def ] ) )
            continue;

        if ( row.show == str_arg )
            return row.def;

        //  🛑 GUARDED, and not defensively-for-the-sake-of-it: rows whose gun
        //  needs no second name pass "" for the key list, and strtok( "", " " )
        //  is not documented to return an empty array on T6 - it may return
        //  undefined, which would throw on the foreach. The guard costs one
        //  test and removes the whole question.
        if ( !isdefined( row.keys ) )
            continue;

        foreach ( key in row.keys )
        {
            if ( key == str_arg )
                return row.def;
        }
    }

    //  3. the curated aliases, so every name that worked before still does.
    a_rows = zmqol_weapon_give_table();

    foreach ( row in a_rows )
    {
        foreach ( key in row.keys )
        {
            if ( key == str_arg && isdefined( level.zombie_weapons[ row.base ] ) )
                return row.base;
        }
    }

    //  4. loose match against the registry -  .give raygunmark2, .give cymbalmonkey
    str_want = zmqol_give_squash( str_arg );
    a_keys = getarraykeys( level.zombie_weapons );

    for ( i = 0; i < a_keys.size; i++ )
    {
        str_name = a_keys[i];

        if ( zmqol_give_squash( str_name ) == str_want )
            return str_name;

        //  ...and again with the trailing "zm" dropped, so ".give raygunmark2"
        //  matches "raygun_mark2_zm" as well as ".give raygunmark2zm" would.
        str_squashed = zmqol_give_squash( str_name );

        if ( str_squashed.size > 2 && getsubstr( str_squashed, str_squashed.size - 2, str_squashed.size ) == "zm" )
        {
            if ( getsubstr( str_squashed, 0, str_squashed.size - 2 ) == str_want )
                return str_name;
        }
    }

    //  5. THE ART NAME.  v2.8.3, user report 2026-08-29: ".give olympia" failed
    //     while ".give m14" worked.  Cause: a BO2 weapon's DEF name and its ART
    //     name disagree for 17 guns, and the four rules above only ever see the
    //     def name.  The Olympia is the worst case - the def is rottweil72_zm
    //     and nothing about it contains the string the player actually knows.
    //
    //  🌟 THE TABLE IS MEASURED, NOT WRITTEN.  Every pair below was read out of
    //     the built mod.ff with
    //         Unlinker --include-assets weapon ... mod.ff
    //     and then each weapon asset's own viewmodel field, stripped of its
    //     t6_wpn_ prefix, its class infix (ar/smg/lmg/shotty/sniper/pistol/
    //     launch/zmb/minigun) and its _view suffix.  No name here was typed from
    //     memory - see zmqol_give_art_table() for the generated list.
    //
    //  📝 It still resolves THROUGH level.zombie_weapons, so a name only works
    //     on a map that actually registered the gun - which is the behaviour the
    //     rest of this function already has, and why ".give list" stays honest.
    str_art = zmqol_give_art_resolve( str_arg );

    if ( str_art != "" )
        return str_art;

    return "";
}

// ============================================================================
//  zmqol_give_art_resolve  -  ART NAME -> registered def name
// ----------------------------------------------------------------------------
//  Walks the measured art-name table and returns the first def this map has
//  actually registered.  Two art names are ambiguous by construction and both
//  are handled by that "this map registered it" test rather than by a rule:
//
//      minigun -> deathmachine_zm  AND  minigun_alcatraz_zm
//      x95l    -> tar21_zm         AND  gl_tar21_zm
//
//  Only one of each pair is ever in level.zombie_weapons on a given map, so the
//  loop below picks the right one without needing to know which map it is on.
// ============================================================================
zmqol_give_art_resolve( str_arg )
{
    if ( !isdefined( level.zombie_weapons ) )
        return "";

    a_rows = zmqol_give_art_table();

    for ( i = 0; i < a_rows.size; i++ )
    {
        if ( a_rows[i].art != str_arg )
            continue;

        if ( isdefined( level.zombie_weapons[ a_rows[i].def ] ) )
            return a_rows[i].def;
    }

    return "";
}

zmqol_give_art_row( str_art, str_def )
{
    o = spawnstruct();
    o.art = str_art;
    o.def = str_def;
    return o;
}

// ============================================================================
//  zmqol_give_art_table  -  GENERATED, do not hand-edit a name into this list
// ----------------------------------------------------------------------------
//  Regenerate after adding a weapon to mod.ff:
//
//    Unlinker --include-assets weapon --search-path <proj> -o <out> mod.ff
//    for each weapons/<name> that is not *_upgraded_zm:
//        art = first (t6_)?wpn_*_view field, minus prefix/class/suffix
//        emit the pair when art != <name minus _zm>
//
//  17 pairs at v2.8.3.  Names that already equal their def (ak47, an94, ksg,
//  lsat, svu, uzi, rnma, hamr, judge, kard, python, rpd, ...) are absent on
//  purpose: rules 1 and 2 in zmqol_give_resolve() already reach those.
// ============================================================================
zmqol_give_art_table()
{
    a = [];

    a[a.size] = zmqol_give_art_row( "ak74u",     "ak74u_extclip_zm" );
    a[a.size] = zmqol_give_art_row( "m82",       "barretm82_zm" );
    a[a.size] = zmqol_give_art_row( "b2023r",    "beretta93r_extclip_zm" );
    a[a.size] = zmqol_give_art_row( "mc96",      "c96_zm" );
    a[a.size] = zmqol_give_art_row( "minigun",   "deathmachine_zm" );
    a[a.size] = zmqol_give_art_row( "minigun",   "minigun_alcatraz_zm" );
    a[a.size] = zmqol_give_art_row( "scorpion",  "evoskorpion_zm" );
    a[a.size] = zmqol_give_art_row( "x95l",      "tar21_zm" );
    a[a.size] = zmqol_give_art_row( "x95l",      "gl_tar21_zm" );
    a[a.size] = zmqol_give_art_row( "type95",    "gl_type95_zm" );
    a[a.size] = zmqol_give_art_row( "xm8",       "gl_xm8_zm" );
    a[a.size] = zmqol_give_art_row( "m16a2",     "m16_zm" );
    a[a.size] = zmqol_give_art_row( "mp40",      "mp40_stalker_zm" );
    a[a.size] = zmqol_give_art_row( "stg44",     "mp44_zm" );
    a[a.size] = zmqol_give_art_row( "mp5",       "mp5k_zm" );
    a[a.size] = zmqol_give_art_row( "chicom",    "qcw05_zm" );
    a[a.size] = zmqol_give_art_row( "olympia",   "rottweil72_zm" );
    a[a.size] = zmqol_give_art_row( "saiga",     "saiga12_zm" );
    a[a.size] = zmqol_give_art_row( "scarh",     "scar_zm" );

    return a;
}

// ============================================================================
//  zmqol_give_names_table  -  THE NAME A PLAYER ACTUALLY TYPES        (v2.9.0)
// ----------------------------------------------------------------------------
//  User, 2026-08-30: *"make sure that the commands to give the weapons are
//  simple and would be what you'd expect to input to give them via commands ...
//  most people call the mauser the mauser even though it has the c96 part."*
//
//  The four rules that existed before all worked off the DEF name, so the only
//  names that ever worked were the engine's: .give c96, .give insas,
//  .give rottweil72, .give qcw05, .give as50, .give slowgun. Nobody calls them
//  that. This table is the missing half - the in-game name -> the def.
//
//  🌟 EVERY `show` NAME BELOW IS MEASURED, NOT REMEMBERED. They were read out
//  of the game's own English string tables, dumped from the retail language
//  fastfiles (en_patch_zm, en_patch_mp, en_ui_zm, en_zm_*, en_dlc*_load_zm):
//
//      Unlinker --include-assets localize --search-path <zone/english;zone/all>
//               -o <out> <zone/english/en_*.ff>
//
//  then joined to the defs through the &"..." reference each add_zombie_weapon()
//  call passes. So `qcw05_zm` is "Chicom CQB" because WEAPON_QCW05 says so, and
//  `c96_zm` is the Mauser because ZMWEAPON_C96 says "Mauser C96" - not because
//  it sounded right. 50 of them came back from that join directly; the wonder
//  weapons came from ZMWEAPON_PARALYZER / _SLIPGUN / _JETGUN / _BLUNDERGAT /
//  ZOMBIE_FREEZEGUN / ZOMBIE_TESLA_GUN / ZMWEAPON_STAFF_*, and `slowgun_zm` is
//  confirmed the Paralyzer by its own weapon pack, "wpck_paralyzer", in
//  zm_buried.gsc:1157.
//
//  📝 THE TWO THAT ARE NOT MEASURED, stated so nobody later reads this list as
//  all-verified: `retriever` / `hellsretriever` and `redeemer` /
//  `hellsredeemer` on the two tomahawk defs. Those names are in no string table
//  this workspace can read. They are added anyway because an extra alias cannot
//  break anything - it either matches or it does not - and `tomahawk`, which IS
//  derivable from the def, is on the same rows.
//
//  🛑 ORDER MATTERS AND THIS TABLE RUNS EARLY - rule 2b, ahead of the curated
//  table (3), the loose match (4) and the art table (5). All 257 keys below
//  were diffed against those three tables. Most already existed and point at
//  the SAME def they always did (swat, fal, xpr, mp5, chicom, olympia, saiga,
//  scarh, stg44, m82, mc96, scorpion, x95l, m16a2 ...).
//
//  THREE point somewhere else than the art table did, and all three are proven
//  no-ops:
//      mp40    art -> mp40_stalker_zm     here -> mp40_zm
//      type95  art -> gl_type95_zm        here -> type95_zm
//      xm8     art -> gl_xm8_zm           here -> xm8_zm
//  RULE 2 ALREADY BEAT THE ART TABLE TO ALL THREE: it tests `<arg>_zm` first,
//  so `.give mp40` has always returned mp40_zm whenever that is registered, and
//  the art row only ever fired on a map where the plain def is absent. Rule 2b
//  carries the same isdefined() guard, so on such a map it also falls through
//  to the art rule. Same answer on every map, before and after.
//
//  `ak74u`, `b2023r` and `minigun` are deliberately ABSENT: the first two
//  already resolve elsewhere, and `minigun` is intercepted by the Death Machine
//  case before any resolver rule runs.
//
//  📝 Seven registered defs get no row on purpose - ak74u_zm,
//  knife_ballistic_no_melee_zm, the four staff_*_upgraded_zm and
//  staff_water_zm_cheap. Rules 1 and 2 already reach all of them, and the list
//  printer falls back to the trimmed def name for exactly these.
//
//  🛑 Rules 1 and 2 still run FIRST, so the raw def name always wins. Nothing
//  here can shadow `.give <def>`.
//
//  📝 A PACK-A-PUNCHED NAME IS A KEY ON THE BASE ROW - boomhilda, sweeper,
//  petrifier, sassafras, wintersfury, zeuscannon, magnacollider, vitriolic.
//  That is not an oversight, it is the convention this file already shipped:
//  `ms` / `mustang` / `sally` have been keys on m1911_zm since v1.99.25 with
//  the note *".give ms pap hands over m1911_upgraded_zm"*. So the upgraded name
//  gets you the gun, and `pap` after it gets you the upgrade - one rule for all
//  of them rather than m1911 behaving unlike the rest.
// ============================================================================
zmqol_give_name_row( str_def, str_show, str_keys )
{
    o = spawnstruct();
    o.def  = str_def;
    o.show = str_show;

    //  strtok() is never handed "" - a gun that needs no second name simply has
    //  no key array, and the resolver skips it. This is the half of the pair
    //  that makes the isdefined( row.keys ) guard in zmqol_give_resolve() exact
    //  rather than hopeful.
    o.keys = undefined;

    if ( str_keys != "" )
        o.keys = strtok( str_keys, " " );

    return o;
}

zmqol_give_names_table()
{
    a = [];

    //  def | what .give list prints | every other name that reaches it
    a[a.size] = zmqol_give_name_row( "870mcs_zm",        "r870",        "870 870mcs r870mcs remington remington870 rem870" );
    a[a.size] = zmqol_give_name_row( "ak47_zm",          "ak47",        "ak" );
    a[a.size] = zmqol_give_name_row( "ak74u_extclip_zm", "ak74uext",    "ak74uextclip 74u" );
    a[a.size] = zmqol_give_name_row( "an94_zm",          "an94",        "" );
    a[a.size] = zmqol_give_name_row( "as50_zm",          "xpr50",       "xpr as50" );
    //  2026-10-07 round 2 - the stock Barrett pair came out (gunswap.gsc),
    //  the Dragunov takes its slots. The Barrett's names were briefly added
    //  here and came back out by user order (see the real-name policy in the
    //  BO1 block below).
    a[a.size] = zmqol_give_name_row( "dragunov_zm",      "dragunov",    "svd" );
    a[a.size] = zmqol_give_name_row( "bouncingbetty_zm", "betty",       "betties bouncingbetty" );
    a[a.size] = zmqol_give_name_row( "ballista_zm",      "ballista",    "" );
    a[a.size] = zmqol_give_name_row( "beacon_zm",        "beacon",      "homingbeacon artillerybeacon" );
    a[a.size] = zmqol_give_name_row( "beretta93r_zm",    "b23r",        "beretta beretta93r 93r" );
    a[a.size] = zmqol_give_name_row( "blundergat_zm",    "blundergat",  "sweeper" );
    a[a.size] = zmqol_give_name_row( "blundersplat_zm",  "acidgat",     "acid gat blundersplat vitriolic" );
    a[a.size] = zmqol_give_name_row( "bouncing_tomahawk_zm", "tomahawk", "hawk retriever hellsretriever" );
    a[a.size] = zmqol_give_name_row( "c96_zm",           "mauser",      "mauserc96 c96 boomhilda" );
    a[a.size] = zmqol_give_name_row( "claymore_zm",      "claymore",    "clay claymores" );
    a[a.size] = zmqol_give_name_row( "crossbow_zm",      "crossbow",    "bow xbow" );
    a[a.size] = zmqol_give_name_row( "cymbal_monkey_zm", "monkey",      "monkeys cymbal monkeybomb" );
    a[a.size] = zmqol_give_name_row( "dsr50_zm",         "dsr50",       "dsr" );
    a[a.size] = zmqol_give_name_row( "emp_grenade_zm",   "emp",         "empgrenade" );
    a[a.size] = zmqol_give_name_row( "evoskorpion_zm",   "skorpion",    "skorpionevo evo" );
    //  2026-10-07 round 2 - the Five-seveN pair came out (gunswap.gsc) for the
    //  Browning HP and its dual wield. The Browning row below answers to
    //  `browning` only - the Five-seveN's names came out by user order
    //  (see the real-name policy in the BO1 block below), and the DW's names
    //  died with it - the Browning HP DW has no give row, box-only like the
    //  MM1 and the Betties.
    a[a.size] = zmqol_give_name_row( "fnfal_zm",         "fal",         "fnfal fn-fal" );
    a[a.size] = zmqol_give_name_row( "fnp45_zm",         "tac45",       "tac fnp45 fnp" );
    a[a.size] = zmqol_give_name_row( "frag_grenade_zm",  "frag",        "frags grenade grenades" );
    a[a.size] = zmqol_give_name_row( "freezegun_zm",     "wintershowl", "winters howl freezegun wintersfury" );
    //  v2.10.14 - `.give wavegun pap` derives microwavegundw_upgraded_zm by the
    //  usual _zm swap; the combined gun rides along as the alt fire.
    a[a.size] = zmqol_give_name_row( "microwavegundw_zm", "wavegun",    "zapgun zapguns microwave mgun microwavegun" );
    a[a.size] = zmqol_give_name_row( "galil_zm",         "galil",       "" );
    //  2026-10-07 round 2 - the HAMR pair came out (gunswap.gsc); the MK48
    //  takes its slots and inherits its name (mk48 row below).
    a[a.size] = zmqol_give_name_row( "hk416_zm",         "m27",         "hk416" );
    a[a.size] = zmqol_give_name_row( "insas_zm",         "msmc",        "insas" );
    a[a.size] = zmqol_give_name_row( "jetgun_zm",        "jetgun",      "jet thrustodyne" );
    a[a.size] = zmqol_give_name_row( "judge_zm",         "judge",       "ragingjudge raging" );
    a[a.size] = zmqol_give_name_row( "kard_zm",          "kap40",       "kap kard" );
    a[a.size] = zmqol_give_name_row( "knife_ballistic_zm", "ballisticknife", "ballistic bk" );
    a[a.size] = zmqol_give_name_row( "knife_ballistic_bowie_zm", "ballisticbowie", "bowieknife bowie" );
    a[a.size] = zmqol_give_name_row( "ksg_zm",           "ksg",         "" );
    a[a.size] = zmqol_give_name_row( "lsat_zm",          "lsat",        "" );
    a[a.size] = zmqol_give_name_row( "m14_zm",           "m14",         "" );
    a[a.size] = zmqol_give_name_row( "m16_zm",           "m16",         "m16a1 m16a2 colt" );
    a[a.size] = zmqol_give_name_row( "m1911_zm",         "m1911",       "1911 ms mustang sally" );
    //  m32_zm/"warmachine" row came out with the War Machine swap (gunswap.gsc,
    //  2026-10-07); the MM1 is box-only and has no give row, like the Betties.
    a[a.size] = zmqol_give_name_row( "metalstorm_mms_zm", "stormpsr",   "storm psr metalstorm" );
    a[a.size] = zmqol_give_name_row( "mg08_zm",          "mg08",        "mg0815 magnacollider" );
    a[a.size] = zmqol_give_name_row( "mk48_zm",          "mk48",        "" );
    a[a.size] = zmqol_give_name_row( "mp40_zm",          "mp40",        "" );
    a[a.size] = zmqol_give_name_row( "mp40_stalker_zm",  "mp40stalker", "" );
    a[a.size] = zmqol_give_name_row( "mp44_zm",          "stg44",       "stg mp44" );
    a[a.size] = zmqol_give_name_row( "mp5k_zm",          "mp5",         "mp5k" );
    a[a.size] = zmqol_give_name_row( "mp7_zm",           "mp7",         "" );
    a[a.size] = zmqol_give_name_row( "pdw57_zm",         "pdw57",       "pdw" );
    a[a.size] = zmqol_give_name_row( "peacekeeper_zm",   "peacekeeper", "pk" );
    a[a.size] = zmqol_give_name_row( "python_zm",        "python",      "" );
    a[a.size] = zmqol_give_name_row( "qbb95_zm",         "qbb",         "qbb95 lsw qbblsw" );
    a[a.size] = zmqol_give_name_row( "qcw05_zm",         "chicom",      "chicomcqb cqb qcw qcw05" );
    a[a.size] = zmqol_give_name_row( "ray_gun_zm",       "raygun",      "ray rg" );
    a[a.size] = zmqol_give_name_row( "raygun_mark2_zm",  "raygunmk2",   "mk2 mark2 markii raygun2" );
    a[a.size] = zmqol_give_name_row( "riotshield_zm",    "zombieshield", "shield riotshield" );
    a[a.size] = zmqol_give_name_row( "rnma_zm",          "rnma",        "newmodelarmy nma sassafras" );
    a[a.size] = zmqol_give_name_row( "rottweil72_zm",    "olympia",     "rottweil rottweil72" );
    //  2026-10-07 round 2 - the RPD pair came out (gunswap.gsc); the M60
    //  (the BO1 block below) takes its slots. nothing answers to "rpd".
    a[a.size] = zmqol_give_name_row( "sa58_zm",          "falosw",      "osw sa58 fal-osw" );
    //  2026-10-07 round 2 - the stock S12 row came out with the gun itself
    //  (gunswap.gsc). The SPAS-12 takes its slots - its restored row is
    //  after slowgun, answering to spas12 only by user order.
    a[a.size] = zmqol_give_name_row( "saritch_zm",       "saritch",     "toz tozsaritch" );
    a[a.size] = zmqol_give_name_row( "scar_zm",          "scarh",       "scar" );
    a[a.size] = zmqol_give_name_row( "sig556_zm",        "swat",        "swat556 sig556 sig" );
    a[a.size] = zmqol_give_name_row( "slipgun_zm",       "sliquifier",  "sliq slipgun" );
    a[a.size] = zmqol_give_name_row( "slowgun_zm",       "paralyzer",   "slowgun petrifier" );
    //  v2.9.18 SPAS-12 give row, restored 2026-10-07 round 2 (the gun is back,
    //  replacing the stock S12 - gunswap.gsc). The S12's names (s12/saiga)
    //  were inherited for a few hours and came back OUT by user order: .give
    //  answers to the real gun's name, never a dead gun's. `spaz24` is the
    //  PaP name's plain form. The Origins copy rows further down
    //  (saiga12qol_zm) stay: that pair has been held back on Origins
    //  since v2.14.4, so those rows never resolve anywhere.
    a[a.size] = zmqol_give_name_row( "spas_zm",          "spas12",      "spas spas-12 spaz24 spaz-24" );
    a[a.size] = zmqol_give_name_row( "srm1216_zm",       "m1216",       "1216 srm1216 srm" );
    a[a.size] = zmqol_give_name_row( "staff_air_zm",     "windstaff",   "staffofwind staffwind wind air" );
    a[a.size] = zmqol_give_name_row( "staff_fire_zm",    "firestaff",   "staffoffire stafffire fire" );
    a[a.size] = zmqol_give_name_row( "staff_lightning_zm", "lightningstaff", "staffoflightning stafflightning lightning" );
    a[a.size] = zmqol_give_name_row( "staff_water_zm",   "icestaff",    "staffofice staffice ice staffwater water" );
    a[a.size] = zmqol_give_name_row( "staff_revive_zm",  "revivestaff", "staffrevive sekhmet" );
    a[a.size] = zmqol_give_name_row( "sticky_grenade_zm", "semtex",     "sticky stickygrenade" );
    a[a.size] = zmqol_give_name_row( "svu_zm",           "svu",         "svuas" );
    a[a.size] = zmqol_give_name_row( "tar21_zm",         "mtar",        "tar21 x95 x95l" );
    a[a.size] = zmqol_give_name_row( "tazer_knuckles_zm", "galvaknuckles", "galva knuckles tazer" );
    a[a.size] = zmqol_give_name_row( "tesla_gun_zm",     "wunderwaffe", "dg2 tesla teslagun" );
    a[a.size] = zmqol_give_name_row( "thompson_zm",      "thompson",    "m1927 tommy tommygun" );
    a[a.size] = zmqol_give_name_row( "thundergun_zm",    "thundergun",  "thunder zeus zeuscannon" );
    a[a.size] = zmqol_give_name_row( "time_bomb_zm",     "timebomb",    "bomb" );
    a[a.size] = zmqol_give_name_row( "titus6_zm",        "titus6",      "titus dart flechette" );
    a[a.size] = zmqol_give_name_row( "type95_zm",        "type25",      "type95 type" );
    a[a.size] = zmqol_give_name_row( "upgraded_tomahawk_zm", "redeemer", "hellsredeemer upgradedtomahawk" );
    a[a.size] = zmqol_give_name_row( "uzi_zm",           "uzi",         "" );
    a[a.size] = zmqol_give_name_row( "vector_zm",        "vector",      "k10 vectork10" );
    a[a.size] = zmqol_give_name_row( "willy_pete_zm",    "smoke",       "smokegrenade willypete" );
    a[a.size] = zmqol_give_name_row( "xm8_zm",           "m8a1",        "m8 xm8" );

    // ------------------------------------------------------------------
    //  v2.15.0 - the four Black Ops 1 guns. The stock RPG came out with the
    //  2026-10-07 gunswap (usrpg_zm is banned from registration), so the
    //  RPG-7 inherited its `rpg` and `usrpg` aliases as well as `rpg7`.
    //  Round 2, same day: the M60 takes the RPD's slots and the Browning HP
    //  takes the Five-seveN's, and both are registered on Origins now too
    //  (the tomb hold-back below is down to the RPG-7 alone).
    //
    //  POLICY, USER, SAME DAY, twice in one hour so it is law: ".give is
    //  by the real gun's name only." The dead stock guns' names (rpd, hamr,
    //  barrett, s12, fiveseven, 57) were briefly inherited by their
    //  replacements and came back OUT by user order - those commands resolve
    //  to nothing now, and that is the intended state, not an oversight.
    // ------------------------------------------------------------------
    a[a.size] = zmqol_give_name_row( "m60_zm",           "m60",         "thepig pig" );
    a[a.size] = zmqol_give_name_row( "t5_l96a1_zm",      "l96",         "l96a1 l115 isolator" );
    a[a.size] = zmqol_give_name_row( "browninghp_zm",    "browning",    "browninghp hipower bap" );
    a[a.size] = zmqol_give_name_row( "rpg_zm",           "rpg7",        "rpg-7 bo1rpg rpg usrpg" );

    // ------------------------------------------------------------------
    //  v2.9.1 - THE NINE ORIGINS COPIES. Same friendly names as the guns
    //  they copy, so .give mp5 / olympia / m16 keeps working on Origins.
    //  Only one of each pair is ever registered on a given map, so the
    //  isdefined() guard in rule 2b picks the right one with no map test.
    //  See zmqol_tomb_weapon() for why Origins has its own copies at all.
    // ------------------------------------------------------------------
    a[a.size] = zmqol_give_name_row( "mp5kqol_zm",       "mp5",         "mp5k" );
    a[a.size] = zmqol_give_name_row( "rottweil72qol_zm", "olympia",     "rottweil rottweil72" );
    a[a.size] = zmqol_give_name_row( "m16qol_zm",        "m16",         "m16a1 m16a2 colt" );
    a[a.size] = zmqol_give_name_row( "as50qol_zm",       "xpr50",       "xpr as50" );
    a[a.size] = zmqol_give_name_row( "barretm82qol_zm",  "barrett",     "m82 m82a1 barret" );
    a[a.size] = zmqol_give_name_row( "judgeqol_zm",      "judge",       "ragingjudge raging" );
    a[a.size] = zmqol_give_name_row( "saiga12qol_zm",    "s12",         "saiga saiga12" );
    a[a.size] = zmqol_give_name_row( "saritchqol_zm",    "saritch",     "toz tozsaritch" );
    a[a.size] = zmqol_give_name_row( "tar21qol_zm",      "mtar",        "tar21 x95 x95l" );

    return a;
}

//  The name .give list should print for a def, or "" when this table has no
//  row for it - the caller then falls back to the def with "_zm" trimmed, which
//  is what the list always printed.
//
//  🛑 THE ROWS ARE PASSED IN, NOT BUILT HERE, and that is not a style choice.
//  zmqol_give_names_table() spawns 84 structs every time it is called, and the
//  list printer calls this once per registered weapon - up to ~90 on a fully
//  unlocked map. Building the table inside would spawn seven thousand structs
//  in one frame for a single .give list. Built once by the caller instead.
zmqol_give_show_name( str_def, a_rows )
{
    for ( i = 0; i < a_rows.size; i++ )
    {
        if ( a_rows[i].def == str_def )
            return a_rows[i].show;
    }

    return "";
}

// ============================================================================
//  .give list  -  AN ON-SCREEN PANEL YOU TOGGLE, NOT A BURST OF CHAT   (v2.9.3)
// ----------------------------------------------------------------------------
//  User, 2026-08-30: *"the .give list chat command is awkward as it lists them
//  so fast you cant read them ... make the .give list command show all the
//  options on screen until you turn it back off with the same command"*.
//
//  Their screenshot is the proof: four lines of names on screen and the header
//  already scrolled away. iprintln() writes into the chat ring, which holds a
//  handful of lines and ages them out - so a 90-name list on Origins could
//  never be read, no matter how the printing was paced. The old version even
//  had `wait 0.05` between lines to stop it outrunning the ring; that slowed
//  the loss down without preventing it.
//
//  So this is modelled on .help, which the user named as the behaviour they
//  want: a HUD panel that stays up until the same command takes it down.
//
//  🛑 THE HUD-ELEMENT BUDGET IS SHARED WITH .help AND IT IS REAL. See
//  zmqol_help_lines() for the failure it caused there - a client has a fixed
//  allowance and this mod already spends ~13 of it on permanent elements, so
//  running two long panels at once is what silently truncated .help before.
//  Opening either panel therefore closes the other. That also keeps them from
//  being drawn on top of each other, since both anchor to the top-left.
//
//  🛑 THE TABLE IS BUILT ONCE. zmqol_give_names_table() spawns 84 structs per
//  call and zmqol_give_show_name() needs it once per registered weapon - up to
//  ~90 on a fully unlocked map. Building it inside the loop would spawn seven
//  thousand structs to draw one panel.
// ============================================================================
zmqol_give_list_lines()
{
    a_lines = [];

    if ( !isdefined( level.zombie_weapons ) )
    {
        a_lines[a_lines.size] = "^1[zm_qol] this map registered no weapons";
        return a_lines;
    }

    a_keys  = getarraykeys( level.zombie_weapons );
    a_named = zmqol_give_names_table();

    a_lines[a_lines.size] = "^5.give ^7- " + a_keys.size + " weapons on this map   ^3.give <name> pap ^7for upgraded   ^3.give list ^7hides this";

    str_line = "";
    n_on_line = 0;

    for ( i = 0; i < a_keys.size; i++ )
    {
        //  The name a player would TYPE, not the engine's def - mauser, msmc,
        //  olympia, chicom, xpr50, paralyzer. Every name shown is a key rule 2b
        //  accepts, which is the contract this loop and zmqol_give_names_table()
        //  keep between them.
        str_show = zmqol_give_show_name( a_keys[i], a_named );

        if ( str_show == "" )
        {
            //  No row for it - the def with "_zm" trimmed, which rule 2 resolves.
            str_show = a_keys[i];

            if ( str_show.size > 3 && getsubstr( str_show, str_show.size - 3, str_show.size ) == "_zm" )
                str_show = getsubstr( str_show, 0, str_show.size - 3 );
        }

        if ( n_on_line == 0 )
            str_line = str_show;
        else
            str_line = str_line + "  " + str_show;

        n_on_line++;

        //  Eight per line, the width the user's own screenshot proves fits.
        //  Ten was tried and reverted before shipping: the sample in that
        //  screenshot is all short names (semtex frag hamr rpd barrett dsr50
        //  fnfal galil), and the registry also holds ballisticknife,
        //  galvaknuckles, lightningstaff and raygunmk2 - ten of those would run
        //  off the side of the screen. Eight names still fits ~90 weapons into
        //  12 lines, inside the 14-element cap below.
        if ( n_on_line >= 8 )
        {
            a_lines[a_lines.size] = "^7" + str_line;
            str_line = "";
            n_on_line = 0;
        }
    }

    if ( n_on_line > 0 )
        a_lines[a_lines.size] = "^7" + str_line;

    return a_lines;
}

zmqol_give_list_toggle()
{
    if ( isdefined( self.zmqol_give_list_hud ) )
    {
        self zmqol_give_list_close();
        return;
    }

    //  One panel at a time - see the budget note above.
    self zmqol_help_close();

    a_lines = zmqol_give_list_lines();

    //  Same hard cap and same honesty as .help: a map with an unusually long
    //  registry drops lines ON PURPOSE and says how many, rather than running
    //  the client out of HUD elements and vanishing.
    n_max = 14;

    if ( a_lines.size > n_max )
    {
        n_dropped = a_lines.size - n_max + 1;
        a_trimmed = [];

        for ( i = 0; i < n_max - 1; i++ )
            a_trimmed[a_trimmed.size] = a_lines[i];

        a_trimmed[a_trimmed.size] = "^1...and " + ( n_dropped * 8 ) + " more not shown";
        a_lines = a_trimmed;
    }

    self.zmqol_give_list_hud = [];

    for ( i = 0; i < a_lines.size; i++ )
    {
        e_line = self createfontstring( "small", 1.1 );
        e_line setpoint( "TOP_LEFT", "TOP_LEFT", 8, 18 + ( i * 12 ) );
        e_line.hidewheninmenu = 1;
        e_line.foreground = 1;
        e_line settext( a_lines[i] );
        self.zmqol_give_list_hud[ self.zmqol_give_list_hud.size ] = e_line;
    }
}

zmqol_give_list_close()
{
    if ( !isdefined( self.zmqol_give_list_hud ) )
        return;

    for ( i = 0; i < self.zmqol_give_list_hud.size; i++ )
    {
        if ( isdefined( self.zmqol_give_list_hud[i] ) )
            self.zmqol_give_list_hud[i] destroy();
    }

    self.zmqol_give_list_hud = undefined;
}

zmqol_give_named_weapon( str_arg, b_pap )
{
    if ( !isdefined( str_arg ) )
        return;

    str_arg = tolower( str_arg );

    if ( !isdefined( b_pap ) )
        b_pap = 0;

    //  The three wonder weapons keep their own path so the zmqol_ww gate and
    //  their friendlier failure message still apply.
    if ( str_arg == "thundergun" || str_arg == "zeus" )
    {
        self zmqol_give_wonder_weapon( "thundergun_zm", "2", "Thundergun" );
        return;
    }

    if ( str_arg == "wunderwaffe" || str_arg == "dg2" || str_arg == "tesla" )
    {
        self zmqol_give_wonder_weapon( "tesla_gun_zm", "3", "Wunderwaffe DG-2" );
        return;
    }

    if ( str_arg == "wintershowl" || str_arg == "winters" || str_arg == "freezegun" )
    {
        self zmqol_give_wonder_weapon( "freezegun_zm", "4", "Winter's Howl" );
        return;
    }

    if ( str_arg == "wavegun" || str_arg == "zapgun" || str_arg == "zapguns" || str_arg == "microwave" || str_arg == "mgun" )
    {
        self zmqol_give_wonder_weapon( "microwavegundw_zm", "5", "Wave Gun" );
        return;
    }

    //  v2.8.6 - THE DEATH MACHINE. User report 2026-08-30: ".give deathmachine
    //  didn't give me the deathmachine minigun". It never could: zmqol_give_resolve()
    //  only looks in level.zombie_weapons, and deathmachine_zm is a POWER-UP weapon -
    //  precacheitem'd in init() but never include_weapon'd, so it is not in that
    //  table. Measured: it is the only real gun in that gap; everything else
    //  precached-but-not-included is a perk bottle or the knuckle-crack prop.
    if ( str_arg == "deathmachine" || str_arg == "dm" || str_arg == "minigun" )
    {
        //  NOT via zmqol_give_wonder_weapon() - that gates on zmqol_ww, and the
        //  Death Machine is a power-up, not one of the three wonder weapons.
        if ( self zmqol_give_or_refill( "deathmachine_zm" ) )
            self iprintln( "^2[zm_qol] refilled ^7Death Machine" );
        else
            self iprintln( "^2[zm_qol] gave ^7Death Machine" );
        return;
    }

    if ( str_arg == "list" || str_arg == "help" || str_arg == "?" )
    {
        self zmqol_give_list_toggle();
        return;
    }

    str_weapon = zmqol_give_resolve( str_arg );

    if ( str_weapon == "" )
    {
        self iprintln( "^1[zm_qol] this map has no weapon called ^7" + str_arg + " ^1- try ^7.give list" );
        return;
    }

    str_base = str_weapon;

    if ( b_pap )
    {
        //  🛑 The registry's own upgrade_name, never a derived string. It is
        //  undefined for equipment and for anything the map registered without
        //  an upgrade, which is the honest answer rather than a missing weapon.
        if ( isdefined( level.zombie_weapons[ str_weapon ].upgrade_name ) )
            str_weapon = level.zombie_weapons[ str_weapon ].upgrade_name;
        else
        {
            self iprintln( "^3[zm_qol] ^7" + str_base + " ^3has no Pack-a-Punched version - giving the base one" );
            b_pap = 0;
        }
    }

    //  🛑 Same reasoning as zmqol_give_wonder_weapon(): weapon_give(), never
    //  giveweapon(). It honours the zombies weapon limit, takes the current gun
    //  when you are at it, gives start ammo, switches and plays the pickup
    //  sound - and for a grenade or a mine it swaps out the one you are already
    //  carrying and updates the player's lethal/tactical slot. That is exactly
    //  what pulling the thing out of the box does, which is the point.
    //  🛑 v2.15.5 - zmqol_give_or_refill(), not weapon_give() raw. This is the
    //  exact call the RPG-7 report came from: `.give rpg` while already holding
    //  the packed Rocket Propelled Grievance left the player carrying both.
    b_refilled = self zmqol_give_or_refill( str_weapon );

    if ( b_refilled )
        self iprintln( "^2[zm_qol] refilled ^7" + str_weapon );
    else if ( b_pap )
        self iprintln( "^2[zm_qol] gave ^7" + str_weapon + " ^5(Pack-a-Punched)" );
    else
        self iprintln( "^2[zm_qol] gave ^7" + str_weapon );
}

// ============================================================================
//  zmqol_toggle_dvar_watch  -  dvar twins for the four player toggles that only
//  had chat commands.                                          (v1.94.0)
//
//  User, 2026-08-14: they want the in-game Settings menu to drive these instead
//  of chat, "so when people now use my mod they don't need to rely on chat
//  commands which get annoying". The menu is LUI and can only write DVARS, so
//  every option it offers needs one - and god / ghost / infinite ammo /
//  infinite sprint were chat-only.
//
//  🛑 FOG AND DEPTH OF FIELD ARE NOT IN HERE ON PURPOSE. `.fog` only ever sets
//  r_fog and DOF is r_dof_enable - both are CLIENT dvars, so the menu writes
//  them directly and a server-side twin would be a pointless extra hop.
//
//  Edge-triggered against the REAL per-player state, never against the dvar's
//  previous value, so the chat command and the menu can never disagree - the
//  same contract as zmqol_fly_dvar_watch() and zmqol_velocity_dvar_watch().
//  Each toggle writes its dvar back, which keeps all three front-ends in sync.
// ============================================================================
zmqol_toggle_dvar_watch()
{
    if ( zmqol_minimal() )
        return;

    self endon( "disconnect" );
    level endon( "game_ended" );

    //  🛑 v1.95.0 - THE NAMES ARE godmode / ghostmode, NOT god / ghost, AND THAT
    //  IS THE WHOLE BUG FROM v1.94.0.
    //
    //  `god` and `ghost` are already owned by zmqol_console_command_names() -
    //  the CHAT-COMMAND channel, which seeds every name in its list to "" and
    //  blanks it again the instant it sees a value. Two systems on one dvar:
    //  the menu wrote god 1, the command watcher consumed it and blanked it,
    //  this watcher then read "" as 0 and switched godmode straight back off.
    //  That is the "[zm_qol] godmode ON / godmode OFF" pair the user
    //  screenshotted, and why the menu row flipped back to DISABLED on exit.
    //
    //  🌟 THE LIVE DVAR DUMP SHOWS IT PLAINLY - `god ""` and `ghost ""` next to
    //  `infammo ""` / `infsprint ""` (the other command-channel names), while
    //  `infinite_ammo "1"` and `infinite_sprint "1"` hold their values. Those
    //  two never collided: the command channel owns `infiniteammo` and
    //  `infinitesprint`, without the underscore. `fly` is the same story and is
    //  deliberately absent from the command list for exactly this reason.
    //
    //  📝 v1.94.0's note claimed the names were collision-checked. They were -
    //  against the engine's 3,210 dvars, which is the wrong list. The collision
    //  was with this mod's own command names.
    //
    //  Neither `godmode` nor `ghostmode` appears anywhere in the dvar dump or in
    //  zmqol_console_command_names(), so both are free.
    //  ------------------------------------------------------------------
    //  🛑 v2.17.24 - god AND ghost RESET AT THE START OF EVERY MATCH.
    //
    //  User, 2026-09-15, on Church: *"the ai is broken right now the zombies
    //  are literally walking into me and like pushing me but they aren't
    //  attacking me"*, and then, on the next boot: *"i don't have ghost on or
    //  anything"*. Both true at once, and this is why.
    //
    //  `.ghost` does setdvar( "ghostmode", "1" ). A dvar lives for the whole
    //  GAME PROCESS, not for the match. The seeding below only ever wrote a
    //  default when the dvar was "", so a 1 from an earlier match survived
    //  every map change - and the loop underneath re-applies it to the new
    //  player entity on the next map, setting self.ignoreme = 1 again.
    //
    //  🛑 SILENTLY. b_first suppresses the "ghost ON" line on the first pass,
    //  which is right for a menu option that was already on and wrong for a
    //  cheat being re-armed behind the player's back. So: load Church, get
    //  ignored by every zombie, and nothing on screen ever mentions ghost.
    //  That is indistinguishable from broken AI, and it was reported as broken
    //  AI - correctly.
    //
    //  A cheat toggle should not outlive the match it was typed in. Clearing
    //  both at match start makes a fresh map always start vanilla; anyone who
    //  wants god or ghost types it again, in the match it applies to. The menu
    //  rows read the same dvars, so they come up OFF to match.
    //
    //  Level-scoped, so it happens once per match and not once per player -
    //  a second player joining must not wipe a toggle the host just set.
    //
    //  📝 infinite_ammo / bottomless_clip / infinite_sprint are deliberately
    //  NOT reset. They are convenience options rather than AI-visible state:
    //  leaving them on surprises nobody and breaks nothing, whereas ghost
    //  silently rewrites how every zombie on the level behaves.
    //  ------------------------------------------------------------------
    //  ------------------------------------------------------------------
    //  🛑 KNOWN, UNFIXED: god/ghost SURVIVE A MAP CHANGE, SILENTLY.
    //
    //  `.ghost` does setdvar( "ghostmode", "1" ). A dvar lives for the whole
    //  GAME PROCESS, not the match, and the seeding below only writes a default
    //  when the dvar is "" - so a 1 from an earlier match survives every map
    //  change, and the loop underneath re-applies it to the new player entity,
    //  setting self.ignoreme = 1 again. b_first suppresses the "ghost ON" line
    //  on that first pass, so nothing on screen ever says why every zombie is
    //  ignoring you. Reported 2026-09-15 as broken AI, which is exactly what it
    //  looks like from the player's chair.
    //
    //  THE FIX IS NOT HERE AND MUST NOT BE PUT HERE. Clearing both dvars once
    //  per match is ~9 lines, and those 9 lines tipped this file over its
    //  compiled-bytecode ceiling: the build that carried them died at load with
    //  `Unresolved external: "getdvarintdefault"` - a function that had worked
    //  for months and had nothing to do with the change. The named symbol is
    //  never the cause. NOTHING NEW GOES IN THIS FILE.
    //
    //  It belongs in its own raw script under scripts\zm\ that installs itself
    //  from its own init(), the way qol_no_mud_slow.gsc does. Until then the
    //  workaround is to type `.ghost` again, or restart the game.
    //  ------------------------------------------------------------------
    if ( getdvar( "godmode" ) == "" )
        setdvar( "godmode", "0" );

    if ( getdvar( "ghostmode" ) == "" )
        setdvar( "ghostmode", "0" );

    if ( getdvar( "infinite_ammo" ) == "" )
        setdvar( "infinite_ammo", "0" );

    //  v2.15.53 - BOTTOMLESS CLIP's own dvar. `bottomless_clip` appears in
    //  neither the engine dvar dump nor zmqol_console_command_names(), so it is
    //  free by the same check the godmode/ghostmode names were cleared by.
    if ( getdvar( "bottomless_clip" ) == "" )
        setdvar( "bottomless_clip", "0" );

    if ( getdvar( "infinite_sprint" ) == "" )
        setdvar( "infinite_sprint", "0" );

    //  v1.95.0 - SILENT FIRST PASS, same rule as the velocity watcher. A config
    //  that already carries infinite_ammo 1 is not a user action taken now, and
    //  announcing it on every spawn is the startup spam the user asked to go.
    b_first = 1;

    for ( ;; )
    {
        //  --- god ---
        b_want = getdvarintdefault( "godmode", 0 );
        b_is = isdefined( self.zmqol_god ) && self.zmqol_god;

        if ( b_want && !b_is )
        {
            self.zmqol_god = 1;
            self enableinvulnerability();
            if ( !b_first )
                self iprintln( "^2[zm_qol] godmode ON" );
        }
        else if ( !b_want && b_is )
        {
            self.zmqol_god = 0;
            self disableinvulnerability();
            if ( !b_first )
                self iprintln( "^1[zm_qol] godmode OFF" );
        }

        //  --- ghost ---
        b_want = getdvarintdefault( "ghostmode", 0 );
        b_is = isdefined( self.zmqol_ghost ) && self.zmqol_ghost;

        if ( b_want && !b_is )
        {
            self.zmqol_ghost = 1;
            self.ignoreme = 1;
            //  v1.95.0 - the chat path threads this and the menu path did not,
            //  so ghost bought from the menu was not re-asserted against stock
            //  code that clears .ignoreme. Both front-ends now do the same work.
            self thread zmqol_ghost_enforce();
            if ( !b_first )
                self iprintln( "^2[zm_qol] ghost ON ^7- zombies ignore you" );
        }
        else if ( !b_want && b_is )
        {
            self.zmqol_ghost = 0;
            self.ignoreme = 0;
            if ( !b_first )
                self iprintln( "^1[zm_qol] ghost OFF ^7- zombies can see you" );
        }

        //  --- infinite ammo ---
        b_want = getdvarintdefault( "infinite_ammo", 0 );
        b_is = isdefined( self.zmqol_infammo ) && self.zmqol_infammo;

        if ( b_want && !b_is )
        {
            self.zmqol_infammo = 1;
            self thread zmqol_infinite_ammo_think();
            if ( !b_first )
                self iprintln( "^2[zm_qol] infinite ammo ON" );
        }
        else if ( !b_want && b_is )
        {
            self.zmqol_infammo = 0;
            self notify( "zmqol_infammo_off" );
            if ( !b_first )
                self iprintln( "^1[zm_qol] infinite ammo OFF" );
        }

        //  --- bottomless clip ---
        b_want = getdvarintdefault( "bottomless_clip", 0 );
        b_is = isdefined( self.zmqol_bclip ) && self.zmqol_bclip;

        if ( b_want && !b_is )
        {
            self.zmqol_bclip = 1;
            self thread zmqol_bottomless_clip_think();
            if ( !b_first )
                self iprintln( "^2[zm_qol] bottomless clip ON" );
        }
        else if ( !b_want && b_is )
        {
            self.zmqol_bclip = 0;
            self notify( "zmqol_bclip_off" );
            if ( !b_first )
                self iprintln( "^1[zm_qol] bottomless clip OFF" );
        }

        //  --- infinite sprint ---
        b_want = getdvarintdefault( "infinite_sprint", 0 );
        b_is = isdefined( self.zmqol_infsprint ) && self.zmqol_infsprint;

        if ( b_want && !b_is )
        {
            self.zmqol_infsprint = 1;
            //  v1.95.0 - was a bare setperk(). The chat path threads
            //  zmqol_infinite_sprint_think(), which is what re-asserts the perk
            //  after stock strips it (down, round change, Stamin-Up purchase).
            //  A one-shot setperk from the menu quietly wore off. Same work now.
            self thread zmqol_infinite_sprint_think();
            if ( !b_first )
                self iprintln( "^2[zm_qol] infinite sprint ON" );
        }
        else if ( !b_want && b_is )
        {
            self.zmqol_infsprint = 0;
            self notify( "zmqol_infsprint_off" );
            self unsetperk( "specialty_unlimitedsprint" );
            if ( !b_first )
                self iprintln( "^1[zm_qol] infinite sprint OFF" );
        }

        b_first = 0;
        wait 0.25;
    }
}

//  give_weapon "<name> [pap]" - the console twin, blanked after every use so a
//  bind can fire it repeatedly. Same shape as the fly / velocity watchers.
zmqol_give_weapon_dvar_watch()
{
    if ( zmqol_minimal() )
        return;

    self endon( "disconnect" );
    level endon( "game_ended" );

    if ( getdvar( "give_weapon" ) == "" )
        setdvar( "give_weapon", "" );

    for ( ;; )
    {
        str_want = getdvar( "give_weapon" );

        if ( isdefined( str_want ) && str_want != "" )
        {
            setdvar( "give_weapon", "" );
            a_parts = strtok( str_want, " " );

            if ( isdefined( a_parts ) && a_parts.size > 0 )
            {
                b_pap = a_parts.size > 1 && ( a_parts[1] == "pap" || a_parts[1] == "packed" || a_parts[1] == "upgraded" );
                self zmqol_give_named_weapon( a_parts[0], b_pap );
            }
        }

        wait 0.25;
    }
}

zmqol_ww_give_dvar_watch()
{
    if ( zmqol_minimal() )
        return;

    self endon( "disconnect" );
    level endon( "game_ended" );

    if ( getdvar( "give_thundergun" ) == "" )
        setdvar( "give_thundergun", "0" );

    if ( getdvar( "give_wunderwaffe" ) == "" )
        setdvar( "give_wunderwaffe", "0" );

    if ( getdvar( "give_wintershowl" ) == "" )
        setdvar( "give_wintershowl", "0" );

    if ( getdvar( "give_wavegun" ) == "" )
        setdvar( "give_wavegun", "0" );

    for ( ;; )
    {
        wait 0.25;

        if ( getdvarintdefault( "give_thundergun", 0 ) )
        {
            setdvar( "give_thundergun", "0" );
            self zmqol_give_wonder_weapon( "thundergun_zm", "2", "Thundergun" );
        }

        if ( getdvarintdefault( "give_wunderwaffe", 0 ) )
        {
            setdvar( "give_wunderwaffe", "0" );
            self zmqol_give_wonder_weapon( "tesla_gun_zm", "3", "Wunderwaffe DG-2" );
        }

        if ( getdvarintdefault( "give_wintershowl", 0 ) )
        {
            setdvar( "give_wintershowl", "0" );
            self zmqol_give_wonder_weapon( "freezegun_zm", "4", "Winter's Howl" );
        }

        if ( getdvarintdefault( "give_wavegun", 0 ) )
        {
            setdvar( "give_wavegun", "0" );
            self zmqol_give_wonder_weapon( "microwavegundw_zm", "5", "Wave Gun" );
        }
    }
}

// ============================================================================
//  BOX WEIGHTING FOR THE THREE WONDER WEAPONS          (v1.75.0)
//
//  User, 2026-08-11: the Wunderwaffe never came out of the box across a whole
//  round-32 game, while the Thundergun and Winter's Howl both did.
//
//  🛑 THERE IS NO ASYMMETRY, AND THAT IS MEASURED. This is NOT a bug fix.
//  All three guns register identically - same include_weapon, same
//  add_limited_weapon( x, 1 ), same add_zombie_weapon weight of 10
//  (thundergun.gsc:36-38, teslagun.gsc:45-47, freeze.gsc:36-44). The
//  2026-08-11 23:32 boot log confirms all three reached the running game:
//  "Loaded weapon: freezegun_zm / tesla_gun_zm / thundergun_zm" and a
//  "GSC Executed ...::init()" for each, with no script error anywhere in the
//  file. And the user pulled two of the three FROM THE BOX in that same game,
//  which proves the path itself works. Neither _zm_weap_tesla.gsc nor either
//  of its two siblings touches the box.
//
//  The real number: this mod's own _zm_magicbox.gsc strips the three stock
//  filters, so treasure_chest_chooseweightedrandomweapon() is a UNIFORM draw
//  over the in-box weapons. TranZit ships 23 of those (zm_transit_dr.gsc,
//  include_weapon calls without in_box=0) plus these 3 = 26. A specific gun is
//  1/26 = 3.8% per spin, so missing it across ~40 spins is (25/26)^40 = 21%.
//  One game in five looks exactly like the user's. Variance, not a defect.
//
//  🌟 SO THIS IS A DELIBERATE WEIGHTING, and it rides TREYARCH'S OWN LIVE HOOK.
//  level.customrandomweaponweights is read by the box at _zm_magicbox.gsc:1039
//  (deliberately KEPT when this project overrode that file) and is the same
//  hook zm_buried.gsc:375 uses. Its contract is fixed by Buried's own
//  implementation (zm_buried.gsc:452): called ON THE PLAYER, takes the
//  randomized key array, returns a key array. Because the box returns the FIRST
//  key that passes its filter, extra copies of a name raise its odds - the same
//  mechanism stock's own dev-only arrayinsert( keys, forced_weapon, 0 ) relies
//  on at _zm_magicbox.gsc:1046.
//
//  📝 NOT level.weapon_weighting_funcs. That array is WRITTEN at
//  _zm_weapons.gsc:704-706 and READ NOWHERE in the 2,093-file stock dump - dead
//  WaW/BO1 legacy. Which is why stock's own default_tesla_weighting_func()
//  (:606), a pity timer written for this exact gun, has never once run in T6.
//
//  🛑 v1.98.0 - THE DIRECTION OF THIS WEIGHTING IS NOW REVERSED, and the dvar
//  above (`zmqol_box_wonder_weight`, default 2, which ADDED entries for unheld
//  wonder weapons from round 10) NO LONGER EXISTS. The user asked for the three
//  ported wonder weapons to be RARE, not boosted. The replacement dvar is
//  `zmqol_box_ww_rarity` (default 4) - see the long note above
//  zmqol_box_wonder_weapon_weights() for the measurements behind it, including
//  the finding that stock BO2 has no box weighting of any kind.
//
//  Everything above about the HOOK is still correct and still the reason this
//  works: level.customrandomweaponweights, called on the player, takes the
//  randomized key array and returns a key array. Only what we do with that
//  array changed - we now REMOVE names instead of appending them.
// ============================================================================
// ============================================================================
//  THE 9 PORTED MULTIPLAYER WEAPONS - BOX REGISTRATION       (v1.89.0)
// ----------------------------------------------------------------------------
//  SWAT-556, FAL OSW, Mk 48, QBB LSW, MP7, Vector K10, MSMC, Peacekeeper and
//  the Crossbow. Their raw defs live in weapons\zm\ (Plutonium loads those
//  straight out of mod.iwd) and their 511 assets are baked into mod.ff. This
//  function is what actually puts them in the box - without it the defs and
//  assets ship and the game is functionally unchanged, which is exactly the
//  state v1.88.0 was in.
//
//  🛑 WHY A ROOT SCRIPT AND NOT SIX added_weapons(). These 9 go on EVERY map,
//  and the three wonder weapons already prove a root-script init() registers a
//  weapon successfully on every map (freeze.gsc:36-44, and the user has pulled
//  them from the box). Six per-map copies would be six places to drift.
//
//  🛑 include_weapon() MUST COME FIRST. add_zombie_weapon() opens with
//      if ( isdefined( level.zombie_include_weapons ) &&
//           !isdefined( level.zombie_include_weapons[weapon_name] ) ) return;
//  (_zm_weapons.gsc:523) - so a missing include_weapon makes the whole
//  registration a SILENT no-op. And struct.is_in_box is read straight from
//  include_weapon's flag (:558), which is why the upgraded halves pass 0: they
//  must exist as weapons but must never be a box result on their own.
//
//  🌟 EVERY VALUE HERE IS TREYARCH'S OR REIMAGINED'S, NOT INVENTED:
//    - the display refs are each def's own displayName field, and all nine were
//      confirmed to already resolve on a zombies map by dumping the localize
//      asset of every en_*.ff a zombies map loads. Only WEAPON_PEACEKEEPER had
//      to be shipped (DLC weapon, its string is in the MP patch zone only).
//    - the costs are BO2-Reimagined's for these same nine weapons.
//    - the vox packs are stock's OWN class mapping from _zm_audio.gsc:123-140:
//      "smg" -> wpck_smg, "assault"/"mg" -> wpck_mg, and - note - stock maps
//      "crossbow" -> wpck_launcher, so the crossbow uses that and not wpck_explo.
//    - the 8th argument is create_vox, NOT an in-box flag. Verified against the
//      real signature, add_zombie_weapon( weapon_name, upgrade_name, hint, cost,
//      weaponvo, weaponvoresp, ammo_cost, create_vox ) at _zm_weapons.gsc:521.
//      Stock passes 1 alongside a wpck_* pack; that is what is copied here.
//
//  📝 THE ATTACHMENT AND PROJECTILE VARIANTS are included with in_box = 0. They
//  are reachable only through Pack-a-Punch attachments or as a projectile, never
//  as a box result, but they must be included or the weapon they belong to
//  cannot resolve them.
//
//  🛑 THE CLIENT TWIN IS zm_expanded.csc::zmqol_mp_weapons_init() AND IT MUST
//  LIST THE SAME WEAPONS. clientscripts _zm_weapons::include_weapon builds
//  level._included_weapons / _display_box_weapons, which drives what the client
//  will draw over the box.
//
//  Bounded and reversible, per the "every feature is also a dvar" rule:
//      zmqol_mp_weapons 0   registers none of them (stock box)
//      zmqol_mp_weapons 1   DEFAULT
// ============================================================================
zmqol_mp_weapons_enabled()
{
    return getdvarintdefault( "zmqol_mp_weapons", 1 );
}

zmqol_mp_weapons_init()
{
    if ( !zmqol_mp_weapons_enabled() )
        return;

    // ========================================================================
    //  🛑 THIS LINE IS THE PACK-A-PUNCH CRASH FIX (v1.89.3). It must run
    //  BEFORE the add_zombie_weapon calls below, because add_zombie_weapon ->
    //  add_attachments() reads this on the way past.
    //
    //  add_attachments() looks the UPGRADED name up in the attachment table and
    //  sets level.zombie_weapons[w].default_attachment from column 1. Every
    //  stock Pack-a-Punched weapon has a row in stock's zm/pap_attach.csv; none
    //  of these nine did, so a packed weapon was built with an attachment set
    //  its def requires and nothing supplied - and firing it froze the game
    //  hard, with the console log simply ending mid-line.
    //
    //  The stock table cannot be overridden (patch_zm.ff owns it - see the
    //  block in zone_source\mod_locations.zone), so mod.ff ships
    //  zm/pap_attach_qol.csv: all 29 stock rows verbatim plus 7 of ours.
    //  Repointing the whole game at it is therefore a no-op for every stock
    //  weapon, which is why this is safe to set unconditionally.
    //
    //  📝 Only 7 rows, not 9: mk48, insas and crossbow have NO `attachments`
    //  field at all on their upgraded defs, exactly like the stock weapons that
    //  are themselves absent from stock's table. Nothing to map.
    // ========================================================================
    level.weapon_attachment_table = "zm/pap_attach_qol.csv";

    // base, upgraded, display ref, cost, vox pack
    zmqol_add_mp_weapon( "sig556_zm",      "sig556_upgraded_zm",      &"WEAPON_SIG556",             1200, "wpck_mg" );
    zmqol_add_mp_weapon( "sa58_zm",        "sa58_upgraded_zm",        &"WEAPON_SA58",               1000, "wpck_mg" );
    zmqol_add_mp_weapon( "mk48_zm",        "mk48_upgraded_zm",        &"WEAPON_MK48",               1000, "wpck_mg" );
    zmqol_add_mp_weapon( "qbb95_zm",       "qbb95_upgraded_zm",       &"WEAPON_QBB95",              1000, "wpck_mg" );
    zmqol_add_mp_weapon( "mp7_zm",         "mp7_upgraded_zm",         &"WEAPON_MP7",                1000, "wpck_smg" );
    zmqol_add_mp_weapon( "vector_zm",      "vector_upgraded_zm",      &"WEAPON_VECTOR",             1200, "wpck_smg" );
    zmqol_add_mp_weapon( "insas_zm",       "insas_upgraded_zm",       &"WEAPON_INSAS",              1000, "wpck_smg" );
    zmqol_add_mp_weapon( "peacekeeper_zm", "peacekeeper_upgraded_zm", &"WEAPON_PEACEKEEPER",        1000, "wpck_smg" );
    zmqol_add_mp_weapon( "crossbow_zm",    "crossbow_upgraded_zm",    &"WEAPON_CROSSBOW_EXPLOSIVE", 1000, "wpck_launcher" );

    //  v1.92.0 - the XPR-50, weapon 10. User request, 2026-08-14.
    //
    //  🌟 The def is `as50_zm` and the art is `xpr50` - see mod_xpr50.zone.
    //
    //  Cost 1000 is BO2-Reimagined's for this weapon, the same source as the
    //  nine above. The vox key is "sniper" and that is STOCK'S OWN, not a
    //  guess: _zm_audio.gsc:130 registers "sniper" -> wpck_sniper, and stock
    //  passes the bare "sniper" for the barretm82 on several maps. There is no
    //  wpck_as50 - the XPR-50 was never a zombies weapon - so a weapon-specific
    //  pack in the shape of wpck_dsr50 / wpck_m82a1 / wpck_svuas cannot exist.
    //
    //  📝 WEAPON_AS50 is NOT shipped in mod.str: it already resolves from
    //  en_patch_zm.ff and en_code_post_gfx_zm.ff. Only the PaP name is ours.
    //  v2.17.37 - the XPR-50 is OFF Origins. It is one of the four pairs the
    //  user gave up to pay for the Black Ops 1 guns; zm_tomb.gsc's banner has
    //  the arithmetic. It is gated here rather than in the map script because
    //  this call is global, and on Origins zmqol_tomb_weapon() would swap it to
    //  the private as50qol copy - zm_tomb.csc drops that twin to match.
    //  No new symbol: isdefined is a builtin and level.script is a variable.
    if ( !isdefined( level.script ) || level.script != "zm_tomb" )
        zmqol_add_mp_weapon( "as50_zm",        "as50_upgraded_zm",        &"WEAPON_AS50",               1000, "sniper" );

    //  v2.9.18 - the campaign SPAS-12, user request 2026-08-31 ("SPAS-12 ...
    //  into the Mystery Box on all Zombie maps ... official BO1 Pack-a-Punch
    //  name"). Same delivery as the Dragunov: raw defs in weapons\zm (so the
    //  def exists on every map and the as50/Origins missing-def class cannot
    //  apply), art from nicaragua.ff via mod_spas.zone, numbers from BO1's own
    //  raw\weapons\sp\spas_zm (clip 8/32, damage 160; SPAZ-24 24/72, 300).
    //  Cost 500 is the Olympia's - stock's other box shotgun of this class -
    //  and "shotgun" is stock's own vox key (the rottweil72 row above uses it).
    //  No pap_attach row needed: the upgraded def ships with NO
    //  attachments field, the mk48/insas/crossbow case.
    //
    //  The gun came out 2026-10-07 (user: "get rid of the Spas 12 and replace
    //  it with the blastomatic") and came back the same day, round 2 of the
    //  gunswap: it takes the stock S12's slots everywhere (saiga12_zm is
    //  banned from registration - gunswap.gsc). The row is verbatim v2.9.18.
    zmqol_add_mp_weapon( "spas_zm",        "spas_upgraded_zm",        &"WEAPON_SPAS",               500, "shotgun" );

    //  v2.9.9 - the campaign Dragunov, weapon 13 (user task 1, 2026-08-30).
    //
    //  A fully separate weapon from the SVU-AS, per the directive: its own
    //  defs (weapons\zm\dragunov_zm / dragunov_upgraded_zm, authored from the
    //  campaign's dragunov_sp on the svu_zm ZM chassis), its own art and anims
    //  (mod_dragunov.zone, donor nicaragua.ff), its own camo
    //  (zone_assets\camo\camo_dragunov.json), its own alias chains in mod.all
    //  (24 rows, every payload already staged), and BO1's real Pack-a-Punch
    //  name ("D115 Disassembler", read from BO1's own string table).
    //
    //  Cost 1000 and vox "sniper" - the identical reasoning to the XPR-50
    //  block above: there is no wpck_dragunov, "sniper" is stock's own class
    //  key, and 1000 matches the other ported snipers.
    zmqol_add_mp_weapon( "dragunov_zm",    "dragunov_upgraded_zm",    &"WEAPON_DRAGUNOV",           1000, "sniper" );

    //  v1.93.0 - the Titus-6, weapon 11 and the last of the port. User request.
    //
    //  🛑 IT IS DUAL-MODE AND THAT CHANGES WHAT GOES IN THE BOX. titus6_zm is
    //  the explosive-dart launcher (inventoryType primary) and its altWeapon is
    //  mk_titus6_zm, the buckshot masterkey (inventoryType altmode). ONLY the
    //  primary may be a box result; the three others are included below as
    //  variants, exactly like the SWAT's grenade launcher. Box the altmode and
    //  the player gets a weapon that cannot switch back.
    //
    //  Cost 1000 and vox "wpck_shotgun": stock maps class "spread" -> shotgun
    //  (_zm_audio.gsc:126) and the masterkey half is spread, which is the half
    //  that reads as a shotgun. The launcher half is class "rifle" but there is
    //  no wpck for a dart launcher in the stock table.
    zmqol_add_mp_weapon( "titus6_zm",      "titus6_upgraded_zm",      &"WEAPON_TITUS6_EXPLOSIVE",   1000, "wpck_shotgun" );

    //  v1.99.13 - the Tac-45, weapon 12. User request, 2026-08-16: "the only
    //  weapon missing" from the multiplayer port.
    //
    //  🌟 The def is `fnp45_zm` and the gun is the Tac-45 - Treyarch shipped it
    //  under its development name, exactly like the XPR-50's `as50`. See
    //  zone_source\mod_tac45.zone.
    //
    //  🛑 IT BECOMES DUAL-WIELD WHEN PACK-A-PUNCHED, so a third def has to be
    //  included below or the upgraded pair cannot resolve each other.
    //
    //  Cost 500 and vox "" are BO2-Reimagined's own values for THIS weapon, read
    //  out of scripts\zm\_zm_reimagined.gsc:2038, not chosen:
    //      add_zombie_weapon("fnp45_zm","fnp45_upgraded_zm",&"WEAPON_FNP45",500,"",...)
    //  The empty vox pack is correct and is not an omission: the pistol class
    //  maps to `wpck_crappy` (_zm_audio.gsc:123) and that alias is in NO zombies
    //  sound bank - dumped zmb_survival_transit, zmb_tomb and zmb_buried and it
    //  is absent from all three - so naming it would be silently nothing. Stock
    //  passes "" for m1911_zm and beretta93r_zm for the same reason.
    //
    //  📝 Reimagined includes it with in_box 0 because there it REPLACES the
    //  starting pistol. Here it goes in the box like the other eleven, which is
    //  what zmqol_add_mp_weapon() does by default.
    zmqol_add_mp_weapon( "fnp45_zm",       "fnp45_upgraded_zm",       &"WEAPON_FNP45",              500,  "" );

    //  v2.12.7 - the campaign STORM PSR, weapon 14. User request, 2026-09-06:
    //  "add the storm psr from the campaign into my mod as another weapon in the
    //  mystery box, the bo2 reimagined mod already does this so just get it from
    //  their".
    //
    //  🌟 The def is `metalstorm_mms` and the gun is the Storm PSR - Treyarch's
    //  development name again, exactly like the XPR-50's `as50` and the Tac-45's
    //  `fnp45`. 🛑 NOT the campaign's Metal Storm DRONE (drone_metalstorm /
    //  metalstorm_gun_turret), which is a vehicle and shares only the word.
    //
    //  🛑 IT IS A FIVE-STAGE CHARGE WEAPON AND THAT DECIDES WHAT GOES IN THE BOX.
    //  Holding fire charges it; each stage is its OWN weapon def, chained by
    //  altWeapon:
    //      metalstorm_mms_zm -> metalstorm2 -> metalstorm3 -> metalstorm4 -> metalstorm5
    //  with damage 1000/2000/3000/4000/5000 (doubled Pack-a-Punched), a bigger
    //  muzzle flash each stage, and tracers mstorm_2 / _3 / _5. ONLY stage one may
    //  be a box result; the other eight defs are included below as variants, the
    //  same shape as the Titus-6's alt-fire half. Box a later stage and the player
    //  starts holding a gun that cannot charge from the beginning.
    //
    //  Cost 1000 and vox "sniper" - the identical reasoning to the XPR-50 and the
    //  Dragunov above: there is no wpck_metalstorm (it was never a zombies gun),
    //  "sniper" is stock's own class key (_zm_audio.gsc:130), and 1000 is what
    //  Reimagined charges for it (_zm_reimagined.gsc:2059) AND what the other
    //  ported snipers cost here.
    //
    //  📝 WEAPON_METALSTORM is NOT shipped in mod.str: it already resolves from
    //  en_code_post_gfx_zm.ff, which loads on every zombies map. Only the
    //  Pack-a-Punch name ("Tempest PTR") is ours. Same as WEAPON_AS50 above.
    //
    //  📝 Reimagined adds it to TranZit ONLY, and as a limited weapon (one per
    //  match). Here it goes in the box on every map like the other thirteen -
    //  which is what zmqol_add_mp_weapon() does - because that is what was asked
    //  for and because every asset it needs now rides in mod.ff, so no map can
    //  be missing a piece of it.
    zmqol_add_mp_weapon( "metalstorm_mms_zm", "metalstorm_mms_upgraded_zm", &"WEAPON_METALSTORM", 1000, "sniper" );

    // ========================================================================
    //  v2.15.0 - THE FOUR BLACK OPS 1 GUNS, weapons 16-19. User request
    //  2026-09-09: *"this mod has a bunch of weapon ports from bo1 that i want
    //  you to port into my mod ... the m60 lmg, the l96, the browning pistol,
    //  the rpg-7"*, from the zm_refreshed build they supplied.
    //
    //  🛑 NAMED EXCEPTION TO HARD RULE 7 (no importing from other mods,
    //  zm_refreshed named explicitly), given by the rule's own author.
    //
    //  Art: zone_source\mod_bo1guns.zone out of zone_source\refreshed_donor\
    //  mod.ff - 121 assets, and the L96's 26 animations are RAW xanims the
    //  Linker reads off disk (they are in no fastfile anywhere). Defs: raw in
    //  weapons\zm\, trimmed 17,392-19,346 B, all under the 20,480 ceiling.
    //
    //  🛑 NO pap_attach_qol.csv ROW FOR ANY OF THE FOUR, and that is deliberate,
    //  not an omission. The v1.89.3 crash was a packed weapon whose def
    //  DECLARES attachments while the table supplies none. m60_upgraded_zm and
    //  browninghp_upgraded_zm arrived with an `attachments` list, so this mod's
    //  copies ship with that field CLEARED - which puts all four in the
    //  mk48 / insas / crossbow class, the one that needs no row at all.
    //
    //  Sounds: the four guns' fire chains are 42 mod-private aliases in
    //  mod.all (wpn_m60_*, t5_l96a1_*, wpn_browninghp_*, wpn_rpg7_*), every one
    //  a name no retail zombies bank carries, so the user's sound pack keeps
    //  authority over everything it owns. 🛑 The RPG's are renamed rpg -> rpg7
    //  for exactly that reason: wpn_rpg_fire_plr IS in five of the six map
    //  banks (all but Origins), so declaring it would shadow the pack there.
    //
    //  Costs and vox packs, each from a source and not chosen:
    //    M60         1100 / "wpck_mg"  - zm_refreshed's own row for this gun,
    //                and stock maps class "mg" -> wpck_mg (_zm_audio.gsc:130).
    //    L96A1       1000 / "sniper"   - the mod's own value for every ported
    //                sniper (XPR-50, Dragunov); "sniper" is stock's class key.
    //    Browning HP  500 / ""         - the Tac-45's reasoning exactly: the
    //                pistol class maps to wpck_crappy, which is in NO zombies
    //                sound bank, so naming it would be silently nothing.
    //    RPG-7         50 / "launcher" - 50 is TREYARCH's own cost for an RPG
    //                in the box (stock zm_buried.gsc:1147, usrpg_zm), and
    //                stock maps class "launcher" -> wpck_launcher, the pack
    //                this mod's crossbow already uses on every map.
    //
    //  📝 Display names: only WEAPON_T5_L96A1 and the three _UPGRADED keys are
    //  shipped in mod.str. WEAPON_M60, WEAPON_BROWNINGHP and WEAPON_RPG already
    //  resolve from en_code_post_gfx_zm.ff, and the packed RPG-7 asks for
    //  ZMWEAPON_USRPG_UPGRADED - "Rocket Propelled Grievance", Treyarch's own
    //  Pack-a-Punch name for an RPG - out of en_patch_zm.ff. Both were dumped
    //  and read, not assumed.
    // ========================================================================
    // ========================================================================
    //  🛑 v2.15.3 - THE FOUR ARE HELD BACK ON ORIGINS. THE MAP DID NOT LOAD.
    //
    //  Boot 2026-09-09 7:27 AM, Crazy Place survival, crash dump
    //  plutonium-r5346-t6zm-2026-09-09_07-27-39.txt:
    //      last gsc error message 'unknown weapon 'm16qol_upgraded_zm''
    //      last gsc pos maps/mp/zombies/_zm_weapons::include_zombie_weapon
    //      gsc callstack: include_zombie_weapon
    //        maps/mp/zombies/_zm_utility::include_weapon
    //        scripts/zm/quality_of_life::zmqol_wallbuy_box_add
    //        scripts/zm/quality_of_life::zmqol_wallbuy_box_init
    //        scripts/zm/quality_of_life::init
    //  "unknown weapon" inside include_zombie_weapon is THE PRECACHE TABLE
    //  RUNNING OUT - the identical signature to the v2.14.0 Crazy Place and
    //  v2.14.6 classic-Origins crashes (see zm_tomb.gsc's added_weapons banner).
    //
    //  🌟 THE ARITHMETIC, MEASURED, NOT ESTIMATED. zmqol_add_mp_weapon()
    //  precaches base + upgraded, so it costs 2 slots per gun. Counted over
    //  this function at both revisions:
    //      ca9208a~1 (pre-BO1 guns)  15 pairs + 19 variants = 49 precacheitem
    //      v2.15.2   (post)          19 pairs + 19 variants = 57 precacheitem
    //  Exactly +8. v2.14.4 froze 14 slots on Origins and recorded that this
    //  "leaves five spare". 8 > 5, so Origins went over the ceiling the moment
    //  the four guns shipped, and the very next precache after the budget was
    //  gone is the one the dump names.
    //
    //  Holding all four back restores the demand to 49 - the exact figure that
    //  booted Origins in console_zm.log .001/.002/.003/.008/.009. Holding only
    //  two back would free 4 and leave a margin of 1, which is not a margin.
    //
    //  ⚠️ WHAT THE PLAYER LOSES, PLAINLY: on Origins - every location, classic
    //  and survival - the box does not offer the M60, the L96A1, the Browning HP
    //  or the RPG-7. All five other maps are untouched. The alternative is a map
    //  that does not load at all. Same trade v2.14.4 made for its seven.
    //
    //  🛑 zm_expanded.csc HOLDS BACK THE SAME FOUR, on the same map test. Its
    //  include_weapon ends in addzombieboxweapon( w, getweaponmodel( w ), ... ),
    //  a model lookup on a weapon nothing precached. Change one list, change
    //  both. .give needs no guard: every give path already tests
    //  isdefined( level.zombie_weapons[...] ) before offering a name.
    // ========================================================================
    // ========================================================================
    //  v2.17.37 - ORIGINS GETS THE L96A1 ONLY, TRADED 1:1 FOR THE XPR-50.
    //  User's call 2026-09-24. The other three stay held back on zm_tomb.
    //
    //  🌟 A PAIR IS NOT A FIXED PRICE. Two boots settled this. v2.17.36 cut 3
    //  pairs for the four guns (net +2) and died on box_init's FIRST precache;
    //  the next build cut 4 pairs for four (net ZERO, by gun count) and still
    //  died - three precaches further in, on rottweil72qol_upgraded_zm. Net
    //  zero by pair count cannot overflow a table unless the incoming guns
    //  cost MORE than the outgoing ones, and console_zm.log says why:
    //
    //      Couldn't find attachmentunique 'au_m60_none' ... _acog, _extclip,
    //      _grip, _reflex, _silencer, _acog+grip, _grip+reflex   (8, M60)
    //      Couldn't find attachmentunique 'au_browninghp_none' ... (3)
    //
    //  The M60 and the Browning HP drag attachment permutations the table pays
    //  for; the L96A1 and the RPG-7 logged none. So "2 slots per gun" is only
    //  true for a gun with no attachment spread - do not budget with it again.
    //
    //  The L96A1 is the cheap one and the one the user asked for by name, and
    //  the XPR-50 it replaces is also a sniper, so the box keeps its shape.
    //  Origins' real headroom stays 0-1 slots; this trade does not touch it.
    //
    //  2026-10-07 ROUND 2 OF THE GUNSWAP CHANGES THE ARITHMETIC, IN THE MOD'S
    //  FAVOUR. The au_* lookups above are from the defs as they shipped THEN;
    //  the mod's m60/browninghp copies now ship with the attachments field
    //  EMPTY (both defs read back attachments:'', the mk48/insas class), so
    //  each is a fixed 2 slots again - measured on the defs, not assumed. And
    //  the same day's swaps freed Origins real slots: the mod-added RPD block
    //  came out of zm_tomb.gsc (-2), the stock HAMR pair is banned (-2), the
    //  stock Five-seveN DW pair is banned (-2). What Origins now pays for, on
    //  every location: the SPAS-12 restored (+2, standing in for the S12 the
    //  box lost at v2.14.4), the M60 (+2, standing in for that RPD), the
    //  Browning HP (+2, standing in for the Five-seveN whose wall buy keeps
    //  its own registration) and the Browning HP Dual Wield (+4: both hands of
    //  both tiers - browninghpdw, its upgrade and the two left-hand halves,
    //  all four defs attachments-cleared; oldschool.gsc's DW gate is now all
    //  six maps). Net +4, 248 -> 252 of 253, ONE slot spare. Derived, not
    //  booted - verify live before adding anything else to this map.
    //
    //  zm_expanded.csc holds back the RPG-7 the same way, on the same map
    //  test, and zm_tomb.csc drops the as50qol twin. Change one list, change
    //  all of them.
    // ========================================================================
    zmqol_add_mp_weapon( "t5_l96a1_zm",    "t5_l96a1_upgraded_zm",    &"WEAPON_T5_L96A1",           1000, "sniper" );

    zmqol_add_mp_weapon( "m60_zm",         "m60_upgraded_zm",         &"WEAPON_M60",                1100, "wpck_mg" );

    //  Round 2 follow-up: gunswap.gsc re-points the stock Origins Five-seveN
    //  wall (zm_tomb.gsc:975) to the Browning HP, and the wall's price comes
    //  from THIS struct (get_weapon_cost). User: same points as the 5.7 wall
    //  charged, so the wall reads 1100 - the box is free, nothing else is
    //  priced by it, and the wall's ammo re-buy is stock's usual half (550).
    //  Everywhere else the Browning HP keeps the Tac-45-reasoned 500.
    if ( level.script == "zm_tomb" )
    {
        zmqol_add_mp_weapon( "browninghp_zm",  "browninghp_upgraded_zm",  &"WEAPON_BROWNINGHP",         1100, "" );
    }
    else
    {
        zmqol_add_mp_weapon( "browninghp_zm",  "browninghp_upgraded_zm",  &"WEAPON_BROWNINGHP",         500,  "" );
    }

    //  Round 2, 2026-10-07: the M60 and the Browning HP are on Origins now.
    //  The RPG-7 stays held back - nothing paid for it there.
    if ( !isdefined( level.script ) || level.script != "zm_tomb" )
    {
        zmqol_add_mp_weapon( "rpg_zm",         "rpg_upgraded_zm",         &"WEAPON_RPG",                50,   "launcher" );
    }


    // Reachable only via a PaP attachment or as a projectile - never a box
    // result, but they must be included or their owner cannot resolve them.
    //  2026-09-27: vector_extclip_zm / _upgraded_zm are no longer included.
    //  Nothing reaches them: the Vector's upgrade is vector_upgraded_zm, no def
    //  names them as altWeapon, and add_attachments() only reads the
    //  pap_attach_qol.csv row of a gun registered with add_zombie_weapon. They
    //  cost a weapon-table slot on every map, and those two slots are what let
    //  the Bloodhound be a starting pistol on every map (scripts\zm\bloodhound.gsc).
    zmqol_include_variant( "gl_sig556_upgraded_zm" );
    zmqol_include_variant( "sf_sa58_upgraded_zm" );
    zmqol_include_variant( "crossbow_explosive_bolt_zm" );
    zmqol_include_variant( "crossbow_explosive_bolt_upgraded_zm" );

    //  The Titus-6's alt-fire half and its two dart projectiles. Never a box
    //  result; reachable only by toggling fire mode or as the fired dart.
    zmqol_include_variant( "mk_titus6_zm" );
    zmqol_include_variant( "mk_titus6_upgraded_zm" );
    zmqol_include_variant( "titus6_explosive_dart_zm" );
    zmqol_include_variant( "titus6_explosive_dart_upgraded_zm" );

    //  The Tac-45's left-hand half. NEVER a box result - it is the off-hand gun
    //  of the Pack-a-Punched pair, inventoryType `dwlefthand`, and
    //  fnp45_upgraded_zm's DualWieldWeapon field names it. Same shape as stock's
    //  m1911lh_upgraded_zm behind Mustang & Sally.
    zmqol_include_variant( "fnp45lh_upgraded_zm" );

    //  The Storm PSR's four later charge stages, base and Pack-a-Punched. NEVER a
    //  box result - the engine swaps the player onto them as the trigger is held
    //  and back down when it is released, through each def's altWeapon field. They
    //  must exist on the level or the chain cannot resolve and the gun stops
    //  charging at stage one.
    zmqol_include_variant( "metalstorm2_mms_zm" );
    zmqol_include_variant( "metalstorm3_mms_zm" );
    zmqol_include_variant( "metalstorm4_mms_zm" );
    zmqol_include_variant( "metalstorm5_mms_zm" );
    zmqol_include_variant( "metalstorm2_mms_upgraded_zm" );
    zmqol_include_variant( "metalstorm3_mms_upgraded_zm" );
    zmqol_include_variant( "metalstorm4_mms_upgraded_zm" );
    zmqol_include_variant( "metalstorm5_mms_upgraded_zm" );

    //  🛑 was a hardcoded "19" that drifted from the real list (old logs print
    //  13 for a 15-pair list). Counted, not asserted - and it is map-dependent
    //  now that Origins holds four back.
    if ( isdefined( level.zombie_weapons ) )
        println( "[zm_qol] mp_weapons: " + level.zombie_weapons.size + " in level.zombie_weapons for the box on " + getdvar( "mapname" ) );
}

// ============================================================================
//  zmqol_wallbuy_box_init  -  WALL-BUY-ONLY GUNS, PUT IN THE MYSTERY BOX
//                                                       (v1.99.56 / v1.99.58)
//
//  User, 2026-08-18: first "the Colt M16A1... you couldn't spin it in the
//  mystery box", then "add the m14 and olympia and the m1911 to the box, the two
//  classic wall weapon buys in first rooms for bo1 and bo2... more the merrier".
//
//  THE WHOLE THING IS ONE ARGUMENT OF TREYARCH'S. Every map registers these
//  guns like this (zm_transit.gsc:1901, :1869, zm_buried.gsc:1195, :1201,
//  zm_highrise.gsc:893, :899 ...):
//
//      include_weapon( "m16_zm", 0 );
//
//  That trailing 0 is the in_box flag, and _zm_weapons.gsc copies it onto the
//  weapon struct as struct.is_in_box when add_zombie_weapon builds it. It is
//  read ONCE, at registration. Nothing else about these guns differs from a box
//  weapon - they already have upgrades, camos, Pack-a-Punch names and full
//  animation sets.
//
//  So on a map that already registered the gun, the whole fix is that one struct
//  field. On a map that never registered it, it is registered here with STOCK'S
//  OWN values - hint, cost and vox copied from the map scripts, never invented:
//
//    m16_zm         &"ZOMBIE_WEAPON_M16"        1200  "burstrifle"  zm_transit:2001
//    rottweil72_zm  &"ZOMBIE_WEAPON_ROTTWEIL72"  500  "shotgun"     zm_buried:1131
//    m1911_zm       &"ZOMBIE_WEAPON_M1911"        50  ""            zm_transit:1985
//
//  THE OLYMPIA IS NOT CALLED "OLYMPIA" - the weapon is rottweil72_zm and its ART
//  is called olympia (t6_wpn_shotty_olympia_view, viewmodel_olympia_*). Its
//  wall-buy effect is literally fx_zmb_wall_buy_olympia (_zm.gsc:1221). That is
//  the def-name-vs-art-name trap: searching the weapon list for "olympia" finds
//  nothing, and searching the art for "rottweil" finds nothing. Both halves are
//  already in mod.ff - 24 xanims, 2 xmodels, 3 materials, 5 images.
//
//  COMPLETENESS AUDIT, run before a line was written, because the user asked
//  specifically after the Titus and SWAT both shipped missing sounds:
//
//    models/anims  all three are declared in mod_base.zone as `weapon` assets
//                  with their art - which is why they already work as wall buys
//                  on every map this mod loads. m1911 carries 88 asset lines,
//                  the Olympia 34, the M16 79.
//    sound         each def's aliases enumerated BY VALUE, not guessed: 17 for
//                  the Olympia, 17 for the M1911, 17 for the M16. In every case
//                  16 are already in mod.all and the 17th is wpn_melee_hit, the
//                  universal melee alias shared by 18 of the 86 shipped defs.
//                  The M16 shipped on exactly this basis in v1.99.56 and the
//                  user confirmed it in game, which is the proof the reading is
//                  right rather than merely plausible.
//    Pack-a-Punch  every upgraded def here has an EMPTY attachments field, so
//                  none needs a row in zm/pap_attach_qol.csv. Same reason
//                  mk48/insas/crossbow need none, and why these cannot hit the
//                  v1.89.3 Pack-a-Punch freeze.
//    strings       ZOMBIE_WEAPON_M16 / _ROTTWEIL72 / _M1911 and their _UPGRADED
//                  twins all live in en_patch_zm.ff, which EVERY zombies map
//                  loads - confirmed with Unlinker --list, not assumed.
//    no regression the wall buys are untouched: on a map that already registered
//                  the gun only is_in_box changes, so cost, hint and vox stay
//                  exactly as the map set them.
//
//  🛑🛑 v1.99.91 - THE M14 PARAGRAPH BELOW IS WRONG AND THE M14 IS NOW SHIPPED.
//  It is kept because the reasoning error is worth seeing. It concluded "this
//  mod ships no m14 def and no m14 art, so this is an asset job" - true about
//  mod.ff, and irrelevant, because the M14 never needed to come from mod.ff.
//  EVERY zombies map registers it itself, measured in the stock dump:
//      zm_transit.gsc:1999  zm_transit_dr.gsc:706  zm_nuked.gsc:876
//      zm_highrise.gsc:834  zm_buried.gsc:1134     zm_prison.gsc:778
//      zm_tomb.gsc:1006     - each followed by include_weapon( "m14_zm", 0 )
//  add_zombie_weapon has already built the struct and the map's own fastfile has
//  already loaded the def, the models and the anims - which is exactly the case
//  zmqol_wallbuy_box_add() handles by flipping is_in_box and returning. The gun
//  is a working wall buy on every map today; the ONLY thing that kept it out of
//  the box was that trailing 0. The add_zombie_weapon fallback in that function
//  is therefore unreachable for the M14 on every shipping map, and its stock
//  values (m14_upgraded_zm, &"ZOMBIE_WEAPON_M14", 500, "rifle") are passed
//  anyway so the call is correct if a future map ever omits it.
//
//  The paragraph as written in v1.99.58:
//  THE M14 IS DELIBERATELY NOT HERE, AND THE USER DID ASK FOR IT. m14_zm is a
//  real BO2 weapon (_zm.gsc:1218 registers its wall-buy fx; Buried and Die Rise
//  register the gun), but this mod ships NO m14 weapon def and NO m14 art -
//  there is no `weapon,m14_zm` row in mod_base.zone and no m14 xmodel or xanim
//  anywhere in it. Adding it is an ASSET job - dumping the def and its animation
//  set out of a stock fastfile and shipping them in mod.ff - not a registration
//  one, and it carries the asset-ownership risk that has broken maps before. It
//  is queued as its own item rather than half-done here.
//
//  Bounded and reversible:
//      zmqol_wallbuy_box 0   leave every gun exactly as the map shipped it
//      zmqol_wallbuy_box 1   DEFAULT
//  v1.99.56 called this dvar zmqol_m16_box. Renamed with the feature one version
//  later: it is console-only, never appeared in a menu, and so was never archived
//  into anyone's config - the rule about never renaming a menu row's dvar does
//  not apply here.
//  THE CLIENT TWIN is zm_expanded.csc::zmqol_wallbuy_box_init() and it must list
//  the SAME weapons - the client's include_weapon builds
//  level._display_box_weapons, which is what draws the gun over the box.
// ============================================================================
zmqol_wallbuy_box_enabled()
{
    return getdvarintdefault( "zmqol_wallbuy_box", 1 );
}

zmqol_wallbuy_box_names()
{
    a = [];
    a[a.size] = "m16_zm";
    a[a.size] = "m1911_zm";
    //  🛑 v2.17.31 - THE OLYMPIA AND THE M14 ARE OUT OF THIS LIST, and out of
    //  the box. User, 2026-09-21: *"remove the olympia and m14 from the mystery
    //  box ... all maps, no m14, no olympia."* They were added at the same
    //  user's request (v1.99.58 / v1.99.91), so both halves of the decision are
    //  theirs and the banner above is kept as the record of the first one.
    //
    //  This list only drives the re-assert below, which forces a gun back INTO
    //  the box - so removing the two names is necessary and not sufficient.
    //  zmqol_wallbuy_box_add() still runs for them (see the call site) and
    //  still sets the flag at init; what actually holds them out is
    //  scripts\zm\boxfix.gsc, a separate script because this file is on its
    //  compiled-bytecode ceiling and the four lines would not fit. Read the
    //  banner at the top of boxfix.gsc before changing either end.
    return a;
}

zmqol_wallbuy_box_init()
{
    if ( !zmqol_wallbuy_box_enabled() )
        return;

    //  base, upgraded, hint, cost, vox - every value is the map script's own.
    zmqol_wallbuy_box_add( "m16_zm",        "m16_gl_upgraded_zm",     &"ZOMBIE_WEAPON_M16",        1200, "burstrifle" );
    zmqol_wallbuy_box_add( "rottweil72_zm", "rottweil72_upgraded_zm", &"ZOMBIE_WEAPON_ROTTWEIL72",  500, "shotgun" );
    zmqol_wallbuy_box_add( "m1911_zm",      "m1911_upgraded_zm",      &"ZOMBIE_WEAPON_M1911",        50, "" );
    zmqol_wallbuy_box_add( "m14_zm",        "m14_upgraded_zm",        &"ZOMBIE_WEAPON_M14",         500, "rifle" );

    //  Alt-weapon halves. NEVER a box result - the M16's grenade launcher and
    //  Mustang & Sally's left-hand gun - but they must resolve or the weapon
    //  that names them cannot be built.
    zmqol_include_variant( "gl_m16_upgraded_zm" );
    zmqol_include_variant( "m1911lh_upgraded_zm" );
}

zmqol_wallbuy_box_add( str_base, str_upgraded, str_hint, n_cost, str_vox )
{
    //  v2.9.1 - Origins uses its private M16 / Olympia. Without this the stock
    //  pair would be registered here on Origins as well, and their aliases no
    //  longer exist there, so the box would hand out two silent guns beside the
    //  audible ones. See zmqol_tomb_weapon().
    str_base     = zmqol_tomb_weapon( str_base );
    str_upgraded = zmqol_tomb_weapon( str_upgraded );

    precacheitem( str_base );
    precacheitem( str_upgraded );

    include_weapon( str_base );          // in_box defaults to 1
    include_weapon( str_upgraded, 0 );

    //  The map already built the struct, so only the box flag changes.
    if ( isdefined( level.zombie_weapons ) && isdefined( level.zombie_weapons[ str_base ] ) )
    {
        level.zombie_weapons[ str_base ].is_in_box = 1;
        return;
    }

    //  Not registered on this map: register it the way stock does.
    add_zombie_weapon( str_base, str_upgraded, str_hint, n_cost, str_vox, "", undefined );
}

// ----------------------------------------------------------------------------
//  THE ONE SILENT-FAILURE MODE THIS FEATURE HAS, CLOSED.
//
//  zmqol_wallbuy_box_init() assumes it runs AFTER the map's own weapon
//  registration. That assumption is well founded - zmqol_box_wonder_weapon_
//  weights_init() already depends on it to chain Buried's
//  level.customrandomweaponweights - but if it were ever wrong the consequence is
//  INVISIBLE: our add_zombie_weapon would run first, the map's would rebuild the
//  struct from its own include_weapon( name, 0 ), and the gun would quietly go
//  back to wall-buy-only with nothing logged.
//
//  So the flag is re-asserted once, a frame later, by which point every map's
//  init has certainly run. Safe to do late: the box picks per spin -
//  treasure_chest_chooseweightedrandomweapon (_zm_magicbox.gsc:911) is a flat
//  array_randomize over the in-box weapons, rebuilt on every use - so nothing
//  has snapshotted the list at init time.
// ----------------------------------------------------------------------------
zmqol_wallbuy_box_reassert()
{
    level endon( "end_game" );

    wait 0.05;

    if ( !zmqol_wallbuy_box_enabled() )
        return;

    if ( !isdefined( level.zombie_weapons ) )
        return;

    a_names = zmqol_wallbuy_box_names();

    for ( i = 0; i < a_names.size; i++ )
    {
        //  v2.9.1 - on Origins the registered name is the private copy, so the
        //  re-assert has to look for that one or it silently does nothing.
        str_w = zmqol_tomb_weapon( a_names[i] );

        if ( isdefined( level.zombie_weapons[ str_w ] ) && !level.zombie_weapons[ str_w ].is_in_box )
        {
            level.zombie_include_weapons[ str_w ] = 1;
            level.zombie_weapons[ str_w ].is_in_box = 1;
            println( "[zm_qol] wallbuy box: re-asserted " + str_w + " on " + getdvar( "mapname" ) );
        }
    }
}

// ============================================================================
//  zmqol_tomb_weapon  -  ORIGINS GETS PRIVATE COPIES OF NINE GUNS    (v2.9.1)
// ----------------------------------------------------------------------------
//  User, 2026-08-30: *"the mp5 no longer uses the custom sounds from the zone
//  folder ... make sure that all the custom sounds from the sound pack work,
//  all of them with no exceptions, without causing any other sounds from the
//  base game to go silent"* - then, asked how Origins should be handled:
//  *"make the sounds work for all maps origins included, don't remove them
//  from the box."*
//
//  THE BIND, measured. Nine guns - MP5, Olympia, M16, XPR-50, Barrett, Judge,
//  S12, Saritch, MTAR - have their aliases declared by SEVEN of the eight map
//  banks. Origins' bank declares ZERO of them, because retail never puts those
//  guns on Origins. So:
//      declare them in mod.all  -> audible on Origins, but mod.all loads first
//                                  and shadows the user's pack on the other 7
//      do not declare them      -> the pack wins on 7, silent on Origins
//  v2.8.8 took the first branch and that is exactly the regression reported.
//
//  🌟 THE WAY OUT IS TO STOP SHARING THE NAME. Origins now gets its own copies
//  of the nine defs - mp5kqol_zm, rottweil72qol_zm, ... - identical to the
//  originals except that their two fire-sound fields point at wpn_<gun>qol_*.
//  mod.all declares only those private names, which no stock bank uses, so it
//  shadows nothing anywhere. On the other seven maps the stock def and the
//  stock alias are untouched and the pack serves them again.
//
//  🛑 THE ONE THING THIS CANNOT FIX, stated rather than hidden: the reload and
//  cocking foley (fly_<gun>_*) is named by the XANIM notetracks, not by the
//  weapon file - the defs' notetrackSoundMap is empty, verified on mp5k_zm. A
//  private weapon cannot redirect a shared animation, so those 50 foley rows
//  stay under their stock names and stay mod-supplied on every map. Only the
//  111 fire-chain names moved.
//
//  🛑 SERVER ONLY. level.script is used 30 times in this file and never once in
//  any stock .csc - the client half is done in zm_tomb.csc, which only ever
//  loads on Origins and so needs no map test at all.
// ============================================================================
zmqol_tomb_weapon( str_name )
{
    if ( !isdefined( level.script ) || level.script != "zm_tomb" )
        return str_name;

    if ( str_name == "as50_zm" )                return "as50qol_zm";
    if ( str_name == "as50_upgraded_zm" )       return "as50qol_upgraded_zm";
    if ( str_name == "m16_zm" )                 return "m16qol_zm";
    if ( str_name == "m16_gl_upgraded_zm" )     return "m16qol_upgraded_zm";
    if ( str_name == "rottweil72_zm" )          return "rottweil72qol_zm";
    if ( str_name == "rottweil72_upgraded_zm" ) return "rottweil72qol_upgraded_zm";

    return str_name;
}

zmqol_add_mp_weapon( str_base, str_upgraded, str_hint, n_cost, str_vox )
{
    //  Origins swaps in its private copies; every other map is unchanged.
    str_base     = zmqol_tomb_weapon( str_base );
    str_upgraded = zmqol_tomb_weapon( str_upgraded );

    precacheitem( str_base );
    precacheitem( str_upgraded );

    include_weapon( str_base );          // in_box defaults to 1
    include_weapon( str_upgraded, 0 );   // exists, but never a box result

    add_zombie_weapon( str_base, str_upgraded, str_hint, n_cost, str_vox, "", undefined, 1 );
}

zmqol_include_variant( str_weapon )
{
    precacheitem( str_weapon );
    include_weapon( str_weapon, 0 );
}

// ============================================================================
//  get_nonalternate_weapon  -  THE STORM PSR'S FIVE CHARGE STAGES MUST REPORT
//                              AS ONE GUN                              v2.12.7
// ----------------------------------------------------------------------------
//  Stock (_zm_weapons.gsc:189) maps an alt-mode weapon back to its primary. It
//  cannot cope with the Storm PSR, and the reason is measured rather than
//  assumed:
//
//    * is_alt_weapon() (_zm_utility.gsc:3208) returns true ONLY for names
//      starting "gl_", "sf_" or "dualoptic_". Every metalstorm stage is
//      inventoryType `primary`, so stock returns the name UNCHANGED.
//    * and the generic path could not fix it anyway: the stages are chained
//      by altWeapon, so weaponaltweaponname("metalstorm3_mms_zm") answers
//      "metalstorm4_mms_zm" - the NEXT stage up, not the base gun.
//
//  Callers that then get the wrong answer are stock's own:
//      maps\mp\zombies\_zm_perks.gsc:429            the perk / Mule Kick path
//      maps\mp\zombies\_zm_weapon_locker.gsc:110,127  Buried, Die Rise, TranZit
//  A player who reaches one of those while the gun is part-charged would have
//  a stage-three def stored or handed back - a weapon registered with in_box 0
//  that was never meant to be held on its own.
//
//  🌟 THE FIX IS BO2-REIMAGINED'S, line for line (_zm_weapons.gsc:1236): collapse
//  any metalstorm name to stage one, keeping the upgraded/base distinction. The
//  rest of this function is stock's body, unchanged, so every other weapon in
//  the game behaves exactly as it did.
// ============================================================================
zmqol_get_nonalternate_weapon( altweapon )
{
    //  Reimagined's rule, first: any charge stage answers as stage one.
    if ( isdefined( altweapon ) && issubstr( altweapon, "metalstorm" ) )
    {
        if ( issubstr( altweapon, "upgraded" ) )
            return "metalstorm_mms_upgraded_zm";

        return "metalstorm_mms_zm";
    }

    //  --- from here down this is stock's own body, copied verbatim ---
    if ( maps\mp\zombies\_zm_utility::is_alt_weapon( altweapon ) )
    {
        alt = weaponaltweaponname( altweapon );

        if ( alt == "none" )
        {
            primaryweapons = self getweaponslistprimaries();
            alt = primaryweapons[0];

            foreach ( weapon in primaryweapons )
            {
                if ( weaponaltweaponname( weapon ) == altweapon )
                {
                    alt = weapon;
                    break;
                }
            }
        }

        return alt;
    }

    return altweapon;
}

zmqol_box_wonder_weapon_weights_init()
{
    // Chain, never clobber. Buried assigns this same pointer (zm_buried.gsc:375);
    // its implementation is a no-op stub that returns keys unchanged, so chaining
    // costs nothing there - but re-pointing without chaining would be CLAUDE.md
    // section 4 failure mode 2.
    if ( isdefined( level.customrandomweaponweights ) )
        level.zmqol_prev_box_weights = level.customrandomweaponweights;

    level.customrandomweaponweights = ::zmqol_box_wonder_weapon_weights;
}

// ============================================================================
//  🛑 v1.98.0 - THIS FUNCTION IS INVERTED. IT USED TO MAKE THE THREE WONDER
//  WEAPONS **MORE** COMMON; IT NOW MAKES THEM RARER.
//
//  User, 2026-08-16: *"make the 3 wonder weapon ports have the same chance to
//  obtain from the mystery box as the raygun mark 2, which is a lot lower than
//  other weapons, and any other weapons like standard assault rifles etc. have
//  standard chances to get like any existing box weapon."*
//
//  🌟 FIRST, THE MEASURED FACT, BECAUSE IT CHANGES THE ANSWER: **BO2 DOES NOT
//  GIVE THE RAY GUN MARK 2 A LOWER BOX CHANCE.** There is no weighting in the
//  game at all. Checked, not assumed:
//    - `treasure_chest_chooseweightedrandomweapon` (_zm_magicbox.gsc:911) is a
//      flat `array_randomize` over every in-box weapon, then the first one that
//      passes the filter. Stock's copy and this mod's copy are identical here.
//    - `level.customrandomweaponweights` is the only weighting hook, and the
//      ONE stock map that sets it (zm_buried.gsc:375) points it at
//      `buried_custom_weapon_weights( keys ) { return keys; }` - a no-op stub.
//    - `add_limited_weapon( "raygun_mark2_zm", 4 )` is a per-PLAYER quota of 4,
//      which never binds in a 4-player game and never in solo. The guns that
//      really are capped are the map wonder weapons - Paralyzer and Sliquifier
//      are `add_limited_weapon( x, 1 )`.
//    - `special_weapon_magicbox_check` only stops Ray Gun and Mark 2 dropping
//      for the same player; it is mutual exclusion, not rarity.
//  So "the same chance as the Mark 2" and "a lot lower than other weapons" are
//  two different requests. This implements the SECOND one, because that is what
//  was described - and `zmqol_box_ww_rarity 1` gives the first one exactly.
//
//  📝 WHAT WAS ACTIVELY WRONG BEFORE. The old default was
//  `zmqol_box_wonder_weight 2`, which appended two extra entries per unheld
//  wonder weapon from round 10 - the exact opposite of what the user wants, and
//  on by default. That behaviour is gone, not merely re-tuned.
//
//  HOW THE THINNING WORKS. The box returns the FIRST key that passes its filter
//  from a shuffled list, so a name's chance is its share of the list. Deleting a
//  name from the shuffled copy on most spins scales its chance down by exactly
//  that fraction, and touches nothing else:
//
//      zmqol_box_ww_rarity 1   same chance as any other gun (= the real Mark 2)
//      zmqol_box_ww_rarity 4   DEFAULT - a quarter as likely as an ordinary gun
//      zmqol_box_ww_rarity 0   never from the box (.thundergun etc. still work)
//
//  🌟 THE ORDINARY GUNS ARE NOT TOUCHED AT ALL. Only the three names below are
//  ever removed, so every other weapon - stock or ported - keeps precisely the
//  share it has today. That is the "standard chances" half of the request, and
//  it is satisfied by doing nothing rather than by a second adjustment.
//
//  📝 THE REAL REASON A SPECIFIC GUN IS HARD TO GET, and it is not a defect:
//  the box now holds roughly 75 in-box names per map (stock's ~40, plus the
//  cross-map additions, plus 11 ported MP guns, plus these 3). A named gun is
//  ~1.3% per spin, so missing one across a 40-spin game is ~59% likely. Nothing
//  is replaced - that was audited name by name for v1.98.0 and only ONE name on
//  ONE map is re-registered at all (qcw05_zm on Buried, which the mod re-adds
//  WITH an upgrade because stock leaves its upgrade undefined).
// ============================================================================
zmqol_box_wonder_weapon_weights( keys )
{
    // self = the player pulling the box. The box calls this as
    //     keys = player [[ level.customrandomweaponweights ]]( keys );
    if ( isdefined( level.zmqol_prev_box_weights ) )
        keys = self [[ level.zmqol_prev_box_weights ]]( keys );

    n_rarity = getdvarintdefault( "zmqol_box_ww_rarity", 4 );

    // 1 = no change at all, which is stock's own uniform behaviour.
    if ( n_rarity == 1 )
        return keys;

    if ( n_rarity < 0 )
        n_rarity = 0;

    guns = [];
    guns[ guns.size ] = "tesla_gun_zm";
    guns[ guns.size ] = "thundergun_zm";
    guns[ guns.size ] = "freezegun_zm";
    guns[ guns.size ] = "microwavegundw_zm";   // v2.10.14 - the Wave Gun's box entry

    a_out = [];

    for ( i = 0; i < keys.size; i++ )
    {
        b_thin = 0;

        for ( j = 0; j < guns.size; j++ )
        {
            if ( keys[i] != guns[j] )
                continue;

            // 0 = never. Otherwise keep it on 1 spin in n_rarity.
            if ( n_rarity == 0 || randomint( n_rarity ) != 0 )
                b_thin = 1;

            break;
        }

        if ( !b_thin )
            a_out[ a_out.size ] = keys[i];
    }

    // 🛑 NEVER HAND BACK AN EMPTY LIST. treasure_chest_chooseweightedrandomweapon
    // falls through to `return keys[0]` when nothing passes its filter, and on an
    // empty array that is undefined - which would be a script error inside the
    // box on a map where the only in-box names were the three wonder weapons.
    // Cannot happen in practice; costs one comparison to make impossible.
    if ( a_out.size == 0 )
        return keys;

    return a_out;
}

// ============================================================================
//  NO BOX LIMITS REACHES THE PORTED WONDER WEAPONS         (v2.9.15)
// ----------------------------------------------------------------------------
//  User, 2026-08-31: *"Ensure the 'No Box Limits' setting applies to the ported
//  BO1 Wonder Weapons. When enabled, remove the 1-per-match restriction for
//  these weapons, allowing multiple players to pull the same Wonder Weapon
//  simultaneously and allowing players to pull it from the box again to refill
//  ammo."*
//
//  🌟 WHAT THE CAP ACTUALLY IS, traced rather than assumed. Each ported gun
//  registers `add_limited_weapon( <gun>, 1 )` in its own init (thundergun.gsc:37,
//  teslagun.gsc:46, freeze.gsc:37), which writes level.limited_weapons[<gun>] = 1.
//  Exactly two things in the stock tree read that table:
//     _zm_weapons::limited_weapon_below_quota()   the quota itself - the magic
//         box (_zm_magicbox.gsc:893) and the four buildable-bench call sites in
//         _zm_buildables.gsc (:1723, :2033, :2060, :2093).
//     _zm_utility::is_limited_weapon()            the weapon locker / fridge on
//         TranZit, Die Rise and Buried, which refuses to store a limited weapon.
//         📝 That one does NOT consult the switch below - it reads the table
//         directly - so the fridge still refuses these guns. Out of scope here;
//         written down so nobody re-derives it.
//
//  🌟 AND STOCK SHIPS THE SWITCH ITSELF. limited_weapon_below_quota() opens
//  with `if ( is_true( level.no_limited_weapons ) ) return false;`
//  (_zm_weapons.gsc:737) - a global kill switch for every quota check that no
//  stock map ever sets. Mirroring the row into it is therefore not an invention
//  and cannot desync from the box: it is the game's own supported way to say
//  "no quotas", and it covers every caller at once.
//
//  📝 THE BOX PATH WAS ALREADY CORRECT, and this is deliberately additive.
//  This mod's _zm_magicbox.gsc override already skips has_weapon_or_upgrade,
//  limited_weapon_below_quota and special_weapon_magicbox_check whenever the row
//  is on, so a second player could already pull the same wonder weapon and a
//  re-pull already refilled it (stock weapon_give() gives start ammo to a weapon
//  you already hold, _zm_weapons.gsc:744). What this adds is that the SAME row
//  now also governs every other quota reader, so the answer cannot differ
//  depending on which door the weapon came through.
//
//  🛑 WHAT THIS DOES CHANGE BEYOND THE BOX, said plainly: with the row on,
//  the buildable benches (Sliquifier, Paralyzer, Jet Gun) also stop enforcing
//  their one-per-match quota. That is the same sentence as the row's name read
//  literally, and it is reversible from the console with `no_box_limits 0`.
//
//  Watched, not read once, so the row is live like every other GAME-tab row.
// ============================================================================
zmqol_no_limited_weapons_watch()
{
    level endon( "end_game" );

    b_last = -1;

    for ( ;; )
    {
        b_want = getdvarintdefault( "no_box_limits", 1 );

        if ( b_want != b_last )
        {
            b_last = b_want;
            level.no_limited_weapons = b_want;
            println( "[zm_qol] no_box_limits -> level.no_limited_weapons = " + b_want );
        }

        wait 1;
    }
}

// ============================================================================
//  TAP TO INTERACT                                          (v2.9.15 / v2.9.33)
//  CONTROLS > GAMEPAD, right under AIM ASSIST
// ----------------------------------------------------------------------------
//  User, 2026-08-31: *"Add a 'Tap to Interact' toggle option to the in-game UI
//  under Options > Controls > Gamepad tab."*
//
//  🛑 v2.9.33 - THE SERVER HALF IS GONE; THIS SECTION IS NOW ONLY THE RECORD
//  OF WHY. The first cut (v2.9.15) set g_useholdtime, named out of `BO2
//  Detailed DVARS.txt:1750`. The v2.9.31 boot disproved that doc for this
//  build three ways: the shipped probe printed "not a registered dvar" on all
//  4 map loads, the live 3,153-dvar dump has no such name, and t6zm.exe's
//  strings carry g_useholdspawndelay but no useholdtime in any case - Treyarch
//  removed the knob after T5. Classic "the API exists ≠ the API applies here".
//
//  The working mechanism (user's own find, a Buried high-rounds video) is two
//  client-side binds that split the pad's combined use/reload button across
//  the engine's two bind slots. Client code applies them the moment the toggle
//  row changes - see ui\t6\menus\optionssettings.lua, which carries the full
//  verification (bind2/unbind2/+activate present in t6zm.exe, stock's own
//  bind2 usage, per-mod bindings file scoping). Nothing server-side to do:
//  binds are client console state GSC cannot touch.
// ============================================================================
//  STRANDED-ZOMBIE PROBE                                 (v1.75.0)
//
//  User, 2026-08-11: "a spawn point near the diner strands the last zombie of a
//  round" - .where x -6269 y -7206 z -63 yaw 236, the ground behind the car.
//
//  🛑 I COULD NOT NAME THE SPAWNER OFFLINE, so this ships a MEASUREMENT rather
//  than a guessed fix (CLAUDE.md: "ship a probe that distinguishes the outcomes
//  rather than a fix built on the likeliest one"). What was ruled out, each from
//  a file actually read:
//
//    1. It is not one of the 8 spawners already disabled. All 8 origins were
//       matched against the zm_transit mapents dump and every one is real, and
//       "[zm_qol] diner main: DONE" is present in the boot log AFTER
//       disable_zombie_spawn_locations() runs - so the pass completed without
//       erroring and the disables applied.
//    2. Nothing re-enables them. _zm_zonemgr::reinit_zone_spawners() DOES force
//       is_enabled = 1 on every unblocked spot (:357-360), but it is called
//       NOWHERE in the 2,093-file stock dump - dead code. zone_init() returns
//       early on an already-initialised zone (:168), so it cannot re-run either.
//    3. No enabled regular spawner is anywhere near the reported spot. Every
//       *_spawners struct in the Diner-area zones was dumped and classified; the
//       nearest ENABLED one is (-5718,-7272,-64), 555 units away. The nearest
//       spawner of any kind is (-6462,-7159,-64) at 198 units - already off.
//    4. It is not the undefined-entrance-node path at _zm_spawner.gsc:411-425.
//       That branch would assign an undefined node (zm_transit has 38
//       exterior_goal structs and ZERO with script_string "find_flesh"), but
//       should_skip_teardown() returns true for exactly that string at :330, so
//       the :383 branch is taken and RETURNS at :409 first. It never runs.
//
//  So the zombie is very likely standing where it was BLOCKED rather than where
//  it spawned, and only its own spawn_point can identify the source.
//
//  🌟 self.spawn_point is assigned in exactly ONE place in stock -
//  _zm_spawner.gsc:2674, "self.spawn_point = spot" - so every zombie carries the
//  struct that produced it. Printing that names the offending spawner outright,
//  and the fix is then the same one-line origin match the other 8 use.
//
//      zmqol_stranded_probe 1   DEFAULT - report, costs one 5s loop
//      zmqol_stranded_probe 0   off
//
//  📝 Deliberately cheap, because frametimes are an open complaint: it wakes
//  every 5 seconds, does nothing at all unless 3 or fewer enemies are alive
//  (the reported symptom is the LAST zombie), and prints once per zombie.
// ============================================================================
zmqol_stranded_zombie_probe()
{
    level endon( "game_ended" );

    for ( ;; )
    {
        wait 5;

        if ( !getdvarintdefault( "zmqol_stranded_probe", 1 ) )
            continue;

        a_enemies = get_round_enemy_array();

        // Only the tail of a round is interesting, and this keeps the probe
        // silent (and free) for the other 99% of a match.
        if ( a_enemies.size == 0 || a_enemies.size > 3 )
            continue;

        for ( i = 0; i < a_enemies.size; i++ )
        {
            ai = a_enemies[i];

            if ( !isdefined( ai ) || !isalive( ai ) )
                continue;

            if ( !isdefined( ai.zmqol_probe_org ) )
            {
                ai.zmqol_probe_org = ai.origin;
                ai.zmqol_probe_ticks = 0;
                continue;
            }

            // 64 units in 5 seconds is far below a walker's pace, so anything
            // under it is genuinely not making progress.
            if ( distancesquared( ai.origin, ai.zmqol_probe_org ) > 4096 )
            {
                ai.zmqol_probe_org = ai.origin;
                ai.zmqol_probe_ticks = 0;
                continue;
            }

            ai.zmqol_probe_ticks++;

            // Exactly 3 - "!= 3" rather than ">= 3" makes this print ONCE per
            // zombie instead of every 5s for the rest of the round.
            if ( ai.zmqol_probe_ticks != 3 )
                continue;

            str_spawn = "none";

            if ( isdefined( ai.spawn_point ) && isdefined( ai.spawn_point.origin ) )
            {
                v_sp = ai.spawn_point.origin;
                str_spawn = "(" + int( v_sp[0] ) + "," + int( v_sp[1] ) + "," + int( v_sp[2] ) + ")";

                if ( isdefined( ai.spawn_point.targetname ) )
                    str_spawn = str_spawn + " tn=" + ai.spawn_point.targetname;

                if ( isdefined( ai.spawn_point.script_noteworthy ) )
                    str_spawn = str_spawn + " nw=" + ai.spawn_point.script_noteworthy;

                if ( isdefined( ai.spawn_point.zone_name ) )
                    str_spawn = str_spawn + " zone=" + ai.spawn_point.zone_name;
            }

            v_at = ai.origin;
            str_at = "(" + int( v_at[0] ) + "," + int( v_at[1] ) + "," + int( v_at[2] ) + ")";

            //  🛑 LOG ONLY, NEVER ON SCREEN. User, 2026-08-12: "don't show the
            //  zombie spawn on the chat or whatever". The v1.75.0 version also
            //  iprintln'd this to every player, which put diagnostic text in the
            //  middle of a normal game. println() still reaches console_zm.log,
            //  which is where it gets read from anyway.
            println( "[zm_qol] STRANDED ZOMBIE stuck at " + str_at + " | spawn_point " + str_spawn );

            //  2026-09-14 - AND NOW IT RESCUES. User, Power Station: one stuck
            //  zombie held the round for minutes - "i had to wait like minutes
            //  and then it eventually bled out". This is the same relocation the
            //  no_bleedout rescue already uses (forceteleport to a live spawn
            //  location near the players), applied the moment the probe says the
            //  zombie is not making progress, instead of waiting out stock's
            //  ~62 s assure_node cycle first. Gated on the same dvars, so
            //  no_bleedout 0 keeps stock behaviour untouched, and skipped when a
            //  player is within melee range - a zombie that is fighting is not
            //  stuck.
            if ( getdvarintdefault( "no_bleedout", 0 ) )
            {
                b_engaged = 0;
                a_players = get_players();

                foreach ( e_player in a_players )
                {
                    if ( distancesquared( ai.origin, e_player.origin ) < 4096 )
                    {
                        b_engaged = 1;
                        break;
                    }
                }

                if ( !b_engaged && getdvarintdefault( "no_bleedout_relocate", 1 ) && ai zmqol_no_bleedout_can_relocate() )
                {
                    if ( ai zmqol_relocate_zombie( 1 ) )
                    {
                        println( "[zm_qol] STRANDED ZOMBIE rescued - moved to a live spawn location" );

                        //  Re-arm, so a zombie that lands somewhere bad is caught
                        //  again 15 s later instead of the round stalling again.
                        ai.zmqol_probe_org = ai.origin;
                        ai.zmqol_probe_ticks = 0;
                    }
                }
            }
        }
    }
}

// ============================================================================
//  .round <n>  -  JUMP TO A ROUND                            (v1.76.0)
//
//  User, 2026-08-12: *"add a command to change the round .round (number) chat
//  command"*.
//
//      chat      .round 30      .setround 30      .round  (prints the current one)
//      console   set_round 30
//
//  🛑 STOCK'S OWN "GO TO ROUND" CANNOT BE CALLED, and this is the `.fog` trap
//  again. maps\mp\zombies\_zm_devgui::zombie_devgui_goto_round() looks like
//  exactly the right function and its ENTIRE BODY sits inside /# #/, so it does
//  not exist in retail. Worse, its mechanism would not work even if copied
//  verbatim: it drives the jump with `level notify( "kill_round" )`, and every
//  matching `level endon( "kill_round" )` - _zm.gsc:2902, :3153,
//  _zm_ai_dogs.gsc:95 - is ALSO inside a /# #/ block. In a retail game that
//  notify is heard by nobody.
//
//  🌟 THE RETAIL PATH, read out of round_think()/round_wait() instead:
//  round_wait() (_zm.gsc:3700) returns as soon as
//      get_current_zombie_count() == 0 && level.zombie_total == 0 && !intermission
//  and round_think() then fires "end_of_round" and does level.round_number++
//  (:3483-3514) before looping into round_start(), which re-derives everything
//  for the new round. round_spawning() calls ai_calculate_health() itself at
//  :2921, so health does NOT need setting by hand.
//
//  So the whole jump is: park round_number at target-1, empty the round, kill
//  what is still walking, and let stock's own loop close the round normally.
//  Nothing is forced and no stock function is replaced.
//
//  📝 level.devcheater is deliberately NOT set. The devgui sets it on every
//  cheat, but it is written and read ONLY inside _zm_devgui.gsc in the whole
//  2,093-file dump, so in retail it is a variable nothing observes.
//  📝 respawn_players() is deliberately NOT called either -
//  _zm_game_module::zombie_goto_round() does that because grief needs it; for a
//  round jump it would just yank everyone back to spawn.
// ============================================================================
zmqol_goto_round( n_target, e_player )
{
    if ( n_target < 1 )
        n_target = 1;

    //  v1.99.93 - the clamp now follows the PATCHES tab's REMOVE ROUND CAP row.
    //  Stock's round_think() clamps to 255 (_zm.gsc:3516) and this mod's copy
    //  does so only when that row is off, so matching it here keeps the two
    //  halves of the same switch honest: with the cap restored, `.round 300`
    //  announces and lands on 255; with it removed, the jump is not truncated.
    if ( !getdvarintdefault( "remove_round_cap", 1 ) && n_target > 255 )
        n_target = 255;

    n_from = level.round_number;

    //  round_think() increments AFTER the round closes, so park one below.
    level.round_number = n_target - 1;
    level.zombie_total = 0;

    //  🌟 v1.99.86 - THE KILL MOVED INTO zmqol_kill_horde(), AND THAT FIXED TWO
    //  REAL BUGS THIS FUNCTION HAD SHIPPED WITH: it damaged magic-bullet-shield
    //  zombies (scripted and boss zombies, which breaks the map script waiting
    //  on them) and it did not reset health first, so on Die Rise - whose
    //  zombies can hold NEGATIVE health - `health + 666` was not lethal and the
    //  horde survived the jump. See the banner over zmqol_kill_horde().
    //
    //  📝 Spawn pacing needs no explicit fix here and deliberately gets none.
    //  Parking round_number one below the target and letting stock's own
    //  round_think() advance it is what re-derives the spawn delay, the move
    //  speed and the health for the new round - so this never writes
    //  level.zombie_vars[...] or level.zombie_move_speed itself, which is the
    //  stock-global hazard QUEUE.md flagged for this item.
    n_killed = zmqol_kill_horde();

    println( "[zm_qol] .round: " + n_from + " -> " + n_target + "  (" + n_killed + " killed)" );

    if ( isdefined( e_player ) )
        e_player iprintln( "^2[zm_qol] round ^7" + n_from + " ^2-> ^7" + n_target );
}

//  Console/bind front-end. A TRIGGER dvar, not a state: it is consumed and
//  reset to 0, so a bind fires on every press. Same shape as the three
//  give_<gun> dvars above.
zmqol_round_dvar_watch()
{
    level endon( "game_ended" );

    if ( getdvar( "set_round" ) == "" )
        setdvar( "set_round", "0" );

    //  v1.99.86, queue item 32 - KILL HORDE and END ROUND ride this same thread
    //  rather than getting one each. Both are one-shot actions with the same
    //  shape as set_round: write 1, it fires, it writes itself back to 0, so a
    //  bind works on every press and the CHEATS row snaps back to DISABLED.
    if ( getdvar( "kill_horde" ) == "" )
        setdvar( "kill_horde", "0" );

    if ( getdvar( "end_round" ) == "" )
        setdvar( "end_round", "0" );

    for ( ;; )
    {
        wait 0.25;

        if ( getdvarintdefault( "kill_horde", 0 ) )
        {
            setdvar( "kill_horde", "0" );
            n_killed = zmqol_kill_horde();
            println( "[zm_qol] kill_horde: " + n_killed + " killed" );
        }

        if ( getdvarintdefault( "end_round", 0 ) )
        {
            setdvar( "end_round", "0" );

            //  Stock ends a round when the last zombie of the round's quota is
            //  gone, so BOTH halves are needed: zero the quota still to spawn,
            //  then clear what is already on the map. Killing alone just makes
            //  the rest of the quota spawn.
            level.zombie_total = 0;
            n_killed = zmqol_kill_horde();
            println( "[zm_qol] end_round: round " + level.round_number + ", " + n_killed + " killed" );
        }

        n_want = getdvarintdefault( "set_round", 0 );

        if ( n_want < 1 )
            continue;

        setdvar( "set_round", "0" );
        level thread zmqol_goto_round( n_want, undefined );
    }
}

// ============================================================================
//  zmqol_kill_horde  -  clear every live round zombie, and the two things that
//  quietly go wrong if you do it naively  (v1.99.86, queue item 32)
//
//  Returns how many were killed, so the callers can print something honest.
//
//  🛑 1. MAGIC-BULLET-SHIELD ZOMBIES ARE SKIPPED. That shield is what stock puts
//  on scripted and boss zombies - the Origins panzer, Mob's brutus, the Die Rise
//  elevator scripts - and damaging one anyway does not just kill something it
//  should not, it breaks the map script that was waiting on it. The mod already
//  respects this in two other places (the nuke at :848 and :865, the tesla gun at
//  _zm_weap_tesla.gsc:304); this brings the round jump into line with them.
//
//  🛑 2. HEALTH IS RESET BEFORE THE DAMAGE, BECAUSE OF DIE RISE. Its zombies can
//  carry NEGATIVE health, and `dodamage( self.health + 666 )` on a zombie at
//  -5000 health asks for -4334 damage, which is not lethal - the horde simply
//  survives the jump. Setting a known positive health first makes the +666
//  margin mean what it says on every map.
//
//  📝 Both of these were already written down as load-bearing in QUEUE.md's
//  item-32 notes, and zmqol_goto_round() - which has shipped since v1.62 - had
//  NEITHER. So this is a real bug fix on the existing .round command, not only
//  plumbing for the two new rows.
// ============================================================================
zmqol_kill_horde()
{
    a_enemies = get_round_enemy_array();

    if ( !isdefined( a_enemies ) )
        return 0;

    n_killed = 0;

    for ( i = 0; i < a_enemies.size; i++ )
    {
        if ( !isdefined( a_enemies[i] ) || !isalive( a_enemies[i] ) )
            continue;

        if ( is_magic_bullet_shield_enabled( a_enemies[i] ) )
            continue;

        //  🛑 v2.15.12 - CLAIM THE KILL, or no_bleedout undoes the whole point.
        //  These kills are a bare attacker-less dodamage, which surfaces in the
        //  "death" notify as `worldspawn`. The mod's own no_bleedout system
        //  (zmqol_nb_death_notify) reads that as "nothing killed it" and OWES the
        //  zombie back to the round (zombie_total++), so with no_bleedout ON the
        //  horde was refunded as fast as it was cleared: `.endround` re-spawned
        //  the round and `.round N` parked at N-1 and never closed to reach N.
        //  Setting marked_for_death is exactly what stock's Nuke does before its
        //  identical dodamage (see no_bleedout's :20853 gate) - it flags the
        //  zombie as claimed by a killer, so nothing is owed back and the round
        //  empties for real. Fixes both .round and .endround at their shared root.
        a_enemies[i].marked_for_death = 1;
        a_enemies[i].health = 10000;
        a_enemies[i] dodamage( a_enemies[i].health + 666, a_enemies[i].origin );
        n_killed++;
    }

    return n_killed;
}

zmqol_fly_dvar_watch()
{
    if ( zmqol_minimal() )
        return;

    self endon( "disconnect" );
    level endon( "game_ended" );

    if ( getdvar( "fly" ) == "" )
        setdvar( "fly", "0" );

    for ( ;; )
    {
        wait 0.25;

        n_want = getdvarintdefault( "fly", 0 );
        b_now  = ( isdefined( self.zmqol_fly ) && self.zmqol_fly );

        if ( n_want && !b_now )
        {
            self zmqol_fly_clear_keys();
            self.zmqol_fly = 1;
            self thread zmqol_fly_think();
            self iprintln( "^2[zm_qol] fly ON" );
        }
        else if ( !n_want && b_now )
        {
            self zmqol_fly_clear_keys();
            self.zmqol_fly = 0;
            self notify( "zmqol_fly_off" );
            self iprintln( "^1[zm_qol] fly OFF" );
        }
    }
}

zmqol_fly_key_toggle()
{
    self endon( "disconnect" );
    level endon( "game_ended" );

    for ( ;; )
    {
        self waittill( "zmqol_fly_key" );

        self zmqol_fly_clear_keys();

        if ( isdefined( self.zmqol_fly ) && self.zmqol_fly )
        {
            self.zmqol_fly = 0;
            self notify( "zmqol_fly_off" );

            //  Keep the "fly" dvar in step - zmqol_fly_dvar_watch() compares it
            //  against the real state, so leaving it at 1 here would have the
            //  next poll take off again a quarter-second later.
            setdvar( "fly", "0" );

            self iprintln( "^1[zm_qol] fly OFF" );
        }
        else
        {
            self.zmqol_fly = 1;
            self thread zmqol_fly_think();
            setdvar( "fly", "1" );
            self iprintln( "^2[zm_qol] fly ON" );
        }
    }
}

// ============================================================================
//  zmqol_fly_clear_keys  -  🛑 THE FIX FOR "IT KEEPS MOVING BY ITSELF"
//
//  User: "the .fly command sometimes is weird sometimes when i do it, it keeps
//  moving by itself but sometimes it works fine".
//
//  The held-key state is built from EDGES, not from polling - +forward sets the
//  flag, -forward clears it, because getnormalizedmovement() does not exist in
//  this build and WASD cannot be read any other way. Edge tracking has one
//  failure mode and this is it: MISS A RELEASE AND THE KEY IS HELD FOREVER.
//
//  And there is a release that is very easy to miss, built into how the command
//  is issued. You type .fly IN CHAT. Opening chat takes keyboard focus away from
//  movement, so a W that was down when the chat box opened can have its key-up
//  swallowed - the client sends +forward and never sends -forward. The flag is
//  now stuck at 1, and it stays stuck for the rest of the match because these
//  watcher threads run whether or not anyone is flying.
//
//  That is exactly the reported shape: intermittent, tied to the moment of
//  toggling, and "sometimes it works fine" - it works whenever you happened to be
//  standing still as you opened chat.
//
//  So the flags are wiped at every takeoff and every landing. A stuck key can no
//  longer outlive one flight, and cannot leak into the next one. If a key really
//  is still physically down after a wipe, the next press re-sets it; the cost of
//  being wrong here is one keystroke, against a permanent drift.
//
//  📝 The general shape, worth keeping: EDGE-DERIVED STATE NEEDS A RESYNC POINT.
//  If you cannot poll the truth, at least re-zero at a moment when you know what
//  the state should be. Takeoff is that moment.
// ============================================================================
// ============================================================================
//  zmqol_fly_install_oopa_veto  -  a STANDING block on the out-of-bounds kill
//
//  Installed once and left in place. For anyone not flying it defers to whatever
//  callback the map had (or to "yes, kill them" if there was none), so stock
//  behaviour is untouched for everyone else - which is why it is safe to leave
//  installed rather than swapping it in and out around each flight and racing
//  every respawn.
//
//  Chained rather than overwritten because a map may install its own: Die Rise
//  does exactly this in setup_zone_monitor(). Clobbering it would break that
//  map's own out-of-bounds handling in a way nothing would report.
// ============================================================================
zmqol_fly_install_oopa_veto()
{
    if ( isdefined( level.zmqol_fly_veto_installed ) )
        return;

    level.zmqol_fly_veto_installed = 1;
    level.zmqol_fly_oopa_prev = level.player_out_of_playable_area_monitor_callback;
    level.player_out_of_playable_area_monitor_callback = ::zmqol_fly_oopa_veto;
}

//  Called ON THE PLAYER. Return false to spare them.
zmqol_fly_oopa_veto()
{
    if ( isdefined( self.zmqol_fly ) && self.zmqol_fly )
        return 0;

    //  Godmode should mean godmode. The stock monitor takes invulnerability off
    //  before it kills, so .god never protected anyone from a death barrier
    //  either - the user hit that too, with godmode visibly ON in the screenshot.
    if ( isdefined( self.zmqol_god ) && self.zmqol_god )
        return 0;

    if ( isdefined( self.zmqol_afk ) && self.zmqol_afk )
        return 0;

    if ( isdefined( level.zmqol_fly_oopa_prev ) )
        return self [[ level.zmqol_fly_oopa_prev ]]();

    return 1;
}

zmqol_fly_clear_keys()
{
    if ( !isdefined( self.zmqol_fly_keys ) )
        return;

    self.zmqol_fly_keys["f"] = 0;
    self.zmqol_fly_keys["b"] = 0;
    self.zmqol_fly_keys["l"] = 0;
    self.zmqol_fly_keys["r"] = 0;
}

zmqol_fly_think()
{
    level endon( "game_ended" );

    e_mover = spawn( "script_origin", self.origin );
    e_mover hide();

    // 🛑 SET THE MOVER'S ANGLES BEFORE LINKING. Stock always does -
    // zm_alcatraz_travel.gsc:770-774 sets e_origin.angles = self.angles on the
    // line before playerlinkto - because the link makes the entity's angles the
    // player's view BASE. Link to an entity still sitting at (0,0,0) and the view
    // is yanked to face world-north the instant you toggle it on, which on its own
    // reads as "the controls broke". v1.19.0 omitted this.
    e_mover.angles = self.angles;

    self zmqol_fly_bind_wasd();

    // Takeoff resync - see zmqol_fly_clear_keys(). Without this a key-up that was
    // swallowed while the chat box had focus leaves you drifting the instant you
    // lift off, which is the whole "it keeps moving by itself" report.
    self zmqol_fly_clear_keys();

    self playerlinkto( e_mover );

    // 🛑 WITHOUT THIS, FLYING KILLS YOU, AND IT READS AS "FLY IS BROKEN".
    // Leaving the playable area in ZM is fatal: _zm.gsc runs a per-player monitor
    // gated on level.player_out_of_playable_area_monitor (set to 1 in
    // _zm.gsc::init(), per-map in zm_highrise.gsc::setup_zone_monitor:571) which
    // kills anyone outside the enabled zones - exactly where flight goes. Stash
    // the old value and clear it for the duration; chat_commands does the same
    // thing at chat_command_ufo_mode.gsc:10-13. Invulnerability + ignoreme cover
    // the rest, mirroring the .afk branch above.
    if ( !isdefined( level.zmqol_fly_oopam ) )
    {
        level.zmqol_fly_oopam = level.player_out_of_playable_area_monitor;
        level.player_out_of_playable_area_monitor = 0;
    }

    // 🛑 AND THE LEVEL FLAG ON ITS OWN DOES NOTHING TO A PLAYER ALREADY IN THE
    // AIR. User: "i keep dying to death barriers... instant game over by mistake
    // when trying to no clip around."
    //
    // Two things were wrong with the block above, and reading the stock function
    // rather than its name settles both:
    //
    // 1. level.player_out_of_playable_area_monitor is only READ AT SPAWN
    //    (_zm.gsc:1335) to decide whether to start the per-player thread. Clearing
    //    it mid-game does not stop a thread that is already running - and for
    //    anyone who has been alive since round 1, it always is. The stash has been
    //    protecting nobody.
    //
    // 2. INVULNERABILITY DOES NOT HELP EITHER, because the monitor takes it off
    //    you first (_zm.gsc:1516-1519):
    //
    //        self disableinvulnerability();
    //        self.lives = 0;
    //        self dodamage( self.health + 1000, self.origin );
    //
    //    That is the instant game over, and it is why .god did not save the user
    //    either. A kill that disables invulnerability cannot be blocked by
    //    enabling invulnerability.
    //
    // The thread endons on "stop_player_out_of_playable_area_monitor" and notifies
    // that itself on entry, so one notify stops it cleanly for THIS player only -
    // stock's own restart mechanism, used exactly as stock uses it. Restarted on
    // landing below.
    //
    // 📝 The general shape: a level flag that GATES thread creation is not a
    // runtime switch. Check whether the thing you are turning off reads the flag
    // continuously or only once, before assuming the flag is a control.
    self notify( "stop_player_out_of_playable_area_monitor" );

    // 🛑 AND THE NOTIFY ALONE IS STILL NOT ENOUGH - v1.51.0 shipped it and the
    // user was "instant killed after a bit when flying around". Killing the
    // thread is a ONE-SHOT act against a thread that can come back: any respawn,
    // revive or host migration runs the spawn path again (_zm.gsc:1335) and
    // starts a fresh copy that has never heard the notify.
    //
    // Stock has a proper veto and it was there the whole time. The monitor asks
    // permission before it kills (_zm.gsc:1495):
    //
    //     if ( !isdefined( level.player_out_of_playable_area_monitor_callback )
    //          || self [[ level.player_out_of_playable_area_monitor_callback ]]() )
    //
    // - a callback returning false skips the kill entirely. That is a STANDING
    // veto rather than a one-off, so it does not care when the thread started or
    // how many times it restarts.
    //
    // 📝 The lesson, and it is the third time this session that reading the stock
    // function paid: when you need to suppress stock behaviour, look for the hook
    // stock already provides before reaching for a notify, a flag or a replaceFunc.
    // Killing the thread was fighting the symptom; the callback is the switch.
    zmqol_fly_install_oopa_veto();

    self.ignoreme = 1;
    self enableinvulnerability();

    self thread zmqol_fly_move( e_mover );

    // 🛑 waittill_any_RETURN, not waittill_any. common_scripts\utility::waittill_any
    // implements notifies 2..n as self endon() - so on death or disconnect this
    // thread would be KILLED and the unlink below would never run, leaving the
    // player welded to a hidden script_origin with no way out. waittill_any_return
    // returns the notify instead, and special-cases "death" so listing it here does
    // not re-introduce the endon.
    self waittill_any_return( "zmqol_fly_off", "disconnect", "death", "player_downed", "bled_out" );

    self notify( "zmqol_fly_move_stop" );

    // Restore the death-barrier monitor for everyone once nobody is flying.
    if ( isdefined( level.zmqol_fly_oopam ) )
    {
        b_anyone_flying = 0;
        a_players = get_players();

        for ( i = 0; i < a_players.size; i++ )
        {
            if ( a_players[i] != self && isdefined( a_players[i].zmqol_fly ) && a_players[i].zmqol_fly )
                b_anyone_flying = 1;
        }

        if ( !b_anyone_flying )
        {
            level.player_out_of_playable_area_monitor = level.zmqol_fly_oopam;
            level.zmqol_fly_oopam = undefined;
        }
    }

    if ( isdefined( self ) )
    {
        self unlink();
        self.zmqol_fly = 0;

        // Landing resync, so nothing left over can leak into the next takeoff.
        self zmqol_fly_clear_keys();

        // Only give back what fly itself turned on - .god / .ghost / .afk own
        // these flags too and must survive a landing.
        if ( ( !isdefined( self.zmqol_ghost ) || !self.zmqol_ghost ) && ( !isdefined( self.zmqol_afk ) || !self.zmqol_afk ) )
            self.ignoreme = 0;

        if ( ( !isdefined( self.zmqol_god ) || !self.zmqol_god ) && ( !isdefined( self.zmqol_afk ) || !self.zmqol_afk ) )
            self disableinvulnerability();

        // Put the death barrier back for this player, unless they are still in a
        // mode that wants it off. Restarting is safe to do twice: the thread's
        // first act is to notify its own endon, so a second copy replaces the
        // first rather than doubling it.
        if ( isdefined( level.zmqol_fly_oopam ) && level.zmqol_fly_oopam )
            self thread maps\mp\zombies\_zm::player_out_of_playable_area_monitor();
        else if ( !isdefined( level.zmqol_fly_oopam ) && isdefined( level.player_out_of_playable_area_monitor ) && level.player_out_of_playable_area_monitor )
            self thread maps\mp\zombies\_zm::player_out_of_playable_area_monitor();
    }

    if ( isdefined( e_mover ) )
        e_mover delete();
}

//  CONTROLS - buttons, not WASD. See the block above zmqol_fly_think() for why
//  WASD cannot be read at all in this build.
//
//      MELEE   fly forward along your view (look down to descend, up to climb)
//      ADS     fly backward
//      JUMP    straight up          STANCE  straight down
//      SPRINT  hold with any of the above for 3x speed
//
//  Melee is the forward key because it is the one button with no meaningful
//  effect while linked - the knife swing is cosmetic - and it is what
//  chat_command_ufo_mode.gsc uses for exactly this reason. Frag (littlegods'
//  choice) would pull a grenade pin every frame, so it is deliberately not used.
//
//  🛑 e_mover.origin, not self.origin. A linked player's origin is driven BY the
//  mover, so feeding self.origin back in makes the step depend on the previous
//  frame's interpolation and the flight drifts and stutters. chat_commands has
//  this bug (it reads self.origin at :112); littlegods reads the mover and is
//  the one to copy.
//
//  🛑 moveto(), never "e_mover.origin = v_pos". A linked player follows the
//  mover's MOVEMENT; a direct origin assignment teleports the parent and the
//  child does not track it. Every stock link target is a real mover. Server tick
//  is 20Hz, so a 0.05s moveto finishes exactly as the next is issued - continuous
//  motion rather than a stutter.
zmqol_fly_move( e_mover )
{
    self endon( "disconnect" );
    self endon( "zmqol_fly_move_stop" );
    level endon( "game_ended" );

    n_speed = 20;

    for ( ;; )
    {
        if ( !isdefined( e_mover ) )
            return;

        v_angles = self getplayerangles();
        v_pos = e_mover.origin;
        b_moved = 0;

        // 🛑 PANIC RELEASE. Melee is the one button with nothing bound to it while
        // linked, and unlike WASD it can be POLLED - so it is the one control that
        // cannot get stuck. Tapping it drops every movement flag.
        //
        // The takeoff resync should mean this is never needed. It is here because
        // the failure it covers is unfalsifiable from script: if the client ever
        // swallows a key-up mid-flight, nothing server-side can tell, and without
        // an escape hatch the only way out is to land and take off again. One
        // pollable button removes that whole class of stuck state.
        if ( self meleebuttonpressed() )
            self zmqol_fly_clear_keys();

        // WASD, from the notifyonplayercommand binds set up in
        // zmqol_fly_bind_wasd(). Mouse buttons are deliberately NOT used any
        // more - the user asked for plain WASD like the console `ufo` command,
        // and driving forward off +attack meant flying and shooting were the
        // same key.
        n_fwd = 0;
        n_rgt = 0;

        if ( self.zmqol_fly_keys["f"] ) n_fwd = n_fwd + 1;
        if ( self.zmqol_fly_keys["b"] ) n_fwd = n_fwd - 1;
        if ( self.zmqol_fly_keys["r"] ) n_rgt = n_rgt + 1;
        if ( self.zmqol_fly_keys["l"] ) n_rgt = n_rgt - 1;

        // Sprint is now a BOOST, not a requirement. Previously forward was
        // OR-ed onto sprint, so flying at all meant holding shift.
        n_step = n_speed;
        if ( self sprintbuttonpressed() )
            n_step = n_speed * 2.5;

        // (The WASD probe that printed a line per tick lived here. It existed to
        // prove notifyonplayercommand reaches a linked player, which it plainly
        // does - the controls work. It was 100 log lines per flight and the file
        // said to delete it once confirmed, so: deleted.)

        if ( n_fwd != 0 )
        {
            v_pos = v_pos + ( anglestoforward( v_angles ) * ( n_fwd * n_step ) );
            b_moved = 1;
        }

        if ( n_rgt != 0 )
        {
            v_pos = v_pos + ( anglestoright( v_angles ) * ( n_rgt * n_step ) );
            b_moved = 1;
        }

        if ( self jumpbuttonpressed() )
        {
            v_pos = v_pos + ( ( 0, 0, 1 ) * n_step );
            b_moved = 1;
        }

        if ( self stancebuttonpressed() )
        {
            v_pos = v_pos - ( ( 0, 0, 1 ) * n_step );
            b_moved = 1;
        }

        // 🛑 AN IDLE TICK ISSUES A STOP, IT DOES NOT JUST SKIP.
        //
        // Previously an idle tick did nothing at all, which quietly assumed the
        // last moveto had already finished. It usually has - 0.05s of travel per
        // 0.05s of wait - but the server tick is not exactly 20Hz, and a frame
        // that runs short leaves the mover still interpolating toward a target
        // nobody is refreshing any more. The player keeps coasting after the key
        // is up.
        //
        // moveto() to the mover's CURRENT origin overrides the one in flight and
        // parks it, so releasing everything stops you on the frame you release.
        // Small on its own; it is the other half of "keeps moving by itself", and
        // the half that survives even a perfectly tracked keyboard.
        if ( b_moved )
            e_mover moveto( v_pos, 0.05 );
        else
            e_mover moveto( e_mover.origin, 0.05 );

        wait 0.05;
    }
}

// ============================================================================
//  zmqol_register_divetonuke_visionset
//
//  🛑 Fixes: EXE_CLIENT_FIELD_MISMATCH on Mob of the Dead survival -
//     "Clientfield 'visionset_lerp' in set [toplayer] is not registered on the
//     server" (console_zm.log 2026-08-02, cellblock run). Cell Block is a STOCK
//     location, so this was breaking stock survival, not just the added ones.
//
//  perks() below calls _zm_perk_divetonuke::enable_divetonuke_perk_for_level()
//  on these five maps, which makes the CLIENT register the PhD visionset:
//  clientscripts\mp\zombies\_zm_perk_divetonuke.csc::init_divetonuke ->
//  vsmgr_register_visionset_info( "zm_perk_divetonuke", ... ), guarded only on
//  level.enable_magic.
//
//  The SERVER half lives in maps\mp\zombies\_zm_perk_divetonuke::init_divetonuke,
//  and the ONLY caller of that is divetonuke_perk_machine_think() - i.e. it runs
//  only once a PhD machine is actually being processed, which is both far too
//  late (vsmgr_register_info asserts on level.vsmgr_initializing, which is only
//  true during the first frame) and does not happen at all on the survival
//  locations. Server ends up with zero registered visionsets while the client
//  has one, so _visionset_mgr never registers visionset_lerp server-side and the
//  client/server clientfield sets disagree -> instant disconnect.
//
//  Registering here in init() puts it inside the legal window, exactly like the
//  Origins fix in zm_tomb.gsc (see zmqol_register_survival_visionset there, and
//  [[t6-visionset-registration-timing]]). zm_tomb is deliberately NOT in this
//  list - it does not call enable_divetonuke_perk_for_level(), and it already
//  registers this visionset itself, so adding it here would double-register.
//
//  Args mirror stock init_divetonuke exactly: version 9000, priority 400,
//  5 lerp steps, activate_per_player 1.
// ============================================================================
zmqol_register_divetonuke_visionset()
{
    map = getDvar( "mapname" );

    if ( map != "zm_transit" && map != "zm_nuked" && map != "zm_highrise" && map != "zm_prison" && map != "zm_buried" )
        return;

    // Degrade to "not registered" rather than erroring out of init() if the
    // ordering ever changes and _visionset_mgr::init() has not run yet.
    if ( !isdefined( level.vsmgr ) || !isdefined( level.vsmgr["visionset"] ) )
        return;

    // Don't double-register if something already did it this frame.
    if ( isdefined( level.vsmgr["visionset"].info ) && isdefined( level.vsmgr["visionset"].info["zm_perk_divetonuke"] ) )
        return;

    //  🛑 v2.9.16 - LERP STEPS CUT TO FIT THE toplayer CEILING. Mob of the
    //  Dead failed to load on v2.9.14 with the exact error ERROR_CATALOGUE
    //  section 2 predicts:
    //      Trying to assign 3 bits for netfield visionset_lerp but Client
    //      Field Set toplayer is out of space.
    //  (console_zm.log, 2026-08-31 20:35 - zm_prison, the vsmgr finalizer, the
    //  last field to ask.) The v2.9.13 perk-field widening to stock's 2 bits is
    //  correct and stays; the space comes back from the mod's OWN visionset
    //  lerp granularity instead, which is the one cosmetic-only lever:
    //  a visionset_lerp/overlay_lerp field is bits(max lerp_step_count over the
    //  registered infos) and is SKIPPED entirely when that max is 1
    //  (_visionset_mgr.gsc:204-224). On the maps where these infos are stock-
    //  native (zombie blood on Origins and Buried, PhD's visionset on TranZit
    //  via its own compiled copies where they win), the native registration is
    //  preserved by the name-dedup guards, so stock maps keep stock widths.
    maps\mp\_visionset_mgr::vsmgr_register_info( "visionset", "zm_perk_divetonuke", 9000, 400, 1, 1 );
}

// ============================================================================
//  zmqol_arm_divetonuke_explosion  -  🛑 HOLDING PhD IS NOT ENOUGH. THE DIVE
//  ONLY EXPLODES IF A PERK MACHINE HAPPENED TO ARM IT.
//
//  User, 2026-09-14: *"i have phd flopper and i just flopped ... and for some
//  reason it didn't like explode"*.
//
//  🌟 THE POINTER IS THE WHOLE BUG, AND IT IS ONE ASSIGNMENT IN STOCK. The dive
//  handler in stock _zm player code calls level.zombiemode_divetonuke_perk_func
//  and does nothing at all when it is undefined - no error, no fx, exactly the
//  silent flop reported. That pointer is assigned in ONE place,
//  _zm_perk_divetonuke::init_divetonuke(), and the ONLY caller of init_divetonuke
//  is divetonuke_perk_machine_think(). So the explosion is armed as a SIDE EFFECT
//  of a PhD vending machine being processed, and never at all otherwise.
//
//  That is fine on a stock map where you can only get PhD by drinking at its
//  machine. It is wrong everywhere this mod hands PhD out by another route:
//  Wunderfizz (wunderfizz.gsc offers PhD on four maps), `.give phd`, GIVE PERKS,
//  and every survival location that has no PhD machine to process. In all of
//  those you hold specialty_flakjacket, you take the fall damage immunity - that
//  part is a specialty and works - and the dive does nothing.
//
//  🛑 THE THREE ZOMBIE VARS AND THE FX ARE NOT OPTIONAL EXTRAS. divetonuke_explode
//  reads level.zombie_vars["zombie_perk_divetonuke_radius"/min/max] and plays
//  level._effect["divetonuke_groundhit"]. init_divetonuke sets all four next to
//  the pointer, so arming the pointer without them would trade a silent flop for
//  an undefined-array error on the first dive. All four move together or not at
//  all.
//
//  📝 SAFE TO RUN TWICE. If a PhD machine does get processed later,
//  init_divetonuke() re-assigns the same pointer, re-sets the same three vars and
//  re-loads the same fx handle - all idempotent. The visionset it also registers
//  is the one thing that is not, and that is already guarded by the name-dedup in
//  zmqol_register_divetonuke_visionset() above.
//
//  Same five maps as the visionset twin, for the same reason: those are the maps
//  perks() calls enable_divetonuke_perk_for_level() on. Origins is excluded there
//  and stays excluded here - it arms its own via zm_tomb.
// ============================================================================
zmqol_arm_divetonuke_explosion()
{
    map = getDvar( "mapname" );

    if ( map != "zm_transit" && map != "zm_nuked" && map != "zm_highrise" && map != "zm_prison" && map != "zm_buried" )
        return;

    level.zombiemode_divetonuke_perk_func = maps\mp\zombies\_zm_perk_divetonuke::divetonuke_explode;

    set_zombie_var( "zombie_perk_divetonuke_radius", 300 );
    set_zombie_var( "zombie_perk_divetonuke_min_damage", 1000 );
    set_zombie_var( "zombie_perk_divetonuke_max_damage", 5000 );

    if ( !isdefined( level._effect ) || !isdefined( level._effect["divetonuke_groundhit"] ) )
        level._effect["divetonuke_groundhit"] = loadfx( "maps/zombie/fx_zmb_phdflopper_exp" );
}

// ============================================================================
//  zmqol_register_vulture_visionset  -  the half of init_vulture() that CANNOT
//  run in main(), and the cause of v1.40.2's EXE_CLIENT_FIELD_MISMATCH
//
//  Town would not launch:
//      Clientfield 'overlay_lerp' in set [toplayer] ... [CLIENT : 12000  SERVER : 1]
//      Clientfield 'overlay_slot' ... bit count [CLIENT: 2  SERVER : 1]
//      Server Disconnected - EXE_CLIENT_FIELD_MISMATCH
//
//  Note what mismatched: NOT any vulture_* field. Every one of those matched.
//  overlay_lerp and overlay_slot are the visionset manager's own fields, and
//  their BIT COUNTS are derived from how many overlays are registered. The
//  client had one more than the server, so the two sides sized the same fields
//  differently and the connection was refused.
//
//  🛑 THE CAUSE IS A TIMING RULE THIS PROJECT ALREADY KNEW AND I BROKE ANYWAY:
//  registerclientfield() must run in main(), but vsmgr_register_info() must run
//  in init() - _visionset_mgr has not built level.vsmgr yet during main(), so
//  the call silently does nothing. Stock's init_vulture() does BOTH: seven
//  registerclientfield calls and one vsmgr_register_info. v1.40.2 called it once
//  from perks(), in main(). The clientfields registered; the overlay did not.
//  Meanwhile the client's enable_vulture_perk_for_level() registered its
//  overlay style filter with no such constraint, and the sides diverged.
//
//  Splitting it is exactly what zmqol_register_divetonuke_visionset() above
//  already does for PhD Flopper, for exactly this reason. It is the same
//  function shape on purpose.
//
//  Arguments are copied verbatim from _zm_perk_vulture.gsc's own call so the two
//  cannot disagree: ( "overlay", "vulture_stink_overlay", 12000, 120, 31, 1 ).
//  The version 12000 in the error message is this registration's, which is how
//  it was identified.
// ============================================================================
zmqol_register_vulture_visionset()
{
    //  🛑 THIS MUST USE THE SAME MAP LIST AS zmqol_enable_vulture(), AND v1.49.0
    //  PROVED IT BY NOT DOING SO. That release excluded Origins from the perk on
    //  both server and client but left this function checking only for Buried, so
    //  the SERVER still registered vulture_stink_overlay while the client did not:
    //
    //      Clientfield 'overlay_lerp' in set[toplayer] is not registered with the
    //      same bit count as the server : [CLIENT: 4  SERVER : 5]
    //      Server Disconnected - EXE_CLIENT_FIELD_MISMATCH
    //
    //  overlay_lerp's WIDTH is derived from how many overlays are registered, so
    //  one extra overlay on one side resizes a shared field and the connection is
    //  refused. This is the second time that exact error has come from this exact
    //  cause - the comment above already documents the first.
    //
    //  So the list now lives in ONE place, zmqol_vulture_enabled(), and every
    //  site asks it. A map list copied into three functions will drift; it drifted
    //  the first time it was copied.
    if ( !zmqol_vulture_enabled() )
        return;

    // Degrade to "not registered" rather than erroring out of init() if the
    // ordering ever changes and _visionset_mgr::init() has not run yet.
    if ( !isdefined( level.vsmgr ) || !isdefined( level.vsmgr[ "overlay" ] ) )
        return;

    // Don't double-register if init_vulture()'s own call did land after all.
    if ( isdefined( level.vsmgr[ "overlay" ].info ) && isdefined( level.vsmgr[ "overlay" ].info[ "vulture_stink_overlay" ] ) )
        return;

    //  🛑 v2.9.22 - steps 7 -> 1 (v2.9.16 had 31 -> 7; not enough). Mob still
    //  refused visionset_slot's 3 bits on the 2026-08-31 boot; at 1 step the
    //  finalizer SKIPS overlay_lerp entirely, which is exactly 3 bits on the
    //  maps this registration runs on (gate above excludes Buried, where
    //  stock's own 31 stays untouched). The stink overlay snaps instead of
    //  fading. Twins: the module's own call in
    //  maps\mp\zombies\_zm_perk_vulture.gsc and the client in zm_expanded.csc
    //  - all three carry 1 and MUST move together.
    maps\mp\_visionset_mgr::vsmgr_register_info( "overlay", "vulture_stink_overlay", 12000, 120, 1, 1 );
}

// ============================================================================
//  zmqol_tombstone_allowed  -  NO TOMBSTONE IN SOLO                 (v1.85.0)
//
//  User, 2026-08-13: *"in solo play remove tombstone cola as that perk is
//  intended for multiplayer games, and it makes no sense to have that perk
//  available when playing solo."*
//
//  🌟 TREYARCH AGREED, AND SHIPPED THE CODE. This is not a house rule invented
//  here - stock has a function for it, by this name:
//
//      maps\mp\zm_transit_utility.gsc:205
//      solo_tombstone_removal()
//      {
//          if ( getnumexpectedplayers() > 1 )
//              return;
//
//          level notify( "tombstone_removed" );
//          level thread maps\mp\zombies\_zm_perks::perk_machine_removal( "specialty_scavenger" );
//      }
//
//  It is threaded from zm_transit_classic.gsc:103 and zm_transit_standard_town
//  .gsc:36 - and NOWHERE ELSE. So stock removes it in solo on TranZit Classic
//  and Town survival only; Die Rise and Buried keep offering a perk that cannot
//  do anything for a solo player. This mod also hands it out through the
//  Wunderfizz on every map, which stock never did. Hence: same rule, applied
//  everywhere, using stock's own removal call rather than a lookalike.
//
//  🛑 THE TEST IS getnumexpectedplayers(), COPIED FROM STOCK'S OWN LINE.
//  Not flag( "solo_game" ) - that is not set until players have connected, and
//  this has to answer during init. This build's own boot log confirms the
//  builtin reports correctly here: `[zm_qol] solo status: expected=1`.
//
//  🛑 AND IT DELIBERATELY DOES NOT TOUCH level.zombiemode_using_tombstone_perk.
//  That flag gates registerclientfield( "toplayer", "perk_tombstone" ) on BOTH
//  halves, and zm_expanded.csc has no way to ask how many players are expected -
//  so gating the flag would desync the two sides and drop everyone with
//  EXE_CLIENT_FIELD_MISMATCH. The 2 bits stay registered and simply go unused,
//  which costs nothing. AVAILABILITY is what changes, not registration.
// ============================================================================
zmqol_tombstone_allowed()
{
    return getnumexpectedplayers() > 1;
}

// ----------------------------------------------------------------------------
//  Stock's solo_tombstone_removal(), applied on every map instead of two.
//  Threaded from init(); stock threads its copy from the map's main(), so this
//  runs strictly later and the machines are certainly spawned by now. The extra
//  network frame is so the notify cannot land before _zm_perks::init() has
//  threaded turn_tombstone_on() - that thread carries
//  `level endon( "tombstone_removed" )` and is what the notify is aimed at.
// ----------------------------------------------------------------------------
zmqol_solo_tombstone_removal()
{
    if ( zmqol_tombstone_allowed() )
        return;

    wait_network_frame();

    level notify( "tombstone_removed" );
    level thread maps\mp\zombies\_zm_perks::perk_machine_removal( "specialty_scavenger" );

    println( "[zm_qol] tombstone: solo game (expected=" + getnumexpectedplayers() + ") - machine removed and perk withheld" );
}

perks()
{
    if ( getDvar("mapname") == "zm_transit" || getDvar("mapname") == "zm_nuked" || getDvar("mapname") == "zm_highrise" || getDvar("mapname") == "zm_prison" || getDvar("mapname") == "zm_buried" ) //GLOBAL
    {
        level.zombiemode_using_marathon_perk = 1;

        // ====================================================================
        //  🛑 v2.9.30 - BURIED IS EXCLUDED FROM DEADSHOT (and Tombstone,
        //  below). Measured from the user's failed boot, 2026-09-01:
        //      Trying to assign 5 bits for netfield vulture_perk_disease_meter
        //      but Client Field Set toplayer is out of space.  (zm_buried, zclassic)
        //  That field is STOCK Buried's own (the mod's Vulture port is off
        //  here - Buried ships the perk) - per ERROR_CATALOGUE §2 the name is
        //  just whoever asked last. The real cause: stock Buried classic is
        //  the fullest toplayer map in the game at 63 bits, and the mod's
        //  additions put it at 71:
        //      perk_dead_shot            +2   (this flag)
        //      perk_tombstone            +2   (below)
        //      perk_electric_cherry      +1   (zmqol_enable_electric_cherry)
        //      powerup_zombie_blood      +2   (zmqol_zombie_blood_enabled)
        //      visionset_lerp 3 -> 4     +1   (zombie blood's 15 lerp steps)
        //  63 is the only total ever seen to boot (stock Buried; this mod's
        //  Buried on 2026-08-13 - which really ran at 63, not the "≥71" the
        //  ERROR_CATALOGUE records, because the pre-v2.9.13 1-bit perk fields
        //  were masking 8 bits; Mob since v2.9.22). 66 fails (Mob v2.9.21,
        //  Origins 2026-09-01). So ALL FIVE of the mod's Buried bits go, and
        //  Buried returns to its stock toplayer roster exactly.
        //
        //  What Buried loses: Deadshot + Electric Cherry from the Wunderfizz
        //  (it keeps its native seven perks incl. Vulture Aid), Tombstone
        //  (was co-op-only anyway), and the Zombie Blood box powerup. If a
        //  boot ever proves the ceiling is 64 or 65, Electric Cherry (+1) and
        //  then Deadshot (+2) are the restoration order.
        //
        //  🛑 The client twin is zm_expanded.csc::perks() and MUST carry the
        //  identical exclusions, or the toplayer set differs in width between
        //  the two sides and everyone is dropped with
        //  EXE_CLIENT_FIELD_MISMATCH before the map starts.
        // ====================================================================
        if ( getDvar( "mapname" ) != "zm_buried" )
            level.zombiemode_using_deadshot_perk = 1;

        level.zombiemode_using_additionalprimaryweapon_perk = 1;
        level.zombiemode_using_divetonuke_perk = 1;
        maps\mp\zombies\_zm_perk_divetonuke::enable_divetonuke_perk_for_level();

        //  v1.56.2 - THE 12TH PERK. Tombstone used to be absent here, and it was
        //  absent for a real reason: setting this flag makes the precache block
        //  further down run precachemodel( "ch_tombstone1" ), and precaching a
        //  model the level does not own is fatal at load. All five Tombstone
        //  assets live in zm_transit.ff and nowhere else, which is exactly why
        //  the TranZit survival locations (Diner/Town/Farm/Depot) already had
        //  twelve perks while Nuketown had eleven.
        //
        //  They now ship in mod.ff - see the TOMBSTONE EVERYWHERE block in
        //  zone_source\mod_locations.zone - so the flag is safe on every map in
        //  this list.
        //
        //  🛑 The twin in scripts\zm\zm_expanded.csc::perks() MUST set this too.
        //  Both sides gate a registerclientfield on it, so one-sided is
        //  EXE_CLIENT_FIELD_MISMATCH before the map starts.
        //  🛑 v2.9.30 - not on Buried; see the Deadshot block above for the
        //  full toplayer arithmetic (63 stock + these 2 was part of the 71
        //  that stopped the map loading).
        if ( getDvar( "mapname" ) != "zm_buried" )
            level.zombiemode_using_tombstone_perk = 1;
    }

    // ========================================================================
    //  v1.58.2 - ORIGINS GETS THE 12TH PERK TOO, and ONLY the 12th.
    //
    //  User, 2026-08-07, on the replaced Wunderfizz: "there's one perk missing
    //  tombstone cola". Correct - the machine said "You Have All 11 Perks",
    //  because getPerks() gates specialty_scavenger on this flag and zm_tomb is
    //  not in the map list above.
    //
    //  🛑 zm_tomb IS DELIBERATELY NOT ADDED TO THAT LIST. The block also calls
    //  _zm_perk_divetonuke::enable_divetonuke_perk_for_level(), and Origins
    //  ALREADY has dive-to-nuke natively - perk_dive_to_nuke is in its stock
    //  clientfield dump. Re-enabling an already-enabled perk risks the
    //  "Attempt to register ClientField ... already registered" fatal that the
    //  Electric Cherry block above this function documents. Marathon, Deadshot
    //  and Additional Primary are likewise already native on Origins (all three
    //  are in its stock dump), so the ONLY thing Origins is actually missing is
    //  Tombstone. Setting one flag is the whole fix.
    //
    //  🌟 THE CLIENTFIELD BUDGET WAS MEASURED, NOT ASSUMED, because overflowing
    //  the toplayer set does not cost a perk - it stops the map loading.
    //  From the per-map dumps in Black Ops 2 Grand Resources\...\Clientfields\:
    //
    //        map        non-perk   stock perk   total
    //        zm_buried      48         15         63     <- mod runs all 12 here
    //        zm_tomb        45         16         61
    //
    //  Origins carries 3 bits MORE headroom than Buried, where Tombstone
    //  already ships and works. The delta from this change is exactly one
    //  field, perk_tombstone, at `bits` wide (2 on Origins, which has
    //  emp_grenade_zm). The mod REPLACES _zm_perks::perks_register_clientfield
    //  on both sides rather than adding to it, so these do not stack on top of
    //  stock's - the mod's list IS the perk list.
    //
    //  🛑 The twin in scripts\zm\zm_expanded.csc::perks() MUST match this
    //  exactly, for the same reason the block above says so.
    //
    // ========================================================================
    //  🛑 v2.12.1 - ORIGINS NO LONGER GETS TOMBSTONE. THIS IS A TRADE THE USER
    //  ASKED FOR, NOT A REGRESSION.
    //
    //  User, 2026-09-05, after being told Origins was 2 bits short of Bonfire
    //  Sale and that Tombstone was exactly those 2 bits: *"Get rid of tombstone
    //  from origins then"*.
    //
    //  The arithmetic is unchanged from the block above, just spent differently:
    //  Origins classic is 61 stock toplayer bits, this mod adds exactly 2, and 63
    //  is the only total ever seen to boot. perk_tombstone WAS those 2 bits; now
    //  powerup_bon_fire is. Origins still lands on 63 either way - one perk out,
    //  one power-up in, no third option.
    //
    //  WHAT ORIGINS LOSES, precisely: Tombstone stops being offered by the
    //  Wunderfizz (wunderfizz.gsc:1712 reads this same flag) and drops out of
    //  getPerks(). Origins has no Tombstone MACHINE - it never did - so nothing
    //  visible is removed from the map, and every other use of the flag is an
    //  isdefined() guard that simply skips.
    //
    //  🛑 THE TWIN IN zm_expanded.csc::perks() CARRIES THE IDENTICAL REMOVAL.
    //  Both sides gate registerclientfield( "toplayer", "perk_tombstone" ) on
    //  this flag; leave it set on one side only and the set is one field wider
    //  there and every player is dropped with EXE_CLIENT_FIELD_MISMATCH.
    //
    //  TO PUT IT BACK: restore the two lines below on BOTH sides and add
    //  `if ( map == "zm_tomb" ) return 0;` to BOTH zmqol_bonfire_sale_enabled()
    //  twins in the same edit. Never one without the other.
    //
    //      if ( getDvar( "mapname" ) == "zm_tomb" )
    //          level.zombiemode_using_tombstone_perk = 1;
    // ========================================================================

    zmqol_enable_electric_cherry();
    zmqol_enable_vulture();
    zmqol_enable_whoswho();
    zmqol_enable_blood_money();

    //  v1.99.39 - user request 2026-08-17. Who's Who hands you a Pack-a-Punched
    //  ballistic knife instead of the map's starting pistol, so you can revive
    //  your own downed body from range. See zmqol_whoswho_knife_watch().
    create_dvar( "whoswho_knife", 1 );
    level thread zmqol_whoswho_knife_onplayerconnect();

    //  Bo2-VN: BETTER DEADSHOT is removed. The actor-damage chain it installed
    //  stays, because ONE SHOT ONE KILL and the special-enemy marker ride it.
    level thread zmqol_better_deadshot_install();

    //  v1.99.74 - AIM ASSIST, user request 2026-08-19. Default 1 = stock.
    //  See the banner over zmqol_aim_assist_watch() for exactly what this can
    //  and cannot reach - it is measured, and it is narrower than the label.
    create_dvar( "aim_assist", 1 );
    level thread zmqol_aim_assist_watch();

    //  v2.9.15 - TAP TO INTERACT, user request 2026-08-31, CONTROLS > GAMEPAD.
    //  Default 0 = stock hold-to-use. v2.9.33: the server half is GONE - the
    //  whole implementation is now client-side binds applied by the toggle row
    //  itself (ui\t6\menus\optionssettings.lua, the selector_changed handler).
    //  The first cut's g_useholdtime dvar DOES NOT EXIST in T6 - proven by the
    //  v2.9.31 boot log (row-inert print on all 4 map loads), the live
    //  3,153-dvar dump, and t6zm.exe's own strings. The dvar row is kept
    //  registered so the LUI toggle has something to read and archive.
    create_dvar( "tap_to_interact", 0 );

    //  ========================================================================
    //  THE PATCHES TAB  (v1.99.93, user request 2026-08-20)
    //
    //  Five of the seven rows the user asked for. The two that are absent are
    //  absent on purpose and the reason is recorded here rather than left to be
    //  rediscovered:
    //
    //    SLIQUIFIER PRE-NERF - held back here in v1.99.93, shipped in v1.99.96
    //      off BO2-Remix's correct implementation, and REMOVED AGAIN in v2.14.17
    //      at the user's request ( the infinite damage is the Pack-a-Punched
    //      Sliquifier's now ). The original reasoning is kept because it is still
    //      the right reading of the shipped script: the legacy mod sets
    //      level.zombie_vars["slipgun_reslip_rate"] = 0, but the SHIPPED script
    //      guards that read with `if ( level.zombie_vars["slipgun_reslip_rate"]
    //      > 0 && randomint( ... ) == 0 )` ( _zm_weap_slipgun.gsc:745, and :779
    //      of the zm_highrise_patch decompile ), so 0 does not mean "always
    //      re-slip", it means NEVER re-slip. Its other line,
    //      slipgun_max_kill_round = undefined, is read by
    //      ai_zombie_health( undefined ) at :65 - which cannot loop and leaves
    //      the goo WEAKER, not stronger. Both lines do the opposite of the row's
    //      label on this build, and no pre-patch copy of that script exists in
    //      the workspace to port instead: BO2-Raw-files' base decompile carries
    //      the same 6 / 100 values as the patch fastfile.
    //
    //    RECOIL PRE-NERF - `sv_patch_zm_weapons` DOES NOT EXIST on this build.
    //      It is absent from the boot dvar dump (2,764 dvars, alphabetical, and
    //      sv_paused / sv_playlistFetchInterval sit either side of where it
    //      would be), from t6zm.exe's string table, from Plutonium's
    //      bootstrapper and from dvar_descriptions.json. setdvar would create a
    //      user dvar that nothing reads - a dead switch.
    //
    //  Both are held for the user's decision rather than shipped broken.
    //  ========================================================================
    create_dvar( "remove_round_cap",   1 );   // ON: the mod already has no cap
    create_dvar( "no_walkers",        0 );   // v2.8.6 - see zmqol_no_walkers_watch()

    //  ========================================================================
    //  🛑 v2.14.17 - `create_dvar( "sliquifier_prenerf", 0 )` WAS HERE AND IS
    //  GONE, and so is its PATCHES row. User, 2026-09-08: *"remove the option
    //  for sliquifier pre nerf patch, and then make it so that the sliquifier is
    //  pack a punchable with my mod, and the pack a punch version is infinite
    //  damage like the pre nerf version"*. The Die Rise script keeps no reader
    //  for it: the watch thread and the fallback death callback are deleted, and
    //  the infinite damage now belongs to the Pack-a-Punched gun instead. See
    //  the banner in scripts\zm\zm_highrise\zm_highrise.gsc for the whole of it.
    //
    //  🛑 v2.0.2 - `create_dvar( "semtex_wallbuy", 0 )` WENT THE SAME WAY.
    //  User, 2026-08-20: *"this semtex wall buy should just be apart of the mod
    //  not an option you can toggle on or off."*  The Die Rise Semtex wall buy
    //  is unconditional now, so there is no dvar and no PATCHES row for it. The
    //  read in scripts\zm\zm_highrise\zm_highrise.gsc went with it - a dvar that
    //  no menu writes and no script reads is exactly the kind of leftover that
    //  turns into a false lead later.
    //
    //  Both features still live entirely in the map's own script, because
    //  maps\mp\zombies\_zm_weap_slipgun ships in zm_highrise_patch.ff and a
    //  qualified reference to it from a root file is an Unresolved external that
    //  kills every OTHER map at load ( AI_CONTEXT rule 2 ).
    //  ========================================================================


    //  CHEATS tab. set_points HOLDS its value (0 is a real setting); teleport
    //  ALSO now holds its value (v2.4.2 - it is just the destination selector);
    //  execute_teleport is the actual action row and writes itself back to 0 -
    //  see zmqol_teleport_watch() for why.
    create_dvar( "set_points", 0 );
    create_dvar( "teleport",   0 );
    create_dvar( "execute_teleport", 0 );

    //  v1.99.39 - user request 2026-08-17. The Pack-a-Punched crossbow's bolts
    //  draw zombies to them like a monkey bomb. See zmqol_awful_lawton_watch().
    level thread zmqol_awful_lawton_onplayerconnect();

    //  🛑 EXACT TWIN of the call at the end of zm_expanded.csc::perks(). Both
    //  sides register player_zombie_blood_fx (allplayers, 1 bit) and, through
    //  add_zombie_powerup, powerup_zombie_blood (toplayer, 2 bits). Enable it on
    //  one side only and everyone is dropped with EXE_CLIENT_FIELD_MISMATCH
    //  before the map starts - the Fire Sale bug, exactly.
    zmqol_enable_zombie_blood();

    // 🛑 STANDING RULE, user 2026-08-09: A PORTED PERK IS NEVER MODIFIED.
    //
    //  v1.62.8/v1.62.9 owned Electric Cherry's reload attack by re-pointing
    //  level._custom_perks[...].player_thread_give at our own copy of
    //  electric_cherry_reload_attack(), to instrument it and then to delete
    //  stock's consecutive-reload throttle and its 0.1s per-zombie damage
    //  stagger. Both deletions were real defects in stock's own terms and both
    //  are now REVERTED, because they made the perk behave and LOOK different
    //  from the one Mob of the Dead and Origins ship:
    //
    //    - no stagger  -> every zombie's tesla_shock fx started in the same
    //                     frame instead of 0.1s apart, so the zap read as one
    //                     bright mass rather than an arc travelling the crowd.
    //    - no throttle -> reload #3+ played full-strength fx where stock plays
    //                     a reduced set or none.
    //
    //  The user's instruction is that the job here is PORTING, not tuning:
    //  *"don't change how electric cherry behaves because you're not meant to
    //  change the perk just leave it alone and then port it over to the maps
    //  that don't have it already. simple, same logic for literally any other
    //  perk (eg. who's who)."*
    //
    //  So the perk now runs stock's own electric_cherry_reload_attack() on
    //  every map, byte-for-byte the function Mob and Origins run. Everything
    //  this mod still does for Electric Cherry is ADDITIVE and only fills a gap
    //  the port leaves - the perk machine/Wunderfizz entry above, and
    //  qol_options.gsc's zmqol_cherry_zap, which supplies the zmb_cherry_explode
    //  audio on maps whose soundbanks lack Alcatraz's alias and is explicitly
    //  skipped on zm_prison and zm_tomb.
}

// ============================================================================
//  zmqol_enable_fire_sale  -  Fire Sale on the two maps that never had it
//
//  Measured across the stock dump, not assumed. include_powerup( "fire_sale" )
//  is called by zm_nuked (:720), zm_prison (:947), zm_buried (:1279) and
//  zm_tomb (:1173). It is NOT called by zm_transit or zm_highrise - those two
//  are the whole gap.
//
//  🛑 WHY THIS NEEDED AN ASSET AND NOT JUST THE ONE-LINE INCLUDE.
//  _zm_powerups::add_zombie_powerup() precaches the model only for powerups
//  that were included:
//        if ( isdefined( level.zombie_include_powerups ) &&
//             !isdefined( level.zombie_include_powerups[powerup_name] ) )
//            return;
//        precachemodel( model_name );
//  and Unlinker --list shows zombie_firesale is absent from zm_transit.ff and
//  zm_highrise.ff - the same two maps. So including it without shipping the
//  model would precache something the level does not have, which is fatal at
//  load. zone_source\mod_locations.zone now carries it; see the block there.
//
//  🛑 TIMING. include_powerup() only sets level.zombie_include_powerups[name],
//  which _zm_powerups::init() reads later when it calls add_zombie_powerup for
//  each one - so this MUST run before that init. main() is inside Plutonium's
//  precache window and runs ahead of every ::init(), which is the same reason
//  wunderfizz.gsc does its precaching there. It is additive, so a map setting
//  up its own list afterwards cannot clobber this.
//
//  Fire Sale needs a mystery box to be worth anything, and stock already gates
//  the drop on that: func_should_drop_fire_sale() refuses while
//  level.chest_moves < 1. Both maps have a moving box, so nothing else is
//  required - and on any map where that stopped being true, stock declines the
//  drop on its own rather than dropping a dud.
// ============================================================================
zmqol_enable_fire_sale()
{
    map = getDvar( "mapname" );

    if ( map != "zm_transit" && map != "zm_highrise" )
        return;     // the other four include it themselves

    maps\mp\zombies\_zm_utility::include_powerup( "fire_sale" );
}

// ============================================================================
//  zmqol_enable_blood_money  -  BLOOD MONEY on every map, dropping naturally
//
//  User, 2026-08-11: *"add these 2 power ups to all the maps that you can that
//  aren't limited by the game... and also for origins make it so that blood
//  money can spawn naturally and it doesn't need to be dug up in a dig site."*
//
//  🌟 BLOOD MONEY IS NOT AN ORIGINS POWERUP. It is `bonus_points_player`, and it
//  is registered in CORE, on every map in the game:
//      _zm_powerups.gsc:106
//      add_zombie_powerup( "bonus_points_player", "zombie_z_money_icon",
//                          &"ZOMBIE_POWERUP_BONUS_POINTS",
//                          ::func_should_never_drop, 1, 0, 0 );
//  Only Origins ever switched it on (zm_tomb.gsc:1176 server, zm_tomb.csc:416
//  client), and even there stock hands it out solely from a dig site
//  (zm_tomb_dig.gsc:442, the "bonus_points_player" branch of dig_up_powerup).
//
//  🌟 IT COSTS ZERO CLIENTFIELD BITS, and that is the reason it can ship on
//  EVERY map while Zombie Blood cannot. The 7-argument call above stops short of
//  add_zombie_powerup's `client_field_name` parameter, so the
//  registerclientfield() at _zm_powerups.gsc:449 never runs - server or client
//  (the client's own add_zombie_powerup, _zm_powerups.csc:20, likewise passes no
//  field name). Nothing is added to the `toplayer` set, so the per-map budget
//  wall documented in .agents\QUEUE.md does not apply here at all.
//
//  📝 EVERYTHING IT DOES IS ALREADY CORE, so this port adds no behaviour of its
//  own - which is exactly what [[zm-qol-port-never-tune]] asks for:
//    - the grab is handled by core powerup_grab()'s own
//      `case "bonus_points_player"` (_zm_powerups.gsc:1060), which threads
//      bonus_points_player_powerup() - randomintrange( 1, 25 ) * 100 points to
//      the grabbing player only, skipped in last stand or spectator.
//    - the pickup glow is level._effect["powerup_on_solo"], loaded by core's
//      client init on every map (solo = 1 in the call above).
//    - the hint string &"ZOMBIE_POWERUP_BONUS_POINTS" is core-localized.
//
//  🛑 THE ANNOUNCER VO IS DELIBERATELY LEFT SILENT, and that is parity, not a
//  gap. powerup_grab() calls powerup_vo( "bonus_points_solo" ), which reaches
//  _zm_audio::create_and_play_dialog() - and that function's second statement is
//      if ( !isdefined( level.vox.speaker[self.zmbvoxid].alias[category][type] ) )
//          return;
//  `createvox( "bonus_points_solo", ... )` appears NOWHERE in the 2,093-file
//  stock dump - not in core's _zm_audio_announcer.gsc (which does register
//  carpenter, insta_kill, double_points, nuke, full_ammo, fire_sale, minigun and
//  zombie_blood), and not on Origins either. So Blood Money is silent on the map
//  that ships it, and adding a line here would make this port LOUDER than the
//  original - the v1.62.9 mistake.
//
//  🛑 TIMING. include_powerup() only writes level.zombie_include_powerups[name];
//  _zm_powerups::init() reads it later, when it calls add_zombie_powerup for each
//  entry. main() is inside Plutonium's precache window and runs ahead of every
//  ::init(), and of the map's own main() - so writing here is early enough. It is
//  purely additive (include_zombie_powerup creates the array only if undefined
//  and never clears it), so the map's own include_powerups() cannot clobber it,
//  and our entry cannot be lost.
//
//  📝 NO MAP GATE, unlike zmqol_enable_fire_sale above, and that is safe for two
//  independent reasons. First, include_zombie_powerup() is idempotent - it sets
//  the key to 1 - so calling it on Origins, which already includes it, is a
//  no-op. Second, the "creating the array flips the filter" trap called out in
//  zm_expanded.csc's fire-sale block cannot bite: all six maps populate
//  level.zombie_include_powerups themselves on BOTH sides (verified - zm_transit,
//  zm_nuked, zm_highrise, zm_prison, zm_buried and zm_tomb each have an
//  include_powerups() in their .gsc and their .csc), so the array is never left
//  holding only our entry.
//
//  🛑 THE MODEL HAD TO SHIP. Unlinker --list over all six map fastfiles plus
//  common_zm.ff and patch_zm.ff:
//      zombie_z_money_icon   tra 0  nuk 0  hig 0  pri 0  bur 1  tom 1  com 0
//  add_zombie_powerup() precaches the model for every INCLUDED powerup
//  (_zm_powerups.gsc:419-422), so including it on the four maps that lack the
//  model would precache an absent asset - fatal at load, the same trap Fire Sale
//  hit. zone_source\mod_locations.zone now carries xmodel,zombie_z_money_icon.
//  zm_buried.ff's and zm_tomb.ff's copies were dumped and hashed and are
//  BYTE-IDENTICAL (json a9e3dae5..., glb c5c760f5..., 4364 bytes), so mod.ff
//  owning it globally cannot regress the two maps that already had it - the
//  mod.ff asset-ownership trap does not apply.
// ============================================================================
// ============================================================================
//  zmqol_custom_powerups_enabled  -  the CUSTOM POWER-UPS row on the GAME tab
//  (v1.99.83, queue item 25)
//
//  User, 2026-08-19: ON = the mod's added drops (Zombie Blood, Blood Money,
//  Death Machine); OFF = the stock power-up table only.
//
//  🛑 WHAT THIS GATES, AND WHAT IT DELIBERATELY DOES NOT.
//  It gates ONLY the calls that put a power-up into the drop table -
//  include_powerup / include_zombie_powerup / add_zombie_powerup /
//  powerup_set_can_pick_up_in_last_stand - and the Blood Money drop-function
//  re-point. It does NOT gate a single registerclientfield, visionset,
//  loadfx or precache.
//
//  🌟 THAT IS THE WHOLE SAFETY ARGUMENT, and it is the trap QUEUE.md flagged as
//  the highest-risk part of this item. A clientfield registered on the server
//  and not on the client - or registered on one map's boot and not the next -
//  is EXE_CLIENT_FIELD_MISMATCH at load, which is fatal and gives no useful
//  error (ERROR_CATALOGUE §1). Leaving every registration exactly where it is
//  means the per-map bit budget with this row OFF is byte-identical to the
//  budget with it ON, on every map, so the row cannot break a boot. The cost is
//  a few reserved bits nobody reads while it is off, which is invisible.
//
//  🌟 ORIGINS IS ALREADY CORRECT WITHOUT A SPECIAL CASE, and that is measured:
//    - Zombie Blood: zmqol_zombie_blood_enabled() already returns 0 on zm_tomb
//      because Origins registers the power-up itself, so this row never reaches
//      it there.
//    - Blood Money: Origins includes it in its OWN main() -
//      <gsc-dump>\ZM\Maps\Origins\maps\mp\zm_tomb.gsc:1176
//      include_powerup( "bonus_points_player" ) - so skipping this mod's
//      include on Origins changes nothing, and skipping the drop-function
//      re-point returns it to stock's ::func_should_never_drop, i.e. dig-site
//      only. That IS Origins' vanilla behaviour, which is exactly what OFF is
//      supposed to mean per the user's requirement.
//
//  📝 Read at map load, not per drop, because these are registration calls that
//  only happen once. Flipping the row takes effect on the next map.
// ============================================================================
zmqol_custom_powerups_enabled()
{
    return getdvarintdefault( "custom_powerups", 1 );
}

// ============================================================================
//  zmqol_zb_should_drop / zmqol_bm_should_drop  -  v1.99.91
//
//  The CUSTOM POWER-UPS row is enforced HERE, in the drop predicate, and no
//  longer at registration time. _zm_powerups::get_valid_powerup() calls
//  [[ struct.func_should_drop_with_regular_powerups ]]() on every drop attempt
//  (_zm_powerups.gsc:337), so the dvar is read live: flipping the row takes
//  effect on the very next drop, with no registration, no clientfield and no
//  visionset moving underneath it.
//
//  🛑 THIS IS THE FIX FOR EXE_CLIENT_FIELD_MISMATCH. Never gate a
//  registration call on this row again - see the block above
//  zmqol_enable_zombie_blood's include_powerup for the whole failure.
// ============================================================================
zmqol_zb_should_drop()
{
    return zmqol_custom_powerups_enabled();
}

zmqol_bm_should_drop()
{
    return zmqol_custom_powerups_enabled();
}

// ============================================================================
//  zmqol_bonus_points_player_powerup  -  BLOOD MONEY'S ANNOUNCER LINE, PLAYED
//  BY THIS MOD RATHER THAN THROUGH STOCK'S QUEUE                     (v2.8.8)
//
//  User, 2026-08-30: the Blood Money line was silent on Nuketown while Zombie
//  Blood's played, and both go through the same stock path.
//
//  🌟 WHAT WAS RULED OUT FIRST, by measurement, not by reading:
//    - the alias exists under BOTH announcer prefixes -
//      vox_zmba_qol_powerup_blood_money and vox_zmba_sam_qol_powerup_blood_money,
//      each in the bare and the _0 form;
//    - the payload is really in the shipped bank - id 0x87bbb7b9, 64106 bytes,
//      inside mod.all.sabs (dumped from the built file, not assumed);
//    - the registration runs, and it runs to completion - Zombie Blood's line
//      is audible on Nuketown, and its createvox is the statement immediately
//      before Blood Money's, so both executed.
//
//  So the alias half is provably fine and the fault is in the trigger, which is
//  stock's own path: _zm_powerups.gsc:1147 threads leaderdialog( powerup_name ),
//  and leaderdialogonplayer() drops the line outright when self.zmbdialogactive
//  is already 1 (no queue flag is passed). Nothing offline pins down which
//  earlier line sets it, so this stops depending on that path at all.
//
//  🛑 THIS IS A replaceFunc OF A 9-LINE STOCK FUNCTION, and the stock body is
//  copied verbatim above the new call - the points award must stay identical.
//  See _zm_powerups.gsc:2062.
// ============================================================================
zmqol_bonus_points_player_powerup( item, player )
{
    //  --- stock body, verbatim (_zm_powerups.gsc:2062-2071) ---
    points = randomintrange( 1, 25 ) * 100;

    if ( isdefined( level.bonus_points_powerup_override ) )
        points = [[ level.bonus_points_powerup_override ]]();

    if ( !player maps\mp\zombies\_zm_laststand::player_is_in_laststand() && !( player.sessionstate == "spectator" ) )
        player maps\mp\zombies\_zm_score::player_add_points( "bonus_points_powerup", points );

    //  --- the half stock never reaches ---
    level thread zmqol_play_announcer_line( "qol_powerup_blood_money" );
}

// ============================================================================
//  zmqol_play_announcer_line  -  the announcer, without stock's drop-if-busy
//
//  Builds the alias exactly as _zm_audio_announcer::playleaderdialogonplayer
//  does - game["zmbdialog"]["prefix"] + "_" + suffix - so it follows Nuketown's
//  vox_zmba_sam prefix on its own, and takes the _0 variant when one exists,
//  which is the shape every other announcer line in the game uses.
//
//  playlocalsound() is stock's own call for this (announcer lines are 2D, per
//  player); get_players() rather than a team filter because these are this mod's
//  own power-ups and every player hears them.
//
//  🛑 v2.14.1 - THE ALIAS ROW'S MIXER SETTINGS DECIDE WHETHER THIS IS HEARD, AND
//  TWO OF THE FOUR LINES HAD THE WRONG ONES. Nothing in this function was at
//  fault: Death Machine and Bonfire Sale shipped on bus_hdrfx / grp_hdrfx /
//  snp_hdrfx at volume 73 with pitch +200, because their rows were copied
//  verbatim from the zmb_vox_ann_* rows their payloads came out of - and those
//  are DEV LEFTOVERS (FileSource devraw\..., played by none of the 2,093 stock
//  scripts), so Treyarch's mix on them was never exercised. snp_hdrfx is ducked
//  by other audio, which is exactly what a power-up grab always has. Measured
//  against zmb_highrise.english's own table: all six announcer rows the game
//  really plays - carpenter, doublepoints, firesale, instakill, maxammo, nuke -
//  use bus_voice / grp_voice / snp_never_duck / vol 84 / pitch 0 / priority 100
//  / pan quad / reverb 0, and so do this mod's two CONFIRMED-AUDIBLE lines
//  (Zombie Blood, Blood Money). All eight rows now match that shape.
//  📝 If a future announcer line is added, copy an existing *_qol_powerup_* row
//  in soundbank\mod.all.aliases.additions.csv - never a zmb_vox_ann_* row.
// ============================================================================
zmqol_play_announcer_line( str_suffix )
{
    if ( !isdefined( level.allowzmbannouncer ) || !level.allowzmbannouncer )
        return;

    if ( !isdefined( game[ "zmbdialog" ] ) || !isdefined( game[ "zmbdialog" ][ "prefix" ] ) )
        return;

    str_alias = game[ "zmbdialog" ][ "prefix" ] + "_" + str_suffix;

    if ( soundexists( str_alias + "_0" ) )
        str_alias = str_alias + "_0";
    else if ( !soundexists( str_alias ) )
        return;

    a_players = get_players();

    for ( i = 0; i < a_players.size; i++ )
    {
        a_players[ i ] playlocalsound( str_alias );

        //  Mirror stock's own book-keeping so the next announcer line does not
        //  talk over this one. playleaderdialogonplayer() sets the same flag and
        //  clears it after the same 4 seconds.
        a_players[ i ].zmbdialogactive = 1;
        a_players[ i ] thread zmqol_announcer_line_clear();
    }
}

zmqol_announcer_line_clear()
{
    self endon( "disconnect" );
    wait 4.0;
    self.zmbdialogactive = 0;
    self.zmbdialoggroup = "";
}

// ============================================================================
//  zmqol_fs_should_drop / zmqol_fire_sale_custom_gate  -  FIRE SALE under the
//  CUSTOM POWER-UPS row                                            (v2.0.5)
//
//  User, 2026-08-21: *"if you have the custom power ups option enabled,
//  alongside all the power ups it already allows for, add fire sale in to the
//  equation as well so that all maps can have fire sale in them, again only
//  with the custom power ups option toggled on."*
//
//  🌟 THE FIRST HALF WAS ALREADY SHIPPING, and that was checked before writing
//  anything. zmqol_enable_fire_sale() (server, :9356) and its exact client twin
//  in zm_expanded.csc have carried Fire Sale on zm_transit and zm_highrise since
//  v1.54.0 - the two maps stock leaves it out of. Measured again against the
//  dump: include_powerup( "fire_sale" ) is called by zm_nuked:720, zm_prison:947,
//  zm_buried:1279 and zm_tomb:1173, on both the .gsc and the .csc side, and by
//  neither transit nor highrise. So "all maps can have fire sale" is already
//  true; the ONLY thing missing was the user's second clause - the row.
//
//  🛑 THE ROW IS ENFORCED IN THE DROP PREDICATE, NEVER AT REGISTRATION. Gating
//  include_powerup() would move a registerclientfield and that is exactly the
//  EXE_CLIENT_FIELD_MISMATCH this mod already shipped once - see the block above
//  zmqol_enable_zombie_blood, and the long client-side write-up above
//  zm_expanded.csc::zmqol_enable_fire_sale(). Both sides register
//  ( "toplayer", "powerup_fire_sale", 1, 2, "int" ) as a side effect of the
//  include LIST, so the two lists must stay identical no matter what this row
//  says. Re-pointing the predicate touches nothing that is registered.
//
//  🌟 THE BIT BUDGET IS NOT A CONCERN HERE, and that is measured rather than
//  hoped: per-map clientfield dumps give toplayer totals of 38 (transit classic)
//  and 33 (die rise) against Buried's 63, Origins' 61 and Mob's 50 - all of which
//  already carry powerup_fire_sale. toplayer is plainly not a 32-bit-capped set,
//  and the two maps being changed sit at the LOW end of the shipped range.
//
//  🛑 THE MAP GATE IS NOT COSMETIC. On zm_nuked / zm_prison / zm_buried / zm_tomb
//  Fire Sale is STOCK, so turning CUSTOM POWER-UPS off there must not remove it -
//  that would be the row deleting vanilla behaviour, which is the same mistake
//  the Blood Money block above documents for Origins. This only re-points the
//  predicate on the two maps where this mod is the reason Fire Sale exists.
//
//  📝 v2.7.3 - THIS PARAGRAPH USED TO SAY ALL THREE OF STOCK'S REFUSALS STILL
//  APPLY. Two of them do. func_should_drop_fire_sale() refuses while a Fire Sale
//  is already running, while level.chest_moves < 1, and while
//  level.disable_firesale_drop is set - and the middle one is now deliberately
//  NOT applied, because on a static-box survival location chest_moves can never
//  reach 1 and it blocked the drop for the whole game. See the banner over
//  zmqol_fs_should_drop() for the measurement.
// ============================================================================
// ============================================================================
//  zmqol_fs_should_drop  -  FIRE SALE ON EVERY MAP, INCLUDING THE STATIC-BOX
//                           SURVIVAL LOCATIONS                      (v2.7.3)
//
//  User, 2026-08-29: *"when my 'custom power-ups' setting is enabled, fire sale
//  must be able to drop on EVERY zombies map - including Town and the other
//  Green Run / Tranzit survival maps that don't get fire sales by default."*
//
//  -- WHY TOWN NEVER GOT ONE, root-caused rather than guessed -----------------
//  This used to delegate straight to stock's predicate, which is
//  (_zm_powerups.gsc:2705, from the Core dump):
//
//      if ( level.zombie_vars["zombie_powerup_fire_sale_on"] == 1 ||
//           level.chest_moves < 1 ||
//           isdefined( level.disable_firesale_drop ) && level.disable_firesale_drop )
//          return false;
//
//  🌟 `level.chest_moves < 1` is the whole bug. chest_moves is incremented in
//  exactly one place - _zm_magicbox.gsc:1388, inside the "joker" branch that
//  flies the box away - and the box only flies to a chest whose
//  script_noteworthy is "move<n+1>" (:787). Town, Farm, Bus Depot and Diner have
//  ONE box location, so the box can never move, so chest_moves is 0 for the whole
//  game, so stock's predicate returns false forever. The include and the powerup
//  registration were both already correct; the drop could simply never fire.
//
//  So the chest_moves clause is dropped here and stock's other two refusals are
//  kept verbatim. A box that never moves is not a reason to withhold a Fire Sale
//  - it just means the one box goes to 10 points, which is the whole point of the
//  power-up on a single-box map.
//
//  📝 `level.chests` is still required to be non-empty: a Fire Sale on a map with
//  no mystery box at all would be a dud drop, and that IS worth refusing.
//
//  🛑 NATIVE FIRE SALE MAPS ARE NOT TOUCHED BY ANY OF THIS, which is the
//  constraint the user set. zmqol_fire_sale_custom_gate() only re-points
//  func_should_drop_with_regular_powerups on zm_transit and zm_highrise - the two
//  maps where this mod is the reason Fire Sale exists at all. zm_nuked,
//  zm_prison, zm_buried and zm_tomb keep stock's predicate byte-for-byte, so
//  turning CUSTOM POWER-UPS off cannot delete vanilla behaviour there.
//
//  Setting OFF -> returns false on those two maps -> vanilla exactly.
// ============================================================================
zmqol_fs_should_drop()
{
    if ( !zmqol_custom_powerups_enabled() )
        return false;

    //  ---- stock's refusals, minus the static-box trap ----
    if ( level.zombie_vars[ "zombie_powerup_fire_sale_on" ] == 1 )
        return false;

    if ( isdefined( level.disable_firesale_drop ) && level.disable_firesale_drop )
        return false;

    //  no box, no point
    if ( !isdefined( level.chests ) || level.chests.size < 1 )
        return false;

    return true;
}

zmqol_fire_sale_custom_gate()
{
    map = getDvar( "mapname" );

    //  The same two maps zmqol_enable_fire_sale() names, for the same reason.
    if ( map != "zm_transit" && map != "zm_highrise" )
        return;

    //  Polls for the struct rather than assuming an order, exactly as
    //  zmqol_blood_money_natural_drop() does: _zm_powerups::init() is reached
    //  from _zm::init(), threaded by the MAP's main(), so this init is not
    //  ordered against it. Capped at 30 seconds so a map that never registers
    //  the powerup cannot leave a thread spinning all game.
    for ( i = 0; i < 600; i++ )
    {
        if ( isdefined( level.zombie_powerups ) &&
             isdefined( level.zombie_powerups[ "fire_sale" ] ) )
        {
            level.zombie_powerups[ "fire_sale" ].func_should_drop_with_regular_powerups =
                ::zmqol_fs_should_drop;
            return;
        }

        wait 0.05;
    }
}

// ============================================================================
//  BONFIRE SALE  -  "Five"'s Pack-a-Punch sale, under CUSTOM POWER-UPS
//                                                                   (v2.12.0)
//
//  User, 2026-09-05: *"add the bonfire sale power up from the t6 declassified
//  mod into my mod as apart of the custom power ups option."*  Their context:
//  it comes from Five, dropped by the Pentagon Thief when he is killed before
//  he steals a weapon.
//
//  🌟 IT IS ALREADY IN BO2. NOTHING ABOUT THE BEHAVIOUR IS WRITTEN HERE.
//  Bonfire Sale is complete, shipped, dormant core T6 code - every piece of it,
//  on both sides, on every map. Verified line by line in the stock dump:
//
//    _zm_powerups.gsc:101   add_zombie_powerup( "bonfire_sale",
//                             "zombie_pickup_bonfire", &"ZOMBIE_POWERUP_MAX_AMMO",
//                             ::func_should_never_drop, 0, 0, 0, undefined,
//                             "powerup_bon_fire", "zombie_powerup_bonfire_sale_time",
//                             "zombie_powerup_bonfire_sale_on" );
//    _zm_powerups.csc:11    add_zombie_powerup( "bonfire_sale", "powerup_bon_fire" );
//    _zm_powerups.gsc:1043  case "bonfire_sale": level thread start_bonfire_sale( self );
//                                               players[i] thread powerup_vo( "firesale" );
//    _zm_powerups.gsc:1182  start_bonfire_sale() - 30 s, zmb_double_point_loop
//                             while it runs, zmb_points_loop_off at the end.
//    _zm_perks.gsc:682      vending_weapon_upgrade_cost() ALREADY waits on
//                             "powerup bonfire sale" and drops Pack-a-Punch from
//                             5000 to 1000 (attachments 2000 -> 1000), restoring
//                             both on "bonfire_sale_off".
//
//  So this is three things and no invention: switch the power-up on
//  (include_powerup), let it drop (the predicate re-point every custom power-up
//  in this mod uses), and teach the mod's OWN Pack-a-Punch trigger about the
//  sale, because stock's discount only reaches stock's trigger. The 5000 -> 1000
//  number is Treyarch's, not a choice made here.
//
//  🛑 THE ART WAS THE ONLY THING MISSING, and it had to be shipped. Unlinker
//  --list over all eight zombies fastfiles (zm_transit, zm_nuked, zm_highrise,
//  zm_prison, zm_buried, zm_tomb, common_zm, patch_zm), 2026-09-05:
//        xmodel   zombie_pickup_bonfire   absent from every one
//        material zom_icon_bonfire        absent from every one
//  add_zombie_powerup() precaches the model for every INCLUDED power-up, so
//  including it without the model is fatal at load - the trap Fire Sale and
//  Blood Money both hit. Both assets now ship in mod.ff; see
//  zone_source\mod_bonfire.zone and zone_source\bonfire_donor\.
//
//  🌟 AND IT FIXES A STOCK ERROR ON THE WAY. _zm_powerups.gsc:30 calls
//  precacheshader( "zom_icon_bonfire" ) unconditionally on every map, so retail
//  BO2 prints  Could not load material "zom_icon_bonfire".  on every zombies
//  boot - six times in the user's own console_zm.log. Owning the name silences
//  it everywhere.
// ============================================================================
//  zmqol_bonfire_sale_enabled  -  WHICH MAPS, AND WHY EACH ONE
//
//  🛑 THE CLIENT TWIN IS zm_expanded.csc::zmqol_bonfire_sale_enabled() AND IT
//  MUST AGREE MAP FOR MAP. include_powerup() decides whether
//  add_zombie_powerup() survives its early-return, and that call registers
//  toplayer/powerup_bon_fire (2 bits) on BOTH sides. Disagree on any map and
//  every player is dropped with EXE_CLIENT_FIELD_MISMATCH before it starts.
//
//  zm_prison - EXCLUDED: the toplayer clientfield set is FULL. Mob classic is
//  zm_buried   50 stock bits and this mod's additions put it at 63; Buried
//              classic is the fullest map in the game at 63 stock and v2.9.30
//              already gave back all five of the mod's bits to get it there. 63
//              is the only total ever seen to boot (ERROR_CATALOGUE section 2:
//              63 boots, 66 fails, 71 fails), so there is no room for 2 more on
//              either map, and taking them would stop the map loading outright.
//              🛑 Do NOT "just try it" - that failure is fatal and silent about
//              its real cause (the field named in the error is whichever asks
//              last, usually a stock one).
//
//  zm_transit  - INCLUDED. 38 stock toplayer bits on classic and 27 on every
//  zm_highrise   survival location; Die Rise classic is 33; Nuketown is 18, the
//  zm_nuked      emptiest map in the game. Counting this mod's own additions in
//                puts them near 54 / 56 / 40, so all three have real headroom.
//
//  🛑 NUKETOWN WAS WRONGLY EXCLUDED IN v2.12.0, and the mistake is worth keeping
//  written down because the measurement LOOKED conclusive. v2.12.0 grepped the
//  map's static mapents (T6-Data-Archive ZM\Mapents\zm_nuked.d3dbsp) for
//  script_noteworthy "specialty_weapupgrade", found ZERO against 1 on Origins
//  and Die Rise and 3 on TranZit, and concluded Nuketown has no Pack-a-Punch.
//  The user corrected it, and they are right: NUKETOWN BUILDS ITS PERK MACHINES
//  FROM SCRIPT, NOT FROM MAPENTS -
//        zm_nuked_perks.gsc:37-40   level.nuked_perks[4].model =
//                                     "p6_anim_zm_buildable_pap";
//                                   level.nuked_perks[4].script_noteworthy =
//                                     "specialty_weapupgrade";
//                                   level.nuked_perks[4].turn_on_notify =
//                                     "Pack_A_Punch_on";
//        zm_nuked_perks.gsc:46/100  level.override_perk_targetname =
//                                     "zm_perk_machine_override";
//  so the machine is the fifth entry of the perk-arrival vehicle and its struct
//  never existed in the .d3dbsp at all. The override_perk_targetname branch is
//  right there in _zm_perks::perk_machine_spawn_init() and v2.12.0 had already
//  read it. 🛑 A GREP THAT FINDS NOTHING IS NOT A MEASUREMENT UNTIL YOU HAVE
//  ASKED WHETHER THE THING COULD EXIST SOMEWHERE THE GREP CANNOT SEE.
//  📝 zmqol_bs_pap_usable() would have declined the drop by itself if Nuketown
//  really had no machine, so the gate was never the risk - only the 2 wasted
//  bits, and Nuketown has 45 spare.
// ============================================================================
//  🌟 v2.17.31 - MOB AND BURIED ARE ONLY FULL IN CLASSIC, AND SURVIVAL IS
//  WHERE THE USER PLAYS. Reported 2026-09-21: twenty rounds of Docks survival
//  with no Bonfire Sale. The exclusion above was written per MAP, and the
//  measurement behind it was taken on the classic dumps only. Re-counted from
//  T6-Data-Archive\ZM\Clientfields with
//      awk '$1=="toplayer"{s+=$4} END{print s}'
//  over every zm_prison and zm_buried dump, stock toplayer bits are:
//
//      63  zm_buried  zclassic processing     <- the map the ceiling came from
//      50  zm_prison  zclassic  prison
//      41  zm_prison  zgrief    cellblock
//      40  zm_buried  zgrief    street
//      38  zm_prison  zgrief    docks
//      34  zm_prison  ZSTANDARD prison        <- survival
//      24  zm_buried  ZSTANDARD processing    <- survival
//
//  So survival on Mob is 34, not 50, and on Buried it is 24, not 63 - sixteen
//  and thirty-nine bits below the classic totals that closed the door. Against
//  the ERROR_CATALOGUE's proven-safe 63, with this mod's own additions counted
//  at their worst (perk_marathon 2, perk_tombstone 2, vulture 1+1+5,
//  perk_electric_cherry 1, perk_chugabud 1, deadshot_perk 1, whoswho 1+1,
//  overlay_slot 1 + overlay_lerp 5 = 22) the survival totals land at 56 and 46
//  WITH this power-up's 2 bits included. Classic and grief are left excluded
//  exactly as they were - grief on Cell Block would be 41 + 22 + 2 = 65, past
//  the only total ever seen to boot.
//
//  🛑 THE TEST MUST BE ONE BOTH VMs CAN ANSWER IDENTICALLY, or this becomes the
//  EXE_CLIENT_FIELD_MISMATCH the twin's banner warns about. is_survival() is
//  server-only (_zm_utility.gsc:382; the .csc defines is_classic and
//  is_encounter and not this one), so the dvar it reads is written out here
//  literally instead. ui_zm_gamemodegroup is the same dvar stock's own
//  is_classic() reads on BOTH sides (_zm_utility.gsc:23 / _zm_utility.csc:392),
//  which is the pattern zmqol_enable_electric_cherry() already depends on.
// ============================================================================
zmqol_bonfire_sale_enabled()
{
    map = getDvar( "mapname" );

    //  toplayer clientfield set is full on these two in CLASSIC and GRIEF only.
    if ( ( map == "zm_prison" || map == "zm_buried" ) && getDvar( "ui_zm_gamemodegroup" ) != "zsurvival" )
        return 0;

    return 1;
}

// ============================================================================
//  zmqol_enable_bonfire_sale  -  called from main()
//
//  🛑 TIMING, and it is the same argument as Fire Sale's and Blood Money's.
//  include_powerup() only writes level.zombie_include_powerups[name];
//  _zm_powerups::init() reads it later when it calls add_zombie_powerup for each
//  entry. main() is inside Plutonium's precache window and runs ahead of every
//  ::init() and of the map's own main(), so writing here is early enough. It is
//  purely additive (include_zombie_powerup creates the array only if undefined
//  and never clears it), so a map populating its own list afterwards cannot
//  clobber this entry.
//
//  🛑 THIS IS GATED ON A MAP, NEVER ON THE CUSTOM POWER-UPS DVAR. Gating a
//  registration on a live option is what caused EXE_CLIENT_FIELD_MISMATCH in
//  v1.99.83; the dvar is read in the DROP PREDICATE instead, where it takes
//  effect on the very next drop and moves no clientfield. See
//  zmqol_custom_powerups_enabled().
// ============================================================================
zmqol_enable_bonfire_sale()
{
    if ( !zmqol_bonfire_sale_enabled() )
        return;

    maps\mp\zombies\_zm_utility::include_powerup( "bonfire_sale" );
}

// ============================================================================
//  zmqol_bs_pap_usable  -  "is there a Pack-a-Punch worth having a sale on"
//
//  The Bonfire Sale equivalent of stock's own Fire Sale gate, which refuses the
//  drop while the mystery box has never moved (func_should_drop_fire_sale, the
//  level.chest_moves clause). A sale on a machine nobody can reach is a wasted
//  drop, and stock declines those rather than spending one.
//
//  Everything here is a CORE signal, so it is safe from a root script and needs
//  no per-map special case:
//    - level.zombiemode_using_pack_a_punch  set by all six maps' main().
//    - getent( "vending_packapunch", "targetname" )  the machine itself.
//      🌟 It is spawned at runtime by _zm_perks::perk_machine_spawn_init() from
//      the map's "zm_perk_machine" structs, so this is true wherever a machine
//      really exists and false on the survival locations that have none - which
//      is why no location list is hard-coded here.
//    - flag( "power_on" )  flag_init'd in core _zm.gsc:1133, so it exists on
//      every map, and every map sets it on its own power path. On Origins it is
//      set by zm_tomb_capture_zones::pack_a_punch_enable() at the exact moment
//      the Pack-a-Punch trigger is switched on, which is precisely right.
//
//  🛑 TRANZIT CLASSIC ALSO HAS TO BUILD IT. Power is not enough there - the
//  machine is a buildable, and qol_instant_pap.gsc's qol_ipap_trigger() waits on
//  "pap_built" for that same reason.
// ============================================================================
zmqol_bs_pap_usable()
{
    if ( !isdefined( level.zombiemode_using_pack_a_punch ) || !level.zombiemode_using_pack_a_punch )
        return false;

    if ( !isdefined( getent( "vending_packapunch", "targetname" ) ) )
        return false;

    if ( !flag( "power_on" ) )
        return false;

    if ( getDvar( "mapname" ) == "zm_transit" && is_classic() )
    {
        if ( !isdefined( level.buildables_built ) || !is_true( level.buildables_built[ "pap" ] ) )
            return false;
    }

    return true;
}

// ============================================================================
//  zmqol_bs_should_drop  -  the drop predicate, and where CUSTOM POWER-UPS is
//                           enforced
//
//  Stock hands Bonfire Sale ::func_should_never_drop, which is why it has never
//  appeared outside Five: get_valid_powerup() calls this function on every drop
//  attempt (_zm_powerups.gsc:337) and skips the power-up when it returns false.
//  Re-pointing that ONE struct field is the whole "make it drop" change - the
//  same route Blood Money and Fire Sale already use here.
//
//  Because it is read live, the CUSTOM POWER-UPS row takes effect on the very
//  next drop with no registration moving underneath it.
// ============================================================================
zmqol_bs_should_drop()
{
    if ( !zmqol_custom_powerups_enabled() )
        return false;

    //  One sale at a time - stock's own first refusal for Fire Sale.
    if ( isdefined( level.zombie_vars ) &&
         isdefined( level.zombie_vars[ "zombie_powerup_bonfire_sale_on" ] ) &&
         level.zombie_vars[ "zombie_powerup_bonfire_sale_on" ] == 1 )
        return false;

    if ( !zmqol_bs_pap_usable() )
        return false;

    return true;
}

// ============================================================================
//  zmqol_bonfire_sale_custom_gate  -  the re-point itself
//
//  🛑 MUST RUN AFTER _zm_powerups::init(), because that is what creates the
//  struct. This init() is not ordered against it (_zm_powerups::init() is
//  reached from _zm::init(), threaded by the MAP's main()), so it polls for the
//  struct rather than assuming - identical to zmqol_fire_sale_custom_gate() and
//  zmqol_blood_money_natural_drop() above. Capped at 30 s so a map that never
//  registers the power-up cannot leave a thread spinning all game.
// ============================================================================
zmqol_bonfire_sale_custom_gate()
{
    if ( !zmqol_bonfire_sale_enabled() )
        return;

    for ( i = 0; i < 600; i++ )
    {
        if ( isdefined( level.zombie_powerups ) &&
             isdefined( level.zombie_powerups[ "bonfire_sale" ] ) )
        {
            level.zombie_powerups[ "bonfire_sale" ].func_should_drop_with_regular_powerups =
                ::zmqol_bs_should_drop;
            return;
        }

        wait 0.05;
    }
}

// ============================================================================
//  zmqol_bs_announcer_watch  -  THE ANNOUNCER LINE BONFIRE SALE NEVER HAD
//                                                                    (v2.12.6)
//
//  User, 2026-09-05: *"i gave myself the bonfire sale power up and it had no
//  announcer line, so make sure thats sorted out."*
//
//  🌟 THE SILENCE IS STOCK'S, AND IT IS TWO OMISSIONS, NOT ONE. Both read out
//  of the 2,093-file dump, neither inferred:
//
//    1. _zm_audio_announcer::init() registers ten announcer voxes at :13-22 -
//       carpenter, insta_kill, double_points, nuke, full_ammo, fire_sale,
//       minigun, zombie_blood, boxmove, dogstart. There is NO createvox for
//       "bonfire_sale". _zm_powerups.gsc:1147 announces every grabbed power-up
//       generically with leaderdialog( self.powerup_name ), so for this one it
//       asks for a key nobody registered and returns having played nothing.
//    2. start_fire_sale() opens with
//           level thread _zm_audio_announcer::leaderdialog( "fire_sale" )
//       (_zm_powerups.gsc:1167). start_bonfire_sale() (:1182) has no equivalent
//       - it goes straight to the loop sound and the 30 s timer.
//
//  What DOES fire is only the character line, powerup_vo( "firesale" ) at
//  :1042 - a survivor shouting "fire sale" 2-2.5 s after the grab. The
//  announcer half was never wired up at all. That character line is left
//  exactly as stock has it; this adds the missing half in front of it, which is
//  the same pairing a real Fire Sale already gives.
//
//  🌟 AND THE REAL RECORDING IS ALREADY IN BLACK OPS II. BO1 always had this
//  line - <BO1>\raw\maps\_zombiemode_audio.gsc:33
//      level.devil_vox["powerup"]["bonfire_sale"] = "bonfiresale";
//  under prefix "zmb_vox_ann_", i.e. zmb_vox_ann_bonfiresale. That alias is
//  shipped in T6: it is in zmb_highrise.english (Die Rise), 3.0 s of real
//  audio (48 kHz stereo, 275,636 B FLAC), and grep says it has ZERO references
//  across all 2,093 stock scripts - recorded, shipped, never called. The same
//  find as the Death Machine line this mod already re-ships, out of the same
//  bank and the same english\sound\vox\scripted\zmb\announcer\ folder, and its
//  60 alias fields are byte-identical to that row's. Nothing here is invented.
//  📝 The dumped death_machine payload compares byte-identical to the copy
//  already in sound\zmb\qol\, so this exact route is proven, not assumed.
//
//  Ships as vox_zmba_qol_powerup_bonfire_sale, plus the vox_zmba_sam_ twin that
//  Nuketown's announcer prefix needs and the _0 variant of each - the same
//  four-row shape zmqol_register_announcer_vox() documents above, all four
//  pointing at the one payload.
//
//  🛑 DELIBERATELY NOT REGISTERED WITH createvox. That would route the line
//  through leaderdialogonplayer(), which drops it outright whenever
//  self.zmbdialogactive is already 1 - the bug that silenced Blood Money on
//  Nuketown (v2.8.8). zmqol_play_announcer_line() is the route that was
//  measured to work; registering the vox as well would give the line twice on
//  the grabs where stock's path does fire.
//
//  🛑 HOOKED ON THE NOTIFY, NOT BY replaceFunc. start_bonfire_sale() opens with
//  level notify( "powerup bonfire sale" ) (:1184), and that notify appears
//  nowhere else in the dump, so waiting on it fires exactly once per sale and
//  copies none of Treyarch's body - there is nothing here that can drift out of
//  step with stock. The thread re-arms in the same frame it wakes, so a second
//  Bonfire Sale grabbed during the first is announced too, which is what stock's
//  own announce-on-every-grab path at :1147 would have done.
// ============================================================================
zmqol_bs_announcer_watch()
{
    if ( !zmqol_bonfire_sale_enabled() )
        return;

    level endon( "end_game" );

    for ( ;; )
    {
        level waittill( "powerup bonfire sale" );

        //  The probe that tells a boot apart from a silent alias. Same shape as
        //  the [zm_qol] vox: line above; the prefix is certainly set by now,
        //  because a power-up cannot be grabbed before the announcer inits.
        if ( isdefined( game[ "zmbdialog" ] ) && isdefined( game[ "zmbdialog" ][ "prefix" ] ) )
        {
            str_alias = game[ "zmbdialog" ][ "prefix" ] + "_qol_powerup_bonfire_sale";

            println( "[zm_qol] bonfire sale: announcer " + str_alias + "  exists=" +
                     soundexists( str_alias ) + "  _0=" + soundexists( str_alias + "_0" ) );
        }
        else
            println( "[zm_qol] bonfire sale: announcer SKIPPED - game[zmbdialog][prefix] is not set" );

        level thread zmqol_play_announcer_line( "qol_powerup_bonfire_sale" );
    }
}

zmqol_enable_blood_money()
{
    //  v1.99.91 - unconditional. include_powerup() decides whether stock's own
    //  add_zombie_powerup( "bonus_points_player", ... ) survives its include-list
    //  early-return (_zm_powerups.gsc:419), so gating it moved a registration.
    //  bonus_points_player carries no client_field_name, so it was not the field
    //  that killed the boots - but the rule is now absolute for every powerup in
    //  this mod, because the next one added might.
    maps\mp\zombies\_zm_utility::include_powerup( "bonus_points_player" );
}

// ============================================================================
//  zmqol_blood_money_natural_drop  -  the "spawn naturally" half
//
//  Stock hands Blood Money ::func_should_never_drop, so it is excluded from the
//  ordinary rotation on every map - which is why Origins can only produce it
//  from a dig site. get_valid_powerup() picks the next powerup and skips any
//  whose function returns false:
//      _zm_powerups.gsc:337
//      if ( ![[ level.zombie_powerups[powerup].func_should_drop_with_regular_powerups ]]() )
//          { powerup = get_next_powerup(); continue; }
//  Re-pointing that ONE struct field to core's own ::func_should_always_drop -
//  the same function nuke, insta_kill, double_points and full_ammo use - puts it
//  in the normal zombie-kill rotation everywhere, Origins included. Origins' dig
//  sites are untouched and keep working; this only adds the natural drop the
//  user asked for.
//
//  🛑 A POINTER RE-POINT, NOT A replaceFunc - the behaviour is reached through
//  level.zombie_powerups[...], which is CLAUDE.md §4 failure mode 2, and its
//  prescribed fix. The same route v1.62.8 used for Electric Cherry.
//
//  🛑 IT MUST RUN AFTER _zm_powerups::init(), because that is what creates the
//  struct (add_zombie_powerup, :424-441). Our init() is not ordered against it -
//  _zm_powerups::init() is reached from _zm::init(), threaded by the MAP's
//  main() - so this polls for the struct instead of assuming. The wait is capped
//  so a map that somehow never registers the powerup cannot leave a thread
//  spinning for the whole game.
//
//  📝 Only bonus_points_player is touched. bonus_points_team keeps
//  ::func_should_never_drop, exactly as stock leaves it - Origins' dig awards the
//  player variant (zm_tomb_dig.gsc:442) and the team variant belongs to Grief's
//  own scripted awards.
// ============================================================================
zmqol_blood_money_natural_drop()
{
    //  v1.99.91 - the re-point happens on every map now, but it points at
    //  ::zmqol_bm_should_drop, which returns 0 while CUSTOM POWER-UPS is off.
    //  That is Blood Money's vanilla behaviour (stock hands it
    //  ::func_should_never_drop), reached without changing when anything is
    //  registered. Origins' dig sites never went through this predicate and are
    //  untouched either way.
    for ( i = 0; i < 600; i++ )
    {
        if ( isdefined( level.zombie_powerups ) &&
             isdefined( level.zombie_powerups[ "bonus_points_player" ] ) )
        {
            level.zombie_powerups[ "bonus_points_player" ].func_should_drop_with_regular_powerups =
                ::zmqol_bm_should_drop;
            return;
        }

        wait 0.05;
    }
}

// ============================================================================
//  ZOMBIE BLOOD  -  Origins' power-up, on the five maps that never had it
//  (v1.65.0)  -  SERVER HALF
//
//  User, 2026-08-11: *"build zombie blood and the three announcer lines."*
//
//  30 seconds of self.ignoreme = 1 - every zombie walks straight past you - plus
//  a red screen filter, the zm_powerup_zombie_blood visionset, a first-person
//  particle effect on the camera, a third-person effect linked to your eyeball
//  tag, your player model swapped for an Origins zombie, a looping sound, the
//  announcer, and the solo-HUD countdown. Ends early if you go down. Cannot be
//  picked up in last stand.
//
//  🛑 THIS IS A PORT, NOT A REDESIGN. Every function below is
//  maps\mp\zombies\_zm_powerup_zombie_blood.gsc (Origins, 196 lines) with the
//  names prefixed and the four sound aliases repointed at this mod's own copies.
//  Nothing else is changed - no re-balanced duration, no "fixed" edge case. See
//  [[zm-qol-port-never-tune]] and QUEUE.md's standing rule.
//
//  🛑 GATED OFF zm_tomb. Origins registers this power-up itself
//  (level.level_specific_init_powerups = ::tomb_powerup_init), and running ours
//  there too would register player_zombie_blood_fx twice - "already registered"
//  is fatal. It also keeps Origins a clean A/B baseline, the same discipline
//  used for Electric Cherry and Who's Who.
//
//  ── WHY EVERY PIECE SITS WHERE IT SITS ──────────────────────────────────────
//
//  zmqol_enable_zombie_blood()          main(), from the tail of perks()
//      registerclientfield + include + add_zombie_powerup + precaches. Clientfields
//      must be registered before the first snapshot, so this cannot move to init()
//      - the same constraint zmqol_enable_vulture() documents.
//
//      🛑 add_zombie_powerup() INDEXES level.zombie_powerup_array, which
//      _zm_powerups::init() creates at :89-90 - later than main(). So the two
//      arrays are created here first if absent. That is safe in both directions:
//      stock's own lines are `if ( !isdefined( ... ) )` guarded, so it will not
//      wipe ours, and ours will not wipe its.
//
//  zmqol_register_zombie_blood_visionsets()   init()
//      vsmgr_register_info() asserts on level.vsmgr_initializing and level.vsmgr
//      does not exist during main() - [[t6-visionset-registration-timing]]. Same
//      split, for the same reason, as zmqol_register_divetonuke_visionset() and
//      zmqol_register_vulture_visionset() above.
//
//  🌟 THE TWO SIDES DO NOT HAVE TO REGISTER IN THE SAME ORDER, and that is
//  measured, not hoped: this mod already registers Vulture's eight clientfields
//  from main() on the server and from _zm_perks::init() on the client, and
//  Vulture ships and boots on five maps. Only the SET of names, versions, sets
//  and bit widths has to agree. (Visionset slots are immune by construction -
//  _visionset_mgr sorts its names alphabetically before assigning slot_index.)
//
//  ── COST, against the ceiling that was settled by a boot ─────────────────────
//
//      allplayers  +1   player_zombie_blood_fx
//      toplayer    +2   powerup_zombie_blood (add_zombie_powerup always takes 2)
//      toplayer    +1   visionset_lerp widens 3 -> 4 (lerp_step_count 15)
//      toplayer  +0-2   visionset_slot / overlay_slot may each gain a bit
//
//  The old arithmetic that said this would not fit on the classic maps is
//  WITHDRAWN. The user booted Buried CLASSIC on v1.64.0 - the fullest map in the
//  game at 63 toplayer bits stock, ~68 under this mod - and it played, with zero
//  EXE_CLIENT_FIELD / "out of space" lines in an 8,567-line log. The ceiling is
//  above the mod's real Buried total, so this fits everywhere.
//
//  ── WHAT IS DELIBERATELY NOT PORTED, and why that is parity ─────────────────
//
//  🛑 THE CHARACTER REACTION LINES ARE NOT SHIPPED. Origins records twelve -
//  vox_plr_0..3_powerup_zombie_blood_0..2 - and create_and_play_dialog() picks
//  one by the PLAYER'S CHARACTER INDEX. Shipping them would make Misty, Marlton,
//  Russman and Stuhlinger speak in the Origins cast's voices on every other map.
//  That is not the original behaviour, it is a new and worse one. With no vox
//  registered the call below returns silently, which is exactly what stock does
//  for any unregistered dialog type. The announcer line, which is character-
//  neutral, IS ported - see zmqol_register_announcer_vox().
//
//  📝 level.a_zombie_blood_entities stays empty off Origins. It holds the hidden
//  dig sites Zombie Blood reveals, and no other map has any - so the reveal loops
//  below iterate zero times. Nothing is missing; there is nothing to reveal.
//
//  📝 c_zom_tomb_german_player_fb is ONE model for all four characters - Origins
//  passes the same string regardless of who you are - so the port turns everyone
//  into an Origins German zombie. That is what the original does, so that is what
//  ships. (Unlike the VO above, the model is not character-keyed, so there is no
//  wrong-voice equivalent here.)
// ============================================================================
zmqol_zombie_blood_enabled()
{
    // Origins ships the power-up itself.
    if ( getDvar( "mapname" ) == "zm_tomb" )
        return 0;

    // ========================================================================
    //  🛑 v1.65.2 - MOB OF THE DEAD CANNOT AFFORD IT. Measured from the user's
    //  own failed boot, not inferred:
    //
    //      Trying to assign 3 bits for netfield visionset_slot
    //      but Client Field Set toplayer is out of space.      (zm_prison, zclassic)
    //
    //  🌟 READ THE FIELD NAME CORRECTLY. visionset_slot is registered LAST, by
    //  _visionset_mgr::finalize_type_clientfields(). It is not the culprit - it
    //  is simply whoever asked when the space had already gone (ERROR_CATALOGUE
    //  §2). Mob is the tightest toplayer map this mod touches once its additions
    //  are counted, even though its STOCK total (50) is far from the worst.
    //
    //  WHAT THE MOD PUTS ON MOB'S toplayer SET, and why it adds up so fast:
    //      perk_additional_primary_weapon  +2   Mule Kick
    //      perk_marathon                   +2   Stamin-Up
    //      perk_tombstone                  +2
    //      perk_dive_to_nuke               +1   PhD
    //      vulture_perk_toplayer           +1
    //      sndVultureStink                 +1
    //      visionset_lerp                  +3   NEW FIELD - stock Mob has none,
    //                                           because every stock Mob visionset
    //                                           has lerp_step_count 1. PhD's 5
    //                                           steps create it.
    //      overlay_lerp                    +5   NEW FIELD, same reason - created
    //                                           solely by Vulture's 31-step stink
    //                                           overlay.
    //      visionset_slot / overlay_slot   +2   both widen by one
    //  ...against only -1 freed (deadshot_perk, dropped by init_client_flags).
    //
    //  🌟 THE TWO *_lerp FIELDS ARE THE EXPENSIVE PART AND THEY ARE INVISIBLE IN
    //  ANY PER-MAP DUMP, because they do not exist in stock Mob at all. Eight
    //  bits appear out of nowhere the moment one high-step visionset or overlay
    //  is added to a map whose own effects all use a single step. Check for that
    //  before adding a visionset to any map, not just the bit count of the field
    //  you meant to add.
    //
    //  Zombie Blood's own share is only 3 of that: powerup_zombie_blood (2) plus
    //  widening visionset_lerp from 3 to 4 (its 15 lerp steps). Removing it frees
    //  exactly those 3.
    //
    //  ⚠️ 3 BITS MAY NOT BE THE WHOLE SHORTFALL, and that is stated rather than
    //  hidden. Mob appears in exactly ONE of the eleven kept console logs - the
    //  failed boot above - so it has not booted with this mod in the whole
    //  retained history. It has been at or over the line since v1.55.0 put
    //  Vulture on it; checkpoint 17's crash there was answered by dropping the
    //  5-bit vulture_perk_disease_meter and Mob was never re-booted to confirm.
    //  This change returns Mob to exactly its v1.64.0 state, which is unverified.
    //
    //  📝 IF MOB STILL FAILS, the next lever is Vulture, and it is justified on
    //  its own terms rather than as a budget raid: the perk ALREADY ships
    //  incomplete there (zmqol_vulture_has_disease_meter() returns 0 for
    //  zm_prison), which is the exact condition that took it off Origins in
    //  v1.59.0 - *"either the thing is added exactly how it'd work with its
    //  original implementation fully intact, no compromises, or you don't even
    //  bother"*. Turning it off on Mob frees 7 more bits (1 + 1 + the whole
    //  5-bit overlay_lerp, which no other Mob overlay needs). That is the user's
    //  call, not a change to make silently.
    //
    //  🛑 The client twin is zm_expanded.csc::zmqol_zombie_blood_enabled(). Both
    //  must agree or the toplayer set differs in width between the two sides and
    //  everyone is dropped with EXE_CLIENT_FIELD_MISMATCH.
    // ========================================================================
    if ( getDvar( "mapname" ) == "zm_prison" )
        return 0;

    // ========================================================================
    //  🛑 v2.9.30 - BURIED CANNOT AFFORD IT EITHER. Same mechanism as the Mob
    //  block above, measured from the user's failed boot 2026-09-01: Buried
    //  classic died at "Trying to assign 5 bits for netfield
    //  vulture_perk_disease_meter but Client Field Set toplayer is out of
    //  space" - stock's own field asking after the mod's additions had filled
    //  the set. Stock Buried classic is the fullest toplayer map in the game
    //  at 63 bits; Zombie Blood's share of the mod's 8-bit overage there is 3
    //  (powerup_zombie_blood 2 + widening visionset_lerp 3->4, its 15 lerp
    //  steps vs stock Buried's widest, PhD's 5). Full arithmetic in the
    //  Deadshot block inside perks().
    //
    //  🛑 The client twin is zm_expanded.csc::zmqol_zombie_blood_enabled().
    //  Both must agree or the toplayer set differs in width between the two
    //  sides and everyone is dropped with EXE_CLIENT_FIELD_MISMATCH.
    // ========================================================================
    if ( getDvar( "mapname" ) == "zm_buried" )
        return 0;

    return 1;
}

zmqol_enable_zombie_blood()
{
    if ( !zmqol_zombie_blood_enabled() )
        return;

    level.str_zombie_blood_model = "c_zom_tomb_german_player_fb";
    precachemodel( level.str_zombie_blood_model );

    registerclientfield( "allplayers", "player_zombie_blood_fx", 14000, 1, "int" );

    //  🛑🛑 v1.99.91 - THIS BLOCK IS NO LONGER GATED, AND MUST NEVER BE AGAIN.
    //  v1.99.83 wrapped it in `if ( zmqol_custom_powerups_enabled() )` believing
    //  add_zombie_powerup() only fills the drop table. IT ALSO REGISTERS THE
    //  CLIENTFIELD: _zm_powerups.gsc:446-452
    //      if ( isdefined( client_field_name ) )
    //          registerclientfield( "toplayer", client_field_name, ... 2, "int" );
    //  and the client half (zm_expanded.csc::zmqol_enable_zombie_blood) registers
    //  it UNCONDITIONALLY. So turning the row off desynchronised the two sides and
    //  every map died at load:
    //      "Clientfield 'powerup_zombie_blood' in set [toplayer] is not
    //       registered on the server"  -> EXE_CLIENT_FIELD_MISMATCH
    //  measured in console_zm.log on Nuketown, Buried, Die Rise and TranZit,
    //  2026-08-20. Origins and Mob were the only maps that still loaded, for the
    //  two reasons that prove the mechanism: Origins registers Zombie Blood
    //  itself in stock, and zmqol_zombie_blood_enabled() returns 0 on Mob, so on
    //  those two maps the two sides still agreed.
    //
    //  🌟 THE ROW IS NOW ENFORCED IN THE DROP PREDICATE (::zmqol_zb_should_drop),
    //  which is read live on every drop attempt. Registration is byte-identical
    //  with the row on and off - which is what the original comment below was
    //  trying to guarantee and what add_zombie_powerup silently broke.
    //
    //  🛑 THIS IS AN `if` BLOCK AND NOT AN EARLY `return` ON PURPOSE. Everything
    //  after it - the two vsmgr priorities - is read later in the same map load
    //  by zmqol_register_zombie_blood_visionsets(), which passes them straight
    //  into vsmgr_register_info(). Returning here would leave them undefined, so
    //  the visionset would register with a bad priority or not at all, and the
    //  number of registered visionsets is what sets visionset_slot's BIT WIDTH.
    //  Server and client disagreeing on that width is a silent desync that boots
    //  clean and then never shows the effect ([[t6-visionset-slot-silent-desync]]),
    //  or EXE_CLIENT_FIELD_MISMATCH outright. The registrations must be
    //  identical with the row on and off; only the drop changes.
    {
        maps\mp\zombies\_zm_utility::include_powerup( "zombie_blood" );

        //  See the block comment: add_zombie_powerup() writes into both of these
        //  and _zm_powerups::init() has not run yet. Its own creation lines are
        //  isdefined-guarded, so seeding them here cannot lose stock's entries.
        if ( !isdefined( level.zombie_powerup_array ) )
            level.zombie_powerup_array = [];

        if ( !isdefined( level.zombie_special_drop_array ) )
            level.zombie_special_drop_array = [];

        //  Arguments copied verbatim from _zm_powerup_zombie_blood.gsc:17. The
        //  hint string is genuinely &"ZOMBIE_POWERUP_MAX_AMMO" in stock -
        //  Treyarch reused Max Ammo's - and it is core-localized, so it resolves
        //  on every map.
        //  v1.99.91 - the drop predicate is OURS now, not core's
        //  ::func_should_always_drop. It returns always-drop while CUSTOM
        //  POWER-UPS is on and never-drop while it is off, read live, so the row
        //  can gate the drop without touching a single registration.
        maps\mp\zombies\_zm_powerups::add_zombie_powerup( "zombie_blood",
            "p6_zm_tm_blood_power_up",
            &"ZOMBIE_POWERUP_MAX_AMMO",
            ::zmqol_zb_should_drop,
            1, 0, 0, undefined,
            "powerup_zombie_blood",
            "zombie_powerup_zombie_blood_time",
            "zombie_powerup_zombie_blood_on" );

        maps\mp\zombies\_zm_powerups::powerup_set_can_pick_up_in_last_stand( "zombie_blood", 0 );

        maps\mp\zombies\_zm_utility::onplayerconnect_callback( ::zmqol_zb_init_player_vars );
    }

    if ( !isdefined( level.vsmgr_prio_visionset_zm_powerup_zombie_blood ) )
        level.vsmgr_prio_visionset_zm_powerup_zombie_blood = 15;

    if ( !isdefined( level.vsmgr_prio_overlay_zm_powerup_zombie_blood ) )
        level.vsmgr_prio_overlay_zm_powerup_zombie_blood = 16;
}

// ============================================================================
//  zmqol_register_zombie_blood_visionsets  -  the half that CANNOT run in main()
//
//  Priorities 15 (visionset) and 16 (overlay) are Origins' own. They were checked
//  against every priority any other map registers, because vsmgr_register_info()
//  asserts on a duplicate within a type:
//      visionset  15 zombie_blood | 17 cheat_bw | 20 transit_power_high_low
//                 120 zm_afterlife | 121 zm_electric_cherry | 123 zm_whos_who
//                 123 zombie_turned | 200 zm_audio_log | 400 zm_perk_divetonuke
//      overlay    16 zombie_blood | 20/21 zm_transit_burn | 50 screecher_blur
//                 60/61 trap_electrified/burn | 75 avogadro | 120 vulture_stink
//                 120 zm_afterlife_filter | 200 zombie_time_bomb
//  15 and 16 are used by nothing but Origins, and Origins is gated out.
//
//  lerp_step_count 15 on both, matching the client's two calls exactly - that
//  number is what sets visionset_lerp's and overlay_lerp's bit widths, so the
//  two sides disagreeing is the [CLIENT: 4 SERVER: 5] boot crash Vulture caused
//  twice.
// ============================================================================
zmqol_register_zombie_blood_visionsets()
{
    if ( !zmqol_zombie_blood_enabled() )
        return;

    //  Degrade to "not registered" rather than erroring out of init() if the
    //  ordering ever changes and _visionset_mgr::init() has not run yet.
    if ( !isdefined( level.vsmgr ) )
        return;

    level._effect[ "zombie_blood" ]     = loadfx( "maps/zombie_tomb/fx_tomb_pwr_up_zmb_blood" );
    level._effect[ "zombie_blood_1st" ] = loadfx( "maps/zombie_tomb/fx_zm_blood_overlay_pclouds" );

    level.a_zombie_blood_entities = [];
    array_thread( getentarray( "zombie_blood_visible", "targetname" ), ::zmqol_zb_make_entity );

    if ( isdefined( level.vsmgr[ "visionset" ] ) &&
         !( isdefined( level.vsmgr[ "visionset" ].info ) &&
            isdefined( level.vsmgr[ "visionset" ].info[ "zm_powerup_zombie_blood_visionset" ] ) ) )
    {
        //  🛑 v2.9.16 - steps 15 -> 1 (see the toplayer note over the PhD
        //  registration). Only reached on maps where zombie blood is NOT
        //  native - the isdefined guard above keeps Origins'/Buried's own
        //  15-step registration, so stock maps keep stock widths. Client twin:
        //  zm_expanded.csc, same guard, same 1.
        maps\mp\_visionset_mgr::vsmgr_register_info( "visionset", "zm_powerup_zombie_blood_visionset",
            14000, level.vsmgr_prio_visionset_zm_powerup_zombie_blood, 1, 1 );
    }

    if ( isdefined( level.vsmgr[ "overlay" ] ) &&
         !( isdefined( level.vsmgr[ "overlay" ].info ) &&
            isdefined( level.vsmgr[ "overlay" ].info[ "zm_powerup_zombie_blood_overlay" ] ) ) )
    {
        //  🛑 v2.9.22 - steps 7 -> 1 (v2.9.16 had 15 -> 7; not enough for
        //  Mob). At 1 step overlay_lerp is SKIPPED by the finalizer, matching
        //  stock Mob, which registers no lerp fields at all. The overlay
        //  snaps instead of fading on mod-ported maps; Origins keeps native
        //  15 via the guard above. Client twin in zm_expanded.csc carries the
        //  same 1.
        maps\mp\_visionset_mgr::vsmgr_register_info( "overlay", "zm_powerup_zombie_blood_overlay",
            14000, level.vsmgr_prio_overlay_zm_powerup_zombie_blood, 1, 1 );
    }
}

zmqol_zb_init_player_vars()
{
    self.zombie_vars[ "zombie_powerup_zombie_blood_on" ] = 0;
    self.zombie_vars[ "zombie_powerup_zombie_blood_time" ] = 30;
}

// ============================================================================
//  zmqol_zb_powerup  -  _zm_powerup_zombie_blood::zombie_blood_powerup(), ported
//
//  Reached from zmqol_pd_grab() in qol_powerup_dispatch.gsc (the
//  level._zombiemode_powerup_grab hook), which is where core's powerup_grab()
//  sends every power-up name it does not handle itself - _zm_powerups.gsc:1072,
//  the `default:` branch.
//
//  🛑 The only edits to stock's body are the three sound aliases, which are
//  Origins-only and are re-shipped under zmqol_ names through this mod's own
//  bank (soundbank\mod.all.aliases.additions.csv):
//      zmb_zombieblood_3rd_loop -> zmqol_zombieblood_3rd_loop
//  and, on the client, _start / _loop / _stop. A missing alias is SILENT, never
//  an error, so calling Origins' names here would have shipped a mute power-up
//  with nothing in any log.
//
//  📝 powerup_vo( "zombie_blood" ) is kept exactly as stock has it even though no
//  character vox is registered off Origins - see the block comment above. It
//  returns immediately, which is the stock code path for an unregistered type.
// ============================================================================
zmqol_zb_powerup( m_powerup, e_player )
{
    e_player notify( "zombie_blood" );
    e_player endon( "zombie_blood" );
    e_player endon( "disconnect" );
    e_player thread maps\mp\zombies\_zm_powerups::powerup_vo( "zombie_blood" );
    e_player.ignoreme = 1;
    e_player thread zmqol_zb_hold_ignoreme();
    e_player._show_solo_hud = 1;
    e_player.zombie_vars[ "zombie_powerup_zombie_blood_time" ] = 30;
    e_player.zombie_vars[ "zombie_powerup_zombie_blood_on" ] = 1;
    level notify( "player_zombie_blood", e_player );
    maps\mp\_visionset_mgr::vsmgr_activate( "visionset", "zm_powerup_zombie_blood_visionset", e_player );
    maps\mp\_visionset_mgr::vsmgr_activate( "overlay", "zm_powerup_zombie_blood_overlay", e_player );
    e_player setclientfield( "player_zombie_blood_fx", 1 );

    level.a_zombie_blood_entities = zmqol_zb_compact( level.a_zombie_blood_entities );

    foreach ( e_zombie_blood in level.a_zombie_blood_entities )
    {
        if ( isdefined( e_zombie_blood.e_unique_player ) )
        {
            if ( e_zombie_blood.e_unique_player == e_player )
                e_zombie_blood setvisibletoplayer( e_player );

            continue;
        }

        e_zombie_blood setvisibletoplayer( e_player );
    }

    if ( !isdefined( e_player.m_fx ) )
    {
        v_origin = e_player gettagorigin( "J_Eyeball_LE" );
        v_angles = e_player gettagangles( "J_Eyeball_LE" );
        m_fx = spawn( "script_model", v_origin );
        m_fx setmodel( "tag_origin" );
        m_fx.angles = v_angles;
        m_fx linkto( e_player, "J_Eyeball_LE", ( 0, 0, 0 ), ( 0, 0, 0 ) );
        m_fx thread zmqol_zb_fx_disconnect_watch( e_player );
        playfxontag( level._effect[ "zombie_blood" ], m_fx, "tag_origin" );
        e_player.m_fx = m_fx;
        e_player.m_fx playloopsound( "zmqol_zombieblood_3rd_loop", 1 );

        if ( isdefined( level.str_zombie_blood_model ) )
        {
            e_player.hero_model = e_player.model;
            e_player setmodel( level.str_zombie_blood_model );
        }
    }

    e_player thread zmqol_zb_watch_early_exit();

    while ( e_player.zombie_vars[ "zombie_powerup_zombie_blood_time" ] >= 0 )
    {
        wait 0.05;
        e_player.zombie_vars[ "zombie_powerup_zombie_blood_time" ] =
            e_player.zombie_vars[ "zombie_powerup_zombie_blood_time" ] - 0.05;
    }

    e_player notify( "zombie_blood_over" );

    if ( isdefined( e_player.characterindex ) )
        e_player playsound( "vox_plr_" + e_player.characterindex + "_exert_grunt_" + randomintrange( 0, 3 ) );

    e_player.m_fx delete();
    maps\mp\_visionset_mgr::vsmgr_deactivate( "visionset", "zm_powerup_zombie_blood_visionset", e_player );
    maps\mp\_visionset_mgr::vsmgr_deactivate( "overlay", "zm_powerup_zombie_blood_overlay", e_player );
    e_player.zombie_vars[ "zombie_powerup_zombie_blood_on" ] = 0;
    e_player.zombie_vars[ "zombie_powerup_zombie_blood_time" ] = 30;
    e_player._show_solo_hud = 0;
    e_player setclientfield( "player_zombie_blood_fx", 0 );

    if ( !isdefined( e_player.early_exit ) )
        e_player.ignoreme = 0;
    else
        e_player.early_exit = undefined;

    level.a_zombie_blood_entities = zmqol_zb_compact( level.a_zombie_blood_entities );

    foreach ( e_zombie_blood in level.a_zombie_blood_entities )
        e_zombie_blood setinvisibletoplayer( e_player );

    if ( isdefined( e_player.hero_model ) )
    {
        e_player setmodel( e_player.hero_model );
        e_player.hero_model = undefined;
    }
}

// ----------------------------------------------------------------------------
//  zmqol_zb_compact  -  drop deleted entities, preserving string keys
//
//  Stock's zombie_blood_powerup() carries this block INLINE, twice - it is what
//  the compiler emits for the array-compact idiom, and the decompiler shows it
//  expanded. There is no array_removeundefined() in T6's utilities (checked
//  common_scripts\utility, maps\mp\_utility and _zm_utility), so it is lifted
//  here verbatim as one function rather than invented or duplicated.
// ----------------------------------------------------------------------------
zmqol_zb_compact( a_ents )
{
    a_new = [];

    foreach ( str_key, e_value in a_ents )
    {
        if ( isdefined( e_value ) )
        {
            if ( isstring( str_key ) )
            {
                a_new[ str_key ] = e_value;
                continue;
            }

            a_new[ a_new.size ] = e_value;
        }
    }

    return a_new;
}

zmqol_zb_fx_disconnect_watch( e_player )
{
    self endon( "death" );
    e_player waittill( "disconnect" );
    self delete();
}

// ----------------------------------------------------------------------------
//  zmqol_zb_hold_ignoreme  -  keep the "AI ignores me" flag set   (v1.68.1)
//
//  User, 2026-08-11: *"one time whilst I had a zombie blood the zombies still
//  came for me and attacked me, all the fx visual and sound wise were working
//  just the actual functionality was scuffed"*.
//
//  🌟 THE FX WORKING IS THE DIAGNOSIS. `e_player.ignoreme = 1` is the FIRST
//  thing zombie_blood_powerup() does - three lines before any of the fx, the
//  visionsets or the clientfield. If the fx ran, the flag was set. So it was set
//  and then something CLEARED it, and this re-asserts it for the 30 seconds the
//  power-up owns.
//
//  🛑 IS THIS "TUNING A PORT"? No, and the distinction matters. The port is
//  otherwise byte-faithful to Origins' zombie_blood_powerup(), which relies on
//  the flag simply staying put for 30s. Something in this mod's environment does
//  not let it. Holding it at the value stock sets restores stock behaviour; it
//  does not make the power-up stronger, longer or wider than Treyarch's. That is
//  the additive gap-filling QUEUE.md's standing rule explicitly allows, not a
//  behaviour change.
//
//  📝 WHO CLEARS IT IS STILL UNKNOWN, so this also PRINTS. Core has at least one
//  unconditional writer - _zm.gsc:1381 player_spawn_protection() runs 3s of
//  ignoreme = 1 from onplayerspawned() and then ends with a bare
//  `self.ignoreme = 0`, which would wipe a power-up grabbed just after a spawn
//  or a revive - and _zm.gsc:2598 does the same on the respawn path. Neither was
//  proven to be what the user hit. The count in the log names the culprit's
//  timing on the next occurrence:
//      [zm_qol] zombie blood: ignoreme cleared (N) - re-asserted after Ns
//  If N is 1 and it lands ~3s after a spawn, it is spawn protection. If it
//  repeats steadily, it is a loop.
//
//  Ends on the same notifies the power-up itself uses, so a second pickup or the
//  power-up expiring stops it - it can never hold the flag past the effect.
// ----------------------------------------------------------------------------
zmqol_zb_hold_ignoreme()
{
    self endon( "disconnect" );
    self endon( "zombie_blood" );
    self endon( "zombie_blood_over" );
    level endon( "end_game" );

    n_start = gettime();
    n_cleared = 0;

    for ( ;; )
    {
        wait 0.25;

        if ( isdefined( self.ignoreme ) && self.ignoreme )
            continue;

        n_cleared++;
        self.ignoreme = 1;
        println( "[zm_qol] zombie blood: ignoreme cleared (" + n_cleared + ") - re-asserted after " + ( ( gettime() - n_start ) / 1000 ) + "s" );
    }
}

zmqol_zb_watch_early_exit()
{
    self notify( "early_exit_watch" );
    self endon( "early_exit_watch" );
    self endon( "zombie_blood_over" );
    self endon( "disconnect" );
    waittill_any_ents_two( self, "player_downed", level, "end_game" );
    self.zombie_vars[ "zombie_powerup_zombie_blood_time" ] = -0.05;
    self.early_exit = 1;
}

zmqol_zb_make_entity()
{
    level.a_zombie_blood_entities[ level.a_zombie_blood_entities.size ] = self;
    self setinvisibletoall();

    foreach ( e_player in getplayers() )
    {
        if ( e_player.zombie_vars[ "zombie_powerup_zombie_blood_on" ] )
        {
            if ( isdefined( self.e_unique_player ) )
            {
                if ( self.e_unique_player == e_player )
                    self setvisibletoplayer( e_player );

                continue;
            }

            self setvisibletoplayer( e_player );
        }
    }
}

// ============================================================================
//  zmqol_register_announcer_vox  -  THE THREE ANNOUNCER LINES        (v1.65.0)
//
//  User, 2026-08-11: *"make sure the announcer lines for them work as well, the
//  ones from origins so even on the other maps. Also, add a death machine
//  announcer line for the death machine power-up."*
//
//  🌟 THE MECHANISM DICTATES THE ALIAS NAMES, so they are not free-form.
//  _zm_powerups.gsc:1147 announces EVERY power-up generically, keyed on the
//  power-up's own name:
//      level thread _zm_audio_announcer::leaderdialog( self.powerup_name, ... )
//  and playleaderdialogonplayer() builds the alias as
//      game["zmbdialog"]["prefix"] + "_" + game["zmbdialog"][dialog]
//  with prefix "vox_zmba". So a ported line MUST be named vox_zmba_* - a zmqol_*
//  name can never be reached down this path. Mod-privacy is kept with a `qol_`
//  infix instead, which collides with nothing in any shipped bank.
//
//  🌟 AND IT MUST END IN _0. getleaderdialogvariant() calls
//  _zm_spawner::get_number_variants(), a soundexists( base + "_" + i ) loop. One
//  variant present -> full_alias = base + "_0", which is stock's own shape.
//
//  🛑 EACH LINE IS SHIPPED TWICE, UNDER BOTH NAMES - with the _0 and without -
//  and that is deliberate, not sloppiness. It closes the one branch that could
//  not be settled offline. get_number_variants() is a soundexists() loop, and
//  whether soundexists() can see an alias that lives in a MOD's own bank rather
//  than a stock one is not something any dump or log in this workspace answers.
//  The two outcomes are:
//      soundexists sees it  -> num_variants 1 -> plays <base>_0
//      soundexists misses it -> returns undefined -> plays <base> verbatim
//                               (playleaderdialogonplayer: `if ( !isdefined(
//                                variant ) ) full_alias = alias;`)
//  Shipping both names means either branch lands on a real alias. They are never
//  both played - the engine takes exactly one path - so the cost is three spare
//  rows in mod.all and the benefit is that a wrong guess about soundexists()
//  cannot silently mute all three lines. A missing alias is SILENT, never an
//  error, which is precisely why this is worth a belt and braces.
//
//  | createvox key        | alias the engine builds              | payload source |
//  | zombie_blood         | vox_zmba_qol_powerup_zombie_blood_0  | zmb_tomb.english |
//  | bonus_points_player  | vox_zmba_qol_powerup_blood_money_0   | zmb_tomb.english |
//  | deathmachine         | vox_zmba_qol_powerup_death_machine_0 | zmb_highrise.english |
//
//  🛑 IT MUST RUN AFTER _zm_audio_announcer::init(), which opens with
//  `game["zmbdialog"] = []` - it would wipe anything written earlier. That init
//  is reached from _zm_audio::init() at _zm.gsc:149, and this mod's init() is not
//  ordered against it, so this polls instead of assuming. Polling is SAFE here
//  and is not the mistake the visionset registrations warn about: there is no
//  closing window - nothing ever clears game["zmbdialog"] again, and the first
//  power-up cannot be grabbed for many seconds.
//
//  ── PER-LINE NOTES ──────────────────────────────────────────────────────────
//
//  ZOMBIE BLOOD. Core already does createvox( "zombie_blood",
//  "powerup_zombie_blood" ) on every map (_zm_audio_announcer.gsc:20), but the
//  alias it resolves to, vox_zmba_powerup_zombie_blood_0, exists ONLY in
//  zmb_tomb.english - measured by dumping the alias tables of zmb_tomb,
//  zmb_highrise, zmb_alcatraz, zmb_buried, zmb_nuked_real, zmb_classic_transit
//  and zmb_survival_transit. Off Origins get_number_variants() returns 0 and the
//  engine plays a name no bank has: silent, no error. Re-pointing the key at our
//  own copy is what makes it audible. Gated off zm_tomb so Origins keeps playing
//  Treyarch's alias through Treyarch's path.
//
//  BLOOD MONEY. 🛑 CORRECTS v1.64.0's WRITE-UP, which said the silence was
//  deliberate parity. That was measured on the wrong path. It is true that
//  createvox( "bonus_points_solo", ... ) appears nowhere in the 2,093-file stock
//  dump, so powerup_grab()'s powerup_vo( "bonus_points_solo" ) really does return
//  without playing - but ORIGINS REACHES THE LINE BY A DIFFERENT ROUTE ENTIRELY,
//  its dig script's own leaderdialog( "blood_money" ) (zm_tomb_dig.gsc:773). The
//  line exists and porting it is correct, not a tuning change.
//
//  📝 NO MAP GATE ON BLOOD MONEY, unlike the other two, and the reason is
//  specific. The key registered here is bonus_points_player - the POWER-UP's own
//  name, which is what :1147 passes - while Origins' dig registers a different
//  key, "blood_money". So this adds a line on the path stock leaves silent
//  (a natural drop) and does not touch the dig's, which keeps using Treyarch's
//  alias. Gating Origins out would instead leave the mod's own natural-drop
//  feature silent on exactly one map, which is the per-map half-implementation
//  this project does not ship.
//
//  DEATH MACHINE. 🛑 powerup_vo( "minigun" ) IS A DEAD END - do not use it. Core
//  registers createvox( "minigun", "powerup_death_machine" ), which resolves to
//  vox_zmba_powerup_death_machine, and that alias exists in NO bank in the game:
//  checked all seven zombie banks above plus the 96 base-game identifier files.
//  The only Death Machine announcer Treyarch actually recorded is Die Rise's
//  zmb_vox_ann_death_machine, which is not part of the zmbdialog system at all
//  and has ZERO references across all 2,093 stock scripts - recorded, shipped,
//  never wired up. It is re-shipped here under the vox_zmba_ shape so the generic
//  path can reach it.
//
//  📝 The key is "deathmachine", not "minigun", because that is what this mod
//  names its own power-up (see the deathmachine_powerup section above, and
//  add_zombie_powerup( "deathmachine", ... ) in init()). :1147 passes
//  self.powerup_name, so the vox has to be registered under that exact string.
//  No gate: no map plays this line in stock, so there is no baseline to preserve.
// ============================================================================
zmqol_register_announcer_vox()
{
    for ( i = 0; i < 1200; i++ )
    {
        if ( isdefined( game[ "zmbdialog" ] ) && isdefined( game[ "zmbdialog" ][ "prefix" ] ) )
        {
            if ( zmqol_zombie_blood_enabled() )
                maps\mp\zombies\_zm_audio_announcer::createvox( "zombie_blood", "qol_powerup_zombie_blood" );

            //  🛑 BLOOD MONEY IS DELIBERATELY NOT REGISTERED HERE ANY MORE
            //  (v2.8.8). It is played by zmqol_bonus_points_player_powerup()
            //  instead - see that function for why. Leaving the createvox in
            //  place as well would give the line twice, because stock's
            //  _zm_powerups.gsc:1147 leaderdialog( self.powerup_name ) fires on
            //  the same grab; with no vox registered for the key,
            //  playleaderdialogonplayer() returns before it plays anything and
            //  the mod's own call is the only one left.
            //
            //  🛑 v2.9.9 - THE DEATH MACHINE'S createvox IS GONE FOR THE SAME
            //  REASON. Its line now plays from deathmachine_powerup() through
            //  zmqol_play_announcer_line(), the route Blood Money's confirmed
            //  fix uses; registering the vox here as well would hand stock's
            //  drop-if-busy path a second copy of the line.

            //  ================================================================
            //  🌟 v1.99.84 - SOLVED, AND THE v1.99.70 PROBE IS RETIRED.
            //
            //  The probe answered its question: stock 1, qol 1 - the alias
            //  resolves, so the bank and the payload were never the fault. The
            //  real cause was measured out of the game files afterwards:
            //
            //  🛑 THE ANNOUNCER ALIAS CARRIES A PREFIX AND NUKETOWN CHANGES IT.
            //  _zm_audio_announcer.gsc:358 builds the alias as
            //      game["zmbdialog"]["prefix"] + "_" + game["zmbdialog"][dialog]
            //  and _zm_utility::sndswitchannouncervox() rewrites that prefix:
            //  "sam" -> "vox_zmba_sam", "richtofen" -> "vox_zmba".
            //
            //  Only ONE map calls it: zm_nuked.gsc:172 threads
            //  sndswitchannouncervox( "sam" ) at map init, and switches back
            //  only in switch_announcer_to_richtofen(), which is
            //  flag_wait( "moon_transmission_over" ) - the easter egg. So on
            //  Nuketown, for the whole of a normal match, the alias the engine
            //  asks for is vox_zmba_sam_qol_powerup_zombie_blood, which this
            //  mod never shipped. A missing alias is SILENT, never an error,
            //  which is exactly what the user reported - on Nuketown.
            //
            //  🌟 Confirmed against the shipped banks, not inferred: dumping
            //  en_zm_nuked.ff gives 8 vox_zmba_powerup_*_0 rows AND 8
            //  vox_zmba_sam_powerup_*_0 rows - Treyarch ships every Nuketown
            //  announcer line twice, once per voice - while en_zm_transit,
            //  en_zm_highrise, en_zm_prison, en_zm_buried and en_zm_tomb ship
            //  no vox_zmba_sam_* row at all. Nuketown is the only map that
            //  needs the second name, and the only map where this was broken.
            //
            //  FIX: soundbank\mod.all.aliases.additions.csv now carries
            //  vox_zmba_sam_qol_powerup_zombie_blood and _blood_money (both the
            //  bare and the _0 form, matching the existing rows - Mob of the
            //  Dead uses bare names, every other map uses _0), pointing at the
            //  SAME payloads. That is voice-correct rather than a patch: both
            //  recordings were dumped from Origins, whose announcer is Samantha,
            //  so under the "sam" prefix they are the right voice.
            //
            //  🛑 THE DEATH MACHINE IS DELIBERATELY NOT GIVEN A "sam" ALIAS, and
            //  it therefore stays silent on Nuketown before the easter egg.
            //  Its payload is Die Rise s zmb_vox_ann_death_machine
            //  (devraw\english\sound\vox\scripted\zmb\announcer\death_machine),
            //  and Die Rise s announcer is Richtofen. No Samantha Death Machine
            //  line exists anywhere in the game - Nuketown s sam set is 8 rows
            //  and has none. So the only options are Richtofen s voice while
            //  Samantha is announcing, or nothing, and picking the mismatch
            //  silently is the kind of compromise this project does not ship.
            //  It is written up in QUEUE.md for the user to decide.
            //
            //  The print below survives as the one-line confirmation: it names
            //  the live prefix and the exact alias the engine will ask for.
            //  ================================================================
            println( "[zm_qol] vox: prefix=" + game[ "zmbdialog" ][ "prefix" ] +
                     "  zblood_alias=" + game[ "zmbdialog" ][ "prefix" ] + "_qol_powerup_zombie_blood" +
                     "  exists=" + soundexists( game[ "zmbdialog" ][ "prefix" ] + "_qol_powerup_zombie_blood" ) +
                     "  bmoney_exists=" + soundexists( game[ "zmbdialog" ][ "prefix" ] + "_qol_powerup_blood_money" ) );

            return;
        }

        wait 0.05;
    }
}

// ============================================================================
//  zmqol_whoswho_enabled  -  THE ONE map list, asked by both sides
//
//  Who's Who is Die Rise's perk. Stage 1 of putting every BO2 perk on every map.
//
//  📝 IT IS THE CHEAPEST OF THE FOUR REMAINING PERKS - exactly ONE clientfield
//  bit - and that is not luck, it is because stock self-gates:
//      level.whos_who_client_setup            gates the corpse glow shader, and
//                                             clientfield_whos_who_audio/_filter
//      level.vsmgr_prio_visionset_zm_whos_who gates the zm_whos_who visionset
//  BOTH are set ONLY by zm_highrise (zm_highrise.gsc:81 and :133-134). Off Die
//  Rise every one of those code paths is skipped, so enabling the perk costs
//  `perk_chugabud` (1 bit, toplayer) and nothing else. In particular it CANNOT
//  reproduce the Vulture overlay_lerp mismatch, because it registers no overlay
//  and no visionset on either side.
//
//  🛑 MOB OF THE DEAD IS EXCLUDED, AND NOT FOR THE USUAL BUDGET REASON.
//  Stock's Who's Who HUD icon is `specialty_quickrevive_zombies` (the perk is
//  revive-adjacent and reuses it - see _zm_perks.gsc:212 vs :256, the revive
//  block and the chugabud block precaching the same shader). Every map ships
//  that material EXCEPT Mob, which has no Quick Revive at all - confirmed with
//  Unlinker --list over all six map fastfiles plus common_zm.ff, not assumed.
//  Mob therefore needs an asset the other four do not, and it is also the map
//  whose toplayer set is already known full. It comes in at STAGE 2, together
//  with Quick Revive, which needs that same shader - one asset, two perks, one
//  boot test.
//
//  🛑 AND IT LIVES IN ONE FUNCTION FOR A REASON. v1.49.0 wrote the Vulture map
//  list into three places, forgot one, and turned a boot crash into a different
//  boot crash. Same discipline here: this function is the only list, and
//  zm_expanded.csc's twin is the one unavoidable copy (separate compilation
//  unit) - check it first if the sets ever disagree.
// ============================================================================
zmqol_whoswho_enabled()
{
    map = getDvar( "mapname" );

    if ( map == "zm_highrise" )   // ships the perk itself
        return 0;

    if ( map == "zm_prison" )     // no specialty_quickrevive_zombies - stage 2
        return 0;

    // 🛑 BURIED IS DROPPED - the user's call, 2026-08-09, and it is a budget wall,
    // not a preference. The perk's corpse-glow field needs 1 bit in the `actor`
    // clientfield set and Buried's classic mode uses all 32 already. Counted from
    // the per-map runtime dump, field by field, not estimated:
    //   Black Ops 2 Grand Resources\...\Clientfields\clientfields_zm_buried_zclassic_processing.txt
    //   21 actor fields -> 32/32  (anim_rate 5, ghost_fx 3, sndGhostAudio 3,
    //   slowgun_fx 3, vulture_perk_actor 2, plus 16 one-bit fields)
    // A 33rd bit is fatal at load, and this project has already hit that exact
    // error on Origins: "Trying to assign 1 bits for netfield zone_capture_zombie
    // but Client Field Set ACTOR is out of space".
    //
    // Buried SURVIVAL only uses 13/32, so the perk could ship there and not in
    // classic - but a perk that exists in one mode of a map and not the other is
    // the kind of half-implementation this project does not ship. Asked and
    // answered: drop it on Buried entirely.
    if ( map == "zm_buried" )
        return 0;

    // ========================================================================
    //  🛑 v2.9.30 - ORIGINS IS DROPPED TOO. Measured from the user's failed
    //  boot, 2026-09-01 (console_zm.log):
    //      Trying to assign 2 bits for netfield visionset_slot
    //      but Client Field Set toplayer is out of space.       (zm_tomb, zclassic)
    //
    //  The arithmetic, from the T6-Data-Archive per-map dump: stock Origins
    //  classic toplayer = 61 bits. This mod added 5 there - perk_tombstone 2
    //  (user-requested, v1.58.2) + Who's Who's 3 (clientfield_whos_who_audio 1,
    //  clientfield_whos_who_filter 1, perk_chugabud 1) - for 66. The only
    //  toplayer totals ever seen to BOOT are <= 63 (stock Buried 63; this mod's
    //  Buried at 63 on 2026-08-13, when the pre-v2.9.13 1-bit perk fields
    //  masked 8 bits; Mob at 63 since v2.9.22). 66 has now failed twice (Mob
    //  v2.9.21, Origins here). Ceiling is somewhere in [63,65]; 63 is the only
    //  proven-safe target, so 3 bits had to go.
    //
    //  Who's Who is the right cut, not Tombstone, for two reasons:
    //    1. Tombstone was an explicit user request for Origins ("there's one
    //       perk missing tombstone cola", 2026-08-07) and costs only 2.
    //    2. Who's Who is ALREADY incomplete on Origins and always will be: the
    //       downed-clone glow needs the `_g` glow materials, which exist for
    //       the Victis crew only - the Origins crew has none anywhere in the
    //       game (the sweep is documented on zmqol_whoswho_clone_glow_enabled).
    //       "Perfectly or not at all" - the same rule that took Vulture off
    //       this map in v1.59.0.
    //  Dropping it here also returns Origins' `actor` set to 31/32 (the
    //  clone-glow shader field goes with it) and un-registers the zm_whos_who
    //  visionset info on both sides.
    //
    //  🛑 The client twin is zm_expanded.csc::zmqol_whoswho_enabled(). Both
    //  must agree or the toplayer set differs in width between the two sides
    //  and everyone is dropped with EXE_CLIENT_FIELD_MISMATCH.
    if ( map == "zm_tomb" )
        return 0;

    return 1;
}

// ============================================================================
//  zmqol_whoswho_clone_glow_enabled  -  THE SECOND map list, and it is smaller
//
//  The perk runs on four maps; the downed clone's orange glow can only run on
//  ONE of them, and both halves of that are hard limits rather than choices.
//
//  1. THE GLOW NEEDS GLOW-CAPABLE MATERIALS. Stock lights the corpse with a
//     shader constant (scriptVector3), and a shader constant does nothing
//     unless the model's material is authored to read it. Only the `_g`
//     variants are, and a sweep of all 191 fastfiles finds every
//     `mc/mtl_c_zom_player_*_g` in zm_highrise.ff and nowhere else. They cover
//     the Victis crew only - Nuketown's CIA/CDC agents and Origins' Richtofen
//     crew have no `_g` material anywhere in the game.
//
//  2. 🛑 AND ORIGINS HAS NO ROOM FOR THE FIELD EVEN IF IT COULD USE IT. Its
//     `scriptmover` set is exactly 32/32 in both classic and survival - see the
//     count in zmqol_enable_whoswho(). Registering there is a boot crash, and
//     v1.99.17 shipped exactly that.
//
//  So: zm_transit only. Asked by the server registration, the precache, the
//  model watcher AND zm_expanded.csc's twin, so there is one list and not four.
// ============================================================================
zmqol_whoswho_clone_glow_enabled()
{
    if ( !zmqol_whoswho_enabled() )
        return 0;

    return getDvar( "mapname" ) == "zm_transit";
}

// ============================================================================
//  zmqol_enable_whoswho
//
//  Setting the flag is the whole job. Unlike Electric Cherry and Vulture Aid,
//  Who's Who is NOT a custom perk - it is one of the nine stock
//  level.zombiemode_using_*_perk flags, so _zm_perks::perks_register_clientfield
//  registers its clientfield and _zm_perks::init() threads turn_chugabud_on()
//  off the back of the same flag. There is no _register_undefined_perk() call to
//  make and no perk_machine_thread pointer to clear afterwards.
//
//  turn_chugabud_on() calls _zm_chugabud::init() and then blocks forever on
//  `level waittill( "chugabud_on" )` after finding getentarray("vending_chugabud")
//  empty - which is exactly the harmless idle the Electric Cherry loop settles
//  into. _zm_chugabud::init() is what sets level.chugabud_laststand_func, so it
//  MUST run; letting stock's own thread call it is what gets that for free.
//
//  Called from perks(), which runs in main(). Clientfields have to be registered
//  before the first snapshot, so this cannot move to init().
//
//  🛑 NOT verified in game yet. Requires build.bat AND build_ff.bat (the bottle
//  weapon is a new mod.ff asset).
// ============================================================================
zmqol_enable_whoswho()
{
    if ( !zmqol_whoswho_enabled() )
        return;

    level.zombiemode_using_chugabud_perk = 1;

    // ========================================================================
    //  THE VISUAL / AUDIO HALF - user 2026-08-09: "Who's Who is still missing
    //  its visual overlay fx when downed and in the self-revive state."
    //
    //  Correct, and the cause is one level var. EVERY effect Who's Who has lives
    //  inside _zm_chugabud::activate_chugabud_effects_and_audio() (:745), and
    //  that whole function body is wrapped in
    //        if ( isdefined( level.whos_who_client_setup ) )
    //  The corpse glow at :71-72 is behind the same flag. Only zm_highrise.gsc:81
    //  ever sets it, so off Die Rise the perk ran with its functionality intact
    //  and every single effect skipped - silently, because the gate is an
    //  isdefined and not an error.
    //
    //  Setting the flag is not enough on its own: it makes stock write three
    //  clientfields that nothing registered, so they must be registered here
    //  FIRST, with zm_highrise's exact names, versions, bit counts and types
    //  (zm_highrise.gsc:78-80). The client twin in zm_expanded.csc registers the
    //  same three with their callbacks - if the two sides ever disagree, that is
    //  EXE_CLIENT_FIELD_MISMATCH before the map starts.
    //
    //  🛑 BIT BUDGET, measured per map, not assumed. Only the `actor` field costs
    //  scarce space; the ceiling is 32 and Buried's classic mode already sits
    //  exactly on it, which is why zmqol_whoswho_enabled() drops Buried:
    //        zm_transit   5/32 classic, 4/32 survival  -> fits easily
    //        zm_nuked     4/32                         -> fits easily
    //        zm_tomb     31/32                         -> lands on exactly 32/32
    //        zm_buried   32/32 classic                 -> DROPPED
    //  Origins therefore has ZERO margin after this. 32 is provably attainable -
    //  stock Buried classic ships at exactly 32 - but nothing else may ever take
    //  an actor bit on Origins again.
    //
    //  📝 level.chugabud_shellshock is deliberately NOT set. It gates
    //  self shellshock( "whoswho", 60 ) at :752, and grepping all 2,093 stock
    //  scripts finds it assigned NOWHERE - so the shellshock never fires in stock
    //  either. Adding it would make this port louder than the original, which is
    //  the mistake v1.62.9 made with Electric Cherry.
    // ========================================================================
    registerclientfield( "actor",    "clientfield_whos_who_clone_glow_shader", 5000, 1, "int" );
    registerclientfield( "toplayer", "clientfield_whos_who_audio",             5000, 1, "int" );
    registerclientfield( "toplayer", "clientfield_whos_who_filter",            5000, 1, "int" );

    //  v1.99.16 - the scriptmover twin of the clone-glow field. Off Die Rise the
    //  Who's Who corpse is a script_model, not an actor, so the stock actor field
    //  above reaches nothing. Full reasoning on zmqol_whoswho_clone_glow().
    //  🛑 EXACT TWIN in zm_expanded.csc::zmqol_enable_whoswho() - both sides
    //  register it on the same map list or the scriptmover set is one bit wider
    //  on one side, which is EXE_CLIENT_FIELD_MISMATCH at load.
    //
    //  🛑 v1.99.18 - AND IT IS GATED TO zm_transit, BECAUSE UNGATED IT KILLED
    //  ORIGINS AT THE LOADING SCREEN:
    //        "Trying to assign 1 bits for netfield zone_captured but Client
    //         Field Set scriptmover is out of space."
    //  Counted from the per-map runtime dump, field by field, not estimated
    //  (Black Ops 2 Grand Resources\...\Clientfields\):
    //        zm_tomb zclassic_tomb   19 stock fields -> 32/32 EXACTLY
    //        zm_tomb survival        25 stock bits + the 7 this mod adds back
    //                                for client/server parity -> 32/32 EXACTLY
    //  Either way a 33rd bit is fatal, and the field is dead weight there anyway:
    //  the glow needs the `_g` materials, which exist for the Victis crew only.
    //  One predicate owns the list - see zmqol_whoswho_clone_glow_enabled().
    if ( zmqol_whoswho_clone_glow_enabled() )
    {
        registerclientfield( "scriptmover", "zmqol_whoswho_clone_glow",        5000, 1, "int" );

        //  🛑 AND THE MODELS MUST BE PRECACHED, WHICH v1.99.17 DID NOT DO - THAT
        //  IS WHY THE DOWNED BODY WAS INVISIBLE. Die Rise precaches all four
        //  (zm_highrise.gsc:673-676) before ever assigning self.whos_who_shader;
        //  setmodel() with a model that was never precached draws nothing and
        //  reports nothing. Declaring them in mod.ff's zone makes them LOADABLE;
        //  only precachemodel() makes them USABLE. Both are needed.
        precachemodel( "c_zom_player_oldman_dlc1_fb" );
        precachemodel( "c_zom_player_reporter_dlc1_fb" );
        precachemodel( "c_zom_player_farmgirl_dlc1_fb" );
        precachemodel( "c_zom_player_engineer_dlc1_fb" );
    }

    level.whos_who_client_setup = 1;

    // Gates the zm_whos_who visionset. Stock registers it inside
    // _zm_perks::turn_chugabud_on() (:1448-1449), which _zm_perks::init() threads
    // off level.zombiemode_using_chugabud_perk - so this var only has to exist by
    // the time init() runs, and perks() runs in main(). 123 is zm_highrise's own
    // priority (zm_highrise.gsc:133-134), kept identical.
    if ( !isdefined( level.vsmgr_prio_visionset_zm_whos_who ) )
        level.vsmgr_prio_visionset_zm_whos_who = 123;

    //  🔊 v2.11.16 - the perk's four pop sounds, silent here since the day it
    //  was enabled off Die Rise. Full reasoning on the function.
    zmqol_whoswho_install_sound_hooks();

    level thread zmqol_whoswho_verify();
    level thread zmqol_whoswho_visionset_probe();
    level thread zmqol_whoswho_overlay_connect();
}

// ============================================================================
//  zmqol_whoswho_install_sound_hooks  -  v2.11.16. THE PERK'S FOUR POP SOUNDS.
//
//  Who's Who makes exactly four sounds, and off Die Rise ALL FOUR were silent.
//  maps\mp\zombies\_zm_chugabud.gsc is Core - it loads and runs everywhere -
//  and it plays them at four points:
//      :394  evt_ww_disappear  at the body you leave behind   (chugabud_fake_revive)
//      :417  evt_ww_appear     at the spot you re-appear on   (chugabud_fake_revive)
//      :157  evt_ww_appear     at the corpse, when revived    (chugabud_corpse_cleanup)
//      :162  evt_ww_disappear  at the corpse, when it bleeds out
//
//  🛑 BOTH ALIASES ARE DIE-RISE-ONLY - measured, not assumed. Plutonium's
//  soundaliaslists (a {alias: length_ms} table per map, common banks included)
//  carries evt_ww_appear and evt_ww_disappear under zm_highrise and under no
//  other map. A missing alias is SILENT and logs nothing, so this shipped as four
//  dead calls and looked like a working perk.
//
//  The fix is the one evt_ww_activate / evt_ww_looper already got (as
//  zmqol_ww_activate / zmqol_ww_looper, confirmed audible in game): re-ship
//  Treyarch's own payloads under mod-private names in this mod's own bank, so
//  nothing anywhere is shadowed. Payloads and alias parameters are Unlinker dumps
//  of zm_highrise.ff + zmb_highrise.all.sabl, copied row-for-row - ww_pop2 is the
//  appear and ww_pop the disappear, which the stock alias rows state outright and
//  the durations confirm (3382 / 2674 ms against the table's 3632 / 2924).
//
//  TWO HOOKS, AND NEITHER IS A GUESS ABOUT TIMING:
//
//  1. level._chugabud_post_respawn_override_func is TREYARCH'S OWN POINTER, called
//     on the player with the respawn origin from inside chugabud_fake_revive()
//     (:398-399) - after the disappear at :394, before the setorigin() at :415.
//     Nothing in between waits (chugabud_get_spawnpoint() is pure lookup, no wait
//     and no waittill anywhere in it), so both plays land in the same frame
//     stock's do, at the same two positions. zm_highrise_classic.gsc:77 is the
//     only setter in the whole game and this never runs on that map; the pointer
//     is chained rather than clobbered anyway.
//
//  2. chugabud_corpse_cleanup() has no hook, so it is replaced by a verbatim copy
//     with two lines added. It is 30 lines of straight-line code - no loops, no
//     branches beyond the two isdefined guards - so the copy carries no risk of
//     the kind a decompile of control flow would. The replacement is installed
//     ONLY on the maps this mod enables the perk on, so Die Rise never sees it.
//
//  3. level._chugabud_reject_node_override_func is TREYARCH'S OWN node filter,
//     called from inside get_chugabug_spawn_point_from_nodes() for every
//     candidate pathnode that passed stock's own checks. v2.14.x installs
//     zmqol_whoswho_reject_node here - see its banner for why stock's checks
//     let Bus Depot respawns land inside the depot trucks and out of the map.
//     Chained like the post-respawn pointer; on these maps there is no previous
//     setter (only zm_highrise_classic sets one, and the perk is stock there).
// ============================================================================
zmqol_whoswho_install_sound_hooks()
{
    if ( isdefined( level._chugabud_post_respawn_override_func ) )
        level.zmqol_ww_prev_respawn_func = level._chugabud_post_respawn_override_func;

    level._chugabud_post_respawn_override_func = ::zmqol_ww_post_respawn_sound;

    if ( isdefined( level._chugabud_reject_node_override_func ) )
        level.zmqol_ww_prev_reject_func = level._chugabud_reject_node_override_func;

    level._chugabud_reject_node_override_func = ::zmqol_whoswho_reject_node;

    replaceFunc( maps\mp\zombies\_zm_chugabud::chugabud_corpse_cleanup, ::zmqol_chugabud_corpse_cleanup );
}

//  self is the player, and at the call site they are STILL STANDING WHERE THEY
//  WENT DOWN - setorigin( spawnpoint.origin ) is sixteen lines below it. So
//  self.origin is stock's own disappear position and v_origin is stock's own
//  appear position; neither is re-derived.
//
//  v2.14.x - AND THE APPEAR POSITION IS NOW VALIDATED. If stock's pick is bad
//  (inside a truck visual, enclosed, outside the enabled zone - see
//  zmqol_whoswho_pos_is_bad()), the respawn is forced back to the downed spot
//  instead: the player stood there seconds ago, so it is provably inside the
//  map. The appear sting then plays at the corrected spot, and the chained
//  stock override - if one ever exists on these maps - receives the corrected
//  origin too, so its own zone bookkeeping cannot disagree with where the
//  player actually lands.
zmqol_ww_post_respawn_sound( v_origin )
{
    v_final = v_origin;

    if ( zmqol_whoswho_pos_is_bad( v_origin ) )
    {
        v_final = zmqol_whoswho_safe_fallback();

        if ( !isdefined( v_final ) )
            v_final = v_origin;
        else
            maps\mp\zombies\_zm_chugabud::force_player_respawn_position( v_final );

        println( "[zm_qol] whoswho: rejected bad respawn at " + v_origin + ", falling back to " + v_final );
    }

    playsoundatposition( "zmqol_ww_disappear", self.origin );
    playsoundatposition( "zmqol_ww_appear", v_final );

    if ( isdefined( level.zmqol_ww_prev_respawn_func ) )
        self [[ level.zmqol_ww_prev_respawn_func ]]( v_final );
}

// ============================================================================
//  zmqol_whoswho_reject_node / zmqol_whoswho_pos_is_bad /
//  zmqol_whoswho_safe_fallback / zmqol_whoswho_vehicle_points
//
//  WHY STOCK PICKS UNREACHABLE RESPAWNS OFF DIE RISE          (v2.14.x, user
//  report 2026-09-11: downed on Bus Depot survival with all perks including
//  Who's Who, respawned INSIDE a truck, walked out of the map.)
//
//  MECHANISM, read out of the scripts, not assumed. Stock picks the respawn in
//  chugabud_get_spawnpoint() -> get_chugabug_spawn_point_from_nodes(), which
//  keeps the FARTHEST pathnode in a 500-700 radius that passes three checks:
//      1. !positionwouldtelefrag(node.origin)
//      2. check_point_in_enabled_zone(node.origin, ...) against player_volumes
//      3. a 30-up/30-down bulletTrace that hits SOMETHING (i.e. has ground)
//
//  The depot trucks are spawned by _zm_gametype::setup_standard_objects() as
//  bare spawn( "script_model", struct.origin ) - no solid flag, compare the
//  perk collision clips' spawn( "script_model", pos.origin, 1 ). Non-solid
//  means every one of those three checks passes inside the truck: nothing to
//  telefrag on, the yard volume covers it, and the vertical trace still finds
//  ground. The farthest-first preference then favours exactly these edge-of-
//  the-yard nodes, and from inside the truck visual the player walks straight
//  past the boundary they would otherwise have collided with.
//
//  Die Rise never sees this because zm_highrise_classic installs its own
//  reject/post-respawn overrides for its elevators and slide; every map this
//  mod ports the perk to has NEITHER. So this installs both of Treyarch's own
//  hooks, with purely generic tests - no map names, no coordinates, no model
//  names - so the same code protects Nuketown and any future port:
//
//      REJECT (node filter, runs per candidate):
//        - headroom: 12 -> 68 must be clear (standing player is ~70 tall).
//          Catches enclosed cabs/trailers and any low solid roof.
//        - sides: 4 traces at torso height (+30), 42 units out. Rejected only
//          when 3+ are blocked, so a wall corner (2) or doorway (1) still
//          passes but a truck bed / trailer / box (3-4) does not. Open-top
//          beds pass headroom, so this is the check that catches them.
//        - vehicles: within 62 units of a dead-vehicle visual's footprint
//          (sampled along its facing axis, cached per match - see
//          zmqol_whoswho_vehicle_points()). This is the check that catches
//          NON-SOLID truck visuals, which no trace can ever see.
//        - enabled zone: stock's own check, repeated here so the post-respawn
//          clamp below can test a position stock already accepted.
//
//      CLAMP (post-respawn hook, runs once on the final pick): the same
//      predicate re-tests stock's winner - belt and braces against any node
//      the filter missed and against stock's non-node fallbacks
//      (check_for_valid_spawn_near_team / initial_spawn). A bad winner is
//      forced to the downed spot (or 45 units beside it), which the player
//      provably stood on seconds ago.
//
//  OVER-REJECTION IS SAFE, UNDER-REJECTION IS THE BUG. Every rejected node
//  just drops stock to its next tier (100-400, then 50-400, then near-team,
//  then initial spawns) - the player still respawns, only nearer the corpse.
//  Letting one bad node through strands them outside the map.
//
//  🛑 RESIDUAL RISK, stated: the fire-pit lava itself is open ground that
//  passes every check here (open sky, open sides, in-zone). A respawn INTO the
//  pit is vanilla-stock behaviour on classic TranZit too and is NOT filtered -
//  this fix is about leaving the map, not about landing somewhere unpleasant.
// ============================================================================
zmqol_whoswho_reject_node( v_corpse_pos, nd_node )
{
    if ( isdefined( level.zmqol_ww_prev_reject_func ) )
    {
        if ( [[ level.zmqol_ww_prev_reject_func ]]( v_corpse_pos, nd_node ) )
            return 1;
    }

    if ( !isdefined( nd_node ) || !isdefined( nd_node.origin ) )
        return 0;

    return zmqol_whoswho_pos_is_bad( nd_node.origin );
}

//  One predicate for both hooks. Returns 1 when v_pos must NOT be spawned on.
zmqol_whoswho_pos_is_bad( v_pos )
{
    if ( !isdefined( v_pos ) )
        return 1;

    if ( positionwouldtelefrag( v_pos ) )
        return 1;

    //  Headroom: chest (+12) to just under standing height (+68) must be open.
    v_chest = ( v_pos[0], v_pos[1], v_pos[2] + 12 );
    v_head = ( v_pos[0], v_pos[1], v_pos[2] + 68 );
    tr = bulletTrace( v_chest, v_head, 0, undefined );

    if ( tr["fraction"] < 1 )
        return 1;

    //  Sides: torso height (+30), 42 units out, four cardinals. 3+ blocked is
    //  enclosed (truck bed, trailer, container); 2 or fewer is a corner or a
    //  wall and stays legal.
    v_mid = ( v_pos[0], v_pos[1], v_pos[2] + 30 );
    n_blocked = 0;
    tr = bulletTrace( v_mid, v_mid + ( 42, 0, 0 ), 0, undefined );

    if ( tr["fraction"] < 1 )
        n_blocked++;

    tr = bulletTrace( v_mid, v_mid + ( -42, 0, 0 ), 0, undefined );

    if ( tr["fraction"] < 1 )
        n_blocked++;

    tr = bulletTrace( v_mid, v_mid + ( 0, 42, 0 ), 0, undefined );

    if ( tr["fraction"] < 1 )
        n_blocked++;

    tr = bulletTrace( v_mid, v_mid + ( 0, -42, 0 ), 0, undefined );

    if ( tr["fraction"] < 1 )
        n_blocked++;

    if ( n_blocked >= 3 )
        return 1;

    //  Dead-vehicle visuals: non-solid, so no trace above can see them.
    a_pts = zmqol_whoswho_vehicle_points();

    foreach ( v_pt in a_pts )
    {
        if ( distancesquared( v_pos, v_pt ) < 3844 )
            return 1;
    }

    //  Enabled zone, stock's own rule, re-tested on the final pick.
    a_vols = getentarray( "player_volume", "script_noteworthy" );

    if ( !maps\mp\zombies\_zm_utility::check_point_in_enabled_zone( v_pos, 1, a_vols ) )
        return 1;

    return 0;
}

//  Where stock's winner was bad: the downed spot first (provably stood-on),
//  else 45 units beside it, else the downed spot anyway - never outside the
//  map, never nothing. self is the downed player.
zmqol_whoswho_safe_fallback()
{
    if ( !zmqol_whoswho_pos_is_bad( self.origin ) )
        return self.origin;

    a_dirs = [];
    a_dirs[0] = ( 45, 0, 0 );
    a_dirs[1] = ( -45, 0, 0 );
    a_dirs[2] = ( 0, 45, 0 );
    a_dirs[3] = ( 0, -45, 0 );

    foreach ( v_dir in a_dirs )
    {
        v_try = self.origin + v_dir;

        if ( !zmqol_whoswho_pos_is_bad( v_try ) )
            return v_try;
    }

    return self.origin;
}

//  Footprint points of every dead vehicle visual on the map, built once per
//  match on first Who's Who down - after all map-init spawns (barricades,
//  location barriers) exist. Long trailers are covered by sampling along the
//  model's facing axis (origin, +/-80, +/-160, each radius 62); cars just get
//  over-covered, which is the safe direction.
zmqol_whoswho_vehicle_points()
{
    if ( isdefined( level.zmqol_ww_vehicle_pts ) )
        return level.zmqol_ww_vehicle_pts;

    level.zmqol_ww_vehicle_pts = [];
    a_ents = getentarray( "script_model", "classname" );

    if ( isdefined( a_ents ) )
    {
        foreach ( e_ent in a_ents )
        {
            if ( !isdefined( e_ent.model ) || !issubstr( e_ent.model, "veh_" ) )
                continue;

            if ( !isdefined( e_ent.origin ) )
                continue;

            //  angles is engine-defaulted on spawned script_models, but a
            //  script error here would abort the whole fake_revive thread and
            //  strand the player frozen - default rather than trust it.
            v_angles = e_ent.angles;

            if ( !isdefined( v_angles ) )
                v_angles = ( 0, 0, 0 );

            v_fwd = anglestoforward( v_angles );
            level.zmqol_ww_vehicle_pts[level.zmqol_ww_vehicle_pts.size] = e_ent.origin;
            level.zmqol_ww_vehicle_pts[level.zmqol_ww_vehicle_pts.size] = e_ent.origin + vectorscale( v_fwd, 80 );
            level.zmqol_ww_vehicle_pts[level.zmqol_ww_vehicle_pts.size] = e_ent.origin - vectorscale( v_fwd, 80 );
            level.zmqol_ww_vehicle_pts[level.zmqol_ww_vehicle_pts.size] = e_ent.origin + vectorscale( v_fwd, 160 );
            level.zmqol_ww_vehicle_pts[level.zmqol_ww_vehicle_pts.size] = e_ent.origin - vectorscale( v_fwd, 160 );
        }
    }

    println( "[zm_qol] whoswho: cached " + level.zmqol_ww_vehicle_pts.size + " vehicle footprint points" );
    return level.zmqol_ww_vehicle_pts;
}

//  A verbatim copy of _zm_chugabud::chugabud_corpse_cleanup() with one added
//  play in each branch. Stock's own evt_ww_* calls are KEPT: they cost nothing
//  where the alias is absent, and they are the right thing to fire the day a
//  sound pack supplies it.
zmqol_chugabud_corpse_cleanup( corpse, was_revived )
{
    self notify( "chugabud_effects_cleanup" );

    if ( was_revived )
    {
        playsoundatposition( "evt_ww_appear", corpse.origin );
        playsoundatposition( "zmqol_ww_appear", corpse.origin );
        playfx( level._effect["chugabud_revive_fx"], corpse.origin );
    }
    else
    {
        playsoundatposition( "evt_ww_disappear", corpse.origin );
        playsoundatposition( "zmqol_ww_disappear", corpse.origin );
        playfx( level._effect["chugabud_bleedout_fx"], corpse.origin );
        self notify( "chugabud_bleedout" );
    }

    if ( isdefined( corpse.revivetrigger ) )
    {
        corpse notify( "stop_revive_trigger" );
        corpse.revivetrigger delete();
        corpse.revivetrigger = undefined;
    }

    if ( isdefined( corpse.revive_hud_elem ) )
    {
        corpse.revive_hud_elem destroy();
        corpse.revive_hud_elem = undefined;
    }

    self.loadout = undefined;
    wait 0.1;
    corpse delete();
    self.e_chugabud_corpse = undefined;
}

// ============================================================================
//  zmqol_whoswho_overlay_*  -  v1.99.14. THE DOWNED-STATE SCREEN OVERLAY.
//
//  User, three rounds running: "who's who is still missing it's visual fx",
//  while confirming the AUDIO works. That combination proved the script half was
//  already correct - stock's activate_chugabud_effects_and_audio() (:745-762)
//  activates the visionset and writes both clientfields from the same four
//  consecutive lines, so if the sting and looper are audible, all of it ran.
//
//  🛑 THE CAUSE IS THIS MOD'S OWN NIGHT MODE, AND CHECKPOINT 60 NAMED IT AS THE
//  SUSPECT BEFORE THIS WAS CHASED. qol_options.gsc::qol_opt_night_on() sets
//
//        r_filmUseTweaks 1
//        vc_rgbh / vc_yl / vc_yh / vc_rgbl / vc_fsm / vc_fbm
//
//  and those vc_* dvars are the SAME colour-grade parameters a .vision file
//  carries - compare zm_whos_who.vision, which is literally a list of vc_LIB,
//  vc_RGBH, vc_YL, vc_SMR ... values. r_filmUseTweaks 1 tells the renderer to
//  use the dvars INSTEAD of the active visionset. So vsmgr_activate() succeeds,
//  the visionset becomes current, and the renderer ignores it. Silently.
//
//  That also explains why shipping the five Die-Rise-only assets in v1.99.13
//  changed nothing visible: they were necessary and they were not sufficient.
//
//  THE FIX: drive the overlay through the same channel night mode uses, which is
//  the one channel proven to reach the renderer on every map in this mod.
//  🛑 The values are NOT invented - they are read straight out of
//  vision/zm_whos_who.vision as dumped from zm_highrise.ff with the Unlinker,
//  and only the six vc_* dvars night mode itself proves exist are used. The
//  file's other entries (vc_SMR, vc_HMR, vc_MMR ...) are left alone rather than
//  guessed at.
//
//  📝 The stock filter pass and the visionset are NOT removed. They are the
//  authentic Die Rise path, their assets now ship (mod_whoswho.zone), and with
//  night mode off they do the work. This runs on top and is what makes the
//  effect survive night mode.
// ============================================================================
zmqol_whoswho_overlay_connect()
{
    for (;;)
    {
        level waittill( "connected", player );
        player thread zmqol_whoswho_overlay_watch();
        player thread zmqol_whoswho_glow_model_watch();
    }
}

// ============================================================================
//  zmqol_whoswho_glow_model_watch  -  v1.99.17. THE CLONE'S GLOW, SOLVED.
//
//  User, with a reference shot of Die Rise: the downed clone should have a
//  bright orange rim glow. Ours had none, even after v1.99.16 delivered the
//  clientfield to the corpse - the log confirms "clone glow set on a
//  script_model corpse" fired, and still nothing glowed.
//
//  🌟 THE REASON IS THE MATERIALS, AND IT IS MEASURABLE. Stock's glow works by
//  writing a shader constant to the corpse:
//        self mapshaderconstant( localclientnum, 0, "scriptVector3" );
//        self setshaderconstant( localclientnum, 0, 1.0, 0, 0, 0 );
//  A shader constant only does something if the model's MATERIAL is authored to
//  read it. Dumping both clone models and reading the material names out of the
//  GLB settles it:
//
//    c_zom_player_reporter_dlc1_fb  (Die Rise) -> ..._arm_g, ..._body_g,
//                                                 ..._gear_g, ..._head_g
//    c_zom_player_reporter_fb       (TranZit)  -> ..._arm,   ..._body,
//                                                 ..._gear,  ..._head
//
//  🛑 The `_g` suffix is the glow-capable variant, and a fastfile sweep finds
//  every `mc/mtl_c_zom_player_*_g` material in **zm_highrise.ff and nowhere
//  else**. So off Die Rise the clone is built from materials that cannot glow,
//  and the shader constant lands on nothing. Silently, as ever.
//
//  THE FIX IS STOCK'S OWN AND IT WAS SITTING IN PLAIN SIGHT: Die Rise sets
//  self.whos_who_shader (zm_highrise.gsc:1185/1194/1203/1213), which
//  _zm_chugabud::chugabud_spawn_corpse() passes to spawn_player_clone() as
//  `forcemodel`. Nothing outside Die Rise ever sets it, so nothing outside Die
//  Rise gets the glow-capable model. Setting it is the whole fix.
//
//  🛑 zm_transit ONLY, and that is an asset limit, not a shortcut:
//    zm_transit  Victis crew, same four characters as Die Rise -> works
//    zm_nuked    CIA / CDC agents (zm_nuked.gsc:653-665). No `_g` materials
//                exist for them anywhere in the game.
//    zm_tomb     Richtofen / Dempsey / Nikolai / Takeo. A sweep for
//                `mc/mtl_c_zom_tomb*_g` returns nothing - Treyarch never made
//                glow materials for the Origins crew.
//  Rather than put a Victis body on a Nuketown agent or an Origins hero, those
//  two keep the plain clone. Reported, not silently bodged.
//
//  📝 The index mapping is TranZit's own switch (zm_transit.gsc:1155-1181), not
//  Die Rise's assumed to carry over - they happen to agree: 0 oldman,
//  1 reporter, 2 farmgirl, 3 engineer.
// ============================================================================
zmqol_whoswho_glow_model_watch()
{
    self endon( "disconnect" );
    level endon( "end_game" );

    //  v1.99.18 - asks the one predicate rather than testing level.script here.
    //  The registration, the precache and the client twin all read the same
    //  list; a second copy of it is how v1.49.0 turned one boot crash into a
    //  different boot crash.
    if ( !zmqol_whoswho_clone_glow_enabled() )
        return;

    for (;;)
    {
        self waittill( "spawned_player" );

        if ( !isdefined( self.characterindex ) )
            continue;

        str_model = zmqol_whoswho_glow_model( self.characterindex );

        if ( isdefined( str_model ) )
            self.whos_who_shader = str_model;
    }
}

zmqol_whoswho_glow_model( n_index )
{
    switch ( n_index )
    {
        case 0:  return "c_zom_player_oldman_dlc1_fb";
        case 1:  return "c_zom_player_reporter_dlc1_fb";
        case 2:  return "c_zom_player_farmgirl_dlc1_fb";
        case 3:  return "c_zom_player_engineer_dlc1_fb";
    }

    return undefined;
}

//  Polls stock's own flag rather than hooking anything: chugabud_laststand()
//  threads activate_chugabud_effects_and_audio(), which sets
//  self.whos_who_effects_active = 1 and threads the deactivate that clears it.
//  That call is UNQUALIFIED and same-file, so replaceFunc cannot reach it
//  (AI_CONTEXT rule / CLAUDE.md §4 failure mode 1) - a watcher is the correct
//  shape, and it is the same conclusion [[t6-replacefunc-threaded-calls]] records.
zmqol_whoswho_overlay_watch()
{
    self endon( "disconnect" );
    level endon( "end_game" );

    b_on = 0;

    for (;;)
    {
        b_active = isdefined( self.whos_who_effects_active ) && self.whos_who_effects_active == 1;

        //  ====================================================================
        //  🛑 v1.99.18 - BACK TO TWO STATES. v1.99.17's THIRD STATE COULD NEVER
        //  FIRE, AND THE LOG PROVES IT: not one
        //  "[zm_qol] whoswho overlay: LAST STAND" line in a session with two
        //  full Who's Who downs on Diner.
        //
        //  🌟 THE PREMISE WAS WRONG, AND STOCK SAYS SO IN ONE LINE. With Who's
        //  Who the player NEVER ENTERS LAST STAND AT ALL. _zm.gsc:4239, inside
        //  the damage override:
        //
        //        if ( self.lives > 0 && self hasperk( "specialty_finalstand" ) )
        //        {
        //            self.lives--;
        //            if ( isdefined( level.chugabud_laststand_func ) )
        //            {
        //                self thread [[ level.chugabud_laststand_func ]]();
        //                return 0;                 <-- RETURNS HERE
        //            }
        //        }
        //
        //  That `return 0` is before player_laststand(), so the engine's own
        //  visionsetlaststand( "zombie_last_stand", 1 ) at _zm.gsc:2022 never
        //  runs and player_is_in_laststand() is never true. The three seconds on
        //  the floor are chugabud_fake_death() - a freeze, not a last stand.
        //
        //  So there is exactly ONE grade in Die Rise's Who's Who, the
        //  zm_whos_who visionset, and it starts when the ghost stands up. The
        //  user's own reference shot shows it on a player who is upright and
        //  moving. Chasing a second grade was chasing something stock does not
        //  do.
        //  ====================================================================
        if ( b_active != b_on )
        {
            b_on = b_active;

            if ( b_active )
                self zmqol_whoswho_overlay_on();
            else
                self zmqol_whoswho_overlay_off();
        }

        //  The clone's glow is a separate clientfield and a separate bug - see
        //  zmqol_whoswho_clone_glow(). Driven from here because stock's own write
        //  sits inline in chugabud_laststand(), which nothing can hook.
        if ( b_active )
        {
            self zmqol_whoswho_clone_glow();

            //  v1.99.43 - and the corpse's DAMAGE callback has exactly the same
            //  actor-vs-script_model bug as its glow did. Armed from the same
            //  loop, for the same reason. See zmqol_whoswho_corpse_revive_arm().
            self zmqol_whoswho_corpse_revive_arm();
        }
        else
        {
            self.zmqol_clone_glow_done = undefined;      // re-arm for the next down
            self.zmqol_corpse_revive_armed = undefined;
        }

        wait 0.05;
    }
}

// ============================================================================
//  zmqol_whoswho_clone_glow  -  v1.99.16. THE DOWNED CLONE'S GLOW.
//
//  User: "my downed character model is missing the glow sort of fx".
//
//  🌟 THE CAUSE, MEASURED, NOT GUESSED. Stock lights the clone with
//        corpse setclientfield( "clientfield_whos_who_clone_glow_shader", 1 );
//  (_zm_chugabud.gsc:72) and that field is registered on the **actor** set.
//  But look at how the clone is created - _zm_clone.gsc:27-38:
//
//        spawner = getent( "fake_player_spawner", "targetname" );
//        if ( isdefined( spawner ) )  { clone = spawner spawnactor(); clone.isactor = 1; }
//        else                         { clone = spawn( "script_model", origin ); clone.isactor = 0; }
//
//  🛑 So the clone is an ACTOR only on maps that ship a `fake_player_spawner`
//  entity. Dumped `mapents` with the Unlinker and counted the occurrences:
//
//        zm_highrise   1     <- Die Rise, where Who's Who is native. Actor.
//        zm_transit    0     <- script_model
//        zm_tomb       0     <- script_model
//
//  An `actor`-set clientfield written to a script_model is delivered to nothing,
//  silently. That is why the glow works on Die Rise and on no other map - and it
//  is the same silent-failure shape as every other Who's Who defect in this saga.
//
//  THE FIX: a `scriptmover` twin of the same field, set on the corpse when the
//  corpse is not an actor. The callback is stock's OWN
//  _zm_perks::chugabud_whos_who_shader - core client code, so it can be named
//  directly and nothing is reimplemented.
//
//  📝 Bit cost is on the `scriptmover` set, not `actor`. That matters: the actor
//  set is the scarce one (Origins sits at 32/32 after Who's Who, which is why
//  Buried is excluded), while scriptmover already carries Vulture's 4-bit field
//  here with room to spare.
// ============================================================================
zmqol_whoswho_clone_glow()
{
    //  v1.99.18 - the field only exists on the maps the predicate names, and
    //  setclientfield on an unregistered field is an error, not a no-op.
    if ( !zmqol_whoswho_clone_glow_enabled() )
        return;

    if ( isdefined( self.zmqol_clone_glow_done ) && self.zmqol_clone_glow_done )
        return;

    if ( !isdefined( self.e_chugabud_corpse ) )
        return;

    corpse = self.e_chugabud_corpse;
    self.zmqol_clone_glow_done = 1;

    //  An actor corpse is already handled by stock's own write; only the
    //  script_model case needs ours, and doing both would be a double write.
    if ( isdefined( corpse.isactor ) && corpse.isactor )
        return;

    corpse setclientfield( "zmqol_whoswho_clone_glow", 1 );
    println( "[zm_qol] whoswho: clone glow set on a script_model corpse" );
}

// ============================================================================
//  zmqol_whoswho_corpse_revive_arm  -  v1.99.43. SHOOTING YOUR OWN CORPSE WITH
//  THE PACK-A-PUNCHED BALLISTIC KNIFE NOW REVIVES YOU OFF DIE RISE.
//
//  User, 2026-08-18, on TranZit: "whenever I shot my downed character model it
//  didn't revive me like how the pap'd ballistic knife is supposed to do."
//
//  🌟 THE CAUSE IS THE GLOW BUG AGAIN, ONE LAYER DOWN, AND IT IS MEASURED.
//  _zm_clone::spawn_player_clone() ends with
//
//        clone.actor_damage_func = ::clone_damage_func;
//
//  and clone_damage_func() is what notifies "player_revived" for the four
//  upgraded ballistic-knife names (_zm_clone.gsc:65-73). But .actor_damage_func
//  is read in exactly ONE place in the entire stock dump -
//  _zm.gsc:4435, inside actor_damage_override(), which is reached only through
//        level.callbackactordamage = ::actor_damage_override_wrapper   (_zm.gsc:976)
//  🛑 That is the engine's ACTOR damage callback. A script_model never goes
//  through it, so on a script_model corpse clone_damage_func is dead code.
//
//  And the corpse is a script_model on every map but Die Rise. Same
//  fake_player_spawner census as the glow, re-dumped from mapents to be sure:
//
//        zm_highrise   1     <- actor.       Stock revive works, natively.
//        zm_transit    0     <- script_model. Dead.
//        zm_nuked      0     <- script_model. Dead.
//        zm_buried     0     <- script_model. Dead.
//
//  Corroborated live: this same session's log prints
//  "[zm_qol] whoswho: clone glow set on a script_model corpse" on TranZit, which
//  is the branch that only runs when corpse.isactor is false.
//
//  🛑 THIS IS PARITY, NOT A NEW FEATURE. The notify, its argument and the four
//  weapon names are all stock's; _zm_chugabud.gsc:89 waits on exactly
//  `corpse waittill( "player_revived", e_reviver )` and :91-92 has a dedicated
//  self-revive branch (`if ( e_reviver == self ) self notify( "whos_who_self_revive" )`),
//  so Treyarch wrote for the player shooting their OWN body. Nothing here
//  reimplements a revive; it re-delivers a message the engine stopped carrying.
//
//  📝 Die Rise is deliberately skipped - its corpse IS an actor, stock's own
//  path already fires, and arming both would notify twice.
// ============================================================================
zmqol_whoswho_corpse_revive_arm()
{
    if ( isdefined( self.zmqol_corpse_revive_armed ) && self.zmqol_corpse_revive_armed )
        return;

    if ( !isdefined( self.e_chugabud_corpse ) )
        return;

    corpse = self.e_chugabud_corpse;
    self.zmqol_corpse_revive_armed = 1;

    if ( isdefined( corpse.isactor ) && corpse.isactor )
        return;

    corpse thread zmqol_whoswho_corpse_damage_watch();

    //  v1.99.44 - and the damage notify NEVER ARRIVED, so the bolt is watched
    //  where stock itself watches it. See zmqol_whoswho_knife_impact_watch().
    self thread zmqol_whoswho_knife_impact_watch( corpse );
}

// ============================================================================
//  zmqol_whoswho_corpse_damage_watch  -  runs ON THE CORPSE
//
//  🛑 THE SHAPE IS STOCK'S, NOT INVENTED. A script_model takes damage through
//  setcandamage() + the "damage" notify, and the zombies codebase does this in
//  two places already:
//      _zm_equipment.gsc:1377-1387    setcandamage(1); health; waittill("damage")
//      _weaponobjects.gsc:495-502     + maxhealth, and switches on weaponname
//  The long argument list is copied from _weaponobjects.gsc:502 and cross-checked
//  against _zm_ai_basic.gsc:462 - the two disagree about whether slots 6/7 are
//  (modelname, tagname) or (tagname, modelname), but BOTH put **weaponname at
//  slot 9**, which is the only one read here.
//
//  🛑 WHY HEALTH IS KEPT TOPPED UP. Stock's clone_damage_func returns
//  `idamage = 0` - the actor corpse takes no damage at all. Restoring health on
//  every hit is how a script_model reproduces that, and it is why a zombie
//  mauling the body cannot destroy it.
//
//  📝 setcandamage() makes the corpse stop bullets. That is not a regression -
//  it is what the Die Rise corpse already does, being an actor. This brings the
//  other maps to Die Rise's behaviour rather than away from it.
//
//  📝 THE PRINT IS A PROBE AND IT IS CAPPED. The one thing that could not be
//  settled offline is whether a ballistic-knife bolt generates a "damage" notify
//  on a script_model at all. This prints the weapon name of the first few hits,
//  so one game distinguishes "the bolt never reaches the corpse" from "it
//  reaches it under a different name" without another round trip. Capped at 12
//  lines so a zombie chewing on the body cannot flood the log.
// ============================================================================
zmqol_whoswho_corpse_damage_watch()
{
    self endon( "death" );
    level endon( "end_game" );

    self setcandamage( 1 );
    self.maxhealth = 100000;
    self.health = self.maxhealth;

    n_printed = 0;

    for (;;)
    {
        self waittill( "damage", n_amount, e_attacker, v_dir, v_point, str_type, str_model, str_tag, str_part, str_weapon, n_idflags );

        //  Never let the body die, exactly as clone_damage_func's idamage = 0.
        self.health = self.maxhealth;

        if ( !isdefined( str_weapon ) )
            str_weapon = "<undefined>";

        if ( n_printed < 12 )
        {
            n_printed++;
            println( "[zm_qol] whoswho corpse: damage weapon='" + str_weapon + "'" );
        }

        if ( str_weapon == "knife_ballistic_upgraded_zm" ||
             str_weapon == "knife_ballistic_bowie_upgraded_zm" ||
             str_weapon == "knife_ballistic_no_melee_upgraded_zm" ||
             str_weapon == "knife_ballistic_sickle_upgraded_zm" )
        {
            println( "[zm_qol] whoswho corpse: ballistic knife hit - notifying player_revived" );
            self notify( "player_revived", e_attacker );
            return;
        }
    }
}

// ============================================================================
//  zmqol_whoswho_knife_impact_watch  -  v1.99.44. THE BOLT IS WATCHED WHERE
//  STOCK WATCHES IT, BECAUSE THE CORPSE NEVER RECEIVES DAMAGE AT ALL.
//
//  🛑 v1.99.43's watcher was armed and it recorded NOTHING. Measured, not
//  assumed: the 2026-08-18 03:17 TranZit session logged
//  "whoswho: clone glow set on a script_model corpse" - and that print sits
//  behind the same two guards, in the same loop, as the arming call, so the
//  damage watcher was running - yet the log carries not one
//  "whoswho corpse: damage weapon=" line while the user shot the body
//  repeatedly with the Pack-a-Punched knife. setcandamage() is not the missing
//  piece: a character xmodel carries no collision of its own, so the bolt goes
//  straight through the body and no damage event is ever raised on it.
//
//  🌟 SO USE THE HOOK TREYARCH USES FOR THIS EXACT WEAPON. Every ballistic
//  knife in zombies is a weapon OBJECT with a watcher -
//  _zm_weapons.gsc:462-463 registers "knife_ballistic" and
//  "knife_ballistic_upgraded" (Bowie and tazer-knuckle variants are added by
//  _zm_weap_bowie.gsc:17-18 and _zm_weap_tazer_knuckles.gsc:24-25 on the maps
//  that have them), and _zm_weap_ballistic_knife::on_spawn ends with
//
//        player notify( "ballistic_knife_stationary", retrievable_model, normal, prey );
//
//  That notify is not a guess: it is what puts the pick-your-knife-back-up
//  prompt in the world, and that prompt demonstrably works in game today, so
//  the path provably runs. It hands over the model that marks EXACTLY where the
//  bolt came to rest (retrievable_model.origin = the "stationary" endpos), the
//  entity it stuck into if any (prey), and the weapon it came from
//  (retrievable_model.name = watcher.weapon).
//
//  🌟 THE HIT TEST IS STOCK'S TOO, TWICE OVER.
//    - _zm_weap_staff_revive.gsc:45-64 - Origins' revive staff, the one other
//      "shoot a projectile at a downed body to revive it" in the game - does not
//      test a hitbox either. It takes the impact point and reviving anyone
//      within 32 units of it (n_closest_dist_sq = 1024).
//    - _zm_weap_thundergun.gsc:187-190 - the cylinder test used here verbatim:
//      pointonsegmentnearesttopoint( view_pos, end_pos, test_origin ), then
//      compare the distance to the radius.
//  Eye -> resting point is the bolt's flight line, so a bolt that passes
//  through the body and sticks in the wall behind counts, which is what Die
//  Rise's actor hitbox does natively. 32 units is the revive staff's own radius.
//
//  📝 The four upgraded names are stock's list from _zm_clone::clone_damage_func;
//  an un-upgraded knife does not revive there and does not revive here.
//
//  📝 Lifetime is the corpse. chugabud_corpse_cleanup() deletes it
//  (_zm_chugabud.gsc:183) on every exit from the Who's Who state, and the delete
//  raises "death" - the same handle stock's own wait_to_show_glowing_model()
//  hangs its endon on.
// ============================================================================
zmqol_whoswho_knife_impact_watch( corpse )
{
    self endon( "disconnect" );
    corpse endon( "death" );
    level endon( "end_game" );

    n_radius = 32;

    for (;;)
    {
        self waittill( "ballistic_knife_stationary", e_model, v_normal, e_prey );

        if ( !isdefined( e_model ) || !isdefined( e_model.name ) )
            continue;

        if ( !( e_model.name == "knife_ballistic_upgraded_zm" ||
                e_model.name == "knife_ballistic_bowie_upgraded_zm" ||
                e_model.name == "knife_ballistic_no_melee_upgraded_zm" ||
                e_model.name == "knife_ballistic_sickle_upgraded_zm" ) )
            continue;

        //  The body's centre, not its feet - corpse.origin sits on the ground.
        v_body = corpse.origin + ( 0, 0, 20 );
        v_rest = e_model.origin;
        v_near = pointonsegmentnearesttopoint( self geteye(), v_rest, v_body );

        n_path_dist = distance( v_body, v_near );
        n_rest_dist = distance( v_body, v_rest );

        b_hit = n_path_dist < n_radius || n_rest_dist < n_radius;

        //  If the corpse ever does stop a bolt, that is a hit with no argument.
        if ( isdefined( e_prey ) && e_prey == corpse )
            b_hit = 1;

        println( "[zm_qol] whoswho knife: bolt at rest, path " + int( n_path_dist ) + " rest " + int( n_rest_dist ) + " from corpse, hit=" + b_hit );

        if ( !b_hit )
            continue;

        println( "[zm_qol] whoswho knife: own corpse hit - notifying player_revived" );
        corpse notify( "player_revived", self );
        return;
    }
}

// ============================================================================
//  zmqol_whoswho_visionset_probe  -  v1.99.19. ONE LINE THAT SPLITS THE NEXT
//  FAILURE IN TWO.
//
//  The grade now rides stock's own visionset, and if it still does not show
//  there are exactly two possibilities: the visionset was never registered on
//  the server, or it was registered and something downstream drops it. Those
//  need different fixes, and telling them apart in game costs a boot. This
//  prints the answer at map load instead.
//
//  Runs one frame after the visionset manager finalizes - slot_index is only
//  assigned inside finalize_type_clientfields(), which the engine calls through
//  onfinalizeinitialization_callback at the end of the init pass.
// ============================================================================
zmqol_whoswho_visionset_probe()
{
    level endon( "end_game" );

    wait 1;

    if ( !isdefined( level.vsmgr ) || !isdefined( level.vsmgr[ "visionset" ] ) ||
         !isdefined( level.vsmgr[ "visionset" ].info ) ||
         !isdefined( level.vsmgr[ "visionset" ].info[ "zm_whos_who" ] ) )
    {
        println( "[zm_qol] whoswho visionset: NOT REGISTERED on the server - the grade cannot show" );
        return;
    }

    if ( !isdefined( level.vsmgr[ "visionset" ].info[ "zm_whos_who" ].slot_index ) )
    {
        println( "[zm_qol] whoswho visionset: registered but slot_index UNASSIGNED - no clientfield to travel on" );
        return;
    }

    println( "[zm_qol] whoswho visionset: registered, slot_index " +
             level.vsmgr[ "visionset" ].info[ "zm_whos_who" ].slot_index +
             ", total visionsets " + level.vsmgr[ "visionset" ].info.size );
}


//  ============================================================================
//  🌟 v1.99.19 - THE COPY IS GONE. WE WERE SWITCHING OFF THE THING THAT WORKS.
//
//  v1.99.18 lifted night mode's exposure and the red STILL did not show. That
//  ruled out brightness and left one candidate, and it was sitting in this
//  function's own first line since v1.99.14:
//
//        self setclientdvar( "r_filmUseTweaks", 1 );
//
//  🛑 r_filmUseTweaks is "Overide film effects with tweak dvar values"
//  (Plutonium's dvar_descriptions.json). Setting it to 1 makes the renderer
//  ignore EVERY VISIONSET - including stock's own zm_whos_who, the exact effect
//  this function exists to produce. So every version since v1.99.14 has turned
//  the real mechanism off and then tried to hand-reproduce it through the dvars,
//  on maps where the real mechanism would have worked unaided.
//
//  🌟 AND THE REAL MECHANISM IS FULLY WIRED UP. Both halves were verified before
//  this rewrite, not assumed:
//    * server - stock's own _zm_perks::turn_chugabud_on() (:1448-1449) calls
//      vsmgr_register_info( "visionset", "zm_whos_who", ... ), gated on
//      level.vsmgr_prio_visionset_zm_whos_who, which zmqol_enable_whoswho() sets.
//    * client - zm_expanded.csc::perks_register_clientfield() registers the
//      twin (v1.63.1), in the one place in that script that runs inside the
//      visionset manager's window.
//    * 🌟 AND THE FACT THAT THE MAP BOOTS AT ALL IS THE PROOF THEY AGREE.
//      _visionset_mgr::finalize_type_clientfields() derives visionset_slot's bit
//      width from how many visionsets each side registered; one side short is
//      "visionset_slot ... [CLIENT: 1 SERVER: 2]" at load, which is exactly the
//      error v1.63.1 hit and fixed. No error now = symmetric now.
//    * the vision file itself, vision/zm_whos_who.vision, ships inside mod.ff
//      (confirmed with Unlinker --list on the DEPLOYED file).
//
//  So there is nothing to reproduce. stock's activate_chugabud_effects_and_audio()
//  already calls vsmgr_activate( "visionset", "zm_whos_who", self ) - and we know
//  that function runs, because its audio siblings are confirmed working in game.
//
//  THIS FUNCTION'S WHOLE JOB IS NOW TO GET NIGHT MODE OUT OF THE WAY: drop the
//  three overrides that make the renderer ignore visionsets and dim the picture,
//  and put them back on the way out. Treyarch's own grade then renders through
//  Treyarch's own path, byte for byte, on every map.
//
//  📝 The 23 copied values are deleted rather than kept as a fallback. Two
//  mechanisms fighting over the same screen is what produced this bug.
//  📝 Night mode's exposure comes back from self.qol_night_exposure, which
//  qol_opt_night_on() stashes, so its per-map table stays in one place.
//  ============================================================================
zmqol_whoswho_overlay_on()
{
    //  🛑 0, NOT 1. See the block above - this one line was the bug.
    self setclientdvar( "r_filmUseTweaks", 0 );
    self setclientdvar( "r_exposureTweak", 0 );
    self setclientdvar( "r_bloomTweaks", 0 );

    println( "[zm_qol] whoswho overlay: ON (night mode suspended, stock visionset in charge)" );
}

//  Hand night mode its screen back. Only the three switches zmqol_whoswho_overlay_on()
//  turned off are turned on again - the vc_* values themselves were never touched,
//  so with r_filmUseTweaks 1 the map's night grade resumes exactly where it left off.
//
//  v1.99.19 - the 23-value restore that used to open this function is gone with the
//  23-value apply it existed to undo.
zmqol_whoswho_overlay_off()
{
    if ( getdvarintdefault( "night_mode", 0 ) )
    {
        self setclientdvar( "r_filmUseTweaks", 1 );
        self setclientdvar( "r_bloomTweaks", 1 );

        //  Night mode's darkness. The value is the one qol_opt_night_on()
        //  actually applied to THIS player, stashed by that function, so the
        //  per-map table is not copied here.
        if ( isdefined( self.qol_night_exposure ) )
        {
            self setclientdvar( "r_exposureTweak", 1 );
            self setclientdvar( "r_exposureValue", self.qol_night_exposure );
        }
    }

    println( "[zm_qol] whoswho overlay: OFF (night_mode=" + getdvarintdefault( "night_mode", 0 ) + ")" );
}

// ============================================================================
//  zmqol_whoswho_verify  -  the perk was given and did nothing
//
//  Reported on Origins: gave Who's Who with the chat command, got run over by
//  the tank, and went straight to game over with no clone and no second life.
//
//  The gate is _zm.gsc:4239, inside player_damage_override:
//
//      if ( self.lives > 0 && self hasperk( "specialty_finalstand" ) )
//      {
//          self.lives--;
//          if ( isdefined( level.chugabud_laststand_func ) )
//          {
//              self thread [[ level.chugabud_laststand_func ]]();
//              return 0;
//          }
//      }
//
//  🛑 Note what happens when that inner isdefined FAILS: self.lives has ALREADY
//  been decremented and there is no else - so the player silently falls through
//  to the ordinary down, one life poorer. "Perk equipped, nothing happened, game
//  over" is precisely the shape of a missing level.chugabud_laststand_func.
//
//  Everything on the give side checks out statically, and was re-read rather
//  than assumed:
//    - give_perk() (our override, line ~4780) does set self.lives = 1 for
//      specialty_finalstand, same as stock.
//    - the .give<perk> command routes through _zm_perks::give_perk, which is
//      the function we replace, so it gets that block.
//    - _zm_perks::init() threads turn_chugabud_on() off
//      level.zombiemode_using_chugabud_perk, which we set in main(), before
//      init() runs.
//    - turn_chugabud_on()'s FIRST statement is _zm_chugabud::init(), and that
//      function's first statement sets level.chugabud_laststand_func - so even
//      a thread that dies on the loadfx calls two lines later should leave the
//      pointer set.
//
//  So the static read says it should work and the game says it does not, which
//  is the point where guessing again would cost another release (checkpoint 18
//  section 1). This verifies instead: it reports the pointer's real state to the
//  log, and if it is genuinely missing it installs it, which is a no-op whenever
//  stock did its job. _zm_chugabud::init() is safe to name from a root script -
//  _zm_perks.gsc calls it on every map, so the file resolves everywhere.
//
//  If the next log says OK and Who's Who still does nothing, the pointer is not
//  the cause and the damage path is - look at the tank first, since
//  zm_tomb_tank::tank_ran_me_over does disableinvulnerability() then
//  dodamage( self.health + 1000 ).
// ============================================================================
zmqol_whoswho_verify()
{
    level endon( "end_game" );

    // Poll rather than flag_wait: stock threads turn_chugabud_on() from
    // _zm_perks::init(), and nothing guarantees which flag it lands behind.
    for ( i = 0; i < 60; i++ )
    {
        if ( isdefined( level.chugabud_laststand_func ) )
        {
            println( "[zm_qol] whoswho: chugabud_laststand_func present after " + i + "s - stock turn_chugabud_on ran" );
            return;
        }

        wait 1;
    }

    println( "[zm_qol] whoswho: chugabud_laststand_func MISSING after 60s - stock turn_chugabud_on did not reach _zm_chugabud::init(). Repairing." );

    maps\mp\zombies\_zm_chugabud::init();

    if ( isdefined( level.chugabud_laststand_func ) )
        println( "[zm_qol] whoswho: repair OK, chugabud_laststand_func now set" );
    else
        println( "[zm_qol] whoswho: repair FAILED, _zm_chugabud::init() did not set the pointer" );
}

// ============================================================================
//  zmqol_enable_vulture  -  the 11th and LAST perk
//
//  Vulture Aid is Buried's, and with it the Wunderfizz can offer every perk
//  Black Ops II Zombies has. Enabled on the five maps that never shipped it;
//  Buried is excluded because it enables the perk itself, and re-running the
//  registration there would fight its own.
//
//  Everything about this mirrors zmqol_enable_electric_cherry() above, on
//  purpose - it is the same problem shape and the same three traps:
//
//  1. 🛑 TEST FOR THE BEHAVIOUR, NOT THE STRUCT. _register_undefined_perk()
//     creates level._custom_perks["specialty_nomotionsensor"] as a bare empty
//     struct the moment anything so much as names the perk, and wunderfizz.gsc's
//     getPerks() names it on every map. Guarding on the struct existing would
//     therefore skip the real registration and leave the perk cosmetic - the
//     exact half-dead state Electric Cherry was in. player_thread_give is the
//     thing register_perk_threads() actually sets, so that is what is checked.
//
//  2. 🛑 init_vulture() MUST RUN EXACTLY ONCE. It calls registerclientfield
//     eight times and a second call is fatal ("already registered"). Stock only
//     ever reaches it through vulture_perk_machine_think(), which _zm_perks::init()
//     threads - so it is called here, once, behind its own flag, and the
//     perk_machine_thread pointer is then cleared so init() cannot call it again.
//     Clearing that costs nothing: the machine loop only drives a physical
//     Vulture Aid machine, and on these five maps there is none - the Wunderfizz
//     is what hands the perk out.
//
//  3. 🛑 THE CLIENT MUST REGISTER THE IDENTICAL SET. Eight clientfields on the
//     server and a different eight on the client is EXE_CLIENT_FIELD_MISMATCH
//     for everyone before the map starts. zm_expanded.csc::zmqol_enable_vulture()
//     is the other half and is deliberately written to the same shape, with the
//     same map list, so the two cannot drift.
//
//  Called from perks(), which runs in main() - clientfields have to be
//  registered before the first snapshot, so this cannot move to init().
//
//  🛑 NOT verified in game yet. Requires build_ff.bat.
// ============================================================================
// ============================================================================
//  zmqol_vulture_enabled  -  THE ONE map list, asked by every site
//
//  🛑 TWO MAPS PHYSICALLY CANNOT TAKE THIS PERK, AND THEY RAN OUT OF DIFFERENT
//  BUDGETS. Both errors are quoted because they look unrelated and are the same
//  problem:
//
//    zm_tomb   Trying to assign 1 bits for netfield zone_capture_zombie
//              but Client Field Set ACTOR is out of space.
//    zm_prison Trying to assign 5 bits for netfield vulture_perk_disease_meter
//              but Client Field Set TOPLAYER is out of space.
//
//  Every clientfield SET has its own fixed bit budget. Vulture Aid registers
//  eight fields spread across four sets, so it can hit the ceiling in more than
//  one place, and which ceiling it hits depends on what the MAP already spends:
//
//    Origins is heavy on ACTOR   - templars, crusaders, capture zones, panzer -
//                                  and vulture_perk_actor is 2 bits.
//    Mob is heavy on TOPLAYER    - afterlife, the plane, the shield, brutus -
//                                  and vulture_perk_disease_meter is 5 bits.
//
//  Neither is fixable by reordering or by a lower version number. The budget is
//  the budget, and the field that errors is whichever one asks LAST - so on both
//  maps the name in the message is the map's own field, not ours. Read those
//  errors as "someone before me used the space", never as "this field is broken".
//
//  There IS a way back for both, and it is the same way: the two expensive fields
//  drive only cosmetics - vulture_perk_actor is the zombie eye glow and stink
//  trail, vulture_perk_disease_meter is the stink meter - so skipping just those
//  on BOTH sides would leave a working perk minus one visual each. The client
//  half lives in clientscripts\mp\zombies\_zm_perk_vulture.csc, which this
//  project ships as COMPILED bytecode; it would have to be decompiled, edited and
//  re-shipped as raw text. A real option and a bigger job than a boot fix.
//
//  📝 A clientfield budget is a shared global resource with no per-mod share.
//  Budget against the FULLEST map, not the emptiest, and expect different maps to
//  run out in different sets.
//
//  🛑 AND IT LIVES IN ONE FUNCTION FOR A REASON. v1.49.0 wrote this list into
//  zmqol_enable_vulture() and its client twin but forgot
//  zmqol_register_vulture_visionset(), which then registered a server-side
//  overlay the client did not have and turned a boot crash into a different boot
//  crash. A list copied into three places drifts; it drifted the first time it
//  was copied.
// ============================================================================
//  ✅ RESOLVED (v1.55.0) - ORIGINS AND MOB ARE NO LONGER EXCLUDED.
//
//  The paragraph above says the way back is to skip just the one expensive
//  cosmetic field on each map, on BOTH sides, and calls the client half "a
//  bigger job than a boot fix" because the client script ships as compiled
//  bytecode. That job is done:
//
//    zm_tomb    drops vulture_perk_actor          (2 bits, actor)   - eye glow
//                                                                     + stink trail
//    zm_prison  drops vulture_perk_disease_meter  (5 bits, toplayer) - stink meter
//
//  Server side: maps\mp\zombies\_zm_perk_vulture.gsc already ships raw, so the
//  two registrations and all seven use sites are gated there directly on
//  zmqol_vulture_has_actor_field() / zmqol_vulture_has_disease_meter().
//
//  Client side: the compiled .csc is NOT replaced. Only init_vulture is
//  re-implemented, in scripts\zm\zm_expanded.csc - read the long comment above
//  zmqol_init_vulture_trimmed() there for why shipping the decompiled .csc raw
//  was tried and rejected (the decompile is lossy, and it would have degraded
//  the three maps where the perk already works).
//
//  Each map loses exactly one visual and keeps the perk.
zmqol_vulture_enabled()
{
    map = getDvar( "mapname" );

    // ========================================================================
    //  🔬 MEASUREMENT DVAR, v1.78.0 - `zmqol_vulture 0` forces the perk off
    //  everywhere. DEFAULT 1, so shipped behaviour is byte-identical to v1.77.0.
    //
    //  WHY IT EXISTS. TranZit classic dies at `vulture_perk_toplayer`, and the
    //  source-derived bit accounting cannot be trusted to size the hole: it
    //  totals TranZit at 65 while Buried classic runs at >=71 and boots. About
    //  28 bits of TranZit's real usage are unexplained, and every offline
    //  search for them came back empty (the mod's own registerclientfield
    //  calls, weapon includes, buildables, powerups, the replaced/ folder).
    //
    //  This dvar buys ONE number that no amount of reading can produce: does
    //  TranZit classic load with Vulture absent?
    //    - loads  => Vulture alone is the overflow, deficit <= 10 bits
    //                (its 9 + the overlay_lerp 4->5 its 31-step stink forces)
    //    - fails  => the next error names the next field, which is another
    //                exact zero-free-bits measurement, and Vulture is not the
    //                whole story
    //
    //  🛑 IT IS A PROBE, NOT A FIX, AND NOT A SHIPPED OPTION. Nothing decides
    //  to leave Vulture off anywhere on the strength of this dvar; it exists to
    //  size the problem. No degraded variant gets shipped either way.
    //
    //  🛑 THE CLIENT TWIN IS zm_expanded.csc::zmqol_vulture_enabled() AND IT
    //  READS THE SAME DVAR WITH THE SAME DEFAULT. Both halves run in one
    //  process here, so they cannot observe different values - but if the two
    //  lines ever drift apart the toplayer/actor sets differ in width between
    //  server and client and every player is dropped with
    //  EXE_CLIENT_FIELD_MISMATCH. Change neither without the other.
    // ========================================================================
    if ( !getdvarintdefault( "zmqol_vulture", 1 ) )
        return 0;

    if ( map == "zm_buried" )   // ships the perk itself
        return 0;

    // ========================================================================
    //  v1.59.0 - VULTURE IS OFF ON ORIGINS, and this is not a budget tweak. It
    //  is the "perfectly or not at all" rule applied to a perk that CANNOT be
    //  whole here.
    //
    //  User, 2026-08-07, final rule: "It's either the thing I want you to add
    //  is added exactly how it'd work with it's original implementation fully
    //  intact, no compromises, or you don't even bother."
    //
    //  🛑 PROVEN IMPOSSIBLE, not assumed. Vulture needs bits in two sets that
    //  Origins has none of:
    //
    //      vulture_perk_scriptmover   4 bits   scriptmover   Origins 32/32
    //      vulture_perk_actor         2 bits   actor         Origins 31/32
    //
    //  1. The ceiling is 32 and it is measured, not inferred: across all 48
    //     per-map dumps in Black Ops 2 Grand Resources\...\Clientfields\, NO
    //     map exceeds 32 in either set - and the map that reaches exactly 32 in
    //     scriptmover IS Origins.
    //  2. The ceiling was also hit for real by this project:
    //         zm_tomb: Trying to assign 1 bits for netfield zone_capture_zombie
    //         but Client Field Set ACTOR is out of space
    //     which is Origins' 31 stock bits plus vulture_perk_actor's 2.
    //  3. None of Origins' 32 scriptmover bits belong to this mod. They are
    //     element_glow_fx (4), staff_charger (3), powerup_fx (3),
    //     play_artillery_barrage (2), perk_bottle_cycle_state (2), bryce_cake
    //     (2) and the rest - the staffs, the generators, the tank. Freeing 4
    //     means deleting an Origins system to bolt on a perk, which is a worse
    //     compromise than not shipping the perk.
    //
    //  v1.55.0 shipped it here anyway with vulture_perk_actor and
    //  vulture_perk_scriptmover dropped, calling it "each map loses exactly one
    //  visual and keeps the perk". In practice Origins lost the zombie eye
    //  glow, the stink trail, the stink pile and (from v1.58.4) the meter. That
    //  is four missing visuals, and the user found every one of them.
    //
    //  📝 Nothing else needs changing when this returns 0. getPerks() gates
    //  Vulture on level._custom_perks[ "specialty_nomotionsensor" ], which is
    //  only defined by the enable path this guards, so the Wunderfizz list
    //  drops to 11 by itself. The visionset registration asks this same
    //  function. That is exactly why the list lives in ONE place.
    //
    //  🛑 The client twin is zm_expanded.csc::zmqol_vulture_enabled(). Both
    //  must agree or the toplayer/actor sets differ in width between server and
    //  client and everyone is dropped with EXE_CLIENT_FIELD_MISMATCH.
    if ( map == "zm_tomb" )     // cannot be complete here - see above
        return 0;

    // ========================================================================
    //  v1.83.0 - VULTURE IS OFF ON TRANZIT. Same rule, different set.
    //
    //  🛑 THIS IS THE FIX FOR THE ONLY MAP THE MOD COULD NOT BOOT, and the user
    //  had to report it twice because it was filed as "known" instead of open:
    //
    //      Trying to assign 1 bits for netfield vulture_perk_toplayer
    //      but Client Field Set toplayer is out of space.
    //
    //  WHY THE ERROR NAMES THIS FIELD, AND WHY THAT IS THE ANSWER. The boot log
    //  puts the COM_ERROR *after* every init() has run - after
    //  `GSC Executed "scripts/zm/zm_transit/zm_transit::init()"` - so bits are
    //  assigned when the clientfield system finalizes, walking the registration
    //  order. The field the error names is therefore the exact point at which
    //  the running total crosses the ceiling: everything registered BEFORE
    //  vulture_perk_toplayer fits, and Vulture's block is the overflow.
    //
    //  WHAT TURNING IT OFF HERE GIVES BACK ON TRANZIT - 10 toplayer bits:
    //        vulture_perk_toplayer        1
    //        sndVultureStink              1
    //        vulture_perk_disease_meter   5
    //        perk_vulture                 2
    //        overlay_lerp 5 -> 4          1   (the 31-step vulture_stink_overlay
    //                                          is the widest overlay the mod
    //                                          adds; without it the next widest
    //                                          is zombie blood at 15 steps)
    //  plus 2 actor, 4 scriptmover, 1 zbarrier and 1 world bit it no longer asks
    //  for. Every one of those is gated on this function, which is why the list
    //  lives in one place.
    //
    //  🛑 WHY NOT SHRINK SOMETHING INSTEAD. vulture_perk_disease_meter's 5 bits
    //  could be moved to `allplayers`, where TranZit uses 25 of 32. That is a
    //  tune of a stock field, which this project does not do, and it frees 5
    //  where 10 are needed. Narrowing the perk fields is not available either -
    //  they are 2 bits wide on EVERY map because that is the width stock
    //  hardcodes in perks_register_clientfield(), and perk_pause() writes the
    //  value 2 into them, which 1 bit cannot hold.
    //
    //  🛑 CORRECTED v2.9.13. This used to say they were 2 bits "because TranZit
    //  ships emp_grenade_zm, which is stock's own rule". That was WRONG on both
    //  counts: stock's function hardcodes 2 and never mentions the EMP, and the
    //  game's own per-map clientfield dumps show 2 bits on all six maps
    //  including the five with no EMP. The EMP conditional was this mod's own
    //  invention and has been removed - see the block on
    //  perks_register_clientfield() itself.
    //
    //  📝 TranZit keeps 11 perks. getPerks() gates Vulture on
    //  level._custom_perks[ "specialty_nomotionsensor" ], defined only by the
    //  enable path this guards, so the Wunderfizz list drops by itself.
    //
    //  🛑 The client twin is zm_expanded.csc::zmqol_vulture_enabled(). Both must
    //  agree or every player is dropped with EXE_CLIENT_FIELD_MISMATCH.
    // ========================================================================
    //  v1.84.0 - AND ONLY ON CLASSIC. The survival locations keep all twelve.
    //
    //  User, 2026-08-13: *"the perk limit has been dropped to 11 for diner, and
    //  presumably the other survival maps as well, those maps were working fine
    //  with all 12 perks."* Correct - v1.83.0 gated on the map name alone, and
    //  every TranZit survival and grief location is also `zm_transit`, so they
    //  all lost a perk they had room for.
    //
    //  🌟 MEASURED, from the per-map dumps in
    //  Black Ops 2 Grand Resources\...\Clientfields\ - stock toplayer bits for
    //  every shipped zm_transit configuration:
    //
    //        38   zclassic  transit      <- the only one that overflows
    //        28   zgrief    (all 7 locations)
    //        27   zstandard (all 7 locations: diner, town, farm, power,
    //                        cornfield, tunnel, transit)
    //        24   dr_zcleansed
    //
    //  Classic carries ELEVEN more stock bits than any survival location, which
    //  is exactly why the survivals were running twelve perks happily while
    //  classic could not load at all. Vulture needs 10. The survivals have room.
    //
    //  🛑 WHY ui_zm_mapstartlocation AND NOT g_gametype. The failing boot log
    //  printed both, from replaced\utility.gsc::struct_class_init:
    //        [zm_qol] struct_class_init - gametype=zclassic location=transit
    //  so either would identify it - but `g_gametype` is a server dvar and this
    //  test has to give the SAME answer inside zm_expanded.csc. The client half
    //  already reads `ui_zm_mapstartlocation` in four places, and the comment
    //  above zmqol_wallbuy_match_string() documents why that dvar in particular
    //  is safe here: `_zm::init()` has not assigned level.scr_zm_* yet at this
    //  point, and both sides read this very dvar later, so they always agree.
    //
    // ========================================================================
    //  v1.89.0 - AND THE GAMETYPE TOO. 🛑 THIS CORRECTS A WRONG CLAIM THAT
    //  SHIPPED IN v1.84.0's COMMENT HERE, WHICH READ:
    //
    //      "zstandard/zgrief at location "transit" are not reachable from the
    //       menus ... they fall on the safe side of this test"
    //
    //  THE FIRST HALF IS FALSE. **Bus Depot is `zstandard` at location
    //  `transit`** and it is on the survival menu. The user played it
    //  2026-08-13 and the boot log printed both configurations back to back:
    //
    //      [zm_qol] struct_class_init - gametype=zclassic  location=transit
    //      [zm_qol] struct_class_init - gametype=zstandard location=transit
    //
    //  So the location-only test caught Bus Depot as well and took a perk it
    //  had room for - the SAME defect as v1.83.0, which cost every TranZit
    //  survival a perk, just narrowed to the one location that shares classic's
    //  name. Bus Depot is 27 stock toplayer bits; classic is 38. Vulture needs
    //  10. Only classic overflows.
    //
    //  🛑 ui_gametype, and it is as safe as the dvar beside it - VERIFIED, not
    //  assumed. zmqol_wallbuy_match_string() reads these TWO dvars together, on
    //  BOTH halves (zm_expanded.csc:439 and locs\loc_common.gsc:157), at
    //  struct_class_init time - strictly earlier than this - and the wallbuys
    //  it drives work today. Its comment records why: _zm::init() has not
    //  assigned level.scr_zm_* yet this early, and both sides read these very
    //  same dvars later, so they cannot disagree.
    //
    //  📝 zgrief at transit now keeps Vulture too, correctly - 28 stock bits.
    //
    //  🛑 The client twin is zm_expanded.csc::zmqol_vulture_enabled(). Both
    //  must test BOTH dvars or the sets differ in width between server and
    //  client and every player is dropped with EXE_CLIENT_FIELD_MISMATCH.
    // ========================================================================
    //  🛑 THE TEST IS INVERTED ON PURPOSE - it asks "is this NOT a survival or
    //  grief game", not "is this classic". The two are equivalent for every
    //  value the menus can produce, but they fail in OPPOSITE directions if
    //  ui_gametype is somehow not readable this early:
    //
    //      == "zclassic"     unset -> Vulture ON on classic  -> WILL NOT BOOT
    //      != "zstandard"    unset -> Vulture OFF on classic -> boots, and only
    //      && != "zgrief"             Bus Depot loses a perk
    //
    //  The second is a cosmetic loss on one location; the first is the crash
    //  this whole branch exists to prevent. Err toward the map that boots.
    str_gametype = getdvar( "ui_gametype" );

    if ( map == "zm_transit" &&
         getdvar( "ui_zm_mapstartlocation" ) == "transit" &&
         str_gametype != "zstandard" && str_gametype != "zgrief" )
        return 0;

    return 1;
}

zmqol_enable_vulture()
{
    if ( !zmqol_vulture_enabled() )
        return;

    if ( !isdefined( level._custom_perks ) )
        level._custom_perks = [];

    if ( isdefined( level._custom_perks[ "specialty_nomotionsensor" ] ) &&
         isdefined( level._custom_perks[ "specialty_nomotionsensor" ].player_thread_give ) )
        return;

    maps\mp\zombies\_zm_perk_vulture::enable_vulture_perk_for_level();

    if ( !isdefined( level.zmqol_vulture_inited ) )
    {
        level.zmqol_vulture_inited = 1;
        maps\mp\zombies\_zm_perk_vulture::init_vulture();
    }

    if ( isdefined( level._custom_perks[ "specialty_nomotionsensor" ] ) )
        level._custom_perks[ "specialty_nomotionsensor" ].perk_machine_thread = undefined;
}

// ============================================================================
//  zmqol_enable_electric_cherry
//
//  Makes Electric Cherry the 9th perk on the maps that never shipped it, which
//  is what stops Wunderfizz at 8 - getPerks() reads level._custom_perks, so a
//  perk the map never registered can never be offered. Reported in game: after
//  eight perks the machine says "You have all 8 perks".
//
//  Stock enables it on Mob of the Dead (zm_prison.gsc:111) and Origins
//  (zm_tomb.gsc:180) only, so those two are EXCLUDED here - registering a perk
//  twice re-registers its clientfields, which is an error in itself.
//
//  maps\mp\zombies\_zm_perk_electric_cherry is a CORE module, so referencing it
//  from this root script is legal under AI_CONTEXT rule 2. Its assets are not
//  core, though - models, fx, the bottle weapon and the client .csc all come
//  from zm_prison(.ff/_patch.ff) via zone_source\mod_locations.zone.
//
//  🛑 WHY init_electric_cherry() IS CALLED HERE AND NOT LEFT ALONE.
//  enable_...for_level() only REGISTERS the perk. The clientfield
//  "electric_cherry_reload_fx" is registered by init_electric_cherry(), while the
//  CLIENT registers that field unconditionally through register_perk_init_thread.
//  Left alone the two sides can disagree by exactly one field and everyone is
//  dropped with EXE_CLIENT_FIELD_MISMATCH. Calling it here puts the server-side
//  registration in the same legal window - identical in shape to
//  zmqol_register_divetonuke_visionset above, and to
//  [[t6-visionset-registration-timing]].
//
//  🛑 AND WHY perk_machine_thread IS THEN CLEARED.
//  v1.18.1 shipped with the call above and nothing else, and every one of these
//  four maps died on load with:
//        COM_ERROR (1) Attempt to register ClientField electric_cherry_reload_fx
//        failed. Client Field set 'allplayers' either already contains a field
//        called electric_cherry_reload_fx, ...
//  The comment that used to sit here claimed the only stock caller of
//  init_electric_cherry() is electric_cherry_perk_machine_think(), which "runs
//  only once an Electric Cherry MACHINE is being processed". That is wrong.
//  _zm_perks::init() lines 101-110 thread EVERY registered custom perk's
//  perk_machine_thread with no check that any machine entity exists:
//        if ( isdefined( level._custom_perks[a_keys[i]].perk_machine_thread ) )
//            level thread [[ level._custom_perks[a_keys[i]].perk_machine_thread ]]();
//  and init_electric_cherry() is that thread's first statement. So it fired a
//  second time and took the server down.
//
//  Clearing the pointer is what stops it: the loop above is guarded on
//  isdefined(). Nothing is lost - the thread's whole body operates on
//  getentarray( "vendingelectric_cherry", ... ), which is empty on these maps,
//  then blocks forever on `level waittill( "electric_cherry_on" )`. The perk's
//  real behaviour (reload attack, perk_lost) is registered separately by
//  register_perk_threads() and is untouched.
//
//  Deleting our own init_electric_cherry() call instead would ALSO fix the crash,
//  but it would make registration depend on _zm_perks::init() reaching that loop -
//  and it does not always: it early-returns when vending_triggers.size < 1. That
//  gate is the documented cause of an earlier mismatch on this project, see
//  zm_qol\scripts\zm\zm_tomb\zm_tomb.gsc:111-124. Registering in main() and
//  removing the duplicate is not exposed to it.
//
//  🛑 The 9-perk result is still NOT verified in game. Needs build_ff.bat - the
//  client half is a .csc.
// ============================================================================
zmqol_enable_electric_cherry()
{
    map = getDvar( "mapname" );

    //  🛑 v2.9.30 - zm_buried REMOVED from this list. Buried classic failed to
    //  load at 71 toplayer bits vs the 63 stock spends (the fullest map in the
    //  game); perk_electric_cherry's 1 bit is part of the 8 cut. Full
    //  arithmetic in the Deadshot block inside perks(). The client twin's list
    //  in zm_expanded.csc::zmqol_enable_electric_cherry() changed in the same
    //  edit and MUST stay identical - one side wider is
    //  EXE_CLIENT_FIELD_MISMATCH before the map starts.
    //  v2.10.7 - MOB OF THE DEAD, NON-CLASSIC (Cell Block survival). User,
    //  2026-09-02: *"Guarantee Electric Cherry remains present and fully
    //  functional on Mob of the Dead (both standard Mob of the Dead and Cell
    //  Block Survival)."* Standard Mob is classic and native - untouched. On
    //  Cell Block the perk did not exist at all: stock zm_prison::main() only
    //  enables it inside `if ( is_gametype_active( "zclassic" ) )`
    //  (zm_prison.gsc:108-112), and the 6:33 AM Cell Block log printed a
    //  Wunderfizz "perk list (8)" with no specialty_grenadepulldeath in it.
    //  BO2-Reimagined enables it for every non-classic Mob mode
    //  (scripts\zm\zm_prison\zm_prison_reimagined.gsc:94-100, and the client
    //  twin at zm_prison_reimagined.csc:22-25) - the working precedent. No
    //  machine struct is tagged for cellblock in stock or Reimagined, so the
    //  Wunderfizz dispenses it, exactly like Jugg / Double Tap / Mule Kick /
    //  PhD there.
    //
    //  BUDGET (ERROR_CATALOGUE section 2: toplayer proven-safe ceiling 63).
    //  Cell Block survival, counted from the T6-Data-Archive zgrief_cellblock
    //  dump (41 toplayer bits stock; the same registrations run on zstandard)
    //  plus what this mod adds on zm_prison: perk_marathon 2, perk_tombstone 2,
    //  vulture_perk_toplayer 1 + sndVultureStink 1 + perk_vulture 2 (the 5-bit
    //  disease meter is already skipped on Mob), overlay_slot 1 + overlay_lerp 5
    //  (Vulture's 31-step stink overlay) = 55, and this perk's
    //  perk_electric_cherry adds 1 = 56. Zombie Blood and Who's Who are off
    //  on Mob already. allplayers: 17 stock + electric_cherry_reload_fx 2 = 19
    //  of 32. So the user's stated priority - "if the limits are exceeded,
    //  keep Electric Cherry over Vulture Aid" - is not triggered by this
    //  arithmetic; if a Cell Block boot ever fails with "Client Field Set
    //  toplayer is out of space", the documented lever is
    //  zmqol_vulture_enabled() (both twins) returning 0 for zm_prison, which
    //  frees 12 bits (5 of them the overlay_lerp only Vulture needs).
    //
    //  is_classic() reads the ui_zm_gamemodegroup dvar on BOTH sides
    //  (_zm_utility.gsc:23-27 / _zm_utility.csc:392-396), so the client twin
    //  in zm_expanded.csc::zmqol_enable_electric_cherry() evaluates the same
    //  condition from the same dvar. Change neither without the other.
    if ( map != "zm_transit" && map != "zm_nuked" && map != "zm_highrise" && !( map == "zm_prison" && !is_classic() ) )
        return;

    //  Stock's classic branch sets this beside the enable; _zm_ai_brutus reads
    //  it to add "vendingelectric_cherry" machines to his zone list (:2402) -
    //  harmless with no machine, kept for fidelity.
    if ( map == "zm_prison" )
        level.zombiemode_using_electric_cherry_perk = 1;

    // 🛑 THIS GUARD IS WHY THE PERK WENT HALF-DEAD - user: "with electric cherry
    // I see the visual effects but the sound effects are missing, also the
    // zombies aren't being effected by it".
    //
    // It used to bail whenever level._custom_perks["specialty_grenadepulldeath"]
    // merely EXISTED. But that entry is created by _register_undefined_perk() as
    // a bare empty struct - any code that so much as names the perk brings it
    // into being, with none of its behaviour attached. When that happened first,
    // this returned and enable_electric_cherry_perk_for_level() never ran, so
    // register_perk_threads() never set player_thread_give.
    //
    // The consequence is exactly the reported symptom set, because the perk
    // splits cleanly in two. Everything the user still SEES - the bottle, the
    // icon, the machine, the reload visuals - is clientfield-driven and comes
    // from elsewhere. Everything they LOST lives inside
    // electric_cherry_reload_attack(): the zmb_cherry_explode sound, the stun,
    // the tesla shock fx and the dodamage() call. That one thread is started
    // only by give_perk() doing [[ player_thread_give ]] (_zm_perks.gsc:2042,
    // and our own override at give_perk() below keeps that line) - so with the
    // pointer unset, the perk is cosmetic.
    //
    // So the test is now for the BEHAVIOUR being registered, not for the struct
    // existing. Re-running enable_electric_cherry_perk_for_level() is safe:
    // every register_* it calls is written `if ( !isdefined( ... ) )` and will
    // not overwrite a real registration.
    if ( !isdefined( level._custom_perks ) )
        level._custom_perks = [];

    if ( isdefined( level._custom_perks[ "specialty_grenadepulldeath" ] ) &&
         isdefined( level._custom_perks[ "specialty_grenadepulldeath" ].player_thread_give ) )
        return;

    maps\mp\zombies\_zm_perk_electric_cherry::enable_electric_cherry_perk_for_level();

    // 🛑 init_electric_cherry() must still run exactly ONCE - its
    // registerclientfield( "electric_cherry_reload_fx" ) is fatal on a second
    // call ("Attempt to register ClientField ... already registered"), which is
    // the crash the block above this function documents. Guard it on its own
    // flag rather than on the perk struct, so it stays once-only even though the
    // enable above may now run when it previously did not.
    if ( !isdefined( level.zmqol_ec_inited ) )
    {
        level.zmqol_ec_inited = 1;
        maps\mp\zombies\_zm_perk_electric_cherry::init_electric_cherry();
    }

    // Stop _zm_perks::init() from threading electric_cherry_perk_machine_think(),
    // whose first line calls init_electric_cherry() a second time. See above.
    if ( isdefined( level._custom_perks[ "specialty_grenadepulldeath" ] ) )
        level._custom_perks[ "specialty_grenadepulldeath" ].perk_machine_thread = undefined;
}

// ============================================================================
//  zmqol_dim_cherry_arcs  -  Electric Cherry's kill arc uses the SECONDARY
//  tesla shock (v2.9.30)
//
//  User, 2026-09-01: electrified zombies cause blinding screen flashes. Stock's
//  electric_cherry_death_fx() plays level._effect["tesla_shock"] on every
//  zombie the reload shock KILLS - at an empty clip that is every zombie
//  within 128 units, each one a 13-element / 10-sprite flash (measured from
//  BO1's raw .efx sources, which this T6 family derives from; peak sprite
//  size 525). Stock's own STUN arc, fx_zombie_tesla_shock_secondary, is the
//  same family at 7 elements / 5 sprites / peak 425 - Treyarch's lighter arc.
//
//  THE MECHANISM: repoint the _effect key, not replaceFunc. The only reader
//  of level._effect["tesla_shock"] in all 2,093 stock scripts is
//  electric_cherry_death_fx() (grepped, not assumed), and it is called
//  UNQUALIFIED from electric_cherry_reload_attack() in the same file - which
//  is replaceFunc failure mode #1 (dev CLAUDE.md §4): a replace would
//  silently not take for those calls. The key repoint reaches every caller.
//
//  No loadfx here - both handles are loaded by stock init_electric_cherry()
//  (lines 44-45), so this only copies an already-loaded handle and cannot hit
//  the loadfx-after-init window. The wait exists because cherry's init timing
//  differs between the ported maps (our perks(), main window) and its native
//  maps (Mob/Origins, machine think inside _zm_perks::init()); nobody can
//  drink the perk within the first seconds, so the poll always wins the race
//  that matters. If cherry is not on this map the keys never appear and this
//  exits after ~10s having touched nothing.
//
//  📝 Server-side only ON PURPOSE: network_safe_play_fx_on_tag() sends the fx
//  handle the server chose, and the zombie-attached arcs are all
//  server-played. No clientfield, no client twin, no symmetry risk.
// ============================================================================
zmqol_dim_cherry_arcs()
{
    for ( i = 0; i < 200; i++ )
    {
        if ( isdefined( level._effect ) &&
             isdefined( level._effect[ "tesla_shock" ] ) &&
             isdefined( level._effect[ "tesla_shock_secondary" ] ) )
        {
            level._effect[ "tesla_shock" ] = level._effect[ "tesla_shock_secondary" ];
            return;
        }

        wait 0.05;
    }
}

perks_register_clientfield()
{
	// ========================================================================
	//  🛑 v2.9.13 - THE `bits` VARIABLE WAS A FABRICATION. RESTORED TO STOCK.
	//
	//  This used to read `bits = 1;` and only widen to 2 when emp_grenade_zm was
	//  included, with a comment elsewhere in this file calling that "stock's own
	//  rule in perks_register_clientfield()". IT IS NOT STOCK'S RULE. Stock's
	//  _zm_perks.gsc hardcodes **2** for all eight perk fields and does not
	//  mention the EMP anywhere in the function - checked in the gsc-dump.
	//
	//  🌟 AND THE GAME'S OWN RUNTIME DUMPS AGREE. T6-Data-Archive's per-map
	//  clientfield dumps show 2-bit perk fields on EVERY map, including the five
	//  that ship no EMP grenade at all:
	//      Origins 2, Buried 2, Mob 2, Die Rise 2, Nuketown 2, TranZit 2.
	//
	//  🔴 SO THIS WAS A REAL, SHIPPED DEFECT, not just a cosmetic deviation.
	//  perk_pause() writes the value **2** into these fields
	//  (_zm_perks.gsc:2650) whenever a machine loses power. A 1-bit field cannot
	//  hold 2, so on all five non-TranZit maps the "perk disabled" client state
	//  was being truncated every time power dropped.
	//
	//  🛑 IT ALSO REMOVED AN ORDERING TRAP. Reading level.zombie_include_weapons
	//  here made the width depend on whether weapon registration had already run
	//  when the perks registered - and the CLIENT twin computed the same thing
	//  from its own separate list. Two independently-ordered reads deciding one
	//  shared bit width is exactly how EXE_CLIENT_FIELD_MISMATCH happens. A
	//  constant cannot desync.
	//
	//  COST: +1 bit per perk field on the five maps that were narrowed. That is
	//  what stock has always spent there. 🛑 toplayer's true ceiling is still
	//  unmeasured (ERROR_CATALOGUE section 2) - if a map now fails to load with
	//  "Client Field Set toplayer is out of space", that is this change, and
	//  this is the first place to look.
	//
	//  🛑 THE CLIENT TWIN IN zm_expanded.csc CHANGED IN THE SAME EDIT and must
	//  stay identical.
	// ========================================================================
	bits = 2;
	if (isdefined(level.zombiemode_using_additionalprimaryweapon_perk) && level.zombiemode_using_additionalprimaryweapon_perk)
	{
		registerclientfield("toplayer", "perk_additional_primary_weapon", 1, bits, "int");
	}
	if (isdefined(level.zombiemode_using_deadshot_perk) && level.zombiemode_using_deadshot_perk)
	{
		registerclientfield("toplayer", "perk_dead_shot", 1, bits, "int");
	}
	if (isdefined(level.zombiemode_using_doubletap_perk) && level.zombiemode_using_doubletap_perk)
	{
		registerclientfield("toplayer", "perk_double_tap", 1, bits, "int");
	}
	if (isdefined(level.zombiemode_using_juggernaut_perk) && level.zombiemode_using_juggernaut_perk)
	{
		registerclientfield("toplayer", "perk_juggernaut", 1, bits, "int");
	}
	if (isdefined(level.zombiemode_using_marathon_perk) && level.zombiemode_using_marathon_perk)
	{
		registerclientfield("toplayer", "perk_marathon", 1, bits, "int");
	}
	if (isdefined(level.zombiemode_using_revive_perk) && level.zombiemode_using_revive_perk)
	{
		registerclientfield("toplayer", "perk_quick_revive", 1, bits, "int");
	}
	if (isdefined(level.zombiemode_using_sleightofhand_perk) && level.zombiemode_using_sleightofhand_perk)
	{
		registerclientfield("toplayer", "perk_sleight_of_hand", 1, bits, "int");
	}
	if (isdefined(level.zombiemode_using_tombstone_perk) && level.zombiemode_using_tombstone_perk)
	{
		registerclientfield("toplayer", "perk_tombstone", 1, bits, "int");
	}
	if (isdefined(level.zombiemode_using_perk_intro_fx) && level.zombiemode_using_perk_intro_fx)
	{
		registerclientfield("scriptmover", "clientfield_perk_intro_fx", 1000, 1, "int");
	}
	if (isdefined(level.zombiemode_using_chugabud_perk) && level.zombiemode_using_chugabud_perk)
	{
		registerclientfield("toplayer", "perk_chugabud", 1000, 1, "int");
	}
	if (isdefined(level._custom_perks))
	{
		a_keys = getarraykeys(level._custom_perks);
		for (i = 0; i < a_keys.size; i++)
		{
			if (isdefined(level._custom_perks[a_keys[i]].clientfield_register))
			{
				level [[level._custom_perks[a_keys[i]].clientfield_register]]();
			}
		}
	}
}

init_client_flags()
{
	//  🛑 v2.2.0 - level.disable_deadshot_clientfield IS NO LONGER SET HERE.
	//  Stock sets it on Buried alone; this mod set it on every map, which
	//  deleted the `deadshot_perk` clientfield and with it the only call to
	//  usealternateaimparams() in the game - Deadshot's head snap on a
	//  controller. See the full note in zm_expanded.csc's
	//  init_client_flag_callback_funcs(), whose matching line went with it. The
	//  two sides must stay in step or it is EXE_CLIENT_FIELD_MISMATCH at load.
	if (isdefined(level.use_clientside_board_fx) && level.use_clientside_board_fx)
	{
		level._zombie_scriptmover_flag_board_horizontal_fx = 14;
		level._zombie_scriptmover_flag_board_vertical_fx = 13;
	}
	if (isdefined(level.use_clientside_rock_tearin_fx) && level.use_clientside_rock_tearin_fx)
	{
		level._zombie_scriptmover_flag_rock_fx = 12;
	}
	level._zombie_player_flag_cloak_weapon = 14;
	if (!(isdefined(level.disable_deadshot_clientfield) && level.disable_deadshot_clientfield))
	{
		registerclientfield("toplayer", "deadshot_perk", 1, 1, "int");
	}
	registerclientfield("actor", "zombie_riser_fx", 1, 1, "int");
	if (!(isdefined(level._no_water_risers) && level._no_water_risers))
	{
		registerclientfield("actor", "zombie_riser_fx_water", 1, 1, "int");
	}
	if (isdefined(level._foliage_risers) && level._foliage_risers)
	{
		registerclientfield("actor", "zombie_riser_fx_foliage", 12000, 1, "int");
	}
	if (isdefined(level.risers_use_low_gravity_fx) && level.risers_use_low_gravity_fx)
	{
		registerclientfield("actor", "zombie_riser_fx_lowg", 1, 1, "int");
	}
}

// give_perk() - stock override (originally from zm_expanded.gsc).
// 2026-07-30: the old "self perkHUD(perk);" pop-up call (folded in from
// custom_perkanimuncompiled.gsc, which replaceFunc'd this same stock function)
// was REMOVED from the end of this function. The perk pop-up is now drawn by
// the "Vanguard Perk Animation" module below, which simply listens for the
// "perk_acquired" notify this function already fires - so give_perk() no
// longer contains ANY HUD hook of its own.
// IMPORTANT for the new module: keep appending the perk to self.perks_active
// BEFORE notify("perk_acquired") (as below) - the listener reads the last
// entry of perks_active to work out which perk was just awarded.
give_perk( perk, bought )
{
    self setperk( perk );
    self.num_perks++;
    if ( isdefined( bought ) && bought )
    {
        self maps\mp\zombies\_zm_audio::playerexert( "burp" );
        if ( isdefined( level.remove_perk_vo_delay ) && level.remove_perk_vo_delay )
            self maps\mp\zombies\_zm_audio::perk_vox( perk );
        else
            self delay_thread( 1.5, maps\mp\zombies\_zm_audio::perk_vox, perk );
        self setblur( 4, 0.1 );
        wait 0.1;
        self setblur( 0, 0.1 );
        self notify( "perk_bought", perk );
    }

    self perk_set_max_health_if_jugg( perk, 1, 0 );

    if (!(isDefined(level.disable_deadshot_clientfield) && level.disable_deadshot_clientfield))
    {
        if ( perk == "specialty_deadshot" )
            self setclientfieldtoplayer( "deadshot_perk", 1 );
        else if ( perk == "specialty_deadshot_upgrade" )
            self setclientfieldtoplayer( "deadshot_perk", 1 );
    }

    if ( perk == "specialty_scavenger" )
        self.hasperkspecialtytombstone = 1;

    players = get_players();
    if ( use_solo_revive() && perk == "specialty_quickrevive" )
    {
        self.lives = 1;
        if ( !isdefined( level.solo_lives_given ) )
            level.solo_lives_given = 0;
        if ( isdefined( level.solo_game_free_player_quickrevive ) )
            level.solo_game_free_player_quickrevive = undefined;
        else
            level.solo_lives_given++;
        if ( level.solo_lives_given >= 3 )
            flag_set( "solo_revive" );
        self thread solo_revive_buy_trigger_move( perk );
    }
    if ( perk == "specialty_finalstand" )
    {
        self.lives = 1;
        self.hasperkspecialtychugabud = 1;
        self notify( "perk_chugabud_activated" );
    }

    if ( isdefined( level._custom_perks[perk] ) && isdefined( level._custom_perks[perk].player_thread_give ) )
        self thread [[ level._custom_perks[perk].player_thread_give ]]();

    self set_perk_clientfield( perk, 1 );

    maps\mp\_demo::bookmark( "zm_player_perk", gettime(), self );

    self maps\mp\zombies\_zm_stats::increment_client_stat( "perks_drank" );
    self maps\mp\zombies\_zm_stats::increment_client_stat( perk + "_drank" );
    self maps\mp\zombies\_zm_stats::increment_player_stat( perk + "_drank" );
    self maps\mp\zombies\_zm_stats::increment_player_stat( "perks_drank" );

    if ( !isdefined( self.perk_history ) )
        self.perk_history = [];
    self.perk_history = add_to_array( self.perk_history, perk, 0 );

    if ( !isdefined( self.perks_active ) )
        self.perks_active = [];
    self.perks_active[self.perks_active.size] = perk;

    //  🛑 NOTHING IS TRACKED HERE. v1.62.1 recorded perk acquisition order in
    //  this function; its probe measured tracked=0 after a .giveperks, i.e.
    //  this override does not run - the replaceFunc in main() is not taking,
    //  even for .giveperks' fully qualified call. It has presumably never run,
    //  and nothing noticed because this body is byte-equivalent to stock's.
    //  Slot order is now OBSERVED instead, by zmqol_perk_slot_watcher().
    self notify( "perk_acquired" );
    self thread perk_think( perk );
}

default_vending_precaching()
{
    if ( isdefined( level.zombiemode_using_pack_a_punch ) && level.zombiemode_using_pack_a_punch )
    {
        precacheitem( "zombie_knuckle_crack" );
        precachemodel( "p6_anim_zm_buildable_pap" );
        precachemodel( "p6_anim_zm_buildable_pap_on" );
        precachestring( &"ZOMBIE_PERK_PACKAPUNCH" );
        precachestring( &"ZOMBIE_PERK_PACKAPUNCH_ATT" );
        level._effect["packapunch_fx"] = loadfx( "maps/zombie/fx_zombie_packapunch" );
        level.machine_assets["packapunch"] = spawnstruct();
        level.machine_assets["packapunch"].weapon = "zombie_knuckle_crack";
        level.machine_assets["packapunch"].off_model = "p6_anim_zm_buildable_pap";
        level.machine_assets["packapunch"].on_model = "p6_anim_zm_buildable_pap_on";
    }

    if ( isdefined( level.zombiemode_using_additionalprimaryweapon_perk ) && level.zombiemode_using_additionalprimaryweapon_perk )
    {
        precacheitem( "zombie_perk_bottle_additionalprimaryweapon" );
        precacheshader( "specialty_additionalprimaryweapon_zombies" );
        precachemodel( "zombie_vending_three_gun" );
        precachemodel( "zombie_vending_three_gun_on" );
        precachestring( &"ZOMBIE_PERK_ADDITIONALWEAPONPERK" );
        level._effect["additionalprimaryweapon_light"] = loadfx( "misc/fx_zombie_cola_arsenal_on" );
        level.machine_assets["additionalprimaryweapon"] = spawnstruct();
        level.machine_assets["additionalprimaryweapon"].weapon = "zombie_perk_bottle_additionalprimaryweapon";
        level.machine_assets["additionalprimaryweapon"].off_model = "zombie_vending_three_gun";
        level.machine_assets["additionalprimaryweapon"].on_model = "zombie_vending_three_gun_on";
    }

    if ( isdefined( level.zombiemode_using_deadshot_perk ) && level.zombiemode_using_deadshot_perk )
    {
        precacheitem( "zombie_perk_bottle_deadshot" );
        precacheshader( "specialty_ads_zombies" );
        precachemodel( "p6_zm_al_vending_ads_on" );
        precachestring( &"ZOMBIE_PERK_DEADSHOT" );
        level._effect["deadshot_light"] = loadfx( "misc/fx_zombie_cola_dtap_on" );
        level.machine_assets["deadshot"] = spawnstruct();
        level.machine_assets["deadshot"].weapon = "zombie_perk_bottle_deadshot";
        level.machine_assets["deadshot"].off_model = "p6_zm_al_vending_ads_on";
        level.machine_assets["deadshot"].on_model = "p6_zm_al_vending_ads_on";
        level.machine_assets["deadshot"].power_on_callback = ::vending_deadshot_power_on;
		level.machine_assets["deadshot"].power_off_callback = ::vending_deadshot_power_off;
    }

    if ( isdefined( level.zombiemode_using_doubletap_perk ) && level.zombiemode_using_doubletap_perk )
    {
        precacheitem( "zombie_perk_bottle_doubletap" );
        precacheshader( "specialty_doubletap_zombies" );
        precachemodel( "zombie_vending_doubletap2" );
        precachemodel( "zombie_vending_doubletap2_on" );
        precachestring( &"ZOMBIE_PERK_DOUBLETAP" );
        level._effect["doubletap_light"] = loadfx( "misc/fx_zombie_cola_dtap_on" );
        level.machine_assets["doubletap"] = spawnstruct();
        level.machine_assets["doubletap"].weapon = "zombie_perk_bottle_doubletap";
        level.machine_assets["doubletap"].off_model = "zombie_vending_doubletap2";
        level.machine_assets["doubletap"].on_model = "zombie_vending_doubletap2_on";
    }

    if ( isdefined( level.zombiemode_using_juggernaut_perk ) && level.zombiemode_using_juggernaut_perk )
    {
        precacheitem( "zombie_perk_bottle_jugg" );
        precacheshader( "specialty_juggernaut_zombies" );
        precachemodel( "zombie_vending_jugg" );
        precachemodel( "zombie_vending_jugg_on" );
        precachestring( &"ZOMBIE_PERK_JUGGERNAUT" );
        level._effect["jugger_light"] = loadfx( "misc/fx_zombie_cola_jugg_on" );
        level.machine_assets["juggernog"] = spawnstruct();
        level.machine_assets["juggernog"].weapon = "zombie_perk_bottle_jugg";
        level.machine_assets["juggernog"].off_model = "zombie_vending_jugg";
        level.machine_assets["juggernog"].on_model = "zombie_vending_jugg_on";
    }

    if ( isdefined( level.zombiemode_using_marathon_perk ) && level.zombiemode_using_marathon_perk )
    {
        precacheitem( "zombie_perk_bottle_marathon" );
        precacheshader( "specialty_marathon_zombies" );
        precachemodel( "zombie_vending_marathon" );
        precachemodel( "zombie_vending_marathon_on" );
        precachestring( &"ZOMBIE_PERK_MARATHON" );
        level._effect["marathon_light"] = loadfx( "maps/zombie/fx_zmb_cola_staminup_on" );
        level.machine_assets["marathon"] = spawnstruct();
        level.machine_assets["marathon"].weapon = "zombie_perk_bottle_marathon";
        level.machine_assets["marathon"].off_model = "zombie_vending_marathon";
        level.machine_assets["marathon"].on_model = "zombie_vending_marathon_on";
    }

    if ( isdefined( level.zombiemode_using_revive_perk ) && level.zombiemode_using_revive_perk )
    {
        precacheitem( "zombie_perk_bottle_revive" );
        precacheshader( "specialty_quickrevive_zombies" );
        precachemodel( "zombie_vending_revive" );
        precachemodel( "zombie_vending_revive_on" );
        precachestring( &"ZOMBIE_PERK_QUICKREVIVE" );
        level._effect["revive_light"] = loadfx( "misc/fx_zombie_cola_revive_on" );
        level._effect["revive_light_flicker"] = loadfx( "maps/zombie/fx_zmb_cola_revive_flicker" );
        level.machine_assets["revive"] = spawnstruct();
        level.machine_assets["revive"].weapon = "zombie_perk_bottle_revive";
        level.machine_assets["revive"].off_model = "zombie_vending_revive";
        level.machine_assets["revive"].on_model = "zombie_vending_revive_on";
    }

    if ( isdefined( level.zombiemode_using_sleightofhand_perk ) && level.zombiemode_using_sleightofhand_perk )
    {
        precacheitem( "zombie_perk_bottle_sleight" );
        precacheshader( "specialty_fastreload_zombies" );
        precachemodel( "zombie_vending_sleight" );
        precachemodel( "zombie_vending_sleight_on" );
        precachestring( &"ZOMBIE_PERK_FASTRELOAD" );
        level._effect["sleight_light"] = loadfx( "misc/fx_zombie_cola_on" );
        level.machine_assets["speedcola"] = spawnstruct();
        level.machine_assets["speedcola"].weapon = "zombie_perk_bottle_sleight";
        level.machine_assets["speedcola"].off_model = "zombie_vending_sleight";
        level.machine_assets["speedcola"].on_model = "zombie_vending_sleight_on";
    }

    if ( isdefined( level.zombiemode_using_tombstone_perk ) && level.zombiemode_using_tombstone_perk )
    {
        precacheitem( "zombie_perk_bottle_tombstone" );
        precacheshader( "specialty_tombstone_zombies" );
        precachemodel( "zombie_vending_tombstone" );
        precachemodel( "zombie_vending_tombstone_on" );
        precachemodel( "ch_tombstone1" );
        precachestring( &"ZOMBIE_PERK_TOMBSTONE" );
        level._effect["tombstone_light"] = loadfx( "misc/fx_zombie_cola_on" );
        level.machine_assets["tombstone"] = spawnstruct();
        level.machine_assets["tombstone"].weapon = "zombie_perk_bottle_tombstone";
        level.machine_assets["tombstone"].off_model = "zombie_vending_tombstone";
        level.machine_assets["tombstone"].on_model = "zombie_vending_tombstone_on";
    }

    //  ------------------------------------------------------------------
    //  WHO'S WHO. Stock's version of this block precaches EIGHT things; off
    //  Die Rise only three of them exist, so it is split in two.
    //
    //  🛑 THREE OF STOCK'S PRECACHES ARE FATAL OFF DIE RISE, and precaching an
    //  absent model/item is a hard load failure, not a warning:
    //      p6_zm_vending_chugabud / _on   the physical MACHINE - zm_highrise.ff
    //                                     only. There is no Who's Who machine
    //                                     anywhere else; the Wunderfizz hands
    //                                     the perk out, so nothing ever
    //                                     setmodel()s these and dropping them
    //                                     costs nothing.
    //      ch_tombstone1                  zm_transit.ff only. Stock precaches it
    //                                     HERE, in the chugabud block, but
    //                                     _zm_chugabud.gsc never references it
    //                                     even once - verified by grep over the
    //                                     whole 785-line module. It is a
    //                                     copy-paste from the tombstone block
    //                                     directly above. Carrying it would make
    //                                     five maps fail to load for an asset
    //                                     the perk does not use. It becomes real
    //                                     work in STAGE 3 (Tombstone).
    //
    //  What IS mandatory is the bottle WEAPON. _zm_perks::perk_give_bottle_begin
    //  does `weapon = level.machine_assets["whoswho"].weapon; self giveweapon(
    //  weapon )`, so without it the GIVE fails, not merely the animation. It now
    //  ships in mod.ff (zone_source\mod_locations.zone), which loads on every
    //  map, alongside its view/world models and the HUD icon material.
    //
    //  off_model/on_model are left UNDEFINED off Die Rise on purpose. Their only
    //  readers are the perk-machine loops, which iterate
    //  getentarray("vending_chugabud", ...) - empty here - so an undefined value
    //  is never dereferenced, whereas a name pointing at an unprecached model is
    //  a live trap for whoever adds a machine later.
    //  ------------------------------------------------------------------
    if ( isdefined( level.zombiemode_using_chugabud_perk ) && level.zombiemode_using_chugabud_perk )
    {
        precacheitem( "zombie_perk_bottle_whoswho" );
        precacheshader( "specialty_quickrevive_zombies" );
        precachestring( &"ZOMBIE_PERK_TOMBSTONE" );
        level._effect["tombstone_light"] = loadfx( "misc/fx_zombie_cola_on" );
        level.machine_assets["whoswho"] = spawnstruct();
        level.machine_assets["whoswho"].weapon = "zombie_perk_bottle_whoswho";

        //  Die Rise owns a real Who's Who machine, so it keeps stock's models.
        if ( level.script == "zm_highrise" )
        {
            precachemodel( "p6_zm_vending_chugabud" );
            precachemodel( "p6_zm_vending_chugabud_on" );
            precachemodel( "ch_tombstone1" );
            level.machine_assets["whoswho"].off_model = "p6_zm_vending_chugabud";
            level.machine_assets["whoswho"].on_model = "p6_zm_vending_chugabud_on";
        }
    }

    if ( level._custom_perks.size > 0 )
    {
        a_keys = getarraykeys( level._custom_perks );
        for ( i = 0; i < a_keys.size; i++ )
        {
            if ( isdefined( level._custom_perks[a_keys[i]].precache_func ) )
                level [[ level._custom_perks[a_keys[i]].precache_func ]]();
        }
    }
}

vending_deadshot_power_on()
{
	if (level.script == "zm_prison")
	{
		self setclientfield("toggle_perk_machine_power", 2);
	}
	else
	{
		level thread clientnotifyloop("toggle_vending_deadshot_power_on", "deadshot_off");
	}
}

vending_deadshot_power_off()
{
	if (level.script == "zm_prison")
	{
		self setclientfield("toggle_perk_machine_power", 1);
	}
	else
	{
		level thread clientnotifyloop("toggle_vending_deadshot_power_off", "deadshot_on");
	}
}

clientnotifyloop(notify_str, endon_str)
{
	if (isdefined(endon_str))
	{
		level endon(endon_str);
	}
	while (1)
	{
		clientnotify(notify_str);
		level waittill("connected", player);
		wait 0.05;
	}
}

// Display name of each perk.
// 2026-09-26 user audit: titles must read like the perk's real name, so this
// table now matches wunderfizz.gsc::getPerkName() exactly - "Double Tap" not
// "Double Tap 2.0", "Juggernog" not "Jugger-Nog", "Vulture Aid" not
// "Vulture Aid Elixir". Change both tables together or the menu and the
// pop-up will disagree.
getPerkName( perk )
{
    switch ( perk )
    {
        case "specialty_armorvest":
            return "Juggernog";
        case "specialty_fastreload":
            return "Speed Cola";
        case "specialty_quickrevive":
            return "Quick Revive";
        case "specialty_rof":
            return "Double Tap";
        case "specialty_longersprint":
            return "Stamin-Up";
        case "specialty_additionalprimaryweapon":
            return "Mule Kick";
        case "specialty_deadshot":
            return "Deadshot Daiquiri";
        case "specialty_flakjacket":
            return "PhD Flopper";
        case "specialty_scavenger":
            return "Tombstone";
        case "specialty_finalstand":
            return "Who's Who";
        case "specialty_nomotionsensor":
            return "Vulture Aid";
        case "specialty_grenadepulldeath":
            return "Electric Cherry";
        default:
            return "";
    }
}

// ============================================================================
//  zm_wallbuy_fills_clip  -  wall buys refill the MAGAZINE too
// ============================================================================
new_ammo_give( weapon )
{
	give_ammo = 0;
	fill_clip = 0;
	if ( !is_offhand_weapon( weapon ) )
	{
		weapon = get_weapon_with_attachments( weapon );
		if ( isdefined( weapon ) )
		{
			stockmax = weaponstartammo( weapon );
			clipmax = weaponclipsize( weapon );
			clipcount = self getweaponammoclip( weapon );
			currstock = self getammocount( weapon );
			stockleft = currstock - clipcount;
			if ( stockleft < stockmax )
				give_ammo = 1;
			// fill the mag whenever it isn't already full
			if ( clipcount < clipmax )
				fill_clip = 1;
		}
	}
	else if ( self has_weapon_or_upgrade( weapon ) )
	{
		if ( self getammocount( weapon ) < weaponmaxammo( weapon ) )
			give_ammo = 1;
	}
	if ( give_ammo || fill_clip )
	{
		self play_sound_on_ent( "purchase" );
		if ( give_ammo )
		{
			self givemaxammo( weapon );
			alt_weap = weaponaltweaponname( weapon );
			if ( alt_weap != "none" )
				self givemaxammo( alt_weap );
		}
		if ( fill_clip )
			self setweaponammoclip( weapon, clipmax );
		return 1;
	}
	return 0;
}

// ============================================================================
//  areanotifier  (was areanotifier.gsc)
// ============================================================================
an_onplayerconnect()
{
    for (;;)
    {
        level waittill( "connected", player );
        player thread an_onplayerspawned();
    }
}

an_onplayerspawned()
{
    self endon( "disconnect" );
    level endon( "game_ended" );
    for (;;)
    {
        self waittill( "spawned_player" );
        self thread zonecheck();
    }
}

//  🛑 v1.77.0 - ONE LOOP PER PLAYER, AND IT ENDS.
//
//  This was threaded from an_onplayerspawned()'s `waittill( "spawned_player" )`
//  loop with no guard and no endon, so EVERY respawn started ANOTHER copy and
//  none of them ever stopped - not on death, not on disconnect, not at end of
//  game. N spawns meant N loops all watching the same self.currentzone and all
//  able to fire a notifier in the same frame.
//
//  That is not the duplicate the user reported (see show_grief_hud_msg below for
//  that one, which is certain from the code) but it is a second, independent way
//  to get two notifiers at once, and it is a thread leak either way.
zonecheck()
{
    self endon( "disconnect" );
    level endon( "end_game" );

    if ( isdefined( self.qol_zonecheck_running ) && self.qol_zonecheck_running )
        return;

    self.qol_zonecheck_running = 1;

    while ( true )
    {
        // ====================================================================
        //  🛑 v2.9.13 - THE ZONE POP-UP NOW OBEYS THE "ZONE NAME" ROW.
        //
        //  User's friend, 2026-08-31, on TranZit: with zone names set to
        //  DISABLED the centre-screen pop-up still announced every zone he
        //  walked into.
        //
        //  Cause: there are TWO zone displays and only one was ever gated.
        //  qol_options.gsc's qol_opt_zone_hud() correctly honours hud_zone for
        //  the small permanent readout in the bottom-left - but this loop, the
        //  pop-up, read no dvar at all and had announced unconditionally since
        //  the areanotifier module was merged in. The HUD row promises "ZONE
        //  NAME - Name of the area you are in", which is exactly what the
        //  pop-up shows, so one switch has to govern both.
        //
        //  Read INSIDE the loop, not once at thread start, so the row is live
        //  the same way BLEEDOUT BAR is (v1.99.6 fixed that exact complaint).
        //  Turning it off also retires whatever is on screen right now rather
        //  than leaving the last pop-up hanging for its remaining 3.25s.
        //
        //  📝 BEHAVIOUR CHANGE, STATED PLAINLY: hud_zone defaults to 0, so out
        //  of the box the pop-up is now OFF where it used to always appear.
        //  That is the point of the report - "disabled" has to mean disabled -
        //  and turning ZONE NAME on restores it along with the corner readout.
        //  currentzone is still tracked while off, so re-enabling mid-game does
        //  not re-announce the zone you are already standing in.
        // ====================================================================
        if ( !self scripts\zm\zmqol_playeropt::zmqol_popt( "hud_zone", 0 ) )
        {
            self.currentzone = self get_zone_name();
            wait 0.2;
            continue;
        }

        str_zone = self get_zone_name();

        if ( self.currentzone != str_zone )
        {
            //  Zones with no friendly name still read as e.g. "zone_diner_roof";
            //  those are skipped, and deliberately do NOT update currentzone, so
            //  crossing an unnamed zone and coming back does not re-announce.
            //  🛑 v2.14.18 - THE CENTRE-SCREEN POP-UP IS GONE. User,
            //  2026-09-08, with a screenshot: *"it shows the area on the bottom
            //  left like i requested, however for some reason the notifier
            //  still shows up when i walk into new areas, remove that one at
            //  the top middle of the screen so just the one on the bottom left
            //  under the players name is there."*
            //
            //  Only the CALL goes. This loop still tracks currentzone exactly
            //  as before, because that field is what the permanent bottom-left
            //  readout reads - qol_options.gsc::qol_opt_zone_hud() takes its
            //  text straight off it rather than walking the zones itself.
            //  Deleting the tracking would blank the row the user wants to keep.
            //
            //  🌟 NOTHING ELSE USED THAT SLOT - grepped, not assumed. The only
            //  caller of grief_reset_message() was this line, and its only
            //  caller of show_grief_hud_msg() is itself, so the whole chain
            //  (grief_reset_message, show_grief_hud_msg,
            //  show_grief_hud_msg_cleanup, qol_zone_notifier_clear) is now
            //  unreferenced. It is LEFT IN PLACE, not deleted: it costs nothing
            //  unreferenced, and restoring the pop-up is then one line here
            //  rather than a rewrite.
            if ( !issubstr( str_zone, "_" ) )
                self.currentzone = str_zone;
        }

        wait 0.2;
    }
}

get_zone_name()
{
    zone = self get_player_zone();
    if ( !isdefined( zone ) )
        return "";
    name = zone;
    if ( level.script == "zm_transit" )
    {
        if ( zone == "zone_pri" )
            name = "Bus Depot";
        else if ( zone == "zone_pri2" )
            name = "Bus Depot";
        else if ( zone == "zone_station_ext" )
            name = "Bus Depot";
        else if ( zone == "zone_trans_2b" )
            name = "Bus Depot";
        else if ( zone == "zone_trans_2" )
            name = "Tunnel";
        else if ( zone == "zone_amb_tunnel" )
            name = "Tunnel";
        else if ( zone == "zone_trans_3" )
            name = "Tunnel";
        else if ( zone == "zone_roadside_west" )
            name = "Diner";
        else if ( zone == "zone_gas" )
            name = "Diner";
        else if ( zone == "zone_roadside_east" )
            name = "Diner";
        else if ( zone == "zone_trans_diner" )
            name = "Diner";
        else if ( zone == "zone_trans_diner2" )
            name = "Diner";
        else if ( zone == "zone_gar" )
            name = "Diner";
        else if ( zone == "zone_din" )
            name = "Diner";
        else if ( zone == "zone_diner_roof" )
            name = "Diner";
        else if ( zone == "zone_trans_4" )
            name = "Diner";
        else if ( zone == "zone_amb_forest" )
            name = "Forest";
        else if ( zone == "zone_trans_10" )
            name = "Church";
        else if ( zone == "zone_town_church" )
            name = "Church";
        else if ( zone == "zone_trans_5" )
            name = "Farm";
        else if ( zone == "zone_far" )
            name = "Farm";
        else if ( zone == "zone_far_ext" )
            name = "Farm";
        else if ( zone == "zone_brn" )
            name = "Farm";
        else if ( zone == "zone_farm_house" )
            name = "Farm";
        else if ( zone == "zone_trans_6" )
            name = "Farm";
        else if ( zone == "zone_amb_cornfield" )
            name = "Cornfield";
        else if ( zone == "zone_cornfield_prototype" )
            name = "Nacht";
        else if ( zone == "zone_trans_pow_ext1" )
            name = "Power Station";
        else if ( zone == "zone_pow" )
            name = "Power Station";
        else if ( zone == "zone_prr" )
            name = "Power Station";
        else if ( zone == "zone_pcr" )
            name = "Power Station";
        else if ( zone == "zone_pow_warehouse" )
            name = "Power Station";
        else if ( zone == "zone_trans_8" )
            name = "Power Station";
        else if ( zone == "zone_amb_power2town" )
            name = "Cabin";
        else if ( zone == "zone_trans_9" )
            name = "Town";
        else if ( zone == "zone_town_north" )
            name = "Town";
        else if ( zone == "zone_tow" )
            name = "Town";
        else if ( zone == "zone_town_east" )
            name = "Town";
        else if ( zone == "zone_town_west" )
            name = "Town";
        else if ( zone == "zone_town_south" )
            name = "Town";
        else if ( zone == "zone_bar" )
            name = "Town";
        else if ( zone == "zone_town_barber" )
            name = "Town";
        else if ( zone == "zone_ban" )
            name = "Town";
        else if ( zone == "zone_ban_vault" )
            name = "Town";
        else if ( zone == "zone_tbu" )
            name = "Town";
        else if ( zone == "zone_trans_11" )
            name = "Town";
        else if ( zone == "zone_trans_1" )
            name = "Bus Depot";
    }
    else if ( level.script == "zm_nuked" )
    {
        if ( zone == "culdesac_yellow_zone" )
            name = "Yellow House";
        else if ( zone == "culdesac_green_zone" )
            name = "Green House";
        else if ( zone == "openhouse1_f1_zone" )
            name = "Green House";
        else if ( zone == "openhouse1_f2_zone" )
            name = "Green House";
        else if ( zone == "openhouse1_backyard_zone" )
            name = "Green House";
        else if ( zone == "openhouse2_f1_zone" )
            name = "Yellow House";
        else if ( zone == "openhouse2_f2_zone" )
            name = "Yellow House";
        else if ( zone == "openhouse2_backyard_zone" )
            name = "Yellow House";
        else if ( zone == "ammo_door_zone" )
            name = "Yellow House";
    }
    else if ( level.script == "zm_highrise" )
    {
        if ( zone == "zone_green_start" )
            name = "Green Highrise";
        else if ( zone == "zone_green_level1" )
            name = "Green Highrise";
        else if ( zone == "zone_green_level2a" )
            name = "Green Highrise";
        else if ( zone == "zone_green_level2b" )
            name = "Green Highrise";
        else if ( zone == "zone_green_level3a" )
            name = "Green Highrise";
        else if ( zone == "zone_green_level3b" )
            name = "Green Highrise";
        else if ( zone == "zone_green_level3c" )
            name = "Green Highrise";
        else if ( zone == "zone_green_level3d" )
            name = "Green Highrise";
        else if ( zone == "zone_orange_level1" )
            name = "Orange Highrise";
        else if ( zone == "zone_orange_level2" )
            name = "Orange Highrise";
        else if ( zone == "zone_orange_level3a" )
            name = "Orange Highrise";
        else if ( zone == "zone_orange_level3b" )
            name = "Orange Highrise";
        else if ( zone == "zone_blue_level5" )
            name = "Blue Highrise";
        else if ( zone == "zone_blue_level4a" )
            name = "Blue Highrise";
        else if ( zone == "zone_blue_level4b" )
            name = "Blue Highrise";
        else if ( zone == "zone_blue_level4c" )
            name = "Blue Highrise";
        else if ( zone == "zone_blue_level2a" )
            name = "Blue Highrise";
        else if ( zone == "zone_blue_level2b" )
            name = "Blue Highrise";
        else if ( zone == "zone_blue_level2c" )
            name = "Blue Highrise";
        else if ( zone == "zone_blue_level2d" )
            name = "Blue Highrise";
        else if ( zone == "zone_blue_level1a" )
            name = "Blue Highrise";
        else if ( zone == "zone_blue_level1b" )
            name = "Blue Highrise";
        else if ( zone == "zone_blue_level1c" )
            name = "Blue Highrise";
    }
    else if ( level.script == "zm_prison" )
    {
        if ( zone == "zone_library" )
            name = "Library";
        //  v2.17.47 - the classic spawn. It was missing, so the zone row under
        //  the name sat blank from spawn until you walked into a named room.
        else if ( zone == "zone_start" )
            name = "Cellblock";
        else if ( zone == "zone_cellblock_west" )
            name = "Cellblock";
        else if ( zone == "zone_cellblock_west_gondola" )
            name = "Cellblock";
        else if ( zone == "zone_cellblock_west_gondola_dock" )
            name = "Cellblock";
        else if ( zone == "zone_cellblock_west_barber" )
            name = "Cellblock";
        else if ( zone == "zone_cellblock_east" )
            name = "Cellblock";
        else if ( zone == "zone_cafeteria" )
            name = "Cafeteria";
        else if ( zone == "zone_cafeteria_end" )
            name = "Cafeteria";
        else if ( zone == "zone_infirmary" )
            name = "Infirmary";
        else if ( zone == "zone_infirmary_roof" )
            name = "Infirmary";
        else if ( zone == "zone_roof_infirmary" )
            name = "Roof";
        else if ( zone == "zone_roof" )
            name = "Roof";
        else if ( zone == "zone_cellblock_west_warden" )
            name = "Cellblock";
        else if ( zone == "zone_warden_office" )
            name = "Warden's Office";
        else if ( zone == "cellblock_shower" )
            name = "Cellblock";
        else if ( zone == "zone_citadel_shower" )
            name = "Cellblock";
        else if ( zone == "zone_citadel" )
            name = "Citadel";
        else if ( zone == "zone_citadel_warden" )
            name = "Citadel";
        else if ( zone == "zone_citadel_stairs" )
            name = "Citadel";
        else if ( zone == "zone_citadel_basement" )
            name = "Citadel";
        else if ( zone == "zone_dock" )
            name = "Docks";
        else if ( zone == "zone_dock_puzzle" )
            name = "Docks";
        else if ( zone == "zone_dock_gondola" )
            name = "Docks";
        else if ( zone == "zone_golden_gate_bridge" )
            name = "Golden Gate Bridge";
    }
    else if ( level.script == "zm_buried" )
    {
        if ( zone == "zone_start" )
            name = "Processing";
        else if ( zone == "zone_start_lower" )
            name = "Processing";
        else if ( zone == "zone_tunnels_center" )
            name = "Tunnels";
        else if ( zone == "zone_tunnels_north" )
            name = "Tunnels";
        else if ( zone == "zone_tunnels_north2" )
            name = "Tunnels";
        else if ( zone == "zone_tunnels_south" )
            name = "Tunnels";
        else if ( zone == "zone_tunnels_south2" )
            name = "Tunnels";
        else if ( zone == "zone_tunnels_south3" )
            name = "Tunnels";
        else if ( zone == "zone_street_lightwest" )
            name = "Underground";
        else if ( zone == "zone_street_lightwest_alley" )
            name = "Underground";
        else if ( zone == "zone_morgue_upstairs" )
            name = "Underground";
        else if ( zone == "zone_stables" )
            name = "Underground";
        else if ( zone == "zone_street_darkwest" )
            name = "Underground";
        else if ( zone == "zone_street_darkwest_nook" )
            name = "Underground";
        else if ( zone == "zone_gun_store" )
            name = "Underground";
        else if ( zone == "zone_bank" )
            name = "Underground";
        else if ( zone == "zone_tunnel_gun2stables" )
            name = "Underground";
        else if ( zone == "zone_tunnel_gun2stables2" )
            name = "Underground";
        else if ( zone == "zone_street_darkeast" )
            name = "Underground";
        else if ( zone == "zone_street_darkeast_nook" )
            name = "Underground";
        else if ( zone == "zone_underground_bar" )
            name = "Underground";
        else if ( zone == "zone_tunnel_gun2saloon" )
            name = "Underground";
        else if ( zone == "zone_toy_store" )
            name = "Underground";
        else if ( zone == "zone_toy_store_floor2" )
            name = "Underground";
        else if ( zone == "zone_toy_store_tunnel" )
            name = "Underground";
        else if ( zone == "zone_candy_store" )
            name = "Underground";
        else if ( zone == "zone_candy_store_floor2" )
            name = "Underground";
        else if ( zone == "zone_street_lighteast" )
            name = "Underground";
        else if ( zone == "zone_underground_courthouse" )
            name = "Underground";
        else if ( zone == "zone_underground_courthouse2" )
            name = "Underground";
        else if ( zone == "zone_street_fountain" )
            name = "Underground";
        else if ( zone == "zone_church_graveyard" )
            name = "Underground";
        else if ( zone == "zone_church_main" )
            name = "Underground";
        else if ( zone == "zone_church_upstairs" )
            name = "Underground";
        else if ( zone == "zone_mansion_lawn" )
            name = "Mansion";
        else if ( zone == "zone_mansion" )
            name = "Mansion";
        else if ( zone == "zone_mansion_backyard" )
            name = "Mansion";
        else if ( zone == "zone_maze" )
            name = "Mansion";
        else if ( zone == "zone_maze_staircase" )
            name = "Mansion";
    }
    else if ( level.script == "zm_tomb" )
    {
        if ( self.teleporting && isdefined( self.teleporting ) )
            return "";
        if ( zone == "zone_start" )
            name = "Laboratory";
        else if ( zone == "zone_start_a" )
            name = "Laboratory";
        else if ( zone == "zone_start_b" )
            name = "Laboratory";
        else if ( zone == "zone_bunker_1a" )
            name = "Bunker";
        else if ( zone == "zone_fire_stairs" )
            name = "Fire Tunnel";
        else if ( zone == "zone_bunker_1" )
            name = "Bunker";
        else if ( zone == "zone_bunker_3a" )
            name = "Bunker";
        else if ( zone == "zone_bunker_3b" )
            name = "Bunker";
        else if ( zone == "zone_bunker_2a" )
            name = "Bunker";
        else if ( zone == "zone_bunker_2" )
            name = "Bunker";
        else if ( zone == "zone_bunker_4a" )
            name = "Bunker";
        else if ( zone == "zone_bunker_4b" )
            name = "Bunker";
        else if ( zone == "zone_bunker_4c" )
            name = "Bunker";
        else if ( zone == "zone_bunker_4d" )
            name = "Bunker";
        else if ( zone == "zone_bunker_tank_c" )
            name = "Bunker";
        else if ( zone == "zone_bunker_tank_c1" )
            name = "Bunker";
        else if ( zone == "zone_bunker_4e" )
            name = "Bunker";
        else if ( zone == "zone_bunker_tank_d" )
            name = "Bunker";
        else if ( zone == "zone_bunker_tank_d1" )
            name = "Bunker";
        else if ( zone == "zone_bunker_4f" )
            name = "Bunker";
        else if ( zone == "zone_bunker_5a" )
            name = "Bunker";
        else if ( zone == "zone_bunker_5b" )
            name = "Bunker";
        else if ( zone == "zone_nml_2a" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_2" )
            name = "No Man's Land";
        else if ( zone == "zone_bunker_tank_e" )
            name = "Bunker";
        else if ( zone == "zone_bunker_tank_e1" )
            name = "Bunker";
        else if ( zone == "zone_bunker_tank_e2" )
            name = "Bunker";
        else if ( zone == "zone_bunker_tank_f" )
            name = "Bunker";
        else if ( zone == "zone_nml_1" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_4" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_0" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_5" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_farm" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_celllar" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_3" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_2b" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_6" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_8" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_10a" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_10" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_7" )
            name = "No Man's Land";
        else if ( zone == "zone_bunker_tank_a" )
            name = "No Man's Land";
        else if ( zone == "zone_bunker_tank_a1" )
            name = "Bunker";
        else if ( zone == "zone_bunker_tank_a2" )
            name = "Bunker";
        else if ( zone == "zone_bunker_tank_b" )
            name = "Bunker";
        else if ( zone == "zone_nml_9" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_11" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_12" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_16" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_17" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_18" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_19" )
            name = "No Man's Land";
        else if ( zone == "ug_bottom_zone" )
            name = "Excavation Site";
        else if ( zone == "zone_nml_13" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_14" )
            name = "No Man's Land";
        else if ( zone == "zone_nml_15" )
            name = "No Man's Land";
        else if ( zone == "zone_village_0" )
            name = "Village";
        else if ( zone == "zone_village_5" )
            name = "Village";
        else if ( zone == "zone_village_5a" )
            name = "Village";
        else if ( zone == "zone_village_5b" )
            name = "Village";
        else if ( zone == "zone_village_1" )
            name = "Village";
        else if ( zone == "zone_village_4b" )
            name = "Village";
        else if ( zone == "zone_village_4a" )
            name = "Village";
        else if ( zone == "zone_village_4" )
            name = "Village";
        else if ( zone == "zone_village_2" )
            name = "Village";
        else if ( zone == "zone_village_3" )
            name = "Village";
        else if ( zone == "zone_village_3a" )
            name = "Village";
        else if ( zone == "zone_bunker_6" )
            name = "Bunker";
        else if ( zone == "zone_nml_20" )
            name = "No Man's Land";
        else if ( zone == "zone_village_6" )
            name = "Village";
        else if ( zone == "zone_chamber_0" )
            name = "The Crazy Place";
        else if ( zone == "zone_chamber_1" )
            name = "The Crazy Place";
        else if ( zone == "zone_chamber_2" )
            name = "The Crazy Place";
        else if ( zone == "zone_chamber_3" )
            name = "The Crazy Place";
        else if ( zone == "zone_chamber_4" )
            name = "The Crazy Place";
        else if ( zone == "zone_chamber_5" )
            name = "The Crazy Place";
        else if ( zone == "zone_chamber_6" )
            name = "The Crazy Place";
        else if ( zone == "zone_chamber_7" )
            name = "The Crazy Place";
        else if ( zone == "zone_chamber_8" )
            name = "The Crazy Place";
        else if ( zone == "zone_robot_head" )
            name = "Robot's Head";
    }
    return name;
}

//  🛑 v1.77.0 - THIS IS PER-PLAYER NOW, AND IT USED NOT TO BE.
//
//  Despite the name, this whole chain is private to the zone notifier: the ONLY
//  caller of grief_reset_message() is zonecheck(), and the ONLY caller of
//  show_grief_hud_msg() is this function. Both verified by grep across the tree.
//  The names are inherited from the 17-module merge; they are kept so the diff
//  stays readable, but nothing about grief reaches here.
//
//  It walked get_players() and pushed the message to EVERYONE, so in co-op one
//  player crossing into "Bus Depot" announced "Bus Depot" on all four screens -
//  wrong for the other three, who are somewhere else. self.currentzone is
//  already per-player, so the announcement had no business being global.
//
//  📝 `player playsound( sound )` sat OUTSIDE the foreach, so it ran on whatever
//  `player` the loop happened to leave behind - and is called with "" from the
//  one caller, so it never played anything anyway. Now it is guarded and on self.
grief_reset_message( setmsg, sound )
{
    self endon( "disconnect" );

    if ( isdefined( level.hostmigrationtimer ) )
    {
        while ( isdefined( level.hostmigrationtimer ) )
            wait 0.05;

        wait 4;
    }

    self thread show_grief_hud_msg( setmsg );

    if ( isdefined( sound ) && sound != "" )
        self playsound( sound );
}

//  Retires the notifier currently on screen, if any. Called before a new one is
//  drawn, so there is never more than one alive per player.
//
//  Order matters: the notify has to reach the waiting threads BEFORE the element
//  goes away. "qol_replaced" ends show_grief_hud_msg's own timing thread (which
//  is mid-`wait` and would otherwise come back to fade a destroyed element) and
//  "death" ends show_grief_hud_msg_cleanup, which already endons exactly that.
qol_zone_notifier_clear()
{
    if ( !isdefined( self.qol_zone_notifier ) )
        return;

    e_old = self.qol_zone_notifier;
    self.qol_zone_notifier = undefined;

    if ( !isdefined( e_old ) )
        return;

    e_old notify( "qol_replaced" );
    e_old notify( "death" );
    e_old destroy();
}

//  🛑 v1.77.0 - THE OVERLAPPING ZONE NOTIFIERS. Root cause, certain from the code.
//
//  User, 2026-08-13: *"if i were to go back and fourth for example into 2
//  different zones in origins and keep spamming back and fourth... the text will
//  become stacked into eachother with 2 or more inside one another."*
//
//  Each call did an unconditional newclienthudelem() and then held that element
//  for 3.25s + 1s of fade = 4.25 SECONDS before destroying it. Nothing referenced
//  the element that was already on screen, so a zone change inside that 4.25s
//  window simply drew a second element at the identical centre position - same
//  x, same y, same font - and the two texts rendered through each other. Cross
//  four zone borders quickly and there are four.
//
//  🌟 FIXED BY RETIRING THE OLD ONE, NOT BY A COOLDOWN, and that choice is
//  deliberate. The user offered either. A cooldown is wrong here because the
//  message is a statement of where you ARE: suppressing the new one leaves the
//  PREVIOUS zone's name on screen while you stand somewhere else, which is a
//  worse bug than the overlap. Retiring the outgoing element means the newest
//  zone always wins and exactly one is ever alive.
//
//  📝 The 3.25s hold and 1s fades are untouched - a single, uncontested notifier
//  still reads exactly as it does today.
show_grief_hud_msg( msg, msg_parm, offset, cleanup_end_game )
{
    self endon( "disconnect" );
    while ( isdefined( level.hostmigrationtimer ) )
        wait 0.05;

    //  Take the outgoing one down BEFORE the new element exists, so the two are
    //  never on screen together even for a frame.
    self qol_zone_notifier_clear();

    notifier_hudmsg = newclienthudelem( self );
    notifier_hudmsg.alignx = "center";
    notifier_hudmsg.aligny = "middle";
    notifier_hudmsg.horzalign = "center";
    notifier_hudmsg.vertalign = "middle";
    notifier_hudmsg.y = notifier_hudmsg.y - 100;
    if ( self issplitscreen() )
        notifier_hudmsg.y = notifier_hudmsg.y + 70;
    if ( isdefined( offset ) )
        notifier_hudmsg.y = notifier_hudmsg.y + offset;
    notifier_hudmsg.foreground = 1;
    notifier_hudmsg.fontscale = 5;
    notifier_hudmsg.alpha = 0;
    notifier_hudmsg.color = ( 1, 1, 1 );
    notifier_hudmsg.hidewheninmenu = 1;
    notifier_hudmsg.font = "default";

    //  Publish it, then bind this thread's lifetime to it. qol_zone_notifier_clear()
    //  notifies "qol_replaced" before destroying, so if another zone change lands
    //  during either wait below, this thread ends here instead of waking up to
    //  fade and destroy an element that is already gone.
    //  🛑 A DISTINCT EVENT, not "death", on purpose: this function notifies
    //  "death" itself at the end, and endon-ing that would kill the thread on its
    //  own notify before the destroy could run.
    self.qol_zone_notifier = notifier_hudmsg;
    notifier_hudmsg endon( "qol_replaced" );

    if ( cleanup_end_game && isdefined( cleanup_end_game ) )
    {
        level endon( "end_game" );
        notifier_hudmsg thread show_grief_hud_msg_cleanup();
    }
    if ( isdefined( msg_parm ) )
        notifier_hudmsg settext( msg, msg_parm );
    else
        notifier_hudmsg settext( msg );
    notifier_hudmsg changefontscaleovertime( 0 );
    notifier_hudmsg fadeovertime( 1 );
    notifier_hudmsg.alpha = 1;
    notifier_hudmsg.fontscale = 2;
    wait 3.25;
    notifier_hudmsg changefontscaleovertime( 0 );
    notifier_hudmsg fadeovertime( 1 );
    notifier_hudmsg.alpha = 0;
    notifier_hudmsg.fontscale = 2;
    wait 1;

    //  Ran its full life uninterrupted, so release the handle - but only if it is
    //  still OURS. Belt and braces: the "qol_replaced" endon above should already
    //  have ended this thread if a newer notifier took over.
    if ( isdefined( self.qol_zone_notifier ) && self.qol_zone_notifier == notifier_hudmsg )
        self.qol_zone_notifier = undefined;

    notifier_hudmsg notify( "death" );
    if ( isdefined( notifier_hudmsg ) )
        notifier_hudmsg destroy();
}

show_grief_hud_msg_cleanup()
{
    self endon( "death" );
    level waittill( "end_game" );
    if ( isdefined( self ) )
        self destroy();
}

// ============================================================================
//  instant_start  -  skip the dead time between clicking Start and actually
//  being able to play.
// ----------------------------------------------------------------------------
//  Added 2026-07-31, user request. Rewritten same day after the first version
//  (a "race the flags early + watchdog the black screen" hack) was deployed
//  and tested in-game and had NO effect - stock's original onallplayersready()
//  thread was still running in the background driving the real timing, and
//  the hack never actually stopped it.
//
//  The rewrite replaceFunc's maps\mp\zombies\_zm::onallplayersready() directly
//  instead of racing it. Earlier reasoning (see AI_CONTEXT.md-style failure
//  mode: "unqualified same-file call defeats replaceFunc") assumed this
//  couldn't work, because _zm.gsc's own main() calls it unqualified
//  (`level thread onallplayersready();`). That assumption was wrong for this
//  specific call: BO2-Reimagined (BO2-Reimagined,
//  scripts/zm/_zm_reimagined.gsc:33) successfully does
//  `replaceFunc(maps\mp\zombies\_zm::onallplayersready, scripts\zm\replaced\_zm::onallplayersready);`
//  in a real, working mod - proving replaceFunc DOES redirect this particular
//  call site. Likely explanation: it's a `thread`-ed call, not a synchronous
//  one, and threaded calls resolve through the redirectable function table
//  even when unqualified, unlike plain synchronous same-file calls.
//
//  onallplayersready_instant() below is a copy of the stock body (verified
//  against both the vanilla dump and BO2-Reimagined's copy, which are
//  otherwise identical) with two numbers changed:
//    - the "wait up to 5000ms to learn how many players are expected" timeout
//      cut to 300ms (the value getnumexpectedplayers() waits on doesn't
//      reliably resolve on Plutonium; no reason to burn the full 5s on it)
//    - fade_out_intro_screen_zm's hold/fade shortened from (5.0, 1.5) to
//      (0.15, 0.3) - still a deliberate, brief fade rather than a jarring
//      instant cut, but no longer a multi-second hold
//  Everything else (connected-player sync, solo lives/pistol setup, bot
//  handling, texture-load wait) is kept faithful to stock for correctness.
//  Since this is a real replaceFunc, stock's original body never runs at all
//  - no background thread left to race or fight.
//
//  NOTE: in-game testing (2026-07-31) confirmed this runs correctly and
//  completes fast, but it turned out NOT to be what the user was actually
//  reporting. The multi-second wait they meant happens BEFORE this point
//  entirely - it's a "match starting in..." countdown in Plutonium's private
//  match lobby UI (the Start/Play button), which typing the console command
//  `xpartygo` manually bypasses. That countdown lives in Plutonium's compiled
//  base-game menu system (CoD.Lobby module) - no loose/raw Lua source for it
//  exists anywhere checked (zm_qol's own ui_mp/, the workspace's
//  raw/ui + raw/ui_mp dump, or BO2-Reimagined), so it isn't something this
//  mod can safely patch. Left in anyway since it's a real, if smaller,
//  improvement to the post-load dead time on every game.
// ============================================================================
onallplayersready_instant()
{
    // Wait briefly for the engine to report an expected player count.
    timeout = gettime() + 1500;

    while ( getnumexpectedplayers() == 0 && gettime() < timeout )
        wait 0.05;

    // 🛑 BOUNDED ON PURPOSE. Stock spins here until connected == expected. When
    // getnumexpectedplayers() never becomes non-zero - which is what happens on
    // solo and custom games launched from the Mods menu, since there is no real
    // party populating it - the condition player_count_actual != 0 stays true
    // forever and the player is left frozen on a black screen. The previous
    // version of this function inherited that unbounded loop and merely cut the
    // FIRST timeout to 300ms, which made reaching that state MORE likely on
    // slower-loading maps (Origins). The second loop now has its own deadline.
    ready_deadline = gettime() + 4000;
    player_count_actual = 0;

    while ( getnumconnectedplayers() < getnumexpectedplayers() || player_count_actual != getnumexpectedplayers() )
    {
        players = get_players();
        player_count_actual = 0;

        for ( i = 0; i < players.size; i++ )
        {
            players[i] freezecontrols( 1 );

            if ( players[i].sessionstate == "playing" )
                player_count_actual++;
        }

        //  ====================================================================
        //  🛑 v2.13.0 - THE ESCAPE HATCH USED TO FIRE WHILE SOMEONE WAS STILL
        //  LOADING, AND THAT BROKE EVERY CO-OP GAME IT TOUCHED.
        //
        //  The old test was ( player_count_actual > 0 && past the deadline ).
        //  In co-op the host reaches "playing" first and the deadline is four
        //  seconds, so a friend on a slower disk was simply left behind: the
        //  loop broke with one player counted, setinitialplayersconnected()
        //  recorded a roster of one, and the block below then found
        //  players.size == 1 and set the "solo_game" FLAG IN A CO-OP MATCH.
        //  Stock branches on that flag in 102 places - Quick Revive, last
        //  stand, tombstone, chugabud, power, powerups - and it only unsticks at
        //  the first round change, when _zm::check_quickrevive_for_hotjoin()
        //  re-derives it. Everything before that ran under solo rules, and the
        //  second player arrived as a hot-joiner into a round already running.
        //
        //  🌟 MEASURED, NOT ASSUMED: stock _zm::onallplayersready has NO
        //  deadline here at all - it spins until connected == expected - and
        //  BO2-Reimagined, which is co-op-tested, copies stock unchanged
        //  (scripts/zm/replaced/_zm.gsc). This deadline is this mod's own
        //  addition, and it is the only one of the three that can start a match
        //  short-handed.
        //
        //  THE FIX KEEPS THE HATCH BUT NARROWS IT TO THE CASE IT WAS BUILT FOR:
        //  the Mods-menu game where getnumexpectedplayers() never resolves, the
        //  loop can never be satisfied, and the player is stranded on a black
        //  screen. Two extra conditions confine it there:
        //
        //    getnumexpectedplayers() == 0
        //        the engine gave us no target at all. When it DOES give one,
        //        stock's unbounded wait is correct and is what now runs.
        //
        //    player_count_actual == getnumconnectedplayers()
        //        everyone who has reached the server is actually in-game. A
        //        client that is connected but still loading IS counted by
        //        getnumconnectedplayers() and is NOT counted by
        //        player_count_actual, so this stays false while anybody is
        //        still coming - which is precisely the case that used to be
        //        dropped on the floor.
        //
        //  Solo is unchanged: expected 0, connected 1, playing 1, so it still
        //  breaks out after the deadline instead of hanging on black.
        //  ====================================================================
        if ( player_count_actual > 0 && gettime() > ready_deadline
             && getnumexpectedplayers() == 0
             && player_count_actual == getnumconnectedplayers() )
        {
            println( "[zm_qol] onallplayersready: engine reported no expected count; starting with "
                     + player_count_actual + " of " + getnumconnectedplayers() + " connected player(s) in-game" );
            break;
        }

        wait 0.05;
    }

    setinitialplayersconnected();

    if ( 1 == getnumconnectedplayers() && getdvarint( #"scr_zm_enable_bots" ) == 1 )
    {
        level thread add_bots();
        flag_set( "initial_players_connected" );
    }
    else
    {
        players = get_players();

        if ( players.size == 1 && !is_encounter() )
        {
            flag_set( "solo_game" );
            level.solo_lives_given = 0;

            foreach ( player in players )
                player.lives = 0;

            level maps\mp\zombies\_zm::set_default_laststand_pistol( 1 );
        }

        flag_set( "initial_players_connected" );

        while ( !aretexturesloaded() )
            wait 0.05;

        thread start_zombie_logic_in_x_sec( 0.5 );
    }

    // Call our own copy directly rather than relying on the replaceFunc above to
    // redirect this call - same file, so this is unambiguous. The replaceFunc is
    // still registered for any other caller of the stock function.
    fade_out_intro_screen_zm_instant( 0.15, 0.3, 1 );
}

// ============================================================================
//  fade_out_intro_screen_zm_instant  (instant_start, part 2)
//
//  Faithful copy of stock maps\mp\zombies\_zm::fade_out_intro_screen_zm with ONE
//  change: the hardcoded `wait 1.6;` after the fade is cut to 0.05.
//
//  Why this is needed on top of onallplayersready_instant: that 1.6s is a literal
//  inside the function, not one of its arguments, so shortening the arguments
//  could never remove it. It sits directly in front of flag_set(
//  "initial_blackscreen_passed" ), which is the flag maps wait on before they
//  start their own setup - Origins (zm_tomb.gsc) does exactly that. So this delay
//  was being paid on every map, every game, regardless of the argument values.
//
//  Everything else - the introscreen hudelem setup, hud_visible, the
//  level.player_movement_suppressed / hostmigrationcontrolsfrozen unfreeze rules,
//  the destroy, and both flag/state assignments - is stock, unchanged. Getting the
//  unfreeze logic wrong here would leave players unable to move, so it is copied
//  verbatim rather than simplified.
// ============================================================================
fade_out_intro_screen_zm_instant( hold_black_time, fade_out_time, destroyed_afterwards )
{
    if ( !isdefined( level.introscreen ) )
    {
        level.introscreen = newhudelem();
        level.introscreen.x = 0;
        level.introscreen.y = 0;
        level.introscreen.horzalign = "fullscreen";
        level.introscreen.vertalign = "fullscreen";
        level.introscreen.foreground = 0;
        level.introscreen setshader( "black", 640, 480 );
        level.introscreen.immunetodemogamehudsettings = 1;
        level.introscreen.immunetodemofreecamera = 1;
        wait 0.05;
    }

    level.introscreen.alpha = 1;

    if ( isdefined( hold_black_time ) )
        wait( hold_black_time );
    else
        wait 0.2;

    if ( !isdefined( fade_out_time ) )
        fade_out_time = 1.5;

    level.introscreen fadeovertime( fade_out_time );
    level.introscreen.alpha = 0;

    // Stock waits a hardcoded 1.6s here; this mod cuts it. Origins used to pay
    // stock's full 1.6 as a test - that test failed, see zmqol_intro_hold_time().
    wait( zmqol_intro_hold_time() );

    level.passed_introscreen = 1;
    players = get_players();

    for ( i = 0; i < players.size; i++ )
    {
        players[i] setclientuivisibilityflag( "hud_visible", 1 );

        if ( !( isdefined( level.host_ended_game ) && level.host_ended_game ) )
        {
            if ( isdefined( level.player_movement_suppressed ) )
            {
                players[i] freezecontrols( level.player_movement_suppressed );
                continue;
            }

            if ( !( isdefined( players[i].hostmigrationcontrolsfrozen ) && players[i].hostmigrationcontrolsfrozen ) )
                players[i] freezecontrols( 0 );
        }
    }

    if ( destroyed_afterwards == 1 )
        level.introscreen destroy();

    flag_set( "initial_blackscreen_passed" );
    println( "[zm_qol] intro: held " + zmqol_intro_hold_time() + "s, passed_introscreen=1, hud_visible set on " + players.size + " player(s)" );
}

// ============================================================================
//  zmqol_intro_hold_time  -  how long to sit on black after the fade
//
//  Stock maps\mp\zombies\_zm::fade_out_intro_screen_zm waits a hardcoded 1.6s
//  here. This mod cuts it to 0.05 to kill dead time at the start of every game,
//  on every map including Origins.
//
//  WHAT IS KNOWN ABOUT THE ORIGINS CAPTURE RING, kept because it stays true:
//
//  KNOWN: the generator capture meter intermittently does not draw. It is NOT a
//  hudelem (checkpoint 17 said so and was wrong) and it is NOT a clientfield -
//  it is the OBJECTIVE/waypoint system, zm_tomb_capture_zones.gsc:1506:
//        objective_setprogress( self.n_objective_index, self.n_current_progress / 100 );
//  all of which is stock code this mod does not replace. The capture itself
//  still completes; only the display is missing. Confirmed by the user
//  2026-08-06: "nothing drew at all".
//
//  KNOWN (new, 2026-08-13): the widget is LUI, not engine code. It is
//  TCZWaypoint in ui_mp/t6/zombie/tombcapturezonedisplay.lua, inheriting
//  ObjectiveWaypoint, and it is selected by the objective's NAME string
//  (ZM_TOMB_OBJ_CAPTURE_1 / _2 / RECAPTURE_*). That whole file ships in
//  zm_tomb_patch.ff.
//
//  KNOWN: no commit has ever successfully targeted this. The one that tried
//  (0aa9f46, "free hudelems for the generator ring") aimed at the hudelem pool,
//  which checkpoint 18 established the ring does not use. So "it worked last
//  release and broke this release" is not a regression - it is the same
//  unfixed intermittent race landing differently on different boots.
//
//  🛑 FALSIFIED 2026-08-13 - THE HOLD IS NOT THE CAUSE, AND IS NOW REVERTED.
//
//  It shipped as a deliberately falsifiable test, and the evidence killed it.
//  console_zm.log holds BOTH of the user's Origins games back to back:
//        line 4694  [zm_qol] intro: held 1.6s ...   -> ring did NOT draw
//        line 8800  [zm_qol] intro: held 1.6s ...   -> ring DID draw
//  Identical hold, identical build, opposite outcomes. A constant cannot
//  explain a variable, so the startup-race theory is dead and the 1.55s of
//  extra black screen on Origins was buying nothing. Back to 0.05 everywhere.
//
//  What the same A/B DOES show, kept here so it is not lost: the one logged
//  difference between the two boots was
//        game A  solo status: expected=1 connected=0   -> no ring
//        game B  solo status: expected=1 connected=1   -> ring
//  i.e. the player was already connected at map-init time in the good boot and
//  not in the bad one. That is a lead about connect ORDER, not about this wait,
//  and it is not enough to act on. The repaired probe in zm_tomb\zm_tomb.gsc
//  (the old one could never print - see its header) is what settles it.
// ============================================================================
zmqol_intro_hold_time()
{
    return 0.05;
}

// ============================================================================
//  zmqol_spawn_baseline_probe   -   DIAGNOSTIC, remove once Buried spawns zombies
//
//  🛑 NO ZOMBIES ON ANY BURIED LOCATION. Confirmed in game 2026-08-02: Borough
//  and Maze both spawn none. This is NOT the Maze zone bug - the A/B run proved
//  that, because Borough never had the zone seal applied (it was gated to
//  location "maze") and fails identically:
//        SPAWNPROBE street t=20 spawners=0 multi=0 groups=0 pool=15 total=6 alive=0 limit=24 flag=1
//        SPAWNPROBE maze   t=20 spawners=0 multi=0 groups=0 pool=3  total=6 alive=0 limit=24 flag=1
//
//  Every gate in _zm.gsc::round_spawning() reads healthy - the spawn pool is
//  populated, "spawn_zombies" is set, zombie_ai_limit is 24, 6 zombies are queued
//  and none are alive. And there is NO script error anywhere in the log.
//
//  That silence is the clue. The spawn block is
//        if ( isdefined( level.zombie_spawners ) )          // _zm.gsc:3037
//        {
//            ...
//            spawner = random( level.zombie_spawners );     // _zm.gsc:3059
//            ai = spawn_zombie( spawner, spawner.targetname, spawn_point );
//        }
//  An EMPTY array is still isdefined, so it would enter, random() would yield
//  undefined, and spawner.targetname would throw a script error every attempt.
//  We see no errors - so the array is more likely UNDEFINED, which skips the whole
//  block silently and leaves ai undefined. That is a perfect match for the symptom.
//
//  🛑 The previous probe could not tell those two apart: it did
//  `if (isdefined(x)) n = x.size;` and printed 0 for both. Same measurement flaw as
//  the zbarrier and MAZEZONE probes - a bare count with no way to read it. So this
//  one reports def and size SEPARATELY.
//
//  Root script on purpose: it has to run on a map that WORKS, to establish what a
//  healthy level.zombie_spawners looks like. Nothing here is map-specific
//  (level vars and _zm_utility only), so it is legal per AI_CONTEXT rule 2.
//
//      [zm_qol] BASE <map>/<loc> t=N spawners def=<0/1> size=<n> multi=<0/1> groups=<n>
//      [zm_qol] BASE <map>/<loc> t=N pool=<n> total=<n> alive=<n> actors=<n> ailim=<n> actlim=<n> flag=<0/1>
// ============================================================================
zmqol_spawn_baseline_probe()
{
    level endon( "end_game" );

    str_where = level.script + "/" + getdvar( "ui_zm_mapstartlocation" );

    flag_wait( "start_zombie_round_logic" );

    for ( i = 0; i < 2; i++ )
    {
        wait 10;

        n_def = 0;
        n_size = 0;

        if ( isdefined( level.zombie_spawners ) )
        {
            n_def = 1;
            n_size = level.zombie_spawners.size;
        }

        n_groups = 0;

        if ( isdefined( level.zombie_spawn ) )
            n_groups = level.zombie_spawn.size;

        // 🛑 live is the whole point of this build. n_size is the array
        // _zm_spawner::init() CACHED at map init; a_live is the same query re-run
        // now. If a_live > 0 while n_size == 0, the entities exist and the cache
        // was simply built too early - which is repairable, and the repair below
        // does it. If a_live is also 0, the spawner entities genuinely are not in
        // the world on this gametype and no script fix can conjure them.
        a_live = getentarray( "zombie_spawner", "script_noteworthy" );

        println( "[zm_qol] BASE " + str_where + " t=" + ( ( i + 1 ) * 10 ) + " spawners def=" + n_def + " size=" + n_size + " live=" + a_live.size + " multi=" + is_true( level.use_multiple_spawns ) + " groups=" + n_groups );

        if ( n_size == 0 && a_live.size > 0 )
        {
            level.zombie_spawners = a_live;
            println( "[zm_qol] BASE " + str_where + " REPAIRED level.zombie_spawners -> " + level.zombie_spawners.size );
        }

        n_pool = 0;

        if ( isdefined( level.zombie_spawn_locations ) )
            n_pool = level.zombie_spawn_locations.size;

        n_total = 0;

        if ( isdefined( level.zombie_total ) )
            n_total = level.zombie_total;

        n_ailim = 0;

        if ( isdefined( level.zombie_ai_limit ) )
            n_ailim = level.zombie_ai_limit;

        n_actlim = 0;

        if ( isdefined( level.zombie_actor_limit ) )
            n_actlim = level.zombie_actor_limit;

        println( "[zm_qol] BASE " + str_where + " t=" + ( ( i + 1 ) * 10 ) + " pool=" + n_pool + " total=" + n_total + " alive=" + get_current_zombie_count() + " actors=" + get_current_actor_count() + " ailim=" + n_ailim + " actlim=" + n_actlim + " flag=" + flag( "spawn_zombies" ) );
    }
}

// ============================================================================
//  zmqol_minimal  -  THE ORIGINS BISECT SWITCH                     (v1.95.1)
//
//  `zmqol_minimal 1` at the console, before starting a map, stops EVERY
//  periodic thread this mod owns from running: the HUD watcher, the round
//  counter master, the LOD fix, night mode, the co-op pause watcher, the game
//  and round timers, the zombie counter, the round chalk, the velocity meter
//  and its poll, the Death Machine state monitor, the credits banner, the
//  console-command watcher and all five dvar watchers.
//
//  🛑 IT IS A DIAGNOSTIC, NOT A FEATURE. Default 0; nothing changes unless it
//  is typed. Everything one-shot - weapon registration, the Wunderfizz, the
//  wall-buy retag, perks, the wonder weapons - is deliberately still active.
//
//  WHY IT EXISTS. Origins dies with EXE_ERR_RELIABLE_CYCLED_OUT at ~20-35s and
//  three explanations have now been wrong: the night-mode ramp (v1.93.1), the
//  capture-objective re-declare and HUD nudge (v1.94.0, and the crash came back
//  with both provably off - neither line appears in the crash log), and this
//  session's zone-HUD settext (the crashing session's own dvar dump reads
//  hud_zone "0", so that loop was not even running).
//
//  🌟 The same dump settles a great deal more, and it is why a switch is worth
//  shipping rather than another guess: in the crashing session hud_master "0",
//  every hud_* sub-option "0", hitmarkers "0", round_summary "0", lod_fix "0".
//  Almost the entire HUD was already off and it crashed anyway. What was left
//  on was night_mode "1" and velocity "1".
//
//  So one boot with this set to 1 splits the remaining space in half:
//    - Origins survives  -> the emitter IS one of this mod's periodic threads,
//                           and the list above is now the whole suspect pool.
//    - Origins still dies -> every periodic thread is exonerated and the cause
//                           is in one-shot map setup, or is not this mod.
//  Either answer is worth more than another fix built on the likeliest story.
// ============================================================================
zmqol_minimal()
{
    return getdvarintdefault( "zmqol_minimal", 0 );
}

// ============================================================================
// ============================================================================
//  zmqol_whoswho_knife  -  Who's Who hands you a PACK-A-PUNCHED BALLISTIC KNIFE
//
//  User, 2026-08-17: "make it so when you get downed with Who's Who you have a
//  pack a punched ballistic knife instead of the stock m1911 like the perk
//  normally does, this way the perk isn't complete trash because the pap'd
//  ballistic knife in bo2 zombies acts as an instant revive if you shoot a
//  downed player with its projectile, again only pap'd... Make this a toggable
//  on/off option in the in-game/pause menu settings under the GAME tab."
//
//  🌟 THE REVIVE HALF NEEDS NO CODE - TREYARCH ALREADY WROTE IT, FOR THIS EXACT
//  ENTITY. maps\mp\zombies\_zm_clone::clone_damage_func(), which is the damage
//  callback spawn_player_clone() puts on every player clone (:60), reads:
//
//      if ( sweapon == "knife_ballistic_upgraded_zm" ||
//           sweapon == "knife_ballistic_bowie_upgraded_zm" ||
//           sweapon == "knife_ballistic_no_melee_upgraded_zm" ||
//           sweapon == "knife_ballistic_sickle_upgraded_zm" )
//          self notify( "player_revived", eattacker );
//
//  and _zm_chugabud::chugabud_spawn_corpse() (:196) builds the Who's Who corpse
//  with that very function. So shooting your own body with an upgraded ballistic
//  knife has ALWAYS been wired to revive you - the perk simply never gives you a
//  gun that can do it. This change hands over the missing weapon and nothing
//  else; the four weapon names above are the whole contract and they are read
//  out of stock, not typed from memory.
//
//  🛑 WHAT IT REPLACES, exactly. _zm_chugabud::chugabud_fake_revive() opens with
//  `self notify( "fake_revive" )` (:392) and later calls
//  `self give_start_weapon( 1 )` (:427), which is
//      giveweapon( level.start_weapon ); givestartammo( ... ); switchtoweapon( ... )
//  (_zm_utility.gsc). level.start_weapon is m1911_zm on the classic maps and
//  c96_zm on Origins - which is why this takes level.start_weapon rather than
//  naming a gun.
//
//  🛑 IT POLLS FOR THE PISTOL INSTEAD OF WAITING A FIXED FRAME. The notify is at
//  the top of that function and the giveweapon is 35 lines below it, with a
//  spawn-point search in between; betting on "one frame later" is betting on
//  that search never yielding. Waiting for the weapon to actually be in the
//  player's hands cannot lose that race, and if the pistol never arrives nothing
//  is taken away and the perk behaves exactly as stock.
//
//  🛑 ORIGINS CANNOT HAVE THIS AND IT IS NOT A SCRIPTING PROBLEM. `Unlinker
//  --list` over the retail zone\all\zm_tomb.ff and zm_prison.ff finds NO
//  knife_ballistic asset of any kind - no weapon, no fx, no reticle - while
//  zm_transit.ff carries all six variants. Stock zm_tomb.gsc and zm_prison.gsc
//  likewise contain zero include_weapon( "knife_ballistic..." ) lines. The gun
//  does not exist on those two maps, so it cannot be given there; the guard
//  below is the real precondition (include_weapon() is what calls precacheitem,
//  _zm_weapons.gsc:700-701) rather than a hard-coded map list that could go
//  stale. Mob of the Dead does not have Who's Who at all, so the gap is Origins
//  only - stated plainly rather than shipped quietly.
//
//  Where the perk and the gun both exist: zm_transit, zm_nuked, zm_highrise.
// ============================================================================
zmqol_whoswho_knife_onplayerconnect()
{
    for (;;)
    {
        level waittill( "connected", player );
        player thread zmqol_whoswho_knife_watch();
    }
}

zmqol_whoswho_knife_watch()
{
    self endon( "disconnect" );
    level endon( "end_game" );

    for (;;)
    {
        self waittill( "fake_revive" );

        if ( !getdvarintdefault( "whoswho_knife", 1 ) )
            continue;

        str_knife = self zmqol_whoswho_knife_name();

        if ( !isdefined( str_knife ) )
            continue;

        if ( !isdefined( level.start_weapon ) )
            continue;

        //  Wait for stock to actually hand over the starting pistol. 40 passes
        //  = 2s, far longer than the frame it really takes; giving up leaves
        //  the perk stock rather than half-changed.
        n_wait = 0;

        while ( n_wait < 40 && !self hasweapon( level.start_weapon ) )
        {
            n_wait++;
            wait 0.05;
        }

        if ( !self hasweapon( level.start_weapon ) )
        {
            println( "[zm_qol] whoswho knife: the start weapon never arrived, left stock" );
            continue;
        }

        self takeweapon( level.start_weapon );
        self giveweapon( str_knife );
        self givemaxammo( str_knife );
        self switchtoweapon( str_knife );

        println( "[zm_qol] whoswho knife: gave " + str_knife + " in place of " + level.start_weapon );

        //  v1.99.43 - the option now takes effect WHILE you are still down.
        self thread zmqol_whoswho_knife_toggle_watch( str_knife );
    }
}

// ============================================================================
//  zmqol_whoswho_knife_toggle_watch  -  v1.99.43. THE OPTION IS LIVE MID-DOWN.
//
//  User, 2026-08-18: "while still down in the who's who perk state, i quickly
//  paused and went to game settings, then disabled the who's who knife option
//  and it didn't toggle it i still have the ballistic knife".
//
//  🛑 IT WAS NOT A BROKEN DVAR - IT WAS READ ONCE AND NEVER AGAIN. The old code
//  tested `whoswho_knife` a single time, at the instant of the "fake_revive"
//  notify, and the swap had already happened by the time the pause menu opened.
//  The dvar itself was fine; the screenshot shows DISABLED and the log for that
//  same session shows the value it was given the knife under. Nothing was
//  reverted because nothing was watching.
//
//  📝 WHY IT ENDS ON e_chugabud_corpse. _zm_chugabud.gsc:68 sets
//  self.e_chugabud_corpse **before** :75 calls chugabud_fake_revive(), which is
//  what emits the notify this thread hangs off - so the handle is already there
//  when we start, no polling race. :183 clears it in chugabud_corpse_cleanup(),
//  which is the one point every exit from the Who's Who state passes through
//  (revived, bled out, or timed out). That makes it the state's real lifetime
//  rather than a guess at one.
//
//  📝 Giving the pistol back goes through stock's own
//  _zm_utility::give_start_weapon( 1 ) - giveweapon + givestartammo +
//  switchtoweapon - so "off" lands on exactly what the perk hands you normally,
//  with stock's ammo, not a reconstruction of it.
// ============================================================================
zmqol_whoswho_knife_toggle_watch( str_knife )
{
    self endon( "disconnect" );
    level endon( "end_game" );

    //  A second down retires the previous watcher. Safe to arm here because this
    //  thread is started FROM the "fake_revive" handler - the notify that would
    //  end it has already passed by the time we are listening.
    self endon( "fake_revive" );

    b_have_knife = 1;

    while ( isdefined( self.e_chugabud_corpse ) )
    {
        b_want_knife = getdvarintdefault( "whoswho_knife", 1 ) != 0;

        if ( b_want_knife != b_have_knife )
        {
            if ( b_want_knife )
            {
                if ( self hasweapon( level.start_weapon ) )
                    self takeweapon( level.start_weapon );

                self giveweapon( str_knife );
                self givemaxammo( str_knife );
                self switchtoweapon( str_knife );
                println( "[zm_qol] whoswho knife: toggled ON mid-down -> " + str_knife );
            }
            else
            {
                if ( self hasweapon( str_knife ) )
                    self takeweapon( str_knife );

                self maps\mp\zombies\_zm_utility::give_start_weapon( 1 );
                println( "[zm_qol] whoswho knife: toggled OFF mid-down -> " + level.start_weapon );
            }

            b_have_knife = b_want_knife;
        }

        wait 0.1;
    }
}

// ============================================================================
//  zmqol_whoswho_knife_name  -  which of the four upgraded variants to give
//
//  🌟 THE VARIANT IS NOT A CHOICE, IT DEPENDS ON THE PLAYER'S MELEE WEAPON, and
//  stock already owns that decision: maps\mp\zombies\_zm_melee_weapon::
//  give_ballistic_knife( name, upgraded ) maps the player's current melee weapon
//  through level.ballistic_upgraded_weapon_name[] and returns the right name.
//  Stock calls it in exactly this shape from _zm_powerups.gsc:2054-2056 and
//  _zm_weapons.gsc:2441. Handing over the plain knife_ballistic_upgraded_zm
//  while the player is holding a Bowie is what would look wrong in the hands.
//
//  🛑 AND THE RESULT IS RE-CHECKED BEFORE IT IS USED. Die Rise ships the Sickle
//  but does NOT include knife_ballistic_sickle_upgraded_zm - counted from stock
//  zm_highrise.gsc, which includes the base, bowie and no_melee variants and
//  nothing else. So a sickle-carrying player would be handed a weapon that was
//  never precached. If the chosen variant is not included, this falls back to
//  the plain upgraded knife, which every map carrying the weapon does include.
//  If even that is missing, it returns undefined and the perk stays stock.
// ============================================================================
zmqol_whoswho_knife_name()
{
    if ( !isdefined( level.zombie_include_weapons ) )
        return undefined;

    if ( !isdefined( level.zombie_include_weapons[ "knife_ballistic_upgraded_zm" ] ) )
        return undefined;

    str_knife = self maps\mp\zombies\_zm_melee_weapon::give_ballistic_knife( "knife_ballistic_upgraded_zm", 1 );

    if ( !isdefined( str_knife ) || !isdefined( level.zombie_include_weapons[ str_knife ] ) )
        str_knife = "knife_ballistic_upgraded_zm";

    return str_knife;
}

// ============================================================================
// ============================================================================
//  zmqol_awful_lawton  -  the Pack-a-Punched crossbow's bolts distract zombies
//
//  User, 2026-08-17: "make it so same as bo1 zombies pap'd crossbow > awful
//  lawton, the explosive bolts have a monkey bomb distraction effect... and to
//  be absolutely clear it's only for when it's pack a punched not just the base
//  crossbow... and make sure you don't make the pap'd crossbow literally create
//  real monkey bomb grenade, just the distraction mechanism for the zombies ai
//  same as bo1, so that way same as bo1 they go to the explosive bolts."
//
//  📝 THE NAME IS ALREADY RIGHT. crossbow_upgraded_zm's displayName is
//  ZOMBIE_CROSSBOW_EXPLOSIVE_UPGRADED and that reference already resolves to
//  "Awful Lawton" on a zombies map - see the v1.89.0 note in
//  zone_assets\english\localizedstrings\mod.str, which lists it among the
//  eleven refs that must NOT be re-declared. Nothing to do there.
//
//  🌟 NO MONKEY IS CREATED, AND NONE IS NEEDED. Stock's cymbal monkey does the
//  attraction with two calls out of maps\mp\zombies\_zm_utility, and they are
//  the whole of it - _zm_weap_cymbal_monkey.gsc:331-334:
//        create_zombie_point_of_interest( max_attract_dist, num_attractors, 10000 )
//        create_zombie_point_of_interest_attractor_positions( 4, attract_dist_diff )
//  Everything else in that function - the monkey model, the animtree, the glow
//  fx, the music, the player clone, resetmissiledetonationtime() - is the toy,
//  not the mechanism. Zombies find these by nothing more than the
//  script_noteworthy = "zombie_poi" that create_zombie_point_of_interest sets:
//  _zm_ai_basic.gsc:42 -> get_zombie_point_of_interest() ->
//  getentarray( "zombie_poi", "script_noteworthy" ) (_zm_utility.gsc). So the
//  bolt itself becomes the point of interest, and when it explodes and the
//  entity goes away it drops out of that array on its own. No cleanup to get
//  wrong, no monkey entity, no monkey sound.
//
//  The numbers are the monkey's own defaults, read from
//  _zm_weap_cymbal_monkey::player_handle_cymbal_monkey() (:44-59):
//  1536 attract distance, 96 attractors, 4 rings 45 units apart.
//
//  🛑 THE PROJECTILE IS NOT THE BOLT, AND GETTING THAT WRONG WOULD HAVE COST A
//  BOOT. Firing crossbow_upgraded_zm produces TWO entities: the missile handed
//  to the "missile_fire" notify, and a separate grenade-classname entity - its
//  grenadeWeapon, crossbow_explosive_bolt_upgraded_zm (weaponType grenade,
//  fuseTime 3, stickiness "Stick to all"), which is what sticks and explodes.
//  The POI has to go on the GRENADE, or zombies walk to the wrong place. Both
//  the split and the "missile_fire" notify name are BO2-Reimagined's, out of
//  scripts\zm\reimagined\_zm_weap_crossbow.gsc, which solves this same problem
//  on the same engine - the designated reference for this project.
//
//  Told apart by model, which the two weapon files settle outright:
//        crossbow_upgraded_zm            projectileModel t5_weapon_crossbow_bolt_exp
//        crossbow_explosive_bolt_*_zm    projectileModel t5_weapon_crossbow_bolt
//  so the search below cannot pick up the missile it was launched from.
//
//  📝 THREE DELIBERATE DIFFERENCES FROM REIMAGINED'S VERSION, all of them
//  narrowing it back to what was actually asked for:
//    1. Their version also plays a zm_electric_stun animation on the zombie the
//       bolt lands in. That is a Reimagined balance change, not BO1 behaviour,
//       and the request was the distraction "same as bo1". Dropped.
//    2. Theirs deletes the missile entity. This mod's crossbow already works
//       without that and the user has played it; deleting an entity the mod has
//       never deleted is a behaviour change outside the request. Left alone.
//    3. Theirs takes the first unmarked bolt in the array; this takes the
//       CLOSEST unmarked bolt to where the shot actually landed, so a bolt still
//       in flight from an earlier shot - or from the un-upgraded crossbow, which
//       this function does not mark at all - cannot be picked up by mistake.
// ============================================================================
zmqol_awful_lawton_onplayerconnect()
{
    for (;;)
    {
        level waittill( "connected", player );
        player thread zmqol_awful_lawton_watch();
    }
}

zmqol_awful_lawton_watch()
{
    self endon( "disconnect" );
    level endon( "end_game" );

    for (;;)
    {
        self waittill( "missile_fire", e_missile, str_weapon );

        //  Pack-a-Punched ONLY. The box crossbow is untouched, as asked.
        if ( !isdefined( str_weapon ) || str_weapon != "crossbow_upgraded_zm" )
            continue;

        if ( isdefined( e_missile ) )
            e_missile thread zmqol_awful_lawton_bolt();
    }
}

zmqol_awful_lawton_bolt()
{
    self endon( "death" );

    self waittill( "stationary", v_endpos );

    if ( !isdefined( v_endpos ) )
        v_endpos = self.origin;

    e_bolt  = undefined;
    n_best  = 262144;   // 512 units, squared - further than that is a different shot
    a_nades = getentarray( "grenade", "classname" );

    for ( i = 0; i < a_nades.size; i++ )
    {
        if ( !isdefined( a_nades[i] ) || !isdefined( a_nades[i].model ) )
            continue;

        if ( a_nades[i].model != "t5_weapon_crossbow_bolt" )
            continue;

        if ( isdefined( a_nades[i].zmqol_lawton_done ) )
            continue;

        n_dist = distancesquared( a_nades[i].origin, v_endpos );

        if ( n_dist > n_best )
            continue;

        n_best = n_dist;
        e_bolt = a_nades[i];
    }

    if ( !isdefined( e_bolt ) )
        return;

    e_bolt.zmqol_lawton_done = 1;

    //  Stock's own guard, from the monkey (:325). A bolt fired into a zone that
    //  is not open must not pull zombies through a wall to reach it.
    if ( !check_point_in_enabled_zone( e_bolt.origin, undefined, undefined ) )
        return;

    e_bolt create_zombie_point_of_interest( 1536, 96, 10000 );
    e_bolt thread create_zombie_point_of_interest_attractor_positions( 4, 45 );
    e_bolt thread zmqol_awful_lawton_follow_if_moving();

    //  🔎 ONE line, the first time only, so a single boot settles the one thing
    //  that cannot be checked offline: whether "missile_fire" is really the
    //  notify this weapon emits. Reimagined's crossbow code says it is, on this
    //  same engine and this same weapon, but that is their evidence and not a
    //  test of this build. If the log has this line, the whole chain fired -
    //  notify, stationary, bolt found, zone valid, POI created. If the feature
    //  looks dead AND this line is absent, the notify name is where to start.
    if ( !isdefined( level.zmqol_lawton_logged ) )
    {
        level.zmqol_lawton_logged = 1;
        println( "[zm_qol] awful lawton: bolt POI created at ("
               + int( e_bolt.origin[0] ) + "," + int( e_bolt.origin[1] ) + "," + int( e_bolt.origin[2] ) + ")" );
    }
}

// ============================================================================
//  zmqol_awful_lawton_follow_if_moving
//
//  The ring of attractor positions is a snapshot of where the bolt landed. If
//  the bolt is stuck in a zombie that is still walking, that ring is stale the
//  moment it is generated, so fall back to attract_to_origin - the same flag
//  stock's monkey uses while its own ring is still being built
//  (_zm_weap_cymbal_monkey.gsc:332, cleared at :399 once the ring exists).
//
//  Measured rather than assumed: the bolt is watched and the flag is set only if
//  it actually moves. A bolt in a wall never trips it; a bolt in a zombie trips
//  it on the first tick. This covers the case Reimagined handles by freezing the
//  zombie with a stun animation, without adding the animation.
//
//  It must run AFTER the ring exists, because
//  create_zombie_point_of_interest_attractor_positions() clears
//  attract_to_origin as its first act - hence the waittill rather than a wait.
// ============================================================================
zmqol_awful_lawton_follow_if_moving()
{
    self endon( "death" );

    self waittill( "attractor_positions_generated" );

    v_last = self.origin;

    for ( i = 0; i < 60; i++ )
    {
        wait 0.05;

        if ( distancesquared( self.origin, v_last ) > 4 )
        {
            self.attract_to_origin = 1;
            return;
        }

        v_last = self.origin;
    }
}

// ============================================================================
//  BETTER DEADSHOT  -  v1.99.73, user request 2026-08-19
// ----------------------------------------------------------------------------
//  *"add an option in the game tab in settings as an option to make deadshot do
//  double headshot damage, same as reimagined. Just a simple on/off switch"*
//
//  🛑 WHY DEADSHOT NEEDED THIS AT ALL. Deadshot Daiquiri's entire stock effect is
//  ONE client-side engine call - `self usealternateaimparams()`, made by
//  _zm.csc:611 on the deadshot_perk clientfield - which swaps the aim-assist
//  lock-on to a parameter set that favours the head. Aim assist exists only on a
//  controller, so on mouse and keyboard the perk does *nothing whatsoever*. That
//  is stock, not a fault in this mod, and it is the reason the perk has the
//  reputation it does.
//
//  🌟 THE HOOK: RE-POINT level.callbackactordamage, DO NOT replaceFunc.
//  Stock installs its own wrapper as a POINTER (`level.callbackactordamage =
//  ::actor_damage_override_wrapper`, _zm.gsc:976), and CLAUDE.md §4 failure mode
//  3 is exactly this shape: a `::fn` captured at assignment cannot be relied on
//  to follow a later replaceFunc. Re-pointing is the prescribed route.
//
//  🛑 AND ORIGINS RE-POINTS IT TOO. zm_tomb.gsc:219 installs
//  tomb_actor_damage_override_wrapper, which adds the Zombie-Blood damage gate,
//  the capture-zombie points and the tank/gib death handling before calling
//  stock's wrapper qualified. So this must CHAIN to whatever is already
//  installed rather than assume stock's - that is what level.zmqol_prev_actordamage
//  is for. Nothing is reimplemented and no map's own damage rules are lost.
//
//  🌟 IT SCALES THE INCOMING DAMAGE, NOT THE FINAL DAMAGE. BO2-Reimagined does
//  `final_damage *= 2` inside its own copy of actor_damage_override; this mod
//  does not own that function, and reproducing it would mean re-implementing
//  Origins' wrapper as well. Pre-scaling lets the entire existing chain run
//  untouched. 📝 The one behavioural difference, stated rather than hidden: an
//  enemy whose `self.actor_damage_func` returns a FIXED number regardless of
//  input - Brutus-style armour rules - is unaffected here where Reimagined would
//  double it. That is arguably the more correct outcome, but it IS a difference.
//
//  The eligibility test is Reimagined's, as asked: bullet headshots only,
//  shotguns excluded except the KSG, metalstorm excluded.
//
//  🛑 INSTALLED AFTER initial_blackscreen_passed. Stock sets the pointer during
//  map init and Origins re-points it there too; installing any earlier would
//  either be overwritten or would capture the wrong predecessor. No zombie can
//  be damaged before that flag, so nothing is missed.
// ============================================================================
zmqol_better_deadshot_install()
{
    if ( zmqol_minimal() )
        return;

    flag_wait( "initial_blackscreen_passed" );

    if ( !isdefined( level.callbackactordamage ) )
        return;

    //  Guarded so a second call can never chain the wrapper to itself, which
    //  would be an infinite recursion on the first bullet fired.
    if ( isdefined( level.zmqol_prev_actordamage ) )
        return;

    level.zmqol_prev_actordamage = level.callbackactordamage;
    level.callbackactordamage = ::zmqol_actor_damage_wrapper;

    println( "[zm_qol] better deadshot: damage chain installed" );
}

zmqol_actor_damage_wrapper( inflictor, attacker, damage, flags, meansofdeath, weapon, vpoint, vdir, shitloc, psoffsettime, boneindex )
{
    //  v2.8.2 - ONE SHOT ONE KILL (CHEATS tab). Last, so it wins over any
    //  multiplier above it. See zmqol_one_shot_scale() below.
    damage = zmqol_one_shot_scale( damage, attacker, meansofdeath );

    self [[ level.zmqol_prev_actordamage ]]( inflictor, attacker, damage, flags, meansofdeath, weapon, vpoint, vdir, shitloc, psoffsettime, boneindex );
}

// ============================================================================
//  ONE SHOT ONE KILL  -  v2.8.2, user request 2026-08-29, the CHEATS tab
// ----------------------------------------------------------------------------
//  🌟 NO NEW HOOK AND NO NEW RISK. It rides the level.callbackactordamage chain
//  zmqol_better_deadshot_install() already owns - the same chain, the same
//  single install, the same chaining to whatever Origins or a gametype put
//  there first. Nothing else about the damage path changes.
//
//  🛑 IT RAISES THE DAMAGE TO EXACTLY self.health, NOT TO A BIG NUMBER.
//  Zombie health is grown 10% a round and stock's own ai_calculate_health()
//  (_zm.gsc:3572) only stops when the value OVERFLOWS a 32-bit int - which is
//  the whole basis of the INSTAKILL ROUNDS row on the PATCHES tab. So at a high
//  round self.health can sit near 2^31, and any fixed constant is either too
//  small to kill there or large enough to overflow when a boss damage func
//  multiplies it. self.health is the exact amount needed and can never do
//  either.
//
//  🛑 BOSSES KEEP THEIR OWN RULES, and that is deliberate rather than a gap.
//  Stock runs self.actor_damage_func BEFORE the final damage is applied
//  (_zm.gsc:4435), and that is where the Panzer's faceplate, Brutus's helmet,
//  the Ghost's phase state and the Avogadro's EMP-only immunity live. A func
//  that SCALES damage still receives self.health here and still kills; a func
//  that returns 0 for the wrong weapon - the Avogadro's - correctly keeps its
//  immunity. Forcing those open would not be a cheat, it would be deleting the
//  boss fights.
//
//  📝 Never applied when the damaged entity is a player: stock's own
//  actor_damage_override() guards with isplayer( self ), so the case exists.
// ============================================================================
zmqol_one_shot_scale( damage, attacker, meansofdeath )
{
    if ( !getdvarintdefault( "one_shot_one_kill", 0 ) )
        return damage;

    if ( !isdefined( damage ) || !isdefined( attacker ) || !isplayer( attacker ) )
        return damage;

    if ( !isdefined( meansofdeath ) || meansofdeath == "" )
        return damage;

    if ( isdefined( self ) && isplayer( self ) )
        return damage;

    if ( !isdefined( self.health ) || self.health <= 0 )
        return damage;

    if ( damage >= self.health )
        return damage;

    return self.health;
}

// ============================================================================
//  AIM ASSIST  -  v1.99.74, user request 2026-08-19
// ----------------------------------------------------------------------------
//  *"seperate target assist from aim assist on the gamepad controls menu"*, then
//  *"do the aim assist option under target assist right now."*
//
//  🛑 READ THIS BEFORE CHANGING ANYTHING HERE - WHAT THIS ROW CAN AND CANNOT DO.
//  It can take aim assist AWAY. It cannot give it back when the player's own
//  TARGET ASSIST switch is off, and nothing in the retail build can. Measured,
//  not assumed:
//
//    * The live game registers NINE aim_* dvars, all of them turn-rate ones
//      ( aim_accel_turnrate_*, aim_input_graph_*, aim_scale_view_axis,
//        aim_turnrate_* ) - counted out of this install's own console_zm.log
//      dvar dump, 3080 total dvars.
//    * aim_lockon_enabled, aim_slowdown_enabled, aim_autoaim_enabled and the
//      whole aim_alternate_lockon_* block are STRINGS INSIDE t6zm.exe BUT NOT
//      REGISTERED DVARS. Writing one creates a fresh dvar nothing reads.
//      🛑 v2.14.28 CORRECTION: this bullet used to list aim_automelee_enabled
//      here too. It IS a registered dvar - the dvar dump in
//      crashlogs\console_zm_07-19-13.log carries aim_automelee_enabled "1",
//      aim_automelee_range "120" and the rest of the aim_automelee_* family -
//      and it is the engine's melee-charge (knife lunge) switch, which the
//      GAME 3 tab's KNIFE LUNGE row (qol_options.gsc::qol_opt_knife_lunge)
//      now drives. It has nothing to do with aim assist onto targets.
//    * input_targetAssist is a PROFILE var, not a dvar - no input_* entry
//      appears anywhere in the dump - and it is the single retail switch.
//
//  🌟 SO THE ONE REAL LEVER IS THE TARGET SIDE, AND STOCK USES IT ITSELF.
//  enableaimassist() / disableaimassist() are per-ENTITY calls that mark whether
//  a thing can be assisted ONTO. Stock calls `guy enableaimassist()` on every
//  zombie it spawns ( _zm_utility.gsc:258 ) and disableaimassist() on the Ghost,
//  the Sloth and Origins' quadrotor. Turning that off for every zombie removes
//  aim assist in the only place it exists - which is a genuine switch, and it is
//  independent of the player's TARGET ASSIST row.
//
//  📝 DEADSHOT IS NOT FIXED BY THIS, AND WAS NEVER GOING TO BE. Its head snap is
//  usealternateaimparams(), which re-tunes assist rather than creating it. The
//  BETTER DEADSHOT toggle ( v1.99.73 ) is what makes the perk worth buying with
//  assist off and on mouse and keyboard.
//
//  Default 1 = stock. A new switch must not change what the mod already does.
// ============================================================================
zmqol_aim_assist_watch()
{
    if ( zmqol_minimal() )
        return;

    level endon( "end_game" );

    flag_wait( "initial_blackscreen_passed" );

    //  -1 so the first pass always applies, which is what picks up a value the
    //  player left in their config from a previous session.
    n_last = -1;

    for ( ;; )
    {
        n_now = getdvarintdefault( "aim_assist", 1 ) != 0;

        if ( n_now != n_last )
        {
            n_last = n_now;
            level.zmqol_aim_assist_on = n_now;
            println( "[zm_qol] aim assist -> " + n_now );
        }

        //  🛑 THIS ONLY EVER DISABLES, AND THAT IS DELIBERATE - RE-ENABLING WOULD
        //  BE A REGRESSION. getaiarray( level.zombie_team ) returns the special
        //  AI too, and stock calls disableaimassist() on Buried's Ghost
        //  ( _zm_ai_ghost.gsc:597 ), Buried's Sloth ( _zm_ai_sloth.gsc:1071 ) and
        //  Origins' quadrotor ( _zm_ai_quadrotor.gsc:780 ) on purpose. A blanket
        //  re-enable pass would hand aim assist to all three, which stock never
        //  does and nobody asked for.
        //
        //  Switching back ON therefore needs no pass at all: stock's own spawner
        //  gives every zombie enableaimassist() as it spawns
        //  ( _zm_utility.gsc:258 ), so the round heals itself as it turns over.
        //  Only the zombies already alive at the moment of the switch keep it
        //  off, and they are dead within the round.
        if ( !n_now )
            zmqol_aim_assist_disable_all();

        wait 1;
    }
}

zmqol_aim_assist_disable_all()
{
    a_zombies = getaiarray( level.zombie_team );

    for ( i = 0; i < a_zombies.size; i++ )
    {
        if ( !isdefined( a_zombies[i] ) )
            continue;

        a_zombies[i] disableaimassist();
    }
}

// ============================================================================
//  zmqol_wallbuy_variant_*  -  A WALL BUY GIVES THE SAME VARIANT THE BOX GIVES
//                                                                  (v1.99.91)
//
//  User, 2026-08-20: *"I grabbed the B23R wallbuy ... then when I spun the box
//  and got the B23R version from the box which I'm pretty certain is the B23R
//  extended mag ... just make it so the B23R and also [any] wall buy weapon that
//  has a mystery box version that has a attachment, make it so that the wall buy
//  version also has the same attachment as the box version (Again same as you
//  did previously in the mods' development for the MP40) ... fixing that for all
//  gun wallbuys with box attachment variants would fix the issue of being able
//  to have the same weapon twice."*
//
//  -- WHY THE MOD CAUSED THIS, MEASURED FROM THE STOCK DUMP -------------------
//  In stock BO2 exactly ONE map has attachment variants in its box: Origins,
//  with ak74u_extclip_zm, beretta93r_extclip_zm and mp40_stalker_zm (a grep of
//  every map's include_weapon calls - the other five maps have none at all).
//  This mod puts the first two into the box on EVERY map:
//      zm_transit.gsc:592,598  zm_nuked.gsc:698,703  zm_highrise.gsc:530,535
//      zm_buried.gsc:159,164   zm_prison.gsc:351,355
//  while the wall buy still hands out the plain def - so the box copy and the
//  wall-buy copy are two different weapons and both fit in the inventory. That
//  is the duplicate B23R the user ended up holding on Nuketown, and it is the
//  same shape as the Origins MP40 the user had fixed on 2026-08-07.
//
//  -- THE MECHANISM IS ORIGINS' OWN, GENERALISED ------------------------------
//  zm_tomb.gsc's zmqol_tomb_mp40_stalker_wallbuys() is the proven version of
//  this and every hard-won detail in it is carried over:
//    - retag the unitrigger STUB's .zombie_weapon_upgrade / .weapon_upgrade,
//      because _zm_weapons.gsc:1120 reads the weapon off the stub live at
//      purchase, so this does not have to race init_spawnable_weapon_upgrade();
//    - push the same value onto any ALREADY-LIVE trigger, because
//      copy_zombie_keys_onto_trigger (_zm_unitrigger.gsc:624-629) copies it once
//      at build time and a built trigger is never rebuilt, so a stub-only fix
//      leaves an existing wall buy handing out the old gun;
//    - refresh hint_string and cost from the replacement's own registration, and
//      REFUSE to touch anything if that weapon is not in level.zombie_weapons -
//      get_weapon_hint/cost index it directly, and writing an undefined hint is
//      what killed the buy prompt outright in v1.59.2;
//    - re-scan for the whole match instead of once, because the one-shot version
//      lost a race it could not see (v1.80.0) and gave the plain gun for the
//      rest of the game.
//
//  ORIGINS' OWN MP40 THREAD IS DELIBERATELY LEFT RUNNING. It is confirmed
//  working in game and this pass writes the identical value, so the overlap is a
//  no-op rather than a conflict. Nothing is removed from a working feature to
//  make a new one tidier.
//
//  THE PAIRS ARE ONLY EVER BASE -> VARIANT OF THE SAME GUN, so ammo, hint and
//  cost all already match: the mod's per-map scripts register each variant with
//  the same hint and cost as the base and call add_shared_ammo_weapon() on it.
//  A map that has neither the wall buy nor the variant simply matches nothing.
//
//      zmqol_wallbuy_variant 0    off - every wall buy gives what the map set
//      zmqol_wallbuy_variant 1    DEFAULT
// ============================================================================
zmqol_wallbuy_variant_pairs()
{
    a = [];
    a[ "beretta93r_zm" ] = "beretta93r_extclip_zm";
    a[ "ak74u_zm" ]      = "ak74u_extclip_zm";
    a[ "mp40_zm" ]       = "mp40_stalker_zm";
    return a;
}

zmqol_wallbuy_variant_keep()
{
    level endon( "end_game" );

    if ( !getdvarintdefault( "zmqol_wallbuy_variant", 1 ) )
        return;

    n_passes = 0;

    //  Same cadence and cap as Origins' thread: 900 passes at 2s covers any
    //  realistic match, and a stub that registers late is caught whenever it
    //  appears rather than only inside an opening window.
    while ( n_passes < 900 )
    {
        zmqol_wallbuy_variant_pass();
        n_passes++;
        wait 2;
    }
}

zmqol_wallbuy_variant_pass()
{
    if ( !isdefined( level._unitriggers ) || !isdefined( level._unitriggers.trigger_stubs ) )
        return 0;

    a_pairs = zmqol_wallbuy_variant_pairs();
    a_from  = getarraykeys( a_pairs );
    a_stubs = level._unitriggers.trigger_stubs;
    n_total = 0;

    for ( p = 0; p < a_from.size; p++ )
    {
        str_from = a_from[p];
        str_to   = a_pairs[ str_from ];

        //  The replacement must be a registered weapon on THIS map, or
        //  get_weapon_hint/cost return undefined and the wall buy loses its
        //  prompt entirely. A map without the variant is left completely alone.
        if ( !isdefined( level.zombie_weapons ) || !isdefined( level.zombie_weapons[ str_to ] ) )
            continue;

        str_hint = maps\mp\zombies\_zm_weapons::get_weapon_hint( str_to );
        n_cost   = maps\mp\zombies\_zm_weapons::get_weapon_cost( str_to );

        if ( !isdefined( str_hint ) || !isdefined( n_cost ) )
            continue;

        n_this = 0;

        for ( i = 0; i < a_stubs.size; i++ )
        {
            if ( !isdefined( a_stubs[i] ) || !isdefined( a_stubs[i].zombie_weapon_upgrade ) )
                continue;

            if ( a_stubs[i].zombie_weapon_upgrade != str_from )
                continue;

            a_stubs[i].zombie_weapon_upgrade = str_to;

            if ( isdefined( a_stubs[i].weapon_upgrade ) )
                a_stubs[i].weapon_upgrade = str_to;

            a_stubs[i].hint_string = str_hint;
            a_stubs[i].cost        = n_cost;

            //  The already-built triggers carry their own copy.
            a_stubs[i] zmqol_wallbuy_variant_push_live();

            n_this++;
        }

        if ( n_this > 0 )
            println( "[zm_qol] wallbuy variant: " + n_this + " " + str_from + " wall buy(s) now give " + str_to );

        n_total += n_this;
    }

    return n_total;
}

// ----------------------------------------------------------------------------
//  The body of zm_tomb.gsc::zmqol_mp40_push_to_live_triggers(), which is
//  confirmed working in game. It lives here as well rather than being called
//  across files because that one is inside a MAP script - a root script may not
//  reference maps\mp\zm_tomb... at all (AI_CONTEXT rule 2: the reference
//  resolves at LOAD time and would kill every other map).
// ----------------------------------------------------------------------------
zmqol_wallbuy_variant_push_live()
{
    n = 0;

    if ( isdefined( self.trigger ) )
    {
        self.trigger.zombie_weapon_upgrade = self.zombie_weapon_upgrade;

        if ( isdefined( self.trigger.weapon_upgrade ) )
            self.trigger.weapon_upgrade = self.zombie_weapon_upgrade;

        n++;
    }

    if ( isdefined( self.playertrigger ) )
    {
        keys = getarraykeys( self.playertrigger );

        for ( k = 0; k < keys.size; k++ )
        {
            if ( !isdefined( self.playertrigger[ keys[k] ] ) )
                continue;

            self.playertrigger[ keys[k] ].zombie_weapon_upgrade = self.zombie_weapon_upgrade;

            if ( isdefined( self.playertrigger[ keys[k] ].weapon_upgrade ) )
                self.playertrigger[ keys[k] ].weapon_upgrade = self.zombie_weapon_upgrade;

            n++;
        }
    }

    return n;
}

// ============================================================================
//  THE PATCHES TAB + SET POINTS + TELEPORT                          (v1.99.93)
// ----------------------------------------------------------------------------
//  User, 2026-08-20, three requests in two messages:
//
//    1. *"add a new tab after the GAME tab called PATCHES, this will contain all
//       Patch toggles like backspeed patch ... add the REMOVE ROUND CAP toggle
//       ... 24 Zombies Round Limit on solo play, Instakill rounds start on round
//       163, Double-tap reverted to 1.0 toggle, Sliquifier pre-patch/pre-nerf by
//       treyarch, Weapon recoil pre-patched/pre-nerf, No zombies attacking
//       through barriers."*
//    2. *"set points ... start at 0 (none) and then go to 1000, 5000, 10000,
//       100000, 1000000. And the reason it's "set" points instead of "give"
//       points is so if you wanna revert it ... you can just go back and set it
//       to a lower number and have that amount of points."*
//    3. *"add the teleport menu from the strat tester to my cheats tab."*
//
//  🌟 EVERY MECHANISM BELOW IS PORTED FROM A SOURCE THE USER SUPPLIED AND THEN
//  CHECKED AGAINST THE SHIPPED SCRIPT, NOT TAKEN ON TRUST. That check is what
//  removed two of the seven patch rows - see the note in init() - and what
//  turned two others into live, reversible level-variable writes instead of the
//  replaceFuncs the legacy mod uses.
//
//  📝 The dvars are read, never trusted to exist: every read is
//  getdvarintdefault( name, <the shipping default> ), so a console `reset` or a
//  missing registration can only fall back to current behaviour.
// ============================================================================

// ============================================================================
//  zmqol_set_points_watch  -  CHEATS > SET POINTS
//
//  🛑 IT IS NOT AN ACTION ROW, AND THAT IS THE WHOLE REQUEST. CHANGE ROUND and
//  KILL HORDE write themselves back to 0 as soon as they fire; this one HOLDS
//  its value, because 0 ("NONE") is a real setting and the user wants to step
//  back DOWN the list to take points away. So it is applied on CHANGE only, and
//  the last applied value is seeded from the dvar on the first pass - otherwise
//  every spawn would re-apply whatever the row happens to be sitting on.
//
//  🛑 THE SCORE IS WRITTEN DIRECTLY, AND THAT IS DELIBERATE. The obvious route
//  is _zm_score::add_to_player_score / minus_to_player_score, but
//  minus_to_player_score ends with `level notify( "spent_points", self, points )`
//  ( _zm_score.gsc:341 ) and Origins listens to it: zm_tomb_challenges.gsc:49
//  counts every point "spent" towards the Rituals of the Ancients points
//  challenge, whose reward is a free Double Tap. Stepping this row from 1000000
//  down to 1000 would hand that challenge over instantly. Stock itself assigns
//  the field directly in exactly this situation - player_downed_score_loss does
//  `self.score = points;` at _zm_score.gsc:303-308 - so this is stock's own
//  route, not a way around one.
//
//  📝 score_total is raised by the same delta when the row goes UP, which is
//  what add_to_player_score would have done ( :322-323 ); it is deliberately not
//  lowered again, because stock's minus path never touches it either.
//
//  📝 In co-op this reads one server dvar, so it sets everyone's points - the
//  same shape as the god / ghost / infinite ammo rows that already ship.
// ============================================================================
zmqol_set_points_watch()
{
    if ( zmqol_minimal() )
        return;

    self endon( "disconnect" );
    level endon( "game_ended" );

    n_last = getdvarintdefault( "set_points", 0 );

    for ( ;; )
    {
        n_want = getdvarintdefault( "set_points", 0 );

        if ( n_want != n_last )
        {
            n_last = n_want;

            //  🛑 self.score is guarded, not assumed: this thread starts at CONNECT
            //  and stock only fills the field in on spawn, so a row moved during
            //  the pre-game blackscreen would otherwise subtract from undefined -
            //  a runtime error, and Plutonium kills the thread for it in silence.
            if ( isdefined( self.score ) && ( !isdefined( level.intermission ) || !level.intermission ) )
            {
                n_delta = n_want - self.score;

                self.score = n_want;
                self.pers["score"] = self.score;

                if ( n_delta > 0 && isdefined( self.score_total ) )
                    self.score_total = self.score_total + n_delta;

                self iprintln( "^2[zm_qol] ^7points set to ^2" + n_want );
            }
        }

        wait 0.25;
    }
}

// ============================================================================
//  zmqol_teleport_watch / zmqol_teleport_dest  -  CHEATS > TELEPORT
//
//  🌟 THE DESTINATIONS ARE THE STRAT TESTER'S OWN, copied value for value out of
//  Strat-Tester-BO2\scripts\zm\strattester\commands.gsc::tpcase() -
//  position AND angles, so each one lands facing the way it does there. Nothing
//  is invented: Nuketown has no list in that file, so until v2.10.4 it had no
//  row in the menu and no case here.
//
//  v2.10.4 - NUKETOWN, measured from the map's OWN entities, not authored by
//  hand. zm_nuked.ff's mapents carry exactly three `player_respawn_point`
//  structs - the spots stock's own zone manager puts a respawning player on
//  (_zm_zonemgr.gsc:661/832 pick the nearest one in an enabled zone) - so
//  they are, by construction, places a player can stand:
//      culdesac_zone            (-56.5, -228.5, 6)  yaw 270   SPAWN
//      openhouse1_backyard_zone (-1872, 402, -24)   yaw 340   GREEN HOUSE BACKYARD
//      openhouse2_backyard_zone (1944, 384, -24)    yaw 190   YELLOW HOUSE BACKYARD
//  openhouse1 = green and openhouse2 = yellow is read off zm_nuked.gsc:588-596
//  (nuked_update_player_zones counts openhouse1_backyard_zone into
//  level.green_backyard and openhouse2 into level.yellow_backyard). The
//  angles are the structs' own. Nothing else on that map is a measured
//  standing position (the other structs are the box/perk pads, which put a
//  player inside a machine), so three is the honest list - add more only
//  from a `.where` reading.
//
//  🛑 THE INDEX ORDER MUST MATCH THE LUI LIST EXACTLY. The menu row's values are
//  indices into the switch below, and the two lists are written to be read side
//  by side - ui\t6\menus\optionssettings.lua, CreateQolCheatsTab, ZmTele. The
//  TranZit order in particular is NOT the Strat Tester's own order.
//
//  🛑 CLASSIC ONLY, AND THIS IS THE TRAP THAT WOULD OTHERWISE HAVE BITTEN. These
//  are classic-layout coordinates; in a survival or grief game the same map is a
//  small carved-out arena and every one of them is outside it. The test is
//  ui_gametype == "zclassic" and NOT `ui_zm_mapstartlocation != "transit"`,
//  because Bus Depot is zstandard AT location transit - the exact false negative
//  that cost this mod a perk on every TranZit survival in v1.83.0 ( see the long
//  note over the Vulture gate ). ui_gametype is safe to read here for the same
//  reason it is safe there.
//
//  📝 v2.10.4 - NUKETOWN IS THE ONE EXCEPTION TO THE CLASSIC GATE. That map
//  registers only zstandard (zm_nuked.gsc:629 - there is no zclassic there),
//  and its zstandard IS the whole map, not a carved-out arena, so the
//  survival-arena reasoning above does not apply. zmqol_teleport_watch() lets
//  zm_nuked through on any gametype; every other map keeps the classic gate.
//
//  🛑 v2.4.2 - SPLIT INTO A SELECTOR + A SEPARATE EXECUTE ROW, MATCHING THE
//  STRAT TESTER'S OWN UX. User, 2026-08-26: *"right now you just cycle through
//  the teleport locations... and then it automatically tp's you to the
//  location when you exit the pause menu... there should be an option to
//  execute teleport... underneath, same as the strat tester."* Checked against
//  the Strat Tester's own menu (optionsstrattester.lua:240-293): it has a
//  left-right destination selector PLUS a separate "EXECUTE TELEPORT" button -
//  picking a destination there only ever writes a dvar, never moves the
//  player by itself.
//
//  "teleport" is now a HOLDING selector, same shape as set_points (0 is a
//  real choice - OFF/no destination picked - and picking a destination does
//  not by itself do anything). "execute_teleport" is the new ACTION row: it
//  writes itself back to 0 the instant it fires, same shape as kill_horde /
//  end_round, so the CHEATS row snaps back to DISABLED and the button can be
//  pressed again for the same destination without having to reselect it.
// ============================================================================
zmqol_teleport_watch()
{
    if ( zmqol_minimal() )
        return;

    self endon( "disconnect" );
    level endon( "game_ended" );

    for ( ;; )
    {
        if ( getdvarintdefault( "execute_teleport", 0 ) )
        {
            setdvar( "execute_teleport", "0" );
            n_want = getdvarintdefault( "teleport", 0 );

            if ( n_want <= 0 )
                self iprintln( "^3[zm_qol] teleport: ^7pick a destination first" );
            else if ( getdvar( "ui_gametype" ) != "zclassic" && level.script != "zm_nuked" )
                self iprintln( "^3[zm_qol] teleport is classic-only ^7- these landmarks sit outside a survival or grief arena" );
            else
            {
                a_dest = zmqol_teleport_dest( n_want );

                if ( !isdefined( a_dest ) )
                    self iprintln( "^3[zm_qol] teleport: ^7no destination " + n_want + " on this map" );
                else
                {
                    self setorigin( a_dest["pos"] );
                    self setplayerangles( a_dest["ang"] );
                    println( "[zm_qol] teleport -> " + level.script + " #" + n_want );
                }
            }
        }

        wait 0.25;
    }
}

zmqol_teleport_dest( n )
{
    a = [];

    if ( level.script == "zm_transit" )
    {
        switch ( n )
        {
            case 1: a["pos"] = ( -5012, -6694, -60 );  a["ang"] = ( 0, -127, 0 ); break;   // DINER
            case 2: a["pos"] = ( 6908, -5750, -62 );   a["ang"] = ( 0, 173, 0 );  break;   // FARM
            case 3: a["pos"] = ( 1152, -717, -55 );    a["ang"] = ( 0, 45, 0 );   break;   // TOWN
            case 4: a["pos"] = ( -7384, 4693, -63 );   a["ang"] = ( 0, 18, 0 );   break;   // BUS DEPOT
            case 5: a["pos"] = ( -11814, -1903, 228 ); a["ang"] = ( 0, -60, 0 );  break;   // TUNNEL
            case 6: a["pos"] = ( 13840, -261, -188 );  a["ang"] = ( 0, -108, 0 ); break;   // NACHT
            case 7: a["pos"] = ( 12195, 8266, -751 );  a["ang"] = ( 0, -90, 0 );  break;   // POWER STATION
            case 8: a["pos"] = ( 11200, 7745, -564 );  a["ang"] = ( 0, -108, 0 ); break;   // AK74U
            case 9: a["pos"] = ( 10600, 8272, -400 );  a["ang"] = ( 0, -108, 0 ); break;   // WAREHOUSE
            default: return undefined;
        }

        return a;
    }

    if ( level.script == "zm_prison" )
    {
        switch ( n )
        {
            case 1: a["pos"] = ( 3309, 9329, 1336 );   a["ang"] = ( 0, 131, 0 ); break;    // CAFETERIA
            case 2: a["pos"] = ( -1771, 5401, -71 );   a["ang"] = ( 0, 0, 0 );   break;    // CAGE
            case 3: a["pos"] = ( -1042, 9489, 1350 );  a["ang"] = ( 0, -43, 0 ); break;    // WARDEN'S OFFICE
            case 4: a["pos"] = ( 25, 8762, 1128 );     a["ang"] = ( 0, 0, 0 );   break;    // DOUBLE TAP
            default: return undefined;
        }

        return a;
    }

    if ( level.script == "zm_highrise" )
    {
        switch ( n )
        {
            case 1: a["pos"] = ( 3805, 1920, 2197 );   a["ang"] = ( 0, -161, 0 ); break;   // SHAFT
            case 2: a["pos"] = ( 2159, 1161, 3070 );   a["ang"] = ( 0, 135, 0 );  break;   // TRAMPLESTEAM
            default: return undefined;
        }

        return a;
    }

    if ( level.script == "zm_buried" )
    {
        switch ( n )
        {
            case 1: a["pos"] = ( 553, -1214, 56 );     a["ang"] = ( 0, -50, 0 ); break;    // SALOON
            case 2: a["pos"] = ( -660, 1030, 8 );      a["ang"] = ( 0, -90, 0 ); break;    // JUGGERNOG
            case 3: a["pos"] = ( -483, 293, 423 );     a["ang"] = ( 0, -40, 0 ); break;    // TUNNEL
            default: return undefined;
        }

        return a;
    }

    if ( level.script == "zm_tomb" )
    {
        switch ( n )
        {
            case 1: a["pos"] = ( 1878, -1358, 150 );   a["ang"] = ( 0, 140, 0 );  break;   // CHURCH
            case 2: a["pos"] = ( 10335, -7902, -411 ); a["ang"] = ( 0, 140, 0 );  break;   // CRAZY PLACE
            case 3: a["pos"] = ( 2340, 4978, -303 );   a["ang"] = ( 0, -132, 0 ); break;   // GENERATOR 1
            case 4: a["pos"] = ( 469, 4788, -285 );    a["ang"] = ( 0, -134, 0 ); break;   // GENERATOR 2
            case 5: a["pos"] = ( 740, 2123, -125 );    a["ang"] = ( 0, 135, 0 );  break;   // GENERATOR 3
            case 6: a["pos"] = ( 2337, -170, 140 );    a["ang"] = ( 0, 90, 0 );   break;   // GENERATOR 4
            case 7: a["pos"] = ( -2830, -21, 238 );    a["ang"] = ( 0, 40, 0 );   break;   // GENERATOR 5
            case 8: a["pos"] = ( 732, -3923, 300 );    a["ang"] = ( 0, 50, 0 );   break;   // GENERATOR 6
            case 9:
                //  📝 level.vh_tank is a level VARIABLE, not a function
                //  reference, so reading it from this root script is safe - it
                //  is not the AI_CONTEXT rule-2 load-time trap. Guarded anyway:
                //  before the tank exists there is nothing to ride.
                if ( !isdefined( level.vh_tank ) )
                    return undefined;

                a["pos"] = level.vh_tank.origin + ( 0, 0, 50 );
                a["ang"] = level.vh_tank.angles;
                break;                                                                    // TANK
            default: return undefined;
        }

        return a;
    }

    if ( level.script == "zm_nuked" )
    {
        //  The three player_respawn_point structs from zm_nuked.ff's mapents -
        //  see the banner above for the derivation and the house colours.
        switch ( n )
        {
            case 1: a["pos"] = ( -56.5, -228.5, 6 );   a["ang"] = ( 0, 270, 0 ); break;   // SPAWN (cul-de-sac)
            case 2: a["pos"] = ( -1872, 402, -24 );    a["ang"] = ( 0, 340, 0 ); break;   // GREEN HOUSE BACKYARD
            case 3: a["pos"] = ( 1944, 384, -24 );     a["ang"] = ( 0, 190, 0 ); break;   // YELLOW HOUSE BACKYARD
            default: return undefined;
        }

        return a;
    }

    return undefined;
}

// ============================================================================
//  zmqol_hud_round_anchor  -  ROUND COUNTER LEFT                     (v2.0.8)
//
//  User, 2026-08-21: *"my mod has the round counter at the top right of the
//  screen like cold war zombies ... it'd be cool to have an option in the hud
//  tab ... to be able to have it on the top left (same vertical y coords, just
//  on the top left instead of top right, same as bo4 zombies)."*
//
//  🌟 THE MIRROR IS DERIVED FROM TWO SHIPPED ELEMENTS, NOT GUESSED. T6 hudelem
//  x is measured from the SAFE-AREA edge named by horzalign, and it grows
//  OUTWARD from that edge into the margin. Both directions are already in this
//  file with working values:
//        round_hud()   horzalign "right", x = +25   (top right, 25 into the margin)
//        healthbar     horzalign "left",  x = -45   (bottom left, 45 into the margin)
//  So the exact mirror of the round counter's +25 on the right is -25 on the
//  left, and it lands the same distance in from the screen edge.
//
//  🛑 THE WHOLE STACK MOVES, NOT JUST THE NUMBER. timer() and
//  qol_options.gsc::qol_opt_round_timer_hud() are calibrated to sit directly
//  under the round counter and both carried its x = 25 verbatim - the comment
//  above timer() says so and warns that changing one without the other splits
//  the stack. All three now read this one anchor. Only the SIDE changes; every
//  y is untouched, which is exactly what the user asked for.
//
//  📝 Twin of qol_options.gsc::zmqol_hud_round_anchor(). Same shape as
//  zmqol_minimal(), which is duplicated across these two root scripts for the
//  same reason - neither file references the other, and adding a cross-file
//  call would be a new load-order dependency for six lines.
// ============================================================================
// ============================================================================
//  v2.3.4 - HOW MANY DIGITS level.round_number IS, NO INVENTED BUILTIN.
//  No T6 function measures rendered text width offline (checked GSC
//  Documentation.md and the stock dump - neither has one), and `.size` is
//  documented for ARRAYS only (GSC Documentation.md:351), never strings, so
//  it is not used on a round-number string either. This is a plain numeric
//  comparison ladder instead - twin of qol_options.gsc's copy.
// ============================================================================
zmqol_round_digit_count()
{
    n = 1;

    if ( isdefined( level.round_number ) )
        n = int( level.round_number );

    if ( n < 10 )
        return 1;
    else if ( n < 100 )
        return 2;
    else if ( n < 1000 )
        return 3;
    else if ( n < 10000 )
        return 4;
    else if ( n < 100000 )
        return 5;
    else if ( n < 1000000 )
        return 6;

    return 7;
}

zmqol_hud_round_anchor( elem )
{
    if ( !isdefined( elem ) )
        return;

    //  Bo2-VN: ROUND COUNTER POSITION is removed; the counter is always top right.
    {
        // ====================================================================
        //  v2.3.4 - DIGIT-COUNT-AWARE INSET. User, 2026-08-25: round 10000 (5
        //  digits) runs off the right edge at the old fixed x = 25.
        //
        //  🌟 THE PER-DIGIT FIGURE IS MEASURED, NOT GUESSED. timer()'s own
        //  pixel scan just above found round 100's "100" (3 digits, this exact
        //  font/fontscale) 33.67 hud-units wide - about 11.2 units/digit. 3
        //  digits at x = 25 is the baseline that was never reported clipping,
        //  so every digit beyond 3 pulls the anchor back toward screen centre
        //  by ~12 units (11.2 rounded up for margin).
        //
        //  🛑 NOT YET VISUALLY CONFIRMED AT ROUND 10000. I cannot measure the
        //  actual on-screen clearance without seeing it rendered - this is the
        //  documented fallback for "no way to measure it": a digit-count
        //  inset, not a text-width one. Tell me if round 10000 still clips or
        //  now sits too far in and the per-digit constant gets tuned from that.
        // ====================================================================
        n_extra_digits = zmqol_round_digit_count() - 3;

        if ( n_extra_digits < 0 )
            n_extra_digits = 0;

        elem.horzalign = "right";
        elem.x = 25 - n_extra_digits * 12;
    }
}

// ============================================================================
//  NO BLEEDOUT PATCH  -  zombies stop killing themselves      (v2.2.0)
// ----------------------------------------------------------------------------
//  User, 2026-08-21: *"add an option to the patches to tab called NO BLEEDOUT
//  PATCH, which as the name suggests, makes it so zombies don't die by
//  themselves after being alive for too long or getting stuck, so that way the
//  player would have to actually kill the zombies themself, so the zombies
//  don't just randomly die, on or off toggle."*
//
//  🌟 THIS IS STOCK'S OWN FUNCTION, ONE BRANCH SKIPPED. maps\mp\zombies\_zm.gsc
//  round_spawn_failsafe() runs on every zombie: every 30 seconds it measures how
//  far the zombie has moved, and if that is under 24 units (576 squared) it
//  kills it outright with dodamage( health + 100 ). That is the "zombies just
//  randomly die" the user is describing, and it is also what quietly removes a
//  zombie stuck on scenery instead of making the player go and find it.
//
//  🛑 THE BELOW-WORLD KILL IS DELIBERATELY KEPT, AND IT IS NOT A COMPROMISE.
//  The same loop also kills a zombie that has fallen below
//  level.zombie_vars["below_world_check"]. A zombie under the map cannot be
//  shot, so removing that kill would not "make the player earn it" - it would
//  end the round FOREVER. Keeping it is what makes this patch safe to leave on.
//
//  🛑 AND SO IS zombie_assure_node(), which is a different function
//  (_zm_spawner.gsc:600) and is NOT touched: it fires only when a zombie failed
//  to find ANY usable entrance node, waits 20 seconds and then kills it. That
//  zombie has no path to anywhere, so it is the same unkillable case as the one
//  above. Everything the player could actually walk up to and shoot survives.
//
//  Default 0 = stock, like every other PATCHES row. The dvar is read on every
//  pass rather than captured, so the row takes effect mid-match.
//
//  📝 The body below is stock's, verbatim, plus the added branches marked in it.
//  The two /# #/ developer blocks stock has inside the kill branches are dropped
//  because they are empty in the retail dump.
//
//  🛑 v2.14.5 - AND THE PATCH DID NOTHING ON TWO MAPS, WHICH IS WHY THE
//  IGNORE FLAG IS SET BELOW. The user, playing Origins on 2026-09-06 with the row
//  ON: *"a zombie just bled out on its own from me getting far away from it,
//  causing the round to end due to it being the last zombie"*. The live log had
//  `no_bleedout "1"` and NOT ONE `SUPPRESSED` line, so a third route was killing
//  it. It is `level._zombies_round_spawn_failsafe`, a per-map POINTER:
//
//      _zm.gsc:88-89        set to _zm::round_spawn_failsafe only
//                           `if ( !isdefined( ... ) )` - so this mod's own
//                           assignment in main() survives on four maps
//      zm_tomb.gsc:164      OVERWRITES it with ::tomb_round_spawn_failsafe
//      zm_prison.gsc:99     OVERWRITES it with ::alcatraz_round_spawn_failsafe
//
//  Both assignments run inside the map's own main(), AFTER this mod's main() and
//  BEFORE `_zm::init()` reaches `_zm_gametype::custom_spawn_init_func`, which is
//  what array_threads the pointer onto every spawner. There is no hook point in
//  that window, so re-pointing cannot win the race.
//
//  🌟 So every zombie on Origins and Mob of the Dead runs TWO failsafes: this
//  patched one (threaded directly by _zm::round_spawning:3068) and the map's own
//  UNPATCHED copy from the spawn function. The map's kills at 15 seconds, half
//  this one's 30, which is why it always won.
//
//  The fix is stock's own escape hatch - see zmqol_nb_sync_ignore_flag() above -
//  and the ordering is not a hope: run_spawn_functions() opens with
//  `waittillframeend` (_zm_utility.gsc:284), so the map's copy cannot start until
//  the end of the frame in which this one already set the flag. Its very first
//  check then returns.
//
//  🛑 The map copies are ALSO replaced, in scripts\zm\zm_tomb\zm_tomb.gsc and
//  scripts\zm\zm_prison\zm_prison.gsc, for the zombies that never go through
//  round_spawning() (Origins' capture-zone spawns, Grief's zmeat spawns). Whether
//  a replaceFunc reaches a call made through a stored pointer is NOT established
//  on this project - STOCK_REFERENCE 7a records the opposite - so those two
//  replacements print once when they run. The flag above is the belt; they are
//  the braces.
// ============================================================================
//  ----------------------------------------------------------------------------
//  zmqol_nb_sync_ignore_flag  -  v2.14.5
//
//  🌟 `self.ignore_round_spawn_failsafe` IS STOCK'S OWN ESCAPE HATCH AND NOTHING
//  IN STOCK EVER SETS IT. Four occurrences in the whole 2,093-file dump, all of
//  them the same `isdefined(...) && ...` read at the top of a failsafe loop:
//  _zm.gsc (shared), zm_tomb.gsc (Origins), zm_prison.gsc (Mob of the Dead) and
//  the Diner copy. Treyarch left the writer to mods. So writing it cannot
//  collide with anything, and it switches off EVERY variant at once - including
//  the two this mod does not otherwise reach.
//
//  Ownership is tracked separately (`zmqol_nb_owns_ignore`) so this copy can
//  tell its own flag from one another script set, and so turning the row off
//  mid-match puts the zombie back exactly where stock had it.
//  ----------------------------------------------------------------------------
//  ----------------------------------------------------------------------------
//  zmqol_nb_watch_death_once / zmqol_nb_death_watch  -  ATTRIBUTION   (v2.14.6)
//
//  Second report, 2026-09-06, Origins round 2 with the row ON: the last zombie
//  was knifed once at a barrier, the player ran to generator 2, and it died on
//  its own. This time the log PROVED both hooks were live -
//      [zm_qol] no_bleedout: shared failsafe hook LIVE on zm_tomb - row=1
//      [zm_qol] no_bleedout: Origins 15s failsafe REPLACEMENT is live - row=1
//  - and printed no SUPPRESSED and no BELOW-WORLD line. So the kill came from
//  neither timer, and guessing which of Origins' other killers it was would be
//  exactly the thing this project does not do.
//
//  🌟 IT ALSO SETTLED AN OPEN QUESTION. The "REPLACEMENT is live" line is proof
//  that a Plutonium replaceFunc DOES reach a call made through a stored function
//  pointer, at least when the pointer is captured after the replace:
//  level._zombies_round_spawn_failsafe holds ::tomb_round_spawn_failsafe and the
//  mod's copy is what ran. STOCK_REFERENCE 7a modes 2-3 are narrower than they
//  read.
//
//  So this watcher names the killer instead. One line per zombie that dies with
//  no player attacker while the row is on - what killed it, the means of death,
//  the weapon, and whether the giant robot's foot had marked it.
//  ----------------------------------------------------------------------------
zmqol_nb_watch_death_once()
{
    //  🛑 v2.14.10 - NOTHING RUNS WITH THE ROW OFF, and the row is off by
    //  default. Two threads and a 4 Hz poll per zombie is cheap but it is not
    //  free, and with no_bleedout 0 they would only ever have measured a feature
    //  that is not switched on. The shared failsafe calls this again on every
    //  pass, so a zombie that was already alive when the row is turned on picks
    //  its watcher up within one pass (30s, or 15s on Origins and Mob) - and the
    //  call is idempotent, so calling it repeatedly costs one isdefined test.
    if ( !getdvarintdefault( "no_bleedout", 0 ) )
        return;

    if ( isdefined( self.zmqol_nb_watching ) )
        return;

    self.zmqol_nb_watching = 1;

    //  Two threads, and they do not overlap. The notify one has the attacker the
    //  engine hands to "death" and owns every KILL; the polled one owns the case
    //  a notify cannot describe - the entity being DELETED, after which every
    //  field on it reads undefined.
    self thread zmqol_nb_death_notify();
    self thread zmqol_nb_death_watch();
    self thread zmqol_nb_stock_delete_watch();
}

zmqol_nb_death_watch()
{
    //  🛑 v2.14.7 - POLLED, NOT `waittill( "death" )`, AND THE STATE IS KEPT IN
    //  THREAD LOCALS. v2.14.6's version answered the Origins report with
    //      DEATH WITH NO PLAYER ATTACKER - by=undefined mod=? weapon=?
    //  nine times in one round, and that shape is itself the finding: every
    //  field came back undefined because THE ENTITY WAS ALREADY GONE. A deleted
    //  entity keeps nothing, so anything read after the fact reads undefined and
    //  a silent deletion cannot be told apart from a damage-less kill.
    //
    //  So the loop caches what matters one second at a time, and the two exits
    //  are different findings:
    //      !isdefined( self )  ->  DELETED. Nothing killed it; it was removed.
    //      !isalive( self )    ->  killed, and self.attacker names by what.
    //
    //  🛑 v2.14.19 - STANDS DOWN WHEN STOCK IS THE DELETER. Every map's
    //  <map>_distance_tracking.gsc removes a zombie no player can see or reach,
    //  and it does its own bookkeeping first (`level.zombie_total++`, the same
    //  put-back this file's requeue does), THEN `self notify( "zombie_delete" )`,
    //  THEN `self delete()` - read at zm_tomb_distance_tracking.gsc:109-152 and
    //  identical in shape on Buried, Die Rise, Mob and TranZit. This thread used
    //  to see only the deletion and put the zombie back a SECOND time: the
    //  2026-09-08 6:47 AM Origins log had 127 VANISHED lines in round 1, 24 of
    //  them requeued on top of stock's own 24, and the round never ended. So the
    //  notify ends this thread, and zmqol_nb_stock_delete_watch() owns that case.
    //
    //  🌟 v2.14.22 - MEASURED WORKING. The 8:14 AM Origins log (v2.14.19, Crazy
    //  Place, rounds 1-5): five stock deletions, ZERO VANISHED lines, ZERO
    //  "(deleted)" put-backs. The endon does its job. What that log also proved
    //  is that T6 does NOT run a notify's waiting threads inline - every one of
    //  the five woke zmqol_nb_stock_delete_watch() AFTER `self delete()` had run
    //  (its old "seen AFTER" line, five for five). The endon still protects
    //  because a pending kill is honoured the moment this thread is next
    //  scheduled, before its poll body runs. So the snapshot this loop keeps is
    //  ALSO written to level.zmqol_nb_last[entnum] each tick: the delete watcher
    //  cannot read a gone entity, but it can read that.
    self endon( "zombie_delete" );

    n_ent = self getentitynumber();

    if ( !isdefined( level.zmqol_nb_last ) )
        level.zmqol_nb_last = [];

    str_zone  = "?";
    n_x = 0;
    n_y = 0;
    n_z = 0;
    n_hp = 0;
    b_dmg = 0;
    b_emerged = 0;
    b_recycle = 0;

    for ( ;; )
    {
        if ( !isdefined( self ) )
        {
            if ( getdvarintdefault( "no_bleedout", 0 ) )
            {
                println( "[zm_qol] no_bleedout: ZOMBIE VANISHED - deleted, never killed - zone=" + str_zone + " at (" + n_x + "," + n_y + "," + n_z + ") hp=" + n_hp + " player_damaged=" + b_dmg + " emerged=" + b_emerged + " round=" + level.round_number + " left=" + get_current_zombie_count() );

                if ( !b_recycle )
                    zmqol_nb_requeue( "deleted" );
            }

            level.zmqol_nb_last[n_ent] = undefined;
            return;
        }

        //  Killed - zmqol_nb_death_notify() owns that, with the real attacker.
        if ( !isalive( self ) )
        {
            level.zmqol_nb_last[n_ent] = undefined;
            return;
        }

        if ( isdefined( self.zone_name ) )
            str_zone = self.zone_name;

        n_x = int( self.origin[0] );
        n_y = int( self.origin[1] );
        n_z = int( self.origin[2] );
        n_hp = self.health;
        b_dmg = is_true( self.has_been_damaged_by_player );
        b_emerged = is_true( self.completed_emerging_into_playable_area );
        b_recycle = is_true( self.marked_for_recycle );

        //  v2.14.22 - the same snapshot, readable after the entity is gone.
        //  One struct per zombie, fields overwritten in place, cleared on every
        //  exit of this thread and by the delete watcher; an entity number that
        //  is reused simply gets overwritten by its next watcher.
        s_last = level.zmqol_nb_last[n_ent];

        if ( !isdefined( s_last ) )
        {
            s_last = spawnstruct();
            level.zmqol_nb_last[n_ent] = s_last;
        }

        s_last.zone = str_zone;
        s_last.hp = n_hp;
        s_last.maxhp = self.maxhealth;
        s_last.dmg = b_dmg;

        //  0.25s, and the number is load-bearing: _zm.gsc:3724's round-end test
        //  polls once a SECOND, so a quarter-second detection window means the
        //  replacement below is in the queue before the round can decide it is
        //  over. A one-second poll would lose that race about as often as it won.
        wait 0.25;
    }
}

//  ----------------------------------------------------------------------------
//  zmqol_nb_stock_delete_watch  -  STOCK ALREADY PAID THIS ONE BACK   (v2.14.19)
//
//  The distance trackers are the second stock system found to be self-balancing
//  (the first was the playspace timeout, _zm.gsc:3666). Their deleter runs
//      level.zombie_total++      (unless excluded, screecher, or the endgame
//                                 rule below says no)
//      self notify( "zombie_delete" )
//      self delete()
//  with no wait between the three, so at the notify the entity is still whole
//  and stock's decision is already made. Whatever it decided, the mod does not
//  second-guess it: stock pays back a full-health zombie and any zombie while
//  more than 24 remain, and deliberately DROPS a player-damaged one when 24 or
//  fewer remain (`zombies.size + level.zombie_total <= 24 && health < maxhealth`)
//  - that endgame trim is vanilla on every map and is left exactly as vanilla.
//
//  🛑 v2.14.22 - THE v2.14.19 ASSUMPTION WAS WRONG, AND THE GUARD STILL HELD.
//  v2.14.19 assumed a GSC notify runs its waiting threads before returning to
//  the notifier, and printed a "seen AFTER ... NOT protecting" line if not.
//  The 8:14 AM Origins log printed that line five times out of five - T6 wakes
//  waiting threads only when the notifier next yields, by which time
//  `self delete()` has run - and the SAME log has zero VANISHED lines and zero
//  "(deleted)" put-backs across those five deletions. So the wording was wrong
//  on both counts: the wake-up is deferred BY DESIGN, and the endon on the
//  polling thread protects regardless, because a pending kill is honoured when
//  that thread is next scheduled, before its poll body. This function's job
//  is therefore the log line and the Die Rise flag, not the guard itself.
//
//  What it reads: the entity if it still exists (Die Rise's off-building path
//  KILLS with dodamage after the notify, zm_highrise_distance_tracking.gsc:383,
//  and Origins' mechz path waits a network frame before deleting - both leave
//  the entity whole at wake-up), otherwise the snapshot the polling thread
//  keeps in level.zmqol_nb_last[entnum] - captured BEFORE the wait, since
//  getentitynumber() cannot be asked of a gone entity.
//
//  Die Rise: the notify is followed by dodamage, so both this thread and
//  zmqol_nb_death_notify() have a pending wake-up in that order. This one sets
//  zmqol_nb_counted first; and since v2.14.22 the kill watcher ALSO carries
//  endon( "zombie_delete" ), so whichever the VM services first, stock's own
//  put-back (zombie_total++ before the notify, same rule as the deleters) is
//  never doubled. The ≤24-and-damaged trim stays vanilla, as everywhere.
//  ----------------------------------------------------------------------------
zmqol_nb_stock_delete_watch()
{
    n_ent = self getentitynumber();

    self waittill( "zombie_delete" );

    str_zone = "?";
    str_hp = "?";
    str_dmg = "?";
    str_how = "entity gone at wake-up (deleted inline, as T6 does)";

    if ( isdefined( self ) )
    {
        self.zmqol_nb_counted = 1;
        str_how = "entity still whole at wake-up (dodamage / mechz path)";

        if ( isdefined( self.zone_name ) )
            str_zone = self.zone_name;

        str_hp = self.health + "/" + self.maxhealth;
        str_dmg = "" + is_true( self.has_been_damaged_by_player );
    }
    else if ( isdefined( level.zmqol_nb_last ) && isdefined( level.zmqol_nb_last[n_ent] ) )
    {
        s_last = level.zmqol_nb_last[n_ent];
        str_zone = s_last.zone;
        str_hp = s_last.hp + "/" + s_last.maxhp;
        str_dmg = "" + s_last.dmg;
    }

    if ( isdefined( level.zmqol_nb_last ) )
        level.zmqol_nb_last[n_ent] = undefined;

    if ( !getdvarintdefault( "no_bleedout", 0 ) )
        return;

    a_ai = getaiarray( "axis" );

    println( "[zm_qol] no_bleedout: REMOVED BY STOCK distance cleanup - stock counted it back itself, nothing owed - " + str_how + " - zone=" + str_zone + " hp=" + str_hp + " player_damaged=" + str_dmg + " ai=" + a_ai.size + " zombie_total=" + level.zombie_total + " round=" + level.round_number );
}

//  The KILL path, unchanged from v2.14.6 except for the requeue at the end: the
//  attacker comes from the "death" notify itself, which the 2026-09-06 log
//  proved carries it (a whole round of player kills stayed silent, and only nine
//  attacker-less deaths printed).
zmqol_nb_death_notify()
{
    //  v2.14.22 - a zombie stock has just announced it is removing is stock's
    //  to account for, whether it deletes it (every distance tracker) or kills
    //  it a line later (Die Rise's off-building trigger). See the note above
    //  zmqol_nb_stock_delete_watch().
    self endon( "zombie_delete" );

    self waittill( "death", e_attacker );

    //  Deleted rather than killed - the polled watcher owns that case and is the
    //  only one of the two with the state to describe it.
    if ( !isdefined( self ) )
        return;

    if ( !getdvarintdefault( "no_bleedout", 0 ) )
        return;

    //  A player kill is the whole point of the feature - say nothing, count
    //  nothing.
    if ( isdefined( e_attacker ) && isplayer( e_attacker ) )
        return;

    str_who = "undefined";

    if ( isdefined( e_attacker ) )
    {
        str_who = "entity";

        if ( isdefined( e_attacker.classname ) )
            str_who = e_attacker.classname;

        if ( isdefined( e_attacker.targetname ) )
            str_who = str_who + "/" + e_attacker.targetname;

        if ( isdefined( e_attacker.model ) )
            str_who = str_who + "/" + e_attacker.model;
    }

    str_mod = "?";

    if ( isdefined( self.damagemod ) )
        str_mod = self.damagemod;

    str_weap = "?";

    if ( isdefined( self.damageweapon ) )
        str_weap = self.damageweapon;

    str_zone = "?";

    if ( isdefined( self.zone_name ) )
        str_zone = self.zone_name;

    println( "[zm_qol] no_bleedout: DEATH WITH NO PLAYER ATTACKER - by=" + str_who + " mod=" + str_mod + " weapon=" + str_weap + " robot_marked=" + is_true( self.marked_for_death ) + " zone=" + str_zone + " player_damaged=" + is_true( self.has_been_damaged_by_player ) + " round=" + level.round_number + " left=" + get_current_zombie_count() );

    //  Stock already puts a recycled zombie back itself (_zm_spawner.gsc:2216),
    //  and this mod's own below-world branches do the same where the level flag
    //  asks for it - neither is counted twice.
    if ( is_true( self.marked_for_recycle ) || is_true( self.zmqol_nb_counted ) )
        return;

    //  🛑 v2.14.20 - A NUKED ZOMBIE IS A KILL, NOT A VANISHING. User, 2026-09-08,
    //  Crazy Place survival: *"just got a nuke ... and it didn't kill the last
    //  zombie so i think the no bleedout patch is interferring with the nuke
    //  power up"*. The 8:14 AM log shows exactly that: a Nuke at round 4 with
    //  one zombie left printed
    //      DEATH WITH NO PLAYER ATTACKER - by=worldspawn/ mod=MOD_UNKNOWN
    //          weapon=none robot_marked=1 ... round=4 left=0
    //      one owed back to the round (killed by worldspawn/) - zombie_total now 1
    //  and a .nuke at round 5 did it four times (zombie_total 20 -> 23). So the
    //  Nuke DID kill the last zombie; this file then handed the round a
    //  replacement, which is the zombie the user saw.
    //
    //  Stock's Nuke (_zm_powerups.gsc:1445-1500, nuke_powerup) sets
    //  `marked_for_death = 1` and `nuked = 1` on every zombie it claims, then
    //  kills each with a bare `dodamage( health + 666, origin )` - no attacker,
    //  so the "death" notify carries worldspawn and zmqol_nb_no_killer() below
    //  reads it as "nothing killed it". `marked_for_death` is stock's own
    //  "a killer has claimed this zombie" flag: the Nuke, _zm_traps.gsc:576's
    //  zombie_trap_death and Mob's trap kills all set it before their equally
    //  attacker-less dodamage, and the robot stomp sets it too (suppressed
    //  elsewhere). None of those is a free zombie - the player earned every one.
    //
    //  📝 Not covered, on purpose: TranZit's diner hatch (zm_transit_classic
    //  .gsc:380-383) sets the flag AFTER its dodamage and then does its own
    //  `level.zombie_total++`, so whether this gate catches it depends on notify
    //  timing. It is a one-zombie case and stock pays it back itself either way.
    if ( is_true( self.nuked ) || is_true( self.marked_for_death ) )
    {
        println( "[zm_qol] no_bleedout: claimed by a stock killer (nuked=" + is_true( self.nuked ) + " marked_for_death=" + is_true( self.marked_for_death ) + ") - a kill, nothing owed" );
        return;
    }

    //  ========================================================================
    //  🛑 v2.14.10 - A NAMED ATTACKER IS NOT A FREE ZOMBIE, and putting one
    //  back for every attacker-less-looking kill was going to break traps.
    //
    //  The line above this one logs EVERY kill with no player attacker, and that
    //  is right - it is the instrument. But the round is only owed a zombie when
    //  NOTHING killed it. Every one of these is a real killer with a real entity
    //  behind it, and each was read out of the stock dump rather than assumed:
    //
    //    trap kills            _zm_traps.gsc:625,642     attacker = the trap ent
    //    TranZit lava          zm_transit_lava.gsc:285   attacker = the trap ent
    //    Origins robot stomp   zm_tomb_giant_robot:933   attacker = the robot
    //                          (and it is suppressed outright on this row now)
    //    grief / module clears _zm_game_module.gsc:105   attacker = the zombie
    //                          _zm_gametype.gsc:1777      itself, MOD_SUICIDE
    //    burning zombies       _zm_spawner.gsc:1877      attacker = player, or
    //                          `level` once that player is gone
    //
    //  A trap is the player's own doing - they bought it and lured the horde in.
    //  Handing the round a replacement for every trap kill would make traps stop
    //  clearing rounds at all on Mob of the Dead and TranZit, which is a bigger
    //  bug than the one this row is fixing.
    //
    //  So only two shapes are owed back: the zombie was DELETED (the polled
    //  watcher's branch, the reported case), or it was killed with NO attacker
    //  entity at all - which is what a bare `dodamage( health + N, origin )` from
    //  some script looks like, and what an unfound remover would look like.
    //  📝 An attacker-less dodamage surfaces in the "death" notify as
    //  `worldspawn`, not as undefined - that is what the 2026-09-06 log's round-4
    //  burst was - so worldspawn counts as "nothing killed it" here. The one
    //  stock place that does it in bulk, zombie_game_over_death, cannot reach
    //  this code: _zm.gsc:4932 sets level.intermission on its first line and
    //  zmqol_nb_requeue() returns on that.
    //  ========================================================================
    if ( !zmqol_nb_no_killer( e_attacker ) )
        return;

    zmqol_nb_requeue( "killed by " + str_who );
}

// ----------------------------------------------------------------------------
//  zmqol_nb_requeue  -  THE ROUND DOES NOT GET SHORTER FOR FREE     (v2.14.7)
//
//  User's own wording for this row: *"no respawns from nothing, they have to be
//  actually killed by the player"*. Two Origins reports in one evening were a
//  zombie leaving play with nothing having killed it, and the second one ended
//  the round. The cause of the vanishing is still open - see the watcher above,
//  which now names it - but the CONSEQUENCE does not have to wait for that: a
//  zombie that leaves play without a player killing it is owed back to the
//  round.
//
//  🌟 THIS IS STOCK'S OWN MECHANISM, NOT AN INVENTION. `level.zombie_total++`
//  with `level.zombie_total_subtract++` is exactly what _zm.gsc:3666-3667 and
//  _zm_spawner.gsc:2216-2219 do when a zombie times out or is recycled, and it
//  is what `put_timed_out_zombies_back_in_queue` exists for.
//
//  🌟 AND IT CANNOT HANG THE ROUND. _zm.gsc:2962's spawner is `while ( true )`
//  with `while ( count >= ai_limit || zombie_total <= 0 ) wait 0.1;` inside it -
//  it never exits on an empty queue, it idles - so a total bumped at any point
//  in the round produces a real spawn. Read out of the dump before writing this,
//  because the failure mode if it were false is a round that never ends.
//
//  🛑 CAPPED AT 24 PER ROUND. If whatever is removing zombies ever removes them
//  as fast as they spawn, an uncapped put-back would be an endless round. At the
//  cap it stops and says so, which is a bad round rather than a dead game.
//  Never touched in a dog round, in intermission, or with the row off.
// ----------------------------------------------------------------------------
//  Is there an entity behind this kill? `undefined` and `worldspawn` both mean
//  no - see the banner in zmqol_nb_death_notify(). Anything else is a trap, a
//  robot, a vehicle or the zombie itself, and those are not owed back.
zmqol_nb_no_killer( e_attacker )
{
    if ( !isdefined( e_attacker ) )
        return true;

    if ( isdefined( e_attacker.classname ) && e_attacker.classname == "worldspawn" )
        return true;

    return false;
}

zmqol_nb_requeue( str_why )
{
    if ( !getdvarintdefault( "no_bleedout", 0 ) )
        return;

    if ( !getdvarintdefault( "no_bleedout_requeue", 1 ) )
        return;

    if ( !isdefined( level.zombie_total ) || is_true( level.intermission ) )
        return;

    if ( level flag_exists( "dog_round" ) && flag( "dog_round" ) )
        return;

    if ( !isdefined( level.zmqol_nb_requeue_round ) || level.zmqol_nb_requeue_round != level.round_number )
    {
        level.zmqol_nb_requeue_round = level.round_number;
        level.zmqol_nb_requeued = 0;
    }

    if ( level.zmqol_nb_requeued >= 24 )
    {
        if ( level.zmqol_nb_requeued == 24 )
        {
            level.zmqol_nb_requeued++;
            println( "[zm_qol] no_bleedout: 24 put back this round already - CAP HIT, letting the rest go. Something is removing zombies in bulk." );
        }

        return;
    }

    level.zmqol_nb_requeued++;
    level.zombie_total++;
    level.zombie_total_subtract++;
    println( "[zm_qol] no_bleedout: one owed back to the round (" + str_why + ") - " + level.zmqol_nb_requeued + " this round, zombie_total now " + level.zombie_total );
}

zmqol_nb_sync_ignore_flag()
{
    if ( getdvarintdefault( "no_bleedout", 0 ) )
    {
        self.ignore_round_spawn_failsafe = 1;
        self.zmqol_nb_owns_ignore = 1;
        return;
    }

    if ( isdefined( self.zmqol_nb_owns_ignore ) )
    {
        self.ignore_round_spawn_failsafe = 0;
        self.zmqol_nb_owns_ignore = undefined;
    }
}

zmqol_round_spawn_failsafe()
{
    self endon( "death" );
    prevorigin = self.origin;

    //  v2.14.5 - AND THE MAP'S OWN COPY OF THIS FUNCTION IS SWITCHED OFF HERE.
    //  See the banner above for why: Origins and Mob of the Dead each thread a
    //  SECOND, unpatched failsafe onto every zombie. Setting stock's own escape
    //  hatch makes that copy return at the top of its next pass.
    self zmqol_nb_sync_ignore_flag();
    self zmqol_nb_watch_death_once();

    if ( !isdefined( level.zmqol_nb_said_shared ) )
    {
        level.zmqol_nb_said_shared = 1;
        println( "[zm_qol] no_bleedout: shared failsafe hook LIVE on " + level.script + " - row=" + getdvarintdefault( "no_bleedout", 0 ) );
    }

    while ( true )
    {
        if ( !level.zombie_vars["zombie_use_failsafe"] )
            return;

        //  🛑 THE ONE ADDED CLAUSE. Stock returns on the flag; this copy must not
        //  return on a flag IT set itself (zmqol_nb_sync_ignore_flag), or the
        //  patch would switch off the only failsafe still running. A flag set by
        //  anything else is still honoured exactly as stock does.
        if ( isdefined( self.ignore_round_spawn_failsafe ) && self.ignore_round_spawn_failsafe && !isdefined( self.zmqol_nb_owns_ignore ) )
            return;

        wait 30;

        //  Re-read the row every pass, so turning it off mid-match hands the
        //  zombie back to stock behaviour and clears the flag with it.
        self zmqol_nb_sync_ignore_flag();
        self zmqol_nb_watch_death_once();

        if ( !self.has_legs )
            wait 10.0;

        if ( isdefined( self.is_inert ) && self.is_inert )
            continue;

        if ( isdefined( self.lastchunk_destroy_time ) )
        {
            if ( gettime() - self.lastchunk_destroy_time < 8000 )
                continue;
        }

        if ( self.origin[2] < level.zombie_vars["below_world_check"] )
        {
            if ( isdefined( level.put_timed_out_zombies_back_in_queue ) && level.put_timed_out_zombies_back_in_queue && !flag( "dog_round" ) && !( isdefined( self.isscreecher ) && self.isscreecher ) )
            {
                level.zombie_total++;
                level.zombie_total_subtract++;
                //  v2.14.7 - stock's put-back already happened here, so
                //  zmqol_nb_requeue() must not count this one a second time.
                self.zmqol_nb_counted = 1;
            }

            println( "[zm_qol] no_bleedout: BELOW-WORLD kill (shared, z=" + int( self.origin[2] ) + ") - kept on purpose, round " + level.round_number );
            self dodamage( self.health + 100, ( 0, 0, 0 ) );
            break;
        }

        if ( distancesquared( self.origin, prevorigin ) < 576 )
        {
            //  🛑 A ZOMBIE NEXT TO A PLAYER IS NOT STRANDED - IT IS ATTACKING.
            //  Runs BEFORE the row test, so it protects the zombie whether
            //  NO BLEEDOUT is on or off. Full reasoning on the helper.
            if ( self scripts\zm\qol_options::zmqol_nb_near_player() )
            {
                prevorigin = self.origin;
                continue;
            }

            //  🛑 THE WHOLE PATCH IS THIS ONE TEST. Stock falls straight through
            //  into the kill; with the row on, the zombie is left alive and the
            //  loop simply keeps watching it.
            if ( getdvarintdefault( "no_bleedout", 0 ) )
            {
                //  v2.9.15 - AND THE ROUND MUST STILL BE ABLE TO END. Skipping the
                //  kill and doing nothing else leaves a zombie welded to scenery
                //  for the rest of the match, which is its own softlock. After
                //  five consecutive stuck passes (~2.5 minutes) it is MOVED to a
                //  live spawn point instead - never damaged - so the player can
                //  walk up and kill it. See zmqol_relocate_zombie().
                if ( !isdefined( self.zmqol_nb_stuck ) )
                    self.zmqol_nb_stuck = 0;

                self.zmqol_nb_stuck++;

                if ( !isdefined( self.zmqol_nb_said ) )
                {
                    self.zmqol_nb_said = 1;
                    println( "[zm_qol] no_bleedout: SUPPRESSED playspace-timeout kill, round " + level.round_number );
                }

                if ( self.zmqol_nb_stuck >= 5 && getdvarintdefault( "no_bleedout_relocate", 1 ) && self zmqol_no_bleedout_can_relocate() )
                {
                    if ( self zmqol_relocate_zombie( 0 ) )
                        self.zmqol_nb_stuck = 0;
                }

                prevorigin = self.origin;
                continue;
            }

            if ( isdefined( level.put_timed_out_zombies_back_in_queue ) && level.put_timed_out_zombies_back_in_queue && !flag( "dog_round" ) )
            {
                if ( !self.ignoreall && !( isdefined( self.nuked ) && self.nuked ) && !( isdefined( self.marked_for_death ) && self.marked_for_death ) && !( isdefined( self.isscreecher ) && self.isscreecher ) && ( isdefined( self.has_legs ) && self.has_legs ) )
                {
                    level.zombie_total++;
                    level.zombie_total_subtract++;
                }
            }

            level.zombies_timeout_playspace++;
            self dodamage( self.health + 100, ( 0, 0, 0 ) );
            break;
        }

        prevorigin = self.origin;
        self.zmqol_nb_stuck = 0;
    }
}

// ============================================================================
//  NO BLEEDOUT, PART 2  -  THE SPAWN-TIME KILL              (v2.9.15)
// ----------------------------------------------------------------------------
//  User, 2026-08-31: *"The 'No Bleedout' patch failed during testing (the last
//  zombie on Round 13 despawned/died on its own after ~1 minute of
//  distance/time). Fix the logic so that when 'No Bleedout' is enabled, zombies
//  (especially the final zombie of a round) never automatically bleed out or
//  self-destruct regardless of distance or time elapsed."*
//
//  🛑 v2.2.0 PATCHED ONE OF THE TWO AUTOMATIC KILLS, NOT BOTH. That is the
//  defect. Every script-side automatic zombie death in the whole 2,093-file
//  stock dump was enumerated for this fix - `dodamage( self.health` across the
//  entire tree, then every zombie_history() string naming a kill - and exactly
//  TWO of them fire on a timer:
//
//    1. _zm.gsc:3635  round_spawn_failsafe()   30s of not moving -> kill.
//                     Patched since v2.2.0, above.
//    2. _zm_spawner.gsc:548  zombie_assure_node()   the zombie could not path to
//                     ANY entrance node -> `wait 20` -> dodamage( health + 10 ).
//                     🛑 NEVER PATCHED. This is the one that was missed.
//
//  🌟 AND ITS TIMING IS THE USER'S "~1 MINUTE", read off the stock body
//  rather than estimated: zombie_bad_path() blocks up to 2s per candidate node,
//  the function walks the entrance-node list, then `wait 2`, then re-picks the
//  20 closest exterior_goals and walks those too, then `wait 20` before the
//  kill. Twenty bad candidates at 2s plus the two fixed waits is ~62 seconds.
//  round_spawn_failsafe's clock is a flat 30s and cannot produce that number.
//
//  🛑 AND "JUST DO NOT KILL IT" IS NOT A FIX HERE. Stock kills this zombie
//  because it is stranded with no path to anywhere; leaving it alive would end
//  the round FOREVER, which is a worse bug than the one being fixed and exactly
//  the reason the v2.2.0 banner gave for keeping the below-world kill. So with
//  the row on, this mod MOVES the zombie to a live spawn point instead of
//  damaging it. It is never killed, and it becomes reachable - which is what the
//  request actually asks for ("the player would have to actually kill the
//  zombies themself").
//
//  📝 The body below is stock's, verbatim, except that:
//    - the two /# #/ println blocks and the zombie_history() /
//      draw_line_ent_to_pos() calls are dropped. Both of those functions have
//      their ENTIRE bodies inside /# #/ (_zm_spawner.gsc:2602,
//      _zm_utility.gsc:2551), so in retail they do nothing at all.
//    - `start_pos` is dropped; stock assigns it and never reads it.
//    - zombie_bad_path() is called fully qualified, because this file is not
//      _zm_spawner.gsc.
//
//  Recovery with no rebuild, if the relocation ever misbehaves:
//      no_bleedout_relocate 0     suppress the kill but never move anything
//      no_bleedout 0              back to stock entirely
// ============================================================================
zmqol_zombie_assure_node()
{
    self endon( "death" );
    self endon( "goal" );
    level endon( "intermission" );

    //  🛑 v2.17.25 - A ZOMBIE STANDING NEXT TO A PLAYER IS IN PLAY. LEAVE IT.
    //
    //  This is the SAME misreading as the failsafe cull, and it does more damage
    //  because it does not kill the zombie - it RETARGETS it. zombie_bad_path()
    //  means "has not moved for a second", and a zombie that has stopped to
    //  swing at a player has not moved. stock's answer is
    //      self setgoalpos( self.entrance_nodes[i].origin );
    //  which sends it back to a SPAWN ENTRANCE. From the player's side that is a
    //  zombie that walks up, refuses to attack, turns round and wanders off to a
    //  fixed spot - and then dies to one of the timeout culls out there.
    //
    //  User, 2026-09-16: *"some zombies will behave normally and attack me and
    //  some other zombies will just refuse to accept that I'm even there and
    //  they'll just won't even attack me and then they'll just disappear."*
    //  Per zombie, intermittent, because it only catches the ones that happen to
    //  pause within the sample window.
    //
    //  A zombie within 256 units of a living player has demonstrably pathed into
    //  the playable area, so it needs no entrance node assured at all - this
    //  whole thread is done. If it is genuinely wedged on scenery there, it is
    //  next to the player and can simply be shot, so no round can lock up.
    if ( self scripts\zm\qol_options::zmqol_nb_near_player() )
        return;

    if ( isdefined( self.entrance_nodes ) )
    {
        for ( i = 0; i < self.entrance_nodes.size; i++ )
        {
            if ( self maps\mp\zombies\_zm_spawner::zombie_bad_path() )
            {
                if ( self scripts\zm\qol_options::zmqol_nb_near_player() )
                    return;

                self.first_node = self.entrance_nodes[i];
                self setgoalpos( self.entrance_nodes[i].origin );
                continue;
            }

            return;
        }
    }

    wait 2;
    nodes = get_array_of_closest( self.origin, level.exterior_goals, undefined, 20 );

    if ( isdefined( nodes ) )
    {
        self.entrance_nodes = nodes;

        for ( i = 0; i < self.entrance_nodes.size; i++ )
        {
            if ( self maps\mp\zombies\_zm_spawner::zombie_bad_path() )
            {
                //  Same guard as the first loop. See the banner above.
                if ( self scripts\zm\qol_options::zmqol_nb_near_player() )
                    return;

                self.first_node = self.entrance_nodes[i];
                self setgoalpos( self.entrance_nodes[i].origin );
                continue;
            }

            return;
        }
    }

    wait 20;

    //  🛑 THE PATCH. Stock's next two lines are the kill and the counter.
    if ( getdvarintdefault( "no_bleedout", 0 ) )
    {
        println( "[zm_qol] no_bleedout: SUPPRESSED assure_node kill, round " + level.round_number );

        if ( getdvarintdefault( "no_bleedout_relocate", 1 ) )
            self thread zmqol_no_bleedout_rescue();

        return;
    }

    self dodamage( self.health + 10, self.origin );
    level.zombies_timeout_spawn++;
}

// ----------------------------------------------------------------------------
//  Keeps moving a stranded zombie to a live spawn point until it finally gets a
//  path. `endon( "goal" )` is what stops it: the moment the zombie reaches an
//  entrance node the thread is gone, so this costs nothing once the zombie is in
//  play. It never damages anything.
// ----------------------------------------------------------------------------
zmqol_no_bleedout_rescue()
{
    self endon( "death" );
    self endon( "goal" );
    level endon( "intermission" );

    for ( ;; )
    {
        if ( !self zmqol_no_bleedout_can_relocate() )
            return;

        self zmqol_relocate_zombie( 1 );
        wait 20;
    }
}

// ----------------------------------------------------------------------------
//  🛑 WHAT MUST NEVER BE TELEPORTED. Every entry is a state where the zombie
//  is mid-script and moving it would break the map rather than help it:
//    - magic bullet shield  = stock's own marker for scripted and boss zombies
//      (the Origins panzer, Mob's brutus, the Die Rise elevator scripts). This
//      mod already skips them for the nuke and for zmqol_kill_horde(); this
//      brings the rescue into line with both.
//    - in_the_ground / in_the_ceiling  = Buried and Die Rise rise-from and
//      drop-from animations, which own the zombie's position outright. Taken
//      from BO2-Reimagined's own round_spawn_failsafe rewrite, which guards on
//      exactly these two.
//    - is_inert  = a zombie parked on purpose by a map script.
//    - isscreecher  = TranZit's denizens, which attach themselves to a player.
//  Anything in this list is simply left alone. Stock's kill is skipped for it
//  too, so nothing here can be killed by the patch either.
// ----------------------------------------------------------------------------
zmqol_no_bleedout_can_relocate()
{
    if ( !isdefined( self ) || !isalive( self ) )
        return false;

    if ( is_magic_bullet_shield_enabled( self ) )
        return false;

    if ( isdefined( self.is_brutus ) && self.is_brutus )
        return false;

    if ( isdefined( self.in_the_ground ) && self.in_the_ground )
        return false;

    if ( isdefined( self.in_the_ceiling ) && self.in_the_ceiling )
        return false;

    if ( isdefined( self.is_inert ) && self.is_inert )
        return false;

    if ( isdefined( self.isscreecher ) && self.isscreecher )
        return false;

    return true;
}

// ----------------------------------------------------------------------------
//  🌟 level.zombie_spawn_locations IS THE RIGHT ARRAY, AND IT IS NOT A GUESS.
//  It is the exact array stock's own round_spawning() draws from every time it
//  spawns a zombie (_zm.gsc:2977), and the zone manager keeps it to the spots
//  inside currently ACTIVE zones - so a spot taken from it is, by construction,
//  somewhere the game was about to spawn a zombie anyway, near the players.
//
//  forceteleport() on an AI is stock's own move: _zm_utility::spawn_zombie does
//  `guy forceteleport( spawner.origin )` for every zombie the game creates, and
//  _zm_spawner::taunt_notetracks does it on a live one.
//
//  b_reassign_entrance:
//     1  the zombie never got into the map - re-derive its entrance node from
//        the new position, using the same two lines stock's own assure_node
//        retry uses.
//     0  the zombie is already in play and find_flesh() owns its goal, so do not
//        touch it; it re-paths to a player on its own.
// ----------------------------------------------------------------------------
zmqol_relocate_zombie( b_reassign_entrance )
{
    if ( !isdefined( level.zombie_spawn_locations ) || level.zombie_spawn_locations.size == 0 )
        return false;

    s_spot = level.zombie_spawn_locations[ randomint( level.zombie_spawn_locations.size ) ];

    if ( !isdefined( s_spot ) || !isdefined( s_spot.origin ) )
        return false;

    self forceteleport( s_spot.origin );

    // ------------------------------------------------------------------
    //  🛑 v2.17.24 - THE GOAL IS NOW ALWAYS RE-ESTABLISHED. THIS WAS THE
    //  "ZOMBIES WALK INTO ME AND DO NOT ATTACK" BUG.
    //
    //  User, 2026-09-15: *"some of the zombies were attacking me like normally
    //  but then other zombies ... they were just like walk into me and they
    //  would be pushing me literally pushing me, but they weren't attacking me
    //  ... something in my mod is breaking the zombie ai to make it stop
    //  targeting me."* Right on every count, including that it is the mod.
    //
    //  forceteleport() moves the actor. It does NOT move the actor's GOAL.
    //  A zombie relocated with b_reassign_entrance 0 - which is what
    //  zmqol_round_spawn_failsafe passes, and it is the common path, firing on
    //  any zombie stuck for 5 ticks - kept the goalpos and entrance_nodes it
    //  had before the teleport. So it woke up somewhere new still trying to
    //  reach a node that is now nowhere near it.
    //
    //  Such a zombie still walks and still collides, so it closes on the player
    //  and shoves them, but its pathing state and its position disagree and it
    //  never enters the melee behaviour. Per zombie, intermittent, and only the
    //  ones that happened to get stuck first - which is exactly the reported
    //  shape: SOME zombies attack normally, others just push.
    //
    //  📝 This is the same rule as "never moveto an AI actor": actors own their
    //  own movement, and anything that repositions one owes it a fresh goal in
    //  the same breath. The b_reassign_entrance 1 path already did this, which
    //  is why the rescue path never showed the bug and the failsafe path did.
    //
    //  b_reassign_entrance now means only "also replace the entrance_nodes
    //  LIST". Setting a goal is unconditional, because there is no case where
    //  teleporting an actor and leaving its old goal is correct.
    // ------------------------------------------------------------------
    //  🛑 v2.17.24 - REVERTED TO THE b_reassign_entrance GUARD. An attempt to
    //  make this unconditional is what "walking away to set locations" appeared
    //  right after: nodes here are level.exterior_goals, i.e. ENTRANCE nodes, so
    //  re-issuing the goal unconditionally sent every relocated zombie off to a
    //  spawn entrance instead of back at the player. That is stock's flow for a
    //  zombie that has just spawned and is wrong for one already in play.
    //  It was shipped on a theory and never proven; it is out.
    if ( isdefined( b_reassign_entrance ) && b_reassign_entrance && isdefined( level.exterior_goals ) )
    {
        nodes = get_array_of_closest( self.origin, level.exterior_goals, undefined, 3 );

        if ( isdefined( nodes ) && nodes.size > 0 )
        {
            self.entrance_nodes = nodes;
            self.first_node = nodes[0];
            self setgoalpos( nodes[0].origin );
        }
    }

    println( "[zm_qol] no_bleedout: MOVED a stranded zombie to (" + int( s_spot.origin[0] ) + "," + int( s_spot.origin[1] ) + "," + int( s_spot.origin[2] ) + ") and re-issued its goal" );
    return true;
}

// ============================================================================
//  BETTER SPEED COLA  -  boards go up twice as fast          (v2.2.0)
// ----------------------------------------------------------------------------
//  User, 2026-08-21: *"make speed cola, like black ops 1 zombies, make speed
//  cola make the animations for rebuilding barriers twice as fast put a toggle
//  for it in the GAME tab called BETTER SPEED COLA right under the BETTER
//  DEADSHOT option."*
//
//  🌟 TREYARCH WROTE THIS FEATURE AND A TYPO SWITCHED IT OFF. Measured out of
//  the stock dump, not inferred:
//        _zm_blockers::has_blocker_affecting_perk()   returns the string
//              "specialty_fastreload"
//        _zm_blockers::replace_chunk()                tests it against
//              "speciality_fastreload"      <- an extra i
//  The comparison can never be true, so `scalar` stays 1.0 and Speed Cola has
//  never sped up boarding in retail BO2. Same class of shipped misspelling as
//  the LUI `beingAnimation` one this project already had to work around.
//  Treyarch's own dormant values are 0.31 for the perk and 0.2112 for its
//  upgrade - i.e. THEY intended 3.2x, not 2x.
//
//  🛑 THE ROW USES 2x, NOT TREYARCH'S 3.2x, BECAUSE THE USER GAVE A NUMBER.
//  "twice as fast" is an instruction, so scalar 0.5 is what ships. Stock's own
//  numbers are recorded here so the choice can be revisited in one line.
//
//  🛑 IT TAKES TWO FUNCTIONS, AND ONLY DOING replace_chunk WOULD BE A HALF FIX.
//  Repairing one board is the closing ANIMATION plus a fixed one-second pause
//  between boards - do_post_chunk_repair_delay(). That function ALREADY takes
//  has_perk as an argument and then ignores it, which is the same dormant hook
//  from the same author. Halving only the animation would leave the flat second
//  in place and the boards would not be anywhere near twice as fast.
//
//  📝 has_blocker_affecting_perk() is NOT replaced. It returns the correct
//  string already; the bug is on the reading side.
//  📝 Both bodies below are stock's, verbatim, with the marked lines changed.
//  📝 specialty_fastreload_upgrade is unreachable in retail - nothing ever
//  returns it from has_blocker_affecting_perk() - but its branch is kept and
//  scaled the same way so a future caller cannot fall back to 1.0.
// ============================================================================
zmqol_speed_cola_scalar()
{
    //  0.5 = "twice as fast", the number the user asked for.
    //  Stock's dormant intent was 0.31; see the banner.
    return 0.5;
}

zmqol_replace_chunk( barrier, chunk, perk, upgrade, via_powerup )
{
    //  ========================================================================
    //  🛑 THE PAUSE BETWEEN BOARDS IS SET HERE, THROUGH STOCK'S OWN FIELD, AND
    //  NOT BY THE replaceFunc ON do_post_chunk_repair_delay.
    //
    //  That function is called `self do_post_chunk_repair_delay( has_perk )` -
    //  same file, unqualified, and SYNCHRONOUS - which is precisely the shape
    //  this project does not bet on a replaceFunc reaching. Its body is
    //        if ( !self script_delay() ) wait 1;
    //  and _zm_utility::script_delay() waits `self.script_delay` and returns
    //  true when that field exists. `self` there is the BARRIER, the same entity
    //  passed in here as `barrier`. So writing the field makes STOCK'S OWN
    //  UNMODIFIED CODE wait 0.5 instead of 1, whether or not the replaceFunc
    //  took. Both routes land on the same number, so they cannot disagree.
    //
    //  🌟 THIS RUNS BEFORE THE DELAY, DETERMINISTICALLY. The caller does
    //  `self thread replace_chunk( ... )` and GSC runs a threaded call
    //  immediately up to its first wait - which here is the animation wait at
    //  the bottom - so the field is written before the caller reaches
    //  do_post_chunk_repair_delay in the same iteration.
    //
    //  🛑 THE MAPPER'S OWN VALUE IS SAVED AND PUT BACK. script_delay is a stock
    //  mapents key; a barrier that shipped with one keeps it the moment the row
    //  is off or the player has no Speed Cola.
    //  ========================================================================
    if ( isdefined( barrier ) )
    {
        if ( !isdefined( barrier.zmqol_sd_saved ) )
        {
            barrier.zmqol_sd_saved = 1;
            barrier.zmqol_sd_had = isdefined( barrier.script_delay );

            if ( barrier.zmqol_sd_had )
                barrier.zmqol_sd_orig = barrier.script_delay;
        }

        if ( isdefined( perk ) && getdvarintdefault( "better_speed_cola", 0 ) )
            barrier.script_delay = zmqol_speed_cola_scalar();
        else if ( barrier.zmqol_sd_had )
            barrier.script_delay = barrier.zmqol_sd_orig;
        else
            barrier.script_delay = undefined;
    }

    if ( !isdefined( barrier.zbarrier ) )
    {
        chunk update_states( "mid_repair" );
        sound = "rebuild_barrier_hover";

        if ( isdefined( chunk.script_presound ) )
            sound = chunk.script_presound;
    }

    has_perk = 0;

    if ( isdefined( perk ) )
        has_perk = 1;

    if ( !isdefined( via_powerup ) && isdefined( sound ) )
        play_sound_at_pos( sound, chunk.origin );

    if ( upgrade )
    {
        barrier.zbarrier zbarrierpieceuseupgradedmodel( chunk );
        barrier.zbarrier.chunk_health[chunk] = barrier.zbarrier getupgradedpiecenumlives( chunk );
    }
    else
    {
        barrier.zbarrier zbarrierpieceusedefaultmodel( chunk );
        barrier.zbarrier.chunk_health[chunk] = 0;
    }

    scalar = 1.0;

    if ( has_perk && getdvarintdefault( "better_speed_cola", 0 ) )
    {
        //  🛑 "specialty_fastreload", spelled correctly. Stock's own line here
        //  reads "speciality_fastreload" and therefore never matches.
        if ( perk == "specialty_fastreload" || perk == "speciality_fastreload" )
            scalar = zmqol_speed_cola_scalar();
        else if ( perk == "specialty_fastreload_upgrade" || perk == "speciality_fastreload_upgrade" )
            scalar = zmqol_speed_cola_scalar();
    }

    barrier.zbarrier showzbarrierpiece( chunk );
    barrier.zbarrier setzbarrierpiecestate( chunk, "closing", scalar );
    waitduration = barrier.zbarrier getzbarrierpieceanimlengthforstate( chunk, "closing", scalar );
    wait( waitduration );
}

zmqol_do_post_chunk_repair_delay( has_perk )
{
    if ( self script_delay() )
        return;

    //  has_perk is stock's own argument, which stock then never reads. It is
    //  the perk STRING (or undefined), not a boolean - see
    //  has_blocker_affecting_perk() - so isdefined() is the test.
    if ( isdefined( has_perk ) && getdvarintdefault( "better_speed_cola", 0 ) )
    {
        wait 0.5;
        return;
    }

    wait 1;
}

// ============================================================================
//  BETTER SPEED COLA, part two  -  perk bottles go down faster     (v2.14.15)
// ----------------------------------------------------------------------------
//  User, 2026-09-08: *"make it so that having speed cola also makes players
//  drink perk bottles faster."*  Same row, same dvar, same 2x.
//
//  🌟 WHAT A DRINK IS, MEASURED. _zm_perks::perk_give_bottle_begin() gives the
//  bottle weapon and switchtoweapon()s it; the drinking animation IS that
//  weapon's raise - zombie_perk_bottle_sleight dumped out of zm_transit.ff:
//  raiseAnim viewmodel_zombie_perksacola_drink, raiseTime 2.1, firstRaiseTime
//  2.8, dropTime 0.9. The perk lands on "weapon_change_complete", then
//  perk_give_bottle_end() switches the gun back and waits for ITS raise. So
//  "drink faster" is "switch weapons faster", for exactly that span.
//
//  🌟 THE ENGINE ALREADY HAS THE KNOB. MP's Fast Hands is
//  specialty_fastweaponswitch, scaled by perk_weapSwitchMultiplier - and that
//  dvar is in THIS build's zombies boot dump ("0.5"), so the code path is
//  compiled into t6zm. The perk is set for the drink and cleared after it;
//  nothing else the player does is touched.
//
//  🛑 NOT hooked at increment_is_drinking() or disable_player_move_states():
//  both are shared with Pack-a-Punch, the Bowie knife, buildables, the gas
//  mask and the tomahawk (measured over the whole ZM dump). The gate is the
//  bottle weapon itself - _zm_utility::is_zombie_perk_bottle(), 14 names.
//
//  THREE PLACES SET IT, ONE STATE, ONE SETTER:
//    1. zmqol_vending_trigger_post_think - stock's post-purchase function
//       verbatim, with the set/clear around the drink. It is THREADED from
//       vending_trigger_think() (the shape STOCK_REFERENCE 7a measured
//       hookable), but a _zm_perks hook has failed before (give_perk), so it
//       PRINTS when it runs: that line in the log is the proof it took.
//    2. wunderfizz.gsc::givePerk() - the mod's own machine, set directly.
//    3. zmqol_speed_cola_drink_watch() - per player, 20 Hz: the moment
//       is_drinking > 0 AND a perk bottle is in the weapon list, set, and
//       LATCHED until is_drinking returns to 0 so the gun's swap back is
//       quick too. Needs no hook to take and reaches every drink path.
//       Cost: two field reads per tick until a drink actually starts.
//  All three go through zmqol_speed_cola_fast_drink_set(), which is
//  idempotent, so they can overlap freely.
//
//  📝 Buying Speed Cola itself: hasperk() is false until the perk lands
//  mid-drink, so that first bottle goes down at normal speed and only the
//  swap back is quick. Correct - you did not have Speed Cola yet.
//  📝 Residual, settled by the boot: whether the engine reads the multiplier
//  when the raise STARTS (after the gun's drop) or when the switch begins.
//  Paths 1 and 2 set the perk before the switch either way; path 3 lands
//  within 50 ms, during the drop, so it covers the first reading only.
// ============================================================================
zmqol_speed_cola_fast_drink_set( b_on )
{
    if ( b_on )
    {
        if ( is_true( self.zmqol_fast_drink ) )
            return;

        if ( !getdvarintdefault( "better_speed_cola", 0 ) )
            return;

        if ( !self hasperk( "specialty_fastreload" ) )
            return;

        self.zmqol_fast_drink = 1;
        self setperk( "specialty_fastweaponswitch" );
        //  printed AFTER setperk() on purpose: if the engine rejects the perk
        //  name the thread dies there and this line never appears
        println( "[zm_qol] speed cola: fast drink -> 1" );
        return;
    }

    if ( !is_true( self.zmqol_fast_drink ) )
        return;

    self.zmqol_fast_drink = 0;
    self unsetperk( "specialty_fastweaponswitch" );
    println( "[zm_qol] speed cola: fast drink -> 0" );
}

zmqol_holding_perk_bottle()
{
    a_weapons = self getweaponslist();

    for ( i = 0; i < a_weapons.size; i++ )
    {
        if ( is_zombie_perk_bottle( a_weapons[i] ) )
            return 1;
    }

    return 0;
}

zmqol_speed_cola_drink_watch()
{
    if ( zmqol_minimal() )
        return;

    self endon( "disconnect" );
    level endon( "end_game" );
    flag_wait( "initial_blackscreen_passed" );
    b_latched = 0;

    for ( ;; )
    {
        if ( !isdefined( self.is_drinking ) || self.is_drinking <= 0 )
        {
            b_latched = 0;
            self zmqol_speed_cola_fast_drink_set( 0 );
            wait 0.05;
            continue;
        }

        if ( self maps\mp\zombies\_zm_laststand::player_is_in_laststand() )
        {
            self zmqol_speed_cola_fast_drink_set( 0 );
            wait 0.05;
            continue;
        }

        if ( !b_latched && self zmqol_holding_perk_bottle() )
            b_latched = 1;

        if ( b_latched )
            self zmqol_speed_cola_fast_drink_set( 1 );

        wait 0.05;
    }
}

//  Stock's vending_trigger_post_think() (_zm_perks.gsc:1888), verbatim except
//  the three marked lines. `self` is the machine's trigger, as in stock.
zmqol_vending_trigger_post_think( player, perk )
{
    player endon( "disconnect" );
    player endon( "end_game" );
    player endon( "perk_abort_drinking" );
    println( "[zm_qol] speed cola: machine drink hook fired (" + perk + ")" );      //  <- proof the replaceFunc took
    player zmqol_speed_cola_fast_drink_set( 1 );                                    //  <- before the bottle comes up
    gun = player maps\mp\zombies\_zm_perks::perk_give_bottle_begin( perk );
    evt = player waittill_any_return( "fake_death", "death", "player_downed", "weapon_change_complete" );

    if ( evt == "weapon_change_complete" )
        player thread maps\mp\zombies\_zm_perks::wait_give_perk( perk, 1 );

    player maps\mp\zombies\_zm_perks::perk_give_bottle_end( gun, perk );
    player zmqol_speed_cola_fast_drink_set( 0 );                                    //  <- the gun is back up

    if ( player maps\mp\zombies\_zm_laststand::player_is_in_laststand() || isdefined( player.intermission ) && player.intermission )
        return;

    player notify( "burp" );

    if ( isdefined( level.pers_upgrade_cash_back ) && level.pers_upgrade_cash_back )
        player maps\mp\zombies\_zm_pers_upgrades_functions::cash_back_player_drinks_perk();

    if ( isdefined( level.pers_upgrade_perk_lose ) && level.pers_upgrade_perk_lose )
        player thread maps\mp\zombies\_zm_pers_upgrades_functions::pers_upgrade_perk_lose_bought();

    if ( isdefined( level.perk_bought_func ) )
        player [[ level.perk_bought_func ]]( perk );

    player.perk_purchased = undefined;

    if ( is_false( self.power_on ) )
    {
        wait 1;
        maps\mp\zombies\_zm_perks::perk_pause( self.script_noteworthy );
    }

    bbprint( "zombie_uses", "playername %s playerscore %d round %d name %s x %f y %f z %f type %s", player.name, player.score, level.round_number, perk, self.origin, "perk" );
}

// ============================================================================
//  zmqol_perma_perks  -  PERMA-PERKS on the GAME tab           (queue item 29)
//
//  User, 2026-08-20: one on/off switch covering every persistent upgrade the
//  base game already gives a map, and nothing more - *"don't add perma perks
//  that aren't meant to be on other maps, like perma phd for instance is a
//  buried only perma perk."*  Settled by them the same day: ENABLED means every
//  perma-perk the map has is active immediately, with no challenge progress
//  needed; DISABLED is stock, earned normally, and is the default.
//
//  SCOPE IS CORRECT BY CONSTRUCTION - NOTHING HERE REGISTERS AN UPGRADE.
//  level.pers_upgrades holds only what the map itself registered in its own
//  init_persistent_abilities(): TranZit and Die Rise set 13 each, Buried sets
//  the same 13 plus pers_upgrade_flopper (Perma-PhD), and Mob, Origins and
//  Nuketown set none at all, so level.pers_upgrades is never even created
//  there. Perma-PhD therefore cannot leak off Buried - this only satisfies the
//  threshold of names that are already in that table.
//
//  THE MECHANISM, AND WHY IT IS NOT THE SHORTCUT CHECKPOINT 125 REFUSED.
//  That shortcut was to set player.pers_upgrades_awarded[name] = 1 directly and
//  call the activation function by hand. It has a real race:
//  pers_upgrades_monitor() (_zm_pers_upgrades_system.gsc:44) re-tests every
//  upgrade whose own stat ticks during play, and when the real stat is still
//  below its threshold it takes the DOWNGRADE branch at :125 - awarded flag
//  back to 0 and "evt_player_downgrade" in the player's ear, mid-match.
//
//  AND THE DOWNGRADE DOES REVOKE THE EFFECT. That was checkpoint 125's open
//  question; it is now answered by grep, not by reasoning. Every perma-perk
//  effect reads self.pers_upgrades_awarded[<name>] AT THE POINT OF USE, not
//  once at activation - _zm_blockers.gsc:1481/1530 ("board"),
//  _zm_magicbox.gsc:1116 ("box_weapon"), _zm.gsc:1960/4136/4182/4372/4395
//  ("perk_lose", "flopper"), _zm_weapons.gsc:1165/2128 ("nube"),
//  _zm_laststand.gsc:1025 - and the pers_upgrade_*_active() watchers re-check
//  the same flag every iteration (_zm_pers_upgrades_functions.gsc:22, :43, :60,
//  :266, :299, :431, :607, :748, :1194). The flag IS the live authority, so a
//  downgrade silently switches the perk off. The shortcut was correctly refused.
//
//  WHAT THIS DOES INSTEAD: MOVE THE THRESHOLD, NOT THE FLAG.
//  check_pers_upgrade_stat() (_zm_pers_upgrades_system.gsc:214) is one
//  comparison,  current_stat_value < stat_desired_value -> not awarded,  and
//  stat_desired_value is read out of
//  level.pers_upgrades[name].stat_desired_values[i], which is ordinary level
//  DATA this script may write. Set every entry to 0 and the comparison can
//  never fail - a stat is never negative - so:
//    - should_award is always 1, which makes the DOWNGRADE BRANCH UNREACHABLE.
//      The race is closed by construction, not mitigated.
//    - the award runs through STOCK'S OWN PATH at :82-119 - evt_player_upgrade,
//      the announcer VO, the "upgrade_aquired" fx, and
//      player thread [[ pers_upgrade.upgrade_active_func ]]() - so all six axes
//      of the completeness audit are stock's own, not this mod's imitation.
//    - NOTHING PERSISTENT IS WRITTEN. The obvious alternative was stock's own
//      grant path (_zm_devgui.gsc:172 zombie_devgui_ability_give), which calls
//      set_global_stat -> setdstat( "PlayerStatsList", ... ). That is the
//      player's SAVED PROFILE: it would hand out real permanent challenge
//      progress, and switching the row back to DISABLED could never undo it.
//      Rejected for that reason. Moving the threshold touches level state only,
//      so OFF restores stock exactly and immediately.
//
//  IMMEDIATE, VIA STOCK'S OWN TRIGGER. The monitor only looks at a player
//  whose stats moved this frame - unless self.pers_upgrade_force_test is set,
//  which short-circuits both the outer gate (:65) and
//  is_any_pers_upgrade_stat_updated() (:196). That is exactly how stock kicks
//  the first evaluation (_zm_stats.gsc:194) and how its own devgui grants one,
//  so this sets the same flag rather than inventing a trigger.
//
//  CLASSIC ONLY, AND THAT IS STOCK'S GATE, NOT ONE ADDED HERE.
//  pers_upgrades_monitor() returns early unless is_classic() (:48), and all
//  three init_persistent_abilities() are themselves wrapped in is_classic().
//  Survival and Grief have never had perma-perks; the row does nothing there.
//
//  ONE STOCK SIDE EFFECT, HANDLED RATHER THAN LEFT. wait_for_game_end()
//  (:145) zeroes the stats of any upgrade registered with
//  game_end_reset_if_not_achieved = 1 that the player did NOT achieve. Exactly
//  one is registered that way - "revive" (_zm_pers_upgrades.gsc:83) - and with
//  this row ON it always reads as achieved, so stock would skip that reset and
//  quietly preserve partial revive progress the player never earned.
//  zmqol_perma_perks_end_game() performs the reset itself against the REAL
//  threshold, so the row changes no saved stat in either direction.
// ============================================================================
zmqol_perma_perks_enabled()
{
    return getdvarintdefault( "perma_perks", 0 );
}

zmqol_perma_perks_watch()
{
    if ( zmqol_minimal() )
        return;

    level endon( "game_ended" );

    //  Stock's own gate on this whole system - see the banner.
    if ( !is_classic() )
        return;

    //  level.pers_upgrades is created by the map's own pers_upgrade_init(), so
    //  wait for it rather than assume an ordering against this script's init().
    //  On Mob, Origins and Nuketown it is never created at all, so give up
    //  rather than spin for the whole match.
    n_waited = 0;

    while ( !isdefined( level.pers_upgrades ) || !isdefined( level.pers_upgrades_keys ) )
    {
        if ( n_waited >= 30 )
            return;

        wait 0.5;
        n_waited += 0.5;
    }

    //  SNAPSHOT THE REAL THRESHOLDS BEFORE ANYTHING IS CHANGED. This is what
    //  DISABLED restores and what the end-of-game reset is measured against.
    //  Copied element by element on purpose - never by assigning the array
    //  wholesale - so it cannot end up aliasing the live one.
    level.zmqol_pp_real = [];

    for ( i = 0; i < level.pers_upgrades_keys.size; i++ )
    {
        str_name = level.pers_upgrades_keys[i];
        a_real = [];

        for ( j = 0; j < level.pers_upgrades[str_name].stat_desired_values.size; j++ )
            a_real[j] = level.pers_upgrades[str_name].stat_desired_values[j];

        level.zmqol_pp_real[str_name] = a_real;
    }

    level thread zmqol_perma_perks_end_game();

    b_applied = 0;

    for ( ;; )
    {
        b_want = zmqol_perma_perks_enabled();

        if ( b_want && !b_applied )
        {
            zmqol_perma_perks_set_thresholds( 1 );
            b_applied = 1;
            zmqol_perma_perks_kick();
            println( "[zm_qol] perma_perks: ON, " + level.pers_upgrades_keys.size + " upgrade(s) on " + level.script );
        }
        else if ( !b_want && b_applied )
        {
            //  Put the real numbers back and let stock re-evaluate honestly,
            //  including its own downgrade, which is the correct outcome here.
            zmqol_perma_perks_set_thresholds( 0 );
            b_applied = 0;
            zmqol_perma_perks_kick();
            println( "[zm_qol] perma_perks: OFF, thresholds restored" );
        }
        else if ( b_want )
        {
            //  A player who connected or respawned after the apply has never
            //  been through the monitor with the thresholds down. Only kick one
            //  that still has something outstanding, so this costs nothing once
            //  everybody is topped up.
            players = getplayers();

            for ( i = 0; i < players.size; i++ )
            {
                if ( isdefined( players[i].pers_upgrades_awarded ) && !players[i] zmqol_perma_perks_all_awarded() )
                    players[i].pers_upgrade_force_test = 1;
            }
        }

        wait 1;
    }
}

zmqol_perma_perks_set_thresholds( b_zero )
{
    for ( i = 0; i < level.pers_upgrades_keys.size; i++ )
    {
        str_name = level.pers_upgrades_keys[i];

        for ( j = 0; j < level.pers_upgrades[str_name].stat_desired_values.size; j++ )
        {
            if ( b_zero )
                level.pers_upgrades[str_name].stat_desired_values[j] = 0;
            else
                level.pers_upgrades[str_name].stat_desired_values[j] = level.zmqol_pp_real[str_name][j];
        }
    }
}

//  Stock's own "re-evaluate this player now" flag - _zm_stats.gsc:194 sets it
//  at stat init and _zm_devgui.gsc:185 sets it after a grant. The monitor
//  clears it itself (:138), so this is a one-shot, not a state to maintain.
zmqol_perma_perks_kick()
{
    players = getplayers();

    for ( i = 0; i < players.size; i++ )
    {
        if ( isdefined( players[i].stats_this_frame ) )
            players[i].pers_upgrade_force_test = 1;
    }
}

zmqol_perma_perks_all_awarded()
{
    for ( i = 0; i < level.pers_upgrades_keys.size; i++ )
    {
        str_name = level.pers_upgrades_keys[i];

        if ( !( isdefined( self.pers_upgrades_awarded[str_name] ) && self.pers_upgrades_awarded[str_name] ) )
            return 0;
    }

    return 1;
}

zmqol_perma_perks_end_game()
{
    //  Stock's wait_for_game_end() (_zm_pers_upgrades_system.gsc:145) waits on
    //  this same notify. Running the reset here as well is order-free and safe:
    //  zero_client_stat is idempotent, and with the row OFF stock's own pass has
    //  already done exactly this, so the second pass is a no-op.
    level waittill( "end_game" );

    if ( !isdefined( level.zmqol_pp_real ) || !isdefined( level.pers_upgrades_keys ) )
        return;

    players = getplayers();

    for ( p = 0; p < players.size; p++ )
    {
        player = players[p];

        for ( i = 0; i < level.pers_upgrades_keys.size; i++ )
        {
            str_name = level.pers_upgrades_keys[i];

            if ( !is_true( level.pers_upgrades[str_name].game_end_reset_if_not_achieved ) )
                continue;

            //  Measured against the REAL threshold, never the lowered one -
            //  that is the whole point of keeping the snapshot.
            b_earned = 1;

            for ( j = 0; j < level.pers_upgrades[str_name].stat_names.size; j++ )
            {
                n_have = player maps\mp\zombies\_zm_stats::get_global_stat( level.pers_upgrades[str_name].stat_names[j] );

                if ( n_have < level.zmqol_pp_real[str_name][j] )
                {
                    b_earned = 0;
                    break;
                }
            }

            if ( !b_earned )
            {
                for ( j = 0; j < level.pers_upgrades[str_name].stat_names.size; j++ )
                    player maps\mp\zombies\_zm_stats::zero_client_stat( level.pers_upgrades[str_name].stat_names[j], 0 );
            }
        }
    }
}

// ============================================================================
//  zmqol_no_walkers_watch  -  NO WALKERS                            (v2.8.6)
//
//  User request, 2026-08-30: *"add an option into the patches tab NO WALKERS
//  which when set to enabled, from round 10 and onwards there will be no
//  walking zombies they will all be sprinters so that way people can train the
//  zombies up more efficiently without the awkward walkers spoiling the train"*.
//
//  🛑 DELIBERATELY A WATCHER, NOT A replaceFunc. Stock picks a speed in THREE
//  places and two of them are same-file unqualified calls, which replaceFunc
//  does not reliably intercept (AI_CONTEXT rule 3):
//
//      _zm_utility::set_run_speed        randomintrange -> walk / run / sprint
//      _zm_utility::set_run_speed_easy   easy difficulty, walk / run only
//      _zm_utility::change_zombie_run_cycle   forces "walk" outright on any
//                                             difficulty above easy - this is
//                                             the one that makes the walkers
//                                             that break a train
//
//  Polling covers all three, plus anything a map script sets on its own, and it
//  is self-correcting: a zombie that somehow ends up walking is fixed within a
//  second rather than staying wrong for its whole life.
//
//  🌟 IT CALLS STOCK'S OWN PRIMITIVE. set_zombie_run_cycle() is what does the
//  real work - assigning zombie_move_speed alone would leave the ANIMATION on
//  the old cycle, because the anim only re-reads it via zm_run::needsupdate(),
//  which that function calls (_zm_utility.gsc:210). It also refreshes
//  .deathanim, so gibbed-leg deaths stay correct.
// ============================================================================
zmqol_no_walkers_watch()
{
    level endon( "end_game" );

    str_team = "axis";

    if ( isdefined( level.zombie_team ) )
        str_team = level.zombie_team;

    for ( ;; )
    {
        wait 1;

        if ( getdvarintdefault( "no_walkers", 0 ) == 0 )
            continue;

        if ( !isdefined( level.round_number ) || level.round_number < 10 )
            continue;

        a_zombies = getaispeciesarray( str_team, "all" );

        if ( !isdefined( a_zombies ) )
            continue;

        for ( i = 0; i < a_zombies.size; i++ )
        {
            zombie = a_zombies[i];

            if ( !isdefined( zombie ) || !isalive( zombie ) )
                continue;

            //  Only the ones that are actually walking. Leaving "run" alone
            //  keeps the horde looking natural - the request was about walkers
            //  spoiling a train, not about making everything identical.
            if ( !isdefined( zombie.zombie_move_speed ) || zombie.zombie_move_speed != "walk" )
                continue;

            zombie maps\mp\zombies\_zm_utility::set_zombie_run_cycle( "sprint" );
        }
    }
}
