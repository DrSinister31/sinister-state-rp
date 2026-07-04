// Sinister Apps — Navigation Logic
let currentApp = null;
function openApp(name) {
    document.querySelectorAll('.app-frame').forEach(f=>f.classList.remove('active'));
    document.getElementById('home').classList.remove('active');
    let frame = document.getElementById(name + '-frame');
    if (frame) { frame.classList.add('active'); currentApp = name; }
    fetch(`https://${document.location.hostname}/appOpened`, { method: 'POST', body: JSON.stringify({ app: name }) });
}
function closeApp() {
    document.querySelectorAll('.app-frame').forEach(f=>f.classList.remove('active'));
    document.getElementById('home').classList.add('active');
    currentApp = null;
    fetch(`https://${document.location.hostname}/appClosed`, { method: 'POST' });
}
