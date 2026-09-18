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

Write-Output '    [ok] perk pop-up centers the name over its own description element'
