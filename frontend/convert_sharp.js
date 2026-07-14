const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

async function processFolder(folderPath) {
  const files = fs.readdirSync(folderPath);
  for (const file of files) {
    if (file.endsWith('.jpg')) {
      const inPath = path.join(folderPath, file);
      const outPath = path.join(folderPath, file.replace('.jpg', '.png'));
      try {
        await sharp(inPath).toFormat('png').toFile(outPath);
        console.log(`Converted ${file} to PNG`);
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
