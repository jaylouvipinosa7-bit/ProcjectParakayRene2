$id = "6a7037f3324251772e699846"
Write-Host "Fetching latest preset from StreamToEarn ($id)..."
$url = "https://api.streamtoearn.io/apiserver/overlay/getpreset/$id"
$preset = Invoke-RestMethod -Uri $url -Method Get

$events = $preset.events | Where-Object {
    $_.active -eq $true -and
    !$_.function.hideEventInOverlay -and
    $_.trigger.action -ne "Custom" -and
    $_.function.image -ne $null -and
    $_.function.image -ne "" -and
    ($_.trigger.platformName -eq "TikTok" -or !$_.trigger.platformName)
}

$dir = Join-Path $PSScriptRoot "images"
if (!(Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

$wc = New-Object System.Net.WebClient
$wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")

# Download socket.io.min.js locally if missing
$socketPath = Join-Path $PSScriptRoot "socket.io.min.js"
if (!(Test-Path $socketPath)) {
    try {
        Write-Host "Downloading local socket.io.min.js..."
        $wc.DownloadFile("https://cdn.socket.io/4.7.5/socket.io.min.js", $socketPath)
        Write-Host "    OK!"
    } catch {
        Write-Host "    Socket.io download failed: $_"
    }
# Create trig_1.svg (Follow icon) and trig_7.svg (Likes circle) if missing
$trig1Path = Join-Path $dir "trig_1.svg"
if (!(Test-Path $trig1Path)) {
    $followSvg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100"><circle cx="36" cy="32" r="18" fill="#3ac956"/><path d="M 8 76 C 8 56 22 50 36 50 C 50 50 64 56 64 76 Z" fill="#3ac956"/><path d="M 78 36 L 78 56 M 68 46 L 88 46" stroke="#3ac956" stroke-width="8" stroke-linecap="round"/></svg>'
    [System.IO.File]::WriteAllText($trig1Path, $followSvg, [System.Text.Encoding]::UTF8)
}

$trig7Path = Join-Path $dir "trig_7.svg"
if (!(Test-Path $trig7Path)) {
    $likeSvg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100"><circle cx="50" cy="50" r="46" fill="#ff0000"/><text x="50" y="65" font-family="''Arial Black'', Impact, sans-serif" font-size="44" font-weight="900" fill="#ffffff" text-anchor="middle">50</text></svg>'
    [System.IO.File]::WriteAllText($trig7Path, $likeSvg, [System.Text.Encoding]::UTF8)
}

$cardList = @()
$i = 1
foreach ($ev in $events) {
    # 1. Download function image
    $fUrl = "https://streamtoearnprod1.s3.eu-central-1.amazonaws.com" + $ev.function.image
    $fPath = Join-Path $dir "func_$($i).png"
    Write-Host "[$i] Downloading plant/zombie image: $($ev.function.image)..."
    try {
        $wc.Headers.Set("Referer", "https://app.streamtoearn.io/")
        $wc.Headers.Set("Origin", "https://app.streamtoearn.io")
        $wc.DownloadFile($fUrl, $fPath)
        Write-Host "    OK!"
    } catch {
        Write-Host "    Func download error: $_"
    }

    # 2. Download trigger image
    $tUrl = ""
    $ext = ".webp"
    if ($ev.trigger.giftData -and $ev.trigger.giftData.image.url_list) {
        $tUrl = $ev.trigger.giftData.image.url_list[0]
        if ($tUrl -match '\.png') { $ext = ".png" }
        elseif ($tUrl -match '\.svg') { $ext = ".svg" }
        elseif ($tUrl -match '\.webp') { $ext = ".webp" }
        $tRelPath = "images/trig_$($i)$ext"
    } elseif ($ev.trigger.action -eq "Follow") {
        $tRelPath = "images/trig_1.svg"
    } elseif ($ev.trigger.action -eq "LikeForEach" -or $ev.trigger.action -eq "LikeAmount" -or $ev.trigger.action -eq "Like") {
        $tRelPath = "images/trig_7.svg"
    } else {
        $tRelPath = "images/trig_$($i).svg"
    }
    
    if ($tUrl) {
        $tPath = Join-Path $dir "trig_$($i)$ext"
        Write-Host "[$i] Downloading trigger gift image: $tUrl..."
        try {
            $wc.Headers.Remove("Referer")
            $wc.Headers.Remove("Origin")
            $wc.DownloadFile($tUrl, $tPath)
            Write-Host "    OK!"
        } catch {
            Write-Host "    Trigger download error: $_"
        }
    }

    $cardInfo = [ordered]@{
        id = "$i"
        action = "$($ev.trigger.action)"
        giftId = if ($ev.trigger.giftId) { "$($ev.trigger.giftId)" } else { "" }
        giftName = if ($ev.trigger.giftData.name) { "$($ev.trigger.giftData.name)" } else { "$($ev.trigger.action)" }
        funcName = "$($ev.function.name)"
        funcImg = "images/func_$($i).png"
        trigImg = $tRelPath
        triggerValue = if ($ev.trigger.value) { "$($ev.trigger.value)" } else { "" }
    }
    $cardList += $cardInfo
    $i++
}

$cardsJsonPath = Join-Path $PSScriptRoot "cards.json"
$cardsJsPath = Join-Path $PSScriptRoot "cards-data.js"
$jsonStr = $cardList | ConvertTo-Json -Depth 4
[System.IO.File]::WriteAllText($cardsJsonPath, $jsonStr, (New-Object System.Text.UTF8Encoding($false)))
$jsContent = "window.S2E_CARDS_DATA = " + $jsonStr + ";"
[System.IO.File]::WriteAllText($cardsJsPath, $jsContent, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Updated cards.json and cards-data.js successfully ($($cardList.Count) cards)!"
Write-Host "All icons and gift mappings synchronized!"
