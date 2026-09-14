#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility; 

init()
{
    if ( !maps\mp\zombies\_zm_weapons::is_weapon_included( "freezegun_zm" ) )
    {
        return;
    }

    // Guard against double-invocation within a single map load: init() is reached
    // more than once per load, and a second RegisterClientField for these fields
    // COM_ERRORs the server ("actor set already contains freezegun_extremity_damage_fx"),
    // which forces a map_rotate and crash-loops the server. level resets each map load,
    // so the engine still re-registers the clientfields once per map as required.
    if ( isdefined( level._freezegun_init_done ) )
    {
        return;
    }
    level._freezegun_init_done = 1;

    register_zombie_damage_callback( ::freezegun_zombie_damage_response );
    register_zombie_death_animscript_callback( ::freezegun_zombie_death_response );
    register_zombie_death_event_callback( ::freezegun_death_event );

    // Origins (zm_tomb) and Buried ship with their "actor" clientfield set at the engine's
    // hard bit ceiling — these two extra actor fields overflow it and crash those maps
    // ("Client Field Set actor is out of space"). Skip the freeze-over visual FX there;
    // the freeze gun itself still works fully (damage/shatter are server-side callbacks).
    // The client registration in _zm_weap_freezegun.csc is gated by the same condition —
    // server and client actor sets MUST stay matched.
    if ( freezegun_actor_fx_enabled() )
    {
        RegisterClientField("actor", "freezegun_extremity_damage_fx", 15000, 1, "int");
        RegisterClientField("actor", "freezegun_torso_damage_fx", 15000, 1, "int");
    }

    set_zombie_var( "freezegun_cylinder_radius",                120 ); // 10 feet
    set_zombie_var( "freezegun_inner_range",                    60 ); // 5 feet
    set_zombie_var( "freezegun_outer_range",                    600 ); // 50 feet
    set_zombie_var( "freezegun_inner_damage",                   1000 );
    set_zombie_var( "freezegun_outer_damage",                   500 );
    set_zombie_var( "freezegun_shatter_range",                  180 ); // 150 feet
    set_zombie_var( "freezegun_shatter_inner_damage",           500 );
    set_zombie_var( "freezegun_shatter_outer_damage",           250 );
    set_zombie_var( "freezegun_cylinder_radius_upgraded",       180 ); // 15 feet
    set_zombie_var( "freezegun_inner_range_upgraded",           120 ); // 10 feet
    set_zombie_var( "freezegun_outer_range_upgraded",           900 ); // 75 feet
    //  🛑 v2.9.13 - WAS 5900000, RESTORED TO BO1'S 1500.
    //
    //  git blame: the 5,900,000 arrived verbatim with the SRS wonder-weapon
    //  import (f4c22d8, v1.69.0) and is the donor package's own number. It is
    //  documented NOWHERE in this project - not MOD_CATALOGUE, not QUEUE, not a
    //  comment - so it was inherited, never chosen here. BO1 ships 1500:
    //      <BO1>\raw\maps\_zombiemode_weap_freezegun.gsc:32
    //
    //  Two things it broke:
    //   1. At 3,933x BO1's damage the Packed gun one-shot every zombie at every
    //      round, so freezegun_damage_response() - the progressive slowdown and
    //      the frost fx - could never run on an upgraded kill. The gun "killed
    //      without freezing anything first", which is the reported symptom.
    //   2. It silently disabled this mod's own WINTER'S HOWL INFINITE DAMAGE row
    //      (PATCHES tab, dvar winters_howl_infinite). That option raises damage to
    //      self.health when ON - but with the base already at 5.9M, self.health is
    //      almost never greater, so ON and OFF behaved identically. The row only
    //      becomes a real switch once this value is sane again.
    //  🌟 v2.11.29 - THE LAST THREE DONOR NUMBERS NOW MATCH BO1 TOO.
    //
    //  v2.9.13 (above) left these alone on the grounds that changing them would be
    //  "an unrequested rebalance". It is requested now: the user's wonder-weapon
    //  parity directive asks for the DEFAULT state to "match BO1 stock damage
    //  falloff", with the extra damage living behind the buff toggle instead.
    //
    //  All three arrived verbatim with the SRS import (f4c22d8, v1.69.0) - checked
    //  with `git log -S` - and, unlike the Wunderwaffe's arc timing, carry NO user
    //  instruction behind them. They were inherited, never chosen here. BO1's own
    //  values, read out of <BO1>\raw\maps\_zombiemode_weap_freezegun.gsc:33,35,36:
    //      outer_damage_upgraded          1000 -> 750
    //      shatter_inner_damage_upgraded  1000 -> 750
    //      shatter_outer_damage_upgraded  1000 -> 500
    //  inner_damage_upgraded (1500) and shatter_range_upgraded (300) already match,
    //  and so does every base-gun number. The whole table is BO1's now.
    //
    //  📝 This makes WINTERS HOWL BUFF matter MORE, not less: the row raises damage
    //  to self.health whenever self.health > damage, so a lower base means the
    //  toggle takes over at earlier rounds - which is the split the directive asks
    //  for. Each value is read only by its own freezegun_get_* accessor (verified),
    //  so nothing else moves.
    set_zombie_var( "freezegun_inner_damage_upgraded",          1500 );
    set_zombie_var( "freezegun_outer_damage_upgraded",          750 );
    set_zombie_var( "freezegun_shatter_range_upgraded",         300 ); // 25 feet
    set_zombie_var( "freezegun_shatter_inner_damage_upgraded",  750 );
    set_zombie_var( "freezegun_shatter_outer_damage_upgraded",  500 );
    

    level._effect[ "freezegun_shatter" ]                = LoadFX( "weapon/freeze_gun/fx_freezegun_shatter" );
    level._effect[ "freezegun_crumple" ]                = LoadFX( "weapon/freeze_gun/fx_freezegun_crumple" );
    level._effect[ "freezegun_smoke_cloud" ]            = loadfx( "weapon/freeze_gun/fx_freezegun_smoke_cloud" );
    level._effect[ "freezegun_damage_torso" ]           = LoadFX( "maps/zombie/fx_zombie_freeze_torso" );
    level._effect[ "freezegun_damage_sm" ]              = LoadFX( "maps/zombie/fx_zombie_freeze_md" );
    level._effect[ "freezegun_upgraded" ]               = LoadFX( "weapon/freeze_gun/fx_exp_freezegun_impact" );

    level._effect[ "freezegun_shatter_gibtrail_fx" ]    = LoadFX( "weapon/freeze_gun/fx_trail_freezegun_blood_streak" );
    level._effect[ "freezegun_crumple_gibtrail_fx" ]    = LoadFX( "trail/fx_trail_blood_streak" );
    level._effect[ "freezegun_gib_fx" ]                 = LoadFX( "weapon/bullet/fx_flesh_gib_fatal_01" );
    
    // For testing FX 
    // system_elements/fx_null

/*
/#
    level thread freezegun_devgui_dvar_think();
#/
*/

    OnPlayerConnect_Callback(::freezegun_on_player_connect);
}

