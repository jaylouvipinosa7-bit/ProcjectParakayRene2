Add-Type -Path "C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\net472\Mono.Cecil.dll"
Add-Type -Path "C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\net472\Mono.Cecil.Rocks.dll"

$srcDll = "C:\Users\pc\Desktop\games ko to ya\Game Files\Mods\RunetifyPVZFusionMod.dll"
$dstDll = "C:\Users\pc\Desktop\games ko to ya\Game Files\Mods\RENEarnPVZFusionMod.dll"
$backupDll = "C:\Users\pc\Desktop\games ko to ya\Game Files\Mods\RunetifyPVZFusionMod.dll.original.bak"

if (-not (Test-Path $backupDll)) {
    Copy-Item $srcDll $backupDll -Force
    Write-Host "[BACKUP] Created backup of original mod at $backupDll" -ForegroundColor Green
}

# Read from backup to guarantee clean base
$bytes = [System.IO.File]::ReadAllBytes($backupDll)
$ms = [System.IO.MemoryStream]::new($bytes)
$assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($ms)

# 1. Update Assembly Attributes & MelonInfo
Write-Host "[1/4] Updating MelonInfo and Assembly Metadata to RENEarn..." -ForegroundColor Cyan
foreach ($attr in $assembly.CustomAttributes) {
    if ($attr.AttributeType.FullName -eq "MelonLoader.MelonInfoAttribute") {
        # Arg 1: Display Name -> "RENEarn Mod"
        # Arg 2: Version -> "1.2.0"
        # Arg 3: Author -> "RENEarn"
        $attr.ConstructorArguments[1] = [Mono.Cecil.CustomAttributeArgument]::new($assembly.MainModule.TypeSystem.String, "RENEarn Mod")
        $attr.ConstructorArguments[2] = [Mono.Cecil.CustomAttributeArgument]::new($assembly.MainModule.TypeSystem.String, "1.2.0")
        $attr.ConstructorArguments[3] = [Mono.Cecil.CustomAttributeArgument]::new($assembly.MainModule.TypeSystem.String, "RENEarn")
        Write-Host "   Updated MelonInfo: 'RENEarn Mod' v1.2.0 by RENEarn" -ForegroundColor Green
    }
    elseif ($attr.AttributeType.FullName -eq "System.Reflection.AssemblyTitleAttribute") {
        $attr.ConstructorArguments[0] = [Mono.Cecil.CustomAttributeArgument]::new($assembly.MainModule.TypeSystem.String, "RENEarnPVZFusionMod")
    }
    elseif ($attr.AttributeType.FullName -eq "System.Reflection.AssemblyDescriptionAttribute") {
        $attr.ConstructorArguments[0] = [Mono.Cecil.CustomAttributeArgument]::new($assembly.MainModule.TypeSystem.String, "RENEarn Mod for Plants vs Zombies Fusion Live Stream Studio")
    }
    elseif ($attr.AttributeType.FullName -eq "System.Reflection.AssemblyCompanyAttribute") {
        $attr.ConstructorArguments[0] = [Mono.Cecil.CustomAttributeArgument]::new($assembly.MainModule.TypeSystem.String, "RENEarn")
    }
    elseif ($attr.AttributeType.FullName -eq "System.Reflection.AssemblyProductAttribute") {
        $attr.ConstructorArguments[0] = [Mono.Cecil.CustomAttributeArgument]::new($assembly.MainModule.TypeSystem.String, "RENEarnPVZFusionMod")
    }
    elseif ($attr.AttributeType.FullName -eq "System.Reflection.AssemblyCopyrightAttribute") {
        $attr.ConstructorArguments[0] = [Mono.Cecil.CustomAttributeArgument]::new($assembly.MainModule.TypeSystem.String, "Copyright (c) RENEarn 2026")
    }
}

# 2. Update Startup Log in RunetifyMode.OnInitializeMelon
Write-Host "[2/4] Updating startup log in OnInitializeMelon..." -ForegroundColor Cyan
$mainType = $assembly.MainModule.Types | Where-Object { $_.Name -eq "RunetifyMode" }
$initMethod = $mainType.Methods | Where-Object { $_.Name -eq "OnInitializeMelon" }
if ($initMethod -and $initMethod.Body) {
    foreach ($inst in $initMethod.Body.Instructions) {
        if ($inst.OpCode.Name -eq "ldstr" -and $inst.Operand -like "*Runetify Mod has been loaded*") {
            $inst.Operand = "RENEarn PvZ Fusion Mod v1.2.0 loaded! Ready for live stream commands."
            Write-Host "   Replaced startup log string." -ForegroundColor Green
        }
    }
}

# 3. Update WebServer.HandleRequest to log summoned commands!
Write-Host "[3/4] Injecting live command summon logging into WebServer.HandleRequest..." -ForegroundColor Cyan
$webServerType = $assembly.MainModule.Types | Where-Object { $_.Name -eq "WebServer" }
$handleMethod = $webServerType.Methods | Where-Object { $_.Name -eq "HandleRequest" }

# Find references to MelonLogger.Msg
$msgMethod = $assembly.MainModule.GetMemberReferences() | Where-Object { $_.DeclaringType.FullName -like "*MelonLogger*" -and $_.Name -eq "Msg" } | Select-Object -First 1

