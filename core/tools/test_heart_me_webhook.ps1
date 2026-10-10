param()
$body = @{
    event = "gift"
    giftId = "7934"
    giftName = "Heart Me"
    repeatCount = 1
    totalRepeatCount = 1
    coins = 1
    diamondCount = 1
    username = "Yuki"
    avatarUrl = "images/default_avatar.svg"
    giftPictureUrl = ""
} | ConvertTo-Json

try {
    $res = Invoke-RestMethod -Uri "http://localhost:8080/api/webhook/tiktok" -Method POST -Body $body -ContentType "application/json"
    Write-Output "WEBHOOK RESPONSE:"
    $res | Format-List
} catch {
    Write-Output "WEBHOOK ERROR: $($_.Exception.Message)"
}

$eventsRes = Invoke-RestMethod -Uri "http://localhost:8080/api/events"
Write-Output "LATEST 5 EVENTS:"
$eventsRes.events | Select-Object -Last 5 | Format-Table -AutoSize
