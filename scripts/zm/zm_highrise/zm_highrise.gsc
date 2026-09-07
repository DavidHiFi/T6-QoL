#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_weapons;
#include maps\mp\zm_highrise;

main()
{
    replaceFunc( maps\mp\zm_highrise::custom_vending_precaching, ::custom_vending_precaching );
    replaceFunc( maps\mp\zm_highrise_elevators::init_elevator_perks, ::init_elevator_perks );

    //  v2.14.17 - PACK-A-PUNCHED SLIQUIFIER. Both overrides are stock's own body
    //  with the upgraded-damage branch added; see the banner further down for
    //  what each one does and what it was measured against.
    //  maps\mp\zombies\_zm_weap_slipgun ships in zm_highrise_patch.ff and NOWHERE
    //  else, so these references are legal only from this file - a root script
    //  would fail to load on every other map.
    replaceFunc( maps\mp\zombies\_zm_weap_slipgun::slipgun_zombie_1st_hit_response, ::zmqol_slipgun_1st_hit_response );
    replaceFunc( maps\mp\zombies\_zm_weap_slipgun::explode_to_near_zombies, ::zmqol_explode_to_near_zombies );

    // --- custom survival start locations: adds Shopping Mall, Dragon Rooftop, Sweatshop ---
    replaceFunc( maps\mp\zm_highrise_gamemodes::init, scripts\zm\replaced\zm_highrise_gamemodes::init );

    zmqol_register_survival_clientfields();

    //  v2.11.15 - the weapon locker's two sounds. The banner on
    //  zmqol_locker_watch() at the bottom of this file says why the hook is on
    //  watch() and not on think().
    replaceFunc( maps\mp\zombies\_zm_weapon_locker::triggerweaponslockerwatch, ::zmqol_locker_watch );
}

// ============================================================================
//  zmqol_register_survival_clientfields
//
//  🛑 Fixes part of: DIE RISE SURVIVAL DISCONNECTS WITH EXE_CLIENT_FIELD_MISMATCH
//     on every location (dragon_rooftop, shopping_mall, rooftop).
//
//  maps\mp\zm_highrise::zclassic_preinit (zm_highrise.gsc:70-82) registers these
//  seven clientfields and then calls zm_highrise_sq::sq_highrise_clientfield_init
//  for an eighth. That function runs ONLY for zclassic. A zstandard game runs
//  zstandard_preinit instead and registers none of them - but the CLIENT
//  registers them unconditionally, so the two sets disagree and the engine drops
//  the player. Exactly the same shape as the MotD visionset_lerp bug fixed in
//  v1.1.4, just a different set of fields.
//
//  registerclientfield is a bare engine builtin with no state behind it, so
//  main() is a legal place for it (see the note in zm_tomb.gsc). Guarded on
//  !is_classic() so classic Die Rise still registers them exactly once via
//  zclassic_preinit and we do not double-register.
//
//  Versions/bit counts/types copied verbatim from the stock registrations -
//  they MUST match the client exactly or the mismatch simply changes shape.
//
//  🛑 KNOWN INCOMPLETE: the log also reports
//      Clientfield buildable in set [toplayer] is not registered on the client
//  which is the opposite direction (server has it, client does not) and is NOT
//  fixed here. Server and client both pick between a per-slot registration and a
//  single "buildable" field based on level.buildable_slot_count
//  (_zm_buildables.gsc:170-180 vs _zm_buildables.csc:40-50); on Die Rise survival
//  those two counts disagree. Until that is resolved Die Rise may still mismatch.
// ============================================================================
zmqol_register_survival_clientfields()
{
    if ( is_classic() )
        return;

    registerclientfield( "scriptmover", "clientfield_escape_pod_tell_fx", 5000, 1, "int" );
    registerclientfield( "scriptmover", "clientfield_escape_pod_sparks_fx", 5000, 1, "int" );
    registerclientfield( "scriptmover", "clientfield_escape_pod_impact_fx", 5000, 1, "int" );
    registerclientfield( "scriptmover", "clientfield_escape_pod_light_fx", 5000, 1, "int" );
    registerclientfield( "actor", "clientfield_whos_who_clone_glow_shader", 5000, 1, "int" );
    registerclientfield( "toplayer", "clientfield_whos_who_audio", 5000, 1, "int" );
    registerclientfield( "toplayer", "clientfield_whos_who_filter", 5000, 1, "int" );

    // The eighth one, plus the VO index table it drives.
    maps\mp\zm_highrise_sq::sq_highrise_clientfield_init();
}

init()
{
    added_weapons();
    move_marathon_origins();

    //  .jumpingjacks (amount) / spawn_jumpingjacks <n>. Installed here, not in
    //  the root script - maps\mp\zombies\_zm_ai_leaper is Die Rise-only and a
    //  qualified reference to it from a root file crashes every other map at load.
    level.zmqol_boss_name = "jumpingjacks";
    level.zmqol_boss_spawn_func = ::zmqol_spawn_jumpingjacks;

    //  ========================================================================
    //  v1.99.96 - DIE RISE WEAPONS. See the big banner at the bottom of this
    //  file for what each of these does and what it was checked against.
    //
    //  precachemodel HERE, not in the wall-buy thread. init() is inside the
    //  precache window - added_weapons() above it calls include_weapon, which is
    //  the same window - whereas the wall buy itself has to wait for the
    //  blackscreen. One model, already resident in zm_highrise.ff, so this costs
    //  nothing when the row is off.
    //  ========================================================================
    precachemodel( "t6_wpn_grenade_semtex_world" );

    level thread zmqol_slipgun_pap_enable();
    level thread zmqol_semtex_wallbuy();
    level thread zmqol_no_power_highrise_extras();
    zmqol_bank_sounds_init();
}

// ============================================================================
//  zmqol_bank_sounds_init  -  DIE RISE'S BANK HAS NEVER MADE A SOUND
//
//  User, 2026-09-04: "the sound effect from grabbing money from the bank in die
//  rise was missing as well".
//
//  🌟 MEASURED, AND IT IS A STOCK GAP, NOT SOMETHING THIS MOD BROKE. Die Rise
//  runs the same _zm_banking.gsc as TranZit and Buried - byte-identical in the
//  dump - so its withdraw path calls
//      player playsoundtoplayer( "zmb_vault_bank_withdraw", player )
//  ( _zm_banking.gsc:267, deposit at :223 ). But that alias is NOT in Die Rise's
//  sound table. Plutonium's own per-map alias dump ( storage/t6/plutonium/
//  soundaliaslists ) lists zmb_vault_bank_deposit / _withdraw for zm_transit and
//  zm_buried ONLY; zm_highrise has neither, while it does carry every common
//  alias ( zmb_cha_ching, evt_perk_bottle_open, uin_alert_lockon ), so the list
//  is the complete runtime set and the two names are genuinely absent. An alias
//  that does not exist is SILENT AND LOGS NOTHING. Treyarch turned banking on
//  for Die Rise ( zm_highrise.gsc:183, level.banking_update_enabled ) and never
//  shipped the audio into its banks.
//
//  🛑 WHY NOT JUST DECLARE zmb_vault_bank_withdraw IN mod.all. Because mod.all
//  loads after the stock banks, so the mod's row would win on TranZit and Buried
//  too, where the sound already works - and this project cannot read Treyarch's
//  own alias parameters ( no soundbank asset in zm_transit.ff to dump ), so the
//  shadowing copy would be a guess at volume/bus/pan on two maps that are
//  currently correct. The mod-private name cannot shadow anything.
//
//  THE HOOK IS TREYARCH'S OWN. _zm_banking.gsc calls level.custom_bank_deposit_vo
//  / level.custom_bank_withdrawl_vo on the player at exactly the right moment
//  ( :228 and :273 ) - Buried uses the same two pointers for its crew's bank
//  lines ( zm_buried.gsc:1473 ). Nothing stock is replaced.
//
//  📝 The withdraw pointer REPLACES stock's else-branch, so the laugh it would
//  have played is re-issued below, verbatim, to keep parity. The deposit branch
//  has no else, so that one only adds the sound.
//
//  The payload is Treyarch's own bank_withdraw / bank_deposit FLAC out of
//  zmb_classic_transit.all ( md5-identical to zmb_buried.all's copy ), shipped
//  under zmqol_bank_withdraw / zmqol_bank_deposit in mod.all.
// ============================================================================
zmqol_bank_sounds_init()
{
    //  Never fight a map that already drives these pointers - Die Rise sets
    //  neither ( verified in the stock dump: only zm_buried.gsc does ).
    if ( isdefined( level.custom_bank_deposit_vo ) || isdefined( level.custom_bank_withdrawl_vo ) )
        return;

    level.custom_bank_deposit_vo = ::zmqol_bank_deposit_vo;
    level.custom_bank_withdrawl_vo = ::zmqol_bank_withdrawl_vo;
}

zmqol_bank_deposit_vo()
{
    self playsoundtoplayer( "zmqol_bank_deposit", self );
}

