param (
	[switch]$Dev
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptsRoot = 'C:\Scripts'
$installExe = Join-Path $scriptsRoot 'eagle.exe'

$releaseExeUrl = `
	'https://github.com/prodbyeagle/eaglePowerShell/releases/latest/download/eagle.exe'

$sourceZipUrl = `
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

function Invoke-DownloadFile {
	param (
		[Parameter(Mandatory = $true)]
		[string]$Uri,

		[Parameter(Mandatory = $true)]
		[string]$OutFile
	)

	Invoke-WebRequest -Uri $Uri -OutFile $OutFile -UseBasicParsing `
		-ErrorAction Stop
}

function Test-Cargo {
	cargo --version > $null 2>&1
	return $LASTEXITCODE -eq 0
}

function Install-FromRelease {
	param (
		[Parameter(Mandatory = $true)]
		[string]$Uri,

		[Parameter(Mandatory = $true)]
		[string]$OutFile
	)

	Log "Downloading: $Uri" 'Cyan'
	Invoke-DownloadFile -Uri $Uri -OutFile $OutFile
}

function Install-FromSourceZip {
	param (
		[Parameter(Mandatory = $true)]
		[string]$Uri,

		[Parameter(Mandatory = $true)]
		[string]$OutFile
	)

	if (-not (Test-Cargo)) {
		throw 'cargo not found. Install Rust (rustup) or use a release build.'
	}

	if (Test-Path $tempZipPath) {
		Remove-Item -Force $tempZipPath
	}
	if (Test-Path $tempExtractPath) {
		Remove-Item -Recurse -Force $tempExtractPath
	}

	Log 'Downloading source zip...' 'Cyan'
	Invoke-DownloadFile -Uri $Uri -OutFile $tempZipPath

	Log 'Extracting...' 'DarkGray'
	Expand-Archive -Path $tempZipPath -DestinationPath $tempExtractPath -Force

	$root = Get-ChildItem -Path $tempExtractPath -Directory | Select-Object -First 1
	if (-not $root) {
		throw 'Zip did not contain a root directory.'
	}

	Log 'Building (cargo build --release)...' 'Yellow'
	Push-Location $root.FullName
	try {
		cargo build --release
		if ($LASTEXITCODE -ne 0) {
			throw 'cargo build failed.'
		}

		$builtExe = Join-Path $root.FullName 'target\release\eagle.exe'
		if (-not (Test-Path $builtExe)) {
			throw "Built exe not found: $builtExe"
		}

		Copy-Item -Force $builtExe $OutFile
	}
	finally {
		Pop-Location
	}
}

Log 'Starting eagle install...' 'White'

Ensure-Directory -Path $scriptsRoot

if ($Dev) {
	Log 'Dev mode: building from local repo...' 'Yellow'

	if (-not (Test-Cargo)) {
		throw 'cargo not found. Install Rust (rustup) to build locally.'
	}

	Push-Location $PSScriptRoot
	try {
		cargo build --release
		if ($LASTEXITCODE -ne 0) {
			throw 'cargo build failed.'
		}

		$builtExe = Join-Path $PSScriptRoot 'target\release\eagle.exe'
		if (-not (Test-Path $builtExe)) {
			throw "Built exe not found: $builtExe"
		}

		Copy-Item -Force $builtExe $installExe
	}
	finally {
		Pop-Location
	}
}
else {
	try {
		Install-FromRelease -Uri $releaseExeUrl -OutFile $installExe
	}
	catch {
		Log 'Release download failed. Falling back to source build...' `
			'Yellow'
		Install-FromSourceZip -Uri $sourceZipUrl -OutFile $installExe
	}
}

Log "Installed: $installExe" 'Green'

if (-not (Test-Path $PROFILE)) {
	New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}

$aliasLine = "Set-Alias eagle `"$installExe`""
$profileContent = Get-Content -Path $PROFILE -ErrorAction SilentlyContinue
if (-not $profileContent) {
	$profileContent = @()
}

$filtered = $profileContent | Where-Object {
	$_ -notmatch '^\s*Set-Alias\s+eagle\s+'
}

$needsWrite = $true
foreach ($line in $filtered) {
	if ($line -eq $aliasLine) {
		$needsWrite = $false
	}
}

if ($needsWrite) {
	Set-Content -Path $PROFILE -Value @($filtered + '' + $aliasLine)
	Log 'Alias updated: eagle' 'Green'
}
else {
	Log 'Alias already correct, skipping.' 'DarkGray'
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
	Log 'PATH already contains C:\Scripts.' 'DarkGray'
}

Remove-Item -Path $tempZipPath -Force -ErrorAction SilentlyContinue
Remove-Item -Path $tempExtractPath -Recurse -Force `
	-ErrorAction SilentlyContinue

Log 'Done. Restart PowerShell to use eagle.' 'Cyan'
