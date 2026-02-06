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
		name = 'example'
		aliases = @('ex')
		summary = 'One-line description'
		usage = 'eagle example [args]'
	}
}

# Implement your command here.
# - Use $argv for args
# - Use $context.version / $context.scriptDir if needed

Write-Host 'Not implemented.' -ForegroundColor DarkRed
exit 1
