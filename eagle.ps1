param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("-s", "-v", "-e", "-h", "help")]
    [string]$option = "-h"
)

function Show-Help {
    Write-Host "`nAvailable commands:" -ForegroundColor Yellow
    Write-Host "  -s    : Installs Spicetify" -ForegroundColor Cyan
    Write-Host "  -v    : Launches or downloads VencordInstallerCli.exe" -ForegroundColor Cyan
    Write-Host "  -e    : Runs '@library Check' (placeholder)" -ForegroundColor Cyan
    Write-Host "  -h    : Displays this help message" -ForegroundColor Cyan
}

switch ($option.ToLower()) {
    "-e" {
        Write-Host "@library Check has started (placeholder)" -ForegroundColor Cyan
        # TODO: Implement @library Check logic here
    }
    "-s" {
        Write-Host "Starting Spicetify installer..." -ForegroundColor Cyan
        try {
            Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/spicetify/cli/main/install.ps1" | Invoke-Expression
            Write-Host "✅ Spicetify successfully installed!" -ForegroundColor Green
        }
        catch {
            Write-Host "❌ Error installing Spicetify: $_" -ForegroundColor Red
        }
    }
    "-v" {
        $userProfile = $env:USERPROFILE
        $vencordDir = "$userProfile\Vencord"
        $vencordExe = "$vencordDir\VencordInstallerCli.exe"
        $vencordUrl = "https://github.com/Vendicated/VencordInstaller/releases/latest/download/VencordInstallerCli.exe"

        if (-not (Test-Path $vencordExe)) {
            Write-Host "VencordInstallerCli.exe not found. Downloading..." -ForegroundColor Yellow
            try {
                New-Item -ItemType Directory -Force -Path $vencordDir | Out-Null
                Invoke-WebRequest -Uri $vencordUrl -OutFile $vencordExe
                Write-Host "✅ VencordInstallerCli.exe successfully downloaded." -ForegroundColor Green
            }
            catch {
                Write-Host "❌ Error downloading Vencord: $_" -ForegroundColor Red
                return
            }
        }

        Write-Host "Launching VencordInstallerCli.exe..." -ForegroundColor Cyan
        Start-Process $vencordExe
    }
    "-h" {
        Show-Help
    }
    "help" {
        Show-Help
    }
    default {
        Write-Host "❌ Unknown command: '$option'" -ForegroundColor Red
        Show-Help
    }
}
