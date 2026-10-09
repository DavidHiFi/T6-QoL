// ============================================================================
//  oldschool.gsc  -  THE MM1 GRENADE LAUNCHER AND THE BROWNING HP DUAL WIELD
//
//  User, 2026-09-26: port these two out of Mario Woopsie's "MOTD Old School
//  Weapons" (Nexus Mods, beta 1.3) into the mystery box on every map they fit.
//  The single Browning HP was already here; the dual wield is a second box gun.
//
//  The art is declared in zone_source\mod_oldschool.zone and linked into mod.ff
//  out of zone_source\oldschool_donor; the six defs ship raw in weapons\zm\.
//  This file only registers the guns, the same way blastomatic.gsc does.
//
//  🛑 WHY THIS IS ITS OWN FILE. quality_of_life.gsc is full on symbols: any new
//  call in it can stop an unrelated import resolving and kill every map
//  (AGENTS.md item 1b). A raw script that installs itself from its own init()
//  costs that file nothing.
//
//  The engine's registered-weapon ceiling is 253. Keep the client twin in
//  zm_expanded.csc on exactly the same map and game-mode conditions.
//
//  📝 THE LEFT-HAND HALVES. browninghplh_zm / _upgraded_zm are never box
//  results: they are the dual wield's off-hand gun, inventoryType dwlefthand,
//  named by the right hand's DualWieldWeapon field. Precached here the way
//  quality_of_life.gsc precaches the Tac-45's fnp45lh_upgraded_zm, and never
//  include_weapon()'d, which is how stock treats fivesevenlh_zm.
//
//  📝 VALUES. Cost 50 is Treyarch's own box cost for both classes (stock
//  m32_zm and fivesevendw_zm, zm_buried.gsc / zm_highrise.gsc). The pickup vox
//  are stock's for the same class, per map, because each map's english bank
//  only voices some of them (dumped, not assumed):
//      wpck_m32     War Machine lines     TranZit, Buried, Die Rise
//      wpck_rpg     launcher lines        Mob of the Dead (and the three above)
//      wpck_duel57  dual pistol lines     TranZit, Buried, Die Rise
//      wpck_dual    dual pistol lines     Mob of the Dead
//  Nuketown voices none of them, so there the pickup is silent, as it is for
//  every gun Nuketown has no line for.
//  Display names: WEAPON_MGL "MM1 Grenade Launcher" and WEAPON_BROWNINGHP_DW
//  "Browning HP Dual Wield" are stock strings (en_code_post_gfx_zm); the two
//  Pack-a-Punch names are MOTD's and live in mod.str.
// ============================================================================

#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;
//  add_zombie_weapon() lives here, include_weapon() in _zm_utility above.
//  Without this include the file still compiles and the map dies with
//  "Unresolved external : add_zombie_weapon" - boxfix.gsc's banner has the
//  boot that proved it.
#include maps\mp\zombies\_zm_weapons;

init()
{
    map = getdvar( "mapname" );
    mode = getdvar( "ui_zm_gamemodegroup" );
    mm1 = oldschool_mm1_enabled( map, mode );
    dw = oldschool_dw_enabled( map, mode );

    if ( !mm1 && !dw )
    {
        println( "[zm_qol] oldschool: held back on " + map + " / " + mode + " - weapon budget" );
        return;
    }

    vox_mm1 = "wpck_m32";
    vox_dw = "wpck_duel57";

    if ( level.script == "zm_prison" )
    {
        vox_mm1 = "wpck_rpg";
        vox_dw = "wpck_dual";
    }

    if ( level.script == "zm_tomb" )
    {
        //  Origins' own banks voice the dual-pistol class as wpck_duel (the
        //  stock Five-seveN DW's key there, zm_tomb.gsc:978) and the M32 as
        //  wpck_crappy (zm_tomb.gsc:979). Copied from the map's own
        //  registrations, never invented - the round-2 gunswap note covers it.
        vox_mm1 = "wpck_crappy";
        vox_dw = "wpck_duel";
    }

    if ( mm1 )
    {
        precacheitem( "mm1_zm" );
        precacheitem( "mm1_upgraded_zm" );
        include_weapon( "mm1_zm" );
        include_weapon( "mm1_upgraded_zm", 0 );
        add_zombie_weapon( "mm1_zm", "mm1_upgraded_zm", &"WEAPON_MGL", 50, vox_mm1, "", undefined, 1 );
        println( "[zm_qol] oldschool: registered mm1 on " + map );
    }

    if ( dw )
    {
        precacheitem( "browninghpdw_zm" );
        precacheitem( "browninghpdw_upgraded_zm" );
        precacheitem( "browninghplh_zm" );
        precacheitem( "browninghplh_upgraded_zm" );
        include_weapon( "browninghpdw_zm" );
        include_weapon( "browninghpdw_upgraded_zm", 0 );
        add_zombie_weapon( "browninghpdw_zm", "browninghpdw_upgraded_zm", &"WEAPON_BROWNINGHP_DW", 50, vox_dw, "", undefined, 1 );
        println( "[zm_qol] oldschool: registered browninghpdw on " + map );
    }
}

oldschool_mm1_enabled( map, mode )
{
    if ( mode != "zclassic" && mode != "zsurvival" )
        return 0;

    //  zm_prison: the mod's own War Machine block came out of added_weapons()
    //  (gunswap 2026-10-07), so the MM1 takes the launcher slot in both modes.
    //  zm_transit: stock's m32 there was include_weapon'd with in_box 0 -
    //  precached, never offered - so there is no box launcher to replace and
    //  survival keeps the gate it always had.
    if ( map == "zm_prison" )
        return 1;

    if ( map == "zm_transit" )
        return mode == "zsurvival";

    return map == "zm_nuked" || map == "zm_highrise" || map == "zm_buried" || map == "zm_tomb";
}

oldschool_dw_enabled( map, mode )
{
    if ( mode != "zclassic" && mode != "zsurvival" )
        return 0;

    //  Round 2 of the gunswap, 2026-10-07: the Five-seveN DW the Browning HP
    //  DW replaces was boxed on every map in both modes (stock include lists),
    //  and the same round's bans freed real slots everywhere - so the gate is
    //  all six maps now, not just the two it booted on. Grief/turned keep
    //  their gate: their weapon budget was never measured, and the FSDW dies
    //  there too (the cost of the swap in the unmeasured modes).
    //  v2.15.43 - the Magmagat quest (scripts\zm\zm_prison\
    //  zm_prison_magmagat.gsc) needs five weapon-table slots on Mob classic
    //  that only exist if this four-slot family steps aside there - the
    //  measured budget says so exactly (248 after the hold-back + 5 = 253 of
    //  the 253 ceiling; same night's SaveRegisteredWeapons death says no
    //  headroom existed before it). The DW keeps every other map it had,
    //  including both Mob survival locations, which stay at 250.
    if ( map == "zm_prison" )
        return false;

    return map == "zm_nuked" || map == "zm_buried" || map == "zm_highrise" ||
           map == "zm_transit" || map == "zm_tomb";
}
