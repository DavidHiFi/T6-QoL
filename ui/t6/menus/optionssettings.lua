require("T6.menus.safeareamenu")

-- ============================================================================
--  🛑 zm_qol v2.2.0 - EVERY ADDITION IN THIS FILE IS GATED ON THE MOD ACTUALLY
--  BEING LOADED.  User, 2026-08-21, with a screenshot: *"I loaded a completely
--  seperate mod from my quality of life mod and some of the stuff from my mod
--  was showing up for some reason, tested multiple mods as well... I also
--  removed the mod with the installer and tried loading up a mod and it still
--  had my mods' options there."*
--
--  🌟 THE CAUSE IS build.bat STEP [6], AND IT IS NOT A MYSTERY.  This project's
--  three frontend .lua files are copied into Plutonium's GLOBAL
--  storage\t6\raw\ folder on every build so the menus exist at boot. raw\ is
--  not per-mod: it shadows Plutonium's own copy for EVERY mod and for no mod at
--  all, and uninstalling zm_qol does not touch it. Confirmed by hashing - the
--  three files in raw\ are byte-identical to this project's copies.
--
--  🌟 AND THE raw\ COPY IS NOT EVEN NEEDED, MEASURED OUT OF console_zm.log.006:
--        523  Loaded menu file: ui_mp/t6/hud/class.lua          <- boot
--        524  Loaded menu file: ui/t6/menus/optionssettings.lua <- boot
--        700  loadmod: loaded mods/zm_qol
--        729  Loading fastfile mod
--        789  Loaded menu file: ui/t6/menus/optionssettings.lua <- AGAIN
--  LUI reloads the frontend menus after a mod loads, and at that point the
--  search path has mods\zm_qol\mod.iwd at rank 1 and raw\ at rank 3, so
--  mod.iwd's copy wins on its own. The same log line is why class.lua has never
--  needed the sync.
--
--  So the fix is two-sided: build.bat no longer writes into raw\, and this
--  guard makes any copy that IS already sitting there behave exactly like
--  Plutonium's original file whenever zm_qol is not the loaded mod. A player
--  who has had an older build synced into raw\ is fixed by the guard alone.
--
--  📝 Dvar.fs_game:get() is PLUTONIUM'S OWN accessor for this, used verbatim in
--  its shipped storage\t6\raw\ui\t6\mods.lua:127 - not an invented call. It is
--  "" with no mod loaded and "mods/zm_qol" with this one; both values are in
--  this install's dvar dumps.
--
--  🛑 IT FAILS OPEN ON PURPOSE. If the read ever throws, the rows are SHOWN.
--  A mod whose entire options menu silently vanished would be a far worse bug
--  than a leaked row, and showing them is exactly what happens today.
-- ============================================================================
ZmQolModLoaded = function ()
	local Ok, Value = pcall(function () return Dvar.fs_game:get() end)

	if not Ok or type(Value) ~= "string" then
		return true
	end

	Value = string.lower(Value)

	return Value == "mods/zm_qol" or Value == "zm_qol"
end

-- ============================================================================
--  zm_qol v1.99.73 - THE "CONTROLS" HEADING IS CENTRED IN GAME.
--
--  User, 2026-08-19, with a screenshot: *"make sure in the controls menu the
--  controls text is centered right above where it says combat, for some reason
--  my mod pushes it off to the left."*
--
--  🛑 THE MOD DID NOT PUSH IT. THIS IS STOCK, AND HERE IS THE PROOF.
--  optionscontrols.lua's in-game branch is
--
--      controlsWidget = CoD.InGameMenu.New( "OptionsControlsMenu",
--                                           localClientIndex,
--                                           Engine.Localize("MENU_CONTROLS_CAPS") )
--
--  and CoD.InGameMenu.New passes that title to addTitle(title) with ONE
--  argument, so CoD.Menu.addTitle(text, alignment) falls back to its default of
--  LUI.Alignment.Left. Its out-of-game branch four lines below passes
--  LUI.Alignment.Center explicitly, which is why the heading is centred at the
--  main menu and left in game. Retail behaviour, on every install.
--
--  What the mod DID do is fix the same fault on ITS OWN menu in v1.95.1 (see the
--  block above LUI.createMenu.OptionsSettingsMenu), which is what made the stock
--  one look wrong by comparison.
--
--  🌟 WHY THIS IS A WRAPPER AND NOT A SHIPPED optionscontrols.lua. Shipping our
--  own copy would SHADOW Plutonium's patched one, and that has already cost this
--  project once - it is what deleted RAW INPUT, MOUSE ACCELERATION and FIX HIGH
--  POLL RATE LAG from the user's CONTROLS menu (checkpoint 48 §4). Wrapping the
--  menu constructor from a file we already ship changes one alignment and
--  nothing else.
--
--  The require is what makes this load-order-proof: LUI.createMenu is populated
--  by the menu file itself, so we pull it in first rather than hoping it is
--  already there. pcall'd because a failed require hard-crashes LUI, and a
--  left-aligned heading is a cosmetic loss rather than a broken menu.
-- ============================================================================
pcall(require, "T6.menus.optionscontrols")

if ZmQolModLoaded() and LUI and LUI.createMenu and LUI.createMenu.OptionsControlsMenu then
	local ZmQolStockControlsMenu = LUI.createMenu.OptionsControlsMenu

	LUI.createMenu.OptionsControlsMenu = function (localClientIndex)
		local controlsWidget = ZmQolStockControlsMenu(localClientIndex)

		if controlsWidget and controlsWidget.titleElement then
			controlsWidget.titleElement:setAlignment(LUI.Alignment.Center)
		end

		return controlsWidget
	end
end

-- ============================================================================
--  zm_qol v1.99.74 - AIM ASSIST, ITS OWN ROW ON CONTROLS > GAMEPAD.
--
--  User, 2026-08-19: *"seperate target assist from aim assist on the gamepad
--  controls menu"*, then *"do the aim assist option under target assist right
--  now."*
--
--  🛑 WHAT THE ROW ACTUALLY REACHES IS NARROWER THAN ITS LABEL, and that is
--  written up in full over zmqol_aim_assist_watch() in quality_of_life.gsc.
--  Short version: it can take aim assist away, it cannot give it back when the
--  player's own TARGET ASSIST is off, because the finer-grained aim_* dvars are
--  strings in t6zm.exe and not registered dvars. It drives the mod's own
--  `aim_assist`, which turns zombies into non-assist targets.
--
--  🌟 IT IS A WRAPPER, NOT A SHIPPED optionscontrols.lua, AND THAT IS THE WHOLE
--  POINT. CoD.OptionsControls.CreateGamepadTab is a plain field on a global
--  table, so it can be wrapped from a file this mod already ships. Shipping our
--  own copy of the menu would shadow Plutonium's patched one - which is exactly
--  what deleted RAW INPUT, MOUSE ACCELERATION and FIX HIGH POLL RATE LAG the
--  last time (checkpoint 48 §4). Proof that copy is stale: the `.aside` in
--  Plutonium's raw folder builds TARGET ASSIST as the SECOND row, while the
--  user's own screenshot shows it SEVENTH, below LOOK SENSITIVITY.
--
--  📝 The row lands at the BOTTOM of the GAMEPAD tab, under everything including
--  TARGET ASSIST. Inserting it directly beneath that one row would mean
--  reordering LUI children after construction, which is not something this
--  project can verify offline - so it is not attempted.
-- ============================================================================
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

