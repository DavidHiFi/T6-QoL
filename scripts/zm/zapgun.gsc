// ============================================================================
//  zapgun.gsc  -  THE WAVE GUN / ZAP GUNS, COMPLETE                (v2.15.49)
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
//   1. THE SWELL IS MOON'S SHADER ROUTE, MADE REAL ON T6 (v2.15.49). Server
//      raises zombie_actor_flag_microwavegun_expand_response on the sizzle
//      death's "expand" notetrack (registered below with Moon's exact
//      lifetime/width/type); zapgun.csc answers it with Moon's
//      microwavegun_bloat() ramp of shader constant "scriptVector3" (BO1's
//      values: X = fraction * 4.0 over 2500 ms). What reads that constant is
//      the part DLC5 never shipped: its two zombie techsets embed the RETAIL
//      vertex shader (measured: byte-identical DXBC, no scriptVector input).
//      mod_wavegun_swell.zone now compiles those techsets from raw with
//      vertex shaders rebuilt from retail's DXBC plus BO1's one bloat line
//      (worldPos += worldNormal * scriptVector3.x). The 53 zombie materials
//      keep MaximumSwell for parity with Moon's authoring; the shader does
//      not read it. The instant_explode fallback still broadcasts its pop
//      from the server (zmqol_mgun_pop) - that path never swells in Moon
//      either. Actor clientfield budget: transit/highrise 4-5/32, nuked
//      4/32, prison 11-13/32, and this adds ONE 1-bit field (measured).
//   2. THE PRE-SCALED MODEL SWELL (v2.15.45-48) IS GONE. It read as stop
//      motion (user, 2026-09-13) and could not be made smooth: precaching
//      more stages overflows G_ModelIndex (118 total loads, 148 overflows).
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

    //  🌟 THE BODY SWELL. Moon's one actor clientfield:
    //  microwavegun_handle_death_notetracks() raises it on the sizzle death's
    //  "expand" notetrack, and the client half in zapgun.csc answers it with
    //  Moon's own microwavegun_bloat() - shader constant "scriptVector3"
    //  ramped over 2500 ms, read by the swell vertex shaders this mod compiles
    //  into the two DLC5 zombie techsets (banner point 1, v2.15.49).
    //  Lifetime/width/type are Moon's own registration (zm_moon zone, :19).
    //  zapgun.csc MUST register the same field with the same numbers or the
    //  engine throws EXE_CLIENT_FIELD_MISMATCH; both files carry the identical
    //  gate above, so they always register together or not at all.
    registerclientfield( "actor", "zombie_actor_flag_microwavegun_expand_response", 15000, 1, "int" );

    //  🌟 THE SWELL IS A VERTEX SHADER AGAIN (v2.15.49). The two DLC5 zombie
    //  techsets now compile from raw with vertex shaders that carry BO1 Moon's
    //  bloat line (worldPos += worldNormal * scriptVector3.x); the client ramp
    //  in zapgun.csc drives scriptVector3 exactly as BO1 does. No pre-scaled
    //  models, no precache, no model-index budget. mod_wavegun_swell.zone has
    //  the measurements behind it. v2.15.51 weights that push from the stomach
    //  outward (SwellOffset in zone_source\swell_shader_src	6_consts.hlsli;
    //  the ramp also sends the J_SpineLower height in scriptVector3.w) so the
    //  belly leads and the limbs and head no longer inflate into each other.

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

    //  v2.15.49 - MOON'S OWN EYE FX, NOTHING ELSE. v2.15.46 swapped in the
    //  stock blood spurt because fx_sizzle_blood_eyes drew as a white stream;
    //  the cause was in mod.ff, not the fx: the wavegun donor carried three of
    //  its materials/models as data-less references (dust_mote_pcloud_blend,
    //  smk_gen_z10, fx_axis_createfx), now declared for real in
    //  mod_wavegun_swell.zone. The user wants the native effect, so this is
    //  Moon's fx on Moon's tag, and the stock spurt is gone.
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
    level thread zmqol_mgun_selftest_watch();
}

//  v2.15.45 - the selftest can be started AFTER the map is up: the watcher
//  polls the dvar, so `set zmqol_mgun_selftest 1` in the console works at any
//  time. (It used to be read only in init(), i.e. before the map load.)
zmqol_mgun_selftest_watch()
{
    level endon( "end_game" );

    for ( ;; )
    {
        wait 1;

        if ( getdvarintdefault( "zmqol_mgun_selftest", 0 ) )
        {
            level thread zmqol_mgun_selftest();
            return;
        }
    }
}

