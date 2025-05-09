function Update-Script {
  $localFolder = 'C:\Scripts'
  $scriptName = 'eagle.ps1'
  $remoteZipUrl = 'https://github.com/prodbyeagle/eaglePowerShell/archive/refs/heads/main.zip'
  $tempZipPath = Join-Path $env:TEMP "eagle_update.zip"
  $tempExtractPath = Join-Path $env:TEMP "eagle_update"

  Write-Host "📦 Checking for updates..." -ForegroundColor Yellow

  try {
    Invoke-WebRequest -Uri $remoteZipUrl -OutFile $tempZipPath -UseBasicParsing -ErrorAction Stop
    Expand-Archive -Path $tempZipPath -DestinationPath $tempExtractPath -Force

    $extractedFolder = Join-Path $tempExtractPath 'eaglePowerShell-main'
    $localScriptPath = Join-Path $localFolder $scriptName

    if (-not (Test-Path $localScriptPath)) {
      Write-Host "❌ Could not find eagle.ps1 in the root of the Scripts folder." -ForegroundColor Red
      return
    }

    $remoteScriptPath = Join-Path $extractedFolder $scriptName
    $localVersionLine = Get-Content -Path $localScriptPath | Where-Object { $_ -match '\$scriptVersion\s*=\s*"' }
    $remoteVersionLine = Get-Content -Path $remoteScriptPath | Where-Object { $_ -match '\$scriptVersion\s*=\s*"' }

    if (-not $localVersionLine -or -not $remoteVersionLine) {
      Write-Host "❌ Could not extract script version from one of the files." -ForegroundColor Red
      return
    }

    $localVersion = ($localVersionLine -split '"')[1]
    $remoteVersion = ($remoteVersionLine -split '"')[1]

    if ([version]$remoteVersion -gt [version]$localVersion) {
      Write-Host "🔄 Update available! Local: $localVersion → Remote: $remoteVersion. Installing update…" -ForegroundColor Yellow

      Copy-Item -Path $remoteScriptPath -Destination $localScriptPath -Force
      Write-Host "✅ eagle.ps1 updated successfully." -ForegroundColor Green
    }
    else {
      Write-Host "✅ You already have the latest version (v$localVersion)." -ForegroundColor Green
    }
  }
  catch {
    Write-Host "❌ Update failed (SEND DM TO PRODBYEAGLE ON DISCORD): $_" -ForegroundColor Red
  }
  finally {
    Remove-Item -Path $tempZipPath -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $tempExtractPath -Recurse -Force -ErrorAction SilentlyContinue
  }
}