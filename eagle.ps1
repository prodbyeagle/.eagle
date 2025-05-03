param (
  [Parameter(Mandatory = $false, Position = 0)]
  [string]$option = "help",
  [string]$name,
  [string]$template
)

$scriptVersion = "2.5.1"

$scriptRoot = $PSScriptRoot
. "$scriptRoot\eagle\show-help.ps1"
. "$scriptRoot\eagle\install-spicetify.ps1"
. "$scriptRoot\eagle\install-vencord.ps1"
. "$scriptRoot\eagle\uninstall-script.ps1"
. "$scriptRoot\eagle\show-version.ps1"
. "$scriptRoot\eagle\create-project.ps1"

$normalized = switch ($option.ToLower()) {
  "--h" { "help" }
  "--v" { "version" }
  "--s" { "spicetify" }
  "--ven" { "vencord" }
  "--rem" { "uninstall" }
  "--c" { "create" }
  default { $option.ToLower() }
}

switch ($normalized) {
  "spicetify" { Install-Spicetify }
  "vencord" { Install-Vencord }
  "uninstall" { Uninstall-Script }
  "version" { Show-Version -Version $scriptVersion }
  "create" { Install-Project -name $name -template $template }
  "help" { Show-Help }
  default {
    Write-Host "❌ Unknown command: '$option'. 'eagle help' for all Commands." -ForegroundColor DarkRed
  }
}
