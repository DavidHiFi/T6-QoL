<#
================================================================================
  Quality Of Life (zm_qol) - ReShade preflight

  Added 2026-09-21. Runs BEFORE the game starts, from both "Play BO2 with
  ReShade.bat" and "Play BO2 with mod + ReShade (LAN).bat", and again when
  reshade-watchdog.ps1 starts.

  WHY THIS EXISTS (user, 2026-09-21): "I clicked play with ReShade, it launched
  with ReShade, but ReShade had been reverted. No shaders, the UI was default,
  my hotkey was switched. It was ReShade with nothing." Then: "make sure that
  when you click play with ReShade, it verifies all the shaders are there and
  that it's using the configs, so you never start the game and have to close it
  and reinstall."

  The watchdog alone could not catch that, for two reasons found on the user's
  own PC the same day:

    1. THE VAULT HAD NO SHADERS IN IT. reshade-vault held the seven loose files
       - dxgi.dll and the six .ini - and no reshade-shaders folder at all. The
       watchdog restores FROM the vault and only checks that the vault EXISTS,
       so it sat there logging "bin is intact, nothing to restore" through a
       whole session while ReShade ran with zero effects. An empty source of
       truth is indistinguishable from a healthy one unless you count.

    2. A WIPED SHADER TREE STILL LOOKS PRESENT. Plutonium had deleted all 857
       files under bin\reshade-shaders but left all 138 DIRECTORIES standing.
       Test-Path on the folder says yes. Only a file count says no.

  So this script counts, and it heals the vault from the shipped payload before
  it trusts it. It never deletes and never overwrites a file that is already
  there, so in-game tweaks and whichever preset was last picked survive.

  Exit 0 means ReShade will work on the next launch. Exit 1 means it cannot be
  repaired from anything on this PC and the installer's ReShade option needs to
  be run - the caller should NOT start the game expecting effects.
================================================================================
#>

