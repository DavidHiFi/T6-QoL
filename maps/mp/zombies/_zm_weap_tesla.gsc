#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_net;

init()
{
    if ( !maps\mp\zombies\_zm_weapons::is_weapon_included( "tesla_gun_zm" ) && !is_true( level.uses_tesla_powerup ) )
    {
        return;
    }

    level._effect["tesla_bolt"]             = loadfx( "maps/zombie/fx_zombie_tesla_bolt_secondary" );
    level._effect["tesla_shock"]            = loadfx( "maps/zombie/fx_zombie_tesla_shock" );
    level._effect["tesla_shock_secondary"]  = loadfx( "maps/zombie/fx_zombie_tesla_shock_secondary" );

    level._effect["tesla_viewmodel_rail"]   = loadfx( "maps/zombie/fx_zombie_tesla_rail_view" );
    level._effect["tesla_viewmodel_tube"]   = loadfx( "maps/zombie/fx_zombie_tesla_tube_view" );
    level._effect["tesla_viewmodel_tube2"]  = loadfx( "maps/zombie/fx_zombie_tesla_tube_view2" );
    level._effect["tesla_viewmodel_tube3"]  = loadfx( "maps/zombie/fx_zombie_tesla_tube_view3" );
    level._effect["tesla_viewmodel_rail_upgraded"]  = loadfx( "maps/zombie/fx_zombie_tesla_rail_view_ug" );
    level._effect["tesla_viewmodel_tube_upgraded"]  = loadfx( "maps/zombie/fx_zombie_tesla_tube_view_ug" );
    level._effect["tesla_viewmodel_tube2_upgraded"] = loadfx( "maps/zombie/fx_zombie_tesla_tube_view2_ug" );
    level._effect["tesla_viewmodel_tube3_upgraded"] = loadfx( "maps/zombie/fx_zombie_tesla_tube_view3_ug" );

    // 🛑 A MOD-PRIVATE KEY, NOT THE STOCK ONE. This used to be
    // level._effect["tesla_shock_eyes"], and that one line changed how ELECTRIC
    // CHERRY looks on every map. Traced 2026-08-13 from the user's report that
    // "the electric cherry fx are a bit too bright and don't look quite vanilla":
    //
    //   stock _zm_spawner.gsc:261   every zombie gets .tesla_head_gib_func
    //   stock _zm_spawner.gsc:2976  zombie_tesla_head_gib() rolls
    //                               tesla_head_gib_chance; on the ELSE branch it
    //                               plays level._effect["tesla_shock_eyes"]
    //   stock _zm_perk_electric_cherry.gsc:170  a cherry kill calls that func
    //
    // In stock BO2 "tesla_shock_eyes" is loaded by exactly ONE script -
    // Origins' _zm_weap_staff_lightning.gsc:19 - so on every other map the key is
    // UNDEFINED and the else branch draws nothing. This script loads on every map,
    // so defining the stock key here added a bright electric eye burst to every
    // Electric Cherry kill on TranZit / Nuketown / Die Rise / Buried / Mob that
    // vanilla never shows there. The Wunderwaffe keeps the effect - it reaches it
    // through zmqol_tesla_head_gib() below, which reads this private key.
    level._effect["zmqol_tesla_shock_eyes"] = loadfx( "maps/zombie/fx_zombie_tesla_shock_eyes" );


    maps\mp\zombies\_zm_spawner::register_zombie_damage_callback( ::tesla_zombie_damage_response );
    maps\mp\zombies\_zm_spawner::register_zombie_death_animscript_callback( ::tesla_zombie_death_response );

    precacheshellshock( "electrocution" );
    
    // 🛑 10, NOT the port's 5. User: "in bo1 when you shoot a zombie with the
    // wunderwaffe it can chain up to 10 zombies, same as waw zombies". The ported
    // T5 source ships 5 and so does the reference implementation
    // (Wonder_Weapons-T6ZM :33) - this is a deliberate deviation on the user's
    // explicit instruction to match BO1/WaW, not a transcription error.
    // Still dvar-backed below as scr_tesla_max_arcs, so 5 is one command away.
    set_zombie_var( "tesla_max_arcs",           10 );
    set_zombie_var( "tesla_max_enemies_killed", 20 );
    set_zombie_var( "tesla_radius_start",       300 );
    set_zombie_var( "tesla_radius_decay",       20 );
    // 🛑 NOT set_zombie_var( "tesla_head_gib_chance", 75 ). That is a STOCK var and
    // Electric Cherry sets it to 50 in its own init (_zm_perk_electric_cherry.gsc:28).
    // Whichever init ran last decided the rate for BOTH, so the Wunderwaffe's 75 was
    // silently re-tuning a stock perk. The gun keeps its own rate, privately.
    level.zmqol_tesla_head_gib_chance = 75;
    //  🌟 v2.11.30 - 0.11 -> 0.5, MATCHING THE DLC5 PORT (and BO1, they agree).
    //
    //  Read out of Zombies Declassified's own zm_factory copy of this script -
    //  compiled Plutonium bytecode, decompiled with
    //      gsc-tool -m decomp -g t6 -s pc --t6fixup
    //  - whose init sets exactly 0.5, the same as BO1's
    //  <BO1>\raw\maps\_zombiemode_weap_tesla.gsc:37.
    //
    //  This is COSMETIC ONLY and does not slow the chain down. It is the MoveTo
    //  duration of the fxOrg carrying level._effect["tesla_bolt"] between two
    //  targets (tesla_play_arc_fx below), and the damage is threaded separately
    //  in tesla_arc_damage - `self thread tesla_do_damage(...)` - so selection
    //  and kills are unaffected. At 0.11 the bolt was a flicker; 0.5 is the
    //  visible arc jump the DLC5 port draws.
    //
    //  📝 The 0.11 arrived with the SRS import (f4c22d8) and was never chosen
    //  here. One line to put back if the trailing bolts read badly at 10 arcs.
    set_zombie_var( "tesla_arc_travel_time",    0.5, true );
    set_zombie_var( "tesla_kills_for_powerup",  15 );
    set_zombie_var( "tesla_min_fx_distance",    128 );
    set_zombie_var( "tesla_network_death_choke",4 );

/*
/#
    level thread tesla_devgui_dvar_think();
#/
*/

    OnPlayerConnect_Callback(::on_player_connect);
}

