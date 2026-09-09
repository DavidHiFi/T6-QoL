CoD.PowerUps = {}
CoD.PowerUps.IconSize = 48
CoD.PowerUps.UpgradeIconSize = 36
CoD.PowerUps.Spacing = 8
CoD.PowerUps.STATE_OFF = 0
CoD.PowerUps.STATE_ON = 1
CoD.PowerUps.STATE_FLASHING_OFF = 2
CoD.PowerUps.STATE_FLASHING_ON = 3
CoD.PowerUps.FLASHING_STAGE_DURATION = 500
CoD.PowerUps.MOVING_DURATION = 500
-- zm_qol v1.99.2: height of the power-up timer text band. The timer sits in its
-- own band directly ABOVE the icon (user, 2026-08-16), so the widget is this much
-- taller than stock's and the upgrade badge rides that much higher. Keeping it a
-- named constant is what stops the two from ever overlapping.
CoD.PowerUps.ZmqolTimerHeight = 18
CoD.PowerUps.UpGradeIconColorRed = {
	r = 1,
	g = 0,
	b = 0
}
CoD.PowerUps.ClientFieldNames = {}
CoD.PowerUps.ClientFieldNames[1] = {
	clientFieldName = "powerup_instant_kill",
	material = RegisterMaterial("specialty_instakill_zombies")
}
CoD.PowerUps.ClientFieldNames[2] = {
	clientFieldName = "powerup_double_points",
	material = RegisterMaterial("specialty_doublepoints_zombies"),
	z_material = RegisterMaterial("specialty_doublepoints_zombies_blue")
}
CoD.PowerUps.ClientFieldNames[3] = {
	clientFieldName = "powerup_fire_sale",
	material = RegisterMaterial("specialty_firesale_zombies")
}
CoD.PowerUps.ClientFieldNames[4] = {
	clientFieldName = "powerup_bon_fire",
	material = RegisterMaterial("zom_icon_bonfire")
}
CoD.PowerUps.ClientFieldNames[5] = {
	clientFieldName = "powerup_mini_gun",
	material = RegisterMaterial("zom_icon_minigun")
}
CoD.PowerUps.ClientFieldNames[6] = {
	clientFieldName = "powerup_zombie_blood",
	-- zm_qol v2.2.6 - THE USER'S OWN ZOMBIE BLOOD ICON, UNDER A NAME NOTHING
	-- ELSE OWNS. specialty_zomblood_zombies lives in dlczm4.ipak, and that ipak
	-- is MOUNTED ON EVERY MAP (the user's console_zm.log, line 482, in a
	-- zm_transit session: "Added ipak file: dlczm4"), so no loose .iwi can ever
	-- replace it - which is why their custom art kept coming out stock.
	-- zmqol_zomblood_zombies is in no ipak and no stock fastfile, so the mod's
	-- own image and material simply ARE the asset. Declared in
	-- zone_source\mod_locations.zone; the .iwi ships in images\ (pixels) and
	-- zone_assets\images\ (so the Linker can compile the material).
	material = RegisterMaterial("zmqol_zomblood_zombies")
}
CoD.PowerUps.ClientFieldNames[7] = {
	clientFieldName = "deathmachine_powerup",
	material = RegisterMaterial("ui_powerup_deathmachine")
}
CoD.PowerUps.DeathMachineDvarName = "deathmachine_powerup_state"
CoD.PowerUps.UpgradeClientFieldNames = {}
CoD.PowerUps.UpgradeClientFieldNames[1] = {
	clientFieldName = CoD.PowerUps.ClientFieldNames[1].clientFieldName .. "_ug",
	material = RegisterMaterial("specialty_instakill_zombies"),
	color = CoD.PowerUps.UpGradeIconColorRed
}

CoD.PowerUps.DeathMachineAmmoCounterHidden = {}

CoD.PowerUps.IsDeathMachineAmmoCounterHidden = function (Controller)
	if Controller == nil then
		Controller = 0
	end

	if CoD.PowerUps.DeathMachineAmmoCounterHidden ~= nil and CoD.PowerUps.DeathMachineAmmoCounterHidden[Controller] == true then
		return true
	end

	if UIExpression ~= nil and UIExpression.DvarInt ~= nil then
		local PowerupState = UIExpression.DvarInt(Controller, CoD.PowerUps.DeathMachineDvarName)
		if PowerupState ~= nil and PowerupState ~= CoD.PowerUps.STATE_OFF then
			return true
		end
	end

	return false
end

CoD.PowerUps.HideAmmoDigits = function (Element)
	if Element == nil or Element.ammoDigits == nil then
		return
	end

	for DigitIndex = 1, #Element.ammoDigits, 1 do
		Element.ammoDigits[DigitIndex]:setAlpha(0)
	end
end

CoD.PowerUps.PatchNormalAmmoCounter = function ()
	if CoD.AmmoCounter == nil or CoD.AmmoCounter.deathmachinePatch == true then
		return
	end

	CoD.AmmoCounter.deathmachinePatch = true
	CoD.AmmoCounter.deathmachineOriginalShouldHideAmmoCounter = CoD.AmmoCounter.ShouldHideAmmoCounter
	CoD.AmmoCounter.deathmachineOriginalUpdateVisibility = CoD.AmmoCounter.UpdateVisibility
	CoD.AmmoCounter.deathmachineOriginalUpdateAmmo = CoD.AmmoCounter.UpdateAmmo

	CoD.AmmoCounter.ShouldHideAmmoCounter = function (Element, Event)
		local Controller = nil
		if Event ~= nil then
			Controller = Event.controller
		end

		if CoD.PowerUps.IsDeathMachineAmmoCounterHidden(Controller) then
			return true
		end

		return CoD.AmmoCounter.deathmachineOriginalShouldHideAmmoCounter(Element, Event)
	end

	CoD.AmmoCounter.UpdateVisibility = function (Element, Event)
		local Controller = nil
		if Event ~= nil then
			Controller = Event.controller
		end

		if CoD.PowerUps.IsDeathMachineAmmoCounterHidden(Controller) then
			if Element.animateToState ~= nil then
				Element:animateToState("hide")
			end
			if Element.ammoLabel ~= nil then
				Element.ammoLabel:setAlpha(0)
			end
			Element.visible = nil
			Element:dispatchEventToChildren(Event)
			return
		end

		if Element.ammoLabel ~= nil then
			Element.ammoLabel:setAlpha(1)
		end

		CoD.AmmoCounter.deathmachineOriginalUpdateVisibility(Element, Event)
	end

	CoD.AmmoCounter.UpdateAmmo = function (Element, Event)
		local Controller = nil
		if Event ~= nil then
			Controller = Event.controller
		end

		if CoD.PowerUps.IsDeathMachineAmmoCounterHidden(Controller) then
			if Element.animateToState ~= nil then
				Element:animateToState("hide")
			end
			if Element.ammoLabel ~= nil then
				Element.ammoLabel:setAlpha(0)
			end
			Element.visible = nil
			return
		end

		if Element.ammoLabel ~= nil then
			Element.ammoLabel:setAlpha(1)
		end

		CoD.AmmoCounter.deathmachineOriginalUpdateAmmo(Element, Event)
	end
