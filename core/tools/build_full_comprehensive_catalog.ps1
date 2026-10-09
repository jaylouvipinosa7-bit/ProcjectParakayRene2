# ==============================================================================
# Build Complete 100% Comprehensive S2E PvZ Fusion Catalog
# Includes ALL 729 Plants, ALL 237 Zombies, All Powers, All TikTok Gifts
# ==============================================================================

$enums = Get-Content "pvz_game_enums.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$cmdMap = Get-Content "runetify_all_commands_map.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$labelMap = Get-Content "runetify_unit_labels.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$giftsJson = Get-Content "tiktok_gifts_verified.json" -Raw -Encoding UTF8
$iconFolder = "images\game-icons\pvz"
$allWebpFiles = Get-ChildItem -Path $iconFolder -Filter "*.webp"

# Lookup of WebP files by lowercase name without extension
$webpLookup = @{}
foreach ($f in $allWebpFiles) {
    $webpLookup[$f.BaseName.ToLower()] = "images/game-icons/pvz/$($f.Name)"
}

function Find-BestIcon($str, $type) {
    $defaultPlant = "images/game-icons/pvz/spawn_peashooter.webp"
    $defaultZombie = "images/game-icons/pvz/spawn_random_zombie.webp"
    
    if (-not $str) {
        return if ($type -eq "Plant") { $defaultPlant } else { $defaultZombie }
    }
    $c = $str.ToLower()
    if ($webpLookup.ContainsKey($c)) { return $webpLookup[$c] }
    
    # Try spawn_ prefix
    if (-not $c.StartsWith('spawn_') -and $webpLookup.ContainsKey("spawn_$c")) {
        return $webpLookup["spawn_$c"]
    }
    
    # Try removing spawn_ prefix
    if ($c.StartsWith('spawn_')) {
        $noSpawn = $c.Substring(6)
        if ($webpLookup.ContainsKey($noSpawn)) { return $webpLookup[$noSpawn] }
    }
    
    # Try without underscores
    $noUnderscore = $c -replace '_', ''
    foreach ($k in $webpLookup.Keys) {
        if (($k -replace '_', '') -eq $noUnderscore) {
            return $webpLookup[$k]
        }
    }
    
    # Keyword matches
    if ($type -eq "Plant") {
        if ($c -match "cattail") { 
            if ($webpLookup.ContainsKey("spawn_ultimatecattail")) { return $webpLookup["spawn_ultimatecattail"] }
            if ($webpLookup.ContainsKey("spawn_cattail_girl")) { return $webpLookup["spawn_cattail_girl"] }
        }
        if ($c -match "sun") { 
            if ($webpLookup.ContainsKey("spawn_gold_sunflower")) { return $webpLookup["spawn_gold_sunflower"] }
            if ($webpLookup.ContainsKey("spawn_big_sun_nut")) { return $webpLookup["spawn_big_sun_nut"] }
        }
        if ($c -match "peashooter|shooter|peater") { return $defaultPlant }
        if ($c -match "nut") { 
            if ($webpLookup.ContainsKey("spawn_wall_nut")) { return $webpLookup["spawn_wall_nut"] }
            if ($webpLookup.ContainsKey("spawn_tallnut")) { return $webpLookup["spawn_tallnut"] }
        }
        if ($c -match "chomper") { 
            if ($webpLookup.ContainsKey("spawn_chomper")) { return $webpLookup["spawn_chomper"] }
            if ($webpLookup.ContainsKey("spawn_super_chomper")) { return $webpLookup["spawn_super_chomper"] }
        }
        if ($c -match "shroom|puff") { 
            if ($webpLookup.ContainsKey("spawn_fume_shroom")) { return $webpLookup["spawn_fume_shroom"] }
            if ($webpLookup.ContainsKey("spawn_doom_shroom")) { return $webpLookup["spawn_doom_shroom"] }
        }
        if ($c -match "melon|cabbage|corn|pult") { 
            if ($webpLookup.ContainsKey("spawn_cabbagepult")) { return $webpLookup["spawn_cabbagepult"] }
        }
        if ($c -match "cherry|bomb|doom|jalapeno") { 
            if ($webpLookup.ContainsKey("spawn_cherry_bomb")) { return $webpLookup["spawn_cherry_bomb"] }
        }
        if ($c -match "pumpkin") { 
            if ($webpLookup.ContainsKey("spawn_pumpkin")) { return $webpLookup["spawn_pumpkin"] }
        }
        if ($c -match "blover") { 
            if ($webpLookup.ContainsKey("spawn_blover")) { return $webpLookup["spawn_blover"] }
        }
        if ($c -match "cactus") { 
            if ($webpLookup.ContainsKey("spawn_cactus")) { return $webpLookup["spawn_cactus"] }
        }
        return $defaultPlant
    } else {
        if ($c -match "horse") { 
            if ($webpLookup.ContainsKey("spawn_summonedhorse")) { return $webpLookup["spawn_summonedhorse"] }
            if ($webpLookup.ContainsKey("spawn_ultimatehorse")) { return $webpLookup["spawn_ultimatehorse"] }
        }
        if ($c -match "gargantuar") { 
            if ($webpLookup.ContainsKey("spawn_gargantuar")) { return $webpLookup["spawn_gargantuar"] }
            if ($webpLookup.ContainsKey("ultimate_gold_gargantuar")) { return $webpLookup["ultimate_gold_gargantuar"] }
        }
        if ($c -match "imp") { 
            if ($webpLookup.ContainsKey("spawn_imp")) { return $webpLookup["spawn_imp"] }
            if ($webpLookup.ContainsKey("spawn_armoredimpzombie")) { return $webpLookup["spawn_armoredimpzombie"] }
        }
        if ($c -match "football") { 
            if ($webpLookup.ContainsKey("spawn_football_zombie")) { return $webpLookup["spawn_football_zombie"] }
            if ($webpLookup.ContainsKey("spawn_ultimate_football_zombie")) { return $webpLookup["spawn_ultimate_football_zombie"] }
        }
        if ($c -match "cone") { 
            if ($webpLookup.ContainsKey("spawn_conehead_zombie")) { return $webpLookup["spawn_conehead_zombie"] }
            if ($webpLookup.ContainsKey("spawn_conezombie")) { return $webpLookup["spawn_conezombie"] }
        }
        if ($c -match "bucket") { 
            if ($webpLookup.ContainsKey("spawn_buckethead_zombie")) { return $webpLookup["spawn_buckethead_zombie"] }
            if ($webpLookup.ContainsKey("spawn_bucketzombie")) { return $webpLookup["spawn_bucketzombie"] }
        }
        if ($c -match "dancer|pole|bungi|miner") { 
            if ($webpLookup.ContainsKey("spawn_dancing_zombie")) { return $webpLookup["spawn_dancing_zombie"] }
        }
        if ($c -match "flag") { 
            if ($webpLookup.ContainsKey("spawn_blackflagfootball")) { return $webpLookup["spawn_blackflagfootball"] }
        }
        return $defaultZombie
    }
}

