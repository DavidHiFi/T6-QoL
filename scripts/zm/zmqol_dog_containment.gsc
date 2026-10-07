// ============================================================================
//  zmqol_dog_containment.gsc  -  HELLHOUND CONTAINMENT FOR EVERY DOG MAP
// ----------------------------------------------------------------------------
//  Owner report, 2026-10-07, Bus Depot survival round 35: "a hellhound
//  literally ran out of the map." The same thing was seen weeks earlier, on a
//  different build, so it is not a regression of any one version - it is a
//  hole in stock dog handling that this mod simply exposes on every map that
//  runs dog rounds.
//
//  WHY A DOG CAN LEAVE THE ARENA (stock mechanics, from the decompile):
//
//  1. Every hellhound is spawned at level.dog_spawners[0] - on TranZit that
//     actor sits at the WORLD ORIGIN (so_zsurvival_zm_transit adds
//     actor_zombie_dog at "0 0 0"), ghosted and magic-bullet-shielded. The
//     only thing that moves it into the arena and makes it fightable is the
//     spawn_loc thread dog_spawn_fx() (_zm_ai_dogs.gsc:216-249), which
//     forceteleports it 1.5s later and then strips the shield, shows it and
//     clears ignoreme. If that thread dies on any line, the dog keeps
//     whatever state it was born with.
//
//  2. There are no "dog_clips" entities on any Black Ops II map, so stock's
//     dog_clip_monitor() (_zm_ai_dogs.gsc:649) has an empty array to work
//     with and never disconnects a single path during a dog round. Dog
//     containment on T6 rests entirely on arena collision.
//
//  3. Dogs move through maps/mp/animscripts/dog_move, which has no crawl or
//     mantle animation. When the pathing solver routes a dog through a
//     humanoid node_negotiation pair (zm_traverse_garage_door,
//     zm_traverse_car_reverse, ...), there is no anim to play, so the actor
//     just keeps travelling along the path spline in a straight line - and
//     straight through the brush it was supposed to traverse, out of the
//     arena. This is measured, not guessed: it is the confirmed mechanism
//     behind the Diner reports (zm_transit_loc_diner.gsc, the 2026-08-23 and
//     2026-08-25 records), and it is map-independent - any map with crawl
//     under/car traverses inside a dog arena can produce it.
//
//  4. Stock's own backstop cannot save the round. round_spawn_failsafe()
//     (_zm.gsc:3990, threaded on every dog by dog_init) only damages a dog
//     that has FAILED TO MOVE for a full check interval. A runaway that keeps
//     sprinting outside the map never fails it, level.zombie_total never
//     reaches 0, and the dog round cannot end.
//
//  THE FIX, and why it looks like the Diner's: Diner already had this exact
//  bug class ("through the back wall out of the map, running indefinitely",
//  2026-08-23; "the last hellhound ... the round could not progress",
//  2026-08-25) and its loc script ships a watchdog that repairs the
//  pre-spawn state, returns escaped dogs to the arena, and hard-backstops
//  the last dog so a round can never hang. That watchdog is live-verified on
//  Diner. This file is the same repair made map-agnostic, for every map that
//  runs stock dog rounds (Bus Depot, Farm, Town, Die Rise, Mob of the Dead,
//  Buried, Origins, Nuketown). A location script that owns its own dogs
//  (Diner, via level.zmqol_diner_dog_locs) is detected and left alone.
//
//  WHAT IS DELIBERATELY NOT HERE:
//  - No spawn-placement override. Stock maps keep stock placement; this only
//    repairs dogs that already went wrong, exactly like the Diner watchdog.
//  - Nothing from quality_of_life.gsc. That file is on a compiled-bytecode
//    ceiling (workspace AGENTS.md item 1b) and must not gain a byte; this
//    script is fully self-contained instead.
//  - No fast_restart or instant-exit touch. Those are UI features and stay.
// ============================================================================

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_ai_dogs;

main()
{
}

init()
{
    //  fast_restart re-runs init() while the previous match's thread may
    //  still be parked in its wait - notify the old one to die before
    //  starting the new one, so a restarted match never carries two.
    level notify( "zmqol_dog_containment_reset" );
    level thread zmqol_dog_containment_watch();
}

