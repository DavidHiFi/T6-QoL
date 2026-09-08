// zm_qol: a bogus "#include maps\mp_utility;" (missing the \ before _utility) used to sit
// here. It produced a harmless-looking "Could not load scriptparsetree maps/mp_utility.gsc"
// in the log. It is DELETED rather than corrected, because line 7 below already includes
// the real maps\mp\_utility - correcting it instead produced
// "[ERROR]:compiler: duplicated include file maps/mp/_utility", which is FATAL and took
// the whole map down. In T6 a duplicate #include is a compile error, not a warning.
#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_weapons;
#include maps\mp\zm_transit;
#include maps\mp\zm_transit_standard_station;
#include maps\mp\_utility;
// zm_qol v2.8.1: "#include maps\mp\zombies\_zm_race_utility;" used to sit here. That
// script does not exist in ANY of the 132 retail fastfiles (Unlinker --list over the
// whole zone\all set) nor in mod.ff, so it resolved to nothing and printed
// "Could not load scriptparsetree maps/mp/zombies/_zm_race_utility.gsc" on every
// TranZit load - see the user's 29 Aug console_zm.log lines 1076 and 5281. Nothing in
// this file called through it (checked: no unresolved bare calls remain). DELETED, not
// corrected, for the same reason as the maps\mp_utility line above: there is no real
// script to correct it to.
#include maps\mp\zombies\_zm_magicbox;
#include maps\mp\gametypes_zm\_zm_gametype;
#include maps\mp\zombies\_zm_perks;

main()
{
    replaceFunc( maps\mp\zm_transit_standard_station::main, ::main_o );
    replaceFunc( maps\mp\zm_transit_lava::zombie_exploding_death, ::zombie_exploding_death );
    replaceFunc( maps\mp\zm_transit_lava::lava_damage_init, ::qol_lava_damage_init );

    //  v2.9.9 - JET GUN AS A REAL WEAPON, part 2 of the give routing (part 1 is
    //  the onbought hook in zmqol_jetgun_real_slot()). This catches every OTHER
    //  route that would hand the jet gun out as equipment: _zm_weapons::
    //  weapon_give() calls equipment_give QUALIFIED at :2344 (so .give and any
    //  scripted give land here), and so does the wallbuy path at :2080. The
    //  crafting-table claim does NOT reach equipment_give through a catchable
    //  call (equipment_buy calls it unqualified, same file - replaceFunc
    //  failure mode 1), which is exactly why the claim is intercepted at the
    //  buildable's own .onbought hook instead, one level higher.
    replaceFunc( maps\mp\zombies\_zm_equipment::equipment_give, ::zmqol_equipment_give );

    //  v2.11.26 - part 3 of the jet gun slot work, and the half that was still
    //  missing: what happens when a player HOLDING the jet gun is handed some
    //  OTHER weapon. See the banner above zmqol_weapon_give().
    replaceFunc( maps\mp\zombies\_zm_weapons::weapon_give, ::zmqol_weapon_give );

    // --- custom survival start locations: adds Diner, Power Station, Tunnel ---
    // Map-specific, so it lives here and not in quality_of_life.gsc (AI_CONTEXT rule 2).
    replaceFunc( maps\mp\zm_transit_gamemodes::init, scripts\zm\replaced\zm_transit_gamemodes::init );

    // Creates + enables zone_amb_tunnel (Tunnel) and the five power-station zones
    // (Power), each gated on its own start location. Without it every Tunnel/Power
    // respawn point stays locked and the player is dumped at the Bus Depot default
    // spawn and killed instantly - see the header comment in
    // scripts\zm\replaced\zm_transit.gsc for the full chain.
    replaceFunc( maps\mp\zm_transit::transit_zone_init, scripts\zm\replaced\zm_transit::transit_zone_init );

    // --- Diner buildable riot shield (server half; client twin in zm_transit.csc) ---
    zmqol_diner_shield_init();

    electric_door_changes();

    if (is_not_busdepot())
	{
	   return;
	}
}


// ============================================================================
//  zm_qol: THE DINER BUILDABLE RIOT SHIELD                         (v1.66.0)
//
//  User, 2026-08-11: *"add the buildable shield to diner, it already exists in
//  the tranzit map, just remove the tarp on the buildable table in the building
//  and add the 2 parts spawns just like the regular tranzit."*
//
//  It is more than the tarp, and every claim below is read out of the shipped
//  map or the stock scripts, not assumed.
//
//  WHAT SURVIVAL ALREADY HAS (Unlinker --include-assets mapents zm_transit.ff):
//    * all 3 dolly structs `riotshield_zm_t6_wpn_zmb_shield_dolly` at
//      (-6118.7,-7869.1,0) (-6467,-7727,0) (-5768.9,-7872.6,1.4)
//    * all 3 door structs `riotshield_zm_t6_wpn_zmb_shield_door` at
//      (-4486,-7980,-8.5) (-4995,-7824,-42) (-4404.5,-7740.5,-1.4)
//      Neither carries script_gameobjectname, so the gamemode filter never
//      touches them - the parts have been sitting there the whole time. And
//      generate_zombie_buildable_piece() looks them up by exactly
//      `buildablename + "_" + modelname`, which is those targetnames.
//    * the riot shield WEAPON and its equipment handling: zm_transit.gsc:314
//      calls include_equipment_for_level() from main() with NO gamemode gate,
//      and that includes "riotshield_zm" (:1630). Core _zm_equipment::init()
//      runs from _zm.gsc:154 on every map and mode.
//
//  WHAT IT DOES NOT HAVE, and why:
//    1. zm_transit_buildables::include_buildables() / ::init_buildables() are
//       called from zm_transit_classic.gsc:33-34 and NOWHERE ELSE, so in
//       survival no riotshield buildable is defined at all.
//    2. The bench trigger `riotshield_zm_buildable_trigger` and the shield on
//       the table `buildable_riotshield` both carry
//       script_gameobjectname "zclassic", and _zm_gametype.gsc:110
//       game_objects_allowed() calls entity delete() on a mismatch. Handled in
//       zm_transit_loc_diner.gsc, which runs early enough - see there.
//
//  🛑 ONLY THE SHIELD IS REGISTERED, not stock's include_buildables(). That
//  would drag in the jetgun, turbine, turret, electric trap, power switch and
//  the buildable Pack-a-Punch, whose triggers are all zclassic-deleted here -
//  parts with nowhere to go.
//
//  WHY level.init_buildables AND NOT A DIRECT CALL. Core
//  _zm_buildables::init() (_zm.gsc:153) does the resets - buildable_piece_count
//  0, buildable_stubs [], buildablepickups [] - and THEN calls
//  [[ level.init_buildables ]](). Registering before that point would have the
//  resets wipe it. Nothing in the 2,093-file stock dump ever ASSIGNS that
//  pointer, only reads it, so it is free to take. It is also the exact hook the
//  client half uses, which keeps the two sides shaped the same.
//
//  🛑 MAP-SCOPED ON PURPOSE. This references maps\mp\zm_transit_buildables,
//  which resolves at SCRIPT LOAD time. It therefore cannot live in
//  scripts\zm\locs\zm_transit_loc_diner.gsc - not one file under locs\ carries
//  a maps\mp\zm_* reference, deliberately - nor in quality_of_life.gsc.
//  AI_CONTEXT rule 2: a map-specific reference in a globally-loaded script
//  throws "Unresolved external" on every OTHER map, and a runtime guard does
//  not save it.
// ============================================================================
zmqol_diner_shield_enabled()
{
    // Twin of zm_transit.csc::zmqol_diner_shield_enabled(). Same two dvars,
    // same order, same comparisons - if these ever disagree the server and
    // client clientfield sets differ in width and everyone is dropped at load.
    return getdvarintdefault( "zmqol_diner_shield", 1 ) && getdvar( "ui_zm_mapstartlocation" ) == "diner" && getdvar( "ui_gametype" ) != "zgrief";
}

zmqol_diner_shield_init()
{
    if ( !zmqol_diner_shield_enabled() )
        return;

    level.init_buildables = ::zmqol_diner_init_buildables;
}

