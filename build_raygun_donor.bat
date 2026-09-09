@echo off
REM ============================================================================
REM  build_raygun_donor.bat  -  rebuilds zone_source\raygun_donor\mod.ff
REM
REM  WHY THIS EXISTS
REM    BO2 has two different Ray Gun meshes under the same asset names. Buried
REM    and Origins carry Treyarch's remade model (17422 verts) with the new
REM    mtl_t6_wpn_zmb_raygun_col/_nml/_spc textures and an ember _glow material.
REM    Green Run, Die Rise, Nuketown AND Mob of the Dead all carry the older
REM    17899-vert mesh drawing the Black Ops 1 textures (~-gray_gun, ray_gun_n).
REM
REM    build_ff.bat loads zm_prison.ff 4th and zm_buried.ff 11th, and the Linker
REM    is FIRST-LOAD-WINS with no override flag, so mod.ff baked MOB's copies -
REM    verified by dumping the shipped mod.ff and diffing the model's material
REM    list against zm_prison.ff's and zm_buried.ff's.
REM
REM    Loading this tiny fastfile ahead of zm_prison.ff is the only lever the
REM    Linker offers. It carries the four Ray Gun models and their dependency
REM    chain and nothing else, so no other shared asset can shift.
REM
REM  RUN THIS BEFORE build_ff.bat WHENEVER THE RAY GUN ART IS TOUCHED.
REM ============================================================================
setlocal
set "PROJ=%~dp0"
set "OAT=%PROJ%..\..\..\tools\oat-windows"
set "BO2=F:\SteamLibrary\steamapps\common\Call of Duty Black Ops II"
if not exist "%OAT%\Linker.exe" ( echo ERROR: Linker.exe not found. & exit /b 1 )
set "TMPSRC=%TEMP%\zmqol_raygun_src"
if not exist "%TMPSRC%" mkdir "%TMPSRC%"
copy /y "%PROJ%zone_source\raygun_donor\mod.zone.source" "%TMPSRC%\mod.zone" >nul
"%OAT%\Linker.exe" ^
  --load "%BO2%\zone\all\zm_buried.ff" ^
  --base-folder "%TMPSRC%" ^
  --add-source-search-path "%TMPSRC%" ^
  --output-folder "%TMPSRC%\out" ^
  mod
if errorlevel 1 ( echo ERROR: link failed. & exit /b 1 )
if not exist "%TMPSRC%\out\mod.ff" ( echo ERROR: no mod.ff produced. & exit /b 1 )
copy /y "%TMPSRC%\out\mod.ff" "%PROJ%zone_source\raygun_donor\mod.ff" >nul
echo   raygun donor rebuilt. Now run build_ff.bat.