function To-CamelCaseLabel($str) {
    $s = $str -creplace '([a-z0-9])([A-Z])', '$1 $2'
    $s = $s -replace '_', ' '
    return (Get-Culture).TextInfo.ToTitleCase($s)
}

function To-Snake($s) {
    return ($s -creplace '([a-z0-9])([A-Z])', '$1_$2').ToLower()
}

. ".\verify_150_items.ps1"

$powersList = [System.Collections.ArrayList]::new()
$plantsList = [System.Collections.ArrayList]::new()
$zombiesList = [System.Collections.ArrayList]::new()
$s2eAllList = [System.Collections.ArrayList]::new()

$seenCmds = @{}

# 1. Add 150 Reference Items from S2E in Exact Order
foreach ($ref in $s2eItems) {
    $cmd = $ref.cmd
    $seenCmds[$cmd.ToLower()] = $true

    $mapInfo = $cmdMap.$cmd
    if (-not $mapInfo) {
        $clean = $cmd -replace '^spawn_', ''
        $mapInfo = $cmdMap.$clean
    }

    $endpoint = if ($mapInfo -and $mapInfo.endpoint) { $mapInfo.endpoint } else {
        if ($ref.type -eq "plant") { "/spawnplant" }
        elseif ($ref.type -eq "zombie") { "/spawnzombie" }
        else { "/$($cmd -replace '_','')" }
    }
    $effect = if ($mapInfo -and $mapInfo.effect) { $mapInfo.effect } else { "" }

    $iconPath = $ref.img
    if (-not (Test-Path ($iconPath -replace '/', '\'))) {
        $found = Find-BestIcon $cmd $ref.type
        if ($found) { $iconPath = $found }
    }

    $entry = [PSCustomObject]@{
        id       = $cmd
        name     = $ref.name
        command  = $cmd
        endpoint = $endpoint
        effect   = "$effect"
        img      = $iconPath
        icon     = $iconPath
        type     = if ($ref.type -eq "plant") { "Plant" } elseif ($ref.type -eq "zombie") { "Zombie" } else { "Power" }
        isS2E    = $true
    }

    $s2eAllList.Add($entry) | Out-Null
    if ($ref.type -eq "plant") { $plantsList.Add($entry) | Out-Null }
    elseif ($ref.type -eq "zombie") { $zombiesList.Add($entry) | Out-Null }
    else { $powersList.Add($entry) | Out-Null }
}

# 2. Add Other Power actions
$otherPowers = @(
    @{ name = "Start Lawnmowers"; cmd = "start_lawnmowers"; ep = "/startlawnmowers"; icon = "lawnmower.webp" },
    @{ name = "Delete Lawnmower"; cmd = "delete_lawnmower"; ep = "/deletelawnmowers"; icon = "delete_lawnmower.webp" },
    @{ name = "Restart Lawnmower"; cmd = "restart_lawnmower"; ep = "/restartlawnmowers"; icon = "restart_lawnmower.webp" },
    @{ name = "Remove Lawnmower"; cmd = "remove_lawnmower"; ep = "/removelawnmowers"; icon = "remove_lawnmower.webp" },
    @{ name = "Clear All Plants"; cmd = "clear_all_plants"; ep = "/clearallplants"; icon = "clear_all_plants.webp" },
    @{ name = "No Game Over"; cmd = "no_game_over"; ep = "/stopgameover"; icon = "no_game_over.webp" },
    @{ name = "Plant Everywhere"; cmd = "plant_everywahre"; ep = "/planteverywhere"; icon = "plant_everywahre.webp" },
    @{ name = "Free Plants On"; cmd = "free_plants_on"; ep = "/freeplants"; icon = "free_plants_on.webp" },
    @{ name = "Free Plants Off"; cmd = "free_plants_off"; ep = "/freeplants"; icon = "free_plants_off.webp" }
)

foreach ($p in $otherPowers) {
    if (-not $seenCmds.ContainsKey($p.cmd.ToLower())) {
        $seenCmds[$p.cmd.ToLower()] = $true
        $icon = "images/game-icons/pvz/$($p.icon)"
        if (-not (Test-Path ($icon -replace '/', '\'))) {
            $icon = "images/game-icons/pvz/lawnmower.webp"
        }
        $entry = [PSCustomObject]@{
            id       = $p.cmd
            name     = $p.name
            command  = $p.cmd
            endpoint = $p.ep
            effect   = ""
            img      = $icon
            icon     = $icon
            type     = "Power"
            isS2E    = $true
        }
        $powersList.Add($entry) | Out-Null
        $s2eAllList.Add($entry) | Out-Null
    }
}

# 3. Add ALL Plants from pvz_game_enums.json (Total 729)
foreach ($prop in ($enums.plants | Get-Member -MemberType NoteProperty)) {
    $pName = $prop.Name
    if ($pName -eq "Nothing" -or $pName.StartsWith("EnumValueAsmResolver")) { continue }
    $pVal = $enums.plants.$pName
    $snake = To-Snake $pName
    $cmd = "spawn_$snake"

    if ($seenCmds.ContainsKey($cmd.ToLower()) -or $seenCmds.ContainsKey($snake.ToLower()) -or $seenCmds.ContainsKey($pName.ToLower())) {
        continue
    }
    $seenCmds[$cmd.ToLower()] = $true

    $iconPath = Find-BestIcon $pName "Plant"
    $label = To-CamelCaseLabel $pName
    if (-not $label.StartsWith("Spawn ")) { $label = "Spawn $label" }

    $entry = [PSCustomObject]@{
        id       = $cmd
        name     = $label
        command  = $cmd
        endpoint = "/spawnplant"
        effect   = "$pVal"
        img      = $iconPath
        icon     = $iconPath
        type     = "Plant"
        isS2E    = $false
    }
    $plantsList.Add($entry) | Out-Null
    $s2eAllList.Add($entry) | Out-Null
}

# 4. Add ALL Zombies from pvz_game_enums.json (Total 237)
foreach ($prop in ($enums.zombies | Get-Member -MemberType NoteProperty)) {
    $zName = $prop.Name
    if ($zName -eq "Nothing" -or $zName.StartsWith("EnumValueAsmResolver")) { continue }
    $zVal = $enums.zombies.$zName
    $snake = To-Snake $zName
    $cmd = "spawn_$snake"

    if ($seenCmds.ContainsKey($cmd.ToLower()) -or $seenCmds.ContainsKey($snake.ToLower()) -or $seenCmds.ContainsKey($zName.ToLower())) {
        continue
    }
    $seenCmds[$cmd.ToLower()] = $true

    $iconPath = Find-BestIcon $zName "Zombie"
    $label = To-CamelCaseLabel $zName
    if (-not $label.StartsWith("Spawn ")) { $label = "Spawn $label" }

    $entry = [PSCustomObject]@{
        id       = $cmd
        name     = $label
        command  = $cmd
        endpoint = "/spawnzombie"
        effect   = "$zVal"
        img      = $iconPath
        icon     = $iconPath
        type     = "Zombie"
        isS2E    = $false
    }
    $zombiesList.Add($entry) | Out-Null
    $s2eAllList.Add($entry) | Out-Null
}

# 5. Add all remaining commands from runetify_all_commands_map.json
foreach ($prop in $cmdMap.PSObject.Properties) {
    $cmd = $prop.Name
    if ($seenCmds.ContainsKey($cmd.ToLower())) { continue }
    $seenCmds[$cmd.ToLower()] = $true

    $info = $prop.Value
    $endpoint = $info.endpoint
    $effect = $info.effect

    $typeStr = if ($endpoint -eq '/spawnplant') { "Plant" } elseif ($endpoint -eq '/spawnzombie') { "Zombie" } else { "Power" }
    $iconPath = Find-BestIcon $cmd $typeStr

    $label = if ($labelMap.$cmd) { $labelMap.$cmd } else {
        $clean = $cmd -replace '^spawn_', '' -replace '_', ' '
        (Get-Culture).TextInfo.ToTitleCase($clean)
    }

    $entry = [PSCustomObject]@{
        id       = $cmd
        name     = $label
        command  = $cmd
        endpoint = $endpoint
        effect   = "$effect"
        img      = $iconPath
        icon     = $iconPath
        type     = $typeStr
        isS2E    = $false
    }

    $s2eAllList.Add($entry) | Out-Null
    if ($typeStr -eq "Plant") { $plantsList.Add($entry) | Out-Null }
    elseif ($typeStr -eq "Zombie") { $zombiesList.Add($entry) | Out-Null }
    else { $powersList.Add($entry) | Out-Null }
}

# 6. Add remaining icons from images/game-icons/pvz
foreach ($file in $allWebpFiles) {
    $base = $file.BaseName
    if ($seenCmds.ContainsKey($base.ToLower())) { continue }
    $seenCmds[$base.ToLower()] = $true

    $isZombie = $base -match "zombie|gargantuar|imp|cone|bucket|screen|football|pole|dancer|miner|balloon|catapult|bungee|ladder|jack|snorkel"
    $isPower = $base -match "sun|lawnmower|kill|invulnerable|cooldown|rain|win|meteor|mecha|damage|demage|cheat"
    $typeStr = if ($isPower) { "Power" } elseif ($isZombie) { "Zombie" } else { "Plant" }
    $endpoint = if ($typeStr -eq "Plant") { "/spawnplant" } elseif ($typeStr -eq "Zombie") { "/spawnzombie" } else { "/$($base -replace '_','')" }

    $clean = $base -replace '^spawn_', '' -replace '_', ' '
    $label = (Get-Culture).TextInfo.ToTitleCase($clean)
    $icon = "images/game-icons/pvz/$($file.Name)"

    $entry = [PSCustomObject]@{
        id       = $base
        name     = $label
        command  = $base
        endpoint = $endpoint
        effect   = ""
        img      = $icon
        icon     = $icon
        type     = $typeStr
        isS2E    = $false
    }

    $s2eAllList.Add($entry) | Out-Null
    if ($typeStr -eq "Plant") { $plantsList.Add($entry) | Out-Null }
    elseif ($typeStr -eq "Zombie") { $zombiesList.Add($entry) | Out-Null }
    else { $powersList.Add($entry) | Out-Null }
}

Write-Host "New Complete Catalog Breakdown:"
Write-Host "  Total Items: $($s2eAllList.Count)"
Write-Host "  Plants:      $($plantsList.Count)"
Write-Host "  Zombies:     $($zombiesList.Count)"
Write-Host "  Powers:      $($powersList.Count)"

$allJson = $s2eAllList | ConvertTo-Json -Depth 4
$plantsJson = $plantsList | ConvertTo-Json -Depth 4
$zombiesJson = $zombiesList | ConvertTo-Json -Depth 4
$powersJson = $powersList | ConvertTo-Json -Depth 4

$finalJson = "{`"all`":" + $allJson + ",`"plants`":" + $plantsJson + ",`"zombies`":" + $zombiesJson + ",`"powers`":" + $powersJson + ",`"tiktokGifts`":" + $giftsJson + "}"
[System.IO.File]::WriteAllText("c:\Users\pc\Downloads\ano na\pvz_units_catalog.json", $finalJson, [System.Text.Encoding]::UTF8)

Write-Host "Successfully generated 100% complete pvz_units_catalog.json!"
