/**
 * RENEarn Game-HUD Custom Modal & Confirmation System
 * Replaces browser native confirm(), alert(), and prompt() with dark neon game-HUD modals.
 */

(function () {
    'use strict';

    // SVG Icons for Variants
    const ICONS = {
        danger: `<svg viewBox="0 0 24 24" width="28" height="28" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <polyline points="3 6 5 6 21 6"></polyline>
            <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
            <line x1="10" y1="11" x2="10" y2="17"></line>
            <line x1="14" y1="11" x2="14" y2="17"></line>
        </svg>`,
        warning: `<svg viewBox="0 0 24 24" width="28" height="28" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path>
            <line x1="12" y1="9" x2="12" y2="13"></line>
            <line x1="12" y1="17" x2="12.01" y2="17"></line>
        </svg>`,
        info: `<svg viewBox="0 0 24 24" width="28" height="28" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <circle cx="12" cy="12" r="10"></circle>
            <line x1="12" y1="16" x2="12" y2="12"></line>
            <line x1="12" y1="8" x2="12.01" y2="8"></line>
        </svg>`,
        success: `<svg viewBox="0 0 24 24" width="28" height="28" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
            <polyline points="22 4 12 14.01 9 11.01"></polyline>
        </svg>`
    };

    // Global sequential queue so multiple dialogs never overlap
    let _queue = Promise.resolve();

    function queueDialog(fn) {
        const p = _queue.then(() => fn());
        _queue = p.catch(() => {});
        return p;
    }

    /**
     * Core modal renderer
     */
    function openModalCore({
        type = 'confirm', // 'confirm', 'alert', 'prompt'
        variant = 'danger', // 'danger', 'warning', 'info', 'success'
        title = '',
        message = '',
        details = '',
        confirmText = '',
        cancelText = 'Cancel',
        icon = '',
        previewHtml = '',
        requireText = '', // If set, user must type this to enable confirm
        defaultValue = '',
        placeholder = '',
        dontAskKey = ''
    }) {
        return new Promise((resolve) => {
            // Check "Don't ask again" preference for low-risk confirmations
            if (dontAskKey && variant !== 'danger') {
                const skip = localStorage.getItem('ren_modal_skip_' + dontAskKey);
                if (skip === 'true') {
                    return resolve(type === 'prompt' ? defaultValue : true);
                }
            }

            // Save previous focus
            const activeElementBefore = document.activeElement;

            // Default button texts based on variant & type
            if (!confirmText) {
                if (type === 'alert') confirmText = 'OK';
                else if (variant === 'danger') confirmText = 'Delete';
                else confirmText = 'Confirm';
            }

            // Create Backdrop
            const backdrop = document.createElement('div');
            backdrop.className = 'ren-modal-backdrop';
            backdrop.setAttribute('role', 'alertdialog');
            backdrop.setAttribute('aria-modal', 'true');

            // Unique IDs for accessibility
            const titleId = 'renModalTitle_' + Date.now();
            const descId = 'renModalDesc_' + Date.now();
            backdrop.setAttribute('aria-labelledby', titleId);
            backdrop.setAttribute('aria-describedby', descId);

            // Icon markup
            const iconSvg = icon || ICONS[variant] || ICONS.info;

            // Format message (convert newlines to <br> or paragraphs if plain text)
            let formattedMsg = '';
            if (message) {
                formattedMsg = String(message).split('\n').map(l => l.trim()).filter(Boolean).map(l => `<div>${escapeHtml(l)}</div>`).join('');
            }

            // Details markup
            let detailsHtml = '';
            if (details) {
                detailsHtml = `<div style="background: rgba(0,0,0,0.3); border-radius: 8px; padding: 10px; font-size: 12px; color: #94a3b8; max-height: 140px; overflow-y: auto; text-align: left; margin-bottom: 14px; font-family: monospace;">${escapeHtml(details)}</div>`;
            }

            // Require text input for bulk operations
            let requireInputHtml = '';
            if (requireText) {
                requireInputHtml = `
                    <div class="ren-modal-input-wrap">
                        <div style="font-size: 11.5px; color: #cbd5e1; margin-bottom: 6px; font-weight: 700;">
                            Type <span style="color: var(--modal-accent); font-family: monospace;">${escapeHtml(requireText)}</span> to confirm:
                        </div>
                        <input type="text" class="ren-modal-input" id="renModalRequireInput" placeholder="${escapeHtml(requireText)}" autocomplete="off" spellcheck="false">
                    </div>
                `;
            }

            // Prompt text input
            let promptInputHtml = '';
            if (type === 'prompt') {
                promptInputHtml = `
                    <div class="ren-modal-input-wrap">
                        <input type="text" class="ren-modal-input" id="renModalPromptInput" value="${escapeHtml(defaultValue)}" placeholder="${escapeHtml(placeholder)}" autocomplete="off">
                    </div>
                `;
            }

            // Don't ask again checkbox (never for destructive deletes)
            let dontAskHtml = '';
            if (dontAskKey && variant !== 'danger') {
                dontAskHtml = `
                    <label class="ren-modal-dont-ask">
                        <input type="checkbox" id="renModalDontAskChk">
                        <span>Don't ask me again</span>
                    </label>
                `;
            }

            // Build Card innerHTML
            backdrop.innerHTML = `
                <div class="ren-modal-card ren-variant-${variant}" tabindex="-1">
                    <div class="ren-modal-icon-badge">${iconSvg}</div>
                    <h3 class="ren-modal-title" id="${titleId}">${escapeHtml(title)}</h3>
                    ${formattedMsg ? `<div class="ren-modal-message" id="${descId}">${formattedMsg}</div>` : ''}
                    ${previewHtml ? `<div class="ren-modal-preview-box">${previewHtml}</div>` : ''}
                    ${detailsHtml}
                    ${requireInputHtml}
                    ${promptInputHtml}
                    ${dontAskHtml}
                    <div class="ren-modal-actions">
                        ${type !== 'alert' ? `
                            <button type="button" class="ren-modal-btn ren-modal-btn-cancel" id="renModalBtnCancel">
                                ${escapeHtml(cancelText)}
                            </button>
                        ` : ''}
                        <button type="button" class="ren-modal-btn ren-modal-btn-confirm" id="renModalBtnConfirm" ${requireText ? 'disabled' : ''}>
                            ${variant === 'danger' ? '<span>🗑️</span>' : ''}
                            <span>${escapeHtml(confirmText)}</span>
                        </button>
                    </div>
                </div>
            `;

            document.body.appendChild(backdrop);
            document.body.classList.add('ren-modal-open');

            const card = backdrop.querySelector('.ren-modal-card');
            const btnCancel = backdrop.querySelector('#renModalBtnCancel');
            const btnConfirm = backdrop.querySelector('#renModalBtnConfirm');
            const promptInput = backdrop.querySelector('#renModalPromptInput');
            const requireInput = backdrop.querySelector('#renModalRequireInput');
            const dontAskChk = backdrop.querySelector('#renModalDontAskChk');

            // Handle bulk requireText typing validation
            if (requireInput && btnConfirm) {
                requireInput.addEventListener('input', () => {
                    const match = requireInput.value.trim().toUpperCase() === requireText.trim().toUpperCase();
                    btnConfirm.disabled = !match;
                });
            }

            // Animation: Trigger entry
            requestAnimationFrame(() => {
                backdrop.classList.add('ren-modal-visible');
            });

            // Focus management: Focus Cancel by default on confirms to prevent accidental Enter deletions
            setTimeout(() => {
                if (promptInput) {
                    promptInput.focus();
                    promptInput.select();
                } else if (requireInput) {
                    requireInput.focus();
                } else if (btnCancel) {
                    btnCancel.focus();
                } else if (btnConfirm) {
                    btnConfirm.focus();
                }
            }, 50);

            let isClosed = false;

            function closeModal(result) {
                if (isClosed) return;
                isClosed = true;

                // Save "Don't ask again" preference if checked
                if (dontAskChk && dontAskChk.checked && dontAskKey) {
                    localStorage.setItem('ren_modal_skip_' + dontAskKey, 'true');
                }

                backdrop.classList.remove('ren-modal-visible');
                backdrop.classList.add('ren-modal-closing');

                setTimeout(() => {
                    backdrop.remove();
                    // If no other modals open, unlock scroll
                    if (!document.querySelector('.ren-modal-backdrop')) {
                        document.body.classList.remove('ren-modal-open');
                    }
                    if (activeElementBefore && typeof activeElementBefore.focus === 'function') {
                        try { activeElementBefore.focus(); } catch (_) {}
                    }
                    resolve(result);
                }, 160);
            }

            // Click Handlers
            if (btnCancel) {
                btnCancel.addEventListener('click', () => {
                    closeModal(type === 'prompt' ? null : false);
                });
            }

            btnConfirm.addEventListener('click', () => {
                if (requireText && requireInput && requireInput.value.trim().toUpperCase() !== requireText.trim().toUpperCase()) {
                    return;
                }
                if (type === 'prompt') {
                    closeModal(promptInput ? promptInput.value : '');
                } else {
                    closeModal(true);
                }
            });

            // Backdrop Click: danger variant shakes; others close
            backdrop.addEventListener('click', (e) => {
                if (e.target === backdrop) {
                    if (variant === 'danger') {
                        // Shake card to reinforce destructive context
                        card.classList.remove('ren-shake');
                        void card.offsetWidth; // force reflow
                        card.classList.add('ren-shake');
                        setTimeout(() => card.classList.remove('ren-shake'), 400);
                    } else {
                        closeModal(type === 'prompt' ? null : false);
                    }
                }
            });

            // Keyboard Accessibility & Focus Trap
            backdrop.addEventListener('keydown', (e) => {
                if (e.key === 'Escape') {
                    e.preventDefault();
                    closeModal(type === 'prompt' ? null : false);
                    return;
                }

                if (e.key === 'Enter') {
                    // If focused on cancel button, let Enter cancel
                    if (document.activeElement === btnCancel) {
                        e.preventDefault();
                        closeModal(type === 'prompt' ? null : false);
                        return;
                    }
                    // If requireText input not valid, block
                    if (requireText && btnConfirm.disabled) {
                        e.preventDefault();
                        return;
                    }
                    e.preventDefault();
                    if (type === 'prompt') {
                        closeModal(promptInput ? promptInput.value : '');
                    } else {
                        closeModal(true);
                    }
                    return;
                }

                // Focus Trap inside modal
                if (e.key === 'Tab') {
                    const focusable = backdrop.querySelectorAll('button:not([disabled]), input:not([disabled]), [tabindex="0"]');
                    if (focusable.length === 0) return;
                    const first = focusable[0];
                    const last = focusable[focusable.length - 1];

                    if (e.shiftKey) {
                        if (document.activeElement === first) {
                            e.preventDefault();
                            last.focus();
                        }
                    } else {
                        if (document.activeElement === last) {
                            e.preventDefault();
                            first.focus();
                        }
                    }
                }
            });
        });
    }

    function escapeHtml(str) {
        if (!str) return '';
        return String(str)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    /**
     * Public Promise-based API
     */
    window.showConfirm = function (options = {}) {
        return queueDialog(() => openModalCore(Object.assign({ type: 'confirm', variant: 'warning' }, options)));
    };

    window.showAlert = function (options = {}) {
        if (typeof options === 'string') {
            options = { title: 'Notice', message: options, variant: 'info' };
        }
        return queueDialog(() => openModalCore(Object.assign({ type: 'alert', variant: 'info' }, options)));
    };

    window.showPrompt = function (options = {}) {
        if (typeof options === 'string') {
            options = { title: 'Input Required', message: options };
        }
        return queueDialog(() => openModalCore(Object.assign({ type: 'prompt', variant: 'info' }, options)));
    };

    /**
     * Tailored Command Trigger Delete Confirmation
     * Shows preview of gift icon, name, reps, and command chips.
     */
    window.showDeleteTriggerConfirm = async function (gift) {
        if (!gift) return false;

        // Resolve gift trigger icon
        let rawTrigger = gift.icon || gift.trigImg || gift.giftIcon || (gift.image && gift.image.url_list ? gift.image.url_list[0] : null);
        if (!rawTrigger && gift.giftId && typeof catalog !== 'undefined' && catalog && catalog.gifts) {
            const foundG = catalog.gifts.find(x => String(x.id) === String(gift.giftId));
            if (foundG) rawTrigger = foundG.icon;
        }
        if (!rawTrigger) rawTrigger = 'images/tiktok-gifts/5655_rose.webp';
        const giftIconSrc = String(rawTrigger).replace(/^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?\//, '');

        // Resolve gift label
        const giftName = gift.giftName || gift.name || gift.label || 'Custom Command Trigger';

        // Resolve command string & repetition
        const reps = gift.repetition !== undefined ? gift.repetition : (gift.amount || 1);
        const mainCmd = (Array.isArray(gift.commands) && gift.commands[0] && gift.commands[0].command)
            ? gift.commands[0].command
            : (gift.command || (typeof gift.commands === 'string' ? gift.commands : 'spawn_unit'));
        const cmdCount = (Array.isArray(gift.commands) && gift.commands.length) ? gift.commands.length : 1;

        const previewHtml = `
            <div class="ren-modal-preview-icon">
                <img src="${giftIconSrc}" alt="${escapeHtml(giftName)}" onerror="this.src='images/tiktok-gifts/5655_rose.webp';">
            </div>
            <div class="ren-modal-preview-info">
                <div class="ren-modal-preview-name">${escapeHtml(giftName)}</div>
                <div class="ren-modal-preview-tags">
                    <span class="ren-modal-chip ren-modal-chip-cmd">${escapeHtml(mainCmd)}</span>
                    ${cmdCount > 1 ? `<span class="ren-modal-chip ren-modal-chip-cmd">+${cmdCount - 1} more</span>` : ''}
                    <span class="ren-modal-chip ren-modal-chip-reps">${reps}x rep</span>
                </div>
            </div>
        `;

        return window.showConfirm({
            variant: 'danger',
            title: 'Delete command trigger?',
            message: "This will permanently remove this trigger and its commands. This can't be undone.",
            previewHtml: previewHtml,
            confirmText: 'Delete Trigger',
            cancelText: 'Cancel'
        });
    };

    /**
     * Soft-delete Undo Toast System
     * Displays a toast with an Undo action at bottom right for 6 seconds.
     */
    let _activeUndoToast = null;

    window.showUndoToast = function ({
        message = 'Trigger deleted',
        undoLabel = 'Undo',
        durationMs = 6000,
        onUndo = () => {},
        onCommit = () => {}
    }) {
        // If an undo toast is already active, commit it immediately
        if (_activeUndoToast) {
            _activeUndoToast.commit();
        }

        let host = document.querySelector('.ren-undo-toast-host');
        if (!host) {
            host = document.createElement('div');
            host.className = 'ren-undo-toast-host';
            document.body.appendChild(host);
        }

        const toast = document.createElement('div');
        toast.className = 'ren-undo-toast';
        toast.innerHTML = `
            <div class="ren-undo-toast-body">
                <span>🗑️</span>
                <span>${escapeHtml(message)}</span>
            </div>
            <button type="button" class="ren-undo-btn">
                <span>↩</span>
                <span>${escapeHtml(undoLabel)}</span>
            </button>
            <div class="ren-undo-progress-bar"></div>
        `;

        host.appendChild(toast);

        // Animate entrance
        requestAnimationFrame(() => {
            toast.classList.add('ren-toast-visible');
        });

        const progressBar = toast.querySelector('.ren-undo-progress-bar');
        if (progressBar) {
            progressBar.style.transition = `transform ${durationMs}ms linear`;
            requestAnimationFrame(() => {
                progressBar.style.transform = 'scaleX(0)';
            });
        }

        let isHandled = false;

        function finishToast(isUndo) {
            if (isHandled) return;
            isHandled = true;
            if (_activeUndoToast && _activeUndoToast.element === toast) {
                _activeUndoToast = null;
            }

            toast.classList.remove('ren-toast-visible');
            toast.classList.add('ren-toast-closing');

            setTimeout(() => {
                toast.remove();
            }, 220);

            if (isUndo) {
                onUndo();
            } else {
                onCommit();
            }
        }

        const timeoutId = setTimeout(() => {
            finishToast(false);
        }, durationMs);

        const undoBtn = toast.querySelector('.ren-undo-btn');
        if (undoBtn) {
            undoBtn.addEventListener('click', () => {
                clearTimeout(timeoutId);
                finishToast(true);
            });
        }

        _activeUndoToast = {
            element: toast,
            commit: () => {
                clearTimeout(timeoutId);
                finishToast(false);
            }
        };
    };

    /**
     * Test / Preview Helper
     */
    window.testModal = async function (variant = 'trigger') {
        if (variant === 'danger' || variant === 'trigger') {
            const confirmed = await window.showDeleteTriggerConfirm({
                giftName: 'Rose (Level 1)',
                icon: 'images/tiktok-gifts/5655_rose.webp',
                repetition: 5,
                commands: [{ command: 'spawn_ultimate_spruce' }]
            });
            console.log('[testModal] Result:', confirmed);
            if (confirmed) {
                window.showUndoToast({
                    message: 'Command trigger deleted',
                    onUndo: () => {
                        if (typeof showToast === 'function') showToast('↩ Trigger restored successfully!', 'success');
                    },
                    onCommit: () => {
                        console.log('[testModal] Permanent delete committed');
                    }
                });
            }
        } else if (variant === 'warning') {
            const res = await window.showConfirm({
                variant: 'warning',
                title: 'Reset all command counts?',
                message: 'This will reset all current trigger counts to 0 on your live stream overlay.',
                confirmText: 'Reset Counts',
                cancelText: 'Keep Current',
                dontAskKey: 'demo_warning'
            });
            console.log('[testModal warning]:', res);
        } else if (variant === 'info') {
            await window.showAlert({
                variant: 'info',
                title: 'Integration Details',
                message: 'PvZ Fusion 4.0 stream engine is connected via WebSocket (0ms latency).'
            });
        } else if (variant === 'success') {
            await window.showAlert({
                variant: 'success',
                title: 'Configuration Saved',
                message: 'All your triggers and preset actions have been successfully synced!'
            });
        } else if (variant === 'prompt') {
            const val = await window.showPrompt({
                title: 'Enter Custom Command',
                message: 'Type the console or script command to execute on trigger:',
                defaultValue: 'killallzombies',
                placeholder: 'e.g. spawn_black_horse'
            });
            console.log('[testModal prompt]:', val);
        } else if (variant === 'bulk') {
            const res = await window.showConfirm({
                variant: 'danger',
                title: 'Delete All Triggers?',
                message: 'This will wipe out all 64 triggers in your workspace.',
                requireText: 'DELETE',
                confirmText: 'Delete All'
            });
            console.log('[testModal bulk]:', res);
        }
    };

    /**
     * Global Native Dialog Interceptors & Polyfills
     * Seamlessly upgrades any un-migrated native alert/confirm/prompt calls
     */
    const _nativeAlert = window.alert;
    const _nativeConfirm = window.confirm;
    const _nativePrompt = window.prompt;

    window.alert = function (msg) {
        return window.showAlert(msg);
    };

    window.confirm = function (msg) {
        // Returns promise when awaited in async functions
        return window.showConfirm({ message: msg, title: 'Confirmation' });
    };

    window.prompt = function (msg, defVal) {
        return window.showPrompt({ message: msg, defaultValue: defVal });
    };

    window.nativeAlert = _nativeAlert;
    window.nativeConfirm = _nativeConfirm;
    window.nativePrompt = _nativePrompt;

})();
