param([string]$targetPath = "C:\Users\pc\Desktop\games ko to ya\Game Files\Mods\S2ECustomMod.dll")
Add-Type -Path "C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\net472\Mono.Cecil.dll"
$assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($targetPath)

Write-Host "=== ASSEMBLY ATTRIBUTES for $targetPath ==="
foreach ($attr in $assembly.CustomAttributes) {
    Write-Host "$($attr.AttributeType.FullName):"
    foreach ($arg in $attr.ConstructorArguments) {
        Write-Host "   Arg: $($arg.Value)"
    }
}

Write-Host "`n=== TYPES & METHODS ==="
foreach ($module in $assembly.Modules) {
    foreach ($type in $module.Types) {
        Write-Host $type.FullName
        foreach ($method in $type.Methods) {
            Write-Host "   $($method.Name)"
        }
    }
}
