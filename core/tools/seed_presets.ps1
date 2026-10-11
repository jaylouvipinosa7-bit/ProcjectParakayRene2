$folder = Split-Path -Parent $PSScriptRoot
$s2eFile = Join-Path $folder "s2e_presets.json"
$cfgFile = Join-Path $folder "pvz_fusion_config.json"

$cfg = if (Test-Path $cfgFile) { Get-Content $cfgFile -Raw -Encoding UTF8 | ConvertFrom-Json } else { $null }
$existing = if (Test-Path $s2eFile) { Get-Content $s2eFile -Raw -Encoding UTF8 | ConvertFrom-Json } else { @{} }

$presetsObj = [ordered]@{}

# Helper to transfer existing
if ($existing) {
    foreach ($p in $existing.PSObject.Properties) {
        $presetsObj[$p.Name] = $p.Value
    }
}

# 1. Live Balagbagan (PvZ Fusion) - Picture 1 Row 1
$balagbaganEvents = if ($cfg -and $cfg.gifts) { $cfg.gifts } else { @() }
$presetsObj["preset_live_balagbagan"] = [ordered]@{
    "_id" = "preset_live_balagbagan"
    "id" = "preset_live_balagbagan"
    "name" = "live balagbagan"
    "game" = "PvZFusion"
    "createdAt" = "08/03/2026"
    "coverIcon" = "images/games/pvz_badge.svg"
    "eventsCount" = 100
    "overflowCount" = "+89"
    "previewSprites" = @(
        "images/game-icons/pvz/spawn_gatling_pea.webp",
        "images/game-icons/pvz/spawn_bucket_zombie.webp",
        "images/game-icons/pvz/spawn_ultimatehorse.webp",
        "images/game-icons/pvz/spawn_summonedhorse.webp",
        "images/game-icons/pvz/spawn_rabbit_zombie.webp",
        "images/game-icons/pvz/spawn_bucket_zombie.webp"
    )
    "allowImport" = $true
    "events" = $balagbaganEvents
}

# 2. Preset Name (PvZ Fusion) - Picture 1 Row 2
$presetsObj["preset_pvz_classic"] = [ordered]@{
    "_id" = "preset_pvz_classic"
    "id" = "preset_pvz_classic"
    "name" = "Preset Name"
    "game" = "PvZFusion"
    "createdAt" = "09/17/2026"
    "coverIcon" = "images/games/pvz_badge.svg"
    "eventsCount" = 28
    "overflowCount" = "+17"
    "previewSprites" = @(
        "images/game-icons/pvz/spawn_gatling_pea.webp",
        "images/game-icons/pvz/spawn_ultimate_football_zombie.webp",
        "images/game-icons/pvz/spawn_bucket_zombie.webp",
        "images/game-icons/pvz/spawn_ultimatehorse.webp",
        "images/game-icons/pvz/spawn_summonedhorse.webp"
    )
    "allowImport" = $true
    "events" = if ($balagbaganEvents.Count -ge 28) { $balagbaganEvents[0..27] } else { $balagbaganEvents }
}

