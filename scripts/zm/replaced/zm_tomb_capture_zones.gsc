#include maps\mp\zm_tomb_capture_zones;
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zm_tomb_utility;
#include maps\mp\zombies\_zm_audio;
// set_players_dontspeak / set_player_dontspeak live here, and all_zones_captured_vo
// calls both unqualified. Verified against the stock dump, not assumed.
#include maps\mp\zm_tomb_vo;

// ============================================================================
//  ORIGINS SURVIVAL - the five zone-capture functions that must not run as
//  written when the map is played as a standalone arena.            (v2.14.0)
// ----------------------------------------------------------------------------
//  🛑 EVERY BODY BELOW IS STOCK maps\mp\zm_tomb_capture_zones, VERBATIM, WITH
//  ONE `is_classic()` EARLY RETURN ADDED. Classic Origins takes the stock path
//  in all five and is byte-for-byte unchanged - that is the whole design of
//  this file, and it is why it is five small functions and not a port of
//  Reimagined's 880-line replacement (which also rewrites the capture progress
//  rules, the objective indices and the recapture rounds - real changes to
//  CLASSIC Origins that nobody asked for).
//
//  --- WHY EACH ONE IS HERE ---------------------------------------------------
//
//  register_elements_powered_by_zone_capture_generators()
//      Stock hands every perk machine and mystery box to the generator zone
//      that owns it. On a survival arena no generator can be reached, so an
//      owned machine would be locked for the whole match. Worse, two of the
//      three stock helpers dereference their lookup immediately:
//      register_perk_machine_for_zone -> get_perk_machine_trigger_from_vending_entity
//      is getent( "vending_revive", "target" ), and nothing spawns those
//      entities on a location whose perk machines this mod registers itself -
//      so the FIRST call dies and takes the rest of setup_capture_zones() with
//      it, including pack_a_punch_init() and the two quick-revive watchers.
//      On non-classic we register nothing: every machine is then simply not
//      owned, which is what check_perk_machine_valid() below expects.
//
//  check_perk_machine_valid( player )
//      level.custom_perk_validation. Stock asserts str_zone_name and reads
//      level.zone_capture.zones[ that ] - undefined on a machine this mod
//      registered - then denies the buy. Returning 1 outside classic makes
//      every machine buyable with no generator involved, which is how Town and
//      Farm behave and what the user asked survival to feel like.
//
//  pack_a_punch_init()
//      Stock ghosts and un-solids the Pack-a-Punch machine at init; only the
//      capture-site animation brings it back, and that never plays on an arena
//      with no generators to capture. Outside classic the machine is left
//      visible and solid and only pack_a_punch_think() is threaded, so the
//      "all zones captured" path (this mod force-captures them at round start -
//      zm_tomb.gsc::zmqol_power_up_all_generators) still runs
//      pack_a_punch_enable() and sets the "power_on" flag the location script
//      waits on.
//
//  recapture_round_tracker()
//      From round 10 stock sends a group of "recapture zombies" to take a
//      generator back. Every generator on a survival arena is outside the
//      playable area, so the event would drag the round's zombies out of the
//      arena and put an objective marker somewhere unreachable.
//
//  all_zones_captured_vo()
//      The "all generators captured" story VO. This mod captures all six at
//      round start on survival, so stock would play Richtofen's line over the
//      first round of every match on an arena that has no generators in it.
// ============================================================================
//  ⭐ capture_zombies_only_attack_nearby_players  -  THE ORIGINS "ZOMBIES WALK
//  INTO ME AND DON'T ATTACK" BUG. THIS IS THE ONE.
//
//  User, 2026-09-16, on Church: *"the zombie attacked me once, i walked away a
//  little bit and then walked back towards him, and then he's just again just
//  walking into me and pushing me and not attacking me."* Origins only - the
//  transit family was fixed by removing the aitype overrides and stayed fixed.
//
//  🌟 MEASURED, NOT ARGUED. A per-zombie audit printed the same fields for a
//  zombie that DID attack and one that did not. Exactly one field differed:
//
//      ✅ OK        attacked after 2s    ignoreme=0  ignoreall=0
//      🛑 NO-ATTACK 11.5s, no damage     ignoreme=1  ignoreall=0
//
//  `ignoreme` is cleared in exactly ONE place in the whole tree -
//  _zm_ai_basic::find_flesh():24 - and that function opens with
//      self endon( "stop_find_flesh" );
//  So a zombie still holding ignoreme=1 is a zombie whose find_flesh thread is
//  NOT RUNNING. It keeps whatever goal it had, so it still walks at the player
//  and still shoves them, and it will never swing again.
//
//  🛑 AND THIS IS WHAT STOPS IT. Stock's loop, zm_tomb_capture_zones.gsc:1067:
//
//      while( true ) {
//          if( self should_capture_zombie_attack_generator( s_zone ) ) {
//              self notify( "stop_find_flesh" );          <- kills find_flesh
//              self.goalradius = 30;
//              self setgoalpos( self.attacking_point.origin );
//          }
//          wait 0.5;
//      }
//
//  It kills find_flesh and NEVER RESTARTS IT. On classic Origins that is
//  correct: the zombie has been told to go and smash a generator and the
//  capture system owns it from then on.
//
//  A SURVIVAL ARENA HAS NO GENERATOR TO CAPTURE - but the thread is still
//  started on every zombie in a capture zone and re-tests every half second.
//  Any zombie it catches loses find_flesh permanently and wanders off to a
//  generator attack point. That is, in the user's words across this whole
//  session: "some zombies attack normally and some refuse to acknowledge I
//  exist", "they stop targeting me and walk away to set locations", and an
//  attack that "stopped midway through".
//
//  📝 It also explains why it survived every earlier fix: nothing about it is
//  in the failsafes, the aitypes, no_bleedout, the robots or the zone list.
//
//  Same shape as the other five here - stock verbatim behind is_classic() - so
//  classic Origins is unchanged. On survival the loop simply never runs, which
//  leaves find_flesh alone and the zombie ordinary.
// ============================================================================
capture_zombies_only_attack_nearby_players( s_zone )
{
	self endon( "death" );

	//  🛑 SURVIVAL: DO NOTHING AT ALL. Returning here means the zombie is never
	//  told to stop finding flesh, so find_flesh keeps running and keeps
	//  ignoreme at 0 - an ordinary zombie that chases and swings.
	if ( !is_classic() )
		return;

	n_goal_radius = self.goalradius;

	while ( true )
	{
		self.goalradius = n_goal_radius;

		if ( self maps\mp\zm_tomb_capture_zones::should_capture_zombie_attack_generator( s_zone ) )
		{
			self notify( "stop_find_flesh" );
			self notify( "zombie_acquire_enemy" );
			self.goalradius = 30;

			if ( !isdefined( self.attacking_point ) )
				self.attacking_point = self maps\mp\zm_tomb_capture_zones::get_unclaimed_attack_point( s_zone );

			self setgoalpos( self.attacking_point.origin );
			self thread maps\mp\zm_tomb_capture_zones::cancel_generator_attack_if_player_gets_close_to_generator( s_zone );
			str_notify = self waittill_any_return( "goal", "stop_attacking_generator" );

			if ( isdefined( str_notify ) && str_notify == "stop_attacking_generator" )
				self.attacking_point maps\mp\zm_tomb_capture_zones::unclaim_attacking_point();
			else
			{
				self maps\mp\zm_tomb_capture_zones::play_melee_attack_animation();
				continue;
			}
		}

		wait 0.5;
	}
}

