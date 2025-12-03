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
color 07
setlocal enabledelayedexpansion

REM Set up ANSI escape code for RGB colors
for /F %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
set "RESET=!ESC![0m"

REM Define pastel rainbow colors (24 colors for smooth gradient)
set "C[0]=!ESC![38;2;255;182;193m"
set "C[1]=!ESC![38;2;255;190;180m"
set "C[2]=!ESC![38;2;255;200;170m"
set "C[3]=!ESC![38;2;255;210;160m"
set "C[4]=!ESC![38;2;255;220;150m"
set "C[5]=!ESC![38;2;255;235;145m"
set "C[6]=!ESC![38;2;255;250;150m"
set "C[7]=!ESC![38;2;240;255;155m"
set "C[8]=!ESC![38;2;220;255;165m"
set "C[9]=!ESC![38;2;200;255;180m"
set "C[10]=!ESC![38;2;180;255;195m"
set "C[11]=!ESC![38;2;165;255;210m"
set "C[12]=!ESC![38;2;155;255;230m"
set "C[13]=!ESC![38;2;155;250;245m"
set "C[14]=!ESC![38;2;160;240;255m"
set "C[15]=!ESC![38;2;170;225;255m"
set "C[16]=!ESC![38;2;180;210;255m"
set "C[17]=!ESC![38;2;190;200;255m"
set "C[18]=!ESC![38;2;200;195;255m"
set "C[19]=!ESC![38;2;210;190;255m"
set "C[20]=!ESC![38;2;220;188;255m"
set "C[21]=!ESC![38;2;230;185;255m"
set "C[22]=!ESC![38;2;240;185;250m"
set "C[23]=!ESC![38;2;250;183;240m"

REM Global offset for shifting gradient effect (1 = forward, -1 = backward)
set /a "OFFSET=0"
set /a "DIRECTION=1"
set /a "WARN_OFFSET=0"
set "WARN_TEXT=Now installing... Please be patient, input may be interrupted while packages install."

echo.
call :rainbowsep
call :rainbow "    PC Gaming Redists AIO Installer"
call :rainbow "    By HarryEffinPotter and Skrimix"
call :rainbowsep
call :rainbow "NET / VC++ / XNA / 7Zip / DirectX"
echo.
call :rainbow "Press any key to start..."
echo.

pause >nul
goto :startInstall

:cancelled
cls
call :rainbowsep
call :rainbow "Installation cancelled."
call :rainbowsep
timeout /t 2 /nobreak >nul
exit /B

:startInstall
cls
title PCGR - PC Gaming Redists - Installing...

call :warning "Now installing... Please be patient, input may be interrupted while packages install."
echo.
call :rainbowsep
call :rainbow "Checking if WinGet is working..."
call :rainbowsep
echo.

:checkWinget
REM Test if winget works by running a simple search
winget search Microsoft.VCRedist.2015+.x64 >"%temp%\winget_test.txt" 2>&1
findstr /C:"Microsoft.VCRedist" "%temp%\winget_test.txt" >nul 2>nul
if %errorlevel% NEQ 0 (
    cls
    echo.
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

REM VC Redists - gradient shifts FORWARD
set /a "DIRECTION=1"
set /a "OFFSET=0"

call :warning "Now installing... Please be patient, input may be interrupted while packages install."
echo.
call :rainbowsep
call :rainbow "Installing VC Redists..."
call :rainbowsep
echo.
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
)
cls

call :warning "!WARN_TEXT!"
echo.
call :rainbowsep
call :rainbow "+ VC Redists Installed +"
call :rainbowsep
echo.
Timeout /t 2 /nobreak 1>nul 2>nul
cls

REM .NET Redists - gradient shifts BACKWARD
set /a "DIRECTION=-1"

call :warning "Now installing... Please be patient, input may be interrupted while packages install."
echo.
call :rainbowsep
call :rainbow "Installing .NET Redists..."
call :rainbowsep
echo.
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
goto :finished

:GET
call :rainbow "Installing %~1..."
winget install -e --id %~1 --accept-package-agreements --accept-source-agreements --force --silent --disable-interactivity 2>nul 1>nul
REM Update the wave animation on the warning line
call :updatewarn
goto :eof

:finished
cls

call :warning "!WARN_TEXT!"
echo.
call :rainbowsep
call :rainbow "+ Installed .NET Redists +"
call :rainbowsep
echo.
Timeout /t 2 /nobreak 1>nul 2>nul
cls

REM Common tools - gradient shifts FORWARD again
set /a "DIRECTION=1"

