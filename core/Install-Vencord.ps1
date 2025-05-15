function Install-Vencord {
  $ErrorActionPreference = "Stop"

  $repoUrl = "https://github.com/prodbyeagle/Vencord"
  $repoName = "Vencord"
  $vencordTempDir = Join-Path $env:APPDATA "EagleCord"
  $vencordCloneDir = Join-Path $vencordTempDir $repoName

  try {
    if (Test-Path $vencordCloneDir) {
      Set-Location -Path $vencordCloneDir
      $localHash = git rev-parse HEAD
      $remoteHash = git ls-remote $repoUrl HEAD | ForEach-Object { $_.Split("`t")[0] }

      if ($localHash -eq $remoteHash) {
        Write-Host "🔁 Repo is up-to-date (commit: $localHash)" -ForegroundColor Cyan
      }
      else {
        Write-Host "♻️  Updating to latest commit..." -ForegroundColor Yellow
        git fetch origin
        git reset --hard origin/main
      }
    }
    else {
      Write-Host "📁 Cloning fresh copy of repo..." -ForegroundColor Yellow
      git clone $repoUrl $vencordCloneDir
      Set-Location -Path $vencordCloneDir
    }

    Write-Host "`n📦 Installing dependencies..." -ForegroundColor Yellow
    bun i
    Write-Host "✅ Dependency installation complete." -ForegroundColor Green
  }
  catch {
    Write-Host "❌ Setup failed: $_" -ForegroundColor Red
    return
  }

  try {
    Write-Host "`n🛠 Injecting Vencord..." -ForegroundColor Yellow
    bun buildStandalone
    bun inject
    Write-Host "✅ Vencord injected successfully." -ForegroundColor Green
    Set-Location -Path $HOME
  }
  catch {
    Write-Host "❌ Failed during inject step: $_" -ForegroundColor Red
    return
  }

  Write-Host "`n🎉 Vencord installation complete." -ForegroundColor Cyan
}
