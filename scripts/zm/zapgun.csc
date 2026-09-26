// ============================================================================
//  zapgun.csc  -  client half of the Wave Gun / Zap Guns          (v2.17.46)
// ----------------------------------------------------------------------------
//  Two jobs:
//
//  1. THE CLIENT WEAPON INCLUDE (v2.10.14). The mystery box needs the weapon
//     included on BOTH sides to draw the pickup model (the rule written over
//     the EMP registration in quality_of_life.gsc). Stock's own
//     clientscripts\mp\zombies\_zm_weapons.csc already lists microwavegundw_zm
//     among the dual-wield names it draws the second gun for.
//
//  2. THE BODY SWELL. Moon's own microwavegun_zombie_expand_response ->
//     microwavegun_bloat() pair (BO1 _zombiemode_weap_microwavegun.csc). The
//     server registers the same 1-bit actor field (zapgun.gsc init), swaps the
//     corpse to its welded zqwg_ copy and raises the field; this file answers
//     it by ramping "scriptVector3".x from 0 to 4.0 over Moon's 2500 ms (1000 ms
//     when the rig has no J_SpineLower tag). The swell vertex shader pushes each
//     vertex out along its normal by exactly that amount - Moon's one line.
//
//  🛑 v2.17.46 - SHADER CONSTANT SLOT 2, NOT 0. Stock maps slot 0 of every
//  zombie to "scriptVector2" for the eye glow, and does it again from
//  zombie_eyes_clientfield_cb() when zombie_has_eyes drops at death
//  (_zm.csc, reached from zombie_death_event -> zombie_eye_glow_stop). On a
//  fallback kill that clientfield and ours arrive together, so slot 0 could be
//  remapped away from scriptVector3 under the ramp and the swell never showed.
//  The working Der Riese build 11 uses slot 2 for exactly this; so does stock
//  Origins for its staff shaders. The gun is gated off Origins.
//
//  The eye-blood fx / mist / sounds stay server-side broadcasts - that part of
//  the original was already ported that way and verified; only the bloat is
//  moved here, because mapshaderconstant()/setshaderconstant() are client
//  builtins and must run on the viewer.
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
//  function's zmqol_ prefix and the slot. endon "entityshutdown" is Moon's
//  own; the burst ghosts and deletes the corpse 0.1 s after it fires, and this
//  thread dies with the entity.
zmqol_mgun_client_bloat( localclientnum )
{
    self endon( "entityshutdown" );
    self.zmqol_mgun_bloat_running = 1;

    durationmsec = 2500;
    tag_pos = self gettagorigin( "J_SpineLower" );
    bloat_max_fraction = 1.0;

    if ( !isdefined( tag_pos ) )
        durationmsec = 1000;

    self mapshaderconstant( localclientnum, 2, "scriptVector3" );
    begin_time = getrealtime();

    while ( true )
    {
        age = getrealtime() - begin_time;
        bloat_fraction = age / durationmsec;

        if ( bloat_fraction > bloat_max_fraction )
            bloat_fraction = bloat_max_fraction;

        if ( !isdefined( self ) )
            return;

        //  BO1's values: the fraction runs to 1.0 and the shader gets
        //  fraction * 4.0 in X. Moon waited 0.05 s between steps; one frame
        //  (as the Der Riese build does) reads as a smooth inflation.
        self setshaderconstant( localclientnum, 2, bloat_fraction * 4.0, 0, 0, 0 );

        if ( bloat_fraction >= bloat_max_fraction )
            break;

        waitrealtime( 0.016 );
    }
}
