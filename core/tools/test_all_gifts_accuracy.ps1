$giftsToTest = @(
    @{ id = "5655"; name = "Rose"; expectedCard = "5" },
    @{ id = "6788"; name = "Glow Stick"; expectedCard = "6" },
    @{ id = "1228602"; name = "GOten"; expectedCard = "7" },
    @{ id = "544253"; name = "I Like What I See"; expectedCard = "17" },
    @{ id = "5879"; name = "Doughnut"; expectedCard = "60" }
)

Write-Host "=========================================================="
Write-Host " TESTING GIFTING ACCURACY ACROSS MULTIPLE TIKTOK GIFTS "
Write-Host "=========================================================="

foreach ($g in $giftsToTest) {
    $beforeCounts = Invoke-RestMethod -Uri "http://localhost:8080/api/counts" -Method GET
    $targetId = $g.expectedCard
    $targetBefore = [int]$beforeCounts.$targetId
    $card3Before = [int]$beforeCounts.'3'
    $card1Before = [int]$beforeCounts.'1'
    $card2Before = [int]$beforeCounts.'2'

    $payload = @{
        event = "gift"
        giftId = $g.id
        giftName = $g.name
        repeatCount = 1
        username = "TestAccuracyUser"
    } | ConvertTo-Json

    $res = Invoke-RestMethod -Uri "http://localhost:8080/api/webhook/tiktok" -Method POST -Body $payload -ContentType "application/json"
    Start-Sleep -Milliseconds 300

    $afterCounts = Invoke-RestMethod -Uri "http://localhost:8080/api/counts" -Method GET
    $targetAfter = [int]$afterCounts.$targetId
    $card3After = [int]$afterCounts.'3'
    $card1After = [int]$afterCounts.'1'
    $card2After = [int]$afterCounts.'2'

    $targetDiff = $targetAfter - $targetBefore
    $card3Diff = $card3After - $card3Before
    $commDiff = ($card1After - $card1Before) + ($card2After - $card2Before) + $card3Diff

    $status = if ($targetDiff -eq 1 -and $commDiff -eq 0) { "PASSED" } else { "FAILED" }
    Write-Host "[$status] Gift '$($g.name)' (ID $($g.id)) -> Expected Card $($targetId): +$targetDiff | Community Bleed: $commDiff"
}
