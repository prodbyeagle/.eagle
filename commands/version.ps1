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
		name = 'version'
		aliases = @('v', '-v', '--version')
		summary = 'Show the current version'
		usage = 'eagle version'
	}
}

$version = '0.0.0'
if ($context -and $context.version) {
	$version = $context.version
}

Write-Host ''
Write-Host "eagle $version" -ForegroundColor Yellow
if ($context -and $context.repoUrl) {
	Write-Host $context.repoUrl -ForegroundColor DarkGray
}
