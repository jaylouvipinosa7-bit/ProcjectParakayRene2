# search_hybrid.ps1 - Find all lines containing pvz_hybrid or Hybrid
$filePath = "c:\Users\pc\Downloads\ano na\core\app.html"
$bytes = [System.IO.File]::ReadAllBytes($filePath)
$html = [System.Text.Encoding]::UTF8.GetString($bytes)
$lines = $html -split "`n"

Write-Host "Total lines: $($lines.Length)"

for ($i = 0; $i -lt $lines.Length; $i++) {
    if ($lines[$i] -match 'pvz_hybrid|Hybrid|hybrid') {
        $ln = $i + 1
        $trimmed = $lines[$i].Trim()
        if ($trimmed.Length -gt 150) {
            $trimmed = $trimmed.Substring(0, 150) + "..."
        }
        Write-Host "L${ln}: $trimmed"
    }
}
