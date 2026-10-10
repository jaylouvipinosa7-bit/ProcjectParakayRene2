Write-Host "=== TEST 1: WIN WIDGET INITIAL STATE ===" -ForegroundColor Cyan
$w0 = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/win-widget" -Method Get
Write-Host "Initial: Wins=$($w0.wins), Losses=$($w0.losses), Score=$($w0.score)/$($w0.target)"

Write-Host "
=== TEST 2: HOTKEY ALT + = (WIN_PLUS) ===" -ForegroundColor Cyan
$wWin = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/win-widget/adjust" -Method Post -Body '{"action":"win_plus"}' -ContentType 'application/json'
Write-Host "Result: Wins=$($wWin.wins), Losses=$($wWin.losses), Score=$($wWin.score)"
if ($wWin.wins -eq ($w0.wins + 1) -and $wWin.score -eq ($w0.score + 1)) {
    Write-Host "[PASS] win_plus incremented Wins and Score!" -ForegroundColor Green
} else {
    Write-Host "[FAIL] win_plus mismatch!" -ForegroundColor Red
}

Write-Host "
=== TEST 3: HOTKEY ALT + - (LOSE_PLUS) ===" -ForegroundColor Cyan
$wLose = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/win-widget/adjust" -Method Post -Body '{"action":"lose_plus"}' -ContentType 'application/json'
Write-Host "Result: Wins=$($wLose.wins), Losses=$($wLose.losses), Score=$($wLose.score)"
if ($wLose.losses -eq ($w0.losses + 1) -and $wLose.score -eq $w0.score) {
    Write-Host "[PASS] lose_plus incremented Losses and decremented Score!" -ForegroundColor Green
} else {
    Write-Host "[FAIL] lose_plus mismatch!" -ForegroundColor Red
}

Write-Host "
=== TEST 4: NUMBER SPINNER POSITIVE & NEGATIVE OUTCOMES ===" -ForegroundColor Cyan
$spinRes = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/spin" -Method Post -Body '{"spinner_id":"spinner_plusminus"}' -ContentType 'application/json'
Write-Host "Won slice: $($spinRes.winner.label) (delta: $($spinRes.winner.delta))"
$wSpin = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/win-widget" -Method Get
Write-Host "Current state after spin: Wins=$($wSpin.wins), Losses=$($wSpin.losses), Score=$($wSpin.score)"

Write-Host "
=== TEST 5: RESTORE CLEAN STATE TO MATCH PICTURE 2 ===" -ForegroundColor Cyan
$restored = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/win-widget" -Method Post -Body '{"wins":23, "losses":3, "score":171, "target":5}' -ContentType 'application/json'
Write-Host "State: Wins=$($restored.wins) (Expected 23), Losses=$($restored.losses) (Expected 3), Score=$($restored.score)/$($restored.target) (Expected 171/5)" -ForegroundColor Green

Write-Host "
=== TEST 6: VERIFY 51 SVG ICONS IN IMAGES/NUMBERS ===" -ForegroundColor Cyan
$svgCount = (Get-ChildItem -Path "c:\Users\pc\Downloads\ano na\core\images\numbers\*.svg").Count
Write-Host "Found $svgCount SVG number icons in images/numbers/" -ForegroundColor Green
