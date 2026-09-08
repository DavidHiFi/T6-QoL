// ============================================================================
//      scripts/zm/zm_buried/qol_subs_buried.gsc
//  SUBTITLES  -  the raw road on Buried                           (v2.14.21)
// ----------------------------------------------------------------------------
//  The Origins twin, scripts/zm/zm_tomb/qol_subs_tomb.gsc, carries the full
//  reasoning. On Buried exactly three character lines go round the dialogue
//  system: Stuhlinger's three answers to Richtofen during the quest's opening
//  narration, played by zm_buried_sq_bt::stage_vo() through
//  playsoundwithnotify() on level.rich_sq_player -
//  vox_plr_1_respond_richtofen_0 / _1 / _2 (rows present in
//  zm/zmqol_subs_zm_buried.csv, checked 2026-09-08). Richtofen's own lines
//  there (vox_zmba_*) are the voice in Stuhlinger's head, not a character
//  line, and Maxis (vox_maxi_*) is Maxis; neither has a table row.
//
//  stage_vo() is `level thread`ed once from zm_buried_sq_bt::init(), the
//  proven-to-take shape for replaceFunc (STOCK_REFERENCE §7a). The copy below
//  is verbatim with the three caption calls added and every same-file call
//  qualified. It prints "[zm_qol] subtitles: hook ran - stage_vo" first.
//  TranZit and Die Rise have the same Richtofen narration and NO character
//  line outside the dialogue system (same grep), so they need no file.
// ============================================================================
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;

main()
{
    replaceFunc( maps\mp\zm_buried_sq_bt::stage_vo, ::zmqol_stage_vo );
}

init()
{
    println( "[zm_qol] subtitles: Buried raw-road hook installed (stage_vo)" );
}

zmqol_stage_vo()
{
    println( "[zm_qol] subtitles: hook ran - stage_vo" );

    level waittill( "start_of_round" );
    level thread maps\mp\zm_buried_sq_bt::stage_vo_watch_underground();
    wait 5;
    maps\mp\zm_buried_sq::maxissay( "vox_maxi_sidequest_maxis_start_1_0" );
    maps\mp\zm_buried_sq::maxissay( "vox_maxi_sidequest_maxis_start_2_0" );
    maps\mp\zm_buried_sq::maxissay( "vox_maxi_sidequest_maxis_start_3_0" );
    maps\mp\zm_buried_sq::maxissay( "vox_maxi_sidequest_maxis_start_4_0" );
    maps\mp\zm_buried_sq::maxissay( "vox_maxi_sidequest_maxis_start_5_0" );
    flag_wait( "sq_player_underground" );
    level.m_maxis_vo_spot.origin = ( -728, -344, 280 );

    while ( isdefined( level.vo_player_who_discovered_stables_roof ) && is_true( level.vo_player_who_discovered_stables_roof.isspeaking ) )
        wait 0.05;

    maps\mp\zm_buried_sq::maxissay( "vox_maxi_sidequest_town_0" );
    maps\mp\zm_buried_sq::maxissay( "vox_maxi_sidequest_town_1" );
    wait 1;
    level thread maps\mp\zm_buried_sq_bt::stage_vo_watch_gallows();

    if ( !level.richcompleted )
    {
        if ( isdefined( level.rich_sq_player ) )
        {
            level.rich_sq_player.dontspeak = 1;
            level.rich_sq_player setclientfieldtoplayer( "isspeaking", 1 );
        }

        maps\mp\zm_buried_sq::richtofensay( "vox_zmba_sidequest_zmba_start_1_0", 3 );

        if ( isdefined( level.rich_sq_player ) )
        {
            while ( isdefined( level.rich_sq_player ) && ( is_true( level.rich_sq_player.isspeaking ) || is_true( level.rich_sq_player.dontspeak ) ) )
                wait 1;

            level.rich_sq_player.dontspeak = 1;
            level.rich_sq_player setclientfieldtoplayer( "isspeaking", 1 );
            level.rich_sq_player playsoundwithnotify( "vox_plr_1_respond_richtofen_0", "sound_done_vox_plr_1_respond_richtofen_0" );
            level.rich_sq_player scripts\zm\zmqol_subtitles::zmqol_subs_raw_line( "vox_plr_1_respond_richtofen_0" );
            level.rich_sq_player waittill( "sound_done_vox_plr_1_respond_richtofen_0" );
            wait 1;
            level.rich_sq_player setclientfieldtoplayer( "isspeaking", 0 );
        }

        maps\mp\zm_buried_sq::richtofensay( "vox_zmba_sidequest_zmba_start_3_0", 4 );

        if ( isdefined( level.rich_sq_player ) )
        {
            while ( isdefined( level.rich_sq_player ) && ( is_true( level.rich_sq_player.isspeaking ) || is_true( level.rich_sq_player.dontspeak ) ) )
                wait 1;

            level.rich_sq_player.dontspeak = 1;
            level.rich_sq_player setclientfieldtoplayer( "isspeaking", 1 );
            level.rich_sq_player playsoundwithnotify( "vox_plr_1_respond_richtofen_1", "sound_done_vox_plr_1_respond_richtofen_1" );
            level.rich_sq_player scripts\zm\zmqol_subtitles::zmqol_subs_raw_line( "vox_plr_1_respond_richtofen_1" );
            level.rich_sq_player waittill( "sound_done_vox_plr_1_respond_richtofen_1" );
            wait 1;
            level.rich_sq_player setclientfieldtoplayer( "isspeaking", 0 );
        }

        maps\mp\zm_buried_sq::richtofensay( "vox_zmba_sidequest_zmba_start_5_0", 12 );
        maps\mp\zm_buried_sq::richtofensay( "vox_zmba_sidequest_zmba_start_6_0", 8 );

        if ( isdefined( level.rich_sq_player ) )
        {
            while ( isdefined( level.rich_sq_player ) && ( is_true( level.rich_sq_player.isspeaking ) || is_true( level.rich_sq_player.dontspeak ) ) )
                wait 1;

            level.rich_sq_player.dontspeak = 1;
            level.rich_sq_player setclientfieldtoplayer( "isspeaking", 1 );
            level.rich_sq_player playsoundwithnotify( "vox_plr_1_respond_richtofen_2", "sound_done_vox_plr_1_respond_richtofen_2" );
            level.rich_sq_player scripts\zm\zmqol_subtitles::zmqol_subs_raw_line( "vox_plr_1_respond_richtofen_2" );
            level.rich_sq_player waittill( "sound_done_vox_plr_1_respond_richtofen_2" );
            wait 1;
            level.rich_sq_player setclientfieldtoplayer( "isspeaking", 0 );
        }

        maps\mp\zm_buried_sq::richtofensay( "vox_zmba_sidequest_town_0", 6 );
        maps\mp\zm_buried_sq::richtofensay( "vox_zmba_sidequest_town_1", 6 );
    }

    flag_set( "sq_intro_vo_done" );
    level thread maps\mp\zm_buried_sq_bt::stage_vo_nag();
    level thread maps\mp\zm_buried_sq_bt::stage_vo_watch_guillotine();
}