// ============================================================================
//  zmqol_mgun_selftest  -  DEV HARNESS, OFF UNLESS zmqol_mgun_selftest 1
// ----------------------------------------------------------------------------
//  Fires the combined Wave Gun for a headless test session so the sizzle path
//  can be exercised without a person at the keyboard. It calls the REAL entry
//  point (microwavegun_fired), so what it proves is what a trigger pull does -
//  it is not a second implementation.
//
//  With zmqol_mgun_debug 1 the log then says, per kill, whether the death
//  animation branch or the instant_explode fallback ran, which is the one thing
//  a compile cannot tell you.
//
//  Never ships enabled: both dvars default to 0 and nothing below runs without
//  them.
// ============================================================================
zmqol_mgun_selftest()
{
    level endon( "end_game" );

    wait 8;

    a_players = get_players();

    for ( i = 0; i < a_players.size; i++ )
    {
        a_players[i] enableinvulnerability();
        a_players[i] giveweapon( "microwavegundw_zm" );
        a_players[i] switchtoweapon( "microwavegundw_zm" );
    }

    println( "[zm_qol] zapgun selftest: armed " + a_players.size + " player(s)" );

    b_probed = 0;

    for ( ;; )
    {
        //  v2.15.46 - a dev probe may hand over one actor in
        //  level.zmqol_mgun_selftest_target. While that actor exists but is
        //  dead (floating, swelling, about to pop) the camera holds on it and
        //  nothing fires, so a headless recording keeps one death on screen
        //  end to end instead of being yanked to the next zombie.
        if ( isdefined( level.zmqol_mgun_selftest_target ) && !isalive( level.zmqol_mgun_selftest_target ) )
        {
            a_players = get_players();

            if ( a_players.size )
                gethostplayer() setplayerangles( vectortoangles( level.zmqol_mgun_selftest_target.origin + ( 0, 0, 40 ) - gethostplayer().origin - ( 0, 0, 55 ) ) );

            wait 0.05;
            continue;
        }

        wait 4;

        a_players = get_players();

        if ( !a_players.size )
            continue;

        a_zombies = getaispeciesarray( "axis", "all" );

        if ( !b_probed && a_zombies.size )
        {
            //  One direct read of the thing the whole port turns on: does this
            //  map's compiled ASD know Moon's sizzle death state?
            println( "[zm_qol] zapgun selftest: animname=" + a_zombies[0].animname + " zm_death_sizzle=" + a_zombies[0] hasanimstatefromasd( "zm_death_sizzle" ) + " zm_death_sizzle_crawl=" + a_zombies[0] hasanimstatefromasd( "zm_death_sizzle_crawl" ) );
            b_probed = 1;
        }

        //  v2.15.45 - AIM AT THE NEAREST ZOMBIE before firing, so a headless
        //  test always has its kill inside the camera frame. setplayerangles
        //  and vectortoangles are stock builtins (the spawner uses both).
        e_target = undefined;
        n_best = 999999999;

        if ( isdefined( level.zmqol_mgun_selftest_target ) && isalive( level.zmqol_mgun_selftest_target ) )
        {
            e_target = level.zmqol_mgun_selftest_target;
            n_best = -1;
        }

        for ( i = 0; i < a_zombies.size; i++ )
        {
            if ( !isdefined( a_zombies[i] ) || !isalive( a_zombies[i] ) )
                continue;

            n_d = distancesquared( gethostplayer().origin, a_zombies[i].origin );

            if ( n_d < n_best )
            {
                n_best = n_d;
                e_target = a_zombies[i];
            }
        }

        if ( isdefined( e_target ) )
        {
            gethostplayer() setplayerangles( vectortoangles( e_target.origin - gethostplayer().origin ) );
            wait 0.2;
        }

        println( "[zm_qol] zapgun selftest: firing, " + a_zombies.size + " actor(s) up" );
        gethostplayer() thread microwavegun_fired( 0 );
    }
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

    // ------------------------------------------------------------------------
    //  🛑 v2.16.4 - NO-GIB IS SET HERE, BEFORE ANY WAIT, OR HEADS POP.
    //
    //  User, 2026-09-14, three builds running: "their heads are still popping".
    //  It was never the swell, the materials or the shader - it is stock's
    //  ordinary head gib, and the mod was marking no_gib too late to stop it.
    //
    //  MEASURED in retail _zm_spawner.gsc: the gib decision runs inside the
    //  damage override, which fires BEFORE any registered zombie damage
    //  callback (check_zombie_damage_callbacks is further down the same chain).
    //  zombie_should_gib() is the gate and it honours self.no_gib; if it
    //  passes, head_should_gib() decides, and for grenade-type damage that is
    //      distance( point, self gettagorigin( "j_head" ) ) > 55
    //  - anywhere within FIFTY-FIVE units of the head pops it. That is most of
    //  a torso, which is why it looked random rather than like a headshot.
    //
    //  microwavegun_sizzle_zombie() does set no_gib, but it is threaded per
    //  target through microwavegun_network_choke(), which waits three network
    //  frames every tenth target. Anything the shot damages before its own
    //  thread is reached is still gibbable. Marking the whole list up front,
    //  with no wait between building it and marking it, closes that window.
    //
    //  no_gib alone is the correct flag: it is what zombie_should_gib reads,
    //  and it stops the head gib by stopping gibbing. Deliberately NOT
    //  self.head_gibbed - that means "the head has already come off" and stock
    //  reads it elsewhere (zombie_eye_glow_stop), so setting it on a live
    //  zombie would be a lie with side effects.
    // ------------------------------------------------------------------------
    //  🛑 v2.16.6 - AND head_gibbed TOO, OR THE HEAD STILL COMES OFF.
    //
    //  The v2.16.5 attach probe answered it: every kill logged the head model
    //  at the kill and c_zom_*_g_behead half a second later. That swap is
    //  stock's zombie_head_gib() - detach the head, attach torsodmg5 - and it
    //  runs AFTER death from zombie_death_event() whenever the attacker has
    //  the multikill_headshots (Head Popper) perma-perk, which this mod's
    //  perma_perks option grants to everyone. zombie_head_gib() never reads
    //  no_gib; the only thing that stops it is self.head_gibbed already set.
    //  Setting it on a zombie that dies on the next dodamage has no other
    //  effect: head_gibbed is read by head_should_gib, zombie_head_gib, the
    //  Electric Cherry tesla gib and _zm_turned's spawn-point pick, all of
    //  which are exactly the things a corpse must not do.
    for ( i = 0; i < shot.enemies.size; i++ )
    {
        if ( isdefined( shot.enemies[i] ) )
        {
            shot.enemies[i].no_gib = 1;
            shot.enemies[i].head_gibbed = 1;
        }
    }

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
    self.head_gibbed = 1;   // v2.16.6 - blocks the post-death perma-perk head gib, see microwavegun_fired()
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

        //  Kept verbatim from Moon. Which branch runs is decided by the map's
        //  compiled ASD: zm_death_sizzle / zm_death_sizzle_crawl now ship as
        //  animstatedef rawfiles for the four stock families (see
        //  zone_source\mod_wonderweapons.zone) with the twelve Moon microwave
        //  xanims behind them, so the anim branch is reachable where those load
        //  and instant_explode is the honest fallback everywhere else.
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

        //  🌟 v2.16.3 - SAY WHICH BRANCH, EVERY KILL, WITHOUT A DVAR.
        //  The user reports the float-up happening "half the time", and which
        //  half is decided right here. Two guesses have already been spent on
        //  this; one line in the log settles it instead. Deliberately NOT
        //  gated on zmqol_mgun_debug: the dvar cannot be set without sending a
        //  console command into the user's live game, and the whole point is
        //  to read this back from a session they played normally. One line per
        //  Wave Gun kill, in the same [zm_qol] shape as everything else here.
        //  Remove once the split is known.
        s_why = "anim";
        if ( instant_explode )
        {
            s_why = "fallback";
            if ( self.isdog ) s_why = "fallback:dog";
            else if ( is_true( self.is_traversing ) ) s_why = "fallback:traversing";
            else if ( is_true( self.in_the_ceiling ) ) s_why = "fallback:ceiling";
            else if ( !self.has_legs ) s_why = "fallback:crawler-no-asd";
            else s_why = "fallback:no-sizzle-asd";
        }
        println( "[zm_qol] zapgun branch: " + s_why + " animname=" + self.animname );
        if ( getdvarintdefault( "zmqol_mgun_debug", 0 ) )
        {
            self zmqol_mgun_log_attaches( "at-kill" );
            self thread zmqol_mgun_attach_probe();
        }

        if ( instant_explode )
        {
            //  Moon: setclientfield( "zombie_actor_flag_microwavegun_expand_response", 1 )
            //  -> the client plays the mist at the spine and wpn_mgun_explode_zombie.
            //  Broadcast from here instead (banner point 1).
            //
            //  v2.15.11: THE SWELL ROUTE IS REMOVED. Boot 2026-09-09 loaded
            //  TranZit with this mod and the engine rejected the script at LOAD:
            //      **** Unresolved external : "setscale" with 1 parameters
            //           in "scripts/zm/zapgun.gsc" at line 1 ****  -> SV_Shutdown
            //  `setscale` is not a builtin on this engine, so its mere presence
            //  in the compiled script aborts every map load - the dvar gate never
            //  gets a chance to run. Route 4 (actor scale) is dead; the pop path
            //  stays, now led by the microwave sizzle + blood (v2.15.13, see
            //  zmqol_mgun_microwave_burst).
            if ( getdvarintdefault( "zmqol_mgun_debug", 0 ) )
                println( "[zm_qol] zapgun: instant_explode fallback (no sizzle animstate)" );

            self thread zmqol_mgun_microwave_burst();
        }
        else
        {
            //  Moon: setclientfield( "..._initial_hit_response", 1 ) puts
            //  fx_sizzle_blood_eyes on J_Eyeball_LE and plays
            //  wpn_mgun_impact_zombie on the client. Broadcast from the server
            //  here instead (banner point 1). wpn_mgun_dual_sizzle is the
            //  microwave hum: Moon rides it in as the secondary alias of
            //  wpn_imp_mgun_dual, which is the ZAP impact - the combined gun's
            //  sizzle cone never fires one, so it is played directly.
            //  From here the death anim drives the rest through its own
            //  "expand" and "explode" notetracks (both present in all twelve
            //  xanims this mod ships - checked in the asset bytes, not assumed).
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
            self playsound( "wpn_mgun_cook_zombie" );
            self playsound( "wpn_mgun_impact_zombie" );
            network_safe_play_fx_on_tag( "zmqol_mgun_sizzle_fx", 2, level.zmqol_mgun_effects["microwavegun_sizzle_blood_eyes"], self, "J_Eyeball_LE" );
            self.handle_death_notetracks = ::microwavegun_handle_death_notetracks;
            self thread zmqol_mgun_sizzle_watchdog();

            if ( getdvarintdefault( "zmqol_mgun_debug", 0 ) )
                println( "[zm_qol] zapgun: sizzle death anim '" + self.deathanim + "' on " + self.animname );
        }
    }
}

