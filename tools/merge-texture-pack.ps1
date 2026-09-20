# =============================================================================
#  merge-textures.ps1  -  fold the shipped HD Texture Pack into the mod itself
# -----------------------------------------------------------------------------
#  The pack has always installed loose into %LOCALAPPDATA%\Plutonium\storage\t6\
#  images. That splits the mod's look across two downloads: install the mod
#  without the pack and half the perk icons are custom (they ride in mod.iwd)
#  while the other half fall back to stock. This copies the pack's payload into
#  the mod's own images\ folder, which pack_iwd.ps1 already packs into mod.iwd.
#
#  Not a new mechanism: mod.iwd carried a 2.1 GB texture pack from 59f1d3e until
#  the user asked for it to be pulled on 2026-08-07 (d15e08c). A fastfile holds
#  only an image HEADER - pixels are always read at runtime from a loose .iwi -
#  so these ride as plain files, declared in no zone, adding zero mod.ff entries.
#
#  WHAT IS DELIBERATELY NOT MERGED
#    hud_dpad_blood.iwi   the installer has always blocked it
#    $ICONFILES           three controller packs share one slot; merging any of
#                         them would take the choice away from the player
#    $VIEWARMFILES        18 character view-arm re-textures, never installed
#    $HASHBOUNDFILES      41 hash-named overrides that repaint stock texture
#                         slots - the 2026-09-20 diner-wall bug
#    git-tracked names    the mod's own art wins over a pack file of the same
#                         name. Tracked status is the keep-list, the same
#                         discriminator d15e08c used.
# =============================================================================
[CmdletBinding()]
param(
    [string] $Mod    = 'H:\Plutonium\t6\mods\zm_qol',
    [string] $JobDir = 'H:\Plutonium\modding-jobs\pack-merge-001',
    [switch] $WhatIfOnly
)

$ErrorActionPreference = 'Stop'

$packDir  = Join-Path $Mod 'Optionals\images'
$destDir  = Join-Path $Mod 'images'
if (-not (Test-Path -LiteralPath $packDir)) { throw "pack folder missing: $packDir" }
if (-not (Test-Path -LiteralPath $destDir)) { throw "mod images folder missing: $destDir" }

# --- the installer's own block lists, reproduced so the two cannot drift ------
$CONTROLLER_FOLDERS = @('Dualsense Icons','Nintendo Switch Icons','Xbox One Buttons')

$ICONFILES = @(
    'xenon_controller_top.iwi',
    'xenonbutton_a.iwi','xenonbutton_b.iwi','xenonbutton_x.iwi','xenonbutton_y.iwi',
    'xenonbutton_back.iwi','xenonbutton_start.iwi',
    'xenonbutton_lb.iwi','xenonbutton_rb.iwi','xenonbutton_lt.iwi','xenonbutton_rt.iwi',
    'xenonbutton_ls.iwi','xenonbutton_rs.iwi',
    'xenonbutton_dpad_all.iwi','xenonbutton_dpad_up.iwi','xenonbutton_dpad_down.iwi',
    'xenonbutton_dpad_left.iwi','xenonbutton_dpad_right.iwi',
    'xenonbutton_dpad_ud.iwi','xenonbutton_dpad_rl.iwi'
)
# Union in whatever the three packs actually carry, exactly as the installer does,
# so a pack that grows a file is covered without editing the constant above.
foreach ($folder in $CONTROLLER_FOLDERS) {
    $root = Join-Path $Mod "Optionals\$folder"
    if (-not (Test-Path -LiteralPath $root)) { continue }
    $ICONFILES += @(Get-ChildItem -LiteralPath $root -File -Recurse -Filter '*.iwi' |
                    ForEach-Object { $_.Name })
}
$ICONFILES = @($ICONFILES | Sort-Object -Unique)

$VIEWARMFILES = @(
    '~-gviewarm_zom_armhair_alpha_c.iwi',
    '~-gviewarm_zom_deluca_longsleeve_c.iwi',  'viewarm_zom_deluca_longsleeve_n.iwi',
    '~-gviewarm_zom_engineer_c.iwi',           'viewarm_zom_engineer_n.iwi',
    '~-gviewarm_zom_handsome_barea~031b2e1b.iwi',
    '~-gviewarm_zom_handsome_barearm_left_c.iwi', 'viewarm_zom_handsome_barearm_n.iwi',
    '~-gviewarm_zom_oldman_c.iwi',             'viewarm_zom_oldman_n.iwi',
    '~-gviewarm_zom_oleary_shortsleeve_c.iwi', 'viewarm_zom_oleary_shortsleeve_n.iwi',
    '~-gviewarm_zom_reporter_c.iwi',           'viewarm_zom_reporter_n.iwi',
    '~-gviewarm_zom_richtofen_l_c.iwi',        '~-gviewarm_zom_richtofen_r_c.iwi',
    'viewarm_zom_richtofen_n.iwi',
    '~~-gviewarm_zom_strands_alpha~b94bebe4.iwi'
)

