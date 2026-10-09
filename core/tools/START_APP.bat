@echo off
title PvZ Fusion 4.0 Stream Studio
color 0a

echo ===============================================================================
echo                PvZ Fusion 4.0 - LIVE STREAM STUDIO
echo ===============================================================================
echo.
echo  [1/4] Closing previous server sessions...
powershell -NoProfile -Command "Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like '*server.ps1*' -or $_.CommandLine -like '*tiktok_bridge.js*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }"

ping 127.0.0.1 -n 2 >nul

echo  [2/4] Checking Plants vs Zombies Fusion 4.0 game...
tasklist /FI "IMAGENAME eq PlantsVsZombiesRH.exe" 2>NUL | find /I /N "PlantsVsZombiesRH.exe">NUL
if "%ERRORLEVEL%"=="1" (
    echo       PvZ Fusion not running. Launching game now...
    start "" "C:\Users\pc\Desktop\games ko to ya\Game Files\PlantsVsZombiesRH.exe"
    echo       Game launched!
) else (
    echo       PvZ Fusion is already running!
)

ping 127.0.0.1 -n 2 >nul

echo  [3/4] Starting PvZ Fusion Live Server (Port 8080)...
start "PvZ Fusion Live Server" powershell.exe -NoProfile -ExecutionPolicy Bypass -NoExit -File "%~dp0server.ps1"

ping 127.0.0.1 -n 3 >nul

echo  [4/4] Launching Control Studio Dashboard...
start http://localhost:8080/app.html

echo.
echo ===============================================================================
echo   SUCCESS! The Stream Control Studio is now running!
echo.
echo   * Control Dashboard    : http://localhost:8080/app.html
echo   * TikTok LIVE Overlay  : http://localhost:8080/overlay.html
echo   * Stream Overlay       : http://localhost:8080/stream-overlay.html
echo.
echo   Spawns are queued when in-game match is active!
echo   Keep the server window open while playing ^& streaming!
echo ===============================================================================
echo.
pause
