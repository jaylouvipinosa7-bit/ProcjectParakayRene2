@echo off
echo ===================================================
echo Fetching latest icons from your StreamToEarn preset
echo ===================================================
powershell -ExecutionPolicy Bypass -File "%~dp0download_assets.ps1"
echo Done! Refresh your browser / overlay in TikTok Live Studio.
pause
