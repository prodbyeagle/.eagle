function Update-Script {
  $localScript = $MyInvocation.MyCommand.Path
  $remoteUrl = "https://raw.githubusercontent.com/prodbyeagle/eaglePowerShell/main/eagle.ps1"
  $tempFile = [System.IO.Path]::GetTempFileName()

  Write-Host "Checking for updates..." -ForegroundColor Cyan

  try {
    Invoke-WebRequest -Uri $remoteUrl -OutFile $tempFile -UseBasicParsing

    $localHash = Get-FileHash $localScript -Algorithm SHA256
    $remoteHash = Get-FileHash $tempFile -Algorithm SHA256

    if ($localHash.Hash -ne $remoteHash.Hash) {
      Write-Host "🔄 Update available! Installing update..." -ForegroundColor Yellow
      Copy-Item -Path $tempFile -Destination $localScript -Force
      Write-Host "✅ [at]eagle PS updated successfully!" -ForegroundColor Green
    }
    else {
      Write-Host "✅ You already have the latest version of [at]eagle PS." -ForegroundColor Green
    }

    Remove-Item $tempFile -Force
  }
  catch {
    Write-Host "❌ Failed to check or apply update: $_" -ForegroundColor Red
  }
}
