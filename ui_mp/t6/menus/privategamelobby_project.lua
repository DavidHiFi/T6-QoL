-- ============================================================================
--  🛑 zm_qol v2.2.0 - THIS MOD'S LOBBY ROWS ARE GATED ON THE MOD BEING LOADED.
--  User, 2026-08-21: another mod was loaded and *"some of the stuff from my mod
--  was showing up"*, and it survived removing zm_qol with the installer.
--  build.bat used to copy this file into Plutonium's GLOBAL storage\t6\raw\
--  folder, which every mod - and no mod - reads. It no longer does, but a copy
--  from an older build may still be there, so the gate makes such a copy behave
--  like Plutonium's own file.
--
--  📝 Dvar.fs_game:get() is Plutonium's own accessor for this, used verbatim in
--  its shipped raw\ui\t6\mods.lua:127. It fails OPEN - a read that throws shows
--  the rows - because a lobby that silently lost its rows would be worse.
-- ============================================================================
function ZmQolLobbyModLoaded()
	local Ok, Value = pcall(function () return Dvar.fs_game:get() end)

	if not Ok or type(Value) ~= "string" then
		return true
	end

	Value = string.lower(Value)

	return Value == "mods/zm_qol" or Value == "zm_qol"
end

-- ============================================================================
--  zm_qol v2.1.3 - THE NUKETOWN SURVIVAL MAP PREVIEW, SIZED TO FIT
--
--  User, 2026-08-21, with a screenshot: *"the hellhounds option is here for
--  nuketown now, but it caused the preview image to be overlapped/colliding
--  like adding options to the pre-game lobby has done in the past, so fix
--  that."*
--
--  🛑 THE v2.1.0 FIX FOR THIS DID NOTHING, AND THE REASON IS IN THE STOCK
--  WIDGET'S OWN SOURCE. It shrank the preview by passing a shorter box to
--  mapInfoImage:setTopBottom(). CoD.MapInfoImage.new (patch_zm/ui/t6/
--  mapinfoimage.lua) builds every visible part of the panel anchored to the
--  WIDGET'S BOTTOM EDGE at fixed offsets:
--
--        picture   bottom -57 - MapImageHeight .. -57      (136 tall)
--        frame     bottom -57 - MapImageHeight .. -11      (182 tall on ZM)
--        captions  bottom -25 and -42, right-aligned to MapImageWidth - 20
--
--  Nothing in there reads the widget's height, so the box can be any size at
--  all and the panel drawn inside it never changes. Only `bottom` moves it.
--  That is why the v2.1.0 screen still measures 182 units tall.
--
--  🌟 THE MODEL IS NOW EXACT, AND IT IS BACKED BY TWO INDEPENDENT MEASUREMENTS.
--  Screen position of the visible frame, from the value passed as `bottom`:
--
--        frame top    = 37 + bottom - 57 - MapImageHeight
--        frame bottom = 37 + bottom - 11
--
--  The 37 is the button pane's own top, and it is not a new guess: the v1.99.28
--  note below records asking for bottom 640 and measuring a frame top of 484.5,
--  which gives 37. Checked against the user's 2026-08-21 screenshot (2560x1440,
--  2 px per LUI unit) on the shipped bottom of 635: predicted 479, measured 478.
--
--  🛑 SO THE PANEL CANNOT BE MOVED OUT OF THE WAY - only shrunk. Every number
--  below is a text-band scan of that screenshot, not an estimate:
--
--        rows        dead-even 32-unit pitch, 12 of them, 90 .. 442
--                    (HELLHOUNDS is the 9th; the scan reads it at 346 only on a
--                     lower brightness threshold because it is the orange
--                     selected row)
--        hint        474 .. 488   - one full pitch below the last row
--        frame       478 .. 658   - and 37 + 635 - 57 - 136 = 479 predicts the
--                                   top to within one unit, so the model holds
--        ESC Back    663 .. 679
--
--  The hint therefore ends at 488 and the frame starts at 478: the panel is
--  drawn OVER the hint line by 10 units, which is the collision. The band left
--  between hint and ESC is 175 units and the frame is 182 tall, so it does not
--  fit there either, and moving it down puts it through ESC Back - the exact
--  v1.99.28 failure this file already records.
--
--  🌟 SO THE PICTURE ITSELF GETS SMALLER, ON THIS ONE SCREEN ONLY, and the
--  bottom edge does not move at all - the clearance to ESC Back stays exactly
--  what ships today. MapImageHeight 136 -> 112 raises the frame's top by 24:
--
--        frame top    502   (14 units clear of the hint, better than the 8.7
--                            this file has used since v1.99.29)
--        frame bottom 658   (unchanged, 5 units clear of ESC Back)
--
--  MapImageWidth goes 294 -> 242 with it so the picture keeps its aspect
--  (294/136 = 2.162, 242/112 = 2.161). The caption plate is a fixed 46 units
--  and is anchored to the bottom, so the map name and mode stay exactly where
--  and how big they are now.
--
--  📝 THE COST, STATED PLAINLY: the Nuketown survival preview is ~18% smaller
--  in each direction than on every other screen. With twelve rows there is no
--  arrangement in which it is not, short of dropping a row or moving the panel
--  to the empty right-hand half of the lobby, which is a different design and
--  was not asked for.
--
--  🛑 WHY A WRAPPER AND NOT A WRITE TO THE CONSTANTS. They are module-level and
--  shared with every other lobby that builds a MapInfoImage (privatelocalgame-
--  lobby, playermatchpartylobby, theaterlobby, mapvoter). Setting them from
--  PopulateButtons_Project would leave them shrunk for whatever screen came
--  next. Inside the wrapper they are shrunk for exactly the duration of one
--  constructor call and restored immediately, whoever the caller is.
-- ============================================================================
--  🛑 THE nil GUARD IS NOT DEFENSIVE PADDING - IT MUST PASS, AND IT DOES.
--  Stock's privategamelobby.lua does require("T6.MapInfoImage") on line 3 and
--  require("T6.Menus.PrivateGameLobby_Project") - this file - on line 13, so
--  CoD.MapInfoImage is fully built by the time these lines run. Read out of the
--  decompiled patch_ui_zm copy, not assumed. If that ever stops being true the
--  wrapper no-ops and the preview goes back to its stock size, which is the
--  right way round to fail.
if CoD.MapInfoImage ~= nil and CoD.MapInfoImage.ZmQolSizeWrapped ~= true then
	CoD.MapInfoImage.ZmQolSizeWrapped = true
	CoD.MapInfoImage.ZmQolStockWidth  = CoD.MapInfoImage.MapImageWidth
	CoD.MapInfoImage.ZmQolStockHeight = CoD.MapInfoImage.MapImageHeight

	local ZmQolStockMapInfoImageNew = CoD.MapInfoImage.new

	CoD.MapInfoImage.new = function (Properties)
		local Width  = CoD.MapInfoImage.ZmQolStockWidth
		local Height = CoD.MapInfoImage.ZmQolStockHeight

		--  🛑 v2.3.4 - THE zm_nuked SPECIAL CASE IS GONE, AND WITH IT THE pcall
		--  THAT USED TO READ ui_mapname/ui_zm_gamemodegroup HERE. It existed only to
		--  shrink this panel for the nine-row lobby the (now removed) Nuketown
		--  hellhound row caused - see that removal's own comment two sections
		--  up. Nuketown survival is an eight-row lobby again, same as every
		--  other survival location, so it now uses the same stock-sized panel
		--  as all of them. Width/Height are left at ZmQolStockWidth/Height
		--  unconditionally - no pcall body needed for a check that no longer
		--  has anything to check.

		CoD.MapInfoImage.MapImageWidth  = Width
		CoD.MapInfoImage.MapImageHeight = Height

		--  🛑 THE RESTORE MUST HAPPEN EVEN IF THE CONSTRUCTOR THROWS. Lua has no
		--  finally, and leaving the shrunk numbers in place would carry them into
		--  the next lobby built in this session - a fault that would look like it
		--  came from somewhere else entirely. pcall, restore, then re-raise.
		local Ok, Widget = pcall(ZmQolStockMapInfoImageNew, Properties)

		CoD.MapInfoImage.MapImageWidth  = CoD.MapInfoImage.ZmQolStockWidth
		CoD.MapInfoImage.MapImageHeight = CoD.MapInfoImage.ZmQolStockHeight

		if not Ok then
			error(Widget, 0)
		end

		return Widget
	end
end

