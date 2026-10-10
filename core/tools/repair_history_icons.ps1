$file = "c:\Users\pc\Downloads\ano na\core\spinner_history.json"
if (Test-Path $file) {
    $h = Get-Content $file -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($item in $h.history) {
        if ($item.icon -eq 'True' -or $item.icon -eq 'true' -or -not $item.icon) {
            if ($item.isNumber) {
                $item.icon = "images/numbers/num_pos_10.svg"
            } elseif ($item.label -match "Corn") {
                $item.icon = "images/game-icons/pvz/spawn_ultimate_corn.webp"
            } elseif ($item.label -match "Kirov") {
                $item.icon = "images/game-icons/pvz/spawn_kirov_c.webp"
            } elseif ($item.label -match "Charm") {
                $item.icon = "images/game-icons/pvz/charm_all_zombies.webp"
            } elseif ($item.label -match "Lawnmower") {
                $item.icon = "images/game-icons/pvz/lawnmower.webp"
            } elseif ($item.label -match "Nut") {
                $item.icon = "images/game-icons/pvz/spawn_bedrocktallnut.webp"
            } elseif ($item.label -match "Threepeater") {
                $item.icon = "images/game-icons/pvz/spawn_superthreepeater_sp.webp"
            } else {
                $item.icon = "images/func_2.png"
            }
        }
    }
    $h | ConvertTo-Json -Depth 6 | Set-Content $file -Encoding UTF8
    Write-Host "Repaired history icons successfully!"
}
