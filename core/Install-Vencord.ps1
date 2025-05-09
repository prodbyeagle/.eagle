function Install-Vencord {
  $userProfile = $env:USERPROFILE
  $vencordDir = Join-Path $userProfile 'Vencord'
  $vencordExe = Join-Path $vencordDir 'VencordInstallerCli.exe'
  $vencordUrl = "https://github.com/Vendicated/VencordInstaller/releases/latest/download/VencordInstallerCli.exe"
  $expectedMinSize = 5772800

  Write-Host "`n🧩 Checking for Vencord Installer..." -ForegroundColor Yellow

  if (Test-Path $vencordExe) {
    $fileSize = (Get-Item $vencordExe).Length
    Write-Host "🔍 Found existing installer at: $vencordExe" -ForegroundColor Cyan

    if ($fileSize -lt $expectedMinSize) {
      Write-Host "⚠️  File appears to be corrupted (size: $fileSize bytes). Re-downloading..." -ForegroundColor Red
      Remove-Item $vencordExe -Force -ErrorAction SilentlyContinue
    }
    else {
      Write-Host "✅ Installer is valid. Launching..." -ForegroundColor Green
      Start-Process -FilePath $vencordExe
      return
    }
  }
  else {
    Write-Host "❌ Installer not found. Preparing to download..." -ForegroundColor Yellow
  }

  try {
    New-Item -ItemType Directory -Force -Path $vencordDir | Out-Null
    Write-Host "🌐 Downloading Vencord Installer..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $vencordUrl -OutFile $vencordExe -UseBasicParsing -ErrorAction Stop
    Write-Host "✅ Download completed: $vencordExe" -ForegroundColor Green
  }
  catch {
    Write-Host "❌ Failed to download Vencord Installer (SEND DM TO PRODBYEAGLE ON DISCORD): $_" -ForegroundColor Red
    return
  }

  try {
    if (Test-Path $vencordExe) {
      Write-Host "🚀 Launching Vencord Installer..." -ForegroundColor Cyan
      Start-Process -FilePath $vencordExe
    }
    else {
      Write-Host "❌ Installer missing after download: $vencordExe (SEND DM TO PRODBYEAGLE ON DISCORD)" -ForegroundColor Red
    }
  }
  catch {
    Write-Host "❌ Failed to launch installer (SEND DM TO PRODBYEAGLE ON DISCORD): $_" -ForegroundColor Red
  }
}
