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
		name = 'create'
		aliases = @('c')
		summary = 'Create a new project from a template'
		usage = 'eagle create --name <name> --template <discord|next|typescript>'
	}
}

function Ensure-Tool {
	param (
		[Parameter(Mandatory = $true)]
		[string]$Name,

		[Parameter(Mandatory = $true)]
		[string]$VersionArg
	)

	& $Name $VersionArg > $null 2>&1
	if ($LASTEXITCODE -ne 0) {
		throw "Required tool not found: $Name"
	}
}

function Parse-Args {
	param (
		[Parameter(Mandatory = $true)]
		[string[]]$Args
	)

	$result = @{
		name = $null
		template = $null
	}

	for ($i = 0; $i -lt $Args.Count; $i++) {
		$a = $Args[$i]
		switch ($a) {
			'--name' {
				if ($i + 1 -ge $Args.Count) {
					throw 'Missing value for --name'
				}
				$result.name = $Args[$i + 1]
				$i++
			}
			'-n' {
				if ($i + 1 -ge $Args.Count) {
					throw 'Missing value for -n'
				}
				$result.name = $Args[$i + 1]
				$i++
			}
			'--template' {
				if ($i + 1 -ge $Args.Count) {
					throw 'Missing value for --template'
				}
				$result.template = $Args[$i + 1]
				$i++
			}
			'-t' {
				if ($i + 1 -ge $Args.Count) {
					throw 'Missing value for -t'
				}
				$result.template = $Args[$i + 1]
				$i++
			}
		}
	}

	return $result
}

function Select-Template {
	$options = @('discord', 'next', 'typescript')
	$selectedIndex = 0

	function Render {
		Clear-Host
		Write-Host 'Choose a template (Up/Down, Enter):' -ForegroundColor Cyan
		Write-Host ''
		for ($i = 0; $i -lt $options.Count; $i++) {
			$prefix = if ($i -eq $selectedIndex) { '> ' } else { '  ' }
			$name = $options[$i]
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
				$selectedIndex -lt ($options.Count - 1)) {
				$selectedIndex++
				continue
			}

			if ($key.Key -eq [ConsoleKey]::Enter) {
				return $options[$selectedIndex]
			}
		}
	}
	finally {
		[Console]::CursorVisible = $true
		Clear-Host
	}
}

Ensure-Tool -Name 'git' -VersionArg '--version'
Ensure-Tool -Name 'bun' -VersionArg '--version'

$parsed = Parse-Args -Args $argv

$name = $parsed.name
if (-not $name) {
	$name = Read-Host 'Enter project name'
}

$template = $parsed.template
if (-not $template) {
	$template = Select-Template
}

$template = $template.ToLower()

$year = (Get-Date).ToString('yy')
$baseRoot = "D:\\Development\\.$year"

$targetRoot = switch ($template) {
	'discord' { Join-Path $baseRoot 'discord' }
	'next' { Join-Path $baseRoot 'frontend' }
	'typescript' { Join-Path $baseRoot 'typescript' }
	default {
		throw "Invalid template: '$template'"
	}
}

$projectPath = Join-Path $targetRoot $name
if (Test-Path $projectPath) {
	throw "Project already exists: $projectPath"
}

New-Item -ItemType Directory -Path $targetRoot -Force | Out-Null

$repoUrl = switch ($template) {
	'discord' { 'https://github.com/meowlounge/discord-template.git' }
	'next' { 'https://github.com/meowlounge/next-template.git' }
	'typescript' { 'https://github.com/meowlounge/typescript-template.git' }
}

Write-Host "Creating '$template' project: $name" -ForegroundColor Cyan
git clone $repoUrl $projectPath
if ($LASTEXITCODE -ne 0) {
	throw 'git clone failed.'
}

Push-Location $projectPath
try {
	$gitFolder = Join-Path $projectPath '.git'
	if (Test-Path $gitFolder) {
		Remove-Item -Recurse -Force $gitFolder
	}

	Write-Host 'Updating packages...' -ForegroundColor DarkGray
	bun update --latest
	if ($LASTEXITCODE -ne 0) {
		throw 'bun update failed.'
	}
}
finally {
	Pop-Location
}

Write-Host "Project created: $projectPath" -ForegroundColor Green
