$ErrorActionPreference = 'Stop'

$optionsPath = Join-Path $PSScriptRoot '..\ui\t6\menus\optionssettings.lua'
$lobbyPath = Join-Path $PSScriptRoot '..\ui_mp\t6\menus\privategamelobby_project.lua'
$options = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $optionsPath))
$lobby = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $lobbyPath))

$magic = $options.IndexOf('local MagicSelector')
$cheats = $options.IndexOf('local CheatsSelector')
if ($magic -lt 0 -or $cheats -le $magic) {
    Write-Error 'GAME 3 must contain CHEATS directly after MAGIC.'
}
if (-not $options.Contains('"sv_cheats"')) {
    Write-Error 'The GAME 3 CHEATS selector must control sv_cheats.'
}
if (-not $lobby.Contains('CoD.PrivateGameLobby.Dvars[1].gameTypes = {}')) {
    Write-Error 'The old pre-game CHEATS row must stay hidden while zm_qol is loaded.'
}

Write-Output '    [ok] MAGIC and CHEATS remain in GAME 3 and out of the mod lobby'

$pageStart = $options.IndexOf('CoD.OptionsSettings.CreateQolPageMenu = function')
if ($pageStart -lt 0) {
    throw 'The shared HUD/CHEATS page builder is missing.'
}
$pageEnd = $options.IndexOf('LUI.createMenu.OptionsSettingsMenu = function', $pageStart)
if ($pageEnd -le $pageStart) {
    throw 'The shared HUD/CHEATS page builder is missing.'
}
$page = $options.Substring($pageStart, $pageEnd - $pageStart)
if ($page -notmatch 'while FirstButton and not FirstButton\.m_focusable do\s+FirstButton = FirstButton:getNextSibling\(\)\s+end\s+if FirstButton then\s+FirstButton:processEvent\(\{ name = "gain_focus", controller = LocalClientIndex \}\)') {
    throw 'HUD/CHEATS must skip non-focusable list children and focus a selectable row for the owning controller.'
}
foreach ($builder in @('CreateQolHudTab', 'CreateQolCheatsTab')) {
    if (-not $page.Contains("CoD.OptionsSettings.$builder, LocalClientIndex")) {
        throw "$builder must use the shared controller-focus page builder."
    }
}
if (-not $page.Contains('not PageMenu:restoreState()') -or
    -not $page.Contains('PageMenu:registerEventHandler("button_prompt_back", CoD.OptionsSettings.Back)')) {
    throw 'HUD/CHEATS must preserve saved focus and the stock Back handler.'
}
Write-Output '    [ok] HUD and CHEATS retain stock controller focus, saved state and Back handling'
