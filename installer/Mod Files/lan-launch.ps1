<#
================================================================================
  Quality Of Life Series - one-click game launcher

  Started life as a Black Ops II LAN launcher (2026-08-26). It now starts
  Black Ops II, Black Ops or World at War through Plutonium, either normally
  or in LAN mode, and can load the zm_qol mod automatically in LAN mode.

  Launched by "Play BO2 with mod (LAN).bat" and "Play BO2 with mod + ReShade
  (LAN).bat" (both sit in this same "Mod Files" folder), and by the app's own
  Play rows, which pass the game, mode and name.

  WHY LAN MODE FOR THE MOD: an asset mod (mod.ff/mod.iwd) can only be
  auto-loaded with the engine's fs_game mechanism, and Plutonium's
  bootstrapper refuses fs_game on a normal online launch (it has no login
  session of its own - that is a 401, not a bug in this script). LAN mode
  sidesteps the login entirely, so fs_game works and the mod is already
  running the moment Zombies loads. Online launches therefore start with no
  mod; pick Quality Of Life from Zombies -> Mods if you want it there.

  THE GAME PATH IS READ FROM PLUTONIUM'S OWN CONFIG, NOT HARDCODED.
  %LOCALAPPDATA%\Plutonium\config.json is a file Plutonium itself writes and
  maintains - every Plutonium install has one, and its t4Path/t5Path/t6Path
  keys are wherever THAT PC's games actually live.

  Closing the game window ends the session normally. If you started the
  ReShade watchdog alongside it (-Watchdog), closing THAT window just stops
  ReShade being restored - nothing is uninstalled either way.
================================================================================
#>

param(
    [string] $PlutoRoot = (Join-Path $env:LOCALAPPDATA 'Plutonium'),
    [string] $Mod       = 'zm_qol',
    # In-game name passed with +name. The app fills this from Settings ->
    # Player name; left generic here on purpose (no personal machine
    # specifics ship).
    [string] $LanName   = '',
    [ValidateSet('t4', 't5', 't6')] [string] $Game = 't6',
    [ValidateSet('zm', 'mp')] [string] $Play = 'zm',
    # -Online starts the game normally (no -lan, no fs_game). Without it the
    # launch is a LAN session, which is what the two .bat files do.
    [switch] $Online,
    # Also start the ReShade watchdog (reshade-watchdog.ps1, same folder) in
    # its own window alongside the game.
    [switch] $Watchdog
)

$ErrorActionPreference = 'Stop'
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Definition }

function Fail {
    param([string] $Message)
    Write-Host ''
    Write-Host "  $Message" -ForegroundColor Red
    Write-Host ''
    Read-Host 'Press Enter to close'
    exit 1
}

$Names = @{ t4 = 'World at War'; t5 = 'Black Ops'; t6 = 'Black Ops II' }
$Modes = @{ zm = 'Zombies'; mp = 'Multiplayer' }
$GameName = $Names[$Game]
$ModeName = $Modes[$Play]
$GameId   = "$Game$Play"

$BinDir = Join-Path $PlutoRoot 'bin'
$Boot   = Join-Path $BinDir 'plutonium-bootstrapper-win32.exe'
$Config = Join-Path $PlutoRoot 'config.json'

if (-not (Test-Path -LiteralPath $Boot)) {
    Fail "Plutonium isn't installed where expected ($Boot missing). Run Plutonium at least once first."
}
if (-not (Test-Path -LiteralPath $Config)) {
    Fail "Plutonium's config.json wasn't found ($Config). Open Plutonium and load $GameName at least once first, so it knows where the game is."
}

$GamePath = $null
$PathKey = "${Game}Path"
try {
    $cfg = Get-Content -LiteralPath $Config -Raw | ConvertFrom-Json
    $GamePath = [string] $cfg.$PathKey
} catch {
    Fail "Couldn't read config.json: $($_.Exception.Message)"
}
if (-not $GamePath -or -not (Test-Path -LiteralPath $GamePath)) {
    Fail "Plutonium's config.json doesn't list a valid $GameName folder. Open Plutonium and load $GameName at least once first."
}

# Already running? Don't fight a second instance over the same game slot.
$already = @('plutonium-bootstrapper-win32', $GameId, "${Game}sp") |
    ForEach-Object { Get-Process -Name $_ -ErrorAction SilentlyContinue } |
    Select-Object -First 1
if ($already) {
    Fail "$GameName already appears to be running. Close it first, then try again."
}

$InGameName = if ($LanName -and $LanName.Trim().Length -gt 0) { $LanName.Trim() } else { 'Player' }
$gameArgs = @($GameId, ('"' + $GamePath.TrimEnd('\') + '"'), '+name', ('"' + $InGameName + '"'))
if (-not $Online) {
    $gameArgs += '-lan'
    if ($Game -eq 't6') {
        $gameArgs += @('+set', 'fs_game', ('"mods/' + $Mod + '"'))
    }
}

Write-Host ''
if ($Online) {
    Write-Host "  Starting $GameName $ModeName through Plutonium as '$InGameName'..." -ForegroundColor Cyan
    if ($Game -eq 't6') {
        Write-Host '  Online session. Pick Quality Of Life in Zombies -> Mods if you want the mod loaded.' -ForegroundColor Yellow
    }
} else {
    Write-Host "  Starting $GameName $ModeName in LAN mode as '$InGameName'" -NoNewline -ForegroundColor Cyan
    if ($Game -eq 't6') { Write-Host " with '$Mod' loaded..." -ForegroundColor Cyan } else { Write-Host '...' -ForegroundColor Cyan }
    Write-Host '  Offline only this session - no online servers or stats.' -ForegroundColor Yellow
}
Write-Host ''

try {
    Start-Process -FilePath $Boot -ArgumentList $gameArgs -WorkingDirectory $PlutoRoot -ErrorAction Stop | Out-Null
} catch {
    Fail "Couldn't start the game: $($_.Exception.Message)"
}

if ($Watchdog) {
    $watchdogPS1 = Join-Path $ScriptDir 'reshade-watchdog.ps1'
    if (Test-Path -LiteralPath $watchdogPS1) {
        Start-Process -FilePath 'powershell.exe' `
            -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$watchdogPS1`"") `
            -WorkingDirectory $PlutoRoot -WindowStyle Normal | Out-Null
        Write-Host '  ReShade watchdog started in its own window - leave it open while you play.' -ForegroundColor Green
    } else {
        Write-Host '  reshade-watchdog.ps1 is missing from this folder - ReShade will not be restored.' -ForegroundColor Yellow
        Write-Host '  Reinstall from the full download, or run the installer''s ReShade option first.' -ForegroundColor Yellow
    }
}

Write-Host ''
Write-Host '  Game launching - this window can be closed.' -ForegroundColor Green
Write-Host ''
Start-Sleep -Seconds 3