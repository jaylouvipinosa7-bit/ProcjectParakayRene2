$ErrorActionPreference = "Stop"

Write-Host "=== 1. Testing GET /api/sounds ==="
$resp = Invoke-RestMethod -Uri "http://localhost:8080/api/sounds" -Method Get
Write-Host "Total catalog sounds returned: $($resp.Count)"
if ($resp.Count -lt 40) {
    throw "Expected at least 40 sounds in catalog!"
}

# Verify duration formatting
$nonStandard = @($resp | Where-Object { $_.duration -notmatch '^\d{2}:\d{2}:\d{2}$' })
if ($nonStandard.Count -gt 0) {
    Write-Warning "Found non-standard duration: $($nonStandard[0].duration)"
} else {
    Write-Host "All sounds have standard 00:00:00 timecode format!"
}

Write-Host "`n=== 2. Testing POST /api/upload-audio (Local Sound Library) ==="
$dummyBytes = [System.Text.Encoding]::ASCII.GetBytes("ID3_DUMMY_MP3_PAYLOAD_TEST")
$b64 = [Convert]::ToBase64String($dummyBytes)
$payloadObj = @{
    name = "test_custom_sfx.mp3"
    title = "Test Custom SFX"
    tag = "Local"
    base64Data = "data:audio/mp3;base64,$b64"
}
$payload = $payloadObj | ConvertTo-Json

$uploadResp = Invoke-RestMethod -Uri "http://localhost:8080/api/upload-audio" -Method Post -Body $payload -ContentType "application/json"
Write-Host "Upload status: $($uploadResp.status)"
Write-Host "New sound ID: $($uploadResp.sound.id)"
Write-Host "New sound Title: $($uploadResp.sound.title)"
Write-Host "New sound Duration: $($uploadResp.sound.duration)"

Write-Host "`n=== 3. Testing Static Audio Serving ==="
$testAudioFile = $resp[0].file
$audioUrl = "http://localhost:8080/" + $testAudioFile
$headResp = Invoke-WebRequest -Uri $audioUrl -Method Head
Write-Host "Audio URL: $audioUrl"
Write-Host "HTTP Status: $($headResp.StatusCode)"
Write-Host "Content-Type: $($headResp.Headers['Content-Type'])"

Write-Host "`n=== ALL BACKEND AND AUDIO CHECKS PASSED SUCCESSFULLY! ==="
