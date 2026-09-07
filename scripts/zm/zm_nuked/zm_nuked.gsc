#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_weapons;
#include maps\mp\zm_nuked;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_perks;
#include maps\mp\zombies\_zm_perk_divetonuke;
#include maps\mp\animscripts\zm_death;
#include maps\mp\zombies\_zm_game_module;
#include maps\mp\zm_nuked_perks;

main()
{
    replaceFunc (maps\mp\zm_nuked_perks::init_nuked_perks, ::init_nuked_perks );
    replaceFunc (maps\mp\zm_nuked_perks::bring_perk, ::bring_perk );
    replaceFunc (maps\mp\zm_nuked_perks::perks_from_the_sky, ::perks_from_the_sky );
    //  v2.8.2 - Pack-a-Punch use trigger 40 -> 64. Nuketown only; see
    //  zmqol_perk_machine_spawn_init() at the bottom of this file.
    replaceFunc (maps\mp\zombies\_zm_perks::perk_machine_spawn_init, ::zmqol_perk_machine_spawn_init );
    //  v2.14.16 - SUBTITLES. Nuketown's only dialogue is Marlton in the bunker,
    //  played by position and never through the dialogue system the root hook
    //  in zmqol_subtitles.gsc watches. See zmqol_subs_marlton_vo_inside_bunker()
    //  at the bottom of this file. The target is a threaded, unqualified
    //  same-file call, which replaceFunc DOES intercept (STOCK_REFERENCE 7a).
    replaceFunc (maps\mp\zm_nuked::marlton_vo_inside_bunker, ::zmqol_subs_marlton_vo_inside_bunker );
}


// ============================================================================
//  zmqol_nuked_fix_sunken_spot  -  one Nuketown drop pad is ~10 units too low
//                                                                  (v1.99.61)
//
//  User, 2026-08-18, with a screenshot of a half-buried Mule Kick machine:
//  *"this drop location in nuketown is in the ground for some reason, fix it's
//  position back to normal"*. They were standing at x 1511 y 889 z -60.
//
//  🌟 MEASURED OUT OF THE MAP ITSELF, NOT ESTIMATED. zm_nuked.ff's mapents were
//  dumped with OpenAssetTools and every drop pad read off. Each `zm_random_machine`
//  struct (up at z 2204, the air-drop start) targets a LANDING struct on the
//  ground, and that landing struct in turn targets a `p6_zm_cratepile` blocker
//  model - the crate stack that stands on the pad until the machine lands. The
//  crate is placed on the floor by the level designer, so it reads the floor
//  height for free. Landing z minus crate z, all ten pads:
//
//      pf15_auto2887  -72     crate -68.16   -3.84
//      pf15_auto2899  -64     crate -62.00   -2.00
//      pf15_auto2900  -76     crate -64.16  -11.84   <-- THIS ONE
//      pf15_auto2901  -71     crate -69.00   -2.00
//      pf15_auto2902  +75     crate +74.50   +0.50
//      pf15_auto2903  -61     crate -59.00   -2.00
//      pf15_auto2904  -66     crate -65.61   -0.39
//      pf15_auto2905  -68     crate -64.04   -3.96
//      pf15_auto2906  -68     crate -68.94   +0.94
//      pf15_auto2907  -68     crate -68.48   +0.48
//
//  Nine pads sit between +0.94 and -3.96 of their crate; pad 2900 sits 11.84
//  below its own. It is the only outlier and it is three times the worst of the
//  others. Three pads use EXACTLY -2.00, so that is the designer's intended
//  offset, which puts 2900 at -64.16 - 2.00 = -66.16 instead of -76.
//
//  📝 The crate origins also prove they are base-anchored rather than centred:
//  if they were centred every pad would sit ~30 below its crate, and none does.
//
//  🛑 THIS IS A STOCK MAP FAULT, NOT ONE THIS MOD INTRODUCED - and it is worth
//  saying because it explains why it shows up now. Stock fills 5 pads out of
//  ten at random; this mod fills 9, so a pad stock usually skips is now used
//  almost every match.
//
//  Matched by position with a 4-unit tolerance rather than by targetname, so if
//  a future map file ever differs this quietly does nothing instead of moving
//  the wrong pad. Runs before the struct lists are built, so the correction is
//  in place whichever perk the shuffle sends there.
// ============================================================================
zmqol_nuked_fix_sunken_spot()
{
    a_air = getstructarray( "zm_random_machine", "script_noteworthy" );

    for ( i = 0; i < a_air.size; i++ )
    {
        if ( !isdefined( a_air[i].target ) )
            continue;

        s_land = getstruct( a_air[i].target, "targetname" );

        if ( !isdefined( s_land ) || !isdefined( s_land.origin ) )
            continue;

        if ( distance( s_land.origin, ( 1624, 960, -76 ) ) > 4 )
            continue;

        s_land.origin = ( s_land.origin[0], s_land.origin[1], -66.16 );
        println( "[zm_qol] NUKED raised sunken drop pad pf15_auto2900 to z -66.16" );
    }
}
init_nuked_perks()
{
    level.perk_arrival_vehicle = getent( "perk_arrival_vehicle", "targetname" );
    level.perk_arrival_vehicle setmodel( "tag_origin" );
    flag_init( "perk_vehicle_bringing_in_perk" );

    //  v1.99.61 - correct the one drop pad that sits ~10 units under the floor,
    //  BEFORE the struct lists below read it. See the measurement above.
    zmqol_nuked_fix_sunken_spot();
    structs = getstructarray( "zm_perk_machine", "targetname" );

    for ( i = 0; i < structs.size; i++ )
    {
        structs[i] structdelete();
    }

    level.nuked_perks = [];
    level.nuked_perks[0] = spawnstruct();
    level.nuked_perks[0].model = "zombie_vending_revive";
    level.nuked_perks[0].script_noteworthy = "specialty_quickrevive";
    level.nuked_perks[0].turn_on_notify = "revive_on";
    level.nuked_perks[1] = spawnstruct();
    level.nuked_perks[1].model = "zombie_vending_sleight";
    level.nuked_perks[1].script_noteworthy = "specialty_fastreload";
    level.nuked_perks[1].turn_on_notify = "sleight_on";
    level.nuked_perks[2] = spawnstruct();
    level.nuked_perks[2].model = "zombie_vending_doubletap2";
    level.nuked_perks[2].script_noteworthy = "specialty_rof";
    level.nuked_perks[2].turn_on_notify = "doubletap_on";
    level.nuked_perks[3] = spawnstruct();
    level.nuked_perks[3].model = "zombie_vending_jugg";
    level.nuked_perks[3].script_noteworthy = "specialty_armorvest";
    level.nuked_perks[3].turn_on_notify = "juggernog_on";
    level.nuked_perks[4] = spawnstruct();
    level.nuked_perks[4].model = "p6_anim_zm_buildable_pap";
    level.nuked_perks[4].script_noteworthy = "specialty_weapupgrade";
    level.nuked_perks[4].turn_on_notify = "Pack_A_Punch_on";
    // Added
    level.nuked_perks[5] = spawnstruct();
    level.nuked_perks[5].model = "zombie_vending_marathon";
    level.nuked_perks[5].script_noteworthy = "specialty_longersprint";
    level.nuked_perks[5].turn_on_notify = "marathon_on";
    level.nuked_perks[6] = spawnstruct();
    level.nuked_perks[6].model = "zombie_vending_three_gun";
    level.nuked_perks[6].script_noteworthy = "specialty_additionalprimaryweapon";
    level.nuked_perks[6].turn_on_notify = "additionalprimaryweapon_on";
    level.nuked_perks[7] = spawnstruct();
    level.nuked_perks[7].model = "p6_zm_al_vending_ads_on";
    level.nuked_perks[7].script_noteworthy = "specialty_deadshot";
    level.nuked_perks[7].turn_on_notify = "deadshot_on";
    level.nuked_perks[8] = spawnstruct();
    level.nuked_perks[8].model = "p6_zm_al_vending_nuke_on";
    level.nuked_perks[8].script_noteworthy = "specialty_flakjacket";
    level.nuked_perks[8].turn_on_notify = "divetonuke_on";
    players = getnumexpectedplayers();

    if ( players == 1 )
    {
        level.override_perk_targetname = "zm_perk_machine_override";
        revive_perk_structs = getstructarray( "solo_revive", "targetname" );

        for ( i = 0; i < revive_perk_structs.size; i++ )
        {
            random_revive_structs[i] = getstruct( revive_perk_structs[i].target, "targetname" );
            random_revive_structs[i].script_int = revive_perk_structs[i].script_int;
        }

        level.random_revive_structs = array_randomize( random_revive_structs );
        level.random_revive_structs[0].targetname = "zm_perk_machine_override";
        level.random_revive_structs[0].model = level.nuked_perks[0].model;
        level.random_revive_structs[0].blocker_model = getent( level.random_revive_structs[0].target, "targetname" );
        level.random_revive_structs[0].script_noteworthy = level.nuked_perks[0].script_noteworthy;
        level.random_revive_structs[0].turn_on_notify = level.nuked_perks[0].turn_on_notify;

        if ( !isdefined( level.struct_class_names["targetname"]["zm_perk_machine_override"] ) )
        {
            level.struct_class_names["targetname"]["zm_perk_machine_override"] = [];
        }

        level.struct_class_names["targetname"]["zm_perk_machine_override"][level.struct_class_names["targetname"]["zm_perk_machine_override"].size] = level.random_revive_structs[0];
/#
        level.random_revive_structs[0] thread draw_debug_location();
#/
        random_perk_structs = [];
        perk_structs = getstructarray( "zm_random_machine", "script_noteworthy" );
        perk_structs = array_exclude( perk_structs, revive_perk_structs );

        for ( i = 0; i < perk_structs.size; i++ )
        {
            random_perk_structs[i] = getstruct( perk_structs[i].target, "targetname" );
            random_perk_structs[i].script_int = perk_structs[i].script_int;
        }

        level.random_perk_structs = array_randomize( random_perk_structs );

        for ( i = 1; i < 9; i++ ) //9
        {
            level.random_perk_structs[i].targetname = "zm_perk_machine_override";
            level.random_perk_structs[i].model = level.nuked_perks[i].model;
            // Add debug log to track the perk being processed
            print("Processing perk: " + i + " with model: " + level.random_perk_structs[i].model);
            level.random_perk_structs[i].blocker_model = getent( level.random_perk_structs[i].target, "targetname" );
            level.random_perk_structs[i].script_noteworthy = level.nuked_perks[i].script_noteworthy;
            level.random_perk_structs[i].turn_on_notify = level.nuked_perks[i].turn_on_notify;

            if ( !isdefined( level.struct_class_names["targetname"]["zm_perk_machine_override"] ) )
            {
                level.struct_class_names["targetname"]["zm_perk_machine_override"] = [];
            }

            level.struct_class_names["targetname"]["zm_perk_machine_override"][level.struct_class_names["targetname"]["zm_perk_machine_override"].size] = level.random_perk_structs[i];
/#
            level.random_perk_structs[i] thread draw_debug_location();
#/
        }
    }
    else
    {
        level.override_perk_targetname = "zm_perk_machine_override";
        random_perk_structs = [];
        perk_structs = getstructarray( "zm_random_machine", "script_noteworthy" );

        for ( i = 0; i < perk_structs.size; i++ )
        {
            random_perk_structs[i] = getstruct( perk_structs[i].target, "targetname" );
            random_perk_structs[i].script_int = perk_structs[i].script_int;
        }

        level.random_perk_structs = array_randomize( random_perk_structs );

        for ( i = 0; i < 9; i++ ) //9
        {
            level.random_perk_structs[i].targetname = "zm_perk_machine_override";
            level.random_perk_structs[i].model = level.nuked_perks[i].model;
            // Add debug log to track the perk being processed
            print("Processing perk: " + i + " with model: " + level.random_perk_structs[i].model);
            level.random_perk_structs[i].blocker_model = getent( level.random_perk_structs[i].target, "targetname" );
            level.random_perk_structs[i].script_noteworthy = level.nuked_perks[i].script_noteworthy;
            level.random_perk_structs[i].turn_on_notify = level.nuked_perks[i].turn_on_notify;

            if ( !isdefined( level.struct_class_names["targetname"]["zm_perk_machine_override"] ) )
            {
                level.struct_class_names["targetname"]["zm_perk_machine_override"] = [];
            }

            level.struct_class_names["targetname"]["zm_perk_machine_override"][level.struct_class_names["targetname"]["zm_perk_machine_override"].size] = level.random_perk_structs[i];
/#
            level.random_perk_structs[i] thread draw_debug_location();
#/
        }
    }
}

