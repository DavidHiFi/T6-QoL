#include common_scripts\utility;

init()
{
    // Competitive modes retain stock team separation and spawn ownership.
    if ( getdvar( "g_gametype" ) == "zgrief" || getdvar( "g_gametype" ) == "zmeat" )
        return;

    // Plutonium installs its dedicated-server spawn detour during startup.
    // Install after that pass, before any connected player can spawn.
    level thread qol_install_spawns();
}

qol_install_spawns()
{
    wait 0.05;
    replacefunc( maps\mp\zombies\_zm::getfreespawnpoint, ::qol_initial_spawn );
    replacefunc( maps\mp\zombies\_zm::get_valid_spawn_location, ::qol_respawn );
}

qol_initial_spawn( spawnpoints, player )
{
    // Co-op can use both authored team halves. A disconnected player's ordinal
    // must not send every later join back to spawnpoints[0].
    point = qol_free_spawn( spawnpoints, player );
    if ( isdefined( point ) )
        return point;
    return spawnpoints[0];
}

qol_respawn( player, groups, group, return_struct )
{
    // Stock's persistent .plyr reservations survive disconnects. Occupancy is
    // authoritative; an exhausted group falls back to the initial pool.
    point = qol_free_spawn( getstructarray( groups[group].target, "targetname" ), player );
    if ( !isdefined( point ) || ( isdefined( return_struct ) && return_struct ) )
        return point;
    return point.origin;
}

qol_free_spawn( points, player )
{
    if ( !isdefined( points ) )
        return undefined;
    players = getplayers();
    foreach ( point in points )
    {
        occupied = 0;
        foreach ( other in players )
        {
            if ( isdefined( player ) && other == player )
                continue;
            if ( other.sessionstate == "playing" && isalive( other )
                && distancesquared( point.origin, other.origin ) < 1024 )
            {
                occupied = 1;
                break;
            }
        }
        if ( !occupied && !positionwouldtelefrag( point.origin ) )
            return point;
    }
    return undefined;
}
