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
		name = 'eagle'
		aliases = @()
		summary = 'Tiny terminal animation'
		usage = 'eagle eagle'
	}
}

function Parse-DelayMs {
	param (
		[Parameter(Mandatory = $true)]
		[string[]]$Args
	)

	for ($i = 0; $i -lt $Args.Count; $i++) {
		if ($Args[$i] -eq '--delay-ms') {
			if ($i + 1 -ge $Args.Count) {
				throw 'Missing value for --delay-ms'
			}
			$val = 0
			if (-not [int]::TryParse($Args[$i + 1], [ref]$val)) {
				throw "Invalid --delay-ms: $($Args[$i + 1])"
			}
			return $val
		}
	}

	return 40
}

$delayMs = Parse-DelayMs -Args $argv
$frames = @(
	'   _  ',
	'  ( ) ',
	'   _  ',
	'  ( ) ',
	'   _  ',
	'  ( ) '
)

try {
	[Console]::CursorVisible = $false
	$Host.UI.RawUI.WindowTitle = 'eagle'

	$i = 0
	while ($true) {
		$frame = $frames[$i % $frames.Count]
		$Host.UI.RawUI.CursorPosition = @{ X = 0; Y = 0 }
		Write-Host $frame -ForegroundColor Magenta
		Write-Host ''
		Write-Host 'Press Ctrl+C to stop.' -ForegroundColor DarkGray
		Start-Sleep -Milliseconds $delayMs
		$i++
	}
}
finally {
	[Console]::CursorVisible = $true
	$Host.UI.RawUI.WindowTitle = 'PowerShell'
}
