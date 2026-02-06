[CmdletBinding()]
param (
	[Parameter(Position = 0)]
	[string]$command = 'help',

	[Parameter(ValueFromRemainingArguments = $true)]
	[string[]]$argv = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-EagleError {
	param (
		[Parameter(Mandatory = $true)]
		[string]$Message
	)

	Write-Host $Message -ForegroundColor DarkRed
}

function Get-EagleVersion {
	param (
		[Parameter(Mandatory = $true)]
		[string]$ScriptDir
	)

	$versionPath = Join-Path $ScriptDir 'version.txt'
	if (-not (Test-Path $versionPath)) {
		return '0.0.0'
	}

	$version = Get-Content -Path $versionPath -TotalCount 1 -ErrorAction Stop
	if (-not $version) {
		return '0.0.0'
	}

	return $version.Trim()
}

function Get-EagleCommandManifests {
	param (
		[Parameter(Mandatory = $true)]
		[string]$CommandsDir
	)

	if (-not (Test-Path $CommandsDir)) {
		return @()
	}

	$paths = Get-ChildItem -Path $CommandsDir -Filter '*.ps1' -File |
		Where-Object { $_.Name -notmatch '^[._]' } |
		Select-Object -ExpandProperty FullName

	$manifests = @()
	foreach ($path in $paths) {
		try {
			$manifest = & $path -mode 'manifest'
		}
		catch {
			Write-EagleError "Failed to load command manifest: $path"
			throw
		}

		if (-not $manifest) {
			continue
		}

		$name = $manifest.name
		if (-not $name) {
			throw "Command manifest missing required field: name ($path)"
		}

		$aliases = @()
		if ($manifest.aliases) {
			$aliases = @($manifest.aliases | ForEach-Object {
				"$_".ToLower()
			})
		}

		$manifests += [pscustomobject]@{
			name = "$name".ToLower()
			aliases = $aliases
			summary = $manifest.summary
			usage = $manifest.usage
			path = $path
		}
	}

	return $manifests | Sort-Object name
}

function Resolve-EagleCommand {
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

$scriptDir = Split-Path -Parent $PSCommandPath
$commandsDir = Join-Path $scriptDir 'commands'
$version = Get-EagleVersion -ScriptDir $scriptDir

$normalized = switch ($command.ToLower()) {
	'-h' { 'help' }
	'--h' { 'help' }
	'--help' { 'help' }
	'/?' { 'help' }
	'-v' { 'version' }
	'--version' { 'version' }
	default { $command.ToLower() }
}

$wantsHelp = $argv -contains '--help' -or $argv -contains '-h' -or $argv -contains '/?'
if ($normalized -ne 'help' -and $wantsHelp) {
	$argv = @($command)
	$normalized = 'help'
}

$manifests = Get-EagleCommandManifests -CommandsDir $commandsDir
$resolved = Resolve-EagleCommand -InputCommand $normalized -Manifests $manifests

$context = @{
	version = $version
	repoUrl = 'https://github.com/prodbyeagle/eaglePowerShell'
	scriptDir = $scriptDir
	commandsDir = $commandsDir
	manifests = $manifests
	invokedAs = $normalized
}

if (-not $resolved) {
	Write-EagleError "Unknown command: '$command'. Try: eagle help"
	exit 1
}

try {
	& $resolved.path -mode 'run' -context $context -argv $argv
}
catch {
	Write-EagleError "Command failed: $($resolved.name)"
	Write-EagleError "$_"
	exit 1
}
