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
		name = 'spicetify'
		aliases = @('s')
		summary = 'Install Spicetify'
		usage = 'eagle spicetify'
	}
}

$installUrl = 'https://raw.githubusercontent.com/spicetify/cli/main/install.ps1'

Write-Host ''
Write-Host 'Installing Spicetify...' -ForegroundColor Cyan
Write-Host "Fetching installer: $installUrl" -ForegroundColor DarkGray

try {
	$scriptContent = Invoke-WebRequest -UseBasicParsing -Uri $installUrl -ErrorAction Stop
	Invoke-Expression $scriptContent.Content
	Write-Host 'Spicetify installed successfully.' -ForegroundColor Green
}
catch {
	Write-Host "Spicetify install failed: $_" -ForegroundColor DarkRed
	exit 1
}