bring_perk( machine, trigger, b_no_flight )
{
    players = get_players();
    is_doubletap = 0;
    is_sleight = 0;
    is_revive = 0;
    is_jugger = 0;
    is_marathon = 0;
    is_mulekick = 0;
    is_deadshot = 0;
    is_phd = 0;
    flag_waitopen( "perk_vehicle_bringing_in_perk" );

    //  ========================================================================
    //  v1.99.65 - b_no_flight: land where you stand, no quad, no queue.
    //
    //  User, 2026-08-19, after seeing ALL ON ROUND 1 work: *"if you could make
    //  it so that the siren blares once and everything drops all at one time
    //  instead of the machines dropping one after another it'd be better so you
    //  don't have to wait"*.
    //
    //  🛑 THE QUEUE IS NOT A CHOICE, IT IS THE VEHICLE. Every arrival rides
    //  level.perk_arrival_vehicle down a numbered path, and there is exactly one
    //  of it, so nine arrivals can only ever be nine trips. Dropping them
    //  together therefore means not using the quad at all.
    //
    //  🌟 WHAT REPLACES IT COSTS NOTHING AND KEEPS THE FALL. move_perk() already
    //  parked every machine 8000 units up and recorded original_pos/_angles, so
    //  the machine can simply be slid across to its landing x/y and then moved
    //  DOWN to the floor - a real drop from the sky, all nine at once, ending in
    //  the same landing block below: the same quake, the same gib, the same
    //  trigger_on, the same perk lights. Nothing about the landing is forked.
    //
    //  📝 The two arrival sounds move OUT of here for this path - the caller
    //  plays them once for the whole flight rather than nine times over.
    //  ========================================================================
    if ( isDefined( b_no_flight ) && b_no_flight )
    {
        //  Slide to the landing column first, then fall. The per-perk x/y offset
        //  below is applied to original_pos, so read it after that block - hence
        //  only the fall itself is deferred, via b_no_flight further down.
        machine setclientfield( "clientfield_perk_intro_fx", 1 );
    }
    else
    {
    playsoundatposition( "zmb_perks_incoming_quad_front", ( 0, 0, 0 ) );
    playsoundatposition( "zmb_perks_incoming_alarm", ( -2198, 486, 327 ) );
    machine setclientfield( "clientfield_perk_intro_fx", 1 );
    machine.fx = spawn( "script_model", machine.origin );
    machine.fx playloopsound( "zmb_perks_incoming_loop", 6 );
    machine.fx thread perk_incoming_sound();
    machine.fx.angles = machine.angles;
    machine.fx setmodel( "tag_origin" );
    machine.fx linkto( machine );
    machine linkto( level.perk_arrival_vehicle, "tag_origin", ( 0, 0, 0 ), ( 0, 0, 0 ) );
    start_node = getvehiclenode( "perk_arrival_path_" + machine.script_int, "targetname" );
/#
    level.perk_arrival_vehicle thread draw_debug_location();
#/
    level.perk_arrival_vehicle perk_follow_path( start_node );
    machine unlink();
    }
    offset = ( 0, 0, 0 );

    if ( issubstr( machine.targetname, "doubletap" ) )
    {
        forward_dir = anglestoforward( machine.original_angles + vectorscale( ( 0, -1, 0 ), 90.0 ) );
        offset = vectorscale( forward_dir * -1, 20 );
        is_doubletap = 1;
    }
    else if ( issubstr( machine.targetname, "sleight" ) )
    {
        forward_dir = anglestoforward( machine.original_angles + vectorscale( ( 0, -1, 0 ), 90.0 ) );
        offset = vectorscale( forward_dir * -1, 5 );
        is_sleight = 1;
    }
    else if ( issubstr( machine.targetname, "revive" ) )
    {
        forward_dir = anglestoforward( machine.original_angles + vectorscale( ( 0, -1, 0 ), 90.0 ) );
        offset = vectorscale( forward_dir * -1, 10 );
        trigger.blocker_model hide();
        is_revive = 1;
    }
    else if ( issubstr( machine.targetname, "jugger" ) )
    {
        forward_dir = anglestoforward( machine.original_angles + vectorscale( ( 0, -1, 0 ), 90.0 ) );
        offset = vectorscale( forward_dir * -1, 10 );
        is_jugger = 1;
    }
    else if ( issubstr( machine.targetname, "marathon" ) )
    {
        forward_dir = anglestoforward( machine.original_angles + vectorscale( ( 0, -1, 0 ), 90.0 ) );
        offset = vectorscale( forward_dir * -1, 5 );
        is_marathon = 1;
    }
    else if ( issubstr( machine.targetname, "mulekick" ) )
    {
        forward_dir = anglestoforward( machine.original_angles + vectorscale( ( 0, -1, 0 ), 90.0 ) );
        offset = vectorscale( forward_dir * -1, 20 );
        is_mulekick = 1;
    }
    else if ( issubstr( machine.targetname, "deadshot" ) )
    {
        forward_dir = anglestoforward( machine.original_angles + vectorscale( ( 0, -1, 0 ), 90.0 ) );
        offset = vectorscale( forward_dir * -1, 10 );
        is_deadshot = 1;
    }
    else if ( issubstr( machine.targetname, "phd" ) )
    {
        forward_dir = anglestoforward( machine.original_angles + vectorscale( ( 0, -1, 0 ), 90.0 ) );
        offset = vectorscale( forward_dir * -1, 20 );
        is_phd = 1;
    }
    // ========================================================================
    //  🛑 v2.8.2 - THE v2.7.3 PACK-A-PUNCH OFFSET IS REVERTED. It was built on
    //  a wrong mechanism and it caused a worse bug than the one it targeted.
    //
    //  User, 2026-08-29, standing at x 1442 y 622 z -57 yaw 215: the machine
    //  "has moved, clips into the fireplace/rubble, and shows no purchase
    //  prompt". That reference point looks straight at pad pf15_auto2899
    //  (1353.63, 584.12, -64), 96 units away - the pad PaP had landed on.
    //
    //  -- WHY THE OFFSET CANNOT WORK, MEASURED ----------------------------
    //  _zm_perks.gsc:2879-2901 spawns THREE things and all three sit at the
    //  pad origin:
    //      use_trigger  = spawn( "trigger_radius_use", pos.origin + (0,0,30), 0, 40, 70 )
    //      perk_machine = spawn( "script_model", pos.origin )
    //      collision    = spawn( "script_model", pos.origin, 1 )   <- zm_collision_perks1
    //  Only the MACHINE is ever moved afterwards. The use trigger and the
    //  zm_collision_perks1 clip stay on the pad origin for the whole match, so
    //  displacing the machine cannot free the volume the player has to stand
    //  in - it only walks the visible machine away from its own prompt. At pad
    //  2899 (yaw 195) the offset resolves to (+5.18, -19.32, 0), which is what
    //  put the machine in the rubble.
    //
    //  🌟 THE ACTUAL CAUSE, measured off the models themselves. The collision
    //  LOD bounds were read out of zm_nuked.ff with OpenAssetTools
    //  (xmodel "collLod": 3, glTF POSITION min/max, glTF y = game z):
    //      p6_anim_zm_buildable_pap   x -39.42 .. +39.42   ->  78.8 wide
    //      zombie_vending_jugg        x -14.70 .. +14.68   ->  29.4 wide
    //  Pack-a-Punch is 2.7x wider than a perk machine and it is solid. With a
    //  player half-width of ~15, the closest standing point beside PaP is ~54
    //  units from the pad origin and the front is ~42 - both OUTSIDE the
    //  40-unit use trigger. A perk machine needs only ~30, which is why every
    //  other machine works. PaP is reachable only from its back (~32), so it
    //  works wherever the back is open and fails wherever it is not: pad 2907
    //  backs onto rubble, pad 2899 onto the fireplace.
    //
    //  The fix therefore belongs on the TRIGGER, not the machine - see
    //  zmqol_perk_machine_spawn_init() at the bottom of this file, which is
    //  stock's own perk_machine_spawn_init with the Pack-a-Punch use trigger
    //  widened 40 -> 64. Stock and BO2-Reimagined both ship NO PaP offset here
    //  (Reimagined scripts\zm\replaced\zm_nuked_perks.gsc:207-235 has only
    //  doubletap/sleight/revive/jugger), so removing the case restores the
    //  working precedent rather than inventing a new rule.
    // ========================================================================

    if ( !is_revive )
    {
        trigger.blocker_model delete();
    }


    machine.original_pos = machine.original_pos + ( offset[0], offset[1], 0 );

    if ( isDefined( b_no_flight ) && b_no_flight )
    {
        //  Move across to the landing column at the parked height, then fall
        //  into it. accel/decel are stock's own move_perk shape, so the arrival
        //  reads as a drop rather than a teleport.
        machine.angles = machine.original_angles;
        machine.origin = ( machine.original_pos[0], machine.original_pos[1], machine.origin[2] );
        machine moveto( machine.original_pos, 3.0, 0.25, 0.75 );
        //  🛑 v1.99.66 - A FIXED WAIT, NOT waittill( "movedone" ).
        //  One of the nine machines did not land on the first in-game test while
        //  the log said all nine threads started, so a thread stopped somewhere
        //  before the blocker crate was deleted - and this waittill is the only
        //  place in the no-flight path that can wait forever. move_perk() raised
        //  every machine with a 5.0s moveto at map start, so if the blackscreen
        //  clears quickly that raise can still be running when this second moveto
        //  begins, and a "movedone" belonging to the first move is easy to miss
        //  or to consume out of order. The move takes exactly 3.0 seconds, so
        //  waiting 3.05 is the same wait with no way to hang.
        wait 3.05;
    }

    machine.origin = machine.original_pos;
    machine.angles = machine.original_angles;

    if ( is_revive )
    {
        level.quick_revive_final_pos = machine.origin;
        level.quick_revive_final_angles = machine.angles;
    }

    //  🛑 machine.fx only exists on the quad path - guard every use of it.
    if ( isDefined( machine.fx ) )
        machine.fx stoploopsound( 0.5 );

    machine setclientfield( "clientfield_perk_intro_fx", 0 );
    playsoundatposition( "zmb_perks_incoming_land", machine.origin );
    trigger trigger_on();
    machine thread bring_perk_landing_damage();

    if ( isDefined( machine.fx ) )
    {
        machine.fx unlink();
        machine.fx delete();
    }

    //  v1.99.66 - names every machine that actually completes a landing, so a
    //  missing one can be identified from the log instead of from a screenshot.
    println( "[zm_qol] nuketown machine LANDED: " + machine.targetname + " at " + machine.origin );
    //  v1.99.68 - landed: Vulture Aid may now mark it. See zmqol_vulture_marker_scan().
    machine.zmqol_not_ready = undefined;
    machine notify( machine.turn_on_notify );
    level notify( machine.turn_on_notify );
    machine vibrate( vectorscale( ( 0, -1, 0 ), 100.0 ), 0.3, 0.4, 3 );
    machine playsound( "zmb_perks_power_on" );
    machine maps\mp\zombies\_zm_perks::perk_fx( undefined, 1 );

    if ( is_revive )
    {
        level.revive_machine_spawned = 1;
        machine thread maps\mp\zombies\_zm_perks::perk_fx( "revive_light" );
    }
    else if ( is_jugger )
    {
        machine thread maps\mp\zombies\_zm_perks::perk_fx( "jugger_light" );
    }
    else if ( is_doubletap )
    {
        machine thread maps\mp\zombies\_zm_perks::perk_fx( "doubletap_light" );
    }
    else if ( is_sleight )
    {
        machine thread maps\mp\zombies\_zm_perks::perk_fx( "sleight_light" );
    }
    else if ( is_marathon )
    {
        machine thread maps\mp\zombies\_zm_perks::perk_fx( "marathon_light" );
    }
    else if ( is_mulekick )
    {
        machine thread maps\mp\zombies\_zm_perks::perk_fx( "additionalprimaryweapon_light" );
    }
    else if ( is_deadshot )
    {
        machine thread maps\mp\zombies\_zm_perks::perk_fx( "deadshot_light" );
    }
    else if ( is_phd )
    {
        machine thread perk_fx( "divetonuke_light" );
    }
}