end

CoD.PowerUps.PatchOtherAmmoCounters = function ()
	if CoD.OtherAmmoCounters == nil or CoD.OtherAmmoCounters.deathmachinePatch == true then
		return
	end

	CoD.OtherAmmoCounters.deathmachinePatch = true
	CoD.OtherAmmoCounters.deathmachineOriginalShouldHideAmmoCounter = CoD.OtherAmmoCounters.ShouldHideAmmoCounter
	CoD.OtherAmmoCounters.deathmachineOriginalUpdateVisibility = CoD.OtherAmmoCounters.UpdateVisibility
	CoD.OtherAmmoCounters.deathmachineOriginalUpdateHeat = CoD.OtherAmmoCounters.UpdateHeat
	CoD.OtherAmmoCounters.deathmachineOriginalUpdateFuel = CoD.OtherAmmoCounters.UpdateFuel

	CoD.OtherAmmoCounters.ShouldHideAmmoCounter = function (Element, Event)
		local Controller = nil
		if Event ~= nil then
			Controller = Event.controller
		end

		if CoD.PowerUps.IsDeathMachineAmmoCounterHidden(Controller) then
			return true
		end

		return CoD.OtherAmmoCounters.deathmachineOriginalShouldHideAmmoCounter(Element, Event)
	end

	CoD.OtherAmmoCounters.UpdateVisibility = function (Element, Event)
		local Controller = nil
		if Event ~= nil then
			Controller = Event.controller
		end

		if CoD.PowerUps.IsDeathMachineAmmoCounterHidden(Controller) then
			Element:beginAnimation("hide")
			Element:setAlpha(0)
			Element.visible = nil
			Element:dispatchEventToChildren(Event)
			return
		end

		CoD.OtherAmmoCounters.deathmachineOriginalUpdateVisibility(Element, Event)
	end

	CoD.OtherAmmoCounters.UpdateHeat = function (Element, Event)
		local Controller = nil
		if Event ~= nil then
			Controller = Event.controller
		end

		if CoD.PowerUps.IsDeathMachineAmmoCounterHidden(Controller) then
			Element:setAlpha(0)
			return
		end

		--  🛑 pcall, not a direct call. This is the exact line that closed the
		--  game in v1.99.23 (COM_ERROR (0), event hud_update_overheat): stock's
		--  UpdateHeat calls the misspelled `beingAnimation`. The alias installed
		--  by zmqolFixOverheatAnimationTypo() is the real fix and this call
		--  should now succeed - but a HUD repaint must never be able to take the
		--  whole game down, so a failure here is contained and recorded once.
		local ok = pcall(CoD.OtherAmmoCounters.deathmachineOriginalUpdateHeat, Element, Event)
		if not ok and CoD.PowerUps.zmqolHeatErrorLogged ~= true then
			CoD.PowerUps.zmqolHeatErrorLogged = true
			CoD.PowerUps.zmqolHeatErrorSeen = true
		end
	end

	CoD.OtherAmmoCounters.UpdateFuel = function (Element, Event)
		local Controller = nil
		if Event ~= nil then
			Controller = Event.controller
		end

		if CoD.PowerUps.IsDeathMachineAmmoCounterHidden(Controller) then
			Element:setAlpha(0)
			return
		end

		CoD.OtherAmmoCounters.deathmachineOriginalUpdateFuel(Element, Event)
	end
end

