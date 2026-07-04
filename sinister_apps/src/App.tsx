import React, { useState, useEffect, useCallback } from "react";

const RESOURCE = "sinister_apps";

async function nuiFetch(event: string, data: any = {}): Promise<any> {
  try {
    const resp = await fetch(`https://cfx-nui-${RESOURCE}/${event}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(data),
    });
    return await resp.json();
  } catch {
    return { _error: "Failed to reach server" };
  }
}

function proxy(app: string, payload: any) {
  return nuiFetch("sinister_proxy", { id: Date.now(), app, payload });
}

const TABS = ["banking", "browser", "syntok"];

const styles: Record<string, React.CSSProperties> = {
  root: {
    height: "100%",
    display: "flex",
    flexDirection: "column",
    background: "#0a0a0f",
    color: "#e0e0e8",
    fontFamily: "'Segoe UI',sans-serif",
    fontSize: 13,
  },
  header: {
    display: "flex",
    alignItems: "center",
    padding: "10px 14px",
    background: "#0d0d16",
    borderBottom: "1px solid #1a1a28",
    flexShrink: 0,
  },
  headerTitle: { color: "#BF5700", fontWeight: 700, fontSize: 15, flex: 1 },
  tabs: {
    display: "flex",
    background: "#0d0d16",
    borderBottom: "1px solid #1a1a28",
    flexShrink: 0,
  },
  tab: (active: boolean) => ({
    flex: 1,
    padding: "12px 4px",
    textAlign: "center" as const,
    cursor: "pointer",
    color: active ? "#BF5700" : "#6a6a7a",
    fontSize: 12,
    fontWeight: 600,
    background: "transparent",
    border: "none",
    borderBottom: active ? "2px solid #BF5700" : "2px solid transparent",
  }),
  content: {
    flex: 1,
    overflowY: "auto" as const,
    padding: 10,
  },
  card: {
    background: "#151520",
    border: "1px solid #1e1e2e",
    borderRadius: 10,
    padding: "12px 14px",
    marginBottom: 8,
  },
  cardHeader: { color: "#BF5700", fontWeight: 700, fontSize: 13, marginBottom: 6 },
  bigNum: { fontSize: 22, fontWeight: 700, color: "#F5EBE0" },
  subText: { fontSize: 11, color: "#8a8a94", marginTop: 2 },
  select: {
    width: "100%",
    background: "#151520",
    color: "#e0e0e8",
    border: "1px solid #2a2a3a",
    padding: "10px 12px",
    borderRadius: 8,
    fontSize: 13,
    marginBottom: 8,
  },
  subTabs: {
    display: "flex",
    gap: 3,
    marginBottom: 8,
    background: "#0d0d16",
    borderRadius: 6,
    padding: 3,
  },
  subTab: (active: boolean) => ({
    flex: 1,
    padding: "8px 4px",
    background: active ? "#1a1020" : "transparent",
    border: "none",
    color: active ? "#BF5700" : "#6a6a7a",
    fontSize: 11,
    fontWeight: 600,
    cursor: "pointer",
    borderRadius: 4,
  }),
  txRow: {
    display: "flex",
    justifyContent: "space-between",
    padding: "9px 0",
    borderBottom: "1px solid #12121c",
    fontSize: 12,
  },
  txGreen: { color: "#4CAF50", fontWeight: 600 },
  txRed: { color: "#e53935", fontWeight: 600 },
  searchBar: { display: "flex", gap: 6, marginBottom: 8 },
  searchInput: {
    flex: 1,
    background: "#151520",
    color: "#e0e0e8",
    border: "1px solid #2a2a3a",
    padding: "10px 12px",
    borderRadius: 8,
    fontSize: 13,
  },
  searchBtn: {
    background: "#BF5700",
    color: "white",
    border: "none",
    padding: "10px 16px",
    borderRadius: 8,
    fontWeight: 600,
    cursor: "pointer",
    fontSize: 13,
  },
  result: {
    padding: "12px 14px",
    cursor: "pointer",
    borderBottom: "1px solid #12121c",
    fontSize: 13,
  },
  gps: { color: "#5a5a6a", fontSize: 10, display: "block", marginTop: 2 },
  empty: { color: "#6a6a7a", textAlign: "center" as const, padding: "30px 15px", fontSize: 12 },
  loading: { color: "#8a8a94", textAlign: "center" as const, padding: 20, fontSize: 12 },
  pnlRow: { display: "flex", justifyContent: "space-between", margin: "2px 0", fontSize: 11, color: "#b0b0bc" },
};

const SERVICES = [
  { n: "City Hall", d: "Get ID, licenses, apply for jobs", h: "Downtown Houston", x: -540.58, y: -212.02 },
  { n: "Mosley's Auto & Chop Shop", d: "Vehicle repair, mods, chop shop", h: "Davis Ave", x: 540, y: -200 },
  { n: "Lone Star Grill", d: "Texas burgers, open 24/7", h: "Mission Row", x: 440, y: -980 },
  { n: "Bucky's Stop & Shop", d: "Gas, snacks, Texas-sized", h: "Route 68", x: 640.66, y: 276.22 },
  { n: "Travis County Courthouse", d: "Legal services, marriage licenses", h: "Downtown", x: 243.5, y: -1086 },
  { n: "Houston Intl Airport", d: "Flights, ATC, airfield ownership", h: "LSIA", x: -1050, y: -2800 },
  { n: "Fort Zancudo", d: "Texas National Guard — Restricted", h: "Fort Zancudo", x: -2200, y: 3250 },
];

export default function App() {
  const [tab, setTab] = useState(0);

  return (
    <div style={styles.root}>
      <div style={styles.header}>
        <span style={styles.headerTitle}>Sinister Apps</span>
      </div>
      <div style={styles.tabs}>
        {["Banking", "Browser", "syntok", "CAD"].map((label, i) => (
          <button key={i} style={styles.tab(tab === i)} onClick={() => setTab(i)}>
            {label}
          </button>
        ))}
      </div>
      <div style={styles.content}>
        {tab === 0 && <Banking />}
        {tab === 1 && <Browser />}
        {tab === 2 && <Syntok />}
        {tab === 3 && <Cad />}
      </div>
    </div>
  );
}

// ---- Banking ----
function Banking() {
  const [biz, setBiz] = useState<any[]>([]);
  const [idx, setIdx] = useState(0);
  const [sub, setSub] = useState("recent");
  const [data, setData] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setLoading(true);
    const r = await proxy("banking", { action: "loadBusinesses", citizenid: "" });
    setBiz(Array.isArray(r) ? r : []);
    setLoading(false);
  }, []);

  useEffect(() => { load(); }, [load]);

  const loadSub = useCallback(async (s: string) => {
    setSub(s);
    const b = biz[idx]; if (!b) return;
    let r;
    if (s === "recent") r = await proxy("banking", { action: "loadTransactions", business_id: b.id });
    else if (s === "payroll") r = await proxy("banking", { action: "loadEmployees", business_id: b.id });
    else r = await proxy("banking", { action: "loadPnl", business_id: b.id });
    setData(Array.isArray(r) ? r : []);
  }, [biz, idx]);

  useEffect(() => { if (biz.length) loadSub(sub); }, [biz, idx]);

  if (loading) return <div style={styles.loading}>Loading...</div>;
  if (!biz.length) return <div style={styles.empty}>No active businesses.<br/>Buy one at City Hall!</div>;

  const b = biz[idx];
  return (
    <div>
      <select style={styles.select} value={idx} onChange={e => setIdx(Number(e.target.value))}>
        {biz.map((x: any, i: number) => <option key={i} value={i}>{x.name}</option>)}
      </select>
      <div style={styles.card}>
        <div style={styles.cardHeader}>{b.name}</div>
        <div style={styles.bigNum}>${(b.bank_account || 0).toLocaleString()}</div>
        <div style={styles.subText}>Revenue: ${(b.revenue || 0).toLocaleString()}</div>
      </div>
      <div style={styles.subTabs}>
        {["recent","payroll","pnl"].map(s => (
          <button key={s} style={styles.subTab(sub === s)} onClick={() => loadSub(s)}>
            {s === "recent" ? "Recent" : s === "payroll" ? "Payroll" : "P&L"}
          </button>
        ))}
      </div>
      {sub === "recent" && data.map((tx: any, i: number) => {
        const amt = tx.amount || 0;
        const cls = amt >= 0 ? styles.txGreen : styles.txRed;
        return <div key={i} style={styles.txRow}><span>{tx.reason || "Tx"}</span><span style={cls}>{(amt>=0?"+":"")}${Math.abs(amt).toLocaleString()}</span></div>;
      })}
      {sub === "payroll" && data.map((e: any, i: number) => (
        <div key={i} style={styles.txRow}><span>{e.is_ai?"[AI] ":""}{e.citizenid||"Unknown"}</span><span>${(e.hourly_wage||e.salary||0).toLocaleString()}/hr</span></div>
      ))}
      {sub === "pnl" && data.map((p: any, i: number) => {
        const rev = p.gross_income || p.revenue || 0;
        const exp = p.expenses || 0;
        const net = p.net_profit !== undefined ? p.net_profit : (rev - exp);
        return <div key={i} style={styles.card}>
          <div style={styles.cardHeader}>Week of {(p.week_start||p.created_at||"").substring(0,10)}</div>
          <div style={styles.pnlRow}><span>Revenue</span><span>${rev.toLocaleString()}</span></div>
          <div style={styles.pnlRow}><span style={{color:"#e53935"}}>Expenses</span><span style={{color:"#e53935"}}>${exp.toLocaleString()}</span></div>
          <div style={{...styles.pnlRow, borderTop:"1px solid #1e1e2e", marginTop:4, paddingTop:4, fontWeight:700}}><span>Net</span><span style={{color:net>=0?"#4CAF50":"#e53935"}}>${net.toLocaleString()}</span></div>
        </div>;
      })}
    </div>
  );
}

// ---- Browser ----
function Browser() {
  const [q, setQ] = useState("");
  const filtered = q ? SERVICES.filter(s => s.n.toLowerCase().includes(q.toLowerCase()) || s.d.toLowerCase().includes(q.toLowerCase()) || s.h.toLowerCase().includes(q.toLowerCase())) : SERVICES;

  return (
    <div>
      <div style={styles.searchBar}>
        <input style={styles.searchInput} placeholder="Search Sinister State..." value={q} onChange={e => setQ(e.target.value)} />
        <button style={styles.searchBtn} onClick={() => {}}>Go</button>
      </div>
      {filtered.map((s, i) => (
        <div key={i} style={styles.result} onClick={() => nuiFetch("setGPS", { x: s.x, y: s.y })}>
          <b style={{color:"#BF5700"}}>{s.n}</b><br/>{s.d}<span style={styles.gps}>GPS: {s.h}</span>
        </div>
      ))}
    </div>
  );
}

// ---- Syntok ----
function Syntok() {
  const [entries, setEntries] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    (async () => {
      const r = await proxy("syntok", { action: "loadChronicles" });
      setEntries(Array.isArray(r) ? r : []);
      setLoading(false);
    })();
  }, []);

  if (loading) return <div style={styles.loading}>Loading chronicles...</div>;
  if (!entries.length) return <div style={styles.empty}>No chronicles yet.<br/>Events will appear here.</div>;

  return (
    <div>
      {entries.map((c: any, i: number) => (
        <div key={i} style={styles.card}>
          <div style={styles.cardHeader}>Score: {c.score||"?"}/30 — {c.title||"Untitled"}</div>
          <div style={styles.subText}>{(c.description||"").substring(0, 250)}</div>
        </div>
      ))}
      <div style={styles.card}>
        <div style={styles.cardHeader}>Submit your clips</div>
        <div style={styles.subText}>Press F12 to screenshot. Featured clips earn rewards!</div>
      </div>
    </div>
  );
}

// ---- CAD (Police) ----
function Cad() {
  const [cadTab, setCadTab] = useState("scanner");
  const C = cadTab;

  return (
    <div>
      <div style={styles.subTabs}>
        {["scanner","radar","reports"].map(t => (
          <button key={t} style={styles.subTab(C === t)} onClick={() => setCadTab(t)}>
            {t === "scanner" ? "🔍 Scanner" : t === "radar" ? "📡 Radar" : "📋 Reports"}
          </button>
        ))}
      </div>
      {C === "scanner" && <PlateScanner />}
      {C === "radar" && <SpeedRadar />}
      {C === "reports" && <MdtReports />}
    </div>
  );
}

// -- Plate Scanner --
function PlateScanner() {
  const [scanResult, setScanResult] = useState<any>(null);
  const [lookup, setLookup] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [manualPlate, setManualPlate] = useState("");

  async function doScan() {
    setLoading(true);
    setLookup(null);
    const scan = await nuiFetch("cad:scanPlate", {});
    setScanResult(scan);
    if (scan.plate) {
      const r = await proxy("cad", { action: "plateLookup", plate: scan.plate });
      setLookup(r);
    }
    setLoading(false);
  }

  async function doManualLookup() {
    if (!manualPlate) return;
    setLoading(true);
    setScanResult({ plate: manualPlate });
    const r = await proxy("cad", { action: "plateLookup", plate: manualPlate });
    setLookup(r);
    setLoading(false);
  }

  return (
    <div>
      <button style={styles.searchBtn} onClick={doScan} disabled={loading}>Scan Nearby Vehicle</button>
      <div style={{display:"flex",gap:6,marginTop:8}}>
        <input style={styles.searchInput} placeholder="Or type plate..." value={manualPlate} onChange={e => setManualPlate(e.target.value)} />
        <button style={styles.searchBtn} onClick={doManualLookup}>Lookup</button>
      </div>

      {loading && <div style={styles.loading}>Scanning...</div>}

      {scanResult && !scanResult.error && (
        <div style={{...styles.card, marginTop:8}}>
          <div style={styles.cardHeader}>Scanned Vehicle</div>
          <div><b>Plate:</b> {scanResult.plate}</div>
          <div><b>Model:</b> {scanResult.model || "Unknown"}</div>
          <div><b>Speed:</b> {scanResult.speed} km/h</div>
        </div>
      )}

      {scanResult?.error && <div style={{...styles.card, marginTop:8, color:"#e53935"}}>{scanResult.error}</div>}

      {lookup && lookup.registry && lookup.registry.plate && (
        <div style={{...styles.card, marginTop:8, borderColor:"#BF5700"}}>
          <div style={styles.cardHeader}>Registry Info</div>
          <div><b>Owner:</b> {lookup.registry.owner_name || "Unknown"}</div>
          <div><b>CID:</b> {lookup.registry.owner_citizenid || "N/A"}</div>
          <div><b>Status:</b> {lookup.registry.stolen ? "🚨 STOLEN" : lookup.registry.flagged ? "⚠️ Flagged: " + (lookup.registry.flag_reason||"") : "✅ Clean"}</div>
        </div>
      )}

      {lookup && lookup.warrants && lookup.warrants.length > 0 && (
        <div style={{...styles.card, marginTop:8, borderColor:"#e53935"}}>
          <div style={{...styles.cardHeader, color:"#e53935"}}>🚨 Active Warrants ({lookup.warrants.length})</div>
          {lookup.warrants.map((w: any, i: number) => (
            <div key={i} style={{fontSize:11,marginBottom:4}}>
              <b>{w.reason}</b> — Issued: {w.issued_at?.substring(0,10)} — Expires: {w.expires_at?.substring(0,10)}
            </div>
          ))}
        </div>
      )}

      {lookup && lookup.records && lookup.records.length > 0 && (
        <div style={{...styles.card, marginTop:8}}>
          <div style={styles.cardHeader}>Criminal History ({lookup.records.length})</div>
          {lookup.records.slice(0, 5).map((r: any, i: number) => (
            <div key={i} style={{fontSize:11,marginBottom:4,borderBottom:"1px solid #12121c",paddingBottom:4}}>
              <b>{r.charge}</b> — {r.severity} — {r.convicted ? "Convicted" : "Pending"} — ${r.fine_amount || 0}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

// -- Speed Radar --
function SpeedRadar() {
  const [radar, setRadar] = useState<any>(null);
  const [loading, setLoading] = useState(false);

  async function checkSpeed() {
    setLoading(true);
    const r = await nuiFetch("cad:getSpeed", {});
    setRadar(r);
    if (r.speed && r.plate) {
      await proxy("cad", { action: "speedLog", plate: r.plate, speed: r.speed, limit_speed: r.limit, location: r.location, officer_citizenid: "" });
    }
    setLoading(false);
  }

  return (
    <div>
      <button style={styles.searchBtn} onClick={checkSpeed} disabled={loading}>Check Speed</button>

      {radar && !radar.error && (
        <div style={{...styles.card, marginTop:8, borderColor: radar.over ? "#e53935" : "#4CAF50"}}>
          <div style={styles.cardHeader}>Speed Reading</div>
          <div style={{...styles.bigNum, color: radar.over ? "#e53935" : "#4CAF50"}}>{radar.speed} km/h</div>
          <div style={styles.subText}>Limit: {radar.limit} km/h — {radar.over ? "OVER LIMIT" : "Within limit"}</div>
          <div style={styles.subText}>Plate: {radar.plate} — {radar.location}</div>
        </div>
      )}

      {radar?.error && <div style={{...styles.card, marginTop:8, color:"#e53935"}}>{radar.error}</div>}
    </div>
  );
}

// -- MDT Reports --
function MdtReports() {
  const [reports, setReports] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ title: "", description: "", priority: "Normal", suspect_citizenid: "" });

  useEffect(() => { load(); }, []);

  async function load() {
    setLoading(true);
    const r = await proxy("cad", { action: "loadMDT" });
    setReports(Array.isArray(r) ? r : []);
    setLoading(false);
  }

  async function submitReport() {
    await proxy("cad", { action: "createReport", report: { ...form, reporter_citizenid: "", status: "Open" } });
    setShowForm(false);
    setForm({ title: "", description: "", priority: "Normal", suspect_citizenid: "" });
    load();
  }

  if (loading) return <div style={styles.loading}>Loading reports...</div>;

  return (
    <div>
      <button style={{...styles.searchBtn, marginBottom: 8}} onClick={() => setShowForm(!showForm)}>
        {showForm ? "Cancel" : "+ New Report"}
      </button>

      {showForm && (
        <div style={{...styles.card, marginBottom:8}}>
          <input style={{...styles.searchInput, marginBottom:6}} placeholder="Title" value={form.title} onChange={e => setForm({...form, title: e.target.value})} />
          <input style={{...styles.searchInput, marginBottom:6}} placeholder="Suspect CID (optional)" value={form.suspect_citizenid} onChange={e => setForm({...form, suspect_citizenid: e.target.value})} />
          <select style={styles.select} value={form.priority} onChange={e => setForm({...form, priority: e.target.value})}>
            <option>Low</option><option>Normal</option><option>High</option><option>Critical</option>
          </select>
          <textarea style={{...styles.searchInput, height:80, resize:"vertical", marginBottom:6}} placeholder="Description..." value={form.description} onChange={e => setForm({...form, description: e.target.value})} />
          <button style={styles.searchBtn} onClick={submitReport}>Submit Report</button>
        </div>
      )}

      {!reports.length && <div style={styles.empty}>No reports yet.</div>}
      {reports.map((r: any, i: number) => (
        <div key={i} style={styles.card}>
          <div style={styles.cardHeader}>{r.title} <span style={{color: r.priority === "Critical" ? "#e53935" : r.priority === "High" ? "#FF9800" : "#8a8a94", fontSize: 10}}>{r.priority}</span></div>
          <div style={styles.subText}>{r.description?.substring(0, 120)}</div>
          <div style={{...styles.pnlRow, marginTop:4}}><span>Status: {r.status}</span><span>{r.created_at?.substring(0,10)}</span></div>
        </div>
      ))}
    </div>
  );
}
