$file = "C:\Users\pc\Downloads\ano na\core\server.ps1"
$text = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)

$target = "'submarinec2|submarine_c2' { return 314 }"
$replacement = @"
'submarinec2|submarine_c2' { return 314 }
        'submarinec|submarine_c' { return 313 }
        'submarineb2|submarine_b2' { return 312 }
        'submarineb|submarine_b' { return 311 }
        'submarinea|submarine_a' { return 310 }
        'cherrysubmarine|cherry_submarine' { return 237 }
        'landsubmarine|land_submarine' { return 211 }
        'supersubmarine|super_submarine' { return 200 }
        'submarinezombie|submarine_zombie|submarine' { return 14 }
        'ultimateimpking|ultimate_imp_king|imperorsarkoftheduck|arkoftheduck' { return 234 }
        'impking|imp_king' { return 235 }
        'ultimatedolphin|ultimate_dolphin' { return 249 }
        'dolphingatling|dolphin_gatling' { return 214 }
        'dolphinrider|dolphin_rider' { return 19 }
        'dolphinpaper' { return 59 }
        'footballdolphin' { return 61 }
        'dolphinpea' { return 113 }
        'zombieduck|zombie_duck' { return 11 }
        'conezombieduck|coneduck' { return 12 }
        'bucketzombieduck|bucketduck' { return 13 }
        'snorklezombie|snorkel' { return 17 }
        'drownzombie|drown' { return 20 }
        'drowngargantuar' { return 76 }
"@

if ($text.Contains($target)) {
    $text = $text.Replace($target, $replacement)
    [System.IO.File]::WriteAllText($file, $text, [System.Text.Encoding]::UTF8)
    Write-Host "SUCCESS: Updated Resolve-ZombieId in server.ps1!"
} else {
    Write-Error "Target string not found!"
}

