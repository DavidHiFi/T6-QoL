#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_net;
#include maps\mp\zombies\_zm_perks;
#include maps\mp\_visionset_mgr;


enable_divetonuke_perk_for_level()
{
    maps\mp\zombies\_zm_perks::register_perk_basic_info( "specialty_flakjacket", "divetonuke", 2000, &"ZOMBIE_PERK_DIVETONUKE", "zombie_perk_bottle_nuke" );
    maps\mp\zombies\_zm_perks::register_perk_precache_func( "specialty_flakjacket", ::divetonuke_precache );
    maps\mp\zombies\_zm_perks::register_perk_clientfields( "specialty_flakjacket", ::divetonuke_register_clientfield, ::divetonuke_set_clientfield );
    maps\mp\zombies\_zm_perks::register_perk_machine( "specialty_flakjacket", ::divetonuke_perk_machine_setup, ::divetonuke_perk_machine_think );
    maps\mp\zombies\_zm_perks::register_perk_host_migration_func( "specialty_flakjacket", ::divetonuke_host_migration_func );
}

init_divetonuke()
{
    level.zombiemode_divetonuke_perk_func = ::divetonuke_explode;
    //  🛑 v2.9.16 - lerp steps 5 -> 1: with every mod-registered visionset at
	//  1 step, visionset_lerp is skipped on the maps stock never paid for it on
	//  (Mob failed to load asking for exactly those 3 bits - see the banner in
	//  quality_of_life.gsc over zmqol_register_divetonuke_visionset). The dive
	//  flash snaps instead of fading; the twin in clientscripts\mp\zombies\
	//  _zm_perk_divetonuke.csc carries the same 1 and MUST stay identical.
	maps\mp\_visionset_mgr::vsmgr_register_info( "visionset", "zm_perk_divetonuke", 9000, 400, 1, 1 );
    level._effect["divetonuke_groundhit"] = loadfx( "maps/zombie/fx_zmb_phdflopper_exp" );
    set_zombie_var( "zombie_perk_divetonuke_radius", 300 );
    set_zombie_var( "zombie_perk_divetonuke_min_damage", 1000 );
    set_zombie_var( "zombie_perk_divetonuke_max_damage", 5000 );
}

divetonuke_precache()
{
    precacheitem( "zombie_perk_bottle_nuke" );
    precacheshader( "specialty_divetonuke_zombies" );
    precachemodel( "p6_zm_al_vending_nuke_on" );
    precachestring( &"ZOMBIE_PERK_DIVETONUKE" );

    if ( getDvar("mapname") == "zm_prison")
    {
        level._effect["divetonuke_light"] = loadfx( "misc/fx_zombie_cola_dtap_on" );
    }
    else 
    {
       level._effect["divetonuke_light"] = loadfx("misc/fx_zombie_cola_dtap_on"); 
    }

    level.machine_assets["divetonuke"] = spawnstruct();
    level.machine_assets["divetonuke"].weapon = "zombie_perk_bottle_nuke";
    level.machine_assets["divetonuke"].off_model = "p6_zm_al_vending_nuke_on";
    level.machine_assets["divetonuke"].on_model = "p6_zm_al_vending_nuke_on";
    level.machine_assets["divetonuke"].power_on_callback = ::vending_divetonuke_power_on;
	level.machine_assets["divetonuke"].power_off_callback = ::vending_divetonuke_power_off;
}

vending_divetonuke_power_on()
{
	if (level.script == "zm_prison")
	{
		self setclientfield("toggle_perk_machine_power", 2);
	}
	else
	{
		//  v1.99.22 - was scripts\zm\zm_expanded::clientnotifyloop. That script was
		//  the pre-merge module that became quality_of_life.gsc; it was deleted from
		//  the project months ago but survived baked inside mod.ff, so this
		//  reference kept resolving. v1.99.21 stripped every .gsc out of mod.ff and
		//  the namespace vanished, making this an "Unresolved external" at SCRIPT
		//  LOAD - fatal on every map, since quality_of_life.gsc (a root script)
		//  #includes this file. The function moved into the merge unchanged; dumped
		//  the donor mod.ff's zm_expanded.gsc and diffed the two bodies to confirm.
		level thread scripts\zm\quality_of_life::clientnotifyloop("toggle_vending_divetonuke_power_on", "divetonuke_off");
	}
}
vending_divetonuke_power_off()
{
	if (level.script == "zm_prison")
	{
		self setclientfield("toggle_perk_machine_power", 1);
	}
	else
	{
		//  v1.99.22 - see the note in vending_divetonuke_power_on() above.
		level thread scripts\zm\quality_of_life::clientnotifyloop("toggle_vending_divetonuke_power_off", "divetonuke_on");
	}
}


