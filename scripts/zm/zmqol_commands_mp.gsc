// Multiplayer permissions and name matcher, built on the command-table-mp layer.
// sv_cheats is the host's single mode switch. Off is no-cheat mode; grants
// live on the player entity and expire on disconnect. Utilities stay open.
// This policy always runs: zmqol_commands_mp is no longer a bypass switch.

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;

zmqol_commands_mp_init()
{
    zmqol_mp_table_build();
    level thread zmqol_mp_mode_watch();
}

zmqol_mp_cheat_mode()
{
    return getdvarintdefault( "sv_cheats", 0 ) == 1;
}

// utility rows always run. self rows require cheat mode or a named grant.
// host rows also require the caller to be the engine's current host.
zmqol_mp_table_build()
{
    level.zmqol_mp_names = [];
    level.zmqol_mp_canon = [];
    level.zmqol_mp_levels = [];
    level.zmqol_mp_target = [];

    // Self cheats and utilities from the existing open list.
    zmqol_mp_row( "give", "", "self", 0 );
    zmqol_mp_row( "giveweapon", "give", "self", 0 );
    zmqol_mp_row( "gun", "give", "self", 0 );
    zmqol_mp_row( "pack", "", "self", 0 );
    zmqol_mp_row( "unpack", "", "self", 0 );
    zmqol_mp_row( "pay", "", "utility", 0 );
    zmqol_mp_row( "character", "", "utility", 0 );
    zmqol_mp_row( "char", "character", "utility", 0 );
    zmqol_mp_row( "help", "", "utility", 0 );
    zmqol_mp_row( "where", "", "utility", 0 );
    zmqol_mp_row( "wallhere", "", "utility", 0 );
    zmqol_mp_row( "reload", "", "self", 1 );
    zmqol_mp_row( "giveperks", "", "self", 1 );
    zmqol_mp_row( "removeperks", "", "self", 1 );
    zmqol_mp_row( "movespeed", "", "self", 0 );
    zmqol_mp_row( "velocity", "", "utility", 0 );
    zmqol_mp_row( "vel", "velocity", "utility", 0 );
    zmqol_mp_row( "speed", "velocity", "utility", 0 );
    zmqol_mp_row( "afk", "", "utility", 1 );
    zmqol_mp_row( "my", "", "utility", 0 );
    zmqol_mp_row( "popt", "my", "utility", 0 );
    zmqol_mp_row( "mine", "my", "utility", 0 );
    zmqol_mp_row( "hud", "", "utility", 0 );
    zmqol_mp_row( "powerups", "", "utility", 0 );

    // Points are self-scoped for guests; the host may still name a target.
    zmqol_mp_row( "p", "", "self", 0 );

    //  ---- host: everything the old gate kept for itself ----
    zmqol_mp_row( "round", "", "host", 0 );
    zmqol_mp_row( "setround", "round", "host", 0 );
    zmqol_mp_row( "endround", "", "host", 0 );
    zmqol_mp_row( "wwfx", "", "host", 1 );
    zmqol_mp_row( "god", "", "host", 1 );
    zmqol_mp_row( "ghost", "", "host", 1 );
    zmqol_mp_row( "nightmode", "", "host", 0 );
    zmqol_mp_row( "night", "nightmode", "host", 0 );
    zmqol_mp_row( "fog", "", "host", 0 );
    zmqol_mp_row( "rayhand", "", "host", 0 );
    zmqol_mp_row( "brutus", "", "host", 0 );
    zmqol_mp_row( "panzer", "", "host", 0 );
    zmqol_mp_row( "jumpingjacks", "", "host", 0 );
    zmqol_mp_row( "jacks", "jumpingjacks", "host", 0 );
    zmqol_mp_row( "machines", "", "host", 0 );
    zmqol_mp_row( "dropmachines", "machines", "host", 0 );
    zmqol_mp_row( "fly", "", "host", 1 );
    zmqol_mp_row( "bottomlessclip", "", "host", 1 );
    zmqol_mp_row( "bclip", "bottomlessclip", "host", 1 );
    zmqol_mp_row( "infiniteammo", "", "host", 1 );
    zmqol_mp_row( "infammo", "infiniteammo", "host", 1 );
    zmqol_mp_row( "thundergun", "", "host", 0 );
    zmqol_mp_row( "zeus", "thundergun", "host", 0 );
    zmqol_mp_row( "wunderwaffe", "", "host", 0 );
    zmqol_mp_row( "dg2", "wunderwaffe", "host", 0 );
    zmqol_mp_row( "tesla", "wunderwaffe", "host", 0 );
    zmqol_mp_row( "wintershowl", "", "host", 0 );
    zmqol_mp_row( "winters", "wintershowl", "host", 0 );
    zmqol_mp_row( "freezegun", "wintershowl", "host", 0 );
    zmqol_mp_row( "wavegun", "", "host", 0 );
    zmqol_mp_row( "zapgun", "wavegun", "host", 0 );
    zmqol_mp_row( "zapguns", "wavegun", "host", 0 );
    zmqol_mp_row( "microwave", "wavegun", "host", 0 );
    zmqol_mp_row( "mgun", "wavegun", "host", 0 );
    zmqol_mp_row( "testsound", "", "host", 0 );
    zmqol_mp_row( "snd", "", "host", 0 );
    zmqol_mp_row( "infinitesprint", "", "host", 1 );
    zmqol_mp_row( "infsprint", "infinitesprint", "host", 1 );
    zmqol_mp_row( "nozmspawns", "", "host", 0 );
    zmqol_mp_row( "boxhere", "", "host", 0 );
    zmqol_mp_row( "bring", "", "host", 0 );
    zmqol_mp_row( "killall", "", "host", 0 );
    zmqol_mp_row( "shield", "", "host", 0 );
    zmqol_mp_row( "staff", "", "host", 0 );
    zmqol_mp_row( "powerup", "", "host", 0 );
    zmqol_mp_row( "drop", "powerup", "host", 0 );

    zmqol_mp_row( "cheats", "", "host", 0 );
    zmqol_mp_row( "cheatrow", "cheats", "host", 0 );

    //  ---- host: the phase 3 grants store, chat edition ----
    zmqol_mp_row( "grant", "", "host", 0 );
    zmqol_mp_row( "ungrant", "", "host", 0 );
    zmqol_mp_row( "grants", "", "host", 0 );
}

