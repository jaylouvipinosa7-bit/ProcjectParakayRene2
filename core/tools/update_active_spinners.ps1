param()
$files = @("pvz_fusion_config.json", "user_configs\tiktok_gohanmalunggay_tiktok.live_config.json")
foreach ($f in $files) {
    if (Test-Path $f) {
        $cfg = Get-Content $f -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($sp in $cfg.spinners) {
            if ($sp.id -eq "spinner_1") {
                $sp.giftId = "5658"
                $sp.giftIcon = "images/tiktok-gifts/5658_perfume.webp"
            } elseif ($sp.id -eq "spinner_plusminus") {
                $sp.giftName = "Heart Me"
                $sp.giftId = "7934"
                $sp.giftIcon = "images/tiktok-gifts/7934_heart_me.webp"
                $sp.coins = 1
            }
        }
        $json = $cfg | ConvertTo-Json -Depth 32
        [System.IO.File]::WriteAllText((Resolve-Path $f).Path, $json, [System.Text.Encoding]::UTF8)
        Write-Output "Updated $f"
    }
}
