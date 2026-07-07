/**
 * @file skinDecoder.js
 * @description High-throughput serialization matrix for The Isle: Evrima skin strings.
 * Provides a bidirectional translation engine to parse raw strings into JSON and serialize JSON into game-ready strings.
 */

class SkinMatrix {
  /**
   * Decodes a raw skin string into a robust JSON structure.
   * @param {string} skinString - The raw alphanumeric skin string (e.g., 'Austroraptor100A9964AFF0E1620FF223344FF556677FF')
   * @returns {Object} JSON representation of the skin payload.
   */
  static decode(skinString) {
    if (typeof skinString !== 'string') {
      throw new TypeError('Skin string must be a string.');
    }

    // Capture groups:
    // 1: Species Name (Alpha chars)
    // 2: Gender (1 digit)
    // 3: Pattern (1 digit)
    // 4: Variant (1 digit)
    // 5-8: Colors (8 hex chars each: RRGGBBAA)
    const regex = /^([a-zA-Z]+)(\d)(\d)(\d)([A-Fa-f0-9]{8})([A-Fa-f0-9]{8})([A-Fa-f0-9]{8})([A-Fa-f0-9]{8})$/;
    const match = skinString.match(regex);

    if (!match) {
      throw new Error(`Invalid skin string format provided: ${skinString}`);
    }

    const [
      ,
      species,
      gender,
      pattern,
      variant,
      layer1, // detail
      layer2, // belly
      layer3, // base tones
      layer4  // spot overlays
    ] = match;

    return {
      metadata: {
        species: species,
        gender: parseInt(gender, 10),
        pattern: parseInt(pattern, 10),
        variant: parseInt(variant, 10)
      },
      layers: {
        detail: {
          hexRGBA: layer1.toUpperCase(),
          hexUI: this.toUIHex(layer1)
        },
        belly: {
          hexRGBA: layer2.toUpperCase(),
          hexUI: this.toUIHex(layer2)
        },
        baseTones: {
          hexRGBA: layer3.toUpperCase(),
          hexUI: this.toUIHex(layer3)
        },
        spotOverlays: {
          hexRGBA: layer4.toUpperCase(),
          hexUI: this.toUIHex(layer4)
        }
      }
    };
  }

  /**
   * Encodes a JSON skin structure back into a game-ready profile string format.
   * @param {Object} skinJson - The JSON object matching the decode output.
   * @returns {string} The reconstructed raw skin string.
   */
  static encode(skinJson) {
    try {
      const { metadata, layers } = skinJson;
      const { species, gender, pattern, variant } = metadata;

      // Extract colors, preferring hexRGBA over hexUI if available. 
      // Fallback appends 'FF' to UI hex to assume full opacity.
      const getLayerHex = (layer) => {
        if (layer.hexRGBA) return layer.hexRGBA.toUpperCase().padStart(8, '0');
        if (layer.hexUI) return layer.hexUI.replace('#', '').toUpperCase().padEnd(8, 'F');
        return 'FFFFFFFF';
      };

      const c1 = getLayerHex(layers.detail);
      const c2 = getLayerHex(layers.belly);
      const c3 = getLayerHex(layers.baseTones);
      const c4 = getLayerHex(layers.spotOverlays);

      return `${species}${gender}${pattern}${variant}${c1}${c2}${c3}${c4}`;
    } catch (err) {
      throw new Error(`Failed to encode skin JSON to string: ${err.message}`);
    }
  }

  /**
   * Converts an 8-character RRGGBBAA hex to a 6-character UI hex string (#RRGGBB).
   * @param {string} hexRGBA 
   * @returns {string} 
   */
  static toUIHex(hexRGBA) {
    return `#${hexRGBA.substring(0, 6).toUpperCase()}`;
  }
}

module.exports = SkinMatrix;

// ==========================================
// TEST EXECUTION (Example)
// ==========================================
// const sample = 'Austroraptor100A9964AFF0E1620FF223344FF556677FF';
// const decoded = SkinMatrix.decode(sample);
// console.log('Decoded JSON:', JSON.stringify(decoded, null, 2));
// const reEncoded = SkinMatrix.encode(decoded);
// console.log('Re-encoded String:', reEncoded);
// console.log('Match?', sample === reEncoded);
