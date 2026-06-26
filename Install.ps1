# -Unattend : skip all interactive prompts and forward /Unattend to the elevated batch.
#             When the calling context is already elevated (e.g. autounattend.xml),
#             the script bypasses the UAC re-launch and runs AIOInstaller.bat directly.
# -BaseUrl  : raw-content base URL for downloading AIOInstaller.bat and pcgr_menu.ps1.
#             Override when testing a fork branch so the patched files are used.
#             Default points to the upstream main branch.
param(
    [switch]$Unattend,
    [string]$BaseUrl = 'https://raw.githubusercontent.com/harryeffinpotter/PC-Gaming-Redists/main'
)

# Log to file silently
$LogFile = "$env:TEMP\PC-Gaming-Redists-Install.log"
Start-Transcript -Path $LogFile -Force | Out-Null

# Determine whether we are already running elevated (needed for autounattend path)
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

# PCGR ASCII Art Logo - rainbow gradient left to right
$b = [char]0x2588  # full block
$s = [char]0x2591  # light shade
$e = [char]27      # escape char for ANSI
$r = "$e[0m"       # Reset

# Pastel rainbow - super gradual: Pink -> Yellow -> Green -> Cyan -> Blue (no loop back)
$rainbow = @(
    # Light Pink
    "$e[38;2;255;182;193m",
    "$e[38;2;255;186;191m",
    "$e[38;2;255;190;189m",
    "$e[38;2;255;194;187m",
    "$e[38;2;255;198;185m",
    "$e[38;2;255;202;183m",
    "$e[38;2;255;206;181m",
    "$e[38;2;255;210;179m",
    "$e[38;2;255;214;177m",
    "$e[38;2;255;218;175m",
    # Pink to Yellow
    "$e[38;2;255;222;173m",
    "$e[38;2;255;226;172m",
    "$e[38;2;255;230;171m",
    "$e[38;2;255;234;170m",
    "$e[38;2;255;238;170m",
    "$e[38;2;255;242;170m",
    "$e[38;2;255;246;170m",
    "$e[38;2;255;250;170m",
    "$e[38;2;253;252;172m",
    "$e[38;2;248;254;174m",
    # Yellow to Green
    "$e[38;2;243;255;176m",
    "$e[38;2;235;255;178m",
    "$e[38;2;227;255;180m",
    "$e[38;2;219;255;182m",
    "$e[38;2;211;255;184m",
    "$e[38;2;203;255;186m",
    "$e[38;2;195;255;190m",
    "$e[38;2;190;255;195m",
    "$e[38;2;185;255;200m",
    "$e[38;2;180;255;208m",
    # Green to Cyan
    "$e[38;2;178;255;216m",
    "$e[38;2;176;255;224m",
    "$e[38;2;174;255;232m",
    "$e[38;2;172;255;240m",
    "$e[38;2;172;252;248m",
    "$e[38;2;172;248;252m",
    "$e[38;2;172;244;255m",
    "$e[38;2;172;238;255m",
    "$e[38;2;174;232;255m",
    "$e[38;2;176;226;255m",
    # Cyan to Blue
    "$e[38;2;178;220;255m",
    "$e[38;2;180;214;255m",
    "$e[38;2;182;208;255m",
    "$e[38;2;184;202;255m",
    "$e[38;2;186;196;255m",
    "$e[38;2;188;192;255m",
    "$e[38;2;190;188;255m",
    "$e[38;2;192;185;255m"
)

