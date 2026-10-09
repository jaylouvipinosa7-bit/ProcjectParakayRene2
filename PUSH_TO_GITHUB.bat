@echo off
title Push to GitHub - PvZ Fusion 4.0 Studio
color 0b

echo ===============================================================================
echo            PUSHING PVZ FUSION 4.0 STUDIO TO GITHUB
echo ===============================================================================
echo.
echo  Target Repository: https://github.com/jaylouvipinosa7-bit/ProcjectParakayRene2.git
echo  Branch           : main
echo.
echo  Uploading project files to your GitHub...
echo  (If a browser window appears, click "Sign in with your browser" to authorize)
echo.

"C:\Program Files\Git\cmd\git.exe" push -u origin main --force

echo.
if "%ERRORLEVEL%"=="0" (
    color 0a
    echo ===============================================================================
    echo   SUCCESS! The app is now published to your GitHub repository!
    echo   View it here: https://github.com/jaylouvipinosa7-bit/ProcjectParakayRene2
    echo ===============================================================================
) else (
    color 0c
    echo ===============================================================================
    echo   Push encountered an error or was cancelled.
    echo ===============================================================================
)
echo.
pause
