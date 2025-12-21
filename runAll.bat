@echo off
REM Runs Docker infra, then user-service, post-service, and frontend

echo Zagon docker...
cd docker
call docker compose up -d
cd ..

echo Zagon baz podatkov...
timeout /t 5 /nobreak

echo Zagon user-service na portu 8080...
cd user-service
start cmd /k "run-dev.bat"
cd ..

timeout /t 3

echo Zagon post-service na portu 8081 + Azurite nastavitve...
cd post-service
start cmd /k "run-dev.bat"
cd ..

timeout /t 3

echo Zagon payment-service na portu 8082...
cd payment-service
start cmd /k "run-dev.bat"
cd ..

timeout /t 3

echo Zagon frontend...
cd frontend
start cmd /k "run-dev.bat"
cd ..

echo Vse storitve so zagnane.
pause
