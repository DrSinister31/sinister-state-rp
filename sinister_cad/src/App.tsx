import React, { useState, useEffect } from "react";

const RESOURCE = "sinister_cad";
const LEO_JOBS = ["police","bcso","sasp","fib","military","judge","prosecutor","publicdefender","bailiff"];

async function nuiFetch(event: string, data: any = {}): Promise<any> {
  try {
    const resp = await fetch(`https://cfx-nui-${RESOURCE}/${event}`, {
      method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(data),
    });
    return await resp.json();
  } catch { return { _error: "Failed" }; }
}
function proxy(payload: any) { return nuiFetch("cad_proxy", { id: Date.now(), payload }); }

const s = {
  root: { height:"100%", width:"100%", display:"flex", flexDirection:"column" as const, background:"#0d1117", color:"#c9d1d9", fontFamily:"'Segoe UI',sans-serif", fontSize:11, overflow:"hidden" },
  tabs: { display:"flex", background:"#08080f", borderBottom:"1px solid #1a1a28", flexShrink:0 },
  tab: (a:boolean) => ({ flex:1, padding:"8px 2px", textAlign:"center" as const, cursor:"pointer", color:a?"#1565C0":"#484f58", border:"none", background:"transparent", borderBottom:a?"2px solid #1565C0":"2px solid transparent", fontSize:11, fontWeight:700 }),
  body: { flex:1, overflowY:"auto" as const, padding:8, overflowX:"hidden" as const },
  card: { background:"#161b22", borderRadius:8, padding:"10px 12px", marginBottom:6, border:"1px solid #21262d", wordBreak:"break-word" as const },
  hdr: { color:"#58a6ff", fontWeight:700, fontSize:13, marginBottom:4 },
  big: { fontSize:36, fontWeight:700, textAlign:"center" as const, margin:"8px 0" },
  sub: { fontSize:10, color:"#8b949e", marginTop:2, wordBreak:"break-word" as const },
  btn: { width:"100%", background:"#1f6feb", color:"white", border:"none", padding:"10px", borderRadius:6, fontWeight:700, cursor:"pointer", fontSize:12, marginBottom:8 },
  inp: { flex:1, background:"#0d1117", color:"#c9d1d9", border:"1px solid #30363d", padding:"7px 10px", borderRadius:6, fontSize:12 },
  btnS: { background:"#21262d", color:"#c9d1d9", border:"1px solid #30363d", padding:"7px 14px", borderRadius:6, fontWeight:700, cursor:"pointer", fontSize:12, flexShrink:0 },
  flex: { display:"flex", gap:4, marginBottom:8 },
  row: { padding:"4px 0", borderBottom:"1px solid #21262d", fontSize:10, wordBreak:"break-word" as const, overflow:"hidden" as const },
  deny: { textAlign:"center" as const, padding:"30px 10px", color:"#484f58", fontSize:12 },
};

export default function App() {
  const [auth,setAuth]=useState<any>(null);
  const [tab,setTab]=useState(0);

  useEffect(()=>{nuiFetch("checkAuth").then(a=>setAuth(a));},[]);

  if(!auth) return <div style={s.root}><div style={s.body}><div style={s.deny}>Loading...</div></div></div>;
  if(!LEO_JOBS.includes(auth.job)) return <div style={s.root}><div style={s.body}><div style={s.deny}><b>ACCESS DENIED</b><br/>LEO personnel only.<br/>Your job: {auth.job||"none"}</div></div></div>;

  return (
    <div style={s.root}>
      <div style={s.tabs}>{["Scanner","Radar"].map((l,i)=><button key={i} style={s.tab(tab===i)} onClick={()=>setTab(i)}>{l}</button>)}</div>
      <div style={s.body}>{tab===0?<Scanner/>:<Radar/>}</div>
      <div style={{padding:"6px 8px",borderTop:"1px solid #21262d",textAlign:"center",fontSize:9,color:"#484f58"}}>Full MDT: /cad &bull; {auth.job||"?"}</div>
    </div>
  );
}

