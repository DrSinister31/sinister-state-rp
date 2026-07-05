import React, { useState, useEffect, useCallback, useRef } from 'react';

interface ForecastItem {
  time: string;
  weather: string;
  weatherName: string;
  temp: number;
}

interface WeatherData {
  weather: string;
  weatherName: string;
  temp: number;
  zone: string;
  windSpeed: number;
  windDir: string;
  humidity: number;
  alert: string | null;
  time: string;
  sunrise: string;
  sunset: string;
  isNight: boolean;
  forecast: ForecastItem[];
}

interface TimeData {
  time: string;
  sunrise: string;
  sunset: string;
  hour: number;
  minute: number;
  isNight: boolean;
}

const WEATHER_ICONS: Record<string, string> = {
  EXTRASUNNY: 'sun',
  CLEAR: 'sun',
  CLOUDS: 'cloud',
  OVERCAST: 'cloud',
  RAIN: 'rain',
  THUNDER: 'thunder',
  CLEARING: 'sun',
  SNOW: 'snow',
  BLIZZARD: 'snow',
  SNOWLIGHT: 'snow',
  XMAS: 'snow',
  HALLOWEEN: 'fog',
  FOG: 'fog',
  WIND: 'wind',
};

const ZONE_NAMES: Record<string, string> = {
  houston: 'Houston',
  fortworth: 'Fort Worth',
  killeen: 'Killeen',
  wilderness: 'Texas Wilderness',
};

const WIND_DIR_MAP: Record<string, number> = {
  N: 0,
  NE: 45,
  E: 90,
  SE: 135,
  S: 180,
  SW: 225,
  W: 270,
  NW: 315,
};

const SunIcon: React.FC<{ animate?: boolean }> = ({ animate = true }) => (
  <svg
    viewBox="0 0 64 64"
    width="80"
    height="80"
    className={animate ? 'weather-icon-sun' : ''}
  >
    <style>
      {`
        .weather-icon-sun {
          animation: sunPulse 3s ease-in-out infinite;
        }
        @keyframes sunPulse {
          0%, 100% { opacity: 0.9; transform: scale(1); }
          50% { opacity: 1; transform: scale(1.05); }
        }
        .weather-icon-sun-rays {
          animation: sunRotate 20s linear infinite;
          transform-origin: 32px 32px;
        }
        @keyframes sunRotate {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
      `}
    </style>
    <circle cx="32" cy="32" r="14" fill="#BF5700" opacity="0.9" />
    <g className="weather-icon-sun-rays" stroke="#BF5700" strokeWidth="2.5" strokeLinecap="round" opacity="0.6">
      {[...Array(8)].map((_, i) => {
        const angle = (i * 45 * Math.PI) / 180;
        return (
          <line
            key={i}
            x1={32 + 20 * Math.cos(angle)}
            y1={32 + 20 * Math.sin(angle)}
            x2={32 + 25 * Math.cos(angle)}
            y2={32 + 25 * Math.sin(angle)}
          />
        );
      })}
    </g>
  </svg>
);

const CloudIcon: React.FC<{ heavy?: boolean }> = ({ heavy = false }) => (
  <svg viewBox="0 0 64 64" width="80" height="80">
    <style>
      {`
        .weather-icon-cloud { animation: cloudFloat 4s ease-in-out infinite; }
        @keyframes cloudFloat {
          0%, 100% { transform: translateY(0); }
          50% { transform: translateY(-3px); }
        }
      `}
    </style>
    <g className="weather-icon-cloud" fill={heavy ? '#666' : '#888'} opacity={heavy ? 0.8 : 0.7}>
      <ellipse cx="28" cy="28" rx="16" ry="10" />
      <ellipse cx="38" cy="24" rx="14" ry="9" />
      {heavy ? (
        <>
          <ellipse cx="33" cy="32" rx="18" ry="8" />
          <ellipse cx="30" cy="37" rx="20" ry="7" />
        </>
      ) : (
        <ellipse cx="33" cy="32" rx="18" ry="8" />
      )}
    </g>
  </svg>
);

