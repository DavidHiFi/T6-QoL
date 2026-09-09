@echo off
REM ============================================================
REM  Quality Of Life  -  BUILD & DEPLOY
REM ------------------------------------------------------------
REM  Display name lives in mod.json ("Quality Of Life"); the folder / mod id
REM  stays zm_qol because that is what Plutonium keys the install off.
REM  Edit any script under scripts\zm\ then double-click this.
REM  Rebuilds mod.iwd and writes all 5 mod files to:
REM    1) a send-ready copy:  <project>\build\zm_qol\
REM    2) your Plutonium mods folder (skipped if Plutonium isn't installed)
REM    3) installer\Mod Files\ - so the installer can never reinstall a stale
REM       build over a fresh one (see [6/9]'s comment for why this exists)
REM  Use build.bat offline to pack and verify without deployment or global cleanup.
REM  Needs only Windows + PowerShell (both built in) - no other tools.
REM ============================================================
setlocal EnableExtensions
cd /d "%~dp0"
set "MOD_NAME=zm_qol"
set "OFFLINE="
if /I "%~1"=="offline" set "OFFLINE=1"
REM  v1.99.55 - FIVE files, not six. deathmachine_zm.all.sabl is gone: its 18
REM  aliases and all 11 of its audio payloads were already inside mod.all, so it
REM  was a duplicate download for every player. The authoritative alias rows
REM  (Pan, Duck and RandomizeType - the three fields the inherited mod.all copies
REM  had lost) now live in soundbank\mod.all.aliases.additions.csv.
REM  See zone_source\mod_base.zone for the evidence that it was a duplicate.
set "FILES=mod.ff mod.iwd mod.json mod.all.sabl mod.all.sabs"

REM  OPTFILES is now EMPTY, and cmn_root.all.sabl is deliberately not in it.
REM
REM  The premise was that shipping a stock bank FILE next to the mod would make
REM  Plutonium load the mod's copy. It does not. console_zm.log prints the full
REM  path and MD5 of every bank it opens, and across three separate attempts -
REM  mods\zm_qol\, mods\zm_qol\sound\, storage\t6\sound\ and storage\t6\raw\sound\ -
REM  it loaded the game's own copy every single time:
REM
REM    SOUND Header load success for F:\...\Black Ops II\sound\cmn_root.all.sabl
REM
REM  The rule the log actually shows is ownership, not search order: a bank comes
REM  from the folder of the ZONE THAT DECLARED IT. mod.all and deathmachine_zm.all
REM  load from the mod folder because mod_base.zone declares them; every stock
REM  bank name loads from the game's sound\ folder and nothing else is consulted.
REM  Declaring a stock bank in our zone is the fatal "Attempting to override
REM  asset ... from zone 'mod'" COM_ERROR that made Origins unbootable in v1.21.0.
REM
REM  So there is no mod-contained route for replacement weapon audio, and copying
REM  267 MB into the mod folder on every build achieved nothing. Replacing the
REM  file in the game's own sound\ folder is the only thing that works, and that
REM  is a change to the game install, not to this mod.
set "OPTFILES="
set "STAMP_FILES=%FILES%"

REM --- find PowerShell (fall back to the full system path if not on PATH) ---
set "PS=powershell.exe"
where powershell.exe >nul 2>nul || set "PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if /I not "%PS%"=="powershell.exe" if not exist "%PS%" (
    color C & echo. & echo   PowerShell was not found on this PC - cannot build. & pause & exit /b 1
)

REM --- pack_iwd.ps1 must sit next to this .bat ---
if not exist "%~dp0pack_iwd.ps1" (
    color C & echo. & echo   pack_iwd.ps1 is missing next to build.bat - cannot build. & pause & exit /b 1
)

REM --- resolve the project root (parent of this folder) for the send-ready copy ---
for %%I in ("%~dp0..") do set "ROOT=%%~fI"
set "BUILD_DIR=%ROOT%\build\%MOD_NAME%"
set "PLUTO_DIR=%LOCALAPPDATA%\Plutonium\storage\t6\mods\%MOD_NAME%"