zmqol_bank_withdrawl_vo()
{
    self playsoundtoplayer( "zmqol_bank_withdraw", self );

    //  _zm_banking.gsc:276 - what stock plays when this pointer is undefined.
    self thread maps\mp\zombies\_zm_utility::do_player_general_vox( "general", "exert_laugh", 10, 50 );
}

// ============================================================================
//  zmqol_spawn_jumpingjacks  -  the real leaper, one leaper round's spawn step.
//
//  🛑 UNLIKE BRUTUS AND THE PANZER, THE LEAPER HAS NO NOTIFY HOOK. Its spawns
//  happen inline inside leaper_round_spawning() (_zm_ai_leaper.gsc:570), which is
//  a whole round - it plays the dog-round vo, sets level.zombie_total, threads
//  the accuracy tracking and the aftermath, and does not return until the round
//  ends. Calling that would start a leaper ROUND, not spawn a leaper.
//
//  So this replicates its per-spawn step and nothing else. Straight out of :644,
//  in the same order, with the same three helpers:
//      favorite_enemy = get_favorite_enemy()                             (:733)
//      spawn_point    = leaper_spawn_logic( level.enemy_dog_spawns, ... ) (:800)
//      ai             = spawn_zombie( level.leaper_spawners[0] )
//      ai.favoriteenemy / ai.spawn_point, then leaper_spawn_fx()         (:924)
//  get_favorite_enemy() is safe to call outside a leaper round: it calls
//  getplayers() itself and defaults .hunted_by, so it depends on nothing the
//  round sets up. spawn_zombie is _zm_utility, already included above.
//
//  📝 level.zombie_total and level.leaper_count are deliberately NOT touched.
//  Those are the ROUND's bookkeeping - decrementing zombie_total outside a leaper
//  round would tell the round system a zombie it never counted has been used up.
//  These are extra AI on top of the round, which is what the command is for.
// ============================================================================
//  ============================================================================
//  🛑 v1.90.4 - THE GUARD WAS GATING ON A VARIABLE THE SPAWN PATH NEVER READS.
//
//  User, 2026-08-14, on Die Rise: ".jumpingjacks didn't work" ->
//  "[zm_qol] the jumpingjacks spawner is not running on this map".
//
//  That message is the else branch of quality_of_life.gsc:5483, i.e. this
//  function returned 0. It was the level.enemy_dog_spawns half of the guard.
//
//  🌟 THAT ARRAY IS ONLY EVER SET BY THE zstandard GAMETYPE.
//      _zm_ai_dogs.gsc:83   level.enemy_dog_spawns = getentarray( "zombie_spawner_dog_init", ... )
//  and the only caller of _zm_ai_dogs::init() is gametypes_zm\zstandard.gsc:27.
//  zclassic never calls it, so on a classic game the array is undefined and the
//  command refused to run - on the map whose boss it is.
//
//  🌟 AND THE ARRAY IS IRRELEVANT ANYWAY: leaper_spawn_logic( leaper_array,
//  favorite_enemy ) (_zm_ai_leaper.gsc:800) NEVER READS ITS FIRST PARAMETER. It
//  builds its candidates from level.zones[zone].leaper_locations. So does the
//  older leaper_spawn_logic_old(), which reads a getstructarray() instead. Stock
//  passes level.enemy_dog_spawns at :645 purely as a leftover. The call below
//  keeps passing it for exact parity with stock's line - it is inert either way,
//  and an unread parameter is not worth deviating from the port over.
//
//  WHAT THE PATH ACTUALLY NEEDS, and what is guarded now instead:
//      level.leaper_spawners     - spawn_zombie( level.leaper_spawners[0] )
//      level.active_zone_names   - leaper_spawn_logic foreaches it; foreach over
//                                  an undefined array is a script error, and
//                                  Plutonium swallows those silently.
//  Both are populated by core, gametype-independent code: leaper_spawner_init()
//  from _zm_ai_leaper::init() (registered into level.custom_ai_type by
//  zm_highrise.gsc:182, every gametype), and _zm_zonemgr.gsc:798/936. Verified
//  against the stock dump, not assumed - which is also why jumping-jack ROUNDS
//  work in classic while this command did not.
//  ============================================================================
zmqol_spawn_jumpingjacks( n_amount )
{
    if ( !isdefined( level.leaper_spawners ) )
        return 0;

    if ( !level.leaper_spawners.size )
        return 0;

    if ( !isdefined( level.active_zone_names ) )
        return 0;

    level thread zmqol_spawn_jumpingjacks_think( n_amount );

    return n_amount;
}

zmqol_spawn_jumpingjacks_think( n_amount )
{
    level endon( "intermission" );
    level endon( "end_game" );

    for ( i = 0; i < n_amount; i++ )
    {
        favorite_enemy = maps\mp\zombies\_zm_ai_leaper::get_favorite_enemy();
        spawn_point = maps\mp\zombies\_zm_ai_leaper::leaper_spawn_logic( level.enemy_dog_spawns, favorite_enemy );
        ai = spawn_zombie( level.leaper_spawners[0] );

        if ( isdefined( ai ) )
        {
            ai.favoriteenemy = favorite_enemy;
            ai.spawn_point = spawn_point;

            //  Stock passes spawn_point as both the caller and the argument; it
            //  can be undefined if every spawn node is occupied, and playing the
            //  fx on an undefined ent is a script error, so gate on it. The
            //  leaper itself is already spawned and functional either way.
            if ( isdefined( spawn_point ) )
                spawn_point thread maps\mp\zombies\_zm_ai_leaper::leaper_spawn_fx( ai, spawn_point );
        }

        //  Stagger, so a request for several does not put them all through the
        //  same spawn node in one frame.
        wait 0.5;
    }
}

