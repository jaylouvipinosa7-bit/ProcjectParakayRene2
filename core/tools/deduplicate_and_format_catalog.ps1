$soundsDir = "c:\Users\pc\Downloads\ano na\core\sounds"
$catalogPath = "c:\Users\pc\Downloads\ano na\core\sounds_catalog.json"
$configPath = "c:\Users\pc\Downloads\ano na\core\config.json"

$catalog = Get-Content -Raw $catalogPath | ConvertFrom-Json
$config = $null
if (Test-Path $configPath) {
    try { $config = Get-Content -Raw $configPath | ConvertFrom-Json } catch {}
}

Write-Host "Initial catalog items count: $($catalog.Count)"

# 1. Collect MD5 hashes for all files
$shell = New-Object -ComObject Shell.Application
$folder = $shell.Namespace($soundsDir)

$fileList = Get-ChildItem $soundsDir -Filter "*.mp3"
$hashes = @{} # hash -> canonical filename
$fileHashMap = @{} # filename -> hash
$removedFilesMap = @{} # duplicate filename -> canonical filename

foreach ($f in $fileList) {
    $h = (Get-FileHash $f.FullName -Algorithm MD5).Hash
    $fileHashMap[$f.Name] = $h
}

# Specific known redundant pairs where user specifically saw:
# anime_wow.mp3 vs anime-wow-sound-effect.mp3
# We will keep the cleaner / shorter name 'anime_wow.mp3' and redirect 'anime-wow-sound-effect.mp3'
$priorityNames = @('anime_wow.mp3', 'apple_pay.mp3', 'among_us_role_reveal_sound.mp3', 'bone_crack.mp3', 'dexter_meme.mp3', 'discord_notification.mp3', 'metal_pipe_clang.mp3', 'michael_jackson_hee_hee.mp3', 'rizz_sound_effect.mp3', 'spongebob_fail.mp3', 'vine_boom_sound.mp3', 'the_undertaker_bell.mp3', 'dry-fart.mp3', 'bruh.mp3')

# Assign priority items first
foreach ($p in $priorityNames) {
    if ($fileHashMap.ContainsKey($p)) {
        $h = $fileHashMap[$p]
        if (!$hashes.ContainsKey($h)) {
            $hashes[$h] = $p
        }
    }
}

# Process remaining files
foreach ($f in $fileList) {
    $h = $fileHashMap[$f.Name]
    if ($hashes.ContainsKey($h)) {
        if ($hashes[$h] -ne $f.Name) {
            $removedFilesMap[$f.Name] = $hashes[$h]
            Write-Host "Marking duplicate: '$($f.Name)' -> will redirect to '$($hashes[$h])'"
        }
    } else {
        $hashes[$h] = $f.Name
    }
}

# 2. Build deduplicated catalog
$dedupCatalog = @()
$seenFiles = @{}
$seenTitles = @{}

foreach ($item in $catalog) {
    $rawFileName = ($item.file -replace '^sounds/', '').Trim()
    
    # If this file was marked as duplicate, substitute with canonical
    if ($removedFilesMap.ContainsKey($rawFileName)) {
        $rawFileName = $removedFilesMap[$rawFileName]
        $item.file = "sounds/$rawFileName"
        $item.name = $rawFileName
    }
    
    $cleanKey = $rawFileName.ToLower()
    $normTitle = ($item.title -replace '[^a-zA-Z0-9]', '').ToLower()
    
    if ($seenFiles.ContainsKey($cleanKey)) {
        Write-Host "Skipping duplicate file in catalog: $cleanKey"
        continue
    }
    
    if ($seenTitles.ContainsKey($normTitle) -and $normTitle.Length -gt 3) {
        Write-Host "Skipping duplicate title in catalog: $($item.title) ($cleanKey)"
        continue
    }
    
    $seenFiles[$cleanKey] = $true
    $seenTitles[$normTitle] = $true
    
    # Measure REAL duration from Windows Shell for this file
    $filePath = Join-Path $soundsDir $rawFileName
    $durationStr = "00:03:00"
    
    if (Test-Path $filePath) {
        $folderItem = $folder.ParseName($rawFileName)
        if ($folderItem) {
            $shellLen = $folder.GetDetailsOf($folderItem, 27) # e.g. "00:00:04"
            if ($shellLen -match '(\d+):(\d+):(\d+)') {
                $hrs = [int]$matches[1]
                $mins = [int]$matches[2]
                $secs = [int]$matches[3]
                
                # Format: 00:03:00 (e.g. MM:SS:00)
                $totMins = ($hrs * 60) + $mins
                $minPart = "{0:D2}" -f $totMins
                $secPart = "{0:D2}" -f $secs
                $durationStr = "$minPart`:$secPart`:00"
            }
        }
    }
    
    $item.duration = $durationStr
    $dedupCatalog += $item
}

Write-Host "Cleaned catalog items count: $($dedupCatalog.Count)"

# 3. Delete redundant files from disk
foreach ($dupName in $removedFilesMap.Keys) {
    $dupPath = Join-Path $soundsDir $dupName
    if (Test-Path $dupPath) {
        try {
            Remove-Item $dupPath -Force
            Write-Host "Deleted redundant file from disk: $dupName"
        } catch {
            Write-Host "Could not delete $dupName : $($_.Exception.Message)"
        }
    }
}

# 4. Save updated catalog
$jsonOut = $dedupCatalog | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText($catalogPath, $jsonOut, [System.Text.Encoding]::UTF8)
Write-Host "Saved updated sounds_catalog.json with $($dedupCatalog.Count) sounds!"

# 5. Update config.json if any gift references a removed duplicate
if ($config -and $config.gifts) {
    $configChanged = $false
    foreach ($g in $config.gifts) {
        if ($g.audio -and $g.audio.file) {
            $fn = ($g.audio.file -replace '^sounds/', '').Trim()
            if ($removedFilesMap.ContainsKey($fn)) {
                $newFn = $removedFilesMap[$fn]
                $g.audio.file = "sounds/$newFn"
                Write-Host "Updated trigger '$($g.id)' audio file to '$($newFn)'"
                $configChanged = $true
            }
        }
    }
    if ($configChanged) {
        $cfgJson = $config | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText($configPath, $cfgJson, [System.Text.Encoding]::UTF8)
        Write-Host "Saved updated config.json with remapped audio file paths."
    }
}
