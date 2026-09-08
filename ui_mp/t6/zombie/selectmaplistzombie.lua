-- ============================================================================
--  selectmaplistzombie.lua  -  flat list menus for Zombies map / game mode
-- ----------------------------------------------------------------------------
--  Ported into zm_qol from BO2-Reimagined (ui_mp/t6/zombie/selectmaplistzombie.lua).
--
--  Replaces the globe-based map picker with two plain list popups reachable from
--  the private game lobby:
--      SelectMapListZM        - "Change Map"
--      SelectGameModeListZM   - "Change Game Mode"
--
--  Selecting a location sets BOTH ui_mapname and ui_zm_mapstartlocation, so
--  picking e.g. "DINER" switches to zm_transit and starts at the Diner.
--
--  v1.15.1: the location lists are back to vanilla. DINER is the only addition
--  the mod still makes, and scripts\zm\replaced\zm_transit_gamemodes.gsc plus
--  scripts\zm\locs\zm_transit_loc_diner.gsc are what make it playable. All the
--  other ported locations, and the custom gamemodes, were removed.
--
--  🛑 DIFFERENCE FROM REIMAGINED - read before "fixing" this:
--  Reimagined reads each location's display name out of the zm/gametypestable.csv
--  stringtable, which it ships inside its own OAT-built mod.ff. zm_qol does not
--  ship those stringtable rows, so that lookup would render every row blank. The
--  names are therefore hardcoded in the `name` field below. Do NOT swap this back
--  to UIExpression.TableLookup without also adding the stringtable rows.
--
--  (This note used to say the reason was that zm_qol "has no OpenAssetTools/
--  linker and cannot rebuild mod.ff". That is no longer true - OAT is installed
--  and build_ff.bat relinks mod.ff, see CLAUDE.md section 8. The hardcoded names
--  stay because the stringtable rows still do not exist, not because they cannot
--  be added.)
-- ============================================================================

require("T6.Lobby")
require("T6.Menus.PopupMenus")
require("T6.ListBox")

-- ============================================================================
--  🛑 v2.2.0 - DINER IS GATED ON THE MOD ACTUALLY BEING LOADED.
--  User, 2026-08-21: another mod was loaded and *"some of the stuff from my mod
--  was showing up"*. build.bat used to copy this file into Plutonium's GLOBAL
--  storage\t6\raw\ folder, which is shared by every mod and by no mod at all.
--  It no longer does - but a copy from an older build may still be sitting
--  there, so the gate below makes it behave correctly anyway.
--
--  🛑 THE REST OF THIS FILE IS DELIBERATELY NOT GATED. It is the list-style map
--  picker itself, and it REPLACED Plutonium's own copy in raw\ - for which no
--  pristine backup exists on this machine. Returning early would leave any
--  other mod with no map picker at all, which is a far worse failure than a
--  different-looking one. Only the row this project ADDS is conditional.
--
--  📝 Dvar.fs_game:get() is Plutonium's own accessor (its raw\ui\t6\mods.lua:127).
--  Fails OPEN, for the same reason as in optionssettings.lua.
-- ============================================================================
local ZmQolModLoadedHere = function ()
	local Ok, Value = pcall(function () return Dvar.fs_game:get() end)

	if not Ok or type(Value) ~= "string" then
		return true
	end

	Value = string.lower(Value)

	return Value == "mods/zm_qol" or Value == "zm_qol"
end

local ZmQolDinerAllowed = ZmQolModLoadedHere()

CoD.SelectMapListZombie = {}
CoD.SelectMapListZombie.GameModes = {}
CoD.SelectMapListZombie.GameModes[1] = {
	ui_zm_gamemodegroup = "zclassic",
	ui_gametype = "zclassic",
}
CoD.SelectMapListZombie.GameModes[2] = {
	ui_zm_gamemodegroup = "zsurvival",
	ui_gametype = "zstandard",
}
CoD.SelectMapListZombie.GameModes[3] = {
	ui_zm_gamemodegroup = "zencounter",
	ui_gametype = "zgrief",
}

CoD.SelectMapListZombie.Maps = {}
CoD.SelectMapListZombie.Maps[1] = {
	ui_mapname = "zm_transit",
	ui_zm_mapstartlocation = "transit",
}
CoD.SelectMapListZombie.Maps[2] = {
	ui_mapname = "zm_highrise",
	ui_zm_mapstartlocation = "rooftop",
}
CoD.SelectMapListZombie.Maps[3] = {
	ui_mapname = "zm_buried",
	ui_zm_mapstartlocation = "processing",
}
CoD.SelectMapListZombie.Maps[4] = {
	ui_mapname = "zm_prison",
	ui_zm_mapstartlocation = "prison",
}
CoD.SelectMapListZombie.Maps[5] = {
	ui_mapname = "zm_tomb",
	ui_zm_mapstartlocation = "tomb",
}

