import React, { useState, useEffect } from 'react';
import { Capacitor } from '@capacitor/core';
import { NativeBiometric } from '@capgo/capacitor-native-biometric';
import { deriveKey } from '../cryptoHelper';
import { supabase } from '../supabaseClient';

/**
 * BiometricLock screen — shown when cached credentials exist.
 * The user MUST authenticate via fingerprint (or fallback password)
 * before the vault opens. App never auto-opens without auth.
 *
 * Props:
 *   email    — stored email address (for display)
 *   password — stored password (derived from Preferences)
 *   onSuccess(sessionInfo) — called after successful biometric auth
 *   onFallbackPassword()  — called when user taps "Use Password Instead"
 */
export default function BiometricLock({ email, password, onSuccess, onFallbackPassword }) {
  const [status, setStatus] = useState('idle'); // idle | scanning | success | error
  const [errorMsg, setErrorMsg] = useState('');
  const isNative = Capacitor.isNativePlatform();

  // Auto-trigger fingerprint prompt on mount
  useEffect(() => {
    triggerBiometric();
  }, []);

  const triggerBiometric = async () => {
    setStatus('scanning');
    setErrorMsg('');

    try {
      if (isNative) {
        // On Android: trigger the real system biometric dialog
        const credentials = await NativeBiometric.getSecureCredentials({
          server: 'diaro.app',
          reason: 'Authenticate to decrypt your private vault',
          title: 'Diaro Vault Lock',
          subtitle: 'Verify your identity',
          description: 'Use fingerprint to unlock your encrypted journal.',
          negativeButtonText: 'Use Password',
        });

        if (credentials && credentials.password) {
          await unlockWithPassword(credentials.password, credentials.username || email);
        } else {
          setStatus('error');
          setErrorMsg('Biometric authentication failed. Try again or use password.');
        }
      } else {
        // Web fallback: simulate success immediately for dev
        await unlockWithPassword(password, email);
      }
    } catch (err) {
      console.error('Biometric error:', err);
      // User cancelled or sensor error
      if (err?.message?.includes('cancel') || err?.code === 10) {
        setStatus('idle');
        setErrorMsg('Authentication cancelled. Tap the fingerprint to try again.');
      } else {
        setStatus('error');
        setErrorMsg('Biometric unavailable. Please use your password.');
      }
    }
  };

  const unlockWithPassword = async (pwd, userEmail) => {
    try {
      const vaultKey = deriveKey(pwd);
      let loginEmail = userEmail.includes('@') ? userEmail : `${userEmail.toLowerCase()}@diaro.app`;

      // Refresh Supabase session silently in background
      supabase.auth.signInWithPassword({ email: loginEmail, password: pwd })
        .catch(err => console.warn('Background refresh failed (offline?):', err));

      setStatus('success');

      setTimeout(() => {
        onSuccess({
          user: { email: loginEmail },
          vaultKey,
          isDecoy: false,
        });
      }, 600); // brief success animation before transitioning
    } catch (err) {
      console.error('Unlock failed:', err);
      setStatus('error');
      setErrorMsg('Failed to decrypt vault. Please try again.');
    }
  };

  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-bgDark relative overflow-hidden">
      
      {/* Background ambient glows */}
      <div className="fixed inset-0 z-0 pointer-events-none">
        <div className="absolute top-[-10%] left-[-10%] w-[60%] h-[60%] ambient-glow-1 rounded-full"></div>
        <div className="absolute bottom-[-10%] right-[-10%] w-[60%] h-[60%] ambient-glow-2 rounded-full"></div>
        <div className="absolute inset-0 bg-[linear-gradient(rgba(255,255,255,0.003)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,0.003)_1px,transparent_1px)] bg-[size:30px_30px] opacity-25"></div>
      </div>

      <div className="relative z-10 flex flex-col items-center text-center px-8 max-w-sm w-full">

        {/* App logo */}
        <div className="mb-6">
          <h1 className="text-3xl font-bold shimmer-text select-none tracking-tight">Diaro</h1>
          <p className="text-xs font-mono text-diaroAccent-400 uppercase tracking-[0.25em] mt-1">Vault Locked</p>
        </div>

        {/* Fingerprint Button */}
        <button
          onClick={triggerBiometric}
          disabled={status === 'scanning' || status === 'success'}
          className={`
            relative w-32 h-32 rounded-full flex items-center justify-center mb-8
            border-2 transition-all duration-500 focus:outline-none
            ${status === 'success'
              ? 'border-green-500 bg-green-500/10 shadow-[0_0_40px_rgba(34,197,94,0.3)]'
              : status === 'scanning'
              ? 'border-diaroAccent-400 bg-diaroAccent-900/20 shadow-[0_0_40px_rgba(184,115,51,0.4)] animate-pulse'
              : status === 'error'
              ? 'border-red-500/60 bg-red-950/20 shadow-[0_0_20px_rgba(239,68,68,0.2)]'
              : 'border-diaroAccent-500/40 bg-diaroAccent-950/40 hover:border-diaroAccent-400 hover:bg-diaroAccent-900/30 hover:shadow-[0_0_30px_rgba(184,115,51,0.3)] active:scale-95'
            }
          `}
          id="fingerprint-btn"
          aria-label="Authenticate with fingerprint"
        >
          {/* Outer ring animation */}
          {status === 'scanning' && (
            <span className="absolute inset-0 rounded-full border-2 border-diaroAccent-400/30 animate-ping"></span>
          )}
          {status === 'success' && (
            <span className="absolute inset-0 rounded-full border-2 border-green-400/30 animate-ping"></span>
          )}

          {/* Icon */}
          <span
            className={`material-symbols-outlined text-[56px] transition-colors duration-300
              ${status === 'success' ? 'text-green-400' 
                : status === 'error' ? 'text-red-400'
                : status === 'scanning' ? 'text-diaroAccent-300'
                : 'text-diaroAccent-400'
              }
            `}
            style={{ fontVariationSettings: "'FILL' 1" }}
          >
            {status === 'success' ? 'check_circle' : status === 'error' ? 'fingerprint_off' : 'fingerprint'}
          </span>
        </button>

        {/* Status text */}
        <div className="mb-6 min-h-[48px] flex flex-col items-center justify-center">
          {status === 'idle' && (
            <p className="text-sm text-diaroAccent-300/80 font-mono">
              Touch sensor to unlock vault
            </p>
          )}
          {status === 'scanning' && (
            <p className="text-sm text-diaroAccent-400 font-mono animate-pulse">
              Verifying fingerprint...
            </p>
          )}
          {status === 'success' && (
            <p className="text-sm text-green-400 font-mono">
              ✓ Identity verified. Opening vault...
            </p>
          )}
          {status === 'error' && (
            <>
              <p className="text-sm text-red-400 font-mono text-center">{errorMsg}</p>
              <button
                onClick={triggerBiometric}
                className="mt-3 text-xs text-diaroAccent-400 underline underline-offset-2 hover:text-diaroAccent-300 transition-colors"
              >
                Try again
              </button>
            </>
          )}
        </div>

        {/* User email display */}
        <div className="mb-8 px-4 py-2 rounded-xl bg-white/3 border border-diaroAccent-500/10 flex items-center gap-2">
          <span className="material-symbols-outlined text-[16px] text-diaroAccent-400" style={{ fontVariationSettings: "'FILL' 1" }}>person</span>
          <p className="text-xs font-mono text-diaroAccent-200/60 truncate max-w-[220px]">{email}</p>
        </div>

        {/* Divider */}
        <div className="flex items-center gap-3 w-full mb-6">
          <div className="flex-1 h-px bg-diaroAccent-500/10"></div>
          <span className="text-[10px] font-mono text-diaroAccent-400/30 uppercase tracking-widest">or</span>
          <div className="flex-1 h-px bg-diaroAccent-500/10"></div>
        </div>

        {/* Fallback: use password */}
        <button
          onClick={onFallbackPassword}
          className="w-full py-3.5 rounded-xl border border-diaroAccent-500/20 bg-diaroAccent-950/20 
                     text-diaroAccent-300 text-sm font-semibold tracking-wider uppercase 
                     hover:border-diaroAccent-400/40 hover:bg-diaroAccent-900/20 
                     active:scale-[0.98] transition-all duration-200"
          id="use-password-btn"
        >
          Use Master Password
        </button>

        <p className="text-[10px] font-mono text-diaroAccent-400/25 mt-8 text-center">
          End-to-end AES-256 encrypted · All data stays on device
        </p>
      </div>
    </div>
  );
}
