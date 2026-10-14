// ============================================================================
//  qol_powerup_dispatch  -  Zombie Blood pickup (issue 13)
//
//  Stock powerup_grab() handles its own names in a switch and sends every
//  other name down level._zombiemode_powerup_grab (_zm_powerups.gsc:1071-1073,
//  the `default:` branch). "zombie_blood" off Origins only ever works if that
//  pointer reaches this mod.
//
//  This module owns the pointer from init():
//    - it installs immediately and re-asserts every half second, so a later
//      writer (a game mode postinit, a map script) cannot strand it;
//    - it chains to the handler it displaced, never to itself, so Origins'
//      ::tomb_powerup_grab and grief's ::meat_stink_powerup_grab still run;
//    - each power-up is dispatched once. A third-party wrapper that saved this
//      handler and chains back into it cannot loop, because the second entry
//      sees the mark the first one left on the power-up.
//
//  Bo2-VN: the Death Machine power-up is removed, and with it every Death
//  Machine branch, runtime thread and per-player watcher this file carried.
// ============================================================================
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;

main()
{
}

init()
{
    zmqol_pd_hook();
    level thread zmqol_pd_hook_watch();
}

// Returns 1 when it had to (re)install. The displaced handler becomes the
// chain target only when it is not this module's own handler.
zmqol_pd_hook()
{
    f_cur = level._zombiemode_powerup_grab;

    if ( isdefined( f_cur ) && f_cur == ::zmqol_pd_grab )
        return 0;

    level.zmqol_pd_next = f_cur;
    level._zombiemode_powerup_grab = ::zmqol_pd_grab;
    return 1;
}

zmqol_pd_hook_watch()
{
    level endon( "end_game" );

    for ( ;; )
    {
        wait 0.5;

        if ( zmqol_pd_hook() )
            println( "[zm_qol] power-up dispatch: level._zombiemode_powerup_grab was replaced - hook re-installed, previous handler chained" );
    }
}

zmqol_pd_grab( s_powerup, e_player )
{
    str_name = undefined;

    if ( isdefined( s_powerup ) )
    {
        if ( isdefined( s_powerup.zmqol_pd_seen ) )
            return;

        s_powerup.zmqol_pd_seen = 1;
        str_name = s_powerup.powerup_name;
    }

    // Origins registers Zombie Blood itself and zmqol_zombie_blood_enabled()
    // returns 0 there, so its own ::tomb_powerup_grab receives the name below.
    // Buried and Mob are excluded by the same gate for their clientfield budget.
    if ( isdefined( str_name ) && str_name == "zombie_blood" && scripts\zm\quality_of_life::zmqol_zombie_blood_enabled() )
    {
        level thread scripts\zm\quality_of_life::zmqol_zb_powerup( s_powerup, e_player );
        return;
    }

    f_next = level.zmqol_pd_next;

    if ( isdefined( f_next ) && f_next != ::zmqol_pd_grab )
        level thread [[ f_next ]]( s_powerup, e_player );
}
