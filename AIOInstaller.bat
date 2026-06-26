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

REM Parse /Unattend or -Unattend flag (forwarded through UAC elevation)
set "PCGR_UNATTEND="
:parseArgs
if /i "%~1"=="/Unattend" (set "PCGR_UNATTEND=1" & shift & goto :parseArgs)
if /i "%~1"=="-Unattend" (set "PCGR_UNATTEND=1" & shift & goto :parseArgs)

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
set /a "FAIL_COUNT=0"
set "FAIL_LOG=%temp%\pcgr_failed_pkgs.txt"
set "DONE_LOG=%temp%\pcgr_done_pkgs.txt"
del "!FAIL_LOG!" 2>nul
del "!DONE_LOG!" 2>nul

REM Options defaults
set /a "OPT_VCREDIST=1"
set /a "OPT_DOTNET=1"
set /a "OPT_ASPNET=1"
set /a "OPT_EXTRAS=0"
set /a "OPT_OUTPUT=0"
set /a "OPT_LOG=0"
set /a "OPT_CLICKPAUSE=0"
set /a "OPT_SILENT=1"
set /a "OPT_FORCE=0"
set "OPT_LOGFILE=log.txt"
set /a "MENU_POS=0"
REM Base directory for log file (overridden to %TEMP%\ when /Unattend)
set "PCGR_LOGDIR=%~dp0"
REM Unattended mode: enable logging to %TEMP% and skip all interactive prompts
if defined PCGR_UNATTEND (
    set /a "OPT_LOG=1"
    set "OPT_LOGFILE=pcgr_aio_%COMPUTERNAME%.log"
    set "PCGR_LOGDIR=%TEMP%\"
)
REM OPT_EXTRAS: 0=Enabled, 1=No 7Zip, 2=Disabled
REM OPT_OUTPUT/OPT_LOG: 0=DISABLED, 1=All Output, 2=All Errors
REM OPT_FORCE: 0=DISABLED, 1=VC++, 2=.NET, 3=ASP.NET, 4=Extras, 5=ALL
REM Option labels
set "OPTNAME[0]=Install VC++ redists"
set "OPTNAME[1]=Install .NET redists"
set "OPTNAME[2]=Install ASP.NET"
set "OPTNAME[3]=Extras"
set "OPTNAME[4]=Output"
set "OPTNAME[5]=Log"
set "OPTNAME[6]=Log file name"
set "OPTNAME[7]=Allow click to pause"
set "OPTNAME[8]=Silent mode (recommended)"
set "OPTNAME[9]=Force reinstall"
REM Output/Log value labels (shared)
set "OUTVAL[0]=DISABLED"
set "OUTVAL[1]=All Output"
set "OUTVAL[2]=All Errors"
REM Force reinstall value labels
set "FORCEVAL[0]=DISABLED"
set "FORCEVAL[1]=VC++"
set "FORCEVAL[2]=.NET"
set "FORCEVAL[3]=Extras"
set "FORCEVAL[4]=ALL"

:splash
if defined PCGR_UNATTEND goto :startInstall
cls
echo.
call :rainbowsep
call :rainbow "    PC Gaming Redists AIO Installer"
call :rainbow "    By HarryEffinPotter and Skrimix"
call :rainbowsep
call :rainbow "   NET / VC++ / XNA / 7Zip / DirectX"
echo.
call :rainbow "  Press S to start, or O for options..."
echo.

choice /C SO /N >nul
if errorlevel 2 goto :optionsMenu
goto :startInstall

:cancelled
cls
call :rainbowsep
call :rainbow "Installation cancelled."
call :rainbowsep
timeout /t 2 /nobreak >nul
exit /B

REM ========================================
REM Options Menu - runs entirely in PowerShell for speed
REM Passes current values in, gets final values out
REM ========================================
:optionsMenu
powershell -nop -f "%~dp0pcgr_menu.ps1" !OPT_VCREDIST! !OPT_DOTNET! !OPT_ASPNET! !OPT_EXTRAS! !OPT_OUTPUT! !OPT_LOG! !OPT_CLICKPAUSE! !OPT_SILENT! !OPT_FORCE! "!OPT_LOGFILE!"
REM Read result from temp file
if exist "%temp%\pcgr_menu_result.txt" (
    for /f "tokens=1-9 delims=," %%a in ('type "%temp%\pcgr_menu_result.txt"') do (
        set "OPT_VCREDIST=%%a"
        set "OPT_DOTNET=%%b"
        set "OPT_ASPNET=%%c"
        set "OPT_EXTRAS=%%d"
        set "OPT_OUTPUT=%%e"
        set "OPT_LOG=%%f"
        set "OPT_CLICKPAUSE=%%g"
        set "OPT_SILENT=%%h"
        set "menuRest=%%i"
    )
    for /f "tokens=1,2 delims=|" %%x in ("!menuRest!") do (
        set "OPT_FORCE=%%x"
        set "OPT_LOGFILE=%%y"
    )
    del "%temp%\pcgr_menu_result.txt" 2>nul
)
goto :splash

