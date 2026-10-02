CoD.QolRoundSummary = {}

local function TimeText(seconds)
    return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

CoD.QolRoundSummary.Lines = function (payload)
    local values = {}
    for token in string.gmatch(payload or "", "%S+") do
        local number = tonumber(token)
        if number == nil then return nil end
        values[#values + 1] = number
    end
    if #values ~= 10 or values[1] < 1 or values[10] < 3 or values[10] > 30 then
        return nil
    end
    local best = "Not Set"
    if values[4] > 0 then best = TimeText(values[4]) end
    local status = "^7No New Personal Best"
    if values[6] == 1 and values[7] == 1 then
        status = "^2New Personal Best Time and New Personal Best Eliminations"
    elseif values[6] == 1 then
        status = "^2New Personal Best Time"
    elseif values[7] == 1 then
        status = "^2New Personal Best Eliminations"
    end
    return {
        "^5ROUND " .. values[1] .. " COMPLETE",
        "^7Eliminations: ^5" .. values[3] .. " ^7| Round Time: ^5" .. TimeText(values[2]),
        "^7Personal Best Time: ^3" .. best .. " ^7| Personal Best Eliminations: ^3" .. values[5],
        "^7Status: " .. status
    }, values[8], values[9]
end

CoD.QolRoundSummary.Attach = function (menu, controller)
    local card = LUI.UIElement.new()
    card:setLeftRight(false, false, 0, 0)
    card:setTopBottom(false, false, 0, 0)
    card:setAlpha(0)
    local rows = {}
    local heights = {30, 25, 22, 22}
    local offsets = {-58, -30, -4, 22}
    for index = 1, 4 do
        local row = LUI.UIText.new()
        row:setLeftRight(false, false, -450, 450)
        row:setTopBottom(false, false, offsets[index], offsets[index] + heights[index])
        row:setAlignment(LUI.Alignment.Center)
        row:setFont(CoD.fonts.Default)
        card:addElement(row)
        rows[index] = row
    end
    menu:addElement(card)
    card:registerEventHandler("zmqol_summary_tick", function (self)
        local payload = UIExpression.DvarString(controller, "zmqol_round_summary") or ""
        if payload ~= self.lastPayload then
            self.lastPayload = payload
            local lines, x, y = CoD.QolRoundSummary.Lines(payload)
            self:beginAnimation("summary_fade", lines and 180 or 280)
            self:setAlpha(lines and 0.95 or 0)
            if lines then
                self:setLeftRight(false, false, x, x)
                self:setTopBottom(false, false, y, y)
                for index = 1, 4 do rows[index]:setText(lines[index]) end
            end
        end
        return true
    end)
    card:addElement(LUI.UITimer.new(100, "zmqol_summary_tick", false, card))
end
