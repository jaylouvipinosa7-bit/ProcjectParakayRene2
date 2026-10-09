$paths = @(
    "C:\Program Files\Git\cmd\git.exe",
    "C:\Program Files\Git\bin\git.exe",
    "C:\Program Files (x86)\Git\cmd\git.exe",
    "C:\Program Files (x86)\Git\bin\git.exe",
    "$env:LOCALAPPDATA\Programs\Git\cmd\git.exe",
    "$env:LOCALAPPDATA\Programs\Git\bin\git.exe",
    "$env:ProgramW6432\Git\cmd\git.exe"
)

foreach ($p in $paths) {
    if (Test-Path $p) {
        Write-Host "FOUND: $p"
        & $p --version
        exit 0
    }
}

# If not found in standard paths, check winget package location
$packagePath = Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Filter "git.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
if ($packagePath) {
    Write-Host "FOUND_WINGET: $packagePath"
    & $packagePath --version
    exit 0
}

Write-Host "NOT_FOUND"