if ZmQolModLoaded() and CoD and CoD.OptionsControls and CoD.OptionsControls.CreateGamepadTab then
	local ZmQolStockGamepadTab = CoD.OptionsControls.CreateGamepadTab

	--  🛑 v1.99.75 - THE ROW IS NOW INSERTED DIRECTLY UNDER TARGET ASSIST, AND
	--  IT HAD TO BE DONE THIS WAY. v1.99.74 appended it and it landed under
	--  DEADZONE MIN, which the user reported as *"it looks out of place"*.
	--  CoD.ButtonList has add* methods and removeAllButtons and NOTHING ELSE -
	--  read out of the shipped bytecode's method table in
	--  BO2-Raw-files\ui\t6\buttonlist.lua - so there is no insert-at-index and no
	--  way to reorder after the fact. The only place the row can be put next to
	--  TARGET ASSIST is at the moment TARGET ASSIST itself is added.
	--
	--  So: for the duration of the stock tab build only, the list returned by
	--  CoD.Options.CreateButtonList gets an INSTANCE-level override of
	--  addProfileLeftRightSelector, which shadows the class method. When the row
	--  carrying MENU_TARGET_ASSIST_CAPS goes in, ours goes in straight after.
	--  Both of stock's branches for that row - the normal one and Plutonium's
	--  locked "disabled on this server" one - pass the same label, so matching on
	--  the label catches either.
	--
	--  Everything is restored the instant the stock function returns, so no other
	--  menu in the game sees a patched CreateButtonList.
	CoD.OptionsControls.CreateGamepadTab = function (gamepadTab, localClientIndex)
		local StockCreateButtonList = CoD.Options.CreateButtonList
		local TargetAssistLabel = Engine.Localize("MENU_TARGET_ASSIST_CAPS")
		local AlreadyAdded = false

		CoD.Options.CreateButtonList = function (...)
			local ButtonList = StockCreateButtonList(...)

			if ButtonList and ButtonList.addProfileLeftRightSelector then
				local StockAddSelector = ButtonList.addProfileLeftRightSelector

				ButtonList.addProfileLeftRightSelector = function (SelfList, ClientIndex, Label, VarName, Description)
					local Selector = StockAddSelector(SelfList, ClientIndex, Label, VarName, Description)

					if not AlreadyAdded and Label == TargetAssistLabel and CoD.OptionsSettings and CoD.OptionsSettings.QolToggle then
						AlreadyAdded = true
						CoD.OptionsSettings.QolToggle(
							SelfList,
							ClientIndex,
							"AIM ASSIST",
							"aim_assist",
							"Aim assist on zombies. Separate from Target Assist."
						)

						--  v2.9.15 - TAP TO INTERACT, user request 2026-08-31.
						--  Rides the same insertion point as AIM ASSIST, one row
						--  further down, for the reason written over that row: a
						--  CoD.ButtonList has add* methods and removeAllButtons
						--  and nothing else, so the only place a row can be put
						--  in a chosen position is the moment the row above it is
						--  added.
						--
						--  🛑 v2.9.33 - THE MECHANISM IS TWO BINDS, NOT A DVAR.
						--  The first cut set g_useholdtime; the v2.9.31 boot
						--  proved that dvar DOES NOT EXIST in T6 (absent from the
						--  live 3,153-dvar dump AND from t6zm.exe's strings -
						--  Treyarch removed it after T5). The working route is
						--  the user's own find (a Buried high-rounds video):
						--  split the pad's combined use/reload button across the
						--  engine's two bind slots -
						--      bind  BUTTON_X "+reload"
						--      bind2 BUTTON_X "+activate"
						--  so a tap fires +activate instantly. All pieces
						--  verified: bind2/unbind2/+activate are in t6zm.exe,
						--  stock itself uses bind2 (bind2 4 "+reload" in the
						--  user's bindings_zm.bdg), stock's BUTTON_X row is
						--  `bind BUTTON_X "+usereload"` with no bind2 - which is
						--  exactly what OFF restores. Binds persist in the
						--  PER-MOD bindings file (players\mods\zm_qol\), so the
						--  stock profile is never touched.
						--
						--  v2.10.2 - the flip now applies through the selector's OWN
						--  choice callback (stock addChoice's 5th argument, which
						--  replaces DvarLeftRightSelector's default Engine.SetDvar
						--  callback), so there is no event routing between the
						--  press and the bind. The v2.9.33 selector_changed handler
						--  is gone; see ZmQolApplyTapToInteract's header above for
						--  why the flip alone was never enough.
						local TapSelector = SelfList:addDvarLeftRightSelector(
							ClientIndex,
							Engine.Localize("TAP TO INTERACT"),
							"tap_to_interact",
							Engine.Localize("Tap to interact instantly instead of holding. The same button still reloads.")
						)
						local TapChoice = function (Params, UserRequested)
							Engine.SetDvar(Params.parentSelectorButton.m_dvarName, Params.value)
							--  Stock also runs this callback on a silent refresh
							--  (menu open). Re-applying ON there is free; only a
							--  real flip may write the OFF restore.
							if UserRequested == true or tostring(Params.value) == "1" then
								pcall(ZmQolApplyTapToInteract, ClientIndex, Params.value, "menu")
							end
						end
						TapSelector:addChoice(ClientIndex, Engine.Localize("MENU_DISABLED_CAPS"), 0, nil, TapChoice)
						TapSelector:addChoice(ClientIndex, Engine.Localize("MENU_ENABLED_CAPS"), 1, nil, TapChoice)
						CoD.OptionsSettings.QolArchive("tap_to_interact")
					end

					return Selector
				end
			end

			return ButtonList
		end

		local Ok, GamepadContainer = pcall(ZmQolStockGamepadTab, gamepadTab, localClientIndex)

		--  Restored before anything can go wrong with the result, and restored
		--  even if the stock builder threw - a patched global left behind would
		--  follow every other menu in the game.
		CoD.Options.CreateButtonList = StockCreateButtonList

		if not Ok then
			return ZmQolStockGamepadTab(gamepadTab, localClientIndex)
		end

		return GamepadContainer
	end
end

CoD.OptionsSettings = {}
CoD.OptionsSettings.CurrentTabIndex = 1
CoD.OptionsSettings.NeedVidRestart = false
CoD.OptionsSettings.NeedPicmip = false
CoD.OptionsSettings.NeedSndRestart = false
CoD.OptionsSettings.ResetRestartFlags = function ()
	CoD.OptionsSettings.NeedVidRestart = false
	CoD.OptionsSettings.NeedPicmip = false
	CoD.OptionsSettings.NeedSndRestart = false
end

CoD.OptionsSettings.LeaveApplyPopup_DeclineApply = function (f2_arg0, ClientInstance)
	f2_arg0:setPreviousMenu("OptionsMenu")
	CoD.OptionsSettings.ResetRestartFlags()
	f2_arg0:goBack(ClientInstance.controller)
end

CoD.OptionsSettings.ApplyPopup_DeclineApply = function (f3_arg0, ClientInstance)
	CoD.OptionsSettings.ResetRestartFlags()
	f3_arg0:goBack(ClientInstance.controller)
end

CoD.OptionsSettings.ApplyPopup_ApplyChanges = function (f4_arg0, ClientInstance)
	CoD.OptionsSettings.ApplyChanges()
	f4_arg0:goBack(ClientInstance.controller)
end

CoD.OptionsSettings.Back = function (f5_arg0, ClientInstance)
	if CoD.OptionsSettings.NeedVidRestart or CoD.OptionsSettings.NeedPicmip or CoD.OptionsSettings.NeedSndRestart then
		local f5_local0 = f5_arg0:openMenu("LeaveApplyConfirmPopup", ClientInstance.controller)
		f5_local0:registerEventHandler("confirm_action", CoD.OptionsSettings.ApplyPopup_ApplyChanges)
		f5_local0:registerEventHandler("decline_action", CoD.OptionsSettings.LeaveApplyPopup_DeclineApply)
		f5_arg0:close()
	else
		CoD.Options.UpdateWindowPosition()
		Engine.Exec(ClientInstance.controller, "updategamerprofile")
		Engine.SaveHardwareProfile()
		Engine.ApplyHardwareProfileSettings()
		f5_arg0:goBack(ClientInstance.controller)
	end
end

CoD.OptionsSettings.TabChanged = function (OptionsSettingsWidget, SettingsTab)
	OptionsSettingsWidget.buttonList = OptionsSettingsWidget.tabManager.buttonList
	local NextFocusableTab = OptionsSettingsWidget.buttonList:getFirstChild()
	while not NextFocusableTab.m_focusable do
		NextFocusableTab = NextFocusableTab:getNextSibling()
	end
	if NextFocusableTab ~= nil then
		NextFocusableTab:processEvent({
			name = "gain_focus"
		})
	end
	CoD.OptionsSettings.CurrentTabIndex = SettingsTab.tabIndex
end

CoD.OptionsSettings.SelectorChanged = function (OptionsMenuTab, SelectorChangedEventTable)
	if SelectorChangedEventTable.userRequested ~= true then
		return 
	end
	local SelectorChoices = OptionsMenuTab.buttonList.m_selectors
	local SelectorChanged = SelectorChangedEventTable.selector
	local OptionChanged = SelectorChanged.m_profileVarName
	if OptionChanged == "r_fullscreen" and SelectorChoices.r_monitor ~= nil and SelectorChoices.r_mode ~= nil then
		local FullscreenMode = SelectorChanged:getCurrentValue()
		local MonitorChoices = SelectorChoices.r_monitor
		local DisplayResolutionChoices = SelectorChoices.r_mode
		if FullscreenMode == "0" then
			MonitorChoices:setChoice(0)
			MonitorChoices:disableSelector()
			DisplayResolutionChoices:enableSelector()
		elseif FullscreenMode == "2" then
			MonitorChoices:enableSelector()
			DisplayResolutionChoices:disableSelector()
		else
			MonitorChoices:enableSelector()
			DisplayResolutionChoices:enableSelector()
		end
	end
	if OptionChanged == "r_vsync" and SelectorChoices.com_maxfps ~= nil then
		local MaxFPSSelector = SelectorChoices.com_maxfps
		if SelectorChanged:getCurrentValue() == "1" then
			MaxFPSSelector:setChoice(0)
			MaxFPSSelector:disableSelector()
		else
			MaxFPSSelector:enableSelector()
		end
	end
	if OptionChanged == "r_monitor" and SelectorChoices.r_mode ~= nil then
		CoD.OptionsSettings.Button_AddChoices_Resolution(SelectorChoices.r_mode)
	end
	if OptionChanged == "r_fullscreen" or OptionChanged == "r_mode" or OptionChanged == "r_aaSamples" or OptionChanged == "r_monitor" or OptionChanged == "r_texFilterQuality" then
		CoD.OptionsSettings.NeedVidRestart = true
		OptionsMenuTab:addApplyPrompt()
	end
	if OptionChanged == "r_picmip" then
		CoD.OptionsSettings.NeedPicmip = true
		OptionsMenuTab:addApplyPrompt()
	end
	if OptionChanged == "sd_xa2_device_name" then
		CoD.OptionsSettings.NeedSndRestart = true
		OptionsMenuTab:addApplyPrompt()
	end
end

CoD.OptionsSettings.ResolutionChanged = function (OptionsMenuTab, ClientInstance)
	CoD.OptionsSettings.RefreshMenu(OptionsMenuTab)
	CoD.Menu.ResolutionChanged(OptionsMenuTab, ClientInstance)
end

CoD.OptionsSettings.OpenBrightness = function (f9_arg0, ClientInstance)
	f9_arg0:saveState()
	f9_arg0:openMenu("Brightness", ClientInstance.controller)
	f9_arg0:close()
	CoD.OptionsSettings.DoNotSyncProfile = true
end

CoD.OptionsSettings.OpenMatureContent = function ( f10_arg0, f10_arg1 )
	f10_arg0:saveState()
	f10_arg0:openMenu( "MatureContentPopup", f10_arg1.controller )
	f10_arg0:close()
	CoD.OptionsSettings.DoNotSyncProfile = true
end

CoD.OptionsSettings.OpenApplyPopup = function (f11_arg0, ClientInstance)
	local f11_local0 = f11_arg0:openMenu("ApplyChangesPopup", ClientInstance.controller)
	f11_local0:registerEventHandler("confirm_action", CoD.OptionsSettings.ApplyPopup_ApplyChanges)
	f11_local0:registerEventHandler("decline_action", CoD.OptionsSettings.ApplyPopup_DeclineApply)
	f11_arg0:close()
end

CoD.OptionsSettings.OpenDefaultPopup = function (f12_arg0, ClientInstance)
	local f12_local0 = f12_arg0:openMenu("SetDefaultPopup", ClientInstance.controller)
	f12_local0:registerEventHandler("confirm_action", CoD.OptionsSettings.DefaultPopup_RestoreDefaultSettings)
	f12_local0:registerEventHandler("decline_action", CoD.OptionsSettings.DefaultPopup_Decline)
	f12_arg0:close()
end

CoD.OptionsSettings.ApplyChanges = function ()
	CoD.Options.UpdateWindowPosition()
	Engine.SaveHardwareProfile()
	Engine.ApplyHardwareProfileSettings()
	if CoD.OptionsSettings.NeedPicmip then
		Engine.Exec(nil, "r_applyPicmip")
	end
	if CoD.OptionsSettings.NeedVidRestart then
		Engine.Exec(nil, "vid_restart")
	end
	if CoD.OptionsSettings.NeedSndRestart then
		Engine.Exec(nil, "snd_restart")
	end
	CoD.OptionsSettings.ResetRestartFlags()
end

CoD.OptionsSettings.ResetSoundToDefault = function (LocalClientIndex)
	Engine.SetProfileVar(LocalClientIndex, "snd_menu_voice", 1)
	Engine.SetProfileVar(LocalClientIndex, "snd_menu_music", 1)
	Engine.SetProfileVar(LocalClientIndex, "snd_menu_sfx", 1)
	Engine.SetProfileVar(LocalClientIndex, "snd_menu_master", 1)
	Engine.SetProfileVar(LocalClientIndex, "snd_shoutcast_game", 0.25)
	Engine.SetProfileVar(LocalClientIndex, "snd_shoutcast_voip", 1)
	Engine.SetProfileVar(LocalClientIndex, "snd_menu_headphones", 0)
	Engine.SetProfileVar(LocalClientIndex, "snd_menu_hearing_impaired", 0)
	Engine.SetProfileVar(LocalClientIndex, "snd_menu_presets", CoD.AudioSettings.TREYARCH_MIX)
end

CoD.OptionsSettings.ResetGameToDefault = function (LocalClientIndex)
	Engine.SetProfileVar(LocalClientIndex, "team_indicator", 0)
	Engine.SetProfileVar(LocalClientIndex, "colorblind_assist", 0)
	Engine.SetHardwareProfileValue("cg_drawLagometer", 0)
	Engine.SetProfileVar(LocalClientIndex, "safeAreaTweakable_vertical", 1)
	Engine.SetProfileVar(LocalClientIndex, "safeAreaTweakable_horizontal", 1)
	Engine.SetProfileVar(LocalClientIndex, "r_gamma", 0.9)
end

CoD.OptionsSettings.ResetDvars = function (LocalClientIndex)
	Engine.Exec(LocalClientIndex, "reset r_fullscreen")
	Engine.Exec(LocalClientIndex, "reset r_vsync")
	Engine.Exec(LocalClientIndex, "reset r_picmip_manual")
	Engine.Exec(LocalClientIndex, "reset r_dofHDR")
	Engine.Exec(LocalClientIndex, "reset cg_chatHeight")
	Engine.Exec(LocalClientIndex, "reset cg_fov_default")
	Engine.Exec(LocalClientIndex, "reset cg_fovscale")
	Engine.Exec(LocalClientIndex, "reset com_maxfps")
	Engine.Exec(LocalClientIndex, "reset cg_drawFPS")
	Engine.SetDvar("sd_xa2_device_name", 0)
	Engine.SetDvar("sd_xa2_device_guid", 0)
end

CoD.OptionsSettings.DefaultPopup_RestoreDefaultSettings = function (f17_arg0, ClientInstance)
	CoD.OptionsSettings.ResetDvars(ClientInstance.controller)
	Engine.ResetHardwareProfileSettings(ClientInstance.controller)
	Engine.Exec(ClientInstance.controller, "r_applyPicmip")
	Engine.Exec(ClientInstance.controller, "vid_restart")
	Engine.Exec(ClientInstance.controller, "snd_restart")
	CoD.OptionsSettings.ResetSoundToDefault(ClientInstance.controller)
	CoD.OptionsSettings.ResetGameToDefault(ClientInstance.controller)
	Engine.SaveHardwareProfile()
	f17_arg0:goBack(ClientInstance.controller)
end

CoD.OptionsSettings.Button_ApplyDvarChanged = function (Button)
	Engine.SetDvar(Button.parentSelectorButton.m_dvarName, Button.value)
end

CoD.OptionsSettings.DefaultPopup_Decline = function (f18_arg0, ClientInstance)
	CoD.OptionsSettings.DoNotSyncProfile = true
	f18_arg0:goBack(ClientInstance.controller)
end

CoD.OptionsSettings.RefreshMenu = function (OptionsMenuTab)
	Engine.SyncHardwareProfileWithDvars()
	OptionsMenuTab:dispatchEventToChildren({
		name = "refresh_choice"
	})
	local SelectorChoices = OptionsMenuTab.buttonList.m_selectors
	local SelectorChoicesTextureQuality = SelectorChoices.r_picmip
	if Engine.GetHardwareProfileValueAsString("r_picmip_manual") == "0" and SelectorChoicesTextureQuality ~= nil then
		SelectorChoicesTextureQuality:setChoice(-1)
	end
	local SelectorChoicesShadows = SelectorChoices.sm_spotQuality
	if Engine.GetHardwareProfileValueAsString("sm_enable") == "0" and SelectorChoicesShadows ~= nil then
		SelectorChoicesShadows:setChoice(-1)
	end
	local SelectorChoicesAntiAliasing = SelectorChoices.r_aaSamples
	if SelectorChoicesAntiAliasing ~= nil then
		CoD.OptionsSettings.AdjustAntiAliasingSettings(SelectorChoicesAntiAliasing)
	end
	local SelectorChoicesResolution = SelectorChoices.r_mode
	if SelectorChoicesResolution then
		CoD.OptionsSettings.Button_AddChoices_Resolution(SelectorChoicesResolution)
	end
	local FullscreenMode = Engine.GetHardwareProfileValueAsString("r_fullscreen")
	local SelectorChoicesMonitors = SelectorChoices.r_monitor
	local SelectorChoicesResolution = SelectorChoices.r_mode
	if SelectorChoicesMonitors and SelectorChoicesResolution then
		if FullscreenMode == "0" then
			SelectorChoicesMonitors:setChoice(0)
			SelectorChoicesMonitors:disableSelector()
			SelectorChoicesResolution:enableSelector()
		elseif FullscreenMode == "2" then
			SelectorChoicesMonitors:enableSelector()
			SelectorChoicesResolution:disableSelector()
		else
			SelectorChoicesMonitors:enableSelector()
			SelectorChoicesResolution:enableSelector()
		end
	end
end

CoD.OptionsSettings.DisableOptionsInGame = function (Options)
	for Key, GraphicsSetting in ipairs({
		"r_mode",
		"r_fullscreen",
		"r_monitor",
		"r_aaSamples",
		"r_texFilterQuality",
		"r_picmip"
	}) do
		if Options[GraphicsSetting] then
			Options[GraphicsSetting]:disableSelector()
		end
	end
end

CoD.OptionsSettings.Button_AddChoices_Resolution = function (DisplayResolutionChoices)
	local ResolutionChoices = nil
	DisplayResolutionChoices:clearChoices()
	if Dvar.r_fullscreen:get() == 0 then
		for Key, DisplayResolutionChoice in ipairs(Dvar.r_mode:getDomainEnumStrings()) do
			DisplayResolutionChoices:addChoice(DisplayResolutionChoice, DisplayResolutionChoice)
		end
	else
		local MonitorIndex = Engine.GetHardwareProfileValueAsString("r_monitor")
		if tonumber(MonitorIndex) > Dvar.r_monitorCount:get() then
			MonitorIndex = "0"
		end
		if MonitorIndex == "0" then
			ResolutionChoices = Dvar.r_mode:getDomainEnumStrings()
		else
			ResolutionChoices = Dvar["r_mode" .. MonitorIndex]:getDomainEnumStrings()
		end
		for Key, DisplayResolutionChoice in ipairs(ResolutionChoices) do
			DisplayResolutionChoices:addChoice(DisplayResolutionChoice, DisplayResolutionChoice)
		end
	end
end

CoD.OptionsSettings.Button_AddChoices_DisplayMode = function (DisplayModeChoices)
	DisplayModeChoices:addChoice(Engine.Localize("PLATFORM_WINDOWED"), 0)
	DisplayModeChoices:addChoice(Engine.Localize("MENU_FULLSCREEN"), 1)
	DisplayModeChoices:addChoice(Engine.Localize("PLATFORM_WINDOWED_FULLSCREEN"), 2)
end

CoD.OptionsSettings.AdjustAntiAliasingSettings = function (AntiAliasingChoices)
	local AASamples = Engine.GetHardwareProfileValueAsString("r_aaSamples")
	if Dvar.r_txaaSupported:get() == true and Engine.GetHardwareProfileValueAsString("r_txaa") == "1" then
		if AASamples == "2" then
			AntiAliasingChoices:setChoice(17)
		elseif AASamples == "4" then
			AntiAliasingChoices:setChoice(18)
		end
	else
		Engine.SetHardwareProfile("r_txaa", 0)
	end
end

CoD.OptionsSettings.AntiAliasingChangeCallback = function (AntiAliasingChosen, f24_arg1)
	if f24_arg1 ~= true then
		return 
	elseif AntiAliasingChosen.value <= 16 then
		Engine.SetHardwareProfileValue("r_aaSamples", AntiAliasingChosen.value)
		Engine.SetHardwareProfileValue("r_txaa", 0)
	elseif AntiAliasingChosen.value == 17 then
		Engine.SetHardwareProfileValue("r_aaSamples", 2)
		Engine.SetHardwareProfileValue("r_txaa", 1)
		Engine.SetHardwareProfileValue("r_fxaa", 0)
	elseif AntiAliasingChosen.value == 18 then
		Engine.SetHardwareProfileValue("r_aaSamples", 4)
		Engine.SetHardwareProfileValue("r_txaa", 1)
		Engine.SetHardwareProfileValue("r_fxaa", 0)
	else
		Engine.SetHardwareProfileValue("r_aaSamples", 1)
		Engine.SetHardwareProfileValue("r_txaa", 0)
		Engine.SetHardwareProfileValue("r_fxaa", 0)
	end
	-- ========================================================================
	--  v2.8.2 - ARCHIVE THE THREE AA DVARS. User, 2026-08-29: anti-aliasing set
	--  to 4X TXAA with FXAA YES in the pre-game ADVANCED tab comes back as MSAA
	--  with FXAA off once in game.
	--
	--  🌟 THE MEASURED GAP: their plutonium_zm.cfg carries
	--        seta r_aaSamples "4"
	--        seta r_fxaa      "1"
	--  and carries NO r_txaa line at all. Every branch above writes r_txaa, but
	--  only two of the three names come back on the next launch - so a TXAA
	--  choice is the one that cannot survive.
	--
	--  🛑 AND THE LOSS IS ACTIVELY DESTRUCTIVE, not merely forgetful.
	--  AdjustAntiAliasingSettings() a few lines above runs every time this tab
	--  is built and its else-branch writes r_txaa 0 whenever it does not read
	--  back "1" - so one unarchived launch does not just forget the setting, it
	--  overwrites it.
	--
	--  Writing all three through the mod's existing archiver closes that gap.
	--  It is purely additive: the game already archives two of these names, so
	--  this adds one config line and changes no behaviour otherwise.
	--
	--  🛑 WHAT THIS DOES NOT YET EXPLAIN, stated rather than papered over: the
	--  user reported MSAA *x8*, while their saved r_aaSamples is 4. The row
	--  reads Engine.GetHardwareProfileValueAsString(), i.e. the auto-detected
	--  HARDWARE PROFILE, not the dvar - and r_aaSamplesMax on this install is 8.
	--  If the profile is what wins in game, archiving alone will not be enough
	--  and the next step is a per-launch re-apply. The console readings of
	--  r_aaSamples / r_txaa / r_fxaa taken IN a match are what tell the two
	--  apart, which is why they were asked for.
	-- ========================================================================
	pcall(function ()
		CoD.OptionsSettings.QolArchive("r_aaSamples")
		CoD.OptionsSettings.QolArchive("r_txaa")
		CoD.OptionsSettings.QolArchive("r_fxaa")
	end)
end

CoD.OptionsSettings.Button_AddChoices_AntiAliasing = function (AntiAliasingChoices)
	AntiAliasingChoices:addChoice(Engine.Localize("MENU_OFF_CAPS"), 1, nil, CoD.OptionsSettings.AntiAliasingChangeCallback)
	AntiAliasingChoices:addChoice(Engine.Localize("PLATFORM_2X_MSAA_CAPS"), 2, nil, CoD.OptionsSettings.AntiAliasingChangeCallback)
	AntiAliasingChoices:addChoice(Engine.Localize("PLATFORM_4X_MSAA_CAPS"), 4, nil, CoD.OptionsSettings.AntiAliasingChangeCallback)
	AntiAliasingChoices:addChoice(Engine.Localize("PLATFORM_8X_MSAA_CAPS"), 8, nil, CoD.OptionsSettings.AntiAliasingChangeCallback)
	if Dvar.r_txaaSupported:get() == true then
		AntiAliasingChoices:addChoice(Engine.Localize("PLATFORM_2X_TXAA_CAPS"), 17, nil, CoD.OptionsSettings.AntiAliasingChangeCallback)
		AntiAliasingChoices:addChoice(Engine.Localize("PLATFORM_4X_TXAA_CAPS"), 18, nil, CoD.OptionsSettings.AntiAliasingChangeCallback)
	end
end

CoD.OptionsSettings.Button_AddChoices_TextureFiltering = function (TextureFilteringChoices)
	TextureFilteringChoices:addChoice(Engine.Localize("PLATFORM_LOW_CAPS"), 0)
	TextureFilteringChoices:addChoice(Engine.Localize("PLATFORM_MEDIUM_CAPS"), 1)
	TextureFilteringChoices:addChoice(Engine.Localize("PLATFORM_HIGH_CAPS"), 2)
end

CoD.OptionsSettings.TextureQualitySelectionChangeCallback = function (TextureQualityChosen, f27_arg1)
	if f27_arg1 ~= true then
		return 
	elseif TextureQualityChosen.value == -1 then
		Engine.SetHardwareProfileValue("r_picmip_manual", 0)
	else
		Engine.SetHardwareProfileValue("r_picmip_manual", 1)
		Engine.SetHardwareProfileValue("r_picmip", TextureQualityChosen.value)
		Engine.SetHardwareProfileValue("r_picmip_bump", TextureQualityChosen.value)
		Engine.SetHardwareProfileValue("r_picmip_spec", TextureQualityChosen.value)
	end
end

CoD.OptionsSettings.Button_AddChoices_TextureQuality = function (TextureQualityChoices)
	TextureQualityChoices:addChoice(Engine.Localize("MENU_AUTOMATIC_CAPS"), -1, nil, CoD.OptionsSettings.TextureQualitySelectionChangeCallback)
	TextureQualityChoices:addChoice(Engine.Localize("PLATFORM_LOW_CAPS"), 3, nil, CoD.OptionsSettings.TextureQualitySelectionChangeCallback)
	TextureQualityChoices:addChoice(Engine.Localize("MENU_NORMAL_CAPS"), 2, nil, CoD.OptionsSettings.TextureQualitySelectionChangeCallback)
	TextureQualityChoices:addChoice(Engine.Localize("PLATFORM_HIGH_CAPS"), 1, nil, CoD.OptionsSettings.TextureQualitySelectionChangeCallback)
	TextureQualityChoices:addChoice(Engine.Localize("MENU_EXTRA_CAPS"), 0, nil, CoD.OptionsSettings.TextureQualitySelectionChangeCallback)
end

CoD.OptionsSettings.ShadowsChangeCallback = function (ShadowSettingChosen, f29_arg1)
	if f29_arg1 ~= true then
		return 
	elseif ShadowSettingChosen.value == -1 then
		Engine.SetHardwareProfileValue("sm_enable", 0)
		Engine.SetHardwareProfileValue("sm_spotQuality", 0)
		Engine.SetHardwareProfileValue("sm_sunQuality", 0)
	else
		Engine.SetHardwareProfileValue("sm_enable", 1)
		Engine.SetHardwareProfileValue("sm_spotQuality", ShadowSettingChosen.value)
		Engine.SetHardwareProfileValue("sm_sunQuality", ShadowSettingChosen.value)
	end
end

CoD.OptionsSettings.Button_AddChoices_Shadows = function (ShadowChoices)
	ShadowChoices:addChoice(Engine.Localize("MENU_OFF_CAPS"), -1, nil, CoD.OptionsSettings.ShadowsChangeCallback)
	ShadowChoices:addChoice(Engine.Localize("PLATFORM_LOW_CAPS"), 0, nil, CoD.OptionsSettings.ShadowsChangeCallback)
	ShadowChoices:addChoice(Engine.Localize("PLATFORM_MEDIUM_CAPS"), 1, nil, CoD.OptionsSettings.ShadowsChangeCallback)
	ShadowChoices:addChoice(Engine.Localize("PLATFORM_HIGH_CAPS"), 2, nil, CoD.OptionsSettings.ShadowsChangeCallback)
end

CoD.OptionsSettings.Button_PlayerNameIndicator_SelectionChanged = function (PlayerNameIndicatorChoice)
	Engine.SetProfileVar(PlayerNameIndicatorChoice.parentSelectorButton.m_currentController, PlayerNameIndicatorChoice.parentSelectorButton.m_profileVarName, PlayerNameIndicatorChoice.value)
	PlayerNameIndicatorChoice.parentSelectorButton.hintText = PlayerNameIndicatorChoice.extraParams.associatedHintText
	local f31_local0 = PlayerNameIndicatorChoice.parentSelectorButton:getParent()
	if f31_local0 ~= nil and f31_local0.hintText ~= nil then
		f31_local0.hintText:updateText(PlayerNameIndicatorChoice.parentSelectorButton.hintText)
	end
end

CoD.OptionsSettings.Button_AddChoices_PlayerNameIndicator = function (PlayerNameIndicatorChoices)
	PlayerNameIndicatorChoices:addChoice(Engine.Localize("PLATFORM_INDICATOR_FULL_CAPS"), 0, {
		associatedHintText = Engine.Localize("PLATFORM_INDICATOR_FULL_DESC")
	}, CoD.OptionsSettings.Button_PlayerNameIndicator_SelectionChanged)
	PlayerNameIndicatorChoices:addChoice(Engine.Localize("MENU_INDICATOR_ABBREVIATED_CAPS"), 1, {
		associatedHintText = Engine.Localize("PLATFORM_INDICATOR_ABBREVIATED_DESC")
	}, CoD.OptionsSettings.Button_PlayerNameIndicator_SelectionChanged)
	PlayerNameIndicatorChoices:addChoice(Engine.Localize("MENU_INDICATOR_ICON_CAPS"), 2, {
		associatedHintText = Engine.Localize("MENU_INDICATOR_ICON_DESC")
	}, CoD.OptionsSettings.Button_PlayerNameIndicator_SelectionChanged)
end

CoD.OptionsSettings.Button_AddChoices_ChatHeight = function (ChatHeightChoices)
	ChatHeightChoices:addChoice(Engine.Localize("MENU_SHOW_CAPS"), 8)
	ChatHeightChoices:addChoice(Engine.Localize("MENU_HIDE_CAPS"), 0)
end

CoD.OptionsSettings.Button_AddChoices_SoundDevices = function (SoundDeviceChoices)
	for Key, SoundDeviceFullName in ipairs(Dvar.sd_xa2_device_name:getDomainEnumStrings()) do
		local SoundDeviceOption = SoundDeviceFullName
		if string.len(SoundDeviceFullName) > 32 then
			SoundDeviceOption = string.sub(SoundDeviceFullName, 1, 32) .. "..."
		end
		SoundDeviceChoices:addChoice(SoundDeviceOption, SoundDeviceFullName)
	end
end

CoD.OptionsSettings.Button_AddChoices_Monitor = function (MonitorChoices)
	local MonitorCount = Dvar.r_monitorCount:get()
	for MonitorOption = 1, MonitorCount, 1 do
		MonitorChoices:addChoice(MonitorOption, MonitorOption)
	end
end

CoD.OptionsSettings.Button_AddChoices_MaxCorpses = function (MaxCorpsesChoices)
	MaxCorpsesChoices:addChoice(Engine.Localize("MENU_TINY"), 3)
	MaxCorpsesChoices:addChoice(Engine.Localize("MENU_SMALL"), 5)
	MaxCorpsesChoices:addChoice(Engine.Localize("MENU_MEDIUM"), 10)
	MaxCorpsesChoices:addChoice(Engine.Localize("MENU_LARGE"), 16)
end

CoD.OptionsSettings.DrawFPSCallback = function (FPSDisplayed, f37_arg1)
	if f37_arg1 ~= true then
		return 
	else
		Engine.SetDvar("cg_drawFPS", FPSDisplayed.value)
		Engine.SetHardwareProfileValue("cg_drawFPS", FPSDisplayed.value)
	end
end

CoD.OptionsSettings.Button_AddChoices_DrawFPS = function (DrawFPSToggle)
	DrawFPSToggle:addChoice(Engine.Localize("MENU_NO_CAPS"), "Off", nil, CoD.OptionsSettings.DrawFPSCallback)
	DrawFPSToggle:addChoice(Engine.Localize("MENU_YES_CAPS"), "Simple", nil, CoD.OptionsSettings.DrawFPSCallback)
end

CoD.OptionsSettings.StreamerModeCallback = function (StreamerModeEnabled, client)
	if client then
		Engine.SetHardwareProfileValue(StreamerModeEnabled.parentSelectorButton.m_profileVarName, StreamerModeEnabled.value)
		if StreamerModeEnabled.value == 1 then
			Dvar.cl_enableStreamerMode:set(true)
		else
			Dvar.cl_enableStreamerMode:set(false)
		end
	end
end

CoD.OptionsSettings.Button_AddChoices_StreamerMode = function (StreamerModeToggle)
	if UIExpression.DvarBool(nil, "cl_enableStreamerMode") == 0 then
		StreamerModeToggle:addChoice(Engine.Localize("MENU_DISABLED_CAPS"), 0, nil, CoD.OptionsSettings.StreamerModeCallback)
		StreamerModeToggle:addChoice(Engine.Localize("MENU_ENABLED_CAPS"), 1, nil, CoD.OptionsSettings.StreamerModeCallback)
	else
		StreamerModeToggle:addChoice(Engine.Localize("MENU_ENABLED_CAPS"), 1, nil, CoD.OptionsSettings.StreamerModeCallback)
		StreamerModeToggle:addChoice(Engine.Localize("MENU_DISABLED_CAPS"), 0, nil, CoD.OptionsSettings.StreamerModeCallback)
	end
end

CoD.OptionsSettings.VoiceChatCallback = function (VoiceValue, f37_arg1)
	if f37_arg1 ~= true then
		return 
	else
		Engine.SetDvar("cl_voice", VoiceValue.value)
		Engine.SetHardwareProfileValue("cl_voice", VoiceValue.value)
	end
end

CoD.OptionsSettings.Button_AddChoices_VoiceChat = function (DrawFPSToggle)
	DrawFPSToggle:addChoice(Engine.Localize("MENU_NO_CAPS"), "0", nil, CoD.OptionsSettings.VoiceChatCallback)
	DrawFPSToggle:addChoice(Engine.Localize("MENU_YES_CAPS"), "1", nil, CoD.OptionsSettings.VoiceChatCallback)
end

-- ============================================================================
--  zm_qol v1.99.54 - DEPTH OF FIELD GAINS A FOURTH STEP: "DISABLED".
--
--  User, 2026-08-18: *"the base game already lets you see the option for the
--  amount of DOF in the Advanced tab in settings, but the lowest setting you can
--  go is to LOW, so you'd just add one more option after that and it'd be OFF or
--  DISABLED, that way people wouldn't even realise that you couldn't turn it
--  fully off to begin with."*
--
--  🛑 THE ROW IS NO LONGER BOUND TO r_dofHDR, AND THAT IS THE WHOLE DESIGN.
--  Stock's row is a HARDWARE-PROFILE selector on r_dofHDR with three values
--  (LOW 0, MEDIUM 1, HIGH 2), and full-off is a DIFFERENT dvar, r_dof_enable.
--  Two ways to bolt a fourth step on, and only one of them is provable offline:
--
--    (a) give DISABLED an r_dofHDR value of 3. Nothing in the workspace says
--        whether the hardware-profile writer CLAMPS an out-of-range value, and
--        if it does the row reads back as HIGH the next time the menu opens and
--        looks broken. That is a guess, so it is not shipped.
--    (b) bind the row to the mod's own dvar, `dof_quality`, which has four
--        values of our own choosing and can never be clamped by anything, and
--        drive r_dof_enable / r_dofHDR from a per-choice CALLBACK.
--
--  (b) it is. The callback shape is stock's own: CoD.LeftRightSelector's
--  UpdateChoice calls callbackFunc(params) where params carries .value and
--  .parentSelectorButton, which is exactly what Plutonium's shipped
--  Button_ApplyDvarChanged (the FOV SENSITIVITY row on the GRAPHICS tab, line
--  ~575) and Treyarch's own DrawFPSCallback / VoiceChatCallback rely on.
--
--  🌟 IT WRITES BOTH THE DVAR AND THE HARDWARE PROFILE, like DrawFPSCallback
--  does for cg_drawFPS. Writing only one of the two loses the setting: the menu
--  calls Engine.SyncHardwareProfileWithDvars() when it opens and
--  Engine.ApplyHardwareProfileSettings() when it closes, so whichever copy was
--  not written gets overwritten by the one that was.
--
--  📝 DISABLED deliberately leaves r_dofHDR ALONE. Turning depth of field off
--  should not forget which quality it was on; r_dof_enable 0 is the master
--  switch and r_dofHDR only matters while it is 1.
--
--  📝 DISABLED IS ADDED FIRST, so it is the leftmost step - "one more option
--  after LOW" as the user described it, reading HIGH > MEDIUM > LOW > DISABLED
--  from the right. It being first also means that a `dof_quality` that does not
--  exist yet (the very first time this menu is opened, before any map has run)
--  displays DISABLED, which is exactly what this mod has always done.
-- ============================================================================
CoD.OptionsSettings.QolDofSettings = {
	[0] = { enable = 0 },              -- DISABLED - master switch off
	[1] = { enable = 1, hdr = 0 },     -- LOW
	[2] = { enable = 1, hdr = 1 },     -- MEDIUM
	[3] = { enable = 1, hdr = 2 }      -- HIGH
}

CoD.OptionsSettings.QolDofCallback = function (DofChoice)
	local Setting = CoD.OptionsSettings.QolDofSettings[tonumber(DofChoice.value)]
	if Setting == nil then
		return
	end
	Engine.SetDvar("dof_quality", DofChoice.value)
	-- zm_qol v2.9.3: r_dof_tweak is documented by Plutonium as "overrides
	-- r_dof_enable", so a DISABLED that leaves it set is not a disable.
	-- Cleared here as well as in quality_of_life.gsc's zmqol_dof_apply(),
	-- so the row still applies instantly without waiting for a respawn.
	Engine.SetDvar("r_dof_tweak", 0)
	Engine.SetDvar("r_dof_enable", Setting.enable)
	if Setting.hdr ~= nil then
		Engine.SetDvar("r_dofHDR", Setting.hdr)
		Engine.SetHardwareProfileValue("r_dofHDR", Setting.hdr)
	end
end

CoD.OptionsSettings.QolAddDepthOfFieldRow = function (ButtonList, LocalClientIndex)
	local DOFChoices = ButtonList:addDvarLeftRightSelector(LocalClientIndex, Engine.Localize("PLATFORM_DEPTH_OF_FIELD_CAPS"), "dof_quality", "Blurs whatever you are not aiming at.")
	local Apply = CoD.OptionsSettings.QolDofCallback
	DOFChoices:addChoice(LocalClientIndex, Engine.Localize("MENU_DISABLED_CAPS"), 0, nil, Apply)
	DOFChoices:addChoice(LocalClientIndex, Engine.Localize("PLATFORM_LOW_CAPS"), 1, nil, Apply)
	DOFChoices:addChoice(LocalClientIndex, Engine.Localize("PLATFORM_MEDIUM_CAPS"), 2, nil, Apply)
	DOFChoices:addChoice(LocalClientIndex, Engine.Localize("PLATFORM_HIGH_CAPS"), 3, nil, Apply)
	CoD.OptionsSettings.QolArchive("dof_quality")
	return DOFChoices
end

CoD.OptionsSettings.Button_AddChoices_MaxFPS = function (MaxFPSChoices)
	MaxFPSChoices:addChoice(Engine.Localize("MENU_UNLIMITED"), 0)
	MaxFPSChoices:addChoice("30", 30)
	MaxFPSChoices:addChoice("45", 45)
	MaxFPSChoices:addChoice("60", 60)
	MaxFPSChoices:addChoice("90", 90)
	MaxFPSChoices:addChoice("120", 120)
	MaxFPSChoices:addChoice("200", 200)
end

local SaveSliderChanges = function (f1_arg0, f1_arg1)
	Engine.SetDvar(f1_arg0.m_dvarName, f1_arg1)
	Engine.SetHardwareProfileValue(f1_arg0.m_dvarName, f1_arg1)
end

CoD.OptionsSettings.DvarLeftRightSlidernew = function (LocalClientIndex, f2_arg1, DvarName, f2_arg3, f2_arg4, f2_arg5, f2_arg6)
	local f2_local0 = tonumber(UIExpression.DvarString(nil, DvarName))
	local LeftRightSlider = CoD.LeftRightSlider.new(f2_arg1, f2_arg5, nil, f2_local0, f2_arg3, f2_arg4, f2_arg6)
	LeftRightSlider.m_dvarName = DvarName
	LeftRightSlider.m_currentValue = f2_local0
	LeftRightSlider.m_currentController = LocalClientIndex
	LeftRightSlider:setSliderCallback(SaveSliderChanges)
	return LeftRightSlider
end

CoD.OptionsSettings.AddDvarLeftRightSlider = function (ParentElement, LocalClientIndex, f19_arg2, DvarName, f19_arg4, f19_arg5, HintText, f19_arg7, f19_arg8)
	local CustomDvarLeftRightSlider = CoD.OptionsSettings.DvarLeftRightSlidernew(LocalClientIndex, f19_arg2, DvarName, f19_arg4, f19_arg5, f19_arg7, {
		leftAnchor = true,
		rightAnchor = true,
		left = 0,
		right = 0,
		topAnchor = true,
		bottomAnchor = false,
		top = 0,
		bottom = CoD.CoD9Button.Height
	})
	CustomDvarLeftRightSlider.hintText = HintText
	CustomDvarLeftRightSlider:setPriority(f19_arg8)
	ParentElement:addElement(CustomDvarLeftRightSlider)
	CoD.ButtonList.AssociateHintTextListenerToButton(CustomDvarLeftRightSlider)
	if ParentElement.buttonBackingAnimationState then
		CustomDvarLeftRightSlider:addBackground(ParentElement.buttonBackingAnimationState)
	end
	return CustomDvarLeftRightSlider
end

CoD.OptionsSettings.CreateGraphicsTab = function (GraphicsTab, LocalClientIndex)
	local GraphicsTabContainer = LUI.UIContainer.new()
	local GraphicsTabButtonList = CoD.Options.CreateButtonList()
	GraphicsTab.buttonList = GraphicsTabButtonList
	GraphicsTabContainer:addElement(GraphicsTabButtonList)
	
	local DisplayResolutionChoices = GraphicsTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("PLATFORM_VIDEO_MODE_CAPS"), "r_mode", Engine.Localize("PLATFORM_VIDEO_MODE_DESC"))
	CoD.OptionsSettings.Button_AddChoices_Resolution(DisplayResolutionChoices)
	
	local DisplayModeChoices = GraphicsTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("PLATFORM_DISPLAY_MODE_CAPS"), "r_fullscreen", Engine.Localize("PLATFORM_DISPLAY_MODE_DESC"))
	CoD.OptionsSettings.Button_AddChoices_DisplayMode(DisplayModeChoices)
	if DisplayModeChoices:getCurrentValue() == "2" then
		DisplayResolutionChoices:disableSelector()
	end
	
	local MonitorUsedChoices = GraphicsTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("PLATFORM_MONITOR_CAPS"), "r_monitor", Engine.Localize("PLATFORM_MONITOR_DESC"))
	CoD.OptionsSettings.Button_AddChoices_Monitor(MonitorUsedChoices)
	if DisplayModeChoices:getCurrentValue() == "0" then
		MonitorUsedChoices:setChoice(0)
		MonitorUsedChoices:disableSelector()
	end
	GraphicsTabButtonList:addSpacer(CoD.CoD9Button.Height / 2)
	
	local BrightnessChoices = GraphicsTabButtonList:addButton(Engine.Localize("MENU_BRIGHTNESS_CAPS"), Engine.Localize("PLATFORM_BRIGHTNESS_DESC"))
	BrightnessChoices:setActionEventName("open_brightness")
	
	local FOVSlider = CoD.OptionsSettings.AddDvarLeftRightSlider(GraphicsTabButtonList, LocalClientIndex, Engine.Localize("PLATFORM_FIELD_OF_VIEW_CAPS"), "cg_fov_default", 65, 120, Engine.Localize("PLATFORM_FOV_DESC"))
	FOVSlider:setNumericDisplayFormatString("%d")
	
	local FOVScaleSlider = GraphicsTabButtonList:addDvarLeftRightSlider(LocalClientIndex, Engine.Localize("FOV SCALE"), "cg_fovscale", 0.5, 2, Engine.Localize("Scale applied to the field of view."))
	FOVScaleSlider:setNumericDisplayFormatString("%.2f")
	FOVScaleSlider:setRoundToFraction(0.05)
	FOVScaleSlider:setBarSpeed(0.01)
	
	local FOVSensitivity = GraphicsTabButtonList:addDvarLeftRightSelector(LocalClientIndex, Engine.Localize("FOV SENSITIVITY"), "cg_usefovsensitivity", Engine.Localize("Scales look sensitivity with your FOV SCALE setting."))
	FOVSensitivity:addChoice(LocalClientIndex, Engine.Localize("MENU_DISABLED_CAPS"), 0, nil, CoD.OptionsSettings.Button_ApplyDvarChanged)
	FOVSensitivity:addChoice(LocalClientIndex, Engine.Localize("MENU_ENABLED_CAPS"), 1, nil, CoD.OptionsSettings.Button_ApplyDvarChanged)
	
	GraphicsTabButtonList:addSpacer(CoD.CoD9Button.Height / 2)
	local ShadowChoices = GraphicsTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("MENU_SHADOWS_CAPS"), "sm_spotQuality", Engine.Localize("PLATFORM_SHADOWS_DESC"))
	CoD.OptionsSettings.Button_AddChoices_Shadows(ShadowChoices)
	if Engine.GetHardwareProfileValueAsString("sm_enable") == "0" then
		ShadowChoices:setChoice(-1)
	end

	local f41_local9 = GraphicsTabButtonList:addProfileLeftRightSelector( LocalClientIndex, Engine.Localize( "MENU_MATURE_CAPS" ), "cg_mature", Engine.Localize( "MENU_MATURE_CONTENT_DESC" ) )
	CoD.Options.Button_AddChoices_EnabledOrDisabled( f41_local9 )
	f41_local9:disableCycling()
	f41_local9:registerEventHandler( "button_action", function ( element, event )
		element:dispatchEventToParent( {
			name = "open_mature_content",
			controller = event.controller
		} )
	end )

	CoD.Options.Button_AddChoices_EnabledOrDisabled(GraphicsTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("PLATFORM_RAGDOLL_CAPS"), "ragdoll_enable", Engine.Localize("PLATFORM_RAGDOLL_DESC")))
	GraphicsTabButtonList:addSpacer(CoD.CoD9Button.Height / 2)
	CoD.OptionsSettings.Button_AddChoices_PlayerNameIndicator(GraphicsTabButtonList:addProfileLeftRightSelector(LocalClientIndex, Engine.Localize("MENU_TEAM_INDICATOR_CAPS"), "team_indicator", ""))
	CoD.Options.Button_AddChoices_OnOrOff(GraphicsTabButtonList:addProfileLeftRightSelector(LocalClientIndex, Engine.Localize("MENU_COLOR_BLIND_ASSIST_CAPS"), "colorblind_assist", Engine.Localize("MENU_COLOR_BLIND_ASSIST_DESC")))
	CoD.OptionsSettings.Button_AddChoices_ChatHeight(GraphicsTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("PLATFORM_CHATMESSAGES_CAPS"), "cg_chatHeight", Engine.Localize("PLATFORM_CHATMESSAGES_DESC")))
	return GraphicsTabContainer