register_elements_powered_by_zone_capture_generators()
{
	if ( !is_classic() )
		return;

	register_random_perk_machine_for_zone( "generator_start_bunker", "starting_bunker" );
	register_perk_machine_for_zone( "generator_start_bunker", "revive", "vending_revive", ::revive_perk_fx_think );
	register_mystery_box_for_zone( "generator_start_bunker", "bunker_start_chest" );
	register_random_perk_machine_for_zone( "generator_tank_trench", "trenches_right" );
	register_mystery_box_for_zone( "generator_tank_trench", "bunker_tank_chest" );
	register_random_perk_machine_for_zone( "generator_mid_trench", "trenches_left" );
	register_perk_machine_for_zone( "generator_mid_trench", "sleight", "vending_sleight" );
	register_mystery_box_for_zone( "generator_mid_trench", "bunker_cp_chest" );
	register_random_perk_machine_for_zone( "generator_nml_right", "nml" );
	register_perk_machine_for_zone( "generator_nml_right", "juggernog", "vending_jugg" );
	register_mystery_box_for_zone( "generator_nml_right", "nml_open_chest" );
	register_random_perk_machine_for_zone( "generator_nml_left", "farmhouse" );
	register_perk_machine_for_zone( "generator_nml_left", "marathon", "vending_marathon" );
	register_mystery_box_for_zone( "generator_nml_left", "nml_farm_chest" );
	register_random_perk_machine_for_zone( "generator_church", "church" );
	register_mystery_box_for_zone( "generator_church", "village_church_chest" );
}

