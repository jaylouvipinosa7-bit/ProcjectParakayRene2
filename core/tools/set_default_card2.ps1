$enc = New-Object System.Text.UTF8Encoding($false)
$files = @("core/pvz_fusion_config.json", "pvz_fusion_config.json")
if (Test-Path "core/user_configs") {
    $files += (Get-ChildItem "core/user_configs/*_config.json" | Select-Object -ExpandProperty FullName)
}

foreach ($f in $files) {
    if (Test-Path $f) {
        $json = Get-Content $f -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($json -and $json.gifts) {
            $g2 = $json.gifts | Where-Object { [string]$_.id -eq "2" -or ($_.giftName -and $_.giftName -match "team\s*zombies\s*likes") }
            if ($g2) {
                $g2.command = "spawn_knight_captain"
                $g2.label = "Spawn Knight Captain Zombie (70)"
                $g2.functionName = "Spawn Knight Captain Zombie (70)"
                $g2.unitIcon = "images/game-icons/pvz/spawn_knight_captain.webp"
                $g2.actionType = "zombie"
                if ($g2.PSObject.Properties["funcImg"]) { $g2.funcImg = "images/game-icons/pvz/spawn_knight_captain.webp" }
                if ($g2.PSObject.Properties["funcName"]) { $g2.funcName = "Spawn Knight Captain Zombie (70)" }
                if ($g2.commands -and $g2.commands.Count -gt 0) {
                    $g2.commands[0].command = "spawn_knight_captain"
                    $g2.commands[0].label = "Spawn Knight Captain Zombie (70)"
                    $g2.commands[0].icon = "images/game-icons/pvz/spawn_knight_captain.webp"
                    $g2.commands[0].actionType = "zombie"
                }
                if ($json.PSObject.Properties["socialTriggers"] -and $json.socialTriggers.likes) {
                    $likes = $json.socialTriggers.likes
                    if ($likes.PSObject.Properties["command"]) { $likes.command = "spawn_knight_captain" } else { $likes | Add-Member -MemberType NoteProperty -Name command -Value "spawn_knight_captain" -Force }
                    if ($likes.PSObject.Properties["label"]) { $likes.label = "Spawn Knight Captain Zombie (70)" } else { $likes | Add-Member -MemberType NoteProperty -Name label -Value "Spawn Knight Captain Zombie (70)" -Force }
                    if ($likes.PSObject.Properties["unitIcon"]) { $likes.unitIcon = "images/game-icons/pvz/spawn_knight_captain.webp" } else { $likes | Add-Member -MemberType NoteProperty -Name unitIcon -Value "images/game-icons/pvz/spawn_knight_captain.webp" -Force }
                    if ($likes.PSObject.Properties["actionType"]) { $likes.actionType = "zombie" } else { $likes | Add-Member -MemberType NoteProperty -Name actionType -Value "zombie" -Force }
                }
                $newJsonStr = ($json | ConvertTo-Json -Depth 30)
                [System.IO.File]::WriteAllText((Resolve-Path $f).Path, $newJsonStr, $enc)
                Write-Host "Updated $f card 2 to spawn_knight_captain"
            }
        }
    }
}

# Also update cards.json
if (Test-Path "core/cards.json") {
    $cList = Get-Content "core/cards.json" -Raw -Encoding UTF8 | ConvertFrom-Json
    $c2 = $cList | Where-Object { [string]$_.id -eq "2" }
    if ($c2) {
        $c2.funcName = "Spawn Knight Captain Zombie (70)"
        $c2.funcImg = "images/game-icons/pvz/spawn_knight_captain.webp"
        $c2.commands = "spawn_knight_captain"
        $c2.actionType = "zombie"
        [System.IO.File]::WriteAllText((Resolve-Path "core/cards.json").Path, ($cList | ConvertTo-Json -Depth 30), $enc)
        Write-Host "Updated core/cards.json card 2"
    }
}
