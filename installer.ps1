param (
    [switch]$Dev
)

$scriptPath = "C:\Scripts"
$corePath = Join-Path $scriptPath "core"
$eagleUrl = "https://raw.githubusercontent.com/prodbyeagle/eaglePowerShell/main/eagle.ps1"
$coreBaseUrl = "https://raw.githubusercontent.com/prodbyeagle/eaglePowerShell/main/core"
$eagleLocalSource = "$PSScriptRoot\eagle.ps1"
$coreLocalSource = "$PSScriptRoot\core"
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
        Write-Error "❌ Failed to download $Uri - $_"
        exit 1
    }
}

function Download-CoreFiles {
    $coreFiles = @(
        "Install-Project.ps1",
        "Install-Spicetify.ps1",
        "Install-Vencord.ps1",
        "Show-Help.ps1",
        "Show-Version.ps1",
        "Uninstall-Script.ps1",
        "Update-Script.ps1"
    )
    foreach ($file in $coreFiles) {
        $remote = "$coreBaseUrl/$file"
        $local = Join-Path $corePath $file
        Write-Host "⬇ Downloading core/$file..." -ForegroundColor Cyan
        Invoke-DownloadFile -Uri $remote -OutFile $local
    }
}

New-Directory -Path $scriptPath
New-Directory -Path $corePath

if ($Dev) {
    Write-Host "⚙ Installing eagle.ps1 and core/ from local source..." -ForegroundColor Yellow
    Copy-Item -Path $eagleLocalSource -Destination $eagleTargetFile -Force -ErrorAction Stop
    Copy-Item -Path "$coreLocalSource\*" -Destination $corePath -Recurse -Force
}
else {
    Write-Host "⬇ Downloading eagle.ps1 from $eagleUrl" -ForegroundColor Cyan
    Invoke-DownloadFile -Uri $eagleUrl -OutFile $eagleTargetFile

    Write-Host "📦 Downloading core/ modules..." -ForegroundColor Cyan
    Download-CoreFiles
}

Write-Host "✅ eagle.ps1 and core/ installed to $scriptPath" -ForegroundColor Green

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
