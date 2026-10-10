$ErrorActionPreference = "SilentlyContinue"

$targetProcesses = Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe' or Name = 'pwsh.exe'" | Where-Object {
    $_.CommandLine -match "server\.ps1"
}

if ($targetProcesses) {
    foreach ($p in $targetProcesses) {
        Write-Host "Stopping server process PID $($p.ProcessId)..."
        Stop-Process -Id $p.ProcessId -Force
    }
    Start-Sleep -Seconds 1
} else {
    Write-Host "No existing server.ps1 process found."
}

Write-Host "Starting fresh server.ps1..."
$newProc = Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSScriptRoot\..\server.ps1`"" -PassThru -WindowStyle Hidden
Write-Host "New server started with PID $($newProc.Id)."
Start-Sleep -Seconds 2

try {
    $status = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/status" -TimeoutSec 3
    Write-Host "Server status OK: $($status.status)"
} catch {
    Write-Host "Server starting up... ($($_.Exception.Message))"
}
