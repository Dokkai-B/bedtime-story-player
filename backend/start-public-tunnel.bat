@echo off
echo ============================================
echo   Bedtime Story Player - LocalTunnel Setup
echo ============================================
echo.
echo This will create a public tunnel for your girlfriend
echo to access the app from anywhere in the world.
echo.
echo IMPORTANT: 
echo 1. Keep this window open while she uses the app
echo 2. The URL will change each time you restart
echo 3. Copy the new URL and update app config when needed
echo 4. Audio playback now works through the tunnel!
echo.
echo Starting backend server...
echo.
cd /d "%~dp0"
set TEST_MODE=true
start /b node server.js
timeout /t 3 /nobreak >nul
echo.
echo Creating public tunnel...
echo.
echo ==========================================
echo COPY THIS URL FOR YOUR GIRLFRIEND'S APK:
echo ==========================================
echo.
npx localtunnel --port 3000
echo.
echo ==========================================
echo Remember to update the APK if URL changed!
echo ==========================================
pause
