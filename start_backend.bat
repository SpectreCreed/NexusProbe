@echo off
title Email OSINT - Backend
color 0B
echo ==========================================
echo   Email OSINT Backend (FastAPI)
echo   http://localhost:8000
echo   Swagger: http://localhost:8000/docs
echo ==========================================
cd /d "e:\NexusProbe"
C:\Python313\python.exe -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
pause
