$cfg = Get-Content 'pvz_fusion_config.json' -Raw -Encoding UTF8 | ConvertFrom-Json
$cfg.gifts | Select-Object id, giftName, giftId, coins, command, label | Format-Table -AutoSize | Out-String | Write-Host
