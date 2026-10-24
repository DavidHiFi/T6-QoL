#include maps\mp\zombies\_zm_utility;

init()
{
    replacefunc( maps\mp\zombies\_zm::player_too_many_players_check, ::qol_player_cap );
}

qol_player_cap()
{
    max_players = 4;
    if ( level.scr_zm_ui_gametype == "zgrief" || level.scr_zm_ui_gametype == "zmeat" )
        max_players = 8;
    else if ( getdvarint( "sv_maxclients" ) > 4 )
        max_players = min( getdvarint( "sv_maxclients" ), 8 );

    if ( get_players().size > max_players )
    {
        maps\mp\zombies\_zm_game_module::freeze_players( 1 );
        level notify( "end_game" );
    }
}
