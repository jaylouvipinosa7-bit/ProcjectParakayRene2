$ErrorActionPreference = "Stop"

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "  TESTING TESTER SPINNER HISTORY SYSTEM" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# 1. Test Points Spinner directly via /api/spin as Tester
Write-Host "`n[1] Testing Points Spinner as Tester via /api/spin..."
$res1 = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/spin?spinnerId=spinner_plusminus&username=Tester&noGameTrigger=true" -Method POST -Body '{}' -ContentType 'application/json'
Write-Host "Won: $($res1.winner.label) (isNumber: $(if ($res1.winner.delta -ne $null) { 'True' } else { 'False' }))"

# 2. Test Plant Spinner directly via /api/spin as Tester
Write-Host "`n[2] Testing Plant Spinner as Tester via /api/spin..."
$res2 = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/spin?spinnerId=spinner_1&username=Tester&noGameTrigger=true" -Method POST -Body '{}' -ContentType 'application/json'
Write-Host "Won: $($res2.winner.label) (Icon: $($res2.winner.unitIcon))"

# 3. Test Zombie Spinner directly via /api/spin as Tester
Write-Host "`n[3] Testing Zombie Spinner as Tester via /api/spin..."
$res3 = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/spin?spinnerId=spinner_2&username=Tester&noGameTrigger=true" -Method POST -Body '{}' -ContentType 'application/json'
Write-Host "Won: $($res3.winner.label) (Icon: $($res3.winner.unitIcon))"

# 4. Test Spinner trigger via /api/test (simulating Tab 1 Gift Card test)
Write-Host "`n[4] Testing Spinner trigger via /api/test as Tester..."
$res4 = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/test" -Method POST -Body '{"type":"gift","actionType":"spinner","spinnerId":"spinner_plusminus","label":"Heart Me","username":"Tester"}' -ContentType 'application/json'
Write-Host "Gift Test response: status=$($res4.status), event=$($res4.event.label)"

# 5. Verify Spinner History records
Write-Host "`n[5] Verifying /api/spinner-history..."
$hist = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/spinner-history" -Method GET
Write-Host "Total history records: $($hist.history.Count)"

$testerRecords = $hist.history | Where-Object { $_.username -eq "Tester" }
Write-Host "Found $($testerRecords.Count) records for 'Tester'!" -ForegroundColor Green

foreach ($rec in $testerRecords[0..3]) {
    Write-Host " -> [$($rec.timeStr)] User: $($rec.username) | Spinner: $($rec.spinnerName) | Prize: $($rec.label) | isNumber: $($rec.isNumber)" -ForegroundColor Yellow
}

if ($testerRecords.Count -ge 4) {
    Write-Host "`n[PASS] SUCCESS: Tester spins are fully recorded in Spinner History for both points and plant/zombie spinners!" -ForegroundColor Green
} else {
    Write-Host "`n[FAIL] Expected at least 4 tester records, got $($testerRecords.Count)" -ForegroundColor Red
}
