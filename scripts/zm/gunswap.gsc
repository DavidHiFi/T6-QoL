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
//
//  ROUND 2, SAME DAY. Five more stock pairs out, each replaced by a gun that
//  was already in the box as an addition:
//      RPD         -> M60 (m60_zm, the BO1 gun; the RPD was also mod-added on
//                     Buried/Mob/Origins - those three blocks came out too)
//      HAMR        -> MK48 (mk48_zm, already a mod gun everywhere)
//      Barrett M82 -> Dragunov (dragunov_zm, already a mod gun everywhere)
//      S12/Saiga-12 -> SPAS-12 (spas_zm, restored this round from the base)
//      Five-seveN pair -> Browning HP and Browning HP Dual Wield (the DW via
//                     oldschool.gsc, whose DW gate is now all six maps)
//  The stock guns stay banned even where their replacements arrive by other
//  routes - the point is the slots, everywhere, on every mode.
//
//  THE FIVE-SEVEN EXCEPTION, OPENED THEN CLOSED. Round 2 first KEPT the
//  single registered on Origins (its 1100-point wall buy is BSP-welded and
//  stock includes it with in_box 0), and relabelled the wall via a mod.str
//  key override - asking the label to say Browning while the wall kept
//  handing out the Five-seveN. User, same hour, plainly: that is nonsense,
//  the wall should sell a Browning and the Five-seveN is meant to be gone
//  entirely - the slots are the point. SO THE PAIR IS BANNED EVERYWHERE, and
//  the wall is re-pointed instead (zmqol_gunswap_wall_repoint below): stock's
//  wall stub init would assert on the now-missing struct, so the two struct
//  getters it calls run this file's copies with one fallback, and a frame
//  after init the wall's stub is swapped over. The wall sells the Browning
//  HP at its old price for real; only the gun model bolted into the BSP
//  stays what it is.
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
    replaceFunc( maps\mp\zombies\_zm_weapons::get_weapon_cost, ::zmqol_gunswap_get_weapon_cost );
    replaceFunc( maps\mp\zombies\_zm_weapons::get_weapon_hint, ::zmqol_gunswap_get_weapon_hint );
    level thread zmqol_gunswap_wall_repoint();
    println( "[zm_qol] gunswap: swapped-out stock pairs banned from registration on " + getdvar( "mapname" ) );
}

