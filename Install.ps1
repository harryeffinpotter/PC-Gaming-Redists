Function Test-CommandExists
{
	Param ($command)
	try { if (Get-Command $command) { RETURN $true } }
	Catch { RETURN $false }
}

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = 'stop'

if (!(Test-CommandExists winget))
{
	echo "Installing latest winget..."
	$DownloadURL = 'https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'

	$FilePath = "$env:TEMP\WinGet.msixbundle"

	try
	{
		Invoke-WebRequest -Uri $DownloadURL -UseBasicParsing -OutFile $FilePath
	}
	catch
	{
		Write-Error $_
		Return
	}

	if (Test-Path $FilePath)
	{
		Add-AppxPackage $FilePath
		$item = Get-Item -LiteralPath $FilePath
		$item.Delete()
	}
}
try
{
	echo "Updating winget sources..."
	echo ""
	$progressPreference = 'silentlyContinue'
	$latestWingetMsixBundleUri = $(Invoke-RestMethod https://api.github.com/repos/microsoft/winget-cli/releases/latest).assets.browser_download_url | Where-Object {$_.EndsWith(".msixbundle")}
	$latestWingetMsixBundle = $latestWingetMsixBundleUri.Split("/")[-1]
	Write-Information "Downloading winget to artifacts directory..."
	Invoke-WebRequest -Uri $latestWingetMsixBundleUri -OutFile "./$latestWingetMsixBundle"
	Invoke-WebRequest -Uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -OutFile Microsoft.VCLibs.x64.14.00.Desktop.appx
	Add-AppxPackage Microsoft.VCLibs.x64.14.00.Desktop.appx
	Add-AppxPackage $latestWingetMsixBundle
	timeout /t 3 /nobreak
	clear
}
catch
{
	echo "Winget sources already up to date."
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

if (Test-Path $FilePath)
{
	Start-Process -Verb runAs $FilePath -Wait
	$item = Get-Item -LiteralPath $FilePath
	$item.Delete()
}
