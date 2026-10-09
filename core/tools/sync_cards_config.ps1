$m = Get-Content 'C:\Users\pc\AppData\Local\Runetify\game_mappings.json' -Raw | ConvertFrom-Json
$cmdMap = Get-Content 'c:\Users\pc\Downloads\ano na\runetify_all_commands_map.json' -Raw | ConvertFrom-Json
$labelMap = Get-Content 'c:\Users\pc\Downloads\ano na\runetify_unit_labels.json' -Raw | ConvertFrom-Json
$verifiedGifts = Get-Content 'c:\Users\pc\Downloads\ano na\tiktok_gifts_verified.json' -Raw | ConvertFrom-Json

# Build gift lookup
$giftMap = @{}
foreach ($g in $verifiedGifts) {
    $giftMap[$g.id] = $g
    $giftMap[$g.name.ToLower()] = $g
}

# 1. Build cards for cards.json (used by s2e-overlay.html)
$cardsList = @()
$cardId = 1

foreach ($item in $m.pvz_fusion) {
    if (-not $item.command) { continue }
    $cmd = $item.command
    $amount = if ($item.amount) { [int]$item.amount } else { 1 }
    $trigger = $item.trigger
    $trigType = if ($trigger) { $trigger.type } else { "gift" }
    $trigLabel = if ($trigger) { $trigger.label } else { "Custom" }
    $giftId = if ($trigger -and $trigger.giftId) { [string]$trigger.giftId } else { "" }

    # Unit Icon
    $funcImg = "images/game-icons/pvz/$cmd.webp"
    if (-not (Test-Path "c:\Users\pc\Downloads\ano na\$funcImg")) {
        $funcImg = "images/game-icons/pvz/spawn_$cmd.webp"
    }

    # Trigger Icon
    $trigImg = ""
    if ($trigType -eq "share") {
        $trigImg = "images/trig_1.svg"
    } elseif ($trigLabel -match "follow") {
        $trigImg = "images/trig_1.svg"
    } elseif ($trigLabel -match "like") {
        $trigImg = "images/trig_7.svg"
    } else {
        if ($giftId -and $giftMap.ContainsKey($giftId)) {
            $trigImg = $giftMap[$giftId].icon
        } elseif ($trigger -and $trigger.icon) {
            $trigImg = $trigger.icon
        } else {
            $trigImg = "images/tiktok-gifts/5655_rose.webp"
        }
    }

    # Action type
    $action = "SelectedGift"
    if ($trigType -eq "share") { $action = "Share" }
    elseif ($trigLabel -match "follower") { $action = "Follow" }
    elseif ($trigLabel -match "like") { $action = "LikeForEach" }

    $cardEntry = [PSCustomObject]@{
        id = [string]$cardId
        action = $action
        giftId = $giftId
        giftName = $trigLabel
        funcName = if ($labelMap.$cmd) { $labelMap.$cmd } else { $cmd }
        funcImg = $funcImg
        trigImg = $trigImg
        triggerValue = if ($action -eq "LikeForEach") { "50" } else { "" }
        commands = $cmd
        repetition = $amount
    }
    $cardsList += $cardEntry
    $cardId++
}

$cardsJson = $cardsList | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText("c:\Users\pc\Downloads\ano na\cards.json", $cardsJson, [System.Text.Encoding]::UTF8)
Write-Output "Successfully generated cards.json with $($cardsList.Count) authentic Runetify/S2E cards!"

# 2. Build config gifts for pvz_fusion_config.json (used by app.html)
$configGifts = @()
$giftIdx = 1

foreach ($card in $cardsList) {
    $cmd = $card.commands
    $cmdInfo = $cmdMap.$cmd
    $actionType = "zombie"
    if ($cmdInfo) {
        if ($cmdInfo.endpoint -eq "/spawnplant") { $actionType = "plant" }
        elseif ($cmdInfo.endpoint -eq "/spawnzombie") { $actionType = "zombie" }
        else { $actionType = "power" }
    } elseif ($cmd -match "plant|cattail|sunnut|threepeater") {
        $actionType = "plant"
    }

    $coins = 1
    if ($card.giftId -and $giftMap.ContainsKey($card.giftId)) {
        $coins = [int]$giftMap[$card.giftId].coins
    }

    $configGifts += [PSCustomObject]@{
        id = [string]$giftIdx
        giftName = $card.giftName
        giftId = $card.giftId
        coins = $coins
        icon = $card.trigImg
        unitIcon = $card.funcImg
        actionType = $actionType
        command = $card.commands
        label = $card.funcName
        amount = $card.repetition
        enabled = $true
    }
    $giftIdx++
}

# Also ensure Galaxy is explicitly included and highlighted
$hasGalaxy = $false
foreach ($cg in $configGifts) {
    if ($cg.giftName -eq "Galaxy" -or $cg.giftId -eq "11046") {
        $hasGalaxy = $true
        $cg.coins = 1000
        $cg.giftId = "11046"
        $cg.icon = "images/tiktok-gifts/11046_galaxy.webp"
    }
}

$existingConfig = Get-Content "c:\Users\pc\Downloads\ano na\pvz_fusion_config.json" -Raw | ConvertFrom-Json
$existingConfig.gifts = $configGifts
$configJson = $existingConfig | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText("c:\Users\pc\Downloads\ano na\pvz_fusion_config.json", $configJson, [System.Text.Encoding]::UTF8)
Write-Output "Successfully updated pvz_fusion_config.json with $($configGifts.Count) cards!"
