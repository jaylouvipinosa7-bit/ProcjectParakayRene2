$outDll = "C:\Users\pc\Downloads\ano na\core\tools\out_water_movement.dll"
$gameModsDir = "C:\Users\pc\Desktop\games ko to ya\Game Files\Mods"
$repoModsDir = "C:\Users\pc\Downloads\ano na\core\mods\pvz_fusion_4"

if (Test-Path $outDll) {
    Copy-Item $outDll "$gameModsDir\RENEarnPVZFusionMod.dll" -Force
    Write-Host "Copied to $gameModsDir\RENEarnPVZFusionMod.dll"

    Copy-Item $outDll "$gameModsDir\RunetifyPVZFusionMod.dll" -Force
    Write-Host "Copied to $gameModsDir\RunetifyPVZFusionMod.dll"

    if (Test-Path $repoModsDir) {
        Copy-Item $outDll "$repoModsDir\RENEarnPVZFusionMod.dll" -Force
        Write-Host "Copied to $repoModsDir\RENEarnPVZFusionMod.dll"
    }

    Write-Host "DEPLOY COMPLETED SUCCESSFULLY!"
} else {
    Write-Error "out_water_movement.dll does not exist!"
}

