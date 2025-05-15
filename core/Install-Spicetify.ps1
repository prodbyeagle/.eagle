function Install-Spicetify {
  Write-Host "`n🎵 Installing Spicetify..." -ForegroundColor Cyan

  $installUrl = "https://raw.githubusercontent.com/spicetify/cli/main/install.ps1"

  try {
    Write-Host "🌐 Downloading installer script from:" -ForegroundColor Yellow
    Write-Host "   $installUrl" -ForegroundColor Cyan

    $scriptContent = Invoke-WebRequest -UseBasicParsing -Uri $installUrl -ErrorAction Stop
    Invoke-Expression $scriptContent.Content

    Write-Host "✅ Spicetify installed successfully!" -ForegroundColor Green
  }
  catch {
    Write-Host "❌ Failed to install Spicetify: $_" -ForegroundColor Red
  }
}
