param()
$g = "user_configs\tiktok_gohanmalunggay_tiktok.live_config.json"
if (Test-Path $g) {
    $cfg = Get-Content $g -Raw -Encoding UTF8 | ConvertFrom-Json
    Write-Output "=== GOHANMALUNGGAY SPINNERS ==="
    $cfg.spinners | Select-Object id, name, enabled, giftName, giftId, coins | Format-Table -AutoSize
}
$c = "pvz_fusion_config.json"
if (Test-Path $c) {
    $cfg = Get-Content $c -Raw -Encoding UTF8 | ConvertFrom-Json
    Write-Output "=== PVZ_FUSION_CONFIG SPINNERS ==="
    $cfg.spinners | Select-Object id, name, enabled, giftName, giftId, coins | Format-Table -AutoSize
}