// ============================================================================
//  zmqol_mgun_log_attaches  -  IS THE HEAD GONE, OR JUST NOT DRAWN? (v2.16.5)
// ----------------------------------------------------------------------------
//  Three fixes have now been aimed at the heads coming off during a Wave Gun
//  kill and the user still sees it, so this stops guessing and measures the
//  one thing that splits the problem in half.
//
//  A zombie's head is a MODEL ATTACHED to the actor. So:
//    * if the attach count DROPS across the death, something is detaching it -
//      a gib, a model swap, script - and the fix is on the server;
//    * if the count HOLDS and the head is still invisible, nothing removed it
//      and it is a RENDER failure - material or vertex shader - which points
//      straight back at the head materials taken off the swell techsets in
//      v2.16.1, and the fix is to put them back.
//
//  Those two have opposite fixes, which is exactly why guessing has cost three
//  builds. Sampled at the kill, at "expand", and again after the swell has run,
//  because the moment it changes is as informative as the fact that it did.
//
//  ANSWERED 2026-09-14 (v2.16.6): count held at 1 but the model went from
//  c_zom_zombie_head_* to c_zom_zombie2_body01_g_behead within 0.5 s - the
//  head was detached by stock's zombie_head_gib() after death (Head Popper
//  perma-perk). Kept behind zmqol_mgun_debug 1 as the regression check.
// ============================================================================
//  Samples the attach list across the whole death without depending on a
//  notetrack arriving - "expand" is the only one that reliably does, and if
//  the head goes after it this still catches it.
zmqol_mgun_attach_probe()
{
    self endon( "death" );

    wait 0.5;
    self zmqol_mgun_log_attaches( "t+0.5" );
    wait 1.0;
    self zmqol_mgun_log_attaches( "t+1.5" );
    wait 1.0;
    self zmqol_mgun_log_attaches( "t+2.5" );
}

