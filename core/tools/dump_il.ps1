Add-Type -Path "C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\net472\Mono.Cecil.dll"
$asmPath = "C:\Users\pc\Desktop\games ko to ya\Game Files\Mods\RunetifyPVZFusionMod.dll"
$assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($asmPath)

function Dump-MethodIL($typeName, $methodName) {
    Write-Host "`n=== $typeName.$methodName ===" -ForegroundColor Cyan
    $type = $assembly.MainModule.Types | Where-Object { $_.FullName -eq $typeName }
    $m = $type.Methods | Where-Object { $_.Name -eq $methodName }
    if ($m -and $m.Body) {
        foreach ($inst in $m.Body.Instructions) {
            Write-Host ("{0:x4}: {1,-15} {2}" -f $inst.Offset, $inst.OpCode, $inst.Operand)
        }
    }
}

Dump-MethodIL "RunetifyPVZFusionMod.RunetifyMode" "OnInitializeMelon"
Dump-MethodIL "RunetifyPVZFusionMod.WebServer" "InitializeHttpServer"
Dump-MethodIL "RunetifyPVZFusionMod.WebServer" "HandleRequest"
