$body = @{
    actionType = "plant"
    command = "spawn_superthreepeater_sp"
    amount = 1
    username = "RENEarn"
    label = "Super Threepeater SP"
} | ConvertTo-Json

Write-Host "Sending summon request to /api/game/trigger..." -ForegroundColor Cyan
$resp = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/game/trigger" -Method Post -Body $body -ContentType "application/json"
Write-Host "PvZ Response: success=$($resp.success), message=$($resp.message)" -ForegroundColor Green
