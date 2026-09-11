// ============================================================================
//  qol_options  -  console-configurable options, adapted from BO2-Remix
// ============================================================================
//  Adds the dvars the user asked for from BO2-Remix and NOTHING else
//  from that mod. Explicitly NOT ported: the walker removal, the power-up
//  rework, the bank/perma-perk/fridge/box patches, the round-255 and points
//  changes, the strat tester. Those are gameplay changes; this file is options.
//
//  Every GAMEPLAY option here is OFF by default, so a fresh install plays
//  exactly as it did before any of this existed. The HUD readouts are the
//  exception and always were: hud_timers, hud_health_bar and hud_remaining ship
//  on. (hud_timers was hud_timer + hud_round_timer until v2.1.3; the round
//  timer joined the defaults in v1.84.0 at the user's request.)
//
//  🛑 THREE THINGS WERE VERIFIED AGAINST THE SHIPPED GAME BEFORE BEING WRITTEN,
//  because each is the class of bug that has already cost this project a
//  release apiece - a name that reads fine and resolves to nothing:
//
//    1. strTok, string_to_float, getdvarintdefault are all real T6 builtins
//       (113 / 4 / 120 uses in the stock dump). array_slice, which an earlier
//       draft of the .help fix used, is NOT - it has zero uses and would have
//       failed at runtime.
//    2. The character models Remix hardcodes DO NOT EXIST on every map.
//       Unlinker --list across Farm's loaded zones finds only
//       c_zom_player_cdc_fb and c_zom_player_cia_fb - survival uses the CDC/CIA
//       teams, not the TranZit crew - so Remix's setmodel( "c_zom_player_
//       oldman_fb" ) would give an INVISIBLE PLAYER there. See qol_opt_character.
//    3. A client's HUD-element allowance is finite and this mod already spends
//       ~13 of it. That is what silently truncated the .help panel. So the two
//       NEW hud elements here are created only when their dvar is on, and never
//       on a player who has not asked for them.
// ============================================================================

#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\gametypes_zm\_hud_util;

init()
{
    //  ========================================================================
    //  🛑 v1.95.5 - THE BISECT SWITCH WAS UNUSABLE AND THAT IS WHY IT HAS NEVER
    //  PRODUCED AN ANSWER.
    //
    //  zmqol_minimal shipped in v1.95.1 as a plain getdvarintdefault() read with
    //  no registration anywhere. An UNREGISTERED dvar does not exist until
    //  something creates it, so typing `zmqol_minimal 1` at the console is not a
    //  dvar assignment - it is an unknown command, and it silently does nothing.
    //
    //  🌟 MEASURED, not assumed: the 2026-08-14 Origins crash log's dvar dump
    //  lists `zmqol_loadmovie_probe` and every other zmqol_* the mod creates, and
    //  contains NO `zmqol_minimal` line at all. The user set it and it never
    //  existed. Two boots were spent on a switch that could not be thrown.
    //
    //  Registering it here fixes that: it is created at 0 on the first load, and
    //  qol_opt_dvar only writes when the value is empty, so a console `1` set
    //  afterwards survives into the next map. The print below then puts the
    //  answer in the log, so "was it actually on?" is never a guess again.
    //  ========================================================================
    qol_opt_dvar( "zmqol_minimal",         "0" );
    println( "[zm_qol] minimal mode: " + zmqol_minimal() + "  (1 = all 18 periodic threads disabled)" );

    //  Registered up front so they all show up in the console's autocomplete
    //  even before anything reads them.
    qol_opt_dvar( "rapid_fire",            "0" );
    qol_opt_dvar( "night_mode",            "0" );
    qol_opt_dvar( "character",             "0" );
    //  v2.7.3 - the orphaned comment that stood here described a Vulture Aid
    //  eye-effect option whose dvar and whose zmqol_vulture_brighter_eyes()
    //  had both already been deleted. Vulture Aid no longer touches zombie eye
    //  colour at all; see zm_expanded.csc::zmqol_init_vulture_trimmed().
    //  v2.11.26 - WAS disable_player_quotes, DEFAULT 1, AND THAT IS WHY NO
    //  CHARACTER HAS EVER SPOKEN. See qol_opt_voice_lines() for the full
    //  story. Renamed to a positive name with the sane default so the row
    //  in the SOUND tab reads the way a player expects.
    qol_opt_dvar( "voice_lines",           "1" );
    qol_opt_dvar( "coop_pause",            "0" );
    //  v2.14.3 - SOLO EASTER EGGS, the pre-game lobby row (user, 2026-09-06).
    //  Registered here only so it shows up in console autocomplete and holds a
    //  real value on the first open of a lobby; the row itself lives in
    //  ui_mp\t6\menus\privategamelobby_project.lua and the behaviour lives in
    //  four per-map files named scripts\zm\<map>\qol_solo_ee.gsc.
    //
    //  🛑 qol_opt_dvar() only writes when the dvar is EMPTY, which is what
    //  makes this safe to run on every map: the lobby writes solo_ee before the
    //  level loads, and seeding it unconditionally here would throw that choice
    //  away on the way into the match.
    //
    //  📝 Default 0 = stock. Registered on EVERY map even though only four
    //  maps read it - a registration is not a behaviour, and the four readers
    //  are each behind stock's own is_sidequest_allowed( "zclassic" ) gate.
    qol_opt_dvar( "solo_ee",               "0" );
    //  STARTING PISTOL, the pre-game lobby row (user, 2026-09-11). 0 = DEFAULT
    //  (this map's own pistol), 1 = M1911, 2 = MAUSER (c96_zm), 3 = TAC-45
    //  (fnp45_zm). Registered here only so it shows up in console autocomplete
    //  and holds a real value on the first open of a lobby; the row itself lives
    //  in ui_mp\t6\menus\privategamelobby_project.lua and the behaviour lives in
    //  qol_opt_starting_pistol() / qol_opt_starting_pistol_player() below.
    //
    //  🛑 qol_opt_dvar() only writes when the dvar is EMPTY, which is what
    //  makes this safe to run on every map: the lobby writes starting_pistol
    //  before the level loads, and seeding it unconditionally here would throw
    //  that choice away on the way into the match.
    qol_opt_dvar( "starting_pistol",       "0" );
    //  v1.99.91 - the ADVANCED tab's FOG row and the .fog command both write
    //  this; quality_of_life::zmqol_fog_dvar_watch() carries it to r_fog. It
    //  exists because r_fog is cheat-protected and therefore never archived,
    //  which is why FOG was the one menu row that did not survive a restart.
    qol_opt_dvar( "fog_enabled",           "1" );
    //  v2.9.31 - the Ray Gun floating-left-hand probe (high-FOV artifact).
    //  "f r u" viewmodel offsets applied only while a Ray Gun is held; "0 0 0"
    //  is stock. See quality_of_life::zmqol_raygun_hand_watch() for the full
    //  story and why this ships as a tunable rather than a fix.
    qol_opt_dvar( "zmqol_raygun_hand_ofs", "0 0 0" );

    //  v1.85.0 - THE MASTER SWITCH, driven by ".hud on" / ".hud off".
    //  hud_all forces the individual hud_* options ON; hud_master overrides the
    //  lot in the other direction, including the game's OWN LUI hud (points,
    //  ammo, round, perk icons) which no hud_* dvar has ever reached. 1 = normal.
    qol_opt_dvar( "hud_master",       "1" );
    qol_opt_dvar( "hud_all",          "0" );
    qol_opt_dvar( "hud_timer",        "1" );
    //  v1.84.0 - ON by default. The user asked for the round timer to be shown
    //  under the game counter, not left behind a switch they have to find.
    qol_opt_dvar( "hud_round_timer",  "1" );
    // ========================================================================
    //  v2.1.3 - hud_timers, the FOUR-WAY row that replaced the two above.
    //
    //  User, 2026-08-21: *"for the timers remove both of them and turn them it
    //  into one option called 'GAME TIMERS' ... 'GAME TIMER', 'ROUND TIMER',
    //  'GAME TIMER + ROUND TIMER', 'OFF'."*
    //
    //      1 = both (the shipped default)   2 = game only
    //      3 = round only                   0 = off
    //
    //  🛑 NOT a plain qol_opt_dvar default: seeding a blank hud_timers with "1"
    //  would give BOTH timers back to a player who had deliberately switched one
    //  of them off, because their choice lives in the two dvars above and this
    //  is the first build that has ever read this name. qol_opt_timer_seed()
    //  derives the value from those two instead. The LUI does the same
    //  derivation in optionssettings.lua::QolMigrateTimers for the case where
    //  the menu is opened before a map has ever loaded; both use the same table
    //  and both are skipped the moment hud_timers holds anything.
    // ========================================================================
    qol_opt_timer_seed();
    qol_opt_dvar( "hud_health_bar",   "1" );
    //  v1.99.1 - the red "Bleeding out in: N" bar shown while you are downed
    //  (scripts\zm\bleedout_bar.gsc, imported from Nathan3197's mod). User asked
    //  for a switch, 2026-08-16. ON by default - it is existing behaviour, and a
    //  new toggle must not silently change what the mod already does.
    //  Read in ONE place, inside bleedout_bar()'s loop.
    //  v1.99.6 - that read moved INTO the loop, so the row is live: flip it
    //  while you are already downed and the bar appears or disappears at once.
    //  v1.99.1 read it once at creation and the user reported exactly that gap.
    qol_opt_dvar( "hud_bleedout_bar", "1" );
    qol_opt_dvar( "hud_remaining",    "1" );
    qol_opt_dvar( "hud_zone",         "0" );
    //  v1.99.26 - compass, user request 2026-08-17 from the TechnoOps mod. OFF by
    //  default: it is a NEW element, and a new toggle must not change what the
    //  mod already draws for someone who never asked for it.
    qol_opt_dvar( "hud_compass",      "0" );
    //  v2.14.16 - SUBTITLES, user request 2026-09-08. Read per line in
    //  scripts/zm/zmqol_subtitles.gsc. OFF by default.
    qol_opt_dvar( "hud_subtitles",    "0" );
    //  v1.98.0 - the icon + name + description pop-up shown when you buy a perk
    //  (the Vanguard Perk Animation module in quality_of_life.gsc). User asked
    //  for a switch, 2026-08-16. ON by default - it is existing behaviour, and a
    //  new toggle must not silently change what the mod already does.
    //  Read in ONE place, at the top of perk_bought(), so the toggle takes
    //  effect on the very next perk with no respawn.
    qol_opt_dvar( "hud_perk_popup",   "1" );
    //  v1.99.0 - seconds remaining under each power-up icon. ON by default:
    //  the user asked for the feature, not merely for a switch.
    //  🛑 The dvar is read SERVER-side, in zmqol_powerup_timer_think(), so
    //  switching it off stops the reliable-command traffic entirely rather than
    //  just hiding the text. See the long note there.
    qol_opt_dvar( "hud_powerup_timers", "1" );
    qol_opt_dvar( "hud_color",        "1 1 1" );
    qol_opt_dvar( "hud_color_health", "1 1 1" );
    //  v1.90.6 - the two stacked timers get their own colours, kept out of the
    //  shared hud_color tint list.
    //
    //  v1.95.3 - both are now the SAME dull navy blue, user 2026-08-14 (was
    //  yellow / light blue). Two dvars are kept rather than one so either row can
    //  still be re-coloured on its own from the console.
    //
    //  🛑 They had to come OUT of the shared hud_color tint list to do this.
    //  qol_opt_hud_watcher() repaints from one dvar on change, so a colour set
    //  at creation was guaranteed to be flattened back to white on the very
    //  first pass - the same single-owner rule as the health bar above.
    //  hud_color still owns zombietext and the zone name.
    //
    //  🛑 The watcher's str_prev_color_timer / _round seeds MUST match these two
    //  strings exactly, or the first pass sees a change and repaints on spawn.
    qol_opt_dvar( "hud_color_timer",       "1 1 1" );   //  white, user 2026-08-31 (was navy blue)
    qol_opt_dvar( "hud_color_round_timer", "1 1 1" );   //  white, directive 2026-09-02 - the 08-31 white
                                                        //  pass changed the creation colour but left this navy

    //  Read by quality_of_life::get_pack_a_punch_weapon_options(). Default 1
    //  keeps the animated camo exactly where this mod already had it.
    //
    //  v1.99.83, queue item 11 - anim_pap_camo is the MASTER row on the GAME
    //  tab. The three per-map dvars below stay, unchanged and still readable
    //  from the console, because they are already archived in players' configs
    //  and removing them would silently reset anyone who had set one. The
    //  master is ANDed with them: OFF means camo 39 (stock) on all three maps
    //  whatever the per-map dvars say, ON leaves the per-map behaviour exactly
    //  as it has always been.
    //  v2.9.12, queue item 9 - GREEN RUN JOINS THEM (user, 2026-08-31, after
    //  spectating a player on the "ezz" server with animated camos on Town
    //  survival). One dvar covers all of Green Run because TranZit, Bus Depot,
    //  Farm, Town and Diner - classic, survival and grief alike - all run with
    //  level.script == "zm_transit".
    qol_opt_dvar( "anim_pap_camo",         "1" );
    qol_opt_dvar( "anim_pap_camo_mob",     "1" );
    qol_opt_dvar( "anim_pap_camo_buried",  "1" );
    qol_opt_dvar( "anim_pap_camo_origins", "1" );
    qol_opt_dvar( "anim_pap_camo_transit", "1" );
    qol_opt_dvar( "anim_pap_camo_highrise", "1" );   //  v2.9.16 - Die Rise joins (user 2026-08-31)
    qol_opt_dvar( "anim_pap_camo_nuked",    "1" );   //  v2.9.16 - Nuketown joins (user 2026-08-31)

    //  v1.95.0 - three new rows for the QUALITY OF LIFE menu, user 2026-08-14.
    //  All default ON, so the mod behaves exactly as before unless switched off.
    //  Read in quality_of_life.gsc by updatedamagefeedback(), the custom-summary
    //  popup and zmqol_credits_banner_print() respectively. Registered here with
    //  the rest so they appear in console autocomplete and so the menu row reads
    //  a real value instead of an empty string on the first open.
    qol_opt_dvar( "hitmarkers",    "1" );

    //  v1.99.31 - the SOUND tab's four feedback packs, user request 2026-08-17.
    //  All default "0", which for hit/kill means the alert this mod has always
    //  played and for downed/crit means silence - so nothing changes for anyone
    //  who does not go looking. The numbering and the alias tables live in
    //  quality_of_life.gsc's zmqol_init_feedback_sounds(); registered here with
    //  the rest so the console autocompletes them and the menu row reads a real
    //  value the first time it is opened instead of an empty string.
    qol_opt_dvar( "hit_sound",     "0" );
    qol_opt_dvar( "kill_sound",    "0" );
    qol_opt_dvar( "downed_sound",  "0" );
    qol_opt_dvar( "crit_sound",    "0" );
    qol_opt_dvar( "round_summary", "1" );
    // ========================================================================
    //  v2.14.14 - flash_intro, the FOUR-WAY row that replaced FLASH CREDITS
    //  (intro_credits) and FLASH HELP (flash_help) on the GAME tab.
    //
    //  User, 2026-09-08: *"combine them into 1 option to save space for another
    //  option ... just flash credits, just flashing help, flashing both, or
    //  nothing popping up at all (Disabled)"*.
    //
    //      1 = both (the shipped default)   2 = credits only
    //      3 = help only                    0 = off
    //
    //  🛑 NOT a plain qol_opt_dvar default, for the same reason as hud_timers:
    //  seeding a blank flash_intro with "1" would hand both flashes back to a
    //  player who had switched one of them off, because their choice lives in
    //  the two old dvars. qol_opt_flash_seed() derives the value from those two
    //  instead; optionssettings.lua::QolMigrateFlash does the same derivation
    //  when the menu is opened before a map has loaded. Both are skipped the
    //  moment flash_intro holds anything. Read in ONE place:
    //  quality_of_life.gsc's zmqol_credits_banner_print().
    // ========================================================================
    qol_opt_flash_seed();

    //  v1.99.61 - PERK BONUS POINTS, user request 2026-08-18. ON by default:
    //  the +100 for proning at a perk machine is behaviour this mod has always
    //  had, so the switch must change nothing until it is thrown. OFF means NO
    //  prone points at all - the mod's own detector stops paying AND Origins'
    //  native 25-point "loose change" easter egg is suppressed, which is the
    //  two-state behaviour the user asked for ("either the effect is on with 100
    //  points prone per machine, or not points at all from proning"). Read live
    //  in quality_of_life.gsc's prone_bonus_monitor() and in zm_tomb.gsc's
    //  origins_change_patch(), so it takes effect mid-match both ways.
    qol_opt_dvar( "perk_bonus_points", "1" );

    //  v1.99.61 - FLASH HELP, user request 2026-08-18: the second match-start
    //  flash line, telling players how to open chat and reach .help.
    //  🛑 v2.14.14 - flash_help is no longer registered here. It and
    //  intro_credits are folded into flash_intro (see qol_opt_flash_seed()
    //  above); the old names stay in players' configs only as migration input.

    qol_opt_dvar( "no_power", "0" );

    //  v1.99.48 - INSTANT NUKE, user request 2026-08-18. Read once per nuke in
    //  quality_of_life.gsc's zmqol_nuke_powerup(), which is stock's own
    //  nuke_powerup() with the per-zombie stagger wait gated on this and nothing
    //  else changed. ON by default: the user asked for the feature, not merely
    //  for a switch (the same call as the power-up timers in v1.99.0). "0" is
    //  exact vanilla, down to the same random 0.1-0.7s wait stock takes.
    qol_opt_dvar( "instant_nuke", "1" );

    //  v1.99.73 - BETTER DEADSHOT, user request 2026-08-19. OFF by default: a
    //  doubled headshot is new behaviour and a new switch must not change what
    //  the mod already does until it is thrown. Registered here so the console
    //  autocompletes it; quality_of_life.gsc::zmqol_better_deadshot_scale()
    //  reads it on every bullet, so it is live both ways mid-game.
    qol_opt_dvar( "better_deadshot", "0" );

    //  v2.2.0 - BETTER SPEED COLA, user request 2026-08-21, the GAME tab row
    //  directly under BETTER DEADSHOT. OFF by default for the same reason that
    //  one is: a new switch must not change what the mod already does until it
    //  is thrown. Read per board chunk in quality_of_life.gsc's
    //  zmqol_replace_chunk() / zmqol_do_post_chunk_repair_delay(), so it is live
    //  mid-match in both directions.
    qol_opt_dvar( "better_speed_cola", "0" );

    //  v2.2.0 - NO BLEEDOUT PATCH, user request 2026-08-21, the PATCHES tab.
    //  OFF = stock. Read on every pass of zmqol_round_spawn_failsafe(), which is
    //  stock's own 30-second per-zombie loop, so it is live mid-match too.
    qol_opt_dvar( "no_bleedout", "0" );

    //  ========================================================================
    //  v2.14.7 - CROSSHAIR, user request (queued as B-CROSSHAIR, asked again
    //  2026-09-06: *"where's the crosshair on/off toggle in the hud menu like i
    //  asked for"*). The HUD tab.
    //
    //  1 = ENABLED = stock, the crosshair the game has always drawn. 0 hides it.
    //
    //  🛑 IT TAKES THREE CLIENT DVARS, NOT ONE, AND THAT IS DELIBERATE.
    //  cg_drawCrosshair is the right dvar - Plutonium's own
    //  dvar_descriptions.json calls it "Turn on weapon crosshair" - but the
    //  game's console printed `cg_drawCrosshair is cheat protected` three times
    //  in this machine's own console_zm.log while execing its default cfgs, so a
    //  plain write to it is refused from a config. Whether setclientdvar is
    //  refused the same way is NOT established here and nothing in the stock
    //  dump or in any mod source on this machine sets it, so the switch also
    //  writes cg_crosshairAlpha and cg_crosshairAlphaMin, which are NOT on that
    //  cheat-protected list and hide the crosshair on their own by drawing it
    //  fully transparent. Whichever of the two routes the build allows, the
    //  crosshair goes.
    //
    //  The restore values are the game's own defaults, read out of the dvar dump
    //  in console_zm.log: cg_drawCrosshair 1, cg_crosshairAlpha 1,
    //  cg_crosshairAlphaMin 0.5.
    //
    //  📝 These are archived client dvars, so leaving the row OFF and then
    //  removing the mod would leave the crosshair hidden. Turning the row back
    //  on restores it, and so does one console line: cg_crosshairAlpha 1.
    //  ========================================================================
    qol_opt_dvar( "crosshair", "1" );

    //  v2.7.0 - NO LAVA DAMAGE, user request 2026-08-28, the PATCHES tab.
    //  TranZit-family maps only (Classic TranZit, Diner, Farm, Town, Bus Depot -
    //  all share mapname "zm_transit", told apart only by ui_zm_mapstartlocation).
    //  OFF (0) = stock: lava still ignites/explodes zombies and damages players.
    //  ON (1) = lava stays visible on the ground but does nothing - the ground
    //  fx/material are a separate system this never touches.
    //  Read live on every lava trigger event by
    //  scripts\zm\zm_transit\zm_transit.gsc::qol_lava_damage_think(), which
    //  replaces maps\mp\zm_transit_lava::lava_damage_init() - see that file for
    //  why that is the one safe hook point (player_lava_damage/zombie_lava_damage
    //  are both called unqualified, same file, in stock - not replaceFunc-able
    //  directly). Live in both directions mid-match, not just at map load.
    qol_opt_dvar( "no_lava_damage", "0" );

    //  v2.12.5 - NO DENIZENS, user request 2026-09-05, the new GAME 3 tab.
    //  *"add an option to turn tranzit denizens on/off (enabled/disabled),
    //  disabled is standard vanilla behaviour, setting it to enabled makes no
    //  denizens spawn in the fog so they wont annoy the player."*
    //
    //  OFF (0) = stock: denizens spawn in the fog exactly as Treyarch shipped.
    //  ON (1) = none ever spawn.
    //
    //  🌟 IT DRIVES A STOCK DVAR, AND THAT DVAR HAS EXACTLY ONE READER IN THE
    //  WHOLE GAME. maps\mp\zombies\_zm_ai_screecher.gsc:85, inside
    //  screecher_spawning_logic()'s main loop:
    //        while ( getdvarint( #"scr_screecher_ignore_player" ) )
    //            wait 0.1;
    //  While it is non-zero the spawn loop parks before it ever picks a spawn
    //  point, so nothing is spawned and nothing is killed off afterwards - the
    //  player never sees a denizen appear and vanish. A grep of the entire
    //  gsc-dump finds that line and no other use of the name (the two
    //  scr_screecher_ignore_SCORE reads at :1111 and :1164 are a different
    //  dvar, and both sit inside /# #/ dev blocks), so there is no side effect
    //  to inherit.
    //
    //  🛑 THAT LINE IS NOT IN A DEV BLOCK. The /# #/ pairs in that function are
    //  at :64-67 and :74-76 only; :85 is plain retail code. Checked explicitly,
    //  because a stock call that turned out to be dev-only is exactly how the
    //  .fog toggle shipped doing nothing (CLAUDE.md's pre-mortem rule).
    //
    //  📝 The write is a plain setdvar of a name stock reads hashed. Stock does
    //  the same thing to itself - gametypes_zm\_serversettings.gsc reads
    //  getdvar( #"sv_hostname" ) at :6 and writes setdvar( "sv_hostname", ... )
    //  at :11, and reads #"g_allowVote" at :22 while writing "g_allowvote" at
    //  :27 - so the hashed and string forms address one dvar, case included.
    //
    //  Mirrored onto the stock dvar once a second by
    //  quality_of_life.gsc::zmqol_no_denizens_watch(), which is TranZit-only
    //  and live in both directions mid-match.
    qol_opt_dvar( "no_denizens", "0" );

    //  v2.14.13 - THIRD PERSON, user request 2026-09-07, the GAME 3 tab. OFF =
    //  stock first person. Applied per player, once a second, by
    //  qol_opt_third_person() below - see its banner for why it drives the
    //  engine method rather than a dvar, and why it has to re-apply after
    //  every spawn.
    qol_opt_dvar( "third_person", "0" );

    //  v2.14.28 - KNIFE LUNGE, user request 2026-09-08, the GAME 3 tab. ON =
    //  stock (the melee charge that pulls you onto the zombie). OFF writes the
    //  engine's own switch for it, aim_automelee_enabled, to 0 - see
    //  qol_opt_knife_lunge() below for the evidence. Applied per player, once a
    //  second, live in both directions.
    qol_opt_dvar( "knife_lunge", "1" );

    //  v2.7.2 - 3 HIT DOWN, user request 2026-08-28, the PATCHES tab. OFF =
    //  stock. Read on every zombie melee hit by
    //  quality_of_life.gsc::zmqol_three_hit_down_scale(), chained through the
    //  stock overrideplayerdamage extension point - see
    //  zmqol_three_hit_down_install() for the whole mechanism. Live mid-match
    //  in both directions, same as the other PATCHES rows.
    qol_opt_dvar( "three_hit_down", "0" );

    //  v2.8.2 - ONE SHOT ONE KILL, user request 2026-08-29, the CHEATS tab.
    //  OFF (0) = stock. Read on every point of damage a player deals, inside
    //  the level.callbackactordamage chain this mod already owns - see
    //  quality_of_life.gsc::zmqol_one_shot_scale(). Live mid-match in both
    //  directions. 🛑 It is in QolNoArchive on the LUI side, like every other
    //  CHEATS row: an archived 1 would arm the cheat on the next launch.
    qol_opt_dvar( "one_shot_one_kill", "0" );

    //  v2.8.2 - WINTER'S HOWL INFINITE DAMAGE, user request 2026-08-29, the
    //  PATCHES tab. OFF (0) = the gun's shipped damage numbers. ON (1) makes
    //  all four of its damage figures effectively unbounded. Read per shot by
    //  the four freezegun_get_*_damage() accessors in
    //  maps\mp\zombies\_zm_weap_freezegun.gsc, so it is live mid-match in both
    //  directions. Does nothing on a map without the gun, and nothing at all
    //  while the zmqol_ww gate has the wonder weapons switched off.
    qol_opt_dvar( "winters_howl_infinite", "0" );

    //  v2.8.2 - ROUND DELAY OFF, user request 2026-08-29, the PATCHES tab.
    //  OFF (0) = stock's 10-second gap plus the 2.5-second round-announce beat.
    //  ON (1) removes both. Read once per round inside this mod's own
    //  round_think() - see the note there for exactly which two waits are
    //  removed and why the first round is deliberately left alone.
    qol_opt_dvar( "round_delay_off", "0" );

    // ------------------------------------------------------------------------
    //  v1.99.91 - NO BOX LIMITS (was BOX LIMITS, v1.99.83, queue item 30).
    //
    //  ON (1) by default: the unlocked box - duplicates, both Ray Guns, no
    //  per-map wonder-weapon cap - which is what this mod has always shipped.
    //  OFF puts stock's three checks back, in stock's own order, inside
    //  maps\mp\zombies\_zm_magicbox::treasure_chest_canplayerreceiveweapon().
    //  Read per candidate weapon inside the spin loop, so the row is live: flip
    //  it and the very next spin obeys it.
    //
    //  🛑 THE MIGRATION IS THE POINT OF THESE FOUR LINES. The meaning is
    //  inverted from the old row, so carrying the old dvar name across would
    //  have flipped the setting of anyone who had already saved one. Their
    //  archived box_limits is read ONCE, inverted into the new name, and never
    //  read again. A player who never saw the old row gets the default.
    // ------------------------------------------------------------------------
    if ( getdvar( "no_box_limits" ) == "" && getdvar( "box_limits" ) != "" )
        setdvar( "no_box_limits", "" + ( !getdvarintdefault( "box_limits", 0 ) ) );

    qol_opt_dvar( "no_box_limits", "1" );

    //  v1.99.83 - CUSTOM POWER-UPS, queue item 25. ON (1) by default: Zombie
    //  Blood, Blood Money and the Death Machine are drops this mod already ships
    //  on every map, so the switch changes nothing until it is thrown. OFF puts
    //  the drop table back to stock. It gates ONLY the drop-table registration -
    //  never a clientfield, visionset or precache - so the per-map bit budget is
    //  identical either way and the row cannot break a map load. Read once at
    //  map load, so it takes effect on the next map. See
    //  quality_of_life::zmqol_custom_powerups_enabled().
    qol_opt_dvar( "custom_powerups", "1" );

    //  v2.8.0 - PERMA-PERKS, queue item 29. OFF (0) by default, and that is the
    //  user's own settled call: DISABLED is stock, earned normally. ENABLED
    //  makes every persistent upgrade the MAP ITSELF registers active
    //  immediately. It never registers an upgrade, so Perma-PhD stays a Buried
    //  perk; it only zeroes the threshold of names already in
    //  level.pers_upgrades. Live both ways - flip it mid-game and the next
    //  second applies or restores it. Classic only, which is stock's own gate.
    //  See quality_of_life::zmqol_perma_perks_watch() for the full derivation.
    qol_opt_dvar( "perma_perks", "0" );

    //  v1.99.74 - AIM ASSIST, its own row on CONTROLS > GAMEPAD. Default 1 =
    //  stock. 🛑 It can only take assist AWAY - see the banner over
    //  quality_of_life.gsc::zmqol_aim_assist_watch() for the measurement behind
    //  that, and do not widen the label without re-reading it.
    qol_opt_dvar( "aim_assist", "1" );

    //  v2.9.15 - TAP TO INTERACT, user request 2026-08-31. Lives on the STOCK
    //  CONTROLS > GAMEPAD tab, not on one of this mod's own tabs, because that
    //  is where the request put it - optionssettings.lua adds the row next to
    //  AIM ASSIST. Default 0 = stock hold-to-use, so it changes nothing until a
    //  player throws it. v2.9.33: read by NOTHING server-side any more - the
    //  row itself applies two client binds on change (optionssettings.lua has
    //  the mechanism and its verification); this registration just keeps the
    //  dvar alive for the toggle to read and archive.
    qol_opt_dvar( "tap_to_interact", "0" );

    //  Model pop-in. On by default - it is a pure image-quality win with no
    //  gameplay effect. See qol_opt_lod_fix() for what it actually writes.
    qol_opt_dvar( "lod_fix", "1" );

    //  v1.99.51 - BACKSPEED PATCH, user request (queue item 2). ON by default,
    //  because forcing these three to 1 is what this mod has always done - the
    //  switch must not change anyone's game until it is thrown. See
    //  qol_opt_move_speed() for the values and where they came from.
    qol_opt_dvar( "move_speed", "1" );

    //  v2.0.6 - NETWORK FRAME PATCH, user request. OFF by default: with it off
    //  quality_of_life::zmqol_wait_network_frame() is byte-exact stock, so the
    //  row changes nothing until it is thrown. See the header above that
    //  function for the console figures and why B2OP disables its own copy on
    //  modern Plutonium.
    qol_opt_dvar( "network_frame_patch", "0" );

    //  v2.0.7 - GRAPHICS BOOST, user request (REZ's "Vanilla+" config). OFF by
    //  default: REZ's own documentation targets modern dedicated GPUs with
    //  1.5-2 GB of VRAM headroom, so it must not be forced on everyone who
    //  updates. See qol_opt_aa_selfheal() below for the one part that survived,
    //  dropped, and the four dvars in that config that do not exist.
    //  v2.8.6 - graphics_boost REMOVED ENTIRELY at the user's request. The UI
    //  row went in v2.6.6; the dvar and its thread lingered, so the console
    //  command still existed. Both are gone now. The r_aaSamples SELF-HEAL it
    //  used to carry survives as qol_opt_aa_selfheal(), which is the only part
    //  that ever needed to run.

    //  v2.0.8 - ROUND COUNTER LEFT (HUD tab). 0 = top right, the Cold War
    //  placement the mod has always shipped, so nobody's HUD moves on update.
    qol_opt_dvar( "hud_round_left", "0" );

    qol_opt_aa_selfheal();
    level thread qol_opt_coop_pause();
    level thread qol_opt_round_clock();
    level thread qol_opt_no_power();
    level thread qol_opt_lod_fix();
    level thread qol_opt_move_speed();
    level thread qol_opt_roundcounter_master();
    level thread qol_opt_connect_loop();
    level thread qol_opt_starting_pistol();

    //  ------------------------------------------------------------------
    //  TARGET ASSIST - v1.99.34, user request 2026-08-17. The lobby's TARGET
    //  ASSIST row is gone (see the long note in ui_mp\t6\menus\
    //  privategamelobby_project.lua), so CONTROLS > GAMEPAD > TARGET ASSIST is
    //  the only switch a player touches. That row writes the PROFILE var
    //  input_targetAssist; THIS dvar is the separate server-side PERMISSION,
    //  and Plutonium's optionscontrols.lua LOCKS the row in game whenever it is
    //  0. Granting it here keeps the one remaining switch always usable.
    //
    //  🛑 setdvar, not qol_opt_dvar. qol_opt_dvar only writes an EMPTY dvar and
    //  this one always has a value - the engine registers it - so the
    //  conditional form would never do anything at all.
    //
    //  📝 The default is already 1 (Plutonium's own DvarDefaults table, and the
    //  lobby row drew no ⭐ beside ENABLED in the user's screenshot), so on a
    //  normal solo or private match this changes nothing. It is written anyway
    //  so the feature does not rest on a default this project does not own. On
    //  a dedicated server that deliberately forbids aim assist this does
    //  re-permit it - zm_qol is a Mods-menu solo/private mod, and that trade is
    //  recorded here rather than left to be discovered.
    //
    //  🛑 LAST in init() on purpose, after every thread above is already
    //  running. A protected dvar prints "Cannot set cheat dvar X" rather than
    //  crashing (console_zm.log does exactly that for r_fog), but if this one
    //  ever did fail hard, being last means it can only cost itself - not the
    //  coop pause, the round clock, no_power, lod_fix or the connect loop.
    setdvar( "sv_allowAimAssist", 1 );
}

