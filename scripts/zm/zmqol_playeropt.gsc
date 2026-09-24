// ============================================================================
//  zmqol_playeropt  -  per-player option channel                    (Fix 1)
// ----------------------------------------------------------------------------
//  Root cause of most co-op Tier 1 findings: there is no per-player option
//  state. Every preference is one server dvar; one player's toggle is the
//  whole lobby's. This script is the channel. It lives HERE so
//  quality_of_life.gsc stays under its compiled-bytecode ceiling.
//
//  Reader (call from any player-scoped thread):
//      b_on = self scripts\zm\zmqol_playeropt::zmqol_popt( "hud_master", 1 );
//
//  Behaviour is identical to getdvarintdefault() until that player has set an
//  override, so each migrated call site can ship and be verified solo without
//  changing anything.
//
//  Writer — chat, any player, in-game only (listener starts at map load):
//      .my <name> <value>     set YOUR override
//      .my <name>             show current (override or server default path)
//      .my <name> clear       drop your override, follow the server dvar again
//
//  🛑 MATCH RULES ARE NOT ON THIS CHANNEL. perk_limit, pap_price, powerup
//  tables, solo_ee, round settings stay host/server dvars on purpose.
//
//  🛑 NOT A CONSOLE TWIN YET. zmqol_console_command_watcher() seeds every
//  name it owns to "" and blanks it on fire; `my` is reserved for that list
//  when someone measures quality_of_life.gsc size after adding it. Chat works
//  without touching the ceiling file.
//
//  Multiple level waittill("say") threads all see the same notify. The main
//  listener in quality_of_life.gsc ignores ".my name value" (tokens.size > 1
//  falls through with no unknown-command print). Bare ".my" may also print
//  "unknown command" from that listener — cosmetic, fixed when the console
//  twin lands.
// ============================================================================

#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;

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
