param()
$procs = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object { 
    $_.CommandLine -like "*server.ps1*" -and $_.ProcessId -ne $PID 
}
foreach ($p in $procs) {
    try {
        Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
        Write-Output "Stopped process $($p.ProcessId)"
    } catch {}
}

Start-Sleep -Seconds 1
$srv = Start-Process powershell.exe -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', 'server.ps1' -WorkingDirectory (Get-Location).Path -PassThru -WindowStyle Hidden
Write-Output "Started server with PID $($srv.Id)"
Start-Sleep -Seconds 2
$port = Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue
if ($port) {
    Write-Output "Port 8080 is actively listening!"
} else {
    Write-Output "Warning: Port 8080 not listening yet."
}
