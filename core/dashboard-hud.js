/**
 * RENEarn Studio - Dashboard Game-HUD Enhancements
 * Telemetry formatting, reactive stepper, keyboard shortcuts, and HUD telemetry animations.
 */

(function () {
    'use strict';

    // Format middle ellipsis e.g. 7703093170968419636 -> 770309...9636
    function formatMiddleEllipsis(str, lead = 6, tail = 4) {
        if (!str || str.length <= lead + tail + 3) return str;
        return str.substring(0, lead) + '...' + str.substring(str.length - tail);
    }

    // Number count-up animation helper
    function animateCountUp(element, targetVal, duration = 600) {
        if (!element) return;
        const startVal = parseInt(element.textContent.replace(/[^0-9]/g, ''), 10) || 0;
        const endVal = parseInt(String(targetVal).replace(/[^0-9]/g, ''), 10) || 0;
        if (startVal === endVal) {
            element.textContent = endVal.toLocaleString();
            return;
        }

        const startTime = performance.now();
        function update(currentTime) {
            const elapsed = currentTime - startTime;
            const progress = Math.min(elapsed / duration, 1);
            // Ease out cubic
            const ease = 1 - Math.pow(1 - progress, 3);
            const current = Math.round(startVal + (endVal - startVal) * ease);
            element.textContent = current.toLocaleString();

            if (progress < 1) {
                requestAnimationFrame(update);
            } else {
                element.textContent = endVal.toLocaleString();
            }
        }
        requestAnimationFrame(update);
    }

    // Initialize Dashboard HUD Watchers
    function initDashboardHUD() {
        // Room ID Middle Ellipsis & Click-to-copy (Strict loop-guard)
        const roomIdEl = document.getElementById('dashboardTikTokRoomId');
        if (roomIdEl) {
            let isFormattingRoomId = false;
            const applyRoomIdFormat = () => {
                if (isFormattingRoomId) return;
                const currentText = roomIdEl.textContent.trim();
                if (!currentText || currentText === '—' || currentText.includes('...')) return;

                isFormattingRoomId = true;
                roomIdEl.setAttribute('data-raw-room-id', currentText);
                roomIdEl.title = `Click to copy Room ID: ${currentText}`;
                roomIdEl.textContent = formatMiddleEllipsis(currentText, 6, 4);
                isFormattingRoomId = false;
            };

            const observer = new MutationObserver(applyRoomIdFormat);
            observer.observe(roomIdEl, { childList: true, characterData: true });
            applyRoomIdFormat();

            roomIdEl.style.cursor = 'pointer';
            roomIdEl.addEventListener('click', (e) => {
                e.stopPropagation();
                const raw = roomIdEl.getAttribute('data-raw-room-id') || roomIdEl.textContent.trim();
                if (raw && raw !== '—') {
                    navigator.clipboard.writeText(raw);
                    if (window.showToast) window.showToast(`Room ID copied: ${raw}`, '📋');
                }
            });
        }

        // Stepper State Synchronization
        const statusBadge = document.getElementById('dashboardTikTokStatusBadge');
        if (statusBadge) {
            const updateStepper = () => {
                const isConnected = statusBadge.classList.contains('connected') || statusBadge.textContent.includes('LIVE CONNECTED');
                const steps = document.querySelectorAll('.tiktok-step-pill');
                if (steps && steps.length >= 4) {
                    if (isConnected) {
                        steps[0].classList.add('completed');
                        steps[1].classList.add('completed');
                        steps[2].classList.add('completed');
                        steps[3].classList.add('active-step');
                    } else {
                        steps[0].classList.remove('completed');
                        steps[1].classList.remove('completed');
                        steps[2].classList.remove('completed');
                        steps[3].classList.remove('active-step');
                    }
                }
            };

            const statusObserver = new MutationObserver(updateStepper);
            statusObserver.observe(statusBadge, { attributes: true, childList: true, characterData: true });
            updateStepper();
        }

        // Keyboard Shortcut: '/' to focus Game Search
        window.addEventListener('keydown', (e) => {
            if (e.key === '/' && !['INPUT', 'TEXTAREA'].includes(document.activeElement.tagName)) {
                const searchInp = document.getElementById('gameSearchInput');
                if (searchInp) {
                    e.preventDefault();
                    searchInp.focus();
                    searchInp.select();
                }
            }
        });

        // Auto-collapse AI Support floating pill after 6 seconds of inactivity
        const aiLauncher = document.getElementById('btnAiSupportLauncher');
        if (aiLauncher) {
            let collapseTimer = null;
            const resetCollapseTimer = () => {
                aiLauncher.classList.remove('collapsed-pill');
                clearTimeout(collapseTimer);
                collapseTimer = setTimeout(() => {
                    // Only collapse if support window is not open
                    const win = document.getElementById('aiSupportWindow');
                    if (!win || win.style.display === 'none') {
                        aiLauncher.classList.add('collapsed-pill');
                    }
                }, 6000);
            };

            resetCollapseTimer();
            window.addEventListener('mousemove', resetCollapseTimer, { passive: true });
            aiLauncher.addEventListener('mouseenter', () => {
                clearTimeout(collapseTimer);
                aiLauncher.classList.remove('collapsed-pill');
            });
        }
        // Toast timeout manager (prevents premature dismiss on rapid triggers)
        let toastDismissTimer = null;
        const origShowToast = window.showToast;
        window.showToast = function (msg, icon = "OK") {
            const t = document.getElementById('toast');
            if (!t) return;
            const tMsg = document.getElementById('toastMsg');
            if (tMsg) tMsg.innerText = msg;
            const tIcon = document.getElementById('toastIcon');
            if (tIcon) tIcon.innerText = icon;
            t.classList.add('show');
            clearTimeout(toastDismissTimer);
            toastDismissTimer = setTimeout(() => t.classList.remove('show'), 3500);
        };
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initDashboardHUD);
    } else {
        initDashboardHUD();
    }
})();