$HASHBOUNDFILES = @(
    '184130943.iwi', '203218850.iwi', '213664688.iwi', '248893139.iwi',
    '310690366.iwi', '387107309.iwi', '414497708.iwi', '712299166.iwi',
    '749883228.iwi', '1242089752.iwi', '1361229722.iwi', '1402996581.iwi',
    '2139588580.iwi', '2193983524.iwi', '2402415086.iwi', '2463049788.iwi',
    '2531095777.iwi', '2532865902.iwi', '2596739401.iwi', '2652134348.iwi',
    '2696824118.iwi', '2696825333.iwi', '2897555984.iwi', '2963536512.iwi',
    '3009761504.iwi', '3104746560.iwi', '3113946313.iwi', '3195629244.iwi',
    '3277816579.iwi', '3343758740.iwi', '3353894529.iwi', '3355417974.iwi',
    '3411929122.iwi', '3449947920.iwi', '3566024970.iwi', '3718463383.iwi',
    '3818552282.iwi', '3958649079.iwi', '3971393839.iwi', '4094420848.iwi',
    '4238982186.iwi'
)

$blocked = New-Object System.Collections.Generic.HashSet[string] ([StringComparer]::OrdinalIgnoreCase)
foreach ($n in @('hud_dpad_blood.iwi') + $ICONFILES + $VIEWARMFILES + $HASHBOUNDFILES) {
    [void]$blocked.Add($n)
}

# --- the mod's own art, by git-tracked status --------------------------------
Push-Location $Mod
try { $trackedRaw = @(& git ls-files images) } finally { Pop-Location }
$tracked = New-Object System.Collections.Generic.HashSet[string] ([StringComparer]::OrdinalIgnoreCase)
foreach ($p in $trackedRaw) { [void]$tracked.Add(([System.IO.Path]::GetFileName($p))) }

# --- classify ----------------------------------------------------------------
$rows = foreach ($f in Get-ChildItem -LiteralPath $packDir -File -Filter '*.iwi') {
    $verdict =
        if ($blocked.Contains($f.Name))  { 'blocked' }
        elseif ($tracked.Contains($f.Name)) { 'mod-owns' }
        elseif (Test-Path -LiteralPath (Join-Path $destDir $f.Name)) { 'replace' }
        else { 'add' }
    [pscustomobject]@{ Name = $f.Name; Bytes = $f.Length; Verdict = $verdict; Source = $f.FullName }
}

$summary = $rows | Group-Object Verdict | Sort-Object Name |
           ForEach-Object { '{0,-9} {1,5}' -f $_.Name, $_.Count }
Write-Output '  pack classification:'
$summary | ForEach-Object { Write-Output "    $_" }

$toCopy = @($rows | Where-Object { $_.Verdict -in @('add','replace') })
$bytes  = ($toCopy | Measure-Object Bytes -Sum).Sum
Write-Output ('  to copy: {0:N0} files, {1:N0} bytes' -f $toCopy.Count, $bytes)

if (-not (Test-Path -LiteralPath $JobDir)) { New-Item -ItemType Directory -Path $JobDir | Out-Null }
$rows | Sort-Object Verdict, Name |
    Select-Object Verdict, Name, Bytes |
    Export-Csv -LiteralPath (Join-Path $JobDir 'texture-merge-plan.csv') -NoTypeInformation -Encoding UTF8
Write-Output "  plan written: $(Join-Path $JobDir 'texture-merge-plan.csv')"

if ($WhatIfOnly) { Write-Output '  -WhatIfOnly: nothing copied.'; exit 0 }

# --- copy ---------------------------------------------------------------------
$n = 0
foreach ($r in $toCopy) {
    Copy-Item -LiteralPath $r.Source -Destination (Join-Path $destDir $r.Name) -Force
    $n++
}
Write-Output ('  copied {0:N0} files into {1}' -f $n, $destDir)
$after = @(Get-ChildItem -LiteralPath $destDir -File -Filter '*.iwi')
Write-Output ('  images\ now holds {0:N0} .iwi, {1:N0} bytes' -f $after.Count,
              (($after | Measure-Object Length -Sum).Sum))
