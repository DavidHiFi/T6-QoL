#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_weapons;
#include maps\mp\zm_tomb;
#include maps\mp\zm_tomb_utility;

main()
{
    // These hook Origins-only functions. Safe here because this map script only
    // loads on Origins (so the references resolve), and done in main() so they're
    // in place before the map threads the native code. Matches zm_highrise.gsc.
    replaceFunc( maps\mp\zm_tomb_dig::swap_weapon, ::custom_swap_weapon );            // weapon-dig fix

    //  v2.14.5 - NO BLEEDOUT PATCH reaches Origins' OWN 15-second failsafe.
    //  See the banner over zmqol_tomb_round_spawn_failsafe() at the end of this
    //  file. The main switch-off is the ignore flag the shared copy sets; this
    //  covers the zombies that never run the shared copy at all.
    replaceFunc( maps\mp\zm_tomb::tomb_round_spawn_failsafe, ::zmqol_tomb_round_spawn_failsafe );

    //  v2.14.6 - and the giant robot's foot, which kills zombies with no player
    //  involved at all. Same row. See the banner at the end of this file.
    replaceFunc( maps\mp\zm_tomb_giant_robot::zombie_stomp_death, ::zmqol_tomb_zombie_stomp_death );
    replaceFunc( maps\mp\zm_tomb_ee_side::check_for_change, ::origins_change_patch ); // prone "loose change" -> 100
    replaceFunc( maps\mp\zm_tomb_utility::check_solo_status, ::qol_check_solo_status ); // 1 player = solo rules

    // ========================================================================
    //  v2.11.11 - THE PANZER DEATH CRASH.
    //
    //  Reproduced twice on 2026-09-04 (03:51:55 and 05:27:33) with byte-identical
    //  dumps: exception 0xC0000005 at 0x005906C0, GSC position inside
    //  _zm_ai_mechz::mechz_explode. Once from a natural round spawn, once from
    //  .panzer, so the spawn route is not the trigger - the death is.
    //
    //  Read out of the crash dump, not inferred. The faulting instruction is a
    //  one-line accessor called on a null pointer:
    //
    //      005906B9  mov  ecx, [eax*4 + 0x321CBF8]   ; weaponTable[eax] -> NULL
    //      005906C0  mov  eax, [ecx+8]               ; read of 0x00000008 <- FAULT
    //
    //  with EAX = 0xFF. 255 comes from the engine's own radiusdamage builtin,
    //  which defaults the SEVENTH argument - the weapon - to 255 whenever fewer
    //  than seven are passed:
    //
    //      0084F182  mov  esi, 0xFF          ; weapon index = 255
    //      0084F187  call Scr_GetNumParam
    //      0084F18F  cmp  eax, 6
    //      0084F192  jbe  <skip>             ; <= 6 args -> esi stays 255
    //                ... Scr_GetString(6) -> weapon lookup -> esi
    //      0084F1C6  push esi                ; handed to RadiusDamage
    //
    //  RadiusDamage guards that index against 0 but NOT against the 255
    //  sentinel; its only other check is against (registered weapon count + 1),
    //  so once enough weapons are loaded the sentinel sails through and
    //  weaponTable[255] is dereferenced. Origins loads 130 weapons stock and
    //  182 with this mod (measured with Unlinker over every fastfile the crash
    //  log shows being loaded).
    //
    //  Stock mechz_explode passes six arguments. This replacement is stock
    //  call-for-call with a real weapon name added, which keeps the sentinel out
    //  of the table lookup. frag_grenade_zm is resident on Origins (confirmed in
    //  zm_tomb.ff's weapon list) and matches the MOD_GRENADE_SPLASH already
    //  being passed.
    //
    //  🛑 NOT the whole problem: 44 stock call sites across the game use the
    //  fewer-than-seven form, ten of them reachable on the maps this mod
    //  supports (PhD Flopper's dive-to-nuke, the trap kills, TranZit's lava,
    //  zm_tomb.gsc:1923). This fixes the one that was measurably crashing.
    //  Full write-up: ERROR_CATALOGUE.md.
    // ========================================================================
    replaceFunc( maps\mp\zombies\_zm_ai_mechz::mechz_explode, ::zmqol_mechz_explode );

    // ========================================================================
    //  v1.58.0 - STRIP ORIGINS' NATIVE WUNDERFIZZ. The mod's own machines take
    //  their place, so every map has the same machine. User, 2026-08-07:
    //  "get rid of the actual pre-existing wunderfizz machines from origins,
    //  and just put the custom ones that are already good and working."
    //
    //  Why the native ones had to go rather than be improved: the mod fed its
    //  perk list into stock's rotation, and stock's cycling code was never
    //  written for a list that size. The user got duplicate bottles for perks
    //  already owned (get_weighted_random_perk falls through to keys[0] once
    //  everything is owned) and bottles landing off to the left - which is
    //  stock's perk_bottle_motion() reading .origin off an entity that is
    //  still mid-moveto. wunderfizz.gsc ALREADY fixes that exact bug; see the
    //  comment block above its own perk_bottle_motion(). Replacing is
    //  therefore strictly less work than patching, and lands on code the user
    //  has already confirmed working on five other maps.
    //
    //  🛑 BOTH of these are suppressed, and NEITHER is _zm_perk_random::init().
    //  init() must keep running: it performs six registerclientfield calls,
    //  and the matching .csc registers the same six. Skip them server-side and
    //  the register lists diverge -> EXE_CLIENT_FIELD_MISMATCH drops every
    //  player at load. Only the MACHINE SETUP is suppressed.
    //
    //      init_machines()        builds the unitriggers (the buy prompt)
    //      start_random_machine() threads machines_setup + machine_selector
    //                             (the ball, the animtree, the relocation)
    //
    //  init_machines is reached as `level thread init_machines()` from init()
    //  - an unqualified same-file call, hookable BECAUSE it is threaded.
    //  start_random_machine is called qualified from stock zm_tomb.gsc:256.
    //  Both are registered here in main(), not init(), because both are
    //  threaded at map-init and a replaceFunc registered in init() would land
    //  after they had already run.
    // ========================================================================
    replaceFunc( maps\mp\zombies\_zm_perk_random::init_machines,        ::zmqol_tomb_no_native_wunderfizz );
    replaceFunc( maps\mp\zombies\_zm_perk_random::start_random_machine, ::zmqol_tomb_no_native_wunderfizz );

    // Crazy Place Survival has no Origins challenge chests or quest path. Do
    // not register the four Origins challenge stats, HUD, rewards, or milestone
    // sound there. Classic Origins keeps the stock initializer below.
    replaceFunc( maps\mp\zm_tomb_challenges::challenges_init, ::zmqol_tomb_challenges_init );

    //  v1.59.2 - MP40 wall-buys hand out the ADJUSTABLE STOCK version.
    //  THREADED, and it waits for the wall-buy stubs to exist - the v1.59.1
    //  version ran inline here and found zero structs. See the function.
    level thread zmqol_mp40_keep_wallbuys_stalker();

    // ========================================================================
    //  ORIGINS SURVIVAL - THE CRAZY PLACE                            (v2.14.0)
    //
    //  User, 2026-09-06: *"add crazy place survival for origins from the
    //  reimagined mod into my mod"*.
    //
    //  Stock zm_tomb_gamemodes::init registers zclassic and the single "tomb"
    //  location and nothing else - Origins has no survival mode at all. The
    //  replacement adds zstandard + zgrief and one location, crazy_place, whose
    //  arena is the nine zone_chamber_* zones. Everything the arena needs
    //  (spawns, four perk machines, Pack-a-Punch, four wall-buys) is registered
    //  from script in scripts\zm\locs\zm_tomb_loc_crazy_place.gsc, so CLASSIC
    //  ORIGINS IS UNTOUCHED - no mapents file is shipped for this map.
    //
    //  📝 The 2026-08 version of this port also carried Reimagined's replaced
    //  zm_tomb_dig, zm_tomb_giant_robot and zm_tomb_ee_side (dig sites, walking
    //  robots and the side easter eggs on the OTHER three Origins arenas). None
    //  of the three is reachable from a sealed chamber, so none is restored.
    // ========================================================================
    replaceFunc( maps\mp\zm_tomb_gamemodes::init, scripts\zm\replaced\zm_tomb_gamemodes::init );

    // ========================================================================
    //  ORIGINS SURVIVAL - the zone-capture / generator system.
    //
    //  Stock zm_tomb_capture_zones assumes classic Origins: every perk machine
    //  and mystery box is OWNED by a generator zone and gated behind capturing
    //  it. A standalone arena has no reachable generator, so a machine handed to
    //  one is locked for the whole match and the Pack-a-Punch never comes back
    //  out of the ghost() it is put into at init.
    //
    //  🛑 FIVE FUNCTIONS, EACH STOCK VERBATIM PLUS ONE is_classic() RETURN -
    //  see the header of scripts\zm\replaced\zm_tomb_capture_zones.gsc for what
    //  each one does and why it is here. Classic Origins takes the stock path in
    //  all five and is byte-for-byte unchanged.
    //
    //  📝 Reimagined solves the same problem by replacing that file wholesale
    //  (880 lines, 18 functions). Deliberately NOT copied: their version also
    //  rewrites the capture-progress rules, the objective indices (31/30/29..24
    //  against stock's 0..3) and the recapture rounds, and precaches six
    //  ZM_TOMB_OBJ_RECAPTURE_ZOMBIE_* strings stock does not have. All of that
    //  lands on CLASSIC Origins, which nobody asked to change.
    // ========================================================================
    replaceFunc( maps\mp\zm_tomb_capture_zones::register_elements_powered_by_zone_capture_generators, scripts\zm\replaced\zm_tomb_capture_zones::register_elements_powered_by_zone_capture_generators );
    replaceFunc( maps\mp\zm_tomb_capture_zones::check_perk_machine_valid,   scripts\zm\replaced\zm_tomb_capture_zones::check_perk_machine_valid );
    replaceFunc( maps\mp\zm_tomb_capture_zones::pack_a_punch_init,          scripts\zm\replaced\zm_tomb_capture_zones::pack_a_punch_init );
    replaceFunc( maps\mp\zm_tomb_capture_zones::recapture_round_tracker,    scripts\zm\replaced\zm_tomb_capture_zones::recapture_round_tracker );
    replaceFunc( maps\mp\zm_tomb_capture_zones::all_zones_captured_vo,      scripts\zm\replaced\zm_tomb_capture_zones::all_zones_captured_vo );

    // Must run in main(), before the map registers its own clientfields.
    zmqol_register_survival_clientfields();
}

zmqol_tomb_challenges_init()
{
    //  Challenges are classic-Origins content: four challenge chests, the quest
    //  path and the milestone drum. No survival location has any of that, so
    //  skip registration off classic. Crazy Place Survival is the reported case.
    if ( !is_classic() )
        return;

    level.challenges_add_stats = maps\mp\zm_tomb_challenges::tomb_challenges_add_stats;
    maps\mp\zombies\_zm_challenges::init();
}

