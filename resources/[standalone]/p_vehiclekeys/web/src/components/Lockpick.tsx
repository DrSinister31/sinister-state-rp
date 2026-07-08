import { useState, useEffect, useCallback, useRef } from 'react';
import { useNuiEvent } from '../hooks/useNuiEvent';
import { fetchNui } from '../utils/fetchNui';
import { debugData } from '../utils/debugData';
import { playSfx } from '../utils/sfx';
import mg from './Minigame.module.scss';
import styles from './Lockpick.module.scss';
import { useT } from '../utils/locales';

// you can uncomment the code below if you want to test game in your browser in dev mode

// debugData([
//     {
//         action: 'setVisibleLockpick',
//         data: true
//     }
// ]);

// debugData([
//     {
//         action: 'startLockpick',
//         data: {
//             difficulty: 'hard', // easy, medium, hard, expert
//             pins: 5,
//             timeLimit: 25000
//         }
//     }
// ]);

type Difficulty = 'easy' | 'medium' | 'hard' | 'expert';

interface LockpickConfig {
    difficulty: Difficulty;
    pins: number;
    timeLimit: number;
}

interface Pin {
    keyLength: number;
    isSet: boolean;
}

const SHEAR_LINE = 65;
const DRIVER_LENGTH = 16;
const CHAMBER_REM = 9.5;
const CHAMBER_W_REM = 2.3;
const CHAMBER_GAP_REM = 0.55;
const PICK_BASE_REM = 0.65;

const difficultySettings: Record<Difficulty, {
    tolerance: number;
    pushSpeed: number;
    sinkSpeed: number;
    tremor: number;
    dropOnFail: boolean;
}> = {
    easy: { tolerance: 6, pushSpeed: 34, sinkSpeed: 7, tremor: 0, dropOnFail: false },
    medium: { tolerance: 4.5, pushSpeed: 38, sinkSpeed: 11, tremor: 0.5, dropOnFail: false },
    hard: { tolerance: 3.2, pushSpeed: 44, sinkSpeed: 16, tremor: 1.1, dropOnFail: true },
    expert: { tolerance: 2.3, pushSpeed: 50, sinkSpeed: 21, tremor: 1.7, dropOnFail: true }
};

const difficultyColors: Record<Difficulty, string> = {
    easy: '#4ade80',
    medium: '#fbbf24',
    hard: '#fb923c',
    expert: '#f87171'
};

const failMessages: Record<string, string> = {
    broken: 'lockpick_broken',
    timeout: 'lockpick_timeout',
    cancelled: 'lockpick_cancelled'
};

