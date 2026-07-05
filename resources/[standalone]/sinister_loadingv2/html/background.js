(function () {
    var canvas = document.getElementById('particleCanvas');
    if (!canvas) { return; }
    var ctx = canvas.getContext('2d');

    var width = window.innerWidth;
    var height = window.innerHeight;
    var centerX = width / 2;
    var centerY = height / 2;
    var mouseX = centerX;
    var mouseY = centerY;
    var mouseRadius = 130;
    var mouseActive = false;
    var mouseDown = false;
    var frameCount = 0;
    var isMobile = /Mobi|Android|iPhone|iPad|iPod/i.test(navigator.userAgent);

    canvas.width = width;
    canvas.height = height;

    var PARTICLE_COUNT = isMobile ? 55 : 90;
    var CONNECT_DISTANCE = 150;
    var CLOSE_CONNECT_DISTANCE = 50;
    var BASE_SPEED = 0.4;
    var MAX_SPEED = BASE_SPEED * 2.5;
    var MIN_SPEED = BASE_SPEED * 0.15;
    var GRAVITY_WELL_COUNT = 3;
    var NEBULA_LAYERS = 3;

    var particles = [];
    var trails = [];
    var clickBurst = [];
    var gravityWells = [];
    var nebulaOffsets = [];
    var pulseWaves = [];

    var COLORS = {
        primary: { r: 191, g: 87, b: 0, a: 0.6 },
        secondary: { r: 255, g: 248, b: 220, a: 0.4 },
        tertiary: { r: 255, g: 170, b: 85, a: 0.35 },
        quaternary: { r: 255, g: 136, b: 34, a: 0.5 },
        lines: { r: 191, g: 120, b: 40, a: 0.15 },
        linesBright: { r: 191, g: 120, b: 40, a: 0.25 },
        burst: { r: 255, g: 136, b: 34, a: 0.7 },
        burstSecondary: { r: 255, g: 200, b: 100, a: 0.5 },
        glow: { r: 191, g: 87, b: 0, a: 0.35 },
        nebula1: { r: 191, g: 87, b: 0, a: 0.04 },
        nebula2: { r: 255, g: 170, b: 85, a: 0.03 },
        nebula3: { r: 191, g: 120, b: 40, a: 0.025 }
    };

    function rgbaString(color, alphaOverride) {
        var a = typeof alphaOverride === 'number' ? alphaOverride : color.a;
        a = Math.min(1, Math.max(0, a));
        return 'rgba(' + color.r + ',' + color.g + ',' + color.b + ',' + a + ')';
    }

    function random(min, max) {
        return Math.random() * (max - min) + min;
    }

    function randomInt(min, max) {
        return Math.floor(random(min, max + 1));
    }

    function dist(x1, y1, x2, y2) {
        var dx = x1 - x2;
        var dy = y1 - y2;
        return Math.sqrt(dx * dx + dy * dy);
    }

    function lerp(a, b, t) {
        return a + (b - a) * t;
    }

    function clamp(val, min, max) {
        return Math.max(min, Math.min(max, val));
    }

    function createGravityWell() {
        return {
            x: random(width * 0.1, width * 0.9),
            y: random(height * 0.1, height * 0.9),
            strength: random(0.0003, 0.001),
            radius: random(100, 250),
            phase: random(0, Math.PI * 2),
            moveSpeed: random(0.0005, 0.002),
            moveRadius: random(50, 150),
            originX: random(width * 0.2, width * 0.8),
            originY: random(height * 0.2, height * 0.8)
        };
    }

    function createParticle(x, y) {
        var roll = Math.random();
        var color;
        var isPrimary;

        if (roll < 0.3) {
            color = COLORS.primary;
            isPrimary = true;
        } else if (roll < 0.5) {
            color = COLORS.tertiary;
            isPrimary = false;
        } else if (roll < 0.75) {
            color = COLORS.secondary;
            isPrimary = false;
        } else {
            color = COLORS.quaternary;
            isPrimary = true;
        }

        var spawnX = typeof x === 'number' ? x : random(0, width);
        var spawnY = typeof y === 'number' ? y : random(0, height);

        return {
            x: spawnX,
            y: spawnY,
            vx: random(-BASE_SPEED, BASE_SPEED) * 0.8,
            vy: random(-BASE_SPEED, BASE_SPEED) * 0.8,
            radius: random(1.5, isPrimary ? 3.5 : 2.5),
            baseRadius: random(1.5, isPrimary ? 3.5 : 2.5),
            color: color,
            isPrimary: isPrimary,
            phase: random(0, Math.PI * 2),
            pulseSpeed: random(0.005, 0.02),
            driftTargetX: random(0, width),
            driftTargetY: random(0, height),
            driftTimer: random(0, 300),
            driftCooldown: randomInt(200, 500),
            trailTimer: 0,
            trailInterval: randomInt(3, 10)
        };
    }

    function createBurstParticle(x, y, isSecondary) {
        var angle = random(0, Math.PI * 2);
        var speed = random(2, 6);
        var color = isSecondary ? COLORS.burstSecondary : COLORS.burst;
        return {
            x: x,
            y: y,
            vx: Math.cos(angle) * speed,
            vy: Math.sin(angle) * speed,
            radius: random(1, 2.5),
            color: color,
            life: 1,
            decay: random(0.015, 0.04)
        };
    }

    function createPulseWave(x, y) {
        return {
            x: x,
            y: y,
            radius: 0,
            maxRadius: random(120, 200),
            speed: random(1, 3),
            life: 1,
            decay: random(0.006, 0.012),
            color: COLORS.primary
        };
    }

    function initGravityWells() {
        gravityWells = [];
        for (var i = 0; i < GRAVITY_WELL_COUNT; i++) {
            gravityWells.push(createGravityWell());
        }
    }

    function initNebulaOffsets() {
        nebulaOffsets = [];
        for (var i = 0; i < NEBULA_LAYERS; i++) {
            nebulaOffsets.push({
                x: random(0, width),
                y: random(0, height),
                vx: random(0.1, 0.3) * (Math.random() > 0.5 ? 1 : -1),
                vy: random(0.1, 0.3) * (Math.random() > 0.5 ? 1 : -1)
            });
        }
    }

    function initParticles() {
        particles = [];
        trails = [];
        clickBurst = [];
        pulseWaves = [];
        for (var i = 0; i < PARTICLE_COUNT; i++) {
            particles.push(createParticle());
        }
    }

    function spawnBurst(x, y, count) {
        for (var i = 0; i < count; i++) {
            clickBurst.push(createBurstParticle(x, y, i % 3 === 0));
        }
    }

    function spawnPulseWave(x, y) {
        pulseWaves.push(createPulseWave(x, y));
        if (pulseWaves.length > 8) {
            pulseWaves.shift();
        }
    }

    function updateNebula() {
        for (var i = 0; i < nebulaOffsets.length; i++) {
            var n = nebulaOffsets[i];
            n.x += n.vx;
            n.y += n.vy;
            if (n.x > width + 200) { n.x = -200; }
            if (n.x < -200) { n.x = width + 200; }
            if (n.y > height + 200) { n.y = -200; }
            if (n.y < -200) { n.y = height + 200; }
        }
    }

    function updateGravityWells() {
        for (var i = 0; i < gravityWells.length; i++) {
            var gw = gravityWells[i];
            gw.phase += gw.moveSpeed;
            gw.x = gw.originX + Math.cos(gw.phase) * gw.moveRadius;
            gw.y = gw.originY + Math.sin(gw.phase * 0.7) * gw.moveRadius * 0.8;
        }
    }

    function updateTrails() {
        for (var i = trails.length - 1; i >= 0; i--) {
            trails[i].life -= trails[i].decay;
            if (trails[i].life <= 0) {
                trails.splice(i, 1);
            }
        }
    }

    function updateBurst() {
        for (var i = clickBurst.length - 1; i >= 0; i--) {
            var b = clickBurst[i];
            b.x += b.vx;
            b.y += b.vy;
            b.vx *= 0.97;
            b.vy *= 0.97;
            b.life -= b.decay;
            b.radius *= 0.995;
            if (b.life <= 0) {
                clickBurst.splice(i, 1);
            }
        }
    }

    function updatePulseWaves() {
        for (var i = pulseWaves.length - 1; i >= 0; i--) {
            var pw = pulseWaves[i];
            pw.radius += pw.speed;
            pw.life -= pw.decay;
            if (pw.life <= 0 || pw.radius >= pw.maxRadius) {
                pulseWaves.splice(i, 1);
            }
        }
    }

    function updateParticles() {
        for (var i = 0; i < particles.length; i++) {
            var p = particles[i];

            p.driftTimer += 1;
            if (p.driftTimer > p.driftCooldown) {
                p.driftTimer = 0;
                p.driftCooldown = randomInt(200, 500);
                p.driftTargetX = random(-50, width + 50);
                p.driftTargetY = random(-50, height + 50);
            }

            var driftFactor = 0.002;
            p.vx += (p.driftTargetX - p.x) * driftFactor;
            p.vy += (p.driftTargetY - p.y) * driftFactor;

            for (var g = 0; g < gravityWells.length; g++) {
                var gw = gravityWells[g];
                var gdx = gw.x - p.x;
                var gdy = gw.y - p.y;
                var gdist = Math.sqrt(gdx * gdx + gdy * gdy);
                if (gdist < gw.radius && gdist > 1) {
                    var gforce = (gw.radius - gdist) / gw.radius * gw.strength * gw.radius;
                    p.vx += (gdx / gdist) * gforce;
                    p.vy += (gdy / gdist) * gforce;
                }
            }

            if (mouseActive) {
                var mdx = p.x - mouseX;
                var mdy = p.y - mouseY;
                var mdist = Math.sqrt(mdx * mdx + mdy * mdy);

                if (mdist < mouseRadius && mdist > 0.01) {
                    var angle = Math.atan2(mdy, mdx);
                    var force = (mouseRadius - mdist) / mouseRadius;
                    var repelX = Math.cos(angle) * force * 2;
                    var repelY = Math.sin(angle) * force * 2;
                    p.vx += repelX * 0.045;
                    p.vy += repelY * 0.045;
                }

                if (mouseDown && mdist < mouseRadius * 2 && mdist > 0.01) {
                    var pullX = Math.cos(Math.atan2(mdy, mdx)) * force * 0.8;
                    var pullY = Math.sin(Math.atan2(mdy, mdx)) * force * 0.8;
                    p.vx -= pullX * 0.02;
                    p.vy -= pullY * 0.02;
                }
            }

            p.x += p.vx;
            p.y += p.vy;

            var speed = Math.sqrt(p.vx * p.vx + p.vy * p.vy);
            if (speed > MAX_SPEED) {
                p.vx = (p.vx / speed) * MAX_SPEED;
                p.vy = (p.vy / speed) * MAX_SPEED;
            }
            if (speed < MIN_SPEED) {
                var rangle = random(0, Math.PI * 2);
                p.vx = Math.cos(rangle) * BASE_SPEED * 0.3;
                p.vy = Math.sin(rangle) * BASE_SPEED * 0.3;
            }

            if (p.x < -15) { p.x = width + 15; }
            if (p.x > width + 15) { p.x = -15; }
            if (p.y < -15) { p.y = height + 15; }
            if (p.y > height + 15) { p.y = -15; }

            var pulseVal = Math.sin(frameCount * p.pulseSpeed + p.phase);
            p.radius = p.baseRadius + pulseVal * 0.4;
            p.radius = clamp(p.radius, 0.8, 6);

            p.trailTimer++;
            if (p.trailTimer >= p.trailInterval && Math.random() < 0.15) {
                p.trailTimer = 0;
                trails.push({
                    x: p.x,
                    y: p.y,
                    radius: p.radius * 0.5,
                    color: p.color,
                    life: 0.5,
                    decay: 0.06
                });
            }
        }
    }

    function drawNebula() {
        var nebulaColors = [COLORS.nebula1, COLORS.nebula2, COLORS.nebula3];
        for (var i = 0; i < nebulaOffsets.length; i++) {
            var n = nebulaOffsets[i];
            var nc = nebulaColors[i];
            if (!nc) { continue; }

            var nebSize = Math.max(width, height) * 0.6;
            var gradient = ctx.createRadialGradient(n.x, n.y, 0, n.x, n.y, nebSize);
            gradient.addColorStop(0, rgbaString(nc, 1));
            gradient.addColorStop(0.4, rgbaString(nc, 0.5));
            gradient.addColorStop(0.7, rgbaString(nc, 0.1));
            gradient.addColorStop(1, 'rgba(0,0,0,0)');

            ctx.beginPath();
            ctx.arc(n.x, n.y, nebSize, 0, Math.PI * 2);
            ctx.fillStyle = gradient;
            ctx.fill();
        }
    }

    function drawTrails() {
        for (var i = 0; i < trails.length; i++) {
            var t = trails[i];
            var trailAlpha = t.life * t.color.a * 0.25;
            if (trailAlpha <= 0) { continue; }
            ctx.beginPath();
            ctx.arc(t.x, t.y, t.radius * t.life, 0, Math.PI * 2);
            ctx.fillStyle = rgbaString(t.color, trailAlpha);
            ctx.fill();
        }
    }

    function drawBurst() {
        for (var i = 0; i < clickBurst.length; i++) {
            var b = clickBurst[i];
            ctx.beginPath();
            ctx.arc(b.x, b.y, b.radius, 0, Math.PI * 2);
            ctx.fillStyle = rgbaString(b.color, b.life);
            ctx.shadowColor = rgbaString(COLORS.glow, 0.5 * b.life);
            ctx.shadowBlur = b.radius * 3;
            ctx.fill();
            ctx.shadowBlur = 0;
        }
    }

    function drawPulseWaves() {
        for (var i = 0; i < pulseWaves.length; i++) {
            var pw = pulseWaves[i];
            var alpha = pw.life * 0.4;
            var progress = pw.radius / pw.maxRadius;
            var ringAlpha = alpha * (1 - progress);

            ctx.beginPath();
            ctx.arc(pw.x, pw.y, pw.radius, 0, Math.PI * 2);
            ctx.strokeStyle = rgbaString(pw.color, ringAlpha);
            ctx.lineWidth = 1.5 * (1 - progress) + 0.5;
            ctx.stroke();

            ctx.beginPath();
            ctx.arc(pw.x, pw.y, pw.radius * 0.8, 0, Math.PI * 2);
            ctx.strokeStyle = rgbaString(pw.color, ringAlpha * 0.6);
            ctx.lineWidth = 1 * (1 - progress) + 0.3;
            ctx.stroke();
        }
    }

    function drawConnections() {
        for (var i = 0; i < particles.length; i++) {
            for (var j = i + 1; j < particles.length; j++) {
                var dx = particles[i].x - particles[j].x;
                var dy = particles[i].y - particles[j].y;
                var dist = Math.sqrt(dx * dx + dy * dy);

                if (dist < CONNECT_DISTANCE && dist > 0) {
                    var opacityRatio = 1 - dist / CONNECT_DISTANCE;
                    var baseOpacity = opacityRatio * COLORS.lines.a;

                    var bothPrimary = (
                        particles[i].isPrimary &&
                        particles[j].isPrimary
                    );

                    var onePrimary = (
                        particles[i].isPrimary ||
                        particles[j].isPrimary
                    );

                    var lineOpacity;
                    if (bothPrimary && dist < CLOSE_CONNECT_DISTANCE) {
                        lineOpacity = baseOpacity * 2.5;
                    } else if (bothPrimary) {
                        lineOpacity = baseOpacity * 1.8;
                    } else if (onePrimary) {
                        lineOpacity = baseOpacity * 1.3;
                    } else {
                        lineOpacity = baseOpacity;
                    }

                    lineOpacity = Math.min(1, lineOpacity);

                    ctx.beginPath();
                    ctx.moveTo(particles[i].x, particles[i].y);
                    ctx.lineTo(particles[j].x, particles[j].y);

                    if (dist < 40 && bothPrimary) {
                        ctx.strokeStyle = rgbaString(COLORS.primary, lineOpacity * 1.2);
                        ctx.lineWidth = 1.4;
                    } else if (dist < 40 && onePrimary) {
                        ctx.strokeStyle = rgbaString(COLORS.primary, lineOpacity * 0.8);
                        ctx.lineWidth = 1.0;
                    } else if (dist < 40) {
                        ctx.strokeStyle = rgbaString(COLORS.lines, lineOpacity * 1.3);
                        ctx.lineWidth = 0.8;
                    } else {
                        ctx.strokeStyle = rgbaString(COLORS.lines, lineOpacity);
                        ctx.lineWidth = 0.55;
                    }

                    ctx.stroke();
                }
            }
        }
    }

    function drawParticles() {
        for (var i = 0; i < particles.length; i++) {
            var p = particles[i];
            ctx.beginPath();
            ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);

            if (p.isPrimary && p.color === COLORS.primary) {
                ctx.shadowColor = rgbaString(COLORS.glow, 0.35);
                ctx.shadowBlur = p.radius * 2.5;
            } else if (p.color === COLORS.tertiary) {
                ctx.shadowColor = rgbaString(COLORS.tertiary, 0.25);
                ctx.shadowBlur = p.radius * 1.8;
            } else if (p.color === COLORS.quaternary) {
                ctx.shadowColor = rgbaString(COLORS.quaternary, 0.3);
                ctx.shadowBlur = p.radius * 2;
            } else {
                ctx.shadowColor = rgbaString(COLORS.secondary, 0.12);
                ctx.shadowBlur = p.radius * 1.2;
            }

            ctx.fillStyle = rgbaString(p.color);
            ctx.fill();
        }
        ctx.shadowBlur = 0;
    }

    function drawMouseIndicator() {
        if (!mouseActive) { return; }
        var alpha = mouseDown ? 0.18 : 0.07;
        var gradient = ctx.createRadialGradient(mouseX, mouseY, 0, mouseX, mouseY, mouseRadius);
        gradient.addColorStop(0, rgbaString(COLORS.primary, alpha * 1.8));
        gradient.addColorStop(0.3, rgbaString(COLORS.primary, alpha));
        gradient.addColorStop(0.7, rgbaString(COLORS.primary, alpha * 0.3));
        gradient.addColorStop(1, 'rgba(0,0,0,0)');

        ctx.beginPath();
        ctx.arc(mouseX, mouseY, mouseRadius, 0, Math.PI * 2);
        ctx.fillStyle = gradient;
        ctx.fill();

        var innerAlpha = mouseDown ? 0.3 : 0.12;
        ctx.beginPath();
        ctx.arc(mouseX, mouseY, 3.5, 0, Math.PI * 2);
        ctx.fillStyle = rgbaString(COLORS.primary, innerAlpha);
        ctx.shadowColor = rgbaString(COLORS.glow, innerAlpha);
        ctx.shadowBlur = 8;
        ctx.fill();
        ctx.shadowBlur = 0;
    }

    function drawCenterNode() {
        var pulse = Math.sin(frameCount * 0.01) * 0.5 + 0.5;
        var nodeAlpha = 0.06 + pulse * 0.04;

        var gradient = ctx.createRadialGradient(centerX, centerY, 0, centerX, centerY, 80);
        gradient.addColorStop(0, rgbaString(COLORS.primary, nodeAlpha * 1.5));
        gradient.addColorStop(0.5, rgbaString(COLORS.primary, nodeAlpha));
        gradient.addColorStop(1, 'rgba(0,0,0,0)');

        ctx.beginPath();
        ctx.arc(centerX, centerY, 80, 0, Math.PI * 2);
        ctx.fillStyle = gradient;
        ctx.fill();

        ctx.beginPath();
        ctx.arc(centerX, centerY, 2 + pulse, 0, Math.PI * 2);
        ctx.fillStyle = rgbaString(COLORS.primary, 0.2 + pulse * 0.3);
        ctx.shadowColor = rgbaString(COLORS.glow, 0.4);
        ctx.shadowBlur = 10 + pulse * 5;
        ctx.fill();
        ctx.shadowBlur = 0;
    }

    function render() {
        ctx.clearRect(0, 0, width, height);

        drawNebula();
        drawTrails();
        drawConnections();
        drawParticles();
        drawPulseWaves();
        drawBurst();
        drawCenterNode();
        drawMouseIndicator();
    }

    function animate() {
        frameCount++;
        updateNebula();
        updateGravityWells();
        updateParticles();
        updateTrails();
        updateBurst();
        updatePulseWaves();
        render();
        requestAnimationFrame(animate);
    }

    canvas.addEventListener('mousemove', function (e) {
        mouseX = e.clientX;
        mouseY = e.clientY;
        mouseActive = true;
    });

    canvas.addEventListener('mouseleave', function () {
        mouseActive = false;
    });

    canvas.addEventListener('mouseenter', function (e) {
        mouseX = e.clientX;
        mouseY = e.clientY;
        mouseActive = true;
    });

    canvas.addEventListener('mousedown', function (e) {
        mouseDown = true;
        spawnBurst(e.clientX, e.clientY, 12);
    });

    canvas.addEventListener('mouseup', function () {
        mouseDown = false;
    });

    canvas.addEventListener('click', function (e) {
        spawnBurst(e.clientX, e.clientY, 8);
        spawnPulseWave(e.clientX, e.clientY);
    });

    canvas.addEventListener('dblclick', function (e) {
        spawnBurst(e.clientX, e.clientY, 20);
        spawnPulseWave(e.clientX, e.clientY);
    });

    if (isMobile) {
        canvas.addEventListener('touchstart', function (e) {
            if (e.touches.length > 0) {
                mouseX = e.touches[0].clientX;
                mouseY = e.touches[0].clientY;
                mouseActive = true;
                mouseDown = true;
                spawnBurst(e.touches[0].clientX, e.touches[0].clientY, 10);
                spawnPulseWave(e.touches[0].clientX, e.touches[0].clientY);
            }
        }, { passive: true });

        canvas.addEventListener('touchmove', function (e) {
            if (e.touches.length > 0) {
                mouseX = e.touches[0].clientX;
                mouseY = e.touches[0].clientY;
                mouseActive = true;
            }
        }, { passive: true });

        canvas.addEventListener('touchend', function () {
            mouseActive = false;
            mouseDown = false;
        });
    }

    var resizeTimeout;
    window.addEventListener('resize', function () {
        clearTimeout(resizeTimeout);
        resizeTimeout = setTimeout(function () {
            width = window.innerWidth;
            height = window.innerHeight;
            centerX = width / 2;
            centerY = height / 2;
            canvas.width = width;
            canvas.height = height;
            initGravityWells();
            initNebulaOffsets();
        }, 250);
    });

    initGravityWells();
    initNebulaOffsets();
    initParticles();
    animate();
})();
