// Issue 12: native bodies with equipment slot 3 and alternate fire slot 1.
// Stock Maps/Buried/maps/mp/zombies/_zm_equip_headchopper.gsc; BO2-Reimagined keeps the same equipment lifecycle.
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_equipment;
#include maps\mp\zombies\_zm_spawner;
#include maps\mp\gametypes_zm\_weaponobjects;
#include maps\mp\zombies\_zm;
#include maps\mp\zombies\_zm_unitrigger;
#include maps\mp\zombies\_zm_power;
#include maps\mp\zombies\_zm_buildables;
#include maps\mp\animscripts\zm_death;
#include maps\mp\animscripts\zm_run;
#include maps\mp\zombies\_zm_audio;

main()
{
    replaceFunc( maps\mp\zombies\_zm_equip_headchopper::headchopper_zombie_death_remove_chopper, ::headchopper_zombie_death_remove_chopper );
}

init()
{
}

headchopper_zombie_death_remove_chopper( chopper )
{
    player = chopper.owner;
    thread maps\mp\zombies\_zm_equipment::equipment_disappear_fx( chopper.origin, undefined, chopper.angles );
    chopper dropped_equipment_destroy( 0 );

    if ( !player hasweapon( level.headchopper_name ) )
    {
        player giveweapon( level.headchopper_name );
        player setweaponammoclip( level.headchopper_name, 1 );
        player setactionslot( 3, "weapon", level.headchopper_name );
    }
}

#using_animtree("zombie_headchopper");
