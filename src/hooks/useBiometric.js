import { useState, useEffect } from 'react';
import { Capacitor } from '@capacitor/core';
import { NativeBiometric } from '@capgo/capacitor-native-biometric';

export function useBiometric() {
  const [isSupported, setIsSupported] = useState(false);
  const [isEnrolled, setIsEnrolled] = useState(false);
  const isNative = Capacitor.isNativePlatform();

  const checkStatus = async () => {
    if (!isNative) {
      // On web, mock status using localStorage
      setIsSupported(true);
      const email = localStorage.getItem('diaro_remembered_email');
      const pass = localStorage.getItem('diaro_cached_password');
      setIsEnrolled(!!(email && pass));
      return;
    }

    try {
      const avail = await NativeBiometric.isAvailable();
      setIsSupported(avail.isAvailable);

      if (avail.isAvailable) {
        const saved = await NativeBiometric.isCredentialsSaved({
          server: 'diaro.app',
        });
        setIsEnrolled(saved.isSaved);
      } else {
        setIsEnrolled(false);
      }
    } catch (err) {
      console.error('Error checking biometric status:', err);
      setIsSupported(false);
      setIsEnrolled(false);
    }
  };

  useEffect(() => {
    checkStatus();
  }, []);

  const saveCredentials = async (email, password) => {
    if (!isNative) {
      localStorage.setItem('diaro_remembered_email', email);
      localStorage.setItem('diaro_cached_password', password);
      setIsEnrolled(true);
      return;
    }

    try {
      // 2 represents AccessControl.BIOMETRY_ANY
      await NativeBiometric.setCredentials({
        username: email,
        password: password,
        server: 'diaro.app',
        accessControl: 2,
      });
      setIsEnrolled(true);
    } catch (err) {
      console.error('Error saving biometric credentials:', err);
    }
  };

  const deleteCredentials = async () => {
    if (!isNative) {
      localStorage.removeItem('diaro_remembered_email');
      localStorage.removeItem('diaro_cached_password');
      setIsEnrolled(false);
      return;
    }

    try {
      await NativeBiometric.deleteCredentials({
        server: 'diaro.app',
      });
      setIsEnrolled(false);
    } catch (err) {
      console.error('Error deleting biometric credentials:', err);
    }
  };

  const authenticate = async () => {
    if (!isNative) {
      // Web mock verification
      const email = localStorage.getItem('diaro_remembered_email');
      const pass = localStorage.getItem('diaro_cached_password');
      if (email && pass) {
        return { username: email, password: pass };
      }
      return null;
    }

    try {
      const credentials = await NativeBiometric.getSecureCredentials({
        server: 'diaro.app',
        reason: 'Authenticate to decrypt local database keys',
        title: 'Diaro Unlock',
        subtitle: 'Use biometric to decrypt your vault',
        description: 'Diaro uses end-to-end local AES-256 encryption.',
        negativeButtonText: 'Use Master Password',
      });
      return credentials; // Contains { username, password }
    } catch (err) {
      console.error('Biometric authentication failed:', err);
      return null;
    }
  };

  return {
    isSupported,
    isEnrolled,
    saveCredentials,
    deleteCredentials,
    authenticate,
    checkStatus,
  };
}
