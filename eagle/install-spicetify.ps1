function Install-Spicetify {
  Write-Host "Starting Spicetify installer..." -ForegroundColor Cyan
  try {
    Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/spicetify/cli/main/install.ps1" | Invoke-Expression
    Write-Host "✅ Spicetify successfully installed!" -ForegroundColor Green
  }
  catch {
    Write-Host "❌ Error installing Spicetify  ( SEND DM TO PRODBYEAGLE ON DISCORD ): $_" -ForegroundColor Red
  }
}
