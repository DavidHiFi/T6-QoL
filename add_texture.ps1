<#
  add_texture.ps1 - PNG -> IWI -> the RIGHT filename, first time, every time.

  WHY THIS EXISTS (2026-09-11)
  Adding lui_bkg_zm + globe_map_zm to the HD pack took three rounds instead of
  one, for two mechanical reasons - neither of them a judgement call:
    1. Both images stream out of zm.ipak, so a loose .iwi named after the image
       is silently ignored by the engine. Ipak textures must be named
       <decimal name-hash>.iwi (measured: console search path + ipak index
       parse; the "real packs ship 1111625965.iwi" convention). Nothing in the
       repo said which names need it.
    2. The converted files sat in Optionals\images but never reached the live
       storage\t6\images folder, so the booted game still drew stock. Nothing
       reminded anyone that staging != installed.
  This script does the whole chain in one go so neither step can be skipped:

    .\add_texture.ps1 -Png C:\path\lui_bkg_zm.png -Image lui_bkg_zm
    .\add_texture.ps1 -Png C:\path\lui_bkg_zm.png -Image lui_bkg_zm -Install

  WHAT IT DOES
    1. PNG -> uncompressed A8B8G8R8 .dds via png2dds.ps1 (same script, same
       format the mod's other converted textures use).
    2. .dds -> T6 .iwi via tools\oat-windows\ImageConverter.exe, then reads
       back the IWI header (magic, version 27, format, dimensions).
    3. Looks the image name up in the T6-iPak-Unpacker name database to get its
       32-bit name hash, then scans the installed game's zone\all\*.ipak index
       sections for that hash:
         - hash found in an ipak  -> installs BOTH <decimal hash>.iwi AND
           <name>.iwi (measured 2026-09-11: hash-only drew vanilla for the
           lui_bkg_zm_* layers; the by-name copy alongside cleared them);
         - hash in no ipak        -> installs <name>.iwi (the loose override
           path, e.g. menu / loadscreen art);
         - game not found / hash unknown -> installs <name>.iwi and says why:
           an uncatalogued name is not a stock texture, so by-name is the
           only thing that can work (a guessed hash would be a silent no-op).
    4. Copies into Optionals\images (the HD pack source the installer ships).
    5. With -Install: also copies into the live storage\t6\images folder and
       appends the installer manifest (installed-images.txt), so a later
       "remove the HD textures" stays accurate. The game must be RESTARTED -
       menu/world art loads at boot, a running session never picks it up.

  Nothing here touches the five mod files, build.bat, or any existing source.
  Overwriting an existing entry in Optionals\images is the normal update path
  (re-run with edited art), and is reported, not hidden.
#>
param(
    [Parameter(Mandatory = $true)][string]$Png,
    [Parameter(Mandatory = $true)][string]$Image,
    [switch]$Install,
    [string]$OutDir = '',
    [string]$Converter = '',
    [string]$NameDb = ''
)

$ErrorActionPreference = 'Stop'

$PROJ = Split-Path -Parent $MyInvocation.MyCommand.Path
$WS   = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PROJ))   # <ws>\t6\mods\zm_qol -> <ws>
if ([string]::IsNullOrWhiteSpace($OutDir))   { $OutDir   = Join-Path $PROJ 'Optionals\images' }
if ([string]::IsNullOrWhiteSpace($Converter)) { $Converter = Join-Path $WS 'tools\oat-windows\ImageConverter.exe' }
if ([string]::IsNullOrWhiteSpace($NameDb))   { $NameDb   = Join-Path $WS 'tools\T6-iPak-Unpacker\iPak_Utils\image_names.csv' }

if (-not (Test-Path -LiteralPath $Png))       { throw "PNG not found: $Png" }
if (-not (Test-Path -LiteralPath $Converter)) { throw "ImageConverter not found: $Converter" }
$png2dds = Join-Path $PROJ 'png2dds.ps1'
if (-not (Test-Path -LiteralPath $png2dds))   { throw "png2dds.ps1 not found next to this script" }
if (-not (Test-Path -LiteralPath $OutDir))    { New-Item -ItemType Directory -Force -Path $OutDir | Out-Null }