custom_vending_precaching()
{
    if ( isdefined( level.zombiemode_using_pack_a_punch ) && level.zombiemode_using_pack_a_punch )
    {
        precacheitem( "zombie_knuckle_crack" );
        precachemodel( "p6_anim_zm_buildable_pap" );
        precachemodel( "p6_anim_zm_buildable_pap_on" );
        precachestring( &"ZOMBIE_PERK_PACKAPUNCH" );
        precachestring( &"ZOMBIE_PERK_PACKAPUNCH_ATT" );
        level._effect["packapunch_fx"] = loadfx( "maps/zombie/fx_zmb_highrise_packapunch" );
        level.machine_assets["packapunch"] = spawnstruct();
        level.machine_assets["packapunch"].weapon = "zombie_knuckle_crack";
        level.machine_assets["packapunch"].off_model = "p6_anim_zm_buildable_pap";
        level.machine_assets["packapunch"].on_model = "p6_anim_zm_buildable_pap_on";
    }

    if ( isdefined( level.zombiemode_using_additionalprimaryweapon_perk ) && level.zombiemode_using_additionalprimaryweapon_perk )
    {
        precacheitem( "zombie_perk_bottle_additionalprimaryweapon" );
        precacheshader( "specialty_additionalprimaryweapon_zombies" );
        precachemodel( "zombie_vending_three_gun" );
        precachemodel( "zombie_vending_three_gun_on" );
        precachestring( &"ZOMBIE_PERK_ADDITIONALWEAPONPERK" );
        level._effect["additionalprimaryweapon_light"] = loadfx( "misc/fx_zombie_cola_arsenal_on" );
        level.machine_assets["additionalprimaryweapon"] = spawnstruct();
        level.machine_assets["additionalprimaryweapon"].weapon = "zombie_perk_bottle_additionalprimaryweapon";
        level.machine_assets["additionalprimaryweapon"].off_model = "zombie_vending_three_gun";
        level.machine_assets["additionalprimaryweapon"].on_model = "zombie_vending_three_gun_on";
    }

    if ( isdefined( level.zombiemode_using_deadshot_perk ) && level.zombiemode_using_deadshot_perk )
    {
        precacheitem( "zombie_perk_bottle_deadshot" );
        precacheshader( "specialty_ads_zombies" );
        //  v2.8.1 - WAS zombie_vending_ads / _ads_on. Those two names are stock
        //  Treyarch's and they resolve to NOTHING: neither is an xmodel in any of
        //  the 132 retail fastfiles, nor in mod.ff (measured with Unlinker --list
        //  over the whole zone\all set). Stock never noticed because stock never
        //  sets level.zombiemode_using_deadshot_perk on Die Rise - quality_of_life
        //  .gsc::perks() does, so this branch runs here and only here. The mod's
        //  own default_vending_precaching() has always used the real Alcatraz
        //  cabinet, and so does stock Mob of the Dead; Die Rise was the one copy
        //  that never got the correction.
        precachemodel( "p6_zm_al_vending_ads_on" );
        precachestring( &"ZOMBIE_PERK_DEADSHOT" );
        level._effect["deadshot_light"] = loadfx( "misc/fx_zombie_cola_dtap_on" );
        level.machine_assets["deadshot"] = spawnstruct();
        level.machine_assets["deadshot"].weapon = "zombie_perk_bottle_deadshot";
        level.machine_assets["deadshot"].off_model = "p6_zm_al_vending_ads_on";
        level.machine_assets["deadshot"].on_model = "p6_zm_al_vending_ads_on";
        //  🛑 NOT ADDED, DELIBERATELY. default_vending_precaching() also sets
        //  .power_on_callback / .power_off_callback here (the machine's neon
        //  toggle). Those two functions live in scripts\zm\quality_of_life.gsc,
        //  and this file has no precedent anywhere in the mod for a
        //  scripts\zm\...:: qualified reference. Qualified refs resolve at SCRIPT
        //  LOAD, so getting the form wrong does not misbehave - it stops Die Rise
        //  loading at all. Left for a deliberate, booted change rather than
        //  smuggled in with an asset fix. See the sweep report, finding #4b.
    }

    if ( isdefined( level.zombiemode_using_divetonuke_perk ) && level.zombiemode_using_divetonuke_perk )
    {
        precacheitem( "zombie_perk_bottle_nuke" );
        precacheshader( "specialty_divetonuke_zombies" );
        //  v2.8.1 - WAS zombie_vending_nuke / _nuke_on; same measurement, same
        //  cause as the deadshot block above. Neither name exists in any fastfile.
        precachemodel( "p6_zm_al_vending_nuke_on" );
        precachestring( &"ZOMBIE_PERK_DIVETONUKE" );
        level._effect["divetonuke_light"] = loadfx( "misc/fx_zombie_cola_dtap_on" );
        level.machine_assets["divetonuke"] = spawnstruct();
        level.machine_assets["divetonuke"].weapon = "zombie_perk_bottle_nuke";
        level.machine_assets["divetonuke"].off_model = "p6_zm_al_vending_nuke_on";
        level.machine_assets["divetonuke"].on_model = "p6_zm_al_vending_nuke_on";
    }

    if ( isdefined( level.zombiemode_using_doubletap_perk ) && level.zombiemode_using_doubletap_perk )
    {
        precacheitem( "zombie_perk_bottle_doubletap" );
        precacheshader( "specialty_doubletap_zombies" );
        precachemodel( "zombie_vending_doubletap2" );
        precachemodel( "zombie_vending_doubletap2_on" );
        precachestring( &"ZOMBIE_PERK_DOUBLETAP" );
        level._effect["doubletap_light"] = loadfx( "misc/fx_zombie_cola_dtap_on" );
        level.machine_assets["doubletap"] = spawnstruct();
        level.machine_assets["doubletap"].weapon = "zombie_perk_bottle_doubletap";
        level.machine_assets["doubletap"].off_model = "zombie_vending_doubletap2";
        level.machine_assets["doubletap"].on_model = "zombie_vending_doubletap2_on";
    }

    if ( isdefined( level.zombiemode_using_juggernaut_perk ) && level.zombiemode_using_juggernaut_perk )
    {
        precacheitem( "zombie_perk_bottle_jugg" );
        precacheshader( "specialty_juggernaut_zombies" );
        precachemodel( "zombie_vending_jugg" );
        precachemodel( "zombie_vending_jugg_on" );
        precachestring( &"ZOMBIE_PERK_JUGGERNAUT" );
        level._effect["jugger_light"] = loadfx( "misc/fx_zombie_cola_jugg_on" );
        level.machine_assets["juggernog"] = spawnstruct();
        level.machine_assets["juggernog"].weapon = "zombie_perk_bottle_jugg";
        level.machine_assets["juggernog"].off_model = "zombie_vending_jugg";
        level.machine_assets["juggernog"].on_model = "zombie_vending_jugg_on";
    }

    if ( isdefined( level.zombiemode_using_marathon_perk ) && level.zombiemode_using_marathon_perk )
    {
        precacheitem( "zombie_perk_bottle_marathon" );
        precacheshader( "specialty_marathon_zombies" );
        precachemodel( "zombie_vending_marathon" );
        precachemodel( "zombie_vending_marathon_on" );
        precachestring( &"ZOMBIE_PERK_MARATHON" );
        level._effect["marathon_light"] = loadfx( "maps/zombie/fx_zmb_cola_staminup_on" );
        level.machine_assets["marathon"] = spawnstruct();
        level.machine_assets["marathon"].weapon = "zombie_perk_bottle_marathon";
        level.machine_assets["marathon"].off_model = "zombie_vending_marathon";
        level.machine_assets["marathon"].on_model = "zombie_vending_marathon_on";
    }

    if ( isdefined( level.zombiemode_using_revive_perk ) && level.zombiemode_using_revive_perk )
    {
        precacheitem( "zombie_perk_bottle_revive" );
        precacheshader( "specialty_quickrevive_zombies" );
        precachemodel( "zombie_vending_revive" );
        precachemodel( "zombie_vending_revive_on" );
        precachestring( &"ZOMBIE_PERK_QUICKREVIVE" );
        level._effect["revive_light"] = loadfx( "misc/fx_zombie_cola_revive_on" );
        level._effect["revive_light_flicker"] = loadfx( "maps/zombie/fx_zmb_cola_revive_flicker" );
        level.machine_assets["revive"] = spawnstruct();
        level.machine_assets["revive"].weapon = "zombie_perk_bottle_revive";
        level.machine_assets["revive"].off_model = "zombie_vending_revive";
        level.machine_assets["revive"].on_model = "zombie_vending_revive_on";
    }

    if ( isdefined( level.zombiemode_using_sleightofhand_perk ) && level.zombiemode_using_sleightofhand_perk )
    {
        precacheitem( "zombie_perk_bottle_sleight" );
        precacheshader( "specialty_fastreload_zombies" );
        precachemodel( "zombie_vending_sleight" );
        precachemodel( "zombie_vending_sleight_on" );
        precachestring( &"ZOMBIE_PERK_FASTRELOAD" );
        level._effect["sleight_light"] = loadfx( "misc/fx_zombie_cola_on" );
        level.machine_assets["speedcola"] = spawnstruct();
        level.machine_assets["speedcola"].weapon = "zombie_perk_bottle_sleight";
        level.machine_assets["speedcola"].off_model = "zombie_vending_sleight";
        level.machine_assets["speedcola"].on_model = "zombie_vending_sleight_on";
    }

    if ( isdefined( level.zombiemode_using_tombstone_perk ) && level.zombiemode_using_tombstone_perk )
    {
        precacheitem( "zombie_perk_bottle_tombstone" );
        precacheshader( "specialty_tombstone_zombies" );
        precachemodel( "zombie_vending_tombstone" );
        precachemodel( "zombie_vending_tombstone_on" );
        precachemodel( "ch_tombstone1" );
        precachestring( &"ZOMBIE_PERK_TOMBSTONE" );
        level._effect["tombstone_light"] = loadfx( "misc/fx_zombie_cola_on" );
        level.machine_assets["tombstone"] = spawnstruct();
        level.machine_assets["tombstone"].weapon = "zombie_perk_bottle_tombstone";
        level.machine_assets["tombstone"].off_model = "zombie_vending_tombstone";
        level.machine_assets["tombstone"].on_model = "zombie_vending_tombstone_on";
    }

    if ( isdefined( level.zombiemode_using_chugabud_perk ) && level.zombiemode_using_chugabud_perk )
    {
        precacheitem( "zombie_perk_bottle_whoswho" );
        precacheshader( "specialty_quickrevive_zombies" );
        precachemodel( "p6_zm_vending_chugabud" );
        precachemodel( "p6_zm_vending_chugabud_on" );
        precachemodel( "ch_tombstone1" );
        precachestring( &"ZOMBIE_PERK_TOMBSTONE" );
        level._effect["tombstone_light"] = loadfx( "misc/fx_zombie_cola_on" );
        level.machine_assets["whoswho"] = spawnstruct();
        level.machine_assets["whoswho"].weapon = "zombie_perk_bottle_whoswho";
        level.machine_assets["whoswho"].off_model = "p6_zm_vending_chugabud";
        level.machine_assets["whoswho"].on_model = "p6_zm_vending_chugabud_on";
	}
	if (level._custom_perks.size > 0)
	{
		a_keys = getarraykeys(level._custom_perks);
		for (i = 0; i < a_keys.size; i++)
		{
			if (isdefined(level._custom_perks[a_keys[i]].precache_func))
			{
				level [[level._custom_perks[a_keys[i]].precache_func]]();
			}
		}
	}
}