zmqol_diner_init_buildables()
{
    // Stock's own two calls, argument for argument (zm_transit_buildables.gsc
    // :31-32). generate_zombie_buildable_piece() precaches the model and the
    // hud shader itself (:208-211), so nothing extra is needed here. The
    // trailing 2 and 3 are client_field_state - the values sent through the
    // "buildable" clientfield, which is why 27 below has to cover them.
    dolly = maps\mp\zombies\_zm_buildables::generate_zombie_buildable_piece( "riotshield_zm", "t6_wpn_zmb_shield_dolly", 32, 64, 0, "zm_hud_icon_dolly", maps\mp\zm_transit_buildables::onpickup_common, maps\mp\zm_transit_buildables::ondrop_common, undefined, "TAG_RIOT_SHIELD_DOLLY", undefined, 2 );
    door = maps\mp\zombies\_zm_buildables::generate_zombie_buildable_piece( "riotshield_zm", "t6_wpn_zmb_shield_door", 48, 15, 25, "zm_hud_icon_cardoor", maps\mp\zm_transit_buildables::onpickup_common, maps\mp\zm_transit_buildables::ondrop_common, undefined, "TAG_RIOT_SHIELD_DOOR", undefined, 3 );

    riotshield = spawnstruct();
    riotshield.name = "riotshield_zm";
    riotshield maps\mp\zombies\_zm_buildables::add_buildable_piece( dolly );
    riotshield maps\mp\zombies\_zm_buildables::add_buildable_piece( door );

    // Stock's callbacks, reused rather than reimplemented. onbuyweapon_riotshield
    // resets the shield's health and location on the player; riotshieldbuildable
    // is the trigger think that drives the bench.
    riotshield.onbuyweapon = maps\mp\zm_transit_buildables::onbuyweapon_riotshield;
    riotshield.triggerthink = maps\mp\zm_transit_buildables::riotshieldbuildable;

    // include_buildable() lives in _zm_utility, not _zm_buildables.
    maps\mp\zombies\_zm_utility::include_buildable( riotshield );
    maps\mp\zombies\_zm_buildables::hide_buildable_table_model( "riotshield_zm_buildable_trigger" );

    // 27 is stock TranZit's own number, set in both its .gsc (:12) and its .csc
    // (:7). Kept rather than reduced to 3: getminbitcountfornum(27) is 5 bits,
    // exactly what classic TranZit registers, so this is parity instead of a
    // number of our own. add_zombie_buildable() is what fires
    // register_clientfields(), and it only fires on the FIRST buildable
    // (_zm_buildables.gsc:160-162) - so the count must be right BEFORE this line.
    level.buildable_piece_count = 27;
    maps\mp\zombies\_zm_buildables::add_zombie_buildable( "riotshield_zm", &"ZOMBIE_BUILD_RIOT", &"ZOMBIE_BUILDING_RIOT", &"ZOMBIE_BOUGHT_RIOT" );

    // 🛑 v1.66.1 - THE CALL v1.66.0 WAS MISSING, and it is why the bench was
    // uncovered but the parts were nowhere on the map.
    //
    // Registering a buildable does NOT put anything in the world. The chain is:
    //     think_buildables()            (_zm_buildables.gsc:2309)
    //       -> [[ buildable.triggerthink ]]()          per included buildable
    //       -> buildable_trigger_think -> setup_unitrigger_buildable
    //       -> the buildable zone, which is what calls generate_piece()
    //          (:1274) and actually spawns the dolly and the door
    // No stub, no zone, no pieces - exactly the symptom.
    //
    // 🌟 think_buildables() is threaded from zm_transit_classic.gsc:108 AND
    // NOWHERE ELSE in the whole stock dump (Buried and Die Rise thread their
    // own from their classic/grief scripts), so survival has never run it.
    //
    // Threaded from HERE rather than from the location main() - which is the
    // slot stock uses - on purpose: this way it cannot run before the
    // registration above, so it depends on no ordering between _zm::init() and
    // rungametypemain(). It iterates level.zombie_include_buildables, which in
    // Diner survival contains only the riot shield, because nothing else calls
    // include_buildable() in this mode.
    level thread maps\mp\zombies\_zm_buildables::think_buildables();

    // Real println, not a /# #/ dev block: the two stock diagnostics in this
    // path ("ZM >> Looking for buildable", "ERROR: Missing buildable piece")
    // are both inside developer blocks and printed nothing on the v1.66.0 boot,
    // which is why that boot could not say whether this function had run at all.
    // spawns.size is read straight from the structs the map ships - 3 and 3.
    n_dolly = 0;
    n_door = 0;

    if ( isdefined( dolly.spawns ) )
        n_dolly = dolly.spawns.size;

    if ( isdefined( door.spawns ) )
        n_door = door.spawns.size;

    println( "[zm_qol] diner shield: registered - dolly spawns " + n_dolly + ", door spawns " + n_door + " (expect 3 and 3), piece_count " + level.buildable_piece_count );
}

init()
{
    if( getDvar("ui_zm_mapstartlocation") == "town" )
    {
        level thread town_vault_breach_init();
    }

    added_weapons();

    level thread zmqol_jetgun_never_breaks();
    level thread zmqol_jetgun_real_slot();
    level thread zmqol_no_power_transit_extras();

    //  ========================================================================
    //  v2.9.16 - THE PACK-A-PUNCH DOOR STAYS OPEN, user request 2026-08-31:
    //  "Once a player opens the Power Station door with a Turbine, keep the
    //  Town Bank Vault Pack-a-Punch door permanently open without requiring a
    //  Turbine to remain behind."
    //
    //  🌟 TREYARCH SHIPPED THE SWITCH; THIS SETS IT. _zm_blockers.gsc's
    //  door_think() checks `level.local_doors_stay_open` immediately after a
    //  local_electric_door opens (:588) and RETURNS - the close half of the
    //  loop (wait 3 / waittill_door_can_close / door_block) never runs, so the
    //  door latches open the first time a Turbine powers it. Stock itself sets
    //  this flag in _zm_game_module::turn_power_on_and_open_doors() (:121) for
    //  the grief/turned modules, so this is a supported state, not a hack.
    //
    //  📝 WHAT IT COVERS: every `local_electric_door` on the map - the bank
    //  vault Pack-a-Punch door AND the power station's turbine door. Both still
    //  need a Turbine placed ONCE to open (door_think still waits on
    //  "local_power_on"); the flag only stops them closing again when the
    //  Turbine leaves or dies.
    //
    //  Recovery with no rebuild: pap_door_stays_open 0, next map load.
    //  ========================================================================
    if ( getdvar( "pap_door_stays_open" ) == "" )
        setdvar( "pap_door_stays_open", "1" );

    if ( getdvarint( "pap_door_stays_open" ) )
        level.local_doors_stay_open = 1;
}

// ============================================================================
//  JET GUN IN A REAL WEAPON SLOT                                    (v2.9.9)
// ----------------------------------------------------------------------------
//  User directive 2026-08-30 (task 3): move the jet gun out of the equipment
//  slot into a standard weapon slot, never breaks, keep the heat mechanic.
//
//  WHAT "EQUIPMENT SLOT" ACTUALLY IS, measured: the jet gun's def is
//  inventoryType "item", and _zm_equipment::equipment_give() adds the
//  bookkeeping - set_player_equipment, the one-equipment-at-a-time
//  equipment_take() (which is why claiming the jet gun costs you your shield
//  and building a shield costs you the jet gun), clip forced to 1, and the
//  drop/placed-item lifecycle.
//
//  THE CHANGE, in three coordinated pieces:
//    1. weapons\zm\jetgun_zm / jetgun_upgraded_zm: inventoryType item ->
//       primary, now UNDER the 20,480 raw-loader ceiling (they were over it
//       and never loaded - ERROR_CATALOGUE §36; that also means the v1.99.23
//       Paralyzer-cooldown fields in them have never applied either, and both
//       land together the first time the trimmed defs load).
//    2. The crafting-table claim: level.zombie_include_buildables["jetgun_zm"]
//       .onbought - stock's own per-buildable hook (_zm_buildables.gsc:2140),
//       which REPLACES the whole equipment_buy branch when set. The claim now
//       gives the gun as a normal weapon: full clip, no equipment bookkeeping,
//       so the shield and the jet gun coexist.
//    3. Every other give route: the equipment_give replaceFunc in main().
//
//  WHAT IS DELIBERATELY UNTOUCHED, because it keys on the unchanged name
//  "jetgun_zm": watch_overheat / wait_for_jetgun_fired / the whole firing,
//  drag, gib and grind logic, and every client-side fx in _zm_weap_jetgun.csc
//  (all of it tests currentweapon == "jetgun_zm" - a renamed weapon would have
//  lost the vortex and power-cell effects, which is why no qol-copy def is
//  used here).
//
//  NEVER BREAKS is already live (v1.99.23, the three flags above). Heat is the
//  def's own engine mechanic (overheatWeapon 1) and survives untouched.
//
//  🛑 HONEST GATE, stated: whether a raw weapons\zm\ def OVERRIDES the copy
//  zm_transit.ff supplies is still unproven (the DSR 50 in v2.9.8 is the same
//  experiment). If the map's def wins, inventoryType stays "item": the gun
//  then still never breaks, still keeps its heat, and still coexists with the
//  shield (that half is pure script), but it selects via the D-pad slot the
//  way stock did instead of cycling with your guns. The claim path below works
//  identically under either outcome - giveweapon + setactionslot behave for
//  both inventory types.
// ============================================================================
zmqol_jetgun_real_slot()
{
    if ( level.script != "zm_transit" )
        return;

    //  The buildable structs are created during the map's own init, after this
    //  mod's main()/init() - poll until the jet gun's struct exists. Same
    //  deferred-hook pattern as zmqol_jetgun_never_breaks() above; a claim
    //  cannot physically happen for minutes, so there is no race window.
    for ( i = 0; i < 1200; i++ )
    {
        if ( isdefined( level.zombie_include_buildables ) && isdefined( level.zombie_include_buildables["jetgun_zm"] ) )
        {
            level.zombie_include_buildables["jetgun_zm"].onbought = ::zmqol_jetgun_claimed;
            println( "[zm_qol] jetgun: real-slot claim hook armed (onbought)" );
            return;
        }
        wait 0.5;
    }
}

