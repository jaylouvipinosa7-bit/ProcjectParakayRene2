$cmdMap = Get-Content "runetify_all_commands_map.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$missingCmds = 0

. ".\verify_150_items.ps1"

foreach ($it in $s2eItems) {
    $cmd = $it.cmd
    $foundMap = $cmdMap.$cmd
    if (-not $foundMap) {
        # Check without spawn_
        $clean = $cmd -replace '^spawn_', ''
        $foundMap = $cmdMap.$clean
    }
    if ($foundMap) {
        $it.endpoint = $foundMap.endpoint
        $it.effect = $foundMap.effect
    } else {
        $missingCmds++
        # Write-Output "Not in cmdMap: $($it.cmd)"
    }
}
Write-Output "Items matched with runetify command map: $($s2eItems.Count - $missingCmds) / $($s2eItems.Count)"
