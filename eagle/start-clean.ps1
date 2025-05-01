$ErrorActionPreference = "Stop"

$baseDir = "D:\BEATS DATA\@prodbyeagle Die Library"
$binDir = Join-Path $baseDir "bin"
$projectsDir = Join-Path $baseDir "@projects"
$exportsDir = Join-Path $baseDir "@exports"
$folderBlacklist = @("FLStudio 21", "leaks", "bin")

function Show-LoadingBar {
  param ([int]$current, [int]$total)
  $width = 30
  $progress = [math]::Floor(($current / $total) * $width)
  $bar = "[" + ("#" * $progress).PadRight($width, " ") + "]"
  Write-Host "`r$bar $current / $total" -NoNewline
}

function New-BinDirectory {
  if (!(Test-Path $binDir)) {
    New-Item -ItemType Directory -Path $binDir -Force | Out-Null
  }
}

function Move-ToBin {
  param ([string]$src)
  $fileName = Split-Path -Leaf $src
  $dest = Join-Path $binDir $fileName
  $counter = 1
  while (Test-Path $dest) {
    $name = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
    $ext = [System.IO.Path]::GetExtension($fileName)
    $dest = Join-Path $binDir "$name`_$counter$ext"
    $counter++
  }
  Move-Item -Path $src -Destination $dest -Force
}

function Move-FileToSubfolder {
  param (
    [string]$filePath,
    [string]$baseTargetDir
  )
  $file = Get-Item -Path $filePath
  $parentDirName = Split-Path -Leaf (Split-Path $file.DirectoryName)
  $destDir = Join-Path $baseTargetDir $parentDirName

  if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
  }

  $targetPath = Join-Path $destDir $file.Name
  if ($file.FullName -ne $targetPath) {
    if (Test-Path $targetPath) {
      Move-ToBin -src $file.FullName
    }
    else {
      Move-Item -Path $file.FullName -Destination $targetPath -Force
    }
  }
}

function Remove-UnwantedFiles {
  param (
    [string]$dir,
    [scriptblock]$shouldRemove,
    [string]$expectedLocation
  )
  if ($folderBlacklist -contains (Split-Path -Leaf $dir)) { return }

  $items = Get-ChildItem -Path $dir -Recurse -File | Where-Object { $_.Name -notmatch "^desktop(\d*)?\.ini$" }

  foreach ($item in $items) {
    try {
      if (& $shouldRemove $item.Name) {
        Move-ToBin -src $item.FullName
      }
      elseif ($expectedLocation) {
        Move-FileToSubfolder -filePath $item.FullName -baseTargetDir $expectedLocation
      }
    }
    catch {
      Write-Error "Error processing file '$($item.FullName)': $_"
    }
  }
}

function Remove-NonFLPFiles {
  Remove-UnwantedFiles -dir $projectsDir -shouldRemove { param($name) [System.IO.Path]::GetExtension($name).ToLower() -ne ".flp" } -expectedLocation $exportsDir
}

function Remove-FLPFiles {
  Remove-UnwantedFiles -dir $exportsDir -shouldRemove { param($name) [System.IO.Path]::GetExtension($name).ToLower() -eq ".flp" } -expectedLocation $projectsDir
}

function Remove-DuplicateAudioFiles {
  param ([string]$dir)

  $audioFiles = Get-ChildItem -Path $dir -Recurse -File | Where-Object { $_.Extension -in @(".mp3", ".flac", ".wav") }

  $fileGroups = $audioFiles | Group-Object { [System.IO.Path]::GetFileNameWithoutExtension($_.Name) }

  foreach ($group in $fileGroups) {
    $mp3File = $null
    $otherFile = $null

    foreach ($file in $group.Group) {
      if ($file.Extension -eq ".mp3") {
        $mp3File = $file
      }
      elseif ($file.Extension -in @(".flac", ".wav")) {
        $otherFile = $file
      }
    }

    if ($mp3File -and $otherFile) {
      Write-Host "Found duplicate files: $($mp3File.Name), moving to bin."
      Move-ToBin -src $mp3File.FullName
    }
  }
}

function Test-BinIntegrity {
  $binFiles = Get-ChildItem -Path $binDir -File | Where-Object { $_.Name -notmatch "^desktop(\d*)?\.ini$" } | Select-Object -ExpandProperty Name
  $allFiles = Get-ChildItem -Path $projectsDir, $exportsDir -Recurse -File | Select-Object -ExpandProperty Name

  $missingFiles = @()
  for ($i = 0; $i -lt $binFiles.Count; $i++) {
    Show-LoadingBar -current ($i + 1) -total $binFiles.Count
    if ($binFiles[$i] -notin $allFiles) {
      $missingFiles += $binFiles[$i]
    }
  }
  Write-Host ""

  if ($missingFiles.Count -eq 0) {
    Write-Host "✅ Verification passed: No missing files. bin is now safe to delete!"
  }
  else {
    Write-Host "⚠ WARNING: The following files are missing in the original folders:"
    $missingFiles | ForEach-Object { Write-Host "  $_" }
  }
}

function Start-Cleanup {
  Write-Host "🚀 Starting cleanup process..."
  New-BinDirectory
  Remove-NonFLPFiles
  Remove-FLPFiles
  Remove-DuplicateAudioFiles -dir $baseDir
  Test-BinIntegrity
  Write-Host "✅ Cleanup process completed!"
}
