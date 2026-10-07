#include clientscripts\mp\_utility;
#include clientscripts\mp\zombies\_zm_utility;
#include clientscripts\mp\zombies\_zm_weapons;
#include clientscripts\mp\zm_prison;
#include clientscripts\mp\zombies\_zm;
#include clientscripts\mp\zm_alcatraz_classic;
#include clientscripts\mp\zm_alcatraz_grief_cellblock;

main()
{
    replaceFunc(clientscripts\mp\zm_prison::include_weapons, ::include_weapons);
    // --- Cell Block survival (client half; server half in
    //     replaced\zm_alcatraz_gamemodes.gsc) ---
    replaceFunc(clientscripts\mp\zm_prison::init_gamemodes, ::init_gamemodes);
}

// ============================================================================
//  init_gamemodes  (CLIENT)
//
//  🛑 Fixes Docks loading to a BLACK SCREEN with no input (must force-quit).
//
//  scripts\zm\replaced\zm_alcatraz_gamemodes.gsc adds a "zstandard" gamemode to
//  Mob of the Dead on the SERVER, plus the docks location. Stock
//  clientscripts\mp\zm_prison::init_gamemodes registers only zclassic and zgrief -
//  there is no zstandard on the client at all. Both of these, in
//  clientscripts\mp\zombies\_zm.csc, then bail immediately:
//
//      start_zombie_gametype()   (_zm.csc:132)
//      zombe_gametype_premain()  (_zm.csc:107)
//          gamemode = getdvar( #"ui_gametype" );          // "zstandard"
//          if ( !isdefined( level.gamemode_map_location_main[gamemode] ) )
//              return;
//
//  That early return also skips level._zombie_gamemodemain, which is what ends the
//  client's loading state - hence a black screen the server never releases.
//
//  Why TranZit's added locations do NOT hit this: stock
//  clientscripts\mp\zm_transit::init_gamemodes DOES register zstandard (with
//  transit/farm/town). Diner and Cornfield have no client *location* entry either
//  and both work - a missing location only skips the optional per-location main,
//  which is guarded separately at _zm.csc:153. It is the missing *gamemode* that is
//  fatal. Docks therefore needs no client-side location funcs, only the gamemode.
//
//  zclassic/zgrief entries below are copied verbatim from stock so the classic and
//  grief paths are unchanged.
//
//  🛑 NOT verified in game yet.
// ============================================================================
init_gamemodes()
{
    add_map_gamemode( "zclassic", undefined, undefined );
    add_map_gamemode( "zgrief", undefined, undefined );
    add_map_gamemode( "zstandard", undefined, undefined );

    add_map_location_gamemode( "zclassic", "prison", clientscripts\mp\zm_alcatraz_classic::precache, clientscripts\mp\zm_alcatraz_classic::premain, clientscripts\mp\zm_alcatraz_classic::main );
    add_map_location_gamemode( "zgrief", "cellblock", clientscripts\mp\zm_alcatraz_grief_cellblock::precache, undefined, clientscripts\mp\zm_alcatraz_grief_cellblock::main );
    add_map_location_gamemode( "zstandard", "cellblock", clientscripts\mp\zm_alcatraz_grief_cellblock::precache, undefined, clientscripts\mp\zm_alcatraz_grief_cellblock::main );
}

