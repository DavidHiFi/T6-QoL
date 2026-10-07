# stamp-mod-json.ps1 - A18 provenance stamp (2026-10-06)
#
# Rewrites the DEPLOYED mod.json's version field to "<orig> <sha> <date>"
# (e.g. "^32.18.0 5d9449b 2026-10-06") so the Plutonium Mods menu shows which
# tree the running build came from. The REPO copy is never modified: the
# original version is read from the pristine repo mod.json, so the stamp is
# idempotent across redeploys.
#
# Inputs come from env vars so paths with spaces/apostrophes are safe (same
# pattern as the build.bat timestamp block):
#   STAMP_JSON_DEST - deployed mod.json to stamp (required)
#   STAMP_JSON_REPO - repo mod.json to read the original version from
#                     (default: ..\mod.json next to this script)
#
# PS 2.0-compatible (no ConvertFrom-Json). Silent-fail-safe: any problem
# leaves the destination untouched and exits 0 - this must never break a
# build or a deploy.

$ErrorActionPreference = 'Stop'
try {
	$dest = $env:STAMP_JSON_DEST
	if (-not $dest) { exit 0 }
	if (-not (Test-Path -LiteralPath $dest)) { exit 0 }

	$repo = $env:STAMP_JSON_REPO
	if (-not $repo) {
		$repo = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) '..\mod.json'
	}
	if (-not (Test-Path -LiteralPath $repo)) { exit 0 }

	# original version string from the pristine repo copy
	$repoText = [System.IO.File]::ReadAllText($repo)
	$m = [regex]::Match($repoText, '"version"\s*:\s*"([^"]*)"')
	if (-not $m.Success) { exit 0 }
	$orig = $m.Groups[1].Value

	# short sha of the tree the build came from; "unknown" when git is absent
	# or the mod.json was copied out of the repo
	$sha = 'unknown'
	$repoRoot = Split-Path -Parent $repo
	if (Test-Path -LiteralPath (Join-Path $repoRoot '.git')) {
		try {
			$out = @(& git -C $repoRoot rev-parse --short HEAD 2>$null)
			if ($LASTEXITCODE -eq 0 -and $out.Count -ge 1) {
				$cand = ('{0}' -f $out[0]).Trim()
				if ($cand) { $sha = $cand }
			}
		} catch { $sha = 'unknown' }
	}

	$date = Get-Date -Format 'yyyy-MM-dd'
	$stamp = '{0} {1} {2}' -f $orig, $sha, $date

	# rewrite only the version VALUE in the deployed copy (Remove/Insert, no
	# regex replacement escaping to worry about)
	$destText = [System.IO.File]::ReadAllText($dest)
	$m2 = [regex]::Match($destText, '"version"\s*:\s*"([^"]*)"')
	if (-not $m2.Success) { exit 0 }
	$newText = $destText.Remove($m2.Groups[1].Index, $m2.Groups[1].Length).Insert($m2.Groups[1].Index, $stamp)
	[System.IO.File]::WriteAllText($dest, $newText)
	exit 0
} catch {
	exit 0
}
