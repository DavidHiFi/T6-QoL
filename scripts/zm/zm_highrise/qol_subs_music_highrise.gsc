// ============================================================================
//      scripts/zm/zm_highrise/qol_subs_music_highrise.gsc
//  SUBTITLES  -  Die Rise's Easter egg song, "We All Fall Down"   (v2.17.42)
// ----------------------------------------------------------------------------
//  Stock zm_highrise_amb::sndmuseggplay() plays it on the third bear. Copied
//  verbatim with one call to zmqol_subtitles::zmqol_subs_music() beside the
//  playsound; see that function's banner.
// ============================================================================
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;

main()
{
    replaceFunc( maps\mp\zm_highrise_amb::sndmuseggplay, ::zmqol_sndmuseggplay );
}

init()
{
}

// ----- maps\mp\zm_highrise_amb::sndmuseggplay  (stock verbatim + 1 caption line) -----
zmqol_sndmuseggplay( ent, alias, time )
{
    println( "[zm_qol] subtitles: hook ran - sndmuseggplay" );

    level.music_override = 1;
    wait 1;
    level thread scripts\zm\zmqol_subtitles::zmqol_subs_music( alias );
    ent playsound( alias );
    level thread maps\mp\zm_highrise_amb::sndeggmusicwait( time );
    level waittill_either( "end_game", "sndSongDone" );
    ent stopsounds();
    wait 0.05;
    ent delete();
    level.music_override = 0;
}