zmqol_mgun_log_attaches( str_when )
{
    if ( !isdefined( self ) )
        return;

    n = self getattachsize();
    s = "";

    for ( i = 0; i < n; i++ )
        s = s + " " + self getattachmodelname( i );

    println( "[zm_qol] zapgun attach " + str_when + ": count=" + n + s );
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

    //  🛑 playsoundatposition, NOT self playsound. The caller ghosts the corpse
    //  and self_delete()s it 0.1 s later, and a sound playing ON an entity dies
    //  with the entity - so the microwave ding was being cut to a click. Moon
    //  never had this problem because its copy runs on the CLIENT as
    //  playsound( 0, "wpn_mgun_explode_zombie", self.origin ), which is
    //  positional and outlives the actor. User, 2026-09-10: "the ding microwave
    //  ding sound effect when the zombie died was missing".
    playsoundatposition( "wpn_mgun_explode_zombie", v_pos );

    //  🌟 THE MICROWAVE DING. Treyarch's own alias, recovered by name rather
    //  than invented: the DLC5 Moon bank carries two payload-bearing rows the
    //  T6 scripts never call, stored under stripped hash names @48e268ca
    //  (microwave_ding.wav) and @69b2adc0 (microwave_cooking.wav). Running
    //  SND_HashName (seed 0x1505, h = c + 0x1003F*h, lowercased - the same
    //  function that reproduces the known @323a08e1 wpn_mgun_explode_zombie and
    //  @cd8064c2 wpn_mgun_impact_zombie) over candidate names resolves them to
    //  wpn_mgun_ding_zombie and wpn_mgun_cook_zombie. Both payloads and both
    //  rows now ship in this mod's bank.
    playsoundatposition( "wpn_mgun_ding_zombie", v_pos );
}

