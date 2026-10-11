Add-Type -Path "C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\net472\Mono.Cecil.dll"
$asmPath = "C:\Users\pc\Desktop\games ko to ya\Game Files\Mods\RunetifyPVZFusionMod.dll"
$assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($asmPath)

Write-Host "=== STRINGS IN METHODS ==="
foreach ($module in $assembly.Modules) {
    foreach ($type in $module.Types) {
        foreach ($method in $type.Methods) {
            if ($method.Body) {
                foreach ($inst in $method.Body.Instructions) {
                    if ($inst.OpCode.Name -eq "ldstr" -and $inst.Operand -like "*Runetify*") {
                        Write-Host "$($type.Name).$($method.Name): '$($inst.Operand)'"
                    }
                }
            }
        }
    }
}
