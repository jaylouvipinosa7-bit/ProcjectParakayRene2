# Full TikTok Live Simulation Suite for RENEarn
param(
    [string]$username = "gohanmalunggay",
    [int]$viewers = 188,
    [int]$likes = 42500
)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   TIKTOK LIVE STREAM CONNECTION & GAME SIMULATION TEST   " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Target Account : @$username" -ForegroundColor Yellow
Write-Host "Target Server  : http://127.0.0.1:8080" -ForegroundColor Yellow

# Step 1: Set Live Connected State in tiktok_live_state.json
$statePath = Join-Path $PSScriptRoot "..\tiktok_live_state.json"
$liveState = @{
    connected = $true
    processRunning = $true
    username = $username
    roomId = "738294819385019"
    viewerCount = $viewers
    totalLikes = $likes
    statusText = "Connected to Live Stream"
    lastEventTime = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
}
[System.IO.File]::WriteAllText($statePath, ($liveState | ConvertTo-Json -Depth 4), [System.Text.Encoding]::UTF8)
Write-Host "[1/5] Set Live Status: CONNECTED (Room ID: 738294819385019, Viewers: $viewers, Likes: $likes)" -ForegroundColor Green

# Step 2: Verify Status API
$status = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/tiktok/status"
Write-Host "[2/5] Verified /api/tiktok/status -> Connected: $($status.connected), Username: @$($status.username)" -ForegroundColor Green

# Step 3: Simulate Live Follow & Like Events
$followPayload = @{
    event = "follow"
    username = "SuperFan_PvZ"
    userId = "9823741"
    uniqueId = "superfan_pvz"
} | ConvertTo-Json
$resFollow = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/webhook/tiktok" -Method POST -Body $followPayload -ContentType "application/json"
Write-Host "[3/5] Simulated Follow Event (@SuperFan_PvZ followed) -> Status: $($resFollow.status)" -ForegroundColor Magenta

$likePayload = @{
    event = "like"
    likeCount = 15
    totalLikeCount = $likes + 15
    username = "SuperFan_PvZ"
} | ConvertTo-Json
$resLike = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/webhook/tiktok" -Method POST -Body $likePayload -ContentType "application/json"
Write-Host "[3/5] Simulated Like Event (+15 Likes) -> Status: $($resLike.status)" -ForegroundColor Magenta

# Step 4: Simulate Live Chat Commands (!plants & !zombies)
$chat1 = @{ event = "chat"; username = "GamerDave"; comment = "!plants" } | ConvertTo-Json
$resChat1 = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/webhook/tiktok" -Method POST -Body $chat1 -ContentType "application/json"
Write-Host "[4/5] Simulated Team Chat (!plants from GamerDave) -> Status: $($resChat1.status)" -ForegroundColor Yellow

$chat2 = @{ event = "chat"; username = "ZombieKing"; comment = "!zombies" } | ConvertTo-Json
$resChat2 = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/webhook/tiktok" -Method POST -Body $chat2 -ContentType "application/json"
Write-Host "[4/5] Simulated Team Chat (!zombies from ZombieKing) -> Status: $($resChat2.status)" -ForegroundColor Yellow

# Step 5: Simulate Live Gift Summons
$giftsToTest = @(
    @{ name = "Rose"; id = "5655"; coins = 1; user = "GamerDave" },
    @{ name = "Heart Me"; id = "7934"; coins = 1; user = "PlantLover99" },
    @{ name = "Doughnut"; id = "5879"; coins = 30; user = "VIP_Gifter" }
)

foreach ($g in $giftsToTest) {
    Start-Sleep -Milliseconds 400
    $giftPayload = @{
        event = "gift"
        giftId = $g.id
        giftName = $g.name
        repeatCount = 1
        totalRepeatCount = 1
        coins = $g.coins
        diamondCount = $g.coins
        username = $g.user
        avatarUrl = "images/default_avatar.svg"
        giftPictureUrl = "images/tiktok-gifts/$($g.id)_test.webp"
    } | ConvertTo-Json
    $resGift = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/webhook/tiktok" -Method POST -Body $giftPayload -ContentType "application/json"
    Write-Host "[5/5] Simulated Live Gift ($($g.name) [ID $($g.id), $($g.coins) coins] from @$($g.user)) -> Status: $($resGift.status)" -ForegroundColor Green
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   TIKTOK LIVE SIMULATION TEST COMPLETED SUCCESSFULLY!    " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
