@echo off
title RENEarn - Zombie Tsunami Interactive PC Edition
color 0b

echo ===============================================================================
echo        RENEarn • ZOMBIE TSUNAMI INTERACTIVE PC EDITION
echo ===============================================================================
echo.
echo  [1/2] Checking RENEarn Server Status...

powershell -NoProfile -Command "Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue" | find "8080" >nul
if "%ERRORLEVEL%"=="0" (
    echo       RENEarn Server is already active and listening on port 8080!
) else (
    echo       Starting RENEarn Studio Background Services...
    if exist "%~dp0core\server.ps1" (
        start "RENEarn Server" /min powershell.exe -NoProfile -ExecutionPolicy Bypass -NoExit -File "%~dp0core\server.ps1"
    ) else if exist "%~dp0..\core\server.ps1" (
        start "RENEarn Server" /min powershell.exe -NoProfile -ExecutionPolicy Bypass -NoExit -File "%~dp0..\core\server.ps1"
    ) else (
        start "RENEarn Server" /min powershell.exe -NoProfile -ExecutionPolicy Bypass -NoExit -File "%~dp0server.ps1"
    )
    timeout /t 3 >nul
)

echo.
echo  [2/2] Launching Zombie Tsunami Interactive PC Game...
echo.

REM Try launching as a clean native window app using Edge or Chrome
start msedge.exe --app="http://localhost:8080/zombie-tsunami.html" --window-size=1280,720 2>nul
if "%ERRORLEVEL%" NEQ "0" (
    start http://localhost:8080/zombie-tsunami.html
)

echo ===============================================================================
echo   GAME IS RUNNING AND CONNECTED TO LIVE STREAM!
echo.
echo   * Controls:
echo       - [SPACEBAR] or Left Click : Jump
echo       - Hold [SPACEBAR]          : Higher Jump
echo.
echo   * Viewer / Gift Commands:
echo       - 🌹 Rose / 1 Coin         : +1 Zombie to Horde
echo       - 🌹 Combo x5              : +5 Zombie Rush
echo       - 🌊 Whale / Galaxy        : Mega Tsunami Tidal Wave!
echo       - 🍩 Doughnut / Heart      : Giant Laser Mecha Zombie!
echo       - 🛸 UFO                   : Alien UFO Clone Drops
echo       - 🪙 Gold                  : Gold Rush Mode (10x Coins)
echo       - !jump                    : Horde Jump
echo.
echo   * OBS / TikTok LIVE Studio Browser Source URL:
echo       http://localhost:8080/zombie-tsunami.html
echo.
echo   Tip: You can use the buttons at the bottom of the game window
echo        to test every command right now without any live stream delay!
echo ===============================================================================
echo.
pause
