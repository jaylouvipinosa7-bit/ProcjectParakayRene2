@echo off
title RENEarn Overlay Local Server (Port 8080)
color 0b
echo ================================================================
echo    Starting RENEarn Overlay Server on Port 8080...
echo ================================================================
echo.
powershell.exe -ExecutionPolicy Bypass -File "%~dp0..\server.ps1"
pause
