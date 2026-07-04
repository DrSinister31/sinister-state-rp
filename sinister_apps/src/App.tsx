import React, { useState, useEffect } from "react";

const RESOURCE = "sinister_apps";

function nuiFetch(event: string, data: any = {}): Promise<any> {
  return fetch(`https://cfx-nui-${RESOURCE}/${event}`, {
    method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(data),
  }).then(r => r.json()).catch(() => ({ _error: "Failed" }));
}
function proxy(app: string, payload: any) { return nuiFetch("sinister_proxy", { id: Date.now(), app, payload }); }

const css = `
*{box-sizing:border-box;max-width:100%;font-family:'Segoe UI',sans-serif}
body{margin:0;padding:0;background:#0d0d16;color:#d0d0d8;font-size:11px}
.s-root{height:100%;display:flex;flex-direction:column;overflow:hidden}
.s-tabs{display:flex;background:#08080f;border-bottom:1px solid #1a1a28}
.s-tab{flex:1;padding:8px 2px;text-align:center;cursor:pointer;font-size:11px;font-weight:700;border:none;background:transparent;border-bottom:2px solid transparent}
.s-tab-a{color:#BF5700;border-bottom-color:#BF5700}
.s-tab-i{color:#5a5a6a}
.s-body{flex:1;overflow-y:auto;padding:8px}
.s-card{background:#151520;border-radius:8px;padding:10px 12px;margin-bottom:6px;border:1px solid #1e1e2e;word-break:break-word}
.s-hdr{color:#BF5700;font-weight:700;font-size:13px;margin-bottom:4px}
.s-big{font-size:20px;font-weight:700;color:#F5EBE0}
.s-sub{font-size:10px;color:#8a8a94;margin-top:2px}
.s-select{width:100%;background:#0d0d16;color:#d0d0d8;border:1px solid #2a2a3a;padding:6px 8px;border-radius:6px;font-size:12px;margin-bottom:8px}
.s-stabs{display:flex;gap:2px;margin-bottom:8px;background:#0d0d16;border-radius:4px;padding:2px}
.s-stab{flex:1;padding:6px 2px;border:none;font-size:10px;font-weight:700;cursor:pointer;border-radius:4px;text-align:center}
.s-stab-a{background:#1a1020;color:#BF5700}
.s-stab-i{background:transparent;color:#5a5a6a}
.s-row{display:flex;justify-content:space-between;padding:6px 0;border-bottom:1px solid #12121c;font-size:11px}
.s-green{color:#4CAF50;font-weight:600}
.s-red{color:#e53935;font-weight:600}
.s-search{display:flex;gap:4px;margin-bottom:8px}
.s-inp{flex:1;background:#151520;color:#d0d0d8;border:1px solid #2a2a3a;padding:7px 10px;border-radius:6px;font-size:12px}
.s-btn{background:#BF5700;color:white;border:none;padding:7px 14px;border-radius:6px;font-weight:700;cursor:pointer;font-size:12px}
.s-result{padding:10px 12px;cursor:pointer;border-bottom:1px solid #12121c}
.s-gps{color:#5a5a6a;font-size:9px;display:block;margin-top:2px}
.s-empty{color:#5a5a6a;text-align:center;padding:20px 8px;font-size:11px}
.s-pnl{display:flex;justify-content:space-between;font-size:10px;color:#b0b0bc}
`;

const SERVICES = [
  { n: "City Hall", d: "Get ID, licenses, apply for jobs", h: "Downtown Houston", x: -540.58, y: -212.02 },
  { n: "Mosley's Auto & Chop Shop", d: "Vehicle repair, mods, chop shop", h: "Davis Ave", x: 540, y: -200 },
  { n: "Lone Star Grill", d: "Texas burgers, open 24/7", h: "Mission Row", x: 440, y: -980 },
  { n: "Bucky's Stop & Shop", d: "Gas, snacks, Texas-sized", h: "Route 68", x: 640.66, y: 276.22 },
  { n: "Travis County Courthouse", d: "Legal services, marriage licenses", h: "Downtown", x: 243.5, y: -1086 },
  { n: "Houston Intl Airport", d: "Flights, ATC, airfield ownership", h: "LSIA", x: -1050, y: -2800 },
  { n: "Lackland AFB", d: "Texas National Guard", h: "Fort Zancudo", x: -2200, y: 3250 },
];

