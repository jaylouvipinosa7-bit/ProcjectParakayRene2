$WshShell = New-Object -ComObject WScript.Shell
$desktop = [System.Environment]::GetFolderPath('Desktop')
$shortcutPath = Join-Path $desktop "PvZ Fusion Studio.lnk"

$currentDir = $PSScriptRoot
$exePath = Join-Path $currentDir "PvZ_Fusion_Studio.exe"
$iconPath = Join-Path $currentDir "app_icon.ico"

$shortcut = $WshShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $exePath
$shortcut.WorkingDirectory = $currentDir
$shortcut.Description = "PvZ Fusion 4.0 - Interactive Live Stream Studio"
$shortcut.IconLocation = "$iconPath, 0"
$shortcut.Save()

Write-Host "Created Desktop Shortcut: $shortcutPath"