perks_from_the_sky()
{
    level thread turn_perks_on();
    top_height = 8000;
    machines = [];
    machine_triggers = [];
    machines[0] = getent( "vending_revive", "targetname" );

    if ( !isdefined( machines[0] ) )
    {
        return;
    }

    machine_triggers[0] = getent( "vending_revive", "target" );
    move_perk( machines[0], top_height, 5.0, 0.001 );
    //  v1.99.68 - parked in the sky. _zm_perk_vulture::zmqol_vulture_marker_scan()
    //  skips a machine carrying this flag, so Vulture Aid does not draw an icon in
    //  the clouds; bring_perk() clears it as the machine lands.
    machines[0].zmqol_not_ready = 1;
    machine_triggers[0] trigger_off();
    machines[1] = getent( "vending_doubletap", "targetname" );
    machine_triggers[1] = getent( "vending_doubletap", "target" );
    move_perk( machines[1], top_height, 5.0, 0.001 );
    //  v1.99.68 - parked in the sky. _zm_perk_vulture::zmqol_vulture_marker_scan()
    //  skips a machine carrying this flag, so Vulture Aid does not draw an icon in
    //  the clouds; bring_perk() clears it as the machine lands.
    machines[1].zmqol_not_ready = 1;
    machine_triggers[1] trigger_off();
    machines[2] = getent( "vending_sleight", "targetname" );
    machine_triggers[2] = getent( "vending_sleight", "target" );
    move_perk( machines[2], top_height, 5.0, 0.001 );
    //  v1.99.68 - parked in the sky. _zm_perk_vulture::zmqol_vulture_marker_scan()
    //  skips a machine carrying this flag, so Vulture Aid does not draw an icon in
    //  the clouds; bring_perk() clears it as the machine lands.
    machines[2].zmqol_not_ready = 1;
    machine_triggers[2] trigger_off();
    machines[3] = getent( "vending_jugg", "targetname" );
    machine_triggers[3] = getent( "vending_jugg", "target" );
    move_perk( machines[3], top_height, 5.0, 0.001 );
    //  v1.99.68 - parked in the sky. _zm_perk_vulture::zmqol_vulture_marker_scan()
    //  skips a machine carrying this flag, so Vulture Aid does not draw an icon in
    //  the clouds; bring_perk() clears it as the machine lands.
    machines[3].zmqol_not_ready = 1;
    machine_triggers[3] trigger_off();
    machine_triggers[4] = getent( "specialty_weapupgrade", "script_noteworthy" );
    machines[4] = getent( machine_triggers[4].target, "targetname" );
    move_perk( machines[4], top_height, 5.0, 0.001 );
    //  v1.99.68 - parked in the sky. _zm_perk_vulture::zmqol_vulture_marker_scan()
    //  skips a machine carrying this flag, so Vulture Aid does not draw an icon in
    //  the clouds; bring_perk() clears it as the machine lands.
    machines[4].zmqol_not_ready = 1;
    machine_triggers[4] trigger_off();
    // Added
    machines[5] = getent( "vending_marathon", "targetname" );
    machine_triggers[5] = getent( "vending_marathon", "target" );
    move_perk( machines[5], top_height, 5.0, 0.001 );
    //  v1.99.68 - parked in the sky. _zm_perk_vulture::zmqol_vulture_marker_scan()
    //  skips a machine carrying this flag, so Vulture Aid does not draw an icon in
    //  the clouds; bring_perk() clears it as the machine lands.
    machines[5].zmqol_not_ready = 1;
    machine_triggers[5] trigger_off();
    machines[6] = getent( "vending_additionalprimaryweapon", "targetname" );
    machine_triggers[6] = getent( "vending_additionalprimaryweapon", "target" );
    move_perk( machines[6], top_height, 5.0, 0.001 );
    //  v1.99.68 - parked in the sky. _zm_perk_vulture::zmqol_vulture_marker_scan()
    //  skips a machine carrying this flag, so Vulture Aid does not draw an icon in
    //  the clouds; bring_perk() clears it as the machine lands.
    machines[6].zmqol_not_ready = 1;
    machine_triggers[6] trigger_off();
    machines[7] = getent( "vending_deadshot_model", "targetname" );
    machine_triggers[7] = getent( "vending_deadshot", "target" );
    move_perk( machines[7], top_height, 5.0, 0.001 );
    //  v1.99.68 - parked in the sky. _zm_perk_vulture::zmqol_vulture_marker_scan()
    //  skips a machine carrying this flag, so Vulture Aid does not draw an icon in
    //  the clouds; bring_perk() clears it as the machine lands.
    machines[7].zmqol_not_ready = 1;
    machine_triggers[7] trigger_off();
    machines[8] = getent( "vending_divetonuke", "targetname" );
    machine_triggers[8] = getent( "vending_divetonuke", "target" );
    move_perk( machines[8], top_height, 5.0, 0.001 );
    //  v1.99.68 - parked in the sky. _zm_perk_vulture::zmqol_vulture_marker_scan()
    //  skips a machine carrying this flag, so Vulture Aid does not draw an icon in
    //  the clouds; bring_perk() clears it as the machine lands.
    machines[8].zmqol_not_ready = 1;
    machine_triggers[8] trigger_off();
    //  ========================================================================
    //  v1.99.63 - the LEVEL arrays become the one list from here on.
    //
    //  Nothing below reads the two locals again, deliberately: that way the
    //  behaviour never depends on whether a GSC array assignment aliases or
    //  copies, which is not something this project has measured.
    //  zmqol_nuked_bring_machine() owns every removal from now on.
    //  ========================================================================
    level.zmqol_nuked_machines = machines;
    level.zmqol_nuked_machine_triggers = machine_triggers;
    level.zmqol_nuked_dropping = 0;

    flag_wait( "initial_blackscreen_passed" );

    //  MACHINE DROPS = ALL ON ROUND 1 (pre-game lobby, Nuketown survival only).
    //  Read HERE rather than at init, so the lobby's write has certainly landed.
    //
    //  🛑 IT GOES BEFORE THE SOLO QUICK REVIVE FLIGHT, DELIBERATELY. That flight
    //  is one full quad trip; leaving it in front would have kept the wait the
    //  user asked to remove. Quick Revive simply comes down with everything else.
    if ( getdvarintdefault( "nuked_all_machines", 0 ) )
    {
        //  v1.99.66 - 5.0, not 3.0. move_perk() lifts every machine with a 5.0s
        //  moveto that starts during map load, and a second moveto issued while
        //  the first is still running is the likeliest reason one machine failed
        //  to land on the first test. Waiting 5s after the blackscreen clears
        //  puts the lift certainly behind us.
        wait 5.0;
        zmqol_nuked_drop_all_at_once();
        return;
    }

    wait( randomfloatrange( 5.0, 15.0 ) );
    players = get_players();

    if ( players.size == 1 )
    {
        wait 4.0;
        //  Index 0 is Quick Revive and solo gets it first. Stock's rule, kept.
        zmqol_nuked_bring_machine( 0 );
    }
    wait_for_round_range( 3, 5 );
    wait( randomintrange( 30, 60 ) );
    zmqol_nuked_bring_machine( -1 );
    wait_for_round_range( 6, 8 );
    wait( randomintrange( 30, 60 ) );
    zmqol_nuked_bring_machine( -1 );
    wait_for_round_range( 9, 11 );
    wait( randomintrange( 60, 120 ) );
    zmqol_nuked_bring_machine( -1 );
    wait_for_round_range( 12, 14 );
    wait( randomintrange( 60, 120 ) );
    zmqol_nuked_bring_machine( -1 );
    wait_for_round_range( 15, 17 );
    wait( randomintrange( 60, 120 ) );
    zmqol_nuked_bring_machine( -1 );
    wait_for_round_range( 18, 20 );
    wait( randomintrange( 60, 120 ) );
    zmqol_nuked_bring_machine( -1 );
    wait_for_round_range( 21, 23 );
    wait( randomintrange( 60, 120 ) );
    zmqol_nuked_bring_machine( -1 );
    wait_for_round_range( 24, 26 );
    wait( randomintrange( 60, 120 ) );
    zmqol_nuked_bring_machine( -1 );
    wait_for_round_range( 24, 26 );
    wait( randomintrange( 60, 120 ) );
    zmqol_nuked_bring_machine( -1 );
}

