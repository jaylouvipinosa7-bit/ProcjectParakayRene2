Add-Type -Path "C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\net472\Mono.Cecil.dll"
Add-Type -Path "C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\net472\Mono.Cecil.Rocks.dll"

$gameDir = "C:\Users\pc\Desktop\games ko to ya\Game Files"
$srcDll = "C:\Users\pc\Desktop\games ko to ya\Game Files\Mods\RENEarnPVZFusionMod.patched.dll"
$outDll = "C:\Users\pc\Downloads\ano na\core\tools\out_water_movement_v3.dll"

Write-Host "Reading assembly $srcDll..."
$bytes = [System.IO.File]::ReadAllBytes($srcDll)
$ms = [System.IO.MemoryStream]::new($bytes)
$assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($ms)
$module = $assembly.MainModule

# Load reference assemblies
$assemblyCSharp = [Mono.Cecil.AssemblyDefinition]::ReadAssembly("$gameDir\MelonLoader\Il2CppAssemblies\Assembly-CSharp.dll")
$unityCore = [Mono.Cecil.AssemblyDefinition]::ReadAssembly("$gameDir\MelonLoader\Il2CppAssemblies\UnityEngine.CoreModule.dll")

# Find types
$zombieType = $assemblyCSharp.MainModule.Types | Where-Object { $_.Name -eq "Zombie" }
$timeType = $unityCore.MainModule.Types | Where-Object { $_.Name -eq "Time" }
$compType = $unityCore.MainModule.Types | Where-Object { $_.Name -eq "Component" }
$transType = $unityCore.MainModule.Types | Where-Object { $_.Name -eq "Transform" }
$vec3Type = $unityCore.MainModule.Types | Where-Object { $_.Name -eq "Vector3" }
$objType = $unityCore.MainModule.Types | Where-Object { $_.Name -eq "Object" }
$typeMgrType = $assemblyCSharp.MainModule.Types | Where-Object { $_.Name -eq "TypeMgr" }
$enumZombieType = $assemblyCSharp.MainModule.Types | Where-Object { $_.Name -eq "ZombieType" }

# Find methods & fields
$ref_op_Equality = ($objType.Methods | Where-Object { $_.Name -eq "op_Equality" -and $_.Parameters.Count -eq 2 } | Select-Object -First 1)
$ref_get_theZombieType = ($zombieType.Methods | Where-Object { $_.Name -eq "get_theZombieType" } | Select-Object -First 1)
$ref_get_theOriginSpeed = ($zombieType.Methods | Where-Object { $_.Name -eq "get_theOriginSpeed" } | Select-Object -First 1)
$ref_set_theOriginSpeed = ($zombieType.Methods | Where-Object { $_.Name -eq "set_theOriginSpeed" } | Select-Object -First 1)
$ref_get_theSpeed = ($zombieType.Methods | Where-Object { $_.Name -eq "get_theSpeed" } | Select-Object -First 1)
$ref_set_theSpeed = ($zombieType.Methods | Where-Object { $_.Name -eq "set_theSpeed" } | Select-Object -First 1)
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
$ref_waterZombie = ($typeMgrType.Methods | Where-Object { $_.Name -eq "WaterZombie" -and $_.Parameters.Count -eq 1 } | Select-Object -First 1)

# Import references
$m_op_Equality = $module.ImportReference($ref_op_Equality)
$m_get_theZombieType = $module.ImportReference($ref_get_theZombieType)
$m_get_theOriginSpeed = $module.ImportReference($ref_get_theOriginSpeed)
$m_set_theOriginSpeed = $module.ImportReference($ref_set_theOriginSpeed)
$m_get_theSpeed = $module.ImportReference($ref_get_theSpeed)
$m_set_theSpeed = $module.ImportReference($ref_set_theSpeed)
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
$m_waterZombie = $module.ImportReference($ref_waterZombie)
$m_vec3Type = $module.ImportReference($vec3Type)
$m_enumZombieType = $module.ImportReference($enumZombieType)

Write-Host "All references imported successfully!"

# 1. Create IsWaterOrSubmarineZombie helper method on Patches
$patchesType = $module.Types | Where-Object { $_.Name -eq "Patches" }

$checkMethod = $patchesType.Methods | Where-Object { $_.Name -eq "IsWaterOrSubmarineZombie" }
if ($checkMethod) {
    $patchesType.Methods.Remove($checkMethod)
}

$helperMethod = [Mono.Cecil.MethodDefinition]::new(
    "IsWaterOrSubmarineZombie",
    [Mono.Cecil.MethodAttributes]"Public, Static",
    $module.TypeSystem.Boolean
)
$paramType = [Mono.Cecil.ParameterDefinition]::new("zombieType", [Mono.Cecil.ParameterAttributes]::None, $m_enumZombieType)
$helperMethod.Parameters.Add($paramType)