init_elevator_perks()
{
    level.elevator_perks = [];
    level.elevator_perks_building = [];
    level.elevator_perks_building["green"] = [];
    level.elevator_perks_building["blue"] = [];
    level.elevator_perks_building["green"][0] = spawnstruct();
    level.elevator_perks_building["green"][0].model = "zombie_vending_revive";
    level.elevator_perks_building["green"][0].script_noteworthy = "specialty_quickrevive";
    level.elevator_perks_building["green"][0].turn_on_notify = "revive_on";
    a = 1;
    b = 2;

    if ( randomint( 100 ) > 50 )
    {
        a = 2;
        b = 1;
    }

    level.elevator_perks_building["green"][a] = spawnstruct();
    level.elevator_perks_building["green"][a].model = "p6_zm_vending_chugabud";
    level.elevator_perks_building["green"][a].script_noteworthy = "specialty_finalstand";
    level.elevator_perks_building["green"][a].turn_on_notify = "chugabud_on";
    level.elevator_perks_building["green"][b] = spawnstruct();
    level.elevator_perks_building["green"][b].model = "zombie_vending_sleight";
    level.elevator_perks_building["green"][b].script_noteworthy = "specialty_fastreload";
    level.elevator_perks_building["green"][b].turn_on_notify = "sleight_on";
    level.elevator_perks_building["blue"][0] = spawnstruct();
    level.elevator_perks_building["blue"][0].model = "zombie_vending_three_gun";
    level.elevator_perks_building["blue"][0].script_noteworthy = "specialty_additionalprimaryweapon";
    level.elevator_perks_building["blue"][0].turn_on_notify = "specialty_additionalprimaryweapon_power_on";
    level.elevator_perks_building["blue"][1] = spawnstruct();
    level.elevator_perks_building["blue"][1].model = "zombie_vending_jugg";
    level.elevator_perks_building["blue"][1].script_noteworthy = "specialty_armorvest";
    level.elevator_perks_building["blue"][1].turn_on_notify = "juggernog_on";
    level.elevator_perks_building["blue"][2] = spawnstruct();
    level.elevator_perks_building["blue"][2].model = "zombie_vending_doubletap2";
    level.elevator_perks_building["blue"][2].script_noteworthy = "specialty_rof";
    level.elevator_perks_building["blue"][2].turn_on_notify = "doubletap_on";
    level.elevator_perks_building["blue"][3] = spawnstruct();
    level.elevator_perks_building["blue"][3].model = "p6_anim_zm_buildable_pap";
    level.elevator_perks_building["blue"][3].script_noteworthy = "specialty_weapupgrade";
    level.elevator_perks_building["blue"][3].turn_on_notify = "Pack_A_Punch_on";
    players_expected = getnumexpectedplayers();
    level.override_perk_targetname = "zm_perk_machine_override";
    level.elevator_perks_building["blue"] = array_randomize( level.elevator_perks_building["blue"] );
    level.elevator_perks = arraycombine( level.elevator_perks_building["green"], level.elevator_perks_building["blue"], 0, 0 );
    random_perk_structs = [];
    revive_perk_struct = getstruct( "force_quick_revive", "targetname" );
    revive_perk_struct = getstruct( revive_perk_struct.target, "targetname" );
    perk_structs = getstructarray( "zm_random_machine", "script_noteworthy" );

    for ( i = 0; i < perk_structs.size; i++ )
    {
        random_perk_structs[i] = getstruct( perk_structs[i].target, "targetname" );
        random_perk_structs[i].script_parameters = perk_structs[i].script_parameters;
        random_perk_structs[i].script_linkent = getent( "elevator_" + perk_structs[i].script_parameters + "_body", "targetname" );
    }

    green_structs = [];
    blue_structs = [];

    foreach ( perk_struct in random_perk_structs )
    {
        if ( isdefined( perk_struct.script_parameters ) )
        {
            if ( issubstr( perk_struct.script_parameters, "bldg1" ) )
            {
                green_structs[green_structs.size] = perk_struct;
                continue;
            }

            blue_structs[blue_structs.size] = perk_struct;
        }
    }

    green_structs = array_exclude( green_structs, revive_perk_struct );
    green_structs = array_randomize( green_structs );
    blue_structs = array_randomize( blue_structs );
    level.random_perk_structs = array( revive_perk_struct );
    level.random_perk_structs = arraycombine( level.random_perk_structs, green_structs, 0, 0 );
    level.random_perk_structs = arraycombine( level.random_perk_structs, blue_structs, 0, 0 );

    for ( i = 0; i < level.elevator_perks.size; i++ )
    {
        if ( !isdefined( level.random_perk_structs[i] ) )
            continue;

        level.random_perk_structs[i].targetname = "zm_perk_machine_override";
        level.random_perk_structs[i].model = level.elevator_perks[i].model;
        level.random_perk_structs[i].script_noteworthy = level.elevator_perks[i].script_noteworthy;
        level.random_perk_structs[i].turn_on_notify = level.elevator_perks[i].turn_on_notify;

        if ( !isdefined( level.struct_class_names["targetname"]["zm_perk_machine_override"] ) )
            level.struct_class_names["targetname"]["zm_perk_machine_override"] = [];

        level.struct_class_names["targetname"]["zm_perk_machine_override"][level.struct_class_names["targetname"]["zm_perk_machine_override"].size] = level.random_perk_structs[i];
	}

	static_perk_structs = getstructarray("zm_perk_machine", "targetname");

	foreach (static_perk_struct in static_perk_structs)
	{
		if (static_perk_struct.script_noteworthy == "specialty_longersprint" || static_perk_struct.script_noteworthy == "specialty_flakjacket")
		{
			level.struct_class_names["targetname"]["zm_perk_machine_override"][level.struct_class_names["targetname"]["zm_perk_machine_override"].size] = static_perk_struct;
		}
	}
}

added_weapons()
{
    if (level.script == "zm_highrise")
	{
        level.weapons_using_ammo_sharing = 1;

        include_weapon( "uzi_zm" );
        include_weapon( "uzi_upgraded_zm", 0 );
        add_zombie_weapon( "uzi_zm", "uzi_upgraded_zm", &"ZOMBIE_WEAPON_UZI", 1500, "wpck_smg", "", undefined );

        include_weapon( "thompson_zm" );
        include_weapon( "thompson_upgraded_zm", 0 );
        add_zombie_weapon( "thompson_zm", "thompson_upgraded_zm", &"ZMWEAPON_THOMPSON_WALLBUY", 1500, "wpck_smg", "", 800 );

        include_weapon( "ak47_zm" );
        include_weapon( "ak47_upgraded_zm", 0 );
        add_zombie_weapon( "ak47_zm", "ak47_upgraded_zm", &"ZOMBIE_WEAPON_AK47", 500, "wpck_mg", "", undefined, 1 );

        include_weapon( "mp40_stalker_zm" );
        include_weapon( "mp40_stalker_upgraded_zm", 0 );
        add_zombie_weapon( "mp40_stalker_zm", "mp40_stalker_upgraded_zm", &"ZOMBIE_WEAPON_MP40", 1300, "wpck_smg", "", undefined, 1 );

        include_weapon( "scar_zm" );
        include_weapon( "scar_upgraded_zm", 0 );
        add_zombie_weapon( "scar_zm", "scar_upgraded_zm", &"ZOMBIE_WEAPON_SCAR", 50, "wpck_rifle", "", undefined, 1 );

        include_weapon( "mg08_zm" );
        include_weapon( "mg08_upgraded_zm", 0 );
        add_zombie_weapon( "mg08_zm", "mg08_upgraded_zm", &"ZOMBIE_WEAPON_MG08", 50, "wpck_mg", "", undefined, 1 );

        include_weapon( "minigun_alcatraz_zm" );
        include_weapon( "minigun_alcatraz_upgraded_zm", 0 );
        add_zombie_weapon( "minigun_alcatraz_zm", "minigun_alcatraz_upgraded_zm", &"ZOMBIE_WEAPON_RPD", 50, "wpck_mg", "", undefined, 1 );
        add_limited_weapon( "minigun_alcatraz_zm", 1 );
        add_limited_weapon( "minigun_alcatraz_upgraded_zm", 1 );

        include_weapon( "evoskorpion_zm" );
        include_weapon( "evoskorpion_upgraded_zm", 0 );
        add_zombie_weapon( "evoskorpion_zm", "evoskorpion_upgraded_zm", &"ZOMBIE_WEAPON_EVOSKORPION", 50, "wpck_smg", "", undefined, 1 );

        include_weapon( "hk416_zm" );
        include_weapon( "hk416_upgraded_zm", 0 );
        add_zombie_weapon( "hk416_zm", "hk416_upgraded_zm", &"ZOMBIE_WEAPON_HK416", 100, "", "", undefined );

        include_weapon( "ksg_zm" );
        include_weapon( "ksg_upgraded_zm", 0 );
        add_zombie_weapon( "ksg_zm", "ksg_upgraded_zm", &"ZOMBIE_WEAPON_KSG", 1100, "wpck_shotgun", "", undefined, 1 );

        include_weapon( "mp44_zm" );
        include_weapon( "mp44_upgraded_zm", 0 );
        add_zombie_weapon( "mp44_zm", "mp44_upgraded_zm", &"ZMWEAPON_MP44_WALLBUY", 1400, "wpck_rifle", "", undefined, 1 );

        include_weapon( "ballista_zm" );
        include_weapon( "ballista_upgraded_zm", 0 );
        add_zombie_weapon( "ballista_zm", "ballista_upgraded_zm", &"ZMWEAPON_BALLISTA_WALLBUY", 500, "wpck_snipe", "", undefined, 1 );

        include_weapon( "rnma_zm" );
        include_weapon( "rnma_upgraded_zm", 0 );
        add_zombie_weapon( "rnma_zm", "rnma_upgraded_zm", &"ZOMBIE_WEAPON_RNMA", 50, "pickup_six_shooter", "", undefined, 1 );

        include_weapon( "lsat_zm" );
        include_weapon( "lsat_upgraded_zm", 0 );
        add_zombie_weapon( "lsat_zm", "lsat_upgraded_zm", &"ZOMBIE_WEAPON_LSAT", 2000, "wpck_lsat", "", undefined, 1 );

        include_weapon( "c96_zm" );
        include_weapon( "c96_upgraded_zm", 0 );
        add_zombie_weapon( "c96_zm", "c96_upgraded_zm", &"ZOMBIE_WEAPON_C96", 50, "wpck_pistol", "", undefined, 1 );

        include_weapon( "beretta93r_extclip_zm" );
        include_weapon( "beretta93r_extclip_upgraded_zm", 0 );
        add_zombie_weapon( "beretta93r_extclip_zm", "beretta93r_extclip_upgraded_zm", &"ZOMBIE_WEAPON_BERETTA93r", 1000, "", "", undefined, 1 );
        add_shared_ammo_weapon( "beretta93r_extclip_zm", "beretta93r_zm" );

        include_weapon( "ak74u_extclip_zm" );
        include_weapon( "ak74u_extclip_upgraded_zm", 0 );
        add_zombie_weapon( "ak74u_extclip_zm", "ak74u_extclip_upgraded_zm", &"ZOMBIE_WEAPON_AK74U", 1200, "smg", "", undefined, 1 );
        add_shared_ammo_weapon( "ak74u_extclip_zm", "ak74u_zm" );
    }
}

