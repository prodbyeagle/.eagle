param (
    [switch]$Dev
)

$scriptPath = "C:\Scripts"
$eagleUrl = "https://raw.githubusercontent.com/prodbyeagle/eaglePowerShell/refs/heads/main/eagle.ps1"
$zipUrl = "https://github.com/prodbyeagle/eaglePowerShell/archive/refs/heads/main.zip"
$eagleLocalSource = "$PSScriptRoot\eagle.ps1"
$eagleSourceFolder = "$PSScriptRoot\eagle"
$eagleTargetFile = "$scriptPath\eagle.ps1"
$eagleTargetFolder = "$scriptPath\eagle"
$tempZipPath = Join-Path $env:TEMP "eagle-main.zip"
$tempExtractPath = Join-Path $env:TEMP "eagle-main"

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

if ($Dev) {
    if (Test-Path $eagleSourceFolder) {
        Write-Host "📂 Copying local eagle folder..." -ForegroundColor Yellow
        Copy-Item -Path $eagleSourceFolder -Destination $scriptPath -Recurse -Force -ErrorAction Stop
    }
    else {
        Write-Error "Local eagle folder not found at $eagleSourceFolder"
        exit 1
    }
}
else {
    Write-Host "⬇ Downloading full repo ZIP to gather eagle folder..." -ForegroundColor Cyan
    if (Test-Path $tempZipPath) { Remove-Item $tempZipPath -Force }
    Invoke-DownloadFile -Uri $zipUrl -OutFile $tempZipPath

    if (Test-Path $tempExtractPath) { Remove-Item $tempExtractPath -Recurse -Force }
    Expand-Archive -Path $tempZipPath -DestinationPath $tempExtractPath -ErrorAction Stop

    $extractedEagle = Join-Path $tempExtractPath "eaglePowerShell-main\eagle"
    if (Test-Path $extractedEagle) {
        Write-Host "📂 Copying eagle folder from ZIP..." -ForegroundColor Yellow
        Copy-Item -Path $extractedEagle -Destination $scriptPath -Recurse -Force -ErrorAction Stop
    }
    else {
        Write-Error "Cannot find 'eagle' folder inside ZIP at $extractedEagle"
        exit 1
    }

    Remove-Item $tempZipPath -Force
    Remove-Item $tempExtractPath -Recurse -Force
}
Write-Host "✅ eagle folder installed to $eagleTargetFolder" -ForegroundColor Green

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
