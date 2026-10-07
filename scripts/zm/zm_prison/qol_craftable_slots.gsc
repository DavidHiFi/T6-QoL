// Issue 12: native bodies with equipment slot 3 and alternate fire slot 1.
// Stock Maps/Mob of the Dead/maps/mp/zombies/_zm_craftables.gsc; BO2-Reimagined keeps the same equipment lifecycle.
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\gametypes_zm\_hud_util;
#include maps\mp\zombies\_zm_laststand;
#include maps\mp\zombies\_zm_equipment;
#include maps\mp\zombies\_zm_unitrigger;
#include maps\mp\zombies\_zm_craftables;
#include maps\mp\zombies\_zm_stats;
#include maps\mp\zombies\_zm_weapons;
#include maps\mp\_demo;

main()
{
    replaceFunc( maps\mp\zombies\_zm_craftables::craftable_place_think, ::craftable_place_think );
}

init()
{
}

craftable_place_think()
{
    self endon( "kill_trigger" );
    player_crafted = undefined;

    while ( !( isdefined( self.stub.crafted ) && self.stub.crafted ) )
    {
        self waittill( "trigger", player );

        if ( isdefined( level.custom_craftable_validation ) )
        {
            valid = self [[ level.custom_craftable_validation ]]( player );

            if ( !valid )
                continue;
        }

        if ( player != self.parent_player )
            continue;

        if ( isdefined( player.screecher_weapon ) )
            continue;

        if ( !is_player_valid( player ) )
        {
            player thread ignore_triggers( 0.5 );
            continue;
        }

        status = player maps\mp\zombies\_zm_craftables::player_can_craft( self.stub.craftablespawn );

        if ( !status )
        {
            self.stub.hint_string = "";
            self sethintstring( self.stub.hint_string );

            if ( isdefined( self.stub.oncantuse ) )
                self.stub [[ self.stub.oncantuse ]]( player );
        }
        else
        {
            if ( isdefined( self.stub.onbeginuse ) )
                self.stub [[ self.stub.onbeginuse ]]( player );

            result = self maps\mp\zombies\_zm_craftables::craftable_use_hold_think( player );
            team = player.pers["team"];

            if ( isdefined( self.stub.onenduse ) )
                self.stub [[ self.stub.onenduse ]]( team, player, result );

            if ( !result )
                continue;

            if ( isdefined( self.stub.onuse ) )
                self.stub [[ self.stub.onuse ]]( player );

            prompt = player maps\mp\zombies\_zm_craftables::player_craft( self.stub.craftablespawn );
            player_crafted = player;
            self.stub.hint_string = prompt;
            self sethintstring( self.stub.hint_string );
        }
    }

    if ( isdefined( self.stub.craftablestub.onfullycrafted ) )
    {
        b_result = self.stub [[ self.stub.craftablestub.onfullycrafted ]]();

        if ( !b_result )
            return;
    }

    if ( isdefined( player_crafted ) )
    {

    }

    if ( self.stub.persistent == 0 )
    {
        self.stub maps\mp\zombies\_zm_craftables::craftablestub_remove();
        thread maps\mp\zombies\_zm_unitrigger::unregister_unitrigger( self.stub );
        return;
    }

    if ( self.stub.persistent == 3 )
    {
        maps\mp\zombies\_zm_craftables::stub_uncraft_craftable( self.stub, 1 );
        return;
    }

    if ( self.stub.persistent == 2 )
    {
        if ( isdefined( player_crafted ) )
            self maps\mp\zombies\_zm_craftables::craftabletrigger_update_prompt( player_crafted );

        if ( !maps\mp\zombies\_zm_weapons::limited_weapon_below_quota( self.stub.weaponname, undefined ) )
        {
            self.stub.hint_string = &"ZOMBIE_GO_TO_THE_BOX_LIMITED";
            self sethintstring( self.stub.hint_string );
            return;
        }

        if ( isdefined( self.stub.str_taken ) && self.stub.str_taken )
        {
            self.stub.hint_string = &"ZOMBIE_GO_TO_THE_BOX";
            self sethintstring( self.stub.hint_string );
            return;
        }

        if ( isdefined( self.stub.model ) )
        {
            self.stub.model notsolid();
            self.stub.model show();
        }

        while ( self.stub.persistent == 2 )
        {
            self waittill( "trigger", player );

            if ( isdefined( player.screecher_weapon ) )
                continue;

            if ( isdefined( level.custom_craftable_validation ) )
            {
                valid = self [[ level.custom_craftable_validation ]]( player );

                if ( !valid )
                    continue;
            }

            if ( !( isdefined( self.stub.crafted ) && self.stub.crafted ) )
            {
                self.stub.hint_string = "";
                self sethintstring( self.stub.hint_string );
                return;
            }

            if ( player != self.parent_player )
                continue;

            if ( !is_player_valid( player ) )
            {
                player thread ignore_triggers( 0.5 );
                continue;
            }

            self.stub.bought = 1;

            if ( isdefined( self.stub.model ) )
                self.stub.model thread maps\mp\zombies\_zm_craftables::model_fly_away( self );

            player maps\mp\zombies\_zm_weapons::weapon_give( self.stub.weaponname );

            if ( isdefined( level.zombie_include_craftables[self.stub.equipname].onbuyweapon ) )
                self [[ level.zombie_include_craftables[self.stub.equipname].onbuyweapon ]]( player );

            if ( !maps\mp\zombies\_zm_weapons::limited_weapon_below_quota( self.stub.weaponname, undefined ) )
                self.stub.hint_string = &"ZOMBIE_GO_TO_THE_BOX_LIMITED";
            else
                self.stub.hint_string = &"ZOMBIE_GO_TO_THE_BOX";

            self sethintstring( self.stub.hint_string );
            player maps\mp\zombies\_zm_craftables::track_craftables_pickedup( self.stub.craftablespawn );
        }
    }
    else if ( !isdefined( player_crafted ) || self maps\mp\zombies\_zm_craftables::craftabletrigger_update_prompt( player_crafted ) )
    {
        if ( isdefined( self.stub.model ) )
        {
            self.stub.model notsolid();
            self.stub.model show();
        }

        while ( self.stub.persistent == 1 )
        {
            self waittill( "trigger", player );

            if ( isdefined( player.screecher_weapon ) )
                continue;

            if ( isdefined( level.custom_craftable_validation ) )
            {
                valid = self [[ level.custom_craftable_validation ]]( player );

                if ( !valid )
                    continue;
            }

            if ( !( isdefined( self.stub.crafted ) && self.stub.crafted ) )
            {
                self.stub.hint_string = "";
                self sethintstring( self.stub.hint_string );
                return;
            }

            if ( player != self.parent_player )
                continue;

            if ( !is_player_valid( player ) )
            {
                player thread ignore_triggers( 0.5 );
                continue;
            }

            if ( player has_player_equipment( self.stub.weaponname ) )
                continue;

            if ( isdefined( level.zombie_craftable_persistent_weapon ) )
            {
                if ( self [[ level.zombie_craftable_persistent_weapon ]]( player ) )
                    continue;
            }

            if ( isdefined( level.zombie_custom_equipment_setup ) )
            {
                if ( self [[ level.zombie_custom_equipment_setup ]]( player ) )
                    continue;
            }

            if ( !maps\mp\zombies\_zm_equipment::is_limited_equipment( self.stub.weaponname ) || !maps\mp\zombies\_zm_equipment::limited_equipment_in_use( self.stub.weaponname ) )
            {
                player maps\mp\zombies\_zm_equipment::equipment_buy( self.stub.weaponname );
                player giveweapon( self.stub.weaponname );
                player setweaponammoclip( self.stub.weaponname, 1 );

                if ( isdefined( level.zombie_include_craftables[self.stub.equipname].onbuyweapon ) )
                    self [[ level.zombie_include_craftables[self.stub.equipname].onbuyweapon ]]( player );
                else if ( self.stub.weaponname != "keys_zm" )
                    player setactionslot( 3, "weapon", self.stub.weaponname );

                if ( isdefined( level.zombie_craftablestubs[self.stub.equipname].str_taken ) )
                    self.stub.hint_string = level.zombie_craftablestubs[self.stub.equipname].str_taken;
                else
                    self.stub.hint_string = "";

                self sethintstring( self.stub.hint_string );
                player maps\mp\zombies\_zm_craftables::track_craftables_pickedup( self.stub.craftablespawn );
            }
            else
            {
                self.stub.hint_string = "";
                self sethintstring( self.stub.hint_string );
            }
        }
    }
}
