function Update-Script {
  $localScript = $PSCommandPath

  if (-not $localScript) {
    $localScript = Join-Path $PSScriptRoot 'eagle.ps1'
  }

  if (-not (Test-Path $localScript)) {
    Write-Host "❌  ( SEND DM TO PRODBYEAGLE ON DISCORD ) Cannot determine local script path. Tried: $localScript" -ForegroundColor Red
    return
  }

  $remoteUrl = 'https://raw.githubusercontent.com/prodbyeagle/eaglePowerShell/main/eagle.ps1'
  $tempFile = [IO.Path]::GetTempFileName()

  Write-Host "Checking for updates..." -ForegroundColor Cyan

  try {
    Invoke-WebRequest -Uri $remoteUrl -OutFile $tempFile -UseBasicParsing

    $localHash = Get-FileHash -Path $localScript -Algorithm SHA256
    $remoteHash = Get-FileHash -Path $tempFile   -Algorithm SHA256

    if ($localHash.Hash -ne $remoteHash.Hash) {
      Write-Host "🔄 Update available! Installing…" -ForegroundColor Yellow
      Copy-Item -Path $tempFile -Destination $localScript -Force -ErrorAction Stop
      Write-Host "✅ [at]eagle PS updated successfully!" -ForegroundColor Green
    }
    else {
      Write-Host "✅ You already have the latest version of [at]eagle PS." -ForegroundColor Green
    }
  }
  catch {
    Write-Host "❌ Failed to check or apply update ( SEND DM TO PRODBYEAGLE ON DISCORD ): $_" -ForegroundColor Red
  }
  finally {
    if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
  }
}