move_marathon_origins()
{
	if (!is_gametype_active("zclassic"))
	{
		return;
	}

	trigs = getentarray("vending_marathon", "target");

	if (!isdefined(trigs))
	{
		return;
	}

	foreach (trig in trigs)
	{
		if (!isdefined(trig.machine))
		{
			continue;
		}

		if (isdefined(trig.clip))
		{
			trig.clip.origin += anglestoup(trig.machine.angles) * 32;
		}

		if (isdefined(trig.bump))
		{
			trig.bump.origin += anglestoup(trig.machine.angles) * 96;
		}

		trig.origin += anglestoup(trig.machine.angles) * 96;
	}
}
// ============================================================================
// ============================================================================
//  DIE RISE WEAPONS  -  PACK-A-PUNCHED SLIQUIFIER + SEMTEX WALL BUY
//
//  🛑 v2.14.17 - "SLIQUIFIER PRE-NERF" IS GONE, AND ITS DAMAGE MOVED TO THE
//  PACKED GUN. User, 2026-09-08: *"remove the option for sliquifier pre nerf
//  patch, and then make it so that the sliquifier is pack a punchable with my
//  mod, and the pack a punch version is infinite damage like the pre nerf
//  version, im pretty sure the BO2 REIMAGINED by jbleezy, pretty basic thing to
//  do"*. Deleted with the row: the `sliquifier_prenerf` dvar and its create_dvar
//  in quality_of_life.gsc, the PATCHES row in optionssettings.lua, the level-var
//  watch thread, and the fallback death callback that let the chain continue
//  while the gun was put away. The BASE gun is now stock in every respect.
//
//  ----------------------------------------------------------------------------
//  1. WHY STOCK REFUSES TO PACK IT - one undefined argument, nothing else
//
//  Treyarch built the entire upgraded weapon and then never linked it up.
//  Measured, not assumed:
//    - `weapon, slipgun_upgraded_zm` IS in zm_highrise.ff ( Unlinker --list ).
//      Both defs dumped and diffed field by field: 1,027 fields each, exactly
//      TWO differ - displayName ZMWEAPON_SLIPGUN -> ZMWEAPON_SLIPGUN_UPGRADED,
//      and grenadeWeapon slip_bolt_zm -> slip_bolt_upgraded_zm. Same clip ( 10 ),
//      same max ammo ( 40 ), and `camo` is EMPTY on both - so the packed gun
//      looks exactly like the plain one. That is Treyarch's data, not a gap here
//      ( ERROR_CATALOGUE §54 already recorded that this pair carries no camo ).
//    - `localize, ZMWEAPON_SLIPGUN_UPGRADED` is in en_patch_zm.ff and reads
//      **"Sl1qu1f13r"** - the game's own name for the packed gun, shipped in
//      retail and, until now, unreachable.
//    - The includes are already there on both sides: zm_highrise.gsc:936
//      `include_weapon( "slipgun_upgraded_zm", 0 )`, :948
//      `add_limited_weapon( "slipgun_upgraded_zm", 1 )`, and the client's own
//      zm_highrise.csc:185 ( this mod's .csc mirrors it at :137 ).
//    - _zm_weap_slipgun.gsc branches on the upgraded names throughout: :30
//      precaches slip_bolt_upgraded_zm, :89 routes it, :102 gives its goo pool
//      36 s instead of 24 s, :788 computes an `upgraded` flag, :814 and :819
//      accept both spellings.
//
//  The one missing link is zm_highrise.gsc:859:
//      add_zombie_weapon( "slipgun_zm", undefined, &"ZOMBIE_WEAPON_SLIPGUN", ... )
//  - the second argument is the upgrade name, and it is `undefined`. The Pack-a-
//  Punch trigger ( _zm_perks.gsc:556 ) skips any weapon that fails
//  _zm_weapons::can_upgrade_weapon(), and that function ( :1786 ) is exactly
//      return isdefined( level.zombie_weapons[ weaponname ].upgrade_name );
//  So zmqol_slipgun_pap_enable() below writes the two table entries
//  add_zombie_weapon() would have written ( :546 and :549 ), and the machine
//  accepts the gun. Jbleezy's BO2-Reimagined does the same two lines
//  ( _zm_reimagined.gsc:780-781 ) - the user pointed at it, and it checks out.
//
//  🌟 It also makes stock's own limited-weapon accounting correct:
//  limited_weapon_below_quota() ( _zm_weapons.gsc:725 ) reads `.upgrade_name` to
//  count a packed copy against Die Rise's one-Sliquifier limit, and could not
//  while the field was undefined.
//
//  ----------------------------------------------------------------------------
//  2. WHERE "INFINITE DAMAGE" HAS TO GO - two functions, not one
//
//  The Sliquifier does not kill with its projectile. Every kill is
//  `dodamage( level.slipgun_damage, ... )`, and level.slipgun_damage is set ONCE
//  ( _zm_weap_slipgun.gsc:65 ) to `_zm::ai_zombie_health( 100 )` - the health a
//  zombie has on round 100. Past that round the goo stops killing. That is the
//  nerf, and it is applied in two places:
//    - slipgun_zombie_1st_hit_response ( :759 ) - the zombie actually hit;
//    - explode_to_near_zombies ( :683 ) - every zombie the chain reaches.
//  Both are replaced below. Fixing only the first would leave the packed gun
//  killing one zombie while the chain fizzled, because the chain only continues
//  through zombies it KILLS - stock's death callback is what calls
//  explode_into_goo, which is what starts the next hop.
//
//  The damage used when upgraded is that zombie's own `health`, so it is lethal
//  at any round. BO2-Reimagined uses the same value. The deleted row's
//  ai_zombie_health( 255 ) was the same idea by a longer road - it only worked
//  because the health curve saturates.
//
//  🛑 STOCK'S OWN `upgraded` ARGUMENT IS NOT ENOUGH BY ITSELF. :788 computes it
//  as `damageweapon == "slipgun_upgraded_zm"`, but the damage that reaches this
//  callback is just as often the bolt ( slip_bolt_upgraded_zm ) or the goo
//  ( slip_goo_zm ), and for those the flag reads false with the packed gun in
//  hand - see is_slipgun_explosive_damage() at :814, which accepts all three
//  names. So the flag is ORed with the gun the player is carrying, and the
//  verdict is cached on the player because the chain is handed a POSITION, not a
//  weapon, and has no other way to know which gun started it.
//
//  ----------------------------------------------------------------------------
//  3. SEMTEX WALL BUY  (v1.99.96, unchanged by the v2.14.17 edit)
//
//  From BO2-Remix's Die Rise feature list, *"Semtex wallbuy added by b23r"*,
//  approved by the user 2026-08-20. Die Rise already had everything it needed
//  and none of it had to be shipped:
//    - zm_highrise.gsc:848 `add_zombie_weapon( "sticky_grenade_zm", ...,
//      &"ZOMBIE_WEAPON_STICKY_GRENADE", 250, "grenade", "", 250 )` - the weapon,
//      its hint string and its 250 cost are all registered already, and :870
//      `include_weapon( "sticky_grenade_zm", 0 )` keeps it OUT of the box, so
//      this wall buy is the only way to get it on the map.
//    - _zm.gsc:1227 loads level._effect["sticky_grenade_zm_fx"] on every map that
//      does not clear level._uses_sticky_grenades. Die Rise does not.
//    - _zm_weapons.gsc:1975 weapon_spawn_think has an explicit
//      `weapontype( ... ) == "grenade"` branch, so a grenade wall buy is a
//      stock-supported path, not a stretch.
//
//  ONE DELIBERATE DEPARTURE FROM REMIX, AND IT IS THE COMPLETENESS AUDIT.
//  Remix draws this wall buy with `t6_wpn_claymore_world` - a CLAYMORE on the
//  wall where a semtex should be. Measured with Unlinker over the real
//  fastfiles: `t6_wpn_grenade_semtex_world` IS in zm_highrise.ff, and it is the
//  only model on the map that follows the t6_wpn_*_world convention every other
//  wall buy uses. ( The name Remix's own commented-out Buried line reaches for,
//  t6_wpn_grenade_sticky_grenade_world, exists in NO zombies fastfile at all -
//  that line would have failed. ) So this ships the real semtex model.
//  CONFIRMED A SECOND WAY, from the weapon def itself: stock's own wall-buy
//  placer ( _zm_weapons.gsc:1025 ) picks its model with
//  `getweaponmodel( weapon )`, which returns the def's worldModel field. The
//  shipped def for sticky_grenade_zm ( T6-Data-Archive ZM/Weapons/WEAPONS )
//  has worldModel = t6_wpn_grenade_semtex_world - byte-for-byte the literal
//  below. The literal is kept because precachemodel() needs a name at init
//  anyway, and it is now the game's own answer, not a choice.
// ============================================================================

