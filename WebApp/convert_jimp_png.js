const Jimp = require('jimp');
const fs = require('fs');
const path = require('path');

const distance = (r1, g1, b1, r2, g2, b2) => {
  return Math.sqrt(Math.pow(r1 - r2, 2) + Math.pow(g1 - g2, 2) + Math.pow(b1 - b2, 2));
};

async function processImage(inPath, outPath) {
  const img = await Jimp.read(inPath);
  const width = img.bitmap.width;
  const height = img.bitmap.height;
  
  // Get background color from top-left pixel
  const bgColorInt = img.getPixelColor(0, 0);
  const bgRgba = Jimp.intToRGBA(bgColorInt);
  
  // Apply transparency to any pixel close to the background color
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const pInt = img.getPixelColor(x, y);
      const p = Jimp.intToRGBA(pInt);
      
      const dist = distance(p.r, p.g, p.b, bgRgba.r, bgRgba.g, bgRgba.b);
      
      if (dist < 45) { // increased tolerance for JPEG artifacts
        img.setPixelColor(Jimp.rgbaToInt(p.r, p.g, p.b, 0), x, y);
      }
    }
  }
  
  await img.writeAsync(outPath);
  console.log(`Processed ${path.basename(inPath)}`);
}

async function processFolder(folderPath) {
  const files = fs.readdirSync(folderPath);
  for (const file of files) {
    if (file.endsWith('.png') && file !== 'gateway_thumb.png' && file !== 'SPLOGO.png') {
      const inPath = path.join(folderPath, file);
      // Overwrite the PNG
      try {
        await processImage(inPath, inPath);
      } catch (e) {
        console.error(`Failed on ${file}: ${e.message}`);
      }
    }
  }
}

async function main() {
  await processFolder('public/assets/icons/dinos');
  await processFolder('public/assets/icons/food');
  console.log('All done!');
}

main();