// ============================================================================
//  zmqol_register_survival_clientfields
//
//  🛑 Fixes a HARD CRASH on every non-classic Origins start location:
//        Clientfield 'element_glow_fx' in set [scriptmover] is not registered on the server
//        Clientfield 'switch_spark'    in set [scriptmover] is not registered on the server
//        COM_ERROR (3) Server Disconnected - EXE_CLIENT_FIELD_MISMATCH
//
//  This is a latent asymmetry in STOCK Origins, not something the port introduced:
//    * the CLIENT registers these unconditionally -
//        element_glow_fx / bryce_cake / switch_spark  in clientscripts/mp/zm_tomb.csc:46-48
//        sndMudSlow                                   in clientscripts/mp/zm_tomb_amb.csc:203
//    * the SERVER only registers them inside
//        maps\mp\zm_tomb_craftables::register_clientfields()  (zm_tomb_craftables.gsc:364-377)
//      which is reached solely from maps\mp\zm_tomb_classic::main() -> init_craftables().
//
//  Stock Origins is zclassic-only, so that path always ran and nobody ever hit it.
//  The moment Origins is played as zstandard/zgrief, the craftables path is skipped,
//  the server registers nothing, client and server disagree, and the engine drops the
//  connection. Registering the same four fields here restores parity.
//
//  Guarded by is_classic() so zclassic still gets them from stock's craftables path -
//  registering the same field twice would itself be an error.
//
//  Verified against BO2-Reimagined, which fixes this identically in
//  scripts/zm/zm_tomb/zm_tomb_reimagined.gsc:191-202 (same four fields, same guard,
//  also called from the end of main()).
//
//  ---------------------------------------------------------------------------
//  2026-07-31: TWO MORE FIELDS, same root cause, different stock code path.
//
//  Crazy Place / zstandard still dropped with EXE_CLIENT_FIELD_MISMATCH:
//        Clientfield 'electric_cherry_reload_fx' in set [allplayers] is not registered on the server
//        Clientfield 'visionset_slot' in set[toplayer] not the same bit count : [CLIENT: 2 SERVER: 1]
//
//  The gate is maps\mp\zombies\_zm_perks::init() line 52:
//
//        vending_triggers = getentarray( "zombie_vending", "targetname" );
//        ...
//        if ( vending_triggers.size < 1 )
//            return;              <-- returns BEFORE the _custom_perks loop at 101-110
//
//  perk_machine_spawn_init() only spawns machines whose struct script_string
//  contains "<gametype>_perks_<location>". No Origins struct is tagged for the
//  survival locations, so zero "zombie_vending" triggers exist, _zm_perks::init()
//  bails at line 52, and the per-perk machine_thread loop never runs. Those threads
//  are the ONLY server-side callers of:
//        _zm_perk_electric_cherry::init_electric_cherry()  -> registers electric_cherry_reload_fx
//        _zm_perk_divetonuke::init_divetonuke()            -> registers the zm_perk_divetonuke visionset
//
//  The client has no such gate - _zm_perks.csc::init_perk_custom_threads() runs
//  every registered perk's init thread unconditionally - so the client registers
//  both and the server neither. The visionset count is what drives visionset_slot's
//  bit width (_visionset_mgr::finalize_type_clientfields ->
//  getminbitcountfornum( info.size - 1 )), which is why the second mismatch rides
//  along with the first:
//        server: default + zombie_blood                     = 2 -> 1 bit
//        client: default + zombie_blood + zm_perk_divetonuke = 3 -> 2 bits
//  Both log lines follow exactly.
//
//  Registering here restores parity. Safe against double-registration: if a perk
//  machine ever DID spawn on a survival location, _zm_perks::init() would not bail,
//  init_electric_cherry/init_divetonuke would run, and these two lines would become
//  duplicates - but that is also precisely the case where the mismatch would not
//  occur, so the guard to revisit is "did we add perk machines to a loc script?".
//
//  VERIFIED IN GAME 2026-07-31 (14:07 run, Excavation Site / zstandard): the four
//  original fields and electric_cherry_reload_fx are all absent from the mismatch
//  list. Only visionset_slot still mismatched, which is the split-out half below.
// ============================================================================
zmqol_register_survival_clientfields()
{
    if ( is_classic() )
        return;

    registerclientfield( "toplayer",    "sndMudSlow",      14000, 1, "int" );
    registerclientfield( "scriptmover", "element_glow_fx", 14000, 4, "int", undefined, 0 );
    registerclientfield( "scriptmover", "bryce_cake",      14000, 2, "int", undefined, 0 );
    registerclientfield( "scriptmover", "switch_spark",    14000, 1, "int", undefined, 0 );

    // ========================================================================
    //  🛑 v2.14.0 - "THE GUARD TO REVISIT" ABOVE IS NOW LIVE.
    //
    //  The comment above says these two mirrors are safe against
    //  double-registration only while no survival location spawns a perk
    //  machine, and names the trigger: "did we add perk machines to a loc
    //  script?". The Crazy Place does exactly that - four machines and a
    //  Pack-a-Punch, registered from
    //  scripts\zm\locs\zm_tomb_loc_crazy_place.gsc::struct_init.
    //
    //  With machines present, _zm_perks::init() no longer bails at its
    //  vending_triggers.size < 1 check, its custom-perk loop runs, and
    //  init_electric_cherry() / init_divetonuke() register these two
    //  themselves - so registering them here as well would be the duplicate,
    //  not the fix.
    // ========================================================================
    if ( zmqol_loc_spawns_perk_machines() )
    {
        println( "[zm_qol] tomb survival clientfields: 4 registered; electric cherry + divetonuke LEFT TO STOCK (this location has perk machines)" );
        return;
    }

    // Mirror of _zm_perk_electric_cherry::init_electric_cherry (stock signature).
    registerclientfield( "allplayers", "electric_cherry_reload_fx", 9000, 2, "int" );

    println( "[zm_qol] tomb survival clientfields: 5 registered (no perk machine on this location)" );

    // The divetonuke visionset cannot be registered from here - see
    // zmqol_register_survival_visionset() below.
}

// ============================================================================
//  zmqol_loc_spawns_perk_machines
//
//  True for the survival locations whose loc script registers zm_perk_machine
//  structs of its own. Reads the dvar rather than level.scr_zm_map_start_location
//  because main() runs before _zm::main() assigns that - the same reason
//  loc_common::wallbuy_match_string() reads the dvars.
// ============================================================================
zmqol_loc_spawns_perk_machines()
{
    return getdvar( "ui_zm_mapstartlocation" ) == "crazy_place";
}

// ============================================================================
//  zmqol_register_survival_visionset
//
//  The second half of the fix above, split out because it CANNOT run in main().
//
//  2026-08-01: the 11:59 run proved the electric_cherry_reload_fx half worked -
//  that field is gone from the mismatch list - but Origins still dropped on:
//        Clientfield 'visionset_slot' in set[toplayer] is not registered with the
//        same bit count as the server : [CLIENT: 2  SERVER : 1]
//  i.e. the vsmgr_register_info call that used to sit at the end of
//  zmqol_register_survival_clientfields() never took.
//
//  Why: registerclientfield is a plain engine builtin with no state behind it,
//  so it works from main(). vsmgr_register_info is not - stock
//  maps\mp\_visionset_mgr.gsc:21-35 reads level.vsmgr[type] and asserts on
//  level.vsmgr_initializing, and BOTH are set up by _visionset_mgr::init(),
//  which runs out of _load::main() - AFTER this mod's main(). The call landed on
//  an undefined level.vsmgr and did nothing.
//
//  init() is inside the legal window: _visionset_mgr::init() has run by then, and
//  level.vsmgr_initializing is only cleared by finalize_clientfields(), which the
//  engine invokes later still via codecallback_finalizeinitialization ->
//  callback( "on_finalize_initialization" ) (_callbacksetup.gsc:19-21).
//
//  Guarded on isdefined so that if that ordering ever changes this degrades to
//  "visionset not registered" rather than a script error that takes out init().
//
//  🛑 NOT verified in game yet.
// ============================================================================
zmqol_register_survival_visionset()
{
    if ( is_classic() )
        return;

    //  🛑 v2.14.0 - same reason as the electric-cherry half above: on a location
    //  that spawns its own perk machines, _zm_perks::init() runs the custom-perk
    //  loop and _zm_perk_divetonuke::init_divetonuke() registers this visionset
    //  itself. Registering it twice would change visionset_slot's bit count on
    //  the server only, which is the mismatch this whole block exists to avoid.
    if ( zmqol_loc_spawns_perk_machines() )
    {
        println( "[zm_qol] tomb survival visionset: LEFT TO STOCK (this location has perk machines)" );
        return;
    }

    if ( !isdefined( level.vsmgr ) || !isdefined( level.vsmgr["visionset"] ) )
        return;

    // Mirror of _zm_perk_divetonuke::init_divetonuke (stock args: version 9000,
    // priority 400, 5 lerp steps, activate_per_player 1).
    maps\mp\_visionset_mgr::vsmgr_register_info( "visionset", "zm_perk_divetonuke", 9000, 400, 5, 1 );
}

init()
{
    level thread zmqol_hide_native_wunderfizz();

    //  🛑 v1.95.7 - zmqol_ring_hud_visibility() IS NO LONGER STARTED, and the
    //  whole hud_visible approach is abandoned. It shipped in v1.95.4, it
    //  provably RAN ("[zm_qol] ring hud: hud_visible cycled 0->1" is in the
    //  2026-08-14 log), and the ring was still missing - the client builds its
    //  LUI later than any moment the server can pick. Every flag-flip fix is a
    //  race and all three lost. The real fix is in
    //  ui_mp\t6\zombie\hudcraftablestombzombie.lua, which wraps the ring menu's
    //  own constructor so its alpha is never 0 in the first place.
    //  User: *"fix that permanently ... no more hidden stuff"* - so this also
    //  stops the mod taking their HUD down for half a second at every spawn.

    //  🛑 v1.94.0 - zmqol_capture_objectives_fix() AND zmqol_capture_hud_nudge()
    //  ARE NO LONGER STARTED. v2.10.12 deleted both as dead code (git history
    //  keeps their measurements); the summary that matters is below.
    //
    //  Two reasons, and the second is the important one:
    //
    //  1. The user rejected the nudge outright: "the ring showed but it flashed
    //     for a brief moment... my mod shouldn't be doing that i never asked you
    //     for you hide that." It works by writing hud_visible 0 then 1, i.e. by
    //     hiding their HUD.
    //  2. Checkpoint 45 already ruled the re-declare loop DISPROVEN as
    //     load-bearing - the ring's LUI is created at alpha 0 and only an
    //     incoming HUD event raises it, so re-declaring objectives could never
    //     have mattered.
    //
    //  📝 AND BOTH EMIT RELIABLE SERVER COMMANDS ON A TIMER. objective_add() is
    //  reliable and the fix re-declared six of them repeatedly for 20s;
    //  setclientuivisibilityflag() is reliable too. Origins is one of the two
    //  maps still dying with EXE_ERR_RELIABLE_CYCLED_OUT, so removing known
    //  timed reliable traffic is worth doing on its own merits. This is NOT
    //  claimed as the fix for that crash - see the queue entry.
    //
    //  ▶️ v1.95.4 tried zmqol_ring_hud_visibility() next (also deleted in
    //  v2.10.12); v1.95.7 above records why every server-side flag flip lost.
    zmqol_register_survival_visionset();
    level thread zmqol_power_up_all_generators();
    level thread zmqol_no_power_tomb_extras();
    level thread zmqol_disable_staff_relay_switches();
    level thread zmqol_remove_survival_ee_props();
    level thread zmqol_open_stock_barriers();
    level thread zmqol_wunderfizz_all_perks();
    added_weapons();

    //  .panzer (amount) / spawn_panzer <n>. Installed here, not in the root
    //  script - maps\mp\zombies\_zm_ai_mechz is Origins-only and a qualified
    //  reference to it from a root file crashes every other map at load.
    level.zmqol_boss_name = "panzer";
    level.zmqol_boss_spawn_func = ::zmqol_spawn_panzer;
}

// ============================================================================
//  zmqol_spawn_panzer  -  the real Panzer Soldat, through stock's own spawner.
//
//  mechz_spawning_logic() (_zm_ai_mechz.gsc:403) is already threaded and sits on
//  `level waittill( "spawn_mechz" )`, then drains level.mechz_left_to_spawn -
//  spawning each one with spawn_zombie( level.mechz_spawners[0] ) + mechz_spawn()
//  (the armour, the claw, the health scaling, the fx, the audio, the hint vo) and
//  waiting for a free spawn location. So all of that stays stock.
//
//  🌟 THIS IS EXACTLY WHAT TREYARCH'S OWN DEV SPAWNER DOES -
//  _zm_ai_mechz_dev.gsc:87-92 sets mechz_left_to_spawn then notifies. The one
//  deliberate difference is += rather than =, so asking for a panzer during a
//  real panzer round tops the queue up instead of cancelling what is pending.
// ============================================================================
zmqol_spawn_panzer( n_amount )
{
    if ( !isdefined( level.mechz_spawners ) || !isdefined( level.mechz_left_to_spawn ) )
        return 0;

    level.mechz_left_to_spawn += n_amount;
    level notify( "spawn_mechz" );

    return n_amount;
}