microwavegun_handle_death_notetracks( note )
{
    if ( note == "expand" )
    {
        //  Moon: expand_response 1 -> the client threads microwavegun_bloat(),
        //  which ramps shader constant 0 ("scriptVector3") from 0 to 0.5 over
        //  2.5 s and makes the body visibly swell.
        //  🌟 v2.15.45 - THE MATERIAL SIDE NOW EXISTS. Moon's zombie materials
        //  carry a MaximumSwell constant on the very techsets these maps'
        //  zombie materials already use (mc_sw4_3d_char_cloth_4z8fq5wu /
        //  mc_sw4_3d_char_skin_j92387z3 - measured byte-identical to DLC5's
        //  _dlc5 copies, technique names included). 53 of those stock
        //  materials now ship with MaximumSwell (20,0,0,1) added
        //  (mod_wavegun_swell.zone); the client half is in zapgun.csc. The
        //  setclientfield below is what starts the ramp on every viewer.
        self.zmqol_mgun_expand_seen = 1;
        self setclientfield( "zombie_actor_flag_microwavegun_expand_response", 1 );
        self playsound( "wpn_mgun_impact_zombie" );

        if ( getdvarintdefault( "zmqol_mgun_debug", 0 ) )
            println( "[zm_qol] zapgun: notetrack expand" );

        //  🛑 "expand" IS THE ONLY NOTETRACK THAT ARRIVES. Measured on Town,
        //  2026-09-10, with zmqol_mgun_debug 1: five sizzle deaths produced five
        //  "expand" lines and ZERO "explode" lines. Both markers are present in
        //  all twelve xanims - checked in the asset bytes - so the anim is not
        //  the problem; the death animscript stops running notetracks before the
        //  end of the cycle on these rigs. That is why bodies hung levitated.
        //
        //  So expand, not explode, is the timing anchor, and it is the right one:
        //  Moon's client starts its 2500 ms bloat on this exact marker
        //  (microwavegun_bloat), which makes the burst land where Treyarch put
        //  it. The watchdog started at the kill still backs this up.
        self thread zmqol_mgun_expand_to_burst();

        return;
    }

    if ( note == "explode" )
    {
        //  Moon: expand_response 0 -> the client drops the eye fx, plays the
        //  mist at J_SpineLower and wpn_mgun_explode_zombie. Same three things,
        //  broadcast from here; the eye fx goes with the corpse on delete.
        self zmqol_mgun_burst_once();

        if ( getdvarintdefault( "zmqol_mgun_debug", 0 ) )
            println( "[zm_qol] zapgun: notetrack explode" );
    }
}

