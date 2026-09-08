-- ============================================================================
--  zm_qol - ui_mp\t6\hud\loading.lua        v2.2.7
--
--  WHY THIS FILE EXISTS: the loading screen's big orange title read "GREEN RUN"
--  while the player was loading into DINER survival - and the scoreboard in the
--  very same match already read "Survival - Diner". User, 2026-08-24.
--
--  🛑 STOCK CAN NEVER SHOW A START LOCATION THERE. CoD.Loading.StartLoading
--  sets that label straight from Dvar.ls_mapname, and ls_mapname is the MAP
--  ("Green Run"). It never reads ui_zm_mapstartlocation at all, so no dvar,
--  script or menu change can fix it from outside - the file has to be owned.
--
--  📐 THIS IS THE STOCK patch_zm FILE, UNCHANGED, PLUS ONE LOOKUP.
--  Base: the stock decompile at
--    POWER UP TIMERS\black_ops_2_decompiled_lua_dump\T6_lua_files\T6\patch_zm\
--    ui_mp\t6\hud\loading.lua
--  It parses clean under luaparse 5.1 (checked), so unlike scoreboard.lua -
--  whose stock decompile is unshippable - the minimal-divergence route was open
--  here and BO2-Reimagined's rewrite was NOT bulk-copied. Exactly two edits:
--    1. this header,
--    2. GetZMLoadingMapName() below, and the one call to it in StartLoading.
--  Everything else is byte-for-byte stock, which is what keeps the loading
--  screen's own image selection intact: stock picks the material as
--  "loadscreen_<map>_<gametype>_<location>" up in LUI.createMenu.Loading, and
--  that code is untouched.
--
--  🌟 THE LOOKUP, VERIFIED, NOT ASSUMED. Section 5 of zm\gametypestable.csv is
--  the start-location table. Its diner row, stock, is
--      5,6,zm_transit,diner,ZMUI_DINER_CAPS,...,ZMUI_DINER,...
--  column 3 = the key ui_zm_mapstartlocation holds, column 4 = the ALL CAPS
--  display string, column 16 = the mixed-case one. This screen is the caps one
--  ("GREEN RUN"), so column 4 is right here where scoreboard.lua wants 16.
--  ZMUI_DINER_CAPS was dumped out of the shipped en_patch_zm.ff with
--  OpenAssetTools and reads "DINER" - Treyarch left the row and the string in.
--
--  🛡️ IT CANNOT BLANK THE TITLE. Every step falls back to the stock map name:
--  not zombies, classic gametype, no location dvar, no table row, no localized
--  string, or a string that came back as its own key - all return ls_mapname.
--  The worst case is the stock behaviour it replaces.
-- ============================================================================
CoD.Loading = {}
local f0_local0 = CoD.Loading
local f0_local1 = {
	theater = {
		"MPTIP_THEATER_CONTROL_SCHEMES",
		"MPTIP_THEATER_CAMERA_MODES",
		"MPTIP_THEATER_TIMELINE",
		"MPTIP_THEATER_SCOREBOARD",
		"MPTIP_THEATER_MONTAGE",
		"MPTIP_THEATER_PAUSE",
		"MPTIP_THEATER_DISCARD",
		"MPTIP_THEATER_PREVIEW",
		"MPTIP_THEATER_TRANSITIONS",
		"MPTIP_THEATER_FILESHARE",
		"MPTIP_THEATER_RATE",
		"MPTIP_THEATER_SCOREBOARD_SWITCH",
		"MPTIP_THEATER_CLIENTS"
	}
}
local f0_local2 = {
	"MPTIP_CREATE_A_CLASS_TIP",
	"MPTIP_CUSTOM_CLASS_TIP",
	"MPTIP_FRIENDS_LIST_TIP",
	"MPTIP_ASSIST_TIP",
	"MPTIP_CUSTOM_GAME_TIP",
	"MPTIP_SHOOTING_AIRCRAFT_TIP",
	"MPTIP_ENEMY_ON_MINIMAP_TIP",
	"MPTIP_MOTD_TIP",
	"MPTIP_LOOK_SENSITIVITY_TIP",
	"MPTIP_PAUSE_MENU_MAP_TIP",
	"MPTIP_FAST_ADS_WALK_TIP",
	"MPTIP_AUTOMATIC_WEAPONS_TIP",
	"MPTIP_DEAD_ALLIES_TIP",
	"MPTIP_GROUND_WEAPONS_TIP",
	"MPTIP_PISTOL_TIP",
	"MPTIP_LOCK_ON_TIP",
	"MPTIP_ADS_TIP",
	"MPTIP_FOOTSTEPS_TIP",
	"MPTIP_STAY_INSIDE_TIP",
	"MPTIP_MUTE_TIP",
	"MPTIP_THEATER_TIP",
	"MPTIP_HUD_TIP",
	"MPTIP_DTP_TIP",
	"MPTIP_CROSSBOW_TIP",
	"MPTIP_AAR_TIP",
	"MPTIP_COMBAT_TRAINING_TIP",
	"MPTIP_MATCH_BONUS_TIP",
	"MPTIP_WILDCARDS_TIP",
	"MPTIP_FRIENDS_BAR_TIP",
	"MPTIP_HELD_KNIFE_TIP",
	"MPTIP_ONE_GUN_PICKUP_TIP",
	"MPTIP_SHOTGUN_SLUG_TIP",
	"MPTIP_GHOST_FADE_TIP",
	"MPTIP_HARDCORE_HUD_TIP",
	"MPTIP_HARDCORE_MINIMAP_TIP",
	"MPTIP_WILLY_PETE_TIP",
	"MPTIP_TACTICAL_INSERTION_TIP",
	"MPTIP_TOMAHAWK_TIP",
	"MPTIP_C4_OBJECTIVES_TIP",
	"MPTIP_GRENADE_SOUND_TIP",
	"MPTIP_NO_COOKING_TIP",
	"MPTIP_CLAYMORE_TIP",
	"MPTIP_SHOCK_CHARGE_TIP",
	"MPTIP_FAST_MAG_TIP",
	"MPTIP_EXTENDED_MAGS_TIP",
	"MPTIP_DEEP_IMPACT_TIP",
	"MPTIP_SUPPRESSOR_TIP",
	"MPTIP_STEADY_AIM_TIP",
	"MPTIP_ATTACHMENT_VARIETY_TIP",
	"MPTIP_ATTACHMENTS_TIP"
}
local f0_local3 = "MPTIP_TARGET_FINDER_TIP"
local f0_local4 = "MPTIP_MMS_TIP"
local f0_local5 = "MPTIP_SELECT_FIRE_TIP"
local f0_local6 = "MPTIP_EXTREME_CARDIO_TIP"
local f0_local7 = "MPTIP_UTILITY_TIP"
local f0_local8 = "MPTIP_GHILLIE_SUIT_TIP"
local f0_local9 = "MPTIP_FLAK_TIP"
local f0_local10 = "MPTIP_KILLSTREAKS_MENU_TIP"
local f0_local11 = "MPTIP_LOOPING_KILLSTREAK_TIP"
local f0_local12 = "MPTIP_KILLSTREAKS_STAY_TIP"
local f0_local13 = "MPTIP_TRANSPORT_HELI_TIP"
local f0_local14 = "MPTIP_SR71_TIP"
local f0_local15 = "MPTIP_ATTACK_DOG_TIP"
local f0_local16 = "MPTIP_WAR_MACHINE_TIP"
local f0_local17 = "MPTIP_TURRET_TIP"
local f0_local18 = "MPTIP_DETONATE_TIP"
local f0_local19 = "MPTIP_BOOST_TIP"
local f0_local20 = "MPTIP_AUTO_EXPLODE_TIP"
local f0_local21 = "MPTIP_TURRET_MELEE_TIP"
local f0_local22 = "MPTIP_SCORESTREAK_OBJECTIVE_TIP"
local f0_local23 = "MPTIP_REMOTE_CONTROL_TIP"
local f0_local24 = "MPTIP_HK_INCOMING_TIP"
local f0_local25 = "MPTIP_VTOL_MOVEMENT_TIP"
local f0_local26 = "MPTIP_HELLSTORM_CLUSTER_TIP"
local f0_local27 = "MPTIP_GUARDIAN_TIP"
local f0_local28 = "MPTIP_TARGET_DIAMOND_LOS_TIP"
f0_local2[33] = f0_local3
f0_local2[34] = f0_local4
f0_local2[35] = f0_local5
f0_local2[36] = f0_local6
f0_local2[37] = f0_local7
f0_local2[38] = f0_local8
f0_local2[39] = f0_local9
f0_local2[40] = f0_local10
f0_local2[41] = f0_local11
f0_local2[42] = f0_local12
f0_local2[43] = f0_local13
f0_local2[44] = f0_local14
f0_local2[45] = f0_local15
f0_local2[46] = f0_local16
f0_local2[47] = f0_local17
f0_local2[48] = f0_local18
f0_local2[49] = f0_local19
f0_local2[50] = f0_local20
f0_local2[51] = f0_local21
f0_local2[52] = f0_local22
f0_local2[53] = f0_local23
f0_local2[54] = f0_local24
f0_local2[55] = f0_local25
f0_local2[56] = f0_local26
f0_local2[57] = f0_local27
f0_local2[58] = f0_local28
f0_local1.general = f0_local2
f0_local1.public = {
	"MPTIP_XP_SOURCES_TIP",
	"MPTIP_LEADERBOARD_TIP",
	"MPTIP_CHALLENGE_REWARDS_TIP",
	"MPTIP_LEAGUE_GAME_TIP"
}
f0_local1.league = {
	"MPTIP_LEAGUE_WINS_TIP",
	"MPTIP_LEAGUE_BONUS_TIP",
	"MPTIP_LEAGUE_LEAVE_TIP",
	"MPTIP_LEAGUE_EARNING_TIP"
}
f0_local1.sd = {
	"MPTIP_SERACH_AND_DESTROY_TIP"
}
f0_local1.dom = {
	"MPTIP_DOMINATION_TIP"
}
f0_local1.koth = {
	"MPTIP_HARDPOINT_TIP"
}
f0_local1.gun = {
	"MPTIP_WAGER_GOLD_DOT",
	"MPTIP_WAGER_GUN_DEMOTE",
	"MPTIP_WAGER_GUN_SUICIDE"
}
f0_local1.oic = {
	"MPTIP_WAGER_GOLD_DOT",
	"MPTIP_WAGER_OIC_KNIFE",
	"MPTIP_WAGER_OIC_LIVES"
}
f0_local1.shrp = {
	"MPTIP_WAGER_GOLD_DOT",
	"MPTIP_WAGER_SHARP_PERKS",
	"MPTIP_WAGER_SHARP_FINAL"
}
f0_local1.sas = {
	"MPTIP_WAGER_GOLD_DOT",
	"MPTIP_WAGER_STICKS_TOMAHAWK",
	"MPTIP_WAGER_STICKS_POINTS",
	"MPTIP_WAGER_STICKS_SPYPLANE"
}
f0_local1.zombies = {}
f0_local0.DidYouKnow = f0_local1
CoD.Loading.FadeInTime = 1000
CoD.Loading.LoadingDelayTime = 2000
CoD.Loading.SpinnerDelayTime = 19000
CoD.Loading.DYKFontName = "Default"
CoD.Loading.DYKFont = CoD.fonts[CoD.Loading.DYKFontName]
CoD.Loading.DYKFontHeight = CoD.textSize[CoD.Loading.DYKFontName]
f0_local0 = function (f1_arg0, f1_arg1)
	if UIExpression.IsCinematicWebm() == 1 then
		if not f1_arg0.iswebm then
			f1_arg0:setImage(RegisterMaterial("webm_720p"))
			f1_arg0.iswebm = true
		end
	elseif f1_arg0.iswebm then
		f1_arg0:setImage(RegisterMaterial("black"))
		f1_arg0.iswebm = false
	end
