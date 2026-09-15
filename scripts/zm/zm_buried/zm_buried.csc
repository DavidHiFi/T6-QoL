#include clientscripts\mp\_utility;
#include clientscripts\mp\zombies\_zm_utility;
#include clientscripts\mp\zombies\_zm_weapons;
#include clientscripts\mp\zm_buried;
#include clientscripts\mp\zombies\_zm;
#include clientscripts\mp\zombies\_zm_turned;
#include clientscripts\mp\zm_buried_classic;
#include clientscripts\mp\zm_buried_turned_street;
#include clientscripts\mp\zm_buried_grief_street;

main()
{
    replaceFunc(clientscripts\mp\zm_buried::include_weapons, ::include_weapons);
    // --- Borough survival (client halves; server halves in zm_buried.gsc /
    //     replaced\zm_buried_gamemodes.gsc) ---
    replaceFunc(clientscripts\mp\zm_buried::init_gamemodes, ::init_gamemodes);
    replaceFunc(clientscripts\mp\zm_buried_grief_street::precache, ::grief_street_precache);

    zmqol_enable_vulture_on_borough();
}

// ============================================================================
//  zmqol_enable_vulture_on_borough  (CLIENT)
//
//  The mandatory other half of scripts\zm\zm_buried\zm_buried.gsc's function of
//  the same name - read the full explanation there. Short version: Borough
//  survival needs Vulture Aid registered so its perk machine stops being tagged
//  as Speed Cola by _zm_perks::perk_machine_spawn_init's `default:` branch.
//
//  Registering it server-side only would register a clientfield the client does
//  not have and disconnect everyone with EXE_CLIENT_FIELD_MISMATCH - exactly the
//  failure grief_street_precache below was written to fix. Stock's gate at
//  clientscripts\mp\zm_buried.csc:49 is zclassic-only on this side too:
//        if ( is_gametype_active( "zclassic" ) )
//            clientscripts\mp\zombies\_zm_perk_vulture::enable_vulture_perk_for_level();
//
//  The condition below is deliberately the same pair of dvars the server checks,
//  so the two sides cannot drift apart.
//
//  🛑 NOT verified in game yet. Requires build_ff.bat - a .csc change does not
//  reach the game through mod.iwd.
// ============================================================================
zmqol_enable_vulture_on_borough()
{
    if ( getdvar( "ui_gametype" ) != "zstandard" )
        return;

    //  v2.17.0 - Maze joins Borough. MUST stay identical to the server half's
    //  test in zm_buried.gsc; the two decide a clientfield registration, and a
    //  location in one list but not the other is EXE_CLIENT_FIELD_MISMATCH for
    //  everyone on that arena.
    str_location = getdvar( "ui_zm_mapstartlocation" );

    if ( str_location != "street" && str_location != "maze" )
        return;

    clientscripts\mp\zombies\_zm_perk_vulture::enable_vulture_perk_for_level();
}

