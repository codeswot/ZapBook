const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

try {
  const htmlPath = path.join(__dirname, '..', 'zap_design_templ.html');
  const htmlContent = fs.readFileSync(htmlPath, 'utf8');

  const manifestMatch = htmlContent.match(/<script type="__bundler\/manifest">([\s\S]*?)<\/script>/);
  if (!manifestMatch) {
    console.error('No manifest found');
    process.exit(1);
  }

  const manifest = JSON.parse(manifestMatch[1].trim());
  const publicDir = path.join(__dirname, 'public', 'assets');
  if (!fs.existsSync(publicDir)) {
    fs.mkdirSync(publicDir, { recursive: true });
  }

  const mimeToExt = {
    'image/png': '.png',
    'image/jpeg': '.jpg',
    'image/svg+xml': '.svg',
    'font/woff2': '.woff2',
    'font/woff': '.woff',
    'text/css': '.css',
    'text/javascript': '.js'
  };

  const assetMapping = {};

  for (const [uuid, entry] of Object.entries(manifest)) {
    const buffer = Buffer.from(entry.data, 'base64');
    let finalBuffer = buffer;

    if (entry.compressed) {
      try {
        finalBuffer = zlib.gunzipSync(buffer);
      } catch (err) {
        console.error(`Failed to decompress ${uuid}:`, err);
      }
    }

    const ext = mimeToExt[entry.mime] || '.bin';
    const filename = `${uuid}${ext}`;
    const destPath = path.join(publicDir, filename);

    fs.writeFileSync(destPath, finalBuffer);
    console.log(`Saved ${entry.mime} to ${destPath}`);

    assetMapping[uuid] = `/assets/${filename}`;
  }

  fs.writeFileSync(
    path.join(__dirname, 'src', 'assets.json'),
    JSON.stringify(assetMapping, null, 2)
  );
  console.log('Saved assets mapping to src/assets.json');
} catch (err) {
  console.error('Error running extraction:', err);
}
