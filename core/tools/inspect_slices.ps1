$cfg = Get-Content -Raw pvz_fusion_config.json | ConvertFrom-Json
foreach ($sp in $cfg.spinners) {
    foreach ($s in $sp.slices) {
        if ($s.label -like '*Big Sniper*') {
            Write-Host "Spinner: $($sp.name)"
            Write-Host ($s | ConvertTo-Json -Depth 5)
        }
    }
}