// ============================================================================
//  grief_street_precache  (CLIENT)
//
//  🛑 Fixes the BOROUGH hard disconnect:
//        Clientfield subwoofer_flings_zombie in set [actor] is not registered
//        on the client
//        COM_ERROR (3) Server Disconnected - EXE_CLIENT_FIELD_MISMATCH
//
//  Direction of the mismatch, per checkpoint 11 §3.7: "not registered on the
//  CLIENT" means the server has it and the client does not, so the fix is
//  client-side and needs a build_ff relink. Confirmed against the engine's own
//  dump in the 06:59 log rather than inferred:
//        [Client] CLIENTFIELD SET [actor] COUNT : 7   - no subwoofer_flings_zombie
//        [Server] CLIENTFIELD SET [actor] COUNT : 8   - has subwoofer_flings_zombie
//  and both sides' [toplayer] sets matched at 23 including buildable/_pu/_sq, which
//  is how we know the buildables half was never the problem here.
//
//  WHY IT HAPPENS. scripts\zm\replaced\zm_buried_gamemodes.gsc:26 routes Borough
//  to the GRIEF server script:
//        add_map_location_gamemode("zstandard", "street",
//                                  maps\mp\zm_buried_grief_street::precache, ...)
//  and that precache (zm_buried_grief_street.gsc:27) calls
//  _zm_equip_subwoofer::init(), which registers the field SERVER-side.
//
//  The client never matches it, because the client registers the subwoofer from a
//  gametype gate in clientscripts\mp\zm_buried.csc:514 that has no zstandard arm:
//        if      ( level.scr_zm_ui_gametype == "zclassic" )                  -> init
//        else if ( zgrief && level.scr_zm_map_start_location == "street" )   -> init
//  Borough is zstandard, so neither fires. The stock client's own
//  zm_buried_grief_street::precache() is EMPTY - on stock the gate above is the
//  only client-side caller, and stock never reaches this location as zstandard.
//
//  WHY HERE. This is the client half of the same precache the server runs, so the
//  two now line up by construction. It is also provably early enough: premain(),
//  which runs AFTER precache, is what registers buildable/_pu/_sq - and those came
//  through registered on the client in the same failing run. Filling an empty stock
//  function also means no existing behaviour is displaced.
//
//  The zstandard guard is load-bearing. Our init_gamemodes registers this same
//  precache for BOTH zgrief and zstandard; on zgrief the gate at zm_buried.csc:514
//  already calls init(), and registering a clientfield twice is itself an error.
//
//  🛑 NOT verified in game yet. Requires build_ff.bat - a .csc change does not
//  reach the game through mod.iwd.
// ============================================================================
grief_street_precache()
{
    if ( getdvar( "ui_gametype" ) != "zstandard" )
        return;

    clientscripts\mp\zombies\_zm_equip_subwoofer::init();
    clientscripts\mp\zombies\_zm_equip_subwoofer::init_animtree();
}

// ============================================================================
//  init_gamemodes  (CLIENT)
//
//  Same defect as zm_prison\zm_prison.csc - see the long comment there.
//
//  scripts\zm\replaced\zm_buried_gamemodes.gsc adds a zstandard gamemode on the
//  server (Street and the custom Maze location). Stock
//  clientscripts\mp\zm_buried::init_gamemodes registers zclassic, zgrief and
//  zcleansed but NOT zstandard, so the client's start_zombie_gametype() bails and
//  the loading state is never released.
//
//  Everything below other than the zstandard line is copied verbatim from stock,
//  including the _zm_turned::init() call and the duplicated zcleansed registration
//  (stock registers zcleansed twice - kept as-is deliberately; add_map_gamemode
//  resets that mode's location arrays, and the second call runs before any
//  add_map_location_gamemode for zcleansed, so it is harmless).
//
//  🛑 NOT verified in game yet - Buried's Maze location has never been tested.
// ============================================================================
init_gamemodes()
{
    clientscripts\mp\zombies\_zm_turned::init();

    add_map_gamemode( "zcleansed", clientscripts\mp\zombies\_zm_turned::precache, clientscripts\mp\zombies\_zm_turned::main );
    add_map_gamemode( "zclassic", undefined, undefined );
    add_map_gamemode( "zgrief", undefined, undefined );
    add_map_gamemode( "zcleansed", undefined, undefined );
    add_map_gamemode( "zstandard", undefined, undefined );

    add_map_location_gamemode( "zclassic", "processing", clientscripts\mp\zm_buried_classic::precache, clientscripts\mp\zm_buried_classic::premain, clientscripts\mp\zm_buried_classic::main );
    add_map_location_gamemode( "zcleansed", "street", clientscripts\mp\zm_buried_turned_street::precache, clientscripts\mp\zm_buried_turned_street::premain, clientscripts\mp\zm_buried_turned_street::main );
    add_map_location_gamemode( "zgrief", "street", clientscripts\mp\zm_buried_grief_street::precache, clientscripts\mp\zm_buried_grief_street::premain, clientscripts\mp\zm_buried_grief_street::main );
    add_map_location_gamemode( "zstandard", "street", clientscripts\mp\zm_buried_grief_street::precache, clientscripts\mp\zm_buried_grief_street::premain, clientscripts\mp\zm_buried_grief_street::main );
}

