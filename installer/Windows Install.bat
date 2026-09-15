@echo off
rem ============================================================================
rem  Quality of Life Series Launcher - installs the Quality of Life mod for
rem  Black Ops II Zombies on Plutonium T6
rem
rem  Double-click this file. That is the whole install.
rem
rem  It opens the installer in "Mod Files\qol-installer.ps1" - a menu is not
rem  something a .bat can draw on its own. Nothing needs administrator rights,
rem  nothing is left running afterwards, and no game file is ever touched.
rem ============================================================================

chcp 65001 >nul 2>&1
title Quality of Life Series Launcher

set "PS1=%~dp0Mod Files\qol-installer.ps1"

if not exist "%PS1%" (
  echo.
  echo   The "Mod Files" folder is missing.
  echo   Unzip the whole download and keep the folders as they came,
  echo   then run this again.
  echo.
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %*
if errorlevel 1 (
  echo.
  echo   The installer stopped with an error.
  echo   See installer.log inside the "Mod Files" folder.
  echo.
  pause
)
exit /b 0