init()
{
    added_weapons();

    //  v1.99.63 - the ".machines" / `machines 1` dev command. The pointer is
    //  installed HERE, in the map's own script, for the same reason the boss
    //  spawners are: the root script may not name anything map-specific, and it
    //  dispatches through level.zmqol_drop_all_machines_func instead.
    level.zmqol_drop_all_machines_func = ::zmqol_nuked_drop_all_machines;

    //  Seeded only when unset, so the pre-game lobby's MACHINE DROPS choice
    //  survives. Read in perks_from_the_sky().
    if ( getdvar( "nuked_all_machines" ) == "" )
        setdvar( "nuked_all_machines", "0" );
}

added_weapons()
{
    if (level.script == "zm_nuked")
	{
        level.weapons_using_ammo_sharing = 1;

        include_weapon( "uzi_zm" );
        include_weapon( "uzi_upgraded_zm", 0 );
        add_zombie_weapon( "uzi_zm", "uzi_upgraded_zm", &"ZOMBIE_WEAPON_UZI", 1500, "wpck_smg", "", undefined );

        include_weapon( "thompson_zm" );
        include_weapon( "thompson_upgraded_zm", 0 );
        add_zombie_weapon( "thompson_zm", "thompson_upgraded_zm", &"ZMWEAPON_THOMPSON_WALLBUY", 1500, "wpck_smg", "", 800 );

        include_weapon( "ak47_zm" );
        include_weapon( "ak47_upgraded_zm", 0 );
        add_zombie_weapon( "ak47_zm", "ak47_upgraded_zm", &"ZOMBIE_WEAPON_AK47", 500, "wpck_mg", "", undefined, 1 );

        include_weapon( "mp40_stalker_zm" );
        include_weapon( "mp40_stalker_upgraded_zm", 0 );
        add_zombie_weapon( "mp40_stalker_zm", "mp40_stalker_upgraded_zm", &"ZOMBIE_WEAPON_MP40", 1300, "wpck_smg", "", undefined, 1 );

        include_weapon( "scar_zm" );
        include_weapon( "scar_upgraded_zm", 0 );
        add_zombie_weapon( "scar_zm", "scar_upgraded_zm", &"ZOMBIE_WEAPON_SCAR", 50, "wpck_rifle", "", undefined, 1 );

        include_weapon( "mg08_zm" );
        include_weapon( "mg08_upgraded_zm", 0 );
        add_zombie_weapon( "mg08_zm", "mg08_upgraded_zm", &"ZOMBIE_WEAPON_MG08", 50, "wpck_mg", "", undefined, 1 );

        include_weapon( "minigun_alcatraz_zm" );
        include_weapon( "minigun_alcatraz_upgraded_zm", 0 );
        add_zombie_weapon( "minigun_alcatraz_zm", "minigun_alcatraz_upgraded_zm", &"ZOMBIE_WEAPON_RPD", 50, "wpck_mg", "", undefined, 1 );
        add_limited_weapon( "minigun_alcatraz_zm", 1 );
        add_limited_weapon( "minigun_alcatraz_upgraded_zm", 1 );

        include_weapon( "evoskorpion_zm" );
        include_weapon( "evoskorpion_upgraded_zm", 0 );
        add_zombie_weapon( "evoskorpion_zm", "evoskorpion_upgraded_zm", &"ZOMBIE_WEAPON_EVOSKORPION", 50, "wpck_smg", "", undefined, 1 );

        include_weapon( "ksg_zm" );
        include_weapon( "ksg_upgraded_zm", 0 );
        add_zombie_weapon( "ksg_zm", "ksg_upgraded_zm", &"ZOMBIE_WEAPON_KSG", 1100, "wpck_shotgun", "", undefined, 1 );

        include_weapon( "pdw57_zm" );
        include_weapon( "pdw57_upgraded_zm", 0 );
        add_zombie_weapon( "pdw57_zm", "pdw57_upgraded_zm", &"ZOMBIE_WEAPON_PDW57", 1000, "smg", "", undefined );

        include_weapon( "mp44_zm" );
        include_weapon( "mp44_upgraded_zm", 0 );
        add_zombie_weapon( "mp44_zm", "mp44_upgraded_zm", &"ZMWEAPON_MP44_WALLBUY", 1400, "wpck_rifle", "", undefined, 1 );

        include_weapon( "ballista_zm" );
        include_weapon( "ballista_upgraded_zm", 0 );
        add_zombie_weapon( "ballista_zm", "ballista_upgraded_zm", &"ZMWEAPON_BALLISTA_WALLBUY", 500, "wpck_snipe", "", undefined, 1 );

        include_weapon( "rnma_zm" );
        include_weapon( "rnma_upgraded_zm", 0 );
        add_zombie_weapon( "rnma_zm", "rnma_upgraded_zm", &"ZOMBIE_WEAPON_RNMA", 50, "pickup_six_shooter", "", undefined, 1 );

        include_weapon( "an94_zm" );
        include_weapon( "an94_upgraded_zm", 0 );
        add_zombie_weapon( "an94_zm", "an94_upgraded_zm", &"ZOMBIE_WEAPON_AN94", 1200, "", "", undefined );

        include_weapon( "svu_zm" );
        include_weapon( "svu_upgraded_zm", 0 );
        add_zombie_weapon( "svu_zm", "svu_upgraded_zm", &"ZOMBIE_WEAPON_SVU", 1000, "wpck_svuas", "", undefined, 1 );

        include_weapon( "c96_zm" );
        include_weapon( "c96_upgraded_zm", 0 );
        add_zombie_weapon( "c96_zm", "c96_upgraded_zm", &"ZOMBIE_WEAPON_C96", 50, "wpck_pistol", "", undefined, 1 );

        include_weapon( "beretta93r_extclip_zm" );
        include_weapon( "beretta93r_extclip_upgraded_zm", 0 );
        add_zombie_weapon( "beretta93r_extclip_zm", "beretta93r_extclip_upgraded_zm", &"ZOMBIE_WEAPON_BERETTA93r", 1000, "", "", undefined, 1 );
        add_shared_ammo_weapon( "beretta93r_extclip_zm", "beretta93r_zm" );

        include_weapon( "ak74u_extclip_zm" );
        include_weapon( "ak74u_extclip_upgraded_zm", 0 );
        add_zombie_weapon( "ak74u_extclip_zm", "ak74u_extclip_upgraded_zm", &"ZOMBIE_WEAPON_AK74U", 1200, "smg", "", undefined, 1 );
        add_shared_ammo_weapon( "ak74u_extclip_zm", "ak74u_zm" );
    }
}
// ============================================================================
//  MACHINE DROPS  -  the lobby option and the ".machines" dev command
//                                                                   (v1.99.63)
// ----------------------------------------------------------------------------
//  User, 2026-08-19: *"add an option here in the pre game menu for nuketown
//  survival ONLY, the option lets you pick whether all machines drop on round
//  1, or if they retain their stock behaviour... also add this as a console
//  command so you can make all the machines drop mid-game in nuketown zombies
//  if you wanted to, regardless of what option was set in the pre-game lobby
//  menu, for dev testing purposes mainly."*
//
//  🌟 NOTHING ABOUT THE DROP ITSELF CHANGES. bring_perk() is untouched, so the
//  quad flies its path, the alarm and incoming loop play, the crate blocker is
//  deleted, the landing quake and the zombie gib still happen, the trigger is
//  turned on and the perk lights come up. All this does is decide WHEN the
//  existing sequence is asked to run, and how many times.
//
//  🛑 WHY A LEVEL-OWNED LIST AND A MUTEX, RATHER THAN THE LOCAL ARRAYS.
//  Two things can now ask for a drop: the schedule inside perks_from_the_sky()
//  and a ".machines" thread started from chat or the console. They must not
//  overlap, because a drop is a single shared vehicle - level.perk_arrival_vehicle
//  - and two bring_perk() calls entering in the same frame would both clear
//  flag_waitopen( "perk_vehicle_bringing_in_perk" ) before either set it, and
//  fly two machines on one path.
//
//  🌟 THE MUTEX IS SOUND BECAUSE GSC IS COOPERATIVE. Between the `while` test
//  below exiting and `level.zmqol_nuked_dropping = 1` there is no wait, so no
//  other thread can run in between. The same reasoning is why the entry is
//  removed from the list BEFORE the flight rather than after: no second caller
//  can ever pick a machine that is already in the air.
//
//  📝 The command works whatever the lobby row said, on purpose - that was the
//  request. With MACHINE DROPS on ALL ON ROUND 1 there is simply nothing left
//  for it to do, and it says so.
// ============================================================================
zmqol_nuked_bring_machine( n_index )
{
    if ( !isdefined( level.zmqol_nuked_machines ) )
        return 0;

    //  One drop at a time - see the note above.
    while ( isdefined( level.zmqol_nuked_dropping ) && level.zmqol_nuked_dropping )
        wait 0.05;

    if ( level.zmqol_nuked_machines.size <= 0 )
        return 0;

    if ( !isdefined( n_index ) || n_index < 0 || n_index >= level.zmqol_nuked_machines.size )
        n_index = randomintrange( 0, level.zmqol_nuked_machines.size );

    level.zmqol_nuked_dropping = 1;

    machine = level.zmqol_nuked_machines[ n_index ];
    trigger = level.zmqol_nuked_machine_triggers[ n_index ];

    a_machines = [];
    a_triggers = [];

    for ( i = 0; i < level.zmqol_nuked_machines.size; i++ )
    {
        if ( i == n_index )
            continue;

        a_machines[ a_machines.size ] = level.zmqol_nuked_machines[i];
        a_triggers[ a_triggers.size ] = level.zmqol_nuked_machine_triggers[i];
    }

    level.zmqol_nuked_machines = a_machines;
    level.zmqol_nuked_machine_triggers = a_triggers;

    if ( !isdefined( machine ) || !isdefined( trigger ) )
    {
        //  A machine this map never placed. Dropped from the list above, so the
        //  schedule simply moves on instead of stalling on it.
        level.zmqol_nuked_dropping = 0;
        return 0;
    }

    bring_perk( machine, trigger );
    level.zmqol_nuked_dropping = 0;
    return 1;
}

