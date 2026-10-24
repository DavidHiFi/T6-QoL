#include scripts\zm\zmqol_playeropt;

init()
{
    // Stock Lua uses this menu identity for non-chat UI responses.
    precachemenu( "luisystem" );
    level thread zmqol_menu_connect();
}

zmqol_menu_connect()
{
    for ( ;; )
    {
        level waittill( "connected", player );
        player thread zmqol_menu_listen();
        player thread zmqol_menu_spawn();
    }
}

zmqol_menu_spawn()
{
    self endon( "disconnect" );
    serial = 0;
    for ( ;; )
    {
        self waittill( "spawned_player" );
        serial++;
        if ( !self zmqol_popt_is_host() )
            self setclientdvar( "zmqol_popt_sync", gettime() + "_" + serial );
    }
}

// Return undefined for every unknown name, malformed token and out-of-range value.
// Neither the menu identity nor a client-supplied name grants host authority.
zmqol_menu_value( words )
{
    if ( words.size < 3 || words[0] != "zmqol_popt" )
        return undefined;
    name = words[1];
    fallback = zmqol_popt_default( name );
    if ( !isdefined( fallback ) )
        return undefined;
    if ( isstring( fallback ) )
    {
        if ( words.size != 3 && words.size != 5 )
            return undefined;
        for ( i = 2; i < words.size; i++ )
        {
            if ( words[i].size < 1 || words[i].size > 12 )
                return undefined;
            dots = 0;
            digits = 0;
            for ( j = 0; j < words[i].size; j++ )
            {
                ch = words[i][j];
                if ( ch == "." )
                    dots++;
                else if ( issubstr( "0123456789", ch ) )
                    digits++;
                else
                    return undefined;
            }
            if ( dots > 1 || !digits || float( words[i] ) > 1 )
                return undefined;
        }
        if ( words.size == 3 )
            return words[2] + " " + words[2] + " " + words[2];
        return words[2] + " " + words[3] + " " + words[4];
    }
    if ( words.size != 3 || words[2].size != 1 )
        return undefined;
    legal = "01";
    if ( name == "hud_timers" || name == "dof_quality" )
        legal = "0123";
    else if ( name == "hud_subtitles" )
        legal = "012";
    if ( !issubstr( legal, words[2] ) )
        return undefined;
    return int( words[2] );
}

zmqol_menu_listen()
{
    self endon( "disconnect" );
    for ( ;; )
    {
        self waittill( "menuresponse", menu, response );
        if ( menu != "luisystem" || !isstring( response ) || response.size > 140 )
            continue;
        words = strtok( response, ":" );
        value = zmqol_menu_value( words );
        if ( !isdefined( value ) )
            continue;
        self zmqol_popt_store( words[1], value );
        println( "[zm_qol] personal menu player=" + self getentitynumber() + " name=" + words[1] + " value=" + value );
    }
}
