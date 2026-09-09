// ============================================================================
//  zapgun.gsc  -  THE WAVE GUN / ZAP GUNS, COMPLETE                (v2.10.14)
// ----------------------------------------------------------------------------
//  v2.9.18-v2.10.13 shipped the split Zap Guns alone, on the zm_ezz3.0
//  package's converted models, because the combined Wave Gun existed only in T5
//  form and nothing on this machine could compile a T6 xmodel. The user's
//  directive of 2026-09-03 delivered the missing half: Zombies Declassified
//  BETA 1 (Logo2K's PC port of the cancelled BO2 DLC5) ships Moon as a native
//  T6 zone, and that zone carries Treyarch's ENTIRE Wave Gun package in T6
//  form - the six weapon defs, the six models, 49 view anims, all 28 effects,
//  the sound bank, and this very script's T6 original,
//  maps\mp\zombies\_zm_weap_microwavegun.gsc. Nothing below is a lookalike.
//
//  THIS FILE IS THAT T6 ORIGINAL, PORTED. It was carved out of the DLC5
//  zm_moon.ff and decompiled with gsc-tool (scratchpad gsc_carve\, checkpoint
//  201); every function keeps its original name and order so a diff against
//  the decompile reads line for line. Every stock API it leans on was
//  grep-verified in the gsc-dump on 2026-09-03: register_zombie_damage_callback
//  and register_zombie_death_animscript_callback (_zm_spawner core - the older
//  banner here that claimed T6 lacked them was wrong), get_round_enemy_array,
//  get_array_of_closest, pointonsegmentnearesttopoint, damageconetrace,
//  network_safe_play_fx_on_tag, hasanimstatefromasd, "thundergun_fling" score.
//  Stock's own core already knows these weapon names: _zm_magicbox draws the
//  second gun in the box, _zm_perks upgrades the dual pair when you Pack-a-Punch
//  holding the combined gun, _zm_audio excludes microwave kills from the kill
//  counter, _zm.gsc lists the pair as pistols.
//
//  WHAT DIFFERS FROM THE ORIGINAL, AND WHY (each one measured, none guessed):
//   1. NO CLIENTFIELDS. Moon registers two 1-bit "actor" fields for the client
//      sizzle visuals. On every map this mod runs on, only the instant-pop
//      branch of microwavegun_sizzle_zombie is reachable (see 2), and that
//      branch's whole client job is one fx + one sound at the zombie - so the
//      pop is broadcast from the server here (zmqol_mgun_pop), like every other
//      broadcast effect in this mod. zapgun.csc carries the include_weapon
//      mirror only.
//
//      🛑 CORRECTED 2026-09-06 - THE BIT BUDGET WAS NEVER THE REASON, AND THE
//      OLD "31/32" HERE WAS ORIGINS' NUMBER ON A MAP THIS GUN IS SWITCHED OFF
//      FOR. Re-measured from the per-map dumps in T6-Data-Archive-main\ZM\
//      Clientfields\ (awk '$1=="actor"{s+=$4}'), the actor set on the four maps
//      this gun DOES run on is nearly empty:
//          zm_transit  4-5 / 32      zm_highrise 4-5 / 32
//          zm_nuked      4 / 32      zm_prison  11-13 / 32
//      (32/32 is zm_buried and 31/32 is zm_tomb - the two maps in the gate
//      above.) Two 1-bit fields would fit with room to spare. The real blocker
//      is the material, see 2. Do not restore the fields expecting the swell.
//   2. THE SWELL IS UNREACHABLE, FOR TWO INDEPENDENT REASONS. Both measured
//      2026-09-06, either one alone is fatal to it:
//        a) THE ANIMATION. The zm_death_sizzle / zm_death_zap animstates live
//           in Moon's aitypes; a stock aitype's compiled anim list cannot take
//           them (§45), so hasanimstatefromasd() is false everywhere here and
//           the original's own fallbacks run. No float-up death.
//        b) THE SHADER. Moon's microwavegun_bloat() (its .csc, decompiled from
//           the DLC5 zone) is not an fx at all - it ramps a shader constant,
//           mapshaderconstant(...,"scriptVector3") then setshaderconstant with
//           the fraction in the W component, 0 -> 0.5 over 2500 ms. That only
//           renders because Moon's zombie materials carry a MaximumSwell
//           constant (literal 20,0,0,1) on the techset
//           mc_sw4_3d_char_cloth_4z8fq5wu_DLC5. Retail's zombie material -
//           mc/mtl_c_zom_dlc0_zombie_hazmat_body_1, techset
//           mc_sw4_3d_char_cloth_4z8fq5wu, no _dlc5 - dumps "constants": [].
//           So the call would be a silent no-op here. Delivering the swell
//           means owning a DLC5 techset plus a re-authored material for every
//           zombie body variant on every map, which changes how all zombies
//           render at all times - not a Wave Gun change.
//      🌟 AND THE FALLBACK IS NOT A COMPROMISE: on a map with no sizzle
//      animstate Moon's OWN code takes the same instant_explode branch, which
//      sets the expand clientfield with initial_hit_occurred still false, and
//      that lands on its client else-branch = the mist fx + wpn_mgun_explode_
//      zombie. Byte for byte what zmqol_mgun_pop() does from the server.
//      The animstate code is kept verbatim so the diff stays honest.
//   3. NO VOICE LINES. Moon's kill/pickup vox ("micro_single", "micro_dual",
//      "wpck_microwave") are Moon-character aliases no stock map carries, so the
//      create_and_play_dialog calls are out and the pickup vox category is "".
//   4. THE BOSS HOOK AND THE SHIELD GUARD, like the three sibling guns: on Mob
//      the first hit takes Brutus's helmet, the second kills
//      (zm_prison.gsc zmqol_brutus_ww_hit); magic-bullet-shielded zombies are
//      left to their scripts.
//   5. THE DAMAGE-MOD TEST IS WIDER. Moon accepts the zap only as MOD_IMPACT.
//      Nothing here could measure what mod a retail projectile impact reports,
//      so any non-melee damage from a zap-gun def counts - the def cannot deal
//      any other kind, so the wider test cannot misfire.
//   6. The dev-only debug prints and the never-threaded microwavegun_sound_thread
//      are dropped.
//
//  🛑 MAP GATE: off on Buried and Origins, exactly like its three siblings
//  (teslagun.gsc's banner: those two sit at engine ceilings and adding more
//  crashes them). The gate MUST stay identical to zapgun.csc - a box weapon
//  included on one side only is the EXE_CLIENT_FIELD_MISMATCH class.
// ============================================================================
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_net;
#include maps\mp\zombies\_zm_weapons;
#include maps\mp\zombies\_zm_spawner;
#include maps\mp\zombies\_zm_score;

