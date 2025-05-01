param (
  [string]$SourceRoot = "D:\BEATS DATA\@prodbyeagle Die Library",
  [string[]]$AllowedExtensions = @(".mp3", ".wav", ".flac", ".flp"),
  [string[]]$FolderBlacklist = @("leaks", "FL Studio 21", "bin", "@prodbyn", "BeatsBackup"),
  [switch]$DryRun
)

function Test-AllowedExtension {
  param($filePath)
  return $AllowedExtensions -contains ([IO.Path]::GetExtension($filePath).ToLower())
}

function Test-BlacklistedFolder {
  param($folderPath)
  foreach ($blacklisted in $FolderBlacklist) {
    if ($folderPath -like "*\$blacklisted\*") {
      return $true
    }
  }
  return $false
}

function Get-TargetFolder {
  param($filePath)

  $file = Get-Item $filePath
  $year = $file.LastWriteTime.Year

  $folderName = "$year @prodbyeagle"
  $ext = [IO.Path]::GetExtension($filePath).ToLower()

  if ($ext -eq ".flp") {
    return Join-Path "@projects" $folderName
  }
  else {
    return Join-Path "@exports" $folderName
  }
}

function rename-Item {
  param($fileName)
  return ($fileName -replace '(^(\d{8}\s+)+)', '').Trim()
}

function Move-FileToYearFolder {
  param($filePath)

  $targetFolder = Get-TargetFolder -filePath $filePath
  if (-not $targetFolder) { return }

  $ext = [IO.Path]::GetExtension($filePath)
  $originalName = [System.IO.Path]::GetFileNameWithoutExtension($filePath)

  $cleanBaseName = rename-Item $originalName
  $newFileName = "$cleanBaseName$ext"

  $targetDir = Join-Path $SourceRoot $targetFolder
  $targetPath = Join-Path $targetDir $newFileName

  if (-not (Test-Path $targetDir)) {
    Write-Host "📁 Creating: $targetDir" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
  }

  if ($DryRun) {
    Write-Host "🔍 Would move: $filePath → $targetPath" -ForegroundColor Yellow
  }
  else {
    Write-Host "✅ Moving: $filePath → $targetPath" -ForegroundColor Green
    Move-Item -Path $filePath -Destination $targetPath -Force
  }
}


function Invoke-FolderScan {
  param($folder)

  Get-ChildItem -Path $folder -Recurse -File | ForEach-Object {
    $filePath = $_.FullName
    if (-not (Test-AllowedExtension $filePath)) {
      Write-Host "🚫 Skipping (ext not allowed): $filePath" -ForegroundColor DarkGray
      return
    }
    if (Test-BlacklistedFolder $filePath) {
      Write-Host "🚫 Skipping (blacklisted): $filePath" -ForegroundColor DarkRed
      return
    }
    Move-FileToYearFolder -filePath $filePath
  }
}

if (-not (Test-Path $SourceRoot)) {
  Write-Error "❌ Source root does not exist: $SourceRoot"
  exit 1
}

Write-Host "`n🎧 Starting scan in: $SourceRoot" -ForegroundColor Cyan
Invoke-FolderScan -folder $SourceRoot
Write-Host "`n✅ Completed. DryRun = $DryRun`n" -ForegroundColor Cyan
