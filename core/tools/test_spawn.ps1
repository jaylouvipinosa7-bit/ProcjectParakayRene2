$body1 = @{ command = 'spawn_submarine_c2'; count = 1; name = 'SubmarineC2Test' } | ConvertTo-Json
$res1 = Invoke-RestMethod -Uri 'http://localhost:8080/api/test' -Method Post -Body $body1 -ContentType 'application/json'
Write-Host "Submarine_c2 Test Response: $($res1 | ConvertTo-Json -Compress)"

$body2 = @{ command = 'spawn_ultimate_imp_king'; count = 1; name = 'ImpKingTest' } | ConvertTo-Json
$res2 = Invoke-RestMethod -Uri 'http://localhost:8080/api/test' -Method Post -Body $body2 -ContentType 'application/json'
Write-Host "Ultimate_Imp_King Test Response: $($res2 | ConvertTo-Json -Compress)"

