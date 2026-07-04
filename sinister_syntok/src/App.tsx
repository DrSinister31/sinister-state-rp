import React, { useState, useEffect } from "react";

const RESOURCE = "sinister_syntok";

async function nuiFetch(event: string, data: any = {}): Promise<any> {
  try { const r = await fetch(`https://cfx-nui-${RESOURCE}/${event}`,{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify(data)}); return await r.json(); }
  catch { return { _error: "Failed" }; }
}

const s = {
  root: { height:"100%",width:"100%",display:"flex",flexDirection:"column" as const,background:"#000",color:"#fff",fontFamily:"'Segoe UI',sans-serif",overflow:"hidden" },
  header: { display:"flex",alignItems:"center",padding:"10px 12px",background:"#000",borderBottom:"1px solid #1a1a1a",flexShrink:0,gap:8 },
  logo: { color:"#ff0050",fontWeight:900,fontSize:16,letterSpacing:"-0.5px" },
  feed: { flex:1,overflowY:"auto" as const,overflowX:"hidden" as const },
  clip: { borderBottom:"1px solid #1a1a1a",padding:0,position:"relative" as const },
  clipInfo: { padding:"12px",display:"flex",flexDirection:"column" as const,gap:4 },
  clipTitle: { fontWeight:700,fontSize:13,color:"#fff" },
  clipScore: { position:"absolute" as const,top:12,right:12,background:"#ff0050",color:"#fff",borderRadius:"50%",width:36,height:36,display:"flex",alignItems:"center",justifyContent:"center",fontWeight:900,fontSize:12 },
  clipDesc: { fontSize:11,color:"#aaa",lineHeight:1.4 },
  clipDate: { fontSize:9,color:"#555",marginTop:2 },
  empty: { color:"#555",textAlign:"center" as const,padding:"40px 20px",fontSize:12 },
  loading: { color:"#555",textAlign:"center" as const,padding:"40px 20px",fontSize:12 },
  tabs: { display:"flex",borderBottom:"1px solid #1a1a1a",flexShrink:0 },
  tab: (a:boolean) => ({ flex:1,padding:"10px 2px",textAlign:"center" as const,cursor:"pointer",color:a?"#fff":"#555",border:"none",background:"transparent",borderBottom:a?"2px solid #ff0050":"2px solid transparent",fontSize:12,fontWeight:700 }),
};

export default function App() {
  const [tab,setTab]=useState(0);
  return (
    <div style={s.root}>
      <div style={s.header}><span style={s.logo}>syntok</span></div>
      <div style={s.tabs}>{["For You","Trending"].map((l,i)=><button key={i} style={s.tab(tab===i)} onClick={()=>setTab(i)}>{l}</button>)}</div>
      <div style={s.feed}>{tab===0?<ForYou/>:<Trending/>}</div>
    </div>
  );
}

function ForYou() {
  const [clips,setClips]=useState<any[]>([]); const [ld,setLd]=useState(true);
  useEffect(()=>{
    nuiFetch("syntok_proxy",{id:Date.now(),payload:{action:"loadChronicles",limit:15}}).then(r=>{setClips(Array.isArray(r)?r:[]);setLd(false);});
  },[]);
  if(ld)return<div style={s.loading}>Loading...</div>;
  if(!clips.length)return<div style={s.empty}>No clips yet.<br/>Events will appear as they happen.</div>;
  return <div>{clips.map((c,i)=><div key={i} style={s.clip}><div style={s.clipInfo}><div style={s.clipTitle}>{c.title||"Untitled"}</div><div style={s.clipDesc}>{(c.description||"").substring(0,200)}</div><div style={s.clipDate}>{(c.created_at||"").substring(0,10)}</div></div><div style={s.clipScore}>{c.score||"?"}</div></div>)}</div>;
}

function Trending() {
  const [clips,setClips]=useState<any[]>([]); const [ld,setLd]=useState(true);
  useEffect(()=>{
    nuiFetch("syntok_proxy",{id:Date.now(),payload:{action:"loadTrending",limit:15}}).then(r=>{setClips(Array.isArray(r)?r:[]);setLd(false);});
  },[]);
  if(ld)return<div style={s.loading}>Loading trending...</div>;
  const sorted = [...clips].sort((a,b)=>(b.score||0)-(a.score||0));
  if(!sorted.length)return<div style={s.empty}>Trending clips appear here.</div>;
  return <div>{sorted.map((c,i)=><div key={i} style={s.clip}><div style={s.clipInfo}><div style={s.clipTitle}>{c.title||"Untitled"}</div><div style={s.clipDesc}>{(c.description||"").substring(0,200)}</div><div style={s.clipDate}>{(c.created_at||"").substring(0,10)}</div></div><div style={{...s.clipScore,background:c.score>=23?"#ff0050":"#555"}}>{c.score||"?"}</div></div>)}</div>;
}
