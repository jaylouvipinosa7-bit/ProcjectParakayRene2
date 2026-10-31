Add-Type -AssemblyName System.Drawing

$outDir = "c:\Users\pc\Downloads\ano na\core\images\games\chars"
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force }

function Crop-Image($srcFile, $outFile, $x, $y, $w, $h) {
    if (-not (Test-Path $srcFile)) { return }
    $bmp = [System.Drawing.Bitmap]::FromFile($srcFile)
    
    # Clamp bounds
    $cx = [Math]::Max(0, [Math]::Min($x, $bmp.Width - 10))
    $cy = [Math]::Max(0, [Math]::Min($y, $bmp.Height - 10))
    $cw = [Math]::Min($w, $bmp.Width - $cx)
    $ch = [Math]::Min($h, $bmp.Height - $cy)
    
    $rect = [System.Drawing.Rectangle]::new($cx, $cy, $cw, $ch)
    $cropped = $bmp.Clone($rect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $cropped.Save($outFile, [System.Drawing.Imaging.ImageFormat]::Png)
    $cropped.Dispose()
    $bmp.Dispose()
    Write-Host "Created $outFile ($cw x $ch)"
}

# 1. Left 4 Dead 2 Tank upper torso & head (Source: 1376 x 768)
Crop-Image "c:\Users\pc\Downloads\ano na\core\images\games\l4d2.jpg" "$outDir\l4d2.png" 620 30 720 520

# 2. Resident Evil 4 Leon (Source: 1376 x 768)
Crop-Image "c:\Users\pc\Downloads\ano na\core\images\games\re4.jpg" "$outDir\re4.png" 930 40 440 480

# 3. GTA San Andreas CJ (Source: 1376 x 768)
Crop-Image "c:\Users\pc\Downloads\ano na\core\images\games\gta_sa.jpg" "$outDir\gta_sa.png" 950 40 420 540

# 4. GTA V Chaos Trevor (Source: 1376 x 768)
Crop-Image "c:\Users\pc\Downloads\ano na\core\images\games\gtav_chaos.jpg" "$outDir\gtav_chaos.png" 540 30 720 560

# 5. GTA V KotH Michael (Source: 1376 x 768)
Crop-Image "c:\Users\pc\Downloads\ano na\core\images\games\gtav_koth.jpg" "$outDir\gtav_koth.png" 480 30 450 560

# 6. GTA V Airport Franklin (Source: 1376 x 768)
Crop-Image "c:\Users\pc\Downloads\ano na\core\images\games\gtav_airport.jpg" "$outDir\gtav_airport.png" 460 40 440 560

# 7. Minecraft Steve (Source: 900 x 1200)
Crop-Image "c:\Users\pc\Downloads\ano na\core\images\games\minecraft.jpg" "$outDir\minecraft.png" 100 550 500 550

# 8. PvZ Fusion Gatling Peashooter (Source: 896 x 1200)
Crop-Image "c:\Users\pc\Downloads\ano na\images\pvz_fusion_cover.jpg" "$outDir\pvz_fusion.png" 20 330 460 420

# 9. PvZ Classic (Source: 1376 x 768 or similar)
Crop-Image "c:\Users\pc\Downloads\ano na\core\images\games\pvz_classic_poster.jpg" "$outDir\pvz_classic.png" 450 100 500 500

# 10. PvZ Hybrid (Source: 1376 x 768 or similar)
Crop-Image "c:\Users\pc\Downloads\ano na\core\images\games\pvz_hybrid_poster.jpg" "$outDir\pvz_hybrid.png" 450 100 500 500

# 11. Zombie Tsunami (from icon)
if (Test-Path "c:\Users\pc\Downloads\ano na\images\zombie_tsunami_icon.png") {
    Copy-Item "c:\Users\pc\Downloads\ano na\images\zombie_tsunami_icon.png" "$outDir\zombie_tsunami.png" -Force
}

# 12. TABS (svg copy)
if (Test-Path "c:\Users\pc\Downloads\ano na\core\images\games\tabs.svg") {
    Copy-Item "c:\Users\pc\Downloads\ano na\core\images\games\tabs.svg" "$outDir\tabs.svg" -Force
}

# 13. UEBS2 (svg copy)
if (Test-Path "c:\Users\pc\Downloads\ano na\core\images\games\uebs2.svg") {
    Copy-Item "c:\Users\pc\Downloads\ano na\core\images\games\uebs2.svg" "$outDir\uebs2.svg" -Force
}

# 14. Crown Clash (svg copy)
if (Test-Path "c:\Users\pc\Downloads\ano na\core\images\games\crown_clash.svg") {
    Copy-Item "c:\Users\pc\Downloads\ano na\core\images\games\crown_clash.svg" "$outDir\crown_clash.svg" -Force
}

Write-Host "All game character crops done!"