// ============================================================================
//  zmqol_jetgun_give_as_primary  -  THE JET GUN MUST COST A WEAPON SLOT
//
//  ✅ VERIFIED IN GAME 2026-09-04 (v2.11.14, TranZit) - user: "the jetgun works
//  as intended, now replaces an actual weapon slot". The raw-def half stays as
//  measured; this function is what makes the slot cost real.
//
//  🛑 User, 2026-09-04, TranZit: "i had the jet gun, whilst having mule kick
//  and three guns, but the jet gun wasn't actually overriding a real weapon
//  slot, so i ended up having 4 weapons".
//
//  MEASURED CAUSE, and it is NOT the def. The def half has been right since
//  v2.9.11 - the raw weapons\zm\jetgun_zm loads as inventoryType "primary",
//  measured in the running game. What was missing is that both of this file's
//  give paths called the bare engine builtin `giveweapon`, and NOTHING IN THE
//  ENGINE ENFORCES THE PRIMARY LIMIT. T6 enforces it in SCRIPT, inside
//  _zm_weapons::weapon_give: it reads getweaponslistprimaries() (:2333),
//  compares against get_player_weapon_limit( player ) (:2341 - 2, or
//  level.additionalprimaryweapon_limit with Mule Kick, _zm_utility.gsc:5046)
//  and takes the HELD weapon first when the player is already at the cap
//  (:2406-2425). A bare giveweapon skips every one of those steps, so a full
//  loadout simply gained a fourth gun.
//
//  🛑 WHY NOT SIMPLY CALL weapon_give( "jetgun_zm" ) AND BE DONE. Because
//  TranZit registers the jet gun as equipment - register_equipment_for_level(
//  "jetgun_zm" ), zm_transit.gsc:1854 - so weapon_give's own first act,
//  `if ( is_equipment( weapon ) ) equipment_give( weapon )` (:2343), lands in
//  zmqol_equipment_give() below, gives the gun there, and weapon_give then sees
//  hasweapon() and returns at :2352 having never reached the limit block. The
//  call would look correct and change nothing. So the limit block is reproduced
//  here, in stock's order, and BOTH give paths go through this one function.
//
//  📝 The equipment registration is deliberately left alone: _zm_weap_jetgun
//  and its client twin key on the name "jetgun_zm" throughout, and stock's
//  is_equipment() guard below is what keeps the riot shield from being taken
//  when it is the weapon in hand.
// ============================================================================
// ============================================================================
//  zmqol_weapon_give  -  THE JET GUN CAN BE SWAPPED OUT LIKE ANY GUN (v2.11.26)
// ============================================================================
//  User, 2026-09-04, TranZit: *"i managed to end up with 4 guns again … i had it
//  in my hands, already had 3 weapons with mule kick, then with chat commands
//  gave myself a new weapon and it didn't overwrite the jet gun's weapon slot
//  and instead added it to a 4th one … no more having 4 weapons due to the jet
//  gun not properly working as a weapon slot."*
//
//  🛑 v2.11.14 FIXED THE OTHER DIRECTION ONLY. Giving the JET GUN at the cap
//  takes a real weapon (zmqol_jetgun_give_as_primary, confirmed in game). This
//  is the reverse: giving ANY OTHER weapon while the jet gun is the weapon in
//  hand. Stock's own limit block, _zm_weapons.gsc:2407-2426, reads
//
//      if ( primaryweapons.size >= weapon_limit )
//      {
//          if ( is_placeable_mine( current_weapon ) || is_equipment( current_weapon ) )
//              current_weapon = undefined;      <-- nothing is taken
//
//  and TranZit registers the jet gun as equipment - register_equipment_for_level(
//  "jetgun_zm" ), zm_transit.gsc:1854 - so the gun in your hands was exempt from
//  being taken and the new one simply became a fourth. The exclusion is there to
//  stop a RIOT SHIELD or a placed mine being taken; the jet gun is a genuine
//  primary here (raw weapons\zm\ def, inventoryType "primary", measured in the
//  running game) and does hold a slot, so it must not be exempt.
//
//  🛑 WHY THE WHOLE FUNCTION IS COPIED RATHER THAN A UTILITY HOOKED. The obvious
//  smaller fix is to replace _zm_utility::is_equipment so it answers "no" for the
//  jet gun. Every one of its nine stock callers was read, and three of them
//  change behaviour that nobody asked for: can_track_ammo (_zm.gsc:631),
//  has_weapon_or_upgrade (_zm_weapons.gsc:1896), and - the one that settles it -
//  zombie_death_points (_zm_spawner.gsc:1651), which withholds points for an
//  EQUIPMENT kill. Flipping that would silently make the jet gun a points weapon.
//  So the change is made in the one place it belongs instead.
//
//  🌟 THE BLAST RADIUS IS AS SMALL AS IT CAN BE MADE:
//    - the replaceFunc is in this MAP'S main(), so no other map runs a line of it;
//    - the body is _zm_weapons::weapon_give copied from the stock dump with every
//      call QUALIFIED (so a replaced utility - is_offhand_weapon, replaced by
//      bouncingbetty.gsc - still reaches the mod's version, exactly as stock did);
//    - exactly ONE condition differs from stock, and it is gated on the weapon
//      name AND on the def actually being a primary at runtime, so every other
//      weapon in the game takes byte-identical decisions.
//
//  📝 If the raw def ever fails the 20,480 B loader ceiling (ERROR_CATALOGUE
//  36) the map's own "item" def is back, the jet gun costs no slot, and
//  zmqol_jetgun_holds_a_slot() answers 0 - stock's exclusion applies again and
//  the player does not lose a gun for nothing. Checked at runtime, not assumed.
// ============================================================================
//  📝 Stock’s one dev-only line, assert( self player_can_use_content(
//  weapon ) ), is deliberately not copied: assert is a no-op in a retail build
//  and keeping it would add a live call for nothing. Every other statement is
//  present, in stock’s order.
zmqol_jetgun_holds_a_slot( str_weapon )
{
    if ( !isdefined( str_weapon ) || str_weapon != "jetgun_zm" )
        return 0;

    return weaponinventorytype( "jetgun_zm" ) == "primary";
}

