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
  try {
    if (!(Test-Path $binDir)) {
      New-Item -ItemType Directory -Path $binDir -ErrorAction Stop | Out-Null
    }
  }
  catch {
    Write-Error "Failed to create bin directory '$binDir': $_"
  }
}

function Move-ToBin {
  param ([string]$src)
  try {
    $fileName = Split-Path -Leaf $src
    $dest = Join-Path $binDir $fileName
    $counter = 1
    while (Test-Path $dest) {
      $name = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
      $ext = [System.IO.Path]::GetExtension($fileName)
      $newFileName = "$name`_$counter$ext"
      $dest = Join-Path $binDir $newFileName
      $counter++
    }
    Move-Item -Path $src -Destination $dest -Force -ErrorAction Stop
  }
  catch {
    Write-Error "Error moving '$src' to bin: $_"
  }
}

function Remove-UnwantedFiles {
  param (
    [string]$dir,
    [scriptblock]$filter
  )
  if ($folderBlacklist -contains (Split-Path -Leaf $dir)) { return }
  try {
    $items = Get-ChildItem -Path $dir -Recurse -ErrorAction Stop
    foreach ($item in $items) {
      if ($item.PSIsContainer) {
        # Do nothing; subdirectories will be processed in the recursive call below.
        continue
      }
      try {
        if (& $filter $item.Name) {
          Move-ToBin -src $item.FullName
        }
      }
      catch {
        Write-Error "Error processing file '$($item.FullName)': $_"
      }
    }
  }
  catch {
    Write-Error "Error retrieving items from '$dir': $_"
  }
}

function Remove-NonFLPFiles {
  Remove-UnwantedFiles -dir $projectsDir -filter { param($name) ([System.IO.Path]::GetExtension($name).ToLower() -ne ".flp") }
}

function Remove-FLPFiles {
  Remove-UnwantedFiles -dir $exportsDir -filter { param($name) ([System.IO.Path]::GetExtension($name).ToLower() -eq ".flp") }
}

function Remove-DuplicateAudioFiles {
  param ([string]$dir)
    
  $audioFiles = Get-ChildItem -Path $dir -Recurse -File | Where-Object { $_.Extension -in @(".mp3", ".flac", ".wav") }
    
  $fileGroups = $audioFiles | Group-Object { [System.IO.Path]::GetFileNameWithoutExtension($_.Name) }

  foreach ($group in $fileGroups) {
    $mp3File = $null
    $flacFile = $null
    $wavFile = $null

    foreach ($file in $group) {
      if ($file.Extension -eq ".mp3") {
        $mp3File = $file
      }
      elseif ($file.Extension -eq ".flac") {
        $flacFile = $file
      }
      elseif ($file.Extension -eq ".wav") {
        $wavFile = $file
      }
    }

    if (($flacFile -or $wavFile) -and $mp3File) {
      Write-Host "Found duplicate files: $($mp3File.Name), moving to bin."
      Move-ToBin -src $mp3File.FullName
    }
  }
}

function Test-BinIntegrity {
  try {
    $binFiles = Get-ChildItem -Path $binDir -File -ErrorAction Stop | Where-Object { $_.Name -notmatch "^desktop(\d*)?\.ini$" } | Select-Object -ExpandProperty Name
    $allFiles = Get-ChildItem -Path $projectsDir, $exportsDir -Recurse -File -ErrorAction Stop | Select-Object -ExpandProperty Name
  }
  catch {
    Write-Error "Error retrieving files for integrity test: $_"
    return
  }
  $total = $binFiles.Count
  $missingFiles = @()
  for ($i = 0; $i -lt $total; $i++) {
    Show-LoadingBar -current ($i + 1) -total $total
    if ($binFiles[$i] -notin $allFiles) {
      $missingFiles += $binFiles[$i]
    }
  }
  Write-Host ""
  if ($missingFiles.Count -eq 0) {
    Write-Host "✅ Verification passed: No missing files. bin is now safe to delete!"
  }
  else {
    Write-Host "⚠ WARNING: The following files are missing in the original folders (excluding desktop.ini files):"
    $missingFiles | ForEach-Object { Write-Host "  $_" }
  }
}

function Start-Cleanup {
  Write-Host "🚀 Starting cleanup process..."
  New-BinDirectory
  Remove-NonFLPFiles
  Remove-FLPFiles
  Remove-DuplicateAudioFiles -dir $baseDir
  Write-Host "✅ Cleanup process completed!"
}