// ----------------------------------------------------------------------------
//  zmqol_slipgun_pap_enable  -  the two table writes that unlock the machine.
//
//  Threaded rather than written straight into init() because the order of this
//  file's init() against stock's own weapon registration is not something to
//  assume: add_zombie_weapon() has to have run first or there is no struct to
//  write to. The wait is bounded - on a Die Rise mode that never includes the
//  Sliquifier ( the struct is only created for modes whose include list has it )
//  the thread gives up instead of spinning for the whole game.
//
//  The println is the hook proof the standing rule asks for: if it is missing
//  from console_zm.log, the registration never happened and the machine will
//  have refused the gun for that reason and no other.
// ----------------------------------------------------------------------------
zmqol_slipgun_pap_enable()
{
    level endon( "end_game" );

    n_waited = 0;

    while ( !isdefined( level.zombie_weapons ) || !isdefined( level.zombie_weapons[ "slipgun_zm" ] ) )
    {
        if ( n_waited >= 60 )
            return;

        wait 0.5;
        n_waited += 0.5;
    }

    if ( !isdefined( level.zombie_weapons_upgraded ) )
        level.zombie_weapons_upgraded = [];

    level.zombie_weapons[ "slipgun_zm" ].upgrade_name = "slipgun_upgraded_zm";
    level.zombie_weapons_upgraded[ "slipgun_upgraded_zm" ] = "slipgun_zm";

    println( "[zm_qol] sliquifier: pack-a-punch enabled, slipgun_zm -> slipgun_upgraded_zm" );
}

// ----------------------------------------------------------------------------
//  zmqol_slipgun_is_upgraded  -  which Sliquifier started this?
//
//  Stock's own flag first ( it is right whenever the damage came from the gun
//  itself ), then the gun in the player's hands, which covers the bolt and goo
//  damage names that make stock's flag read false. hasweapon() is exact here:
//  Pack-a-Punch REPLACES the weapon, and the map allows one Sliquifier per
//  player, so nobody can hold both.
// ----------------------------------------------------------------------------
zmqol_slipgun_is_upgraded( b_flag, player )
{
    if ( is_true( b_flag ) )
        return 1;

    if ( isdefined( player ) && isplayer( player ) && player hasweapon( "slipgun_upgraded_zm" ) )
        return 1;

    return 0;
}

// ----------------------------------------------------------------------------
//  zmqol_slipgun_1st_hit_response  -  replaceFunc'd in main().
//
//  STOCK ( _zm_weap_slipgun.gsc:759-780 ) with the upgraded branch added. With
//  the plain gun it is stock exactly: same notifies, same orientmode, same
//  ignoreall/gibbed, same insta-kill handling, same damage number, same weapon
//  name on the dodamage ( "slip_goo_zm" - stock's own death callback tests for
//  it at :814, and the chain would stop dead under any other name ).
//
//  Called by stock as `self thread slipgun_zombie_1st_hit_response( ... )` from
//  slipgun_zombie_hit_response_internal ( :789 ) - an unqualified same-file call,
//  which STOCK_REFERENCE §7a records as measured-hookable for THREADED calls.
//  The println below is the proof for this half.
// ----------------------------------------------------------------------------
zmqol_slipgun_1st_hit_response( upgraded, player )
{
    b_up = zmqol_slipgun_is_upgraded( upgraded, player );

    if ( isdefined( player ) && isplayer( player ) )
        player.zmqol_slip_upgraded = b_up;

    self notify( "stop_find_flesh" );
    self notify( "zombie_acquire_enemy" );
    self orientmode( "face default" );
    self.ignoreall = 1;
    self.gibbed = 1;

    if ( isalive( self ) )
    {
        if ( !isdefined( self.goo_chain_depth ) )
            self.goo_chain_depth = 0;

        if ( self.health > 0 )
        {
            if ( player maps\mp\zombies\_zm_powerups::is_insta_kill_active() )
                self.health = 1;

            n_damage = level.slipgun_damage;

            if ( b_up )
            {
                n_damage = self.health;

                if ( !is_true( level.zmqol_slip_logged ) )
                {
                    level.zmqol_slip_logged = 1;
                    println( "[zm_qol] sliquifier: upgraded hit, lethal damage " + n_damage );
                }
            }

            self dodamage( n_damage, self.origin, player, player, "none", level.slipgun_damage_mod, 0, "slip_goo_zm" );
        }
    }
}

// ----------------------------------------------------------------------------
//  zmqol_explode_to_near_zombies  -  replaceFunc'd in main().
//
//  STOCK ( _zm_weap_slipgun.gsc:683-757 ) with the same upgraded branch. Called
//  by stock as `level thread explode_to_near_zombies( ... )` from
//  explode_into_goo ( :682 ), so `self` is level and the only handle on the
//  player is the argument - which is why the upgraded verdict is cached on the
//  player rather than passed down.
//
//  Stock's re-slip guard is `( !isdefined( enemy.slick_count ) ||
//  enemy.slick_count == 0 )`. BO2-Remix wrote `isDefined( ... ) && ... == 0`,
//  which is the opposite for an undefined count; stock's condition is what ships
//  here.
// ----------------------------------------------------------------------------
zmqol_explode_to_near_zombies( player, origin, radius, chain_depth )
{
    if ( level.zombie_vars[ "slipgun_max_kill_chain_depth" ] > 0 && chain_depth > level.zombie_vars[ "slipgun_max_kill_chain_depth" ] )
        return;

    b_up = 0;

    if ( isdefined( player ) && isplayer( player ) )
        b_up = zmqol_slipgun_is_upgraded( player.zmqol_slip_upgraded, player );

    enemies = get_round_enemy_array();
    enemies = get_array_of_closest( origin, enemies );
    minchainwait = level.zombie_vars[ "slipgun_chain_wait_min" ];
    maxchainwait = level.zombie_vars[ "slipgun_chain_wait_max" ];
    rsquared = radius * radius;
    tag = "J_Head";
    marked_zombies = [];

    if ( isdefined( enemies ) && enemies.size )
    {
        index = 0;
        enemy = enemies[ index ];

        while ( distancesquared( enemy.origin, origin ) < rsquared )
        {
            if ( isalive( enemy ) && !is_true( enemy.guts_explosion ) && !is_true( enemy.nuked ) && !isdefined( enemy.slipgun_sizzle ) )
            {
                trace = bullettrace( origin + vectorscale( ( 0, 0, 1 ), 50.0 ), enemy.origin + vectorscale( ( 0, 0, 1 ), 50.0 ), 0, undefined, 1 );

                if ( isdefined( trace[ "fraction" ] ) && trace[ "fraction" ] == 1 )
                {
                    enemy.slipgun_sizzle = playfxontag( level._effect[ "slipgun_simmer" ], enemy, tag );
                    marked_zombies[ marked_zombies.size ] = enemy;
                }
            }

            index++;

            if ( index >= enemies.size )
                break;

            enemy = enemies[ index ];
        }
    }

    if ( isdefined( marked_zombies ) && marked_zombies.size )
    {
        foreach ( enemy in marked_zombies )
        {
            if ( isalive( enemy ) && !is_true( enemy.guts_explosion ) && !is_true( enemy.nuked ) )
            {
                wait( randomfloatrange( minchainwait, maxchainwait ) );

                if ( isalive( enemy ) && !is_true( enemy.guts_explosion ) && !is_true( enemy.nuked ) )
                {
                    if ( !isdefined( enemy.goo_chain_depth ) )
                        enemy.goo_chain_depth = chain_depth;

                    if ( enemy.health > 0 )
                    {
                        if ( player maps\mp\zombies\_zm_powerups::is_insta_kill_active() )
                            enemy.health = 1;

                        n_damage = level.slipgun_damage;

                        if ( b_up )
                            n_damage = enemy.health;

                        enemy dodamage( n_damage, origin, player, player, "none", level.slipgun_damage_mod, 0, "slip_goo_zm" );
                    }

                    if ( level.slippery_spot_count < level.zombie_vars[ "slipgun_reslip_max_spots" ] )
                    {
                        if ( ( !isdefined( enemy.slick_count ) || enemy.slick_count == 0 ) && enemy.health <= 0 )
                        {
                            if ( level.zombie_vars[ "slipgun_reslip_rate" ] > 0 && randomint( level.zombie_vars[ "slipgun_reslip_rate" ] ) == 0 )
                            {
                                startpos = origin;
                                duration = 24;
                                thread maps\mp\zombies\_zm_weap_slipgun::add_slippery_spot( enemy.origin, duration, startpos );
                            }
                        }
                    }
                }
            }
        }
    }
}

