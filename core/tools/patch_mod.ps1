param([string]$targetDll = "C:\Users\pc\Desktop\games ko to ya\Game Files\Mods\RENEarnPVZFusionMod.dll")
Add-Type -Path "C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\net472\Mono.Cecil.dll"
Add-Type -Path "C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\net472\Mono.Cecil.Rocks.dll"

$assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($targetDll)
$type = $assembly.MainModule.Types | Where-Object { $_.Name -eq "ZombieSpawner" }
$m = $type.Methods | Where-Object { $_.Name -eq "AdjustLaneForTerrain" }

Write-Host "Modifying AdjustLaneForTerrain in $targetDll..."

# Instructions 48, 49, 50:
# 48 : ldarg.2 (ZombieType)
# 49 : call WaterZombie
# 50 : brfalse.s IL_00b3 (instruction 75)
# If we replace instruction 50 with `br` to instruction 75 (IL_00b3), then WaterZombie never forces lane redirection to water!
# AND for instruction 00:
# In AdjustLaneForTerrain:
# 00: ldarg.3
# 01: ldc.i4.0
# 02: stind.i1
# If we change 01 to `ldc.i4.1` (stind.i1 true), then spawnOnLand (V_3) is ALWAYS set to true!
# When spawnOnLand is true, SetZombie registers the zombie into AmphibiousZombieToLand!
# Which enables ANY amphibious/water zombie to successfully move and exist on land!

$inst01 = $m.Body.Instructions[1]
Write-Host "Original inst 01: $($inst01.OpCode.Name) $($inst01.Operand)"
$inst01.OpCode = [Mono.Cecil.Cil.OpCodes]::Ldc_I4_1
Write-Host "New inst 01: $($inst01.OpCode.Name) $($inst01.Operand)"

# Now instruction 50: change brfalse.s to br.s pointing to instruction 75
$inst50 = $m.Body.Instructions[50]
$target75 = $m.Body.Instructions[75]
Write-Host "Original inst 50: $($inst50.OpCode.Name) -> $($inst50.Operand.Offset)"
$inst50.OpCode = [Mono.Cecil.Cil.OpCodes]::Br_S
$inst50.Operand = $target75
Write-Host "New inst 50: $($inst50.OpCode.Name) -> $($inst50.Operand.Offset)"

# Recompute offsets
$m.Body.OptimizeMacros()

$assembly.Write("C:\Users\pc\Desktop\games ko to ya\Game Files\Mods\RENEarnPVZFusionMod.dll.patched")
Write-Host "Patched assembly successfully written to temporary file!"
