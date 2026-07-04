// Sinister Apps — Phone UI with server-side proxy for Supabase
let currentApp = null;
let currentCitizenid = null;

// Phone clock
function updateClock() {
    const now = new Date();
    const h = now.getHours().toString().padStart(2, '0');
    const m = now.getMinutes().toString().padStart(2, '0');
    const el = document.getElementById('phone-time');
    if (el) el.textContent = h + ':' + m;
}
updateClock();
setInterval(updateClock, 30000);

// Proxy call through NUI → client → server → client → NUI
let proxyId = 0;
const proxyCallbacks = {};

window.addEventListener('message', function(e) {
    if (e.data.type === 'proxyResponse') {
        const cb = proxyCallbacks[e.data.id];
        if (cb) {
            delete proxyCallbacks[e.data.id];
            cb(e.data.data);
        }
    } else if (e.data.type === 'loadBusinessBanking') {
        currentCitizenid = e.data.citizenid;
    } else if (e.data.type === 'loadSyntok') {
        loadSyntok();
    }
});

function proxyRequest(app, payload) {
    return new Promise(function(resolve) {
        const id = ++proxyId;
        proxyCallbacks[id] = resolve;
        fetch('https://' + document.location.hostname + '/proxyRequest', {
            method: 'POST',
            body: JSON.stringify({ id: id, app: app, payload: payload })
        });
    });
}

// ===== NAVIGATION =====

function openApp(name) {
    currentApp = name;
    document.getElementById('home').classList.remove('active');
    document.querySelectorAll('.app-frame').forEach(function(f) { f.classList.remove('active'); });
    var frame = document.getElementById(name + '-frame');
    if (frame) { frame.classList.add('active'); }

    fetch('https://' + document.location.hostname + '/appOpened', { method: 'POST', body: JSON.stringify({ app: name }) });

    if (name === 'banking') loadBanking();
    if (name === 'browser') loadBrowser();
    if (name === 'syntok') loadSyntok();
}

function closeApp() {
    document.querySelectorAll('.app-frame').forEach(function(f) { f.classList.remove('active'); });
    document.getElementById('home').classList.add('active');
    currentApp = null;
    fetch('https://' + document.location.hostname + '/appClosed', { method: 'POST' });
}

// ===== BANKING =====

var bizData = [];

async function loadBanking() {
    var content = document.getElementById('banking-content');
    content.innerHTML = '<div class="loading-text">Loading your businesses...</div>';

    try {
        var result = await proxyRequest('banking', { action: 'loadBusinesses', citizenid: currentCitizenid || '' });
        if (result._error) { content.innerHTML = '<div class="error-text">' + result._error + '</div>'; return; }
        bizData = result || [];
        if (!bizData.length) {
            content.innerHTML = '<div class="empty-text">No active businesses.<br>Buy one at City Hall!</div>';
            return;
        }
        renderBanking();
    } catch(e) {
        content.innerHTML = '<div class="error-text">Failed to connect to server</div>';
    }
}

function renderBanking() {
    var content = document.getElementById('banking-content');
    var b = bizData[0];
    var selOptions = bizData.map(function(biz, i) {
        return '<option value="' + i + '"' + (i === 0 ? ' selected' : '') + '>' + biz.name + '</option>';
    }).join('');

    content.innerHTML = ''
        + '<div class="balance-card">'
        +   '<select id="biz-select" onchange="showBiz()">' + selOptions + '</select>'
        +   '<h3 id="biz-name">' + (b.name || 'Business') + '</h3>'
        +   '<div class="amount" id="biz-balance">$' + ((b.bank_account || 0)).toLocaleString() + '</div>'
        +   '<div class="sub" id="biz-revenue">Revenue: $' + ((b.revenue || 0)).toLocaleString() + '</div>'
        + '</div>'
        + '<div class="tab-bar">'
        +   '<button class="tab active" onclick="bankingTab(\'recent\', this)">Recent</button>'
        +   '<button class="tab" onclick="bankingTab(\'payroll\', this)">Payroll</button>'
        +   '<button class="tab" onclick="bankingTab(\'pnl\', this)">P&amp;L</button>'
        + '</div>'
        + '<div id="biz-recent" class="tab-content active"><div class="loading-text">Select a tab</div></div>'
        + '<div id="biz-payroll" class="tab-content"><div class="loading-text">Select a tab</div></div>'
        + '<div id="biz-pnl" class="tab-content"><div class="loading-text">Select a tab</div></div>';
}

