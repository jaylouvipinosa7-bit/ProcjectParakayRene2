$cfg = Get-Content "pvz_fusion_config.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$missing = 0
foreach ($g in $cfg.gifts) {
    if ($g.unitIcon) {
        $img = $g.unitIcon -replace '/', '\'
        if (-not (Test-Path $img)) {
            Write-Output "Missing config gift icon: $($g.label) -> $($g.unitIcon)"
            $missing++
        }
    }
}
foreach ($s in $cfg.spinner.slices) {
    if ($s.unitIcon) {
        $img = $s.unitIcon -replace '/', '\'
        if (-not (Test-Path $img)) {
            Write-Output "Missing spinner slice icon: $($s.label) -> $($s.unitIcon)"
            $missing++
        }
    }
}
Write-Output "Config gifts & slices tested, Missing images: $missing"
