#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_weapons;

// Console switches affect acquisition, never the resource layout a late client loads.
perk_allowed( perk )
{
    if ( perk != "specialty_nomotionsensor" || getdvar( "mapname" ) == "zm_buried" )
        return 1;
    return getdvarintdefault( "zmqol_vulture", 1 );
}

wallbuy_in_box( weapon )
{
    if ( getdvarintdefault( "zmqol_wallbuy_box", 1 ) )
        return 1;
    // Preserve a map's existing box entry when the promotion feature is off.
    return isdefined( level.zombie_weapons ) && isdefined( level.zombie_weapons[weapon] ) && level.zombie_weapons[weapon].is_in_box;
}

add_mp_weapon( base, upgraded, hint, cost, vox )
{
    base = scripts\zm\quality_of_life::zmqol_tomb_weapon( base );
    upgraded = scripts\zm\quality_of_life::zmqol_tomb_weapon( upgraded );
    enabled = getdvarintdefault( "zmqol_mp_weapons", 1 );
    precacheitem( base );
    precacheitem( upgraded );
    include_weapon( base, enabled );
    include_weapon( upgraded, 0 );
    if ( !enabled )
        return;
    add_zombie_weapon( base, upgraded, hint, cost, vox, "", undefined, 1 );
}