end

CoD.OptionsSettings.CreateAdvancedTab = function (AdvancedTab, LocalClientIndex)
	local AdvancedTabContainer = LUI.UIContainer.new()
	local InGame = UIExpression.IsInGame() == 1
	local AdvancedTabButtonList = CoD.Options.CreateButtonList()
	AdvancedTab.buttonList = AdvancedTabButtonList
	AdvancedTabContainer.buttonList = AdvancedTabButtonList
	AdvancedTabContainer:addElement(AdvancedTabButtonList)

	-- ========================================================================
	--  🛑 v2.2.0 - WITH ANY OTHER MOD LOADED (OR NONE), THIS TAB IS PLUTONIUM'S,
	--  UNCHANGED. The body below is copied verbatim out of
	--  storage\t6\raw\ui\t6\menus\optionssettings.lua.bak-before-gametab, the
	--  pristine copy taken before this project first touched the file - stock
	--  strings, stock spacers, stock row order. See ZmQolModLoaded() at the top.
	-- ========================================================================
	if not ZmQolModLoaded() then
		local StockTexQuality = AdvancedTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("MENU_TEXTURE_QUALITY_CAPS"), "r_picmip", Engine.Localize("PLATFORM_TEXTURE_QUALITY_DESC"))
		CoD.OptionsSettings.Button_AddChoices_TextureQuality(StockTexQuality)
		if Engine.GetHardwareProfileValueAsString("r_picmip_manual") == "0" then
			StockTexQuality:setChoice(-1)
		end
		if InGame and CoD.isMultiplayer then
			StockTexQuality:disableSelector()
		end
		CoD.OptionsSettings.Button_AddChoices_TextureFiltering(AdvancedTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("MENU_TEXTURE_MIPMAPS_CAPS"), "r_texFilterQuality", Engine.Localize("PLATFORM_TEXTURE_FILTERING_DESC")))
		local StockAA = AdvancedTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("MENU_ANTIALIASING_CAPS"), "r_aaSamples", Engine.Localize("PLATFORM_ANTIALIASING_DESC"))
		CoD.OptionsSettings.Button_AddChoices_AntiAliasing(StockAA)
		CoD.OptionsSettings.AdjustAntiAliasingSettings(StockAA)
		CoD.Options.Button_AddChoices_YesOrNo(AdvancedTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("PLATFORM_FXAA_CAPS"), "r_fxaa", Engine.Localize("PLATFORM_FXAA_DESC")))
		CoD.Options.Button_AddChoices_OnOrOff(AdvancedTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("PLATFORM_AMBIENT_OCCLUSION_CAPS"), "r_ssao", Engine.Localize("PLATFORM_AMBIENT_OCCLUSION_DESC")))
		CoD.OptionsSettings.Button_AddChoices_DepthOfField(AdvancedTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("PLATFORM_DEPTH_OF_FIELD_CAPS"), "r_dofHDR", Engine.Localize("PLATFORM_DEPTH_OF_FIELD_DESC")))
		AdvancedTabButtonList:addSpacer(CoD.CoD9Button.Height / 2)
		AdvancedTabButtonList:addSpacer(CoD.CoD9Button.Height / 2)
		CoD.Options.Button_AddChoices_YesOrNo(AdvancedTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("MENU_SYNC_EVERY_FRAME_CAPS"), "r_vsync", Engine.Localize("PLATFORM_VSYNC_DESC")))
		local StockMaxFps = AdvancedTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("PLATFORM_MAX_FPS_CAPS"), "com_maxfps", Engine.Localize("PLATFORM_MAX_FPS_DESC"))
		CoD.OptionsSettings.Button_AddChoices_MaxFPS(StockMaxFps)
		if Engine.GetHardwareProfileValueAsString("r_vsync") == "1" then
			StockMaxFps:setChoice(0)
			StockMaxFps:disableSelector()
		end
		CoD.OptionsSettings.Button_AddChoices_DrawFPS(AdvancedTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("PLATFORM_DRAW_FPS_CAPS"), "cg_drawFPS", Engine.Localize("PLATFORM_DRAW_FPS_DESC")))
		AdvancedTabButtonList:addSpacer(CoD.CoD9Button.Height / 2)
		CoD.OptionsSettings.Button_AddChoices_StreamerMode(AdvancedTabButtonList:addHardwareProfileLeftRightSelector("STREAMER MODE", "cl_enableStreamerMode", "Hides identifying player and network info while you stream."))
		AdvancedTabButtonList:addSpacer(CoD.CoD9Button.Height / 2)
		local StockSafeArea = AdvancedTabButtonList:addButton(Engine.Localize("MENU_SAFE_AREA_ADJUSTMENT_CAPS"), Engine.Localize("Adjust how far the HUD sits from the screen edges."))
		StockSafeArea:setActionEventName("open_safe_area")
		return AdvancedTabContainer
	end

	local TextureQualityChoices = AdvancedTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("MENU_TEXTURE_QUALITY_CAPS"), "r_picmip", "How sharp textures look. Higher uses more video memory.")
	CoD.OptionsSettings.Button_AddChoices_TextureQuality(TextureQualityChoices)
	if Engine.GetHardwareProfileValueAsString("r_picmip_manual") == "0" then
		TextureQualityChoices:setChoice(-1)
	end
	if InGame and CoD.isMultiplayer then
		TextureQualityChoices:disableSelector()
	end
	CoD.OptionsSettings.Button_AddChoices_TextureFiltering(AdvancedTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("MENU_TEXTURE_MIPMAPS_CAPS"), "r_texFilterQuality", "How sharp textures stay when you view them at an angle."))
	local AntiAliasingChoices = AdvancedTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("MENU_ANTIALIASING_CAPS"), "r_aaSamples", "Smooths jagged edges. Higher settings cost more performance.")
	CoD.OptionsSettings.Button_AddChoices_AntiAliasing(AntiAliasingChoices)
	CoD.OptionsSettings.AdjustAntiAliasingSettings(AntiAliasingChoices)
	CoD.Options.Button_AddChoices_YesOrNo(AdvancedTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("PLATFORM_FXAA_CAPS"), "r_fxaa", "Cheap extra edge smoothing. Slightly softer picture."))
	CoD.Options.Button_AddChoices_OnOrOff(AdvancedTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("PLATFORM_AMBIENT_OCCLUSION_CAPS"), "r_ssao", "Soft shading where surfaces meet. Costs some performance."))

	CoD.OptionsSettings.QolAddDepthOfFieldRow(AdvancedTabButtonList, LocalClientIndex)

	-- ========================================================================
	--  zm_qol v1.99.54 - THE THREE WORLD-RENDERING ROWS MOVED HERE FROM THE
	--  MOD'S OWN "GAME" TAB, at the user's request, 2026-08-18:
	--
	--    *"you're removing those 4 graphical related options added in the custom
	--    GAME tab menu in settings and moving them to the existing Advanced tab
	--    which is a stock/base game tab in settings... Also rename the MODEL
	--    DETAIL FIX to HIGHER DRAW DISTANCE."*
	--
	--  They sit directly under DEPTH OF FIELD because that is what they are -
	--  image-quality settings - and this is the image-quality group.
	--
	--  🛑 THE DVARS ARE NOT RENAMED WITH THE LABEL. `lod_fix` keeps its name
	--  even though the row now reads HIGHER DRAW DISTANCE: it has been archived
	--  in the player's config since v1.99.45 and it is the name the console
	--  takes, so renaming it would silently reset everyone's saved setting.
	--  Same call as whoswho_knife (v1.99.48) and move_speed (v1.99.52).
	--
	--  🛑 FOG ONLY APPLIES FROM THE IN-GAME PAUSE MENU, AND THAT IS PRE-EXISTING
	--  - the move neither causes it nor cures it. r_fog is a CHEAT-PROTECTED
	--  dvar: this install's own console_zm.log carries "Cannot set cheat dvar
	--  r_fog" 22 times and "r_fog is cheat protected" 9 times, every one of them
	--  in a rotation where no map fastfile was ever loaded, i.e. at the main
	--  menu. The mod's GSC does setdvar( "sv_cheats", 1 ) once a map is running
	--  (quality_of_life::zmqol_dev_commands), which is what lets the same row
	--  through in the pause menu, and the .fog chat command goes the other way
	--  round entirely - the SERVER pushes it with setclientdvar, which no cheat
	--  check applies to. Do not "fix" this by moving the row again.
	-- ========================================================================
	local T = CoD.OptionsSettings.QolToggle
	T(AdvancedTabButtonList, LocalClientIndex, "NIGHT MODE",          "night_mode", "Darker, moodier lighting.")
	-- 🌟 v1.99.91 - THIS ROW WRITES fog_enabled, NOT r_fog, AND THAT IS THE FIX
	-- FOR "the options don't save". r_fog is cheat-protected, so the `seta` that
	-- QolArchive runs for every other row is refused for it and it never reaches
	-- the per-mod config - and quality_of_life.gsc then forced r_fog back to 1 on
	-- every connect. fog_enabled is an ordinary mod dvar: it archives exactly
	-- like the other 39 rows, and the GSC side applies it to r_fog on connect and
	-- on every change (zmqol_fog_dvar_watch). The renderer still reads r_fog, so
	-- typing `r_fog 0` at the console keeps working until the next spawn.
	--
	-- 🛑 This is the ONE row whose dvar was deliberately renamed, against the
	-- standing "a renamed row keeps its dvar" rule, because r_fog was never
	-- saved in the first place - there is no stored preference to lose.
	T(AdvancedTabButtonList, LocalClientIndex, "FOG",                 "fog_enabled","World fog. Off shows the map edge.")
	T(AdvancedTabButtonList, LocalClientIndex, "HIGHER DRAW DISTANCE","lod_fix",    "Stops foreground textures popping in and out at high FOV.")

	-- 🛑 v2.6.6 - GRAPHICS BOOST REMOVED FROM THIS TAB, user request. It sat
	-- here from v2.1.2 to v2.6.5 - see git history for the row and its layout
	-- reasoning if it's ever added back. Removing it drops this tab to 14
	-- rows with no spacers (14.0 pitches), comfortably under the 15.0
	-- collision ceiling documented below, so no spacer changes were needed
	-- to compensate. The dvar (graphics_boost) and its GSC logic
	-- (qol_opt_graphics_boost() in scripts\zm\qol_options.gsc) are untouched -
	-- this only removes the UI toggle, not the underlying capability.

	-- ========================================================================
	--  🛑 v2.2.0 - THE SIX STOCK DESCRIPTIONS BELOW ARE REPLACED WITH SHORT
	--  ONES, AND THAT IS THE FIX FOR THE "ESC BACK" COLLISION.
	--
	--  User, 2026-08-21, screenshot Eki9Qryrh0.jpg: *"the description text
	--  collides with the ESC BACK prompt/option"*, with SYNC EVERY FRAME
	--  highlighted.
	--
	--  🌟 MEASURED, NOT NUDGED. This tab is 15 rows and no spacers = exactly
	--  15.0 pitches, the proven ceiling (see the GRAPHICS BOOST block above):
	--  rows run on a 50 px pitch from y=234, the hint draws one pitch below the
	--  last row at y=984, and the ESC prompt is anchored at y=1036. A ONE-line
	--  hint clears it by 52 px. PLATFORM_VSYNC_DESC is 152 characters - *"Match
	--  screen updates with your monitor's refresh rate. Enabling this will cap
	--  your FPS to your monitor's refresh rate, but will prevent screen
	--  tearing."* - and wraps to two, putting line 2 at ~y=1030, on top of ESC.
	--  The wrap point measured off that screenshot is ~104 characters.
	--
	--  🌟 WHY SHORTEN THE TEXT RATHER THAN DROP A ROW. Dropping one would mean
	--  moving a row the user specifically asked to have here (NIGHT MODE, FOG,
	--  HIGHER DRAW DISTANCE and GRAPHICS BOOST were all placed on this tab by
	--  name, GRAPHICS BOOST as recently as v2.1.2), and the GRAPHICS tab has no
	--  room either - it is 13 rows + 3 half-spacers = 14.5 pitches already.
	--  Shortening costs nothing and it is what the user asked for generally in
	--  v2.0.3: *"make them really simplistic."*
	--
	--  🛑 KEEP EVERY ONE OF THESE UNDER ~95 CHARACTERS. That is the whole point
	--  of the block; a long one puts the collision straight back.
	--  📝 Only rows this file creates are changed. The stock STRING is untouched
	--  and any other menu that uses PLATFORM_VSYNC_DESC still shows Treyarch's.
	-- ========================================================================
	CoD.Options.Button_AddChoices_YesOrNo(AdvancedTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("MENU_SYNC_EVERY_FRAME_CAPS"), "r_vsync", "Match your monitor's refresh rate. Stops tearing, but caps your FPS."))
	local MaxFpsChoices = AdvancedTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("PLATFORM_MAX_FPS_CAPS"), "com_maxfps", "The highest frame rate the game will run at.")
	CoD.OptionsSettings.Button_AddChoices_MaxFPS(MaxFpsChoices)
	if Engine.GetHardwareProfileValueAsString("r_vsync") == "1" then
		MaxFpsChoices:setChoice(0)
		MaxFpsChoices:disableSelector()
	end
	CoD.OptionsSettings.Button_AddChoices_DrawFPS(AdvancedTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("PLATFORM_DRAW_FPS_CAPS"), "cg_drawFPS", "Show your frame rate on screen."))
	
	CoD.OptionsSettings.Button_AddChoices_StreamerMode(AdvancedTabButtonList:addHardwareProfileLeftRightSelector("STREAMER MODE", "cl_enableStreamerMode", "Hides identifying player and network info while you stream."))

	local SafeAreaButton = AdvancedTabButtonList:addButton(Engine.Localize("MENU_SAFE_AREA_ADJUSTMENT_CAPS"), Engine.Localize("Adjust how far the HUD sits from the screen edges."))
	SafeAreaButton:setActionEventName("open_safe_area")
	
	return AdvancedTabContainer