init()
{
    //  Same kill switch as the other three wonder weapons, same reason
    //  ("" or "1" = on, "5" = this gun alone; teslagun.gsc:26).
    str_ww = getdvar( "zmqol_ww" );

    if ( str_ww != "" && str_ww != "1" && str_ww != "5" )
        return;

    if ( getdvar( "mapname" ) == "zm_buried" || getdvar( "mapname" ) == "zm_tomb" )
        return;

    precachestring( &"ZOMBIE_WEAPON_MICROWAVEGUNDW" );
    precachestring( &"ZOMBIE_WEAPON_MICROWAVEGUNDW_UPGRADED" );
    precachestring( &"ZOMBIE_WEAPON_MICROWAVEGUN" );
    precachestring( &"ZOMBIE_WEAPON_MICROWAVEGUN_UPGRADED" );

    //  Moon's own registration (zm_moon.gsc decompile :897-898, :906, :1416):
    //  the box weapon is the dual pair; the left-hand halves come off the defs'
    //  DualWieldWeapon field and the combined gun off altWeapon, so neither is
    //  included on its own. The left-hand models are precached explicitly
    //  because _zm_magicbox::get_left_hand_weapon_model_name asks for them.
    include_weapon( "microwavegundw_zm" );
    include_weapon( "microwavegundw_upgraded_zm", 0 );
    add_limited_weapon( "microwavegundw_zm", 1 );   // lifted by NO BOX LIMITS like its siblings
    add_zombie_weapon( "microwavegundw_zm", "microwavegundw_upgraded_zm", &"ZOMBIE_WEAPON_MICROWAVEGUNDW", 10, "", "", undefined );

    //  🛑 v2.11.3 - THE TWO UPGRADED FORMS T6 NEVER HEARD ABOUT.
    //  Moon's registration above is BO1's, and it is right for BO1: only the
    //  dual pair is a box weapon, the combined gun comes off altWeapon and the
    //  left half off DualWieldWeapon, so neither is add_zombie_weapon()'d.
    //  T6 then inherits a gap BO1 never had, because T6 decides a Pack-a-Punch
    //  camo in _zm_weapons::get_pack_a_punch_weapon_options(), whose FIRST line
    //  is
    //          if ( !is_weapon_upgraded( weapon ) )
    //              return self calcweaponoptions( 0, 0, 0, 0 );
    //  and is_weapon_upgraded() (:1820) reads exactly one table -
    //  level.zombie_weapons_upgraded - which only add_zombie_weapon() (:546)
    //  ever writes. So microwavegun_upgraded_zm (the combined Wave Gun) and
    //  microwavegunlh_upgraded_zm (the left Zap Gun) report NOT upgraded and are
    //  handed camo index 0 - no camo at all, guaranteed, whatever the animated
    //  camo option says. Every other weapon this mod adds registers its own
    //  _upgraded_zm name; these two were the only ones that did not (swept
    //  2026-09-03 over every add_zombie_weapon call in the mod).
    //
    //  Writing the table directly rather than calling add_zombie_weapon() is
    //  deliberate: add_zombie_weapon() also builds a level.zombie_weapons struct
    //  and a "weapon_<name>" classname, which would offer these two as box/wall
    //  weapons in their own right - exactly what Moon's comment above says must
    //  not happen. The upgrade map is the only part T6's camo path reads.
    //
    //  Nothing else iterates this table; its four stock readers are
    //  is_weapon_upgraded (:1828), get_base_weapon_name (:1752-1753) and the two
    //  name lookups at :1933 and :1953, all of which want exactly this answer -
    //  these weapons ARE upgraded. It also makes .unpack work on them.
    if ( isdefined( level.zombie_weapons_upgraded ) )
    {
        level.zombie_weapons_upgraded[ "microwavegun_upgraded_zm" ]   = "microwavegun_zm";
        level.zombie_weapons_upgraded[ "microwavegunlh_upgraded_zm" ] = "microwavegunlh_zm";
        println( "[zm_qol] zapgun: registered microwavegun_upgraded_zm + microwavegunlh_upgraded_zm as upgraded (PaP camo path)" );
    }

    precachemodel( getweaponmodel( "microwavegunlh_zm" ) );
    precachemodel( getweaponmodel( "microwavegunlh_upgraded_zm" ) );

    maps\mp\zombies\_zm_spawner::register_zombie_damage_callback( ::microwavegun_zombie_damage_response );
    maps\mp\zombies\_zm_spawner::register_zombie_death_animscript_callback( ::microwavegun_zombie_death_response );

    set_zombie_var( "microwavegun_cylinder_radius", 180 );
    set_zombie_var( "microwavegun_sizzle_range", 480 );

    //  The nine effects the server plays. All 28 of the family are mod.ff assets
    //  copied out of the DLC5 zone (zone_source\mod_wavegun.zone).
    // Private storage survives map initialization resetting level._effect.
    level.zmqol_mgun_effects = [];
    level.zmqol_mgun_effects["microwavegun_zap_shock_dw"]         = loadfx( "weapon/microwavegun/fx_zap_shock_dw" );
    level.zmqol_mgun_effects["microwavegun_zap_shock_eyes_dw"]    = loadfx( "weapon/microwavegun/fx_zap_shock_eyes_dw" );
    level.zmqol_mgun_effects["microwavegun_zap_shock_lh"]         = loadfx( "weapon/microwavegun/fx_zap_shock_lh" );
    level.zmqol_mgun_effects["microwavegun_zap_shock_eyes_lh"]    = loadfx( "weapon/microwavegun/fx_zap_shock_eyes_lh" );
    level.zmqol_mgun_effects["microwavegun_zap_shock_ug"]         = loadfx( "weapon/microwavegun/fx_zap_shock_ug" );
    level.zmqol_mgun_effects["microwavegun_zap_shock_eyes_ug"]    = loadfx( "weapon/microwavegun/fx_zap_shock_eyes_ug" );
    level.zmqol_mgun_effects["microwavegun_sizzle_blood_eyes"]    = loadfx( "weapon/microwavegun/fx_sizzle_blood_eyes" );
    level.zmqol_mgun_effects["microwavegun_sizzle_death_mist"]    = loadfx( "weapon/microwavegun/fx_sizzle_mist" );
    level.zmqol_mgun_effects["microwavegun_sizzle_death_mist_low_g"] = loadfx( "weapon/microwavegun/fx_sizzle_mist_low_g" );

    level._microwaveable_objects = [];

    //  Host sweep + connect loop, the bouncingbetty.gsc lesson: the host is
    //  "connected" before a root script's init() runs. Moon waits on
    //  "connecting" from its own map script, which runs earlier than we do.
    a_players = get_players();

    for ( i = 0; i < a_players.size; i++ )
        a_players[i] thread wait_for_microwavegun_fired();

    level thread microwavegun_on_player_connect();
    level thread zmqol_ww_screecher_zap_hook();   // denizens (v2.12.5)
}