$line1 = "  $b$b$b$b$b$b$b$b$b$b   $b$b$b$b$b$b$b$b   $b$b$b$b$b$b$b$b$b  $b$b$b$b$b$b$b$b$b "
$line2 = " $s$s$b$b$b$s$s$s$b$b$b$s$s$b$b$b$s$s$s$s$b$b  $b$b$b$s$s$s$s$s$b$b$b$s$s$b$b$b$s$s$s$b$b$b"
$line3 = "  $s$b$b$b $s$s$b$b$b$s$b$b$b   $s$s$s$s $b$b$b     $s$s$s  $s$b$b$b $s$s$b$b$b "
$line4 = "  $s$b$b$b$b$b$b$b$b $s$b$b$b       $s$b$b$b          $s$b$b$b$b$b$b$b$b  "
$line5 = "  $s$b$b$b$s$s$s$s  $s$b$b$b       $s$b$b$b    $b$b$b$b$b $s$b$b$b$s$b$b$b   "
$line6 = "  $s$b$b$b      $s$s$b$b$b   $s$b$b$s$s$b$b$b $s$s$s$b$b$b  $s$b$b$b$s$s$b$b$b  "
$line7 = "  $b$b$b$b$b      $s$s$b$b$b$b$b$b$b$b $s$s$b$b$b$b$b$b$b$b$b  $b$b$b$b $s$s$b$b$b$b"
$line8 = " $s$s$s$s$s        $s$s$s$s$s$s$s$s$s  $s$s$s$s$s$s$s$s$s  $s$s$s$s$s  $s$s$s$s"
$lines = @($line1, $line2, $line3, $line4, $line5, $line6, $line7, $line8)

Write-Host ""
foreach ($line in $lines) {
    $chars = $line.ToCharArray()
    $len = $chars.Length
    $out = ""
    for ($i = 0; $i -lt $len; $i++) {
        $colorIdx = [Math]::Floor(($i / $len) * $rainbow.Length)
        if ($colorIdx -ge $rainbow.Length) { $colorIdx = $rainbow.Length - 1 }
        $out += $rainbow[$colorIdx] + $chars[$i]
    }
    Write-Host "$out$r"
}
Write-Host ""

# Text lines with same gradient 
$textLines = @("              PC  Gaming  Redists", "     Downloading  installer,  please  wait...")
foreach ($line in $textLines) {
    $chars = $line.ToCharArray()
    $len = $chars.Length
    $out = ""
    for ($i = 0; $i -lt $len; $i++) {
        $colorIdx = [Math]::Floor(($i / $len) * $rainbow.Length)
        if ($colorIdx -ge $rainbow.Length) { $colorIdx = $rainbow.Length - 1 }
        $out += $rainbow[$colorIdx] + $chars[$i]
    }
    Write-Host "$out$r"
}
Write-Host ""

Function Write-Rainbow
{
	Param ([string]$Text)
	$chars = $Text.ToCharArray()
	$len = $chars.Length
	$out = ""
	for ($i = 0; $i -lt $len; $i++) {
		$colorIdx = [Math]::Floor(($i / $len) * $rainbow.Length)
		if ($colorIdx -ge $rainbow.Length) { $colorIdx = $rainbow.Length - 1 }
		$out += $rainbow[$colorIdx] + $chars[$i]
	}
	Write-Host "$out$r"
}

Function Test-CommandExists
{
	Param ($command)
	try { if (Get-Command $command) { RETURN $true } }
	Catch { RETURN $false }
}

Function Test-WingetWorks
{
	# Just check winget runs and returns a version. If it does, trust it.
	# The AIOInstaller has its own retry/source logic that handles actual failures.
	try {
		$version = winget --version 2>&1
		if ($version -match "^v\d+\.\d+") {
			return $true
		}
		return $false
	}
	catch {
		return $false
	}
}

Function Stop-BlockingPackages
{
	Param ([string[]]$PackageNames)

	foreach ($pkgName in $PackageNames) {
		Get-Process | Where-Object { $_.Path -like "*$pkgName*" } | ForEach-Object {
			Write-Rainbow "  Closing $($_.ProcessName)..."
			Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
		}
	}
	Start-Sleep -Seconds 1
}

Function Install-AppxSilent
{
	# Try to install silently - no prompts, just try and move on
	Param ([string]$Path, [string]$DisplayName)

	try {
		Add-AppxPackage -Path $Path -ForceApplicationShutdown -ErrorAction Stop
		return $true
	}
	catch {
		Write-Rainbow "  $DisplayName - skipped (may not be needed on this system)"
		return $false
	}
}

