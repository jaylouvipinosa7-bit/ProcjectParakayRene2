$appHtmlPath = "core/app.html"
$content = [System.IO.File]::ReadAllText((Resolve-Path $appHtmlPath).Path, [System.Text.Encoding]::UTF8)

$replacements = @(
    @{ Old = 'title="Import events or triggers from S2E, TikFinity, and other applications"'; New = 'title="Import events or triggers from TikFinity, JSON, and preset files"' },
    @{ Old = 'title="Export triggers to JSON for S2E or other applications"'; New = 'title="Export triggers to JSON file or preset"' },
    @{ Old = 'title="Allow this event/trigger to be imported or shared across applications like S2E"'; New = 'title="Allow this event/trigger to be imported or shared"' },
    @{ Old = 'title="Enable to allow this event to be imported into any application like S2E and other apps"'; New = 'title="Enable to allow this event to be imported into other apps or presets"' },
    @{ Old = 'Import triggers and summon actions from <strong>S2E / TikFinity</strong>'; New = 'Import triggers and summon actions from <strong>TikFinity or Preset JSON</strong>' },
    @{ Old = "placeholder='Paste S2E Event Code (e.g. 6ab90a09802d615caa9b8877) or full S2E JSON payload...'"; New = "placeholder='Paste Preset Code (e.g. 6ab90a09802d615caa9b8877) or JSON payload...'" },
    @{ Old = '🎯 S2E Ice Cream (Snow Monster)'; New = '🎯 Preset: Ice Cream (Snow Monster)' },
    @{ Old = '🎯 S2E 50K Likes Milestone'; New = '🎯 Preset: 50K Likes Milestone' },
    @{ Old = 'Share code and JSON schema compatible with <strong>S2E / TikFinity</strong>'; New = 'Share code and JSON schema compatible with <strong>Live Stream Studio & TikFinity</strong>' },
    @{ Old = '<span>🎯 S2E Share / Preset Code (24-Hex)</span>'; New = '<span>🎯 Preset Share Code (24-Hex)</span>' },
    @{ Old = 'onclick="setSliceCategory(''all'')">All / S2E (Recommended)</button>'; New = 'onclick="setSliceCategory(''all'')">All Cards (Recommended)</button>' },
    @{ Old = 'title="Import Allowed: Any app like S2E can import or trigger this event"'; New = 'title="Import Allowed: Presets can import or trigger this event"' },
    @{ Old = 'title="Export / Copy Event for S2E or other apps"'; New = 'title="Export / Copy Event"' },
    @{ Old = "engineStatus.innerText = 'MelonLoader + Runetify Mod Linked & Active';"; New = "engineStatus.innerText = 'MelonLoader + RENEarn In-Game Mod Linked & Active';" },
    @{ Old = "badge.innerText = 'S2E Code';"; New = "badge.innerText = 'Preset Code';" },
    @{ Old = '<span>⏳</span> Resolving RENEarn (S2E) Code: <code>${s2eCode}</code>...'; New = '<span>⏳</span> Resolving Preset Code: <code>${s2eCode}</code>...' },
    @{ Old = '<strong>S2E Code detected:</strong> <code>${s2eCode}</code><br>Preset not found on RENEarn cloud or local database. If you have the raw event JSON from S2E, you can paste it directly.'; New = '<strong>Preset Code detected:</strong> <code>${s2eCode}</code><br>Preset not found on cloud or local database. If you have the raw event JSON, you can paste it directly.' },
    @{ Old = 'Failed to resolve S2E code: '; New = 'Failed to resolve preset code: ' },
    @{ Old = 'showToast("Copied S2E Code to clipboard: " + code, "OK");'; New = 'showToast("Copied Preset Code to clipboard: " + code, "OK");' },
    @{ Old = 'showToast("Copied S2E JSON payload to clipboard!", "OK");'; New = 'showToast("Copied Preset JSON to clipboard!", "OK");' },
    @{ Old = 'showToast("Downloaded S2E preset JSON file!", "OK");'; New = 'showToast("Downloaded preset JSON file!", "OK");' }
)

$count = 0
foreach ($r in $replacements) {
    if ($content.Contains($r.Old)) {
        $content = $content.Replace($r.Old, $r.New)
        $count++
    }
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Resolve-Path $appHtmlPath).Path, $content, $utf8NoBom)
Write-Host "app.html updated: $count strings replaced."

$sidePath = "core/overlay-side.html"
if (Test-Path $sidePath) {
    $sContent = [System.IO.File]::ReadAllText((Resolve-Path $sidePath).Path, [System.Text.Encoding]::UTF8)
    if ($sContent.Contains("Icons Only (S2E)")) {
        $sContent = $sContent.Replace("Icons Only (S2E)", "Icons Only")
        [System.IO.File]::WriteAllText((Resolve-Path $sidePath).Path, $sContent, $utf8NoBom)
        Write-Host "overlay-side.html updated."
    }
}

$s2ePath = "core/s2e-overlay.html"
if (Test-Path $s2ePath) {
    $s2Content = [System.IO.File]::ReadAllText((Resolve-Path $s2ePath).Path, [System.Text.Encoding]::UTF8)
    if ($s2Content.Contains("<title>StreamToEarn PvZ TikTok LIVE Overlay</title>")) {
        $s2Content = $s2Content.Replace("<title>StreamToEarn PvZ TikTok LIVE Overlay</title>", "<title>RENEarn Live Stream Overlay</title>")
        [System.IO.File]::WriteAllText((Resolve-Path $s2ePath).Path, $s2Content, $utf8NoBom)
        Write-Host "s2e-overlay.html updated."
    }
}
