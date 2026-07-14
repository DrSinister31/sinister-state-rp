'use client';

import { useState, useRef, useEffect } from 'react';
import { Volume2, VolumeX } from 'lucide-react';

export default function AudioPlayer() {
  const [muted, setMuted] = useState(false);
  const audioRef = useRef(null);

  useEffect(() => {
    const audio = audioRef.current;
    if (!audio) return;

    const tryPlay = () => {
      audio.volume = 0.3;
      audio.play().catch(() => {});
    };

    tryPlay();

    // Resume playback on user interaction if autoplay blocked
    const resume = () => {
      if (audio.paused) tryPlay();
    };
    document.addEventListener('click', resume, { once: true });
    document.addEventListener('keydown', resume, { once: true });

    return () => {
      document.removeEventListener('click', resume);
      document.removeEventListener('keydown', resume);
    };
  }, []);

  const toggleMute = () => {
    const audio = audioRef.current;
    if (!audio) return;
    if (muted) {
      audio.muted = false;
      setMuted(false);
    } else {
      audio.muted = true;
      setMuted(true);
    }
  };

  return (
    <>
      <audio ref={audioRef} src="/audio/sinister-isle-echoes.mp3" loop preload="auto" />
      <button
        onClick={toggleMute}
        title={muted ? 'Unmute' : 'Mute'}
        className="fixed bottom-4 right-4 z-[9999] w-9 h-9 flex items-center justify-center rounded-full bg-black/60 border border-red-900/40 hover:border-red-500/60 hover:bg-black/80 transition-all shadow-[0_0_12px_rgba(220,38,38,0.15)] cursor-pointer"
      >
        {muted ? (
          <VolumeX className="w-4 h-4 text-red-400" />
        ) : (
          <Volume2 className="w-4 h-4 text-red-400" />
        )}
      </button>
    </>
  );
}