-- ============================================================================
--  zm_qol v2.10.2 - THE LOBBY PREVIEW CAPTION FOR THE RESTORED LOCATIONS.
--
--  User, 2026-09-02, with a screenshot of the solo lobby reading
--  "GREEN RUN" / " / SURVIVAL" for a restored location: *"the names are
--  missing from the previews in the lobby ... it says the specific name of the
--  map"*.
--
--  Stock CoD.MapInfoImage.ZombieUpdate (ui/t6/mapinfoimage.lua) builds the
--  small caption as <location> .. " / " .. <gametype>, taking <location> from
--  zm/gametypestable.csv section 5 (column 3 = ui_zm_mapstartlocation, column
--  4 = the ALL CAPS localize key - the diner row is
--  5,6,zm_transit,diner,ZMUI_DINER_CAPS,...). power, crazy_place and the three
--  Die Rise locations have NO row in the stock table (dumped 2026-09-02), so the
--  lookup hands back "" and the caption comes out " / SURVIVAL". The big
--  "GREEN RUN" line is the MAP name and is correct - stock's own Diner reads
--  "GREEN RUN" over "DINER / SURVIVAL", which is the shape restored here.
--
--  Same fix shape as loading.lua's GetZMLoadingMapName and scoreboard.lua's
--  GetMapDisplayName: a Lua table for the rows stock lacks, consulted ONLY
--  when the stock lookup fails, so any location stock does know keeps its
--  stock string. BO2-Reimagined solves it by shipping its own
--  gametypestable.csv + localize asset; owning that whole stringtable in
--  mod.ff would override every gametype row on every map, which is why this
--  mod keeps to the Lua route.
--
--  The preview IMAGE is untouched: the menu_/loadscreen_ material pair for
--  every added location is in mod.ff (Unlinker --list) with the same images
--  Reimagined uses for them (Die Rise trio = the rooftop picture, The Crazy
--  Place = Origins' own survival/loadscreen art).
-- ============================================================================
if CoD.MapInfoImage ~= nil and CoD.MapInfoImage.ZombieUpdate ~= nil and CoD.MapInfoImage.ZmQolCaptionWrapped ~= true then
	CoD.MapInfoImage.ZmQolCaptionWrapped = true

	local ZmQolStockZombieUpdate = CoD.MapInfoImage.ZombieUpdate

	-- ALL CAPS, because stock's column-4 keys are the _CAPS strings.
	local ZmQolLocationCaptions = {
		power          = "POWER STATION",
		shopping_mall  = "SHOPPING MALL",
		dragon_rooftop = "DRAGON ROOFTOP",
		sweatshop      = "SWEATSHOP",
		crazy_place    = "THE CRAZY PLACE",
		diner          = "DINER",
		cellblock      = "CELL BLOCK",
		street         = "BOROUGH",
	}

	CoD.MapInfoImage.ZombieUpdate = function (Widget, MapName, GameType)
		ZmQolStockZombieUpdate(Widget, MapName, GameType)

		pcall(function ()
			if not ZmQolLobbyModLoaded() then
				return
			end
			if GameType == nil or GameType == CoD.Zombie.GAMETYPE_ZCLASSIC then
				return
			end
			-- Stock blanks the whole panel while a non-host is watching the
			-- host pick, and in Theater with no film; leave those alone.
			if Engine.GameModeIsMode(CoD.GAMEMODE_THEATER) == true and UIExpression.DvarString(Widget.controller, "ui_demoname") == "" then
				return
			end
			local Location = UIExpression.DvarString(nil, "ui_zm_mapstartlocation")
			if Location == nil or Location == "" then
				return
			end
			local HostState = Engine.PartyGetHostUIState()
			if (HostState == CoD.PARTYHOST_STATE_SELECTING_GAMETYPE or HostState == CoD.PARTYHOST_STATE_SELECTING_MAP) and UIExpression.GameHost(Widget.controller) ~= 1 then
				return
			end

			-- Did stock resolve a name? Then it is already on screen.
			local Key = UIExpression.TableLookup(nil, CoD.gametypesTable, 0, 5, 3, Location, 4)
			if Key ~= nil and Key ~= "" then
				local StockName = Engine.Localize(Key)
				if StockName ~= nil and StockName ~= "" and string.match(StockName, Key) == nil then
					return
				end
			end

			local Caption = ZmQolLocationCaptions[Location]
			if Caption == nil then
				return
			end

			local Description = CoD.GetZombieGameTypeDescription(GameType, CoD.Zombie.GetUIMapName())
			if Description ~= nil and Description ~= "" then
				Widget.gameTypeText:setText(Caption .. " / " .. Description)
			else
				Widget.gameTypeText:setText(Caption)
			end
		end)
	end
end

CoD.PrivateGameLobby.GameTypeSettings = {}
CoD.PrivateGameLobby.GameTypeSettings[1] = {}
CoD.PrivateGameLobby.GameTypeSettings[1].id = "zmDifficulty"
CoD.PrivateGameLobby.GameTypeSettings[1].name = "ZMUI_DIFFICULTY_CAPS"
CoD.PrivateGameLobby.GameTypeSettings[1].hintText = "ZMUI_DIFFICULTY_DESC"
CoD.PrivateGameLobby.GameTypeSettings[1].labels = {}
CoD.PrivateGameLobby.GameTypeSettings[1].labels[1] =  "ZMUI_DIFFICULTY_EASY_CAPS"
CoD.PrivateGameLobby.GameTypeSettings[1].labels[2] =  "ZMUI_DIFFICULTY_NORMAL_CAPS"
CoD.PrivateGameLobby.GameTypeSettings[1].values = {}
CoD.PrivateGameLobby.GameTypeSettings[1].values[1] = 0
CoD.PrivateGameLobby.GameTypeSettings[1].values[2] = 1
CoD.PrivateGameLobby.GameTypeSettings[1].gameTypes = {}
CoD.PrivateGameLobby.GameTypeSettings[1].gameTypes[1] = "zclassic"
CoD.PrivateGameLobby.GameTypeSettings[1].gameTypes[2] = "zstandard"
CoD.PrivateGameLobby.GameTypeSettings[1].gameTypes[3] = "zgrief"
CoD.PrivateGameLobby.GameTypeSettings[2] = {}
CoD.PrivateGameLobby.GameTypeSettings[2].id = "startRound"
CoD.PrivateGameLobby.GameTypeSettings[2].name = "ZMUI_STARTING_ROUND_CAPS"
CoD.PrivateGameLobby.GameTypeSettings[2].hintText = "ZMUI_STARTING_ROUND_DESC"
CoD.PrivateGameLobby.GameTypeSettings[2].labels = {}
CoD.PrivateGameLobby.GameTypeSettings[2].labels[1] = "1"
CoD.PrivateGameLobby.GameTypeSettings[2].labels[2] = "5"
CoD.PrivateGameLobby.GameTypeSettings[2].labels[3] = "10"
CoD.PrivateGameLobby.GameTypeSettings[2].labels[4] = "15"
CoD.PrivateGameLobby.GameTypeSettings[2].labels[5] = "20"
CoD.PrivateGameLobby.GameTypeSettings[2].labels[6] = "25"
CoD.PrivateGameLobby.GameTypeSettings[2].labels[7] = "30"
CoD.PrivateGameLobby.GameTypeSettings[2].values = {}
CoD.PrivateGameLobby.GameTypeSettings[2].values[1] = 1
CoD.PrivateGameLobby.GameTypeSettings[2].values[2] = 5
CoD.PrivateGameLobby.GameTypeSettings[2].values[3] = 10
CoD.PrivateGameLobby.GameTypeSettings[2].values[4] = 15
CoD.PrivateGameLobby.GameTypeSettings[2].values[5] = 20
CoD.PrivateGameLobby.GameTypeSettings[2].values[6] = 25
CoD.PrivateGameLobby.GameTypeSettings[2].values[7] = 30
CoD.PrivateGameLobby.GameTypeSettings[2].gameTypes = {}
CoD.PrivateGameLobby.GameTypeSettings[2].gameTypes[1] = "zclassic"
CoD.PrivateGameLobby.GameTypeSettings[2].gameTypes[2] = "zstandard"
CoD.PrivateGameLobby.GameTypeSettings[2].gameTypes[3] = "zgrief"
CoD.PrivateGameLobby.GameTypeSettings[3] = {}
CoD.PrivateGameLobby.GameTypeSettings[3].id = "magic"
CoD.PrivateGameLobby.GameTypeSettings[3].name = "ZMUI_MAGIC_CAPS"
CoD.PrivateGameLobby.GameTypeSettings[3].hintText = "ZMUI_MAGIC_DESC"
CoD.PrivateGameLobby.GameTypeSettings[3].labels = {}
CoD.PrivateGameLobby.GameTypeSettings[3].labels[1] = "MENU_ENABLED_CAPS"
CoD.PrivateGameLobby.GameTypeSettings[3].labels[2] = "MENU_DISABLED_CAPS"
CoD.PrivateGameLobby.GameTypeSettings[3].values = {}
CoD.PrivateGameLobby.GameTypeSettings[3].values[1] = 1
CoD.PrivateGameLobby.GameTypeSettings[3].values[2] = 0
CoD.PrivateGameLobby.GameTypeSettings[3].gameTypes = {}
CoD.PrivateGameLobby.GameTypeSettings[3].gameTypes[1] = "zstandard"
CoD.PrivateGameLobby.GameTypeSettings[3].gameTypes[2] = "zgrief"
CoD.PrivateGameLobby.GameTypeSettings[4] = {}
CoD.PrivateGameLobby.GameTypeSettings[4].id = "headshotsonly"
CoD.PrivateGameLobby.GameTypeSettings[4].name = "ZMUI_HEADSHOTS_ONLY_CAPS"
CoD.PrivateGameLobby.GameTypeSettings[4].hintText = "ZMUI_HEADSHOTS_ONLY_DESC"
CoD.PrivateGameLobby.GameTypeSettings[4].labels = {}
CoD.PrivateGameLobby.GameTypeSettings[4].labels[1] = "MENU_DISABLED_CAPS"
CoD.PrivateGameLobby.GameTypeSettings[4].labels[2] = "MENU_ENABLED_CAPS"
CoD.PrivateGameLobby.GameTypeSettings[4].values = {}
CoD.PrivateGameLobby.GameTypeSettings[4].values[1] = 0
CoD.PrivateGameLobby.GameTypeSettings[4].values[2] = 1
CoD.PrivateGameLobby.GameTypeSettings[4].gameTypes = {}
CoD.PrivateGameLobby.GameTypeSettings[4].gameTypes[1] = "zclassic"
CoD.PrivateGameLobby.GameTypeSettings[4].gameTypes[2] = "zstandard"
CoD.PrivateGameLobby.GameTypeSettings[4].gameTypes[3] = "zgrief"
CoD.PrivateGameLobby.GameTypeSettings[5] = {}
CoD.PrivateGameLobby.GameTypeSettings[5].id = "allowdogs"
CoD.PrivateGameLobby.GameTypeSettings[5].name = "ZMUI_DOGS_CAPS"
CoD.PrivateGameLobby.GameTypeSettings[5].hintText = "ZMUI_DOGS_DESC"
CoD.PrivateGameLobby.GameTypeSettings[5].labels = {}
CoD.PrivateGameLobby.GameTypeSettings[5].labels[1] = "MENU_DISABLED_CAPS"
CoD.PrivateGameLobby.GameTypeSettings[5].labels[2] = "MENU_ENABLED_CAPS"
CoD.PrivateGameLobby.GameTypeSettings[5].values = {}
CoD.PrivateGameLobby.GameTypeSettings[5].values[1] = 0
CoD.PrivateGameLobby.GameTypeSettings[5].values[2] = 1
CoD.PrivateGameLobby.GameTypeSettings[5].gameTypes = {}
CoD.PrivateGameLobby.GameTypeSettings[5].gameTypes[1] = "zstandard"
CoD.PrivateGameLobby.GameTypeSettings[5].maps = {}
CoD.PrivateGameLobby.GameTypeSettings[5].maps[1] = "zm_transit"
-- ===========================================================================
--  zm_qol v2.1.0 - HELLHOUNDS ON NUKETOWN SURVIVAL.  User, 2026-08-21:
--  *"add hellhounds as a pre-game option for nuketown survival as well ...
--  and of course make sure the hell hound spawns are proper/normal inside the
--  actual playable map, not in areas where the player can't even access."*
--
--  🌟 TREYARCH ALREADY WIRED THE WHOLE SERVER HALF AND JUST NEVER SHOWED THE
--  ROW - the same shape as the survival locations this mod already ports.
--  Nuketown's own gametype script does all of it:
--        zm_nuked\maps\mp\gametypes_zm\zstandard.gsc:26
--            maps\mp\zombies\_zm_ai_dogs::init();
--        :39   level.dog_rounds_allowed = getgametypesetting( "allowdogs" );
--        :41-42  if ( level.dog_rounds_allowed )
--                    maps\mp\zombies\_zm_ai_dogs::enable_dog_rounds();
--  Byte for byte what TranZit, Die Rise, Mob, Buried and Origins run. The ONLY
--  thing that hid it was this whitelist, which stock left at zm_transit alone.
--  So this is one line, and no GSC changes at all.
--
--  🌟 THE SPAWNS ARE STOCK'S OWN AND THEY ARE IN THE PLAYABLE MAP - measured,
--  not assumed. `Unlinker --include-assets mapents` on zm_nuked.ff finds 29
--  script_structs tagged dog_location across 12 zones - both houses, both
--  backyards, all four alleys, the garage, both cul-de-sacs, the start and the
--  truck - every one at z -32..-34, the map's ground plane, spanning
--  x -1976..1688 and y -426..1064. Nuketown survival plays the WHOLE map
--  rather than a carved-out arena, so unlike the Diner there is no out-of-
--  bounds zone for a dog to land in. Nothing was moved or disabled.
--
--  🛑 REMOVED v2.3.4. User, 2026-08-25: *"because of how much of a hassle it's
--  been to get hellhounds working on Diner survival, and Nuketown survival,
--  just drop it at this point"*. This is the mod-only Nuketown addition
--  above (added v2.1.0, made the row conditional on ZmQolLobbyModLoaded()
--  since v2.2.0) - `maps[1] = "zm_transit"` two blocks up is STOCK's own row
--  and stays untouched, so Bus Depot / Farm / Town keep hellhounds exactly as
--  they always have.
--
--  🛑 THE TWO PANEL-SIZE COMPENSATIONS THIS ROW NEEDED ARE ALSO REVERTED, IN
--  THE SAME EDIT. They existed only because this row made Nuketown survival a
--  nine-row lobby - the `Mapname == "zm_nuked" and ModeGrp == "zsurvival"`
--  special cases in CoD.MapInfoImage.new (top of this file) and in the
--  zmqol_lobby_panel_nudge handler below now fall through to the same `else`
--  every other eight-row survival lobby uses. Reverting the row without also
--  reverting those would leave Nuketown's preview panel shrunk and mispositioned
--  for a row count it no longer has - the exact "number being wrong" failure
--  class this file's own header warns about.
-- ===========================================================================
CoD.PrivateGameLobby.GameTypeSettings[6] = {}
CoD.PrivateGameLobby.GameTypeSettings[6].id = "cleansedLoadout"
CoD.PrivateGameLobby.GameTypeSettings[6].name = "ZMUI_CLEANSED_LOADOUT_CAPS"
CoD.PrivateGameLobby.GameTypeSettings[6].hintText = "ZMUI_CLEANSED_LOADOUT_DESC"
CoD.PrivateGameLobby.GameTypeSettings[6].labels = {}
CoD.PrivateGameLobby.GameTypeSettings[6].labels[1] = "ZMUI_CLEANSED_LOADOUT_SHOTGUN_CAPS"
CoD.PrivateGameLobby.GameTypeSettings[6].labels[2] = "ZMUI_CLEANSED_LOADOUT_GUN_GAME_CAPS"
CoD.PrivateGameLobby.GameTypeSettings[6].values = {}
CoD.PrivateGameLobby.GameTypeSettings[6].values[1] = 0
CoD.PrivateGameLobby.GameTypeSettings[6].values[2] = 1
CoD.PrivateGameLobby.GameTypeSettings[6].gameTypes = {}
CoD.PrivateGameLobby.GameTypeSettings[6].gameTypes[1] = "zcleansed"
CoD.PrivateGameLobby.DvarDefaults = {}
CoD.PrivateGameLobby.DvarDefaults["sv_cheats"] = 0
-- CoD.PrivateGameLobby.DvarDefaults["zombies_minplayers"] = 1
-- -- ===========================================================================
--  zm_qol v1.99.58 - MAP-AWARE CHARACTER PICKER, above DIFFICULTY.
--
--  User, 2026-08-18: *"add that into the pre-game lobby above the difficulty
--  option in classic mode and have it be map-aware... if you changed to
--  tranzit/buried/die rise it would change the character selection options to
--  match the victus crew... And also add this option when survival mode is
--  selected... because all the survival maps only have CIA & CDC."*
--
--  🌟 STOCK ALREADY DOES THE HARD PART. AddGameOptionsButtons reads ui_mapname
--  and honours an optional per-entry `maps` list - the shipped TranZit-only
--  HELLHOUNDS row proves both the mechanism and the value format. So this is
--  four ordinary rows bound to ONE dvar, each shown only where it belongs;
--  there is no new machinery and no per-map code.
--
--  🛑 TWO THINGS HAD TO BE FIXED FIRST, BOTH IN AddGameOptionsButtons:
--    1. MapIsValid was never reset inside the loop (Treyarch's bug). Harmless
--       with one map-filtered row, fatal with four.
--    2. gametype cannot separate classic from survival - ui_gameType is
--       "zclassic" on Origins AND on a Green Run survival game. The new
--       `modeGroups` filter reads ui_zm_gamemodegroup instead, whose values
--       ("zclassic" / "zsurvival" / "zencounter") are written by
--       selectmaplistzombie.lua next to ui_mapname.
--
--  🌟 THE CREW ORDERS ARE READ OUT OF THE STOCK SCRIPTS, NOT FROM MEMORY, and
--  the order is NOT the order the cases appear in - zm_transit.gsc's switch
--  lists its cases 2, 0, 3, 1. Each map's give_personality_characters():
--
--    characterindex   TranZit / Die Rise / Buried   Origins      Mob
--      0              Russman   (oldman)            Dempsey      Finn
--      1              Stuhlinger(reporter)          Nikolai      Sal
--      2              Misty     (farmgirl)          Richtofen    Billy
--      3              Marlton   (engineer)          Takeo        Arlington
--
--  Survival is the SAME mechanism, not a different one: give_team_characters()
--  (zm_buried.gsc) also switches on characterindex - 0 and 2 give
--  c_zom_player_cia_dlc1_fb, 1 and 3 give c_zom_player_cdc_dlc1_fb.
--
--  🛑 THE VALUES ARE 1-BASED because the mod's `character` dvar is: 0 means
--  "leave whoever you spawned as alone", and 1-4 map to characterindex 0-3.
--  qol_options.gsc::qol_opt_character() owns that translation; do not change
--  one side without the other.
--
--  📝 Coop: the lobby writes a client dvar and the server reads its own, so
--  this is the host's choice - the same limitation night_mode and lod_fix
--  already carry. Per-client picks would need a different route entirely.
-- ===========================================================================
CoD.PrivateGameLobby.QolCharacter = {}

local QolCrewRow = function (Index, Maps, ModeGroups, Names)
	local Row = {}
	Row.id = "character"
	Row.name = "CHARACTER"
	Row.hintText = "Which member of the crew you play as."
	Row.maps = Maps
	Row.modeGroups = ModeGroups
	Row.labels = {}
	Row.values = {}
	Row.labels[1] = "DEFAULT"
	Row.values[1] = 0
	for i = 1, #Names, 1 do
		Row.labels[i + 1] = Names[i]
		Row.values[i + 1] = i
	end
	CoD.PrivateGameLobby.QolCharacter[Index] = Row
end

--  🛑 v2.14.23 - THE SURVIVAL ROW FOLLOWS THE MAP, NOT THE MODE. User,
--  2026-09-08: *"in the pre game lobby screen the character selection for
--  crazy place said CIA or CDC, i left it at default and i spawned as nikolai
--  ... same problem i had with mob and maybe buried."* The old row 4 was
--  "survival, every map: CIA/CDC", written when TranZit's stock locations
--  were the only survival games. The mod's own survival locations do not all
--  use the teams - measured from what each map actually installs as
--  level.givecustomcharacters for a zstandard game:
--
--    The Crazy Place (zm_tomb)   give_personality_characters - stock zm_tomb.gsc
--                                :156, and scripts/zm/replaced/zm_tomb_gamemodes
--                                .gsc leaves it (its banner: "Origins survival
--                                keeps the four heroes"). Ultimis.
--    Cell Block (zm_prison)      give_personality_characters - scripts/zm/
--                                replaced/zm_alcatraz_gamemodes.gsc routes
--                                zstandard through zm_prison::init_characters
--                                (the grief guard/inmate models are not in any
--                                fastfile a zstandard game loads). Mob crew.
--    Borough (zm_buried)         give_team_characters - replaced/zm_buried_
--                                gamemodes.gsc:380. CIA/CDC.
--    Die Rise's three            give_team_characters - replaced/zm_highrise_
--                                gamemodes.gsc:53. CIA/CDC.
--    TranZit's and Nuketown's    stock survival_init(): give_team_characters.
--                                CIA/CDC.
--
--  So Origins and Mob show their crews in survival too, and the CIA/CDC row is
--  pinned to the four maps whose survival games use the teams. Nothing else
--  changes: the values are the same 1-4 (1-2 for the teams), and
--  qol_options.gsc::qol_opt_character() already runs on every map and mode
--  and writes characterindex, which is exactly what both
--  give_personality_characters() implementations switch on.

-- Victus, on the three maps that use the crew. Classic only - those maps'
-- survival games (Borough, the Die Rise locations, TranZit's) use the teams.
QolCrewRow(1, { "zm_transit", "zm_highrise", "zm_buried" }, { "zclassic" },
	{ "RUSSMAN", "STUHLINGER", "MISTY", "MARLTON" })

-- Ultimis, Origins: classic and The Crazy Place alike.
QolCrewRow(2, { "zm_tomb" }, { "zclassic", "zsurvival" },
	{ "DEMPSEY", "NIKOLAI", "RICHTOFEN", "TAKEO" })

-- Mob of the Dead: classic and Cell Block alike.
QolCrewRow(3, { "zm_prison" }, { "zclassic", "zsurvival" },
	{ "FINN", "SAL", "BILLY", "ARLINGTON" })

-- Survival on the maps whose survival games use the CDC and CIA teams.
QolCrewRow(4, { "zm_transit", "zm_nuked", "zm_highrise", "zm_buried" }, { "zsurvival" },
	{ "CIA", "CDC" })

--  v1.99.60 - the little red cross next to a row that is no longer on its
--  default, which every other lobby row shows. User, 2026-08-18: *"there should
--  be a cross like the other pre-game menu options to display that it has been
--  modified and isn't stock/default."*
--
--  🌟 IT IS ONE TABLE ENTRY, NOT NEW CODE. Plutonium's own dvar selector
--  (raw\ui\t6\dvarleftrightselector.lua) already does the work in its default
--  handler DvarSelectorSetDvarFunc:
--
--      for Key, DvarValue in pairs( CoD.PrivateGameLobby.DvarDefaults ) do
--          if DvarSelector.parentSelectorButton.m_dvarName == Key then
--              ... showStarIcon( DvarSelector.value ~= DvarValue )
--
--  It only ever fires for a dvar that HAS an entry here, which is why the
--  CHARACTER row showed nothing. 0 is the row's own DEFAULT choice, so the
--  cross appears for any crew member and clears when you cycle back.
--
--  📝 This works on menu OPEN as well as on change, without any extra call:
--  CoD.LeftRightSelector.AddChoice runs updateChoice on whichever choice
--  matches the current value while the row is being built, and that is what
--  invokes the handler above. The rows deliberately pass NO custom callback for
--  exactly this reason - overriding it would replace the star-icon logic along
--  with the dvar write, which is the v1.93.0 bug in a new costume.
CoD.PrivateGameLobby.DvarDefaults["character"] = 0
CoD.PrivateGameLobby.Dvars = {}
-- CoD.PrivateGameLobby.Dvars[1] = {}
-- CoD.PrivateGameLobby.Dvars[1].id = "zombies_minplayers"
-- CoD.PrivateGameLobby.Dvars[1].name = "MIN PLAYERS"
-- CoD.PrivateGameLobby.Dvars[1].hintText = "The game will wait at the loadscreen until the amount of players ingame is reached."
-- CoD.PrivateGameLobby.Dvars[1].labels = {}
-- CoD.PrivateGameLobby.Dvars[1].labels[1] = "1"
-- CoD.PrivateGameLobby.Dvars[1].labels[2] = "2"
-- CoD.PrivateGameLobby.Dvars[1].labels[3] = "3"
-- CoD.PrivateGameLobby.Dvars[1].labels[4] = "4"
-- CoD.PrivateGameLobby.Dvars[1].labels[5] = "5"
-- CoD.PrivateGameLobby.Dvars[1].labels[6] = "6"
-- CoD.PrivateGameLobby.Dvars[1].labels[7] = "7"
-- CoD.PrivateGameLobby.Dvars[1].labels[8] = "8"
-- CoD.PrivateGameLobby.Dvars[1].values = {}
-- CoD.PrivateGameLobby.Dvars[1].values[1] = 1
-- CoD.PrivateGameLobby.Dvars[1].values[2] = 2
-- CoD.PrivateGameLobby.Dvars[1].values[3] = 3
-- CoD.PrivateGameLobby.Dvars[1].values[4] = 4
-- CoD.PrivateGameLobby.Dvars[1].values[5] = 5
-- CoD.PrivateGameLobby.Dvars[1].values[6] = 6
-- CoD.PrivateGameLobby.Dvars[1].values[7] = 7
-- CoD.PrivateGameLobby.Dvars[1].values[8] = 8
-- ===========================================================================
--  TARGET ASSIST  -  the lobby row is REMOVED, v1.99.34, user request
--  2026-08-17: *"there's already an option in the controls > gamepad settings
--  ... just simply remove the option from the pre-game lobby menu, and make
--  the other option in controls > gamepad toggle both those options' states."*
-- ---------------------------------------------------------------------------
--  🌟 THE TWO ROWS ARE NOT DUPLICATES, THEY ARE A PERMISSION AND A SETTING -
--  and that is precisely why one of them can go.
--
--      lobby row            sv_allowAimAssist   "may controller players use
--                                                aim assist in this match"
--      CONTROLS > GAMEPAD   input_targetAssist  this player's own switch
--
--  Plutonium's own optionscontrols.lua proves the dependency the user
--  suspected. Its GAMEPAD tab reads (raw\ui\t6\menus\optionscontrols.lua.aside,
--  line 389):
--
--      if UIExpression.IsInGame() == 1 and UIExpression.DvarBool(nil,
--         "sv_allowAimAssist") == 0 then
--          ... a LOCKED row, "Target Assist is disabled on this server."
--
--  So with the permission off, the real setting cannot even be reached in game.
--  Two switches in series, one of them buried in the lobby, is the base game's
--  design fault - not something worth reproducing.
--
--  🛑 THE FIX IS NOT TO MAKE THE GAMEPAD ROW WRITE BOTH DVARS. That would mean
--  shipping this mod's own optionscontrols.lua, and a shipped copy SHADOWS
--  Plutonium's patched one - which is exactly how RAW INPUT, MOUSE ACCELERATION
--  and FIX HIGH POLL RATE LAG were deleted from the user's CONTROLS menu once
--  already (.agents\checkpoint_48.md §4). Trading three working Plutonium rows
--  for one is a straight loss, and the copy would go stale on their next update.
--
--  Instead the permission is simply always granted, so input_targetAssist is
--  the only switch left standing - the same end result with nothing shadowed.
--  qol_options.gsc::init() sets sv_allowAimAssist to 1 at map load; see the
--  note there for why it is set rather than left to the default.
--
--  📝 DvarDefaults keeps its entry on purpose. It is read only by
--  dvarleftrightselector.lua, and only to decide whether to draw the ⭐ "differs
--  from default" icon - it never writes the dvar. Leaving it costs nothing and
--  records what Plutonium considers the default. 🌟 That default is 1, and it
--  is confirmed twice over: this table, and the user's own screenshot of the
--  lobby showing TARGET ASSIST ENABLED with no star beside it.
-- ===========================================================================
CoD.PrivateGameLobby.DvarDefaults["sv_allowAimAssist"] = 1
CoD.PrivateGameLobby.Dvars = {}
--  🛑 AddGameOptionsButtons() walks this table with `for i = 1, #GameOptions`,
--  so the indices must stay contiguous from 1. Removing the old [1] means
--  renumbering everything below it - it is not enough to delete the block.
CoD.PrivateGameLobby.Dvars[1] = {}
CoD.PrivateGameLobby.Dvars[1].id = "sv_cheats"
CoD.PrivateGameLobby.Dvars[1].name = "CHEATS"
CoD.PrivateGameLobby.Dvars[1].hintText = "Enable cheats on server."
CoD.PrivateGameLobby.Dvars[1].labels = {}
CoD.PrivateGameLobby.Dvars[1].labels[1] = "MENU_DISABLED_CAPS"
CoD.PrivateGameLobby.Dvars[1].labels[2] = "MENU_ENABLED_CAPS"
CoD.PrivateGameLobby.Dvars[1].values = {}
CoD.PrivateGameLobby.Dvars[1].values[1] = 0
CoD.PrivateGameLobby.Dvars[1].values[2] = 1

-- ===========================================================================
--  PERK LIMIT  -  v1.99.26, user request 2026-08-17
-- ===========================================================================
--  Asked for after seeing the same row in the TechnoOps lobby. This is the one
--  of those four requests that genuinely belongs in the lobby: it has to be
--  settled before the match starts, because the server reads it once during map
--  init (quality_of_life.gsc::remove_perk_limit).
--
--  🛑 THE DEFAULT IS 0 AND 0 MEANS "AS MANY AS THIS MAP OFFERS". That is the
--  behaviour the mod has had since v1.55.4, so leaving this row alone changes
--  nothing. The comment above remove_perk_limit() records TWO separate in-game
--  bugs caused by this number being wrong (nine on Origins, eleven at the Diner
--  machine) - this option must not become a third, which is why it is opt-in
--  rather than a number that has to be correct out of the box.
--
--  📝 12 is Black Ops II's real perk count and the highest fixed choice here.
--  A map that somehow offers more is still reachable through MAP MAX; the
--  server clamps a chosen number DOWN to what the map has, never up.
--  🌟 v1.99.94 - THE DEFAULT HERE IS 4, NOT 0, AND THAT IS THE RED CROSS. User,
--  2026-08-20: *"Make it so that MAP MAX option for perk limit in the pre-game
--  menu lobby screen also has an x to the left of it as this isn't stock/default
--  behaviour and is modified from the vanilla state of the perks limit."*
--
--  🛑 THIS TABLE NEVER WRITES A DVAR - it is COSMETIC ONLY, and that is measured,
--  not assumed. `CoD.PrivateGameLobby.DvarDefaults` is read in exactly one place
--  in the whole of Plutonium's raw LUI: dvarleftrightselector.lua:6, inside
--  DvarSelectorSetDvarFunc, purely to decide `showStarIcon( value ~= default )`.
--  The dvar itself is created by quality_of_life.gsc:683 with `create_dvar(
--  "perk_limit", 0 )` and read at :3251 with getdvarintdefault( "perk_limit", 0 ),
--  so MAP MAX remains the shipping behaviour and nothing about the match changes.
--
--  🌟 WHY 4. Stock BO2's limit is `level.perk_purchase_limit = 4`
--  ( _zm_perks.gsc:23 ) on every map - Origins' dig easter egg raises it per
--  player afterwards ( zm_tomb_dig.gsc:619-633 ), it does not change the base.
--  So 4 is the one choice on this row that IS vanilla: pick it and the cross
--  clears, and every other choice - MAP MAX included - is marked as modified,
--  which is exactly what the row does for CHARACTER and MACHINE DROPS.
CoD.PrivateGameLobby.DvarDefaults["perk_limit"] = 4
CoD.PrivateGameLobby.Dvars[2] = {}
CoD.PrivateGameLobby.Dvars[2].id = "perk_limit"
CoD.PrivateGameLobby.Dvars[2].name = "PERK LIMIT"
CoD.PrivateGameLobby.Dvars[2].hintText = "How many perks a player may hold at once. MAP MAX allows every perk the map offers."
CoD.PrivateGameLobby.Dvars[2].labels = {}
CoD.PrivateGameLobby.Dvars[2].labels[1] = "MAP MAX"
CoD.PrivateGameLobby.Dvars[2].labels[2] = "1"
CoD.PrivateGameLobby.Dvars[2].labels[3] = "2"
CoD.PrivateGameLobby.Dvars[2].labels[4] = "3"
CoD.PrivateGameLobby.Dvars[2].labels[5] = "4"
CoD.PrivateGameLobby.Dvars[2].labels[6] = "5"
CoD.PrivateGameLobby.Dvars[2].labels[7] = "6"
CoD.PrivateGameLobby.Dvars[2].labels[8] = "7"
CoD.PrivateGameLobby.Dvars[2].labels[9] = "8"
CoD.PrivateGameLobby.Dvars[2].labels[10] = "9"
CoD.PrivateGameLobby.Dvars[2].labels[11] = "10"
CoD.PrivateGameLobby.Dvars[2].labels[12] = "11"
CoD.PrivateGameLobby.Dvars[2].labels[13] = "12"
CoD.PrivateGameLobby.Dvars[2].values = {}
CoD.PrivateGameLobby.Dvars[2].values[1] = 0
CoD.PrivateGameLobby.Dvars[2].values[2] = 1
CoD.PrivateGameLobby.Dvars[2].values[3] = 2
CoD.PrivateGameLobby.Dvars[2].values[4] = 3
CoD.PrivateGameLobby.Dvars[2].values[5] = 4
CoD.PrivateGameLobby.Dvars[2].values[6] = 5
CoD.PrivateGameLobby.Dvars[2].values[7] = 6
CoD.PrivateGameLobby.Dvars[2].values[8] = 7
CoD.PrivateGameLobby.Dvars[2].values[9] = 8
CoD.PrivateGameLobby.Dvars[2].values[10] = 9
CoD.PrivateGameLobby.Dvars[2].values[11] = 10
CoD.PrivateGameLobby.Dvars[2].values[12] = 11
CoD.PrivateGameLobby.Dvars[2].values[13] = 12

-- ===========================================================================
--  MACHINE DROPS  -  Nuketown survival only, v1.99.63, user request 2026-08-19
-- ===========================================================================
--  *"the option lets you pick whether all machines drop on round 1, or if they
--  retain their stock behaviour... a lot of peoples' critiques in this Zombies
--  map is how annoying they find the fact that you have to progress through so
--  many waves/rounds in order to have access to all the typical map features"*.
--
--  🌟 THE FILTERS ARE THE ONES ALREADY BUILT FOR THE CHARACTER ROWS. `maps`
--  is Treyarch's own (the TranZit-only HELLHOUNDS row uses it); `modeGroups`
--  was added in v1.99.58 because ui_gameType cannot separate classic from
--  survival. Together they pin this row to Nuketown survival and nowhere else.
--
--  📝 That pinning is total, not just tidy: Nuketown appears in
--  selectmaplistzombie.lua's Locations table and in NO other list - it is not
--  a classic map and it is not in GriefLocations - so "Nuketown survival" is
--  every game of Nuketown there is. The dvar can never leak into a mode where
--  the row is hidden.
--
--
--  🛑 THE HINT IS ONE LINE, AND THAT IS A MEASURED BUDGET, NOT A STYLE CHOICE.
--  v1.99.63 shipped a 147-character hint; it wrapped, and the second line was
--  drawn straight through the map preview image (user screenshot, 2026-08-19).
--
--  🌟 MEASURED OFF THAT SCREENSHOT. It is 2000 px wide for LUI's 1280 units, so
--  1.5625 px per unit. The line that DID fit was 97 characters and rendered
--  x 327 -> 1513, i.e. 1186 px, about 12.06 px per character; the next word
--  ("every", ~72 px) is what would not fit, so the wrap boundary is between
--  1513 and 1585 px. 87 characters is ~1050 px - roughly 16% inside it.
--
--  📝 The other hand-written hint in this file, PERK LIMIT's, is 83 characters
--  and has shipped on one line since v1.99.26. Treat ~90 as the ceiling.
--  🛑 THE DVAR NAME IS FROZEN. It is what the console takes and what ends up in
--  the player's archived config; renaming the visible label is free, renaming
--  `nuked_all_machines` silently resets everyone's saved choice.
CoD.PrivateGameLobby.DvarDefaults["nuked_all_machines"] = 0
CoD.PrivateGameLobby.Dvars[3] = {}
CoD.PrivateGameLobby.Dvars[3].id = "nuked_all_machines"
CoD.PrivateGameLobby.Dvars[3].name = "MACHINE DROPS"
CoD.PrivateGameLobby.Dvars[3].hintText = "STOCK spreads the machines over rounds 3 to 26. ALL ON ROUND 1 brings them all at once."
CoD.PrivateGameLobby.Dvars[3].labels = {}
CoD.PrivateGameLobby.Dvars[3].labels[1] = "STOCK"
CoD.PrivateGameLobby.Dvars[3].labels[2] = "ALL ON ROUND 1"
CoD.PrivateGameLobby.Dvars[3].values = {}
CoD.PrivateGameLobby.Dvars[3].values[1] = 0
CoD.PrivateGameLobby.Dvars[3].values[2] = 1
CoD.PrivateGameLobby.Dvars[3].maps = {}
CoD.PrivateGameLobby.Dvars[3].maps[1] = "zm_nuked"
CoD.PrivateGameLobby.Dvars[3].modeGroups = {}
CoD.PrivateGameLobby.Dvars[3].modeGroups[1] = "zsurvival"

-- ===========================================================================
--  SOLO EASTER EGGS  -  classic maps only, v2.14.3, user request 2026-09-06
-- ===========================================================================
--  *"in all the classic maps in the pre-game lobby screen, add an option to
--  enable/disable solo easter eggs ... make sure to not add that option into
--  survival maps that dont have easter eggs."*
--
--  The server half is five files, one per map, each named qol_solo_ee.gsc and
--  living in that map's own scripts\zm\<map>\ folder. Four are adapted from
--  Hadi77KSA's "Plutonium T6 Any Player EE Scripts" v2.4.1; the fifth (Mob of
--  the Dead, v2.14.18) is written from Treyarch's own scripts because that mod
--  does not cover Mob. Each reads this dvar once, after
--  flag_wait( "initial_players_connected" ).
--
--  🌟 THE FILTERS ARE THE ONES ALREADY BUILT FOR THE CHARACTER AND MACHINE
--  DROPS ROWS - `maps` is Treyarch's own, `modeGroups` was added in v1.99.58 -
--  so this is one table entry and no new machinery.
--
--  🛑 THE MAP LIST IS THE ANSWER TO "not on survival maps that have no Easter
--  Egg". All five classic maps are now on it:
--
--    zm_transit / zm_highrise / zm_buried / zm_tomb   -> listed. Each has a
--        qol_solo_ee.gsc that changes something on that map.
--    zm_prison (Mob of the Dead)                      -> listed since v2.14.18
--        (user, 2026-09-08: *"enable that for motd as well so every maps easter
--        egg can be solo'd"*). It was held back while no script existed - the
--        source mod does not cover Mob - and the row would have been a lie. It
--        now has scripts\zm\zm_prison\qol_solo_ee.gsc, written from Treyarch's
--        own scripts: Mob's whole quest is already soloable EXCEPT the final
--        flight, which stock gates twice on getplayers().size >= 2 inside
--        maps\mp\zm_prison_sq_final. That file lifts both, and restores the
--        Pop Goes the Weasel achievement that stage_final() only hands out on
--        its four-player showdown path. Full reasoning is in its header.
--    zm_nuked (Nuketown)                              -> NOT listed, and could
--        not be: it has no Easter Egg and is not a classic map at all.
--
--  🛑 SURVIVAL AND GRIEF ARE EXCLUDED TWICE OVER, ON PURPOSE. modeGroups pins
--  the row to "zclassic", so Bus Depot / Farm / Town / Diner / Borough /
--  Cell Block / Rooftop never draw it even though four of them share a
--  level.script with a classic map. The GSC half then repeats the check with
--  stock's own maps\mp\zombies\_zm_sidequests::is_sidequest_allowed(
--  "zclassic" ), which reads g_gametype - "zstandard" for survival, "zgrief"
--  for grief - so even a dvar set by hand at the console cannot leak the
--  behaviour into a mode that has no quest to change.
--
--  📝 DEFAULT 0 = STOCK, and that is the project rule, not timidity: a new
--  toggle must not silently change what the mod already does. The red cross
--  therefore appears when the row is ENABLED, which is correct - Treyarch's
--  Easter Eggs want four players.
--
--  📝 ROW BUDGET. A classic map currently draws six rows (CHARACTER, plus
--  DIFFICULTY / STARTING ROUND / HEADSHOTS ONLY, plus CHEATS / PERK LIMIT);
--  this makes seven. Nuketown and Green Run survival already draw eight, so
--  the hint text sits no lower here than on a screen that already ships.
--
--  🛑 THE DVAR NAME IS FROZEN once this ships - it is what the console takes
--  and what lands in the player's archived config. Renaming the label is free;
--  renaming `solo_ee` silently resets everyone's saved choice.
--
--  📝 The hint is 84 characters. ~90 is the measured ceiling before it wraps
--  into the map preview panel - see the MACHINE DROPS note above.
CoD.PrivateGameLobby.DvarDefaults["solo_ee"] = 0
CoD.PrivateGameLobby.Dvars[4] = {}
CoD.PrivateGameLobby.Dvars[4].id = "solo_ee"
CoD.PrivateGameLobby.Dvars[4].name = "SOLO EASTER EGGS"
CoD.PrivateGameLobby.Dvars[4].hintText = "Lets this map's main Easter Egg quest be finished with fewer than four players."
CoD.PrivateGameLobby.Dvars[4].labels = {}
CoD.PrivateGameLobby.Dvars[4].labels[1] = "MENU_DISABLED_CAPS"
CoD.PrivateGameLobby.Dvars[4].labels[2] = "MENU_ENABLED_CAPS"
CoD.PrivateGameLobby.Dvars[4].values = {}
CoD.PrivateGameLobby.Dvars[4].values[1] = 0
CoD.PrivateGameLobby.Dvars[4].values[2] = 1
CoD.PrivateGameLobby.Dvars[4].maps = {}
CoD.PrivateGameLobby.Dvars[4].maps[1] = "zm_transit"
CoD.PrivateGameLobby.Dvars[4].maps[2] = "zm_highrise"
CoD.PrivateGameLobby.Dvars[4].maps[3] = "zm_buried"
CoD.PrivateGameLobby.Dvars[4].maps[4] = "zm_tomb"
CoD.PrivateGameLobby.Dvars[4].maps[5] = "zm_prison"
CoD.PrivateGameLobby.Dvars[4].modeGroups = {}
CoD.PrivateGameLobby.Dvars[4].modeGroups[1] = "zclassic"
CoD.PrivateGameLobby.ButtonPrompt_TeamPrev = function (f1_arg0, ClientInstance)
	if Engine.PartyHostIsReadyToStart() == true then
		return 
	else
		Engine.LocalPlayerPartyPrevTeam(ClientInstance.controller)
		Engine.PlaySound("cac_loadout_edit_submenu")
	end
end

CoD.PrivateGameLobby.ButtonPrompt_TeamNext = function (f2_arg0, ClientInstance)
	if Engine.PartyHostIsReadyToStart() == true then
		return 
	else
		Engine.LocalPlayerPartyNextTeam(ClientInstance.controller)
		Engine.PlaySound("cac_loadout_edit_submenu")
	end
end

CoD.PrivateGameLobby.ShouldEnableTeamCycling = function (PrivateGameLobbyWidget)
	if PrivateGameLobbyWidget.panelManager == nil then
		return false
	elseif not PrivateGameLobbyWidget.panelManager:isPanelOnscreen("lobbyPane") then
		return false
	elseif Engine.PartyIsReadyToStart() == true then
		return false
	elseif Engine.PartyHostIsReadyToStart() == true then
		return false
	elseif Engine.GetGametypeSetting("autoTeamBalance") == 1 and Engine.GetGametypeSetting("allowspectating") ~= 1 then
		return false
	else
		return true
	end
end

CoD.PrivateGameLobby.SetupTeamCycling = function (PrivateGameLobbyWidget)
	if CoD.PrivateGameLobby.ShouldEnableTeamCycling(PrivateGameLobbyWidget) then
		PrivateGameLobbyWidget.cycleTeamButtonPrompt:enable()
	else
		PrivateGameLobbyWidget.cycleTeamButtonPrompt:disable()
	end
end

CoD.PrivateGameLobby.CurrentPanelChanged = function (PrivateGameLobbyWidget, f5_arg1)
	CoD.Lobby.CurrentPanelChanged(PrivateGameLobbyWidget, f5_arg1)
	CoD.PrivateGameLobby.SetupTeamCycling(PrivateGameLobbyWidget)
end

CoD.PrivateGameLobby.ButtonPrompt_PartyUpdateStatus = function (PrivateGameLobbyWidget, f6_arg1)
	CoD.GameLobby.UpdateStatusText(PrivateGameLobbyWidget, f6_arg1)
	CoD.PrivateGameLobby.SetupTeamCycling(PrivateGameLobbyWidget)
	PrivateGameLobbyWidget:dispatchEventToChildren(f6_arg1)
end

CoD.PrivateGameLobby.DoesGametypeSupportBots = function (Gametype)
	return true
end

CoD.PrivateGameLobby.BotButton_Update = function (BotsButton)
	local Gametype = UIExpression.DvarString(nil, "ui_gameType")
	local EnemyBots = UIExpression.DvarInt(nil, "bot_enemies")
	BotsButton.starImage:setAlpha(0)
	if not CoD.IsGametypeTeamBased() then
		Engine.SetDvar("bot_friends", 0)
	end
	if CoD.IsGametypeTeamBased() and EnemyBots > 9 then
		Engine.SetDvar("bot_enemies", 9)
	end
	if CoD.PrivateGameLobby.DoesGametypeSupportBots(Gametype) then
		BotsButton.hintText = Engine.Localize("MENU_BOTS_HINT")
		BotsButton:enable()
		if UIExpression.DvarInt(nil, "bot_friends") ~= 0 or EnemyBots ~= 0 then
			BotsButton.starImage:setAlpha(1)
		end
	else
		BotsButton.hintText = Engine.Localize("MENU_BOTS_NOT_SUPPORTED_" .. Gametype)
		BotsButton:disable()
	end
end

CoD.PrivateGameLobby.PopulateButtons_Project_Multiplayer = function (PrivateGameLobbyButtonPane, IsHost)
	if IsHost == true then
		local SetupGameText = Engine.Localize("MPUI_SETUP_GAME_CAPS")
		local f9_local1_1, f9_local1_2, f9_local1_3, f9_local1_4 = GetTextDimensions(SetupGameText, CoD.CoD9Button.Font, CoD.CoD9Button.TextHeight)
		PrivateGameLobbyButtonPane.body.setupGameButton = PrivateGameLobbyButtonPane.body.buttonList:addButton(SetupGameText)
		PrivateGameLobbyButtonPane.body.setupGameButton.hintText = Engine.Localize("MPUI_SETUP_GAME_DESC")
		PrivateGameLobbyButtonPane.body.setupGameButton:setActionEventName("open_setup_game_flyout")
		PrivateGameLobbyButtonPane.body.setupGameButton:registerEventHandler("button_update", CoD.PrivateGameLobby.Button_UpdateHostButton)
		if PrivateGameLobbyButtonPane.body.widestButtonTextWidth < f9_local1_3 then
			PrivateGameLobbyButtonPane.body.widestButtonTextWidth = f9_local1_3
		end
		local SetupBotsText = Engine.Localize("MENU_SETUP_BOTS_CAPS")
		local f9_local2_1, f9_local2_2, f9_local2_3, f9_local2_4 = GetTextDimensions(SetupBotsText, CoD.CoD9Button.Font, CoD.CoD9Button.TextHeight)
		PrivateGameLobbyButtonPane.body.botsButton = PrivateGameLobbyButtonPane.body.buttonList:addButton(SetupBotsText)
		PrivateGameLobbyButtonPane.body.botsButton:setActionEventName("open_bots_menu")
		PrivateGameLobbyButtonPane.body.botsButton:registerEventHandler("gamelobby_update", CoD.PrivateGameLobby.BotButton_Update)
		if PrivateGameLobbyButtonPane.body.widestButtonTextWidth < f9_local2_3 then
			PrivateGameLobbyButtonPane.body.widestButtonTextWidth = f9_local2_3
		end
		local recImage = LUI.UIImage.new()
		recImage:setLeftRight(true, false, f9_local2_3 + 5, f9_local2_3 + 5 + 30)
		recImage:setTopBottom(false, false, -15, 15)
		recImage:setAlpha(0)
		recImage:setImage(RegisterMaterial(CoD.MPZM("ui_host", "ui_host_zm")))
		PrivateGameLobbyButtonPane.body.botsButton:addElement(recImage)
		PrivateGameLobbyButtonPane.body.botsButton.starImage = recImage
		CoD.PrivateGameLobby.BotButton_Update(PrivateGameLobbyButtonPane.body.botsButton)
		PrivateGameLobbyButtonPane.body.buttonList:addSpacer(CoD.CoD9Button.Height / 2)
	end
	local CreateAClassText = Engine.Localize("MENU_CREATE_A_CLASS_CAPS")
	local f9_local3_1, f9_local3_2, f9_local3_3, f9_local3_4 = GetTextDimensions(CreateAClassText, CoD.CoD9Button.Font, CoD.CoD9Button.TextHeight)
	PrivateGameLobbyButtonPane.body.createAClassButton = PrivateGameLobbyButtonPane.body.buttonList:addButton(CreateAClassText)
	PrivateGameLobbyButtonPane.body.createAClassButton.id = "CoD9Button." .. "PrivateGameLobby." .. Engine.Localize("MENU_CREATE_A_CLASS_CAPS")
	CoD.CACUtility.SetupCACLock(PrivateGameLobbyButtonPane.body.createAClassButton)
	PrivateGameLobbyButtonPane.body.createAClassButton:registerEventHandler("button_action", CoD.GameLobby.Button_CAC)
	if PrivateGameLobbyButtonPane.body.widestButtonTextWidth < f9_local3_3 then
		PrivateGameLobbyButtonPane.body.widestButtonTextWidth = f9_local3_3
	end
	local ScorestreakText = Engine.Localize("MENU_SCORE_STREAKS_CAPS")
	local f9_local4_1, f9_local4_2, f9_local4_3, f9_local4_4 = GetTextDimensions(ScorestreakText, CoD.CoD9Button.Font, CoD.CoD9Button.TextHeight)
	PrivateGameLobbyButtonPane.body.rewardsButton = PrivateGameLobbyButtonPane.body.buttonList:addButton(ScorestreakText)
	PrivateGameLobbyButtonPane.body.rewardsButton.id = "CoD9Button." .. "PrivateGameLobby." .. Engine.Localize("MENU_SCORE_STREAKS_CAPS")
	PrivateGameLobbyButtonPane.body.rewardsButton.hintText = Engine.Localize("FEATURE_KILLSTREAKS_DESC")
	CoD.SetupButtonLock(PrivateGameLobbyButtonPane.body.rewardsButton, nil, "FEATURE_KILLSTREAKS", "FEATURE_KILLSTREAKS_DESC")
	PrivateGameLobbyButtonPane.body.rewardsButton:registerEventHandler("button_action", CoD.GameLobby.Button_Rewards)
	if PrivateGameLobbyButtonPane.body.widestButtonTextWidth < f9_local4_3 then
		PrivateGameLobbyButtonPane.body.widestButtonTextWidth = f9_local4_3
	end
	PrivateGameLobbyButtonPane.body.barracksButtonSpacer = PrivateGameLobbyButtonPane.body.buttonList:addSpacer(CoD.CoD9Button.Height / 2)
	PrivateGameLobbyButtonPane.body.barracksButton = PrivateGameLobbyButtonPane.body.buttonList:addButton(Engine.Localize("MENU_BARRACKS_CAPS"))
	PrivateGameLobbyButtonPane.body.barracksButton.id = "CoD9Button." .. "PrivateGameLobby." .. Engine.Localize("MENU_BARRACKS_CAPS")
	CoD.SetupBarracksLock(PrivateGameLobbyButtonPane.body.barracksButton)
	PrivateGameLobbyButtonPane.body.barracksButton:setActionEventName("open_barracks")
	PrivateGameLobbyButtonPane.body.buttonList:addSpacer(CoD.CoD9Button.Height / 4, 200)
	if IsHost and UIExpression.SessionMode_IsOnlineGame() == 1 then
		local ToggleDemoRecording = PrivateGameLobbyButtonPane.body.buttonList:addButton(Engine.Localize("CUSTOM_GAME_RECORDING_CAPS"))
		ToggleDemoRecording.hintText = Engine.Localize("CUSTOM_GAME_RECORDING_DESC")
		ToggleDemoRecording:registerEventHandler("button_action", CoD.PrivateGameLobby.DemoRecordingButton_ToggleDemoRecording)
		
		local recImage = LUI.UIImage.new()
		recImage:setLeftRight(false, true, -130, -100)
		recImage:setTopBottom(false, false, -15, 15)
		recImage:setAlpha(1)
		recImage:setImage(RegisterMaterial("codtv_recording"))
		
		local recText = LUI.UIText.new({
			leftAnchor = false,
			rightAnchor = true,
			left = -100,
			right = -40,
			topAnchor = false,
			bottomAnchor = false,
			top = -CoD.textSize.Condensed / 2,
			bottom = CoD.textSize.Condensed / 2,
			font = CoD.fonts.Condensed,
			alignment = LUI.Alignment.Left
		})
		ToggleDemoRecording:addElement(recImage)
		ToggleDemoRecording.recImage = recImage
		
		ToggleDemoRecording:addElement(recText)
		ToggleDemoRecording.recText = recText
		
		CoD.PrivateGameLobby.UpdateDemoRecordingButton(ToggleDemoRecording)
	end
	if Engine.SessionModeIsMode(CoD.SESSIONMODE_SYSTEMLINK) == false and UIExpression.DvarBool(nil, "webm_encUiEnabledCustom") == 1 then
		CoD.Lobby.AddLivestreamButton(PrivateGameLobbyButtonPane, 10, IsHost)
	end
end

CoD.PrivateGameLobby.UpdateDemoRecordingButton = function (ToggleDemoRecording)
	if Dvar.demo_recordPrivateMatch:get() then
		ToggleDemoRecording.recImage:setRGB(1, 0, 0)
		ToggleDemoRecording.recText:setText(Engine.Localize("MENU_ON_CAPS"))
	else
		ToggleDemoRecording.recImage:setRGB(0.3, 0.3, 0.3)
		ToggleDemoRecording.recText:setText(Engine.Localize("MENU_OFF_CAPS"))
	end
end

CoD.PrivateGameLobby.DemoRecordingButton_ToggleDemoRecording = function (ToggleDemoRecording, f11_arg1)
	Dvar.demo_recordPrivateMatch:set(not Dvar.demo_recordPrivateMatch:get())
	CoD.PrivateGameLobby.UpdateDemoRecordingButton(ToggleDemoRecording)
end

CoD.PrivateGameLobby.PopulateFlyoutButtons_Project_Multiplayer = function (PrivateGameLobbyButtonPane)
	if not CoD.isZombie then
		PrivateGameLobbyButtonPane.body.setupGameFlyoutContainer.changeMapButton = PrivateGameLobbyButtonPane.body.setupGameFlyoutContainer.buttonList:addButton(Engine.Localize("MPUI_CHANGE_MAP_CAPS"))
		PrivateGameLobbyButtonPane.body.setupGameFlyoutContainer.changeMapButton.hintText = Engine.Localize("MPUI_CHANGE_MAP_DESC")
		PrivateGameLobbyButtonPane.body.setupGameFlyoutContainer.changeMapButton:setActionEventName("open_change_map")
		PrivateGameLobbyButtonPane.body.setupGameFlyoutContainer.changeMapButton:registerEventHandler("button_update", CoD.PrivateGameLobby.Button_UpdateHostButton)
		PrivateGameLobbyButtonPane.body.setupGameFlyoutContainer.changeGameModeButton = PrivateGameLobbyButtonPane.body.setupGameFlyoutContainer.buttonList:addButton(Engine.Localize("MPUI_CHANGE_GAME_MODE_CAPS"))
		PrivateGameLobbyButtonPane.body.setupGameFlyoutContainer.changeGameModeButton.hintText = Engine.Localize("MPUI_CHANGE_GAME_MODE_DESC")
		PrivateGameLobbyButtonPane.body.setupGameFlyoutContainer.changeGameModeButton:setActionEventName("open_change_game_mode")
		PrivateGameLobbyButtonPane.body.setupGameFlyoutContainer.changeGameModeButton:registerEventHandler("button_update", CoD.PrivateGameLobby.Button_UpdateHostButton)
	end
	PrivateGameLobbyButtonPane.body.setupGameFlyoutContainer.editGameOptionsButton = PrivateGameLobbyButtonPane.body.setupGameFlyoutContainer.buttonList:addButton(Engine.Localize("MPUI_EDIT_GAME_RULES_CAPS"))
	PrivateGameLobbyButtonPane.body.setupGameFlyoutContainer.editGameOptionsButton.hintText = Engine.Localize("MPUI_EDIT_GAME_RULES_DESC")
	PrivateGameLobbyButtonPane.body.setupGameFlyoutContainer.editGameOptionsButton:setActionEventName("open_editGameOptions_menu")
	PrivateGameLobbyButtonPane.body.setupGameFlyoutContainer.editGameOptionsButton:registerEventHandler("button_update", CoD.PrivateGameLobby.Button_UpdateHostButton)
end

local AddGameOptionsButtons = function (PrivateGameLobbyButtonPane, GameOptions, GameOptionsType)
	local Gametype = UIExpression.DvarString(nil, "ui_gameType")
	local f13_local1 = 220
	if Gametype == "zcleansed" then
		f13_local1 = 170
	end
	local Mapname = UIExpression.DvarString(nil, "ui_mapname")
	-- zm_qol v1.99.58 - the mode GROUP, which is what the lobby's "CHANGE GAME
	-- MODE" row actually sets. selectmaplistzombie.lua writes it alongside
	-- ui_mapname, and its values are "zclassic" / "zsurvival" / "zencounter".
	--
	-- 🛑 IT IS NOT ui_gameType, AND THE DIFFERENCE MATTERS. ui_gameType is
	-- zclassic on BOTH Origins (its only mode) and on a Green Run SURVIVAL
	-- game, so gametype alone cannot tell "Origins with the Ultimis crew" from
	-- "Diner survival with the CIA/CDC teams". ui_zm_gamemodegroup can.
	local ModeGroup = UIExpression.DvarString(nil, "ui_zm_gamemodegroup")
	local GametypeIsValid = false
	local MapIsValid = false
	for GameOptionsIndex = 1, #GameOptions, 1 do
		GametypeIsValid = false
		-- 🛑 v1.99.58 - MapIsValid IS RESET HERE, AND STOCK NEVER DID.
		-- Treyarch declares it outside the loop and only ever sets it TRUE, so
		-- once any entry matched the map every later map-filtered entry passed
		-- too. It was invisible while exactly one row used a `maps` list (the
		-- TranZit-only HELLHOUNDS row); the character rows below add four, and
		-- without this line picking Origins would also draw the Victus crew.
		MapIsValid = false
		if GameOptions[GameOptionsIndex].gameTypes ~= nil then
			for GametypeIndex = 1, #GameOptions[GameOptionsIndex].gameTypes, 1 do
				if GameOptions[GameOptionsIndex].gameTypes[GametypeIndex] == Gametype then
					GametypeIsValid = true
				end
			end
		else
			GametypeIsValid = true
		end
		if GameOptions[GameOptionsIndex].maps ~= nil then
			for MapIndex = 1, #GameOptions[GameOptionsIndex].maps, 1 do
				if GameOptions[GameOptionsIndex].maps[MapIndex] == Mapname then
					MapIsValid = true
					break
				end
			end
			if not MapIsValid then
				GametypeIsValid = false
			end
		end
		-- zm_qol v1.99.58 - optional `modeGroups` filter, same shape as `maps`.
		if GameOptions[GameOptionsIndex].modeGroups ~= nil then
			local ModeGroupIsValid = false
			for ModeGroupIndex = 1, #GameOptions[GameOptionsIndex].modeGroups, 1 do
				if GameOptions[GameOptionsIndex].modeGroups[ModeGroupIndex] == ModeGroup then
					ModeGroupIsValid = true
					break
				end
			end
			if not ModeGroupIsValid then
				GametypeIsValid = false
			end
		end
		if GametypeIsValid then
			local GameOptionsButton = nil
			if GameOptionsType == "gts" then
				GameOptionsButton = PrivateGameLobbyButtonPane.body.buttonList:addGametypeSettingLeftRightSelector(PrivateGameLobbyButtonPane.panelManager.m_ownerController, Engine.Localize(GameOptions[GameOptionsIndex].name), GameOptions[GameOptionsIndex].id, Engine.Localize(GameOptions[GameOptionsIndex].hintText), f13_local1)
			elseif GameOptionsType == "dvar" then 
				GameOptionsButton = PrivateGameLobbyButtonPane.body.buttonList:addDvarLeftRightSelector(PrivateGameLobbyButtonPane.panelManager.m_ownerController, Engine.Localize(GameOptions[GameOptionsIndex].name), GameOptions[GameOptionsIndex].id, Engine.Localize(GameOptions[GameOptionsIndex].hintText), f13_local1)
			end
			for LabelIndex = 1, #GameOptions[GameOptionsIndex].labels, 1 do
				GameOptionsButton:addChoice(PrivateGameLobbyButtonPane.panelManager.m_ownerController, Engine.Localize(GameOptions[GameOptionsIndex].labels[LabelIndex]), GameOptions[GameOptionsIndex].values[LabelIndex])
			end
			GameOptionsButton:registerEventHandler("gain_focus", CoD.PrivateGameLobby.ButtonGainFocusZombie)
			GameOptionsButton:registerEventHandler("lose_focus", CoD.PrivateGameLobby.ButtonLoseFocusZombie)
			GameOptionsButton:registerEventHandler("start_game", GameOptionsButton.disable)
			GameOptionsButton:registerEventHandler("cancel_start_game", GameOptionsButton.enable)
			GameOptionsButton:registerEventHandler("gamelobby_update", CoD.PrivateGameLobby.ButtonGameLobbyUpdate_Zombie)
		end
	end
end

CoD.PrivateGameLobby.PopulateButtons_Project_Zombie = function (PrivateGameLobbyButtonPane, IsHost)
	if IsHost == true then
		-- zm_qol: MAP button now emits "open_change_map" instead of "open_change_startLoc",
		-- so it opens the flat SelectMapListZM list instead of the globe. A CHANGE GAME MODE
		-- button is added alongside it, because the globe flow was previously the only way to
		-- pick the gametype and repointing the map button would otherwise strand it.
		-- Mirrors BO2-Reimagined's PopulateButtons_Project_Zombie.
		PrivateGameLobbyButtonPane.body.changeMapButton = PrivateGameLobbyButtonPane.body.buttonList:addButton(Engine.Localize("ZMUI_MAP_CAPS"))
		PrivateGameLobbyButtonPane.body.changeMapButton.hintText = Engine.Localize("ZMUI_MAP_SELECTION_DESC")
		PrivateGameLobbyButtonPane.body.changeMapButton:setActionEventName("open_change_map")
		PrivateGameLobbyButtonPane.body.changeMapButton:registerEventHandler("button_update", CoD.PrivateGameLobby.Button_UpdateHostButton)
		PrivateGameLobbyButtonPane.body.changeGameModeButton = PrivateGameLobbyButtonPane.body.buttonList:addButton(Engine.Localize("MPUI_CHANGE_GAME_MODE_CAPS"))
		PrivateGameLobbyButtonPane.body.changeGameModeButton.hintText = Engine.Localize("MPUI_CHANGE_GAME_MODE_DESC")
		PrivateGameLobbyButtonPane.body.changeGameModeButton:setActionEventName("open_change_game_mode")
		PrivateGameLobbyButtonPane.body.changeGameModeButton:registerEventHandler("button_update", CoD.PrivateGameLobby.Button_UpdateHostButton)
		-- zm_qol: 1 -> 0.5 (v1.9x) -> 0 (v1.99.27). The hint text sits directly under
		-- the last settings row and follows the list's height, so every row added to
		-- the Dvars table pushes it further down into the map preview panel.
		--
		-- 🛑 THE OLD NOTE HERE SAID "Do NOT take this to 0: a full row up puts the hint
		-- into the CHEATS row." That was written when the list had SEVEN rows. PERK
		-- LIMIT (v1.99.26) made it eight, so the premise is gone: zeroing the spacer now
		-- only gives back the row that was just added. Correcting the note is part of
		-- the change, not a footnote to it.
		--
		-- 🌟 MEASURED FROM THE USER'S SCREENSHOT, not estimated. It is 2000x1125, and
		-- LUI is 1280x720, so 1.5625 px per LUI unit exactly. Scanning the label column
		-- for text bands gives:
		--     row pitch          32.0 units  (8 rows, 202.9 -> 426.9, dead even)
		--     PERK LIMIT row     426.9 - 446.1
		--     hint text          460.2 - 470.4
		--     preview panel top  451.2 - 454.4
		-- so the hint was 8-18 units inside the panel. The spacer is Height * 0.5 and
		-- Height is the 32-unit pitch, so removing it lifts everything below by exactly
		-- 16 units and puts the hint at 444.2 - 454.4.
		--
		-- 📝 That still leaves the hint's bottom ~2 units on the panel's top border
		-- line. Reported rather than glossed: this file cannot move the panel (it is
		-- stock LUI compiled into patch_ui_zm.ff and created in neither this file nor
		-- any file the mod ships), so the remaining options are to reposition the hint
		-- explicitly or to drop a row. Neither is worth doing blind - one more
		-- screenshot measures the result and settles it.
		PrivateGameLobbyButtonPane.body.buttonList:addSpacer(0)
		-- local SetupGameText = Engine.Localize("MPUI_SETUP_GAME_CAPS")
		-- local f9_local1_1, f9_local1_2, f9_local1_3, f9_local1_4 = GetTextDimensions(SetupGameText, CoD.CoD9Button.Font, CoD.CoD9Button.TextHeight)
		-- PrivateGameLobbyButtonPane.body.setupGameButton = PrivateGameLobbyButtonPane.body.buttonList:addButton(SetupGameText)
		-- PrivateGameLobbyButtonPane.body.setupGameButton.hintText = Engine.Localize("MPUI_SETUP_GAME_DESC")
		-- PrivateGameLobbyButtonPane.body.setupGameButton:setActionEventName("open_setup_game_flyout")
		-- PrivateGameLobbyButtonPane.body.setupGameButton:registerEventHandler("button_update", CoD.PrivateGameLobby.Button_UpdateHostButton)
		-- if PrivateGameLobbyButtonPane.body.widestButtonTextWidth < f9_local1_3 then
		-- 	PrivateGameLobbyButtonPane.body.widestButtonTextWidth = f9_local1_3
		-- end
		-- zm_qol v1.99.58 - FIRST, so CHARACTER sits ABOVE DIFFICULTY as the user
		-- asked. Row order on this pane is simply the order they are added, and
		-- DIFFICULTY is GameTypeSettings[1], so nothing short of rendering our
		-- table before that one puts a row above it. Only one of these four rows
		-- can pass the map/mode filters at a time, so this adds exactly one row.
		-- 🛑 v2.2.0 - only when zm_qol is the loaded mod. See ZmQolLobbyModLoaded()
		-- at the top of this file: an older build may still have a copy of this
		-- file sitting in Plutonium's global raw\ folder, where it is shared by
		-- every mod.
		if ZmQolLobbyModLoaded() then
			AddGameOptionsButtons(PrivateGameLobbyButtonPane, CoD.PrivateGameLobby.QolCharacter, "dvar")
		end
		-- ====================================================================
		--  zm_qol v2.3.9 - HELLHOUNDS ROW HIDDEN ON DINER SPECIFICALLY, PER THE
		--  USER'S EXPLICIT ASK: "the hellhound options are still there in the
		--  pre-game menu for diner and nuketown, get rid of them."
		--
		--  GameTypeSettings[5] (id "allowdogs") is STOCK's own row, gated
		--  `.maps[1] = "zm_transit"`. Read AddGameOptionsButtons() itself (this
		--  file has no copy, but BO2-Reimagined's privategamelobby_project.lua
		--  ships one unmodified, confirming the real stock logic): `.maps` is
		--  matched against UIExpression.DvarString(nil, "ui_mapname") - the
		--  MAP dvar - never the LOCATION dvar (ui_zm_mapstartlocation). Diner,
		--  Bus Depot, Farm and Town all set ui_mapname to the same "zm_transit"
		--  (they are locations within one map, picked via the separate
		--  location dvar), so the row's own static table cannot tell them
		--  apart - hiding it there statically would hide it on all four, which
		--  the user does not want (Bus Depot/Farm/Town keep dogs untouched).
		--
		--  The fix mutates the row's .maps list right before it renders, based
		--  on the location dvar this file already reads the same way
		--  elsewhere (selectmaplistzombie.lua:191-192 uses the identical
		--  UIExpression.DvarString(nil, ...) call). An empty .maps table makes
		--  every map fail the match (the loop that would set MapIsValid simply
		--  never runs), so the row does not render at all; a one-element table
		--  restores stock's own behaviour for the other three locations. This
		--  runs on every lobby open, so it is never left in the wrong state
		--  from a previous location.
		--
		--  🛑 NUKETOWN ALREADY SHOWS NO ROW HERE AT ALL. Its own dedicated row
		--  (added v2.1.0) was fully removed in v2.3.4, and Nuketown's ui_mapname
		--  is "zm_nuked" - never a match for GameTypeSettings[5]'s "zm_transit"
		--  entry either. Checked against the byte-identical deployed copy of
		--  this file, not assumed. If a dogs row is still visible on Nuketown,
		--  it is not coming from this function - report exactly what it says.
		-- ====================================================================
		if UIExpression.DvarString(nil, "ui_zm_mapstartlocation") == "diner" then
			CoD.PrivateGameLobby.GameTypeSettings[5].maps = {}
		else
			CoD.PrivateGameLobby.GameTypeSettings[5].maps = {}
			CoD.PrivateGameLobby.GameTypeSettings[5].maps[1] = "zm_transit"
		end
		AddGameOptionsButtons(PrivateGameLobbyButtonPane, CoD.PrivateGameLobby.GameTypeSettings, "gts")
		AddGameOptionsButtons(PrivateGameLobbyButtonPane, CoD.PrivateGameLobby.Dvars, "dvar")
		PrivateGameLobbyButtonPane:registerEventHandler("enable_sliding_zm", CoD.PrivateGameLobby.EnableSlidingZombie)
		PrivateGameLobbyButtonPane.defaultFocusButton = PrivateGameLobbyButtonPane.body.startMatchButton
		PrivateGameLobbyButtonPane.body.buttonList.hintText:setAlpha(1)
		-- zm_qol: stop the hint wrapping onto a second line, which collides with the
		-- map preview panel below it.
		--
		-- The hint sits under the settings list, so its Y follows the row count. This
		-- mod's Dvars table has TWO rows (TARGET ASSIST, CHEATS) where Reimagined's has
		-- one (ui_gametype_pro), so the hint starts one row lower than the stock layout
		-- allows for. At that position line 1 still clears the top of the preview panel
		-- but line 2 is drawn inside it - e.g. "Change the game mode to a traditional or
		-- / custom rule set.", where only "custom rule set." overlaps.
		--
		-- Widening the element so the text fits on one line removes the overlapping line
		-- rather than fighting the vertical layout. Same fix and same 800 width that
		-- Reimagined uses on its options hint (BO2-Reimagined/ui/t6/options.lua:431).
		-- The hint is above the panel, so extending it rightward is free.
		--
		-- If a longer hint ever wraps again, widen further or drop a Dvars row - do NOT
		-- reposition the panel, which is stock LUI compiled into patch_ui_zm.ff and not
		-- editable from here.
		PrivateGameLobbyButtonPane.body.buttonList.hintText:setLeftRight(true, false, 0, 800)

		-- ====================================================================
		--  v1.99.28 - MOVE THE MAP PREVIEW PANEL DOWN, which is what the user
		--  asked for: "just move the image preview down a bit".
		-- --------------------------------------------------------------------
		--  🛑 The note above used to say the panel could not be moved from here.
		--  That was WRONG and is corrected rather than left standing. A string
		--  sweep of the stock `ui/t6/menus/privategamelobby.lua` bytecode
		--  (unlinked from patch_ui_zm.ff) shows it created as
		--  `PrivateGameLobbyButtonPane.body.mapInfoImage`, on the very pane this
		--  function already receives - so it is reachable, just not at the
		--  moment this function runs.
		--
		--  🛑 IT DOES NOT EXIST YET. The same sweep shows the creation happening
		--  AFTER the call to PopulateButtons_Project, i.e. after this function
		--  returns. Hence the timer: it fires once, shortly after, when the
		--  element is there. The event name is mod-specific so it cannot collide
		--  with a stock handler the way reusing gamelobby_update would.
		--
		--  🌟 MEASURED, from the user's screenshots at 2000x1125 (1.5625 px per
		--  LUI unit). Three rounds of it, each one measured rather than nudged
		--  by eye:
		--      v1.99.26  panel 451.2 - 627.8, hint 460.2 - 470.4  (hint 18 in)
		--      v1.99.27  spacer zeroed -> hint 442.2 - 455.7      (hint 4.5 in)
		--      v1.99.28  panel 484.5 - 659.8                      (bottom on ESC)
		--
		--  🛑 THE NUMBERS PASSED HERE ARE NOT SCREEN COORDINATES. v1.99.28 asked
		--  for top 463 and the panel landed at 484.5 - a constant **+21.5**, so
		--  this element is positioned relative to its parent, not the screen. The
		--  requested HEIGHT was honoured exactly (177 asked, 175.3 measured, the
		--  difference being the border). So: pass (target - 21.5).
		--  That offset is the whole reason v1.99.28 overshot, and it could only
		--  be learned by shipping once and measuring the result.
		--
		--  v1.99.29 targets a panel top of ~469.5, chosen from the gap the
		--  measurement exposes: hint bottom 460.8, ESC Back row ~672.
		--      469.5 - 646.5  ->  8.7 units clear of the hint above
		--                         25.5 units clear of ESC Back below
		--  which is the middle of the only band that clears both.
		-- ====================================================================
		local ZmQolPanelNudge = LUI.UITimer.new(50, "zmqol_lobby_panel_nudge", false, PrivateGameLobbyButtonPane)
		PrivateGameLobbyButtonPane:addElement(ZmQolPanelNudge)
		PrivateGameLobbyButtonPane:registerEventHandler("zmqol_lobby_panel_nudge", function (Element, Event)
			if Element.body == nil or Element.body.mapInfoImage == nil then
				return
			end

			--  Once only. The timer repeats, and re-applying an absolute
			--  position every 50 ms would fight anything else that lays the
			--  panel out.
			if Element.body.mapInfoImage.zmqolNudged == true then
				return
			end

			Element.body.mapInfoImage.zmqolNudged = true

			-- ============================================================
			--  v2.1.0 - NINE ROWS ON NUKETOWN SURVIVAL NEED THEIR OWN
			--  PANEL POSITION, and the numbers come straight out of the
			--  measurements above rather than from a nudge by eye.
			--
			--  Adding HELLHOUNDS makes Nuketown survival the only screen in
			--  the game with NINE option rows. Everything else in this file
			--  was measured at EIGHT:
			--        row pitch      32.0 units, dead even
			--        8 rows         202.9 -> 446.1
			--        hint           444.2 -> 460.8   (spacer already zeroed)
			--        panel          469.5 -> 646.5   (8.7 clear above,
			--                                         25.5 clear of ESC ~672)
			--  A ninth row pushes the hint down exactly one pitch, to
			--  476.2 -> 492.8 - which is 23.3 units INSIDE the panel at
			--  469.5. That is the collision, measured, not feared.
			--
			--  🛑 THE PANEL CANNOT SIMPLY MOVE DOWN BY A ROW. Keeping the
			--  8.7-unit clearance puts its top at 501.5, and 501.5 + 177 =
			--  678.5, which is past the ESC Back row at ~672 - exactly the
			--  v1.99.28 failure this block already records ("bottom on ESC").
			--  The band left between the new hint and ESC is 501.5 -> 672,
			--  i.e. 170.5 units, and the panel is 177 tall. It does not fit.
			--
			--  So on this one screen the preview is 155 tall instead of 177:
			--        top    501.5  (8.7 clear of the hint, same as every
			--                       other screen)
			--        bottom 656.5  (15.5 clear of ESC Back)
			--  Requested values are screen minus the constant +21.5 parent
			--  offset this block already establishes: top 480, bottom 635.
			--
			--  🛑 v2.1.3 - EVERYTHING FROM "So on this one screen" DOWN WAS
			--  WRONG, and the user's next screenshot proved it: the panel
			--  had not shrunk at all and the hint was still under it.
			--  THE HEIGHT PASSED HERE IS IGNORED. CoD.MapInfoImage.new
			--  anchors every visible part of the panel to the WIDGET'S
			--  BOTTOM at fixed offsets and reads nothing from its height,
			--  so `top` does nothing and `bottom` alone places it. The row
			--  count was wrong too - this screen draws TWELVE rows, not
			--  nine. The working fix is the size wrapper at the top of this
			--  file; the full measurement and the model are written up
			--  there. The 635 below is kept exactly as it shipped, because
			--  it is what puts the panel's bottom 5 units clear of ESC
			--  Back, and the wrapper only moves the top.
			-- ============================================================
			--  🛑 v2.3.4 - THE zm_nuked BRANCH IS GONE, SAME REASON AS THE SIZE
			--  WRAPPER ABOVE: the Nuketown hellhound row that made this lobby
			--  nine rows is removed, so it no longer needs its own panel
			--  position. Every survival lobby, Nuketown included, now takes
			--  this one path.
			--  448 + 21.5 parent offset = 469.5 on screen; height 177 preserved.
			Element.body.mapInfoImage:setTopBottom(true, false, 448, 625)
		end)
		if CoD.useController == true and not PrivateGameLobbyButtonPane:restoreState() then
			PrivateGameLobbyButtonPane.body.buttonList:selectElementIndex(1)
		end
		-- local ToggleDemoRecording = PrivateGameLobbyButtonPane.body.buttonList:addButton(Engine.Localize("CUSTOM_GAME_RECORDING_CAPS"))
		-- ToggleDemoRecording.hintText = Engine.Localize("CUSTOM_GAME_RECORDING_DESC")
		-- ToggleDemoRecording:registerEventHandler("button_action", CoD.PrivateGameLobby.DemoRecordingButton_ToggleDemoRecording)
		-- local recImage = LUI.UIImage.new()
		-- recImage:setLeftRight(false, true, -130, -100)
		-- recImage:setTopBottom(false, false, -15, 15)
		-- recImage:setAlpha(1)
		-- recImage:setImage(RegisterMaterial("codtv_recording"))
		-- local recText = LUI.UIText.new({
		-- 	leftAnchor = false,
		-- 	rightAnchor = true,
		-- 	left = -100,
		-- 	right = -40,
		-- 	topAnchor = false,
		-- 	bottomAnchor = false,
		-- 	top = -CoD.textSize.Condensed / 2,
		-- 	bottom = CoD.textSize.Condensed / 2,
		-- 	font = CoD.fonts.Condensed,
		-- 	alignment = LUI.Alignment.Left
		-- })
		-- ToggleDemoRecording:addElement(recImage)
		-- ToggleDemoRecording.recImage = recImage
		-- ToggleDemoRecording:addElement(recText)
		-- ToggleDemoRecording.recText = recText
		-- CoD.PrivateGameLobby.UpdateDemoRecordingButton(ToggleDemoRecording)
	else
		PrivateGameLobbyButtonPane.defaultFocusButton = nil
		PrivateGameLobbyButtonPane.body.buttonList.hintText:setAlpha(0)
	end
	if PrivateGameLobbyButtonPane.menuName ~= "TheaterLobby" then
		CoD.GameGlobeZombie.MoveToUpDirectly()
	end
end

CoD.PrivateGameLobby.ButtonGameLobbyUpdate_Zombie = function (GametypeSettingButton, f14_arg1)
	GametypeSettingButton:refreshChoice()
	GametypeSettingButton:dispatchEventToChildren(f14_arg1)
end

CoD.PrivateGameLobby.ButtonGainFocusZombie = function (GametypeSettingButton, ClientInstance)
	CoD.CoD9Button.GainFocus(GametypeSettingButton, ClientInstance)
	GametypeSettingButton:dispatchEventToParent({
		name = "enable_sliding_zm",
		enableSliding = false,
		controller = ClientInstance.controller
	})
end

CoD.PrivateGameLobby.ButtonLoseFocusZombie = function (GametypeSettingButton, ClientInstance)
	CoD.CoD9Button.LoseFocus(GametypeSettingButton, ClientInstance)
	GametypeSettingButton:dispatchEventToParent({
		name = "enable_sliding_zm",
		enableSliding = true,
		controller = ClientInstance.controller
	})
end

CoD.PrivateGameLobby.EnableSlidingZombie = function (f17_arg0, f17_arg1)
	f17_arg0.panelManager.slidingEnabled = f17_arg1.enableSliding
end

CoD.PrivateGameLobby.PopulateButtons_Project = function (PrivateGameLobbyButtonPane, IsHost)
	if CoD.isZombie == true then
		CoD.PrivateGameLobby.PopulateButtons_Project_Zombie(PrivateGameLobbyButtonPane, IsHost)
	else
		CoD.PrivateGameLobby.PopulateButtons_Project_Multiplayer(PrivateGameLobbyButtonPane, IsHost)
	end
end

local LobbyTeamChangeAllowed = function ()
	if Engine.GetGametypeSetting("allowSpectating") == 1 then
		return true
	elseif Engine.GetGametypeSetting("autoTeamBalance") == 1 then
		return false
	elseif CoD.IsGametypeTeamBased() == true then
		if CoD.isZombie == true and Engine.GetGametypeSetting("teamCount") == 1 then
			return false
		else
			return true
		end
	else
		return false
	end
end

CoD.PrivateGameLobby.PopulateButtonPrompts_Project = function (PrivateGameLobbyWidget)
	if PrivateGameLobbyWidget.cycleTeamButtonPrompt ~= nil then
		PrivateGameLobbyWidget.cycleTeamButtonPrompt:close()
	end
	if LobbyTeamChangeAllowed() then
		PrivateGameLobbyWidget.cycleTeamButtonPrompt = CoD.DualButtonPrompt.new("shoulderl", Engine.Localize("MPUI_CHANGE_ROLE"), "shoulderr", PrivateGameLobbyWidget, "button_prompt_team_prev", "button_prompt_team_next", false, nil, nil, nil, nil, "A", "D")
		CoD.PrivateGameLobby.SetupTeamCycling(PrivateGameLobbyWidget)
		PrivateGameLobbyWidget:addRightButtonPrompt(PrivateGameLobbyWidget.cycleTeamButtonPrompt)
		PrivateGameLobbyWidget:registerEventHandler("button_prompt_team_prev", CoD.PrivateGameLobby.ButtonPrompt_TeamPrev)
		PrivateGameLobbyWidget:registerEventHandler("button_prompt_team_next", CoD.PrivateGameLobby.ButtonPrompt_TeamNext)
		PrivateGameLobbyWidget:registerEventHandler("current_panel_changed", CoD.PrivateGameLobby.CurrentPanelChanged)
		PrivateGameLobbyWidget:registerEventHandler("party_update_status", CoD.PrivateGameLobby.ButtonPrompt_PartyUpdateStatus)
	else
		PrivateGameLobbyWidget:registerEventHandler("party_update_status", CoD.GameLobby.UpdateStatusText)
	end
end

CoD.PrivateGameLobby.LeaveLobby_Project_Multiplayer = function (PrivateGameLobbyWidget, ClientInstance)
	Engine.SetDvar("invite_visible", 1)
	Engine.SetGametype(Dvar.ui_gametype:get())
	if Engine.SessionModeIsMode(CoD.SESSIONMODE_OFFLINE) == true or Engine.SessionModeIsMode(CoD.SESSIONMODE_SYSTEMLINK) == true then
		Engine.ExecNow(ClientInstance.controller, "xstopallparties")
		CoD.resetGameModes()
	elseif Engine.SessionModeIsMode(CoD.SESSIONMODE_PRIVATE) == true then
		if UIExpression.PrivatePartyHost(ClientInstance.controller) == 0 or ClientInstance.name ~= nil and ClientInstance.name == "confirm_leave_alone" then
			Engine.ExecNow(ClientInstance.controller, "xstopallparties")
		else
			Engine.ExecNow(ClientInstance.controller, "xstoppartykeeptogether")
		end
		CoD.resetGameModes()
		CoD.StartMainLobby(ClientInstance.controller)
	elseif Engine.IsSignedInToDemonware(ClientInstance.controller) == true and Engine.HasMPPrivileges(ClientInstance.controller) == true then
		Engine.ExecNow(ClientInstance.controller, "xstoppartykeeptogether")
		CoD.resetGameModes()
		CoD.StartMainLobby(ClientInstance.controller)
	else
		Engine.ExecNow(ClientInstance.controller, "xstopprivateparty")
		CoD.resetGameModes()
	end
	Engine.SessionModeSetPrivate(false)
	PrivateGameLobbyWidget:processEvent({
		name = "lose_host"
	})
	PrivateGameLobbyWidget:goBack(ClientInstance)
end

CoD.PrivateGameLobby.LeaveLobby_Project_Zombie_After_Animation = function (PrivateGameLobbyWidget, ClientInstance)
	CoD.PrivateGameLobby.LeaveLobby_Project_Multiplayer(PrivateGameLobbyWidget, {
		name = PrivateGameLobbyWidget.leaveType,
		controller = ClientInstance.controller
	})
	PrivateGameLobbyWidget.leaveType = nil
end

CoD.PrivateGameLobby.LeaveLobby_Project_Zombie = function (PrivateGameLobbyWidget, ClientInstance)
	PrivateGameLobbyWidget.leaveType = ClientInstance.name
	CoD.GameGlobeZombie.gameGlobe.currentMenu = PrivateGameLobbyWidget
	if PrivateGameLobbyWidget.menuName == "TheaterLobby" then
		CoD.GameGlobeZombie.MoveToCornerFromUp(ClientInstance.controller, false)
	else
		CoD.GameGlobeZombie.MoveToCornerFromUp(ClientInstance.controller)
	end
	CoD.PrivateGameLobby.LeaveLobby_Project_Zombie_After_Animation(PrivateGameLobbyWidget, ClientInstance)
end

CoD.PrivateGameLobby.LeaveLobby_Project = function (PrivateGameLobbyWidget, ClientInstance)
	if CoD.isZombie == true then
		CoD.PrivateGameLobby.LeaveLobby_Project_Zombie(PrivateGameLobbyWidget, ClientInstance)
	else
		CoD.PrivateGameLobby.LeaveLobby_Project_Multiplayer(PrivateGameLobbyWidget, ClientInstance)
	end
end

CoD.PrivateGameLobby.OpenChangeStartLoc = function (PrivateGameLobbyWidget, ClientInstance)
	Engine.PartyHostSetUIState(CoD.PARTYHOST_STATE_SELECTING_GAMETYPE)
	local f27_local0 = PrivateGameLobbyWidget:openMenu("SelectStartLocZM", ClientInstance.controller)
	f27_local0:setPreviousMenu("SelectMapZM")
	CoD.SelectStartLocZombie.GoToPreChoices(f27_local0, ClientInstance)
	PrivateGameLobbyWidget:close()
end

CoD.PrivateGameLobby.OpenSetupGameFlyout = function (PrivateGameLobbyWidget, f28_arg1)
	if PrivateGameLobbyWidget.buttonPane ~= nil and PrivateGameLobbyWidget.buttonPane.body ~= nil then
		CoD.PrivateGameLobby.RemoveSetupGameFlyout(PrivateGameLobbyWidget.buttonPane)
		CoD.PrivateGameLobby.AddSetupGameFlyout(PrivateGameLobbyWidget.buttonPane)
		PrivateGameLobbyWidget.panelManager.slidingEnabled = false
		CoD.ButtonList.DisableInput(PrivateGameLobbyWidget.buttonPane.body.buttonList)
		PrivateGameLobbyWidget.buttonPane.body.buttonList:animateToState("disabled")
		PrivateGameLobbyWidget.buttonPane.body.setupGameFlyoutContainer:processEvent({
			name = "gain_focus"
		})
		PrivateGameLobbyWidget:registerEventHandler("button_prompt_back", CoD.PrivateGameLobby.CloseSetupGameFlyout)
	end
end

CoD.PrivateGameLobby.CloseSetupGameFlyout = function (PrivateGameLobbyWidget, f29_arg1)
	if PrivateGameLobbyWidget.buttonPane ~= nil and PrivateGameLobbyWidget.buttonPane.body ~= nil and PrivateGameLobbyWidget.buttonPane.body.setupGameFlyoutContainer ~= nil then
		CoD.PrivateGameLobby.RemoveSetupGameFlyout(PrivateGameLobbyWidget.buttonPane)
		CoD.ButtonList.EnableInput(PrivateGameLobbyWidget.buttonPane.body.buttonList)
		PrivateGameLobbyWidget.buttonPane.body.buttonList:animateToState("default")
		PrivateGameLobbyWidget:registerEventHandler("button_prompt_back", CoD.PrivateGameLobby.ButtonBack)
		PrivateGameLobbyWidget.panelManager.slidingEnabled = true
		Engine.PlaySound("cac_cmn_backout")
	end
end

CoD.PrivateGameLobby.OpenBotsMenu = function (PrivateGameLobbyWidget, ClientInstance)
	Engine.PartyHostSetUIState(CoD.PARTYHOST_STATE_EDITING_GAME_OPTIONS)
	PrivateGameLobbyWidget:openPopup("EditBotOptions", ClientInstance.controller)
	Engine.PlaySound("cac_screen_fade")
end

CoD.PrivateGameLobby.OpenChangeMap = function (PrivateGameLobbyWidget, ClientInstance)
	Engine.PartyHostSetUIState(CoD.PARTYHOST_STATE_SELECTING_MAP)
	PrivateGameLobbyWidget:openPopup("ChangeMap", ClientInstance.controller)
	Engine.PlaySound("cac_screen_fade")
end

CoD.PrivateGameLobby.OpenChangeGameMode = function (PrivateGameLobbyWidget, ClientInstance)
	Engine.PartyHostSetUIState(CoD.PARTYHOST_STATE_SELECTING_GAMETYPE)
	PrivateGameLobbyWidget:openPopup("ChangeGameMode", ClientInstance.controller)
	Engine.PlaySound("cac_screen_fade")
end

CoD.PrivateGameLobby.OpenEditGameOptionsMenu = function (PrivateGameLobbyWidget, ClientInstance)
	Engine.PartyHostSetUIState(CoD.PARTYHOST_STATE_EDITING_GAME_OPTIONS)
	PrivateGameLobbyWidget:openPopup("EditGameOptions", ClientInstance.controller)
	Engine.PlaySound("cac_screen_fade")
end

CoD.PrivateGameLobby.OpenViewGameOptionsMenu = function (PrivateGameLobbyWidget, ClientInstance)
	Engine.PartyHostSetUIState(CoD.PARTYHOST_STATE_EDITING_GAME_OPTIONS)
	PrivateGameLobbyWidget:openPopup("ViewGameOptions", ClientInstance.controller)
end

CoD.PrivateGameLobby.CloseAllPopups = function (PrivateGameLobbyWidget, ClientInstance)
	CoD.PrivateGameLobby.CloseSetupGameFlyout(PrivateGameLobbyWidget, ClientInstance)
	CoD.Menu.MenuChanged(PrivateGameLobbyWidget, ClientInstance)
end

CoD.PrivateGameLobby.RegisterEventHandler_Project = function (PrivateGameLobbyWidget)
	if CoD.isZombie == true then
		PrivateGameLobbyWidget:registerEventHandler("open_change_startLoc", CoD.PrivateGameLobby.OpenChangeStartLoc)
		PrivateGameLobbyWidget:registerEventHandler("open_setup_game_flyout", CoD.PrivateGameLobby.OpenSetupGameFlyout)
		-- zm_qol: these two were commented out in stock (Zombies used the globe via
		-- open_change_startLoc). Re-enabled and pointed at the ZM list-popup handlers
		-- defined at the bottom of this file.
		PrivateGameLobbyWidget:registerEventHandler("open_change_map", CoD.PrivateGameLobby.OpenChangeMapZM)
		PrivateGameLobbyWidget:registerEventHandler("open_change_game_mode", CoD.PrivateGameLobby.OpenChangeGameModeZM)
		PrivateGameLobbyWidget:registerEventHandler("open_editGameOptions_menu", CoD.PrivateGameLobby.OpenEditGameOptionsMenu)
		PrivateGameLobbyWidget:registerEventHandler("open_viewGameOptions_menu", CoD.PrivateGameLobby.OpenViewGameOptionsMenu)
	else
		PrivateGameLobbyWidget:registerEventHandler("open_setup_game_flyout", CoD.PrivateGameLobby.OpenSetupGameFlyout)
		PrivateGameLobbyWidget:registerEventHandler("open_bots_menu", CoD.PrivateGameLobby.OpenBotsMenu)
		PrivateGameLobbyWidget:registerEventHandler("open_change_map", CoD.PrivateGameLobby.OpenChangeMap)
		PrivateGameLobbyWidget:registerEventHandler("open_change_game_mode", CoD.PrivateGameLobby.OpenChangeGameMode)
		PrivateGameLobbyWidget:registerEventHandler("open_editGameOptions_menu", CoD.PrivateGameLobby.OpenEditGameOptionsMenu)
		PrivateGameLobbyWidget:registerEventHandler("open_viewGameOptions_menu", CoD.PrivateGameLobby.OpenViewGameOptionsMenu)
		PrivateGameLobbyWidget:registerEventHandler("close_all_popups", CoD.PrivateGameLobby.CloseAllPopups)
	end
end


-- ============================================================================
--  zm_qol: INSTANT START - skip the lobby "match starting in..." countdown.
--  Added 2026-07-31.
--
--  The stock Start button runs a countdown (the party_gameStartTimerLength*
--  dvars) before it actually launches the match. Overriding ButtonStartGame to
--  Exec "xpartygo" directly is precisely what typing `xpartygo` into the
--  console does by hand: it tells the party to go NOW, bypassing the countdown.
--
--  The base game does not define ButtonStartGame anywhere in this file, so
--  this is a pure addition - every line above is the stock file, unchanged.
--  Technique confirmed against a real working mod (BO2-Reimagined ships the
--  same one-function override).
-- ============================================================================
-- 🛑 zm_qol 2026-08-11: THIS FUNCTION IS NEVER CALLED. "ButtonStartGame" does
-- not appear in ANY stock LUI file (grepped every file in BO2-Raw-files\ui and
-- \ui_mp) nor anywhere in Plutonium's raw\ tree. Stock wires the button as
--     startMatchButton:registerEventHandler("button_action",
--                                           CoD.PrivateGameLobby.Button_StartMatch)
-- read out of privategamelobby.lua's constant table. So the instant-start
-- override above has never actually run, and whatever start behaviour is seen
-- in game is stock's. Left in place rather than removed: it is pre-existing and
-- inert, and removing it is a separate change from the one in flight.
CoD.PrivateGameLobby.ButtonStartGame = function (PrivateGameLobbyButtonPane, ClientInstance)
	Engine.Exec(ClientInstance.controller, "xpartygo")
end


-- ============================================================================
--  zm_qol: CUSTOM SURVIVAL START LOCATIONS - list picker instead of the globe.
--
--  Repoints the lobby's "Change Map" / "Change Game Mode" buttons at the two
--  list popups defined in ui_mp/t6/zombie/selectmaplistzombie.lua, so every
--  survival start location (including the ones this mod's GSC adds - Diner,
--  Power Station, Shopping Mall, Dragon Rooftop, Sweatshop, Borough, Cell Block
--  and The Crazy Place) is pickable from one flat list.
--  Ported from BO2-Reimagined; same pure-override pattern as ButtonStartGame.
--
--  The require is wrapped in pcall per CLAUDE.md rule 5 - a bad require would
--  hard-crash LUI.
--
--  These two are defined UNCONDITIONALLY. RegisterEventHandler_Project (above)
--  now registers them for the Zombies branch, so if they were left nil on a
--  failed require the MAP button would silently do nothing - strictly worse than
--  the stock globe. On failure they fall back to the stock globe handler instead.
-- ============================================================================
local zmQolMapListOk = pcall(require, "T6.Zombie.SelectMapListZombie")

CoD.PrivateGameLobby.OpenChangeMapZM = function (PrivateGameLobbyWidget, ClientInstance)
	if not zmQolMapListOk then
		return CoD.PrivateGameLobby.OpenChangeStartLoc(PrivateGameLobbyWidget, ClientInstance)
	end

	Engine.PartyHostSetUIState(CoD.PARTYHOST_STATE_SELECTING_MAP)
	PrivateGameLobbyWidget:openPopup("SelectMapListZM", ClientInstance.controller)
end

CoD.PrivateGameLobby.OpenChangeGameModeZM = function (PrivateGameLobbyWidget, ClientInstance)
	if not zmQolMapListOk then
		return CoD.PrivateGameLobby.OpenChangeStartLoc(PrivateGameLobbyWidget, ClientInstance)
	end

	Engine.PartyHostSetUIState(CoD.PARTYHOST_STATE_SELECTING_GAMETYPE)
	PrivateGameLobbyWidget:openPopup("SelectGameModeListZM", ClientInstance.controller)
end


-- ============================================================================
--  zm_qol: SKIP THE GLOBE when entering a Custom Game / Solo Zombies lobby.
--
--  Stock sends you to the spinning globe map-picker first and only then to the
--  lobby. Reimagined instead seeds the map/gametype dvars from the saved profile
--  and opens the lobby directly, sliding the globe out of view. Ported from
--  BO2-Reimagined ui_mp/t6/main.lua (OpenCustomGamesLobby / OpenSoloLobby_Zombie
--  / InitMapDvars). zm_qol does not ship its own main.lua, so these overrides
--  live here - a file this project already owns and which is loaded with the
--  lobby. If the list module failed to load we leave stock behaviour alone.
-- ============================================================================
if zmQolMapListOk then
	CoD.MainLobby = CoD.MainLobby or {}

	CoD.MainLobby.InitMapDvars = function (controller)
		local gametype = UIExpression.ProfileValueAsString(controller, CoD.profileKey_gametype)
		local profileMap = UIExpression.ProfileValueAsString(controller, CoD.profileKey_map)
		local map, location
		if profileMap ~= nil then
			map, location = string.match(profileMap, "(.*) (.*)")
		end

		if gametype == nil or map == nil or location == nil then
			gametype = "zclassic"
			map = "zm_transit"
			location = "transit"

			Engine.SetProfileVar(controller, CoD.profileKey_gametype, gametype)
			Engine.SetProfileVar(controller, CoD.profileKey_map, map .. " " .. location)
			Engine.CommitProfileChanges(controller)
		end

		local gametypeTable = CoD.SelectMapListZombie.GameModes
		local gametypeIndex = CoD.SelectMapListZombie.GetKeyValueIndex(gametypeTable, "ui_gametype", gametype)
		local mapTable = {}
		local mapIndex = 1

		if gametype == "zclassic" then
			mapTable = CoD.SelectMapListZombie.Maps
			mapIndex = CoD.SelectMapListZombie.GetKeyValueIndex(mapTable, "ui_mapname", map)
		else
			mapTable = CoD.SelectMapListZombie.Locations
			mapIndex = CoD.SelectMapListZombie.GetKeyValueIndex(mapTable, "ui_zm_mapstartlocation", location)
		end

		Engine.SetDvar("ui_zm_gamemodegroup", gametypeTable[gametypeIndex].ui_zm_gamemodegroup)
		Engine.SetGametype(gametypeTable[gametypeIndex].ui_gametype)
		Engine.SetDvar("ui_mapname", mapTable[mapIndex].ui_mapname)
		Engine.SetDvar("ui_zm_mapstartlocation", mapTable[mapIndex].ui_zm_mapstartlocation)
	end

	CoD.MainLobby.OpenCustomGamesLobby = function (MainLobbyWidget, ClientInstance)
		if CoD.MainLobby.ShouldPreventCreateLobby() then
			return
		elseif CoD.MainLobby.OnlinePlayAvailable(MainLobbyWidget, ClientInstance) == 1
			and CoD.MainLobby.IsControllerCountValid(MainLobbyWidget, ClientInstance.controller,
				UIExpression.DvarInt(ClientInstance.controller, "party_maxlocalplayers_privatematch")) == 1 then
			CoD.SwitchToPrivateLobby(ClientInstance.controller)
			Engine.SetDvar("party_solo", 0)
			if CoD.isZombie == true then
				CoD.MainLobby.InitMapDvars(ClientInstance.controller)
				MainLobbyWidget:openMenu("PrivateOnlineGameLobby", ClientInstance.controller)
				CoD.GameGlobeZombie.MoveToUpDirectly()
			else
				MainLobbyWidget:openMenu("PrivateOnlineGameLobby", ClientInstance.controller)
			end
			MainLobbyWidget:close()
		end
	end

	CoD.MainLobby.OpenSoloLobby_Zombie = function (MainLobbyWidget, ClientInstance)
		if CoD.MainLobby.ShouldPreventCreateLobby() then
			return
		elseif CoD.MainLobby.OnlinePlayAvailable(MainLobbyWidget, ClientInstance) == 1 then
			if CoD.MainLobby.IsControllerCountValid(MainLobbyWidget, ClientInstance.controller, 1) == 1 then
				CoD.SwitchToPrivateLobby(ClientInstance.controller)
				Engine.SetDvar("party_solo", 1)
				Dvar.party_maxplayers:set(1)
				CoD.MainLobby.InitMapDvars(ClientInstance.controller)
				-- zm_qol: re-assert AFTER InitMapDvars. That call ends in
				-- Engine.SetGametype(), which puts party_maxplayers back to the
				-- gametype's cap (4 for zclassic) - so the line above is undone
				-- one line later. Measured: console_zm.log.000/.001 are solo
				-- zm_prison zclassic runs with party_solo "1" and
				-- party_maxplayers "4". Additive only; the ported lines are
				-- untouched. NOT sufficient on its own - the lobby's own New()
				-- resets it again a moment later, which is why the real work is
				-- in privateonlinegamelobby.lua (zmQolForceSoloPartySize).
				Dvar.party_maxplayers:set(1)
				MainLobbyWidget:openMenu("PrivateOnlineGameLobby", ClientInstance.controller)
				CoD.GameGlobeZombie.MoveToUpDirectly()
				MainLobbyWidget:close()
			end
		end
	end
end


-- ============================================================================
--  zm_qol: PREVIEW IMAGE + LOADING SCREEN for the custom start locations.
--
--  NOTHING IS OVERRIDDEN HERE ANY MORE - and that is the fix, not an omission.
--
--  The lobby preview and the loading screen are derived by name:
--      ui/t6/mapinfoimage.lua   GetMapMaterialName(map, location, gamemode)
--                                 -> "menu_"       .. map .. "_zsurvival_" .. location
--      ui_mp/t6/hud/loading.lua GetMapLoadscreenName(map, location, gametype)
--                                 -> "loadscreen_" .. map .. "_zstandard_" .. location
--  (both normalise any non-zclassic gametype, so zgrief resolves to the same
--   name as zstandard/zsurvival - there is no separate grief art to provide.)
--
--  Stock BO2 only ships those materials for transit / farm / town / nuked, so
--  every other row in the list menu asked for a material that does not exist
--  and drew the checkerboard.
--
--  An earlier attempt redirected each new location to the parent map's stock
--  art. That was only ever a partial fix and is now removed:
--    * it silently kept the checkerboard for Die Rise, Buried and Mob, because
--      menu_zm_highrise_zsurvival_rooftop / _buried_zsurvival_street /
--      _prison_zsurvival_cellblock do NOT exist in stock either (verified by
--      unlinking ui_zm.ff and patch_ui_zm.ff), and
--    * it would now override the correct per-map art with a worse match.
--
--  The preview/loadscreen materials are built into mod.ff instead (2 Diner +
--  1 Mob-classic + 14 for the locations restored 2026-09-02) - see
--  zone_source/mod_locations.zone and build_ff.bat. The stock name-deriving
--  functions therefore resolve correctly on their own and are left alone.
-- ============================================================================
