$cat = Get-Content "pvz_units_catalog.json" -Raw | ConvertFrom-Json
$missing = @()
foreach ($item in $cat.all) {
    $path = $item.icon -replace '/', '\'
    if (-not (Test-Path $path)) {
        $missing += [PSCustomObject]@{ Id = $item.id; Name = $item.name; Icon = $item.icon }
    }
}
Write-Host "Total items checked: $($cat.all.Count)"
Write-Host "Missing icon files: $($missing.Count)"
if ($missing.Count -gt 0) {
    $missing | Select-Object -First 10 | ForEach-Object { Write-Host "  $($_.Name): $($_.Icon)" }
}
