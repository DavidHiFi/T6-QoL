// ============================================================================
//  bloodhound.gsc  -  THE BLOODHOUND AND THE MEAT WAGON
//
//  User, 2026-09-27: port the Bloodhound revolver (Black Ops III, Shadows of
//  Evil) into the mystery box, with `.give bloodhound` working, and make it a
//  STARTING PISTOL choice on every map. Ported to T6 by Halo / SickoHours for
//  Zombies Declassified; zone_source\mod_bloodhound.zone says what was rebuilt
//  from his handoff. This file only registers the gun, the same way
//  oldschool.gsc does.
//
//  🛑 WHY THIS IS ITS OWN FILE. quality_of_life.gsc is full on symbols: any new
//  call in it can stop an unrelated import resolving and kill every map
//  (AGENTS.md item 1b). A raw script that installs itself from its own init()
//  costs that file nothing.
//
//  🛑 THE WEAPON BUDGET. The engine registers at most 253 weapons per map
//  (modding-jobs\motd-port-001\BUDGET.md). The Bloodhound costs 3: the base
//  gun, the Meat Wagon and the Meat Wagon's left-hand half.
//
//  TWO LEVELS, so it can be a starting pistol everywhere:
//    BOX                   all three defs, in the mystery box, Pack-a-Punches
//                          into the Meat Wagon. Nuketown, Die Rise, Mob, Docks,
//                          Buried and Maze.
//    STARTING PISTOL ONLY  TranZit (classic and every survival location) and
//                          Origins, which sit at the
//                          ceiling: only the base gun is registered (1 slot),
//                          not boxed and with no Pack-a-Punch form. The Meat
//                          Wagon is a dual wield, and a dual wield whose left
//                          half is not registered kills the map at load
//                          ("could not find alt Dual Wield Weapon", BUDGET.md),
//                          so it is left out there rather than half-registered.
//                          Downed in solo, the player gets the Bloodhound back
//                          (qol_options.gsc keeps the base gun when no upgrade
//                          is registered).
//  Measured 2026-09-28 (live\m-*-table-*.txt, main + Scavenger + Bloodhound):
//  TranZit 252, Origins 252, Mob 252, Nuketown 253, Die Rise 253, Buried 250;
//  Town hit 254 with the box form, so all of TranZit is starting-pistol only.
//  The room comes from two weapons zm_qol always registered and nothing ever
//  hands out: vector_extclip_zm / _upgraded_zm (quality_of_life.gsc and the
//  zm_expanded.csc twin no longer include them), and on Mob / Docks the
//  misspelled ak74_extclip_upgraded_zm (zm_prison.gsc). Measured counts per
//  map: modding-jobs\bloodhound-port-001\BUDGET.md.
//
//  📝 THE LEFT-HAND HALF. bloodhoundlh_upgraded_zm is never a box result: it is
//  the Meat Wagon's off-hand gun, inventoryType dwlefthand, named by the right
//  hand's DualWieldWeapon field. Precached here, never include_weapon()'d,
//  which is how stock treats m1911lh_upgraded_zm.
//
//  📝 VALUES. Cost 50 is Treyarch's box cost for both stock revolvers. The
//  pickup vox is the Python's, wpck_python, which Buried's bank voices; Mob
//  voices no revolver line, so Mob and Docks use its pistol line, wpck_pistol.
//
//  Keep the client twin in zm_expanded.csc on exactly the same conditions.
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
    in_box = bloodhound_in_box( map, mode );

    vox = "wpck_python";

    if ( map == "zm_prison" )
        vox = "wpck_pistol";

    precacheitem( "bloodhound_zm" );

    if ( !in_box )
    {
        include_weapon( "bloodhound_zm", 0 );
        add_zombie_weapon( "bloodhound_zm", undefined, &"ZMWEAPON_BLOODHOUND", 50, vox, "", undefined, 1 );
        println( "[zm_qol] bloodhound: registered on " + map + " (starting pistol only - weapon budget)" );
        return;
    }

    precacheitem( "bloodhound_upgraded_zm" );
    precacheitem( "bloodhoundlh_upgraded_zm" );
    include_weapon( "bloodhound_zm" );
    include_weapon( "bloodhound_upgraded_zm", 0 );
    add_zombie_weapon( "bloodhound_zm", "bloodhound_upgraded_zm", &"ZMWEAPON_BLOODHOUND", 50, vox, "", undefined, 1 );
    println( "[zm_qol] bloodhound: registered on " + map + " (box + starting pistol)" );
}

//  The box needs all three slots. TranZit (classic and all seven survival
//  locations) and Origins sit at the ceiling even after the freed slots:
//  measured 2026-09-28 with the Scavenger in, Town reached 254 with the box
//  form, one past the 253 RadiusDamage bound (BUDGET.md). There the gun is a
//  starting pistol only.
bloodhound_in_box( map, mode )
{
    if ( map == "zm_tomb" )
        return 0;

    if ( map == "zm_transit" )
        return 0;

    return 1;
}
