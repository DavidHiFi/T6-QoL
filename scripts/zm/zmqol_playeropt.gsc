// ============================================================================
//  zmqol_playeropt  -  per-player option readers
// ----------------------------------------------------------------------------
//  Bo2-VN: every chat and console command is removed (the .say listener, the
//  console twins, the host gate and .my). What stays are the readers other
//  scripts call path-qualified: the host or a solo player reads the server
//  dvar, anyone else reads the shipped default. With no host player at all
//  (a dedicated server) everybody reads the server dvar.
// ============================================================================

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;

//  The host and a solo player own the server dvars. With no host player at all
//  (a dedicated server) everybody falls back to the dvars, the old behaviour.
zmqol_popt_is_host()
{
    if ( !isplayer( self ) )
        return 1;

    e_host = gethostplayer();

    return !isdefined( e_host ) || e_host == self;
}

//  This player's value for a personal option: their own override, else the
//  server dvar if they own it, else the row's shipped default.
zmqol_popt( str_name, n_default )
{
    if ( isdefined( self.zmqol_popt ) && isdefined( self.zmqol_popt[str_name] ) )
        return self.zmqol_popt[str_name];

    if ( self zmqol_popt_is_host() )
        return getdvarintdefault( str_name, n_default );

    return n_default;
}

//  The shared HUD rule. Bo2-VN: hud_master and hud_all are removed, so a row
//  is decided by its own value alone.
zmqol_popt_hud_on( str_row, n_row_default )
{
    return self zmqol_popt( str_row, n_row_default );
}

