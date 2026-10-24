// Roster metadata for the extended points list. Scores stay on the native LUI event.
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;

init()
{
    precachestring( &"qol_points_roster" );
    precachestring( &"qol_points_crew" );
    level thread qol_points_roster();
}

qol_points_roster()
{
    level endon( "end_game" );
    previous = "";
    refresh = 0;
    extended = 0;

    for ( ;; )
    {
        players = get_players();
        signature = "";
        foreach ( player in players )
            signature += player getentitynumber() + ":" + player qol_points_faction() + ":" + player qol_points_character() + ";";

        if ( players.size > 4 || extended )
        {
            if ( signature != previous || gettime() >= refresh )
            {
                foreach ( viewer in players )
                {
                    viewer luinotifyevent( &"qol_points_roster", 2, players.size, viewer getentitynumber() );
                    foreach ( player in players )
                        viewer luinotifyevent( &"qol_points_crew", 3, player getentitynumber(), player qol_points_faction(), player qol_points_character() );
                }
                previous = signature;
                refresh = gettime() + 2000;
            }
        }
        extended = players.size > 4;
        wait 0.5;
    }
}

qol_points_character()
{
    // Optional character portraits are supplied by the build, never by this script.
    if ( isdefined( self.qol_hud_portrait ) )
        return self.qol_hud_portrait;
    if ( isdefined( self.characterindex ) )
        return self.characterindex;
    return -1;
}

qol_points_faction()
{
    // Same map-first faction choice as the TAB scoreboard, sent per player.
    switch ( level.script )
    {
        case "zm_highrise": return 3;
        case "zm_prison":   return 4;
        case "zm_buried":   return 5;
        case "zm_tomb":     return 6;
    }
    if ( is_classic() )
        return 2;

    // A personal character pick can differ from the level's CIA/CDC roll.
    model = self.model;
    if ( isdefined( model ) && model == "c_zom_player_cia_fb" )
        return 1;
    if ( isdefined( model ) && model == "c_zom_player_cdc_fb" )
        return 0;
    return -1;
}
