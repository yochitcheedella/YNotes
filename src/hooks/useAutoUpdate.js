import { useState, useEffect } from 'react';
import { Browser } from '@capacitor/browser';
import { App } from '@capacitor/app';

export function useAutoUpdate() {
  const [updateAvailable, setUpdateAvailable] = useState(false);
  const [updateInfo, setUpdateInfo] = useState(null);

  useEffect(() => {
    checkForUpdates();
  }, []);

  const checkForUpdates = async () => {
    try {
      // Get current app info dynamically (retrieves versionCode as 'build' on Android)
      let currentBuild = 8; // default to latest build code
      try {
        const info = await App.getInfo();
        currentBuild = parseInt(info.build, 10) || 8;
      } catch (err) {
        console.warn('Could not read app build info:', err);
      }

      // Fetch latest version info directly from Cloudflare Pages
      const response = await fetch('https://ynote-app.pages.dev/version.json', { cache: 'no-store' });
      const data = await response.json();

      if (data.versionCode > currentBuild) {
        setUpdateInfo(data);
        setUpdateAvailable(true);
      }
    } catch (error) {
      console.warn('Auto-Update check failed (offline or network error).', error);
    }
  };

  const executeUpdate = async () => {
    if (!updateInfo?.downloadUrl) return;
    
    // Open the direct APK download URL in the external system browser
    // This securely passes the download task to Android's built-in Download Manager
    // which automatically prompts the user to install the APK once finished.
    await Browser.open({ url: updateInfo.downloadUrl });
  };

  const postponeUpdate = () => {
    setUpdateAvailable(false);
  };

  return { updateAvailable, updateInfo, executeUpdate, postponeUpdate };
}
