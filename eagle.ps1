param (
  [Parameter(Mandatory = $false, Position = 0)]
  [string]$option = "help"
)

$scriptVersion = "2.0.1"

. "$PSScriptRoot\eagle\show-help.ps1"
. "$PSScriptRoot\eagle\install-spicetify.ps1"
. "$PSScriptRoot\eagle\install-vencord.ps1"
. "$PSScriptRoot\eagle\update-script.ps1"
. "$PSScriptRoot\eagle\uninstall-script.ps1"
. "$PSScriptRoot\eagle\show-version.ps1"
. "$PSScriptRoot\eagle\update-apps.ps1"

switch ($option.ToLower()) {
  "--h" { $option = "help" }
  "--v" { $option = "version" }
  "--u" { $option = "update" }
  "--a" { $option = "apps" }
  "--s" { $option = "spicetify" }
  "--ven" { $option = "vencord" }
  "--rem" { $option = "uninstall" }
}

switch ($option.ToLower()) {
  "spicetify" { Install-Spicetify }
  "vencord" { Install-Vencord }
  "update" { Update-Script }
  "uninstall" { Uninstall-Script }
  "version" { Show-Version -Version $scriptVersion }
  "help" { Show-Help }
  "apps" {
    Test-WingetInstalled
    Update-All-Applications
  }
  default {
    Write-Host "❌ Unknown command: '$option'" -ForegroundColor Red
    Show-Help
  }
}
