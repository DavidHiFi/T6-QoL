// ============================================================================
//  bloodhound.gsc  -  THE BLOODHOUND AND THE MEAT WAGON
//
//  User, 2026-09-27: port the Bloodhound revolver (Black Ops III, Shadows of
//  Evil) into the mystery box, with `.give bloodhound` working. Ported to T6 by
//  Halo / SickoHours for Zombies Declassified; zone_source\mod_bloodhound.zone
//  says what was rebuilt from his handoff. This file only registers the gun,
//  the same way oldschool.gsc does.
//
//  🛑 WHY THIS IS ITS OWN FILE. quality_of_life.gsc is full on symbols: any new
//  call in it can stop an unrelated import resolving and kill every map
//  (AGENTS.md item 1b). A raw script that installs itself from its own init()
//  costs that file nothing.
//
//  🛑 THE WEAPON BUDGET. The engine registers at most 253 weapons per map
//  (modding-jobs\motd-port-001\BUDGET.md). The Bloodhound costs 3: the base
//  gun, the Meat Wagon and the Meat Wagon's left-hand half. Measured room left
//  after the MM1, the dual Browning and the Scavenger (split agreed with the
//  Scavenger port, 2026-09-27):
//      Buried classic  249 -> 252      Maze  242 -> 245      Docks  250 -> 253
//  Every other map is at 251-253 already, so the gun is held back there. Keep
//  the client twin in zm_expanded.csc on exactly the same conditions.
//
//  📝 THE LEFT-HAND HALF. bloodhoundlh_upgraded_zm is never a box result: it is
//  the Meat Wagon's off-hand gun, inventoryType dwlefthand, named by the right
//  hand's DualWieldWeapon field. Precached here, never include_weapon()'d,
//  which is how stock treats m1911lh_upgraded_zm.
//
//  📝 VALUES. Cost 50 is Treyarch's box cost for both stock revolvers. The
//  pickup vox is the Python's, wpck_python, which Buried's bank voices; Mob
//  voices no revolver line, so Docks uses its pistol line, wpck_pistol.
// ============================================================================

#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;
//  add_zombie_weapon() lives here, include_weapon() in _zm_utility above.
//  Without this include the file still compiles and the map dies with
//  "Unresolved external : add_zombie_weapon".
#include maps\mp\zombies\_zm_weapons;

init()
{
    map = getdvar( "mapname" );
    mode = getdvar( "ui_zm_gamemodegroup" );

    if ( !bloodhound_enabled( map, mode ) )
    {
        println( "[zm_qol] bloodhound: held back on " + map + " / " + mode + " - weapon budget" );
        return;
    }

    vox = "wpck_python";

    if ( map == "zm_prison" )
        vox = "wpck_pistol";

    precacheitem( "bloodhound_zm" );
    precacheitem( "bloodhound_upgraded_zm" );
    precacheitem( "bloodhoundlh_upgraded_zm" );
    include_weapon( "bloodhound_zm" );
    include_weapon( "bloodhound_upgraded_zm", 0 );
    add_zombie_weapon( "bloodhound_zm", "bloodhound_upgraded_zm", &"ZMWEAPON_BLOODHOUND", 50, vox, "", undefined, 1 );
    println( "[zm_qol] bloodhound: registered on " + map );
}

bloodhound_enabled( map, mode )
{
    if ( map == "zm_buried" )
        return mode == "zclassic" || mode == "zsurvival";

    if ( map == "zm_prison" )
        return mode == "zsurvival";

    return 0;
}
