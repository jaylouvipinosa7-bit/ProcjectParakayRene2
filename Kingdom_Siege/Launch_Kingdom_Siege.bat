@echo off
title Kingdom Siege - TikTok LIVE Interactive Castle Defense
color 0e

echo ===============================================================================
echo       KINGDOM SIEGE - TIKTOK LIVE INTERACTIVE CASTLE DEFENSE
echo ===============================================================================
echo.
echo  [1/2] Checking Local Studio Server...
netstat -ano | findstr /R /C:":8080 .*LISTENING" >nul
if "%ERRORLEVEL%"=="1" (
    echo       Server not active. Starting background server on port 8080...
    if exist "%~dp0..\core\server.ps1" (
        start "PvZ Fusion Live Studio Server" /min powershell.exe -NoProfile -ExecutionPolicy Bypass -NoExit -File "%~dp0..\core\server.ps1"
    ) else if exist "%~dp0core\server.ps1" (
        start "PvZ Fusion Live Studio Server" /min powershell.exe -NoProfile -ExecutionPolicy Bypass -NoExit -File "%~dp0core\server.ps1"
    )
    ping 127.0.0.1 -n 3 >nul
) else (
    echo       Server is active and ready on port 8080!
)

echo.
echo  [2/2] Launching Kingdom Siege Game Window...
start msedge.exe --app=http://localhost:8080/kingdom-siege.html

echo.
echo ===============================================================================
echo   GAME IS RUNNING AND READY FOR YOUR STREAM!
echo.
echo   * Direct Play / Window : http://localhost:8080/kingdom-siege.html
echo   * OBS Browser Source   : http://localhost:8080/kingdom-siege.html
echo.
echo   Recommended OBS Settings:
echo    - Horizontal (YouTube/Twitch) : 1920 x 1080
echo    - Vertical (TikTok LIVE)      : 1080 x 1920 (Click the "Vertical" toggle)
echo.
echo   Viewer Controls:
echo    - Free Likes / Comments       : Spawn Goblin Swarms
echo    - Rose (1 coin)               : Spawns Orc Berserker
echo    - Heart / Ice Cream           : Spawns Armored Battering Ram
echo    - Donut (30 coins)            : Spawns Dark Trebuchet Catapult
echo    - Dragon / Swan               : Spawns Flying Shadow Dragon
echo    - Galaxy / Lion (1000+ coins) : Spawns THE COLOSSAL TITAN BOSS!
echo ===============================================================================
echo.
pause
