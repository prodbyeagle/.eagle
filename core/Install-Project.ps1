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
    "discord" { "https://github.com/prodbyeagle/discord-template.git" }
    "next" { "https://github.com/prodbyeagle/next-template.git" }
  }

  Write-Host "📁 Creating new '$template' project: $name" -ForegroundColor Cyan
  Write-Host "🔗 Cloning from $repoUrl to $projectPath..." -ForegroundColor Gray

  git clone $repoUrl $projectPath

  if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Project '$name' created at $projectPath" -ForegroundColor Green

    Set-Location -Path $projectPath

    $gitFolder = Join-Path $projectPath ".git"
    if (Test-Path $gitFolder) {
      Remove-Item -Recurse -Force $gitFolder
      Write-Host "🧹 Removed .git" -ForegroundColor Magenta
    }

    Write-Host "📦 Running 'bun update --latest'..." -ForegroundColor Gray
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