/*
/#
tesla_devgui_dvar_think()
{
    if ( maps\mp\zombies\_zm_weapons::is_weapon_included( "tesla_gun_zm" ) )
    {
        return;
    }

    SetDvar( "scr_tesla_max_arcs", level.zombie_vars["tesla_max_arcs"] ); 
    SetDvar( "scr_tesla_max_enemies", level.zombie_vars["tesla_max_enemies_killed"] ); 
    SetDvar( "scr_tesla_radius_start", level.zombie_vars["tesla_radius_start"] );
    SetDvar( "scr_tesla_radius_decay", level.zombie_vars["tesla_radius_decay"] );
    SetDvar( "scr_tesla_head_gib_chance", level.zombie_vars["tesla_head_gib_chance"] );
    SetDvar( "scr_tesla_arc_travel_time", level.zombie_vars["tesla_arc_travel_time"] );

    for ( ;; )
    {
        level.zombie_vars["tesla_max_arcs"]             = GetDvarInt( "scr_tesla_max_arcs" );
        level.zombie_vars["tesla_max_enemies_killed"]   = GetDvarInt( "scr_tesla_max_enemies" );
        level.zombie_vars["tesla_radius_start"]         = GetDvarInt( "scr_tesla_radius_start" );
        level.zombie_vars["tesla_radius_decay"]         = GetDvarInt( "scr_tesla_radius_decay" );
        level.zombie_vars["tesla_head_gib_chance"]      = GetDvarInt( "scr_tesla_head_gib_chance" );
        level.zombie_vars["tesla_arc_travel_time"]      = GetDvarFloat( "scr_tesla_arc_travel_time" );

        wait( 0.5 );
    }
}
#/
*/

