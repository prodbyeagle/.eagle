param(
	# If set, bumps Cargo.toml to this version, commits, then tags/releases.
	[string]$SetVersion,
	[switch]$SkipChecks,
	[switch]$Force,
	[switch]$DryRun,
	[string]$Remote = 'origin',
	[string]$Branch = 'main'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Invoke-Checked {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Exe,
		[Parameter(Mandatory = $true)]
		[string[]]$Args
	)

	if ($DryRun) {
		Write-Host ('DRYRUN: ' + $Exe + ' ' + ($Args -join ' '))
		return
	}

	& $Exe @Args
	if ($LASTEXITCODE -ne 0) {
		throw ('Command failed: ' + $Exe + ' ' + ($Args -join ' '))
	}
}

function Assert-Semver {
	param([string]$Version)

	if ($Version -notmatch '^\d+\.\d+\.\d+$') {
		throw ('Invalid semver: ' + $Version)
	}
}

function Assert-RepoClean {
	$dirty = (& git status --porcelain)
	if ($dirty -and -not $Force) {
		$lines = ($dirty | Out-String).Trim()
		throw ("Working tree is dirty. Commit/stash or pass -Force.`n$lines")
	}
}

function Assert-OnBranch {
	param([string]$Expected)

	$branch = (& git rev-parse --abbrev-ref HEAD).Trim()
	if ($branch -ne $Expected -and -not $Force) {
		throw ("Not on $Expected (current: $branch). Pass -Force to override.")
	}
}

function Assert-TagDoesNotExist {
	param([string]$Tag)

	& git show-ref --tags --verify --quiet ("refs/tags/" + $Tag)
	if ($LASTEXITCODE -eq 0) {
		throw ('Tag already exists: ' + $Tag)
	}
}

function Get-CargoPackageVersion {
	param([string]$Path)

	$lines = Get-Content -LiteralPath $Path

	$inPackage = $false
	foreach ($line in $lines) {
		if ($line -match '^\s*\[package\]\s*$') {
			$inPackage = $true
			continue
		}

		if ($inPackage -and $line -match '^\s*\[.+\]\s*$') {
			break
		}

		if ($inPackage -and $line -match '^\s*version\s*=\s*\"([^\"]+)\"\s*$') {
			return $Matches[1]
		}
	}

	throw ('Could not find [package] version in ' + $Path)
}

function Set-CargoPackageVersion {
	param(
		[string]$Path,
		[string]$NewVersion
	)

	if ($DryRun) {
		Write-Host ('DRYRUN: set ' + $Path + ' version = ' + $NewVersion)
		return
	}

	$lines = Get-Content -LiteralPath $Path
	$pkgIndex = -1

	for ($i = 0; $i -lt $lines.Count; $i++) {
		if ($lines[$i] -match '^\s*\[package\]\s*$') {
			$pkgIndex = $i
			break
		}
	}

	if ($pkgIndex -lt 0) {
		throw ('[package] section not found in ' + $Path)
	}

	$endIndex = $lines.Count
	for ($i = $pkgIndex + 1; $i -lt $lines.Count; $i++) {
		if ($lines[$i] -match '^\s*\[.+\]\s*$') {
			$endIndex = $i
			break
		}
	}

	$updated = $false
	for ($i = $pkgIndex + 1; $i -lt $endIndex; $i++) {
		if ($lines[$i] -match '^\s*version\s*=\s*\"[^\"]+\"\s*$') {
			$lines[$i] = ('version = "' + $NewVersion + '"')
			$updated = $true
			break
		}
	}

	if (-not $updated) {
		throw ('version = "..." not found in [package] section in ' + $Path)
	}

	Set-Content -LiteralPath $Path -Value $lines -Encoding utf8
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $repoRoot

Assert-OnBranch $Branch
Assert-RepoClean

Write-Host '== Fetch tags =='
Invoke-Checked -Exe 'git' -Args @('fetch', '--tags', $Remote)

if ($SetVersion) {
	Assert-Semver $SetVersion
	Write-Host ('== Bump Cargo.toml to ' + $SetVersion + ' ==')
	Set-CargoPackageVersion -Path 'Cargo.toml' -NewVersion $SetVersion
}

if (-not $SkipChecks) {
	Write-Host '== Checks =='
	Invoke-Checked -Exe 'powershell' -Args @(
		'-NoProfile',
		'-ExecutionPolicy',
		'Bypass',
		'-File',
		'.\\scripts\\check.ps1'
	)
}

$version = Get-CargoPackageVersion 'Cargo.toml'
Assert-Semver $version
$tag = ('v' + $version)

Write-Host ('== Tag target: ' + $tag + ' ==')
Assert-TagDoesNotExist $tag

if ($SetVersion) {
	Write-Host '== Commit version bump =='
	Invoke-Checked -Exe 'git' -Args @('add', 'Cargo.toml', 'Cargo.lock')
	Invoke-Checked -Exe 'git' -Args @('commit', '-m', ('chore: release ' + $tag))
}

Write-Host ('== Create tag ' + $tag + ' ==')
Invoke-Checked -Exe 'git' -Args @('tag', '-a', $tag, '-m', $tag)

Write-Host '== Push (triggers .github/workflows/release.yml) =='
Invoke-Checked -Exe 'git' -Args @('push', $Remote, $Branch)
Invoke-Checked -Exe 'git' -Args @('push', $Remote, $tag)

if ($DryRun) {
	Write-Host ('Dry run complete: ' + $tag)
} else {
	Write-Host ('Release pushed: ' + $tag)
}
