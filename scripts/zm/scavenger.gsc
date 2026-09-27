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
//  THE BOLT. BO1 spawns a second weapon where the bolt lands: the timed sticky
//  grenade sniper_explosive_bolt_zm (and an _upgraded_ twin). Its showIndicator
//  1 + indicatorIcon hud_indicator_sniper_explosive is what draws the warning
//  round the crosshair, the frag-grenade indicator with the Scavenger's bolt
//  icon. Only a grenade def gets that from the engine; a scripted HUD waypoint
//  over the bolt looked wrong in game (user, 2026-09-28, with screenshots).
//
//  🛑 ONE BOLT DEF, NOT TWO. Every weapon def costs one slot of the engine's
//  253-weapon table on every map it loads on (motd-port-001\BUDGET.md), and
//  the TranZit survival locations sit at 252 with the Scavenger, the MM1 and
//  the Bloodhound (bloodhound-port-001\live\r2-table-town.txt). So there is
//  one bolt, weapons\zm\scavenger_bolt_zm (T6's own crossbow explosive_bolt_mp
//  with BO1's bolt values), and it deals no damage: the rifle's projectile
//  bursts on impact like an Origins staff (projImpactExplode 1, radius 1 /
//  damage 1: staff_air_zm's values), the engine raises "projectile_impact" on
//  the shooter, this file launches the bolt grenade into that spot so it sticks
//  there, and runs BO1's fuse, blast and death mist itself. Everything the PaP
//  bolt did differently (radius 480, the _ug fx, the PaP sound) is script-side
//  already; only BO1's PaP indicatorRadius (320, vs 384) is not kept. 3 slots.
//
//  WHERE IT IS REGISTERED. The Scavenger (3 slots) goes on the maps with room:
//  TranZit's 7 survival locations (252 -> 253, the ceiling), Buried classic
//  (250 -> 251) and Maze (243 -> 244). Nuketown, Die Rise, Mob, Docks, TranZit
//  classic and Origins have no room (Docks' spare went to the Bloodhound,
//  agreed on coop 2026-09-27). zm_expanded.csc's twin uses the same test.
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
    precacheitem( "scavenger_bolt_zm" );
    precachemodel( "t5_weapon_zom_sniper_projectile" );
    //  The bolt def's indicatorIcon: BO1's hud_indicator_sniper_explosive
    //  (64x64, out of zombie_coast.ff), on BO2's own grenade-icon material.
    precacheshader( "scav_hud_indicator_bolt" );

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

    //  BO1's own tuning (sniper_explosive_bolt_zm / _upgraded_zm: fuseTime 3,
    //  explosionRadius 360 / 480, explosionInner/OuterDamage 10000). The
    //  indicator's range, BO1's indicatorRadius 384, is in the bolt def.
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

//  The stuck bolt. The rifle's shot has just burst at v_point, so the bolt
//  grenade (weapons\zm\scavenger_bolt_zm, "Stick to all") is launched into that
//  same spot from a little way back along the shot. It sticks where the shot
//  landed, on a wall, the floor or a zombie, and rides a zombie the way BO1's
//  did. Being a grenade with showIndicator 1, it is what makes the engine draw
//  BO1's warning: the Scavenger bolt icon and arrow round the crosshair,
//  inside BO1's indicatorRadius (384).
//
//  The grenade's own fuse is set a second past BO1's 3 s, so this thread, not
//  the engine, times the blast; the def deals no damage and plays no blast of
//  its own either way. Its position is read every frame, so a bolt that goes
//  away early (the zombie it rode was deleted) still blows where it last was.
scavenger_bolt( v_point, b_upgraded )
{
    v_eye = self geteye();
    v_dir = vectornormalize( v_point - v_eye );

    //  40 back clears a zombie's collision box however the shot entered it;
    //  that stretch of the shot line was just flown by the rifle's projectile,
    //  so nothing solid is in it. A point-blank shot starts at the eye.
    n_back = distance( v_eye, v_point ) - 4;

    if ( n_back > 40 )
        n_back = 40;

    if ( n_back < 0 )
        n_back = 0;

    e_bolt = self magicgrenadetype( "scavenger_bolt_zm", v_point - v_dir * n_back, v_dir * 2000, level.scavenger_fuse + 1 );

    //  BO1: wpn_ubersniper_bomb_rampup on the bolt, then the blast
    if ( isdefined( e_bolt ) )
        e_bolt playsound( "scav_bomb_rampup" );
    else
        playsoundatposition( "scav_bomb_rampup", v_point );

    v_blast = v_point;
    b_rode = 0;
    n_end = gettime() + level.scavenger_fuse * 1000;

    while ( gettime() < n_end )
    {
        if ( isdefined( e_bolt ) )
        {
            v_blast = e_bolt.origin;
            b_rode = isdefined( e_bolt getlinkedent() );
        }

        wait 0.05;
    }

    if ( isdefined( e_bolt ) )
    {
        v_blast = e_bolt.origin;
        b_rode = isdefined( e_bolt getlinkedent() );
        e_bolt delete();
    }

    //  a bolt riding a zombie sits in its body; lift the blast clear of it
    if ( b_rode )
        v_blast = v_blast + ( 0, 0, 10 );

    self scavenger_explode( v_blast, b_upgraded );
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
    //
    //  SCAVENGER BUFF (GAME 3, dvar scavenger_buff). Pack-a-Punched only, the
    //  same rule as WINTERS HOWL BUFF: the blast deals each zombie its own
    //  remaining health, so it kills at any round without a constant that
    //  could overflow. (The only boss hook, Mob's Brutus, is on a map this gun
    //  is not registered on.)
    b_buff = b_upgraded && getdvarint( "scavenger_buff" ) == 1;
    a_zombies = getaispeciesarray( level.zombie_team, "all" );
    n_radius_sq = n_radius * n_radius;

    for ( i = 0; i < a_zombies.size; i++ )
    {
        e_zombie = a_zombies[i];

        if ( !isdefined( e_zombie ) || !isalive( e_zombie ) )
            continue;

        if ( distancesquared( e_zombie.origin, v_blast ) > n_radius_sq )
            continue;

        n_damage = level.scavenger_damage;

        if ( b_buff && isdefined( e_zombie.health ) && e_zombie.health > n_damage )
            n_damage = e_zombie.health;

        if ( isdefined( self ) && isplayer( self ) )
            e_zombie dodamage( n_damage, v_blast, self, self, "none", "MOD_GRENADE_SPLASH", 0, str_weapon );
        else
            e_zombie dodamage( n_damage, v_blast, undefined, undefined, "none", "MOD_GRENADE_SPLASH", 0, str_weapon );
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
