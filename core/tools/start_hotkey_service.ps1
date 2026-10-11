$exe = "C:\Users\pc\Downloads\ano na\core\tools\GlobalHotkeyService.exe"
if (Test-Path $exe) {
    Start-Process -FilePath $exe -WindowStyle Hidden
    Start-Sleep -Milliseconds 600
    $p = Get-Process -Name 'GlobalHotkeyService' -ErrorAction SilentlyContinue
    if ($p) {
        Write-Host "GlobalHotkeyService is RUNNING on PID $($p.Id)!"
    } else {
        Write-Host "GlobalHotkeyService failed to start."
    }
} else {
    Write-Host "Executable not found at $exe"
}
