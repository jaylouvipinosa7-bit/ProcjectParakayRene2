Add-Type -Path 'C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\net472\Mono.Cecil.dll'
$assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly('C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\Il2CppAssemblies\Assembly-CSharp.dll')
$uik = $assembly.MainModule.Types | Where-Object { $_.Name -eq 'UltimateImpKing' }
Write-Host "UltimateImpKing methods:"
$uik.Methods | ForEach-Object { $_.FullName }

