// ============================================================================
//  qol_dedicated.gsc  -  NO CHEATS ON A DEDICATED SERVER          (Bo2-VN)
// ----------------------------------------------------------------------------
//  The mod was written for Plutonium's Mods menu, where the host IS the
//  server. On a public dedicated server three things were wrong:
//
//    1. zmqol_playeropt.gsc used to force sv_cheats 1 on every map load, which
//       hands every client the engine's own cheat commands. That line went
//       with the chat commands; this file makes sure sv_cheats is 0 anyway,
//       whatever the server config or a previous map left behind.
//    2. The CHEATS tab rows are SERVER dvars read by per-player watchers in
//       quality_of_life.gsc. A godmode / fly / infinite_ammo value left in a
//       server config would switch the cheat on for EVERY player who joins.
//       Every one of them is reset to its off value at map load.
//    3. The one-shot rows (set_round, kill_horde, give_*, spawn_*) fire the
//       moment they hold a value, so a stale one fires on map load.
//
//  Only the reset happens here. An admin who sets one of these over rcon
//  after the map has loaded still gets exactly what they typed.
//
//  Opt out (a private server that wants cheats):  set zmqol_allow_cheats 1
//
//  🛑 HOW A DEDICATED SERVER IS RECOGNISED. The engine's `dedicated` dvar is
//  non-zero on a dedicated server. As a fallback that does not depend on that
//  dvar, the first player to connect on a server with no host player
//  (gethostplayer() undefined) also triggers the reset. A listen server or a
//  solo game always has a host, so it is never touched.
// ============================================================================

#include maps\mp\_utility;

init()
{
    level thread qol_ded_enforce();
}

qol_ded_enforce()
{
    if ( getdvarint( "zmqol_allow_cheats" ) )
    {
        println( "[zm_qol] dedicated: zmqol_allow_cheats 1 - cheat dvars left alone" );
        return;
    }

    if ( getdvarint( "dedicated" ) > 0 )
    {
        qol_ded_reset_cheats( "dedicated dvar" );
        return;
    }

    level waittill( "connected", player );
    wait 0.05;

    if ( !isdefined( gethostplayer() ) )
        qol_ded_reset_cheats( "no host player" );
}

qol_ded_reset_cheats( str_why )
{
    setdvar( "sv_cheats", 0 );

    //  The CHEATS tab toggles - optionssettings.lua's QolNoArchive list.
    a_off = [];
    a_off[a_off.size] = "godmode";
    a_off[a_off.size] = "ghostmode";
    a_off[a_off.size] = "infinite_ammo";
    a_off[a_off.size] = "bottomless_clip";
    a_off[a_off.size] = "infinite_sprint";
    a_off[a_off.size] = "fly";
    a_off[a_off.size] = "rapid_fire";
    a_off[a_off.size] = "no_power";
    a_off[a_off.size] = "one_shot_one_kill";
    a_off[a_off.size] = "set_round";
    a_off[a_off.size] = "kill_horde";
    a_off[a_off.size] = "end_round";
    a_off[a_off.size] = "set_points";
    a_off[a_off.size] = "teleport";
    a_off[a_off.size] = "execute_teleport";
    //  One-shot gives and boss spawns.
    a_off[a_off.size] = "give_thundergun";
    a_off[a_off.size] = "give_wavegun";
    a_off[a_off.size] = "give_wintershowl";
    a_off[a_off.size] = "give_wunderwaffe";
    a_off[a_off.size] = "spawn_brutus";
    a_off[a_off.size] = "spawn_panzer";
    a_off[a_off.size] = "spawn_jumpingjacks";

    for ( i = 0; i < a_off.size; i++ )
        setdvar( a_off[i], "0" );

    setdvar( "give_weapon", "" );

    println( "[zm_qol] dedicated: cheats reset (" + str_why + ") - sv_cheats 0 and " + a_off.size + " cheat dvars off" );
}
