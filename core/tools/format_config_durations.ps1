$cfgFile = "c:\Users\pc\Downloads\ano na\core\pvz_fusion_config.json"
if (Test-Path $cfgFile) {
    $cfg = Get-Content -Raw $cfgFile | ConvertFrom-Json
    $changed = $false
    foreach ($g in $cfg.gifts) {
        if ($g.audio) {
            if ($g.audio.duration) {
                $d = [string]$g.audio.duration
                if ($d -match '(\d+):(\d+)(\.(\d+))?') {
                    $m = [int]$matches[1]
                    $s = [int]$matches[2]
                    $g.audio.duration = ("{0:D2}:{1:D2}:00" -f $m, $s)
                    $changed = $true
                } elseif ($d -match '(\d+)') {
                    $s = [int]$matches[1]
                    $g.audio.duration = ("00:{0:D2}:00" -f $s)
                    $changed = $true
                }
            }
        }
    }
    if ($changed) {
        $json = $cfg | ConvertTo-Json -Depth 20 -Compress
        [System.IO.File]::WriteAllText($cfgFile, $json, [System.Text.Encoding]::UTF8)
        Write-Host "Updated pvz_fusion_config.json durations."
    }
}
