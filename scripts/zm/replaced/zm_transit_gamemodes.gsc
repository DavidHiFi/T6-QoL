#include maps\mp\zm_transit_gamemodes;
#include maps\mp\zm_transit_grief_town;
#include maps\mp\zm_transit_grief_farm;
#include maps\mp\zm_transit_grief_station;
#include maps\mp\zm_transit_standard_town;
#include maps\mp\zm_transit_standard_farm;
#include maps\mp\zm_transit_standard_station;
#include maps\mp\zm_transit_classic;
#include maps\mp\zm_transit;
#include maps\mp\gametypes_zm\_zm_gametype;
#include maps\mp\zm_transit_utility;
#include maps\mp\zombies\_zm_game_module;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\_utility;
#include common_scripts\utility;

// ============================================================================
//  Everything here except the DINER / POWER / TUNNEL lines is a verbatim copy
//  of stock maps\mp\zm_transit_gamemodes::init. Stock registers only transit,
//  farm and town on each mode (verified against the stock dump), so all three
//  custom locations are entirely additions here.
//
//  Power Station and Tunnel were first shipped pre-v1.15.0, verified in game
//  2026-08-02 (checkpoint 12), stripped in v1.15.0 at the user's call, and
//  restored 2026-09-02 at the user's request. Registration lines are byte-for-
//  byte the pre-strip ones (git d722590).
//
//  🛑 TUNNEL WAS REMOVED IN v2.14.0 ("remove tunnel survival") and PUT BACK IN
//  v2.14.30 (2026-09-08, user: "add back tunnel survival i dont know why you
//  removed it, it was fine, and add a mystery box to it"). Everything it needs
//  came back in the same change: the loc script (now with a box), the
//  transit_zone_init enable block, the client wall-buy twin in zm_expanded.csc,
//  the lobby row and its two mod.ff materials. Cornfield has been out since
//  the v2.10.0 restoration.
//
//  Diner is the one location that never needed the transit_zone_init override -
//  its zones (zone_gas / zone_roadside_east / zone_roadside_west) all have
//  stock adjacency edges, so they come up on their own. Tunnel and Power need
//  the override in scripts\zm\replaced\zm_transit.gsc: Tunnel's zone is an
//  island with no adjacency edge, and Power's five zones are outside the
//  non-classic init set. Both are hooked from scripts\zm\zm_transit\
//  zm_transit.gsc::main().
// ============================================================================
init()
{
	add_map_gamemode("zclassic", maps\mp\zm_transit::zclassic_preinit, undefined, undefined);
	add_map_gamemode("zgrief", maps\mp\zm_transit::zgrief_preinit, undefined, undefined);
	add_map_gamemode("zstandard", maps\mp\zm_transit::zstandard_preinit, undefined, undefined);

	add_map_location_gamemode("zclassic", "transit", maps\mp\zm_transit_classic::precache, maps\mp\zm_transit_classic::main);

	add_map_location_gamemode("zstandard", "transit", maps\mp\zm_transit_standard_station::precache, maps\mp\zm_transit_standard_station::main);
	add_map_location_gamemode("zstandard", "farm", maps\mp\zm_transit_standard_farm::precache, maps\mp\zm_transit_standard_farm::main);
	add_map_location_gamemode("zstandard", "town", maps\mp\zm_transit_standard_town::precache, maps\mp\zm_transit_standard_town::main);
	add_map_location_gamemode("zstandard", "diner", scripts\zm\locs\zm_transit_loc_diner::precache, scripts\zm\locs\zm_transit_loc_diner::main);
	add_map_location_gamemode("zstandard", "power", scripts\zm\locs\zm_transit_loc_power::precache, scripts\zm\locs\zm_transit_loc_power::main);
	add_map_location_gamemode("zstandard", "tunnel", scripts\zm\locs\zm_transit_loc_tunnel::precache, scripts\zm\locs\zm_transit_loc_tunnel::main);

	add_map_location_gamemode("zgrief", "transit", maps\mp\zm_transit_grief_station::precache, maps\mp\zm_transit_grief_station::main);
	add_map_location_gamemode("zgrief", "farm", maps\mp\zm_transit_grief_farm::precache, maps\mp\zm_transit_grief_farm::main);
	add_map_location_gamemode("zgrief", "town", maps\mp\zm_transit_grief_town::precache, maps\mp\zm_transit_grief_town::main);
	add_map_location_gamemode("zgrief", "diner", scripts\zm\locs\zm_transit_loc_diner::precache, scripts\zm\locs\zm_transit_loc_diner::main);
	add_map_location_gamemode("zgrief", "power", scripts\zm\locs\zm_transit_loc_power::precache, scripts\zm\locs\zm_transit_loc_power::main);
	add_map_location_gamemode("zgrief", "tunnel", scripts\zm\locs\zm_transit_loc_tunnel::precache, scripts\zm\locs\zm_transit_loc_tunnel::main);

	scripts\zm\replaced\utility::add_struct_location_gamemode_func("zstandard", "diner", scripts\zm\locs\zm_transit_loc_diner::struct_init);
	scripts\zm\replaced\utility::add_struct_location_gamemode_func("zgrief", "diner", scripts\zm\locs\zm_transit_loc_diner::struct_init);
	scripts\zm\replaced\utility::add_struct_location_gamemode_func("zstandard", "power", scripts\zm\locs\zm_transit_loc_power::struct_init);
	scripts\zm\replaced\utility::add_struct_location_gamemode_func("zgrief", "power", scripts\zm\locs\zm_transit_loc_power::struct_init);
	scripts\zm\replaced\utility::add_struct_location_gamemode_func("zstandard", "tunnel", scripts\zm\locs\zm_transit_loc_tunnel::struct_init);
	scripts\zm\replaced\utility::add_struct_location_gamemode_func("zgrief", "tunnel", scripts\zm\locs\zm_transit_loc_tunnel::struct_init);
}