//  Runs for the life of the match. One pass per second over every
//  zombie-team AI that is a live hellhound. Everything is guarded: maps and
//  gametypes without dogs simply have an empty list to walk.
zmqol_dog_containment_watch()
{
    level endon( "end_game" );
    level endon( "intermission" );
    level endon( "zmqol_dog_containment_reset" );

    for ( ;; )
    {
        wait 1;

        if ( !isdefined( level.zombie_team ) )
            continue;

        //  TEMPORARY DIAGNOSTIC (2026-10-07 live test): one line every 10s
        //  saying the thread is alive and what each enumeration API sees.
        //  Gated on zmqol_dog_heartbeat (default 0 = silent). Remove once the
        //  containment is live-verified.
        if ( getdvarint( "zmqol_dog_heartbeat" ) )
        {
            i_hb_ai = 0;
            i_hb_sp = 0;

            if ( isdefined( getaiarray( level.zombie_team ) ) )
                i_hb_ai = getaiarray( level.zombie_team ).size;

            if ( isdefined( getaispeciesarray( level.zombie_team, "all" ) ) )
                i_hb_sp = getaispeciesarray( level.zombie_team, "all" ).size;

            println( "[zm_qol] hellhounds: heartbeat ai=" + i_hb_ai + " species=" + i_hb_sp );
        }

        //  A location script that owns this map's dogs (currently Diner)
        //  ships its own repair, containment and last-dog timeout keyed to
        //  its own snapshot. Two watchdogs teleporting the same dog would
        //  fight each other, so generic containment stands down there.
        if ( isdefined( level.zmqol_diner_dog_locs ) && level.zmqol_diner_dog_locs.size > 0 )
            continue;

        //  ?? getaiarray() CANNOT SEE THE DOGS ON THIS MAP - MEASURED LIVE
        //  2026-10-07 (Bus Depot, zm_qol + probes): with two live hellhounds on
        //  the field, getaiarray( level.zombie_team ) returned 0 while
        //  getaispeciesarray( level.zombie_team, "all" ) returned 2. The map's
        //  only dog spawner (actor_zombie_dog, so_zsurvival_zm_transit.mapents)
        //  carries no team key, and the generic zombie spawn init that writes
        //  self.team = level.zombie_team (_zm_spawner.gsc:270) is not part of
        //  the dog spawner's spawn chain - so the dogs never enter the team
        //  bucket every stock getaiarray call filters by. The species array is
        //  what stock's own round bookkeeping uses (get_round_enemy_array,
        //  _zm_utility.gsc:135), and it includes corpses, so filter to alive
        //  here: the last-dog timeout below must count only living actors.
        a_all = getaispeciesarray( level.zombie_team, "all" );

        a_ai = [];

        for ( i_hb = 0; i_hb < a_all.size; i_hb++ )
        {
            if ( isdefined( a_all[i_hb] ) && isalive( a_all[i_hb] ) )
                a_ai[a_ai.size] = a_all[i_hb];
        }

        for ( i = 0; i < a_ai.size; i++ )
        {
            ai = a_ai[i];

            if ( !isdefined( ai ) || !isalive( ai ) )
                continue;

            if ( !( isdefined( ai.isdog ) && ai.isdog ) )
                continue;

            //  First sighting: remember when, and move on. dog_spawn_fx takes
            //  1.5s of its own before it teleports, so nothing is judged
            //  before a healthy spawn has had its chance.
            if ( !isdefined( ai.zmqol_dog_seen ) )
            {
                ai.zmqol_dog_seen = gettime();
                continue;
            }

            if ( gettime() - ai.zmqol_dog_seen < 4000 )
                continue;

            //  ------------------------------------------------  pre-spawn repair
            //  A dog whose dog_spawn_fx() thread died mid-way is still in the
            //  state it spawned with: magic bullet shield (unkillable),
            //  ignoreme (ignores players), and none of the attack properties
            //  zombie_setup_attack_properties_dog() would have set. Re-assert
            //  the end state stock was trying to reach, field for field.
            //
            //  disablearrivals is zombie_setup_attack_properties_dog()'s last
            //  write and nothing else in the dog path sets it, so it doubles
            //  as "did that function complete" - gating the growl thread on
            //  it is what stops a healthy dog from growling twice.
            if ( !isdefined( ai.zmqol_dog_state_fixed ) )
            {
                ai.zmqol_dog_state_fixed = 1;
                str_fixed = "";

                //  is_magic_bullet_shield_enabled() is exactly this test
                //  (_zm_utility.gsc:2784), inlined.
                if ( isdefined( ai.magic_bullet_shield ) && ai.magic_bullet_shield == 1 )
                {
                    ai stop_magic_bullet_shield();
                    str_fixed = str_fixed + " unkillable";
                }

                if ( isdefined( ai.ignoreme ) && ai.ignoreme )
                {
                    ai.ignoreme = 0;
                    str_fixed = str_fixed + " ignoreme";
                }

                if ( !( isdefined( ai.disablearrivals ) && ai.disablearrivals ) )
                {
                    //  zombie_setup_attack_properties_dog(), inline - it is
                    //  five field writes plus a dev-only history line.
                    ai.ignoreall          = 0;
                    ai.pathenemyfightdist = 64;
                    ai.meleeattackdist    = 64;
                    ai.disablearrivals    = 1;
                    ai.disableexits       = 1;

                    ai thread dog_behind_audio();
                    str_fixed = str_fixed + " attack-properties+audio";
                }

                ai show();
                ai setfreecameralockonallowed( 1 );

                if ( str_fixed != "" )
                    println( "[zm_qol] hellhounds: a dog was still in its pre-spawn state after 4s -" + str_fixed + " - stock's dog_spawn_fx did not finish. Repaired." );
            }

            //  ------------------------------------------------  last-dog timeout
            //  The hard backstop. Exactly one zombie-team AI left, alive, for
            //  20+ seconds: the round is hanging on a dog the player cannot
            //  reach, for a reason neither test below caught (the Diner
            //  record has one: the dog was within 2500 units of a player the
            //  whole time, behind unreachable geometry). Nothing about a
            //  healthy dog round holds "1 AI left" for 20s - the player kills
            //  the last dog in seconds, or the containment below already
            //  fired. Past the timeout, return it unconditionally: no
            //  distance test and no zone test, because both are exactly what
            //  already missed it once.
            if ( a_ai.size == 1 )
            {
                if ( !isdefined( ai.zmqol_dog_lastone_since ) )
                    ai.zmqol_dog_lastone_since = gettime();

                if ( !isdefined( ai.zmqol_dog_lastone_rescued ) && gettime() - ai.zmqol_dog_lastone_since >= 20000 )
                {
                    ai.zmqol_dog_lastone_rescued = 1;
                    zmqol_dog_containment_return( ai, "LAST ZOMBIE TIMEOUT - sole remaining dog had not ended the round in 20s, force-returned" );
                }
            }
            else
            {
                ai.zmqol_dog_lastone_since   = undefined;
                ai.zmqol_dog_lastone_rescued = undefined;
            }

            //  ------------------------------------------------  runaway rescue
            //  One test, measured, stock-aligned: a dog more than 2500 units
            //  from EVERY player for five consecutive seconds is outside
            //  anything stock would ever have placed. Stock's own dog spawn
            //  refuses any spot further than 1150 units from a player
            //  (dog_spawn_transit_logic, dist_squared > 1322500), so 2500 has
            //  generous headroom, and a dog near ONE player in a split co-op
            //  never trips it (the test requires far from EVERY player).
            //
            //  ?? v2 (2026-10-07 live test, Bus Depot): the first version also
            //  required get_zone_from_position() to return undefined, and THAT
            //  VETO BLINDED THE RESCUE TO THE EXACT REPORTED BUG. The probe
            //  teleported a dog to the cornfield (9593.5,-173.5,-207.3) - the
            //  kind of place the owner's round-35 runaway ends up - and the
            //  rescue never fired: that position sits inside a TranZit zone
            //  volume (zone_trans_cornfield), so the "no enabled zone" test
            //  passed and the dog was left outside. Measured, not inferred:
            //  heartbeat lines showed the thread alive and seeing both dogs
            //  (species=2) while the cornfield dog sat there for the whole 25s
            //  window. The distance test alone is the stock-aligned question;
            //  the zone veto is gone.
            //
            //  Five consecutive seconds, not one: a dog chasing a player
            //  across a gap between spawn locations must never be teleported.
            //  The counter resets the moment the dog is near any player again.
            b_far = 1;

            foreach ( player in get_players() )
            {
                if ( isdefined( player ) && distancesquared( ai.origin, player.origin ) < 6250000 )   //  2500 units
                    b_far = 0;
            }

            if ( !b_far )
            {
                ai.zmqol_dog_far_ticks = 0;
            }
            else
            {
                if ( !isdefined( ai.zmqol_dog_far_ticks ) )
                    ai.zmqol_dog_far_ticks = 0;

                ai.zmqol_dog_far_ticks++;

                if ( ai.zmqol_dog_far_ticks >= 5 )
                {
                    ai.zmqol_dog_far_ticks = 0;
                    zmqol_dog_containment_return( ai, "RUNAWAY DOG was more than 2500 units from every player for 5s - returned to the arena" );
                }
            }

            //  ------------------------------------------------  stranded rescue
            //  A dog still at its spawner 4s after spawn never got its
            //  teleport: on TranZit the spawner is the world origin, seven
            //  kilometres from the Bus Depot arena, and a dog left there is
            //  invisible and out of the fight for good. Once per dog - do not
            //  fight the stock thread if it is merely slow.
            if ( isdefined( ai.zmqol_dog_rescued ) )
                continue;

            if ( !isdefined( level.dog_spawners ) || level.dog_spawners.size == 0 || !isdefined( level.dog_spawners[0] ) )
                continue;

            if ( distancesquared( ai.origin, level.dog_spawners[0].origin ) > 4096 )     //  64 units
                continue;

            ai.zmqol_dog_rescued = 1;
            zmqol_dog_containment_return( ai, "STRANDED DOG still at its spawner 4s after spawn - returned to the arena" );
        }
    }
}

