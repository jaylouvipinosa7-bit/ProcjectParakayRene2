param()
$p = "pvz_fusion_template.json"
$t = Get-Content $p -Raw -Encoding UTF8 | ConvertFrom-Json

foreach ($sp in $t.spinners) {
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

$json = $t | ConvertTo-Json -Depth 32
[System.IO.File]::WriteAllText((Resolve-Path $p).Path, $json, [System.Text.Encoding]::UTF8)
Write-Output "Successfully updated pvz_fusion_template.json!"

# Also update teststreamer if exists
$ts = "user_configs\tiktok_teststreamer_tiktok.live_config.json"
if (Test-Path $ts) {
    $cfg = Get-Content $ts -Raw -Encoding UTF8 | ConvertFrom-Json
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
    $cfgJson = $cfg | ConvertTo-Json -Depth 32
    [System.IO.File]::WriteAllText((Resolve-Path $ts).Path, $cfgJson, [System.Text.Encoding]::UTF8)
    Write-Output "Successfully updated teststreamer config!"
}
