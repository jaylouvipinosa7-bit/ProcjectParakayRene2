# clean_mojibake.ps1 - Find and fix all corrupted/garbled characters in app.html
$filePath = "c:\Users\pc\Downloads\ano na\core\app.html"
$bytes = [System.IO.File]::ReadAllBytes($filePath)
$html = [System.Text.Encoding]::UTF8.GetString($bytes)

Write-Host "File size: $($html.Length) chars"

# List of mojibake patterns to search for
$searchPatterns = @(
    'ðŸ§¬',
    'ðŸ'¿',
    'ðŸŽ',
    'ðŸ"',
    'ðŸ''
)

foreach ($p in $searchPatterns) {
    $idx = $html.IndexOf($p)
    if ($idx -ge 0) {
        $start = [Math]::Max(0, $idx - 20)
        $len = [Math]::Min(80, $html.Length - $start)
        $context = $html.Substring($start, $len) -replace "`r`n", " " -replace "`n", " "
        Write-Host "FOUND '$p' at index $idx context: ...$context..."
    }
}

# Now do targeted replacements for corrupted text we introduced
$replacements = @{
    # Album pill label
    'ðŸ§¬ PvZ: Hybrid Edition (æ‚äº¤ç‰ˆ)' = 'PvZ: Hybrid Edition'
    # Album card title
    'PvZ: Hybrid Edition (æ‚äº¤ç‰ˆ)' = 'PvZ: Hybrid Edition'
    # Album card engine
    'ðŸ§¬ Hybrid Mod &amp; Memory Link' = 'Hybrid Mod &amp; Memory Link'
    'ðŸ§¬ Hybrid Mod & Memory Link' = 'Hybrid Mod &amp; Memory Link'
    # Album card badge
    'ðŸŽ 100+ Hybrids' = '100+ Hybrids'
    # Preset modal option
    'Plants vs Zombies: Hybrid Edition (æ‚äº¤ç‰ˆ)' = 'Plants vs Zombies: Hybrid Edition'
    # Comment
    'Game 0: PvZ: Hybrid Edition (æ‚äº¤ç‰ˆ)' = 'Game 0: PvZ: Hybrid Edition'
    # Sidebar icon if any leftover
    'ðŸ'¿' = ''
}

$changeCount = 0
foreach ($old in $replacements.Keys) {
    $new = $replacements[$old]
    if ($html.Contains($old)) {
        $count = ([regex]::Matches($html, [regex]::Escape($old))).Count
        $html = $html.Replace($old, $new)
        Write-Host "Replaced '$old' -> '$new' ($count occurrences)"
        $changeCount += $count
    }
}

# Also search for the specific mojibake pattern in the chooser modal game switcher pills
# These were added by the PS1 script and may have corrupted characters
$mojibakePatterns = @(
    'ðŸ§',  # partial emoji sequences
    'ðŸ"',
    'ðŸ''
)

foreach ($p in $mojibakePatterns) {
    if ($html.Contains($p)) {
        $idx = $html.IndexOf($p)
        $start = [Math]::Max(0, $idx - 30)
        $len = [Math]::Min(100, $html.Length - $start)
        $context = $html.Substring($start, $len) -replace "`r`n", " " -replace "`n", " "
        Write-Host "WARNING: Still contains '$p' at index $idx context: ...$context..."
    }
}

if ($changeCount -gt 0) {
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($filePath, $html, $utf8NoBom)
    Write-Host "Saved $changeCount replacements to app.html (UTF-8 no BOM)"
} else {
    Write-Host "No mojibake patterns found to replace."
}