// ============================================================================
//  zmqol_wunderfizz_all_perks  -  the mod's perks, out of ORIGINS' OWN machines
//
//  User: "get rid of them keep the vanilla ones and just add all perks to the
//  machine like the other maps with the added machine... make sure that every map
//  with the real actual wunderfizz machine let's you get all 11 perks."
//
//  So the split on Origins is now: STOCK OWNS THE MACHINE, THE MOD OWNS WHAT
//  COMES OUT OF IT. The added machine is gone from wunderfizz.gsc; this puts the
//  extra perks into the rotation the map's own four machines already draw from.
//
//  level._random_perk_machine_perk_list is that rotation, and
//  _zm_perk_random::include_perk_in_random_rotation() is stock's own way to add to
//  it (_zm_perk_random.gsc:485) - so nothing here overrides a stock function or
//  reimplements one. get_weighted_random_perk() then skips whatever the player
//  already holds, exactly as before.
//
//  ⚠️ WHY THIS IS NOT ELEVEN ON ORIGINS. Vulture Aid cannot be enabled here at
//  all - Origins' ACTOR clientfield set has no room for vulture_perk_actor, which
//  is what made Classic Origins refuse to boot; see zmqol_vulture_enabled() in
//  quality_of_life.gsc. Every OTHER perk the mod can enable is added below, and
//  the purchase cap is no longer the thing standing in the way. Getting the
//  eleventh onto this map means freeing those two bits, which needs the client
//  script shipped as raw text instead of compiled bytecode.
//
//  🛑 This file is map-specific, which is the only reason the qualified reference
//  to _zm_perk_random is legal - that module ships in zm_tomb.ff and nowhere
//  else, so the same line in a root script would throw "Unresolved external" on
//  the other five maps. AI_CONTEXT rule 2.
// ============================================================================
zmqol_wunderfizz_all_perks()
{
    level waittill( "start_of_round" );
    wait 0.05;

    a_perks = scripts\zm\wunderfizz::getPerks();

    if ( !isdefined( a_perks ) || a_perks.size < 1 )
        return;

    if ( !isdefined( level._random_perk_machine_perk_list ) )
        level._random_perk_machine_perk_list = [];

    n_added = 0;

    for ( i = 0; i < a_perks.size; i++ )
    {
        str_perk = a_perks[i];

        // Only perks the level actually registered - offering one the map never
        // set up hands out a bottle that does nothing, which is the half-dead
        // state Electric Cherry was in before v1.36.0.
        if ( !isdefined( level._custom_perks ) || !isdefined( level._custom_perks[ str_perk ] ) ||
             !isdefined( level._custom_perks[ str_perk ].player_thread_give ) )
        {
            if ( !zmqol_tomb_perk_is_stock( str_perk ) )
                continue;
        }

        if ( isinarray( level._random_perk_machine_perk_list, str_perk ) )
            continue;

        maps\mp\zombies\_zm_perk_random::include_perk_in_random_rotation( str_perk );
        n_added++;
    }

    println( "[zm_qol] origins: added " + n_added + " perk(s) to the native Wunderfizz rotation, list is now " + level._random_perk_machine_perk_list.size );

    //  And make a repeat impossible - see zmqol_tomb_perk_weights() below.
    if ( isdefined( level.custom_random_perk_weights ) && !isdefined( level.zmqol_tomb_weights_prev ) )
    {
        level.zmqol_tomb_weights_prev = level.custom_random_perk_weights;
        level.custom_random_perk_weights = ::zmqol_tomb_perk_weights;
    }
}

// ============================================================================
//  zmqol_tomb_perk_weights  -  never hand out a perk the player already holds
//
//  User: "when i got to mule kick and spun the machine again i got mule kick
//  again when i already had it, spun it a 3rd time and got mule kick again."
//
//  🛑 STOCK HAS EXACTLY ONE PATH THAT CAN RETURN A HELD PERK, and it is the last
//  line of get_weighted_random_perk() (_zm_perk_random.gsc:516):
//
//      for ( i = 0; i < keys.size; i++ )
//          if ( player hasperk( list[keys[i]] ) ) continue;
//          else return list[keys[i]];
//
//      return list[keys[0]];          <- the fallback
//
//  The loop is correct and skips everything you hold. The fallback underneath it
//  returns keys[0] unconditionally - it is stock's "you already own everything,
//  have something anyway" case. Whatever is putting the player down that path,
//  keys[0] is what comes back, and Mule Kick three times in a row is keys[0]
//  being stable across spins.
//
//  Why it is stable, and why Mule Kick specifically: Origins' own weighting
//  function (zm_tomb.gsc::tomb_random_perk_weights) appends up to five BONUS
//  entries every single spin with arraycombine( ..., keepdupes = 1 ) - among them
//  specialty_additionalprimaryweapon. That is how stock weights the draw: more
//  copies, more likely. It also means the list grows without bound as you spin,
//  and the more you spin the more of it is those five perks.
//
//  So rather than guess which condition sends the draw to the fallback, this
//  removes the fallback's ability to be wrong: the key order handed back has
//  every perk the player LACKS first, so keys[0] is always something they can
//  use. Perks they hold are kept on the end so the fallback still has something
//  to return in the genuine "owns everything" case.
//
//  Stock's weighting is preserved exactly - this calls Origins' own function and
//  only reorders what it returns, so the duplicate-weighted draw still works as
//  Treyarch tuned it.
//
//  📝 Worth keeping: when a bug is "sometimes returns the wrong thing" and the
//  code has a fallback branch, check the FALLBACK before the main path. The main
//  path here was right all along and reads like the suspect.
//
//  Called ON THE PLAYER - get_weighted_random_perk does
//  `keys = player [[ level.custom_random_perk_weights ]]();`
// ============================================================================
zmqol_tomb_perk_weights()
{
    a_keys = self [[ level.zmqol_tomb_weights_prev ]]();

    if ( !isdefined( a_keys ) || a_keys.size < 1 )
        return a_keys;

    a_want = [];
    a_have = [];

    for ( i = 0; i < a_keys.size; i++ )
    {
        str_perk = level._random_perk_machine_perk_list[ a_keys[i] ];

        if ( !isdefined( str_perk ) )
            continue;

        if ( self hasperk( str_perk ) )
            a_have[ a_have.size ] = a_keys[i];
        else
            a_want[ a_want.size ] = a_keys[i];
    }

    //  Everything they lack, in stock's own weighted order, then the rest.
    for ( i = 0; i < a_have.size; i++ )
        a_want[ a_want.size ] = a_have[i];

    return a_want;
}

//  The perks Origins registers itself, which do not appear in level._custom_perks
//  because they are core rather than custom.
zmqol_tomb_perk_is_stock( str_perk )
{
    a_stock = array( "specialty_armorvest", "specialty_quickrevive", "specialty_fastreload",
                     "specialty_rof", "specialty_longersprint", "specialty_additionalprimaryweapon",
                     "specialty_deadshot", "specialty_flakjacket", "specialty_scavenger" );

    return isinarray( a_stock, str_perk );
}

//  True while any capture zone currently owns an objective index - stock assigns
//  it on acquire and clears it on release (zm_tomb_capture_zones.gsc:1548/:1715),
//  so this is exactly "a ring is live right now". Written defensively because it
//  runs before the capture system may have registered anything.
zmqol_any_zone_capturing()
{
    if ( !isdefined( level.zone_capture ) || !isdefined( level.zone_capture.zones ) )
        return 0;

    foreach ( zone in level.zone_capture.zones )
    {
        if ( isdefined( zone.n_objective_index ) )
            return 1;
    }

    return 0;
}

//  If anything at all goes wrong between the 0 and the 1 above, the flag is
//  restored anyway. Writing 1 twice is a no-op, so this costs nothing in the
//  normal case - and a player with no HUD for a whole match would be a far worse
//  bug than the one being fixed.
zmqol_ring_hud_failsafe()
{
    self endon( "disconnect" );

    wait 10;
    self setclientuivisibilityflag( "hud_visible", 1 );
}

zmqol_capture_objectives_on_connect()
{
    level endon( "end_game" );

    for ( ;; )
    {
        level waittill( "connected", player );

        player waittill( "spawned_player" );
        wait 0.05;

        //  v1.90.7 - same guard as above. A co-op player connecting while someone
        //  else is mid-capture must not blank that player's ring.
        if ( zmqol_any_zone_capturing() )
        {
            println( "[zm_qol] capture objectives: connect re-declare SKIPPED - a capture is live" );
            continue;
        }

        maps\mp\zm_tomb_capture_zones::declare_objectives();
        println( "[zm_qol] capture objectives: re-declared for a connecting player" );
    }
}

// ============================================================================
//  ✅ THE ORIGINS CAPTURE RING IS FIXED - PROBE REMOVED IN v2.11.22
// ============================================================================
//  zmqol_probe_capture_zones() lived here from v1.82.0 to v2.11.21. It was
//  the diagnostic for the capture ring never drawing, and on 2026-09-04 it
//  finally reported: 65 lines during a generator_start_bunker capture,
//  progress climbing 3.33 -> 53, decaying whenever the player stepped out,
//  contested=1 throughout, obj=0 - and obj 0 is a REAL index, not a default
//  (zm_tomb_capture_zones.gsc:82 declares it as ZM_TOMB_OBJ_CAPTURE_1). So
//  the server half was always perfect, exactly as the probe's own decision
//  rule predicted, and the user confirmed the ring itself in the same game:
//  *"yeah origins generator is fine"*.
//
//  The fix that did it is NOT here - it is the LUI wrap in
//  ui_mp\t6\zombie\hudcraftablestombzombie.lua, which raises the ring menu
//  that CoD.GametypeBase.new() leaves at alpha 0. Full history:
//  zm_qol - dev\.agents\checkpoint_225.md and QUEUE.md (2026-09-04).
//
//  🛑 Do not re-add a for(;;) probe here casually - this one printed 65
//  lines per capture for the whole match.
// ============================================================================
// ============================================================================
//  zmqol_tomb_mp40_stalker_wallbuys  -  Origins' MP40 wall-buys give the same
//  adjustable-stock MP40 the mystery box gives.
//
//  User, 2026-08-07: "make sure that the mp40 wallbuys give you the mp40
//  adjustable stock just like my friend did, the same mp40 adjustable stock
//  that you get if you get the mp40 out of the mystery box."
//
//  🌟 THIS NEEDS NO NEW ASSET AND NO WEAPON REGISTRATION. Stock Origins already
//  ships both guns and already registers the stalker one (zm_tomb.gsc):
//
//      add_zombie_weapon( "mp40_zm",         "mp40_upgraded_zm",         ... 1300 ... )
//      add_zombie_weapon( "mp40_stalker_zm", "mp40_stalker_upgraded_zm", ... 1300 ... )
//      include_weapon( "mp40_zm", 0 )          <- buyable, NOT in the box
//      include_weapon( "mp40_stalker_zm" )     <- in the box
//      add_shared_ammo_weapon( "mp40_stalker_zm", "mp40_zm" )
//
//  Both are registered at the same 1300 cost and already share ammo, so
//  pointing the wall-buys at the stalker variant changes which of two
//  already-present weapons is handed over. Nothing is precached, nothing is
//  added to the box, and the cost does not move.
//
//  🛑 TIMING: this MUST run in main(). maps\mp\zombies\_zm_weapons::
//  init_spawnable_weapon_upgrade() reads .zombie_weapon_upgrade off these
//  structs during init and builds the trigger and its hint string from it.
//  Editing them afterwards would change nothing.
//
//  📝 It also prints every MP40 wall-buy it finds, which is the probe for the
//  second half of the same report: the wall-buy by the mound in No Man's Land
//  shows its chalk but offers no buy prompt. The mapents dump of zm_tomb.ff has
//  THREE structs, all identical in shape:
//        (3237, -429, 195)   (-517, 4503, -285)   (-640, 693, 199)
//  If this line reports 3, all three structs exist and the missing prompt is
//  downstream in trigger creation. If it reports fewer, the struct itself is
//  not reaching the game and that is a different problem entirely. Either way
//  the next boot answers it without another round trip.
// ============================================================================
zmqol_tomb_mp40_stalker_wallbuys()
{
    level endon( "end_game" );

    //  🛑 v1.59.2 - THE v1.59.1 VERSION RAN IN main() AND DID NOTHING. Its own
    //  probe said so: "retagged 0 of 0 weapon_upgrade struct(s)".
    //  getstructarray() reads level.struct, which is built by the MAP's main()
    //  from the mapents - and this mod's main() runs BEFORE the map's (proven by
    //  the animtree ordering documented in zm_expanded.csc). So at main() there
    //  are literally no structs to retag yet. Retagging structs is the wrong
    //  lever anyway; see below.
    //
    //  🌟 THE RIGHT LEVER IS THE UNITRIGGER STUB, and it is timing-proof.
    //  _zm_weapons.gsc:1120 reads the weapon LIVE at purchase:
    //        weapon = self.stub.zombie_weapon_upgrade;
    //  so rewriting the stub after the wall-buys are built is enough, and does
    //  not race init_spawnable_weapon_upgrade() at all. Stock keeps every stub
    //  in level._unitriggers.trigger_stubs (_zm_unitrigger.gsc:123).
    //
    //  The hint needs no repair: get_weapon_hint() returns &"ZOMBIE_WEAPON_MP40"
    //  for BOTH variants and both cost 1300, so the prompt is identical either
    //  way. hint_string and cost are refreshed regardless, using stock's own
    //  idiom from _zm_weapons.gsc:1261, so nothing can drift.
    n_wait = 0;

    while ( !isdefined( level._unitriggers ) || !isdefined( level._unitriggers.trigger_stubs ) || level._unitriggers.trigger_stubs.size == 0 )
    {
        wait 0.5;
        n_wait += 0.5;

        if ( n_wait > 30 )
            return 0;
    }

    //  Let every wall-buy finish registering before walking the list.
    wait 2;

    //  🛑 v1.59.3 - REFUSE TO TOUCH ANYTHING UNLESS THE REPLACEMENT WEAPON IS
    //  REALLY REGISTERED. v1.59.2 retagged all three wallbuys and KILLED THE BUY
    //  PROMPT on every one of them - chalk still drawn, no prompt, unbuyable.
    //
    //  The mechanism, from stock (_zm_weapons.gsc):
    //      get_weapon_hint( w ) { return level.zombie_weapons[w].hint; }
    //      get_weapon_cost( w ) { return level.zombie_weapons[w].cost; }
    //  Both index level.zombie_weapons directly. If "mp40_stalker_zm" is not in
    //  that table at the moment this runs, BOTH return undefined - and the
    //  prompt is built from them, so an undefined hint is exactly a wallbuy with
    //  no prompt. Worse, the trigger re-derives the hint from
    //  .zombie_weapon_upgrade later (line 1218), so even leaving hint_string
    //  alone would not have saved it.
    //
    //  So the whole change is now gated on the table entry existing. If it does
    //  not, nothing is touched and the wallbuys keep working exactly as stock -
    //  a missing feature instead of a broken wallbuy. The log says which
    //  happened, so this cannot fail silently again.
    if ( !isdefined( level.zombie_weapons ) || !isdefined( level.zombie_weapons[ "mp40_stalker_zm" ] ) )
    {
        println( "[zm_qol] origins mp40: mp40_stalker_zm is NOT in level.zombie_weapons - RETAG SKIPPED, wallbuys left stock" );
        return 0;
    }

    //  And never write an undefined into the stub, even now.
    str_hint = maps\mp\zombies\_zm_weapons::get_weapon_hint( "mp40_stalker_zm" );
    n_cost   = maps\mp\zombies\_zm_weapons::get_weapon_cost( "mp40_stalker_zm" );

    if ( !isdefined( str_hint ) || !isdefined( n_cost ) )
    {
        println( "[zm_qol] origins mp40: hint or cost undefined for mp40_stalker_zm - RETAG SKIPPED, wallbuys left stock" );
        return 0;
    }

    a_stubs   = level._unitriggers.trigger_stubs;
    n_mp40    = 0;
    n_wb      = 0;
    n_live    = 0;
    a_mine    = [];
    str_where = "";

    for ( i = 0; i < a_stubs.size; i++ )
    {
        if ( !isdefined( a_stubs[i] ) || !isdefined( a_stubs[i].zombie_weapon_upgrade ) )
            continue;

        n_wb++;

        //  DIAGNOSTIC for the second half of the report: the wall-buy by the
        //  mound in No Man's Land shows chalk but offers no buy prompt. Every
        //  wall-buy stub that exists is printed with its weapon and position, so
        //  the log says outright whether that one was ever built. The mapents
        //  dump has three mp40 structs, at (3237,-429,195), (-517,4503,-285) and
        //  (-640,693,199) - if fewer than three appear here, the trigger is not
        //  being created and that is a separate fault from the weapon it hands
        //  out.
        if ( a_stubs[i].zombie_weapon_upgrade == "mp40_zm" || a_stubs[i].zombie_weapon_upgrade == "mp40_stalker_zm" )
        {
            if ( isdefined( a_stubs[i].origin ) )
            {
                str_where = str_where + a_stubs[i].zombie_weapon_upgrade + "("
                          + int( a_stubs[i].origin[0] ) + "," + int( a_stubs[i].origin[1] ) + "," + int( a_stubs[i].origin[2] ) + ") ";
            }
        }

        if ( a_stubs[i].zombie_weapon_upgrade != "mp40_zm" )
            continue;

        a_stubs[i].zombie_weapon_upgrade = "mp40_stalker_zm";

        //  .weapon_upgrade is set alongside it at _zm_weapons.gsc:957; keep the
        //  pair consistent rather than leaving one naming the old gun.
        if ( isdefined( a_stubs[i].weapon_upgrade ) )
            a_stubs[i].weapon_upgrade = "mp40_stalker_zm";

        a_stubs[i].hint_string = str_hint;
        a_stubs[i].cost        = n_cost;

        //  v1.79.0 - THE STUB IS NOT WHAT THE PURCHASE READS. See the block
        //  above zmqol_mp40_push_to_live_triggers() for the full mechanism.
        n_live += a_stubs[i] zmqol_mp40_push_to_live_triggers();

        a_mine[ a_mine.size ] = a_stubs[i];
        n_mp40++;
    }

    if ( n_mp40 > 0 || n_live > 0 )
        println( "[zm_qol] origins mp40: retagged " + n_mp40 + " mp40 wallbuy stub(s) to mp40_stalker_zm; " + n_wb + " wallbuy stub(s) total; corrected " + n_live + " already-live trigger(s); mp40 at " + str_where );

    if ( n_mp40 == 0 && n_wb == 0 )
        level.zmqol_mp40_saw_no_stubs = 1;

    //  🛑 The watcher thread is NOT started here any more. This function is now
    //  called once every 2s by zmqol_mp40_keep_wallbuys_stalker(), so threading
    //  a watcher per pass would spawn hundreds of them. The outer loop's re-scan
    //  does the watcher's job and does it for stubs that appear late as well.
    return n_mp40;
}