zmqol_mp_row( str_name, str_canon, str_level, n_targetable )
{
    level.zmqol_mp_names[level.zmqol_mp_names.size] = str_name;
    level.zmqol_mp_canon[level.zmqol_mp_canon.size] = str_canon;
    level.zmqol_mp_levels[level.zmqol_mp_levels.size] = str_level;
    level.zmqol_mp_target[level.zmqol_mp_target.size] = n_targetable;
}

zmqol_mp_index( str_cmd )
{
    for ( i = 0; i < level.zmqol_mp_names.size; i++ )
    {
        if ( level.zmqol_mp_names[i] == str_cmd )
            return i;
    }

    return -1;
}

// Canonical grants apply to aliases and the perk/power-up alias families.
zmqol_mp_canonical( str_cmd )
{
    n_i = zmqol_mp_index( str_cmd );
    if ( n_i >= 0 )
    {
        if ( level.zmqol_mp_canon[n_i] != "" )
            return level.zmqol_mp_canon[n_i];
        return str_cmd;
    }
    if ( str_cmd.size > 4 && getsubstr( str_cmd, 0, 4 ) == "give" && isdefined( scripts\zm\quality_of_life::zmqol_perk_from_alias( getsubstr( str_cmd, 4, str_cmd.size ) ) ) )
        return "giveperks";
    if ( str_cmd.size > 6 && getsubstr( str_cmd, 0, 6 ) == "remove" && isdefined( scripts\zm\quality_of_life::zmqol_perk_from_alias( getsubstr( str_cmd, 6, str_cmd.size ) ) ) )
        return "removeperks";
    if ( isdefined( scripts\zm\quality_of_life::zmqol_powerup_alias( str_cmd ) ) )
        return "powerup";
    return str_cmd;
}

