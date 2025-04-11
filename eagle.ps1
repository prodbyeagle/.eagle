param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("s", "v", "e", "h", "help")]
    [string]$option = "h"
)

function Show-Help {
    Write-Host "`nVerfügbare Befehle:" -ForegroundColor Yellow
    Write-Host "  s    : Installiert Spicetify" -ForegroundColor Cyan
    Write-Host "  v    : Startet oder lädt VencordInstallerCli.exe" -ForegroundColor Cyan
    Write-Host "  e    : Führt '@library Check' aus (Platzhalter)" -ForegroundColor Cyan
    Write-Host "  h    : Zeigt diese Hilfe an" -ForegroundColor Cyan
}

switch ($option.ToLower()) {
    "e" {
        Write-Host "@library Check wurde gestartet (Platzhalter)" -ForegroundColor Cyan
        # TODO: @library Check implementation here
    }
    "s" {
        Write-Host "Starte Spicetify-Installer..." -ForegroundColor Cyan
        try {
            Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/spicetify/cli/main/install.ps1" | Invoke-Expression
            Write-Host "✅ Spicetify erfolgreich installiert!" -ForegroundColor Green
        }
        catch {
            Write-Host "❌ Fehler beim Installieren von Spicetify: $_" -ForegroundColor Red
        }
    }
    "v" {
        $userProfile = $env:USERPROFILE
        $vencordDir = "$userProfile\Vencord"
        $vencordExe = "$vencordDir\VencordInstallerCli.exe"
        $vencordUrl = "https://github.com/Vendicated/VencordInstaller/releases/latest/download/VencordInstallerCli.exe"

        if (-not (Test-Path $vencordExe)) {
            Write-Host "VencordInstallerCli.exe nicht gefunden. Lade herunter..." -ForegroundColor Yellow
            try {
                New-Item -ItemType Directory -Force -Path $vencordDir | Out-Null
                Invoke-WebRequest -Uri $vencordUrl -OutFile $vencordExe
                Write-Host "✅ VencordInstallerCli.exe heruntergeladen." -ForegroundColor Green
            }
            catch {
                Write-Host "❌ Fehler beim Herunterladen: $_" -ForegroundColor Red
                return
            }
        }

        Write-Host "Starte VencordInstallerCli.exe..." -ForegroundColor Cyan
        Start-Process $vencordExe
    }
    "h" {
        Show-Help
    }
    "help" {
        Show-Help
    }
    default {
        Write-Host "❌ Unbekannter Befehl: '$option'" -ForegroundColor Red
        Show-Help
    }
}
