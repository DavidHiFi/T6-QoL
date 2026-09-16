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
