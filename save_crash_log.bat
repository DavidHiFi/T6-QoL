@echo off
REM ============================================================================
REM  save_crash_log.bat  -  grab the Plutonium Zombies console log AFTER a crash
REM ----------------------------------------------------------------------------
REM  RUN THIS BEFORE RELAUNCHING THE GAME.
REM
REM  Plutonium truncates console_zm.log and starts a fresh one every time the
REM  game launches, so relaunching destroys the record of a crash.
REM
REM  NOTE: the first version of this file used WMIC for the timestamp. WMIC has
REM  been removed from recent Windows 11 builds, so it silently produced nothing.
REM  It now uses PowerShell, which is always present.
REM ============================================================================
setlocal

set "SRC=%LOCALAPPDATA%\Plutonium\storage\t6\main\console_zm.log"
REM  Crash logs are DEV data, not mod source, so they go to the sibling dev
REM  folder and stay out of the repo (moved there 2026-08-20).
set "DSTDIR=%~dp0..\zm_qol - dev\crashlogs"

if not exist "%SRC%" (
    echo.
    echo   Could not find the log at:
    echo     %SRC%
    echo.
    pause
    exit /b 1
)

if not exist "%DSTDIR%" mkdir "%DSTDIR%"

for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm-ss"') do set "STAMP=%%I"
if not defined STAMP set "STAMP=nodate"

copy /Y "%SRC%" "%DSTDIR%\console_zm_%STAMP%.log" >nul
if errorlevel 1 (
    echo   COPY FAILED - is the game still running and holding the file?
    pause
    exit /b 1
)

echo.
echo   Saved:  crashlogs\console_zm_%STAMP%.log

copy /Y "%LOCALAPPDATA%\Plutonium\storage\t6\mods\zm_qol\games_mp.log" "%DSTDIR%\games_mp_%STAMP%.log" >nul 2>&1
if exist "%DSTDIR%\games_mp_%STAMP%.log" echo   Saved:  crashlogs\games_mp_%STAMP%.log

echo.
dir /b "%DSTDIR%"
echo.
pause
