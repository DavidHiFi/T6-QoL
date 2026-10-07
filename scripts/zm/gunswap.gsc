// ============================================================================
//  gunswap.gsc  -  THE STOCK WEAPONS THE BOX SWAPS OUT
//
//  User, 2026-10-07: *"replace the stock RPG with [the] RPG 7, replace the
//  war machine with [the] MM1, if that is literally just gonna give me some
//  free slots."* Both replacements were already in the box as additions -
//  the BO1 RPG-7 via the mp-weapons list, the MM1 via oldschool.gsc - so the
//  only work left was making the stock pairs they duplicate stop existing:
//  the stock RPG (usrpg_zm) and the stock War Machine (m32_zm). The
//  Blastomatic swap needed no script at all: the SPAS-12 was this mod's own
//  addition (quality_of_life.gsc + zm_expanded.csc), so deleting its
//  registration rows removes it everywhere.
//
//  🌟 THE WHOLE THING IS ONE BAN IN ONE PLACE. The stock map scripts call
//  include_weapon("usrpg_zm") / ("m32_zm") on five maps each (zm_transit,
//  zm_buried, zm_highrise, zm_nuked, zm_prison - and zm_tomb for the m32).
//  maps\mp\zombies\_zm_utility::include_weapon is an eight-line wrapper that
//  forwards to _zm_weapons::include_zombie_weapon, which sets
//  level.zombie_include_weapons[name] and precaches. Stock's own
//  add_zombie_weapon opens with
//
//      if(isDefined(level.zombie_include_weapons) &&
//         !isDefined(level.zombie_include_weapons[weapon_name])) return;
//
//  so a weapon that was never include_weapon'd self-noops out of every
//  add_zombie_weapon call the maps still make: no struct, no box entry, no
//  precache slot. No stock map script calls include_zombie_weapon directly
//  (checked across the whole decompile), and _zm_utility never calls
//  include_weapon from inside itself - the only internal-shaped match in that
//  file is the definition line - so replacing this one function intercepts
//  every path there is, on every map, without touching a single stock file.
//
//  🛑 WHY THE WRAPPER IS A COPY AND NOT A PRE-CALL. A replacement cannot call
//  the function it replaced from inside itself (the roundenddof investigation
//  in the queue, failure mode 1). The body below the ban check is stock's own
//  eight lines, verbatim.
//
//  🛑 THE CLIENT TWIN IS zm_expanded.csc AND MUST MATCH. The stock per-map
//  .csc scripts include both pairs client-side; a client include with no
//  server twin is the v2.14.27 Betty crash class, and the client's
//  _display_box_weapons is what draws the box, so the names must vanish from
//  both halves at once. The client wrapper lives there and carries the same
//  four names.
//
//  📝 WHAT DID NOT NEED TOUCHING. quality_of_life.gsc's player-connect
//  precache list DID need its m32 pair removed (a direct precacheitem bypasses
//  include_weapon and would have kept both slots spent on every map) - that
//  edit lives there. The camo fail-safe array keeps its m32/usrpg entries: a
//  map key for a weapon that never registers is inert. The give rows for
//  usrpg_zm ("rpg") moved onto the RPG-7's row and the m32_zm row
//  ("warmachine") was deleted, both in quality_of_life.gsc. Nothing here
//  un-registers anything at runtime, so there is no re-assert race to poll
//  against - the boxfix poller pattern is for flags, not for registrations.
// ============================================================================

#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;
//  The wrapper forwards to include_zombie_weapon, which lives here. See
//  boxfix.gsc's banner for why this include is load-bearing even when nothing
//  in this file calls add_zombie_weapon directly.
#include maps\mp\zombies\_zm_weapons;

init()
{
    replaceFunc( maps\mp\zombies\_zm_utility::include_weapon, ::zmqol_gunswap_include_weapon );
    println( "[zm_qol] gunswap: usrpg_zm and m32_zm pairs banned from registration on " + getdvar( "mapname" ) );
}

//  Named separately from the wrapper so the next swap is a two-line change.
//  The client list in zm_expanded.csc must match this one exactly.
zmqol_gunswap_banned_names()
{
    a = [];
    a[a.size] = "usrpg_zm";             //  the stock RPG - replaced by rpg_zm (BO1 RPG-7)
    a[a.size] = "usrpg_upgraded_zm";    //  its PaP half; the RPG-7 already PaPs into Rocket Propelled Grievance
    a[a.size] = "m32_zm";               //  the War Machine - replaced by mm1_zm (MM1)
    a[a.size] = "m32_upgraded_zm";
    return a;
}

zmqol_gunswap_include_weapon( weapon_name, in_box, collector, weighting_func )
{
    //  Faithful copy of maps\mp\zombies\_zm_utility::include_weapon with one
    //  addition at the top: the swapped-out names return before anything is
    //  precached or flagged, which is what makes stock's own add_zombie_weapon
    //  guard refuse the struct afterwards.
    if ( !isdefined( level.zmqol_gunswap_banned ) )
    {
        level.zmqol_gunswap_banned = zmqol_gunswap_banned_names();
    }

    for ( i = 0; i < level.zmqol_gunswap_banned.size; i++ )
    {
        if ( weapon_name == level.zmqol_gunswap_banned[ i ] )
        {
            println( "[zm_qol] gunswap: " + weapon_name + " blocked from registration on " + level.script );
            return;
        }
    }

    println("ZM >> include_weapon = " + weapon_name);

    if(!isDefined(in_box)) {
        in_box = 1;
    }

    if(!isDefined(collector)) {
        collector = 0;
    }

    maps\mp\zombies\_zm_weapons::include_zombie_weapon(weapon_name, in_box, collector, weighting_func);
}