const RainIcon: React.FC = () => (
  <svg viewBox="0 0 64 64" width="80" height="80">
    <style>
      {`
        .weather-icon-rain-drop { animation: rainFall 1.5s linear infinite; }
        .weather-icon-rain-drop:nth-child(2) { animation-delay: 0.2s; }
        .weather-icon-rain-drop:nth-child(3) { animation-delay: 0.5s; }
        .weather-icon-rain-drop:nth-child(4) { animation-delay: 0.8s; }
        @keyframes rainFall {
          0% { opacity: 0; transform: translateY(-8px); }
          30% { opacity: 0.8; }
          100% { opacity: 0; transform: translateY(12px); }
        }
      `}
    </style>
    <g fill="#7799bb" opacity="0.7">
      <ellipse cx="30" cy="20" rx="18" ry="10" />
      <ellipse cx="38" cy="18" rx="14" ry="8" />
    </g>
    <g stroke="#7799bb" strokeWidth="1.5" opacity="0.6">
      <line className="weather-icon-rain-drop" x1="20" y1="34" x2="17" y2="40" />
      <line className="weather-icon-rain-drop" x1="28" y1="34" x2="25" y2="40" />
      <line className="weather-icon-rain-drop" x1="36" y1="34" x2="33" y2="40" />
      <line className="weather-icon-rain-drop" x1="44" y1="34" x2="41" y2="40" />
    </g>
  </svg>
);

const ThunderIcon: React.FC = () => (
  <svg viewBox="0 0 64 64" width="80" height="80">
    <style>
      {`
        .weather-icon-thunder-bolt { animation: thunderFlash 1.5s ease-in-out infinite; }
        @keyframes thunderFlash {
          0%, 90%, 100% { opacity: 0.4; }
          92%, 96% { opacity: 1; }
        }
      `}
    </style>
    <g fill="#555" opacity="0.8">
      <ellipse cx="28" cy="18" rx="18" ry="10" />
      <ellipse cx="38" cy="16" rx="14" ry="8" />
    </g>
    <polygon
      className="weather-icon-thunder-bolt"
      points="32,28 26,38 30,38 24,50 38,34 34,34 40,24 36,28"
      fill="#FFB800"
    />
  </svg>
);

const SnowIcon: React.FC = () => (
  <svg viewBox="0 0 64 64" width="80" height="80">
    <style>
      {`
        .weather-icon-snow-flake { animation: snowFall 3s linear infinite; }
        .weather-icon-snow-flake:nth-child(3) { animation-delay: 0.5s; }
        .weather-icon-snow-flake:nth-child(4) { animation-delay: 1s; }
        .weather-icon-snow-flake:nth-child(5) { animation-delay: 1.5s; }
        .weather-icon-snow-flake:nth-child(6) { animation-delay: 2s; }
        @keyframes snowFall {
          0% { opacity: 0; transform: translateY(-6px) translateX(0); }
          20% { opacity: 0.8; }
          100% { opacity: 0; transform: translateY(14px) translateX(4px); }
        }
      `}
    </style>
    <g fill="#aaa" opacity="0.7">
      <ellipse cx="28" cy="18" rx="18" ry="10" />
      <ellipse cx="38" cy="16" rx="14" ry="8" />
    </g>
    <g fill="#fff" opacity="0.6">
      <circle className="weather-icon-snow-flake" cx="18" cy="34" r="2" />
      <circle className="weather-icon-snow-flake" cx="28" cy="40" r="2" />
      <circle cx="38" cy="34" r="2" />
      <circle className="weather-icon-snow-flake" cx="48" cy="40" r="2" />
      <circle className="weather-icon-snow-flake" cx="33" cy="44" r="2" />
    </g>
  </svg>
);

const FogIcon: React.FC = () => (
  <svg viewBox="0 0 64 64" width="80" height="80">
    <style>
      {`
        .weather-icon-fog-line { animation: fogPulse 3s ease-in-out infinite; }
        .weather-icon-fog-line:nth-child(2) { animation-delay: 0.3s; }
        .weather-icon-fog-line:nth-child(3) { animation-delay: 0.6s; }
        .weather-icon-fog-line:nth-child(4) { animation-delay: 0.9s; }
        @keyframes fogPulse {
          0%, 100% { opacity: 0.2; }
          50% { opacity: 0.5; }
        }
      `}
    </style>
    <g fill="#999">
      <rect className="weather-icon-fog-line" x="4" y="20" width="56" height="3" rx="1.5" />
      <rect className="weather-icon-fog-line" x="8" y="27" width="48" height="3" rx="1.5" />
      <rect className="weather-icon-fog-line" x="2" y="34" width="60" height="3" rx="1.5" />
      <rect className="weather-icon-fog-line" x="10" y="41" width="44" height="3" rx="1.5" />
    </g>
  </svg>
);

