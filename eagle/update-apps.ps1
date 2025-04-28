# utils-update-all.ps1
function Test-WingetInstalled {
  Write-Host "🔍 Checking for winget..." -ForegroundColor Cyan

  $wingetPath = Get-Command winget -ErrorAction SilentlyContinue

  if (-not $wingetPath) {
    Write-Host "⚠ winget not found. Installing..." -ForegroundColor Yellow
    Install-Winget
  }
  else {
    Write-Host "✅ winget is available." -ForegroundColor Green
    Test-WingetUpdate
  }
}

function Install-Winget {
  try {
    $installerUrl = "https://aka.ms/getwinget"
    $installerPath = [System.IO.Path]::GetTempFileName() + ".msixbundle"

    Write-Host "⬇ Downloading winget installer from $installerUrl ..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing

    Write-Host "🚀 Installing winget..." -ForegroundColor Cyan
    Add-AppxPackage -Path $installerPath

    Write-Host "✅ winget installed successfully." -ForegroundColor Green
  }
  catch {
    Write-Host "❌ Failed to install winget: $_" -ForegroundColor Red
    exit 1
  }
}

function Test-WingetUpdate {
  try {
    Write-Host "🔍 Testing for winget updates..." -ForegroundColor Cyan
    $wingetUpgrade = winget upgrade --name "App Installer" --source winget | Out-String

    if ($wingetUpgrade -match "No applicable update found") {
      Write-Host "✅ winget is already up-to-date." -ForegroundColor Green
    }
    else {
      Write-Host "⬆ Updating winget (App Installer)..." -ForegroundColor Yellow
      winget upgrade --name "App Installer" --source winget --accept-source-agreements --accept-package-agreements
      Write-Host "✅ winget updated successfully." -ForegroundColor Green
    }
  }
  catch {
    Write-Host "❌ Error testing/updating winget: $_" -ForegroundColor Red
    exit 1
  }
}

function Update-All-Applications {
  Write-Host "🔄 Updating all applications via winget..." -ForegroundColor Cyan
  try {
    winget upgrade --all --accept-source-agreements --accept-package-agreements
    Write-Host "🎉 All applications updated successfully." -ForegroundColor Green
  }
  catch {
    Write-Host "❌ Failed to update some applications: $_" -ForegroundColor Red
  }
}
