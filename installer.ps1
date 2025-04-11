$scriptPath = "C:\Scripts"
$eagleUrl = "https://raw.githubusercontent.com/prodbyeagle/eaglePowerShell/refs/heads/main/eagle.ps1"
$eagleLocalPath = "$scriptPath\eagle.ps1"

if (!(Test-Path $scriptPath)) {
    Write-Host "📁 Creating script directory: $scriptPath"
    New-Item -ItemType Directory -Path $scriptPath -Force | Out-Null
}

try {
    Write-Host "⬇ Downloading eagle.ps1 from $eagleUrl ..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $eagleUrl -OutFile $eagleLocalPath -UseBasicParsing
    Write-Host "✅ eagle.ps1 saved at: $eagleLocalPath" -ForegroundColor Green
}
catch {
    Write-Host "❌ Error while downloading eagle.ps1: $_" -ForegroundColor Red
    exit 1
}

$profilePath = $PROFILE
if (!(Test-Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
}

$aliasLine = "Set-Alias eagle `"$eagleLocalPath`""
if (-not (Get-Content $profilePath | Select-String -SimpleMatch $aliasLine)) {
    Write-Host "🔧 Adding alias 'eagle' to PowerShell profile..."
    Add-Content -Path $profilePath -Value "`n$aliasLine"
    Write-Host "✅ Alias added. Please restart PowerShell to apply changes."
}
else {
    Write-Host "ℹ Alias 'eagle' is already present in your PowerShell profile."
}

if ($env:Path -notlike "*$scriptPath*") {
    Write-Host "🔧 Adding $scriptPath to PATH environment variable..."
    [Environment]::SetEnvironmentVariable("Path", $env:Path + ";$scriptPath", [EnvironmentVariableTarget]::User)
    Write-Host "✅ PATH updated successfully. Please restart PowerShell to apply changes."
}
else {
    Write-Host "ℹ $scriptPath is already in the system PATH."
}

Write-Host "`n🎉 Installation complete!" -ForegroundColor Green
