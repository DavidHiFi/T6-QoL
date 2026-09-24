<#
    check-menu-art-modgated.ps1  -  the main-menu art must be reachable ONLY
    while this mod is loaded.

    WHY THIS EXISTS
    ---------------
    User, 2026-09-14: the art must not be a loose override, because loose
    overrides apply to the stock game.
    User, 2026-09-23, with a screenshot of the QoL title screen: *"i didn't have
    the mod loaded and i still saw them so make sure they loaded from the mod
    not from the images folder"*.

    Same instruction, nine days apart, because nothing was checking.

    THE TRAP
    --------
    storage\t6\images is a JUNCTION into the deployed mod's images\ folder. That
    was a deliberate, good change - the HD texture pack has to be loose, an ipak
    beats every mod-side path, and the junction stopped the pack being duplicated
    into mod.iwd (1.48 GB -> 3.3 MB).

    But a junction has no opinion about which mod is loaded. Everything inside it
    is global: stock game, other mods, no mod at all. So the same change that
    fixed the texture pack silently un-gated the menu art, and neither has an
    error message.

    The split this gate enforces:

        images\        loose, global, the HD texture pack           - correct
        images_menu\   packed into mod.iwd as images/, mod-gated    - correct
        a menu file in images\                                      - the bug

    WHAT IT CHECKS
    --------------
      1. all 20 menu textures are in images_menu\
      2. none of them are in images\ or zone_assets\images\ (either would put
         them back in the junction on the next build)
      3. -PostPack: all 20 really are inside the built mod.iwd, under images/
      4. -PostPack: none of them are in the DEPLOYED mod's images\ folder, which
         is what the junction actually exposes. The sync has no delete pass, so
         a stale copy there keeps overriding the stock game no matter how the
         repo looks.

    Each texture ships under TWO names - its asset name and its zm.ipak hash -
    because the menu's lookup order varies and an override only wins if both are
    present. Both names are required; half the pair is a broken menu.

    EXIT CODES
    ----------
      0  the art is mod-gated
      1  at least one file is loose or missing  (do not build)
#>

[CmdletBinding()]
param(
    #  -PostPack        the built mod.iwd really carries the art under images/
    #  -CheckDeployed   the DEPLOYED images folder is clean of it
    #
    #  These are separate on purpose. build.bat calls -PostPack straight after
    #  the repack, and at that point the deployed folder has not been evicted
    #  yet - the eviction is part of the deploy step further down. Checking both
    #  there fails a build that is about to fix itself.
    [switch] $PostPack,
    [switch] $CheckDeployed
)

$ErrorActionPreference = 'Stop'
$proj = Split-Path -Parent $PSScriptRoot
$fail = @()
$note = @()

#  asset name -> zm.ipak hash. Both names must ship for the override to win.
$menu = [ordered]@{
    'lui_bkg_zm'                     = '526515145'
    'globe_map_zm'                   = '3683125256'
    'menu_zm_title_screen'           = '448887191'
    'lui_bkg_zm_rocks_back'          = '1429008398'
    'lui_bkg_zm_rocks_front'         = '2125833060'
    'lui_bkg_zm_rocks_front_forward' = '260179946'
    'lui_bkg_zm_sun'                 = '1777841770'
    'lui_bkg_zm_flare'               = '3018744286'
    'lui_bkg_zm_flare_left'          = '3243541390'
    'lui_bkg_zm_meteor'              = '3331619410'
}
$names = @()
foreach ($k in $menu.Keys) { $names += $k; $names += $menu[$k] }

$menuDir  = Join-Path $proj 'images_menu'
$looseDir = Join-Path $proj 'images'
$zoneDir  = Join-Path $proj 'zone_assets\images'

# --- 1. present in images_menu\ ---------------------------------------------
if (-not (Test-Path -LiteralPath $menuDir)) {
    $fail += "images_menu\ is missing entirely - the menu art has nowhere mod-gated to ship from"
} else {
    $missing = @()
    foreach ($n in $names) {
        if (-not (Test-Path -LiteralPath (Join-Path $menuDir "$n.iwi"))) { $missing += "$n.iwi" }
    }
    if ($missing.Count -gt 0) {
        $fail += "images_menu\ is missing $($missing.Count) of $($names.Count) file(s): $(($missing | Select-Object -First 6) -join ', ')"
    }
}

