Add-Type -Path 'C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\net472\Mono.Cecil.dll'
$assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly('C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\Il2CppAssemblies\Assembly-CSharp.dll')
$cz = $assembly.MainModule.Types | Where-Object { $_.Name -eq 'CreateZombie' }
Write-Host "CreateZombie methods:"
$cz.Methods | ForEach-Object { $_.FullName }

