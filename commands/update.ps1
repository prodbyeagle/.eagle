param (
	[Parameter(Mandatory = $true)]
	[ValidateSet('manifest', 'run')]
	[string]$mode,

	[hashtable]$context,

	[string[]]$argv = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($mode -eq 'manifest') {
	return @{
		name = 'update'
		aliases = @('u')
		summary = 'Update eagle in place (installed copy)'
		usage = 'eagle update [--force]'
	}
}

function Has-Flag {
	param (
		[Parameter(Mandatory = $true)]
		[string]$Name,

		[Parameter(Mandatory = $true)]
		[string[]]$Args
	)

	return $Args -contains $Name
}

$force = Has-Flag -Name '--force' -Args $argv

$scriptDir = $null
if ($context -and $context.scriptDir) {
	$scriptDir = $context.scriptDir
}
if (-not $scriptDir) {
	throw 'Missing context.scriptDir'
}

$localVersion = '0.0.0'
if ($context -and $context.version) {
	$localVersion = $context.version
}

if ((Test-Path (Join-Path $scriptDir '.git')) -and -not $force) {
	Write-Host 'Refusing to self-update inside a git repo.' -ForegroundColor Yellow
	Write-Host 'Run: eagle update --force (or update via git).' `
		-ForegroundColor DarkGray
	exit 1
}

$remoteZipUrl = `
	'https://github.com/prodbyeagle/eaglePowerShell/archive/refs/heads/main.zip'

$tempZipPath = Join-Path $env:TEMP 'eagle_update.zip'
$tempExtractPath = Join-Path $env:TEMP 'eagle_update'

Write-Host 'Checking for updates...' -ForegroundColor Cyan

try {
	if (Test-Path $tempZipPath) {
		Remove-Item -Force $tempZipPath
	}
	if (Test-Path $tempExtractPath) {
		Remove-Item -Recurse -Force $tempExtractPath
	}

	Invoke-WebRequest -Uri $remoteZipUrl -OutFile $tempZipPath `
		-UseBasicParsing -ErrorAction Stop

	Expand-Archive -Path $tempZipPath -DestinationPath $tempExtractPath -Force

	$remoteRoot = Get-ChildItem -Path $tempExtractPath -Directory |
		Select-Object -First 1

	if (-not $remoteRoot) {
		throw 'Remote zip did not contain a root directory.'
	}

	$remoteVersionPath = Join-Path $remoteRoot.FullName 'version.txt'
	if (-not (Test-Path $remoteVersionPath)) {
		throw 'Remote version.txt not found.'
	}

	$remoteVersion = (Get-Content -Path $remoteVersionPath -TotalCount 1).Trim()
	if ([version]$remoteVersion -le [version]$localVersion) {
		Write-Host "Already up-to-date ($localVersion)." -ForegroundColor Green
		return
	}

	Write-Host "Updating $localVersion -> $remoteVersion" -ForegroundColor Yellow

	$copyTargets = @(
		@{ src = 'eagle.ps1'; dst = 'eagle.ps1' },
		@{ src = 'version.txt'; dst = 'version.txt' },
		@{ src = 'commands'; dst = 'commands' },
		@{ src = 'lib'; dst = 'lib' }
	)

	foreach ($t in $copyTargets) {
		$src = Join-Path $remoteRoot.FullName $t.src
		$dst = Join-Path $scriptDir $t.dst

		if (-not (Test-Path $src)) {
			continue
		}

		if (Test-Path $dst) {
			Remove-Item -Recurse -Force $dst
		}

		Copy-Item -Path $src -Destination $dst -Recurse -Force
	}

	Write-Host 'Update complete.' -ForegroundColor Green
}
finally {
	Remove-Item -Path $tempZipPath -Force -ErrorAction SilentlyContinue
	Remove-Item -Path $tempExtractPath -Recurse -Force `
		-ErrorAction SilentlyContinue
}