# Import String.Concat(string, string, string, string)
$concat4Method = [string].GetMethod("Concat", [type[]]@([string], [string], [string], [string]))
$concat4Ref = $assembly.MainModule.ImportReference($concat4Method)

# Import Object.ToString()
$toStringMethod = [object].GetMethod("ToString", [type[]]@())
$toStringRef = $assembly.MainModule.ImportReference($toStringMethod)

if ($handleMethod -and $handleMethod.Body -and $msgMethod) {
    $il = $handleMethod.Body.GetILProcessor()

    # Find the TryGetValue call at index 121
    $tryGetIdx = -1
    for ($i = 0; $i -lt $handleMethod.Body.Instructions.Count; $i++) {
        $inst = $handleMethod.Body.Instructions[$i]
        if ($inst.OpCode.Name -eq "callvirt" -and $inst.Operand.Name -eq "TryGetValue") {
            $tryGetIdx = $i
            break
        }
    }

    if ($tryGetIdx -ge 0) {
        $pathField = $handleMethod.Body.Instructions[$tryGetIdx - 3].Operand
        $targetInst = $handleMethod.Body.Instructions[$tryGetIdx + 2] # The instruction right after brfalse.s

        # Look forward for the json field access
        $jsonField = $null
        for ($j = $tryGetIdx; $j -lt $tryGetIdx + 15; $j++) {
            $f = $handleMethod.Body.Instructions[$j].Operand
            if ($f -and $f.Name -eq "json") {
                $jsonField = $f
                break
            }
        }

        Write-Host "   Located TryGetValue at index $tryGetIdx. Target: $($targetInst.OpCode.Name) at offset $($targetInst.Offset)" -ForegroundColor Green
        Write-Host "   Path field: $($pathField.Name) | Json field: $($jsonField.Name)" -ForegroundColor Green

        $instLdstr1 = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldstr, ">>> [RENEarn Mod] Command Summoned: ")
        $instLdloc3 = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc_3)
        $instLdfldPath = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldfld, $pathField)
        $instLdstr2 = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldstr, " | Payload: ")
        $instLdloc3_2 = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc_3)
        $instLdfldJson = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldfld, $jsonField)
        $instCallToString = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $toStringRef)
        $instCallConcat = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Call, $concat4Ref)
        $instCallMsg = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Call, $msgMethod)

        $il.InsertBefore($targetInst, $instLdstr1)
        $il.InsertBefore($targetInst, $instLdloc3)
        $il.InsertBefore($targetInst, $instLdfldPath)
        $il.InsertBefore($targetInst, $instLdstr2)
        $il.InsertBefore($targetInst, $instLdloc3_2)
        $il.InsertBefore($targetInst, $instLdfldJson)
        $il.InsertBefore($targetInst, $instCallToString)
        $il.InsertBefore($targetInst, $instCallConcat)
        $il.InsertBefore($targetInst, $instCallMsg)

        Write-Host "   Successfully injected live command logging!" -ForegroundColor Green
    } else {
        Write-Warning "Could not find TryGetValue index"
    }
}

# 4. Save patched DLL
Write-Host "[4/4] Writing patched assemblies..." -ForegroundColor Cyan

# Save to destination RENEarnPVZFusionMod.dll
$assembly.Write($dstDll)
Write-Host "   Saved $dstDll" -ForegroundColor Green

# Also overwrite RunetifyPVZFusionMod.dll so MelonLoader loads RENEarn regardless of which file it checks!
try {
    $assembly.Write($srcDll)
    Write-Host "   Updated $srcDll" -ForegroundColor Green
} catch {
    Write-Host "   Note: $srcDll might be in use, writing to temporary and copying..." -ForegroundColor Yellow
    $tmpDll = Join-Path $env:TEMP "RunetifyPVZFusionMod.dll"
    $assembly.Write($tmpDll)
    Copy-Item $tmpDll $srcDll -Force -ErrorAction SilentlyContinue
}

# Copy deps.json for RENEarnPVZFusionMod
$srcDeps = "C:\Users\pc\Desktop\games ko to ya\Game Files\Mods\RunetifyPVZFusionMod.deps.json"
$dstDeps = "C:\Users\pc\Desktop\games ko to ya\Game Files\Mods\RENEarnPVZFusionMod.deps.json"
if (Test-Path $srcDeps) {
    Copy-Item $srcDeps $dstDeps -Force
    Write-Host "   Created $dstDeps" -ForegroundColor Green
}

# Create renearn_info.json in Game Files
$renearnInfoPath = "C:\Users\pc\Desktop\games ko to ya\Game Files\renearn_info.json"
$infoObj = @{
    versionName = "47"
    versionCode = 47
    info = "renearn.studio"
    game = "PvZFusion"
    modName = "RENEarn Mod"
    version = "1.2.0"
}
$infoObj | ConvertTo-Json | Set-Content $renearnInfoPath -Encoding UTF8
Write-Host "   Created $renearnInfoPath" -ForegroundColor Green

Write-Host "`nSUCCESS! RENEarn Mod built and deployed to game directory!" -ForegroundColor Green
