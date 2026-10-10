param()
$c = Get-Content "user_configs\tiktok_gohanmalunggay_tiktok.live_config.json" -Raw -Encoding UTF8 | ConvertFrom-Json
Write-Output "=== gohanmalunggay SPINNERS ==="
if ($c.spinners) {
    $c.spinners | Select-Object id, name, enabled, giftName, giftId, triggerType | Format-Table -AutoSize
} else {
    Write-Output "NO SPINNERS!"
}

Write-Output "=== gohanmalunggay GIFTS WITH SPINNER ACTION ==="
$c.gifts | Where-Object { $_.actionType -eq "spinner" -or $_.command -match "spin" -or $_.giftName -match "Heart" } | Select-Object id, giftName, giftId, actionType, command, enabled | Format-Table -AutoSize
