# deploy.ps1 -Tree <worktree> -Job <job folder>
#
# Installs a worktree's build into the one folder the game loads, after backing
# up what is there. Run only with the coop 'game' and 'deploy' locks held, no
# game process running, and after merging every build other threads deployed
# before you (a deploy must be a superset of the one it replaces).
#
# It calls the mod's own build.bat (no 'offline'), which repacks, deploys the
# five files, refreshes the texture junction and stamps deployed-by.txt. Prove
# the result with verify-installed.py <tree> <gun>.
param(
    [Parameter(Mandatory)][string]$Tree,
    [Parameter(Mandatory)][string]$Job
)
$ErrorActionPreference = 'Stop'
$live = Join-Path $env:LOCALAPPDATA 'Plutonium\storage\t6\mods\zm_qol'
$raw  = Join-Path $env:LOCALAPPDATA 'Plutonium\storage\t6\raw\scripts'

if (Get-Process -Name 'plutonium-bootstrapper-win32' -ErrorAction SilentlyContinue) {
    Write-Host 'deploy: BLOCKED - a game process is running'; exit 1
}

# build.bat step 9 parks every foreign loose script. Another thread's probe in
# raw\scripts is theirs to remove; refuse rather than move it under them.
$probes = Get-ChildItem -LiteralPath $raw -Recurse -File -Include *.gsc,*.csc -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ne 'ranked.gsc' }
if ($probes) {
    Write-Host 'deploy: BLOCKED - loose probe scripts present (yours: move it aside first):'
    $probes | ForEach-Object { Write-Host "  $($_.FullName)" }
    exit 1
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$bak = Join-Path $Job "deploy-backup-$stamp"
New-Item -ItemType Directory -Path $bak | Out-Null
foreach ($f in 'mod.ff', 'mod.iwd', 'mod.json', 'mod.all.sabl', 'mod.all.sabs', 'deployed-by.txt') {
    $p = Join-Path $live $f
    if (Test-Path -LiteralPath $p) { Copy-Item -LiteralPath $p -Destination $bak }
}
Write-Host "deploy: backed up the previous install to $bak"

# build.bat ends in an unconditional pause; feed it one newline.
$log = Join-Path $Job "build-deploy-$stamp.log"
"`r`n" | cmd /c "`"$Tree\build.bat`"" *> $log
$code = $LASTEXITCODE
Write-Host "deploy: build.bat exit=$code (log $log)"
exit $code
