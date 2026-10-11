Add-Type -Path "C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\net472\Mono.Cecil.dll"
$mlPath = "C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\net6\MelonLoader.dll"
$assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($mlPath)

$loggerType = $assembly.MainModule.Types | Where-Object { $_.Name -eq "MelonLogger" }
if ($loggerType) {
    Write-Host "=== MelonLogger Methods ==="
    foreach ($m in $loggerType.Methods) {
        Write-Host "$($m.ReturnType.Name) $($m.Name) ($($m.Parameters | ForEach-Object { "$($_.ParameterType.Name) $($_.Name)" } -join ', '))"
    }
}
