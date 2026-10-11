Add-Type -Path "C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\net472\Mono.Cecil.dll"
$asmPath = "C:\Users\pc\Desktop\games ko to ya\Game Files\Mods\RunetifyPVZFusionMod.dll"
$assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($asmPath)

Write-Host "=== MelonLogger references in RunetifyPVZFusionMod.dll ==="
foreach ($mr in $assembly.MainModule.GetMemberReferences()) {
    if ($mr.DeclaringType.FullName -like "*MelonLogger*") {
        Write-Host "$($mr.DeclaringType.FullName):: $($mr.Name) ($($mr.FullName))"
    }
}