// ============================================================================
//  qol_opt_roundcounter_master  -  ".hud off" reaches the round chalk too
//
//  v1.87.1. The BOCW round counter (quality_of_life.gsc::round_hud()) was the
//  one HUD element ".hud off" did not hide - it is still visible as the chalk
//  mark in the top right of the user's screenshot.
//
//  🛑 IT CANNOT BE DRIVEN FROM qol_opt_hud_watcher(). Two reasons:
//    1. It is a SERVER hudelem (createservericon / createserverfontstring),
//       one shared element rather than one per player, so a per-player watcher
//       would have every player writing the same element.
//    2. It is ANIMATION-driven, not tick-driven - round_hud() runs
//       fadeovertime / scaleovertime / moveovertime sequences at each round
//       change. Writing its alpha on a timer would fight those animations.
//
//  So this only ever writes while the HUD is switched OFF, plus exactly once on
//  the off->on edge to put it back. While the HUD is on it never touches the
//  element, and the round animation is left completely alone.
// ============================================================================
qol_opt_roundcounter_master()
{
    if ( zmqol_minimal() )
        return;

    level endon( "end_game" );

    n_prev = 1;

    for ( ;; )
    {
        wait 0.25;

        // ====================================================================
        //  v2.1.3 - ROUND COUNTER POSITION -> OFF hides it here too.
        //
        //  User, 2026-08-21: *"add a third 'off' options so you can turn it off
        //  entirely."*  hud_round_left 2 = OFF.
        //
        //  🌟 THIS LOOP IS THE RIGHT PLACE AND NOT A NEW MECHANISM: it already
        //  owns this element's alpha and already re-asserts it every pass, which
        //  is exactly what the round counter needs - round_hud() fades it back
        //  to alpha 1 at every round transition, so a single write would be
        //  undone by the next round. Adding a second writer elsewhere is the
        //  flashing-hudelem bug this project has already had once.
        //
        //  🛑 level.zmqol_roundcounter is a SERVER hudelem, one for the whole
        //  match, so OFF is the host's setting for everybody - the same as
        //  hud_master has always been on this element. It cannot be per-player
        //  without rebuilding the counter as a client hudelem, which would
        //  change what every other feature that touches it is holding.
        // ====================================================================
        n_on = getdvarintdefault( "hud_master", 1 ) && getdvarintdefault( "hud_round_left", 0 ) != 2;

        if ( !isdefined( level.zmqol_roundcounter ) )
        {
            n_prev = n_on;
            continue;
        }

        if ( !n_on )
        {
            //  Re-asserted every pass, not once: round_hud() sets alpha back to
            //  1 at every round transition, so a single write would be undone
            //  by the next round.
            level.zmqol_roundcounter.alpha = 0;
        }
        else if ( !n_prev )
        {
            level.zmqol_roundcounter.alpha = 1;
        }

        n_prev = n_on;
    }
}

// ============================================================================
//  qol_opt_lod_fix  -  stop models popping in at distance
//
//  What the user sees as "texture pop-in" on BO2 is LOD swapping: the renderer
//  drops rigid (world/prop) and skinned (character) models to lower detail
//  levels past a distance threshold. Treyarch tuned that for 2012 consoles, and
//  the fog exists partly to hide it.
//
//  📝 THE FOUR DVARS ARE REAL AND VERIFIED, not taken on trust from the forum
//  post they came from. All four appear in this install's own dvar dump
//  (console_zm.log) with these stock defaults:
//        r_lodBiasRigid    "0"
//        r_lodBiasSkinned  "0"
//        r_lodScaleRigid   "1"
//        r_lodScaleSkinned "1"
//  and Treyarch's own descriptions (BO2 Detailed DVARS.txt) give the direction:
//        r_lodBias*   "Bias the level of detail distance ... negative INCREASES detail"
//        r_lodScale*  "Scale the level of detail distance ... larger REDUCES detail"
//
//  🛑 SO ONLY TWO OF THE FOUR ACTUALLY DO ANYTHING HERE. r_lodScaleRigid and
//  r_lodScaleSkinned already sit at 1, which is the neutral value the advice
//  asks for - writing 1 over 1 is a no-op on a stock config. They are still
//  written, deliberately: this mod ships to other people, and a config that has
//  raised either of them (larger = less detail) would otherwise keep popping
//  models regardless of the bias. Writing them makes the result independent of
//  whatever is in the user's config, which is the whole point.
//
//  🛑 THESE ARE CLIENT RENDERER DVARS. Setting them from GSC works because this
//  mod runs through Plutonium's Mods menu, where the host IS the client - one
//  process. They are NOT networked, so on a dedicated server this would change
//  nothing for remote players. That is a limitation of the approach, not a bug.
//
//  Written only when the setting CHANGES, not on a timer - same discipline as
//  the hud_color watcher above, which exists because writing dvars every tick
//  is a lot of work for a value that changes when someone types at the console.
// ============================================================================
qol_opt_lod_fix()
{
    if ( zmqol_minimal() )
        return;

    level endon( "end_game" );

    n_prev = -1;

    for ( ;; )
    {
        n_on = getdvarintdefault( "lod_fix", 1 );

        if ( n_on != n_prev )
        {
            n_prev = n_on;

            if ( n_on )
            {
                setdvar( "r_lodBiasRigid",   "-1000" );
                setdvar( "r_lodBiasSkinned", "-1000" );
            }
            else
            {
                //  Back to the stock values read out of this install's dvar
                //  dump, so switching the option off is a real restore rather
                //  than a guess at what BO2 shipped with.
                setdvar( "r_lodBiasRigid",   "0" );
                setdvar( "r_lodBiasSkinned", "0" );
            }

            //  Neutral either way - see the note above on why these are written
            //  at all rather than assumed.
            setdvar( "r_lodScaleRigid",   "1" );
            setdvar( "r_lodScaleSkinned", "1" );
        }

        wait 1;
    }
}

