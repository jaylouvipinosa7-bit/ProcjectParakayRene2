Add-Type -Path 'C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\net472\Mono.Cecil.dll'
$dll = 'C:\Users\pc\Downloads\ano na\core\tools\out_debug.dll'
$assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($dll)
$zs = $assembly.MainModule.Types | Where-Object { $_.Name -eq 'ZombieSpawner' }
$adj = $zs.Methods | Where-Object { $_.Name -eq 'AdjustLaneForTerrain' }
Write-Host "AdjustLaneForTerrain Instructions:"
foreach ($instr in $adj.Body.Instructions) {
    Write-Host "$($instr.OpCode) $($instr.Operand)"
}

