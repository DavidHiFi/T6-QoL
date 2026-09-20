@echo off
rem ============================================================================
rem  Quality Of Life - ReShade watchdog launcher
rem
rem  Added 2026-08-26. Double-click this INSTEAD OF opening Plutonium directly
rem  when you want ReShade active. Leave the window it opens running for as
rem  long as you're playing - Plutonium wipes ReShade out of its own folder
rem  every time it starts, and this is what puts it back. Then start Plutonium
rem  and play as normal; you do not need to do anything else here.
rem
rem  Closing this window does not uninstall anything - it just stops watching.
rem
rem  Needs the installer's ReShade option to have been run at least once
rem  ("Windows Install.bat", one folder up -> ReShade). If it hasn't, this
rem  will say so.
rem ============================================================================

chcp 65001 >nul 2>&1
title Quality Of Life - ReShade watchdog
cd /d "%~dp0"

set "PS1=%~dp0reshade-watchdog.ps1"
set "VERIFY=%~dp0reshade-verify.ps1"

if not exist "%PS1%" (
  echo.
  echo   reshade-watchdog.ps1 is missing from this folder.
  echo   Unzip the whole download and keep the folders as they came,
  echo   then run this again.
  echo.
  pause
  exit /b 1
)

rem  Check and repair BEFORE the watchdog starts watching. The watchdog restores
rem  from the vault and only ever checked that the vault existed, so a vault with
rem  no shaders in it left it reporting "bin is intact" for a whole session while
rem  ReShade ran with no effects at all (user, 2026-09-21).
if exist "%VERIFY%" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%VERIFY%"
  if errorlevel 1 (
    echo.
    echo   ReShade could not be verified - see the message above.
    echo   Starting the watchdog anyway, but effects may not load.
    echo.
    pause
  )
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %*
if errorlevel 1 pause
exit /b 0
