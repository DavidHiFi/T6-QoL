<#
    coop-gate.ps1  -  catch the co-op defect shapes this mod keeps producing.

    WHY THIS EXISTS
    ---------------
    2026-09-15 audit (modding-jobs\mp-stability-001): zm_qol's own games_mp.log
    holds 322 join records and every one is client slot 0. Co-op has never been
    exercised. It is not regressed - it was never built.

    Solo cannot catch any of this. On a Plutonium listen server the host IS a
    client in one process, so the host never sees a remote client's dvar space,
    never exercises the between-rounds respawn path (solo bleed-out ends the
    game), and never has a second player to overwrite its state. Every defect
    below is invisible until two people play, and nobody plays two-up.

    So the defects have to be caught by reading, and that is what this does.

    WHAT IT CHECKS
    --------------
    R1  A client script (.csc) reading a dvar the engine does not replicate.
        On the host this reads the server's value; on a REMOTE client it reads
        that machine's local default. When such a dvar gates a
        registerclientfield, the two halves build different clientfield tables
        and every remote player is dropped with EXE_CLIENT_FIELD_MISMATCH
        before the map starts.
        Replicated and therefore safe: mapname, ui_gametype,
        ui_zm_mapstartlocation, scr_zm_ui_gametype_group - stock T6 client
        scripts make load-time decisions on exactly these
        (ZM\Core\clientscripts\mp\zombies\_zm.csc:32-33), and Treyarch shipped
        4-player co-op.

    R2  Indexing a player array at [0] as if it were "the host" or "the
        player". get_players()[0] is not defined to be the host; on a listen
        server it usually is, which is why this survives solo testing. The
        answer is gethostplayer().

    R3  A connect loop that parks on one player's spawn. `level waittill
        ("connected", p)` followed by `p waittill("spawned_player")` INSIDE the
        loop drops every "connected" notify raised while it is parked, so
        players 3 and 4 connecting in the same burst are never served. Thread
        the per-player work instead.

    R4  setdvar() inside a per-player thread (a function carrying
        `self endon("disconnect")`). The field is per-player, the dvar is one
        global: the last player to act wins for everybody. This is the shape
        behind "one player types .hud off and all four screens go blank".

    R5  (INFO) server-scope hudelem count. A server hudelem is ONE element
        shared by every player. Correct for genuinely global HUD, wrong for
        anything per-player. Reported so growth gets noticed.

    R6  (INFO) survival-location initial-spawn margin. Stock _zm.gsc:415-419
        deletes half an initial-spawn pool by script_int for an all-allies
        lobby, so a 4/4 split leaves exactly 4 points for 4 players. Stock's
        own survival locations ship 5 per side. With no spare, the 5th
        playernum assignment of the match - one rejoin - falls through
        _zm.gsc:478 to spawnpoints[0] and spawns inside player 1.

    BASELINE
    --------
    Findings already present and accepted at audit time live in
    tools\coop-gate.baseline.txt, keyed by rule + file + token (not line
    number, so they survive edits). Baselined findings are reported as KNOWN
    and do not fail the build. ANYTHING NEW FAILS.

    That is the point: this gate is not here to fix the backlog, it is here to
    stop the backlog growing while nobody is testing co-op.

    Regenerate the baseline with -UpdateBaseline after deliberately accepting a
    new finding. Do not regenerate it to make a build go green.

    EXIT CODES
    ----------
      0  no new findings
      1  at least one new finding  (do not build)
#>

param(
    [string] $Root = (Split-Path -Parent $PSScriptRoot),
    [switch] $UpdateBaseline,
    [switch] $Quiet
)

$ErrorActionPreference = 'Stop'

# Dvars the engine replicates to remote clients. Anything else read in a .csc
# returns that machine's own local value.
$ReplicatedDvars = @(
    'mapname',
    'ui_gametype',
    'ui_zm_mapstartlocation',
    'scr_zm_ui_gametype_group',
    'scr_zm_ui_gametype'
)

$baselinePath = Join-Path $PSScriptRoot 'coop-gate.baseline.txt'

$baseline = @{}
if ((Test-Path $baselinePath) -and (-not $UpdateBaseline)) {
    foreach ($line in (Get-Content $baselinePath)) {
        $t = $line.Trim()
        if ($t -eq '' -or $t.StartsWith('#')) { continue }
        $baseline[$t] = $true
    }
}

$findings = New-Object System.Collections.ArrayList
$info     = New-Object System.Collections.ArrayList

function Add-Finding {
    param($Rule, $RelPath, $Line, $Token, $Message)
    $key = "$Rule|$RelPath|$Token"
    $null = $findings.Add([pscustomobject]@{
        Rule    = $Rule
        Rel     = $RelPath
        Line    = $Line
        Token   = $Token
        Message = $Message
        Key     = $key
        Known   = $baseline.ContainsKey($key)
    })
}

# --- gather sources -------------------------------------------------------
$sourceDirs = @('scripts', 'clientscripts') |
    ForEach-Object { Join-Path $Root $_ } |
    Where-Object { Test-Path $_ }

if (-not $sourceDirs) {
    Write-Host "coop-gate: no scripts\ or clientscripts\ under $Root"
    exit 0
}

$files = Get-ChildItem -Path $sourceDirs -Recurse -Include *.gsc, *.csc -File

# Compiled .csc are bytecode, not source - scanning them yields garbage.
# Heuristic: a source file has a readable function definition at column 0.
$textFiles = @()
foreach ($f in $files) {
    $head = Get-Content $f.FullName -TotalCount 200 -ErrorAction SilentlyContinue
    if ($null -eq $head) { continue }
    if (($head -join "`n") -match '(?m)^[a-zA-Z_][a-zA-Z0-9_]*\s*\(') {
        $textFiles += $f
    }
}