end

f0_local1 = function (f2_arg0, f2_arg1)
	if f2_arg1.button == "left" then
		f2_arg0:processEvent({
			name = "loading_startplay"
		})
	end
end

CoD.Loading.HideContinueButton = function (f3_arg0, f3_arg1)
	f3_arg0:beginAnimation("hide", 1000)
	f3_arg0:setAlpha(0)
end

f0_local2 = function (f4_arg0, f4_arg1)
	local f4_local0, f4_local1 = Engine.GetUserSafeArea()
	local f4_local2 = Dvar.ui_errorMessage:get()
	if f4_local2 ~= "" then
		f4_arg0.errorText = LUI.UIText.new({
			left = -f4_local0 / 2,
			top = 36,
			right = f4_local0 / 2,
			bottom = 36 + CoD.textSize.Condensed,
			leftAnchor = false,
			topAnchor = true,
			rightAnchor = false,
			bottomAnchor = false,
			font = CoD.fonts.Condensed,
			alignment = LUI.Alignment.Left
		})
		f4_arg0:addElement(f4_arg0.errorText)
		f4_arg0.errorText:setText(f4_local2)
		Dvar.ui_errorMessage:set("")
	end
	if CoD.useMouse then
		f4_arg0:registerEventHandler("mouseup", f0_local1)
	end
	f4_arg0.continueButton:registerEventHandler("hide_continue_button", CoD.Loading.HideContinueButton)
	f4_arg0.continueButton:addElement(LUI.UITimer.new(5000, "hide_continue_button", true, f4_arg0.continueButton))
	f4_arg0.continueButton:beginAnimation("show", 1000)
	f4_arg0.continueButton:setAlpha(1)
	LUI.UIButton.gainFocus(f4_arg0.continueButton, f4_arg1)
