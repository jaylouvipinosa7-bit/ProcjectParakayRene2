$cat = Get-Content "pvz_units_catalog.json" -Raw | ConvertFrom-Json
$match = $cat.all | Where-Object { $_.id -like "*sniper*gatling*" -or $_.name -like "*sniper*gatling*" }
if ($match) {
    Write-Host "Found in catalog:"
    $match | ForEach-Object { Write-Host "  $($_.id) | $($_.name) | $($_.type) | $($_.icon)" }
} else {
    Write-Host "NOT found in catalog!"
}
