#!/usr/bin/env python3
"""Exercise personal Options callbacks and spawn sync with a stub Lua engine.

Needs Lua 5.1 or newer on PATH. Exit 0 pass, 1 failed assertion, 2 missing tool.
This checks Lua behavior, not Plutonium networking or server execution.
"""
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def function(source, name):
    start = source.index('CoD.OptionsSettings.' + name + ' = function ')
    end = source.index('\nend', start) + len('\nend')
    return source[start:end]


def main():
    lua = shutil.which('lua')
    if not lua:
        print('Lua is missing; install Lua and rerun tools/check-personal-menu.py', file=sys.stderr)
        return 2
    source = (ROOT / 'ui/t6/menus/optionssettings.lua').read_text()
    factories = '\n'.join(function(source, name) for name in ('QolToggle', 'QolChoice'))
    module = (ROOT / 'ui_mp/t6/zombie/qolpersonaloptions.lua').read_text()
    harness = r'''
local values, sent, archives = {}, {}, {}
local inGame, host = 1, false
CoD = {isHost = function () return host end, OptionsSettings = {}}
UIExpression = {
    IsInGame = function () return inGame end,
    DvarString = function (controller, name) return values[name] end
}
Engine = {
    Localize = function (text) return text end,
    SetDvar = function (name, value) values[name] = tostring(value) end,
    SendMenuResponse = function (controller, menu, response)
        assert(menu == 'luisystem')
        sent[#sent + 1] = {controller, response}
    end
}
CoD.OptionsSettings.QolArchive = function (name) archives[#archives + 1] = name end
LUI = {UITimer = {new = function (ms, event, once, target)
    assert(ms == 100 and event == 'zmqol_personal_sync' and once == false)
    return {}
end}}
local list = {addDvarLeftRightSelector = function (self, controller, label, name)
    local selector = {m_dvarName = name, choices = {}}
    selector.addChoice = function (self, controller, label, value, extra, callback)
        self.choices[#self.choices + 1] = {value = value, callback = callback}
        if callback then callback({value = value}, nil) end
    end
    return selector
end}
'''
    checks = r'''
local Options = CoD.QolPersonalOptions
local total = 0
for name, spec in pairs(Options.Personal) do
    total = total + 1
    local choice = Options.Choice(2, name)
    choice({value = spec[1]}, false)
    assert(#sent == 0, 'building a selector sent ' .. name)
end
assert(total == 26)
assert(values.fog_enabled == "1" and values.hud_color == "1 1 1", "unset remote rows must display their shipped defaults")
for name, spec in pairs(Options.Personal) do
    local before = #sent
    Options.Choice(2, name)({value = spec[1]}, true)
    assert(#sent == before + 1)
    assert(sent[#sent][1] == 2)
    assert(sent[#sent][2] == 'zmqol_popt ' .. name .. ' ' .. tostring(spec[1]))
end
assert(Options.Choice(0, 'sv_cheats') == nil)
assert(CoD.OptionsSettings.QolToggle(list, 2, 'GOD', 'godmode', '') == nil)
assert(CoD.OptionsSettings.QolChoice(list, 2, 'RULE', 'remove_round_cap', '', {{'ON', 1}}) == nil)
assert(CoD.OptionsSettings.QolToggle(list, 2, 'LOCAL', 'cl_allowDownload', '') ~= nil)
local toggle = CoD.OptionsSettings.QolToggle(list, 2, 'FOG', 'fog_enabled', '')
local count = #sent
toggle.choices[1].callback({value = 0}, true)
assert(values.fog_enabled == '0' and #sent == count + 1)
local enum = CoD.OptionsSettings.QolChoice(list, 2, 'TIMERS', 'hud_timers', '', {{'OFF', 0}, {'ROUND', 3}})
enum.choices[2].callback({value = 3}, true)
assert(values.hud_timers == '3' and sent[#sent][2] == 'zmqol_popt hud_timers 3')
-- A retained selector never sends from the frontend. Hosting still uses the same transport.
inGame = 0
Options.Send(2, 'fog_enabled', 0)
assert(#sent == count + 2)
inGame, host = 1, true
assert(CoD.OptionsSettings.QolToggle(list, 0, 'RULE', 'remove_round_cap', '') ~= nil)
Options.Send(0, 'fog_enabled', 1)
assert(sent[#sent][1] == 0 and sent[#sent][2] == 'zmqol_popt fog_enabled 1')
host = false
local tick
local menu = {
    registerEventHandler = function (self, event, callback) tick = callback end,
    addElement = function () end
}
Options.Attach(menu, 2)
count = #sent
tick()
assert(#sent == count, 'no spawn token must mean no sync')
values.zmqol_popt_sync = 'spawn_1'
for index = 1, 26 do
    local before = #sent
    tick()
    assert(#sent == before + 1, 'one value per tick')
end
for index = 1, 30 do tick() end
assert(#sent == count + 26, 'one sync per token')
local synced = {}
for index = count + 1, #sent do
    local name = string.match(sent[index][2], '^zmqol_popt ([%w_]+) ')
    assert(not synced[name], 'duplicate name')
    synced[name] = true
end
for name in pairs(Options.Personal) do assert(synced[name], 'missing ' .. name) end
values.zmqol_popt_sync = 'spawn_2'
for index = 1, 26 do tick() end
assert(#sent == count + 52, 'respawn sync')
host = true
values.zmqol_popt_sync = 'spawn_3'
tick()
assert(#sent == count + 52, 'host spawn must preserve solo preferences')
print('PASS: 26 personal callbacks, host/frontend gates, hidden shared rows, saved spawn and respawn sync')
'''
    proc = subprocess.run([lua, '-'], input=harness + module + factories + checks,
                          text=True, cwd=ROOT, capture_output=True)
    print(proc.stdout, end='')
    print(proc.stderr, end='', file=sys.stderr)
    return proc.returncode


if __name__ == '__main__':
    sys.exit(main())
