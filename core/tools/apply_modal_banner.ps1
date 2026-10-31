$appPath = "c:\Users\pc\Downloads\ano na\core\app.html"
$content = [System.IO.File]::ReadAllText($appPath, [System.Text.Encoding]::UTF8)
$target = "                        <!-- Filter Chips & Search inside template -->"

if ($content -notmatch 'id="pvzModalGameSubBannerWrap"') {
    $inject = @"
                        <!-- Game-Specific Subscription Banner (Image 1 Parity) -->
                        <div id="pvzModalGameSubBannerWrap" style="margin-top: 14px; margin-bottom: 14px;">
                            `${getGameSubscriptionBannerHTML(gameKey)}
                        </div>

                        <!-- Filter Chips & Search inside template -->
"@
    $content = $content.Replace($target, $inject)
    [System.IO.File]::WriteAllText($appPath, $content, [System.Text.Encoding]::UTF8)
    Write-Host "Injected into modal successfully!"
} else {
    Write-Host "Already present in modal."
}
