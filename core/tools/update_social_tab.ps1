$appHtmlPath = "core/app.html"
$content = [System.IO.File]::ReadAllText((Resolve-Path $appHtmlPath).Path, [System.Text.Encoding]::UTF8)

# 1. Target block for #tab-social
$oldStartTag = '<!-- TAB 2: SOCIAL TRIGGERS -->'
$oldEndTag = '<!-- TAB 3: LUCKY WHEEL / REEL STUDIO -->'

$startIdx = $content.IndexOf($oldStartTag)
$endIdx = $content.IndexOf($oldEndTag)

if ($startIdx -lt 0 -or $endIdx -lt 0) {
    Write-Host "Error: Could not locate tab-social tags"
    exit 1
}

$newSocialTab = @"
            <!-- TAB 2: SOCIAL TRIGGERS (AUTHENTIC EVENT DISPATCHER REPLICA) -->
            <div id="tab-social" class="tab-pane">
                <!-- TOP HEADER BAR (EXACT REPLICA OF USER IMAGE 2) -->
                <div class="social-header-block" style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; flex-wrap: wrap; gap: 14px;">
                    <div>
                        <div style="display: flex; align-items: center; gap: 10px;">
                            <span style="font-size: 26px; line-height: 1; filter: drop-shadow(0 0 10px rgba(245, 158, 11, 0.7)); display: inline-flex; align-items: center;">⚡</span>
                            <h1 style="font-size: 24px; font-weight: 800; color: #f8fafc; margin: 0; letter-spacing: -0.4px;">Social Triggers</h1>
                            <span class="select-trigger-pill-badge" style="background: rgba(14, 165, 233, 0.15); border: 1px solid rgba(14, 165, 233, 0.4); color: #38bdf8; font-size: 11px; font-weight: 800; padding: 3px 10px; border-radius: 9999px; text-transform: uppercase; letter-spacing: 0.6px;">EVENT DISPATCHER</span>
                        </div>
                        <p style="font-size: 13px; color: #94a3b8; margin: 6px 0 0 0;">
                            Reward stream engagement, viewer chat, follower goals, and social events with in-game spawns and bonuses!
                        </p>
                    </div>
                    <div style="display: flex; gap: 10px; align-items: center;">
                        <button type="button" class="btn btn-primary" onclick="openTriggerSelectorModal('likes_person', 'social_tab')"
                            style="display: inline-flex; align-items: center; gap: 7px; font-weight: 700; padding: 8px 16px; border-radius: 8px; cursor: pointer; box-shadow: 0 4px 14px rgba(56, 189, 248, 0.25);">
                            <span>⚡</span> Select Trigger Modal
                        </button>
                    </div>
                </div>

                <!-- EMBEDDED SELECT TRIGGER EVENT DISPATCHER (EXACT REPLICA OF USER IMAGE 1) -->
                <div class="social-trigger-dispatcher-card" style="background: #0b1120; border: 1.5px solid rgba(56, 189, 248, 0.25); border-radius: 16px; padding: 18px 22px; margin-bottom: 24px; box-shadow: 0 16px 36px rgba(0, 0, 0, 0.45), inset 0 1px 0 rgba(255, 255, 255, 0.08);">
                    <!-- Header -->
                    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px; flex-wrap: wrap; gap: 10px;">
                        <div style="display: flex; align-items: center; gap: 10px;">
                            <span style="font-size: 20px; line-height: 1;">⚡</span>
                            <h3 style="margin: 0; font-size: 18px; font-weight: 800; color: #f8fafc;">Select Trigger</h3>
                            <span class="select-trigger-pill-badge" style="background: rgba(14, 165, 233, 0.15); border: 1px solid rgba(14, 165, 233, 0.4); color: #38bdf8; font-size: 10px; font-weight: 800; padding: 2px 8px; border-radius: 9999px; text-transform: uppercase;">EVENT DISPATCHER</span>
                        </div>
                        
                        <div class="trigger-platform-tabs" style="margin: 0;">
                            <div class="btn-platform active" style="padding: 6px 14px; cursor: default;">
                                <svg width="15" height="15" viewBox="0 0 24 24" fill="currentColor">
                                    <path d="M19.59 6.69a4.83 4.83 0 0 1-3.77-4.25V2h-3.45v13.67a2.89 2.89 0 0 1-5.2 1.74 2.89 2.89 0 0 1 2.31-4.64c.298-.002.595.042.88.13V9.4a6.33 6.33 0 0 0-1-.08A6.34 6.34 0 0 0 3 15.66a6.34 6.34 0 0 0 10.82 4.49 6.27 6.27 0 0 0 1.91-4.49V8.62a8.28 8.28 0 0 0 4.86 1.57v-3.5Z" />
                                </svg>
                                <span style="font-size: 12.5px; font-weight: 700;">TikTok LIVE</span>
                                <span class="platform-live-badge"><span class="platform-active-dot"></span> LIVE</span>
                            </div>
                        </div>
                    </div>

                    <!-- AVAILABLE FOR DROPDOWN -->
                    <div style="margin-bottom: 14px;">
                        <label style="display: block; font-size: 11px; font-weight: 800; text-transform: uppercase; color: #94a3b8; letter-spacing: 0.6px; margin-bottom: 6px;">Available For</label>
                        <select id="socialAudienceSelect" class="trigger-audience-select" onchange="onSocialAudienceChanged(this.value)">
                            <option value="Anyone" selected>Anyone</option>
                            <option value="Followers only">Followers only</option>
                            <option value="Subscribers only">Subscribers only</option>
                            <option value="Moderators only">Moderators only</option>
                            <option value="Super Fans">Super Fans</option>
                        </select>
                    </div>

                    <hr class="trigger-modal-divider" style="margin-bottom: 14px;">

                    <!-- 10 TRIGGER CARDS (2 ROWS x 5 COLUMNS) -->
                    <div class="trigger-cards-grid" id="socialTabTriggerGrid">
                        <!-- 1. Gift -->
                        <div class="trig-card" data-trigger="gift" onclick="selectSocialTriggerCard('gift')">
                            <div class="trig-icon-wrap">
                                <svg class="anim-gift" width="34" height="34" viewBox="0 0 36 36" fill="none">
                                    <defs>
                                        <linearGradient id="tgGiftBoxSocial" x1="0%" y1="0%" x2="100%" y2="100%">
                                            <stop offset="0%" stop-color="#ff3366" />
                                            <stop offset="100%" stop-color="#be123c" />
                                        </linearGradient>
                                        <linearGradient id="tgRibbonSocial" x1="0%" y1="0%" x2="100%" y2="0%">
                                            <stop offset="0%" stop-color="#fde047" />
                                            <stop offset="100%" stop-color="#f59e0b" />
                                        </linearGradient>
                                    </defs>
                                    <rect x="5" y="14" width="26" height="18" rx="4" fill="url(#tgGiftBoxSocial)" />
                                    <rect x="3" y="10" width="30" height="6" rx="2.5" fill="#fb7185" />
                                    <rect x="15.5" y="10" width="5" height="22" fill="url(#tgRibbonSocial)" />
                                    <rect x="5" y="20.5" width="26" height="4" fill="url(#tgRibbonSocial)" opacity="0.9" />
                                    <path d="M14 6c-3.5 0-5.5 2-3.5 4.5 1.8 2 5.5 0.5 7.5-0.5-2-1-3-4-4-4z" fill="url(#tgRibbonSocial)" />
                                    <path d="M22 6c3.5 0 5.5 2 3.5 4.5-1.8 2-5.5 0.5-7.5-0.5 2-1 3-4 4-4z" fill="url(#tgRibbonSocial)" />
                                    <circle cx="18" cy="9.5" r="2.2" fill="#fef08a" />
                                    <path d="M28 8l1 2 2 1-2 1-1 2-1-2-2-1 2-1z" fill="#fde047" opacity="0.85" />
                                </svg>
                            </div>
                            <span class="trig-card-name">Gift</span>
                        </div>

                        <!-- 2. Likes By Person (Active Default) -->
                        <div class="trig-card active" data-trigger="likes_person" onclick="selectSocialTriggerCard('likes_person')">
                            <div class="trig-icon-wrap">
                                <svg class="anim-heart-person" width="34" height="34" viewBox="0 0 36 36" fill="none">
                                    <defs>
                                        <linearGradient id="tgHeartGradSocial" x1="0%" y1="0%" x2="100%" y2="100%">
                                            <stop offset="0%" stop-color="#ff3b69" />
                                            <stop offset="50%" stop-color="#fe2c55" />
                                            <stop offset="100%" stop-color="#b91c1c" />
                                        </linearGradient>
                                    </defs>
                                    <path d="M18 31.5l-2.2-2C7.8 22.2 3 17.8 3 12.3 3 7.8 6.5 4.3 11 4.3c2.5 0 5 1.2 7 3.1 2-1.9 4.5-3.1 7-3.1 4.5 0 8 3.5 8 8 0 5.5-4.8 9.9-12.8 17.2L18 31.5z" fill="url(#tgHeartGradSocial)" />
                                    <ellipse cx="11.5" cy="10" rx="3.5" ry="2" fill="rgba(255,255,255,0.45)" transform="rotate(-30 11.5 10)" />
                                    <circle cx="28" cy="7" r="2" fill="#ff708f" opacity="0.8" />
                                </svg>
                            </div>
                            <span class="trig-card-name">Likes By Person</span>
                        </div>

                        <!-- 3. All Likes -->
                        <div class="trig-card" data-trigger="likes_all" onclick="selectSocialTriggerCard('likes_all')">
                            <div class="trig-icon-wrap">
                                <svg class="anim-stream-all" width="34" height="34" viewBox="0 0 36 36" fill="none">
                                    <defs>
                                        <linearGradient id="tgCyanHeartSocial" x1="0%" y1="0%" x2="100%" y2="100%">
                                            <stop offset="0%" stop-color="#38bdf8" />
                                            <stop offset="60%" stop-color="#0284c7" />
                                            <stop offset="100%" stop-color="#0369a1" />
                                        </linearGradient>
                                        <linearGradient id="tgPulseRingSocial" x1="0%" y1="0%" x2="100%" y2="100%">
                                            <stop offset="0%" stop-color="#7dd3fc" />
                                            <stop offset="100%" stop-color="#38bdf8" />
                                        </linearGradient>
                                    </defs>
                                    <path d="M18 32l-2-1.8C8.5 23 4 19 4 13.8 4 9.6 7.2 6.5 11.4 6.5c2.3 0 4.6 1.1 6.6 2.9 2-1.8 4.3-2.9 6.6-2.9 4.2 0 7.4 3.1 7.4 7.3 0 5.2-4.5 9.2-12 16.4L18 32z" fill="url(#tgPulseRingSocial)" opacity="0.3" transform="scale(1.08) translate(-1.3, -1.3)" />
                                    <path d="M18 31l-2-1.8C8.5 22.3 4 18.5 4 13.5 4 9.5 7.2 6.5 11.3 6.5c2.3 0 4.6 1.1 6.7 2.9 2.1-1.8 4.4-2.9 6.7-2.9 4.1 0 7.3 3 7.3 7 0 5-4.5 8.8-12 15.7L18 31z" fill="url(#tgCyanHeartSocial)" />
                                    <ellipse cx="11.5" cy="11.5" rx="3.2" ry="1.8" fill="rgba(255,255,255,0.55)" transform="rotate(-30 11.5 11.5)" />
                                    <path d="M28 8l0.8 1.5 1.5 0.8-1.5 0.8-0.8 1.5-0.8-1.5-1.5-0.8 1.5-0.8z" fill="#bae6fd" />
                                </svg>
                            </div>
                            <span class="trig-card-name">All Likes</span>
                        </div>

                        <!-- 4. Follow -->
                        <div class="trig-card" data-trigger="follow" onclick="selectSocialTriggerCard('follow')">
                            <div class="trig-icon-wrap">
                                <svg class="anim-follow-beacon" width="34" height="34" viewBox="0 0 36 36" fill="none">
                                    <defs>
                                        <linearGradient id="tgFollowGradSocial" x1="0%" y1="0%" x2="100%" y2="100%">
                                            <stop offset="0%" stop-color="#34d399" />
                                            <stop offset="100%" stop-color="#059669" />
                                        </linearGradient>
                                    </defs>
                                    <circle cx="14" cy="11" r="5.5" fill="url(#tgFollowGradSocial)" />
                                    <path d="M5 28c0-5 4-8 9-8s9 3 9 8v1.5H5V28z" fill="url(#tgFollowGradSocial)" />
                                    <circle cx="26" cy="14" r="6.5" fill="#10b981" />
                                    <rect x="24.8" y="10.5" width="2.4" height="7" rx="1.2" fill="#ffffff" />
                                    <rect x="22.5" y="12.8" width="7" height="2.4" rx="1.2" fill="#ffffff" />
                                </svg>
                            </div>
                            <span class="trig-card-name">Follow</span>
                        </div>

                        <!-- 5. Min-Max coins -->
                        <div class="trig-card" data-trigger="coins_range" onclick="selectSocialTriggerCard('coins_range')">
                            <div class="trig-icon-wrap">
                                <svg class="anim-coins-sparkle" width="34" height="34" viewBox="0 0 36 36" fill="none">
                                    <defs>
                                        <linearGradient id="tgCoinGoldSocial" x1="0%" y1="0%" x2="100%" y2="100%">
                                            <stop offset="0%" stop-color="#fef08a" />
                                            <stop offset="40%" stop-color="#facc15" />
                                            <stop offset="100%" stop-color="#b45309" />
                                        </linearGradient>
                                        <linearGradient id="tgCoinBackSocial" x1="0%" y1="0%" x2="100%" y2="100%">
                                            <stop offset="0%" stop-color="#fbbf24" />
                                            <stop offset="100%" stop-color="#78350f" />
                                        </linearGradient>
                                    </defs>
                                    <circle cx="22" cy="14" r="10" fill="url(#tgCoinBackSocial)" stroke="#fde047" stroke-width="1.2" />
                                    <circle cx="22" cy="14" r="7" fill="none" stroke="rgba(255,255,255,0.3)" stroke-width="1" />
                                    <circle cx="14" cy="20" r="11" fill="url(#tgCoinGoldSocial)" stroke="#fef08a" stroke-width="1.5" />
                                    <circle cx="14" cy="20" r="8" fill="none" stroke="rgba(255,255,255,0.4)" stroke-width="1" />
                                    <path d="M14 14.5l1.5 3.5 3.5 0.5-2.7 2.2 0.8 3.8-3.1-1.8-3.1 1.8 0.8-3.8-2.7-2.2 3.5-0.5z" fill="#ffffff" opacity="0.9" />
                                    <path d="M28 6l0.8 1.6 1.6 0.8-1.6 0.8-0.8 1.6-0.8-1.6-1.6-0.8 1.6-0.8z" fill="#fef08a" />
                                </svg>
                            </div>
                            <span class="trig-card-name">Min-Max coins</span>
                        </div>

                        <!-- 6. Viewer Joined -->
                        <div class="trig-card" data-trigger="viewer_join" onclick="selectSocialTriggerCard('viewer_join')">
                            <div class="trig-icon-wrap">
                                <svg class="anim-sonar-wave" width="34" height="34" viewBox="0 0 36 36" fill="none">
                                    <defs>
                                        <linearGradient id="tgJoinGradSocial" x1="0%" y1="0%" x2="100%" y2="100%">
                                            <stop offset="0%" stop-color="#c084fc" />
                                            <stop offset="100%" stop-color="#7c3aed" />
                                        </linearGradient>
                                    </defs>
                                    <circle cx="18" cy="18" r="15" stroke="#a855f7" stroke-width="1.4" stroke-dasharray="3 3" opacity="0.5" />
                                    <circle cx="18" cy="18" r="10.5" stroke="#c084fc" stroke-width="1.8" opacity="0.75" />
                                    <circle cx="18" cy="18" r="6" fill="url(#tgJoinGradSocial)" />
                                    <circle cx="18" cy="18" r="2.5" fill="#ffffff" />
                                    <path d="M18 4l2.5 3.5h-5z" fill="#c084fc" />
                                </svg>
                            </div>
                            <span class="trig-card-name">Viewer Joined</span>
                        </div>

                        <!-- 7. Chat -->
                        <div class="trig-card" data-trigger="chat" onclick="selectSocialTriggerCard('chat')">
                            <div class="trig-icon-wrap">
                                <svg width="34" height="34" viewBox="0 0 36 36" fill="none">
                                    <defs>
                                        <linearGradient id="tgChatGradSocial" x1="0%" y1="0%" x2="100%" y2="100%">
                                            <stop offset="0%" stop-color="#38bdf8" />
                                            <stop offset="100%" stop-color="#2563eb" />
                                        </linearGradient>
                                    </defs>
                                    <path d="M6 8a4 4 0 0 1 4-4h16a4 4 0 0 1 4 4v14a4 4 0 0 1-4 4h-9l-5 4.5V26H10a4 4 0 0 1-4-4V8z" fill="url(#tgChatGradSocial)" />
                                    <path d="M10 6h16a2 2 0 0 1 2 2v1h-20V8a2 2 0 0 1 2-2z" fill="rgba(255,255,255,0.25)" />
                                    <circle class="anim-chat-dot1" cx="12" cy="15" r="2.2" fill="#ffffff" />
                                    <circle class="anim-chat-dot2" cx="18" cy="15" r="2.2" fill="#ffffff" />
                                    <circle class="anim-chat-dot3" cx="24" cy="15" r="2.2" fill="#ffffff" />
                                </svg>
                            </div>
                            <span class="trig-card-name">Chat</span>
                        </div>

                        <!-- 8. Share -->
                        <div class="trig-card" data-trigger="share" onclick="selectSocialTriggerCard('share')">
                            <div class="trig-icon-wrap">
                                <svg class="anim-share-arrow" width="34" height="34" viewBox="0 0 36 36" fill="none">
                                    <defs>
                                        <linearGradient id="tgShareGradSocial" x1="0%" y1="0%" x2="100%" y2="100%">
                                            <stop offset="0%" stop-color="#fb923c" />
                                            <stop offset="50%" stop-color="#f97316" />
                                            <stop offset="100%" stop-color="#c2410c" />
                                        </linearGradient>
                                    </defs>
                                    <path d="M4 24h6" stroke="#fdba74" stroke-width="2" stroke-linecap="round" opacity="0.6" />
                                    <path d="M6 28h5" stroke="#fdba74" stroke-width="1.8" stroke-linecap="round" opacity="0.4" />
                                    <path d="M17 12V6l15 12-15 12v-6.2C7 23.8 4 30 4 30c1.5-10 6-18 13-18z" fill="url(#tgShareGradSocial)" />
                                    <path d="M17 12l10 6-10-1v-5z" fill="rgba(255,255,255,0.35)" />
                                </svg>
                            </div>
                            <span class="trig-card-name">Share</span>
                        </div>

                        <!-- 9. Super Fan -->
                        <div class="trig-card" data-trigger="super_fan" onclick="selectSocialTriggerCard('super_fan')">
                            <div class="trig-icon-wrap">
                                <svg class="anim-crown-stars" width="34" height="34" viewBox="0 0 36 36" fill="none">
                                    <defs>
                                        <linearGradient id="tgCrownGoldSocial" x1="0%" y1="0%" x2="100%" y2="100%">
                                            <stop offset="0%" stop-color="#fef08a" />
                                            <stop offset="50%" stop-color="#f59e0b" />
                                            <stop offset="100%" stop-color="#d97706" />
                                        </linearGradient>
                                        <linearGradient id="tgCrownRubySocial" x1="0%" y1="0%" x2="100%" y2="100%">
                                            <stop offset="0%" stop-color="#f43f5e" />
                                            <stop offset="100%" stop-color="#be123c" />
                                        </linearGradient>
                                    </defs>
                                    <path d="M5 25l3-14 6 7 4-10 4 10 6-7 3 14H5z" fill="url(#tgCrownGoldSocial)" />
                                    <rect x="5" y="24" width="26" height="5" rx="2" fill="#b45309" />
                                    <circle cx="10" cy="26.5" r="1.5" fill="url(#tgCrownRubySocial)" />
                                    <circle cx="18" cy="26.5" r="1.8" fill="#38bdf8" />
                                    <circle cx="26" cy="26.5" r="1.5" fill="url(#tgCrownRubySocial)" />
                                    <circle cx="5" cy="11" r="2.2" fill="#fef08a" />
                                    <circle cx="18" cy="8" r="2.8" fill="#fef08a" />
                                    <circle cx="31" cy="11" r="2.2" fill="#fef08a" />
                                    <path d="M18 2l0.8 1.6 1.6 0.8-1.6 0.8-0.8 1.6-0.8-1.6-1.6-0.8 1.6-0.8z" fill="#fef08a" />
                                </svg>
                            </div>
                            <span class="trig-card-name">Super Fan</span>
                        </div>

                        <!-- 10. Custom -->
                        <div class="trig-card" data-trigger="custom" onclick="selectSocialTriggerCard('custom')">
                            <div class="trig-icon-wrap">
                                <svg width="34" height="34" viewBox="0 0 36 36" fill="none">
                                    <defs>
                                        <linearGradient id="tgGear1Social" x1="0%" y1="0%" x2="100%" y2="100%">
                                            <stop offset="0%" stop-color="#22d3ee" />
                                            <stop offset="100%" stop-color="#0284c7" />
                                        </linearGradient>
                                        <linearGradient id="tgGear2Social" x1="0%" y1="0%" x2="100%" y2="100%">
                                            <stop offset="0%" stop-color="#38bdf8" />
                                            <stop offset="100%" stop-color="#0369a1" />
                                        </linearGradient>
                                    </defs>
                                    <g class="anim-gear-spin">
                                        <circle cx="15" cy="15" r="7.5" fill="url(#tgGear1Social)" />
                                        <circle cx="15" cy="15" r="3.2" fill="#0f172a" />
                                        <path d="M13.5 4.5h3v3h-3zM13.5 22.5h3v3h-3zM4.5 13.5h3v3h-3zM22.5 13.5h3v3h-3z" fill="url(#tgGear1Social)" />
                                        <path d="M7.5 7.5l2.2 2.2-2.2 2.2-2.2-2.2zM20.3 20.3l2.2 2.2-2.2 2.2-2.2-2.2z" fill="url(#tgGear1Social)" />
                                    </g>
                                    <g class="anim-gear-spin-rev">
                                        <circle cx="25" cy="25" r="5" fill="url(#tgGear2Social)" />
                                        <circle cx="25" cy="25" r="2.2" fill="#0f172a" />
                                        <path d="M24 17h2v2h-2zM24 31h2v2h-2zM17 24h2v2h-2zM31 24h2v2h-2z" fill="url(#tgGear2Social)" />
                                    </g>
                                </svg>
                            </div>
                            <span class="trig-card-name">Custom</span>
                        </div>
                    </div>
                </div>

                <!-- CONFIGURED TRIGGER CARDS SECTION -->
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px;">
                    <div style="font-size: 13px; font-weight: 800; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.5px;">
                        Configured Trigger Actions
                    </div>
                    <span id="socialFilterBadge" style="font-size: 11px; font-weight: 700; color: #38bdf8; background: rgba(56, 189, 248, 0.1); border: 1px solid rgba(56, 189, 248, 0.3); padding: 2px 8px; border-radius: 6px;">
                        Showing All Triggers
                    </span>
                </div>

                <div class="card-grid" id="socialCardsList">
                    <!-- CARD 1: LIKES BY PERSON (EVERY 50 LIKES) -->
                    <div class="command-card" id="cardSocialLikesPerson" data-social-type="likes_person">
                        <div class="command-card-header">
                            <div class="gift-info">
                                <div class="gift-img-wrap"
                                    style="background: rgba(239,68,68,0.15); border-color: rgba(239,68,68,0.3);">
                                    <span style="font-size: 14px; font-weight: 800; color: #ef4444;">LIKES</span>
                                </div>
                                <div>
                                    <div class="gift-name" id="socialLikesPersonTitle">Every 50 Likes</div>
                                    <div class="gift-coins" id="socialLikesPersonSubtitle">Likes By Person (Team Zombies)</div>
                                </div>
                            </div>
                            <input type="checkbox" id="socialLikesToggle" checked onchange="saveSocialConfig()">
                        </div>
                        <div class="action-preview">
                            <div style="display: flex; align-items: center; gap: 8px;">
                                <img id="socialLikesPersonImg" src="images/game-icons/pvz/spawn_trident_juggernut_gargantuar.webp"
                                    style="width: 32px; height: 32px; border-radius: 6px; object-fit: contain; background: rgba(0,0,0,0.5);">
                                <div>
                                    <span class="action-badge zombie" id="socialLikesPersonBadge">Zombie</span>
                                    <div id="socialLikesActionName" class="action-name" style="margin-top: 4px;">
                                        Spawn Trident Jugger-nut Gargantuar (240)
                                    </div>
                                </div>
                            </div>
                            <div class="action-count" id="socialLikesPersonCount">x1</div>
                        </div>
                        <div class="command-card-footer">
                            <button class="btn-test" onclick="testSocial('likes_person')">⚡ Test 50 Likes</button>
                            <button class="btn-edit" onclick="editSocial('likes_person')">✏️ Edit</button>
                        </div>
                    </div>

                    <!-- CARD 2: ALL LIKES (STREAM GOAL MILESTONE) -->
                    <div class="command-card" id="cardSocialLikesAll" data-social-type="likes_all">
                        <div class="command-card-header">
                            <div class="gift-info">
                                <div class="gift-img-wrap"
                                    style="background: rgba(56,189,248,0.15); border-color: rgba(56,189,248,0.3);">
                                    <span style="font-size: 14px; font-weight: 800; color: #38bdf8;">GOAL</span>
                                </div>
                                <div>
                                    <div class="gift-name" id="socialLikesAllTitle">50K Stream Likes Goal</div>
                                    <div class="gift-coins">All Likes Milestone (Entire Room)</div>
                                </div>
                            </div>
                            <input type="checkbox" id="socialLikesAllToggle" checked onchange="saveSocialConfig()">
                        </div>
                        <div class="action-preview">
                            <div style="display: flex; align-items: center; gap: 8px;">
                                <img id="socialLikesAllImg" src="images/game-icons/pvz/spawn_super_horse.webp"
                                    style="width: 32px; height: 32px; border-radius: 6px; object-fit: contain; background: rgba(0,0,0,0.5);">
                                <div>
                                    <span class="action-badge power" id="socialLikesAllBadge">Power</span>
                                    <div id="socialLikesAllActionName" class="action-name" style="margin-top: 4px;">
                                        Spawn SummonedHorse (Milestone)
                                    </div>
                                </div>
                            </div>
                            <div class="action-count" id="socialLikesAllCount">x1</div>
                        </div>
                        <div class="command-card-footer">
                            <button class="btn-test" onclick="testSocial('likes_all')">⚡ Test Stream Goal</button>
                            <button class="btn-edit" onclick="editSocial('likes_all')">✏️ Edit</button>
                        </div>
                    </div>

                    <!-- CARD 3: NEW FOLLOWER -->
                    <div class="command-card" id="cardSocialFollow" data-social-type="follow">
                        <div class="command-card-header">
                            <div class="gift-info">
                                <div class="gift-img-wrap"
                                    style="background: rgba(16,185,129,0.15); border-color: rgba(16,185,129,0.3);">
                                    <span style="font-size: 14px; font-weight: 800; color: #10b981;">FOLLOW</span>
                                </div>
                                <div>
                                    <div class="gift-name">New Follower</div>
                                    <div class="gift-coins">Instant Follow Trigger</div>
                                </div>
                            </div>
                            <input type="checkbox" id="socialFollowToggle" checked onchange="saveSocialConfig()">
                        </div>
                        <div class="action-preview">
                            <div style="display: flex; align-items: center; gap: 8px;">
                                <img id="socialFollowImg" src="images/game-icons/pvz/spawn_super_horse.webp"
                                    style="width: 32px; height: 32px; border-radius: 6px; object-fit: contain; background: rgba(0,0,0,0.5);">
                                <div>
                                    <span class="action-badge plant" id="socialFollowBadge">Plant</span>
                                    <div id="socialFollowActionName" class="action-name" style="margin-top: 4px;">
                                        Spawn SummonedHorse
                                    </div>
                                </div>
                            </div>
                            <div class="action-count" id="socialFollowCount">x1</div>
                        </div>
                        <div class="command-card-footer">
                            <button class="btn-test" onclick="testSocial('follow')">⚡ Test Follow</button>
                            <button class="btn-edit" onclick="editSocial('follow')">✏️ Edit</button>
                        </div>
                    </div>

                    <!-- CARD 4: STREAM SHARE -->
                    <div class="command-card" id="cardSocialShare" data-social-type="share">
                        <div class="command-card-header">
                            <div class="gift-info">
                                <div class="gift-img-wrap"
                                    style="background: rgba(249,115,22,0.15); border-color: rgba(249,115,22,0.3);">
                                    <span style="font-size: 14px; font-weight: 800; color: #f97316;">SHARE</span>
                                </div>
                                <div>
                                    <div class="gift-name">Stream Share</div>
                                    <div class="gift-coins">Instant Share Trigger</div>
                                </div>
                            </div>
                            <input type="checkbox" id="socialShareToggle" checked onchange="saveSocialConfig()">
                        </div>
                        <div class="action-preview">
                            <div style="display: flex; align-items: center; gap: 8px;">
                                <img id="socialShareImg" src="images/game-icons/pvz/planteverywhere.webp"
                                    style="width: 32px; height: 32px; border-radius: 6px; object-fit: contain; background: rgba(0,0,0,0.5);">
                                <div>
                                    <span class="action-badge power" id="socialShareBadge">Power</span>
                                    <div id="socialShareActionName" class="action-name" style="margin-top: 4px;">
                                        Plant Everywhere Mode (Share)
                                    </div>
                                </div>
                            </div>
                            <div class="action-count" id="socialShareCount">x1</div>
                        </div>
                        <div class="command-card-footer">
                            <button class="btn-test" onclick="testSocial('share')">⚡ Test Share</button>
                            <button class="btn-edit" onclick="editSocial('share')">✏️ Edit</button>
                        </div>
                    </div>

                    <!-- CARD 5: VIEWER JOIN / STREAM WELCOME ALERT -->
                    <div class="command-card" id="cardSocialViewerJoin" data-social-type="viewer_join"
                        style="border: 1px solid rgba(245,158,11,0.35); background: linear-gradient(180deg, rgba(245,158,11,0.08) 0%, rgba(13,17,23,0.7) 100%);">
                        <div class="command-card-header">
                            <div class="gift-info">
                                <div class="gift-img-wrap"
                                    style="background: rgba(245,158,11,0.15); border-color: rgba(245,158,11,0.4); box-shadow: 0 0 10px rgba(245,158,11,0.2);">
                                    <span style="font-size: 14px; font-weight: 900; color: #f59e0b; text-shadow: 0 0 8px rgba(245,158,11,0.5);">🌟 JOIN</span>
                                </div>
                                <div>
                                    <div class="gift-name" style="color: #f1f5f9; display: flex; align-items: center; gap: 6px;">
                                        Viewer Join Alert
                                        <span style="font-size: 9px; font-weight: 800; background: linear-gradient(135deg, #f59e0b, #d97706); color: #000; padding: 1px 6px; border-radius: 9999px;">OBS OVERLAY</span>
                                    </div>
                                    <div class="gift-coins" style="color: #94a3b8;">Welcome Ribbon & Groudon Badge</div>
                                </div>
                            </div>
                            <input type="checkbox" id="socialJoinToggle" checked onchange="saveSocialJoinToggle()">
                        </div>
                        <div class="action-preview"
                            style="background: rgba(0,0,0,0.3); border-radius: 8px; padding: 10px; display: flex; align-items: center; justify-content: space-between;">
                            <div style="display: flex; align-items: center; gap: 10px;">
                                <div style="width: 38px; height: 38px; border-radius: 50%; background: radial-gradient(circle, #ffe066 0%, #b8860b 80%); display: flex; align-items: center; justify-content: center; font-size: 20px; box-shadow: 0 0 10px rgba(245,158,11,0.5);">
                                    ⭐
                                </div>
                                <div>
                                    <span class="action-badge power" style="background: linear-gradient(135deg, #7c3aed, #4f46e5); color: #fff; font-size: 10px; font-weight: 800; padding: 2px 8px; border-radius: 4px;">Royal Ribbon</span>
                                    <div id="socialJoinActionName" class="action-name" style="margin-top: 4px; font-size: 13px; font-weight: 800; color: #fff;">
                                        NEW FOLLOWER • renearn joined!
                                    </div>
                                </div>
                            </div>
                            <button type="button" class="btn btn-secondary btn-sm" onclick="copyJoinOverlayUrl()"
                                style="font-size: 11px; padding: 4px 8px; background: rgba(255,255,255,0.06); border: 1px solid rgba(255,255,255,0.12); color: #38bdf8; border-radius: 6px; cursor: pointer;">
                                📋 Copy Link
                            </button>
                        </div>
                        <div class="command-card-footer" style="display: flex; gap: 8px; margin-top: 10px; flex-wrap: wrap;">
                            <button type="button" class="btn-test" onclick="triggerTestJoinAlert()"
                                style="flex: 1.2; background: linear-gradient(135deg, #f59e0b, #d97706); color: #000; font-weight: 800; border: none; border-radius: 6px; padding: 7px 10px; cursor: pointer;">
                                ⚡ Test Join Alert
                            </button>
                            <button type="button" class="btn btn-sm" onclick="triggerConsecutiveJoinTest(3)"
                                style="flex: 1; background: linear-gradient(135deg, #10b981, #059669); color: #fff; font-weight: 800; border: none; border-radius: 6px; padding: 7px 10px; cursor: pointer;"
                                title="Simulate 3 viewers joining consecutively in queue">
                                👥 +3 Queue
                            </button>
                            <button type="button" class="btn btn-sm" onclick="clearJoinAlertQueue()"
                                style="background: rgba(239, 68, 68, 0.2); border: 1px solid rgba(239, 68, 68, 0.5); color: #f87171; border-radius: 6px; font-size: 11px; font-weight: 700; padding: 0 10px; cursor: pointer;"
                                title="Stop & clear queue">
                                🛑 Clear
                            </button>
                        </div>
                    </div>

                    <!-- CARD 6: CHAT KEYWORD TRIGGER -->
                    <div class="command-card" id="cardSocialChat" data-social-type="chat">
                        <div class="command-card-header">
                            <div class="gift-info">
                                <div class="gift-img-wrap"
                                    style="background: rgba(37,99,235,0.15); border-color: rgba(37,99,235,0.3);">
                                    <span style="font-size: 14px; font-weight: 800; color: #38bdf8;">CHAT</span>
                                </div>
                                <div>
                                    <div class="gift-name">Chat Keyword Trigger</div>
                                    <div class="gift-coins">Matches '!zombie' or stream chat keywords</div>
                                </div>
                            </div>
                            <input type="checkbox" id="socialChatToggle" checked onchange="saveSocialConfig()">
                        </div>
                        <div class="action-preview">
                            <div style="display: flex; align-items: center; gap: 8px;">
                                <div style="width: 32px; height: 32px; border-radius: 6px; background: rgba(56, 189, 248, 0.2); display: flex; align-items: center; justify-content: center; font-size: 16px;">💬</div>
                                <div>
                                    <span class="action-badge power">Chat</span>
                                    <div id="socialChatActionName" class="action-name" style="margin-top: 4px;">
                                        Summon on Chat Keyword (!zombie)
                                    </div>
                                </div>
                            </div>
                            <div class="action-count">x1</div>
                        </div>
                        <div class="command-card-footer">
                            <button class="btn-test" onclick="testSocial('chat')">⚡ Test Chat Command</button>
                            <button class="btn-edit" onclick="editSocial('chat')">✏️ Edit</button>
                        </div>
                    </div>

                    <!-- CARD 7: SUPER FAN / SUBSCRIBER -->
                    <div class="command-card" id="cardSocialSuperFan" data-social-type="super_fan">
                        <div class="command-card-header">
                            <div class="gift-info">
                                <div class="gift-img-wrap"
                                    style="background: rgba(245,158,11,0.15); border-color: rgba(245,158,11,0.4);">
                                    <span style="font-size: 14px; font-weight: 800; color: #fbbf24;">VIP</span>
                                </div>
                                <div>
                                    <div class="gift-name">Super Fan / Subscriber Perk</div>
                                    <div class="gift-coins">Exclusive Member Trigger</div>
                                </div>
                            </div>
                            <input type="checkbox" id="socialSuperFanToggle" checked onchange="saveSocialConfig()">
                        </div>
                        <div class="action-preview">
                            <div style="display: flex; align-items: center; gap: 8px;">
                                <div style="width: 32px; height: 32px; border-radius: 6px; background: rgba(245, 158, 11, 0.2); display: flex; align-items: center; justify-content: center; font-size: 16px;">👑</div>
                                <div>
                                    <span class="action-badge power" style="background: linear-gradient(135deg, #f59e0b, #d97706); color: #000;">Subscriber</span>
                                    <div id="socialSuperFanActionName" class="action-name" style="margin-top: 4px;">
                                        Super Fan Mega Wave Summon
                                    </div>
                                </div>
                            </div>
                            <div class="action-count">x1</div>
                        </div>
                        <div class="command-card-footer">
                            <button class="btn-test" onclick="testSocial('super_fan')">⚡ Test Super Fan</button>
                            <button class="btn-edit" onclick="editSocial('super_fan')">✏️ Edit</button>
                        </div>
                    </div>

                    <!-- CARD 8: MIN-MAX COINS RANGE -->
                    <div class="command-card" id="cardSocialCoinsRange" data-social-type="coins_range">
                        <div class="command-card-header">
                            <div class="gift-info">
                                <div class="gift-img-wrap"
                                    style="background: rgba(234,179,8,0.15); border-color: rgba(234,179,8,0.3);">
                                    <span style="font-size: 14px; font-weight: 800; color: #eab308;">COINS</span>
                                </div>
                                <div>
                                    <div class="gift-name">Min-Max Coins Range</div>
                                    <div class="gift-coins">Summons on gifts within coin bracket</div>
                                </div>
                            </div>
                            <input type="checkbox" id="socialCoinsRangeToggle" checked onchange="saveSocialConfig()">
                        </div>
                        <div class="action-preview">
                            <div style="display: flex; align-items: center; gap: 8px;">
                                <div style="width: 32px; height: 32px; border-radius: 6px; background: rgba(234, 179, 8, 0.2); display: flex; align-items: center; justify-content: center; font-size: 16px;">🪙</div>
                                <div>
                                    <span class="action-badge zombie">Bracket</span>
                                    <div id="socialCoinsRangeActionName" class="action-name" style="margin-top: 4px;">
                                        Coin Range Spawns (100 - 500 Coins)
                                    </div>
                                </div>
                            </div>
                            <div class="action-count">x1</div>
                        </div>
                        <div class="command-card-footer">
                            <button class="btn-test" onclick="testSocial('coins_range')">⚡ Test Coins Bracket</button>
                            <button class="btn-edit" onclick="editSocial('coins_range')">✏️ Edit</button>
                        </div>
                    </div>

                    <!-- CARD 9: TIKTOK GIFTS LINK -->
                    <div class="command-card" id="cardSocialGift" data-social-type="gift">
                        <div class="command-card-header">
                            <div class="gift-info">
                                <div class="gift-img-wrap"
                                    style="background: rgba(244,63,94,0.15); border-color: rgba(244,63,94,0.3);">
                                    <span style="font-size: 14px; font-weight: 800; color: #f43f5e;">GIFTS</span>
                                </div>
                                <div>
                                    <div class="gift-name">TikTok Gift Commands</div>
                                    <div class="gift-coins">32+ Interactive Gift Triggers</div>
                                </div>
                            </div>
                            <span class="badge-pill" style="font-size: 10px; background: rgba(56, 189, 248, 0.2); color: #38bdf8;">ACTIVE</span>
                        </div>
                        <div class="action-preview">
                            <div style="display: flex; align-items: center; gap: 8px;">
                                <div style="width: 32px; height: 32px; border-radius: 6px; background: rgba(244, 63, 94, 0.2); display: flex; align-items: center; justify-content: center; font-size: 16px;">🎁</div>
                                <div>
                                    <span class="action-badge power">32 Gifts</span>
                                    <div class="action-name" style="margin-top: 4px;">
                                        Rose, Ice Cream, GG, Doughnut & More
                                    </div>
                                </div>
                            </div>
                            <div class="action-count">32+</div>
                        </div>
                        <div class="command-card-footer">
                            <button class="btn-primary" onclick="switchTab('commands')" style="width: 100%; font-weight: 700; padding: 8px 12px; border-radius: 6px; display: inline-flex; align-items: center; justify-content: center; gap: 6px; cursor: pointer;">
                                🎁 Manage TikTok Gift Commands
                            </button>
                        </div>
                    </div>

                    <!-- CARD 10: CUSTOM WEBHOOK / EVENT -->
                    <div class="command-card" id="cardSocialCustom" data-social-type="custom">
                        <div class="command-card-header">
                            <div class="gift-info">
                                <div class="gift-img-wrap"
                                    style="background: rgba(6,182,212,0.15); border-color: rgba(6,182,212,0.3);">
                                    <span style="font-size: 14px; font-weight: 800; color: #06b6d4;">CUSTOM</span>
                                </div>
                                <div>
                                    <div class="gift-name">Custom Event / Webhook</div>
                                    <div class="gift-coins">Direct In-Game Command Dispatcher</div>
                                </div>
                            </div>
                            <input type="checkbox" id="socialCustomToggle" checked onchange="saveSocialConfig()">
                        </div>
                        <div class="action-preview">
                            <div style="display: flex; align-items: center; gap: 8px;">
                                <div style="width: 32px; height: 32px; border-radius: 6px; background: rgba(6, 182, 212, 0.2); display: flex; align-items: center; justify-content: center; font-size: 16px;">⚙️</div>
                                <div>
                                    <span class="action-badge zombie">Custom</span>
                                    <div id="socialCustomActionName" class="action-name" style="margin-top: 4px;">
                                        Custom In-Game Command
                                    </div>
                                </div>
                            </div>
                            <div class="action-count">x1</div>
                        </div>
                        <div class="command-card-footer">
                            <button class="btn-test" onclick="testSocial('custom')">⚡ Test Custom Trigger</button>
                            <button class="btn-edit" onclick="editSocial('custom')">✏️ Edit</button>
                        </div>
                    </div>
                </div>
            </div>
            
"@

$newContent = $content.Substring(0, $startIdx) + $newSocialTab + $content.Substring($endIdx)

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Resolve-Path $appHtmlPath).Path, $newContent, $utf8NoBom)
Write-Host "tab-social upgraded successfully!"
