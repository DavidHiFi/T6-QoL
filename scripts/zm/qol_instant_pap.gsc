// ============================================================================
//  qol_instant_pap.gsc  -  INSTANT PAP, moved out of quality_of_life.gsc
// ----------------------------------------------------------------------------
//  The INSTANT PAP trigger, its live hand-over to stock's own Pack-a-Punch, and
//  the Bonfire Sale price. It lived in quality_of_life.gsc (new_pap_trigger and
//  friends) until 2026-10-04. That file sits on its compiled-bytecode ceiling,
//  so the subsystem moved here whole and installs itself from its own init().
//
//  🛑 v2.17.x (audit A03) - THE PURCHASE IS NOW ONE UNINTERRUPTED STEP.
//  The old loop read `player.score >= cost` before `can_upgrade_weapon()`, and
//  `cost` was only assigned for an upgradable weapon. The first player to walk
//  up holding a knife-only, a perk bottle or a wonder weapon with no upgrade
//  evaluated an undefined `cost`. It also waited 0.1 s between charging the
//  player and taking the gun, and up to a second more in
//  switch_from_alt_weapon(), so a player could down, swap weapons or leave in
//  the middle of a paid upgrade. A disconnect during the 1.6 s cooldown made
//  setinvisibletoplayer( undefined ) kill the trigger thread with
//  level.qol_pap_busy still 1 and pack_machine_in_use never cleared: no
//  Pack-a-Punch for anyone, and the INSTANT PAP switch stuck.
//
//  Now:
//    1. qol_ipap_weapon() validates the player and the gun and returns the
//       base weapon (alt-fire halves resolved without a weapon switch), or
//       undefined. Nothing is priced until it passes.
//    2. Validation, the charge, the take and the give run with no wait between
//       them. GSC threads only yield at a wait, so nobody else can buy, down,
//       or disconnect in the middle of it.
//    3. The busy state is claimed before the swap and released by the same
//       thread after the cooldown, whoever is still connected. Every player
//       call in the cooldown is guarded.
//
//  Same rules stock and BO2-Reimagined apply in vending_weapon_upgrade():
//  can_buy_weapon, last stand, intermission, a grenade in hand, mid weapon
//  switch, is_weapon_or_base_included, level.custom_pap_validation (Mob's
//  afterlife), and level.pap_moving (Die Rise's elevator machine).
// ============================================================================

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;

main()
{
}

init()
{
    if ( is_true( level.qol_ipap_loaded ) )
        return;

    level.qol_ipap_loaded = 1;

    qol_ipap_create_dvar( "pap_price", 5000 );
    qol_ipap_create_dvar( "repap_price", 2000 );
    //  v1.99.26 - user request 2026-08-17: an INSTANT PAP switch on the GAME tab,
    //  ON by default because it is what the mod has always done. Read live by
    //  qol_ipap_mode_watch(), not once here.
    qol_ipap_create_dvar( "instant_pap", 1 );

    level thread qol_ipap_trigger();
}

qol_ipap_create_dvar( dvar, set )
{
    if ( getdvar( dvar ) == "" )
        setdvar( dvar, set );
}

qol_ipap_setup_attachments()
{
    flag_wait( "initial_blackscreen_passed" );

    if ( !isdefined( level.zombie_weapons ) )
        return;

    keys = getarraykeys( level.zombie_weapons );

    for ( i = 0; i < keys.size; i++ )
    {
        w = level.zombie_weapons[keys[i]];
        // Skip guns without an upgrade, and guns that already have a list
        // (e.g. native Buried built them at registration).
        if ( !isdefined( w.upgrade_name ) || isdefined( w.addon_attachments ) )
            continue;

        maps\mp\zombies\_zm_weapons::add_attachments( keys[i], w.upgrade_name );
    }
}

