/* ====================================
   SINISTER STATE TX — Loading Script
   ==================================== */

(function () {
    'use strict';

    var statusEl = document.getElementById('status');
    var contentEl = document.getElementById('content');
    var audio    = document.getElementById('soundtrack');

    var loadingSteps = [
        { text: 'Initializing framework',     at: 0.05 },
        { text: 'Loading game resources',     at: 0.20 },
        { text: 'Building the world',          at: 0.40 },
        { text: 'Syncing state',              at: 0.60 },
        { text: 'Preparing spawn',            at: 0.80 },
        { text: 'Welcome to Texas',            at: 0.95 }
    ];

    var currentStep = 0;
    var muted = false;

    // ── Audio ──
    if (audio && audio.canPlayType('audio/mpeg')) {
        audio.volume = 0.12;
        var playPromise = audio.play();
        if (playPromise !== undefined) {
            playPromise.catch(function () {});
        }
    }

    // ── Space bar toggle mute ──
    document.addEventListener('keydown', function (e) {
        if (e.code === 'Space') {
            e.preventDefault();
            muted = !muted;
            if (audio) {
                audio.muted = muted;
                var note = document.getElementById('music-note');
                if (note) note.classList.toggle('hidden', muted);
            }
        }
    });

    // ── Loading progress handler ──
    window.addEventListener('message', function (e) {
        var data = e.data;
        if (!data) return;

        switch (data.eventName) {
            case 'loadProgress':
                var fraction = data.loadFraction || 0;

                for (var i = loadingSteps.length - 1; i >= 0; i--) {
                    if (fraction >= loadingSteps[i].at) {
                        if (i !== currentStep) {
                            currentStep = i;
                            if (statusEl) {
                                statusEl.textContent = loadingSteps[i].text;
                                statusEl.style.opacity = '0.55';
                                setTimeout(function () {
                                    if (statusEl) statusEl.style.opacity = '0.25';
                                }, 1500);
                            }
                        }
                        break;
                    }
                }
                break;

            case 'startInitFunctionOrder':
                break;

            case 'startInitFunction':
                break;

            case 'initFunctionInvoking':
                break;

            case 'initFunctionInvoked':
                break;

            case 'endInitFunctionOrder':
                break;

            case 'onLogLine':
                break;

            case 'startDataFileEntries':
                break;

            case 'performMapLoadFunction':
                break;

            case 'endDataFileEntries':
                break;
        }
    });

    // ── Done — fade out ──
    var hideTimeout;
    window.addEventListener('message', function (e) {
        if (e.data && e.data.eventName === 'onLogLine' &&
            e.data.data && e.data.data.message === 'Awaiting scripts') {
            if (statusEl) statusEl.textContent = 'Loading in...';
        }
    });

})();
