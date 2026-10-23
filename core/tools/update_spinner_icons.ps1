$targetFiles = @(
    "c:\Users\pc\Downloads\ano na\core\pvz_fusion_config.json",
    "c:\Users\pc\Downloads\ano na\core\pvz_fusion_template.json",
    "c:\Users\pc\Downloads\ano na\core\cards.json"
) + (Get-ChildItem -Path "c:\Users\pc\Downloads\ano na\core\user_configs" -Filter "*.json").FullName

foreach ($f in $targetFiles) {
    if (-not (Test-Path $f)) { continue }
    try {
        $raw = Get-Content -Encoding UTF8 $f -Raw | ConvertFrom-Json
        $changed = $false
        if ($raw.gifts) {
            foreach ($g in $raw.gifts) {
                if ($g.label -eq "Spin Plants Lucky Wheel" -or $g.command -eq "spinner_1" -or [string]$g.id -eq "33") {
                    $g.unitIcon = "images/spinner_plants_3d.webp"
                    $changed = $true
                }
                if ($g.label -eq "Spin Zombies Lucky Wheel" -or $g.command -eq "spinner_2" -or [string]$g.id -eq "34") {
                    $g.unitIcon = "images/spinner_zombies_3d.webp"
                    $changed = $true
                }
            }
        }
        if ($changed) {
            $json = $raw | ConvertTo-Json -Depth 10
            [System.IO.File]::WriteAllText($f, $json, [System.Text.Encoding]::UTF8)
            Write-Host "Updated $($f)"
        }
    } catch {
        Write-Warning "Could not update $($f): $_"
    }
}