// ============================================================================
//  🌟 zmqol_mp40_keep_wallbuys_stalker  -  THE ACTUAL CAUSE, v1.80.0
//
//  User, 2026-08-13: *"for some reason now the mp40 gives me the regular again?
//  you just had it working with the adjustable stock stop reverting that
//  change."*
//
//  📝 NOTHING WAS REVERTED, and this was checkable rather than asserted: the
//  v1.79.0 fix (zmqol_mp40_push_to_live_triggers) has shipped in every build
//  since. Its read-only twin zmqol_mp40_watch_triggers, which only printed the
//  trigger census, was deleted as dead code in v2.10.12.
//
//  🛑 AND v1.79.0 WAS AIMED AT THE WRONG THING. Said plainly because it was
//  shipped as "verified mechanism, unproven cause" and the log has now answered:
//
//      retagged 0 mp40 wallbuy stub(s); 0 wallbuy stub(s) total;
//      corrected 0 already-live trigger(s)
//
//  **Zero stubs, not three.** The trigger-vs-stub split is real but it was never
//  reached - there was nothing to retag, so the live-trigger push had an empty
//  list and the watcher was handed an empty array. The two-copy fix stays (it is
//  correct, and it matters once the retag DOES run) but it is not the cause.
//
//  🌟 THE CAUSE IS THAT THE RETAG WAS A ONE-SHOT AGAINST A RACE IT COULD LOSE.
//  It waited for `level._unitriggers.trigger_stubs` to be non-empty - which the
//  FIRST unitrigger of any kind satisfies, a door or a perk machine - then
//  waited 2 seconds and walked the list exactly once. If the three MP40 wall-buy
//  stubs had not registered inside that window, it found nothing and gave up
//  permanently, for the rest of the game.
//
//  That is the whole intermittency, and the logs show both faces of the same
//  coin across boots of identical code:
//        .003 / .004 / one earlier   ->  23 stubs, 3 mp40, worked
//        .007 / .008 / this one      ->   0 stubs, 0 mp40, gave the plain gun
//
//  "It worked and then you broke it" was really "it won a race and then lost
//  it". No version boundary lines up with it.
//
//  THE FIX: stop betting on a window. Re-scan for the whole match, so a stub
//  registered late is retagged whenever it appears, and a trigger rebuilt from a
//  stub is re-checked. Correcting something already correct is a no-op, so the
//  steady state costs one walk of ~23 stubs every 2s and nothing else.
// ============================================================================
zmqol_mp40_keep_wallbuys_stalker()
{
    level endon( "end_game" );

    n_done   = 0;
    n_passes = 0;

    while ( n_passes < 900 )
    {
        n_done += zmqol_tomb_mp40_stalker_wallbuys();
        n_passes++;

        //  Loud exactly once, so a boot that never finds them is obvious in the
        //  log instead of silent - that silence is what hid this for weeks.
        if ( n_passes == 15 && n_done == 0 )
            println( "[zm_qol] origins mp40: STILL 0 mp40 stubs after 15 passes - wallbuy stubs are not registering at all, this is NOT the retag window" );

        wait 2;
    }
}

// ============================================================================
//  zmqol_mp40_push_to_live_triggers  -  the wall-buy hands out the OLD gun
//
//  User, 2026-08-13: *"still didn't get the box variant from the wallbuy, the
//  mp40 adjustable stock"*, and separately *"i don't know when/why you removed
//  this"*.
//
//  📝 IT WAS NEVER REMOVED. `git log -S zmqol_tomb_mp40_stalker_wallbuys` returns
//  exactly ONE commit - 30b05a8, the one that ADDED it - and the thread is still
//  started at zm_tomb.gsc:58. Nothing deleted it; it has simply never worked
//  reliably.
//
//  🌟 THE MECHANISM, verified in stock source. `zombie_weapon_upgrade` exists in
//  TWO places and the prompt and the purchase read DIFFERENT ones:
//
//      prompt    self.stub.zombie_weapon_upgrade    _zm_weapons.gsc:1120
//      PURCHASE  self.zombie_weapon_upgrade         _zm_weapons.gsc:1975, 2043
//                                                   and the give at :2088-2094
//
//  The trigger gets its own copy when it is built, and only then:
//
//      copy_zombie_keys_onto_trigger( trig, stub )      _zm_unitrigger.gsc:624
//          trig.zombie_weapon_upgrade = stub.zombie_weapon_upgrade;   // :629
//
//  and once built it is NOT rebuilt while it lives - build_trigger_from_
//  unitrigger_stub() is only reached when `!isdefined( closest[index].trigger )`
//  (:471). So a wall-buy whose trigger already existed when the retag ran keeps
//  the old weapon on the trigger while advertising the new one on the stub.
//  Rewriting only the stub cannot fix that trigger.
//
//  🛑 HONEST STATUS: the two-copy split is VERIFIED from source. That it is what
//  is happening in THIS failure is NOT yet proven - the retag runs ~2s in, and
//  whether any of the three triggers exists that early depends on where the
//  player has walked. That is exactly why the watcher below ships alongside: it
//  reports divergence directly instead of leaving it inferred. If the next log
//  shows `corrected 0` and the watcher never reports a mismatch, this mechanism
//  is NOT the cause and the search moves elsewhere - say so rather than
//  quietly assuming the fix worked.
//
//  This correction is safe regardless of whether it is the cause: it only makes
//  the trigger agree with the stub, which stock itself does on every build.
//
//  Stock's own back-pointers are used rather than a search: `stub.trigger` for
//  a shared trigger (:619) and `stub.playertrigger[ entnum ]` for a per-player
//  one (:616), walked with getarraykeys exactly as stock does at :149-153.
// ============================================================================
zmqol_mp40_push_to_live_triggers()
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

zmqol_tomb_no_native_wunderfizz()
{
    //  Deliberately empty - the replacement for BOTH
    //  _zm_perk_random::init_machines and ::start_random_machine.
    //
    //  Both are reached with `level thread ...`, so an empty body just ends
    //  that thread and nothing downstream runs: no unitriggers (no buy
    //  prompt), no ball, no animtree use, no machine_selector, no
    //  machine_think. The six map entities themselves are left alone - see
    //  zmqol_hide_native_wunderfizz for why they must survive.
}

// ============================================================================
//  zmqol_hide_native_wunderfizz  -  make the six vanilla machines invisible
//  WITHOUT deleting them.
//
//  🛑 DO NOT DELETE THESE ENTITIES. zm_tomb_capture_zones.gsc builds a
//  per-zone array out of them (`...zones[str_zone_name].perk_machines_random`,
//  lines 369-377) and sets `.is_locked` on each member as generators come and
//  go:
//
//      enable_random_perk_machines_in_zone()   ->  .is_locked = 0
//      disable_random_perk_machines_in_zone()  ->  .is_locked = 1
//
//  That IS the generator gating the user asked to keep, and the mod's own
//  machines read it back via zmqol_wf_tomb_native_for() in wunderfizz.gsc.
//  Delete these and the gating dies with them - and stock would be iterating
//  an array of deleted entities on every zone change.
//
//  Hidden two ways on purpose: setmodel( "tag_origin" ) is the technique this
//  project has already proven (wunderfizz.gsc uses it on the perk bottle), and
//  hide() is belt and braces so invisibility does not rest on either alone.
//  Verified from the zm_tomb.ff mapents dump: all six are classname
//  "script_model", targetname "random_perk_machine" - both calls are valid.
// ============================================================================
zmqol_hide_native_wunderfizz()
{
    level endon( "end_game" );

    //  Map-placed, so they exist from load - but give the map's own init a
    //  frame to finish before touching them.
    wait 0.05;

    a_native = getentarray( "random_perk_machine", "targetname" );
    n_hidden = 0;

    for ( i = 0; i < a_native.size; i++ )
    {
        if ( !isdefined( a_native[i] ) )
            continue;

        a_native[i] setmodel( "tag_origin" );
        a_native[i] hide();
        n_hidden++;
    }

    println( "[zm_qol] origins wunderfizz: hid " + n_hidden + " of " + a_native.size + " native machine(s) - the mod's own replace them" );
}