/*
/#
freezegun_devgui_dvar_think()
{
    if ( !maps\mp\zombies\_zm_weapons::is_weapon_included( "freezegun_zm" ) )
    {
        return;
    }

    SetDvar( "scr_freezegun_cylinder_radius",               level.zombie_vars["freezegun_cylinder_radius"] );
    SetDvar( "scr_freezegun_inner_range",                   level.zombie_vars["freezegun_inner_range"] );
    SetDvar( "scr_freezegun_outer_range",                   level.zombie_vars["freezegun_outer_range"] );
    SetDvar( "scr_freezegun_inner_damage",                  level.zombie_vars["freezegun_inner_damage"] );
    SetDvar( "scr_freezegun_outer_damage",                  level.zombie_vars["freezegun_outer_damage"] );
    SetDvar( "scr_freezegun_shatter_range",                 level.zombie_vars["freezegun_shatter_range"] );
    SetDvar( "scr_freezegun_shatter_inner_damage",          level.zombie_vars["freezegun_shatter_inner_damage"] );
    SetDvar( "scr_freezegun_shatter_outer_damage",          level.zombie_vars["freezegun_shatter_outer_damage"] );
    SetDvar( "scr_freezegun_cylinder_radius_upgraded",      level.zombie_vars["freezegun_cylinder_radius_upgraded"] );
    SetDvar( "scr_freezegun_inner_range_upgraded",          level.zombie_vars["freezegun_inner_range_upgraded"] );
    SetDvar( "scr_freezegun_outer_range_upgraded",          level.zombie_vars["freezegun_outer_range_upgraded"] );
    SetDvar( "scr_freezegun_inner_damage_upgraded",         level.zombie_vars["freezegun_inner_damage_upgraded"] );
    SetDvar( "scr_freezegun_outer_damage_upgraded",         level.zombie_vars["freezegun_outer_damage_upgraded"] );
    SetDvar( "scr_freezegun_shatter_range_upgraded",        level.zombie_vars["freezegun_shatter_range_upgraded"] );
    SetDvar( "scr_freezegun_shatter_inner_damage_upgraded", level.zombie_vars["freezegun_shatter_inner_damage_upgraded"] );
    SetDvar( "scr_freezegun_shatter_outer_damage_upgraded", level.zombie_vars["freezegun_shatter_outer_damage_upgraded"] );

    for ( ;; )
    {
        level.zombie_vars["freezegun_cylinder_radius"]                  = GetDvarInt( "scr_freezegun_cylinder_radius" );
        level.zombie_vars["freezegun_inner_range"]                      = GetDvarInt( "scr_freezegun_inner_range" );
        level.zombie_vars["freezegun_outer_range"]                      = GetDvarInt( "scr_freezegun_outer_range" );
        level.zombie_vars["freezegun_inner_damage"]                     = GetDvarInt( "scr_freezegun_inner_damage" );
        level.zombie_vars["freezegun_outer_damage"]                     = GetDvarInt( "scr_freezegun_outer_damage" );
        level.zombie_vars["freezegun_shatter_range"]                    = GetDvarInt( "scr_freezegun_shatter_range" );
        level.zombie_vars["freezegun_shatter_inner_damage"]             = GetDvarInt( "scr_freezegun_shatter_inner_damage" );
        level.zombie_vars["freezegun_shatter_outer_damage"]             = GetDvarInt( "scr_freezegun_shatter_outer_damage" );
        level.zombie_vars["freezegun_cylinder_radius_upgraded"]         = GetDvarInt( "scr_freezegun_cylinder_radius_upgraded" );
        level.zombie_vars["freezegun_inner_range_upgraded"]             = GetDvarInt( "scr_freezegun_inner_range_upgraded" );
        level.zombie_vars["freezegun_outer_range_upgraded"]             = GetDvarInt( "scr_freezegun_outer_range_upgraded" );
        level.zombie_vars["freezegun_inner_damage_upgraded"]            = GetDvarInt( "scr_freezegun_inner_damage_upgraded" );
        level.zombie_vars["freezegun_outer_damage_upgraded"]            = GetDvarInt( "scr_freezegun_outer_damage_upgraded" );
        level.zombie_vars["freezegun_shatter_range_upgraded"]           = GetDvarInt( "scr_freezegun_shatter_range_upgraded" );
        level.zombie_vars["freezegun_shatter_inner_damage_upgraded"]    = GetDvarInt( "scr_freezegun_shatter_inner_damage_upgraded" );
        level.zombie_vars["freezegun_shatter_outer_damage_upgraded"]    = GetDvarInt( "scr_freezegun_shatter_outer_damage_upgraded" );

        wait( 0.5 );
    }
}
#/
*/