Function Install-AppxWithRetry
{
	# Try to install with interactive prompts on failure - use for critical packages
	Param ([string]$Path, [string]$DisplayName)

	$maxRetries = 2

	for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
		try {
			Add-AppxPackage -Path $Path -ForceApplicationShutdown -ErrorAction Stop
			Write-Rainbow "  $DisplayName installed successfully."
			return $true
		}
		catch {
			$errorMsg = $_.Exception.Message

			# Check if it's the "resources in use" error (0x80073D02)
			if ($errorMsg -match "0x80073D02" -or $errorMsg -match "resources it modifies are currently in use") {
				# Parse out the blocking package names from the error
				$blockingApps = @()
				$lines = $errorMsg -split "`n"
				foreach ($line in $lines) {
					if ($line -match "(Microsoft\.[A-Za-z0-9_.]+)_[\d.]+_") {
						$blockingApps += $matches[1]
					}
					if ($line -match "(MicrosoftWindows\.[A-Za-z0-9_.]+)_[\d.]+_") {
						$blockingApps += $matches[1]
					}
				}
				$blockingApps = $blockingApps | Select-Object -Unique

				if ($blockingApps.Count -gt 0 -and $attempt -lt $maxRetries) {
					Write-Host ""
					Write-Rainbow "The following apps are blocking the installation of $DisplayName :"
					foreach ($app in $blockingApps) {
						Write-Rainbow "  - $app"
					}
					Write-Host ""
					$doClose = $true
					if (-not $script:Unattend) {
						$response = Read-Host "Close these apps to continue? (Y/n)"
						if ($response -notmatch "^[Yy]?" -or $response -match "^[Nn]") {
							$doClose = $false
						}
					}
					if ($doClose) {
						Write-Rainbow "Closing blocking apps..."
						Stop-BlockingPackages -PackageNames $blockingApps
						# Also kill Edge as a precaution
						Get-Process | Where-Object { $_.ProcessName -like "*msedge*" } | Stop-Process -Force -ErrorAction SilentlyContinue
						Start-Sleep -Seconds 2
						continue
					} else {
						Write-Rainbow "Couldn't install $DisplayName - continuing anyway (may not be needed)..."
						return $false
					}
				}
			}

			# Other error or final attempt failed
			if ($attempt -eq $maxRetries) {
				Write-Rainbow "Failed to install $DisplayName"
				Write-Rainbow "  Error: $errorMsg"
				return $false
			}
		}
	}
	return $false
}

Function Update-WingetSources
{
	Write-Rainbow "Updating WinGet sources and accepting agreements..."
	try {
		winget source update --accept-source-agreements 2>&1 | Out-Null
		winget search Microsoft.VCRedist --source winget --accept-source-agreements 2>&1 | Out-Null
	} catch { }
}

Function Test-WingetSearch
{
	try {
		$searchResult = winget search Microsoft.VCRedist.2015+.x64 --source winget 2>&1 | Out-String
		if ($searchResult -match "Microsoft\.VCRedist") {
			return $true
		}
		return $false
	}
	catch {
		return $false
	}
}

