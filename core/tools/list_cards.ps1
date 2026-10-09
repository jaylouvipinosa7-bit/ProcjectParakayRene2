$cards = Get-Content "cards.json" -Raw | ConvertFrom-Json
Write-Host "Total cards in cards.json: $($cards.Count)"
$cards | Select-Object -First 20 | ForEach-Object {
    Write-Host "  $($_.id) | $($_.funcName) | $($_.commands) | $($_.funcImg)"
}
