@echo off
setlocal EnableDelayedExpansion
REM ============================================================================
REM  build_octagonal_map.bat  -  relinks zm_octagonal.ff and octagonal.iwd.
REM ----------------------------------------------------------------------------
REM  Run this only when zone_source\octagonal_map\zm_octagonal.zone changes, and
REM  ALWAYS after build_ff.bat - the map zone is generated against the current
REM  mod.ff, and a stale pairing is a COM_ERROR on load.
REM
REM  WHY THE MAP HAS ITS OWN FASTFILE AT ALL
REM
REM  Octagonal Ascension ships standalone, so the 1.2beta release's mod.ff
REM  carries everything the map needs to run - mystery box, window barriers,
REM  perk machines, 35 weapons, the Hellhound chain, the player models. That is
REM  correct for a mod that only ever loads with its own map.
REM
REM  🔴 v2.17.1 PASTED IT INTO zm_qol's SHARED mod.ff AND ORIGINS STOPPED BOOTING:
REM
REM      COM_ERROR: Attempting to override asset 'zmcore_basicwoodbarrier'
REM                 from zone 'mod' with zone 'zm_tomb'
REM
REM  mod.ff loads ahead of every stock map zone, so every one of those 2,687
REM  assets was a name the map zones had to fight over. zm_octagonal.ff only
REM  loads when this map loads, so the same assets are harmless in it.
REM  zone_ownership_gate.py is what stops that regressing.
REM
REM  🛑 THIS NEEDS THE 1.2beta SOURCE CAPTURE, WHICH IS NOT IN THIS REPO.
REM  It is ~440 MB: the .d3dbsp, the map's raw images and the author's own
REM  custom-map build of OpenAssetTools. Retail OAT CANNOT build this zone - it
REM  rejects a >custom_map,T6 fastfile with "Loaded fastfile has an invalid
REM  signature" on read-back. Capture and provenance:
REM      modding-jobs\octagonal-ascension-001\README.md
REM  Point OCT_SRC at it, or drop it in the default path below.
REM
REM  📝 Two artefacts the Linker cannot produce on its own, both handled here:
REM     - maps\mp\zm_octagonal.d3dbsp.paths, the pathnode connectivity blob.
REM       linker.exe knows nothing about .paths files, and the map crashes on
REM       load without it, so it is injected into octagonal.iwd afterwards.
REM     - the frontend half of the route (map card, signpost, loading screens,
REM       the two UI tables) is NOT here. It is in mod.ff, declared by
REM       zone_source\mod_custom_maps.zone, because the menu needs it before
REM       any map has loaded.
REM ============================================================================

set "PROJ=%~dp0"
if "%PROJ:~-1%"=="\" set "PROJ=%PROJ:~0,-1%"

if not defined OCT_SRC set "OCT_SRC=H:\Plutonium\modding-jobs\octagonal-ascension-001\source\zm_octagonal"
if not defined BO2_DIR set "BO2_DIR=F:\SteamLibrary\steamapps\common\Call of Duty Black Ops II"

set "OCT_OAT=%OCT_SRC%\OpenAssetTools"
set "OCT_MAP=%OCT_SRC%\zm_octagonal"
set "OCT_MOD=%OCT_SRC%\mod"

if not exist "%OCT_OAT%\linker.exe" (
    echo   ERROR: the 1.2beta source capture is not at "%OCT_SRC%".
    echo          Set OCT_SRC to it and re-run. See the header of this file.
    exit /b 1
)
if not exist "%OCT_MOD%\zone\mod.ff" (
    echo   ERROR: "%OCT_MOD%\zone\mod.ff" is missing - it is the donor every
    echo          payload asset resolves from.
    exit /b 1
)
if not exist "%PROJ%\mod.ff" (
    echo   ERROR: mod.ff is missing. Run build_ff.bat first - the map zone is
    echo          generated against it and loads it as a dependency.
    exit /b 1
)
if not exist "%PROJ%\zone_source\octagonal_map\zm_octagonal.zone" (
    echo   ERROR: zone_source\octagonal_map\zm_octagonal.zone is missing.
    echo          Regenerate it with make_octagonal_map_zone.py.
    exit /b 1
)

set "OCT_OUT=%PROJ%\zone_out_octagonal"
if exist "%OCT_OUT%" rmdir /s /q "%OCT_OUT%"
mkdir "%OCT_OUT%"

