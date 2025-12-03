@echo off
echo Restoring QuickEdit mode...

set "backupFile=%APPDATA%\PCGR_QuickEdit_Backup.txt"

if exist "%backupFile%" (
    set /p origValue=<"%backupFile%"
    reg add "HKCU\Console" /v QuickEdit /t REG_DWORD /d %origValue% /f >nul
    del "%backupFile%" >nul 2>&1
    echo Restored your original QuickEdit setting.
) else (
    reg add "HKCU\Console" /v QuickEdit /t REG_DWORD /d 1 /f >nul
    echo No backup found - enabled QuickEdit by default.
)

echo Done! Change applies to new console windows.
pause
