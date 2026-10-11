Add-Type -Path "C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\net472\Mono.Cecil.dll"
$asmPath = "C:\Users\pc\Desktop\games ko to ya\Game Files\Mods\RunetifyPVZFusionMod.dll"
$assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($asmPath)

$t = $assembly.MainModule.Types | Where-Object { $_.Name -eq "WebServer" }
$m = $t.Methods | Where-Object { $_.Name -eq "InitializeHttpServer" }
foreach ($inst in $m.Body.Instructions) {
    if ($inst.OpCode.Name -eq "ldstr") {
        Write-Host "InitializeHttpServer ldstr: '$($inst.Operand)'"
    }
}
