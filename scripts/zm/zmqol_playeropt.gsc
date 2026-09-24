// ============================================================================
//  zmqol_playeropt  -  per-player option channel + host-gated commands
// ----------------------------------------------------------------------------
//  Root cause of most co-op Tier 1 findings: there is no per-player option
//  state. Every preference is one server dvar; one player's toggle is the
//  whole lobby's. This script is the channel. It lives HERE so
//  quality_of_life.gsc stays under its compiled-bytecode ceiling.
//
//  Fix 1 - reader (call from any player-scoped thread):
//      b_on = self scripts\zm\zmqol_playeropt::zmqol_popt( "hud_master", 1 );
//
//  Fix 1 - writer (chat, any player, in-game only):
//      .my <name> <value>     set YOUR override
//      .my <name>             show current (override or server default path)
//      .my <name> clear       drop your override, follow the server dvar again
//
//  Fix 2 - the chat/console command dispatcher (zmqol_dev_command_listener,
//  zmqol_console_command_watcher, zmqol_console_command_names) MOVED here from
//  quality_of_life.gsc so the host gate costs nothing against the ceiling.
//  Match-scoped commands (.round, .nuke, .god, .hud, .killall, ...) require
//  self == gethostplayer(); self-scoped rows (.give, .pack, .p, .help, ...)
//  stay open to every player. Console path uses gethostplayer() too, not
//  players[0].
//
//  🛑 MATCH RULES ARE NOT ON THE .my CHANNEL. perk_limit, pap_price, powerup
//  tables, solo_ee, round settings stay host/server dvars on purpose.
//
//  Multiple level waittill("say") threads all see the same notify. quality_of_life
//  no longer runs its own command listener - init() calls
//  scripts\zm\zmqol_playeropt::zmqol_dev_commands() instead.
// ============================================================================

#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;


//  FIX 2 - host / scope helpers for the chat+console command listeners.
zmqol_popt_is_host( e_player )
{
    e_host = gethostplayer();

    //  Fail closed: no known host means match-scoped commands stay blocked.
    if ( !isdefined( e_host ) )
        return 0;

    return e_player == e_host;
}

//  Self-scoped commands any player may run (they apply to that player only).
//  Everything else is match-scoped and host-gated in the listener.
zmqol_popt_cmd_is_self( str_cmd )
{
    switch ( str_cmd )
    {
        case "give":
        case "giveweapon":
        case "gun":
        case "pack":
        case "unpack":
        case "p":
        case "pay":
        case "character":
        case "char":
        case "help":
        case "where":
        case "reload":
        case "boxhere":
        case "wallhere":
        case "giveperks":
        case "removeperks":
        case "movespeed":
        case "velocity":
        case "vel":
        case "speed":
        case "fly":
        case "afk":
        case "my":
        case "popt":
        case "mine":
            return 1;
    }

    return 0;
}

init()
{
    level thread zmqol_popt_say_listener();
}

//  Returns this player's override if they set one, else the server dvar.
//  Safe when self is not a player (falls through to the dvar).
zmqol_popt( str_name, n_default )
{
    if ( isdefined( self.zmqol_popt ) && isdefined( self.zmqol_popt[str_name] ) )
        return self.zmqol_popt[str_name];

    return getdvarintdefault( str_name, n_default );
}

//  Whitelist: preference rows only. A typo must not invent a key.
zmqol_popt_is_allowed( str_name )
{
    switch ( str_name )
    {
        case "hud_master":
        case "hud_all":
        case "hud_health_bar":
        case "hud_timers":
        case "hud_zone":
        case "hud_compass":
        case "hud_remaining":
        case "hud_bleedout_bar":
        case "hud_subtitles":
        case "hud_perk_popup":
        case "hud_powerup_timers":
        case "round_summary":
        case "crosshair":
        case "third_person":
        case "velocity":
        case "hitmarkers":
        case "character":
            return 1;
    }

    return 0;
}

zmqol_popt_set( str_name, n_value )
{
    if ( !isdefined( self.zmqol_popt ) )
        self.zmqol_popt = [];

    self.zmqol_popt[str_name] = n_value;
    level notify( "zmqol_popt_changed", self );
}

zmqol_popt_clear( str_name )
{
    if ( !isdefined( self.zmqol_popt ) )
        return;

    if ( !isdefined( self.zmqol_popt[str_name] ) )
        return;

    self.zmqol_popt[str_name] = undefined;
    level notify( "zmqol_popt_changed", self );
}

//  Own say listener — does not edit quality_of_life.gsc.
zmqol_popt_say_listener()
{
    level endon( "game_ended" );

    for ( ;; )
    {
        level waittill( "say", message, player );

        if ( !isdefined( player ) || !isdefined( message ) )
            continue;

        if ( isdefined( level.intermission ) && level.intermission )
            continue;

        message = tolower( message );

        if ( message.size < 2 )
            continue;

        if ( message[0] != "!" && message[0] != "." && message[0] != "/" )
            continue;

        tokens = strtok( message, " " );

        if ( !isdefined( tokens ) || tokens.size == 0 )
            continue;

        cmd = getsubstr( tokens[0], 1 );

        if ( cmd != "my" && cmd != "popt" && cmd != "mine" )
            continue;

        if ( tokens.size < 2 )
        {
            player iprintln( "^3[zm_qol] usage: ^7.my <option> <value>  ^3| ^7.my <option> clear" );
            player iprintln( "^3options: ^7hud_master hud_all hud_timers hud_zone hud_compass crosshair third_person velocity hitmarkers ..." );
            continue;
        }

        str_name = tokens[1];

        if ( !zmqol_popt_is_allowed( str_name ) )
        {
            player iprintln( "^1[zm_qol] not a personal option: ^7" + str_name );
            continue;
        }

        if ( tokens.size == 2 )
        {
            if ( isdefined( player.zmqol_popt ) && isdefined( player.zmqol_popt[str_name] ) )
                player iprintln( "^2[zm_qol] ^7" + str_name + " override = ^3" + player.zmqol_popt[str_name] + " ^7(yours only)" );
            else
                player iprintln( "^3[zm_qol] ^7" + str_name + " follows the server dvar (^3" + getdvarintdefault( str_name, -999 ) + "^7)" );

            continue;
        }

        str_val = tokens[2];

        if ( str_val == "clear" || str_val == "reset" || str_val == "default" )
        {
            player zmqol_popt_clear( str_name );
            player iprintln( "^3[zm_qol] ^7" + str_name + " back to the server dvar (yours alone was cleared)" );
            continue;
        }

        //  0/1 and small integers are the common rows; int() of junk is 0,
        //  which would silently mean "off". Reject non-numeric-looking input.
        b_numeric = 1;

        for ( i = 0; i < str_val.size; i++ )
        {
            c = str_val[i];

            if ( c != "0" && c != "1" && c != "2" && c != "3" &&
                 c != "4" && c != "5" && c != "6" && c != "7" &&
                 c != "8" && c != "9" && c != "-" )
            {
                b_numeric = 0;
                break;
            }
        }

        if ( !b_numeric || str_val == "" || str_val == "-" )
        {
            player iprintln( "^1[zm_qol] .my needs a number or ^7clear" );
            continue;
        }

        n_value = int( str_val );
        player zmqol_popt_set( str_name, n_value );

        //  character also has the older per-player field .character writes;
        //  qol_opt_character() still reads zmqol_char_want first. Keep both.
        if ( str_name == "character" )
        {
            if ( n_value == 0 )
                player.zmqol_char_want = undefined;
            else
                player.zmqol_char_want = n_value;
        }

        player iprintln( "^2[zm_qol] ^7" + str_name + " = ^3" + n_value + " ^7- yours only" );
    }
}

