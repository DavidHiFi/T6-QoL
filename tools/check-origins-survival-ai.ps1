param(
    [string] $Root = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'

$locCommon = Get-Content -LiteralPath (Join-Path $Root 'scripts\zm\locs\loc_common.gsc') -Raw
$capture = Get-Content -LiteralPath (Join-Path $Root 'scripts\zm\replaced\zm_tomb_capture_zones.gsc') -Raw
$tomb = Get-Content -LiteralPath (Join-Path $Root 'scripts\zm\zm_tomb\zm_tomb.gsc') -Raw

$failures = [System.Collections.Generic.List[string]]::new()

if ($locCommon -match 'level\s+thread\s+fix_stuck_fight_distance\s*\(') {
    $failures.Add('loc_common still starts the broad AI field-rewrite loop')
}

$captureFunction = [regex]::Match(
    $capture,
    '(?s)capture_zombies_only_attack_nearby_players\s*\([^)]*\)\s*\{(?<body>.*?)\n\}'
)

if (-not $captureFunction.Success -or $captureFunction.Groups['body'].Value -notmatch 'if\s*\(\s*!is_classic\s*\(\s*\)\s*\)\s*\r?\n\s*return\s*;') {
    $failures.Add('Origins survival no longer returns before the stock capture-zone AI loop')
}

if ($tomb -notmatch 'replaceFunc\s*\(\s*maps\\mp\\zm_tomb_capture_zones::capture_zombies_only_attack_nearby_players') {
    $failures.Add('Origins no longer installs the capture-zone AI replacement')
}

$aitypeOverrides = @(
    Get-ChildItem -LiteralPath (Join-Path $Root 'aitype') -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -in '.gsc', '.csc' }
)

if ($aitypeOverrides.Count -gt 0) {
    $failures.Add("mod still ships $($aitypeOverrides.Count) aitype script override(s)")
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Output 'Origins survival AI gate: PASS'