[CmdletBinding()]
param(
    [string] $PlutoRoot = (Join-Path $env:LOCALAPPDATA 'Plutonium'),
    # The shipped payload that sits next to this script. This is the only thing
    # on the PC guaranteed to be complete, so it is what the vault heals from.
    # Resolved in the body, not here: Windows PowerShell 5.1 has not bound
    # $PSScriptRoot yet while it is evaluating param() defaults, and the .bat
    # files all run 5.1.
    [string] $PayloadDir,
    [switch] $Quiet
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

if (-not $PayloadDir) {
    $here = $PSScriptRoot
    if (-not $here) { $here = Split-Path -Parent $MyInvocation.MyCommand.Path }
    $PayloadDir = Join-Path $here 'reshade'
}

$BinDir = Join-Path $PlutoRoot 'bin'
# 🛑 Must match $RESHADEVAULT in qol-installer.ps1 and $VaultDir in
# reshade-watchdog.ps1 exactly. Three files, one path.
$VaultDir = Join-Path $PlutoRoot 'storage\t6\_zm_qol_installer\reshade-vault'
# Last resort if the payload is gone: the installer's own "back up first" copy.
$BackupDir = Join-Path $PlutoRoot 'storage\t6\backups\reshade'

function Say {
    param([string] $Text, [string] $Colour = 'Gray')
    if (-not $Quiet) { Write-Host $Text -ForegroundColor $Colour }
}

function Count-Fx {
    param([string] $Root)
    if (-not (Test-Path -LiteralPath $Root)) { return 0 }
    return @(Get-ChildItem -LiteralPath $Root -Recurse -File -Filter *.fx -ErrorAction SilentlyContinue).Count
}

# Copy every file under $From that is not already under $To. Never overwrites,
# never deletes - the player's own edits are not ours to replace.
function Copy-Missing {
    param([string] $From, [string] $To)
    if (-not (Test-Path -LiteralPath $From)) { return 0 }
    if (-not (Test-Path -LiteralPath $To)) { New-Item -ItemType Directory -Force -Path $To | Out-Null }
    $n = 0
    $prefix = (Resolve-Path -LiteralPath $From).Path.TrimEnd('\')
    foreach ($f in Get-ChildItem -LiteralPath $From -Recurse -File -ErrorAction SilentlyContinue) {
        $rel = $f.FullName.Substring($prefix.Length).TrimStart('\')
        $target = Join-Path $To $rel
        if (Test-Path -LiteralPath $target) { continue }
        $dir = Split-Path -Parent $target
        if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
        Copy-Item -LiteralPath $f.FullName -Destination $target -Force
        $n++
    }
    return $n
}

Say ''
Say '  ReShade preflight' 'Cyan'
Say '  ------------------------------------------------------------------' 'Cyan'

# --- 1. the vault must be complete before anything is restored from it -------
$payloadFx = Count-Fx $PayloadDir
$vaultFx = Count-Fx $VaultDir

if ($payloadFx -gt 0 -and $vaultFx -lt $payloadFx) {
    if ($vaultFx -eq 0) {
        Say "  The ReShade vault has no shaders in it - filling it from this download." 'Yellow'
    } else {
        Say "  The ReShade vault is short ($vaultFx of $payloadFx shaders) - topping it up." 'Yellow'
    }
    $added = Copy-Missing $PayloadDir $VaultDir
    $vaultFx = Count-Fx $VaultDir
    Say "  Vault repaired: $added file(s) added, $vaultFx shaders now stored." 'Green'
}
elseif ($vaultFx -eq 0 -and (Count-Fx $BackupDir) -gt 0) {
    Say "  No shipped payload here - falling back to your ReShade backup." 'Yellow'
    $added = Copy-Missing $BackupDir $VaultDir
    $vaultFx = Count-Fx $VaultDir
    Say "  Vault repaired: $added file(s) added, $vaultFx shaders now stored." 'Green'
}

if ($vaultFx -eq 0) {
    Say ''
    Say '  ReShade cannot be verified: there is nothing to restore from.' 'Red'
    Say "    vault:   $VaultDir" 'Red'
    Say "    payload: $PayloadDir" 'Red'
    Say '  Run Windows Install.bat -> ReShade once, then try again.' 'Red'
    Say ''
    exit 1
}

# --- 2. what is actually missing from bin right now --------------------------
if (-not (Test-Path -LiteralPath $BinDir)) {
    Say "  Plutonium's bin folder does not exist yet: $BinDir" 'Red'
    Say '  Start Plutonium once so it creates it, then try again.' 'Red'
    exit 1
}

$binFx = Count-Fx (Join-Path $BinDir 'reshade-shaders')
$loose = @(Get-ChildItem -LiteralPath $VaultDir -File -ErrorAction SilentlyContinue)
$missingLoose = @($loose | Where-Object { -not (Test-Path -LiteralPath (Join-Path $BinDir $_.Name)) })

Say "  shaders in Plutonium's bin : $binFx of $vaultFx"
Say ("  config files missing       : {0} of {1}" -f $missingLoose.Count, $loose.Count)

if ($binFx -ge $vaultFx -and $missingLoose.Count -eq 0) {
    Say '  Everything ReShade needs is already in place.' 'Green'
    Say ''
    exit 0
}

# --- 3. put back only what is gone -------------------------------------------
Say '  Restoring what Plutonium cleared out...' 'Yellow'
$restored = Copy-Missing $VaultDir $BinDir

$binFx = Count-Fx (Join-Path $BinDir 'reshade-shaders')
$stillMissing = @($loose | Where-Object { -not (Test-Path -LiteralPath (Join-Path $BinDir $_.Name)) })

Say "  Restored $restored file(s)." 'Green'
Say "  shaders in Plutonium's bin : $binFx of $vaultFx"

if ($binFx -lt $vaultFx -or $stillMissing.Count -gt 0) {
    Say ''
    Say '  ReShade is still incomplete after the repair.' 'Red'
    foreach ($m in $stillMissing) { Say "    missing: $($m.Name)" 'Red' }
    Say '  Run Windows Install.bat -> ReShade to put it back properly.' 'Red'
    Say ''
    exit 1
}

Say '  ReShade is ready.' 'Green'
Say ''
exit 0
