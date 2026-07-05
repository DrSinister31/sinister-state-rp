'use client';

import React, { useRef, useMemo } from 'react';
import { Canvas, useFrame } from '@react-three/fiber';
import { OrbitControls, Environment, ContactShadows, useGLTF, useTexture, Html } from '@react-three/drei';
import * as THREE from 'three';
import { vectorStringToHex } from '../utils/color';

const ALL_MODELS = [
  'Omniraptor', 'Carnotaurus', 'Tyrannosaurus', 'Ceratosaurus',
  'Allosaurus', 'Deinosuchus', 'Troodon', 'Pteranodon',
  'Dilophosaurus', 'Herrerasaurus', 'Diabloceratops', 'Stegosaurus',
  'Gallimimus', 'Dryosaurus', 'Tenontosaurus', 'Hypsilophodon',
  'Maiasaura', 'Pachycephalosaurus', 'Beipiaosaurus',
  'Austroraptor', 'Kentrosaurus', 'Triceratops',
  'Baryonyx', 'Oviraptor', 'Quetzalcoatlus', 'Parasaurolophus', 'Avaceratops',
];

// Preload all models in parallel batches of 3 (don't flood the browser)
function preloadAllModels() {
  if (!useGLTF.preload) return;
  const BATCH = 3;
  let i = 0;
  function next() {
    const slice = ALL_MODELS.slice(i, i + BATCH);
    if (!slice.length) return;
    Promise.all(slice.map(m => {
      const p = useGLTF.preload(`/models/${m}.glb`);
      return p ? p.catch(() => {}) : Promise.resolve();
    })).then(() => { i += BATCH; next(); });
  }
  next();
}
preloadAllModels();

function getSkinnedBoundingBox(scene) {
  scene.updateMatrixWorld(true);
  const box = new THREE.Box3();
  let hasSkinnedMesh = false;

  scene.traverse((child) => {
    if (child.isSkinnedMesh) {
      hasSkinnedMesh = true;
      const position = child.geometry.attributes.position;
      const skinIndex = child.geometry.attributes.skinIndex;
      const skinWeight = child.geometry.attributes.skinWeight;
      
      if (position && skinIndex && skinWeight) {
        const vertex = new THREE.Vector3();
        const skinned = new THREE.Vector3();
        const temp = new THREE.Vector3();
        const boneMatrix = new THREE.Matrix4();
        
        const bones = child.skeleton.bones;
        const boneInverses = child.skeleton.boneInverses;
        
        // Optimize: Subsample vertices for high performance, check ~1000 vertices max
        const step = Math.max(1, Math.floor(position.count / 1000));
        
        for (let i = 0; i < position.count; i += step) {
          vertex.fromBufferAttribute(position, i);
          skinned.set(0, 0, 0);
          
          const indices = [
            skinIndex.getX(i),
            skinIndex.getY(i),
            skinIndex.getZ(i),
            skinIndex.getW(i)
          ];
          const weights = [
            skinWeight.getX(i),
            skinWeight.getY(i),
            skinWeight.getZ(i),
            skinWeight.getW(i)
          ];
          
          let totalWeight = 0;
          for (let k = 0; k < 4; k++) {
            const weight = weights[k];
            if (weight > 0.0001) {
              totalWeight += weight;
              const boneIndex = indices[k];
              const bone = bones[boneIndex];
              const invBind = boneInverses[boneIndex];
              if (bone && invBind) {
                boneMatrix.multiplyMatrices(bone.matrixWorld, invBind);
                temp.copy(vertex).applyMatrix4(boneMatrix);
                skinned.addScaledVector(temp, weight);
              } else {
                temp.copy(vertex).applyMatrix4(child.matrixWorld);
                skinned.addScaledVector(temp, weight);
              }
            }
          }
          if (totalWeight < 0.01) {
            skinned.copy(vertex).applyMatrix4(child.matrixWorld);
          }
          box.expandByPoint(skinned);
        }
      }
    }
  });

  if (!hasSkinnedMesh) {
    box.setFromObject(scene);
  }
  return box;
}

