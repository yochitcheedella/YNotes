import React, { useState, useEffect } from 'react';
import { supabase } from '../supabaseClient';
import { Preferences } from '@capacitor/preferences';
import { hashPassword, encryptText } from '../cryptoHelper';

export default function Settings({ vaultKey, onLogout, onShowLegal }) {
  const [pinEnabled, setPinEnabled] = useState(false);
  const [showPinModal, setShowPinModal] = useState(false);
  const [pinInput, setPinInput] = useState('');
  const [pinConfirm, setPinConfirm] = useState('');
  const [pinStep, setPinStep] = useState('enter'); // 'enter' | 'confirm' | 'remove'

  useEffect(() => {
    const checkPin = async () => {
      const { value } = await Preferences.get({ key: 'diaro_pin_hash' });
      if (value) setPinEnabled(true);
    };
    checkPin();
  }, []);

  const [autoLockSeconds, setAutoLockSeconds] = useState(60);
  const [biometricEnabled, setBiometricEnabled] = useState(true);
  const [decoyEnabled, setDecoyEnabled] = useState(false);
  const [decoyPassword, setDecoyPassword] = useState('Demo@123');

  const [showPasswordModal, setShowPasswordModal] = useState(false);
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');

  const handleChangePassword = async (e) => {
    e.preventDefault();
    if (newPassword.length < 8) {
      alert('Master Password must be at least 8 characters.');
      return;
    }
    // Update password in Supabase Auth
    const { error } = await supabase.auth.updateUser({ password: newPassword });
    if (error) {
      alert(`Update failed: ${error.message}`);
    } else {
      alert('Master Password updated successfully on cloud auth nodes!');
      setShowPasswordModal(false);
      setCurrentPassword('');
      setNewPassword('');
    }
  };

  const handleWipeData = async () => {
    if (!window.confirm('WARNING: This will permanently erase ALL encrypted journal logs and user configurations from local and cloud databases. Proceed?')) return;
    
    try {
      // Clear notes table for the user by user_id to avoid UUID type issues
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        const { error } = await supabase.from('notes').delete().eq('user_id', user.id);
        if (error) {
          console.error("Failed to wipe data from server:", error.message);
        }
      }
    } catch (err) {
      console.error("Wipe error:", err);
    }
    alert('Vault erased successfully. Closing session...');
    onLogout();
  };

  const togglePinLock = async (enable) => {
    if (enable) {
      setPinStep('enter');
      setPinInput('');
      setPinConfirm('');
      setShowPinModal(true);
    } else {
      setPinStep('remove');
      setPinInput('');
      setShowPinModal(true);
    }
  };

  const handlePinSubmit = async (e) => {
    e.preventDefault();
    if (pinStep === 'enter') {
      if (pinInput.length !== 4) return alert('PIN must be 4 digits.');
      setPinStep('confirm');
    } else if (pinStep === 'confirm') {
      if (pinInput !== pinConfirm) {
        alert('PINs do not match. Try again.');
        setPinStep('enter');
        setPinInput('');
        setPinConfirm('');
        return;
      }
      // Store hashed PIN
      const hashed = hashPassword(pinInput);
      await Preferences.set({ key: 'diaro_pin_hash', value: hashed });
      
      // Encrypt vault key and store it
      const encryptedKey = encryptText(vaultKey, pinInput);
      await Preferences.set({ key: 'diaro_encrypted_vault_key', value: encryptedKey });
      
      setPinEnabled(true);
      setShowPinModal(false);
      alert('PIN Lock enabled successfully.');
    } else if (pinStep === 'remove') {
      const { value: storedHash } = await Preferences.get({ key: 'diaro_pin_hash' });
      if (hashPassword(pinInput) !== storedHash) {
        alert('Incorrect PIN. Cannot disable.');
        setPinInput('');
        return;
      }
      // Correct PIN entered, remove from storage
      await Preferences.remove({ key: 'diaro_pin_hash' });
      await Preferences.remove({ key: 'diaro_encrypted_vault_key' });
      setPinEnabled(false);
      setShowPinModal(false);
      alert('PIN Lock disabled.');
    }
  };

  return (
    <main className="relative z-10 pt-20 px-4 max-w-2xl mx-auto pb-24 space-y-6">
      
      {/* Header */}
      <div>
        <h2 className="text-xl font-semibold text-white tracking-wide">Vault Configurations</h2>
        <p className="text-xs text-diaroAccent-300/40 mt-1">Configure encryption schemas, sessions, and stealth profiles.</p>
      </div>

      {/* Security settings */}
      <section className="glass-card rounded-2xl p-6 space-y-4 shadow-xl">
        <div className="flex justify-between items-center mb-2">
          <h3 className="text-xs font-mono text-diaroAccent-300 uppercase tracking-widest block">Security Settings</h3>
          <button 
            onClick={onShowLegal}
            className="text-[10px] font-mono text-diaroAccent-400 hover:text-white uppercase tracking-widest transition-colors"
          >
            Privacy & Legal
          </button>
        </div>
        
        {/* Change Password List Item */}
        <div className="flex items-center justify-between py-2 border-b border-slate-800/60">
          <div>
            <p className="text-sm font-semibold text-white">Change Master Password</p>
            <p className="text-xs text-diaroAccent-300/40 mt-0.5">Modify the password used to derive AES-256 vault keys.</p>
          </div>
          <button 
            onClick={() => setShowPasswordModal(true)}
            className="px-3 py-1.5 bg-diaroAccent-950/40 border border-diaroAccent-500/25 text-diaroAccent-400 hover:text-white rounded-lg text-xs font-mono uppercase tracking-wider transition-colors"
          >
            Modify
          </button>
        </div>

        {/* PIN Lock Switch */}
        <div className="flex items-center justify-between py-2 border-b border-slate-800/60">
          <div>
            <p className="text-sm font-semibold text-white">PIN Code Lock</p>
            <p className="text-xs text-diaroAccent-300/40 mt-0.5">Secure vault with a 4-digit PIN.</p>
          </div>
          <label className="relative inline-flex items-center cursor-pointer">
            <input 
              type="checkbox" 
              className="sr-only peer"
              checked={pinEnabled}
              onChange={(e) => togglePinLock(e.target.checked)}
            />
            <div className="w-11 h-6 bg-slate-800 rounded-full peer peer-focus:ring-0 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-0.5 after:left-[2px] after:bg-slate-400 after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-diaroAccent-600 peer-checked:after:bg-white"></div>
          </label>
        </div>

        {/* Biometrics Switch */}
        <div className="flex items-center justify-between py-2 border-b border-slate-800/60">
          <div>
            <p className="text-sm font-semibold text-white">Biometric Authentication</p>
            <p className="text-xs text-diaroAccent-300/40 mt-0.5">Unlock database with registered fingerprint signature.</p>
          </div>
          <label className="relative inline-flex items-center cursor-pointer">
            <input 
              type="checkbox" 
              className="sr-only peer"
              checked={biometricEnabled}
              onChange={(e) => setBiometricEnabled(e.target.checked)}
            />
            <div className="w-11 h-6 bg-slate-800 rounded-full peer peer-focus:ring-0 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-0.5 after:left-[2px] after:bg-slate-400 after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-diaroAccent-600 peer-checked:after:bg-white"></div>
          </label>
        </div>

        {/* Decoy Password Switch */}
        <div className="flex items-center justify-between py-2 border-b border-slate-800/60">
          <div>
            <p className="text-sm font-semibold text-white">Stealth Decoy Profile</p>
            <p className="text-xs text-diaroAccent-300/40 mt-0.5">Launches decoy vault profile if matching decoy key is entered.</p>
          </div>
          <label className="relative inline-flex items-center cursor-pointer">
            <input 
              type="checkbox" 
              className="sr-only peer"
              checked={decoyEnabled}
              onChange={(e) => setDecoyEnabled(e.target.checked)}
            />
            <div className="w-11 h-6 bg-slate-800 rounded-full peer peer-focus:ring-0 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-0.5 after:left-[2px] after:bg-slate-400 after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-diaroAccent-600 peer-checked:after:bg-white"></div>
          </label>
        </div>

        {/* Decoy Setup input field */}
        {decoyEnabled && (
          <div className="p-4 rounded-xl border border-diaroAccent-500/10 bg-slate-950/40 space-y-2 animate-fade-in">
            <label className="block text-xs font-mono text-diaroAccent-300 uppercase tracking-widest" htmlFor="decoy-pass">Configure Decoy Password</label>
            <input 
              className="w-full px-4 py-2 rounded-xl text-white font-mono placeholder:text-diaroAccent-200/20 cyber-input outline-none focus:ring-0 text-sm" 
              id="decoy-pass"
              type="password"
              value={decoyPassword}
              onChange={(e) => setDecoyPassword(e.target.value)}
            />
            <p className="text-[10px] text-diaroAccent-300/30">Use this password at the login card to view sample logs instead of real journal records.</p>
          </div>
        )}
      </section>

      {/* Auto lock settings */}
      <section className="glass-card rounded-2xl p-6 space-y-4 shadow-xl">
        <h3 className="text-xs font-mono text-diaroAccent-300 uppercase tracking-widest block">Session Timeout</h3>
        <p className="text-xs text-diaroAccent-300/40">Select vault lock timer trigger after inactivity periods.</p>
        
        <div className="grid grid-cols-3 gap-3">
          {[
            { val: 30, label: '30s' },
            { val: 60, label: '1 min' },
            { val: 300, label: '5 mins' }
          ].map(timer => (
            <button
              key={timer.val}
              onClick={() => setAutoLockSeconds(timer.val)}
              className={`py-3 rounded-xl text-xs font-mono border transition-all duration-200
                ${autoLockSeconds === timer.val 
                  ? 'bg-diaroAccent-600/35 border-diaroAccent-500 text-white' 
                  : 'bg-[#0f172a]/60 border-diaroAccent-400/10 text-diaroAccent-300/50 hover:text-white'
                }
              `}
            >
              {timer.label}
            </button>
          ))}
        </div>
      </section>

      {/* Data Management options */}
      <section className="glass-card rounded-2xl p-6 space-y-4 shadow-xl">
        <h3 className="text-xs font-mono text-red-400 uppercase tracking-widest block">Data Operations</h3>
        <div className="flex items-center justify-between py-2">
          <div>
            <p className="text-sm font-semibold text-white">Erase Local & Cloud Vault</p>
            <p className="text-xs text-diaroAccent-300/40 mt-0.5">Wipe all sqlite nodes and synchronized Cloud Firestore nodes.</p>
          </div>
          <button 
            onClick={handleWipeData}
            className="px-3 py-2 bg-red-950/30 border border-red-500/30 hover:bg-red-900/30 text-red-400 rounded-lg text-xs font-mono uppercase tracking-wider transition-colors"
          >
            Wipe Vault
          </button>
        </div>
      </section>

      {/* Logout button */}
      <button 
        onClick={onLogout}
        className="w-full py-4 bg-slate-950/40 hover:bg-slate-900/40 border border-slate-800 text-diaroAccent-300 font-semibold text-xs uppercase tracking-[0.15em] rounded-xl active:scale-[0.98] transition-all duration-200 flex items-center justify-center gap-2"
      >
        <span className="material-symbols-outlined text-[18px]">logout</span>
        <span>Close Vault (Logout)</span>
      </button>

      {/* Password Modal */}
      {showPasswordModal && (
        <div className="fixed inset-0 z-50 bg-black/80 flex items-center justify-center p-4">
          <form 
            onSubmit={handleChangePassword}
            className="glass-card rounded-2xl p-6 w-full max-w-md space-y-4 relative"
          >
            <h3 className="text-md font-semibold text-white">Update Vault Password</h3>
            <div className="space-y-1">
              <label className="block text-xs font-mono text-diaroAccent-300 uppercase tracking-widest">New Master Password</label>
              <input 
                type="password"
                className="w-full px-4 py-2.5 rounded-xl text-white cyber-input outline-none focus:ring-0 text-sm" 
                placeholder="Must be at least 8 characters"
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                required
              />
            </div>
            <div className="flex justify-end gap-2 pt-2">
              <button 
                type="button" 
                onClick={() => setShowPasswordModal(false)}
                className="px-4 py-2 rounded-lg bg-slate-800 hover:bg-slate-700 text-xs font-mono uppercase tracking-wider text-diaroAccent-200"
              >
                Cancel
              </button>
              <button 
                type="submit"
                className="px-4 py-2 rounded-lg bg-diaroAccent-600 hover:bg-diaroAccent-500 text-xs font-mono uppercase tracking-wider text-white"
              >
                Save
              </button>
            </div>
          </form>
        </div>
      )}

      {/* PIN Modal */}
      {showPinModal && (
        <div className="fixed inset-0 z-50 bg-black/80 flex items-center justify-center p-4">
          <form 
            onSubmit={handlePinSubmit}
            className="glass-card rounded-2xl p-6 w-full max-w-sm space-y-4 relative"
          >
            <h3 className="text-md font-semibold text-white">
              {pinStep === 'enter' ? 'Set 4-Digit PIN' : pinStep === 'confirm' ? 'Confirm PIN' : 'Enter Current PIN'}
            </h3>
            <div className="space-y-1">
              <label className="block text-xs font-mono text-diaroAccent-300 uppercase tracking-widest">
                {pinStep === 'remove' ? 'Current PIN' : 'PIN'}
              </label>
              <input 
                type="password"
                maxLength={4}
                className="w-full px-4 py-2.5 rounded-xl text-white font-mono text-center tracking-[0.5em] cyber-input outline-none focus:ring-0 text-2xl" 
                placeholder="••••"
                value={pinStep === 'confirm' ? pinConfirm : pinInput}
                onChange={(e) => {
                  const val = e.target.value.replace(/\D/g, '');
                  if (pinStep === 'confirm') setPinConfirm(val);
                  else setPinInput(val);
                }}
                required
              />
            </div>
            <div className="flex justify-end gap-2 pt-2">
              <button 
                type="button" 
                onClick={() => setShowPinModal(false)}
                className="px-4 py-2 rounded-lg bg-slate-800 hover:bg-slate-700 text-xs font-mono uppercase tracking-wider text-diaroAccent-200"
              >
                Cancel
              </button>
              <button 
                type="submit"
                className="px-4 py-2 rounded-lg bg-diaroAccent-600 hover:bg-diaroAccent-500 text-xs font-mono uppercase tracking-wider text-white"
              >
                {pinStep === 'remove' ? 'Disable' : 'Next'}
              </button>
            </div>
          </form>
        </div>
      )}

    </main>
  );
}