// ============================================================================
//  qol_ipap_trigger  -  build the radius trigger, then serve it
//
//  Stock's vending_weapon_upgrade() thread stays alive and parks on its own
//  sunk trigger, so the INSTANT PAP switch can hand the machine back to it at
//  any time. Exactly one of the two triggers stands - see qol_ipap_mode_watch().
// ============================================================================
qol_ipap_trigger()
{
    level waittill( "Pack_A_Punch_on" );
    wait 2;

    if ( getdvar( "mapname" ) == "zm_nuked" )
        level waittill( "Pack_A_Punch_on" );

    perk_machine = getent( "vending_packapunch", "targetname" );

    if ( !isdefined( perk_machine ) )
        return;

    //  getentarray, so guard the index - a map with no such trigger used to
    //  crash this thread on weapon_upgrade_trigger[0].
    weapon_upgrade_trigger = getentarray( "specialty_weapupgrade", "script_noteworthy" );
    stock_trigger = undefined;

    if ( weapon_upgrade_trigger.size > 0 )
        stock_trigger = weapon_upgrade_trigger[0];

    if ( getdvar( "mapname" ) == "zm_transit" && getdvar( "g_gametype" ) == "zclassic" )
    {
        if ( !isdefined( level.buildables_built ) || !is_true( level.buildables_built["pap"] ) )
            level waittill( "pap_built" );
    }

    wait 1;

    if ( getdvar( "mapname" ) == "zm_highrise" )
    {
        //  Die Rise's machine rides an elevator. The trigger follows it, and
        //  qol_ipap_weapon() refuses while level.pap_moving is set.
        trigger = spawn( "trigger_radius", perk_machine.origin, 1, 60, 80 );
        trigger enablelinkto();
        trigger linkto( perk_machine );
    }
    else
        trigger = spawn( "trigger_radius", perk_machine.origin, 1, 35, 80 );

    //  pap_effects() places its fx from trigger.perk_machine.
    trigger.perk_machine = perk_machine;
    trigger.current_weapon = "";
    trigger setcursorhint( "HINT_NOICON" );
    trigger sethintstring( qol_ipap_hint_text( 0, qol_ipap_cost( "pap_price" ) ) );
    trigger usetriggerrequirelookat();
    perk_machine thread maps\mp\zombies\_zm_perks::activate_packapunch();

    //  Hand the machine to whichever mode the switch is in RIGHT NOW, then keep
    //  watching it. Applied before the loop so a match that starts with INSTANT
    //  PAP disabled never shows this trigger at all.
    level.qol_pap_busy = 0;
    level.qol_pap_sank_stock = 0;
    b_instant_now = getdvarintdefault( "instant_pap", 1 ) != 0;

    //  Where stock's Pack-a-Punch thread does not exist, instant mode is the
    //  only Pack-a-Punch there is - never sink this trigger.
    if ( is_true( level.qol_pap_stock_missing ) || !isdefined( stock_trigger ) )
        b_instant_now = 1;

    level qol_ipap_apply_mode( b_instant_now, trigger, stock_trigger );
    level thread qol_ipap_mode_watch( trigger, stock_trigger );

    for (;;)
    {
        trigger waittill( "trigger", player );

        //  A radius trigger fires on touch. The use key is the purchase.
        weapon = qol_ipap_weapon( player, trigger );

        if ( isdefined( weapon ) && player usebuttonpressed() && !qol_ipap_machine_in_use() )
        {
            cost = qol_ipap_weapon_cost( weapon );

            if ( player.score >= cost )
                qol_ipap_buy( player, weapon, cost, trigger );
        }

        if ( isdefined( player ) )
            qol_ipap_update_hint( trigger, player );

        wait 0.1;
    }
}

