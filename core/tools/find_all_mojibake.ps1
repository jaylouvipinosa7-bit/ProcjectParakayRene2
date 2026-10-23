# find_all_mojibake.ps1 - Find ALL non-ASCII corrupted text patterns in app.html
$filePath = "c:\Users\pc\Downloads\ano na\core\app.html"
$bytes = [System.IO.File]::ReadAllBytes($filePath)
$html = [System.Text.Encoding]::UTF8.GetString($bytes)
$lines = $html -split "`n"

Write-Host "Total lines: $($lines.Length)"
Write-Host ""

# Search for common mojibake patterns visible in the screenshot
$patterns = @(
    'Test 50 Likes',
    'Test Stream Goal',
    'Test Follow',
    'Test Share',
    'Test Join Alert',
    'Test Chat Command',
    'Test Super Fan',
    'Test Coins Bracket',
    'Queue',
    'Clear',
    'Edit',
    'Manage TikTok Gift',
    'Copy Link',
    'NEW FOLLOWER'
)

foreach ($pat in $patterns) {
    for ($i = 0; $i -lt $lines.Length; $i++) {
        if ($lines[$i] -match [regex]::Escape($pat)) {
            $ln = $i + 1
            $trimmed = $lines[$i].Trim()
            if ($trimmed.Length -gt 150) { $trimmed = $trimmed.Substring(0, 150) + "..." }
            # Check if line has non-ASCII chars
            $hasNonAscii = $false
            foreach ($c in $trimmed.ToCharArray()) {
                if ([int]$c -gt 127 -and [int]$c -lt 8192) { $hasNonAscii = $true; break }
            }
            if ($hasNonAscii) {
                Write-Host "L${ln}: $trimmed"
            }
        }
    }
}

# Also find lines with common mojibake byte patterns (double-encoded UTF-8)
Write-Host ""
Write-Host "=== Lines with high-range non-ASCII near button/card elements ==="
for ($i = 0; $i -lt $lines.Length; $i++) {
    $line = $lines[$i]
    # Only check lines that contain button, card-icon, or trigger-related HTML
    if ($line -match 'btn-test|btn-edit|btn-action|card-icon-wrap|trigger-icon|card-header-icon|\.queue|\.clear') {
        $hasCorrupt = $false
        foreach ($c in $line.ToCharArray()) {
            $code = [int]$c
            if ($code -gt 127 -and $code -lt 8192) { $hasCorrupt = $true; break }
        }
        if ($hasCorrupt) {
            $ln = $i + 1
            $trimmed = $line.Trim()
            if ($trimmed.Length -gt 150) { $trimmed = $trimmed.Substring(0, 150) + "..." }
            Write-Host "L${ln}: $trimmed"
        }
    }
}
