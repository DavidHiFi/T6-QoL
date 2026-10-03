// Issue 12: native bodies with equipment slot 3 and alternate fire slot 1.
// Stock Core/maps/mp/zombies/_zm_equipment.gsc; BO2-Reimagined keeps the same equipment lifecycle.
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_audio;
#include maps\mp\zombies\_zm_buildables;
#include maps\mp\zombies\_zm_unitrigger;
#include maps\mp\zombies\_zm_laststand;
#include maps\mp\zombies\_zm_weapons;
#include maps\mp\zombies\_zm_stats;
#include maps\mp\zombies\_zm_spawner;

main()
{
    replaceFunc( maps\mp\zombies\_zm_equipment::init, ::stock_equipment_init );
    replaceFunc( maps\mp\zombies\_zm_equipment::init_equipment_upgrade, ::init_equipment_upgrade );
    replaceFunc( maps\mp\zombies\_zm_equipment::equipment_spawn_think, ::equipment_spawn_think );
    replaceFunc( maps\mp\zombies\_zm_equipment::equipment_take, ::equipment_take );
    replaceFunc( maps\mp\zombies\_zm_equipment::equipment_give, ::equipment_give );
    replaceFunc( maps\mp\zombies\_zm_equipment::equipment_onspawnretrievableweaponobject, ::equipment_onspawnretrievableweaponobject );
    replaceFunc( maps\mp\zombies\_zm_equipment::equipment_retrieve, ::equipment_retrieve );
    replaceFunc( maps\mp\zombies\_zm_equipment::equipment_drop_to_planted, ::equipment_drop_to_planted );
    replaceFunc( maps\mp\zombies\_zm_equipment::equipment_transfer, ::equipment_transfer );
    replaceFunc( maps\mp\zombies\_zm_equipment::equipment_release, ::equipment_release );
    replaceFunc( maps\mp\zombies\_zm_equipment::equipment_drop, ::equipment_drop );
    replaceFunc( maps\mp\zombies\_zm_equipment::equipment_grab, ::equipment_grab );
    replaceFunc( maps\mp\zombies\_zm_equipment::equipment_orphaned, ::equipment_orphaned );
    replaceFunc( maps\mp\zombies\_zm_equipment::equipment_to_deployed, ::equipment_to_deployed );
    replaceFunc( maps\mp\zombies\_zm_equipment::equipment_from_deployed, ::equipment_from_deployed );
    replaceFunc( maps\mp\zombies\_zm_equipment::equipment_buy, ::equipment_buy );
    replaceFunc( maps\mp\zombies\_zm_equipment::placed_equipment_think, ::placed_equipment_think );
    replaceFunc( maps\mp\zombies\_zm_equipment::placed_equipment_unitrigger_think, ::placed_equipment_unitrigger_think );
    replaceFunc( maps\mp\zombies\_zm_equipment::pickup_placed_equipment, ::pickup_placed_equipment );
    replaceFunc( maps\mp\zombies\_zm_equipment::dropped_equipment_think, ::dropped_equipment_think );
    replaceFunc( maps\mp\zombies\_zm_equipment::dropped_equipment_unitrigger_think, ::dropped_equipment_unitrigger_think );
    replaceFunc( maps\mp\zombies\_zm_equipment::pickup_dropped_equipment, ::pickup_dropped_equipment );
    replaceFunc( maps\mp\zombies\_zm_equipment::dropped_equipment_destroy, ::dropped_equipment_destroy );
    replaceFunc( maps\mp\zombies\_zm_equipment::equipment_placement_watcher, ::equipment_placement_watcher );
    replaceFunc( maps\mp\zombies\_zm_equipment::equipment_watch_placement, ::equipment_watch_placement );
    replaceFunc( maps\mp\zombies\_zm_equipment::watch_melee_swipes, ::watch_melee_swipes );
    replaceFunc( maps\mp\zombies\_zm_equipment::player_damage_equipment, ::player_damage_equipment );
    replaceFunc( maps\mp\zombies\_zm_equipment::item_damage, ::item_damage );
    replaceFunc( maps\mp\zombies\_zm_equipment::item_watch_damage, ::item_watch_damage );
    replaceFunc( maps\mp\zombies\_zm_equipment::item_watch_explosions, ::item_watch_explosions );
    replaceFunc( maps\mp\zombies\_zm_equipment::item_attract_zombies, ::item_attract_zombies );
    replaceFunc( maps\mp\zombies\_zm_equipment::attack_item, ::attack_item );
    replaceFunc( maps\mp\zombies\_zm_equipment::window_notetracks, ::window_notetracks );
}

init()
{
    onplayerconnect_callback( ::watch_spawn_slots );
}

watch_spawn_slots()
{
    self endon( "disconnect" );
    for ( ;; )
    {
        self waittill( "spawned_player" );
        waittillframeend;
        self setactionslot( 1, "altMode" );
        equipment = self get_player_equipment();
        if ( isdefined( equipment ) && self hasweapon( equipment ) )
            self setactionslot( 3, "weapon", equipment );
        else
            self setactionslot( 3, "" );
    }
}

