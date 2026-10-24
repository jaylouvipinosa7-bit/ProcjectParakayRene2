@echo off
title RENEarn - Public Cloudflare Overlay Tunnel
color 0b

echo ===============================================================================
echo            RENEarn - GENERATE SECURE PUBLIC OVERLAY LINK
echo ===============================================================================
echo.
echo Starting Cloudflare Tunnel to expose your local overlay to the internet...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0core\start_tunnel.ps1"

echo.
pause
