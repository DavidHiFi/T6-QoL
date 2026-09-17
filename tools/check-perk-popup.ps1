param([string]$Source)

$ErrorActionPreference = 'Stop'

if (-not $Source) {
    $Source = Join-Path $PSScriptRoot '..\scripts\zm\quality_of_life.gsc'
}
$text = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $Source))

# The pop-up is three elements: icon + name + description, each centred on
# its own hudelem. Merging name + description onto one element centres the
# block on its widest line, so under a long description (Quick Revive, 82
# chars) the short name draws left of centre. Never recombine them.
if ($text.Contains('getPerkName( perk ) + "\n" + getPerkDesc( perk )')) {
    Write-Error 'Perk name and description must be separate centred elements, not one combined string.'
}
foreach ($marker in @('name_hud = newclienthudelem( self );', 'desc_hud = newclienthudelem( self );')) {
    if (-not $text.Contains($marker)) {
        Write-Error "Missing required pop-up element: $marker"
    }
}
foreach ($marker in @('name_hud settext( getPerkName( perk ) );', 'desc_hud settext( getPerkDesc( perk ) );')) {
    if (-not $text.Contains($marker)) {
        Write-Error "Missing required pop-up text: $marker"
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

Write-Output '    [ok] perk pop-up keeps name and description on separate centred elements'
