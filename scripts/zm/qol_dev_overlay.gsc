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
//  TOGGLE - console, either form:
//      zmqol_dev_overlay 1     on
//      zmqol_dev_overlay 0     off  (the default)
//
//  🛑 OFF UNLESS ASKED FOR, v2.16.17. This used to fall back to sv_cheats when
//  the dvar was unset, which meant any player who turned CHEATS on in GAME 3
//  got a developer readout in the corner of a shipped release - reported by the
//  user on 2026-09-20 with a screenshot of the published build. sv_cheats is a
//  gameplay switch, not a debug switch, so it no longer implies this overlay.
//  It now draws only when the dvar is explicitly 1.
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

//  Explicit only: the overlay draws when zmqol_dev_overlay is 1 and never
//  otherwise. Unset and 0 both mean off - see the banner above.
zmqol_dev_overlay_on()
{
    return getdvar( "zmqol_dev_overlay" ) == "1";
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

    println( "[zm_qol] dev overlay: watching for a player (toggle with zmqol_dev_overlay 1/0, off unless explicitly 1, currently " + zmqol_dev_overlay_on() + ")" );

    // ========================================================================
    //  🛑 v2.17.41 - ALLOCATED ONLY WHILE IT IS ON. DO NOT GO BACK TO FADING.
    //
    //  This used to build its seven elements for every player at connect and
    //  hide them at alpha 0 when off - which is always, for a player. A hidden
    //  hudelem still occupies one of the 31 ARCHIVED slots the engine sends a
    //  client per snapshot (HudElem_UpdateClient; see the HUD SLOT BUDGET
    //  banner in qol_options.gsc), and a fresh TranZit spawn measured 30/31.
    //  These seven were the biggest single tenant, and every one was invisible.
    //  The stock HUD built after them - the buildable bench bar, the revive
    //  bar - is what went missing. Off now means destroyed, not transparent.
    // ========================================================================
    a_hud = undefined;

    for ( ;; )
    {
        if ( !zmqol_dev_overlay_on() )
        {
            if ( isdefined( a_hud ) )
            {
                for ( i = 0; i < a_hud.size; i++ )
                    a_hud[i] destroy();

                a_hud = undefined;
            }

            wait 0.25;
            continue;
        }

        if ( !isdefined( a_hud ) )
        {
            a_hud = [];

            a_hud[0] = self zmqol_dev_overlay_line( 8, 8 );
            a_hud[0].color = ( 0.5, 0.8, 1 );
            a_hud[0] settext( getdvar( "mapname" ) + " / " + getdvar( "ui_zm_mapstartlocation" ) + " / " + getdvar( "ui_gametype" ) );

            a_hud[1] = self zmqol_dev_overlay_line( 8, 24 );
            a_hud[1].label = &"round ";
            a_hud[1].color = ( 0.5, 0.8, 1 );

            a_hud[2] = self zmqol_dev_overlay_line( 8, 40 );
            a_hud[2].label = &"x ";

            a_hud[3] = self zmqol_dev_overlay_line( 64, 40 );
            a_hud[3].label = &"y ";

            a_hud[4] = self zmqol_dev_overlay_line( 120, 40 );
            a_hud[4].label = &"z ";

            a_hud[5] = self zmqol_dev_overlay_line( 8, 56 );
            a_hud[5].label = &"yaw ";

            a_hud[6] = self zmqol_dev_overlay_line( 76, 56 );
            a_hud[6].label = &"pitch ";
        }

        v_o = self.origin;
        v_a = self getplayerangles();

        n_round = 0;

        if ( isdefined( level.round_number ) )
            n_round = level.round_number;

        zmqol_dev_overlay_push( a_hud[1], n_round );
        zmqol_dev_overlay_push( a_hud[2], int( v_o[0] ) );
        zmqol_dev_overlay_push( a_hud[3], int( v_o[1] ) );
        zmqol_dev_overlay_push( a_hud[4], int( v_o[2] ) );
        zmqol_dev_overlay_push( a_hud[5], int( v_a[1] ) );
        zmqol_dev_overlay_push( a_hud[6], int( v_a[0] ) );

        wait 0.25;
    }
}