// ============================================================================
//  Moved from quality_of_life.gsc (Fix 2) - chat/console command dispatcher
//  + host gate. quality_of_life starts this via zmqol_dev_commands().
// ============================================================================
zmqol_dev_commands()
{
    setdvar( "sv_cheats", 1 );
    level thread zmqol_dev_command_listener();
    level thread zmqol_console_command_watcher();
}

// ============================================================================
//  CONSOLE TWINS FOR EVERY CHAT COMMAND                             (v1.86.0)
//
//  User, 2026-08-13: *"make all the chat commands available as console
//  commands, not just chat commands example(s): .pack .round (without the . or
//  ! prefix)."*
//
//  🌟 THE WATCHER DOES NOT REIMPLEMENT ANY COMMAND. It writes the line back
//  through the SAME entry point chat uses -
//        level notify( "say", message, player )
//  which is exactly what zmqol_dev_command_listener() sits on
//  (`level waittill( "say", message, player )`). So every command, every alias
//  and every future addition is reachable from the console the moment it works
//  in chat, and the two lists can never drift because there is only one list.
//
//  🛑 HOW YOU ACTUALLY TYPE IT, AND WHY. GSC cannot register a real console
//  COMMAND - the only lever it has is a dvar. So each command name is registered
//  as a dvar and ANY non-empty value fires it:
//        round 100     ->  .round 100
//        p 5000        ->  .p 5000
//        pack 1        ->  .pack          (a value is required; bare `pack`
//                                          just prints the dvar, as dvars do)
//  This is the same shape as `fly`, which the user already uses, so it is the
//  established pattern here rather than a new convention.
//
//  🛑 THE NAMES WERE CHECKED FOR COLLISIONS, NOT ASSUMED SAFE. Every command
//  name below was diffed against the 3,210 dvars this install actually dumps
//  into console_zm.log. Exactly one matched - `fly` - and that one is this mod's
//  own, already registered by qol_options with its own watcher. It is therefore
//  DELIBERATELY ABSENT from the list: clearing it to "" every pass would break
//  the watcher that owns it. Everything else is a name the engine does not use.
//
//  📝 `qol` takes a whole command line, which covers the alias families that are
//  matched by prefix rather than by name - the per-perk `.givejug` /
//  `.removecherry` forms and the power-up aliases:
//        qol "givejug"      qol "maxammo"      qol "powerup nuke"
//
//  ⚠️ Each pass reads one dvar per name, 4 times a second. That is ~150 hash
//  lookups/sec and nothing else - no allocation, no per-player work. Listed here
//  because this project has an open frametime question and every new periodic
//  loop should say what it costs.
// ============================================================================
zmqol_console_command_names()
{
    a = [];

    //  🛑 ADD NEW CHAT COMMANDS HERE TOO. This is the one list the console side
    //  reads; a command missing from it still works in chat and silently has no
    //  console twin. `fly` is intentionally omitted - see the note above.
    a[a.size] = "p";            a[a.size] = "round";        a[a.size] = "setround";
    a[a.size] = "god";          a[a.size] = "ghost";        a[a.size] = "afk";
    a[a.size] = "hud";          a[a.size] = "help";         a[a.size] = "where";
    a[a.size] = "boxhere";
    a[a.size] = "wallhere";
    a[a.size] = "fog";          a[a.size] = "night";        a[a.size] = "nightmode";
    a[a.size] = "pack";         a[a.size] = "unpack";       a[a.size] = "reload";
    a[a.size] = "infammo";      a[a.size] = "infiniteammo";
    a[a.size] = "bclip";        a[a.size] = "bottomlessclip";
    a[a.size] = "infsprint";    a[a.size] = "infinitesprint";
    a[a.size] = "giveperks";    a[a.size] = "removeperks";  a[a.size] = "nozmspawns";
    a[a.size] = "powerup";      a[a.size] = "powerups";     a[a.size] = "drop";
    a[a.size] = "dm";           a[a.size] = "deathmachine";
    a[a.size] = "tesla";        a[a.size] = "thundergun";   a[a.size] = "zeus";
    a[a.size] = "freezegun";    a[a.size] = "winters";      a[a.size] = "wintershowl";
    a[a.size] = "wunderwaffe";  a[a.size] = "dg2";
    //  v2.10.14 - the Wave Gun (the box hands out the Zap Gun pair; the combined
    //  gun is its alt fire), gated on zmqol_ww "5" like zapgun.gsc.
    a[a.size] = "wavegun";      a[a.size] = "zapgun";       a[a.size] = "zapguns";
    a[a.size] = "microwave";    a[a.size] = "mgun";
    a[a.size] = "testsound";
    //  v1.99.15 - .wwfx toggles the Who's Who downed-state overlay on demand, so
    //  it can be checked in two seconds instead of by dying for it.
    a[a.size] = "wwfx";
    //  v1.99.57 - the console/bind twin of .bloodmoney, per the mod's standing
    //  rule that every chat command is also a bindable console command.
    a[a.size] = "bloodmoney";
    //  v1.99.63 - the console/bind twin of .machines (Nuketown only).
    a[a.size] = "machines";     a[a.size] = "dropmachines";
    //  v2.9.34 - the Ray Gun hand-offset preset cycler (tuning tool).
    a[a.size] = "rayhand";
    //  v2.15.4 - the console/bind twin of .bonfiresale, the same call bloodmoney
    //  got in v1.99.57 and for the same reason: the user asked for this power-up
    //  by name. 📝 The other power-up short forms (.firesale, .zombieblood,
    //  .bonfire) still have no dedicated dvar - they are reachable from the
    //  console through the generic `qol` dvar, which forwards any chat command.
    a[a.size] = "bonfiresale";

    return a;
}