zmqol_weapon_give( weapon, is_upgrade, magic_box, nosound )
{
    primaryweapons = self getweaponslistprimaries();
    current_weapon = self getcurrentweapon();
    current_weapon = self maps\mp\zombies\_zm_weapons::switch_from_alt_weapon( current_weapon );

    if ( !isdefined( is_upgrade ) )
        is_upgrade = 0;

    weapon_limit = self maps\mp\zombies\_zm_utility::get_player_weapon_limit( self );

    if ( maps\mp\zombies\_zm_utility::is_equipment( weapon ) )
        self maps\mp\zombies\_zm_equipment::equipment_give( weapon );

    if ( weapon == "riotshield_zm" )
    {
        if ( isdefined( self.player_shield_reset_health ) )
            self [[ self.player_shield_reset_health ]]();
    }

    if ( self hasweapon( weapon ) )
    {
        if ( issubstr( weapon, "knife_ballistic_" ) )
            self notify( "zmb_lost_knife" );

        self givestartammo( weapon );

        if ( !maps\mp\zombies\_zm_utility::is_offhand_weapon( weapon ) )
            self switchtoweapon( weapon );

        return;
    }

    if ( maps\mp\zombies\_zm_utility::is_melee_weapon( weapon ) )
        current_weapon = self maps\mp\zombies\_zm_melee_weapon::change_melee_weapon( weapon, current_weapon );
    else if ( maps\mp\zombies\_zm_utility::is_lethal_grenade( weapon ) )
    {
        old_lethal = self maps\mp\zombies\_zm_utility::get_player_lethal_grenade();

        if ( isdefined( old_lethal ) && old_lethal != "" )
        {
            self takeweapon( old_lethal );
            maps\mp\zombies\_zm_weapons::unacquire_weapon_toggle( old_lethal );
        }

        self maps\mp\zombies\_zm_utility::set_player_lethal_grenade( weapon );
    }
    else if ( maps\mp\zombies\_zm_utility::is_tactical_grenade( weapon ) )
    {
        old_tactical = self maps\mp\zombies\_zm_utility::get_player_tactical_grenade();

        if ( isdefined( old_tactical ) && old_tactical != "" )
        {
            self takeweapon( old_tactical );
            maps\mp\zombies\_zm_weapons::unacquire_weapon_toggle( old_tactical );
        }

        self maps\mp\zombies\_zm_utility::set_player_tactical_grenade( weapon );
    }
    else if ( maps\mp\zombies\_zm_utility::is_placeable_mine( weapon ) )
    {
        old_mine = self maps\mp\zombies\_zm_utility::get_player_placeable_mine();

        if ( isdefined( old_mine ) )
        {
            self takeweapon( old_mine );
            maps\mp\zombies\_zm_weapons::unacquire_weapon_toggle( old_mine );
        }

        self maps\mp\zombies\_zm_utility::set_player_placeable_mine( weapon );
    }

    if ( !maps\mp\zombies\_zm_utility::is_offhand_weapon( weapon ) )
        self maps\mp\zombies\_zm_weapons::take_fallback_weapon();

    if ( primaryweapons.size >= weapon_limit )
    {
        //  🛑 THE ONE LINE THAT DIFFERS FROM STOCK. Stock reads
        //      if ( is_placeable_mine( current_weapon ) || is_equipment( current_weapon ) )
        //  The added clause lets a jet gun that is genuinely holding a primary
        //  slot be taken like any other gun. Nothing else in this function is
        //  changed, and no other weapon can reach the new clause.
        if ( maps\mp\zombies\_zm_utility::is_placeable_mine( current_weapon ) || ( maps\mp\zombies\_zm_utility::is_equipment( current_weapon ) && !zmqol_jetgun_holds_a_slot( current_weapon ) ) )
            current_weapon = undefined;

        if ( isdefined( current_weapon ) )
        {
            if ( !maps\mp\zombies\_zm_utility::is_offhand_weapon( weapon ) )
            {
                if ( current_weapon == "tesla_gun_zm" )
                    level.player_drops_tesla_gun = 1;

                if ( issubstr( current_weapon, "knife_ballistic_" ) )
                    self notify( "zmb_lost_knife" );

                self takeweapon( current_weapon );
                maps\mp\zombies\_zm_weapons::unacquire_weapon_toggle( current_weapon );
            }
        }
    }

    if ( isdefined( level.zombiemode_offhand_weapon_give_override ) )
    {
        if ( self [[ level.zombiemode_offhand_weapon_give_override ]]( weapon ) )
            return;
    }

    if ( weapon == "cymbal_monkey_zm" )
    {
        self maps\mp\zombies\_zm_weap_cymbal_monkey::player_give_cymbal_monkey();
        self maps\mp\zombies\_zm_weapons::play_weapon_vo( weapon, magic_box );
        return;
    }
    else if ( issubstr( weapon, "knife_ballistic_" ) )
        weapon = self maps\mp\zombies\_zm_melee_weapon::give_ballistic_knife( weapon, issubstr( weapon, "upgraded" ) );
    else if ( weapon == "claymore_zm" )
    {
        self thread maps\mp\zombies\_zm_weap_claymore::claymore_setup();
        self maps\mp\zombies\_zm_weapons::play_weapon_vo( weapon, magic_box );
        return;
    }

    if ( isdefined( level.zombie_weapons_callbacks ) && isdefined( level.zombie_weapons_callbacks[weapon] ) )
    {
        self thread [[ level.zombie_weapons_callbacks[weapon] ]]();
        self maps\mp\zombies\_zm_weapons::play_weapon_vo( weapon, magic_box );
        return;
    }

    if ( !( isdefined( nosound ) && nosound ) )
        self maps\mp\zombies\_zm_utility::play_sound_on_ent( "purchase" );

    if ( weapon == "ray_gun_zm" )
        playsoundatposition( "mus_raygun_stinger", ( 0, 0, 0 ) );

    if ( !maps\mp\zombies\_zm_weapons::is_weapon_upgraded( weapon ) )
        self giveweapon( weapon );
    else
        self giveweapon( weapon, 0, self maps\mp\zombies\_zm_weapons::get_pack_a_punch_weapon_options( weapon ) );

    maps\mp\zombies\_zm_weapons::acquire_weapon_toggle( weapon, self );
    self givestartammo( weapon );

    if ( !maps\mp\zombies\_zm_utility::is_offhand_weapon( weapon ) )
    {
        if ( !maps\mp\zombies\_zm_utility::is_melee_weapon( weapon ) )
            self switchtoweapon( weapon );
        else
            self switchtoweapon( current_weapon );
    }

    self maps\mp\zombies\_zm_weapons::play_weapon_vo( weapon, magic_box );
}

zmqol_jetgun_give_as_primary()
{
    if ( self hasweapon( "jetgun_zm" ) )
        return;

    //  _zm_weapons.gsc:2333-2341 - read the slot state BEFORE anything is given.
    primaryweapons = self getweaponslistprimaries();
    current_weapon = self getcurrentweapon();
    current_weapon = self maps\mp\zombies\_zm_weapons::switch_from_alt_weapon( current_weapon );
    weapon_limit = maps\mp\zombies\_zm_utility::get_player_weapon_limit( self );

    //  :2404-2405 - the fists are not a primary and must not hold a slot.
    self maps\mp\zombies\_zm_weapons::take_fallback_weapon();

    //  :2406-2425 - at the cap, the weapon in hand is the one that goes. The
    //  two exclusions are stock's own: a placed mine or a piece of equipment
    //  (the riot shield) is never what gets taken.
    //
    //  🛑 GATED ON THE DEF ACTUALLY BEING A PRIMARY, checked at runtime. If the
    //  raw weapons\zm\ copy ever fails the 20,480 B loader ceiling the map's
    //  own "item" def is back, the gun then costs no slot at all, and taking
    //  the held weapon here would be a pure loss for the player.
    if ( weaponinventorytype( "jetgun_zm" ) == "primary" && primaryweapons.size >= weapon_limit )
    {
        if ( maps\mp\zombies\_zm_utility::is_placeable_mine( current_weapon ) || maps\mp\zombies\_zm_utility::is_equipment( current_weapon ) )
            current_weapon = undefined;

        if ( isdefined( current_weapon ) )
        {
            self takeweapon( current_weapon );
            maps\mp\zombies\_zm_weapons::unacquire_weapon_toggle( current_weapon );
        }
    }

    //  :2463-2467 - give, register it with the weapon-toggle bookkeeping, then
    //  fill the clip. weaponclipsize() rather than stock equipment's forced 1.
    self giveweapon( "jetgun_zm" );
    maps\mp\zombies\_zm_weapons::acquire_weapon_toggle( "jetgun_zm", self );
    self setweaponammoclip( "jetgun_zm", weaponclipsize( "jetgun_zm" ) );

    //  🛑 v2.9.16, user request: no action-slot bind, because that is what drew
    //  the equipment HUD widget and its key prompt. It survives only as the
    //  fallback for the one state where it is load-bearing - if the raw def
    //  ever fails to load (the 20,480 B ceiling, ERROR_CATALOGUE 36) the map's
    //  own "item" def is back and slot 1 is the only way to select the gun.
    //  Checked at runtime, not assumed.
    if ( weaponinventorytype( "jetgun_zm" ) != "primary" )
        self setactionslot( 1, "weapon", "jetgun_zm" );
}

//  The crafting-table claim. self = the buildable's unitrigger (stock calls
//  `self [[ onbought ]]( player )`), so self.stub.* is available exactly as it
//  is in stock's own else-branch, and the hint/cursor cleanup below mirrors
//  that branch line for line (_zm_buildables.gsc:2144-2163) so the table stops
//  prompting once claimed.
zmqol_jetgun_claimed( player )
{
    if ( !isdefined( player ) || player hasweapon( "jetgun_zm" ) )
        return;

    //  v2.11.14 - the slot accounting lives in one place now; see the banner
    //  above zmqol_jetgun_give_as_primary(). This used to be a bare giveweapon,
    //  which is why a player at the Mule Kick cap ended up carrying four guns.
    player zmqol_jetgun_give_as_primary();
    //  🛑 v2.9.16 - NO ACTION-SLOT BIND ANY MORE, user request 2026-08-31:
    //  "remove the Jet Gun equipment HUD element/icon on the right side of the
    //  screen [and] the dedicated equipment hotkey prompt (e.g. key 8)". The
    //  old comment here called the slot-1 bind "redundant but harmless" with
    //  the primary def - the harm is exactly that engine-drawn equipment
    //  widget and its key prompt (slot 1 = DPAD_UP = key 8, read from the
    //  user's own bindings_zm.bdg). The v2.9.11 boot MEASURED the raw def
    //  loading as inventoryType "primary" in the running game, so the gun
    //  cycles with the weapon-switch key like any rifle and needs no slot.
    //  The bind survives only as a fallback for the one state where it is
    //  load-bearing: if the raw def ever fails to load (the 20,480 B loader
    //  ceiling) the map's own "item" def is back and slot 1 is the only way
    //  to select the gun at all. Checked at runtime, not assumed.
    if ( weaponinventorytype( "jetgun_zm" ) != "primary" )
        player setactionslot( 1, "weapon", "jetgun_zm" );
    player switchtoweapon( "jetgun_zm" );

    self.stub.cursor_hint = "HINT_NOICON";
    self.stub.cursor_hint_weapon = undefined;
    self setcursorhint( self.stub.cursor_hint );

    if ( isdefined( level.zombie_buildables["jetgun_zm"].bought ) )
        self.stub.hint_string = level.zombie_buildables["jetgun_zm"].bought;
    else
        self.stub.hint_string = "";

    self sethintstring( self.stub.hint_string );
    player maps\mp\zombies\_zm_buildables::track_buildables_pickedup( "jetgun_zm" );
}