//  Teleport a dog to a real in-arena spot and re-assert the whole of stock's
//  dog_spawn_fx() end state, in stock's order, because a dog that got out
//  there may have got out there because part of that end state never ran.
//  s_reason goes into the log line.
zmqol_dog_containment_return( ai, s_reason )
{
    s_home = zmqol_dog_containment_home( ai );

    if ( !isdefined( s_home ) || !isdefined( s_home.origin ) )
    {
        println( "[zm_qol] hellhounds: " + s_reason + " - but no in-arena location exists to return it to" );
        return;
    }

    //  Face the dog the way stock's own spawn does: at its favourite enemy.
    v_angles = ai.angles;

    if ( isdefined( ai.favoriteenemy ) && isdefined( ai.favoriteenemy.origin ) )
    {
        v_face   = vectortoangles( ai.favoriteenemy.origin - s_home.origin );
        v_angles = ( ai.angles[0], v_face[1], ai.angles[2] );
    }

    ai forceteleport( s_home.origin, v_angles );

    if ( isdefined( ai.magic_bullet_shield ) && ai.magic_bullet_shield == 1 )
        ai stop_magic_bullet_shield();

    ai show();
    ai setfreecameralockonallowed( 1 );
    ai.ignoreme  = 0;
    ai.ignoreall = 0;
    ai.zmqol_dog_far_ticks = 0;
    ai notify( "visible" );

    println( "[zm_qol] hellhounds: " + s_reason + " to (" + int( s_home.origin[0] ) + "," + int( s_home.origin[1] ) + "," + int( s_home.origin[2] ) + ")" );
}