CoD.PowerUps.PatchZombieAmmoArea = function ()
	if CoD.AmmoAreaZombie == nil or CoD.AmmoAreaZombie.deathmachinePatch == true then
		return
	end

	CoD.AmmoAreaZombie.deathmachinePatch = true
	CoD.AmmoAreaZombie.deathmachineOriginalShouldHideAmmoCounter = CoD.AmmoAreaZombie.ShouldHideAmmoCounter
	CoD.AmmoAreaZombie.deathmachineOriginalUpdateAmmo = CoD.AmmoAreaZombie.UpdateAmmo
	CoD.AmmoAreaZombie.deathmachineOriginalUpdateOverheat = CoD.AmmoAreaZombie.UpdateOverheat
	CoD.AmmoAreaZombie.deathmachineOriginalUpdateVisibility = CoD.AmmoAreaZombie.UpdateVisibility
	CoD.AmmoAreaZombie.deathmachineOriginalUpdateWeapon = CoD.AmmoAreaZombie.UpdateWeapon

	-- ======================================================================
	--  🛑 v1.99.0 - THIS RETURNED `false` AND THAT WAS THE WHOLE ORIGINS BUG.
	--
	--  User, 2026-08-16: *"the ammo counter disappears obviously when you get
	--  the death machine ... but when using it in origins you can still see the
	--  ammo counter."*
	--
	--  ShouldHideAmmoCounter returning false means "do NOT hide me", so this
	--  branch was explicitly telling Origins' counter to stay on screen for the
	--  exact duration the Death Machine was active. Its two siblings in this
	--  file - CoD.AmmoCounter (:102) and CoD.OtherAmmoCounters (:176) - both
	--  `return true` here. This one was the odd one out.
	--
	--  🌟 AND ORIGINS IS THE ONLY MAP THAT COULD SHOW IT, which is why the bug
	--  looked map-specific rather than like a plain typo:
	--  `ui_mp/t6/zombie/ammoareazombie.lua` is shipped by **zm_tomb_patch.ff and
	--  by no other fastfile** - patch_zm.ff carries otherammocounters.lua but no
	--  ammoareazombie.lua at all (checked with Unlinker --list on both). So
	--  CoD.AmmoAreaZombie only ever exists on Origins, and every other map was
	--  hidden correctly by the two siblings above.
	-- ======================================================================
	CoD.AmmoAreaZombie.ShouldHideAmmoCounter = function (Element, Event)
		local Controller = nil
		if Event ~= nil then
			Controller = Event.controller
		end

		if CoD.PowerUps.IsDeathMachineAmmoCounterHidden(Controller) then
			return true
		end

		return CoD.AmmoAreaZombie.deathmachineOriginalShouldHideAmmoCounter(Element, Event)
	end

	CoD.AmmoAreaZombie.UpdateAmmo = function (Element, Event)
		local Controller = nil
		if Event ~= nil then
			Controller = Event.controller
		end

		if CoD.PowerUps.IsDeathMachineAmmoCounterHidden(Controller) then
			CoD.PowerUps.HideAmmoDigits(Element)
			Element:dispatchEventToChildren(Event)
			return
		end

		CoD.AmmoAreaZombie.deathmachineOriginalUpdateAmmo(Element, Event)
	end

	CoD.AmmoAreaZombie.UpdateOverheat = function (Element, Event)
		local Controller = nil
		if Event ~= nil then
			Controller = Event.controller
		end

		if CoD.PowerUps.IsDeathMachineAmmoCounterHidden(Controller) then
			CoD.PowerUps.HideAmmoDigits(Element)
			Element:dispatchEventToChildren(Event)
			return
		end

		CoD.AmmoAreaZombie.deathmachineOriginalUpdateOverheat(Element, Event)
	end

	CoD.AmmoAreaZombie.UpdateVisibility = function (Element, Event)
		CoD.AmmoAreaZombie.deathmachineOriginalUpdateVisibility(Element, Event)

		local Controller = nil
		if Event ~= nil then
			Controller = Event.controller
		end

		if CoD.PowerUps.IsDeathMachineAmmoCounterHidden(Controller) then
			CoD.PowerUps.HideAmmoDigits(Element)
		end
	end

	CoD.AmmoAreaZombie.UpdateWeapon = function (Element, Event)
		CoD.AmmoAreaZombie.deathmachineOriginalUpdateWeapon(Element, Event)

		local Controller = nil
		if Event ~= nil then
			Controller = Event.controller
		end

		if CoD.PowerUps.IsDeathMachineAmmoCounterHidden(Controller) then
			CoD.PowerUps.HideAmmoDigits(Element)
		end
	end
end

CoD.PowerUps.PatchAmmoCounters = function ()
	CoD.PowerUps.PatchNormalAmmoCounter()

	if CoD.OtherAmmoCounters == nil then
		pcall(require, "T6.Zombie.OtherAmmoCounters")  -- pcall: don't hard-crash if the file isn't shipped
	end
	CoD.PowerUps.PatchOtherAmmoCounters()

	if CoD.AmmoAreaZombie == nil and CoD.Zombie ~= nil and CoD.Zombie.IsDLCMap ~= nil then
		if CoD.Zombie.IsDLCMap(CoD.Zombie.DLC2Maps) or CoD.Zombie.IsDLCMap(CoD.Zombie.DLC3Maps) or CoD.Zombie.IsDLCMap(CoD.Zombie.DLC4Maps) then
			pcall(require, "T6.Zombie.AmmoAreaZombie")  -- pcall: this is the DLC-map crash; PatchZombieAmmoArea() no-ops if it fails to load
		end
	end
	CoD.PowerUps.PatchZombieAmmoArea()
end

-- ===========================================================================
--  🌟 v1.99.24 - A TREYARCH TYPO THAT HARD-CRASHES THE GAME
-- ===========================================================================
--  Stock `ui_mp/t6/zombie/otherammocounters.lua` calls **`beingAnimation`** -
--  misspelled - where every other file in the game calls `beginAnimation`.
--  It is in the branch that restores the ammo counter to its normal colour
--  when an overheating weapon finishes cooling down. The method does not
--  exist, so Lua raises "function expected instead of nil", and a LUI error
--  in T6 is fatal: `COM_ERROR (0) LUI_ERROR: Error processing event:
--  hud_update_overheat`. The whole game closes.
--
--  🛑 MEASURED, NOT INFERRED. A string sweep of the shipped bytecode of every
--  LUI file in the game finds `beingAnimation` in **exactly one file** -
--  otherammocounters.lua, once - against `beginAnimation` in dozens,
--  including 7 times in `ui/lui/luielement.lua` where the real method lives.
--
--  WHY NOBODY EVER HIT IT: the only weapons raising this event are the jet gun
--  and the Paralyzer, the jet gun's ammo counter is normally hidden (there is
--  a well-known glitch people use to make it appear at all), and in stock the
--  jet gun EXPLODES the instant it overheats - so it is taken away before it
--  can ever cool back down and reach the bad branch.
--
--  This mod made the jet gun never break (v1.99.23), so for the first time it
--  overheated, held, and cooled back to normal - and hit the typo. The user's
--  account matches the code exactly: it stopped firing, and **then, a few
--  seconds later**, as it finished cooling, the game closed.
--
--  THE FIX: give the misspelling somewhere to land. Aliasing it onto the LUI
--  classes means stock's own code runs, unmodified and complete - nothing of
--  Treyarch's logic is reconstructed or guessed at, which is the whole reason
--  this is an alias rather than a rewrite of UpdateHeat.
--
--  📝 Belt and braces: the alias is the real fix; PatchOtherAmmoCounters also
--  wraps the original call in pcall so that if the alias somehow lands on the
--  wrong class the game still survives. A crash is never an acceptable failure
--  mode for a cosmetic HUD update.
-- ===========================================================================
CoD.PowerUps.zmqolFixOverheatAnimationTypo = function ()
	if LUI == nil then
		return
	end

	local classNames = {
		"UIElement",
		"UIText",
		"UIImage",
		"UIBar",
		"UITimer",
		"UIVerticalList",
		"UIHorizontalList"
	}
	local patched = 0

	for i = 1, #classNames, 1 do
		local class = LUI[classNames[i]]
		if class ~= nil and class.beginAnimation ~= nil and class.beingAnimation == nil then
			class.beingAnimation = class.beginAnimation
			patched = patched + 1
		end
	end

	CoD.PowerUps.zmqolTypoAliasCount = patched