add_microwaveable_object( ent )
{
    level._microwaveable_objects = add_to_array( level._microwaveable_objects, ent, 0 );
}

remove_microwaveable_object( ent )
{
    arrayremovevalue( level._microwaveable_objects, ent );
}

microwavegun_on_player_connect()
{
    for ( ;; )
    {
        level waittill( "connected", player );
        player thread wait_for_microwavegun_fired();
    }
}

wait_for_microwavegun_fired()
{
    self endon( "disconnect" );
    self notify( "zmqol_wait_for_microwavegun_fired" );
    self endon( "zmqol_wait_for_microwavegun_fired" );
    self waittill( "spawned_player" );

    for ( ;; )
    {
        self waittill( "weapon_fired" );
        currentweapon = self getcurrentweapon();

        if ( currentweapon == "microwavegun_zm" || currentweapon == "microwavegun_upgraded_zm" )
            self thread microwavegun_fired( currentweapon == "microwavegun_upgraded_zm" );
    }
}

microwavegun_network_choke( shot )
{
    shot.choke_count++;

    if ( !( shot.choke_count % 10 ) )
    {
        wait_network_frame();
        wait_network_frame();
        wait_network_frame();
    }
}

microwavegun_fired( upgraded )
{
    self endon( "disconnect" );

    // Damage dispatch yields after ten targets. Keep each shot's targets and
    // pacing together so another firing thread cannot overwrite them.
    shot = spawnstruct();
    shot.enemies = [];
    shot.vecs = [];
    shot.choke_count = 0;
    self microwavegun_get_enemies_in_range( upgraded, 0, shot );
    self microwavegun_get_enemies_in_range( upgraded, 1, shot );

    for ( i = 0; i < shot.enemies.size; i++ )
    {
        microwavegun_network_choke( shot );
        if ( isdefined( shot.enemies[i] ) )
            shot.enemies[i] thread microwavegun_sizzle_zombie( self, shot.vecs[i], i );
    }
}

