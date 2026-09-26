# ============================================================
#  pack_iwd.ps1  -  builds mod.iwd from the raw source folders
# ------------------------------------------------------------
#  Pure .NET - needs only Windows + .NET 4.5+ (built into Win 8+).
#  Produces a spec-compliant ZIP (forward-slash paths) so Plutonium
#  T6 reads the raw script paths correctly. Called by build.bat.
# ============================================================
param(
    [string]$Root = $PSScriptRoot,
    [string]$Out  = "mod.iwd"
)

$ErrorActionPreference = 'Stop'

# Load .NET compression (ZipArchive). Clear message if it isn't available.
try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    Add-Type -AssemblyName System.IO.Compression
}
catch {
    Write-Output "  ERROR: .NET compression is unavailable (needs Windows 8+ / .NET 4.5+)."
    exit 1
}

try {
    # 'character' holds stock scripts the GAME fails to ship in every gametype's
    # fastfile set - see character\c_buried_player_reporter_dam.gsc for the case
    # that made this necessary (Buried survival could not load without it).
    # 'ui' is the OTHER LUI root. T6 resolves a "T6.Menus.X" require against both
    # ui\ and ui_mp\ - stock keeps privateonlinegamelobby.lua under ui\ and
    # privategamelobby_project.lua under ui_mp\ - so a mod that overrides a ui\
    # file needs that folder packed too, or the override never reaches the game.
    # 'fx' carries the wonder weapons' 63 raw .efx. OpenAssetTools cannot read or
    # write FxEffectDef, so they can never enter mod.ff - Plutonium loads them
    # straight out of mod.iwd at runtime.
    #
    # 🌟 ALL 60 ARE BYTE-IDENTICAL TO Wonder_Weapons-T6ZM\wonder_wepons_zm\mod.iwd,
    # a SHIPPED WORKING BUILD. Do not hand-edit them, and in particular DO NOT
    # CHANGE THEIR LINE ENDINGS.
    #
    # 🛑 v1.97.0 - THIS COMMENT USED TO CLAIM BYTE-IDENTITY WHILE 35 OF THE 60
    # WERE CRLF-CORRUPTED, AND THAT CLAIM IS WHY IT WENT UNNOTICED FOR SEVEN
    # VERSIONS. v1.70.0 ("the wonder-weapon crash was LF line endings") compared
    # our copies against Wonder_Weapons-T6ZM\src\fx\ - the WORKING COPY of a git
    # clone whose core.autocrlf is true, so git had rewritten every one of them
    # LF -> CRLF on checkout. The file that actually ships in that mod, and the
    # blob git stores, are LF:
    #
    #     src\fx\...\fx_freezegun_view.efx  (checkout)  49451 bytes, 2676 CR
    #     git show HEAD:src/fx/.../same file            46775 bytes,    0 CR
    #     wonder_wepons_zm\mod.iwd  (the working build) 46775 bytes,    0 CR
    #     ours, v1.70.0 - v1.96.0                       49451 bytes, 2676 CR
    #
    # So v1.70.0 converted all of ours to match a checkout artefact. T6 parses
    # .efx as text; the muzzle flash, the smoke cloud and 33 others have been
    # parsing wrong ever since, which is the Winter's Howl "wrong firing fx" the
    # user reported on 2026-08-16. All 60 are now restored from the shipped
    # mod.iwd and verified 60/60 identical to it.
    #
    # .gitattributes sets `* -text`, so a checkout of THIS repo cannot re-break
    # them. Nothing in the build converts line endings either - this script
    # copies bytes through a stream.
    #
    # 📝 The other two theories of that era were also wrong and are recorded here
    # so they are not retried: substituting 22 materials (v1.71.0) did not stop
    # the crash, and the real gap was THIRTEEN TECHNIQUESETS in mod.ff, seven of
    # them effect_* / distortion_*, the shaders particles draw with. See
    # zone_source\mod_wonderweapons.zone.
    # 🛑 'images' IS DELIBERATELY NOT IN THIS LIST.  (v2.17.35, 2026-09-22)
    #
    #  It was added for one day on the theory that t6zm.exe's relative 'images/'
    #  string is handed to the normal filesystem layer, which searches .iwd
    #  archives. It is not: the mod's 1252 .iwi went in, mod.iwd went from 40 MB
    #  to 1.48 GB, and the game still drew stock fonts and stock perk icons.
    #  Textures stream from a real file handle, and a zip entry cannot give one.
    #
    #  So packing them here costs 1.4 GB on every build, every deploy and every
    #  map load and buys nothing. The pack ships in the mod's own images\ folder
    #  instead, and build.bat mirrors it into the deployed mod and points
    #  storage\t6\images at it with a junction - see the texture-pack block
    #  there. The bytes still live in the mod; only the doorway is outside it.
    #  'images_menu' (v2.17.45) - THE MAIN-MENU ART, AND WHY IT IS THE ONE
    #  TEXTURE FOLDER THAT GOES INSIDE mod.iwd.
    #
    #  User, 2026-09-23: *"i didn't have the mod loaded and i still saw them so
    #  make sure they loaded from the mod not from the images folder"*.
    #
    #  The texture pack lives loose on purpose (see the block above) and
    #  storage\t6\images is a junction into the mod's own images\ folder. That
    #  junction is GLOBAL: anything inside it applies to the stock game and to
    #  every other mod, with no mod loaded at all. Fine for the HD pack, wrong
    #  for the menu - the user has now rejected the loose route for this art
    #  twice, 2026-09-14 and 2026-09-23.
    #
    #  mod.iwd is mounted only while fs_game points at this mod, so shipping the
    #  art here is what makes it mod-gated. It is packed from images_menu\ but
    #  REWRITTEN to images/ inside the archive, because that is the path the
    #  menu looks it up under; the separate source folder is what keeps it out
    #  of the junction.
    $folders  = @('aitype','attachmentunique','character','fx','images_menu','maps','scripts','ui','ui_mp','weapons','xanim')
    # 'xanim' (v2.9.18-v2.10.13): raw xanims load from a mod's iwd the same way raw
    # weapon defs do (proven by the zm_ezz3.0 package, checkpoint 173). The Zap Gun's
    # 15 view anims shipped this way until v2.10.14, when the Wave Gun's 49 came in
    # as fastfile assets through zone_source\wavegun_donor (native T6 xanims from
    # Zombies Declassified's zm_moon.ff). The folder is empty now and skipped by the
    # Test-Path below; the entry stays so a future raw xanim needs no packer change.
    $rootPath = (Resolve-Path -LiteralPath $Root).Path.TrimEnd('\','/')
    $outPath = if ([System.IO.Path]::IsPathRooted($Out)) {
        [System.IO.Path]::GetFullPath($Out)
    } else { [System.IO.Path]::GetFullPath((Join-Path $rootPath $Out)) }
    foreach ($folder in $folders) {
        $sourcePath = (Join-Path $rootPath $folder) + [System.IO.Path]::DirectorySeparatorChar
        if ($outPath.StartsWith($sourcePath, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw 'The output must be outside the packed source folders.'
        }
    }
    # Finish and close a sibling archive before replacing the previous good build.
    # A failed build retains its partial archive for diagnosis.
    $tempPath = $outPath + '.' + [guid]::NewGuid().ToString('N') + '.partial'
    $fs  = [System.IO.File]::Open($tempPath, [System.IO.FileMode]::CreateNew)
    $zip = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Create)
    $count = 0
    try {
        foreach ($folder in $folders) {
            $folderPath = Join-Path $rootPath $folder
            if (-not (Test-Path -LiteralPath $folderPath)) { continue }
            # v2.4.2 - a `gsc-tool -m parse` check run from inside scripts\ drops a
            # decompiled byproduct copy at <cwd>\parsed\t6\<file>.gsc. It is already
            # .gitignored (build artifact, not source) but this loop doesn't consult
            # .gitignore, so one had been silently shipping inside mod.iwd since a
            # past session's parse-check - found when the file count crept from 593
            # to 594 with no new source file added. Excluded structurally so a stray
            # `parsed\` anywhere under a packed folder can never leak in again.
            Get-ChildItem -LiteralPath $folderPath -Recurse -File | Where-Object {
                $_.FullName -notmatch '\\parsed\\'
            } | Sort-Object FullName | ForEach-Object {
                # entry path relative to project root, forward slashes
                $rel   = $_.FullName.Substring($rootPath.Length + 1) -replace '\\','/'

                # images_menu\ is a SOURCE folder name only - it exists so the
                # menu art stays out of images\, and therefore out of the global
                # storage\t6\images junction. Inside the archive it has to be
                # images/, which is where the menu actually looks.
                $isMenuArt = $rel -like 'images_menu/*'
                if ($isMenuArt) { $rel = 'images/' + $rel.Substring('images_menu/'.Length) }

                # .iwi is ALREADY a compressed texture (DXT/BC blocks). Deflating it
                # again buys almost nothing and costs a great deal of time - images\
                # is ~2.1 GB since the upscaled texture pack landed, and running that
                # through Optimal turns every build into a multi-minute wait for a
                # couple of percent. Store them instead; the game reads stored and
                # deflated entries identically.
                #  ...but the menu art is the exception to the exception. Those
                #  20 files are IWI FORMAT 1 - raw RGBA, not DXT - so there are
                #  no compressed blocks to leave alone and deflate earns its
                #  keep: 65.7 MB of source collapses to a fraction of it, and
                #  mod.iwd is a download every player takes. There are 20 of
                #  them, so the build cost the comment above warns about does
                #  not apply either.
                $level = if ($_.Extension -ieq '.iwi' -and -not $isMenuArt) {
                    [System.IO.Compression.CompressionLevel]::NoCompression
                } else {
                    [System.IO.Compression.CompressionLevel]::Optimal
                }

                $entry = $zip.CreateEntry($rel, $level)
                $es    = $entry.Open()
                try {
                    $fsIn = [System.IO.File]::OpenRead($_.FullName)
                    try { $fsIn.CopyTo($es) } finally { $fsIn.Dispose() }
                } finally { $es.Dispose() }
                $count++
            }
        }
    }
    finally {
        try { if ($zip) { $zip.Dispose() } }
        finally { if ($fs) { $fs.Dispose() } }
    }

    if (Test-Path -LiteralPath $outPath) {
        [System.IO.File]::Replace($tempPath, $outPath, [System.Management.Automation.Language.NullString]::Value)
    } else { [System.IO.File]::Move($tempPath, $outPath) }

    Write-Output ("  mod.iwd packed: {0:N0} files, {1:N0} bytes" -f $count, (Get-Item -LiteralPath $outPath).Length)
    exit 0
}
catch {
    Write-Output ("  ERROR packing mod.iwd: " + $_.Exception.Message)
    exit 1
}
