Add-Type -AssemblyName presentationCore

$soundsDir = "c:\Users\pc\Downloads\ano na\core\sounds"
$files = Get-ChildItem $soundsDir -Filter "*anime*wow*"

foreach ($f in $files) {
    $player = New-Object System.Windows.Media.MediaPlayer
    $player.Open([System.Uri]$f.FullName)
    Start-Sleep -Milliseconds 300
    while (!$player.NaturalDuration.HasTimeSpan) {
        Start-Sleep -Milliseconds 50
    }
    $ts = $player.NaturalDuration.TimeSpan
    $player.Close()
    Write-Host "$($f.Name) => TotalSeconds: $($ts.TotalSeconds) | Minutes: $($ts.Minutes) | Seconds: $($ts.Seconds) | Millis: $($ts.Milliseconds)"
}
