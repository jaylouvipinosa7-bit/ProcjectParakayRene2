/**
 * TikTok Live Studio & OBS CEF Performance & Keep-Alive Engine
 * Ensures overlays stay 100% active, never throttled, zero lag spikes, ultra smooth 60fps.
 */
(function initStreamKeepAlive() {
    // 1. Spoof document visibility so CEF never flags page as inactive or occluded
    try {
        Object.defineProperty(document, 'hidden', { get: () => false, configurable: true });
        Object.defineProperty(document, 'visibilityState', { get: () => 'visible', configurable: true });
    } catch (e) {}

    // 2. AudioContext Keep-Alive Heartbeat (Exempts Chromium renderer process from background freezing)
    let audioCtx = null;
    function startAudioKeepAlive() {
        try {
            if (audioCtx) return;
            const AudioContext = window.AudioContext || window.webkitAudioContext;
            if (!AudioContext) return;
            audioCtx = new AudioContext();
            const osc = audioCtx.createOscillator();
            const gain = audioCtx.createGain();
            gain.gain.value = 0.00001; // Silent, non-intrusive
            osc.connect(gain);
            gain.connect(audioCtx.destination);
            osc.start();

            // Auto-resume if suspended
            if (audioCtx.state === 'suspended') {
                const resume = () => {
                    if (audioCtx && audioCtx.state === 'suspended') audioCtx.resume();
                    ['click', 'touchstart', 'keydown'].forEach(evt => window.removeEventListener(evt, resume));
                };
                ['click', 'touchstart', 'keydown'].forEach(evt => window.addEventListener(evt, resume, { once: true }));
            }
        } catch (e) {}
    }

    if (document.readyState === 'complete' || document.readyState === 'interactive') {
        startAudioKeepAlive();
    } else {
        window.addEventListener('DOMContentLoaded', startAudioKeepAlive);
    }

    // 3. Unthrottled Web Worker Ticker Factory
    window.createWorkerTicker = function(callback, intervalMs = 150) {
        try {
            const blob = new Blob([`
                let timer = null;
                self.onmessage = function(e) {
                    if (e.data === 'start') {
                        if (timer) clearInterval(timer);
                        timer = setInterval(() => self.postMessage('tick'), ${intervalMs});
                    } else if (e.data === 'stop') {
                        if (timer) clearInterval(timer);
                        timer = null;
                    }
                };
            `], { type: 'application/javascript' });
            const worker = new Worker(URL.createObjectURL(blob));
            worker.onmessage = () => {
                if (typeof callback === 'function') callback();
            };
            worker.postMessage('start');
            return worker;
        } catch (e) {
            // Fallback to setInterval if Web Worker is blocked
            const id = setInterval(callback, intervalMs);
            return { postMessage: (msg) => { if (msg === 'stop') clearInterval(id); } };
        }
    };
})();
