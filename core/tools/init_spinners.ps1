$cfg = Get-Content 'pvz_fusion_config.json' -Raw -Encoding UTF8 | ConvertFrom-Json

# Build default 2 spinners matching screenshot
$spinner1Slices = @(
    [PSCustomObject]@{ id = "s1_1"; label = "Nuclear Doom Cherry"; actionType = "plant"; command = "spawn_nucleardoomcherry"; amount = 3; rarity = "Mythic"; weight = 5; color = "#ef4444"; unitIcon = "images/game-icons/pvz/spawn_nucleardoomcherry.webp" },
    [PSCustomObject]@{ id = "s1_2"; label = "Super Threepeater SP"; actionType = "plant"; command = "spawn_superthreepeater_sp"; amount = 6; rarity = "Legendary"; weight = 8; color = "#f59e0b"; unitIcon = "images/game-icons/pvz/spawn_superthreepeater_sp.webp" },
    [PSCustomObject]@{ id = "s1_3"; label = "Ultimate Cattail"; actionType = "plant"; command = "spawn_ultimatecattail"; amount = 1; rarity = "Legendary"; weight = 10; color = "#f59e0b"; unitIcon = "images/game-icons/pvz/spawn_ultimatecattail.webp" },
    [PSCustomObject]@{ id = "s1_4"; label = "Ultimate Sniper Gatling"; actionType = "plant"; command = "spawn_ultimatesnipergatling"; amount = 10; rarity = "Legendary"; weight = 10; color = "#f59e0b"; unitIcon = "images/game-icons/pvz/spawn_ultimatesnipergatling.webp" },
    [PSCustomObject]@{ id = "s1_5"; label = "Ultimate Big Sniper"; actionType = "plant"; command = "spawn_ultimate_big_sniper"; amount = 1; rarity = "Legendary"; weight = 12; color = "#f59e0b"; unitIcon = "images/game-icons/pvz/spawn_ultimate_big_sniper.webp" },
    [PSCustomObject]@{ id = "s1_6"; label = "Charm All Zombies"; actionType = "power"; command = "charmallzombies"; amount = 1; rarity = "Epic"; weight = 15; color = "#a855f7"; unitIcon = "images/game-icons/pvz/charm_all_zombies.webp" },
    [PSCustomObject]@{ id = "s1_7"; label = "Launch Lawnmowers"; actionType = "power"; command = "startlawnmowers"; amount = 1; rarity = "Epic"; weight = 15; color = "#a855f7"; unitIcon = "images/game-icons/pvz/lawnmower.webp" },
    [PSCustomObject]@{ id = "s1_8"; label = "Big Sun Nut"; actionType = "plant"; command = "spawn_big_sun_nut"; amount = 50; rarity = "Rare"; weight = 20; color = "#3b82f6"; unitIcon = "images/game-icons/pvz/spawn_big_sun_nut.webp" },
    [PSCustomObject]@{ id = "s1_9"; label = "Bedrock Tall Nut"; actionType = "plant"; command = "spawn_bedrocktallnut"; amount = 6; rarity = "Rare"; weight = 20; color = "#3b82f6"; unitIcon = "images/game-icons/pvz/spawn_bedrocktallnut.webp" },
    [PSCustomObject]@{ id = "s1_10"; label = "Ultimate Corn"; actionType = "plant"; command = "spawn_ultimate_corn"; amount = 2; rarity = "Normal"; weight = 25; color = "#94a3b8"; unitIcon = "images/game-icons/pvz/spawn_ultimate_corn.webp" }
)

