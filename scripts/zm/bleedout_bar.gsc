// zm_qol: imported from pluto-t6zm-bleedout-bar (Nathan3197 / Stick Gaming).
//
// Two changes from upstream:
//  1. Includes were written with FORWARD slashes, which is another compiler's
//     dialect - T6 needs backslashes and gsc-tool rejects the file otherwise.
//     Same fix as wunderfizz.gsc and the _zm_magicbox override.
//  2. `maps\_utility` is a SINGLEPLAYER path and does not exist in zombies.
//     Dropped; nothing in this file needs it.
#include maps\mp\zombies\_zm_utility;
#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\zombies\_zm_spawner;
#include maps\mp\gametypes_zm\_hud_message;
#include maps\mp\gametypes_zm\_hud_util;

// This Script is only use for Stick Gaming Zombies server for Pluto T6 Zombies only
// Some code in the script have been use or remix from other people round the internet
// This script is not ment to be shared outside Stick Gaming Devs unless given premissing from Nathan3197
//
// Any contributors will be credited down below
// Nathan3197
// 
//
// Credit of use of other people code found on the internet
// 
//
// Big thanks to the pluto team for all there hard efforts to allow us to play BO2 with mods and servers.




init()
{
	BleedoutTimer = getDvarIntDefault("Bleedout_timer", 45 );
	reviveTrigger = getDvarIntDefault("revive_trigger", 75);
	// How long untill the player bleed out
	level.cmPlayerLaststandBleedoutTime = getDvarIntDefault( "cmPlayerLaststandBleedoutTime", int(BleedoutTimer) );
	setdvar( "player_lastStandBleedoutTime", level.cmPlayerLaststandBleedoutTime );
	//revive trigger radius size
	level.cmPlayerReviveTriggerRadius = getDvarIntDefault( "cmPlayerReviveTriggerRadius", int(reviveTrigger) );
	setdvar( "revive_trigger_radius", level.cmPlayerReviveTriggerRadius );
	level thread onplayerconnect();
}

onplayerconnect()
{
	level endon ("end_game");
	for ( ;; )
	{
        level waittill( "connected", player );
		player thread Bleedout_bar_startup(); // thread the AFK_listener
		player thread Bleedout_bar_End_game_fix();
	}
}

Bleedout_bar_startup()
{
	self endon( "dissable_bleedout_End_game" ); 
	self endon( "disconnect" ); 
	self endon("end_game");
	flag_wait( "initial_blackscreen_passed" ); // yeah we don't want this to run while the match is setting up
	//self iprintln("Bleed out bar setup"); // debuging
	
	// zm_qol: upstream flashed "Bleedout Bar V2.0 Created by Nathan3197" on screen
	// at every spawn. Default flipped to OFF so it does not interrupt the start of
	// a game - the attribution lives in this file's header and in the commit
	// instead. Set the "credits" dvar to 1 to bring the on-screen line back.
	credits = getDvarIntDefault( "credits", 0 );

	if(int(credits) == 1)
	{
		self iprintln("Bleedout Bar V2.0 Created by ^2Nathan3197");
	}
	//watching if player goes down
	self thread Bleedout_bar_hud_toggle();


}

Bleedout_bar_hud_toggle()
{
	level endon( "end_game" );
	self endon( "end_game" ); 
	self endon( "disconnect" ); 
	//self iprintln("bleedout_toggle"); //debuging
	//bleeding out timer
	for(;;)
	{
		//when player goes down we continue
		self waittill("player_downed");
		self.bleeding_Out = true;
		//creating the hud
		self thread bleedout_bar();
		//we wait till any of these to turn of the hud
		self waittill_any("player_revived","bled_out", "death");
		self.bleeding_Out = false;
		wait 1;
	}
}
Bleedout_bar_End_game_fix()
{
	self endon( "disconnect" );
	level waittill("end_game");
	//  zm_qol v1.99.6 - was an `&&` of both references, which tore down NEITHER
	//  element if only one existed. Now shares the one teardown helper with
	//  bleedout_bar(), which checks each independently and clears both.
	self bleedout_bar_destroy_hud();
	return;
}