# --- 2. absent from the loose folders ---------------------------------------
foreach ($pair in @(
    @{ dir = $looseDir; label = 'images\';             why = 'it is mirrored into the global storage\t6\images junction' },
    @{ dir = $zoneDir;  label = 'zone_assets\images\'; why = 'build.bat step [1/9] copies it straight back into images\' }
)) {
    if (-not (Test-Path -LiteralPath $pair.dir)) { continue }
    $leak = @()
    foreach ($n in $names) {
        if (Test-Path -LiteralPath (Join-Path $pair.dir "$n.iwi")) { $leak += "$n.iwi" }
    }
    if ($leak.Count -gt 0) {
        $fail += "$($leak.Count) menu texture(s) are in $($pair.label) - $($pair.why): $(($leak | Select-Object -First 6) -join ', ')"
    }
}

# --- 3 + 4. the built and deployed reality ----------------------------------
if ($PostPack) {
    $iwd = Join-Path $proj 'mod.iwd'
    if (-not (Test-Path -LiteralPath $iwd)) {
        $fail += "mod.iwd not found - cannot prove the menu art shipped"
    } else {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip = [IO.Compression.ZipFile]::OpenRead($iwd)
        try {
            $inIwd = @{}
            foreach ($e in $zip.Entries) { if ($e.FullName -like 'images/*') { $inIwd[$e.FullName] = $true } }
        } finally { $zip.Dispose() }
        $absent = @()
        foreach ($n in $names) { if (-not $inIwd.ContainsKey("images/$n.iwi")) { $absent += "$n.iwi" } }
        if ($absent.Count -gt 0) {
            $fail += "mod.iwd is missing $($absent.Count) menu texture(s) under images/: $(($absent | Select-Object -First 6) -join ', ')"
        } else {
            $note += "mod.iwd carries all $($names.Count) menu textures under images/"
        }
    }

}

#  The deployed folder is what the junction actually exposes. A stale copy here
#  overrides the stock game however clean the repo looks.
if ($CheckDeployed) {
    $deployed = $env:PLUTO_DIR
    if (-not $deployed) {
        $fail += "PLUTO_DIR is not set - cannot check the deployed images folder"
    } else {
        $dImg = Join-Path $deployed 'images'
        if (Test-Path -LiteralPath $dImg) {
            $stale = @()
            foreach ($n in $names) { if (Test-Path -LiteralPath (Join-Path $dImg "$n.iwi")) { $stale += "$n.iwi" } }
            if ($stale.Count -gt 0) {
                $fail += "$($stale.Count) menu texture(s) are STILL in the deployed images folder and remain global: $(($stale | Select-Object -First 6) -join ', ')"
            } else {
                $note += "deployed images folder is clean of menu art"
            }
        }
    }
}

# --- report ------------------------------------------------------------------
if ($fail.Count -gt 0) {
    Write-Host ''
    Write-Host '    [BROKEN] the main-menu art is not mod-gated:' -ForegroundColor Red
    foreach ($f in $fail) { Write-Host "      - $f" -ForegroundColor Red }
    Write-Host ''
    Write-Host '    storage\t6\images is a junction into the deployed mod''s images\ folder,' -ForegroundColor Yellow
    Write-Host '    and that junction is GLOBAL - it applies to the stock game and to every' -ForegroundColor Yellow
    Write-Host '    other mod, with nothing loaded. The menu art belongs in images_menu\,' -ForegroundColor Yellow
    Write-Host '    which pack_iwd.ps1 packs into mod.iwd as images/ and which never reaches' -ForegroundColor Yellow
    Write-Host '    the junction. The HD texture pack stays loose in images\ on purpose.' -ForegroundColor Yellow
    Write-Host ''
    exit 1
}

foreach ($n in $note) { Write-Host "    [ok] $n" }
Write-Host "    [ok] menu art is mod-gated ($($names.Count) textures in images_menu\, none loose)"
exit 0
