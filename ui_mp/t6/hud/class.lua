-- ============================================================================
--  zm_qol - THE ZOMBIES PAUSE MENU, +3 ROWS. Queue items 27, 28 and 29.
--
--  User, 2026-08-19, from a friend's screen-share:
--    28  INSTANT EXIT   - under the existing END GAME, straight to the lobby
--                         with no game-over music and no scoreboard. Same effect
--                         as the `disconnect` console command they already have
--                         bound and have confirmed works.
--    29  QUIT TO DESKTOP - runs `quit`, closes the game instantly.
--  🛑 END GAME IS NOT TOUCHED. The user was explicit about that; these are
--  additions beside it.
--
--  🌟 27 RESTART GAME - the SECOND row, directly under RESUME GAME, which is
--                      where the user asked for it and also exactly where stock
--                      puts it. Shipped v1.99.87.
--
--  🛑 IT IS NOT MERELY A RELAXED CONDITION, WHICH IS WHAT QUEUE.md ASSUMED.
--  Stock gates the button on the session being SYSTEMLINK or OFFLINE, and
--  Plutonium reports neither - but PLUTONIUM'S OWN class.lua, this file's base,
--  has removed the whole branch and its handler as well, so there was no
--  condition left to relax. What made it shippable anyway is that the rest of
--  the feature is still in the game: patch_zm.ff ships
--  ui_mp\t6\zombie\restartgamepopupzombie.lua with the confirm popup intact,
--  and stock's own restart inside it is Engine.Exec( controller, 'fast_restart' )
--  - a command whose string is present in t6zm.exe. So this is Treyarch's
--  button, Treyarch's popup and Treyarch's restart command, re-connected. The
--  popup needed two lines changed for the same session-mode reason; they are
--  marked in that file.
--
--  ── WHY THIS FILE CAN BE OVERRIDDEN AT ALL, measured ────────────────────────
--  `class.lua` is loaded at BOOT, before any mod is on the search path
--  (console_zm.log line 512, loadmod at 682) - so a naive reading says a mod can
--  never win it. But it is loaded a SECOND time after a mod loads: in the
--  2026-08-19 session log it appears at line 524 and again at 861, with
--  `loadmod: loaded mods/zm_qol` at 701 and `Loading fastfile mod` at 730 in
--  between. At that point the search path has
--  `storage\t6\mods\zm_qol\mod.iwd` at RANK 1, above `storage\t6\raw` at rank 3
--  (both orderings are printed verbatim in the log). So this copy wins while the
--  mod is loaded, and it wins for someone who merely downloaded the release -
--  unlike optionssettings.lua and the other two frontend files, which are menu
--  time only and therefore have to be synced into Plutonium's raw\ folder by
--  build.bat.
--
--  🛑 THE BASE IS PLUTONIUM'S FILE, NOT TREYARCH'S. It is a copy of
--  storage\t6\raw\ui_mp\t6\hud\class.lua with only the marked additions. Their
--  version already differs from stock (the RESTART GAME branch is gone). If
--  Plutonium ships a new class.lua, this copy shadows it while the mod is
--  loaded - re-copy and re-apply the two marked blocks when that happens.
-- ============================================================================
require("T6.HUD.InGameMenus")
require("T6.UnifiedFriends")
if CoD.isMultiplayer and not CoD.isZombie then
	require("T6.XPBar")
end
CoD.Class = {}

CoD.Class.DisableChooseTeam = function ()
	if CoD.Class.GametypeSettings.allowInGameTeamChange == 1 then
		return false
	end
	if CoD.Class.GametypeSettings.allowSpectating == 1 then
		return false
	end
	return true
end

CoD.Class.DisableChooseClass = function ()
	return CoD.Class.GametypeSettings.disableClassSelection == 1
end

CoD.Class.IsChooseTeamAvailable = function ()
	if CoD.isZombie and CoD.Class.GametypeSettings.teamCount < 2 then
		return false
	end
	if CoD.Class.GametypeSettings.allowInGameTeamChange == 0 and CoD.Class.GametypeSettings.allowSpectating == 0 then
		return false
	end
	return true
end

CoD.Class.AddButton = function (IngameMenuWidget, ButtonName, MenuName, f3_arg3)
	local NewButton = IngameMenuWidget.buttonList:addButton(ButtonName)
	NewButton:setActionEventName(MenuName)
	if f3_arg3 == true then
		NewButton:disable()
	end
	return NewButton