Function Install-WingetDependencies
{
	Write-Rainbow "Fixing WinGet..."

	$ProgressPreference = 'SilentlyContinue'
	$tempDir = "$env:TEMP\WinGetBootstrap"
	New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

	$depsZipUrl = "https://github.com/microsoft/winget-cli/releases/latest/download/DesktopAppInstaller_Dependencies.zip"
	$depsZipPath = "$tempDir\Dependencies.zip"
	$depsExtractPath = "$tempDir\Dependencies"

	Write-Rainbow "  Downloading dependencies..."
	try {
		curl.exe -L -s -o $depsZipPath $depsZipUrl
		Expand-Archive -Path $depsZipPath -DestinationPath $depsExtractPath -Force
	} catch { }

	Update-WingetSources
	if (Test-WingetSearch) {
		Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
		return
	}

	# Install VCLibs
	Write-Rainbow "  Installing VCLibs..."
	$vcLibs = Get-ChildItem -Path $depsExtractPath -Recurse -Filter "*VCLibs*x64*.appx" -ErrorAction SilentlyContinue
	foreach ($vc in $vcLibs) {
		Install-AppxSilent -Path $vc.FullName -DisplayName $vc.BaseName | Out-Null
	}

	# Install UI.Xaml
	Write-Rainbow "  Installing UI.Xaml..."
	$uiXaml = Get-ChildItem -Path $depsExtractPath -Recurse -Filter "*UI.Xaml*x64*.appx" -ErrorAction SilentlyContinue | Select-Object -First 1
	if ($uiXaml) {
		Install-AppxSilent -Path $uiXaml.FullName -DisplayName "Microsoft.UI.Xaml" | Out-Null
	} else {
		$uiXamlUrl = "https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.8.6"
		$uiXamlZip = "$tempDir\Microsoft.UI.Xaml.zip"
		$uiXamlExtract = "$tempDir\UIXaml"
		curl.exe -L -s -o $uiXamlZip $uiXamlUrl
		Expand-Archive -Path $uiXamlZip -DestinationPath $uiXamlExtract -Force -ErrorAction SilentlyContinue
		$uiXamlAppx = Get-ChildItem -Path $uiXamlExtract -Recurse -Filter "*x64*.appx" -ErrorAction SilentlyContinue | Select-Object -First 1
		if ($uiXamlAppx) {
			Install-AppxSilent -Path $uiXamlAppx.FullName -DisplayName "Microsoft.UI.Xaml" | Out-Null
		}
	}

	# Download and install WinGet
	Write-Rainbow "  Downloading WinGet..."
	$tempWinget = "$tempDir\getwinget.msixbundle"
	curl.exe -L -s -o $tempWinget "https://aka.ms/getwinget"

	Write-Rainbow "  Installing WinGet..."
	try {
		Add-AppxPackage -Path $tempWinget -ForceApplicationShutdown -ErrorAction Stop
	}
	catch {
		$errorMsg = $_.Exception.Message
		if ($errorMsg -match "Microsoft\.WindowsAppRuntime\.(\d+\.\d+)") {
			$runtimeVersion = $matches[1]
			Write-Rainbow "  Installing WindowsAppRuntime $runtimeVersion..."
			$appRuntimeUrl = "https://aka.ms/windowsappsdk/$runtimeVersion/latest/windowsappruntimeinstall-x64.exe"
			$appRuntimeExe = "$tempDir\WindowsAppRuntimeInstall.exe"
			curl.exe -L -s -o $appRuntimeExe $appRuntimeUrl
			if (Test-Path $appRuntimeExe) {
				Start-Process -FilePath $appRuntimeExe -ArgumentList "--quiet" -Wait -ErrorAction SilentlyContinue
				Write-Rainbow "  Installing WinGet..."
				Add-AppxPackage -Path $tempWinget -ForceApplicationShutdown -ErrorAction SilentlyContinue
			}
		}
	}

	Update-WingetSources
	if (Test-WingetSearch) {
		Write-Rainbow "  WinGet fixed!"
		Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
		return
	}

	# Fallback to GitHub
	Write-Rainbow "  Trying GitHub fallback..."
	$wingetBundleUrl = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
	$wingetBundlePath = "$tempDir\WinGet.msixbundle"
	curl.exe -L -s -o $wingetBundlePath $wingetBundleUrl
	if (Test-Path $wingetBundlePath) {
		Add-AppxPackage -Path $wingetBundlePath -ForceApplicationShutdown -ErrorAction SilentlyContinue
	}

	Update-WingetSources
	if (Test-WingetSearch) {
		Write-Rainbow "  WinGet fixed!"
		Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
		return
	}

	Write-Host ""
	Write-Rainbow "WinGet could not be fixed automatically."
	Write-Rainbow "Report: https://github.com/harryeffinpotter/PC-Gaming-Redists/issues"
	Write-Host ""

	Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = 'stop'

# Check if winget exists AND actually works
$wingetFixRan = $false
if (!(Test-CommandExists winget) -or !(Test-WingetWorks))
{
	$wingetFixRan = $true
	Write-Rainbow "WinGet is missing or not working properly..."
	Write-Rainbow "This is common on fresh Windows 11 installs."
	Write-Host ""
	Write-Rainbow "NOTE: This may need to close Edge, Notepad, MS Store, and other apps to install dependencies."
	Write-Host ""

	Install-WingetDependencies

	# Verify it worked
	Start-Sleep -Seconds 2
	if (Test-WingetWorks) {
		Write-Rainbow "WinGet is now working!"
	} else {
		Write-Rainbow "WinGet may still have issues. Continuing anyway..."
	}
}

$progressPreference = 'silentlyContinue'
try { winget source update --accept-source-agreements 2>&1 | Out-Null } catch { }

$DownloadURL = "$BaseUrl/AIOInstaller.bat"
$FilePath = "$env:TEMP\AIOInstaller.bat"
$MenuURL = "$BaseUrl/pcgr_menu.ps1"
$MenuPath = "$env:TEMP\pcgr_menu.ps1"

try {
	Invoke-WebRequest -Uri $DownloadURL -UseBasicParsing -OutFile $FilePath -ErrorAction Stop
} catch {
	Write-Host "ERROR: Failed to download installer!" -ForegroundColor Red
	Write-Host $_.Exception.Message -ForegroundColor Red
	Stop-Transcript | Out-Null
	if (-not $Unattend) { Read-Host "Press Enter to exit" | Out-Null }
	exit 1
}

try {
	Invoke-WebRequest -Uri $MenuURL -UseBasicParsing -OutFile $MenuPath -ErrorAction Stop
} catch {
	Write-Host "WARNING: Failed to download menu script - options menu will not work" -ForegroundColor Yellow
}

# Fix line endings - GitHub raw serves LF, but batch files need CRLF
try {
	$content = [System.IO.File]::ReadAllText($FilePath)
	$content = $content -replace "`r`n", "`n" -replace "`n", "`r`n"
	[System.IO.File]::WriteAllText($FilePath, $content)
} catch { }

if (!(Test-Path $FilePath)) {
	Write-Host "ERROR: Download succeeded but file not found!" -ForegroundColor Red
	Stop-Transcript | Out-Null
	if (-not $Unattend) { Read-Host "Press Enter to exit" | Out-Null }
	exit 1
}

# Rainbow text for launch message (bold)
$bold = "$e[1m"
if ($Unattend) {
	$launchLines = @("          Launching AIOInstaller (unattended)...")
} elseif ($wingetFixRan) {
	$launchLines = @("Launching Installer Window.", "(Be sure to agree to UAC prompt)")
} else {
	$launchLines = @("          Launching Installer Window.", "        (Be sure to agree to UAC prompt)")
}
foreach ($line in $launchLines) {
    $chars = $line.ToCharArray()
    $len = $chars.Length
    $out = ""
    for ($i = 0; $i -lt $len; $i++) {
        $colorIdx = [Math]::Floor(($i / $len) * $rainbow.Length)
        if ($colorIdx -ge $rainbow.Length) { $colorIdx = $rainbow.Length - 1 }
        $out += $bold + $rainbow[$colorIdx] + $chars[$i]
    }
    Write-Host "$out$r"
}
if (-not $Unattend) { Start-Sleep -Seconds 3 }

# Disable QuickEdit for this session only (doesn't modify registry, safe if script is cancelled)
$QuickEditCode = @"
using System;
using System.Runtime.InteropServices;
public class QuickEdit {
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr GetStdHandle(int nStdHandle);
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);
}
"@
try {
    Add-Type -TypeDefinition $QuickEditCode -Language CSharp -ErrorAction SilentlyContinue
    $handle = [QuickEdit]::GetStdHandle(-10) # STD_INPUT_HANDLE
    $mode = 0
    [void][QuickEdit]::GetConsoleMode($handle, [ref]$mode)
    $mode = $mode -band (-bnot 0x0040) # Disable ENABLE_QUICK_EDIT_MODE
    [void][QuickEdit]::SetConsoleMode($handle, $mode)
} catch { }