// ============================================================================
//  zmqol_ww_sizzle_target_list  -  THE WAVE GUN NOW HITS DENIZENS   (v2.11.26)
// ============================================================================
//  User, 2026-09-04, TranZit: *"the wave gun for some reason doesn't deal any
//  damage to the denizens whilst i was testing in tranzit"*.
//
//  🌟 MEASURED CAUSE, one flag. The sizzle cone built its candidate list from
//  get_round_enemy_array() (_zm_utility.gsc), and that function's whole body is
//
//      enemies = getaispeciesarray( level.zombie_team, "all" );
//      ... if ( isdefined( enemies[i].ignore_enemy_count ) && enemies[i].ignore_enemy_count )
//              continue;
//
//  and the denizen sets exactly that flag on itself at spawn -
//  _zm_ai_screecher.gsc:376, `self.ignore_enemy_count = 1`, four lines after
//  `self.isscreecher = 1`. So a denizen was never a candidate and the beam
//  passed straight through it. Nothing was wrong with the damage; the target
//  was never in the list.
//
//  🛑 THE FIX ADDS DENIZENS AND NOTHING ELSE. Every special AI in the game
//  carries that same flag - Brutus, the Ghost, the Sloth, Mechz, the Avogadro -
//  and sweeping them all in would quietly turn the Wave Gun into a boss-killer
//  nobody asked for. The list is widened by the denizen's OWN marker,
//  self.isscreecher, so only denizens come back. Everything they then go
//  through is the path a normal zombie already takes.
//
//  📝 Nothing leaks. screecher_cleanup() (_zm_ai_screecher.gsc:924) is threaded
//  at spawn and parks on `self waittill( "death" )`, so the dodamage kill runs
//  it and level.zombie_screecher_count is decremented exactly as it is for any
//  other denizen death. The pop fx already falls back from J_SpineLower to
//  J_Spine1 to getcentroid(), so a rig without those tags costs the garnish and
//  never the kill.
//
//  📝 Built by hand rather than with arraycombine(): that name is nowhere in
//  the stock dump's own utility files, so its signature would have been a
//  guess. get_round_enemy_array() reads the same getaispeciesarray() this does
//  and drops every denizen, so the two halves cannot overlap.
// ============================================================================
zmqol_ww_sizzle_target_list()
{
    a_out = get_round_enemy_array();
    a_ai = getaispeciesarray( level.zombie_team, "all" );

    for ( i = 0; i < a_ai.size; i++ )
    {
        if ( !isdefined( a_ai[i] ) || !isalive( a_ai[i] ) )
            continue;

        if ( !( isdefined( a_ai[i].isscreecher ) && a_ai[i].isscreecher ) )
            continue;

        a_out[ a_out.size ] = a_ai[i];
    }

    return a_out;
}

