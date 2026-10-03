// Issue 12: native bodies with equipment slot 3 and alternate fire slot 1.
// Stock Core/maps/mp/zombies/_zm_buildables.gsc; BO2-Reimagined keeps the same equipment lifecycle.
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\gametypes_zm\_hud_util;
#include maps\mp\zombies\_zm_laststand;
#include maps\mp\zombies\_zm_equipment;
#include maps\mp\zombies\_zm_unitrigger;
#include maps\mp\zombies\_zm_buildables;
#include maps\mp\zombies\_zm_stats;
#include maps\mp\zombies\_zm_weapons;
#include maps\mp\_demo;

main()
{
    replaceFunc( maps\mp\zombies\_zm_buildables::bptrigger_think_persistent, ::bptrigger_think_persistent );
}

init()
{
}

bptrigger_think_persistent( player_built )
{
    if ( !isdefined( player_built ) || self [[ self.stub.prompt_and_visibility_func ]]( player_built ) )
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

            if ( !( isdefined( self.stub.built ) && self.stub.built ) )
            {
                self.stub.hint_string = "";
                self sethintstring( self.stub.hint_string );
                self setcursorhint( "HINT_NOICON" );
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

            if ( isdefined( self.stub.buildablestruct.onbought ) )
                self [[ self.stub.buildablestruct.onbought ]]( player );
            else if ( !maps\mp\zombies\_zm_equipment::is_limited_equipment( self.stub.weaponname ) || !maps\mp\zombies\_zm_equipment::limited_equipment_in_use( self.stub.weaponname ) )
            {
                player maps\mp\zombies\_zm_equipment::equipment_buy( self.stub.weaponname );
                player giveweapon( self.stub.weaponname );
                player setweaponammoclip( self.stub.weaponname, 1 );

                if ( isdefined( level.zombie_include_buildables[self.stub.equipname].onbuyweapon ) )
                    self [[ level.zombie_include_buildables[self.stub.equipname].onbuyweapon ]]( player );

                if ( self.stub.weaponname != "keys_zm" )
                    player setactionslot( 3, "weapon", self.stub.weaponname );

                self.stub.cursor_hint = "HINT_NOICON";
                self.stub.cursor_hint_weapon = undefined;
                self setcursorhint( self.stub.cursor_hint );

                if ( isdefined( level.zombie_buildables[self.stub.equipname].bought ) )
                    self.stub.hint_string = level.zombie_buildables[self.stub.equipname].bought;
                else
                    self.stub.hint_string = "";

                self sethintstring( self.stub.hint_string );
                player maps\mp\zombies\_zm_buildables::track_buildables_pickedup( self.stub.weaponname );
            }
            else
            {
                self.stub.hint_string = "";
                self sethintstring( self.stub.hint_string );
                self.stub.cursor_hint = "HINT_NOICON";
                self.stub.cursor_hint_weapon = undefined;
                self setcursorhint( self.stub.cursor_hint );
            }
        }
    }
}
