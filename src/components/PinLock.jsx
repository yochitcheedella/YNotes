import React, { useState, useEffect } from 'react';
import { Preferences } from '@capacitor/preferences';
import { hashPassword, decryptText } from '../cryptoHelper';

export default function PinLock({ onUnlock, onLogout }) {
  const [pin, setPin] = useState('');
  const [errorMsg, setErrorMsg] = useState('');
  const [attempts, setAttempts] = useState(0);
  const [lockoutTime, setLockoutTime] = useState(0);
  
  const [storedHash, setStoredHash] = useState(null);
  const [encryptedVaultKey, setEncryptedVaultKey] = useState(null);

  useEffect(() => {
    const loadPinData = async () => {
      const { value: hash } = await Preferences.get({ key: 'diaro_pin_hash' });
      const { value: encKey } = await Preferences.get({ key: 'diaro_encrypted_vault_key' });
      setStoredHash(hash);
      setEncryptedVaultKey(encKey);
    };
    loadPinData();
  }, []);

  useEffect(() => {
    let interval;
    if (lockoutTime > 0) {
      interval = setInterval(() => {
        setLockoutTime((prev) => (prev > 1 ? prev - 1 : 0));
      }, 1000);
    } else if (lockoutTime === 0 && attempts >= 5) {
      setAttempts(0); // Reset attempts after lockout expires
      setErrorMsg('');
    }
    return () => clearInterval(interval);
  }, [lockoutTime, attempts]);

  useEffect(() => {
    if (pin.length === 4) {
      verifyPin();
    }
  }, [pin]);

  const verifyPin = () => {
    if (lockoutTime > 0) return;

    const inputHash = hashPassword(pin);
    if (inputHash === storedHash) {
      // PIN is correct, decrypt the vault key
      const vaultKey = decryptText(encryptedVaultKey, pin);
      if (vaultKey && !vaultKey.startsWith('[Decryption failed')) {
        setErrorMsg('');
        onUnlock(vaultKey);
      } else {
        handleFailure('Vault key corrupted. Please log out and sign in again.');
      }
    } else {
      handleFailure('Incorrect PIN');
    }
  };

  const handleFailure = (msg) => {
    const newAttempts = attempts + 1;
    setAttempts(newAttempts);
    setPin('');
    
    if (newAttempts >= 5) {
      setLockoutTime(30);
      setErrorMsg('Too many attempts. Locked for 30s.');
    } else {
      setErrorMsg(`${msg}. ${5 - newAttempts} attempts left.`);
      // Vibrate if native
      if (window.navigator && window.navigator.vibrate) {
        window.navigator.vibrate(200);
      }
    }
  };

  const handleKeyPress = (num) => {
    if (pin.length < 4 && lockoutTime === 0) {
      setPin((prev) => prev + num);
      setErrorMsg('');
    }
  };

  const handleDelete = () => {
    if (pin.length > 0 && lockoutTime === 0) {
      setPin((prev) => prev.slice(0, -1));
    }
  };

  const renderDots = () => {
    const dots = [];
    for (let i = 0; i < 4; i++) {
      dots.push(
        <div 
          key={i} 
          className={`w-4 h-4 rounded-full border-2 transition-all duration-200 ${
            i < pin.length 
              ? 'bg-diaroAccent-400 border-diaroAccent-400 shadow-[0_0_10px_rgba(184,115,51,0.5)]' 
              : 'border-diaroAccent-500/30 bg-transparent'
          } ${errorMsg && !lockoutTime ? 'animate-pulse bg-red-500 border-red-500' : ''}`}
        />
      );
    }
    return dots;
  };

  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-bgDark relative overflow-hidden">
      {/* Background ambient glows */}
      <div className="fixed inset-0 z-0 pointer-events-none">
        <div className="absolute top-[-10%] left-[-10%] w-[60%] h-[60%] ambient-glow-1 rounded-full"></div>
        <div className="absolute bottom-[-10%] right-[-10%] w-[60%] h-[60%] ambient-glow-2 rounded-full"></div>
        <div className="absolute inset-0 bg-[linear-gradient(rgba(255,255,255,0.003)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,0.003)_1px,transparent_1px)] bg-[size:30px_30px] opacity-25"></div>
      </div>

      <div className="relative z-10 flex flex-col items-center px-8 w-full max-w-sm">
        
        <div className="mb-8 flex flex-col items-center">
          <div className="w-16 h-16 rounded-full bg-diaroAccent-900/40 border border-diaroAccent-500/30 flex items-center justify-center mb-4">
            <span className="material-symbols-outlined text-3xl text-diaroAccent-400">lock</span>
          </div>
          <h2 className="text-xl font-bold text-white tracking-wide">Enter PIN</h2>
          <p className="text-xs text-diaroAccent-300/50 mt-1 font-mono uppercase tracking-widest">
            {lockoutTime > 0 ? `Locked for ${lockoutTime}s` : 'App Locked'}
          </p>
        </div>

        {/* PIN Indicators */}
        <div className="flex gap-6 mb-8">
          {renderDots()}
        </div>

        {/* Error Message */}
        <div className="h-6 mb-4">
          {errorMsg && (
            <p className="text-xs font-mono text-red-400 animate-fade-in">{errorMsg}</p>
          )}
        </div>

        {/* Keypad */}
        <div className="grid grid-cols-3 gap-4 w-full max-w-[280px] mb-8">
          {[1, 2, 3, 4, 5, 6, 7, 8, 9].map((num) => (
            <button
              key={num}
              onClick={() => handleKeyPress(num.toString())}
              disabled={lockoutTime > 0}
              className="w-16 h-16 rounded-full mx-auto flex items-center justify-center text-2xl font-mono text-white bg-white/5 hover:bg-white/10 active:bg-white/20 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {num}
            </button>
          ))}
          <div className="w-16 h-16"></div>
          <button
            onClick={() => handleKeyPress('0')}
            disabled={lockoutTime > 0}
            className="w-16 h-16 rounded-full mx-auto flex items-center justify-center text-2xl font-mono text-white bg-white/5 hover:bg-white/10 active:bg-white/20 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            0
          </button>
          <button
            onClick={handleDelete}
            disabled={lockoutTime > 0 || pin.length === 0}
            className="w-16 h-16 rounded-full mx-auto flex items-center justify-center text-xl text-diaroAccent-300 hover:text-white bg-transparent active:bg-white/10 transition-colors disabled:opacity-30 disabled:cursor-not-allowed"
          >
            <span className="material-symbols-outlined">backspace</span>
          </button>
        </div>

        {/* Logout Fallback */}
        <button
          onClick={onLogout}
          className="mt-4 px-6 py-2 rounded-full border border-diaroAccent-500/20 text-xs font-mono text-diaroAccent-400 uppercase tracking-widest hover:bg-diaroAccent-900/20 transition-colors"
        >
          Logout
        </button>
      </div>
    </div>
  );
}