// ============================================================================
//  qol_opt_move_speed  -  full speed backwards and sideways        (v1.99.51)
//
//  BO2 slows you down whenever you are not running forwards. The mod has
//  always cancelled that by forcing three scales to 1, on this line inside
//  quality_of_life::init()'s high_round_fix block:
//
//      setdvar( "player_backSpeedScale", 1 );
//      setdvar( "player_strafeSpeedScale", 1 );
//      setdvar( "player_sprintStrafeSpeedScale", 1 );
//
//  Those three lines are GONE from there now; this is the only writer, so the
//  GAME > BACKSPEED PATCH row can put the game back to stock live and have it
//  stay that way across a map change.
//
//  📝 THE OFF VALUES ARE MEASURED, NOT GUESSED. They are this install's own
//  boot-time dvar dump (console_zm.log), read before the mod's init runs:
//        player_backSpeedScale        "0.7"
//        player_strafeSpeedScale      "0.8"
//        player_sprintStrafeSpeedScale "0.667"
//  The same file's later dumps show all three at "1" once the mod has loaded,
//  which is also the proof that a plain setdvar reaches them at all - they are
//  not write-protected here. (T6-B2OP-PATCH independently registers
//  player_backSpeedScale with a "0.7" default, which agrees.)
//
//  🛑 These are movement dvars read by the client's own prediction, and this
//  mod runs through Plutonium's Mods menu where the host IS the client, one
//  process - the same standing limitation qol_opt_lod_fix() carries. On a
//  dedicated server this would not reach a remote player.
//
//  Written only when the setting CHANGES, same discipline as the lod watcher
//  above, so flipping the row costs three setdvars and nothing per tick.
// ============================================================================
qol_opt_move_speed()
{
    if ( zmqol_minimal() )
        return;

    level endon( "end_game" );

    n_prev = -1;

    for ( ;; )
    {
        n_on = getdvarintdefault( "move_speed", 1 );

        if ( n_on != n_prev )
        {
            n_prev = n_on;

            if ( n_on )
            {
                setdvar( "player_backSpeedScale",         "1" );
                setdvar( "player_strafeSpeedScale",       "1" );
                setdvar( "player_sprintStrafeSpeedScale", "1" );
            }
            else
            {
                setdvar( "player_backSpeedScale",         "0.7" );
                setdvar( "player_strafeSpeedScale",       "0.8" );
                setdvar( "player_sprintStrafeSpeedScale", "0.667" );
            }
        }

        wait 1;
    }
}


// ============================================================================
//  qol_opt_aa_selfheal  -  the r_aaSamples repair                    (v2.8.6)
//
//  🛑 THIS IS ALL THAT REMAINS OF GRAPHICS BOOST. The whole feature - the dvar,
//  the 21-key apply/restore thread and the menu row - was removed at the user's
//  request, 2026-08-30: *"the graphics_boost console command for some reason
//  still exists??? I told you ages ago to get rid of that from my mod"*. The UI
//  row went in v2.6.6 but the dvar and its thread stayed, so the console command
//  was still there and still force-wrote render dvars on every load.
//
//  What could NOT be dropped is the self-heal, because it repairs a config that
//  kills the game before any script runs:
//
//  Every build from v2.0.7 to v2.2.3 wrote r_aaSamples 16 the moment GRAPHICS
//  BOOST was thrown. That dvar is ARCHIVED and LATCHED, so the 16 sits in
//  plutonium_zm.cfg afterwards and is applied by the renderer restart that runs
//  as the mod loads. 16x MSAA is a sample count D3D cannot create, so device
//  creation returns E_INVALIDARG and the game dies at the frontend:
//
//      Reading stats... / Reading backup stats...
//      COM_ERROR (0) E_INVALIDARG ... @ 0x74C0E0
//
//  Writing the dvar re-archives it, so one launch on a poisoned config cleans it
//  permanently. Anyone who never threw the boost never had 16 written, and this
//  function does nothing for them.
//
//  🛑 17 AND 18 ARE THE TXAA SENTINELS, NOT SAMPLE COUNTS - hence the <= 16.
//  User report 2026-08-30: *"I set TXAA X4 ... started the new game and the
//  settings didn't save"*. TXAA x2/x4 write r_aaSamples 17/18, both above the
//  hardware max of 8, so an unbounded heal fired every load and stamped the
//  value back to 8. <= 16 is exactly the bound stock's own
//  AntiAliasingChangeCallback uses to separate real MSAA values from TXAA.
//
//  Not a thread and not a loop: it runs once, at init, and returns.
// ============================================================================
qol_opt_aa_selfheal()
{
    n_aa_max_heal = getdvarintdefault( "r_aaSamplesMax", 0 );
    n_aa_now      = getdvarintdefault( "r_aaSamples", 0 );

    if ( n_aa_max_heal > 0 && n_aa_now > n_aa_max_heal && n_aa_now <= 16 )
    {
        setdvar( "r_aaSamples", "" + n_aa_max_heal );
        println( "[zm_qol] SELF-HEAL: r_aaSamples was " + n_aa_now + " with a hardware max of " + n_aa_max_heal + " - written back to " + n_aa_max_heal + ". That value black-screens the game at load." );
    }
}
//  setdvar only when the dvar has never been set, so a value already in the
//  user's config or typed at the console survives a map change. Remix's
//  create_dvar(), same idea.
qol_opt_dvar( str_dvar, str_default )
{
    if ( getdvar( str_dvar ) == "" )
        setdvar( str_dvar, str_default );
}

// ============================================================================
//  qol_opt_timer_seed  -  v2.1.3, the GAME TIMER / ROUND TIMER merge
//
//  Fills hud_timers in from the two dvars the old pair of HUD rows wrote, once,
//  and only while hud_timers is still empty:
//
//        hud_timer  hud_round_timer      hud_timers
//            1            1          ->      1   both
//            1            0          ->      2   game only
//            0            1          ->      3   round only
//            0            0          ->      0   off
//
//  🛑 IDEMPOTENT BY CONSTRUCTION. The only write is the setdvar at the bottom,
//  and the first line returns the moment the name holds anything, so a stale
//  hud_timer can never re-derive a value the player has since changed.
//
//  📝 Twin of optionssettings.lua::CoD.OptionsSettings.QolMigrateTimers, which
//  covers the player who opens the menu from the main menu before any map has
//  loaded. Same table on both sides - change one and change the other.
// ============================================================================
qol_opt_timer_seed()
{
    if ( getdvar( "hud_timers" ) != "" )
        return;

    b_game  = getdvarintdefault( "hud_timer", 1 ) != 0;
    b_round = getdvarintdefault( "hud_round_timer", 1 ) != 0;

    n_mode = 0;

    if ( b_game && b_round )
        n_mode = 1;
    else if ( b_game )
        n_mode = 2;
    else if ( b_round )
        n_mode = 3;

    setdvar( "hud_timers", n_mode );
}

// ============================================================================
//  qol_opt_flash_seed  -  v2.14.14, the FLASH CREDITS / FLASH HELP merge
//
//  Fills flash_intro in from the two dvars the old pair of GAME rows wrote,
//  once, and only while flash_intro is still empty:
//
//        intro_credits  flash_help      flash_intro
//              1            1        ->      1   both
//              1            0        ->      2   credits only
//              0            1        ->      3   help only
//              0            0        ->      0   off
//
//  Idempotent by construction, exactly like qol_opt_timer_seed(): the only
//  write is the setdvar at the bottom, and the first line returns the moment
//  the name holds anything.
//
//  📝 Twin of optionssettings.lua::CoD.OptionsSettings.QolMigrateFlash. Same
//  table on both sides - change one and change the other.
// ============================================================================
qol_opt_flash_seed()
{
    if ( getdvar( "flash_intro" ) != "" )
        return;

    b_credits = getdvarintdefault( "intro_credits", 1 ) != 0;
    b_help    = getdvarintdefault( "flash_help", 1 ) != 0;

    n_mode = 0;

    if ( b_credits && b_help )
        n_mode = 1;
    else if ( b_credits )
        n_mode = 2;
    else if ( b_help )
        n_mode = 3;

    setdvar( "flash_intro", n_mode );
}

qol_opt_connect_loop()
{
    for ( ;; )
    {
        level waittill( "connected", player );
        player thread qol_opt_player_init();
    }
}

qol_opt_player_init()
{
    self endon( "disconnect" );

    b_first = 1;

    for ( ;; )
    {
        self waittill( "spawned_player" );

        if ( !b_first )
            continue;

        b_first = 0;

        self thread qol_opt_cherry_sound();
        self thread qol_opt_rapid_fire();
        self thread qol_opt_voice_lines();
        self thread qol_opt_night_mode();
        self thread qol_opt_character();
        self thread qol_opt_starting_pistol_player();
        self thread qol_opt_hud_watcher();
        self thread qol_opt_crosshair();
        self thread qol_opt_third_person();
        self thread qol_opt_knife_lunge();
        //  v2.14.15 - BETTER SPEED COLA, part two: the perk-bottle drink watcher.
        //  Lives with the rest of that feature in quality_of_life.gsc.
        self thread scripts\zm\quality_of_life::zmqol_speed_cola_drink_watch();
    }
}

// ----------------------------------------------------------------------------
//  rapid_fire
// ----------------------------------------------------------------------------
//  The "fast ray" trick: switching weapon and back cancels the fire animation,
//  so the next shot can start immediately. Adapted from Remix _players.gsc:139.
//
//  🛑 IT NEEDS A SECOND PRIMARY - Mule Kick, or any two-weapon loadout - because
//  the cancel IS the weapon switch. With one gun there is nothing to switch to
//  and this does nothing at all. That is inherent to the technique, not a bug
//  here, and it is why the loop checks primaries.size before doing anything.
// ----------------------------------------------------------------------------
qol_opt_rapid_fire()
{
    self endon( "disconnect" );
    level endon( "end_game" );

    for ( ;; )
    {
        if ( !getdvarintdefault( "rapid_fire", 0 ) )
        {
            wait 0.25;
            continue;
        }

        self waittill( "weapon_fired", str_fired );

        if ( !getdvarintdefault( "rapid_fire", 0 ) )
            continue;

        a_primaries = self getweaponslistprimaries();

        if ( !isdefined( a_primaries ) || a_primaries.size < 2 )
            continue;

        foreach ( str_weapon in a_primaries )
        {
            if ( str_weapon == str_fired )
                continue;

            self switchtoweapon( str_weapon );
            wait 0.05;
            self switchtoweapon( str_fired );
            self setspawnweapon( str_fired );
            break;
        }
    }
}

// ----------------------------------------------------------------------------
//  Electric Cherry's missing zap
// ----------------------------------------------------------------------------
//  v1.35.0 fixed the perk's DAMAGE - the guard bug that left player_thread_give
//  unset, so electric_cherry_reload_attack() never started. The sound did not
//  come back with it, and this is why: that function plays
//  "zmb_cherry_explode", and Electric Cherry is a Mob of the Dead perk, so its
//  aliases live in Mob of the Dead's soundbank. On Farm the loaded banks are
//  cmn_root, zmb_common, zmb_patch and zmb_survival_transit - none of them
//  Alcatraz's - so the alias resolves to nothing and the perk fires silently.
//  Exactly the wall the Wunderfizz spin sound is stuck behind, and it cannot be
//  fixed by script: a bank loads from the folder of the zone that declared it.
//
//  ✅ v1.39.0 — IT NOW PLAYS THE REAL SOUND, not a substitute. The mod builds
//  its own soundbank (see build_ff.bat), so zmb_cherry_explode's actual audio -
//  raw\sound\wpn\grenade\taser_mine\explode\tazer_mine, with Alcatraz's own
//  volume, bus and 125/625/750 distance curve - ships inside mod.all under the
//  mod-private name zmqol_cherry_zap and resolves on every map.
//
//  🛑 v1.38.0's substitute was zmb_hellhound_bolt, and the reason the user still
//  heard nothing is that THERE IS NO SUCH ALIAS. Dumping every bank a zombies
//  map can load (cmn_root, zmb_common, zmb_code_post_gfx, and the per-map banks)
//  and searching all of them finds it in none. It was never verified, only
//  described as verified. So was zmb_tombstone_looper in v1.32.0, which produced
//  the same silence for the same reason.
//
//  The check that settles this in seconds, for any alias, before shipping it:
//      Unlinker --include-assets soundbank -o <dir> <map>.ff
//      grep "^<alias>," <dir>\soundbank\*.aliases.csv
//  A missing alias is SILENT, never an error, so nothing in any log will tell
//  you. Look it up.
//
//  The listener itself is unchanged and was always right: stock notifies
//  "electric_cherry_start" on the player one line before its own playsound
//  (_zm_perk_electric_cherry.gsc:271).
//
//  Skipped on the two maps that own the perk, where stock's own alias resolves
//  and playing ours as well would just double the zap.
// ----------------------------------------------------------------------------
qol_opt_cherry_sound()
{
    self endon( "disconnect" );
    level endon( "end_game" );

    if ( level.script == "zm_prison" || level.script == "zm_tomb" )
        return;

    for ( ;; )
    {
        self waittill( "electric_cherry_start" );
        self playsound( "zmqol_cherry_zap" );
    }
}

// ----------------------------------------------------------------------------
//  voice_lines  -  the character's spoken lines, ON by default   (v2.11.26)
// ----------------------------------------------------------------------------
//  User, 2026-09-04, in a TranZit game: *"my characters on all classic maps seem
//  to be never speaking with their voicelines … im playing as stuhlinger right now
//  in tranzit and i haven't heard even one of his voice lines throughout the
//  game … fix the characters' voice lines so they're back to normal"*.
//
//  🛑 THIS FILE WAS THE CAUSE, AND IT SHIPPED THAT WAY FROM THE START. The option
//  came over from BO2-Remix as `disable_player_quotes` with a DEFAULT OF 1 -
//  against this file's own stated policy that every gameplay option is OFF by
//  default - and it was never given a menu row, so there was no way to turn it
//  off. Measured, not inferred: the user's own console_zm.log dvar dump reads
//  `disable_player_quotes "1"`.
//
//  🌟 HOW ONE LINE SILENCED EVERY MAP. The loop pinned self.isspeaking = 1
//  twice a second. _zm_audio::do_player_or_npc_playvox() opens with
//      if ( isdefined( self.isspeaking ) && self.isspeaking )  return;
//  ("Can't play because we are speaking already"), so EVERY line the game asked
//  for was dropped before it reached playsoundontag. Nothing logs, because a
//  dropped line is not an error - which is why it survived this long. The
//  alias tables were never the problem: Plutonium's own dumped alias list for
//  zm_transit carries 2,277 vox_plr_* rows, 568 of them Stuhlinger's.
//
//  🛑 THE RELEASE HAS TO BE A ONE-SHOT, NOT A SECOND PIN. Holding
//  isspeaking = 0 every half second would clobber stock's own book-keeping
//  mid-line and let two lines play over each other - the flag is exactly how
//  stock stops that. So the clear fires only on the transition into "on", and
//  after that this thread never touches the flag again.
// ----------------------------------------------------------------------------
qol_opt_voice_lines()
{
    self endon( "disconnect" );
    level endon( "end_game" );

    b_last = -1;

    for ( ;; )
    {
        b_on = getdvarintdefault( "voice_lines", 1 );

        if ( !b_on )
            self.isspeaking = 1;
        else if ( b_last != 1 )
            self.isspeaking = 0;

        b_last = b_on;
        wait 0.5;
    }
}

// ----------------------------------------------------------------------------
//  night_mode  -  client-side visual dvars only. Nothing server-authoritative
//  changes, so this cannot desync anything.
// ----------------------------------------------------------------------------
qol_opt_night_mode()
{
    self endon( "disconnect" );
    level endon( "end_game" );

    if ( !isdefined( level.qol_default_exposure ) )
    {
        level.qol_default_exposure = getdvar( "r_exposureValue" );
        level.qol_default_sunlight = getdvar( "r_lightTweakSunLight" );
        level.qol_default_skyfactor = getdvar( "r_sky_intensity_factor0" );
    }

    b_on = 0;

    for ( ;; )
    {
        b_want = getdvarintdefault( "night_mode", 0 );

        if ( b_want && !b_on )
        {
            b_on = 1;
            self qol_opt_night_on();
        }
        else if ( !b_want && b_on )
        {
            b_on = 0;
            self qol_opt_night_off();
        }

        wait 0.25;
    }
}

qol_opt_night_on()
{
    if ( zmqol_minimal() )
        return;

    //  ========================================================================
    //  v1.59.3 - WHY THIS USED TO RENDER A BLACK SCREEN.
    //
    //  User, twice: "the night mode toggle command in console still is scuffed
    //  as hell, when i enable it the screen seems to go just black."
    //
    //  Two findings, both from Plutonium's own dvar_descriptions.json rather
    //  than from reasoning:
    //
    //  1. "r_exposureValue": "exposure ev stops". It is an EV OFFSET, and every
    //     stop HALVES the image. The old values came from Remix - 3.9 by
    //     default, up to 5.6 on Nuketown - which is between 1/15th and 1/48th
    //     brightness. That is the black screen, on its own, with nothing else
    //     wrong.
    //
    //  2. 🛑 THE ENTIRE vc_* FAMILY DOES NOT EXIST ON THIS BUILD. vc_yl, vc_yh,
    //     vc_rgbl and vc_rgbh return ZERO matches in dvar_descriptions.json,
    //     while r_exposureValue and r_filmUseTweaks are both present. Those four
    //     lines were the half that tinted the picture blue and lifted it back
    //     up - so only the darkening half ever applied. They are deleted rather
    //     than left in: a setclientdvar to a non-existent dvar is silent, and
    //     four silent lines are exactly what made this look like a colour
    //     problem instead of an exposure one.
    //
    //  The port was faithful to Remix. Remix simply targets a build where the
    //  other half of it works.
    //
    //  📝 TUNABLE, because the RIGHT number needs eyes and this has already
    //  cost boots. Default 1.25 stops - a bit over half brightness, which reads
    //  as dusk rather than a blackout. Change it live with:
    //        night_exposure 2      (darker)
    //        night_exposure 0.75   (lighter)
    //  then tell me the value that looks right and it becomes the default.
    //  ========================================================================
    //  ========================================================================
    //  v1.59.5 - PORTED FROM THE WORKING MOD, after three failed attempts at
    //  reasoning it out from dvar descriptions.
    //
    //  Source: BO2-GSC-Releases\Zombies Mods\Nightmode\Source Code\
    //          _zm_nightmode.gsc  - a dedicated, shipped night-mode mod.
    //
    //  🛑 THE BLACK SCREEN WAS A DUPLICATED LINE IN REMIX. This mod's values
    //  came from BO2-Remix\src\scripts\zm\remix\_visual.gsc, which sets vc_rgbh
    //  TWICE:
    //        line 86:  vc_rgbh  "0.07 0 0.25 0"      <- the real value
    //        line 90:  vc_rgbh  "0.015 0 0.07 0"     <- overwrites it
    //  vc_rgbh is the HIGHLIGHT end of the grade. Capped at 0.015 the brightest
    //  the picture can ever be is ~1.5%, which is a black screen. The working
    //  mod sets it ONCE, to "0.1 0 0.3 0". Remix's second line is a bug that
    //  was faithfully copied in.
    //
    //  Two more values were wrong in the same way, and both push the same
    //  direction:
    //        r_lightTweakSunLight      zm_qol 16  ->  working mod 1
    //        r_sky_intensity_factor0   zm_qol 3   ->  working mod 0
    //
    //  📝 AND I WAS WRONG ABOUT vc_* NOT EXISTING (v1.59.3/v1.59.4). They are
    //  absent from Plutonium's dvar_descriptions.json, and I read that as "not
    //  on this build". That file documents dvars; it does not enumerate every
    //  tweak dvar. A shipped mod depends on these and works. Absence from a
    //  description list is not absence from the engine - do not repeat that
    //  inference.
    //
    //  vc_fbm / vc_fsm are the baseline the working mod sets before any of the
    //  tweaks; they were never ported and are included now.
    //
    //  Deliberately NOT ported: r_lodBiasRigid / r_lodBiasSkinned at -1000.
    //  They force maximum model detail - a performance change, unrelated to
    //  darkness, and not something to inflict as a side effect of a light
    //  toggle.
    //  ========================================================================
    self setclientdvar( "r_dof_enable", 0 );
    self setclientdvar( "r_enablePlayerShadow", 1 );
    self setclientdvar( "r_skyTransition", 1 );
    self setclientdvar( "sm_sunquality", 2 );
    self setclientdvar( "vc_fbm", "0 0 0 0" );
    self setclientdvar( "vc_fsm", "1 1 1 1" );

    self setclientdvar( "r_filmUseTweaks", 1 );
    self setclientdvar( "r_bloomTweaks", 1 );
    self setclientdvar( "r_exposureTweak", 1 );
    self setclientdvar( "vc_rgbh", "0.1 0 0.3 0" );
    self setclientdvar( "vc_yl", "0 0 0.25 0" );
    self setclientdvar( "vc_yh", "0.02 0 0.1 0" );
    self setclientdvar( "vc_rgbl", "0.02 0 0.1 0" );
    self setclientdvar( "r_lightTweakSunLight", 1 );
    self setclientdvar( "r_sky_intensity_factor0", 0 );

    n_exposure = 3.9;

    if ( level.script == "zm_buried" )
        n_exposure = 3.5;
    else if ( level.script == "zm_tomb" )
        n_exposure = 4;
    else if ( level.script == "zm_nuked" )
        n_exposure = 5.6;
    else if ( level.script == "zm_highrise" )
        n_exposure = 3.9;

    self setclientdvar( "r_exposureValue", n_exposure );

    //  v1.99.18 - stashed so anything that has to SUSPEND night mode for a
    //  moment can put it back exactly, without a second copy of the table
    //  above. Who's Who is the first caller: its screen effect is a bright
    //  blowout and cannot read at 1/15 brightness, so it drops
    //  r_exposureTweak while the ghost state is up and restores from here.
    //  quality_of_life.gsc::zmqol_whoswho_overlay_off().
    self.qol_night_exposure = n_exposure;

    //  Buried, Mob and Origins actively re-assert their own lighting, so the
    //  working mod holds the values down in a loop. Ported with it.
    self thread qol_opt_night_visual_fix();

    println( "[zm_qol] night_mode ON - ported from _zm_nightmode.gsc, exposure " + n_exposure );
}