const WindIcon: React.FC = () => (
  <svg viewBox="0 0 64 64" width="80" height="80">
    <style>
      {`
        .weather-icon-wind-line { animation: windMove 2s ease-in-out infinite; }
        .weather-icon-wind-line:nth-child(2) { animation-delay: 0.3s; }
        .weather-icon-wind-line:nth-child(3) { animation-delay: 0.6s; }
        @keyframes windMove {
          0%, 100% { transform: translateX(0); }
          50% { transform: translateX(4px); }
        }
      `}
    </style>
    <g fill="none" stroke="#999" strokeWidth="2.5" strokeLinecap="round" opacity="0.6">
      <path className="weather-icon-wind-line" d="M8,24 Q20,20 32,24 Q44,28 56,24" />
      <path className="weather-icon-wind-line" d="M12,34 Q24,30 36,34 Q48,38 52,34" />
      <path className="weather-icon-wind-line" d="M16,44 Q24,40 32,44 Q40,48 48,44" />
    </g>
  </svg>
);

const DefaultIcon: React.FC = () => (
  <svg viewBox="0 0 64 64" width="80" height="80">
    <circle cx="32" cy="32" r="16" fill="#BF5700" opacity="0.5" />
    <circle cx="32" cy="32" r="12" fill="#BF5700" opacity="0.7" />
  </svg>
);

function getWeatherIcon(weatherType: string) {
  const iconType = WEATHER_ICONS[weatherType.toUpperCase()] || 'default';

  switch (iconType) {
    case 'sun':
      return <SunIcon />;
    case 'cloud':
      return <CloudIcon heavy={weatherType.toUpperCase() === 'OVERCAST'} />;
    case 'rain':
      return <RainIcon />;
    case 'thunder':
      return <ThunderIcon />;
    case 'snow':
      return <SnowIcon />;
    case 'fog':
      return <FogIcon />;
    case 'wind':
      return <WindIcon />;
    default:
      return <DefaultIcon />;
  }
}

function getSmallWeatherIcon(weatherType: string) {
  const iconType = WEATHER_ICONS[weatherType.toUpperCase()] || 'default';

  switch (iconType) {
    case 'sun':
      return (
        <svg viewBox="0 0 64 64" width="32" height="32">
          <circle cx="32" cy="32" r="14" fill="#BF5700" opacity="0.9" />
          <g stroke="#BF5700" strokeWidth="2" strokeLinecap="round" opacity="0.5">
            {[...Array(8)].map((_, i) => {
              const a = (i * 45 * Math.PI) / 180;
              return <line key={i} x1={32 + 20 * Math.cos(a)} y1={32 + 20 * Math.sin(a)} x2={32 + 25 * Math.cos(a)} y2={32 + 25 * Math.sin(a)} />;
            })}
          </g>
        </svg>
      );
    case 'cloud':
      return (
        <svg viewBox="0 0 64 64" width="32" height="32">
          <g fill="#888" opacity="0.7">
            <ellipse cx="28" cy="28" rx="16" ry="10" />
            <ellipse cx="38" cy="24" rx="14" ry="9" />
            <ellipse cx="33" cy="32" rx="18" ry="8" />
          </g>
        </svg>
      );
    case 'rain':
      return (
        <svg viewBox="0 0 64 64" width="32" height="32">
          <g fill="#7799bb" opacity="0.7">
            <ellipse cx="30" cy="20" rx="18" ry="10" />
            <ellipse cx="38" cy="18" rx="14" ry="8" />
          </g>
          <g stroke="#7799bb" strokeWidth="1.5">
            <line x1="20" y1="34" x2="17" y2="40" />
            <line x1="28" y1="34" x2="25" y2="40" />
            <line x1="36" y1="34" x2="33" y2="40" />
          </g>
        </svg>
      );
    case 'thunder':
      return (
        <svg viewBox="0 0 64 64" width="32" height="32">
          <g fill="#555" opacity="0.8">
            <ellipse cx="28" cy="18" rx="18" ry="10" />
            <ellipse cx="38" cy="16" rx="14" ry="8" />
          </g>
          <polygon points="32,28 26,38 30,38 24,50 38,34 34,34 40,24 36,28" fill="#FFB800" />
        </svg>
      );
    case 'snow':
      return (
        <svg viewBox="0 0 64 64" width="32" height="32">
          <g fill="#aaa" opacity="0.7">
            <ellipse cx="28" cy="18" rx="18" ry="10" />
            <ellipse cx="38" cy="16" rx="14" ry="8" />
          </g>
          <g fill="#fff" opacity="0.6">
            <circle cx="18" cy="34" r="2" />
            <circle cx="28" cy="40" r="2" />
            <circle cx="38" cy="34" r="2" />
          </g>
        </svg>
      );
    case 'fog':
      return (
        <svg viewBox="0 0 64 64" width="32" height="32">
          <g fill="#999" opacity="0.3">
            <rect x="4" y="20" width="56" height="3" rx="1.5" />
            <rect x="8" y="27" width="48" height="3" rx="1.5" />
            <rect x="2" y="34" width="60" height="3" rx="1.5" />
          </g>
        </svg>
      );
    default:
      return (
        <svg viewBox="0 0 64 64" width="32" height="32">
          <circle cx="32" cy="32" r="14" fill="#BF5700" opacity="0.6" />
        </svg>
      );
  }
}