end

-- ============================================================================
--  zm_qol v2.9.3 - THE SOLO INTRO CUTSCENE GATE, client half.
--
--  User, 2026-08-30: on Origins solo they skipped the intro part-way through
--  and "when i spawned in the zombies were right near me already and had
--  already broke through the barrier".
--
--  🛑 THE MOD CAUSED THIS AND NOTHING IN THE ROUND-DELAY SWITCH DID. Read
--  quality_of_life.gsc's round_think(): ROUND DELAY OFF is guarded with
--  `&& !level.first_round`, so it cannot touch round one at all. What DOES
--  create the overlap is this file's own cutscene, which zm_qol turns on by
--  forcing party_maxplayers to 1 (see privateonlinegamelobby.lua). Stock never
--  reaches this branch in a Plutonium private match, so there is no vanilla
--  behaviour being restored here - the mod added a video that can run for over
--  three minutes and never told the match to wait for it.
--
--  MEASURED, not guessed: video\zm_tomb_load.webm is 196.2s, zm_prison_load
--  170.6s, zm_buried_load 158.0s, zm_highrise_load 78.6s (Matroska Duration
--  element x TimecodeScale, read straight out of each file).
--
--  🌟 WHY A DVAR IS THE RIGHT CHANNEL. Solo is the ONLY case that reaches this
--  branch, and solo on Plutonium is a listen server - the LUI writing the dvar
--  and the GSC reading it are the same process. That is not a new trick here:
--  zmQolForceSoloPartySize already hands "zmqol_loadmovie_probe" to
--  quality_of_life.gsc the same way, and it arrives.
--
--  This handler is the END of the cutscene: it is the SKIP button's action, the
--  mouse-click path, and the only thing that calls Stop3DCinematic. Clearing
--  the gate here is therefore exact rather than timed.
-- ============================================================================
f0_local3 = function (f5_arg0, f5_arg1)
	pcall(Engine.SetDvar, "zmqol_cutscene", "0")
	Engine.Stop3DCinematic(0)
end

