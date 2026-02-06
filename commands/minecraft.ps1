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
		name = 'minecraft'
		aliases = @('m')
		summary = 'Start a Minecraft server from ~/Documents/mc-servers'
		usage = 'eagle minecraft [--ram <mb>]'
	}
}

function Parse-RamMb {
	param (
		[Parameter(Mandatory = $true)]
		[string[]]$Args
	)

	for ($i = 0; $i -lt $Args.Count; $i++) {
		$a = $Args[$i]
		if ($a -eq '--ram' -or $a -eq '--ram-mb') {
			if ($i + 1 -ge $Args.Count) {
				throw "Missing value for $a"
			}

			$val = 0
			if (-not [int]::TryParse($Args[$i + 1], [ref]$val)) {
				throw "Invalid RAM value: $($Args[$i + 1])"
			}

			return $val
		}
	}

	return 8192
}

function Select-ServerPath {
	$rootPath = Join-Path $env:USERPROFILE 'Documents\\mc-servers'
	if (-not (Test-Path $rootPath)) {
		Write-Host "Folder not found: $rootPath" -ForegroundColor DarkRed
		return $null
	}

	$servers = Get-ChildItem -Path $rootPath -Directory | Where-Object {
		Test-Path (Join-Path $_.FullName 'server.jar')
	}

	if (-not $servers -or $servers.Count -eq 0) {
		Write-Host "No servers found in: $rootPath" -ForegroundColor DarkRed
		return $null
	}

	$selectedIndex = 0

	function Render {
		Clear-Host
		Write-Host 'Select a Minecraft server (Up/Down, Enter):' `
			-ForegroundColor Cyan
		Write-Host ''

		for ($i = 0; $i -lt $servers.Count; $i++) {
			$prefix = if ($i -eq $selectedIndex) { '> ' } else { '  ' }
			$name = $servers[$i].Name
			if ($i -eq $selectedIndex) {
				Write-Host "$prefix$name" -ForegroundColor Yellow
			}
			else {
				Write-Host "$prefix$name"
			}
		}
	}

	[Console]::CursorVisible = $false
	try {
		while ($true) {
			Render
			$key = [Console]::ReadKey($true)

			if ($key.Key -eq [ConsoleKey]::UpArrow -and $selectedIndex -gt 0) {
				$selectedIndex--
				continue
			}

			if ($key.Key -eq [ConsoleKey]::DownArrow -and
				$selectedIndex -lt ($servers.Count - 1)) {
				$selectedIndex++
				continue
			}

			if ($key.Key -eq [ConsoleKey]::Enter) {
				break
			}
		}

		$serverName = $servers[$selectedIndex].Name
		$Host.UI.RawUI.WindowTitle = "MC-SERVER: $serverName"

		return $servers[$selectedIndex].FullName
	}
	finally {
		[Console]::CursorVisible = $true
		Clear-Host
	}
}

$ramMb = Parse-RamMb -Args $argv
$serverPath = Select-ServerPath
if (-not $serverPath) {
	exit 1
}

$jarPath = Join-Path $serverPath 'server.jar'
if (-not (Test-Path $jarPath)) {
	Write-Host "server.jar not found: $jarPath" -ForegroundColor DarkRed
	exit 1
}

Write-Host "Starting server with ${ramMb}MB RAM..." -ForegroundColor Cyan

Push-Location $serverPath
try {
	$javaArgs = @(
		"-Xmx${ramMb}M",
		"-Xms${ramMb}M",
		'-XX:+UseG1GC',
		'-XX:+ParallelRefProcEnabled',
		'-XX:MaxGCPauseMillis=200',
		'-XX:+UnlockExperimentalVMOptions',
		'-XX:+DisableExplicitGC',
		'-XX:+AlwaysPreTouch',
		'-XX:G1NewSizePercent=30',
		'-XX:G1MaxNewSizePercent=40',
		'-XX:G1HeapRegionSize=8M',
		'-XX:G1ReservePercent=20',
		'-XX:G1HeapWastePercent=5',
		'-XX:G1MixedGCCountTarget=4',
		'-XX:InitiatingHeapOccupancyPercent=15',
		'-XX:G1MixedGCLiveThresholdPercent=90',
		'-XX:G1RSetUpdatingPauseTimePercent=5',
		'-XX:SurvivorRatio=32',
		'-XX:+PerfDisableSharedMem',
		'-XX:MaxTenuringThreshold=1',
		'-Daikars.new.flags=true',
		'-Dusing.aikars.flags=https://mcutils.com',
		'-jar',
		$jarPath,
		'nogui'
	)

	& java @javaArgs
}
finally {
	Pop-Location
}

Write-Host 'Server stopped.' -ForegroundColor Green
