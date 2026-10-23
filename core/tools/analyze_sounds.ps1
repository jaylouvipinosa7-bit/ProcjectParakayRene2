$catalogPath = "c:\Users\pc\Downloads\ano na\core\sounds_catalog.json"
$catalog = Get-Content -Raw $catalogPath | ConvertFrom-Json

Write-Host "Total catalog entries: $($catalog.Count)"

# Check duplicate file hashes or sizes or normalized names
$soundsDir = "c:\Users\pc\Downloads\ano na\core\sounds"

# Use Shell.Application to extract exact media duration from Windows shell
$shell = New-Object -ComObject Shell.Application
$folder = $shell.Namespace($soundsDir)

# Find duration column index (usually index 27 in Windows Shell)
$durationIndex = -1
for ($i = 0; $i -lt 100; $i++) {
    $header = $folder.GetDetailsOf($null, $i)
    if ($header -eq "Length" -or $header -eq "Duration") {
        $durationIndex = $i
        break
    }
}
Write-Host "Windows Shell Duration column index: $durationIndex"

# Sample reading duration
$sampleFile = Get-ChildItem $soundsDir -Filter "*.mp3" | Select-Object -First 5
foreach ($f in $sampleFile) {
    $item = $folder.ParseName($f.Name)
    $len = $folder.GetDetailsOf($item, $durationIndex)
    Write-Host "$($f.Name) => Length: '$len'"
}