zmqol_power_up_all_generators()
{
    if ( is_classic() )
        return;

    flag_wait( "start_zombie_round_logic" );
    wait_network_frame();
    zmqol_capture_every_generator();
}

// ============================================================================
//  zmqol_capture_every_generator  -  the body, split out in v2.11.22
// ============================================================================
//  Was inline in zmqol_power_up_all_generators(). NO POWER NEEDED needs the
//  same work in CLASSIC, where that function returns immediately, so the body
//  moved here and both callers share it. No behaviour change for survival.
// ============================================================================
//  v2.11.24 - it also records WHICH zones it captured, in
//  level.zmqol_last_captured_zones. NO POWER NEEDED is a toggle now and has to
//  be able to release exactly what it took and nothing the player earned. The
//  list is rewritten on every call; survival calls this once and never reads it
//  back, so nothing there changes.
zmqol_capture_every_generator()
{
    level.zmqol_last_captured_zones = [];

    if ( !isdefined( level.zone_capture ) || !isdefined( level.zone_capture.zones ) )
        return 0;

    n_done = 0;

    foreach ( zone in level.zone_capture.zones )
    {
        if ( !isdefined( zone ) )
            continue;

        if ( zone ent_flag( "player_controlled" ) )
            continue;

        zone maps\mp\zm_tomb_capture_zones::set_player_controlled_area();
        zone.n_current_progress = 100;
        zone maps\mp\zm_tomb_capture_zones::generator_state_power_up();
        level setclientfield( zone.script_noteworthy, zone.n_current_progress / 100 );
        level.zmqol_last_captured_zones[ level.zmqol_last_captured_zones.size ] = zone;
        n_done++;
        wait_network_frame();
    }

    return n_done;
}

// ============================================================================
//  zmqol_release_captured_generators  -  NO POWER NEEDED's Origins undo
//
//  🌟 v2.11.24. The exact inverse of the capture above, built out of stock's
//  own pieces, and it touches ONLY the zones this row captured - a generator
//  the player earned before or after is skipped, and so is one the zombies have
//  already taken back.
//
//  🛑 set_zombie_controlled_ZONE(), NOT set_zombie_controlled_AREA(). The
//  _area() wrapper (zm_tomb_capture_zones.gsc:1428) sets
//  flag_set( "generator_lost_to_recapture_zombies" ) on any zone that was
//  player-controlled, and that flag is read at :316 to withhold the
//  "all_zones_captured_none_lost" notify for the rest of the match. The player
//  did not lose a generator to zombies; a cheat row handed one back. So the
//  inner _zone() is called directly and play_pap_anim( 0 ) - the only other
//  thing _area() does - is called beside it.
//
//  What _zone() itself covers, so none of it is reimplemented here: the
//  "player_controlled" ent_flag the perk gate reads, the generator HUD state,
//  the monolith crystal, the perk-machine smoke fx, update_captured_zone_count()
//  (which clears "all_zones_captured", and stock's pack_a_punch_think() at :298
//  is parked on flag_waitopen of exactly that, so Pack-a-Punch disables itself),
//  and disable_perk_machines / _random_perk_machines / _mystery_boxes_in_zone.
//
//  generator_state_turn_off() then plays the generator's own shutdown anim and
//  drops it to state 0 when the anim ends (:1902-:1917), and the progress
//  clientfield goes to 0 so the capture ring empties.
// ============================================================================
zmqol_release_captured_generators()
{
    if ( !isdefined( level.zmqol_no_power_captured_zones ) )
        return 0;

    n_done = 0;

    foreach ( zone in level.zmqol_no_power_captured_zones )
    {
        if ( !isdefined( zone ) )
            continue;

        //  Already lost, or handed back some other way - leave it alone.
        if ( !zone ent_flag( "player_controlled" ) )
            continue;

        zone.n_current_progress = 0;
        zone maps\mp\zm_tomb_capture_zones::set_zombie_controlled_zone( 0 );
        zone maps\mp\zm_tomb_capture_zones::play_pap_anim( 0 );
        zone maps\mp\zm_tomb_capture_zones::generator_state_turn_off();
        level setclientfield( zone.script_noteworthy, 0 );
        n_done++;
        wait_network_frame();
    }

    level.zmqol_no_power_captured_zones = [];
    return n_done;
}

// ============================================================================
//  zmqol_no_power_tomb_extras  -  NO POWER NEEDED's Origins half (v2.11.22)
// ============================================================================
//  🛑 ORIGINS IS THE ONE MAP WHERE THE ROW DID LITERALLY NOTHING.
//  zm_tomb_standard.gsc:20 sets flag "power_on" as soon as the blackscreen
//  lifts, so the root row found it already set and left - while every perk
//  machine stayed locked, because Origins does not use the power flag for them
//  at all. zm_tomb_capture_zones.gsc:117 installs
//      level.custom_perk_validation = ::check_perk_machine_valid
//  and that function (:1854 in _zm_perks.gsc is what calls it) returns the
//  GENERATOR ZONE's own "player_controlled" ent_flag, playing the "power_off"
//  line when it is clear. Generators ARE the power here.
//
//  So the honest way to make the row true on Origins is to capture them, and
//  this uses stock's own capture path - set_player_controlled_area() ->
//  set_player_controlled_zone(), which enables the perk machines, the random
//  perk machines and the mystery boxes in the zone and raises
//  "zone_captured_by_player" exactly as a real capture does.
//
//  Zones already captured are skipped, so flipping the row mid-game costs
//  nothing for generators the player had already earned.
// ============================================================================
//  🌟 v2.11.24 - A LOOP, BECAUSE THE ROW IS A TOGGLE NOW. The generators this
//  row captured are remembered on the way in and released on the way out; ones
//  the player earned are never in that list and are never touched.
zmqol_no_power_tomb_extras()
{
    level endon( "end_game" );

    for ( ;; )
    {
        if ( !( isdefined( level.zmqol_no_power_applied ) && level.zmqol_no_power_applied ) )
            level waittill( "zmqol_no_power_applied" );

        wait_network_frame();

        n_done = zmqol_capture_every_generator();
        level.zmqol_no_power_captured_zones = level.zmqol_last_captured_zones;
        println( "[zm_qol] no_power: Origins - " + n_done + " generator(s) captured, perk machines and boxes unlocked" );

        //  Guarded, not a bare waittill: a notify fired while this thread was
        //  inside its apply block above (the Origins one yields on every
        //  generator) would be missed, and the thread would park here for the
        //  rest of the match. If the row is already off, the restore runs now.
        if ( isdefined( level.zmqol_no_power_applied ) && level.zmqol_no_power_applied )
            level waittill( "zmqol_no_power_reverted" );

        n_back = zmqol_release_captured_generators();
        println( "[zm_qol] no_power: Origins - " + n_back + " generator(s) released, machines locked again. Generators you captured yourself are untouched." );
    }
}

// ============================================================================
//  zmqol_disable_staff_relay_switches
//
//  🛑 The lightning-staff switches stay interactable on survival.
//
//  Reported on Trenches: the switch in the tank-station building by generator 2 still
//  takes input. That is one of the eight elemental-staff relay switches
//  (maps\mp\zm_tomb_quest_elec::electric_puzzle_2_init - relays "bunker",
//  "tank_platform", "start", "elec", "ruins", "air", "ice", "village", built from the
//  map's "puzzle_relay_switch" entities).
//
//  They exist on survival because stock maps\mp\zm_tomb.gsc::main() threads
//  main_quest_init() with no gametype guard, and that threads zm_tomb_quest_elec::main(),
//  which registers a unitrigger per relay in relay_switch_run(). The puzzle they feed is
//  unreachable on a locked-down arena, so the switch is pure noise.
//
//  Why unregister the triggers instead of replaceFunc'ing electric_puzzle_2_init:
//    1. That function is called SYNCHRONOUSLY and UNQUALIFIED from its own file's main()
//       (`electric_puzzle_2_init();`). Threaded same-file calls are reliably redirected by
//       replaceFunc; plain synchronous ones are the case that is still in doubt. No reason
//       to bet a fix on it.
//    2. Skipping the init outright would leave level.electric_relays undefined, and
//       electric_puzzle_2_run/cleanup foreach over it.
//  unregister_unitrigger (maps\mp\zombies\_zm_unitrigger.gsc:133) is the stock teardown:
//  it kills the per-player trigger ents and drops the stub from level._unitriggers, and it
//  no-ops safely on an undefined stub. relay_switch_run() is left blocked forever on a
//  waittill that can no longer fire, which is harmless.
//
//  Deliberately does NOT touch the rest of the staff quest - deleting main_quest_init would
//  leave level.a_elemental_staffs undefined, which maps\mp\zm_tomb_ffotd.gsc:26
//  (update_charger_position, threaded from main_end on every gametype) foreachs over.
//
//  is_classic() gated, so the classic Origins puzzle is untouched.
//
//  🛑 NOT verified in game yet.
// ============================================================================
zmqol_disable_staff_relay_switches()
{
    if ( is_classic() )
        return;

    flag_wait( "start_zombie_round_logic" );
    wait_network_frame();

    if ( !isdefined( level.electric_relays ) )
        return;

    foreach ( s_relay in level.electric_relays )
    {
        if ( isdefined( s_relay.trigger_stub ) )
            maps\mp\zombies\_zm_unitrigger::unregister_unitrigger( s_relay.trigger_stub );
    }
}

// ============================================================================
//  zmqol_remove_survival_ee_props
//
//  🛑 The two remaining bits of full-map Origins furniture that are physically
//  standing inside the survival arenas.
//
//  1. THE TANK. maps\mp\zm_tomb_tank::init() runs on every gametype and sets the
//     vehicle up unconditionally. The tank parks at the tank station, which is
//     generator 2 - i.e. inside the TRENCHES arena - and its route crosses NO
//     MAN'S LAND. Its two call boxes (verified in the shipped mapents) are
//         trig_tank_station_call  ( 377, -2985,   95)  script_noteworthy call_box_village
//         trig_tank_station_call  (-273,  4537, -254)  script_noteworthy call_box_bunkers
//     the first of which is inside the CHURCH arena, where buying it drove the
//     tank straight through the barricade that fences the location off.
//
//     🛑 Why here and not in the loc script, where zm_tomb_loc_church::disable_tank
//     used to do it: the loc scripts run out of zm_tomb_gamemodes::init, which is
//     reached from maps\mp\zombies\_zm::init() - line ~218 of zm_tomb::main(),
//     ELEVEN LINES BEFORE maps\mp\zm_tomb_tank::init() at ~229. Deleting the tank
//     there means tank::init then runs
//         level.vh_tank = getent( "tank", "targetname" );   // undefined
//         level.vh_tank tank_setup();                       // method on undefined
//     Church has been shipping that ordering, which is very likely a silent script
//     error every round. Waiting for start_zombie_round_logic puts us safely after
//     tank::init and after players_on_tank_update/tank_disconnect_paths have taken
//     their path snapshot. Deleting an entity terminates the threads that hold it
//     as self, so tank_setup/tankuseanimtree/tank_discovery_vo all go with it.
//
//     Safe to leave level.enemy_location_override_func pointing at the tank code:
//     enemy_location_override() only dereferences level.vh_tank underneath
//     `if ( isdefined( self.tank_state ) )`, and nothing sets tank_state once the
//     tank is gone.
//
//  2. THE SOUL BOXES. maps\mp\zm_tomb_challenges::init_box_footprints() threads
//     box_footprint_think on all four "foot_box" script_models regardless of
//     gametype - they glow, they open, they absorb souls. Two of the four sit in
//     the EXCAVATION SITE arena (-2138,-300,176) and (667, 640, 66), a third at
//     (2752,-88,151) also in no man's land, the fourth (1324,-3712,302) by the
//     church. The challenge they feed rewards the one inch punch, which is the
//     quest weapon we are removing everywhere else.
//
//     Deleted rather than replaceFunc'd on purpose: init_box_footprints is reached
//     ONLY as a ::function pointer handed to add_stat() inside
//     tomb_challenges_add_stats, which is CLAUDE.md §4 failure mode 3 (pointer
//     bound at registration). Deleting the entities kills the box_footprint_think
//     threads with them and needs no hook at all.
//
//  is_classic() gated - classic Origins keeps its tank and its soul boxes.
//
//  🛑 NOT verified in game yet.
// ============================================================================
zmqol_remove_survival_ee_props()
{
    if ( is_classic() )
        return;

    // ------------------------------------------------------------------------
    //  🛑 ORDERING. This used to wait on start_zombie_round_logic, which was two
    //  frames TOO LATE. maps\mp\zm_tomb_tank::players_on_tank_update() - threaded
    //  on the tank by tank_setup() - opens with exactly that flag_wait and then
    //  immediately does `self thread tank_disconnect_paths()`. The matching
    //  connectpaths() lives on the tank's own thread, so deleting the vehicle
    //  afterwards stranded a disconnected region in the AI path graph with nothing
    //  left alive to reconnect it. The tank is parked off-map at (-8192, -4096, 0)
    //  so it probably severed nothing real, but "probably" is not good enough next
    //  to a reported zombie-pathing bug.
    //
    //  Waiting on level.vh_tank instead lands the deletion in the correct window:
    //  AFTER maps\mp\zm_tomb_tank::init() has run (it is what assigns the var, so
    //  tank_setup() never sees an undefined self - the ordering trap that made this
    //  wrong in zm_tomb_loc_church) and BEFORE start_zombie_round_logic releases
    //  players_on_tank_update. Deleting an entity terminates the threads holding it
    //  as self, so that thread dies still parked on its flag_wait and
    //  tank_disconnect_paths() is never reached.
    //
    //  The timeout keeps this from spinning forever if tank::init is ever skipped;
    //  the getent() calls below are all isdefined-guarded, so giving up early
    //  degrades to "nothing to remove".
    // ------------------------------------------------------------------------
    n_waited = 0;

    while ( !isdefined( level.vh_tank ) && n_waited < 200 )
    {
        n_waited++;
        wait 0.05;
    }

    a_call_boxes = getentarray( "trig_tank_station_call", "targetname" );

    foreach ( trigger in a_call_boxes )
    {
        if ( isdefined( trigger ) )
            trigger delete();
    }

    // The ride-on trigger. It ships parked off-map at (-8192, -4240, 164) with the
    // tank and is carried along with it, so it has to go too or it rides to the
    // station with a vehicle that no longer exists.
    t_use_tank = getent( "trig_use_tank", "targetname" );

    if ( isdefined( t_use_tank ) )
        t_use_tank delete();

    e_tank = getent( "tank", "targetname" );

    if ( isdefined( e_tank ) )
        e_tank delete();

    level.vh_tank = undefined;

    a_boxes = getentarray( "foot_box", "script_noteworthy" );

    foreach ( box in a_boxes )
    {
        if ( isdefined( box ) )
            box delete();
    }
}

