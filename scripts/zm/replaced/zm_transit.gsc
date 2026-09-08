#include maps\mp\zm_transit;
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_zonemgr;
// 🛑 REQUIRED: the stock body below calls disconnect_door_zones() unqualified.
// That function lives in maps\mp\zm_transit_utility, and stock zm_transit.gsc
// only gets it via its own #include of that file. Copying the body without this
// line throws "Unresolved external: disconnect_door_zones with 3 parameters" at
// SCRIPT LOAD, which kills every TranZit location (Tunnel, Diner, classic) with
// a COM_ERROR before the map starts. Confirmed in console_zm.log 2026-08-02.
#include maps\mp\zm_transit_utility;

// ============================================================================
//  transit_zone_init   -   replaces maps\mp\zm_transit::transit_zone_init
//
//  🛑 Fixes: POWER STATION SURVIVAL KILLS THE PLAYER AT MAP LOAD.
//  (Tunnel had the identical fault and is the case the derivation below is
//   written against; that location was removed in v2.14.0, Power's fix stays.)
//
//  The body below is STOCK, verbatim, with ONE addition at the end (the
//  zone_init/enable_zone block). Everything else is unchanged so classic
//  TranZit, Diner and the stock locations behave exactly as before.
//
//  Restored 2026-09-02 from the pre-strip copy (git d722590) that was verified
//  in game 2026-08-02, with two deliberate changes from that copy:
//    - the Cornfield zone enables are gone (Cornfield is excluded from the
//      restoration by the user's request), and
//    - the Tunnel enable is now gated on ui_zm_mapstartlocation == "tunnel".
//      The pre-strip copy enabled zone_amb_tunnel for EVERY non-classic
//      location; today's Diner is verified working WITHOUT this file, so the
//      gate keeps every other location's zone set exactly as it boots now.
//
//  --- WHY -------------------------------------------------------------------
//  maps\mp\zombies\_zm_zonemgr::manage_zones() runs in this order:
//
//      1. spawn_points = _zm_gametype::get_player_spawns_for_gametype();
//         for each: spawn_points[i].locked = 1;        <-- ALL respawns locked
//      2. [[ level.zone_manager_init_func ]]();        <-- this function
//      3. for each initial zone: zone_init(); enable_zone();
//
//  and enable_zone( name ) is the ONLY thing that unlocks a respawn point:
//
//      if ( spawn_points[i].script_noteworthy == zone_name )
//          spawn_points[i].locked = 0;
//
//  Tunnel registers its whole respawn group under script_noteworthy
//  "zone_amb_tunnel" (scripts\zm\locs\zm_transit_loc_tunnel::struct_init, via
//  scripts\zm\replaced\utility::register_map_spawn_group). But stock TranZit
//  only puts zone_amb_tunnel in init_zones INSIDE `if ( is_classic() )`
//  (zm_transit.gsc:371-390) - in zstandard/zgrief the zone is never created,
//  never enabled, and it has no add_adjacent_zone edge anywhere in this
//  function, so no door-opening can ever reach it either.
//
//  Result on Tunnel survival: every tunnel respawn point stays locked forever,
//  _zm_gametype::onspawnplayer finds no usable spawn and falls through to
//  `getstructarray( "initial_spawn_points", "targetname" )` - the map default,
//  back at the Bus Depot, where the non-classic pass has already deleted the
//  "classic_only" player_volume areas. The player is dumped outside the
//  playable area and dies at once. That is the "death barrier".
//
//  This is also exactly why Diner works and Tunnel does not: Diner's zones
//  (zone_gas / zone_roadside_east / zone_roadside_west) all have adjacency
//  edges below, so they get created and reached normally.
//
//  --- WHY THIS FUNCTION AND NOT SOMEWHERE CHEAPER ---------------------------
//  The enable has to land between steps 1 and 3 above. level.zone_manager_init_func
//  is only assigned inside maps\mp\zm_transit::main(), which runs AFTER our
//  main() - so re-pointing the level var (CLAUDE.md section 4, failure mode 2)
//  is not available here and the function itself has to be replaced.
//
//  Verified against BO2-Reimagined, which fixes this identically:
//  scripts\zm\replaced\zm_transit.gsc:228-235 - same zones, same place,
//  hooked from scripts\zm\zm_transit\zm_transit_reimagined.gsc:24.
// ============================================================================
transit_zone_init()
{
    flag_init( "always_on" );
    flag_init( "init_classic_adjacencies" );
    flag_set( "always_on" );

    if ( is_classic() )
    {
        flag_set( "init_classic_adjacencies" );
        add_adjacent_zone( "zone_trans_2", "zone_trans_2b", "init_classic_adjacencies" );
        add_adjacent_zone( "zone_station_ext", "zone_trans_2b", "init_classic_adjacencies", 1 );
        add_adjacent_zone( "zone_town_west2", "zone_town_west", "init_classic_adjacencies" );
        add_adjacent_zone( "zone_town_south", "zone_town_church", "init_classic_adjacencies" );
        add_adjacent_zone( "zone_trans_pow_ext1", "zone_trans_7", "init_classic_adjacencies" );
        add_adjacent_zone( "zone_far", "zone_far_ext", "OnFarm_enter" );
    }
    else
    {
        playable_area = getentarray( "player_volume", "script_noteworthy" );

        foreach ( area in playable_area )
        {
            add_adjacent_zone( "zone_station_ext", "zone_trans_2b", "always_on" );

            if ( isdefined( area.script_parameters ) && area.script_parameters == "classic_only" )
                area delete();
        }
    }

    add_adjacent_zone( "zone_pri2", "zone_station_ext", "OnPriDoorYar", 1 );
    add_adjacent_zone( "zone_pri2", "zone_pri", "OnPriDoorYar3", 1 );

    if ( getdvar( "ui_zm_mapstartlocation" ) == "transit" )
    {
        level thread disconnect_door_zones( "zone_pri2", "zone_station_ext", "OnPriDoorYar" );
        level thread disconnect_door_zones( "zone_pri2", "zone_pri", "OnPriDoorYar3" );
    }

    add_adjacent_zone( "zone_station_ext", "zone_pri", "OnPriDoorYar2" );
    add_adjacent_zone( "zone_roadside_west", "zone_din", "OnGasDoorDin" );
    add_adjacent_zone( "zone_roadside_west", "zone_gas", "always_on" );
    add_adjacent_zone( "zone_roadside_east", "zone_gas", "always_on" );
    add_adjacent_zone( "zone_roadside_east", "zone_gar", "OnGasDoorGar" );
    add_adjacent_zone( "zone_trans_diner", "zone_roadside_west", "always_on", 1 );
    add_adjacent_zone( "zone_trans_diner", "zone_gas", "always_on", 1 );
    add_adjacent_zone( "zone_trans_diner2", "zone_roadside_east", "always_on", 1 );
    add_adjacent_zone( "zone_gas", "zone_din", "OnGasDoorDin" );
    add_adjacent_zone( "zone_gas", "zone_gar", "OnGasDoorGar" );
    add_adjacent_zone( "zone_diner_roof", "zone_din", "OnGasDoorDin", 1 );
    add_adjacent_zone( "zone_amb_cornfield", "zone_cornfield_prototype", "always_on" );
    add_adjacent_zone( "zone_tow", "zone_bar", "always_on", 1 );
    add_adjacent_zone( "zone_bar", "zone_tow", "OnTowDoorBar", 1 );
    add_adjacent_zone( "zone_tow", "zone_ban", "OnTowDoorBan" );
    add_adjacent_zone( "zone_ban", "zone_ban_vault", "OnTowBanVault" );
    add_adjacent_zone( "zone_tow", "zone_town_north", "always_on" );
    add_adjacent_zone( "zone_town_north", "zone_ban", "OnTowDoorBan" );
    add_adjacent_zone( "zone_tow", "zone_town_west", "always_on" );
    add_adjacent_zone( "zone_tow", "zone_town_south", "always_on" );
    add_adjacent_zone( "zone_town_south", "zone_town_barber", "always_on", 1 );
    add_adjacent_zone( "zone_tow", "zone_town_east", "always_on" );
    add_adjacent_zone( "zone_town_east", "zone_bar", "OnTowDoorBar" );
    add_adjacent_zone( "zone_tow", "zone_town_barber", "always_on", 1 );
    add_adjacent_zone( "zone_town_barber", "zone_tow", "OnTowDoorBarber", 1 );
    add_adjacent_zone( "zone_town_barber", "zone_town_west", "OnTowDoorBarber" );
    add_adjacent_zone( "zone_far_ext", "zone_brn", "OnFarm_enter" );
    add_adjacent_zone( "zone_far_ext", "zone_farm_house", "open_farmhouse" );
    add_adjacent_zone( "zone_prr", "zone_pow", "OnPowDoorRR", 1 );
    add_adjacent_zone( "zone_pcr", "zone_prr", "OnPowDoorRR" );
    add_adjacent_zone( "zone_pcr", "zone_pow_warehouse", "OnPowDoorWH" );
    add_adjacent_zone( "zone_pow", "zone_pow_warehouse", "OnPowDoorWH" );
    add_adjacent_zone( "zone_tbu", "zone_tow", "vault_opened", 1 );

    // ---- zm_qol addition: everything above this line is stock ----------------
    // zone_init() is idempotent (it returns early if the zone already exists) and
    // enable_zone() no-ops on an already-enabled zone, so this is safe even if a
    // future stock path starts creating them.
    if ( !is_classic() )
    {
        // 🛑 Tunnel survival: zone_amb_tunnel is an island with no adjacency
        // edge and is only put in init_zones under is_classic(), so nothing
        // ever creates or enables it here - the WHY section at the top of this
        // file is the full chain. Removed with the location in v2.14.0, back
        // with it in v2.14.30 (user, 2026-09-08: "add back tunnel survival").
        if ( getdvar( "ui_zm_mapstartlocation" ) == "tunnel" )
        {
            zone_init( "zone_amb_tunnel" );
            enable_zone( "zone_amb_tunnel" );
        }

        // 🛑 Power Station survival: instant death on spawn.
        //
        // Same mechanism as Tunnel, different symptom path. scripts\zm\locs\
        // zm_transit_loc_power::struct_init DOES register initial_spawn structs
        // (16 of its 17 register_map_spawn calls pass a team_num), so the player
        // spawns in the RIGHT PLACE - it is not the map-default fallthrough that
        // hit Cell Block. What kills them is the playable area:
        // _zm::in_enabled_playable_area() (_zm.gsc:1442-1456) only counts a
        // "player_volume" whose targetname is an ENABLED zone, and TranZit's
        // non-classic init_zones is just zone_pri / zone_station_ext / zone_tow /
        // zone_far_ext / zone_brn (zm_transit.gsc:391-396). None of the power
        // station's zones are in it, and they have no adjacency edge that the
        // enabled set can reach, so the player stands in a volume that is never
        // enabled and the out-of-area monitor kills them.
        //
        // Gated on the location so Diner, Tunnel and Town keep the zone set they
        // are already working with - enabling zones also opens them to zombie
        // spawning.
        if ( getdvar( "ui_zm_mapstartlocation" ) == "power" )
        {
            // The power station arena is FIVE zones, not the three the loc
            // script happens to register spawn groups for. Enabling only those
            // three stopped the instant death at spawn but left the rest of the
            // arena outside the enabled playable area, so walking into the back
            // corner by the power station building - which is zone_pcr - tripped
            // the out-of-area monitor and killed the player on the spot.
            //
            // The full set is not a guess: BO2-Reimagined's Containment mode
            // enumerates exactly this area as
            //   containment_zones = array( "zone_pow", "zone_trans_8", "zone_prr",
            //                              "zone_pcr", "zone_pow_warehouse" );
            // (scripts\zm\zencounter\zencounter_reimagined.gsc:2742).
            //
            // zone_trans_8 belongs to the arena as walkable ground but must NOT
            // spawn zombies - it is the bus route. zm_transit_loc_power::
            // disable_zombie_spawn_locations already sets
            // level.zones["zone_trans_8"].is_spawning_allowed = 0, and that runs
            // from main() AFTER manage_zones, so enabling it here is safe and is
            // in fact what makes that pre-existing line meaningful: you cannot
            // disable spawning in a zone that was never enabled.
            zone_init( "zone_prr" );
            enable_zone( "zone_prr" );

            zone_init( "zone_pow" );
            enable_zone( "zone_pow" );

            zone_init( "zone_pow_warehouse" );
            enable_zone( "zone_pow_warehouse" );

            zone_init( "zone_pcr" );
            enable_zone( "zone_pcr" );

            zone_init( "zone_trans_8" );
            enable_zone( "zone_trans_8" );
        }
    }
}
