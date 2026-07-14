// Unreal Engine Vector String to Hex / RGB Conversion

/**
 * Parses an Evrima vector string like 'X=0.9451,Y=0.0157,Z=0.7451' into a Linear RGB array.
 * Note: Evrima's X, Y, Z often correspond to R, G, B in Linear Space.
 */
export function parseVectorString(vecStr) {
  if (!vecStr) return [0, 0, 0];
  
  // Handle some of the weird formatting in the user's examples like "X=-10,Y=-100" or extra spaces
  const xMatch = vecStr.match(/X=([-\d.]+)/);
  const yMatch = vecStr.match(/Y=([-\d.]+)/);
  const zMatch = vecStr.match(/Z=([-\d.]+)/);
  
  const r = xMatch ? parseFloat(xMatch[1]) : 0;
  const g = yMatch ? parseFloat(yMatch[1]) : 0;
  const b = zMatch ? parseFloat(zMatch[1]) : 0;
  
  return [
    Math.max(0, Math.min(1, r)), // Clamp for standard Hex conversion, though UE allows overbrights
    Math.max(0, Math.min(1, g)),
    Math.max(0, Math.min(1, b))
  ];
}

/**
 * Converts a Linear RGB float [0-1] to sRGB float [0-1]
 */
export function linearToSRGB(x) {
  if (x <= 0.0031308) {
    return x * 12.92;
  }
  return 1.055 * Math.pow(x, 1.0 / 2.4) - 0.055;
}

/**
 * Converts a Linear RGB vector string to a Hex color string '#RRGGBB'
 */
export function vectorStringToHex(vecStr) {
  const [lr, lg, lb] = parseVectorString(vecStr);
  
  // Convert Linear to sRGB for accurate web display
  const sr = linearToSRGB(lr);
  const sg = linearToSRGB(lg);
  const sb = linearToSRGB(lb);
  
  const rHex = Math.round(sr * 255).toString(16).padStart(2, '0');
  const gHex = Math.round(sg * 255).toString(16).padStart(2, '0');
  const bHex = Math.round(sb * 255).toString(16).padStart(2, '0');
  
  return `#${rHex}${gHex}${bHex}`.toUpperCase();
}

/**
 * Converts an sRGB float [0-1] to Linear RGB float [0-1]
 */
export function sRGBToLinear(x) {
  if (x <= 0.04045) {
    return x / 12.92;
  }
  return Math.pow((x + 0.055) / 1.055, 2.4);
}

/**
 * Converts a standard web Hex '#RRGGBB' to an Evrima vector string
 */
export function hexToVectorString(hex) {
  hex = hex.replace('#', '');
  
  const r = parseInt(hex.substring(0, 2), 16) / 255;
  const g = parseInt(hex.substring(2, 4), 16) / 255;
  const b = parseInt(hex.substring(4, 6), 16) / 255;
  
  const lr = sRGBToLinear(r).toFixed(4);
  const lg = sRGBToLinear(g).toFixed(4);
  const lb = sRGBToLinear(b).toFixed(4);
  
  return `X=${lr},Y=${lg},Z=${lb}`;
}

/**
 * Cleans up and parses the weird single-quoted object format the user provided
 * into standard JSON.
 */
export function parseEvrimaSkinCode(codeString) {
  try {
    // Replace single quotes with double quotes
    let jsonString = codeString.replace(/'/g, '"');
    // Basic fallback parsing if it's slightly malformed
    return JSON.parse(jsonString);
  } catch (e) {
    console.error("Failed to parse skin code:", e);
    return null;
  }
}