// ============================================================================
//  zmqol_mgun_expand_to_burst  -  NO CORPSE HANGS IN THE AIR       (v2.15.16)
// ----------------------------------------------------------------------------
//  User, 2026-09-10: "sometimes they're getting stuck in midair. After they
//  would have been killed, right now they're just stuck floating in the air,
//  just inanimate."
//
//  The death anim carries its own "explode" notetrack and that is what pops the
//  body and deletes it. When the notetrack does not arrive - the corpse is
//  cleaned up, restarted or retargeted mid-animation, so the death animscript
//  stops running notetracks - nothing else was left to finish the kill, and the
//  actor just held its last levitated frame forever.
//
//  So the pop no longer depends only on the notetrack. Moon's own cycle is
//  2500 ms on a full rig and 1000 ms on one with no lower spine
//  (microwavegun_bloat, DLC5 client script); 4 seconds clears the longer of the
//  two with margin, so a corpse that reaches the notetrack normally is never
//  touched by this. zmqol_mgun_burst_once() is what stops a second pop or a
//  second delete when more than one of the three callers gets here.
// ============================================================================
zmqol_mgun_expand_to_burst()
{
    //  Moon's own cycle: 2500 ms on a full rig, 1000 ms when the lower spine
    //  tag is missing (microwavegun_bloat, DLC5 client script).
    n_cycle = 2.5;

    if ( !isdefined( self gettagorigin( "J_SpineLower" ) ) )
        n_cycle = 1;

    wait n_cycle;
    self zmqol_mgun_burst_once();
}

//  🛑 ONE FLAG, NOT A NOTIFY. Three callers can reach the burst - the "explode"
//  notetrack, the expand timer and the watchdog - and only the first may run.
//  A notify cannot do that job here: a thread that notifies its own endon
//  condition kills itself on that line, so the pop would never be reached.
zmqol_mgun_burst_once()
{
    if ( !isdefined( self ) || is_true( self.zmqol_mgun_burst_done ) )
        return;

    self.zmqol_mgun_burst_done = 1;
    self zmqol_mgun_pop();
    self microwavegun_sizzle_death_ending();
}

zmqol_mgun_sizzle_watchdog()
{
    wait 4;

    //  v2.15.46 - MEASURED on Town with a per-tick tracker (2026-09-13): the
    //  sizzle death reaches "expand" ~3.4 s after the kill and Moon's swell
    //  cycle runs 2.5 s from there. Popping at a flat 4 s cut the swell to
    //  0.5 s. Once expand has arrived, zmqol_mgun_expand_to_burst() owns the
    //  timing; this only covers an anim that never gets there.
    if ( is_true( self.zmqol_mgun_expand_seen ) )
        return;

    self zmqol_mgun_burst_once();
}

microwavegun_sizzle_death_ending()
{
    if ( !isdefined( self ) )
        return;

    self ghost();
    wait 0.1;
    self self_delete();
}

