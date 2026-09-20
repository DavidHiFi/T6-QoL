#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_weapons;

init()
{
    // Pulled from Buried/Origins: the freeze-over FX assets are not yet compiled into
    // mod.ff (deferred FX pack), and firing the gun crashes clients. Gate matches freeze.csc.
    if (getdvar("mapname") == "zm_buried" || getdvar("mapname") == "zm_tomb") return;
    precachestring(&"ZOMBIE_WEAPON_FREEZEGUN"); // wallbuy hint

    precacheitem("freezegun_zm");
    precacheitem("freezegun_upgraded_zm");

    include_weapon("freezegun_zm");
    add_limited_weapon("freezegun_zm", 1); // 1 player can get it (for box)
    // 🛑 ZOMBIE_WEAPON_FREEZEGUN, not _UPGRADED. Found by diffing the three guns'
    // registrations while investigating the missing Wunderwaffe: thundergun.gsc:38
    // and teslagun.gsc:47 both pass their BASE key here, this one passed the
    // upgraded one. add_zombie_weapon()'s third argument is the base weapon's
    // display name, so the un-Packed Winter's Howl was announcing itself as
    // "Winter's Fury" in the box and on the HUD.
    add_zombie_weapon("freezegun_zm", "freezegun_upgraded_zm", &"ZOMBIE_WEAPON_FREEZEGUN", 10, "freeze", "", undefined );

    maps\mp\zombies\_zm_weap_freezegun::init();
}
