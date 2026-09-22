<#
    check-wonderweapon-anims.ps1  -  the Wave Gun float and the Winter's Howl
    ice block are an ASSET CHAIN, and this gate refuses to build with it broken.

    WHY THIS EXISTS
    ---------------
    2026-09-23, third time: *"the wave gun ... no longer makes the zombies float
    up into the sky"* and *"the winters howl ... they don't freeze like how
    they're meant to into like the ice cube"*. Both guns, same day, same cause -
    v2.17.26 had commented out eight lines in zone_source\mod_wonderweapons.zone
    as an "AI regression test".

    Neither weapon's script was touched, and that is exactly what makes this
    class of bug so expensive. Both guns ASK for a death anim state and fall
    back to an ordinary death, silently, when it is missing:

        zapgun.gsc              hasanimstatefromasd( "zm_death_sizzle" )
        _zm_weap_freezegun.gsc  HasAnimStateFromASD( "zm_death_freeze_t5" )
                                -> freezegun_run_skipped_death_events()

    So the guns keep working. They just stop being the guns. Days went into
    "fixing" zapgun.gsc across v2.16.1 / v2.16.3 / v2.17.35 while the real
    switch sat commented out in a zone file nobody diffed.

    THE CHAIN, AND WHY EVERY LINK IS CHECKED
    ----------------------------------------
    Each of these has broken at least once in this project's history:

      1. The 8 rawfile lines in mod_wonderweapons.zone.  Commented out by
         v2.17.26. This is the one that broke both guns.
      2. The .asd files carry BOTH death states.  The shipped copies had been
         trimmed to sizzle-only at some point, which is why the Winter's Howl
         froze on Origins and nowhere else.
      3. The 28 aitype overrides exist under aitype\.  Deleted wholesale by
         1d982cb (09-16) on an AI theory that was never confirmed.
      4. Those aitypes still carry the 19 microwave/freeze anim refs.  The .asd
         is validated against the AITYPE's baked anim list - strip the refs and
         every map dies at BG_AnimStateDef_Parse, which reads like a map bug.
      5. zapgun.gsc's fallback still sets a.nodeath = 1.  Setting it to
         undefined hands the corpse to stock's animmode( "gravity" ), and a
         gravity-owned body cannot be lifted by a moveto - the script safety net
         for maps with no .asd goes dead silently.

    -PostPack additionally proves the aitypes reached mod.iwd. A fix that lives
    only in the repo is the other half of this project's regression history; see
    the texture sync that compared file length and shipped nothing for weeks.

    EXIT CODES
    ----------
      0  the chain is intact
      1  at least one link is broken  (do not build)
#>

[CmdletBinding()]
param(
    [switch] $PostPack
)

$ErrorActionPreference = 'Stop'
$proj = Split-Path -Parent $PSScriptRoot
$fail = @()
$note = @()

$maps = @('zm_transit', 'zm_nuked', 'zm_highrise', 'zm_prison')

# --- 1. the eight rawfile lines are live, not commented ----------------------
$zonePath = Join-Path $proj 'zone_source\mod_wonderweapons.zone'
if (-not (Test-Path -LiteralPath $zonePath)) {
    $fail += "mod_wonderweapons.zone is missing entirely"
} else {
    $zone = Get-Content -LiteralPath $zonePath
    foreach ($m in $maps) {
        foreach ($pair in @(
            @{ kind = 'animtrees';     ext = 'atr' },
            @{ kind = 'animstatedefs'; ext = 'asd' }
        )) {
            $want = "rawfile,$($pair.kind)/$($m)_basic.$($pair.ext)"
            $live = $zone | Where-Object { $_.Trim() -eq $want }
            if (-not $live) {
                $commented = $zone | Where-Object { $_ -match [regex]::Escape($want) }
                if ($commented) {
                    $fail += "$want is COMMENTED OUT - this is what kills both guns"
                } else {
                    $fail += "$want is missing from the zone"
                }
            }
        }
    }
}

# --- 2. each .asd carries both death states ----------------------------------
#  zm_tomb_basic.asd is freeze-only by design - Origins has no sizzle state -
#  so it is checked for the freeze state alone.
$asdDir = Join-Path $proj 'zone_assets\animstatedefs'
foreach ($m in $maps) {
    $p = Join-Path $asdDir "$($m)_basic.asd"
    if (-not (Test-Path -LiteralPath $p)) {
        $fail += "$($m)_basic.asd is missing from zone_assets\animstatedefs"
        continue
    }
    $body = Get-Content -LiteralPath $p -Raw
    if ($body -notmatch 'zm_death_sizzle')   { $fail += "$($m)_basic.asd has no zm_death_sizzle state - the Wave Gun cannot float on this map" }
    if ($body -notmatch 'zm_death_freeze_t5'){ $fail += "$($m)_basic.asd has no zm_death_freeze_t5 state - the Winter's Howl cannot freeze on this map" }
}
$tomb = Join-Path $asdDir 'zm_tomb_basic.asd'
if ((Test-Path -LiteralPath $tomb) -and ((Get-Content -LiteralPath $tomb -Raw) -notmatch 'zm_death_freeze_t5')) {
    $fail += "zm_tomb_basic.asd has no zm_death_freeze_t5 state - the Winter's Howl cannot freeze on Origins"
}