freezegun_on_player_connect()
{
    self thread wait_for_thundergun_fired(); 
}

wait_for_thundergun_fired()
{
    self endon( "disconnect" );
    self waittill( "spawned_player" ); 

    for( ;; )
    {
        self waittill( "weapon_fired" ); 
        currentweapon = self GetCurrentWeapon(); 
        if( ( currentweapon == "freezegun_zm" ) || ( currentweapon == "freezegun_upgraded_zm" ) )
        {
            self thread freezegun_fired( currentweapon == "freezegun_upgraded_zm" );

            // v1.99.11 - RESTORED. v1.99.10 removed this and the gun drew nothing at all.
            // fx_freezegun_smoke_cloud IS the white frost burst, not a stray "wind" - the
            // muzzle-flash elements alone are not visible in practice. This is the BO1 port's
            // own effect and it stays. Do not remove it again.
            view_pos = self GetTagOrigin( "tag_flash" ) - self GetPlayerViewHeight();
            view_angles = self GetTagAngles( "tag_flash" );
            playfx( level._effect["freezegun_smoke_cloud"], view_pos, AnglesToForward( view_angles ), AnglesToUp( view_angles ) );
        }
    }
}

freezegun_fired( upgraded )
{
    if ( !IsDefined( level.freezegun_enemies ) )
    {
        level.freezegun_enemies = [];
        level.freezegun_enemies_dist_ratio = [];
    }

    self freezegun_get_enemies_in_range( upgraded );

    for ( i = 0; i < level.freezegun_enemies.size; i++ )
    {
        level.freezegun_enemies[i] thread freezegun_do_damage( upgraded, self, level.freezegun_enemies_dist_ratio[i] );
    }

    level.freezegun_enemies = [];
    level.freezegun_enemies_dist_ratio = [];
}

freezegun_get_cylinder_radius( upgraded )
{
    if ( upgraded )
    {
        return level.zombie_vars["freezegun_cylinder_radius_upgraded"];
    }
    else
    {
        return level.zombie_vars["freezegun_cylinder_radius"];
    }
}

freezegun_get_inner_range( upgraded )
{
    if ( upgraded )
    {
        return level.zombie_vars["freezegun_inner_range_upgraded"];
    }
    else
    {
        return level.zombie_vars["freezegun_inner_range"];
    }
}

freezegun_get_outer_range( upgraded )
{
    if ( upgraded )
    {
        return level.zombie_vars["freezegun_outer_range_upgraded"];
    }
    else
    {
        return level.zombie_vars["freezegun_outer_range"];
    }
}

freezegun_get_inner_damage( upgraded )
{
    if ( upgraded )
    {
        return level.zombie_vars["freezegun_inner_damage_upgraded"];
    }
    else
    {
        return level.zombie_vars["freezegun_inner_damage"];
    }
}

