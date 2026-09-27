// ============================================================================
//  scavenger.gsc  -  THE SCAVENGER, Call of the Dead's explosive sniper (BO1)
//
//  User, 2026-09-27: port it "as seamlessly as possible ... no missing textures,
//  no missing sounds, no missing scope overlays, pack-a-punch textures".
//  Models, anims, art, sounds and fx come straight out of BO1's zombie_coast.ff
//  (zone_source\mod_scavenger.zone has the list and where each came from).
//
//  WHAT BO1 DOES, AND WHAT THIS FILE REPRODUCES
//  (maps\_zombiemode_weap_sniper_explosive.gsc + sniper_explosive_bolt_zm def)
//    - the rifle fires a bolt that sticks where it lands, beeps, and blows up
//      3 seconds later: radius 360 (480 Pack-a-Punched), 10000 damage inside;
//    - a zombie the blast kills turns to mist (fx_zmb_coast_jackal_death), with
//      no body left behind, and still pays death points;
//    - the Hyena Infra-dead's scope is an infrared scope.
//
//  🛑 WHY THE BOLT IS SCRIPTED. BO1 spawns a second weapon, the timed grenade
//  sniper_explosive_bolt_zm, where the bolt lands. Every weapon def costs one
//  slot of the engine's 253-weapon table on every map it loads on, and the maps
//  that fit this gun have 2 spare (modding-jobs\motd-port-001\BUDGET.md). So
//  the rifle's projectile bursts on impact like an Origins staff
//  (projImpactExplode 1, radius 1 / damage 1: staff_air_zm's values), the
//  engine raises "projectile_impact" on the shooter, and this file plants the
//  bolt model there and runs BO1's fuse. 2 slots instead of 4.
//
//  WHERE IT IS REGISTERED. The weapon table ceiling is 253 per map and most
//  maps are within 0-3 of it after the MM1 and dual Browning. The Scavenger
//  (2 slots) goes on the maps with room: TranZit's 7 survival locations,
//  Buried classic and Maze. Nuketown, Die Rise, Mob, Docks, TranZit classic
//  and Origins have no room (Docks' spare went to the Bloodhound, agreed on
//  coop 2026-09-27). zm_expanded.csc's twin uses the same test.
//
//  🛑 WHY THIS IS ITS OWN FILE. quality_of_life.gsc is full on symbols; any new
//  call there can stop an unrelated import resolving and kill every map
//  (AGENTS.md item 1b). This file installs itself from its own init().
// ============================================================================

#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;
//  add_zombie_weapon() lives here; without it the map dies on "Unresolved external".
#include maps\mp\zombies\_zm_weapons;

init()
{
    map = getdvar( "mapname" );
    mode = getdvar( "ui_zm_gamemodegroup" );

    if ( !scavenger_enabled( map, mode ) )
    {
        println( "[zm_qol] scavenger: held back on " + map + " / " + mode + " - weapon budget" );
        return;
    }

    precacheitem( "scavenger_zm" );
    precacheitem( "scavenger_upgraded_zm" );
    precachemodel( "t5_weapon_zom_sniper_projectile" );

    //  Raw .efx in mod.iwd load only through a SERVER loadfx (the Wunderfizz
    //  lesson, tools\check-client-fx-precache.py). The four flash / trail names
    //  are also what the two defs name; loading them here is what makes the
    //  defs' names resolve.
    level._effect["scavenger_flash"] = loadfx( "weapon/jackal/fx_jackal_muzzleflash" );
    level._effect["scavenger_flash_ug"] = loadfx( "weapon/jackal/fx_jackal_muzzleflash_ug" );
    level._effect["scavenger_trail"] = loadfx( "weapon/jackal/fx_jackal_trail" );
    level._effect["scavenger_trail_ug"] = loadfx( "weapon/jackal/fx_jackal_trail_ug" );
    level._effect["scavenger_trail_ring"] = loadfx( "weapon/jackal/fx_jackal_trail_ring_emit" );
    level._effect["scavenger_trail_ring_ug"] = loadfx( "weapon/jackal/fx_jackal_trail_ring_emit_ug" );
    level._effect["scavenger_exp"] = loadfx( "weapon/jackal/fx_jackal_exp" );
    level._effect["scavenger_exp_ug"] = loadfx( "weapon/jackal/fx_jackal_exp_ug" );
    level._effect["scavenger_death_mist"] = loadfx( "maps/zombie/fx_zmb_coast_jackal_death" );

    include_weapon( "scavenger_zm" );
    include_weapon( "scavenger_upgraded_zm", 0 );

    //  Cost 50 and the DSR-50's pickup vox are stock's for a box sniper
    //  (zm_buried.gsc / zm_transit.gsc add_zombie_weapon dsr50_zm).
    add_zombie_weapon( "scavenger_zm", "scavenger_upgraded_zm", &"ZMWEAPON_SCAVENGER", 50, "wpck_dsr50", "", undefined, 1 );

    //  BO1's own tuning (sniper_explosive_bolt_zm / _upgraded_zm).
    level.scavenger_fuse = 3;
    level.scavenger_radius = 360;
    level.scavenger_radius_ug = 480;
    level.scavenger_damage = 10000;

    maps\mp\zombies\_zm_spawner::register_zombie_death_animscript_callback( ::scavenger_death_response );
    level thread scavenger_on_player_connect();

    println( "[zm_qol] scavenger: registered on " + map + " / " + mode );
}

