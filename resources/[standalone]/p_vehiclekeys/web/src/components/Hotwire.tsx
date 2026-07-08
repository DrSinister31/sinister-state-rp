import { useState, useEffect, useCallback, useRef } from 'react';
import { useNuiEvent } from '../hooks/useNuiEvent';
import { fetchNui } from '../utils/fetchNui';
import { debugData } from '../utils/debugData';
import { playSfx } from '../utils/sfx';
import mg from './Minigame.module.scss';
import styles from './Hotwire.module.scss';
import { useT } from '../utils/locales';

// uncomment this code below to use in dev mode on browser

// debugData([
//     {
//         action: 'setVisibleHotwire',
//         data: true
//     }
// ]);

// debugData([
//     {
//         action: 'startHotwire',
//         data: {
//             difficulty: 'medium',
//             timeLimit: 28000
//         }
//     }
// ]);

type Difficulty = 'easy' | 'medium' | 'hard' | 'expert';

interface HotwireConfig {
    difficulty: Difficulty;
    timeLimit: number;
}

const difficultySettings: Record<Difficulty, {
    stages: number; 
    speed: number;
    zoneWidth: number;
    fuses: number;
    penalty: number;
    drift: number;
}> = {
    easy: { stages: 3, speed: 70, zoneWidth: 14, fuses: 4, penalty: 2000, drift: 0 },
    medium: { stages: 4, speed: 92, zoneWidth: 11, fuses: 3, penalty: 3000, drift: 0 },
    hard: { stages: 5, speed: 118, zoneWidth: 8, fuses: 2, penalty: 4000, drift: 3 },
    expert: { stages: 6, speed: 145, zoneWidth: 6.5, fuses: 2, penalty: 5000, drift: 5 }
};

const difficultyColors: Record<Difficulty, string> = {
    easy: '#4ade80',
    medium: '#fbbf24',
    hard: '#fb923c',
    expert: '#f87171'
};

const circuitLabels: Record<number, string[]> = {
    3: ['BATT', 'IGN', 'START'],
    4: ['BATT', 'ACC', 'IGN', 'START'],
    5: ['BATT', 'ACC', 'FUEL', 'IGN', 'START'],
    6: ['BATT', 'ACC', 'FUEL', 'COIL', 'IGN', 'START']
};

const failMessages: Record<string, string> = {
    shorted: 'hotwire_shorted',
    timeout: 'hotwire_timeout',
    cancelled: 'attempt_cancelled'
};

const randomZoneCenter = (width: number) => Math.random() * (100 - width - 24) + width / 2 + 12;