tesla_damage_init( hit_location, hit_origin, player )
{
    player endon( "disconnect" );

    if ( isdefined( player.tesla_firing ) && player.tesla_firing )
    {
//      debug_print( "TESLA: Player: '" + player.name + "' currently processing tesla damage" );
        return;
    }

    // ========================================================================
    // 🛑 v1.95.2 - THIS CLEAR HAS TO HAPPEN BEFORE THE zombie_tesla_hit TEST
    // BELOW, AND ITS OLD CONDITION COULD NEVER BE TRUE.
    //
    // User, 2026-08-14: "i was shooting at brutus with the wunderwaffe it didn't
    // do anything at all when directly shooting him with it, the only way i could
    // damage him is if i shot a zombie near him and the zap from the waffe jumped
    // to him".
    //
    // 🌟 MEASURED: `tesla_damage_func` is ASSIGNED NOWHERE. Not in this file, not
    // anywhere in scripts\ or maps\, not in the stock T6 dump, and not in either
    // donor (SRS_T5_WonderWeapons_portable, Wonder_Weapons-T6ZM) - it is only
    // ever READ, in five places. So the loop this replaces was gated on a field
    // that is always undefined and its body never executed once. It was written
    // specifically to unflag surviving bosses and it never unflagged anything.
    //
    // WHAT THAT PRODUCED, exactly as reported:
    //   - tesla_flag_hit() sets zombie_tesla_hit = true on every arc candidate.
    //   - A normal zombie dies, so the flag dies with the entity.
    //   - Brutus SURVIVES, so he stays flagged. The only other place the flag is
    //     ever cleared is the arc-cap early-out in tesla_arc_damage().
    //   - A DIRECT hit then enters this function with self == Brutus and takes
    //     the `self.zombie_tesla_hit` early return two lines down: the shot does
    //     nothing whatsoever, no damage, no arc, no boss hook.
    //   - Shooting a nearby ZOMBIE enters with self == that zombie, which is not
    //     flagged, so the shot proceeds and the arc reaches Brutus. That is
    //     precisely the one thing the user found that works.
    //
    // THE FIX: a new shot clears the per-shot flag on every AI that is still
    // ALIVE. That is what "per-shot" was always supposed to mean, and it is the
    // author's own intent with the dead condition removed.
    //
    // 🛑 THE isalive() TEST IS LOAD-BEARING, not decoration. It preserves the
    // original protection below verbatim: an AI already marked for tesla death
    // is dead or dying, so it is NOT cleared here and the early return still
    // catches it. Only survivors are freed. Clearing unconditionally would
    // re-arm a corpse mid-death.
    // ========================================================================
    a_alive = srs_ww_target_array();

    for ( i = 0; i < a_alive.size; i++ )
    {
        if ( IsDefined( a_alive[i] ) && IsAlive( a_alive[i] ) )
        {
            a_alive[i].zombie_tesla_hit = false;
        }
    }

    if ( IsDefined( self.zombie_tesla_hit ) && self.zombie_tesla_hit )
    {
        // can happen if an enemy is marked for tesla death and player hits again with the tesla gun
        return;
    }

//  debug_print( "TESLA: Player: '" + player.name + "' hit with the tesla gun" );

    //TO DO Add Tesla Kill Dialog thread....

    player.tesla_enemies = undefined;
    player.tesla_enemies_hit = 1;
    player.tesla_powerup_dropped = false;
    player.tesla_arc_count = 0;
    player.tesla_firing = 1;    

    self tesla_arc_damage( self, player, 1 );
    
    if ( player.tesla_enemies_hit >= 4)
    {
        player thread tesla_killstreak_sound();
    }

    player.tesla_enemies_hit = 0;
    player.tesla_firing = 0;
}

// this enemy is in the range of the source_enemy's tesla effect
tesla_arc_damage( source_enemy, player, arc_num )
{
    player endon( "disconnect" );

//  debug_print( "TESLA: Evaulating arc damage for arc: " + arc_num + " Current enemies hit: " + player.tesla_enemies_hit );

    tesla_flag_hit( self, true );
    wait_network_frame();

    radius_decay = level.zombie_vars["tesla_radius_decay"] * arc_num;

    // srs_tesla_node_origin, not a bare GetTagOrigin("j_head"). This is the origin the NEXT hop is
    // measured from, and an AI whose model has no j_head returned undefined here -- which made it a
    // dead end: the arc could reach it and then never continue to anything beyond it. The candidate
    // scan already had this fallback; the node doing the scanning did not. That is what stopped the
    // chain at the Avogadro instead of carrying on to nearby zombies and screechers.
    enemies = tesla_get_enemies_in_area( srs_tesla_node_origin( self ), level.zombie_vars["tesla_radius_start"] - radius_decay, player );
    tesla_flag_hit( enemies, true );

    self thread tesla_do_damage( source_enemy, arc_num, player );

//  debug_print( "TESLA: " + enemies.size + " enemies hit during arc: " + arc_num );
            
    for( i = 0; i < enemies.size; i++ )
    {
        if ( enemies[i] == self )
        {
            continue;
        }
        
        if ( tesla_end_arc_damage( arc_num + 1, player.tesla_enemies_hit ) )
        {           
            tesla_flag_hit( enemies[i], false );
            continue;
        }

        player.tesla_enemies_hit++;
        enemies[i] tesla_arc_damage( self, player, arc_num + 1 );
    }
}

tesla_end_arc_damage( arc_num, enemies_hit_num )
{
    if ( arc_num >= level.zombie_vars["tesla_max_arcs"] )
    {
//      debug_print( "TESLA: Ending arcing. Max arcs hit" );
        return true;
        //TO DO Play Super Happy Tesla sound
    }

    if ( enemies_hit_num >= level.zombie_vars["tesla_max_enemies_killed"] )
    {
//      debug_print( "TESLA: Ending arcing. Max enemies killed" );      
        return true;
    }

    radius_decay = level.zombie_vars["tesla_radius_decay"] * arc_num;
    if ( level.zombie_vars["tesla_radius_start"] - radius_decay <= 0 )
    {
//      debug_print( "TESLA: Ending arcing. Radius is less or equal to zero" );
        return true;
    }

    return false;
    //TO DO play Tesla Missed sound (sad)
}

