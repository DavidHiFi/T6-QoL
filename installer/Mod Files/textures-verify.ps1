<#
================================================================================
  Quality Of Life (zm_qol) - texture preflight

  Added 2026-09-21. Runs before the game starts, from the same launchers that
  run reshade-verify.ps1.

  WHY THIS EXISTS. The HD textures cannot be served from inside the mod, and
  that is not a packaging choice - stock images stream from .ipak archives, an
  ipak outranks every file path, and the ONLY thing that beats one is the folder
  Plutonium patches its image loader to check first:
  %LOCALAPPDATA%\Plutonium\storage\t6\images.

  Measured, not assumed. v1.99.81 (a14af3b) booted every mod-side placement -
  mod.iwd by name, mod.iwd by hash, storage\t6\mods\zm_qol\images\ and
  <BO2>\mods\zm_qol\images\ - and all of them did nothing. The engine's own log
  lists the only two directories it will accept an ipak from, and both are
  inside the Black Ops II install, so a mod cannot ship one either. Plutonium's
  dvar list offers r_noipak, which disables ipak streaming for the whole game -
  useless here, because every stock texture outside this pack would go missing.

  So the folder has to exist. What does NOT have to exist is the player ever
  thinking about it: this counts the files on every launch and puts back
  anything that has gone, which is the actual complaint - "install the mod
  without the texture pack and half the perk icons are stock".

  Never overwrites, so a texture swapped in by hand is left alone.
================================================================================
#>
[CmdletBinding()]
param(
    [string] $PlutoRoot = (Join-Path $env:LOCALAPPDATA 'Plutonium'),
    [string] $PayloadDir,
    [switch] $Quiet
)
$ErrorActionPreference = 'Stop'
if (-not $PayloadDir) {
    $here = $PSScriptRoot
    if (-not $here) { $here = Split-Path -Parent $MyInvocation.MyCommand.Path }
    foreach ($c in @((Join-Path $here 'images'),
                     (Join-Path (Split-Path -Parent $here) 'Optionals\images'),
                     (Join-Path (Split-Path -Parent (Split-Path -Parent $here)) 'Optionals\images'))) {
        if (Test-Path -LiteralPath $c) { $PayloadDir = $c; break }
    }
}
$ImgDir = Join-Path $PlutoRoot 'storage\t6\images'
function Say { param([string]$T,[string]$C='Gray') if (-not $Quiet) { Write-Host $T -ForegroundColor $C } }

Say ''
Say '  Texture preflight' 'Cyan'
Say '  ------------------------------------------------------------------' 'Cyan'

if (-not $PayloadDir -or -not (Test-Path -LiteralPath $PayloadDir)) {
    Say '  No texture payload found next to the installer - nothing to check against.' 'Yellow'
    Say '  Run Windows Install.bat -> The mod once, which installs them.' 'Yellow'
    exit 0
}
if (-not (Test-Path -LiteralPath $ImgDir)) { New-Item -ItemType Directory -Force -Path $ImgDir | Out-Null }

#  🛑 RESTORE ONLY WHAT THE MANIFEST NAMES. The payload folder is the whole
#  pack, and parts of it must never go loose: the mod's own menu art (the nine
#  hash-named .iwi and the lui_bkg_zm_* set) is mod-gated and ships in mod.iwd
#  ONLY - a loose copy overrides the mod's own and breaks the menu background.
#  The controller glyphs are the player's choice, and the view-arm re-textures
#  have never been installed. textures-manifest.txt is the exact set, taken from
#  a folder measured working on a real install rather than derived from a rule.
$manifestPath = Join-Path (Split-Path -Parent $PSCommandPath) 'textures-manifest.txt'
if (Test-Path -LiteralPath $manifestPath) {
    $allow = New-Object System.Collections.Generic.HashSet[string] ([StringComparer]::OrdinalIgnoreCase)
    foreach ($line in Get-Content -LiteralPath $manifestPath) {
        $t = $line.Trim()
        if ($t) { [void]$allow.Add($t) }
    }
    $want = @(Get-ChildItem -LiteralPath $PayloadDir -File -Filter '*.iwi' |
              Where-Object { $allow.Contains($_.Name) })
} else {
    Say '  textures-manifest.txt is missing - checking nothing rather than guessing.' 'Yellow'
    Say ''
    exit 0
}
$have = 0; $missing = @()
foreach ($f in $want) {
    if (Test-Path -LiteralPath (Join-Path $ImgDir $f.Name)) { $have++ } else { $missing += $f }
}
Say ("  textures in place : {0} of {1}" -f $have, $want.Count)

if ($missing.Count -eq 0) { Say '  Every texture the mod needs is already there.' 'Green'; Say ''; exit 0 }

Say ("  Restoring {0} missing texture(s)..." -f $missing.Count) 'Yellow'
$n = 0
foreach ($f in $missing) {
    try { Copy-Item -LiteralPath $f.FullName -Destination (Join-Path $ImgDir $f.Name) -Force; $n++ }
    catch { Say "    could not copy $($f.Name)" 'Red' }
}
Say ("  Restored {0}." -f $n) 'Green'
$after = @($want | Where-Object { Test-Path -LiteralPath (Join-Path $ImgDir $_.Name) }).Count
Say ("  textures in place : {0} of {1}" -f $after, $want.Count)
if ($after -lt $want.Count) { Say '  Still incomplete - run Windows Install.bat -> The mod.' 'Red'; Say ''; exit 1 }
Say '  Textures are ready.' 'Green'
Say ''
exit 0
