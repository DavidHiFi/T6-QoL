<#
    check-perk-guard.ps1  -  every survival location that spawns perk machines
                             must be listed in zmqol_loc_spawns_perk_machines().

    WHY THIS EXISTS
    ---------------
    2026-09-15, the boot straight after Trenches / Excavation Site / Church were
    registered:

        SV_Shutdown: Attempt to register ClientField electric_cherry_reload_fx
        failed. Client Field set 'allplayers' either already contains a field
        called electric_cherry_reload_fx, or a hash collision has occurred.

    zm_tomb.gsc mirrors two clientfields that stock only registers when a perk
    machine exists on the level. Once a loc script registers machines,
    _zm_perks::init() stops bailing at its `vending_triggers.size < 1` check,
    runs its custom-perk loop, and registers those fields ITSELF - so the mirror
    becomes a duplicate and the server shuts down at load.

    zmqol_loc_spawns_perk_machines() is the switch that suppresses the mirror.
    MOD_CATALOGUE.md §37e predicted this exact trap and named the trigger to
    watch for - "did we add perk machines to a loc script?" - and a human still
    missed it, because nothing enforced it.

    WHAT IT CHECKS
    --------------
    For every scripts\zm\locs\*.gsc: does it call register_perk_struct? If yes,
    its location name must appear in zmqol_loc_spawns_perk_machines() in
    scripts\zm\zm_tomb\zm_tomb.gsc.

    Only Origins (zm_tomb) locations are governed by that guard - it is the map
    whose zm_tomb.gsc carries the mirrors. Locations on other maps are reported
    as INFO so the list stays readable.

    EXIT CODES
    ----------
      0  every machine-spawning Origins location is in the guard
      1  at least one is missing  (do not build - it is SV_Shutdown at map load)
#>

