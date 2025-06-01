function Show-Animation {
  [CmdletBinding()]
  param (
    [int]$FrameDelayMs = 100
  )

  try {
    [Console]::CursorVisible = $false
    $Host.UI.RawUI.WindowTitle = "🦅 EAGLE VISION - SECRET MODE 🦅"

    $angle = 0
    while ($true) {
      # Dynamically get console size each frame in case of resize
      $consoleWidth = $Host.UI.RawUI.WindowSize.Width
      $consoleHeight = $Host.UI.RawUI.WindowSize.Height

      # Adjusted center offset (lower the cube rendering area)
      $centerX = [int]($consoleWidth / 2)
      $centerY = [int]($consoleHeight / 2 + 4)  # ⬅ Increase to lower the cube

      Clear-Host

      $cos = [Math]::Cos($angle)
      $sin = [Math]::Sin($angle)

      $vertices = @(
        @(-15, -15, -15), @(15, -15, -15), @(15, 15, -15), @(-15, 15, -15),
        @(-15, -15, 15), @(15, -15, 15), @(15, 15, 15), @(-15, 15, 15)
      )

      $rotated = @()
      foreach ($v in $vertices) {
        $x = $v[0]; $y = $v[1]; $z = $v[2]

        # Y rotation
        $newX = $x * $cos - $z * $sin
        $newZ = $x * $sin + $z * $cos

        # X rotation
        $newY = $y * [Math]::Cos($angle * 0.5) - $newZ * [Math]::Sin($angle * 0.5)
        $finalZ = $y * [Math]::Sin($angle * 0.5) + $newZ * [Math]::Cos($angle * 0.5)

        $distance = 70  # 🔧 Adjusted projection distance
        $scale = $distance / ($distance + $finalZ)
        $screenX = [int]($newX * $scale) + $centerX
        $screenY = [int]($newY * $scale) + $centerY

        $rotated += , @($screenX, $screenY, $finalZ)
      }

      $screen = @{}

      $edges = @(
        @(0, 1), @(1, 2), @(2, 3), @(3, 0),
        @(4, 5), @(5, 6), @(6, 7), @(7, 4),
        @(0, 4), @(1, 5), @(2, 6), @(3, 7)
      )

      foreach ($edge in $edges) {
        $v1 = $rotated[$edge[0]]
        $v2 = $rotated[$edge[1]]
        $x1 = $v1[0]; $y1 = $v1[1]; $z1 = $v1[2]
        $x2 = $v2[0]; $y2 = $v2[1]; $z2 = $v2[2]

        $dx = [Math]::Abs($x2 - $x1)
        $dy = [Math]::Abs($y2 - $y1)
        $sx = if ($x1 -lt $x2) { 1 } else { -1 }
        $sy = if ($y1 -lt $y2) { 1 } else { -1 }
        $err = $dx - $dy
        $x = $x1; $y = $y1

        while ($true) {
          if ($x -ge 0 -and $x -lt $consoleWidth -and $y -ge 0 -and $y -lt $consoleHeight) {
            $key = "$x,$y"
            $avgZ = ($z1 + $z2) / 2
            if (-not $screen.ContainsKey($key) -or $screen[$key][1] -lt $avgZ) {
              $char = if ($avgZ -gt 5) { "▒" }
              elseif ($avgZ -gt 0) { "▓" }
              elseif ($avgZ -gt -5) { "▒█" }
              else { "░" }
              $screen[$key] = @($char, $avgZ)
            }
          }
          if ($x -eq $x2 -and $y -eq $y2) { break }
          $e2 = 2 * $err
          if ($e2 -gt - $dy) { $err -= $dy; $x += $sx }
          if ($e2 -lt $dx) { $err += $dx; $y += $sy }
        }
      }

      for ($i = 0; $i -lt $rotated.Length; $i++) {
        $x = $rotated[$i][0]
        $y = $rotated[$i][1]
        $z = $rotated[$i][2]
        if ($x -ge 0 -and $x -lt $consoleWidth -and $y -ge 0 -and $y -lt $consoleHeight) {
          $screen["$x,$y"] = @(if ($z -gt 0) { "●" } else { "○" }, $z + 100)
        }
      }

      for ($y = 0; $y -lt $consoleHeight; $y++) {
        $line = ""
        for ($x = 0; $x -lt $consoleWidth; $x++) {
          $key = "$x,$y"
          $line += if ($screen.ContainsKey($key)) { $screen[$key][0] } else { " " }
        }
        Write-Host $line -ForegroundColor Yellow
      }

      $angle += 0.08
      Start-Sleep -Milliseconds $FrameDelayMs
    }
  }
  catch [System.Management.Automation.PipelineStoppedException] {
    Clear-Host
    Write-Host "`n🦅 3D scan complete. Eagle has landed." -ForegroundColor Green
  }
  catch {
    Clear-Host
    Write-Host "❌ 3D render error: $_" -ForegroundColor Red
  }
  finally {
    [Console]::CursorVisible = $true
    $Host.UI.RawUI.WindowTitle = "PowerShell"
  }
}