zmqol_mp_granted( e_player, str_cmd )
{
    return isdefined( e_player.zmqol_mp_grants ) && isdefined( e_player.zmqol_mp_grants[str_cmd] ) && e_player.zmqol_mp_grants[str_cmd] == 1;
}

// Empty means allowed; otherwise return the one-line refusal for the speaker.
zmqol_mp_refusal( e_player, str_cmd )
{
    str_cmd = zmqol_mp_canonical( str_cmd );
    n_i = zmqol_mp_index( str_cmd );
    str_level = "host";
    if ( n_i >= 0 )
        str_level = level.zmqol_mp_levels[n_i];
    if ( str_level == "utility" )
        return "";
    e_host = gethostplayer();
    if ( str_level == "host" && ( !isdefined( e_host ) || e_player != e_host ) )
        return "is host only";
    if ( str_cmd == "grant" || str_cmd == "ungrant" || str_cmd == "grants" )
        return "";
    if ( !zmqol_mp_cheat_mode() && !zmqol_mp_granted( e_player, str_cmd ) )
        return "cheats are off in this game; ask the host for a grant";
    return "";
}

// ============================================================================
//  THE DISPATCHER
//
//  Called from zmqol_dev_command_listener() after the prefix and token parse,
//  before the old open-list gate. Returns 1 only when this layer consumed the
//  line; 0 hands the line to the old chain untouched.
// ============================================================================
zmqol_mp_dispatch( e_player, str_cmd, a_tokens )
{
    str_reason = zmqol_mp_refusal( e_player, str_cmd );
    if ( str_reason != "" )
    {
        e_player iprintln( "^1[zm_qol] ^7." + str_cmd + " ^1" + str_reason );
        return 1;
    }
    n_i = zmqol_mp_index( zmqol_mp_canonical( str_cmd ) );
    if ( str_cmd == "cheatrow" )
    {
        zmqol_mp_cmd_cheatrow( e_player, a_tokens );
        return 1;
    }
    if ( str_cmd == "cheats" )
    {
        e_player iprintln( "^3[zm_qol] use the CHEATS page" );
        return 1;
    }

    if ( str_cmd == "p" )
    {
        zmqol_mp_cmd_p( e_player, a_tokens );
        return 1;
    }

    if ( str_cmd == "pay" )
        return zmqol_mp_cmd_pay( e_player, a_tokens );

    if ( str_cmd == "grant" )
    {
        zmqol_mp_cmd_grant( e_player, a_tokens );
        return 1;
    }

    if ( str_cmd == "ungrant" )
    {
        zmqol_mp_cmd_ungrant( e_player, a_tokens );
        return 1;
    }

    if ( str_cmd == "grants" )
    {
        zmqol_mp_cmd_grants( e_player );
        return 1;
    }

    //  The target grammar is declared on the entity-local rows but delivered
    //  by the per-player update (phase 3). Until then an explicit non-me
    //  target is refused with the reason, and "me" falls through harmlessly -
    //  these bodies take no arguments and ignore the extra token.
    if ( n_i >= 0 && level.zmqol_mp_target[n_i] == 1 && a_tokens.size > 1 )
    {
        str_t = tolower( a_tokens[1] );

        if ( str_t != "me" )
        {
            e_player iprintln( "^3[zm_qol] ^7." + str_cmd + " <player> ^7is not available yet - it runs for you only" );
            return 1;
        }
    }

    return 0;
}

