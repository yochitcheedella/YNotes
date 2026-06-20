import React, { useState, useEffect, useRef } from 'react';
import { supabase } from './supabaseClient';
import { decryptText, encryptText } from './cryptoHelper';
import Login from './components/Login';
import Dashboard from './components/Dashboard';
import EntryEditor from './components/EntryEditor';
import SearchMemories from './components/SearchMemories';
import Analytics from './components/Analytics';
import MediaVault from './components/MediaVault';
import Settings from './components/Settings';
import AuditLogs from './components/AuditLogs';

export default function App() {
  const [session, setSession] = useState(null); // { user, vaultKey, isDecoy }
  const [activeScreen, setActiveScreen] = useState('login');
  const [notes, setNotes] = useState([]);
  const [activeNote, setActiveNote] = useState(null);

  // Auto-lock tracking
  const [autoLockSeconds, setAutoLockSeconds] = useState(300); // 5 mins default
  const [loginMessage, setLoginMessage] = useState('');
  const lastActivityRef = useRef(Date.now());

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

      const { data, error } = await supabase
        .from('notes')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', { ascending: false });

      if (error) {
        console.warn('Supabase fetch notes error (using mock fallback):', error.message);
        // Fallback to local storage or starting mock notes
        loadMockNotes(vaultKey);
        return;
      }

      if (data && data.length > 0) {
        // Decrypt notes in memory
        const decryptedList = data.map(n => ({
          ...n,
          title: decryptText(n.title, vaultKey),
          content: decryptText(n.content, vaultKey)
        }));
        setNotes(decryptedList);
      } else {
        // Table is empty, seed starting notes for demo
        seedNotes(vaultKey, user.id);
      }
    } catch (err) {
      console.error('Error fetching diaries', err);
      loadMockNotes(vaultKey);
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
        title: encryptText(s.title, vaultKey),
        content: encryptText(s.content, vaultKey),
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
          title: decryptText(n.title, vaultKey),
          content: decryptText(n.content, vaultKey)
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

  const loadMockNotes = (vaultKey) => {
    // Return standard mock notes for testing
    const seed = [
      {
        id: 1,
        title: 'Morning Reflection',
        content: 'Woke up feeling incredibly centered. The fog over the valley was thick this morning, reminding me that clarity often comes after a period of stillness...',
        mood: 'happy',
        created_at: new Date(2024, 9, 11, 8, 45).toISOString()
      },
      {
        id: 2,
        title: 'The Creative Spark',
        content: 'Finally cracked the project structure. It feels like a massive weight has been lifted. [Attached Blueprint Photo]',
        mood: 'excited',
        created_at: new Date(2024, 9, 11, 14, 15).toISOString()
      }
    ];
    setNotes(seed);
  };

  // Auth Success hook
  const handleAuthSuccess = (sessionInfo) => {
    setSession(sessionInfo);
    setActiveScreen('dashboard');
    loadNotes(sessionInfo.vaultKey);
    // Reset timer
    lastActivityRef.current = Date.now();
  };

  const handleLogout = async () => {
    await supabase.auth.signOut();
    setSession(null);
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

  if (!session) {
    return (
      <Login 
        onAuthSuccess={handleAuthSuccess} 
        initialMessage={loginMessage} 
        clearInitialMessage={() => setLoginMessage('')} 
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
      <header className="fixed top-0 w-full z-50 bg-[#0b1326]/80 backdrop-blur-xl border-b border-blue-500/10 flex items-center justify-between px-6 h-16">
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-full bg-cyberBlue-900/60 border border-cyberBlue-500/25 flex items-center justify-center overflow-hidden">
            <span className="material-symbols-outlined text-cyberBlue-400 text-sm">lock</span>
          </div>
          <h1 className="text-xl font-bold shimmer-text select-none">Diaro</h1>
        </div>
        <div className="flex items-center gap-2">
          <button 
            onClick={() => setActiveScreen(activeScreen === 'audit_logs' ? 'dashboard' : 'audit_logs')}
            className="w-10 h-10 flex items-center justify-center rounded-full hover:bg-white/10 transition-colors active:scale-95 text-cyberBlue-400"
            title="Security Audit Logs"
          >
            <span className="material-symbols-outlined">
              {activeScreen === 'audit_logs' ? 'close' : 'shield'}
            </span>
          </button>
          <button 
            onClick={() => setActiveScreen(activeScreen === 'search' ? 'dashboard' : 'search')}
            className="w-10 h-10 flex items-center justify-center rounded-full hover:bg-white/10 transition-colors active:scale-95 text-cyberBlue-400"
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
          <Settings onLogout={handleLogout} />
        )}
        {activeScreen === 'audit_logs' && (
          <AuditLogs onCancel={() => setActiveScreen('dashboard')} />
        )}
      </div>

      {/* Bottom Nav Bar */}
      <nav className="fixed bottom-0 left-0 w-full z-50 flex justify-around items-center pt-2 pb-6 px-4 bg-[#0b1326]/90 backdrop-blur-xl border-t border-blue-500/10 shadow-lg">
        <button 
          onClick={() => setActiveScreen('dashboard')}
          className={`flex flex-col items-center justify-center rounded-full px-4 py-1 transition-all duration-200 active:scale-90
            ${activeScreen === 'dashboard' ? 'text-cyberBlue-400 font-semibold' : 'text-blue-300/40 hover:text-white'}
          `}
        >
          <span className="material-symbols-outlined" style={{ fontVariationSettings: activeScreen === 'dashboard' ? "'FILL' 1" : "'FILL' 0" }}>dashboard</span>
          <span className="text-[10px] font-mono mt-0.5">Vault</span>
        </button>
        
        <button 
          onClick={() => { setActiveNote(null); setActiveScreen('editor'); }}
          className={`flex flex-col items-center justify-center rounded-full px-4 py-1 transition-all duration-200 active:scale-90
            ${activeScreen === 'editor' ? 'text-cyberBlue-400 font-semibold' : 'text-blue-300/40 hover:text-white'}
          `}
        >
          <span className="material-symbols-outlined">add_circle</span>
          <span className="text-[10px] font-mono mt-0.5">Write</span>
        </button>

        <button 
          onClick={() => setActiveScreen('media')}
          className={`flex flex-col items-center justify-center rounded-full px-4 py-1 transition-all duration-200 active:scale-90
            ${activeScreen === 'media' ? 'text-cyberBlue-400 font-semibold' : 'text-blue-300/40 hover:text-white'}
          `}
        >
          <span className="material-symbols-outlined" style={{ fontVariationSettings: activeScreen === 'media' ? "'FILL' 1" : "'FILL' 0" }}>perm_media</span>
          <span className="text-[10px] font-mono mt-0.5">Media</span>
        </button>

        <button 
          onClick={() => setActiveScreen('analytics')}
          className={`flex flex-col items-center justify-center rounded-full px-4 py-1 transition-all duration-200 active:scale-90
            ${activeScreen === 'analytics' ? 'text-cyberBlue-400 font-semibold' : 'text-blue-300/40 hover:text-white'}
          `}
        >
          <span className="material-symbols-outlined">analytics</span>
          <span className="text-[10px] font-mono mt-0.5">Stats</span>
        </button>

        <button 
          onClick={() => setActiveScreen('settings')}
          className={`flex flex-col items-center justify-center rounded-full px-4 py-1 transition-all duration-200 active:scale-90
            ${activeScreen === 'settings' ? 'text-cyberBlue-400 font-semibold' : 'text-blue-300/40 hover:text-white'}
          `}
        >
          <span className="material-symbols-outlined">settings</span>
          <span className="text-[10px] font-mono mt-0.5">Config</span>
        </button>
      </nav>
    </div>
  );
}
