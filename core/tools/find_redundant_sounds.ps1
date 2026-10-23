$soundsDir = "c:\Users\pc\Downloads\ano na\core\sounds"
$catalogPath = "c:\Users\pc\Downloads\ano na\core\sounds_catalog.json"
$catalog = Get-Content -Raw $catalogPath | ConvertFrom-Json

Write-Host "Total catalog items: $($catalog.Count)"

# 1. Group files by MD5 hash
$files = Get-ChildItem $soundsDir -Filter "*.mp3"
$hashes = @{}
$dupFiles = @()

foreach ($f in $files) {
    $hash = (Get-FileHash $f.FullName -Algorithm MD5).Hash
    if ($hashes.ContainsKey($hash)) {
        $dupFiles += [PSCustomObject]@{
            Original = $hashes[$hash]
            Duplicate = $f.Name
            Hash = $hash
            Size = $f.Length
        }
    } else {
        $hashes[$hash] = $f.Name
    }
}

Write-Host "Identical MD5 Duplicate files count: $($dupFiles.Count)"
foreach ($d in $dupFiles) {
    Write-Host "Duplicate: '$($d.Duplicate)' is identical to '$($d.Original)'"
}

# 2. Check catalog entries pointing to same file or duplicate titles
$seenFiles = @{}
$dupCatalogByFile = @()
foreach ($item in $catalog) {
    $cleanFile = ($item.file -replace '^sounds/', '').ToLower()
    if ($seenFiles.ContainsKey($cleanFile)) {
        $dupCatalogByFile += $item
    } else {
        $seenFiles[$cleanFile] = $item
    }
}
Write-Host "Catalog items pointing to duplicate file: $($dupCatalogByFile.Count)"

# 3. Check normalized titles
$seenTitles = @{}
$dupByTitle = @()
foreach ($item in $catalog) {
    $normTitle = ($item.title -replace '[^a-zA-Z0-9]', '').ToLower()
    if ($seenTitles.ContainsKey($normTitle)) {
        $dupByTitle += [PSCustomObject]@{
            Existing = $seenTitles[$normTitle].file
            Duplicate = $item.file
            Title = $item.title
        }
    } else {
        $seenTitles[$normTitle] = $item
    }
}
Write-Host "Catalog items with duplicate/redundant title: $($dupByTitle.Count)"
foreach ($dt in $dupByTitle | Select-Object -First 15) {
    Write-Host "Redundant title: '$($dt.Title)' -> $($dt.Duplicate) vs $($dt.Existing)"
}
