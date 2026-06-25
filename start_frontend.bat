@echo off
title Email OSINT - Flutter Frontend
color 0A
echo ==========================================
echo   Email OSINT Flutter App (Chrome)
echo   http://localhost:3000
echo ==========================================
set PATH=%PATH%;C:\flutter\bin
cd /d "e:\NexusProbe\mobile"
flutter run -d chrome --web-port=3000 --dart-define=API_BASE_URL=http://localhost:8000
pause