//  .p [amount] [player]. Only the host may name somebody else. The
//  amount default and the int()-of-junk rule are the old branch's; points are
//  per-entity, so this can name another player on day one.
zmqol_mp_cmd_p( e_caller, a_tokens )
{
    n_amount = 1000;
    str_name = "";

    if ( a_tokens.size > 1 )
    {
        if ( zmqol_mp_is_number( a_tokens[1] ) && int( a_tokens[1] ) != 0 )
            n_amount = int( a_tokens[1] );
        else
            str_name = a_tokens[1];

        if ( a_tokens.size > 2 )
            str_name = a_tokens[2];
    }

    e_target = e_caller;

    if ( str_name != "" && str_name != "me" )
    {
        a_hits = zmqol_mp_resolve_player( e_caller, str_name );

        if ( a_hits.size != 1 )
            return;

        e_target = a_hits[0];
    }

    if ( e_target != e_caller && e_caller != gethostplayer() )
    {
        e_caller iprintln( "^1[zm_qol] .p runs for you only; use .pay for a teammate" );
        return;
    }

    if ( e_target == e_caller )
    {
        e_caller maps\mp\zombies\_zm_score::add_to_player_score( n_amount, 1 );
        e_caller iprintln( "^2[zm_qol] ^7points ^2+" + n_amount );
        return;
    }

    e_target maps\mp\zombies\_zm_score::add_to_player_score( n_amount, 1 );
    e_caller iprintln( "^2[zm_qol] gave ^7" + n_amount + "^2 points to ^7" + e_target.name );
    e_target iprintln( "^2[zm_qol] ^7" + e_caller.name + "^2 gave you ^7" + n_amount + "^2 points" );
}

//  .pay <player> <amount> - stays open (it charges the sender), but the name
//  goes through matcher v2 first. On a unique match the transfer itself is
//  still quality_of_life::zmqol_pay_points, unchanged; on an ambiguous or
//  unknown name the resolver has already replied, and the silent first-match
//  the old chain would have picked never happens.
zmqol_mp_cmd_pay( e_caller, a_tokens )
{
    if ( a_tokens.size < 3 )
        return 0;   // usage error: let the old branch print it

    a_hits = zmqol_mp_resolve_player( e_caller, a_tokens[1] );

    if ( a_hits.size != 1 )
        return 1;

    e_caller scripts\zm\quality_of_life::zmqol_pay_points( a_hits[0].name, int( a_tokens[2] ) );
    return 1;
}

// ============================================================================
//  THE GRANTS STORE (phase 3, chat edition)
//
//  .grant <player> <command> / .ungrant <player> <command> / .grants
//
//  Host-only. Grants live on the player entity (e_player.zmqol_mp_grants), so
//  a disconnect frees them with the entity and a rejoining player starts with
//  nothing - the connect and disconnect handling the plan asks for is the
//  entity's own lifetime. Aliases share a canonical grant. Host commands
//  and CHEATS rows can only be granted to the host, never a remote player.
zmqol_mp_cmd_grant( e_caller, a_tokens )
{
    if ( a_tokens.size < 3 )
    {
        e_caller iprintln( "^3[zm_qol] usage: ^7.grant <player> <command>" );
        return;
    }

    a_hits = zmqol_mp_resolve_player( e_caller, a_tokens[1] );

    if ( a_hits.size != 1 )
        return;

    e_target = a_hits[0];
    str_cmd = zmqol_mp_canonical( tolower( a_tokens[2] ) );
    n_i = zmqol_mp_index( str_cmd );

    if ( n_i < 0 || level.zmqol_mp_levels[n_i] == "utility" || str_cmd == "grant" || str_cmd == "ungrant" || str_cmd == "grants" )
    {
        e_caller iprintln( "^1[zm_qol] ^7." + str_cmd + " ^1is not a grantable command" );
        return;
    }

    if ( level.zmqol_mp_levels[n_i] == "host" && e_target != gethostplayer() )
    {
        e_caller iprintln( "^1[zm_qol] match cheats and CHEATS rows stay host only" );
        return;
    }

    if ( !isdefined( e_target.zmqol_mp_grants ) )
        e_target.zmqol_mp_grants = [];

    e_target.zmqol_mp_grants[str_cmd] = 1;

    e_caller iprintln( "^2[zm_qol] ^7." + str_cmd + " ^2granted to ^7" + e_target.name );
    e_target iprintln( "^2[zm_qol] ^7the host granted you ^2." + str_cmd );
}

