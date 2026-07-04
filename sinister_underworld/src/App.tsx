import React, { useState, useEffect } from "react";

const RESOURCE = "sinister_underworld";

async function nuiFetch(event: string, data: any = {}): Promise<any> {
  try { const r = await fetch(`https://cfx-nui-${RESOURCE}/${event}`,{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify(data)}); return await r.json(); }
  catch { return { _error: "Failed" }; }
}
function proxy(payload: any) { return nuiFetch("uw_proxy", { id: Date.now(), payload }); }

const s = {
  root: { height:"100%",width:"100%",display:"flex",flexDirection:"column" as const,background:"#0a0a0a",color:"#b0a0b8",fontFamily:"'Segoe UI',sans-serif",fontSize:11,overflow:"hidden" },
  tabs: { display:"flex",background:"#0d0d0d",borderBottom:"1px solid #1a0a1a",flexShrink:0 },
  tab: (a:boolean) => ({ flex:1,padding:"8px 2px",textAlign:"center" as const,cursor:"pointer",color:a?"#a855f7":"#3a2a3a",border:"none",background:"transparent",borderBottom:a?"2px solid #a855f7":"2px solid transparent",fontSize:11,fontWeight:700 }),
  body: { flex:1,overflowY:"auto" as const,padding:8,overflowX:"hidden" as const },
  card: { background:"#120812",borderRadius:8,padding:"10px 12px",marginBottom:6,border:"1px solid #1a0a1a",wordBreak:"break-word" as const },
  hdr: { color:"#a855f7",fontWeight:700,fontSize:13,marginBottom:4 },
  big: { fontSize:20,fontWeight:700,color:"#d8b4fe",textAlign:"center" as const },
  sub: { fontSize:10,color:"#7a6a7a",marginTop:2 },
  row: { display:"flex",justifyContent:"space-between",padding:"4px 0",borderBottom:"1px solid #1a0a1a",fontSize:10,overflow:"hidden" as const },
  empty: { color:"#3a2a3a",textAlign:"center" as const,padding:"20px 8px",fontSize:11 },
};

export default function App() {
  const [tab,setTab]=useState(0);
  return (
    <div style={s.root}>
      <div style={s.tabs}>{["Rep","Contracts","Heists"].map((l,i)=><button key={i} style={s.tab(tab===i)} onClick={()=>setTab(i)}>{l}</button>)}</div>
      <div style={s.body}>{tab===0?<Rep/>:tab===1?<Contracts/>:<Heists/>}</div>
    </div>
  );
}

function Rep() {
  const [rep,setRep]=useState<any>(null); const [drug,setDrug]=useState<any>(null); const [ld,setLd]=useState(true);
  useEffect(()=>{Promise.all([proxy({action:"loadRep"}),proxy({action:"loadDrugXP"})]).then(([r,d])=>{setRep(Array.isArray(r)?r[0]:null);setDrug(Array.isArray(d)?d[0]:null);setLd(false)});},[]);
  if(ld)return<div style={s.empty}>Loading...</div>;
  if(!rep)return<div style={s.empty}>No street rep yet.<br/>Make moves to build reputation.</div>;
  return <div>
    <div style={s.card}><div style={s.hdr}>Street Reputation</div><div style={s.big}>{rep.rep_score||0}</div><div style={s.sub}>Rep Score</div><div style={s.row}><span>Territory</span><span>{rep.territory_control||0}</span></div><div style={s.row}><span>Street Cred</span><span>{rep.street_cred||0}</span></div><div style={s.row}><span>Heat Level</span><span style={{color:rep.heat_level>50?"#ef4444":"#f59e0b"}}>{rep.heat_level||0}</span></div></div>
    <div style={s.card}><div style={s.hdr}>Drug Empire</div><div style={s.row}><span>Level</span><span style={{color:"#a855f7",fontWeight:700}}>{drug?.drug_level||0}</span></div><div style={s.row}><span>Total Sales</span><span>{drug?.total_sales||0}</span></div><div style={s.row}><span>Lifetime Earnings</span><span style={{color:"#4CAF50"}}>${(drug?.lifetime_earnings||0).toLocaleString()}</span></div><div style={s.row}><span>Last Sale</span><span>{(drug?.last_sale||"").substring(0,10)}</span></div></div>
  </div>;
}

function Contracts() {
  const [contracts,setContracts]=useState<any[]>([]); const [ld,setLd]=useState(true);
  useEffect(()=>{proxy({action:"loadContracts"}).then(r=>{setContracts(Array.isArray(r)?r:[]);setLd(false)});},[]);
  if(ld)return<div style={s.empty}>Loading...</div>;
  if(!contracts.length)return<div style={s.empty}>No open contracts.<br/>Check back later.</div>;
  return <div>{contracts.map((c,i)=><div key={i} style={s.card}><div style={s.hdr}>{c.contract_type||"Contract"}</div><div style={s.sub}>Payout: ${(c.payout||0).toLocaleString()}</div><div style={s.sub}>Status: {c.status||"open"}</div></div>)}</div>;
}

function Heists() {
  const [heists,setHeists]=useState<any[]>([]); const [ld,setLd]=useState(true);
  useEffect(()=>{proxy({action:"loadHeists"}).then(r=>{setHeists(Array.isArray(r)?r:[]);setLd(false)});},[]);
  if(ld)return<div style={s.empty}>Loading...</div>;
  if(!heists.length)return<div style={s.empty}>No recent heists.<br/>Activity will appear here.</div>;
  return <div>{heists.map((h,i)=><div key={i} style={s.card}><div style={s.hdr}>{h.cargo_tier||"Heist"}</div><div style={s.row}><span>Value</span><span>${(h.estimated_value||0).toLocaleString()}</span></div><div style={s.row}><span>Police</span><span>{h.police_responded?"Responded":"Not Responded"}</span></div><div style={s.row}><span>Outcome</span><span style={{color:h.suspects_escaped?"#4CAF50":"#ef4444"}}>{h.suspects_escaped?"Escaped":"Caught"}</span></div></div>)}</div>;
}