:startInstall
cls
title PCGR - PC Gaming Redists - Installing...
set /a "WINGET_RETRY_COUNT=0"

REM Disable QuickEdit unless user enabled "Allow click to pause"
if !OPT_CLICKPAUSE!==0 (
    powershell -nop -c "try{Add-Type 'using System;using System.Runtime.InteropServices;public class QE{[DllImport(\"kernel32.dll\")]public static extern IntPtr GetStdHandle(int h);[DllImport(\"kernel32.dll\")]public static extern bool GetConsoleMode(IntPtr h,out uint m);[DllImport(\"kernel32.dll\")]public static extern bool SetConsoleMode(IntPtr h,uint m);}';$h=[QE]::GetStdHandle(-10);$m=0;[void][QE]::GetConsoleMode($h,[ref]$m);[void][QE]::SetConsoleMode($h,$m-band(-bnot 0x0040))}catch{}" >nul 2>&1
)

REM If log file exists and is over 5MB, clear it
if exist "!PCGR_LOGDIR!!OPT_LOGFILE!" (
    for %%F in ("!PCGR_LOGDIR!!OPT_LOGFILE!") do (
        if %%~zF GTR 5242880 del "!PCGR_LOGDIR!!OPT_LOGFILE!"
    )
)

call :warning "Now installing... Please be patient, input may be interrupted while packages install."
echo.
call :rainbowsep
call :rainbow "Checking if WinGet is working..."
call :rainbowsep
echo.

:checkWinget
REM Test if winget works by running a simple search
winget search Microsoft.VCRedist.2015+.x64 --source winget >"%temp%\winget_test.txt" 2>&1
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
    if defined PCGR_UNATTEND (
        set /a "WINGET_RETRY_COUNT+=1"
        if !WINGET_RETRY_COUNT! GTR 5 (
            call :rainbow "WinGet still not working after 5 retries - cannot continue."
            exit /b 1
        )
        call :rainbow "WinGet not ready - retrying [!WINGET_RETRY_COUNT!/5] in 10s..."
        timeout /t 10 /nobreak >nul
        goto :checkWinget
    )
    choice /C YN /M "Retry WinGet check"
    if errorlevel 2 goto :wingetFailed
    if errorlevel 1 goto :checkWinget
)
del "%temp%\winget_test.txt" 2>nul
goto :wingetOK

:wingetFailed
echo.
echo Cannot continue without working WinGet. Exiting...
if not defined PCGR_UNATTEND pause
exit /B 1

:wingetOK
cls

REM VC Redists - gradient shifts FORWARD
set /a "DIRECTION=1"
set /a "OFFSET=0"

