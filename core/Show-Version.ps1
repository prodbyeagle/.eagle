function Show-Version {
  param (
    [string]$Version
  )

  Write-Host ""
  Write-Host "🦅 eaglePower" -ForegroundColor Yellow
  Write-Host "────────────────────────────"
  Write-Host "Version        : $Version" -ForegroundColor Green
  Write-Host "Repository     : https://github.com/prodbyeagle/eaglePowerShell" -ForegroundColor Cyan
  Write-Host "────────────────────────────"
}