// Sinister Apps — Client-side
var pendingCallbacks = {};
var isOpen = false;

onNet("sinister_apps:proxyResponse", function(requestId, result) {
  var cb = pendingCallbacks[requestId];
  if (cb) { delete pendingCallbacks[requestId]; cb(result); }
});

RegisterNuiCallbackType("proxyRequest");
on("__cfx_nui:proxyRequest", function(data, cb) {
  var requestId = data.id;
  pendingCallbacks[requestId] = cb;
  emitNet("sinister_apps:proxyRequest", requestId, data.app, data.payload);
  setTimeout(function() {
    if (pendingCallbacks[requestId]) { delete pendingCallbacks[requestId]; cb({ _error: "Request timed out" }); }
  }, 15000);
});

RegisterNuiCallbackType("setGPS");
on("__cfx_nui:setGPS", function(data, cb) {
  SetNewWaypoint(data.x, data.y);
  cb("ok");
});

// Open/close via command /apps
RegisterCommand("apps", function() {
  SetNuiFocus(true, true);
  isOpen = true;
  SendNUIMessage({ type: "open" });
}, false);

// Close with Backspace
setTick(function() {
  if (isOpen && IsControlJustPressed(0, 177)) {
    SetNuiFocus(false, false);
    isOpen = false;
  }
});