end

CoD.Class.ChooseClassButtonPressed = function (IngameMenuWidget, ClientInstance)
	IngameMenuWidget:saveState()
	IngameMenuWidget:openMenu("changeclass", ClientInstance.controller)
	IngameMenuWidget:close()
end

CoD.Class.OptionsButtonPressed = function (IngameMenuWidget, ClientInstance)
	IngameMenuWidget:saveState()
	if ZmQolInstallParentOptionsMenu then
		ZmQolInstallParentOptionsMenu()
	end
	IngameMenuWidget:openMenu("OptionsMenu", ClientInstance.controller)
	IngameMenuWidget:close()
end

CoD.Class.EndGameButtonPressed = function (IngameMenuWidget, ClientInstance)
	IngameMenuWidget:openPopup("EndGamePopup", ClientInstance.controller)
end

-- zm_qol ADDITION 1 of 2 - the two handlers. Engine.Exec( controller, cmd ) is
-- the shipped route for running a console command from LUI: Plutonium's own
-- mainlobby.lua uses it for xsigninlive, and this mod's optionssettings.lua
-- already uses it for vid_restart and snd_restart. Both command names were
-- confirmed present in t6zm.exe's string table.
-- v1.99.91 - RESTART GAME is now ONE console command and nothing else.
--
-- User, 2026-08-20: *"the only one that didn't work was the Restart option, it
-- did a bunch of wacky stuff and also froze my game, just make it behave the
-- same way as the map_restart console command, it simply restarts map not
-- complicated at all."*
--
-- v1.99.87 routed this through stock's RestartGamePopup, whose RestartLevel
-- runs a fade-to-black, a `silence`, a controller-rumble stop, sets
-- ui_busyBlockIngameMenu and only then restarts - and it restarted with
-- `fast_restart`. That is the "wacky stuff", and with the UI busy-blocked a
-- restart that does not complete leaves the game frozen with no way back.
-- The popup override has been deleted with this change; stock's own copy in
-- patch_zm.ff is untouched and is what any other caller now gets.
--
-- This is the same shape as INSTANT EXIT below, which the user confirmed
-- working in the same session: one Engine.Exec of one command the user named.
CoD.Class.ZmQolRestartPressed = function (IngameMenuWidget, ClientInstance)
	Engine.Exec(ClientInstance.controller, "map_restart")
end

-- v2.15.12 - FAST RESTART, re-added after a LIVE re-test. User, 2026-09-09.
--
-- 🛑 THIS WAS REMOVED IN v2.2.6 BECAUSE fast_restart CRASHED 3/3 - and that
-- removal was correct FOR THAT BUILD. It is re-added now only because the
-- command was re-tested on Plutonium r5346 on 2026-09-09 and did NOT crash:
-- sent once from the CLI into a live TranZit match, the game stayed on the same
-- pid, reloaded the zones and came back with sv_running 1 and no crash dump and
-- no console error. Plutonium fixed the engine bug the old note's minidump
-- described (null read at 0x4) some time after 2026-08-23. Same shape as
-- RESTART GAME above: one Engine.Exec of one command, no popup, no busy-block -
-- the popup + busy-block was the OTHER half of the old freeze and stays gone.
--
-- 📝 If a future Plutonium update reintroduces the crash, this is the row to
-- pull again; map_restart (RESTART GAME) is the crash-free full-reload fallback.
CoD.Class.ZmQolFastRestartPressed = function (IngameMenuWidget, ClientInstance)
	-- ========================================================================
	-- 🛑 v2.15.40 - BACK TO ONE EXEC AND NOTHING ELSE (the v2.15.12 shape).
	-- The v2.15.37 story below is kept for the record, but its premise was
	-- wrong and its fix did not hold.
	--
	-- What happened on 2026-09-11: FAST RESTART pressed from this row on
	-- Nuketown survival round 3 hard-crashed the process with an access
	-- violation (0xC0000005; last GSC pos maps/mp/_visionset_mgr::monitor,
	-- 'type undefined is not an int' - teardown fallout, not the cause).
	-- No LUI_ERROR dialog, no later INSTANT EXIT involved: the row itself
	-- kills the game.
	--
	-- That refutes v2.15.37's core premise, stated below, that Engine.Exec
	-- QUEUES the restart to end of frame: if the teardown really ran after
	-- the close had finished, there would be nothing left to race. The
	-- restart evidently tears the level down synchronously enough that the
	-- menu close in the same handler runs on a dying UI - the same
	-- same-frame teardown+UI race as v2.15.36 (orphaned transition) and
	-- v2.15.34 (CloseAllInGameMenus freeze), third verse. The 2026-09-09
	-- clean re-test is consistent with it: that restart was sent from the
	-- console with NO menu open at all, so there was nothing to race.
	--
	-- So per v2.15.37's own fallback instruction, the processEvent close is
	-- deleted. The pause menu stays open over the restarting match; one
	-- back-press closes it once the restart has completed. One extra click,
	-- zero same-frame races - and this is a previously SHIPPED shape
	-- (v2.15.12), not a new invention. (v2.15.36/37's full notes live in
	-- git history, not here.)
	-- ========================================================================
	Engine.Exec(ClientInstance.controller, "fast_restart")
