function Install-Project {
  param (
    [string]$Name,
    [string]$Template
  )

  if (-not $Name) {
    $Name = Read-Host "📝 Enter project name"
  }

  if (-not $Template) {
    Write-Host "📦 Available templates:" -ForegroundColor Cyan
    Write-Host " - discord" -ForegroundColor Yellow
    Write-Host " - next" -ForegroundColor Yellow
    $Template = Read-Host "📌 Choose a template"
  }

  $targetRoot = switch ($Template.ToLower()) {
    "discord" { "D:\VSCode\2025\Discord" }
    "next" { "D:\VSCode\2025\Frontend" }
    default {
      Write-Host "❌ Invalid template: '$Template'. Allowed: discord, next" -ForegroundColor Red
      return
    }
  }

  $projectPath = Join-Path $targetRoot $Name
  if (Test-Path $projectPath) {
    Write-Host "⚠️ Project '$Name' already exists at $projectPath" -ForegroundColor Yellow
    return
  }

  $repoUrl = switch ($Template.ToLower()) {
    "discord" { "https://github.com/prodbyeagle/EagleBotTemplate.git" }
    "next" { "https://github.com/prodbyeagle/Eagle-NextJS-Template.git" }
  }

  Write-Host "📁 Creating new '$Template' project: $Name" -ForegroundColor Cyan
  Write-Host "🔗 Cloning from $repoUrl to $projectPath..." -ForegroundColor Gray

  git clone $repoUrl $projectPath

  if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Project '$Name' created at $projectPath" -ForegroundColor Green
  }
  else {
    Write-Host "❌ Git clone failed." -ForegroundColor Red
  }
}
