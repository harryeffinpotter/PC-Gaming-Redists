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
if '%1'=='ELEV' (echo ELEV & shift /1 & goto gotPrivileges)
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
cls
echo.
echo.
echo.
echo.
echo.
echo.
echo.
Timeout /t 2 /nobreak 1>nul 2>nul
cls
echo ============================
echo   Installing VC Redists...
echo ============================
echo.
Timeout /t 4 /nobreak 1>nul 2>nul
setlocal ENABLEDELAYEDEXPANSION
FOR /F "tokens=*" %%G IN ('winget search Microsoft.VC') DO (
set "str=%%G"
set "str=!str:*Microsoft.=Microsoft.!"
for /f "tokens=1 delims= " %%a in ("!str!") do (
echo %%a | FIND /I "Microsoft." 1>nul 2>Nul && ( 
call :GET %%a
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
echo %%a | FIND /I "Microsoft.DotNet.SDK" 1>nul 2>Nul && (set /a skip=1)
echo %%a | FIND /I "Microsoft.DotNet.HostingBundle" 1>nul 2>Nul  && (set /a skip=1)
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
winget install -e --id %1 --accept-package-agreements --accept-source-agreements --force 2>nul 1>nul
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
winget install -e --id Microsoft.DirectX --accept-package-agreements --accept-source-agreements --force --silent 2>nul 1>nul
echo XNA Framework Redistributable
winget install -e --id Microsoft.XNARedist --accept-package-agreements --accept-source-agreements --force --silent 2>nul 1>nul
echo 7zip
winget install -e --id 7zip.7zip --accept-package-agreements --accept-source-agreements --force --silent 2>nul 1>nul
echo Powershell
winget install -e --id Microsoft.PowerShell --accept-package-agreements --accept-source-agreements --force --silent 2>nul 1>nul
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

:eol