//  Installed on level in init() and called from the root script's ".machines"
//  branch. Returns how many machines were still in the air, or 0.
zmqol_nuked_drop_all_machines()
{
    if ( !isdefined( level.zmqol_nuked_machines ) )
        return 0;

    n_left = level.zmqol_nuked_machines.size;

    if ( n_left <= 0 )
        return 0;

    level thread zmqol_nuked_drop_all_thread();
    return n_left;
}
zmqol_nuked_drop_all_thread()
{
    level endon( "end_game" );
    zmqol_nuked_drop_all_at_once();
}

// ============================================================================
//  zmqol_nuked_drop_all_at_once  -  one siren, everything lands together
//                                                                   (v1.99.65)
// ----------------------------------------------------------------------------
//  Drives both the ALL ON ROUND 1 lobby option and the ".machines" command.
//
//  🛑 THE MUTEX IS TAKEN FOR THE WHOLE OPERATION, not per machine. If a
//  scheduled quad trip is already in the air this waits for it, and while this
//  runs the schedule cannot start one - otherwise a machine could be linked to
//  the vehicle and moveto'd by two owners at once.
//
//  🌟 THE MACHINES ARE PULLED OFF THE LIST BEFORE ANY OF THEM MOVES. That is
//  what makes it safe to hand nine of them to nine threads: the list is empty
//  before the first thread runs, so nothing else can pick one up.
//
//  📝 The arrival sounds are played ONCE, here, rather than nine times inside
//  bring_perk - that is the "siren blares once" the user asked for. The landing
//  sound stays per machine, because nine machines hitting the ground is nine
//  impacts and they all land in the same second anyway.
// ============================================================================
zmqol_nuked_drop_all_at_once()
{
    level endon( "end_game" );

    if ( !isdefined( level.zmqol_nuked_machines ) )
        return;

    while ( isdefined( level.zmqol_nuked_dropping ) && level.zmqol_nuked_dropping )
        wait 0.05;

    if ( level.zmqol_nuked_machines.size <= 0 )
        return;

    level.zmqol_nuked_dropping = 1;

    a_machines = level.zmqol_nuked_machines;
    a_triggers = level.zmqol_nuked_machine_triggers;

    level.zmqol_nuked_machines = [];
    level.zmqol_nuked_machine_triggers = [];

    //  The siren, once, for the whole flight.
    playsoundatposition( "zmb_perks_incoming_quad_front", ( 0, 0, 0 ) );
    playsoundatposition( "zmb_perks_incoming_alarm", ( -2198, 486, 327 ) );
    wait 2.0;

    n_sent = 0;

    for ( i = 0; i < a_machines.size; i++ )
    {
        if ( !isdefined( a_machines[i] ) || !isdefined( a_triggers[i] ) )
            continue;

        println( "[zm_qol] nuketown machine SENT: " + a_machines[i].targetname );
        level thread bring_perk( a_machines[i], a_triggers[i], 1 );
        n_sent++;

        //  🛑 A 0.05s gap between starts, on purpose. Nine machines entering the
        //  landing block in ONE frame is nine setclientfields, nine sounds and
        //  eighteen exploders down the reliable command ring, which holds 128 -
        //  see ERROR_CATALOGUE §7b. Spread over 0.45s the peak is a ninth of that
        //  and the fall is 3s, so they still land together to the eye.
        wait 0.05;
    }


    println( "[zm_qol] nuketown: dropped " + n_sent + " machine(s) together" );

    //  The fall is 3.0s inside bring_perk; hold the mutex until they are all
    //  down so a scheduled trip cannot overlap the tail of it.
    wait 4.0;
    level.zmqol_nuked_dropping = 0;
}

