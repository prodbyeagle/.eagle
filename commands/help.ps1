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
		name = 'help'
		aliases = @('h', '-h', '--h', '--help', '/?')
		summary = 'Show help'
		usage = 'eagle help [command]'
	}
}

function Write-Header {
	param (
		[Parameter(Mandatory = $true)]
		[string]$Version
	)

	Write-Host ''
	Write-Host "eagle $Version" -ForegroundColor Yellow
	Write-Host 'Usage: eagle <command> [args]' -ForegroundColor Gray
	Write-Host ''
}

function Write-CommandList {
	param (
		[Parameter(Mandatory = $true)]
		[object[]]$Manifests
	)

	if (-not $Manifests -or $Manifests.Count -eq 0) {
		Write-Host 'No commands found.' -ForegroundColor DarkRed
		return
	}

	$rows = $Manifests | Where-Object { $_.name -ne 'help' }
	$rows = @($rows | Sort-Object name)

	$nameWidth = 0
	foreach ($r in $rows) {
		$nameWidth = [Math]::Max($nameWidth, $r.name.Length)
	}
	$nameWidth = [Math]::Min([Math]::Max($nameWidth, 7), 20)

	Write-Host 'Commands:' -ForegroundColor Cyan
	foreach ($r in $rows) {
		$summary = $r.summary
		if (-not $summary) {
			$summary = ''
		}

		$line = ('{0,-' + $nameWidth + '}  {1}') -f $r.name, $summary
		Write-Host "  $line"
	}

	Write-Host ''
	Write-Host 'Run: eagle help <command> for details.' -ForegroundColor DarkGray
}

function Write-CommandDetails {
	param (
		[Parameter(Mandatory = $true)]
		[object]$Manifest
	)

	Write-Host "Command: $($Manifest.name)" -ForegroundColor Cyan

	if ($Manifest.usage) {
		Write-Host "Usage:   $($Manifest.usage)" -ForegroundColor Gray
	}

	if ($Manifest.aliases -and $Manifest.aliases.Count -gt 0) {
		$aliasList = $Manifest.aliases -join ', '
		Write-Host "Aliases: $aliasList" -ForegroundColor Gray
	}

	if ($Manifest.summary) {
		Write-Host ''
		Write-Host $Manifest.summary
	}
}

function Resolve-Manifest {
	param (
		[Parameter(Mandatory = $true)]
		[string]$InputCommand,

		[Parameter(Mandatory = $true)]
		[object[]]$Manifests
	)

	$needle = $InputCommand.ToLower()
	foreach ($m in $Manifests) {
		if ($m.name -eq $needle) {
			return $m
		}

		if ($m.aliases -contains $needle) {
			return $m
		}
	}

	return $null
}

$version = '0.0.0'
if ($context -and $context.version) {
	$version = $context.version
}

Write-Header -Version $version

$manifests = @()
if ($context -and $context.manifests) {
	$manifests = @($context.manifests)
}

if ($argv -and $argv.Count -gt 0) {
	$target = $argv[0]
	$resolved = Resolve-Manifest -InputCommand $target -Manifests $manifests
	if (-not $resolved) {
		Write-Host "Unknown command: '$target'" -ForegroundColor DarkRed
		exit 1
	}

	Write-CommandDetails -Manifest $resolved
	exit 0
}

Write-CommandList -Manifests $manifests