// ----------------------------------------------------------------------------
//  qol_opt_night_visual_fix  -  straight port of visual_fix() from
//  BO2-GSC-Releases\Zombies Mods\Nightmode\Source Code\_zm_nightmode.gsc
//
//  Three maps fight the settings back after they are applied - Buried re-raises
//  the sky, Mob and Origins re-raise the sun - so the values are re-asserted
//  until they stick. Without this those maps look untouched, which is exactly
//  the "does nothing at all" failure mode to avoid.
//
//  float() around the getdvar reads: getdvar returns a STRING, and the upstream
//  loop compares and decrements it directly. That is the one place this port
//  deviates, and only to make the comparison numeric rather than relying on
//  string coercion.
//
//  ========================================================================
//  🛑 v1.90.3 - THIS LOOP WAS KILLING ORIGINS, MOB AND BURIED AT 0:06.
//
//  User, 2026-08-14: Origins, Mob and Buried all failed to reach the game
//  with "CL_CGameNeedsServerCommand: A reliable command was cycled out."
//  TranZit and Die Rise were fine. All three died at exactly 0:06 server
//  time (games_mp.log), which is a threshold, not a race.
//
//  🌟 setclientdvar IS A RELIABLE SERVER COMMAND, and this function emitted
//  20 (prison/tomb) to 40 (buried) of them PER SECOND, from spawn, forever.
//  Six seconds of that is ~120-240 queued commands; the client's reliable
//  ring holds 128, so the oldest was overwritten before the client - still
//  loading, not yet acking - had read it. That is the error, verbatim.
//
//  🛑 AND THE EXIT CONDITION COULD NEVER BE TRUE. setclientdvar does not
//  write back into the value the SERVER's getdvar() returns. Measured, not
//  assumed: across 13 logged games the load-time dvar dump reports
//  r_exposureValue "3" and r_sky_intensity_factor0 "1" every single time,
//  including immediately after night mode set them to 3.5/3.9/4 and 0. So
//  `while ( getdvar(...) != 0 )` was always an infinite loop - here AND in
//  the source mod, where the same line compares a string to an int. It is
//  written as for(;;) now because that is what it always was; pretending
//  otherwise hid the real cost of the wait.
//
//  📝 WHY IT ONLY SURFACED NOW. It needs a second per-frame consumer to tip
//  it over: every one of these maps booted fine yesterday with night mode
//  ON and the velocity meter OFF, and died today with both ON. Nine games,
//  no counterexample. The meter is not the bug - it is one hudelem on
//  setvalue() - it is simply the load that exposed this one.
//
//  THE FIX IS A RATE CUT, NOT A RETUNE. The prison/tomb ramp keeps its
//  exact trajectory: it was 0.05 units per 0.05s and is now 0.2 per 0.2s -
//  the same 1.0 units/second, from the same start value to the same 0.
//  Buried's clamp is unchanged except that it re-asserts every 0.2s rather
//  than every 0.05s. Worst case over the first six seconds drops from
//  120-240 commands to 30-60, comfortably inside the ring.
//  ========================================================================
// ----------------------------------------------------------------------------
qol_opt_night_visual_fix()
{
    level endon( "game_ended" );
    self endon( "disconnect" );
    self endon( "disable_nightmode" );

    //  ========================================================================
    //  🛑 v1.93.1 - THIS RAN FOREVER AND IT IS WHY MOB OF THE DEAD DIED AT ~12s
    //  WITH CL_CGameNeedsServerCommand: EXE_ERR_RELIABLE_CYCLED_OUT.
    //
    //  Read the ORIGINAL, _zm_nightmode.gsc::visual_fix(), before changing this
    //  again. It is:
    //
    //      while( getDvar( "r_lightTweakSunLight" ) != 0 )
    //      {
    //          for( i = getDvar( "r_lightTweakSunLight" ); i >= 0; i -= 0.05 )
    //          { self setclientdvar( "r_lightTweakSunLight", i ); wait 0.05; }
    //          wait 0.05;
    //      }
    //
    //  That `while` is the author's own stop condition: ramp until the value is
    //  0, then stop. 🌟 IT CAN NEVER BE SATISFIED - setclientdvar does NOT write
    //  back into what the SERVER's getdvar() returns (proven in this project
    //  from 13 games of dvar dumps, see [[t6-plutonium-...]] and checkpoint 43).
    //  So the source mod's loop is infinite too; it is a latent bug there.
    //
    //  This port then dropped the `while` entirely for a bare for(;;), and
    //  v1.90.3 "fixed" the resulting flood by cutting the rate 4x (0.05 -> 0.2).
    //  🛑 A RATE CUT IS THE WRONG SHAPE. An unbounded stream fills the client's
    //  128-entry reliable ring eventually no matter how slow it is - the cut
    //  only moved the crash from 0:06 to 0:12, which is exactly what the
    //  2026-08-14 Mob log shows.
    //
    //  So: ramp ONCE and stop, which is what the original's `while` was written
    //  to do. That is parity with the author's intent, not a re-tune. Total
    //  cost is ~22 reliable commands on Mob/Origins and 2 on Buried, once, on a
    //  ring that holds 128 - instead of a permanent 5/sec.
    //
    //  📝 The step is back to the original's 0.05 because the ramp is now a
    //  one-shot: 0.2 was only ever there to slow the flood, and it made the
    //  fade visibly chunky.
    //  ========================================================================
    if ( level.script == "zm_buried" )
    {
        self setclientdvar( "r_lightTweakSunLight", 1 );
        self setclientdvar( "r_sky_intensity_factor0", 0 );
        return;
    }

    if ( level.script == "zm_prison" || level.script == "zm_tomb" )
    {
        n_start = float( getdvar( "r_lightTweakSunLight" ) );

        //  🛑 THE RAMP IS BOUNDED ON PURPOSE. Every step is one reliable
        //  command and the client's ring holds 128. The measured live value on
        //  Mob is exactly 1 ("r_lightTweakSunLight \"1\"" in the 2026-08-14
        //  dvar dump), i.e. 21 steps - but a map, a config or a user setting it
        //  higher must not be able to turn this back into the flood it just
        //  stopped being. Capping at 2 keeps the worst case at 41 commands,
        //  under a third of the ring.
        if ( n_start > 2 )
            n_start = 2;

        for ( i = n_start; i >= 0; i = ( i - 0.05 ) )
        {
            self setclientdvar( "r_lightTweakSunLight", i );
            wait 0.05;
        }

        //  Land exactly on 0 rather than on whatever the last step happened to
        //  be - the loop exits on i < 0, so the final written value could be a
        //  small positive number if the starting value is not a multiple of the
        //  step. One extra command, and it removes the doubt.
        self setclientdvar( "r_lightTweakSunLight", 0 );
    }
}

qol_opt_night_off()
{
    //  Undo the light grid, and explicitly clear the three overrides older
    //  builds switched on - anyone toggling night mode after running v1.59.3 or
    //  earlier may still have r_filmUseTweaks stuck at 1 from that session, and
    //  that alone is the black screen. Clearing them here makes turning night
    //  mode OFF a way out of it rather than a no-op.
    //  🛑 FIRST, and it is still not optional even though the reason changed in
    //  v1.93.1. qol_opt_night_visual_fix() endons on this notify. It used to run
    //  forever, so without the notify the restore below was overwritten within
    //  0.05s; it now ramps once and returns, so the only window is the ~1s the
    //  Mob/Origins ramp is still stepping - toggle night mode off inside that
    //  window without this notify and the ramp would fight the restore.
    //  disable_night_mode() in the source mod opens with the same notify.
    self notify( "disable_nightmode" );

    //  v1.99.18 - night mode is no longer applied, so there is nothing for a
    //  suspend/restore caller to put back. Cleared here so it cannot restore a
    //  stale value from an earlier toggle.
    self.qol_night_exposure = undefined;

    self setclientdvar( "r_lightGridEnableTweaks", 0 );
    self setclientdvar( "r_lightGridIntensity", 1 );
    self setclientdvar( "r_filmUseTweaks", 0 );
    self setclientdvar( "r_bloomTweaks", 0 );
    self setclientdvar( "r_exposureTweak", 0 );

    //  The grade itself, cleared exactly as the source mod's
    //  disable_night_mode() does. Without these the blue tint survives the
    //  toggle even with the film override off.
    self setclientdvar( "vc_rgbh", "0 0 0 0" );
    self setclientdvar( "vc_yl",   "0 0 0 0" );
    self setclientdvar( "vc_yh",   "0 0 0 0" );
    self setclientdvar( "vc_rgbl", "0 0 0 0" );

    if ( isdefined( level.qol_default_exposure ) )
    {
        self setclientdvar( "r_exposureValue", level.qol_default_exposure );
        self setclientdvar( "r_lightTweakSunLight", level.qol_default_sunlight );
        self setclientdvar( "r_sky_intensity_factor0", level.qol_default_skyfactor );
    }

    //  ========================================================================
    //  🛑 v1.99.54 - PUT DEPTH OF FIELD BACK THE WAY THE ADVANCED TAB HAS IT.
    //
    //  qol_opt_night_on() sets r_dof_enable 0 as part of the ported night look
    //  (it is one of the donor mod's own lines and it stays), but the donor's
    //  disable_night_mode() never puts it back - it had no depth-of-field
    //  option to put back. From v1.99.54 this mod does: stock's ADVANCED tab
    //  DEPTH OF FIELD row is HIGH / MEDIUM / LOW / DISABLED and it owns
    //  r_dof_enable. Without this line, one trip through night mode leaves the
    //  row reading HIGH while nothing is drawn, for the rest of the session.
    //
    //  dof_quality is that row's own dvar: 0 = DISABLED, 1 / 2 / 3 = LOW /
    //  MEDIUM / HIGH. Read rather than remembered on purpose - a value saved on
    //  the way in would be stale if the row were changed while night mode was
    //  on, and would then overwrite the player's newer choice.
    //  ========================================================================
    if ( getdvarintdefault( "dof_quality", 0 ) > 0 )
        self setclientdvar( "r_dof_enable", "1" );

}