const App: React.FC = () => {
  const [weather, setWeather] = useState<WeatherData | null>(null);
  const [time, setTime] = useState<TimeData | null>(null);
  const [zone, setZone] = useState<string>('houston');
  const [loading, setLoading] = useState<boolean>(false);
  const [fadeIn, setFadeIn] = useState<boolean>(false);
  const mountRef = useRef<boolean>(true);

  const fetchWeather = useCallback(() => {
    setLoading(true);
    fetch('https://cfx-nui-sinister_weather/getWeather', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ zone }),
    })
      .then((r) => r.json())
      .then((data: WeatherData) => {
        if (mountRef.current) {
          setWeather(data);
          setLoading(false);
        }
      })
      .catch(() => {
        if (mountRef.current) setLoading(false);
      });
  }, [zone]);

  const fetchForecast = useCallback(() => {
    fetch('https://cfx-nui-sinister_weather/getForecast', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ zone }),
    })
      .then((r) => r.json())
      .then((data) => {
        if (mountRef.current && data && data.forecast) {
          setWeather((prev) =>
            prev
              ? { ...prev, forecast: data.forecast }
              : null
          );
        }
      })
      .catch(() => {});
  }, [zone]);

  const fetchTime = useCallback(() => {
    fetch('https://cfx-nui-sinister_weather/getTime', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({}),
    })
      .then((r) => r.json())
      .then((data: TimeData) => {
        if (mountRef.current) setTime(data);
      })
      .catch(() => {});
  }, []);

  const handleRefresh = useCallback(() => {
    fetchWeather();
    fetchForecast();
    fetchTime();
  }, [fetchWeather, fetchForecast, fetchTime]);

  useEffect(() => {
    mountRef.current = true;
    fetchWeather();
    fetchForecast();
    fetchTime();

    const interval = setInterval(() => {
      fetchTime();
    }, 30000);

    const fadeTimer = setTimeout(() => setFadeIn(true), 100);

    const handleMessage = (event: MessageEvent) => {
      if (event.data && event.data.type === 'weatherUpdate') {
        setWeather({
          weather: event.data.weather || 'EXTRASUNNY',
          weatherName: event.data.weatherName || 'Sunny',
          temp: event.data.temp || 72,
          zone: event.data.zone || 'houston',
          windSpeed: event.data.windSpeed || 5,
          windDir: event.data.windDir || 'SW',
          humidity: event.data.humidity || 45,
          alert: event.data.alert || null,
          time: time?.time || '12:00',
          sunrise: time?.sunrise || '06:30',
          sunset: time?.sunset || '20:15',
          isNight: time?.isNight || false,
          forecast: event.data.forecast || [],
        });
      }
      if (event.data && event.data.type === 'timeUpdate') {
        setTime((prev) => ({
          ...prev,
          time: event.data.time || prev?.time || '12:00',
          sunrise: event.data.sunrise || prev?.sunrise || '06:30',
          sunset: event.data.sunset || prev?.sunset || '20:15',
          hour: prev?.hour || 12,
          minute: prev?.minute || 0,
          isNight: prev?.isNight || false,
        }));
      }
    };

    window.addEventListener('message', handleMessage);

    return () => {
      mountRef.current = false;
      clearInterval(interval);
      clearTimeout(fadeTimer);
      window.removeEventListener('message', handleMessage);
    };
  }, []);

  const handleZoneChange = (newZone: string) => {
    setZone(newZone);
  };

  if (!weather) {
    return (
      <div style={styles.container}>
        <div style={styles.loadingContainer}>
          <SunIcon animate={false} />
          <div style={styles.loadingText}>Loading weather...</div>
          <div style={styles.spinner} />
        </div>
      </div>
    );
  }

  const windDeg = WIND_DIR_MAP[weather.windDir] || 0;
  const feelsLike = weather.temp - Math.floor(weather.windSpeed / 3);

  return (
    <div
      style={{
        ...styles.container,
        opacity: fadeIn ? 1 : 0,
        transition: 'opacity 0.5s ease-in-out',
      }}
    >
      {weather.alert && (
        <div style={styles.alertBanner}>
          <span style={styles.alertIcon}>&#9888;</span>
          <span style={styles.alertText}>{weather.alert}</span>
        </div>
      )}

      <div style={styles.mainWeather}>
        <div style={styles.mainIcon}>{getWeatherIcon(weather.weather)}</div>
        <div style={styles.mainInfo}>
          <div style={styles.mainTemp}>{weather.temp}°F</div>
          <div style={styles.mainWeatherName}>{weather.weatherName}</div>
          <div style={styles.mainZone}>{ZONE_NAMES[weather.zone] || weather.zone}</div>
        </div>
      </div>

      <div style={styles.detailRow}>
        <span style={styles.detailText}>
          Feels like {feelsLike}°F &middot; Wind {weather.windDir} {weather.windSpeed} mph &middot; Humidity {weather.humidity}%
        </span>
      </div>

      <div style={styles.zoneSelector}>
        {['houston', 'fortworth', 'killeen', 'wilderness'].map((z) => (
          <button
            key={z}
            onClick={() => handleZoneChange(z)}
            style={{
              ...styles.zoneButton,
              borderColor: zone === z ? '#BF5700' : '#333333',
              background: zone === z ? 'rgba(191, 87, 0, 0.15)' : 'transparent',
              color: zone === z ? '#BF5700' : '#888888',
            }}
          >
            {ZONE_NAMES[z]}
          </button>
        ))}
      </div>

      <div style={styles.astroBar}>
        <div style={styles.astroItem}>
          <span style={styles.astroLabel}>&#8593; Sunrise</span>
          <span style={styles.astroValue}>{weather.sunrise}</span>
        </div>
        <div style={styles.astroDivider} />
        <div style={styles.astroItem}>
          <span style={styles.astroLabel}>&#8595; Sunset</span>
          <span style={styles.astroValue}>{weather.sunset}</span>
        </div>
        <div style={styles.astroDivider} />
        <div style={styles.astroItemCenter}>
          <span style={styles.astroLabel}>Wind</span>
          <svg
            viewBox="0 0 24 24"
            width="24"
            height="24"
            style={{ transform: `rotate(${windDeg}deg)` }}
          >
            <path
              d="M12 2 L12 20 M8 10 L12 2 L16 10"
              fill="none"
              stroke="#BF5700"
              strokeWidth="2"
            />
          </svg>
          <span style={styles.windDirText}>{weather.windDir}</span>
        </div>
      </div>

      {weather.forecast && weather.forecast.length > 0 && (
        <div style={styles.forecastSection}>
          <div style={styles.forecastTitle}>3-Hour Forecast</div>
          <div style={styles.forecastScroll}>
            {weather.forecast.slice(0, 6).map((f, i) => (
              <div key={i} style={styles.forecastItem}>
                <div style={styles.forecastTime}>{f.time}</div>
                <div style={styles.forecastIcon}>{getSmallWeatherIcon(f.weather)}</div>
                <div style={styles.forecastTemp}>{f.temp}°</div>
                <div style={styles.forecastName}>{f.weatherName.substring(0, 10)}</div>
              </div>
            ))}
          </div>
        </div>
      )}

      <div style={styles.refreshSection}>
        <button
          onClick={handleRefresh}
          style={{
            ...styles.refreshButton,
            opacity: loading ? 0.6 : 1,
          }}
          disabled={loading}
        >
          {loading ? '⟳ Refreshing...' : '⟳ Refresh'}
        </button>
      </div>
    </div>
  );
};

