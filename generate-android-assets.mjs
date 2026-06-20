import sharp from 'sharp';
import { existsSync, mkdirSync } from 'fs';

const SOURCE = 'C:/Users/yochi/.gemini/antigravity-ide/brain/8e9acdfc-0479-41a8-95fc-d2a3ed2aee08/media__1781971263231.png';
const RES_DIR = './android/app/src/main/res';

if (!existsSync(SOURCE)) {
  console.error(`Source icon not found at ${SOURCE}`);
  process.exit(1);
}

// Config for standard mipmap folders
const densities = [
  { name: 'mdpi', size: 48, foregroundSize: 108 },
  { name: 'hdpi', size: 72, foregroundSize: 162 },
  { name: 'xhdpi', size: 96, foregroundSize: 216 },
  { name: 'xxhdpi', size: 144, foregroundSize: 324 },
  { name: 'xxxhdpi', size: 192, foregroundSize: 432 }
];

async function generateAssets() {
  for (const d of densities) {
    const dir = `${RES_DIR}/mipmap-${d.name}`;
    if (!existsSync(dir)) {
      mkdirSync(dir, { recursive: true });
    }

    // 1. Generate normal ic_launcher.png
    await sharp(SOURCE)
      .resize(d.size, d.size)
      .png()
      .toFile(`${dir}/ic_launcher.png`);
    console.log(`✅ Generated mipmap-${d.name}/ic_launcher.png (${d.size}x${d.size})`);

    // 2. Generate ic_launcher_round.png
    await sharp(SOURCE)
      .resize(d.size, d.size)
      .png()
      .toFile(`${dir}/ic_launcher_round.png`);
    console.log(`✅ Generated mipmap-${d.name}/ic_launcher_round.png (${d.size}x${d.size})`);

    // 3. Generate adaptive ic_launcher_foreground.png
    const iconSize = Math.round(d.foregroundSize * 0.72);
    const resizedIcon = await sharp(SOURCE)
      .resize(iconSize, iconSize)
      .toBuffer();

    await sharp({
      create: {
        width: d.foregroundSize,
        height: d.foregroundSize,
        channels: 4,
        background: { r: 0, g: 0, b: 0, alpha: 0 }
      }
    })
      .composite([{ input: resizedIcon, gravity: 'center' }])
      .png()
      .toFile(`${dir}/ic_launcher_foreground.png`);
    console.log(`✅ Generated mipmap-${d.name}/ic_launcher_foreground.png (${d.foregroundSize}x${d.foregroundSize})`);
  }

  // 4. Generate splash screen
  const splashLogoSize = 384;
  const resizedSplashLogo = await sharp(SOURCE)
    .resize(splashLogoSize, splashLogoSize)
    .toBuffer();

  const drawableDir = `${RES_DIR}/drawable`;
  if (!existsSync(drawableDir)) {
    mkdirSync(drawableDir, { recursive: true });
  }

  // Overwrite drawable/splash.png
  await sharp({
    create: {
      width: 2048,
      height: 2048,
      channels: 4,
      background: '#000000'
    }
  })
    .composite([{ input: resizedSplashLogo, gravity: 'center' }])
    .png()
    .toFile(`${drawableDir}/splash.png`);
  console.log(`✅ Generated drawable/splash.png (2048x2048)`);

  console.log('\n🎉 Android app assets generated successfully!');
}

generateAssets().catch(err => {
  console.error('Generation failed:', err);
});
