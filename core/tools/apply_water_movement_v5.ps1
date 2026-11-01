Add-Type -Path "C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\net472\Mono.Cecil.dll"
Add-Type -Path "C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\net472\Mono.Cecil.Rocks.dll"

$gameDir = "C:\Users\pc\Desktop\games ko to ya\Game Files"
$srcDll = "$gameDir\Mods\RENEarnPVZFusionMod.patched.dll"
$outDll = "C:\Users\pc\Downloads\ano na\core\tools\out_debug.dll"

Write-Host "Reading base assembly $srcDll..."
$bytes = [System.IO.File]::ReadAllBytes($srcDll)
$ms = [System.IO.MemoryStream]::new($bytes)
$assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($ms)
$module = $assembly.MainModule

$assemblyCSharp = [Mono.Cecil.AssemblyDefinition]::ReadAssembly("$gameDir\MelonLoader\Il2CppAssemblies\Assembly-CSharp.dll")
$unityCore = [Mono.Cecil.AssemblyDefinition]::ReadAssembly("$gameDir\MelonLoader\Il2CppAssemblies\UnityEngine.CoreModule.dll")

# 1. Grab resolved method references from ZombieDemageUtils.KillAllZombies
$zdu = $module.Types | Where-Object { $_.Name -eq "ZombieDemageUtils" }
$killMethod = $zdu.Methods | Where-Object { $_.Name -eq "KillAllZombies" }

$ref_get_zombieArray = ($killMethod.Body.Instructions | Where-Object { $_.Operand -and $_.Operand.ToString() -like "*get_zombieArray*" } | Select-Object -First 1).Operand
$ref_get_Item = ($killMethod.Body.Instructions | Where-Object { $_.Operand -and $_.Operand.ToString() -like "*get_Item*" } | Select-Object -First 1).Operand
$ref_get_Count = ($killMethod.Body.Instructions | Where-Object { $_.Operand -and $_.Operand.ToString() -like "*get_Count*" } | Select-Object -First 1).Operand
$ref_op_Inequality = ($killMethod.Body.Instructions | Where-Object { $_.Operand -and $_.Operand.ToString() -like "*op_Inequality*" } | Select-Object -First 1).Operand
$ref_isMindControlled = ($killMethod.Body.Instructions | Where-Object { $_.Operand -and $_.Operand.ToString() -like "*get_isMindControlled*" } | Select-Object -First 1).Operand

# 2. Grab references from UnityEngine & Assembly-CSharp
$zType = $assemblyCSharp.MainModule.Types | Where-Object { $_.Name -eq "Zombie" }
$timeType = $unityCore.MainModule.Types | Where-Object { $_.Name -eq "Time" }
$compType = $unityCore.MainModule.Types | Where-Object { $_.Name -eq "Component" }
$transType = $unityCore.MainModule.Types | Where-Object { $_.Name -eq "Transform" }
$vec3Type = $unityCore.MainModule.Types | Where-Object { $_.Name -eq "Vector3" }
$objType = $unityCore.MainModule.Types | Where-Object { $_.Name -eq "Object" }