// ============================================================================
//  qol_ipap_weapon  -  the weapon this player may Pack-a-Punch now, or undefined
//
//  Synchronous on purpose: no wait, no weapon switch. Returns the BASE weapon,
//  so a player aiming down an underbarrel launcher (gl_*, sf_*, dualoptic_*) or
//  holding a later Storm PSR charge stage upgrades the gun that owns it. The
//  call goes to the mod's zmqol_get_nonalternate_weapon() through replaceFunc.
// ============================================================================
qol_ipap_weapon( player, trigger )
{
    if ( !isdefined( player ) || !isplayer( player ) || !isalive( player ) )
        return undefined;

    if ( !is_player_valid( player ) )
        return undefined;

    if ( is_true( player.intermission ) || is_true( level.intermission ) )
        return undefined;

    if ( isdefined( player.is_drinking ) && player.is_drinking > 0 )
        return undefined;

    if ( !player maps\mp\zombies\_zm_magicbox::can_buy_weapon() )
        return undefined;

    if ( player isthrowinggrenade() || player isswitchingweapons() )
        return undefined;

    //  Die Rise: the machine is between floors.
    if ( is_true( level.pap_moving ) )
        return undefined;

    if ( isdefined( level.custom_pap_validation ) )
    {
        if ( !trigger [[ level.custom_pap_validation ]]( player ) )
            return undefined;
    }

    weapon = player getcurrentweapon();

    if ( !isdefined( weapon ) || weapon == "" || weapon == "none" )
        return undefined;

    if ( weapon == "riotshield_zm" || is_placeable_mine( weapon ) || is_equipment( weapon ) )
        return undefined;

    if ( isdefined( level.revive_tool ) && weapon == level.revive_tool )
        return undefined;

    //  Stock's own rename - the Wave Gun's one-hand form packs as the dual form.
    if ( weapon == "microwavegun_zm" )
        weapon = "microwavegundw_zm";

    weapon = player maps\mp\zombies\_zm_weapons::get_nonalternate_weapon( weapon );

    if ( !isdefined( weapon ) || weapon == "none" || !player hasweapon( weapon ) )
        return undefined;

    if ( !maps\mp\zombies\_zm_weapons::can_upgrade_weapon( weapon ) )
        return undefined;

    if ( !maps\mp\zombies\_zm_weapons::is_weapon_or_base_included( weapon ) )
        return undefined;

    return weapon;
}

//  Stock's own machine, or a mode hand-over, is mid-upgrade.
qol_ipap_machine_in_use()
{
    if ( is_true( level.qol_pap_busy ) )
        return 1;

    if ( isdefined( level.flag ) && isdefined( level.flag["pack_machine_in_use"] ) && flag( "pack_machine_in_use" ) )
        return 1;

    return 0;
}

// ============================================================================
//  qol_ipap_buy  -  charge, swap and give with no wait in between
//
//  Called only with a weapon qol_ipap_weapon() returned in this same frame.
//  The cooldown at the end is the only wait, and nothing in it assumes the
//  player is still here.
// ============================================================================
qol_ipap_buy( player, weapon, cost, trigger )
{
    is_upgraded = maps\mp\zombies\_zm_weapons::is_weapon_upgraded( weapon );
    upgrade_as_attachment = is_upgraded;

    if ( !is_upgraded )
        upgrade_as_attachment = maps\mp\zombies\_zm_weapons::will_upgrade_weapon_as_attachment( weapon );

    upgrade_name = maps\mp\zombies\_zm_weapons::get_upgrade_weapon( weapon, upgrade_as_attachment );

    //  Nothing charged yet - a weapon with no real upgrade leaves the machine as
    //  it found it.
    if ( !isdefined( upgrade_name ) || upgrade_name == "" || upgrade_name == weapon )
        return;

    //  Claim the machine. qol_ipap_mode_watch() will not hand it over while
    //  this is set, and stock readers (Die Rise's elevator, Origins' generator
    //  loss, Buried's time bomb) wait on pack_machine_in_use.
    level.qol_pap_busy = 1;
    level.qol_pap_owner = player;
    trigger.pack_player = player;
    trigger.current_weapon = weapon;

    if ( isdefined( level.flag ) && isdefined( level.flag["pack_machine_in_use"] ) )
        flag_set( "pack_machine_in_use" );

    clip_ammo = player getweaponammoclip( weapon );
    stock_ammo = player getweaponammostock( weapon );
    options = player maps\mp\zombies\_zm_weapons::get_pack_a_punch_weapon_options( upgrade_name );

    player maps\mp\zombies\_zm_score::minus_to_player_score( cost, 1 );
    player takeweapon( weapon );
    player giveweapon( upgrade_name, 0, options );

    if ( is_upgraded )
    {
        new_clip_size = weaponclipsize( upgrade_name );

        if ( clip_ammo > new_clip_size )
            clip_ammo = new_clip_size;

        player setweaponammoclip( upgrade_name, clip_ammo );
        player setweaponammostock( upgrade_name, stock_ammo );
    }

    player switchtoweapon( upgrade_name );
    player thread maps\mp\zombies\_zm_audio::play_jingle_or_stinger( "mus_perks_packa_sting" );
    player pap_effects( weapon, upgrade_name, trigger.perk_machine, trigger );
    trigger playsound( "zmb_perks_packa_upgrade" );
    player playsound( "zmb_perks_packa_ready" );
    player playsound( "zmb_cha_ching" );

    //  Cooldown: the buyer alone sees the trigger for a moment, then nobody,
    //  then everyone. Guarded, because the buyer may have left.
    trigger setinvisibletoall();
    trigger setvisibletoplayer( player );
    wait 0.1;

    if ( isdefined( player ) )
        trigger setinvisibletoplayer( player );

    wait 1.5;
    qol_ipap_release( trigger );
}