if !OPT_VCREDIST!==1 (
call :warning "Now installing... Please be patient, input may be interrupted while packages install."
echo.
call :rainbowsep
call :rainbow "Installing VC Redists..."
call :rainbowsep
echo.
set "INSTALL_SECTION=vc"
winget search Microsoft.VCRed --source winget --accept-source-agreements >NUL 2>NUL
FOR /F "tokens=*" %%G IN ('winget search Microsoft.VCRed --source winget') DO (
set /a skip=0
set "str=%%G"
set "str=!str:*Microsoft.=Microsoft.!"
for /f "tokens=1 delims= " %%a in ("!str!") do (
REM Only accept packages starting with Microsoft.VCRedist
echo %%a | FIND /I "Microsoft.VCRedist." 1>nul 2>Nul && (
echo %%a | FIND /I "arm" 1>nul 2>Nul || (
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
) else (
call :rainbow "Skipping VC Redists - disabled"
echo.
)

REM .NET Redists - gradient shifts BACKWARD
set /a "DIRECTION=-1"

if !OPT_DOTNET!==1 (
cls
call :warning "Now installing... Please be patient, input may be interrupted while packages install."
echo.
call :rainbowsep
call :rainbow "Installing .NET Redists..."
call :rainbowsep
echo.
set "INSTALL_SECTION=dotnet"
FOR /F "tokens=*" %%G IN ('winget search Microsoft.dotNet --source winget') DO (
set /a skip=0
set "str=%%G"
set "str=!str:*Microsoft.=Microsoft.!"
for /f "tokens=1 delims= " %%a in ("!str!") do (
REM Whitelist: only install DesktopRuntime and AspNetCore
set /a "isValid=0"
echo %%a | FIND /I "DesktopRuntime" 1>nul 2>Nul && (set /a isValid=1)
if !OPT_ASPNET!==1 echo %%a | FIND /I "AspNetCore" 1>nul 2>Nul && (set /a isValid=1)
REM Skip ARM builds
echo %%a | FIND /I "arm" 1>nul 2>Nul && (set /a isValid=0)
if "!isValid!" == "1" (
set "INSTALL_SECTION=dotnet"
echo %%a | FIND /I "AspNet" 1>nul 2>Nul && (set "INSTALL_SECTION=aspnet")
call :GET %%a
)
  )
)
) else (
call :rainbow "Skipping .NET Redists - disabled"
echo.
)
goto :finished

:GET
REM Build flags based on options
set "getFlags="
REM Silent mode
if !OPT_SILENT!==1 set "getFlags=!getFlags! --silent"
REM Force reinstall logic
set "addForce=0"
if !OPT_FORCE!==5 set "addForce=1"
if !OPT_FORCE!==1 if "!INSTALL_SECTION!"=="vc" set "addForce=1"
if !OPT_FORCE!==2 if "!INSTALL_SECTION!"=="dotnet" set "addForce=1"
if !OPT_FORCE!==3 if "!INSTALL_SECTION!"=="aspnet" set "addForce=1"
if !OPT_FORCE!==4 if "!INSTALL_SECTION!"=="extras" set "addForce=1"
if "!addForce!"=="1" set "getFlags=!getFlags! --force"
call :GETEX %~1 "!getFlags!"
goto :eof

:GETEX
set "pkg=%~1"
set "extraFlags=%~2"
set /a "retries=0"
set /a "maxRetries=3"
set "WINGET_OUT=%temp%\pcgr_winget_out.txt"

:GETEX_retry
set /a "retries+=1"

REM Display status line
if !retries! GTR 1 (
    <nul set /p "=!ESC![2K!ESC![G"
    call :rainbowline "  Retry !retries!/!maxRetries! for !pkg!... INSTALLING"
) else (
    call :rainbowline "Installing !pkg!... INSTALLING"
)

REM Always capture output to temp file for status detection and logging
winget install -e --id !pkg! --accept-package-agreements --accept-source-agreements --source winget !extraFlags! >"!WINGET_OUT!" 2>&1
set "WG_EXIT=!ERRORLEVEL!"

REM Determine result
set "STATUS=UNKNOWN"
if "!WG_EXIT!"=="0" set "STATUS=DONE"
if "!WG_EXIT!"=="-1978335189" set "STATUS=ALREADY UP TO DATE"
if "!WG_EXIT!"=="-1978335135" set "STATUS=ALREADY UP TO DATE"
if "!WG_EXIT!"=="-1978334963" set "STATUS=ALREADY UP TO DATE"
if "!WG_EXIT!"=="-1978334962" set "STATUS=ALREADY UP TO DATE"
if "!WG_EXIT!"=="-1978335153" set "STATUS=ALREADY UP TO DATE"

REM If still unknown, it's a real failure
if "!STATUS!"=="UNKNOWN" (
    if !retries! LSS !maxRetries! (
        <nul set /p "=!ESC![2K!ESC![G"
        call :rainbowline "Installing !pkg!... FAILED - retrying in 3s"
        timeout /t 3 /nobreak >nul
        goto :GETEX_retry
    )
    set "STATUS=FAILED"
    set /a "FAIL_COUNT+=1"
    echo !pkg!>>"!FAIL_LOG!"
)

REM Track successful installs
if "!STATUS!"=="DONE" echo !pkg!>>"!DONE_LOG!"

REM Overwrite the line with final status
<nul set /p "=!ESC![2K!ESC![G"
call :rainbow "Installing !pkg!... !STATUS!"

REM Show output on screen if Output option enabled
if exist "!WINGET_OUT!" (
    if !OPT_OUTPUT!==1 type "!WINGET_OUT!"
    if !OPT_OUTPUT!==2 if "!STATUS!"=="FAILED" type "!WINGET_OUT!"
)

REM Write to log file if Log option enabled
if exist "!WINGET_OUT!" (
    if !OPT_LOG!==1 (
        echo === !pkg! [!STATUS!] ===>>!PCGR_LOGDIR!!OPT_LOGFILE!
        type "!WINGET_OUT!">>!PCGR_LOGDIR!!OPT_LOGFILE!
        echo.>>!PCGR_LOGDIR!!OPT_LOGFILE!
    )
    if !OPT_LOG!==2 if "!STATUS!"=="FAILED" (
        echo === FAILED: !pkg! ===>>!PCGR_LOGDIR!!OPT_LOGFILE!
        type "!WINGET_OUT!">>!PCGR_LOGDIR!!OPT_LOGFILE!
        echo.>>!PCGR_LOGDIR!!OPT_LOGFILE!
    )
)

REM Cleanup
del "!WINGET_OUT!" 2>nul
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
set "INSTALL_SECTION=extras"

if !OPT_EXTRAS! LSS 2 (
call :warning "Now installing... Please be patient, input may be interrupted while packages install."
echo.
call :rainbowsep
call :rainbow "Installing common tools..."
call :rainbowsep
echo.
call :GET Microsoft.DirectX
call :GET Microsoft.XNARedist
if !OPT_EXTRAS!==0 (
    call :GET 7zip.7zip
) else (
    call :rainbow "Skipping 7zip..."
)
call :GET Microsoft.PowerShell
cls
call :warning "!WARN_TEXT!"
echo.
call :rainbowsep
call :rainbow "+ Installed Common Tools +"
call :rainbowsep
echo.
Timeout /t 2 /nobreak 1>nul 2>nul
cls
) else (
call :rainbow "Skipping Extras - disabled"
echo.
)

REM FAIL_LOG is displayed at end screen, deleted there

REM Show log file location if logging was enabled
if !OPT_LOG! GEQ 1 if exist "!PCGR_LOGDIR!!OPT_LOGFILE!" (
    call :rainbow "Log saved to: !PCGR_LOGDIR!!OPT_LOGFILE!"
    echo.
)

echo.
call :rainbowsep
if !FAIL_COUNT! GTR 0 (
    call :rainbow "Done, but with !FAIL_COUNT! failure(s). Press any key to exit."
) else (
    call :rainbow "All done. Press any key to exit."
)
call :rainbowsep
echo.

REM Show what was installed/updated
if exist "%temp%\pcgr_done_pkgs.txt" (
    echo.
    call :rainbow "Installed/Updated:"
    for /f "tokens=*" %%p in (%temp%\pcgr_done_pkgs.txt) do (
        call :rainbow "  + %%p"
    )
    echo.
)
del "%temp%\pcgr_done_pkgs.txt" 2>nul

REM Show what failed in red
if exist "%temp%\pcgr_failed_pkgs.txt" (
    echo !ESC![38;2;220;20;60mFailed:!RESET!
    for /f "tokens=*" %%p in (%temp%\pcgr_failed_pkgs.txt) do (
        echo !ESC![38;2;220;20;60m  - %%p!RESET!
    )
    echo.
)
del "%temp%\pcgr_failed_pkgs.txt" 2>nul

if not defined PCGR_UNATTEND pause > nul
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

REM ========================================
REM Rainbow text on current line - no newline, no offset shift
REM Used for in-place status updates (INSTALLING -> DONE)
REM ========================================
:rainbowline
setlocal enabledelayedexpansion
set "text=%~1"
set "output="
set /a "idx=0"

:rainbowline_loop
if "!text:~%idx%,1!"=="" goto :rainbowline_done
set "char=!text:~%idx%,1!"
set /a "ci=(idx + OFFSET) %% 24"
if !ci! LSS 0 set /a "ci+=24"
for %%c in (!ci!) do set "output=!output!!C[%%c]!!char!"
set /a "idx+=1"
goto :rainbowline_loop

:rainbowline_done
<nul set /p "=!output!!RESET!"
endlocal
goto :eof
