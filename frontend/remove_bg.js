const Jimp = require('jimp');

async function removeBackground() {
  const img = await Jimp.read('C:\\Users\\Dilla\\.gemini\\antigravity\\brain\\8872d676-ad67-4bb1-9bf0-80138905c76b\\media__1782511419183.png');
  const bgColor = Jimp.intToRGBA(img.getPixelColor(0, 0));
  
  img.scan(0, 0, img.bitmap.width, img.bitmap.height, function(x, y, idx) {
    const r = this.bitmap.data[idx];
    const g = this.bitmap.data[idx+1];
    const b = this.bitmap.data[idx+2];
    
    // Distance from bgColor
    const dist = Math.abs(r - bgColor.r) + Math.abs(g - bgColor.g) + Math.abs(b - bgColor.b);
    
    if (dist < 40) { // Tolerance
      this.bitmap.data[idx+3] = 0; // Transparent
    }
  });

  await img.writeAsync('public/assets/discordicon.png');
  console.log('Background removed successfully!');
}

removeBackground().catch(console.error);