# Log file written by AIOInstaller.bat when /Unattend is active
$AIOLog = "$env:TEMP\pcgr_aio_$env:COMPUTERNAME.log"

# Stream AIOInstaller log back to this console while the elevated process runs.
# Used when the batch runs in a separate elevated window (non-admin caller).
function Watch-AIOLog {
    param([string]$LogPath, [System.Diagnostics.Process]$Proc)

    $ansi = [regex]'(\x1b\[[0-9;]*[mKJHfABCDsu]|\r)'
    Write-Host ""
    Write-Host "  [install log stream - Ctrl+C to detach without stopping install]" -ForegroundColor DarkCyan
    Write-Host ""

    # Wait up to 60 s for the log file to be created
    $waited = 0
    while (-not (Test-Path $LogPath) -and $waited -lt 120 -and -not $Proc.HasExited) {
        Start-Sleep -Milliseconds 500
        $waited++
    }

    if (-not (Test-Path $LogPath)) { $Proc.WaitForExit(); return }

    $stream = $null; $reader = $null
    try {
        $stream = [System.IO.File]::Open($LogPath, [System.IO.FileMode]::Open,
                                          [System.IO.FileAccess]::Read,
                                          [System.IO.FileShare]::ReadWrite)
        $reader = New-Object System.IO.StreamReader($stream)

        while (-not $Proc.HasExited) {
            $chunk = $reader.ReadToEnd()
            if ($chunk) { Write-Host ($ansi.Replace($chunk, '')) -NoNewline }
            Start-Sleep -Milliseconds 400
        }
        # Final flush after process exits
        $chunk = $reader.ReadToEnd()
        if ($chunk) { Write-Host ($ansi.Replace($chunk, '')) -NoNewline }
    } finally {
        if ($reader) { $reader.Dispose() }
        if ($stream) { $stream.Dispose() }
    }

    $Proc.WaitForExit()
    Write-Host ""
}

