$dir = Join-Path (Split-Path -Parent $PSScriptRoot) "images\numbers"
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

$numbers = @(
    @{ val = "1";   color = "#f43f5e"; glow = "rgba(244,63,94,0.6)"; border = "#f43f5e" },
    @{ val = "2";   color = "#f59e0b"; glow = "rgba(245,158,11,0.6)"; border = "#f59e0b" },
    @{ val = "5";   color = "#a855f7"; glow = "rgba(168,85,247,0.6)"; border = "#a855f7" },
    @{ val = "10";  color = "#ec4899"; glow = "rgba(236,72,153,0.6)"; border = "#ec4899" },
    @{ val = "20";  color = "#f59e0b"; glow = "rgba(245,158,11,0.6)"; border = "#f59e0b" },
    @{ val = "50";  color = "#10b981"; glow = "rgba(16,185,129,0.6)"; border = "#10b981" },
    @{ val = "100"; color = "#fb7185"; glow = "rgba(251,113,133,0.6)"; border = "#fb7185" },
    @{ val = "-1";  color = "#ef4444"; glow = "rgba(239,68,68,0.6)"; border = "#ef4444" },
    @{ val = "-5";  color = "#8b5cf6"; glow = "rgba(139,92,246,0.6)"; border = "#8b5cf6" },
    @{ val = "-10"; color = "#d946ef"; glow = "rgba(217,70,239,0.6)"; border = "#d946ef" },
    @{ val = "-20"; color = "#f59e0b"; glow = "rgba(245,158,11,0.6)"; border = "#f59e0b" },
    @{ val = "-50"; color = "#059669"; glow = "rgba(5,150,105,0.6)"; border = "#059669" },
    @{ val = "-100"; color = "#dc2626"; glow = "rgba(220,38,38,0.6)"; border = "#dc2626" }
)

foreach ($n in $numbers) {
    $v = $n.val
    $c = $n.color
    $b = $n.border
    $safeName = "num_" + ($v.Replace("-", "neg_").Replace("+", "pos_"))
    if ($v -notmatch '-') { $safeName = "num_pos_" + $v }
    $filePath = Join-Path $dir "$safeName.svg"

    $fontSize = if ($v.Length -ge 4) { "28" } elseif ($v.Length -ge 3) { "34" } else { "40" }
    
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
  <rect x="6" y="6" width="88" height="88" rx="14" ry="14" fill="#0d1117" stroke="$b" stroke-width="4" filter="url(#neon-glow)" />
  <rect x="10" y="10" width="80" height="80" rx="10" ry="10" fill="none" stroke="$b" stroke-width="1.5" stroke-opacity="0.5" />
  <text x="50" y="58" dominant-baseline="middle" text-anchor="middle" font-family="'Outfit', 'Plus Jakarta Sans', sans-serif" font-weight="900" font-size="$fontSize" fill="$c" filter="url(#neon-glow)">$v</text>
</svg>
"@
    [System.IO.File]::WriteAllText($filePath, $svg, [System.Text.Encoding]::UTF8)
}

Write-Host "Created $($numbers.Count) neon number icons in $dir!"
