@echo off
REM ============================================================================
REM  build_metalstorm.bat  -  rebuilds zone_source\metalstorm_donor\mod.ff
REM
REM  WHY THIS EXISTS
REM    The Storm PSR (internal name "metalstorm_mms") is a CAMPAIGN weapon. Its
REM    package ships as zone\all\weapons!metalstorm_mms_sp.ff, which is part of
REM    the SINGLE-PLAYER install - and this machine's Black Ops II has only the
REM    multiplayer/zombies half. Measured 2026-09-06 across all 226 files in
REM    retail's zone\all: the ONLY storm assets present anywhere are
REM        la_1b.ff    t6_wpn_special_storm_world + the storm materials/images
REM        frontend.ff menu_mp_weapons_metalstorm (the HUD / box icon)
REM    The VIEW model (t6_wpn_special_storm_view_sp), all 24 viewmodel_storm_*
REM    anims, the five mstorm_* tracers and the sound ALIAS TABLE
REM    (soundbank wpn_metalstormsnp.all) are in NO retail fastfile at all.
REM
REM    BO2-Reimagined ships that campaign fastfile in its own repo, and
REM    CLAUDE.md overrides the no-import rule for BO2-Reimagined specifically,
REM    so it is the legitimate - and only - source here.
REM
REM  WHY IT IS RE-LINKED INSTEAD OF LOADED DIRECTLY
REM    build_ff.bat runs under EnableDelayedExpansion, and cmd eats a '!' inside
REM    a quoted argument there - the donor's real filename has one. Renaming is
REM    not an option: a T6 fastfile's internal zone name must match its filename
REM    or OAT fails with "inflate of stream N failed: invalid block type" (see
REM    build_ff.bat's header). Re-linking it to a plain mod.ff in its own folder
REM    is the same shape every other donor in this project already uses.
REM
REM  🛑 THE SOUNDS ARE NOT COPIED AND MUST NOT BE. The soundbank asset carried
REM  here is only the ALIAS TABLE. All 35 audio payloads it names already live in
REM  cmn_root.all.sabl - verified 2026-09-06 by hashing every FileSource with the
REM  engine's own snd_id and finding 35/35, in BOTH retail's copy and the user's
REM  custom sound-pack copy. cmn_root loads on every map, so the gun is audible
REM  with ZERO rows added to mod.all, and the user's pack keeps winning.
REM ============================================================================
setlocal
set "PROJ=%~dp0"
set "OAT=%PROJ%..\..\..\tools\oat-windows"
set "BO2=F:\SteamLibrary\steamapps\common\Call of Duty Black Ops II"
set "SRCFF=%PROJ%..\..\reference\BO2-Reimagined\zone\all\weapons!metalstorm_mms_sp.ff"

if not exist "%OAT%\Linker.exe" ( echo   ERROR: Linker.exe not found. & exit /b 1 )
if not exist "%SRCFF%" ( echo   ERROR: donor fastfile not found: "%SRCFF%" & exit /b 1 )

set "TMPSRC=%TEMP%\zmqol_metalstorm_src"
if not exist "%TMPSRC%" mkdir "%TMPSRC%"
copy /y "%PROJ%zone_source\metalstorm_donor\mod.zone.source" "%TMPSRC%\mod.zone" >nul

echo   Linking the Storm PSR donor...
"%OAT%\Linker.exe" ^
  --load "%SRCFF%" ^
  --load "%BO2%\zone\all\common_zm.ff" ^
  --load "%BO2%\zone\all\patch_zm.ff" ^
  --load "%BO2%\zone\all\common_mp.ff" ^
  --load "%BO2%\zone\all\code_post_gfx.ff" ^
  --load "%BO2%\zone\all\code_post_gfx_mp.ff" ^
  --base-folder "%TMPSRC%" ^
  --add-source-search-path "%TMPSRC%" ^
  --output-folder "%TMPSRC%\out" ^
  mod
if errorlevel 1 ( echo   ERROR: link failed. & exit /b 1 )
if not exist "%TMPSRC%\out\mod.ff" ( echo   ERROR: no mod.ff produced. & exit /b 1 )

copy /y "%TMPSRC%\out\mod.ff" "%PROJ%zone_source\metalstorm_donor\mod.ff" >nul
echo   Storm PSR donor rebuilt. Now run build_ff.bat.
exit /b 0