//  Named separately from the wrapper so the next swap is a two-line change.
//  The client list in zm_expanded.csc must match this one exactly - including
//  the Five-seveN exception, which there keys off getdvar("mapname") because
//  the client has no level.script.
zmqol_gunswap_banned_names()
{
    a = [];
    a[a.size] = "usrpg_zm";             //  the stock RPG - replaced by rpg_zm (BO1 RPG-7)
    a[a.size] = "usrpg_upgraded_zm";    //  its PaP half; the RPG-7 already PaPs into Rocket Propelled Grievance
    a[a.size] = "m32_zm";               //  the War Machine - replaced by mm1_zm (MM1)
    a[a.size] = "m32_upgraded_zm";
    a[a.size] = "rpd_zm";               //  the RPD - replaced by m60_zm (BO1 M60)
    a[a.size] = "rpd_upgraded_zm";
    a[a.size] = "hamr_zm";              //  the HAMR - replaced by mk48_zm
    a[a.size] = "hamr_upgraded_zm";
    a[a.size] = "barretm82_zm";         //  the Barrett M82 - replaced by dragunov_zm
    a[a.size] = "barretm82_upgraded_zm";
    a[a.size] = "saiga12_zm";           //  the S12 - replaced by spas_zm (the restored SPAS-12)
    a[a.size] = "saiga12_upgraded_zm";
    a[a.size] = "fiveseven_zm";         //  the Five-seveN - replaced by browninghp_zm, EVERYWHERE incl Origins (user reversal)
    a[a.size] = "fiveseven_upgraded_zm";
    a[a.size] = "fivesevendw_zm";       //  the Five-seveN DW - replaced by browninghpdw_zm
    a[a.size] = "fivesevendw_upgraded_zm";
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

// ============================================================================
//  THE ORIGINS WALL RE-POINT   (round 2 follow-up, user reversal)
// ----------------------------------------------------------------------------
//  Stock zm_tomb.gsc:975 registers the Origins Five-seveN wall as a BSP
//  struct whose zombie_weapon_upgrade is "fiveseven_zm"; the wall's price,
//  hint and delivery all flow from level.zombie_weapons through the stub that
//  _zm_weapons.gsc::init_spawnable_weapon_upgrade() builds from that struct
//  (:891 cost, :894 hint, :916 weapon_upgrade). With the Five-seveN pair
//  banned, that struct never registers - so the two getters the init calls
//  are replaced by the copies below (one fallback each, exact otherwise, the
//  mod's standing copy-not-precall pattern), and a frame after init the wall
//  stub's name fields are swapped to browninghp_zm. From then on the prompt,
//  the price and the delivery all read the Browning HP's own struct.
//
//  The gun model bolted into the BSP is what it is - script cannot re-model
//  a map entity. The REPLACEMENTS's model is rendered client-side
//  (zm_expanded.csc's twin of the player-connect model spawn resolves it
//  from the weapon), so the shelf shows a Browning and the prompt agrees.
// ============================================================================

zmqol_gunswap_get_weapon_cost( weapon_name )
{
    //  Copy of _zm_weapons.gsc:1441-1444. The fallback answers the one weapon
    //  this file can leave unregistered: the re-pointed Origins wall's BSP
    //  name during stub init, before the swap below lands. The replacement's
    //  registered cost (1100 on Origins - quality_of_life.gsc) is what the
    //  wall keeps charging once the swap has landed.
    if ( isdefined( level.zombie_weapons[ weapon_name ] ) )
        return level.zombie_weapons[ weapon_name ].cost;

    if ( level.script == "zm_tomb" && weapon_name == "fiveseven_zm" && isdefined( level.zombie_weapons[ "browninghp_zm" ] ) )
        return level.zombie_weapons[ "browninghp_zm" ].cost;

    assert(isDefined(level.zombie_weapons[weapon_name]), weapon_name + " was not included or is not part of the zombie weapon list.");
    return level.zombie_weapons[weapon_name].cost;
}

zmqol_gunswap_get_weapon_hint( weapon_name )
{
    //  Copy of _zm_weapons.gsc:1436-1439, same single fallback as above.
    if ( isdefined( level.zombie_weapons[ weapon_name ] ) )
        return level.zombie_weapons[ weapon_name ].hint;

    if ( level.script == "zm_tomb" && weapon_name == "fiveseven_zm" && isdefined( level.zombie_weapons[ "browninghp_zm" ] ) )
        return level.zombie_weapons[ "browninghp_zm" ].hint;

    assert(isDefined(level.zombie_weapons[weapon_name]), weapon_name + " was not included or is not part of the zombie weapon list.");
    return level.zombie_weapons[weapon_name].hint;
}

zmqol_gunswap_wall_repoint()
{
    level endon( "end_game" );

    //  Same contract zmqol_wallbuy_box_reassert() has run on for a year:
    //  one frame after init every map's init has certainly run.
    n = 0;

    while ( !isdefined( level._spawned_wallbuys ) && n < 20 )
    {
        wait 0.05;
        n++;
    }

    if ( !isdefined( level._spawned_wallbuys ) )
    {
        println( "[zm_qol] gunswap: wall repoint gave up - level._spawned_wallbuys never appeared" );
        return;
    }

    for ( i = 0; i < level._spawned_wallbuys.size; i++ )
    {
        struct = level._spawned_wallbuys[ i ];

        if ( !isdefined( struct.zombie_weapon_upgrade ) || struct.zombie_weapon_upgrade != "fiveseven_zm" )
            continue;

        struct.zombie_weapon_upgrade = "browninghp_zm";
        stub = struct.trigger_stub;

        if ( isdefined( stub ) )
        {
            stub.zombie_weapon_upgrade = "browninghp_zm";
            stub.weapon_upgrade = "browninghp_zm";
            stub.cost = maps\mp\zombies\_zm_weapons::get_weapon_cost( "browninghp_zm" );
            stub.hint_parm1 = stub.cost;
            stub.hint_string = maps\mp\zombies\_zm_weapons::get_weapon_hint( "browninghp_zm" );
        }

        println( "[zm_qol] gunswap: fiveseven wall repointed to browninghp_zm (" + getdvar( "mapname" ) + ")" );
    }
}
