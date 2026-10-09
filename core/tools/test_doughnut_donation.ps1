$initialCounts = Invoke-RestMethod -Uri "http://localhost:8080/api/counts" -Method GET
Write-Host "Initial Counts:"
Write-Host "  Card 1 (Team Plants): $($initialCounts.'1')"
Write-Host "  Card 2 (Team Zombies): $($initialCounts.'2')"
Write-Host "  Card 3 (Total Likes): $($initialCounts.'3')"
Write-Host "  Card 17 (I Like What I See): $($initialCounts.'17')"
Write-Host "  Card 60 (Doughnut): $($initialCounts.'60')"

Write-Host "`nSending simulated Doughnut donation (5879)..."
$payload = @{
    event = "gift"
    giftId = "5879"
    giftName = "Doughnut"
    repeatCount = 1
    totalRepeatCount = 1
    username = "Monsterrized23"
    avatarUrl = ""
    giftPictureUrl = "images/tiktok-gifts/5879_doughnut.webp"
} | ConvertTo-Json

$res = Invoke-RestMethod -Uri "http://localhost:8080/api/webhook/tiktok" -Method POST -Body $payload -ContentType "application/json"
Write-Host "Webhook Response: $($res.status)"

Start-Sleep -Milliseconds 600

$newCounts = Invoke-RestMethod -Uri "http://localhost:8080/api/counts" -Method GET
Write-Host "`nUpdated Counts:"
Write-Host "  Card 1 (Team Plants): $($newCounts.'1') (Diff: $([int]$newCounts.'1' - [int]$initialCounts.'1'))"
Write-Host "  Card 2 (Team Zombies): $($newCounts.'2') (Diff: $([int]$newCounts.'2' - [int]$initialCounts.'2'))"
Write-Host "  Card 3 (Total Likes): $($newCounts.'3') (Diff: $([int]$newCounts.'3' - [int]$initialCounts.'3'))"
Write-Host "  Card 17 (I Like What I See): $($newCounts.'17') (Diff: $([int]$newCounts.'17' - [int]$initialCounts.'17'))"
Write-Host "  Card 60 (Doughnut): $($newCounts.'60') (Diff: $([int]$newCounts.'60' - [int]$initialCounts.'60'))"

# Check recent events
$since = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() - 5000
$events = Invoke-RestMethod -Uri "http://localhost:8080/api/events?since=$since" -Method GET
Write-Host "`nRecent Events:"
foreach ($e in $events.events) {
    Write-Host "  [$($e.type)] $($e.label) (User: $($e.username), Spinner: $($e.spinnerName))"
}
