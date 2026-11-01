Add-Type -Path "C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\net472\Mono.Cecil.dll"
Add-Type -Path "C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\net472\Mono.Cecil.Rocks.dll"

$gameDir = "C:\Users\pc\Desktop\games ko to ya\Game Files"
$srcDll = "C:\Users\pc\Desktop\games ko to ya\Game Files\Mods\RENEarnPVZFusionMod.patched.dll"
$outDll = "C:\Users\pc\Downloads\ano na\core\tools\out_debug.dll"

$bytes = [System.IO.File]::ReadAllBytes($srcDll)
$ms = [System.IO.MemoryStream]::new($bytes)
$assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($ms)
$module = $assembly.MainModule

$assemblyCSharp = [Mono.Cecil.AssemblyDefinition]::ReadAssembly("$gameDir\MelonLoader\Il2CppAssemblies\Assembly-CSharp.dll")
$unityCore = [Mono.Cecil.AssemblyDefinition]::ReadAssembly("$gameDir\MelonLoader\Il2CppAssemblies\UnityEngine.CoreModule.dll")

$zombieType = $assemblyCSharp.MainModule.Types | Where-Object { $_.Name -eq "Zombie" }
$timeType = $unityCore.MainModule.Types | Where-Object { $_.Name -eq "Time" }
$compType = $unityCore.MainModule.Types | Where-Object { $_.Name -eq "Component" }
$transType = $unityCore.MainModule.Types | Where-Object { $_.Name -eq "Transform" }
$vec3Type = $unityCore.MainModule.Types | Where-Object { $_.Name -eq "Vector3" }
$objType = $unityCore.MainModule.Types | Where-Object { $_.Name -eq "Object" }

$ref_op_Equality = ($objType.Methods | Where-Object { $_.Name -eq "op_Equality" -and $_.Parameters.Count -eq 2 } | Select-Object -First 1)
$ref_get_theZombieType = ($zombieType.Methods | Where-Object { $_.Name -eq "get_theZombieType" } | Select-Object -First 1)
$ref_get_theSpeed = ($zombieType.Methods | Where-Object { $_.Name -eq "get_theSpeed" } | Select-Object -First 1)
$ref_set_theSpeed = ($zombieType.Methods | Where-Object { $_.Name -eq "set_theSpeed" } | Select-Object -First 1)
$ref_get_theOriginSpeed = ($zombieType.Methods | Where-Object { $_.Name -eq "get_theOriginSpeed" } | Select-Object -First 1)
$ref_set_theOriginSpeed = ($zombieType.Methods | Where-Object { $_.Name -eq "set_theOriginSpeed" } | Select-Object -First 1)
$ref_get_isAttacking = ($zombieType.Methods | Where-Object { $_.Name -eq "get_isAttacking" } | Select-Object -First 1)
$ref_get_beforeDying = ($zombieType.Methods | Where-Object { $_.Name -eq "get_beforeDying" } | Select-Object -First 1)
$ref_get_theHealth = ($zombieType.Methods | Where-Object { $_.Name -eq "get_theHealth" } | Select-Object -First 1)
$ref_get_butterSpeed = ($zombieType.Methods | Where-Object { $_.Name -eq "get_butterSpeed" } | Select-Object -First 1)
$ref_get_freezeSpeed = ($zombieType.Methods | Where-Object { $_.Name -eq "get_freezeSpeed" } | Select-Object -First 1)
$ref_get_coldSpeed = ($zombieType.Methods | Where-Object { $_.Name -eq "get_coldSpeed" } | Select-Object -First 1)
$ref_get_isMindControlled = ($zombieType.Methods | Where-Object { $_.Name -eq "get_isMindControlled" } | Select-Object -First 1)
$ref_get_fixedDeltaTime = ($timeType.Methods | Where-Object { $_.Name -eq "get_fixedDeltaTime" } | Select-Object -First 1)
$ref_get_transform = ($compType.Methods | Where-Object { $_.Name -eq "get_transform" } | Select-Object -First 1)
$ref_get_position = ($transType.Methods | Where-Object { $_.Name -eq "get_position" } | Select-Object -First 1)
$ref_set_position = ($transType.Methods | Where-Object { $_.Name -eq "set_position" -and $_.Parameters.Count -eq 1 } | Select-Object -First 1)
$ref_field_x = ($vec3Type.Fields | Where-Object { $_.Name -eq "x" } | Select-Object -First 1)

