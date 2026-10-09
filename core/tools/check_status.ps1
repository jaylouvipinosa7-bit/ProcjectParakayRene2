Select-String -Path 'c:\Users\pc\Downloads\ano na\app.html' -Pattern 'openAddGiftModal|openEditGiftModal|function openGiftModal|giftModal.*active|selectActionCategory' | ForEach-Object {
    $line = $_.Line.Trim()
    if ($line.Length -gt 140) { $line = $line.Substring(0, 140) }
    Write-Host "$($_.LineNumber): $line"
}
