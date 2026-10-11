// ========================================================
// LUXURY CASINO ROULETTE & WHEEL ENGINE (SHARED)
// ========================================================

        function getWheelPointerHTML(theme = 'brass_chevron', customIcon = '') {
            if (theme === 'ivory_ball') {
                return `
                    <div style="display: flex; flex-direction: column; align-items: center; filter: drop-shadow(0 4px 10px rgba(0,0,0,0.95));">
                        <div style="width: 24px; height: 24px; border-radius: 50%; background: radial-gradient(circle at 35% 35%, #ffffff 0%, #f1f5f9 45%, #cbd5e1 80%, #94a3b8 100%); box-shadow: 0 3px 8px rgba(0,0,0,0.8), inset 0 1px 2px rgba(255,255,255,0.9); border: 1.5px solid rgba(255,255,255,0.7);"></div>
                        <div style="width: 0; height: 0; border-left: 6px solid transparent; border-right: 6px solid transparent; border-top: 10px solid #cbd5e1; margin-top: -2px;"></div>
                    </div>
                `;
            }
            if (theme === 'neon_laser') {
                return `
                    <div style="display: flex; flex-direction: column; align-items: center; filter: drop-shadow(0 0 14px #00f0ff);">
                        <svg viewBox="0 0 32 42" width="34" height="44" fill="none">
                            <polygon points="16,40 2,12 8,2 24,2 30,12" fill="#090d16" stroke="#00f0ff" stroke-width="2.5"/>
                            <polygon points="16,35 6,13 11,5 21,5 26,13" fill="#00f0ff" opacity="0.8"/>
                            <circle cx="16" cy="15" r="5.5" fill="#ffffff"/>
                        </svg>
                    </div>
                `;
            }
            if (theme === 'custom_badge' && customIcon) {
                return `
                    <div style="display: flex; flex-direction: column; align-items: center; filter: drop-shadow(0 4px 12px rgba(0,0,0,0.95));">
                        <div style="width: 38px; height: 38px; border-radius: 50%; border: 2.5px solid #f59e0b; background: #0f172a; overflow: hidden; box-shadow: 0 0 14px rgba(245, 158, 11, 0.65); display: flex; align-items: center; justify-content: center;">
                            <img src="${customIcon}" onerror="this.src='images/func_2.png'" style="width: 100%; height: 100%; object-fit: cover;">
                        </div>
                        <div style="width: 0; height: 0; border-left: 8px solid transparent; border-right: 8px solid transparent; border-top: 12px solid #f59e0b; margin-top: -3px;"></div>
                    </div>
                `;
            }
            // Default: 'brass_chevron' (High-roller Casino Brass Chevron with Ruby Facet - Matches Reference Photo 1)
            return `
                <div style="width: 36px; height: 46px; position: relative; filter: drop-shadow(0 4px 14px rgba(0,0,0,0.95));">
                    <svg viewBox="0 0 34 44" width="36" height="46" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <defs>
                            <linearGradient id="overlayBrassPtr" x1="0" y1="0" x2="34" y2="44" gradientUnits="userSpaceOnUse">
                                <stop offset="0%" stop-color="#fef08a"/>
                                <stop offset="25%" stop-color="#eab308"/>
                                <stop offset="50%" stop-color="#b45309"/>
                                <stop offset="75%" stop-color="#fde047"/>
                                <stop offset="100%" stop-color="#78350f"/>
                            </linearGradient>
                            <radialGradient id="overlayRubyPtrJewel" cx="45%" cy="40%" r="55%">
                                <stop offset="0%" stop-color="#ff7185"/>
                                <stop offset="45%" stop-color="#e11d48"/>
                                <stop offset="85%" stop-color="#881337"/>
                                <stop offset="100%" stop-color="#4c0519"/>
                            </radialGradient>
                        </defs>
                        <path d="M17 43 L3 13 C1 9 4 3 9 3 L25 3 C30 3 33 9 31 13 Z" fill="url(#overlayBrassPtr)" stroke="#1a0f02" stroke-width="1.8" />
                        <path d="M17 38 L6 14 C4.5 11 6.5 6 10 6 L24 6 C27.5 6 29.5 11 28 14 Z" fill="#2d1507" opacity="0.65"/>
                        <circle cx="17" cy="15" r="7.5" fill="url(#overlayRubyPtrJewel)" stroke="#fde047" stroke-width="1.2"/>
                        <circle cx="15.2" cy="13.2" r="2.2" fill="#ffffff" opacity="0.85"/>
                    </svg>
                </div>
            `;
        }

        function drawRealisticWheel(canvas, spinner) {
            if (!canvas) return;
            const ctx = canvas.getContext('2d');
            const w = canvas.width;
            const h = canvas.height;
            const cx = w / 2;
            const cy = h / 2;
            const R = Math.min(w, h) / 2 - 4;

            ctx.clearRect(0, 0, w, h);

            const sp = spinner || {};
            const slices = (sp.slices && sp.slices.length > 0) ? sp.slices : [
                { id: '1', label: '+500', rarity: 'Mythic', delta: 500 },
                { id: '2', label: '-100', rarity: 'Mythic', delta: -100 },
                { id: '3', label: '+100', rarity: 'Legendary', delta: 100 },
                { id: '4', label: '-50', rarity: 'Legendary', delta: -50 },
                { id: '5', label: '+50', rarity: 'Epic', delta: 50 },
                { id: '6', label: '-25', rarity: 'Rare', delta: -25 },
                { id: '7', label: '+20', rarity: 'Normal', delta: 20 },
                { id: '8', label: '-10', rarity: 'Normal', delta: -10 }
            ];

            const num = slices.length || 8;
            const arc = (2 * Math.PI) / num;

            const theme = sp.wheelTheme || 'casino_royale';
            const centerFinial = sp.centerFinial || 'turret_3d';
            const colorMode = sp.wheelRarityStyle || 'rarity_enamel';

            const rOuter = R;
            const rWoodIn = R * 0.84;
            const rBrassIn = R * 0.81;
            const rTrackIn = R * 0.72;
            const rPocketOut = R * 0.72;
            const rPocketIn = R * 0.44;
            const rConeIn = R * 0.22;
            const rTurretBase = R * 0.22;
            const rTurretMid = R * 0.15;
            const rTurretTop = R * 0.085;

            // 1. Outer Mahogany / Themed Rim
            ctx.save();
            let rimGrad;
            if (theme === 'pvz_gold') {
                rimGrad = ctx.createRadialGradient(cx, cy, rWoodIn, cx, cy, rOuter);
                rimGrad.addColorStop(0.0, '#78350f');
                rimGrad.addColorStop(0.3, '#d97706');
                rimGrad.addColorStop(0.7, '#fef08a');
                rimGrad.addColorStop(1.0, '#451a03');
            } else if (theme === 'cyberpunk_neon') {
                rimGrad = ctx.createRadialGradient(cx, cy, rWoodIn, cx, cy, rOuter);
                rimGrad.addColorStop(0.0, '#0b0f19');
                rimGrad.addColorStop(0.4, '#161e2e');
                rimGrad.addColorStop(0.8, '#0d131f');
                rimGrad.addColorStop(1.0, '#04060a');
            } else if (theme === 'obsidian_vip') {
                rimGrad = ctx.createRadialGradient(cx, cy, rWoodIn, cx, cy, rOuter);
                rimGrad.addColorStop(0.0, '#1c1917');
                rimGrad.addColorStop(0.4, '#292524');
                rimGrad.addColorStop(0.8, '#18181b');
                rimGrad.addColorStop(1.0, '#09090b');
            } else if (theme === 'emerald_montecarlo') {
                rimGrad = ctx.createRadialGradient(cx, cy, rWoodIn, cx, cy, rOuter);
                rimGrad.addColorStop(0.0, '#064e3b');
                rimGrad.addColorStop(0.35, '#047857');
                rimGrad.addColorStop(0.75, '#022c22');
                rimGrad.addColorStop(1.0, '#011c15');
            } else {
                rimGrad = ctx.createRadialGradient(cx, cy, rWoodIn, cx, cy, rOuter);
                rimGrad.addColorStop(0.00, '#2b0e04');
                rimGrad.addColorStop(0.25, '#4a1b0b');
                rimGrad.addColorStop(0.60, '#381206');
                rimGrad.addColorStop(0.85, '#220802');
                rimGrad.addColorStop(1.00, '#0f0301');
            }

            ctx.beginPath();
            ctx.arc(cx, cy, rOuter, 0, 2 * Math.PI);
            ctx.fillStyle = rimGrad;
            ctx.fill();

            const glossGrad = ctx.createLinearGradient(cx - rOuter, cy - rOuter, cx + rOuter, cy + rOuter);
            glossGrad.addColorStop(0.0, 'rgba(255, 255, 255, 0.18)');
            glossGrad.addColorStop(0.45, 'rgba(255, 255, 255, 0.02)');
            glossGrad.addColorStop(0.55, 'rgba(0, 0, 0, 0.22)');
            glossGrad.addColorStop(1.0, 'rgba(255, 255, 255, 0.12)');
            ctx.fillStyle = glossGrad;
            ctx.fill();

            ctx.beginPath();
            ctx.arc(cx, cy, rOuter, 0, 2 * Math.PI);
            ctx.strokeStyle = '#050100';
            ctx.lineWidth = 3;
            ctx.stroke();

            // 2. Brass Rivets
            const rivetCount = Math.max(16, Math.min(32, num * 2));
            const rRivets = (rOuter + rWoodIn) / 2;
            for (let k = 0; k < rivetCount; k++) {
                const ra = (k / rivetCount) * 2 * Math.PI;
                const rx = cx + rRivets * Math.cos(ra);
                const ry = cy + rRivets * Math.sin(ra);

                const rSize = Math.max(2.5, R * 0.012);
                const rGrad = ctx.createRadialGradient(rx - 1, ry - 1, 0, rx, ry, rSize);
                if (theme === 'cyberpunk_neon') {
                    rGrad.addColorStop(0, '#ffffff');
                    rGrad.addColorStop(0.4, '#00f0ff');
                    rGrad.addColorStop(1, '#005577');
                } else if (theme === 'pvz_gold') {
                    rGrad.addColorStop(0, '#a7f3d0');
                    rGrad.addColorStop(0.5, '#10b981');
                    rGrad.addColorStop(1, '#064e3b');
                } else {
                    rGrad.addColorStop(0, '#fef08a');
                    rGrad.addColorStop(0.4, '#eab308');
                    rGrad.addColorStop(0.85, '#b45309');
                    rGrad.addColorStop(1, '#451a03');
                }

                ctx.beginPath();
                ctx.arc(rx, ry, rSize, 0, 2 * Math.PI);
                ctx.fillStyle = rGrad;
                ctx.shadowColor = 'rgba(0,0,0,0.85)';
                ctx.shadowBlur = 3;
                ctx.fill();
                ctx.shadowBlur = 0;

                ctx.beginPath();
                ctx.arc(rx - 0.7, ry - 0.7, rSize * 0.35, 0, 2 * Math.PI);
                ctx.fillStyle = 'rgba(255,255,255,0.85)';
                ctx.fill();
            }
            ctx.restore();

            // 3. Brass Inlay Bezel
            ctx.save();
            const brassGrad = ctx.createRadialGradient(cx, cy, rBrassIn, cx, cy, rWoodIn);
            if (theme === 'cyberpunk_neon') {
                brassGrad.addColorStop(0.0, '#003344');
                brassGrad.addColorStop(0.5, '#00f0ff');
                brassGrad.addColorStop(1.0, '#001a24');
            } else {
                brassGrad.addColorStop(0.0, '#78350f');
                brassGrad.addColorStop(0.2, '#fde047');
                brassGrad.addColorStop(0.5, '#eab308');
                brassGrad.addColorStop(0.8, '#fef08a');
                brassGrad.addColorStop(1.0, '#451a03');
            }

            ctx.beginPath();
            ctx.arc(cx, cy, rWoodIn, 0, 2 * Math.PI);
            ctx.arc(cx, cy, rBrassIn, 0, 2 * Math.PI, true);
            ctx.fillStyle = brassGrad;
            ctx.fill();

            ctx.beginPath();
            ctx.arc(cx, cy, rWoodIn, 0, 2 * Math.PI);
            ctx.strokeStyle = '#270e02';
            ctx.lineWidth = 1.5;
            ctx.stroke();
            ctx.restore();

            // 4. Sunken Ball Track
            ctx.save();
            const trackGrad = ctx.createRadialGradient(cx, cy, rTrackIn, cx, cy, rBrassIn);
            trackGrad.addColorStop(0.00, '#100401');
            trackGrad.addColorStop(0.40, '#240b03');
            trackGrad.addColorStop(0.75, '#180702');
            trackGrad.addColorStop(1.00, '#060100');

            ctx.beginPath();
            ctx.arc(cx, cy, rBrassIn, 0, 2 * Math.PI);
            ctx.arc(cx, cy, rTrackIn, 0, 2 * Math.PI, true);
            ctx.fillStyle = trackGrad;
            ctx.fill();

            ctx.beginPath();
            ctx.arc(cx, cy, rTrackIn + 3, 0, 2 * Math.PI);
            ctx.strokeStyle = 'rgba(0,0,0,0.9)';
            ctx.lineWidth = 3;
            ctx.stroke();

            ctx.beginPath();
            ctx.arc(cx, cy, rPocketOut, 0, 2 * Math.PI);
            ctx.strokeStyle = (theme === 'cyberpunk_neon') ? '#00f0ff' : '#d97706';
            ctx.lineWidth = 1.8;
            ctx.stroke();
            ctx.restore();

            // 5. Enamel Pockets & Metallic Frets
            ctx.save();
            for (let i = 0; i < num; i++) {
                const sAngle = i * arc;
                const eAngle = (i + 1) * arc;
                const mAngle = sAngle + arc / 2;
                const slice = slices[i] || { label: 'Prize ' + (i+1) };

                let col1 = '#881337', col2 = '#4c0519';
                const rText = (slice.rarity || 'Normal').toLowerCase();
                const isNumber = slice.delta !== undefined || /^([+-]?\d+)$/.test(slice.label || '');
                const delta = Number(slice.delta !== undefined ? slice.delta : parseInt(slice.label) || 0);

                if (colorMode === 'classic_roulette') {
                    if (delta === 0 || slice.label === '0' || slice.isZero) {
                        col1 = '#047857'; col2 = '#064e3b';
                    } else if (i % 2 === 0) {
                        col1 = '#9f1239'; col2 = '#4c0519';
                    } else {
                        col1 = '#18181b'; col2 = '#09090b';
                    }
                } else if (colorMode === 'slice_custom' && slice.color) {
                    col1 = slice.color;
                    col2 = '#09090b';
                } else {
                    switch (rText) {
                        case 'mythic': col1 = '#b91c1c'; col2 = '#450a0a'; break;
                        case 'legendary': col1 = '#d97706'; col2 = '#78350f'; break;
                        case 'epic': col1 = '#7e22ce'; col2 = '#3b0764'; break;
                        case 'rare': col1 = '#2563eb'; col2 = '#172554'; break;
                        default:
                            col1 = (isNumber && delta > 0) ? '#059669' : '#1f2937';
                            col2 = (isNumber && delta > 0) ? '#064e3b' : '#09090b';
                            break;
                    }
                }

                ctx.beginPath();
                ctx.arc(cx, cy, rPocketOut, sAngle, eAngle);
                ctx.arc(cx, cy, rPocketIn, eAngle, sAngle, true);
                ctx.closePath();

                const pocketGrad = ctx.createRadialGradient(cx, cy, rPocketIn, cx, cy, rPocketOut);
                pocketGrad.addColorStop(0.0, col1);
                pocketGrad.addColorStop(0.7, col2);
                pocketGrad.addColorStop(1.0, '#000000');
                ctx.fillStyle = pocketGrad;
                ctx.fill();

                ctx.save();
                ctx.clip();
                const sheenGrad = ctx.createLinearGradient(
                    cx + rPocketIn * Math.cos(mAngle), cy + rPocketIn * Math.sin(mAngle),
                    cx + rPocketOut * Math.cos(mAngle), cy + rPocketOut * Math.sin(mAngle)
                );
                sheenGrad.addColorStop(0, 'rgba(255,255,255,0.22)');
                sheenGrad.addColorStop(0.4, 'rgba(255,255,255,0.0)');
                sheenGrad.addColorStop(1, 'rgba(0,0,0,0.4)');
                ctx.fillStyle = sheenGrad;
                ctx.fill();
                ctx.restore();
            }

            // Metallic Frets
            for (let i = 0; i < num; i++) {
                const sAngle = i * arc;
                const cosA = Math.cos(sAngle);
                const sinA = Math.sin(sAngle);

                const x1 = cx + (rPocketIn - 4) * cosA;
                const y1 = cy + (rPocketIn - 4) * sinA;
                const x2 = cx + (rPocketOut + 1) * cosA;
                const y2 = cy + (rPocketOut + 1) * sinA;

                ctx.beginPath();
                ctx.moveTo(x1 - 1.2 * sinA, y1 + 1.2 * cosA);
                ctx.lineTo(x2 - 1.2 * sinA, y2 + 1.2 * cosA);
                ctx.strokeStyle = 'rgba(0,0,0,0.85)';
                ctx.lineWidth = 2.5;
                ctx.stroke();

                ctx.beginPath();
                ctx.moveTo(x1, y1);
                ctx.lineTo(x2, y2);
                ctx.strokeStyle = (theme === 'cyberpunk_neon') ? '#00f0ff' : '#eab308';
                ctx.lineWidth = 1.8;
                ctx.stroke();

                ctx.beginPath();
                ctx.moveTo(x1 + 0.6 * sinA, y1 - 0.6 * cosA);
                ctx.lineTo(x2 + 0.6 * sinA, y2 - 0.6 * cosA);
                ctx.strokeStyle = 'rgba(255,255,255,0.85)';
                ctx.lineWidth = 0.8;
                ctx.stroke();
            }

            // Labels / Numbers (Radial Alignment)
            const fontPx = Math.max(11, Math.min(20, Math.floor((rPocketOut - rPocketIn) * 0.40 * (14 / Math.max(10, num)) + 4)));
            for (let i = 0; i < num; i++) {
                const mAngle = (i + 0.5) * arc;
                const slice = slices[i] || {};
                let label = slice.label || '';
                if (slice.delta !== undefined && slice.delta !== null) {
                    const d = Number(slice.delta);
                    label = d > 0 ? `+${d}` : `${d}`;
                }

                ctx.save();
                ctx.translate(cx, cy);
                ctx.rotate(mAngle);

                ctx.textAlign = 'right';
                ctx.textBaseline = 'middle';
                ctx.font = `900 ${fontPx}px 'Outfit', 'Plus Jakarta Sans', sans-serif`;

                ctx.shadowColor = 'rgba(0,0,0,0.95)';
                ctx.shadowBlur = 4;
                ctx.shadowOffsetX = 1;
                ctx.shadowOffsetY = 1;
                ctx.fillStyle = '#fef08a';
                ctx.fillText(label, rPocketOut - 14, 0);

                ctx.shadowBlur = 0;
                ctx.shadowOffsetX = 0;
                ctx.shadowOffsetY = 0;
                ctx.fillStyle = '#ffffff';
                ctx.fillText(label, rPocketOut - 14, -0.6);

                ctx.restore();
            }
            ctx.restore();

            // 6. Inner Cone
            ctx.save();
            const coneGrad = ctx.createRadialGradient(cx, cy, rConeIn, cx, cy, rPocketIn);
            coneGrad.addColorStop(0.00, '#541e0a');
            coneGrad.addColorStop(0.35, '#3d1406');
            coneGrad.addColorStop(0.75, '#240a03');
            coneGrad.addColorStop(1.00, '#120401');

            ctx.beginPath();
            ctx.arc(cx, cy, rPocketIn, 0, 2 * Math.PI);
            ctx.arc(cx, cy, rConeIn, 0, 2 * Math.PI, true);
            ctx.fillStyle = coneGrad;
            ctx.fill();

            ctx.beginPath();
            ctx.arc(cx, cy, rPocketIn, 0, 2 * Math.PI);
            ctx.strokeStyle = '#f59e0b';
            ctx.lineWidth = 2;
            ctx.stroke();

            ctx.beginPath();
            ctx.arc(cx, cy, rConeIn, 0, 2 * Math.PI);
            ctx.strokeStyle = '#b45309';
            ctx.lineWidth = 1.5;
            ctx.stroke();

            for (let i = 0; i < num; i++) {
                const sAngle = i * arc;
                const cosA = Math.cos(sAngle);
                const sinA = Math.sin(sAngle);

                ctx.beginPath();
                ctx.moveTo(cx + rConeIn * cosA, cy + rConeIn * sinA);
                ctx.lineTo(cx + rPocketIn * cosA, cy + rPocketIn * sinA);
                ctx.strokeStyle = 'rgba(234, 179, 8, 0.45)';
                ctx.lineWidth = 1.2;
                ctx.stroke();
            }
            ctx.restore();

            // 7. Center Finial
            ctx.save();
            if (centerFinial === 'golden_crown') {
                const cGrad = ctx.createRadialGradient(cx, cy, 0, cx, cy, rTurretBase);
                cGrad.addColorStop(0, '#fef08a');
                cGrad.addColorStop(0.5, '#eab308');
                cGrad.addColorStop(1, '#78350f');
                ctx.beginPath();
                ctx.arc(cx, cy, rTurretBase, 0, 2 * Math.PI);
                ctx.fillStyle = cGrad;
                ctx.shadowColor = 'rgba(0,0,0,0.8)';
                ctx.shadowBlur = 10;
                ctx.fill();

                for (let k = 0; k < 8; k++) {
                    const ca = (k / 8) * 2 * Math.PI;
                    ctx.beginPath();
                    ctx.arc(cx + rTurretMid * Math.cos(ca), cy + rTurretMid * Math.sin(ca), 3, 0, 2 * Math.PI);
                    ctx.fillStyle = '#ef4444';
                    ctx.fill();
                }
            } else if (centerFinial === 'ruby_gem') {
                const rGrad = ctx.createRadialGradient(cx, cy, 0, cx, cy, rTurretBase);
                rGrad.addColorStop(0, '#ff7185');
                rGrad.addColorStop(0.5, '#e11d48');
                rGrad.addColorStop(1, '#881337');
                ctx.beginPath();
                ctx.arc(cx, cy, rTurretBase, 0, 2 * Math.PI);
                ctx.fillStyle = rGrad;
                ctx.shadowColor = 'rgba(0,0,0,0.85)';
                ctx.shadowBlur = 12;
                ctx.fill();
                ctx.beginPath();
                ctx.arc(cx, cy, rTurretBase, 0, 2 * Math.PI);
                ctx.strokeStyle = '#fde047';
                ctx.lineWidth = 2;
                ctx.stroke();
            } else {
                // 3D Lathe-Turned Turret (Picture 1)
                const tBaseGrad = ctx.createRadialGradient(cx, cy, rTurretMid, cx, cy, rTurretBase);
                tBaseGrad.addColorStop(0.0, '#78350f');
                tBaseGrad.addColorStop(0.25, '#fef08a');
                tBaseGrad.addColorStop(0.55, '#d97706');
                tBaseGrad.addColorStop(0.85, '#fde047');
                tBaseGrad.addColorStop(1.0, '#451a03');

                ctx.beginPath();
                ctx.arc(cx, cy, rTurretBase, 0, 2 * Math.PI);
                ctx.fillStyle = tBaseGrad;
                ctx.shadowColor = 'rgba(0,0,0,0.75)';
                ctx.shadowBlur = 8;
                ctx.fill();
                ctx.shadowBlur = 0;

                ctx.beginPath();
                ctx.arc(cx, cy, rTurretBase, 0, 2 * Math.PI);
                ctx.strokeStyle = '#270e02';
                ctx.lineWidth = 1.5;
                ctx.stroke();

                const tMidGrad = ctx.createRadialGradient(cx - rTurretMid * 0.25, cy - rTurretMid * 0.25, 0, cx, cy, rTurretMid);
                tMidGrad.addColorStop(0.00, '#ffffff');
                tMidGrad.addColorStop(0.35, '#cbd5e1');
                tMidGrad.addColorStop(0.65, '#64748b');
                tMidGrad.addColorStop(0.90, '#334155');
                tMidGrad.addColorStop(1.00, '#0f172a');

                ctx.beginPath();
                ctx.arc(cx, cy, rTurretMid, 0, 2 * Math.PI);
                ctx.fillStyle = tMidGrad;
                ctx.fill();

                ctx.beginPath();
                ctx.arc(cx, cy, rTurretMid, 0, 2 * Math.PI);
                ctx.strokeStyle = '#fde047';
                ctx.lineWidth = 1.5;
                ctx.stroke();

                const lx = cx - rTurretTop * 0.35;
                const ly = cy - rTurretTop * 0.35;
                const orbGrad = ctx.createRadialGradient(lx, ly, rTurretTop * 0.05, cx, cy, rTurretTop);
                orbGrad.addColorStop(0.00, '#ffffff');
                orbGrad.addColorStop(0.20, '#f8fafc');
                orbGrad.addColorStop(0.50, '#94a3b8');
                orbGrad.addColorStop(0.80, '#475569');
                orbGrad.addColorStop(1.00, '#0f172a');

                ctx.beginPath();
                ctx.arc(cx, cy, rTurretTop, 0, 2 * Math.PI);
                ctx.fillStyle = orbGrad;
                ctx.shadowColor = 'rgba(0,0,0,0.85)';
                ctx.shadowBlur = 10;
                ctx.fill();
                ctx.shadowBlur = 0;

                const spotGrad = ctx.createRadialGradient(lx, ly, 0, lx, ly, rTurretTop * 0.45);
                spotGrad.addColorStop(0.0, 'rgba(255, 255, 255, 0.95)');
                spotGrad.addColorStop(0.4, 'rgba(255, 255, 255, 0.55)');
                spotGrad.addColorStop(1.0, 'rgba(255, 255, 255, 0)');

                ctx.beginPath();
                ctx.arc(lx, ly, rTurretTop * 0.45, 0, 2 * Math.PI);
                ctx.fillStyle = spotGrad;
                ctx.fill();
            }
            ctx.restore();
        }