stock_equipment_init()
{
    init_equipment_upgrade();
    onplayerconnect_callback( ::equipment_placement_watcher );
    level._equipment_disappear_fx = loadfx( "maps/zombie/fx_zmb_tranzit_electrap_explo" );

    if ( !( isdefined( level.disable_fx_zmb_tranzit_shield_explo ) && level.disable_fx_zmb_tranzit_shield_explo ) )
        level._riotshield_dissapear_fx = loadfx( "maps/zombie/fx_zmb_tranzit_shield_explo" );

    level.placeable_equipment_destroy_fn = [];

    if ( !( isdefined( level._no_equipment_activated_clientfield ) && level._no_equipment_activated_clientfield ) )
        registerclientfield( "scriptmover", "equipment_activated", 12000, 4, "int" );
}

init_equipment_upgrade()
{
    equipment_spawns = [];
    equipment_spawns = getentarray( "zombie_equipment_upgrade", "targetname" );

    for ( i = 0; i < equipment_spawns.size; i++ )
    {
        hint_string = maps\mp\zombies\_zm_equipment::get_equipment_hint( equipment_spawns[i].zombie_equipment_upgrade );
        equipment_spawns[i] sethintstring( hint_string );
        equipment_spawns[i] setcursorhint( "HINT_NOICON" );
        equipment_spawns[i] usetriggerrequirelookat();
        equipment_spawns[i] maps\mp\zombies\_zm_equipment::add_to_equipment_trigger_list( equipment_spawns[i].zombie_equipment_upgrade );
        equipment_spawns[i] thread equipment_spawn_think();
    }
}

equipment_spawn_think()
{
    for (;;)
    {
        self waittill( "trigger", player );

        if ( player in_revive_trigger() || player.is_drinking > 0 )
        {
            wait 0.1;
            continue;
        }

        if ( maps\mp\zombies\_zm_equipment::is_limited_equipment( self.zombie_equipment_upgrade ) )
        {
            player maps\mp\zombies\_zm_equipment::setup_limited_equipment( self.zombie_equipment_upgrade );

            if ( isdefined( level.hacker_tool_positions ) )
            {
                new_pos = random( level.hacker_tool_positions );
                self.origin = new_pos.trigger_org;
                model = getent( self.target, "targetname" );
                model.origin = new_pos.model_org;
                model.angles = new_pos.model_ang;
            }
        }

        player equipment_give( self.zombie_equipment_upgrade );
    }
}

equipment_take( equipment )
{
    if ( !isdefined( equipment ) )
        equipment = self get_player_equipment();

    if ( !isdefined( equipment ) )
        return;

    if ( !self has_player_equipment( equipment ) )
        return;

    current = 0;
    current_weapon = 0;

    if ( isdefined( self get_player_equipment() ) && equipment == self get_player_equipment() )
        current = 1;

    if ( equipment == self getcurrentweapon() )
        current_weapon = 1;



    if ( isdefined( self.current_equipment_active[equipment] ) && self.current_equipment_active[equipment] )
    {
        self.current_equipment_active[equipment] = 0;
        self notify( equipment + "_deactivate" );
    }

    self notify( equipment + "_taken" );
    self takeweapon( equipment );

    if ( !maps\mp\zombies\_zm_equipment::is_limited_equipment( equipment ) || maps\mp\zombies\_zm_equipment::is_limited_equipment( equipment ) && !maps\mp\zombies\_zm_equipment::limited_equipment_in_use( equipment ) )
        self maps\mp\zombies\_zm_equipment::set_equipment_invisibility_to_player( equipment, 0 );

    if ( current )
    {
        self set_player_equipment( undefined );
        self setactionslot( 3, "" );
    }
    else
        arrayremovevalue( self.deployed_equipment, equipment );

    if ( current_weapon )
    {
        primaryweapons = self getweaponslistprimaries();

        if ( isdefined( primaryweapons ) && primaryweapons.size > 0 )
            self switchtoweapon( primaryweapons[0] );
    }
}

