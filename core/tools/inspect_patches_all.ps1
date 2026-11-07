Add-Type -Path 'C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\net472\Mono.Cecil.dll'
$dll = 'C:\Users\pc\Downloads\ano na\core\tools\out_debug.dll'
$assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($dll)
$p = $assembly.MainModule.Types | Where-Object { $_.Name -eq 'Patches' }
Write-Host "Patches methods:"
$p.Methods | ForEach-Object { $_.FullName }