-- ----------------------------------------------------------------------------
--  🛑 SURVIVAL AND GRIEF HAVE DIFFERENT LOCATION LISTS IN THE VANILLA GAME.
--
--  This used to be ONE flat table shared by both modes, which is why Borough and
--  Cell Block showed up when picking a Survival map. They are not survival
--  locations - vanilla offers them in Grief only - so a single list is wrong in
--  both directions: it puts grief-only arenas in the survival picker, and
--  deleting them outright would take them out of Grief, where they belong.
--
--  Vanilla, exactly:
--      Survival : Bus Depot, Farm, Town, Nuketown
--      Grief    : Bus Depot, Farm, Town, Borough, Cell Block
--
--  DINER is the single addition this mod makes, and it appears in both. Stock
--  registers Diner for NEITHER mode (verified against the stock
--  zm_transit_gamemodes dump, which has only transit/farm/town on each), so its
--  grief entry is an addition here too, not a vanilla one.
-- ----------------------------------------------------------------------------
--  🛑 v2.2.0 - built by APPEND rather than by fixed index, so the two DINER
--  rows can be left out without leaving a hole in the array. Everything else is
--  vanilla and is listed in vanilla order.
local ZmQolAddLoc = function (List, MapName, StartLocation, DisplayName)
	List[#List + 1] = {
		ui_mapname = MapName,
		ui_zm_mapstartlocation = StartLocation,
		name = DisplayName,
	}
end

CoD.SelectMapListZombie.Locations = {}
ZmQolAddLoc(CoD.SelectMapListZombie.Locations, "zm_nuked",   "nuked",   "NUKETOWN")
ZmQolAddLoc(CoD.SelectMapListZombie.Locations, "zm_transit", "transit", "BUS DEPOT")
if ZmQolDinerAllowed then
	ZmQolAddLoc(CoD.SelectMapListZombie.Locations, "zm_transit", "diner", "DINER")   -- added by this mod
