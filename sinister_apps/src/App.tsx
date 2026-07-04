import React, { useState, useEffect, useCallback } from "react";
import { ThemeProvider, createTheme, CssBaseline, Box, Typography, Paper, Button, TextField, Select, MenuItem, Tabs, Tab, CircularProgress } from "@mui/material";
import { Building2 } from "lucide-react";

const RESOURCE = "sinister_apps";

const theme = createTheme({
  palette: {
    mode: "dark",
    primary: { main: "#BF5700" },
    background: { default: "#0a0a0f", paper: "#151520" },
  },
  typography: { fontFamily: "'Segoe UI',sans-serif", fontSize: 13 },
  components: { MuiPaper: { styleOverrides: { root: { backgroundImage: "none" } } } },
});

async function nuiFetch(event: string, data: any = {}): Promise<any> {
  try {
    const resp = await fetch(`https://cfx-nui-${RESOURCE}/${event}`, {
      method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(data),
    });
    return await resp.json();
  } catch { return { _error: "Failed" }; }
}

function proxy(app: string, payload: any) { return nuiFetch("sinister_proxy", { id: Date.now(), app, payload }); }

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
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Box sx={{ height: "100%", display: "flex", flexDirection: "column", bgcolor: "background.default" }}>
        <Tabs value={tab} onChange={(_, v) => setTab(v)} variant="fullWidth" sx={{ borderBottom: 1, borderColor: "divider", minHeight: 40 }}>
          {["Banking", "Browser", "syntok"].map((l, i) => <Tab key={i} label={l} sx={{ minHeight: 40, py: 1, fontSize: 12, fontWeight: 600 }} />)}
        </Tabs>
        <Box sx={{ flex: 1, overflow: "auto", p: 1.5 }}>
          {tab === 0 && <Banking />}
          {tab === 1 && <Browser />}
          {tab === 2 && <Syntok />}
        </Box>
      </Box>
    </ThemeProvider>
  );
}

function Banking() {
  const [biz, setBiz] = useState<any[]>([]);
  const [idx, setIdx] = useState(0);
  const [sub, setSub] = useState("recent");
  const [data, setData] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => { proxy("banking", { action: "loadBusinesses", citizenid: "" }).then(r => { setBiz(Array.isArray(r) ? r : []); setLoading(false); }); }, []);
  const loadSub = useCallback(async (s: string) => {
    setSub(s); const b = biz[idx]; if (!b) return;
    let r; if (s === "recent") r = await proxy("banking", { action: "loadTransactions", business_id: b.id });
    else if (s === "payroll") r = await proxy("banking", { action: "loadEmployees", business_id: b.id });
    else r = await proxy("banking", { action: "loadPnl", business_id: b.id });
    setData(Array.isArray(r) ? r : []);
  }, [biz, idx]);
  useEffect(() => { if (biz.length) loadSub(sub); }, [biz, idx]);

  if (loading) return <Box sx={{ display: "flex", justifyContent: "center", py: 4 }}><CircularProgress size={24} /></Box>;
  if (!biz.length) return <Typography color="textSecondary" textAlign="center" py={4}>No active businesses.<br/>Buy one at City Hall!</Typography>;

  const b = biz[idx];
  return (
    <Box>
      <Select size="small" fullWidth value={idx} onChange={e => setIdx(Number(e.target.value))} sx={{ mb: 1 }}>
        {biz.map((x, i) => <MenuItem key={i} value={i}>{x.name}</MenuItem>)}
      </Select>
      <Paper sx={{ p: 1.5, mb: 1 }}>
        <Typography color="primary" fontWeight={700} fontSize={14}>{b.name}</Typography>
        <Typography fontSize={22} fontWeight={700} color="white">${(b.bank_account || 0).toLocaleString()}</Typography>
        <Typography variant="caption" color="textSecondary">Revenue: ${(b.revenue || 0).toLocaleString()}</Typography>
      </Paper>
      <Tabs value={sub} onChange={(_, v) => loadSub(v)} variant="fullWidth" sx={{ minHeight: 32, mb: 1 }}>
        <Tab value="recent" label="Recent" sx={{ minHeight: 32, py: 0.5, fontSize: 11 }} />
        <Tab value="payroll" label="Payroll" sx={{ minHeight: 32, py: 0.5, fontSize: 11 }} />
        <Tab value="pnl" label="P&L" sx={{ minHeight: 32, py: 0.5, fontSize: 11 }} />
      </Tabs>
      {sub === "recent" && data.map((tx, i) => {
        const amt = tx.amount || 0;
        return <Box key={i} sx={{ display: "flex", justifyContent: "space-between", py: 1, borderBottom: 1, borderColor: "divider", fontSize: 12 }}>
          <Typography variant="body2">{tx.reason || "Tx"}</Typography>
          <Typography variant="body2" fontWeight={600} color={amt >= 0 ? "success.main" : "error.main"}>{(amt >= 0 ? "+" : "")}${Math.abs(amt).toLocaleString()}</Typography>
        </Box>;
      })}
      {sub === "payroll" && data.map((e, i) => (
        <Box key={i} sx={{ display: "flex", justifyContent: "space-between", py: 1, borderBottom: 1, borderColor: "divider", fontSize: 12 }}>
          <Typography variant="body2">{e.is_ai ? "[AI] " : ""}{e.citizenid || "Unknown"}</Typography>
          <Typography variant="body2" fontWeight={600}>${(e.hourly_wage || e.salary || 0).toLocaleString()}/hr</Typography>
        </Box>
      ))}
      {sub === "pnl" && data.map((p, i) => {
        const rev = p.gross_income || p.revenue || 0; const exp = p.expenses || 0; const net = p.net_profit !== undefined ? p.net_profit : rev - exp;
        return <Paper key={i} sx={{ p: 1, mb: 0.5 }}>
          <Typography color="primary" fontWeight={600} fontSize={12}>Week of {(p.week_start || p.created_at || "").substring(0, 10)}</Typography>
          <Box sx={{ display: "flex", justifyContent: "space-between", fontSize: 11, color: "text.secondary" }}><span>Revenue</span><span>${rev.toLocaleString()}</span></Box>
          <Box sx={{ display: "flex", justifyContent: "space-between", fontSize: 11, color: "error.main" }}><span>Expenses</span><span>${exp.toLocaleString()}</span></Box>
          <Box sx={{ display: "flex", justifyContent: "space-between", fontSize: 11, fontWeight: 700, borderTop: 1, borderColor: "divider", pt: 0.5, mt: 0.5 }}>
            <span>Net</span><span style={{ color: net >= 0 ? "#4CAF50" : "#e53935" }}>${net.toLocaleString()}</span>
          </Box>
        </Paper>;
      })}
    </Box>
  );
}