const Lockpick: React.FC = () => {
    const t = useT();
    const [isVisible, setVisible] = useState(false);
    const [gameState, setGameState] = useState<'idle' | 'playing' | 'success' | 'failed'>('idle');
    const [config, setConfig] = useState<LockpickConfig>({ difficulty: 'medium', pins: 4, timeLimit: 30000 });
    const [pins, setPins] = useState<Pin[]>([]);
    const [pinIndex, setPinIndex] = useState(0);
    const [health, setHealth] = useState(100);
    const [timeRemaining, setTimeRemaining] = useState(30000);
    const [failReason, setFailReason] = useState('cancelled');
    const [frame, setFrame] = useState({ raise: 0, tremor: 0 });
    const [shake, setShake] = useState(false);

    const raiseRef = useRef(0);
    const pushDirRef = useRef<0 | 1 | -1>(0);
    const tremorRef = useRef(0);
    const pinsRef = useRef<Pin[]>([]);
    const pinIndexRef = useRef(0);
    const lastTickRef = useRef(0);
    const timerRef = useRef<number>();
    const shakeTimeoutRef = useRef<number>();

    pinsRef.current = pins;
    pinIndexRef.current = pinIndex;

    const settings = difficultySettings[config.difficulty];

    const finish = useCallback((success: boolean, reason?: string) => {
        setGameState(success ? 'success' : 'failed');
        if (!success && reason) setFailReason(reason);
        playSfx(success ? 'success' : 'fail');
        fetchNui('lockpickResult', success ? { success: true } : { success: false, reason });
    }, []);

    const finishRef = useRef(finish);
    finishRef.current = finish;

    const applyDamage = useCallback((amount: number) => {
        setHealth((prev) => {
            const next = prev - amount;
            if (next <= 0) {
                finishRef.current(false, 'broken');
                return 0;
            }
            return next;
        });
    }, []);

    const applyDamageRef = useRef(applyDamage);
    applyDamageRef.current = applyDamage;

    const triggerShake = useCallback(() => {
        setShake(true);
        if (shakeTimeoutRef.current) clearTimeout(shakeTimeoutRef.current);
        shakeTimeoutRef.current = window.setTimeout(() => setShake(false), 280);
    }, []);

    const initializeGame = useCallback((pinCount: number) => {
        const newPins: Pin[] = [];
        for (let i = 0; i < pinCount; i++) {
            newPins.push({
                keyLength: Math.random() * 23 + 25,
                isSet: false
            });
        }

        setPins(newPins);
        setPinIndex(0);
        setHealth(100);
        raiseRef.current = 0;
        pushDirRef.current = 0;
        tremorRef.current = 0;
        setFrame({ raise: 0, tremor: 0 });
        setShake(false);
    }, []);

    useNuiEvent<boolean>('setVisibleLockpick', (visible) => {
        setVisible(visible);
        if (!visible) {
            setGameState('idle');
            if (timerRef.current) clearInterval(timerRef.current);
        }
    });

    useNuiEvent<LockpickConfig>('startLockpick', (data) => {
        setConfig(data);
        setTimeRemaining(data.timeLimit);
        initializeGame(data.pins);
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

            const pin = pinsRef.current[pinIndexRef.current];
            if (!pin) {
                raf = requestAnimationFrame(loop);
                return;
            }

            let raise = raiseRef.current;
            if (pushDirRef.current === 1) raise += s.pushSpeed * dt;
            else if (pushDirRef.current === -1) raise -= s.sinkSpeed * 3.2 * dt;
            else raise -= s.sinkSpeed * dt;

            const maxRaise = 100 - pin.keyLength - DRIVER_LENGTH - 4;
            raise = Math.max(0, Math.min(maxRaise, raise));

            const tremor = s.tremor > 0
                ? Math.sin(t * 0.013) * s.tremor + Math.sin(t * 0.0071 + 1.3) * s.tremor * 0.55
                : 0;

            const seam = raise + tremor + pin.keyLength;

            // overshooting the shear line is fine — the pin just rides up to the top.
            // sink it back down (S) to find the sweet spot, no slip or damage.
            if (Math.abs(seam - SHEAR_LINE) <= s.tolerance && t - lastTickRef.current > 130) {
                // pin is binding, subtle feedback ticks
                playSfx('tick');
                lastTickRef.current = t;
            }

            raiseRef.current = raise;
            tremorRef.current = tremor;
            setFrame({ raise, tremor });

            raf = requestAnimationFrame(loop);
        };

        raf = requestAnimationFrame(loop);
        return () => cancelAnimationFrame(raf);
    }, [gameState, config.difficulty]);

    // apply tension and try to bind the current pin
    const attemptSet = useCallback(() => {
        if (gameState !== 'playing') return;

        const pin = pins[pinIndex];
        if (!pin) return;

        const seam = raiseRef.current + tremorRef.current + pin.keyLength;
        const distance = Math.abs(seam - SHEAR_LINE);

        if (distance <= settings.tolerance) {
            playSfx('pinSet');
            const newPins = pins.map((p, i) => (i === pinIndex ? { ...p, isSet: true } : p));
            setPins(newPins);
            raiseRef.current = 0;
            setFrame({ raise: 0, tremor: 0 });

            if (pinIndex + 1 >= newPins.length) {
                finish(true);
            } else {
                setPinIndex(pinIndex + 1);
            }
        } else {
            playSfx('pinFail');
            triggerShake();
            raiseRef.current = 0;
            setFrame({ raise: 0, tremor: 0 });

            if (settings.dropOnFail && pinIndex > 0) {
                setPins((prev) => prev.map((p, i) => (i === pinIndex - 1 ? { ...p, isSet: false } : p)));
                setPinIndex(pinIndex - 1);
            }

            applyDamage(8 + Math.min(18, distance * 0.9));
        }
    }, [gameState, pins, pinIndex, settings, finish, applyDamage, triggerShake]);

    // controls
    useEffect(() => {
        const handleKeyDown = (e: KeyboardEvent) => {
            if (gameState !== 'playing') return;

            if (e.code === 'KeyW' || e.code === 'ArrowUp') {
                e.preventDefault();
                pushDirRef.current = 1;
            } else if (e.code === 'KeyS' || e.code === 'ArrowDown') {
                e.preventDefault();
                pushDirRef.current = -1;
            } else if (e.code === 'Space') {
                e.preventDefault();
                if (!e.repeat) attemptSet();
            } else if (e.code === 'Escape') {
                e.preventDefault();
                finish(false, 'cancelled');
                fetchNui('hideFrame', { name: 'setVisibleLockpick' });
            }
        };

        const handleKeyUp = (e: KeyboardEvent) => {
            if ((e.code === 'KeyW' || e.code === 'ArrowUp') && pushDirRef.current === 1) {
                pushDirRef.current = 0;
            } else if ((e.code === 'KeyS' || e.code === 'ArrowDown') && pushDirRef.current === -1) {
                pushDirRef.current = 0;
            }
        };

        window.addEventListener('keydown', handleKeyDown);
        window.addEventListener('keyup', handleKeyUp);
        return () => {
            window.removeEventListener('keydown', handleKeyDown);
            window.removeEventListener('keyup', handleKeyUp);
        };
    }, [gameState, attemptSet, finish]);

    useEffect(() => {
        return () => {
            if (timerRef.current) clearInterval(timerRef.current);
            if (shakeTimeoutRef.current) clearTimeout(shakeTimeoutRef.current);
        };
    }, []);

    const formatTime = (ms: number) => {
        const seconds = Math.floor(ms / 1000);
        const tenths = Math.floor((ms % 1000) / 100);
        return `${seconds}.${tenths}s`;
    };

    if (!isVisible) return null;

    const timePct = config.timeLimit > 0 ? (timeRemaining / config.timeLimit) * 100 : 0;
    const pickCenterRem = pinIndex * (CHAMBER_W_REM + CHAMBER_GAP_REM) + CHAMBER_W_REM / 2;

    const currentPin = pins[pinIndex];
    const currentSeam = currentPin ? frame.raise + frame.tremor + currentPin.keyLength : 0;
    const currentDistance = currentPin ? Math.abs(currentSeam - SHEAR_LINE) : 100;
    const inZone = gameState === 'playing' && currentDistance <= settings.tolerance;
    const nearZone = gameState === 'playing' && !inZone && currentDistance <= settings.tolerance * 2;

    return (
        <div className={mg.container}>
            <div className={mg.overlay} />
            <div className={mg.panel}>
                <div className={mg.head}>
                    <span className={mg.badge}>{t('lockpick')}</span>
                    <span className={mg.diff} style={{ color: difficultyColors[config.difficulty] }}>
                        {t(config.difficulty)}
                    </span>
                </div>

                <div className={`${mg.card} ${shake ? styles.shake : ''}`}>
                    <div className={styles.chamberArea}>
                        <div
                            className={`${styles.shearLine} ${inZone ? styles.shearAligned : ''}`}
                            style={{ bottom: `${SHEAR_LINE}%` }}
                        />
                        <div className={styles.chambers}>
                            {pins.map((pin, i) => {
                                const isCurrent = i === pinIndex && gameState === 'playing' && !pin.isSet;
                                const raise = pin.isSet
                                    ? SHEAR_LINE - pin.keyLength
                                    : isCurrent
                                        ? Math.max(0, frame.raise + frame.tremor)
                                        : 0;
                                const seam = raise + pin.keyLength;

                                return (
                                    <div
                                        key={i}
                                        className={[
                                            styles.chamber,
                                            isCurrent ? styles.active : '',
                                            isCurrent && nearZone ? styles.nearZone : '',
                                            isCurrent && inZone ? styles.inZone : '',
                                            pin.isSet ? styles.set : ''
                                        ].join(' ')}
                                    >
                                        <div
                                            className={styles.spring}
                                            style={{
                                                bottom: `${seam + DRIVER_LENGTH}%`,
                                                height: `${100 - seam - DRIVER_LENGTH}%`
                                            }}
                                        />
                                        <div
                                            className={styles.driverPin}
                                            style={{ bottom: `${seam}%`, height: `${DRIVER_LENGTH}%` }}
                                        />
                                        <div
                                            className={`${styles.keyPin} ${isCurrent && inZone ? styles.keyPinZone : ''} ${pin.isSet ? styles.keyPinSet : ''}`}
                                            style={{ bottom: `${raise}%`, height: `${pin.keyLength}%` }}
                                        />
                                    </div>
                                );
                            })}
                        </div>

                        {gameState === 'playing' && pins.length > 0 && (
                            <>
                                <div
                                    className={styles.pickShaft}
                                    style={{ width: `${0.8 + pickCenterRem}rem` }}
                                />
                                <div
                                    className={styles.pickTip}
                                    style={{
                                        left: `${pickCenterRem - 0.1}rem`,
                                        height: `${PICK_BASE_REM + (Math.max(0, frame.raise + frame.tremor) / 100) * CHAMBER_REM}rem`
                                    }}
                                />
                            </>
                        )}
                    </div>

                    <div className={styles.dots}>
                        {pins.map((pin, i) => (
                            <span
                                key={i}
                                className={[
                                    styles.dot,
                                    pin.isSet ? styles.dotSet : '',
                                    i === pinIndex && gameState === 'playing' && !pin.isSet ? styles.dotActive : ''
                                ].join(' ')}
                            />
                        ))}
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
                    <div className={mg.barRow}>
                        <div className={mg.barHead}>
                            <span className={mg.barLabel}>{t('durability')}</span>
                            <span className={`${mg.barValue} ${health < 30 ? mg.danger : ''}`}>
                                {Math.ceil(health)}%
                            </span>
                        </div>
                        <div className={mg.bar}>
                            <div
                                className={mg.barFill}
                                style={{
                                    width: `${health}%`,
                                    background: health > 50 ? '#6366f1' : health > 25 ? '#fbbf24' : '#ef4444'
                                }}
                            />
                        </div>
                    </div>
                </div>

                <div className={mg.hints}>
                    <span className={mg.hint}><span className={mg.hintKey}>{t('push_keys')}</span> {t('push')}</span>
                    <span className={mg.hint}><span className={mg.hintKey}>{t('set_key')}</span> {t('set')}</span>
                    <span className={mg.hint}><span className={mg.hintKey}>{t('cancel_key')}</span> {t('cancel')}</span>
                </div>

                {gameState === 'success' && (
                    <div className={mg.resultOverlay}>
                        <div className={mg.resultCard}>
                            <div className={`${mg.resultTitle} ${mg.ok}`}>{t('unlocked')}</div>
                            <div className={mg.resultSub}>{t('lock_success')}</div>
                        </div>
                    </div>
                )}

                {gameState === 'failed' && (
                    <div className={mg.resultOverlay}>
                        <div className={mg.resultCard}>
                            <div className={`${mg.resultTitle} ${mg.bad}`}>{t('failed')}</div>
                            <div className={mg.resultSub}>{t(failMessages[failReason])}</div>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
};

export default Lockpick;
