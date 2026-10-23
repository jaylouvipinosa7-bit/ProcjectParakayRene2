$soundsDir = "c:\Users\pc\Downloads\ano na\core\sounds"
$shell = New-Object -ComObject Shell.Application
$folder = $shell.Namespace($soundsDir)

$files = Get-ChildItem $soundsDir -Filter "*anime*wow*"
foreach ($f in $files) {
    $item = $folder.ParseName($f.Name)
    $len = $folder.GetDetailsOf($item, 27)
    $hash = (Get-FileHash $f.FullName -Algorithm MD5).Hash
    Write-Host "$($f.Name) | Length: '$len' | Size: $($f.Length) | Hash: $hash"
}
