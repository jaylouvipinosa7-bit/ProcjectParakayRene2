Get-ChildItem 'images\tiktok-gifts' | Where-Object { $_.Name -match 'donut|doughnut|perfume|scent|scented|love' } | Select-Object Name, Length
