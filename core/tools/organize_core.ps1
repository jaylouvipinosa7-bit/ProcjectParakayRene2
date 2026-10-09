# Script to organize all internal files into core/ folder
$root = $PSScriptRoot | Split-Path -Parent
$core = Join-Path $root "core"

if (-not (Test-Path $core)) {
    New-Item -ItemType Directory -Path $core -Force | Out-Null
}

# Stop old servers
Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -like '*server.ps1*' -or $_.CommandLine -like '*tiktok_bridge.js*'
} | ForEach-Object {
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
}

# Root whitelist: these stay in root
$keepInRoot = @(
    "PvZ_Fusion_Studio.exe",
    "Create_Desktop_Shortcut.bat",
    "create_desktop_shortcut.ps1",
    "Launch_Studio.bat",
    "DISTRIBUTION_GUIDE.md",
    "app_icon.ico",
    "core"
)

# Move directories to core
Get-ChildItem -Path $root -Directory | Where-Object {
    $_.Name -ne "core"
} | ForEach-Object {
    $dest = Join-Path $core $_.Name
    if (Test-Path $dest) {
        Remove-Item -Path $dest -Recurse -Force -ErrorAction SilentlyContinue
    }
    Move-Item -Path $_.FullName -Destination $core -Force
}

# Move files to core (except whitelist)
Get-ChildItem -Path $root -File | Where-Object {
    $keepInRoot -notcontains $_.Name
} | ForEach-Object {
    $dest = Join-Path $core $_.Name
    Move-Item -Path $_.FullName -Destination $core -Force
}

# Copy app_icon.ico and favicon.ico to core if not present
if (Test-Path (Join-Path $root "app_icon.ico")) {
    Copy-Item (Join-Path $root "app_icon.ico") (Join-Path $core "app_icon.ico") -Force
}

Write-Host "Organization complete! Files in root:"
Get-ChildItem -Path $root | Select-Object Name, PSIsContainer
