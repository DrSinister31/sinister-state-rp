window.addEventListener('message', function(event) {
    const data = event.data;
    const off = document.getElementById('off');
    const on = document.getElementById('on');

    if (data.type === "images") {
        off.src = "img/" + data.off;
        on.src = "img/" + data.on;
    }

    if(data.type === "off"){
        off.style.opacity = 1;
        on.style.opacity = 0;
    }

    if(data.type === "on"){
        off.style.opacity = 1;
        on.style.opacity = 1;

        setTimeout(() => { off.style.opacity = 0; }, 400);
        setTimeout(() => { on.style.opacity = 0; }, data.time || 2500);
    }

    if(data.type === "hide"){
        off.style.opacity = 0;
        on.style.opacity = 0;
    }

    if(data.type === "click"){
        const audio = new Audio('click.ogg');
        audio.volume = data.volume || 0.4;
        audio.play();
    }
});