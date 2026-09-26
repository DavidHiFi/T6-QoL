// ============================================================================
//      scripts/zm/zm_buried/qol_subs_music_buried.gsc
//  SUBTITLES  -  Buried's Easter egg songs                        (v2.17.42)
// ----------------------------------------------------------------------------
//  Three stock functions in zm_buried_amb play them:
//      sndmuseggplay()          mus_zmb_secret_song "Always Running", the
//                               three bottles
//      sndmusicquestendgame()   "Richtofen's Delight" / "Samantha's Desire",
//      sndendgamemusicredux()   the quest endings and their replay button
//  Copied verbatim with one call to zmqol_subtitles::zmqol_subs_music()
//  beside each playsound; see that function's banner.
// ============================================================================
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;

main()
{
    replaceFunc( maps\mp\zm_buried_amb::sndmuseggplay, ::zmqol_sndmuseggplay );
    replaceFunc( maps\mp\zm_buried_amb::sndmusicquestendgame, ::zmqol_sndmusicquestendgame );
    replaceFunc( maps\mp\zm_buried_amb::sndendgamemusicredux, ::zmqol_sndendgamemusicredux );
}

init()
{
}

// ----- maps\mp\zm_buried_amb::sndmuseggplay  (stock verbatim + 1 caption line) -----
zmqol_sndmuseggplay( ent, alias, time )
{
    println( "[zm_qol] subtitles: hook ran - sndmuseggplay" );

    level.music_override = 1;
    wait 1;
    level thread scripts\zm\zmqol_subtitles::zmqol_subs_music( alias );
    ent playsound( alias );
    level setclientfield( "mus_zmb_egg_snapshot_loop", 1 );
    level thread maps\mp\zm_buried_amb::sndeggmusicwait( time );
    level waittill_either( "end_game", "sndSongDone" );
    ent stopsounds();
    level setclientfield( "mus_zmb_egg_snapshot_loop", 0 );
    wait 0.05;
    ent delete();
    level.music_override = 0;
}

// ----- maps\mp\zm_buried_amb::sndmusicquestendgame  (stock verbatim + 1 caption line) -----
zmqol_sndmusicquestendgame( alias, length )
{
    println( "[zm_qol] subtitles: hook ran - sndmusicquestendgame" );

    while ( is_true( level.music_override ) )
        wait 1;

    level.music_override = 1;
    level setclientfield( "mus_zmb_egg_snapshot_loop", 1 );
    ent = spawn( "script_origin", ( 0, 0, 0 ) );
    level thread scripts\zm\zmqol_subtitles::zmqol_subs_music( alias );
    ent playsound( alias );
    wait( length );
    level setclientfield( "mus_zmb_egg_snapshot_loop", 0 );
    level.music_override = 0;
    wait 0.05;
    ent delete();
    wait 1;
    level thread zmqol_sndendgamemusicredux( alias, length );
}

// ----- maps\mp\zm_buried_amb::sndendgamemusicredux  (stock verbatim + 1 caption line) -----
zmqol_sndendgamemusicredux( alias, length )
{
    println( "[zm_qol] subtitles: hook ran - sndendgamemusicredux" );

    m_endgame_machine = getstruct( "sq_endgame_machine", "targetname" );
    temp_ent = spawn( "script_origin", m_endgame_machine.origin );
    temp_ent thread maps\mp\zombies\_zm_sidequests::fake_use( "main_music_egg_hit", maps\mp\zm_buried_amb::sndmusicegg_override );
    temp_ent playloopsound( "zmb_meteor_loop" );
    temp_ent waittill( "main_music_egg_hit", player );
    temp_ent stoploopsound( 1 );
    level.music_override = 1;
    temp_ent playsound( "zmb_endgame_mach_button" );
    level setclientfield( "mus_zmb_egg_snapshot_loop", 1 );
    level thread scripts\zm\zmqol_subtitles::zmqol_subs_music( alias );
    temp_ent playsound( alias );
    wait( length );
    level setclientfield( "mus_zmb_egg_snapshot_loop", 0 );
    level.music_override = 0;
    wait 0.05;
    temp_ent delete();
}
