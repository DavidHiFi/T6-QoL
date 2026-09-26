// ============================================================================
//      scripts/zm/zm_tomb/qol_subs_music_tomb.gsc
//  SUBTITLES  -  Origins' three Easter egg songs                  (v2.17.42)
// ----------------------------------------------------------------------------
//  Every one goes through stock zm_tomb_amb::sndmuseggplay():
//      mus_zmb_secret_song         "Archangel"        the three meteor bottles
//      mus_zmb_secret_song_aether  "Aether"           the 1-1-5 floor panels
//      mus_zmb_secret_song_a7x     "Shepherd of Fire" the three radios
//                                  (zm_tomb_ee_side, which calls the function
//                                  fully qualified - replaceFunc still takes)
//  Copied verbatim with one call to zmqol_subtitles::zmqol_subs_music()
//  beside the playsound; see that function's banner.
// ============================================================================
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;

main()
{
    replaceFunc( maps\mp\zm_tomb_amb::sndmuseggplay, ::zmqol_sndmuseggplay );
}

init()
{
}

// ----- maps\mp\zm_tomb_amb::sndmuseggplay  (stock verbatim + 1 caption line) -----
zmqol_sndmuseggplay( ent, alias, time )
{
    println( "[zm_qol] subtitles: hook ran - sndmuseggplay" );

    level.music_override = 1;
    wait 1;
    level thread scripts\zm\zmqol_subtitles::zmqol_subs_music( alias );
    ent playsound( alias );
    level setclientfield( "mus_zmb_egg_snapshot_loop", 1 );
    level notify( "sndStingerForceStop" );
    level thread maps\mp\zm_tomb_amb::sndeggmusicwait( time );
    level waittill_either( "end_game", "sndSongDone" );
    ent stopsounds();
    level setclientfield( "mus_zmb_egg_snapshot_loop", 0 );
    wait 0.05;
    ent delete();
    level.music_override = 0;
}