set "PROJ_DIR0=%~dp0"
REM --- PRE-FLIGHT: raw weapon files must stay under 20,480 bytes ---------------
REM  Plutonium's runtime loader reads a raw weapons\zm\ file into a fixed buffer
REM  and REFUSES anything at or above 20480 bytes (0x5000). The failure is a one-
REM  line 'Failed to load weapon X' in console_zm.log and NOTHING else - until a
REM  client script include_weapon()s that name for the box, at which point
REM  addzombieboxweapon() looks up a model on a weapon def that does not exist and
REM  the game takes an access violation mid-load. That is the Origins crash of
REM  2026-08-30 (saiga12qol_zm at 20,642 bytes).
REM
REM  Measured, not assumed: on that boot 47 files up to 20,380 bytes loaded and
REM  every file from 20,494 up failed, with no counterexample; and BO2-Reimagined
REM  ships 208 raw weapon files whose largest is 20,475 - five bytes under.
REM
REM  The six names below are over the limit ON PURPOSE. They have never loaded and
REM  that is harmless: every map that puts those guns in the box supplies its own
REM  def from its own fastfile (verified against zm_transit/highrise/buried/nuked/
REM  prison/tomb .ff), so the mod's copy is never the only source. Making them load
REM  would give the mod's copy ownership instead - an unverified behaviour change,
REM  not a fix.
REM
REM  If a NEW name shows up here, trim it rather than adding it to the list: the
REM  24 attachWorldModelOffset{Pitch,Yaw,Roll}1-8 fields are '0' on every gun in
REM  this project, Reimagined's own working files omit them, and dropping them
REM  saves exactly 720 bytes.
set "WPN_OK="
echo [0/9] Pre-flight: raw weapon file size ceiling (20480 bytes)...
"%PS%" -NoProfile -ExecutionPolicy Bypass -Command "$d=Join-Path $env:PROJ_DIR0 'weapons\zm'; if(-not (Test-Path -LiteralPath $d)){ Write-Host '    [skip] no weapons\zm folder'; exit 0 }; $ok=$env:WPN_OK -split ' '; $bad=@(); Get-ChildItem -LiteralPath $d -File | ForEach-Object { if($_.Length -ge 20480){ if($ok -contains $_.Name){ Write-Host ('    [known] ' + $_.Name + ' ' + $_.Length + ' B - over the limit on purpose, the map supplies its own') } else { $bad += ($_.Name + ' ' + $_.Length + ' B'); Write-Host ('    [OVER]  ' + $_.Name + ' ' + $_.Length + ' B') } } }; if($bad.Count -gt 0){ Write-Host ''; Write-Host '    This weapon will NOT load and will crash the game if a .csc include_weapon()s'; Write-Host '    it for the box. Trim it below 20480 before building.'; exit 1 }; Write-Host '    [ok] every raw weapon file is under the ceiling'"
if errorlevel 1 goto wpnfail

REM  v2.11.8 (user, 2026-09-04): the nine camo_zmb_dlc2* textures are NEVER copied into
REM  images\ (= mod.iwd). They are the ZM Dark Matter animated Pack-a-Punch camo, and
REM  they are delivered ONLY as loose by-name files in %LOCALAPPDATA%\Plutonium\storage\r
REM  t6\images (the HD Texture Pack / Optionals\images). zone_assets\images keeps
REM  Treyarch's own 512x512 copies purely so the Linker can build mod.ff's image
REM  headers; a fastfile carries no pixels, so nothing in the mod's five files can
REM  override the pack, and nothing in mod.iwd can shadow it either.
echo [1/9] Syncing zone_assets\images -^> images (runtime pixel data)...
REM  T6 keeps image PIXEL DATA in a loose .iwi, not in the fastfile. mod.ff only
REM  carries the material and an image header. An image that is linked but whose
REM  .iwi never reaches mod.iwd draws BLACK - that was the black Diner loading
REM  screen. zone_assets\images\ is the link-time source; images\ is what
REM  pack_iwd.ps1 packs. Copying one to the other here keeps them from drifting.
set "PROJ_DIR=%~dp0"
REM  Keep to PowerShell 2.0-era cmdlets here - build.bat falls back to the system
REM  WindowsPowerShell, which on this machine has no Get-FileHash (that is 4.0+).
REM  These are a handful of small files, so copy unconditionally rather than diff.
"%PS%" -NoProfile -ExecutionPolicy Bypass -Command "$proj=$env:PROJ_DIR; $src=Join-Path $proj 'zone_assets\images'; $dst=Join-Path $proj 'images'; if(-not (Test-Path -LiteralPath $src)){ Write-Host '    [skip] no zone_assets\images folder'; exit 0 }; if(-not (Test-Path -LiteralPath $dst)){ New-Item -ItemType Directory -Path $dst | Out-Null }; $n=0; Get-ChildItem -LiteralPath $src -Filter *.iwi | Where-Object { $_.Name -notmatch 'camo_zmb_dlc2' } | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $dst $_.Name) -Force; $n++ }; Write-Host ('    [ok] ' + $n + ' .iwi copied to images\')"
if errorlevel 1 goto packfail

