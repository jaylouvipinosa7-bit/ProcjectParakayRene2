@echo off
title Plants vs. Zombies 2 - PC Download Launcher
color 0a

:MENU
cls
echo ===============================================================================
echo            PLANTS VS. ZOMBIES 2 - PC DOWNLOAD & SETUP LAUNCHER
echo ===============================================================================
echo.
echo   PvZ 2 was designed for mobile (Android/iOS). To play it on PC with 
echo   full keyboard + mouse controls and 60 FPS, choose an option below:
echo.
echo   [1] BlueStacks 5 (Recommended - Pre-configured Mouse/Keyboard Controls)
echo   [2] Google Play Games for PC (Official Google Windows App)
echo   [3] LDPlayer 9 (Lightweight & High FPS for Low-End to High-End PCs)
echo   [4] PvZ 2: Reflourished (Popular Fan PC Mod - All Worlds & No Paywalls)
echo   [5] Open PvZ 2 Official Google Play Store Page
echo   [6] Open Download Guide (Text File)
echo   [0] Exit
echo.
echo ===============================================================================
set /p choice="  Enter your choice (1-6, or 0 to exit): "

if "%choice%"=="1" goto BLUESTACKS
if "%choice%"=="2" goto GOOGLEPLAY
if "%choice%"=="3" goto LDPLAYER
if "%choice%"=="4" goto REFLOURISHED
if "%choice%"=="5" goto PLAYSTORE
if "%choice%"=="6" goto GUIDE
if "%choice%"=="0" exit
goto MENU

:BLUESTACKS
echo.
echo   Opening BlueStacks PvZ 2 PC download page in your browser...
start https://www.bluestacks.com/apps/casual/plants-vs-zombies-2-on-pc.html
echo   Done!
pause
goto MENU

:GOOGLEPLAY
echo.
echo   Opening Official Google Play Games on PC download page...
start https://play.google.com/googleplaygames
echo   Done!
pause
goto MENU

:LDPLAYER
echo.
echo   Opening LDPlayer 9 PvZ 2 PC download page...
start https://www.ldplayer.net/games/plants-vs-zombies-2-on-pc.html
echo   Done!
pause
goto MENU

:REFLOURISHED
echo.
echo   Opening PvZ 2: Reflourished community edition page...
start https://pvz2reflourished.fandom.com/wiki/Plants_vs._Zombies_2:_Reflourished
echo   Done!
pause
goto MENU

:PLAYSTORE
echo.
echo   Opening Google Play Store PvZ 2 page...
start https://play.google.com/store/apps/details?id=com.ea.game.pvz2_row
echo   Done!
pause
goto MENU

:GUIDE
if exist "%~dp0PvZ2_Download_Guide.txt" (
    start notepad.exe "%~dp0PvZ2_Download_Guide.txt"
) else (
    echo Guide file not found.
)
goto MENU
