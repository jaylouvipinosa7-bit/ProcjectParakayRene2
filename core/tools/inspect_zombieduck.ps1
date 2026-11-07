Add-Type -Path 'C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\net472\Mono.Cecil.dll'
$assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly('C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\Il2CppAssemblies\Assembly-CSharp.dll')
$zd = $assembly.MainModule.Types | Where-Object { $_.Name -eq 'ZombieDuck' }
Write-Host "ZombieDuck methods:"
$zd.Methods | ForEach-Object { $_.FullName }

