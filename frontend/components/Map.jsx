// components/Map.jsx
'use client';
import React, { useEffect, useState } from 'react';
import { MapContainer, ImageOverlay, Marker, Popup, CircleMarker, Tooltip, Circle, useMapEvents, Polyline } from 'react-leaflet';
import L from 'leaflet';
import { MAP_CONFIG } from '../lib/mapConfig';
import { worldToLatLng, latLngToWorld } from '../lib/markerLogic';

function CoordinateTracker() {
  const [coords, setCoords] = useState(null);
  const [zoom, setZoom] = useState(0);

  const map = useMapEvents({
    mousemove: (e) => {
      const worldCoords = latLngToWorld(e.latlng.lat, e.latlng.lng);
      setCoords(worldCoords);
    },
    zoomend: () => {
      setZoom(map.getZoom());
    }
  });

  const scale = Math.max(0.6, 1 - (zoom * 0.15));

  return (
    <div 
      style={{
        position: 'absolute',
        bottom: '60px',
        left: '20px',
        zIndex: 1000,
        background: 'rgba(15, 15, 15, 0.3)',
        backdropFilter: 'blur(4px)',
        border: '1px solid rgba(139, 0, 0, 0.3)',
        borderRadius: '12px',
        padding: '8px 12px',
        color: 'var(--syn-text)',
        fontFamily: 'Orbitron, sans-serif',
        transform: `scale(${scale})`,
        transformOrigin: 'bottom left',
        transition: 'transform 0.2s ease',
        boxShadow: '0 0 10px rgba(255, 42, 75, 0.3)',
        pointerEvents: 'none',
        userSelect: 'none'
      }}
    >
      <div style={{ fontSize: '9px', color: 'var(--syn-text-muted)', textTransform: 'uppercase', letterSpacing: '1px', marginBottom: '2px' }}>Coordinates</div>
      {coords ? (
        <div style={{ fontWeight: 'bold', fontSize: '14px', textShadow: '0 0 5px rgba(255,42,75,0.8)', whiteSpace: 'nowrap' }}>
          X: {coords.x} <span style={{ opacity: 0.3, margin: '0 4px' }}>|</span> Y: {coords.y}
        </div>
      ) : (
        <div style={{ fontStyle: 'italic', fontSize: '12px', color: '#888' }}>Hover map...</div>
      )}
    </div>
  );
}

// Leaflet styles
import 'leaflet/dist/leaflet.css';
import 'leaflet-defaulticon-compatibility/dist/leaflet-defaulticon-compatibility.css';
import 'leaflet-defaulticon-compatibility';

