param (
    [switch]$Dev
)

$scriptPath = "C:\Scripts"
$eagleUrl = "https://raw.githubusercontent.com/prodbyeagle/eaglePowerShell/refs/heads/main/eagle.ps1"
$eagleLocalSource = "$PSScriptRoot\eagle.ps1"
$eagleLocalFolder = "$PSScriptRoot\eagle"
$eagleLocalTarget = "$scriptPath\eagle.ps1"
$eagleTargetFolder = "$scriptPath\eagle"

if (!(Test-Path $scriptPath)) {
    Write-Host "📁 Creating script directory: $scriptPath"
    New-Item -ItemType Directory -Path $scriptPath -Force | Out-Null
}

try {
    if ($Dev) {
        Write-Host "⚙ Installing eagle.ps1 from local development source..." -ForegroundColor Yellow
        Copy-Item -Path $eagleLocalSource -Destination $eagleLocalTarget -Force

        if (Test-Path $eagleLocalFolder) {
            Write-Host "📂 Copying eagle folder..." -ForegroundColor Yellow
            Copy-Item -Path $eagleLocalFolder -Destination $scriptPath -Recurse -Force
            Write-Host "✅ eagle folder copied to: $eagleTargetFolder" -ForegroundColor Green
        }
        else {
            Write-Host "❌ Local eagle folder not found. Cannot continue." -ForegroundColor Red
            exit 1
        }
        
        Write-Host "✅ eagle.ps1 and supporting files installed locally." -ForegroundColor Green
    }
    else {
        Write-Host "⬇ Downloading eagle.ps1 from $eagleUrl ..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $eagleUrl -OutFile $eagleLocalTarget -UseBasicParsing
        Write-Host "✅ eagle.ps1 downloaded to: $eagleLocalTarget" -ForegroundColor Green
    }
}
catch {
    Write-Host "❌ Error during eagle.ps1 installation: $_" -ForegroundColor Red
    exit 1
}

$profilePath = $PROFILE
if (!(Test-Path $profilePath)) {
    Write-Host "📄 Creating new PowerShell profile at: $profilePath"
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
}

$aliasLine = "Set-Alias eagle `"$eagleLocalTarget`""
$profileContent = Get-Content $profilePath -ErrorAction SilentlyContinue

if ($profileContent -notcontains $aliasLine) {
    Write-Host "🔧 Adding alias 'eagle' to PowerShell profile..."
    Add-Content -Path $profilePath -Value "`n$aliasLine"
    Write-Host "✅ Alias added. Please restart PowerShell to apply changes." -ForegroundColor Green
}
else {
    Write-Host "ℹ Alias 'eagle' already exists in PowerShell profile." -ForegroundColor Yellow
}

$userPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
if ($userPath -notlike "*$scriptPath*") {
    Write-Host "🔧 Adding $scriptPath to PATH environment variable..."
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$scriptPath", [EnvironmentVariableTarget]::User)
    Write-Host "✅ PATH updated successfully. Please restart PowerShell to apply changes." -ForegroundColor Green
}
else {
    Write-Host "ℹ $scriptPath is already in the PATH." -ForegroundColor Yellow
}

Write-Host "`n🎉 Installation complete!" -ForegroundColor Green