# --- 3 + 4. the aitype overrides exist and still carry the anim refs ---------
$aiDir = Join-Path $proj 'aitype'
if (-not (Test-Path -LiteralPath $aiDir)) {
    $fail += "aitype\ is missing - without it every map dies at BG_AnimStateDef_Parse"
} else {
    $gsc = @(Get-ChildItem -LiteralPath $aiDir -Filter *.gsc -File -ErrorAction SilentlyContinue)
    $csc = @(Get-ChildItem -LiteralPath (Join-Path $aiDir 'clientscripts') -Filter *.csc -File -ErrorAction SilentlyContinue)
    if ($gsc.Count -lt 14) { $fail += "aitype\ has $($gsc.Count) .gsc, expected 14" }
    if ($csc.Count -lt 14) { $fail += "aitype\clientscripts\ has $($csc.Count) .csc, expected 14" }

    $stripped = @()
    foreach ($f in $gsc) {
        $body = Get-Content -LiteralPath $f.FullName -Raw
        $hasMicro  = $body -match 'ai_zombie_microwave_death'
        $hasFreeze = $body -match 'ai_zombie_freeze_death'
        if (-not ($hasMicro -and $hasFreeze)) { $stripped += $f.Name }
    }
    if ($stripped.Count -gt 0) {
        $fail += "aitype override(s) lost their microwave/freeze anim refs: $($stripped -join ', ')"
    }
}

# --- 5. the zapgun fallback still holds the corpse rigid ---------------------
$zap = Join-Path $proj 'scripts\zm\zapgun.gsc'
if (-not (Test-Path -LiteralPath $zap)) {
    $fail += "scripts\zm\zapgun.gsc is missing"
} else {
    $body = Get-Content -LiteralPath $zap -Raw
    $code = ($body -split "`n" | Where-Object { $_ -notmatch '^\s*//' }) -join "`n"
    if ($code -notmatch '\$?self\.a\.nodeath\s*=\s*1\s*;') {
        $fail += "zapgun.gsc's fallback no longer sets a.nodeath = 1 - the corpse goes back to animmode( `"gravity`" ) and the script lift dies silently"
    }
    if ($code -notmatch 'moveto\(') {
        $fail += "zapgun.gsc has no moveto left - the fallback lift is gone"
    }
}

# --- 6. the freezegun still has its death path ------------------------------
$fg = Join-Path $proj 'maps\mp\zombies\_zm_weap_freezegun.gsc'
if (-not (Test-Path -LiteralPath $fg)) {
    $fail += "maps\mp\zombies\_zm_weap_freezegun.gsc is missing"
} else {
    $body = Get-Content -LiteralPath $fg -Raw
    if ($body -notmatch 'zm_death_freeze_t5') { $fail += "_zm_weap_freezegun.gsc no longer references zm_death_freeze_t5" }
}

# --- PostPack: the aitypes actually reached mod.iwd -------------------------
if ($PostPack) {
    $iwd = Join-Path $proj 'mod.iwd'
    if (-not (Test-Path -LiteralPath $iwd)) {
        $fail += "mod.iwd not found - cannot prove the aitypes shipped"
    } else {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip = [IO.Compression.ZipFile]::OpenRead($iwd)
        try {
            $n = @($zip.Entries | Where-Object { $_.FullName -like 'aitype/*' }).Count
        } finally { $zip.Dispose() }
        if ($n -lt 28) {
            $fail += "mod.iwd carries $n aitype file(s), expected 28 - the animation route is in the repo but not in the build"
        } else {
            $note += "mod.iwd carries $n aitype files"
        }
    }
}

# --- report ------------------------------------------------------------------
if ($fail.Count -gt 0) {
    Write-Host ''
    Write-Host '    [BROKEN] the wonder-weapon animation chain:' -ForegroundColor Red
    foreach ($f in $fail) { Write-Host "      - $f" -ForegroundColor Red }
    Write-Host ''
    Write-Host '    Both the Wave Gun float and the Winter''s Howl ice block come from this' -ForegroundColor Yellow
    Write-Host '    chain. Neither gun''s script will report a problem - they fall back to an' -ForegroundColor Yellow
    Write-Host '    ordinary death and look merely disappointing. Fix the chain, do not go' -ForegroundColor Yellow
    Write-Host '    looking in zapgun.gsc or _zm_weap_freezegun.gsc.' -ForegroundColor Yellow
    Write-Host ''
    Write-Host '    Restore points: zone lines live in zone_source\mod_wonderweapons.zone;' -ForegroundColor Yellow
    Write-Host '    full .asd at modding-jobs\wwport-001\asd-originals\*.full-with-freeze;' -ForegroundColor Yellow
    Write-Host '    aitypes at modding-jobs\church-pap-001\PARKED-aitype-overrides\aitype\.' -ForegroundColor Yellow
    Write-Host '    Verified live on Tunnel 2026-09-23, commit 80dc533.' -ForegroundColor Yellow
    Write-Host ''
    exit 1
}

foreach ($n in $note) { Write-Host "    [ok] $n" }
Write-Host '    [ok] wonder-weapon animation chain intact (8 zone lines, 5 .asd, 28 aitypes, both fallbacks)'
exit 0
