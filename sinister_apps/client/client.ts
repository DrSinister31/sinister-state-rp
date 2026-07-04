// Sinister Apps — Client-side NUI callbacks for proxy communication

interface ProxyPayload {
  id: number;
  app: string;
  payload: any;
}

const pendingCallbacks: Record<number, (data: any) => void> = {};

onNet("sinister_apps:proxyResponse", (requestId: number, result: any) => {
  const cb = pendingCallbacks[requestId];
  if (cb) {
    delete pendingCallbacks[requestId];
    cb(result);
  }
});

RegisterNuiCallbackType("proxyRequest");
on("__cfx_nui:proxyRequest", (data: ProxyPayload, cb: (result: any) => void) => {
  const requestId = data.id;
  pendingCallbacks[requestId] = cb;
  emitNet("sinister_apps:proxyRequest", requestId, data.app, data.payload);

  setTimeout(() => {
    if (pendingCallbacks[requestId]) {
      delete pendingCallbacks[requestId];
      cb({ _error: "Request timed out" });
    }
  }, 15000);
});
