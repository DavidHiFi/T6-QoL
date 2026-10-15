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
//  out."* The row that writes the bind lives in optionssettings.lua
//  (CONTROLS > UTILITY tab, v2.17.0 block); this file is the side that MAKES
//  the bound key do something.
//
//  ?? THE ROUTE IS A DVAR TRIGGER, NOT "+actionslot N". The v1 route rode
//  notifyonplayercommand("zmqol_tp_key", "+actionslot 5") and did not work:
//  measured 2026-10-09 (audit thread 8cb16e49, zm_qol_mg_audit, PID 13516,
//  god+ghost confirmed) - with the watcher armed at connect and verified
//  loaded, a real keypress dispatching "+actionslot 5" via a bind fires
//  NOTHING, and so do "+actionslot 6" and "+actionslot 7" by key AND by
//  console, while an ESC press the same minute opens the pause menu. The
//  engine special-cases actionslot commands away from the player-notify
//  path. The T6-Data-Archive subscribable list (MPZM/Script/User Input)
//  lists "+actionslot N", but the shipped .fly "precedent" never proved it:
//  the user's real fly keys are `bind 9 "fly 1"` / `bind 0 "fly 0"` (their
//  bindings_zm.bdg) - dvar binds, the same channel as every cheat command.
//
//  ?? SO THE KEY IS A TRIGGER, THE FLY-SHAPED WAY: the row binds
//  `set zmqol_tp_fire 1`; this side watches the dvar, consumes it back to 0,
//  and flips the preference. "The dvar ... is reset to 0 on consumption, so
//  it is a trigger and a keybind fires on every press" - the established
//  shape (zmqol_boss_spawn_dvar_watch, zmqol_ww_give_dvar_watch). The flip
//  itself is unchanged: this player's third person PREFERENCE through
//  zmqol_playeropt (zmqol_popt / zmqol_popt_store), the same thing the
//  GAME 3 tab's THIRD PERSON row writes; the 1 Hz pass owns every
//  setclientthirdperson call, so the camera follows within 0.25s.
//
//  ?? CO-OP: the trigger dvar is a server dvar, so like the fly dvar
//  commands only the host's copy consumes it; a non-host's key press sets
//  their own client dvar and does not reach this watcher. Solo (the
//  utility row's target) is unaffected. Non-host players keep the GAME 3
//  row and the .tp chat route.
//
//  ?? WHY A NEW FILE AND NOT quality_of_life.gsc. The ceiling file must not
//  grow (workspace AGENTS.md item 1b). This file is small and self-contained
//  with its own init(); every helper is an engine builtin or a
//  zmqol_playeropt namespace call with its full path.
// ============================================================================

#include maps\mp\_utility;

init()
{
    //  Fresh trigger state every map load: a press that landed during a
    //  match end must not fire once into the next map.
    setdvar( "zmqol_tp_fire", "0" );

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

//  Poll the trigger dvar. 0.1s is well under the 0.25s camera-follow and
//  far above GSC scheduler cost; the dvar is consumed so one press is one
//  flip no matter how long the watcher cycle is.
zmqol_tp_key_watch()
{
    self endon( "disconnect" );

    //  Co-op: the trigger acts on a server dvar, so only the host's copy
    //  may run - the same guard the fly dvar watches use.
    if ( !self scripts\zm\zmqol_playeropt::zmqol_popt_is_host() )
        return;

    for ( ;; )
    {
        wait 0.1;

        if ( getdvarint( "zmqol_tp_fire" ) == 1 )
        {
            setdvar( "zmqol_tp_fire", "0" );
            self zmqol_tp_key_flip();
        }
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