$body = [Mono.Cecil.Cil.MethodBody]::new($helperMethod)
$helperMethod.Body = $body
$helperMethod.Body.InitLocals = $true

$v_intType = [Mono.Cecil.Cil.VariableDefinition]::new($module.TypeSystem.Int32)
$helperMethod.Body.Variables.Add($v_intType)

$hIl = $helperMethod.Body.GetILProcessor()

$lbl_return_true = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_I4_1)
$lbl_return_false = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_I4_0)
$lbl_ret = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ret)

# Convert arg_0 to int and store in V_0
$hIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0))
$hIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Conv_I4))
$hIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stloc_0))

# All Submarines, Arks, Dolphins, Ducks, Water zombies
$exactIds = @(
    11, 12, 13, 14, 17, 19, 20, 27, 51, 59, 61, 71, 76, 113,
    200, 202, 211, 214, 216, 218, 234, 235, 237, 239, 240, 249, 262,
    310, 311, 312, 313, 314, 315, 316, 317, 333, 334, 335
)

foreach ($id in $exactIds) {
    $hIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc_0))
    $hIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_I4, [int]$id))
    $hIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Beq, $lbl_return_true))
}

# Also call TypeMgr.WaterZombie(zombieType)
$hIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0))
$hIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Call, $m_waterZombie))
$hIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Brtrue, $lbl_return_true))

# Return false
$hIl.Append($lbl_return_false)
$hIl.Append($lbl_ret)

# Return true
$hIl.Append($lbl_return_true)
$hIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ret))

$patchesType.Methods.Add($helperMethod)
$helperRef = $module.ImportReference($helperMethod)
Write-Host "Added and imported IsWaterOrSubmarineZombie helper method!"

# 2. Patch Patches.FixedUpdate with world pos.x translation
$fixedUpdateMethod = $patchesType.Methods | Where-Object { $_.Name -eq "FixedUpdate" }
$fIl = $fixedUpdateMethod.Body.GetILProcessor()

# Keep only the first 7 instructions (FixFlippedChild x2 + ret)
while ($fixedUpdateMethod.Body.Instructions.Count -gt 7) {
    $fixedUpdateMethod.Body.Instructions.RemoveAt($fixedUpdateMethod.Body.Instructions.Count - 1)
}

$retInst = $fixedUpdateMethod.Body.Instructions[6]

# Configure local variables
$fixedUpdateMethod.Body.InitLocals = $true
$fixedUpdateMethod.Body.Variables.Clear()

$v_speed = [Mono.Cecil.Cil.VariableDefinition]::new($module.TypeSystem.Single)
$v_dir = [Mono.Cecil.Cil.VariableDefinition]::new($module.TypeSystem.Single)
$v_dx = [Mono.Cecil.Cil.VariableDefinition]::new($module.TypeSystem.Single)
$v_pos = [Mono.Cecil.Cil.VariableDefinition]::new($m_vec3Type)

$fixedUpdateMethod.Body.Variables.Add($v_speed)
$fixedUpdateMethod.Body.Variables.Add($v_dir)
$fixedUpdateMethod.Body.Variables.Add($v_dx)
$fixedUpdateMethod.Body.Variables.Add($v_pos)

# Labels
$lbl_fu_ret = $retInst
$lbl_fu_have_speed = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Nop)
$lbl_fu_check_dir = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Nop)
$lbl_fu_calc_dx = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Nop)

$newInsts = [System.Collections.Generic.List[Mono.Cecil.Cil.Instruction]]::new()

# Step 1: Check __instance != null
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldnull))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Call, $m_op_Equality))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Brtrue, $lbl_fu_ret))

# Step 2: Check IsWaterOrSubmarineZombie(__instance.theZombieType)
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_get_theZombieType))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Call, $helperRef))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Brfalse, $lbl_fu_ret))

# Step 3: Check if isAttacking
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_get_isAttacking))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Brtrue, $lbl_fu_ret))

# Step 4: Check if beforeDying
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_get_beforeDying))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Brtrue, $lbl_fu_ret))

# Step 5: Check health > 0
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_get_theHealth))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_I4_0))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Conv_I8))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ble, $lbl_fu_ret))

# Step 6: Check butterSpeed == 0
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_get_butterSpeed))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_R4, [float]0.0))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Bgt_Un, $lbl_fu_ret))

# Step 7: Check freezeSpeed == 0
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_get_freezeSpeed))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_R4, [float]0.0))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Bgt_Un, $lbl_fu_ret))

# Step 8: Get and ensure speed (speed >= 0.05, else 0.35f)
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_get_theSpeed))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stloc, $v_speed))

$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $v_speed))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_R4, [float]0.05))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Bgt_Un, $lbl_fu_have_speed))

