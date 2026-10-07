// ============================================================================
//  zmqol_console_twins.gsc  -  the missing CONSOLE TWINS of six chat commands
// ----------------------------------------------------------------------------
//  LOCATION INSIDE mod.iwd:
//      scripts/zm/zmqol_console_twins.gsc
//
//  🛑 WHAT THIS FIXES (W6 options-audit, 2026-10-06). The mod's standing rule
//  since v1.99.57 is that EVERY chat command is also a bindable console
//  command - "the console twin of .bloodmoney, per the mod's standing rule
//  that every chat command is also a bindable console command" (v1.99.57,
//  quality_of_life.gsc). The console side of that rule is
//  zmqol_console_command_names() in quality_of_life.gsc, and its own banner
//  says a command missing from that list "still works in chat and silently
//  has no console twin". Six commands never made it onto the list:
//
//      .pay  .bring  .killall  .shield  .staff  .movespeed
//
//  All six have live chat handlers (zmqol_dev_command_listener(),
//  quality_of_life.gsc:7577-7603) - nothing is broken in chat. Only the
//  BINDABLE route is missing, so a player cannot put them on a key.
//
//  🛑 WHY A NEW FILE AND NOT A LIST EDIT. quality_of_life.gsc sits on its
//  compiled-bytecode ceiling (workspace AGENTS.md item 1b): adding names to
//  zmqol_console_command_names() grows the file and the build dies at map
//  load with an Unresolved external in a function nobody touched. This file
//  is a raw script that installs itself from its own init() and costs the
//  ceiling file nothing.
//
//  🌟 THE MECHANISM IS THE PROVEN ONE. zmqol_console_command_watcher() reads
//  each name's dvar every 0.25s, clears it BEFORE dispatching so an
//  internally-waiting command cannot fire twice, seeds them empty at boot so
//  a stale config value cannot fire on map load, and forwards to the chat
//  listener through level notify( "say", "." + name + " " + args, e_host ) -
//  the listener's own documented input ( v1.5.0 argument-order note ). This
//  watcher is the same shape, with the same guards, for the six missing
//  names. The console belongs to the host, so the host is who the command
//  runs as - exactly as the existing watcher does.
//
//  🛑 NAME CHOICES CHECKED. None of the six names is written by any GSC in
//  this mod (grepped: each name appears only as its chat-command branch),
//  and none is a stock engine dvar. A bind on one of these names was
//  previously a silent no-op, so nothing that worked can regress. .fly is
//  intentionally absent - it has its own dvar watcher (zmqol_fly_dvar_watch)
//  and is excluded from the existing list on purpose, for the same reason.
//
//  📝 `.snd` stays out too: it is the silent-gun probe (v2.8.3 PROBE B), a
//  developer aid, not a player-facing switch.
// ============================================================================

#include maps\mp\_utility;

init()
{
    thread zmqol_twin_command_watcher();
}

//  The six names, in the same shape as zmqol_console_command_names().
zmqol_twin_command_names()
{
    a = [];

    a[a.size] = "pay";
    a[a.size] = "bring";
    a[a.size] = "killall";
    a[a.size] = "shield";
    a[a.size] = "staff";
    a[a.size] = "movespeed";

    return a;
}

zmqol_twin_command_watcher()
{
    level endon( "game_ended" );

    a_names = zmqol_twin_command_names();

    //  Seeded empty so a value left in the user's config from a previous
    //  session does not fire a command the instant the map loads - the same
    //  guard the existing console watcher applies to its own list.
    for ( i = 0; i < a_names.size; i++ )
        setdvar( a_names[i], "" );

    for ( ;; )
    {
        wait 0.25;

        a_players = get_players();

        if ( a_players.size == 0 )
            continue;

        //  The console belongs to the host, so the host is who the command
        //  runs as - the same player the chat path would have supplied.
        e_host = a_players[0];

        for ( i = 0; i < a_names.size; i++ )
        {
            str_val = getdvar( a_names[i] );

            if ( str_val == "" )
                continue;

            //  Cleared BEFORE dispatching, so a command that waits internally
            //  cannot be fired twice by the next pass.
            setdvar( a_names[i], "" );

            level notify( "say", "." + a_names[i] + " " + str_val, e_host );
        }
    }
}
