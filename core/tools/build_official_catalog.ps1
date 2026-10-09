# ==============================================================================
# Build Ultimate S2E PvZ Fusion Catalog with Official English In-Game Names
# ==============================================================================

$zombieAlmanac = Get-Content "C:\Users\pc\Desktop\games ko to ya\Game Files\Mods\PvZ_Fusion_Translator\Localization\English\Almanac\ZombieStringsTranslate.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$plantAlmanac = Get-Content "C:\Users\pc\Desktop\games ko to ya\Game Files\Mods\PvZ_Fusion_Translator\Localization\English\Almanac\LawnStringsTranslate.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$enums = Get-Content "pvz_game_enums.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$cmdMap = Get-Content "runetify_all_commands_map.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$labelMap = Get-Content "runetify_unit_labels.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$giftsJson = Get-Content "tiktok_gifts_verified.json" -Raw -Encoding UTF8
$cardsJson = Get-Content "cards.json" -Raw -Encoding UTF8 | ConvertFrom-Json

$iconFolder = "images\game-icons\pvz"
$allWebpFiles = Get-ChildItem -Path $iconFolder -Filter "*.webp"

# Build Comprehensive Multi-Key Normalized Lookup
$normLookup = @{}

function Register-IconKey($key, $path) {
    if (-not $key) { return }
    $k = $key.ToLower().Trim()
    if ($k.Length -gt 0 -and -not $normLookup.ContainsKey($k)) {
        $normLookup[$k] = $path
    }
}

foreach ($f in $allWebpFiles) {
    $path = "images/game-icons/pvz/$($f.Name)"
    $base = $f.BaseName.ToLower()
    $noSpawn = $base -replace '^spawn_', ''
    $clean = $base -replace '_', ''
    $cleanNoSpawn = $noSpawn -replace '_', ''

    Register-IconKey $base $path
    Register-IconKey $noSpawn $path
    Register-IconKey $clean $path
    Register-IconKey $cleanNoSpawn $path
    Register-IconKey "spawn_$cleanNoSpawn" $path
    Register-IconKey "spawn$cleanNoSpawn" $path
}

# Pre-map official in-game translations
$officialZombieNames = @{}
foreach ($z in $zombieAlmanac.zombies) {
    $officialZombieNames[[int]$z.theZombieType] = $z.name
}

$officialPlantNames = @{}
foreach ($p in $plantAlmanac.plants) {
    $officialPlantNames[[int]$p.seedType] = $p.name
}

