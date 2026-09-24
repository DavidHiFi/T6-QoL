// ============================================================================
//  blastomatic.gsc  -  THE BLAST-O-MATIC IN THE MYSTERY BOX
//
//  User, 2026-09-25: port SadSlothXL's Black Ops Cold War Gallo SA12
//  "Blast-O-Matic" mastercraft into the mod, with its sounds, animations and
//  Pack-a-Punch camos, on every map it fits.
//
//  The art is declared in zone_source\mod_blastomatic.zone and linked into
//  mod.ff; the two defs ship raw in weapons\zm\. This file only registers the
//  gun, the same way boxfix.gsc registers the Blundergat.
//
//  🛑 WHY THIS IS ITS OWN FILE. quality_of_life.gsc is full on symbols: any new
//  call in it, even to a function it already uses, can stop an unrelated
//  import resolving and kill every map (AGENTS.md item 1b). A raw script that
//  installs itself from its own init() costs that file nothing.
//
//  🛑 ORIGINS IS SKIPPED, AND THAT IS A BUDGET, NOT A PREFERENCE. Every
//  precacheitem() takes a slot from a per-map weapon table, and zm_tomb has
//  0-1 spare (quality_of_life.gsc's v2.17.37 banner and zm_tomb.gsc's
//  added_weapons banner carry the boots that measured it). This pair costs 2.
//  Over the ceiling the map dies at load with "unknown weapon" naming some
//  innocent gun. Putting the gun on Origins means trading a pair out first.
//
//  🛑 THE CLIENT TWIN IS zm_expanded.csc and it skips Origins on the same test.
//  Its include_weapon() ends in addzombieboxweapon( w, getweaponmodel( w ) ),
//  a model lookup on a weapon nothing precached - the as50_zm client crash.
//  Change one list, change both.
//
//  📝 VALUES. Cost 1500 is stock's own for the Remington 870 in the box
//  (zm_transit.gsc and four other maps); a box gun's cost only matters to a
//  wall buy, which this gun has none of. "wpck_shotgun" and the trailing 1
//  (create_vox) are Sloth's, and stock uses the same pair for the KSG
//  (zm_buried.gsc). Display names come from mod.str: "Blast-O-Matic" and, for
//  the Pack-a-Punched gun, "H-NGM-N" - both Sloth's.
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
        println( "[zm_qol] blastomatic: held back on zm_tomb - no precache budget" );
        return;
    }

    precacheitem( "blastomatic_zm" );
    precacheitem( "blastomatic_upgraded_zm" );

    include_weapon( "blastomatic_zm" );                 //  in_box defaults to 1
    include_weapon( "blastomatic_upgraded_zm", 0 );

    add_zombie_weapon( "blastomatic_zm", "blastomatic_upgraded_zm", &"WEAPON_T9_GALLO_BLASTOMATIC_ZM", 1500, "wpck_shotgun", "", undefined, 1 );

    println( "[zm_qol] blastomatic: registered on " + level.script );
}
