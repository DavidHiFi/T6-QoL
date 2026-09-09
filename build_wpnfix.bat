@echo off
REM ============================================================================
REM  build_wpnfix.bat  -  rebuilds zone_source\wpnfix_donor\mod.ff
REM
REM  WHY THIS EXISTS
REM    zone_source\base\mod.ff (the donor) carries m1911_zm, m1911_upgraded_zm,
REM    m1911lh_upgraded_zm and c96_zm whose fire aliases are wpn_m1911_* and
REM    wpn_mc96_* - names that exist in NO Black Ops II sound bank, ZM or MP.
REM    The guns were therefore silent. Retail's own copies name wpn_1911_*,
REM    which every map bank declares and which the user's sound pack replaces.
REM
REM    The Linker is FIRST-LOAD-WINS and has no override flag, so a raw source
REM    file cannot beat the donor. Plutonium's runtime raw-weapon loader cannot
REM    either - it refuses a name mod.ff already owns ("Failed to load weapon").
REM    The only route is to supply the name from a zone loaded AHEAD of the
REM    donor, which is what this tiny fastfile does.
REM
REM    Measured safe: 326 assets, ZERO overlap with anything zm_qol's own zones
REM    declare and ZERO overlap with its raw sources in zone_assets\.
REM ============================================================================
setlocal
set "PROJ=%~dp0"
set "OAT=%PROJ%..\..\..\tools\oat-windows"
set "BO2=F:\SteamLibrary\steamapps\common\Call of Duty Black Ops II"
if not exist "%OAT%\Linker.exe" ( echo ERROR: Linker.exe not found. & exit /b 1 )
set "TMPSRC=%TEMP%\zmqol_wpnfix_src"
if not exist "%TMPSRC%" mkdir "%TMPSRC%"
copy /y "%PROJ%zone_source\wpnfix_donor\mod.zone.source" "%TMPSRC%\mod.zone" >nul
"%OAT%\Linker.exe" ^
  --load "%BO2%\zone\all\zm_nuked.ff" ^
  --load "%BO2%\zone\all\zm_tomb.ff" ^
  --base-folder "%TMPSRC%" ^
  --add-source-search-path "%TMPSRC%" ^
  --output-folder "%TMPSRC%\out" ^
  mod
if errorlevel 1 ( echo ERROR: link failed. & exit /b 1 )
if not exist "%TMPSRC%\out\mod.ff" ( echo ERROR: no mod.ff produced. & exit /b 1 )
copy /y "%TMPSRC%\out\mod.ff" "%PROJ%zone_source\wpnfix_donor\mod.ff" >nul
echo   wpnfix donor rebuilt. Now run build_ff.bat.
