Add-Type -Path 'C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\net472\Mono.Cecil.dll'
$assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly('C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\Il2CppAssemblies\Assembly-CSharp.dll')
$z = $assembly.MainModule.Types | Where-Object { $_.Name -eq 'Zombie' }
Write-Host "Zombie Properties:"
$z.Properties | Where-Object { $_.Name -like '*speed*' -or $_.Name -like '*pos*' -or $_.Name -like '*vx*' -or $_.Name -like '*water*' -or $_.Name -like '*anim*' } | ForEach-Object { "$($_.PropertyType.FullName) $($_.Name)" }

