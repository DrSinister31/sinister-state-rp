/* ====================================
   SINISTER STATE TX — Loading Script
   Particles + loading progress
   ==================================== */

(function () {
    'use strict';

    var statusEl = document.getElementById('status');
    var bgVideo  = document.getElementById('bg-video');
    var canvas   = document.getElementById('particles');
    var ctx      = canvas.getContext('2d');
    var audio    = document.getElementById('soundtrack');

    var particles = [];
    var PARTICLE_COUNT = 40;

    // ── YouTube embed (set VIDEO_URL in your server.cfg or here) ──
    var VIDEO_URL = '';
    // EXAMPLE: var VIDEO_URL = 'https://www.youtube.com/embed/XXXXXXXX?autoplay=1&mute=1&controls=0&loop=1&playlist=XXXXXXXX';
    
    if (VIDEO_URL) {
        bgVideo.src = VIDEO_URL;
        bgVideo.classList.add('active');
    } else {
        bgVideo.style.display = 'none';
    }

    // ── Loading steps ──
    var loadingSteps = [
        { text: 'Saddling up',               at: 0.05 },
        { text: 'Opening the gates',          at: 0.20 },
        { text: 'Loading the world',          at: 0.45 },
        { text: 'Getting your horse ready',   at: 0.70 },
        { text: 'Welcome to Texas',            at: 0.95 }
    ];
    var currentStep = 0;

    // ── Particles ──
    function resize() {
        canvas.width  = window.innerWidth;
        canvas.height = window.innerHeight;
    }
    window.addEventListener('resize', resize);
    resize();

    function createParticle() {
        return {
            x: Math.random() * canvas.width,
            y: Math.random() * canvas.height,
            size: Math.random() * 2 + 0.5,
            speed: Math.random() * 0.4 + 0.1,
            opacity: Math.random() * 0.5 + 0.1,
            drift: Math.random() * 0.5 - 0.25
        };
    }

    for (var i = 0; i < PARTICLE_COUNT; i++) {
        particles.push(createParticle());
    }

    function drawParticles() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        for (var i = 0; i < particles.length; i++) {
            var p = particles[i];
            p.y -= p.speed;
            p.x += p.drift;
            if (p.y < -10) { p.y = canvas.height + 10; p.x = Math.random() * canvas.width; }
            if (p.x < -10) { p.x = canvas.width + 10; }
            if (p.x > canvas.width + 10) { p.x = -10; }
            ctx.beginPath();
            ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
            ctx.fillStyle = 'rgba(191,87,0,' + p.opacity + ')';
            ctx.fill();
        }
        requestAnimationFrame(drawParticles);
    }
    drawParticles();

    // ── Audio ──
    if (audio && audio.canPlayType('audio/mpeg')) {
        audio.volume = 0.10;
        try { audio.play(); } catch(e) {}
    }
    document.addEventListener('keydown', function(e) {
        if (e.code === 'Space') {
            e.preventDefault();
            if (audio) audio.muted = !audio.muted;
        }
    });

    // ── Loading progress ──
    window.addEventListener('message', function(e) {
        var data = e.data;
        if (!data || data.eventName !== 'loadProgress') return;
        
        var fraction = data.loadFraction || 0;
        for (var i = loadingSteps.length - 1; i >= 0; i--) {
            if (fraction >= loadingSteps[i].at && i !== currentStep) {
                currentStep = i;
                if (statusEl) {
                    statusEl.textContent = loadingSteps[i].text;
                    statusEl.style.opacity = '0.6';
                    setTimeout(function() {
                        if (statusEl) statusEl.style.opacity = '0.3';
                    }, 2000);
                }
                break;
            }
        }
    });

})();