end
ZmQolAddLoc(CoD.SelectMapListZombie.Locations, "zm_transit", "farm",    "FARM")
ZmQolAddLoc(CoD.SelectMapListZombie.Locations, "zm_transit", "town",    "TOWN")
-- Restored survival locations (2026-09-02, user request). Same gate as Diner:
-- server-side registration only exists when this mod is loaded, and offering a
-- location the server does not register would hang the lobby at launch.
if ZmQolDinerAllowed then
	ZmQolAddLoc(CoD.SelectMapListZombie.Locations, "zm_transit",  "power",          "POWER STATION")   -- added by this mod
	ZmQolAddLoc(CoD.SelectMapListZombie.Locations, "zm_transit",  "tunnel",         "TUNNEL")          -- added by this mod (back in v2.14.30)
	ZmQolAddLoc(CoD.SelectMapListZombie.Locations, "zm_highrise", "shopping_mall",  "SHOPPING MALL")   -- added by this mod
	ZmQolAddLoc(CoD.SelectMapListZombie.Locations, "zm_highrise", "dragon_rooftop", "DRAGON ROOFTOP")  -- added by this mod
	ZmQolAddLoc(CoD.SelectMapListZombie.Locations, "zm_highrise", "sweatshop",      "SWEATSHOP")       -- added by this mod
	ZmQolAddLoc(CoD.SelectMapListZombie.Locations, "zm_buried",   "street",         "BOROUGH")         -- added by this mod
	ZmQolAddLoc(CoD.SelectMapListZombie.Locations, "zm_prison",   "cellblock",      "CELL BLOCK")      -- added by this mod
	-- v2.14.0: Origins survival (Tunnel went out in the same change and came
	-- back in v2.14.30, both at the user's request). The server half is
	-- scripts/zm/replaced/zm_tomb_gamemodes.gsc, which registers crazy_place on
	-- zstandard and zgrief.
	ZmQolAddLoc(CoD.SelectMapListZombie.Locations, "zm_tomb",     "crazy_place",    "THE CRAZY PLACE") -- added by this mod
end

CoD.SelectMapListZombie.GriefLocations = {}
ZmQolAddLoc(CoD.SelectMapListZombie.GriefLocations, "zm_transit", "transit", "BUS DEPOT")
if ZmQolDinerAllowed then
	ZmQolAddLoc(CoD.SelectMapListZombie.GriefLocations, "zm_transit", "diner", "DINER")   -- added by this mod
end
ZmQolAddLoc(CoD.SelectMapListZombie.GriefLocations, "zm_transit", "farm",      "FARM")
ZmQolAddLoc(CoD.SelectMapListZombie.GriefLocations, "zm_transit", "town",      "TOWN")
ZmQolAddLoc(CoD.SelectMapListZombie.GriefLocations, "zm_buried",  "street",    "BOROUGH")
ZmQolAddLoc(CoD.SelectMapListZombie.GriefLocations, "zm_prison",  "cellblock", "CELL BLOCK")

-- Which list a non-classic mode uses. Grief gets its own; anything else
-- (Survival) gets the survival list.
CoD.SelectMapListZombie.GetLocations = function(gametype)
	if gametype == "zgrief" then
		return CoD.SelectMapListZombie.GriefLocations
	end

	return CoD.SelectMapListZombie.Locations
end

CoD.SelectMapListZombie.GetKeyValueIndex = function(table, key, value)
	for i, v in ipairs(table) do
		if v[key] == value then
			return i
		end
	end

	return 1
end

local function gameModeListSelectionClickedEventHandler(self, event)
	local index = self.listBox:getFocussedIndex()

	if index ~= nil then
		local prevTeamCount = Engine.GetGametypeSetting("teamCount")

		local gameTable = CoD.SelectMapListZombie.GameModes

		Engine.SetDvar("ui_zm_gamemodegroup", gameTable[index].ui_zm_gamemodegroup)
		Engine.SetGametype(gameTable[index].ui_gametype)

		if gameTable[index].ui_zm_gamemodegroup ~= "zencounter" then
			Engine.SetDvar("ui_gametype_pro", 0)
		end

		-- zm_qol: same nil-`controller` bug as in the map handler below. Read the current
		-- map/location from the dvars, which are always set, instead of parsing a profile
		-- string fetched with a nil controller. GetKeyValueIndex already falls back to 1.
		local map = UIExpression.DvarString(nil, "ui_mapname")
		local location = UIExpression.DvarString(nil, "ui_zm_mapstartlocation")
		local mapTable = {}
		local mapIndex = 1

		if gameTable[index].ui_gametype == "zclassic" then
			mapTable = CoD.SelectMapListZombie.Maps
			mapIndex = CoD.SelectMapListZombie.GetKeyValueIndex(mapTable, "ui_mapname", map)
		else
			-- Uses the gametype being switched TO, not the current dvar - this runs
			-- while changing mode, so the dvar is still the old one.
			mapTable = CoD.SelectMapListZombie.GetLocations(gameTable[index].ui_gametype)
			mapIndex = CoD.SelectMapListZombie.GetKeyValueIndex(mapTable, "ui_zm_mapstartlocation", location)
		end

		Engine.SetDvar("ui_mapname", mapTable[mapIndex].ui_mapname)
		Engine.SetDvar("ui_zm_mapstartlocation", mapTable[mapIndex].ui_zm_mapstartlocation)

		-- zm_qol: keep the profile map/location pair in sync with the dvars we just set,
		-- otherwise the match start re-reads a stale pair from the profile.
		Engine.SetProfileVar(self.controller, CoD.profileKey_map,
			mapTable[mapIndex].ui_mapname .. " " .. mapTable[mapIndex].ui_zm_mapstartlocation)

		Engine.SetProfileVar(self.controller, CoD.profileKey_gametype, gameTable[index].ui_gametype)

		Engine.CommitProfileChanges(self.controller)

		local currTeamCount = Engine.GetGametypeSetting("teamCount")

		if currTeamCount ~= prevTeamCount then
			Engine.PartyHostReassignTeams()
		end
	end

	Engine.PartyHostClearUIState()

	self.occludedMenu:swapMenu("PrivateOnlineGameLobby", self.controller)
	self:goBack(self.controller)
end

local function gameModeListCreateButtonMutables(controller, mutables)
	local text = LUI.UIText.new()
	text:setLeftRight(true, false, 2, 2)
	text:setTopBottom(true, true, 0, 0)
	text:setRGB(1, 1, 1)
	text:setAlpha(1)
	mutables:addElement(text)
	mutables.text = text
end

local function gameModeListGetButtonData(controller, index, mutables, self)
	if CoD.SelectMapListZombie.GameModes[index].ui_gametype == "zclassic" then
		mutables.text:setText(UIExpression.ToUpper(nil, Engine.Localize("MPUI_ZCLASSIC")))
	else
		mutables.text:setText(Engine.Localize(UIExpression.TableLookup(nil, CoD.gametypesTable, 0, 0, 1, CoD.SelectMapListZombie.GameModes[index].ui_gametype, 2)))
	end
end

function LUI.createMenu.SelectGameModeListZM(controller)
	local self = CoD.Menu.New("SelectGameModeListZM")
	self.controller = controller

	self:addLargePopupBackground()
	self:addSelectButton()
	self:addBackButton()

	self:addTitle(Engine.Localize("MPUI_CHANGE_GAME_MODE_CAPS"))

	local listBox = CoD.ListBox.new(nil, controller, 15, CoD.CoD9Button.Height, 250, gameModeListCreateButtonMutables, gameModeListGetButtonData, 5, 0)
	listBox:setLeftRight(true, false, 0, 250)
	listBox:setTopBottom(true, false, 75, 75 + 530)
	listBox:addScrollBar()

	local index = CoD.SelectMapListZombie.GetKeyValueIndex(CoD.SelectMapListZombie.GameModes, "ui_gametype", UIExpression.DvarString(nil, "ui_gametype"))

	if UIExpression.DvarBool(nil, "party_solo") == 1 then
		listBox:setTotalItems(2, index)
	else
		listBox:setTotalItems(#CoD.SelectMapListZombie.GameModes, index)
	end

	self:addElement(listBox)
	self.listBox = listBox

	self:registerEventHandler("click", gameModeListSelectionClickedEventHandler)

	return self
end

local function mapListSelectionClickedEventHandler(self, event)
	local index = self.listBox:getFocussedIndex()

	if index ~= nil then
		local mapTable = CoD.SelectMapListZombie.Maps

		if UIExpression.DvarString(nil, "ui_gametype") ~= "zclassic" then
			mapTable = CoD.SelectMapListZombie.GetLocations(UIExpression.DvarString(nil, "ui_gametype"))
		end

		Engine.SetDvar("ui_mapname", mapTable[index].ui_mapname)
		Engine.SetDvar("ui_zm_mapstartlocation", mapTable[index].ui_zm_mapstartlocation)

		-- 🛑 zm_qol FIX. Reimagined's original wrote the profile as
		--     <map parsed from the OLD profile value> .. " " .. <new location>
		-- using a bare `controller`, which is not a local here and is nil - so
		-- ProfileValueAsString returned nothing, string.match produced nil, and the
		-- write either errored or stored a stale/mismatched pair. The game re-reads
		-- ui_zm_mapstartlocation from this profile value at match start, which is why
		-- picking Diner still loaded Town (console log: "location=town").
		--
		-- Both halves now come from the selected row, so map and location can never
		-- disagree and the selection always survives to the match.
		Engine.SetProfileVar(self.controller, CoD.profileKey_map,
			mapTable[index].ui_mapname .. " " .. mapTable[index].ui_zm_mapstartlocation)

		Engine.CommitProfileChanges(self.controller)
	end

	Engine.PartyHostClearUIState()

	self.occludedMenu:swapMenu("PrivateOnlineGameLobby", self.controller)
	self:goBack(self.controller)
end

local function mapListCreateButtonMutables(controller, mutables)
	local text = LUI.UIText.new()
	text:setLeftRight(true, false, 2, 2)
	text:setTopBottom(true, true, 0, 0)
	text:setRGB(1, 1, 1)
	text:setAlpha(1)
	mutables:addElement(text)
	mutables.text = text
end

local function mapListGetButtonData(controller, index, mutables, self)
	if UIExpression.DvarString(nil, "ui_gametype") == "zclassic" then
		mutables.text:setText(CoD.GetZombieGameTypeDescription(CoD.Zombie.GAMETYPE_ZCLASSIC, CoD.SelectMapListZombie.Maps[index].ui_mapname))
	else
		-- Hardcoded name, not a stringtable lookup - see the header note.
		mutables.text:setText(CoD.SelectMapListZombie.GetLocations(UIExpression.DvarString(nil, "ui_gametype"))[index].name)
	end
end

function LUI.createMenu.SelectMapListZM(controller)
	local self = CoD.Menu.New("SelectMapListZM")
	self.controller = controller

	self:addLargePopupBackground()
	self:addSelectButton()
	self:addBackButton()

	self:addTitle(Engine.Localize("MPUI_CHANGE_MAP_CAPS"))

	local listBox = CoD.ListBox.new(nil, controller, 15, CoD.CoD9Button.Height, 250, mapListCreateButtonMutables, mapListGetButtonData, 5, 0)
	listBox:setLeftRight(true, false, 0, 250)
	listBox:setTopBottom(true, false, 75, 75 + 530)
	listBox:addScrollBar()

	if UIExpression.DvarString(nil, "ui_gametype") == "zclassic" then
		local index = CoD.SelectMapListZombie.GetKeyValueIndex(CoD.SelectMapListZombie.Maps, "ui_mapname", UIExpression.DvarString(nil, "ui_mapname"))
		listBox:setTotalItems(#CoD.SelectMapListZombie.Maps, index)
	else
		local locTable = CoD.SelectMapListZombie.GetLocations(UIExpression.DvarString(nil, "ui_gametype"))
		local index = CoD.SelectMapListZombie.GetKeyValueIndex(locTable, "ui_zm_mapstartlocation", UIExpression.DvarString(nil, "ui_zm_mapstartlocation"))
		listBox:setTotalItems(#locTable, index)
	end

	self:addElement(listBox)
	self.listBox = listBox

	self:registerEventHandler("click", mapListSelectionClickedEventHandler)

	return self
end
