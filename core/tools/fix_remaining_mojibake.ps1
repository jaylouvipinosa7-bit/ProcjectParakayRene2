# fix_remaining_mojibake.ps1 - Fix the two remaining lines with corrupted text
$filePath = "c:\Users\pc\Downloads\ano na\core\app.html"
$bytes = [System.IO.File]::ReadAllBytes($filePath)
$html = [System.Text.Encoding]::UTF8.GetString($bytes)
$lines = $html -split "`n"

Write-Host "Total lines: $($lines.Length)"
$fixCount = 0

for ($i = 0; $i -lt $lines.Length; $i++) {
    $line = $lines[$i]

    # Fix line ~11972: album pill text with corrupted emoji + Chinese
    if ($line -match 'albumPillpvz_hybrid' -or ($i -gt 0 -and $lines[$i-1] -match 'albumPillpvz_hybrid')) {
        # Skip - check next line
    }
    
    # The pill text line: contains garbled chars then "PvZ: Hybrid Edition" then more garbled chars
    if ($line -match 'PvZ: Hybrid Edition' -and $line -notmatch '<' -and $line -notmatch 'name:' -and $line -notmatch 'desc:') {
        $cleaned = $line -replace '[^\x00-\x7F]+', ''
        $cleaned = $cleaned -replace '\s+PvZ', ' PvZ'
        $cleaned = $cleaned -replace 'Edition\s*\(\s*\)', 'Edition'
        $cleaned = $cleaned.TrimEnd()
        if ($cleaned -ne $line) {
            Write-Host "L$($i+1) BEFORE: $($line.Trim())"
            Write-Host "L$($i+1) AFTER:  $($cleaned.Trim())"
            $lines[$i] = $cleaned
            $fixCount++
        }
    }

    # Fix line ~19135: preset dropdown option with corrupted Chinese
    if ($line -match '<option value="pvz_hybrid">' -and $line -match 'Hybrid Edition') {
        $cleaned = '                                    <option value="pvz_hybrid">Plants vs Zombies: Hybrid Edition</option>'
        if ($cleaned.Trim() -ne $line.Trim()) {
            Write-Host "L$($i+1) BEFORE: $($line.Trim())"
            Write-Host "L$($i+1) AFTER:  $($cleaned.Trim())"
            $lines[$i] = $cleaned
            $fixCount++
        }
    }
}

if ($fixCount -gt 0) {
    $result = $lines -join "`n"
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($filePath, $result, $utf8NoBom)
    Write-Host "Fixed $fixCount lines and saved."
} else {
    Write-Host "No remaining mojibake found."
}
