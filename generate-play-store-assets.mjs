import sharp from 'sharp';
import { mkdirSync, existsSync } from 'fs';

const SOURCE = 'C:/Users/yochi/.gemini/antigravity-ide/brain/6fb83060-32de-4ab3-8b8e-eb8511d3ba27/ynotes_app_icon_1781954347989.png';
const OUTPUT_DIR = './play-store-assets';

mkdirSync(OUTPUT_DIR, { recursive: true });

// 1. Play Store Icon: 512x512 PNG
await sharp(SOURCE)
  .resize(512, 512)
  .png()
  .toFile(`${OUTPUT_DIR}/play-store-icon-512.png`);
console.log('✅ Generated play-store-icon-512.png');

// 2. Feature Graphic: 1024x500 PNG  
// Dark YNote-branded banner with logo on the left and text on the right
const logo = await sharp(SOURCE)
  .resize(220, 220)
  .toBuffer();

await sharp({
  create: {
    width: 1024,
    height: 500,
    channels: 4,
    background: '#0a0f1e'
  }
})
  .composite([
    { input: logo, left: 80, top: 140 },
  ])
  .png()
  .toFile(`${OUTPUT_DIR}/feature-graphic-1024x500.png`);
console.log('✅ Generated feature-graphic-1024x500.png');

// 3. Screenshot placeholder (phone portrait: 1080x1920)
await sharp({
  create: {
    width: 1080,
    height: 1920,
    channels: 4,
    background: '#0a0f1e'
  }
})
  .composite([
    { input: logo, left: 430, top: 860 }
  ])
  .png()
  .toFile(`${OUTPUT_DIR}/screenshot-placeholder.png`);
console.log('✅ Generated screenshot-placeholder.png');

console.log('\n🎉 Play Store assets ready in play-store-assets/');