// ----------------------------------------------------------------------------
//  character
// ----------------------------------------------------------------------------
//  🛑 DELIBERATELY NOT A COPY OF REMIX'S VERSION, AND THIS IS THE IMPORTANT
//  COMMENT IN THIS FILE.
//
//  Remix hardcodes the models: setmodel( "c_zom_player_oldman_fb" ),
//  setviewmodel( "c_zom_oldman_viewhands" ), and so on for the TranZit crew.
//  Those models are NOT on every map. Unlinker --list over every fastfile a
//  Farm survival game loads finds exactly two player bodies -
//  c_zom_player_cdc_fb and c_zom_player_cia_fb - because survival uses the
//  CDC/CIA teams rather than the crew. Setting a model the level never shipped
//  gives an invisible player, the same failure that made the Wunderfizz bottle
//  vanish.
//
//  So this sets characterindex and calls the LEVEL'S OWN character function
//  instead. Stock give_personality_characters() already switches on exactly
//  that variable (zm_transit.gsc:1153) and stock even has a dev-only force_char
//  dvar doing this very thing at :1149 - but inside a /# #/ block, so it is
//  stripped from the release build and unreachable from the console. This is
//  that, made available.
//
//  Because the level picks the model, it can only ever pick one the level has.
//  On Farm you get the CDC/CIA variants, on TranZit proper the crew - and on
//  Origins and Mob of the Dead nothing happens, which is correct: their
//  characters are story-fixed and stock guards them the same way.
// ----------------------------------------------------------------------------
qol_opt_character()
{
    self endon( "disconnect" );

    //  🛑 v1.99.65 - NOT AN EARLY RETURN ANY MORE. level.givecustomcharacters is
    //  assigned during the map's own main()/preinit, and a player thread can
    //  start before that; returning here killed the picker for the whole match.
    //  The loop below tests it every pass instead.

    //  ========================================================================
    //  🛑 v1.99.58 - TWO EARLY RETURNS REMOVED, AND BOTH WERE WRONG.
    //
    //  This function used to refuse to run in two cases. The comment above
    //  claimed *"on Origins and Mob of the Dead nothing happens, which is
    //  correct: their characters are story-fixed and stock guards them the same
    //  way."* That is FALSE, and the stock dump says so plainly:
    //
    //      zm_prison.gsc:51   level.givecustomcharacters = ::give_personality_characters;
    //      zm_tomb.gsc:156    level.givecustomcharacters = ::give_personality_characters;
    //
    //  Both switch on self.characterindex exactly the way TranZit does - Origins
    //  cycles Dempsey / Nikolai / Richtofen / Takeo and Mob cycles Finn / Sal /
    //  Billy / Arlington. Neither is story-fixed in classic, so the map gate was
    //  blocking two maps that work perfectly.
    //
    //      if ( level.script == "zm_tomb" || level.script == "zm_prison" ) return;
    //
    //  The second refusal was force_team_characters, which zm_tomb.gsc:71 sets
    //  in survival_init() - i.e. exactly the SURVIVAL case the new lobby row is
    //  for. And give_team_characters() (zm_buried.gsc) honours characterindex
    //  too: 0 and 2 give the CIA model, 1 and 3 the CDC one. So that guard was
    //  refusing the one path it was supposed to protect.
    //
    //  What still stops it is the real precondition, checked above: a map with
    //  no level.givecustomcharacters at all cannot switch anybody, and that is
    //  the only condition that actually matters.
    //  ========================================================================

    n_last = -1;
    b_last_saw_cia_flag = 0;
    b_seen_once = 0;
    //  v2.13.0 - co-op. Remembers the level's own CIA/CDC value so a RESTART
    //  LEVEL reroll can be spotted and this player's pick re-applied. See the
    //  borrow-and-restore block further down for why the drift check that used
    //  to do this job cannot work once more than one player is picking.
    n_last_cia_value = undefined;

    for ( ;; )
    {
        if ( !isdefined( level.givecustomcharacters ) )
        {
            wait 0.5;
            continue;
        }

        //  ====================================================================
        //  🛑 v2.13.0 - THE PICK IS PER-PLAYER NOW. THE DVAR ALONE COULD NEVER
        //  WORK IN CO-OP, AND THAT IS WHY NOBODY BUT THE HOST COULD CHOOSE.
        //
        //  `character` is a SERVER dvar. The menu row and the console both write
        //  it, and on the host's machine client and server share one dvar space,
        //  so the host's pick took. A remote player's menu writes their OWN
        //  local dvar; the server never sees it. Worse, every player's copy of
        //  this thread read that same server dvar, so all four were assigned the
        //  same characterindex and the whole team wore one face.
        //
        //  🌟 THE ONLY PROVEN CLIENT-TO-SERVER CHANNEL IN THIS ENGINE IS CHAT.
        //  There is no getclientdvar in T6 - checked against the GSC reference,
        //  no such builtin - and a client console command never reaches the
        //  server. The "say" notify does, and it carries the SPEAKING PLAYER,
        //  which this mod's command listener has relied on since v1.5.0. So
        //  `.character N` sets self.zmqol_char_want on whoever typed it, and
        //  that is what this loop reads first.
        //
        //  The dvar stays as the fallback, so nothing that worked before stops
        //  working: the lobby/menu row is still the default for anyone who has
        //  not made a personal pick, and solo is completely unchanged.
        //  ====================================================================
        if ( isdefined( self.zmqol_char_want ) )
            n_want = self.zmqol_char_want;
        else
            n_want = getdvarintdefault( "character", 0 );

        b_sees_cia_flag = isdefined( level.should_use_cia );
        b_is_coop = get_players().size > 1;

        // ========================================================================
        //  🛑 v2.3.5 - RESTART LEVEL RE-ROLLS should_use_cia AND THIS LOOP NEVER
        //  NOTICED, BECAUSE "NOTHING CHANGED" FROM ITS OWN POINT OF VIEW.
        //
        //  User, 2026-08-25: lobby character = CIA, start Diner survival, pause
        //  -> RESTART LEVEL, scoreboard now shows CDC. Pause -> instant exit ->
        //  fresh start -> CIA again, correctly. So a fresh load is right and a
        //  restart is wrong, and the difference is exactly this: a restart does
        //  NOT disconnect the player (this thread's self endon("disconnect")
        //  never fires, so n_last/b_last_saw_cia_flag survive it untouched), but
        //  it DOES re-run the map's own survival_init() - zm_transit.gsc:88-92
        //  rerolls `should_use_cia = 0; if ( randomint(100) > 50 )
        //  should_use_cia = 1;` on every level start, restart included.
        //
        //  So after a restart: n_want == n_last (the dvar never changed) and
        //  b_last_saw_cia_flag is already 1 (set the first time this ran, before
        //  the restart) - both terms of the reapply check below are false, so
        //  the block is skipped and should_use_cia is left at whatever the fresh
        //  reroll produced, which is CDC roughly half the time. This is the same
        //  race v1.99.65 already fixed once, just from a different trigger.
        //
        //  🌟 THE FIX WATCHES THE VALUE, NOT JUST WHETHER THE FLAG EXISTS. Every
        //  pass, once a pick has actually been applied once (b_seen_once),
        //  recompute what should_use_cia OUGHT to be from n_want alone (not from
        //  self.characterindex - that field is only written inside this same
        //  block, so on the very tick that needs to catch a reroll it would
        //  still hold the value from before the restart) and compare it to the
        //  live value. A mismatch reapplies exactly like a real dvar change.
        //  🛑 DEFAULT STAYS RANDOM: gated on n_want > 0, so character 0 never
        //  touches should_use_cia and the vanilla random roll is untouched.
        // ========================================================================
        b_should_use_cia_drifted = 0;

        //  🛑 v2.13.0 - SOLO ONLY. This test asks "does the level's CIA/CDC
        //  value still match MY pick", which is only a sane question while this
        //  player owns that value. In co-op the level value belongs to the map's
        //  own roll (see the borrow-and-restore block below), so an unmatched
        //  value is the normal state and this would have re-applied the
        //  character on every 0.5s pass, forever.
        if ( !b_is_coop && n_want > 0 && b_sees_cia_flag && b_seen_once )
        {
            n_would_be_index = ( n_want - 1 ) % 4;
            b_would_want_cia = ( n_would_be_index == 0 || n_would_be_index == 2 );

            if ( ( level.should_use_cia == 1 ) != b_would_want_cia )
                b_should_use_cia_drifted = 1;
        }

        //  The co-op replacement, and it asks a different question: "has the
        //  LEVEL's value moved on its own since I last looked". Only a RESTART
        //  LEVEL does that - survival_init rerolls it - which is exactly the
        //  v2.3.5 case, and it fires once per reroll instead of every pass.
        //  Nothing this function does can trip it, because the borrow below puts
        //  the value back before this thread ever yields.
        b_cia_value_rerolled = 0;

        if ( b_sees_cia_flag )
        {
            if ( isdefined( n_last_cia_value ) && n_last_cia_value != level.should_use_cia && b_seen_once )
                b_cia_value_rerolled = 1;

            n_last_cia_value = level.should_use_cia;
        }

        //  ====================================================================
        //  🛑 v1.99.65 - THIS USED TO FIRE ONCE AND LATCH, AND ON A CDC/CIA MAP
        //  THAT MADE THE LOBBY PICKER PICK THE WRONG TEAM.
        //
        //  User, 2026-08-19: *"in the pre-game menu i set the character override
        //  to CIA and started the match with the CDC viewarm/player model"* -
        //  while `character 1` typed at the console MID-GAME worked. Those two
        //  facts together name the cause exactly.
        //
        //  level.should_use_cia is set by the map's survival_init()
        //  (zm_nuked.gsc:41-44, zm_transit.gsc:88-92, zm_tomb.gsc:72-75), but
        //  level.givecustomcharacters is set earlier, in main() (zm_nuked.gsc:98).
        //  So there is a window where this loop can run with the character
        //  function available and the team flag NOT yet defined. In that window
        //  the block below skips the should_use_cia write, give_team_characters()
        //  reads whatever the random roll left, and the player is dressed as the
        //  wrong team - and because n_last was already set, it never tried again.
        //  Typing the dvar later lands outside the window, which is exactly why
        //  the console worked and the lobby did not.
        //
        //  🌟 THE FIX IS TO RE-APPLY WHEN THE FLAG TURNS UP. One extra condition:
        //  the choice changed, OR should_use_cia has appeared since the last
        //  application. It can fire at most twice per choice and it is the same
        //  code path both times.
        //
        //  v2.3.5 adds a THIRD: b_should_use_cia_drifted, computed above -
        //  catches a RESTART LEVEL reroll with no dvar change at all. See its
        //  own comment block for the mechanism.
        //  ====================================================================
        b_real_change = n_want != n_last;

        if ( n_want > 0 && ( b_real_change || ( b_sees_cia_flag && !b_last_saw_cia_flag ) || b_should_use_cia_drifted || b_cia_value_rerolled ) )
        {
            n_last = n_want;
            b_last_saw_cia_flag = b_sees_cia_flag;
            //  1-4 in the console maps to characterindex 0-3, so the dvar reads
            //  the way a player expects rather than exposing the engine index.
            self.characterindex = ( n_want - 1 ) % 4;

            //  ================================================================
            //  🛑 v1.99.59 - ON THE TEAM MAPS, characterindex IS IGNORED, AND
            //  THAT IS WHY THE LOBBY PICKER DID NOTHING ON DINER SURVIVAL.
            //
            //  The two give_team_characters() implementations are NOT the same
            //  function, and v1.99.58 was written against the wrong one:
            //
            //    zm_buried.gsc   switches on self.characterindex - 0 and 2 give
            //                    the CIA model, 1 and 3 the CDC one.
            //    zm_transit.gsc:1076  checks level.should_use_cia FIRST, and if
            //                    it is defined it uses that ALONE, sets the
            //                    model from it and then OVERWRITES
            //                    self.characterindex with 0 or 1 on the way out.
            //                    The characterindex switch is only the `else`.
            //
            //  zm_transit's survival init defines should_use_cia every time
            //  (:88-92, `should_use_cia = 0; if ( randomint( 100 ) > 50 )
            //  should_use_cia = 1;`), so on Diner/Farm/Town the else branch is
            //  unreachable and setting characterindex could never have worked.
            //  Origins' survival_init() does the same thing (zm_tomb.gsc:72-75).
            //
            //  So on those maps the team is chosen through should_use_cia, and
            //  it has to be set BEFORE givecustomcharacters is called. CIA is
            //  characterindex 0 in both implementations, which is what keeps the
            //  lobby's ordering (1 = CIA, 2 = CDC) true on every map.
            //
            //  📝 It is a LEVEL variable, so in coop it is the whole team's
            //  model, not one player's - the same host-scoped limitation the
            //  lobby row already carries. Nothing else in either map reads it:
            //  zm_transit uses it only at :88-92 and inside
            //  give_team_characters().
            //  ================================================================
            //  ================================================================
            //  🛑 v2.13.0 - IN CO-OP THE LEVEL FLAG IS BORROWED AND PUT BACK,
            //  SO EACH PLAYER GETS THEIR OWN LOOK AND NOTHING ELSE NOTICES.
            //
            //  The note above is right that should_use_cia is a LEVEL variable,
            //  and the old code simply wrote it - which in co-op meant the last
            //  player to pick dressed the entire team, and the whole lobby
            //  changed clothes every time anybody chose.
            //
            //  🛑 THE FIX IS NOT TO setmodel() DIRECTLY. That is the trap this
            //  file's own header warns about, and the model names are NOT the
            //  same on every map - measured in the stock dump:
            //      zm_transit / zm_nuked / zm_tomb   c_zom_player_cia_fb
            //      zm_buried                          c_zom_player_cia_dlc1_fb
            //      zm_nuked viewhands                 c_zom_hazmat_viewhands_light
            //  Hardcoding any of those gives an invisible player on the maps
            //  that ship the other name.
            //
            //  🌟 SO LET THE MAP PICK, AND LIE TO IT FOR ONE CALL. Set the level
            //  flag to what THIS player wants, call the map's own
            //  givecustomcharacters (which then chooses the correct models for
            //  the map it belongs to), and put the flag straight back.
            //
            //  🌟 THE BORROW IS ATOMIC, AND THAT IS MEASURED, NOT HOPED FOR. GSC
            //  is cooperative - a thread only yields at a wait - and none of the
            //  four give_team_characters() implementations contains a wait,
            //  waittill or flag_wait (checked in the stock dump for zm_transit,
            //  zm_buried, zm_nuked and zm_tomb). So no other thread can ever
            //  observe the borrowed value.
            //
            //  Solo keeps the old behaviour EXACTLY - it really does own the
            //  level value there, and the stock readers that also look at it
            //  (_globallogic_player.gsc:278, zcleansed.gsc:51, zm_nuked.gsc:654)
            //  must keep seeing the player's choice.
            //  ================================================================
            self.favorite_wall_weapons_list = [];

            if ( isdefined( level.should_use_cia ) )
            {
                if ( self.characterindex == 0 || self.characterindex == 2 )
                    n_want_cia = 1;
                else
                    n_want_cia = 0;

                if ( b_is_coop )
                {
                    n_saved_cia = level.should_use_cia;
                    level.should_use_cia = n_want_cia;
                    self [[ level.givecustomcharacters ]]();
                    level.should_use_cia = n_saved_cia;
                    n_last_cia_value = level.should_use_cia;
                }
                else
                {
                    level.should_use_cia = n_want_cia;
                    self [[ level.givecustomcharacters ]]();
                }
            }
            else
            {
                self [[ level.givecustomcharacters ]]();
            }

            //  ================================================================
            //  🛑 v1.99.66 - THE SCOREBOARD BADGE CANNOT FOLLOW A MID-MATCH
            //  SWITCH, AND THAT IS MEASURED, NOT ASSUMED.
            //
            //  The emblem watcher logs every write. On the user's 2026-08-19
            //  test the log reads:
            //      [zm_qol] scoreboard emblem -> faction_cia (should_use_cia=1)
            //      [zm_qol] scoreboard emblem -> faction_cdc (should_use_cia=0)
            //  so g_TeamIcon_Allies WAS changed to faction_cdc the moment
            //  `character 2` ran - and the scoreboard still drew CIA. The icon is
            //  therefore resolved when the scoreboard is built, not when it is
            //  opened, and setdvar is the only lever GSC has (_scoreboard.gsc is
            //  four setdvar calls and nothing else).
            //
            //  So the pre-game pick is correct - the user confirmed it - and the
            //  console path says so rather than pretending. Say it once, and only
            //  for a change made after the first application, so the normal
            //  spawn-time pick stays silent.
            //
            //  v2.3.5 - gated on b_real_change specifically now, not just
            //  b_seen_once, so a silent RESTART LEVEL drift-correction (the
            //  player did nothing) does not print a message about a "change"
            //  that, from their side, never happened.
            //  ================================================================
            if ( b_seen_once && b_real_change && isdefined( level.should_use_cia ) )
                self iprintln( "^3[zm_qol] ^7character changed ^3- the scoreboard badge is fixed when the match starts and cannot follow" );

            b_seen_once = 1;
        }

        wait 0.5;
    }
}

// ============================================================================
//  qol_opt_starting_pistol  -  STARTING PISTOL lobby row (user, 2026-09-11)
//
//  The lobby row (ui_mp\t6\menus\privategamelobby_project.lua, QolStartingPistol,
//  rendered above CHARACTER on every map and mode) writes `starting_pistol`:
//      0 = DEFAULT - this map's own pistol, stock behaviour, the shipped default
//      1 = M1911   (m1911_zm)   2 = MAUSER (c96_zm)   3 = TAC-45 (fnp45_zm)
//
//  🌟 TWO HALVES, because neither half alone covers every spawn path. The level
//  half repoints level.start_weapon (plus the three laststand pistol vars stock
//  derives from the same choice) before the first spawn, so the spawn itself,
//  Who's Who revives, Turned/Grief respawns and the downed pistol all hand over
//  the wanted gun through stock's own give_start_weapon(). The player half is
//  the safety net: on first spawn it checks what is actually in the player's
//  hands and swaps if the level half missed (init ordering is not something
//  this project owns, so it is not bet on). Both are idempotent and both
//  no-op on 0, so DEFAULT is byte-for-byte stock.
//
//  🛑 NO NEW PRECACHE SLOTS. m1911 is stock on every map and c96 is stock on
//  Origins plus this mod's per-map includes on the other five (each map's own
//  scripts\zm\<map>\ file, base and upgraded), so options 1-2 are always
//  resolvable. The Tac-45 rides in the MP-weapons box pool
//  (quality_of_life.gsc::zmqol_mp_weapons_init); if that pool is off the gun
//  was never precached, so asking for it falls back to stock with a log line
//  rather than handing over a weapon that does not exist. Origins' precache
//  ceiling (v2.15.3) is why nothing is precached here to "make sure".
//
//  🛑 ROOT SCRIPT, NO MAP REFERENCES (AI_CONTEXT rule 2): only weapon names,
//  the dvar and level vars. Nothing here names a map, so it loads everywhere.
//
//  📝 CO-OP: `starting_pistol` is a server dvar, so the lobby row is the host's
//  choice for the whole team - the same standing limitation the CHARACTER row
//  carries (its per-player path needed the chat channel; this has none).
// ============================================================================
qol_opt_starting_pistol_name( n_choice )
{
    if ( n_choice == 1 )
        return "m1911_zm";
    if ( n_choice == 2 )
        return "c96_zm";
    if ( n_choice == 3 )
        return "fnp45_zm";
    return undefined;
}

qol_opt_starting_pistol_upgraded( str_base )
{
    if ( str_base == "c96_zm" )
        return "c96_upgraded_zm";
    if ( str_base == "fnp45_zm" )
        return "fnp45_upgraded_zm";
    return "m1911_upgraded_zm";
}

//  Mapping plus the include check. Returns the weapon to spawn with, or
//  undefined for DEFAULT / out-of-range / not-included (all three mean stock).
qol_opt_starting_pistol_validated()
{
    str_want = qol_opt_starting_pistol_name( getdvarintdefault( "starting_pistol", 0 ) );

    if ( !isdefined( str_want ) )
        return undefined;

    if ( !isdefined( level.zombie_include_weapons ) || !isdefined( level.zombie_include_weapons[str_want] ) )
    {
        println( "[zm_qol] starting pistol: " + str_want + " is not included on this map - left stock" );
        return undefined;
    }

    return str_want;
}

qol_opt_starting_pistol()
{
    level endon( "end_game" );

    //  initial_players_connected fires after every map init - including
    //  Origins' custom_add_weapons override of level.start_weapon - and before
    //  the first spawn, which is exactly the window this needs.
    flag_wait( "initial_players_connected" );

    if ( !isdefined( level.start_weapon ) )
        return;

    str_want = qol_opt_starting_pistol_validated();

    if ( !isdefined( str_want ) || level.start_weapon == str_want )
        return;

    level.start_weapon = str_want;
    level.laststandpistol = str_want;
    level.default_laststandpistol = str_want;
    level.default_solo_laststandpistol = qol_opt_starting_pistol_upgraded( str_want );

    println( "[zm_qol] starting pistol: spawn and laststand repointed at " + str_want );
}

//  Safety net, first spawn only - the caller (qol_opt_player_init) starts this
//  once, on the first spawned_player, so no waittill here: the player is
//  already spawning and stock's pistol is either here or a moment away.
qol_opt_starting_pistol_player()
{
    self endon( "disconnect" );
    level endon( "end_game" );

    str_want = qol_opt_starting_pistol_validated();

    if ( !isdefined( str_want ) )
        return;

    //  Wait for stock's pistol to arrive (up to 2s, same polling shape as the
    //  Who's Who knife watch). If the level half already repointed the spawn,
    //  the wanted pistol is what arrives and the first check returns.
    n_wait = 0;

    for ( ;; )
    {
        if ( self hasweapon( str_want ) )
            return;

        if ( isdefined( level.start_weapon ) && level.start_weapon != str_want && self hasweapon( level.start_weapon ) )
            break;

        n_wait++;

        if ( n_wait >= 40 )
            return;

        wait 0.05;
    }

    //  🛑 STOCK AMMO, NOT MAX - drain the shared pool first (user, 2026-09-11:
    //  option pistols spawned with full reserves). The C96 and the M1911 share
    //  ONE ammo pool (both defs: ammoName ".45acp m1911", measured) and
    //  takeweapon leaves the pool behind, so swapping onto a pool that still
    //  holds the stock pistol's rounds overfills the new gun. Zeroing the pool
    //  before the take puts giveweapon+givestartammo on the exact same empty
    //  pool a clean stock spawn starts from - so the result is byte-for-byte
    //  stock spawn ammo whatever those two builtins' add-vs-set semantics are.
    //  Harmless when the pool is not shared (Tac-45) or already empty.
    self setweaponammostock( level.start_weapon, 0 );
    self takeweapon( level.start_weapon );
    self giveweapon( str_want );
    self givestartammo( str_want );
    self switchtoweapon( str_want );

    println( "[zm_qol] starting pistol: swapped spawn pistol for " + str_want );
}

// ----------------------------------------------------------------------------
//  coop_pause  -  freeze zombie spawning between rounds. Solo games ignore it,
//  same as Remix, because a solo player can just pause the game.
// ----------------------------------------------------------------------------
qol_opt_coop_pause()
{
    if ( zmqol_minimal() )
        return;

    level endon( "end_game" );

    b_paused = 0;

    for ( ;; )
    {
        wait 0.5;

        b_want = getdvarintdefault( "coop_pause", 0 );

        if ( b_want == b_paused )
            continue;

        a_players = get_players();

        if ( a_players.size < 2 )
            continue;

        if ( b_want )
        {
            //  Wait for the round to end first - pausing mid-round would strand
            //  whatever is already alive and read as a freeze.
            if ( get_round_enemy_array().size + level.zombie_total != 0 )
            {
                level iprintln( "^3[zm_qol] ^7pausing at the start of the next round" );
                level waittill( "end_of_round" );
            }

            b_paused = 1;
            level iprintln( "^3[zm_qol] ^7PAUSED - coop_pause 0 to resume" );
        }
        else
        {
            b_paused = 0;
            level iprintln( "^3[zm_qol] ^7resumed" );
        }

        foreach ( player in a_players )
            player setclientdvar( "ai_disableSpawn", b_paused );
    }
}

