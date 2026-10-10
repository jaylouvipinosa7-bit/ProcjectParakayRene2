param()
$tmpl = Get-Content "pvz_fusion_template.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$cfg = Get-Content "pvz_fusion_config.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$vg = Get-Content "tiktok_gifts_verified.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$vgMap = @{}
$vgNameMap = @{}
foreach ($g in $vg) {
    if ($g.id) { $vgMap[[string]$g.id] = $g }
    if ($g.name) {
        $clean = ($g.name -replace '[^a-zA-Z0-9]','').ToLower()
        if (-not $vgNameMap.ContainsKey($clean)) { $vgNameMap[$clean] = $g }
    }
}

Write-Output "=== TEMPLATE GIFTS AUDIT ==="
$unmatched = @()
foreach ($g in $tmpl.gifts) {
    $hasId = -not [string]::IsNullOrWhiteSpace($g.giftId)
    $inVg = $hasId -and $vgMap.ContainsKey([string]$g.giftId)
    $cleanName = ($g.giftName -replace '[^a-zA-Z0-9]','').ToLower()
    $nameMatch = $vgNameMap.ContainsKey($cleanName)
    if ($g.actionType -ne "share" -and $g.eventType -ne "follow" -and $g.eventType -ne "team_plants_likes" -and $g.eventType -ne "team_zombies_likes" -and $g.eventType -ne "total_likes" -and $g.id -notin @("1","2","3","4","59","61")) {
        if (-not $inVg -and -not $nameMatch) {
            Write-Output "Card #$($g.id) '$($g.giftName)' (giftId='$($g.giftId)') NOT IN VERIFIED CATALOG!"
        }
    }
}
Write-Output "Done audit."
