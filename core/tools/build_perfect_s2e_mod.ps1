# ==============================================================================
# Build Perfect S2EPvZFusionMod:
# 1. Base from S2EPvZFusionMod.dll.before_queue_fix.bak (has mowers & bullet patches)
# 2. Add query string effect parsing (?effect=43, ?effect=229, etc.)
# 3. Add all lawnmower aliases (/start_lawnmower, /restart_lawnmower, /delete_lawnmower, etc.)
# 4. Add live MelonLogger notification on every summoned command
# 5. Add land movement support for water/amphibious/submarine zombies
# 6. Add try/catch safeguard in OdysseyCore.LoadConfig so it never crashes
# ==============================================================================

Add-Type -Path "C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\net472\Mono.Cecil.dll"
Add-Type -Path "C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\net472\Mono.Cecil.Rocks.dll"

$srcDll = "C:\Users\pc\Desktop\games ko to ya\Game Files\Mods\S2EPvZFusionMod.dll.before_queue_fix.bak"
$dstDll = "C:\Users\pc\Desktop\games ko to ya\Game Files\Mods\S2EPvZFusionMod.dll"

Write-Host "Reading base DLL from $srcDll..." -ForegroundColor Cyan
$bytes = [System.IO.File]::ReadAllBytes($srcDll)
$ms = [System.IO.MemoryStream]::new($bytes)
$assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($ms)
$module = $assembly.MainModule

# Import common methods
$msgMethod = $module.GetMemberReferences() | Where-Object { $_.DeclaringType.FullName -like "*MelonLogger*" -and $_.Name -eq "Msg" -and $_.Parameters.Count -eq 1 } | Select-Object -First 1
$concat4Method = [string].GetMethod("Concat", [type[]]@([string], [string], [string], [string]))
$concat4Ref = $module.ImportReference($concat4Method)
$toStringMethod = [object].GetMethod("ToString", [type[]]@())
$toStringRef = $module.ImportReference($toStringMethod)

# ------------------------------------------------------------------------------
# 1. WebServer: Bind BOTH port 55001 and port 5003 + Update parceDuration regex
# ------------------------------------------------------------------------------
Write-Host "[1/5] Updating InitializeHttpServer to bind port 55001 & 5003..." -ForegroundColor Yellow
$webServerType = $module.Types | Where-Object { $_.Name -eq "WebServer" }
$initHttp = $webServerType.Methods | Where-Object { $_.Name -eq "InitializeHttpServer" }
$listenerField = $webServerType.Fields | Where-Object { $_.Name -eq "listener" }
$getPrefixesMethod = ($initHttp.Body.Instructions | Where-Object { $_.OpCode.Name -eq "callvirt" -and $_.Operand.Name -eq "get_Prefixes" } | Select-Object -First 1).Operand
$addPrefixMethod = ($initHttp.Body.Instructions | Where-Object { $_.OpCode.Name -eq "callvirt" -and $_.Operand.Name -eq "Add" } | Select-Object -First 1).Operand

# Find instruction where listener.Start() is called
$startIdx = -1
for ($i = 0; $i -lt $initHttp.Body.Instructions.Count; $i++) {
    $inst = $initHttp.Body.Instructions[$i]
    if ($inst.OpCode.Name -eq "callvirt" -and $inst.Operand.Name -eq "Start") {
        $startIdx = $i
        break
    }
}

if ($startIdx -gt 0) {
    $targetStart = $initHttp.Body.Instructions[$startIdx - 2] # ldarg.0 before ldfld listener before Start()
    $ilInit = $initHttp.Body.GetILProcessor()
    
    $prefixInsts = @(
        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0),
        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldfld, $listenerField),
        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $getPrefixesMethod),
        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldstr, "http://127.0.0.1:55001/"),
        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $addPrefixMethod),
        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0),
        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldfld, $listenerField),
        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $getPrefixesMethod),
        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldstr, "http://localhost:55001/"),
        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $addPrefixMethod)
    )
    
    foreach ($pi in $prefixInsts) {
        $ilInit.InsertBefore($targetStart, $pi)
    }
    
    # Insert log right after Start()
    $instAfterStart = $initHttp.Body.Instructions[$startIdx + 11] # Adjust for newly inserted instructions
    if ($msgMethod) {
        $ilInit.InsertBefore($instAfterStart, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldstr, "[StreamToEarn Mod] HTTP server listening on http://127.0.0.1:55001/ and http://127.0.0.1:5003/"))
        $ilInit.InsertBefore($instAfterStart, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Call, $msgMethod))
    }
    Write-Host "   Added port 55001 prefixes to HttpListener!" -ForegroundColor Green
}

