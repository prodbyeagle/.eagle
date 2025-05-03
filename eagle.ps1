param (
  [Parameter(Mandatory = $false, Position = 0)]
  [string]$option = "help",
  [string]$name,
  [string]$template
)

$scriptVersion = "2.5.2"

#! LOGIC

function Uninstall-Script {
  $scriptPath = "C:\Scripts"
  $eaglePath = "$scriptPath\eagle.ps1"
  $eagleFolder = "$scriptPath\eagle"
  $profilePath = $PROFILE

  Write-Host "🛑 You are about to uninstall eagle." -ForegroundColor Yellow
  $confirmation = Read-Host "Are you sure you want to continue? (y/n)"

  if ($confirmation.ToLower() -ne 'y' -and $confirmation.ToLower() -ne 'yes') {
    Write-Host "❌ Uninstallation cancelled." -ForegroundColor Red
    return
  }

  Write-Host "Uninstalling eagle..." -ForegroundColor Cyan

  try {
    if (Test-Path $eaglePath) {
      Remove-Item $eaglePath -Force
      Write-Host "✅ Removed eagle.ps1 from $eaglePath" -ForegroundColor Green
    }
    else {
      Write-Host "ℹ eagle.ps1 not found at $eaglePath" -ForegroundColor Yellow
    }

    if (Test-Path $eagleFolder) {
      Remove-Item $eagleFolder -Recurse -Force
      Write-Host "✅ Removed eagle folder and its contents from $eagleFolder" -ForegroundColor Green
    }
    else {
      Write-Host "ℹ eagle folder not found at $eagleFolder" -ForegroundColor Yellow
    }

    if (Test-Path $profilePath) {
      $profileContent = Get-Content $profilePath
      $filteredContent = $profileContent | Where-Object { $_ -notmatch "Set-Alias eagle" }
      Set-Content $profilePath -Value $filteredContent
      Write-Host "✅ Removed alias from PowerShell profile" -ForegroundColor Green
    }

    if ((Test-Path $scriptPath) -and ((Get-ChildItem $scriptPath).Count -eq 0)) {
      Remove-Item $scriptPath -Force
      Write-Host "✅ Removed empty folder $scriptPath" -ForegroundColor Green
    }

    Write-Host "🎉 Uninstallation complete." -ForegroundColor Green
  }
  catch {
    Write-Host "❌ Failed to uninstall eagle  ( SEND DM TO PRODBYEAGLE ON DISCORD ): $_" -ForegroundColor Red
  }
}


function Show-Version {
  param (
    [string]$Version
  )

  Write-Host ""
  Write-Host "🦅 eaglePower" -ForegroundColor Yellow
  Write-Host "────────────────────────────"
  Write-Host "Version        : $Version" -ForegroundColor Green
  Write-Host "Repository     : https://github.com/prodbyeagle/eaglePowerShell" -ForegroundColor Cyan
  Write-Host "────────────────────────────"
}


function Show-Help {
  Write-Host ""
  Write-Host "🦅 eaglePower — Available Commands" -ForegroundColor Yellow
  Write-Host "─────────────────────────────────────────────"

  $commands = @(
    @{ Cmd = "spicetify"; Alias = "--s"; Desc = "Installs Spicetify" },
    @{ Cmd = "vencord"; Alias = "--ven"; Desc = "Launches or downloads the Vencord Installer" },
    @{ Cmd = "update"; Alias = "--u"; Desc = "Checks for updates to eagle and installs if needed" },
    @{ Cmd = "uninstall"; Alias = "--rem"; Desc = "Removes eagle and cleans up the alias and folder" },
    @{ Cmd = "version"; Alias = "--v"; Desc = "Displays the current version of the eagle script" },
    @{ Cmd = "help"; Alias = "--h"; Desc = "Displays this help message" },
    @{ Cmd = "apps"; Alias = "--a"; Desc = "Updates all applications via winget" }
  )

  foreach ($c in $commands) {
    $line = "{0,-10} {1,-10} : {2}" -f $c.Cmd, "($($c.Alias))", $c.Desc
    Write-Host "  $line" -ForegroundColor Blue
  }

  Write-Host "─────────────────────────────────────────────"
}