//  Stock _zm_equipment::equipment_give() with ONE added branch at the top.
//  The body below the branch is stock's, verbatim (_zm_equipment.gsc:247-277),
//  with the same-file helper calls qualified so they resolve from this file -
//  behaviour for the shield and every other piece of equipment is unchanged.
zmqol_equipment_give( equipment )
{
    if ( !isdefined( equipment ) )
        return;

    //  --- the jet gun is a weapon now, not equipment ---
    if ( equipment == "jetgun_zm" )
    {
        //  v2.11.14 - through the shared slot-aware give, so every route that
        //  is NOT the crafting table obeys the primary limit as well: .give,
        //  any script hand-over, and weapon_give()'s own is_equipment() detour
        //  at _zm_weapons.gsc:2343. This was a bare giveweapon, which is half
        //  of why a full loadout ended up with four guns.
        self zmqol_jetgun_give_as_primary();
        return;
    }

    //  --- stock body, verbatim ---
    if ( !isdefined( level.zombie_equipment[equipment] ) )
        return;

    if ( self maps\mp\zombies\_zm_utility::has_player_equipment( equipment ) )
        return;

    curr_weapon = self getcurrentweapon();
    curr_weapon_was_curr_equipment = self maps\mp\zombies\_zm_utility::is_player_equipment( curr_weapon );
    self maps\mp\zombies\_zm_equipment::equipment_take();
    self maps\mp\zombies\_zm_utility::set_player_equipment( equipment );
    self giveweapon( equipment );
    self setweaponammoclip( equipment, 1 );
    self thread maps\mp\zombies\_zm_equipment::show_equipment_hint( equipment );
    self notify( equipment + "_given" );
    self maps\mp\zombies\_zm_equipment::set_equipment_invisibility_to_player( equipment, 1 );
    self setactionslot( 1, "weapon", equipment );

    if ( isdefined( level.zombie_equipment[equipment].watcher_thread ) )
        self thread [[ level.zombie_equipment[equipment].watcher_thread ]]();

    self thread maps\mp\zombies\_zm_equipment::equipment_slot_watcher( equipment );
    self maps\mp\zombies\_zm_audio::create_and_play_dialog( "weapon_pickup", level.zombie_equipment[equipment].vox );
}

// ============================================================================
//  JET GUN - IT NEVER BREAKS, AND IT COOLS LIKE THE PARALYZER   (v1.99.23)
// ----------------------------------------------------------------------------
//  User, 2026-08-17: the jet gun should stop being "the terrible piece of trash
//  it is in the stock game" - never break, so it never needs rebuilding, and to
//  pay for that, take the Paralyzer's cooldown so it cannot be fired forever.
//
//  🛑 THIS IS HALF THE REQUEST. The other half - making it occupy a real weapon
//  slot instead of the equipment slot - is queue 16 and is NOT done here. It
//  needs `inventoryType` flipped in the weapon def, which reroutes how the gun
//  is given, dropped and picked up, and that is a bigger change than this one.
//  Split deliberately: this half is self-contained and its result tells us
//  whether the other half is even deliverable. See the probe note below.
//
//  ---------------------------------------------------------------------------
//  NEVER BREAKS - one flag, and it is stock's own
//  ---------------------------------------------------------------------------
//  `maps\mp\zm_transit.gsc:1638` sets `level.explode_overheated_jetgun = 1`.
//  That is the ONLY assignment to it in the whole game, and its two siblings
//  `unbuild_overheated_jetgun` / `take_overheated_jetgun` are set nowhere at
//  all. `_zm_weap_jetgun.gsc:201 handle_overheated_jetgun()` tests all three
//  with `isdefined( x ) && x` and, with none of them true, does NOTHING - the
//  gun simply overheats and cools down. So clearing the flag is the entire
//  "never breaks" feature; nothing is reimplemented and no stock function is
//  replaced.
//
//  Set to 0 rather than undefined on purpose: the stock test is
//  `isdefined( x ) && x`, so 0 satisfies it either way, and a defined 0 cannot
//  be mistaken later for "this was never set".
//
//  🛑 Cleared AFTER `flag_wait( "start_zombie_round_logic" )` because line 1638
//  runs during the map's own init and would otherwise set it back. Same
//  ordering trick, and the same flag, that `qol_options.gsc:914` already uses.
//
//  ---------------------------------------------------------------------------
//  THE COOLDOWN - three numbers, measured, not tuned by feel
//  ---------------------------------------------------------------------------
//  Both guns already use the SAME engine overheat system (`overheatWeapon 1`,
//  driven by setweaponoverheating / isweaponoverheating). `_zm_weap_slowgun.gsc`
//  is 815 lines and has no heat, cooldown or fuel logic anywhere in it - the
//  Paralyzer's bar is entirely its weapon file. So this is not a port; it is
//  three fields, taken by dumping both defs with the Unlinker and diffing all
//  1,027 fields of each by value:
//
//      overheatRate     17 -> 10   heats up slower
//      cooldownRate      1 ->  3   cools three times faster
//      overheatEndVal   77 -> 87   the threshold the overheat lockout releases at
//
//  📝 The first two are unambiguous. `overheatEndVal` is NOT described anywhere
//  in this workspace and its direction is UNVERIFIED - whether a higher value
//  releases the lockout sooner or later is a guess either way, so no claim is
//  made about it. It is set to the Paralyzer's value because copying the
//  Paralyzer's feel is the request; the number is measured, its meaning is not.
//
//  They ship in `weapons\zm\jetgun_zm` and `weapons\zm\jetgun_upgraded_zm`,
//  which are byte-for-byte the stock defs with exactly those 3 of 1,027 fields
//  changed. The upgraded def is included because if anything in this mod ever
//  Pack-a-Punches the jet gun, an untouched upgraded def would silently hand
//  back the stock cooldown mid-game.
//
//  ---------------------------------------------------------------------------
//  🔮 WHAT THIS IS ALSO A PROBE FOR
//  ---------------------------------------------------------------------------
//  Raw weapon defs in `weapons\zm\` are a proven path here - 40 ride there now
//  (thundergun, tesla, freezegun, the MP weapons, Tac-45) and they work. BUT
//  every one of those 40 is a weapon that exists in NO zombies fastfile, so
//  they only prove a raw def can SUPPLY a missing weapon. `jetgun_zm` already
//  exists inside `zm_transit.ff`, so this is the first time a raw def has to
//  OVERRIDE one. That cannot be settled offline.
//
//  **If the cooldown feels different in game, the raw def overrode the fastfile**
//  - and queue 16 becomes deliverable the same way. If it feels identical, the
//  fastfile copy is still in charge and 16 needs a different route entirely.
//  The inventorytype line below is the baseline for that comparison: it must
//  read `item` today, and would read `primary` once 16 lands.
// ============================================================================
zmqol_jetgun_never_breaks()
{
    if ( level.script != "zm_transit" )
        return;

    flag_wait( "start_zombie_round_logic" );

    level.explode_overheated_jetgun = 0;
    level.unbuild_overheated_jetgun = 0;
    level.take_overheated_jetgun = 0;

    println( "[zm_qol] jetgun: never-breaks armed - explode/unbuild/take all 0; inventorytype=" + weaponinventorytype( "jetgun_zm" ) + " clipsize=" + weaponclipsize( "jetgun_zm" ) );
}