//  Keep in step with zm_expanded.csc's twin.
scavenger_enabled( map, mode )
{
    if ( map == "zm_transit" )
        return mode == "zsurvival";

    if ( map == "zm_buried" )
        return mode == "zclassic" || mode == "zsurvival";

    return 0;
}

scavenger_on_player_connect()
{
    for (;;)
    {
        level waittill( "connecting", player );
        player thread scavenger_watch_impact();
    }
}

scavenger_watch_impact()
{
    self endon( "disconnect" );

    for (;;)
    {
        self waittill( "projectile_impact", str_weapon, v_point );

        if ( !isdefined( str_weapon ) || !isdefined( v_point ) )
            continue;

        if ( str_weapon == "scavenger_zm" )
            self thread scavenger_bolt( v_point, 0 );
        else if ( str_weapon == "scavenger_upgraded_zm" )
            self thread scavenger_bolt( v_point, 1 );
    }
}

//  The stuck bolt: BO1's model where the shot landed, following a zombie it hit
//  the way BO1's bolt rode its target (the sticky grenade stuck to the AI).
scavenger_bolt( v_point, b_upgraded )
{
    e_bolt = spawn( "script_model", v_point );
    e_bolt setmodel( "t5_weapon_zom_sniper_projectile" );
    e_bolt.angles = self getplayerangles();

    e_target = scavenger_bolt_target( v_point );

    if ( isdefined( e_target ) )
        e_bolt linkto( e_target, "j_spine4" );

    //  BO1: wpn_ubersniper_bomb_rampup on the bolt, then the blast
    e_bolt playsound( "scav_bomb_rampup" );

    wait( level.scavenger_fuse );

    v_blast = e_bolt.origin;

    if ( isdefined( e_target ) )
        v_blast = v_blast + ( 0, 0, 10 );

    e_bolt delete();

    self scavenger_explode( v_blast, b_upgraded );
}

scavenger_bolt_target( v_point )
{
    a_zombies = getaispeciesarray( level.zombie_team, "all" );
    e_best = undefined;
    n_best = 1024;

    for ( i = 0; i < a_zombies.size; i++ )
    {
        if ( !isalive( a_zombies[i] ) )
            continue;

        n_dist = distancesquared( a_zombies[i] gettagorigin( "j_spine4" ), v_point );

        if ( n_dist < n_best )
        {
            n_best = n_dist;
            e_best = a_zombies[i];
        }
    }

    return e_best;
}

scavenger_explode( v_blast, b_upgraded )
{
    n_radius = level.scavenger_radius;
    str_fx = "scavenger_exp";
    str_sound = "scav_bomb_explo";
    str_weapon = "scavenger_zm";

    if ( b_upgraded )
    {
        n_radius = level.scavenger_radius_ug;
        str_fx = "scavenger_exp_ug";
        str_sound = "scav_bomb_explo_pap";
        str_weapon = "scavenger_upgraded_zm";
    }

    playfx( level._effect[str_fx], v_blast );
    playsoundatposition( str_sound, v_blast );
    earthquake( 0.4, 1, v_blast, n_radius );

    //  The engine's radiusdamage can miss what an .efx-driven blast looks like
    //  it covers (bouncingbetty.gsc measured 0 of 3), so the kill is per zombie:
    //  every living zombie inside the radius, with the blast's own falloff from
    //  10000 at the centre. The attacker is the shooter, so points, kills,
    //  powerup drops and the insta-kill / double points rules are stock's.
    a_zombies = getaispeciesarray( level.zombie_team, "all" );
    n_radius_sq = n_radius * n_radius;

    for ( i = 0; i < a_zombies.size; i++ )
    {
        e_zombie = a_zombies[i];

        if ( !isdefined( e_zombie ) || !isalive( e_zombie ) )
            continue;

        if ( distancesquared( e_zombie.origin, v_blast ) > n_radius_sq )
            continue;

        if ( isdefined( self ) && isplayer( self ) )
            e_zombie dodamage( level.scavenger_damage, v_blast, self, self, "none", "MOD_GRENADE_SPLASH", 0, str_weapon );
        else
            e_zombie dodamage( level.scavenger_damage, v_blast, undefined, undefined, "none", "MOD_GRENADE_SPLASH", 0, str_weapon );
    }
}

//  BO1's sniper_explosive_death_response(): a zombie the blast kills turns to
//  mist. Returning true tells _zm_spawner that this callback owns the death, so
//  stock's own points call is skipped there; this pays it instead, exactly the
//  way BO1's player_add_points( "death" ) did.
scavenger_death_response()
{
    if ( !isdefined( self.damageweapon ) || !isdefined( self.damagemod ) )
        return 0;

    if ( self.damageweapon != "scavenger_zm" && self.damageweapon != "scavenger_upgraded_zm" )
        return 0;

    if ( self.damagemod != "MOD_GRENADE_SPLASH" )
        return 0;

    self thread scavenger_death_mist();
    return 1;
}

scavenger_death_mist()
{
    v_mist = self gettagorigin( "J_SpineLower" );

    if ( isdefined( self.attacker ) && isplayer( self.attacker ) )
        level maps\mp\zombies\_zm_spawner::zombie_death_points( self.origin, self.damagemod, self.damagelocation, self.attacker, self );

    self maps\mp\zombies\_zm_spawner::zombie_eye_glow_stop();
    playfx( level._effect["scavenger_death_mist"], v_mist );
    self hide();
    wait 0.4;

    if ( isdefined( self ) )
        self delete();
}