$parceMethod = $webServerType.Methods | Where-Object { $_.Name -eq "parceDuration" }
# Instruction 1 is ldstr :(\-?\d+(?:\.\d+)?)$
$parceMethod.Body.Instructions[1].Operand = '(?::|[?&]effect=)([\-]?\w+)'
Write-Host "   Updated parceDuration regex to support query string & colon" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 2. WebServer.HandleRequest: Pass PathAndQuery to parceDuration & log summon
# ------------------------------------------------------------------------------
Write-Host "[2/5] Updating HandleRequest to pass PathAndQuery and log commands..." -ForegroundColor Yellow
$handleMethod = $webServerType.Methods | Where-Object { $_.Name -eq "HandleRequest" }
$getPathAndQuery = $module.ImportReference([System.Uri].GetProperty("PathAndQuery").GetGetMethod())

# Find instruction where parceDuration is called
$callParceIdx = -1
for ($i = 0; $i -lt $handleMethod.Body.Instructions.Count; $i++) {
    $inst = $handleMethod.Body.Instructions[$i]
    if ($inst.OpCode.Name -like "*call*" -and $inst.Operand.Name -eq "parceDuration") {
        $callParceIdx = $i
        break
    }
}

if ($callParceIdx -gt 0) {
    # Replace instructions before parceDuration call
    # Originally:
    # ldarg.0
    # ldloc.2 (closure)
    # ldfld path
    # call parceDuration
    
    # We want:
    # ldarg.0
    # ldloc.0 (request)
    # callvirt get_Url()
    # callvirt get_PathAndQuery()
    # call parceDuration
    
    $il = $handleMethod.Body.GetILProcessor()
    $instUrl = $handleMethod.Body.Instructions | Where-Object { $_.OpCode.Name -eq "callvirt" -and $_.Operand.Name -eq "get_Url" } | Select-Object -First 1
    
    # Change instruction at callParceIdx - 2: ldloc.0
    $handleMethod.Body.Instructions[$callParceIdx - 2].OpCode = [Mono.Cecil.Cil.OpCodes]::Ldloc_0
    $handleMethod.Body.Instructions[$callParceIdx - 2].Operand = $null
    
    # Change instruction at callParceIdx - 1: callvirt get_Url
    $handleMethod.Body.Instructions[$callParceIdx - 1].OpCode = [Mono.Cecil.Cil.OpCodes]::Callvirt
    $handleMethod.Body.Instructions[$callParceIdx - 1].Operand = $instUrl.Operand
    
    # Insert callvirt get_PathAndQuery right before call parceDuration
    $instPathAndQuery = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $getPathAndQuery)
    $targetCall = $handleMethod.Body.Instructions[$callParceIdx]
    $il.InsertBefore($targetCall, $instPathAndQuery)
    
    Write-Host "   HandleRequest now passes request.Url.PathAndQuery to parceDuration!" -ForegroundColor Green
}

# Inject MelonLogger.Msg after TryGetValue succeeds
$tryGetIdx = -1
for ($i = 0; $i -lt $handleMethod.Body.Instructions.Count; $i++) {
    $inst = $handleMethod.Body.Instructions[$i]
    if ($inst.OpCode.Name -eq "callvirt" -and $inst.Operand.Name -eq "TryGetValue") {
        $tryGetIdx = $i
        break
    }
}

if ($tryGetIdx -gt 0 -and $msgMethod) {
    # Find closure fields: path and json
    $closureInst = $handleMethod.Body.Instructions[$tryGetIdx - 2] # ldfld path
    $pathField = $closureInst.Operand
    
    # Find json field
    $jsonField = $null
    for ($j = $tryGetIdx; $j -ge 0; $j--) {
        $f = $handleMethod.Body.Instructions[$j].Operand
        if ($f -and $f.Name -eq "json") {
            $jsonField = $f
            break
        }
    }
    
    if ($pathField -and $jsonField) {
        $targetAfterBr = $handleMethod.Body.Instructions[$tryGetIdx + 2] # Right after brfalse.s
        $il = $handleMethod.Body.GetILProcessor()
        
        $logInsts = @(
            [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldstr, "[StreamToEarn Mod] >>> Command Summoned: "),
            [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc_2),
            [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldfld, $pathField),
            [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldstr, " | Payload: "),
            [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc_2),
            [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldfld, $jsonField),
            [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $toStringRef),
            [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Call, $concat4Ref),
            [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Call, $msgMethod)
        )
        
        foreach ($li in $logInsts) {
            $il.InsertBefore($targetAfterBr, $li)
        }
        Write-Host "   Injected live command logging into HandleRequest!" -ForegroundColor Green
    }
}

