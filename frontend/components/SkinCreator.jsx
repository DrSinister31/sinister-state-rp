import React, { useState, useRef, useEffect, useMemo, Suspense } from 'react';
import { Canvas, useFrame } from '@react-three/fiber';
import { OrbitControls, Environment, ContactShadows, useGLTF, useAnimations, Box } from '@react-three/drei';
import * as THREE from 'three';
import { Store, Paintbrush, Send, Camera, Volume2, ArrowDownCircle, Info } from 'lucide-react';
import { getSupabase } from '@/lib/supabaseClient';
import { useSession, signIn } from 'next-auth/react';

// ==========================================
// DINOSAUR ROSTER
// ==========================================
const DINOSAURS = [
  // PLAYABLE
  { id: 'Omniraptor', name: 'Omniraptor', playable: true },
  { id: 'Carnotaurus', name: 'Carnotaurus', playable: true },
  { id: 'Stegosaurus', name: 'Stegosaurus', playable: true },
  { id: 'Deinosuchus', name: 'Deinosuchus', playable: true },
  { id: 'Ceratosaurus', name: 'Ceratosaurus', playable: true },
  { id: 'Tenontosaurus', name: 'Tenontosaurus', playable: true },
  { id: 'Gallimimus', name: 'Gallimimus', playable: true },
  { id: 'Dryosaurus', name: 'Dryosaurus', playable: true },
  { id: 'Pteranodon', name: 'Pteranodon', playable: true },
  { id: 'Beipiaosaurus', name: 'Beipiaosaurus', playable: true },
  { id: 'Dilophosaurus', name: 'Dilophosaurus', playable: true },
  { id: 'Herrerasaurus', name: 'Herrerasaurus', playable: true },
  { id: 'Troodon', name: 'Troodon', playable: true },
  { id: 'Pachycephalosaurus', name: 'Pachycephalosaurus', playable: true },
  { id: 'Hypsilophodon', name: 'Hypsilophodon', playable: true },
  { id: 'Diablo', name: 'Diabloceratops', playable: true },
  { id: 'TRex', name: 'Tyrannosaurus Rex', playable: true },
  { id: 'Triceratops', name: 'Triceratops', playable: true },
  { id: 'Maiasaura', name: 'Maiasaura', playable: true },
  { id: 'Allosaurus', name: 'Allosaurus', playable: true },
  
  // UNPLAYABLE (WIP)
  { id: 'Spinosaurus', name: 'Spinosaurus', playable: false },
  { id: 'Ankylosaurus', name: 'Ankylosaurus', playable: false },
  { id: 'Brachiosaurus', name: 'Brachiosaurus', playable: false },
  { id: 'Puertasaurus', name: 'Puertasaurus', playable: false },
  { id: 'Baryonyx', name: 'Baryonyx', playable: false },
  { id: 'Albertosaurus', name: 'Albertosaurus', playable: false },
  { id: 'Acrocanthosaurus', name: 'Acrocanthosaurus', playable: false }
];

