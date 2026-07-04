import React, { useState, useEffect } from 'react';

const RESOURCE_NAME = 'sinister_apps';

async function nuiFetch(event: string, data: any = {}): Promise<any> {
  try {
    const resp = await fetch(`https://cfx-nui-${RESOURCE_NAME}/${event}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    return await resp.json();
  } catch {
    return { _error: 'Failed to reach server' };
  }
}

async function proxyRequest(app: string, payload: any): Promise<any> {
  return nuiFetch('proxyRequest', { id: Date.now(), app, payload });
}

// ------- Types -------
interface Business {
  id: string;
  name: string;
  bank_account?: number;
  revenue?: number;
}

interface TxRow {
  reason?: string;
  amount?: number;
}

interface Employee {
  citizenid?: string;
  is_ai?: boolean;
  hourly_wage?: number;
  salary?: number;
}

interface PnlRow {
  week_start?: string;
  created_at?: string;
  gross_income?: number;
  revenue?: number;
  expenses?: number;
  net_profit?: number;
}

interface Chronicle {
  title?: string;
  description?: string;
  score?: number;
}

interface Service {
  name: string;
  desc: string;
  hint: string;
  x: number;
  y: number;
}

const SERVICES: Service[] = [
  { name: 'City Hall', desc: 'Get ID, licenses, apply for jobs', hint: 'Downtown Houston', x: -540.58, y: -212.02 },
  { name: "Mosley's Auto & Chop Shop", desc: 'Vehicle repair, mods, chop shop', hint: 'Davis Ave', x: 540, y: -200 },
  { name: 'Lone Star Grill', desc: 'Texas burgers, open 24/7', hint: 'Mission Row', x: 440, y: -980 },
  { name: "Bucky's Stop & Shop", desc: 'Gas, snacks, Texas-sized', hint: 'Route 68', x: 640.66, y: 276.22 },
  { name: 'Travis County Courthouse', desc: 'Legal services, marriage licenses', hint: 'Downtown', x: 243.5, y: -1086 },
  { name: 'Houston Intl Airport', desc: 'Flights, ATC, airfield ownership', hint: 'LSIA', x: -1050, y: -2800 },
  { name: 'Fort Zancudo', desc: 'Texas National Guard — Restricted', hint: 'Fort Zancudo', x: -2200, y: 3250 },
];

// ------- Styles (dark Texas theme) -------
const css = `
.sa-root { height:100%; display:flex; flex-direction:column; background:#0d0d14; color:#e0e0e8; font-family:'Segoe UI',sans-serif; }
.sa-header { display:flex; align-items:center; padding:10px 14px; background:#08080f; border-bottom:1px solid #1a1a28; flex-shrink:0; }
.sa-header h2 { color:#BF5700; font-size:15px; margin:0; flex:1; }
.sa-tabs { display:flex; flex-shrink:0; background:#08080f; border-bottom:1px solid #1a1a28; }
.sa-tab { flex:1; padding:12px 8px; text-align:center; cursor:pointer; color:#6a6a7a; font-size:12px; font-weight:600; background:transparent; border:none; border-bottom:2px solid transparent; transition:.15s; }
.sa-tab:hover { color:#a0a0b0; }
.sa-tab.active { color:#BF5700; border-bottom-color:#BF5700; }
.sa-content { flex:1; overflow-y:auto; padding:12px; }
.sa-card { background:#151520; border:1px solid #1e1e2e; border-radius:10px; padding:14px; margin-bottom:10px; }
.sa-card-header { color:#BF5700; font-weight:700; font-size:13px; margin-bottom:8px; }
.sa-balance { font-size:24px; font-weight:700; color:#F5EBE0; }
.sa-sub { font-size:12px; color:#8a8a94; margin-top:2px; }
.sa-select { width:100%; background:#0d0d14; color:#e0e0e8; border:1px solid #2a2a3a; padding:8px 10px; border-radius:6px; font-size:13px; margin-bottom:10px; }
.sa-tab-row { display:flex; gap:4px; margin-bottom:10px; background:#0d0d14; border-radius:6px; padding:3px; }
.sa-tab-btn { flex:1; padding:8px; background:transparent; border:none; color:#6a6a7a; font-size:11px; font-weight:600; border-radius:4px; cursor:pointer; }
.sa-tab-btn.active { background:#1a1020; color:#BF5700; }
.sa-tx-row { display:flex; justify-content:space-between; padding:8px 0; border-bottom:1px solid #151520; font-size:12px; }
.sa-tx-label { color:#b0b0bc; }
.sa-tx-amount { font-weight:600; }
.sa-tx-amount.pos { color:#4CAF50; }
.sa-tx-amount.neg { color:#e53935; }
.sa-pnl-row { display:flex; justify-content:space-between; margin:2px 0; font-size:11px; color:#b0b0bc; }
.sa-pnl-divider { border-top:1px solid #1e1e2e; margin-top:4px; padding-top:4px; font-weight:700; }
.sa-search { display:flex; gap:8px; margin-bottom:12px; }
.sa-search input { flex:1; background:#151520; color:#e0e0e8; border:1px solid #2a2a3a; padding:10px 12px; border-radius:6px; font-size:13px; }
.sa-search input::placeholder { color:#5a5a6a; }
.sa-search button { background:#BF5700; color:white; border:none; padding:10px 18px; border-radius:6px; font-weight:600; cursor:pointer; font-size:13px; }
.sa-result { padding:12px; cursor:pointer; border-bottom:1px solid #151520; }
.sa-result:hover { background:#151520; }
.sa-result b { color:#BF5700; }
.sa-gps { color:#5a5a6a; font-size:11px; margin-top:2px; display:block; }
.sa-empty { color:#6a6a7a; text-align:center; padding:30px 10px; font-size:13px; }
.sa-loading { color:#8a8a94; text-align:center; padding:20px; font-size:13px; }
`

// ------- Main App -------
export function SinisterApp() {
  const [tab, setTab] = useState('banking');

  return (
    <div className="sa-root">
      <style>{css}</style>
      <div className="sa-header"><h2>Sinister Apps</h2></div>
      <div className="sa-tabs">
        <button className={`sa-tab ${tab === 'banking' ? 'active' : ''}`} onClick={() => setTab('banking')}>Banking</button>
        <button className={`sa-tab ${tab === 'browser' ? 'active' : ''}`} onClick={() => setTab('browser')}>Browser</button>
        <button className={`sa-tab ${tab === 'syntok' ? 'active' : ''}`} onClick={() => setTab('syntok')}>syntok</button>
      </div>
      <div className="sa-content">
        {tab === 'banking' && <BankingTab />}
        {tab === 'browser' && <BrowserTab />}
        {tab === 'syntok' && <SyntokTab />}
      </div>
    </div>
  );
}

// ------- Banking Tab -------
function BankingTab() {
  const [bizList, setBizList] = useState<Business[]>([]);
  const [selectedIdx, setSelectedIdx] = useState(0);
  const [subtab, setSubtab] = useState('recent');
  const [data, setData] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    loadBusinesses();
  }, []);

  async function loadBusinesses() {
    setLoading(true);
    const result = await proxyRequest('banking', { action: 'loadBusinesses', citizenid: '' });
    if (result._error) { setError(result._error); setLoading(false); return; }
    const list = Array.isArray(result) ? result : [];
    setBizList(list);
    setLoading(false);
    if (list.length > 0) loadSubData(list[0], 'recent');
  }

  async function loadSubData(biz: Business, s: string) {
    setSubtab(s);
    setLoading(true);
    let result;
    if (s === 'recent') result = await proxyRequest('banking', { action: 'loadTransactions', business_id: biz.id });
    else if (s === 'payroll') result = await proxyRequest('banking', { action: 'loadEmployees', business_id: biz.id });
    else result = await proxyRequest('banking', { action: 'loadPnl', business_id: biz.id });
    if (result._error) { setError(result._error); setLoading(false); return; }
    setData(Array.isArray(result) ? result : []);
    setLoading(false);
  }

  if (error) return <div className="sa-empty">Error: {error}</div>;
  if (loading && bizList.length === 0) return <div className="sa-loading">Loading businesses...</div>;
  if (bizList.length === 0) return <div className="sa-empty">No active businesses.<br/>Buy one at City Hall!</div>;

  const biz = bizList[selectedIdx] || bizList[0];

  return (
    <div>
      <select className="sa-select" value={selectedIdx} onChange={e => {
        const idx = Number(e.target.value);
        setSelectedIdx(idx);
        loadSubData(bizList[idx], subtab);
      }}>
        {bizList.map((b, i) => <option key={i} value={i}>{b.name}</option>)}
      </select>
      <div className="sa-card">
        <div className="sa-card-header">{biz.name}</div>
        <div className="sa-balance">${(biz.bank_account || 0).toLocaleString()}</div>
        <div className="sa-sub">Revenue: ${(biz.revenue || 0).toLocaleString()}</div>
      </div>
      <div className="sa-tab-row">
        <button className={`sa-tab-btn ${subtab === 'recent' ? 'active' : ''}`} onClick={() => loadSubData(biz, 'recent')}>Recent</button>
        <button className={`sa-tab-btn ${subtab === 'payroll' ? 'active' : ''}`} onClick={() => loadSubData(biz, 'payroll')}>Payroll</button>
        <button className={`sa-tab-btn ${subtab === 'pnl' ? 'active' : ''}`} onClick={() => loadSubData(biz, 'pnl')}>P&L</button>
      </div>
      {loading && <div className="sa-loading">Loading...</div>}
      {!loading && subtab === 'recent' && <TxList txs={data as TxRow[]} />}
      {!loading && subtab === 'payroll' && <EmployeeList emps={data as Employee[]} />}
      {!loading && subtab === 'pnl' && <PnlList pnls={data as PnlRow[]} />}
    </div>
  );
}

function TxList({ txs }: { txs: TxRow[] }) {
  if (!txs.length) return <div className="sa-empty">No transactions yet</div>;
  return <>{txs.map((tx, i) => {
    const amt = tx.amount || 0;
    const cls = amt >= 0 ? 'pos' : 'neg';
    const sign = amt >= 0 ? '+' : '';
    return <div key={i} className="sa-tx-row"><span className="sa-tx-label">{tx.reason || 'Transaction'}</span><span className={`sa-tx-amount ${cls}`}>{sign}${Math.abs(amt).toLocaleString()}</span></div>;
  })}</>;
}

function EmployeeList({ emps }: { emps: Employee[] }) {
  if (!emps.length) return <div className="sa-empty">No employees</div>;
  return <>{emps.map((e, i) => <div key={i} className="sa-tx-row"><span className="sa-tx-label">{e.is_ai ? '[AI] ' : ''}{e.citizenid || 'Unknown'}</span><span className="sa-tx-amount">${(e.hourly_wage || e.salary || 0).toLocaleString()}/hr</span></div>)}</>;
}

function PnlList({ pnls }: { pnls: PnlRow[] }) {
  if (!pnls.length) return <div className="sa-empty">No P&L reports yet. Generated weekly.</div>;
  return <>{pnls.map((p, i) => {
    const rev = p.gross_income || p.revenue || 0;
    const exp = p.expenses || 0;
    const net = p.net_profit || (rev - exp);
    return <div key={i} className="sa-card">
      <div className="sa-card-header">Week of {(p.week_start || p.created_at || '').substring(0, 10)}</div>
      <div className="sa-pnl-row"><span>Revenue</span><span>${rev.toLocaleString()}</span></div>
      <div className="sa-pnl-row"><span>Expenses</span><span style={{color:'#e53935'}}>${exp.toLocaleString()}</span></div>
      <div className={`sa-pnl-row sa-pnl-divider`}><span>Net Profit</span><span style={{color: net >= 0 ? '#4CAF50' : '#e53935'}}>${net.toLocaleString()}</span></div>
    </div>;
  })}</>;
}

// ------- Browser Tab -------
function BrowserTab() {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<Service[]>(SERVICES);

  function search(q: string) {
    setQuery(q);
    if (!q) { setResults(SERVICES); return; }
    const ql = q.toLowerCase();
    setResults(SERVICES.filter(s => s.name.toLowerCase().includes(ql) || s.desc.toLowerCase().includes(ql) || s.hint.toLowerCase().includes(ql)));
  }

  function setGPS(x: number, y: number) {
    nuiFetch('setGPS', { x, y });
  }

  return (
    <div>
      <div className="sa-search">
        <input placeholder="Search Sinister State..." value={query} onChange={e => search(e.target.value)} />
        <button onClick={() => search(query)}>Go</button>
      </div>
      {results.map((s, i) => (
        <div key={i} className="sa-result" onClick={() => setGPS(s.x, s.y)}>
          <b>{s.name}</b><br/>
          {s.desc}
          <span className="sa-gps">GPS: {s.hint}</span>
        </div>
      ))}
    </div>
  );
}

// ------- Syntok Tab -------
function SyntokTab() {
  const [entries, setEntries] = useState<Chronicle[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadChronicles();
  }, []);

  async function loadChronicles() {
    const result = await proxyRequest('syntok', { action: 'loadChronicles' });
    if (result._error) { setLoading(false); return; }
    setEntries(Array.isArray(result) ? result : []);
    setLoading(false);
  }

  if (loading) return <div className="sa-loading">Loading chronicles...</div>;
  if (!entries.length) return <div className="sa-empty">No chronicles yet.<br/>Events will appear as they happen.</div>;

  return (
    <div>
      {entries.map((c, i) => (
        <div key={i} className="sa-card">
          <div className="sa-card-header">Score: {c.score || '?'}/30 — {c.title || 'Untitled'}</div>
          <div className="sa-sub">{(c.description || '').substring(0, 200)}</div>
        </div>
      ))}
      <div className="sa-card">
        <div className="sa-card-header">Submit your clips</div>
        <div className="sa-sub">Press F12 to screenshot in-game</div>
      </div>
    </div>
  );
}
