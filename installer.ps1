param (
    [switch]$Dev
)

$scriptPath = "C:\Scripts"
$eagleUrl = "https://raw.githubusercontent.com/prodbyeagle/eaglePowerShell/refs/heads/main/eagle.ps1"
$eagleLocalSource = "$PSScriptRoot\eagle.ps1"
$eagleTargetFile = "$scriptPath\eagle.ps1"

function New-Directory {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Invoke-DownloadFile {
    param([string]$Uri, [string]$OutFile)
    try {
        Invoke-WebRequest -Uri $Uri -OutFile $OutFile -UseBasicParsing -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to download $Uri - $_"
        exit 1
    }
}

New-Directory -Path $scriptPath

if ($Dev) {
    Write-Host "⚙ Installing eagle.ps1 from local source..." -ForegroundColor Yellow
    Copy-Item -Path $eagleLocalSource -Destination $eagleTargetFile -Force -ErrorAction Stop
}
else {
    Write-Host "⬇ Downloading eagle.ps1 from $eagleUrl" -ForegroundColor Cyan
    Invoke-DownloadFile -Uri $eagleUrl -OutFile $eagleTargetFile
}
Write-Host "✅ eagle.ps1 installed to $eagleTargetFile" -ForegroundColor Green

if (-not (Test-Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}
$aliasLine = "Set-Alias eagle `"$eagleTargetFile`""
if (-not (Select-String -Path $PROFILE -Pattern ([regex]::Escape($aliasLine)) -Quiet)) {
    Add-Content -Path $PROFILE -Value "`n$aliasLine"
    Write-Host "🔧 Alias 'eagle' added to profile ($PROFILE)" -ForegroundColor Green
}
else {
    Write-Host "ℹ Alias already exists in profile" -ForegroundColor Yellow
}

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$scriptPath*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$scriptPath", "User")
    Write-Host "🔧 Added $scriptPath to user PATH" -ForegroundColor Green
}
else {
    Write-Host "ℹ $scriptPath already in user PATH" -ForegroundColor Yellow
}

Write-Host "`n🎉 Installation complete! Restart PowerShell to apply changes." -ForegroundColor Cyan
