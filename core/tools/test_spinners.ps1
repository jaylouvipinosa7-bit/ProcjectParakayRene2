$r1 = Invoke-RestMethod -Uri 'http://localhost:8080/api/spin?spinnerId=spinner_1&username=TestPlayer' -Method POST
Write-Host "Spinner 1 Result:"
Write-Host "  Spinner Name : $($r1.spinner.name)"
Write-Host "  Group ID     : $($r1.spinner.groupId)"
Write-Host "  Won Prize    : $($r1.winner.label)"
Write-Host "  Action Type  : $($r1.winner.actionType)"
Write-Host "  Command      : $($r1.winner.command)"
Write-Host "  Duration     : $($r1.spinner.duration)"
Write-Host "  Ticks        : $($r1.spinner.ticks)"

$r2 = Invoke-RestMethod -Uri 'http://localhost:8080/api/spin?spinnerId=spinner_2&username=TestPlayer' -Method POST
Write-Host "`nSpinner 2 Result:"
Write-Host "  Spinner Name : $($r2.spinner.name)"
Write-Host "  Group ID     : $($r2.spinner.groupId)"
Write-Host "  Won Prize    : $($r2.winner.label)"
Write-Host "  Action Type  : $($r2.winner.actionType)"
Write-Host "  Command      : $($r2.winner.command)"
Write-Host "  Duration     : $($r2.spinner.duration)"
Write-Host "  Ticks        : $($r2.spinner.ticks)"

Write-Host "`n--- Testing TikTok Live Gift Donation Webhook ---"
# Simulate viewer sending Pink Perfume gift (20 coins)
$perfumeBody = @{
    eventType = "gift"
    giftName = "Perfume"
    giftId = "perfume"
    repeatCount = 1
    username = "TikTokFan1"
} | ConvertTo-Json
$wh1 = Invoke-RestMethod -Uri 'http://localhost:8080/api/webhook/tiktok' -Method POST -Body $perfumeBody -ContentType 'application/json'
Write-Host "Perfume Donation (20 coins) Webhook: $($wh1.status)"

# Simulate viewer sending Doughnut gift (30 coins)
$doughnutBody = @{
    eventType = "gift"
    giftName = "Doughnut"
    giftId = "5879"
    repeatCount = 1
    username = "ZombieSupporter"
} | ConvertTo-Json
$wh2 = Invoke-RestMethod -Uri 'http://localhost:8080/api/webhook/tiktok' -Method POST -Body $doughnutBody -ContentType 'application/json'
Write-Host "Doughnut Donation (30 coins) Webhook: $($wh2.status)"

# Fetch latest event logs from server to inspect what was broadcast
$events = Invoke-RestMethod -Uri 'http://localhost:8080/api/events?since=0'
Write-Host "`nRecent Server Broadcast Events:"
$events | Select-Object -Last 4 | ForEach-Object {
    Write-Host "  Type: $($_.type) | Label: $($_.label) | Spinner: $($_.spinnerName) (GroupId: $($_.groupId)) | Won: $($_.slice.label) | User: $($_.username)"
}
