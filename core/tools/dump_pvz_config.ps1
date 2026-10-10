param()
$c = Get-Content "pvz_fusion_config.json" -Raw -Encoding UTF8 | ConvertFrom-Json
Write-Output "SPINNERS IN pvz_fusion_config.json:"
$c.spinners | Select-Object id, name, enabled, giftName, giftId | Format-Table -AutoSize
Write-Output "GIFTS IN pvz_fusion_config.json matching Heart:"
$c.gifts | Where-Object { $_.giftName -match "Heart" } | Select-Object id, giftName, giftId, actionType, command, enabled | Format-Table -AutoSize
