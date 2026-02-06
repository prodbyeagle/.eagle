param (
	[switch]$Dev
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptsRoot = 'C:\\Scripts'
$installDir = Join-Path $scriptsRoot 'eagle'
$zipUrl = `
	'https://github.com/prodbyeagle/eaglePowerShell/archive/refs/heads/main.zip'

$tempZipPath = Join-Path $env:TEMP 'eagle_install.zip'
$tempExtractPath = Join-Path $env:TEMP 'eagle_install'

function Log {
	param (
		[Parameter(Mandatory = $true)]
		[string]$Message,

		[ConsoleColor]$Color = 'Gray'
	)

	Write-Host $Message -ForegroundColor $Color
}

function Ensure-Directory {
	param (
		[Parameter(Mandatory = $true)]
		[string]$Path
	)

	if (-not (Test-Path $Path)) {
		New-Item -ItemType Directory -Path $Path -Force | Out-Null
	}
}

function Copy-InstallTree {
	param (
		[Parameter(Mandatory = $true)]
		[string]$FromDir,

		[Parameter(Mandatory = $true)]
		[string]$ToDir
	)

	$items = @('eagle.ps1', 'version.txt', 'commands', 'lib')
	foreach ($item in $items) {
		$src = Join-Path $FromDir $item
		$dst = Join-Path $ToDir $item

		if (-not (Test-Path $src)) {
			continue
		}

		if (Test-Path $dst) {
			Remove-Item -Recurse -Force $dst
		}

		Copy-Item -Path $src -Destination $dst -Recurse -Force
	}
}

Log 'Starting eagle install...' 'White'

Ensure-Directory -Path $scriptsRoot
Ensure-Directory -Path $installDir

if ($Dev) {
	Log 'Installing from local files (Dev mode)...' 'Yellow'
	Copy-InstallTree -FromDir $PSScriptRoot -ToDir $installDir
}
else {
	Log 'Downloading release zip...' 'Cyan'

	if (Test-Path $tempZipPath) {
		Remove-Item -Force $tempZipPath
	}
	if (Test-Path $tempExtractPath) {
		Remove-Item -Recurse -Force $tempExtractPath
	}

	Invoke-WebRequest -Uri $zipUrl -OutFile $tempZipPath `
		-UseBasicParsing -ErrorAction Stop

	Expand-Archive -Path $tempZipPath -DestinationPath $tempExtractPath -Force

	$root = Get-ChildItem -Path $tempExtractPath -Directory | Select-Object -First 1
	if (-not $root) {
		throw 'Zip did not contain a root directory.'
	}

	Copy-InstallTree -FromDir $root.FullName -ToDir $installDir
}

Log "Installed to: $installDir" 'Green'

if (-not (Test-Path $PROFILE)) {
	New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}

$aliasLine = "Set-Alias eagle `"$installDir\\eagle.ps1`""
if (-not (Select-String -Path $PROFILE -Pattern ([regex]::Escape($aliasLine)) -Quiet)) {
	Add-Content -Path $PROFILE -Value "`n$aliasLine"
	Log 'Alias added: eagle' 'Green'
}
else {
	Log 'Alias already present, skipping.' 'DarkGray'
}

$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath -notlike "*$scriptsRoot*") {
	[Environment]::SetEnvironmentVariable(
		'Path',
		"$userPath;$scriptsRoot",
		'User'
	)
	Log "Added to PATH: $scriptsRoot" 'Green'
}
else {
	Log 'PATH already contains C:\\Scripts.' 'DarkGray'
}

if (-not $Dev) {
	Remove-Item -Path $tempZipPath -Force -ErrorAction SilentlyContinue
	Remove-Item -Path $tempExtractPath -Recurse -Force `
		-ErrorAction SilentlyContinue
}

Log 'Done. Restart PowerShell to use eagle.' 'Cyan'