function DinosaurModel({ skin, materialProps, dinoModel }) {
  const { scene } = useGLTF(`/models/${dinoModel}.glb`);
  
  const diffuseMap = useTexture(`/textures/${dinoModel}/diffuse.webp`);
  const tintMaskMap = useTexture(`/textures/${dinoModel}/tint_mask.webp`);
  
  diffuseMap.flipY = false;
  tintMaskMap.flipY = false;

  const groupRef = useRef(null);
  const getHex = (vec) => vectorStringToHex(vec);

  // Keep references to custom albedo material configurations
  const materialConfigs = useMemo(() => ({
    b: { value: new THREE.Color() },
    u: { value: new THREE.Color() },
    m: { value: new THREE.Color() },
    md: { value: new THREE.Color() },
    f: { value: new THREE.Color() },
    d1: { value: new THREE.Color() }
  }), []);

  // Center and normalize size mathematically to zoom in 3x closer
  const { clone, center, factor, bottomOffset } = useMemo(() => {
    // Clone scene safely to avoid corrupting R3F cached source object
    const cloneScene = scene.clone(true);
    
    // Remap bones manually for skinned meshes to point to cloned bones, preventing collapses
    const cloneBones = {};
    cloneScene.traverse((child) => {
      if (child.isBone) {
        cloneBones[child.name] = child;
      }
    });
    cloneScene.traverse((child) => {
      if (child.isSkinnedMesh) {
        const bones = child.skeleton.bones.map((b) => cloneBones[b.name] || b);
        child.skeleton = new THREE.Skeleton(bones, child.skeleton.boneInverses);
        child.bind(child.skeleton, child.bindMatrix);
      }
    });

    // Reset transforms to ensure accurate bounding box calc on cloned object
    cloneScene.position.set(0, 0, 0);
    cloneScene.rotation.set(0, 0, 0);
    cloneScene.scale.set(1, 1, 1);

    // Update world matrices so box expansion calculates true bounds
    cloneScene.updateMatrixWorld(true);
    
    // Calculate bounding box using skinned vertices
    const box = getSkinnedBoundingBox(cloneScene);

    const centerVec = new THREE.Vector3();
    const sizeVec = new THREE.Vector3();
    box.getCenter(centerVec);
    box.getSize(sizeVec);

    // Normalize scale by maximum dimension so all dinosaurs fit perfectly without clipping
    const maxDim = Math.max(sizeVec.x, sizeVec.y, sizeVec.z);
    const fFactor = 4.2 / (maxDim || 1);
    console.log("[DEBUG WEBGL] dinoModel:", dinoModel, "center:", centerVec.x, centerVec.y, centerVec.z, "maxDim:", maxDim, "factor:", fFactor);

    // Apply materials using onBeforeCompile for full, native skeletal skinning support
    cloneScene.traverse((child) => {
      if (child.isMesh) {
        child.castShadow = true;
        child.receiveShadow = true;

        const nameLower = child.name.toLowerCase();
        const matNameLower = (child.material && child.material.name) ? child.material.name.toLowerCase() : '';
        const isEye = nameLower.includes('eye') || matNameLower.includes('eye') || nameLower.includes('pupil');

        if (isEye) {
          child.material = new THREE.MeshStandardMaterial({
            color: new THREE.Color(getHex(skin?.e) || '#ffff00'),
            roughness: 0.1,
            metalness: 0.9,
            emissive: new THREE.Color(getHex(skin?.e) || '#ffff00'),
            emissiveIntensity: 1.8,
            side: THREE.DoubleSide
          });
        } else {
          // Standard body parts get native MeshStandardMaterial customized via onBeforeCompile
          // We bind tintMaskMap to aoMap so Three.js automatically allocates an active texture unit slot
          const bodyMaterial = new THREE.MeshStandardMaterial({
            map: diffuseMap,
            aoMap: tintMaskMap,
            aoMapIntensity: 1.0,
            roughness: materialProps?.roughness ?? 0.8,
            metalness: materialProps?.metalness ?? 0.0,
            side: THREE.DoubleSide
          });

          bodyMaterial.onBeforeCompile = (shader) => {
            // Bind our custom uniforms to our memoized color references
            shader.uniforms.b = materialConfigs.b;
            shader.uniforms.u = materialConfigs.u;
            shader.uniforms.m = materialConfigs.m;
            shader.uniforms.md = materialConfigs.md;
            shader.uniforms.f = materialConfigs.f;
            shader.uniforms.d1 = materialConfigs.d1;

            // Header declarations (sampler2Ds for map and aoMap are declared by Three.js internally)
            shader.fragmentShader = `
              uniform vec3 b;
              uniform vec3 u;
              uniform vec3 m;
              uniform vec3 md;
              uniform vec3 f;
              uniform vec3 d1;
            ` + shader.fragmentShader;

            // Injected skin texture color blending logic into map albedo lookup block
            shader.fragmentShader = shader.fragmentShader.replace(
              '#include <map_fragment>',
              `
              vec4 maskColor = texture2D(aoMap, vMapUv); // Reads from bound aoMap unit
              vec4 texelColor = texture2D(map, vMapUv); // Reads from bound map unit
              vec3 mask = maskColor.rgb;

              float r = max(0.0, mask.r - max(mask.g, mask.b));
              float g = max(0.0, mask.g - max(mask.r, mask.b));
              float bl = max(0.0, mask.b - max(mask.r, mask.g));
              float c = max(0.0, min(mask.g, mask.b) - mask.r);
              float mag = max(0.0, min(mask.r, mask.b) - mask.g);
              float y = max(0.0, min(mask.r, mask.g) - mask.b);

              vec3 skinColor = vec3(0.0);
              skinColor += f * r;
              skinColor += u * g;
              skinColor += d1 * bl;
              skinColor += b * c;
              skinColor += m * mag;
              skinColor += md * y;

              float totalWeight = r + g + bl + c + mag + y;
              if (totalWeight < 0.05) {
                skinColor = b;
              }

              texelColor.rgb = skinColor * texelColor.rgb * 1.5;
              diffuseColor *= texelColor;
              `
            );

            // Override aomap lookup so aoMap only acts as our shader tint mask texture,
            // while keeping the actual material lighting occlusion neutral
            shader.fragmentShader = shader.fragmentShader.replace(
              '#include <aomap_fragment>',
              `
              float ambientOcclusion = 1.0;
              `
            );
          };

          child.material = bodyMaterial;
        }
      }
    });

    // Shadow sits flat on the ground exactly at the base of the centered model height
    const bottom = -(sizeVec.y / 2) * fFactor;

    return { 
      clone: cloneScene,
      center: centerVec,
      factor: fFactor,
      bottomOffset: bottom
    };
  }, [scene, dinoModel]);

  useFrame((state, delta) => {
    // Lerp colors dynamically
    const dampFactor = 1.0 - Math.exp(-10 * delta);
    
    const targetB = new THREE.Color(getHex(skin?.b) || '#222222');
    const targetU = new THREE.Color(getHex(skin?.u) || '#888888');
    const targetM = new THREE.Color(getHex(skin?.m) || '#111111');
    const targetMD = new THREE.Color(getHex(skin?.md) || '#ff0000');
    const targetF = new THREE.Color(getHex(skin?.f) || '#00ff00');
    const targetD1 = new THREE.Color(getHex(skin?.d1) || '#0000ff');
    const targetE = new THREE.Color(getHex(skin?.e) || '#ffff00');

    materialConfigs.b.value.lerp(targetB, dampFactor);
    materialConfigs.u.value.lerp(targetU, dampFactor);
    materialConfigs.m.value.lerp(targetM, dampFactor);
    materialConfigs.md.value.lerp(targetMD, dampFactor);
    materialConfigs.f.value.lerp(targetF, dampFactor);
    materialConfigs.d1.value.lerp(targetD1, dampFactor);

    if (groupRef.current) {
      groupRef.current.traverse((child) => {
        if (child.isMesh) {
          const nameLower = child.name.toLowerCase();
          const matNameLower = (child.material && child.material.name) ? child.material.name.toLowerCase() : '';
          const isEye = nameLower.includes('eye') || matNameLower.includes('eye') || nameLower.includes('pupil');

          if (isEye && child.material.color) {
            child.material.color.lerp(targetE, dampFactor);
            child.material.emissive.lerp(targetE, dampFactor);
          } else if (child.material) {
            // Apply roughness, metalness and emission presets
            child.material.roughness += ((materialProps?.roughness ?? 0.8) - child.material.roughness) * dampFactor;
            child.material.metalness += ((materialProps?.metalness ?? 0.0) - child.material.metalness) * dampFactor;
            if (materialProps?.emission !== undefined) {
              child.material.emissiveIntensity += (materialProps.emission - child.material.emissiveIntensity) * dampFactor;
            }
          }
        }
      });
    }
  });

  return (
    <group ref={groupRef}>
      {/* Outer group to apply scale and rotation around the centered model */}
      <group
        scale={[factor, factor, factor]}
        rotation={[0, -Math.PI / 6, 0]}
      >
        <primitive 
          object={clone} 
          position={[-center.x, -center.y, -center.z]} 
          scale={[1, 1, 1]}
          rotation={[0, 0, 0]}
        />
      </group>
      <ContactShadows position={[0, bottomOffset, 0]} opacity={0.8} scale={15} blur={2.0} far={4} color="#000000" />
    </group>
  );
}