qol_ipap_release( trigger )
{
    trigger setvisibletoall();
    trigger.current_weapon = "";
    trigger.pack_player = undefined;
    level.qol_pap_owner = undefined;

    if ( isdefined( level.flag ) && isdefined( level.flag["pack_machine_in_use"] ) )
        flag_clear( "pack_machine_in_use" );

    level.qol_pap_busy = 0;
}

// ============================================================================
//  Price and hint
//
//  qol_ipap_cost (was zmqol_pap_cost) - the Bonfire Sale price for this trigger.
//  Stock's discount lives in _zm_perks::vending_weapon_upgrade_cost(), which
//  only reprices STOCK's trigger. INSTANT PAP sinks that trigger, so without
//  this a default game charges 5000 during a Bonfire Sale. 1000 is stock's sale
//  price (_zm_perks.gsc:697-698); the cap never raises a price the player has
//  already lowered in the GAME tab.
// ============================================================================
qol_ipap_cost( str_dvar )
{
    n_cost = getdvarint( str_dvar );

    if ( n_cost < 0 )
        n_cost = 0;

    if ( isdefined( level.zombie_vars ) &&
         isdefined( level.zombie_vars[ "zombie_powerup_bonfire_sale_on" ] ) &&
         level.zombie_vars[ "zombie_powerup_bonfire_sale_on" ] == 1 &&
         n_cost > 1000 )
        n_cost = 1000;

    return n_cost;
}

qol_ipap_weapon_cost( weapon )
{
    if ( maps\mp\zombies\_zm_weapons::is_weapon_upgraded( weapon ) )
        return qol_ipap_cost( "repap_price" );

    return qol_ipap_cost( "pap_price" );
}

qol_ipap_hint_text( b_repack, cost )
{
    if ( b_repack )
        return "			Hold ^3&&1^7 for Repack-a-Punch [Cost: " + cost + "]";

    return "			Hold ^3&&1^7 for Pack-a-Punch [Cost: " + cost + "]";
}

//  The hint is one string for the whole trigger, written for the player who
//  touched it last - the same as before the move.
qol_ipap_update_hint( trigger, player )
{
    weapon = qol_ipap_weapon( player, trigger );

    if ( !isdefined( weapon ) )
    {
        trigger sethintstring( "" );
        return;
    }

    trigger sethintstring( qol_ipap_hint_text( maps\mp\zombies\_zm_weapons::is_weapon_upgraded( weapon ), qol_ipap_weapon_cost( weapon ) ) );
}