$m_op_Equality = $module.ImportReference($ref_op_Equality)
$m_get_theZombieType = $module.ImportReference($ref_get_theZombieType)
$m_get_theSpeed = $module.ImportReference($ref_get_theSpeed)
$m_set_theSpeed = $module.ImportReference($ref_set_theSpeed)
$m_get_theOriginSpeed = $module.ImportReference($ref_get_theOriginSpeed)
$m_set_theOriginSpeed = $module.ImportReference($ref_set_theOriginSpeed)
$m_get_isAttacking = $module.ImportReference($ref_get_isAttacking)
$m_get_beforeDying = $module.ImportReference($ref_get_beforeDying)
$m_get_theHealth = $module.ImportReference($ref_get_theHealth)
$m_get_butterSpeed = $module.ImportReference($ref_get_butterSpeed)
$m_get_freezeSpeed = $module.ImportReference($ref_get_freezeSpeed)
$m_get_coldSpeed = $module.ImportReference($ref_get_coldSpeed)
$m_get_isMindControlled = $module.ImportReference($ref_get_isMindControlled)
$m_get_fixedDeltaTime = $module.ImportReference($ref_get_fixedDeltaTime)
$m_get_transform = $module.ImportReference($ref_get_transform)
$m_get_position = $module.ImportReference($ref_get_position)
$m_set_position = $module.ImportReference($ref_set_position)
$m_field_x = $module.ImportReference($ref_field_x)
$m_vec3Type = $module.ImportReference($vec3Type)

# Logger Msg reference
$loggerRef = $assembly.MainModule.GetMemberReferences() | Where-Object { $_.DeclaringType.FullName -like "*MelonLogger*" -and $_.Name -eq "Msg" -and $_.Parameters.Count -eq 1 } | Select-Object -First 1

$patchesType = $module.Types | Where-Object { $_.Name -eq "Patches" }

# In FixedUpdate, let's inject a direct, unconditional check for 234 and submarines:
$fixedUpdateMethod = $patchesType.Methods | Where-Object { $_.Name -eq "FixedUpdate" }
$fIl = $fixedUpdateMethod.Body.GetILProcessor()

while ($fixedUpdateMethod.Body.Instructions.Count -gt 7) {
    $fixedUpdateMethod.Body.Instructions.RemoveAt($fixedUpdateMethod.Body.Instructions.Count - 1)
}

$retInst = $fixedUpdateMethod.Body.Instructions[6]

$fixedUpdateMethod.Body.InitLocals = $true
$fixedUpdateMethod.Body.Variables.Clear()

$v_speed = [Mono.Cecil.Cil.VariableDefinition]::new($module.TypeSystem.Single)
$v_dir = [Mono.Cecil.Cil.VariableDefinition]::new($module.TypeSystem.Single)
$v_dx = [Mono.Cecil.Cil.VariableDefinition]::new($module.TypeSystem.Single)
$v_pos = [Mono.Cecil.Cil.VariableDefinition]::new($m_vec3Type)
$v_type = [Mono.Cecil.Cil.VariableDefinition]::new($module.TypeSystem.Int32)

$fixedUpdateMethod.Body.Variables.Add($v_speed)
$fixedUpdateMethod.Body.Variables.Add($v_dir)
$fixedUpdateMethod.Body.Variables.Add($v_dx)
$fixedUpdateMethod.Body.Variables.Add($v_pos)
$fixedUpdateMethod.Body.Variables.Add($v_type)

$lbl_fu_ret = $retInst
$lbl_is_water_zombie = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Nop)
$lbl_fu_have_speed = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Nop)
$lbl_fu_check_dir = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Nop)
$lbl_fu_calc_dx = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Nop)

$newInsts = [System.Collections.Generic.List[Mono.Cecil.Cil.Instruction]]::new()

