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
		name = 'uninstall'
		aliases = @('rem')
		summary = 'Uninstall eagle (installed copy)'
		usage = 'eagle uninstall [--force]'
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

$installDir = $null
if ($context -and $context.scriptDir) {
	$installDir = $context.scriptDir
}
if (-not $installDir) {
	throw 'Missing context.scriptDir'
}

if ((Test-Path (Join-Path $installDir '.git')) -and -not $force) {
	Write-Host 'Refusing to uninstall inside a git repo.' -ForegroundColor Yellow
	Write-Host 'Run: eagle uninstall --force (or remove manually).' `
		-ForegroundColor DarkGray
	exit 1
}

$isSafeInstallDir = $false
if (Test-Path (Join-Path $installDir 'version.txt')) {
	if (Test-Path (Join-Path $installDir 'commands')) {
		$isSafeInstallDir = $true
	}
}

if (-not $isSafeInstallDir -and -not $force) {
	Write-Host "Refusing to uninstall from: $installDir" -ForegroundColor Yellow
	Write-Host 'Run: eagle uninstall --force if you are sure.' `
		-ForegroundColor DarkGray
	exit 1
}

Write-Host 'You are about to uninstall eagle.' -ForegroundColor Yellow
$confirmation = Read-Host 'Continue? (y/n)'
if ($confirmation.ToLower() -notin @('y', 'yes')) {
	Write-Host 'Uninstall cancelled.' -ForegroundColor DarkRed
	exit 0
}

if (Test-Path $installDir) {
	Remove-Item -Recurse -Force $installDir
	Write-Host "Removed: $installDir" -ForegroundColor Green
}

if (Test-Path $PROFILE) {
	$profileContent = Get-Content -Path $PROFILE
	$filtered = $profileContent | Where-Object { $_ -notmatch 'Set-Alias\\s+eagle' }
	Set-Content -Path $PROFILE -Value $filtered
	Write-Host 'Removed alias from PowerShell profile.' -ForegroundColor Green
}

Write-Host 'Uninstall complete.' -ForegroundColor Green
