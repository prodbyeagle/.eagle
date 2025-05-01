function Uninstall-Script {
  $scriptPath = "C:\Scripts"
  $eaglePath = "$scriptPath\eagle.ps1"
  $profilePath = $PROFILE

  Write-Host "🛑 You are about to uninstall eagle." -ForegroundColor Yellow
  $confirmation = Read-Host "Are you sure you want to continue? (y/n)"

  if ($confirmation.ToLower() -ne 'y' -and $confirmation.ToLower() -ne 'yes') {
    Write-Host "❌ Uninstallation cancelled." -ForegroundColor Red
    return
  }

  Write-Host "Uninstalling eagle..." -ForegroundColor Cyan

  try {
    if (Test-Path $eaglePath) {
      Remove-Item $eaglePath -Force
      Write-Host "✅ Removed eagle.ps1 from $eaglePath" -ForegroundColor Green
    }
    else {
      Write-Host "ℹ eagle.ps1 not found at $eaglePath" -ForegroundColor Yellow
    }

    if (Test-Path $profilePath) {
      $profileContent = Get-Content $profilePath
      $filteredContent = $profileContent | Where-Object { $_ -notmatch "Set-Alias eagle" }
      Set-Content $profilePath -Value $filteredContent
      Write-Host "✅ Removed alias from PowerShell profile" -ForegroundColor Green
    }

    if ((Test-Path $scriptPath) -and ((Get-ChildItem $scriptPath).Count -eq 0)) {
      Remove-Item $scriptPath -Force
      Write-Host "✅ Removed empty folder $scriptPath" -ForegroundColor Green
    }

    Write-Host "🎉 Uninstallation complete." -ForegroundColor Green
  }
  catch {
    Write-Host "❌ Failed to uninstall eagle  ( SEND DM TO PRODBYEAGLE ON DISCORD ): $_" -ForegroundColor Red
  }
}
