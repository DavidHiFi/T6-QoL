#include maps\mp\_utility;
#include common_scripts\utility;

// ============================================================================
//  qol_vsmgr_guard.gsc  -  VISIONSET MANAGER SURVIVES FAST_RESTART
//
//  GitHub issue 11: fast_restart (console command or the pause-menu row)
//  crashed the game on every map except Origins and Origins survival. The
//  crash dumps agree on one signature:
//
//      last gsc pos maps/mp/_visionset_mgr::monitor
//      last gsc error message 'type undefined is not an int'
//
//  Why: fast_restart re-runs every script init() in the same process, but the
//  engine does not re-fire the "connected" notify for the players it keeps.
//  _visionset_mgr::on_player_connect() therefore never runs again, so a
//  preserved player keeps no _player_entnum and no entry in any
//  state.players[] array. When the manager's 0.05s monitor tick next runs
//  get_first_active_name() / update_clientfields() for such a player, it
//  indexes an array with an undefined entity number - the exact "not an int"
//  error - and the title goes down with a native access violation.
//
//  The guard: re-create exactly what stock on_player_connect() would have
//  created, and only for entries that are still missing. On a healthy load
//  every entry already exists and this touches nothing. The default-info
//  activate at the end of stock's on_player_connect() is deliberately not
//  replicated: the "none" info has the lowest priority, so
//  get_first_active_name() reaches it through its fall-through regardless.
//
//  Polling, not the "connected" notify - the notify is precisely the thing
//  that does not re-fire. 0.01s so a backfill always lands before the next
//  0.05s monitor read.
//
//  Its own root script, not quality_of_life.gsc, which is full (AGENTS.md 1b).
// ============================================================================

init()
{
    level thread qol_vsmgr_guard_watch();
}

qol_vsmgr_guard_watch()
{
    level endon( "end_game" );
    while ( 1 )
    {
        if ( isDefined( level.vsmgr ) )
        {
            players = get_players();
            player_index = 0;
            while ( player_index < players.size )
            {
                qol_vsmgr_guard_backfill_player( players[ player_index ] );
                player_index++;
            }
        }
        wait 0.01;
    }
}

//  The per-player body of stock _visionset_mgr::on_player_connect(), minus
//  the parts only a fresh connection needs.
qol_vsmgr_guard_backfill_player( player )
{
    player._player_entnum = player getentitynumber();
    typekeys = getarraykeys( level.vsmgr );
    type_index = 0;
    while ( type_index < typekeys.size )
    {
        type = typekeys[ type_index ];
        if ( level.vsmgr[ type ].in_use )
        {
            name_index = 0;
            while ( name_index < level.vsmgr[ type ].sorted_name_keys.size )
            {
                name_key = level.vsmgr[ type ].sorted_name_keys[ name_index ];
                state = level.vsmgr[ type ].info[ name_key ].state;
                entnum = player._player_entnum;
                if ( !isDefined( state.players[ entnum ] ) )
                {
                    state.players[ entnum ] = spawnstruct();
                    state.players[ entnum ].active = 0;
                    state.players[ entnum ].lerp = 0;
                    if ( state.ref_count_lerp_thread && state.activate_per_player )
                    {
                        state.players[ entnum ].ref_count = 0;
                    }
                }
                name_index++;
            }
        }
        type_index++;
    }
}
