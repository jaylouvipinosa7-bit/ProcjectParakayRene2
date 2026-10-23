$f = "c:\Users\pc\Downloads\ano na\core\s2e_presets.json"
$p = Get-Content $f -Raw -Encoding UTF8 | ConvertFrom-Json
$ev = $p.preset_pvz_custom.events | Where-Object { [string]$_.id -eq '2' }
if ($ev) {
    Write-Host "Updating event 2 in preset_pvz_custom..."
    $ev.command = "spawn_trident_juggernut_gargantuar"
    $ev.unitIcon = "images/game-icons/pvz/spawn_trident_juggernut_gargantuar.webp"
    $ev.label = "Spawn Trident Jugger-nut Gargantuar (240)"
    $ev.functionName = "Spawn Trident Jugger-nut Gargantuar (240)"
    if ($ev.commands -and $ev.commands.Count -gt 0) {
        $ev.commands[0].command = "spawn_trident_juggernut_gargantuar"
        $ev.commands[0].label = "Spawn Trident Jugger-nut Gargantuar (240)"
        $ev.commands[0].icon = "images/game-icons/pvz/spawn_trident_juggernut_gargantuar.webp"
    }
    [System.IO.File]::WriteAllText($f, ($p | ConvertTo-Json -Depth 15), [System.Text.Encoding]::UTF8)
    Write-Host "SUCCESS: s2e_presets.json updated!"
} else {
    Write-Host "Event 2 not found in preset_pvz_custom"
}