zmqol_console_command_watcher()
{
    if ( scripts\zm\quality_of_life::zmqol_minimal() )
        return;

    level endon( "game_ended" );

    a_names = zmqol_console_command_names();

    //  Seeded empty so a value left in the user's config from a previous session
    //  does not fire a command the instant the map loads.
    for ( i = 0; i < a_names.size; i++ )
        setdvar( a_names[i], "" );

    setdvar( "qol", "" );

    for ( ;; )
    {
        wait 0.25;

        a_players = get_players();

        if ( a_players.size == 0 )
            continue;

        //  The console belongs to the host, so the host is who the command runs
        //  as - the same player the chat path would supply.
        //  FIX 2: gethostplayer() only. No a_players[0] fallback - slot 0 is
        //  not the host; if the host is not known yet, skip this pass.
        e_host = gethostplayer();

        if ( !isdefined( e_host ) )
            continue;

        str_line = getdvar( "qol" );

        if ( str_line != "" )
        {
            setdvar( "qol", "" );
            level notify( "say", "." + str_line, e_host );
        }

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

zmqol_dev_command_listener()
{
    level endon( "game_ended" );

    for ( ;; )
    {
        // 🛑 ARGUMENT ORDER IS ( message, player ) - NOT ( player, message ).
        // v1.5.0 had these the wrong way round, which is why "!p 10000" silently
        // did nothing: strtok() was being handed a player ENTITY. Confirmed
        // against a working Plutonium T6 mod the user already runs,
        // littlegods-mod\chat.gsc:21 - `level waittill("say", message,
        // player)`. The BO2-GSC-Releases sample has them the other way round and
        // is what led me wrong; trust the mod that actually runs on Plutonium.
        level waittill( "say", message, player );

        if ( !isdefined( player ) || !isdefined( message ) )
            continue;

        if ( isdefined( level.intermission ) && level.intermission )
            continue;

        message = tolower( message );

        // Accept ALL THREE prefixes. The user asked for "!", but Plutonium appears
        // to swallow a leading "!" as a console command - typing "!god" printed
        // "unknown cmd" rather than reaching script - and the reference mod above
        // uses ".". Supporting all of them means whichever survives to GSC works.
        //
        // "/" added 2026-08-03 at the user's request. Same caveat as "!": the
        // client may treat a leading "/" in chat as a console command and never
        // fire the "say" notify. "." is the one prefix proven to reach script, so
        // that is what the help panel leads with.
        if ( message.size < 2 )
            continue;

        if ( message[0] != "!" && message[0] != "." && message[0] != "/" )
            continue;

        tokens = strtok( message, " " );

        if ( !isdefined( tokens ) || tokens.size == 0 )
            continue;

        // Strip the prefix character, leaving the bare command word.
        cmd = getsubstr( tokens[0], 1 );

        //  FIX 2 - host gate for match-scoped commands. Self-scoped rows
        //  (give/pack/p/character/help/...) stay open to every player; anything
        //  that mutates the match (.round, .nuke, .god, .hud, .killall, ...)
        //  is host-only. Test is gethostplayer(), not players[0].
        if ( !zmqol_popt_cmd_is_self( cmd ) && !zmqol_popt_is_host( player ) )
        {
            player iprintln( "^1[zm_qol] host only: ^7." + cmd );
            continue;
        }

        //  .my / .popt / .mine are owned by zmqol_popt_say_listener() above.
        //  Without this, bare ".my" also falls through to unknown-command here.
        if ( cmd == "my" || cmd == "popt" || cmd == "mine" )
            continue;

        if ( cmd == "p" )
        {
            // int() of anything non-numeric is 0, so treat 0 as "no amount given"
            // and fall back to a sensible default rather than doing nothing.
            amount = 1000;

            if ( tokens.size > 1 && int( tokens[1] ) != 0 )
                amount = int( tokens[1] );

            player maps\mp\zombies\_zm_score::add_to_player_score( amount, 1 );
            player iprintln( "^2[zm_qol] ^7points ^2+" + amount );
        }
        else if ( cmd == "round" || cmd == "setround" )
        {
            //  User, 2026-08-12: ".round (number)". Console twin: set_round <n>.
            if ( tokens.size < 2 || int( tokens[1] ) < 1 )
            {
                player iprintln( "^3[zm_qol] usage: ^7.round <number>  ^3(current: ^7" + level.round_number + "^3)" );
                continue;
            }

            level thread scripts\zm\quality_of_life::zmqol_goto_round( int( tokens[1] ), player );
        }
        else if ( cmd == "endround" )
        {
            // ================================================================
            //  .endround  -  end the CURRENT round and let it advance    (v2.3.4)
            //
            //  User, 2026-08-25: *"add /.!endround as a chat command so I can just
            //  quickly open my chat in-game and do .endround and switch the round
            //  over to the next one"*.
            //
            //  🛑 THIS IS NOT scripts\zm\quality_of_life::zmqol_goto_round( round + 1 ). That function JUMPS
            //  to an arbitrary target round and re-derives everything for it
            //  (see its own banner) - the right tool for ".round 30", the wrong
            //  one for "just end this one". Ending a round is a narrower, already
            //  -solved problem: zero what is still queued to spawn AND kill what
            //  is already alive, then let stock's own scripts\zm\quality_of_life::round_think() close the
            //  round and increment level.round_number normally - exactly what
            //  the END ROUND cheats-tab row (end_round dvar,
            //  scripts\zm\quality_of_life::zmqol_round_dvar_watch() above) already does, reusing
            //  scripts\zm\quality_of_life::zmqol_kill_horde() and its magic-bullet-shield/negative-health
            //  fixes rather than a second implementation of either.
            //
            //  🌟 REUSED, NOT REBUILT: setting the same dvar the existing
            //  cheats-tab row uses is the whole command. scripts\zm\quality_of_life::zmqol_round_dvar_watch()
            //  picks it up within 0.25s and does the real work; this only adds
            //  the chat entry point and the player-facing confirmation, which
            //  the dvar path (console-only, no player context) doesn't have.
            // ================================================================
            setdvar( "end_round", "1" );
            player iprintln( "^2[zm_qol] ^7ending round ^2" + level.round_number );
        }
        else if ( cmd == "wwfx" )
        {
            //  Apply / clear the Who's Who screen effect without going down.
            //
            //  v1.99.19 - it now drives the REAL mechanism, which is the whole
            //  point of a verification aid: stock's own visionset, activated
            //  through _visionset_mgr exactly as
            //  _zm_chugabud::activate_chugabud_effects_and_audio() does it, plus
            //  the night-mode suspend that lets a visionset render at all.
            //  Before this it only drove the dvar copy, so it could not have
            //  distinguished "the visionset is broken" from "the copy is broken"
            //  - and the copy was the thing that was broken.
            //
            //  It also reports whether the visionset is registered at all, which
            //  separates "not registered" from "registered and not showing"
            //  without costing a boot.
            if ( isdefined( player.zmqol_wwfx ) && player.zmqol_wwfx )
            {
                player.zmqol_wwfx = 0;
                player setclientfieldtoplayer( "clientfield_whos_who_filter", 0 );
                maps\mp\_visionset_mgr::vsmgr_deactivate( "visionset", "zm_whos_who", player );
                player scripts\zm\quality_of_life::zmqol_whoswho_overlay_off();
                player iprintln( "^1[zm_qol] Who's Who overlay OFF" );
            }
            else
            {
                b_registered = isdefined( level.vsmgr ) &&
                               isdefined( level.vsmgr[ "visionset" ] ) &&
                               isdefined( level.vsmgr[ "visionset" ].info ) &&
                               isdefined( level.vsmgr[ "visionset" ].info[ "zm_whos_who" ] );

                if ( !b_registered )
                {
                    player iprintln( "^1[zm_qol] zm_whos_who visionset NOT registered - the grade cannot show" );
                    println( "[zm_qol] wwfx: zm_whos_who visionset NOT registered on the server" );
                    continue;
                }

                //  slot_index is assigned in finalize_type_clientfields(), which
                //  returns early when only the default visionset exists - so an
                //  undefined here means the grade has no clientfield to travel on.
                str_slot = "UNASSIGNED";

                if ( isdefined( level.vsmgr[ "visionset" ].info[ "zm_whos_who" ].slot_index ) )
                    str_slot = "" + level.vsmgr[ "visionset" ].info[ "zm_whos_who" ].slot_index;

                player.zmqol_wwfx = 1;
                player scripts\zm\quality_of_life::zmqol_whoswho_overlay_on();

                //  v1.99.20 - drive BOTH routes, exactly as stock does from the
                //  same four lines of activate_chugabud_effects_and_audio():
                //  the clientfield (which reaches our own client callback, and
                //  is what actually applies the vision now) and the manager.
                player setclientfieldtoplayer( "clientfield_whos_who_filter", 1 );
                maps\mp\_visionset_mgr::vsmgr_activate( "visionset", "zm_whos_who", player );

                player iprintln( "^2[zm_qol] Who's Who overlay ON (slot " + str_slot + ")" );
                println( "[zm_qol] wwfx: zm_whos_who registered, slot_index " + str_slot );
            }
        }
        else if ( cmd == "god" )
        {
            //  🛑 v1.95.0 - THE DVAR IS WRITTEN BACK. scripts\zm\quality_of_life::zmqol_toggle_dvar_watch()
            //  treats `godmode` as the state, so a front-end that changes the
            //  state without telling it gets its change undone 0.25s later -
            //  which is precisely what .god did before this line existed. Same
            //  contract as .fly, which has always written `fly` back.
            if ( isdefined( player.zmqol_god ) && player.zmqol_god )
            {
                player.zmqol_god = 0;
                player disableinvulnerability();
                setdvar( "godmode", "0" );
                player iprintln( "^1[zm_qol] godmode OFF" );
            }
            else
            {
                player.zmqol_god = 1;
                player enableinvulnerability();
                setdvar( "godmode", "1" );
                player iprintln( "^2[zm_qol] godmode ON" );
            }
        }
        else if ( cmd == "hud" )
        {
            // ================================================================
            //  .hud on / .hud off  -  the master HUD switch          (v1.85.0)
            //
            //  Console twin: `hud_master 0|1`, registered in qol_options::init()
            //  like every other command here - see the commands-are-dvars rule.
            //  This branch only writes the dvar; qol_options::qol_opt_hud_watcher
            //  is the single place that acts on it, so the chat command and the
            //  console command cannot drift or fight each other.
            //
            //  Bare ".hud" toggles, which is what every other switch here does.
            // ================================================================
            b_on = !getdvarintdefault( "hud_master", 1 );

            if ( tokens.size > 1 )
            {
                str_arg = tolower( tokens[1] );

                if ( str_arg == "on" || str_arg == "1" )
                    b_on = 1;
                else if ( str_arg == "off" || str_arg == "0" )
                    b_on = 0;
                else
                {
                    player iprintln( "^3[zm_qol] usage: ^7.hud on ^3| ^7.hud off" );
                    continue;
                }
            }

            setdvar( "hud_master", b_on );

            if ( b_on )
                player iprintln( "^2[zm_qol] HUD ON" );
            else
                player iprintln( "^1[zm_qol] HUD OFF ^7- .hud on to bring it back" );
        }
        else if ( cmd == "ghost" )
        {
            // self.ignoreme is the stock "AI does not target me" flag - it is what
            // maps\mp\zombies\_zm_spawner sets on a fresh zombie and what the
            // afk_on_command_by_THS script uses for the same purpose.
            //  v1.95.0 - writes `ghostmode` back for the same reason .god does.
            if ( isdefined( player.zmqol_ghost ) && player.zmqol_ghost )
            {
                player.zmqol_ghost = 0;
                player.ignoreme = 0;
                setdvar( "ghostmode", "0" );
                player iprintln( "^1[zm_qol] ghost OFF ^7- zombies can see you" );
            }
            else
            {
                player.zmqol_ghost = 1;
                player.ignoreme = 1;
                player thread scripts\zm\quality_of_life::zmqol_ghost_enforce();
                setdvar( "ghostmode", "1" );
                player iprintln( "^2[zm_qol] ghost ON ^7- zombies ignore you" );
            }
        }
        else if ( cmd == "afk" )
        {
            // Ghost + godmode together, which is what the AFK script does. No
            // 5-minute cap or 30-minute cooldown here: that exists upstream to stop
            // abuse in public games, and this is a private-match QoL mod.
            if ( isdefined( player.zmqol_afk ) && player.zmqol_afk )
            {
                player.zmqol_afk = 0;
                player.ignoreme = 0;

                if ( !isdefined( player.zmqol_god ) || !player.zmqol_god )
                    player disableinvulnerability();

                player iprintln( "^1[zm_qol] AFK OFF" );
            }
            else
            {
                player.zmqol_afk = 1;
                player.ignoreme = 1;
                player enableinvulnerability();
                player thread scripts\zm\quality_of_life::zmqol_ghost_enforce();
                player iprintln( "^2[zm_qol] AFK ON ^7- ignored and invulnerable" );
            }
        }
        else if ( cmd == "character" || cmd == "char" )
        {
            //  ================================================================
            //  🛑 v2.13.0 - THE PER-PLAYER CHARACTER PICK, AND THE REASON IT
            //  HAS TO BE A CHAT COMMAND RATHER THAN A MENU ROW.
            //
            //  The menu row writes the `character` dvar. On the host that is the
            //  server's dvar and it works; on anybody else it is their own local
            //  copy and the server never reads it. There is no getclientdvar in
            //  T6 and a client console command does not reach the server, so the
            //  "say" notify - which carries the SPEAKING PLAYER - is the only
            //  channel a non-host has. That is what this is.
            //
            //  qol_options::qol_opt_character() reads self.zmqol_char_want FIRST
            //  and only falls back to the dvar, so the menu row still works as
            //  the default for anyone who has not typed this, and solo behaves
            //  exactly as it did before.
            //
            //  🛑 DELIBERATELY NOT ADDED TO zmqol_console_command_names(). That
            //  watcher seeds every name in its list to "" and blanks it the
            //  instant it sees a value - and `character` is an OWNED dvar with
            //  its own watcher, exactly like `fly`, `god` and `ghost`. Putting
            //  it in that list would wipe the menu row on every pass. The host
            //  already has the console twin: the `character` dvar itself.
            //  ================================================================
            str_arg = "";

            if ( tokens.size > 1 )
                str_arg = tokens[1];

            if ( str_arg == "" )
            {
                if ( isdefined( player.zmqol_char_want ) )
                    player iprintln( "^3[zm_qol] ^7your character is set to ^3" + player.zmqol_char_want );
                else
                    player iprintln( "^3[zm_qol] ^7your character follows the menu (^3" + getdvarintdefault( "character", 0 ) + "^7)" );

                player iprintln( "^5.character 1-4 ^7to choose, ^5.character 0 ^7for the map's own pick" );
            }
            else
            {
                n_pick = int( str_arg );

                if ( n_pick < 0 || n_pick > 4 )
                    player iprintln( "^1[zm_qol] character must be 0-4 ^7(0 = the map's own pick)" );
                else
                {
                    //  0 means "go back to following the menu/lobby default",
                    //  which is what an unset field already means - so clear it
                    //  rather than storing a zero the resolver would honour.
                    if ( n_pick == 0 )
                    {
                        player.zmqol_char_want = undefined;
                        player iprintln( "^3[zm_qol] ^7character back to the map's own pick" );
                    }
                    else
                    {
                        player.zmqol_char_want = n_pick;
                        player iprintln( "^2[zm_qol] ^7character ^3" + n_pick + " ^7- yours only" );
                    }
                }
            }
        }
        else if ( cmd == "nightmode" || cmd == "night" )
        {
            //  v1.59.6 - chat front-end for the night_mode dvar.
            //
            //  Deliberately just sets the dvar rather than calling
            //  qol_opt_night_on/off directly: qol_options.gsc::qol_opt_night_mode()
            //  polls that dvar and owns the on/off transition, including
            //  starting and stopping visual_fix. Driving the perk from two
            //  places would let the two disagree - the dvar would read 0 while
            //  the screen was dark, and the next poll would fight it.
            //
            //  One owner, two front-ends: console `night_mode 1` and this.
            str_arg = "";

            if ( tokens.size > 1 )
                str_arg = tokens[1];

            if ( str_arg == "off" || str_arg == "0" )
            {
                setdvar( "night_mode", "0" );
                player iprintln( "^1[zm_qol] night mode OFF" );
            }
            else if ( str_arg == "on" || str_arg == "1" )
            {
                setdvar( "night_mode", "1" );
                player iprintln( "^2[zm_qol] night mode ON" );
            }
            else
            {
                //  No argument = toggle, which is what a bind wants.
                if ( getdvarintdefault( "night_mode", 0 ) )
                {
                    setdvar( "night_mode", "0" );
                    player iprintln( "^1[zm_qol] night mode OFF" );
                }
                else
                {
                    setdvar( "night_mode", "1" );
                    player iprintln( "^2[zm_qol] night mode ON" );
                }
            }
        }
        else if ( cmd == "fog" )
        {
            //  v1.59.2 - a plain on/off toggle, nothing else.
            //
            //  The v1.57.x ".fog <number>" is deliberately NOT back. Fog
            //  DISTANCE cannot be changed on this build - checkpoint 20 §2 -
            //  and a command that pretends otherwise cost several boots. This
            //  only touches r_fog, which is the one fog control that is known
            //  to work.
            //
            //  Default is ON (see nofog_onplayerconnect). The fog CLOUD sprites
            //  stay suppressed on TranZit either way; that is FX registration in
            //  disable_fog_transition.gsc and has nothing to do with this dvar.
            str_arg = "";

            if ( tokens.size > 1 )
                str_arg = tokens[1];

            //  v1.99.91 - both front-ends write fog_enabled, which the ADVANCED
            //  tab's FOG row also drives and which scripts\zm\quality_of_life::zmqol_fog_dvar_watch()
            //  carries to r_fog. One owner, so the chat command and the menu row
            //  can never disagree, and .fog now survives a restart like the row.
            if ( str_arg == "off" )
            {
                setdvar( "fog_enabled", "0" );
                player iprintln( "^1[zm_qol] fog OFF ^7- the world edge will be visible" );
            }
            else if ( str_arg == "on" )
            {
                setdvar( "fog_enabled", "1" );
                player iprintln( "^2[zm_qol] fog ON ^7(default)" );
            }
            else
            {
                player iprintln( "^3[zm_qol] ^3.fog on ^7or ^3.fog off ^8(on by default)" );
            }
        }
        else if ( cmd == "rayhand" )
        {
            //  v2.9.34 - the controller-friendly front-end for the v2.9.31 Ray
            //  Gun floating-left-hand tunable. The console route
            //  (`zmqol_raygun_hand_ofs f r u`) went unused for two sessions -
            //  typing vectors on a pad is why - so this walks a preset ladder
            //  instead: hold the Ray Gun, type .rayhand to step through
            //  candidate viewmodel shifts (right/down combinations that push
            //  the floating hand toward the screen edge), stop on the one that
            //  hides it and report the number - it then ships as the default.
            //  .rayhand off resets; .rayhand <n> jumps; .rayhand f r u still
            //  takes a custom triple. The offsets land through the existing
            //  scripts\zm\quality_of_life::zmqol_raygun_hand_watch() poll (applies only while a Ray Gun is
            //  held, resets on switch), so this branch only writes the dvar.
            //  Deliberately NOT in .help - it is a tuning tool, gone once the
            //  winning value is known.
            a_presets = [];
            a_presets[a_presets.size] = "0 1 -1";
            a_presets[a_presets.size] = "0 2 -2";
            a_presets[a_presets.size] = "0 3 -2";
            a_presets[a_presets.size] = "0 4 -3";
            a_presets[a_presets.size] = "1 2 -2";
            a_presets[a_presets.size] = "2 3 -2";
            a_presets[a_presets.size] = "0 2 0";
            a_presets[a_presets.size] = "0 0 -3";

            str_arg = "";

            if ( tokens.size > 1 )
                str_arg = tokens[1];

            if ( tokens.size >= 4 )
            {
                str_set = tokens[1] + " " + tokens[2] + " " + tokens[3];
                setdvar( "zmqol_raygun_hand_ofs", str_set );
                level.zmqol_rayhand_idx = undefined;
                player iprintln( "^2[zm_qol] Ray Gun hand offset ^7" + str_set + " ^8(custom - hold the Ray Gun)" );
            }
            else if ( str_arg == "off" || str_arg == "0" )
            {
                setdvar( "zmqol_raygun_hand_ofs", "0 0 0" );
                level.zmqol_rayhand_idx = undefined;
                player iprintln( "^1[zm_qol] Ray Gun hand offset OFF ^7(stock view)" );
            }
            else
            {
                if ( str_arg != "" && int( str_arg ) >= 1 && int( str_arg ) <= a_presets.size )
                    n_idx = int( str_arg ) - 1;
                else if ( isdefined( level.zmqol_rayhand_idx ) )
                    n_idx = ( level.zmqol_rayhand_idx + 1 ) % a_presets.size;
                else
                    n_idx = 0;

                level.zmqol_rayhand_idx = n_idx;
                setdvar( "zmqol_raygun_hand_ofs", a_presets[n_idx] );
                player iprintln( "^2[zm_qol] Ray Gun hand preset ^3" + ( n_idx + 1 ) + "^7/" + a_presets.size + " (" + a_presets[n_idx] + ")" );
                player iprintln( "^8hold the Ray Gun - ^3.rayhand ^8again for next, ^3.rayhand off ^8to reset" );
            }
        }
        else if ( cmd == "brutus" || cmd == "panzer" || cmd == "jumpingjacks" || cmd == "jacks" )
        {
            //  User, 2026-08-13: ".brutus (amount)" on Mob, ".panzer (amount)" on
            //  Origins, ".jumpingjacks (amount)" on Die Rise, plus console dvars.
            //
            //  🛑 THIS BRANCH MAY NOT NAME A SINGLE BOSS FUNCTION. _zm_ai_brutus,
            //  _zm_ai_mechz and _zm_ai_leaper are MAP-SPECIFIC scripts, and a
            //  qualified reference to one resolves at SCRIPT LOAD time - so
            //  naming any of them from this root file would throw "Unresolved
            //  external" and crash every OTHER map, and a runtime
            //  `if ( level.script == ... )` guard does not prevent it
            //  (AI_CONTEXT rule 2). The call therefore goes through a pointer
            //  that each map's own script installs in its scripts\zm\quality_of_life::init().
            n_amount = 1;

            if ( tokens.size > 1 && int( tokens[1] ) > 0 )
                n_amount = int( tokens[1] );

            player scripts\zm\quality_of_life::zmqol_boss_spawn_request( cmd, n_amount );
        }
        else if ( cmd == "machines" || cmd == "dropmachines" )
        {
            //  User, 2026-08-19: drop every remaining Nuketown perk machine and
            //  the Pack-a-Punch on demand, "regardless of what option was set in
            //  the pre-game lobby menu, for dev testing purposes mainly."
            //
            //  🛑 SAME RULE AS THE BOSS COMMANDS ABOVE - this branch may not name
            //  maps\mp\zm_nuked_perks or anything else Nuketown-only. Such a
            //  reference resolves at SCRIPT LOAD, and this file loads on every
            //  map, so it would be an Unresolved external everywhere else and a
            //  runtime level.script guard would not help (AI_CONTEXT rule 2).
            //  scripts\zm\zm_nuked\zm_nuked.gsc installs the pointer in its
            //  scripts\zm\quality_of_life::init(); on any other map it is simply undefined.
            if ( !isdefined( level.zmqol_drop_all_machines_func ) )
            {
                player iprintln( "^1[zm_qol] ^7.machines ^1is Nuketown only" );
                continue;
            }

            n_dropped = level [[ level.zmqol_drop_all_machines_func ]]();

            if ( isdefined( n_dropped ) && n_dropped > 0 )
                player iprintln( "^2[zm_qol] dropping the last ^7" + n_dropped + "^2 machine(s)" );
            else
                player iprintln( "^3[zm_qol] every machine is already down" );
        }
        else if ( cmd == "velocity" || cmd == "vel" || cmd == "speed" )
        {
            //  User, 2026-08-13, pointing at T6-B2OP-PATCH.
            //
            //  🛑 THE METER IS NOT IN THAT PATCH. b2op.gsc has no velocity meter;
            //  its README only documents the stat slot that toggles B2FR's one,
            //  and B2FR is a separate repo that is not in the workspace. So this
            //  is written, not ported. What B2OP did supply is the HUD shape -
            //  its coordinates readout (b2op.gsc:5279-5301) uses setvalue() on a
            //  numeric hudelem rather than settext per tick, which is also this
            //  project's own rule (settext every frame floods reliable commands
            //  and throws EXE_SERVERCOMMANDOVERFLOW).
            str_arg = "";

            if ( tokens.size > 1 )
                str_arg = tokens[1];

            if ( str_arg == "off" )
                player scripts\zm\quality_of_life::zmqol_velocity_set( 0 );
            else if ( str_arg == "on" )
                player scripts\zm\quality_of_life::zmqol_velocity_set( 1 );
            else
                player iprintln( "^3[zm_qol] ^3.velocity on ^7or ^3.velocity off ^8(off by default)" );
        }
        else if ( cmd == "fly" )
        {
            //  setdvar keeps the "fly" console dvar in step with reality -
            //  scripts\zm\quality_of_life::zmqol_fly_dvar_watch() compares against the real state, so a
            //  stale dvar here would have the next poll undo this toggle a
            //  quarter-second later.
            if ( isdefined( player.zmqol_fly ) && player.zmqol_fly )
            {
                player.zmqol_fly = 0;
                player notify( "zmqol_fly_off" );
                setdvar( "fly", "0" );
                player iprintln( "^1[zm_qol] fly OFF" );
            }
            else
            {
                player.zmqol_fly = 1;
                player thread scripts\zm\quality_of_life::zmqol_fly_think();
                setdvar( "fly", "1" );
                player iprintln( "^2[zm_qol] fly ON ^7- WASD to move, JUMP up, STANCE down, SPRINT boost" );
            }
        }
        else if ( cmd == "bottomlessclip" || cmd == "bclip" )
        {
            //  🛑 v1.97.0 - THE DVAR IS WRITTEN BACK, AND WITHOUT THIS LINE THE
            //  COMMAND CANNOT WORK AT ALL.
            //
            //  User, 2026-08-16: *"some chat commands aren't working, so far
            //  it's only infammo because of the menu options"* - with a
            //  screenshot showing "infinite ammo ON" immediately followed by
            //  "infinite ammo OFF".
            //
            //  🌟 THE MECHANISM, EXACTLY. scripts\zm\quality_of_life::zmqol_toggle_dvar_watch() polls
            //  `bottomless_clip` every 0.25s and drives self.zmqol_bclip from
            //  it. This branch set the FIELD and never the DVAR, so the very
            //  next poll saw want=0, is=1, and switched it straight back off -
            //  printing the OFF line the user photographed. The menu row was
            //  never the villain; it is simply the other writer of the one dvar
            //  that is the state.
            //
            //  .god, .ghost and .hud were given this same line in v1.95.0 for
            //  the identical reason. These two were missed. One owner (the
            //  watcher), two front-ends (menu row and chat command).
            //
            //  📝 The dvar is global while the field is per-player, so in co-op
            //  this turns it on for everyone - the same contract .god and
            //  .ghost already have, and this mod is a private-match mod.
            if ( isdefined( player.zmqol_bclip ) && player.zmqol_bclip )
            {
                player.zmqol_bclip = 0;
                player notify( "zmqol_bclip_off" );
                setdvar( "bottomless_clip", "0" );
                player iprintln( "^1[zm_qol] bottomless clip OFF" );
            }
            else
            {
                player.zmqol_bclip = 1;
                player thread scripts\zm\quality_of_life::zmqol_bottomless_clip_think();
                setdvar( "bottomless_clip", "1" );
                player iprintln( "^2[zm_qol] bottomless clip ON ^7- you never reload" );
            }
        }
        else if ( cmd == "infiniteammo" || cmd == "infammo" )
        {
            //  v2.15.53 - the reserves-only half of the old .infammo. See the
            //  note above scripts\zm\quality_of_life::zmqol_infinite_ammo_think() for why the two are
            //  separate commands now. Same write-the-dvar-back rule as every
            //  other toggle here.
            if ( isdefined( player.zmqol_infammo ) && player.zmqol_infammo )
            {
                player.zmqol_infammo = 0;
                player notify( "zmqol_infammo_off" );
                setdvar( "infinite_ammo", "0" );
                player iprintln( "^1[zm_qol] infinite ammo OFF" );
            }
            else
            {
                player.zmqol_infammo = 1;
                player thread scripts\zm\quality_of_life::zmqol_infinite_ammo_think();
                setdvar( "infinite_ammo", "1" );
                player iprintln( "^2[zm_qol] infinite ammo ON ^7- reserves never empty, you still reload" );
            }
        }
        else if ( cmd == "thundergun" || cmd == "zeus" )
        {
            player scripts\zm\quality_of_life::zmqol_give_wonder_weapon( "thundergun_zm", "2", "Thundergun" );
        }
        else if ( cmd == "wunderwaffe" || cmd == "dg2" || cmd == "tesla" )
        {
            player scripts\zm\quality_of_life::zmqol_give_wonder_weapon( "tesla_gun_zm", "3", "Wunderwaffe DG-2" );
        }
        else if ( cmd == "wintershowl" || cmd == "winters" || cmd == "freezegun" )
        {
            player scripts\zm\quality_of_life::zmqol_give_wonder_weapon( "freezegun_zm", "4", "Winter's Howl" );
        }
        else if ( cmd == "wavegun" || cmd == "zapgun" || cmd == "zapguns" || cmd == "microwave" || cmd == "mgun" )
        {
            //  v2.10.14 - the box weapon is the dual pair; the engine brings the
            //  left-hand half and the combined Wave Gun with it off the def's
            //  DualWieldWeapon / altWeapon fields (zapgun.gsc banner).
            player scripts\zm\quality_of_life::zmqol_give_wonder_weapon( "microwavegundw_zm", "5", "Wave Gun" );
        }
        else if ( cmd == "testsound" )
        {
            //  B-RISERSOUND instrument (v1.99.8). The work happens CLIENT-side -
            //  see zmqol_testsound_watch() at the bottom of zm_expanded.csc for
            //  what it plays and how to read the result. All this does is hand
            //  the alias name across.
            //
            //  🛑 setclientdvar, NOT setdvar. The riser sound is played by a
            //  CLIENT script, so the test has to happen there to be a fair test;
            //  a server dvar never reaches the client. One reliable command per
            //  invocation, on demand only - ERROR_CATALOGUE §7b is about
            //  sustained emitters, not one-shots.
            //
            //  The counter is what makes asking for the SAME alias twice work:
            //  the watcher fires on a CHANGE, and "zmb_zombie_spawn" set twice
            //  is not a change. The client takes token 0 and ignores the rest.
            str_alias = "zmb_zombie_spawn";

            if ( tokens.size > 1 )
                str_alias = tokens[1];

            if ( !isdefined( level.zmqol_testsound_n ) )
                level.zmqol_testsound_n = 0;

            level.zmqol_testsound_n++;

            player setclientdvar( "zmqol_testsound", str_alias + " " + level.zmqol_testsound_n );
            player iprintln( "^2[zm_qol] testsound ^7" + str_alias + " ^2-> 2D, then 3D, then the control" );
        }
        //  ====================================================================
        //  v2.8.3 PROBE B - ".snd"  the SERVER half of the silent-gun question.
        //
        //  WHY THIS EXISTS. Every offline check says the sound chain is intact:
        //  the shipped mod.all declares 581 aliases over 368 payloads, the count
        //  the alias table needs is exactly 368, wpn_ak47_fire_plr is declared
        //  WITH its audio in the bank, and the ak47_zm weapon asset inside
        //  mod.ff references that exact alias string. Two theories were killed
        //  by measurement (a filename-extension mismatch, and the shared duck) -
        //  the known-WORKING Death Machine alias has the identical shape to the
        //  silent AK-47. So the break is at runtime and cannot be reached from
        //  disk.
        //
        //  .testsound already covers the CLIENT half. This is the server half,
        //  plus the one fact no dump can give: which weapon def is actually in
        //  the player's hands when the gun sounds silent.
        //
        //  HOW TO READ IT - run all three:
        //      .snd                      -> names the gun you are holding
        //      .snd wpn_vulcan_fire_loop_plr   (the CONTROL - known audible)
        //      .snd wpn_ak47_fire_plr          (a silent gun)
        //
        //    control plays, ak47 silent  -> the alias does not resolve at
        //        runtime even though it is in mod.all: a bank load-order or
        //        shadowing problem, NOT the alias table.
        //    both play                   -> the aliases are fine and the weapon
        //        asset's own fireSound binding is what is broken.
        //    neither plays               -> mod.all is not being loaded at all.
        //
        //  🛑 One-shot, on demand only - ERROR_CATALOGUE §7b is about sustained
        //  emitters. Remove once the cause is named.
        //  ====================================================================
        else if ( cmd == "snd" )
        {
            str_cur = player getcurrentweapon();

            if ( tokens.size < 2 )
            {
                player iprintln( "^3[zm_qol] holding: ^7" + str_cur );
                player iprintln( "^3[zm_qol] usage ^7.snd <alias>  ^3control ^7.snd wpn_vulcan_fire_loop_plr" );
            }
            else
            {
                str_alias = tokens[1];

                //  Both server routes, because they fail differently: playsound
                //  is entity-attached and playsoundatposition is world-placed,
                //  and an alias with a bad 3D curve can be inaudible on one and
                //  fine on the other.
                player playsound( str_alias );
                playsoundatposition( str_alias, player.origin );

                player iprintln( "^2[zm_qol] .snd ^7" + str_alias + "  ^2(holding ^7" + str_cur + "^2)" );
                println( "[zm_qol] PROBE B .snd alias=" + str_alias + " holding=" + str_cur );
            }
        }
        else if ( cmd == "give" || cmd == "giveweapon" || cmd == "gun" )
        {
            //  v1.93.0 - user, 2026-08-14: "make sure that all the added weapons
            //  have console commands to give myself the weapons, so i can
            //  instead of spamming the box for half an hour and praying i get
            //  the weapon i wanna test, i can just give myself it".
            //      .give swat        base
            //      .give swat pap    Pack-a-Punched
            //      .give list        every name it accepts
            if ( tokens.size < 2 )
            {
                player iprintln( "^3[zm_qol] usage: ^7.give <weapon> [pap]   ^3try ^7.give list" );
                continue;
            }

            b_pap = tokens.size > 2 && ( tokens[2] == "pap" || tokens[2] == "packed" || tokens[2] == "upgraded" );
            player scripts\zm\quality_of_life::zmqol_give_named_weapon( tokens[1], b_pap );
        }
        else if ( cmd == "infinitesprint" || cmd == "infsprint" )
        {
            //  v1.97.0 - writes `infinite_sprint` back, same fix and the same
            //  reason as .infammo / .bclip further up this listener. It had the
            //  identical defect and would have been the next command reported.
            if ( isdefined( player.zmqol_infsprint ) && player.zmqol_infsprint )
            {
                player.zmqol_infsprint = 0;
                player notify( "zmqol_infsprint_off" );
                player unsetperk( "specialty_unlimitedsprint" );
                setdvar( "infinite_sprint", "0" );
                player iprintln( "^1[zm_qol] infinite sprint OFF" );
            }
            else
            {
                player.zmqol_infsprint = 1;
                player thread scripts\zm\quality_of_life::zmqol_infinite_sprint_think();
                setdvar( "infinite_sprint", "1" );
                player iprintln( "^2[zm_qol] infinite sprint ON" );
            }
        }
        else if ( cmd == "reload" )
        {
            player scripts\zm\quality_of_life::zmqol_fill_all_ammo();
            player iprintln( "^2[zm_qol] ^7all weapons and equipment refilled" );
        }
        else if ( cmd == "nozmspawns" )
        {
            //  "spawn_zombies" is the stock flag round_spawning() waits on, once
            //  per spawn, at _zm.gsc:2973 - clearing it parks that loop before it
            //  picks a spawn point. flag_init( "spawn_zombies", 1 ) is at :1135.
            //
            //  🛑 v2.11.0 - IT NOW TAKES AN EXPLICIT on/off, and that is the whole
            //  of the 2026-09-03 "it didn't work" report. The log shows the
            //  command was typed twice in a row - OFF, then straight back ON - so
            //  the state the user was left in was ON, which is exactly what the
            //  screenshot's red "zombie spawning ON" says. A bare toggle cannot
            //  survive a double tap or a repeated bind, so both spellings exist:
            //      .nozmspawns off / on     explicit, idempotent, always correct
            //      .nozmspawns              flips, as before
            //
            //  And OFF now STAYS off: _hostmigration.gsc sets this flag again on
            //  every migration, so a keeper thread re-clears it until the user
            //  turns spawning back on.
            b_want = !( isdefined( level.zmqol_nospawns ) && level.zmqol_nospawns );

            if ( tokens.size > 1 )
            {
                if ( tokens[1] == "off" || tokens[1] == "0" || tokens[1] == "stop" )
                    b_want = 1;
                else if ( tokens[1] == "on" || tokens[1] == "1" || tokens[1] == "go" )
                    b_want = 0;
            }

            if ( b_want )
            {
                level.zmqol_nospawns = 1;
                flag_clear( "spawn_zombies" );
                level thread scripts\zm\quality_of_life::zmqol_nospawns_keeper();
                player iprintln( "^2[zm_qol] zombie spawning OFF ^7- existing zombies remain (^3.nozmspawns on^7)" );
            }
            else
            {
                level.zmqol_nospawns = 0;
                level notify( "zmqol_nospawns_off" );
                flag_set( "spawn_zombies" );
                player iprintln( "^1[zm_qol] zombie spawning ON" );
            }
        }
        else if ( cmd == "where" )
        {
            //  v1.40.1: reports YAW as well as position. A coordinate alone is
            //  half an answer when the thing being placed is a machine - it has
            //  to face out of the wall, and "back left corner" in a screenshot
            //  cannot be resolved without knowing which way the camera was
            //  pointing. Stand where you want it, face the way it should face,
            //  and this one line is now the whole spec.
            v_pos = player.origin;
            v_ang = player getplayerangles();
            n_yaw = int( v_ang[1] );

            if ( n_yaw < 0 )
                n_yaw += 360;

            player iprintln( "^2[zm_qol] ^7x " + int( v_pos[0] ) + "  y " + int( v_pos[1] ) + "  z " + int( v_pos[2] ) + "  ^2yaw ^7" + n_yaw );
            println( "[zm_qol] WHERE " + level.script + " (" + v_pos[0] + ", " + v_pos[1] + ", " + v_pos[2] + ") yaw " + n_yaw );
        }
        else if ( cmd == "boxhere" )
        {
            //  v2.14.25 - a placement probe for a location's moved mystery box:
            //  stand where you would use it, face the wall, and the location's
            //  own handler (level.zmqol_box_here_func, set by e.g.
            //  scripts\zm\locs\zm_tomb_loc_crazy_place.gsc) moves the box there
            //  and prints the numbers to bake. A level pointer, never a
            //  qualified reference: this file loads on every map.
            if ( isdefined( level.zmqol_box_here_func ) )
                [[ level.zmqol_box_here_func ]]( player );
            else
                player iprintln( "^1[zm_qol] .boxhere ^7- nothing to move on this map/location" );
        }
        else if ( cmd == "wallhere" )
        {
            //  v2.15.42 - a measurement probe for a future wall-buy: stand
            //  where you would buy it, face the wall at buy height, and the
            //  location's own handler (level.zmqol_wall_here_func, set by e.g.
            //  scripts\zm\locs\zm_tomb_loc_crazy_place.gsc) traces the face
            //  and prints the numbers to bake. Measurement only - structs are
            //  load-time, so nothing moves live. A level pointer, never a
            //  qualified reference: this file loads on every map.
            if ( isdefined( level.zmqol_wall_here_func ) )
                [[ level.zmqol_wall_here_func ]]( player );
            else
                player iprintln( "^1[zm_qol] .wallhere ^7- no wall-buy probe on this map/location" );
        }
        else if ( cmd == "giveperks" )
        {
            n_given = player scripts\zm\quality_of_life::zmqol_give_all_perks();
            player iprintln( "^2[zm_qol] ^7gave " + n_given + " perk(s)" );
        }
        else if ( cmd == "removeperks" )
        {
            n_taken = player scripts\zm\quality_of_life::zmqol_remove_all_perks();
            player iprintln( "^1[zm_qol] ^7removed " + n_taken + " perk(s)" );
        }
        //  🛑 THESE TWO MUST STAY BELOW giveperks / removeperks. "giveperks"
        //  starts with "give", so a prefix test placed above would swallow it
        //  and never reach the all-perks handler. The else-if chain is the
        //  ordering guarantee - do not reorder these four blocks.
        else if ( cmd.size > 4 && getsubstr( cmd, 0, 4 ) == "give" && isdefined( scripts\zm\quality_of_life::zmqol_perk_from_alias( getsubstr( cmd, 4, cmd.size ) ) ) )
        {
            perk = scripts\zm\quality_of_life::zmqol_perk_from_alias( getsubstr( cmd, 4, cmd.size ) );
            player scripts\zm\quality_of_life::zmqol_give_one_perk( perk );
        }
        else if ( cmd.size > 6 && getsubstr( cmd, 0, 6 ) == "remove" && isdefined( scripts\zm\quality_of_life::zmqol_perk_from_alias( getsubstr( cmd, 6, cmd.size ) ) ) )
        {
            perk = scripts\zm\quality_of_life::zmqol_perk_from_alias( getsubstr( cmd, 6, cmd.size ) );
            player scripts\zm\quality_of_life::zmqol_remove_one_perk( perk );
        }
        //  ====================================================================
        //  v1.99.25 - the six commands taken from the ezz_server release that
        //  this mod did NOT already have. Everything else it offers was already
        //  here under a different name and is deliberately NOT duplicated:
        //    !help=.help  !pap=.pack  !round=.round  !god=.god  !ignore=.ghost
        //    !points=.p   !ammo=.reload  !allperks/!perks=.giveperks
        //    !drop=.drop/.powerup
        //  and the six weapon commands (!galil !an94 !ms !monkeys !raygun !mk2)
        //  became rows in scripts\zm\quality_of_life::zmqol_weapon_give_table() instead of six new commands.
        //
        //  🛑 `!speed` is NOT ported under that name. `.speed` is already taken
        //  in this mod as an alias for the velocity HUD, and silently changing
        //  what an existing command does is worse than not adding the new one.
        //  It is `.movespeed` here.
        //
        //  🛑 Every reference below is either a builtin or a globally-safe
        //  `maps\mp\zombies\_zm*` path, and every weapon is named by STRING.
        //  Nothing map-specific is referenced by function, so AI_CONTEXT rule 2
        //  cannot bite - this is a root script and a `maps\mp\zm_tomb::` style
        //  reference here would crash every other map at load.
        //  ====================================================================
        else if ( cmd == "pay" )
        {
            if ( tokens.size < 3 )
            {
                player iprintln( "^3[zm_qol] usage: ^7.pay <player> <amount>" );
                continue;
            }

            player scripts\zm\quality_of_life::zmqol_pay_points( tokens[1], int( tokens[2] ) );
        }
        else if ( cmd == "bring" )
        {
            player scripts\zm\quality_of_life::zmqol_bring_players();
        }
        else if ( cmd == "killall" )
        {
            player scripts\zm\quality_of_life::zmqol_kill_all_zombies();
        }
        else if ( cmd == "shield" )
        {
            player scripts\zm\quality_of_life::zmqol_give_shield();
        }
        else if ( cmd == "staff" )
        {
            player scripts\zm\quality_of_life::zmqol_give_staff( tokens );
        }
        else if ( cmd == "movespeed" )
        {
            player scripts\zm\quality_of_life::zmqol_toggle_movespeed();
        }
        else if ( cmd == "pack" )
        {
            player scripts\zm\quality_of_life::zmqol_pack( 1 );
        }
        else if ( cmd == "unpack" )
        {
            player scripts\zm\quality_of_life::zmqol_pack( 0 );
        }
        else if ( cmd == "help" )
        {
            player thread scripts\zm\quality_of_life::zmqol_print_help();
        }
        else if ( cmd == "powerups" )
        {
            player thread scripts\zm\quality_of_life::zmqol_list_powerups();
        }
        else if ( cmd == "powerup" || cmd == "drop" )
        {
            // Bare ".powerup" lists what this map actually registered, which is
            // the only reliable way to know - the set differs per map.
            if ( tokens.size < 2 )
            {
                player thread scripts\zm\quality_of_life::zmqol_list_powerups();
                continue;
            }

            player scripts\zm\quality_of_life::zmqol_spawn_powerup( tokens[1] );
        }
        else
        {
            // Fall-through: short forms (".nuke", ".maxammo", ".dm") resolve
            // through the same lookup, so there is exactly one spawn path.
            str_powerup = scripts\zm\quality_of_life::zmqol_powerup_alias( cmd );

            if ( isdefined( str_powerup ) )
                player scripts\zm\quality_of_life::zmqol_spawn_powerup( str_powerup );
            else
            {
                //  🛑 v2.11.0 - AN UNKNOWN COMMAND USED TO DO NOTHING AT ALL, AND
                //  IT COST A BUG REPORT. The 2026-09-03 log has, in order:
                //      DavidHiFi: .nozmpsawns      <- transposed, silently ignored
                //      DavidHiFi: .killall
                //      DavidHiFi: .nozmspawns      <- OFF
                //      DavidHiFi: .nozmspawns      <- straight back ON
                //  and the report that followed was ".nozmspawns didn't work,
                //  zombies kept spawning in". A typo that prints nothing is
                //  indistinguishable from a command that ran and failed, so every
                //  unrecognised word now says so. Chat that merely starts with a
                //  prefix character is not a command, so this only fires on a
                //  single token of plausible command shape - no reply to "..." or
                //  to a sentence.
                if ( tokens.size == 1 && cmd.size >= 2 && cmd.size <= 20 )
                    player iprintln( "^1[zm_qol] unknown command ^7." + cmd + "  ^7- type ^3.help" );
            }
        }
    }
}

