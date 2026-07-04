// Sinister Apps — Phone UI
// All Supabase calls proxied through server (no keys in client)

var currentTab = 'banking';
var bizList = [];
var bizIdx = 0;
var activeSubtab = 'recent';
var synEntries = [];

// ---- Clock ----
function tick() {
  var d = new Date();
  var h = d.getHours().toString().padStart(2, '0');
  var m = d.getMinutes().toString().padStart(2, '0');
  var el = document.getElementById('clock');
  if (el) el.textContent = h + ':' + m;
}
tick();
setInterval(tick, 30000);

// ---- NUI Proxy ----
var proxyIdCounter = 0;
var proxyCallbacks = {};

function proxyRequest(app, payload) {
  return new Promise(function(resolve) {
    var id = ++proxyIdCounter;
    proxyCallbacks[id] = resolve;
    fetch('https://' + document.location.hostname + '/proxyRequest', {
      method: 'POST',
      body: JSON.stringify({ id: id, app: app, payload: payload })
    });
    setTimeout(function() {
      if (proxyCallbacks[id]) {
        delete proxyCallbacks[id];
        resolve({ _error: 'Request timed out' });
      }
    }, 15000);
  });
}

// ---- Tab Navigation ----
function switchTab(tab) {
  currentTab = tab;
  document.querySelectorAll('.foot-btn').forEach(function(b) { b.classList.remove('active'); });
  document.getElementById('btn-' + tab).classList.add('active');
  renderTab();
}

function renderTab() {
  var root = document.getElementById('app-root');
  if (currentTab === 'banking') renderBanking(root);
  else if (currentTab === 'browser') renderBrowser(root);
  else if (currentTab === 'syntok') renderSyntok(root);
}

// ---- BANKING ----
async function renderBanking(root) {
  root.innerHTML = '<div class="loading">Loading businesses...</div>';
  var result = await proxyRequest('banking', { action: 'loadBusinesses', citizenid: '' });
  if (result._error) { root.innerHTML = '<div class="error">' + result._error + '</div>'; return; }
  bizList = result || [];
  if (!bizList.length) { root.innerHTML = '<div class="empty">No active businesses.<br>Buy one at City Hall!</div>'; return; }
  bizIdx = 0;
  buildBankingUI(root);
}

function buildBankingUI(root) {
  var b = bizList[bizIdx];
  var opts = bizList.map(function(biz, i) {
    return '<option value="' + i + '"' + (i === bizIdx ? ' selected' : '') + '>' + biz.name + '</option>';
  }).join('');

  root.innerHTML =
    '<select id="biz-select" onchange="onBizChange(this.value)">' + opts + '</select>' +
    '<div class="card">' +
      '<div class="card-header" id="biz-name">' + (b.name || 'Business') + '</div>' +
      '<div class="big-num" id="biz-balance">$' + ((b.bank_account || 0)).toLocaleString() + '</div>' +
      '<div class="sub-text" id="biz-rev">Revenue: $' + ((b.revenue || 0)).toLocaleString() + '</div>' +
    '</div>' +
    '<div class="sub-tabs">' +
      '<button class="sub-tab active" onclick="loadSubData(\'recent\', this)">Recent</button>' +
      '<button class="sub-tab" onclick="loadSubData(\'payroll\', this)">Payroll</button>' +
      '<button class="sub-tab" onclick="loadSubData(\'pnl\', this)">P&amp;L</button>' +
    '</div>' +
    '<div id="biz-sub-content"><div class="loading">Select a tab above</div></div>';

  loadSubData('recent', document.querySelector('.sub-tab'));
}

function onBizChange(idx) {
  bizIdx = parseInt(idx);
  var b = bizList[bizIdx];
  if (!b) return;
  document.getElementById('biz-name').textContent = b.name;
  document.getElementById('biz-balance').textContent = '$' + ((b.bank_account || 0)).toLocaleString();
  document.getElementById('biz-rev').textContent = 'Revenue: $' + ((b.revenue || 0)).toLocaleString();
  document.querySelectorAll('.sub-tab').forEach(function(t) { t.classList.remove('active'); });
  loadSubData(activeSubtab, document.querySelector('.sub-tab[onclick*="' + activeSubtab + '"]') || document.querySelector('.sub-tab'));
}

async function loadSubData(subtab, btn) {
  activeSubtab = subtab;
  document.querySelectorAll('.sub-tab').forEach(function(t) { t.classList.remove('active'); });
  if (btn) btn.classList.add('active');

  var b = bizList[bizIdx];
  if (!b) return;

  var panel = document.getElementById('biz-sub-content');
  panel.innerHTML = '<div class="loading">Loading...</div>';

  var result;
  if (subtab === 'recent') result = await proxyRequest('banking', { action: 'loadTransactions', business_id: b.id });
  else if (subtab === 'payroll') result = await proxyRequest('banking', { action: 'loadEmployees', business_id: b.id });
  else if (subtab === 'pnl') result = await proxyRequest('banking', { action: 'loadPnl', business_id: b.id });
  if (result._error) { panel.innerHTML = '<div class="error">' + result._error + '</div>'; return; }

  var data = result || [];
  if (!data.length) { panel.innerHTML = '<div class="empty">Nothing here yet.</div>'; return; }

  if (subtab === 'recent') {
    panel.innerHTML = data.map(function(tx) {
      var amt = tx.amount || 0;
      var cls = amt >= 0 ? 'green' : 'red';
      return '<div class="tx-row"><span class="tx-label">' + (tx.reason || 'Transaction') + '</span><span class="tx-amount ' + cls + '">' + (amt >= 0 ? '+' : '') + '$' + Math.abs(amt).toLocaleString() + '</span></div>';
    }).join('');
  } else if (subtab === 'payroll') {
    panel.innerHTML = data.map(function(e) {
      return '<div class="tx-row"><span class="tx-label">' + (e.is_ai ? '[AI] ' : '') + (e.citizenid || 'Unknown') + '</span><span class="tx-amount">$' + ((e.hourly_wage || e.salary || 0)).toLocaleString() + '/hr</span></div>';
    }).join('');
  } else if (subtab === 'pnl') {
    panel.innerHTML = data.map(function(p) {
      var rev = p.gross_income || p.revenue || 0;
      var exp = p.expenses || 0;
      var net = p.net_profit !== undefined ? p.net_profit : (rev - exp);
      var week = (p.week_start || p.created_at || '').substring(0, 10);
      return '<div class="pnl-card"><div class="pnl-header">Week of ' + week + '</div>' +
        '<div class="pnl-row"><span>Revenue</span><span>$' + rev.toLocaleString() + '</span></div>' +
        '<div class="pnl-row"><span>Expenses</span><span style="color:#e53935">$' + exp.toLocaleString() + '</span></div>' +
        '<div class="pnl-row pnl-divider"><span>Net Profit</span><span style="color:' + (net >= 0 ? '#4CAF50' : '#e53935') + '">$' + net.toLocaleString() + '</span></div></div>';
    }).join('');
  }
}

