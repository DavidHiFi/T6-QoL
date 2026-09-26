param([string]$Source)

$ErrorActionPreference = 'Stop'

if (-not $Source) {
    $Source = Join-Path $PSScriptRoot '..\scripts\zm\quality_of_life.gsc'
}
$text = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $Source))

$nameLine = 'name_hud settext( getPerkName( perk ) );'
if (-not $text.Contains($nameLine)) {
    Write-Error 'Perk name must have its own centered HUD element (name_hud).'
}
$descLine = 'desc_hud settext( getPerkDesc( perk ) );'
if (-not $text.Contains($descLine)) {
    Write-Error 'Perk description must have its own centered HUD element (desc_hud).'
}
if ($text.Contains('getPerkName( perk ) + "\n" + getPerkDesc( perk )')) {
    Write-Error 'Name and description must NOT share one HUD element: the merged element left-aligns the title.'
}
# Geometry lock (2026-09-18): the centered two-line look is these exact
# positions. Any "tidy" that moves them re-breaks the title alignment.
$geometry = @(
    'name_hud.alignx = "center";',
    'name_hud.horzalign = "user_center";',
    'name_hud.y = 122;',
    'name_hud.fontscale = 1.6;',
    'desc_hud.alignx = "center";',
    'desc_hud.horzalign = "user_center";',
    'desc_hud.y = 147;',
    'desc_hud.fontscale = 1.3;'
)
foreach ($line in $geometry) {
    if (-not $text.Contains($line)) {
        Write-Error "Perk pop-up geometry changed or missing: $line"
    }
}

$perks = @(
    'specialty_armorvest', 'specialty_fastreload', 'specialty_quickrevive',
    'specialty_rof', 'specialty_longersprint', 'specialty_additionalprimaryweapon',
    'specialty_deadshot', 'specialty_flakjacket', 'specialty_scavenger',
    'specialty_finalstand', 'specialty_nomotionsensor', 'specialty_grenadepulldeath'
)
foreach ($perk in $perks) {
    $case = 'case "' + $perk + '":'
    if (($text.Split($case).Count - 1) -lt 3) {
        Write-Error "$perk must have shader, name, and description cases."
    }
}

# Text lock (2026-09-26): the user approved these 24 strings on screen and asked
# for them to stay for good. Every title and description must match exactly.
# A stale branch or a "tidy" that brings back "Double Tap 2.0", Jugg's BO1
# "100 to 250" or any other old line fails the build here. To change one, the
# user has to ask; then update this table in the same commit as the .gsc.
# Receipts: modding-jobs\perk-popup-text-001\ (Nuketown screenshots).
function Get-PerkTable([string]$Src, [string]$Fn) {
    $m = [regex]::Match($Src, [regex]::Escape($Fn) + '\( perk \)\s*\{(.*?)\r?\n\}', 'Singleline')
    $t = @{}
    if (-not $m.Success) { return $t }
    $rx = 'case "([a-z_]+)":(?:\s*//[^\r\n]*)*\s*return "([^"]*)";'
    foreach ($c in [regex]::Matches($m.Groups[1].Value, $rx)) {
        $t[$c.Groups[1].Value] = $c.Groups[2].Value
    }
    return $t
}
$pinnedNames = [ordered]@{
    'specialty_armorvest'               = 'Juggernog'
    'specialty_fastreload'              = 'Speed Cola'
    'specialty_quickrevive'             = 'Quick Revive'
    'specialty_rof'                     = 'Double Tap'
    'specialty_longersprint'            = 'Stamin-Up'
    'specialty_additionalprimaryweapon' = 'Mule Kick'
    'specialty_deadshot'                = 'Deadshot Daiquiri'
    'specialty_flakjacket'              = 'PhD Flopper'
    'specialty_scavenger'               = 'Tombstone'
    'specialty_finalstand'              = "Who's Who"
    'specialty_nomotionsensor'          = 'Vulture Aid'
    'specialty_grenadepulldeath'        = 'Electric Cherry'
}
$pinnedDescs = [ordered]@{
    'specialty_armorvest'               = 'Increase Your Health from 100 to 160'
    'specialty_fastreload'              = 'Reload Your Weapons Faster'
    'specialty_quickrevive'             = 'In Solo Mode, You Revive Yourself. In Co-op Mode, You Revive Your Allies Faster'
    'specialty_rof'                     = 'Fires a Third Faster and Shoots Two Bullets per Shot'
    'specialty_longersprint'            = 'Move Faster and Sprint for Longer'
    'specialty_additionalprimaryweapon' = 'Allows You to Carry 3 Weapons Instead of 2'
    'specialty_deadshot'                = 'Tighter Hip Fire, Less Recoil, and Aim Assist Locks Onto the Head'
    'specialty_flakjacket'              = 'Immune to Explosive Damage. Creates Explosions When You Throw Yourself to the Ground'
    'specialty_scavenger'               = 'When You Die, You Leave Behind a Tombstone With Your Weapons and Perks | Co-op Only'
    'specialty_finalstand'              = 'Create a Clone to Bring Yourself Back to Life'
    'specialty_nomotionsensor'          = 'Zombies Drop Ammo and Money, and Green Clouds Hide You From Them'
    'specialty_grenadepulldeath'        = 'An Electric Shock When You Reload That Damages Nearby Zombies'
}
foreach ($pair in @(@('getPerkName', $pinnedNames), @('getPerkDesc', $pinnedDescs))) {
    $have = Get-PerkTable $text $pair[0]
    foreach ($perk in $pair[1].Keys) {
        $want = $pair[1][$perk]
        if (-not $have.ContainsKey($perk)) {
            Write-Error "Perk pop-up text lock: $($pair[0]) has no string for $perk."
        }
        if ($have[$perk] -cne $want) {
            Write-Error "Perk pop-up text lock: $($pair[0]) $perk reads `"$($have[$perk])`", the approved text is `"$want`"."
        }
        # settext drops "%" (it drew "33%" as "33." in game). Write it in words.
        if ($have[$perk].Contains('%')) {
            Write-Error "Perk pop-up text lock: $perk contains '%', which does not draw in game."
        }
    }
}

Write-Output '    [ok] perk pop-up centers the name over its own description element'
Write-Output '    [ok] perk pop-up titles and descriptions match the approved text'