// ============================================================================
//  zmqol_mgun_microwave_burst  -  THE MICROWAVE SIZZLE THE POP WAS MISSING
//                                                                 (v2.15.13)
//  User, 2026-09-09: the combined Wave Gun should sound and bleed like the real
//  gun - the microwave hum, the burst, and the blood - not a bare pop.
//
//  🛑 WHAT IS ADDED AND WHAT STILL CANNOT BE, both measured, not guessed:
//   ADDED  - wpn_mgun_dual_sizzle (the microwave hum) and the blood-from-the-
//            eyes fx, both already shipped in this mod's bank/fx but never wired
//            on the instant-pop path; then, after a short sizzle, the existing
//            burst: fx_sizzle_mist at the spine + wpn_mgun_explode_zombie.
//   NOT ADDED - the float-up and the expand. The float-up is the zm_death_sizzle
//            death ANIM, which a stock aitype's compiled ASD does not carry
//            (hasanimstatefromasd is false everywhere here, §45). The expand is
//            Moon's DLC5 swell material OR setscale(); retail's zombie material
//            dumps "constants":[] and setscale is an UNRESOLVED EXTERNAL that
//            crashed the TranZit map load on the 2026-09-09 boot. Both need DLC5
//            assets stock maps do not have, so this is the audible/blood half of
//            the effect - the most the stock-map engine can actually run.
//
//  Own thread per corpse (the caller already threads the kill), and every step
//  is isdefined-guarded so a corpse cleaned up mid-sizzle just stops.
// ============================================================================
//  🌟 v2.16.1 - THIS PATH NOW SWELLS AND FLOATS TOO, so every Wave Gun kill
//  reads the same. User, 2026-09-14: *"sometimes they just kind of tap around
//  and they don't float up in the air ... sometimes they float up after they
//  tap around, but then they tap around and then they just explode and pop.
//  make sure it's consistent."*
//
//  That inconsistency was this branch versus the anim branch, and the split is
//  decided per kill a few lines up: a zombie mid-window-traversal, in the
//  ceiling, a crawler with no sizzle-crawl state, or a dog takes
//  instant_explode - and instant_explode used to sizzle for half a second and
//  burst, with no rise and no swell. On TranZit a traversing zombie is common,
//  which is exactly why it looked like a coin flip.
//
//  The float-up in the anim branch belongs to zm_death_sizzle, which this
//  branch by definition does not have. So it is driven here instead: the
//  corpse is already held rigid by nodeathragdoll, so a plain moveto lifts it
//  in a straight smooth line, eased at both ends. The swell is Moon's own
//  clientfield - the same one the "expand" notetrack raises - so the body
//  inflates on the identical 2.5 s ramp rather than a second code path.
//  Timings are matched to the anim branch on purpose: swell and rise together,
//  then burst at the top.
zmqol_mgun_microwave_burst()
{
    //  Keep the body still for the sizzle instead of ragdoll-flopping - a
    //  microwaved zombie holds, rises, then bursts. Safe: a plain field write,
    //  and it is what makes the moveto below read as a lift and not a drag.
    self.nodeathragdoll = 1;

    self playsound( "wpn_mgun_dual_sizzle" );

    //  Keep the eye blood attached to the corpse, matching the full sizzle
    //  route above. The old positional playfx survived self_delete() and left
    //  a stream hanging in the world after the zombie was gone.
    if ( isdefined( self gettagorigin( "J_Eyeball_LE" ) ) )
        network_safe_play_fx_on_tag( "zmqol_mgun_sizzle_fx", 2, level.zmqol_mgun_effects["microwavegun_sizzle_blood_eyes"], self, "J_Eyeball_LE" );

    //  Start the swell on the same clientfield the notetrack uses, and mark it
    //  seen so nothing else tries to cut the cycle short.
    self.zmqol_mgun_expand_seen = 1;
    self setclientfield( "zombie_actor_flag_microwavegun_expand_response", 1 );
    self playsound( "wpn_mgun_impact_zombie" );

    //  🛑 v2.16.3 - NO moveto ON AN ACTOR. v2.16.2 lifted the corpse with
    //  `self moveto( self.origin + (0,0,42), 1.6, 0.45, 0.45 )` and the user
    //  reported two things at once on that build: heads popping off, and the
    //  rise only happening about half the time. Both are the one mistake.
    //  bouncingbetty.gsc:670 already wrote the rule down for a neighbouring
    //  case - "a planted grenade entity cannot be moveto'd - which is exactly
    //  why MP spawns its minemover" - and an AI is the same class: it owns its
    //  own movement, so the move is fought or dropped (the rise that only
    //  sometimes lands) and the head, a separate model riding a tag, desyncs
    //  from a body being shoved from underneath (the popping).
    //
    //  The float is NOT reimplemented here with a stand-in mover. The engine
    //  already floats corpses correctly in the anim branch, and the honest way
    //  to make the rise consistent is to get more kills INTO that branch
    //  rather than to hand-roll a second rise that has to look identical. The
    //  print below is what decides which, with evidence instead of a guess.
    //  The swell above stays: it is Moon's own clientfield and the user
    //  confirmed inflation working.
    wait 2.5;

    if ( !isdefined( self ) )
        return;

    self zmqol_mgun_pop();
    self microwavegun_sizzle_death_ending();
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
