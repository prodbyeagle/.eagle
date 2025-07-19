function Show-Animation {
  [CmdletBinding()]
  param (
    [int]$FrameDelayMs = 40
  )

  try {
    [Console]::CursorVisible = $false
    $Host.UI.RawUI.WindowTitle = "eagle was here."

    $angle = 0
    while ($true) {
      $consoleWidth = $Host.UI.RawUI.WindowSize.Width
      $consoleHeight = $Host.UI.RawUI.WindowSize.Height

      $scaleFactor = [Math]::Min($consoleWidth, $consoleHeight) * 0.3
      $half = $scaleFactor / 2

      $centerX = [int]($consoleWidth / 2)
      $centerY = [int]($consoleHeight / 2 + 2)

      # $Host.UI.RawUI.CursorPosition = @{X = 0; Y = 0 }

      $cosY = [Math]::Cos($angle)
      $sinY = [Math]::Sin($angle)
      $cosX = [Math]::Cos($angle * 0.5)
      $sinX = [Math]::Sin($angle * 0.5)

      $vertices = @(
        @(-1, -1, -1), @(1, -1, -1), @(1, 1, -1), @(-1, 1, -1),
        @(-1, -1, 1), @(1, -1, 1), @(1, 1, 1), @(-1, 1, 1)
      )

      $rotated = @()
      foreach ($v in $vertices) {
        $x = $v[0] * $half
        $y = $v[1] * $half
        $z = $v[2] * $half

        $rx = $x * $cosY - $z * $sinY
        $rz = $x * $sinY + $z * $cosY

        $ry = $y * $cosX - $rz * $sinX
        $finalZ = $y * $sinX + $rz * $cosX

        $distance = $scaleFactor * 1.5
        $scale = $distance / ($distance + $finalZ)
        $screenX = [int]($rx * $scale) + $centerX
        $aspectCorrection = 0.5
        $screenY = [int]($ry * $scale * $aspectCorrection) + $centerY

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
              elseif ($avgZ -gt -5) { "█" }
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
        $x = $rotated[$i][0]; $y = $rotated[$i][1]; $z = $rotated[$i][2]
        if ($x -ge 0 -and $x -lt $consoleWidth -and $y -ge 0 -and $y -lt $consoleHeight) {
          $screen["$x,$y"] = @(if ($z -gt 0) { "○" } else { "●" }, $z + 100)
        }
      }

      $Host.UI.RawUI.CursorPosition = @{X = 0; Y = 0 }

      $buffer = New-Object System.Text.StringBuilder

      for ($y = 1; $y -lt $consoleHeight; $y++) {
        for ($x = 0; $x -lt $consoleWidth; $x++) {
          $key = "$x,$y"
          if ($screen.ContainsKey($key)) {
            $char = $screen[$key][0]
          }
          else {
            $char = " "
          }
          $null = $buffer.Append($char)
        }
        $null = $buffer.AppendLine()
      }

      Write-Host $buffer.ToString() -ForegroundColor Magenta
      $angle += 0.08
      Start-Sleep -Milliseconds $FrameDelayMs
    }
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