// ============================================================================
//  zmqol_ww_screecher_zap_hook  -  THE ZAP HALF NOW KILLS DENIZENS  (v2.12.5)
// ============================================================================
//  User, 2026-09-05, TranZit: *"the wave gun for some reason deals no damage to
//  denizens"* - the SECOND report of this. v2.11.26's fix directly above is real
//  and still in place, but it only ever covered the ALT fire.
//
//  🌟 MEASURED, from the mod's own weapon defs (weapons\zm\):
//        microwavegundw_zm   primary, what you hold    damage 1, explosion 0/0
//        microwavegun_zm     altmode, the wave         damage 0, explosion 0/0
//  NEITHER gun kills anything with its own damage. The alt fire kills through
//  the sizzle cone (target list fixed in v2.11.26); the gun in your hands kills
//  through a damage CALLBACK, registered in init() with
//        _zm_spawner::register_zombie_damage_callback( ::microwavegun_zombie_damage_response )
//  so against a denizen every shot was landing its literal 1 point of damage.
//
//  🛑 AND A DENIZEN NEVER RUNS THAT CALLBACK. The chain that reaches it is
//        enemy_death_detection()             _zm_spawner.gsc:118, waittill "damage"
//          -> player_attacks_enemy()         :136
//          -> level.global_damage_func       = _zm_spawner::zombie_damage
//          -> check_zombie_damage_callbacks() :2025
//  and `enemy_death_detection` is threaded in exactly TWO places in the whole
//  stock dump: `zombie_spawn_init()` (_zm_spawner.gsc:236) for ordinary zombies,
//  and `_zm_ai_dogs.gsc:438` for the hellhounds. A denizen is set up by
//  `_zm_ai_screecher::screecher_prespawn` - hung on the map's own spawners at
//  _zm_ai_screecher.gsc:34 - which calls NEITHER. So NO registered damage
//  callback of any kind has ever fired for a denizen.
//
//  The fix threads the missing watcher on denizens ONLY, through the very
//  mechanism stock uses to give them their spawn function (add_spawn_function
//  on level.screecher_spawners), and routes a zap hit into the same response an
//  ordinary zombie already gets. No other AI is touched, ordinary zombies keep
//  going through stock's chain, and a denizen hit by anything else is unchanged.
//
//  📝 Spawn functions are THREADED, not called - `run_spawn_functions()`
//  (_zm_utility.gsc:283) dispatches each through single_thread() - so parking in
//  a waittill loop here cannot stall a spawn.
//
//  📝 Points: the response awards "death" points, and stock gives a denizen kill
//  NONE (screecher_death_func returns true and deletes the body, so
//  zombie_death_animscript's zombie_death_points never runs). Kept anyway,
//  because v2.11.26's sizzle half already awards them and the two halves of one
//  gun must not disagree. Say the word and both go silent.
// ============================================================================
zmqol_ww_screecher_zap_hook()
{
    level endon( "end_game" );

    //  level.screecher_spawners is built in _zm_ai_screecher::init(), TranZit
    //  only - hence the isdefined() rather than a map name. Waiting for the
    //  blackscreen puts this after every map init and still long before a
    //  denizen can exist: screecher_spawning_logic() parks on flag
    //  "spawn_zombies", which is later again.
    flag_wait( "initial_blackscreen_passed" );

    if ( !isdefined( level.screecher_spawners ) || !level.screecher_spawners.size )
        return;

    array_thread( level.screecher_spawners, maps\mp\zombies\_zm_utility::add_spawn_function, ::zmqol_ww_screecher_zap_watch );

    println( "[zm_qol] zapgun: denizen zap watcher armed on " + level.screecher_spawners.size + " spawner(s)" );
}