// ==========================================
// SHADER LOGIC
// ==========================================
const applySinisterShader = (mat, uniforms) => {
  mat.onBeforeCompile = (shader) => {
    mat.userData.shader = shader;
    shader.uniforms.baseColor = uniforms.baseColor;
    shader.uniforms.detailColor = uniforms.detailColor;
    shader.uniforms.pattern1Color = uniforms.pattern1Color;
    shader.uniforms.pattern2Color = uniforms.pattern2Color;
    shader.uniforms.patternType = uniforms.patternType;
    
    shader.vertexShader = `
      varying vec2 vMyUv;
      ${shader.vertexShader}
    `.replace(
      `#include <uv_vertex>`,
      `#include <uv_vertex>\n vMyUv = uv;`
    );
    
    shader.fragmentShader = `
      uniform vec3 baseColor;
      uniform vec3 detailColor;
      uniform vec3 pattern1Color;
      uniform vec3 pattern2Color;
      uniform int patternType;
      varying vec2 vMyUv;
      
      vec3 permute(vec3 x) { return mod(((x*34.0)+1.0)*x, 289.0); }
      float snoise(vec2 v){
        const vec4 C = vec4(0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439);
        vec2 i  = floor(v + dot(v, C.yy) );
        vec2 x0 = v -   i + dot(i, C.xx);
        vec2 i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
        vec4 x12 = x0.xyxy + C.xxzz;
        x12.xy -= i1;
        i = mod(i, 289.0);
        vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 )) + i.x + vec3(0.0, i1.x, 1.0 ));
        vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
        m = m*m; m = m*m;
        vec3 x = 2.0 * fract(p * C.www) - 1.0;
        vec3 h = abs(x) - 0.5;
        vec3 ox = floor(x + 0.5);
        vec3 a0 = x - ox;
        m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
        vec3 g;
        g.x  = a0.x  * x0.x  + h.x  * x0.y;
        g.yz = a0.yz * x12.xz + h.yz * x12.yw;
        return 130.0 * dot(m, g);
      }
      
      ${shader.fragmentShader}
    `.replace(
      `vec4 diffuseColor = vec4( diffuse, opacity );`,
      `
      float detailMask = step(0.4, snoise(vMyUv * 15.0));
      float pat1Mask = 0.0;
      float pat2Mask = 0.0;
      
      if (patternType == 0) {
          pat1Mask = step(0.6, snoise(vMyUv * 25.0 + snoise(vMyUv * 5.0)));
          pat2Mask = step(0.8, snoise(vMyUv * 60.0));
      } else if (patternType == 1) {
          pat1Mask = step(0.2, sin(vMyUv.x * 50.0 + snoise(vMyUv * 10.0) * 2.0));
          pat2Mask = step(0.7, snoise(vMyUv * 30.0));
      } else if (patternType == 2) {
          vec2 grid = fract(vMyUv * 20.0 + snoise(vMyUv * 5.0) * 0.2) - 0.5;
          float dist = length(grid);
          pat1Mask = step(dist, 0.3);
          pat2Mask = step(0.2, dist) * step(dist, 0.4);
      } else if (patternType == 3) {
          pat1Mask = step(0.9, fract(vMyUv.x * 40.0)) + step(0.9, fract(vMyUv.y * 40.0));
          pat2Mask = step(0.5, snoise(vMyUv * 80.0));
          pat1Mask = clamp(pat1Mask, 0.0, 1.0);
      }
      
      vec3 finalColor = baseColor;
      finalColor = mix(finalColor, detailColor, detailMask);
      finalColor = mix(finalColor, pattern1Color, pat1Mask);
      finalColor = mix(finalColor, pattern2Color, pat2Mask);
      
      vec4 diffuseColor = vec4( finalColor, opacity );
      `
    );
  };
};

// ==========================================
// RED CUBE PLACEHOLDER
// ==========================================
const RedCube = ({ colors }) => {
  const materialRef = useRef();
  const uniforms = useMemo(() => ({
    baseColor: { value: new THREE.Color(colors.base || '#8b0000') },
    detailColor: { value: new THREE.Color(colors.detail || '#000000') },
    pattern1Color: { value: new THREE.Color(colors.pattern1 || '#000000') },
    pattern2Color: { value: new THREE.Color(colors.pattern2 || '#000000') },
    patternType: { value: colors.patternType || 0 }
  }), []);

  useFrame(() => {
    if (materialRef.current && materialRef.current.userData.shader) {
      materialRef.current.userData.shader.uniforms.baseColor.value.set(colors.base);
      materialRef.current.userData.shader.uniforms.detailColor.value.set(colors.detail);
      materialRef.current.userData.shader.uniforms.pattern1Color.value.set(colors.pattern1);
      materialRef.current.userData.shader.uniforms.pattern2Color.value.set(colors.pattern2);
      materialRef.current.userData.shader.uniforms.patternType.value = colors.patternType || 0;
    }
  });

  const material = useMemo(() => {
    const mat = new THREE.MeshPhysicalMaterial({ roughness: 0.6, metalness: 0.1 });
    applySinisterShader(mat, uniforms);
    return mat;
  }, [uniforms]);

  return (
    <Box args={[1, 1, 1]} position={[0, 0, 0]} castShadow>
      <primitive object={material} attach="material" ref={materialRef} />
    </Box>
  );
};

