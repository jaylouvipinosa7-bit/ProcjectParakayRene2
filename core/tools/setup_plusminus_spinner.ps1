$cfgPath = "c:\Users\pc\Downloads\ano na\core\pvz_fusion_config.json"
$cfg = Get-Content $cfgPath -Raw -Encoding UTF8 | ConvertFrom-Json

$pmSlices = @(
    [PSCustomObject]@{ id = "pm_1"; label = "1"; delta = 1; value = 1; amount = 1; weight = 20; chance = 15; color = "#f43f5e"; rarity = "Normal"; unitIcon = "images/numbers/num_pos_1.svg"; actionType = "score" },
    [PSCustomObject]@{ id = "pm_2"; label = "5"; delta = 5; value = 5; amount = 5; weight = 15; chance = 12; color = "#a855f7"; rarity = "Rare"; unitIcon = "images/numbers/num_pos_5.svg"; actionType = "score" },
    [PSCustomObject]@{ id = "pm_3"; label = "10"; delta = 10; value = 10; amount = 10; weight = 12; chance = 10; color = "#ec4899"; rarity = "Epic"; unitIcon = "images/numbers/num_pos_10.svg"; actionType = "score" },
    [PSCustomObject]@{ id = "pm_4"; label = "20"; delta = 20; value = 20; amount = 20; weight = 10; chance = 8; color = "#f59e0b"; rarity = "Legendary"; unitIcon = "images/numbers/num_pos_20.svg"; actionType = "score" },
    [PSCustomObject]@{ id = "pm_5"; label = "50"; delta = 50; value = 50; amount = 50; weight = 6; chance = 5; color = "#10b981"; rarity = "Mythic"; unitIcon = "images/numbers/num_pos_50.svg"; actionType = "score" },
    [PSCustomObject]@{ id = "pm_6"; label = "100"; delta = 100; value = 100; amount = 100; weight = 3; chance = 2; color = "#fb7185"; rarity = "Mythic"; unitIcon = "images/numbers/num_pos_100.svg"; actionType = "score" },
    [PSCustomObject]@{ id = "pm_7"; label = "-1"; delta = -1; value = -1; amount = -1; weight = 20; chance = 15; color = "#ef4444"; rarity = "Normal"; unitIcon = "images/numbers/num_neg_1.svg"; actionType = "score" },
    [PSCustomObject]@{ id = "pm_8"; label = "-5"; delta = -5; value = -5; amount = -5; weight = 15; chance = 12; color = "#8b5cf6"; rarity = "Rare"; unitIcon = "images/numbers/num_neg_5.svg"; actionType = "score" },
    [PSCustomObject]@{ id = "pm_9"; label = "-10"; delta = -10; value = -10; amount = -10; weight = 12; chance = 10; color = "#d946ef"; rarity = "Epic"; unitIcon = "images/numbers/num_neg_10.svg"; actionType = "score" },
    [PSCustomObject]@{ id = "pm_10"; label = "-20"; delta = -20; value = -20; amount = -20; weight = 10; chance = 8; color = "#f59e0b"; rarity = "Legendary"; unitIcon = "images/numbers/num_neg_20.svg"; actionType = "score" },
    [PSCustomObject]@{ id = "pm_11"; label = "-50"; delta = -50; value = -50; amount = -50; weight = 6; chance = 5; color = "#059669"; rarity = "Mythic"; unitIcon = "images/numbers/num_neg_50.svg"; actionType = "score" },
    [PSCustomObject]@{ id = "pm_12"; label = "-100"; delta = -100; value = -100; amount = -100; weight = 3; chance = 2; color = "#dc2626"; rarity = "Mythic"; unitIcon = "images/numbers/num_neg_100.svg"; actionType = "score" },
    [PSCustomObject]@{ id = "pm_13"; label = "2"; delta = 2; value = 2; amount = 2; weight = 15; chance = 10; color = "#f59e0b"; rarity = "Normal"; unitIcon = "images/numbers/num_pos_2.svg"; actionType = "score" }
)

$pmSpinner = [PSCustomObject]@{
    id = "spinner_plusminus"
    groupId = 4
    name = "Spinner"
    duration = 6000
    ticks = 100
    giftName = "Rose"
    giftId = "5655"
    giftIcon = "images/tiktok-gifts/5655_rose.webp"
    coins = 1
    audience = "Anyone"
    enabled = $true
    mode = "reel"
    style = "neon"
    type = "win_score"
    pointerIcon = "images/game-icons/pvz/spawn_ultimatecattail.webp"
    slices = $pmSlices
}

# Win Widget default config
$winWidgetCfg = [PSCustomObject]@{
    enabled = $true
    score = -4
    target = 5
    wins = 472
    losses = 6724
    autoWin = $true
    hotkeysEnabled = $true
    label = "Win"
}

$cfg | Add-Member -NotePropertyName "winWidget" -NotePropertyValue $winWidgetCfg -Force

$existingSpinners = @()
if ($cfg.spinners) {
    foreach ($s in $cfg.spinners) {
        if ($s.id -ne "spinner_plusminus") {
            $existingSpinners += $s
        }
    }
}
# Put +- Number Spinner at front (or matching GroupId 4)
$updatedSpinners = @($pmSpinner) + $existingSpinners
$cfg | Add-Member -NotePropertyName "spinners" -NotePropertyValue $updatedSpinners -Force
$cfg.spinner = $pmSpinner

$json = $cfg | ConvertTo-Json -Depth 8
[System.IO.File]::WriteAllText($cfgPath, $json, [System.Text.Encoding]::UTF8)

# Also write win_widget_state.json
$winStatePath = "c:\Users\pc\Downloads\ano na\core\win_widget_state.json"
[System.IO.File]::WriteAllText($winStatePath, ($winWidgetCfg | ConvertTo-Json -Depth 5), [System.Text.Encoding]::UTF8)

Write-Host "Successfully initialized +- Number Spinner (GroupId 4) and Win Widget!"
