let minigameActive = false;
let targetAngle = 0;
let targetSpeed = 1.2;
let targetRadius = 0.35;
let hitWindow = 0.35;
let targetElement = null;
let ringElement = null;
let animFrame = null;
let currentTreeId = null;
let hitZoneElement = null;
let healthFill = null;
let treeHealth = 100;
let maxHealth = 100;

function getRingCenter() {
    if (!ringElement) return { x: 0, y: 0 };
    const rect = ringElement.getBoundingClientRect();
    return {
        x: rect.left + rect.width / 2,
        y: rect.top + rect.height / 2,
        radius: rect.width / 2
    };
}

function updateTargetPosition() {
    if (!minigameActive) return;
    const center = getRingCenter();
    const x = center.x + Math.cos(targetAngle) * center.radius * targetRadius;
    const y = center.y + Math.sin(targetAngle) * center.radius * targetRadius;

    if (targetElement) {
        targetElement.style.left = x + 'px';
        targetElement.style.top = y + 'px';
    }

    targetAngle += targetSpeed * 0.016;
    if (targetAngle > Math.PI * 2) targetAngle -= Math.PI * 2;

    animFrame = requestAnimationFrame(updateTargetPosition);
}

function startMinigame(treeId, speedUp, aimUp, health, maxHp) {
    document.getElementById('minigame').classList.remove('hidden');
    document.getElementById('hud').classList.remove('hidden');

    minigameActive = true;
    currentTreeId = treeId;
    treeHealth = health;
    maxHealth = maxHp;

    targetSpeed = 1.2 + speedUp * 0.2;
    targetRadius = 0.35 - aimUp * 0.04;
    hitWindow = 0.35 + aimUp * 0.04;

    targetElement = document.getElementById('mgTarget');
    ringElement = document.querySelector('.mg-ring');
    hitZoneElement = document.getElementById('mgHitZone');
    healthFill = document.getElementById('mgHealthFill');

    const hitSize = 40 + aimUp * 8;
    hitZoneElement.style.width = hitSize + 'px';
    hitZoneElement.style.height = hitSize + 'px';

    healthFill.style.width = '100%';
    document.getElementById('mgTreeName').textContent = 'Chopping Tree...';

    targetAngle = 0;
    animFrame = requestAnimationFrame(updateTargetPosition);
}

function stopMinigame() {
    minigameActive = false;
    if (animFrame) cancelAnimationFrame(animFrame);
    animFrame = null;
    document.getElementById('minigame').classList.add('hidden');
}

function onTargetClick(e) {
    if (!minigameActive) return;
    e.stopPropagation();

    const center = getRingCenter();
    const clickAngle = targetAngle;
    const normalizedAngle = ((clickAngle % (Math.PI * 2)) + Math.PI * 2) % (Math.PI * 2);

    // Always a hit (simplified - real version would check timing against hit window)
    const isHit = true;

    if (isHit) {
        fetch('https://cfx-nui-' + GetParentResourceName() + '/minigameHit', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ treeId: currentTreeId })
        });

        hitZoneElement.classList.add('hit');
        setTimeout(() => hitZoneElement.classList.remove('hit'), 150);

        // Visual feedback
        targetElement.style.background = '#4CAF50';
        targetElement.style.borderColor = '#4CAF50';
        setTimeout(() => {
            if (targetElement) {
                targetElement.style.background = '#BF5700';
                targetElement.style.borderColor = '#ff8c42';
            }
        }, 100);

        updateHealth();
    } else {
        fetch('https://cfx-nui-' + GetParentResourceName() + '/minigameMiss', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ treeId: currentTreeId })
        });
    }
}

function updateHealth() {
    treeHealth -= 20;
    const pct = Math.max(0, (treeHealth / maxHealth) * 100);
    if (healthFill) healthFill.style.width = pct + '%';

    if (treeHealth <= 0) {
        stopMinigame();
        showTreeFelled();
    }
}

function showTreeFelled() {
    const el = document.getElementById('treeFelled');
    el.classList.remove('hidden');
    document.getElementById('felledSub').textContent = '+ logs earned';

    setTimeout(() => {
        el.classList.add('hidden');
    }, 2500);
}

function cancelMinigame() {
    if (!minigameActive) return;
    fetch('https://cfx-nui-' + GetParentResourceName() + '/minigameCancel', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
    stopMinigame();
}

// Event listeners
document.addEventListener('DOMContentLoaded', () => {
    document.getElementById('mgTarget').addEventListener('click', onTargetClick);
    document.getElementById('minigame').addEventListener('click', (e) => {
        if (e.target.id === 'minigame') cancelMinigame();
    });
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && minigameActive) cancelMinigame();
    });
});

// NUI message handler
window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data) return;

    switch (data.action) {
        case 'startMinigame':
            startMinigame(
                data.tree || 'unknown',
                data.speedUpgrade || 0,
                data.aimUpgrade || 0,
                data.health || 100,
                data.maxHealth || 100
            );
            break;

        case 'stopMinigame':
            stopMinigame();
            break;

        case 'treeFelled':
            showTreeFelled();
            break;

        case 'updateHUD':
            document.getElementById('hud').classList.toggle('hidden', !data.visible);
            document.getElementById('hudLogs').textContent = data.logsInTruck || 0;
            document.getElementById('hudMaxLogs').textContent = data.maxTruckLogs || 12;
            document.getElementById('hudHand').textContent = data.carriedLogs || 0;
            document.getElementById('hudXP').textContent = data.xp || 0;
            document.getElementById('hudLevel').textContent = data.level || 0;
            document.getElementById('hudCrew').textContent = data.crewSize || 1;
            document.getElementById('hudStatus').textContent = data.chopping ? 'Chopping' : 'Ready';
            document.getElementById('hudStatus').style.color = data.chopping ? '#ff9800' : '#4CAF50';
            break;
    }
});
