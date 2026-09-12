// ============================================================================
//  zapgun.csc  -  client half of the Wave Gun / Zap Guns          (v2.15.45)
// ----------------------------------------------------------------------------
//  Two jobs:
//
//  1. THE CLIENT WEAPON INCLUDE (v2.10.14). The mystery box needs the weapon
//     included on BOTH sides to draw the pickup model (the rule written over
//     the EMP registration in quality_of_life.gsc). Stock's own
//     clientscripts\mp\zombies\_zm_weapons.csc already lists microwavegundw_zm
//     among the dual-wield names it draws the second gun for.
//
//  2. THE BODY SWELL (v2.15.45). This is Moon's own
//     microwavegun_zombie_expand_response -> microwavegun_bloat() pair, carried
//     from _zm_weap_microwavegun.csc (DLC5 decompile, 2026-09-03). The server
//     registers the same 1-bit actor field (zapgun.gsc init) and raises it on
//     the sizzle death's "expand" notetrack; this file answers it by mapping
//     the actor's shader constant 0 to "scriptVector3" and ramping its W from
//     0 to 0.5 over Moon's own 2500 ms (1000 ms when the rig has no
//     J_SpineLower tag). The zombie body/head materials that ramp deforms ship
//     in mod_wavegun_swell.zone (MaximumSwell added, Moon's literal 20).
//
//  The eye-blood fx / mist / sounds stay server-side broadcasts - that part of
//  the original was already ported that way and verified; only the bloat is
//  moved here, because mapshaderconstant()/setshaderconstant() are client
//  builtins and must run on the viewer. (Same calls stock uses for the Origins
//  staff crystals and the Buried wonderfizz glow - they are not DLC5-only.)
//
//  🛑 BOTH GATES BELOW MUST STAY IDENTICAL TO zapgun.gsc's, and the include
//  list must mirror its two include_weapon calls exactly - a weapon included on
//  one side only is the InitGame -> ShutdownGame-at-0:00 failure with a clean
//  log (teslagun.csc's banner), and a client include of a weapon the server
//  never precached is an access violation (§37). getdvar, not
//  getdvarintdefault, for the reason recorded there: getdvarintdefault is not
//  reachable from these files and throws Unresolved external.
//
//  🛑 THE CLIENTFIELD REGISTRATION MUST MATCH zapgun.gsc EXACTLY
//  ("zombie_actor_flag_microwavegun_expand_response", 15000, 1, "int") or the
//  engine throws EXE_CLIENT_FIELD_MISMATCH at map load. The gates above
//  guarantee both sides register together or not at all; the two files have
//  mirrored gates since v2.10.14 and must keep doing so.
// ============================================================================
#include clientscripts\mp\zombies\_zm_weapons;

init()
{
    str_ww = getdvar( "zmqol_ww" );

    if ( str_ww != "" && str_ww != "1" && str_ww != "5" )
        return;

    if ( getdvar( "mapname" ) == "zm_buried" || getdvar( "mapname" ) == "zm_tomb" )
        return;

    include_weapon( "microwavegundw_zm" );
    include_weapon( "microwavegundw_upgraded_zm", 0 );

    registerclientfield( "actor", "zombie_actor_flag_microwavegun_expand_response", 15000, 1, "int", ::microwavegun_zombie_expand_response, 1 );
}

//  Moon's callback, minus the parts that served the eye fx and pop sound
//  (those stay server broadcasts here). localclientnum 0 only, as in Moon;
//  the bloat is per-viewer shader state.
microwavegun_zombie_expand_response( localclientnum, oldval, newval, bnewent, binitialsnap, fieldname, bwasdemojump )
{
    if ( localclientnum != 0 || !newval )
        return;

    if ( getdvarint( "zmqol_mgun_debug" ) )
        println( "[zm_qol] zapgun client: expand_response -> bloat ramp" );

    if ( isdefined( self.zmqol_mgun_bloat_running ) && self.zmqol_mgun_bloat_running )
        return;

    self thread zmqol_mgun_client_bloat( localclientnum );
}

//  Moon's microwavegun_bloat(), carried over name-for-name apart from this
//  function's zmqol_ prefix and the commented dev println. endon
//  "entityshutdown" is Moon's own; the burst ghosts and deletes the corpse
//  0.1 s after it fires, and this thread dies with the entity.
zmqol_mgun_client_bloat( localclientnum )
{
    self endon( "entityshutdown" );
    self.zmqol_mgun_bloat_running = 1;

    durationmsec = 2500;
    tag_pos = self gettagorigin( "J_SpineLower" );
    bloat_max_fraction = 0.5;

    if ( !isdefined( tag_pos ) )
        durationmsec = 1000;

    self mapshaderconstant( localclientnum, 0, "scriptVector3" );
    begin_time = getrealtime();

    while ( true )
    {
        age = getrealtime() - begin_time;
        bloat_fraction = age / durationmsec;

        if ( bloat_fraction > bloat_max_fraction )
            bloat_fraction = bloat_max_fraction;

        if ( !isdefined( self ) )
            return;

        self setshaderconstant( localclientnum, 0, 0, 0, 0, bloat_fraction );

        if ( bloat_fraction >= bloat_max_fraction )
            break;

        waitrealtime( 0.05 );
    }
}
