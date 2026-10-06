<#
    check-lui-guard.ps1  -  the LUI event guard must ship in both of its files.

    WHY THIS EXISTS
    ---------------
    The guard was written once, lived only as uncommitted work in one worktree,
    and was missing from every build until 2026-10-02. Without it, a menu event
    handler that throws ends the UI VM:
        LUI_ERROR: Error processing event: process_events
    and the game needs a full quit.

    The guard is one block of Lua, carried identically by two files:
      ui\t6\codroot.lua    the engine requires it at boot, before the mod is
                           mounted, so this copy only acts if it is re-required
      ui\t6\mainlobby.lua  reloaded after loadmod; this copy normally installs it
    Losing either file, or letting the two copies drift, loses the guard with no
    error message.

    WHAT IT CHECKS
    --------------
      1. both files exist and each holds exactly one guard block
      2. the two blocks are identical
      3. the block still pcalls the handler, preserves return values, gates on
         fs_game, re-points ProcessEventNow and logs the install marker
      4. codroot.lua still defines the stock CoDRoot functions around it
      5. -PostPack: mod.iwd carries both files, byte-identical to the source

    EXIT CODES
    ----------
      0  the guard is intact
      1  it is missing, partial or out of sync  (do not build)
#>

[CmdletBinding()]
param(
    [switch] $PostPack
)

$ErrorActionPreference = 'Stop'
$proj = Split-Path -Parent $PSScriptRoot
$fail = @()
$note = @()

$begin = '-- zm_qol LUI EVENT GUARD BEGIN'
$end   = '-- zm_qol LUI EVENT GUARD END'
$files = @('ui/t6/codroot.lua', 'ui/t6/mainlobby.lua')

$required = @(
    @{ text = 'pcall(LUI.UIElement.processEvent, Root, Event)';               why = 'the handler is no longer dispatched inside pcall' },
    @{ text = 'pcall(Root.propagateEvent, Root, Event)';                      why = 'event propagation is no longer guarded' },
    @{ text = 'return Finish(Event, pcall(';                                  why = 'handler results are no longer returned through Finish' },
    @{ text = 'return ...';                                                   why = 'successful handlers no longer return all their values' },
    @{ text = 'Engine.PIXEndEvent()';                                         why = 'the PIX scope is no longer closed after a failure' },
    @{ text = 'if not ZmQolLuiGuardModActive() then';                         why = 'the guard no longer steps aside under another mod' },
    @{ text = 'LUI.CoDRoot.ZmQolGuardDispatch == nil';                        why = 'repeat runs could wrap the dispatcher twice' },
    @{ text = 'LUI.CoDRoot.ProcessEventNow = LUI.CoDRoot.ZmQolGuardDispatch'; why = 'ProcessEventNow is no longer replaced' },
    @{ text = '[zm_qol] LUI GUARD: event ';                                   why = 'caught failures are no longer logged' },
    @{ text = '[zm_qol] LUI event guard installed';                           why = 'the install marker is gone' }
)

function Get-GuardBlock([string] $text, [string] $label) {
    $text = $text.Replace("`r`n", "`n")
    $first = $text.IndexOf($begin)
    if ($first -lt 0) { $script:fail += "$label has no guard block"; return $null }
    if ($text.IndexOf($begin, $first + 1) -ge 0) { $script:fail += "$label has more than one guard block"; return $null }
    $last = $text.IndexOf($end, $first)
    if ($last -lt 0) { $script:fail += "$label guard block has no end marker"; return $null }
    return $text.Substring($first, $last + $end.Length - $first)
}

function Test-GuardFiles([hashtable] $texts, [string] $where) {
    $blocks = @{}
    foreach ($f in $files) {
        if (-not $texts.ContainsKey($f)) { $script:fail += "$where is missing $f"; continue }
        $b = Get-GuardBlock $texts[$f] "$where $f"
        if ($b -eq $null) { continue }
        $blocks[$f] = $b
        foreach ($r in $required) {
            if (-not $b.Contains($r.text)) { $script:fail += "$where $f`: $($r.why) (missing: $($r.text))" }
        }
    }
    if ($blocks.Count -eq 2 -and $blocks[$files[0]] -ne $blocks[$files[1]]) {
        $script:fail += "$where`: the guard blocks in codroot.lua and mainlobby.lua differ"
    }
    if ($texts.ContainsKey($files[0])) {
        foreach ($fn in @('ProcessEvent', 'ProcessEvents', 'ProcessEventNow', 'PropagateEventToPrimaryRoot', 'CloseAll', 'new')) {
            if (-not $texts[$files[0]].Contains("LUI.CoDRoot.$fn = function")) {
                $script:fail += "$where codroot.lua no longer defines the stock LUI.CoDRoot.$fn"
            }
        }
    }
}

# --- 1-4. the source tree ----------------------------------------------------
$srcBytes = @{}
$srcTexts = @{}
foreach ($f in $files) {
    $p = Join-Path $proj ($f.Replace('/', '\'))
    if (Test-Path -LiteralPath $p) {
        $srcBytes[$f] = [IO.File]::ReadAllBytes($p)
        $srcTexts[$f] = [Text.Encoding]::UTF8.GetString($srcBytes[$f])
    }
}
Test-GuardFiles $srcTexts 'source'

# --- 5. the built archive ----------------------------------------------------
if ($PostPack) {
    $iwd = Join-Path $proj 'mod.iwd'
    if (-not (Test-Path -LiteralPath $iwd)) {
        $fail += 'mod.iwd not found - cannot prove the guard shipped'
    } else {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $packed = @{}
        $packedBytes = @{}
        $zip = [IO.Compression.ZipFile]::OpenRead($iwd)
        try {
            foreach ($e in $zip.Entries) {
                if ($files -contains $e.FullName) {
                    $s = $e.Open()
                    try {
                        $ms = New-Object IO.MemoryStream
                        $s.CopyTo($ms)
                        $packedBytes[$e.FullName] = $ms.ToArray()
                        $packed[$e.FullName] = [Text.Encoding]::UTF8.GetString($packedBytes[$e.FullName])
                    } finally { $s.Dispose() }
                }
            }
        } finally { $zip.Dispose() }
        Test-GuardFiles $packed 'mod.iwd'
        foreach ($f in $files) {
            if ($packedBytes.ContainsKey($f) -and $srcBytes.ContainsKey($f)) {
                if ([Convert]::ToBase64String($packedBytes[$f]) -ne [Convert]::ToBase64String($srcBytes[$f])) {
                    $fail += "mod.iwd $f differs from the source file - repack"
                }
            }
        }
        if ($fail.Count -eq 0) { $note += 'mod.iwd carries both guard files, identical to the source' }
    }
}

# --- report ------------------------------------------------------------------
if ($fail.Count -gt 0) {
    Write-Host ''
    Write-Host '    [BROKEN] the LUI event guard is not intact:' -ForegroundColor Red
    foreach ($f in $fail) { Write-Host "      - $f" -ForegroundColor Red }
    Write-Host ''
    Write-Host '    Without it a throwing menu handler ends the UI with' -ForegroundColor Yellow
    Write-Host '    "LUI_ERROR: Error processing event: process_events". Restore the block in' -ForegroundColor Yellow
    Write-Host '    both files; see the header of ui\t6\codroot.lua.' -ForegroundColor Yellow
    Write-Host ''
    exit 1
}

foreach ($n in $note) { Write-Host "    [ok] $n" }
Write-Host '    [ok] LUI event guard present and identical in codroot.lua and mainlobby.lua'
exit 0
