-- ============================================================================
--  zm_qol: SOLO PLAY LOBBY TITLE
--
--  Stock titles this menu "CUSTOM GAMES" unconditionally, but Solo Play and
--  Custom Games are the SAME menu (PrivateOnlineGameLobby) - so entering
--  Zombies > Solo Play showed the Custom Games header.
--
--  This file is a faithful reconstruction of the stock one, verified against
--  the constant table of the shipped bytecode
--  (BO2-Raw-files\ui\t6\menus\privateonlinegamelobby.lua): require /
--  T6.Menus.PrivateGameLobby / CoD / PrivateOnlineGameLobby / LUI / createMenu /
--  New / isMultiplayer / setPreviousMenu / MainLobby / Engine / Localize /
--  MPUI_CUSTOM_GAMES_CAPS / addTitle / panelManager / panels / buttonPane /
--  titleText - in exactly that order, with nothing left over. The ONLY addition
--  is the ZMUI_SOLO_PLAY_CAPS branch. Same approach BO2-Reimagined takes in its
--  copy of this file, minus its two unrelated gameplay changes.
--
--  WHY IT IS A SEPARATE FILE, and not a patch in privategamelobby_project.lua
--  (a file this mod already owns): stock privategamelobby.lua requires
--  T6.Menus.PrivateGameLobby_Project, and this file requires
--  T6.Menus.PrivateGameLobby. So our project file runs FIRST, and anything it
--  assigned to LUI.createMenu.PrivateOnlineGameLobby would be overwritten when
--  this file loaded afterwards. The title is also applied after New() returns,
--  so no _Project hook runs late enough to change it either.
--
--  ZMUI_SOLO_PLAY_CAPS is a STOCK localize key, not one this mod has to ship -
--  Plutonium's own ui/t6/mainlobby.lua:446 uses it for the "SOLO PLAY" button
--  the user clicks to get here.
--
--  party_solo is guaranteed correct by the time this runs: this mod's own
--  CoD.MainLobby.OpenSoloLobby_Zombie sets it to 1 immediately before
--  openMenu("PrivateOnlineGameLobby"), and OpenCustomGamesLobby sets it to 0 -
--  so the Custom Games lobby keeps its own title, and Multiplayer is untouched
--  because the branch also requires CoD.isZombie.
--
--  Shipped under BOTH ui/ and ui_mp/ (identical content). T6 resolves
--  "T6.Menus.X" against both roots - stock keeps this file under ui/ and
--  privategamelobby_project.lua under ui_mp/ - and the search ORDER between
--  them has never been measured in this project. Two identical copies means
--  whichever root wins, the result is the same. require() caches by module
--  name, so only one of them is ever executed.
-- ============================================================================

require("T6.Menus.PrivateGameLobby")

CoD.PrivateOnlineGameLobby = {}

LUI.createMenu.PrivateOnlineGameLobby = function (controller)
	local menu = CoD.PrivateGameLobby.New("PrivateOnlineGameLobby", controller)

	if CoD.isMultiplayer then
		menu:setPreviousMenu("MainLobby")
	end

	local title = Engine.Localize("MPUI_CUSTOM_GAMES_CAPS")

	if CoD.isZombie and UIExpression.DvarBool(nil, "party_solo") == 1 then
		title = Engine.Localize("ZMUI_SOLO_PLAY_CAPS")
	end

	menu:addTitle(title)
	menu.panelManager.panels.buttonPane.titleText = title

	-- zm_qol: see the SOLO INTRO CUTSCENES block below. The lobby's own
	-- New() has just put the party size back to the gametype cap, so this is
	-- the first moment it can be corrected.
	zmQolForceSoloPartySize("lobby")

	-- zm_qol v1.96.0: see the INSTANT START block below.
	zmQolInstantStart()

	return menu
end


-- ============================================================================
--  zm_qol v1.96.0: INSTANT START - the Start button launches immediately.
--
--  🛑 THIS MOD HAS NEVER ACTUALLY SHIPPED INSTANT START, AND THE README SAID IT
--  DID. Reported 2026-08-16: a friend on Linux installed the v1.95.7 release and
--  got the stock five-second "match starting in" countdown in Solo Play.
--
--  🌟 THE MECHANISM, MEASURED - NOT THE ONE THIS PROJECT BELIEVED.
--  Two files on the author's own PC settle it between them:
--      players\plutonium_zm.cfg.bak-before-instantstart   (2026-07-31 04:11)
--      players\plutonium_zm.cfg                           (live)
--  and the ONLY party_* lines that differ are
--      party_gameStartTimerLengthPrivate   5 -> 0
--      party_pregameStartTimerLength       5 -> 0
--  Instant start has worked on that machine ever since, on every build, and the
--  friend - who has the mod but not that config - reports exactly FIVE seconds,
--  which is the shipped default of the first dvar. Plutonium's own
--  dvar_descriptions.json defines it as "Time in seconds before a game start
--  once enough party members are ready".
--
--  So it was never the mod: it is two archived dvars that one session set by
--  hand on ONE machine and nothing ever shipped.
--
--  🛑 THE OLD OVERRIDE IN privategamelobby_project.lua IS NOT THE FIX AND NEVER
--  WAS. CoD.PrivateGameLobby.ButtonStartGame is called by nothing in this game -
--  already established and documented at that call site, 2026-08-11. Left alone;
--  removing dead code is a separate change.
--
--  📝 party_gameStartTimerLength (the PUBLIC one) is deliberately NOT touched.
--  It is still 5 on the machine where this works, so 5 is proven compatible and
--  changing it would alter public matches for no reason.
--
--  📝 These are archived dvars, so a player who runs the mod once keeps the
--  instant start afterwards even in vanilla. That is the same state the author's
--  machine has been in since July and is the behaviour being asked for.
--
--  Called from two places for the same reason zmQolForceSoloPartySize is: the
--  lobby opening, and the last moment before the match launches.
-- ============================================================================
function zmQolInstantStart()
	local names = { "party_gameStartTimerLengthPrivate", "party_pregameStartTimerLength" }

	for i = 1, #names do
		local name = names[i]
		-- Dvar.<name>:set is the route already proven in this file
		-- (zmQolForceSoloPartySize writes party_maxplayers that way). pcall
		-- because a dvar this build does not define would otherwise index nil
		-- and hard-crash the lobby menu.
		local ok = pcall(function()
			Dvar[name]:set(0)
		end)

		if not ok then
			pcall(Engine.SetDvar, name, "0")
		end
	end