export default function App() {
  const [tab, setTab] = useState(0);
  const labels = ["Banking", "Browser", "syntok"];
  return React.createElement("div", null,
    React.createElement("style", null, css),
    React.createElement("div", { className: "s-root" },
      React.createElement("div", { className: "s-tabs" },
        labels.map((l, i) =>
          React.createElement("button", {
            key: i, className: `s-tab ${tab === i ? "s-tab-a" : "s-tab-i"}`,
            onClick: () => setTab(i)
          }, l)
        )
      ),
      React.createElement("div", { className: "s-body" },
        tab === 0 ? React.createElement(Banking) :
        tab === 1 ? React.createElement(Browser) :
        React.createElement(Syntok)
      )
    )
  );
}

function Banking() {
  const [biz, setBiz] = useState<any[]>([]);
  const [idx, setIdx] = useState(0);
  const [sub, setSub] = useState("recent");
  const [data, setData] = useState<any[]>([]);
  const [ld, setLd] = useState(true);

  useEffect(() => {
    proxy("banking", { action: "loadBusinesses", citizenid: "" })
      .then(r => { setBiz(Array.isArray(r) ? r : []); setLd(false); })
      .catch(() => setLd(false));
  }, []);

  useEffect(() => {
    if (!biz.length) return;
    const b = biz[idx];
    if (!b) return;
    let p;
    if (sub === "recent") p = proxy("banking", { action: "loadTransactions", business_id: b.id });
    else if (sub === "payroll") p = proxy("banking", { action: "loadEmployees", business_id: b.id });
    else p = proxy("banking", { action: "loadPnl", business_id: b.id });
    p.then(r => setData(Array.isArray(r) ? r : []));
  }, [biz, idx, sub]);

  if (ld) return React.createElement("div", { className: "s-empty" }, "Loading...");
  if (!biz.length) return React.createElement("div", { className: "s-empty" }, "No businesses.", React.createElement("br"), "Buy one at City Hall.");

  const b = biz[idx];
  const sel = React.createElement("select", {
    className: "s-select", value: idx,
    onChange: (e: any) => setIdx(Number(e.target.value))
  }, biz.map((x, i) => React.createElement("option", { key: i, value: i }, x.name)));

  const card = React.createElement("div", { className: "s-card" },
    React.createElement("div", { className: "s-hdr" }, b.name),
    React.createElement("div", { className: "s-big" }, "$" + (b.bank_account || 0).toLocaleString()),
    React.createElement("div", { className: "s-sub" }, "Revenue: $" + (b.revenue || 0).toLocaleString())
  );

  const stabs = React.createElement("div", { className: "s-stabs" },
    ["recent", "payroll", "pnl"].map(t =>
      React.createElement("button", {
        key: t, className: `s-stab ${sub === t ? "s-stab-a" : "s-stab-i"}`,
        onClick: () => setSub(t)
      }, t === "recent" ? "Recent" : t === "payroll" ? "Payroll" : "P&L")
    )
  );

  let content;
  if (sub === "recent") {
    content = data.map((tx, i) => {
      const amt = tx.amount || 0;
      return React.createElement("div", { key: i, className: "s-row" },
        React.createElement("span", null, tx.reason || "Tx"),
        React.createElement("span", { className: amt >= 0 ? "s-green" : "s-red" }, (amt >= 0 ? "+" : "") + "$" + Math.abs(amt).toLocaleString())
      );
    });
  } else if (sub === "payroll") {
    content = data.map((e, i) =>
      React.createElement("div", { key: i, className: "s-row" },
        React.createElement("span", null, (e.is_ai ? "[AI] " : "") + (e.citizenid || "?")),
        React.createElement("span", { style: { fontWeight: 600 } }, "$" + (e.hourly_wage || e.salary || 0).toLocaleString() + "/hr")
      )
    );
  } else {
    content = data.map((p, i) => {
      const rev = p.gross_income || p.revenue || 0;
      const exp = p.expenses || 0;
      const net = p.net_profit !== undefined ? p.net_profit : rev - exp;
      return React.createElement("div", { key: i, className: "s-card" },
        React.createElement("div", { className: "s-hdr" }, "Week of " + (p.week_start || p.created_at || "").substring(0, 10)),
        React.createElement("div", { className: "s-pnl" }, React.createElement("span", null, "Revenue"), React.createElement("span", null, "$" + rev.toLocaleString())),
        React.createElement("div", { className: "s-pnl", style: { color: "#e53935" } }, React.createElement("span", null, "Expenses"), React.createElement("span", null, "$" + exp.toLocaleString())),
        React.createElement("div", { className: "s-pnl", style: { fontWeight: 700, borderTop: "1px solid #1e1e2e", marginTop: 4, paddingTop: 4 } },
          React.createElement("span", null, "Net"),
          React.createElement("span", { style: { color: net >= 0 ? "#4CAF50" : "#e53935" } }, "$" + net.toLocaleString())
        )
      );
    });
  }

  return React.createElement("div", null, sel, card, stabs, content);
}