equipment_give( equipment )
{
    if ( !isdefined( equipment ) )
        return;

    if ( equipment == "jetgun_zm" && weaponinventorytype( equipment ) == "primary" && isdefined( level.zmqol_jetgun_primary_give ) )
    {
        self [[ level.zmqol_jetgun_primary_give ]]();
        return;
    }

    if ( !isdefined( level.zombie_equipment[equipment] ) )
        return;

    if ( self has_player_equipment( equipment ) )
        return;


    curr_weapon = self getcurrentweapon();
    curr_weapon_was_curr_equipment = self is_player_equipment( curr_weapon );
    self equipment_take();
    self set_player_equipment( equipment );
    self giveweapon( equipment );
    self setweaponammoclip( equipment, 1 );
    self thread maps\mp\zombies\_zm_equipment::show_equipment_hint( equipment );
    self notify( equipment + "_given" );
    self maps\mp\zombies\_zm_equipment::set_equipment_invisibility_to_player( equipment, 1 );
    self setactionslot( 3, "weapon", equipment );

    if ( isdefined( level.zombie_equipment[equipment].watcher_thread ) )
        self thread [[ level.zombie_equipment[equipment].watcher_thread ]]();

    self thread maps\mp\zombies\_zm_equipment::equipment_slot_watcher( equipment );
    self maps\mp\zombies\_zm_audio::create_and_play_dialog( "weapon_pickup", level.zombie_equipment[equipment].vox );
}