tesla_get_enemies_in_area( origin, distance, player )
{
/*
    /#
        level thread tesla_debug_arc( origin, distance );
    #/
*/

    distance_squared = distance * distance;
    enemies = [];

    if ( !IsDefined( player.tesla_enemies ) )
    {
        player.tesla_enemies = srs_ww_target_array();
        player.tesla_enemies = get_array_of_closest( origin, player.tesla_enemies );
    }

    zombies = player.tesla_enemies; 

    if ( IsDefined( zombies ) )
    {
        for ( i = 0; i < zombies.size; i++ )
        {
            if ( !IsDefined( zombies[i] ) )
            {
                continue;
            }

            test_origin = srs_tesla_node_origin( zombies[i] );


            if ( IsDefined( zombies[i].zombie_tesla_hit ) && zombies[i].zombie_tesla_hit == true )
            {

                continue;
            }

            // A bespoke tesla_damage_func means something deliberately handles this AI, so it
            // outranks the blanket shield skip.
            if ( is_magic_bullet_shield_enabled( zombies[i] ) && !IsDefined( zombies[i].tesla_damage_func ) )
            {

                continue;
            }

            if ( DistanceSquared( origin, test_origin ) > distance_squared )
            {

                continue;
            }

            if ( !BulletTracePassed( origin, test_origin, false, undefined ) )
            {

                continue;
            }


            enemies[enemies.size] = zombies[i];
        }
    }


    // NOTE (2026-08-02): a second pass used to live here, re-adding any AI with a bespoke
    // tesla_damage_func in case the filters above dropped it. An in-game probe proved that
    // unnecessary -- Brutus is already added by the loop above on the first arc (the probe
    // reported him 'already-in-list'). Targeting was never the fault; removed rather than left
    // in place looking load-bearing. The remaining Brutus-vs-arc issue is downstream, in
    // tesla_do_damage or the tesla_arc_damage recursion.

    return enemies;
}

tesla_flag_hit( enemy, hit )
{
    if ( IsArray( enemy ) )
    {
        for( i = 0; i < enemy.size; i++ )
        {
            enemy[i].zombie_tesla_hit = hit;
        }
    }
    else
    {
        enemy.zombie_tesla_hit = hit;
    }
}


