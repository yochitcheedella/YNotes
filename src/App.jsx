import React, { useState, useEffect, useRef } from 'react';
import { supabase } from './supabaseClient';
import { decryptText, encryptText, deriveKey } from './cryptoHelper';
import { Preferences } from '@capacitor/preferences';
import { useAutoUpdate } from './hooks/useAutoUpdate';
import Login from './components/Login';
import BiometricLock from './components/BiometricLock';
import Dashboard from './components/Dashboard';
import EntryEditor from './components/EntryEditor';
import SearchMemories from './components/SearchMemories';
import Analytics from './components/Analytics';
import MediaVault from './components/MediaVault';
import Settings from './components/Settings';
import AuditLogs from './components/AuditLogs';
import Legal from './components/Legal';
import PinLock from './components/PinLock';

export default function App() {
  const [session, setSession] = useState(null); // { user, vaultKey, isDecoy }
  const [activeScreen, setActiveScreen] = useState('login');
  const [notes, setNotes] = useState([]);
  const [activeNote, setActiveNote] = useState(null);
  const [pathname, setPathname] = useState(window.location.pathname);
  const [pinLocked, setPinLocked] = useState(false);

  // Biometric gate: holds cached email+password while lock screen is shown
  // null = no cached creds (show login), object = show fingerprint lock screen
  const [biometricPending, setBiometricPending] = useState(null);
  
  // Auto-Update hook
  const { updateAvailable, updateInfo, executeUpdate, postponeUpdate } = useAutoUpdate();

  // Auto-lock tracking
  const [autoLockSeconds, setAutoLockSeconds] = useState(300); // 5 mins default
  const [loginMessage, setLoginMessage] = useState('');
  const lastActivityRef = useRef(Date.now());

  // Startup: Check for cached credentials and show biometric lock if found.
  // We do NOT auto-login — the user must pass biometric first.
  useEffect(() => {
    const checkCachedCredentials = async () => {
      try {
        const { value: pinHash } = await Preferences.get({ key: 'diaro_pin_hash' });
        if (pinHash) {
          setPinLocked(true);
          return; // Skip biometric check if PIN is enabled
        }

        const { value: email } = await Preferences.get({ key: 'diaro_remembered_email' });
        const { value: password } = await Preferences.get({ key: 'diaro_cached_password' });
        
        if (email && password) {
          // Show the fingerprint lock screen — do NOT open vault yet
          setBiometricPending({ email, password });
        }
        // else: biometricPending stays null → Login screen renders normally
      } catch (err) {
        console.error('Startup credential check error:', err);
      }
    };
    checkCachedCredentials();
  }, []);

  // Listen for browser navigation / history events
  useEffect(() => {
    const handlePopState = () => {
      setPathname(window.location.pathname);
    };
    window.addEventListener('popstate', handlePopState);
    return () => window.removeEventListener('popstate', handlePopState);
  }, []);

  // Lock app when sent to background
  useEffect(() => {
    const handleVisibilityChange = () => {
      if (document.hidden && session) {
        Preferences.get({ key: 'diaro_pin_hash' }).then(({ value }) => {
          if (value) setPinLocked(true);
        });
      }
    };
    document.addEventListener('visibilitychange', handleVisibilityChange);
    return () => document.removeEventListener('visibilitychange', handleVisibilityChange);
  }, [session]);

  // Called by BiometricLock after successful fingerprint authentication
  const handleBiometricSuccess = (sessionInfo) => {
    setBiometricPending(null);
    setSession(sessionInfo);
    setActiveScreen('dashboard');
    loadNotes(sessionInfo.vaultKey);
    lastActivityRef.current = Date.now();
  };

  // Called when user taps "Use Master Password" on the lock screen
  const handleBiometricFallback = () => {
    setBiometricPending(null);
    // biometricPending is cleared → renders normal Login screen
  };

  // Supabase Auth state listener
  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session: sbSession } }) => {
      // If we have a supabase session but no vaultKey, we still require them to enter password to decrypt.
      // Thus, we manage session state locally.
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange((event, sbSession) => {
      if (event === 'SIGNED_OUT') {
        handleLogout();
      }
    });

    return () => subscription.unsubscribe();
  }, []);

  // Fetch and decrypt notes from Supabase
  const loadNotes = async (vaultKey) => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      if (navigator.onLine) {
        await syncOfflineQueue(user.id);
      }

      const { data, error } = await supabase
        .from('notes')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', { ascending: false });

      if (error || !navigator.onLine) {
        console.warn('Network error or offline (loading from offline cache):', error?.message);
        await loadOfflineNotes(vaultKey, user.id);
        return;
      }

      if (data && data.length > 0) {
        // Decrypt notes in memory
        const decryptedList = data.map(n => ({
          ...n,
          title: decryptText(n.title_encrypted, vaultKey),
          content: decryptText(n.content_encrypted, vaultKey)
        }));
        setNotes(decryptedList);
        // Cache encrypted data for offline use
        await Preferences.set({ key: `diaro_offline_notes_${user.id}`, value: JSON.stringify(data) });
      } else {
        // Table is empty, seed starting notes for demo
        seedNotes(vaultKey, user.id);
      }
    } catch (err) {
      console.error('Error fetching diaries', err);
      try {
        const { data: { user } } = await supabase.auth.getUser();
        if (user) await loadOfflineNotes(vaultKey, user.id);
      } catch (e) {
        // user not available
      }
    }
  };

  const seedNotes = async (vaultKey, userId) => {
    const seed = [
      {
        title: 'Morning Reflection',
        content: 'Woke up feeling incredibly centered. The fog over the valley was thick this morning, reminding me that clarity often comes after a period of stillness...',
        mood: 'happy',
        created_at: new Date(2024, 9, 11, 8, 45).toISOString()
      },
      {
        title: 'The Creative Spark',
        content: 'Finally cracked the project structure. It feels like a massive weight has been lifted. I need to remember this feeling of flow when things get tough again. [Attached Blueprint Photo]',
        mood: 'excited',
        created_at: new Date(2024, 9, 11, 14, 15).toISOString()
      }
    ];

    try {
      const encryptedSeed = seed.map(s => ({
        title_encrypted: encryptText(s.title, vaultKey),
        content_encrypted: encryptText(s.content, vaultKey),
        mood: s.mood,
        user_id: userId,
        created_at: s.created_at
      }));

      const { data, error } = await supabase
        .from('notes')
        .insert(encryptedSeed)
        .select();

      if (!error && data) {
        const decryptedList = data.map(n => ({
          ...n,
          title: decryptText(n.title_encrypted, vaultKey),
          content: decryptText(n.content_encrypted, vaultKey)
        }));
        setNotes(decryptedList);
      } else {
        setNotes(seed.map((s, idx) => ({ ...s, id: idx + 1 })));
      }
    } catch (e) {
      console.error('Seed error:', e);
      setNotes(seed.map((s, idx) => ({ ...s, id: idx + 1 })));
    }
  };

  const loadOfflineNotes = async (vaultKey, userId) => {
    try {
      const { value } = await Preferences.get({ key: `diaro_offline_notes_${userId}` });
      if (value) {
        const data = JSON.parse(value);
        const decryptedList = data.map(n => ({
          ...n,
          title: decryptText(n.title_encrypted, vaultKey),
          content: decryptText(n.content_encrypted, vaultKey)
        }));
        setNotes(decryptedList);
      } else {
        setNotes([]);
      }
    } catch (err) {
      console.error('Error loading offline notes:', err);
      setNotes([]);
    }
  };

  const syncOfflineQueue = async (userId) => {
    try {
      const { value } = await Preferences.get({ key: `diaro_sync_queue_${userId}` });
      if (!value) return;
      const queue = JSON.parse(value);
      if (queue.length === 0) return;

      const remainingQueue = [];
      for (const action of queue) {
        try {
          if (action.type === 'INSERT') {
            const { error } = await supabase.from('notes').insert(action.payload);
            if (error) throw error;
          } else if (action.type === 'UPDATE') {
            const { error } = await supabase.from('notes').update(action.payload).eq('id', action.id);
            if (error) throw error;
          }
        } catch (e) {
          console.error('Failed to sync action:', action, e);
          remainingQueue.push(action);
        }
      }
      await Preferences.set({ key: `diaro_sync_queue_${userId}`, value: JSON.stringify(remainingQueue) });
    } catch (err) {
      console.error('Error processing sync queue:', err);
    }
  };

  // Auth Success hook
  const handleAuthSuccess = (sessionInfo) => {
    setSession(sessionInfo);
    setActiveScreen('dashboard');
    loadNotes(sessionInfo.vaultKey);
    // Reset timer
    lastActivityRef.current = Date.now();
  };

  const handlePinUnlock = async (vaultKey) => {
    const { data } = await supabase.auth.getUser();
    if (data?.user) {
      setSession({ user: data.user, vaultKey, isDecoy: false });
      setPinLocked(false);
      setActiveScreen('dashboard');
      loadNotes(vaultKey);
      lastActivityRef.current = Date.now();
    } else {
      // Session invalid, force login
      handleLogout();
    }
  };

  const handleLogout = async () => {
    await supabase.auth.signOut();
    await Preferences.remove({ key: 'diaro_remembered_email' });
    await Preferences.remove({ key: 'diaro_cached_password' });
    await Preferences.remove({ key: 'diaro_pin_hash' });
    await Preferences.remove({ key: 'diaro_encrypted_vault_key' });
    setSession(null);
    setBiometricPending(null);
    setPinLocked(false);
    setNotes([]);
    setActiveNote(null);
    setActiveScreen('login');
  };

  // Inactivity tracking (Auto lock)
  useEffect(() => {
    if (!session) return;

    const checkInterval = setInterval(() => {
      const inactiveMs = Date.now() - lastActivityRef.current;
      if (inactiveMs >= autoLockSeconds * 1000) {
        handleLogout();
        setLoginMessage('Vault Auto-Locked due to session inactivity.');
      }
    }, 5000);

    const recordActivity = () => {
      lastActivityRef.current = Date.now();
    };

    window.addEventListener('mousedown', recordActivity);
    window.addEventListener('keydown', recordActivity);
    window.addEventListener('touchstart', recordActivity);

    return () => {
      clearInterval(checkInterval);
      window.removeEventListener('mousedown', recordActivity);
      window.removeEventListener('keydown', recordActivity);
      window.removeEventListener('touchstart', recordActivity);
    };
  }, [session, autoLockSeconds]);

  // Save / Delete Note handlers
  const handleSaveComplete = (savedNote, deletedId) => {
    if (deletedId) {
      setNotes(prev => prev.filter(n => n.id !== deletedId));
    } else if (savedNote) {
      setNotes(prev => {
        const exists = prev.some(n => n.id === savedNote.id);
        if (exists) {
          return prev.map(n => n.id === savedNote.id ? savedNote : n);
        } else {
          return [savedNote, ...prev];
        }
      });
    }
    setActiveNote(null);
    setActiveScreen('dashboard');
  };

  // 1. Check path-based routes first (publicly accessible legal pages)
  if (pathname === '/privacy-policy') {
    return (
      <div className="min-h-screen flex flex-col justify-between relative bg-bgDark">
        <Legal 
          onCancel={() => {
            window.history.pushState({}, '', '/');
            setPathname('/');
          }} 
          initialTab="privacy" 
        />
      </div>
    );
  }

  if (pathname === '/terms-of-service') {
    return (
      <div className="min-h-screen flex flex-col justify-between relative bg-bgDark">
        <Legal 
          onCancel={() => {
            window.history.pushState({}, '', '/');
            setPathname('/');
          }} 
          initialTab="tos" 
        />
      </div>
    );
  }

  // 2. PIN Lock takes precedence if enabled
  if (pinLocked) {
    return (
      <PinLock 
        onUnlock={handlePinUnlock} 
        onLogout={handleLogout} 
      />
    );
  }

  // 3. Show fingerprint lock screen if cached credentials exist
  if (biometricPending) {
    return (
      <BiometricLock
        email={biometricPending.email}
        password={biometricPending.password}
        onSuccess={handleBiometricSuccess}
        onFallbackPassword={handleBiometricFallback}
      />
    );
  }

  // 3. No cached credentials → show standard login
  if (!session) {
    return (
      <Login 
        onAuthSuccess={handleAuthSuccess} 
        initialMessage={loginMessage} 
        clearInitialMessage={() => setLoginMessage('')} 
        onShowLegal={() => {
          window.history.pushState({}, '', '/privacy-policy');
          setPathname('/privacy-policy');
        }}
      />
    );
  }

  return (
    <div className="min-h-screen flex flex-col justify-between relative bg-bgDark">
      
      {/* Background Ambient Glows */}
      <div className="fixed inset-0 z-0 pointer-events-none">
        <div className="absolute top-[-10%] left-[-10%] w-[60%] h-[60%] ambient-glow-1 rounded-full"></div>
        <div className="absolute bottom-[-10%] right-[-10%] w-[60%] h-[60%] ambient-glow-2 rounded-full"></div>
        <div className="absolute inset-0 bg-[linear-gradient(rgba(255,255,255,0.003)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,0.003)_1px,transparent_1px)] bg-[size:30px_30px] opacity-25"></div>
      </div>

      {/* Top App Bar */}
      <header className="fixed top-0 w-full z-50 bg-[#0b1326]/80 backdrop-blur-xl border-b border-diaroAccent-500/10 flex items-center justify-between px-6 h-16">
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-full bg-diaroAccent-900/60 border border-diaroAccent-500/25 flex items-center justify-center overflow-hidden">
            <span className="material-symbols-outlined text-diaroAccent-400 text-sm">lock</span>
          </div>
          <h1 className="text-xl font-bold shimmer-text select-none">Diaro</h1>
        </div>
        <div className="flex items-center gap-2">
          <button 
            onClick={() => setActiveScreen(activeScreen === 'audit_logs' ? 'dashboard' : 'audit_logs')}
            className="w-10 h-10 flex items-center justify-center rounded-full hover:bg-white/10 transition-colors active:scale-95 text-diaroAccent-400"
            title="Security Audit Logs"
          >
            <span className="material-symbols-outlined">
              {activeScreen === 'audit_logs' ? 'close' : 'shield'}
            </span>
          </button>
          <button 
            onClick={() => setActiveScreen(activeScreen === 'search' ? 'dashboard' : 'search')}
            className="w-10 h-10 flex items-center justify-center rounded-full hover:bg-white/10 transition-colors active:scale-95 text-diaroAccent-400"
          >
            <span className="material-symbols-outlined">
              {activeScreen === 'search' ? 'close' : 'search'}
            </span>
          </button>
        </div>
      </header>

      {/* Main Viewport Content */}
      <div className="flex-grow">
        {activeScreen === 'dashboard' && (
          <Dashboard 
            notes={notes} 
            onNavigate={setActiveScreen}
            onSelectNote={(note) => { setActiveNote(note); setActiveScreen('editor'); }}
            onNewNote={() => { setActiveNote(null); setActiveScreen('editor'); }}
          />
        )}
        {activeScreen === 'editor' && (
          <EntryEditor 
            activeNote={activeNote}
            vaultKey={session.vaultKey}
            onSaveComplete={handleSaveComplete}
            onCancel={() => { setActiveNote(null); setActiveScreen('dashboard'); }}
          />
        )}
        {activeScreen === 'search' && (
          <SearchMemories 
            notes={notes}
            onSelectNote={(note) => { setActiveNote(note); setActiveScreen('editor'); }}
          />
        )}
        {activeScreen === 'analytics' && (
          <Analytics 
            notes={notes}
            onNavigate={setActiveScreen}
          />
        )}
        {activeScreen === 'media' && (
          <MediaVault />
        )}
        {activeScreen === 'settings' && (
          <Settings 
            vaultKey={session.vaultKey}
            onLogout={handleLogout} 
            onShowLegal={() => {
              window.history.pushState({}, '', '/privacy-policy');
              setPathname('/privacy-policy');
            }} 
          />
        )}
        {activeScreen === 'audit_logs' && (
          <AuditLogs onCancel={() => setActiveScreen('dashboard')} />
        )}
      </div>

      {/* Bottom Nav Bar */}
      <nav className="fixed bottom-0 left-0 w-full z-50 flex justify-around items-center pt-2 pb-6 px-4 bg-[#0b1326]/90 backdrop-blur-xl border-t border-diaroAccent-500/10 shadow-lg">
        <button 
          onClick={() => setActiveScreen('dashboard')}
          className={`flex flex-col items-center justify-center rounded-full px-4 py-1 transition-all duration-200 active:scale-90
            ${activeScreen === 'dashboard' ? 'text-diaroAccent-400 font-semibold' : 'text-diaroAccent-300/40 hover:text-white'}
          `}
        >
          <span className="material-symbols-outlined" style={{ fontVariationSettings: activeScreen === 'dashboard' ? "'FILL' 1" : "'FILL' 0" }}>dashboard</span>
          <span className="text-[10px] font-mono mt-0.5">Vault</span>
        </button>
        
        <button 
          onClick={() => { setActiveNote(null); setActiveScreen('editor'); }}
          className={`flex flex-col items-center justify-center rounded-full px-4 py-1 transition-all duration-200 active:scale-90
            ${activeScreen === 'editor' ? 'text-diaroAccent-400 font-semibold' : 'text-diaroAccent-300/40 hover:text-white'}
          `}
        >
          <span className="material-symbols-outlined">add_circle</span>
          <span className="text-[10px] font-mono mt-0.5">Write</span>
        </button>

        <button 
          onClick={() => setActiveScreen('media')}
          className={`flex flex-col items-center justify-center rounded-full px-4 py-1 transition-all duration-200 active:scale-90
            ${activeScreen === 'media' ? 'text-diaroAccent-400 font-semibold' : 'text-diaroAccent-300/40 hover:text-white'}
          `}
        >
          <span className="material-symbols-outlined" style={{ fontVariationSettings: activeScreen === 'media' ? "'FILL' 1" : "'FILL' 0" }}>perm_media</span>
          <span className="text-[10px] font-mono mt-0.5">Media</span>
        </button>

        <button 
          onClick={() => setActiveScreen('analytics')}
          className={`flex flex-col items-center justify-center rounded-full px-4 py-1 transition-all duration-200 active:scale-90
            ${activeScreen === 'analytics' ? 'text-diaroAccent-400 font-semibold' : 'text-diaroAccent-300/40 hover:text-white'}
          `}
        >
          <span className="material-symbols-outlined">analytics</span>
          <span className="text-[10px] font-mono mt-0.5">Stats</span>
        </button>

        <button 
          onClick={() => setActiveScreen('settings')}
          className={`flex flex-col items-center justify-center rounded-full px-4 py-1 transition-all duration-200 active:scale-90
            ${activeScreen === 'settings' ? 'text-diaroAccent-400 font-semibold' : 'text-diaroAccent-300/40 hover:text-white'}
          `}
        >
          <span className="material-symbols-outlined">settings</span>
          <span className="text-[10px] font-mono mt-0.5">Config</span>
        </button>
      </nav>

      {/* Auto-Update Modal Overlay */}
      {updateAvailable && updateInfo && (
        <div className="fixed inset-0 z-[100] bg-black/80 flex items-center justify-center p-4 backdrop-blur-sm">
          <div className="glass-card rounded-3xl p-6 w-full max-w-md space-y-4 text-center border border-diaroAccent-500/30 shadow-2xl relative overflow-hidden animate-fade-in">
            <div className="w-16 h-16 rounded-full bg-diaroAccent-900/60 mx-auto flex items-center justify-center mb-2 border border-diaroAccent-500/30">
              <span className="material-symbols-outlined text-[32px] text-diaroAccent-400">system_update</span>
            </div>
            <h3 className="text-xl font-bold text-white tracking-wide">Update Available</h3>
            <p className="text-sm text-diaroAccent-200/80 font-mono">Version {updateInfo.version}</p>
            
            <div className="bg-slate-900/50 rounded-xl p-4 text-left border border-white/5 my-4">
              <p className="text-sm text-diaroAccent-100/70 whitespace-pre-line leading-relaxed font-sans">{updateInfo.releaseNotes}</p>
            </div>
            
            <div className="flex gap-3 pt-2">
              <button onClick={postponeUpdate} className="flex-1 py-3 bg-white/5 hover:bg-white/10 text-white text-xs font-semibold uppercase tracking-wider rounded-xl transition-colors">
                Later
              </button>
              <button onClick={executeUpdate} className="flex-1 py-3 bg-diaroAccent-600 hover:bg-diaroAccent-500 text-white text-xs font-semibold uppercase tracking-wider rounded-xl transition-all hover:shadow-[0_0_15px_rgba(184, 115, 51,0.4)]">
                Install Now
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
