# Script to inject the +- Spinner and WinWidget config into pvz_fusion_config.json and user configs
$root = Split-Path -Parent $PSScriptRoot

$pmSpinner = @{
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
    pointerIcon = "images/numbers/num_pos_1.svg"
    slices = @(
        @{ id = "pm_1";  label = "1";    delta = 1;    actionType = "score"; rarity = "Normal";    weight = 18; chance = 18; color = "#f43f5e"; unitIcon = "images/numbers/num_pos_1.svg" },
        @{ id = "pm_2";  label = "5";    delta = 5;    actionType = "score"; rarity = "Rare";      weight = 12; chance = 12; color = "#a855f7"; unitIcon = "images/numbers/num_pos_5.svg" },
        @{ id = "pm_3";  label = "10";   delta = 10;   actionType = "score"; rarity = "Epic";      weight = 9;  chance = 9;  color = "#f43f5e"; unitIcon = "images/numbers/num_pos_10.svg" },
        @{ id = "pm_4";  label = "20";   delta = 20;   actionType = "score"; rarity = "Epic";      weight = 6;  chance = 6;  color = "#eab308"; unitIcon = "images/numbers/num_pos_20.svg" },
        @{ id = "pm_5";  label = "50";   delta = 50;   actionType = "score"; rarity = "Legendary"; weight = 3;  chance = 3;  color = "#22c55e"; unitIcon = "images/numbers/num_pos_50.svg" },
        @{ id = "pm_6";  label = "100";  delta = 100;  actionType = "score"; rarity = "Mythic";    weight = 2;  chance = 2;  color = "#ef4444"; unitIcon = "images/numbers/num_pos_100.svg" },
        @{ id = "pm_7";  label = "-1";   delta = -1;   actionType = "score"; rarity = "Normal";    weight = 18; chance = 18; color = "#f97316"; unitIcon = "images/numbers/num_neg_1.svg" },
        @{ id = "pm_8";  label = "-5";   delta = -5;   actionType = "score"; rarity = "Rare";      weight = 12; chance = 12; color = "#d946ef"; unitIcon = "images/numbers/num_neg_5.svg" },
        @{ id = "pm_9";  label = "-10";  delta = -10;  actionType = "score"; rarity = "Epic";      weight = 8;  chance = 8;  color = "#ef4444"; unitIcon = "images/numbers/num_neg_10.svg" },
        @{ id = "pm_10"; label = "-20";  delta = -20;  actionType = "score"; rarity = "Epic";      weight = 5;  chance = 5;  color = "#f59e0b"; unitIcon = "images/numbers/num_neg_20.svg" },
        @{ id = "pm_11"; label = "-50";  delta = -50;  actionType = "score"; rarity = "Legendary"; weight = 3;  chance = 3;  color = "#06b6d4"; unitIcon = "images/numbers/num_neg_50.svg" },
        @{ id = "pm_12"; label = "-100"; delta = -100; actionType = "score"; rarity = "Mythic";    weight = 2;  chance = 2;  color = "#ec4899"; unitIcon = "images/numbers/num_neg_100.svg" },
        @{ id = "pm_13"; label = "2";    delta = 2;    actionType = "score"; rarity = "Normal";    weight = 15; chance = 15; color = "#f59e0b"; unitIcon = "images/numbers/num_pos_2.svg" }
    )
}

$winWidgetCfg = @{
    enabled = $true
    score = -4
    target = 5
    wins = 472
    losses = 6724
    autoWin = $true
    hotkeysEnabled = $true
    label = "Win"
}

$configFiles = @(
    (Join-Path $root "pvz_fusion_config.json"),
    (Join-Path $root "pvz_fusion_template.json")
)

foreach ($f in $configFiles) {
    if (Test-Path $f) {
        try {
            $raw = Get-Content $f -Raw -Encoding UTF8
            $json = $raw | ConvertFrom-Json
            
            # 1. Update/Add winWidget
            $json | Add-Member -MemberType NoteProperty -Name "winWidget" -Value $winWidgetCfg -Force
            
            # 2. Update/Add spinner_plusminus to spinners array
            $spinnersList = @()
            if ($json.spinners) {
                foreach ($sp in $json.spinners) {
                    if ($sp.id -ne "spinner_plusminus") {
                        $spinnersList += $sp
                    }
                }
            }
            # Add +- spinner to list
            $spinnersList += $pmSpinner
            $json.spinners = $spinnersList

            $newJson = $json | ConvertTo-Json -Depth 8
            [System.IO.File]::WriteAllText($f, $newJson, [System.Text.Encoding]::UTF8)
            Write-Host "Successfully updated $f with spinner_plusminus (13 neon slices) and winWidget!" -ForegroundColor Green
        } catch {
            Write-Host "Error updating $f : $_" -ForegroundColor Red
        }
    }
}
