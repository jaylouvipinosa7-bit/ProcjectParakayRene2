$csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
$gameDir = "C:\Users\pc\Desktop\games ko to ya\Game Files"
$src = "c:\Users\pc\Downloads\ano na\core\tools\ImpKingLandMovement.cs"
$out = "c:\Users\pc\Downloads\ano na\core\tools\ImpKingLandMovement.dll"

$refs = @(
    "$gameDir\MelonLoader\net472\MelonLoader.dll",
    "$gameDir\MelonLoader\net472\0Harmony.dll",
    "$gameDir\MelonLoader\Il2CppAssemblies\Assembly-CSharp.dll",
    "$gameDir\MelonLoader\Il2CppAssemblies\UnityEngine.CoreModule.dll",
    "$gameDir\MelonLoader\Il2CppAssemblies\Il2CppInterop.Runtime.dll"
)

$refArgs = ($refs | ForEach-Object { "/r:`"$_`"" }) -join " "

$cmd = "& `"$csc`" /target:library /out:`"$out`" $refArgs `"$src`""
Write-Host "Running: $cmd"
Invoke-Expression $cmd

if (Test-Path $out) {
    Write-Host "SUCCESS: ImpKingLandMovement.dll compiled! Size: $((Get-Item $out).Length)"
} else {
    Write-Host "FAILED to compile."
}