try {
	if ($Unattend -and $isAdmin) {
		# Already elevated (SSH / admin shell / autounattend.xml).
		# Run inline via call operator - stdout goes straight to this console,
		# no separate window spawned, works perfectly over SSH/remote sessions.
		Remove-Item $AIOLog -Force -ErrorAction SilentlyContinue
		& cmd.exe /c "`"$FilePath`" /Unattend"
	} elseif ($Unattend) {
		# Need elevation. ShellExecute "runas" on a .bat file does NOT reliably forward
		# ArgumentList - elevate cmd.exe instead and stream the log back to this window.
		Remove-Item $AIOLog -Force -ErrorAction SilentlyContinue
		$proc = Start-Process -FilePath 'cmd.exe' -Verb RunAs `
		                      -ArgumentList "/c `"$FilePath`" /Unattend" -PassThru
		Watch-AIOLog -LogPath $AIOLog -Proc $proc
		if ($proc.ExitCode -and $proc.ExitCode -ne 0) {
			Write-Host "AIOInstaller exited with code $($proc.ExitCode)" -ForegroundColor Red
			exit $proc.ExitCode
		}
	} else {
		# Interactive mode - original behaviour.
		Start-Process -Verb runAs $FilePath -Wait
	}
} catch {
	Write-Host "ERROR launching installer: $_" -ForegroundColor Red
	if (-not $Unattend) { Read-Host "Press Enter to exit" | Out-Null }
	exit 1
}

# Cleanup
try { Remove-Item $FilePath -Force -ErrorAction SilentlyContinue } catch { }

Write-Host ""
Write-Host "Install.ps1 complete." -ForegroundColor Green
Write-Host "  PS bootstrap log  : $LogFile"
if (Test-Path $AIOLog) {
    Write-Host "  AIOInstaller log  : $AIOLog"
    $done     = ([regex]::Matches((Get-Content $AIOLog -Raw -ErrorAction SilentlyContinue), '\[DONE\]')).Count
    $fail     = ([regex]::Matches((Get-Content $AIOLog -Raw -ErrorAction SilentlyContinue), '\[FAILED\]')).Count
    $uptodate = ([regex]::Matches((Get-Content $AIOLog -Raw -ErrorAction SilentlyContinue), '\[ALREADY UP TO DATE\]')).Count
    $color = if ($fail -gt 0) { 'Red' } else { 'Green' }
    Write-Host "  Result            : $done installed, $uptodate up-to-date, $fail failed" -ForegroundColor $color
}
Stop-Transcript | Out-Null
