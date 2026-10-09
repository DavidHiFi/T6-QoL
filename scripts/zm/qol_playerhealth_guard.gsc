#include maps\mp\_utility;
#include maps\mp\zombies\_zm_playerhealth;

// ============================================================================
//  qol_playerhealth_guard.gsc  -  PLAYER HEALTH REGEN SURVIVES FAST_RESTART
//
//  Companion to qol_vsmgr_guard.gsc (issue 11, DavidHiFi/T6-QoL). A04 named
//  _zm_playerhealth::playerhealthregen "a second same-class site, known and
//  out of scope". This module closes that site with the same discipline the
//  vsmgr guard uses: re-create only what is missing, touch nothing on a
//  healthy load.
//
//  WHAT STOCK BUILDS, AND WHERE (patch_zm decompile):
//
//    _zm_playerhealth::init()            -> onplayerconnect_callback( ::onplayerconnect )
//    onplayerconnect()                   -> self thread onplayerspawned()
//    onplayerspawned()                   -> for(;;) self waittill( "spawned_player" );
//                                           perk_set_max_health_if_jugg( "health_reboot", 1, 0 );
//                                           self notify( "noHealthOverlay" );
//                                           self thread playerhealthregen();
//
//  fast_restart re-runs init() but does not re-fire "connected" for the
//  players it preserves (A04 mechanism), so the onplayerspawned() waiter is
//  only still alive if old entity threads survive the restart. If they do
//  not, a preserved player is left with no regen loop, no red-flash overlay
//  watcher and no invulnerability window - the regen side of the crash class
//  silently stops instead of crashing: playerhealthregen() lazy-creates its
//  own state (self.flag / self.flags_lock at its lines 104-113) and reads
//  level.* vars that init() re-creates, so it has no vsmgr-shaped undefined
//  index to die on. This guard restores the THREADS, which is the only
//  connect-only state the file has.
//
//  WHEN IT FIRES: exactly once per process re-init, and only when init()
//  ran while players already existed - the signature of fast_restart /
//  map_restart. On a first load init() runs before any player exists, the
//  size check fails, and the module never threads anything. The bounded
//  window covers the restart teardown racing the re-init.
//
//  WHY THE RE-ARM IS SAFE EVEN IF REDUNDANT: it is stock's own spawn branch
//  verbatim. playerhealthregen() opens with notify( "playerHealthRegen" ),
//  which kills any surviving older instance before the new loop starts, and
//  the loop returns by itself on self.health <= 0. If stock's own
//  onplayerspawned() also re-fires, last writer wins and both writers ran
//  the identical stock sequence.
//
//  DELIBERATELY NOT REPLICATED (same rule as the vsmgr guard's no-activate
//  decision): perk_set_max_health_if_jugg( "health_reboot", 1, 0 ). On a
//  restart it would clamp a preserved Juggernog player's maxhealth to 100,
//  and the perk system's own re-apply rides the same "spawned_player" notify
//  that may never fire again. Not touching maxhealth preserves stock state.
//
//  Own root script, not quality_of_life.gsc, which is full (AGENTS.md 1b).
//  playerhealthregen is called QUALIFIED (maps\mp\zombies\_zm_playerhealth::)
//  because the bare name also exists in maps/_gameskill.gsc and a loose
//  script's bare-name include resolution picks the wrong one.
// ============================================================================

init()
{
    players = get_players();

    if ( players.size < 1 )
        return;

    level thread qol_playerhealth_guard_restart_window();
}

qol_playerhealth_guard_restart_window()
{
    level endon( "end_game" );

    armed = [];
    deadline = gettime() + 30000;

    while ( gettime() < deadline )
    {
        players = get_players();
        player_index = 0;

        while ( player_index < players.size )
        {
            if ( isalive( players[ player_index ] ) )
            {
                entnum = players[ player_index ] getentitynumber();

                if ( !isDefined( armed[ entnum ] ) )
                {
                    armed[ entnum ] = 1;
                    players[ player_index ] qol_playerhealth_guard_rearm();
                }
            }

            player_index++;
        }

        wait 0.1;
    }
}

//  The per-player body of stock onplayerspawned()'s spawn branch, minus the
//  maxhealth reset. playerhealthregen() self-deduplicates via its opening
//  "playerHealthRegen" notify.
qol_playerhealth_guard_rearm()
{
    self notify( "noHealthOverlay" );
    self thread maps\mp\zombies\_zm_playerhealth::playerhealthregen();
}
