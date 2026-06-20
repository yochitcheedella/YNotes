// generate-icons.mjs - Generate PWA icons from source image
import sharp from 'sharp';
import { mkdirSync } from 'fs';

const SOURCE = 'C:/Users/yochi/.gemini/antigravity-ide/brain/8e9acdfc-0479-41a8-95fc-d2a3ed2aee08/media__1781971263231.png';
const OUTPUT_DIR = './public/icons';

const sizes = [72, 96, 128, 144, 152, 192, 384, 512];

mkdirSync(OUTPUT_DIR, { recursive: true });

for (const size of sizes) {
  await sharp(SOURCE)
    .resize(size, size)
    .png()
    .toFile(`${OUTPUT_DIR}/icon-${size}.png`);
  console.log(`✅ Generated icon-${size}.png`);
}

console.log('\n🎉 All PWA icons generated successfully!');