const styles: Record<string, React.CSSProperties> = {
  container: {
    minHeight: '100vh',
    background: 'linear-gradient(180deg, #1a1a2e 0%, #0d0d14 100%)',
    color: '#ffffff',
    fontFamily: "'Inter', sans-serif",
    padding: '16px',
  },
  loadingContainer: {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: '80vh',
    gap: '16px',
  },
  loadingText: {
    fontSize: '16px',
    color: '#aaaaaa',
  },
  spinner: {
    width: '32px',
    height: '32px',
    border: '3px solid #333333',
    borderTop: '3px solid #BF5700',
    borderRadius: '50%',
    animation: 'spin 1s linear infinite',
  },
  alertBanner: {
    background: 'rgba(255, 60, 30, 0.15)',
    border: '1px solid #ff3c1e',
    borderRadius: '8px',
    padding: '10px 14px',
    marginBottom: '16px',
    display: 'flex',
    alignItems: 'center',
    gap: '8px',
    fontSize: '13px',
    color: '#ff6b4a',
  },
  alertIcon: {
    fontSize: '16px',
  },
  alertText: {
    flex: 1,
  },
  mainWeather: {
    display: 'flex',
    alignItems: 'center',
    gap: '16px',
    marginBottom: '12px',
  },
  mainIcon: {
    flexShrink: 0,
  },
  mainInfo: {
    display: 'flex',
    flexDirection: 'column',
  },
  mainTemp: {
    fontSize: '52px',
    fontWeight: 700,
    color: '#BF5700',
    lineHeight: 1,
  },
  mainWeatherName: {
    fontSize: '16px',
    color: '#cccccc',
    marginTop: '4px',
  },
  mainZone: {
    fontSize: '13px',
    color: '#888888',
    marginTop: '2px',
  },
  detailRow: {
    marginBottom: '16px',
  },
  detailText: {
    fontSize: '13px',
    color: '#aaaaaa',
  },
  zoneSelector: {
    display: 'flex',
    gap: '4px',
    marginBottom: '16px',
  },
  zoneButton: {
    flex: 1,
    padding: '8px 4px',
    borderRadius: '8px',
    border: '1px solid #333333',
    background: 'transparent',
    color: '#888888',
    fontSize: '11px',
    fontFamily: "'Inter', sans-serif",
    cursor: 'pointer',
    transition: 'all 0.2s ease',
  },
  astroBar: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: '14px 0',
    borderTop: '1px solid #222222',
    borderBottom: '1px solid #222222',
    marginBottom: '16px',
  },
  astroItem: {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'flex-start',
  },
  astroItemCenter: {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
  },
  astroLabel: {
    fontSize: '10px',
    color: '#BF5700',
    textTransform: 'uppercase',
    letterSpacing: '0.5px',
    marginBottom: '2px',
  },
  astroValue: {
    fontSize: '15px',
    fontWeight: 600,
    color: '#ffffff',
  },
  astroDivider: {
    width: '1px',
    height: '30px',
    background: '#222222',
  },
  windDirText: {
    fontSize: '10px',
    color: '#aaaaaa',
    marginTop: '2px',
  },
  forecastSection: {
    marginBottom: '16px',
  },
  forecastTitle: {
    fontSize: '14px',
    fontWeight: 600,
    color: '#BF5700',
    marginBottom: '10px',
  },
  forecastScroll: {
    display: 'flex',
    gap: '8px',
    overflowX: 'auto',
    paddingBottom: '8px',
    scrollbarWidth: 'none',
  },
  forecastItem: {
    flexShrink: 0,
    width: '74px',
    textAlign: 'center',
    background: 'rgba(255, 255, 255, 0.03)',
    borderRadius: '10px',
    padding: '10px 4px',
    border: '1px solid #1e1e2e',
  },
  forecastTime: {
    fontSize: '10px',
    color: '#aaaaaa',
    marginBottom: '6px',
  },
  forecastIcon: {
    marginBottom: '4px',
  },
  forecastTemp: {
    fontSize: '14px',
    fontWeight: 600,
    color: '#ffffff',
  },
  forecastName: {
    fontSize: '9px',
    color: '#888888',
    marginTop: '2px',
  },
  refreshSection: {
    textAlign: 'center',
    marginTop: '8px',
  },
  refreshButton: {
    background: '#BF5700',
    color: '#ffffff',
    border: 'none',
    padding: '10px 24px',
    borderRadius: '8px',
    fontSize: '13px',
    fontFamily: "'Inter', sans-serif",
    cursor: 'pointer',
    transition: 'background 0.2s ease',
  },
};

export default App;