// ==========================================
// DINO MESH COMPONENT
// ==========================================
const DinoMesh = ({ colors, species }) => {
  // If useGLTF fails (file doesn't exist), ErrorBoundary catches it and renders RedCube
  const gltf = useGLTF(`/models/${species}.glb`);
  const { actions } = useAnimations(gltf.animations || [], gltf.scene);
  
  const materialRefs = useRef([]);

  const uniforms = useMemo(() => ({
    baseColor: { value: new THREE.Color(colors.base || '#000000') },
    detailColor: { value: new THREE.Color(colors.detail || '#000000') },
    pattern1Color: { value: new THREE.Color(colors.pattern1 || '#000000') },
    pattern2Color: { value: new THREE.Color(colors.pattern2 || '#000000') },
    patternType: { value: colors.patternType || 0 }
  }), []);

  useFrame(() => {
    materialRefs.current.forEach(mat => {
      if (mat && mat.userData.shader) {
        mat.userData.shader.uniforms.baseColor.value.set(colors.base);
        mat.userData.shader.uniforms.detailColor.value.set(colors.detail);
        mat.userData.shader.uniforms.pattern1Color.value.set(colors.pattern1);
        mat.userData.shader.uniforms.pattern2Color.value.set(colors.pattern2);
        mat.userData.shader.uniforms.patternType.value = colors.patternType || 0;
      }
    });
  });

  useEffect(() => {
    // Apply shader to all meshes
    materialRefs.current = [];
    gltf.scene.traverse((child) => {
      if (child.isMesh) {
        // Temporarily bypassing the custom shader so we can actually see the real dinosaur textures first!
        // const mat = child.material.clone();
        // applySinisterShader(mat, uniforms);
        // child.material = mat;
        // materialRefs.current.push(mat);
      }
    });
    
    // Play Animation
    if (actions && Object.keys(actions).length > 0) {
      const defaultAction = Object.values(actions)[0];
      defaultAction.play();
    }
  }, [gltf.scene, uniforms, actions]);

  // Unreal Engine models are scaled in cm (1 unit = 1cm). A TRex is massive, so we need to scale it down heavily!
  return <primitive object={gltf.scene} scale={[0.015, 0.015, 0.015]} position={[0, -1.5, 0]} />;
};

class ModelErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false };
  }
  static getDerivedStateFromError(error) {
    return { hasError: true };
  }
  componentDidUpdate(prevProps) {
    if (prevProps.species !== this.props.species) {
      this.setState({ hasError: false });
    }
  }
  render() {
    if (this.state.hasError || !this.props.playable) {
      return (
        <Suspense fallback={null}>
          <RedCube colors={this.props.colors} />
        </Suspense>
      );
    }
    return this.props.children;
  }
}

