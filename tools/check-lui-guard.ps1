param(
    [string] $Root = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'

$codrootPath = Join-Path $Root 'ui\t6\codroot.lua'
$mainlobbyPath = Join-Path $Root 'ui\t6\mainlobby.lua'

if (-not (Test-Path -LiteralPath $codrootPath)) {
    Write-Error 'ui\t6\codroot.lua is missing'
    exit 1
}

$codroot = Get-Content -LiteralPath $codrootPath -Raw
$mainlobby = Get-Content -LiteralPath $mainlobbyPath -Raw
$failures = [System.Collections.Generic.List[string]]::new()

if ($codroot -notmatch 'pcall\s*\(\s*LUI\.CoDRoot\.ZmQolGuardInner') {
    $failures.Add('codroot does not dispatch ProcessEventNow through pcall')
}
if ($codroot -notmatch 'LUI\.CoDRoot\.ProcessEventNow\s*=') {
    $failures.Add('codroot does not replace ProcessEventNow')
}
if ($mainlobby -notmatch 'LUI\.CoDRoot\.ProcessEventNow\s*=\s*ZmQolGuardDispatch') {
    $failures.Add('mainlobby does not reinstall the guard after mod load')
}
if ($mainlobby -notmatch '\[zm_qol\] LUI event guard installed') {
    $failures.Add('mainlobby no longer logs the live guard marker')
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Output 'LUI event guard gate: PASS'
