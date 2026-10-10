param()
$t = Get-Content "pvz_fusion_template.json" -Raw -Encoding UTF8 | ConvertFrom-Json
Write-Output "SPINNERS IN TEMPLATE:"
$t.spinners | Select-Object id, name, enabled, giftName, giftId, coins | Format-Table -AutoSize
