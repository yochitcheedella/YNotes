import fs from 'fs';
import path from 'path';

function walk(dir, callback) {
  fs.readdirSync(dir).forEach(f => {
    let dirPath = path.join(dir, f);
    let isDirectory = fs.statSync(dirPath).isDirectory();
    isDirectory ? walk(dirPath, callback) : callback(path.join(dir, f));
  });
}

walk('./src', function(filePath) {
  if (filePath.endsWith('.jsx') || filePath.endsWith('.js') || filePath.endsWith('.css') || filePath.endsWith('.html')) {
    let content = fs.readFileSync(filePath, 'utf8');
    let original = content;
    
    // Replace theme color class
    content = content.replace(/cyberBlue/g, 'ynoteAccent');
    
    // Replace blue text colors with purple/fuchsia to match the new theme
    content = content.replace(/text-blue-/g, 'text-purple-');
    content = content.replace(/border-blue-/g, 'border-purple-');
    
    // Replace text
    content = content.replace(/Diaro/g, 'YNote');
    content = content.replace(/diaro\.io/g, 'ynote.app');
    content = content.replace(/diaro\.app/g, 'ynote.app');
    content = content.replace(/diaro_/g, 'ynote_');
    content = content.replace(/diaro/g, 'ynote');
    
    // Update tagline
    content = content.replace(/Your Thoughts\. Your Privacy\./g, 'Capture Everything. Securely.');
    
    if (content !== original) {
      fs.writeFileSync(filePath, content, 'utf8');
      console.log(`Updated ${filePath}`);
    }
  }
});
