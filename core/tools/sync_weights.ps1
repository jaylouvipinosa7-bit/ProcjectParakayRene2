$coreDir = Resolve-Path (Join-Path $PSScriptRoot "..")

function Get-Weight($r) {
    switch (($r + '').ToLower()) {
        'mythic' { return 1 }
        'legendary' { return 2 }
        'epic' { return 6 }
        'rare' { return 12 }
        'uncommon' { return 25 }
        default { return 50 }
    }
}

$filesToProcess = @()
$filesToProcess += Get-ChildItem -Path "$coreDir\pvz_fusion_config.json" -ErrorAction SilentlyContinue
$filesToProcess += Get-ChildItem -Path "$coreDir\pvz_fusion_template.json" -ErrorAction SilentlyContinue
$filesToProcess += Get-ChildItem -Path "$coreDir\user_configs\*.json" -ErrorAction SilentlyContinue

$totalUpdatedFiles = 0

foreach ($f in $filesToProcess) {
    if ($f.Name -eq "users_registry.json") { continue }
    try {
        $content = Get-Content -Raw -Path $f.FullName -ErrorAction Stop
        $cfg = $content | ConvertFrom-Json
        $fileChanged = $false

        if ($cfg.spinners) {
            foreach ($sp in $cfg.spinners) {
                if ($sp.slices) {
                    foreach ($s in $sp.slices) {
                        $cw = Get-Weight $s.rarity
                        if ($s.weight -ne $cw) {
                            $s.weight = $cw
                            $fileChanged = $true
                        }
                    }
                }
            }
        }

        if ($fileChanged) {
            $newJson = $cfg | ConvertTo-Json -Depth 32
            Set-Content -Path $f.FullName -Value $newJson -Encoding UTF8
            Write-Host "Updated weights in: $($f.Name)"
            $totalUpdatedFiles++
        }
    } catch {
        Write-Warning "Could not parse or update $($f.Name): $_"
    }
}

Write-Host "Done. Total files updated: $totalUpdatedFiles"
