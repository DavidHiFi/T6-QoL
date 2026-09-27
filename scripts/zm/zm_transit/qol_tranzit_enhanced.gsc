// ============================================================================
//  qol_tranzit_enhanced.gsc  (TranZit)  -  fixes from Tranzit Enhanced
// ----------------------------------------------------------------------------
//  LOCATION INSIDE mod.iwd:
//      scripts/zm/zm_transit/qol_tranzit_enhanced.gsc
//
//  User, 2026-09-27, picking four features out of Myrix's "[Release] [ZM]
//  Tranzit Enhanced" (forum.plutonium.pw/topic/46428): turbine doors that the
//  power unlocks, the Town MP5 wall buy on classic TranZit, a Max Ammo every
//  time the Avogadro is killed, and a Pack-a-Punch door that stays open after
//  its Turbine is gone. The author asks for credit; README.md carries it.
//
//  The MP5 wall buy is NOT in this file. A wall buy is a world clientfield
//  that the server and the client must both register, so it is a struct
//  re-tag in scripts\zm\replaced\zm_transit_gamemodes.gsc plus its client
//  twin in scripts\zm\zm_expanded.csc.
//
//  Ported by behaviour, not copied. Two differences from the source:
//    - Tranzit Enhanced re-asserts its flags and the hatch's powered item
//      every 0.05 s. Stock reads power_local_doors_globally ONCE, so this sets
//      it once before that read and fixes the hatch once after it.
//    - Tranzit Enhanced drops the Max Ammo whenever the Avogadro LEAVES, which
//      includes flying off unharmed when nobody is in its region. This waits
//      on stock's own "avogadro_defeated" notify, which only a kill raises.
//
//  Recovery with no rebuild, set in the console before the map loads:
//      pap_door_stays_open 0      turbine doors close again when unpowered
//      turbine_doors_on_power 0   the power no longer opens turbine doors
//      avogadro_max_ammo 0        no drop (read at each kill, so live too)
// ============================================================================

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;

init()
{
    qol_te_default_dvar( "pap_door_stays_open" );
    qol_te_default_dvar( "turbine_doors_on_power" );
    qol_te_default_dvar( "avogadro_max_ammo" );

    level thread qol_te_pap_door_stays_open();

    //  Survival and Grief need neither. electric_door_changes() in
    //  zm_transit.gsc turns their turbine doors into 750-point doors, and the
    //  Avogadro is only spawned by zm_transit_classic.gsc.
    if ( !is_classic() )
        return;

    if ( getdvarint( "turbine_doors_on_power" ) )
        level thread qol_te_turbine_doors_on_power();

    level thread qol_te_avogadro_max_ammo();
}

qol_te_default_dvar( str_dvar )
{
    if ( getdvar( str_dvar ) == "" )
        setdvar( str_dvar, "1" );
}

// ============================================================================
//  PACK-A-PUNCH DOOR STAYS OPEN                                     (v2.9.16)
// ----------------------------------------------------------------------------
//  Moved here from zm_transit.gsc init() on 2026-09-27. Same dvar, same flag.
//
//  _zm_blockers.gsc door_think() returns straight after a local_electric_door
//  opens when level.local_doors_stay_open is set (:586), so the close half of
//  its loop never runs and the door latches open the first time it is
//  powered. Stock sets the same flag in _zm_game_module::
//  turn_power_on_and_open_doors() (:119) for Grief and the Survival maps.
//  It covers every turbine door, the bank vault Pack-a-Punch hatch included.
//
//  NO POWER NEEDED's off switch (qol_options.gsc, qol_no_power_revert) sets
//  local_doors_stay_open back to 0, and any door opened after that would close
//  again. It raises "zmqol_no_power_reverted" after the reset, so the flag is
//  put back here.
// ============================================================================
qol_te_pap_door_stays_open()
{
    level endon( "end_game" );

    if ( !getdvarint( "pap_door_stays_open" ) )
        return;

    for ( ;; )
    {
        level.local_doors_stay_open = 1;
        level waittill( "zmqol_no_power_reverted" );
    }
}