end

CoD.OptionsSettings.CreateSoundTab = function (SoundTab, LocalClientIndex)
	local SoundTabContainer = LUI.UIContainer.new()
	local InGame = UIExpression.IsInGame() == 1
	local SoundTabButtonList = CoD.Options.CreateButtonList()
	SoundTab.buttonList = SoundTabButtonList
	SoundTabContainer:addElement(SoundTabButtonList)
	local VoiceVolumeSlider = SoundTabButtonList:addProfileLeftRightSlider(LocalClientIndex, Engine.Localize("MENU_VOICE_VOLUME_CAPS"), "snd_menu_voice", 0, 1, Engine.Localize("MENU_VOICE_VOLUME_DESC"), nil, nil, CoD.Options.AdjustSFX)
	local MusicVolumeSlider = SoundTabButtonList:addProfileLeftRightSlider(LocalClientIndex, Engine.Localize("MENU_MUSIC_VOLUME_CAPS"), "snd_menu_music", 0, 1, Engine.Localize("MENU_MUSIC_VOLUME_DESC"), nil, nil, CoD.Options.AdjustSFX)
	local SFXVolumeSlider = SoundTabButtonList:addProfileLeftRightSlider(LocalClientIndex, Engine.Localize("MENU_SFX_VOLUME_CAPS"), "snd_menu_sfx", 0, 1, Engine.Localize("MENU_SFX_VOLUME_DESC"), nil, nil, CoD.Options.AdjustSFX)
	local MasterVolumeSlider = SoundTabButtonList:addProfileLeftRightSlider(LocalClientIndex, Engine.Localize("MENU_MASTER_VOLUME_CAPS"), "snd_menu_master", 0, 1, Engine.Localize("MENU_MASTER_VOLUME_DESC"), nil, nil, CoD.Options.AdjustSFX)
	local CodCasterVolumeSlider = SoundTabButtonList:addProfileLeftRightSlider(LocalClientIndex, Engine.Localize("MENU_SHOUTCAST_GAME_VOLUME_CAPS"), "snd_shoutcast_game", 0, 2, Engine.Localize("MENU_SHOUTCAST_GAME_VOLUME_DESC"), nil, nil, CoD.Options.AdjustSFX)
	local CodCasterVOIPVolumeSlider = SoundTabButtonList:addProfileLeftRightSlider(LocalClientIndex, Engine.Localize("MENU_SHOUTCAST_VOIP_VOLUME_CAPS"), "snd_shoutcast_voip", 0, 2, Engine.Localize("MENU_SHOUTCAST_VOIP_VOLUME_DESC"), nil, nil, CoD.Options.AdjustSFX)
	--  v2.11.26 - the two half spacers this tab used to carry are GONE, and
	--  that is what pays for the VOICE LINES row below. See the note there.
	CoD.Options.Button_AddChoices_OnOrOff(SoundTabButtonList:addProfileLeftRightSelector(LocalClientIndex, Engine.Localize("MENU_HEARING_IMPAIRED_CAPS"), "snd_menu_hearing_impaired", Engine.Localize("MENU_HEARING_IMPAIRED_DESC")))
	if UIExpression.DvarBool(nil, "sd_can_switch_device") == 0 then
	else
		local SoundDeviceChoices = SoundTabButtonList:addHardwareProfileLeftRightSelector(Engine.Localize("PLATFORM_SOUND_DEVICE_CAPS"), "sd_xa2_device_name")
		CoD.OptionsSettings.Button_AddChoices_SoundDevices(SoundDeviceChoices)
		if Dvar.sd_xa2_num_devices:get() <= 1 or InGame then
			SoundDeviceChoices:disableSelector()
		end
	end
	CoD.AudioSettings.Button_AudioPresets_AddChoices(SoundTabButtonList:addProfileLeftRightSelector(LocalClientIndex, Engine.Localize("MENU_AUDIO_PRESETS_CAPS"), "snd_menu_presets", "", nil, nil, CoD.AudioSettings.CycleSFX))
	if UIExpression.IsInGame() == 0 and not (UIExpression.IsDemoPlaying(LocalClientIndex) ~= 0) then
		local SoundSystemTest = SoundTabButtonList:addButton(Engine.Localize("MENU_SYSTEM_TEST_CAPS"), Engine.Localize("MENU_SYSTEM_TEST_DESC"))
		SoundSystemTest:registerEventHandler("button_action", CoD.AudioSettings.Button_SystemTestButton)
	end

	-- ========================================================================
	--  v1.99.31 - THE MOD'S FOUR FEEDBACK SOUND PACKS, user request 2026-08-17.
	--
	--  🛑 SOUND is a STOCK tab. Everything above this line is Treyarch's, and it
	--  is only editable at all because this mod ships a full replacement of
	--  optionssettings.lua. So the mod's rows go at the BOTTOM, behind a spacer,
	--  and touch nothing above.
	--
	--  🛑 v1.99.32 - THE `if InGame then` GATE IS GONE, AND ITS ROW-BUDGET
	--  JUSTIFICATION WAS WRONG. User, 2026-08-17: *"the sound settings are still
	--  vanilla and don't have the toggable options"* - the rows only ever
	--  existed in the PAUSE menu, so the main-menu SOUND tab was unchanged, and
	--  hiding half a feature is exactly the compromise this project does not
	--  ship. The four rows are now built in both menus.
	--
	--  🌟 THE REAL CEILING IS MEASURED, NOT GUESSED AT. The old note treated
	--  14.5 row-pitches - stock's GRAPHICS tab, the largest tab known to render
	--  cleanly - as a hard limit. It is a proven-good LOWER BOUND, nothing more.
	--  The actual box comes straight out of the decompiled stock LUI
	--  (codmenu / codbase / options / buttonlist, English, non-SP):
	--
	--      CoD.Menu.Height        = CoD.SDSafeHeight       = 648   (codbase)
	--      CoD.Menu.TitleHeight   = CoD.textSize.Big       =  48   (codmenu)
	--      MFTabManager.TabHeight = CoD.textSize.Default   =  25   (mftabmanager)
	--      CoD.ButtonPrompt.Height (the ESC prompt)        =  25   (buttonprompt)
	--      CoD.CoD9Button.Height   (one row pitch)         =  30   (cod9button)
	--      CoD.HintText.Height    = CoD.textSize.Default   =  25   (hinttext)
	--
	--  SetupTabManager puts the content widget at 48 + 25 + 15 = 88 and stops it
	--  ButtonPrompt.Height short of the bottom; CreateButtonList insets another
	--  20. So the list runs 108..623 = 515 units = 17.1 pitches, or ~16.3 once
	--  the hint line is allowed for. SOUND out of game is 10 rows + 2 half
	--  spacers = 11 pitches (SYSTEM TEST is out-of-game only, SOUND DEVICE is
	--  there whenever sd_can_switch_device is 1 - it is on this machine).
	--  11 + 0.5 + 4 = 15.5 pitches = 465 units, inside 515 with a full row to
	--  spare. In game it is 14.5, the number that was already proven good.
	--  (The v1.94.0 fault the old note cited was 23.5 pitches = 705 units, over
	--  the box by 190 - a different order of problem entirely.)
	--
	--  🛑 v1.99.33 - THE SEPARATOR SPACER IS GONE, AND THAT IS MEASURED OFF THE
	--  USER'S OWN SCREENSHOT, not guessed at. At 15.5 pitches the tab fits the
	--  BOX, but the hint line rides directly under the last row and the ESC
	--  prompt is anchored to the menu, so the two met. Scanning the shot
	--  (2000x1125, so 1.5625 px per LUI unit) for text bands in the label
	--  column gave:
	--
	--      DOWNED SOUND, the last row      964 - 993 px
	--      hint line, with its descenders 1023 - 1045 px
	--      ESC Back                       1046 - 1059 px
	--
	--  - a one-pixel touch, which is exactly the "slightly colliding" the user
	--  reported. The measured row pitch is 50 px and every spacer in this tab is
	--  26 px, so dropping this one spacer lifts everything from HITMARKER HIT
	--  SOUND down by 26 px and leaves ~27 px of clear air under the hint line -
	--  more than the 22 px that separates two ordinary rows. In game, where
	--  SYSTEM TEST is absent, the clearance is a further 50 px on top.
	--
	--  📝 The cost is the visual grouping: the four rows now follow SYSTEM TEST
	--  at normal pitch instead of sitting in their own block. A collision with
	--  the ESC prompt is a reported fault; tighter grouping is not.
	-- ========================================================================
	local C = CoD.OptionsSettings.QolChoice
	local T = CoD.OptionsSettings.QolToggle

	-- ========================================================================
	--  VOICE LINES  -  v2.11.26, user request 2026-09-04, placed exactly where
	--  they asked: between PRESETS and the first hitmarker row.
	--
	--  The row drives voice_lines (1 = on, the new default). Its GSC half is
	--  qol_options.gsc::qol_opt_voice_lines - which until this version was
	--  disable_player_quotes, defaulted to 1, had no row anywhere, and silenced
	--  every character on every map.
	--
	--  🛑 IT COSTS THE TAB NOTHING, AND THAT IS DELIBERATE. The measured
	--  ceiling is 15.0 row-pitches (see the note above QolToggle: 15.5 touches
	--  the ESC prompt, 16.0 overlaps it - both reported by the user). SOUND was
	--  already AT 15.0 out of game (14 rows + 2 half spacers), so a plain
	--  addition would have hit 16.0 and reproduced the v2.0.8 fault. The two
	--  half spacers above were removed to pay for it: out of game 15 rows + 0
	--  spacers = 15.0, in game 14.0 - the exact totals that ship today, so the
	--  layout cannot regress. The cost is stock's visual grouping, which is the
	--  same trade v1.99.33 already made on this tab.
	-- ========================================================================
	T(SoundTabButtonList, LocalClientIndex, "VOICE LINES", "voice_lines", "Your character's spoken lines.")

	--  1..8 keep the donor mod's own pack numbering so the two cannot drift.
	--  0 = DEFAULT plays pack 1 (v2.3.4) - the old stock spl_hit_alert it tried
	--  to play before was silent on four of six maps and its payload cannot be
	--  extracted with this project's tooling; see quality_of_life.gsc's
	--  zmqol_play_feedback_sound() for the full measurement. 9 = NO SOUND
	--  silences the marker entirely.
	local MarkerPacks = {
		{ "DEFAULT",      0 },
		{ "COLD WAR",     1 },
		{ "MW 2019",      2 },
		{ "BLACK OPS 4",  3 },
		{ "OVERWATCH",    4 },
		{ "APEX LEGENDS", 5 },
		{ "8 BIT",        6 },
		{ "MW CLASSIC",   7 },
		{ "BLACK OPS 7",  8 },
		{ "NO SOUND",     9 }
	}

	C(SoundTabButtonList, LocalClientIndex, "HITMARKER HIT SOUND",  "hit_sound",    "Plays when you hit a zombie.",        MarkerPacks)
	C(SoundTabButtonList, LocalClientIndex, "HITMARKER KILL SOUND", "kill_sound",   "Plays when you kill a zombie.",       MarkerPacks)
	C(SoundTabButtonList, LocalClientIndex, "CRITS SOUND",          "crit_sound",   "Extra sound on a headshot or melee kill.", {
		{ "NO SOUND",    0 },
		{ "BLACK OPS 7", 1 },
		{ "MW 2019",     2 }
	})
	C(SoundTabButtonList, LocalClientIndex, "DOWNED SOUND",         "downed_sound", "Plays for everyone when a player goes down.", {
		{ "NO SOUND",     0 },
		{ "BLACK OPS 4",  1 },
		{ "COLD WAR",     2 },
		{ "MW 2019",      3 }
	})

	return SoundTabContainer
end

CoD.OptionsSettings.CreateVoiceChatTab = function (f44_arg0, f44_arg1)
	local f44_local0 = LUI.UIContainer.new()
	local f44_local1 = CoD.Options.CreateButtonList()
	f44_arg0.buttonList = f44_local1
	f44_local0:addElement(f44_local1)
	CoD.OptionsSettings.Button_AddChoices_VoiceChat(f44_local1:addHardwareProfileLeftRightSelector(Engine.Localize("MENU_VOICECHAT_CAPS"), "cl_voice", Engine.Localize("PLATFORM_VOICECHAT_DESC")))
	f44_local1:addSpacer(CoD.CoD9Button.Height / 2)
	local f44_local2 = f44_local1:addProfileLeftRightSlider(f44_arg1, Engine.Localize("PLATFORM_VOICECHAT_VOLUME"), "snd_voicechat_volume", 0, 1, Engine.Localize("PLATFORM_VOICECHAT_VOLUME_DESC"), nil, nil, CoD.Options.AdjustSFX)
	local f44_local3 = f44_local1:addProfileLeftRightSlider(f44_arg1, Engine.Localize("PLATFORM_VOICECHAT_RECORD_LEVEL"), "snd_voicechat_record_level", 0, 1, Engine.Localize("PLATFORM_VOICECHAT_RECORD_LEVEL_DESC"), nil, nil, CoD.Options.AdjustSFX)
	f44_local1:addSpacer(CoD.CoD9Button.Height / 2)
	local f44_local4 = f44_local1:addVoiceMeter(Engine.Localize("MENU_VOICECHAT_LEVEL_INDICATOR_CAPS"), Engine.Localize("PLATFORM_VOICEMETER_DESC"))
	return f44_local0
end

-- ============================================================================
--  zm_qol - THE "QUALITY OF LIFE" TAB.                            (v1.94.0)
--
--  User, 2026-08-14, on the v1.93.0 attempt: "the placement for the game menu
--  itself is wrong, it should be the furthest right, after voice chat... the
--  menu navigation arrows are bugged and colliding with text... rename the Game
--  tab to Quality Of Life and then add some toggable options in that menu
--  itself so when people now use my mod they don't need to rely on chat
--  commands which get annoying."
--
--  🛑 THE ARROW BUG WAS THE TAB POSITION, NOT THE ARROWS. Registering our tab
--  FIRST shifted every stock tab one place right, and the tab manager lays its
--  left/right arrows out from the ORIGINAL extents - so the left arrow landed
--  off the strip and the right one printed over "VOICE CHAT". Registered last,
--  the strip is stock's plus one on the end and both arrows sit correctly.
--
--  🌟 EVERY DVAR BELOW WAS READ OUT OF A LIVE DVAR DUMP OR THE MOD'S OWN
--  REGISTRATION LIST - none is guessed:
--     cl_allowDownload, cg_drawIdentifier, cg_flashScriptHashes, cg_holdToSprint
--         from console_zm.log's dvar dump
--     r_fog, r_dof_enable
--         the two the mod's own .fog command and night mode already write
--     night_mode, hud_master, hud_timer, hud_round_timer, hud_health_bar,
--     hud_remaining, hud_zone, rapid_fire, no_power, lod_fix
--         from qol_options.gsc's qol_opt_dvar() table
--     velocity, fly
--         from quality_of_life.gsc
--     god, ghost, infinite_ammo, infinite_sprint
--         added in v1.94.0 by zmqol_toggle_dvar_watch() for exactly this menu
--
--  📝 "REDUCE ENGINE SLEEPS" IS DELIBERATELY ABSENT. It is in the stock
--  Plutonium GAME tab the user screenshotted, but no dvar of that name exists
--  in this build's dump and inventing one would be a guess. The other three
--  standard entries are all here.
--
--  📝 PERMA-PERKS WAS ABSENT HERE UNTIL v2.8.0 for the reason stated at the
--  time - the mod had no perma-perk system at all. It has one now: the
--  PERMA-PERKS row further down this file, dvar perma_perks, queue item 29.
--
--  🛑 DESCRIPTIONS ARE SHORT ON PURPOSE. The v1.93.0 text ran off the right
--  edge of the screen; the hint line does not wrap.
--
--  🛑 NO CUSTOM APPLY CALLBACK. v1.93.0 passed
--  CoD.OptionsSettings.Button_ApplyDvarChanged as the 5th argument, which
--  REPLACES the widget's own DvarSelectorSetDvarFunc - and "hold to sprint"
--  then would not turn back off. Passing nil uses Plutonium's default handler,
--  the same one optionscontrols.lua uses for cl_freelook and m_pitch, which are
--  known to work both ways.
-- ============================================================================
-- ============================================================================
--  v1.99.31 - the same widget as QolToggle, but with N named values instead of
--  DISABLED/ENABLED. Choices is a list of { LABEL, value } pairs, in the order
--  they should cycle. The callback argument is left nil for the same reason
--  QolToggle leaves it nil - see the note below; passing one replaces the
--  widget's own DvarSelectorSetDvarFunc and the row then will not set back.
-- ============================================================================
-- ============================================================================
--  v1.99.45 - THE MOD'S OWN SETTINGS NOW SURVIVE A RESTART.
--
--  User, 2026-08-18: "I keep having to re-do all my settings from the menu...
--  if i restart my game i find myself having to constantly re do my settings
--  configuration enabled/disabled for the ones you added, sometimes they work
--  sometimes they don't it's really inconsistent."
--
--  🌟 THE INCONSISTENCY IS THE WHOLE DIAGNOSIS, AND IT IS MEASURED. Plutonium
--  writes a config on exit and re-runs it at startup, but it only writes dvars
--  carrying the ARCHIVE flag - the `seta` lines. A dvar created by GSC's
--  setdvar() has no flags, so it is never written and is gone the moment the
--  game closes. Read out of the mod's own live config
--  (storage\t6\players\mods\zm_qol\plutonium_zm.cfg) on 2026-08-18, out of
--  ~35 option rows exactly THREE names appear: hud_enable, night_mode and
--  velocity - names that other software had already archived. Every row the
--  user reported as sticking is one of those; every row they reported as
--  resetting is one of the rest.
--
--  THE FIX: mark each option's dvar archived as its row is built. `seta` is a
--  real command in this build - the string is in t6zm.exe's table, alongside
--  `toggle`, while `sets` and `setu` are not - and the flag lives on the DVAR,
--  not on the write, so once it is set Plutonium's exit-time writer emits
--  whatever value the row ends up holding. Nothing hooks the row's change
--  callback: v1.93.0 tried that and a toggle then would not switch back off
--  (see the note further down), so the widget's own handler is left untouched.
--
--  🛑 AN EMPTY VALUE IS WRITTEN TOO, AND THAT IS THE BELT-AND-BRACES. One thing
--  cannot be settled from the files: whether `seta` ADDS the archive flag to a
--  dvar GSC already created this session, or only sets the flag on a dvar it
--  creates itself. Writing the empty case covers the second branch - at the main
--  menu, before any map has loaded, the mod's dvars do not exist yet, so this
--  `seta` is what creates them and the flag is unambiguous. GSC then fills the
--  real default in on map load (qol_opt_dvar only writes when getdvar() == ""),
--  and Plutonium's exit-time writer emits whatever value it ends up holding.
--  The engine-owned rows on this tab (r_fog, r_dof_enable, cl_allowDownload…)
--  always have a value, so none of them can be blanked by this.
--
--  📝 pcall, because an error thrown while a menu is building takes the whole
--  menu with it. A failure here must cost persistence, never the options screen.
-- ============================================================================
CoD.OptionsSettings.QolNoArchive = {
	-- The CHEATS tab. These are per-match states, not preferences: an archived
	-- fly = 1 would put the player in noclip on the next launch before they had
	-- touched anything. Deliberate, and easy to reverse if the user wants them.
	godmode = true,
	ghostmode = true,
	infinite_ammo = true,
	infinite_sprint = true,
	fly = true,
	rapid_fire = true,
	no_power = true,
	-- v1.99.86 - the three ACTION rows. An archived set_round 50 would jump the
	-- player to round 50 on their next launch, and an archived kill_horde 1
	-- would fire on map load. They are per-match actions, never preferences.
	set_round = true,
	kill_horde = true,
	end_round = true,
	-- v1.99.93 - the two new CHEATS rows. set_points holds its value in a match
	-- BY DESIGN (see the row), but an archived 1000000 would hand out a million
	-- points on the next launch. teleport (v2.4.2: now a pure selector, same
	-- shape as set_points) is kept out for the same reason as set_points -
	-- an archived destination index means nothing on a different map anyway.
	-- execute_teleport is the actual action - an archived 1 would fire on load.
	set_points = true,
	teleport = true,
	execute_teleport = true,
	-- v2.8.2 - ONE SHOT ONE KILL. An archived 1 would arm the cheat on the next
	-- launch before the player had touched anything, same as god mode.
	one_shot_one_kill = true
}

