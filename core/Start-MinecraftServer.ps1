function Show-ServerSelector {
  $rootPath = "$env:USERPROFILE\Documents\mc-servers"
  if (-not (Test-Path $rootPath)) {
    Write-Host "oh. ich habe $rootPath nicht gefunden. stelle sicher das du den ordner erstellt hast, und ein minecraft server vorhanden ist." -ForegroundColor Red
    return $null
  }

  $servers = Get-ChildItem -Path $rootPath -Directory | Where-Object {
    Test-Path (Join-Path $_.FullName "server.jar")
  }

  if ($servers.Count -eq 0) {
    Write-Host "oh. ich finde keinen server im $rootPath ordner, stelle sicher das du eine 'server.jar' im ordner hast." -ForegroundColor Red
    return $null
  }

  $selectedIndex = 0

  function Render {
    Clear-Host
    Write-Host "wähle einen minecraft server aus den du starten willst:`n" -ForegroundColor Cyan
    for ($i = 0; $i -lt $servers.Count; $i++) {
      $prefix = if ($i -eq $selectedIndex) { "> " } else { "  " }
      $name = $servers[$i].Name
      if ($i -eq $selectedIndex) {
        Write-Host "$prefix$name" -ForegroundColor Yellow
      }
      else {
        Write-Host "$prefix$name"
      }
    }
    Write-Host "`nuse ↑ ↓ to scroll. press enter to confirm." -ForegroundColor DarkGray
  }

  [Console]::CursorVisible = $false
  try {
    while ($true) {
      Render
      $key = [Console]::ReadKey($true)

      if ($key.Key -eq [ConsoleKey]::UpArrow -and $selectedIndex -gt 0) {
        $selectedIndex--
      }
      elseif ($key.Key -eq [ConsoleKey]::DownArrow -and $selectedIndex -lt ($servers.Count - 1)) {
        $selectedIndex++
      }
      elseif ($key.Key -eq [ConsoleKey]::Enter) {
        break
      }
    }

    return $servers[$selectedIndex].FullName
  }
  finally {
    [Console]::CursorVisible = $true
    Clear-Host
  }
}

function Start-MinecraftServer {
  param (
    [int]$RamMB = 2048
  )

  $serverPath = Show-ServerSelector
  if (-not $serverPath) {
    return
  }

  $jarPath = Join-Path $serverPath "server.jar"
  if (-not (Test-Path $jarPath)) {
    Write-Host "oh. ich finde keinen server im $serverPath ordner, stelle sicher das du eine 'server.jar' im ordner hast." -ForegroundColor Red
    return
  }

  Write-Host "ich starte $serverPath mit ${RamMB}mb ram..." -ForegroundColor Cyan
  Set-Location $serverPath

  $javaCmd = "java -Xmx${RamMB}M -Xms${RamMB}M -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Daikars.new.flags=true -Dusing.aikars.flags=https://mcutils.com -jar `"$jarPath`" nogui"
  Start-Process -NoNewWindow -Wait -FilePath "cmd.exe" -ArgumentList "/c $javaCmd"

  Write-Host "server gestoppt." -ForegroundColor Green
}
