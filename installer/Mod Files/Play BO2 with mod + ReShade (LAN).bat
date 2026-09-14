@echo off
rem ============================================================================
rem  Quality of Life Series - one-click LAN launch, Black Ops II, mod + ReShade
rem
rem  Added 2026-08-26. Same as "Play BO2 with mod (LAN).bat" but also starts
rem  the ReShade watchdog in its own window first, so ReShade is being
rem  restored the moment Plutonium opens. Leave that second window running
rem  for as long as you're playing. LAN / offline only this session.
rem
rem  Needs the installer's "The mod" AND "ReShade" options to have been run
rem  at least once first ("Windows Install.bat" is one folder up).
rem ============================================================================

chcp 65001 >nul 2>&1
title Quality of Life Series - Black Ops II LAN launch + ReShade
cd /d "%~dp0"

set "PS1=%~dp0lan-launch.ps1"

if not exist "%PS1%" (
  echo.
  echo   lan-launch.ps1 is missing from this folder.
  echo   Unzip the whole download and keep the folders as they came,
  echo   then run this again.
  echo.
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" -Watchdog %*
if errorlevel 1 pause
exit /b 0