param(
    [string] $Root = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'

$locDir = Join-Path $Root 'scripts\zm\locs'
$guardFile = Join-Path $Root 'scripts\zm\zm_tomb\zm_tomb.gsc'

if (-not (Test-Path $locDir) -or -not (Test-Path $guardFile)) {
    Write-Host "check-perk-guard: loc scripts or zm_tomb.gsc not found - skipping"
    exit 0
}

# --- the guard's current list ------------------------------------------------
$guardSrc = [IO.File]::ReadAllText($guardFile)
$m = [regex]::Match($guardSrc, 'zmqol_loc_spawns_perk_machines\s*\(\s*\)\s*\{(.*?)\n\}', 'Singleline')
if (-not $m.Success) {
    Write-Host "check-perk-guard: could not find zmqol_loc_spawns_perk_machines() in zm_tomb.gsc" -ForegroundColor Red
    exit 1
}
$guardBody = $m.Groups[1].Value
$guardLocs = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($q in [regex]::Matches($guardBody, '"([a-z_]+)"')) {
    $null = $guardLocs.Add($q.Groups[1].Value)
}

$missing = @()
$info = @()

foreach ($f in Get-ChildItem -Path $locDir -Filter *.gsc -File) {
    if ($f.BaseName -eq 'loc_common') { continue }

    $src = [IO.File]::ReadAllText($f.FullName)

    # count register_perk_struct calls outside comment lines
    $n = 0
    foreach ($line in [IO.File]::ReadAllLines($f.FullName)) {
        if ($line.TrimStart().StartsWith('//')) { continue }
        if ($line -match 'register_perk_struct\s*\(') { $n++ }
    }
    if ($n -eq 0) { continue }

    # zm_<map>_loc_<location>.gsc  ->  <location>
    if ($f.BaseName -notmatch '^zm_([a-z]+)_loc_(.+)$') { continue }
    $mapName = $Matches[1]
    $locName = $Matches[2]

    if ($mapName -ne 'tomb') {
        $info += ("{0,-18} {1} machine(s)  [{2}, not governed by this guard]" -f $locName, $n, $mapName)
        continue
    }

    if ($guardLocs.Contains($locName)) {
        $info += ("{0,-18} {1} machine(s)  in guard, OK" -f $locName, $n)
    }
    else {
        $missing += [pscustomobject]@{ Loc = $locName; Count = $n; File = $f.Name }
    }
}

Write-Host ""
Write-Host "check-perk-guard: guard lists [$(($guardLocs | Sort-Object) -join ', ')]"
foreach ($i in $info) { Write-Host "   $i" }

# ---------------------------------------------------------------------------
#  Second check: an UNBUILT Pack-a-Punch.
#
#  replaced\utility::register_perk_struct() special-cases specialty_weapupgrade
#  and spawns a "zombie_sign_please_wait" flag target, which draws the machine
#  in the generator-gated / unbuilt pose. Correct for classic Origins, wrong for
#  a survival arena. User hit it on Trenches, 2026-09-15.
#
#  loc_common::register_pap_struct_built() is the fix and must be used instead.
#  Only the locations restored in v2.17.x are policed - the TranZit four
#  (diner, power, tunnel, cornfield) shipped this way and are left alone rather
#  than changed blind.
# ---------------------------------------------------------------------------
$papPoliced = @('zm_tomb_loc_trenches', 'zm_tomb_loc_excavation_site', 'zm_tomb_loc_church',
                'zm_prison_loc_docks', 'zm_buried_loc_maze', 'zm_tomb_loc_crazy_place')
$papBad = @()
foreach ($f in Get-ChildItem -Path $locDir -Filter *.gsc -File) {
    if ($papPoliced -notcontains $f.BaseName) { continue }
    $n = 0
    foreach ($line in [IO.File]::ReadAllLines($f.FullName)) {
        if ($line.TrimStart().StartsWith('//')) { continue }
        if ($line -match 'register_perk_struct\s*\([^)]*specialty_weapupgrade') { $n++ }
    }
    if ($n -gt 0) { $papBad += [pscustomobject]@{ File = $f.Name; Count = $n } }
}

if ($papBad.Count -gt 0) {
    Write-Host ""
    Write-Host "UNBUILT PACK-A-PUNCH - register_perk_struct adds a 'please wait' sign:" -ForegroundColor Red
    foreach ($b in $papBad) {
        Write-Host ("   {0}  {1} specialty_weapupgrade call(s) via register_perk_struct" -f $b.File, $b.Count) -ForegroundColor Red
    }
    Write-Host "   Use scripts\zm\locs\loc_common::register_pap_struct_built( model, origin, angles )." -ForegroundColor Red
    Write-Host "check-perk-guard: FAIL (unbuilt Pack-a-Punch)" -ForegroundColor Red
    exit 1
}
Write-Host "   pack-a-punch: all policed locations use register_pap_struct_built, none draw 'please wait'"

# ---------------------------------------------------------------------------
#  Third check: the Church Pack-a-Punch coordinate, GSC vs CSC.
#
#  The server registers the machine and ghosts it; the client spawns its own
#  assembled p6_zm_tm_packapunch to stand in its place. Those are two files and
#  two sets of literals, and if they disagree the player gets TWO machines: an
#  unbuilt stone heap at the working one, and an assembled model somewhere else.
#
#  This is not hypothetical. v2.17.23 moved the GSC side to (478,-2535) and left
#  zm_tomb.csc on (528,-2697) - 170 units apart, past pap_built_pose()'s 128-unit
#  ghost radius, so nothing was ghosted at all. Both files already carried a
#  comment saying "must match zm_tomb_loc_church.gsc exactly". Comments do not
#  check anything.
#
#  GSC side is zmqol_church_pap_origin() / zmqol_church_pap_yaw(); CSC side is
#  the church branch of zmqol_cp_pap_client_model(). They are fixed literals so
#  remote clients cannot observe different local dvars.
# ---------------------------------------------------------------------------
$papGsc = Join-Path $Root 'scripts\zm\locs\zm_tomb_loc_church.gsc'
$papCsc = Join-Path $Root 'scripts\zm\zm_tomb\zm_tomb.csc'

if ((Test-Path $papGsc) -and (Test-Path $papCsc)) {
    function Get-PapCoordinates([string] $path, [bool] $client) {
        $t = [IO.File]::ReadAllText($path)
        $d = @{}
        if ($client) {
            $m = [regex]::Match($t, 'else\s+if\s*\(\s*str_loc\s*==\s*"church"\s*\).*?v_origin\s*=\s*\(\s*(-?\d+)\s*,\s*(-?\d+)\s*,\s*(-?\d+)\s*\)\s*;.*?v_angles\s*=\s*\(\s*0\s*,\s*(-?\d+)\s*,\s*0\s*\)', 'Singleline')
        }
        else {
            $m = [regex]::Match($t, 'zmqol_church_pap_origin\s*\(\s*\)\s*\{.*?return\s*\(\s*(-?\d+)\s*,\s*(-?\d+)\s*,\s*(-?\d+)\s*\)\s*;.*?zmqol_church_pap_yaw\s*\(\s*\)\s*\{.*?return\s+(-?\d+)\s*;', 'Singleline')
        }
        if ($m.Success) {
            $d['x'] = [int] $m.Groups[1].Value
            $d['y'] = [int] $m.Groups[2].Value
            $d['z'] = [int] $m.Groups[3].Value
            $d['yaw'] = [int] $m.Groups[4].Value
        }
        return $d
    }

    $gsc = Get-PapCoordinates $papGsc $false
    $csc = Get-PapCoordinates $papCsc $true
    $keys = @('x', 'y', 'z', 'yaw')
    $papDrift = @()

    foreach ($k in $keys) {
        $inG = $gsc.ContainsKey($k)
        $inC = $csc.ContainsKey($k)
        if (-not $inG -and -not $inC) {
            $papDrift += [pscustomobject]@{ Dvar = $k; Gsc = '(absent)'; Csc = '(absent)' }
        }
        elseif (-not $inG) { $papDrift += [pscustomobject]@{ Dvar = $k; Gsc = '(absent)'; Csc = $csc[$k] } }
        elseif (-not $inC) { $papDrift += [pscustomobject]@{ Dvar = $k; Gsc = $gsc[$k]; Csc = '(absent)' } }
        elseif ($gsc[$k] -ne $csc[$k]) { $papDrift += [pscustomobject]@{ Dvar = $k; Gsc = $gsc[$k]; Csc = $csc[$k] } }
    }

    if ($papDrift.Count -gt 0) {
        Write-Host ""
        Write-Host "CHURCH PACK-A-PUNCH COORDINATE DRIFT - the server and client would draw two machines:" -ForegroundColor Red
        foreach ($b in $papDrift) {
            Write-Host ("   {0,-24} gsc={1,-10} csc={2}" -f $b.Dvar, $b.Gsc, $b.Csc) -ForegroundColor Red
        }
        Write-Host "   zm_tomb_loc_church.gsc::zmqol_church_pap_origin()/_yaw() and the church branch" -ForegroundColor Red
        Write-Host "   of zm_tomb.csc::zmqol_cp_pap_client_model() must carry identical defaults." -ForegroundColor Red
        Write-Host "check-perk-guard: FAIL (church PaP coordinate drift)" -ForegroundColor Red
        exit 1
    }

    $shown = ($keys | ForEach-Object { "$_=$($gsc[$_])" }) -join ' '
    Write-Host "   church pap: gsc and csc agree  ($shown)"
}

if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Host "MISSING FROM zmqol_loc_spawns_perk_machines() - this is SV_Shutdown at map load:" -ForegroundColor Red
    foreach ($b in $missing) {
        Write-Host ("   {0}  registers {1} perk machine(s) in {2}" -f $b.Loc, $b.Count, $b.File) -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "   Add them to zmqol_loc_spawns_perk_machines() in scripts\zm\zm_tomb\zm_tomb.gsc." -ForegroundColor Red
    Write-Host "check-perk-guard: FAIL ($($missing.Count) missing)" -ForegroundColor Red
    exit 1
}

Write-Host "check-perk-guard: PASS"
exit 0