# Speed is < 0.05, set origin and current speed to 0.35f
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_R4, [float]0.35))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_set_theOriginSpeed))

$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_R4, [float]0.35))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_set_theSpeed))

$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_R4, [float]0.35))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stloc, $v_speed))

$newInsts.Add($lbl_fu_have_speed)

# Step 9: If coldSpeed > 0, speed *= 0.5
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_get_coldSpeed))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_R4, [float]0.0))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ble_Un, $lbl_fu_check_dir))

$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $v_speed))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_R4, [float]0.5))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Mul))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stloc, $v_speed))

$newInsts.Add($lbl_fu_check_dir)

# Step 10: Direction (default -1.0 moving left, if isMindControlled then 1.0 moving right)
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_R4, [float]-1.0))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stloc, $v_dir))

$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_get_isMindControlled))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Brfalse, $lbl_fu_calc_dx))

$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_R4, [float]1.0))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stloc, $v_dir))

$newInsts.Add($lbl_fu_calc_dx)

# Step 11: dx = dir * speed * Time.fixedDeltaTime
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $v_dir))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $v_speed))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Mul))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Call, $m_get_fixedDeltaTime))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Mul))
$newInsts.Add([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stloc, $v_dx))

# Step 12: Direct world position modification:
# Transform t = __instance.transform;
# Vector3 pos = t.position;
# pos.x += dx;
# t.position = pos;

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

# Insert all instructions before the final ret
foreach ($inst in $newInsts) {
    $fIl.InsertBefore($retInst, $inst)
}

Write-Host "Patches.FixedUpdate patched with DIRECT WORLD POSITION X TRANSLATION!"

# 3. Patch ZombieSpawner.SetZombie so speed is set immediately
$spawnerType = $module.Types | Where-Object { $_.Name -eq "ZombieSpawner" }
$setZombieMethod = $spawnerType.Methods | Where-Object { $_.Name -eq "SetZombie" }

$foundStloc4 = $false
$targetInst = $null
for ($i = 0; $i -lt $setZombieMethod.Body.Instructions.Count; $i++) {
    $inst = $setZombieMethod.Body.Instructions[$i]
    if ($inst.OpCode.Name -eq "stloc.s" -and $inst.Operand.Index -eq 4) {
        $targetInst = $setZombieMethod.Body.Instructions[$i + 1]
        $foundStloc4 = $true
        break
    }
}

if ($foundStloc4 -and $targetInst) {
    Write-Host "Found stloc.s V_4 in SetZombie. Injecting speed initialization for water/submarine zombies..."
    $zIl = $setZombieMethod.Body.GetILProcessor()
    $lbl_skip_init = $targetInst

    $v4 = $setZombieMethod.Body.Variables[4]
    $initInsts = @(
        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc_1),
        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Call, $helperRef),
        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Brfalse, $lbl_skip_init),

        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $v4),
        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldnull),
        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Call, $m_op_Equality),
        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Brtrue, $lbl_skip_init),

        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $v4),
        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_R4, [float]0.35),
        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_set_theOriginSpeed),

        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $v4),
        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_R4, [float]0.35),
        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_set_theSpeed)
    )

    foreach ($inst in $initInsts) {
        $zIl.InsertBefore($targetInst, $inst)
    }
    Write-Host "ZombieSpawner.SetZombie patched with initial speed!"
} else {
    Write-Warning "Could not find stloc.s V_4 in SetZombie"
}

# 4. Save patched DLL
Write-Host "Writing patched assembly to $outDll..."
$assembly.Write($outDll)
$fileSize = (Get-Item $outDll).Length
Write-Host "SUCCESS: Saved to $outDll! Size: $fileSize"

if ($fileSize -lt 50000) {
    Write-Error "ERROR: Output file size is too small ($fileSize bytes)!"
    exit 1
}

# Deploy immediately to game directories
$gameModsDir = "C:\Users\pc\Desktop\games ko to ya\Game Files\Mods"
$repoModsDir = "C:\Users\pc\Downloads\ano na\core\mods\pvz_fusion_4"

Copy-Item $outDll "$gameModsDir\RENEarnPVZFusionMod.dll" -Force
Write-Host "Deployed to $gameModsDir\RENEarnPVZFusionMod.dll"

Copy-Item $outDll "$gameModsDir\RunetifyPVZFusionMod.dll" -Force
Write-Host "Deployed to $gameModsDir\RunetifyPVZFusionMod.dll"

if (Test-Path $repoModsDir) {
    Copy-Item $outDll "$repoModsDir\RENEarnPVZFusionMod.dll" -Force
    Write-Host "Deployed to $repoModsDir\RENEarnPVZFusionMod.dll"
}

Write-Host "`nALL WATER AND SUBMARINE ZOMBIES FIXED TO MOVE DIRECTLY ON GROUND!" -ForegroundColor Green
