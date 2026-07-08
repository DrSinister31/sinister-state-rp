console.log('Fishing NUI loaded');

document.documentElement.style.background = 'transparent';
document.body.style.background = 'transparent';
document.body.style.backgroundColor = 'transparent';

const app = document.getElementById('app');
const fishList = document.getElementById('fishList');
const closeBtn = document.getElementById('closeBtn');

const resourceName = window.GetParentResourceName ? window.GetParentResourceName() : 'wasabi_fishing';

function post(event, data = {}) {
    fetch(`https://${resourceName}/${event}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8'
        },
        body: JSON.stringify(data)
    }).catch((err) => {
        console.error('NUI post failed:', err);
    });
}

function moneyFormat(value) {
    return `$${Number(value || 0).toLocaleString()}`;
}

function renderFish(items) {
    fishList.innerHTML = '';

    if (!items || !items.length) {
        fishList.innerHTML = `<div class="empty-state">You have no fish to sell right now.</div>`;
        return;
    }

    for (const fish of items) {
        const card = document.createElement('div');
        card.className = 'fish-card';

        card.innerHTML = `
            <img src="${fish.image}" alt="${fish.label}">
            <div class="fish-info">
                <div class="fish-topline">
                    <h3>${fish.label}</h3>
                    <span class="fish-badge">Sellable</span>
                </div>

                <div class="fish-stats">
                    <div class="stat-block">
                        <div class="stat-label">Owned</div>
                        <div class="stat-value">${fish.count}</div>
                    </div>
                    <div class="stat-block">
                        <div class="stat-label">Per Fish</div>
                        <div class="stat-value">${moneyFormat(fish.price)}</div>
                    </div>
                    <div class="stat-block">
                        <div class="stat-label">Total Value</div>
                        <div class="stat-value">${moneyFormat(fish.total)}</div>
                    </div>
                </div>
            </div>
            <button class="sell-btn">Sell All ${fish.label}</button>
        `;

        const btn = card.querySelector('.sell-btn');
        btn.addEventListener('click', () => {
            post('sellFishType', { item: fish.item });
        });

        fishList.appendChild(card);
    }
}

window.addEventListener('message', (event) => {
    const data = event.data;

    if (data.action === 'openFishingSell') {
        app.classList.remove('hidden');
        renderFish(data.fish || []);
    }

    if (data.action === 'refreshFishingSell') {
        renderFish(data.fish || []);
    }

    if (data.action === 'closeFishingSell') {
        app.classList.add('hidden');
    }
});

closeBtn.addEventListener('click', () => {
    post('closeFishingSell');
});

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        post('closeFishingSell');
    }
});