$ref_op_Equality = ($objType.Methods | Where-Object { $_.Name -eq "op_Equality" -and $_.Parameters.Count -eq 2 } | Select-Object -First 1)
$ref_get_theZombieType = ($zType.Methods | Where-Object { $_.Name -eq "get_theZombieType" } | Select-Object -First 1)
$ref_get_inWater = ($zType.Methods | Where-Object { $_.Name -eq "get_inWater" } | Select-Object -First 1)
$ref_get_beforeDying = ($zType.Methods | Where-Object { $_.Name -eq "get_beforeDying" } | Select-Object -First 1)
$ref_get_butterSpeed = ($zType.Methods | Where-Object { $_.Name -eq "get_butterSpeed" } | Select-Object -First 1)
$ref_get_freezeSpeed = ($zType.Methods | Where-Object { $_.Name -eq "get_freezeSpeed" } | Select-Object -First 1)
$ref_get_coldSpeed = ($zType.Methods | Where-Object { $_.Name -eq "get_coldSpeed" } | Select-Object -First 1)
$ref_get_theSpeed = ($zType.Methods | Where-Object { $_.Name -eq "get_theSpeed" } | Select-Object -First 1)
$ref_set_theSpeed = ($zType.Methods | Where-Object { $_.Name -eq "set_theSpeed" } | Select-Object -First 1)
$ref_set_theOriginSpeed = ($zType.Methods | Where-Object { $_.Name -eq "set_theOriginSpeed" } | Select-Object -First 1)
$ref_AdjustPosition = ($zType.Methods | Where-Object { $_.Name -eq "AdjustPosition" } | Select-Object -First 1)
$ref_get_transform = ($compType.Methods | Where-Object { $_.Name -eq "get_transform" } | Select-Object -First 1)
$ref_get_position = ($transType.Methods | Where-Object { $_.Name -eq "get_position" } | Select-Object -First 1)
$ref_set_position = ($transType.Methods | Where-Object { $_.Name -eq "set_position" -and $_.Parameters.Count -eq 1 } | Select-Object -First 1)
$ref_field_x = ($vec3Type.Fields | Where-Object { $_.Name -eq "x" } | Select-Object -First 1)
$ref_get_deltaTime = ($timeType.Methods | Where-Object { $_.Name -eq "get_deltaTime" } | Select-Object -First 1)

# Import all needed references into our module
$m_op_Equality = $module.ImportReference($ref_op_Equality)
$m_get_theZombieType = $module.ImportReference($ref_get_theZombieType)
$m_get_inWater = $module.ImportReference($ref_get_inWater)
$m_get_beforeDying = $module.ImportReference($ref_get_beforeDying)
$m_get_butterSpeed = $module.ImportReference($ref_get_butterSpeed)
$m_get_freezeSpeed = $module.ImportReference($ref_get_freezeSpeed)
$m_get_coldSpeed = $module.ImportReference($ref_get_coldSpeed)
$m_get_theSpeed = $module.ImportReference($ref_get_theSpeed)
$m_set_theSpeed = $module.ImportReference($ref_set_theSpeed)
$m_set_theOriginSpeed = $module.ImportReference($ref_set_theOriginSpeed)
$m_AdjustPosition = $module.ImportReference($ref_AdjustPosition)
$m_get_transform = $module.ImportReference($ref_get_transform)
$m_get_position = $module.ImportReference($ref_get_position)
$m_set_position = $module.ImportReference($ref_set_position)
$m_field_x = $module.ImportReference($ref_field_x)
$m_get_deltaTime = $module.ImportReference($ref_get_deltaTime)
$m_vec3Type = $module.ImportReference($vec3Type)

$rawBoardType = ($assemblyCSharp.MainModule.Types | Where-Object { $_.Name -eq "Board" } | Select-Object -First 1)
$boardType = $module.ImportReference($rawBoardType)

Write-Host "All references imported successfully!"

# 3. Create helper method IsWaterOrSubmarineZombie(int type) on Board_Patch
$bpType = $module.Types | Where-Object { $_.Name -eq "Board_Patch" }

$oldHelper = $bpType.Methods | Where-Object { $_.Name -eq "IsWaterOrSubmarineZombie" }
if ($oldHelper) { $bpType.Methods.Remove($oldHelper) }

$helperMethod = [Mono.Cecil.MethodDefinition]::new(
    "IsWaterOrSubmarineZombie",
    [Mono.Cecil.MethodAttributes]"Public, Static",
    $module.TypeSystem.Boolean
)
$paramType = [Mono.Cecil.ParameterDefinition]::new("type", [Mono.Cecil.ParameterAttributes]::None, $module.TypeSystem.Int32)
$helperMethod.Parameters.Add($paramType)

$helperMethod.Body = [Mono.Cecil.Cil.MethodBody]::new($helperMethod)
$hIl = $helperMethod.Body.GetILProcessor()

