# fix_all_social_mojibake.ps1 - Fix ALL corrupted emojis in social triggers section
$filePath = "c:\Users\pc\Downloads\ano na\core\app.html"
$bytes = [System.IO.File]::ReadAllBytes($filePath)
$html = [System.Text.Encoding]::UTF8.GetString($bytes)
$lines = $html -split "`n"
$fixCount = 0

for ($i = 0; $i -lt $lines.Length; $i++) {
    $original = $lines[$i]
    $line = $lines[$i]

    # Fix btn-test buttons: remove corrupted emoji before "Test ..."
    if ($line -match 'class="btn-test"' -and $line -match 'Test ') {
        # Remove all non-ASCII chars from this line
        $newLine = ''
        foreach ($c in $line.ToCharArray()) {
            if ([int]$c -le 127) { $newLine += $c }
        }
        # Clean up double spaces
        $newLine = $newLine -replace '\s{2,}', ' '
        # Fix the inner text: ensure proper format
        $newLine = $newLine -replace '>\s*Test ', '>Test '
        $lines[$i] = $newLine
    }

    # Fix btn-edit buttons: remove corrupted emoji before "Edit"
    if ($line -match 'class="btn-edit"' -and $line -match 'Edit') {
        $newLine = ''
        foreach ($c in $line.ToCharArray()) {
            if ([int]$c -le 127) { $newLine += $c }
        }
        $newLine = $newLine -replace '\s{2,}', ' '
        $newLine = $newLine -replace '>\s*Edit', '>Edit'
        $lines[$i] = $newLine
    }

    # Fix "JOIN" header with corrupted emoji
    if ($line -match 'JOIN</span>') {
        $newLine = ''
        foreach ($c in $line.ToCharArray()) {
            if ([int]$c -le 127) { $newLine += $c }
        }
        $newLine = $newLine -replace '\s{2,}', ' '
        $newLine = $newLine -replace '>\s*JOIN', '>JOIN'
        $lines[$i] = $newLine
    }

    # Fix star icon (line 13388)
    if ($line.Trim() -match '^\x{2B50}$' -or $line.Trim() -match '^\x{FFFD}' -or ($line.Trim().Length -le 5 -and $i -ge 13386 -and $i -le 13390)) {
        $stripped = ''
        foreach ($c in $line.ToCharArray()) {
            if ([int]$c -le 127) { $stripped += $c }
        }
        if ($stripped.Trim() -eq '') {
            # This was just an emoji on its own line - keep whitespace but empty the content
            $lines[$i] = $line -replace '[^\s]', ''
            # Actually better: just leave the empty whitespace
        }
    }

    # Fix "NEW FOLLOWER" line with corrupted bullet
    if ($line -match 'NEW FOLLOWER') {
        $newLine = ''
        foreach ($c in $line.ToCharArray()) {
            if ([int]$c -le 127) { $newLine += $c }
        }
        $newLine = $newLine -replace '\s{2,}', ' '
        $newLine = $newLine -replace 'FOLLOWER\s+renearn', 'FOLLOWER - renearn'
        $lines[$i] = $newLine
    }

    # Fix "Copy Link" button with corrupted emoji
    if ($line -match 'Copy Link') {
        $newLine = ''
        foreach ($c in $line.ToCharArray()) {
            if ([int]$c -le 127) { $newLine += $c }
        }
        $newLine = $newLine -replace '\s{2,}', ' '
        $newLine = $newLine -replace '>\s*Copy Link', '>Copy Link'
        $lines[$i] = $newLine
    }

    # Fix "+3 Queue" button with corrupted emoji
    if ($line -match '\+3 Queue') {
        $newLine = ''
        foreach ($c in $line.ToCharArray()) {
            if ([int]$c -le 127) { $newLine += $c }
        }
        $newLine = $newLine -replace '\s{2,}', ' '
        $newLine = $newLine -replace '>\s*\+3', '>+3'
        $lines[$i] = $newLine
    }

    # Fix "Clear" button with corrupted emoji
    if ($line -match 'Clear' -and $line -match 'clear.*queue' -and $i -ge 13410 -and $i -le 13420) {
        $newLine = ''
        foreach ($c in $line.ToCharArray()) {
            if ([int]$c -le 127) { $newLine += $c }
        }
        $newLine = $newLine -replace '\s{2,}', ' '
        $newLine = $newLine -replace '>\s*Clear', '>Clear'
        $lines[$i] = $newLine
    }

    # Fix "Manage TikTok Gift Commands" button
    if ($line -match 'Manage TikTok Gift Commands') {
        $newLine = ''
        foreach ($c in $line.ToCharArray()) {
            if ([int]$c -le 127) { $newLine += $c }
        }
        $newLine = $newLine -replace '\s{2,}', ' '
        $newLine = $newLine -replace '>\s*Manage', '>Manage'
        $lines[$i] = $newLine
    }

    # Fix chat icon div (line ~13437) - corrupted 💬
    if ($line -match 'font-size: 16px' -and $line -match '56, 189, 248') {
        $newLine = ''
        foreach ($c in $line.ToCharArray()) {
            if ([int]$c -le 127) { $newLine += $c }
        }
        # Add back a simple text icon
        $newLine = $newLine -replace '></div>', '>CHAT</div>'
        $lines[$i] = $newLine
    }

    # Fix VIP/crown icon div (line ~13470) - corrupted 👑
    if ($line -match 'font-size: 16px' -and $line -match '245, 158, 11') {
        $newLine = ''
        foreach ($c in $line.ToCharArray()) {
            if ([int]$c -le 127) { $newLine += $c }
        }
        $newLine = $newLine -replace '></div>', '>VIP</div>'
        $lines[$i] = $newLine
    }

    # Fix coins icon div (line ~13503) - corrupted emoji
    if ($line -match 'font-size: 16px' -and $line -match '234, 179, 8') {
        $newLine = ''
        foreach ($c in $line.ToCharArray()) {
            if ([int]$c -le 127) { $newLine += $c }
        }
        $newLine = $newLine -replace '></div>', '>COINS</div>'
        $lines[$i] = $newLine
    }

    # Fix gifts icon div (line ~13536) - corrupted emoji
    if ($line -match 'font-size: 16px' -and $line -match '244, 63, 94') {
        $newLine = ''
        foreach ($c in $line.ToCharArray()) {
            if ([int]$c -le 127) { $newLine += $c }
        }
        $newLine = $newLine -replace '></div>', '>GIFT</div>'
        $lines[$i] = $newLine
    }

    # Fix custom trigger icon div (line ~13570) - corrupted emoji
    if ($line -match 'font-size: 16px' -and $line -match '6, 182, 212') {
        $newLine = ''
        foreach ($c in $line.ToCharArray()) {
            if ([int]$c -le 127) { $newLine += $c }
        }
        $newLine = $newLine -replace '></div>', '>USTO</div>'
        # Actually keep it as just the text shown in screenshot
        $lines[$i] = $newLine
    }

    # Fix line 13388 standalone star emoji
    if ($i -eq 13387) {
        $stripped = $line.Trim()
        $hasOnlyNonAscii = $true
        foreach ($c in $stripped.ToCharArray()) {
            if ([int]$c -le 127 -and $c -ne ' ') { $hasOnlyNonAscii = $false; break }
        }
        if ($hasOnlyNonAscii -and $stripped.Length -gt 0) {
            $indent = $line -replace '[^\s].*', ''
            $lines[$i] = $indent
        }
    }

    # Fix the "Clear" standalone line (line ~13415)
    if ($line.Trim() -match '^.{0,6}Clear$' -and $i -ge 13412 -and $i -le 13418) {
        $indent = $line -replace '\S.*', ''
        $lines[$i] = $indent + "Clear"
    }

    if ($lines[$i] -ne $original) {
        $fixCount++
        $ln = $i + 1
        Write-Host "L${ln}: FIXED"
    }
}

if ($fixCount -gt 0) {
    $result = $lines -join "`n"
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($filePath, $result, $utf8NoBom)
    Write-Host ""
    Write-Host "Fixed $fixCount lines total. Saved."
} else {
    Write-Host "No fixes needed."
}
