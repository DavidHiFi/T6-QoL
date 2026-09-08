// ============================================================================
//      scripts/zm/zm_tomb/qol_subs_tomb.gsc
//  SUBTITLES  -  the raw road on Origins                          (v2.14.21)
// ----------------------------------------------------------------------------
//  User, 2026-09-08, after the first boot of SUBTITLES on Origins: *"the
//  subtitles kinda worked, but not all the time so make sure they're
//  persistent and smooth, make sure to iron out any rough edges."*
//
//  WHAT THIS FILE IS FOR. scripts/zm/zmqol_subtitles.gsc captions every line
//  that goes through _zm_audio::create_and_play_dialog() - which is every
//  reactive quote. Origins' STORY lines do not go that way: zm_tomb_vo.gsc
//  plays them straight through playsoundwithnotify() on the player, a builtin
//  with no hook. Measured by grepping the map's scripts for every sound
//  builtin fed a vox_plr alias (checkpoint 262):
//
//      zm_tomb_vo::samantha_intro_1/2/3      rounds 5, 6, 7 - "hear_samantha_1",
//                                            "heroes_confer", "hear_samantha_3",
//                                            every character, via
//                                            play_line_on_player_character_if_present()
//      zm_tomb_vo::richtofenrespondvoplay    the soul-box exchanges
//                                            (zm_tomb_challenges) and the beacon
//                                            (zm_tomb_ee_side) - "zm_box_start",
//                                            "zm_box_continue", "zm_box_complete",
//                                            "zm_box_final_complete", "get_beacon"
//      zm_tomb_vo::tomb_drone_built_vo       Richtofen's "maxis_drone_5" after
//                                            the drone's first build
//      zm_tomb_giant_robot::play_robot_crush_player_vo   "robot_crush_player_0/1"
//      zm_tomb_giant_robot::player_screams_while_falling "exit_robot_0", played to
//                                            the ejected player's own ears via
//                                            playsoundtoplayer()
//
//  All of those aliases have rows in zm/zmqol_subs_zm_tomb.csv (checked one by
//  one, 2026-09-08). The stock functions are copied verbatim below with ONE
//  line added beside each player playsoundwithnotify():
//        <player> scripts\zm\zmqol_subtitles::zmqol_subs_raw_line( alias );
//  Dev-only /# #/ blocks are dropped; nothing else changes.
//
//  🛑 WHICH FUNCTIONS ARE REPLACED, AND WHY THOSE. STOCK_REFERENCE §7a: a
//  threaded call is proven to reach a replaceFunc'd copy, a synchronous
//  unqualified same-file call is the case still in doubt. samantha_intro_N and
//  play_line_on_player_character_if_present are called synchronously from
//  inside zm_tomb_vo, so they are NOT the hook points - start_samantha_intro_vo
//  is (level-threaded once from zm_tomb_vo::init), and this file's copies of
//  the three intros and the two helpers are private to it. richtofenrespondvoplay
//  is always threaded (player thread ... / delay_thread with its pointer, both
//  resolved at quest time, long after main()). play_robot_crush_player_vo is
//  self-threaded. tomb_drone_built_vo is reached through
//  level.zombie_custom_craftable_built_vo, so besides the replaceFunc the
//  pointer itself is re-pointed once the players are in (§7a mode 2).
//
//  📝 Every replacement prints "[zm_qol] subtitles: hook ran - <name>" the
//  first thing it does. §7a's last line: a hook is not proven until a boot
//  shows that line.
//
//  Maxis and Samantha (vox_maxi_*, vox_sam_*) are NPC voices: no table row,
//  not the character's own words, left as they are.
// ============================================================================
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;

main()
{
    replaceFunc( maps\mp\zm_tomb_vo::start_samantha_intro_vo, ::zmqol_start_samantha_intro_vo );
    replaceFunc( maps\mp\zm_tomb_vo::richtofenrespondvoplay, ::zmqol_richtofenrespondvoplay );
    replaceFunc( maps\mp\zm_tomb_vo::tomb_drone_built_vo, ::zmqol_tomb_drone_built_vo );
    replaceFunc( maps\mp\zm_tomb_giant_robot::play_robot_crush_player_vo, ::zmqol_play_robot_crush_player_vo );
    replaceFunc( maps\mp\zm_tomb_giant_robot::player_screams_while_falling, ::zmqol_player_screams_while_falling );
}

init()
{
    thread zmqol_subs_tomb_repoint();
}

