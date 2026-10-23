$appHtmlPath = "core/app.html"
$content = [System.IO.File]::ReadAllText((Resolve-Path $appHtmlPath).Path, [System.Text.Encoding]::UTF8)

$oldRenderTag = '// Render Social Triggers'
$oldEndTestTag = '// ==================== MULTI-GAME MASTER SYSTEM ===================='

$startIdx = $content.IndexOf($oldRenderTag)
$endIdx = $content.IndexOf($oldEndTestTag)

if ($startIdx -lt 0 -or $endIdx -lt 0) {
    Write-Host "Error: Could not locate renderSocial tags in app.html"
    exit 1
}

$newSocialJs = @"
// Render Social Triggers & Event Dispatcher
                let currentSocialFilter = 'all';

                function renderSocial() {
                    if (!config) return;

                    // 1. Likes By Person (Card ID 2)
                    const g2 = config.gifts ? config.gifts.find(g => String(g.id) === '2') : null;
                    if (g2) {
                        const nameEl = document.getElementById('socialLikesActionName');
                        if (nameEl) nameEl.innerText = g2.label || g2.functionName || g2.command || 'Spawn Trident Jugger-nut Gargantuar (240)';
                        const imgEl = document.getElementById('socialLikesPersonImg');
                        if (imgEl && (g2.funcImg || g2.unitIcon)) imgEl.src = g2.funcImg || g2.unitIcon;
                        const badgeEl = document.getElementById('socialLikesPersonBadge');
                        if (badgeEl) {
                            badgeEl.innerText = (g2.actionType || 'Zombie').toUpperCase();
                            badgeEl.className = 'action-badge ' + (g2.actionType === 'plant' ? 'plant' : (g2.actionType === 'power' ? 'power' : 'zombie'));
                        }
                        const countEl = document.getElementById('socialLikesPersonCount');
                        if (countEl) countEl.innerText = 'x' + (g2.amount || g2.repetition || 1);
                        const chk = document.getElementById('socialLikesToggle');
                        if (chk) chk.checked = g2.enabled !== false;
                    }

                    // 2. All Likes Milestone (Card ID 3)
                    const g3 = config.gifts ? config.gifts.find(g => String(g.id) === '3') : null;
                    if (g3) {
                        const nameEl = document.getElementById('socialLikesAllActionName');
                        if (nameEl) nameEl.innerText = g3.label || g3.functionName || g3.command || 'Spawn SummonedHorse';
                        const imgEl = document.getElementById('socialLikesAllImg');
                        if (imgEl && (g3.funcImg || g3.unitIcon)) imgEl.src = g3.funcImg || g3.unitIcon;
                        const badgeEl = document.getElementById('socialLikesAllBadge');
                        if (badgeEl) {
                            badgeEl.innerText = (g3.actionType || 'Power').toUpperCase();
                            badgeEl.className = 'action-badge ' + (g3.actionType === 'plant' ? 'plant' : (g3.actionType === 'power' ? 'power' : 'zombie'));
                        }
                        const countEl = document.getElementById('socialLikesAllCount');
                        if (countEl) countEl.innerText = 'x' + (g3.amount || g3.repetition || 1);
                        const chk = document.getElementById('socialLikesAllToggle');
                        if (chk) chk.checked = g3.enabled !== false;
                    }

                    // 3. Follow Trigger (Card ID 4)
                    const g4 = config.gifts ? config.gifts.find(g => String(g.id) === '4') : null;
                    if (g4) {
                        const nameEl = document.getElementById('socialFollowActionName');
                        if (nameEl) nameEl.innerText = g4.label || g4.functionName || g4.command || 'Spawn SummonedHorse';
                        const imgEl = document.getElementById('socialFollowImg');
                        if (imgEl && (g4.funcImg || g4.unitIcon)) imgEl.src = g4.funcImg || g4.unitIcon;
                        const badgeEl = document.getElementById('socialFollowBadge');
                        if (badgeEl) {
                            badgeEl.innerText = (g4.actionType || 'Plant').toUpperCase();
                            badgeEl.className = 'action-badge ' + (g4.actionType === 'plant' ? 'plant' : (g4.actionType === 'power' ? 'power' : 'zombie'));
                        }
                        const countEl = document.getElementById('socialFollowCount');
                        if (countEl) countEl.innerText = 'x' + (g4.amount || g4.repetition || 1);
                        const chk = document.getElementById('socialFollowToggle');
                        if (chk) chk.checked = g4.enabled !== false;
                    }

                    // 4. Social config fallbacks
                    if (config.socialTriggers) {
                        const soc = config.socialTriggers;
                        if (soc.share) {
                            const nameEl = document.getElementById('socialShareActionName');
                            if (nameEl) nameEl.innerText = soc.share.label || soc.share.command || 'Plant Everywhere Mode (Share)';
                            const chk = document.getElementById('socialShareToggle');
                            if (chk) chk.checked = soc.share.enabled !== false;
                        }
                    }
                }

                function selectSocialTriggerCard(triggerKey) {
                    currentSocialFilter = triggerKey;

                    // Update active styling on embedded 10 cards
                    const cards = document.querySelectorAll('#socialTabTriggerGrid .trig-card');
                    cards.forEach(c => {
                        if (c.dataset.trigger === triggerKey) {
                            c.classList.add('active');
                        } else {
                            c.classList.remove('active');
                        }
                    });

                    // Quick actions for special trigger types
                    if (triggerKey === 'gift') {
                        showToast("🎁 Switching to TikTok Gift Commands...", "INFO");
                        switchTab('commands');
                        return;
                    }

                    // Filter or highlight matching card below
                    const cardMap = {
                        'likes_person': 'cardSocialLikesPerson',
                        'likes_all': 'cardSocialLikesAll',
                        'follow': 'cardSocialFollow',
                        'share': 'cardSocialShare',
                        'viewer_join': 'cardSocialViewerJoin',
                        'chat': 'cardSocialChat',
                        'super_fan': 'cardSocialSuperFan',
                        'coins_range': 'cardSocialCoinsRange',
                        'custom': 'cardSocialCustom'
                    };

                    const targetCardId = cardMap[triggerKey];
                    const badge = document.getElementById('socialFilterBadge');
                    if (badge) {
                        const labelMap = {
                            'likes_person': 'Selected: Likes By Person',
                            'likes_all': 'Selected: All Likes Milestone',
                            'follow': 'Selected: New Follower',
                            'share': 'Selected: Stream Share',
                            'viewer_join': 'Selected: Viewer Joined Alert',
                            'chat': 'Selected: Chat Keyword',
                            'super_fan': 'Selected: Super Fan / Sub',
                            'coins_range': 'Selected: Min-Max Coins',
                            'custom': 'Selected: Custom Webhook'
                        };
                        badge.innerText = labelMap[triggerKey] || 'Selected Trigger';
                    }

                    if (targetCardId) {
                        const targetCard = document.getElementById(targetCardId);
                        if (targetCard) {
                            targetCard.scrollIntoView({ behavior: 'smooth', block: 'center' });
                            targetCard.style.transition = 'all 0.3s ease';
                            targetCard.style.outline = '2px solid #38bdf8';
                            targetCard.style.boxShadow = '0 0 24px rgba(56, 189, 248, 0.4)';
                            setTimeout(() => {
                                targetCard.style.outline = 'none';
                                targetCard.style.boxShadow = 'none';
                            }, 2200);
                        }
                    }
                }

                function onSocialAudienceChanged(val) {
                    currentEditingAudience = val;
                    showToast("Audience set to: " + val, "INFO");
                }

                function editSocial(type) {
                    if (type === 'likes' || type === 'likes_person') {
                        openEditGiftModal('2');
                    } else if (type === 'likes_all') {
                        openEditGiftModal('3');
                    } else if (type === 'follow') {
                        openEditGiftModal('4');
                    } else if (type === 'share') {
                        const shareGift = config && config.gifts ? config.gifts.find(g => g.giftName && g.giftName.toLowerCase().includes('share')) : null;
                        if (shareGift) {
                            openEditGiftModal(shareGift.id);
                        } else {
                            openTriggerSelectorModal('share', 'social_tab');
                        }
                    } else if (type === 'viewer_join') {
                        const card = document.getElementById('cardSocialViewerJoin');
                        if (card) card.scrollIntoView({ behavior: 'smooth', block: 'center' });
                        showToast("Viewer Join Alert is managed via OBS Browser Source link.", "INFO");
                    } else if (type === 'gift') {
                        switchTab('commands');
                    } else {
                        openTriggerSelectorModal(type, 'social_tab');
                    }
                }

                async function testSocial(type) {
                    if (type === 'likes' || type === 'likes_person') {
                        await testGift('2');
                        return;
                    }
                    if (type === 'likes_all') {
                        await testGift('3');
                        return;
                    }
                    if (type === 'follow') {
                        await testGift('4');
                        return;
                    }
                    if (type === 'viewer_join') {
                        triggerTestJoinAlert();
                        return;
                    }

                    const soc = config && config.socialTriggers ? config.socialTriggers[type] : null;
                    const label = soc ? soc.label : (type.toUpperCase() + ' Trigger');
                    const cmd = soc ? soc.command : 'spawn_super_horse';
                    const actionType = soc ? soc.actionType : 'plant';

                    showToast(`Tested: ${type.toUpperCase()} -> ${label}`);

                    try {
                        await fetch('/api/test', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({
                                type: type,
                                label: label,
                                command: cmd,
                                actionType: actionType,
                                amount: soc ? (soc.amount || 1) : 1,
                                username: 'RENEarn'
                            })
                        });
                    } catch (err) {
                        showToast("Test failed: " + err.message, "ERR");
                    }
                }

                function getTesterProfile() {
                    return { name: 'RENEarn', avatar: 'images/default_avatar.svg' };
                }

                // Test Single Gift (Executes ALL sub-commands and plays attached audio simultaneously with zero delay)
                async function testGift(giftId, skipAudio = false) {
                    const gift = config.gifts.find(g => String(g.id) === String(giftId));
                    if (!gift) return;

                    const repCount = (gift.repetition !== undefined && gift.repetition !== null && gift.repetition > 0) ? gift.repetition : (gift.amount || 1);
                    showToast(`Fired (${repCount}x): ${gift.giftName} -> ${gift.label}`);

                    // 1. Play attached sound effect immediately with ZERO latency
                    if (!skipAudio && gift.audio && gift.audio.file) {
                        try {
                            triggerCommandSound(gift.id, gift.audio, { username: 'RENEarn', repeatCount: 1 });
                        } catch (e) { }
                    }

                    const prof = getTesterProfile();
                    const isSpinner = gift.actionType === 'spinner' || gift.command === 'spin_wheel' || (gift.command && gift.command.includes('spin')) || Boolean(gift.triggerSpinner);

                    try {
                        // Immediately increment count for overlay (parallel)
                        fetch('/api/counts', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({ id: gift.id, count: 1 })
                        }).catch(() => { });

                        try {
                            const bcSide = new BroadcastChannel('renearn_side_overlay');
                            bcSide.postMessage({ cardId: gift.id, count: undefined, amount: 1 });
                        } catch (e) { }

                        // Collect ALL sub-commands configured on this trigger!
                        const subCmds = (Array.isArray(gift.commands) && gift.commands.length > 0) ? gift.commands : [];
                        const joinedCmd = subCmds.length > 0 
                            ? subCmds.map(c => c.command).filter(Boolean).join(';') 
                            : (gift.command || (gift.function && gift.function.commands ? gift.function.commands.join(';') : ''));
                        const testCmd = joinedCmd || (subCmds[0] ? subCmds[0].command : '');
                        const testAction = gift.actionType || (subCmds[0] && subCmds[0].actionType) || (gift.function ? gift.function.actionType : '') || 'pvz_command';
                        const testLabel = gift.label || (gift.function ? gift.function.name : '') || 'Test Action';
                        const testGiftName = gift.giftName || (gift.trigger ? gift.trigger.giftName : '') || 'Test Gift';

                        if (isSpinner) {
                            const spId = gift.triggerSpinner || gift.spinnerId || (gift.command && gift.command.startsWith('spinner_') ? gift.command : '');
                            const spParam = spId ? `&spinnerId=${encodeURIComponent(spId)}` : '';
                            await fetch(`/api/spin?username=${encodeURIComponent(prof.name)}&avatar=${encodeURIComponent(prof.avatar)}${spParam}`, { method: 'POST' });

                            // Also execute ALL plant or zombie commands attached to this card!
                            if (subCmds.length > 0) {
                                for (const subCmd of subCmds) {
                                    if (subCmd.command && !subCmd.command.startsWith('spinner_') && subCmd.command !== 'spin_wheel') {
                                        fetch('/api/test', {
                                            method: 'POST',
                                            headers: { 'Content-Type': 'application/json' },
                                            body: JSON.stringify({
                                                type: 'game_trigger',
                                                cardId: gift.id,
                                                label: subCmd.label || gift.label,
                                                command: subCmd.command,
                                                actionType: subCmd.actionType || 'plant',
                                                amount: subCmd.amount || gift.amount || 1,
                                                repetition: repCount,
                                                delay: gift.delay || 0,
                                                interval: (gift.interval !== undefined && gift.interval !== null) ? gift.interval : 100,
                                                hideInOverlay: gift.hideInOverlay === true,
                                                username: 'RENEarn'
                                            })
                                        }).catch(() => { });
                                    }
                                }
                            }
                        } else {
                            // Non-spinner: summon ALL commands configured on this card!
                            await fetch('/api/test', {
                                method: 'POST',
                                headers: { 'Content-Type': 'application/json' },
                                body: JSON.stringify({
                                    type: (gift.triggerType === 'custom' ? 'custom' : (gift.triggerType || 'gift')),
                                    triggerType: gift.triggerType || 'gift',
                                    cardId: gift.id,
                                    giftName: testGiftName,
                                    label: testLabel,
                                    command: testCmd,
                                    actionType: testAction,
                                    amount: gift.amount || 1,
                                    repetition: repCount,
                                    delay: gift.delay || 0,
                                    interval: (gift.interval !== undefined && gift.interval !== null) ? gift.interval : 100,
                                    repetitionMultiplier: gift.repetitionMultiplier !== false,
                                    hideInOverlay: gift.hideInOverlay === true,
                                    username: 'RENEarn',
                                    avatar: prof.avatar,
                                    icon: gift.icon,
                                    coins: gift.coins,
                                    commands: subCmds
                                })
                            });
                        }
                    } catch (err) {
                        showToast("Test failed: " + err.message, "ERR");
                    }
                }

                
"@

$newContent = $content.Substring(0, $startIdx) + $newSocialJs + $content.Substring($endIdx)

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Resolve-Path $appHtmlPath).Path, $newContent, $utf8NoBom)
Write-Host "JavaScript functions for Social Triggers & Event Dispatcher updated successfully!"
