# Stop old instances holding file handles
Get-Process -Name 'RENEarn_Studio', 'PvZ_Fusion_Studio', 'GlobalHotkeyService' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 800

$csc = (Get-ChildItem -Path "C:\Windows\Microsoft.NET\Framework64" -Filter "csc.exe" -Recurse | Select-Object -Last 1).FullName
Write-Host "CSC Path: $csc"

if ($csc -and (Test-Path $csc)) {
    $src = "C:\Users\pc\Downloads\ano na\core\tools\AppLauncher.cs"
    $out = "C:\Users\pc\Downloads\ano na\RENEarn_Studio.exe"
    $ico = "C:\Users\pc\Downloads\ano na\renearn.ico"
    
    & $csc /target:winexe /win32icon:"$ico" /out:"$out" "$src" /r:System.Windows.Forms.dll /r:System.Drawing.dll
    Write-Host "Compile exit code: $LASTEXITCODE"
    if (Test-Path $out) {
        Write-Host "RENEarn_Studio.exe successfully compiled with Groudon icon! Size: $((Get-Item $out).Length)"
        Copy-Item -Path $out -Destination "C:\Users\pc\Downloads\ano na\PvZ_Fusion_Studio.exe" -Force
        if (Test-Path "C:\Users\pc\Downloads\ano na\Apps") {
            Copy-Item -Path $out -Destination "C:\Users\pc\Downloads\ano na\Apps\RENEarn_Studio.exe" -Force
        }
        Write-Host "Updated PvZ_Fusion_Studio.exe and Apps\RENEarn_Studio.exe as well."
    }

    # Also compile standalone GlobalHotkeyService.exe
    $svcSrc = "C:\Users\pc\Downloads\ano na\core\tools\GlobalHotkeyService.cs"
    $svcOut = "C:\Users\pc\Downloads\ano na\core\tools\GlobalHotkeyService.exe"
    & $csc /target:exe /win32icon:"$ico" /out:"$svcOut" "$svcSrc" /r:System.Windows.Forms.dll /r:System.Drawing.dll
    if (Test-Path $svcOut) {
        Write-Host "GlobalHotkeyService.exe successfully compiled! Size: $((Get-Item $svcOut).Length)"
    }
}
