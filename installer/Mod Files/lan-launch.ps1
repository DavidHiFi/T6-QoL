<#
================================================================================
  Quality of Life Series - one-click LAN launch for the Black Ops II entry
  (zm_qol, T6), mod already loaded

  Added 2026-08-26. Launched by "Play BO2 with mod (LAN).bat" or
  "Play BO2 with mod + ReShade (LAN).bat" - both sit in this same "Mod
  Files" folder (moved here 2026-09-05; "Windows Install.bat" stays one
  level up) - and by the installer's own LAUNCH menu option.

  WHY LAN MODE: an asset mod (mod.ff/mod.iwd) can only be auto-loaded with
  the engine's fs_game mechanism, and Plutonium's bootstrapper refuses
  fs_game on a normal online launch (it has no login session of its own -
  that is a 401, not a bug in this script). LAN mode sidesteps the login
  entirely, so fs_game works and the mod is already running the moment
  Zombies loads - no MODS menu, no manual pick.

  OFFLINE ONLY, ON PURPOSE: no online servers, no stats, this session only.
  Solo and custom games work exactly the same as any other launch. For an
  ONLINE game, start Plutonium normally instead and pick "Quality Of Life"
  from Zombies -> Mods.

  🌟 THE GAME PATH IS READ FROM PLUTONIUM'S OWN CONFIG, NOT HARDCODED.
  %LOCALAPPDATA%\Plutonium\config.json is a file Plutonium itself writes and
  maintains - every Plutonium install has one, and its "t6Path" key is
  wherever THAT PC's Black Ops II actually lives. Reading it here is what
  makes this work on any player's PC, not just the one it was written on.

  Closing the game window ends the session normally. If you started the
  ReShade watchdog alongside it (-Watchdog), closing THAT window just stops
  ReShade being restored - nothing is uninstalled either way.
================================================================================
#>

param(
    [string] $PlutoRoot = (Join-Path $env:LOCALAPPDATA 'Plutonium'),
    [string] $Mod       = 'zm_qol',
    # In-game name for this LAN session. Left generic on purpose - see
    # zm_qol - dev/CLAUDE.md's "no personal machine specifics ship" rule.
    [string] $LanName   = 'Player',
    # Also start the ReShade watchdog (reshade-watchdog.ps1, same folder) in
    # its own window alongside the game. Reuses that script rather than a
    # second copy of its restore logic.
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

$BinDir = Join-Path $PlutoRoot 'bin'
$Boot   = Join-Path $BinDir 'plutonium-bootstrapper-win32.exe'
$Config = Join-Path $PlutoRoot 'config.json'

if (-not (Test-Path -LiteralPath $Boot)) {
    Fail "Plutonium isn't installed where expected ($Boot missing). Run Plutonium at least once first."
}
if (-not (Test-Path -LiteralPath $Config)) {
    Fail "Plutonium's config.json wasn't found ($Config). Open Plutonium and load Black Ops II at least once first, so it knows where the game is."
}

$t6Path = $null
try {
    $cfg = Get-Content -LiteralPath $Config -Raw | ConvertFrom-Json
    $t6Path = [string] $cfg.t6Path
} catch {
    Fail "Couldn't read config.json: $($_.Exception.Message)"
}
if (-not $t6Path -or -not (Test-Path -LiteralPath $t6Path)) {
    Fail "Plutonium's config.json doesn't list a valid Black Ops II folder. Open Plutonium and load Black Ops II at least once first."
}

# Already running? Don't fight a second instance over the same fs_game slot.
$already = @('plutonium-bootstrapper-win32', 't6zm', 't6mp', 't6sp') |
    ForEach-Object { Get-Process -Name $_ -ErrorAction SilentlyContinue } |
    Select-Object -First 1
if ($already) {
    Fail "Black Ops II already appears to be running. Close it first, then try again."
}

Write-Host ''
Write-Host "  Starting BO2 Zombies in LAN mode with '$Mod' loaded..." -ForegroundColor Cyan
Write-Host '  Offline only this session - no online servers or stats.' -ForegroundColor Yellow
Write-Host ''

#  🛑 v2.3.8 - INVESTIGATED A CRASH HERE, ARGUMENTS TURNED OUT NOT TO BE IT.
#  User hit exception 0x80000003 (frozen thread, no GSC ever ran) right after
#  "bound socket to localhost:4976" in console_zm.log. Web search surfaced a
#  differently-ordered invocation ('-lan -offline +set name ... t6zm <path>
#  +set fs_game ...', flags before t6zm) from other Plutonium builds/tools,
#  and it was tried here - but DIRECT TESTING on this machine (running the
#  bootstrapper synchronously and capturing its own output) showed that
#  reordering throws an immediate "invalid application specified" and never
#  even starts, while THIS original order launches cleanly - confirmed with
#  a real game window ("Plutonium T6 Zombies (r5346) (LAN)") that reached
#  well past the socket-bind point where the crash happened, with no repeat
#  of the crash. So the argument order/flags were never the cause - reverted
#  to the form that is now verified to work. The original crash's real cause
#  is still unexplained; it did not reproduce on retest and is suspected
#  transient (see checkpoint). If it recurs, that rules out this script.
$gameArgs = @('t6zm', ('"' + $t6Path.TrimEnd('\') + '"'), '+name', ('"' + $LanName + '"'), '-lan',
              '+set', 'fs_game', ('"mods/' + $Mod + '"'))

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
