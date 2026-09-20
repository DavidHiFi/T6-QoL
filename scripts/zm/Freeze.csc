#include clientscripts\mp\zombies\_zm_weapons;

init()
{
    // MUST match the server gate in freeze.gsc.
    if (getdvar("mapname") == "zm_buried" || getdvar("mapname") == "zm_tomb") return;
    include_weapon("freezegun_zm");
    clientscripts\mp\zombies\_zm_weap_freezegun::init();
}