function Browser() {
  const [q, setQ] = useState("");
  const f = q ? SERVICES.filter(s => s.n.toLowerCase().includes(q.toLowerCase()) || s.d.toLowerCase().includes(q.toLowerCase()) || s.h.toLowerCase().includes(q.toLowerCase())) : SERVICES;
  return React.createElement("div", null,
    React.createElement("div", { className: "s-search" },
      React.createElement("input", { className: "s-inp", placeholder: "Search...", value: q, onChange: (e: any) => setQ(e.target.value) }),
      React.createElement("button", { className: "s-btn" }, "Go")
    ),
    f.map((sv, i) =>
      React.createElement("div", { key: i, className: "s-result", onClick: () => nuiFetch("setGPS", { x: sv.x, y: sv.y }) },
        React.createElement("div", { style: { color: "#BF5700", fontWeight: 700, fontSize: 12 } }, sv.n),
        React.createElement("div", { style: { fontSize: 10, color: "#b0b0bc" } }, sv.d),
        React.createElement("div", { className: "s-gps" }, "GPS: " + sv.h)
      )
    )
  );
}

function Syntok() {
  const [entries, setEntries] = useState<any[]>([]);
  const [ld, setLd] = useState(true);
  useEffect(() => {
    proxy("syntok", { action: "loadChronicles" })
      .then(r => { setEntries(Array.isArray(r) ? r : []); setLd(false); })
      .catch(() => setLd(false));
  }, []);
  if (ld) return React.createElement("div", { className: "s-empty" }, "Loading chronicles...");
  if (!entries.length) return React.createElement("div", { className: "s-empty" }, "No chronicles yet.", React.createElement("br"), "Events appear here.");
  return React.createElement("div", null,
    entries.map((c, i) =>
      React.createElement("div", { key: i, className: "s-card" },
        React.createElement("div", { className: "s-hdr" }, "Score: " + (c.score || "?") + "/30 — " + (c.title || "Untitled")),
        React.createElement("div", { className: "s-sub" }, (c.description || "").substring(0, 200))
      )
    ),
    React.createElement("div", { className: "s-card" },
      React.createElement("div", { className: "s-hdr" }, "Submit clips"),
      React.createElement("div", { className: "s-sub" }, "F12 to screenshot. Earn rewards!")
    )
  );
}