tesla_do_damage( source_enemy, arc_num, player )
{
    player endon( "disconnect" );

    // v1.93.0 - BOSSES FIRST, same hook as the thundergun and the freeze gun.
    // The Wunderwaffe's health+666 was being scaled to 10% by Brutus's own
    // actor_damage_func and never came close to killing him - the "no effect"
    // the user reported. Installed per-map so this root file never references
    // a Mob-only script. See zmqol_brutus_ww_hit() in zm_prison.gsc.
    if ( isdefined( level.zmqol_ww_boss_hit ) )
    {
        b_handled = self [[ level.zmqol_ww_boss_hit ]]( player );

        if ( b_handled )
            return;
    }

    // 🛑 THE DELAYED-KILL BUG. User, 2026-08-11: "in bo1 when you shoot a zombie
    // with the wunderwaffe it can chain up to 10 zombies, same as waw zombies, and
    // it's basically instantaneous, i just shot a few zombies in even just small
    // hoards and sometimes it'll kill the zombie next to the one i shot and then
    // it'll chain back to the first zombie i shot and it'll essentially be a
    // delayed kill."
    //
    // The chain never actually revisits a target - tesla_get_enemies_in_area()
    // skips anything with .zombie_tesla_hit set, and that check is intact. What the
    // user is seeing is this WAIT. Targets are SELECTED instantly but their damage
    // was applied on a per-arc stagger of randomfloatrange( 0.2, 0.6 ) * arc_num,
    // so arc 2 landed 0.2-0.6s late and arc 3 up to 1.2s late. With the fx timed
    // against the damage rather than the selection, the kills appear out of order
    // and read as the arc bouncing backwards.
    //
    // 📝 This value is FAITHFUL to the port's source - the reference implementation
    // at Wonder_Weapons-T6ZM carries the identical line (its :261) and the identical
    // tesla_max_arcs of 5. So this is a deliberate DEVIATION from the T5 script,
    // made on the user's explicit and repeated instruction that BO1/WaW parity is
    // the target: "Make it on par with the real wunderwaffe... from bo1."
    //
    // 🌟 v2.11.30 - THE STAGGER IS BACK ON BY DEFAULT, BY DECISION.
    //
    // Everything above is the history of why it was turned OFF in the first
    // place, and it is kept because it is still the reason the dvar exists.
    // What changed is the target: the user asked for this gun to match the DLC5
    // port's logic, and DLC5 carries this exact wait. Read out of Zombies
    // Declassified's own zm_factory copy (compiled bytecode, decompiled with
    // gsc-tool -m decomp -g t6 -s pc --t6fixup), tesla_do_damage opens with:
    //       if ( arc_num > 1 )
    //           wait( randomfloatrange( 0.2, 0.6 ) * arc_num );
    // - identical to BO1's <BO1>\raw\maps\_zombiemode_weap_tesla.gsc.
    //
    // 🛑 ASKED AND ANSWERED, 2026-09-04: restoring this alone would have meant
    // dropping the chain from 10 back to DLC5's 5 as well. The user chose
    // "DLC5 timing, keep 10 chain" - so tesla_max_arcs STAYS at 10 (see init)
    // and only the timing moves. They were told the consequence up front: the
    // stagger scales with arc_num, so on a full 10-deep chain the last kill can
    // land ~6s after the shot.
    //
    // Still one console command either way:
    //   scr_tesla_arc_delay 1     DLC5 / BO1 stagger (default as of v2.11.30)
    //   scr_tesla_arc_delay 0     instantaneous, the v2.9.x behaviour
    if ( arc_num > 1 && getdvarintdefault( "scr_tesla_arc_delay", 1 ) )
    {
        wait( randomfloatrange( 0.2, 0.6 ) * arc_num );
    }
    else if ( arc_num > 1 )
    {
        // One server frame so the arcs still resolve in order and the fx have a
        // frame to spawn - not a gameplay delay.
        wait 0.05;
    }

    if ( !IsDefined( self ) || !IsAlive( self ) )
    {
        // guy died on us 
        return;
    }

    // Death-anim selection applies only to an AI this arc is about to kill outright. An AI with a
    // bespoke tesla_damage_func survives and never uses deathanim, so it must skip this block --
    // otherwise the ASD check below returns and the thread dies before the hook at the bottom of
    // this function is ever consulted. That was the Brutus bug: zm_death_tesla_t5 is the T5 death
    // state carried on the regular zombie ASD, Brutus runs his own animset and has no such state,
    // so every arc that reached him returned here silently -- no fx, no damage, while arcs still
    // spread FROM him because that recursion is a direct call in tesla_arc_damage, not this thread.
    // _zm_weap_freezegun.gsc has the identical ASD gate but consults its per-entity hook at :427,
    // BEFORE the gate -- which is exactly why the freeze gun worked on Brutus and this did not.
    // An AI missing the T5 death state gets NO death anim -- but it must still take the damage.
    // Stock returned here instead, which silently made the arc a no-op against anything running its
    // own animstatedef. Only the per-map *_basic ASDs were given the T5 states by the wonder-weapon
    // port; every special AI has its own file that was never patched (verified against the stock
    // zones: zm_highrise_leaper, zm_transit_screecher, zm_transit_avogadro, zm_alcatraz_brutus,
    // zm_tomb_mechz -- all lack it. zm_nuked_dog lacks it too; an earlier note here claimed it was
    // patched, which was WRONG -- verified 0 hits on 2026-08-03. It does not matter, because dogs
    // take the isdog branch above and never reach the check, but do not repeat the claim).
    // Degrading to "normal death, full damage" is strictly better than "gun does nothing",
    // and it covers any future special without needing a per-entity hook.
    b_no_death_anim = false;

    if ( !IsDefined( self.tesla_damage_func ) )
    {
        if ( !self.isdog )
        {
            if ( self.has_legs )
            {
                if ( !self HasAnimStateFromASD( "zm_death_tesla_t5" ) )
                {
                    b_no_death_anim = true;
                }
                else
                {
                    self.deathanim = "zm_death_tesla_t5";
                }
            }
            else
            {
                if ( !self HasAnimStateFromASD( "zm_death_tesla_crawl_t5" ) )
                {
                    b_no_death_anim = true;
                }
                else
                {
                    self.deathanim = "zm_death_tesla_crawl_t5";
                }
            }
        }
        else
        {
            self.a.nodeath = undefined;
        }

        if( is_true( self.is_traversing))
        {
            self.deathanim = undefined;
        }
    }

    if( source_enemy != self )
    {
        if ( player.tesla_arc_count > 3 )
        {
            wait_network_frame();
            player.tesla_arc_count = 0;
        }
        
        player.tesla_arc_count++;
        source_enemy tesla_play_arc_fx( self );
    }

    while ( player.tesla_network_death_choke > level.zombie_vars["tesla_network_death_choke"] )
    {
//      debug_print( "TESLA: Choking Tesla Damage. Dead enemies this network frame: " + player.tesla_network_death_choke );     
        wait( 0.05 ); 
    }

    if( !IsDefined( self ) || !IsAlive( self ) )
    {
        // guy died on us 
        return;
    }

    player.tesla_network_death_choke++;

    self.tesla_death = true;
    // Bespoke handler runs BEFORE the fx. tesla_play_death_fx plays on tag "J_SpineUpper" (or
    // J_Spine1 for dogs) and an AI whose model lacks that tag would take the thread down with it,
    // so ordering the damage first means a missing tag can cost the effect but never the damage.
    // NOTE: this ordering was NOT the Brutus fix -- it shipped in cd5d8068 and changed nothing,
    // because the thread was already returning at the death-anim gate further up. Kept as hygiene.
    if ( IsDefined( self.tesla_damage_func ) )
    {
        v_src = player.origin;

        if ( IsDefined( source_enemy ) && source_enemy != self )
        {
            v_src = source_enemy.origin;
        }

        self [[ self.tesla_damage_func ]]( v_src, player );

        // NOT lethal. An AI with a bespoke tesla_damage_func is by definition one that handles the
        // arc itself and lives -- the Avogadro's avogadro_overload_trigger deals no damage at all.
        // Passing true here pops the head of an AI that is still walking around.
        self tesla_play_death_fx( arc_num, false );
        return;
    }

    // use the origin of the arc orginator so it pics the correct death direction anim
    origin = source_enemy.origin;

    if ( isdefined(source_enemy) || source_enemy == self )
    {
        origin = player.origin;
    }

    if ( b_no_death_anim )
    {
        // No death anim to sell the kill, so the fx is pure garnish -- do the damage FIRST. Same
        // reasoning as the hook branch above: tesla_play_death_fx plays on tag "J_SpineUpper", and
        // an AI running its own animstatedef is exactly the kind that might not carry it. This way
        // a missing tag costs the effect and never the kill.
        self DoDamage( self.health + 666, origin, player );

        // Reached ONLY when DoDamage( health + 666 ) failed to kill -- i.e. this AI survives lethal
        // damage. So this is the not-lethal case too, and the gib must stay off for the same reason
        // as the hook branch above.
        if ( IsDefined( self ) && IsAlive( self ) )
        {
            self tesla_play_death_fx( arc_num, false );
        }
    }
    else
    {
        // Stock ordering, unchanged, for AI that HAS the death anim -- the fx is timed against it.
        self tesla_play_death_fx( arc_num );

        if( !IsDefined( self ) || !IsAlive( self ) )
        {
            // guy died on us
            return;
        }

        self DoDamage( self.health + 666, origin, player );
    }

    // (stock had a second tesla_damage_func branch here; it was unreachable -- the hook branch
    //  above returns -- so it went out with the restructure rather than being left to mislead.)


    if(!(isdefined(self.deathpoints_already_given) && self.deathpoints_already_given))
    {
        self.deathpoints_already_given = 1;
        player maps\mp\zombies\_zm_score::player_add_points( "death", "", "" );
    }

//  if ( !player.tesla_powerup_dropped && player.tesla_enemies_hit >= level.zombie_vars["tesla_kills_for_powerup"] )
//  {
//      player.tesla_powerup_dropped = true;
//      level.zombie_vars["zombie_drop_item"] = 1;
//      level thread maps\mp\zombies\_zm_powerups::powerup_drop( self.origin );
//  }
}