zmqol_ww_screecher_zap_watch()
{
    self endon( "death" );

    for ( ;; )
    {
        self waittill( "damage", n_amount, e_attacker );

        if ( !isdefined( e_attacker ) || !isplayer( e_attacker ) )
            continue;

        //  The same predicate the registered callback uses, over the same
        //  engine-set fields: self.damageweapon and self.damagemod are never
        //  assigned anywhere in the stock dump, so the engine fills them in
        //  before this notify.
        if ( !self is_microwavegun_dw_damage() )
            continue;

        if ( is_magic_bullet_shield_enabled( self ) )
            continue;

        //  🛑 NOT microwavegun_dw_zombie_hit_response_internal(). That function
        //  is written for something zombie_spawn_init() has set up: it reads
        //  self.isdog, self.has_legs, self.a.nodeath and hasanimstatefromasd(),
        //  and a denizen runs NONE of that init - it is built by
        //  screecher_prespawn(), which sets has_legs and nothing else on that
        //  list. Its own deathfunction (_zm_ai_screecher.gsc:1128) plays the
        //  denizen's death anim, unlinks it from whoever it was riding and
        //  deletes the body, so the death animation was never ours to choose.
        //  What is left is exactly the two lines that matter, in the order that
        //  survives: garnish first (threaded, so a rig without J_SpineUpper or
        //  J_Eyeball_LE costs the fx and never the kill), then the kill.
        self.microwavegun_dw_death = 1;

        if ( !isdefined( self.isdog ) )
            self.isdog = 0;

        self thread microwavegun_zap_death_fx( self.damageweapon );
        self dodamage( self.health + 666, self.origin, e_attacker );
        e_attacker maps\mp\zombies\_zm_score::player_add_points( "death", "", "" );
        return;
    }
}

microwavegun_get_enemies_in_range( upgraded, microwaveable_objects, shot )
{
    view_pos = self getweaponmuzzlepoint();
    test_list = undefined;
    range = level.zombie_vars["microwavegun_sizzle_range"];
    cylinder_radius = level.zombie_vars["microwavegun_cylinder_radius"];

    if ( microwaveable_objects )
    {
        test_list = level._microwaveable_objects;
        range = range * 10;
        cylinder_radius = cylinder_radius * 10;
    }
    else
        test_list = zmqol_ww_sizzle_target_list();

    zombies = get_array_of_closest( view_pos, test_list, undefined, undefined, range );

    if ( !isdefined( zombies ) )
        return;

    sizzle_range_squared = range * range;
    cylinder_radius_squared = cylinder_radius * cylinder_radius;
    forward_view_angles = self getweaponforwarddir();
    end_pos = view_pos + vectorscale( forward_view_angles, range );

    for ( i = 0; i < zombies.size; i++ )
    {
        if ( !isdefined( zombies[i] ) || isai( zombies[i] ) && !isalive( zombies[i] ) )
            continue;

        test_origin = zombies[i] getcentroid();
        test_range_squared = distancesquared( view_pos, test_origin );

        //  The list is sorted nearest-first, so the first one out of range
        //  ends the walk - the original returns here too.
        if ( test_range_squared > sizzle_range_squared )
            return;

        normal = vectornormalize( test_origin - view_pos );
        dot = vectordot( forward_view_angles, normal );

        if ( 0 > dot )
            continue;

        radial_origin = pointonsegmentnearesttopoint( view_pos, end_pos, test_origin );

        if ( distancesquared( test_origin, radial_origin ) > cylinder_radius_squared )
            continue;

        if ( 0 == zombies[i] damageconetrace( view_pos, self ) )
            continue;

        if ( isai( zombies[i] ) )
        {
            shot.enemies[shot.enemies.size] = zombies[i];
            dist_mult = ( sizzle_range_squared - test_range_squared ) / sizzle_range_squared;
            sizzle_vec = vectornormalize( test_origin - view_pos );

            if ( 5000 < test_range_squared )
                sizzle_vec = sizzle_vec + vectornormalize( test_origin - radial_origin );

            sizzle_vec = ( sizzle_vec[0], sizzle_vec[1], abs( sizzle_vec[2] ) );
            sizzle_vec = vectorscale( sizzle_vec, 100 + 100 * dist_mult );
            shot.vecs[shot.vecs.size] = sizzle_vec;
            continue;
        }

        zombies[i] notify( "microwaved", self );
    }
}