//  zm_tomb_vo::init (classic only) sets level.zombie_custom_craftable_built_vo
//  = ::tomb_drone_built_vo at map init. The replaceFunc above should already
//  catch a call through it; re-pointing costs nothing and removes the doubt.
zmqol_subs_tomb_repoint()
{
    flag_wait( "initial_players_connected" );

    if ( isdefined( level.zombie_custom_craftable_built_vo ) )
        level.zombie_custom_craftable_built_vo = ::zmqol_tomb_drone_built_vo;

    println( "[zm_qol] subtitles: Origins raw-road hooks installed (samantha intro, richtofen exchanges, drone, robot crush, robot eject)" );
}

// ----------------------------------------------------------------------------
//  zm_tomb_vo.gsc  -  the Samantha intro, rounds 5-7
// ----------------------------------------------------------------------------
zmqol_start_samantha_intro_vo()
{
    println( "[zm_qol] subtitles: hook ran - start_samantha_intro_vo" );

    while ( true )
    {
        level waittill( "start_of_round" );

        if ( level.round_number == 5 )
            zmqol_samantha_intro_1();
        else if ( level.round_number == 6 )
            zmqol_samantha_intro_2();
        else if ( level.round_number == 7 )
        {
            zmqol_samantha_intro_3();
            flag_set( "samantha_intro_done" );
            break;
        }
    }
}

zmqol_samantha_intro_1()
{
    players = getplayers();

    if ( !isdefined( players[0] ) )
        return;

    flag_waitopen( "story_vo_playing" );
    flag_set( "story_vo_playing" );
    maps\mp\zm_tomb_vo::set_players_dontspeak( 1 );
    maps\mp\zm_tomb_vo::samanthasay( "vox_sam_sam_help_5_0", players[0], 1, 1 );
    players = getplayers();

    foreach ( player in players )
    {
        if ( player.character_name != "Richtofen" )
        {
            player zmqol_play_category_on_player_character_if_present( "hear_samantha_1", player.character_name );
            wait 1;
            zmqol_play_line_on_player_character_if_present( "vox_plr_2_hear_samantha_1_0", "Richtofen" );
            break;
        }
    }

    maps\mp\zm_tomb_vo::set_players_dontspeak( 0 );
    flag_clear( "story_vo_playing" );
}

zmqol_samantha_intro_2()
{
    player_richtofen = maps\mp\zm_tomb_vo::get_player_character_if_present( "Richtofen" );

    if ( !isdefined( player_richtofen ) )
        return;

    flag_waitopen( "story_vo_playing" );
    flag_set( "story_vo_playing" );
    maps\mp\zm_tomb_vo::set_players_dontspeak( 1 );

    if ( isdefined( player_richtofen ) )
    {
        nearest_friend = maps\mp\zm_tomb_vo::get_nearest_friend_within_speaking_distance( player_richtofen );

        if ( isdefined( nearest_friend ) )
        {
            nearest_friend zmqol_play_category_on_player_character_if_present( "heroes_confer", nearest_friend.character_name );
            wait 1;
            zmqol_play_line_on_player_character_if_present( "vox_plr_2_heroes_confer_0", "Richtofen" );
        }
    }

    maps\mp\zm_tomb_vo::set_players_dontspeak( 0 );
    flag_clear( "story_vo_playing" );
}

zmqol_samantha_intro_3()
{
    players = getplayers();

    if ( !isdefined( players[0] ) )
        return;

    flag_waitopen( "story_vo_playing" );
    flag_set( "story_vo_playing" );
    maps\mp\zm_tomb_vo::set_players_dontspeak( 1 );
    maps\mp\zm_tomb_vo::samanthasay( "vox_sam_hear_samantha_3_0", players[0], 1, 1 );
    players = getplayers();
    player = players[randomintrange( 0, players.size )];

    if ( isdefined( player ) )
        player zmqol_play_category_on_player_character_if_present( "hear_samantha_3", player.character_name );

    maps\mp\zm_tomb_vo::set_players_dontspeak( 0 );
    flag_clear( "story_vo_playing" );
}

zmqol_play_category_on_player_character_if_present( category, character_name )
{
    vox_line_prefix = undefined;

    switch ( character_name )
    {
        case "Dempsey":
            vox_line_prefix = "vox_plr_0_";
            break;
        case "Nikolai":
            vox_line_prefix = "vox_plr_1_";
            break;
        case "Richtofen":
            vox_line_prefix = "vox_plr_2_";
            break;
        case "Takeo":
            vox_line_prefix = "vox_plr_3_";
            break;
    }

    vox_line = vox_line_prefix + category + "_0";
    zmqol_play_line_on_player_character_if_present( vox_line, character_name );
}

