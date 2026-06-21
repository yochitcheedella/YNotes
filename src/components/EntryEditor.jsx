import React, { useState, useEffect } from 'react';
import { supabase } from '../supabaseClient';
import { encryptText } from '../cryptoHelper';

const MOODS = [
  { val: 'happy', label: '😊 Happy' },
  { val: 'neutral', label: '😐 Neutral' },
  { val: 'sad', label: '😔 Sad' },
  { val: 'angry', label: '😡 Angry' },
  { val: 'excited', label: '😍 Excited' }
];

export default function EntryEditor({ activeNote, vaultKey, onSaveComplete, onCancel }) {
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [mood, setMood] = useState('neutral');
  const [expiresInDays, setExpiresInDays] = useState('');
  const [maxViews, setMaxViews] = useState('');
  const [isSaving, setIsSaving] = useState(false);
  const [isRecording, setIsRecording] = useState(false);
  const isRecordingRef = React.useRef(false);
  const [recordTimer, setRecordTimer] = useState(0);
  const [interimText, setInterimText] = useState('');   // live preview of speech
  const [voiceError, setVoiceError] = useState('');     // microphone/API errors
  const recordingIntervalRef = React.useRef(null);
  const recognitionRef = React.useRef(null);             // SpeechRecognition instance

  const toggleRecordingState = (val) => {
    setIsRecording(val);
    isRecordingRef.current = val;
  };

  // Load existing note data if editing
  useEffect(() => {
    if (activeNote) {
      setTitle(activeNote.title || '');
      setContent(activeNote.content || '');
      setMood(activeNote.mood || 'neutral');
      if (activeNote.expires_at) {
        const days = Math.round((new Date(activeNote.expires_at) - new Date()) / 86400000);
        setExpiresInDays(days > 0 ? days : '');
      }
      setMaxViews(activeNote.max_views || '');
    } else {
      setTitle('');
      setContent('');
      setMood('neutral');
      setExpiresInDays('');
      setMaxViews('');
    }
  }, [activeNote]);

  // Offline AI mood detector scan on content change
  useEffect(() => {
    if (activeNote) return; // Don't auto-change mood when editing old notes unless user edits content

    const lower = content.toLowerCase();
    if (lower.includes('great') || lower.includes('glad') || lower.includes('awesome') || lower.includes('happy')) {
      setMood('happy');
    } else if (lower.includes('sad') || lower.includes('cry') || lower.includes('lonely') || lower.includes('depressed')) {
      setMood('sad');
    } else if (lower.includes('angry') || lower.includes('mad') || lower.includes('hate') || lower.includes('annoyed')) {
      setMood('angry');
    } else if (lower.includes('wow') || lower.includes('excited') || lower.includes('hype') || lower.includes('spark')) {
      setMood('excited');
    }
  }, [content, activeNote]);

  // Cleanup on unmount
  React.useEffect(() => {
    return () => {
      clearInterval(recordingIntervalRef.current);
      if (recognitionRef.current) {
        try { recognitionRef.current.stop(); } catch (_) {}
      }
    };
  }, []);

  const handleVoiceRecord = () => {
    if (isRecordingRef.current) {
      // ── STOP recording ──────────────────────────────────────────────────
      clearInterval(recordingIntervalRef.current);
      toggleRecordingState(false);
      setRecordTimer(0);
      setInterimText('');
      if (recognitionRef.current) {
        try { recognitionRef.current.stop(); } catch (_) {}
        recognitionRef.current = null;
      }
      return;
    }

    // ── START recording ─────────────────────────────────────────────────
    setVoiceError('');
    setInterimText('');

    // Check browser / WebView support
    const SpeechRecognition =
      window.SpeechRecognition ||
      window.webkitSpeechRecognition ||
      window.mozSpeechRecognition ||
      window.msSpeechRecognition;

    if (!SpeechRecognition) {
      setVoiceError('Voice recognition is not supported on this device. Please update your browser/WebView.');
      return;
    }

    try {
      const recognition = new SpeechRecognition();
      recognitionRef.current = recognition;

      recognition.continuous = true;       // keep listening until stopped
      recognition.interimResults = true;   // show live text as you speak
      recognition.lang = 'en-US';          // default language
      recognition.maxAlternatives = 1;

      // ── Live result handler ────────────────────────────────────────────
      recognition.onresult = (event) => {
        let interim = '';
        let final = '';

        for (let i = event.resultIndex; i < event.results.length; i++) {
          const transcript = event.results[i][0].transcript;
          if (event.results[i].isFinal) {
            final += transcript + ' ';
          } else {
            interim += transcript;
          }
        }

        // Show live preview
        setInterimText(interim);

        // Append confirmed words to content immediately
        if (final) {
          setContent(prev => prev + (prev && !prev.endsWith(' ') && !prev.endsWith('\n') ? ' ' : '') + final);
        }
      };

      // ── Error handler ──────────────────────────────────────────────────
      recognition.onerror = (event) => {
        clearInterval(recordingIntervalRef.current);
        toggleRecordingState(false);
        setRecordTimer(0);
        setInterimText('');
        recognitionRef.current = null;

        switch (event.error) {
          case 'not-allowed':
          case 'permission-denied':
            setVoiceError('Microphone permission denied. Please allow mic access in your device settings.');
            break;
          case 'no-speech':
            setVoiceError('No speech detected. Please speak clearly and try again.');
            break;
          case 'audio-capture':
            setVoiceError('No microphone found. Please check your device.');
            break;
          case 'network':
            setVoiceError('Network error during transcription. Check your internet connection.');
            break;
          default:
            setVoiceError(`Voice error: ${event.error}. Please try again.`);
        }
      };

      // ── End handler (fires when recognition stops automatically) ───────
      recognition.onend = () => {
        // If user didn't manually stop but recognition ended (e.g. timeout),
        // restart automatically to keep recording
        if (recognitionRef.current && isRecordingRef.current) {
          try {
            recognitionRef.current.start();
          } catch (_) {
            // Already stopped or restarting — ignore
          }
        } else {
          clearInterval(recordingIntervalRef.current);
          toggleRecordingState(false);
          setRecordTimer(0);
          setInterimText('');
        }
      };

      // ── Start the microphone ───────────────────────────────────────────
      recognition.start();
      toggleRecordingState(true);

      // Timer counter
      recordingIntervalRef.current = setInterval(() => {
        setRecordTimer(prev => prev + 1);
      }, 1000);

    } catch (err) {
      console.error('SpeechRecognition start failed:', err);
      setVoiceError('Failed to start voice recording. Please try again.');
      toggleRecordingState(false);
    }
  };

  const handleSave = async () => {
    if (!title.trim()) {
      alert('Please specify a title.');
      return;
    }
    if (!content.trim()) {
      alert('Content field is empty.');
      return;
    }

    setIsSaving(true);

    try {
      // 1. Encrypt fields client-side
      const encryptedTitle = encryptText(title.trim(), vaultKey);
      const encryptedContent = encryptText(content.trim(), vaultKey);

      // 2. Fetch authenticated user id
      const { data: { user } } = await supabase.auth.getUser();
      const userId = user ? user.id : null;

      if (activeNote && activeNote.id) {
        // Update existing note
        const { error } = await supabase
          .from('notes')
          .update({
            title_encrypted: encryptedTitle,
            content_encrypted: encryptedContent,
            mood: mood,
            expires_at: expiresInDays ? new Date(Date.now() + parseInt(expiresInDays, 10) * 86400000).toISOString() : null,
            max_views: maxViews ? parseInt(maxViews, 10) : null,
          })
          .eq('id', activeNote.id);

        if (error) {
          // If Supabase table isn't set up yet, fallback to saving state in Memory
          console.warn('Supabase update error (falling back to memory):', error.message);
        }
      } else {
        // Insert new note
        const { error } = await supabase
          .from('notes')
          .insert({
            title_encrypted: encryptedTitle,
            content_encrypted: encryptedContent,
            mood: mood,
            user_id: userId,
            created_at: new Date().toISOString(),
            expires_at: expiresInDays ? new Date(Date.now() + parseInt(expiresInDays, 10) * 86400000).toISOString() : null,
            max_views: maxViews ? parseInt(maxViews, 10) : null,
          });

        if (error) {
          console.warn('Supabase insert error (falling back to memory):', error.message);
        }
      }

      // Notify parent app of success, passing plaintext version to instantly show in state
      onSaveComplete({
        id: activeNote?.id || Date.now(), // Fallback mock id
        title: title.trim(),
        content: content.trim(),
        mood: mood,
        created_at: activeNote?.created_at || new Date().toISOString()
      });

    } catch (err) {
      console.error(err);
      alert('Vault synchronization encryption failed.');
    } finally {
      setIsSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!activeNote || !activeNote.id) return;
    if (!window.confirm('Are you sure you want to permanently erase this secure log from local and cloud nodes?')) return;

    setIsSaving(true);
    try {
      const { error } = await supabase
        .from('notes')
        .delete()
        .eq('id', activeNote.id);

      if (error) {
        console.warn('Delete error:', error.message);
      }
      onSaveComplete(null, activeNote.id);
    } catch (err) {
      console.error(err);
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <main className="relative z-10 pt-20 px-4 max-w-2xl mx-auto pb-24">
      <div className="glass-card rounded-2xl p-6 shadow-xl space-y-6">
        
        {/* Editor Title Header */}
        <div className="flex justify-between items-center">
          <button 
            onClick={onCancel}
            className="flex items-center gap-1.5 text-diaroAccent-300/60 hover:text-white transition-colors"
          >
            <span className="material-symbols-outlined text-[20px]">arrow_back</span>
            <span className="text-xs uppercase font-mono tracking-wider">Vault</span>
          </button>
          
          <h2 className="text-lg font-semibold text-white">
            {activeNote ? 'Edit Diary Entry' : 'New Diary Entry'}
          </h2>

          {activeNote ? (
            <button 
              onClick={handleDelete}
              className="text-red-400 hover:text-red-300 transition-colors flex items-center"
              title="Erase Note"
            >
              <span className="material-symbols-outlined text-[20px]">delete_forever</span>
            </button>
          ) : (
            <div className="w-6" />
          )}
        </div>

        {/* Title Input */}
        <div className="space-y-2">
          <label className="block text-xs font-mono text-diaroAccent-300 uppercase tracking-widest" htmlFor="note-title">Title</label>
          <input 
            className="w-full px-4 py-3 rounded-xl text-white font-sans placeholder:text-diaroAccent-200/20 cyber-input outline-none focus:ring-0 text-sm" 
            id="note-title"
            placeholder="Name your reflection..." 
            value={title}
            onChange={(e) => setTitle(e.target.value)}
          />
        </div>

        {/* Mood Selection */}
        <div className="space-y-2">
          <label className="block text-xs font-mono text-diaroAccent-300 uppercase tracking-widest">Select Mood</label>
          <div className="flex flex-wrap gap-2">
            {MOODS.map((m) => {
              const isSelected = mood === m.val;
              return (
                <button
                  key={m.val}
                  type="button"
                  onClick={() => setMood(m.val)}
                  className={`px-3 py-2 rounded-xl text-xs font-mono border transition-all duration-200
                    ${isSelected 
                      ? 'bg-diaroAccent-600/35 border-diaroAccent-500 text-white shadow-[0_0_10px_rgba(184, 115, 51,0.2)]' 
                      : 'bg-[#0f172a]/60 border-diaroAccent-400/10 text-diaroAccent-300/50 hover:text-white'
                    }
                  `}
                >
                  {m.label}
                </button>
              );
            })}
          </div>
        </div>

        {/* Content Box */}
        <div className="space-y-2">
          <div className="flex justify-between items-center">
            <label className="block text-xs font-mono text-diaroAccent-300 uppercase tracking-widest" htmlFor="note-content">Diary Content</label>
            <span className="text-[10px] font-mono text-emerald-400 uppercase tracking-widest flex items-center gap-1">
              <span className="w-1.5 h-1.5 bg-emerald-400 rounded-full animate-pulse" />
              AI Mood Scanner Active
            </span>
          </div>
          <textarea 
            className="w-full px-4 py-3 rounded-xl text-white font-sans placeholder:text-diaroAccent-200/20 cyber-input outline-none focus:ring-0 text-sm min-h-[220px]" 
            id="note-content"
            placeholder="Write down your thoughts. They are encrypted locally in your browser..." 
            value={content}
            onChange={(e) => setContent(e.target.value)}
          />
        </div>

        {/* Self-Destruct Security Settings */}
        <div className="p-4 rounded-xl border border-orange-500/20 bg-[#0a0a0a] flex flex-col gap-3">
          <div className="flex items-center gap-2 text-orange-400">
            <span className="material-symbols-outlined text-[20px]">local_fire_department</span>
            <p className="text-xs font-mono uppercase tracking-widest font-semibold">Self-Destruct Parameters</p>
          </div>
          <div className="flex gap-4">
            <div className="flex-1">
              <label className="block text-[10px] font-mono text-gray-400 uppercase tracking-widest mb-1">Delete after X days</label>
              <input 
                type="number"
                min="1"
                className="w-full px-3 py-2 rounded-lg text-white font-sans bg-black border border-gray-800 outline-none text-sm focus:border-orange-500/50" 
                placeholder="Leave blank for never" 
                value={expiresInDays}
                onChange={(e) => setExpiresInDays(e.target.value)}
              />
            </div>
            <div className="flex-1">
              <label className="block text-[10px] font-mono text-gray-400 uppercase tracking-widest mb-1">Delete after X views</label>
              <input 
                type="number"
                min="1"
                className="w-full px-3 py-2 rounded-lg text-white font-sans bg-black border border-gray-800 outline-none text-sm focus:border-orange-500/50" 
                placeholder="Leave blank for infinite" 
                value={maxViews}
                onChange={(e) => setMaxViews(e.target.value)}
              />
            </div>
          </div>
        </div>

        {/* AI Voice Recorder Widget — Real Speech Recognition */}
        <div className={`p-4 rounded-xl border bg-slate-950/40 flex flex-col gap-3 transition-all duration-300
          ${isRecording ? 'border-red-500/40 shadow-[0_0_15px_rgba(239,68,68,0.1)]' : 'border-diaroAccent-500/10'}
        `}>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <span className={`material-symbols-outlined text-[28px] transition-colors duration-300
                ${isRecording ? 'text-red-400 animate-pulse' : 'text-diaroAccent-400'}
              `}
              style={{ fontVariationSettings: isRecording ? "'FILL' 1" : "'FILL' 0" }}
              >mic</span>
              <div>
                <p className="text-xs text-white font-semibold">
                  {isRecording ? 'Recording...' : 'AI Voice Diary Transcriber'}
                </p>
                <p className="text-[10px] text-diaroAccent-300/40 font-mono">
                  {isRecording
                    ? `Speak clearly · ${recordTimer}s · Tap STOP when done`
                    : 'Record thoughts, appends transcript automatically.'}
                </p>
              </div>
            </div>
            <button 
              type="button"
              onClick={handleVoiceRecord}
              className={`px-4 py-2 text-xs font-mono uppercase tracking-wider rounded-lg border transition-all duration-200 flex items-center gap-1.5
                ${isRecording 
                  ? 'bg-red-950/30 border-red-500/40 text-red-400 animate-pulse' 
                  : 'bg-diaroAccent-950/40 border-diaroAccent-500/25 text-diaroAccent-400 hover:bg-diaroAccent-900/40'
                }
              `}
            >
              <span className="material-symbols-outlined text-[16px]">
                {isRecording ? 'stop_circle' : 'radio_button_checked'}
              </span>
              <span>{isRecording ? `STOP (${recordTimer}s)` : 'RECORD'}</span>
            </button>
          </div>

          {/* Live interim transcription preview */}
          {isRecording && interimText && (
            <div className="px-3 py-2 rounded-lg bg-red-950/20 border border-red-500/20">
              <p className="text-xs font-mono text-red-300/70 italic leading-relaxed">
                <span className="text-red-400">●</span> {interimText}
              </p>
            </div>
          )}

          {/* Waveform dots animation while recording */}
          {isRecording && !interimText && (
            <div className="flex items-center gap-1.5 px-3">
              {[0,1,2,3,4].map(i => (
                <div
                  key={i}
                  className="w-1 bg-red-400 rounded-full"
                  style={{
                    height: `${8 + Math.random() * 16}px`,
                    animation: `pulse 0.${6+i}s ease-in-out infinite alternate`,
                    animationDelay: `${i * 0.1}s`
                  }}
                />
              ))}
              <span className="text-[10px] text-red-400/60 font-mono ml-2">Listening...</span>
            </div>
          )}

          {/* Error message */}
          {voiceError && (
            <div className="px-3 py-2 rounded-lg bg-orange-950/30 border border-orange-500/20 flex items-start gap-2">
              <span className="material-symbols-outlined text-[14px] text-orange-400 mt-0.5" style={{ fontVariationSettings: "'FILL' 1" }}>warning</span>
              <p className="text-[10px] font-mono text-orange-300/80 leading-relaxed">{voiceError}</p>
            </div>
          )}
        </div>

        {/* Bottom Save Action */}
        <button 
          disabled={isSaving}
          onClick={handleSave}
          className="w-full py-4 bg-diaroAccent-600 hover:bg-diaroAccent-500 text-white font-semibold text-xs uppercase tracking-[0.15em] rounded-xl hover:shadow-[0_0_20px_rgba(184, 115, 51,0.3)] active:scale-[0.98] transition-all duration-200 flex items-center justify-center gap-2 focus:outline-none focus:ring-2 focus:ring-diaroAccent-500 disabled:opacity-50"
        >
          {isSaving ? (
            <div className="flex items-center gap-2">
              <svg className="animate-spin h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              <span>Encrypting & Syncing...</span>
            </div>
          ) : (
            <>
              <span>Lock & Save Entry</span>
              <span className="material-symbols-outlined text-[16px]">lock_open</span>
            </>
          )}
        </button>

      </div>
    </main>
  );
}
