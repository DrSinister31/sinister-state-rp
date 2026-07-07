const Jimp = require('jimp');

async function processImage(inPath, outPath) {
  const img = await Jimp.read(inPath);
  const width = img.bitmap.width;
  const height = img.bitmap.height;
  
  // Get background color from top-left pixel
  const bgColorInt = img.getPixelColor(0, 0);
  const bgRgba = Jimp.intToRGBA(bgColorInt);
  
  const distance = (r1, g1, b1, r2, g2, b2) => {
    return Math.sqrt(Math.pow(r1 - r2, 2) + Math.pow(g1 - g2, 2) + Math.pow(b1 - b2, 2));
  };
  
  // Apply transparency to any pixel close to the background color
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const pInt = img.getPixelColor(x, y);
      const p = Jimp.intToRGBA(pInt);
      
      const dist = distance(p.r, p.g, p.b, bgRgba.r, bgRgba.g, bgRgba.b);
      
      if (dist < 30) { // Tolerance
        img.setPixelColor(Jimp.rgbaToInt(p.r, p.g, p.b, 0), x, y);
      }
    }
  }
  
  await img.writeAsync(outPath);
  console.log(`Processed ${inPath} to ${outPath}, bgColor: ${bgRgba.r},${bgRgba.g},${bgRgba.b}`);
}

processImage('public/assets/icons/dinos/crab.jpg', 'public/assets/icons/dinos/crab.png').catch(console.error);
