param (
    [switch]$Dev
)

$scriptPath = "C:\Scripts"
$corePath = Join-Path $scriptPath "core"
$eagleUrl = "https://raw.githubusercontent.com/prodbyeagle/.eagle/main/eagle.ps1"
$coreBaseUrl = "https://raw.githubusercontent.com/prodbyeagle/.eagle/main/core"
$eagleLocalSource = "$PSScriptRoot\eagle.ps1"
$coreLocalSource = "$PSScriptRoot\core"
$eagleTargetFile = "$scriptPath\eagle.ps1"

function Log {
    param (
        [string]$Tag = "INFO",
        [string]$Message,
        [ConsoleColor]$Color = "Gray"
    )
    Write-Host "[$Tag] $Message" -ForegroundColor $Color
}

function New-Directory {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Log "INFO" "Created folder: $Path" "DarkGray"
    }
}

function Invoke-DownloadFile {
    param([string]$Uri, [string]$OutFile)
    try {
        Invoke-WebRequest -Uri $Uri -OutFile $OutFile -UseBasicParsing -ErrorAction Stop
    }
    catch {
        Log "ERROR" "✖ Couldn't download file from $Uri. Please check your internet connection and try again." "Red"
        exit 1
    }
}

function Get-CoreFiles {
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
        Log "STEP" "Downloading helper file: $file" "Cyan"
        Invoke-DownloadFile -Uri $remote -OutFile $local
    }
}

# Start
Log "INFO" "Starting Eagle setup..." "White"

New-Directory -Path $scriptPath
New-Directory -Path $corePath

if ($Dev) {
    Log "DEV" "Installing from local developer files..." "Yellow"
    Copy-Item -Path $eagleLocalSource -Destination $eagleTargetFile -Force -ErrorAction Stop
    Copy-Item -Path "$coreLocalSource\*" -Destination $corePath -Recurse -Force
}
else {
    Log "STEP" "Downloading the main Eagle script..." "Cyan"
    Invoke-DownloadFile -Uri $eagleUrl -OutFile $eagleTargetFile

    Log "STEP" "Downloading required helper files..." "Cyan"
    Get-CoreFiles
}

Log "SUCCESS" "✔ Eagle has been installed in C:\Scripts" "Green"

# Alias setup
if (-not (Test-Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}

$aliasLine = "Set-Alias eagle `"$eagleTargetFile`""
if (-not (Select-String -Path $PROFILE -Pattern ([regex]::Escape($aliasLine)) -Quiet)) {
    Add-Content -Path $PROFILE -Value "`n$aliasLine"
    Log "SUCCESS" "✔ You can now run 'eagle' from PowerShell." "Green"
}
else {
    Log "INFO" "Seems like 'eagle' was already installed, skipping step." "Gray"
}

# PATH setup
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$scriptPath*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$scriptPath", "User")
    Log "SUCCESS" "✔ Added Eagle folder to your PATH environment variable." "Green"
}
else {
    Log "INFO" "The Eagle folder is already in your system PATH." "Yellow"
}

# Done
Log "DONE" "`n✔ All done! Please restart PowerShell to use Eagle." "Cyan"
