$m = Get-Content 'C:\Users\pc\AppData\Local\Runetify\game_mappings.json' -Raw | ConvertFrom-Json
$missing = @()
$found = 0
foreach ($item in $m.pvz_fusion) {
    if ($item.command) {
        $p = "c:\Users\pc\Downloads\ano na\images\game-icons\pvz\" + $item.command + ".webp"
        if (Test-Path $p) {
            $found++
        } else {
            $missing += $item.command
        }
    }
}
Write-Output "Found: $found"
Write-Output "Missing ($($missing.Count)): $($missing -join ', ')"
