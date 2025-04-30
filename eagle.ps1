param (
  [Parameter(Mandatory = $false, Position = 0)]
  [string]$option = "help"
)

$currentUser = $env:USERNAME
$allowedUser = "heypa"
$scriptVersion = "2.1.3"

. "$PSScriptRoot\eagle\show-help.ps1"
. "$PSScriptRoot\eagle\install-spicetify.ps1"
. "$PSScriptRoot\eagle\install-vencord.ps1"
. "$PSScriptRoot\eagle\update-script.ps1"
. "$PSScriptRoot\eagle\uninstall-script.ps1"
. "$PSScriptRoot\eagle\show-version.ps1"
. "$PSScriptRoot\eagle\update-apps.ps1"
. "$PSScriptRoot\eagle\start-clean.ps1"

switch ($option.ToLower()) {
  "--h" { $option = "help" }
  "--v" { $option = "version" }
  "--u" { $option = "update" }
  "--a" { $option = "apps" }
  "--s" { $option = "spicetify" }
  "--ven" { $option = "vencord" }
  "--rem" { $option = "uninstall" }
  "--c" { $option = "clean" }
}

switch ($option.ToLower()) {
  "spicetify" { Install-Spicetify }
  "vencord" { Install-Vencord }
  "update" { Update-Script }
  "uninstall" { Uninstall-Script }
  "version" { Show-Version -Version $scriptVersion }
  "help" { Show-Help }
  "clean" {
    if ($currentUser -eq $allowedUser) {
      Start-Cleanup
    }
    else {
      Write-Host "❌ The 'clean' command is restricted and cannot be used by this user." -ForegroundColor Red
    }
  }
  "apps" {
    Test-WingetInstalled
    Update-All-Applications
  }
  default {
    Write-Host "❌ Unknown command: '$option'" -ForegroundColor Red
    Show-Help
  }
}