main_o()
{
    maps\mp\gametypes_zm\_zm_gametype::setup_standard_objects( "station" );
    maps\mp\zm_transit_standard_station::station_treasure_chest_init();
    level.enemy_location_override_func = maps\mp\zm_transit_standard_station::enemy_location_override;
    collision = spawn( "script_model", ( -6896, 4744, 0 ), 1 );
    collision setmodel( "zm_collision_transit_busdepot_survival" );
    collision disconnectpaths();

    //  v2.14.0 - the fire pit the bus pulls away from is open again. Called
    //  HERE, straight after setup_standard_objects() spawned the props and
    //  after stock's own collision spawn, so both exist and nothing waits.
    zmqol_busdepot_open_fire_pit( collision );

    flag_wait( "initial_blackscreen_passed" );
    flag_set( "power_on" );
    level setclientfield( "zombie_power_on", 1 );
    zombie_doors = getentarray( "zombie_door", "targetname" );

    foreach ( door in zombie_doors )
    {
        if ( isdefined( door.script_noteworthy ) && door.script_noteworthy == "local_electric_door" )
        {
            door trigger_off();
        }
    }
}

// ============================================================================
//  BUS DEPOT SURVIVAL - THE FIRE PIT IS OPEN AGAIN                   (v2.14.0)
// ----------------------------------------------------------------------------
//  User, 2026-09-06: "for bus depot survival, remove the car that is on top of
//  the fire pit where the bus usually first departures from at spawn, because
//  in tranzit the fire pit is open, the reimagined mod does this exact thing
//  for bus depot survival."
//
//  WHAT THE STOCK MAP PUTS THERE - read out of the zm_transit mapents dump
//  (T6-Data-Archive zm_transit.d3dbsp), not assumed:
//
//      info_volume              depot_lava_pit / lava_volume  (-6698, 4771, -101)
//      trigger_multiple         lava_damage / fire            (-6698, 4771,  -95)
//      info_vehicle_node_rotate BUS_START / depot             (-6527, 4770, -28.6)
//
//  so the pit is exactly the spot the bus first pulls away from, as described.
//  Bus Depot survival then dresses FOUR "game_mode_object" structs over it.
//  _zm_gametype::setup_standard_objects( "station" ) spawns each one as a plain
//  script_model AT its struct origin, so these are the map's own numbers:
//
//      veh_t6_civ_smallwagon_dead     (-6663.96, 4816.34, -71.8)   <- "the car"
//      veh_t6_civ_microbus_dead       (-6807.05, 4765.23, -68.01)
//      veh_t6_civ_movingtrk_cab_dead  (-6652.9,  4767.7,   -6.73)
//      p6_zm_rocks_small_cluster_01   (-6745.48, 4782.86, -79.01)
//
//  The map has NINE station barricades; the other five stand at the play-area
//  edge (x -7900..-8100 and -5787) and are deliberately left alone.
//
//  🛑 DELETING THE PROPS ALONE WOULD NOT OPEN ANYTHING. The pit itself is
//  plugged by the collision model handed in here - zm_collision_transit_
//  busdepot_survival, spawned by stock's own station main() three lines above
//  the call. Reimagined deletes it too, in scripts\zm\zm_transit\
//  zm_transit_reimagined.gsc::busdepot_remove_lava_collision(), whose own
//  comment says the pit plug and the play-area edge collision are the SAME
//  entity - which is why it then spawns three replacement walls at the edge.
//  Both halves are ported: the deletion without the walls would open the map
//  edge, which is a regression, not a feature.
//
//  ⚠️ ONE THING COULD NOT BE MEASURED OFFLINE, and is stated rather than
//  hidden: what that collision model actually covers. OAT dumps all four
//  zm_collision_transit_*_survival models as the identical 8-vertex 512-unit
//  cube (they plainly cannot all be one cube), so the real collision lives in
//  data the Unlinker does not export. Reimagined's shipped, played behaviour is
//  the only evidence there is, and the three wall positions below are its
//  numbers verbatim.
//
//  📝 NO connectpaths() BEFORE THE DELETE, on purpose - Reimagined does not
//  call one either. The nodes stock disconnected are the ones over the plug;
//  with the pit open again they SHOULD stay disabled, exactly as in classic.
//
//  📝 SURVIVAL ONLY. This runs from main_o(), which replaces
//  maps\mp\zm_transit_standard_station::main - registered for "transit" on
//  zstandard alone. Grief's Bus Depot goes through zm_transit_grief_station and
//  is untouched; the four props do not exist there anyway, their script_string
//  being "zstandard znml zcleansed".
//
//  📝 collision_wall_512x512x10_standard NEEDS NO PRECACHE HERE. Stock
//  zm_transit.gsc:203 threads zm_transit_ffotd::main_start() as the FIRST
//  statement of the map's own main(), and that precaches it unconditionally,
//  long before any location main runs.
// ============================================================================
zmqol_busdepot_open_fire_pit( e_pit_collision )
{
    a_models = [];
    a_origins = [];

    a_models[0] = "veh_t6_civ_smallwagon_dead";
    a_origins[0] = ( -6663.96, 4816.34, -71.8 );
    a_models[1] = "veh_t6_civ_microbus_dead";
    a_origins[1] = ( -6807.05, 4765.23, -68.01 );
    a_models[2] = "veh_t6_civ_movingtrk_cab_dead";
    a_origins[2] = ( -6652.9, 4767.7, -6.73 );
    a_models[3] = "p6_zm_rocks_small_cluster_01";
    a_origins[3] = ( -6745.48, 4782.86, -79.01 );

    n_deleted = 0;
    a_ents = getentarray( "script_model", "classname" );

    foreach ( e_ent in a_ents )
    {
        if ( !isdefined( e_ent.model ) )
        {
            continue;
        }

        for ( i = 0; i < a_models.size; i++ )
        {
            if ( e_ent.model != a_models[i] )
            {
                continue;
            }

            //  16 units. The origins above are the map's own and a barricade is
            //  spawned AT its struct origin, so this only has to absorb float
            //  printing error - never "near enough" guessing. Same rule as
            //  scripts\zm\locs\loc_common::enable_wallbuys.
            if ( distancesquared( e_ent.origin, a_origins[i] ) > 256 )
            {
                continue;
            }

            e_ent delete();
            n_deleted++;
            break;
        }
    }

    if ( isdefined( e_pit_collision ) )
    {
        e_pit_collision delete();
    }

    //  The play-area edge, put back by hand. Reimagined's three positions.
    scripts\zm\locs\loc_common::barrier( "collision_wall_512x512x10_standard", ( -5898, 4653, 0 ), ( 0, 55, 0 ), 1 );
    scripts\zm\locs\loc_common::barrier( "collision_wall_512x512x10_standard", ( -8062, 4700, 0 ), ( 0, 70, 0 ), 1 );
    scripts\zm\locs\loc_common::barrier( "collision_wall_512x512x10_standard", ( -7881, 5200, 0 ), ( 0, 70, 0 ), 1 );

    println( "[zm_qol] busdepot fire pit: deleted " + n_deleted + " of 4 barricades (expect 4) + the pit collision, 3 edge walls up" );
}

zombie_exploding_death( zombie_dmg, trap )
{
    self endon( "stop_flame_damage" );

    if ( isdefined( self.isdog ) && self.isdog && isdefined( self.a.nodeath ) )
    {
        return;
    }

    while ( isdefined( self ) && self.health >= zombie_dmg && ( isdefined( self.is_on_fire ) && self.is_on_fire ) )
    {
        wait 0.5;
    }

    if ( !isdefined( self ) || !( isdefined( self.is_on_fire ) && self.is_on_fire ) || isdefined( self.damageweapon ) && ( self.damageweapon == "tazer_knuckles_zm" || self.damageweapon == "jetgun_zm" ) || isdefined( self.knuckles_extinguish_flames ) && self.knuckles_extinguish_flames )
    {
        return;
    }

    tag = "J_SpineLower";

    if ( isdefined( self.animname ) && self.animname == "zombie_dog" )
    {
        tag = "tag_origin";
    }

    if ( is_mature() )
    {
        if ( isdefined( level._effect["zomb_gib"] ) )
        {
            playfx( level._effect["zomb_gib"], self gettagorigin( tag ) );
        }
    }
    else if ( isdefined( level._effect["spawn_cloud"] ) )
    {
        playfx( level._effect["spawn_cloud"], self gettagorigin( tag ) );
    }

    //  The seventh argument is load-bearing: with six or fewer the engine
    //  substitutes weapon index 255 and RadiusDamage dereferences a null
    //  weaponTable[255]. That is the Origins Panzer crash (v2.11.11); this
    //  call had the same shape. frag_grenade_zm is resident on TranZit.
    self radiusdamage( self.origin, 128, 30, 15, undefined, "MOD_GRENADE_SPLASH", "frag_grenade_zm" );
    self ghost();

    if ( isdefined( self.isdog ) && self.isdog )
    {
        self hide();
    }
    else
    {
        self delay_thread( 1, ::self_delete );
    }
}

