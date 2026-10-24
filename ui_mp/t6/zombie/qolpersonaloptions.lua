-- Personal Options use the stock menu-response channel, never player chat.
CoD.QolPersonalOptions = {}
local Options = CoD.QolPersonalOptions
Options.Personal = {
    night_mode = {0, 1}, dof_quality = {0, 3}, voice_lines = {1, 1},
    fog_enabled = {1, 1}, knife_lunge = {1, 1}, hud_master = {1, 1},
    hud_all = {0, 1}, hud_health_bar = {1, 1}, hud_timers = {1, 3},
    hud_remaining = {1, 1}, hud_bleedout_bar = {1, 1}, hud_perk_popup = {1, 1},
    hud_powerup_timers = {1, 1}, hud_zone = {0, 1}, hud_compass = {0, 1},
    hud_subtitles = {0, 2}, crosshair = {1, 1}, hitmarkers = {1, 1},
    redhitmarkers = {1, 1}, third_person = {0, 1}, velocity = {0, 1},
    hud_color = {"1 1 1"}, hud_color_health = {"1 1 1"},
    hud_color_timer = {"1 1 1"}, hud_color_round_timer = {"0.7 0.7 0.7"},
    hud_color_zone = {"0.7 0.7 0.7"}
}
-- These engine rows already act entirely on the local client.
Options.Local = {
    cl_allowDownload = true, com_busyWait = true,
    cg_drawIdentifier = true, cg_flashScriptHashes = true
}
Options.Remote = function ()
    return UIExpression.IsInGame() == 1 and not (CoD.isHost and CoD.isHost())
end
Options.Seed = function (controller, name)
    if not Options.Remote() then return end
    local value = UIExpression.DvarString(controller, name)
    if value == nil or value == "" then
        Engine.SetDvar(name, Options.Personal[name][1])
    end
end
Options.Value = function (controller, name)
    local spec = Options.Personal[name]
    local value = UIExpression.DvarString(controller, name)
    if value == nil or value == "" then value = spec[1] end
    return tostring(value)
end
Options.Send = function (controller, name, value)
    if UIExpression.IsInGame() == 1 and Options.Personal[name] then
        Engine.SendMenuResponse(controller, "luisystem", "zmqol_popt " .. name .. " " .. tostring(value))
    end
end
Options.Choice = function (controller, name)
    if not Options.Personal[name] then return nil end
    Options.Seed(controller, name)
    return function (choice, userRequested)
        -- The stock selector invokes callbacks while constructing choices too.
        if userRequested ~= true then return end
        Engine.SetDvar(name, choice.value)
        CoD.OptionsSettings.QolArchive(name)
        Options.Send(controller, name, choice.value)
    end
end
Options.Attach = function (menu, controller)
    local names = {}
    for name in pairs(Options.Personal) do names[#names + 1] = name end
    table.sort(names)
    local token, nextName
    menu:registerEventHandler("zmqol_personal_sync", function ()
        if not Options.Remote() then return end
        local current = UIExpression.DvarString(controller, "zmqol_popt_sync")
        if current and current ~= "" and current ~= token then
            token, nextName = current, 1
        end
        if nextName and names[nextName] then
            local name = names[nextName]
            Options.Send(controller, name, Options.Value(controller, name))
            nextName = nextName + 1
        end
    end)
    -- The stock server queue drains one response per 50ms. Do not flood it.
    menu:addElement(LUI.UITimer.new(100, "zmqol_personal_sync", false, menu))
end