freezegun_get_outer_damage( upgraded )
{
    if ( upgraded )
    {
        return level.zombie_vars["freezegun_outer_damage_upgraded"];
    }
    else
    {
        return level.zombie_vars["freezegun_outer_damage"];
    }
}

freezegun_get_shatter_range( upgraded )
{
    if ( upgraded )
    {
        return level.zombie_vars["freezegun_shatter_range_upgraded"];
    }
    else
    {
        return level.zombie_vars["freezegun_shatter_range"];
    }
}

freezegun_get_shatter_inner_damage( upgraded )
{
    if ( upgraded )
    {
        return level.zombie_vars["freezegun_shatter_inner_damage_upgraded"];
    }
    else
    {
        return level.zombie_vars["freezegun_shatter_inner_damage"];
    }
}

freezegun_get_shatter_outer_damage( upgraded )
{
    if ( upgraded )
    {
        return level.zombie_vars["freezegun_shatter_outer_damage_upgraded"];
    }
    else
    {
        return level.zombie_vars["freezegun_shatter_outer_damage"];
    }
}

freezegun_get_enemies_in_range( upgraded )
{
    inner_range = freezegun_get_inner_range( upgraded );
    outer_range = freezegun_get_outer_range( upgraded );
    cylinder_radius = freezegun_get_cylinder_radius( upgraded );

    view_pos = self GetWeaponMuzzlePoint();

    // Add a 10% epsilon to the range on this call to get guys right on the edge
    zombies = get_array_of_closest( view_pos, srs_ww_target_array(), undefined, undefined, (outer_range * 1.1) );
    if ( !isDefined( zombies ) )
    {
        return;
    }

    freezegun_inner_range_squared = inner_range * inner_range;
    freezegun_outer_range_squared = outer_range * outer_range;
    cylinder_radius_squared = cylinder_radius * cylinder_radius;

    forward_view_angles = self GetWeaponForwardDir();
    end_pos = view_pos + VectorScale( forward_view_angles, outer_range );

/*
/#
    if ( 2 == GetDvarInt( "scr_freezegun_debug" ) )
    {
        // push the near circle out a couple units to avoid an assert in Circle() due to it attempting to
        // derive the view direction from the circle's center point minus the viewpos
        // (which is what we're using as our center point, which results in a zeroed direction vector)
        near_circle_pos = view_pos + VectorScale( forward_view_angles, 2 );

        Circle( near_circle_pos, cylinder_radius, (1, 0, 0), false, false, 100 );
        Line( near_circle_pos, end_pos, (0, 0, 1), 1, false, 100 );
        Circle( end_pos, cylinder_radius, (1, 0, 0), false, false, 100 );
    }
#/
*/

    for ( i = 0; i < zombies.size; i++ )
    {
        if ( !IsDefined( zombies[i] ) || !IsAlive( zombies[i] ) )
        {
            // guy died on us
            continue;
        }

        test_origin = zombies[i] getcentroid();
        test_range_squared = DistanceSquared( view_pos, test_origin );
        if ( test_range_squared > freezegun_outer_range_squared )
        {
//          zombies[i] freezegun_debug_print( "range", (1, 0, 0) );
            return; // everything else in the list will be out of range
        }

        //  🛑 v2.9.16 - TRANZIT DENIZENS: same rule and same reason as the
        //  thundergun's candidate loop (see the banner there) - a screecher at
        //  or on the shooter fails the dot and cone gates by geometry, so a
        //  close or latched one is accepted outright and takes the shot's
        //  normal damage through the list below.
        if ( isdefined( zombies[i].isscreecher ) && zombies[i].isscreecher && ( test_range_squared < 16384 || ( isdefined( zombies[i].linked_ent ) && zombies[i].linked_ent == self ) ) )
        {
            level.freezegun_enemies[level.freezegun_enemies.size] = zombies[i];
            level.freezegun_enemies_dist_ratio[level.freezegun_enemies_dist_ratio.size] = 1;
            continue;
        }

        normal = VectorNormalize( test_origin - view_pos );
        dot = VectorDot( forward_view_angles, normal );
        if ( 0 > dot )
        {
            // guy's behind us
//          zombies[i] freezegun_debug_print( "dot", (1, 0, 0) );
            continue;
        }
        
        radial_origin = PointOnSegmentNearestToPoint( view_pos, end_pos, test_origin );
        if ( DistanceSquared( test_origin, radial_origin ) > cylinder_radius_squared )
        {
            // guy's outside the range of the cylinder of effect
//          zombies[i] freezegun_debug_print( "cylinder", (1, 0, 0) );
            continue;
        }

        if ( 0 == zombies[i] DamageConeTrace( view_pos, self ) )
        {
            // guy can't actually be hit from where we are
//          zombies[i] freezegun_debug_print( "cone", (1, 0, 0) );
            continue;
        }

        level.freezegun_enemies[level.freezegun_enemies.size] = zombies[i];
        level.freezegun_enemies_dist_ratio[level.freezegun_enemies_dist_ratio.size] = (freezegun_outer_range_squared - test_range_squared) / (freezegun_outer_range_squared - freezegun_inner_range_squared);
    }
}

