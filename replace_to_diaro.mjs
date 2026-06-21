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
    
    // Replace text
    content = content.replace(/YNote/g, 'Diaro');
    content = content.replace(/ynote\.app/g, 'diaro.app');
    content = content.replace(/ynote_/g, 'diaro_');
    content = content.replace(/ynote/g, 'diaro');
    
    // We should also replace 'Capture Everything. Securely.' with 'Your Notes. Your Privacy.' if they want to match the landing page.
    content = content.replace(/Capture Everything\. Securely\./g, 'Your Notes. Your Privacy.');
    
    if (content !== original) {
      fs.writeFileSync(filePath, content, 'utf8');
      console.log(`Updated ${filePath}`);
    }
  }
});
