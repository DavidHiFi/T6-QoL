// ============================================================================
//  boxfix.gsc  -  WHAT THE MYSTERY BOX MAY AND MAY NOT HAND OUT   (v2.17.31)
//
//  User, 2026-09-21: *"remove the olympia and m14 from the mystery box ... all
//  maps, no m14, no olympia"* and *"make sure that the blundergat is in the
//  mystery box on every mob of the dead survival map"*.
//
//  🛑 WHY THIS IS ITS OWN FILE AND NOT FOUR LINES IN quality_of_life.gsc.
//  That script is ON the compiled-bytecode ceiling: it compiles to 223,029
//  bytes at HEAD and the first build that ever failed was 223,353, so the whole
//  margin is about 300 bytes of bytecode. The first cut of this change lived in
//  quality_of_life.gsc and measured 223,649 - it would have taken every map
//  down with "Unresolved external" naming some innocent stock function. See
//  AGENTS.md item 1b. Comments are free; code is not. New behaviour goes in a
//  new raw script, which is exactly what this is.
//
//  🌟 THE BOX READS ONE FIELD, ONCE PER SPIN.
//  _zm_magicbox::treasure_chest_canplayerreceiveweapon() opens with
//  get_is_in_box( weapon ), which is level.zombie_weapons[w].is_in_box, and
//  treasure_chest_chooseweightedrandomweapon() rebuilds its candidate list on
//  every single use. So the flag is read live and setting it late is safe -
//  nothing snapshots the box contents at init.
//
//  🛑 NO WEAPON IS REGISTERED OR DE-REGISTERED HERE, DELIBERATELY.
//  quality_of_life.gsc::zmqol_wallbuy_box_add() still runs untouched, so both
//  the Olympia and the M14 keep their include_weapon() calls, their
//  add_zombie_weapon() struct, their wall buys, their camos and their client
//  twin in zm_expanded.csc. Only the box flag moves. A weapon list that differs
//  between the server and the client half is the EXE_CLIENT_FIELD_MISMATCH this
//  mod has been bitten by before, and there is no reason to go near it: the
//  user asked for the box, not for the guns.
//
//  📝 THE OLYMPIA IS NOT CALLED "OLYMPIA". The weapon is rottweil72_zm; only
//  its art is named for the Olympia. Origins gets the mod's private copy,
//  rottweil72qol_zm (quality_of_life.gsc::zmqol_tomb_weapon), so both names are
//  listed below.
//
//  📝 STOCK AGREES WITH THE USER. Every stock map registers both guns with
//  include_weapon( name, 0 ) - zm_transit.gsc:1891/1897, zm_buried.gsc:1195/1201,
//  zm_nuked.gsc:761/767, zm_prison.gsc:838/840, zm_tomb.gsc:1069. They were
//  only ever in the box because this mod put them there on 2026-08-18 and
//  2026-08-20, at the same user's request. This returns them to stock.
//
//  🌟 THE BLUNDERGAT NEEDED NOTHING BUT PROOF, and that is what the log line is
//  for. Stock Mob includes it with the flag already set -
//  zm_prison.gsc:864 include_weapon( "blundergat_zm" ), no second argument, so
//  in_box defaults to 1 - and zm_prison::include_weapons() is called
//  unconditionally from main() (:144), in every gametype, survival included.
//  The gun is limited to one per match (add_limited_weapon, :872) and Mob's own
//  zm_alcatraz_utility::check_for_special_weapon_limit_exist() refuses it to a
//  player already holding an Acid Gat, but nothing in that chain is
//  gametype-aware. So on Cell Block and Docks it was already a legal pull and a
//  quiet one: ~55 names in that box, so twenty spins miss any given gun about
//  seven times in ten. This asserts the flag anyway - free if it was already
//  right - and prints what it found, so the next boot says which it was rather
//  than leaving it to memory.
// ============================================================================

#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;

init()
{
    level thread zmqol_boxfix_think();
}

//  Named separately from the map test so a future map that carries one of these
//  guns is a one-line change rather than a rewrite.
zmqol_boxfix_banned_names()
{
    a = [];
    a[a.size] = "rottweil72_zm";        //  Olympia
    a[a.size] = "rottweil72qol_zm";     //  Olympia, Origins' private copy
    a[a.size] = "m14_zm";
    return a;
}

zmqol_boxfix_forced_names()
{
    a = [];

    //  Mob only. blundergat_zm exists in no other map's fastfile, and naming a
    //  weapon that was never registered here is harmless (every write below is
    //  isdefined-guarded) but pointless.
    if ( isdefined( level.script ) && level.script == "zm_prison" )
    {
        a[a.size] = "blundergat_zm";
    }

    return a;
}

// ----------------------------------------------------------------------------
//  🛑 THIS RE-ASSERTS RATHER THAN SETTING ONCE, and the reason is in this mod's
//  own history. quality_of_life.gsc::zmqol_wallbuy_box_reassert() exists
//  because the map's registration can rebuild a weapon struct AFTER ours and
//  silently undo the flag, with nothing logged. The same hazard applies here in
//  both directions, and it now has a second source: that re-assert itself runs
//  0.05 s after its init and forces its own list back ON. The Olympia and the
//  M14 were removed from that list in the same edit as this file, but a poll is
//  what makes this correct no matter which of the two lands first.
//
//  Cost: a handful of array lookups every quarter second for ten seconds, then
//  one pass every five seconds. The box is a per-spin read, so even the slow
//  pass would be in time on its own.
// ----------------------------------------------------------------------------
zmqol_boxfix_think()
{
    level endon( "end_game" );

    a_banned = zmqol_boxfix_banned_names();
    a_forced = zmqol_boxfix_forced_names();

    n_fast = 40;

    for ( i = 0; ; i++ )
    {
        if ( isdefined( level.zombie_weapons ) )
        {
            for ( j = 0; j < a_banned.size; j++ )
            {
                zmqol_boxfix_set( a_banned[j], 0 );
            }

            for ( j = 0; j < a_forced.size; j++ )
            {
                zmqol_boxfix_set( a_forced[j], 1 );
            }
        }

        if ( i < n_fast )
        {
            wait 0.25;
        }
        else
        {
            wait 5;
        }
    }
}

//  Returns nothing and logs only on a CHANGE, so a correct map prints one line
//  per gun at most and a silent log means nothing had to be corrected.
zmqol_boxfix_set( str_weapon, n_state )
{
    if ( !isdefined( level.zombie_weapons[ str_weapon ] ) )
    {
        return;
    }

    if ( is_true( level.zombie_weapons[ str_weapon ].is_in_box ) == is_true( n_state ) )
    {
        return;
    }

    level.zombie_weapons[ str_weapon ].is_in_box = n_state;

    if ( isdefined( level.zombie_include_weapons ) )
    {
        level.zombie_include_weapons[ str_weapon ] = n_state;
    }

    if ( n_state )
    {
        println( "[zm_qol] boxfix: " + str_weapon + " PUT IN the box on " + level.script + " / " + getdvar( "ui_zm_mapstartlocation" ) );
    }
    else
    {
        println( "[zm_qol] boxfix: " + str_weapon + " TAKEN OUT of the box on " + level.script + " / " + getdvar( "ui_zm_mapstartlocation" ) );
    }
}