// ============================================================================
//  zmqol_perk_machine_spawn_init  -  the Pack-a-Punch use trigger is too small
//                                    for the Pack-a-Punch machine     (v2.8.2)
//
//  Stock's maps\mp\zombies\_zm_perks::perk_machine_spawn_init(), verbatim,
//  with exactly ONE change: the use trigger spawned for specialty_weapupgrade
//  gets radius 64 instead of 40. Everything else - the switch, the bump
//  trigger, the zm_collision_perks1 clip, the pack_flag, the _custom_perks
//  kvp callback - is untouched.
//
//  🌟 WHY 64, MEASURED. See the long note in bring_perk() above for the full
//  derivation. Short version, from the collision LODs dumped out of zm_nuked.ff
//  with OpenAssetTools:
//
//      model                       collision half-width   closest stand   trigger
//      zombie_vending_jugg              14.7                  ~30          40 ok
//      p6_anim_zm_buildable_pap         39.4                  ~54-61       40 NO
//
//  A player bounding box is 30x30, so add ~15 flat / ~21 at the corner to the
//  machine half-width to get the nearest reachable point. Every perk machine
//  clears 40 comfortably. Pack-a-Punch is 2.7x wider and clears it on NO side
//  except its back (~32), so on Nuketown it works only where the back happens
//  to be open - and fails silently everywhere else. 64 covers the worst case
//  (39.4 + 21.2 = 60.6) with margin while reaching only ~25 units past the
//  side of the machine.
//
//  🛑 RESIDUAL RISK, stated rather than hidden: a radius trigger has no line of
//  sight, so behind the machine the volume now reaches ~47 units past the model
//  instead of ~23. Against a thin wall a player in the next room could get the
//  prompt. That is a convenience, not a break, and it is the price of the
//  machine being usable at all. If it shows up in play the alternative is to
//  move the trigger toward the open side per pad, which needs ten measurements.
//
//  🛑 SCOPE: this replaceFunc lives in the Nuketown map script only, so no other
//  map's perk machines are touched. Nuketown is the only map where the machines
//  are placed by random drop rather than by the level designer, which is why it
//  is the only map where PaP can land somewhere with no open back.
//
//  📝 Cross-checked against two independent copies of the stock body: the
//  starter kit dump (Core\maps\mp\zombies\_zm_perks.gsc:2832-3080) and
//  BO2-Reimagined's hand-maintained scripts\zm\replaced\_zm_perks.gsc:7 - they
//  agree line for line except for Reimagined's is_encounter()/grief gametype
//  override, which is NOT carried over here.
// ============================================================================
zmqol_perk_machine_spawn_init()
{
    match_string = "";
    location = level.scr_zm_map_start_location;

    if ( ( location == "default" || location == "" ) && isdefined( level.default_start_location ) )
        location = level.default_start_location;

    match_string = level.scr_zm_ui_gametype + "_perks_" + location;
    pos = [];

    if ( isdefined( level.override_perk_targetname ) )
        structs = getstructarray( level.override_perk_targetname, "targetname" );
    else
        structs = getstructarray( "zm_perk_machine", "targetname" );

    foreach ( struct in structs )
    {
        if ( isdefined( struct.script_string ) )
        {
            tokens = strtok( struct.script_string, " " );

            foreach ( token in tokens )
            {
                if ( token == match_string )
                    pos[pos.size] = struct;
            }

            continue;
        }

        pos[pos.size] = struct;
    }

    if ( !isdefined( pos ) || pos.size == 0 )
        return;

    precachemodel( "zm_collision_perks1" );

    for ( i = 0; i < pos.size; i++ )
    {
        perk = pos[i].script_noteworthy;

        if ( isdefined( perk ) && isdefined( pos[i].model ) )
        {
            //  ---- THE ONE CHANGE FROM STOCK ---------------------------------
            n_use_radius = 40;

            if ( perk == "specialty_weapupgrade" )
                n_use_radius = 64;
            //  ----------------------------------------------------------------

            use_trigger = spawn( "trigger_radius_use", pos[i].origin + vectorscale( ( 0, 0, 1 ), 30.0 ), 0, n_use_radius, 70 );
            use_trigger.targetname = "zombie_vending";
            use_trigger.script_noteworthy = perk;
            use_trigger triggerignoreteam();
            perk_machine = spawn( "script_model", pos[i].origin );
            perk_machine.angles = pos[i].angles;
            perk_machine setmodel( pos[i].model );

            if ( isdefined( level._no_vending_machine_bump_trigs ) && level._no_vending_machine_bump_trigs )
                bump_trigger = undefined;
            else
            {
                bump_trigger = spawn( "trigger_radius", pos[i].origin, 0, 35, 64 );
                bump_trigger.script_activated = 1;
                bump_trigger.script_sound = "zmb_perks_bump_bottle";
                bump_trigger.targetname = "audio_bump_trigger";

                if ( perk != "specialty_weapupgrade" )
                    bump_trigger thread thread_bump_trigger();
            }

            collision = spawn( "script_model", pos[i].origin, 1 );
            collision.angles = pos[i].angles;
            collision setmodel( "zm_collision_perks1" );
            collision.script_noteworthy = "clip";
            collision disconnectpaths();
            use_trigger.clip = collision;
            use_trigger.machine = perk_machine;
            use_trigger.bump = bump_trigger;

            if ( isdefined( pos[i].blocker_model ) )
                use_trigger.blocker_model = pos[i].blocker_model;

            if ( isdefined( pos[i].script_int ) )
                perk_machine.script_int = pos[i].script_int;

            if ( isdefined( pos[i].turn_on_notify ) )
                perk_machine.turn_on_notify = pos[i].turn_on_notify;
            switch ( perk )
            {
                case "specialty_quickrevive":
                case "specialty_quickrevive_upgrade":
                    use_trigger.script_sound = "mus_perks_revive_jingle";
                    use_trigger.script_string = "revive_perk";
                    use_trigger.script_label = "mus_perks_revive_sting";
                    use_trigger.target = "vending_revive";
                    perk_machine.script_string = "revive_perk";
                    perk_machine.targetname = "vending_revive";

                    if ( isdefined( bump_trigger ) )
                        bump_trigger.script_string = "revive_perk";

                    break;
                case "specialty_fastreload":
                case "specialty_fastreload_upgrade":
                    use_trigger.script_sound = "mus_perks_speed_jingle";
                    use_trigger.script_string = "speedcola_perk";
                    use_trigger.script_label = "mus_perks_speed_sting";
                    use_trigger.target = "vending_sleight";
                    perk_machine.script_string = "speedcola_perk";
                    perk_machine.targetname = "vending_sleight";

                    if ( isdefined( bump_trigger ) )
                        bump_trigger.script_string = "speedcola_perk";

                    break;
                case "specialty_longersprint":
                case "specialty_longersprint_upgrade":
                    use_trigger.script_sound = "mus_perks_stamin_jingle";
                    use_trigger.script_string = "marathon_perk";
                    use_trigger.script_label = "mus_perks_stamin_sting";
                    use_trigger.target = "vending_marathon";
                    perk_machine.script_string = "marathon_perk";
                    perk_machine.targetname = "vending_marathon";

                    if ( isdefined( bump_trigger ) )
                        bump_trigger.script_string = "marathon_perk";

                    break;
                case "specialty_armorvest":
                case "specialty_armorvest_upgrade":
                    use_trigger.script_sound = "mus_perks_jugganog_jingle";
                    use_trigger.script_string = "jugg_perk";
                    use_trigger.script_label = "mus_perks_jugganog_sting";
                    use_trigger.longjinglewait = 1;
                    use_trigger.target = "vending_jugg";
                    perk_machine.script_string = "jugg_perk";
                    perk_machine.targetname = "vending_jugg";

                    if ( isdefined( bump_trigger ) )
                        bump_trigger.script_string = "jugg_perk";

                    break;
                case "specialty_scavenger":
                case "specialty_scavenger_upgrade":
                    use_trigger.script_sound = "mus_perks_tombstone_jingle";
                    use_trigger.script_string = "tombstone_perk";
                    use_trigger.script_label = "mus_perks_tombstone_sting";
                    use_trigger.target = "vending_tombstone";
                    perk_machine.script_string = "tombstone_perk";
                    perk_machine.targetname = "vending_tombstone";

                    if ( isdefined( bump_trigger ) )
                        bump_trigger.script_string = "tombstone_perk";

                    break;
                case "specialty_rof":
                case "specialty_rof_upgrade":
                    use_trigger.script_sound = "mus_perks_doubletap_jingle";
                    use_trigger.script_string = "tap_perk";
                    use_trigger.script_label = "mus_perks_doubletap_sting";
                    use_trigger.target = "vending_doubletap";
                    perk_machine.script_string = "tap_perk";
                    perk_machine.targetname = "vending_doubletap";

                    if ( isdefined( bump_trigger ) )
                        bump_trigger.script_string = "tap_perk";

                    break;
                case "specialty_finalstand":
                case "specialty_finalstand_upgrade":
                    use_trigger.script_sound = "mus_perks_whoswho_jingle";
                    use_trigger.script_string = "tap_perk";
                    use_trigger.script_label = "mus_perks_whoswho_sting";
                    use_trigger.target = "vending_chugabud";
                    perk_machine.script_string = "tap_perk";
                    perk_machine.targetname = "vending_chugabud";

                    if ( isdefined( bump_trigger ) )
                        bump_trigger.script_string = "tap_perk";

                    break;
                case "specialty_additionalprimaryweapon":
                case "specialty_additionalprimaryweapon_upgrade":
                    use_trigger.script_sound = "mus_perks_mulekick_jingle";
                    use_trigger.script_string = "tap_perk";
                    use_trigger.script_label = "mus_perks_mulekick_sting";
                    use_trigger.target = "vending_additionalprimaryweapon";
                    perk_machine.script_string = "tap_perk";
                    perk_machine.targetname = "vending_additionalprimaryweapon";

                    if ( isdefined( bump_trigger ) )
                        bump_trigger.script_string = "tap_perk";

                    break;
                case "specialty_weapupgrade":
                    use_trigger.target = "vending_packapunch";
                    use_trigger.script_sound = "mus_perks_packa_jingle";
                    use_trigger.script_label = "mus_perks_packa_sting";
                    use_trigger.longjinglewait = 1;
                    perk_machine.targetname = "vending_packapunch";
                    flag_pos = getstruct( pos[i].target, "targetname" );

                    if ( isdefined( flag_pos ) )
                    {
                        perk_machine_flag = spawn( "script_model", flag_pos.origin );
                        perk_machine_flag.angles = flag_pos.angles;
                        perk_machine_flag setmodel( flag_pos.model );
                        perk_machine_flag.targetname = "pack_flag";
                        perk_machine.target = "pack_flag";
                    }

                    if ( isdefined( bump_trigger ) )
                        bump_trigger.script_string = "perks_rattle";

                    break;
                case "specialty_deadshot":
                case "specialty_deadshot_upgrade":
                    use_trigger.script_sound = "mus_perks_deadshot_jingle";
                    use_trigger.script_string = "deadshot_perk";
                    use_trigger.script_label = "mus_perks_deadshot_sting";
                    use_trigger.target = "vending_deadshot";
                    perk_machine.script_string = "deadshot_vending";
                    perk_machine.targetname = "vending_deadshot_model";

                    if ( isdefined( bump_trigger ) )
                        bump_trigger.script_string = "deadshot_vending";

                    break;
                default:
                    use_trigger.script_sound = "mus_perks_speed_jingle";
                    use_trigger.script_string = "speedcola_perk";
                    use_trigger.script_label = "mus_perks_speed_sting";
                    use_trigger.target = "vending_sleight";
                    perk_machine.script_string = "speedcola_perk";
                    perk_machine.targetname = "vending_sleight";

                    if ( isdefined( bump_trigger ) )
                        bump_trigger.script_string = "speedcola_perk";

                    break;
            }

            if ( isdefined( level._custom_perks[perk] ) && isdefined( level._custom_perks[perk].perk_machine_set_kvps ) )
                [[ level._custom_perks[perk].perk_machine_set_kvps ]]( use_trigger, perk_machine, bump_trigger, collision );
        }
    }
}


