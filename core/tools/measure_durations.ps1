Add-Type -AssemblyName presentationCore

$soundsDir = "c:\Users\pc\Downloads\ano na\core\sounds"
$files = Get-ChildItem $soundsDir -Filter "*.mp3"

$durations = @{}
$shell = New-Object -ComObject Shell.Application
$folder = $shell.Namespace($soundsDir)

Write-Host "Measuring durations of $($files.Count) files..."
$count = 0
foreach ($f in $files) {
    $item = $folder.ParseName($f.Name)
    # Shell duration is HH:MM:SS
    $shellLen = $folder.GetDetailsOf($item, 27)
    
    # Parse shellLen: e.g. "00:00:04"
    if ($shellLen -match '(\d+):(\d+):(\d+)') {
        $h = [int]$matches[1]
        $m = [int]$matches[2]
        $s = [int]$matches[3]
        $totalSeconds = ($h * 3600) + ($m * 60) + $s
        
        # User wanted format: e.g. 00:03:00 for 3 seconds
        # That is: MM:SS:00 (Minutes : Seconds : 00 centiseconds)
        $minPart = "{0:D2}" -f $m
        $secPart = "{0:D2}" -f $s
        $formatted = "$minPart`:$secPart`:00"
        $durations[$f.Name] = $formatted
    } else {
        $durations[$f.Name] = "00:03:00"
    }
    $count++
}

Write-Host "Finished measuring $count files. Samples:"
$files | Select-Object -First 10 | ForEach-Object {
    Write-Host "$($_.Name) => $($durations[$_.Name])"
}
