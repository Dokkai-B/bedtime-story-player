@echo off
echo Starting Bedtime Story Player Backend in Test Mode...
echo.
cd /d "%~dp0"
set TEST_MODE=true
node server.js
pause
