function Show-ServerSelector {
  $rootPath = "$env:USERPROFILE\Documents\mc-servers"
  if (-not (Test-Path $rootPath)) {
    Write-Host "❌ No mc-server directory found at $rootPath" -ForegroundColor Red
    return $null
  }

  $servers = Get-ChildItem -Path $rootPath -Directory | Where-Object {
    Test-Path (Join-Path $_.FullName "server.jar")
  }

  if ($servers.Count -eq 0) {
    Write-Host "❌ No servers with server.jar found in $rootPath" -ForegroundColor Red
    return $null
  }

  $selectedIndex = 0
  function Render {
    Clear-Host
    Write-Host "🎮 Choose a Minecraft server to start:`n" -ForegroundColor Cyan
    for ($i = 0; $i -lt $servers.Count; $i++) {
      if ($i -eq $selectedIndex) {
        Write-Host "> $($servers[$i].Name)" -ForegroundColor Yellow
      }
      else {
        Write-Host "  $($servers[$i].Name)"
      }
    }
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
    Write-Host "❌ server.jar not found in $serverPath" -ForegroundColor Red
    return
  }

  Write-Host "🚀 Starting Minecraft server in $serverPath with ${RamMB}MB RAM..." -ForegroundColor Cyan
  Set-Location $serverPath

  $javaCmd = "java -Xmx${RamMB}M -Xms${RamMB}M -jar `"$jarPath`" nogui"
  Start-Process -NoNewWindow -Wait -FilePath "cmd.exe" -ArgumentList "/c $javaCmd"

  Write-Host "✅ Server process exited." -ForegroundColor Green
}
