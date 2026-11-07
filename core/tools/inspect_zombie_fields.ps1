Add-Type -Path 'C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\net472\Mono.Cecil.dll'
$assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly('C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\Il2CppAssemblies\Assembly-CSharp.dll')
$z = $assembly.MainModule.Types | Where-Object { $_.Name -eq 'Zombie' }
Write-Host "Zombie fields:"
$z.Fields | Where-Object { $_.Name -like '*pos*' -or $_.Name -like '*speed*' -or $_.Name -like '*x*' -or $_.Name -like '*move*' -or $_.Name -like '*water*' } | ForEach-Object { "$($_.FieldType.FullName) $($_.Name)" }