divetonuke_register_clientfield()
{
	//  🛑 v2.9.23 - CONSTANT 1, EMP conditional removed; the client twin in
	//  clientscripts\mp\zombies\_zm_perk_divetonuke.csc carries the full
	//  story and the same constant. Stock ships 1 bit on every map that
	//  registers this field (seven T6-Data-Archive dumps agree), and a
	//  computed width desynced the two halves on Mob (client 2 / server 1).
	registerclientfield("toplayer", "perk_dive_to_nuke", 9000, 1, "int");
}

divetonuke_set_clientfield( state )
{
    self setclientfieldtoplayer( "perk_dive_to_nuke", state );
}

divetonuke_perk_machine_setup( use_trigger, perk_machine, bump_trigger, collision )
{

    use_trigger.script_string = "divetonuke_perk";
    use_trigger.target = "vending_divetonuke";
    perk_machine.script_string = "divetonuke_perk";
    perk_machine.targetname = "vending_divetonuke";

    //  🛑 v2.11.27 - THE zm_prison SPECIAL CASE IS GONE, AND IT WAS THE BUG.
    //
    //  It asked for "mus_perks_phd_sting" on Mob. That alias EXISTS NOWHERE:
    //  absent from all six of Plutonium's runtime alias tables
    //  (storage\t6\plutonium\soundaliaslists) AND from all six fastfile
    //  soundbank dumps. A play on a name no bank declares is silent and logs
    //  nothing, so PhD Flopper had no purchase sting on Mob of the Dead.
    //
    //  🌟 The branch bought nothing even when it worked. Measured in
    //  zmb_alcatraz.all.aliases.csv - Mob declares BOTH jingle names and both
    //  point at THE SAME FILE:
    //      mus_perks_phd_jingle        -> alcatraz\perksacola\phd_jingle.flac
    //      mus_perks_phdflopper_jingle -> alcatraz\perksacola\phd_jingle.flac
    //  (both 14,000 ms in the runtime table). So Mob keeps its own 1930s
    //  jingle either way, and gains the sting it never had:
    //      mus_perks_phdflopper_sting  -> perksacola\mus_phd_sting.flac (13,995 ms)
    //
    //  The other four maps this mod gives PhD out on already took this branch
    //  and are byte-for-byte unchanged. Neither mus_perks_* name is declared in
    //  mod.all on any map, so a user sound pack still owns both of them.
    //
    //  🛑 ORIGINS IS THE ONE MAP THAT CANNOT USE THE STOCK NAME (v2.11.28).
    //  zmb_tomb.all declares BOTH mus_perks_phdflopper_* rows with an EMPTY
    //  FileSource and Storage=streamed - the alias resolves and plays nothing -
    //  and mus_perks_phd_jingle is not in Origins' table at all. Plutonium's
    //  runtime table agrees: 0 ms for both. So stock Origins ships PhD Flopper
    //  and no PhD machine music, and NO rename can fix it.
    //
    //  🌟 So on Origins ONLY, the machine takes this mod's own copies. The
    //  payload is Treyarch's own, lifted out of zmb_nuked_real:
    //      zmqol_phd_jingle -> raw\sound\mus\zombie\perksacola\mus_phd_jingle.SN55...
    //      zmqol_phd_sting  -> raw\sound\mus\zombie\perksacola\mus_phd_sting.SN55...
    //  Both rows in mod.all.aliases.additions.csv are the zmb_nuked_real rows
    //  copied VERBATIM with only the Name column changed (60/60 columns, same
    //  mix, same snp_x3 duck group, same @866cadbc duck), so Origins gets the
    //  same mix every other map gets. The .flac is byte-identical across all
    //  four banks that carry it - md5 checked - so there is no "which copy"
    //  question to get wrong.
    //
    //  🛑 THE PRIVATE NAMES ARE ORIGINS-ONLY ON PURPOSE. On the other five maps
    //  mus_perks_phdflopper_* has real audio, and declaring those names in
    //  mod.all would shadow the user's sound pack - the failure this project
    //  calls "audible but the mod's flavour". zmqol_* is a name no stock bank
    //  uses, so it shadows nothing, and no pack can supply Origins' PhD music
    //  anyway: the alias table lives in the fastfile, which a pack does not
    //  replace, and its row points at nothing.
    if ( getDvar( "mapname" ) == "zm_tomb" )
    {
        use_trigger.script_sound = "zmqol_phd_jingle";
        use_trigger.script_label = "zmqol_phd_sting";
    }
    else
    {
        use_trigger.script_sound = "mus_perks_phdflopper_jingle";
        use_trigger.script_label = "mus_perks_phdflopper_sting";
    }
    if ( isdefined( bump_trigger ) )
    {
        bump_trigger.script_string = "divetonuke_perk";
    }
}

