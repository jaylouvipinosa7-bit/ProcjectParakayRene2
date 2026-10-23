$coreDir = Split-Path $PSScriptRoot -Parent
$procs = Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -and $_.CommandLine.Contains("server.ps1") -and $_.ProcessId -ne $PID }
foreach ($p in $procs) {
    Write-Host "Stopping old server PID $($p.ProcessId)..."
    Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 1
Write-Host "Starting new server.ps1 in background..."
Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File ""$coreDir\server.ps1""" -WorkingDirectory $coreDir -WindowStyle Hidden
Start-Sleep -Seconds 2
Write-Host "Server restarted."

