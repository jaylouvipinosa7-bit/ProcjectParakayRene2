# 1. Fetch current config
$cfg = Invoke-RestMethod -Uri 'http://localhost:8080/api/config'
$g2 = $cfg.gifts | Where-Object { [string]$_.id -eq '2' }
Write-Host "Initial command: $($g2.command)"

# 2. Change to another command
$g2.command = "spawn_supergargantuar"
$g2.label = "Super Gargantuar Mega Boss"
$g2.unitIcon = "images/game-icons/pvz/spawn_supergargantuar.webp"
$g2.commands[0].command = "spawn_supergargantuar"
$g2.commands[0].label = "Super Gargantuar Mega Boss"
$g2.commands[0].icon = "images/game-icons/pvz/spawn_supergargantuar.webp"

# 3. Save to server
$jsonBody = $cfg | ConvertTo-Json -Depth 30
$headers = @{ 'x-admin-key' = 'jaylouvipinosa7'; 'Content-Type' = 'application/json' }
$res = Invoke-RestMethod -Uri 'http://localhost:8080/api/config' -Method POST -Body $jsonBody -Headers $headers
Write-Host "Saved change: $($res.message)"

# 4. Fetch config again
$cfgAfter = Invoke-RestMethod -Uri 'http://localhost:8080/api/config'
$g2After = $cfgAfter.gifts | Where-Object { [string]$_.id -eq '2' }
Write-Host "Fetched command after save: $($g2After.command)"

if ($g2After.command -eq "spawn_supergargantuar") {
    Write-Host "SUCCESS: Custom edit persisted perfectly!"
} else {
    Write-Host "FAILED: Command reverted to $($g2After.command)!"
}

# 5. Restore Knight Captain as requested by the user
$g2After.command = "spawn_knight_captain"
$g2After.label = "Spawn Knight Captain Zombie (70)"
$g2After.unitIcon = "images/game-icons/pvz/spawn_knight_captain.webp"
$g2After.commands[0].command = "spawn_knight_captain"
$g2After.commands[0].label = "Spawn Knight Captain Zombie (70)"
$g2After.commands[0].icon = "images/game-icons/pvz/spawn_knight_captain.webp"
$jsonBody = $cfgAfter | ConvertTo-Json -Depth 30
$res = Invoke-RestMethod -Uri 'http://localhost:8080/api/config' -Method POST -Body $jsonBody -Headers $headers
Write-Host "Restored Knight Captain: $($res.message)"