function Install-Vencord {
  $userProfile = $env:USERPROFILE
  $vencordDir = Join-Path $userProfile 'Vencord'
  $vencordExe = Join-Path $vencordDir 'VencordInstallerCli.exe'
  $vencordUrl = "https://github.com/Vendicated/VencordInstaller/releases/latest/download/VencordInstallerCli.exe"
  $expectedMinSize = 5772800

  Write-Host "`n🧩 Checking for Vencord Installer..." -ForegroundColor Yellow

  if (Test-Path $vencordExe) {
    $fileSize = (Get-Item $vencordExe).Length
    Write-Host "🔍 Found existing installer at: $vencordExe" -ForegroundColor Cyan

    if ($fileSize -lt $expectedMinSize) {
      Write-Host "⚠️  File appears to be corrupted (size: $fileSize bytes). Re-downloading..." -ForegroundColor Red
      Remove-Item $vencordExe -Force -ErrorAction SilentlyContinue
    }
    else {
      Write-Host "✅ Installer is valid. Launching..." -ForegroundColor Green
      Start-Process -FilePath $vencordExe
      return
    }
  }
  else {
    Write-Host "❌ Installer not found. Preparing to download..." -ForegroundColor Yellow
  }

  try {
    New-Item -ItemType Directory -Force -Path $vencordDir | Out-Null
    Write-Host "🌐 Downloading Vencord Installer..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $vencordUrl -OutFile $vencordExe -UseBasicParsing -ErrorAction Stop
    Write-Host "✅ Download completed: $vencordExe" -ForegroundColor Green
  }
  catch {
    Write-Host "❌ Failed to download Vencord Installer (SEND DM TO PRODBYEAGLE ON DISCORD): $_" -ForegroundColor Red
    return
  }

  try {
    if (Test-Path $vencordExe) {
      Write-Host "🚀 Launching Vencord Installer..." -ForegroundColor Cyan
      Start-Process -FilePath $vencordExe
    }
    else {
      Write-Host "❌ Installer missing after download: $vencordExe (SEND DM TO PRODBYEAGLE ON DISCORD)" -ForegroundColor Red
    }
  }
  catch {
    Write-Host "❌ Failed to launch installer (SEND DM TO PRODBYEAGLE ON DISCORD): $_" -ForegroundColor Red
  }
}


function Install-Spicetify {
  Write-Host "`n🎵 Installing Spicetify..." -ForegroundColor Cyan

  $installUrl = "https://raw.githubusercontent.com/spicetify/cli/main/install.ps1"

  try {
    Write-Host "🌐 Downloading installer script from:" -ForegroundColor Yellow
    Write-Host "   $installUrl" -ForegroundColor Cyan

    $scriptContent = Invoke-WebRequest -UseBasicParsing -Uri $installUrl -ErrorAction Stop
    Invoke-Expression $scriptContent.Content

    Write-Host "✅ Spicetify installed successfully!" -ForegroundColor Green
  }
  catch {
    Write-Host "❌ Failed to install Spicetify (SEND DM TO PRODBYEAGLE ON DISCORD): $_" -ForegroundColor Red
  }
}


function Install-Project {
  param (
    [string]$name,
    [string]$template
  )

  if (-not $name) {
    $name = Read-Host "📝 Enter project name"
  }

  if (-not $template) {
    Write-Host "📦 Available templates:" -ForegroundColor Cyan
    Write-Host " - discord" -ForegroundColor Yellow
    Write-Host " - next" -ForegroundColor Yellow
    $template = Read-Host "📌 Choose a template"
  }

  $targetRoot = switch ($template.ToLower()) {
    "discord" { "D:\VSCode\2025\Discord" }
    "next" { "D:\VSCode\2025\Frontend" }
    default {
      Write-Host "❌ Invalid template: '$template'. Allowed: discord, next" -ForegroundColor Red
      return
    }
  }

  $projectPath = Join-Path $targetRoot $name
  if (Test-Path $projectPath) {
    Write-Host "⚠️ Project '$name' already exists at $projectPath" -ForegroundColor Yellow
    return
  }

  $repoUrl = switch ($template.ToLower()) {
    "discord" { "https://github.com/prodbyeagle/EagleBotTemplate.git" }
    "next" { "https://github.com/prodbyeagle/Eagle-NextJS-Template.git" }
  }

  Write-Host "📁 Creating new '$template' project: $name" -ForegroundColor Cyan
  Write-Host "🔗 Cloning from $repoUrl to $projectPath..." -ForegroundColor Gray

  git clone $repoUrl $projectPath

  if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Project '$name' created at $projectPath" -ForegroundColor Green
  }
  else {
    Write-Host "❌ Git clone failed." -ForegroundColor Red
  }
}