$spinner2Slices = @(
    [PSCustomObject]@{ id = "s2_1"; label = "Golden Zomboss"; actionType = "zombie"; command = "spawn_zombie_boss2"; amount = 30; rarity = "Mythic"; weight = 3; color = "#ef4444"; unitIcon = "images/game-icons/pvz/spawn_zombie_boss2.webp" },
    [PSCustomObject]@{ id = "s2_2"; label = "Ultimate Gold Gargantuar"; actionType = "zombie"; command = "ultimate_gold_gargantuar"; amount = 2; rarity = "Legendary"; weight = 8; color = "#f59e0b"; unitIcon = "images/game-icons/pvz/ultimate_gold_gargantuar.webp" },
    [PSCustomObject]@{ id = "s2_3"; label = "Trident Jugger-nut Gargantuar"; actionType = "zombie"; command = "spawn_ulti_water_gargantuar"; amount = 1; rarity = "Legendary"; weight = 10; color = "#f59e0b"; unitIcon = "images/game-icons/pvz/spawn_ulti_water_gargantuar.webp" },
    [PSCustomObject]@{ id = "s2_4"; label = "Hydrofowl Zombie"; actionType = "zombie"; command = "spawn_boat_imp"; amount = 2; rarity = "Epic"; weight = 15; color = "#a855f7"; unitIcon = "images/game-icons/pvz/spawn_boat_imp.webp" },
    [PSCustomObject]@{ id = "s2_5"; label = "Kirov Airship"; actionType = "zombie"; command = "spawn_kirov_c"; amount = 30; rarity = "Epic"; weight = 15; color = "#a855f7"; unitIcon = "images/game-icons/pvz/spawn_kirov_c.webp" },
    [PSCustomObject]@{ id = "s2_6"; label = "Ultimate Machine Nut Zombie"; actionType = "zombie"; command = "spawn_ultimate_machine_nut_zombie"; amount = 50; rarity = "Rare"; weight = 20; color = "#3b82f6"; unitIcon = "images/game-icons/pvz/spawn_ultimate_machine_nut_zombie.webp" },
    [PSCustomObject]@{ id = "s2_7"; label = "Ultimate Horse"; actionType = "zombie"; command = "spawn_ultimatehorse"; amount = 20; rarity = "Rare"; weight = 20; color = "#3b82f6"; unitIcon = "images/game-icons/pvz/spawn_ultimatehorse.webp" },
    [PSCustomObject]@{ id = "s2_8"; label = "Ultimate Football Zombie"; actionType = "zombie"; command = "spawn_ultimate_football_zombie"; amount = 1; rarity = "Normal"; weight = 25; color = "#94a3b8"; unitIcon = "images/game-icons/pvz/spawn_ultimate_football_zombie.webp" }
)

$spinners = @(
    [PSCustomObject]@{
        id = "spinner_1"
        groupId = 5
        name = "Spinner"
        duration = 2500
        ticks = 100
        giftName = "Perfume"
        giftId = "perfume"
        giftIcon = "images/tiktok-gifts/perfume_gift.webp"
        coins = 20
        audience = "Anyone"
        enabled = $true
        mode = "reel"
        style = "neon"
        pointerIcon = "images/game-icons/pvz/spawn_ultimatecattail.webp"
        slices = $spinner1Slices
    },
    [PSCustomObject]@{
        id = "spinner_2"
        groupId = 1
        name = "zombies spinner"
        duration = 2500
        ticks = 100
        giftName = "Doughnut"
        giftId = "5879"
        giftIcon = "images/tiktok-gifts/5879_doughnut.webp"
        coins = 30
        audience = "Anyone"
        enabled = $true
        mode = "reel"
        style = "neon"
        pointerIcon = "images/game-icons/pvz/ultimate_gold_gargantuar.webp"
        slices = $spinner2Slices
    }
)

$cfg | Add-Member -NotePropertyName "spinners" -NotePropertyValue $spinners -Force
$cfg.spinner = $spinners[0]

$json = $cfg | ConvertTo-Json -Depth 8
[System.IO.File]::WriteAllText("c:\Users\pc\Downloads\ano na\pvz_fusion_config.json", $json, [System.Text.Encoding]::UTF8)
Write-Output "Successfully updated pvz_fusion_config.json with 2 authentic spinner groups!"
