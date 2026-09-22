// ============================================================================
//  perkpopup.gsc  -  THE PERK POP-UP'S THREE ELEMENTS, ALLOCATED ONCE
//                                                                   (v2.17.39)
//
//  User, 2026-09-22, after days of it: *"it's only showing the name now. it's
//  not even showing the icon or the description of the perk ... it's not just
//  electric cherry, it's all perks ... hard gate that issue so it can never
//  happen again."*
//
//  🌟 THE CAUSE, AND IT IS IN THE SYMPTOM. perk_bought() asked for three client
//  hudelems in a row at the instant a perk was bought. newclienthudelem() draws
//  from a finite client pool and FAILS QUIETLY when that pool is empty, so
//  whichever element is requested last is the one that silently does not draw.
//  v2.17.x already knew this - it reordered the calls so the icon, not the
//  description, would be the casualty, and left a banner saying so. The user's
//  screenshot shows the name drawing and BOTH the description and the icon
//  missing, which is the same failure one step worse: only the first of the
//  three got a slot.
//
//  Reordering can only choose which thing breaks. It cannot stop the breakage,
//  because the pool's state at the moment of purchase is not something this mod
//  controls - the player has been fighting for twenty rounds and every other
//  HUD feature, powerup timer and capture ring has taken its slots by then.
//
//  🛑 SO THE ALLOCATION MOVED OFF THE PURCHASE PATH ENTIRELY. The three
//  elements are created ONCE per player, at spawn, when the pool is at its
//  emptiest, and then reused for every perk for the rest of the match. A full
//  pool at purchase time can no longer cost the description or the icon,
//  because by then nothing is being allocated. That is the hard gate: not a
//  better ordering, but no ordering at all.
//
//  📝 NOTHING ABOUT THE LOOK CHANGES. Geometry, font scales, colours, the fade
//  timings and the twelve description strings all stay in
//  quality_of_life.gsc::perk_bought() exactly as they are - that file is what
//  tools\check-perk-popup.ps1 gates on, and the layout is the user's. This file
//  owns only WHERE the elements come from.
//
//  📝 AND IT IS A SEPARATE FILE because quality_of_life.gsc is on its
//  compiled-bytecode ceiling; a ~15-line diagnostic added to this very function
//  on 2026-09-21 took the whole mod down. The edit there is a net REDUCTION -
//  three newclienthudelem() calls become three calls to this, and the
//  destroy-and-forget blocks at both ends of the function are gone.
// ============================================================================

#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;

init()
{
    level thread zmqol_perkpop_watch();
}

// ----------------------------------------------------------------------------
//  Pre-create the three elements the moment a player is in the world. Done per
//  spawn rather than per connect because a client hudelem belongs to a spawned
//  player; the isdefined guard in zmqol_perkpop_elem() makes a repeat spawn
//  free rather than a second allocation.
// ----------------------------------------------------------------------------
zmqol_perkpop_watch()
{
    level endon( "end_game" );

    for ( ;; )
    {
        level waittill( "connected", player );

        if ( isdefined( player ) )
        {
            player thread zmqol_perkpop_reserve();
        }
    }
}

zmqol_perkpop_reserve()
{
    self endon( "disconnect" );

    self waittill( "spawned_player" );

    //  Order matches perk_bought(): name, description, icon.
    self zmqol_perkpop_elem( 0 );
    self zmqol_perkpop_elem( 1 );
    self zmqol_perkpop_elem( 2 );
}

// ----------------------------------------------------------------------------
//  Hand back this player's element for a slot, creating it only the first time.
//  perk_bought() calls this exactly where it used to call newclienthudelem(),
//  so the call site reads the same and the elements are never destroyed.
//
//  🛑 THEY ARE DELIBERATELY NEVER DESTROYED. Destroying them returned the slots
//  to the pool between purchases, which is precisely how the next purchase
//  ended up unable to get them back. Three elements held for the match is the
//  price of the pop-up always drawing, and it is three fewer allocations per
//  perk than before.
// ----------------------------------------------------------------------------
zmqol_perkpop_elem( n_slot )
{
    if ( !isdefined( self.zmqol_perkpop ) )
    {
        self.zmqol_perkpop = [];
    }

    if ( !isdefined( self.zmqol_perkpop[ n_slot ] ) )
    {
        self.zmqol_perkpop[ n_slot ] = newclienthudelem( self );
    }

    return self.zmqol_perkpop[ n_slot ];
}
