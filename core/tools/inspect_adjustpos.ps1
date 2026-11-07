Add-Type -Path 'C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\net472\Mono.Cecil.dll'
$assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly('C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\Il2CppAssemblies\Assembly-CSharp.dll')
$z = $assembly.MainModule.Types | Where-Object { $_.Name -eq 'Zombie' }
$ap = $z.Methods | Where-Object { $_.Name -eq 'AdjustPosition' }
Write-Host "AdjustPosition: $($ap.FullName)"
$mv = $z.Methods | Where-Object { $_.Name -eq 'MoveXUpdate' }
Write-Host "MoveXUpdate: $($mv.FullName)"

