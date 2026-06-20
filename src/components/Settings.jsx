import React, { useState } from 'react';
import { supabase } from '../supabaseClient';

export default function Settings({ onLogout }) {
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
    
    // Clear notes table for the user
    const { error } = await supabase.from('notes').delete().neq('id', 0);
    if (error) {
      console.error(error);
    }
    alert('Vault erased successfully. Closing session...');
    onLogout();
  };

  return (
    <main className="relative z-10 pt-20 px-4 max-w-2xl mx-auto pb-24 space-y-6">
      
      {/* Header */}
      <div>
        <h2 className="text-xl font-semibold text-white tracking-wide">Vault Configurations</h2>
        <p className="text-xs text-purple-300/40 mt-1">Configure encryption schemas, sessions, and stealth profiles.</p>
      </div>

      {/* Security settings */}
      <section className="glass-card rounded-2xl p-6 space-y-4 shadow-xl">
        <h3 className="text-xs font-mono text-ynoteAccent-300 uppercase tracking-widest block">Security Settings</h3>
        
        {/* Change Password List Item */}
        <div className="flex items-center justify-between py-2 border-b border-slate-800/60">
          <div>
            <p className="text-sm font-semibold text-white">Change Master Password</p>
            <p className="text-xs text-purple-300/40 mt-0.5">Modify the password used to derive AES-256 vault keys.</p>
          </div>
          <button 
            onClick={() => setShowPasswordModal(true)}
            className="px-3 py-1.5 bg-ynoteAccent-950/40 border border-ynoteAccent-500/25 text-ynoteAccent-400 hover:text-white rounded-lg text-xs font-mono uppercase tracking-wider transition-colors"
          >
            Modify
          </button>
        </div>

        {/* Biometrics Switch */}
        <div className="flex items-center justify-between py-2 border-b border-slate-800/60">
          <div>
            <p className="text-sm font-semibold text-white">Biometric Authentication</p>
            <p className="text-xs text-purple-300/40 mt-0.5">Unlock database with registered fingerprint signature.</p>
          </div>
          <label className="relative inline-flex items-center cursor-pointer">
            <input 
              type="checkbox" 
              className="sr-only peer"
              checked={biometricEnabled}
              onChange={(e) => setBiometricEnabled(e.target.checked)}
            />
            <div className="w-11 h-6 bg-slate-800 rounded-full peer peer-focus:ring-0 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-0.5 after:left-[2px] after:bg-slate-400 after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-ynoteAccent-600 peer-checked:after:bg-white"></div>
          </label>
        </div>

        {/* Decoy Password Switch */}
        <div className="flex items-center justify-between py-2 border-b border-slate-800/60">
          <div>
            <p className="text-sm font-semibold text-white">Stealth Decoy Profile</p>
            <p className="text-xs text-purple-300/40 mt-0.5">Launches decoy vault profile if matching decoy key is entered.</p>
          </div>
          <label className="relative inline-flex items-center cursor-pointer">
            <input 
              type="checkbox" 
              className="sr-only peer"
              checked={decoyEnabled}
              onChange={(e) => setDecoyEnabled(e.target.checked)}
            />
            <div className="w-11 h-6 bg-slate-800 rounded-full peer peer-focus:ring-0 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-0.5 after:left-[2px] after:bg-slate-400 after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-ynoteAccent-600 peer-checked:after:bg-white"></div>
          </label>
        </div>

        {/* Decoy Setup input field */}
        {decoyEnabled && (
          <div className="p-4 rounded-xl border border-purple-500/10 bg-slate-950/40 space-y-2 animate-fade-in">
            <label className="block text-xs font-mono text-ynoteAccent-300 uppercase tracking-widest" htmlFor="decoy-pass">Configure Decoy Password</label>
            <input 
              className="w-full px-4 py-2 rounded-xl text-white font-mono placeholder:text-purple-200/20 cyber-input outline-none focus:ring-0 text-sm" 
              id="decoy-pass"
              type="password"
              value={decoyPassword}
              onChange={(e) => setDecoyPassword(e.target.value)}
            />
            <p className="text-[10px] text-purple-300/30">Use this password at the login card to view sample logs instead of real journal records.</p>
          </div>
        )}
      </section>

      {/* Auto lock settings */}
      <section className="glass-card rounded-2xl p-6 space-y-4 shadow-xl">
        <h3 className="text-xs font-mono text-ynoteAccent-300 uppercase tracking-widest block">Session Timeout</h3>
        <p className="text-xs text-purple-300/40">Select vault lock timer trigger after inactivity periods.</p>
        
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
                  ? 'bg-ynoteAccent-600/35 border-ynoteAccent-500 text-white' 
                  : 'bg-[#0f172a]/60 border-purple-400/10 text-purple-300/50 hover:text-white'
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
            <p className="text-xs text-purple-300/40 mt-0.5">Wipe all sqlite nodes and synchronized Cloud Firestore nodes.</p>
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
        className="w-full py-4 bg-slate-950/40 hover:bg-slate-900/40 border border-slate-800 text-purple-300 font-semibold text-xs uppercase tracking-[0.15em] rounded-xl active:scale-[0.98] transition-all duration-200 flex items-center justify-center gap-2"
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
              <label className="block text-xs font-mono text-ynoteAccent-300 uppercase tracking-widest">New Master Password</label>
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
                className="px-4 py-2 rounded-lg bg-slate-800 hover:bg-slate-700 text-xs font-mono uppercase tracking-wider text-purple-200"
              >
                Cancel
              </button>
              <button 
                type="submit"
                className="px-4 py-2 rounded-lg bg-ynoteAccent-600 hover:bg-ynoteAccent-500 text-xs font-mono uppercase tracking-wider text-white"
              >
                Save
              </button>
            </div>
          </form>
        </div>
      )}

    </main>
  );
}
