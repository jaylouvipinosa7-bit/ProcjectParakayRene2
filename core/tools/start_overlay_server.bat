@echo off
title StreamToEarn Overlay Local Server (Port 8080)
color 0b
echo ================================================================
echo    Starting StreamToEarn Overlay Server on Port 8080...
echo ================================================================
echo.
powershell.exe -ExecutionPolicy Bypass -File "%~dp0server.ps1"
pause
