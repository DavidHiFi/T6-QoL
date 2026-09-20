#include clientscripts\mp\zombies\_zm_weapons;

init()
{
    // MUST match the server gate in thundergun.gsc.
    if (getdvar("mapname") == "zm_buried" || getdvar("mapname") == "zm_tomb") return;
    include_weapon("thundergun_zm");
    clientscripts\mp\zombies\_zm_weap_thundergun::init();
}