//  An in-arena spot for a returned dog, in stock's own order of preference:
//  the map's live dog structs inside stock's own 400-1150 unit window, then
//  those structs unfiltered, then the ground zombie spawn list (which the
//  zonemgr keeps to enabled+active zones, i.e. the arena floor), then the
//  spawner itself as a last resort. Randomised so consecutive returns differ.
zmqol_dog_containment_home( ai )
{
    s_loc = undefined;

    if ( isdefined( level.enemy_dog_locations ) && level.enemy_dog_locations.size > 0 )
    {
        s_loc = zmqol_dog_containment_pick( level.enemy_dog_locations, 160000, 1322500 );   //  400^2, 1150^2

        if ( !isdefined( s_loc ) )
            s_loc = zmqol_dog_containment_pick( level.enemy_dog_locations, 0, 0 );
    }

    if ( !isdefined( s_loc ) && isdefined( level.zombie_spawn_locations ) && level.zombie_spawn_locations.size > 0 )
        s_loc = zmqol_dog_containment_pick( level.zombie_spawn_locations, 0, 0 );

    if ( !isdefined( s_loc ) && isdefined( level.dog_spawners ) && level.dog_spawners.size > 0 && isdefined( level.dog_spawners[0] ) )
        s_loc = level.dog_spawners[0];

    return s_loc;
}

//  A location from a_locs that sits i_min2..i_max2 units-squared from every
//  player when i_min2 > 0, or any valid location otherwise.
zmqol_dog_containment_pick( a_locs, i_min2, i_max2 )
{
    a_shuffled = array_randomize( a_locs );

    for ( i = 0; i < a_shuffled.size; i++ )
    {
        s = a_shuffled[i];

        if ( !isdefined( s ) || !isdefined( s.origin ) )
            continue;

        if ( i_min2 > 0 )
        {
            b_ok = 1;

            foreach ( player in get_players() )
            {
                d2 = distancesquared( s.origin, player.origin );

                if ( d2 < i_min2 || d2 > i_max2 )
                {
                    b_ok = 0;
                    break;
                }
            }

            if ( !b_ok )
                continue;
        }

        return s;
    }

    return undefined;
}
