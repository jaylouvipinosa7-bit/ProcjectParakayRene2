$cat = Get-Content "pvz_units_catalog.json" -Raw | ConvertFrom-Json
$item = $cat.all | Where-Object { $_.id -eq "spawn_ultimatesnipergatling" }
Write-Host "Item JSON:"
$item | ConvertTo-Json
