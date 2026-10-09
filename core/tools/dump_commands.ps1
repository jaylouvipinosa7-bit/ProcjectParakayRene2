$bytes = [System.IO.File]::ReadAllBytes('C:\Users\pc\AppData\Local\Runetify\runetify.exe')
$str = [System.Text.Encoding]::UTF8.GetString($bytes)
$chunk = $str.Substring(4765000, 15000)
$lines = $chunk -split "`n"
$lines | Select-Object -First 25
