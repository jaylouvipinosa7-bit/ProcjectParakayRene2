/**
 * RENEarn Studio - Quiet Premium Sidebar Navigation Engine
 * Single-config driven menu, 20px consistent line-icon library,
 * sliding active highlight indicator, collapsible accordion controller,
 * and keyboard navigation.
 */

(function () {
    'use strict';

    // ==========================================
    // 1. CONSISTENT 20px LINE-ICON SVG REPOSITORY (1.75 stroke)
    // ==========================================
    const SVG_ICONS = {
        'dashboard': `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><rect width="7" height="9" x="3" y="3" rx="1"/><rect width="7" height="5" x="14" y="3" rx="1"/><rect width="7" height="9" x="14" y="12" rx="1"/><rect width="7" height="5" x="3" y="16" rx="1"/></svg>`,
        'gamemaster': `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><line x1="6" x2="10" y1="12" y2="12"/><line x1="8" x2="8" y1="10" y2="14"/><line x1="15" x2="15.01" y1="13" y2="13"/><line x1="18" x2="18.01" y1="11" y2="11"/><rect width="20" height="12" x="2" y="6" rx="2"/></svg>`,
        'gifts': `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="8" width="18" height="4" rx="1"/><path d="M12 8v13"/><path d="M19 12v7a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2v-7"/><path d="M7.5 8a2.5 2.5 0 0 1 0-5A4.8 8 0 0 1 12 8a4.8 8 0 0 1 4.5-5 2.5 2.5 0 0 1 0 5"/></svg>`,
        'spinner': `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M6 12c0-3.31 2.69-6 6-6v6"/><circle cx="12" cy="12" r="2"/></svg>`,
        'games': `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><path d="M21 17a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v2a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-2z"/><path d="M6 15v-2"/><path d="M12 15V9"/><circle cx="12" cy="6" r="3"/></svg>`,
        'presets': `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><polygon points="12 2 2 7 12 12 22 7 12 2"/><polyline points="2 17 12 22 22 17"/><polyline points="2 12 12 17 22 12"/></svg>`,
        'social': `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>`,
        'audio': `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/><path d="M15.54 8.46a5 5 0 0 1 0 7.07"/><path d="M19.07 4.93a10 10 0 0 1 0 14.14"/></svg>`,
        'overlays': `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><rect width="20" height="14" x="2" y="3" rx="2"/><line x1="8" x2="16" y1="21" y2="21"/><line x1="12" x2="12" y1="17" x2="12" y2="21"/></svg>`,
        'bot': `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><path d="M12 8V4H8"/><rect width="16" height="12" x="4" y="8" rx="2"/><path d="M2 14h2"/><path d="M20 14h2"/><path d="M15 13v2"/><path d="M9 13v2"/></svg>`,
        'tts': `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3Z"/><path d="M19 10v2a7 7 0 0 1-14 0v-2"/><line x1="12" x2="12" y1="19" y2="22"/></svg>`,
        'music': `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/></svg>`,
        'soundboard': `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><rect width="18" height="18" x="3" y="3" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><circle cx="15.5" cy="8.5" r="1.5"/><circle cx="8.5" cy="15.5" r="1.5"/><circle cx="15.5" cy="15.5" r="1.5"/></svg>`,
        'chevron': `<svg class="nav-chevron" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"></polyline></svg>`
    };

    window.SIDEBAR_ICONS = SVG_ICONS;

    // ==========================================
    // 2. DATA-DRIVEN SIDEBAR MENU CONFIG
    // ==========================================
    const SIDEBAR_MENU_CONFIG = [
        // Group 1: Core Navigation
        {
            group: 1,
            items: [
                {
                    id: 'sideBtnDashboard',
                    tab: 'dashboard',
                    label: 'Dashboard',
                    icon: 'dashboard',
                    badge: { type: 'live', text: 'LIVE' }
                },
                {
                    id: 'sideBtnGamemaster',
                    tab: 'gamemaster',
                    label: 'Game Master',
                    icon: 'gamemaster'
                }
            ]
        },
        // Group 2: Live Actions & Presets
        {
            group: 2,
            items: [
                {
                    id: 'sideBtnGifts',
                    tab: 'gifts',
                    label: 'Gift Commands',
                    icon: 'gifts',
                    badge: { type: 'neutral', id: 'sidebarGiftCountBadge', default: '74' }
                },
                {
                    id: 'sideBtnSpinner',
                    tab: 'spinner',
                    label: 'Lucky Wheel',
                    icon: 'spinner',
                    badge: { type: 'spin', text: 'SPIN' }
                },
                {
                    id: 'sideBtnAlbum',
                    tab: 'album',
                    label: 'Games',
                    icon: 'games'
                },
                {
                    id: 'sideBtnPresets',
                    tab: 'presets',
                    label: 'Presets',
                    icon: 'presets',
                    badge: { type: 'neutral', id: 'sidebarPresetsCountBadge', default: '17' }
                },
                {
                    id: 'sideBtnSocial',
                    tab: 'social',
                    label: 'Social Triggers',
                    icon: 'social'
                }
            ]
        },
        // Group 3: Collapsible Modules (Audio & Overlays)
        {
            group: 3,
            items: [
                {
                    id: 'sideBtnAudio',
                    type: 'collapsible',
                    label: 'Audio',
                    icon: 'audio',
                    groupId: 'sidebarAudioGroup',
                    submenuId: 'sidebarAudioSubmenu',
                    toggleFn: 'toggleAudioMenu',
                    children: [
                        { id: 'sideBtnTTS', tab: 'tts', label: 'Voice TTS', icon: 'tts', badge: { type: 'cyan', text: 'READY' } },
                        { id: 'sideBtnSongRequest', tab: 'songrequest', label: 'Song Request', icon: 'music', badge: { type: 'green', text: 'SPOTIFY' } },
                        { id: 'sideBtnSoundboard', tab: 'soundboard', label: 'Soundboard', icon: 'soundboard', badge: { type: 'neutral', text: '325+ FX' } }
                    ]
                },
                {
                    id: 'sideBtnSettings',
                    type: 'collapsible',
                    label: 'Overlays',
                    icon: 'overlays',
                    groupId: 'sidebarOverlaysGroup',
                    submenuId: 'sidebarOverlaysSubmenu',
                    toggleFn: 'toggleOverlaysMenu'
                }
            ]
        }
    ];

    window.SIDEBAR_MENU_CONFIG = SIDEBAR_MENU_CONFIG;

    // ==========================================
    // 3. SLIDING ACTIVE INDICATOR CONTROLLER
    // ==========================================
    let indicatorUpdateRaf = null;

    function ensureIndicatorEl() {
        let indicator = document.getElementById('sidebarActiveIndicator');
        const navList = document.querySelector('.sidebar-nav-list');
        if (!indicator && navList) {
            indicator = document.createElement('div');
            indicator.className = 'sidebar-active-indicator';
            indicator.id = 'sidebarActiveIndicator';
            indicator.setAttribute('aria-hidden', 'true');
            navList.prepend(indicator);
        }
        return indicator;
    }

    function updateSlidingIndicator(immediate = false) {
        if (indicatorUpdateRaf) cancelAnimationFrame(indicatorUpdateRaf);

        indicatorUpdateRaf = requestAnimationFrame(() => {
            const indicator = ensureIndicatorEl();
            if (!indicator) return;

            const navList = document.querySelector('.sidebar-nav-list');
            if (!navList) return;

            // Find currently active item
            const activeItem = navList.querySelector('.sidebar-nav-item.active:not(.sub-nav-item)') ||
                               navList.querySelector('.sidebar-nav-item.child-active');

            if (!activeItem) {
                indicator.style.opacity = '0';
                return;
            }

            const navListRect = navList.getBoundingClientRect();
            const itemRect = activeItem.getBoundingClientRect();
            const relativeTop = itemRect.top - navListRect.top;

            if (immediate) {
                indicator.style.transition = 'none';
            } else {
                indicator.style.transition = 'transform 200ms cubic-bezier(0.16, 1, 0.3, 1), height 200ms cubic-bezier(0.16, 1, 0.3, 1), opacity 150ms ease';
            }

            indicator.style.opacity = '1';
            indicator.style.transform = `translateY(${relativeTop}px)`;
            indicator.style.height = `${itemRect.height}px`;
        });
    }

    window.updateSidebarActiveIndicator = updateSlidingIndicator;

    // Hook tab switches to glide the indicator
    const originalSwitchTab = window.switchTab;
    window.switchTab = function (tabId) {
        if (typeof originalSwitchTab === 'function') {
            originalSwitchTab(tabId);
        }
        setTimeout(updateSlidingIndicator, 40);
        setTimeout(updateSlidingIndicator, 220); // after submenu expand/collapse
    };

    // ==========================================
    // 4. SIDEBAR COLLAPSE & TOOLTIPS
    // ==========================================
    window.toggleSidebarCollapse = function () {
        const sidebar = document.getElementById('appSidebar');
        const icon = document.getElementById('collapseIcon');
        if (!sidebar) return;

        const isCollapsed = sidebar.classList.toggle('collapsed');
        if (icon) {
            icon.textContent = isCollapsed ? '▶' : '◀';
        }

        try {
            localStorage.setItem('renearn_sidebar_collapsed', isCollapsed ? '1' : '0');
        } catch (_) {}

        setTimeout(updateSlidingIndicator, 240);
    };

    function restoreSidebarState() {
        try {
            const isCollapsed = localStorage.getItem('renearn_sidebar_collapsed') === '1';
            const sidebar = document.getElementById('appSidebar');
            const icon = document.getElementById('collapseIcon');
            if (sidebar && isCollapsed) {
                sidebar.classList.add('collapsed');
                if (icon) icon.textContent = '▶';
            }
        } catch (_) {}
    }

    // ==========================================
    // 5. KEYBOARD ARROW-KEY NAVIGATION
    // ==========================================
    function setupKeyboardNav() {
        const sidebar = document.getElementById('appSidebar');
        if (!sidebar) return;

        sidebar.addEventListener('keydown', (e) => {
            const items = Array.from(sidebar.querySelectorAll('.sidebar-nav-item:not([style*="display: none"]), .sidebar-ai-support-card'));
            const currentIndex = items.indexOf(document.activeElement);

            if (e.key === 'ArrowDown') {
                e.preventDefault();
                const next = items[currentIndex + 1] || items[0];
                if (next) next.focus();
            } else if (e.key === 'ArrowUp') {
                e.preventDefault();
                const prev = items[currentIndex - 1] || items[items.length - 1];
                if (prev) prev.focus();
            }
        });
    }

    // ==========================================
    // 6. INITIALIZATION & ICONS INJECTION
    // ==========================================
    function init() {
        restoreSidebarState();
        ensureIndicatorEl();
        setupKeyboardNav();

        // Update indicator on load
        setTimeout(() => updateSlidingIndicator(true), 80);

        // Window resize listener
        window.addEventListener('resize', () => updateSlidingIndicator(true));

        // Submenu state observers
        const audioGroup = document.getElementById('sidebarAudioGroup');
        const overlaysGroup = document.getElementById('sidebarOverlaysGroup');
        if (audioGroup) {
            const obs1 = new MutationObserver(() => updateSlidingIndicator());
            obs1.observe(audioGroup, { attributes: true, attributeFilter: ['class'] });
        }
        if (overlaysGroup) {
            const obs2 = new MutationObserver(() => updateSlidingIndicator());
            obs2.observe(overlaysGroup, { attributes: true, attributeFilter: ['class'] });
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

})();

