// ============================================================================
//  zapgun.csc  -  client half of the Wave Gun / Zap Guns          (v2.15.51)
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
    //  v2.15.49: BO1's own values (_zombiemode_weap_microwavegun.csc): the
    //  fraction runs to 1.0 and the shader gets fraction * 4.0 in X. The T6
    //  DLC5 decompile had 0.5 / W, which matched the shader it never had.
    bloat_max_fraction = 1.0;

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

        //  X is BO1's amount (fraction * 4.0). YZW carry the stomach
        //  (J_SpineLower) RELATIVE TO THE LOCAL VIEWER'S EYE, because the
        //  zombie shaders see eye-relative world positions (retail's fog code
        //  measures length(worldPos) as the eye distance).
        //
        //  🛑 v2.16.2 - THE EYE SUBTRACTION IS LOAD-BEARING. v2.16.1 removed
        //  it and had SwellOffset reconstruct world space from
        //  inverseViewMatrix instead; measured in game, zombies stopped
        //  inflating at all, because that matrix row is not the camera
        //  position on this engine. Restored. See the banner on SwellOffset
        //  in t6_consts.hlsli before touching either half again - they are one
        //  change in two files and must always agree about the space.
        //  A rig without the tag uses its origin plus 42 units.
        v_center = self gettagorigin( "J_SpineLower" );

        if ( !isdefined( v_center ) )
            v_center = self.origin + ( 0, 0, 42 );

        v_center = v_center - getlocalclienteyepos( localclientnum );

        self setshaderconstant( localclientnum, 0, bloat_fraction * 4.0, v_center[0], v_center[1], v_center[2] );

        if ( bloat_fraction >= bloat_max_fraction )
            break;

        //  🌟 v2.16.2 - RESEND EVERY FRAME, NOT EVERY 50 ms. This is the safe
        //  half of the wobble fix. The shader rebuilds its side of the
        //  comparison every frame, so at 50 ms the centre was up to three
        //  frames stale and a strafing player dragged the ball across the
        //  body. One frame of lag is small enough not to read as motion.
        //  Cheap: one setshaderconstant on one dying actor, for 2.5 s.
        waitrealtime( 0.016 );
    }
}