include_weapons()
{
    if ( getdvar( #"createfx" ) != "" )
        return;

    gametype = getdvar( #"ui_gametype" );
    include_weapon( "knife_zm", 0 );
    include_weapon( "frag_grenade_zm", 0 );
    include_weapon( "claymore_zm", 0 );
    level._uses_sticky_grenades = 0;
    include_weapon( "m1911_zm", 0 );
    include_weapon( "m1911_upgraded_zm", 0 );
    include_weapon( "rnma_zm" );
    include_weapon( "rnma_upgraded_zm", 0 );
    include_weapon( "judge_zm" );
    include_weapon( "judge_upgraded_zm", 0 );
    include_weapon( "kard_zm", 0 ); //
    include_weapon( "kard_upgraded_zm", 0 );
    include_weapon( "fiveseven_zm" );
    include_weapon( "fiveseven_upgraded_zm", 0 );
    include_weapon( "beretta93r_zm", 0 );
    include_weapon( "beretta93r_upgraded_zm", 0 );
    include_weapon( "beretta93r_extclip_zm", 0 );
    include_weapon( "beretta93r_extclip_upgraded_zm", 0 );
    include_weapon( "fivesevendw_zm" );
    include_weapon( "fivesevendw_upgraded_zm", 0 );
    include_weapon( "ak74u_zm", 0 );
    include_weapon( "ak74u_upgraded_zm", 0 );
    include_weapon( "ak74u_extclip_zm", 0 );
    include_weapon( "ak74u_extclip_upgraded_zm", 0 );
    include_weapon( "mp5k_zm", 0 );
    include_weapon( "mp5k_upgraded_zm", 0 );

    if ( gametype == "zcleansed" )
        include_weapon( "qcw05_zm" );

    include_weapon( "870mcs_zm", 0 );
    include_weapon( "870mcs_upgraded_zm", 0 );
    include_weapon( "rottweil72_zm", 0 );
    include_weapon( "rottweil72_upgraded_zm", 0 );
    include_weapon( "saiga12_zm", 0 ); //
    include_weapon( "saiga12_upgraded_zm", 0 );
    include_weapon( "srm1216_zm", 0 ); //
    include_weapon( "srm1216_upgraded_zm", 0 );
    include_weapon( "m14_zm", 0 );
    include_weapon( "m14_upgraded_zm", 0 );
    include_weapon( "saritch_zm", 0 );
    include_weapon( "saritch_upgraded_zm", 0 );
    include_weapon( "m16_zm", 0 );
    include_weapon( "m16_gl_upgraded_zm", 0 );
    include_weapon( "tar21_zm" );
    include_weapon( "tar21_upgraded_zm", 0 );
    include_weapon( "galil_zm" );
    include_weapon( "galil_upgraded_zm", 0 );
    include_weapon( "fnfal_zm" );
    include_weapon( "fnfal_upgraded_zm", 0 );
    include_weapon( "dsr50_zm" );
    include_weapon( "dsr50_upgraded_zm", 0 );
    include_weapon( "barretm82_zm", 0 );
    include_weapon( "barretm82_upgraded_zm", 0 );
    include_weapon( "hamr_zm" );
    include_weapon( "hamr_upgraded_zm", 0 );
    include_weapon( "usrpg_zm" );
    include_weapon( "usrpg_upgraded_zm", 0 );
    include_weapon( "m32_zm", 0 );
    include_weapon( "m32_upgraded_zm", 0 );
    include_weapon( "cymbal_monkey_zm" );
    include_weapon( "ray_gun_zm" );
    include_weapon( "ray_gun_upgraded_zm", 0 );
    include_weapon( "raygun_mark2_zm", 1 );
    include_weapon( "raygun_mark2_upgraded_zm", 0 );
    include_weapon( "slowgun_zm" );
    include_weapon( "slowgun_upgraded_zm", 0 );
    include_weapon( "knife_ballistic_zm", 0 );
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
    include_weapon( "c96_zm" );
    include_weapon( "c96_upgraded_zm", 0);
    // Tranzit weapons
    include_weapon( "qcw05_zm" );
    include_weapon( "qcw05_upgraded_zm", 0 );
    include_weapon( "type95_zm" );
    include_weapon( "type95_upgraded_zm", 0 );
    include_weapon( "xm8_zm" );
    include_weapon( "xm8_upgraded_zm", 0 );
    include_weapon( "rpd_zm" );
    include_weapon( "rpd_upgraded_zm", 0 );
    include_weapon( "python_zm" );
    include_weapon( "python_upgraded_zm", 0 );
}