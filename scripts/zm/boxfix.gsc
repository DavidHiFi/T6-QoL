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
//  🛑 _zm_weapons IS REQUIRED and its absence is not a compile error.
//  add_zombie_weapon() and add_limited_weapon() live here; include_weapon()
//  lives in _zm_utility above, which is why three of the four calls in
//  zmqol_blundergat_register() resolved and two did not. gsc-tool compiles the
//  file either way and build.bat's check-loc-refs only walks in-mod
//  cross-script calls, so the first sign was the game's own dialog:
//      Unresolved external : "add_zombie_weapon" with 7 parameters
//      Unresolved external : "add_limited_weapon" with 2 parameters
//  scripts\zm\bouncingbetty.gsc calls the same two functions and carries this
//  same line - that file is the template and the include was dropped copying it.
#include maps\mp\zombies\_zm_weapons;

init()
{
    zmqol_blundergat_register();
    zmqol_paralyzer_register();
    level thread zmqol_boxfix_think();
}

// ============================================================================
//  zmqol_paralyzer_register  -  BURIED'S PARALYZER, OFF BURIED     (v2.17.35)
//
//  Art in zone_source\mod_paralyzer.zone, behaviour in scripts\zm\paralyzer.gsc
//  (stock's _zm_weap_slowgun with its seven map-locked loadfx calls repointed
//  at effects this mod already ships). Read either banner for the reasoning.
//
//  🛑 TWO MAPS REFUSE IT, and paralyzer.gsc::init() refuses on the same pair,
//  so the weapon list and the behaviour can never disagree:
//    zm_buried  already has the gun, registered by the map with its own values
//               and already in the box (zm_buried.gsc:1236 include_weapon(
//               "slowgun_zm", 1 )). Registering again would rebuild the struct
//               and run the core init twice.
//    zm_tomb    Origins' ACTOR clientfield set is 31 of 32 stock and this gun
//               wants 8 of them (slowgun_fx 3 + anim_rate 5). TranZit and Die
//               Rise sit at 4-5, Nuketown 4, Mob 11-13.
//
//  📝 THE HINT IS THE GUN'S OWN NAME, NOT STOCK'S BOX STRING. Buried passes
//  &"ZOMBIE_WEAPON_SLOWGUN", which is NOT in en_patch_zm.ff - dumped that
//  zone's .str and it is absent, so off Buried it would draw as a raw token.
//  &"ZMWEAPON_PARALYZER" is in there (it is the defs' own displayName) and
//  reads "Paralyzer".
//
//  📝 Cost and vox are Buried's own (zm_buried.gsc:1157), as is the
//  one-per-match limit on both halves.
// ============================================================================
zmqol_paralyzer_register()
{
    //  🛑 getdvar( "mapname" ), NOT level.script, and the client twin reads the
    //  same dvar. Two sides gating one registration on two different sources is
    //  exactly how navcard_held desynced (see zm_expanded.csc's banner on it):
    //  they agree almost always, and the day they do not, one VM registers
    //  fields the other has not and everybody is dropped.
    str_map = getdvar( "mapname" );

    if ( str_map == "zm_buried" || str_map == "zm_tomb" )
    {
        return;
    }

    precacheitem( "slowgun_zm" );
    precacheitem( "slowgun_upgraded_zm" );

    include_weapon( "slowgun_zm" );                 //  in_box defaults to 1
    include_weapon( "slowgun_upgraded_zm", 0 );

    if ( isdefined( level.zombie_weapons ) && isdefined( level.zombie_weapons[ "slowgun_zm" ] ) )
    {
        return;
    }

    add_zombie_weapon( "slowgun_zm", "slowgun_upgraded_zm", &"ZMWEAPON_PARALYZER", 10, "wpck_paralyzer", "", undefined );
    add_limited_weapon( "slowgun_zm", 1 );
    add_limited_weapon( "slowgun_upgraded_zm", 1 );
}

// ============================================================================
//  zmqol_blundergat_register  -  THE BLUNDERGAT ON EVERY MAP        (v2.17.32)
//
//  User, 2026-09-22: *"just the same way you've put weapons from other maps to
//  other maps just do the same thing."*  So this is that mechanism, unchanged:
//  the art is declared in zone_source\mod_blundergat.zone and linked into
//  mod.ff, the two defs ship raw in weapons\zm\, and the gun is registered here
//  from a root script the way scripts\zm\bouncingbetty.gsc registers the
//  Bouncing Betty. Read mod_blundergat.zone for what the port needed and, more
//  usefully, for the four things it did NOT need - the camo, the three icons
//  and both display strings are all assets every map already loads.
//
//  🛑 ON MOB THIS ONLY MOVES THE FLAG. zm_prison registers the gun itself
//  (zm_prison.gsc:775 via custom_add_weapons, included at :864) and re-running
//  add_zombie_weapon there would rebuild a struct the map already built with
//  its own cost and vox. Same shape as quality_of_life.gsc's
//  zmqol_wallbuy_box_add(): if the struct exists, stop.
//
//  📝 VALUES ARE MOB'S OWN, copied not invented - cost 500 and vox "wpck_shot"
//  from zm_prison.gsc:775, hint &"ZMWEAPON_BLUNDERGAT" from the def's own
//  displayName. add_limited_weapon mirrors zm_prison.gsc:872 so the gun behaves
//  on other maps exactly as it does on Mob; the mod's own no_box_limits row
//  already governs whether that quota is enforced, through
//  level.no_limited_weapons, so this adds no new rule of its own.
//
//  🛑 THE CLIENT TWIN IS zm_expanded.csc and it must include the same name.
//  The client's include_weapon builds level._display_box_weapons, which is what
//  draws the gun floating over an open box - a server-only registration gives a
//  box that awards a weapon while showing nothing.
// ============================================================================
zmqol_blundergat_register()
{
    precacheitem( "blundergat_zm" );
    precacheitem( "blundergat_upgraded_zm" );

    include_weapon( "blundergat_zm" );              //  in_box defaults to 1
    include_weapon( "blundergat_upgraded_zm", 0 );

    if ( isdefined( level.zombie_weapons ) && isdefined( level.zombie_weapons[ "blundergat_zm" ] ) )
    {
        return;
    }

    add_zombie_weapon( "blundergat_zm", "blundergat_upgraded_zm", &"ZMWEAPON_BLUNDERGAT", 500, "wpck_shot", "", undefined );
    add_limited_weapon( "blundergat_zm", 1 );
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

    //  v2.17.32 - EVERY MAP NOW, not just Mob. The art is in mod.ff and the
    //  defs are in weapons\zm\, so zmqol_blundergat_register() above has
    //  registered it wherever this script runs. On Mob the map registered it
    //  first and this only holds the flag it already had.
    a[a.size] = "blundergat_zm";

    //  Buried and Origins are skipped by zmqol_paralyzer_register(); naming it
    //  here anyway is harmless because zmqol_boxfix_set() is isdefined-guarded,
    //  and on Buried the flag it would assert is the one the map already set.
    a[a.size] = "slowgun_zm";

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
