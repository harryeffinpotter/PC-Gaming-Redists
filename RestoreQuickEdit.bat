@echo off
:: Self-elevate if needed
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo Enabling QuickEdit mode...
reg add "HKCU\Console" /v QuickEdit /t REG_DWORD /d 1 /f >nul
echo Done! QuickEdit is now enabled for new console windows.
pause