$work = Join-Path ([IO.Path]::GetTempPath()) ('addtex_' + [IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Force -Path $work | Out-Null
try {
    # --- 1+2. PNG -> DDS -> IWI ------------------------------------------------
    $dds = Join-Path $work ($Image + '.dds')
    & powershell -NoProfile -ExecutionPolicy Bypass -File $png2dds -In $Png -Out $dds
    if ($LASTEXITCODE -ne 0) { throw 'png2dds.ps1 failed (see above)' }
    & $Converter --t6 $dds
    if ($LASTEXITCODE -ne 0) { throw 'ImageConverter failed (see above)' }
    $iwi = Join-Path $work ($Image + '.iwi')
    if (-not (Test-Path -LiteralPath $iwi)) { $iwi = [IO.Path]::ChangeExtension($dds, '.iwi') }
    if (-not (Test-Path -LiteralPath $iwi)) { throw 'ImageConverter produced no .iwi (see above)' }

    # --- header check: IWi magic, T6 version 27, format + dimensions -----------
    $fs = [IO.File]::OpenRead($iwi)
    try {
        $br = New-Object IO.BinaryReader($fs)
        $h = $br.ReadBytes(12)
    } finally { $fs.Close() }
    if (!($h[0] -eq 0x49 -and $h[1] -eq 0x57 -and $h[2] -eq 0x69)) { throw 'output is not an IWI file' }
    if ($h[3] -ne 27) { throw ("unexpected IWI version " + $h[3] + ', expected 27 (T6)') }
    $fmt = $h[4]
    $w = [BitConverter]::ToUInt16($h, 6); $hh = [BitConverter]::ToUInt16($h, 8)
    $len = (Get-Item -LiteralPath $iwi).Length
    Write-Host ("  [iwi] format={0} {1}x{2} {3:N0} bytes" -f $fmt, $w, $hh, $len)

    # --- 3. name hash + ipak membership ----------------------------------------
    # The CSV's first column is the hex name hash (no 0x), e.g. 1F61FBC9.
    [uint32]$hash = 0
    $haveHash = $false
    if (Test-Path -LiteralPath $NameDb) {
        foreach ($line in [IO.File]::ReadLines($NameDb)) {
            $c = $line.Split(',')
            if ($c.Count -ge 2 -and $c[1].Trim() -ieq $Image) {
                $haveHash = [uint32]::TryParse($c[0].Trim(),
                    [Globalization.NumberStyles]::HexNumber, $null, [ref]$hash)
                break
            }
        }
    } else { Write-Host '  [warn] name database not found - cannot resolve a hash' }

    # Game path: Plutonium's own config first (same source lan-launch.ps1 uses),
    # then the common Steam location. No game -> no ipak scan -> install both.
    $gameZone = $null
    try {
        $cfg = Join-Path $env:LOCALAPPDATA 'Plutonium\config.json'
        if (Test-Path -LiteralPath $cfg) {
            $m = [regex]::Match((Get-Content -LiteralPath $cfg -Raw), '"t6Path"\s*:\s*"([^"]+)"')
            if ($m.Success) { $gameZone = Join-Path $m.Groups[1].Value 'zone\all' }
        }
    } catch { }
    if ((-not $gameZone -or -not (Test-Path -LiteralPath $gameZone)) -and (Test-Path -LiteralPath 'F:\SteamLibrary\steamapps\common\Call of Duty Black Ops II\zone\all')) {
        $gameZone = 'F:\SteamLibrary\steamapps\common\Call of Duty Black Ops II\zone\all'
    }

    # Ipak layout (see T6-iPak-Unpacker pc_ipak.cpp): 16-byte header
    # {KAPI, version, size, section_count}, 16-byte sections
    # {type, offset, size, item_count}, type 1 = index of 16-byte entries
    # {data_hash, name_hash, offset, physical_size}. Index-only reads: fast.
    $inIpak = @()
    if ($haveHash -and $gameZone -and (Test-Path -LiteralPath $gameZone)) {
        foreach ($ipak in @(Get-ChildItem -LiteralPath $gameZone -Filter '*.ipak' -ErrorAction SilentlyContinue)) {
            $s = [IO.File]::OpenRead($ipak.FullName)
            try {
                $br = New-Object IO.BinaryReader($s)
                $magic = [Text.Encoding]::ASCII.GetString($br.ReadBytes(4))
                if ($magic -ne 'KAPI') { continue }
                $br.ReadUInt32() | Out-Null; $br.ReadUInt32() | Out-Null
                $nsec = $br.ReadUInt32()
                if ($nsec -eq 0 -or $nsec -gt 64) { continue }
                $idxOff = 0; $idxCnt = 0
                for ($i = 0; $i -lt $nsec; $i++) {
                    $t = $br.ReadUInt32(); $o = $br.ReadUInt32()
                    $br.ReadUInt32() | Out-Null; $c = $br.ReadUInt32()
                    if ($t -eq 1) { $idxOff = $o; $idxCnt = $c }
                }
                if ($idxOff -eq 0 -or $idxCnt -eq 0 -or $idxCnt -gt 2000000) { continue }
                $s.Seek($idxOff, [IO.SeekOrigin]::Begin) | Out-Null
                for ($i = 0; $i -lt $idxCnt; $i++) {
                    $br.ReadUInt32() | Out-Null
                    if ($br.ReadUInt32() -eq $hash) { $inIpak += $ipak.Name; break }
                    $br.ReadUInt32() | Out-Null; $br.ReadUInt32() | Out-Null
                }
            } finally { $s.Close() }
        }
    }

    $names = @()
    if ($inIpak.Count -gt 0) {
        # 2026-09-11, measured in game: hash-only is NOT enough. Seven
        # lui_bkg_zm_* layers installed hash-only drew vanilla; adding the
        # by-name copy alongside and rebooting cleared them (see
        # modding-jobs\lui-bkg-verify-001\menu-now.png vs
        # menu-byname-test.png). Install BOTH names so either lookup hits it.
        $names = @((([string][uint32]$hash) + '.iwi'), ($Image + '.iwi'))
        Write-Host ("  [name] ipak-streamed ({0}) -> dual name {1} + {2}" -f ($inIpak -join ', '), $names[0], $names[1])
    } elseif ($haveHash -and $gameZone) {
        $names = @($Image + '.iwi')
        Write-Host ('  [name] in no ipak -> by-name file {0}' -f $names[0])
    } else {
        # Unknown to the 32k-name database, so it is not a stock streamed
        # texture either (those are all catalogued) - a by-name file is the
        # only thing that can work. Flag it so a silent no-op stays visible.
        $names = @($Image + '.iwi')
        Write-Host ("  [warn] '{0}' is in no name database - staged by-name; if the game still draws stock, it needs its hash looked up" -f $Image)
    }

    # --- 4. stage into the HD pack source ---------------------------------------
    foreach ($n in $names) {
        $dst = Join-Path $OutDir $n
        $verb = 'wrote'
        if (Test-Path -LiteralPath $dst) { $verb = 'updated' }
        Copy-Item -LiteralPath $iwi -Destination $dst -Force
        Write-Host ("  [{0}] {1}" -f $verb, $dst)
    }

    # --- 5. live install + manifest ----------------------------------------------
    if ($Install) {
        $live = Join-Path $env:LOCALAPPDATA 'Plutonium\storage\t6\images'
        if (-not (Test-Path -LiteralPath $live)) { New-Item -ItemType Directory -Force -Path $live | Out-Null }
        foreach ($n in $names) {
            Copy-Item -LiteralPath (Join-Path $OutDir $n) -Destination (Join-Path $live $n) -Force
            Write-Host ("  [live] {0}" -f (Join-Path $live $n))
        }
        $man = Join-Path $env:LOCALAPPDATA 'Plutonium\storage\t6\_zm_qol_installer\installed-images.txt'
        if (Test-Path -LiteralPath $man) {
            $have = @{}
            foreach ($l in (Get-Content -LiteralPath $man)) { $have[$l.Trim().ToLower()] = $true }
            $add = @($names | Where-Object { -not $have.ContainsKey($_.ToLower()) })
            if ($add.Count -gt 0) {
                Add-Content -LiteralPath $man -Value $add
                Write-Host ("  [manifest] appended {0}" -f ($add -join ', '))
            } else { Write-Host '  [manifest] already listed' }
        } else { Write-Host '  [warn] installer manifest not found - live files copied but untracked' }
        Write-Host '  RESTART the game - art loads at boot, a running session never picks it up.'
    } else {
        Write-Host '  staged only (no -Install): run the HD pack installer or re-run with -Install to put it live.'
    }
} finally {
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}
