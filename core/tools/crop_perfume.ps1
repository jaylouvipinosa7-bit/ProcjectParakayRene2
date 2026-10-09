Add-Type -AssemblyName System.Drawing

$img = [System.Drawing.Bitmap]::FromFile("C:\Users\pc\.gemini\antigravity-ide\brain\a4694cdc-bb95-4421-98c1-6e9e133d6a82\.user_uploaded\media_1791538343898.png")

# Tighter crop of perfume bottle
$rect = New-Object System.Drawing.Rectangle(63, 36, 44, 52)
$crop = New-Object System.Drawing.Bitmap($rect.Width, $rect.Height)
$g = [System.Drawing.Graphics]::FromImage($crop)
$g.DrawImage($img, (New-Object System.Drawing.Rectangle(0,0,$rect.Width,$rect.Height)), $rect.X, $rect.Y, $rect.Width, $rect.Height, [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose()
$img.Dispose()

$crop.Save("images\tiktok-gifts\perfume_gift.png", [System.Drawing.Imaging.ImageFormat]::Png)
$crop.Save("images\tiktok-gifts\perfume_gift.webp", [System.Drawing.Imaging.ImageFormat]::Png)
$crop.Dispose()
Write-Output "Saved refined perfume_gift"