end

CoD.Class.ZmQolInstantExitPressed = function (IngameMenuWidget, ClientInstance)
	Engine.Exec(ClientInstance.controller, "disconnect")
end

CoD.Class.ZmQolQuitToDesktopPressed = function (IngameMenuWidget, ClientInstance)
	Engine.Exec(ClientInstance.controller, "quit")
end

CoD.Class.ResumeGameButtonPressed = function (IngameMenuWidget, ClientInstance)
	IngameMenuWidget:processEvent({
		name = "button_prompt_back",
		controller = ClientInstance.controller
	})
end

CoD.Class.ChooseTeamButtonPressed = function (IngameMenuWidget, ClientInstance)
	IngameMenuWidget:saveState()
	IngameMenuWidget:openMenu("team_marinesopfor", ClientInstance.controller)
	IngameMenuWidget:close()
end

CoD.Class.ButtonPromptFriendsMenu = function (IngameMenuWidget, ClientInstance)
	IngameMenuWidget:saveState()
	local f11_local0 = IngameMenuWidget:openMenu("FriendsList", ClientInstance.controller)
	f11_local0:setPreviousMenu("class")
	IngameMenuWidget:close()
end

CoD.Class.PrepareClassButtonList = function (LocalClientIndex, IngameMenuWidget)
	local f12_local0 = CoD.SplitscreenScaler.new(nil, 1.5)
	f12_local0:setLeftRight(true, false, 0, 0)
	f12_local0:setTopBottom(true, false, 0, 0)
	IngameMenuWidget:addElement(f12_local0)
	IngameMenuWidget.buttonList = CoD.ButtonList.new({
		leftAnchor = true,
		rightAnchor = false,
		left = 0,
		right = CoD.ButtonList.DefaultWidth,
		topAnchor = true,
		bottomAnchor = false,
		top = CoD.Menu.TitleHeight,
		bottom = CoD.Menu.TitleHeight + 720
	})
	f12_local0:addElement(IngameMenuWidget.buttonList)
	if CoD.isZombie == true then
		if Engine.CanPauseZombiesGame() and CoD.canLeaveGame(LocalClientIndex) then
			CoD.Class.AddButton(IngameMenuWidget, Engine.Localize("MENU_RESUMEGAME_CAPS"), "soloResumeGame")
			-- zm_qol v1.99.87 - RESTART GAME, queue item 27, as the SECOND row
			-- directly under RESUME GAME. That is where the user asked for it
			-- and it is also exactly where stock puts it: stock's own
			-- PrepareClassButtonList adds MENU_RESTART_LEVEL_CAPS here, inside
			-- this same if, gated on the session being SYSTEMLINK or OFFLINE.
			-- Plutonium reports neither, and its class.lua dropped the whole
			-- branch, so the row is re-added without that test. The string and
			-- the popup are both stock; see restartgamepopupzombie.lua for the
			-- two lines that had to change in the popup itself.
			CoD.Class.AddButton(IngameMenuWidget, Engine.Localize("MENU_RESTART_LEVEL_CAPS"), "zmqol_restart_game")
			-- v2.15.12 - FAST RESTART, directly under RESTART GAME. Re-added after
			-- the 2026-09-09 live re-test proved fast_restart no longer crashes on
			-- r5346 (see the handler banner above). Engine.Localize returns the key
			-- itself when a string is absent, so the literal reads as the row text.
			CoD.Class.AddButton(IngameMenuWidget, Engine.Localize("FAST RESTART"), "zmqol_fast_restart")
			-- 🛑 v2.2.6 - THE FAST RESTART ROW IS GONE, AND THE ROW WAS NEVER THE BUG.
			-- The user reproduced the crash by typing `fast_restart` into the console
			-- with no menu involved (2026-08-23), which retires every theory that
			-- blamed this row's command list. Three console logs carry `Restart: 1`
			-- (.000, .008, .009) and all three END at the re-init - three crashes out
			-- of three attempts. Two of those ran v2.2.5, whose post-restart dvar dump
			-- reads r_aaSamples "8" of r_aaSamplesMax "8", so ERROR_CATALOGUE 26b's
			-- latched-dvar cause is ruled out as well. The minidump's own exception
			-- record is a null-pointer READ at address 0x4 inside the game image, and
			-- the console log carries no GSC error line at all, so the mechanism could
			-- not be named offline. Per the user's instruction (2026-08-23) the row is
			-- removed rather than shipped broken.
			-- 📝 RESTART GAME above STAYS. It runs `map_restart`, a full reload, which
			-- is a different engine path and appears in none of the three crashes.
		end
	else
		if UIExpression.Team(LocalClientIndex, "name") ~= "TEAM_SPECTATOR" and CoD.IsWagerMode() == false then
			CoD.Class.AddButton(IngameMenuWidget, Engine.Localize("MPUI_CHOOSE_CLASS_BUTTON_CAPS"), "open_chooseClass", CoD.Class.DisableChooseClass())
		end
	end
	if UIExpression.IsVisibilityBitSet(LocalClientIndex, CoD.BIT_ROUND_END_KILLCAM) == 0 and UIExpression.IsVisibilityBitSet(LocalClientIndex, CoD.BIT_FINAL_KILLCAM) == 0 and CoD.Class.IsChooseTeamAvailable() then
		CoD.Class.AddButton(IngameMenuWidget, Engine.Localize("MPUI_CHANGE_TEAM_BUTTON_CAPS"), "open_chooseTeam", CoD.Class.DisableChooseTeam())
	end
	CoD.Class.AddButton(IngameMenuWidget, Engine.Localize("MENU_OPTIONS_CAPS"), "open_options")
	if CoD.canLeaveGame(LocalClientIndex) then
		if CoD.isHost() then
			CoD.Class.AddButton(IngameMenuWidget, Engine.Localize("MENU_END_GAME_CAPS"), "open_endGamePopup")
		else
			CoD.Class.AddButton(IngameMenuWidget, Engine.Localize("MENU_LEAVE_GAME_CAPS"), "open_endGamePopup")
		end
		-- zm_qol ADDITION 2 of 2, part a - INSTANT EXIT, immediately under END
		-- GAME as asked, and inside the SAME canLeaveGame() gate: leaving is
		-- leaving, so if the game will not let you end it, it must not offer a
		-- faster way out either.
		if CoD.isZombie == true then
			CoD.Class.AddButton(IngameMenuWidget, Engine.Localize("INSTANT EXIT"), "zmqol_instant_exit")
		end
	end
	-- part b - QUIT TO DESKTOP. Outside the canLeaveGame() gate on purpose:
	-- closing the program is always available, and it is last so it cannot be
	-- hit by muscle memory aimed at the row above.
	-- 📝 No confirmation step, which is what the user asked for ("closes the
	-- game instantly"). It is one row below INSTANT EXIT on a menu people
	-- navigate blind, so if they ever want a confirm popup, EndGameButtonPressed
	-- above is the pattern to copy.
	if CoD.isZombie == true then
		CoD.Class.AddButton(IngameMenuWidget, Engine.Localize("QUIT TO DESKTOP"), "zmqol_quit_desktop")
	end
	if not IngameMenuWidget:restoreState() then
		IngameMenuWidget.buttonList:processEvent({
			name = "gain_focus_skip_disabled"
		})
	end
end

LUI.createMenu.class = function (LocalClientIndex)
	if CoD.Class.GametypeSettings == nil then
		CoD.Class.GametypeSettings = {
			teamCount = Engine.GetGametypeSetting("teamCount"),
			allowSpectating = Engine.GetGametypeSetting("allowSpectating"),
			allowInGameTeamChange = Engine.GetGametypeSetting("allowInGameTeamChange"),
			disableClassSelection = Engine.GetGametypeSetting("disableClassSelection")
		}
	end
	local ClassMenuHeader = "MPUI_PAUSE_MENU"
	if CoD.isZombie == true then
		ClassMenuHeader = "MENU_ZOMBIES_CAPS"
	end
	local IngameMenuWidget = CoD.InGameMenu.New("class", LocalClientIndex, UIExpression.ToUpper(nil, Engine.Localize(ClassMenuHeader)))
	Engine.PlaySound("uin_main_pause")
	IngameMenuWidget:addButtonPrompts()
	CoD.Class.PrepareClassButtonList(LocalClientIndex, IngameMenuWidget)
	IngameMenuWidget:registerEventHandler("open_chooseClass", CoD.Class.ChooseClassButtonPressed)
	IngameMenuWidget:registerEventHandler("open_chooseTeam", CoD.Class.ChooseTeamButtonPressed)
	IngameMenuWidget:addFriendsButton()
	IngameMenuWidget:registerEventHandler("button_prompt_friends", CoD.Class.ButtonPromptFriendsMenu)
	IngameMenuWidget:registerEventHandler("open_options", CoD.Class.OptionsButtonPressed)
	IngameMenuWidget:registerEventHandler("open_endGamePopup", CoD.Class.EndGameButtonPressed)
	-- zm_qol - the two additions' handlers. Registered unconditionally, the same
	-- way open_endGamePopup is: a handler with no button is inert, and this
	-- keeps the registration out of the isZombie branch below where the button
	-- code cannot see it.
	-- v2.2.0 - added so FAST RESTART could close the pause menu before it
	-- restarted, the way stock's own restart does. v2.2.5 took that call back
	-- out, and v2.2.6 removed the FAST RESTART row entirely, so nothing in this file
	-- fires the event any more. THE REGISTRATION STAYS: it binds a stock event
	-- name to stock's own handler, which is what stock does on every other menu
	-- that carries it, and removing it could only take away a close path some
	-- other caller expects. CoD.InGameMenu comes from the
	-- T6.HUD.InGameMenus require at the top of this file.
	-- Guarded even though it is verified present (stock ui\t6\hud\ingamemenus.lua
	-- defines CoD.InGameMenu.CloseAllInGameMenus, and Reimagined's restart popup
	-- registers this exact pair): a nil handler here would take the whole pause
	-- menu down, and losing the pause menu is far worse than losing a fade.
	if CoD.InGameMenu and CoD.InGameMenu.CloseAllInGameMenus then
		IngameMenuWidget:registerEventHandler("close_all_ingame_menus", CoD.InGameMenu.CloseAllInGameMenus)
	end
	IngameMenuWidget:registerEventHandler("zmqol_restart_game", CoD.Class.ZmQolRestartPressed)
	IngameMenuWidget:registerEventHandler("zmqol_fast_restart", CoD.Class.ZmQolFastRestartPressed)
	IngameMenuWidget:registerEventHandler("zmqol_instant_exit", CoD.Class.ZmQolInstantExitPressed)
	IngameMenuWidget:registerEventHandler("zmqol_quit_desktop", CoD.Class.ZmQolQuitToDesktopPressed)
	if CoD.isZombie == true then
		IngameMenuWidget:registerEventHandler("soloResumeGame", CoD.Class.ResumeGameButtonPressed)
	end
	local Mapname = UIExpression.TableLookup(LocalClientIndex, UIExpression.GetCurrentMapTableName(), 0, UIExpression.DvarString(nil, "mapname"), 3)
	local f13_local10 = CoD.SplitscreenScaler.new(nil, CoD.SplitscreenMultiplier)
	f13_local10:setLeftRight(false, true, 0, 0)
	f13_local10:setTopBottom(true, true, CoD.Menu.TitleHeight, -CoD.Menu.TitleHeight)
	IngameMenuWidget:addElement(f13_local10)
	if CoD.isZombie == false and not Engine.IsShoutcaster(LocalClientIndex) then
		local MapnameText = LUI.UIText.new()
		MapnameText:setLeftRight(false, true, -300, 0)
		MapnameText:setTopBottom(true, false, 0, CoD.textSize.Condensed)
		MapnameText:setFont(CoD.fonts.Condensed)
		MapnameText:setAlignment(LUI.Alignment.Left)
		MapnameText:setRGB(CoD.trueOrange.r, CoD.trueOrange.g, CoD.trueOrange.b)
		MapnameText:setText(Engine.Localize(Mapname .. "_CAPS"))
		f13_local10:addElement(MapnameText)
		local LocationText = LUI.UIText.new()
		LocationText:setLeftRight(false, true, -300, 0)
		LocationText:setTopBottom(true, false, CoD.textSize.Condensed, CoD.textSize.Condensed + CoD.textSize.Default)
		LocationText:setFont(CoD.fonts.Default)
		LocationText:setAlignment(LUI.Alignment.Left)
		LocationText:setText(Engine.Localize(Mapname .. "_LOC"))
		f13_local10:addElement(LocationText)
		CoD.Compass.AddInGameMap(f13_local10, LocalClientIndex, {
			leftAnchor = false,
			rightAnchor = true,
			left = -300,
			right = 0,
			topAnchor = true,
			bottomAnchor = false,
			top = CoD.textSize.Condensed + CoD.textSize.Default,
			bottom = CoD.textSize.Condensed + CoD.textSize.Default + 300
		})
		local f13_local15 = CoD.textSize.Condensed + CoD.textSize.Default + 300
		local GametypeText = LUI.UIText.new()
		GametypeText:setLeftRight(false, true, -300, 0)
		GametypeText:setTopBottom(true, false, f13_local15, f13_local15 + CoD.textSize.Condensed)
		GametypeText:setFont(CoD.fonts.Condensed)
		GametypeText:setAlignment(LUI.Alignment.Left)
		GametypeText:setText(UIExpression.GametypeName())
		GametypeText:setRGB(CoD.trueOrange.r, CoD.trueOrange.g, CoD.trueOrange.b)
		f13_local10:addElement(GametypeText)
		local f13_local17 = f13_local15 + CoD.textSize.Condensed
		local GametypeDescription = LUI.UIText.new()
		GametypeDescription:setLeftRight(false, true, -300, 0)
		GametypeDescription:setTopBottom(true, false, f13_local17, f13_local17 + CoD.textSize.Default)
		GametypeDescription:setFont(CoD.fonts.Default)
		GametypeDescription:setAlignment(LUI.Alignment.Left)
		GametypeDescription:setText(UIExpression.GametypeDescription())
		f13_local10:addElement(GametypeDescription)
	end
	if CoD.isZombie == false and not Engine.IsShoutcaster(LocalClientIndex) and UIExpression.IsGuest(LocalClientIndex) == 0 and Engine.GameModeIsMode(CoD.GAMEMODE_PUBLIC_MATCH) == true and CoD.CanRankUp(LocalClientIndex) == true then
		local f13_local14 = -10 - CoD.ButtonPrompt.Height
		local XPBarWidget = LUI.UIElement.new()
		XPBarWidget:setLeftRight(false, false, -(CoD.Menu.Width / 2), CoD.Menu.Width / 2)
		XPBarWidget:setTopBottom(false, true, f13_local14 - 40, f13_local14)
		IngameMenuWidget:addElement(XPBarWidget)
		local f13_local15 = LUI.UIImage.new()
		f13_local15:setLeftRight(true, true, 1, -1)
		f13_local15:setTopBottom(true, true, 1, -1)
		f13_local15:setRGB(0, 0, 0)
		f13_local15:setAlpha(0.6)
		XPBarWidget:addElement(f13_local15)
		XPBarWidget.border = CoD.Border.new(1, 1, 1, 1, 0.1)
		XPBarWidget:addElement(XPBarWidget.border)
		local XPBar = CoD.XPBar.New(nil, LocalClientIndex, CoD.Menu.Width - 20)
		XPBar:setLeftRight(true, true, 10, -10)
		XPBar:setTopBottom(true, true, 0, 0)
		XPBarWidget:addElement(XPBar)
		XPBar:processEvent({
			name = "animate_xp_bar",
			duration = 0
		})
	end
	return IngameMenuWidget
end

