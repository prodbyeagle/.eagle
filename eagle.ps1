param (
  [Parameter(Mandatory = $false, Position = 0)]
  [string]$option = "help",
  [string]$name,
  [string]$template
)

$scriptVersion = "2.6.3"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$coreDir = Join-Path $scriptDir "core"

Get-ChildItem -Path $coreDir -Filter *.ps1 | ForEach-Object {
  . $_.FullName
}

$normalized = switch ($option.ToLower()) {
  "--h" { "help" }
  "--v" { "version" }
  "--s" { "spicetify" }
  "--ven" { "vencord" }
  "--u" { "update" }
  "--rem" { "uninstall" }
  "--c" { "create" }
  default { $option.ToLower() }
}

switch ($normalized) {
  "spicetify" { Install-Spicetify }
  "vencord" { Install-Vencord }
  "uninstall" { Uninstall-Script }
  "version" { Show-Version -Version $scriptVersion }
  "update" { Update-Script }
  "create" { Install-Project -name $name -template $template }
  "help" { Show-Help }
  default {
    Write-Host "❌ Unknown command: '$option'. Use 'eagle help' for a list of available commands." -ForegroundColor DarkRed
    exit 1
  }
}