end

CoD.PowerUps.zmqolFixOverheatAnimationTypo()
CoD.PowerUps.PatchAmmoCounters()

-- ===========================================================================
--  zm_qol - THE PERK-ROW OFF-BY-ONE FIX  (stock CoD.Perks.RemovePerkIcon)
-- ===========================================================================
--  Reported repeatedly: own all 12 perks, go down, and the whole perk row
--  collapses into 12 copies of ONE icon, permanently. Whichever perk landed in
--  slot 12 is the one that spams - PhD for the user, Vulture Aid for their
--  friend. It is NOT the chat commands; a down reproduces it on its own
--  (user, 2026-08-09, with a screenshot).
--
--  THE DEFECT IS STOCK'S, in ui_mp/t6/zombie/hudperkszombie.lua. Removing a
--  perk shifts every icon down one slot:
--
--      elseif PerkIndex ~= #CoD.Perks.ClientFieldNames then
--          NextPerkWidget = Menu.perks[PerkIndex + 1]
--      end                          <- no else, so on the LAST index
--                                      NextPerkWidget keeps slot 12 from the
--                                      previous iteration
--
--  Slot 12 then copies ITSELF and breaks without ever clearing. It only fires
--  when the row is 12/12 FULL, which is why Treyarch never saw it and this mod
--  does - no perk limit. One free slot and the loop reaches it and clears
--  correctly. Adding the missing `else NextPerkWidget = nil` sends slot 12
--  down stock's OWN "no next widget" branch - the branch stock already uses
--  when you remove the perk that is sitting in slot 12 - so nothing new is
--  invented here.
--
--  🛑 WHY WE PATCH ONE FUNCTION INSTEAD OF SHIPPING hudperkszombie.lua.
--  A ui_mp/ override is a WHOLE-FILE replacement, and there is no
--  stock-faithful source for that file:
--    - the stock copy is T6-modified Lua BYTECODE and no decompiler reads it
--      (unluac fails on four measured deviations - see unluac\);
--    - BO2-Reimagined's readable copy is stock PLUS their changes, and their
--      Update() DROPS stock's STATE_PAUSED / STATE_TBD branches. Stock's
--      bytecode string table proves those branches exist (STATE_PAUSED,
--      PausedAlpha and STATE_TBD are all constants of Update), and they are
--      REACHABLE here - perk fields are 2 bits wide wherever emp_grenade_zm is
--      included, e.g. stock zm_transit.gsc:1926. Shipping Reimagined's file
--      would silently stop EMP-paused perks dimming. That is a regression, and
--      reconstructing those branches from constant order would be a guess.
--  Replacing only RemovePerkIcon leaves every branch we cannot read untouched.
--
--  The body below is stock's, character for character, plus the one `else`.
--  Verified stock-identical, not assumed: the order of stock's own constants
--  for this function - perkId, perkIcon, setAlpha, perkGlowIcon, close,
--  meterContainer, setImage, GetMaterial, GetGlowMaterial - matches this
--  source's first-use order exactly.
--
--  WHY THE HOOK LIVES IN THE POWERUPS FILE. CoD.Perks.RemovePerkIcon is looked
--  up dynamically at call time (stock's Update does CoD.Perks.RemovePerkIcon(),
--  and it is never captured by registerEventHandler), so reassigning the field
--  is enough. Stock hud.lua creates PerksArea and PowerUpsArea on ADJACENT
--  lines, PerksArea first - so by the time this file's PowerUpsArea runs,
--  hudperkszombie.lua is fully loaded and CoD.Perks is complete. This file is
--  already a zm_qol override and is confirmed to load from mod.iwd:
--  "Loaded menu file: ui_mp/t6/zombie/hudpowerupszombie.lua" appears in the
--  boot log while the file exists in NO other search path.
-- ===========================================================================

CoD.PowerUps.ZmqolFixedRemovePerkIcon = function (Menu, OwnedPerkIndex)
	local PerkWidget, NextPerkWidget = nil, nil
	for PerkIndex = OwnedPerkIndex, #CoD.Perks.ClientFieldNames, 1 do
		PerkWidget = Menu.perks[PerkIndex]
		if not PerkWidget.perkId then
			break
		elseif PerkIndex ~= #CoD.Perks.ClientFieldNames then
			NextPerkWidget = Menu.perks[PerkIndex + 1]
		else
			NextPerkWidget = nil
		end
		if not NextPerkWidget then
			PerkWidget.perkIcon:setAlpha(0)
			if PerkWidget.perkGlowIcon then
				PerkWidget.perkGlowIcon:setAlpha(0)
			end
			PerkWidget.perkId = nil
			break
		elseif not NextPerkWidget.perkId then
			PerkWidget.perkIcon:setAlpha(0)
			if PerkWidget.perkGlowIcon then
				PerkWidget.perkGlowIcon:close()
				PerkWidget.perkGlowIcon = nil
			end
			if PerkWidget.meterContainer then
				PerkWidget.meterContainer:close()
				PerkWidget.meterContainer = nil
			end
			PerkWidget.perkId = nil
			break
		else
			PerkWidget.perkIcon:setImage(CoD.Perks.GetMaterial(Menu, NextPerkWidget.perkId))
			local GlowMaterial = CoD.Perks.GetGlowMaterial(Menu, NextPerkWidget.perkId)
			if GlowMaterial and PerkWidget.perkGlowIcon then
				PerkWidget.perkGlowIcon:setImage(GlowMaterial)
			end
		end
		PerkWidget.perkId = NextPerkWidget.perkId
	end
