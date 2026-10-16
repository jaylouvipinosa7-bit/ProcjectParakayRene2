@echo off
title RENEarn • Real Zombie Tsunami Live Command Bridge
color 0a

echo ===============================================================================
echo        RENEarn • REAL ZOMBIE TSUNAMI LIVE COMMAND BRIDGE
echo ===============================================================================
echo.
echo  This bridge connects your REAL installed Zombie Tsunami game to:
echo    - TikTok Live Studio (Gifts: Rose, Whale, Doughnut)
echo    - Live Chat commands (!jump, !highjump, !tsunami)
echo    - RENEarn Studio interactive dashboard
echo.
echo  Starting Bridge in interactive mode...
echo ===============================================================================
echo.

if exist "%~dp0..\core\zombie_bridge.ps1" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\core\zombie_bridge.ps1"
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0core\zombie_bridge.ps1"
)

pause
