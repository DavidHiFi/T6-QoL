// ============================================================================
//      scripts/zm/zm_transit/qol_subs_music_transit.gsc
//  SUBTITLES  -  TranZit's Easter egg song, "Carrion"             (v2.17.42)
// ----------------------------------------------------------------------------
//  Two roads play mus_zmb_secret_song on this map, and both need the card:
//
//  1. CLASSIC (Green Run): stock zm_transit::sndplaymusicegg(), threaded from
//     sndmusicegg() when the third bear is used. Replaced verbatim below with
//     one caption call beside the playsound.
//
//  2. SURVIVAL (Town, Bus Depot, Farm, Diner) - the one the user heard:
//     stock never runs its egg outside zclassic, so quality_of_life.gsc spawns
//     its own three bears (spawnteddybear / play_secret_song) and plays the
//     song itself. That file is on its symbol ceiling and must not gain a
//     call, so this file WATCHES instead: the mod's bears count up
//     level.sss_teddybear_count, and play_secret_song() starts the song
//     1 s after the count reaches 3. Polled every 0.25 s from here; the card
//     goes up the moment the count hits 3 plus that same 1 s.
// ============================================================================
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;

main()
{
    replaceFunc( maps\mp\zm_transit::sndplaymusicegg, ::zmqol_sndplaymusicegg );
}

init()
{
    if ( !is_classic() )
        level thread zmqol_subs_watch_mod_bears();
}

// ----- maps\mp\zm_transit::sndplaymusicegg  (stock verbatim + 1 caption line) -----
zmqol_sndplaymusicegg( player, ent )
{
    println( "[zm_qol] subtitles: hook ran - sndplaymusicegg" );

    wait 1;
    level thread scripts\zm\zmqol_subtitles::zmqol_subs_music( "mus_zmb_secret_song" );
    ent playsound( "mus_zmb_secret_song" );
    level waittill( "end_game" );
    ent stopsounds();
    wait 0.05;
    ent delete();
}

//  The mod's survival bears (quality_of_life.gsc setteddybears). Ends when the
//  song starts or the game does; costs one level read four times a second.
zmqol_subs_watch_mod_bears()
{
    level endon( "end_game" );

    while ( !isdefined( level.sss_teddybear_count ) || level.sss_teddybear_count < 3 )
        wait 0.25;

    println( "[zm_qol] subtitles: survival bears 3/3 - song starting" );
    wait 1;
    level thread scripts\zm\zmqol_subtitles::zmqol_subs_music( "mus_zmb_secret_song" );
}