/*
freezegun_debug_print( msg, color )
{
/#
    if ( !GetDvarInt( "scr_freezegun_debug" ) )
    {
        return;
    }

    if ( !isdefined( color ) )
    {
        color = (1, 1, 1);
    }

    Print3d(self.origin + (0,0,60), msg, color, 1, 1, 40); // 10 server frames is 1 second
#/
}
*/

freezegun_do_damage( upgraded, player, dist_ratio )
{
    // v1.93.0 - BOSSES FIRST, same hook as the thundergun and the tesla gun.
    // Installed per-map so this root file never references a Mob-only script.
    // See zmqol_brutus_ww_hit() in scripts\zm\zm_prison\zm_prison.gsc.
    if ( isdefined( level.zmqol_ww_boss_hit ) )
    {
        b_handled = self [[ level.zmqol_ww_boss_hit ]]( player );

        if ( b_handled )
            return;
    }

    // do not gib this time, was causing issues when creating a crawler
    self.no_gib = true;
    
    damage = Int( LerpFloat( freezegun_get_outer_damage( upgraded ), freezegun_get_inner_damage( upgraded ), dist_ratio ) );

    // ========================================================================
    //  v2.8.2 - WINTER'S HOWL INFINITE DAMAGE (PATCHES tab), the direct hit.
    //
    //  🌟 RAISED TO EXACTLY self.health, NOT TO A BIG CONSTANT. self is the
    //  enemy this thread is damaging, so its health is known here. Stock's
    //  ai_calculate_health() ( _zm.gsc:3572 ) only stops growing zombie health
    //  when the value overflows a 32-bit int, so at a high round no fixed
    //  number is reliably "infinite" - and one big enough to be would overflow
    //  when an actor_damage_func multiplies it. self.health is the exact amount
    //  and can do neither.
    //
    //  🛑 Bosses keep their own rules for the same reason ONE SHOT ONE KILL
    //  leaves them alone: level.zmqol_ww_boss_hit has already had its say a few
    //  lines above, and self.actor_damage_func still runs after this.
    // ========================================================================
    // The freezegun applies damage from this script instead of the stock weapon
    // damage path, so stock check_for_instakill() never raises it for us. Match
    // Treyarch's Paralyzer handling and include both team and personal insta-kill.
    b_instakill = isdefined( player ) && isalive( player ) &&
        ( level.zombie_vars[player.team]["zombie_insta_kill"] ||
          isdefined( player.personal_instakill ) && player.personal_instakill );

    if ( b_instakill && isdefined( self.health ) )
        damage = self.health + 666;
    else if ( getdvarintdefault( "winters_howl_infinite", 0 ) && isdefined( self.health ) && self.health > damage )
        damage = self.health;

    self DoDamage( damage, player.origin, player, player, "none", "MOD_PROJECTILE" );
    
//  self freezegun_debug_print( damage, (0, 1, 0) );
}

// The freeze-over FX clientfields are not registered on zm_tomb/zm_buried (actor bit
// ceiling — see init). Setting an unregistered clientfield errors, so every setter
// must share the same gate.
freezegun_actor_fx_enabled()
{
    mapname = getdvar( "mapname" );
    return mapname != "zm_tomb" && mapname != "zm_buried";
}

freezegun_set_extremity_damage_fx()
{
    if ( !freezegun_actor_fx_enabled() )
        return;

    self SetClientField( "freezegun_extremity_damage_fx", 1);
}

freezegun_clear_extremity_damage_fx()
{
    if ( !freezegun_actor_fx_enabled() )
        return;

    self SetClientField( "freezegun_extremity_damage_fx", 0);
}

freezegun_set_torso_damage_fx()
{
    if ( !freezegun_actor_fx_enabled() )
        return;

    self SetClientField( "freezegun_torso_damage_fx", 1);
}

freezegun_clear_torso_damage_fx()
{
    if ( !freezegun_actor_fx_enabled() )
        return;

    self SetClientField( "freezegun_torso_damage_fx", 0);
}