const Hotwire: React.FC = () => {
    const t = useT();
    const [isVisible, setVisible] = useState(false);
    const [gameState, setGameState] = useState<'idle' | 'playing' | 'success' | 'failed'>('idle');
    const [config, setConfig] = useState<HotwireConfig>({ difficulty: 'medium', timeLimit: 28000 });
    const [stage, setStage] = useState(0);
    const [fuses, setFuses] = useState(3);
    const [timeRemaining, setTimeRemaining] = useState(28000);
    const [failReason, setFailReason] = useState('cancelled');
    const [frame, setFrame] = useState({ pos: 0, zoneCenter: 50, zoneWidth: 11 });
    const [sparkAt, setSparkAt] = useState<number | null>(null);
    const [bridgedFlash, setBridgedFlash] = useState(false);

    const posRef = useRef(0);
    const dirRef = useRef(1);
    const speedRef = useRef(92);
    const zoneWidthRef = useRef(11);
    const zoneBaseRef = useRef(50);
    const zoneEffRef = useRef(50);
    const timerRef = useRef<number>();
    const sparkTimeoutRef = useRef<number>();
    const flashTimeoutRef = useRef<number>();

    const settings = difficultySettings[config.difficulty];
    const labels = circuitLabels[settings.stages] || circuitLabels[4];

    const finish = useCallback((success: boolean, reason?: string) => {
        setGameState(success ? 'success' : 'failed');
        if (!success && reason) setFailReason(reason);
        playSfx(success ? 'engine' : 'fail');
        fetchNui('hotwireResult', success ? { success: true } : { success: false, reason });
    }, []);

    const finishRef = useRef(finish);
    finishRef.current = finish;

    const initializeGame = useCallback((difficulty: Difficulty) => {
        const s = difficultySettings[difficulty];
        posRef.current = 0;
        dirRef.current = 1;
        speedRef.current = s.speed;
        zoneWidthRef.current = s.zoneWidth;
        zoneBaseRef.current = randomZoneCenter(s.zoneWidth);
        zoneEffRef.current = zoneBaseRef.current;
        setStage(0);
        setFuses(s.fuses);
        setSparkAt(null);
        setBridgedFlash(false);
        setFrame({ pos: 0, zoneCenter: zoneBaseRef.current, zoneWidth: s.zoneWidth });
    }, []);

    useNuiEvent<boolean>('setVisibleHotwire', (visible) => {
        setVisible(visible);
        if (!visible) {
            setGameState('idle');
            if (timerRef.current) clearInterval(timerRef.current);
        }
    });

    useNuiEvent<HotwireConfig>('startHotwire', (data) => {
        setConfig(data);
        setTimeRemaining(data.timeLimit);
        initializeGame(data.difficulty);
        setGameState('playing');
        setVisible(true);
    });

    useEffect(() => {
        if (gameState !== 'playing') return;

        timerRef.current = window.setInterval(() => {
            setTimeRemaining((prev) => {
                if (prev <= 100) {
                    finishRef.current(false, 'timeout');
                    return 0;
                }
                return prev - 100;
            });
        }, 100);

        return () => {
            if (timerRef.current) clearInterval(timerRef.current);
        };
    }, [gameState]);

    useEffect(() => {
        if (gameState !== 'playing') return;

        const s = difficultySettings[config.difficulty];
        let last = performance.now();
        let raf: number;

        const loop = (t: number) => {
            const dt = Math.min((t - last) / 1000, 0.05);
            last = t;

            let pos = posRef.current + dirRef.current * speedRef.current * dt;
            if (pos >= 100) {
                pos = 100 - (pos - 100);
                dirRef.current = -1;
            } else if (pos <= 0) {
                pos = -pos;
                dirRef.current = 1;
            }
            posRef.current = pos;

            const zoneCenter = s.drift > 0
                ? Math.max(8, Math.min(92, zoneBaseRef.current + Math.sin(t * 0.002) * s.drift))
                : zoneBaseRef.current;
            zoneEffRef.current = zoneCenter;

            setFrame({ pos, zoneCenter, zoneWidth: zoneWidthRef.current });
            raf = requestAnimationFrame(loop);
        };

        raf = requestAnimationFrame(loop);
        return () => cancelAnimationFrame(raf);
    }, [gameState, config.difficulty]);

    const strike = useCallback(() => {
        if (gameState !== 'playing') return;

        const pos = posRef.current;
        const distance = Math.abs(pos - zoneEffRef.current);

        if (distance <= zoneWidthRef.current / 2) {
            const nextStage = stage + 1;

            if (nextStage >= settings.stages) {
                setStage(nextStage);
                finish(true);
                return;
            }

            playSfx('connect');
            setStage(nextStage);
            setBridgedFlash(true);
            if (flashTimeoutRef.current) clearTimeout(flashTimeoutRef.current);
            flashTimeoutRef.current = window.setTimeout(() => setBridgedFlash(false), 250);

            speedRef.current *= 1.12;
            zoneWidthRef.current = Math.max(4, zoneWidthRef.current - 1);
            zoneBaseRef.current = randomZoneCenter(zoneWidthRef.current);
        } else {
            playSfx('spark');
            setSparkAt(pos);
            if (sparkTimeoutRef.current) clearTimeout(sparkTimeoutRef.current);
            sparkTimeoutRef.current = window.setTimeout(() => setSparkAt(null), 350);

            setFuses((prev) => {
                const next = prev - 1;
                if (next <= 0) {
                    finishRef.current(false, 'shorted');
                    return 0;
                }
                return next;
            });
            setTimeRemaining((prev) => Math.max(100, prev - settings.penalty));
        }
    }, [gameState, stage, settings, finish]);

    // controls
    useEffect(() => {
        const handleKeyDown = (e: KeyboardEvent) => {
            if (gameState !== 'playing') return;

            if (e.code === 'Space') {
                e.preventDefault();
                if (!e.repeat) strike();
            } else if (e.code === 'Escape') {
                e.preventDefault();
                finish(false, 'cancelled');
                fetchNui('hideFrame', { name: 'setVisibleHotwire' });
            }
        };

        window.addEventListener('keydown', handleKeyDown);
        return () => window.removeEventListener('keydown', handleKeyDown);
    }, [gameState, strike, finish]);

    useEffect(() => {
        return () => {
            if (timerRef.current) clearInterval(timerRef.current);
            if (sparkTimeoutRef.current) clearTimeout(sparkTimeoutRef.current);
            if (flashTimeoutRef.current) clearTimeout(flashTimeoutRef.current);
        };
    }, []);

    const formatTime = (ms: number) => {
        const seconds = Math.floor(ms / 1000);
        const tenths = Math.floor((ms % 1000) / 100);
        return `${seconds}.${tenths}s`;
    };

    if (!isVisible) return null;

    const timePct = config.timeLimit > 0 ? (timeRemaining / config.timeLimit) * 100 : 0;
    const currentLabel = labels[Math.min(stage, labels.length - 1)];

    return (
        <div className={mg.container}>
            <div className={mg.overlay} />
            <div className={mg.panel} style={{ width: '21rem' }}>
                <div className={mg.head}>
                    <span className={mg.badge}>{t('hotwire')}</span>
                    <span className={mg.diff} style={{ color: difficultyColors[config.difficulty] }}>
                        {t(config.difficulty)}
                    </span>
                </div>

                <div className={mg.card}>
                    <div className={styles.statusRow}>
                        <div className={styles.circuits}>
                            {labels.map((label, i) => (
                                <span
                                    key={label}
                                    className={[
                                        styles.circuitDot,
                                        i < stage ? styles.circuitDone : '',
                                        i === stage && gameState === 'playing' ? styles.circuitActive : ''
                                    ].join(' ')}
                                />
                            ))}
                            <span className={styles.circuitLabel}>{currentLabel}</span>
                        </div>
                        <div className={styles.fuses}>
                            {Array.from({ length: settings.fuses }).map((_, i) => (
                                <span
                                    key={i}
                                    className={`${styles.fuse} ${i >= fuses ? styles.fuseBlown : ''}`}
                                />
                            ))}
                        </div>
                    </div>

                    <div className={`${styles.track} ${bridgedFlash ? styles.bridged : ''}`}>
                        <div
                            className={styles.zone}
                            style={{
                                left: `${frame.zoneCenter - frame.zoneWidth / 2}%`,
                                width: `${frame.zoneWidth}%`
                            }}
                        />
                        <div className={styles.cursor} style={{ left: `${frame.pos}%` }} />
                        {sparkAt !== null && (
                            <div className={styles.spark} style={{ left: `${sparkAt}%` }} />
                        )}
                    </div>
                </div>

                <div className={mg.bars}>
                    <div className={mg.barRow}>
                        <div className={mg.barHead}>
                            <span className={mg.barLabel}>{t('time')}</span>
                            <span className={`${mg.barValue} ${timeRemaining < 5000 ? mg.danger : ''}`}>
                                {formatTime(timeRemaining)}
                            </span>
                        </div>
                        <div className={mg.bar}>
                            <div
                                className={mg.barFill}
                                style={{
                                    width: `${timePct}%`,
                                    background: timeRemaining < 5000 ? '#ef4444' : '#6366f1'
                                }}
                            />
                        </div>
                    </div>
                </div>

                <div className={mg.hints}>
                    <span className={mg.hint}><span className={mg.hintKey}>{t('space_key')}</span> {t('bridge')}</span>
                    <span className={mg.hint}><span className={mg.hintKey}>{t('esc_key')}</span> {t('cancel')}</span>
                </div>

                {gameState === 'success' && (
                    <div className={mg.resultOverlay}>
                        <div className={mg.resultCard}>
                            <div className={`${mg.resultTitle} ${mg.ok}`}>{t('engine_started')}</div>
                            <div className={mg.resultSub}>{t('vehicle_hotwired_successfully')}</div>
                        </div>
                    </div>
                )}

                {gameState === 'failed' && (
                    <div className={mg.resultOverlay}>
                        <div className={mg.resultCard}>
                            <div className={`${mg.resultTitle} ${mg.bad}`}>{t('short_circuit')}</div>
                            <div className={mg.resultSub}>{t(failMessages[failReason])}</div>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
};

export default Hotwire;
