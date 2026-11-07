Add-Type -Path 'C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\net472\Mono.Cecil.dll'
$assembly = [Mono.Cecil.AssemblyDefinition]::ReadAssembly('C:\Users\pc\Desktop\games ko to ya\Game Files\MelonLoader\Il2CppAssemblies\Assembly-CSharp.dll')
$subs = $assembly.MainModule.Types | Where-Object { $_.Name -like '*Submarine*' }
foreach ($s in $subs) {
    Write-Host "$($s.FullName) BaseType: $($s.BaseType.FullName)"
    $s.Methods | ForEach-Object { Write-Host "   $($_.FullName)" }
}