end

--  Deliberately stateless: it compares the live field against our function
--  rather than setting an "installed" flag. Both LUI files are loaded twice
--  (once for the lobby, once for the game) and each load re-runs
--  `CoD.Perks = {}` / `CoD.PowerUps = {}`, so a flag on either table could go
--  out of step with the thing it describes. An identity test cannot. It also
--  keeps us from adding a key to CoD.Perks, which is not our table.
CoD.PowerUps.ZmqolInstallPerkRowFix = function ()
	if CoD.Perks == nil or CoD.Perks.RemovePerkIcon == nil then
		return
	end
	if CoD.Perks.RemovePerkIcon == CoD.PowerUps.ZmqolFixedRemovePerkIcon then
		return
	end
	CoD.Perks.RemovePerkIcon = CoD.PowerUps.ZmqolFixedRemovePerkIcon
	--  Probe, so a failed test still tells us WHICH half failed: type
	--  "zmqol_lui_perkfix" in the console. 1 = the patch installed, so a
	--  surviving bug is not this file. pcall + guard because setting an
	--  unregistered dvar must never be able to take the HUD down with it.
	if Engine ~= nil and Engine.SetDvar ~= nil then
		pcall(Engine.SetDvar, "zmqol_lui_perkfix", 1)
	end
end