echo.
echo [2/9] Repacking mod.iwd from raw folders...
"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0pack_iwd.ps1"
if errorlevel 1 goto packfail

echo.
echo [3/9] Verifying all 5 source files are present...
for %%F in (%FILES%) do (
    if exist "%~dp0%%F" ( echo    [ok] %%F ) else ( echo    [MISSING] %%F & goto missing )
)

echo.
if defined OFFLINE ( echo Offline package verified. No deployment performed. & exit /b 0 )

echo [4/9] Writing send-ready copy to:
echo        %BUILD_DIR%
call :deploy "%BUILD_DIR%"
if errorlevel 1 goto copyfail

echo.
echo [5/9] Installing to Plutonium (skipped if not installed):
echo        %PLUTO_DIR%
call :deploy "%PLUTO_DIR%"
if errorlevel 1 echo    [skip] couldn't write to Plutonium - the send-ready copy above is still good.
echo.
echo [6/9] Refreshing the installer's own bundled copy:
echo        %~dp0installer\Mod Files
REM  ============================================================================
REM  🛑 v2.3.2 - THE INSTALLER WAS SILENTLY REVERTING EVERY FIX.
REM
REM  User, 2026-08-25: a claymore fix (and the last-zombie hellhound backstop)
REM  built and deployed here, byte-verified in Plutonium's mods folder, then
REM  came back MISSING after they used the installer for something unrelated
REM  (testing the ReShade watchdog). Root cause, measured not guessed:
REM  qol-installer.ps1's Act-InstallMod copies the 5 mod files FROM ITS OWN
REM  FOLDER (installer\Mod Files\, via Find-ModSource) INTO Plutonium's mods
REM  folder. That folder held a snapshot from an earlier real-install test,
REM  never touched by this script - so any later run of "Install/Update the
REM  mod" (or "EVERYTHING") quietly reinstalled OLD code over a fresh build,
REM  and the hash of the reverted files matched that stale snapshot exactly.
REM
REM  So this bundled copy is now a THIRD deploy target, kept in lockstep with
REM  the other two on every build - it can no longer go stale between here and
REM  the next time someone runs the installer. Not tracked in git (see
REM  .gitignore): it is a byte-for-byte copy of files already tracked at the
REM  project root, and doubling ~115 MB of binaries in history for a copy this
REM  script regenerates every run buys nothing.
REM  ============================================================================
call :deploy "%~dp0installer\Mod Files"
if errorlevel 1 echo    [skip] couldn't write the installer's bundled copy.
echo.
echo [7/9] Cleaning this mod's LUI out of Plutonium's raw\ folder...
REM  ============================================================================
REM  🛑 v2.2.0 - THIS STEP USED TO *WRITE* INTO raw\. IT NOW UNDOES THAT.
REM
REM  User, 2026-08-21, with a screenshot: "I loaded a completely seperate mod
REM  from my quality of life mod and some of the stuff from my mod was showing
REM  up for some reason, tested multiple mods as well... I also removed the mod
REM  with the installer and tried loading up a mod and it still had my mods'
REM  options there."
REM
REM  storage\t6\raw\ is GLOBAL. It is not per-mod, every mod reads it, no-mod
REM  reads it, and uninstalling zm_qol never touched it. Copying this project's
REM  optionssettings.lua / privategamelobby_project.lua / selectmaplistzombie.lua
REM  in there put this mod's tabs, rows and start locations in front of every
REM  other mod on the machine, permanently.
REM
REM  🌟 AND THE SYNC WAS NEVER NEEDED. The old comment here claimed the frontend
REM  menus load at BOOT before any mod is on the search path, so they could not
REM  be delivered any other way. Only the first half of that is true. Measured
REM  out of console_zm.log.006, verbatim line numbers:
REM        523  Loaded menu file: ui_mp/t6/hud/class.lua           <- boot
REM        524  Loaded menu file: ui/t6/menus/optionssettings.lua  <- boot
REM        700  loadmod: loaded mods/zm_qol
REM        729  Loading fastfile mod
REM        786  Loaded menu file: ui/t6/mainlobby.lua              <- AGAIN
REM        789  Loaded menu file: ui/t6/menus/optionssettings.lua  <- AGAIN
REM        792  Loaded menu file: ui_mp/t6/menus/privategamelobby_project.lua
REM        793  Loaded menu file: ui_mp/t6/zombie/selectmaplistzombie.lua
REM  LUI reloads the frontend menus AFTER a mod loads, and the search path
REM  printed right after loadmod is mod.iwd (1), the mod folder (2), raw (3). So
REM  mod.iwd's copy wins on its own - exactly the reason class.lua has never
REM  needed this step.
REM
REM  WHAT THIS STEP DOES NOW, per file this project ships under ui\ or ui_mp\:
REM    - if raw holds a copy that CONTAINS THE STRING "zm_qol" - i.e. one of
REM      ours, from any build - restore the pristine Plutonium file from its
REM      .bak-* sibling if one exists, otherwise LEAVE IT ALONE and say so.
REM      A BYTE-COMPARE IS NOT GOOD ENOUGH and the first attempt used one: the
REM      moment this project edits one of these files the stale copy in raw\
REM      stops matching and becomes invisible to the clean-up forever.
REM      Plutonium own files carry no such string - checked against every
REM      .bak-* in raw and against its mainlobby.lua.
REM    - never delete a raw\ file with no backup: Plutonium's own copy of
REM      selectmaplistzombie.lua was overwritten before any backup was taken, and
REM      deleting it would leave every other mod with no map picker at all. The
REM      in-file ZmQolModLoaded() gate is what makes such a leftover behave.
REM  ============================================================================
set "RAW_DIR=%LOCALAPPDATA%\Plutonium\storage\t6\raw"
set "PROJ_DIR=%~dp0"
"%PS%" -NoProfile -ExecutionPolicy Bypass -Command "$raw=$env:RAW_DIR; $proj=$env:PROJ_DIR; if(-not (Test-Path -LiteralPath $raw)){ Write-Host '    [skip] no raw\ folder'; exit 0 }; $restored=0; $left=0; @('ui_mp','ui') | ForEach-Object { Get-ChildItem -LiteralPath (Join-Path $proj $_) -Recurse -Filter *.lua -ErrorAction SilentlyContinue } | ForEach-Object { $rel=$_.FullName.Substring($proj.Length); $dst=Join-Path $raw $rel; if(-not (Test-Path -LiteralPath $dst)){ return }; $body=(Get-Content -LiteralPath $dst -Raw); if($body -eq $null -or -not ($body -match 'zm_qol')){ return }; $bak=@(Get-ChildItem -LiteralPath (Split-Path $dst -Parent) -Filter ((Split-Path $dst -Leaf) + '.bak-*') -ErrorAction SilentlyContinue | Sort-Object LastWriteTime); if($bak.Count -gt 0){ Copy-Item -LiteralPath $bak[0].FullName -Destination $dst -Force; Write-Host ('    [restored] ' + $rel + '  <- ' + $bak[0].Name); $restored++ } else { Copy-Item -LiteralPath $_.FullName -Destination $dst -Force; Write-Host ('    [gated] ' + $rel + '  no pristine backup - refreshed to the mod-aware copy'); $left++ } }; if($restored -eq 0 -and $left -eq 0){ Write-Host '    [ok] raw\ holds none of this mod''s LUI' }" 2>nul
echo.
echo [8/9] Reconciling Plutonium's loose scripts\ folder...
REM  🛑 THIS ONE COST SIX BOOTS AND FOUR CRASHES, 2026-08-11.
REM
REM  %%LOCALAPPDATA%%\Plutonium\storage\t6\scripts\ is loaded GLOBALLY and takes
REM  precedence over the .gsc packed in mod.iwd - exactly like raw\ does for
REM  .lua in step [6/6]. Something (the BO2 Mod Manager's Deploy button is the
REM  likely candidate) had left 46 loose copies of this mod's scripts there.
REM  They were HOURS stale, so every script fix deployed into mod.iwd was
REM  silently ignored: a bisect dvar that "did nothing", a set of deleted files
REM  that kept throwing their compile error, and a crash point that never moved
REM  no matter what was changed.
REM
REM  Two rules, and the difference matters:
REM    - a loose script that ALSO exists in this project is REFRESHED, so it can
REM      never be older than what was just packed
REM    - an unmatched loose script is reported and preserved. Its folder alone
REM      does not establish ownership; it may belong to another mod.
set "LOOSE_DIR=%LOCALAPPDATA%\Plutonium\storage\t6\scripts"
"%PS%" -NoProfile -ExecutionPolicy Bypass -Command "$loose=$env:LOOSE_DIR; $proj=$env:PROJ_DIR; if(-not (Test-Path -LiteralPath $loose)){ Write-Host '    [skip] no loose scripts\ folder'; exit 0 }; $s=0; $d=0; Get-ChildItem -LiteralPath $loose -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in '.gsc','.csc' } | ForEach-Object { $rel=$_.FullName.Substring($loose.Length+1); $src=Join-Path (Join-Path $proj 'scripts') $rel; if(Test-Path -LiteralPath $src){ Copy-Item -LiteralPath $src -Destination $_.FullName -Force; $s++ } elseif($rel -like 'zm\*'){ Write-Host ('    [review] unmatched loose script preserved: ' + $rel); $d++ } }; Write-Host ('    ' + $s + ' refreshed, ' + $d + ' unmatched preserved')" 2>nul

