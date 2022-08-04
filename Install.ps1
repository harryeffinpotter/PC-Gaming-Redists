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

echo "Downloading script..."
$DownloadURL = 'https://github.com/harryeffinpotter/PC-Gaming-Redists-AIO/raw/main/AIOInstaller.bat'

$FilePath = "$env:TEMP\AIOInstaller.bat"

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
	Start-Process -Verb runAs $FilePath -Wait
	$item = Get-Item -LiteralPath $FilePath
	$item.Delete()
}