equipment_onspawnretrievableweaponobject( watcher, player )
{
    self.plant_parent = self;
    iswallmount = isdefined( level.placeable_equipment_type[self.name] ) && level.placeable_equipment_type[self.name] == "wallmount";

    if ( !isdefined( player.turret_placement ) || !player.turret_placement["result"] )
    {
        if ( iswallmount || !getdvarint( #"tu11_zombie_turret_placement_ignores_bodies" ) )
        {
            self waittill( "stationary" );
            waittillframeend;

            if ( iswallmount )
            {
                if ( isdefined( player.planted_wallmount_on_a_zombie ) && player.planted_wallmount_on_a_zombie )
                {
                    equip_name = self.name;
                    thread maps\mp\zombies\_zm_equipment::equipment_disappear_fx( self.origin, undefined, self.angles );
                    self delete();

                    if ( player hasweapon( equip_name ) )
                        player setweaponammoclip( equip_name, 1 );

                    player.planted_wallmount_on_a_zombie = undefined;
                    return;
                }
            }
        }
        else
        {
            self.plant_parent = player;
            self.origin = player.origin;
            self.angles = player.angles;
            wait_network_frame();
        }
    }

    equipment = watcher.name + "_zm";


    if ( isdefined( player.current_equipment ) && player.current_equipment == equipment )
        player equipment_to_deployed( equipment );

    if ( isdefined( level.zombie_equipment[equipment].place_fn ) )
    {
        if ( isdefined( player.turret_placement ) && player.turret_placement["result"] )
        {
            plant_origin = player.turret_placement["origin"];
            plant_angles = player.turret_placement["angles"];
        }
        else if ( isdefined( level.placeable_equipment_type[self.name] ) && level.placeable_equipment_type[self.name] == "wallmount" )
        {
            plant_origin = self.origin;
            plant_angles = self.angles;
        }
        else
        {
            plant_origin = self.origin;
            plant_angles = self.angles;
        }

        if ( isdefined( level.check_force_deploy_origin ) )
        {
            if ( player [[ level.check_force_deploy_origin ]]( self, plant_origin, plant_angles ) )
            {
                plant_origin = player.origin;
                plant_angles = player.angles;
                self.plant_parent = player;
            }
        }
        else if ( isdefined( level.check_force_deploy_z ) )
        {
            if ( player [[ level.check_force_deploy_z ]]( self, plant_origin, plant_angles ) )
                plant_origin = ( plant_origin[0], plant_origin[1], player.origin[2] + 10 );
        }

        if ( isdefined( iswallmount ) && iswallmount )
            self ghost();

        replacement = player [[ level.zombie_equipment[equipment].place_fn ]]( plant_origin, plant_angles );

        if ( isdefined( replacement ) )
        {
            replacement.owner = player;
            replacement.original_owner = player;
            replacement.name = self.name;
            player notify( "equipment_placed", replacement, self.name );

            if ( isdefined( level.equipment_planted ) )
                player [[ level.equipment_planted ]]( replacement, equipment, self.plant_parent );

            player maps\mp\zombies\_zm_buildables::track_buildables_planted( self );
        }

        if ( isdefined( self ) )
            self delete();
    }
}

equipment_retrieve( player )
{
    if ( isdefined( self ) )
    {
        self stoploopsound();
        original_owner = self.original_owner;
        weaponname = self.name;

        if ( !isdefined( original_owner ) )
        {
            player equipment_give( weaponname );
            self.owner = player;
        }
        else
        {
            if ( player != original_owner )
            {
                equipment_transfer( weaponname, original_owner, player );
                self.owner = player;
            }

            player equipment_from_deployed( weaponname );
        }

        if ( isdefined( self.requires_pickup ) && self.requires_pickup )
        {
            if ( isdefined( level.zombie_equipment[weaponname].pickup_fn ) )
            {
                self.owner = player;

                if ( isdefined( self.damage ) )
                    player maps\mp\zombies\_zm_equipment::player_set_equipment_damage( weaponname, self.damage );

                player [[ level.zombie_equipment[weaponname].pickup_fn ]]( self );
            }
        }

        self.playdialog = 0;
        weaponname = self.name;
        self delete();

        if ( !player hasweapon( weaponname ) )
        {
            player giveweapon( weaponname );
            clip_ammo = player getweaponammoclip( weaponname );
            clip_max_ammo = weaponclipsize( weaponname );

            if ( clip_ammo < clip_max_ammo )
                clip_ammo++;

            player setweaponammoclip( weaponname, clip_ammo );
        }

        player maps\mp\zombies\_zm_buildables::track_planted_buildables_pickedup( weaponname );
    }
}

equipment_drop_to_planted( equipment, player )
{


    if ( isdefined( player.current_equipment ) && player.current_equipment == equipment )
        player equipment_to_deployed( equipment );

    if ( isdefined( level.zombie_equipment[equipment].place_fn ) )
    {
        replacement = player [[ level.zombie_equipment[equipment].place_fn ]]( player.origin, player.angles );

        if ( isdefined( replacement ) )
        {
            replacement.owner = player;
            replacement.original_owner = player;
            replacement.name = equipment;

            if ( isdefined( level.equipment_planted ) )
                player [[ level.equipment_planted ]]( replacement, equipment, player );

            player notify( "equipment_placed", replacement, equipment );
            player maps\mp\zombies\_zm_buildables::track_buildables_planted( replacement );
        }
    }
}

equipment_transfer( weaponname, fromplayer, toplayer )
{
    if ( maps\mp\zombies\_zm_equipment::is_limited_equipment( weaponname ) )
    {

        toplayer equipment_orphaned( weaponname );
        wait 0.05;
        assert( !toplayer has_player_equipment( weaponname ) );
        assert( fromplayer has_player_equipment( weaponname ) );
        toplayer equipment_give( weaponname );
        toplayer equipment_to_deployed( weaponname );

        if ( isdefined( level.zombie_equipment[weaponname].transfer_fn ) )
            [[ level.zombie_equipment[weaponname].transfer_fn ]]( fromplayer, toplayer );

        fromplayer equipment_release( weaponname );
        assert( toplayer has_player_equipment( weaponname ) );
        assert( !fromplayer has_player_equipment( weaponname ) );
        equipment_damage = 0;
        toplayer maps\mp\zombies\_zm_equipment::player_set_equipment_damage( weaponname, fromplayer maps\mp\zombies\_zm_equipment::player_get_equipment_damage( weaponname ) );
        fromplayer maps\mp\zombies\_zm_equipment::player_set_equipment_damage( equipment_damage );
    }
    else
    {

        toplayer equipment_give( weaponname );

        if ( isdefined( toplayer.current_equipment ) && toplayer.current_equipment == weaponname )
            toplayer equipment_to_deployed( weaponname );

        if ( isdefined( level.zombie_equipment[weaponname].transfer_fn ) )
            [[ level.zombie_equipment[weaponname].transfer_fn ]]( fromplayer, toplayer );

        equipment_damage = toplayer maps\mp\zombies\_zm_equipment::player_get_equipment_damage( weaponname );
        toplayer maps\mp\zombies\_zm_equipment::player_set_equipment_damage( weaponname, fromplayer maps\mp\zombies\_zm_equipment::player_get_equipment_damage( weaponname ) );
        fromplayer maps\mp\zombies\_zm_equipment::player_set_equipment_damage( weaponname, equipment_damage );
    }
}

equipment_release( equipment )
{

    self equipment_take( equipment );
}

equipment_drop( equipment )
{
    if ( isdefined( level.zombie_equipment[equipment].place_fn ) )
    {
        equipment_drop_to_planted( equipment, self );

    }
    else if ( isdefined( level.zombie_equipment[equipment].drop_fn ) )
    {
        if ( isdefined( self.current_equipment ) && self.current_equipment == equipment )
            self equipment_to_deployed( equipment );

        item = self [[ level.zombie_equipment[equipment].drop_fn ]]();

        if ( isdefined( item ) )
        {
            if ( isdefined( level.equipment_planted ) )
                self [[ level.equipment_planted ]]( item, equipment, self );

            item.owner = undefined;
            item.damage = self maps\mp\zombies\_zm_equipment::player_get_equipment_damage( equipment );
        }


    }
    else
        self equipment_take();

    self notify( "equipment_dropped", equipment );
}

equipment_grab( equipment, item )
{

    self equipment_give( equipment );

    if ( isdefined( level.zombie_equipment[equipment].pickup_fn ) )
    {
        item.owner = self;
        self maps\mp\zombies\_zm_equipment::player_set_equipment_damage( equipment, item.damage );
        self [[ level.zombie_equipment[equipment].pickup_fn ]]( item );
    }
}

equipment_orphaned( equipment )
{

    self equipment_take( equipment );
}

equipment_to_deployed( equipment )
{


    if ( !isdefined( self.deployed_equipment ) )
        self.deployed_equipment = [];

    assert( self.current_equipment == equipment );
    self.deployed_equipment[self.deployed_equipment.size] = equipment;
    self.current_equipment = undefined;

    if ( !isdefined( level.riotshield_name ) || equipment != level.riotshield_name )
        self takeweapon( equipment );

    self setactionslot( 3, "" );
}

equipment_from_deployed( equipment )
{
    if ( !isdefined( equipment ) )
        equipment = "none";



    if ( isdefined( self.current_equipment ) && equipment != self.current_equipment )
        self equipment_drop( self.current_equipment );

    assert( self has_deployed_equipment( equipment ) );
    self.current_equipment = equipment;

    if ( isdefined( level.riotshield_name ) && equipment != level.riotshield_name )
        self giveweapon( equipment );

    if ( self hasweapon( equipment ) )
        self setweaponammoclip( equipment, 1 );

    self setactionslot( 3, "weapon", equipment );
    arrayremovevalue( self.deployed_equipment, equipment );
    self notify( equipment + "_pickup" );
}

equipment_buy( equipment )
{


    if ( isdefined( self.current_equipment ) && equipment != self.current_equipment )
        self equipment_drop( self.current_equipment );

    if ( ( equipment == "riotshield_zm" || equipment == "alcatraz_shield_zm" ) && isdefined( self.player_shield_reset_health ) )
        self [[ self.player_shield_reset_health ]]();
    else
        self maps\mp\zombies\_zm_equipment::player_set_equipment_damage( equipment, 0 );

    self equipment_give( equipment );
}

placed_equipment_think( model, equipname, origin, angles, tradius, toffset )
{
    pickupmodel = spawn( "script_model", origin );

    if ( isdefined( angles ) )
        pickupmodel.angles = angles;

    pickupmodel setmodel( model );

    if ( isdefined( level.equipment_safe_to_drop ) )
    {
        if ( !self [[ level.equipment_safe_to_drop ]]( pickupmodel ) )
        {
            maps\mp\zombies\_zm_equipment::equipment_disappear_fx( pickupmodel.origin, undefined, pickupmodel.angles );
            pickupmodel delete();
            self equipment_take( equipname );
            return undefined;
        }
    }

    watchername = getsubstr( equipname, 0, equipname.size - 3 );

    if ( isdefined( level.retrievehints[watchername] ) )
        hint = level.retrievehints[watchername].hint;
    else
        hint = &"MP_GENERIC_PICKUP";

    icon = maps\mp\zombies\_zm_equipment::get_equipment_icon( equipname );

    if ( !isdefined( tradius ) )
        tradius = 32;

    torigin = origin;

    if ( isdefined( toffset ) )
    {
        tforward = anglestoforward( angles );
        torigin = torigin + toffset * tforward;
    }

    tup = anglestoup( angles );
    eq_unitrigger_offset = 12 * tup;
    pickupmodel.stub = maps\mp\zombies\_zm_equipment::generate_equipment_unitrigger( "trigger_radius_use", torigin + eq_unitrigger_offset, angles, 0, tradius, 64, hint, equipname, ::placed_equipment_unitrigger_think, isdefined( pickupmodel.canmove ) && pickupmodel.canmove );
    pickupmodel.stub.model = pickupmodel;
    pickupmodel.stub.equipname = equipname;
    pickupmodel.equipname = equipname;
    pickupmodel thread item_attract_zombies();
    pickupmodel thread item_watch_explosions();

    if ( maps\mp\zombies\_zm_equipment::is_limited_equipment( equipname ) )
    {
        if ( !isdefined( level.dropped_equipment ) )
            level.dropped_equipment = [];

        if ( isdefined( level.dropped_equipment[equipname] ) && isdefined( level.dropped_equipment[equipname].model ) )
            level.dropped_equipment[equipname].model dropped_equipment_destroy( 1 );

        level.dropped_equipment[equipname] = pickupmodel.stub;
    }

    maps\mp\zombies\_zm_equipment::destructible_equipment_list_add( pickupmodel );
    return pickupmodel;
}

placed_equipment_unitrigger_think()
{
    self endon( "kill_trigger" );
    self thread maps\mp\zombies\_zm_equipment::watch_player_visibility( self.stub.equipname );

    while ( true )
    {
        self waittill( "trigger", player );

        if ( !player maps\mp\zombies\_zm_equipment::can_pick_up_equipment( self.stub.equipname, self ) )
            continue;

        self thread pickup_placed_equipment( player );
        return;
    }
}

pickup_placed_equipment( player )
{
    assert( !( isdefined( player.pickup_equipment ) && player.pickup_equipment ) );
    player.pickup_equipment = 1;
    stub = self.stub;

    if ( isdefined( player.current_equipment ) && stub.equipname != player.current_equipment )
        player equipment_drop( player.current_equipment );

    if ( maps\mp\zombies\_zm_equipment::is_limited_equipment( stub.equipname ) )
    {
        if ( isdefined( level.dropped_equipment ) && isdefined( level.dropped_equipment[stub.equipname] ) && level.dropped_equipment[stub.equipname] == stub )
            level.dropped_equipment[stub.equipname] = undefined;
    }

    if ( isdefined( stub.model ) )
        stub.model equipment_retrieve( player );

    thread maps\mp\zombies\_zm_unitrigger::unregister_unitrigger( stub );
    wait 3;
    player.pickup_equipment = 0;
}

dropped_equipment_think( model, equipname, origin, angles, tradius, toffset )
{
    pickupmodel = spawn( "script_model", origin );

    if ( isdefined( angles ) )
        pickupmodel.angles = angles;

    pickupmodel setmodel( model );

    if ( isdefined( level.equipment_safe_to_drop ) )
    {
        if ( !self [[ level.equipment_safe_to_drop ]]( pickupmodel ) )
        {
            maps\mp\zombies\_zm_equipment::equipment_disappear_fx( pickupmodel.origin, undefined, pickupmodel.angles );
            pickupmodel delete();
            self equipment_take( equipname );
            return;
        }
    }

    watchername = getsubstr( equipname, 0, equipname.size - 3 );

    if ( isdefined( level.retrievehints[watchername] ) )
        hint = level.retrievehints[watchername].hint;
    else
        hint = &"MP_GENERIC_PICKUP";

    icon = maps\mp\zombies\_zm_equipment::get_equipment_icon( equipname );

    if ( !isdefined( tradius ) )
        tradius = 32;

    torigin = origin;

    if ( isdefined( toffset ) )
    {
        offset = 64;
        tforward = anglestoforward( angles );
        torigin = torigin + toffset * tforward + vectorscale( ( 0, 0, 1 ), 8.0 );
    }

    pickupmodel.stub = maps\mp\zombies\_zm_equipment::generate_equipment_unitrigger( "trigger_radius_use", torigin, angles, 0, tradius, 64, hint, equipname, ::dropped_equipment_unitrigger_think, isdefined( pickupmodel.canmove ) && pickupmodel.canmove );
    pickupmodel.stub.model = pickupmodel;
    pickupmodel.stub.equipname = equipname;
    pickupmodel.equipname = equipname;

    if ( isdefined( level.equipment_planted ) )
        self [[ level.equipment_planted ]]( pickupmodel, equipname, self );

    if ( !isdefined( level.dropped_equipment ) )
        level.dropped_equipment = [];

    if ( isdefined( level.dropped_equipment[equipname] ) )
        level.dropped_equipment[equipname].model dropped_equipment_destroy( 1 );

    level.dropped_equipment[equipname] = pickupmodel.stub;
    maps\mp\zombies\_zm_equipment::destructible_equipment_list_add( pickupmodel );
    pickupmodel thread item_attract_zombies();
    return pickupmodel;
}

dropped_equipment_unitrigger_think()
{
    self endon( "kill_trigger" );
    self thread maps\mp\zombies\_zm_equipment::watch_player_visibility( self.stub.equipname );

    while ( true )
    {
        self waittill( "trigger", player );

        if ( !player maps\mp\zombies\_zm_equipment::can_pick_up_equipment( self.stub.equipname, self ) )
            continue;

        self thread pickup_dropped_equipment( player );
        return;
    }
}

pickup_dropped_equipment( player )
{
    player.pickup_equipment = 1;
    stub = self.stub;

    if ( isdefined( player.current_equipment ) && stub.equipname != player.current_equipment )
        player equipment_drop( player.current_equipment );

    player equipment_grab( stub.equipname, stub.model );
    stub.model dropped_equipment_destroy();
    wait 3;
    player.pickup_equipment = 0;
}

dropped_equipment_destroy( gusto )
{
    stub = self.stub;

    if ( isdefined( gusto ) && gusto )
        maps\mp\zombies\_zm_equipment::equipment_disappear_fx( self.origin, undefined, self.angles );

    if ( isdefined( level.dropped_equipment ) )
        level.dropped_equipment[stub.equipname] = undefined;

    if ( isdefined( stub.model ) )
        stub.model delete();

    if ( isdefined( self.original_owner ) && ( maps\mp\zombies\_zm_equipment::is_limited_equipment( stub.equipname ) || maps\mp\zombies\_zm_weapons::is_weapon_included( stub.equipname ) ) )
        self.original_owner equipment_take( stub.equipname );

    thread maps\mp\zombies\_zm_unitrigger::unregister_unitrigger( stub );
}

equipment_placement_watcher()
{
    self endon( "death_or_disconnect" );

    for (;;)
    {
        self waittill( "weapon_change", weapon );

        if ( self.sessionstate != "spectator" && maps\mp\zombies\_zm_equipment::is_placeable_equipment( weapon ) )
            self thread equipment_watch_placement( weapon );
    }
}

equipment_watch_placement( equipment )
{
    self.turret_placement = undefined;
    carry_offset = vectorscale( ( 1, 0, 0 ), 22.0 );
    carry_angles = ( 0, 0, 0 );
    placeturret = spawnturret( "auto_turret", self.origin, equipment + "_turret" );
    placeturret.angles = self.angles;
    placeturret setmodel( level.placeable_equipment[equipment] );
    placeturret setturretcarried( 1 );
    placeturret setturretowner( self );

    if ( isdefined( level.placeable_equipment_type[equipment] ) )
        placeturret setturrettype( level.placeable_equipment_type[equipment] );

    self carryturret( placeturret, carry_offset, carry_angles );

    if ( isdefined( level.use_swipe_protection ) )
        self thread watch_melee_swipes( equipment, placeturret );

    self notify( "create_equipment_turret", equipment, placeturret );
    ended = self waittill_any_return( "weapon_change", "grenade_fire", "death_or_disconnect" );

    if ( !( isdefined( level.use_legacy_equipment_placement ) && level.use_legacy_equipment_placement ) )
        self.turret_placement = self canplayerplaceturret( placeturret );

    if ( ended == "weapon_change" )
    {
        self.turret_placement = undefined;

        if ( self hasweapon( equipment ) )
            self setweaponammoclip( equipment, 1 );
    }

    self notify( "destroy_equipment_turret", equipment, placeturret );
    self stopcarryturret( placeturret );
    placeturret setturretcarried( 0 );
    placeturret delete();
}

watch_melee_swipes( equipment, turret )
{
    self endon( "weapon_change" );
    self endon( "grenade_fire" );
    self endon( "death" );
    self endon( "disconnect" );

    while ( true )
    {
        self waittill( "melee_swipe", zombie );

        if ( distancesquared( zombie.origin, self.origin ) > zombie.meleeattackdist * zombie.meleeattackdist )
            continue;

        tpos = turret.origin;
        tangles = turret.angles;
        self player_damage_equipment( equipment, 200, zombie.origin );

        if ( self.equipment_damage[equipment] >= 1500 )
        {
            thread maps\mp\zombies\_zm_equipment::equipment_disappear_fx( tpos, undefined, tangles );
            primaryweapons = self getweaponslistprimaries();

            if ( isdefined( primaryweapons[0] ) )
                self switchtoweapon( primaryweapons[0] );

            if ( isalive( self ) )
                self playlocalsound( level.zmb_laugh_alias );

            self maps\mp\zombies\_zm_stats::increment_client_stat( "cheat_total", 0 );
            self equipment_release( equipment );
            return;
        }
    }
}

player_damage_equipment( equipment, damage, origin )
{
    if ( !isdefined( self.equipment_damage ) )
        self.equipment_damage = [];

    if ( !isdefined( self.equipment_damage[equipment] ) )
        self.equipment_damage[equipment] = 0;

    self.equipment_damage[equipment] = self.equipment_damage[equipment] + damage;

    if ( self.equipment_damage[equipment] > 1500 )
    {
        if ( isdefined( level.placeable_equipment_destroy_fn[equipment] ) )
            self [[ level.placeable_equipment_destroy_fn[equipment] ]]();
        else
            maps\mp\zombies\_zm_equipment::equipment_disappear_fx( origin );

        self equipment_release( equipment );
    }
}

item_damage( damage )
{
    if ( isdefined( self.isriotshield ) && self.isriotshield )
    {
        if ( isdefined( level.riotshield_damage_callback ) && isdefined( self.owner ) )
            self.owner [[ level.riotshield_damage_callback ]]( damage, 0 );
        else if ( isdefined( level.deployed_riotshield_damage_callback ) )
            self [[ level.deployed_riotshield_damage_callback ]]( damage );
    }
    else if ( isdefined( self.owner ) )
        self.owner player_damage_equipment( self.equipname, damage, self.origin );
    else
    {
        if ( !isdefined( self.damage ) )
            self.damage = 0;

        self.damage = self.damage + damage;

        if ( self.damage > 1500 )
            self thread dropped_equipment_destroy( 1 );
    }
}

item_watch_damage()
{
    self endon( "death" );
    self setcandamage( 1 );
    self.health = 1500;

    while ( true )
    {
        self waittill( "damage", amount );
        self item_damage( amount );
    }
}

item_watch_explosions()
{
    self endon( "death" );

    while ( true )
    {
        level waittill( "grenade_exploded", position, radius, idamage, odamage );
        wait( randomfloatrange( 0.05, 0.3 ) );
        distsqrd = distancesquared( self.origin, position );

        if ( distsqrd < radius * radius )
        {
            dist = sqrt( distsqrd );
            dist = dist / radius;
            damage = odamage + ( idamage - odamage ) * ( 1 - dist );
            self item_damage( damage * 5 );
        }
    }
}

item_attract_zombies()
{
    self endon( "death" );
    self notify( "stop_attracting_zombies" );
    self endon( "stop_attracting_zombies" );


    if ( maps\mp\zombies\_zm_equipment::is_equipment_ignored( self.equipname ) )
        return;

    while ( true )
    {
        if ( isdefined( level.vert_equipment_attack_range ) )
            vdistmax = level.vert_equipment_attack_range;
        else
            vdistmax = 36;

        if ( isdefined( level.max_equipment_attack_range ) )
            distmax = level.max_equipment_attack_range * level.max_equipment_attack_range;
        else
            distmax = 4096;

        if ( isdefined( level.min_equipment_attack_range ) )
            distmin = level.min_equipment_attack_range * level.min_equipment_attack_range;
        else
            distmin = 2025;

        ai = getaiarray( level.zombie_team );

        for ( i = 0; i < ai.size; i++ )
        {
            if ( !isdefined( ai[i] ) )
                continue;

            if ( isdefined( ai[i].ignore_equipment ) && ai[i].ignore_equipment )
                continue;

            if ( isdefined( level.ignore_equipment ) )
            {
                if ( self [[ level.ignore_equipment ]]( ai[i] ) )
                    continue;
            }

            if ( isdefined( ai[i].is_inert ) && ai[i].is_inert )
                continue;

            if ( isdefined( ai[i].is_traversing ) && ai[i].is_traversing )
                continue;

            vdist = abs( ai[i].origin[2] - self.origin[2] );
            distsqrd = distance2dsquared( ai[i].origin, self.origin );

            if ( isdefined( self.equipname ) && ( self.equipname == "riotshield_zm" || self.equipname == "alcatraz_shield_zm" ) )
                vdistmax = 108;

            should_attack = 0;

            if ( isdefined( level.should_attack_equipment ) )
                should_attack = self [[ level.should_attack_equipment ]]( distsqrd );

            if ( distsqrd < distmax && distsqrd > distmin && vdist < vdistmax || should_attack )
            {
                if ( !( isdefined( ai[i].isscreecher ) && ai[i].isscreecher ) && !ai[i] is_quad() && !ai[i] is_leaper() )
                {
                    ai[i] thread attack_item( self );
                    maps\mp\zombies\_zm_equipment::item_choke();
                }
            }

            maps\mp\zombies\_zm_equipment::item_choke();
        }

        wait 0.1;
    }
}

attack_item( item )
{
    self endon( "death" );
    item endon( "death" );
    self endon( "start_inert" );

    if ( isdefined( self.doing_equipment_attack ) && self.doing_equipment_attack )
        return 0;

    if ( isdefined( self.not_interruptable ) && self.not_interruptable )
        return 0;

    self thread maps\mp\zombies\_zm_equipment::attack_item_stop( item );
    self thread maps\mp\zombies\_zm_equipment::attack_item_interrupt( item );

    if ( getdvar( #"zombie_equipment_attack_freq" ) == "" )
        setdvar( "zombie_equipment_attack_freq", "15" );

    freq = getdvarint( #"zombie_equipment_attack_freq" );
    self.doing_equipment_attack = 1;
    self maps\mp\zombies\_zm_spawner::zombie_history( "doing equipment attack 1 - " + gettime() );
    self.item = item;

    if ( !isdefined( self ) || !isalive( self ) )
        return;

    if ( isdefined( item.zombie_attack_callback ) )
        item [[ item.zombie_attack_callback ]]( self );

    self thread maps\mp\zombies\_zm_audio::do_zombies_playvocals( "attack", self.animname );

    if ( isdefined( level.attack_item ) )
        self [[ level.attack_item ]]();

    melee_anim = "zm_window_melee";

    if ( !self.has_legs )
    {
        melee_anim = "zm_walk_melee_crawl";

        if ( self.a.gib_ref == "no_legs" )
            melee_anim = "zm_stumpy_melee";
        else if ( self.zombie_move_speed == "run" || self.zombie_move_speed == "sprint" )
            melee_anim = "zm_run_melee_crawl";
    }

    self orientmode( "face point", item.origin );
    self animscripted( self.origin, flat_angle( vectortoangles( item.origin - self.origin ) ), melee_anim );
    self notify( "item_attack" );

    if ( isdefined( self.custom_item_dmg ) )
        item thread item_damage( self.custom_item_dmg );
    else
        item thread item_damage( 100 );

    item playsound( "fly_riotshield_zm_impact_flesh" );
    wait( randomint( 100 ) / 100.0 );
    self.doing_equipment_attack = 0;
    self maps\mp\zombies\_zm_spawner::zombie_history( "doing equipment attack 0 from wait - " + gettime() );
    self orientmode( "face default" );
}

window_notetracks( msg, equipment )
{
    self endon( "death" );
    equipment endon( "death" );

    while ( self.doing_equipment_attack )
    {
        self waittill( msg, notetrack );

        if ( notetrack == "end" )
            return;

        if ( notetrack == "fire" )
            equipment item_damage( 100 );
    }
}
