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
$coreDir = "c:\Users\pc\Downloads\ano na\core"
$srv = Start-Process powershell.exe -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $coreDir 'server.ps1') -WorkingDirectory $coreDir -PassThru -WindowStyle Hidden
Write-Output "Started server with PID $($srv.Id)"
Start-Sleep -Seconds 2
$port = Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue
if ($port) {
    Write-Output "Port 8080 is actively listening!"
} else {
    Write-Output "Warning: Port 8080 not listening yet."
}