function showBiz() {
    var idx = document.getElementById('biz-select').value;
    var b = bizData[idx];
    if (!b) return;
    document.getElementById('biz-name').textContent = b.name;
    document.getElementById('biz-balance').textContent = '$' + ((b.bank_account || 0)).toLocaleString();
    document.getElementById('biz-revenue').textContent = 'Revenue: $' + ((b.revenue || 0)).toLocaleString();
}

async function bankingTab(tab, btn) {
    var tabs = document.querySelectorAll('#banking-content .tab');
    tabs.forEach(function(t) { t.classList.remove('active'); });
    btn.classList.add('active');
    var contents = document.querySelectorAll('#banking-content .tab-content');
    contents.forEach(function(c) { c.classList.remove('active'); });
    var panel = document.getElementById('biz-' + tab);
    if (panel) panel.classList.add('active');

    var idx = document.getElementById('biz-select').value;
    var b = bizData[idx];
    if (!b) return;

    if (tab === 'recent') {
        panel.innerHTML = '<div class="loading-text">Loading transactions...</div>';
        var result = await proxyRequest('banking', { action: 'loadTransactions', business_id: b.id });
        if (result._error) { panel.innerHTML = '<div class="error-text">' + result._error + '</div>'; return; }
        var txs = result || [];
        if (!txs.length) { panel.innerHTML = '<div class="empty-text">No transactions yet</div>'; return; }
        panel.innerHTML = txs.map(function(tx) {
            var cls = (tx.amount || 0) >= 0 ? 'positive' : 'negative';
            var sign = (tx.amount || 0) >= 0 ? '+' : '';
            return '<div class="tx-row"><span class="tx-label">' + (tx.reason || 'Transaction') + '</span><span class="tx-amount ' + cls + '">' + sign + '$' + Math.abs(tx.amount || 0).toLocaleString() + '</span></div>';
        }).join('');
    } else if (tab === 'payroll') {
        panel.innerHTML = '<div class="loading-text">Loading employees...</div>';
        var result = await proxyRequest('banking', { action: 'loadEmployees', business_id: b.id });
        if (result._error) { panel.innerHTML = '<div class="error-text">' + result._error + '</div>'; return; }
        var emps = result || [];
        if (!emps.length) { panel.innerHTML = '<div class="empty-text">No employees</div>'; return; }
        panel.innerHTML = emps.map(function(emp) {
            var wage = emp.hourly_wage || emp.salary || 0;
            return '<div class="tx-row"><span class="tx-label">' + (emp.is_ai ? '[AI] ' : '') + (emp.citizenid || 'Unknown') + '</span><span class="tx-amount">$' + wage.toLocaleString() + '/hr</span></div>';
        }).join('');
    } else if (tab === 'pnl') {
        panel.innerHTML = '<div class="loading-text">Loading P&amp;L reports...</div>';
        var result = await proxyRequest('banking', { action: 'loadPnl', business_id: b.id });
        if (result._error) { panel.innerHTML = '<div class="error-text">' + result._error + '</div>'; return; }
        var pnls = result || [];
        if (!pnls.length) { panel.innerHTML = '<div class="empty-text">No P&amp;L reports yet. Generated weekly.</div>'; return; }
        panel.innerHTML = pnls.map(function(p) {
            return '<div class="pnl-card">'
                + '<div class="pnl-header">Week of ' + (p.week_start || p.created_at || 'Unknown').substring(0,10) + '</div>'
                + '<div class="pnl-row"><span>Revenue</span><span>$' + ((p.gross_income || p.revenue || 0)).toLocaleString() + '</span></div>'
                + '<div class="pnl-row"><span>Expenses</span><span style="color:#e53935">$' + ((p.expenses || 0)).toLocaleString() + '</span></div>'
                + '<div class="pnl-row" style="font-weight:700;margin-top:4px;padding-top:4px;border-top:1px solid #1e1e2e"><span>Net Profit</span><span style="color:' + ((p.net_profit || ((p.gross_income||0)-(p.expenses||0))) >= 0 ? '#4CAF50' : '#e53935') + '">$' + ((p.net_profit || ((p.gross_income||0)-(p.expenses||0)))).toLocaleString() + '</span></div>'
                + '</div>';
        }).join('');
    }
}

