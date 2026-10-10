$cfg = Get-Content 'pvz_fusion_config.json' -Raw -Encoding UTF8 | ConvertFrom-Json
$overlayCards = @()
foreach ($g in $cfg.gifts) {
    $overlayAction = "SelectedGift"
    $trigVal = ""
    if ($g.id -eq "1" -or ($g.eventType -eq "team_plants_likes") -or ($g.giftName -match "team\s*plants\s*likes")) {
        $overlayAction = "LikeForEach"
        $trigVal = if ($g.likeThreshold) { [string]$g.likeThreshold } else { "50" }
    } elseif ($g.id -eq "2" -or ($g.eventType -eq "team_zombies_likes") -or ($g.giftName -match "team\s*zombies\s*likes")) {
        $overlayAction = "LikeForEach"
        $trigVal = if ($g.likeThreshold) { [string]$g.likeThreshold } else { "50" }
    } elseif ($g.id -eq "3" -or ($g.eventType -eq "total_likes") -or ($g.giftName -match "^total\s*likes")) {
        $overlayAction = "LikeAmount"
        $trigVal = if ($g.likeThreshold) { [string]$g.likeThreshold } elseif ($g.triggerValue) { [string]$g.triggerValue } else { "500" }
    } elseif ($g.id -eq "4" -or ($g.eventType -eq "follow") -or ($g.giftName -match "^follow(er)?$")) {
        $overlayAction = "Follow"
        $trigVal = ""
    } elseif ($g.actionType -eq "share" -or ($g.giftName -match "^share\s*stream$")) {
        $overlayAction = "Share"
        $trigVal = ""
    } else {
        $overlayAction = "SelectedGift"
        $trigVal = ""
    }

    $overlayCards += [PSCustomObject]@{
        id = [string]$g.id
        action = $overlayAction
        giftId = if ($g.giftId) { [string]$g.giftId } else { "" }
        giftName = if ($g.giftName) { [string]$g.giftName } else { "Gift" }
        funcName = if ($g.label) { [string]$g.label } else { [string]$g.command }
        funcImg = if ($g.unitIcon) { [string]$g.unitIcon } else { "images/game-icons/pvz/$($g.command).webp" }
        trigImg = if ($g.icon) { [string]$g.icon } else { "images/tiktok-gifts/5655_rose.webp" }
        triggerValue = $trigVal
        commands = [string]$g.command
        repetition = if ($g.repetition -and [int]$g.repetition -gt 0) { [int]$g.repetition } elseif ($g.amount -and [int]$g.amount -gt 0) { [int]$g.amount } else { 1 }
    }
}

$cardsJson = $overlayCards | ConvertTo-Json -Depth 6
[System.IO.File]::WriteAllText((Join-Path (Get-Location) "cards.json"), $cardsJson, [System.Text.Encoding]::UTF8)
$cardsDataJs = "const cardsData = " + $cardsJson + ";"
[System.IO.File]::WriteAllText((Join-Path (Get-Location) "cards-data.js"), $cardsDataJs, [System.Text.Encoding]::UTF8)

Write-Host "Cards count: $($overlayCards.Count)"
$c17 = $overlayCards | Where-Object { $_.id -eq "17" }
Write-Host "Card 17 Action: $($c17.action), Name: $($c17.giftName), TrigImg: $($c17.trigImg)"
$c60 = $overlayCards | Where-Object { $_.id -eq "60" }
Write-Host "Card 60 Action: $($c60.action), Name: $($c60.giftName), GiftId: $($c60.giftId), TrigImg: $($c60.trigImg)"
