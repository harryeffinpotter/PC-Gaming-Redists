Function Test-CommandExists
{
	Param ($command)
	try { if (Get-Command $command) { RETURN $true } }
	Catch { RETURN $false }
}

Function Test-WingetWorks
{
	# Check if winget actually works, not just exists
	# On fresh Win11 installs it may exist but return garbage (just "-")
	# So we do an actual search and verify real results come back
	try {
		# First check version
		$version = winget --version 2>&1
		if ($version -notmatch "^v\d+\.\d+") {
			return $false
		}

		# Now do an actual search - this catches "winget runs but returns nothing"
		$searchResult = winget search Microsoft.VCRedist.2015+.x64 2>&1 | Out-String
		if ($searchResult -match "Microsoft\.VCRedist") {
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
			echo "  Closing $($_.ProcessName)..."
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
		echo "  $DisplayName - skipped (may not be needed on this system)"
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
			echo "  $DisplayName installed successfully."
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
					echo ""
					echo "The following apps are blocking the installation of $DisplayName :"
					foreach ($app in $blockingApps) {
						echo "  - $app"
					}
					echo ""
					$response = Read-Host "Close these apps to continue? (Y/n)"
					if ($response -eq "" -or $response -match "^[Yy]") {
						echo "Closing blocking apps..."
						Stop-BlockingPackages -PackageNames $blockingApps
						# Also kill Edge as a precaution
						Get-Process | Where-Object { $_.ProcessName -like "*msedge*" } | Stop-Process -Force -ErrorAction SilentlyContinue
						Start-Sleep -Seconds 2
						continue
					} else {
						echo "Couldn't install $DisplayName - continuing anyway (may not be needed)..."
						return $false
					}
				}
			}

			# Other error or final attempt failed
			if ($attempt -eq $maxRetries) {
				echo "Failed to install $DisplayName"
				return $false
			}
		}
	}
	return $false
}

Function Update-WingetSources
{
	echo "Updating WinGet sources and accepting agreements..."
	try {
		winget source update --accept-source-agreements 2>&1 | Out-Null
		winget search Microsoft.VCRedist --accept-source-agreements 2>&1 | Out-Null
	} catch { }
}

Function Test-WingetSearch
{
	try {
		$searchResult = winget search Microsoft.VCRedist.2015+.x64 2>&1 | Out-String
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
	echo "Attempting to fix WinGet..."
	echo ""

	$ProgressPreference = 'SilentlyContinue'
	$tempDir = "$env:TEMP\WinGetBootstrap"
	New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

	# Download dependencies zip upfront
	$depsZipUrl = "https://github.com/microsoft/winget-cli/releases/latest/download/DesktopAppInstaller_Dependencies.zip"
	$depsZipPath = "$tempDir\Dependencies.zip"
	$depsExtractPath = "$tempDir\Dependencies"

	echo "Downloading dependencies from Microsoft..."
	try {
		curl.exe -L -s -o $depsZipPath $depsZipUrl
		Expand-Archive -Path $depsZipPath -DestinationPath $depsExtractPath -Force
	} catch {
		echo "Failed to download dependencies"
	}

	# STEP 1: Update sources and test
	Update-WingetSources
	if (Test-WingetSearch) {
		echo "WinGet is working!"
		Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
		return
	}

	# STEP 2: Install WindowsAppRuntime, then getwinget
	echo "WinGet not working. Installing WindowsAppRuntime..."
	$appRuntime = Get-ChildItem -Path $depsExtractPath -Recurse -Filter "*WindowsAppRuntime*x64*.msix" -ErrorAction SilentlyContinue | Select-Object -First 1
	if ($appRuntime) {
		Install-AppxWithRetry -Path $appRuntime.FullName -DisplayName "WindowsAppRuntime"
	}

	echo "Installing WinGet from aka.ms..."
	$tempWinget = "$tempDir\getwinget.msixbundle"
	curl.exe -L -s -o $tempWinget "https://aka.ms/getwinget"
	Install-AppxWithRetry -Path $tempWinget -DisplayName "WinGet"

	# Test again
	Update-WingetSources
	if (Test-WingetSearch) {
		echo "WinGet is working!"
		Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
		return
	}

	# STEP 3: Try VCLibs
	echo "Still not working. Installing VCLibs..."
	$vcLibs = Get-ChildItem -Path $depsExtractPath -Recurse -Filter "*VCLibs*x64*.appx" -ErrorAction SilentlyContinue
	foreach ($vc in $vcLibs) {
		Install-AppxWithRetry -Path $vc.FullName -DisplayName $vc.BaseName
	}

	# Test again
	Update-WingetSources
	if (Test-WingetSearch) {
		echo "WinGet is working!"
		Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
		return
	}

	# STEP 4: Try the msixbundle
	echo "Still not working. Trying WinGet msixbundle..."
	$wingetBundleUrl = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
	$wingetBundlePath = "$tempDir\WinGet.msixbundle"
	curl.exe -L -s -o $wingetBundlePath $wingetBundleUrl
	Install-AppxWithRetry -Path $wingetBundlePath -DisplayName "WinGet Bundle"

	# Final test
	Update-WingetSources
	if (Test-WingetSearch) {
		echo "WinGet is working!"
		Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
		return
	}

	# FAILED - tell user to report
	echo ""
	echo "============================================"
	echo "  WinGet could not be fixed automatically"
	echo "============================================"
	echo ""
	echo "Please report this issue at:"
	echo "  https://github.com/harryeffinpotter/PC-Gaming-Redists/issues"
	echo ""
	echo "Include your Windows version and any error messages."
	echo ""

	Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = 'stop'

# Check if winget exists AND actually works
if (!(Test-CommandExists winget) -or !(Test-WingetWorks))
{
	echo "WinGet is missing or not working properly..."
	echo "This is common on fresh installs."
	echo ""
	echo "NOTE: This may need to close Edge, Notepad, MS Store, and other apps to install dependencies."
	echo ""

	Install-WingetDependencies

	# Verify it worked
	Start-Sleep -Seconds 2
	if (Test-WingetWorks) {
		echo "WinGet is now working!"
	} else {
		echo "WinGet may still have issues. Continuing anyway..."
	}
}

try
{
	echo "Updating winget sources..."
	echo ""
	$progressPreference = 'silentlyContinue'
	winget source update --accept-source-agreements 2>&1 | Out-Null
}
catch
{
	echo "Winget sources already up to date or update failed."
}
echo "Downloading script..."
$DownloadURL = 'https://github.com/harryeffinpotter/PC-Gaming-Redists-AIO/raw/main/AIOInstaller.bat'

$FilePath = "$env:TEMP\AIOInstaller.bat"

try
{
	Invoke-WebRequest -Uri $DownloadURL -UseBasicParsing -OutFile $FilePath
}
catch
{
	Invoke-WebRequest -Uri $DownloadURL -UseBasicParsing -OutFile $FilePath
	Return
}
try
{
if (Test-Path $FilePath)
{
	Start-Process -Verb runAs $FilePath -Wait
	$item = Get-Item -LiteralPath $FilePath
	$item.Delete()
}
}
catch
{
Start-Process -Verb runAs $FilePath -Wait
	$item = Get-Item -LiteralPath $FilePath
	$item.Delete()
 }