$lbl_ret_true = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_I4_1)
$lbl_ret_false = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_I4_0)
$lbl_helper_ret = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ret)

# Water / Submarine Zombie IDs:
$waterIds = @(
    234, 235, 314, 310, 311, 312, 313,
    11, 12, 13, 14, 17, 19, 20, 27,
    51, 59, 61, 71, 76, 113, 200, 202,
    211, 214, 216, 218, 237, 239, 240, 249, 262,
    315, 316, 317, 333, 334, 335
)

foreach ($id in $waterIds) {
    $hIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0))
    $hIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_I4, [int]$id))
    $hIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Beq, $lbl_ret_true))
}

$hIl.Append($lbl_ret_false)
$hIl.Append($lbl_helper_ret)
$hIl.Append($lbl_ret_true)
$hIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ret))

$bpType.Methods.Add($helperMethod)
$m_IsWaterOrSubmarineZombie = $module.ImportReference($helperMethod)
Write-Host "Created Board_Patch.IsWaterOrSubmarineZombie(int type)"

# 4. Create UpdateWaterZombies(Il2Cpp.Board board) on Board_Patch
$oldUpdateMethod = $bpType.Methods | Where-Object { $_.Name -eq "UpdateWaterZombies" }
if ($oldUpdateMethod) { $bpType.Methods.Remove($oldUpdateMethod) }

$updateWaterMethod = [Mono.Cecil.MethodDefinition]::new(
    "UpdateWaterZombies",
    [Mono.Cecil.MethodAttributes]"Public, Static",
    $module.TypeSystem.Void
)
$paramBoard = [Mono.Cecil.ParameterDefinition]::new("board", [Mono.Cecil.ParameterAttributes]::None, $boardType)
$updateWaterMethod.Parameters.Add($paramBoard)

$updateWaterMethod.Body = [Mono.Cecil.Cil.MethodBody]::new($updateWaterMethod)
$updateWaterMethod.Body.InitLocals = $true

# Variables:
# V_0: list (List<Zombie>)
# V_1: count (int)
# V_2: dt (float)
# V_3: i (int)
# V_4: z (Zombie)
# V_5: type (int)
# V_6: speed (float)
# V_7: dir (float)
# V_8: dx (float)
# V_9: pos (Vector3)
$v_list = [Mono.Cecil.Cil.VariableDefinition]::new($ref_get_zombieArray.ReturnType)
$v_count = [Mono.Cecil.Cil.VariableDefinition]::new($module.TypeSystem.Int32)
$v_dt = [Mono.Cecil.Cil.VariableDefinition]::new($module.TypeSystem.Single)
$v_i = [Mono.Cecil.Cil.VariableDefinition]::new($module.TypeSystem.Int32)
$v_z = [Mono.Cecil.Cil.VariableDefinition]::new($m_AdjustPosition.DeclaringType)
$v_type = [Mono.Cecil.Cil.VariableDefinition]::new($module.TypeSystem.Int32)
$v_speed = [Mono.Cecil.Cil.VariableDefinition]::new($module.TypeSystem.Single)
$v_dir = [Mono.Cecil.Cil.VariableDefinition]::new($module.TypeSystem.Single)
$v_dx = [Mono.Cecil.Cil.VariableDefinition]::new($module.TypeSystem.Single)
$v_pos = [Mono.Cecil.Cil.VariableDefinition]::new($m_vec3Type)

$updateWaterMethod.Body.Variables.Add($v_list)
$updateWaterMethod.Body.Variables.Add($v_count)
$updateWaterMethod.Body.Variables.Add($v_dt)
$updateWaterMethod.Body.Variables.Add($v_i)
$updateWaterMethod.Body.Variables.Add($v_z)
$updateWaterMethod.Body.Variables.Add($v_type)
$updateWaterMethod.Body.Variables.Add($v_speed)
$updateWaterMethod.Body.Variables.Add($v_dir)
$updateWaterMethod.Body.Variables.Add($v_dx)
$updateWaterMethod.Body.Variables.Add($v_pos)

