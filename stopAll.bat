@echo off
echo Zaustavljanje frontend (node/npm na portu 3000)...
for /f "tokens=5" %%i in ('netstat -ano ^| findstr :3000 ^| findstr LISTENING') do taskkill /F /PID %%i 2>nul
taskkill /F /IM node.exe 2>nul

echo Zaustavljanje Java mikrostoritev...
for /f "tokens=5" %%i in ('netstat -ano ^| findstr :8080 ^| findstr LISTENING') do taskkill /F /PID %%i 2>nul
for /f "tokens=5" %%i in ('netstat -ano ^| findstr :8081 ^| findstr LISTENING') do taskkill /F /PID %%i 2>nul
for /f "tokens=5" %%i in ('netstat -ano ^| findstr :8082 ^| findstr LISTENING') do taskkill /F /PID %%i 2>nul
taskkill /F /IM java.exe 2>nul

echo Zaustavljanje Docker infrastrukture...
cd docker
call docker compose down
cd ..

echo Vse storitve so zaustavljene.
pause