export default function Map({ isAdmin, userSteamId, shareCode, herdMembers = [], onSelectPlayer, trackerEnabled, activeFilters, recentKills = [] }) {
  const [players, setPlayers] = useState([]);
  const [pois, setPois] = useState(null);

  const backendUrl = process.env.NEXT_PUBLIC_BACKEND_URL || '';

  // Dual-fetch: try backend directly first (lower latency), fallback to Next.js->Supabase proxy
  useEffect(() => {
    const fetchPlayers = async () => {
      const params = `steam_id=${userSteamId || ""}&share_code=${shareCode || ""}&is_admin=${isAdmin}`;

      const fetchWithTimeout = (url, timeoutMs) =>
        new Promise(async (resolve, reject) => {
          const controller = new AbortController();
          const timer = setTimeout(() => { controller.abort(); reject(new Error('timeout')); }, timeoutMs);
          try {
            const res = await fetch(url, { signal: controller.signal });
            clearTimeout(timer);
            if (res.ok) resolve(await res.json());
            else reject(new Error(`HTTP ${res.status}`));
          } catch (e) {
            clearTimeout(timer);
            reject(e);
          }
        });

      try {
        if (backendUrl) {
          const data = await fetchWithTimeout(`${backendUrl}/api/players?${params}`, 1500);
          setPlayers(data);
          return;
        }
      } catch (e) {
        console.debug('Backend fetch unavailable, falling back to proxy:', e.message);
      }

      try {
        const res = await fetch(`/api/players?${params}`);
        if (res.ok) {
          const data = await res.json();
          setPlayers(data);
        }
      } catch (err) {
        console.error('Error fetching live positions:', err);
      }
    };

    fetchPlayers();
    const interval = setInterval(fetchPlayers, 2000);
    return () => clearInterval(interval);
  }, [isAdmin, userSteamId, shareCode, backendUrl]);

  // Load POIs
  useEffect(() => {
    fetch('/data/pois.json')
      .then(res => {
        if (!res.ok) throw new Error('Failed to load POIs');
        return res.json();
      })
      .then(data => setPois(data))
      .catch(err => console.error('POI load error:', err));
  }, []);

  return (
    <div style={{ height: '100%', width: '100%', position: 'relative' }}>
      <MapContainer 
        crs={L.CRS.Simple} 
        bounds={MAP_CONFIG.bounds}
        minZoom={-3}
        maxZoom={3}
        style={{ height: '100%', width: '100%', backgroundColor: '#0f0f0f' }}
        zoomControl={true}
      >
        <ImageOverlay 
          url={MAP_CONFIG.imageUrl} 
          bounds={MAP_CONFIG.bounds} 
        />
        <CoordinateTracker />
        
        {/* Render Players */}
        {players.filter(p => isAdmin || trackerEnabled).map((p) => {
          if (p.position_x === undefined || p.position_y === undefined) return null;
          
          const latLng = worldToLatLng(p.position_x, p.position_y);
          return (
            <React.Fragment key={p.steam_id}>
              {/* Render Player Trail (Only for the user themselves) */}
              {p.steam_id === userSteamId && p.path && p.path.length > 1 && (
                <Polyline 
                  positions={p.path.map(coord => worldToLatLng(coord[0], coord[1]))} 
                  pathOptions={{ color: '#00FFFF', dashArray: '5, 10', weight: 2, opacity: 0.6 }} 
                />
              )}
              {/* Render Player Marker with Diet Specific Dino Icon */}
              {(() => {
                let emoji = '🦖';
                let iconColor = p.is_server_admin ? 'rgba(255, 215, 0, 1)' : 'rgba(255, 50, 50, 0.9)'; // Gold for admin, Red for carni default

                const isHerdMate = herdMembers.length > 0 && herdMembers.some(m => m.steam_id === p.steam_id) && p.steam_id !== userSteamId;
                let iconHtml = '';

                if (p.species) {
                  const s = p.species.toLowerCase();
                  
                  // Try to find the exact image file match
                  const supportedDinos = ['allosaurus', 'beipiaosaurus', 'carnotaurus', 'ceratosaurus', 'deinosuchus', 'diabloceratops', 'dryosaurus', 'gallimimus', 'herrerasaurus', 'hypsilophodon', 'maiasaura', 'omniraptor', 'pachycephalosaurus', 'pteranodon', 'stegosaurus', 'tenontosaurus', 'triceratops'];
                  
                  // Match partial names to real files if possible (e.g. 'carno' -> 'carnotaurus')
                  let exactFile = s;
                  if (s.includes('carno')) exactFile = 'carnotaurus';
                  if (s.includes('cera')) exactFile = 'ceratosaurus';
                  if (s.includes('deino')) exactFile = 'deinosuchus';
                  if (s.includes('herrera')) exactFile = 'herrerasaurus';
                  if (s.includes('omni')) exactFile = 'omniraptor';
                  if (s.includes('ptera')) exactFile = 'pteranodon';
                  if (s.includes('rex')) exactFile = 'tyrannosaurus';
                  if (s.includes('diablo')) exactFile = 'diabloceratops';
                  if (s.includes('stego')) exactFile = 'stegosaurus';
                  if (s.includes('tenon')) exactFile = 'tenontosaurus';
                  if (s.includes('pachy')) exactFile = 'pachycephalosaurus';
                  if (s.includes('galli')) exactFile = 'gallimimus';
                  if (s.includes('dryo')) exactFile = 'dryosaurus';
                  if (s.includes('hypsi')) exactFile = 'hypsilophodon';
                  if (s.includes('beipi')) exactFile = 'beipiaosaurus';
                  if (s.includes('maia')) exactFile = 'maiasaura';
                  if (s.includes('trike')) exactFile = 'triceratops';

                  const herbivores = ['diablo', 'stego', 'tenon', 'pachy', 'galli', 'dryo', 'hypsi', 'beipi', 'maia', 'trike', 'diabloceratops', 'stegosaurus', 'tenontosaurus', 'pachycephalosaurus', 'gallimimus', 'dryosaurus', 'hypsilophodon', 'beipiaosaurus', 'maiasaura', 'triceratops'];
                  const carnivores = ['carno', 'cera', 'deino', 'dilo', 'herrera', 'omni', 'ptera', 'troodon', 'rex', 'carnotaurus', 'ceratosaurus', 'deinosuchus', 'dilophosaurus', 'herrerasaurus', 'omniraptor', 'pteranodon', 'tyrannosaurus'];
                  
                  if (!p.is_server_admin) {
                      if (herbivores.some(h => s.includes(h))) {
                        emoji = '🦕';
                        iconColor = 'rgba(50, 255, 50, 0.9)'; // Green for herbi
                      } else if (carnivores.some(c => s.includes(c))) {
                        emoji = '🦖';
                        iconColor = 'rgba(255, 50, 50, 0.9)'; // Red for carni
                      } else {
                        emoji = '🦎'; // Omni or unknown
                        iconColor = 'rgba(255, 255, 50, 0.9)'; // Yellow
                      }
                  }
                  
                  if (supportedDinos.includes(exactFile)) {
                      const herdExtra = isHerdMate ? 'border: 2px solid cyan; box-shadow: 0 0 8px cyan, 0 0 16px rgba(0,255,255,0.4); animation: herdPulse 1.5s infinite;' : '';
                      iconHtml = `<div style="position:relative;"><img src="/assets/icons/dinos/${exactFile}.png" style="width: 32px; height: 32px; filter: drop-shadow(0px 2px 5px ${iconColor}); transform: scale(1.1); border-radius: 50%; ${p.is_server_admin ? 'border: 2px solid gold; background: rgba(0,0,0,0.5);' : ''} ${herdExtra}" />${p.is_server_admin ? '<div style="position:absolute; top:-10px; right:-10px; font-size:16px; text-shadow:0 0 5px black;">👑</div>' : ''}</div>`;
                  } else {
                      const herdExtra = isHerdMate ? 'border: 2px solid cyan; box-shadow: 0 0 8px cyan, 0 0 16px rgba(0,255,255,0.4); animation: herdPulse 1.5s infinite; border-radius: 50%; padding: 4px;' : '';
                      iconHtml = `<div style="position:relative; font-size: 24px; filter: drop-shadow(0px 2px 4px ${iconColor}); text-align: center; line-height: 28px; ${herdExtra}">${emoji}${p.is_server_admin ? '<div style="position:absolute; top:-10px; right:-10px; font-size:16px; text-shadow:0 0 5px black;">👑</div>' : ''}</div>`;
                  }
                }
                
                return (
                  <Marker 
                    position={latLng}
                    icon={L.divIcon({
                      html: iconHtml,
                      iconSize: [32, 32],
                      iconAnchor: [16, 16],
                      className: 'player-map-icon'
                    })}
                    eventHandlers={{
                      click: () => onSelectPlayer && onSelectPlayer(p),
                    }}
                  >
                    <Popup>
                      <div className="text-black" style={{ color: 'black' }}>
                        <strong>{p.player_name || 'Unknown'} {p.is_server_admin && '👑 (Server Admin)'}</strong><br />
                        Species: {p.species || 'Unknown'}<br />
                        Health: {p.health ? (p.health * 100).toFixed(0) + '%' : 'N/A'}<br />
                        Growth: {p.growth ? (p.growth * 100).toFixed(0) + '%' : 'N/A'}<br />
                        Steam ID: {p.steam_id}
                      </div>
                    </Popup>
                  </Marker>
                );
              })()}
            </React.Fragment>
          );
        })}

        {/* Render POIs */}
        {pois && Object.entries(pois).map(([category, items]) => {
          if (category === '_meta') return null;
          if (!activeFilters[category]) return null;
          
          return items.map((poi, idx) => {
            if (poi.x === undefined || poi.y === undefined) return null;
            const latLng = worldToLatLng(poi.x, poi.y);
            
            // Special handling for 'areas'
            if (category === 'areas') {
              const dangerColors = {
                'Delta': '#11d13b', 'Delta Bay': '#11d13b', 'Forks Plains': '#11d13b',
                'South Plains': '#d11111', 'Eastern Jungle': '#d11111', 'Central Jungle': '#d11111', 'Water Access': '#d11111',
                'Highland': '#d15e11', 'North Plains': '#d15e11', 'Swamps': '#d15e11', 'Northern Jungle': '#d15e11',
                'East Coast': '#d1a811', 'West Coast': '#d1a811', 'Mudflats': '#d1a811', 'North Lake': '#d1a811',
                'North Bay': '#d1a811', 'NE Cape': '#d1a811',
                "Bruno's Volcano": '#dc143c', 'Mokes Port': '#e14db0', 'Eastern Lake': '#2196F3',
                'Pit': '#ff5722', 'Port': '#4CAF50', 'Sandbank Bay': '#FF9800', 'Ridges': '#795548',
                'Tide Pool': '#03A9F4', 'West Rail': '#9C27B0', 'Southern Beach': '#E91E63', 'Radio Tower': '#607D8B',
              };
              const borderColor = dangerColors[poi.name] || '#8a8a8a';
              
              const textIcon = L.divIcon({
                html: `<div style="color: rgba(255,255,255,0.7); font-family: 'Orbitron', sans-serif; font-size: 16px; font-weight: bold; text-shadow: 0 0 5px ${borderColor}, 0 2px 4px #000; text-transform: uppercase; letter-spacing: 0.1em; text-align: center; width: 200px; margin-left: -100px;">${poi.name}</div>`,
                className: '',
                iconSize: [0, 0]
              });

              return (
                <React.Fragment key={`${category}-${idx}`}>
                  <Marker position={latLng} icon={textIcon} interactive={false} />
                </React.Fragment>
              );
            }

            // Try to resolve a custom icon image for the category
            let iconUrl = null;
            let emojiIcon = null;

            // Emoji Mapping for POI Categories
            const EMOJI_MAP = {
              water: '💧',
              drinking_water_river_pond: '💧',
              drinking_water_waterfall: '🌊',
              salt_licks: '🧂',
              sanctuaries: '🌴',
              wallows: '🟤',
              mud_pools: '🟤',
              spawns: '📍',
              caves: '🦇',
              caves_surface: '🦇',
              caves_underwater: '🫧',
              cave_exits_up: '⬆️',
              cave_exits_down: '⬇️',
              migrations: '🐾',
              patrol_zones: '⚔️',
              landmarks: '🗿',
              landmarks_surface: '🗿',
              landmarks_underwater: '⚓',
              mountains: '🏔️',
              tp_points: '🌀',
              air_currents: '💨',
              updrafts: '💨',
              roads: '🛤️',
              trails: '🛤️',
              ditches: '🕳️',
              hoists: '🏗️',
              heat_activity: '🔥',
            };

            if (EMOJI_MAP[category]) {
              emojiIcon = EMOJI_MAP[category];
            } else if (category.startsWith('food_')) {
              let foodType = category.replace('food_', '');
              if (foodType === 'galli') foodType = 'gallimimus';
              if (foodType === 'gastro') foodType = 'gastropod';
              const dinoFoods = ['boar', 'chicken', 'crab', 'deer', 'fish', 'frog', 'gallimimus', 'gastropod', 'goat', 'rabbit', 'taco', 'turtle'];
              const plantFoods = ['agave', 'ash', 'banana', 'brazilnuts', 'cashew', 'chanterelle', 'coconut', 'dulse', 'fiddlehead', 'fireweed', 'jackfruit', 'mango', 'marigold', 'melon', 'orange', 'papaya', 'potato', 'potatovine', 'pumpkin', 'radish', 'redcurrant', 'russula', 'sumac', 'sunchoke', 'trillium'];
              if (dinoFoods.includes(foodType)) iconUrl = `/assets/icons/dinos/${foodType}.png`;
              else if (plantFoods.includes(foodType)) iconUrl = `/assets/icons/food/${foodType}.png`;
            }

            if (iconUrl || emojiIcon) {
              const customIcon = L.divIcon({
                html: iconUrl 
                  ? `<img src="${iconUrl}" style="width: 28px; height: 28px; filter: drop-shadow(0px 2px 3px rgba(0,0,0,0.8)); transform: scale(1.1);" />`
                  : `<div style="font-size: 24px; filter: drop-shadow(0px 2px 3px rgba(0,0,0,0.8)); text-align: center; line-height: 28px;">${emojiIcon}</div>`,
                iconSize: [28, 28],
                iconAnchor: [14, 14],
                className: 'emoji-map-icon'
              });
              return (
                <Marker key={`${category}-${idx}`} position={latLng} icon={customIcon}>
                  <Tooltip direction="top" offset={[0, -12]} opacity={0.9}>
                    <div style={{ textTransform: 'capitalize' }}><strong>{poi.name || category.replace(/_/g, ' ')}</strong></div>
                  </Tooltip>
                </Marker>
              );
            }

            // Simple color mapping for categories without images
            const color = category.includes('sanctuar') ? '#4CAF50' : 
                          category.includes('salt_lick') ? '#FFC107' :
                          category.includes('water') ? '#2196F3' :
                          category.includes('cave') ? '#9C27B0' : '#FF5722';
                          
            return (
              <CircleMarker 
                key={`${category}-${idx}`} 
                center={latLng} 
                radius={6} 
                pathOptions={{ color: '#fff', weight: 1, fillColor: color, fillOpacity: 0.8 }}
              >
                <Tooltip direction="top" offset={[0, -10]} opacity={0.9}>
                  <div style={{ textTransform: 'capitalize' }}>
                    <strong>{poi.name || category.replace(/_/g, ' ')}</strong>
                  </div>
                </Tooltip>
              </CircleMarker>
            );
          });
        })}

        {/* Render Zone Geometry (circles for sanctuaries, migrations, patrols) */}
        {['sanctuaries','migrations','patrol_zones'].map(zoneCategory => {
          if (!pois || !pois[zoneCategory] || !activeFilters[zoneCategory]) return null;

          const zoneColors = {
            sanctuaries: { fill: '#4CAF50', opacity: 0.08, border: '#4CAF50' },
            migrations: { fill: '#FF9800', opacity: 0.06, border: '#FF9800' },
            patrol_zones: { fill: '#03A9F4', opacity: 0.05, border: '#03A9F4' },
          };
          const zc = zoneColors[zoneCategory];

          return pois[zoneCategory].map((zone, idx) => {
            if (zone.type === 'circle' && zone.x && zone.y && zone.rx) {
              const center = worldToLatLng(zone.x, zone.y);
              const radius = Math.max(zone.rx, zone.ry || zone.rx);
              return (
                <Circle key={`zone-${zoneCategory}-${idx}`} center={center} radius={radius}
                  pathOptions={{ color: zc.border, weight: 1, fillColor: zc.fill, fillOpacity: zc.opacity }} >
                  <Tooltip direction="center" opacity={0.9}>
                    <div style={{ color: 'black' }}><strong>{zone.name}</strong><br/>{zoneCategory.replace('_',' ')}</div>
                  </Tooltip>
                </Circle>
              );
            }
            if (zone.type === 'path' && zone.points?.length >= 3) {
              const positions = zone.points.map(p => worldToLatLng(p[0], p[1]));
              return (
                <Polyline key={`zone-${zoneCategory}-${idx}`} positions={positions}
                  pathOptions={{ color: zc.border, weight: 1, dashArray: '4 8', fillColor: zc.fill, fillOpacity: zc.opacity }} >
                  <Tooltip direction="center" opacity={0.9}>
                    <div style={{ color: 'black' }}><strong>{zone.name}</strong><br/>{zoneCategory.replace('_',' ')} polygon</div>
                  </Tooltip>
                </Polyline>
              );
            }
            return null;
          }).filter(Boolean);
        })}

        {/* Heat Map — infrared palette for active zones */}
        {activeFilters.heat_activity && recentKills.map((kill, idx) => {
          if (kill.x === undefined || kill.y === undefined) return null;
          const latLng = worldToLatLng(kill.x, kill.y);
          const age = (Date.now() / 1000) - kill.timestamp;
          const isHot = age < 300;
          const isWarm = age < 900;
          const opacity = Math.max(0.1, 1.0 - (age / 1800));

          const heatColors = isHot ? { fill: '#ff1a1a', border: '#ff4444' }
            : isWarm ? { fill: '#ff6600', border: '#ff9944' }
            : { fill: '#ffaa00', border: '#ffcc66' };

          return (
            <Circle key={`heat-${idx}`} center={latLng} radius={100}
              pathOptions={{ color: heatColors.border, weight: 1, fillColor: heatColors.fill, fillOpacity: opacity * 0.6 }} >
              <Tooltip direction="top" opacity={0.9}>
                <div style={{ color: 'black' }}>
                  <strong>{kill.killer_name}</strong> killed <em>{kill.victim}</em>
                  {isHot ? ' 🔥' : isWarm ? ' 🌡️' : ''} {Math.round(age)}s ago
                </div>
              </Tooltip>
            </Circle>
          );
        })}

      </MapContainer>
    </div>
  );
}