// ============================================================================
//  zmqol_open_stock_barriers
//
//  🛑 Zombies walk through Origins' wooden window barriers WITHOUT tearing the
//  boards. Reported at generator 3 on Trenches, 2026-08-02.
//
//  ROOT CAUSE - Origins is the only map that never zone-tags its zbarriers.
//
//  maps\mp\zombies\_zm_zonemgr.gsc:317 only adds a barrier to a zone:
//        if ( targets[j] iszbarrier() && isdefined( targets[j].script_string )
//             && targets[j].script_string == zone_name )
//            zone.zbarriers[zone.zbarriers.size] = targets[j];
//
//  Counted over the shipped mapents (T6-Data-Archive):
//        zm_transit   38 of 38 zbarriers carry script_string
//        zm_prison    22 of 22
//        zm_tomb       0 of 12          <-- every one of them untagged
//
//  So on Origins `zone.zbarriers` is empty for EVERY zone, forever. Three
//  consequences, and the third is the bug:
//    1. maps\mp\zm_tomb.gsc::drop_all_barriers() iterates zone.zbarriers, so on
//       this map it is a COMPLETE NO-OP. Treyarch clearly meant every barrier to
//       be open - Origins has no board-repair minigame - but the code never
//       reaches a single one, which is why the boards are still standing.
//    2. The barrier attack/repair system never engages with them either, so no
//       zombie ever plays a tear animation on one.
//    3. Each barrier ships with a node_negotiation_begin entity at the SAME
//       origin carrying animscript "zm_mantle_over_40" - an ordinary path node,
//       always live, owned by nobody. Zombies mantle straight through six intact
//       boards. Verified on the one 394 units from generator_mid_trench:
//         (696, 1985, -97)  zbarrier_zmcore_BasicWoodBarrier, zbarriernumboards 6
//
//  THE FIX - finish what drop_all_barriers() was trying to do.
//
//  Same two calls stock uses, same 0.05s pacing, but the barriers are reached via
//  the "exterior_goal" structs (which DO target them correctly) instead of the
//  permanently-empty zone arrays. The window then reads as an open hole, matching
//  both Treyarch's evident intent and what the zombies actually do.
//
//  is_classic() gated, so classic Origins is untouched - and note this changes
//  nothing there anyway, since stock already intends all barriers open.
//
//  🛑 THE OTHER OPTION, NOT TAKEN. The barriers could instead be made REAL on
//  survival - assign each one a script_string naming the zone it sits in, before
//  _zm_zonemgr builds its arrays, and Origins survival would get Town/Farm-style
//  boards that zombies tear and players rebuild for points. That is a bigger
//  change: zone membership has to be resolved at runtime by volume containment
//  (the volumes are brush models, so it cannot be tabulated offline), barriers sit
//  on zone boundaries where containment is ambiguous, and registering them alters
//  zombie spawn/goal selection on all four arenas. Worth doing deliberately, not
//  as a side effect of a bug fix.
//
//  🛑 NOT verified in game yet.
// ============================================================================
zmqol_open_stock_barriers()
{
    if ( is_classic() )
        return;

    flag_wait( "start_zombie_round_logic" );
    wait_network_frame();

    a_goals = getstructarray( "exterior_goal", "targetname" );
    n_opened = 0;

    foreach ( s_goal in a_goals )
    {
        if ( !isdefined( s_goal.target ) )
            continue;

        a_targets = getentarray( s_goal.target, "targetname" );

        foreach ( e_barrier in a_targets )
        {
            if ( !isdefined( e_barrier ) || !e_barrier iszbarrier() )
                continue;

            n_pieces = e_barrier getnumzbarrierpieces();

            for ( i = 0; i < n_pieces; i++ )
            {
                e_barrier hidezbarrierpiece( i );
                e_barrier setzbarrierpiecestate( i, "open" );
            }

            n_opened++;
            wait 0.05;
        }
    }

    println( "[zm_qol] BARRIERS opened " + n_opened + " stock zbarriers" );
}

