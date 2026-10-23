$soundsDir = "c:\Users\pc\Downloads\ano na\core\sounds"

$placeholdersToFix = @{
    "apple_pay.mp3" = "https://www.myinstants.com/media/sounds/applepay.mp3"
    "a-few-moments-later-sponge-bob-sfx-fun.mp3" = "https://www.myinstants.com/media/sounds/a-few-moments-later-sponge-bob-sfx-fun.mp3"
    "angel-choirrr.mp3" = "https://www.myinstants.com/media/sounds/angel-choirrr.mp3"
    "arrow-effect.mp3" = "https://www.myinstants.com/media/sounds/arrow-effect.mp3"
}

foreach ($name in $placeholdersToFix.Keys) {
    $url = $placeholdersToFix[$name]
    $dest = Join-Path $soundsDir $name
    try {
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "Mozilla/5.0")
        $wc.DownloadFile($url, $dest)
        Write-Host "Downloaded real sound for: $name (Size: $((Get-Item $dest).Length) bytes)"
    } catch {
        Write-Host "Download failed for $name : $($_.Exception.Message)"
    }
}
