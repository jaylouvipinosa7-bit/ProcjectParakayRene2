$cmdMap = Get-Content "c:\Users\pc\Downloads\ano na\runetify_all_commands_map.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$labelMap = Get-Content "c:\Users\pc\Downloads\ano na\runetify_unit_labels.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$giftsJson = Get-Content "c:\Users\pc\Downloads\ano na\tiktok_gifts_verified.json" -Raw -Encoding UTF8
$iconFolder = "c:\Users\pc\Downloads\ano na\images\game-icons\pvz"

$plants = [System.Collections.ArrayList]::new()
$zombies = [System.Collections.ArrayList]::new()
$powers = [System.Collections.ArrayList]::new()

foreach ($prop in $cmdMap.PSObject.Properties) {
    $cmd = $prop.Name
    $info = $prop.Value
    $endpoint = $info.endpoint
    $effect = $info.effect

    # Check if icon exists
    $iconPath = "images/game-icons/pvz/$cmd.webp"
    $fullIcon = Join-Path $iconFolder "$cmd.webp"
    if (-not (Test-Path $fullIcon)) {
        if ($cmd -match '^spawn_(.+)$' -and (Test-Path (Join-Path $iconFolder "$($matches[1]).webp"))) {
            $iconPath = "images/game-icons/pvz/$($matches[1]).webp"
        } elseif (Test-Path (Join-Path $iconFolder "spawn_$cmd.webp")) {
            $iconPath = "images/game-icons/pvz/spawn_$cmd.webp"
        } else {
            $iconPath = if ($endpoint -eq '/spawnplant') { "images/catmower.png" } elseif ($endpoint -eq '/spawnzombie') { "images/func_2.png" } else { "images/func_15.png" }
        }
    }

    # Label
    $label = if ($labelMap.$cmd) { $labelMap.$cmd } else {
        $clean = $cmd -replace '^spawn_', '' -replace '_', ' '
        (Get-Culture).TextInfo.ToTitleCase($clean)
    }

    $entry = [PSCustomObject]@{
        id       = $cmd
        name     = $label
        command  = $cmd
        endpoint = $endpoint
        effect   = $effect
        img      = $iconPath
    }

    if ($endpoint -eq '/spawnplant') {
        $entry | Add-Member -NotePropertyName "type" -NotePropertyValue "Fusion Plant"
        $plants.Add($entry) | Out-Null
    } elseif ($endpoint -eq '/spawnzombie') {
        $entry | Add-Member -NotePropertyName "type" -NotePropertyValue "Fusion Zombie"
        $zombies.Add($entry) | Out-Null
    } else {
        $entry | Add-Member -NotePropertyName "type" -NotePropertyValue "Cheat / World Power"
        $powers.Add($entry) | Out-Null
    }
}

Write-Output "Plants: $($plants.Count), Zombies: $($zombies.Count), Powers: $($powers.Count)"

$plantsJson = $plants | ConvertTo-Json -Depth 4
$zombiesJson = $zombies | ConvertTo-Json -Depth 4
$powersJson = $powers | ConvertTo-Json -Depth 4

$finalJson = "{`"plants`":" + $plantsJson + ",`"zombies`":" + $zombiesJson + ",`"powers`":" + $powersJson + ",`"tiktokGifts`":" + $giftsJson + "}"
[System.IO.File]::WriteAllText("c:\Users\pc\Downloads\ano na\pvz_units_catalog.json", $finalJson, [System.Text.Encoding]::UTF8)

Write-Output "Successfully built pvz_units_catalog.json with pure arrays!"
