param()
$testGifts = @(
    @{ name = "Heart Me"; id = "7934"; count = 1; coins = 1 },
    @{ name = "Rose"; id = "5655"; count = 1; coins = 1 },
    @{ name = "Ice Cream Cone"; id = "5827"; count = 1; coins = 1 },
    @{ name = "Perfume"; id = "5658"; count = 1; coins = 20 },
    @{ name = "Doughnut"; id = "5879"; count = 1; coins = 30 }
)

Write-Output "Testing simulated TikTok gift webhooks to http://127.0.0.1:8080/api/webhook/tiktok..."
foreach ($g in $testGifts) {
    $payload = @{
        event = "gift"
        giftId = $g.id
        giftName = $g.name
        repeatCount = $g.count
        totalRepeatCount = $g.count
        coins = $g.coins
        diamondCount = $g.coins
        username = "TestGifter"
        avatarUrl = "https://p16-sign.tiktokcdn-us.com/tos-useast5-avt-0068-tx/sample.webp"
        giftPictureUrl = "images/tiktok-gifts/$($g.id)_test.webp"
    } | ConvertTo-Json

    try {
        $res = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/webhook/tiktok" -Method Post -Body $payload -ContentType "application/json" -TimeoutSec 10
        Write-Output "Gift $($g.name) (ID $($g.id)): Status = $($res.status), Message = $($res.message)"
    } catch {
        Write-Output "Gift $($g.name) (ID $($g.id)): Error = $($_.Exception.Message)"
    }
    Start-Sleep -Milliseconds 600
}
