@echo off
echo Restoring QuickEdit mode...
reg add "HKCU\Console" /v QuickEdit /t REG_DWORD /d 1 /f >nul
echo Done! QuickEdit is now enabled for new console windows.
pause
