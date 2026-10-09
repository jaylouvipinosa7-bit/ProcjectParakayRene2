$html = Get-Content 'overlay-spinner.html' -Raw

$tests = @(
    @{ Name = "Transparent Body"; Pattern = "background:\s*transparent\s*!important" },
    @{ Name = "Hidden Debug Bar"; Pattern = "\.debug-controls-bar\s*\{[^}]*display:\s*none" },
    @{ Name = "Auto-Hide Stage Hidden Idle"; Pattern = "\.spinner-stage-container\s*\{[^}]*opacity:\s*0[^}]*visibility:\s*hidden" },
    @{ Name = "Active Stage Visible On Gift"; Pattern = "\.spinner-stage-container\.active\s*\{[^}]*opacity:\s*1[^}]*visibility:\s*visible" },
    @{ Name = "Fade Out Class Present"; Pattern = "\.spinner-stage-container\.fading-out" },
    @{ Name = "findSpinnerForGift Defined"; Pattern = "function findSpinnerForGift" },
    @{ Name = "buildReelForSpinner Defined"; Pattern = "function buildReelForSpinner" },
    @{ Name = "showAndSpin Function Defined"; Pattern = "function showAndSpin" },
    @{ Name = "Auto-Hide 5000ms Timer"; Pattern = "5000\);\s*// 5 seconds display hold time" },
    @{ Name = "Reel Pointer Triangle"; Pattern = "\.pointer-arrow" },
    @{ Name = "Winner Banner Exists"; Pattern = "id=.winnerBanner." },
    @{ Name = "Reel Track Exists"; Pattern = "id=.reelTrack." },
    @{ Name = "Events Polling Active"; Pattern = "initEventsListener" }
)

Write-Host "=== OVERLAY SPINNER VERIFICATION ===" -ForegroundColor Cyan
$allPass = $true
foreach ($t in $tests) {
    $match = [regex]::IsMatch($html, $t.Pattern)
    $status = if ($match) { "PASS" } else { "FAIL"; $allPass = $false }
    $color = if ($match) { "Green" } else { "Red" }
    Write-Host ("{0,-35}: {1}" -f $t.Name, $status) -ForegroundColor $color
}

if ($allPass) {
    Write-Host "`nALL 13 VERIFICATION TESTS PASSED SUCCESSFULLY!" -ForegroundColor Green
} else {
    Write-Host "`nSOME TESTS FAILED!" -ForegroundColor Red
}