echo.
echo [9/9] Quarantining FOREIGN scripts in Plutonium's raw\ folder...
REM  ============================================================================
REM  🛑 THIS IS WHAT KILLED DIE RISE ON 2026-09-04 (ERROR_CATALOGUE 65).
REM
REM  %%LOCALAPPDATA%%\Plutonium\storage\t6\raw\ is loaded GLOBALLY, for EVERY mod,
REM  whatever fs_game says. Another mod - Zombies Declassified / dlc5 - installs 60
REM  files there when it launches: 57 zzz_*.gsc written for BO1 maps (23 of them
REM  run for(;;) + wait 0.05 loops), a full replacement clientscripts\mp\zombies\
REM  _zm.csc, and two stock dog animscripts. They then load on top of THIS mod.
REM
REM  Measured: the 10:07 and 11:04 sessions loaded 0 of them and Die Rise was fine;
REM  the 11:45 session loaded all 60 and died with
REM  CL_CGameNeedsServerCommand: EXE_ERR_RELIABLE_CYCLED_OUT.
REM
REM  So every build parks them. NOTHING IS DELETED - they move, whole, into
REM  backups\raw-foreign-parked\, which carries RESTORE-for-dlc5.ps1 to put them
REM  back before playing that mod. Plutonium's OWN two ranked.gsc stay put.
REM  ============================================================================
set "PARK_DIR=%LOCALAPPDATA%\Plutonium\storage\t6\backups\raw-foreign-parked"
"%PS%" -NoProfile -ExecutionPolicy Bypass -Command "$raw=$env:RAW_DIR; $park=$env:PARK_DIR; if(-not (Test-Path -LiteralPath $raw)){ Write-Host '    [skip] no raw\ folder'; exit 0 }; $keep=@('scripts\mp\ranked.gsc','scripts\zm\ranked.gsc'); $n=0; $conflicts=0; Get-ChildItem -LiteralPath $raw -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in '.gsc','.csc' } | ForEach-Object { $rel=$_.FullName.Substring($raw.Length+1); if($keep -contains $rel){ return }; $dst=Join-Path $park $rel; $dir=Split-Path $dst -Parent; if(-not (Test-Path -LiteralPath $dir)){ New-Item -ItemType Directory -Force $dir | Out-Null }; if(Test-Path -LiteralPath $dst){ Write-Host ('    [review] quarantine already exists; source preserved: ' + $rel); $conflicts++; return }; Move-Item -LiteralPath $_.FullName -Destination $dst -ErrorAction Stop; Write-Host ('    [parked] ' + $rel); $n++ }; if($n -eq 0 -and $conflicts -eq 0){ Write-Host '    [ok] raw\ holds no foreign script' } else { Write-Host ('    ' + $n + ' foreign script(s) parked in backups\raw-foreign-parked - run its RESTORE-for-dlc5.ps1 before playing that mod') }" 2>nul

