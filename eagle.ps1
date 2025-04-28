param (
  [Parameter(Mandatory = $false)]
  [ValidateSet("spicetify", "vencord", "update", "uninstall", "version", "help")]
  [string]$option = "help"
)

$scriptVersion = "2.0.0"

. "$PSScriptRoot\eagle\show-help.ps1"
. "$PSScriptRoot\eagle\install-spicetify.ps1"
. "$PSScriptRoot\eagle\install-vencord.ps1"
. "$PSScriptRoot\eagle\update-script.ps1"
. "$PSScriptRoot\eagle\uninstall-script.ps1"
. "$PSScriptRoot\eagle\show-version.ps1"

switch ($option.ToLower()) {
  "spicetify" { Install-Spicetify }
  "vencord" { Install-Vencord }
  "update" { Update-Script }
  "uninstall" { Uninstall-Script }
  "version" { Show-Version -Version $scriptVersion }
  "help" { Show-Help }
  default {
    Write-Host "❌ Unknown command: '$option'" -ForegroundColor Red
    Show-Help
  }
}