microwavegun_sizzle_zombie( player, sizzle_vec, index )
{
    if ( !isdefined( self ) || !isalive( self ) )
        return;

    //  The boss hook first, exactly like the other three guns: on Mob the
    //  first hit takes Brutus's helmet, the second kills.
    if ( isdefined( level.zmqol_ww_boss_hit ) )
    {
        if ( self [[ level.zmqol_ww_boss_hit ]]( player ) )
            return;
    }

    //  Scripted/shielded zombies are left to their scripts - same protection
    //  as the nuke, the kill-horde command and the Betty.
    if ( is_magic_bullet_shield_enabled( self ) )
        return;

    if ( isdefined( self.microwavegun_sizzle_func ) )
    {
        self [[ self.microwavegun_sizzle_func ]]( player );
        return;
    }

    self.no_gib = 1;
    self.gibbed = 1;
    self dodamage( self.health + 666, player.origin, player );

    if ( self.health <= 0 )
    {
        points = 10;

        if ( !index )
            points = maps\mp\zombies\_zm_score::get_zombie_death_player_points();
        else if ( 1 == index )
            points = 30;

        player maps\mp\zombies\_zm_score::player_add_points( "thundergun_fling", points );
        self.microwavegun_death = 1;
        instant_explode = 0;

        //  Kept verbatim from Moon. On this mod's maps no aitype knows
        //  zm_death_sizzle (§45), so every branch lands on instant_explode.
        if ( !self.isdog )
        {
            if ( self.has_legs )
            {
                if ( self hasanimstatefromasd( "zm_death_sizzle" ) )
                    self.deathanim = "zm_death_sizzle";
                else
                {
                    self.a.nodeath = undefined;
                    instant_explode = 1;
                }
            }
            else if ( self hasanimstatefromasd( "zm_death_sizzle_crawl" ) )
                self.deathanim = "zm_death_sizzle_crawl";
            else
            {
                self.a.nodeath = undefined;
                instant_explode = 1;
            }
        }
        else
        {
            self.a.nodeath = undefined;
            instant_explode = 1;
        }

        if ( is_true( self.is_traversing ) || is_true( self.in_the_ceiling ) )
        {
            self.deathanim = undefined;
            instant_explode = 1;
        }

        if ( instant_explode )
        {
            //  Moon: setclientfield( "zombie_actor_flag_microwavegun_expand_response", 1 )
            //  -> the client plays the mist at the spine and wpn_mgun_explode_zombie.
            //  Broadcast from here instead (banner point 1).
            self zmqol_mgun_pop();
            self thread microwavegun_sizzle_death_ending();
        }
        else
        {
            //  Moon: the initial-hit clientfield (eye fx + wpn_mgun_impact_zombie)
            //  and the swell driven by the death anim's notetracks. Unreachable
            //  here; the pop is served from the "explode" notetrack the same way
            //  for parity.
            //
            //  📝 wpn_mgun_impact_zombie IS SILENT IN TREYARCH'S OWN BUILD, so
            //  nothing is being withheld. Re-confirmed 2026-09-06 by hashing the
            //  name with SND_HashName (seed 0x1505, c + 0x1003F*h, lowercased)
            //  to @cd8064c2 and finding that row in the DLC5 Moon bank
            //  zmb_blops_moon.all with an EMPTY FileSource - one of the 698
            //  payload-less aliases of §47. The same hash run over
            //  wpn_mgun_explode_zombie gives @323a08e1, whose three rows resolve
            //  to sound\_unnamed\{8a417db0,17e5f16f,a58a652e}.wav - the exact
            //  three payloads this mod already ships, which is what proves the
            //  method rather than assuming it.
            self.nodeathragdoll = 1;
            self.handle_death_notetracks = ::microwavegun_handle_death_notetracks;
        }
    }
}

//  The server-side twin of Moon's client expand response: the sizzle mist at
//  J_SpineLower (J_Spine1 when the rig has no lower spine) and the pop sound.
//  Threaded fx call through the choke-safe helper; a rig missing both tags can
//  cost the garnish but never the kill above.
zmqol_mgun_pop()
{
    fx = level.zmqol_mgun_effects["microwavegun_sizzle_death_mist"];

    if ( isdefined( self.in_low_g ) && self.in_low_g )
        fx = level.zmqol_mgun_effects["microwavegun_sizzle_death_mist_low_g"];

    str_tag = "J_SpineLower";
    v_pos = self gettagorigin( str_tag );

    if ( !isdefined( v_pos ) )
    {
        str_tag = "J_Spine1";
        v_pos = self gettagorigin( str_tag );
    }

    if ( !isdefined( v_pos ) )
        v_pos = self getcentroid();

    playfx( fx, v_pos );
    self playsound( "wpn_mgun_explode_zombie" );
}

microwavegun_handle_death_notetracks( note )
{
    if ( note == "explode" )
    {
        self zmqol_mgun_pop();
        self thread microwavegun_sizzle_death_ending();
    }
}

microwavegun_sizzle_death_ending()
{
    if ( !isdefined( self ) )
        return;

    self ghost();
    wait 0.1;
    self self_delete();
}

