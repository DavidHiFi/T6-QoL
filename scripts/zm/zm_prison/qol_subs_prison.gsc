// ============================================================================
//      scripts/zm/zm_prison/qol_subs_prison.gsc
//  SUBTITLES  -  the raw road on Mob of the Dead                  (v2.14.21)
// ----------------------------------------------------------------------------
//  The Origins twin, scripts/zm/zm_tomb/qol_subs_tomb.gsc, carries the full
//  reasoning; this file does the same job for the character lines Mob's
//  quest scripts play straight through sound builtins, never touching
//  _zm_audio's dialogue system. Measured by grepping the map's scripts for
//  every sound builtin fed a vox_plr alias (2026-09-08):
//
//      zm_alcatraz_sq::electric_chair_player_thread   "<name>_electrocution_0"
//                                                     via playsoundontag()
//      zm_alcatraz_sq_vo::player_scream_thread        "free_fall_0", every NML
//                                                     character's line played
//                                                     to EACH player's own ears
//                                                     via playsoundtoplayer()
//      zm_prison_sq_final::final_battle_vo            the showdown exchange -
//        + final_battle_reveal                        "end_scenario_0/1"
//
//  All rows present in zm/zmqol_subs_zm_prison.csv (checked one by one).
//
//  🛑 HOW EACH IS REACHED, per STOCK_REFERENCE §7a:
//    - the electric chair has a custom-function pointer stock declares and
//      never sets, level.electric_chair_player_thread_custom_func (zm_alcatraz_
//      sq.gsc:1846, checked against the whole dump and this mod: no writer).
//      Setting it is the cleanest hook there is - no replaceFunc at all.
//    - player_scream_thread is `player thread`ed, final_battle_vo is
//      `level thread`ed: the proven-to-take shape. final_battle_reveal is a
//      synchronous same-file call FROM final_battle_vo, so this file's copy of
//      final_battle_vo calls its own copy.
//  Every replacement prints "[zm_qol] subtitles: hook ran - <name>" first.
// ============================================================================
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;

main()
{
    replaceFunc( maps\mp\zm_alcatraz_sq_vo::player_scream_thread, ::zmqol_player_scream_thread );
    replaceFunc( maps\mp\zm_prison_sq_final::final_battle_vo, ::zmqol_final_battle_vo );
}

init()
{
    level.electric_chair_player_thread_custom_func = ::zmqol_electric_chair_player_thread;
    println( "[zm_qol] subtitles: Mob raw-road hooks installed (electric chair, free fall, showdown)" );
}

// ----------------------------------------------------------------------------
//  zm_alcatraz_sq.gsc  -  the chair. self is the player in it.
// ----------------------------------------------------------------------------
zmqol_electric_chair_player_thread( m_linkpoint, chair_number, n_effects_duration )
{
    self endon( "death_or_disconnect" );

    println( "[zm_qol] subtitles: hook ran - electric_chair_player_thread" );

    e_home_telepoint = getstruct( "home_telepoint_" + chair_number, "targetname" );
    e_corpse_location = getstruct( "corpse_starting_point_" + chair_number, "targetname" );
    self disableweapons();
    self enableinvulnerability();
    self setstance( "stand" );
    self allowstand( 1 );
    self allowcrouch( 0 );
    self allowprone( 0 );
    self playerlinktodelta( m_linkpoint, "tag_origin", 1, 20, 20, 20, 20 );
    self setplayerangles( m_linkpoint.angles );
    self playsoundtoplayer( "zmb_electric_chair_2d", self );
    self do_player_general_vox( "quest", "chair_electrocution", undefined, 100 );
    self ghost();
    self.ignoreme = 1;
    self.dontspeak = 1;
    self setclientfieldtoplayer( "isspeaking", 1 );
    wait( n_effects_duration - 2 );

    str_alias = undefined;

    switch ( self.character_name )
    {
        case "Arlington":
            str_alias = "vox_plr_3_arlington_electrocution_0";
            break;
        case "Sal":
            str_alias = "vox_plr_1_sal_electrocution_0";
            break;
        case "Billy":
            str_alias = "vox_plr_2_billy_electrocution_0";
            break;
        case "Finn":
            str_alias = "vox_plr_0_finn_electrocution_0";
            break;
    }

    if ( isdefined( str_alias ) )
    {
        self playsoundontag( str_alias, "J_Head" );
        self scripts\zm\zmqol_subtitles::zmqol_subs_raw_line( str_alias );
    }

    wait 2;
    level.zones["zone_golden_gate_bridge"].is_enabled = 1;
    level.zones["zone_golden_gate_bridge"].is_spawning_allowed = 1;
    self.keep_perks = 1;
    self disableinvulnerability();
    self.afterlife = 1;
    self thread maps\mp\zombies\_zm_afterlife::afterlife_laststand( 1 );
    self unlink();
    self setstance( "stand" );
    self waittill( "player_fake_corpse_created" );
    self thread maps\mp\zm_alcatraz_sq::track_player_completed_cycle();
    trace_start = e_corpse_location.origin + vectorscale( ( 0, 0, 1 ), 100.0 );
    trace_end = e_corpse_location.origin + vectorscale( ( 0, 0, -1 ), 100.0 );
    corpse_trace = bullettrace( trace_start, trace_end, 0, self.e_afterlife_corpse );
    self.e_afterlife_corpse.origin = corpse_trace["position"];
    self setorigin( e_home_telepoint.origin );
    self enableweapons();
    self setclientfieldtoplayer( "rumble_electric_chair", 0 );

    if ( level.n_quest_iteration_count == 2 )
    {
        self waittill( "player_revived" );
        wait 1;
        self do_player_general_vox( "quest", "start_2", undefined, 100 );
    }
}

