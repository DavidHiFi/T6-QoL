-- Eight-row layout adapted from SickoHours' points HUD. Defaults to stock BO2 faction emblems.
-- Install during HUD construction, after the stock competitive scoreboard has loaded.
CoD.QolEightPlayerPoints = CoD.QolEightPlayerPoints or {}
local Q = CoD.QolEightPlayerPoints
-- Optional build-supplied material names, keyed by the server's character portrait ID.
Q.Portraits = Q.Portraits or {}
pcall(require, "T6.QolCharacterPack")
for slot, character in pairs(CoD.QolCharacterPack or {}) do
	if character.portrait then Q.Portraits[slot] = character.portrait end
end
local avatars = {
	[0] = "faction_cdc", [1] = "faction_cia", [2] = "faction_tranzit",
	[3] = "faction_highrise", [4] = "faction_prison", [5] = "faction_buried", [6] = "faction_tomb"
}

local function addRows(menu)
	local block = CoD.SplitscreenScaler.new(nil, CoD.Zombie.SplitscreenMultiplier)
	block:setLeftRight(false, true, 0, 0)
	block:setTopBottom(false, true, 0, 0)
	block:setAlpha(0)
	menu:addElement(block)
	block.rows = {}
	local bottom = CoD.CompetitiveScoreboard.Bottom - CoD.CompetitiveScoreboard.RowHeight
	local right = -CoD.CompetitiveScoreboard.LeftOffset
	for slot = 1, 8 do
		local height = slot == 1 and 32 or 22
		local rowBottom = bottom - (slot == 1 and 0 or 37 + (slot - 2) * 27)
		local row = LUI.UIElement.new()
		row:setLeftRight(false, true, right - 296, right)
		row:setTopBottom(false, true, rowBottom - height, rowBottom)
		row:setAlpha(0)
		block:addElement(row)
		row.portrait = LUI.UIImage.new()
		row.portrait:setLeftRight(true, false, 138, 138 + height)
		row.portrait:setTopBottom(true, true, 0, 0)
		row.portrait:setAlpha(0)
		row:addElement(row.portrait)
		row.number = LUI.UIText.new()
		row.number:setLeftRight(true, true, 138 + height + 7, 0)
		row.number:setTopBottom(true, true, 0, 0)
		row.number:setFont(CoD.fonts.Default)
		row.number:setAlignment(LUI.Alignment.Left)
		row:addElement(row.number)
		row.playerName = LUI.UIText.new()
		row.playerName:setLeftRight(true, false, 0, 131)
		local nameHeight = slot == 1 and 14 or 12
		row.playerName:setTopBottom(false, false, -nameHeight / 2, nameHeight / 2)
		row.playerName:setFont(CoD.fonts.Default)
		row.playerName:setAlignment(LUI.Alignment.Right)
		row:addElement(row.playerName)
		block.rows[slot] = row
	end
	return block
end

local function draw(menu, event)
	local block = menu.qolPoints
	local scores = event and event.competitivescores
	if not block or not scores then return end
	local own = event.selfindex
	local order = {}
	if own and scores[own] then order[1] = own end
	for index = 1, #scores do
		if index ~= own then order[#order + 1] = index end
	end
	for slot, row in ipairs(block.rows) do
		local index = order[slot]
		local entry = index and scores[index]
		row:setAlpha(entry and 1 or 0)
		row.portrait:setAlpha(0)
		if entry then
			row.number:setText(tostring(entry.score))
			local player = Engine.GetCalloutPlayerData(nil, entry.clientNum)
			row.playerName:setText(player and player.playerName or "")
			local color = CoD.Zombie.PlayerColors[index] or CoD.Zombie.PlayerColors[(index - 1) % 4 + 1]
			if color then
				row.number:setRGB(color.r, color.g, color.b)
				row.playerName:setRGB(color.r, color.g, color.b)
			end
			local crew = menu.qolCrew[entry.clientNum]
			local avatar = crew and (Q.Portraits[crew.character] or avatars[crew.faction])
			if avatar then
				row.portrait:setImage(RegisterMaterial(avatar))
				row.portrait:setAlpha(1)
			end
		end
	end
end

Q.Attach = function (menu)
	menu.qolCrew = {}
	local stockUpdate = menu.m_eventHandlers.hud_update_competitive_scoreboard
	menu:registerEventHandler("hud_update_competitive_scoreboard", function (self, event)
		self.qolLastScores = event
		if #event.competitivescores <= 4 then
			if self.qolExtended then
				self.qolPoints:setAlpha(0)
				self.scaleContainer:setAlpha(1)
				self.qolExtended = false
			end
			return stockUpdate(self, event)
		end
		if not self.qolPoints then self.qolPoints = addRows(self) end
		self.qolExtended = true
		self.scaleContainer:setAlpha(0)
		self.qolPoints:setAlpha(1)
		draw(self, event)
	end)
	menu:registerEventHandler("qol_points_roster", function (self)
		self.qolCrew = {}
		if self.qolPoints then draw(self, self.qolLastScores) end
	end)
	menu:registerEventHandler("qol_points_crew", function (self, event)
		self.qolCrew[event.data[1]] = {faction=event.data[2], character=event.data[3]}
		if self.qolPoints then draw(self, self.qolLastScores) end
	end)
end

Q.Install = function ()
	if Q.installed then return end
	Q.installed = true
	local stock = LUI.createMenu.CompetitiveScoreboard
	LUI.createMenu.CompetitiveScoreboard = function (controller)
		local menu = stock(controller)
		Q.Attach(menu)
		return menu
	end
end
