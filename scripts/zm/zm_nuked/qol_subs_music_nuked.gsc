// ============================================================================
//      scripts/zm/zm_nuked/qol_subs_music_nuked.gsc
//  SUBTITLES  -  Nuketown's three Easter egg songs                (v2.17.42)
// ----------------------------------------------------------------------------
//  Every one goes through stock zm_nuked::sndmuseggplay():
//      zmb_nuked_song_1   8-bit "Re-Damned"      clock + population sign at 115
//      zmb_nuked_song_2   "Samantha's Lullaby"   the three teddy bears
//      zmb_nuked_song_3   8-bit "Coming Home" or "Pareidolia" (the alias picks
//                         one of two files at random) - the mannequin heads
//  Copied verbatim with one call to zmqol_subtitles::zmqol_subs_music()
//  beside the playsound; see that function's banner.
// ============================================================================
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;

main()
{
    replaceFunc( maps\mp\zm_nuked::sndmuseggplay, ::zmqol_sndmuseggplay );
}

init()
{
}

// ----- maps\mp\zm_nuked::sndmuseggplay  (stock verbatim + 1 caption line) -----
zmqol_sndmuseggplay( ent, alias, time )
{
    println( "[zm_qol] subtitles: hook ran - sndmuseggplay" );

    level.music_override = 1;
    wait 1;
    level thread scripts\zm\zmqol_subtitles::zmqol_subs_music( alias );
    ent playsound( alias );
    level thread maps\mp\zm_nuked::sndeggmusicwait( time );
    level waittill_either( "end_game", "sndSongDone" );
    ent stopsounds();
    wait 0.05;
    ent delete();
    level.music_override = 0;
}