# 3. KOTH Minecraft - Picture 1 Row 3
$presetsObj["preset_koth_minecraft"] = [ordered]@{
    "_id" = "preset_koth_minecraft"
    "id" = "preset_koth_minecraft"
    "name" = "KOTH Minecraft"
    "game" = "Minecraft"
    "createdAt" = "10/04/2026"
    "coverIcon" = "images/games/tnt.svg"
    "eventsCount" = 8
    "overflowCount" = ""
    "previewSprites" = @(
        "images/games/sprites/mc_zombie.svg",
        "images/games/sprites/mc_piglin.svg",
        "images/games/sprites/mc_zombie.svg",
        "images/games/sprites/mc_tnt.svg",
        "images/games/sprites/mc_iron.svg",
        "images/games/sprites/mc_gold.svg",
        "images/games/sprites/mc_diamond.svg",
        "images/games/sprites/mc_zombie.svg"
    )
    "allowImport" = $true
    "events" = @(
        [ordered]@{
            "id" = "mc_1"
            "giftName" = "Spawn Zombie Horde"
            "coins" = 1
            "icon" = "images/tiktok-gifts/5655_rose.webp"
            "unitIcon" = "images/games/sprites/mc_zombie.svg"
            "actionType" = "zombie"
            "command" = '/summon zombie ~ ~ ~ {CustomName:"Chat Horde"}'
            "label" = "Spawn Zombie"
            "amount" = 5
            "repetition" = 5
            "interval" = 100
            "delay" = 0
            "triggerType" = "gift"
            "spinnerRarity" = "Common"
            "targetGame" = "Minecraft"
        },
        [ordered]@{
            "id" = "mc_2"
            "giftName" = "Ignite TNT Block"
            "coins" = 20
            "icon" = "images/tiktok-gifts/5827_icecream.webp"
            "unitIcon" = "images/games/sprites/mc_tnt.svg"
            "actionType" = "bomb"
            "command" = "/summon tnt ~ ~ ~ {Fuse:40}"
            "label" = "Ignite Live TNT"
            "amount" = 1
            "repetition" = 1
            "interval" = 100
            "delay" = 0
            "triggerType" = "gift"
            "spinnerRarity" = "Rare"
            "targetGame" = "Minecraft"
        },
        [ordered]@{
            "id" = "mc_3"
            "giftName" = "Equip Diamond Armor"
            "coins" = 99
            "icon" = "images/tiktok-gifts/5655_rose.webp"
            "unitIcon" = "images/games/sprites/mc_diamond.svg"
            "actionType" = "plant"
            "command" = "/give @p diamond_chestplate 1"
            "label" = "Grant Diamond Armor"
            "amount" = 1
            "repetition" = 1
            "interval" = 100
            "delay" = 0
            "triggerType" = "gift"
            "spinnerRarity" = "Epic"
            "targetGame" = "Minecraft"
        }
    )
}

# 4. Shieldrunner - Picture 1 Row 4
$presetsObj["preset_shieldrunner"] = [ordered]@{
    "_id" = "preset_shieldrunner"
    "id" = "preset_shieldrunner"
    "name" = "Shieldrunner"
    "game" = "Minecraft"
    "createdAt" = "09/09/2026"
    "coverIcon" = "images/games/shield.svg"
    "eventsCount" = 32
    "overflowCount" = "+21"
    "previewSprites" = @(
        "images/games/sprites/mc_totem.svg",
        "images/games/sprites/mc_plus10.svg",
        "images/games/sprites/mc_minus10.svg",
        "images/games/sprites/mc_minus5.svg",
        "images/games/sprites/mc_minus1.svg",
        "images/games/sprites/mc_luckyblock.svg",
        "images/games/sprites/mc_villager.svg",
        "images/games/sprites/mc_arrows.svg"
    )
    "allowImport" = $true
    "events" = @(
        [ordered]@{
            "id" = "sr_1"
            "giftName" = "Totem of Undying"
            "coins" = 50
            "icon" = "images/tiktok-gifts/5655_rose.webp"
            "unitIcon" = "images/games/sprites/mc_totem.svg"
            "actionType" = "plant"
            "command" = "/give @p totem_of_undying 1"
            "label" = "Give Totem"
            "repetition" = 1
            "triggerType" = "gift"
            "spinnerRarity" = "Legendary"
            "targetGame" = "Minecraft"
        }
    )
}

