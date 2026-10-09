# Fix missing icons in the catalog
$catalogPath = "c:\Users\pc\Downloads\ano na\pvz_units_catalog.json"
$raw = Get-Content $catalogPath -Raw | ConvertFrom-Json
$c = $raw.all

# Map of missing IDs to correct icon files
$iconFixes = @{
    "spawn_gold_zomboss"             = "images/game-icons/pvz/spawn_zombie_gold_zomboss.webp"
    "dolphin_rider"                  = "images/game-icons/pvz/spawn_dolphinrider.webp"
    "spawn_drownpult"                = "images/game-icons/pvz/spawn_drownpult_a.webp"
    "drownpult"                      = "images/game-icons/pvz/spawn_drownpult_a.webp"
    "golden_zomboss"                 = "images/game-icons/pvz/spawn_zombie_golden_zomboss.webp"
    "drown"                          = "images/game-icons/pvz/spawn_drown_a.webp"
    "footballdrown"                  = "images/game-icons/pvz/spawn_football_drown.webp"
    "spawn_golden_zomboss"           = "images/game-icons/pvz/spawn_zombie_golden_zomboss.webp"
    "spawn_zombie_drown_gargantuar"  = "images/game-icons/pvz/spawn_drowngargantuar.webp"
    "dr_zomboss"                     = "images/game-icons/pvz/spawn_zombie_dr_zomboss.webp"
    "spawn_zomboss"                  = "images/game-icons/pvz/spawn_zombie_dr_zomboss.webp"
    "spawn_zombie_drown"             = "images/game-icons/pvz/spawn_drown_zombie.webp"
    "spawn_dr_zomboss"               = "images/game-icons/pvz/spawn_zombie_dr_zomboss.webp"
    "drownpultzombie"                = "images/game-icons/pvz/spawn_drownpult_zombie.webp"
    "duck_zombie"                    = "images/game-icons/pvz/spawn_zombie_duck.webp"
    "spawn_drown"                    = "images/game-icons/pvz/spawn_drown_a.webp"
    "snowdrownzombie"                = "images/game-icons/pvz/spawn_snow_drown_zombie.webp"
    "submarine"                      = "images/game-icons/pvz/spawn_submarine_a.webp"
    "ultimatefootballdrown"          = "images/game-icons/pvz/spawn_ultimate_football_drown.webp"
    "drown_gargantuar"               = "images/game-icons/pvz/spawn_drowngargantuar.webp"
    "zomboss"                        = "images/game-icons/pvz/spawn_zombie_dr_zomboss.webp"
}

$fixCount = 0
for ($i = 0; $i -lt $c.Count; $i++) {
    $id = $c[$i].id
    if ($iconFixes.ContainsKey($id)) {
        $oldIcon = $c[$i].icon
        $newIcon = $iconFixes[$id]
        $c[$i].icon = $newIcon
        $c[$i].img = $newIcon
        $fixCount++
        Write-Host "Fixed: $id -> $newIcon (was: $oldIcon)"
    }
}

$raw.all = $c
$raw | ConvertTo-Json -Depth 10 | Set-Content $catalogPath -Encoding UTF8
Write-Host "`nFixed $fixCount icons. Catalog saved."

# Verify no more missing
$stillMissing = 0
$c | ForEach-Object {
    $iconPath = Join-Path "c:\Users\pc\Downloads\ano na" $_.icon
    if (-not (Test-Path $iconPath)) {
        $stillMissing++
        Write-Host "STILL MISSING: $($_.id) -> $($_.icon)"
    }
}
Write-Host "Remaining missing icons: $stillMissing"
