$conn = Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue
if ($conn) {
    Write-Host "Port 8080 is ACTIVE on PID $($conn.OwningProcess)"
    try {
        $res = Invoke-RestMethod -Uri "http://localhost:8080/api/status" -TimeoutSec 3
        Write-Host "API Status: $($res.status) | GameOnline: $($res.gameOnline)"
    } catch {
        Write-Host "HTTP request error: $_"
    }
} else {
    Write-Host "Port 8080 is not listening. Starting server.ps1..."
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSScriptRoot\..\server.ps1`"" -WindowStyle Hidden
    Start-Sleep -Seconds 2
    $conn2 = Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue
    if ($conn2) {
        Write-Host "Server successfully started on PID $($conn2.OwningProcess)!"
    } else {
        Write-Host "Could not start server. Please check server.ps1."
    }
}
