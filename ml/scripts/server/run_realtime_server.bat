@echo off
setlocal

REM This BAT is located at: liftright\ml\scripts\server\run_realtime_server.bat
REM So SCRIPT_DIR = liftright\ml\scripts\server
set SCRIPT_DIR=%~dp0
REM ML_SCRIPTS_DIR = liftright\ml\scripts
set ML_SCRIPTS_DIR=%SCRIPT_DIR%\..
REM LIFTRIGHT_ROOT = liftright
set LIFTRIGHT_ROOT=%ML_SCRIPTS_DIR%\..\..

cd /d "%LIFTRIGHT_ROOT%"

REM Start the realtime server (the file you actually have)
python "%LIFTRIGHT_ROOT%\ml\scripts\realtime_server.py"
