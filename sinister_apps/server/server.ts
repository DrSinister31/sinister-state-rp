// Sinister Apps — Server-side proxy for Supabase + NPWD Registration

const SUPABASE_URL = GetConvar("sinister_apps:supabase_url", "");
const SUPABASE_KEY = GetConvar("sinister_apps:supabase_key", "");

on("onResourceStart", (resourceName: string) => {
  if (resourceName !== GetCurrentResourceName()) return;

  try {
    (global as any).exports.npwd.RegisterExternalApp({
      id: "sinister_apps",
      resourceName: GetCurrentResourceName(),
      name: "Sinister Apps",
    });
    console.log(`[sinister_apps] Registered with NPWD`);
  } catch (err) {
    console.error(`[sinister_apps] Failed to register with NPWD:`, err);
  }
});

async function supabaseRequest(method: string, endpoint: string, body?: any): Promise<any> {
  const p = new Promise((resolve) => {
    const url = `${SUPABASE_URL}/rest/v1/${endpoint}`;
    const headers: Record<string, string> = {
      "Content-Type": "application/json",
      apikey: SUPABASE_KEY,
      Authorization: `Bearer ${SUPABASE_KEY}`,
      Prefer: "return=representation",
    };
    (global as any).PerformHttpRequest(url, (code: number, data: string) => {
      try {
        resolve({ code, data: JSON.parse(data) });
      } catch {
        resolve({ code, data: null });
      }
    }, method, body ? JSON.stringify(body) : "", headers);
  });
  return p;
}

onNet("sinister_apps:proxyRequest", async (requestId: number, app: string, payload: any) => {
  const src = (global as any).source;
  let result: any = {};

  if (app === "banking") {
    if (payload.action === "loadBusinesses") {
      const resp: any = await supabaseRequest(
        "GET",
        `businesses?select=*&owner_citizenid=eq.${payload.citizenid}&active=eq.true`
      );
      result = resp.data || [];
    } else if (payload.action === "loadTransactions") {
      const resp: any = await supabaseRequest(
        "GET",
        `transactions?select=*&business_id=eq.${payload.business_id}&order=created_at.desc&limit=20`
      );
      result = resp.data || [];
    } else if (payload.action === "loadPnl") {
      const resp: any = await supabaseRequest(
        "GET",
        `business_pnl?select=*&business_id=eq.${payload.business_id}&order=created_at.desc&limit=12`
      );
      result = resp.data || [];
    } else if (payload.action === "loadEmployees") {
      const resp: any = await supabaseRequest(
        "GET",
        `business_employees?select=*&business_id=eq.${payload.business_id}`
      );
      result = resp.data || [];
    } else {
      result = { _error: `Unknown banking action: ${payload.action}` };
    }
  } else if (app === "syntok") {
    if (payload.action === "loadChronicles") {
      const resp: any = await supabaseRequest(
        "GET",
        "chronicle_entries?select=title,description,score,created_at&order=created_at.desc&limit=10"
      );
      result = resp.data || [];
    } else {
      result = { _error: `Unknown syntok action: ${payload.action}` };
    }
  } else {
    result = { _error: `Unknown app: ${app}` };
  }

  emitNet("sinister_apps:proxyResponse", src, requestId, result);
});
