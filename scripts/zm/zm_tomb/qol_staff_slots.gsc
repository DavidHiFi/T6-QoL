// Issue 12: native bodies with equipment slot 3 and alternate fire slot 1.
// Stock Maps/Origins/maps/mp/zm_tomb_utility.gsc; BO2-Reimagined keeps the same equipment lifecycle.
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_net;
#include maps\mp\zombies\_zm_spawner;
#include maps\mp\zombies\_zm_craftables;
#include maps\mp\zombies\_zm_equipment;
#include maps\mp\zm_tomb_teleporter;
#include maps\mp\zm_tomb_vo;
#include maps\mp\zombies\_zm_ai_basic;
#include maps\mp\animscripts\zm_shared;
#include maps\mp\zombies\_zm_unitrigger;
#include maps\mp\zombies\_zm_zonemgr;
#include maps\mp\zm_tomb_chamber;
#include maps\mp\zombies\_zm_challenges;
#include maps\mp\zm_tomb_challenges;
#include maps\mp\zm_tomb_tank;
#include maps\mp\zm_tomb_craftables;

main()
{
    replaceFunc( maps\mp\zm_tomb_utility::watch_staff_usage, ::watch_staff_usage );
    replaceFunc( maps\mp\zm_tomb_utility::update_staff_accessories, ::update_staff_accessories );
}

init()
{
}

watch_staff_usage()
{
    self notify( "watch_staff_usage" );
    self endon( "watch_staff_usage" );
    self endon( "disconnect" );
    self setclientfieldtoplayer( "player_staff_charge", 0 );

    while ( true )
    {
        self waittill( "weapon_change", weapon );
        has_upgraded_staff = 0;
        has_revive_staff = 0;
        weapon_is_upgraded_staff = maps\mp\zm_tomb_utility::is_weapon_upgraded_staff( weapon );
        str_upgraded_staff_weapon = undefined;
        a_str_weapons = self getweaponslist();

        foreach ( str_weapon in a_str_weapons )
        {
            if ( maps\mp\zm_tomb_utility::is_weapon_upgraded_staff( str_weapon ) )
            {
                has_upgraded_staff = 1;
                str_upgraded_staff_weapon = str_weapon;
            }

            if ( str_weapon == "staff_revive_zm" )
                has_revive_staff = 1;
        }



        if ( has_upgraded_staff && !has_revive_staff )
        {
            self takeweapon( str_upgraded_staff_weapon );
            has_upgraded_staff = 0;
        }

        if ( !has_upgraded_staff && has_revive_staff )
        {
            self takeweapon( "staff_revive_zm" );
            has_revive_staff = 0;
        }

        if ( !has_revive_staff || !weapon_is_upgraded_staff && "none" != weapon && "none" != weaponaltweaponname( weapon ) )
            self setactionslot( 1, "altmode" );
        else
            self setactionslot( 1, "weapon", "staff_revive_zm" );

        if ( weapon_is_upgraded_staff )
            self thread maps\mp\zm_tomb_utility::staff_charge_watch_wrapper( weapon );
    }
}

update_staff_accessories( n_element_index )
{


    if ( !( isdefined( self.one_inch_punch_flag_has_been_init ) && self.one_inch_punch_flag_has_been_init ) )
    {
        cur_weapon = self get_player_melee_weapon();
        weapon_to_keep = "knife_zm";
        self.use_staff_melee = 0;

        if ( n_element_index != 0 )
        {
            staff_info = maps\mp\zm_tomb_craftables::get_staff_info_from_element_index( n_element_index );

            if ( staff_info.charger.is_charged )
                staff_info = staff_info.upgrade;

            if ( isdefined( staff_info.melee ) )
            {
                weapon_to_keep = staff_info.melee;
                self.use_staff_melee = 1;
            }
        }

        melee_changed = 0;

        if ( cur_weapon != weapon_to_keep )
        {
            self takeweapon( cur_weapon );
            self giveweapon( weapon_to_keep );
            self set_player_melee_weapon( weapon_to_keep );
            melee_changed = 1;
        }
    }

    has_revive = self hasweapon( "staff_revive_zm" );
    has_upgraded_staff = 0;
    a_weapons = self getweaponslistprimaries();
    staff_info = maps\mp\zm_tomb_craftables::get_staff_info_from_element_index( n_element_index );

    foreach ( str_weapon in a_weapons )
    {
        if ( maps\mp\zm_tomb_utility::is_weapon_upgraded_staff( str_weapon ) )
            has_upgraded_staff = 1;
    }

    if ( has_revive && !has_upgraded_staff )
    {
        self setactionslot( 1, "altmode" );
        self takeweapon( "staff_revive_zm" );
    }
    else if ( !has_revive && has_upgraded_staff )
    {
        self setactionslot( 1, "weapon", "staff_revive_zm" );
        self giveweapon( "staff_revive_zm" );

        if ( isdefined( staff_info ) )
        {
            if ( isdefined( staff_info.upgrade.revive_ammo_stock ) )
            {
                self setweaponammostock( "staff_revive_zm", staff_info.upgrade.revive_ammo_stock );
                self setweaponammoclip( "staff_revive_zm", staff_info.upgrade.revive_ammo_clip );
            }
        }
    }
}
