# find_card_header_mojibake.ps1 - Find ALL corrupted text in social trigger card headers
$filePath = "c:\Users\pc\Downloads\ano na\core\app.html"
$bytes = [System.IO.File]::ReadAllBytes($filePath)
$html = [System.Text.Encoding]::UTF8.GetString($bytes)
$lines = $html -split "`n"

# Search the entire social triggers section (lines 13200-13600)
Write-Host "=== Lines 13200-13600 with non-ASCII chars ==="
for ($i = 13199; $i -lt [Math]::Min(13600, $lines.Length); $i++) {
    $line = $lines[$i]
    $hasCorrupt = $false
    foreach ($c in $line.ToCharArray()) {
        $code = [int]$c
        if ($code -gt 127 -and $code -lt 65536) { $hasCorrupt = $true; break }
    }
    if ($hasCorrupt) {
        $ln = $i + 1
        $trimmed = $line.Trim()
        if ($trimmed.Length -gt 160) { $trimmed = $trimmed.Substring(0, 160) + "..." }
        Write-Host "L${ln}: $trimmed"
    }
}