// b_lethal: is the caller actually about to kill this AI? Defaults true, so the stock lethal
// path is unchanged. THE HEAD GIB IS A DEATH EFFECT AND DOES NOT KILL. zombie_tesla_head_gib
// (stock _zm_spawner.gsc) waits 0.53-1.0s and then calls zombie_head_gib, whose only damage is
// damage_over_time( health * 0.2 ) -- 20%, non-lethal. It relies entirely on the caller landing
// the kill afterwards. Play it on an AI that SURVIVES and you get a living headless zombie, which
// is what Hans saw in TranZit on 2026-08-03. Two callers below survive by design; they pass false.
tesla_play_death_fx( arc_num, b_lethal )
{
    if ( !IsDefined( b_lethal ) )
    {
        b_lethal = true;
    }

    tag = "J_SpineUpper";
    fx = "tesla_shock";

    if ( self.isdog )
    {
        tag = "J_Spine1";
    }

    if ( arc_num > 1 )
    {
        fx = "tesla_shock_secondary";
    }

    network_safe_play_fx_on_tag( "tesla_death_fx", 2, level._effect[fx], self, tag );
    self playsound( "wpn_imp_tesla" );

    if ( b_lethal && IsDefined( self.tesla_head_gib_func ) && !self.head_gibbed )
    {
        // Deliberately NOT [[ self.tesla_head_gib_func ]](). That pointer is stock's
        // zombie_tesla_head_gib(), which Electric Cherry also calls - so anything this
        // port wanted from it (a 75% gib rate, the eye fx) landed on the perk too.
        // Same behaviour, read out of this script's own vars instead. See init().
        self zmqol_tesla_head_gib();
    }
}

