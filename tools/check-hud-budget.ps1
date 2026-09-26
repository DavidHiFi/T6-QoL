# check-hud-budget.ps1 - the client HUD slot budget, enforced on every build.
#
# The engine sends a client at most 31 archived (.archived = 1, the default) and
# 31 non-archived (.archived = 0) hudelems per snapshot, walking the server pool
# in slot order, and silently never draws the rest (HudElem_UpdateClient, 2013
# PC server PDB; the same 0x1F caps are in the live r5346 t6zm image). No error,
# no log line, and the script handle stays valid, so nothing at runtime can see
# it happen. On 2026-09-25 a fresh TranZit spawn measured archived 30/31, and
# stock's buildable bar drew only its fill while subtitles came and went.
#
# tools\hud-budget.json lists every place the mod creates a HUD element. This
# fails the build when:
#   - a creation site in scripts\ or maps\ is not in the table,
#   - a site the table puts in the "current" group lost its .archived = 0,
#   - a site the table puts in the "archived" group sets .archived = 0,
#   - either group's standing total would eat stock's reserve,
#   - a forbid / require rule (a regression the table exists to stop) trips.
param([string]$Root)

$ErrorActionPreference = 'Stop'

if (-not $Root) { $Root = Join-Path $PSScriptRoot '..' }
$Root = (Resolve-Path -LiteralPath $Root).Path
$table = Get-Content -LiteralPath (Join-Path $Root 'tools\hud-budget.json') -Raw | ConvertFrom-Json

$failures = New-Object System.Collections.Generic.List[string]
$creators = 'newclienthudelem|newhudelem|newteamhudelem|newdamageindicatorhudelem|createfontstring|createserverfontstring|createicon|createservericon|createprimaryprogressbar|createbar'
$createRx = [regex]::new("^\s*(?<var>[A-Za-z_][\w\.\[\]]*)\s*=\s*(?:[A-Za-z_]\w*\s+)?(?:[\w\\]+::)?(?<fn>$creators)\s*\(", 'IgnoreCase')
$anyRx    = [regex]::new("\b(?:$creators)\s*\(", 'IgnoreCase')
$defRx    = [regex]::new('^(?<name>[A-Za-z_]\w*)\s*\([^;]*\)\s*$')

# file -> list of @{ name; start; end; lines }
$bodies = @{}
function Get-Bodies([string]$rel) {
    if ($bodies.ContainsKey($rel)) { return $bodies[$rel] }
    $lines = [IO.File]::ReadAllLines((Join-Path $Root $rel))
    $list = New-Object System.Collections.Generic.List[object]
    $cur = $null
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $m = $defRx.Match($lines[$i])
        if ($m.Success -and $m.Groups['name'].Value -notmatch '^(if|while|for|foreach|switch|return|else)$') {
            if ($cur) { $cur.end = $i - 1; $list.Add($cur) }
            $cur = [pscustomobject]@{ name = $m.Groups['name'].Value; start = $i; end = $lines.Length - 1; lines = $lines }
        }
    }
    if ($cur) { $list.Add($cur) }
    $bodies[$rel] = $list
    return $list
}
function Get-Body([string]$rel, [string]$fn) {
    foreach ($b in (Get-Bodies $rel)) { if ($b.name -eq $fn) { return $b } }
    return $null
}
function Get-Code([object]$b) {
    # the function's lines with // comments removed, so a banner that talks
    # about ".archived = 0" can never satisfy or trip a rule
    $out = New-Object System.Collections.Generic.List[string]
    for ($i = $b.start; $i -le $b.end; $i++) {
        $l = $b.lines[$i]
        $c = $l.IndexOf('//')
        if ($c -ge 0) { $l = $l.Substring(0, $c) }
        $out.Add($l)
    }
    return ,$out
}

# ---- 1. every creation site is in the table, in the group the table says ----
$sites = @($table.sites)
$files = Get-ChildItem -LiteralPath (Join-Path $Root 'scripts'), (Join-Path $Root 'maps') -Recurse -Filter '*.gsc' -ErrorAction SilentlyContinue
$found = 0
foreach ($f in $files) {
    $rel = $f.FullName.Substring($Root.Length).TrimStart('\').Replace('\', '/')
    $lines = [IO.File]::ReadAllLines($f.FullName)
    $inBlock = $false
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i]
        if ($inBlock) { if ($line -match '\*/') { $inBlock = $false }; continue }
        if ($line -match '^\s*/\*' -and $line -notmatch '\*/') { $inBlock = $true; continue }
        $code = $line
        $c = $code.IndexOf('//'); if ($c -ge 0) { $code = $code.Substring(0, $c) }
        if (-not $anyRx.IsMatch($code)) { continue }
        # a helper's own definition line (createbar( color, ... )) is not a call
        if ($defRx.IsMatch($code)) { continue }
        $fn = $null
        foreach ($b in (Get-Bodies $rel)) { if ($i -ge $b.start -and $i -le $b.end) { $fn = $b.name } }
        $m = $createRx.Match($code)
        $var = if ($m.Success) { $m.Groups['var'].Value } else { '?' }
        $found++
        $row = $sites | Where-Object { $_.file -eq $rel -and $_.function -eq $fn -and $_.var -eq $var } | Select-Object -First 1
        if (-not $row) {
            $failures.Add("${rel}:$($i + 1) $fn creates a HUD element ($var) that is not in tools\hud-budget.json. Add a row: which group, how long it lives, and check the totals still fit.")
        }
    }
}

