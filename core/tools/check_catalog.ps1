$cat = Get-Content 'pvz_units_catalog.json' -Raw -Encoding UTF8 | ConvertFrom-Json
Write-Output "Powers count: $($cat.powers.Count)"
Write-Output "Plants count: $($cat.plants.Count)"
Write-Output "Zombies count: $($cat.zombies.Count)"

Write-Output "--- Sample Powers ---"
foreach ($p in ($cat.powers | Select-Object -First 15)) {
    Write-Output "$($p.name) | img: $($p.img) | cmd: $($p.command)"
}

Write-Output "--- Sample Plants ---"
foreach ($p in ($cat.plants | Select-Object -First 15)) {
    Write-Output "$($p.name) | img: $($p.img) | cmd: $($p.command)"
}