function Get-Rel { param($Full) return $Full.Substring($Root.Length).TrimStart('\') }

# Split a file into top-level function blocks: name, start line, body lines.
function Get-FunctionBlocks {
    param($Lines)
    $blocks = @()
    $starts = @()
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^([a-zA-Z_][a-zA-Z0-9_]*)\s*\(') {
            $starts += [pscustomobject]@{ Name = $Matches[1]; Index = $i }
        }
    }
    for ($s = 0; $s -lt $starts.Count; $s++) {
        $from = $starts[$s].Index
        if ($s + 1 -lt $starts.Count) { $to = $starts[$s + 1].Index - 1 } else { $to = $Lines.Count - 1 }
        $blocks += [pscustomobject]@{
            Name  = $starts[$s].Name
            Start = $from + 1
            Body  = $Lines[$from..$to]
        }
    }
    return $blocks
}

function Remove-Comment {
    param($Line)
    $l = $Line
    $idx = $l.IndexOf('//')
    if ($idx -ge 0) { $l = $l.Substring(0, $idx) }
    return $l
}

# --- scan -----------------------------------------------------------------
$serverHudCount = 0

foreach ($f in $textFiles) {
    $rel   = Get-Rel $f.FullName
    $lines = Get-Content $f.FullName
    $isCsc = $f.Extension -eq '.csc'

    # ---- R1: non-replicated dvar read in a client script -----------------
    if ($isCsc) {
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $code = Remove-Comment $lines[$i]
            if ($code -notmatch 'getdvar') { continue }
            $m = [regex]::Matches($code, 'getdvar(?:int|float|string)?(?:default)?\s*\(\s*#?"([^"]+)"')
            foreach ($hit in $m) {
                $name = $hit.Groups[1].Value
                if ($ReplicatedDvars -contains $name) { continue }
                Add-Finding 'R1' $rel ($i + 1) $name `
                    "client script reads non-replicated dvar '$name' - a remote client gets its own local default, not the host's"
            }
        }
    }

    # ---- R2: player array indexed at [0] ---------------------------------
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $code = Remove-Comment $lines[$i]
        if ($code -notmatch '\[\s*0\s*\]') { continue }
        $m = [regex]::Matches($code, '(get_players\s*\(\s*\)|\b(?:a_)?players|level\.players)\s*\[\s*0\s*\]')
        foreach ($hit in $m) {
            Add-Finding 'R2' $rel ($i + 1) $hit.Value `
                "'$($hit.Value)' is not the host and is not 'the player' - use gethostplayer() or iterate"
        }
    }

    # ---- R3: connect loop that parks on one player's spawn ---------------
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $code = Remove-Comment $lines[$i]
        if ($code -notmatch 'waittill\s*\(\s*"connected"\s*,\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*\)') { continue }
        $var = $Matches[1]
        $last = [Math]::Min($i + 8, $lines.Count - 1)
        for ($j = $i + 1; $j -le $last; $j++) {
            $c2 = Remove-Comment $lines[$j]
            if ($c2 -match ('\b' + [regex]::Escape($var) + '\s+waittill\s*\(\s*"spawned_player"')) {
                Add-Finding 'R3' $rel ($i + 1) "connected+spawned_player" `
                    "connect loop parks on '$var' spawning (line $($j+1)) - notifies raised meanwhile are lost, so players 3-4 are never served"
                break
            }
        }
    }

    # ---- R4: setdvar() inside a per-player thread -------------------------
    foreach ($blk in (Get-FunctionBlocks $lines)) {
        $bodyText = ($blk.Body | ForEach-Object { Remove-Comment $_ }) -join "`n"
        if ($bodyText -notmatch 'self\s+endon\s*\(\s*"disconnect"') { continue }
        $sd = [regex]::Matches($bodyText, 'setdvar\s*\(\s*"([^"]+)"')
        foreach ($hit in $sd) {
            Add-Finding 'R4' $rel $blk.Start "$($blk.Name):$($hit.Groups[1].Value)" `
                "per-player thread '$($blk.Name)()' writes global dvar '$($hit.Groups[1].Value)' - last player to act wins for everybody"
        }
    }

    # ---- R5 (INFO): server-scope hudelems ---------------------------------
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $code = Remove-Comment $lines[$i]
        if ($code -match '\bnewhudelem\s*\(\s*\)|\bcreateserverfontstring\s*\(|\bcreateservericon\s*\(') {
            $serverHudCount++
            $null = $info.Add("R5  $rel`:$($i+1)  $($code.Trim())")
        }
    }
}

# ---- R6 (INFO): survival-location initial-spawn margin --------------------
# Arguments contain vector literals - (1024, -32, 8) - so commas and parens
# cannot be counted naively. Walk the call and count TOP-LEVEL commas only.
function Get-CallArgCount {
    param($Text, $OpenParenIndex)
    $depth = 0
    $commas = 0
    $sawArg = $false
    for ($i = $OpenParenIndex; $i -lt $Text.Length; $i++) {
        $ch = $Text[$i]
        if ($ch -eq '(') { $depth++; continue }
        if ($ch -eq ')') {
            $depth--
            if ($depth -eq 0) { if ($sawArg) { return $commas + 1 } else { return 0 } }
            continue
        }
        if ($depth -eq 1) {
            if ($ch -eq ',') { $commas++ }
            elseif (-not [char]::IsWhiteSpace($ch)) { $sawArg = $true }
        }
    }
    return -1   # unbalanced
}

$locDir = Join-Path $Root 'scripts\zm\locs'
if (Test-Path $locDir) {
    foreach ($f in (Get-ChildItem $locDir -Filter *.gsc -File)) {
        # strip comments line-by-line, then join so multi-line calls survive
        $code = (Get-Content $f.FullName | ForEach-Object { Remove-Comment $_ }) -join "`n"

        $tagged = 0
        $plain  = 0
        foreach ($hit in [regex]::Matches($code, 'register_map_spawn\s*\(')) {
            $open = $code.IndexOf('(', $hit.Index)
            if ($open -lt 0) { continue }
            $n = Get-CallArgCount $code $open
            # register_map_spawn( origin, angles, zone [, team_num ] )
            if ($n -ge 4) { $tagged++ } elseif ($n -ge 1) { $plain++ }
        }

        $groups = ([regex]::Matches($code, 'register_map_spawn_group\s*\(')).Count
        if ($tagged -eq 0 -and $plain -eq 0 -and $groups -eq 0) { continue }

        # stock _zm.gsc:415-419 deletes one whole script_int side for an
        # all-allies lobby; untagged points are never filtered
        $usable = [Math]::Floor($tagged / 2) + $plain

        $verdict = 'ok'
        if ($usable -gt 0 -and $usable -le 4) { $verdict = 'NO SPARE - one rejoin falls to spawnpoints[0], inside player 1' }
        if ($usable -eq 0 -and $tagged -gt 0) { $verdict = 'CHECK - all points team-tagged, none survive?' }

        $null = $info.Add(("R6  {0}  initial-spawn: tagged={1} untagged={2} usable-after-halving={3}  respawn-groups={4}  [{5}]" -f `
            (Get-Rel $f.FullName), $tagged, $plain, $usable, $groups, $verdict))
    }
}

# --- baseline update ------------------------------------------------------
if ($UpdateBaseline) {
    $header = @(
        '# coop-gate.ps1 baseline - findings present and accepted at the time of writing.',
        '# Key format: RULE|relative\path|token   (no line numbers, so edits do not churn it)',
        '# Anything NOT in this list fails the build. Do not add entries to make a build go green.',
        "# Regenerated: $(Get-Date -Format 'yyyy-MM-dd HH:mm')",
        ''
    )
    $keys = $findings | ForEach-Object { $_.Key } | Sort-Object -Unique
    Set-Content -Path $baselinePath -Value ($header + $keys) -Encoding ASCII
    Write-Host "coop-gate: baseline written with $($keys.Count) entries -> $baselinePath"
    exit 0
}

# --- report ---------------------------------------------------------------
$new   = @($findings | Where-Object { -not $_.Known })
$known = @($findings | Where-Object { $_.Known })

if (-not $Quiet) {
    foreach ($line in $info) { Write-Host "  $line" }
    if ($info.Count) { Write-Host '' }
    Write-Host "coop-gate: server-scope hudelems: $serverHudCount  (each is ONE element shared by every player)"
    Write-Host "coop-gate: known/accepted findings: $($known.Count)"
    Write-Host ''
}

if ($new.Count -eq 0) {
    Write-Host "coop-gate: PASS - no new co-op findings"
    exit 0
}

Write-Host "coop-gate: FAIL - $($new.Count) new co-op finding(s)"
Write-Host ''
foreach ($x in ($new | Sort-Object Rule, Rel, Line)) {
    Write-Host ("  [{0}] {1}:{2}" -f $x.Rule, $x.Rel, $x.Line)
    Write-Host ("        {0}" -f $x.Message)
}
Write-Host ''
Write-Host 'If one of these is genuinely correct, say why in the source and then run:'
Write-Host '    powershell -NoProfile -File tools\coop-gate.ps1 -UpdateBaseline'
exit 1
