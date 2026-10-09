$gifts = Get-Content 'tiktok_gifts_verified.json' -Raw | ConvertFrom-Json
$gifts | Where-Object { $_.coins -eq 20 -or $_.coins -eq 30 -or $_.name -match 'perfume|scent|doughnut|donut|box' } | Select-Object id, name, coins, icon
