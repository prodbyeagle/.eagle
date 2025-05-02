function Update-Script {
  $localFolder = 'C:\Scripts'
  $scriptName = 'eagle.ps1'
  $remoteZipUrl = 'https://github.com/prodbyeagle/eaglePowerShell/archive/refs/heads/main.zip'
  $tempZipPath = Join-Path $env:TEMP "eagle_update.zip"
  $tempExtractPath = Join-Path $env:TEMP "eagle_update"

  Write-Host "📦 Checking for updates..." -ForegroundColor Cyan

  Write-Host "Local Folder: $localFolder" -ForegroundColor Yellow
  Write-Host "Script Path to check: $($localFolder)\$scriptName" -ForegroundColor Yellow

  try {
    Write-Host "🔄 Fetching the latest version from GitHub..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $remoteZipUrl -OutFile $tempZipPath -UseBasicParsing -ErrorAction Stop
    Write-Host "✅ Latest version fetched successfully from GitHub." -ForegroundColor Green

    Write-Host "📦 Extracting update package..." -ForegroundColor Cyan
    Expand-Archive -Path $tempZipPath -DestinationPath $tempExtractPath -Force
    Write-Host "✅ Update package extracted successfully." -ForegroundColor Green

    $extractedFolder = Join-Path $tempExtractPath 'eaglePowerShell-main'
    $localScriptPath = Join-Path $localFolder $scriptName

    Write-Host "🔍 Checking if local script exists..." -ForegroundColor Cyan
    if (-not (Test-Path $localScriptPath)) {
      Write-Host "❌ Could not find eagle.ps1 in the root of the Scripts folder." -ForegroundColor Red
      return
    }

    $remoteScriptPath = Join-Path $extractedFolder $scriptName

    Write-Host "🔍 Extracting version info..." -ForegroundColor Cyan
    $localVersionLine = Get-Content -Path $localScriptPath | Where-Object { $_ -match '\$scriptVersion\s*=\s*"' }
    $remoteVersionLine = Get-Content -Path $remoteScriptPath | Where-Object { $_ -match '\$scriptVersion\s*=\s*"' }

    if (-not $localVersionLine -or -not $remoteVersionLine) {
      Write-Host "❌ Could not extract script version from one of the files." -ForegroundColor Red
      return
    }

    $localVersion = ($localVersionLine -split '"')[1]
    $remoteVersion = ($remoteVersionLine -split '"')[1]

    Write-Host "📅 Local version: v$localVersion, Remote version: v$remoteVersion" -ForegroundColor Yellow

    if ([version]$remoteVersion -gt [version]$localVersion) {
      Write-Host "🔄 Update available! Local: $localVersion → Remote: $remoteVersion. Installing update…" -ForegroundColor Yellow

      $backupPath = "$localFolder-backup-" + (Get-Date -Format "yyyyMMddHHmmss")
      Write-Host "📦 Creating backup of current script folder..." -ForegroundColor Cyan
      Copy-Item -Path $localFolder -Destination $backupPath -Recurse
      Write-Host "✅ Backup created at $backupPath" -ForegroundColor Green

      Write-Host "📂 Updating eagle.ps1..." -ForegroundColor Cyan
      Copy-Item -Path $remoteScriptPath -Destination $localScriptPath -Force
      Write-Host "✅ eagle.ps1 updated successfully." -ForegroundColor Green

  
      Write-Host "📂 Updating files in 'eagle' subfolder..." -ForegroundColor Cyan
      $extractedEagleFolder = Join-Path $extractedFolder 'eagle'
      Get-ChildItem -Path $extractedEagleFolder -Recurse | ForEach-Object {
        $relativePath = $_.FullName.Substring($extractedEagleFolder.Length)
        $destinationPath = Join-Path (Join-Path $localFolder 'eagle') $relativePath.TrimStart('\')
        if ($_.PSIsContainer) {
          if (-not (Test-Path $destinationPath)) {
            New-Item -ItemType Directory -Path $destinationPath | Out-Null
          }
        }
        else {
          Copy-Item -Path $_.FullName -Destination $destinationPath -Force
        }
      }
      Write-Host "✅ Files in 'eagle' subfolder updated." -ForegroundColor Green

      Write-Host "🧹 Cleaning up backup folder..." -ForegroundColor Cyan
      Remove-Item -Path $backupPath -Recurse -Force -ErrorAction SilentlyContinue
      Write-Host "✅ Backup folder deleted successfully." -ForegroundColor Green
    }
    else {
      Write-Host "✅ You already have the latest version (v$localVersion)." -ForegroundColor Green
    }
  }
  catch {
    Write-Host "❌ Update failed (SEND DM TO PRODBYEAGLE ON DISCORD): $_" -ForegroundColor Red
  }
  finally {
    Write-Host "🧹 Cleaning up temporary files..." -ForegroundColor Cyan
    Remove-Item -Path $tempZipPath -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $tempExtractPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✅ Temporary files cleaned up." -ForegroundColor Green
  }
}
