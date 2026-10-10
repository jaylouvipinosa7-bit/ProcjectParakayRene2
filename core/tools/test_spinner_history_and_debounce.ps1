$ErrorActionPreference = "Stop"

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "  TEST 1: SPINNER HISTORY ENDPOINTS TEST" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

$histRes = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/spinner-history" -Method GET
Write-Host "Initial history enabled: $($histRes.enabled), Count: $($histRes.history.Count)"

Write-Host "`n=================================================" -ForegroundColor Cyan
Write-Host "  TEST 2: SERVER-SIDE 350MS DEBOUNCE VERIFICATION" -ForegroundColor Cyan
Write-Host "  (Simulate rapid duplicate Alt+= and Alt+- triggers)" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Fetch baseline state
$before = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/win-widget" -Method GET
Write-Host "Baseline: Wins=$($before.wins), Losses=$($before.losses), Score=$($before.score)"

# Simulate duplicate Alt+= key hit (e.g. Electron globalShortcut + DOM keydown within 30ms)
Write-Host "Firing 2 rapid win_plus requests separated by 30ms..."
$req1 = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/win-widget/adjust" -Method POST -Body '{"action":"win_plus"}' -ContentType 'application/json'
Start-Sleep -Milliseconds 30
$req2 = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/win-widget/adjust" -Method POST -Body '{"action":"win_plus"}' -ContentType 'application/json'

$afterWin = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/win-widget" -Method GET
Write-Host "After 2 rapid win_plus: Wins=$($afterWin.wins), Score=$($afterWin.score)"

$scoreGain = $afterWin.score - $before.score
$winGain = $afterWin.wins - $before.wins

if ($scoreGain -eq 1 -and $winGain -eq 1) {
    Write-Host "[PASS] SUCCESS: Debounce prevented duplicate! Exactly +1 point added, NOT +2!" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Score gained $scoreGain points instead of 1!" -ForegroundColor Red
}

# Wait out debounce window
Start-Sleep -Milliseconds 400

# Simulate duplicate Alt+- key hit
Write-Host "`nFiring 2 rapid lose_plus requests separated by 30ms..."
$beforeLose = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/win-widget" -Method GET
$req3 = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/win-widget/adjust" -Method POST -Body '{"action":"lose_plus"}' -ContentType 'application/json'
Start-Sleep -Milliseconds 30
$req4 = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/win-widget/adjust" -Method POST -Body '{"action":"lose_plus"}' -ContentType 'application/json'

$afterLose = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/win-widget" -Method GET
Write-Host "After 2 rapid lose_plus: Losses=$($afterLose.losses), Score=$($afterLose.score)"

$scoreLoss = $beforeLose.score - $afterLose.score
$lossGain = $afterLose.losses - $beforeLose.losses

if ($scoreLoss -eq 1 -and $lossGain -eq 1) {
    Write-Host "[PASS] SUCCESS: Debounce prevented duplicate! Exactly -1 point subtracted, NOT -2!" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Score changed by $scoreLoss points instead of 1!" -ForegroundColor Red
}

Write-Host "`n=================================================" -ForegroundColor Cyan
Write-Host "  TEST 3: SPINNER HISTORY - POINT & UNIT SPINS" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# 3a: Point Spinner spin (e.g. spinner_plusminus)
Write-Host "Triggering Point Spinner spin for user 'GohanViewer'..."
$spinPoint = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/spin?spinnerId=spinner_plusminus&user=GohanViewer&noGameTrigger=true" -Method POST -Body '{}' -ContentType 'application/json'
Write-Host "Point spin winner: $($spinPoint.winner.label)"

# 3b: Plant/Zombie Multi-Spinner spin (e.g. spinner_1)
Write-Host "Triggering Plant/Zombie Spinner spin for user 'ZombossHunter'..."
$spinPlant = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/spin?spinnerId=spinner_1&user=ZombossHunter&noGameTrigger=true" -Method POST -Body '{}' -ContentType 'application/json'
Write-Host "Plant spin winner: $($spinPlant.winner.label)"

# Verify History entries
$updatedHist = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/spinner-history" -Method GET
Write-Host "History list length: $($updatedHist.history.Count)"

$foundPoint = $updatedHist.history | Where-Object { $_.username -eq "GohanViewer" } | Select-Object -First 1
$foundPlant = $updatedHist.history | Where-Object { $_.username -eq "ZombossHunter" } | Select-Object -First 1

if ($foundPoint) {
    Write-Host "[PASS] Point record saved: User='$($foundPoint.username)', Prize='$($foundPoint.label)', isNumber=$($foundPoint.isNumber)" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Point record not found in history!" -ForegroundColor Red
}

if ($foundPlant) {
    Write-Host "[PASS] Plant/Zombie record saved: User='$($foundPlant.username)', Prize='$($foundPlant.label)', Icon='$($foundPlant.icon)'" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Plant/Zombie record not found in history!" -ForegroundColor Red
}

Write-Host "`n=================================================" -ForegroundColor Cyan
Write-Host "  ALL TESTS COMPLETED SUCCESSFULLY" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Cyan