divetonuke_perk_machine_think()
{
    init_divetonuke();

    while ( true )
    {
        machine = getentarray( "vending_divetonuke", "targetname" );
        machine_triggers = getentarray( "vending_divetonuke", "target" );

        for ( i = 0; i < machine.size; i++ )
        {
            machine[i] setmodel( level.machine_assets["divetonuke"].off_model );
        }

        array_thread( machine_triggers, ::set_power_on, 0 );
        level thread do_initial_power_off_callback( machine, "divetonuke" );
        level waittill( "divetonuke_on" );

        for ( i = 0; i < machine.size; i++ )
        {
            machine[i] setmodel( level.machine_assets["divetonuke"].on_model );
            machine[i] vibrate( vectorscale( ( 0, -1, 0 ), 100.0 ), 0.3, 0.4, 3 );
            machine[i] playsound( "zmb_perks_power_on" );
            machine[i] thread perk_fx( "divetonuke_light" );
            machine[i] thread play_loop_on_machine();
        }

        level notify( "specialty_flakjacket_power_on" );
        array_thread( machine_triggers, ::set_power_on, 1 );

        if ( isdefined( level.machine_assets["divetonuke"].power_on_callback ) )
        {
            array_thread( machine, level.machine_assets["divetonuke"].power_on_callback );
        }

        level waittill( "divetonuke_off" );

        if ( isdefined( level.machine_assets["divetonuke"].power_off_callback ) )
        {
            array_thread( machine, level.machine_assets["divetonuke"].power_off_callback );
        }

        array_thread( machine, ::turn_perk_off );
    }
}

divetonuke_host_migration_func()
{
    flop = getentarray( "vending_divetonuke", "targetname" );

    foreach ( perk in flop )
    {
        if ( isdefined( perk.model ) && perk.model == level.machine_assets["divetonuke"].on_model )
        {
            perk perk_fx( undefined, 1 );
            perk thread perk_fx( "divetonuke_light" );
        }
    }
}

divetonuke_explode( attacker, origin )
{
    radius = level.zombie_vars["zombie_perk_divetonuke_radius"];
    min_damage = level.zombie_vars["zombie_perk_divetonuke_min_damage"];
    max_damage = level.zombie_vars["zombie_perk_divetonuke_max_damage"];
    a_near = [];
    a_health = [];

    if ( isdefined( level.flopper_network_optimized ) && level.flopper_network_optimized )
    {
        attacker thread divetonuke_explode_network_optimized( origin, radius, max_damage, min_damage, "MOD_GRENADE_SPLASH" );
    }
    else
    {
        //  v2.11.17 - THE SEVENTH ARGUMENT. Stock ships this call with six.
        //  Six means the engine substitutes weapon index 255 and dereferences
        //  whatever weaponTable[255] holds - the exact null read that crashed
        //  Origins on a Panzer death (ERROR_CATALOGUE.md §60, fixed and
        //  confirmed in game as v2.11.11).
        //
        //  This was the LAST short-form radiusdamage in a file this mod ships -
        //  the v2.11.11 sweep only walked scripts/, not maps/, so it was missed.
        //  It is also the most frequently reached site of the class: every PhD
        //  dive on zm_transit, zm_nuked, zm_highrise, zm_prison and zm_buried
        //  runs it, because level.flopper_network_optimized (the branch above)
        //  is set ONLY by Origins' zm_tomb.gsc:181 - grepped over the whole
        //  2,093-file stock dump - and Origins is not in this mod's PhD map list.
        //
        //  frag_grenade_zm is resident on all five maps (Unlinker --list over
        //  each map ff, 2026-09-04) and matches the MOD_GRENADE_SPLASH already
        //  being passed - the same pairing stock itself uses in
        //  _zm_weap_cymbal_monkey.gsc:237.
        //
        //  Naming the weapon changes no damage: this mod's damage chain
        //  (zmqol_actor_damage_wrapper) scales only bullet means-of-death, and
        //  stock's gib/explode branch (_zm_spawner.gsc:2191) already fires on
        //  MOD_GRENADE_SPLASH regardless of the weapon name.
        //
        //  Latent, not observed - no dive crash has ever been reported. This
        //  makes the call deterministic; it does not fix a seen bug.
        a_near = divetonuke_zombies_in_blast( origin, radius );

        for ( i = 0; i < a_near.size; i++ )
            a_health[i] = a_near[i].health;

        radiusdamage( origin, radius, max_damage, min_damage, attacker, "MOD_GRENADE_SPLASH", "frag_grenade_zm" );
        level thread divetonuke_blast_fill_in( attacker, origin, radius, max_damage, min_damage, a_near, a_health );
    }

    playfx( level._effect["divetonuke_groundhit"], origin );
    attacker playsound( "zmb_phdflop_explo" );
    maps\mp\_visionset_mgr::vsmgr_activate( "visionset", "zm_perk_divetonuke", attacker );
    wait 1;
    maps\mp\_visionset_mgr::vsmgr_deactivate( "visionset", "zm_perk_divetonuke", attacker );
}

