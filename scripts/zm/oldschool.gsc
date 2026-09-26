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
//  🛑 ORIGINS IS SKIPPED, AND THAT IS A BUDGET, NOT A PREFERENCE. zm_tomb has
//  0-1 spare weapon precache slots (quality_of_life.gsc's v2.17.37 banner) and
//  these two pairs cost at least 4. Over the ceiling the map dies at load with
//  "unknown weapon" naming some innocent gun. The client twin in zm_expanded.csc
//  skips Origins on the same test; change one, change both.
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
    if ( level.script == "zm_tomb" )
    {
        println( "[zm_qol] oldschool: held back on zm_tomb - no precache budget" );
        return;
    }

    vox_mm1 = "wpck_m32";
    vox_dw = "wpck_duel57";

    if ( level.script == "zm_prison" )
    {
        vox_mm1 = "wpck_rpg";
        vox_dw = "wpck_dual";
    }

    precacheitem( "mm1_zm" );
    precacheitem( "mm1_upgraded_zm" );
    precacheitem( "browninghpdw_zm" );
    precacheitem( "browninghpdw_upgraded_zm" );
    precacheitem( "browninghplh_zm" );
    precacheitem( "browninghplh_upgraded_zm" );

    include_weapon( "mm1_zm" );                         //  in_box defaults to 1
    include_weapon( "mm1_upgraded_zm", 0 );
    include_weapon( "browninghpdw_zm" );
    include_weapon( "browninghpdw_upgraded_zm", 0 );

    add_zombie_weapon( "mm1_zm", "mm1_upgraded_zm", &"WEAPON_MGL", 50, vox_mm1, "", undefined, 1 );
    add_zombie_weapon( "browninghpdw_zm", "browninghpdw_upgraded_zm", &"WEAPON_BROWNINGHP_DW", 50, vox_dw, "", undefined, 1 );

    println( "[zm_qol] oldschool: registered mm1 + browninghpdw on " + level.script );
}
