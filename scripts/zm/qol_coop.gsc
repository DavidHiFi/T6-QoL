// Re-evaluate stock solo Quick Revive when a second player arrives, rather
// than waiting for the next round. Map-specific forever-solo state lives in
// the map scripts so this module links on every Zombies map.
#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;

init()
{
    level thread zmqol_coop_watch();
    println( "[zm_qol] co-op solo watcher active" );
}

zmqol_coop_watch()
{
    level endon( "end_game" );
    flag_wait( "initial_players_connected" );

    for ( ;; )
    {
        if ( get_players().size > 1 && flag( "solo_game" ) )
        {
            maps\mp\zombies\_zm::check_quickrevive_for_hotjoin();
            println( "[zm_qol] co-op: stock hot-join Quick Revive update, players=" + get_players().size + " solo_game=" + flag( "solo_game" ) );
        }
        wait 0.05;
    }
}

zmqol_coop_roster()
{
    return getnumexpectedplayers() > 1 || getnumconnectedplayers() > 1 || get_players().size > 1;
}