call :warning "Now installing... Please be patient, input may be interrupted while packages install."
echo.
call :rainbowsep
call :rainbow "Installing common tools..."
call :rainbowsep
echo.
call :rainbow "DirectX"
winget install -e --id Microsoft.DirectX --accept-package-agreements --accept-source-agreements --force --silent --disable-interactivity 2>nul 1>nul
call :updatewarn
call :rainbow "XNA Framework"
winget install -e --id Microsoft.XNARedist --accept-package-agreements --accept-source-agreements --force --silent --disable-interactivity 2>nul 1>nul
call :updatewarn
call :rainbow "7zip"
winget install -e --id 7zip.7zip --accept-package-agreements --accept-source-agreements --force --silent --disable-interactivity 2>nul 1>nul
call :updatewarn
call :rainbow "PowerShell"
winget install -e --id Microsoft.PowerShell --accept-package-agreements --accept-source-agreements --force --silent --disable-interactivity 2>nul 1>nul
call :updatewarn

cls

call :warning "!WARN_TEXT!"
echo.
call :rainbowsep
call :rainbow "+ Installed Common Tools +"
call :rainbowsep
echo.
Timeout /t 2 /nobreak 1>nul 2>nul
cls

echo.
call :rainbowsep
call :rainbow "All done! Press any key to exit."
call :rainbowsep
echo.
pause > nul
color
exit

REM ========================================
REM Warning line - same rainbow but opposite direction
REM ========================================
:warning
setlocal enabledelayedexpansion
set "text=%~1"
set "output="
set /a "idx=0"

:warning_loop
if "!text:~%idx%,1!"=="" goto :warning_done
set "char=!text:~%idx%,1!"
REM Divide by 6 for super gradual gradient
set /a "ci=(24 - (idx / 6) + WARN_OFFSET) %% 24"
if !ci! LSS 0 set /a "ci+=24"
for %%c in (!ci!) do set "output=!output!!C[%%c]!!char!"
set /a "idx+=1"
goto :warning_loop

:warning_done
<nul set /p "=!output!!RESET!"
echo.
endlocal
goto :eof

REM ========================================
REM Update warning line with wave animation
REM Uses ANSI to move cursor to top, redraw, move back
REM ========================================
:updatewarn
setlocal enabledelayedexpansion
set "text=!WARN_TEXT!"
set "output="
set /a "idx=0"

:updatewarn_loop
if "!text:~%idx%,1!"=="" goto :updatewarn_done
set "char=!text:~%idx%,1!"
REM Divide by 6 for super gradual gradient
set /a "ci=(24 - (idx / 6) + WARN_OFFSET) %% 24"
if !ci! LSS 0 set /a "ci+=24"
for %%c in (!ci!) do set "output=!output!!C[%%c]!!char!"
set /a "idx+=1"
goto :updatewarn_loop

:updatewarn_done
REM Save cursor, move to row 1, clear line, draw, restore cursor
<nul set /p "=!ESC![s!ESC![1;1H!ESC![K!output!!RESET!!ESC![u"
endlocal
REM Shift by 5 each time for more noticeable wave
set /a "WARN_OFFSET+=5"
goto :eof

REM ========================================
REM Rainbow separator line - shifts with offset
REM ========================================
:rainbowsep
setlocal enabledelayedexpansion
set "output="
for /L %%i in (0,1,39) do (
    set /a "ci=(%%i + OFFSET) %% 24"
    if !ci! LSS 0 set /a "ci+=24"
    for %%c in (!ci!) do set "output=!output!!C[%%c]!="
)
<nul set /p "=!output!!RESET!"
echo.
endlocal
REM Shift offset for next call
set /a "OFFSET+=DIRECTION"
goto :eof

REM ========================================
REM Rainbow text function - colorizes each character with shifting offset
REM Usage: call :rainbow "Your text here"
REM ========================================
:rainbow
setlocal enabledelayedexpansion
set "text=%~1"
set "output="
set /a "idx=0"

:rainbow_loop
if "!text:~%idx%,1!"=="" goto :rainbow_done
set "char=!text:~%idx%,1!"
set /a "ci=(idx + OFFSET) %% 24"
if !ci! LSS 0 set /a "ci+=24"
for %%c in (!ci!) do set "output=!output!!C[%%c]!!char!"
set /a "idx+=1"
goto :rainbow_loop

:rainbow_done
<nul set /p "=!output!!RESET!"
echo.
endlocal
REM Shift offset for next call
set /a "OFFSET+=DIRECTION"
goto :eof