CoD.OptionsSettings.QolArchive = function (DvarName)
	if CoD.OptionsSettings.QolNoArchive[DvarName] then
		return
	end
	pcall(function ()
		local Value = UIExpression.DvarString(nil, DvarName)
		if Value == nil then
			Value = ""
		end
		Engine.Exec(nil, "seta " .. DvarName .. " \"" .. Value .. "\"")
	end)
end

CoD.OptionsSettings.QolChoice = function (ButtonList, LocalClientIndex, Label, DvarName, Description, Choices)
	local Selector = ButtonList:addDvarLeftRightSelector(LocalClientIndex, Engine.Localize(Label), DvarName, Engine.Localize(Description))
	for i = 1, #Choices do
		Selector:addChoice(LocalClientIndex, Engine.Localize(Choices[i][1]), Choices[i][2])
	end
	CoD.OptionsSettings.QolArchive(DvarName)
	return Selector
end

-- ============================================================================
--  QolMigrateTimers  -  v2.1.3, the GAME TIMER / ROUND TIMER merge
--
--  Runs once, the first time this tab is built on a machine that has never seen
--  hud_timers. It reads the two dvars the old pair of rows wrote - both of which
--  are still sitting in the player's config - and writes the four-way value that
--  means the same thing:
--
--        game  round      hud_timers
--          1     1    ->      1   both
--          1     0    ->      2   game only
--          0     1    ->      3   round only
--          0     0    ->      0   off
--
--  🛑 IT MUST BE IDEMPOTENT, and it is: the migration is skipped the moment
--  hud_timers holds anything at all, and the seta below is what puts it there.
--  A second pass can therefore never re-derive it from a stale hud_timer.
--
--  📝 The GSC does the same derivation in qol_options.gsc::qol_opt_timer_mode()
--  for a player who never opens this menu. Both sides agree on the table above;
--  change one and change the other.
--
--  Everything is inside pcall for the same reason QolArchive is: a dvar read
--  that throws must never be able to stop the tab from being built.
-- ============================================================================
CoD.OptionsSettings.QolMigrateTimers = function ()
	pcall(function ()
		local Cur = UIExpression.DvarString(nil, "hud_timers")
		if Cur ~= nil and Cur ~= "" then
			return
		end

		local function OldOn(Name)
			local V = UIExpression.DvarString(nil, Name)
			-- Unset means the player never touched it, and both rows shipped ON.
			if V == nil or V == "" then
				return true
			end
			return V ~= "0"
		end

		local Value = 0
		if OldOn("hud_timer") and OldOn("hud_round_timer") then
			Value = 1
		elseif OldOn("hud_timer") then
			Value = 2
		elseif OldOn("hud_round_timer") then
			Value = 3
		end

		Engine.Exec(nil, "seta hud_timers \"" .. Value .. "\"")
	end)
end

-- ============================================================================
--  QolMigrateFlash  -  v2.14.14, the FLASH CREDITS / FLASH HELP merge
--
--  The twin of QolMigrateTimers for the GAME tab's match-start flash rows. It
--  reads the two dvars the old pair of rows wrote and writes the four-way
--  value that means the same thing, once, while flash_intro is still empty:
--
--        credits  help      flash_intro
--          1       1    ->      1   both
--          1       0    ->      2   credits only
--          0       1    ->      3   help only
--          0       0    ->      0   off
--
--  Idempotent for the same reason: the first line returns the moment
--  flash_intro holds anything, and the seta below is what puts it there.
--  📝 qol_options.gsc::qol_opt_flash_seed() is the GSC side of the same table.
-- ============================================================================
CoD.OptionsSettings.QolMigrateFlash = function ()
	pcall(function ()
		local Cur = UIExpression.DvarString(nil, "flash_intro")
		if Cur ~= nil and Cur ~= "" then
			return
		end

		local function OldOn(Name)
			local V = UIExpression.DvarString(nil, Name)
			-- Unset means the player never touched it, and both rows shipped ON.
			if V == nil or V == "" then
				return true
			end
			return V ~= "0"
		end

		local Value = 0
		if OldOn("intro_credits") and OldOn("flash_help") then
			Value = 1
		elseif OldOn("intro_credits") then
			Value = 2
		elseif OldOn("flash_help") then
			Value = 3
		end

		Engine.Exec(nil, "seta flash_intro \"" .. Value .. "\"")
	end)
end

CoD.OptionsSettings.QolToggle = function (ButtonList, LocalClientIndex, Label, DvarName, Description)
	local Selector = ButtonList:addDvarLeftRightSelector(LocalClientIndex, Engine.Localize(Label), DvarName, Engine.Localize(Description))
	Selector:addChoice(LocalClientIndex, Engine.Localize("MENU_DISABLED_CAPS"), 0)
	Selector:addChoice(LocalClientIndex, Engine.Localize("MENU_ENABLED_CAPS"), 1)
	CoD.OptionsSettings.QolArchive(DvarName)
	return Selector
end

