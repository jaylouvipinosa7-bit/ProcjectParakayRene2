# ==============================================================================
# Build Accurate S2E PvZ Fusion Units Catalog
# ==============================================================================

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

function Find-BestIcon($cmd) {
    $c = $cmd.ToLower()
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
    
    return $null
}

. ".\verify_150_items.ps1"

$powersList = [System.Collections.ArrayList]::new()
$plantsList = [System.Collections.ArrayList]::new()
$zombiesList = [System.Collections.ArrayList]::new()
$s2eAllList = [System.Collections.ArrayList]::new()

$seenCmds = @{}

# 1. Add the 150 Reference Items from the 5 Photos in EXACT ORDER
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
        $found = Find-BestIcon $cmd
        if ($found) { $iconPath = $found }
    }

    $entry = [PSCustomObject]@{
        id       = $cmd
        name     = $ref.name
        command  = $cmd
        endpoint = $endpoint
        effect   = $effect
        img      = $iconPath
        icon     = $iconPath
        type     = if ($ref.type -eq "plant") { "Plant" } elseif ($ref.type -eq "zombie") { "Zombie" } else { "Power" }
        isS2E    = $true
    }

    $s2eAllList.Add($entry) | Out-Null
    if ($ref.type -eq "plant") {
        $plantsList.Add($entry) | Out-Null
    } elseif ($ref.type -eq "zombie") {
        $zombiesList.Add($entry) | Out-Null
    } else {
        $powersList.Add($entry) | Out-Null
    }
}

# 2. Add other powers
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

# 3. Add all remaining commands from runetify_all_commands_map.json
foreach ($prop in $cmdMap.PSObject.Properties) {
    $cmd = $prop.Name
    if ($seenCmds.ContainsKey($cmd.ToLower())) { continue }
    $seenCmds[$cmd.ToLower()] = $true

    $info = $prop.Value
    $endpoint = $info.endpoint
    $effect = $info.effect

    $iconPath = Find-BestIcon $cmd
    if (-not $iconPath) {
        if ($endpoint -eq '/spawnplant') { $iconPath = "images/game-icons/pvz/spawn_peashooter.webp" }
        elseif ($endpoint -eq '/spawnzombie') { $iconPath = "images/game-icons/pvz/spawn_zombie.webp" }
        else { $iconPath = "images/game-icons/pvz/win_level.webp" }
    }

    $label = if ($labelMap.$cmd) { $labelMap.$cmd } else {
        $clean = $cmd -replace '^spawn_', '' -replace '_', ' '
        (Get-Culture).TextInfo.ToTitleCase($clean)
    }

    $typeStr = if ($endpoint -eq '/spawnplant') { "Plant" } elseif ($endpoint -eq '/spawnzombie') { "Zombie" } else { "Power" }

    $entry = [PSCustomObject]@{
        id       = $cmd
        name     = $label
        command  = $cmd
        endpoint = $endpoint
        effect   = $effect
        img      = $iconPath
        icon     = $iconPath
        type     = $typeStr
        isS2E    = $false
    }

    $s2eAllList.Add($entry) | Out-Null
    if ($typeStr -eq "Plant") {
        $plantsList.Add($entry) | Out-Null
    } elseif ($typeStr -eq "Zombie") {
        $zombiesList.Add($entry) | Out-Null
    } else {
        $powersList.Add($entry) | Out-Null
    }
}

# 4. Check any remaining WebP icons in images/game-icons/pvz that weren't in cmdMap
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
    if ($typeStr -eq "Plant") {
        $plantsList.Add($entry) | Out-Null
    } elseif ($typeStr -eq "Zombie") {
        $zombiesList.Add($entry) | Out-Null
    } else {
        $powersList.Add($entry) | Out-Null
    }
}

Write-Output "Catalog Totals:"
Write-Output "  S2E All Items: $($s2eAllList.Count)"
Write-Output "  Plants:        $($plantsList.Count)"
Write-Output "  Zombies:       $($zombiesList.Count)"
Write-Output "  Powers:        $($powersList.Count)"

$allJson = $s2eAllList | ConvertTo-Json -Depth 4
$plantsJson = $plantsList | ConvertTo-Json -Depth 4
$zombiesJson = $zombiesList | ConvertTo-Json -Depth 4
$powersJson = $powersList | ConvertTo-Json -Depth 4

$finalJson = "{`"all`":" + $allJson + ",`"plants`":" + $plantsJson + ",`"zombies`":" + $zombiesJson + ",`"powers`":" + $powersJson + ",`"tiktokGifts`":" + $giftsJson + "}"
[System.IO.File]::WriteAllText("c:\Users\pc\Downloads\ano na\pvz_units_catalog.json", $finalJson, [System.Text.Encoding]::UTF8)

Write-Output "Successfully generated pvz_units_catalog.json with authentic S2E priority!"