// ============================================================================
//  🛑 v2.14.2 - THE CRAZY PLACE RUNS ORIGINS' OWN GUN LIST, AND THAT IS WHAT
//  STOPS IT CRASHING AT LOAD.
//
//  v2.14.0 boot, 2026-09-06 1:51 PM, crash dump
//  plutonium-r5346-t6zm-2026-09-06_01-51-43.txt:
//      last gsc error message 'unknown weapon 'mp5kqol_upgraded_zm''
//      gsc callstack: maps/mp/zombies/_zm_weapons::include_zombie_weapon
//        maps/mp/zombies/_zm_utility::include_weapon
//        scripts/zm/zm_tomb/zm_tomb::added_weapons
//        scripts/zm/zm_tomb/zm_tomb::init
//  The Crazy Place's own code was NOT at fault - every stage of it logged
//  clean, right through `loc_common::init reached - location=crazy_place`.
//  It died afterwards, here.
//
//  🌟 THE MECHANISM: the weapon precache table ran out, and the Crazy Place is
//  what tips it over. The raw def loaded fine (`Loaded weapon:
//  mp5kqol_upgraded_zm` is in the log and there is NO `Failed to load weapon`
//  line, so this is not ERROR_CATALOGUE §36's 20,480-byte rule) - it is
//  precacheitem() that came back unknown, and two calls later the empty slot
//  was dereferenced.
//
//  WHY THIS LOCATION AND NOT CLASSIC ORIGINS. It is the first Origins survival
//  location with perk machines. _zm_perks::init() returns at _zm_perks.gsc:52
//  (`if ( vending_triggers.size < 1 ) return;`) BEFORE
//  default_vending_precaching(), so the "tomb" survival location skips that
//  batch entirely. With four machines + Pack-a-Punch it runs, and it is TEN
//  extra precacheitem() calls: zombie_knuckle_crack plus nine
//  zombie_perk_bottle_*. Each of those blocks is gated on a level-wide
//  level.zombiemode_using_* flag that Origins sets for every perk it supports,
//  regardless of which machines this particular location has, so there is no
//  way to trim them without breaking the perks.
//
//  So the room has to pay for itself out of the weapon list - and the gate is
//  drawn where it actually buys something. MEASURED, not assumed: of the twenty
//  pairs this function adds, THIRTEEN are precached on every map regardless by
//  quality_of_life.gsc's own init() (72 unconditional precacheitem calls) or by
//  zmqol_wallbuy_box_add()'s internal precache. Holding those back would delete
//  a gun from the box and free NOTHING. Only SEVEN pairs are precached here and
//  nowhere else - saritchqol, barretm82qol, mp5kqol, tar21qol, saiga12qol,
//  judgeqol, usrpg - so those are the seven the gate skips, freeing FOURTEEN
//  slots against a ten-slot problem.
//
//  🌟 WHY FOURTEEN IS PROVABLY ENOUGH, without knowing the ceiling: classic
//  Origins boots today at demand D. The Crazy Place is D + 10 and crashes.
//  D + 10 - 14 = D - 4, four below a configuration that demonstrably loads.
//
//  Classic Origins is untouched: the gate only fires on this one location, so
//  the map every other mode runs is byte-for-byte what it was.
//
//  ⚠️ WHAT THE PLAYER LOSES, said plainly: inside the Crazy Place the mystery
//  box is missing seven of the mod's added guns (the Saritch, the Barrett M82,
//  the MP5K, the MTAR, the Saiga-12, the Judge and the RPG). The other thirteen
//  are still there. The user chose this lane over the alternatives, 2026-09-06,
//  after being told the trade.
//
//  🛑 IF THE ROOT PRECACHE LIST EVER CHANGES, RE-MEASURE THIS SEVEN. A gun that
//  stops being precached by the root but stays out of the gate would silently
//  make the saving smaller, and the crash would come back.
//
//  🛑 THE CLIENT MUST SKIP THE SAME TWENTY, and zm_tomb.csc::include_weapons()
//  does, under the same test. This is not optional bookkeeping: the client's
//  include_weapon (clientscripts\mp\zombies\_zm_weapons.csc:138) ends in
//  addzombieboxweapon( weapon, getweaponmodel( weapon ), ... ), a model lookup
//  on a weapon nothing precached - which is exactly the as50_zm client crash
//  v2.9.4 documents in zm_expanded.csc. Change one list, change both.
//
//  📝 knife_ballistic_* STAYS on this location. It costs two slots, it is not a
//  box weapon (no add_zombie_weapon, and the client list never had it), and it
//  exists solely so zmqol_whoswho_knife_name()'s guard passes - dropping it
//  would quietly take the ballistic knife off Who's Who here.
// ============================================================================
added_weapons()
{
    if (level.script == "zm_tomb")
	{
        include_weapon( "uzi_zm" );
        include_weapon( "uzi_upgraded_zm", 0 );
        add_zombie_weapon( "uzi_zm", "uzi_upgraded_zm", &"ZOMBIE_WEAPON_UZI", 1500, "wpck_smg", "", undefined );

        include_weapon( "ak47_zm" );
        include_weapon( "ak47_upgraded_zm", 0 );
        add_zombie_weapon( "ak47_zm", "ak47_upgraded_zm", &"ZOMBIE_WEAPON_AK47", 500, "wpck_mg", "", undefined, 1 );

        include_weapon( "minigun_alcatraz_zm" );
        include_weapon( "minigun_alcatraz_upgraded_zm", 0 );
        add_zombie_weapon( "minigun_alcatraz_zm", "minigun_alcatraz_upgraded_zm", &"ZOMBIE_WEAPON_RPD", 50, "wpck_mg", "", undefined, 1 );

        include_weapon( "hk416_zm" );
        include_weapon( "hk416_upgraded_zm", 0 );
        add_zombie_weapon( "hk416_zm", "hk416_upgraded_zm", &"ZOMBIE_WEAPON_HK416", 100, "", "", undefined );

        include_weapon( "rnma_zm" );
        include_weapon( "rnma_upgraded_zm", 0 );
        add_zombie_weapon( "rnma_zm", "rnma_upgraded_zm", &"ZOMBIE_WEAPON_RNMA", 50, "pickup_six_shooter", "", undefined, 1 );

        include_weapon( "an94_zm" );
        include_weapon( "an94_upgraded_zm", 0 );
        add_zombie_weapon( "an94_zm", "an94_upgraded_zm", &"ZOMBIE_WEAPON_AN94", 1200, "", "", undefined );

        include_weapon( "lsat_zm" );
        include_weapon( "lsat_upgraded_zm", 0 );
        add_zombie_weapon( "lsat_zm", "lsat_upgraded_zm", &"ZOMBIE_WEAPON_LSAT", 2000, "wpck_lsat", "", undefined, 1 );

        include_weapon( "svu_zm" );
        include_weapon( "svu_upgraded_zm", 0 );
        add_zombie_weapon( "svu_zm", "svu_upgraded_zm", &"ZOMBIE_WEAPON_SVU", 1000, "wpck_svuas", "", undefined );

        include_weapon( "xm8_zm" );
        include_weapon( "xm8_upgraded_zm", 0 );
        add_zombie_weapon( "xm8_zm", "xm8_upgraded_zm", &"ZOMBIE_WEAPON_XM8", 50, "wpck_m8a1", "", undefined, 1 );

        include_weapon( "rpd_zm" );
        include_weapon( "rpd_upgraded_zm", 0 );
        add_zombie_weapon( "rpd_zm", "rpd_upgraded_zm", &"ZOMBIE_WEAPON_RPD", 50, "wpck_rpd", "", undefined, 1 );

      // ======================================================================
      //  🛑 v2.14.4 - THESE SEVEN PAIRS ARE HELD BACK ON ALL OF ORIGINS
      //  NOW, NOT JUST THE CRAZY PLACE, AND CLASSIC ORIGINS IS WHY.
      //
      //  Boot 2026-09-06 6:41 PM, CLASSIC Origins (location=tomb), crash dump
      //  plutonium-r5346-t6zm-2026-09-06_06-41-43.txt:
      //      last gsc error message 'unknown weapon 'mp5kqol_upgraded_zm''
      //      gsc callstack: maps/mp/zombies/_zm_weapons::include_zombie_weapon
      //        maps/mp/zombies/_zm_utility::include_weapon
      //        scripts/zm/zm_tomb/zm_tomb::added_weapons
      //  Same weapon, same stack and the same position in this list as the
      //  v2.14.0 Crazy Place crash. The precache table runs out at EXACTLY the
      //  same include on both locations.
      //
      //  🛑 SO v2.14.2'S STATED MECHANISM WAS WRONG, AND IS CORRECTED HERE.
      //  It blamed the Crazy Place's four perk machines: _zm_perks::init()
      //  returns at :52 before default_vending_precaching() when a location has
      //  no vending triggers, so a machine-less survival location skips ten
      //  precacheitem calls. That much is true - but CLASSIC Origins has
      //  machines too, pays the same ten, and was over the ceiling all along.
      //  Measured, not inferred: maps\mp\zm_tomb_classic.gsc and
      //  maps\mp\zm_tomb_craftables.gsc contain ZERO precacheitem and ZERO
      //  include_weapon calls, so classic and the Crazy Place demand the same
      //  weapon slots to the slot. v2.14.2's "classic Origins boots today at
      //  demand D" was never measured; this boot disproves it.
      //
      //  The Crazy Place got past this point once the fourteen slots were
      //  freed, so the same fourteen carry classic. Classic died on include #6
      //  of this block - five slots in - so NINE is the measured minimum and
      //  fourteen leaves five spare.
      //
      //  ⚠️ WHAT THE PLAYER LOSES, PLAINLY: on Origins, every location, the
      //  box no longer offers the Saritch, the Barrett M82, the MP5K, the MTAR,
      //  the Saiga-12, the Judge or the RPG. The other thirteen added pairs
      //  stay and every other map is untouched. The alternative was a map that
      //  does not load at all. Keeping the seven means finding nine slots
      //  elsewhere on this map first, and the only place left is the root
      //  script's own precache block - the stock saritch / barretm82 / m16
      //  copies it precaches are dead weight on Origins (zmqol_tomb_weapon()
      //  swaps the m16 out, and the box registers the qol copies of the other
      //  two) but they are worth eight slots, one short of nine.
      //
      //  🛑 zm_tomb.csc::include_weapons() HOLDS BACK THE SAME SEVEN. Its
      //  include_weapon ends in addzombieboxweapon( w, getweaponmodel( w ), ...)
      //  - a model lookup on a weapon nothing precached, which is the as50_zm
      //  client crash. Change one list, change both.
      // ======================================================================
        println( "[zm_qol] origins: added_weapons holds back 7 pair(s) - 14 precache slot(s) freed, ALL locations (v2.14.4)" );

        // ====================================================================
        //  🛑 THESE TWO PAIRS STAY ON EVERY LOCATION, THE CRAZY PLACE INCLUDED,
        //  and skipping them would cost nothing while breaking the box.
        //
        //  Origins' private M16 and Olympia are ALREADY precached on this map by
        //  the root script - quality_of_life.gsc::zmqol_wallbuy_box_add() calls
        //  precacheitem() itself and zmqol_tomb_weapon() swaps m16_zm ->
        //  m16qol_zm / rottweil72_zm -> rottweil72qol_zm there. So holding them
        //  back here frees ZERO slots.
        //
        //  What it WOULD do is desync the box: the server would still have them
        //  registered (from that root call) while zm_tomb.csc's matching skip
        //  removed the client's only include of the qol names - zm_expanded.csc's
        //  client twin includes the STOCK m16_zm / rottweil72_zm, not these. A
        //  weapon the server can hand out that the client never included is a box
        //  result the client cannot render.
        //  📝 m1911 is the third name in that root list and does NOT need this,
        //  because zm_expanded.csc's twin includes m1911_zm by its own name.
        // ====================================================================
        include_weapon( "m16qol_zm" );
        include_weapon( "m16qol_upgraded_zm", 0 );
        add_zombie_weapon( "m16qol_zm", "m16qol_upgraded_zm", &"ZOMBIE_WEAPON_M16", 1200, "burstrifle", "", undefined );

        include_weapon( "rottweil72qol_zm" );
        include_weapon( "rottweil72qol_upgraded_zm", 0 );
        add_zombie_weapon( "rottweil72qol_zm", "rottweil72qol_upgraded_zm", &"ZOMBIE_WEAPON_ROTTWEIL72", 500, "shotgun", "", undefined );

        include_weapon( "m1911_zm" );
        include_weapon( "m1911_upgraded_zm", 0);
        add_zombie_weapon( "m1911_zm", "m1911_upgraded_zm", &"ZOMBIE_WEAPON_M1911", 50, "", "", undefined );

        // ====================================================================
        //  v2.9.13 - THE BALLISTIC KNIFE, SO WHO'S WHO CAN REVIVE YOU HERE.
        //
        //  README known issue: Who's Who handed out no ballistic knife on
        //  Origins, so the revive-your-own-body trick did not work. The cause
        //  was never scripting - `Unlinker --list` over retail zm_tomb.ff finds
        //  ZERO knife_ballistic assets of any kind. The gun simply is not on
        //  this map.
        //
        //  mod_ballisticknife.zone now makes mod.ff own the weapon and its 4
        //  models / 17 anims / 6 materials / fx, taken verbatim from zm_buried
        //  (whose copy is md5-identical to zm_transit's and zm_highrise's, so
        //  no map that already had it can be changed). mod.ff loads ahead of
        //  every map, so the asset exists here now - these two lines are what
        //  make the map actually PRECACHE it.
        //
        //  🛑 NO add_zombie_weapon(). This must NOT enter the mystery box; it
        //  exists solely so zmqol_whoswho_knife_name()'s guard
        //  (level.zombie_include_weapons["knife_ballistic_upgraded_zm"]) passes.
        //  That guard was already dynamic rather than a hard-coded map list,
        //  which is why no give-logic changed for this.
        //
        //  📝 Mob of the Dead is deliberately NOT given this: it has no Who's
        //  Who at all, so there would be nothing to hand a knife to.
        // ====================================================================
        include_weapon( "knife_ballistic_zm", 0 );
        include_weapon( "knife_ballistic_upgraded_zm", 0 );
    }
}

// Origins weapon-dig fix: if you dig up a weapon whose Pack-a-Punched version
// you already hold, give max ammo instead of swapping. (Merged from the old
// standalone Originspatch2.0.gsc so it only loads on Origins - no unresolved
// externals on other maps.)
custom_swap_weapon( str_weapon, e_player )
{
    if ( isdefined( level.zombie_weapons[str_weapon] ) && isdefined( level.zombie_weapons[str_weapon].upgrade_name ) )
    {
        upgraded_weapon = level.zombie_weapons[str_weapon].upgrade_name;

        if ( e_player hasweapon( upgraded_weapon ) )
        {
            e_player givemaxammo( upgraded_weapon );
            return;
        }
    }

    str_current_weapon = e_player getcurrentweapon();

    if ( str_weapon == "claymore_zm" )
    {
        if ( !e_player hasweapon( str_weapon ) )
        {
            e_player thread maps\mp\zombies\_zm_weap_claymore::show_claymore_hint( "claymore_purchased" );
            e_player thread maps\mp\zombies\_zm_weap_claymore::claymore_setup();
            e_player thread maps\mp\zombies\_zm_audio::create_and_play_dialog( "weapon_pickup", "grenade" );
        }
        else
        {
            e_player givemaxammo( str_weapon );
        }

        return;
    }

    if ( is_player_valid( e_player ) && !e_player.is_drinking && !is_placeable_mine( str_current_weapon ) && !is_equipment( str_current_weapon ) && level.revive_tool != str_current_weapon && str_current_weapon != "none" && !e_player hacker_active() )
    {
        if ( !e_player hasweapon( str_weapon ) )
        {
            e_player maps\mp\zm_tomb_dig::take_old_weapon_and_give_new( str_current_weapon, str_weapon );
            return;
        }
        else
        {
            e_player givemaxammo( str_weapon );
        }
    }
}

// Origins native "loose change" reward (prone at a perk machine): stock's own
// maps\mp\zm_tomb_ee_side::check_for_change with two changes and no others -
// it pays 100 instead of 25, and it honours the PERK BONUS POINTS switch.
// (Moved here from perkbonuspoints.gsc - it must live in this Origins-only map
// script or the zm_tomb_ee_side reference is unresolved on other maps.)
//
// 🛑 v1.99.61 - THE SWITCH HAD TO REACH THIS FUNCTION TOO. User, 2026-08-18:
// *"the base black ops 2 zombies origins is the only map to give you points, it
// gives you 25 points when you prone in front of machines but my mod makes it
// 100 so just make sure if you do set it to disabled in settings it also
// disables the 25 points from the base game"*. Origins is the one map where the
// mod's own detector never runs, so gating only quality_of_life.gsc would have
// left Origins paying regardless.
//
// The dvar is read at award time, not at thread start, so flipping the row
// mid-match works in both directions. When it is off the loop keeps waiting
// instead of returning - a machine skipped while the switch was off is still
// claimable once it goes back on, and stock's own "pay once, then break"
// remains exactly intact.
origins_change_patch()
{
    while ( true )
    {
        self waittill( "trigger", e_player );

        if ( e_player getstance() == "prone" && getdvarintdefault( "perk_bonus_points", 1 ) )
        {
            e_player maps\mp\zombies\_zm_score::add_to_player_score( 100 );
            play_sound_at_pos( "purchase", e_player.origin );
            break;
        }

        wait 0.1;
    }
}

