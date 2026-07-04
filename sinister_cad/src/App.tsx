import React, { useState } from "react";
import { ThemeProvider, createTheme, CssBaseline, Box, Typography, Paper, Button, TextField, CircularProgress } from "@mui/material";

const RESOURCE = "sinister_cad";
const theme = createTheme({
  palette: { mode: "dark", primary: { main: "#1565C0" }, background: { default: "#0d1117", paper: "#161b22" } },
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

function proxy(payload: any) { return nuiFetch("cad_proxy", { id: Date.now(), payload }); }

export default function App() {
  const [tab, setTab] = useState(0);
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Box sx={{ height: "100%", display: "flex", flexDirection: "column", bgcolor: "background.default" }}>
        <Box sx={{ display: "flex", borderBottom: 1, borderColor: "divider" }}>
          {["Scanner", "Radar"].map((l, i) => (
            <Button key={i} fullWidth sx={{
              color: tab === i ? "primary.main" : "text.disabled", borderBottom: tab === i ? 2 : 0,
              borderColor: "primary.main", borderRadius: 0, py: 1.5, fontSize: 13, fontWeight: 600
            }} onClick={() => setTab(i)}>{l}</Button>
          ))}
        </Box>
        <Box sx={{ flex: 1, overflow: "auto", p: 1.5 }}>
          {tab === 0 && <Scanner />}
          {tab === 1 && <Radar />}
        </Box>
        <Typography variant="caption" color="textDisabled" textAlign="center" sx={{ py: 1, borderTop: 1, borderColor: "divider" }}>
          Full MDT: /cad &bull; distortedz_cad
        </Typography>
      </Box>
    </ThemeProvider>
  );
}

function Scanner() {
  const [scan, setScan] = useState<any>(null);
  const [lookup, setLookup] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [manual, setManual] = useState("");

  async function doScan() {
    setLoading(true); setLookup(null);
    const s = await nuiFetch("cad:scanPlate", {});
    setScan(s);
    if (s.plate) { const r = await proxy({ action: "plateLookup", plate: s.plate }); setLookup(r); }
    setLoading(false);
  }

  async function doManual() {
    if (!manual) return;
    setLoading(true); setScan({ plate: manual });
    const r = await proxy({ action: "plateLookup", plate: manual }); setLookup(r);
    setLoading(false);
  }

  return (
    <Box>
      <Button variant="contained" fullWidth onClick={doScan} disabled={loading} sx={{ mb: 1 }}>
        {loading ? <CircularProgress size={20} /> : "Scan Nearby Vehicle"}
      </Button>
      <Box sx={{ display: "flex", gap: 1, mb: 1 }}>
        <TextField size="small" fullWidth placeholder="Or type plate..." value={manual} onChange={e => setManual(e.target.value)} />
        <Button variant="outlined" size="small" onClick={doManual} sx={{ minWidth: 80 }}>Lookup</Button>
      </Box>

      {scan?.error && <Typography color="error" sx={{ my: 1 }}>{scan.error}</Typography>}

      {scan?.plate && (
        <Paper sx={{ p: 1.5, mb: 1 }}>
          <Typography color="primary" fontWeight={700}>Scanned Vehicle</Typography>
          <Typography variant="body2"><b>Plate:</b> {scan.plate}</Typography>
          <Typography variant="body2"><b>Model:</b> {scan.model || "Unknown"}</Typography>
          <Typography variant="body2"><b>Speed:</b> {scan.speed} km/h</Typography>
        </Paper>
      )}

      {lookup?.registry?.plate && (
        <Paper sx={{ p: 1.5, mb: 1, border: 1, borderColor: lookup.registry.stolen ? "error.main" : lookup.registry.flagged ? "warning.main" : "divider" }}>
          <Typography color="primary" fontWeight={700}>Registry</Typography>
          <Typography variant="body2"><b>Owner:</b> {lookup.registry.owner_name || "Unknown"}</Typography>
          <Typography variant="body2"><b>CID:</b> {lookup.registry.owner_citizenid || "N/A"}</Typography>
          <Typography variant="body2" color={lookup.registry.stolen ? "error" : lookup.registry.flagged ? "warning.main" : "success.main"}>
            {lookup.registry.stolen ? "STOLEN" : lookup.registry.flagged ? `Flagged: ${lookup.registry.flag_reason}` : "Clean"}
          </Typography>
        </Paper>
      )}

      {lookup?.warrants?.length > 0 && (
        <Paper sx={{ p: 1.5, mb: 1, border: 1, borderColor: "error.main" }}>
          <Typography color="error" fontWeight={700}>Active Warrants ({lookup.warrants.length})</Typography>
          {lookup.warrants.map((w: any, i: number) => (
            <Typography key={i} variant="caption" display="block">{w.reason} — {w.issued_at?.substring(0, 10)}</Typography>
          ))}
        </Paper>
      )}

      {lookup?.records?.length > 0 && (
        <Paper sx={{ p: 1.5 }}>
          <Typography color="primary" fontWeight={700}>Criminal History ({lookup.records.length})</Typography>
          {lookup.records.slice(0, 5).map((r: any, i: number) => (
            <Box key={i} sx={{ py: 0.5, borderBottom: 1, borderColor: "divider" }}>
              <Typography variant="caption" display="block"><b>{r.charge}</b> — {r.severity} — {r.convicted ? "Convicted" : "Pending"}</Typography>
            </Box>
          ))}
        </Paper>
      )}
    </Box>
  );
}

function Radar() {
  const [radar, setRadar] = useState<any>(null);
  const [loading, setLoading] = useState(false);

  async function checkSpeed() {
    setLoading(true);
    const r = await nuiFetch("cad:getSpeed", {});
    setRadar(r);
    if (r.speed && r.plate) {
      proxy({ action: "speedLog", plate: r.plate, speed: r.speed, limit_speed: r.limit, location: r.location, officer_citizenid: "" });
    }
    setLoading(false);
  }

  return (
    <Box>
      <Button variant="contained" fullWidth onClick={checkSpeed} disabled={loading} sx={{ mb: 2 }}>
        {loading ? <CircularProgress size={20} /> : "Check Speed"}
      </Button>
      {radar?.error && <Typography color="error">{radar.error}</Typography>}
      {radar?.speed && (
        <Paper sx={{ p: 2, textAlign: "center", border: 2, borderColor: radar.over ? "error.main" : "success.main" }}>
          <Typography variant="h3" fontWeight={700} color={radar.over ? "error" : "success.main"}>{radar.speed}</Typography>
          <Typography variant="body2" color="textSecondary">KM/H</Typography>
          <Box sx={{ mt: 1 }}>
            <Typography variant="body2"><b>Limit:</b> {radar.limit} km/h</Typography>
            <Typography variant="body2"><b>Plate:</b> {radar.plate}</Typography>
            <Typography variant="caption" color="textDisabled">{radar.location}</Typography>
          </Box>
        </Paper>
      )}
    </Box>
  );
}