// A private copy of stock zombie_tesla_head_gib() (_zm_spawner.gsc:2976), identical
// except that the gib chance and the eye fx come from this script's own keys rather
// than the two stock globals Electric Cherry shares. The 0.53-1.0s wait, the
// quad_zombie guard and zombie_head_gib() are stock's, unchanged.
zmqol_tesla_head_gib()
{
    self endon( "death" );

    if ( self.animname == "quad_zombie" )
    {
        return;
    }

    if ( randomint( 100 ) < level.zmqol_tesla_head_gib_chance )
    {
        wait( randomfloatrange( 0.53, 1.0 ) );
        self maps\mp\zombies\_zm_spawner::zombie_head_gib();
    }
    else
    {
        network_safe_play_fx_on_tag( "tesla_death_fx", 2, level._effect["zmqol_tesla_shock_eyes"], self, "J_Eyeball_LE" );
    }
}

tesla_play_arc_fx( target )
{
    if ( !IsDefined( self ) || !IsDefined( target ) )
    {
        // TODO: can happen on dog exploding death
        wait( level.zombie_vars["tesla_arc_travel_time"] );
        return;
    }
    
    tag = "J_SpineUpper";

    if ( self.isdog )
    {
        tag = "J_Spine1";
    }

    target_tag = "J_SpineUpper";

    if ( target.isdog )
    {
        target_tag = "J_Spine1";
    }
    
    origin = self GetTagOrigin( tag );
    target_origin = target GetTagOrigin( target_tag );
    distance_squared = level.zombie_vars["tesla_min_fx_distance"] * level.zombie_vars["tesla_min_fx_distance"];

    if ( DistanceSquared( origin, target_origin ) < distance_squared )
    {
//      debug_print( "TESLA: Not playing arcing FX. Enemies too close." );      
        return;
    }
    
    fxOrg = Spawn( "script_model", origin );
    fxOrg SetModel( "tag_origin" );

    fx = PlayFxOnTag( level._effect["tesla_bolt"], fxOrg, "tag_origin" );
    playsoundatposition( "wpn_tesla_bounce", fxOrg.origin );
    
    fxOrg MoveTo( target_origin, level.zombie_vars["tesla_arc_travel_time"] );
    fxOrg waittill( "movedone" );
    fxOrg delete();
}

/*
tesla_debug_arc( origin, distance )
{
/#
    if ( GetDvarInt( "zombie_debug" ) != 3 )
    {
        return;
    }

    start = GetTime();

    while( GetTime() < start + 3000 )
    {
        drawcylinder( origin, distance, 1 );
        wait( 0.05 ); 
    }
#/
}
*/

is_tesla_damage( mod )
{
    return ( ( IsDefined( self.damageweapon ) && (self.damageweapon == "tesla_gun_zm" || self.damageweapon == "tesla_gun_upgraded_zm" ) ) && ( mod == "MOD_PROJECTILE" || mod == "MOD_PROJECTILE_SPLASH" ) );
}

enemy_killed_by_tesla()
{
    return ( IS_TRUE( self.tesla_death ) );     
}

on_player_connect()
{
    self thread tesla_sound_thread(); 
    self thread tesla_pvp_thread();
    self thread tesla_network_choke();
}

tesla_sound_thread()
{
    self endon( "disconnect" );

    for( ;; )
    {
        result = self waittill_any_return( "grenade_fire", "death", "player_downed", "weapon_change", "grenade_pullback", "disconnect" );     

        if ( !IsDefined( result ) )
        {
            continue;
        }

        if( ( result == "weapon_change" || result == "grenade_fire" ) && (self GetCurrentWeapon() == "tesla_gun_zm" || self GetCurrentWeapon() == "tesla_gun_upgraded_zm") )
        {
            if(!isdefined(self.tesla_loop_sound))
            {
                self.tesla_loop_sound = spawn("script_origin", self.origin);
                self.tesla_loop_sound linkto(self);
                self thread cleanup_loop_sound(self.tesla_loop_sound);
            }

            // 🛑 THE CONSTANT HUM. User, twice: "there's this constant sound
            // eminating from it even when i'm not shooting, that's not regular
            // wunderwaffe behaviour."
            //
            // wpn_tesla_idle is a LOOP that runs for as long as the DG-2 is the
            // active weapon - it starts on weapon_change and only stops when you
            // switch away. The ported T5 script does this and so does the reference
            // implementation; it is faithful, but the user has called it wrong
            // twice, so it is OFF by default here and restorable with one command:
            //   scr_tesla_idle_loop 0    silent while held (default)
            //   scr_tesla_idle_loop 1    restores the ported idle hum
            if ( getdvarintdefault( "scr_tesla_idle_loop", 0 ) )
                self.tesla_loop_sound PlayLoopSound( "wpn_tesla_idle", 0.25 );

            self thread tesla_engine_sweets();
            continue;
        }

        self notify ("weap_away");

        if(isdefined(self.tesla_loop_sound))
        {
            self.tesla_loop_sound StopLoopSound(0.25);
        }
    }
}