// ----------------------------------------------------------------------------
//  no_power  -  TranZit's power-free challenge: no turbine, no jet gun.
// ----------------------------------------------------------------------------
//  🛑 This lives in a ROOT script even though it is TranZit-only, and that is
//  safe BECAUSE it touches no map-specific FUNCTION. It reads
//  level.zombie_include_buildables, a core variable, and points triggerthink at
//  a local stub. AI_CONTEXT rule 2 is about `maps\mp\zm_transit::foo`-style
//  references, which resolve at script LOAD time and crash every other map -
//  a runtime level.script guard does not save those. A level variable is fine.
//
//  Read once at setup rather than watched: the buildables are wired up during
//  level init, so flipping this mid-game would do nothing and pretending
//  otherwise would just be confusing.
// ----------------------------------------------------------------------------
// ============================================================================
//  🛑 v2.9.13 - THIS OPTION DID THE OPPOSITE OF WHAT ITS ROW SAYS. REWRITTEN.
//
//  User, 2026-08-31: *"make sure that the option to enable power for the current
//  map works as intended, the option in the cheats menu."*
//
//  What the menu promises (ui\t6\menus\optionssettings.lua:2054, CHEATS tab):
//      "NO POWER NEEDED"  -  "Perks and doors work without power."
//
//  What the old body actually did: returned immediately on every map except
//  TranZit, and on TranZit pointed the TURBINE and JET GUN buildables at a null
//  stub - i.e. it REMOVED the only way to get power there. A row sitting on the
//  CHEATS tab, promising perks and doors without power, instead made the map
//  strictly harder and did nothing at all on the other five. Its own comment
//  called it "TranZit's power-free challenge", so the code was coherent with
//  itself and simply never matched the row it was wired to.
//
//  🌟 THE FIX USES THE GAME'S OWN CHEAT, NOT AN INVENTION. Stock's devgui does
//  exactly one thing for its "power_on" button (_zm_devgui.gsc:900-902):
//      case "power_on":  flag_set( "power_on" );  break;
//  and "power_on" is flag_init()'d in CORE _zm.gsc:1133, so it exists on every
//  map, not just one - confirmed in the dump, and every map's own scripts read
//  it (TranZit 23 references, Buried 13, Die Rise 8, Mob 8, Origins 5,
//  Nuketown 3). Perk machines, Pack-a-Punch and power doors are all driven off
//  it through _zm_power.gsc's powered-item list, which is why setting the one
//  flag is enough and no per-map special-casing is needed.
//
//  Watched rather than read once, so the row is live like BLEEDOUT BAR: flip it
//  mid-game and the lights come on. Turning it back OFF deliberately does NOT
//  cut the power again - if you had legitimately switched the power on, clearing
//  the flag would strand every door and machine you had already paid for. The
//  row is one-way within a match, and that is a deliberate choice, not an
//  oversight.
//
// ============================================================================
//  🛑 v2.11.22 - THE FLAG ALONE WAS NEVER THE WHOLE CHEAT. AUDITED CALL BY CALL.
//
//  User, 2026-09-04: *"make sure that the no power needed cheat works as
//  intended and actually bypasses power being disabled restrictions etc."*
//
//  v2.9.13 set flag "power_on" and stopped there. That is genuinely most of it -
//  _zm_power.gsc's watch_global_power() picks the flag up and powers every
//  registered item (perk machines, Pack-a-Punch, electric doors) - but a diff
//  against what the game's OWN power switches do found five gaps, every one of
//  them read out of the stock dump, not guessed:
//
//   1. 🌟 THE CLIENT WAS NEVER TOLD. Buried (zm_buried_power.gsc:31-33) and Die
//      Rise (zm_highrise.gsc:1136) both clientnotify AND set the clientfield
//      "zombie_power_on". Nothing in this mod did either, and the client half of
//      power hangs entirely off it: _zm.csc:56's callback turns the field into
//      the "ZPO" notify, zpo_listener (:580) turns THAT into "power_on", and
//      _zm.csc:886 perk_start_up() waits on it before it will light a single
//      perk machine. Same story for the map ambience - zm_highrise_amb.csc:141
//      and zm_transit_amb.csc:208 both wait for it. So the machines worked while
//      staying dark and silent, which is exactly what the user saw.
//      (TranZit is the exception and always was: wait_for_power() at
//      zm_transit_power.gsc:339 watches the flag server-side and sets the
//      clientfield itself, which is why TranZit looked more correct than the
//      others.)
//   2. LOCAL ELECTRIC DOORS were skipped by design. set_global_power() (:365)
//      refuses any item with power_sources == 1, and that is precisely how a
//      local_electric_door registers unless level.power_local_doors_globally is
//      set (:88-93). TranZit is the only map with them - its turbine doors -
//      so the row promised "doors work without power" and left those shut.
//   3. Doors that DID power up could close again: level.local_doors_stay_open
//      was never set, so door_think()'s close half (:588, :625) still ran.
//   4. Die Rise's lighting never changed - its switch ends stop_exploder(10);
//      exploder(11) (zm_highrise.gsc:1138-1139) and the map stayed dark.
//   5. TranZit's SECOND flag, "switches_on", was never set. It gates the reactor
//      event (powerevent(), :382), the Avogadro's power-plant behaviour
//      (_zm_ai_avogadro.gsc:1295) and four side-quest checks (zm_transit_sq.gsc
//      :962, :994, :1037, :1118), all of which test it separately from power_on.
//
//  🌟 THE FIX IS AGAIN TREYARCH'S OWN CODE. _zm_game_module.gsc:119 is
//  turn_power_on_and_open_doors() - the exact thing Grief and the TranZit
//  survival sub-maps call - and it covers 1, 2 and 3 in one call:
//      level.local_doors_stay_open = 1;
//      level.power_local_doors_globally = 1;
//      flag_set( "power_on" );
//      level setclientfield( "zombie_power_on", 1 );
//      + a direct power_on / local_power_on notify to every zombie_door
//  It lives in maps\mp\zombies\_zm_game_module, which AI_CONTEXT rule 2 lists as
//  globally safe from a root script (maps\mp\zombies\_zm*).
//
//  4 and 5 are map-specific, so they live in the map's own file and hang off the
//  "zmqol_no_power_applied" notify this function raises:
//      zm_highrise\zm_highrise.gsc  the two exploders
//      zm_transit\zm_transit.gsc    flag "switches_on"
//      zm_tomb\zm_tomb.gsc          Origins is a special case - see below
//
//  🛑 ORIGINS: THE ROW DID NOTHING AT ALL THERE, AND STILL WOULD.
//  zm_tomb_standard.gsc:20 sets power_on itself the moment the blackscreen
//  lifts, so the old code printed "already on, nothing to do" and left. Origins
//  does not gate perks on the power flag at all: zm_tomb_capture_zones.gsc:117
//  installs level.custom_perk_validation = ::check_perk_machine_valid, which
//  reads the GENERATOR ZONE's own "player_controlled" ent_flag (:where the
//  machine's str_zone_name points) and plays the "power_off" line when it is
//  clear. So on Origins the cheat has to capture the generators, and that is
//  what the map hook does - through stock's own set_player_controlled_area() /
//  generator_state_power_up(), the same path a real capture takes.
//
//  Mob of the Dead and Nuketown also set power_on at blackscreen
//  (zm_alcatraz_standard.gsc:20, zm_nuked_standard.gsc:21) and, unlike Origins,
//  gate NOTHING else on it - Mob's only other references are voice lines. The
//  row is correctly a no-op on those two, and the log says so.
// ============================================================================
//  ============================================================================
//  🌟 v2.11.24 - THE ROW IS A TOGGLE NOW. TURNING IT OFF TAKES THE POWER BACK.
//
//  User, 2026-09-04, asked for exactly this after finding the Wunderfizz still
//  purchasable with the row switched off: the row had latched on b_applied and
//  never looked at the dvar again, so power granted was power kept.
//
//  🌟 THE WHOLE POWER-OFF IS ONE STOCK LINE: flag_clear( "power_on" ).
//  _zm_power.gsc:43 watch_global_power() is a two-way loop -
//      flag_wait( "power_on" );      set_global_power( 1 );
//      flag_waitopen( "power_on" );  set_global_power( 0 );
//  - and set_global_power( 0 ) walks every registered powered item calling its
//  power_off_func: perk_power_off (:614) kills the machine's trigger think,
//  restarts it unpowered, deletes the perk_hum and perk_pause()s the perk;
//  pap_power_off (:663) notifies "Pack_A_Punch_off" and restores the dummy;
//  door_power_off (:488) notifies the door "power_off". Nothing is
//  reimplemented here. Stock's own devgui power button is the same single line
//  (_zm_devgui.gsc:904), and TranZit's switch - which is a real two-way switch
//  in stock - clears the same flag at zm_transit_power.gsc:90.
//
//  The client half is setclientfield( "zombie_power_on", 0 ), which is what
//  zm_transit_power.gsc:350 does on the way down. That is what makes the perk
//  machines go dark and quiet again and swings map ambience back (_zm.csc:56 ->
//  "ZPO" -> zpo_listener), and it is what re-locks the Wunderfizz through
//  wunderfizz.gsc's live gate.
//
//  🛑 ONLY GIVE BACK WHAT THE ROW ITSELF TOOK. Everything below is guarded on
//  level.zmqol_no_power_turned_it_on, set only in the branch that actually
//  turned the power on. A player who flipped the real switch keeps their power,
//  and the row is correctly a no-op both ways on Origins, Mob, Nuketown and
//  every survival start, where power_on was already set before it ran.
//
//  🛑 WHAT THIS CANNOT UNDO, AND WHY - DOORS THE ROW OPENED STAY OPEN.
//  Stock's turn_power_on_and_open_doors() parks level.local_doors_stay_open at
//  1, and _zm_blockers.gsc:625 / :588 make door_think() *return* on that - the
//  thread that would ever close the door is gone, not parked. Worse, local
//  electric doors were registered in standard_powered_items() with
//  power_sources = 1 before the row ran, and set_global_power() skips exactly
//  those (:374), so the flag can never reach them anyway. Closing them again
//  would mean hand-rolling a door sweep that re-blocks doors and clears their
//  script_flags mid-round - which can shut a zone under a player's feet - so it
//  is deliberately NOT done. Told to the user rather than shipped half-working.
//  ============================================================================
qol_opt_no_power()
{
    level endon( "end_game" );

    flag_wait( "start_zombie_round_logic" );

    b_applied = 0;

    for ( ;; )
    {
        b_want = getdvarintdefault( "no_power", 0 );

        if ( b_applied && !b_want )
        {
            qol_no_power_revert();
            b_applied = 0;
        }

        if ( !b_applied && b_want )
        {
            if ( !flag( "power_on" ) )
            {
                //  🌟 STOCK'S OWN FUNCTION, not a hand-rolled flag flip. See the
                //  v2.11.22 banner above for the five things it does that a bare
                //  flag_set does not.
                maps\mp\zombies\_zm_game_module::turn_power_on_and_open_doors();
                level.zmqol_no_power_turned_it_on = 1;
                println( "[zm_qol] no_power: turn_power_on_and_open_doors() run on " + level.script + " - flag, client sync, every electric door incl. local" );
            }
            else
            {
                println( "[zm_qol] no_power: power_on was already set on " + level.script + " - only the per-map extras apply here" );
            }

            //  The per-map halves listen for this. Set the level var FIRST so a
            //  listener that starts late still sees it - a notify fires once.
            level.zmqol_no_power_applied = 1;
            level notify( "zmqol_no_power_applied" );
            b_applied = 1;
        }

        wait 0.5;
    }
}

// ----------------------------------------------------------------------------
//  qol_no_power_revert  -  the row went off; hand the power back (v2.11.24)
//
//  Order matters and is stock's, not invented. The flag goes first because
//  watch_global_power() is already parked on flag_waitopen( "power_on" ) and
//  starts un-powering machines the moment it opens; the clientfield follows so
//  the client's own listeners see the server state they are being told about.
//  level.local_doors_stay_open / power_local_doors_globally are put back the
//  way stock left them so a LATER re-apply behaves like a first apply.
//
//  The per-map halves hang off "zmqol_no_power_reverted" the same way the apply
//  halves hang off "zmqol_no_power_applied": Die Rise swaps its two exploders
//  back, TranZit clears "switches_on" and lets stock lower the reactor, Origins
//  releases exactly the generators this row captured and no others.
// ----------------------------------------------------------------------------
qol_no_power_revert()
{
    if ( isdefined( level.zmqol_no_power_turned_it_on ) && level.zmqol_no_power_turned_it_on )
    {
        level.local_doors_stay_open = 0;
        level.power_local_doors_globally = 0;

        //  v2.11.25 - THE OFF SWITCH IS NOT AN EMP. The swap has to happen
        //  BEFORE the flag moves, because flag_clear wakes watch_global_power()
        //  and the un-powering sweep starts on that same notify.
        n_shielded = zmqol_no_power_shield_perks();

        flag_clear( "power_on" );
        level setclientfield( "zombie_power_on", 0 );

        level thread zmqol_no_power_unshield_perks();

        println( "[zm_qol] no_power: row switched OFF on " + level.script + " - power_on cleared, client synced, machines dark. " + n_shielded + " perk machine(s) shielded: no drink and no Mule Kick gun is taken. Doors the row opened stay open (see the banner)." );
    }
    else
    {
        println( "[zm_qol] no_power: row switched OFF on " + level.script + " - the power was never this row's to take back, flag left alone" );
    }

    //  Cleared BEFORE the notify, so a map half that reads the var rather than
    //  waiting on the notify cannot see a stale 1. The per-map halves read
    //  zmqol_no_power_turned_it_on at APPLY time and remember it themselves,
    //  which is why it is safe to clear it here.
    level.zmqol_no_power_applied = 0;
    level.zmqol_no_power_turned_it_on = 0;
    level notify( "zmqol_no_power_reverted" );
}

// ----------------------------------------------------------------------------
//  zmqol_no_power_shield_perks  -  the OFF switch is not an EMP      (v2.11.25)
// ----------------------------------------------------------------------------
//  User, 2026-09-04, correcting the v2.11.24 hand-off: "thats how the emp
//  grenade/turbine functions. if NO POWER NEEDED is set to disabled, then that'd
//  be stock behaviour and you'd need to turn power on normally on whichever
//  classic mode map the player is playing on. This option being there is only to
//  save time so i dont have to go to the power." The row is a SHORTCUT. Turning
//  it off puts the MAP back to unpowered - it must not take the drinks out of
//  the player's hands.
//
//  🛑 WHERE THE PERK LOSS ACTUALLY CAME FROM - READ, NOT ASSUMED.
//  set_global_power( 0 ) (_zm_power.gsc:365) walks every registered item and
//  calls its power_off_func. For a perk machine that is perk_power_off (:614),
//  whose LAST line is _zm_perks::perk_pause(). perk_pause (:2633) unsetperks the
//  drink on EVERY player and, for specialty_additionalprimaryweapon, calls
//  _zm::take_additionalprimaryweapon(). perk_unpause hands the perk back on
//  re-power but NOT the third gun. The user was right about the feel: the EMP
//  grenade reaches that same perk_pause through perk_pause_all_perks( :2705 ).
//
//  THE OTHER OFF-FUNCS WERE READ TOO, AND TAKE NOTHING FROM A PLAYER, so this
//  one call is the entire problem: pap_power_off (:663) notifies and restarts
//  the upgrade think; door_power_off (:485) flips a flag and notifies. Origins
//  never had the bug at all - its generator loss goes through
//  disable_perk_machines_in_zone() (zm_tomb_capture_zones.gsc:428), which only
//  locks the trigger and re-hints it.
//
//  So: swap ONLY the perk machines' power_off_func for a copy of stock's minus
//  that final perk_pause. The machine still dies, still re-arms its "Power Must
//  Be Activated First" think, still fires <perk>_off. The pointers go straight
//  back afterwards (zmqol_no_power_unshield_perks) so a LATER, legitimate power
//  cut - TranZit's own reactor switch, an EMP grenade - pauses perks exactly
//  like stock. Returns how many machines were shielded, for the log line.
// ----------------------------------------------------------------------------
zmqol_no_power_shield_perks()
{
    if ( !isdefined( level.powered_items ) )
        return 0;

    n = 0;

    for ( i = 0; i < level.powered_items.size; i++ )
    {
        powered = level.powered_items[i];

        if ( !isdefined( powered.target ) || !isdefined( powered.target.targetname ) )
            continue;

        //  Stock's OWN discriminator for "this is a perk machine", copied from
        //  standard_powered_items() (_zm_power.gsc:54-66): the vending triggers
        //  are getentarray( "zombie_vending", "targetname" ), minus the one
        //  whose script_noteworthy is Pack-a-Punch.
        if ( powered.target.targetname != "zombie_vending" )
            continue;

        if ( isdefined( powered.target.script_noteworthy ) && powered.target.script_noteworthy == "specialty_weapupgrade" )
            continue;

        if ( isdefined( powered.zmqol_saved_power_off_func ) )
            continue;

        powered.zmqol_saved_power_off_func = powered.power_off_func;
        powered.power_off_func = ::zmqol_perk_power_off_keep_drinks;
        n++;
    }

    return n;
}

// ----------------------------------------------------------------------------
//  zmqol_no_power_unshield_perks  -  put stock's pointers back      (v2.11.25)
//
//  Bounded by the sweep's own pacing rather than a guess: set_global_power()
//  spends one wait_network_frame per registered item (:365-379), so waiting a
//  tenth of a second per item on top of a two second floor cannot restore a
//  pointer before the sweep has reached it. Threaded so the option watcher's
//  poll loop is not held up for those seconds.
// ----------------------------------------------------------------------------
zmqol_no_power_unshield_perks()
{
    level endon( "end_game" );

    if ( !isdefined( level.powered_items ) )
        return;

    wait 2 + ( level.powered_items.size * 0.1 );

    n = 0;

    for ( i = 0; i < level.powered_items.size; i++ )
    {
        powered = level.powered_items[i];

        if ( isdefined( powered.zmqol_saved_power_off_func ) )
        {
            powered.power_off_func = powered.zmqol_saved_power_off_func;
            powered.zmqol_saved_power_off_func = undefined;
            n++;
        }
    }

    println( "[zm_qol] no_power: " + n + " perk machine power_off hook(s) restored - the next power cut pauses perks like stock" );
}

// ----------------------------------------------------------------------------
//  zmqol_perk_power_off_keep_drinks                                 (v2.11.25)
//
//  _zm_power::perk_power_off (:614) copied line for line with exactly ONE line
//  removed - the perk_pause. Nothing is added and nothing is reordered, so the
//  machine goes dark the way it always has.
// ----------------------------------------------------------------------------
zmqol_perk_power_off_keep_drinks( origin, radius )
{
    notify_name = self.target maps\mp\zombies\_zm_perks::getvendingmachinenotify();

    if ( isdefined( notify_name ) && notify_name == "revive" )
    {
        if ( level flag_exists( "solo_game" ) && flag( "solo_game" ) )
            return;
    }

    self.target notify( "death" );
    self.target thread maps\mp\zombies\_zm_perks::vending_trigger_think();

    if ( isdefined( self.target.perk_hum ) )
        self.target.perk_hum delete();

    //  stock's perk_pause( self.target.script_noteworthy ) belongs HERE and is
    //  deliberately absent - that single call is the whole reason this function
    //  exists. See the banner above zmqol_no_power_shield_perks.
    level notify( notify_name + "_off" );
}