zmqol_mp_cmd_ungrant( e_caller, a_tokens )
{
    if ( a_tokens.size < 3 )
    {
        e_caller iprintln( "^3[zm_qol] usage: ^7.ungrant <player> <command>" );
        return;
    }

    a_hits = zmqol_mp_resolve_player( e_caller, a_tokens[1] );

    if ( a_hits.size != 1 )
        return;

    e_target = a_hits[0];
    str_cmd = zmqol_mp_canonical( tolower( a_tokens[2] ) );

    if ( isdefined( e_target.zmqol_mp_grants ) && isdefined( e_target.zmqol_mp_grants[str_cmd] ) )
        e_target.zmqol_mp_grants[str_cmd] = undefined;

    e_caller iprintln( "^3[zm_qol] ^7." + str_cmd + " ^3taken back from ^7" + e_target.name );
    e_target iprintln( "^3[zm_qol] ^7the host took ^3." + str_cmd + " ^7back" );
}

zmqol_mp_cmd_grants( e_caller )
{
    a_players = get_players();

    for ( i = 0; i < a_players.size; i++ )
    {
        if ( !isdefined( a_players[i].name ) )
            continue;

        if ( !isdefined( a_players[i].zmqol_mp_grants ) )
        {
            e_caller iprintln( "^3[zm_qol] ^7" + a_players[i].name + "^3: no grants" );
            continue;
        }

        str_list = "";

        foreach ( str_cmd, n_on in a_players[i].zmqol_mp_grants )
        {
            if ( n_on != 1 )
                continue;

            if ( str_list != "" )
                str_list = str_list + ", ";

            str_list = str_list + "." + str_cmd;
        }

        if ( str_list == "" )
            e_caller iprintln( "^3[zm_qol] ^7" + a_players[i].name + "^3: no grants" );
        else
            e_caller iprintln( "^3[zm_qol] ^7" + a_players[i].name + "^3: " + str_list );
    }
}

// ============================================================================
//  MATCHER V2
//
//  Clan tags stripped, case-insensitive, exact match wins, then a unique
//  prefix. Two or more prefix matches reply with a numbered candidate list
//  instead of silently picking the first - that silent pick is item 6 in the
//  plan's "where it breaks" list. The tag strip is the reference Give Points
//  approach; the string indexing forms are the file's own (str_val[i] and
//  message[0] in zmqol_playeropt.gsc).
// ============================================================================
zmqol_mp_resolve_player( e_caller, str_want )
{
    a_hits = [];

    if ( !isdefined( str_want ) || str_want.size == 0 )
        return a_hits;

    a_players = get_players();
    str_want_l = tolower( str_want );
    str_want_s = tolower( zmqol_mp_strip_tag( str_want ) );

    //  Exact on the raw name or on the stripped name wins outright.
    for ( i = 0; i < a_players.size; i++ )
    {
        if ( !isdefined( a_players[i].name ) )
            continue;

        str_have = tolower( a_players[i].name );

        if ( str_have == str_want_l || zmqol_mp_strip_tag( str_have ) == str_want_s )
        {
            a_hits[0] = a_players[i];
            return a_hits;
        }
    }

    //  Prefix on either form; every hit is collected so a second match can
    //  refuse instead of guessing.
    for ( i = 0; i < a_players.size; i++ )
    {
        if ( !isdefined( a_players[i].name ) )
            continue;

        str_have = tolower( a_players[i].name );
        str_stripped = zmqol_mp_strip_tag( str_have );

        if ( str_want_l.size > 0 && str_have.size >= str_want_l.size && getsubstr( str_have, 0, str_want_l.size ) == str_want_l )
            a_hits[a_hits.size] = a_players[i];
        else if ( str_want_s.size > 0 && str_stripped.size >= str_want_s.size && getsubstr( str_stripped, 0, str_want_s.size ) == str_want_s )
            a_hits[a_hits.size] = a_players[i];
    }

    if ( a_hits.size > 1 )
    {
        e_caller iprintln( "^3[zm_qol] ^7" + str_want + " ^3matches " + a_hits.size + " players - be more specific:" );

        for ( i = 0; i < a_hits.size; i++ )
            e_caller iprintln( "^3[zm_qol] ^7 " + ( i + 1 ) + ". " + a_hits[i].name );
    }
    else if ( a_hits.size == 0 )
    {
        e_caller iprintln( "^1[zm_qol] no player matching ^7" + str_want );
    }

    return a_hits;
}

