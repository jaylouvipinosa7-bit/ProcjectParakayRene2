@echo off
title PvZ Fusion 4.0 Studio Launcher
color 0a

echo ===============================================================================
echo                PvZ FUSION 4.0 - INTERACTIVE STREAM STUDIO
echo ===============================================================================
echo.
echo  [1/3] Closing any previous server instances...
powershell -NoProfile -Command "Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like '*server.ps1*' -or $_.CommandLine -like '*tiktok_bridge.js*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }"

ping 127.0.0.1 -n 2 >nul

echo  [2/3] Checking Plants vs Zombies Fusion game status...
tasklist /FI "IMAGENAME eq PlantsVsZombiesRH.exe" 2>NUL | find /I /N "PlantsVsZombiesRH.exe">NUL
if "%ERRORLEVEL%"=="1" (
    echo       PvZ Fusion is not running. Attempting to start game...
    set "GAME_FOUND=0"
    if exist "%USERPROFILE%\Desktop\games ko to ya\Game Files\PlantsVsZombiesRH.exe" (
        start "" "%USERPROFILE%\Desktop\games ko to ya\Game Files\PlantsVsZombiesRH.exe"
        set "GAME_FOUND=1"
    ) else if exist "C:\Users\pc\Desktop\games ko to ya\Game Files\PlantsVsZombiesRH.exe" (
        start "" "C:\Users\pc\Desktop\games ko to ya\Game Files\PlantsVsZombiesRH.exe"
        set "GAME_FOUND=1"
    ) else if exist "%~dp0..\PlantsVsZombiesRH.exe" (
        start "" "%~dp0..\PlantsVsZombiesRH.exe"
        set "GAME_FOUND=1"
    ) else if exist "%~dp0PlantsVsZombiesRH.exe" (
        start "" "%~dp0PlantsVsZombiesRH.exe"
        set "GAME_FOUND=1"
    )
    if "!GAME_FOUND!"=="1" (
        echo       Game launched!
    ) else (
        echo       (Note: Please ensure Plants vs Zombies Fusion is running on your PC)
    )
) else (
    echo       PvZ Fusion is running and ready!
)

ping 127.0.0.1 -n 2 >nul

echo  [3/3] Starting Live Stream Studio Services...
if exist "%~dp0core\server.ps1" (
    start "PvZ Fusion Live Studio Server" /min powershell.exe -NoProfile -ExecutionPolicy Bypass -NoExit -File "%~dp0core\server.ps1"
) else (
    start "PvZ Fusion Live Studio Server" /min powershell.exe -NoProfile -ExecutionPolicy Bypass -NoExit -File "%~dp0server.ps1"
)

ping 127.0.0.1 -n 3 >nul

echo  Launching PvZ Fusion Studio Application...
if exist "%~dp0PvZ_Fusion_Studio.exe" (
    start "" "%~dp0PvZ_Fusion_Studio.exe"
) else (
    start msedge.exe --app=http://localhost:8080/app.html
)

echo.
echo ===============================================================================
echo   READY FOR LIVE STREAMING!
echo.
echo   * Studio Application   : PvZ Fusion 4.0 Studio
echo   * OBS Live Overlay     : http://localhost:8080/overlay.html
echo   * Stream Grid Overlay  : http://localhost:8080/stream-overlay.html
echo.
echo   Tip: Add the overlay URLs to OBS Studio as Browser Sources (1920x1080).
echo   Keep this server window open while streaming!
echo ===============================================================================
echo.
pause
