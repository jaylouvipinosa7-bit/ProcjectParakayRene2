Add-Type -Path 'C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\net472\Mono.Cecil.dll'
$assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly('C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\Il2CppAssemblies\Assembly-CSharp.dll')
$boat = $assembly.MainModule.Types | Where-Object { $_.Name -eq 'BoatImp' }
Write-Host "BoatImp methods:"
$boat.Methods | ForEach-Object { $_.FullName }

