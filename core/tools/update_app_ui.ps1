$htmlPath = "c:\Users\pc\Downloads\ano na\app.html"
$content = [System.IO.File]::ReadAllText($htmlPath, [System.Text.Encoding]::UTF8)

# 1. Insert socialCustomizationPanel right before customGiftFieldsContainer
$panelHtml = @'
                <!-- Dedicated Likes & Social Customization Panel (Shows when editing Likes / Follow cards) -->
                <div id="socialCustomizationPanel" class="custom-fields-panel" style="display: none; background: rgba(56, 189, 248, 0.08); border: 1px solid rgba(56, 189, 248, 0.4); flex-direction: column; gap: 8px;">
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                        <span id="socialPanelTitle" style="font-weight: 800; font-size: 14px; color: #38bdf8;">❤️ Likes Threshold Customization</span>
                        <span id="socialPanelBadge" class="pill" style="font-size: 10px; background: rgba(56, 189, 248, 0.2); color: #38bdf8; border-color: rgba(56, 189, 248, 0.4);">NO COINS REQUIRED</span>
                    </div>
                    <div id="socialPanelDesc" style="font-size: 12px; color: var(--text-secondary); line-height: 1.4;">
                        Customize how many likes are needed to trigger this spawn:
                    </div>
                    <div id="likeThresholdRow" style="display: flex; gap: 12px; align-items: center; flex-wrap: wrap;">
                        <div style="flex: 1; min-width: 140px;">
                            <label class="form-label" style="font-size: 11px;">Likes Threshold</label>
                            <input type="number" id="modalLikeThreshold" class="form-input" style="font-size: 16px; font-weight: 800; color: #38bdf8;" value="50" min="1" oninput="onLikeThresholdChanged()">
                        </div>
                        <div style="flex: 2; min-width: 220px;">
                            <label class="form-label" style="font-size: 11px;">Quick Presets</label>
                            <div class="pill-group" id="socialQuickPills">
                                <!-- Dynamic quick pills based on card type -->
                            </div>
                        </div>
                    </div>
                </div>

                <div id="customGiftFieldsContainer"
'@

if (-not $content.Contains("socialCustomizationPanel")) {
    $content = $content.Replace('<div id="customGiftFieldsContainer"', $panelHtml)
}

# 2. Update renderGifts in app.html to display proper badge subtitle instead of "1 Coins"
$oldRenderCardInfo = @'
                                <div class="gift-name">${gift.giftName}</div>
                                <div class="gift-coins">🪙 ${gift.coins} Coins</div>
'@

$newRenderCardInfo = @'
                                <div class="gift-name">${gift.giftName}</div>
                                ${(() => {
                                    if (String(gift.id) === '1' || gift.eventType === 'team_plants_likes') {
                                        return `<div class="gift-coins" style="color: #4ade80; font-weight: 800; font-size: 11px;">🌿 Every ${gift.likeThreshold || 50} Likes (Team Plants)</div>`;
                                    } else if (String(gift.id) === '2' || gift.eventType === 'team_zombies_likes') {
                                        return `<div class="gift-coins" style="color: #c084fc; font-weight: 800; font-size: 11px;">🧟 Every ${gift.likeThreshold || 50} Likes (Team Zombies)</div>`;
                                    } else if (String(gift.id) === '3' || gift.eventType === 'total_likes' || (gift.giftName && gift.giftName.toLowerCase().includes('total likes'))) {
                                        const kStr = (gift.likeThreshold >= 1000) ? (gift.likeThreshold / 1000) + 'K' : (gift.likeThreshold || '50K');
                                        return `<div class="gift-coins" style="color: #38bdf8; font-weight: 800; font-size: 11px;">🎯 Total Likes Goal: ${kStr}</div>`;
                                    } else if (String(gift.id) === '4' || gift.eventType === 'follow' || (gift.giftName && gift.giftName.toLowerCase().includes('follow'))) {
                                        return `<div class="gift-coins" style="color: #34d399; font-weight: 800; font-size: 11px;">👤 On New Follower</div>`;
                                    } else {
                                        return `<div class="gift-coins">🪙 ${gift.coins || 1} Coins</div>`;
                                    }
                                })()}
'@

$content = $content.Replace($oldRenderCardInfo, $newRenderCardInfo)

# 3. Add helper functions for likes presets and threshold changes
$helperCode = @'
        function setLikePreset(val) {
            const inp = document.getElementById('modalLikeThreshold');
            if (inp) {
                inp.value = val;
                onLikeThresholdChanged();
            }
        }

        function onLikeThresholdChanged() {
            const val = parseInt(document.getElementById('modalLikeThreshold')?.value) || 50;
            const previewCoins = document.getElementById('previewGiftCoins');
            if (!previewCoins) return;
            if (editingGiftId === '1') {
                previewCoins.innerText = `🌿 Every ${val} Likes (Team Plants)`;
            } else if (editingGiftId === '2') {
                previewCoins.innerText = `🧟 Every ${val} Likes (Team Zombies)`;
            } else if (editingGiftId === '3') {
                const kStr = (val >= 1000) ? (val / 1000) + 'K' : val;
                previewCoins.innerText = `🎯 Stream Goal: Every ${kStr} Likes`;
            }
        }
'@

if (-not $content.Contains("function setLikePreset")) {
    $content = $content.Replace("function handleBackdropClick(e) {", $helperCode + "`n`n        function handleBackdropClick(e) {")
}

[System.IO.File]::WriteAllText($htmlPath, $content, [System.Text.Encoding]::UTF8)
Write-Host "Updated app.html successfully!"
