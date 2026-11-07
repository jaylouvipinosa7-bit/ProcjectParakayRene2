param([string]$targetDll = "C:\Users\pc\Desktop\games ko to ya\Game Files\Mods\RunetifyPVZFusionMod.dll.original.bak")
Add-Type -Path "C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\net472\Mono.Cecil.dll"
Add-Type -Path "C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\net472\Mono.Cecil.Rocks.dll"

$assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($targetDll)
$type = $assembly.MainModule.Types | Where-Object { $_.Name -eq "ZombieSpawner" }
$m = $type.Methods | Where-Object { $_.Name -eq "AdjustLaneForTerrain" }

# In AdjustLaneForTerrain:
# Instruction 01: change ldc.i4.0 to ldc.i4.1
# That sets ldarg.3 (spawnOnLand) = true initially!
$inst01 = $m.Body.Instructions[1]
$inst01.OpCode = [Mono.Cecil.Cil.OpCodes]::Ldc_I4_1

# Instruction 50: change brfalse.s IL_00b3 to br.s IL_00b3
# That skips forcing the water check! Water zombies can spawn on whatever lane was chosen!
$inst50 = $m.Body.Instructions[50]
$inst50.OpCode = [Mono.Cecil.Cil.OpCodes]::Br_S
# Target remains instruction 75 (IL_00b3)

# Next, in SetZombie:
$setZombie = $type.Methods | Where-Object { $_.Name -eq "SetZombie" }

# In SetZombie:
# Instruction 0085: ldloc.1
# Currently: TypeMgr.AmphibiousZombieToLand.Add(type, type)
# When type is 234 or 71, it adds to AmphibiousZombieToLand.
# But does the game have a land counterpart, or should we make sure DuckZombies also maps it, or the game's SetZombie can take it?
# In fact, AmphibiousZombieToLand maps: Amphibious Water Zombie -> Land Zombie!
# In the original game:
# SnorkelZombie -> Zombie, DolphinZombie -> PoleVaultingZombie, etc.
# But for custom fusion zombies like UltimateImpKing (234) and BoatImp (71), the developers never added them to AmphibiousZombieToLand in TypeMgr!
# So when SetZombie called TypeMgr.AmphibiousZombieToLand.Add(234, 234), it registers 234 as its OWN land counterpart!
# And then CreateZombie.SetZombie checks AmphibiousZombieToLand and says "Ah! On land, type 234 maps to type 234!"
# So it spawns type 234 directly on land!

$outPath = "C:\Users\pc\Desktop\games ko to ya\Game Files\Mods\RENEarnPVZFusionMod.dll.patched"
$assembly.Write($outPath)
Write-Host "Wrote updated patched DLL to $outPath"
