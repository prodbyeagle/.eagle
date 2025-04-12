param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("spicetify", "vencord", "update", "uninstall", "version", "help")]
    [string]$option = "help"
)

$scriptVersion = "1.5.4"

function Show-Help {
    Write-Host "`nAvailable commands:" -ForegroundColor Yellow
    Write-Host "  spicetify    : Installs Spicetify" -ForegroundColor Cyan
    Write-Host "  vencord      : Launches or downloads the Vencord Installer" -ForegroundColor Cyan
    Write-Host "  update       : Checks for updates to the [at]eagle PS and installs if needed" -ForegroundColor Cyan
    Write-Host "  uninstall    : Removes [at]eagle PS and cleans up the alias and folder" -ForegroundColor Cyan
    Write-Host "  version      : Displays the current version of the eagle script" -ForegroundColor Cyan
    Write-Host "  help         : Displays this help message" -ForegroundColor Cyan
}

switch ($option.ToLower()) {
    "spicetify" {
        Write-Host "Starting Spicetify installer..." -ForegroundColor Cyan
        try {
            Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/spicetify/cli/main/install.ps1" | Invoke-Expression
            Write-Host "✅ Spicetify successfully installed!" -ForegroundColor Green
        }
        catch {
            Write-Host "❌ Error installing Spicetify: $_" -ForegroundColor Red
        }
    }

    "vencord" {
        $userProfile = $env:USERPROFILE
        $vencordDir = "$userProfile\Vencord"
        $vencordExe = "$vencordDir\VencordInstallerCli.exe"
        $vencordUrl = "https://github.com/Vendicated/VencordInstaller/releases/latest/download/VencordInstallerCli.exe"

        if (Test-Path $vencordExe) {
            Write-Host "ℹ Vencord Installer already exists. Launching..." -ForegroundColor Yellow
        }
        else {
            Write-Host "Vencord Installer not found. Downloading..." -ForegroundColor Yellow
            try {
                New-Item -ItemType Directory -Force -Path $vencordDir | Out-Null
                Invoke-WebRequest -Uri $vencordUrl -OutFile $vencordExe
                Write-Host "✅ Installer successfully downloaded." -ForegroundColor Green
            }
            catch {
                Write-Host "❌ Error downloading Vencord: $_" -ForegroundColor Red
                return
            }
        }

        Write-Host "Launching Vencord Installer..." -ForegroundColor Cyan
        Start-Process $vencordExe
    }

    "update" {
        $localScript = $MyInvocation.MyCommand.Path
        $remoteUrl = "https://raw.githubusercontent.com/prodbyeagle/eaglePowerShell/main/eagle.ps1"
        $tempFile = [System.IO.Path]::GetTempFileName()

        Write-Host "Checking for updates..." -ForegroundColor Cyan

        try {
            Invoke-WebRequest -Uri $remoteUrl -OutFile $tempFile -UseBasicParsing

            $localHash = Get-FileHash $localScript -Algorithm SHA256
            $remoteHash = Get-FileHash $tempFile -Algorithm SHA256

            if ($localHash.Hash -ne $remoteHash.Hash) {
                Write-Host "🔄 Update available! Installing update..." -ForegroundColor Yellow
                Copy-Item -Path $tempFile -Destination $localScript -Force
                Write-Host "✅ [at]eagle PS updated successfully!" -ForegroundColor Green
            }
            else {
                Write-Host "✅ You already have the latest version of [at]eagle PS." -ForegroundColor Green
            }

            Remove-Item $tempFile -Force
        }
        catch {
            Write-Host "❌ Failed to check or apply update: $_" -ForegroundColor Red
        }
    }

    "uninstall" {
        $scriptPath = "C:\Scripts"
        $eaglePath = "$scriptPath\eagle.ps1"
        $profilePath = $PROFILE

        Write-Host "Uninstalling eagle..." -ForegroundColor Cyan

        try {
            if (Test-Path $eaglePath) {
                Remove-Item $eaglePath -Force
                Write-Host "✅ Removed eagle.ps1 from $eaglePath" -ForegroundColor Green
            }
            else {
                Write-Host "ℹ eagle.ps1 not found at $eaglePath" -ForegroundColor Yellow
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
            Write-Host "❌ Failed to uninstall eagle: $_" -ForegroundColor Red
        }
    }

    "version" {
        Write-Host "`n[at]eagle PS version: $scriptVersion" -ForegroundColor Green
    }

    "help" {
        Show-Help
    }

    default {
        Write-Host "❌ Unknown command: '$option'" -ForegroundColor Red
        Show-Help
    }
}