# ---- 2. the table's groups match the code ----
foreach ($s in $sites) {
    $b = Get-Body $s.file $s.function
    if (-not $b) { $failures.Add("hud-budget.json lists $($s.file)::$($s.function) but that function no longer exists. Remove or correct the row."); continue }
    $code = (Get-Code $b) -join "`n"
    $setsCurrent = [regex]::IsMatch($code, [regex]::Escape($s.var) + '\.archived\s*=\s*0\s*;', 'IgnoreCase')
    if ($s.group -eq 'current' -and -not $setsCurrent) {
        $failures.Add("$($s.file)::$($s.function) - $($s.var) is budgeted in the NON-ARCHIVED group but no longer sets '$($s.var).archived = 0;'. Without it the element falls back into the archived group, which is the one that overflowed.")
    }
    if ($s.group -ne 'current' -and $setsCurrent) {
        $failures.Add("$($s.file)::$($s.function) - $($s.var) sets .archived = 0 but the table says '$($s.group)'. Move the row to 'current' and re-check the totals.")
    }
}

# ---- 3. regressions the budget exists to stop ----
foreach ($r in @($table.forbid)) {
    $b = Get-Body $r.file $r.function
    if (-not $b) { $failures.Add("forbid rule names $($r.file)::$($r.function), which no longer exists."); continue }
    foreach ($l in (Get-Code $b)) {
        if ([regex]::IsMatch($l, $r.pattern)) { $failures.Add("$($r.file)::$($r.function): $($r.why)"); break }
    }
}
foreach ($r in @($table.require)) {
    $b = Get-Body $r.file $r.function
    if (-not $b) { $failures.Add("require rule names $($r.file)::$($r.function), which no longer exists."); continue }
    if (-not [regex]::IsMatch(((Get-Code $b) -join "`n"), $r.pattern)) { $failures.Add("$($r.file)::$($r.function): $($r.why)") }
}

# ---- 4. the arithmetic ----
function Sum-Count($rows) { $n = 0; foreach ($x in $rows) { $n += [int]$x.count }; return $n }
$cap = [int]$table.cap
$st  = $table.stock
$curStanding  = Sum-Count ($sites | Where-Object { $_.group -eq 'current' -and ($_.life -eq 'permanent' -or $_.life -eq 'ondemand') })
$arcStanding  = Sum-Count ($sites | Where-Object { ($_.group -eq 'archived' -or $_.group -eq 'server') -and ($_.life -eq 'permanent' -or $_.life -eq 'ondemand') })
$arcTransient = 0
foreach ($x in ($sites | Where-Object { ($_.group -eq 'archived' -or $_.group -eq 'server') -and $_.life -eq 'transient' })) {
    if ([int]$x.count -gt $arcTransient) { $arcTransient = [int]$x.count }
}
$curTotal = [int]$st.current + $curStanding + [int]$st.current_reserve
$arcTotal = [int]$st.archived + $arcStanding + [int]$st.archived_reserve
$panTotal = [int]$st.archived + $arcStanding + $arcTransient + [int]$st.archived_transient_reserve

Write-Output ("    non-archived: stock {0} + mod {1} + reserve {2} = {3} / {4}" -f $st.current, $curStanding, $st.current_reserve, $curTotal, $cap)
Write-Output ("    archived:     stock {0} + mod {1} + reserve {2} = {3} / {4}" -f $st.archived, $arcStanding, $st.archived_reserve, $arcTotal, $cap)
Write-Output ("    archived with the biggest panel open: {0} + {1} + {2} + one stock bar {3} = {4} / {5}" -f $st.archived, $arcStanding, $arcTransient, $st.archived_transient_reserve, $panTotal, $cap)
if ($curTotal -gt $cap) { $failures.Add("the non-archived group is over budget: $curTotal of $cap. Something permanent has to become on-demand, or move groups.") }
if ($arcTotal -gt $cap) { $failures.Add("the archived group is over budget: $arcTotal of $cap. Stock's on-demand HUD (bench bars, revive bars) would lose elements again.") }
if ($panTotal -gt $cap) { $failures.Add("the archived group cannot hold the biggest chat panel plus one stock progress bar: $panTotal of $cap.") }
if ($found -eq 0) { $failures.Add('found no HUD creation sites at all - the scan is broken, not the mod.') }

if ($failures.Count -gt 0) {
    foreach ($x in $failures) { Write-Output "  HUD BUDGET: $x" }
    exit 1
}
Write-Output "    [ok] HUD slot budget: $found creation sites, every one budgeted, both groups inside 31"
exit 0
