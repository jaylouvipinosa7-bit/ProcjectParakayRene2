$w = Invoke-RestMethod 'http://localhost:8080/api/win-widget'
Write-Host "Initial: Score=$($w.score) Target=$($w.target) Style=$($w.style) Wins=$($w.wins) Losses=$($w.losses)" -ForegroundColor Cyan

# Test win_plus (Alt + = simulation)
$adj1 = Invoke-RestMethod 'http://localhost:8080/api/win-widget/adjust' -Method POST -Body '{"action":"win_plus"}' -ContentType 'application/json'
Write-Host "After Win+: Score=$($adj1.score) Wins=$($adj1.wins) (Expected Score = -2, Wins = 473)" -ForegroundColor Green

# Test lose_plus (Alt + - simulation)
$adj2 = Invoke-RestMethod 'http://localhost:8080/api/win-widget/adjust' -Method POST -Body '{"action":"lose_plus"}' -ContentType 'application/json'
Write-Host "After Lose+: Score=$($adj2.score) Losses=$($adj2.losses) (Expected Score = -3, Losses = 6725)" -ForegroundColor Yellow

# Test spin auto-add to trophy fraction
$spin = Invoke-RestMethod 'http://localhost:8080/api/spin?spinnerId=spinner_plusminus' -Method POST
Write-Host "Spin landed on: $($spin.winner.label) (Delta: $($spin.winner.delta))" -ForegroundColor Magenta

$wAfter = Invoke-RestMethod 'http://localhost:8080/api/win-widget'
Write-Host "Trophy Fraction Score after Spin: $($wAfter.score) / $($wAfter.target)" -ForegroundColor Green
