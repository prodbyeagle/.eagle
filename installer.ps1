# === Einstellungen ===
$scriptPath = "C:\Scripts"
$eagleUrl = "https://raw.githubusercontent.com/dein-user/dein-repo/main/eagle.ps1"
$eagleLocalPath = "$scriptPath\eagle.ps1"

if (!(Test-Path $scriptPath)) {
    Write-Host "📁 Erstelle Skript-Ordner: $scriptPath"
    New-Item -ItemType Directory -Path $scriptPath -Force | Out-Null
}

try {
    Write-Host "⬇ Lade eagle.ps1 von $eagleUrl ..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $eagleUrl -OutFile $eagleLocalPath -UseBasicParsing
    Write-Host "✅ eagle.ps1 gespeichert unter: $eagleLocalPath" -ForegroundColor Green
}
catch {
    Write-Host "❌ Fehler beim Laden von eagle.ps1: $_" -ForegroundColor Red
    exit 1
}

$profilePath = $PROFILE
if (!(Test-Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
}

$aliasLine = "Set-Alias eagle `"$eagleLocalPath`""
if (-not (Get-Content $profilePath | Select-String -SimpleMatch $aliasLine)) {
    Write-Host "🔧 Füge Alias 'eagle' zum PowerShell-Profil hinzu..."
    Add-Content -Path $profilePath -Value "`n$aliasLine"
    Write-Host "✅ Alias hinzugefügt. Bitte starte PowerShell neu."
}
else {
    Write-Host "ℹ Alias 'eagle' ist bereits im Profil vorhanden."
}

# === Ordner zu PATH hinzufügen ===
if ($env:Path -notlike "*$scriptPath*") {
    Write-Host "🔧 Füge $scriptPath zur PATH-Umgebungsvariablen hinzu..."
    [Environment]::SetEnvironmentVariable("Path", $env:Path + ";$scriptPath", [EnvironmentVariableTarget]::User)
    Write-Host "✅ PATH erfolgreich aktualisiert. Bitte PowerShell neu starten."
}
else {
    Write-Host "ℹ $scriptPath ist bereits im PATH enthalten."
}

Write-Host "`n🎉 Installation abgeschlossen! Benutze den Befehl 'eagle -option s/v/e'" -ForegroundColor Green