zmqol_play_line_on_player_character_if_present( vox_line, character_name )
{
    player_character = maps\mp\zm_tomb_vo::get_player_character_if_present( character_name );

    if ( isdefined( player_character ) )
    {
        player_character playsoundwithnotify( vox_line, "sound_done" + vox_line );
        player_character scripts\zm\zmqol_subtitles::zmqol_subs_raw_line( vox_line );
        player_character waittill( "sound_done" + vox_line );
        return true;
    }
    else
        return false;
}

// ----------------------------------------------------------------------------
//  zm_tomb_vo.gsc  -  the Richtofen exchanges (soul boxes, beacon)
// ----------------------------------------------------------------------------
zmqol_richtofenrespondvoplay( vox_category, b_richtofen_first, str_flag )
{
    println( "[zm_qol] subtitles: hook ran - richtofenrespondvoplay " + vox_category );

    if ( !isdefined( b_richtofen_first ) )
        b_richtofen_first = 0;

    if ( flag( "story_vo_playing" ) )
        return;

    flag_set( "story_vo_playing" );
    maps\mp\zm_tomb_vo::set_players_dontspeak( 1 );

    if ( b_richtofen_first )
    {
        if ( self.character_name == "Richtofen" )
        {
            str_vox_line = "vox_plr_" + self.characterindex + "_" + vox_category + "_0";
            self playsoundwithnotify( str_vox_line, "rich_done" );
            self scripts\zm\zmqol_subtitles::zmqol_subs_raw_line( str_vox_line );
            self waittill( "rich_done" );
            wait 0.5;

            foreach ( player in getplayers() )
            {
                if ( player.character_name != "Richtofen" && distance2d( player.origin, self.origin ) < 800 )
                {
                    str_vox_line = "vox_plr_" + player.characterindex + "_" + vox_category + "_0";
                    player playsoundwithnotify( str_vox_line, "rich_done" );
                    player scripts\zm\zmqol_subtitles::zmqol_subs_raw_line( str_vox_line );
                    player waittill( "rich_done" );
                }
            }
        }
        else
        {
            foreach ( player in getplayers() )
            {
                if ( player.character_name == "Richtofen" && distance2d( player.origin, self.origin ) < 800 )
                {
                    str_vox_line = "vox_plr_" + player.characterindex + "_" + vox_category + "_0";
                    player playsoundwithnotify( str_vox_line, "rich_done" );
                    player scripts\zm\zmqol_subtitles::zmqol_subs_raw_line( str_vox_line );
                    player waittill( "rich_done" );
                    wait 0.5;
                }
            }

            if ( isdefined( self ) )
            {
                str_vox_line = "vox_plr_" + self.characterindex + "_" + vox_category + "_0";
                self playsoundwithnotify( str_vox_line, "rich_response" );
                self scripts\zm\zmqol_subtitles::zmqol_subs_raw_line( str_vox_line );
                self waittill( "rich_response" );
            }
        }
    }
    else if ( self.character_name == "Richtofen" )
    {
        foreach ( player in getplayers() )
        {
            if ( player.character_name != "Richtofen" && distance2d( player.origin, self.origin ) < 800 )
            {
                str_vox_line = "vox_plr_" + player.characterindex + "_" + vox_category + "_0";
                player playsoundwithnotify( str_vox_line, "rich_done" );
                player scripts\zm\zmqol_subtitles::zmqol_subs_raw_line( str_vox_line );
                player waittill( "rich_done" );
                wait 0.5;
            }
        }

        if ( isdefined( self ) )
        {
            str_vox_line = "vox_plr_" + self.characterindex + "_" + vox_category + "_0";
            self playsoundwithnotify( str_vox_line, "rich_done" );
            self scripts\zm\zmqol_subtitles::zmqol_subs_raw_line( str_vox_line );
            self waittill( "rich_done" );
        }
    }
    else
    {
        str_vox_line = "vox_plr_" + self.characterindex + "_" + vox_category + "_0";
        self playsoundwithnotify( str_vox_line, "rich_response" );
        self scripts\zm\zmqol_subtitles::zmqol_subs_raw_line( str_vox_line );
        self waittill( "rich_response" );
        wait 0.5;

        foreach ( player in getplayers() )
        {
            if ( player.character_name == "Richtofen" && distance2d( player.origin, self.origin ) < 800 )
            {
                str_vox_line = "vox_plr_" + player.characterindex + "_" + vox_category + "_0";
                player playsoundwithnotify( str_vox_line, "rich_done" );
                player scripts\zm\zmqol_subtitles::zmqol_subs_raw_line( str_vox_line );
                player waittill( "rich_done" );
            }
        }
    }

    if ( isdefined( str_flag ) )
        flag_set( str_flag );

    maps\mp\zm_tomb_vo::set_players_dontspeak( 0 );
    flag_clear( "story_vo_playing" );
}

