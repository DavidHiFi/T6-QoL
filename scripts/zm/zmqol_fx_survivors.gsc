// ============================================================================
//  zmqol_fx_survivors  -  A04 fast_restart crash fix (F1)
// ----------------------------------------------------------------------------
//  Root cause (measured, modding-jobs\overnight-20261007\a04-dump-analysis\):
//  a fast_restart keeps entities and the process but rebuilds the engine's FX
//  descriptor tables. A persistent SpawnFX entity that survives the restart
//  holds a binding into the old table; when that binding is next refreshed the
//  descriptor read returns NULL and the engine dereferences it
//  (plutonium_bootstrapper_win32+0x1dd7ed, ET_FX entities only, 0xC0000005).
//  The visionset-manager script error recorded in the same dumps was a decoy:
//  the vsmgr guard fixed it and the deaths continued, which is exactly what
//  this mechanism predicts.
//
//  The fix is NOT a guard. The mod's persistent SpawnFX entities are tracked
//  here (the wunderfizz orb glow, the per-purchase wunderfizz loop handle, the
//  Die Rise wall chalk) and deleted the moment scripts re-init after a
//  restart; the owning features recreate them naturally (the glow's own 1 s
//  proximity watcher, the chalk thread's respawn loop, the next purchase).
//  Transient one-shot playfx calls self-expire and are not tracked.
//
//  level persists across a fast_restart while every init() re-runs - the
//  classic isdefined( level.x ) init-guard idiom depends on it - so a list
//  filled before the restart is readable in the re-init burst, well inside the
//  measured 1-2 s crash window.
//
//  WHY A SEPARATE FILE: scripts\zm\quality_of_life.gsc is on its compiled-
//  bytecode ceiling (workspace AGENTS.md item 1b). New behaviour goes in its
//  own raw script that installs itself from its own init(). The PaP machine's
//  fx_ent and the zombie-blood m_fx are spawn("script_model") holders for
//  playfxontag - ET_SCRIPTMOVER, not ET_FX - so the measured crash path never
//  reaches them and they stay where they are.
// ============================================================================

init()
{
    //  overnight-20261008-001: host-console off switch for the F1-off live
    //  A/B test. Default (unset) is ON; `set zmqol_fx_survivors 0` skips the
    //  sweep so the stale-binding crash can be reproduced on demand.
    if ( getdvar( "zmqol_fx_survivors" ) == "0" )
        return;

    if ( isdefined( level.zmqol_spawnfx_entities ) )
    {
        foreach ( ent in level.zmqol_spawnfx_entities )
        {
            if ( isdefined( ent ) )
                ent delete();
        }
    }
    level.zmqol_spawnfx_entities = [];
}

//  Record a persistent SpawnFX entity for the next re-init. Returns the entity
//  so a spawn site can wrap inline:
//    self.x = scripts\zm\zmqol_fx_survivors::zmqol_track_spawnfx( SpawnFX( ... ) );
zmqol_track_spawnfx( ent )
{
    if ( !isdefined( ent ) )
        return ent;

    if ( !isdefined( level.zmqol_spawnfx_entities ) )
        level.zmqol_spawnfx_entities = [];

    level.zmqol_spawnfx_entities[ level.zmqol_spawnfx_entities.size ] = ent;
    return ent;
}