end


-- ============================================================================
--  zm_qol: SOLO INTRO CUTSCENES  (Die Rise / Mob / Buried / Origins)
--
--  ui_mp/t6/hud/loading.lua:229 plays video/<map>_load.webm only when:
--      not theater
--      AND Dvar.party_maxplayers:get() == 1
--      AND map is zm_highrise / zm_prison / zm_buried / zm_tomb
--      AND gametype == zclassic
--  Three of those already hold in solo. party_maxplayers is the one that does
--  not: it reads "4" in the dvar dump of every solo boot.
--
--  🛑 WHY v1.65.7 DID NOT WORK. It set the dvar from
--  CoD.PrivateGameLobby.ButtonStartGame, and that function is called by
--  NOTHING - the string does not occur in any stock LUI file, nor anywhere in
--  Plutonium's raw\ tree. The real handler is Button_StartMatch, wired by
--  stock privategamelobby.lua as
--      startMatchButton:registerEventHandler("button_action",
--                                            CoD.PrivateGameLobby.Button_StartMatch)
--  (read out of the shipped bytecode's constant table, in order).
--
--  🛑 AND THE DVAR IS NOT THE AUTHORITY. The same constant table shows stock
--  calling, in sequence:
--      Engine.SetGametype( ... )
--      Engine.PartySetMaxPlayerCount( CoD.Zombie.GameTypeGroups[gt].maxPlayers )
--  so the party system writes party_maxplayers back to 4 for zclassic. Setting
--  the dvar alone is fighting a mirror; PartySetMaxPlayerCount is the setter.
--  It is a genuine stock binding - stock calls it from privategamelobby.lua,
--  switchlobbies.lua, publicgamelobby.lua and selectstartloczombie.lua.
--
--  WHERE THIS HAS TO LIVE. Not privategamelobby_project.lua: that file is
--  require()d BY privategamelobby.lua, so it runs first and privategamelobby.lua
--  would overwrite any Button_StartMatch defined there. This file requires
--  privategamelobby.lua, so it runs AFTER - the wrap below is the only ordering
--  that survives. The button captures the handler when the menu is built, which
--  is later still, so it captures the wrapper.
--
--  Called from two places, because either one alone can be undone: once when
--  the lobby is created, and once from Button_StartMatch, the last point before
--  the match launches. Gated on party_solo so Custom Games keeps its own cap.
--
--  No gameplay side-effect: party_maxplayers appears NOWHERE in the 2,093-file
--  stock GSC dump. The only other LUI reader is scoreboard.lua:277, where == 1
--  leaves CoD.Zombie.SoloQuestMode true - correct for solo.
-- ============================================================================
function zmQolForceSoloPartySize(tag)
	if UIExpression.DvarBool(nil, "party_solo") ~= 1 then
		return
	end

	local before = Dvar.party_maxplayers:get()

	if Engine.PartySetMaxPlayerCount ~= nil then
		Engine.PartySetMaxPlayerCount(1)
	end

	Dvar.party_maxplayers:set(1)

	-- Probe, so a bad boot still answers the question instead of costing a
	-- blind round. quality_of_life.gsc prints this to the console at map init.
	-- pcall because creating a fresh dvar from LUI is not something this
	-- project has done before, and a raw error here would hard-crash the menu.
	pcall(Engine.SetDvar, "zmqol_loadmovie_probe",
		tag .. " solo=1"
		.. " before=" .. tostring(before)
		.. " after=" .. tostring(Dvar.party_maxplayers:get())
		.. " map=" .. tostring(Dvar.ui_mapname:get())
		.. " gt=" .. tostring(Dvar.ui_gametype:get()))
end

local zmQolStockStartMatch = CoD.PrivateGameLobby.Button_StartMatch

if zmQolStockStartMatch ~= nil then
	-- varargs: the handler's exact signature is not documented anywhere this
	-- project can read, and forwarding blind cannot get it wrong.
	CoD.PrivateGameLobby.Button_StartMatch = function (...)
		zmQolForceSoloPartySize("start")
		zmQolInstantStart()
		return zmQolStockStartMatch(...)
	end
end

-- zm_qol v1.96.0: and once at load, the earliest moment the mod can act. This
-- covers the one residual risk in the block above - that the party system reads
-- the timer length once at frontend init rather than per match. Same two dvars,
-- same call; there is no second mechanism here to confuse a bad boot with.
zmQolInstantStart()

-- optionssettings.lua can load while options.lua is still defining the stock
-- parent Options menu. This file loads afterwards, so retry once the parent
-- constructor and category builder exist.
if ZmQolInstallParentOptionsMenu then
	ZmQolInstallParentOptionsMenu()
end