// ----------------------------------------------------------------------------
//  The HUD dvars
// ----------------------------------------------------------------------------
//  These drive the HUD THIS MOD ALREADY DRAWS rather than adding a second one
//  next to it - the user asked to "keep my current hud for my health hud and
//  timer at the top of the screen". quality_of_life's timer(), zombiecounter()
//  and first_spawn() now stash their elements on self for this to find.
//
//  hud_all is an override, not a master switch: 0 leaves each hud_* dvar to
//  decide for itself, 1 forces everything on. That way turning it on to see
//  everything does not wipe out the individual settings underneath.
//
//  🛑 Only hud_zone and the round timer (hud_timers 1 or 3) create anything,
//  and only while their dvar is on - see the HUD allowance note at the top of
//  this file.
// ----------------------------------------------------------------------------
qol_opt_hud_watcher()
{
    if ( zmqol_minimal() )
        return;

    self endon( "disconnect" );
    level endon( "end_game" );

    flag_wait( "initial_blackscreen_passed" );

    //  🛑 SEEDED WITH THE DEFAULT, NOT "". Seeding empty made the first pass see
    //  a "change" from "" to "1 1 1" and tint everything white on spawn - which
    //  turned the health bar's dark backing plate into the thick white border
    //  the user reported and never asked for. Nothing may be recoloured until
    //  the value actually differs from the default.
    str_prev_color = "1 1 1";
    //  v1.90.6 - same contract as str_prev_color: seeded to the dvar default so
    //  the first pass is a no-op. The elements are created already carrying
    //  these colours (timer() in quality_of_life.gsc and qol_opt_round_timer_hud
    //  below), so the watcher only ever has to act on a real console change.
    //  v2.10.1 - both white now; these MUST track the two qol_opt_dvar defaults
    //  above or the first pass repaints on spawn. (The 08-31 white pass missed
    //  this pair - the game timer repainted once per spawn until 2026-09-02.)
    str_prev_color_timer = "1 1 1";
    str_prev_color_round = "1 1 1";

    //  -1 so the first pass always writes the LUI flag once, whatever hud_master
    //  says. Seeding it to 1 would leave the flag unset on a player who joined
    //  with hud_master already 0.
    n_prev_master = -1;
    n_tick = 0;

    for ( ;; )
    {
        b_all = getdvarintdefault( "hud_all", 0 );

        // ====================================================================
        //  v1.85.0 - hud_master, the ".hud off" switch.
        //
        //  🛑 IT MUST BEAT hud_all, so it is applied as a multiplier on every
        //  branch below rather than as another `||` term. ".hud off" means off.
        //
        //  🌟 setclientuivisibilityflag( "hud_visible", 0 ) is what actually
        //  takes the GAME's hud down - points, ammo, round, perk icons, the
        //  power-up row. None of those are hudelems this mod owns, so no hud_*
        //  dvar has ever been able to touch them. This is not a guess: it is the
        //  exact call stock uses to hide the hud behind the intro screen, and
        //  quality_of_life.gsc::fade_out_intro_screen_zm_instant() sets the very
        //  same flag back to 1 when the blackscreen lifts.
        //
        //  Written ONLY on change. It is a reliable client command, and firing
        //  one every 0.25s is how you earn EXE_SERVERCOMMANDOVERFLOW.
        // ====================================================================
        //  🛑 AND IT HAS TO BE RE-ASSERTED, not just written once. Stock sets
        //  "hud_visible" back to 1 from several places during normal play -
        //  _globallogic_player.gsc:79, _globallogic.gsc:1197 and _zm.gsc:5300 -
        //  so a spawn or a round transition would quietly undo ".hud off".
        //  Re-written every 2s, and ONLY while the switch is off, which is a
        //  state the user asked for explicitly. At the normal setting this costs
        //  exactly one write, on the first pass.
        b_master = getdvarintdefault( "hud_master", 1 );
        n_tick++;

        if ( b_master != n_prev_master || ( !b_master && n_tick % 8 == 0 ) )
        {
            n_prev_master = b_master;
            self setclientuivisibilityflag( "hud_visible", b_master );

            // ================================================================
            //  🌟 v1.99.91 - THE SESSION WATERMARK GOES WITH IT.
            //
            //  User, 2026-08-20: *"same with the draw identifier ... make sure
            //  when HUD is set to Disabled the hud is really disabled, not just
            //  some hud elements."*
            //
            //  cg_drawIdentifier is the Plutonium dvar behind the GAME tab's
            //  DRAW IDENTIFIER row (ui/t6/menus/optionssettings.lua:1267) - the
            //  "*1787171762-0fe7-..." line across the top of the screen. It is
            //  drawn by the client, not by any hudelem or LUI widget this mod
            //  owns, so neither hud_visible nor any hud_* dvar could reach it.
            //
            //  🛑 THE USER'S OWN SETTING IS PRESERVED, NOT OVERWRITTEN. The
            //  value is stashed on the first switch-off and put back verbatim on
            //  switch-on, so a player who had it off keeps it off, and a player
            //  who had it on gets it back. Writing a hardcoded 1 on restore
            //  would quietly turn the watermark on for everyone who had it off.
            // ================================================================
            if ( !b_master )
            {
                if ( !isdefined( self.qol_drawid_saved ) )
                    self.qol_drawid_saved = getdvarintdefault( "cg_drawIdentifier", 1 );

                setdvar( "cg_drawIdentifier", 0 );
            }
            else if ( isdefined( self.qol_drawid_saved ) )
            {
                setdvar( "cg_drawIdentifier", self.qol_drawid_saved );
                self.qol_drawid_saved = undefined;
            }
        }

        // ====================================================================
        //  v2.0.8 - ROUND COUNTER LEFT, applied live.
        //
        //  The round counter re-anchors itself every round (round_hud() calls
        //  the same helper on its fly-back), but the two timers are created
        //  ONCE, so without this a mid-game flip would leave them behind on the
        //  other side of the screen. Written only when the row CHANGES.
        //
        //  🛑 level.zmqol_roundcounter is a SERVER hudelem shared by everyone,
        //  so it is moved once at level scope rather than once per player -
        //  writing it inside this per-player loop would still be correct but
        //  would do it N times for no reason. It is guarded because the default
        //  branch of round_hud() destroys and re-creates it every round.
        // ====================================================================
        //  🛑 v2.1.3 - `!= 0` BECAME `== 1`. hud_round_left is three-valued now
        //  (0 RIGHT, 1 LEFT, 2 OFF) and the old test would have read OFF as
        //  LEFT, dragging both timers to the other side of the screen the moment
        //  the round number was switched off. OFF anchors RIGHT, the default.
        b_round_left = getdvarintdefault( "hud_round_left", 0 ) == 1;
        //  v2.3.4 - the round counter re-anchors itself on the RIGHT-anchored
        //  digit-count inset every round transition (round_hud() calls it on
        //  every fly-back), but these two timers only got re-anchored above on
        //  a LEFT/RIGHT flip - so without this they would freeze at whatever
        //  inset was live the last time hud_round_left changed and drift out
        //  of alignment with the round counter as the round climbs past a
        //  digit boundary (9->10, 99->100, ...). Tracked the same way
        //  b_round_left already is: only write on an actual change.
        n_round_digits = zmqol_round_digit_count();

        if ( !isdefined( self.qol_round_left_last ) || self.qol_round_left_last != b_round_left ||
             !isdefined( self.qol_round_digits_last ) || self.qol_round_digits_last != n_round_digits )
        {
            self.qol_round_left_last = b_round_left;
            self.qol_round_digits_last = n_round_digits;

            zmqol_hud_round_anchor( self.qol_hud_timer );
            zmqol_hud_round_anchor( self.qol_hud_roundtimer );

            if ( isdefined( level.zmqol_roundcounter ) )
                zmqol_hud_round_anchor( level.zmqol_roundcounter );
        }

        //  v2.1.3 - one dvar, four states. See qol_opt_timer_seed() for the
        //  table and for why nobody's old setting was lost in the merge.
        n_timers = getdvarintdefault( "hud_timers", 1 );

        self qol_opt_show( self.qol_hud_timer, b_master && ( b_all || n_timers == 1 || n_timers == 2 ) );

        // ====================================================================
        //  🛑 TWO ELEMENTS ARE DELIBERATELY NOT TOUCHED HERE, AND v1.85.0 GOT
        //  BOTH WRONG. Same rule as the health HUD below: whatever repaints an
        //  element every tick is the ONLY thing allowed to write its alpha.
        //
        //  self.zombietext - quality_of_life.gsc::zombiecounter() writes
        //  `alpha = 1` four times a second. Writing 0 from here made the counter
        //  visibly flash on and off, which is what the user reported. That loop
        //  now reads hud_master / hud_all / hud_remaining itself.
        //
        //  self.qol_hud_shield - shield_hud() CREATES AND DESTROYS its two
        //  elements rather than fading them, and its background is deliberately
        //  alpha 0.5. qol_opt_show() only knows 0 and 1, so restoring it from
        //  here would have turned that dark backing plate fully opaque - the
        //  exact "thick white border" bug this file already documents for the
        //  health bar. shield_hud() takes its own destroy path on hud_master 0.
        // ====================================================================

        //  🛑 The health HUD is deliberately NOT touched here. quality_of_life's
        //  own health loop already owns its alpha (it restores it the instant it
        //  sees a 0) and its colour (it repaints per health tier every 0.1s).
        //  Two threads writing the same health elements is what produced the white
        //  bar, so there is exactly one owner now: that loop reads hud_health_bar
        //  and hud_color_health itself.

        self qol_opt_zone_hud( b_master && ( b_all || getdvarintdefault( "hud_zone", 0 ) ) );
        self qol_opt_compass_hud( b_master && ( b_all || getdvarintdefault( "hud_compass", 0 ) ) );
        self qol_opt_round_timer_hud( b_master && ( b_all || n_timers == 1 || n_timers == 3 ) );

        //  Colour is only re-applied when the string actually changes. Writing
        //  .color every tick on every element would be a lot of needless work
        //  for a value that changes when someone types at the console.
        str_color = getdvar( "hud_color" );

        if ( str_color != str_prev_color )
        {
            str_prev_color = str_color;
            v_color = qol_opt_parse_color( str_color );

            if ( isdefined( v_color ) )
            {
                //  v1.90.6 - qol_hud_timer and qol_hud_roundtimer are NO LONGER
                //  tinted from hud_color; they have their own dvars below so the
                //  user's yellow / light blue survive a hud_color change.
                self qol_opt_tint( self.zombietext, v_color );
                self qol_opt_tint( self.qol_hud_zone, v_color );
            }
        }

        //  The two stacked top-right timers, each with its own colour dvar.
        str_color_timer = getdvar( "hud_color_timer" );

        if ( str_color_timer != str_prev_color_timer )
        {
            str_prev_color_timer = str_color_timer;
            v_color = qol_opt_parse_color( str_color_timer );

            if ( isdefined( v_color ) )
                self qol_opt_tint( self.qol_hud_timer, v_color );
        }

        str_color_round = getdvar( "hud_color_round_timer" );

        if ( str_color_round != str_prev_color_round )
        {
            str_prev_color_round = str_color_round;
            v_color = qol_opt_parse_color( str_color_round );

            if ( isdefined( v_color ) )
                self qol_opt_tint( self.qol_hud_roundtimer, v_color );
        }

        wait 0.25;
    }
}

//  "1 0.5 0" -> ( 1, 0.5, 0 ). Undefined on anything that is not three numbers,
//  so a typo at the console leaves the HUD alone instead of blanking it.
qol_opt_parse_color( str_color )
{
    if ( !isdefined( str_color ) || str_color == "" )
        return undefined;

    a_parts = strtok( str_color, " " );

    if ( !isdefined( a_parts ) || a_parts.size != 3 )
        return undefined;

    return ( string_to_float( a_parts[0] ), string_to_float( a_parts[1] ), string_to_float( a_parts[2] ) );
}

qol_opt_show( e_hud, b_visible )
{
    if ( !isdefined( e_hud ) )
        return;

    if ( b_visible )
        e_hud.alpha = 1;
    else
        e_hud.alpha = 0;
}

qol_opt_tint( e_hud, v_color )
{
    if ( !isdefined( e_hud ) )
        return;

    e_hud.color = v_color;
}

// ----------------------------------------------------------------------------
//  ZONE NAME  -  the permanent location readout, above the perk row
// ----------------------------------------------------------------------------
//  User, 2026-09-05, with a screenshot: *"make the location indicator hud
//  option for my mod always show up here, above the perks just like how the
//  strat tester mod does, but not in yellow, in white like how it is currently,
//  and make sure it doesn't fade away off screen."*
//
//  🛑 THIS ROW HAS NEVER DRAWN A SINGLE CHARACTER, AND THAT IS THE REAL BUG.
//  It used to read `self.zone_name`, and a PLAYER never has one. Measured, not
//  assumed - the only assignments to that field in the whole 2,093-file stock
//  dump are
//        _zm_spawner.gsc:2689      self.zone_name = spot.zone_name;   (an AI)
//        _zm_zonemgr.gsc:216, 355  spots[i].zone_name = ...           (a struct)
//  and there is not one assignment anywhere in this mod's own tree either. So
//  isdefined( self.zone_name ) was always false, str_zone was always "", and
//  this element has sat in the bottom-left corner rendering an empty string for
//  every version it has existed. The old header comment claiming _zm_zonemgr
//  "maintains" it on every map was wrong: it maintains it on zombies.
//
//  🌟 SO THE ONLY LOCATION READOUT THE USER HAS EVER SEEN is the centre-screen
//  pop-up in quality_of_life.gsc::zonecheck(), which is white
//  (show_grief_hud_msg sets color ( 1, 1, 1 )) and fades out after 3.25 s
//  (fadeovertime( 1 ) -> alpha 0). That is exactly the "white" and the "fades
//  away" of the request, so what is being asked for is: make the permanent
//  readout actually work, and put it where the strat tester's one is.
//  📝 The pop-up is left alone - it was not part of the ask, and both it and
//  this row are governed by the same hud_zone switch.
//
//  -- THE POSITION -----------------------------------------------------------
//  🛑 v2.14.8 - MOVED, AND THE OLD SPOT IS THE BUG. User, 2026-09-06:
//  *"the zone notifier is colliding with other hud elements in origins,
//  potentially other maps too, so move the zone notifier below where users name
//  shows up, just underneath it."* The old position was Strat-Tester-BO2's
//  (x 8 / y -95 on "user_left"/"user_bottom", +15 Buried, +10 Origins), and on
//  Origins that lands ON the perk icon column - the user's screenshot shows
//  "No Man's Land" drawn straight through a perk icon.
//
//  🌟 THE NEW SPOT IS THE PLAYER NAME'S OWN, ONE LINE LOWER, AND THE NUMBERS
//  ARE MEASURED OFF THAT SCREENSHOT (2000x1125, so the 640x480 virtual screen
//  scales by 1125/480 = 2.34 vertically):
//        "Zombies: N"  ink rows 1004-1023  ->  virtual centre 432.5
//        "DavidHiFi"   ink rows 1074-1091  ->  virtual centre 461.9
//  quality_of_life.gsc draws those two with setpoint( "LEFT", "BOTTOM_LEFT",
//  -45, -12 ) and ( ..., -45, 18 ) - offsets 30 apart, centres 29.4 apart - so
//  ONE UNIT OF setpoint's y IS ONE VIRTUAL PIXEL, DOWNWARD, and this anchor's
//  origin sits at virtual y 444 (the 7.5% safe-area line). Everything below
//  follows from that: the screen bottom is offset ~35.8, the name's ink ends at
//  offset ~21.4, and a "small" 1.2 line is ~8.1 virtual px tall.
//
//  y = 29 therefore puts this line's centre 11 below the name, its ink from
//  offset ~25 to ~33, which is a ~3.7 px gap under the name and ~2.7 px of clear
//  screen below it. x = -45 is the name's own x, so the two left edges line up.
//
//  📝 IT IS TIGHT BECAUSE THE STACK ALREADY ENDS AT THE SCREEN EDGE - there
//  are only ~14.5 virtual px under the name. If it reads as too close to the
//  bottom, y is the one number to change.
//
//  🛑 THE TWO PER-MAP NUDGES ARE GONE WITH IT. +15 on Buried and +10 on
//  Origins existed to clear those maps' lower perk rows; anchored under the name
//  they would only push this line off the bottom of the screen.
//
//  📝 IF THE HEALTH BAR ROW IS OFF, SO IS THE NAME - quality_of_life.gsc's
//  qol_health_hud_create() builds both as one set - and this line then sits alone
//  where the name would have been. That is a fixed, predictable spot rather than
//  a floating one, so it is left as is.
//
//  🛑 THEIR FONT IS NOT COPIED. hud.gsc:306 asks for "hudsmall", which is not a
//  T6 font - the engine rejects it with  "hudsmall" is not a valid value for
//  hudelem field "font"  and silently falls back to the default. This project
//  has already paid for that exact error once, on the zombie counter
//  (quality_of_life.gsc, createfontstring( "small", 1.2 ) and the long note
//  above it). "small" is a name from the engine's own list, so it stays.
//
//  🛑 AND THEIR FADE IS NOT COPIED EITHER, which is the third part of the ask:
//  hud.gsc:334-341 fades the text to alpha 0, re-texts it and fades it back in
//  on every zone change. This element is created at alpha 1 and nothing ever
//  writes its alpha again - qol_opt_show() is deliberately never called on it,
//  and qol_opt_tint() only touches .color.
//
//  📝 WHITE COSTS NO CODE. hud_color defaults to "1 1 1", the watcher above
//  already tints this element from it, and a fresh hudelem is white anyway - so
//  "white like how it is currently" is the state both paths already produce,
//  and the colour stays user-configurable instead of being hardcoded here.
//
//  -- WHERE THE NAME COMES FROM ----------------------------------------------
//  self.currentzone, which quality_of_life.gsc::zonecheck() already maintains
//  per player every 0.2 s out of its own get_zone_name() - the friendly names
//  ("Bus Depot", "Diner", "The Crazy Place"), map by map, for all six maps.
//
//  🌟 REUSING THAT CACHE RATHER THAN CALLING get_zone_name() HERE IS THE POINT.
//  get_zone_name() -> _zm_zonemgr::get_player_zone() walks every zone key and
//  istouching()es every volume of each one. This function is called from
//  qol_opt_hud_watcher()'s permanent 0.25 s loop, so calling it here would run
//  that whole walk a second time, four times a second, for a value another loop
//  already holds. It also keeps this file free of a cross-file call.
//
//  📝 A NAME CONTAINING "_" IS SKIPPED AND THE LAST GOOD ONE STAYS ON SCREEN.
//  Unnamed pockets read as their raw key ("zone_diner_roof"). zonecheck() only
//  writes currentzone for friendly names while hud_zone is ON, but its
//  hud_zone-OFF branch writes the raw key unfiltered - so someone who switches
//  the row on while standing in one of those pockets would otherwise get
//  "zone_diner_roof" in the corner. Holding the previous text is also simply
//  better for a permanent readout: "Diner" stays up while you are on the diner
//  roof.
qol_opt_zone_hud( b_on )
{
    if ( !b_on )
    {
        if ( isdefined( self.qol_hud_zone ) )
        {
            self.qol_hud_zone destroy();
            self.qol_hud_zone = undefined;
        }

        return;
    }

    if ( !isdefined( self.qol_hud_zone ) )
    {
        //  v2.14.25 - 1.2 -> 1.1 together with the name row
        //  (quality_of_life.gsc::qol_health_hud_create): user 2026-09-08,
        //  *"the area and username text ... a tiny bit smaller"*.
        self.qol_hud_zone = self createfontstring( "small", 1.1 );

        //  🛑 setpoint(), AND THE SAME CALL THE PLAYER NAME MAKES. The old
        //  position hand-assigned horzalign/vertalign "user_left"/"user_bottom"
        //  to sit above the perk row; this line is anchored to the NAME now, and
        //  quality_of_life.gsc::qol_health_hud_create() places that with
        //  setpoint( "LEFT", "BOTTOM_LEFT", -45, 18 ). Matching the call is what
        //  makes "one line lower" mean exactly 11, in the same frame, on every
        //  map. See the measurement in the banner above.
        //  v2.14.21 - 29 -> 27, the same two units the name row moved up in
        //  quality_of_life.gsc::qol_health_hud_create() (its comment has the
        //  measurement). The 11-unit gap between the two is unchanged.
        self.qol_hud_zone setpoint( "LEFT", "BOTTOM_LEFT", -45, 27 );

        //  Never faded, never hidden. That is the whole row.
        self.qol_hud_zone.alpha = 1;
        self.qol_hud_zone.hidewheninmenu = 1;
    }

    str_zone = self.currentzone;

    //  Nothing known yet (the first fraction of a second of a match), or a raw
    //  zone key - leave whatever is already on screen where it is.
    if ( !isdefined( str_zone ) || str_zone == "" || issubstr( str_zone, "_" ) )
        return;

    //  🛑 WRITTEN ONLY ON CHANGE, v1.95.1. settext() is ONE RELIABLE SERVER
    //  COMMAND PER CALL, and this runs four times a second off
    //  qol_opt_hud_watcher(), so an unconditional write is a permanent stream
    //  against a 128-entry ring - the defect ERROR_CATALOGUE section 7b is
    //  about, and what the health HUD was fixed for in v1.65.3.
    //
    //  🌟 THE CACHE LIVES ON THE HUDELEM, because the block above destroys and
    //  re-creates this element whenever hud_zone is toggled; a local would
    //  survive that and leave the fresh element permanently blank. A new
    //  element carries no .qol_last_zone, so the first pass after any re-create
    //  writes the text again.
    if ( !isdefined( self.qol_hud_zone.qol_last_zone ) || self.qol_hud_zone.qol_last_zone != str_zone )
    {
        self.qol_hud_zone settext( str_zone );
        self.qol_hud_zone.qol_last_zone = str_zone;
    }
}

