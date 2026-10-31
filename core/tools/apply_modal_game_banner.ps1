# Complete injection of modal subscription banner and switchTab album update

$appPath = "c:\Users\pc\Downloads\ano na\core\app.html"
$content = [System.IO.File]::ReadAllText($appPath, [System.Text.Encoding]::UTF8)

# 1. Inject into renderPvzPresetDetail
$targetHeroEnd = "                                </div>`r`n                            </div>`r`n                        </div>`r`n`r`n                        <!-- Filter Chips & Search inside template -->"
$replacementHeroEnd = "                                </div>`r`n                            </div>`r`n                        </div>`r`n`r`n                        <!-- Game-Specific Subscription Banner (Image 1 Parity) -->`r`n                        <div style=`"margin-top: 14px; margin-bottom: 14px;`">`r`n                            `${getGameSubscriptionBannerHTML(gameKey)}`r`n                        </div>`r`n`r`n                        <!-- Filter Chips & Search inside template -->"

if ($content -notmatch 'getGameSubscriptionBannerHTML\(gameKey\)') {
    if ($content.Contains($targetHeroEnd)) {
        $content = $content.Replace($targetHeroEnd, $replacementHeroEnd)
        Write-Host "Injected Game Subscription Banner into renderPvzPresetDetail!"
    } else {
        # Fallback with LF
        $targetHeroEndLF = "                                </div>`n                            </div>`n                        </div>`n`n                        <!-- Filter Chips & Search inside template -->"
        $replacementHeroEndLF = "                                </div>`n                            </div>`n                        </div>`n`n                        <!-- Game-Specific Subscription Banner (Image 1 Parity) -->`n                        <div style=`"margin-top: 14px; margin-bottom: 14px;`">`n                            `${getGameSubscriptionBannerHTML(gameKey)}`n                        </div>`n`n                        <!-- Filter Chips & Search inside template -->"
        $content = $content.Replace($targetHeroEndLF, $replacementHeroEndLF)
        Write-Host "Injected Game Subscription Banner into renderPvzPresetDetail (LF)!"
    }
}

# 2. Add updateGameSpecificSubscriptionBanner to switchTab
$targetSwitchTab = "targetPane.classList.add('active');`r`n                    targetPane.querySelectorAll('iframe[data-src]').forEach(loadDeferredIframe);"
$newSwitchTab = "$targetSwitchTab`r`n                    if (tabId === 'album') { updateGameSpecificSubscriptionBanner(currentActiveAlbumGame || 'l4d2'); }"

if ($content -notmatch "if \(tabId === 'album'\) \{ updateGameSpecificSubscriptionBanner") {
    if ($content.Contains($targetSwitchTab)) {
        $content = $content.Replace($targetSwitchTab, $newSwitchTab)
        Write-Host "Injected updateGameSpecificSubscriptionBanner into switchTab!"
    } else {
        $targetSwitchTabLF = "targetPane.classList.add('active');`n                    targetPane.querySelectorAll('iframe[data-src]').forEach(loadDeferredIframe);"
        $newSwitchTabLF = "$targetSwitchTabLF`n                    if (tabId === 'album') { updateGameSpecificSubscriptionBanner(currentActiveAlbumGame || 'l4d2'); }"
        $content = $content.Replace($targetSwitchTabLF, $newSwitchTabLF)
        Write-Host "Injected updateGameSpecificSubscriptionBanner into switchTab (LF)!"
    }
}

# 3. Also initialize banner on window load if not already called
$domLoadTarget = "window.addEventListener('DOMContentLoaded', () => {"
$domLoadNew = "$domLoadTarget`r`n                setTimeout(() => { if (typeof updateGameSpecificSubscriptionBanner === 'function') updateGameSpecificSubscriptionBanner('l4d2'); }, 100);"

if ($content -notmatch "updateGameSpecificSubscriptionBanner\('l4d2'\)") {
    $content = $content.Replace($domLoadTarget, $domLoadNew)
    Write-Host "Injected banner initial load into DOMContentLoaded!"
}

[System.IO.File]::WriteAllText($appPath, $content, [System.Text.Encoding]::UTF8)
Write-Host "All modal and switchTab integrations completed!"