include_weapons()
{
    include_weapon( "knife_zm", 0 );
    include_weapon( "knife_zm_alcatraz", 0 );
    include_weapon( "spoon_zm_alcatraz", 0 );
    include_weapon( "spork_zm_alcatraz", 0 );
    include_weapon( "frag_grenade_zm", 0 );
    include_weapon( "claymore_zm", 0 );
    include_weapon( "willy_pete_zm", 0 );
    include_weapon( "m1911_zm", 0 ); //
    include_weapon( "m1911_upgraded_zm", 0 );
    include_weapon( "judge_zm", 0 ); //
    include_weapon( "judge_upgraded_zm", 0 );
    //  fiveseven_zm pair swapped out 2026-10-07 round 2: gunswap.gsc bans the
    //  stock pair and browninghp_zm (same root list) takes the slots.
    include_weapon( "beretta93r_zm", 0 );
    include_weapon( "beretta93r_upgraded_zm", 0 );
    //  fivesevendw_zm pair swapped out 2026-10-07 round 2: gunswap.gsc bans
    //  the stock pair and browninghpdw_zm (oldschool.gsc, all six maps now)
    //  takes the slots.
    include_weapon( "uzi_zm", 0 );
    include_weapon( "uzi_upgraded_zm", 0 );
    include_weapon( "thompson_upgraded_zm", 0 );
    include_weapon( "mp5k_zm", 0 );
    include_weapon( "mp5k_upgraded_zm", 0 );

    if ( is_classic() )
    {
        include_weapon( "thompson_zm", 0 );
        include_weapon( "870mcs_zm", 0 );
    }
    else
    {
        include_weapon( "870mcs_zm" );
        include_weapon( "thompson_zm" );
    }

    include_weapon( "pdw57_zm", 0 ); //
    include_weapon( "pdw57_upgraded_zm", 0 );
    include_weapon( "870mcs_upgraded_zm", 0 );
    //  saiga12_zm pair swapped out 2026-10-07 round 2: gunswap.gsc bans the
    //  stock pair and spas_zm (the restored SPAS-12, same root list) takes
    //  the slots.
    include_weapon( "rottweil72_zm", 0 );
    include_weapon( "rottweil72_upgraded_zm", 0 );
    include_weapon( "m14_zm", 0 );
    include_weapon( "m14_upgraded_zm", 0 );
    include_weapon( "ak47_zm" );
    include_weapon( "ak47_upgraded_zm", 0 );
    include_weapon( "tar21_zm", 0 ); //
    include_weapon( "tar21_upgraded_zm", 0 );
    include_weapon( "galil_zm" );
    include_weapon( "galil_upgraded_zm", 0 );
    include_weapon( "fnfal_zm", 0 ); //
    include_weapon( "fnfal_upgraded_zm", 0 );
    include_weapon( "dsr50_zm", 0 ); //
    include_weapon( "dsr50_upgraded_zm", 0 );
    //  barretm82_zm pair swapped out 2026-10-07 round 2: gunswap.gsc bans the
    //  stock pair and dragunov_zm (zm_expanded.csc root list) takes the slots.
    include_weapon( "minigun_alcatraz_zm" );
    include_weapon( "minigun_alcatraz_upgraded_zm", 0 );
    include_weapon( "lsat_zm" );
    include_weapon( "lsat_upgraded_zm", 0 );
    //  usrpg_zm pair swapped out 2026-10-07: gunswap.gsc bans the stock pair
    //  from registration and rpg_zm (BO1 RPG-7) takes the slots.
    include_weapon( "ray_gun_zm" );
    include_weapon( "ray_gun_upgraded_zm", 0 );
    include_weapon( "bouncing_tomahawk_zm", 0 );
    include_weapon( "alcatraz_shield_zm", 0 );
    include_weapon( "blundergat_zm" );
    include_weapon( "blundergat_upgraded_zm", 0 );
    include_weapon( "blundersplat_zm", 0 );
    include_weapon( "blundersplat_upgraded_zm", 0 );
    // Added weapons
    include_weapon( "mp40_stalker_zm" );
    include_weapon( "mp40_stalker_upgraded_zm", 0 );
    include_weapon( "scar_zm" );
    include_weapon( "scar_upgraded_zm", 0 );
    include_weapon( "mg08_zm" );
    include_weapon( "mg08_upgraded_zm", 0 );
    include_weapon( "evoskorpion_zm" );
    include_weapon( "evoskorpion_upgraded_zm", 0 );
    include_weapon( "hk416_zm" );
    include_weapon( "hk416_upgraded_zm", 0 );
    include_weapon( "ksg_zm" );
    include_weapon( "ksg_upgraded_zm", 0 );
    include_weapon( "mp44_zm" );
    include_weapon( "mp44_upgraded_zm", 0 );
    include_weapon( "ballista_zm" );
    include_weapon( "ballista_upgraded_zm", 0 );
    include_weapon( "rnma_zm" );
    include_weapon( "rnma_upgraded_zm", 0 );
    include_weapon( "an94_zm" );
    include_weapon( "an94_upgraded_zm", 0 );
    include_weapon( "svu_zm" );
    include_weapon( "svu_upgraded_zm", 0 );
    include_weapon( "c96_zm" );
    include_weapon( "c96_upgraded_zm", 0 );
    // Tranzit weapons
    include_weapon( "qcw05_zm" );
    include_weapon( "qcw05_upgraded_zm", 0 );
    include_weapon( "ak74u_extclip_zm" );
    include_weapon( "ak74u_extclip_upgraded_zm", 0 );
    include_weapon( "beretta93r_extclip_zm", 0 );
    include_weapon( "beretta93r_extclip_upgraded_zm", 0 );
    include_weapon( "saritch_zm" );
    include_weapon( "saritch_upgraded_zm", 0 );
    include_weapon( "m16_zm" );
    include_weapon( "m16_gl_upgraded_zm", 0 );
    include_weapon( "type95_zm" );
    include_weapon( "type95_upgraded_zm", 0 );
    include_weapon( "xm8_zm" );
    include_weapon( "xm8_upgraded_zm", 0 );
    include_weapon( "srm1216_zm" );
    include_weapon( "srm1216_upgraded_zm", 0 );
    //  rpd_zm and hamr_zm pairs (the mod's own additions) came out 2026-10-07
    //  round 2: gunswap.gsc bans the stock pairs too and m60_zm / mk48_zm
    //  (zm_expanded.csc root list) take the slots.
    include_weapon( "python_zm" );
    include_weapon( "python_upgraded_zm", 0 );
    include_weapon( "kard_zm" );
    include_weapon( "kard_upgraded_zm", 0 );
    //  m32_zm pair (the War Machine) came out 2026-10-07: the MM1 covers the
    //  launcher slot in both Mob modes now (oldschool.gsc).

    if ( isdefined( level.raygun2_included ) && level.raygun2_included && !isdemoplaying() )
    {
        include_weapon( "raygun_mark2_zm", hasdlcavailable( "dlc3" ) );
        include_weapon( "raygun_mark2_upgraded_zm", 0 );
    }
}