-- ============================================================================
--  🛑 v1.95.0 - THE LIST IS SPLIT ACROSS TWO TABS BECAUSE 22 ROWS DO NOT FIT.
--
--  User, 2026-08-14: "The Esc back at the bottom left doesn't account for all
--  the options in the list for this menu, and it collides with some of the
--  options in the list, and the header groups... also collide with the menu
--  options."
--
--  🌟 THE BUDGET IS MEASURED OFF A TAB THAT IS KNOWN TO RENDER CORRECTLY.
--  Stock's GRAPHICS tab in this same file is 13 rows + 3 half-height spacers =
--  14.5 row-pitches and it lays out cleanly, hint line and ESC prompt included.
--  The v1.94.0 QUALITY OF LIFE tab was 22 rows + 3 spacers = 23.5 pitches, 62%
--  over that, and CoD.ButtonList does not clip or scroll - it simply draws
--  past both ends of its container, over the tab strip above and the ESC
--  prompt below. That is the whole of the reported "scuffed-ness".
--
--  The mod's own tabs, as of v2.14.28: GAME 1 15.0, GAME 2 14.0, GAME 3 3.0,
--  HUD 15.0 (v2.14.16, full), CHEATS 14.0. (GAME 1 and GAME 2 are the tabs called GAME and
--  PATCHES before v2.12.5; both were already at the ceiling, which is why
--  GAME 3 exists.) The stock tabs this file also builds: ADVANCED 15.0 (full).
--  🌟 v2.14.17 - GAME 2 HAS ONE FREE PITCH AGAIN: SLIQUIFIER PRE-NERF was
--  removed at the user's request. GAME 1 and HUD are still at the ceiling.
--  🛑 IF YOU ADD A ROW, ADD IT TO THE SHORTEST TAB IT HONESTLY BELONGS IN.
--
--  🌟 v1.99.61 - THE CEILING IS 15.0 PITCHES, NOT 14.5, AND IT IS MEASURED.
--  14.5 was stock's GRAPHICS tab - a proven-good lower bound that this note
--  used to quote as a hard limit. The real number comes from CreateSoundTab's
--  measurement pass in v1.99.33: SOUND ships at 14 rows + 2 half spacers =
--  15.0 pitches and leaves ~27 px of clear air under the hint line, against the
--  22 px that separates two ordinary rows. 15.5 is where the user actually
--  reported a collision with the ESC prompt. Do not go past 15.0 without
--  re-measuring.
--
--  🌟 v2.1.2 - 15.0 IS NOW CONFIRMED FROM THE OTHER SIDE, AND THE RULE HAS A
--  FORMULA. The HUD tab reached 16.0 pitches in v2.0.8 and the user reported
--  the hint line drawing on top of the ESC prompt. Their screenshot gives
--  rows on a 50 px pitch from y=234, the hint one full pitch under the last
--  row, and the ESC prompt fixed at y=1036:
--
--      hint_top(px) = 234 + pitches * 50        one line is 28 px tall
--      a second hint line sits 46 px below the first
--
--  So 15.0 -> 984 (clears by 24 px), 15.5 -> 1009 (touches, the v1.99.33
--  report), 16.0 -> 1034 (overlaps, the v2.0.8 report). A tab whose longest
--  description WRAPS needs 14.5 or less. Descriptions wrap past roughly 95
--  characters - measured off the same shot, where a 100-character hint spanned
--  x=346..1538 and spilled its last word onto a second line.
--
-- ============================================================================
--  🌟 v1.96.0 - THREE TABS: GAME / HUD / CHEATS, SORTED BY WHAT EACH ROW DOES.
--
--  User, 2026-08-16: *"add another tab in the pause menu options called CHEATS
--  after the HUD section, and move any cheat options like godmode, fly, ghost,
--  infinite sprint, infinite ammo, etc. to that tab to make room for other
--  future options in the GAME tab, and also make sure that any added toggable
--  options are in the correct relevant tab, so HUD would contain all hud element
--  toggles and so on."*
--
--  So the rule for this file is now: HUD holds things that draw on the HUD.
--  CHEATS holds things that change the rules in the player's favour. GAME holds
--  everything else - client/session options, world rendering, startup.
--
--  That moved the four RENDERING rows (night mode, fog, depth of field, model
--  detail fix) OUT of HUD, where they never belonged: none of them is a HUD
--  element, they are r_* / visionset settings applied to the world.
--
--  🛑 HOLD TO SPRINT IS REMOVED AND IT IS NOT MOVED TO CONTROLS. Same message:
--  *"in the game tab remove the hold to sprint option as this was never even in
--  the regular GAME tab without the mod to begin with, or just move it to
--  controls instead if that option didn't already exist."*
--
--  It cannot go to CONTROLS, and the reason is a bug this project already paid
--  for. Stock BO2's controls menu has no hold-to-sprint row at all - verified
--  directly against the retail decompile now sitting at
--  storage\t6\raw\ui\t6\menus\optionscontrols.lua.aside, whose five tabs (LOOK /
--  MOVE / COMBAT / INTERACT / GAMEPAD) contain only the "+sprint" key BIND. So
--  adding the row means this mod shipping its own optionscontrols.lua, and that
--  file would then SHADOW Plutonium's patched one exactly the way the .aside
--  copy did - which is what deleted RAW INPUT, MOUSE ACCELERATION and FIX HIGH
--  POLL RATE LAG from the user's CONTROLS menu in the first place
--  (.agents/checkpoint_48.md §4). Trading three working Plutonium rows for one
--  new row is a straight loss, so the row is simply gone.
--
--  The dvar itself is untouched and still works from the console:
--  `cg_holdToSprint 1`.
-- ============================================================================
CoD.OptionsSettings.CreateQolTab = function (QolTab, LocalClientIndex)
	local QolContainer = LUI.UIContainer.new()
	local QolButtons = CoD.Options.CreateButtonList()
	QolTab.buttonList = QolButtons
	QolContainer:addElement(QolButtons)

	local T = CoD.OptionsSettings.QolToggle
	local C = CoD.OptionsSettings.QolChoice

	-- The standard Plutonium game options.                            3 rows
	T(QolButtons, LocalClientIndex, "ALLOW DOWNLOADING",  "cl_allowDownload",     "Lets a server send you its mod files when you join.")
	T(QolButtons, LocalClientIndex, "DRAW IDENTIFIER",    "cg_drawIdentifier",    "Session watermark at the top of the screen.")
	T(QolButtons, LocalClientIndex, "FLASH SCRIPT HASHES","cg_flashScriptHashes", "Developer readout. Leave it off unless you are debugging.")

	-- 🛑 v1.99.54 - THE FOUR WORLD-RENDERING ROWS ARE GONE FROM THIS TAB.
	-- NIGHT MODE, FOG and MODEL DETAIL FIX (now HIGHER DRAW DISTANCE) moved to
	-- the stock ADVANCED tab, and the mod's own DEPTH OF FIELD row was deleted
	-- outright - stock's ADVANCED row now carries a DISABLED step instead of
	-- there being two DOF rows in one menu. User request, 2026-08-18; see the
	-- notes in CreateAdvancedTab and QolAddDepthOfFieldRow.
	--
	-- Removing them left two spacers touching again, exactly as removing HOLD TO
	-- SPRINT did in v1.99.51. Collapsed back to one, then removed outright in
	-- v2.8.0 to pay for the PERMA-PERKS row - see the note over that row for the
	-- pitch arithmetic. Do not re-add a spacer here without removing a row.

	-- Gameplay rules.                                                 6 rows
	-- v1.99.26, user request 2026-08-17.
	-- v1.99.30: LIVE now, both ways. The claim that used to sit here - that it
	-- could only take effect next match - was wrong, and the row did nothing at
	-- all when flipped mid-game. Off hands the machine back to stock's own
	-- Pack-a-Punch: put the gun in, wait, take it out.
	T(QolButtons, LocalClientIndex, "INSTANT PAP",        "instant_pap",          "Pack-a-Punch with no wait. Off uses the stock machine.")
	-- v1.99.39, user request 2026-08-17. Both default ON: each one is behaviour
	-- the mod already had, so the switch must not change anything until it is
	-- thrown. BO4 MAX AMMO off is EXACT vanilla - the mod's replacement for
	-- full_ammo_powerup differs from stock by the single setweaponammoclip line
	-- the dvar gates, nothing else.
	T(QolButtons, LocalClientIndex, "BO4 MAX AMMO",       "bo4_max_ammo",         "Max Ammo fills the magazine too. Off needs a reload first.")
	-- Origins has no ballistic knife in its fastfile at all, so the perk stays
	-- stock there whatever this is set to. Said in the GSC, not hidden here.
	-- 🛑 v1.99.48 - the LABEL is now "BETTER WHO'S WHO" (user, 2026-08-18) but
	-- the DVAR is still whoswho_knife, deliberately: it is already archived in
	-- the player's config from v1.99.45, and it is the name the console command
	-- takes. Renaming it would silently reset everyone's saved setting to the
	-- default and break any bind they have made.
	T(QolButtons, LocalClientIndex, "BETTER WHO'S WHO",   "whoswho_knife",        "Who's Who gives a PaP'd ballistic knife, not the pistol.")
	-- v1.99.48, user request 2026-08-18. The nuke kills its zombies all at once
	-- instead of staggering them 0.1-0.7s apart, which is what lets a survivor
	-- swing at you mid-nuke. Same zombies, same 400 points - only the stagger
	-- goes. See zmqol_nuke_powerup() in quality_of_life.gsc.
	T(QolButtons, LocalClientIndex, "INSTANT NUKE",       "instant_nuke",         "Nuke kills every zombie at once, not one by one.")
	-- v1.99.51, queue item 2. ON by default - forcing the three movement
	-- scales to 1 is what this mod has always done, so the switch changes
	-- nothing until it is thrown. OFF is exact stock: 0.7 back, 0.8 strafe,
	-- 0.667 sprint-strafe, read out of this install's own dvar dump. Live both
	-- ways; see qol_options::qol_opt_move_speed().
	-- 🛑 v1.99.52 - the LABEL is "BACKSPEED PATCH" now (user, 2026-08-18) but the
	-- DVAR is still move_speed, deliberately: it is already archived in the
	-- player's config from v1.99.51 and it is the name the console takes.
	-- Renaming it would reset the saved setting. Same call as whoswho_knife.
	-- 🛑 v1.99.93 - BACKSPEED PATCH and ANIMATED CAMO PATCH MOVED TO THE NEW
	-- PATCHES TAB, dvars unchanged (move_speed / anim_pap_camo). Do not re-add
	-- them here; see CoD.OptionsSettings.CreateQolPatchesTab.

	-- v1.99.61, user request 2026-08-18. ON by default - the +100 for proning
	-- at a perk machine is behaviour the mod has always had, so the switch
	-- changes nothing until it is thrown. OFF is NO prone points anywhere,
	-- Origins' native 25 included: the user asked for exactly two states, not
	-- for a 100/25/off ladder. Live both ways; see prone_bonus_monitor() in
	-- quality_of_life.gsc and origins_change_patch() in zm_tomb\zm_tomb.gsc.
	T(QolButtons, LocalClientIndex, "PERK BONUS POINTS",  "perk_bonus_points",    "Prone at a perk machine for +100, once per machine.")

	-- v1.99.73, user request 2026-08-19. OFF by default - it is new behaviour,
	-- and every switch on this tab leaves the mod as it was until thrown.
	-- Deadshot's stock effect is aim-assist only, so on mouse and keyboard the
	-- perk does nothing at all; this is what makes it worth buying either way.
	T(QolButtons, LocalClientIndex, "BETTER DEADSHOT",    "better_deadshot",      "Deadshot doubles bullet headshot damage, on mouse and controller.")
	-- ========================================================================
	--  v2.2.0 - BETTER SPEED COLA, directly under BETTER DEADSHOT as asked.
	--  User, 2026-08-21: *"make speed cola, like black ops 1 zombies, make speed
	--  cola make the animations for rebuilding barriers twice as fast."*
	--
	--  🌟 TREYARCH WROTE THIS AND A TYPO SWITCHED IT OFF.
	--  _zm_blockers::has_blocker_affecting_perk() returns the string
	--  "specialty_fastreload", and replace_chunk() then tests it against
	--  "speciality_fastreload" - an extra i - so the branch NEVER runs and the
	--  board-rebuild scalar stays 1.0. Speed Cola has never sped up boarding in
	--  retail BO2. Same class of shipped misspelling as the LUI beingAnimation
	--  one. See zmqol_replace_chunk() in quality_of_life.gsc for the two halves.
	-- ========================================================================
	T(QolButtons, LocalClientIndex, "BETTER SPEED COLA",  "better_speed_cola",    "Speed Cola rebuilds barriers twice as fast, like Black Ops 1.")

	-- v1.99.83, queue item 11. ON by default - the animated Pack-a-Punch camo
	-- is behaviour the mod has always had on Mob, Buried and Origins, so the
	-- switch changes nothing until it is thrown. OFF is exact stock: camo 39,
	-- the static one, on all three. The three per-map dvars anim_pap_camo_mob /
	-- _buried / _origins are untouched and still work from the console; this
	-- row is ANDed with them, so nobody's saved per-map setting is lost.
	-- 🛑 It decides the camo at the moment a gun is Pack-a-Punched. A gun
	-- already in your hands keeps the camo it was given - stock caches the
	-- weapon options per weapon and the options are baked into the carried
	-- weapon. See get_pack_a_punch_weapon_options() in quality_of_life.gsc.

	-- v1.99.83, queue item 30. OFF by default, and that is not a typo: the box
	-- with NO limits is what this mod has always shipped, so DISABLED is the
	-- existing behaviour and the switch changes nothing until it is thrown.
	-- ENABLED restores the base game exactly - one Ray Gun, no pulling a gun you
	-- already hold, per-map wonder-weapon caps - by putting stock's own three
	-- checks back in stock's own order. It is live: flip it and the next spin
	-- obeys it. See treasure_chest_canplayerreceiveweapon() in
	-- maps\mp\zombies\_zm_magicbox.gsc.
	-- v1.99.91 - renamed and inverted at the user's request (2026-08-20). ON is
	-- the unlocked box (duplicates, Mk1 + Mk2, no wonder-weapon cap), OFF is
	-- vanilla box rules with the mod's custom guns still in the roster. The dvar
	-- had to change with it - see the migration in qol_options::init().
	T(QolButtons, LocalClientIndex, "NO BOX LIMITS",      "no_box_limits",      "Unlocked mystery box: duplicates and no caps. Off is vanilla rules.")

	-- v1.99.83, queue item 25. ON by default - Zombie Blood, Blood Money and the
	-- Death Machine are drops the mod already ships, so the switch changes
	-- nothing until it is thrown. OFF is the stock power-up table.
	-- 🛑 Origins keeps its own Zombie Blood and its own dig-site Blood Money
	-- either way: the mod never registers Zombie Blood there, and Origins
	-- includes Blood Money in its own main(). OFF means "vanilla for this map",
	-- not "no Zombie Blood anywhere".
	-- 📝 Takes effect on the next map: these are registrations that happen once
	-- at load, not per drop.
	T(QolButtons, LocalClientIndex, "CUSTOM POWER-UPS",   "custom_powerups",    "The mod's extra drops. Off leaves the stock power-ups only.")

	-- ========================================================================
	--  v2.8.0 - PERMA-PERKS, queue item 29. User, 2026-08-20, settled the same
	--  day: ENABLED = every perma-perk the map has is active immediately with no
	--  challenge progress needed; DISABLED = stock, earned normally, and is the
	--  default, so the switch changes nothing until it is thrown.
	--
	--  🛑 IT NEVER REGISTERS AN UPGRADE, which is what keeps the user's own
	--  scope rule (*"don't add perma perks that aren't meant to be on other
	--  maps, like perma phd"*). Only TranZit, Die Rise and Buried register any at
	--  all, and Perma-PhD is Buried's alone; the GSC zeroes the threshold of
	--  names already in level.pers_upgrades and adds none.
	--
	--  📝 Classic only - stock gates the whole perma-perk system on is_classic(),
	--  so the row does nothing in Survival or Grief. Said in the GSC too.
	--
	--  🛑 THE HALF-SPACER ABOVE INSTANT PAP WENT TO PAY FOR THIS ROW. GAME was
	--  14 rows + 1 half-spacer = 14.5 pitches; a 15th row would have made it
	--  15.5, which is the exact figure the v1.99.33 report measured colliding
	--  with the ESC prompt. 15 rows + no spacer = 15.0, the proven ceiling the
	--  SOUND tab already ships at. The cost is the visual break between the
	--  client/session rows and the gameplay rows - restore the spacer and move
	--  this row to CHEATS if that grouping matters more.
	-- ========================================================================
	T(QolButtons, LocalClientIndex, "PERMA-PERKS",        "perma_perks",        "Every perma-perk this map has, active from the start.")

	-- ========================================================================
	--  v2.1.2 - THE TWO MATCH-START FLASH ROWS MOVED HERE FROM THE HUD TAB.
	--
	--  Not a change of heart about where they belong - a row budget. ROUND
	--  COUNTER LEFT took HUD to 16 rows and its hint line landed on the ESC
	--  prompt; the full measurement is in CreateQolHudTab. The user picked these
	--  two to move, and this is the tab with the room: 11 rows + 1 half-spacer
	--  was 11.5 pitches, and 13.5 is still well inside the proven 15.0.
	--
	--  🛑 BOTH DVARS ARE UNCHANGED - intro_credits and flash_help. Moving a row
	--  between tabs never renames its dvar, exactly as renaming a label never
	--  does: the name is archived in every player's config and it is what the
	--  console takes.
	--
	--  🌟 v2.14.14 - THE TWO ROWS ARE NOW ONE FOUR-WAY ROW, flash_intro.
	--
	--  User, 2026-09-08: *"combine them into 1 option to save space for another
	--  option ... one cycleable option where you can choose from just flash
	--  credits, just flashing help, flashing both, or nothing popping up at all
	--  (Disabled)"*. Same shape as the GAME TIMERS merge (v2.1.3, HUD tab):
	--
	--        1 = both (the shipped default)   2 = credits only
	--        3 = help only                    0 = off
	--
	--  1 is "both" because intro_credits "1" + flash_help "1" was the shipped
	--  default, so the migration is the identity for every player on defaults.
	--  The user's own order is what the row cycles through; addChoice order is
	--  what shows, the number behind it is free.
	--
	--  🛑 THE OLD DVARS ARE NOT RENAMED, THEY ARE MIGRATED. QolMigrateFlash reads
	--  intro_credits and flash_help ONCE, while flash_intro is still empty, and
	--  writes the value that means the same thing; qol_options.gsc's
	--  qol_opt_flash_seed() does the identical derivation for a player who never
	--  opens this menu. Same table on both sides - change one and change the
	--  other. Nothing reads the two old names any more.
	--
	--  📝 The freed pitch is left FREE on purpose - that was the point of the
	--  request. GAME is 14 rows + 0 spacers = 14.0, one full row under the 15.0
	--  ceiling. Do not spend it on a spacer.
	-- ========================================================================
	CoD.OptionsSettings.QolMigrateFlash()
	C(QolButtons, LocalClientIndex, "FLASH MESSAGES",     "flash_intro",        "Text flashed at match start: the credits, how to find the chat commands, both, or nothing.", {
		{ "CREDITS",        2 },
		{ "HELP",           3 },
		{ "CREDITS + HELP", 1 },
		{ "DISABLED",       0 }
	})

	-- 🛑 v1.99.61 - INTRO CREDITS IS GONE FROM THIS TAB. It moved to HUD and was
	-- renamed FLASH CREDITS (user, 2026-08-18: *"it should be under the HUD tab
	-- as it's a heads-up display element"*). Its DVAR is still intro_credits -
	-- same call as whoswho_knife and move_speed: the name is already archived in
	-- players' configs and it is what the console takes, so renaming it would
	-- silently reset everyone's saved setting.
	--
	-- Removing the last row left a TRAILING spacer, which is the same layout
	-- fault as two spacers touching. It went with the row.

	-- 🛑 STALE COUNT FIXED 2026-08-27 - this said "11 rows + 1 spacer = 11.5" from
	-- v2.1.2 onward, three additions behind: BETTER SPEED COLA (v2.2.0),
	-- NO BOX LIMITS and CUSTOM POWER-UPS (v1.99.83) never updated it. Recounted
	-- directly against the T() calls above, not against the old comment.
	-- 🛑 STALE AGAIN, FIXED 2026-08-30 - said "14 rows + 1 spacer = 14.5";
	-- PERMA-PERKS (v2.8.0) was added and the spacer had already gone. Recounted
	-- against the T() calls: 15 rows, no spacer - also at the 15.0 ceiling.
	-- v2.14.14 - FLASH CREDITS + FLASH HELP became the one FLASH MESSAGES row:
	-- 13 T() + 1 C() = 14 rows, no spacer. One row of room, kept free on purpose.
	return QolContainer                              -- 14 rows + 0 spacers = 14.0
end

CoD.OptionsSettings.CreateQolHudTab = function (QolHudTab, LocalClientIndex)
	local QolHudContainer = LUI.UIContainer.new()
	local QolHudButtons = CoD.Options.CreateButtonList()
	QolHudTab.buttonList = QolHudButtons
	QolHudContainer:addElement(QolHudButtons)

	local T = CoD.OptionsSettings.QolToggle
	local C = CoD.OptionsSettings.QolChoice

	-- HUD elements, and nothing else.                                15 rows
	T(QolHudButtons, LocalClientIndex, "HUD",               "hud_master",     "Master switch for the whole HUD.")
	-- v2.14.7, user request (queued as B-CROSSHAIR, asked again 2026-09-06).
	-- Sits next to HITMARKERS because that row's own description is about the
	-- crosshair. ENABLED is stock. The GSC half is qol_options.gsc's
	-- qol_opt_crosshair(), and its banner says why it writes three client dvars.
	T(QolHudButtons, LocalClientIndex, "CROSSHAIR",         "crosshair",      "The crosshair in the middle of the screen.")
	T(QolHudButtons, LocalClientIndex, "HITMARKERS",        "hitmarkers",     "Hit and kill markers on your crosshair.")
	T(QolHudButtons, LocalClientIndex, "ROUND SUMMARY",     "round_summary",  "Stats pop-up after each round.")
	-- v1.98.0, user request 2026-08-16.
	T(QolHudButtons, LocalClientIndex, "PERK POP-UP",       "hud_perk_popup", "Icon and name shown when you buy a perk.")
	-- v1.99.0, user request 2026-08-16.
	T(QolHudButtons, LocalClientIndex, "POWER-UP TIMERS",   "hud_powerup_timers", "Seconds left under each power-up icon.")
	-- ========================================================================
	--  🌟 v2.1.3 - THE TWO TIMER ROWS ARE ONE FOUR-WAY ROW NOW.
	--
	--  User, 2026-08-21: *"for the timers remove both of them and turn them it
	--  into one option called 'GAME TIMERS' and make it cycleable, So it'd be 4
	--  options 'GAME TIMER', 'ROUND TIMER', 'GAME TIMER + ROUND TIMER', 'OFF'."*
	--
	--  🛑 A MERGE CANNOT KEEP BOTH OLD DVARS - a dvar selector writes exactly
	--  one name - so this row takes a NEW one, hud_timers, and NOBODY'S SAVED
	--  SETTING IS LOST: QolMigrateTimers below reads the two old archived dvars
	--  ONCE and writes the matching four-way value. hud_timer and hud_round_timer
	--  stay registered (an old config line is harmless), they are simply no
	--  longer what the HUD reads.
	--
	--  Values are NOT the display order, on purpose:
	--        1 = both   2 = game only   3 = round only   0 = off
	--  1 is "both" because that is what the shipped default hud_timer "1" plus
	--  hud_round_timer "1" already meant, so the migration is the identity for
	--  every player on defaults. The user's own order is what the row cycles
	--  through; addChoice order is what shows, the number behind it is free.
	-- ========================================================================
	CoD.OptionsSettings.QolMigrateTimers()
	C(QolHudButtons, LocalClientIndex, "GAME TIMERS",       "hud_timers",     "Match time and round time, under the round number.", {
		{ "GAME TIMER",                2 },
		{ "ROUND TIMER",               3 },
		{ "GAME TIMER + ROUND TIMER",  1 },
		{ "OFF",                       0 }
	})
	-- 🌟 v2.1.2 - WAS THE TOGGLE "ROUND COUNTER LEFT". User request, 2026-08-21:
	-- *"rename that to ROUND COUNTER POSITION and make it 2 cycleable options
	-- LEFT, or RIGHT"*. RIGHT is listed first because it is value 0, the stock
	-- side and the shipped default, so the row reads the same way round as every
	-- DISABLED/ENABLED row in this file.
	-- 🛑 THE DVAR IS STILL hud_round_left. Same call as whoswho_knife, move_speed
	-- and lod_fix: the label changed, the name in the player's config did not.
	-- The GSC reads it as a plain 0/1 in three places
	-- (quality_of_life.gsc:15428, qol_options.gsc:1595 and :1972), and RIGHT=0 /
	-- LEFT=1 is exactly what the old toggle wrote, so nobody's saved setting
	-- changes meaning.
	-- 🌟 v2.1.3 - A THIRD CHOICE, OFF. User, 2026-08-21: *"for the Round
	-- position thingy on top of the left or right cycleable options, add a third
	-- 'off' options so you can turn it off entirely."*
	-- 🛑 OFF IS 2, AND 2 STILL ANCHORS RIGHT. Every reader of this dvar used to
	-- be a plain `!= 0` test meaning "left", so all three - the two
	-- zmqol_hud_round_anchor() twins and qol_opt_hud_watcher - now test `== 1`
	-- instead. Getting that wrong would put the timers on the left whenever the
	-- counter was switched off. The timers keep their own y; only the round
	-- number goes, which is what "turn it off" asks for.
	C(QolHudButtons, LocalClientIndex, "ROUND COUNTER POSITION","hud_round_left", "Which corner the round number sits in, or off entirely.", {
		{ "RIGHT", 0 },
		{ "LEFT",  1 },
		{ "OFF",   2 }
	})
	T(QolHudButtons, LocalClientIndex, "HEALTH BAR",        "hud_health_bar", "Your health bar, bottom left.")
	-- v1.99.1, user request 2026-08-16. Belongs in HUD despite HUD being the
	-- longest tab: it draws a progress bar and a text line on the HUD, so the
	-- file's own sorting rule puts it here. 12 pitches, inside the proven 14.5.
	T(QolHudButtons, LocalClientIndex, "BLEEDOUT BAR",      "hud_bleedout_bar", "Countdown bar shown while you are downed.")
	T(QolHudButtons, LocalClientIndex, "ZOMBIES REMAINING", "hud_remaining",  "How many zombies are left.")
	T(QolHudButtons, LocalClientIndex, "ZONE NAME",         "hud_zone",       "Name of the area you are in.")
	-- v1.99.26, user request 2026-08-17. 13 pitches, inside the proven 14.5.
	T(QolHudButtons, LocalClientIndex, "COMPASS",           "hud_compass",    "Heading you are facing, top of the screen.")
	T(QolHudButtons, LocalClientIndex, "VELOCITY METER",    "velocity",       "Your speed. Green, yellow, red.")
	-- v2.14.16, user request 2026-09-08. 15 rows = 15.0 pitches, the measured
	-- ceiling (see the note above CreateQolHudTab) - this tab is now FULL. The
	-- GSC half is scripts/zm/zmqol_subtitles.gsc; the text is one stringtable
	-- per map inside mod.ff. Default OFF, like every row added after launch.
	-- v2.14.24 - three-way, user request 2026-09-08. 1 = text only (a config
	-- holding the old toggle's 1 lands here); 2 = "[Name] " in front of every
	-- line. Read per line in zmqol_subtitles.gsc, nothing else reads it.
	C(QolHudButtons, LocalClientIndex, "SUBTITLES",         "hud_subtitles",  "Spoken lines as text at the bottom of the screen. Simultaneous voices stack without covering each other.", {
		{ "OFF",               0 },
		{ "SUBTITLES",         1 },
		{ "SUBTITLES + NAMES", 2 }
	})

	-- ========================================================================
	--  v1.99.61 - THE TWO MATCH-START FLASH LINES, user request 2026-08-18.
	--
	--  FLASH CREDITS is the old GAME-tab row INTRO CREDITS, moved here and
	--  renamed: *"it should be under the HUD tab as it's a heads-up display
	--  element/hud element, not a general gameplay/game overhaul"*.
	--  🛑 THE DVAR IS STILL intro_credits. Renaming a row's label never renames
	--  its dvar in this file - the name is archived in every player's config and
	--  it is what the console takes. Same call as whoswho_knife and move_speed.
	--
	--  FLASH HELP is new and points players at the chat command list, so they
	--  can find .help without being told about it out of band.
	--
	--  🛑 ROW BUDGET: this takes HUD from 13 to 15 rows = 15.0 pitches. That is
	--  NOT a guess - it is exactly the SOUND tab's shipped total (14 rows + 2
	--  half spacers), the configuration measured off the user's own screenshot
	--  in v1.99.33 and found to leave ~27 px of clear air under the hint line,
	--  more than the 22 px between two ordinary rows. In game there is a further
	--  50 px because SYSTEM TEST is absent there. See the long measurement note
	--  in CreateSoundTab.
	--
	--  🛑 v2.1.2 - BOTH FLASH ROWS ARE GONE FROM THIS TAB. They are built in
	--  CreateQolTab (the GAME tab) now, and the two dvars are untouched.
	--
	--  ROUND COUNTER LEFT (v2.0.8) had taken this tab to 16 rows and the user
	--  reported the result: *"the description for the currently selected option
	--  ... and where it says ESC back it being overlapped/bugged"*. That is
	--  measured, not inferred - scanning their 2000x1125 screenshot for text
	--  bands in the label column gives rows on a 50 px pitch from y=234, so:
	--
	--      FLASH HELP, the 16th row         984 - 1013 px
	--      hint line                       1035 - 1061 px
	--      ESC Back                        1036 - 1061 px   (same band)
	--
	--  The hint line always draws ONE FULL ROW-PITCH below the last row, and the
	--  ESC prompt is anchored to the menu at y=1036 whatever the list does, so
	--  hint_top = 234 + pitches * 50. 15.0 pitches puts it at 984 and clears the
	--  prompt by 24 px; 16.0 puts it at 1034 and lands on top of it. Confirmed
	--  against the PATCHES tab in the same set of screenshots (12.0 pitches ->
	--  hint at 788, exactly as the formula says). There were no spacers left on
	--  this tab to spend, so a row had to leave.
	--
	--  The user chose the two FLASH rows (2026-08-21) over moving ROUND SUMMARY
	--  or splitting HUD in two. They are match-start announcements rather than
	--  persistent HUD elements, they go together, and moving both leaves this tab
	--  at 14.0 with a full row of headroom for the next HUD option.
	--  📝 This does reverse v1.99.61's move of INTRO CREDITS into HUD; the user
	--  was told that explicitly before choosing.
	-- ========================================================================

	-- 🌟 v2.1.3 - 13 rows now: GAME TIMER + ROUND TIMER became one GAME TIMERS
	-- row. 13.0 pitches puts the hint line at 234 + 13*50 = 884 px, 152 px clear
	-- of the ESC prompt at 1036, and the longest description here is 55 chars so
	-- nothing wraps. Two full rows of headroom for the next HUD option.
	-- v2.14.7 - CROSSHAIR spends one of those two: 14 rows = 14.0 pitches, hint
	-- line at 234 + 14*50 = 934 px, still 102 px clear of the ESC prompt and a
	-- row under the 15.0 ceiling this file measured on the SOUND tab.
	return QolHudContainer                                          -- 15 total (v2.14.16: at the 15.0 ceiling)
end

-- ============================================================================
--  v1.99.93 - THE PATCHES TAB. User request, 2026-08-20.
--
--  *"add a new tab after the GAME tab called PATCHES, this will contain all
--  Patch toggles like backspeed patch, and inside the new patches menu along
--  with the other existing patches that were transitioned from the game menu to
--  this new one, add the REMOVE ROUND CAP toggle ... also add these toggles to
--  the patches menu: 24 Zombies Round Limit on solo play, Instakill rounds start
--  on round 163, Double-tap reverted to 1.0 toggle, Sliquifier pre-patch/pre-
--  nerf by treyarch, Weapon recoil pre-patched/pre-nerf, No zombies attacking
--  through barriers."*
--
--  🛑 THE TWO MOVED ROWS KEEP THEIR DVARS. move_speed and anim_pap_camo are
--  already archived in players' configs and are the names the console takes;
--  moving a row between tabs must never rename one. Same rule as the v1.99.52
--  BACKSPEED PATCH relabel.
--
--  🌟 THE FIVE NEW ROWS ARE A PORT OF THE USER'S OWN REFERENCE, not a design.
--  legacy-decompiled.gsc - the "legacy" pre-patch mod they supplied -
--  is four replaceFuncs and an init, and every row below is one line of it:
--      round cap        stock round_think clamps `if (255 < round) round = 255`
--      24 solo zombies  level.zombie_total = 23 while solo past round 5
--      instakill 163    ai_calculate_health capped at ai_zombie_health( 155 )
--      double tap 1.0   setdvar perk_weapRateEnhanced 0
--      barrier attacks  should_attack_player_thru_boards returns false
--  See the block above zmqol_patches_watch() in quality_of_life.gsc for what
--  each one does and how it is applied without a replaceFunc where possible.
--
--  🛑 TWO OF THE SEVEN THE USER ASKED FOR ARE NOT HERE, AND THE REASON IS NOT
--  EFFORT - each is provably wrong on this build, so shipping the row would ship
--  a switch that does nothing or the opposite of its label:
--
--    SLIQUIFIER PRE-NERF. Legacy sets slipgun_reslip_rate = 0, but the shipped
--      script reads it as `if ( level.zombie_vars["slipgun_reslip_rate"] > 0 &&
--      randomint( ... ) == 0 )` ( _zm_weap_slipgun.gsc:745 ), so 0 means NEVER
--      re-slip, not always. Its other line, slipgun_max_kill_round = undefined,
--      feeds ai_zombie_health( undefined ) at :65 and leaves the goo WEAKER.
--      No pre-patch copy of that script exists in the workspace to port instead
--      - BO2-Raw-files' base decompile carries the same 6 / 100 values as the
--      patch fastfile does.
--
--    RECOIL PRE-NERF. `sv_patch_zm_weapons` does not exist on this build: it is
--      absent from the boot dvar dump (2,764 dvars, alphabetical, with sv_paused
--      and sv_playlistFetchInterval either side of where it would sit), from
--      t6zm.exe's string table, from Plutonium's bootstrapper, and from
--      dvar_descriptions.json. setdvar would create a dvar nothing reads.
--
--  📝 ALL FIVE DEFAULT OFF except REMOVE ROUND CAP, which defaults ON because the
--  cap is ALREADY absent from this mod's round_think() and has been since the
--  Cold War round HUD shipped - so ON is what the mod already does, and OFF is
--  the row that changes something (it puts stock's clamp back). A new switch
--  must never change existing behaviour until it is thrown.
-- ============================================================================
CoD.OptionsSettings.CreateQolPatchesTab = function (QolPatchesTab, LocalClientIndex)
	local QolPatchesContainer = LUI.UIContainer.new()
	local QolPatchesButtons = CoD.Options.CreateButtonList()
	QolPatchesTab.buttonList = QolPatchesButtons
	QolPatchesContainer:addElement(QolPatchesButtons)

	local T = CoD.OptionsSettings.QolToggle

	-- Moved here from the GAME tab, dvars unchanged.                  2 rows
	T(QolPatchesButtons, LocalClientIndex, "BACKSPEED PATCH",     "move_speed",          "Walk backwards and sideways at full speed.")
	T(QolPatchesButtons, LocalClientIndex, "NETWORK FRAME PATCH", "network_frame_patch", "Solo runs on the console's fixed 100ms network frame instead of PC timing.")
	-- 🛑 v2.1.2 - GRAPHICS BOOST IS NOT HERE ANY MORE. It moved to the stock
	-- ADVANCED tab at the user's request, 2026-08-21, where the dvars it
	-- overwrites already live. Its dvar is unchanged (graphics_boost) and so is
	-- its behaviour; see the note in CreateAdvancedTab. This tab is now 10 rows
	-- + 2 half-spacers = 11.0 pitches.
	T(QolPatchesButtons, LocalClientIndex, "ANIMATED CAMO PATCH", "anim_pap_camo",       "Animated Pack-a-Punch camo on every map.")


	-- The legacy / pre-patch restorations.                            5 rows
	T(QolPatchesButtons, LocalClientIndex, "REMOVE ROUND CAP",    "remove_round_cap",    "Rounds carry on past 255. Off puts the stock cap back.")
	T(QolPatchesButtons, LocalClientIndex, "24 ZOMBIE SOLO CAP",  "solo_zombie_limit",   "Solo rounds past 5 stop growing the horde, like World at War.")
	T(QolPatchesButtons, LocalClientIndex, "INSTAKILL ROUNDS",    "instakill_rounds",    "Zombie health overflows at round 163 and resets, so one shot kills. Like Black Ops 1.")
	T(QolPatchesButtons, LocalClientIndex, "DOUBLE TAP 1.0",      "double_tap_1",        "Double Tap only makes you shoot faster, like World at War and Black Ops 1. No extra damage.")
	T(QolPatchesButtons, LocalClientIndex, "NO BARRIER ATTACKS",  "no_barrier_attacks",  "Zombies cannot reach through boarded windows.")


	-- ========================================================================
	--  v1.99.96 - THE TWO DIE RISE ROWS. User request 2026-08-20, from
	--  BO2-Remix's Die Rise feature list: *"all 4 of these options implement
	--  them into my mod"*. Both rows are now gone and both features live on
	--  without a switch, so this block is history, not layout:
	--
	--  🛑 v2.14.17 - "SLIQUIFIER PRE-NERF" WAS HERE AND IS GONE. User,
	--  2026-09-08: *"remove the option for sliquifier pre nerf patch, and then
	--  make it so that the sliquifier is pack a punchable with my mod, and the
	--  pack a punch version is infinite damage like the pre nerf version"*. The
	--  row, its `sliquifier_prenerf` dvar and every reader of it are deleted;
	--  the Sliquifier can now be Pack-a-Punched instead, and the packed gun is
	--  the one that kills at any round. That needs no row - it is a weapon you
	--  earn, not a setting. GAME 2 drops from 15.0 pitches to 14.0.
	--
	--  🛑 v2.0.2 - "SEMTEX WALL BUY" WAS HERE AND IS GONE. User, 2026-08-20,
	--  screenshot `gxxTTWxkHW.jpg`: *"this semtex wall buy should just be apart
	--  of the mod not an option you can toggle on or off, so get rid of that
	--  option and just keep the added wallbuys i told you to add earlier."*
	--  The wall buy itself stays and is now unconditional; only the switch went.
	--  Its `semtex_wallbuy` dvar is retired with it (create_dvar removed from
	--  quality_of_life.gsc, the read removed from zm_highrise.gsc), so nothing
	--  is left reading a dvar no menu writes.
	-- ========================================================================
	-- ========================================================================
	--  v2.2.0 - NO BLEEDOUT PATCH. User, 2026-08-21: *"add an option to the
	--  patches to tab called NO BLEEDOUT PATCH, which as the name suggests,
	--  makes it so zombies don't die by themselves after being alive for too
	--  long or getting stuck, so that way the player would have to actually kill
	--  the zombies themself, so the zombies don't just randomly die."*
	--
	--  🌟 IT IS STOCK'S OWN SWITCH. maps\mp\zombies\_zm::round_spawn_failsafe()
	--  runs on every zombie: every 30 seconds it checks whether the zombie moved
	--  24 units, and kills it if not. The whole loop is already gated on
	--  level.zombie_vars["zombie_use_failsafe"]. Nothing is invented.
	--
	--  🛑 THE FALL-OUT-OF-THE-WORLD KILL IS KEPT ON. The same function also kills
	--  a zombie that drops below level.zombie_vars["below_world_check"], and that
	--  one has to stay: a zombie under the map cannot be shot, so removing it
	--  would end the round forever rather than making the player earn the kill.
	--  See zmqol_round_spawn_failsafe() in quality_of_life.gsc.
	-- ========================================================================
	T(QolPatchesButtons, LocalClientIndex, "NO BLEEDOUT PATCH",    "no_bleedout",         "Stuck zombies stay alive. You have to kill every one yourself.")

	-- ========================================================================
	--  v2.7.0 - NO LAVA DAMAGE. User, 2026-08-28: *"add an option ... that lets
	--  you turn off the lava in-game, it'll still obviously be visible on the
	--  ground and what not, but zombies wont be able to be lit on fire and
	--  explode once shot/killed, and the player will no longer take damage from
	--  standing on any pits of lava."* TranZit-family only (Classic TranZit,
	--  Diner, Farm, Town, Bus Depot). Shown on every map, same as the other
	--  map-specific rows on this tab (NO BLEEDOUT PATCH above).
	-- ========================================================================
	T(QolPatchesButtons, LocalClientIndex, "NO LAVA DAMAGE",     "no_lava_damage",      "TranZit maps. The lava still glows, but it stops burning you and the zombies.")

	-- ========================================================================
	--  v2.7.2 - 3 HIT DOWN. User, 2026-08-28: *"add '3 HIT DOWN' which as the
	--  name suggests, makes the player have the same kinda health as black ops
	--  3 zombies and onwards"*. Caps a single zombie melee hit's damage at
	--  maxhealth/3, so no round's melee scaling can down you in fewer than 3
	--  hits. See zmqol_three_hit_down_install() in quality_of_life.gsc.
	-- ========================================================================
	T(QolPatchesButtons, LocalClientIndex, "3 HIT DOWN",         "three_hit_down",      "A zombie can never down you in fewer than 3 hits, the way Black Ops 3 does it.")

	-- ========================================================================
	--  v2.8.2 - WINTER'S HOWL INFINITE. User request 2026-08-29, for the BO1
	--  port this mod already ships. OFF = the gun's shipped damage numbers.
	--
	--  🌟 The direct hit is raised to the target's own health, so it is a kill
	--  at any round; the shatter blast uses a constant, because radiusDamage has
	--  no single target to read a health off. 📝 The blast therefore stops being
	--  a guaranteed kill past roughly round 163, where zombie health overflows
	--  past it - the direct hit still is. Stated rather than hidden.
	--
	--  📝 Range is deliberately untouched: the request was infinite damage, not
	--  infinite reach, and widening the blast would change WHERE the gun kills.
	--  Does nothing on a map without the gun.
	-- ========================================================================
	T(QolPatchesButtons, LocalClientIndex, "WINTERS HOWL BUFF", "winters_howl_infinite", "The Winter's Howl kills anything it hits. Its blast range is unchanged.")

	-- ========================================================================
	--  v2.8.2 - ROUND DELAY OFF. User request 2026-08-29: no wait between
	--  rounds. Two waits make up that gap and this row removes both:
	--    · round_over()'s wait on zombie_between_round_time - 10 seconds
	--    · round_one_up()'s round-announce beat - 2.5 seconds
	--  The announcer, the music cue and the round HUD all still play; the second
	--  one is simply threaded instead of blocking the spawner. 🛑 Never on the
	--  first round, which is the map intro. See this mod's round_think().
	-- ========================================================================
	T(QolPatchesButtons, LocalClientIndex, "ROUND DELAY OFF",    "round_delay_off",     "No pause between rounds. Removes the 10 second gap and the round announce wait.")
	T(QolPatchesButtons, LocalClientIndex, "NO WALKERS",         "no_walkers",          "Every zombie sprints from round 10. No walkers to break up a train.")

	-- 🛑 STALE COUNT FIXED 2026-08-27 - said "9 total"; NO BLEEDOUT PATCH (v2.2.0)
	-- was added without updating it. Recounted directly against the T() calls.
	-- v2.8.2 - two rows added (WINTER'S HOWL INFINITE, ROUND DELAY OFF).
	-- v2.8.6 - NO WALKERS added, and BOTH half-spacers removed to pay for it:
	-- 15 rows + 0 spacers = 15.0 pitches, exactly the measured ceiling in the
	-- note above. This tab is FULL. Do not add a 16th row without moving one off.
	return QolPatchesContainer                                      -- 15 total
end

-- ============================================================================
--  v2.12.5 - THE "GAME 3" TAB. User request, 2026-09-05.
--
--  *"rename GAME to GAME 1, PATCHES to GAME 2, then add a new tab right after
--  GAME 2 named GAME 3 ... In the 3rd GAME tab add an option to turn tranzit
--  denizens on/off (enabled/disabled), disabled is standard vanilla behaviour,
--  setting it to enabled makes no denizens spawn in the fog so they wont annoy
--  the player."*
--
--  🌟 THE TAB EXISTS BECAUSE THE OTHER TWO ARE MEASURABLY FULL, not as a
--  preference. CreateQolTab returns 15.0 row-pitches and CreateQolPatchesTab
--  returns 15.0, and 15.0 is the ceiling derived in the note above CreateQolTab
--  from the user's own overflow screenshots. A 16th row on either one is the
--  reported bug, not a risk of it.
--
--  📝 ROOM LEFT: 12 more rows (v2.14.28) before this tab reaches the same ceiling. When
--  the next option needs a home, it belongs here rather than on GAME 1 or 2.
--
--  📝 The label reads NO DENIZENS rather than DENIZENS so that ENABLED is the
--  state that changes something, which is how every other row in this menu
--  works (NO WALKERS, NO LAVA DAMAGE, NO BARRIER ATTACKS). DISABLED is stock,
--  exactly as asked.
-- ============================================================================
CoD.OptionsSettings.CreateQolGame3Tab = function (QolGame3Tab, LocalClientIndex)
	local QolGame3Container = LUI.UIContainer.new()
	local QolGame3Buttons = CoD.Options.CreateButtonList()
	QolGame3Tab.buttonList = QolGame3Buttons
	QolGame3Container:addElement(QolGame3Buttons)

	local T = CoD.OptionsSettings.QolToggle

	--                                                                  3 rows
	T(QolGame3Buttons, LocalClientIndex, "NO DENIZENS", "no_denizens", "TranZit. No denizens spawn in the fog. Any already out are left alone.")

	-- ========================================================================
	--  v2.14.13 - THIRD PERSON. User request 2026-09-07: "put a 3rd person
	--  toggle in the GAME 3 tab in the mod". Read once a second per player by
	--  qol_options.gsc::qol_opt_third_person(), which drives the engine's own
	--  setclientthirdperson() - the method stock zombies uses for its own
	--  third-person moments (_zm.gsc::set_third_person) - never the
	--  cheat-protected cg_thirdPerson dvar. Live both ways, and re-applied
	--  after every spawn because stock's onplayerspawned() switches it off.
	-- ========================================================================
	T(QolGame3Buttons, LocalClientIndex, "THIRD PERSON", "third_person", "Play from a camera behind your character. Off is the normal first-person view.")

	-- ========================================================================
	--  v2.14.28 - KNIFE LUNGE. User request 2026-09-08: "add an option in GAME
	--  3 called KNIFE LUNGE and by default it's set to enabled (vanilla
	--  behaviour), or you can set it to disabled so that you can no longer
	--  lunge when meleeing". ENABLED = stock, so this is the one row in the
	--  menu where ENABLED is the state that changes nothing - deliberately, as
	--  asked. The default 1 is seeded by qol_options.gsc (qol_opt_dvar), the
	--  same way BLEEDOUT BAR's is; the row is applied per player, once a
	--  second, by qol_options.gsc::qol_opt_knife_lunge().
	-- ========================================================================
	T(QolGame3Buttons, LocalClientIndex, "KNIFE LUNGE", "knife_lunge", "The melee charge that pulls you onto a zombie. Disable it to knife in place.")

	return QolGame3Container                          -- 3 rows + 0 spacers = 3.0
end

CoD.OptionsSettings.CreateQolCheatsTab = function (QolCheatsTab, LocalClientIndex)
	local QolCheatsContainer = LUI.UIContainer.new()
	local QolCheatsButtons = CoD.Options.CreateButtonList()
	QolCheatsTab.buttonList = QolCheatsButtons
	QolCheatsContainer:addElement(QolCheatsButtons)

	local T = CoD.OptionsSettings.QolToggle

	-- 🛑 godmode / ghostmode, NOT god / ghost. Those two names belong to the
	-- mod's CHAT-COMMAND dvar channel, which blanks them the moment they are
	-- written - so the v1.94.0 rows switched themselves straight back off. See
	-- the long note in zmqol_toggle_dvar_watch() in quality_of_life.gsc.
	--                                                                 7 rows
	T(QolCheatsButtons, LocalClientIndex, "GOD MODE",        "godmode",        "You cannot be damaged.")
	T(QolCheatsButtons, LocalClientIndex, "GHOST",           "ghostmode",      "Zombies ignore you.")
	T(QolCheatsButtons, LocalClientIndex, "INFINITE AMMO",   "infinite_ammo",  "Never run out of ammo.")
	T(QolCheatsButtons, LocalClientIndex, "INFINITE SPRINT", "infinite_sprint","Sprint without tiring.")
	T(QolCheatsButtons, LocalClientIndex, "FLY MODE",        "fly",            "Noclip. Melee to stop.")
	T(QolCheatsButtons, LocalClientIndex, "RAPID FIRE",      "rapid_fire",     "Faster firing on every weapon.")
	T(QolCheatsButtons, LocalClientIndex, "NO POWER NEEDED", "no_power",       "Perks and doors work without power.")
	-- ========================================================================
	--  v2.8.2 - ONE SHOT ONE KILL. User request 2026-08-29.
	--
	--  🌟 It rides the level.callbackactordamage chain the mod already installs
	--  for BETTER DEADSHOT - no second hook, no new failure mode. GSC raises the
	--  damage to exactly the target's own health rather than to a big constant,
	--  because zombie health keeps doubling up to a 32-bit overflow at high
	--  rounds and no fixed number is both large enough there and safe from
	--  overflowing when a boss damage func multiplies it.
	--
	--  🛑 BOSSES KEEP THEIR OWN RULES. The Panzer's faceplate, Brutus's helmet
	--  and the Avogadro's EMP-only immunity all live in self.actor_damage_func,
	--  which stock runs after this. Forcing those open would delete the boss
	--  fights rather than cheat them.
	--
	--  🛑 In QolNoArchive, like every other CHEATS row.
	-- ========================================================================
	T(QolCheatsButtons, LocalClientIndex, "ONE SHOT ONE KILL", "one_shot_one_kill", "Every hit you land kills a zombie outright. Bosses keep their own armour rules.")

	-- ========================================================================
	--  v1.99.86, queue item 32 - three ACTION rows, user request 2026-08-19.
	--
	--  🌟 These are not settings, they are one-shot actions, and they use the
	--  shape zmqol_round_dvar_watch() already had for set_round: the row writes
	--  a value, GSC does the thing and writes the dvar back to 0, so the row
	--  snaps back to DISABLED / OFF by itself. That is why KILL HORDE and END
	--  ROUND read as toggles that will not stay on - they are buttons.
	--
	--  🛑 ALL THREE ARE IN QolNoArchive, and that is not optional. An archived
	--  `set_round 50` would jump the player to round 50 on their next launch
	--  before they had touched anything, and an archived `kill_horde 1` would
	--  fire the moment a map loaded. Same reason fly and godmode are in there.
	--
	--  📝 Console twins, per this project's rule that every row is bindable:
	--  `set_round <n>`, `kill_horde 1`, `end_round 1`. set_round is also the
	--  existing `.round <n>` chat command.
	-- ========================================================================
	-- ========================================================================
	--  v2.2.0 - 500 / 1000 / 10000, and ONLY WITH THE ROUND CAP OFF.
	--  User, 2026-08-21: *"for the change round cheat add 3 more options, round
	--  500, 1000, 10000 but only of course if the 255 round cap has been turned
	--  off via the patch in options for it."*
	--
	--  🌟 THE GSC SIDE ALREADY AGREES, so this row and the jump cannot disagree:
	--  zmqol_goto_round() clamps to 255 when remove_round_cap is 0, matching
	--  stock's own clamp in round_think() (_zm.gsc:3516). Hiding the three rows
	--  here is the same test, read live off the same dvar - so with the cap on
	--  the player is never offered a number the jump would truncate.
	--
	--  📝 remove_round_cap DEFAULTS TO 1 in qol_options.gsc, so out of the box
	--  the three rows are there. The read is pcall'd like every other one in
	--  this file; if it ever throws, the extra rows are simply not offered.
	-- ========================================================================
	local ZmQolRounds = {
		{ "OFF", 0 }, { "1", 1 }, { "5", 5 }, { "10", 10 }, { "15", 15 },
		{ "20", 20 }, { "25", 25 }, { "30", 30 }, { "40", 40 }, { "50", 50 },
		{ "75", 75 }, { "100", 100 }, { "150", 150 }, { "200", 200 }, { "255", 255 }
	}

	local CapOk, CapValue = pcall(UIExpression.DvarString, nil, "remove_round_cap")

	if CapOk and tonumber(CapValue) ~= nil and tonumber(CapValue) ~= 0 then
		ZmQolRounds[#ZmQolRounds + 1] = { "500", 500 }
		ZmQolRounds[#ZmQolRounds + 1] = { "1000", 1000 }
		ZmQolRounds[#ZmQolRounds + 1] = { "10000", 10000 }
	end

	CoD.OptionsSettings.QolChoice(QolCheatsButtons, LocalClientIndex, "CHANGE ROUND", "set_round",
		"Jump to a round. Returns to OFF once it fires.", ZmQolRounds)
	T(QolCheatsButtons, LocalClientIndex, "KILL HORDE",      "kill_horde",     "Kill every zombie on the map. Bosses are left alone.")
	T(QolCheatsButtons, LocalClientIndex, "END ROUND",       "end_round",      "Finish this round now.")

	-- ========================================================================
	--  v1.99.93 - SET POINTS. User request, 2026-08-20:
	--  *"works similar the round change option you can set it to certain
	--  amounts, so like for the Set Points it'd start at 0 (none) and then go to
	--  1000 points, 5000 points, 10000 points, 100000 points, 1000000 points.
	--  And the reason it's "set" points instead of "give" points is so if you
	--  wanna revert it, say you switch it to one hundred thousand points, you
	--  can just go back and set it to a lower number and have that amount."*
	--
	--  🛑 IT IS NOT AN ACTION ROW, AND THAT IS THE WHOLE REQUEST. CHANGE ROUND /
	--  KILL HORDE / END ROUND write themselves back to 0 the instant they fire;
	--  this one must HOLD its value, because 0 is a real setting here (set me to
	--  zero points) and because the user wants to step back down the list. So
	--  GSC applies it on CHANGE only - zmqol_set_points_watch() remembers what it
	--  last applied and does nothing until the row moves.
	--
	--  🛑 IN QolNoArchive, like every other CHEATS row: an archived
	--  set_points 1000000 would hand out a million points on the next launch
	--  before the player had touched anything.
	-- ========================================================================
	CoD.OptionsSettings.QolChoice(QolCheatsButtons, LocalClientIndex, "SET POINTS", "set_points",
		"Sets your points to this amount. Pick a lower one to go back down.", {
			{ "NONE", 0 }, { "1000", 1000 }, { "5000", 5000 }, { "10000", 10000 },
			{ "100000", 100000 }, { "1000000", 1000000 }
		})

	-- ========================================================================
	--  v1.99.93 - TELEPORT, ported from the Strat Tester. User request,
	--  2026-08-20: *"add the teleport menu from the strat tester to my cheats
	--  tab in my mod."*
	--
	--  🌟 THE DESTINATIONS ARE THE STRAT TESTER'S OWN, copied value for value out
	--  of Strat-Tester-BO2\scripts\zm\strattester\commands.gsc::tpcase()
	--  - position AND angles - so each one lands facing the way it does there.
	--  Nothing is invented: a map that has no list in that file (Nuketown) gets
	--  no row at all rather than a made-up destination.
	--
	--  🛑 THE LIST IS BUILT PER MAP, HERE, because the row has to name real
	--  places. `mapname` is set by the time the in-game pause menu is built -
	--  this is the same UIExpression.DvarString call QolArchive already uses.
	--  The VALUES are indices into the matching list in
	--  quality_of_life.gsc::zmqol_teleport_dest(), and the two lists must stay in
	--  the same order. They are written next to each other for that reason.
	--
	--  🛑 v2.4.2 - NO LONGER AN ACTION ROW BY ITSELF. User, 2026-08-26: cycling
	--  through destinations here was firing the teleport as soon as it left the
	--  pause menu, with no separate confirm step - unlike the Strat Tester's own
	--  menu (optionsstrattester.lua:240-293), which has this exact selector PLUS
	--  a separate "EXECUTE TELEPORT" button. This row now only HOLDS the picked
	--  destination (same shape as SET POINTS); the EXECUTE TELEPORT row right
	--  below is what actually moves the player. See zmqol_teleport_watch().
	-- ========================================================================
	local ZmMap = UIExpression.DvarString(nil, "mapname")
	local ZmTele = nil

	if ZmMap == "zm_transit" then
		ZmTele = { { "OFF", 0 }, { "DINER", 1 }, { "FARM", 2 }, { "TOWN", 3 }, { "BUS DEPOT", 4 },
			{ "TUNNEL", 5 }, { "NACHT", 6 }, { "POWER STATION", 7 }, { "AK74U", 8 }, { "WAREHOUSE", 9 } }
	elseif ZmMap == "zm_prison" then
		ZmTele = { { "OFF", 0 }, { "CAFETERIA", 1 }, { "CAGE", 2 }, { "WARDEN'S OFFICE", 3 }, { "DOUBLE TAP", 4 } }
	elseif ZmMap == "zm_highrise" then
		ZmTele = { { "OFF", 0 }, { "SHAFT", 1 }, { "TRAMPLESTEAM", 2 } }
	elseif ZmMap == "zm_buried" then
		ZmTele = { { "OFF", 0 }, { "SALOON", 1 }, { "JUGGERNOG", 2 }, { "TUNNEL", 3 } }
	elseif ZmMap == "zm_tomb" then
		ZmTele = { { "OFF", 0 }, { "CHURCH", 1 }, { "CRAZY PLACE", 2 }, { "GENERATOR 1", 3 },
			{ "GENERATOR 2", 4 }, { "GENERATOR 3", 5 }, { "GENERATOR 4", 6 }, { "GENERATOR 5", 7 },
			{ "GENERATOR 6", 8 }, { "TANK", 9 } }
	elseif ZmMap == "zm_nuked" then
		-- v2.10.4 - the map's own three player_respawn_point structs, measured
		-- from zm_nuked.ff's mapents; see zmqol_teleport_dest() for the
		-- derivation. Same index order as the GSC switch, always.
		ZmTele = { { "OFF", 0 }, { "SPAWN", 1 }, { "GREEN HOUSE BACKYARD", 2 }, { "YELLOW HOUSE BACKYARD", 3 } }
	end

	if ZmTele ~= nil then
		CoD.OptionsSettings.QolChoice(QolCheatsButtons, LocalClientIndex, "TELEPORT", "teleport",
			"Pick a landmark on this map, then use EXECUTE TELEPORT below to jump there.", ZmTele)

		T(QolCheatsButtons, LocalClientIndex, "EXECUTE TELEPORT", "execute_teleport",
			"Teleport to the destination picked above. Returns to OFF once it fires.")
	end


	-- 🛑 STALE COUNT FIXED 2026-08-27 - said "12 total"; SET POINTS (v1.99.93) was
	-- added without updating it. Recounted directly: 11 rows always present
	-- (GOD MODE..SET POINTS) + TELEPORT/EXECUTE TELEPORT on every map.
	-- v2.8.2 - ONE SHOT ONE KILL added to the always-present block.
	-- v2.10.4 - Nuketown got its landmark list, so the pair is on all six maps
	-- now and the row count is the same everywhere.
	return QolCheatsContainer                        -- 14 total, on every map
end

-- HUD and Cheats used to be the final two tabs on OptionsSettingsMenu. Keeping
-- them there made the tab strip wider than smaller displays could show. They
-- now have their own entries on OptionsMenu, between Settings and Controls.
CoD.OptionsSettings.CreateQolPageMenu = function (MenuName, Title, PageBuilder, LocalClientIndex)
	local PageMenu = nil
	local InGame = UIExpression.IsInGame() == 1

	if InGame then
		PageMenu = CoD.InGameMenu.New(MenuName, LocalClientIndex, Engine.Localize(Title))
		if PageMenu.titleElement then
			PageMenu.titleElement:setAlignment(LUI.Alignment.Center)
		end
	else
		PageMenu = CoD.Menu.New(MenuName)
		PageMenu:addTitle(Engine.Localize(Title), LUI.Alignment.Center)
		PageMenu:addLargePopupBackground()
	end

	PageMenu.addApplyPrompt = CoD.Options.AddApplyPrompt
	PageMenu.addResetPrompt = CoD.Options.AddResetPrompt
	PageMenu:setPreviousMenu("OptionsMenu")
	PageMenu:setOwner(LocalClientIndex)
	PageMenu:registerEventHandler("add_apply_prompt", CoD.Options.AddApplyPrompt)
	PageMenu:registerEventHandler("button_prompt_back", CoD.OptionsSettings.Back)
	PageMenu:registerEventHandler("selector_changed", CoD.OptionsSettings.SelectorChanged)
	PageMenu:addSelectButton()
	PageMenu:addBackButton()

	local PageContainer = PageBuilder(PageMenu, LocalClientIndex)
	PageMenu:addElement(PageContainer)

	if not PageMenu:restoreState() and PageMenu.buttonList then
		local FirstButton = PageMenu.buttonList:getFirstChild()
		if FirstButton then
			FirstButton:processEvent({ name = "gain_focus" })
		end
	end

	return PageMenu
end

LUI.createMenu.OptionsQolHudMenu = function (LocalClientIndex)
	return CoD.OptionsSettings.CreateQolPageMenu(
		"OptionsQolHudMenu", "HUD", CoD.OptionsSettings.CreateQolHudTab, LocalClientIndex
	)
end

LUI.createMenu.OptionsQolCheatsMenu = function (LocalClientIndex)
	return CoD.OptionsSettings.CreateQolPageMenu(
		"OptionsQolCheatsMenu", "CHEATS", CoD.OptionsSettings.CreateQolCheatsTab, LocalClientIndex
	)
end

LUI.createMenu.OptionsSettingsMenu = function (LocalClientIndex)
	local OptionsSettingsWidget = nil
	local InGame = UIExpression.IsInGame() == 1
	-- ========================================================================
	--  zm_qol v1.95.1 - THE HEADING READS "QUALITY OF LIFE" AND IS CENTRED.
	--  User, 2026-08-14: "move where it says settings on the top left in the
	--  pause menu to where the arrow faces, which is centered, and rename it
	--  from SETTINGS to QUALITY OF LIFE."
	--
	--  🛑 THE IN-GAME PATH CANNOT PASS AN ALIGNMENT. CoD.InGameMenu.New(name,
	--  controller, title) calls addTitle(title) with ONE argument, and
	--  CoD.Menu.addTitle(text, alignment) defaults to LUI.Alignment.Left - which
	--  is why the heading sits top-left in game and centred out of game (the
	--  else-branch below has always passed Center).
	--
	--  🌟 READ OUT OF THE SHIPPED BYTECODE, NOT GUESSED. The constant table of
	--  BO2-Raw-files\ui\t6\codmenu.lua shows addTitle building
	--      self.titleElement = LUI.UIText.new() ... :setAlignment( <alignment> )
	--  and a sibling setTitle() that writes through the same handle. So
	--  titleElement is the real field name and setAlignment is the real method;
	--  re-aligning after construction is the supported route, not a second
	--  addTitle call that would stack two heading elements.
	--
	--  Guarded anyway: an unexpected nil here would hard-crash LUI, and a
	--  left-aligned heading is a cosmetic loss, not a broken menu.
	-- ========================================================================
	-- 🛑 v2.2.0 - with another mod loaded (or none) the heading stays stock and
	-- none of this mod's tabs are added. See ZmQolModLoaded() at the top.
	local ZmQolLoaded = ZmQolModLoaded()
	local ZmQolMenuTitle = Engine.Localize("QUALITY OF LIFE")
	if not ZmQolLoaded then
		ZmQolMenuTitle = Engine.Localize("MENU_SETTINGS_CAPS")
	end
	if InGame then
		OptionsSettingsWidget = CoD.InGameMenu.New("OptionsSettingsMenu", LocalClientIndex, ZmQolMenuTitle)
		if ZmQolLoaded and OptionsSettingsWidget.titleElement then
			OptionsSettingsWidget.titleElement:setAlignment(LUI.Alignment.Center)
		end
	else
		OptionsSettingsWidget = CoD.Menu.New("OptionsSettingsMenu")
		OptionsSettingsWidget:addTitle(ZmQolMenuTitle, LUI.Alignment.Center)
		OptionsSettingsWidget:addLargePopupBackground()
	end
	OptionsSettingsWidget.addApplyPrompt = CoD.Options.AddApplyPrompt
	OptionsSettingsWidget.addResetPrompt = CoD.Options.AddResetPrompt
	OptionsSettingsWidget:setPreviousMenu("OptionsMenu")
	OptionsSettingsWidget:setOwner(LocalClientIndex)
	OptionsSettingsWidget:registerEventHandler("add_apply_prompt", CoD.Options.AddApplyPrompt)
	OptionsSettingsWidget:registerEventHandler("button_prompt_back", CoD.OptionsSettings.Back)
	OptionsSettingsWidget:registerEventHandler("tab_changed", CoD.OptionsSettings.TabChanged)
	OptionsSettingsWidget:registerEventHandler("selector_changed", CoD.OptionsSettings.SelectorChanged)
	OptionsSettingsWidget:registerEventHandler("resolution_changed", CoD.OptionsSettings.ResolutionChanged)
	OptionsSettingsWidget:registerEventHandler("apply_changes", CoD.OptionsSettings.ApplyChanges)
	OptionsSettingsWidget:registerEventHandler("restore_default_settings", CoD.OptionsSettings.RestoreDefaultSettings)
	OptionsSettingsWidget:registerEventHandler("open_brightness", CoD.OptionsSettings.OpenBrightness)
	OptionsSettingsWidget:registerEventHandler( "open_mature_content", CoD.OptionsSettings.OpenMatureContent )
	OptionsSettingsWidget:registerEventHandler("open_speaker_setup", CoD.AudioSettings.OpenSpeakerSetup)
	OptionsSettingsWidget:registerEventHandler("open_apply_popup", CoD.OptionsSettings.OpenApplyPopup)
	OptionsSettingsWidget:registerEventHandler("open_default_popup", CoD.OptionsSettings.OpenDefaultPopup)
	OptionsSettingsWidget:registerEventHandler("open_safe_area", CoD.OptionsSettings.OpenSafeArea)
	OptionsSettingsWidget:addSelectButton()
	OptionsSettingsWidget:addBackButton()
	if not InGame then
		OptionsSettingsWidget:addResetPrompt()
	end
	if CoD.OptionsSettings.NeedVidRestart or CoD.OptionsSettings.NeedPicmip or CoD.OptionsSettings.NeedSndRestart then
		OptionsSettingsWidget:addApplyPrompt()
	end
	if not CoD.OptionsSettings.DoNotSyncProfile then
		Engine.SyncHardwareProfileWithDvars()
	end
	CoD.OptionsSettings.DoNotSyncProfile = nil
	-- zm_qol v1.95.1 - 800 -> 700, because the tabs were renamed GAME and HUD.
	-- v1.95.0 raised stock's 500 to 800; THAT is what pulled the arrows off the
	-- text in the first place.
	--
	-- CoD.Options.SetupTabManager(widget, HorizontalOffset) does
	--     GenericTabManager:setLeftRight(false, false, -HorizontalOffset/2, HorizontalOffset/2)
	-- so the number is the TOTAL WIDTH of the tab strip container, centred, and
	-- the left/right arrows are drawn at its two edges. The tabs themselves are
	-- centre-aligned inside it and their width does not depend on it - so a
	-- container narrower than the labels puts both arrows on top of the text,
	-- which is exactly the screenshot: left arrow over "GRAPHICS", right arrow
	-- over "QUALITY OF LIFE". 500 was stock's value for FOUR tabs.
	--
	-- 🌟 MEASURED, NOT GUESSED. Scanned the user's 2000x1125 screenshot for the
	-- five label runs in the tab band (LUI is 1280x720, so exactly 1.5625 px per
	-- unit):
	--     GRAPHICS 536..645   ADVANCED 727..841   SOUND 924..997
	--     VOICE CHAT 1078..1207   QUALITY OF LIFE 1289..1465
	-- Five labels span 929 px = 595 units; stock's four span 675 px = 432 units
	-- inside the 500 container, i.e. stock leaves ~34 units of margin per side.
	-- The six labels are now GRAPHICS ADVANCED SOUND VOICE CHAT GAME HUD, and
	-- the two short names make the strip NARROWER than the five-tab version:
	-- 527 px of glyphs plus five 82 px gaps = 937 px = 600 units. 600 + 68 = 668
	-- is the minimum, so 700 leaves ~32 px of margin per side - stock's is 31.
	-- 800 would now leave 82 px per side and push the arrows visibly away from
	-- the text, which is the opposite of what was asked for.
	--
	-- 🌟 700 is also BO2-Reimagined's shipped value for a six-tab settings strip
	-- labelled GRAPHICS ADVANCED SOUND VOICE CHAT GAME MOD - the same label set
	-- to within one three-letter word (its ui/t6/options.lua, line 661).
	--
	-- 🌟 v1.96.0 - 700 -> 800, BECAUSE A SEVENTH TAB WAS ADDED (CHEATS), and the
	-- number is re-derived from the SAME pixel measurements rather than nudged.
	-- From the scan above: the inter-label gap is a constant 82 px, and the
	-- measured labels average ~14 px per capital glyph (GRAPHICS 109/8,
	-- ADVANCED 114/8, SOUND 73/5). CHEATS is 6 glyphs, so ~84 px, and it costs
	-- one extra gap as well:
	--     six tabs   937 px  = 600 units   (measured, v1.95.1)
	--     + 82 gap + 84 glyphs  ->  1103 px = 706 units
	-- Stock leaves ~34 units of margin per side, so the minimum here is
	-- 706 + 68 = 774. 800 leaves 47 units (73 px) per side.
	--
	-- 🛑 THE ERROR IS DELIBERATELY BIASED WIDE. Too narrow is the REPORTED bug -
	-- the arrows draw on top of the labels (v1.93.0/v1.95.0). Too wide only
	-- pushes the arrows a little further out, which nobody has ever reported.
	-- CHEATS's width is the one estimated quantity here, so the margin absorbs it.
	--
	-- 🌟 v2.0.2 - 800 -> 900, BECAUSE THE EIGHTH TAB (PATCHES) LANDED IN v1.99.93
	-- AND THIS NUMBER WAS NOT RE-DERIVED WITH IT. User, 2026-08-20, screenshot
	-- `peENVCHd5W.jpg`: *"since you added the patches menu to the settings, the
	-- arrows are now colliding with the menu options"* - the left arrow sits on
	-- the "A" of GRAPHICS and the right arrow inside CHEATS. Exactly the v1.95.0
	-- bug again, from exactly the same cause.
	--
	-- 🌟 NOTHING IS ESTIMATED THIS TIME. Both CHEATS and PATCHES now exist on
	-- screen, so the whole strip was measured off the user's 2560x1440 shot
	-- `gxxTTWxkHW.jpg` by scanning the tab band (y 210-245) for lit columns.
	-- 2560 px = 1280 LUI units, so 2 px per unit:
	--     GRAPHICS   457..598 px      ADVANCED  701..848
	--     SOUND      954..1048        VOICE CHAT 1152..1315
	--     GAME      1421..1496        PATCHES   1599..1728
	--     HUD       1833..1887        CHEATS    1993..2101
	-- Strip = 457..2101 px = 1644 px = 822 units, centred on 1279 px (= 639.5
	-- units, i.e. screen centre, which is the check that the scan is sound).
	--
	-- The same scan finds the two arrows at 496..512 px and 2037..2063 px - and
	-- 800 units puts the container edges at 480 px and 2080 px. That is the
	-- collision, measured rather than inferred: the container is 822 units of
	-- labels inside an 800-unit box, so both arrows are drawn INSIDE the text.
	--
	-- Stock leaves ~34 units of margin per side, so the minimum is 822 + 68 =
	-- 890. 900 leaves 39 units (78 px) per side - 5 units more than stock's, and
	-- still biased wide for the reason above.
	--  v2.2.0 - 900 is the EIGHT-tab width. With no zm_qol tabs the strip is
	--  stock's four, so it takes stock's own 500 - measured the same way, and it
	--  is the number in the pristine .bak-before-gametab copy.
	--
	-- 🌟 v2.12.5 - 900 -> 1020, BECAUSE THE NINTH TAB (GAME 3) LANDS HERE AND
	-- TWO LABELS CHANGE LENGTH. Re-derived from the SAME 2560x1440 scan quoted
	-- above rather than nudged, because that scan is the only measured source
	-- this file has. From it: 911 px of glyphs over 51 characters = 17.9 px per
	-- character, and (2101-457) - 911 = 733 px over 7 gaps = 104.7 px per gap.
	-- Both hold at 2 px per LUI unit.
	--
	-- The nine labels are now
	--     GRAPHICS(8) ADVANCED(8) SOUND(5) VOICE CHAT(10)
	--     GAME 1(6) GAME 2(6) GAME 3(6) HUD(3) CHEATS(6)   = 58 characters
	--     58 x 18 px glyphs           = 1044 px
	--     8 x 104.7 px gaps           =  838 px
	--     strip                       = 1882 px = 941 units
	-- Stock leaves ~34 units of margin per side, so the minimum is 941 + 68 =
	-- 1009. 1020 leaves 39.5 units (79 px) per side - the same clearance 900
	-- gave the eight-tab strip, and biased wide for the reason stated above:
	-- too narrow is the REPORTED bug (v1.93.0, v1.95.0, v2.0.2), too wide has
	-- never been reported.
	--
	-- 📝 The container is centred, so 1020 puts its edges - and therefore the
	-- two navigation arrows - at 130 and 1150 of the 1280-unit screen, while
	-- the labels span 169.5..1110.5. Nothing else draws in that band.
	--
	-- 🛑 RENAMING IS NOT FREE. GAME -> "GAME 1" adds two characters and
	-- PATCHES -> "GAME 2" removes one; a rename that changes the strip's width
	-- has to come back through this arithmetic, exactly like adding a tab does.
	local SettingsTabs = CoD.Options.SetupTabManager(OptionsSettingsWidget, (ZmQolLoaded and 830) or 500)
	SettingsTabs:addTab(LocalClientIndex, "MENU_GRAPHICS_CAPS", CoD.OptionsSettings.CreateGraphicsTab)
	SettingsTabs:addTab(LocalClientIndex, "MENU_ADVANCED_CAPS", CoD.OptionsSettings.CreateAdvancedTab)
	SettingsTabs:addTab(LocalClientIndex, "MENU_SOUND_CAPS", CoD.OptionsSettings.CreateSoundTab)
	SettingsTabs:addTab(LocalClientIndex, "MENU_VOICECHAT_CAPS", CoD.OptionsSettings.CreateVoiceChatTab)
	if not ZmQolLoaded then
		--  🛑 A remembered tab index from a zm_qol session can point past the
		--  four stock tabs. CurrentTabIndex is a file-level value that survives
		--  in this same Lua state, so clamp it rather than hand loadTab an
		--  index that does not exist.
		if CoD.OptionsSettings.CurrentTabIndex and CoD.OptionsSettings.CurrentTabIndex > 4 then
			CoD.OptionsSettings.CurrentTabIndex = 1
		end
		if CoD.OptionsSettings.CurrentTabIndex then
			SettingsTabs:loadTab(LocalClientIndex, CoD.OptionsSettings.CurrentTabIndex)
		else
			SettingsTabs:refreshTab(LocalClientIndex)
		end
		return OptionsSettingsWidget
	end
	-- zm_qol: LAST, after VOICE CHAT. Registering it first is what broke the
	-- navigation arrows in v1.93.0 - see the note above CreateQolTab.
	-- Engine.Localize falls back to the literal when a key does not exist, which
	-- is how this renders as "QUALITY OF LIFE" with no new localize entry;
	-- Plutonium's own line for FOV SENSITIVITY relies on the same behaviour.
	-- 🌟 v2.12.5 - "GAME" IS NOW "GAME 1", "PATCHES" IS NOW "GAME 2", AND
	-- "GAME 3" IS NEW. User request, 2026-09-05: *"rename GAME to GAME 1,
	-- PATCHES to GAME 2, then add a new tab right after GAME 2 named GAME 3 ...
	-- the reasoning for adding the 3rd new tab is because there wouldn't be
	-- enough space on either the current GAME or PATCHES tab to add this option
	-- without it causing a collision issue"*.
	--
	-- 🌟 THAT REASONING IS CORRECT AND THIS FILE ALREADY SAID SO. Both existing
	-- tabs return exactly 15.0 row-pitches, which is the measured ceiling in the
	-- note above CreateQolTab; the comment at the end of each one has said "do
	-- not add a 16th row without moving one off" since v2.8.6. A third tab is
	-- the only way to add a row without displacing one.
	--
	-- 📝 NO DVAR IS RENAMED BY ANY OF THIS. The labels are display strings and
	-- nothing else; every row keeps the dvar it already has, so no player's
	-- archived setting moves. Same rule as the v1.99.52 BACKSPEED PATCH relabel.
	--
	-- 📝 Engine.Localize falls back to the literal for a key it does not know,
	-- which is how "GAME"/"PATCHES"/"HUD"/"CHEATS" have always rendered here -
	-- "GAME 1" and the rest go through the same path, space and digit included.
	SettingsTabs:addTab(LocalClientIndex, "GAME 1", CoD.OptionsSettings.CreateQolTab)
	-- v1.99.93 - the PATCHES tab, directly after GAME as asked then; renamed
	-- GAME 2 in v2.12.5, contents untouched.
	SettingsTabs:addTab(LocalClientIndex, "GAME 2", CoD.OptionsSettings.CreateQolPatchesTab)
	-- v2.12.5 - GAME 3, directly after GAME 2 as asked.
	SettingsTabs:addTab(LocalClientIndex, "GAME 3", CoD.OptionsSettings.CreateQolGame3Tab)
	if CoD.OptionsSettings.CurrentTabIndex then
		if CoD.OptionsSettings.CurrentTabIndex > 7 then
			CoD.OptionsSettings.CurrentTabIndex = 1
		end
		SettingsTabs:loadTab(LocalClientIndex, CoD.OptionsSettings.CurrentTabIndex)
	else
		SettingsTabs:refreshTab(LocalClientIndex)
	end
	return OptionsSettingsWidget
end

CoD.OptionsSettings.OpenSafeArea = function (OptionsSettingsWidget, ClientInstance)
	OptionsSettingsWidget:saveState()
	OptionsSettingsWidget:openMenu("SafeArea", ClientInstance.controller)
	OptionsSettingsWidget:close()
end

-- options.lua has finished defining the parent menu by the time the mod reloads
-- this file. Wrap its category builder so the stock Settings and Controls code
-- remains untouched, including Plutonium's additions.
if ZmQolModLoaded() and CoD.Options and CoD.Options.AddOptionCategories and
	LUI.createMenu.OptionsMenu and not ZmQolParentMenuWrapped then
	ZmQolParentMenuWrapped = true

	CoD.Options.OpenQolHud = function (OptionsMenuWidget, ClientInstance)
		if OptionsMenuWidget:getParent() then
			OptionsMenuWidget:saveState()
			OptionsMenuWidget:openMenu("OptionsQolHudMenu", ClientInstance.controller)
			OptionsMenuWidget:close()
		end
	end

	CoD.Options.OpenQolCheats = function (OptionsMenuWidget, ClientInstance)
		if OptionsMenuWidget:getParent() then
			OptionsMenuWidget:saveState()
			OptionsMenuWidget:openMenu("OptionsQolCheatsMenu", ClientInstance.controller)
			OptionsMenuWidget:close()
		end
	end

	local StockAddOptionCategories = CoD.Options.AddOptionCategories
	CoD.Options.AddOptionCategories = function (OptionsMenuWidget)
		if not ZmQolModLoaded() then
			return StockAddOptionCategories(OptionsMenuWidget)
		end

		local StockButtonListNew = CoD.ButtonList.new

		CoD.ButtonList.new = function (...)
			local ButtonList = StockButtonListNew(...)
			local SettingsLabel = Engine.Localize("MENU_SETTINGS_CAPS")
			local AddedQolPages = false

			local function AddQolButtons(AddButton)
				if AddedQolPages then
					return
				end
				AddedQolPages = true

				local HudButton = AddButton("HUD", "open_qol_hud")
				local CheatsButton = AddButton("CHEATS", "open_qol_cheats")

				if UIExpression.IsInGame() == 0 and not CoD.isSinglePlayer then
					HudButton.brackets:close()
					HudButton.m_skipAnimation = true
					CheatsButton.brackets:close()
					CheatsButton.m_skipAnimation = true
				end
			end

			if ButtonList.addButton then
				local StockAddButton = ButtonList.addButton
				ButtonList.addButton = function (Self, Label, ...)
					local Button = StockAddButton(Self, Label, ...)
					if Label == SettingsLabel then
						AddQolButtons(function (QolLabel, EventName)
							local QolButton = StockAddButton(Self, Engine.Localize(QolLabel))
							QolButton:setActionEventName(EventName)
							return QolButton
						end)
					end
					return Button
				end
			end

			if ButtonList.addNavButton then
				local StockAddNavButton = ButtonList.addNavButton
				ButtonList.addNavButton = function (Self, Label, EventName, ...)
					local Button = StockAddNavButton(Self, Label, EventName, ...)
					if Label == SettingsLabel then
						AddQolButtons(function (QolLabel, QolEventName)
							return StockAddNavButton(Self, Engine.Localize(QolLabel), QolEventName)
						end)
					end
					return Button
				end
			end

			return ButtonList
		end

		local Ok, Result = pcall(StockAddOptionCategories, OptionsMenuWidget)
		CoD.ButtonList.new = StockButtonListNew

		if not Ok then
			return StockAddOptionCategories(OptionsMenuWidget)
		end

		return Result
	end

	local StockOptionsMenu = LUI.createMenu.OptionsMenu
	LUI.createMenu.OptionsMenu = function (LocalClientIndex)
		local OptionsMenuWidget = StockOptionsMenu(LocalClientIndex)
		OptionsMenuWidget:registerEventHandler("open_qol_hud", CoD.Options.OpenQolHud)
		OptionsMenuWidget:registerEventHandler("open_qol_cheats", CoD.Options.OpenQolCheats)
		return OptionsMenuWidget
	end
end
