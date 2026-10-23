# clean_mojibake_v2.ps1 - Fix corrupted characters using line-by-line replacement
# Read as raw bytes and convert to UTF-8 string properly
$filePath = "c:\Users\pc\Downloads\ano na\core\app.html"
$bytes = [System.IO.File]::ReadAllBytes($filePath)
$html = [System.Text.Encoding]::UTF8.GetString($bytes)
$originalLen = $html.Length
Write-Host "File loaded: $originalLen chars"

# Pattern 1: Remove the corrupted DNA emoji (was 🧬 but became mojibake)
# The byte sequence for corrupted emoji starts with C3 B0 C5 B8
# We'll search line by line for known corrupted text patterns

$lines = $html -split "`n"
$fixedLines = @()
$fixCount = 0

foreach ($line in $lines) {
    $original = $line

    # Fix corrupted hybrid album pill label - remove garbled emoji and Chinese chars
    if ($line -match 'albumPillpvz_hybrid' -or $line -match 'albumCardpvz_hybrid' -or $line -match 'album-card-title' -or $line -match 'album-card-engine' -or $line -match 'album-card-presets-badge' -or $line -match 'presetInputGame' -or $line -match 'Game 0: PvZ') {
        # Remove any non-ASCII garbled sequences before known text
        # Keep only clean ASCII + valid HTML entities
        $cleaned = $line
        # Replace any sequence of 2+ consecutive non-ASCII chars (mojibake) with empty string
        # But preserve valid Unicode like Chinese in JS strings (those are in the GAME_INFO_MAP etc)
        if ($cleaned -match '[^\x00-\x7F]{3,}') {
            # Only clean lines that are HTML content (not JS code with intentional Unicode)
            if ($cleaned -match '<div|<button|<option|<span|<!--') {
                $cleaned = $cleaned -replace '[^\x00-\x7F]{2,}\s*', ''
                # Also clean up double spaces left behind
                $cleaned = $cleaned -replace '\s{2,}', ' '
            }
        }
        if ($cleaned -ne $original) {
            $fixCount++
            Write-Host "Fixed line: $($cleaned.Trim().Substring(0, [Math]::Min(80, $cleaned.Trim().Length)))..."
        }
        $fixedLines += $cleaned
    } else {
        $fixedLines += $line
    }
}

$result = $fixedLines -join "`n"
Write-Host "Fixed $fixCount lines"

if ($fixCount -gt 0) {
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($filePath, $result, $utf8NoBom)
    Write-Host "Saved cleaned app.html"
} else {
    Write-Host "No changes needed"
}
