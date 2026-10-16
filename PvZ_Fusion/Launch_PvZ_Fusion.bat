@echo off
title RENEarn - PvZ Fusion Live Stream Studio
color 0a

if exist "%~dp0..\Apps\Launch_Studio.bat" (
    call "%~dp0..\Apps\Launch_Studio.bat"
) else if exist "%~dp0..\Launch_Studio.bat" (
    call "%~dp0..\Launch_Studio.bat"
) else if exist "%~dp0..\core\server.ps1" (
    start "PvZ Fusion Live Studio Server" /min powershell.exe -NoProfile -ExecutionPolicy Bypass -NoExit -File "%~dp0..\core\server.ps1"
    start msedge.exe --app=http://localhost:8080/app.html
)