function Find-AccurateIcon($name, $cmd, $type) {
    $cands = [System.Collections.ArrayList]::new()
    if ($cmd) {
        $cands.Add($cmd.ToLower()) | Out-Null
        $cands.Add(($cmd.ToLower() -replace '^spawn_', '')) | Out-Null
        $cands.Add(($cmd.ToLower() -replace '_', '')) | Out-Null
        $cands.Add(($cmd.ToLower() -replace '^spawn_', '' -replace '_', '')) | Out-Null
    }
    if ($name) {
        $cleanName = $name.ToLower() -replace '[^a-z0-9]', ''
        $cands.Add($cleanName) | Out-Null
        $cands.Add(($cleanName -replace '^spawn', '')) | Out-Null
    }

    foreach ($c in $cands) {
        if ($normLookup.ContainsKey($c)) { return $normLookup[$c] }
    }

    $combined = "$($cmd.ToLower()) $($name.ToLower())"
    if ($type -eq "Zombie") {
        if ($combined -match "trident|jugger|240") {
            return "images/game-icons/pvz/spawn_trident_juggernut_gargantuar.png"
        }
        if ($combined -match "hydrofowl|71") {
            return "images/game-icons/pvz/spawn_hydrofowl_zombie.png"
        }
        if ($combined -match "zomboss") {
            if ($combined -match "gold") { return "images/game-icons/pvz/spawn_zombie_golden_zomboss.webp" }
            return "images/game-icons/pvz/spawn_zombie_dr_zomboss.webp"
        }
        if ($combined -match "drown") {
            if ($combined -match "pult") { return "images/game-icons/pvz/spawn_drownpult_zombie.webp" }
            if ($combined -match "garg") { return "images/game-icons/pvz/spawn_drowngargantuar.webp" }
            if ($combined -match "football") { return "images/game-icons/pvz/spawn_football_drown.webp" }
            return "images/game-icons/pvz/spawn_drown_zombie.webp"
        }
        if ($combined -match "duck") { return "images/game-icons/pvz/spawn_zombie_duck.webp" }
        if ($combined -match "submarine") { return "images/game-icons/pvz/spawn_super_submarine.webp" }
        if ($combined -match "horse") {
            if ($combined -match "ultimate") { return "images/game-icons/pvz/spawn_ultimatehorse.webp" }
            return "images/game-icons/pvz/spawn_summonedhorse.webp"
        }
        if ($combined -match "pole") { return "images/game-icons/pvz/spawn_polevaulter_zombie.webp" }
        if ($combined -match "dancer|dance") { return "images/game-icons/pvz/spawn_dance_pol_zombie.webp" }
        if ($combined -match "bungi|bungee") { return "images/game-icons/pvz/spawn_bungi_zombie.webp" }
        if ($combined -match "paper|9527") {
            if ($combined -match "elite") { return "images/game-icons/pvz/spawn_elitepaper_zombie.webp" }
            return "images/game-icons/pvz/spawn_cherry_paper_zombie.webp"
        }
        if ($combined -match "tall_fire_nut|obsidian_tall_nut") { return "images/game-icons/pvz/spawn_tall_ice_nut_zombie.webp" }
        if ($combined -match "sun_nut|nut") { return "images/game-icons/pvz/spawn_bucket_nut_zombie.webp" }
        if ($combined -match "doll") { return "images/game-icons/pvz/spawn_doll_gold.webp" }
        if ($combined -match "imp") { return "images/game-icons/pvz/spawn_imp_zombie.webp" }
        if ($combined -match "garg") { return "images/game-icons/pvz/spawn_gargantuar.webp" }
        if ($combined -match "football") { return "images/game-icons/pvz/spawn_football_zombie.webp" }
        if ($combined -match "cone") { return "images/game-icons/pvz/spawn_conezombie.webp" }
        if ($combined -match "bucket") { return "images/game-icons/pvz/spawn_bucketzombie.webp" }
        if ($combined -match "balloon") { return "images/game-icons/pvz/spawn_balloon_zombie.webp" }
        if ($combined -match "catapult") { return "images/game-icons/pvz/spawn_catapult_zombie.webp" }
        if ($combined -match "jack") { return "images/game-icons/pvz/spawn_jack_in_the_box_zombie.webp" }
        if ($combined -match "miner") { return "images/game-icons/pvz/spawn_miner_zombie.webp" }
        if ($combined -match "flag") { return "images/game-icons/pvz/spawn_blackflagfootball.webp" }
        if ($combined -match "random") { return "images/game-icons/pvz/spawn_random_zombie.webp" }
        return "images/game-icons/pvz/spawn_armoredimpzombie.webp"
    }

    if ($type -eq "Plant") {
        if ($combined -match "sniper.*gatling|gatling.*sniper") { return "images/game-icons/pvz/spawn_ultimatesnipergatling.webp" }
        if ($combined -match "cattail") {
            if ($combined -match "girl") { return "images/game-icons/pvz/spawn_cattail_girl.webp" }
            if ($combined -match "lour") { return "images/game-icons/pvz/spawn_cattail_lour.webp" }
            return "images/game-icons/pvz/spawn_ultimatecattail.webp"
        }
        if ($combined -match "sun") {
            if ($combined -match "nut") { return "images/game-icons/pvz/spawn_big_sun_nut.webp" }
            if ($combined -match "shroom") { return "images/game-icons/pvz/spawn_big_sun_shroom.webp" }
            return "images/game-icons/pvz/spawn_gold_sunflower.webp"
        }
        if ($combined -match "nut") {
            if ($combined -match "tall") { return "images/game-icons/pvz/spawn_tallnut.webp" }
            return "images/game-icons/pvz/spawn_wall_nut.webp"
        }
        if ($combined -match "chomper") { return "images/game-icons/pvz/spawn_chomper.webp" }
        if ($combined -match "gloom") { return "images/game-icons/pvz/spawn_gloomshroom.webp" }
        if ($combined -match "fume") { return "images/game-icons/pvz/spawn_fume_shroom.webp" }
        if ($combined -match "puff|shroom") { return "images/game-icons/pvz/spawn_small_puff.webp" }
        if ($combined -match "cannon") { return "images/game-icons/pvz/spawn_cob_cannon.webp" }
        if ($combined -match "melon") { return "images/game-icons/pvz/spawn_melonpult.webp" }
        if ($combined -match "cabbage") { return "images/game-icons/pvz/spawn_cabbagepult.webp" }
        if ($combined -match "corn") { return "images/game-icons/pvz/spawn_cornpult.webp" }
        if ($combined -match "cherry|bomb") { return "images/game-icons/pvz/spawn_cherry_bomb.webp" }
        if ($combined -match "jalapeno") { return "images/game-icons/pvz/spawn_jalapeno.webp" }
        if ($combined -match "pumpkin") { return "images/game-icons/pvz/spawn_pumpkin.webp" }
        if ($combined -match "blover") { return "images/game-icons/pvz/spawn_blover.webp" }
        if ($combined -match "cactus") { return "images/game-icons/pvz/spawn_cactus.webp" }
        if ($combined -match "lotus") { return "images/game-icons/pvz/spawn_ice_lotus.webp" }
        if ($combined -match "dragon") { return "images/game-icons/pvz/spawn_bamboo_dragon.webp" }
        if ($combined -match "torch") { return "images/game-icons/pvz/spawn_torch_wood.webp" }
        if ($combined -match "spikerock|caltrop") { return "images/game-icons/pvz/spawn_caltrop.webp" }
        if ($combined -match "potato") { return "images/game-icons/pvz/spawn_potato_mine.webp" }
        if ($combined -match "squash") { return "images/game-icons/pvz/spawn_squash.webp" }
        if ($combined -match "lily") { return "images/game-icons/pvz/spawn_lily_pad.webp" }
        return "images/game-icons/pvz/spawn_peashooter.webp"
    }

    if ($combined -match "lawnmower") {
        if ($combined -match "delete") { return "images/game-icons/pvz/delete_lawnmower.webp" }
        if ($combined -match "remove") { return "images/game-icons/pvz/remove_lawnmower.webp" }
        if ($combined -match "restart") { return "images/game-icons/pvz/restart_lawnmower.webp" }
        return "images/game-icons/pvz/lawnmower.webp"
    }
    if ($combined -match "sun") { return "images/game-icons/pvz/add_sun.webp" }
    return "images/game-icons/pvz/win_level.webp"
}

