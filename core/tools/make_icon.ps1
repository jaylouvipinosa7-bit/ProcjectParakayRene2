Add-Type -AssemblyName System.Drawing

$srcPath = "c:\Users\pc\Downloads\ano na\app_icon.png"
$icoPath = "c:\Users\pc\Downloads\ano na\app_icon.ico"
$srcBmp = [System.Drawing.Bitmap]::FromFile($srcPath)

$sizes = @(256, 128, 64, 48, 32, 16)
$pngStreams = @()

foreach ($sz in $sizes) {
    $targetBmp = New-Object System.Drawing.Bitmap $sz, $sz
    $g = [System.Drawing.Graphics]::FromImage($targetBmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.DrawImage($srcBmp, 0, 0, $sz, $sz)
    $g.Dispose()

    $ms = New-Object System.IO.MemoryStream
    $targetBmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $targetBmp.Dispose()
    $pngStreams += $ms
}
$srcBmp.Dispose()

$icoFile = [System.IO.File]::Create($icoPath)
$bw = New-Object System.IO.BinaryWriter $icoFile

# Header (6 bytes)
$bw.Write([uint16]0) # Reserved
$bw.Write([uint16]1) # Type (1 = ICO)
$bw.Write([uint16]$sizes.Count) # Image count

$offset = 6 + ($sizes.Count * 16)

# Directory Entries (16 bytes each)
for ($i = 0; $i -lt $sizes.Count; $i++) {
    $sz = $sizes[$i]
    $dataLen = [uint32]$pngStreams[$i].Length
    
    $wByte = if ($sz -ge 256) { [byte]0 } else { [byte]$sz }
    $hByte = if ($sz -ge 256) { [byte]0 } else { [byte]$sz }

    $bw.Write($wByte) # Width
    $bw.Write($hByte) # Height
    $bw.Write([byte]0) # Colors
    $bw.Write([byte]0) # Reserved
    $bw.Write([uint16]1) # Planes
    $bw.Write([uint16]32) # Bit count
    $bw.Write($dataLen) # Bytes in res
    $bw.Write([uint32]$offset) # Offset

    $offset += $dataLen
}

# Image Data
for ($i = 0; $i -lt $sizes.Count; $i++) {
    $bytes = $pngStreams[$i].ToArray()
    $bw.Write($bytes)
    $pngStreams[$i].Dispose()
}

$bw.Close()
$icoFile.Close()

Write-Host "Created app_icon.ico successfully! Size: $((Get-Item $icoPath).Length) bytes"
