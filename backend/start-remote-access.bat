@echo off
echo ============================================
echo   Bedtime Story Player - Remote Access Mode
echo ============================================
echo.
echo Starting backend server for remote access...
echo Your girlfriend can connect from anywhere!
echo.
echo Public IP: 112.202.133.117
echo Port: 3000
echo Test URL: http://112.202.133.117:3000/health
echo.
echo IMPORTANT: Make sure port forwarding is set up
echo on your router for port 3000 -^> 192.168.68.109
echo.
cd /d "%~dp0"
set TEST_MODE=true
set NODE_ENV=production
node server.js
pause
