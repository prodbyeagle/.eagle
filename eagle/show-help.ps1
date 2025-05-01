function Show-Help {
  Write-Host "`nAvailable commands:" -ForegroundColor Yellow
  Write-Host "  spicetify (--s)     : Installs Spicetify" -ForegroundColor Cyan
  Write-Host "  vencord (--ven)     : Launches or downloads the Vencord Installer" -ForegroundColor Cyan
  Write-Host "  update (--u)        : Checks for updates to eagle and installs if needed" -ForegroundColor Cyan
  Write-Host "  uninstall (--rem)   : Removes eagle and cleans up the alias and folder" -ForegroundColor Cyan
  Write-Host "  version (--v)       : Displays the current version of the eagle script" -ForegroundColor Cyan
  Write-Host "  help (--h)          : Displays this help message" -ForegroundColor Cyan
  Write-Host "  apps (--a)          : Updates all applications via winget" -ForegroundColor Cyan
}
