$cat = Get-Content 'pvz_units_catalog.json' -Raw -Encoding UTF8 | ConvertFrom-Json
if ($cat.tiktokGifts.value) {
    $cat.tiktokGifts = @($cat.tiktokGifts.value)
}
$json = $cat | ConvertTo-Json -Depth 6
[System.IO.File]::WriteAllText("pvz_units_catalog.json", $json, [System.Text.Encoding]::UTF8)
Write-Output "Fixed pvz_units_catalog.json tiktokGifts to array!"
