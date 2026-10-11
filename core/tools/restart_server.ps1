$procs = Get-WmiObject Win32_Process -Filter "Name = 'powershell.exe'"
foreach ($p in $procs) {
    if ($p.CommandLine -like "*server.ps1*") {
        Write-Output "Found server.ps1 process: $($p.ProcessId)"
        Stop-Process -Id $p.ProcessId -Force
        Write-Output "Stopped PID $($p.ProcessId)"
    }
}