// ----------------------------------------------------------------------------
//  v1.99.30 - INSTANT PAP IS A LIVE SWITCH
//
//      instant_pap 1  ->  this module's radius trigger
//      instant_pap 0  ->  stock's own "specialty_weapupgrade" trigger, driven by
//                         stock's own vending_weapon_upgrade() thread
//
//  🛑 trigger_on()/trigger_off() (common_scripts\utility) move a trigger 10000
//  units down and remember `realorigin`. Stock's enable_trigger()/
//  disable_trigger() do the same move through `.disabled`. Handing over while
//  stock has its trigger sunk mid-upgrade would record the sunken origin as
//  `realorigin` and bury the trigger for the rest of the match, so the watcher
//  refuses to switch while either side is mid-upgrade.
//
//  🛑 THE MOD RAISES ONLY WHAT THE MOD SANK. level.qol_pap_sank_stock records
//  whether stock's trigger is down because of us. On TranZit CLASSIC stock
//  keeps its trigger off until the machine is BUILT.
// ----------------------------------------------------------------------------
qol_ipap_apply_mode( b_instant, qol_trigger, stock_trigger )
{
    if ( b_instant )
    {
        //  Idempotent - skips weapons that already have a list.
        level.zombiemode_reusing_pack_a_punch = 1;
        level thread qol_ipap_setup_attachments();

        if ( isdefined( stock_trigger ) && !is_true( stock_trigger.trigger_off ) )
        {
            stock_trigger trigger_off();
            level.qol_pap_sank_stock = 1;
        }

        if ( isdefined( qol_trigger ) && is_true( qol_trigger.trigger_off ) )
        {
            qol_trigger trigger_on();
            qol_trigger setvisibletoall();
        }
    }
    else
    {
        if ( isdefined( qol_trigger ) && !is_true( qol_trigger.trigger_off ) )
        {
            qol_trigger trigger_off();
            qol_trigger setinvisibletoall();
        }

        if ( isdefined( stock_trigger ) && is_true( level.qol_pap_sank_stock ) && is_true( stock_trigger.trigger_off ) )
        {
            stock_trigger trigger_on();
            level.qol_pap_sank_stock = 0;
        }
    }
}

//  State-based, not edge-based: compares the switch with what the triggers
//  actually are, so it repairs a trigger something else moved. On TranZit
//  CLASSIC stock's vending_weapon_upgrade() calls trigger_on() the moment the
//  machine is built.
qol_ipap_mode_watch( qol_trigger, stock_trigger )
{
    //  Nothing to switch to on the custom survival locations, where stock's
    //  Pack-a-Punch thread never started, or on a map with no stock trigger.
    if ( is_true( level.qol_pap_stock_missing ) || !isdefined( stock_trigger ) )
        return;

    for (;;)
    {
        wait 0.5;

        b_want = getdvarintdefault( "instant_pap", 1 ) != 0;
        b_qol_on = isdefined( qol_trigger ) && !is_true( qol_trigger.trigger_off );
        b_mismatch = 0;

        if ( b_want )
        {
            if ( !b_qol_on )
                b_mismatch = 1;

            if ( isdefined( stock_trigger ) && !is_true( stock_trigger.trigger_off ) )
                b_mismatch = 1;
        }
        else
        {
            if ( b_qol_on )
                b_mismatch = 1;

            if ( isdefined( stock_trigger ) && is_true( level.qol_pap_sank_stock ) && is_true( stock_trigger.trigger_off ) )
                b_mismatch = 1;
        }

        if ( !b_mismatch )
            continue;

        //  Never hand the machine over while a weapon is inside it.
        if ( qol_ipap_machine_in_use() )
            continue;

        if ( isdefined( stock_trigger ) && is_true( stock_trigger.disabled ) )
            continue;

        level qol_ipap_apply_mode( b_want, qol_trigger, stock_trigger );
    }
}

//  Stock's third_person_weapon_upgrade() fx placement without the floating
//  weapon model - the instant upgrade has nothing to show going in.
pap_effects( current_weapon, upgrade_weapon, perk_machine, trigger )
{
    if ( !isdefined( perk_machine ) )
        return;

    origin_offset = ( 0, 0, 35 );

    if ( isdefined( level.pap_interaction_height ) )
        origin_offset = ( 0, 0, level.pap_interaction_height );

    angles_offset = ( 0, 90, 0 );

    if ( !isdefined( perk_machine.fx_ent ) )
    {
        perk_machine.fx_ent = spawn( "script_model", perk_machine.origin + origin_offset + ( 0, 1, -34 ) );
        perk_machine.fx_ent.angles = perk_machine.angles + angles_offset;
        perk_machine.fx_ent setmodel( "tag_origin" );
        perk_machine.fx_ent linkto( perk_machine );
    }

    if ( isdefined( level._effect["packapunch_fx"] ) )
        playfxontag( level._effect["packapunch_fx"], perk_machine.fx_ent, "tag_origin" );
}
