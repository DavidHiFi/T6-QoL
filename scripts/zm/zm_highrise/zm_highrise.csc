#include clientscripts\mp\_utility;
#include clientscripts\mp\zombies\_zm_utility;
#include clientscripts\mp\zombies\_zm_weapons;
#include clientscripts\mp\zm_highrise;
#include clientscripts\mp\zombies\_zm;
#include clientscripts\mp\zm_highrise_classic;

main()
{
    replaceFunc(clientscripts\mp\zm_highrise::include_weapons, ::include_weapons);
    // --- Die Rise survival locations (client half; server half in
    //     replaced\zm_highrise_gamemodes.gsc) ---
    replaceFunc(clientscripts\mp\zm_highrise::init_gamemodes, ::init_gamemodes);
}

// ============================================================================
//  init_gamemodes  (CLIENT)
//
//  Same defect as zm_prison\zm_prison.csc - see the long comment there.
//
//  scripts\zm\replaced\zm_highrise_gamemodes.gsc adds zstandard AND zgrief on the
//  server (Shopping Mall, Dragon Rooftop, Sweatshop). Stock
//  clientscripts\mp\zm_highrise::init_gamemodes registers only zclassic, so the
//  client's start_zombie_gametype() bails and the loading state is never released.
//
//  🛑 NOT verified in game yet - Die Rise's custom locations have never been tested.
// ============================================================================
init_gamemodes()
{
    add_map_gamemode( "zclassic", undefined, undefined );
    add_map_gamemode( "zstandard", undefined, undefined );
    add_map_gamemode( "zgrief", undefined, undefined );

    add_map_location_gamemode( "zclassic", "rooftop", clientscripts\mp\zm_highrise_classic::precache, clientscripts\mp\zm_highrise_classic::premain, clientscripts\mp\zm_highrise_classic::main );

    // 🛑 Fixes: EXE_CLIENT_FIELD_MISMATCH on every Die Rise survival location -
    //    "Clientfield buildable in set [toplayer] is not registered on the client".
    //
    // The three gamemodes above were declared but NO location functions were ever
    // registered for zstandard/zgrief, so on Shopping Mall, Dragon Rooftop and
    // Sweatshop the client ran no location script at all. It therefore never
    // included a single buildable, and
    // clientscripts\mp\zombies\_zm_buildables.csc:25-34 only calls
    // register_clientfields() when the FIRST buildable is added
    // ( if ( level.zombie_buildables.size == 1 ) ). The server meanwhile does
    // register buildables, so the server had the "buildable" clientfield and the
    // client did not - hence the mismatch and the instant disconnect.
    //
    // Note this is the OPPOSITE direction to the seven fields fixed server-side
    // in v1.4.0 (those were client-has/server-lacks), which is why that fix could
    // never have covered this one.
    //
    // Pointing them at zm_highrise_classic's client functions is the same
    // technique already used on Buried, where zstandard/zgrief "street" reuse
    // clientscripts\mp\zm_buried_grief_street. Die Rise ships exactly one client
    // location script, so it is the only correct target.
    a_locations = array( "shopping_mall", "dragon_rooftop", "sweatshop" );

    foreach ( str_loc in a_locations )
    {
        add_map_location_gamemode( "zstandard", str_loc, clientscripts\mp\zm_highrise_classic::precache, clientscripts\mp\zm_highrise_classic::premain, clientscripts\mp\zm_highrise_classic::main );
        add_map_location_gamemode( "zgrief", str_loc, clientscripts\mp\zm_highrise_classic::precache, clientscripts\mp\zm_highrise_classic::premain, clientscripts\mp\zm_highrise_classic::main );
    }
}

