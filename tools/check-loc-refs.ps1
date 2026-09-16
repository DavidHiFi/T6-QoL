<#
    check-loc-refs.ps1  -  resolve every cross-script GSC/CSC call in this mod.

    WHY THIS EXISTS
    ---------------
    2026-09-15: registering the Excavation Site survival location crashed Origins
    at map load with

        **** Unresolved external : "spawn_wallbuy_plywood" with 2 parameters
             in "scripts/zm/locs/zm_tomb_loc_excavation_site.gsc" ****
        SV_Shutdown: **** 1 script error(s)

    The call had been re-pointed from a file the mod does not ship
    (zm_tomb_reimagined.gsc) to loc_common, and the body was never brought over.
    It sat harmless for months because the location was unregistered.

    Two things make this class of bug worth its own gate:

      1. gsc-tool PARSES IT CLEAN. Syntax is fine; the target just is not there.
         A green parse proves nothing about cross-script references.
      2. IT IS FATAL FOR THE WHOLE MAP, NOT JUST THE CALLER. GSC resolves every
         script in the zone at map load. The crash above landed on CHURCH, which
         never calls the function. One dangling reference in any registered loc
         script takes down every location on that map.

    WHAT IT CHECKS
    --------------
    Every `path\to\script::function(` reference in scripts\ and clientscripts\,
    resolved against the function definitions in the target file. Reports any
    reference whose target file is shipped but does not define the function.

    References into maps\ / clientscripts\mp\ (stock engine scripts) are
    reported separately as INFO, since those resolve from the game's own
    fastfiles and cannot be checked from disk.

    EXIT CODES
    ----------
      0  no dangling references
      1  at least one dangling reference  (do not build)
#>

param(
    [string] $Root = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'

$sourceDirs = @('scripts', 'clientscripts') |
    ForEach-Object { Join-Path $Root $_ } |
    Where-Object { Test-Path $_ }

if (-not $sourceDirs) {
    Write-Host "check-loc-refs: no scripts\ or clientscripts\ under $Root"
    exit 0
}

$files = Get-ChildItem -Path $sourceDirs -Recurse -File -Include *.gsc, *.csc

# --- index every function this mod defines, per file -------------------------
#
#  🛑 COMPILED SCRIPTS MUST BE SKIPPED, NOT SCANNED. Some shipped .csc are
#  COMPILED bytecode, not source - clientscripts\mp\zombies\_zm_perk_vulture.csc
#  is one. A line-based scan finds no definitions in those and would report every
#  call into them as dangling. The first run of this gate did exactly that and
#  flagged four calls that demonstrably resolve in game (Maze registers Vulture
#  Aid through one of them). A NUL byte in the head of the file is the tell.
$defs = @{}
$compiled = @{}
foreach ($f in $files) {
    $rel = $f.FullName.Substring($Root.Length + 1) -replace '\\', '/' -replace '\.(gsc|csc)$', ''

    #  Read the head with .NET, not Get-Content: -AsByteStream is PowerShell 7+
    #  and -Encoding Byte is 5.1-only, and build.bat runs this under Windows
    #  PowerShell 5.1. A FileStream works identically on both.
    $head = New-Object byte[] 4096
    $fs = [IO.File]::OpenRead($f.FullName)
    try { $read = $fs.Read($head, 0, $head.Length) } finally { $fs.Dispose() }

    $isCompiled = $false
    for ($i = 0; $i -lt $read; $i++) {
        if ($head[$i] -eq 0) { $isCompiled = $true; break }
    }
    if ($isCompiled) {
        $compiled[$rel] = $true
        continue
    }

    $names = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($line in [IO.File]::ReadAllLines($f.FullName)) {
        # a definition is a function name at column 0 followed by ( ... )
        if ($line -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*\(') {
            $null = $names.Add($Matches[1])
        }
    }
    $defs[$rel] = $names
}

$bad = @()
$info = 0

foreach ($f in $files) {
    $relSelf = $f.FullName.Substring($Root.Length + 1) -replace '\\', '/'
    $lineNo = 0
    foreach ($line in [IO.File]::ReadAllLines($f.FullName)) {
        $lineNo++
        $trimmed = $line.TrimStart()
        if ($trimmed.StartsWith('//')) { continue }

        foreach ($m in [regex]::Matches($line, '([A-Za-z0-9_\\/]+)::([A-Za-z_][A-Za-z0-9_]*)\s*\(')) {
            $target = $m.Groups[1].Value -replace '\\', '/'
            $func = $m.Groups[2].Value

            if ($compiled.ContainsKey($target)) {
                # compiled bytecode we ship - cannot read its symbols from disk
                $info++
            }
            elseif ($defs.ContainsKey($target)) {
                if (-not $defs[$target].Contains($func)) {
                    $bad += [pscustomobject]@{
                        File = $relSelf; Line = $lineNo; Target = $target; Func = $func
                    }
                }
            }
            else {
                # stock engine script (maps\..., clientscripts\mp\...) - not on disk
                $info++
            }
        }
    }
}

Write-Host ""
Write-Host "check-loc-refs: $($files.Count) script(s), $info reference(s) into stock engine scripts (not checkable from disk)"

if ($bad.Count -gt 0) {
    Write-Host ""
    Write-Host "DANGLING REFERENCES - these are 'Unresolved external' at map load and are FATAL:" -ForegroundColor Red
    foreach ($b in $bad) {
        Write-Host ("   {0}:{1}  ->  {2}::{3}   NOT DEFINED" -f $b.File, $b.Line, $b.Target, $b.Func) -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "check-loc-refs: FAIL ($($bad.Count) dangling)" -ForegroundColor Red
    exit 1
}

Write-Host "check-loc-refs: PASS - every in-mod cross-script call resolves"
exit 0