$uIl = $updateWaterMethod.Body.GetILProcessor()

$lbl_ret = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ret)
$lbl_dt_ok = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Nop)
$lbl_loop_check = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Nop)
$lbl_loop_body = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Nop)
$lbl_loop_inc = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Nop)
$lbl_speed_have = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Nop)
$lbl_dir_check = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Nop)
$lbl_dx_calc = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Nop)

# Step 1: board == null -> ret
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldnull))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Call, $m_op_Equality))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Brtrue, $lbl_ret))

# Step 2: list = board.zombieArray; if (list == null) return;
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $ref_get_zombieArray))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Dup))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stloc_0))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Brfalse, $lbl_ret))

# Step 3: count = list.Count; if (count <= 0) return;
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc_0))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $ref_get_Count))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Dup))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stloc_1))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_I4_0))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ble, $lbl_ret))

# Step 4: dt = Time.deltaTime; if (dt > 0.05f) dt = 0.02f;
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Call, $m_get_deltaTime))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Dup))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_R4, [float]0.05))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ble_S, $lbl_dt_ok))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Pop))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_R4, [float]0.02))
$uIl.Append($lbl_dt_ok)
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stloc_2))

# Step 5: i = 0; goto loop_check;
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_I4_0))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stloc_3))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Br, $lbl_loop_check))

# Step 6: Loop body
$uIl.Append($lbl_loop_body)

# z = list[i];
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc_0))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc_3))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $ref_get_Item))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stloc, $v_z))

# if (z == null) continue;
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $v_z))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldnull))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Call, $m_op_Equality))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Brtrue, $lbl_loop_inc))

# if (z.inWater) continue; (only move on land!)
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $v_z))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_get_inWater))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Brtrue, $lbl_loop_inc))

# if (z.beforeDying) continue;
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $v_z))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_get_beforeDying))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Brtrue, $lbl_loop_inc))

# if (z.butterSpeed > 0) continue;
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $v_z))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_get_butterSpeed))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_R4, [float]0.0))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Bgt_Un, $lbl_loop_inc))

# if (z.freezeSpeed > 0) continue;
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $v_z))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_get_freezeSpeed))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_R4, [float]0.0))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Bgt_Un, $lbl_loop_inc))

# type = (int)z.theZombieType;
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $v_z))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_get_theZombieType))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Conv_I4))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stloc, $v_type))

# if (!IsWaterOrSubmarineZombie(type)) continue;
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $v_type))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Call, $m_IsWaterOrSubmarineZombie))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Brfalse, $lbl_loop_inc))

# speed = z.theSpeed;
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $v_z))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_get_theSpeed))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stloc, $v_speed))

# if (speed < 0.1f) { z.theOriginSpeed = 0.65f; z.theSpeed = 0.65f; speed = 0.65f; }
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $v_speed))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_R4, [float]0.1))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Bgt_Un, $lbl_speed_have))

$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $v_z))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_R4, [float]0.65))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_set_theOriginSpeed))

$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $v_z))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_R4, [float]0.65))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_set_theSpeed))

$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_R4, [float]0.65))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stloc, $v_speed))

$uIl.Append($lbl_speed_have)

# if (z.coldSpeed > 0) speed *= 0.5f;
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $v_z))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_get_coldSpeed))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_R4, [float]0.0))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ble_Un, $lbl_dir_check))

$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $v_speed))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_R4, [float]0.5))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Mul))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stloc, $v_speed))

$uIl.Append($lbl_dir_check)

# dir = z.isMindControlled ? 1.0f : -1.0f;
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_R4, [float]-1.0))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stloc, $v_dir))

$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $v_z))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $ref_isMindControlled))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Brfalse, $lbl_dx_calc))

$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_R4, [float]1.0))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stloc, $v_dir))

$uIl.Append($lbl_dx_calc)

# dx = dir * speed * dt;
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $v_dir))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $v_speed))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Mul))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc_2)) # dt
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Mul))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stloc, $v_dx))