// ===== BROWSER =====

var browserServices = [
    { name: 'City Hall', desc: 'Get ID, licenses, apply for jobs', hint: 'Downtown Houston', x: -540.58, y: -212.02 },
    { name: "Mosley's Auto & Chop Shop", desc: 'Vehicle repair, mods, chop shop', hint: 'Davis Ave', x: 540, y: -200 },
    { name: 'Lone Star Grill', desc: 'Texas burgers, open 24/7', hint: 'Mission Row', x: 440, y: -980 },
    { name: "Bucky's Stop & Shop", desc: 'Gas, snacks, Texas-sized', hint: 'Route 68', x: 640.66, y: 276.22 },
    { name: 'Travis County Courthouse', desc: 'Legal services, marriage licenses', hint: 'Downtown', x: 243.5, y: -1086.0 },
    { name: 'Houston Intl Airport', desc: 'Flights, ATC, airfield ownership', hint: 'LSIA', x: -1050, y: -2800 },
    { name: 'Fort Zancudo', desc: 'Texas National Guard — Restricted', hint: 'Fort Zancudo', x: -2200, y: 3250 }
];

function loadBrowser() {
    renderBrowser('');
}

function renderBrowser(filter) {
    var results = document.getElementById('browser-results');
    var filtered = browserServices;
    if (filter) {
        var q = filter.toLowerCase();
        filtered = browserServices.filter(function(s) {
            return s.name.toLowerCase().includes(q) || s.desc.toLowerCase().includes(q) || s.hint.toLowerCase().includes(q);
        });
    }
    results.innerHTML = filtered.map(function(s) {
        return '<div class="result-card" onclick="setGPS(' + s.x + ',' + s.y + ')"><b>' + s.name + '</b><br>' + s.desc + '<span class="gps-hint">GPS: ' + s.hint + '</span></div>';
    }).join('');
}

function searchBrowser() {
    var q = document.getElementById('browser-search').value;
    renderBrowser(q);
}

function setGPS(x, y) {
    fetch('https://' + document.location.hostname + '/setGPS', { method: 'POST', body: JSON.stringify({ x: x, y: y }) });
    closeApp();
}

// ===== SYNTOK =====

async function loadSyntok() {
    var content = document.getElementById('syntok-content');
    content.innerHTML = '<div class="loading-text">Loading chronicles...</div>';

    try {
        var result = await proxyRequest('syntok', { action: 'loadChronicles' });
        if (result._error) { content.innerHTML = '<div class="error-text">' + result._error + '</div>'; return; }
        var entries = result || [];
        if (!entries.length) { content.innerHTML = '<div class="empty-text">No chronicles yet. Events will appear here as they happen.</div>'; return; }
        content.innerHTML = entries.map(function(c) {
            return '<div class="clip-card"><div class="clip-author">Score: ' + (c.score || '?') + '/30 — ' + (c.title || 'Untitled') + '</div><div class="clip-placeholder">' + ((c.description || '').substring(0, 200)) + '</div></div>';
        }).join('') + '<div class="clip-card"><div class="clip-author">Submit your clips</div><div class="clip-placeholder">Press F12 to screenshot in-game</div></div>';
    } catch(e) {
        content.innerHTML = '<div class="error-text">Failed to connect to server</div>';
    }
}
