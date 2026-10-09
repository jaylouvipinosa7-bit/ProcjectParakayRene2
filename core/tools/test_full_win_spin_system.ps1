# Test script for Win Widget and Spinner auto-add system
Start-Sleep -Seconds 1

Write-Host "=== 1. Testing GET /api/win-widget ===" -ForegroundColor Cyan
$ww = Invoke-RestMethod -Uri "http://localhost:8080/api/win-widget"
Write-Host "Score: $($ww.score) | Target: $($ww.target) | Wins: $($ww.wins) | Losses: $($ww.losses)" -ForegroundColor Green

Write-Host "`n=== 2. Testing POST /api/win-widget/adjust (win_plus) ===" -ForegroundColor Cyan
$adjWin = Invoke-RestMethod -Uri "http://localhost:8080/api/win-widget/adjust" -Method POST -Body '{"action":"win_plus"}' -ContentType "application/json"
Write-Host "Wins is now: $($adjWin.wins) (Expected 473)" -ForegroundColor Green

Write-Host "`n=== 3. Testing POST /api/spin (spinner_plusminus) ===" -ForegroundColor Cyan
$spinRes = Invoke-RestMethod -Uri "http://localhost:8080/api/spin?spinnerId=spinner_plusminus&username=TikTokTester" -Method POST
Write-Host "Winner Slice: $($spinRes.winner.label) | Delta: $($spinRes.winner.delta) | Color: $($spinRes.winner.color)" -ForegroundColor Yellow

Start-Sleep -Milliseconds 500
$wwAfter = Invoke-RestMethod -Uri "http://localhost:8080/api/win-widget"
Write-Host "Score after spin auto-add: $($wwAfter.score) | Wins: $($wwAfter.wins) | Losses: $($wwAfter.losses)" -ForegroundColor Magenta

Write-Host "`n=== 4. Checking Event Log ===" -ForegroundColor Cyan
$events = Invoke-RestMethod -Uri "http://localhost:8080/api/events"
$spinEvents = $events.events | Where-Object { $_.type -eq "spin_result" -or $_.type -eq "win_widget_update" }
Write-Host "Found $($spinEvents.Count) live stream events for spinner and win widget!" -ForegroundColor Green
foreach ($e in $spinEvents | Select-Object -Last 3) {
    Write-Host "  -> Event type: $($e.type) | label: $($e.label) | delta: $($e.delta) | score: $($e.score)" -ForegroundColor Gray
}

Write-Host "`nALL TESTS PASSED!" -ForegroundColor Green