include_weapons()
{
    include_weapon( "knife_zm", 0 );
    include_weapon( "frag_grenade_zm", 0 );
    include_weapon( "claymore_zm", 0 );
    include_weapon( "sticky_grenade_zm", 0 );
    include_weapon( "m1911_zm", 0 );
    include_weapon( "m1911_upgraded_zm", 0 );
    include_weapon( "python_zm" );
    include_weapon( "python_upgraded_zm", 0 );
    include_weapon( "judge_zm" );
    include_weapon( "judge_upgraded_zm", 0 );
    include_weapon( "kard_zm", 0 ); //
    include_weapon( "kard_upgraded_zm", 0 );
    //  fiveseven_zm pair swapped out 2026-10-07 round 2: gunswap.gsc bans the
    //  stock pair and browninghp_zm (same root list) takes the slots.
    include_weapon( "beretta93r_zm", 0 );
    include_weapon( "beretta93r_upgraded_zm", 0 );
    //  fivesevendw_zm pair swapped out 2026-10-07 round 2: gunswap.gsc bans
    //  the stock pair and browninghpdw_zm (oldschool.gsc, all six maps now)
    //  takes the slots.
    include_weapon( "ak74u_zm", 0 );
    include_weapon( "ak74u_upgraded_zm", 0 );
    include_weapon( "mp5k_zm", 0 );
    include_weapon( "mp5k_upgraded_zm", 0 );
    include_weapon( "qcw05_zm", 0 ); //
    include_weapon( "qcw05_upgraded_zm", 0 );
    include_weapon( "870mcs_zm", 0 );
    include_weapon( "870mcs_upgraded_zm", 0 );
    include_weapon( "rottweil72_zm", 0 );
    include_weapon( "rottweil72_upgraded_zm", 0 );
    //  saiga12_zm pair swapped out 2026-10-07 round 2: gunswap.gsc bans the
    //  stock pair and spas_zm (the restored SPAS-12, same root list) takes
    //  the slots.
    include_weapon( "srm1216_zm", 0 ); //
    include_weapon( "srm1216_upgraded_zm", 0 );
    include_weapon( "m14_zm", 0 );
    include_weapon( "m14_upgraded_zm", 0 );
    include_weapon( "saritch_zm", 0 ); //
    include_weapon( "saritch_upgraded_zm", 0 );
    include_weapon( "m16_zm", 0 );
    include_weapon( "m16_gl_upgraded_zm", 0 );
    include_weapon( "xm8_zm" );
    include_weapon( "xm8_upgraded_zm", 0 );
    include_weapon( "type95_zm" );
    include_weapon( "type95_upgraded_zm", 0 );
    include_weapon( "tar21_zm" );
    include_weapon( "tar21_upgraded_zm", 0 );
    include_weapon( "galil_zm" );
    include_weapon( "galil_upgraded_zm", 0 );
    include_weapon( "fnfal_zm", 0 ); //
    include_weapon( "fnfal_upgraded_zm", 0 );
    include_weapon( "dsr50_zm" );
    include_weapon( "dsr50_upgraded_zm", 0 );
    //  barretm82_zm pair swapped out 2026-10-07 round 2: gunswap.gsc bans the
    //  stock pair and dragunov_zm (zm_expanded.csc root list) takes the slots.
    include_weapon( "svu_zm", 0 );
    include_weapon( "svu_upgraded_zm", 0 );
    //  rpd_zm and hamr_zm pairs swapped out 2026-10-07 round 2: gunswap.gsc
    //  bans both stock pairs and m60_zm / mk48_zm (zm_expanded.csc root list)
    //  take the slots.
    include_weapon( "pdw57_zm", 0 );
    include_weapon( "pdw57_upgraded_zm", 0 );
    //  usrpg_zm / m32_zm pairs swapped out 2026-10-07: gunswap.gsc bans the
    //  stock pairs from registration and rpg_zm / mm1_zm take the slots.
    include_weapon( "an94_zm", 0 );
    include_weapon( "cymbal_monkey_zm" );
    include_weapon( "ray_gun_zm" );
    include_weapon( "ray_gun_upgraded_zm", 0 );
    include_weapon( "slipgun_zm" );
    include_weapon( "slipgun_upgraded_zm", 0 );
    include_weapon( "knife_ballistic_zm" );
    include_weapon( "knife_ballistic_upgraded_zm", 0 );
    include_weapon( "knife_ballistic_bowie_zm", 0 );
    include_weapon( "knife_ballistic_bowie_upgraded_zm", 0 );
    // Added weapons
    include_weapon( "uzi_zm" );
    include_weapon( "uzi_upgraded_zm", 0 );
    include_weapon( "thompson_zm" );
    include_weapon( "thompson_upgraded_zm", 0 );
    include_weapon( "ak47_zm" );
    include_weapon( "ak47_upgraded_zm", 0 );
    include_weapon( "mp40_stalker_zm" );
    include_weapon( "mp40_stalker_upgraded_zm", 0 );
    include_weapon( "scar_zm" );
    include_weapon( "scar_upgraded_zm", 0 );
    include_weapon( "mg08_zm" );
    include_weapon( "mg08_upgraded_zm", 0 );
    include_weapon( "minigun_alcatraz_zm" );
    include_weapon( "minigun_alcatraz_upgraded_zm", 0 );
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
    include_weapon( "lsat_zm" );
    include_weapon( "lsat_upgraded_zm", 0 );
    include_weapon( "c96_zm" );
    include_weapon( "c96_upgraded_zm", 0 );
    // Tranzit weapons
    include_weapon( "beretta93r_extclip_zm", 0 );
    include_weapon( "beretta93r_extclip_upgraded_zm", 0 );
    include_weapon( "ak74u_extclip_zm", 0 );
    include_weapon( "ak74u_extclip_upgraded_zm", 0 );

    if ( is_true( level.raygun2_included ) && !isdemoplaying() )
    {
        include_weapon( "raygun_mark2_zm", hasdlcavailable( "dlc3" ) );
        include_weapon( "raygun_mark2_upgraded_zm", 0 );
    }
}