microwavegun_dw_zombie_hit_response_internal( mod, damageweapon, player )
{
    player endon( "disconnect" );

    if ( !isdefined( self ) || !isalive( self ) )
        return;

    //  Boss hook and shield guard, as in the sizzle above.
    if ( isdefined( level.zmqol_ww_boss_hit ) )
    {
        if ( self [[ level.zmqol_ww_boss_hit ]]( player ) )
            return;
    }

    if ( is_magic_bullet_shield_enabled( self ) )
        return;

    //  Kept verbatim from Moon; zm_death_zap is Moon-aitype only (§45), so on
    //  this mod's maps the zombie dies with its normal death animation.
    if ( !self.isdog )
    {
        if ( self.has_legs )
        {
            if ( self hasanimstatefromasd( "zm_death_zap" ) )
                self.deathanim = "zm_death_zap";
            else
                self.a.nodeath = undefined;
        }
        else if ( self hasanimstatefromasd( "zm_death_zap_crawl" ) )
            self.deathanim = "zm_death_zap_crawl";
        else
            self.a.nodeath = undefined;
    }
    else
        self.a.nodeath = undefined;

    if ( is_true( self.is_traversing ) )
        self.deathanim = undefined;

    self.microwavegun_dw_death = 1;
    self thread microwavegun_zap_death_fx( damageweapon );

    if ( isdefined( self.microwavegun_zap_damage_func ) )
    {
        self [[ self.microwavegun_zap_damage_func ]]( player );
        return;
    }
    else
        self dodamage( self.health + 666, self.origin, player );

    player maps\mp\zombies\_zm_score::player_add_points( "death", "", "" );
}

microwavegun_zap_get_shock_fx( weapon )
{
    if ( weapon == "microwavegundw_zm" )
        return level.zmqol_mgun_effects["microwavegun_zap_shock_dw"];
    else if ( weapon == "microwavegunlh_zm" )
        return level.zmqol_mgun_effects["microwavegun_zap_shock_lh"];
    else
        return level.zmqol_mgun_effects["microwavegun_zap_shock_ug"];
}

microwavegun_zap_get_shock_eyes_fx( weapon )
{
    if ( weapon == "microwavegundw_zm" )
        return level.zmqol_mgun_effects["microwavegun_zap_shock_eyes_dw"];
    else if ( weapon == "microwavegunlh_zm" )
        return level.zmqol_mgun_effects["microwavegun_zap_shock_eyes_lh"];
    else
        return level.zmqol_mgun_effects["microwavegun_zap_shock_eyes_ug"];
}

microwavegun_zap_head_gib( weapon )
{
    self endon( "death" );
    network_safe_play_fx_on_tag( "microwavegun_zap_death_fx", 2, microwavegun_zap_get_shock_eyes_fx( weapon ), self, "J_Eyeball_LE" );
}

microwavegun_zap_death_fx( weapon )
{
    tag = "J_SpineUpper";

    if ( self.isdog )
        tag = "J_Spine1";

    network_safe_play_fx_on_tag( "microwavegun_zap_death_fx", 2, microwavegun_zap_get_shock_fx( weapon ), self, tag );
    self playsound( "wpn_imp_tesla" );

    if ( is_true( self.head_gibbed ) )
        return;

    if ( isdefined( self.microwavegun_zap_head_gib_func ) )
        self thread [[ self.microwavegun_zap_head_gib_func ]]( weapon );
    else if ( "quad_zombie" != self.animname )
        self thread microwavegun_zap_head_gib( weapon );
}

microwavegun_zombie_damage_response( mod, hit_location, hit_origin, player, amount )
{
    if ( self is_microwavegun_dw_damage() )
    {
        self thread microwavegun_dw_zombie_hit_response_internal( mod, self.damageweapon, player );
        return true;
    }

    return false;
}

microwavegun_zombie_death_response()
{
    if ( self enemy_killed_by_dw_microwavegun() )
        return true;
    else if ( self enemy_killed_by_microwavegun() )
        return true;

    return false;
}

//  Banner point 5: Moon tests self.damagemod == "MOD_IMPACT"; any non-melee
//  damage from a zap-gun def counts here.
is_microwavegun_dw_damage()
{
    return isdefined( self.damageweapon ) && ( self.damageweapon == "microwavegundw_zm" || self.damageweapon == "microwavegundw_upgraded_zm" || self.damageweapon == "microwavegunlh_zm" || self.damageweapon == "microwavegunlh_upgraded_zm" ) && ( !isdefined( self.damagemod ) || self.damagemod != "MOD_MELEE" );
}

enemy_killed_by_dw_microwavegun()
{
    return is_true( self.microwavegun_dw_death );
}

is_microwavegun_damage()
{
    return isdefined( self.damageweapon ) && ( self.damageweapon == "microwavegun_zm" || self.damageweapon == "microwavegun_upgraded_zm" ) && ( self.damagemod != "MOD_GRENADE" && self.damagemod != "MOD_GRENADE_SPLASH" );
}

enemy_killed_by_microwavegun()
{
    return is_true( self.microwavegun_death );
}