// ----------------------------------------------------------------------------
//  COMPASS  -  the heading you are facing, top centre.          (v1.99.26)
// ----------------------------------------------------------------------------
//  User request 2026-08-17, from the TechnoOps collection. Their version is in
//  their pre-game lobby; the user asked for it on the HUD tab instead.
//
//  🌟 NOTHING IS IMPORTED. Theirs is three text hudelems and an angle lookup -
//  a technique, not an asset - so this is written against this file's own zone
//  HUD rather than copied. No shader, no material, no rule-7 question.
//
//  🛑 AND IT IS DELIBERATELY NOT A COPY OF THEIRS, because theirs would crash
//  this mod. `compassHud()` (their main.gsc:1926) calls settext() every pass of
//  a permanent loop. settext() is ONE RELIABLE SERVER COMMAND PER CALL against
//  a 128-entry ring - the exact unbounded emitter ERROR_CATALOGUE section 7b is
//  about, and the one that was fixed out of the zone HUD directly above in
//  v1.95.1. Here the heading is one of EIGHT strings and is written only when
//  it actually changes, so standing still or turning slowly costs nothing.
//
//  📝 Only the heading is drawn. Their version stacks a numeric angle and the
//  zone name under it; this mod already has a zone-name row (hud_zone), and a
//  raw yaw number is not something a player reads mid-round.
qol_opt_compass_hud( b_on )
{
    if ( !b_on )
    {
        if ( isdefined( self.qol_hud_compass ) )
        {
            self.qol_hud_compass destroy();
            self.qol_hud_compass = undefined;
        }

        return;
    }

    if ( !isdefined( self.qol_hud_compass ) )
    {
        self.qol_hud_compass = self createfontstring( "small", 1.4 );
        //  Top centre. Clear of the round counter (top right) and of the
        //  power-up row, which is centred lower down.
        self.qol_hud_compass setpoint( "TOP", "TOP", 0, 10 );
        self.qol_hud_compass.hidewheninmenu = 1;
    }

    str_heading = qol_opt_heading_text( self getplayerangles() );

    //  🌟 The cache lives ON THE HUDELEM, not in a local - same reason as the
    //  zone HUD above. Toggling hud_compass destroys and re-creates the element,
    //  and a local would survive that and leave the new element permanently
    //  blank. A fresh element carries no .qol_last_heading, so the first pass
    //  after any re-create writes the text again.
    if ( !isdefined( self.qol_hud_compass.qol_last_heading ) || self.qol_hud_compass.qol_last_heading != str_heading )
    {
        self.qol_hud_compass settext( str_heading );
        self.qol_hud_compass.qol_last_heading = str_heading;
    }
}

//  Yaw -> compass point. getplayerangles()[1] is the yaw, 0 = +X = East in this
//  engine, increasing anticlockwise; the +22.5 rounds to the nearest of eight
//  rather than truncating, so each label owns a 45-degree arc centred on it.
qol_opt_heading_text( v_angles )
{
    n_yaw = v_angles[1];

    while ( n_yaw < 0 )
        n_yaw = n_yaw + 360;
    while ( n_yaw >= 360 )
        n_yaw = n_yaw - 360;

    n_index = int( ( n_yaw + 22.5 ) / 45 );

    if ( n_index >= 8 )
        n_index = 0;

    if ( n_index == 0 ) return "E";
    if ( n_index == 1 ) return "NE";
    if ( n_index == 2 ) return "N";
    if ( n_index == 3 ) return "NW";
    if ( n_index == 4 ) return "W";
    if ( n_index == 5 ) return "SW";
    if ( n_index == 6 ) return "S";

    return "SE";
}

//  Time since the current round started, next to the game timer.
qol_opt_round_timer_hud( b_on )
{
    if ( !b_on )
    {
        if ( isdefined( self.qol_hud_roundtimer ) )
        {
            self.qol_hud_roundtimer destroy();
            self.qol_hud_roundtimer = undefined;
        }

        return;
    }

    if ( !isdefined( self.qol_hud_roundtimer ) )
    {
        //  v1.95.3 - SITS DIRECTLY UNDER THE GAME TIMER, TOP-RIGHT, and the pair
        //  now sits under the round counter instead of on Mob's key icon.
        //
        //  🛑 EVERY FIELD BELOW MIRRORS quality_of_life.gsc::timer() ON PURPOSE,
        //  and the derivation of all four numbers lives in that function's
        //  comment - read it before touching either element. Same alignx, same
        //  horzalign, same vertalign, same x; only y differs, by one 14-unit row.
        //  (Both keep vertalign "user_top" rather than round_hud()'s "top": the y
        //  values are measured in the "user_top" frame, so that offset is already
        //  accounted for.)
        //  🛑 v2.14.21 - BUILT EXACTLY AS THE GAME TIMER IS BUILT. User,
        //  2026-09-08, screenshot in hand: *"the round timer below the global
        //  timer still has the black outline and doesn't match the global timer,
        //  so fix that"*. This used to be createfontstring( "small", 1.2 ), and
        //  the "small" face is where the outline came from (v2.14.18's glow
        //  fields changed nothing on either element - measured on that
        //  screenshot). A raw newclienthudelem() with no .font at fontscale 1.4
        //  is the game timer's own construction, so the two now share one face,
        //  one size and one (absent) outline. y stays 94: both are aligny "top",
        //  and the 14-unit row was measured glyph-top to glyph-top.
        self.qol_hud_roundtimer = newclienthudelem( self );
        self.qol_hud_roundtimer.fontscale = 1.4;
        self.qol_hud_roundtimer.alignx = "center";
        self.qol_hud_roundtimer.aligny = "top";
        self.qol_hud_roundtimer.vertalign = "user_top";
        //  v2.0.8 - side comes from the shared anchor so this stays glued to the
        //  round counter when ROUND COUNTER LEFT is thrown. y is untouched.
        zmqol_hud_round_anchor( self.qol_hud_roundtimer );
        self.qol_hud_roundtimer.y = 94;     // == timer.y (80) + one 14-unit row
        //  v1.95.3 - dull navy blue, same value as the game timer above, user
        //  2026-08-14. Set at creation for the same reason: the watcher no-ops on
        //  its first pass. Console override: hud_color_round_timer "r g b".
        self.qol_hud_roundtimer.color = ( 1, 1, 1 );   //  white, user 2026-08-31 - twin of the game timer's write in quality_of_life.gsc
        //  No glow: see the v2.14.21 note above and in quality_of_life.gsc::
        //  timer(). 🛑 Change one construction without the other and the pair
        //  splits again.
        self.qol_hud_roundtimer.hidewheninmenu = 1;

        if ( isdefined( level.qol_round_start_time ) )
            self.qol_hud_roundtimer settimerup( ( gettime() - level.qol_round_start_time ) / 1000 );
        else
            self.qol_hud_roundtimer settimerup( 0 );
    }
}

//  level.qol_round_start_time is what the round timer counts from. Threaded
//  from init() rather than hooked into the round logic so nothing stock has to
//  be replaced for a cosmetic readout.
qol_opt_round_clock()
{
    level endon( "end_game" );

    for ( ;; )
    {
        level waittill( "start_of_round" );
        level.qol_round_start_time = gettime();

        foreach ( player in get_players() )
        {
            if ( isdefined( player.qol_hud_roundtimer ) )
                player.qol_hud_roundtimer settimerup( 0 );
        }
    }
}

zmqol_minimal()
{
    //  Twin of the one in quality_of_life.gsc - see the long note there. GSC
    //  scopes function names per file, so each file that needs the gate carries
    //  its own two-line copy rather than reaching across with a qualified call.
    return getdvarintdefault( "zmqol_minimal", 0 );
}

// ============================================================================
//  zmqol_hud_round_anchor  -  ROUND COUNTER LEFT                     (v2.0.8)
//
//  User, 2026-08-21: *"my mod has the round counter at the top right of the
//  screen like cold war zombies ... it'd be cool to have an option in the hud
//  tab ... to be able to have it on the top left (same vertical y coords, just
//  on the top left instead of top right, same as bo4 zombies)."*
//
//  🌟 THE MIRROR IS DERIVED FROM TWO SHIPPED ELEMENTS, NOT GUESSED. T6 hudelem
//  x is measured from the SAFE-AREA edge named by horzalign, and it grows
//  OUTWARD from that edge into the margin. Both directions are already in this
//  file with working values:
//        round_hud()   horzalign "right", x = +25   (top right, 25 into the margin)
//        healthbar     horzalign "left",  x = -45   (bottom left, 45 into the margin)
//  So the exact mirror of the round counter's +25 on the right is -25 on the
//  left, and it lands the same distance in from the screen edge.
//
//  🛑 THE WHOLE STACK MOVES, NOT JUST THE NUMBER. timer() and
//  qol_options.gsc::qol_opt_round_timer_hud() are calibrated to sit directly
//  under the round counter and both carried its x = 25 verbatim - the comment
//  above timer() says so and warns that changing one without the other splits
//  the stack. All three now read this one anchor. Only the SIDE changes; every
//  y is untouched, which is exactly what the user asked for.
//
//  📝 Twin of quality_of_life.gsc::zmqol_hud_round_anchor(). Same shape as
//  zmqol_minimal(), which is duplicated across these two root scripts for the
//  same reason - neither file references the other, and adding a cross-file
//  call would be a new load-order dependency for six lines.
// ============================================================================
// ============================================================================
//  v2.3.4 - HOW MANY DIGITS level.round_number IS, NO INVENTED BUILTIN.
//  No T6 function measures rendered text width offline (checked GSC
//  Documentation.md and the stock dump - neither has one), and `.size` is
//  documented for ARRAYS only (GSC Documentation.md:351), never strings, so
//  it is not used on a round-number string either. This is a plain numeric
//  comparison ladder instead - twin of quality_of_life.gsc's copy.
// ============================================================================
zmqol_round_digit_count()
{
    n = 1;

    if ( isdefined( level.round_number ) )
        n = int( level.round_number );

    if ( n < 10 )
        return 1;
    else if ( n < 100 )
        return 2;
    else if ( n < 1000 )
        return 3;
    else if ( n < 10000 )
        return 4;
    else if ( n < 100000 )
        return 5;
    else if ( n < 1000000 )
        return 6;

    return 7;
}

zmqol_hud_round_anchor( elem )
{
    if ( !isdefined( elem ) )
        return;

    //  v2.1.3 - `== 1`, not `!= 0`: 2 is OFF and OFF stays on the RIGHT.
    if ( getdvarintdefault( "hud_round_left", 0 ) == 1 )
    {
        elem.horzalign = "left";
        elem.x = -25;
    }
    else
    {
        // ====================================================================
        //  v2.3.4 - DIGIT-COUNT-AWARE INSET. User, 2026-08-25: round 10000 (5
        //  digits) runs off the right edge at the old fixed x = 25.
        //
        //  🌟 THE PER-DIGIT FIGURE IS MEASURED, NOT GUESSED. timer()'s own
        //  pixel scan (quality_of_life.gsc, right above timer()'s body) found
        //  round 100's "100" (3 digits, this exact font/fontscale) 33.67
        //  hud-units wide - about 11.2 units/digit. 3 digits at x = 25 is the
        //  baseline that was never reported clipping, so every digit beyond 3
        //  pulls the anchor back toward screen centre by ~12 units (11.2
        //  rounded up for margin).
        //
        //  🛑 NOT YET VISUALLY CONFIRMED AT ROUND 10000. I cannot measure the
        //  actual on-screen clearance without seeing it rendered - this is the
        //  documented fallback for "no way to measure it": a digit-count
        //  inset, not a text-width one. Tell me if round 10000 still clips or
        //  now sits too far in and the per-digit constant gets tuned from that.
        // ====================================================================
        n_extra_digits = zmqol_round_digit_count() - 3;

        if ( n_extra_digits < 0 )
            n_extra_digits = 0;

        elem.horzalign = "right";
        elem.x = 25 - n_extra_digits * 12;
    }
}

// ============================================================================
//  qol_opt_crosshair  -  the HUD tab's CROSSHAIR row                (v2.14.7)
// ----------------------------------------------------------------------------
//  Live in both directions: the row can be flipped mid-match and the next pass
//  applies it. Seeded with -1 so the first pass always writes, which is what
//  picks up a value the player left in their config from a previous session -
//  and what puts the crosshair back for a player who joined with the row on.
//
//  See the banner over the qol_opt_dvar( "crosshair", ... ) registration for why
//  three dvars are written instead of one.
// ============================================================================
qol_opt_crosshair()
{
    if ( zmqol_minimal() )
        return;

    self endon( "disconnect" );
    level endon( "end_game" );

    flag_wait( "initial_blackscreen_passed" );

    n_last = -1;

    for ( ;; )
    {
        n_now = getdvarintdefault( "crosshair", 1 ) != 0;

        if ( n_now != n_last )
        {
            n_last = n_now;

            if ( n_now )
            {
                self setclientdvar( "cg_drawCrosshair", 1 );
                self setclientdvar( "cg_crosshairAlpha", 1 );
                self setclientdvar( "cg_crosshairAlphaMin", 0.5 );
            }
            else
            {
                self setclientdvar( "cg_drawCrosshair", 0 );
                self setclientdvar( "cg_crosshairAlpha", 0 );
                self setclientdvar( "cg_crosshairAlphaMin", 0 );
            }

            println( "[zm_qol] crosshair -> " + n_now );
        }

        wait 1;
    }
}

// ============================================================================
//  qol_opt_knife_lunge  -  the GAME 3 tab's KNIFE LUNGE row           (v2.14.28)
// ----------------------------------------------------------------------------
//  User, 2026-09-08: *"add an option in GAME 3 called KNIFE LUNGE and by
//  default it's set to enabled (vanilla behaviour), or you can set it to
//  disabled so that you can no longer lunge when meleeing/knifing in zombies
//  ... reimagined has this implementation so it just needs to be a toggle."*
//
//  THE MECHANISM, found rather than guessed. Nothing in Reimagined mentions a
//  "lunge" by that word; its commit feb3cf4d "Disabled melee lunging" is one
//  line, setDvar( "aim_automelee_enabled", 0 ). That is the engine's melee
//  charge: BO2 Detailed DVARS.txt describes aim_automelee_enabled as "Turn on
//  auto melee" alongside aim_automelee_range (120), _region_width/_height and
//  _move_limit* ("Speed at which player needs to be moving forward to
//  activate the charge"). Treyarch's own campaign script
//  nicaragua_menendez_rage.gsc flips the same dvar off and back on with
//  setsaveddvar(), and BO2-Remix writes it per player with
//  self setClientDvar( "aim_automelee_enabled", 0 ).
//
//  🛑 CORRECTING A NOTE OF THIS MOD'S OWN. quality_of_life.gsc's AIM ASSIST
//  banner (v1.99.74) says aim_automelee_enabled is "a string inside t6zm.exe
//  but not a registered dvar". It IS registered: the dvar dump in
//  crashlogs\console_zm_07-19-13.log lists aim_automelee_enabled "1",
//  aim_automelee_range "120", aim_automelee_region_width "320" and the rest,
//  plus tu_aim_automelee_fix1. That banner is corrected in the same commit.
//
//  Two writes, because Plutonium runs every match as a listen server: the
//  host's client and the server share one dvar table, so the plain setdvar
//  (Reimagined's route) covers the host; a co-op joiner has its own table, so
//  each player also gets setclientdvar (Remix's route). Both are written ONLY
//  ON CHANGE - ERROR_CATALOGUE §7b, a setclientdvar loop with no stop
//  condition is how EXE_ERR_RELIABLE_CYCLED_OUT happened twice.
//
//  Not verified offline, stated: whether a joiner's client honours the
//  setclientdvar for this particular dvar. The host path is the one Reimagined
//  and the campaign rely on.
// ============================================================================
qol_opt_knife_lunge()
{
    if ( zmqol_minimal() )
        return;

    self endon( "disconnect" );
    level endon( "end_game" );

    self.zmqol_lunge_applied = -1;

    for ( ;; )
    {
        n_want = 0;

        if ( getdvarintdefault( "knife_lunge", 1 ) != 0 )
            n_want = 1;

        if ( n_want != self.zmqol_lunge_applied )
        {
            self.zmqol_lunge_applied = n_want;

            self setclientdvar( "aim_automelee_enabled", n_want );

            if ( getdvarintdefault( "aim_automelee_enabled", 1 ) != n_want )
                setdvar( "aim_automelee_enabled", n_want );

            println( "[zm_qol] knife lunge -> " + n_want + " (aim_automelee_enabled now " + getdvar( "aim_automelee_enabled" ) + ")" );
        }

        wait 1;
    }
}

// ============================================================================
//  qol_opt_third_person  -  the GAME 3 tab's THIRD PERSON row       (v2.14.13)
// ----------------------------------------------------------------------------
//  User, 2026-09-07: "put a 3rd person toggle in the GAME 3 tab in the mod".
//
//  THE ENGINE HAS A METHOD FOR THIS, AND STOCK ZOMBIES USES IT. Not the
//  cg_thirdPerson dvar (client-side, and the crosshair row already found this
//  build's cg_* switches cheat-protected) but the player method
//  setclientthirdperson(), which stock calls at six places in the zombies
//  dump: _zm.gsc::onplayerconnect_clientdvars() :1257, onplayerspawned()
//  :1322, set_third_person() :2131/:2137, _globallogic_spawn.gsc :860/:865,
//  _zm_gametype.gsc :1928. The angle is stock's own: set_third_person() pairs
//  it with setclientthirdpersonangle( 354 ), and _globallogic.gsc:1947 makes
//  cg_thirdPersonAngle 354 serverinfo. BO2-Reimagined ships the same call.
//
//  NOT A CALL TO STOCK'S set_third_person(). Its "on" branch also writes
//  setdepthoffield( 0, 128, 512, 4000, 6, 1.8 ) - a real scripted blur that
//  overrides the renderer's r_dof_enable, which is exactly what this mod's
//  DOF fix (quality_of_life.gsc, item 48) exists to keep off. That banner
//  records set_third_person() as "unreached on this platform"; calling it
//  from here would make it reached and hand DOF a second owner. So only the
//  two camera methods are used, plus resetfov() as every stock branch does.
//
//  STOCK TURNS IT OFF ON EVERY SPAWN. onplayerspawned() :1322 writes
//  setclientthirdperson( 0 ) - so a revive-respawn in co-op, or the
//  spawned_player at match start, silently puts the camera back. The
//  companion thread below resets the applied state on that notify, and the
//  next 1 Hz pass re-applies; stock's write is synchronous inside the notify,
//  ours is up to a second later, so ours always lands last.
//
//  Live in both directions, seeded with -1 so the first pass always writes -
//  same shape as qol_opt_crosshair() above. The first-person weapon model is
//  not drawn in third person; that is the engine's view, not a missing asset
//  (stock's game-over camera is this same mode).
// ============================================================================
qol_opt_third_person()
{
    if ( zmqol_minimal() )
        return;

    self endon( "disconnect" );
    level endon( "end_game" );

    flag_wait( "initial_blackscreen_passed" );

    self.zmqol_tp_applied = -1;
    self thread qol_opt_third_person_respawn();

    for ( ;; )
    {
        n_now = getdvarintdefault( "third_person", 0 ) != 0;

        if ( n_now != self.zmqol_tp_applied )
        {
            self.zmqol_tp_applied = n_now;

            if ( n_now )
            {
                self setclientthirdperson( 1 );
                self setclientthirdpersonangle( 354 );
            }
            else
            {
                self setclientthirdperson( 0 );
                self setclientthirdpersonangle( 0 );
            }

            self resetfov();

            println( "[zm_qol] third person -> " + n_now );
        }

        wait 1;
    }
}

//  Stock's onplayerspawned() has just written setclientthirdperson( 0 ) on
//  this same notify; forgetting the applied state makes the watcher's next
//  pass put the player's choice back.
qol_opt_third_person_respawn()
{
    self endon( "disconnect" );
    level endon( "end_game" );

    for ( ;; )
    {
        self waittill( "spawned_player" );
        self.zmqol_tp_applied = -1;
    }
}
