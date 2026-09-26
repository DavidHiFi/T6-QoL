// ============================================================================
//      scripts/zm/zm_prison/qol_subs_music_prison.gsc
//  SUBTITLES  -  Mob's Easter egg song, "Rusty Cage"              (v2.17.42)
// ----------------------------------------------------------------------------
//  Stock zm_alcatraz_amb::sndmuseggplay() plays it on the third bottle.
//  Copied verbatim with one call to zmqol_subtitles::zmqol_subs_music()
//  beside the playsound; see that function's banner. Mob's second song,
//  "Where Are We Going" (the 935 nixie code), is captioned in the generated
//  qol_subs_npc_prison.gsc copy of nixie_935_audio().
// ============================================================================
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;

main()
{
    replaceFunc( maps\mp\zm_alcatraz_amb::sndmuseggplay, ::zmqol_sndmuseggplay );
}

init()
{
}

// ----- maps\mp\zm_alcatraz_amb::sndmuseggplay  (stock verbatim + 1 caption line) -----
zmqol_sndmuseggplay( ent, alias, time )
{
    println( "[zm_qol] subtitles: hook ran - sndmuseggplay" );

    level.music_override = 1;
    wait 1;
    level thread scripts\zm\zmqol_subtitles::zmqol_subs_music( alias );
    ent playsound( alias );
    level thread maps\mp\zm_alcatraz_amb::sndeggmusicwait( time );
    level waittill_either( "end_game", "sndSongDone" );
    ent stopsounds();
    wait 0.05;
    ent delete();
    level.music_override = 0;
}