LUI.createMenu.PowerUpsArea = function (f1_arg0)
	CoD.PowerUps.ZmqolInstallPerkRowFix()
	local f1_local0 = CoD.Menu.NewSafeAreaFromState("PowerUpsArea", f1_arg0)
	f1_local0:setOwner(f1_arg0)
	f1_local0.scaleContainer = CoD.SplitscreenScaler.new(nil, CoD.Zombie.SplitscreenMultiplier)
	f1_local0.scaleContainer:setLeftRight(false, false, 0, 0)
	f1_local0.scaleContainer:setTopBottom(false, true, 0, 0)
	f1_local0:addElement(f1_local0.scaleContainer)
	local f1_local1 = CoD.PowerUps.IconSize * 0.5
	-- zm_qol v1.99.2: stock is IconSize + UpgradeIconSize + 10. The timer's own
	-- band is inserted between the icon and that 10-unit gap, so the widget grows
	-- by exactly ZmqolTimerHeight and every element keeps the spacing it had.
	local f1_local2 = CoD.PowerUps.IconSize + CoD.PowerUps.ZmqolTimerHeight + CoD.PowerUps.UpgradeIconSize + 10
	local Widget = nil
	f1_local0.powerUps = {}
	for f1_local4 = 1, #CoD.PowerUps.ClientFieldNames, 1 do
		Widget = LUI.UIElement.new()
		Widget:setLeftRight(false, false, -f1_local1, f1_local1)
		Widget:setTopBottom(false, true, -f1_local2, 0)
		Widget:registerEventHandler("transition_complete_off_fade_out", CoD.PowerUps.PowerUpIcon_UpdatePosition)
		
		local powerUpIcon = LUI.UIImage.new()
		powerUpIcon:setLeftRight(true, true, 0, 0)
		powerUpIcon:setTopBottom(false, true, -CoD.PowerUps.IconSize, 0)
		powerUpIcon:setAlpha(0)
		Widget:addElement(powerUpIcon)
		Widget.powerUpIcon = powerUpIcon
		
		local upgradePowerUpIcon = LUI.UIImage.new()
		upgradePowerUpIcon:setLeftRight(false, false, -CoD.PowerUps.UpgradeIconSize / 2, CoD.PowerUps.UpgradeIconSize / 2)
		upgradePowerUpIcon:setTopBottom(true, false, 0, CoD.PowerUps.UpgradeIconSize)
		upgradePowerUpIcon:setAlpha(0)
		Widget:addElement(upgradePowerUpIcon)
		Widget.upgradePowerUpIcon = upgradePowerUpIcon
		
		-- zm_qol v1.99.0: POWER-UP TIMER TEXT. One per icon, alpha 0 until the
		-- server reports seconds for that power-up.
		--
		-- v1.99.2: MOVED ABOVE THE ICON (user, 2026-08-16 - "move the timer right
		-- above the power up icon itself"). It used to be the forum mod's layout:
		-- right-aligned in the bottom 18 units, which is the same band the icon
		-- occupies, so the number sat ON the icon's lower-right corner.
		--
		-- Now it is its own band, bottom edge flush with the icon's top edge, and
		-- centred over the icon rather than right-aligned - the number is a label
		-- for the icon now, not an overlay on it.
		local zmqolTimerText = LUI.UIText.new()
		zmqolTimerText:setLeftRight(true, true, 0, 0)
		zmqolTimerText:setTopBottom(false, true, -(CoD.PowerUps.IconSize + CoD.PowerUps.ZmqolTimerHeight), -CoD.PowerUps.IconSize)
		zmqolTimerText:setAlignment(LUI.Alignment.Center)
		-- v1.99.52: WHITE (user, 2026-08-18). Was the forum mod's yellow-green
		-- 0.8/0.9/0. Nothing else reads or writes this colour - it is set once
		-- at construction and the tick handler only touches text and alpha.
		zmqolTimerText:setRGB(1, 1, 1)
		zmqolTimerText:setAlpha(0)
		Widget:addElement(zmqolTimerText)
		Widget.zmqolTimerText = zmqolTimerText

		Widget.powerupId = nil
		f1_local0.scaleContainer:addElement(Widget)
		f1_local0.powerUps[f1_local4] = Widget
		f1_local0:registerEventHandler(CoD.PowerUps.ClientFieldNames[f1_local4].clientFieldName, CoD.PowerUps.Update)
		f1_local0:registerEventHandler(CoD.PowerUps.ClientFieldNames[f1_local4].clientFieldName .. "_ug", CoD.PowerUps.UpgradeUpdate)
	end
	f1_local0.activePowerUpCount = 0
	f1_local0.deathmachinePowerupState = -1
	f1_local0:registerEventHandler("deathmachine_powerup_dvar_update", CoD.PowerUps.DeathMachineDvarUpdate)
	f1_local0:addElement(LUI.UITimer.new(100, "deathmachine_powerup_dvar_update", false, f1_local0))
	f1_local0:registerEventHandler("hud_update_refresh", CoD.PowerUps.UpdateVisibility)
	f1_local0:registerEventHandler("hud_update_bit_" .. CoD.BIT_HUD_VISIBLE, CoD.PowerUps.UpdateVisibility)
	f1_local0:registerEventHandler("hud_update_bit_" .. CoD.BIT_IS_PLAYER_IN_AFTERLIFE, CoD.PowerUps.UpdateVisibility)
	f1_local0:registerEventHandler("hud_update_bit_" .. CoD.BIT_EMP_ACTIVE, CoD.PowerUps.UpdateVisibility)
	f1_local0:registerEventHandler("hud_update_bit_" .. CoD.BIT_UI_ACTIVE, CoD.PowerUps.UpdateVisibility)
	f1_local0:registerEventHandler("hud_update_bit_" .. CoD.BIT_SPECTATING_CLIENT, CoD.PowerUps.UpdateVisibility)
	f1_local0:registerEventHandler("hud_update_bit_" .. CoD.BIT_SCOREBOARD_OPEN, CoD.PowerUps.UpdateVisibility)
	f1_local0:registerEventHandler("hud_update_bit_" .. CoD.BIT_IN_VEHICLE, CoD.PowerUps.UpdateVisibility)
	f1_local0:registerEventHandler("hud_update_bit_" .. CoD.BIT_IN_GUIDED_MISSILE, CoD.PowerUps.UpdateVisibility)
	f1_local0:registerEventHandler("hud_update_bit_" .. CoD.BIT_IN_REMOTE_KILLSTREAK_STATIC, CoD.PowerUps.UpdateVisibility)
	f1_local0:registerEventHandler("hud_update_bit_" .. CoD.BIT_IS_SCOPED, CoD.PowerUps.UpdateVisibility)
	f1_local0:registerEventHandler("hud_update_bit_" .. CoD.BIT_IS_FLASH_BANGED, CoD.PowerUps.UpdateVisibility)
	f1_local0:registerEventHandler("hud_update_bit_" .. CoD.BIT_DEMO_CAMERA_MODE_MOVIECAM, CoD.PowerUps.UpdateVisibility)
	f1_local0:registerEventHandler("hud_update_bit_" .. CoD.BIT_DEMO_ALL_GAME_HUD_HIDDEN, CoD.PowerUps.UpdateVisibility)
	f1_local0:registerEventHandler("powerups_update_position", CoD.PowerUps.UpdatePosition)

	-- =======================================================================
	--  zm_qol v1.99.0: POWER-UP TIMERS, the client half.
	--
	--  Reads the `powerup_times` dvar the server writes (see
	--  zmqol_powerup_timer_think in quality_of_life.gsc) and paints the
	--  seconds under whichever icon is showing that power-up.
	--
	--  Format is `name:secs,name:secs,` - the forum mod's, kept as-is.
	--
	--  🛑 THE SERVER SENDS WHOLE SECONDS AND ONLY WHEN THEY CHANGE. That is not
	--  a detail: the forum version wrote the dvar on every one of stock's
	--  20 Hz ticks per power-up per player, which is ~120 reliable commands a
	--  second against a 128-entry ring. Do NOT "improve" this by asking for
	--  fractional time.
	--
	--  📝 NOT HARDCODED TO A POWER-UP LIST. It matches on Widget.powerUpId,
	--  which stock sets to the clientFieldName of whatever is in that slot - so
	--  the Death Machine (deathmachine_powerup) and anything added later are
	--  covered with no extra work.
	--
	--  🛑 v1.99.1 - THE CAPITAL U IS THE WHOLE BUG. v1.99.0 read `w.powerupId`.
	--  Lua is case-sensitive, and although stock DOES write a lowercase
	--  `Widget.powerupId = nil` once at construction (line ~515), that field is
	--  dead - nothing ever assigns it again. The live one is `powerUpId`, set in
	--  CoD.PowerUps.UpdateState and read by GetExistingPowerUpIndex and
	--  UpdatePosition. Proof it is the live one: the icons position themselves
	--  correctly in game, and UpdatePosition keys entirely off powerUpId.
	--  So `t` was ALWAYS nil, the alpha was ALWAYS 0, and no timer could ever
	--  draw regardless of what the server sent.
	--
	--  Re-patching AmmoAreaZombie here as well: on Origins that table may not
	--  exist yet when PatchAmmoCounters() runs at file scope, and this handler
	--  is idempotent (the deathmachinePatch flag), so it self-heals in 100 ms.
	-- =======================================================================
	f1_local0:registerEventHandler("zmqol_powerup_timer_tick", function (self)
		if CoD.AmmoAreaZombie ~= nil and CoD.AmmoAreaZombie.deathmachinePatch ~= true then
			CoD.PowerUps.PatchZombieAmmoArea()
		end

		local times = {}
		local str = UIExpression.DvarString(nil, "powerup_times")

		if str ~= nil and str ~= "" then
			for pair in string.gmatch(str, "([^,]+)") do
				local name, secs = string.match(pair, "([^:]+):([^:]+)")
				if name ~= nil and secs ~= nil then
					local n = tonumber(secs)
					if n ~= nil then
						times[name] = n
					end
				end
			end
		end

		for i = 1, #self.powerUps do
			local w = self.powerUps[i]

			if w.zmqolTimerText ~= nil then
				local t = nil
				if w.powerUpId ~= nil then
					t = times[w.powerUpId]
				end

				if t ~= nil and t > 0 then
					w.zmqolTimerText:setText(tostring(math.ceil(t)))
					w.zmqolTimerText:setAlpha(1)
				else
					w.zmqolTimerText:setAlpha(0)
				end
			end
		end

		return true
	end)
	f1_local0:addElement(LUI.UITimer.new(100, "zmqol_powerup_timer_tick", false, f1_local0))

	f1_local0.visible = true
	return f1_local0
end


CoD.PowerUps.DeathMachineDvarUpdate = function (Menu, ClientInstance)
	local LocalClientIndex = nil
	if ClientInstance ~= nil then
		LocalClientIndex = ClientInstance.controller
	end
	if LocalClientIndex == nil then
		LocalClientIndex = Menu.m_ownerController
	end
	if LocalClientIndex == nil then
		LocalClientIndex = 0
	end

	local PowerupState = UIExpression.DvarInt(LocalClientIndex, CoD.PowerUps.DeathMachineDvarName)
	if PowerupState == nil then
		PowerupState = CoD.PowerUps.STATE_OFF
	end

	CoD.PowerUps.PatchAmmoCounters()

	local HideAmmoCounter = PowerupState ~= CoD.PowerUps.STATE_OFF
	CoD.PowerUps.DeathMachineAmmoCounterHidden[LocalClientIndex] = HideAmmoCounter

	if HideAmmoCounter ~= Menu.deathmachineAmmoCounterHidden and Menu.dispatchEventToRoot ~= nil then
		Menu.deathmachineAmmoCounterHidden = HideAmmoCounter
		Menu:dispatchEventToRoot({
			name = "hud_update_refresh",
			controller = LocalClientIndex
		})
	end

	if PowerupState ~= Menu.deathmachinePowerupState then
		Menu.deathmachinePowerupState = PowerupState
		Menu:processEvent({
			name = "deathmachine_powerup",
			controller = LocalClientIndex,
			newValue = PowerupState
		})
	end
end

CoD.PowerUps.UpdateVisibility = function (f2_arg0, f2_arg1)
	local f2_local0 = f2_arg1.controller
	if UIExpression.IsVisibilityBitSet(f2_local0, CoD.BIT_HUD_VISIBLE) == 1 and UIExpression.IsVisibilityBitSet(f2_local0, CoD.BIT_IS_PLAYER_IN_AFTERLIFE) == 0 and UIExpression.IsVisibilityBitSet(f2_local0, CoD.BIT_EMP_ACTIVE) == 0 and UIExpression.IsVisibilityBitSet(f2_local0, CoD.BIT_DEMO_CAMERA_MODE_MOVIECAM) == 0 and UIExpression.IsVisibilityBitSet(f2_local0, CoD.BIT_DEMO_ALL_GAME_HUD_HIDDEN) == 0 and UIExpression.IsVisibilityBitSet(f2_local0, CoD.BIT_UI_ACTIVE) == 0 and UIExpression.IsVisibilityBitSet(f2_local0, CoD.BIT_IN_KILLCAM) == 0 and UIExpression.IsVisibilityBitSet(f2_local0, CoD.BIT_SCOREBOARD_OPEN) == 0 and (not CoD.IsShoutcaster(f2_local0) or CoD.ExeProfileVarBool(f2_local0, "shoutcaster_teamscore")) and UIExpression.IsVisibilityBitSet(f2_local0, CoD.BIT_IN_GUIDED_MISSILE) == 0 and UIExpression.IsVisibilityBitSet(f2_local0, CoD.BIT_IN_REMOTE_KILLSTREAK_STATIC) == 0 and UIExpression.IsVisibilityBitSet(f2_local0, CoD.BIT_IS_SCOPED) == 0 and UIExpression.IsVisibilityBitSet(f2_local0, CoD.BIT_IN_VEHICLE) == 0 and UIExpression.IsVisibilityBitSet(f2_local0, CoD.BIT_IS_FLASH_BANGED) == 0 then
		if not f2_arg0.visible then
			f2_arg0:setAlpha(1)
			f2_arg0.visible = true
		end
	elseif f2_arg0.visible then
		f2_arg0:setAlpha(0)
		f2_arg0.visible = nil
	end
end

CoD.PowerUps.Update = function (f3_arg0, f3_arg1)
	CoD.PowerUps.UpdateState(f3_arg0, f3_arg1)
	CoD.PowerUps.UpdatePosition(f3_arg0, f3_arg1)
end

CoD.PowerUps.UpdateState = function (f4_arg0, f4_arg1)
	local f4_local0 = nil
	local f4_local1 = CoD.PowerUps.GetExistingPowerUpIndex(f4_arg0, f4_arg1.name)
	if f4_local1 ~= nil then
		f4_local0 = f4_arg0.powerUps[f4_local1]
		if f4_arg1.newValue == CoD.PowerUps.STATE_ON then
			f4_local0.powerUpId = f4_arg1.name
			f4_local0.powerUpIcon:setImage(CoD.PowerUps.GetMaterial(f4_arg0, f4_arg1.controller, f4_arg1.name))
			f4_local0.powerUpIcon:setAlpha(1)
		elseif f4_arg1.newValue == CoD.PowerUps.STATE_OFF then
			f4_local0.powerUpIcon:beginAnimation("off_fade_out", CoD.PowerUps.FLASHING_STAGE_DURATION)
			f4_local0.powerUpIcon:setAlpha(0)
			f4_local0.upgradePowerUpIcon:beginAnimation("off_fade_out", CoD.PowerUps.FLASHING_STAGE_DURATION)
			f4_local0.upgradePowerUpIcon:setAlpha(0)
			f4_local0.powerUpId = nil
			f4_arg0.activePowerUpCount = f4_arg0.activePowerUpCount - 1
		elseif f4_arg1.newValue == CoD.PowerUps.STATE_FLASHING_OFF then
			f4_local0.powerUpIcon:beginAnimation("fade_out", CoD.PowerUps.FLASHING_STAGE_DURATION)
			f4_local0.powerUpIcon:setAlpha(0)
		elseif f4_arg1.newValue == CoD.PowerUps.STATE_FLASHING_ON then
			f4_local0.powerUpIcon:beginAnimation("fade_in", CoD.PowerUps.FLASHING_STAGE_DURATION)
			f4_local0.powerUpIcon:setAlpha(1)
		end
	elseif f4_arg1.newValue == CoD.PowerUps.STATE_ON or f4_arg1.newValue == CoD.PowerUps.STATE_FLASHING_ON then
		local f4_local2 = CoD.PowerUps.GetFirstAvailablePowerUpIndex(f4_arg0)
		if f4_local2 ~= nil then
			f4_local0 = f4_arg0.powerUps[f4_local2]
			f4_local0.powerUpId = f4_arg1.name
			f4_local0.powerUpIcon:setImage(CoD.PowerUps.GetMaterial(f4_arg0, f4_arg1.controller, f4_arg1.name))
			f4_local0.powerUpIcon:setAlpha(1)
			f4_arg0.activePowerUpCount = f4_arg0.activePowerUpCount + 1
		end
	end
end

CoD.PowerUps.UpgradeUpdate = function (f5_arg0, f5_arg1)
	CoD.PowerUps.UpgradeUpdateState(f5_arg0, f5_arg1)
end

CoD.PowerUps.UpgradeUpdateState = function (f6_arg0, f6_arg1)
	local f6_local0 = nil
	local f6_local1 = CoD.PowerUps.GetExistingPowerUpIndex(f6_arg0, string.sub(f6_arg1.name, 0, -4))
	if f6_local1 ~= nil then
		f6_local0 = f6_arg0.powerUps[f6_local1].upgradePowerUpIcon
		if f6_arg1.newValue == CoD.PowerUps.STATE_ON then
			f6_local0:setImage(CoD.PowerUps.GetUpgradeMaterial(f6_arg0, f6_arg1.name))
			f6_local0:setAlpha(1)
			CoD.PowerUps.SetUpgradeColor(f6_local0, f6_arg1.name)
		elseif f6_arg1.newValue == CoD.PowerUps.STATE_OFF then
			f6_local0:beginAnimation("off_fade_out", CoD.PowerUps.FLASHING_STAGE_DURATION)
			f6_local0:setAlpha(0)
		elseif f6_arg1.newValue == CoD.PowerUps.STATE_FLASHING_OFF then
			f6_local0:beginAnimation("fade_out", CoD.PowerUps.FLASHING_STAGE_DURATION)
			f6_local0:setAlpha(0)
		elseif f6_arg1.newValue == CoD.PowerUps.STATE_FLASHING_ON then
			f6_local0:beginAnimation("fade_in", CoD.PowerUps.FLASHING_STAGE_DURATION)
			f6_local0:setAlpha(1)
		end
	end
end

CoD.PowerUps.GetMaterial = function (f7_arg0, f7_arg1, f7_arg2)
	local f7_local0 = nil
	for f7_local1 = 1, #CoD.PowerUps.ClientFieldNames, 1 do
		if CoD.PowerUps.ClientFieldNames[f7_local1].clientFieldName == f7_arg2 then
			f7_local0 = CoD.PowerUps.ClientFieldNames[f7_local1].material
			if UIExpression.IsVisibilityBitSet(f7_arg1, CoD.BIT_IS_PLAYER_ZOMBIE) == 1 and CoD.PowerUps.ClientFieldNames[f7_local1].z_material then
				f7_local0 = CoD.PowerUps.ClientFieldNames[f7_local1].z_material
				break
			end
		end
	end
	return f7_local0
end

CoD.PowerUps.GetUpgradeMaterial = function (f8_arg0, f8_arg1)
	local f8_local0 = nil
	for f8_local1 = 1, #CoD.PowerUps.UpgradeClientFieldNames, 1 do
		if CoD.PowerUps.UpgradeClientFieldNames[f8_local1].clientFieldName == f8_arg1 then
			f8_local0 = CoD.PowerUps.UpgradeClientFieldNames[f8_local1].material
			break
		end
	end
	return f8_local0
end

CoD.PowerUps.SetUpgradeColor = function (f9_arg0, f9_arg1)
	local f9_local0 = nil
	for f9_local1 = 1, #CoD.PowerUps.UpgradeClientFieldNames, 1 do
		if CoD.PowerUps.UpgradeClientFieldNames[f9_local1].clientFieldName == f9_arg1 then
			if CoD.PowerUps.UpgradeClientFieldNames[f9_local1].color then
				f9_arg0:setRGB(CoD.PowerUps.UpgradeClientFieldNames[f9_local1].color.r, CoD.PowerUps.UpgradeClientFieldNames[f9_local1].color.g, CoD.PowerUps.UpgradeClientFieldNames[f9_local1].color.b)
				break
			end
		end
	end
end

CoD.PowerUps.GetExistingPowerUpIndex = function (f10_arg0, f10_arg1)
	for f10_local0 = 1, #CoD.PowerUps.ClientFieldNames, 1 do
		if f10_arg0.powerUps[f10_local0].powerUpId == f10_arg1 then
			return f10_local0
		end
	end
	return nil
end

CoD.PowerUps.GetFirstAvailablePowerUpIndex = function (f11_arg0)
	for f11_local0 = 1, #CoD.PowerUps.ClientFieldNames, 1 do
		if not f11_arg0.powerUps[f11_local0].powerUpId then
			return f11_local0
		end
	end
	return nil
end

CoD.PowerUps.PowerUpIcon_UpdatePosition = function (f12_arg0, f12_arg1)
	if f12_arg1.interrupted ~= true then
		f12_arg0:dispatchEventToParent({
			name = "powerups_update_position"
		})
	end
end

CoD.PowerUps.UpdatePosition = function (f13_arg0, f13_arg1)
	local f13_local0 = nil
	local f13_local1 = 0
	local f13_local2 = 0
	local f13_local3 = nil
	for f13_local4 = 1, #CoD.PowerUps.ClientFieldNames, 1 do
		f13_local0 = f13_arg0.powerUps[f13_local4]
		if f13_local0.powerUpId ~= nil then
			if not f13_local3 then
				f13_local1 = -(CoD.PowerUps.IconSize * 0.5 * f13_arg0.activePowerUpCount + CoD.PowerUps.Spacing * 0.5 * (f13_arg0.activePowerUpCount - 1))
			else
				f13_local1 = f13_local3 + CoD.PowerUps.IconSize + CoD.PowerUps.Spacing
			end
			f13_local2 = f13_local1 + CoD.PowerUps.IconSize
			f13_local0:beginAnimation("move", CoD.PowerUps.MOVING_DURATION)
			f13_local0:setLeftRight(false, false, f13_local1, f13_local2)
			f13_local3 = f13_local1
		end
	end
end