freezegun_damage_response( player, amount )
{
    if ( IsDefined( self.freezegun_damage_response_func ) )
    {
        if ( self [[ self.freezegun_damage_response_func ]]( player, amount ) )
        {
            return;
        }
    }

    self.freezegun_damage += amount;

    new_move_speed = self.zombie_move_speed;

    percent_dmg = self enemy_percent_damaged_by_freezegun();
    
    //  🛑 v2.9.13 - DECOMPILE DAMAGE, FIXED AGAINST BO1'S OWN SOURCE.
    //  Both branches read `0.1 <= percent_dmg`, so the second could NEVER run -
    //  identical condition, dead code. Any zombie past 10% freeze damage was
    //  dropped straight to "walk" and the intermediate sprint->run step, which is
    //  what makes the gun feel like it is freezing them progressively, never
    //  happened at all.
    //
    //  The real thresholds are 0.66 and 0.33, read out of Black Ops 1's own
    //  shipped source - not guessed, not inferred:
    //      <BO1>\raw\maps\_zombiemode_weap_freezegun.gsc::freezegun_damage_response
    //  which is the file this whole module was ported from. CLAUDE.md's rule
    //  earned its keep here: "a decompile is trustworthy in inverse proportion to
    //  its control flow", and a two-branch if/else-if is exactly where a
    //  decompiler drops the discriminating constant.
    if ( 0.66 <= percent_dmg )
    {
        new_move_speed = "walk";
    }
    else if ( 0.33 <= percent_dmg )
    {
        if ( "sprint" == self.zombie_move_speed )
        {
            new_move_speed = "run";
        }
        else
        {
            new_move_speed = "walk";
        }
    }

    if ( !self.isdog && self.zombie_move_speed != new_move_speed )
    {
        self set_zombie_run_cycle( new_move_speed );
    }

    self thread freezegun_set_extremity_damage_fx();
}

freezegun_do_gib( gib_type, upgraded )
{
    gibArray = [];
    gibArray[gibArray.size] = level._ZOMBIE_GIB_PIECE_INDEX_ALL;

    if ( upgraded )
    {
        gibArray[gibArray.size] = 7;
    }

    self gib( gib_type, gibArray );

    self Ghost();
    wait( 0.4 );
    self self_delete();
}

freezegun_do_shatter( player, weap, shatter_trigger, crumple_trigger )
{
//  freezegun_debug_print( "shattered" );

    self freezegun_cleanup_freezegun_triggers( shatter_trigger, crumple_trigger );

    upgraded = (weap == "freezegun_upgraded_zm");

    // ========================================================================
    //  v2.8.2 - WINTER'S HOWL INFINITE DAMAGE (PATCHES tab), the shatter AoE.
    //
    //  🛑 A CONSTANT HERE, NOT self.health, AND THAT IS FORCED: radiusDamage
    //  has no single target, so there is no health to read. 999999999 is under
    //  the 2147483647 int ceiling with room for the engine's own falloff maths.
    //  📝 THE ONE PLACE THIS IS NOT LITERALLY INFINITE: past roughly round 163
    //  zombie health overflows upward beyond this number (the same mechanism
    //  the INSTAKILL ROUNDS row uses), so the AoE stops being a guaranteed kill
    //  there while the direct hit above still is. Stated rather than hidden.
    //
    //  📝 The range is left alone deliberately - "infinite damage" was the
    //  request, not infinite reach, and widening the blast would change where
    //  the gun kills as well as how hard.
    //
    //  🌟 PLAYERS ARE NO MORE AT RISK THAN THEY ALREADY WERE. This call is
    //  unchanged in every argument but the two damage figures, and the shipped
    //  ones are already 500/1000 against a player health of 100 (160 with
    //  Juggernog) - so if own-explosive damage reached players at all they
    //  would already be going down to every shatter. It does not, and scaling
    //  a number that is multiplied by zero changes nothing.
    // ========================================================================
    n_sh_inner = freezegun_get_shatter_inner_damage( upgraded );
    n_sh_outer = freezegun_get_shatter_outer_damage( upgraded );

    if ( getdvarintdefault( "winters_howl_infinite", 0 ) )
    {
        n_sh_inner = 999999999;
        n_sh_outer = 999999999;
    }

    self radiusDamage( self.origin, freezegun_get_shatter_range( upgraded ), n_sh_inner, n_sh_outer, player, "MOD_EXPLOSIVE", weap );

    // The radiusDamage above still lands -- the shatter kills as normal. What is skipped is the
    // gib/ragdoll, which would destroy a body that a MotD soul catcher is mid-way through
    // consuming and strand its is_eating flag at 1, bricking Hell's Retriever. Treyarch's own
    // hook; the Blundergat is the only stock weapon that honours it.
    if ( self srs_ww_feeding_the_wolves() )
    {
        // Never gib -- freezegun_do_gib ends in self_delete() and would destroy a body a
        // soul catcher is consuming. But DO ragdoll: my_soul_catcher is set on EVERY zombie
        // killed in the volume (zombie_killed_override), not just the one being eaten, so
        // returning bare left all the others standing up dead (observed 2026-08-02).
        // The consumed one is ghosted and replaced by a client clone, so ragdolling its
        // server entity is invisible -- and nothing here deletes it, so is_eating still clears.
        self StartRagdoll();
        self freezegun_clear_extremity_damage_fx();
        self freezegun_clear_torso_damage_fx();
        return;
    }

    if ( is_mature() )
    {
        self thread freezegun_do_gib( "up", upgraded );
    }
    else
    {
        self StartRagdoll();
        self freezegun_clear_extremity_damage_fx();
        self freezegun_clear_torso_damage_fx();
    }
}