echo.
echo Done.
echo   Launch Plutonium T6 ^> Zombies ^> Mods ^> %MOD_NAME%
echo.
pause
exit /b 0

REM ---- copy all 5 files to %1, confirm each landed, stamp build time ----
:deploy
set "DEST=%~1"
if not exist "%DEST%" mkdir "%DEST%" 2>nul
if not exist "%DEST%" ( echo    [FAILED] could not create the folder & exit /b 1 )
REM  v2.11.13 - CHECK THE COPY, NOT JUST THAT SOMETHING IS THERE.
REM  `if exist` passes on the STALE file the copy failed to overwrite, so a
REM  deploy over a running game printed [ok] for a file it never wrote:
REM  Plutonium holds mod.all.sabs open while it plays, and only that one
REM  silently kept the previous build. Measured 2026-09-04. copy sets
REM  errorlevel 1 when the target is locked, so test that first.
for %%F in (%FILES%) do (
    copy /Y "%~dp0%%F" "%DEST%\%%F" >nul 2>nul || ( echo    [FAILED] %%F - in use by another process, close the game and build again & exit /b 1 )
    if exist "%DEST%\%%F" ( echo    [ok] %%F ) else ( echo    [FAILED] %%F & exit /b 1 )
)
REM optional banks: copy when present, stay silent when not
for %%F in (%OPTFILES%) do (
    if exist "%~dp0%%F" (
        copy /Y "%~dp0%%F" "%DEST%\%%F" >nul 2>nul
        if exist "%DEST%\%%F" ( echo    [ok] %%F ^(optional^) ) else ( echo    [FAILED] %%F & exit /b 1 )
    )
)
REM stamp all 5 with the current time - paths passed via env vars so any
REM username/path (spaces, apostrophes, etc.) is safe
set "STAMP_DIR=%DEST%"
"%PS%" -NoProfile -ExecutionPolicy Bypass -Command "$t=Get-Date; foreach($f in $env:STAMP_FILES.Split(' ')){ $p=Join-Path $env:STAMP_DIR $f; if(Test-Path -LiteralPath $p){ (Get-Item -LiteralPath $p).LastWriteTime=$t } }" 2>nul
exit /b 0

:packfail
color C
echo.
echo   FAILED to pack mod.iwd (see the PowerShell error above).
if not defined OFFLINE pause
exit /b 1

:wpnfail
echo.
echo   BUILD STOPPED: a raw weapon file is at or over the 20480-byte ceiling.
echo   Drop its 24 attachWorldModelOffset{Pitch,Yaw,Roll}1-8 fields (all '0') to
echo   save 720 bytes, then build again.
if not defined OFFLINE pause
exit /b 1

:missing
color C
echo.
echo   A required mod file is missing from this folder - cannot build.
echo   Expected: %FILES%
if not defined OFFLINE pause
exit /b 1

:copyfail
color C
echo.
echo   Could not write the send-ready copy (permissions or disk full?).
if not defined OFFLINE pause
exit /b 1
