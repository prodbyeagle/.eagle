function Show-TemplateSelector {
  $options = @("discord", "next")
  $selectedIndex = 0

  function Render {
    Clear-Host
    Write-Host "📌 Choose a template using ↑ ↓ and press Enter:`n" -ForegroundColor Cyan
    for ($i = 0; $i -lt $options.Count; $i++) {
      if ($i -eq $selectedIndex) {
        Write-Host "> $($options[$i])" -ForegroundColor Yellow
      }
      else {
        Write-Host "  $($options[$i])"
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
      elseif ($key.Key -eq [ConsoleKey]::DownArrow -and $selectedIndex -lt ($options.Count - 1)) {
        $selectedIndex++
      }
      elseif ($key.Key -eq [ConsoleKey]::Enter) {
        break
      }
      # else ignore any other keys
    }

    return $options[$selectedIndex]
  }
  finally {
    [Console]::CursorVisible = $true
    Clear-Host
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
    $template = Show-TemplateSelector
  }

  $targetRoot = switch ($template.ToLower()) {
    "discord" { "D:\Development\.25\Discord" }
    "next" { "D:\Development\.25\Frontend" }
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
    "discord" { "https://github.com/meowlounge/discord-template.git" }
    "next" { "https://github.com/meowlounge/next-template.git" }
  }

  Write-Host "📁 Creating new '$template' project: $name" -ForegroundColor Cyan
  git clone $repoUrl $projectPath

  if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Project '$name' created at $projectPath" -ForegroundColor Green
    Set-Location -Path $projectPath

    $gitFolder = Join-Path $projectPath ".git"
    if (Test-Path $gitFolder) {
      Remove-Item -Recurse -Force $gitFolder
      Write-Host "🧹 Removed .git" -ForegroundColor Magenta
    }

    Write-Host "📦 Updating / Installing Packages..." -ForegroundColor Gray
    bun update --latest

    if ($LASTEXITCODE -eq 0) {
      Write-Host "✅ Bun packages updated successfully." -ForegroundColor Green
    }
    else {
      Write-Host "❌ Failed to update Bun packages." -ForegroundColor Red
    }
  }
  else {
    Write-Host "❌ Git clone failed." -ForegroundColor Red
  }
}