// ============================================================================
//  TURBINE DOORS OPEN WITH THE POWER
// ----------------------------------------------------------------------------
//  🌟 TREYARCH SHIPPED THE SWITCH. _zm_power.gsc standard_powered_items() (:84)
//  registers every local_electric_door with power_sources 1 unless
//  level.power_local_doors_globally is set, and set_global_power() (:365),
//  which the power switch drives through watch_global_power(), powers every
//  item whose power_sources is not 1. With the flag set, the real switch opens
//  the turbine doors and a Turbine still opens them before the power is on:
//  change_power_in_radius() skips only power_sources 2.
//
//  The flag is read ONCE, right after "start_zombie_round_logic", so it has to
//  be set before then. init() is early enough.
//
//  🛑 THE PACK-A-PUNCH HATCH IS KEPT ON THE TURBINE, as Tranzit Enhanced does
//  (its keep_local_target "lab_secret_hatch"). Its trigger is in the power
//  station lab and the hatch is the Town bank vault floor, and carrying a
//  Turbine to the lab is the map's Pack-a-Punch step. After registration its
//  powered item goes back to power_sources 1, which set_global_power() skips.
//  Once a Turbine has opened it, the latch above keeps it open.
// ============================================================================
qol_te_turbine_doors_on_power()
{
    level endon( "end_game" );

    level.power_local_doors_globally = 1;

    flag_wait( "start_zombie_round_logic" );

    //  standard_powered_items() registers in the frame the flag is set and
    //  never yields while doing it, so the list is complete by the end of this
    //  frame. Polled for up to five seconds anyway rather than assumed.
    waittillframeend;

    for ( i = 0; i < 100; i++ )
    {
        n_doors = 0;
        b_pap = 0;

        if ( isdefined( level.powered_items ) )
        {
            foreach ( powered in level.powered_items )
            {
                if ( !isdefined( powered ) || !isdefined( powered.target ) )
                    continue;

                if ( !isdefined( powered.target.script_noteworthy ) || powered.target.script_noteworthy != "local_electric_door" )
                    continue;

                if ( isdefined( powered.target.target ) && powered.target.target == "lab_secret_hatch" )
                {
                    powered.power_sources = 1;
                    b_pap = 1;
                    continue;
                }

                n_doors++;
            }
        }

        if ( n_doors > 0 || b_pap )
        {
            println( "[zm_qol] turbine doors: " + n_doors + " open with the power, Pack-a-Punch hatch kept on the Turbine: " + b_pap );
            return;
        }

        wait 0.05;
    }

    println( "[zm_qol] turbine doors: no local_electric_door registered after 5 s - nothing changed" );
}

// ============================================================================
//  THE AVOGADRO DROPS A MAX AMMO WHEN KILLED
// ----------------------------------------------------------------------------
//  _zm_ai_avogadro.gsc avogadro_pain() raises "avogadro_defeated" (:1281) once
//  per kill, whether four knife hits did it or an EMP grenade did (stun_avogadro
//  adds four hits and calls the same function). It is the notify stock's own
//  "You Have No Power Over Me" achievement waits on. Reading the Avogadro in
//  the same frame gets the spot it died on: every branch after the notify
//  yields before it moves.
//
//  A kill at a bus window drops the Max Ammo at the window, the same as any
//  zombie's drop there. zm_transit_bus.gsc has an attachpoweruptobus() that
//  would carry it inside the bus, but nothing in stock calls it, so it is left
//  alone.
// ============================================================================
qol_te_avogadro_max_ammo()
{
    level endon( "end_game" );

    for ( ;; )
    {
        level waittill( "avogadro_defeated" );

        if ( !getdvarint( "avogadro_max_ammo" ) )
            continue;

        if ( !isdefined( level.avogadro ) || !isdefined( level.zombie_powerups ) || !isdefined( level.zombie_powerups["full_ammo"] ) )
        {
            println( "[zm_qol] avogadro: killed, but the Avogadro or the Max Ammo is missing on this map - no drop" );
            continue;
        }

        v_drop = level.avogadro.origin;
        str_state = "none";

        if ( isdefined( level.avogadro.state ) )
            str_state = level.avogadro.state;

        powerup = maps\mp\zombies\_zm_powerups::specific_powerup_drop( "full_ammo", v_drop );

        println( "[zm_qol] avogadro: killed at " + v_drop + " (state " + str_state + ") - Max Ammo dropped: " + isdefined( powerup ) );
    }
}