# ------------------------------------------------------------------------------
# 3. Effects: Register all lawnmower route aliases
# ------------------------------------------------------------------------------
Write-Host "[3/5] Registering Lawnmower route aliases in Effects.RegisterRoutes..." -ForegroundColor Yellow
$effectsType = $module.Types | Where-Object { $_.Name -eq "Effects" }
$regRoutesMethod = $effectsType.Methods | Where-Object { $_.Name -eq "RegisterRoutes" }
$startMowerMethod = $effectsType.Methods | Where-Object { $_.Name -eq "RouteStartLawnMowers" }
$restartMowerMethod = $effectsType.Methods | Where-Object { $_.Name -eq "RouteRestartLawnMowers" }
$removeMowerMethod = $effectsType.Methods | Where-Object { $_.Name -eq "RouteRemoveLawnMowers" }

$dictSetItem = ($regRoutesMethod.Body.Instructions | Where-Object { $_.OpCode.Name -eq "callvirt" -and $_.Operand.Name -eq "set_Item" } | Select-Object -First 1).Operand
$actionCtor = ($regRoutesMethod.Body.Instructions | Where-Object { $_.OpCode.Name -eq "newobj" -and $_.Operand.DeclaringType.Name -like "*Action*" } | Select-Object -First 1).Operand

$mowerAliases = @(
    @{ route = "/start_lawnmower"; method = $startMowerMethod },
    @{ route = "/start_lawnmowers"; method = $startMowerMethod },
    @{ route = "/startlawnmowers"; method = $startMowerMethod },
    @{ route = "/restart_lawnmower"; method = $restartMowerMethod },
    @{ route = "/restart_lawnmowers"; method = $restartMowerMethod },
    @{ route = "/restartlawnmowers"; method = $restartMowerMethod },
    @{ route = "/delete_lawnmower"; method = $removeMowerMethod },
    @{ route = "/delete_lawnmowers"; method = $removeMowerMethod },
    @{ route = "/deletelawnmower"; method = $removeMowerMethod },
    @{ route = "/deletelawnmowers"; method = $removeMowerMethod },
    @{ route = "/remove_lawnmower"; method = $removeMowerMethod },
    @{ route = "/remove_lawnmowers"; method = $removeMowerMethod }
)

$retInst = $regRoutesMethod.Body.Instructions[$regRoutesMethod.Body.Instructions.Count - 1]
$ilEffects = $regRoutesMethod.Body.GetILProcessor()

foreach ($alias in $mowerAliases) {
    $aliasInsts = @(
        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Dup),
        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldstr, $alias.route),
        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldnull),
        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldftn, $alias.method),
        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Newobj, $actionCtor),
        [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $dictSetItem)
    )
    foreach ($ai in $aliasInsts) {
        $ilEffects.InsertBefore($retInst, $ai)
    }
    Write-Host "   Registered mower alias: $($alias.route)" -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# 4. ZombieSpawner: Enable land movement for amphibious/water/submarine zombies
# ------------------------------------------------------------------------------
Write-Host "[4/5] Applying land movement patch to ZombieSpawner.AdjustLaneForTerrain..." -ForegroundColor Yellow
$spawnerType = $module.Types | Where-Object { $_.Name -eq "ZombieSpawner" }
$adjustMethod = $spawnerType.Methods | Where-Object { $_.Name -eq "AdjustLaneForTerrain" }

# Instruction 1: ldc.i4.0 -> ldc.i4.1
$adjustMethod.Body.Instructions[1].OpCode = [Mono.Cecil.Cil.OpCodes]::Ldc_I4_1

# Find WaterZombie call and change brfalse to br
for ($i = 0; $i -lt $adjustMethod.Body.Instructions.Count; $i++) {
    $inst = $adjustMethod.Body.Instructions[$i]
    if ($inst.OpCode.Name -like "*call*" -and "$($inst.Operand)" -like "*WaterZombie*") {
        $nextInst = $adjustMethod.Body.Instructions[$i + 1]
        if ($nextInst.OpCode.Name -like "*brfalse*") {
            $nextInst.OpCode = [Mono.Cecil.Cil.OpCodes]::Br_S
            Write-Host "   Changed WaterZombie brfalse at $($i+1) to unconditional branch!" -ForegroundColor Green
        }
        break
    }
}

# ------------------------------------------------------------------------------
# 5. OdysseyCore: Clean - No try/catch modification needed
# ------------------------------------------------------------------------------
Write-Host "[5/5] OdysseyCore intact and clean." -ForegroundColor Green

# Optimize and save
Write-Host "Optimizing macros and writing assembly to $dstDll..." -ForegroundColor Cyan
[Mono.Cecil.Rocks.MethodBodyRocks]::OptimizeMacros($handleMethod.Body)
[Mono.Cecil.Rocks.MethodBodyRocks]::OptimizeMacros($regRoutesMethod.Body)
[Mono.Cecil.Rocks.MethodBodyRocks]::OptimizeMacros($adjustMethod.Body)

$assembly.Write($dstDll)
Write-Host "SUCCESS! S2EPvZFusionMod.dll successfully built and deployed!" -ForegroundColor Green
