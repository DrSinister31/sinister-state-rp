const audioContext = new (window.AudioContext || (window as any).webkitAudioContext)();

export type SfxType =
    | 'tick'
    | 'click'
    | 'pinSet'
    | 'pinFail'
    | 'slip'
    | 'spark'
    | 'connect'
    | 'engine'
    | 'success'
    | 'fail';

const tone = (
    type: OscillatorType,
    freqs: [number, number][],
    gainStart: number,
    duration: number
) => {
    const now = audioContext.currentTime;
    const osc = audioContext.createOscillator();
    const gain = audioContext.createGain();
    osc.connect(gain);
    gain.connect(audioContext.destination);
    osc.type = type;
    freqs.forEach(([freq, at]) => osc.frequency.setValueAtTime(freq, now + at));
    gain.gain.setValueAtTime(gainStart, now);
    gain.gain.exponentialRampToValueAtTime(0.01, now + duration);
    osc.start(now);
    osc.stop(now + duration);
};

const noise = (duration: number, gainStart: number, filterFreq?: number) => {
    const now = audioContext.currentTime;
    const bufferSize = Math.floor(audioContext.sampleRate * duration);
    const buffer = audioContext.createBuffer(1, bufferSize, audioContext.sampleRate);
    const data = buffer.getChannelData(0);
    for (let i = 0; i < bufferSize; i++) {
        data[i] = (Math.random() * 2 - 1) * Math.exp(-i / (bufferSize * 0.25));
    }

    const source = audioContext.createBufferSource();
    source.buffer = buffer;
    const gain = audioContext.createGain();
    gain.gain.setValueAtTime(gainStart, now);
    gain.gain.exponentialRampToValueAtTime(0.01, now + duration);

    if (filterFreq) {
        const filter = audioContext.createBiquadFilter();
        filter.type = 'highpass';
        filter.frequency.setValueAtTime(filterFreq, now);
        source.connect(filter);
        filter.connect(gain);
    } else {
        source.connect(gain);
    }

    gain.connect(audioContext.destination);
    source.start(now);
    source.stop(now + duration);
};

export const playSfx = (type: SfxType) => {
    const now = audioContext.currentTime;

    switch (type) {
        case 'tick':
            tone('square', [[2400, 0]], 0.025, 0.015);
            break;

        case 'click':
            tone('square', [[1500, 0]], 0.05, 0.02);
            break;

        case 'pinSet': {
            noise(0.08, 0.4, 2000);
            const osc = audioContext.createOscillator();
            const gain = audioContext.createGain();
            osc.connect(gain);
            gain.connect(audioContext.destination);
            osc.type = 'square';
            osc.frequency.setValueAtTime(3000, now);
            osc.frequency.exponentialRampToValueAtTime(800, now + 0.02);
            gain.gain.setValueAtTime(0.3, now);
            gain.gain.exponentialRampToValueAtTime(0.01, now + 0.03);
            osc.start(now);
            osc.stop(now + 0.03);
            break;
        }

        case 'pinFail':
            tone('sawtooth', [[200, 0]], 0.15, 0.15);
            break;

        case 'slip':
            tone('sawtooth', [[400, 0], [180, 0.04]], 0.08, 0.1);
            noise(0.06, 0.1, 3000);
            break;

        case 'spark':
            noise(0.12, 0.2, 1800);
            tone('sawtooth', [[150, 0]], 0.08, 0.1);
            break;

        case 'connect':
            tone('sine', [[600, 0], [900, 0.05], [1200, 0.1]], 0.12, 0.15);
            break;

        case 'engine': {
            const osc = audioContext.createOscillator();
            const gain = audioContext.createGain();
            osc.connect(gain);
            gain.connect(audioContext.destination);
            osc.type = 'sawtooth';
            osc.frequency.setValueAtTime(45, now);
            osc.frequency.exponentialRampToValueAtTime(130, now + 0.6);
            gain.gain.setValueAtTime(0.18, now);
            gain.gain.exponentialRampToValueAtTime(0.01, now + 0.8);
            osc.start(now);
            osc.stop(now + 0.8);
            noise(0.3, 0.08, 400);
            break;
        }

        case 'success':
            tone('sine', [[523, 0], [659, 0.1], [784, 0.2], [1047, 0.3]], 0.25, 0.5);
            break;

        case 'fail':
            tone('sawtooth', [[300, 0]], 0.2, 0.3);
            break;
    }
};