function Update-Script {
  $localFolder = 'C:\Scripts'
  $scriptName = 'eagle.ps1'
  $remoteZipUrl = 'https://github.com/prodbyeagle/eaglePowerShell/archive/refs/heads/main.zip'
  $tempZipPath = Join-Path $env:TEMP "eagle_update.zip"
  $tempExtractPath = Join-Path $env:TEMP "eagle_update"

  Write-Host "📦 Checking for updates..." -ForegroundColor Cyan

  Write-Host "Local Folder: $localFolder" -ForegroundColor Yellow
  Write-Host "Script Path to check: $($localFolder)\$scriptName" -ForegroundColor Yellow

  try {
    Write-Host "🔄 Fetching the latest version from GitHub..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $remoteZipUrl -OutFile $tempZipPath -UseBasicParsing -ErrorAction Stop
    Write-Host "✅ Latest version fetched successfully from GitHub." -ForegroundColor Green

    Write-Host "📦 Extracting update package..." -ForegroundColor Cyan
    Expand-Archive -Path $tempZipPath -DestinationPath $tempExtractPath -Force
    Write-Host "✅ Update package extracted successfully." -ForegroundColor Green

    $extractedFolder = Join-Path $tempExtractPath 'eaglePowerShell-main'
    $localScriptPath = Join-Path $localFolder $scriptName

    Write-Host "🔍 Checking if local script exists..." -ForegroundColor Cyan
    if (-not (Test-Path $localScriptPath)) {
      Write-Host "❌ Could not find eagle.ps1 in the root of the Scripts folder." -ForegroundColor Red
      return
    }

    $remoteScriptPath = Join-Path $extractedFolder $scriptName

    Write-Host "🔍 Extracting version info..." -ForegroundColor Cyan
    $localVersionLine = Get-Content -Path $localScriptPath | Where-Object { $_ -match '\$scriptVersion\s*=\s*"' }
    $remoteVersionLine = Get-Content -Path $remoteScriptPath | Where-Object { $_ -match '\$scriptVersion\s*=\s*"' }

    if (-not $localVersionLine -or -not $remoteVersionLine) {
      Write-Host "❌ Could not extract script version from one of the files." -ForegroundColor Red
      return
    }

    $localVersion = ($localVersionLine -split '"')[1]
    $remoteVersion = ($remoteVersionLine -split '"')[1]

    Write-Host "📅 Local version: v$localVersion, Remote version: v$remoteVersion" -ForegroundColor Yellow

    if ([version]$remoteVersion -gt [version]$localVersion) {
      Write-Host "🔄 Update available! Local: $localVersion → Remote: $remoteVersion. Installing update…" -ForegroundColor Yellow

      $backupPath = "$localFolder-backup-" + (Get-Date -Format "yyyyMMddHHmmss")
      Write-Host "📦 Creating backup of current script folder..." -ForegroundColor Cyan
      Copy-Item -Path $localFolder -Destination $backupPath -Recurse
      Write-Host "✅ Backup created at $backupPath" -ForegroundColor Green

      Write-Host "📂 Updating eagle.ps1..." -ForegroundColor Cyan
      Copy-Item -Path $remoteScriptPath -Destination $localScriptPath -Force
      Write-Host "✅ eagle.ps1 updated successfully." -ForegroundColor Green

      Write-Host "🧹 Cleaning up backup folder..." -ForegroundColor Cyan
      Remove-Item -Path $backupPath -Recurse -Force -ErrorAction SilentlyContinue
      Write-Host "✅ Backup folder deleted successfully." -ForegroundColor Green
    }
    else {
      Write-Host "✅ You already have the latest version (v$localVersion)." -ForegroundColor Green
    }
  }
  catch {
    Write-Host "❌ Update failed (SEND DM TO PRODBYEAGLE ON DISCORD): $_" -ForegroundColor Red
  }
  finally {
    Write-Host "🧹 Cleaning up temporary files..." -ForegroundColor Cyan
    Remove-Item -Path $tempZipPath -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $tempExtractPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✅ Temporary files cleaned up." -ForegroundColor Green
  }
}

$normalized = switch ($option.ToLower()) {
  "--h" { "help" }
  "--v" { "version" }
  "--s" { "spicetify" }
  "--ven" { "vencord" }
  "--u" { "update" }
  "--rem" { "uninstall" }
  "--c" { "create" }
  default { $option.ToLower() }
}

switch ($normalized) {
  "spicetify" { Install-Spicetify }
  "vencord" { Install-Vencord }
  "uninstall" { Uninstall-Script }
  "version" { Show-Version -Version $scriptVersion }
  "update" { Update-Script }
  "create" { Install-Project -name $name -template $template }
  "help" { Show-Help }
  default {
    Write-Host "❌ Unknown command: '$option'. Use 'eagle help' for a list of available commands." -ForegroundColor DarkRed
    exit 1
  }
}