function Scanner() {
  const [scan,setScan]=useState<any>(null); const [lookup,setLookup]=useState<any>(null);
  const [ld,setLd]=useState(false); const [manual,setManual]=useState("");

  async function doScan() { setLd(true); setLookup(null); const sc=await nuiFetch("cad:scanPlate",{}); setScan(sc); if(sc.plate){const r=await proxy({action:"plateLookup",plate:sc.plate});setLookup(r);} setLd(false); }
  async function doManual() { if(!manual)return; setLd(true); setScan({plate:manual}); const r=await proxy({action:"plateLookup",plate:manual});setLookup(r); setLd(false); }

  return <div>
    <button style={s.btn} onClick={doScan} disabled={ld}>{ld?"Scanning...":"Scan Nearby Vehicle"}</button>
    <div style={s.flex}><input style={s.inp} placeholder="Or type plate..." value={manual} onChange={e=>setManual(e.target.value)}/><button style={s.btnS} onClick={doManual}>Lookup</button></div>
    {scan?.error&&<div style={{...s.card,color:"#f85149"}}>{scan.error}</div>}
    {scan?.plate&&<div style={s.card}><div style={s.hdr}>Vehicle</div><div style={s.sub}><b>Plate:</b> {scan.plate}</div><div style={s.sub}><b>Model:</b> {scan.model||"?"}</div></div>}
    {lookup?.registry?.plate&&<div style={{...s.card,borderColor:lookup.registry.stolen?"#f85149":lookup.registry.flagged?"#d29922":"#21262d"}}><div style={s.hdr}>Registry</div><div style={s.sub}><b>Owner:</b> {lookup.registry.owner_name||"?"}</div><div style={s.sub}><b>CID:</b> {lookup.registry.owner_citizenid||"N/A"}</div><div style={{...s.sub,color:lookup.registry.stolen?"#f85149":lookup.registry.flagged?"#d29922":"#3fb950"}}>{lookup.registry.stolen?"STOLEN":lookup.registry.flagged?`Flagged: ${lookup.registry.flag_reason}`:"Clean"}</div></div>}
    {lookup?.warrants?.length>0&&<div style={{...s.card,borderColor:"#f85149"}}><div style={{...s.hdr,color:"#f85149"}}>Warrants ({lookup.warrants.length})</div>{lookup.warrants.map((w:any,i:number)=><div key={i} style={s.row}>{w.reason} — {w.issued_at?.substring(0,10)}</div>)}</div>}
    {lookup?.records?.length>0&&<div style={s.card}><div style={s.hdr}>Records ({lookup.records.length})</div>{lookup.records.slice(0,5).map((r:any,i:number)=><div key={i} style={s.row}><b>{r.charge}</b> — {r.severity}</div>)}</div>}
  </div>;
}

function Radar() {
  const [radar,setRadar]=useState<any>(null); const [ld,setLd]=useState(false);
  async function check() { setLd(true); const r=await nuiFetch("cad:getSpeed",{}); setRadar(r); if(r.speed&&r.plate){proxy({action:"speedLog",plate:r.plate,speed:r.speed,limit_speed:r.limit,location:r.location,officer_citizenid:""});} setLd(false); }
  return <div>
    <button style={s.btn} onClick={check} disabled={ld}>{ld?"Checking...":"Check Speed"}</button>
    {radar?.error&&<div style={{...s.card,color:"#f85149"}}>{radar.error}</div>}
    {radar?.speed&&<div style={{...s.card,textAlign:"center",borderColor:radar.over?"#f85149":"#3fb950"}}><div style={{...s.big,color:radar.over?"#f85149":"#3fb950"}}>{radar.speed}</div><div style={s.sub}>KM/H</div><div style={{marginTop:8}}><div style={s.sub}><b>Limit:</b> {radar.limit} km/h</div><div style={s.sub}><b>Plate:</b> {radar.plate}</div><div style={s.sub}>{radar.location}</div></div></div>}
  </div>;
}
