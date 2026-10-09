$allIcons = Get-ChildItem -Path "images/game-icons/pvz" -Filter "*.webp"
Write-Output "Total webp icons in images/game-icons/pvz: $($allIcons.Count)"

$sampleNames = @(
  'kill_all_plants', 'kill_all_zombies', 'double_demage', 'x100_demage', 'invulnerable_zombies', 'invulnerable_plants',
  'sun', 'set_sun', 'unlimited_sun', 'free_cooldown', 'seed_rain', 'win_level', 'spawn_fertilizer', 'spawn_bucket',
  'spawn_helmet', 'spawn_jack', 'spawn_pickaxe', 'spawn_sprout', 'spawn_mecha', 'spawn_meteor', 'charm_all_zombies',
  'spawn_peashooter', 'spawn_cherry_bomb', 'spawn_wall_nut', 'spawn_potato_mine', 'spawn_chomper', 'spawn_small_puff',
  'spawn_fume_shroom', 'spawn_hypno_shroom', 'spawn_scaredy_shroom', 'spawn_ice_shroom', 'spawn_doom_shroom',
  'spawn_lily_pad', 'spawn_squash', 'spawn_three_peater', 'spawn_jalapeno', 'spawn_caltrop', 'spawn_torch_wood',
  'spawn_sea_shroom', 'spawn_plantern', 'spawn_cactus', 'spawn_blover', 'spawn_star_fruit', 'spawn_pumpkin',
  'spawn_magnetshroom', 'spawn_cabbagepult', 'spawn_pot', 'spawn_cornpult', 'spawn_garlic', 'spawn_umbrellaleaf',
  'spawn_marigold', 'spawn_melonpult', 'spawn_shulkflower', 'spawn_electric_onion', 'spawn_ice_bean', 'spawn_endo_flame_girl',
  'spawn_hamburger', 'spawn_mix_bomb', 'spawn_imitater', 'spawn_squalour',
  'spawn_sword_star', 'spawn_present_zombie', 'spawn_big_sun_nut', 'spawn_cattail_girl', 'spawn_wheat', 'spawn_endo_flame',
  'spawn_big_wall_nut', 'spawn_present', 'spawn_hypno_emperor', 'spawn_ultimate_gatling', 'spawn_ultimate_torch',
  'spawn_ultimate_chomper', 'spawn_ultimate_fume', 'spawn_super_sun_nut', 'spawn_obsidian_spike', 'spawn_doom_gatling',
  'spawn_snow_gatling_puff', 'spawn_ultimate_star', 'spawn_ultimate_gloom', 'spawn_ultimate_pumpkin', 'spawn_ultimate_fly',
  'spawn_ultimate_tall_nut', 'spawn_ultimate_melon', 'spawn_ultimate_cannon', 'spawn_emerald_umbrella', 'spawn_hypno_queen',
  'spawn_ash_three_peater', 'spawn_super_three_peater', 'spawn_ultimate_blover', 'spawn_garlic_ultimate_chomper'
)

$found = 0
$missing = @()

foreach ($n in $sampleNames) {
    $exact = Join-Path "images/game-icons/pvz" "$n.webp"
    if (Test-Path $exact) {
        $found++
    } else {
        # Check without underscores or similar
        $clean = ($n -replace '_', '').ToLower()
        $m = $allIcons | Where-Object { ($_.BaseName -replace '_', '').ToLower() -eq $clean }
        if ($m) {
            $found++
            # Write-Output "Matched $n -> $($m[0].Name)"
        } else {
            $missing += $n
        }
    }
}

Write-Output "Found: $found / $($sampleNames.Count)"
if ($missing.Count -gt 0) {
    Write-Output "Missing: $($missing -join ', ')"
}
