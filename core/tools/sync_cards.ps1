param()

$root = Split-Path -Parent $PSScriptRoot
$cfgPath = Join-Path $root "pvz_fusion_config.json"
if (-not (Test-Path $cfgPath)) {
    $cfgPath = Join-Path (Split-Path -Parent $root) "pvz_fusion_config.json"
}

$cfg = Get-Content $cfgPath -Raw -Encoding UTF8 | ConvertFrom-Json
$overlayCards = @()

foreach ($g in $cfg.gifts) {
    if (-not $g.enabled) { continue }
    $overlayAction = if ($g.action) { [string]$g.action } else { "SelectedGift" }
    $trigVal = if ($g.triggerValue) { [string]$g.triggerValue } else { "" }
    
    if ($g.triggerType -eq "likes_person" -or $g.triggerType -eq "likes_all") {
        $overlayAction = "Likes"
        $trigVal = [string]$g.likeThreshold
    } elseif ($g.triggerType -eq "share") {
        $overlayAction = "Share"
    } elseif ($g.triggerType -eq "follow") {
        $overlayAction = "Follow"
    } elseif ($g.triggerType -eq "chat") {
        $overlayAction = "Chat"
    } elseif ($g.triggerType -eq "custom" -or $g.actionType -eq "custom" -or $overlayAction -eq "Custom" -or [string]$g.id -eq "59") {
        $overlayAction = "Custom"
    }

    $isCustomTrig = ($g.triggerType -eq "custom" -or $g.actionType -eq "custom" -or $overlayAction -eq "Custom" -or [string]$g.id -eq "59")
    $isHideInOverlay = ($g.hideInOverlay -eq $true -or $isCustomTrig)
    
    if ([string]$g.id -eq "2" -or ($g.giftName -and $g.giftName -match "team\s*zombies\s*likes")) {
        $fName = "Spawn Trident Jugger-nut Gargantuar (240)"
        $uImg = "images/game-icons/pvz/spawn_trident_juggernut_gargantuar.webp"
        $cmdStr = "spawn_trident_juggernut_gargantuar"
        $overlayAction = "LikeForEach"
        $trigVal = if ($g.likeThreshold) { [string]$g.likeThreshold } else { "50" }
    } else {
        $fName = if ($g.label -and $g.label -ne "Custom") { [string]$g.label } elseif ($g.functionName -and $g.functionName -ne "Custom") { [string]$g.functionName } elseif ($g.command) { [string]$g.command } else { "Action" }
        $uImg = if ($g.unitIcon -and $g.unitIcon -notmatch "func_2") { [string]$g.unitIcon } elseif ($g.command) { "images/game-icons/pvz/$($g.command).webp" } else { "images/func_2.png" }
        $cmdStr = [string]$g.command
    }

    $overlayCards += [PSCustomObject]@{
        id = [string]$g.id
        action = $overlayAction
        giftId = if ($g.giftId) { [string]$g.giftId } else { "" }
        giftName = if ($g.giftName) { [string]$g.giftName } else { "Gift" }
        funcName = $fName
        funcImg = $uImg
        trigImg = if ($g.icon) { [string]$g.icon } else { "images/tiktok-gifts/5655_rose.webp" }
        triggerValue = $trigVal
        commands = [string]$g.command
        repetition = if ($g.repetition -and [int]$g.repetition -gt 0) { [int]$g.repetition } elseif ($g.amount -and [int]$g.amount -gt 0) { [int]$g.amount } else { 1 }
        hideInOverlay = $isHideInOverlay
        triggerType = if ($g.triggerType) { [string]$g.triggerType } else { "gift" }
        actionType = if ($g.actionType) { [string]$g.actionType } else { "zombie" }
    }
}

$cardsJson = $overlayCards | ConvertTo-Json -Depth 6
$destCards = Join-Path $root "cards.json"
$destCardsJs = Join-Path $root "cards-data.js"
$destRootCards = Join-Path (Split-Path -Parent $root) "cards.json"

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($destCards, $cardsJson, $utf8NoBom)
[System.IO.File]::WriteAllText($destCardsJs, "const cardsData = $cardsJson;", $utf8NoBom)
if (Test-Path (Split-Path -Parent $root)) {
    [System.IO.File]::WriteAllText($destRootCards, $cardsJson, $utf8NoBom)
}

Write-Host "Successfully synced $($overlayCards.Count) cards to cards.json and cards-data.js!"
