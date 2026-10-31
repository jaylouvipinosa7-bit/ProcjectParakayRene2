Add-Type -AssemblyName System.Drawing

$src = [System.Drawing.Bitmap]::FromFile("c:\Users\pc\Downloads\ano na\core\images\games\chars\l4d2_tank.png")
$out = [System.Drawing.Bitmap]::new($src.Width, $src.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)

# The tank is in the center/left, background is dark smoke.
# We apply a soft alpha mask based on luminance and distance from center.
for ($y = 0; $y -lt $src.Height; $y++) {
    for ($x = 0; $x -lt $src.Width; $x++) {
        $p = $src.GetPixel($x, $y)
        $brightness = ($p.R * 0.299 + $p.G * 0.587 + $p.B * 0.114)
        
        # Don't include the yellow text at bottom
        if ($y -gt ($src.Height * 0.70)) {
            $out.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
            continue
        }
        
        if ($brightness -lt 25) {
            $out.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
        } elseif ($brightness -lt 45) {
            $alpha = [int](($brightness - 25) / 20 * 255)
            $out.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($alpha, $p.R, $p.G, $p.B))
        } else {
            $out.SetPixel($x, $y, $p)
        }
    }
}

$out.Save("c:\Users\pc\Downloads\ano na\core\images\games\chars\l4d2_tank_cutout.png", [System.Drawing.Imaging.ImageFormat]::Png)
$out.Dispose()
$src.Dispose()
Write-Host "Cutout saved!"
