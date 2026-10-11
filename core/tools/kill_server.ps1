$currentPid = $PID
$procs = Get-WmiObject Win32_Process -Filter "Name = 'powershell.exe'"
foreach ($p in $procs) {
    if ($p.ProcessId -ne $currentPid -and $p.CommandLine -match "core\\server\.ps1") {
        Write-Output "Stopping server PID $($p.ProcessId)..."
        Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
    }
}
Write-Output "Done cleaning server processes."
