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
		name = 'eaglecord'
		aliases = @('e', 'e:dev')
		summary = 'Install or update EagleCord'
		usage = 'eagle eaglecord [--reinstall]'
	}
}

function Has-Arg {
	param (
		[Parameter(Mandatory = $true)]
		[string]$Name,

		[Parameter(Mandatory = $true)]
		[string[]]$Args
	)

	return $Args -contains $Name
}

$reinstall = $false
if ($context -and $context.invokedAs -eq 'e:dev') {
	$reinstall = $true
}
if (Has-Arg -Name '--reinstall' -Args $argv) {
	$reinstall = $true
}
if (Has-Arg -Name '--re' -Args $argv) {
	$reinstall = $true
}

$repoUrl = 'https://github.com/prodbyeagle/cord'
$repoName = 'Vencord'
$tempRoot = Join-Path $env:APPDATA 'EagleCord'
$cloneDir = Join-Path $tempRoot $repoName

function Ensure-Bun {
	Write-Host 'Checking for Bun runtime...' -ForegroundColor Cyan

	bun --version > $null 2>&1
	if ($LASTEXITCODE -eq 0) {
		Write-Host 'Bun is installed.' -ForegroundColor Green
		return
	}

	Write-Host 'Bun not found. Installing Bun...' -ForegroundColor Yellow
	powershell -NoProfile -Command 'irm bun.sh/install.ps1 | iex'

	$env:PATH = [Environment]::GetEnvironmentVariable('Path', 'User')
	bun --version > $null 2>&1
	if ($LASTEXITCODE -ne 0) {
		throw 'Bun install did not succeed.'
	}
}

function Ensure-Git {
	git --version > $null 2>&1
	if ($LASTEXITCODE -ne 0) {
		throw 'git not found. Install git and try again.'
	}
}

Ensure-Git
Ensure-Bun

New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

Push-Location
try {
	if ($reinstall -and (Test-Path $cloneDir)) {
		Write-Host "Reinstall requested. Removing: $cloneDir" -ForegroundColor Yellow
		Remove-Item -Recurse -Force -Path $cloneDir
	}

	if (Test-Path $cloneDir) {
		Set-Location -Path $cloneDir
		$localHash = git rev-parse HEAD
		$remoteHash = git ls-remote $repoUrl HEAD | ForEach-Object {
			($_ -split "`t")[0]
		}

		if ($localHash -eq $remoteHash) {
			Write-Host "Repo is up-to-date ($localHash)" -ForegroundColor Green
		}
		else {
			Write-Host 'Updating repo to latest commit...' -ForegroundColor Yellow
			git fetch origin
			git reset --hard origin/main
		}
	}
	else {
		Write-Host 'Cloning repo...' -ForegroundColor Yellow
		git clone $repoUrl $cloneDir
		Set-Location -Path $cloneDir
	}

	if (Test-Path '.\\dist') {
		Write-Host 'Cleaning dist folder...' -ForegroundColor DarkGray
		Remove-Item -Recurse -Force '.\\dist'
	}

	$discordTypesPath = Join-Path $cloneDir 'packages\\discord-types'
	if (Test-Path $discordTypesPath) {
		Write-Host 'Linking @vencord/discord-types...' -ForegroundColor Cyan
		Push-Location $discordTypesPath
		try {
			bun link
		}
		finally {
			Pop-Location
		}
	}

	Write-Host 'Installing dependencies...' -ForegroundColor Cyan
	bun install

	Write-Host 'Building...' -ForegroundColor Cyan
	bun run build

	Write-Host 'Injecting...' -ForegroundColor Cyan
	bun inject

	Write-Host 'EagleCord complete.' -ForegroundColor Green
}
finally {
	Pop-Location
}
