$cat = Get-Content 'pvz_units_catalog.json' -Raw -Encoding UTF8 | ConvertFrom-Json
$iconFiles = Get-ChildItem -Path "images/game-icons/pvz" -Filter "*.webp"

$catImgs = @{}
foreach ($arr in @($cat.powers, $cat.plants, $cat.zombies)) {
    foreach ($item in $arr) {
        if ($item.img) {
            $catImgs[$item.img.ToLower()] = $item
        }
    }
}

$unmappedIcons = @()
foreach ($file in $iconFiles) {
    $relPath = "images/game-icons/pvz/$($file.Name)".ToLower()
    if (-not $catImgs.ContainsKey($relPath)) {
        $unmappedIcons += $file.Name
    }
}

Write-Output "Total icon files: $($iconFiles.Count)"
Write-Output "Catalog entries count with img: $($catImgs.Count)"
Write-Output "Unmapped icon files (files not used in catalog): $($unmappedIcons.Count)"
if ($unmappedIcons.Count -gt 0) {
    Write-Output "Sample unmapped icons:"
    $unmappedIcons | Select-Object -First 30 | ForEach-Object { Write-Output "  $_" }
}
