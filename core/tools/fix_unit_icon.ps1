$enc = New-Object System.Text.UTF8Encoding($false)
$paths = @("cards.json", "core/cards.json")
foreach ($p in $paths) {
    if (Test-Path $p) {
        $full = (Resolve-Path $p).Path
        $cards = Get-Content $full -Raw | ConvertFrom-Json
        foreach ($c in $cards) {
            if ($c.id -eq "2") {
                $c | Add-Member -MemberType NoteProperty -Name "unitIcon" -Value "images/game-icons/pvz/spawn_trident_juggernut_gargantuar.webp" -Force
                $c.funcImg = "images/game-icons/pvz/spawn_trident_juggernut_gargantuar.webp"
            }
        }
        $json = $cards | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText($full, $json, $enc)
        Write-Host "Updated unitIcon in $p"
    }
}
