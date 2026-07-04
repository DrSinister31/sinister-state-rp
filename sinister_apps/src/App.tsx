import React, { useState, useEffect, useCallback } from "react";

const RESOURCE = "sinister_apps";

async function nuiFetch(event: string, data: any = {}): Promise<any> {
  try {
    const resp = await fetch(`https://cfx-nui-${RESOURCE}/${event}`, {
      method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(data),
    });
    return await resp.json();
  } catch { return { _error: "Failed" }; }
}
function proxy(app: string, payload: any) { return nuiFetch("sinister_proxy", { id: Date.now(), app, payload }); }

const SVC = [
  { n: "City Hall", d: "Get ID, licenses, apply for jobs", h: "Downtown Houston", x: -540.58, y: -212.02 },
  { n: "Mosley's Auto & Chop Shop", d: "Vehicle repair, mods, chop shop", h: "Davis Ave", x: 540, y: -200 },
  { n: "Lone Star Grill", d: "Texas burgers, open 24/7", h: "Mission Row", x: 440, y: -980 },
  { n: "Bucky's Stop & Shop", d: "Gas, snacks, Texas-sized", h: "Route 68", x: 640.66, y: 276.22 },
  { n: "Travis County Courthouse", d: "Legal services, marriage licenses", h: "Downtown", x: 243.5, y: -1086 },
  { n: "Houston Intl Airport", d: "Flights, ATC, airfield ownership", h: "LSIA", x: -1050, y: -2800 },
  { n: "Fort Zancudo", d: "Texas National Guard", h: "Fort Zancudo", x: -2200, y: 3250 },
];

const s = {
  root: { height:"100%", width:"100%", display:"flex", flexDirection:"column" as const, background:"#0d0d16", color:"#d0d0d8", fontFamily:"'Segoe UI',sans-serif", fontSize:11, overflow:"hidden" },
  tabs: { display:"flex", background:"#08080f", borderBottom:"1px solid #1a1a28", flexShrink:0 },
  tab: (a:boolean) => ({ flex:1, padding:"8px 2px", textAlign:"center" as const, cursor:"pointer", color:a?"#BF5700":"#5a5a6a", border:"none", background:"transparent", borderBottom:a?"2px solid #BF5700":"2px solid transparent", fontSize:11, fontWeight:700 }),
  body: { flex:1, overflowY:"auto" as const, padding:8, overflowX:"hidden" as const },
  card: { background:"#151520", borderRadius:8, padding:"10px 12px", marginBottom:6, border:"1px solid #1e1e2e", wordBreak:"break-word" as const },
  hdr: { color:"#BF5700", fontWeight:700, fontSize:13, marginBottom:4 },
  big: { fontSize:20, fontWeight:700, color:"#F5EBE0" },
  sub: { fontSize:10, color:"#8a8a94", marginTop:2 },
  sel: { width:"100%", background:"#0d0d16", color:"#d0d0d8", border:"1px solid #2a2a3a", padding:"6px 8px", borderRadius:6, fontSize:12, marginBottom:8 },
  subtabs: { display:"flex", gap:2, marginBottom:8, background:"#0d0d16", borderRadius:4, padding:2 },
  stab: (a:boolean) => ({ flex:1, padding:"6px 2px", border:"none", background:a?"#1a1020":"transparent", color:a?"#BF5700":"#5a5a6a", fontSize:10, fontWeight:700, cursor:"pointer", borderRadius:4, textAlign:"center" as const }),
  row: { display:"flex", justifyContent:"space-between", padding:"6px 0", borderBottom:"1px solid #12121c", fontSize:11, overflow:"hidden" as const },
  green: { color:"#4CAF50", fontWeight:600 },
  red: { color:"#e53935", fontWeight:600 },
  srch: { display:"flex", gap:4, marginBottom:8 },
  inp: { flex:1, background:"#151520", color:"#d0d0d8", border:"1px solid #2a2a3a", padding:"7px 10px", borderRadius:6, fontSize:12 },
  btn: { background:"#BF5700", color:"white", border:"none", padding:"7px 14px", borderRadius:6, fontWeight:700, cursor:"pointer", fontSize:12, flexShrink:0 },
  res: { padding:"10px 12px", cursor:"pointer", borderBottom:"1px solid #12121c" },
  gps: { color:"#5a5a6a", fontSize:9, display:"block", marginTop:2 },
  empty: { color:"#5a5a6a", textAlign:"center" as const, padding:"20px 8px", fontSize:11 },
  pnl: { display:"flex", justifyContent:"space-between", fontSize:10, color:"#b0b0bc" },
};

// ---- MAIN ----
export default function App() {
  const [tab, setTab] = useState(0);
  const labels = ["Banking", "Browser"];
  return (
    <div style={s.root}>
      <div style={s.tabs}>
        {labels.map((l,i) => <button key={i} style={s.tab(tab===i)} onClick={()=>setTab(i)}>{l}</button>)}
      </div>
      <div style={s.body}>{tab===0?<Banking/>:tab===1?<Browser/>:<Syntok/>}</div>
    </div>
  );
}