// ---- BROWSER ----
function renderBrowser(root) {
  var svc = [
    { n: 'City Hall', d: 'Get ID, licenses, apply for jobs', h: 'Downtown Houston', x: -540.58, y: -212.02 },
    { n: "Mosley's Auto & Chop Shop", d: 'Vehicle repair, mods, chop shop', h: 'Davis Ave', x: 540, y: -200 },
    { n: 'Lone Star Grill', d: 'Texas burgers, open 24/7', h: 'Mission Row', x: 440, y: -980 },
    { n: "Bucky's Stop & Shop", d: 'Gas, snacks, Texas-sized', h: 'Route 68', x: 640.66, y: 276.22 },
    { n: 'Travis County Courthouse', d: 'Legal services, marriage licenses', h: 'Downtown', x: 243.5, y: -1086 },
    { n: 'Houston Intl Airport', d: 'Flights, ATC, airfield ownership', h: 'LSIA', x: -1050, y: -2800 },
    { n: 'Fort Zancudo', d: 'Texas National Guard — Restricted', h: 'Fort Zancudo', x: -2200, y: 3250 }
  ];
  root.innerHTML =
    '<div class="search-bar"><input id="browser-q" placeholder="Search Sinister State..." oninput="searchBrowser()"><button onclick="searchBrowser()">Go</button></div>' +
    '<div id="browser-results"></div>';
  showBrowserResults(svc);
}

function searchBrowser() {
  var q = (document.getElementById('browser-q') || {}).value || '';
  var svc = [
    { n: 'City Hall', d: 'Get ID, licenses, apply for jobs', h: 'Downtown Houston', x: -540.58, y: -212.02 },
    { n: "Mosley's Auto & Chop Shop", d: 'Vehicle repair, mods, chop shop', h: 'Davis Ave', x: 540, y: -200 },
    { n: 'Lone Star Grill', d: 'Texas burgers, open 24/7', h: 'Mission Row', x: 440, y: -980 },
    { n: "Bucky's Stop & Shop", d: 'Gas, snacks, Texas-sized', h: 'Route 68', x: 640.66, y: 276.22 },
    { n: 'Travis County Courthouse', d: 'Legal services, marriage licenses', h: 'Downtown', x: 243.5, y: -1086 },
    { n: 'Houston Intl Airport', d: 'Flights, ATC, airfield ownership', h: 'LSIA', x: -1050, y: -2800 },
    { n: 'Fort Zancudo', d: 'Texas National Guard — Restricted', h: 'Fort Zancudo', x: -2200, y: 3250 }
  ];
  if (q) {
    q = q.toLowerCase();
    svc = svc.filter(function(s) { return s.n.toLowerCase().includes(q) || s.d.toLowerCase().includes(q) || s.h.toLowerCase().includes(q); });
  }
  showBrowserResults(svc);
}

function showBrowserResults(svc) {
  var el = document.getElementById('browser-results');
  if (!el) return;
  el.innerHTML = svc.map(function(s) {
    return '<div class="search-result" onclick="setGPS(' + s.x + ',' + s.y + ')"><b>' + s.n + '</b><br>' + s.d + '<span class="gps-hint">GPS: ' + s.h + '</span></div>';
  }).join('');
}

function setGPS(x, y) {
  fetch('https://' + document.location.hostname + '/setGPS', { method: 'POST', body: JSON.stringify({ x: x, y: y }) });
}

// ---- SYNTOK ----
async function renderSyntok(root) {
  root.innerHTML = '<div class="loading">Loading chronicles...</div>';
  var result = await proxyRequest('syntok', { action: 'loadChronicles' });
  if (result._error) { root.innerHTML = '<div class="error">' + result._error + '</div>'; return; }
  synEntries = result || [];
  if (!synEntries.length) { root.innerHTML = '<div class="empty">No chronicles yet.<br>Events will appear here.</div>'; return; }
  root.innerHTML = synEntries.map(function(c) {
    return '<div class="syn-card"><div class="syn-title">Score: ' + (c.score || '?') + '/30 — ' + (c.title || 'Untitled') + '</div><div class="syn-body">' + ((c.description || '').substring(0, 250)) + '</div></div>';
  }).join('') +
  '<div class="syn-card"><div class="syn-title">Submit your clips</div><div class="syn-body">Press F12 to screenshot in-game. Featured clips earn rewards!</div></div>';
}

// ---- Init ----
renderTab();