// ============================================================================
//  NO LAVA DAMAGE                                                    (v2.7.0)
// ----------------------------------------------------------------------------
//  User, 2026-08-28: a PATCHES-tab toggle for Classic TranZit and all four
//  survival locations (Diner, Farm, Town, Bus Depot) that leaves lava visible
//  on the ground but stops it igniting/exploding zombies and stops it
//  damaging players. Dvar: no_lava_damage (qol_options.gsc).
//
//  WHY lava_damage_init IS THE HOOK, NOT THE DAMAGE FUNCTIONS THEMSELVES.
//  Stock's maps\mp\zm_transit_lava.gsc:
//      lava_damage_init()   -> array_thread( lava, ::lava_damage_think )
//      lava_damage_think()  -> ent thread player_lava_damage( self )
//                              ent thread zombie_lava_damage( self )
//  Both dispatch calls are UNQUALIFIED, SAME FILE - a replaceFunc aimed at
//  player_lava_damage/zombie_lava_damage from an external script like this one
//  cannot intercept them (AI_CONTEXT rule 3 / starter kit CLAUDE.md §4, failure
//  mode 1). lava_damage_init() is different: BOTH its stock callers
//  (zm_transit.gsc and zm_transit_dr.gsc, Diner's own top-level script) invoke
//  it as `level thread maps\mp\zm_transit_lava::lava_damage_init()` - a
//  qualified call from a DIFFERENT file, which is exactly the case replaceFunc
//  is built for.
//
//  🛑 NO "CALL THE ORIGINAL" AFTER A REPLACE. Once lava_damage_init is
//  replaced, any call to that qualified name - including from inside this very
//  replacement - redirects back here, so qol_lava_damage_init() below
//  reimplements stock's six-line body directly rather than trying to invoke a
//  now-shadowed original. qol_lava_damage_think() is a line-for-line copy of
//  stock's lava_damage_think(), with exactly two differences: one inserted
//  live dvar check, and its two dispatch calls made BY QUALIFIED NAME to
//  stock's real, untouched player_lava_damage()/zombie_lava_damage() - calling
//  a function externally by its qualified name is unaffected by replacing a
//  DIFFERENT function in the same file, so OFF/vanilla reproduces stock
//  exactly. Neither damage function nor any of their own helpers
//  (zombie_burning_fx, zombie_burning_dmg, player_stop_burning, etc.) are
//  touched at all - when the toggle is OFF they simply never get a reason not
//  to run, and when it is ON they are never reached in the first place.
// ============================================================================
qol_lava_damage_init()
{
    lava = getentarray( "lava_damage", "targetname" );

    //  🛑 Confirms two things this session could not verify offline: that this
    //  replace actually took (and ran before stock's own qualified call to the
    //  original), and how many lava_damage entities this location has (0 would
    //  mean this start location has no lava triggers to gate at all).
    println( "[zm_qol] lava: qol_lava_damage_init running (replaceFunc took) - " + lava.size + " lava_damage entities found, location=" + getdvar( "ui_zm_mapstartlocation" ) );

    if ( !isdefined( lava ) )
        return;

    array_thread( lava, ::qol_lava_damage_think );
}

qol_lava_damage_think()
{
    self._trap_type = "";

    if ( isdefined( self.script_noteworthy ) )
        self._trap_type = self.script_noteworthy;

    if ( isdefined( self.target ) )
    {
        self.volume = getent( self.target, "targetname" );
        assert( isdefined( self.volume ), "No volume found for lava target " + self.target );
    }

    while ( true )
    {
        self waittill( "trigger", ent );

        //  Read live on every trigger, not just once at map load, so the
        //  PATCHES row applies instantly mid-match in both directions.
        if ( getdvarintdefault( "no_lava_damage", 0 ) )
            continue;

        if ( isdefined( ent.ignore_lava_damage ) && ent.ignore_lava_damage )
            continue;

        if ( isdefined( ent.is_burning ) )
            continue;

        if ( isdefined( self.target ) && !ent istouching( self.volume ) )
            continue;

        if ( isplayer( ent ) )
        {
            if ( !isdefined( self.script_float ) || self.script_float >= 0.1 )
                ent thread maps\mp\zm_transit_lava::player_lava_damage( self );
        }
        else if ( !isdefined( ent.marked_for_death ) )
        {
            if ( !isdefined( self.script_float ) || self.script_float >= 0.1 )
                ent thread maps\mp\zm_transit_lava::zombie_lava_damage( self );
        }
    }
}

electric_door_changes() //BO2 Reimagined
{
	if (is_classic())
	{
		return;
	}

	zombie_doors = getentarray("zombie_door", "targetname");

	for (i = 0; i < zombie_doors.size; i++)
	{
        
		if (isDefined(zombie_doors[i].script_noteworthy) && (zombie_doors[i].script_noteworthy == "local_electric_door" || zombie_doors[i].script_noteworthy == "electric_door"))
		{
			if (zombie_doors[i].target == "lab_secret_hatch")
			{
				continue;
			}

			zombie_doors[i].script_noteworthy = "default";
			zombie_doors[i].zombie_cost = 750;

			// link Bus Depot and Farm electric doors together
			new_target = undefined;

			if (zombie_doors[i].target == "pf1766_auto2353")
			{
				new_target = "pf1766_auto2352";

			}
			else if (zombie_doors[i].target == "pf1766_auto2358")
			{
				new_target = "pf1766_auto2357";
			}

			if (isDefined(new_target))
			{
				targets = getentarray(zombie_doors[i].target, "targetname");
				zombie_doors[i].target = new_target;

				foreach (target in targets)
				{
					target.targetname = zombie_doors[i].target;
				}
			}
		}
	} 
}

town_vault_breach_init()
{
    vault_doors = getentarray( "town_bunker_door", "targetname" );
    array_thread( vault_doors, ::town_vault_breach );
}

town_vault_breach()
{
    if ( isdefined( self ) )
    {
        self.damage_state = 0;

        if ( isdefined( self.target ) )
        {
            clip = getent( self.target, "targetname" );
            clip linkto( self );
            self.clip = clip;
        }

        self thread vault_breach_think();
    }
    else
        return;
}

vault_breach_think()
{
    level endon( "intermission" );
    self.health = 99999;
    self setcandamage( 1 );
    self.damage_state = 0;
    self.clip.health = 99999;
    self.clip setcandamage( 1 );

    while ( true )
    {
        self thread track_clip_damage();
        self waittill( "damage", amount, attacker, direction, point, dmg_type, modelname, tagname, partname, weaponname );

        if ( isdefined( weaponname ) && ( weaponname == "emp_grenade_zm" || weaponname == "ray_gun_zm" || weaponname == "ray_gun_upgraded_zm" ) )
            continue;

        if ( isdefined( amount ) && amount <= 1 )
            continue;

        if ( isplayer( attacker ) && ( dmg_type == "MOD_PROJECTILE" || dmg_type == "MOD_PROJECTILE_SPLASH" || dmg_type == "MOD_EXPLOSIVE" || dmg_type == "MOD_EXPLOSIVE_SPLASH" || dmg_type == "MOD_GRENADE" || dmg_type == "MOD_GRENADE_SPLASH" ) )
        {
            if ( self.damage_state == 0 )
                self.damage_state = 1;

            playfxontag( level._effect["def_explosion"], self, "tag_origin" );
            self playsound( "exp_vault_explode" );
            self bunkerdoorrotate( 1 );

            if ( isdefined( self.script_flag ) )
                flag_set( self.script_flag );

            if ( isdefined( self.clip ) )
                self.clip connectpaths();

            wait 1;
            playsoundatposition( "zmb_cha_ching_loud", self.origin );
            return;
        }
    }
}

track_clip_damage()
{
    self endon( "damage" );
    self.clip waittill( "damage", amount, attacker, direction, point, dmg_type );
    self notify( "damage", amount, attacker, direction, point, dmg_type );
}

bunkerdoorrotate( open, time )
{
    if ( !isdefined( time ) )
        time = 0.2;

    rotate = self.script_float;

    if ( !open )
        rotate = rotate * -1;

    if ( isdefined( self.script_angles ) )
    {
        self notsolid();
        self rotateto( self.script_angles, time, 0, 0 );
        self thread maps\mp\zombies\_zm_blockers::door_solid_thread();
    }
}

is_not_busdepot()
{
	return !getdvar("g_gametype") == "zclassic" && getdvar("mapname") == "zm_transit" && getdvar("ui_zm_mapstartlocation") == "transit";
}