echo.
echo [1/3] Linking zm_octagonal.ff ...
REM  --load ORDER, same rule as build_ff.bat: first loaded zone that carries real
REM  data for a name wins it. The release's own mod.ff goes first so the map gets
REM  exactly the asset copies 1.2beta shipped; zm_qol's mod.ff is next so every
REM  name it owns resolves as a reference instead of a second copy; the stock
REM  zones follow in the order the map's own build_all.cmd used.
REM  🛑 Do NOT put REM lines between the caret-continued arguments below - cmd
REM  passes them to the Linker as arguments.
pushd "%OCT_MAP%"
"%OCT_OAT%\linker.exe" -v ^
  --load "%OCT_MOD%\zone\mod.ff" ^
  --load "%PROJ%\mod.ff" ^
  --load "%BO2_DIR%\zone\all\zm_transit.ff" ^
  --load "%BO2_DIR%\zone\all\zm_prison.ff" ^
  --load "%BO2_DIR%\zone\all\zm_buried.ff" ^
  --load "%BO2_DIR%\zone\all\zm_tomb.ff" ^
  --load "%BO2_DIR%\zone\all\so_zclassic_zm_transit.ff" ^
  --load "%BO2_DIR%\zone\all\so_zsurvival_zm_transit.ff" ^
  --load "%BO2_DIR%\zone\all\common_zm.ff" ^
  --load "%BO2_DIR%\zone\all\zm_highrise.ff" ^
  --load "%BO2_DIR%\zone\all\ui_zm.ff" ^
  --load "%BO2_DIR%\zone\all\zm_nuked.ff" ^
  --load "%BO2_DIR%\zone\all\patch_zm.ff" ^
  --load "%BO2_DIR%\zone\all\dlc4_load_zm.ff" ^
  --load "%BO2_DIR%\zone\all\code_post_gfx_zm.ff" ^
  --load "%BO2_DIR%\zone\all\code_pre_gfx_zm.ff" ^
  --load "%BO2_DIR%\zone\all\dlc1_load_zm.ff" ^
  --load "%BO2_DIR%\zone\all\dlc2_load_zm.ff" ^
  --load "%BO2_DIR%\zone\all\dlc3_load_zm.ff" ^
  --load "%BO2_DIR%\zone\all\dlczm0_load_zm.ff" ^
  --load "%BO2_DIR%\zone\all\zm_transit_patch.ff" ^
  --load "%BO2_DIR%\zone\all\zm_prison_patch.ff" ^
  --load "%BO2_DIR%\zone\all\zm_buried_patch.ff" ^
  --load "%BO2_DIR%\zone\all\zm_tomb_patch.ff" ^
  --load "%BO2_DIR%\zone\all\zm_nuked_patch.ff" ^
  --load "%BO2_DIR%\zone\all\zm_highrise_patch.ff" ^
  --base-folder "%OCT_OAT%" ^
  --add-asset-search-path "%OCT_MAP%" ^
  --add-asset-search-path "%OCT_MOD%" ^
  --source-search-path "%PROJ%\zone_source\octagonal_map" ^
  --output-folder "%OCT_OUT%" ^
  zm_octagonal
set "err=%ERRORLEVEL%"
popd

if not %err% EQU 0 (
    echo   ERROR: link failed - zm_octagonal.ff NOT replaced.
    exit /b %err%
)
if not exist "%OCT_OUT%\zm_octagonal.ff" (
    echo   ERROR: Linker reported success but produced no zm_octagonal.ff.
    exit /b 1
)

echo.
echo [2/3] Injecting the pathnode blob into octagonal.iwd ...
set "PATHS=%OCT_MAP%\maps\mp\zm_octagonal.d3dbsp.paths"
if not exist "%PATHS%" (
    echo   ERROR: zm_octagonal.d3dbsp.paths is missing - the map crashes on load
    echo          without it, so this build is not shippable.
    exit /b 1
)
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; $zip=[System.IO.Compression.ZipFile]::Open('%OCT_OUT%\octagonal.iwd','Update'); $e=$zip.GetEntry('maps/mp/zm_octagonal.d3dbsp.paths'); if ($e) { $e.Delete() }; [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,'%PATHS%','maps/mp/zm_octagonal.d3dbsp.paths') | Out-Null; $zip.Dispose()"
if errorlevel 1 ( echo   ERROR: could not inject the pathnodes. & exit /b 1 )

echo.
echo [3/3] Installing ...
copy /y "%OCT_OUT%\zm_octagonal.ff" "%PROJ%\zm_octagonal.ff" >nul
copy /y "%OCT_OUT%\octagonal.iwd"   "%PROJ%\octagonal.iwd"   >nul
rmdir /s /q "%OCT_OUT%"

for %%F in ("%PROJ%\zm_octagonal.ff") do echo   zm_octagonal.ff rebuilt: %%~zF bytes
for %%F in ("%PROJ%\octagonal.iwd")   do echo   octagonal.iwd  rebuilt: %%~zF bytes
echo   Now run build.bat to package and deploy.
exit /b 0