check_perk_machine_valid( player )
{
	if ( !is_classic() )
		return 1;

	if ( isdefined( self.script_noteworthy ) && isinarray( level.zone_capture.perk_machines_always_on, self.script_noteworthy ) )
		b_machine_valid = 1;
	else
	{
		assert( isdefined( self.str_zone_name ), "str_zone_name field missing on perk machine! This is required by the zone capture system!" );
		b_machine_valid = level.zone_capture.zones[self.str_zone_name] ent_flag( "player_controlled" );
	}

	if ( !b_machine_valid )
		player create_and_play_dialog( "lockdown", "power_off" );

	return b_machine_valid;
}

pack_a_punch_init()
{
	vending_weapon_upgrade_trigger = getentarray( "specialty_weapupgrade", "script_noteworthy" );
	level.pap_triggers = vending_weapon_upgrade_trigger;
	t_pap = getent( "specialty_weapupgrade", "script_noteworthy" );

	//  Not stock: outside classic there can be more than one of these (the
	//  location script registers its own machine inside the arena) and none of
	//  them may be hidden, because nothing on a survival arena ever plays the
	//  monolith assembly that would show it again.
	if ( !is_classic() )
	{
		println( "[zm_qol] tomb pap: survival - " + vending_weapon_upgrade_trigger.size + " pap trigger(s), machine left visible and solid" );
		level thread pack_a_punch_think();
		return;
	}

	t_pap.machine ghost();
	t_pap.machine notsolid();
	t_pap.bump enablelinkto();
	t_pap.bump linkto( t_pap );
	level thread pack_a_punch_think();
}

recapture_round_tracker()
{
	if ( !is_classic() )
		return;

	n_next_recapture_round = 10;

	while ( true )
	{
		level waittill_any( "between_round_over", "force_recapture_start" );

		if ( level.round_number >= n_next_recapture_round && !flag( "zone_capture_in_progress" ) && get_captured_zone_count() >= get_player_controlled_zone_count_for_recapture() )
		{
			n_next_recapture_round = level.round_number + randomintrange( 3, 6 );
			level thread recapture_round_start();
		}
	}
}

all_zones_captured_vo()
{
	if ( !is_classic() )
		return;

	flag_wait( "all_zones_captured" );
	flag_waitopen( "story_vo_playing" );
	set_players_dontspeak( 1 );
	flag_set( "story_vo_playing" );
	e_speaker = get_closest_player_to_richtofen();

	if ( isdefined( e_speaker ) )
	{
		e_speaker set_player_dontspeak( 0 );
		e_speaker create_and_play_dialog( "zone_capture", "all_generators_captured" );
		e_speaker waittill_any( "done_speaking", "disconnect" );
	}

	e_richtofen = get_player_named( "Richtofen" );

	if ( isdefined( e_richtofen ) )
	{
		e_richtofen set_player_dontspeak( 0 );
		e_richtofen create_and_play_dialog( "zone_capture", "all_generators_captured" );
	}

	set_players_dontspeak( 0 );
	flag_clear( "story_vo_playing" );
}
