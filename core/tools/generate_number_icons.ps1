$numbersDir = Join-Path $PSScriptRoot "..\images\numbers"
if (-not (Test-Path $numbersDir)) { New-Item -ItemType Directory -Path $numbersDir -Force | Out-Null }

$posNumbers = @(1, 2, 3, 4, 5, 10, 15, 20, 25, 30, 40, 50, 75, 100, 200, 500, 1000)
$negNumbers = @(1, 2, 3, 4, 5, 10, 15, 20, 25, 30, 40, 50, 75, 100, 200, 500, 1000)

function Get-ColorForNum([int]$n, [bool]$isPos) {
    if ($isPos) {
        if ($n -ge 100) { return '#ef4444' }     # Mythic Red
        elseif ($n -ge 50) { return '#10b981' }  # Legendary Green
        elseif ($n -ge 20) { return '#eab308' }  # Epic Gold
        elseif ($n -ge 10) { return '#f43f5e' }  # Rose
        elseif ($n -ge 5) { return '#a855f7' }   # Rare Purple
        elseif ($n -eq 2) { return '#f59e0b' }   # Amber
        else { return '#10b981' }                # Emerald
    } else {
        if ($n -ge 100) { return '#ec4899' }     # Mythic Pink
        elseif ($n -ge 50) { return '#06b6d4' }  # Cyan/Ice
        elseif ($n -ge 20) { return '#f59e0b' }  # Amber
        elseif ($n -ge 10) { return '#ef4444' }  # Red
        elseif ($n -ge 5) { return '#d946ef' }   # Fuchsia
        else { return '#f97316' }                # Orange
    }
}

foreach ($n in $posNumbers) {
    $col = Get-ColorForNum $n $true
    $txt = "$n"
    $fontSize = if ($txt.Length -gt 3) { 28 } elseif ($txt.Length -gt 2) { 34 } else { 40 }
    $svg = @"
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100">
  <defs>
    <filter id="neon-glow" x="-20%" y="-20%" width="140%" height="140%">
      <feGaussianBlur stdDeviation="3" result="blur" />
      <feMerge>
        <feMergeNode in="blur" />
        <feMergeNode in="SourceGraphic" />
      </feMerge>
    </filter>
  </defs>
  <rect x="6" y="6" width="88" height="88" rx="14" ry="14" fill="#0d1117" stroke="$col" stroke-width="4" filter="url(#neon-glow)" />
  <rect x="10" y="10" width="80" height="80" rx="10" ry="10" fill="none" stroke="$col" stroke-width="1.5" stroke-opacity="0.5" />
  <text x="50" y="58" dominant-baseline="middle" text-anchor="middle" font-family="'Outfit', 'Plus Jakarta Sans', sans-serif" font-weight="900" font-size="$fontSize" fill="$col" filter="url(#neon-glow)">$txt</text>
</svg>
"@
    [System.IO.File]::WriteAllText((Join-Path $numbersDir "num_pos_$n.svg"), $svg, [System.Text.Encoding]::UTF8)

    # Explicit + version
    $txtPlus = "+$n"
    $fPlus = if ($txtPlus.Length -gt 3) { 28 } elseif ($txtPlus.Length -gt 2) { 32 } else { 38 }
    $svgPlus = @"
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100">
  <defs>
    <filter id="neon-glow" x="-20%" y="-20%" width="140%" height="140%">
      <feGaussianBlur stdDeviation="3" result="blur" />
      <feMerge>
        <feMergeNode in="blur" />
        <feMergeNode in="SourceGraphic" />
      </feMerge>
    </filter>
  </defs>
  <rect x="6" y="6" width="88" height="88" rx="14" ry="14" fill="#0d1117" stroke="$col" stroke-width="4" filter="url(#neon-glow)" />
  <rect x="10" y="10" width="80" height="80" rx="10" ry="10" fill="none" stroke="$col" stroke-width="1.5" stroke-opacity="0.5" />
  <text x="50" y="58" dominant-baseline="middle" text-anchor="middle" font-family="'Outfit', 'Plus Jakarta Sans', sans-serif" font-weight="900" font-size="$fPlus" fill="$col" filter="url(#neon-glow)">$txtPlus</text>
</svg>
"@
    [System.IO.File]::WriteAllText((Join-Path $numbersDir "num_plus_$n.svg"), $svgPlus, [System.Text.Encoding]::UTF8)
}

foreach ($n in $negNumbers) {
    $col = Get-ColorForNum $n $false
    $txt = "-$n"
    $fontSize = if ($txt.Length -gt 3) { 28 } elseif ($txt.Length -gt 2) { 32 } else { 38 }
    $svg = @"
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100">
  <defs>
    <filter id="neon-glow" x="-20%" y="-20%" width="140%" height="140%">
      <feGaussianBlur stdDeviation="3" result="blur" />
      <feMerge>
        <feMergeNode in="blur" />
        <feMergeNode in="SourceGraphic" />
      </feMerge>
    </filter>
  </defs>
  <rect x="6" y="6" width="88" height="88" rx="14" ry="14" fill="#0d1117" stroke="$col" stroke-width="4" filter="url(#neon-glow)" />
  <rect x="10" y="10" width="80" height="80" rx="10" ry="10" fill="none" stroke="$col" stroke-width="1.5" stroke-opacity="0.5" />
  <text x="50" y="58" dominant-baseline="middle" text-anchor="middle" font-family="'Outfit', 'Plus Jakarta Sans', sans-serif" font-weight="900" font-size="$fontSize" fill="$col" filter="url(#neon-glow)">$txt</text>
</svg>
"@
    [System.IO.File]::WriteAllText((Join-Path $numbersDir "num_neg_$n.svg"), $svg, [System.Text.Encoding]::UTF8)
}

Write-Host "Generated all $(($posNumbers.Count * 2) + $negNumbers.Count) SVG number icons successfully in $numbersDir!" -ForegroundColor Green