cleanup_loop_sound(loop_sound)
{
    self waittill("disconnect");

    if(isdefined(loop_sound))
    {
        loop_sound delete();
    }
}

tesla_engine_sweets()
{
    self endon( "disconnect" ); 
    self endon("weap_away");

    while(1)
    {
        wait(randomintrange(7,15));
        self play_tesla_sound ("wpn_tesla_sweeps_idle");
    }
}

tesla_pvp_thread()
{
    self endon( "disconnect" );
    self endon( "death" );

    for( ;; )
    {
        self waittill( "weapon_pvp_attack", attacker, weapon, damage, mod );

        if( self maps\mp\zombies\_zm_laststand::player_is_in_laststand() )
        {
            continue;
        }

        if ( weapon != "tesla_gun_zm" && weapon != "tesla_gun_upgraded_zm" )
        {
            continue;
        }

        if ( mod != "MOD_PROJECTILE" && mod != "MOD_PROJECTILE_SPLASH" )
        {
            continue;
        }

        if ( self == attacker )
        {
            damage = int( self.maxhealth * .25 );
            if ( damage < 25 )
            {
                damage = 25;
            }

            if ( self.health - damage < 1 )
            {
                self.health = 1;
            }
            else
            {
                self.health -= damage;
            }
        }

        self setelectrified( 1 ); 
        self shellshock( "electrocution", 1 );
        self playsound( "wpn_tesla_bounce" );
    }
}

play_tesla_sound(emotion)
{
    self endon( "disconnect" );

    if (!IsDefined (level.one_emo_at_a_time))
    {
        level.one_emo_at_a_time = 0;
        level.var_counter = 0;  
    }

    if (level.one_emo_at_a_time == 0)
    {
        level.var_counter ++;
        level.one_emo_at_a_time = 1;
        org = spawn("script_origin", self.origin);
        org LinkTo(self);
        org PlaySoundWithNotify (emotion, "sound_complete"+ "_"+level.var_counter);
        org waittill("sound_complete"+ "_"+level.var_counter);
        org delete();
        level.one_emo_at_a_time = 0;
    }       
}

tesla_killstreak_sound()
{
    self endon( "disconnect" );

    //TUEY Play some dialog if you kick ass with the Tesla gun

    self maps\mp\zombies\_zm_audio::create_and_play_dialog( "kill", "tesla" );  
    wait(3.5);
    level clientNotify ("TGH");
}

tesla_network_choke()
{
    self endon( "disconnect" );
    self endon( "death" );
    self waittill( "spawned_player" ); 

    self.tesla_network_death_choke = 0;

    for ( ;; )
    {
        wait_network_frame();
        wait_network_frame();
        self.tesla_network_death_choke = 0;
    }
}

tesla_zombie_death_response()
{
    if ( self enemy_killed_by_tesla() )
    {
        return true;
    }
    
    return false;
}

tesla_zombie_damage_response( mod, hit_location, hit_origin, player, amount )
{
    if ( self is_tesla_damage( mod ) )
    {
        self thread tesla_damage_init( hit_location, hit_origin, player );
        return true;
    }
    return false;
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

// Where an arc enters and leaves a given AI. Not every hostile model carries a j_head -- the bosses
// and specials mostly do not -- and an undefined origin here silently broke arcing in two separate
// ways: as a CANDIDATE the AI fell out at the DistanceSquared test (this is what kept the Wunderwaffe
// off Brutus), and as a SCANNING NODE it became a dead end that the chain could reach but never pass
// through. One helper for both so the two can never drift apart again.
srs_tesla_node_origin( ai )
{
    if ( !IsDefined( ai ) )
        return undefined;

    org = ai GetTagOrigin( "j_head" );

    if ( IsDefined( org ) )
        return org;

    return ai getcentroid();
}