# Step 1: __instance == null
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldnull))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Call, $m_op_Equality))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Brtrue, $lbl_fu_ret))

# Step 2: Get type int into V_4
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_get_theZombieType))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Conv_I4))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stloc, $v_type))

# Check if V_4 matches any water/submarine type:
# 234 (UltimateImpKing)
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $v_type))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_I4, [int]234))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Beq, $lbl_is_water_zombie))

# 314 (Submarine_c2)
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $v_type))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_I4, [int]314))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Beq, $lbl_is_water_zombie))

# Check all other submarine and water IDs:
$otherIds = @(11, 12, 13, 14, 17, 19, 20, 27, 51, 59, 61, 71, 76, 113, 200, 202, 211, 214, 216, 218, 235, 237, 239, 240, 249, 262, 310, 311, 312, 313, 315, 316, 317, 333, 334, 335)
foreach ($id in $otherIds) {
    $newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $v_type))
    $newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_I4, [int]$id))
    $newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Beq, $lbl_is_water_zombie))
}

# If no match -> return
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Br, $lbl_fu_ret))

# MATCHED WATER/SUBMARINE ZOMBIE!
$newInsts.Add($lbl_is_water_zombie)

# LOG THAT IT WAS DETECTED!
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldstr, "[WATER_MOVE] Water/Submarine zombie detected! Moving..."))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Call, $loggerRef))

# Check dying or dead
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_get_beforeDying))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Brtrue, $lbl_fu_ret))

$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_get_theHealth))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_I4_0))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Conv_I8))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ble, $lbl_fu_ret))

# Check frozen or buttered
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_get_butterSpeed))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_R4, [float]0.0))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Bgt_Un, $lbl_fu_ret))

$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_get_freezeSpeed))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_R4, [float]0.0))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Bgt_Un, $lbl_fu_ret))

# NOTE: Do NOT return on isAttacking unless speed is needed for attack. But let's check:
# If isAttacking is true, return:
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_get_isAttacking))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Brtrue, $lbl_fu_ret))

# Speed
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_get_theSpeed))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stloc, $v_speed))

$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $v_speed))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_R4, [float]0.05))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Bgt_Un, $lbl_fu_have_speed))

$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_R4, [float]0.35))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_set_theOriginSpeed))

$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_R4, [float]0.35))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_set_theSpeed))

$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_R4, [float]0.35))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stloc, $v_speed))

$newInsts.Add($lbl_fu_have_speed)

# Cold
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_get_coldSpeed))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_R4, [float]0.0))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ble_Un, $lbl_fu_check_dir))

$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $v_speed))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_R4, [float]0.5))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Mul))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stloc, $v_speed))

$newInsts.Add($lbl_fu_check_dir)

# Direction
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_R4, [float]-1.0))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stloc, $v_dir))

$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_get_isMindControlled))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Brfalse, $lbl_fu_calc_dx))

$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_R4, [float]1.0))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stloc, $v_dir))

$newInsts.Add($lbl_fu_calc_dx)

# dx
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $v_dir))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $v_speed))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Mul))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Call, $m_get_fixedDeltaTime))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Mul))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stloc, $v_dx))

# World position
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_get_transform))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Dup))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_get_position))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stloc, $v_pos))

$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloca, $v_pos))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Dup))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldfld, $m_field_x))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $v_dx))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Add))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stfld, $m_field_x))

$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $v_pos))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_set_position))

foreach ($inst in $newInsts) {
    $fIl.InsertBefore($retInst, $inst)
}

$assembly.Write($outDll)
Write-Host "SUCCESS: Written $outDll Size: $((Get-Item $outDll).Length)"

# Deploy
Copy-Item $outDll "$gameDir\Mods\RENEarnPVZFusionMod.dll" -Force
Copy-Item $outDll "$gameDir\Mods\RunetifyPVZFusionMod.dll" -Force
Copy-Item $outDll "C:\Users\pc\Downloads\ano na\core\mods\pvz_fusion_4\RENEarnPVZFusionMod.dll" -Force
Write-Host "DEPLOYED TO ALL DIRS!"
