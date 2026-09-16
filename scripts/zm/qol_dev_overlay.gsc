// ============================================================================
//  qol_dev_overlay.gsc  -  the developer overlay, now SHIPPED, not hotloaded
// ----------------------------------------------------------------------------
//  Top-left readout: map / location / gametype, round, x y z, yaw, pitch.
//
//  🛑 WHY THIS IS A MOD SCRIPT AND NOT A LOOSE PROBE ANY MORE.
//  User, 2026-09-15: *"why is my developer probe gsc not being loaded ... make
//  sure this is permanent and it sticks."*
//
//  It used to live at
//      %LOCALAPPDATA%\Plutonium\storage\t6\raw\scripts\zm\zzz_dev_hud.gsc
//  and it kept disappearing for a reason that was nobody's fault: build.bat's
//  step [9/9] quarantines FOREIGN scripts out of Plutonium's shared raw\ folder
//  into backups\raw-foreign-parked\, because that folder is global and a stale
//  loose script shadows the mod on every boot for every mod. zzz_dev_hud.gsc
//  looked exactly like one of those, so every single build parked it. It is
//  sitting in that backup folder right now.
//
//  Living in scripts\zm\ instead, it is packed into mod.iwd by build.bat and
//  cannot be parked, cannot be shadowed, and survives every rebuild. Plutonium
//  auto-runs init() for every .gsc under scripts\zm\, which is the same reason
//  the loose copy worked with nothing but an init().
//
//  TOGGLE
//      zmqol_dev_overlay 1     force on
//      zmqol_dev_overlay 0     force off
//  With the dvar unset it follows sv_cheats: on for a dev/console session,
//  invisible to a normal player. That is deliberate - the overlay should never
//  appear for someone who just installed the mod, and tying it to sv_cheats
//  means no one has to remember to switch it off before a release.
//
//  🛑 THE settext() TRAP, KEPT FROM THE PROBE'S OWN HISTORY. An earlier version
//  painted the coordinate rows with settext() four times a second. Every unique
//  string consumes a configstring slot until the pool dies:
//      G_FindConfigstringIndex: overflow (488): 'x 10826 y -7631 z -463'
//      -> SV_Shutdown -> LUI_ERROR wedge, game dead at the dialog.
//  Numbers go through setvalue() and labels are set once via .label. The only
//  settext() is the one-shot header. Do not "simplify" this back.
// ============================================================================

#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include common_scripts\utility;

init()
{
    level thread zmqol_dev_overlay_watch();
}

//  Unset -> follow sv_cheats. Set -> obey it exactly.
zmqol_dev_overlay_on()
{
    str_on = getdvar( "zmqol_dev_overlay" );

    if ( str_on == "1" )
        return 1;

    if ( str_on == "0" )
        return 0;

    return getdvarint( "sv_cheats" ) == 1;
}

zmqol_dev_overlay_watch()
{
    level endon( "intermission" );

    //  Players already connected when this runs, plus any who join later. The
    //  prone fix earlier today was broken by handling only the second case:
    //  in solo the player is already in by the time a script's init() runs, so
    //  a bare waittill( "connected" ) never fires.
    a_players = get_players();

    foreach ( player in a_players )
    {
        if ( isdefined( player ) )
            player thread zmqol_dev_overlay_for_player();
    }

    for ( ;; )
    {
        level waittill( "connected", player );

        if ( isdefined( player ) )
            player thread zmqol_dev_overlay_for_player();
    }
}

zmqol_dev_overlay_line( x, y )
{
    hud = newclienthudelem( self );
    hud.horzalign = "user_left";
    hud.vertalign = "user_top";
    hud.alignx = "left";
    hud.aligny = "top";
    hud.x = x;
    hud.y = y;
    hud.fontscale = 1;
    hud.color = ( 1, 1, 1 );
    hud.alpha = 1;
    hud.hidewheninmenu = 1;
    return hud;
}

//  setvalue() only when the number actually moved - a stationary player costs
//  zero writes.
zmqol_dev_overlay_push( hud, n )
{
    if ( !isdefined( hud.zmqol_dev_last ) || hud.zmqol_dev_last != n )
    {
        hud setvalue( n );
        hud.zmqol_dev_last = n;
    }
}

zmqol_dev_overlay_for_player()
{
    self endon( "disconnect" );
    level endon( "intermission" );

    //  One overlay per player, even if both seeding paths reach the same one.
    if ( is_true( self.zmqol_dev_overlay_running ) )
        return;

    self.zmqol_dev_overlay_running = 1;

    hud_head = self zmqol_dev_overlay_line( 8, 8 );
    hud_head.color = ( 0.5, 0.8, 1 );
    hud_head settext( getdvar( "mapname" ) + " / " + getdvar( "ui_zm_mapstartlocation" ) + " / " + getdvar( "ui_gametype" ) );

    e_round = self zmqol_dev_overlay_line( 8, 24 );
    e_round.label = &"round ";
    e_round.color = ( 0.5, 0.8, 1 );

    e_x = self zmqol_dev_overlay_line( 8, 40 );
    e_x.label = &"x ";

    e_y = self zmqol_dev_overlay_line( 64, 40 );
    e_y.label = &"y ";

    e_z = self zmqol_dev_overlay_line( 120, 40 );
    e_z.label = &"z ";

    e_yaw = self zmqol_dev_overlay_line( 8, 56 );
    e_yaw.label = &"yaw ";

    e_pitch = self zmqol_dev_overlay_line( 76, 56 );
    e_pitch.label = &"pitch ";

    println( "[zm_qol] dev overlay: installed for a player (toggle with zmqol_dev_overlay 0/1; unset follows sv_cheats, currently " + zmqol_dev_overlay_on() + ")" );

    for ( ;; )
    {
        v_o = self.origin;
        v_a = self getplayerangles();

        n_round = 0;

        if ( isdefined( level.round_number ) )
            n_round = level.round_number;

        zmqol_dev_overlay_push( e_round, n_round );
        zmqol_dev_overlay_push( e_x, int( v_o[0] ) );
        zmqol_dev_overlay_push( e_y, int( v_o[1] ) );
        zmqol_dev_overlay_push( e_z, int( v_o[2] ) );
        zmqol_dev_overlay_push( e_yaw, int( v_a[1] ) );
        zmqol_dev_overlay_push( e_pitch, int( v_a[0] ) );

        n_alpha = 0;

        if ( zmqol_dev_overlay_on() )
            n_alpha = 1;

        hud_head.alpha = n_alpha;
        e_round.alpha = n_alpha;
        e_x.alpha = n_alpha;
        e_y.alpha = n_alpha;
        e_z.alpha = n_alpha;
        e_yaw.alpha = n_alpha;
        e_pitch.alpha = n_alpha;

        wait 0.25;
    }
}