// ----------------------------------------------------------------------------
//  zmqol_semtex_wallbuy  -  row 4.
//
//  🛑 v2.0.2 - NOT A TOGGLE ANY MORE. User, 2026-08-20: *"this semtex wall buy
//  should just be apart of the mod not an option you can toggle on or off, so
//  get rid of that option and just keep the added wallbuys i told you to add
//  earlier."*  The `semtex_wallbuy` dvar, its create_dvar() in
//  quality_of_life.gsc and its PATCHES row in optionssettings.lua are all gone;
//  the wall buy itself is unchanged and now always spawns.
//
//  The flag_wait below STAYS. It was there so the dvar read could not race the
//  root script's create_dvar(), but it is load-bearing for a second reason as
//  well: zmqol_spawn_wallbuy_weapon() registers a static unitrigger and plays
//  the chalk fx, and both want the map fully up. Removing it would be an
//  unrelated change riding on this one.
//
//  Angle, position and the "weapon_upgrade" targetname are Remix's, which is the
//  tested placement; the MODEL is not - see the banner.
// ----------------------------------------------------------------------------
zmqol_semtex_wallbuy()
{
    level endon( "end_game" );

    flag_wait( "initial_blackscreen_passed" );

    zmqol_spawn_wallbuy_weapon( ( 0, 270, 0 ), ( 2119, 1826, 3115 ), "sticky_grenade_zm_fx", "sticky_grenade_zm", "t6_wpn_grenade_semtex_world" );
}

// ----------------------------------------------------------------------------
//  zmqol_spawn_wallbuy_weapon  -  a script-placed wall buy.
//
//  Adapted from BO2-Remix's spawn_wallbuy_weapon: the melee-weapon and claymore
//  branches are dropped ( neither can be reached from here ), and the bounds are
//  measured off a throwaway script_model exactly as the original does, because
//  the trigger box has to match the model that is actually drawn.
//
//  Every helper it calls is stock: get_weapon_cost / get_weapon_hint /
//  get_weapon_display_name / wall_weapon_update_prompt / weapon_spawn_think all
//  come from maps\mp\zombies\_zm_weapons, which this file already includes, and
//  the two unitrigger calls are reached qualified.
// ----------------------------------------------------------------------------
zmqol_spawn_wallbuy_weapon( weapon_angles, weapon_coordinates, chalk_fx, weapon_name, weapon_model )
{
    tempmodel = spawn( "script_model", ( 0, 0, 0 ) );
    tempmodel.origin = weapon_coordinates;
    tempmodel.angles = weapon_angles;
    tempmodel setmodel( weapon_model );
    tempmodel useweaponhidetags( weapon_name );

    absmins = tempmodel getabsmins();
    absmaxs = tempmodel getabsmaxs();
    bounds  = absmaxs - absmins;

    stub = spawnstruct();
    stub.origin = weapon_coordinates;
    stub.angles = weapon_angles;
    stub.script_length = bounds[ 0 ] * 0.25;
    stub.script_width  = bounds[ 1 ];
    stub.script_height = bounds[ 2 ];
    stub.origin -= anglestoright( stub.angles ) * ( stub.script_length * 0.4 );
    stub.target     = weapon_name;
    stub.targetname = "weapon_upgrade";
    stub.cursor_hint = "HINT_NOICON";
    stub.cost = get_weapon_cost( weapon_name );

    if ( !is_true( level.monolingustic_prompt_format ) )
    {
        stub.hint_string = get_weapon_hint( weapon_name );
        stub.hint_parm1  = stub.cost;
    }
    else
    {
        stub.hint_parm1 = get_weapon_display_name( weapon_name );

        if ( !isdefined( stub.hint_parm1 ) || stub.hint_parm1 == "" || stub.hint_parm1 == "none" )
            stub.hint_parm1 = "missing weapon name " + weapon_name;

        stub.hint_parm2 = stub.cost;
        stub.hint_string = &"ZOMBIE_WEAPONCOSTONLY";
    }

    stub.weapon_upgrade = weapon_name;
    stub.zombie_weapon_upgrade = weapon_name;
    stub.script_unitrigger_type = "unitrigger_box_use";
    stub.require_look_at  = 1;
    stub.require_look_from = 0;
    stub.prompt_and_visibility_func = ::wall_weapon_update_prompt;

    maps\mp\zombies\_zm_unitrigger::unitrigger_force_per_player_triggers( stub, 1 );
    maps\mp\zombies\_zm_unitrigger::register_static_unitrigger( stub, ::weapon_spawn_think );

    tempmodel delete();

    level thread zmqol_play_chalk_fx( chalk_fx, weapon_coordinates, weapon_angles );
}

// ----------------------------------------------------------------------------
//  zmqol_play_chalk_fx  -  the wall chalk.
//
//  Remix's shape: spawn it, trigger it, and respawn it whenever someone else
//  connects so a late joiner sees it too. spawnfx + triggerfx is stock's own
//  pattern for a script-placed looping effect ( maps\mp\_fx.gsc:248-256 ).
// ----------------------------------------------------------------------------
zmqol_play_chalk_fx( effect, origin, angles )
{
    level endon( "end_game" );

    if ( !isdefined( level._effect[ effect ] ) )
        return;

    for ( ;; )
    {
        fx = spawnfx( level._effect[ effect ], origin, anglestoforward( angles ), anglestoup( angles ) );
        triggerfx( fx );

        level waittill( "connected", player );

        fx delete();
    }
}

// ============================================================================
//  zmqol_locker_watch / zmqol_locker_think  -  THE DIE RISE WEAPON LOCKER IS
//  SILENT FOR THE SAME REASON THE BANK WAS
//
//  User, 2026-09-04: "just fix the locker as well".
//
//  _zm_weapon_locker.gsc plays evt_fridge_locker_close when you stash a gun
//  ( :177 ) and evt_fridge_locker_open when you take it back ( :242 ). Neither
//  alias is in Die Rise's own table - zmb_highrise.all, dumped straight out of
//  zm_highrise.ff, is 9,953 rows and evt_fridge_locker_ is in 0 of them - so
//  both calls name nothing and are silent with no error. There is no shared
//  payload to fall back on either: Green Run and Buried each point those two
//  names at a recording of their own, the diner fridge there and putin /
//  takeout here. Same shape as the bank ( zmqol_bank_sounds_init above ); both
//  are written up in STOCK_REFERENCE.md.
//
//  v2.11.19 - THE ROWS ARE BURIED'S, FIELD FOR FIELD. v2.11.15 shipped the
//  TranZit fridge FLACs on a row modelled on another alias ( guessed volume,
//  pan and storage ). Die Rise's weapon locker is a locker, not a fridge door,
//  and zmb_buried.all carries Treyarch's real rows for exactly this trigger, so
//  those ship instead, renamed and otherwise untouched.
//
//  🛑 WHY THIS ONE NEEDS A COPY AND THE BANK DID NOT. The bank has Treyarch's
//  own level.custom_bank_*_vo pointers to hang audio off. The locker has no
//  hook at all: the two calls sit inside triggerweaponslockerthink()'s branches,
//  and both branches can also exit WITHOUT playing anything ( an invalid weapon,
//  a full loadout, the two DENY paths ), so a watcher on the trigger would have
//  to re-derive stock's decisions and would drift the moment one changed.
//
//  So this is stock's own two functions, copied VERBATIM out of the dump and
//  transformed mechanically rather than retyped: same-file calls qualified to
//  maps\mp\zombies\_zm_weapon_locker, and the only edits are the two
//  added playsoundtoplayer lines. The stock lines stay exactly where they were.
//
//  ⭐ THE REPLACEMENT IS ON watch(), NOT think(), AND THAT IS DELIBERATE.
//  zm_highrise.gsc:111 calls triggerweaponslockerwatch() by its qualified name,
//  so replaceFunc certainly intercepts it. think() is never called by name - it
//  is handed to register_static_unitrigger() as a ::pointer ( :90 ), and whether
//  a replaceFunc detour is seen through a stored pointer is not something this
//  project has ever measured. Replacing watch() sidesteps the question: our
//  copy registers our think() directly.
// ============================================================================

