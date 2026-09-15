# check-recoil-prenerf.ps1 - build preflight: the pre-nerf recoil must not drift.
#
# WHY THIS EXISTS (2026-09-15). zm_qol ships Treyarch's PRE-PATCH recoil values.
# That is not an option and never was: there is no dvar, no script call and no
# menu row behind it, so nothing in the game can turn it on or off. It is simply
# what the weapon definitions in weapons\zm\ contain, and the only way it can be
# lost is a silent edit to one of those files.
#
# That is exactly what this checks. The expected values below were read out of
# the shipping defs on 2026-09-15 and cross-checked against
# modding-jobs\recoil-toggle-001\01-field-diff.txt, which diffed this mod against
# weapon assets dumped from zm_transit_patch.ff. Every value here is the mod's
# side of that diff - the pre-nerf side.
#
# A GAME 3 row for this CANNOT come back. The toggle needs both versions of each
# gun loaded at once, which is 20 extra weapon assets, and this mod is at the
# engine's weapon-asset ceiling: turning it on crashed every map load, and
# because the dvar archived it was a crash loop that survived restarts. See
# modding-jobs\recoil-toggle-001 and branch feature/recoil-toggle commit 2820514.
# So the values in the files ARE the feature. Guard them.
#
#   check-recoil-prenerf.ps1          exit 0 = every guarded field still pre-nerf
#
# Exit codes: 0 clean, 1 drift found, 2 io error.

$ErrorActionPreference = 'Stop'

$proj = Split-Path -Parent $PSScriptRoot
$dir = Join-Path $proj 'weapons\zm'

if (-not (Test-Path -LiteralPath $dir)) {
    Write-Host '    [skip] no weapons\zm folder'
    exit 0
}

# gun -> field -> expected pre-nerf value
$expected = @{
    'barretm82qol_zm'          = @{ adsViewKickPitchMin = '70'; adsViewKickPitchMax = '85'; adsViewKickYawMin = '-65'; adsViewKickYawMax = '35'; adsViewKickCenterSpeed = '500'; hipViewKickCenterSpeed = '800'; adsSpread = '3' }
    'barretm82qol_upgraded_zm' = @{ adsViewKickPitchMin = '70'; adsViewKickPitchMax = '85'; adsViewKickYawMin = '-65'; adsViewKickYawMax = '35'; adsViewKickCenterSpeed = '500'; hipViewKickCenterSpeed = '800'; adsSpread = '1' }
    'dsr50_zm'                 = @{ adsViewKickPitchMin = '67'; adsViewKickPitchMax = '67'; adsViewKickYawMin = '10'; adsViewKickYawMax = '-60'; adsViewKickCenterSpeed = '750'; hipViewKickCenterSpeed = '500'; adsSpread = '3' }
    'dsr50_upgraded_zm'        = @{ adsViewKickPitchMin = '67'; adsViewKickPitchMax = '67'; adsViewKickYawMin = '10'; adsViewKickYawMax = '-60'; adsViewKickCenterSpeed = '750'; hipViewKickCenterSpeed = '500'; adsSpread = '0' }
    'fiveseven_zm'             = @{ adsViewKickPitchMin = '20'; adsViewKickPitchMax = '40'; adsViewKickYawMin = '40'; adsViewKickYawMax = '-20'; adsViewKickCenterSpeed = '1100'; hipViewKickCenterSpeed = '1100'; adsSpread = '0.1' }
    'fiveseven_upgraded_zm'    = @{ adsViewKickPitchMin = '20'; adsViewKickPitchMax = '40'; adsViewKickYawMin = '40'; adsViewKickYawMax = '-20'; adsViewKickCenterSpeed = '1100'; hipViewKickCenterSpeed = '1100'; adsSpread = '0.1' }
    'tar21qol_zm'              = @{ adsViewKickPitchMin = '5'; adsViewKickPitchMax = '52.5'; adsViewKickYawMin = '-45'; adsViewKickYawMax = '45'; adsViewKickCenterSpeed = '1500'; hipViewKickCenterSpeed = '1500'; adsSpread = '5' }
    'tar21qol_upgraded_zm'     = @{ adsViewKickPitchMin = '-30'; adsViewKickPitchMax = '52.5'; adsViewKickYawMin = '-45'; adsViewKickYawMax = '45'; adsViewKickCenterSpeed = '1500'; hipViewKickCenterSpeed = '1500'; adsSpread = '2' }
}

# The T6 weapon def is one long backslash-delimited key/value stream. Pairing is
# read positionally: find the key token, take the token after it. Do NOT assume
# the stream starts on a key - these files do not.
function Get-WeaponFields {
    param([string]$Path, [string[]]$Names)

    $raw = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::GetEncoding('iso-8859-1'))
    $parts = $raw.Split([char]92)
    $out = @{}

    for ($i = 0; $i -lt $parts.Length - 1; $i++) {
        $key = $parts[$i].Trim()
        if ($Names -contains $key -and -not $out.ContainsKey($key)) {
            $out[$key] = $parts[$i + 1].Trim()
        }
    }
    return $out
}

$drift = @()
$checked = 0
$missing = 0

foreach ($gun in ($expected.Keys | Sort-Object)) {
    $path = Join-Path $dir $gun

    if (-not (Test-Path -LiteralPath $path)) {
        Write-Host ('    [gone]  ' + $gun + ' - guarded def is no longer in weapons\zm')
        $missing++
        continue
    }

    $want = $expected[$gun]
    $got = Get-WeaponFields -Path $path -Names ([string[]]$want.Keys)

    foreach ($field in ($want.Keys | Sort-Object)) {
        $checked++
        if (-not $got.ContainsKey($field)) {
            $drift += ($gun + '  ' + $field + '  expected ' + $want[$field] + ', field ABSENT')
        }
        elseif ($got[$field] -ne $want[$field]) {
            $drift += ($gun + '  ' + $field + '  expected ' + $want[$field] + ', found ' + $got[$field])
        }
    }
}

if ($missing -gt 0) {
    Write-Host ''
    Write-Host '    A guarded weapon def has been removed or renamed. If that was deliberate,'
    Write-Host '    update the table in tools\check-recoil-prenerf.ps1 in the same commit.'
    exit 1
}

if ($drift.Count -gt 0) {
    Write-Host ''
    Write-Host '    RECOIL HAS DRIFTED OFF THE PRE-NERF VALUES:'
    foreach ($d in $drift) { Write-Host ('      ' + $d) }
    Write-Host ''
    Write-Host '    These numbers are the pre-nerf recoil feature. There is no menu row and no'
    Write-Host '    dvar behind it - the files ARE the feature, so a changed value here silently'
    Write-Host '    ships Treyarch''s patched recoil to every player.'
    Write-Host '    Intentional? Update the table in tools\check-recoil-prenerf.ps1 to match.'
    exit 1
}

Write-Host ('    [ok] pre-nerf recoil intact - ' + $checked + ' fields across ' + $expected.Count + ' weapon defs')
Write-Host '    [note] hamr, rpd, type95 and xm8 ship their recoil in mod.ff, not weapons\zm,'
Write-Host '           so they are outside this check. Loose defs are what a stray edit hits.'
exit 0