added_weapons()
{
    if (level.script == "zm_transit")
	{
        level.weapons_using_ammo_sharing = 1;

        include_weapon( "uzi_zm" );
        include_weapon( "uzi_upgraded_zm", 0 );
        add_zombie_weapon( "uzi_zm", "uzi_upgraded_zm", &"ZOMBIE_WEAPON_UZI", 1500, "wpck_smg", "", undefined );

        include_weapon( "thompson_zm" );
        include_weapon( "thompson_upgraded_zm", 0 );
        add_zombie_weapon( "thompson_zm", "thompson_upgraded_zm", &"ZMWEAPON_THOMPSON_WALLBUY", 1500, "wpck_smg", "", 800 );
    
        include_weapon( "ak47_zm" );
        include_weapon( "ak47_upgraded_zm", 0 );
        add_zombie_weapon( "ak47_zm", "ak47_upgraded_zm", &"ZOMBIE_WEAPON_AK47", 500, "wpck_mg", "", undefined, 1 );

        include_weapon( "mp40_stalker_zm" );
        include_weapon( "mp40_stalker_upgraded_zm", 0 );
        add_zombie_weapon( "mp40_stalker_zm", "mp40_stalker_upgraded_zm", &"ZOMBIE_WEAPON_MP40", 1300, "wpck_smg", "", undefined, 1 );

        include_weapon( "scar_zm" );
        include_weapon( "scar_upgraded_zm", 0 );
        add_zombie_weapon( "scar_zm", "scar_upgraded_zm", &"ZOMBIE_WEAPON_SCAR", 50, "wpck_rifle", "", undefined, 1 );

        include_weapon( "mg08_zm" );
        include_weapon( "mg08_upgraded_zm", 0 );
        add_zombie_weapon( "mg08_zm", "mg08_upgraded_zm", &"ZOMBIE_WEAPON_MG08", 50, "wpck_mg", "", undefined, 1 );

        include_weapon( "minigun_alcatraz_zm" );
        include_weapon( "minigun_alcatraz_upgraded_zm", 0 );
        add_limited_weapon( "minigun_alcatraz_zm", 1 );
        add_limited_weapon( "minigun_alcatraz_upgraded_zm", 1 );
        add_zombie_weapon( "minigun_alcatraz_zm", "minigun_alcatraz_upgraded_zm", &"ZOMBIE_WEAPON_RPD", 50, "wpck_mg", "", undefined, 1 );

        include_weapon( "evoskorpion_zm" );
        include_weapon( "evoskorpion_upgraded_zm", 0 );
        add_zombie_weapon( "evoskorpion_zm", "evoskorpion_upgraded_zm", &"ZOMBIE_WEAPON_EVOSKORPION", 50, "wpck_smg", "", undefined, 1 );

        include_weapon( "hk416_zm" );
        include_weapon( "hk416_upgraded_zm", 0 );
        add_zombie_weapon( "hk416_zm", "hk416_upgraded_zm", &"ZOMBIE_WEAPON_HK416", 100, "", "", undefined );

        include_weapon( "ksg_zm" );
        include_weapon( "ksg_upgraded_zm", 0 );
        add_zombie_weapon( "ksg_zm", "ksg_upgraded_zm", &"ZOMBIE_WEAPON_KSG", 1100, "wpck_shotgun", "", undefined, 1 );

        include_weapon( "pdw57_zm" );
        include_weapon( "pdw57_upgraded_zm", 0 );
        add_zombie_weapon( "pdw57_zm", "pdw57_upgraded_zm", &"ZOMBIE_WEAPON_PDW57", 1000, "smg", "", undefined );

        include_weapon( "mp44_zm" );
        include_weapon( "mp44_upgraded_zm", 0 );
        add_zombie_weapon( "mp44_zm", "mp44_upgraded_zm", &"ZMWEAPON_MP44_WALLBUY", 1400, "wpck_rifle", "", undefined, 1 );

        include_weapon( "ballista_zm" );
        include_weapon( "ballista_upgraded_zm", 0 );
        add_zombie_weapon( "ballista_zm", "ballista_upgraded_zm", &"ZMWEAPON_BALLISTA_WALLBUY", 500, "wpck_snipe", "", undefined, 1 );

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
        add_zombie_weapon( "svu_zm", "svu_upgraded_zm", &"ZOMBIE_WEAPON_SVU", 1000, "wpck_svuas", "", undefined, 1 );

        include_weapon( "c96_zm" );
        include_weapon( "c96_upgraded_zm", 0 );
        add_zombie_weapon( "c96_zm", "c96_upgraded_zm", &"ZOMBIE_WEAPON_C96", 50, "wpck_pistol", "", undefined, 1 );

        /* AK74u Extended Clip */
        include_weapon( "ak74u_extclip_zm" );
        include_weapon( "ak74u_extclip_upgraded_zm", 0 );
        add_zombie_weapon( "ak74u_extclip_zm", "ak74u_extclip_upgraded_zm", &"ZOMBIE_WEAPON_AK74U", 1200, "smg", "", undefined, 1 );
        add_shared_ammo_weapon( "ak74u_extclip_zm", "ak74u_zm" );

        /* B23R Extended Clip */
        include_weapon( "beretta93r_extclip_zm" );
        include_weapon( "beretta93r_extclip_upgraded_zm", 0 );
        add_zombie_weapon( "beretta93r_extclip_zm", "beretta93r_extclip_upgraded_zm", &"ZOMBIE_WEAPON_BERETTA93r", 1000, "", "", undefined, 1 );
        add_shared_ammo_weapon( "beretta93r_extclip_zm", "beretta93r_zm" );
	}
}

// ============================================================================
//  zmqol_no_power_transit_extras  -  NO POWER NEEDED's TranZit half (v2.11.22)
// ============================================================================
//  The root row (qol_options.gsc) runs stock's turn_power_on_and_open_doors(),
//  which covers the flag, the client sync and every door. TranZit needs one
//  more thing that no other map has: a SECOND flag.
//
//  zm_transit_power.gsc's electricswitch() sets "switches_on" BEFORE "power_on"
//  (:63 then :68) and three separate systems read it on its own:
//      powerevent()              :395  the reactor core rise - the thing that
//                                      makes the power station look powered
//      _zm_ai_avogadro.gsc      :1295  needs power_on AND switches_on together
//      zm_transit_sq.gsc   :962/:994/  four side-quest gates, each testing both
//                    :1037/:1118
//  Leaving it clear meant the map had power while every system that asks the
//  second question still believed it did not.
//
//  🛑 flag_exists() FIRST, ALWAYS. "switches_on" is flag_init()'d inside
//  zm_transit_power.gsc:43, so it exists only once that script has run - and
//  flag_set() on an uninitialised flag asserts. This file is TranZit-only so
//  the flag will be there, but the guard costs nothing and the failure it
//  prevents is a load-time assert.
//
//  Setting it AFTER power_on rather than before is deliberate and harmless:
//  powerevent() is already threaded (zm_transit_power.gsc:16), so it picks the
//  flag up and plays the full 30-second reactor sequence exactly as it would
//  have; nothing waits on "power_event_complete" except the switch's own loop,
//  which is parked on its trigger.
// ============================================================================
//  🌟 v2.11.24 - A LOOP, BECAUSE THE ROW IS A TOGGLE NOW.
//
//  Clearing "switches_on" is stock's own way down: zm_transit_power.gsc:90 does
//  exactly this when a player flips the real switch back off, and powerevent()
//  (:382) is a two-way loop parked on flag_waitopen( "switches_on" ) - so the
//  clear plays the full 30-second reactor-lowering sequence, doors and all,
//  with no help from this file.
//
//  📝 STOCK CLEARS "switches_on" FIRST AND "power_on" 30 SECONDS LATER, after
//  "power_event_complete". This row clears power_on immediately (in
//  qol_options.gsc) and the two run concurrently instead: a cheat row that took
//  30 seconds to go off would read as broken. The only visible difference is
//  that the lights die before the reactor finishes sinking. Nothing waits on
//  that ordering - _zm_ai_avogadro and the four zm_transit_sq gates test both
//  flags and see both clear either way.
zmqol_no_power_transit_extras()
{
    level endon( "end_game" );

    for ( ;; )
    {
        if ( !( isdefined( level.zmqol_no_power_applied ) && level.zmqol_no_power_applied ) )
            level waittill( "zmqol_no_power_applied" );

        b_did = 0;

        if ( !flag_exists( "switches_on" ) )
        {
            println( "[zm_qol] no_power: switches_on does not exist on " + level.script + " - skipped" );
        }
        else if ( flag( "switches_on" ) )
        {
            println( "[zm_qol] no_power: switches_on was already set - nothing to do" );
        }
        else
        {
            flag_set( "switches_on" );
            b_did = 1;
            println( "[zm_qol] no_power: switches_on set - reactor event, Avogadro and the side-quest gates now agree with the power flag" );
        }

        //  Guarded, not a bare waittill: a notify fired while this thread was
        //  inside its apply block above (the Origins one yields on every
        //  generator) would be missed, and the thread would park here for the
        //  rest of the match. If the row is already off, the restore runs now.
        if ( isdefined( level.zmqol_no_power_applied ) && level.zmqol_no_power_applied )
            level waittill( "zmqol_no_power_reverted" );

        if ( b_did && flag_exists( "switches_on" ) && flag( "switches_on" ) )
        {
            flag_clear( "switches_on" );
            println( "[zm_qol] no_power: switches_on cleared - stock's powerevent() lowers the reactor" );
        }
    }
}