//  "[QoL] Dave" -> "Dave". Repeats so a clan-stacked name strips clean, and
//  stops on an unclosed bracket so "[QoL" survives as itself.
zmqol_mp_strip_tag( str_in )
{
    str_out = str_in;

    while ( str_out.size > 2 && str_out[0] == "[" )
    {
        n_close = -1;

        for ( i = 0; i < str_out.size; i++ )
        {
            if ( str_out[i] == "]" )
            {
                n_close = i;
                break;
            }
        }

        if ( n_close < 0 )
            break;

        str_out = getsubstr( str_out, n_close + 1, str_out.size - n_close - 1 );

        while ( str_out.size > 0 && str_out[0] == " " )
            str_out = getsubstr( str_out, 1, str_out.size - 1 );
    }

    return str_out;
}

//  Same rule as the .my parser: int() of junk is 0, which would silently read
//  as a valid amount, so the digits are checked character by character.
zmqol_mp_is_number( str_in )
{
    if ( !isdefined( str_in ) || str_in.size == 0 )
        return 0;

    for ( i = 0; i < str_in.size; i++ )
    {
        if ( !issubstr( "-0123456789", str_in[i] ) )
            return 0;
    }

    return 1;
}

// A CHEATS row uses chat instead of writing an unchecked server dvar. This
// allow-list is shared with the mode-reset list and the menu callbacks.
zmqol_mp_cheat_rows()
{
    return strTok( "godmode ghostmode infinite_ammo bottomless_clip infinite_sprint fly rapid_fire no_power one_shot_one_kill set_round kill_horde end_round set_points teleport execute_teleport", " " );
}

zmqol_mp_cmd_cheatrow( e_player, a_tokens )
{
    if ( a_tokens.size != 3 || !zmqol_mp_is_number( a_tokens[2] ) )
        return;
    a_rows = zmqol_mp_cheat_rows();
    foreach ( str_row in a_rows )
    {
        if ( str_row == a_tokens[1] )
        {
            setdvar( str_row, int( a_tokens[2] ) );
            return;
        }
    }
    e_player iprintln( "^1[zm_qol] unknown CHEATS row" );
}

zmqol_mp_reset_cheats()
{
    foreach ( str_row in zmqol_mp_cheat_rows() )
    {
        // These are selections, not running effects. Setting set_points to
        // zero would take players' earned points when mode changes.
        if ( str_row != "set_points" && str_row != "teleport" )
            setdvar( str_row, 0 );
    }
}

zmqol_mp_mode_watch()
{
    level endon( "game_ended" );
    if ( !zmqol_mp_cheat_mode() )
        zmqol_mp_reset_cheats();
    b_last_mode = zmqol_mp_cheat_mode();
    b_last_rows = 0;
    e_last_host = undefined;
    for ( ;; )
    {
        e_host = gethostplayer();
        b_rows = 0;
        if ( isdefined( e_host ) )
            b_rows = zmqol_mp_refusal( e_host, "cheats" ) == "";
        b_mode = zmqol_mp_cheat_mode();
        if ( ( b_last_mode && !b_mode ) || ( b_last_rows && !b_rows ) )
            zmqol_mp_reset_cheats();
        // This is a display hint only. Every row request is checked again
        // on the server with the actual speaking player and server sv_cheats.
        if ( isdefined( e_host ) && ( !isdefined( e_last_host ) || e_host != e_last_host || b_rows != b_last_rows ) )
            e_host setclientdvar( "zmqol_cheats_allowed", int( b_rows ) );
        e_last_host = e_host;
        b_last_mode = b_mode;
        b_last_rows = b_rows;
        wait 0.25;
    }
}