zmqol_locker_watch()
{
    unitrigger_stub = spawnstruct();
    unitrigger_stub.origin = self.origin;

    if ( isdefined( self.script_angles ) )
        unitrigger_stub.angles = self.script_angles;
    else
        unitrigger_stub.angles = self.angles;

    unitrigger_stub.script_angles = unitrigger_stub.angles;

    if ( isdefined( self.script_length ) )
        unitrigger_stub.script_length = self.script_length;
    else
        unitrigger_stub.script_length = 16;

    if ( isdefined( self.script_width ) )
        unitrigger_stub.script_width = self.script_width;
    else
        unitrigger_stub.script_width = 32;

    if ( isdefined( self.script_height ) )
        unitrigger_stub.script_height = self.script_height;
    else
        unitrigger_stub.script_height = 64;

    unitrigger_stub.origin = unitrigger_stub.origin - anglestoright( unitrigger_stub.angles ) * ( unitrigger_stub.script_length / 2 );
    unitrigger_stub.targetname = "weapon_locker";
    unitrigger_stub.cursor_hint = "HINT_NOICON";
    unitrigger_stub.script_unitrigger_type = "unitrigger_box_use";
    unitrigger_stub.clientfieldname = "weapon_locker";
    maps\mp\zombies\_zm_unitrigger::unitrigger_force_per_player_triggers( unitrigger_stub, 1 );
    unitrigger_stub.prompt_and_visibility_func = maps\mp\zombies\_zm_weapon_locker::triggerweaponslockerthinkupdateprompt;
    maps\mp\zombies\_zm_unitrigger::register_static_unitrigger( unitrigger_stub, ::zmqol_locker_think );
}

zmqol_locker_think()
{
    self.parent_player thread maps\mp\zombies\_zm_weapon_locker::triggerweaponslockerweaponchangethink( self );

    while ( true )
    {
        self waittill( "trigger", player );
        retrievingweapon = player maps\mp\zombies\_zm_weapon_locker::wl_has_stored_weapondata();

        if ( !retrievingweapon )
        {
            curweapon = player getcurrentweapon();
            curweapon = player maps\mp\zombies\_zm_weapons::switch_from_alt_weapon( curweapon );

            if ( !maps\mp\zombies\_zm_weapon_locker::triggerweaponslockerisvalidweapon( curweapon ) )
                continue;

            weapondata = player maps\mp\zombies\_zm_weapons::get_player_weapondata( player );
            player maps\mp\zombies\_zm_weapon_locker::wl_set_stored_weapondata( weapondata );
            assert( curweapon == weapondata["name"], "weapon data does not match" );
            player takeweapon( curweapon );
            primaries = player getweaponslistprimaries();

            if ( isdefined( primaries[0] ) )
                player switchtoweapon( primaries[0] );
            else
                player maps\mp\zombies\_zm_weapons::give_fallback_weapon();

            self maps\mp\zombies\_zm_weapon_locker::triggerweaponslockerisvalidweaponpromptupdate( player, player getcurrentweapon() );
            player playsoundtoplayer( "evt_fridge_locker_close", player );
            //  v2.11.15 - the mod-private twin. Stock's line above names an
            //  alias Die Rise does not have; this one is in mod.all.
            player playsoundtoplayer( "zmqol_locker_close", player );
            player thread maps\mp\zombies\_zm_audio::create_and_play_dialog( "general", "weapon_storage" );
        }
        else
        {
            curweapon = player getcurrentweapon();
            primaries = player getweaponslistprimaries();
            weapondata = player maps\mp\zombies\_zm_weapon_locker::wl_get_stored_weapondata();

            if ( isdefined( level.remap_weapon_locker_weapons ) )
                weapondata = maps\mp\zombies\_zm_weapon_locker::remap_weapon( weapondata, level.remap_weapon_locker_weapons );

            weapontogive = weapondata["name"];

            if ( !maps\mp\zombies\_zm_weapon_locker::triggerweaponslockerisvalidweapon( weapontogive ) )
            {
                player playlocalsound( level.zmb_laugh_alias );
                player maps\mp\zombies\_zm_weapon_locker::wl_clear_stored_weapondata();
                self maps\mp\zombies\_zm_weapon_locker::triggerweaponslockerisvalidweaponpromptupdate( player, player getcurrentweapon() );
                continue;
            }

            curweap_base = maps\mp\zombies\_zm_weapons::get_base_weapon_name( curweapon, 1 );
            weap_base = maps\mp\zombies\_zm_weapons::get_base_weapon_name( weapontogive, 1 );

            if ( player has_weapon_or_upgrade( weap_base ) && weap_base != curweap_base )
            {
                self sethintstring( &"ZOMBIE_WEAPON_LOCKER_DENY" );
                wait 3;
                self maps\mp\zombies\_zm_weapon_locker::triggerweaponslockerisvalidweaponpromptupdate( player, player getcurrentweapon() );
                continue;
            }

            maxweapons = get_player_weapon_limit( player );

            if ( isdefined( primaries ) && primaries.size >= maxweapons || weapontogive == curweapon )
            {
                curweapon = player maps\mp\zombies\_zm_weapons::switch_from_alt_weapon( curweapon );

                if ( !maps\mp\zombies\_zm_weapon_locker::triggerweaponslockerisvalidweapon( curweapon ) )
                {
                    self sethintstring( &"ZOMBIE_WEAPON_LOCKER_DENY" );
                    wait 3;
                    self maps\mp\zombies\_zm_weapon_locker::triggerweaponslockerisvalidweaponpromptupdate( player, player getcurrentweapon() );
                    continue;
                }

                curweapondata = player maps\mp\zombies\_zm_weapons::get_player_weapondata( player );
                player takeweapon( curweapondata["name"] );
                player maps\mp\zombies\_zm_weapons::weapondata_give( weapondata );
                player maps\mp\zombies\_zm_weapon_locker::wl_clear_stored_weapondata();
                player maps\mp\zombies\_zm_weapon_locker::wl_set_stored_weapondata( curweapondata );
                player switchtoweapon( weapondata["name"] );
                self maps\mp\zombies\_zm_weapon_locker::triggerweaponslockerisvalidweaponpromptupdate( player, player getcurrentweapon() );
            }
            else
            {
                player thread maps\mp\zombies\_zm_audio::create_and_play_dialog( "general", "wall_withdrawl" );
                player maps\mp\zombies\_zm_weapon_locker::wl_clear_stored_weapondata();
                player maps\mp\zombies\_zm_weapons::weapondata_give( weapondata );
                player switchtoweapon( weapondata["name"] );
                self maps\mp\zombies\_zm_weapon_locker::triggerweaponslockerisvalidweaponpromptupdate( player, player getcurrentweapon() );
            }

            level notify( "weapon_locker_grab" );
            player playsoundtoplayer( "evt_fridge_locker_open", player );
            player playsoundtoplayer( "zmqol_locker_open", player );
        }

        wait 0.5;
    }
}

// ============================================================================
//  zmqol_no_power_highrise_extras  -  NO POWER NEEDED's Die Rise half (v2.11.22)
// ============================================================================
//  Die Rise's switch ends with two lines the power flag knows nothing about
//  (zm_highrise.gsc:1138-1139):
//      stop_exploder( 10 );
//      exploder( 11 );
//  That pair IS the map's lit state - exploder 10 is the dark set, 11 the lit
//  one. Without it the cheat gave you working perks in a building that still
//  looked like the power was off.
//
//  🛑 GUARDED ON zmqol_no_power_turned_it_on, not on the row being on. If the
//  player had already flipped the real switch, stock has run these two and
//  running them again would re-spawn the lit set on top of itself. The root
//  function sets that variable ONLY in the branch where it actually turned the
//  power on.
//
//  exploder() / stop_exploder() are maps\mp\_utility (:93, :1048) - core, so
//  safe anywhere; the NUMBERS are what is map-specific, which is why this sits
//  in the map's own file.
// ============================================================================
//  🌟 v2.11.24 - A LOOP, BECAUSE THE ROW IS A TOGGLE NOW. The restore is the
//  same pair the other way round, and b_did is read at APPLY time: a run where
//  the player's own switch had already lit the building restores nothing, which
//  is the only way to avoid stripping the lighting off someone who earned it.
//  stop_exploder() deletes the set on the clients and any server-side looper
//  (maps\mp\_utility:1048) and does not care whether the set loops, so the pair
//  is symmetric in both directions.
zmqol_no_power_highrise_extras()
{
    level endon( "end_game" );

    for ( ;; )
    {
        if ( !( isdefined( level.zmqol_no_power_applied ) && level.zmqol_no_power_applied ) )
            level waittill( "zmqol_no_power_applied" );

        b_did = 0;

        if ( isdefined( level.zmqol_no_power_turned_it_on ) && level.zmqol_no_power_turned_it_on )
        {
            stop_exploder( 10 );
            exploder( 11 );
            b_did = 1;
            println( "[zm_qol] no_power: Die Rise lighting swapped - exploder 10 off, 11 on" );
        }
        else
        {
            println( "[zm_qol] no_power: the player's own switch lit Die Rise - exploders left alone" );
        }

        //  Guarded, not a bare waittill: a notify fired while this thread was
        //  inside its apply block above (the Origins one yields on every
        //  generator) would be missed, and the thread would park here for the
        //  rest of the match. If the row is already off, the restore runs now.
        if ( isdefined( level.zmqol_no_power_applied ) && level.zmqol_no_power_applied )
            level waittill( "zmqol_no_power_reverted" );

        if ( b_did )
        {
            stop_exploder( 11 );
            exploder( 10 );
            println( "[zm_qol] no_power: Die Rise lighting restored - exploder 11 off, 10 on" );
        }
    }
}