// ----------------------------------------------------------------------------
//  zm_tomb_vo.gsc  -  the drone's first build (self is the builder)
// ----------------------------------------------------------------------------
zmqol_tomb_drone_built_vo( s_craftable )
{
    println( "[zm_qol] subtitles: hook ran - tomb_drone_built_vo" );

    if ( s_craftable.weaponname != "equip_dieseldrone_zm" )
        return;

    flag_waitopen( "story_vo_playing" );
    flag_set( "story_vo_playing" );
    maps\mp\zm_tomb_vo::set_players_dontspeak( 1 );
    wait 1;
    e_vo_origin = maps\mp\zm_tomb_vo::get_speaking_location_maxis_drone( self, s_craftable );
    vox_line = "vox_maxi_maxis_drone_1_0";
    //  v2.14.31 - Maxis' two lines here are NPC voice, captioned like the
    //  generated copies do it (qol_subs_npc_tomb.gsc): source = the origin
    //  the sound plays on.
    scripts\zm\zmqol_subtitles::zmqol_subs_npc( vox_line, e_vo_origin, undefined, undefined );
    e_vo_origin playsoundwithnotify( vox_line, "sound_done" + vox_line );
    e_vo_origin waittill( "sound_done" + vox_line );
    e_vo_origin delete();
    wait 1;
    e_vo_origin = maps\mp\zm_tomb_vo::get_speaking_location_maxis_drone( self, s_craftable );
    vox_line = "vox_maxi_maxis_drone_4_0";
    scripts\zm\zmqol_subtitles::zmqol_subs_npc( vox_line, e_vo_origin, undefined, undefined );
    e_vo_origin playsoundwithnotify( vox_line, "sound_done" + vox_line );
    e_vo_origin waittill( "sound_done" + vox_line );
    e_vo_origin delete();
    wait 1;

    if ( isdefined( self ) && self.character_name == "Richtofen" )
    {
        vox_line = "vox_plr_2_maxis_drone_5_0";
        self playsoundwithnotify( vox_line, "sound_done" + vox_line );
        self scripts\zm\zmqol_subtitles::zmqol_subs_raw_line( vox_line );
        self waittill( "sound_done" + vox_line );
    }

    maps\mp\zm_tomb_vo::set_players_dontspeak( 0 );
    flag_clear( "story_vo_playing" );
    flag_set( "maxis_crafted_intro_done" );
}

// ----------------------------------------------------------------------------
//  zm_tomb_giant_robot.gsc  -  crushed underfoot while down
// ----------------------------------------------------------------------------
zmqol_play_robot_crush_player_vo()
{
    self endon( "disconnect" );

    println( "[zm_qol] subtitles: hook ran - play_robot_crush_player_vo" );

    if ( self maps\mp\zombies\_zm_laststand::player_is_in_laststand() )
    {
        if ( cointoss() )
            n_alt = 1;
        else
            n_alt = 0;

        str_alias = "vox_plr_" + self.characterindex + "_robot_crush_player_" + n_alt;
        self playsoundwithnotify( str_alias, "sound_done" + str_alias );
        self scripts\zm\zmqol_subtitles::zmqol_subs_raw_line( str_alias );
    }
}

// ----------------------------------------------------------------------------
//  zm_tomb_giant_robot.gsc  -  ejected from the head. self is the player; the
//  line is played to self's own ears only, so the caption is self's only.
// ----------------------------------------------------------------------------
zmqol_player_screams_while_falling()
{
    self endon( "disconnect" );

    println( "[zm_qol] subtitles: hook ran - player_screams_while_falling" );

    self stopsounds();
    wait_network_frame();
    str_alias = "vox_plr_" + self.characterindex + "_exit_robot_0";
    self playsoundtoplayer( str_alias, self );
    self scripts\zm\zmqol_subtitles::zmqol_subs_raw_line( str_alias, self );
}