// ==========================================
// MAIN UI COMPONENT
// ==========================================
export default function SkinCreatorEngine() {
  const { data: session } = useSession();
  const [userProfile, setUserProfile] = useState(null);
  const [appMode, setAppMode] = useState('studio'); 
  const [colors, setColors] = useState({
    base: '#4a5d23', detail: '#2d3816', pattern1: '#8b0000', pattern2: '#ff8c00', patternType: 0
  });
  
  const [dinoSpecies, setDinoSpecies] = useState('Omniraptor');
  
  // Storage for submitted skins
  const [submitForm, setSubmitForm] = useState({ skinName: '', thumbnail: '' });
  const [submitting, setSubmitting] = useState(false);
  const [storeSkins, setStoreSkins] = useState([]);
  // Original Code Tracking
  const [originalImportCode, setOriginalImportCode] = useState('');
  
  const audioRef = useRef(null);
  
  useEffect(() => {
    async function fetchProfile() {
      if (session?.user?.id) {
        try {
          const res = await fetch(`/api/discord_link/${session.user.id}`);
          if (res.ok) {
            const data = await res.json();
            if (data.steam_id) setUserProfile({ steam_id: data.steam_id });
          }
        } catch {}
      }
    }
    fetchProfile();
  }, [session]);

  useEffect(() => {
    if (appMode === 'marketplace') fetchSkins();
  }, [appMode, userProfile]);

  const fetchSkins = async () => {
    if (!userProfile?.steam_id) return;
    const supabase = getSupabase();
    const { data } = await supabase.from('approved_skins').select('*').eq('steam_id', userProfile.steam_id);
    if (data) setStoreSkins(data);
  };

  const handleColorChange = (channel, value) => {
    setColors(prev => ({ ...prev, [channel]: value }));
  };

  const playBroadcast = () => {
    if (audioRef.current) {
      audioRef.current.currentTime = 0;
      audioRef.current.play().catch(e => console.log("Audio play failed (maybe browser autoplay blocked)"));
    }
  };

  const takeScreenshot = () => {
    const canvas = document.querySelector('canvas');
    if (canvas) {
      setSubmitForm(prev => ({ ...prev, thumbnail: canvas.toDataURL('image/png') }));
    }
  };

  // Parser to intercept raw UE FVectors
  const parseImportCode = (code) => {
    setOriginalImportCode(code); // Keep their original code
    
    // Check if it's our JSON format first
    try {
      if(code.includes('SinisterSkin::')) {
        const jsonString = code.trim().replace('SinisterSkin::', '');
        const decoded = JSON.parse(jsonString);
        if (decoded.colors) setColors(decoded.colors);
        if (decoded.species) setDinoSpecies(decoded.species);
        return;
      }
      
      // Attempt to parse raw UE FVector format like: (R=0.5, G=0.1, B=0.9, A=1.0)
      // This is a simplified regex extractor that looks for R=, G=, B=
      const rMatch = code.match(/R=([0-9.]+)/i);
      const gMatch = code.match(/G=([0-9.]+)/i);
      const bMatch = code.match(/B=([0-9.]+)/i);
      
      if (rMatch && gMatch && bMatch) {
         const r = Math.floor(parseFloat(rMatch[1]) * 255);
         const g = Math.floor(parseFloat(gMatch[1]) * 255);
         const b = Math.floor(parseFloat(bMatch[1]) * 255);
         const hex = `#${r.toString(16).padStart(2, '0')}${g.toString(16).padStart(2, '0')}${b.toString(16).padStart(2, '0')}`;
         
         // Apply it to base for demonstration, in a real scenario we'd parse multiple vectors for multiple channels
         setColors(prev => ({ ...prev, base: hex }));
         alert("Detected and translated Unreal FVector to Hex!");
      }
    } catch (err) {
      console.error("Invalid skin code");
    }
  };

  // Generate 4-6 digit alphanumeric short code
  const generateShortCode = () => {
    return Math.random().toString(36).substring(2, 8).toUpperCase();
  };

  const submitToMarketplace = async () => {
    if (!session || !userProfile?.steam_id) {
      alert("You must connect your Discord account to save creations.");
      return;
    }
    if (!submitForm.skinName || !submitForm.thumbnail) {
      alert("Please fill in the skin name and generate a thumbnail screenshot!");
      return;
    }
    
    setSubmitting(true);
    try {
      const supabase = getSupabase();
      const shortCode = generateShortCode();
      const skinData = { colors, species: dinoSpecies, version: 2 };
      
      const { error } = await supabase.from('approved_skins').insert({
        discord_username: session.user.name,
        steam_id: userProfile.steam_id,
        skin_name: submitForm.skinName,
        species: dinoSpecies,
        price: 10000,
        skin_data: `SinisterSkin::${JSON.stringify(skinData)}`,
        thumbnail_base64: submitForm.thumbnail,
        is_approved: false,
        original_code: originalImportCode,
        short_code: shortCode
      });
      
      if (error) throw error;
      alert(`Skin submitted for approval!\n\nYour Original Code was saved.\nYour new Share Code will be: ${shortCode} (Hidden until approved)`);
      setSubmitForm({ skinName: '', thumbnail: '' });
      setAppMode('marketplace');
    } catch (e) {
      alert("Error saving skin: " + e.message);
    }
    setSubmitting(false);
  };
  
  // Drag Drop logic for both Thumbnails and Text Files
  const handleDrop = (e) => {
    e.preventDefault(); e.stopPropagation();
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      const file = e.dataTransfer.files[0];
      
      if (file.type.startsWith('image/')) {
        const reader = new FileReader();
        reader.onload = (ev) => {
          setSubmitForm(prev => ({ ...prev, thumbnail: ev.target.result }));
        };
        reader.readAsDataURL(file);
      } else {
        const reader = new FileReader();
        reader.onload = (event) => {
          parseImportCode(event.target.result);
        };
        reader.readAsText(file);
      }
    }
  };

  const activeDino = DINOSAURS.find(d => d.id === dinoSpecies);

  return (
    <div className="relative w-full h-full flex overflow-hidden bg-black pt-[60px]" onDragOver={e => e.preventDefault()} onDrop={handleDrop}>
      <div className="vignette-overlay"></div>
      
      <audio ref={audioRef} src={`/audio/${dinoSpecies}.mp3`} preload="auto" />

      {/* 3D VIEWER */}
      <div className="flex-1 h-full relative cursor-move z-0">
        <Canvas shadows camera={{ position: [3, 2, 4], fov: 45 }} gl={{ preserveDrawingBuffer: true }}>
          <color attach="background" args={['#0f0f0f']} />
          <ambientLight intensity={0.5} />
          <spotLight position={[10, 10, 10]} angle={0.15} penumbra={1} intensity={1} castShadow />
          
          <Suspense fallback={null}>
            <ModelErrorBoundary species={dinoSpecies} colors={colors} playable={activeDino?.playable}>
              <DinoMesh colors={colors} species={dinoSpecies} />
            </ModelErrorBoundary>
          </Suspense>
          
          <ContactShadows resolution={1024} scale={10} blur={2} opacity={0.5} far={10} color="#000000" />
          <OrbitControls minPolarAngle={0} maxPolarAngle={Math.PI / 2 + 0.1} />
          <Environment preset="city" />
        </Canvas>
        
        {/* Navigation & Controls */}
        <div className="absolute top-4 left-4 flex gap-2">
          <button onClick={() => setAppMode('studio')} className={`px-4 py-2 rounded-lg font-bold flex items-center gap-2 ${appMode === 'studio' ? 'bg-syn-crimson text-white' : 'bg-black/50 text-gray-400 hover:text-white'}`}>
            <Paintbrush className="w-4 h-4" /> Studio
          </button>
          <button onClick={() => setAppMode('marketplace')} className={`px-4 py-2 rounded-lg font-bold flex items-center gap-2 ${appMode === 'marketplace' ? 'bg-syn-crimson text-white' : 'bg-black/50 text-gray-400 hover:text-white'}`}>
            <Store className="w-4 h-4" /> My Creations
          </button>
        </div>
        
        <div className="absolute bottom-4 left-4 flex gap-2">
           <button onClick={playBroadcast} className="px-4 py-2 rounded-lg bg-black/60 border border-white/10 hover:border-white text-white font-bold flex items-center gap-2">
              <Volume2 className="w-4 h-4" /> Play Broadcast
           </button>
           <button onClick={takeScreenshot} className="px-4 py-2 rounded-lg bg-black/60 border border-white/10 hover:border-white text-white font-bold flex items-center gap-2">
              <Camera className="w-4 h-4" /> Snapshot Thumbnail
           </button>
        </div>
      </div>

      {/* UI PANEL */}
      <div className="w-[350px] h-full overflow-y-auto glass-panel border-l border-white/5 relative z-20 flex flex-col">
        <div className="p-6 flex-1">
          {appMode === 'studio' && (
            <>
              <div className="p-6 space-y-6">
                
                {/* DINOSAUR SELECTOR */}
                <div className="space-y-2">
                  <h2 className="text-sm font-bold text-gray-400 uppercase tracking-wider">Dinosaur Model</h2>
                  <select value={dinoSpecies} onChange={(e) => {
                      setDinoSpecies(e.target.value);
                      setTimeout(playBroadcast, 500); // Play sound on switch
                    }} className="w-full glass-input text-sm">
                    <optgroup label="Playable Models">
                      {DINOSAURS.filter(d => d.playable).map(d => (
                        <option key={d.id} value={d.id} className="bg-syn-charcoal">{d.name}</option>
                      ))}
                    </optgroup>
                    {(userProfile?.is_admin || userProfile?.role === 'admin') && (
                      <optgroup label="Coming Soon... (Red Cube Mode)">
                        {DINOSAURS.filter(d => !d.playable).map(d => (
                          <option key={d.id} value={d.id} className="bg-syn-charcoal text-gray-500">{d.name} (WIP)</option>
                        ))}
                      </optgroup>
                    )}
                  </select>
                </div>

                {/* BASIC COLORS */}
                <div className="space-y-4 pt-4 border-t border-white/10">
                  <div className="flex justify-between items-center mb-4">
                    <span className="text-xs font-bold uppercase tracking-widest text-syn-crimson">Pattern Type</span>
                    <select 
                      value={colors.patternType || 0} 
                      onChange={(e) => handleColorChange('patternType', parseInt(e.target.value))}
                      className="bg-black/50 border border-white/20 rounded p-1 text-xs outline-none"
                    >
                      <option value={0}>PT:A (Standard)</option>
                      <option value={1}>PT:B (Striped)</option>
                      <option value={2}>Custom: Leopard Spots</option>
                      <option value={3}>Custom: Cybernetic</option>
                    </select>
                  </div>
                  {['base', 'detail', 'pattern1', 'pattern2'].map((key) => (
                    <div key={key} className="flex justify-between items-center">
                      <span className="text-xs font-bold uppercase tracking-widest">{key}</span>
                      <input type="color" value={colors[key]} onChange={(e) => handleColorChange(key, e.target.value)} className="w-8 h-8 rounded cursor-pointer" />
                    </div>
                  ))}
                </div>

                {/* IMPORT/DROP ZONE */}
                <div className="pt-4 border-t border-white/10">
                  <div className="border-2 border-dashed border-white/20 rounded-lg p-6 text-center hover:border-syn-crimson transition flex flex-col items-center justify-center bg-black/30">
                    <ArrowDownCircle className="w-8 h-8 text-gray-500 mb-2" />
                    <p className="text-xs text-gray-400">Drag & Drop Files Here</p>
                    <p className="text-[10px] text-gray-500 mt-1">.txt / .json (Vectors) or .png / .jpg (Thumbnail)</p>
                  </div>
                  <div className="pt-4">
                    <input 
                      type="text" 
                      placeholder="Or paste code here..." 
                      className="w-full glass-input text-xs" 
                      onChange={(e) => parseImportCode(e.target.value)}
                    />
                  </div>
                </div>

                {/* SUBMISSION */}
                <div className="space-y-4 pt-4 border-t border-white/10 bg-black/30 p-4 rounded-lg mt-4">
                  <h2 className="text-sm font-bold text-yellow-500 uppercase tracking-wider flex items-center gap-2">
                    <Store className="w-4 h-4" /> Apply for Approval
                  </h2>
                  
                  {!session ? (
                    <button onClick={() => signIn('discord')} className="w-full bg-[#5865F2] hover:bg-[#4752C4] text-white font-bold py-2 rounded flex justify-center items-center gap-2 transition">
                      Connect Discord to Apply
                    </button>
                  ) : (
                    <div className="bg-black/50 p-2 rounded text-xs text-gray-300 flex items-center gap-2">
                       <Info className="w-4 h-4 text-syn-crimson" /> Applying as: <strong className="text-white">{session.user.name}</strong>
                    </div>
                  )}
                  
                  <input type="text" placeholder="Skin Name" value={submitForm.skinName} onChange={e => setSubmitForm({...submitForm, skinName: e.target.value})} className="w-full glass-input text-sm" />
                  
                  {submitForm.thumbnail && (
                    <img src={submitForm.thumbnail} alt="Thumbnail Preview" className="w-full h-24 object-cover rounded border border-white/10" />
                  )}
                  
                  <button onClick={submitToMarketplace} disabled={submitting} className="w-full bg-[#141416] hover:bg-[#8B0000] text-white border border-syn-crimson/50 font-bold py-2 rounded flex justify-center gap-2 transition-all duration-300 hover-glitch shadow-[0_0_15px_rgba(255,26,26,0.2)] hover:shadow-[0_0_25px_rgba(255,26,26,0.6)]">
                    <Send className="w-4 h-4" /> {submitting ? 'Applying...' : 'Submit Application'}
                  </button>
                </div>
              </div>
            </>
          )}

          {appMode === 'marketplace' && (
            <div className="p-6">
              <h1 className="text-2xl font-black text-white mb-6">MY CREATIONS</h1>
              <div className="grid grid-cols-1 gap-4">
                {storeSkins.map(skin => (
                  <div key={skin.id} className="bg-black/60 border border-white/10 rounded-lg overflow-hidden relative">
                    <img src={skin.thumbnail_base64} alt={skin.skin_name} className="w-full h-32 object-cover" />
                    
                    {/* Status Badge */}
                    <div className={`absolute top-2 right-2 px-2 py-1 text-[10px] font-bold rounded uppercase ${skin.is_approved ? 'bg-green-500' : 'bg-yellow-500 text-black'}`}>
                       {skin.is_approved ? 'Approved' : 'Pending'}
                    </div>

                    <div className="p-3">
                      <h3 className="font-bold">{skin.skin_name}</h3>
                      
                      {skin.is_approved ? (
                        <div className="mt-2 p-2 bg-black border border-green-500/30 rounded text-center">
                           <p className="text-[10px] text-gray-400 uppercase tracking-widest mb-1">Share Code</p>
                           <p className="font-mono text-xl text-green-400 font-bold tracking-widest">{skin.short_code}</p>
                        </div>
                      ) : (
                        <div className="mt-2 p-2 bg-black border border-white/10 rounded text-center">
                           <p className="text-[10px] text-gray-500 uppercase">Code hidden until approved</p>
                        </div>
                      )}
                    </div>
                  </div>
                ))}
                {!session && <p className="text-red-400 text-center py-8 font-bold">Please log in with Discord to view your creations.</p>}
                {session && storeSkins.length === 0 && <p className="text-gray-500">You haven't submitted any skins yet.</p>}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