// ----------------------------------------------------------------------------
//  zm_alcatraz_sq_vo.gsc  -  the free fall. self is the listening player; each
//  NML character's scream is played to self's ears only, so the caption goes to
//  self only, with the other character's name in front.
// ----------------------------------------------------------------------------
zmqol_player_scream_thread()
{
    self endon( "death" );
    self endon( "disconnect" );

    println( "[zm_qol] subtitles: hook ran - player_scream_thread" );

    players = getplayers();

    foreach ( player in players )
    {
        if ( isdefined( player ) && isinarray( level.characters_in_nml, player.character_name ) )
        {
            str_alias = "vox_plr_" + player.characterindex + "_free_fall_0";
            player playsoundtoplayer( str_alias, self );
            player scripts\zm\zmqol_subtitles::zmqol_subs_raw_line( str_alias, self );
        }
    }

    level flag_wait( "plane_crashed" );
    self stopsounds();
    self.dontspeak = 0;
    player setclientfieldtoplayer( "isspeaking", 0 );
}

// ----------------------------------------------------------------------------
//  zm_prison_sq_final.gsc  -  the showdown
// ----------------------------------------------------------------------------
zmqol_final_battle_vo( p_weasel, a_player_team )
{
    level endon( "showdown_over" );

    println( "[zm_qol] subtitles: hook ran - final_battle_vo" );

    wait 10;
    a_players = arraycopy( a_player_team );
    player = a_players[randomintrange( 0, a_players.size )];
    arrayremovevalue( a_players, player );

    if ( a_players.size > 0 )
        player_2 = a_players[randomintrange( 0, a_players.size )];

    if ( isdefined( player ) )
        player zmqol_final_battle_reveal();

    wait 3;

    if ( isdefined( p_weasel ) )
    {
        p_weasel playsoundontag( "vox_plr_3_end_scenario_0", "J_Head" );
        p_weasel scripts\zm\zmqol_subtitles::zmqol_subs_raw_line( "vox_plr_3_end_scenario_0" );
    }

    wait 1;

    foreach ( player in a_player_team )
    {
        level thread maps\mp\zm_prison_sq_final::final_showdown_create_icon( player, p_weasel );
        level thread maps\mp\zm_prison_sq_final::final_showdown_create_icon( p_weasel, player );
    }

    wait 10;

    if ( isdefined( player_2 ) )
    {
        str_alias = "vox_plr_" + player_2.characterindex + "_end_scenario_1";
        player_2 playsoundontag( str_alias, "J_Head" );
        player_2 scripts\zm\zmqol_subtitles::zmqol_subs_raw_line( str_alias );
    }
    else if ( isdefined( player ) )
    {
        str_alias = "vox_plr_" + player.characterindex + "_end_scenario_1";
        player playsoundontag( str_alias, "J_Head" );
        player scripts\zm\zmqol_subtitles::zmqol_subs_raw_line( str_alias );
    }

    wait 4;

    if ( isdefined( p_weasel ) )
    {
        p_weasel playsoundontag( "vox_plr_3_end_scenario_1", "J_Head" );
        p_weasel scripts\zm\zmqol_subtitles::zmqol_subs_raw_line( "vox_plr_3_end_scenario_1" );
        p_weasel.dontspeak = 0;
        p_weasel setclientfieldtoplayer( "isspeaking", 0 );
    }

    foreach ( player in a_player_team )
    {
        player.dontspeak = 0;
        player setclientfieldtoplayer( "isspeaking", 0 );
    }
}

zmqol_final_battle_reveal()
{
    self endon( "death_or_disconnect" );

    str_alias = "vox_plr_" + self.characterindex + "_end_scenario_0";
    self playsoundwithnotify( str_alias, "showdown_icon_reveal" );
    self scripts\zm\zmqol_subtitles::zmqol_subs_raw_line( str_alias );
    self waittill( "showdown_icon_reveal" );
}
