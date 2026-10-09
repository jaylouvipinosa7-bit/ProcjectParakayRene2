$asarPath = "C:\Program Files\Stream To Earn\resources\app.asar"
$fs = [System.IO.File]::OpenRead($asarPath)
$br = New-Object System.IO.BinaryReader($fs)

$magic = $br.ReadUInt32()
$size1 = $br.ReadUInt32()
$size2 = $br.ReadUInt32()
$headerSize = $br.ReadUInt32()

$headerBytes = $br.ReadBytes($headerSize)
$headerStr = [System.Text.Encoding]::UTF8.GetString($headerBytes)
$headerObj = $headerStr | ConvertFrom-Json

$baseOffset = 16 + $headerSize
$destDir = "c:\Users\pc\Downloads\ano na\s2e_unpacked"
New-Item -ItemType Directory -Force -Path $destDir | Out-Null

function Extract-Node($node, $curPath) {
    if ($node.files) {
        $dirPath = Join-Path $curPath ""
        if (-not (Test-Path $dirPath)) { New-Item -ItemType Directory -Force -Path $dirPath | Out-Null }
        foreach ($prop in $node.files.PSObject.Properties) {
            $name = $prop.Name
            if ($name -eq "node_modules") { continue }
            Extract-Node $prop.Value (Join-Path $curPath $name)
        }
    } else {
        # File
        $offset = [int64]$node.offset
        $size = [int64]$node.size
        $fs.Seek($baseOffset + $offset, [System.IO.SeekOrigin]::Begin) | Out-Null
        $data = $br.ReadBytes([int]$size)
        [System.IO.File]::WriteAllBytes($curPath, $data)
        Write-Output "Extracted: $curPath ($size bytes)"
    }
}

Extract-Node $headerObj $destDir
$fs.Close()
Write-Output "Unpacking completed!"