-- ============================================================================
--  zm_qol v2.10.2 - TAP TO INTERACT: the bind applier.
--
--  The v2.9.33 cut applied the two binds ONLY inside a selector_changed
--  handler, i.e. only at the moment the row was flipped. A profile that
--  already had tap_to_interact "1" saved from an earlier build never flipped
--  it again, so the binds were never written. The 2026-09-02 boot showed
--  exactly that: toggle ON, plutonium_zm.cfg holding `seta tap_to_interact
--  "1"`, and the mod's bindings_zm.bdg still on stock `bind BUTTON_X
--  "+usereload"` with no bind2 - so every stock trigger (barriers, perks)
--  still needed a hold. (Wunderfizz tapped fine only because wunderfizz.gsc
--  latches the press itself via notifyonplayercommand.)
--
--  Now the setting is applied FROM THE DVAR on every lobby build
--  (mainlobby.lua) and every map load (loading.lua), and the row's own choice
--  callback applies it again the instant it is flipped. At launch only ON
--  writes anything - OFF at launch touches nothing, so a player's own X
--  binding is never clobbered by a setting they never turned on; the OFF
--  restore happens once, in the row's callback, when they turn it off.
--
--  Every application echoes one line into console_zm.log naming its source,
--  so a boot proves which path ran. The two functions are defined guarded and
--  duplicated per Lua VM (frontend: optionssettings.lua + mainlobby.lua;
--  in-game: loading.lua) so load order never matters.
-- ============================================================================
if ZmQolApplyTapToInteract == nil then
	ZmQolApplyTapToInteract = function (ClientIndex, Value, Source)
		if ClientIndex == nil then
			ClientIndex = 0
		end
		if tostring(Value) == "1" then
			Engine.Exec(ClientIndex, "bind BUTTON_X \"+reload\"")
			Engine.Exec(ClientIndex, "bind2 BUTTON_X \"+activate\"")
			Engine.Exec(ClientIndex, "echo [zm_qol] tap_to_interact ON - BUTTON_X = +reload plus bind2 +activate - source " .. tostring(Source))
		else
			Engine.Exec(ClientIndex, "bind BUTTON_X \"+usereload\"")
			Engine.Exec(ClientIndex, "unbind2 BUTTON_X")
			Engine.Exec(ClientIndex, "echo [zm_qol] tap_to_interact OFF - BUTTON_X = +usereload and bind2 cleared - source " .. tostring(Source))
		end
	end
end

if ZmQolApplyTapToInteractFromDvar == nil then
	ZmQolApplyTapToInteractFromDvar = function (ClientIndex, Source)
		pcall(function ()
			local Value = UIExpression.DvarString(nil, "tap_to_interact")
			if Value == "1" then
				ZmQolApplyTapToInteract(ClientIndex, "1", Source)
			else
				Engine.Exec(ClientIndex, "echo [zm_qol] tap_to_interact is off or unset - binds left alone - source " .. tostring(Source))
			end
		end)
	end
end

LUI.createMenu.Loading = function (f6_arg0)
	-- zm_qol v2.10.2 - TAP TO INTERACT applied from its saved dvar on every
	-- map load (f6_arg0 is the controller: stock hands it to setOwner below).
	pcall(ZmQolApplyTapToInteractFromDvar, f6_arg0, "loading")
	-- zm_qol: clear the intro-cutscene gate at the TOP of every loading screen.
	-- Quitting mid-cutscene would otherwise leave it raised, and the next
	-- match would sit waiting for a video that is never going to play. Only
	-- the movie branch below puts it back up.
	pcall(Engine.SetDvar, "zmqol_cutscene", "0")
	local f6_local0 = CoD.Menu.NewFromState("Loading", {
		leftAnchor = true,
		rightAnchor = true,
		left = 0,
		right = 0,
		topAnchor = true,
		bottomAnchor = true,
		top = 0,
		bottom = 0
	})
	f6_local0:setOwner(f6_arg0)
	f6_local0:registerEventHandler("start_loading", CoD.Loading.StartLoading)
	f6_local0:registerEventHandler("start_spinner", CoD.Loading.StartSpinner)
	f6_local0:registerEventHandler("fade_in_map_location", CoD.Loading.FadeInMapLocation)
	f6_local0:registerEventHandler("fade_in_gametype", CoD.Loading.FadeInGametype)
	f6_local0:registerEventHandler("fade_in_map_image", CoD.Loading.FadeInMapImage)
	local f6_local1 = false
	local f6_local2 = Dvar.ui_mapname:get()
	local f6_local3 = Dvar.ui_gametype:get()
	local f6_local4 = "loadscreen_" .. f6_local2
	if CoD.isZombie == true then
		if (not (CoD.isOnlineGame() ~= false or Engine.SessionModeIsMode(CoD.SESSIONMODE_SYSTEMLINK) ~= false) or Dvar.party_maxplayers:get() == 1) and Engine.GameModeIsMode(CoD.GAMEMODE_THEATER) == false and (f6_local2 == CoD.Zombie.MAP_ZM_HIGHRISE or f6_local2 == CoD.Zombie.MAP_ZM_PRISON or f6_local2 == CoD.Zombie.MAP_ZM_BURIED or f6_local2 == CoD.Zombie.MAP_ZM_TOMB) and f6_local3 == CoD.Zombie.GAMETYPE_ZCLASSIC then
			f6_local4 = "black"
			f6_local1 = true
		else
			f6_local4 = "loadscreen_" .. f6_local2 .. "_" .. f6_local3 .. "_" .. Dvar.ui_zm_mapstartlocation:get()
			Engine.SetDvar("ui_zm_useloadingmovie", 0)
		end
	end
	f6_local0.mapImage = LUI.UIStreamedImage.new({
		leftAnchor = false,
		rightAnchor = false,
		left = -640,
		right = 640,
		topAnchor = false,
		bottomAnchor = false,
		top = -360,
		bottom = 360,
		material = RegisterMaterial(f6_local4),
		red = 0,
		green = 0,
		blue = 0,
		alpha = 1
	})
	f6_local0:addElement(f6_local0.mapImage)
	if f6_local1 == true then
		f6_local0.mapImage:setShaderVector(0, 0, 0, 0, 0)
		f6_local0.mapImage.iswebm = false
	end
	if f6_local1 == false then
		local f6_local5 = 200
		local f6_local6 = 0.6
		local f6_local7 = LUI.UIImage.new()
		f6_local7:setLeftRight(false, false, -640, 640)
		f6_local7:setTopBottom(true, false, 0, f6_local5)
		f6_local7:setImage(RegisterMaterial("gradient_top"))
		f6_local0:addElement(f6_local7)
		local f6_local8 = LUI.UIImage.new()
		f6_local8:setLeftRight(false, false, -640, 640)
		f6_local8:setTopBottom(false, true, -f6_local5, 0)
		f6_local8:setImage(RegisterMaterial("gradient_bottom"))
		f6_local0:addElement(f6_local8)
	end
	local f6_local5 = 50
	local f6_local6 = 70
	local f6_local7 = "Big"
	local f6_local8 = CoD.fonts[f6_local7]
	local f6_local9 = CoD.textSize[f6_local7]
	local f6_local10 = "Condensed"
	local f6_local11 = CoD.fonts[f6_local10]
	local f6_local12 = CoD.textSize[f6_local10]
	f6_local0.mapNameLabel = LUI.UIText.new()
	f6_local0.mapNameLabel:setLeftRight(true, false, f6_local6, f6_local6 + 1)
	f6_local0.mapNameLabel:setTopBottom(true, false, f6_local5, f6_local5 + f6_local9)
	f6_local0.mapNameLabel:setFont(f6_local8)
	f6_local0.mapNameLabel:setRGB(CoD.BOIIOrange.r, CoD.BOIIOrange.g, CoD.BOIIOrange.b)
	f6_local0.mapNameLabel:setAlpha(0)
	f6_local0.mapNameLabel:registerEventHandler("transition_complete_map_name_fade_in", CoD.Loading.MapNameFadeInComplete)
	f6_local0:addElement(f6_local0.mapNameLabel)
	f6_local5 = f6_local5 + f6_local9 - 5
	f6_local0.mapLocationLabel = LUI.UIText.new()
	f6_local0.mapLocationLabel:setLeftRight(true, false, f6_local6, f6_local6 + 1)
	f6_local0.mapLocationLabel:setTopBottom(true, false, f6_local5, f6_local5 + f6_local12)
	f6_local0.mapLocationLabel:setFont(f6_local11)
	f6_local0.mapLocationLabel:setRGB(CoD.offWhite.r, CoD.offWhite.g, CoD.offWhite.b)
	f6_local0.mapLocationLabel:setAlpha(0)
	f6_local0.mapLocationLabel:registerEventHandler("transition_complete_map_location_fade_in", CoD.Loading.MapLocationFadeInComplete)
	f6_local0:addElement(f6_local0.mapLocationLabel)
	f6_local5 = f6_local5 + f6_local12 - 2
	f6_local0.gametypeLabel = LUI.UIText.new()
	f6_local0.gametypeLabel:setLeftRight(true, false, f6_local6, f6_local6 + 1)
	f6_local0.gametypeLabel:setTopBottom(true, false, f6_local5, f6_local5 + f6_local12)
	f6_local0.gametypeLabel:setFont(f6_local11)
	f6_local0.gametypeLabel:setRGB(CoD.offWhite.r, CoD.offWhite.g, CoD.offWhite.b)
	f6_local0.gametypeLabel:setAlpha(0)
	f6_local0.gametypeLabel:registerEventHandler("transition_complete_gametype_fade_in", CoD.Loading.GametypeFadeInComplete)
	f6_local0:addElement(f6_local0.gametypeLabel)
	f6_local5 = f6_local5 + f6_local12 + 5
	-- 🛑 v2.3.1 - DECOMPILER BUG, NOT A STOCK BUG. GetTextDimensions returns
	-- FOUR separate values (x, y, width, height), never a table - confirmed
	-- against BO2-Reimagined's own working ui_mp\t6\hud\loading.lua, which
	-- unpacks all four (its f6_local14_1..4 etc.) and reads width off the
	-- third. The decompile this file is based on mis-reconstructed every
	-- multi-return call here as "assign into a pre-built {} table", so the
	-- single value Lua actually captured (the FIRST return, x) got indexed
	-- with [3] a moment later - "attempt to index a number value", crashing
	-- LUI_ERROR: Error processing event: addmenu the instant Loading is
	-- created, i.e. the moment ANY match is started. User, 2026-08-26, crash
	-- screenshot: "just clicked start game with my mod loaded for diner and
	-- got this crash error fix it so it never happens ever again". Full
	-- traceback measured from Plutonium\console.log, not guessed:
	-- "ui_mp/T6/HUD/Loading.lua:382: attempt to index a number value".
	local f6_local13 = Engine.Localize("MPUI_TITLE_CAPS") .. ":"
	local f6_local14_1, f6_local14_2, f6_local14_3, f6_local14_4 = GetTextDimensions(f6_local13, f6_local11, f6_local12)
	local f6_local15 = Engine.Localize("MPUI_DURATION_CAPS") .. ":"
	local f6_local16_1, f6_local16_2, f6_local16_3, f6_local16_4 = GetTextDimensions(f6_local15, f6_local11, f6_local12)
	local f6_local17 = Engine.Localize("MPUI_AUTHOR_CAPS") .. ":"
	local f6_local18_1, f6_local18_2, f6_local18_3, f6_local18_4 = GetTextDimensions(f6_local17, f6_local11, f6_local12)
	local f6_local19 = math.max(f6_local14_3, f6_local16_3, f6_local18_3) + 5
	local f6_local20 = 0
	f6_local0.demoInfoContainer = LUI.UIElement.new()
	f6_local0.demoInfoContainer:setLeftRight(true, false, f6_local6, 600)
	f6_local0.demoInfoContainer:setTopBottom(true, false, f6_local5, f6_local5 + 600)
	f6_local0.demoInfoContainer:setAlpha(0)
	f6_local0:addElement(f6_local0.demoInfoContainer)
	f6_local0.demoTitleTitle = LUI.UIText.new()
	f6_local0.demoTitleTitle:setLeftRight(true, true, 0, 0)
	f6_local0.demoTitleTitle:setTopBottom(true, false, f6_local20, f6_local20 + f6_local12)
	f6_local0.demoTitleTitle:setFont(f6_local11)
	f6_local0.demoTitleTitle:setRGB(CoD.BOIIOrange.r, CoD.BOIIOrange.g, CoD.BOIIOrange.b)
	f6_local0.demoTitleTitle:setAlignment(LUI.Alignment.Left)
	f6_local0.demoTitleTitle:setText(f6_local13)
	f6_local0.demoInfoContainer:addElement(f6_local0.demoTitleTitle)
	f6_local0.demoTitleLabel = LUI.UIText.new()
	f6_local0.demoTitleLabel:setLeftRight(true, true, f6_local19, 0)
	f6_local0.demoTitleLabel:setTopBottom(true, false, f6_local20, f6_local20 + f6_local12)
	f6_local0.demoTitleLabel:setFont(f6_local11)
	f6_local0.demoTitleLabel:setRGB(CoD.offWhite.r, CoD.offWhite.g, CoD.offWhite.b)
	f6_local0.demoTitleLabel:setAlignment(LUI.Alignment.Left)
	f6_local0.demoInfoContainer:addElement(f6_local0.demoTitleLabel)
	f6_local20 = f6_local20 + f6_local12 - 2
	f6_local0.demoDurationTitle = LUI.UIText.new()
	f6_local0.demoDurationTitle:setLeftRight(true, true, 0, 0)
	f6_local0.demoDurationTitle:setTopBottom(true, false, f6_local20, f6_local20 + f6_local12)
	f6_local0.demoDurationTitle:setFont(f6_local11)
	f6_local0.demoDurationTitle:setRGB(CoD.BOIIOrange.r, CoD.BOIIOrange.g, CoD.BOIIOrange.b)
	f6_local0.demoDurationTitle:setAlignment(LUI.Alignment.Left)
	f6_local0.demoDurationTitle:setText(f6_local15)
	f6_local0.demoInfoContainer:addElement(f6_local0.demoDurationTitle)
	f6_local0.demoDurationLabel = LUI.UIText.new()
	f6_local0.demoDurationLabel:setLeftRight(true, true, f6_local19, 0)
	f6_local0.demoDurationLabel:setTopBottom(true, false, f6_local20, f6_local20 + f6_local12)
	f6_local0.demoDurationLabel:setFont(f6_local11)
	f6_local0.demoDurationLabel:setRGB(CoD.offWhite.r, CoD.offWhite.g, CoD.offWhite.b)
	f6_local0.demoDurationLabel:setAlignment(LUI.Alignment.Left)
	f6_local0.demoInfoContainer:addElement(f6_local0.demoDurationLabel)
	f6_local20 = f6_local20 + f6_local12 - 2
	f6_local0.demoAuthorTitle = LUI.UIText.new()
	f6_local0.demoAuthorTitle:setLeftRight(true, true, 0, 0)
	f6_local0.demoAuthorTitle:setTopBottom(true, false, f6_local20, f6_local20 + f6_local12)
	f6_local0.demoAuthorTitle:setFont(f6_local11)
	f6_local0.demoAuthorTitle:setRGB(CoD.BOIIOrange.r, CoD.BOIIOrange.g, CoD.BOIIOrange.b)
	f6_local0.demoAuthorTitle:setAlignment(LUI.Alignment.Left)
	f6_local0.demoAuthorTitle:setText(f6_local17)
	f6_local0.demoInfoContainer:addElement(f6_local0.demoAuthorTitle)
	f6_local0.demoAuthorLabel = LUI.UIText.new()
	f6_local0.demoAuthorLabel:setLeftRight(true, true, f6_local19, 0)
	f6_local0.demoAuthorLabel:setTopBottom(true, false, f6_local20, f6_local20 + f6_local12)
	f6_local0.demoAuthorLabel:setFont(f6_local11)
	f6_local0.demoAuthorLabel:setRGB(CoD.offWhite.r, CoD.offWhite.g, CoD.offWhite.b)
	f6_local0.demoAuthorLabel:setAlignment(LUI.Alignment.Left)
	f6_local0.demoInfoContainer:addElement(f6_local0.demoAuthorLabel)
	local f6_local21 = 3
	local f6_local22 = CoD.Loading.DYKFontHeight + f6_local21 * 2
	local f6_local23 = 2
	local f6_local24 = f6_local22 + 1 + f6_local23 + CoD.Loading.DYKFontHeight - f6_local5
	local f6_local25 = CoD.Menu.Width - 5 * 2
	local f6_local26 = -200
	local f6_local27 = 0
	local f6_local28 = 2
	local f6_local29 = f6_local22 - f6_local28 * 2
	local f6_local30 = 6
	f6_local0.loadingBarContainer = LUI.UIElement.new()
	f6_local0.loadingBarContainer:setLeftRight(false, false, -f6_local25 / 2, f6_local25 / 2)
	f6_local0.loadingBarContainer:setTopBottom(false, true, f6_local26 - f6_local24, f6_local26)
	f6_local0.loadingBarContainer:setAlpha(0)
	f6_local0:addElement(f6_local0.loadingBarContainer)
	f6_local0.dykContainer = LUI.UIElement.new()
	f6_local0.dykContainer:setLeftRight(true, true, 0, 0)
	f6_local0.dykContainer:setTopBottom(true, false, f6_local27, f6_local27 + f6_local22)
	f6_local0.dykContainer.containerHeight = f6_local22
	f6_local0.dykContainer.textAreaWidth = f6_local25 - f6_local21 - f6_local30 - f6_local28 - f6_local29 - 1
	f6_local0.loadingBarContainer:addElement(f6_local0.dykContainer)
	if CoD.isZombie == false then
		CoD.Loading.SetupDYKContainerImages(f6_local0.dykContainer)
		f6_local0.didYouKnow = LUI.UIText.new()
		f6_local0.didYouKnow:setLeftRight(true, true, f6_local21 + f6_local30, -f6_local28 - f6_local29 - 1)
		f6_local0.didYouKnow:setTopBottom(true, false, f6_local21, f6_local21 + CoD.Loading.DYKFontHeight)
		f6_local0.didYouKnow:setRGB(CoD.offWhite.r, CoD.offWhite.g, CoD.offWhite.b)
		f6_local0.didYouKnow:setFont(CoD.Loading.DYKFont)
		f6_local0.didYouKnow:setAlignment(LUI.Alignment.Left)
		f6_local0.didYouKnow:setPriority(0)
		f6_local0.dykContainer:addElement(f6_local0.didYouKnow)
	else
		f6_local30 = 0
	end
	f6_local27 = f6_local27 + f6_local22 + 1
	f6_local0.spinner = LUI.UIImage.new()
	f6_local0.spinner:setLeftRight(false, true, -f6_local28 - f6_local29, -f6_local28)
	f6_local0.spinner:setTopBottom(false, false, -f6_local29 / 2, f6_local29 / 2)
	f6_local0.spinner:setImage(RegisterMaterial("lui_loader_32"))
	f6_local0.spinner:setShaderVector(0, 0, 0, 0, 0)
	f6_local0.spinner:setAlpha(0)
	f6_local0.dykContainer:addElement(f6_local0.spinner)
	local f6_local31 = LUI.UIImage.new()
	f6_local31:setLeftRight(true, true, 1, -1)
	f6_local31:setTopBottom(true, false, f6_local27, f6_local27 + f6_local23)
	f6_local31:setRGB(0.1, 0.1, 0.1)
	f6_local0.loadingBarContainer:addElement(f6_local31)
	local f6_local32 = LUI.UIImage.new()
	f6_local32:setLeftRight(true, true, 1, -1)
	f6_local32:setTopBottom(true, false, f6_local27, f6_local27 + f6_local23)
	f6_local32:setRGB(CoD.BOIIOrange.r, CoD.BOIIOrange.g, CoD.BOIIOrange.b)
	f6_local32:setupLoadingBar()
	f6_local0.loadingBarContainer:addElement(f6_local32)
	local f6_local33 = 1
	local f6_local34 = LUI.UIImage.new()
	f6_local34:setLeftRight(true, true, 2, -2)
	f6_local34:setTopBottom(true, false, f6_local27, f6_local27 + f6_local33)
	f6_local34:setRGB(1, 1, 1)
	f6_local34:setAlpha(0.5)
	f6_local34:setupLoadingBar()
	f6_local0.loadingBarContainer:addElement(f6_local34)
	f6_local27 = f6_local27 + f6_local23
	f6_local0.statusLabel = LUI.UIText.new()
	f6_local0.statusLabel:setLeftRight(true, true, f6_local21 + f6_local30, 0)
	f6_local0.statusLabel:setTopBottom(true, false, f6_local27, f6_local27 + CoD.Loading.DYKFontHeight)
	f6_local0.statusLabel:setAlpha(0.55)
	f6_local0.statusLabel:setFont(CoD.Loading.DYKFont)
	f6_local0.statusLabel:setAlignment(LUI.Alignment.Left)
	f6_local0.statusLabel:setupLoadingStatusText()
	f6_local0.loadingBarContainer:addElement(f6_local0.statusLabel)
	if f6_local1 == true then
		f6_local0.mapImage:registerEventHandler("loading_updateimage", f0_local0)
		f6_local0:addElement(LUI.UITimer.new(16, "loading_updateimage", false, f6_local0.mapImage))
		Engine.SetDvar("ui_zm_useloadingmovie", 1)
		-- zm_qol: the intro cutscene is now on screen. quality_of_life.gsc holds
		-- the first round until f0_local3 above puts this back to 0.
		pcall(Engine.SetDvar, "zmqol_cutscene", "1")
		local f6_local35 = 15
		local f6_local36 = 15
		local f6_local37, f6_local38 = Engine.GetUserSafeArea()
		f6_local0.continueButton = LUI.UIButton.new()
		f6_local0.continueButton:setLeftRight(false, false, -f6_local37, f6_local37 / 2 - f6_local35)
		f6_local0.continueButton:setTopBottom(false, false, f6_local38 / 2 - CoD.textSize.Condensed - f6_local36, f6_local38 / 2 - f6_local36)
		f6_local0.continueButton:setAlignment(LUI.Alignment.Right)
		f6_local0.continueButton:setAlpha(0)
		f6_local0.continueButton:setActionEventName("loading_startplay")
		f6_local0:addElement(f6_local0.continueButton)
		f6_local0.continueButton:addElement(CoD.ButtonPrompt.new("start", "", f6_local0, "loading_startplay", true))
		f6_local0.continueButton.label = LUI.UIText.new()
		f6_local0.continueButton.label:setLeftRight(true, true, 0, 0)
		f6_local0.continueButton.label:setTopBottom(true, true, 0, 0)
		f6_local0.continueButton.label:setFont(CoD.fonts.Condensed)
		f6_local0.continueButton.label:setAlignment(LUI.Alignment.Right)
		f6_local0.continueButton:addElement(f6_local0.continueButton.label)
		f6_local0.continueButton.label:setText(Engine.Localize("PLATFORM_SKIP"))
		f6_local0.continueButton:setHandleMouse(false)
		f6_local0:registerEventHandler("loading_displaycontinue", f0_local2)
		f6_local0:registerEventHandler("loading_startplay", f0_local3)
	else
		f6_local0:addElement(LUI.UITimer.new(CoD.Loading.LoadingDelayTime, "start_loading", true, f6_local0))
		f6_local0:addElement(LUI.UITimer.new(CoD.Loading.SpinnerDelayTime, "start_spinner", true, f6_local0))
	end
	return f6_local0
end

CoD.Loading.GetDidYouKnowString = function ()
	local f7_local0 = 0
	local f7_local1 = ""
	local f7_local2 = 0
	if Engine.GameModeIsMode(CoD.GAMEMODE_THEATER) == true then
		f7_local0 = #CoD.Loading.DidYouKnow.theater
		if f7_local0 ~= nil and 0 < f7_local0 then
			f7_local1 = CoD.Loading.DidYouKnow.theater[math.random(f7_local0)]
		end
	elseif CoD.isZombie == true then
		f7_local0 = #CoD.Loading.DidYouKnow.zombies
		if f7_local0 ~= nil and 0 < f7_local0 then
			f7_local1 = CoD.Loading.DidYouKnow.zombies[math.random(f7_local0)]
		end
	else
		local f7_local3 = #CoD.Loading.DidYouKnow.general
		f7_local0 = f7_local0 + f7_local3
		local f7_local4 = Dvar.ui_gametype:get()
		local f7_local5 = 0
		if f7_local4 ~= nil and f7_local4 ~= "" and CoD.Loading.DidYouKnow[f7_local4] then
			f7_local5 = #CoD.Loading.DidYouKnow[f7_local4]
		end
		f7_local0 = f7_local0 + f7_local5
		local f7_local6 = 0
		local f7_local7 = 0
		if Engine.GameModeIsMode(CoD.GAMEMODE_LEAGUE_MATCH) == true then
			f7_local6 = #CoD.Loading.DidYouKnow.league
		elseif Engine.GameModeIsMode(CoD.GAMEMODE_PUBLIC_MATCH) == true then
			f7_local7 = #CoD.Loading.DidYouKnow.public
		end
		f7_local2 = math.random(f7_local0 + f7_local6 + f7_local7)
		if f7_local2 <= f7_local3 then
			f7_local1 = CoD.Loading.DidYouKnow.general[f7_local2]
		elseif 0 < f7_local5 and f7_local2 <= f7_local3 + f7_local5 then
			f7_local1 = CoD.Loading.DidYouKnow[f7_local4][f7_local2 - f7_local3]
		elseif 0 < f7_local7 and f7_local2 <= f7_local3 + f7_local5 + f7_local7 then
			f7_local1 = CoD.Loading.DidYouKnow.public[f7_local2 - f7_local3 - f7_local5]
		elseif 0 < f7_local6 and f7_local2 <= f7_local3 + f7_local5 + f7_local7 + f7_local6 then
			f7_local1 = CoD.Loading.DidYouKnow.league[f7_local2 - f7_local3 - f7_local5 - f7_local7]
		end
	end
	if f7_local1 == nil or f7_local1 == "" then
		return ""
	else
		return Engine.Localize(f7_local1)
	end
end

-- zm_qol - the loading screen's big title. In CLASSIC the map name is the right
-- answer ("Green Run"); in every other zombies gametype the START LOCATION is,
-- which is what turns "GREEN RUN" into "DINER". Mirrors GetMapDisplayName() in
-- zm_qol's scoreboard.lua, except it takes column 4 (ALL CAPS) instead of 16,
-- because this label is the caps one.
--
-- Returns the stock ls_mapname at every step that cannot be resolved, so the
-- title can never come out blank.
function CoD.Loading.GetZMLoadingMapName()
	local StockName = Dvar.ls_mapname:get()

	if CoD.isZombie ~= true then
		return StockName
	end

	local gametype = UIExpression.DvarString(nil, "ui_gametype")
	if gametype == CoD.Zombie.GAMETYPE_ZCLASSIC then
		return StockName
	end

	local location = UIExpression.DvarString(nil, "ui_zm_mapstartlocation")
	if location == nil or location == "" then
		return StockName
	end

	-- zm_qol: caps titles for the survival locations that have NO row in stock
	-- zm\gametypestable.csv (dumped 2026-09-02: power, tunnel and the three Die
	-- Rise locations are absent; diner/cellblock/street have rows). crazy_place
	-- is absent for the same reason - Origins has no survival row of any kind.
	local ZmQolLocationTitles = {
		power          = "POWER STATION",
		tunnel         = "TUNNEL",
		shopping_mall  = "SHOPPING MALL",
		dragon_rooftop = "DRAGON ROOFTOP",
		sweatshop      = "SWEATSHOP",
		crazy_place    = "THE CRAZY PLACE",
	}
	if ZmQolLocationTitles[location] ~= nil then
		return ZmQolLocationTitles[location]
	end

	local LocationKey = UIExpression.TableLookup(nil, CoD.gametypesTable, 0, 5, 3, location, 4)
	if LocationKey == nil or LocationKey == "" then
		return StockName
	end

	-- Engine.Localize hands the key straight back when the string is missing,
	-- which is how a bad key is told from a good one.
	local LocationName = Engine.Localize(LocationKey)
	if LocationName == nil or LocationName == "" or string.match(LocationName, LocationKey) ~= nil then
		return StockName
	end

	return LocationName
end

CoD.Loading.StartLoading = function (f8_arg0, f8_arg1)
	local f8_local0 = CoD.Loading.GetZMLoadingMapName()
	local f8_local1 = Dvar.ls_maplocation:get()
	local f8_local2 = Dvar.ls_gametype:get()
	f8_arg0.mapNameLabel:setText(f8_local0)
	f8_arg0.mapLocationLabel:setText(f8_local1)
	f8_arg0.gametypeLabel:setText(f8_local2)
	if UIExpression.IsDemoPlaying(f8_arg0:getOwner()) ~= 0 then
		local f8_local3 = Dvar.ls_demotitle:get()
		local f8_local4 = UIExpression.SecondsAsTime(nil, Dvar.ls_demoduration:get())
		local f8_local5 = Dvar.ls_demoauthor:get()
		f8_arg0.demoTitleLabel:setText(f8_local3)
		f8_arg0.demoDurationLabel:setText(f8_local4)
		f8_arg0.demoAuthorLabel:setText(f8_local5)
		if f8_local5 == "" then
			f8_arg0.demoAuthorTitle:setAlpha(0)
		end
	end
	if CoD.isZombie == false then
		local f8_local3 = CoD.Loading.GetDidYouKnowString()
		-- 🛑 v2.3.1 - same decompiler bug as the demo-info block above (see the
		-- note there): GetTextDimensions returns four values, not a table.
		-- This one only fires on a non-zombies loading screen (the isZombie
		-- guard above), which is why the Diner crash didn't reach it first.
		local f8_local4_1, f8_local4_2, f8_local4_3, f8_local4_4 = GetTextDimensions(f8_local3, CoD.Loading.DYKFont, CoD.Loading.DYKFontHeight)
		if f8_arg0.dykContainer.textAreaWidth < f8_local4_3 then
			f8_arg0.dykContainer:setTopBottom(true, false, -CoD.Loading.DYKFontHeight, f8_arg0.dykContainer.containerHeight)
		end
		f8_arg0.didYouKnow:setText(f8_local3)
	end
	f8_arg0.mapNameLabel:beginAnimation("map_name_fade_in", CoD.Loading.FadeInTime)
	f8_arg0.mapNameLabel:setAlpha(1)
end

CoD.Loading.StartSpinner = function (f9_arg0, f9_arg1)
	f9_arg0.spinner:beginAnimation("spinner_fade_in", 200)
	f9_arg0.spinner:setAlpha(1)
end

CoD.Loading.MapNameFadeInComplete = function (f10_arg0)
	f10_arg0:dispatchEventToParent({
		name = "fade_in_map_location"
	})
end

CoD.Loading.FadeInMapLocation = function (f11_arg0)
	f11_arg0.mapLocationLabel:beginAnimation("map_location_fade_in", CoD.Loading.FadeInTime)
	f11_arg0.mapLocationLabel:setAlpha(1)
end

CoD.Loading.MapLocationFadeInComplete = function (f12_arg0)
	f12_arg0:dispatchEventToParent({
		name = "fade_in_gametype"
	})
end

CoD.Loading.FadeInGametype = function (f13_arg0)
	f13_arg0.gametypeLabel:beginAnimation("gametype_fade_in", CoD.Loading.FadeInTime)
	f13_arg0.gametypeLabel:setAlpha(0.6)
end

CoD.Loading.GametypeFadeInComplete = function (f14_arg0)
	f14_arg0:dispatchEventToParent({
		name = "fade_in_map_image"
	})
end

CoD.Loading.FadeInMapImage = function (f15_arg0)
	f15_arg0.mapImage:beginAnimation("map_image_fade_in", CoD.Loading.FadeInTime)
	f15_arg0.mapImage:setRGB(1, 1, 1)
	f15_arg0.loadingBarContainer:beginAnimation("loading_bar_fade_in", CoD.Loading.FadeInTime)
	f15_arg0.loadingBarContainer:setAlpha(1)
	if UIExpression.IsDemoPlaying(f15_arg0:getOwner()) ~= 0 then
		f15_arg0.demoInfoContainer:beginAnimation("demo_info_fade_in", CoD.Loading.FadeInTime)
		f15_arg0.demoInfoContainer:setAlpha(1)
	end
end

CoD.Loading.SetupDYKContainerImages = function (f16_arg0)
	local f16_local0 = LUI.UIImage.new()
	f16_local0:setLeftRight(true, true, 0, 0)
	f16_local0:setTopBottom(true, true, 0, 0)
	f16_local0:setRGB(0, 0, 0)
	f16_local0:setAlpha(0.52)
	f16_local0:setPriority(-110)
	f16_arg0:addElement(f16_local0)
	local f16_local1 = CoD.Border.new(1, 1, 1, 1, 0.05)
	f16_local1:setPriority(-100)
	f16_arg0:addElement(f16_local1)
	local f16_local2 = LUI.UIImage.new()
	f16_local2:setLeftRight(true, true, 2, -2)
	f16_local2:setTopBottom(true, true, 1, -1)
	f16_local2:setImage(RegisterMaterial(CoD.MPZM("menu_mp_cac_grad_stretch", "menu_zm_cac_grad_stretch")))
	f16_local2:setRGB(0, 0, 0)
	f16_local2:setAlpha(0.65)
	f16_local2:setPriority(-80)
	f16_arg0:addElement(f16_local2)
	local f16_local3 = LUI.UIImage.new()
	f16_local3:setLeftRight(true, true, 3, -3)
	f16_local3:setTopBottom(true, false, 3, 23)
	f16_local3:setImage(RegisterMaterial(CoD.MPZM("menu_mp_cac_grad_stretch", "menu_zm_cac_grad_stretch")))
	f16_local3:setPriority(100)
	f16_local3:setAlpha(0.06)
	f16_arg0:addElement(f16_local3)
end