export default function SkinViewer3D({ skin, materialPreset = 'matte', dinoModel = 'TRex' }) {
  const materialProps = useMemo(() => {
    switch (materialPreset) {
      case 'chrome': return { roughness: 0.1, metalness: 1.0, emission: 0.0 };
      case 'metallic': return { roughness: 0.3, metalness: 0.8, emission: 0.0 };
      case 'neon': return { roughness: 0.8, metalness: 0.1, emission: 1.5 };
      case 'glossy': return { roughness: 0.1, metalness: 0.1, emission: 0.0 };
      case 'matte':
      default: return { roughness: 0.9, metalness: 0.0, emission: 0.0 };
    }
  }, [materialPreset]);

  return (
    <div className="w-full h-full min-h-[500px] bg-black/60 rounded-xl overflow-hidden relative shadow-[0_0_40px_rgba(220,38,38,0.15)] border border-red-900/40">
      <Canvas key={dinoModel} camera={{ position: [0, 0, 5.0], fov: 40 }} shadows dpr={[1, 2]}>
        <color attach="background" args={['#0a0a0c']} />

        <ambientLight intensity={materialPreset === 'neon' ? 0.2 : 0.85} />
        <spotLight position={[10, 15, 10]} angle={0.4} penumbra={1} intensity={2.5} castShadow shadow-mapSize={[2048, 2048]} />
        <pointLight position={[-10, -5, -10]} intensity={1.0} color="#5555ff" />
        <pointLight position={[10, -5, 10]} intensity={1.0} color="#ff5555" />

        <React.Suspense fallback={
          <mesh>
            <boxGeometry args={[1, 1, 1]} />
            <meshStandardMaterial color="#2c1a1a" roughness={0.9} />
            <Html center>
              <div style={{ color: '#fff', fontFamily: 'monospace', fontSize: '11px', textAlign: 'center', whiteSpace: 'nowrap' }}>
                Loading {dinoModel}...
              </div>
            </Html>
          </mesh>
        }>
          <DinosaurModel skin={skin} materialProps={materialProps} dinoModel={dinoModel} />
        </React.Suspense>

        <OrbitControls 
          makeDefault 
          enablePan={false} // Prevents moving/sliding model left and right
          enableDamping 
          dampingFactor={0.05} 
          minPolarAngle={0} 
          maxPolarAngle={Math.PI} 
          minDistance={1.5} 
          maxDistance={8.0}
          zoomSpeed={4.0} // Increases zoom speed for scroll wheel to zoom in at larger intervals
          target={[0, 0, 0]} // Camera rotates in a sphere strictly centered around the model pivot
        />
        {materialPreset !== 'neon' && <Environment preset="studio" />}
      </Canvas>

      <div className="absolute top-4 left-4 pointer-events-none z-10 flex flex-col gap-1">
        <h2 className="text-red-500 text-sm font-bold tracking-widest uppercase flex items-center gap-2">
          <span className="w-2 h-2 rounded-full bg-red-500 animate-pulse"></span>
          Evrima Mesh Active
        </h2>
        <p className="text-gray-400 text-xs tracking-wider">Species: <span className="text-white">{dinoModel}</span> | <span className="text-white capitalize">{materialPreset}</span></p>
      </div>
    </div>
  );
}

