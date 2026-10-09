# ==============================================================================
# Full S2E Sync: Import user's authentic rules into pvz_fusion_config, cards.json & cards-data.js
# ==============================================================================

$rulesFile = 'C:\Users\pc\AppData\Roaming\Runetify\game-rules.json'
if (-not (Test-Path $rulesFile)) {
    $rulesFile = 'C:\Users\pc\AppData\Local\Runetify\game-rules.json'
}

$rulesRaw = (Get-Content $rulesFile -Raw -Encoding UTF8 | ConvertFrom-Json).pvz_fusion
$catalog = Get-Content 'pvz_units_catalog.json' -Raw -Encoding UTF8 | ConvertFrom-Json
$labelMap = Get-Content 'runetify_unit_labels.json' -Raw -Encoding UTF8 | ConvertFrom-Json

# Build fast unit lookup
$unitLookup = @{}
foreach ($p in $catalog.plants) { $unitLookup[$p.command.ToLower()] = @{ name = $p.name; img = $p.img; type = "plant" } }
foreach ($z in $catalog.zombies) { $unitLookup[$z.command.ToLower()] = @{ name = $z.name; img = $z.img; type = "zombie" } }
foreach ($pw in $catalog.powers) { $unitLookup[$pw.command.ToLower()] = @{ name = $pw.name; img = $pw.img; type = "power" } }

# Filter active rules
$activeRules = $rulesRaw | Where-Object { $_.enabled -and $_.command -ne "" -and $_.trigger.label -ne "Select trigger" }

Write-Output "Found $($activeRules.Count) active authentic S2E rules."

$configGifts = @()
$overlayCards = @()
$cardId = 1

foreach ($r in $activeRules) {
    $trig = $r.trigger
    $rawCmd = $r.command.Trim()
    
    # Extra actions chained with ;
    $fullCmd = $rawCmd
    if ($r.extraActions -and $r.extraActions.Count -gt 0) {
        $extraCmds = @()
        foreach ($ea in $r.extraActions) {
            if ($ea.command) { $extraCmds += $ea.command.Trim() }
        }
        if ($extraCmds.Count -gt 0) {
            $fullCmd = "$rawCmd; " + ($extraCmds -join "; ")
        }
    }

    $amount = if ($r.amount) { [int]$r.amount } else { 1 }
    $coins = if ($trig.coins) { [int]$trig.coins } else { 1 }
    $giftId = if ($trig.giftId) { [string]$trig.giftId } else { "" }
    $giftName = if ($trig.label) { [string]$trig.label } else { "Custom" }

    # Resolve unit name and type
    $lookupKey = $rawCmd.ToLower()
    $unitInfo = $unitLookup[$lookupKey]
    if (-not $unitInfo) {
        $lookupKey2 = ($rawCmd -replace '^spawn_', '').ToLower()
        $unitInfo = $unitLookup[$lookupKey2]
    }

    $unitName = if ($unitInfo) { $unitInfo.name } elseif ($labelMap.$rawCmd) { $labelMap.$rawCmd } else { $rawCmd }
    $actionType = if ($unitInfo) { $unitInfo.type } elseif ($rawCmd -match "plant|sunnut|threepeater|cattail") { "plant" } elseif ($rawCmd -match "kill_|plant_every|lawnmower|charm_") { "power" } else { "zombie" }

    # Resolve Unit Icon
    $unitIcon = ""
    if ($unitInfo -and (Test-Path $unitInfo.img)) {
        $unitIcon = $unitInfo.img
    } else {
        $cand1 = "images/game-icons/pvz/$rawCmd.webp"
        $cand2 = "images/game-icons/pvz/spawn_$rawCmd.webp"
        $cand3 = "images/game-icons/pvz/$($rawCmd -replace '^spawn_', '').webp"
        if (Test-Path $cand1) { $unitIcon = $cand1 }
        elseif (Test-Path $cand2) { $unitIcon = $cand2 }
        elseif (Test-Path $cand3) { $unitIcon = $cand3 }
        else {
            $unitIcon = if ($actionType -eq "plant") { "images/catmower.png" } elseif ($actionType -eq "power") { "images/func_15.png" } else { "images/func_2.png" }
        }
    }

    # Resolve Trigger Icon
    $trigIcon = ""
    $sanitizedLabel = ($giftName.ToLower() -replace '[^a-z0-9]', '_').Trim('_')
    $localGiftWebp = if ($giftId) { "images/tiktok-gifts/${giftId}_${sanitizedLabel}.webp" } else { "images/tiktok-gifts/${sanitizedLabel}.webp" }

    if ($trig.type -eq "share") {
        $trigIcon = "images/trig_1.svg"
    } elseif ($giftName -match "follower|follow") {
        $trigIcon = "images/trig_1.svg"
    } elseif ($giftName -match "like") {
        $trigIcon = "images/trig_7.svg"
    } elseif (Test-Path $localGiftWebp) {
        $trigIcon = $localGiftWebp
    } elseif ($trig.icon) {
        $trigIcon = $trig.icon
    } else {
        $trigIcon = "images/tiktok-gifts/5655_rose.webp"
    }

    # Overlay Action Type
    $overlayAction = "SelectedGift"
    if ($trig.type -eq "share") { $overlayAction = "Share" }
    elseif ($giftName -match "follower|follow") { $overlayAction = "Follow" }
    elseif ($giftName -match "like") { $overlayAction = "LikeForEach" }

    # 1. Overlay card entry
    $overlayCards += [PSCustomObject]@{
        id = [string]$cardId
        action = $overlayAction
        giftId = $giftId
        giftName = $giftName
        funcName = $unitName
        funcImg = $unitIcon
        trigImg = $trigIcon
        triggerValue = if ($overlayAction -eq "LikeForEach") { "50" } else { "" }
        commands = $fullCmd
        repetition = $amount
    }

    # 2. Studio Config gift entry
    $configGifts += [PSCustomObject]@{
        id = [string]$cardId
        giftName = $giftName
        giftId = $giftId
        coins = $coins
        icon = $trigIcon
        unitIcon = $unitIcon
        actionType = $actionType
        command = $fullCmd
        label = $unitName
        amount = $amount
        enabled = $true
    }

    $cardId++
}

# Update cards.json
$cardsJson = $overlayCards | ConvertTo-Json -Depth 6
[System.IO.File]::WriteAllText("cards.json", $cardsJson, [System.Text.Encoding]::UTF8)

# Update cards-data.js
$cardsDataJs = "const cardsData = " + ($overlayCards | ConvertTo-Json -Depth 6) + ";"
[System.IO.File]::WriteAllText("cards-data.js", $cardsDataJs, [System.Text.Encoding]::UTF8)

# Update pvz_fusion_config.json
$existingConfig = Get-Content "pvz_fusion_config.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$existingConfig.gifts = $configGifts
$configJson = $existingConfig | ConvertTo-Json -Depth 6
[System.IO.File]::WriteAllText("pvz_fusion_config.json", $configJson, [System.Text.Encoding]::UTF8)

Write-Output "SUCCESS: Synchronized $($overlayCards.Count) authentic S2E rules across cards.json, cards-data.js, and pvz_fusion_config.json!"
