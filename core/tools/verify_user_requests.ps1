$cat = Get-Content "pvz_units_catalog.json" -Raw | ConvertFrom-Json

Write-Host "Search for Trident:"
$cat.all | Where-Object { $_.name -like "*Trident*" -or $_.id -like "*trident*" } | ForEach-Object {
    Write-Host "  $($_.id) | $($_.name) | $($_.icon) | Effect: $($_.effect)"
}

Write-Host "`nSearch for Hydrofowl:"
$cat.all | Where-Object { $_.name -like "*Hydrofowl*" -or $_.id -like "*hydrofowl*" } | ForEach-Object {
    Write-Host "  $($_.id) | $($_.name) | $($_.icon) | Effect: $($_.effect)"
}

Write-Host "`nSearch for SniperGatling:"
$cat.all | Where-Object { $_.name -like "*Sniper*Gatling*" -or $_.id -like "*sniper*gatling*" } | ForEach-Object {
    Write-Host "  $($_.id) | $($_.name) | $($_.icon) | isS2E: $($_.isS2E)"
}
