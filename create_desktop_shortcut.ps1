$WshShell = New-Object -ComObject WScript.Shell
$desktop = [System.Environment]::GetFolderPath('Desktop')
$shortcutPath = Join-Path $desktop "RENEarn - PvZ Fusion Studio.lnk"

$currentDir = $PSScriptRoot
$exePath = if (Test-Path (Join-Path $currentDir "RENEarn_Studio.exe")) { 
    Join-Path $currentDir "RENEarn_Studio.exe" 
} elseif (Test-Path (Join-Path $currentDir "Apps\RENEarn_Studio.exe")) {
    Join-Path $currentDir "Apps\RENEarn_Studio.exe"
} elseif (Test-Path (Join-Path $currentDir "..\Apps\RENEarn_Studio.exe")) {
    Join-Path $currentDir "..\Apps\RENEarn_Studio.exe"
} else { 
    Join-Path $currentDir "Launch_Studio.bat" 
}

$iconPath = if (Test-Path (Join-Path $currentDir "renearn.ico")) { 
    Join-Path $currentDir "renearn.ico" 
} elseif (Test-Path (Join-Path $currentDir "Assets\renearn.ico")) {
    Join-Path $currentDir "Assets\renearn.ico"
} elseif (Test-Path (Join-Path $currentDir "..\Assets\renearn.ico")) {
    Join-Path $currentDir "..\Assets\renearn.ico"
} else { 
    Join-Path $currentDir "app_icon.ico" 
}

$shortcut = $WshShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $exePath
$shortcut.WorkingDirectory = Split-Path -Parent $exePath
$shortcut.Description = "RENEarn - Interactive Live Stream Studio & PvZ Fusion Mod Controller"
$shortcut.IconLocation = "$iconPath, 0"
$shortcut.Save()

Write-Host "Created Desktop Shortcut: $shortcutPath"
