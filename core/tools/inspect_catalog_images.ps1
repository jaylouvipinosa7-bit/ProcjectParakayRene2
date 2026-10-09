$cat = Get-Content 'pvz_units_catalog.json' -Raw -Encoding UTF8 | ConvertFrom-Json
$missingImgs = 0
$total = 0
$sampleFallbacks = @()
foreach ($list in @($cat.powers, $cat.plants, $cat.zombies)) {
    foreach ($item in $list) {
        $total++
        if ($item.img -match 'func_|catmower') {
            $missingImgs++
            if ($sampleFallbacks.Count -lt 15) {
                $sampleFallbacks += "$($item.name) ($($item.command)) -> $($item.img)"
            }
        }
    }
}
Write-Output "Total catalog items: $total, Fallback/Missing icons: $missingImgs"
Write-Output "Sample fallbacks:"
$sampleFallbacks | ForEach-Object { Write-Output "  $_" }