. ".\verify_150_items.ps1"

$powersList = [System.Collections.ArrayList]::new()
$plantsList = [System.Collections.ArrayList]::new()
$zombiesList = [System.Collections.ArrayList]::new()
$s2eAllList = [System.Collections.ArrayList]::new()

$seenCmds = @{}

# 1. Add all 64 S2E Preset Cards first (including UltimateSniperGatling, DoomSniper, etc.)
foreach ($c in $cardsJson) {
    $rawCmd = $c.commands.Split(';')[0].Trim()
    if ($seenCmds.ContainsKey($rawCmd.ToLower())) { continue }
    $seenCmds[$rawCmd.ToLower()] = $true

    $isZombie = $rawCmd -match "zombie|gargantuar|horse|penguin|monster|machine|dolphin|jack|driver|boss"
    $typeStr = if ($isZombie) { "Zombie" } else { "Plant" }
    $ep = if ($typeStr -eq "Plant") { "/spawnplant" } else { "/spawnzombie" }
    
    $iconPath = $c.funcImg
    if (-not (Test-Path ($iconPath -replace '/', '\'))) {
        $iconPath = Find-AccurateIcon $c.funcName $rawCmd $typeStr
    }

    $mapInfo = $cmdMap.$rawCmd
    if (-not $mapInfo) {
        $clean = $rawCmd -replace '^spawn_', ''
        $mapInfo = $cmdMap.$clean
    }
    $effVal = if ($mapInfo -and $mapInfo.effect) { [string]$mapInfo.effect } else { "" }
    if ($rawCmd -match "ultimatesnipergatling") { $effVal = "309" }

    $entry = [PSCustomObject]@{
        id       = $rawCmd
        name     = $c.funcName
        command  = $rawCmd
        endpoint = $ep
        effect   = $effVal
        img      = $iconPath
        icon     = $iconPath
        type     = $typeStr
        isS2E    = $true
    }

    $s2eAllList.Add($entry) | Out-Null
    if ($typeStr -eq "Plant") { $plantsList.Add($entry) | Out-Null }
    else { $zombiesList.Add($entry) | Out-Null }
}

# 2. Add the 150 Reference Items from S2E in Exact Order
foreach ($ref in $s2eItems) {
    $cmd = $ref.cmd
    if ($seenCmds.ContainsKey($cmd.ToLower())) { continue }
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
        $iconPath = Find-AccurateIcon $ref.name $cmd (if ($ref.type -eq "plant") { "Plant" } elseif ($ref.type -eq "zombie") { "Zombie" } else { "Power" })
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

# 3. Add Other Powers
$otherPowers = @(
    @{ name = "Start Lawnmowers"; cmd = "start_lawnmowers"; ep = "/startlawnmowers"; icon = "images/game-icons/pvz/lawnmower.webp" },
    @{ name = "Delete Lawnmower"; cmd = "delete_lawnmower"; ep = "/deletelawnmowers"; icon = "images/game-icons/pvz/delete_lawnmower.webp" },
    @{ name = "Restart Lawnmower"; cmd = "restart_lawnmower"; ep = "/restartlawnmowers"; icon = "images/game-icons/pvz/restart_lawnmower.webp" },
    @{ name = "Remove Lawnmower"; cmd = "remove_lawnmower"; ep = "/removelawnmowers"; icon = "images/game-icons/pvz/remove_lawnmower.webp" },
    @{ name = "Clear All Plants"; cmd = "clear_all_plants"; ep = "/clearallplants"; icon = "images/game-icons/pvz/clear_all_plants.webp" },
    @{ name = "No Game Over"; cmd = "no_game_over"; ep = "/stopgameover"; icon = "images/game-icons/pvz/no_game_over.webp" },
    @{ name = "Plant Everywhere"; cmd = "plant_everywahre"; ep = "/planteverywhere"; icon = "images/game-icons/pvz/plant_everywahre.webp" },
    @{ name = "Free Plants On"; cmd = "free_plants_on"; ep = "/freeplants"; icon = "images/game-icons/pvz/free_plants_on.webp" },
    @{ name = "Free Plants Off"; cmd = "free_plants_off"; ep = "/freeplants"; icon = "images/game-icons/pvz/free_plants_off.webp" }
)

foreach ($p in $otherPowers) {
    if (-not $seenCmds.ContainsKey($p.cmd.ToLower())) {
        $seenCmds[$p.cmd.ToLower()] = $true
        $icon = $p.icon
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

# 4. Add ALL Plants from pvz_game_enums.json with OFFICIAL ENGLISH ALMANAC NAMES
foreach ($prop in ($enums.plants | Get-Member -MemberType NoteProperty)) {
    $pName = $prop.Name
    if ($pName -eq "Nothing" -or $pName.StartsWith("EnumValueAsmResolver")) { continue }
    $pVal = [int]$enums.plants.$pName
    $snake = ($pName -creplace '([a-z0-9])([A-Z])', '$1_$2').ToLower()
    $cmd = "spawn_$snake"

    if ($seenCmds.ContainsKey($cmd.ToLower()) -or $seenCmds.ContainsKey($snake.ToLower()) -or $seenCmds.ContainsKey($pName.ToLower())) {
        continue
    }
    $seenCmds[$cmd.ToLower()] = $true

    # Official English Name
    $label = if ($officialPlantNames.ContainsKey($pVal)) {
        "Spawn $($officialPlantNames[$pVal]) ($pVal)"
    } else {
        $cName = ($pName -creplace '([a-z0-9])([A-Z])', '$1 $2') -replace '_', ' '
        "Spawn $((Get-Culture).TextInfo.ToTitleCase($cName))"
    }

    $iconPath = Find-AccurateIcon $pName $cmd "Plant"

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

# 5. Add ALL Zombies from pvz_game_enums.json with OFFICIAL ENGLISH ALMANAC NAMES
foreach ($prop in ($enums.zombies | Get-Member -MemberType NoteProperty)) {
    $zName = $prop.Name
    if ($zName -eq "Nothing" -or $zName.StartsWith("EnumValueAsmResolver")) { continue }
    $zVal = [int]$enums.zombies.$zName
    $snake = ($zName -creplace '([a-z0-9])([A-Z])', '$1_$2').ToLower()
    $cmd = "spawn_$snake"

    if ($seenCmds.ContainsKey($cmd.ToLower()) -or $seenCmds.ContainsKey($snake.ToLower()) -or $seenCmds.ContainsKey($zName.ToLower())) {
        continue
    }
    $seenCmds[$cmd.ToLower()] = $true

    # Official English Name
    $label = if ($officialZombieNames.ContainsKey($zVal)) {
        "Spawn $($officialZombieNames[$zVal]) ($zVal)"
    } else {
        $cName = ($zName -creplace '([a-z0-9])([A-Z])', '$1 $2') -replace '_', ' '
        "Spawn $((Get-Culture).TextInfo.ToTitleCase($cName))"
    }

    $iconPath = Find-AccurateIcon $zName $cmd "Zombie"

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

# 6. Add remaining commands from runetify_all_commands_map.json
foreach ($prop in $cmdMap.PSObject.Properties) {
    $cmd = $prop.Name
    if ($seenCmds.ContainsKey($cmd.ToLower())) { continue }
    $seenCmds[$cmd.ToLower()] = $true

    $info = $prop.Value
    $endpoint = $info.endpoint
    $effect = $info.effect

    $typeStr = if ($endpoint -eq '/spawnplant') { "Plant" } elseif ($endpoint -eq '/spawnzombie') { "Zombie" } else { "Power" }
    
    $label = if ($labelMap.$cmd) { $labelMap.$cmd } else {
        $clean = $cmd -replace '^spawn_', '' -replace '_', ' '
        (Get-Culture).TextInfo.ToTitleCase($clean)
    }

    $iconPath = Find-AccurateIcon $label $cmd $typeStr

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

# 7. Add remaining icons from images/game-icons/pvz
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

Write-Host "New Complete S2E Catalog Breakdown:"
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

Write-Host "Successfully generated pvz_units_catalog.json with Official English in-game translations!"
