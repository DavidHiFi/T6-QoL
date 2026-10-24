#include common_scripts\utility;

init()
{
    // Classic and competitive modes retain stock spawn selection.
    if ( getdvar( "ui_zm_gamemodegroup" ) != "zsurvival" )
        return;

    qol_install_spawns( 0 );
    // Plutonium's dedicated startup hooks can run after the mod's init pass.
    level thread qol_install_spawns( 1 );
}

qol_install_spawns( wait_for_player )
{
    if ( wait_for_player )
        level waittill( "connected", player );
    replacefunc( maps\mp\zombies\_zm::getfreespawnpoint, ::qol_initial_spawn );
    replacefunc( maps\mp\zombies\_zm::get_valid_spawn_location, ::qol_respawn );
}

qol_initial_spawn( spawnpoints, player )
{
    println( "[zm_qol] co-op initial spawn selection" );
    // Co-op can use both authored team halves. A disconnected player's ordinal
    // must not send every later join back to spawnpoints[0].
    point = qol_free_spawn( spawnpoints, player, 1 );
    if ( isdefined( point ) )
        return point;
    return spawnpoints[0];
}

qol_respawn( player, groups, group, return_struct )
{
    // Stock's persistent .plyr reservations survive disconnects. Occupancy is
    // authoritative; an exhausted group falls back to the initial pool.
    point = qol_free_spawn( getstructarray( groups[group].target, "targetname" ), player, 0 );
    if ( !isdefined( point ) || ( isdefined( return_struct ) && return_struct ) )
        return point;
    return point.origin;
}

qol_free_spawn( points, player, allow_blocked )
{
    if ( !isdefined( points ) )
        return undefined;
    players = getplayers();
    backup = undefined;
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
        if ( !occupied )
        {
            // Zombies can block every start; that must not select an occupied
            // player start when the initial pool is the last resort.
            backup = point;
            if ( !positionwouldtelefrag( point.origin ) )
                return point;
        }
    }
    if ( allow_blocked )
        return backup;
    return undefined;
}