//  🌟 2026-09-28 - THE DIVE KILLS WHAT IT LANDS IN. A tester: a dive from a
//  high place into zombies "wasn't killing them".
//
//  The radiusdamage above goes off at the player's feet, on the floor. The
//  Bouncing Betty measured the same engine call reaching 0 of 3 zombies
//  inside its radius (betty-radius-001, bouncingbetty.gsc
//  zmqol_betty_blast_fill_in). Origins never had the problem: zm_tomb sets
//  level.flopper_network_optimized, which takes the branch above and hits
//  every zombie in range with dodamage, no trace. Buried's Perma-Flopper does
//  the same (level.pers_flopper_network_optimized).
//
//  So every zombie that was inside the radius before the blast and still has
//  the same health 0.05 s after it takes the stock falloff here, once,
//  labelled like the blast. A zombie the blast did reach lost health and is
//  skipped, so nothing is hit twice. Scripted and boss zombies keep their
//  magic bullet shield, as in the Betty fill-in.
divetonuke_zombies_in_blast( origin, radius )
{
    a_near = [];
    a_zombies = get_round_enemy_array();

    for ( i = 0; i < a_zombies.size; i++ )
    {
        if ( !isdefined( a_zombies[i] ) || !isalive( a_zombies[i] ) )
            continue;

        if ( distance( a_zombies[i].origin, origin ) > radius )
            continue;

        if ( is_magic_bullet_shield_enabled( a_zombies[i] ) )
            continue;

        a_near[a_near.size] = a_zombies[i];
    }

    return a_near;
}

divetonuke_blast_fill_in( attacker, origin, radius, max_damage, min_damage, a_near, a_health )
{
    wait 0.05;

    n_hit = 0;
    n_filled = 0;

    for ( i = 0; i < a_near.size; i++ )
    {
        e_zombie = a_near[i];

        if ( !isdefined( e_zombie ) || !isalive( e_zombie ) || e_zombie.health < a_health[i] )
        {
            n_hit++;
            continue;
        }

        n_frac = distance( e_zombie.origin, origin ) / radius;

        if ( n_frac > 1 )
            n_frac = 1;

        n_damage = int( max_damage - ( max_damage - min_damage ) * n_frac );

        if ( isdefined( attacker ) && isplayer( attacker ) )
            e_zombie dodamage( n_damage, e_zombie.origin, attacker, attacker, "none", "MOD_GRENADE_SPLASH", 0, "frag_grenade_zm" );
        else
            e_zombie dodamage( n_damage, e_zombie.origin, undefined, undefined, "none", "MOD_GRENADE_SPLASH", 0, "frag_grenade_zm" );

        n_filled++;
    }

    println( "[zm_qol] phd dive: " + a_near.size + " zombie(s) within " + radius + " - blast hit " + n_hit + ", filled in " + n_filled );
}

divetonuke_explode_network_optimized( origin, radius, max_damage, min_damage, damage_mod )
{
    self endon( "disconnect" );
    a_zombies = get_array_of_closest( origin, get_round_enemy_array(), undefined, undefined, radius );
    network_stall_counter = 0;

    if ( isdefined( a_zombies ) )
    {
        for ( i = 0; i < a_zombies.size; i++ )
        {
            e_zombie = a_zombies[i];

            if ( !isdefined( e_zombie ) || !isalive( e_zombie ) )
            {
                continue;
            }

            dist = distance( e_zombie.origin, origin );
            damage = min_damage + ( max_damage - min_damage ) * ( 1.0 - dist / radius );
            e_zombie dodamage( damage, e_zombie.origin, self, self, 0, damage_mod );
            network_stall_counter--;

            if ( network_stall_counter <= 0 )
            {
                wait_network_frame();
                network_stall_counter = randomintrange( 1, 3 );
            }
        }
    }
}