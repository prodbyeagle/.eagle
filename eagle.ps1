param (
  [Parameter(Mandatory = $false, Position = 0)]
  [string]$option = "help"
)

$scriptVersion = "2.4.0"

$scriptRoot = $PSScriptRoot
. "$scriptRoot\eagle\show-help.ps1"
. "$scriptRoot\eagle\install-spicetify.ps1"
. "$scriptRoot\eagle\install-vencord.ps1"
. "$scriptRoot\eagle\update-script.ps1"
. "$scriptRoot\eagle\uninstall-script.ps1"
. "$scriptRoot\eagle\show-version.ps1"

$normalized = switch ($option.ToLower()) {
  "--h" { "help" }
  "--v" { "version" }
  "--u" { "update" }
  "--s" { "spicetify" }
  "--ven" { "vencord" }
  "--rem" { "uninstall" }
  default { $option.ToLower() }
}

switch ($normalized) {
  "spicetify" { Install-Spicetify }
  "vencord" { Install-Vencord }
  "update" { Update-Script }
  "uninstall" { Uninstall-Script }
  "version" { Show-Version -Version $scriptVersion }
  "help" { Show-Help }
  default {
    Write-Host "❌ Unknown command: '$option'. 'eagle help' for all Commands." -ForegroundColor DarkRed
  }
}
