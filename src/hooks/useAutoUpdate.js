import { useState, useEffect } from 'react';
import { Browser } from '@capacitor/browser';
import { App } from '@capacitor/app';

const CURRENT_VERSION_CODE = 3;

export function useAutoUpdate() {
  const [updateAvailable, setUpdateAvailable] = useState(false);
  const [updateInfo, setUpdateInfo] = useState(null);

  useEffect(() => {
    checkForUpdates();
  }, []);

  const checkForUpdates = async () => {
    try {
      // Fetch latest version info directly from Cloudflare Pages
      const response = await fetch('https://ynote-app.pages.dev/version.json', { cache: 'no-store' });
      const data = await response.json();

      if (data.versionCode > CURRENT_VERSION_CODE) {
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
    
    // Optionally close the app so the user focuses on the installation
    // await App.exitApp(); 
  };

  const postponeUpdate = () => {
    setUpdateAvailable(false);
  };

  return { updateAvailable, updateInfo, executeUpdate, postponeUpdate };
}