function Browser() {
  const [q, setQ] = useState("");
  const filtered = q ? SERVICES.filter(s => s.n.toLowerCase().includes(q.toLowerCase()) || s.d.toLowerCase().includes(q.toLowerCase()) || s.h.toLowerCase().includes(q.toLowerCase())) : SERVICES;
  return (
    <Box>
      <Box sx={{ display: "flex", gap: 1, mb: 1 }}>
        <TextField size="small" fullWidth placeholder="Search Sinister State..." value={q} onChange={e => setQ(e.target.value)} />
        <Button variant="contained" size="small" sx={{ minWidth: 60 }}>Go</Button>
      </Box>
      {filtered.map((s, i) => (
        <Paper key={i} sx={{ p: 1.5, mb: 0.5, cursor: "pointer", "&:hover": { bgcolor: "#1a1a28" } }} onClick={() => nuiFetch("setGPS", { x: s.x, y: s.y })}>
          <Typography color="primary" fontWeight={600}>{s.n}</Typography>
          <Typography variant="body2">{s.d}</Typography>
          <Typography variant="caption" color="textDisabled">GPS: {s.h}</Typography>
        </Paper>
      ))}
    </Box>
  );
}

function Syntok() {
  const [entries, setEntries] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  useEffect(() => { proxy("syntok", { action: "loadChronicles" }).then(r => { setEntries(Array.isArray(r) ? r : []); setLoading(false); }); }, []);
  if (loading) return <Box sx={{ display: "flex", justifyContent: "center", py: 4 }}><CircularProgress size={24} /></Box>;
  if (!entries.length) return <Typography color="textSecondary" textAlign="center" py={4}>No chronicles yet.</Typography>;
  return <Box>
    {entries.map((c, i) => (
      <Paper key={i} sx={{ p: 1.5, mb: 1 }}>
        <Typography color="primary" fontWeight={700} fontSize={13}>Score: {c.score || "?"}/30 — {c.title || "Untitled"}</Typography>
        <Typography variant="caption" color="textSecondary">{(c.description || "").substring(0, 250)}</Typography>
      </Paper>
    ))}
    <Paper sx={{ p: 1.5 }}>
      <Typography color="primary" fontWeight={700}>Submit your clips</Typography>
      <Typography variant="caption">Press F12 to screenshot. Featured clips earn rewards!</Typography>
    </Paper>
  </Box>;
}