// ============================================================================
//  zmqol_subs_marlton_vo_inside_bunker  -  SUBTITLES for the bunker  (v2.14.16)
//
//  Nuketown's players are the CIA/CDC pair, who never get a voice id (this
//  map's character switch calls no zmbvoxinitspeaker), so the dialogue system
//  - and the root subtitle hook in scripts/zm/zmqol_subtitles.gsc - never
//  fires here. The map's only spoken lines are Marlton's from inside the
//  bunker: zm_nuked::marlton_vo_inside_bunker() picks one of fourteen aliases
//  when the bunker trigger fires, plays it by position, and waits for the
//  next round. This is that function verbatim plus one call after the play.
//
//  The list is stock's own, typos included: vox_plr_3_cough_0 and
//  vox_plr_3_oh_shit_0_alt01 exist in NO loaded bank (measured 2026-09-08 in
//  the zmb_nuked_real.english and zmb_common.english alias tables - the bank
//  has vox_plr_3_exert_cough_0 and vox_plr_3_oh_shit_0 instead), so those two
//  picks are silent in stock, stay silent here, and get no text, because the
//  duration read fails before the lookup. Correcting stock's names would be a
//  gameplay change, not a subtitle. 1750 is the aliases' DistMaxDry, from the
//  same table.
// ============================================================================
zmqol_subs_marlton_vo_inside_bunker()
{
    marlton_bunker_trig = getent( "marlton_bunker_trig", "targetname" );
    marlton_sound_pos = marlton_bunker_trig.origin;
    marlton_vo = [];
    marlton_vo[marlton_vo.size] = "vox_plr_3_pap_wait_0";
    marlton_vo[marlton_vo.size] = "vox_plr_3_pap_wait2_0";
    marlton_vo[marlton_vo.size] = "vox_plr_3_pap_wait2_2";
    marlton_vo[marlton_vo.size] = "vox_plr_3_avogadro_attack_1";
    marlton_vo[marlton_vo.size] = "vox_plr_3_avogadro_attack_2";
    marlton_vo[marlton_vo.size] = "vox_plr_3_build_add_1";
    marlton_vo[marlton_vo.size] = "vox_plr_3_build_pck_bjetgun_0";
    marlton_vo[marlton_vo.size] = "vox_plr_3_bus_zom_chase_1";
    marlton_vo[marlton_vo.size] = "vox_plr_3_bus_zom_roof_4";
    marlton_vo[marlton_vo.size] = "vox_plr_3_cough_0";
    marlton_vo[marlton_vo.size] = "vox_plr_3_map_in_fog_0";
    marlton_vo[marlton_vo.size] = "vox_plr_3_map_in_fog_1";
    marlton_vo[marlton_vo.size] = "vox_plr_3_map_in_fog_2";
    marlton_vo[marlton_vo.size] = "vox_plr_3_oh_shit_0_alt01";

    while ( true )
    {
        marlton_bunker_trig waittill( "trigger" );
        str_alias = marlton_vo[randomintrange( 0, marlton_vo.size )];
        playsoundatposition( str_alias, marlton_sound_pos );
        scripts\zm\zmqol_subtitles::zmqol_subs_from_position( str_alias, "Marlton", marlton_sound_pos, 1750 );
        maps\mp\zm_nuked::wait_for_next_round( level.round_number );
    }
}
