$enc = New-Object System.Text.UTF8Encoding($false)
$paths = @("cards.json", "core/cards.json", "pvz_fusion_config.json", "core/pvz_fusion_config.json", "version.json", "core/version.json")
foreach ($p in $paths) {
    if (Test-Path $p) {
        $full = (Resolve-Path $p).Path
        $bytes = [System.IO.File]::ReadAllBytes($full)
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            Write-Host "Stripping BOM from $p"
            $text = [System.Text.Encoding]::UTF8.GetString($bytes, 3, $bytes.Length - 3)
            [System.IO.File]::WriteAllText($full, $text, $enc)
        }
    }
}
Write-Host "BOM check completed."