# 5. TABS - Picture 1 Row 5
$presetsObj["preset_tabs"] = [ordered]@{
    "_id" = "preset_tabs"
    "id" = "preset_tabs"
    "name" = "TABS"
    "game" = "tabs"
    "createdAt" = "09/24/2026"
    "coverIcon" = "images/games/tabs.svg"
    "eventsCount" = 12
    "overflowCount" = "+1"
    "previewSprites" = @(
        "images/games/sprites/tabs_clubber.svg",
        "images/games/sprites/tabs_clubber.svg",
        "images/games/sprites/tabs_viking.svg",
        "images/games/sprites/tabs_viking.svg",
        "images/games/sprites/tabs_dragon.svg",
        "images/games/sprites/tabs_dragon.svg",
        "images/games/sprites/tabs_zeus.svg"
    )
    "allowImport" = $true
    "events" = @(
        [ordered]@{
            "id" = "tabs_1"
            "giftName" = "Spawn Red Dragon"
            "coins" = 99
            "icon" = "images/tiktok-gifts/5655_rose.webp"
            "unitIcon" = "images/games/sprites/tabs_dragon.svg"
            "actionType" = "zombie"
            "command" = "tabs_spawn?unit=dragon&team=red"
            "label" = "Summon Fire Dragon"
            "repetition" = 2
            "triggerType" = "gift"
            "targetGame" = "tabs"
        }
    )
}

# 6. Ultimate Epic Battle 2 - Picture 1 Row 6
$presetsObj["preset_uebs2"] = [ordered]@{
    "_id" = "preset_uebs2"
    "id" = "preset_uebs2"
    "name" = "Ultimate Epic Battle 2"
    "game" = "uebs2"
    "createdAt" = "09/05/2026"
    "coverIcon" = "images/games/uebs2.svg"
    "eventsCount" = 35
    "overflowCount" = "+24"
    "previewSprites" = @(
        "images/games/sprites/uebs_demon.svg",
        "images/games/sprites/uebs_trex.svg",
        "images/games/sprites/uebs_knight.svg",
        "images/games/sprites/uebs_chicken.svg"
    )
    "allowImport" = $true
    "events" = @(
        [ordered]@{
            "id" = "uebs_1"
            "giftName" = "Spawn Jurassic T-Rex"
            "coins" = 199
            "icon" = "images/tiktok-gifts/5655_rose.webp"
            "unitIcon" = "images/games/sprites/uebs_trex.svg"
            "actionType" = "zombie"
            "command" = "uebs_spawn?unit=trex&count=1"
            "label" = "Spawn Giant T-Rex"
            "repetition" = 1
            "triggerType" = "gift"
            "targetGame" = "uebs2"
        }
    )
}

# 7. Crown Clash - Picture 1 Row 7
$presetsObj["preset_crown_clash"] = [ordered]@{
    "_id" = "preset_crown_clash"
    "id" = "preset_crown_clash"
    "name" = "Crown Clash"
    "game" = "Crown Clash"
    "createdAt" = "09/22/2026"
    "coverIcon" = "images/games/crown_clash.svg"
    "eventsCount" = 16
    "overflowCount" = "+5"
    "previewSprites" = @(
        "images/games/sprites/cc_knight.svg",
        "images/games/sprites/cc_goblin.svg",
        "images/games/sprites/cc_knight.svg",
        "images/games/sprites/cc_goblin.svg",
        "images/games/sprites/cc_paladin.svg",
        "images/games/sprites/cc_wizard.svg",
        "images/games/sprites/cc_goblin.svg"
    )
    "allowImport" = $true
    "events" = @(
        [ordered]@{
            "id" = "cc_1"
            "giftName" = "Deploy Goblin Swarm"
            "coins" = 5
            "icon" = "images/tiktok-gifts/5655_rose.webp"
            "unitIcon" = "images/games/sprites/cc_goblin.svg"
            "actionType" = "zombie"
            "command" = "cc_deploy?card=goblin_swarm"
            "label" = "Deploy Goblins"
            "repetition" = 3
            "triggerType" = "gift"
            "targetGame" = "Crown Clash"
        }
    )
}

$jsonOut = $presetsObj | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($s2eFile, $jsonOut, [System.Text.Encoding]::UTF8)
Write-Output "Successfully seeded presets! Total: $($presetsObj.Count)"