// See the long note on srs_ww_feeding_the_wolves in _zm_weap_thundergun.gsc. Duplicated per gun
// rather than shared so each weapon file stays self-contained.
srs_ww_feeding_the_wolves()
{
    // my_soul_catcher is the check that actually holds. Treyarch's level.no_gib_in_wolf_area
    // returns true only while the catcher is NOT yet eating, and zombie_soul_catcher_death sets
    // is_eating = 1 before this weapon's shatter runs -- so the hook alone reported false here and
    // freezegun_do_gib deleted the body mid-consume, stranding is_eating and bricking that dog head
    // for the rest of the game. (Observed on MotD 2026-08-02: freeze bricked it, thunder and tesla
    // did not -- thunder gibs pre-death, tesla never gibs at all.)
    if ( IsDefined( self.my_soul_catcher ) )
        return true;

    if ( !IsDefined( level.no_gib_in_wolf_area ) )
        return false;

    return self [[ level.no_gib_in_wolf_area ]]();
}

// Target list for all three wonder weapons. get_round_enemy_array() drops every AI with
// ignore_enemy_count set -- a flag that exists to keep bosses out of the ROUND COUNTER, not out of
// harm's way. Brutus sets it in brutus_spawn, so he was never in any of the three guns' target
// lists and could not be damaged by them at all. Take the full hostile species array instead;
// the callers already isalive-check every entry.
srs_ww_target_array()
{
    a = getaispeciesarray( level.zombie_team, "all" );

    if ( !IsDefined( a ) )
        return [];

    return a;
}


freezegun_wait_for_shatter( player, weap, shatter_trigger, crumple_trigger )
{
    shatter_trigger endon( "cleanup_freezegun_triggers" );
    
    orig_attacker = self.attacker;
    shatter_trigger waittill( "damage", amount, attacker, dir, org, mod );

    if ( isDefined( attacker ) && attacker == orig_attacker && "MOD_PROJECTILE" == mod && ("freezegun_zm" == attacker GetCurrentWeapon() || "freezegun_upgraded_zm" == attacker GetCurrentWeapon()) )
    {
        // player doesn't get the shatter result if they hit him again with the freezegun's attack
        self thread freezegun_do_crumple( weap, shatter_trigger, crumple_trigger );
    }
    else
    {
        self thread freezegun_do_shatter( player, weap, shatter_trigger, crumple_trigger );
    }
}

freezegun_do_crumple( weap, shatter_trigger, crumple_trigger )
{
//  freezegun_debug_print( "crumpled" );

    self freezegun_cleanup_freezegun_triggers( shatter_trigger, crumple_trigger );

    upgraded = (weap == "freezegun_upgraded_zm");

    if ( isDefined( self ) )
    {
        // Same soul-catcher rule as freezegun_do_shatter above.
        if ( self srs_ww_feeding_the_wolves() )
        {
            // Never gib -- freezegun_do_gib ends in self_delete() and would destroy a body a
            // soul catcher is consuming. But DO ragdoll: my_soul_catcher is set on EVERY zombie
            // killed in the volume (zombie_killed_override), not just the one being eaten, so
            // returning bare left all the others standing up dead (observed 2026-08-02).
            // The consumed one is ghosted and replaced by a client clone, so ragdolling its
            // server entity is invisible -- and nothing here deletes it, so is_eating still clears.
            self StartRagdoll();
            self freezegun_clear_extremity_damage_fx();
            self freezegun_clear_torso_damage_fx();
            return;
        }

        if ( is_mature() )
        {
            self thread freezegun_do_gib( "freeze", upgraded );
        }
        else
        {
            self StartRagdoll();
            self freezegun_clear_extremity_damage_fx();
            self freezegun_clear_torso_damage_fx();
        }
    }
}

freezegun_wait_for_crumple( weap, shatter_trigger, crumple_trigger )
{
    crumple_trigger endon( "cleanup_freezegun_triggers" );

    crumple_trigger waittill( "trigger" );

    self thread freezegun_do_crumple( weap, shatter_trigger, crumple_trigger );
}

freezegun_cleanup_freezegun_triggers( shatter_trigger, crumple_trigger )
{
    self notify( "cleanup_freezegun_triggers" );
    shatter_trigger notify( "cleanup_freezegun_triggers" );
    crumple_trigger notify( "cleanup_freezegun_triggers" );

    shatter_trigger self_delete();
    crumple_trigger self_delete();
}

