param([string]$Source)

$ErrorActionPreference = 'Stop'

if (-not $Source) {
    $Source = Join-Path $PSScriptRoot '..\scripts\zm\quality_of_life.gsc'
}
$text = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $Source))

$combined = 'text_hud settext( getPerkName( perk ) + "\n" + getPerkDesc( perk ) );'
if (-not $text.Contains($combined)) {
    Write-Error 'Perk name and description must share one HUD element.'
}
if ($text.Contains('desc_hud = newclienthudelem( self );')) {
    Write-Error 'A separate description HUD element can disappear on Origins.'
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

Write-Output '    [ok] perk pop-up keeps every description on the shared text element'