// ---- BANKING ----
function Banking() {
  const [biz,setBiz]=useState<any[]>([]); const [idx,setIdx]=useState(0);
  const [sub,setSub]=useState("recent"); const [data,setData]=useState<any[]>([]);
  const [ld,setLd]=useState(true);
  useEffect(()=>{proxy("banking",{action:"loadBusinesses",citizenid:""}).then(r=>{setBiz(Array.isArray(r)?r:[]);setLd(false)});},[]);
  const loadSub=useCallback(async(s:string)=>{setSub(s);const b=biz[idx];if(!b)return;let r;if(s==="recent")r=await proxy("banking",{action:"loadTransactions",business_id:b.id});else if(s==="payroll")r=await proxy("banking",{action:"loadEmployees",business_id:b.id});else r=await proxy("banking",{action:"loadPnl",business_id:b.id});setData(Array.isArray(r)?r:[]);},[biz,idx]);
  useEffect(()=>{if(biz.length)loadSub(sub);},[biz,idx]);
  if(ld)return <div style={s.empty}>Loading...</div>;
  if(!biz.length)return <div style={s.empty}>No businesses.<br/>Buy one at City Hall.</div>;
  const b=biz[idx];
  return <div>
    <select style={s.sel} value={idx} onChange={e=>setIdx(Number(e.target.value))}>{biz.map((x,i)=><option key={i} value={i}>{x.name}</option>)}</select>
    <div style={s.card}><div style={s.hdr}>{b.name}</div><div style={s.big}>${(b.bank_account||0).toLocaleString()}</div><div style={s.sub}>Revenue: ${(b.revenue||0).toLocaleString()}</div></div>
    <div style={s.subtabs}>{["recent","payroll","pnl"].map(t=><button key={t} style={s.stab(sub===t)} onClick={()=>loadSub(t)}>{t==="recent"?"Recent":t==="payroll"?"Payroll":"P&L"}</button>)}</div>
    {sub==="recent"&&data.map((tx,i)=>{const amt=tx.amount||0;return <div key={i} style={s.row}><span style={{overflow:"hidden",textOverflow:"ellipsis",whiteSpace:"nowrap",flex:1,marginRight:4}}>{tx.reason||"Tx"}</span><span style={amt>=0?s.green:s.red}>{(amt>=0?"+":"")}${Math.abs(amt).toLocaleString()}</span></div>;})}
    {sub==="payroll"&&data.map((e,i)=><div key={i} style={s.row}><span>{e.is_ai?"[AI] ":""}{e.citizenid||"?"}</span><span style={{fontWeight:600}}>${(e.hourly_wage||e.salary||0).toLocaleString()}/hr</span></div>)}
    {sub==="pnl"&&data.map((p,i)=>{const rev=p.gross_income||p.revenue||0;const exp=p.expenses||0;const net=p.net_profit!==undefined?p.net_profit:rev-exp;return <div key={i} style={s.card}><div style={s.hdr}>Week of {(p.week_start||p.created_at||"").substring(0,10)}</div><div style={s.pnl}><span>Revenue</span><span>${rev.toLocaleString()}</span></div><div style={{...s.pnl,color:"#e53935"}}><span>Expenses</span><span>${exp.toLocaleString()}</span></div><div style={{...s.pnl,fontWeight:700,borderTop:"1px solid #1e1e2e",marginTop:4,paddingTop:4}}><span>Net</span><span style={{color:net>=0?"#4CAF50":"#e53935"}}>${net.toLocaleString()}</span></div></div>;})}
  </div>;
}

// ---- BROWSER ----
function Browser() {
  const [q,setQ]=useState(""); const f=q?SVC.filter(s=>s.n.toLowerCase().includes(q.toLowerCase())||s.d.toLowerCase().includes(q.toLowerCase())||s.h.toLowerCase().includes(q.toLowerCase())):SVC;
  return <div>
    <div style={s.srch}><input style={s.inp} placeholder="Search..." value={q} onChange={e=>setQ(e.target.value)}/><button style={s.btn}>Go</button></div>
    {f.map((sv,i)=><div key={i} style={s.res} onClick={()=>nuiFetch("setGPS",{x:sv.x,y:sv.y})}><div style={{color:"#BF5700",fontWeight:700,fontSize:12}}>{sv.n}</div><div style={{fontSize:10,color:"#b0b0bc"}}>{sv.d}</div><div style={s.gps}>GPS: {sv.h}</div></div>)}
  </div>;
}

// ---- SYNTOK ----
function Syntok() {
  const [entries,setEntries]=useState<any[]>([]); const [ld,setLd]=useState(true);
  useEffect(()=>{proxy("syntok",{action:"loadChronicles"}).then(r=>{setEntries(Array.isArray(r)?r:[]);setLd(false)});},[]);
  if(ld)return <div style={s.empty}>Loading chronicles...</div>;
  if(!entries.length)return <div style={s.empty}>No chronicles yet.<br/>Events appear here.</div>;
  return <div>{entries.map((c,i)=><div key={i} style={s.card}><div style={s.hdr}>Score: {c.score||"?"}/30 — {c.title||"Untitled"}</div><div style={{...s.sub,fontSize:10}}>{(c.description||"").substring(0,200)}</div></div>)}<div style={s.card}><div style={s.hdr}>Submit clips</div><div style={{...s.sub,fontSize:10}}>F12 to screenshot. Earn rewards!</div></div></div>;
}
