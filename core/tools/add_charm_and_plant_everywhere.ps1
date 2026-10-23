$paths = @(
    "c:\Users\pc\Downloads\ano na\core\pvz_units_catalog.json",
    "c:\Users\pc\Downloads\ano na\pvz_units_catalog.json"
)

foreach ($filePath in $paths) {
    if (-not (Test-Path $filePath)) { continue }
    Write-Host "Processing $filePath..."
    $cat = Get-Content $filePath -Raw -Encoding UTF8 | ConvertFrom-Json

    $charmItem = [PSCustomObject]@{
        id       = "charm_all_zombies"
        name     = "Charm all zombies"
        command  = "charm_all_zombies"
        endpoint = "/charmallzombies"
        effect   = "1"
        img      = "images/game-icons/pvz/charm_all_zombies.webp"
        icon     = "images/game-icons/pvz/charm_all_zombies.webp"
        type     = "Power"
        isS2E    = $true
    }

    $charmAlt = [PSCustomObject]@{
        id       = "charmallzombies"
        name     = "Charm All Zombies"
        command  = "charmallzombies"
        endpoint = "/charmallzombies"
        effect   = "1"
        img      = "images/game-icons/pvz/charm_all_zombies.webp"
        icon     = "images/game-icons/pvz/charm_all_zombies.webp"
        type     = "Power"
        isS2E    = $true
    }

    # Add to powers
    $hasCharm = $false
    foreach ($item in $cat.powers) {
        if ($item.id -eq "charm_all_zombies" -or $item.command -eq "charm_all_zombies") {
            $hasCharm = $true
            break
        }
    }
    if (-not $hasCharm) {
        $powersList = [System.Collections.ArrayList]::new($cat.powers)
        [void]$powersList.Add($charmItem)
        [void]$powersList.Add($charmAlt)
        $cat.powers = $powersList
    }

    # Add to all
    $hasCharmAll = $false
    foreach ($item in $cat.all) {
        if ($item.id -eq "charm_all_zombies" -or $item.command -eq "charm_all_zombies") {
            $hasCharmAll = $true
            break
        }
    }
    if (-not $hasCharmAll) {
        $allList = [System.Collections.ArrayList]::new($cat.all)
        [void]$allList.Add($charmItem)
        [void]$allList.Add($charmAlt)
        $cat.all = $allList
    }

    # Also add plant_everywahre into plants list so searching plants finds it
    $hasPlantInPlants = $false
    foreach ($item in $cat.plants) {
        if ($item.id -eq "plant_everywahre" -or $item.command -eq "plant_everywahre" -or $item.id -eq "planteverywhere") {
            $hasPlantInPlants = $true
            break
        }
    }
    if (-not $hasPlantInPlants) {
        $plantEveryItem = [PSCustomObject]@{
            id       = "plant_everywahre"
            name     = "Plant everywahre"
            command  = "plant_everywahre"
            endpoint = "/planteverywhere"
            effect   = "1"
            img      = "images/game-icons/pvz/plant_everywahre.webp"
            icon     = "images/game-icons/pvz/plant_everywahre.webp"
            type     = "Plant"
            isS2E    = $true
        }
        $plantsList = [System.Collections.ArrayList]::new($cat.plants)
        [void]$plantsList.Add($plantEveryItem)
        $cat.plants = $plantsList
    }

    $json = $cat | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($filePath, $json, [System.Text.Encoding]::UTF8)
    Write-Host "Successfully updated $filePath"
}