// call this when we skip out of freezegun_death() to run the things we skipped in zombie_death_event()
freezegun_run_skipped_death_events()
{
    self thread maps\mp\zombies\_zm_audio::do_zombies_playvocals( "death", self.animname );
    self thread maps\mp\zombies\_zm_spawner::zombie_eye_glow_stop();
}

freezegun_death( hit_location, hit_origin, player )
{
    if ( self.isdog )
    {
        self freezegun_run_skipped_death_events();
        return;
    }

    if ( !self.has_legs )
    {
        
        if ( !self HasAnimStateFromASD( "zm_death_freeze_crawl_t5" ) )
        {
            self freezegun_run_skipped_death_events();
            return;
        }

        self.deathanim = "zm_death_freeze_crawl_t5";
    }
    else
    {
        if ( !self HasAnimStateFromASD( "zm_death_freeze_t5" ) )
        {
            self freezegun_run_skipped_death_events();
            return;
        }

        self.deathanim = "zm_death_freeze_t5";
    }

    self.freezegun_death = true;
    self.skip_death_notetracks = true;
    self.nodeathragdoll = true;
    
    self PlaySound( "wpn_freezegun_impact_zombie" );
    

    if ( IsPlayer( player ) )
    {
        if( RandomIntRange(0,101) >= 88 )
        {
            player maps\mp\zombies\_zm_audio::create_and_play_dialog( "kill", "freeze" );
        }
    }

    self thread freezegun_set_extremity_damage_fx();
    self thread freezegun_set_torso_damage_fx();

    shatter_trigger = spawn( "trigger_damage", self.origin, 0, 15, 72 );
    shatter_trigger enablelinkto();
    shatter_trigger linkto( self );

    spawnflags = 1 + 2 + 4 + 16 + 64; // SF_TOUCH_AI_AXIS | SF_TOUCH_AI_ALLIES | SF_TOUCH_AI_NEUTRAL | SF_TOUCH_VEHICLE | SF_TOUCH_ONCE
    crumple_trigger = spawn( "trigger_radius", self.origin, spawnflags, 15, 72 );
    crumple_trigger enablelinkto();
    crumple_trigger linkto( self );

    weap = self.damageweapon;
    self thread freezegun_wait_for_shatter( player, weap, shatter_trigger, crumple_trigger );
    self thread freezegun_wait_for_crumple( weap, shatter_trigger, crumple_trigger );
    self endon( "cleanup_freezegun_triggers" );

    wait(4); //T6 - Add artificial wait to better match original timing

    self thread freezegun_do_crumple( weap, shatter_trigger, crumple_trigger );
}

is_freezegun_damage( mod )
{
    // added for the water hazard
    if ( is_true( self.water_damage ) )
    {
        return true;
    }

    return ( isdefined(mod) && ("MOD_EXPLOSIVE" == mod || "MOD_PROJECTILE" == mod) && IsDefined( self.damageweapon ) && (self.damageweapon == "freezegun_zm" || self.damageweapon == "freezegun_upgraded_zm") );
}

is_freezegun_shatter_damage( mod )
{
    return ("MOD_EXPLOSIVE" == mod && IsDefined( self.damageweapon ) && (self.damageweapon == "freezegun_zm" || self.damageweapon == "freezegun_upgraded_zm"));
}

should_do_freezegun_death( mod )
{
    return is_freezegun_damage( mod );
}

enemy_damaged_by_freezegun()
{
    return 0 < self.freezegun_damage;
}

enemy_percent_damaged_by_freezegun()
{
    return self.freezegun_damage / self.maxhealth;
}

enemy_killed_by_freezegun()
{
    return ( IsDefined( self.freezegun_death ) && self.freezegun_death == true );
}

freezegun_zombie_death_response()
{
    if ( should_do_freezegun_death( self.damagemod ) )
    {
        self thread freezegun_death( self.damagelocation, self.origin, self.attacker );

        if ( "MOD_EXPLOSIVE" == self.damagemod )
        {
            // no points awarded for damage or deaths dealt by the shatter result
            return true;
        }
    }
    return false;
}

freezegun_zombie_damage_response( mod, hit_location, hit_origin, player, amount )
{
    if ( self is_freezegun_damage( self.damagemod ) )
    {
        self thread freezegun_damage_response( player, amount );
        return true;
    }   
    return false;
}

freezegun_death_event()
{
    // this gets called before the freezegun gets a chance to set freezegun_death, so we check whether it will do it
    if ( should_do_freezegun_death( self.damagemod ) )
    {
        self thread maps\mp\zombies\_zm_audio::do_zombies_playvocals( "death", self.animname );
        self thread maps\mp\zombies\_zm_spawner::zombie_eye_glow_stop();
    }   
    
    if ( maps\mp\zombies\_zm_weapons::is_weapon_included( "freezegun_zm" ) )
    {
        self thread freezegun_clear_extremity_damage_fx();
        self thread freezegun_clear_torso_damage_fx();
    }   
}