bleedout_bar()
{
	self endon( "disconnect" );
	level endon("end_game");

	//  zm_qol v1.99.1 - THE HUD TAB TOGGLE, user request 2026-08-16.
	//  zm_qol v1.99.6 - MADE LIVE. See the note below; this is a real fix, not a
	//  tidy-up.
	//
	//  Read here and nowhere else. This is the one function that creates the hud
	//  elements, so OFF means nothing is drawn AND nothing is allocated - it does
	//  not merely hide the bar behind alpha 0. The caller
	//  (Bleedout_bar_hud_toggle) still sets and clears self.bleeding_Out either
	//  way, so the down/revive state machine is untouched.
	//
	//  Gating matches the rest of the HUD options: hud_master is the master
	//  override, hud_all forces the individual rows on. Same expression as
	//  quality_of_life::zmqol_powerup_timer_think().
	//
	//  ---------------------------------------------------------------------
	//  🛑 WHY THE CHECK MOVED INSIDE THE LOOP - user report, 2026-08-16
	//
	//  v1.99.1 read the dvar ONCE, above the element creation, and shipped with a
	//  note calling that acceptable ("takes effect on the very next down"). The
	//  user tested exactly that and it is NOT acceptable to them:
	//
	//    "if you have the bleedout bar enabled when you go down [...] and when you
	//     turn it off via the settings it wont update on screen and the bar will
	//     still be there [...] basically i cant update it to on or off realtime."
	//
	//  So the dvar is now polled every server frame while you are down, and the
	//  elements are created and destroyed to follow it. Both directions work:
	//  turn it off mid-down and the bar disappears; turn it back on and it comes
	//  straight back with the current count.
	//
	//  🌟 THE POLL DOES NOT ADD NETWORK TRAFFIC, and that is deliberate. The two
	//  writes (updateBar -> setshader, setvalue) are the parts that cost reliable
	//  commands, and they still happen only when the whole SECOND changes, which
	//  is the same ~1/sec the old `wait 1` produced. n_shown is what enforces
	//  that. Polling a dvar is a local read and costs nothing on the wire.
	//  (ERROR_CATALOGUE §7b - the 128-entry reliable ring is why this matters.)
	//
	//  🛑 Do NOT "simplify" this back to writing every pass.
	//  ---------------------------------------------------------------------
	//
	//  📝 The elements are destroyed on OFF rather than hidden, because
	//  createPrimaryProgressBar is not cheap: _hud_util::createbar makes THREE
	//  hudelems (bar, frame, background) and the text is a fourth. A client's
	//  allowance is finite and this mod already spends ~13 of it, so a player who
	//  has the row switched off must not be charged four.
	n_shown = -1;                       // last whole second written to the HUD

	while ( self.bleeding_Out == true )
	{
		b_want = ( self scripts\zm\zmqol_playeropt::zmqol_popt( "hud_master", 1 ) &&
		           ( self scripts\zm\zmqol_playeropt::zmqol_popt( "hud_all", 0 ) || self scripts\zm\zmqol_playeropt::zmqol_popt( "hud_bleedout_bar", 1 ) ) );

		if ( b_want && !isdefined( self.ProcessBar2 ) )
		{
			//self iprintln("bleedout bar new"); //debuging
			//we create a progress bar for the bleedout bar
			self.ProcessBar2 = createPrimaryProgressBar();
			self.ProcessBar2 setPoint("CENTER","CENTER",0,120);
			self.ProcessBar2.color = (0,0,0);
			self.ProcessBar2.bar.color = (1,0,0);
			self.ProcessBar2.alpha = 1;
			self.ProcessBar2.archived = 1;

			//we create a text displaying the bleedout timer
			self.Bleedout_text = newclienthudelem( self );
			self.Bleedout_text.x = 320;
			self.Bleedout_text.y = 345;
			self.Bleedout_text.alignx = "center";
			self.Bleedout_text.aligny = "middle";
			self.Bleedout_text.horzalign = "fullscreen";
			self.Bleedout_text.vertalign = "fullscreen";
			self.Bleedout_text.alpha = 1;
			self.Bleedout_text.archived = 1;
			self.Bleedout_text.fontscale = 1.2;
			self.Bleedout_text.hidewheninmenu = 1;
			self.Bleedout_text.label = &"Bleeding out in:^1 ";

			//  Force the first write, so a bar switched back on mid-down shows
			//  the live count immediately instead of staying blank for up to a
			//  second.
			n_shown = -1;
		}
		else if ( !b_want && isdefined( self.ProcessBar2 ) )
		{
			self bleedout_bar_destroy_hud();
		}

		if ( b_want )
		{
			n_now = int( self.bleedout_time );

			//  🛑 Only on change. See the note above.
			if ( n_now != n_shown )
			{
				self.ProcessBar2 updateBar( n_now / int( level.cmPlayerLaststandBleedoutTime ) );
				self.Bleedout_text setvalue( n_now );
				n_shown = n_now;
			}
		}

		wait 0.05;
	}
	//we destroy the hud so we free up hud elemets for other scripts
	//self iprintln("hud destorty"); //debuging
	self bleedout_bar_destroy_hud();
}

//  Tear the two (four, really) elements down and CLEAR THE REFERENCES.
//
//  🛑 The clearing is the point. bleedout_bar() now decides what to do from
//  isdefined( self.ProcessBar2 ), and Bleedout_bar_End_game_fix() has always
//  keyed off the same test, so a stale reference to a destroyed element would
//  either double-destroy or block the bar from ever coming back. Setting both
//  to undefined makes the test mean what it says regardless of what destroy()
//  does to the variable itself.
bleedout_bar_destroy_hud()
{
	if ( isdefined( self.ProcessBar2 ) )
	{
		self.ProcessBar2 destroyElem();
		self.ProcessBar2 = undefined;
	}

	if ( isdefined( self.Bleedout_text ) )
	{
		self.Bleedout_text destroy();
		self.Bleedout_text = undefined;
	}
}