# pos = z.transform.position;
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $v_z))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_get_transform))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Dup)) # save transform on stack
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_get_position))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stloc, $v_pos))

# pos.x += dx;
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloca, $v_pos))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Dup))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldfld, $m_field_x))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $v_dx))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Add))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stfld, $m_field_x))

# transform.position = pos;
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $v_pos))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_set_position))

# z.AdjustPosition(pos);
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $v_z))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $v_pos))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $m_AdjustPosition))

# i++;
$uIl.Append($lbl_loop_inc)
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc_3))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_I4_1))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Add))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stloc_3))

# loop_check: if (i < count) goto loop_body;
$uIl.Append($lbl_loop_check)
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc_3))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc_1))
$uIl.Append([Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Blt, $lbl_loop_body))

$uIl.Append($lbl_ret)

$bpType.Methods.Add($updateWaterMethod)
$m_UpdateWaterZombies = $module.ImportReference($updateWaterMethod)
Write-Host "Created Board_Patch.UpdateWaterZombies(Il2Cpp.Board board)"

# 5. Hook UpdateWaterZombies into Board_Patch.Update AT INSTRUCTION 0 (UNCONDITIONAL FIRST ACTION)
$boardUpdateMethod = $bpType.Methods | Where-Object { $_.Name -eq "Update" -and $_.Parameters.Count -eq 1 }
$bIl = $boardUpdateMethod.Body.GetILProcessor()
$bFirstInst = $boardUpdateMethod.Body.Instructions[0]

# Insert ldarg.0; call UpdateWaterZombies; as the very first instructions so NO branch can ever skip it!
$bIl.InsertBefore($bFirstInst, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0))
$bIl.InsertBefore($bFirstInst, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Call, $m_UpdateWaterZombies))
Write-Host "Injected UNCONDITIONAL call to UpdateWaterZombies at START of Board_Patch.Update!"

# 6. Clean Patches.FixedUpdate to only have original 7 instructions
$patchesType = $module.Types | Where-Object { $_.Name -eq "Patches" }
$fixedUpdateMethod = $patchesType.Methods | Where-Object { $_.Name -eq "FixedUpdate" }
while ($fixedUpdateMethod.Body.Instructions.Count -gt 7) {
    $fixedUpdateMethod.Body.Instructions.RemoveAt($fixedUpdateMethod.Body.Instructions.Count - 1)
}
Write-Host "Cleaned Patches.FixedUpdate to original 7 instructions!"

# 7. In ZombieSpawner.SetZombie, adjust spawn position from 9.9f to 8.8f
$spawnerType = $module.Types | Where-Object { $_.Name -eq "ZombieSpawner" }
$setZombieMethod = $spawnerType.Methods | Where-Object { $_.Name -eq "SetZombie" }
$adjustedCount = 0
foreach ($inst in $setZombieMethod.Body.Instructions) {
    if ($inst.OpCode.Name -eq "ldc.r4" -and [Math]::Abs($inst.Operand - 9.9) -lt 0.01) {
        $inst.Operand = [float]8.8
        $adjustedCount++
    }
}
Write-Host "Adjusted $adjustedCount spawn X coordinates from 9.9f to 8.8f in ZombieSpawner.SetZombie!"

# 8. Save assembly to out_debug.dll
$assembly.Write($outDll)
$fileSize = (Get-Item $outDll).Length
Write-Host "SUCCESS: Written $outDll Size: $fileSize"

# 9. Stop game process if running so files can be overwritten
Get-Process -Name "PlantsVsZombiesRH" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 800

# 10. Deploy to all mod folders
Copy-Item $outDll "$gameDir\Mods\RENEarnPVZFusionMod.dll" -Force
Copy-Item $outDll "$gameDir\Mods\RunetifyPVZFusionMod.dll" -Force
Copy-Item $outDll "C:\Users\pc\Downloads\ano na\core\mods\pvz_fusion_4\RENEarnPVZFusionMod.dll" -Force
Write-Host "DEPLOYED TO ALL DIRS!" -ForegroundColor Green
