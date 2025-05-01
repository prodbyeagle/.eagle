function Install-Vencord {
  $userProfile = $env:USERPROFILE
  $vencordDir = "$userProfile\Vencord"
  $vencordExe = "$vencordDir\VencordInstallerCli.exe"
  $vencordUrl = "https://github.com/Vendicated/VencordInstaller/releases/latest/download/VencordInstallerCli.exe"

  $expectedMinSize = 5772800

  if (Test-Path $vencordExe) {
    Write-Host "ℹ Vencord Installer already exists. Verifying file..." -ForegroundColor Yellow

    $fileSize = (Get-Item $vencordExe).length

    if ($fileSize -lt $expectedMinSize) {
      Write-Host "❌ Vencord Installer seems corrupted (file size: $fileSize bytes). Re-downloading..." -ForegroundColor Red
      Remove-Item $vencordExe -Force
    }
    else {
      Write-Host "✅ Vencord Installer is valid. Launching..." -ForegroundColor Green
      & $vencordExe
      return
    }
  }

  Write-Host "Vencord Installer not found or corrupted. Downloading..." -ForegroundColor Yellow
  try {
    New-Item -ItemType Directory -Force -Path $vencordDir | Out-Null
    Invoke-WebRequest -Uri $vencordUrl -OutFile $vencordExe -UseBasicParsing
    Write-Host "✅ Installer successfully downloaded." -ForegroundColor Green
  }
  catch {
    Write-Host "❌ Error downloading Vencord  ( SEND DM TO PRODBYEAGLE ON DISCORD ): $_" -ForegroundColor Red
    return
  }

  Write-Host "🚀 Launching Vencord Installer..." -ForegroundColor Cyan
  try {
    if (Test-Path $vencordExe) {
      & $vencordExe
    }
    else {
      Write-Host "❌ Failed to find $vencordExe after download  ( SEND DM TO PRODBYEAGLE ON DISCORD )." -ForegroundColor Red
    }
  }
  catch {
    Write-Host "❌ Failed to launch Vencord Installer  ( SEND DM TO PRODBYEAGLE ON DISCORD ): $_" -ForegroundColor Red
  }
}