// ============================================================================
//  qol_check_solo_status  (replaces maps\mp\zm_tomb_utility::check_solo_status)
//
//  🛑 A one-player game on Plutonium was getting CO-OP rules. Stock:
//
//      if ( getnumexpectedplayers() == 1 && ( !sessionmodeisonlinegame() || !sessionmodeisprivate() ) )
//          level.is_forever_solo_game = 1;
//
//  On retail the session clause is what separates "alone on the couch" from
//  "online private lobby my friends can still join". Plutonium runs EVERY game
//  - including the Solo entry - as an online private match, so both builtins
//  return true, the OR is false, and the flag is never set no matter how the
//  game was started. Origins then ran the whole map on co-op rules.
//
//  What that actually broke, all from stock (nothing here is a guess):
//    - zm_tomb_utility::zone_capture_powerup - the start-bunker reward chest
//      after the first generator gives reward_powerup_double_points in solo and
//      reward_powerup_zombie_blood in co-op. The zombie blood the user got IS
//      this branch.
//    - zm_tomb_utility::adjustments_for_solo - the solo door/debris price cut
//      and the 750-point Beretta/870 never applied.
//    - zm_tomb_capture_zones::get_recapture_zombies_needed - 6 instead of 4.
//    - zm_tomb_capture_zones::get_capture_rate - the slower co-op rate, scaled
//      by (players in zone / players total), instead of rate_capture_solo.
//    - _zm_ai_mechz - solo has its own Mechz behaviour.
//
//  Fix: keep stock's player-count test exactly, drop only the session-mode
//  clause that Plutonium always fails. getnumexpectedplayers() is valid at this
//  call site - stock reads it here itself. Evaluated once, never re-checked,
//  which is what "forever solo" means in stock too.
// ============================================================================
//  v1.62.0: `<= 1`, matching zm_prison's copy. Origins already reported
//  expected=1 in a real boot log, so this changes nothing here today - it is
//  kept identical to Mob's on purpose, so the two cannot drift and so Origins
//  is covered if its call site ever resolves the count as late as Mob's does.
//  See the long note above zm_prison.gsc::qol_check_solo_status.
qol_check_solo_status()
{
    n_expected = getnumexpectedplayers();

    if ( n_expected <= 1 )
        level.is_forever_solo_game = 1;
    else
        level.is_forever_solo_game = 0;

    println( "[zm_qol] solo status: expected=" + n_expected + " connected=" + getnumconnectedplayers() + " is_forever_solo_game=" + level.is_forever_solo_game );

    //  ========================================================================
    //  v2.13.0 - THE ONE CO-OP QUESTION THIS MAP CANNOT ANSWER OFFLINE, SO IT
    //  ASKS THE LOG INSTEAD OF GUESSING.
    //
    //  The `<= 1` above differs from stock's `== 1` only when the engine
    //  reports ZERO expected players. The v1.62.0 note thirty lines up says
    //  Origins has never been seen to do that - it reported expected=1 - but
    //  that reading is from a SOLO boot, and nobody has ever read this line
    //  out of a co-op one. If a Mods-menu co-op game also resolves to 0, this
    //  hands a two-player match the solo rules, and on THIS map that means
    //  exactly the five stock behaviours the v1.62.0 note lists:
    //    - zone_capture_powerup gives the solo reward chest (double points
    //      rather than zombie blood) after the first generator
    //    - adjustments_for_solo applies the solo door/debris prices and the
    //      750-point Beretta/870
    //    - get_recapture_zombies_needed returns 4 instead of 6
    //    - get_capture_rate uses rate_capture_solo instead of the co-op rate
    //    - _zm_ai_mechz runs its solo Panzer behaviour
    //  Wrong, but playable - none of it is a script error.
    //
    //  IT IS DELIBERATELY NOT PRE-EMPTIVELY "FIXED". This value is read once
    //  and never re-checked, which is what "forever solo" means in stock too,
    //  and flipping it on a guess would break the solo case that is currently
    //  correct on this map. One co-op boot and this log line settles it.
    //  ========================================================================
    if ( n_expected <= 1 )
        println( "[zm_qol] *** solo rules are ON. If this is a CO-OP game, this line is the bug - report it with the two counts above." );
}

//  Stock maps\mp\zombies\_zm_ai_mechz::mechz_explode, unchanged except for the
//  seventh radiusdamage argument. See the note in main() for why it is there.
zmqol_mechz_explode( str_tag, death_origin )
{
    wait 2.0;
    v_origin = self gettagorigin( str_tag );
    level notify( "mechz_exploded", v_origin );
    playsoundatposition( "zmb_ai_mechz_death_explode", v_origin );
    playfx( level._effect["mechz_death"], v_origin );
    radiusdamage( v_origin, 128, 100, 25, undefined, "MOD_GRENADE_SPLASH", "frag_grenade_zm" );
    earthquake( 0.5, 1.0, v_origin, 256 );
    playrumbleonposition( "grenade_rumble", v_origin );
    level notify( "mechz_killed", death_origin );
}

// ============================================================================
//  ORIGINS' OWN round_spawn_failsafe — THE SECOND ONE, PATCHED      (v2.14.5)
// ----------------------------------------------------------------------------
//  User, 2026-09-06, playing Origins with NO BLEEDOUT PATCH set to ENABLED:
//  *"a zombie just bled out on its own from me getting far away from it,
//  causing the round to end due to it being the last zombie"*.
//
//  🌟 THE CAUSE, MEASURED. Origins does not use the shared failsafe alone.
//  maps\mp\zm_tomb::main() line 164 does
//      level._zombies_round_spawn_failsafe = ::tomb_round_spawn_failsafe;
//  and _zm_gametype::custom_spawn_init_func array_threads that pointer onto
//  every zombie spawner. So each zombie runs TWO failsafes: the shared one
//  (patched in quality_of_life.gsc since v2.2.0) and this map-local copy, which
//  is stock's 30-second loop rewritten to **15 seconds** with its own
//  below-world floor of -3000. The 15-second one always wins, and it was never
//  patched — the live log showed `no_bleedout "1"` and not one SUPPRESSED line.
//
//  🛑 WHY NOT JUST RE-POINT THE POINTER. Both the map's assignment (:164) and
//  the read (`_zm::init` → `_zm_spawner::init` → `custom_spawn_init_func`) happen
//  inside stock's own zm_tomb::main(), in that order, with nothing of this mod's
//  running in between — mod main() is earlier, mod init() is later. The race
//  cannot be won, so the mod does not try.
//
//  The real switch-off is quality_of_life.gsc::zmqol_nb_sync_ignore_flag(),
//  which sets stock's own `self.ignore_round_spawn_failsafe` from the shared
//  copy before this one starts (run_spawn_functions opens with
//  `waittillframeend`). This replacement covers what that cannot: zombies that
//  never go through _zm::round_spawning() and so never get the shared failsafe
//  at all — Origins' capture-zone spawner is the live example.
//
//  📝 Body is maps\mp\zm_tomb.gsc:592 verbatim — 15s wait, -3000 floor, the
//  brutus exclusion Treyarch left in a map with no Brutus — with the same one
//  branch added that the shared copy has.
// ============================================================================
zmqol_tomb_round_spawn_failsafe()
{
    self endon( "death" );
    prevorigin = self.origin;

    //  v2.14.6 - the zombies that never run the shared copy still get the
    //  death-attribution line. See quality_of_life.gsc::zmqol_nb_death_watch().
    self scripts\zm\quality_of_life::zmqol_nb_watch_death_once();

    if ( !isdefined( level.zmqol_nb_said_tomb ) )
    {
        level.zmqol_nb_said_tomb = 1;
        println( "[zm_qol] no_bleedout: Origins 15s failsafe REPLACEMENT is live - row=" + getdvarintdefault( "no_bleedout", 0 ) );
    }

    while ( true )
    {
        if ( isdefined( self.ignore_round_spawn_failsafe ) && self.ignore_round_spawn_failsafe )
            return;

        wait 15;

        if ( isdefined( self.is_inert ) && self.is_inert )
            continue;

        if ( isdefined( self.lastchunk_destroy_time ) )
        {
            if ( gettime() - self.lastchunk_destroy_time < 8000 )
                continue;
        }

        //  🛑 KEPT, exactly as the shared copy keeps its own: a zombie under the
        //  map cannot be shot, so suppressing this would end the round forever.
        if ( self.origin[2] < -3000 )
        {
            if ( isdefined( level.put_timed_out_zombies_back_in_queue ) && level.put_timed_out_zombies_back_in_queue && !flag( "dog_round" ) && !( isdefined( self.isscreecher ) && self.isscreecher ) )
            {
                level.zombie_total++;
                level.zombie_total_subtract++;
                //  v2.14.7 - stock's put-back already happened here, so
                //  zmqol_nb_requeue() must not count this one a second time.
                self.zmqol_nb_counted = 1;
            }

            println( "[zm_qol] no_bleedout: BELOW-WORLD kill (Origins, z=" + int( self.origin[2] ) + ") - kept on purpose, round " + level.round_number );
            self dodamage( self.health + 100, ( 0, 0, 0 ) );
            break;
        }

        if ( distancesquared( self.origin, prevorigin ) < 576 )
        {
            //  🛑 THE PATCH — the same one the shared copy carries.
            if ( getdvarintdefault( "no_bleedout", 0 ) )
            {
                if ( !isdefined( self.zmqol_nb_stuck ) )
                    self.zmqol_nb_stuck = 0;

                self.zmqol_nb_stuck++;

                if ( !isdefined( self.zmqol_nb_said ) )
                {
                    self.zmqol_nb_said = 1;
                    println( "[zm_qol] no_bleedout: SUPPRESSED Origins playspace-timeout kill, round " + level.round_number );
                }

                //  Five stuck passes here is ~75 seconds, not the shared copy's
                //  ~2.5 minutes, because this loop is half as long. Same rule:
                //  never damaged, only moved somewhere the player can reach it.
                if ( self.zmqol_nb_stuck >= 5 && getdvarintdefault( "no_bleedout_relocate", 1 ) && self scripts\zm\quality_of_life::zmqol_no_bleedout_can_relocate() )
                {
                    if ( self scripts\zm\quality_of_life::zmqol_relocate_zombie( 0 ) )
                        self.zmqol_nb_stuck = 0;
                }

                prevorigin = self.origin;
                continue;
            }

            if ( isdefined( level.put_timed_out_zombies_back_in_queue ) && level.put_timed_out_zombies_back_in_queue && !flag( "dog_round" ) )
            {
                if ( !self.ignoreall && !( isdefined( self.nuked ) && self.nuked ) && !( isdefined( self.marked_for_death ) && self.marked_for_death ) && !( isdefined( self.isscreecher ) && self.isscreecher ) && ( isdefined( self.has_legs ) && self.has_legs ) && !( isdefined( self.is_brutus ) && self.is_brutus ) )
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
//  THE GIANT ROBOT'S FOOT — the other thing that kills zombies with no player
//  anywhere near them                                               (v2.14.6)
// ----------------------------------------------------------------------------
//  Origins ships more than one script that kills a zombie by itself, and the
//  two failsafes were only the timers. This is the other one that runs in
//  ordinary play from round 1: maps\mp\zm_tomb_giant_robot::activate_kill_trigger
//  walks every zombie within 600 units of the foot trigger, marks each one that
//  is touching it (`zombie.marked_for_death = 1`, `setgoalpos( own origin )`)
//  and hands the list to zombie_stomp_death(), which does
//      zombie dodamage( zombie.health, zombie.origin, robot );
//  The attacker is the robot, not a player, so under the user's own definition
//  of the row - *"they have to be actually killed by the player"* - a stomp
//  that takes the last zombie of a round is exactly the reported bug.
//
//  🛑 THIS IS NOT YET PROVEN TO BE WHAT KILLED THE ROUND-2 ZOMBIE, and the
//  banner over zmqol_nb_death_watch() in quality_of_life.gsc says why the proof
//  is still missing. It IS proven to be a kill with no player attacker, which
//  the row promises to stop, so it is suppressed on the same switch. The death
//  watcher will name the killer in the next log either way.
//
//  What suppression costs: with the row ON a zombie standing under the foot
//  walks out from under it instead of being crushed. Nothing else changes - the
//  stomp fx, the sound, the screen shake and the player-crush are all in other
//  functions and are untouched, and `marked_for_death` is cleared so the rest of
//  the AI stops treating the zombie as a corpse. Its frozen goal repairs itself:
//  _zm_ai_basic::find_flesh() is a while(1) that re-targets every pass.
//
//  📝 The `else` branch is maps\mp\zm_tomb_giant_robot.gsc:923 verbatim.
// ============================================================================
zmqol_tomb_zombie_stomp_death( robot, a_zombies_to_kill )
{
    if ( getdvarintdefault( "no_bleedout", 0 ) )
    {
        n_spared = 0;

        for ( i = 0; i < a_zombies_to_kill.size; i++ )
        {
            zombie = a_zombies_to_kill[i];

            if ( !isdefined( zombie ) || !isalive( zombie ) )
                continue;

            zombie.marked_for_death = undefined;
            n_spared++;
        }

        if ( !isdefined( level.zmqol_nb_stomp_round ) || level.zmqol_nb_stomp_round != level.round_number )
        {
            level.zmqol_nb_stomp_round = level.round_number;
            println( "[zm_qol] no_bleedout: SUPPRESSED giant-robot stomp - " + n_spared + " zombie(s) spared, round " + level.round_number );
        }

        return;
    }

    n_interval = 0;

    for ( i = 0; i < a_zombies_to_kill.size; i++ )
    {
        zombie = a_zombies_to_kill[i];

        if ( !isdefined( zombie ) || !isalive( zombie ) )
            continue;

        zombie dodamage( zombie.health, zombie.origin, robot );
        n_interval++;

        if ( n_interval >= 4 )
        {
            wait_network_frame();
            n_interval = 0;
        }
    }
}
