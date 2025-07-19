function Install-EagleCord {
  param (
    [switch]$re
  )

  $ErrorActionPreference = "Stop"

  $repoUrl = "https://github.com/prodbyeagle/cord"
  $repoName = "Vencord"
  $vencordTempDir = Join-Path $env:APPDATA "EagleCord"
  $vencordCloneDir = Join-Path $vencordTempDir $repoName

  try {
    Write-Host "🔍 Checking for Bun runtime..." -ForegroundColor Cyan
    bun --version > $null 2>&1
    if ($LASTEXITCODE -ne 0) {
      Write-Host "📥 Bun not found. Installing Bun..." -ForegroundColor Yellow
      powershell -c "irm bun.sh/install.ps1 | iex"

      $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    }
    else {
      Write-Host "✅ Bun is already installed." -ForegroundColor Green
    }

    if ($re -and (Test-Path $vencordCloneDir)) {
      Write-Host "🗑️  Removing existing repo directory for reinstall..." -ForegroundColor Yellow
      Remove-Item -Recurse -Force -Path $vencordCloneDir
    }

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

    if (Test-Path "./dist") {
      Write-Host "🧹 Cleaning dist folder..." -ForegroundColor Magenta
      Remove-Item -Recurse -Force "./dist"
    }

    Write-Host "`n📦 Installing dependencies..." -ForegroundColor Yellow
    bun install
    Write-Host "✅ Dependency installation complete." -ForegroundColor Green

    # 🔗 Bun link step for packages/discord-types
    $discordTypesPath = Join-Path $vencordCloneDir "packages/discord-types"
    if (Test-Path $discordTypesPath) {
      Write-Host "🔗 Linking @vencord/discord-types..." -ForegroundColor Cyan
      Push-Location $discordTypesPath
      bun link
      Pop-Location
    }
    else {
      Write-Host "⚠️ Could not find packages/discord-types to link." -ForegroundColor Yellow
    }

  }
  catch {
    Write-Host "❌ Setup failed: $_" -ForegroundColor Red
    return
  }

  try {
    Write-Host "`n🦅 Injecting EagleCord..." -ForegroundColor Yellow
    bun run build
    bun inject
    Write-Host "✅ EagleCord injected successfully." -ForegroundColor Green
    Set-Location -Path $HOME
  }
  catch {
    Write-Host "❌ Failed during inject step: $_" -ForegroundColor Red
    return
  }

  Write-Host "`n🎉 Vencord installation complete." -ForegroundColor Cyan
}
