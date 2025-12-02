@echo off

:Start
setlocal DisableDelayedExpansion
set "batchPath=%~0"
for %%k in (%0) do set batchName=%%~nk
set "vbsGetPrivileges=%temp%\OEgetPriv_%batchName%.vbs"
setlocal EnableDelayedExpansion
:checkPrivileges
NET FILE 1>NUL 2>NUL
if '%errorlevel%' == '0' ( goto :gotPrivileges ) else ( goto :getPrivileges )
:getPrivileges
if '%1'=='ELEV' (echo ELEV & shift /1 & goto :gotPrivileges)
ECHO Set UAC = CreateObject^("Shell.Application"^) > "%vbsGetPrivileges%"
ECHO args = "ELEV " >> "%vbsGetPrivileges%"
ECHO For Each strArg in WScript.Arguments >> "%vbsGetPrivileges%"
ECHO args = args ^& strArg ^& " "  >> "%vbsGetPrivileges%"
ECHO Next >> "%vbsGetPrivileges%"
ECHO UAC.ShellExecute "!batchPath!", args, "", "runas", 1 >> "%vbsGetPrivileges%"
"%SystemRoot%\System32\WScript.exe" "%vbsGetPrivileges%" %*
exit /B
:gotPrivileges
setlocal & pushd .
cd /d %~dp0
if '%1'=='ELEV' (del "%vbsGetPrivileges%" 1>nul 2>nul  &  shift /1)

cls
title PC Gaming Redists AIO Installer
color 1b
echo =================================
echo  PC Gaming Redists AIO Installer
echo  By HarryEffinPotter and Skrimix
echo =================================
echo NET / VC++ / XNA / 7Zip / DirectX
echo.
echo Press any key to begin.
pause > nul
cls

echo.
echo Checking if WinGet is working...
echo.

:checkWinget
REM Test if winget works by running a simple search
winget search Microsoft.VCRedist.2015+.x64 >"%temp%\winget_test.txt" 2>&1
findstr /C:"Microsoft.VCRedist" "%temp%\winget_test.txt" >nul 2>nul
if %errorlevel% NEQ 0 (
    cls
    
    echo ============================================
    echo   ERROR: WinGet is not working properly!
    echo ============================================
    echo.
    echo WinGet returned no results or is broken.
    echo This can happen on fresh Windows installs.
    echo.
    echo Please install WinGet manually from:
    echo   https://github.com/microsoft/winget-cli
    echo.
    echo Download the latest .msixbundle from Releases
    echo and install it, then try again.
    echo.
    echo ============================================
    echo.
    choice /C YN /M "Retry WinGet check"
    if errorlevel 2 goto :wingetFailed
    if errorlevel 1 goto :checkWinget
)
del "%temp%\winget_test.txt" 2>nul
goto :wingetOK

:wingetFailed
echo.
echo Cannot continue without working WinGet. Exiting...
pause
exit /B

:wingetOK
cls

echo ============================
echo   Installing VC Redists...
echo ============================
echo.
Timeout /t 4 /nobreak 1>nul 2>nul
setlocal ENABLEDELAYEDEXPANSION
winget search Microsoft.VCRed --accept-source-agreements >NUL 2>NUL
FOR /F "tokens=*" %%G IN ('winget search Microsoft.VCRed') DO (
set /a skip=0
set "str=%%G"
set "str=!str:*Microsoft.=Microsoft.!"
for /f "tokens=1 delims= " %%a in ("!str!") do (
echo %%a | FIND /I "arm" 1>nul 2>Nul && (set /a skip=1)
echo %%a | FIND /I "Microsoft." 1>nul 2>Nul && (
if "!skip!" == "0" (
call :GET %%a
)
)
)
)
endlocal
)
cls

echo ============================
echo   + VC Redists Installed +
echo ============================
echo.
Timeout /t 2 /nobreak 1>nul 2>nul
cls

echo ============================
echo  Installing .NET Redists...
echo ============================
echo.
Timeout /t 2 /nobreak 1>nul 2>nul
setlocal ENABLEDELAYEDEXPANSION
FOR /F "tokens=*" %%G IN ('winget search Microsoft.dotNet') DO (
set /a skip=0
set "str=%%G"
set "str=!str:*Microsoft.=Microsoft.!"
for /f "tokens=1 delims= " %%a in ("!str!") do (
echo %%a | FIND /I "Microsoft.dotnetUninstallTool" 1>nul 2>Nul && (set /a skip=1)
echo %%a | FIND /I "Microsoft.DotNet.UninstallTool" 1>nul 2>Nul && (set /a skip=1)
echo %%a | FIND /I "Microsoft.DotNet.SDK" 1>nul 2>Nul && (set /a skip=1)
echo %%a | FIND /I "arm" 1>nul 2>Nul && (set /a skip=1)
echo %%a | FIND /I "Microsoft.DotNet.HostingBundle" 1>nul 2>Nul && (set /a skip=1)
echo %%a | FIND /I "Microsoft.Framework.Developer" 1>nul 2>Nul && (set /a skip=1)
echo %%a | FIND /I "DeveloperPack" 1>nul 2>Nul && (set /a skip=1)
echo %%a | FIND /I "Preview" 1>nul 2>Nul && (set /a skip=1)
echo %%a | FIND /I "RepairTool" 1>nul 2>Nul && (set /a skip=1)
echo %%a | FIND /I "DotNet.Runtime." 1>nul 2>Nul && (set /a skip=1)
echo %%a | FIND /I "Microsoft." 1>nul 2>Nul && ( 
if "!skip!" == "0" (
call :GET %%a
)
)
  )
)
endlocal
goto :finished

:GET outer
echo Installing %1... 2>nul
winget install -e --id %1 --accept-package-agreements --accept-source-agreements --force --silent --disable-interactivity 2>nul 1>nul
goto :eol

:finished
cls

echo ============================
echo  + Installed .Net redists +
echo ============================
echo.
Timeout /t 2 /nobreak 1>nul 2>nul
cls

echo ============================
echo  Installing common tools...
echo ============================
echo.
Timeout /t 2 /nobreak 1>nul 2>nul
REM Install some other loose ends.
echo DirectX
winget install -e --id Microsoft.DirectX --accept-package-agreements --accept-source-agreements --force --silent --disable-interactivity 2>nul 1>nul
echo XNA Framework Redistributable
winget install -e --id Microsoft.XNARedist --accept-package-agreements --accept-source-agreements --force --silent --disable-interactivity 2>nul 1>nul
echo 7zip
winget install -e --id 7zip.7zip --accept-package-agreements --accept-source-agreements --force --silent --disable-interactivity 2>nul 1>nul
echo Powershell
winget install -e --id Microsoft.PowerShell --accept-package-agreements --accept-source-agreements --force --silent --disable-interactivity 2>nul 1>nul
Timeout /t 2 /nobreak 1>nul 2>nul

cls

echo ============================
echo  + Installed Common Tools +
echo ============================
echo.
Timeout /t 2 /nobreak 1>nul 2>nul
cls

echo All done. Press any key to exit.
pause > nul
color
exit

:eol
goto :eof

