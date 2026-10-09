$cards = Get-Content "cards.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$missing = 0
foreach ($c in $cards) {
    $img = $c.funcImg -replace '/', '\'
    if (-not (Test-Path $img)) {
        Write-Output "Missing card funcImg: $($c.funcName) ($($c.commands)) -> $($c.funcImg)"
        $missing++
    }
}
Write-Output "Cards tested: $($cards.Count), Missing images: $missing"
