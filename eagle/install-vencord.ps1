function Install-Vencord {
  $userProfile = $env:USERPROFILE
  $vencordDir = "$userProfile\Vencord"
  $vencordExe = "$vencordDir\VencordInstallerCli.exe"
  $vencordUrl = "https://github.com/Vendicated/VencordInstaller/releases/latest/download/VencordInstallerCli.exe"

  if (Test-Path $vencordExe) {
    Write-Host "ℹ Vencord Installer already exists. Launching..." -ForegroundColor Yellow
  }
  else {
    Write-Host "Vencord Installer not found. Downloading..." -ForegroundColor Yellow
    try {
      New-Item -ItemType Directory -Force -Path $vencordDir | Out-Null
      Invoke-WebRequest -Uri $vencordUrl -OutFile $vencordExe
      Write-Host "✅ Installer successfully downloaded." -ForegroundColor Green
    }
    catch {
      Write-Host "❌ Error downloading Vencord: $_" -ForegroundColor Red
      return
    }
  }

  Write-Host "Launching Vencord Installer..." -ForegroundColor Cyan
  Start-Process $vencordExe
}
