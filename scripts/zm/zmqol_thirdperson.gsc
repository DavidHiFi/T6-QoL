// ============================================================================
//  zmqol_thirdperson.gsc  -  the bindable third person toggle key
// ----------------------------------------------------------------------------
//  LOCATION INSIDE mod.iwd:
//      scripts/zm/zmqol_thirdperson.gsc
//
//  ?? WHAT THIS IS (user, 2026-10-07, with the stock controls-menu
//  screenshot): *"in this new tab, there's going to be some quality of life
//  key bind options ... we'll start off simple with third person. so you can
//  go to that new utility tab and click and assign a key the same way you
//  would on any of all those other tabs ... on your controller or your
//  keyboard, and then tap one button and go in third person and toggle back
//  out."* The rows that write the bind live in optionssettings.lua
//  (CONTROLS > UTILITY tab, v2.17.0 block); this file is the side that MAKES
//  the bound key do something.
//
//  ?? THE ROUTE IS THE PROVEN .fly ONE, NOT A DVAR BIND. GSC cannot register
//  a new console command, and the cg_thirdPerson dvar is one of this build's
//  cheat-protected cg_* switches (qol_options.gsc's crosshair finding) - a
//  `bind x "toggle cg_thirdPerson 0 1"` would be refused outside a cheat
//  server. The mod already solved all of this for .fly (quality_of_life.gsc,
//  v1.59.3/v1.99.x): ride "+actionslot N", a command the engine accepts,
//  subscribes through notifyonplayercommand, and never uses in Zombies.
//  The fly bind took +actionslot 7; this takes +actionslot 5, which nothing
//  in this mod or the stock zombies binds touches. One notify registration
//  covers BOTH input devices, so the keyboard key from the native bind
//  editor and the pad button from the choice row fire the same toggle.
//
//  ?? WHAT THE TOGGLE FLIPS: this player's third person PREFERENCE, the same
//  thing the GAME 3 tab's THIRD PERSON row writes (qol_opt_third_person's
//  1 Hz pass owns every setclientthirdperson call - camera mode, angle, FOV
//  recovery, and stock's own off-on-spawn). Flipping the preference keeps
//  one owner for the camera; the applied camera follows within 0.25s.
//
//  ?? WHO CAN USE IT: the host flips the dvar; anyone else gets a per-player
//  override, both through zmqol_playeropt's own store/read (zmqol_popt /
//  zmqol_popt_store) - the same split the chat .my command uses. Nothing
//  here reads or writes another player's client dvars.
//
//  ?? WHY A NEW FILE AND NOT quality_of_life.gsc. The ceiling file must not
//  grow (workspace AGENTS.md item 1b). Every name used here is an engine
//  builtin or a zmqol_playeropt namespace call with its full path, so a
//  hotloaded copy of this file resolves cleanly too (hotload-gate defs:
//  notifyonplayercommand, waittill, wait, endon).
// ============================================================================

#include maps\mp\_utility;

init()
{
    thread zmqol_tp_key_players();
}

//  One key-watcher per player, forever. New joiners get their own.
zmqol_tp_key_players()
{
    level endon( "game_ended" );

    for ( ;; )
    {
        level waittill( "connected", player );
        player thread zmqol_tp_key_watch();
    }
}

zmqol_tp_key_watch()
{
    self endon( "disconnect" );
    level endon( "game_ended" );

    self notifyonplayercommand( "zmqol_tp_key", "+actionslot 5" );

    for ( ;; )
    {
        self waittill( "zmqol_tp_key" );
        self zmqol_tp_key_flip();
    }
}

//  Flip this player's third person preference. Reads through the same rule
//  the GAME 3 row reads (personal override, else the host's dvar), so a
//  console `third_person 1` and a key tap agree on what is on.
zmqol_tp_key_flip()
{
    n_now = self scripts\zm\zmqol_playeropt::zmqol_popt( "third_person", 0 );

    if ( n_now != 0 )
        self scripts\zm\zmqol_playeropt::zmqol_popt_store( "third_person", 0 );
    else
        self scripts\zm\zmqol_playeropt::zmqol_popt_store( "third_person", 1 );

    println( "[zm_qol] third person key -> " + ( 1 - n_now ) );
}
