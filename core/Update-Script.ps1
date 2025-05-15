function Update-Script {
  $localFolder = 'C:\Scripts'
  $scriptName = 'eagle.ps1'
  $coreFolderName = 'core'
  $remoteZipUrl = 'https://github.com/prodbyeagle/eaglePowerShell/archive/refs/heads/main.zip'
  $tempZipPath = Join-Path $env:TEMP "eagle_update.zip"
  $tempExtractPath = Join-Path $env:TEMP "eagle_update"

  Write-Host "📦 Checking for updates..." -ForegroundColor Yellow

  try {
    Write-Host "⬇ Downloading remote files..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $remoteZipUrl -OutFile $tempZipPath -UseBasicParsing -ErrorAction Stop
    Expand-Archive -Path $tempZipPath -DestinationPath $tempExtractPath -Force

    $remoteScriptPath = Get-ChildItem -Path $tempExtractPath -Filter $scriptName -Recurse |
    Select-Object -First 1 -ExpandProperty FullName

    $remoteCoreFolder = Get-ChildItem -Path $tempExtractPath -Directory -Recurse |
    Where-Object { $_.Name -ieq $coreFolderName } |
    Select-Object -First 1 -ExpandProperty FullName

    $localScriptPath = Join-Path $localFolder $scriptName
    $localCoreFolder = Join-Path $localFolder $coreFolderName

    if (-not (Test-Path $localScriptPath)) {
      Write-Host "❌ Could not find eagle.ps1 in the root of the Scripts folder." -ForegroundColor Red
      return
    }

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

      if (Test-Path $localCoreFolder) {
        Remove-Item $localCoreFolder -Recurse -Force
        Write-Host "✅ Removed old core folder from $localCoreFolder" -ForegroundColor Green
      }

      if (Test-Path $remoteCoreFolder) {
        Copy-Item -Path $remoteCoreFolder -Destination $localFolder -Recurse -Force
        Write-Host "✅ core folder updated successfully." -ForegroundColor Green
      }
      else {
        Write-Host "ℹ No core folder found in the remote update." -ForegroundColor Yellow
      }
    }
    else {
      Write-Host "✅ You already have the latest version (v$localVersion)." -ForegroundColor Green
    }
  }
  catch {
    Write-Host "❌ Update failed: $_" -ForegroundColor Red
  }
  finally {
    Remove-Item -Path $tempZipPath -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $tempExtractPath -Recurse -Force -ErrorAction SilentlyContinue
  }
}
