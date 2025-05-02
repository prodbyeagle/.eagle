function Update-Script {
  $localFolder = $PSScriptRoot
  $scriptName = 'eagle.ps1'
  $remoteZipUrl = 'https://github.com/prodbyeagle/eaglePowerShell/archive/refs/heads/main.zip'
  $tempZipPath = Join-Path $env:TEMP "eagle_update.zip"
  $tempExtractPath = Join-Path $env:TEMP "eagle_update"

  Write-Host "📦 Checking for updates..." -ForegroundColor Cyan

  try {
    Invoke-WebRequest -Uri $remoteZipUrl -OutFile $tempZipPath -UseBasicParsing -ErrorAction Stop
    Expand-Archive -Path $tempZipPath -DestinationPath $tempExtractPath -Force

    $extractedFolder = Join-Path $tempExtractPath 'eaglePowerShell-main'
    $localScriptPath = Get-ChildItem -Path $localFolder -Recurse -Filter $scriptName -File -ErrorAction SilentlyContinue |
    Select-Object -First 1

    if (-not $localScriptPath) {
      $parent = Split-Path -Path $localFolder -Parent
      $localScriptPath = Get-ChildItem -Path $parent -Recurse -Filter $scriptName -File -ErrorAction SilentlyContinue |
      Select-Object -First 1
    }

    if (-not $localScriptPath) {
      Write-Host "❌ Could not find eagle.ps1 in current or parent folders." -ForegroundColor Red
      return
    }

    $localScriptPath = $localScriptPath.FullName
    $remoteScriptPath = Join-Path $extractedFolder $scriptName

    if (-not (Test-Path $localScriptPath)) {
      Write-Host "❌ Local eagle.ps1 not found: $localScriptPath" -ForegroundColor Red
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
      Write-Host "🔄 Update available ($localVersion → $remoteVersion). Installing…" -ForegroundColor Yellow

      $backupPath = "$localFolder-backup-" + (Get-Date -Format "yyyyMMddHHmmss")
      Copy-Item -Path $localFolder -Destination $backupPath -Recurse

      Get-ChildItem -Path $extractedFolder -Recurse | ForEach-Object {
        $relativePath = $_.FullName.Substring($extractedFolder.Length)
        $destinationPath = Join-Path $localFolder $relativePath.TrimStart('\')
        if ($_.PSIsContainer) {
          if (-not (Test-Path $destinationPath)) {
            New-Item -ItemType Directory -Path $destinationPath | Out-Null
          }
        }
        else {
          Copy-Item -Path $_.FullName -Destination $destinationPath -Force
        }
      }

      Write-Host "✅ [at]eagle PS updated to v$remoteVersion!" -ForegroundColor Green
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
