$res = Invoke-RestMethod -Uri "http://localhost:8080/api/catalog" -Method Get
Write-Output "--- Items 91-120 (Screenshot 4) ---"
for ($i = 90; $i -lt 120; $i++) {
    Write-Output "[$($i+1)] $($res.all[$i].name) -> $($res.all[$i].img)"
}
Write-Output "--- Items 121-150 (Screenshot 5) ---"
for ($i = 120; $i -lt 150; $i++) {
    Write-Output "[$($i+1)] $($res.all[$i].name) -> $($res.all[$i].img)"
}
