@echo off
set RAZOR_PATH=C:\Program Files (x86)\Razor
set SCRIPT_PATH=C:\Program Files (x86)\OpenEUO\scripts
cd /D %RAZOR_PATH%
echo Monitoring "kill_them_all.txt" since %TIME%
:while1 
  if exist "%SCRIPT_PATH%\kill_them_all.txt" (
    echo Found kill_them_all.txt at %TIME%, try to kill client.exe 
    taskkill.exe /F /IM client.exe >NUL
    del "%SCRIPT_PATH%\kill_them_all.txt"
    start "New Razor" Razor.exe
    echo New Razor started at %TIME%
  ) else ( 
    ping -n 5 localhost >NUL
  ) 
goto :while1
