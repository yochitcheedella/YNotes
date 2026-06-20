import React, { useState } from 'react';

export default function SearchMemories({ notes, onSelectNote }) {
  const [query, setQuery] = useState('');
  const [selectedMood, setSelectedMood] = useState('all');
  const [selectedMedia, setSelectedMedia] = useState('all');

  const handleClear = () => {
    setQuery('');
    setSelectedMood('all');
    setSelectedMedia('all');
  };

  const filteredNotes = notes.filter((note) => {
    // 1. Text Search matching title or content
    const matchText = 
      note.title?.toLowerCase().includes(query.toLowerCase()) || 
      note.content?.toLowerCase().includes(query.toLowerCase());

    // 2. Mood filter match
    const matchMood = selectedMood === 'all' || note.mood?.toLowerCase() === selectedMood.toLowerCase();

    // 3. Media filter match (mock filter)
    let matchMedia = true;
    if (selectedMedia === 'voice') {
      matchMedia = note.content?.includes('[Transcribed') || note.content?.includes('[Voice');
    } else if (selectedMedia === 'images') {
      matchMedia = note.content?.includes('[Attached') || note.title?.toLowerCase().includes('spark') || note.title?.toLowerCase().includes('blueprints');
    }

    return matchText && matchMood && matchMedia;
  });

  return (
    <main className="relative z-10 pt-20 px-4 max-w-4xl mx-auto pb-24">
      <div className="glass-card rounded-2xl p-6 shadow-xl space-y-6">
        
        {/* Search Header */}
        <div>
          <h2 className="text-xl font-semibold text-white tracking-wide">Search Memories</h2>
          <p className="text-xs text-blue-300/40 mt-1">Locate entries using plaintext queries. Encryption keys remain in sandbox.</p>
        </div>

        {/* Input Bar */}
        <div className="relative flex items-center">
          <span className="material-symbols-outlined absolute left-4 text-[22px] text-blue-400/50">search</span>
          <input 
            className="w-full pl-12 pr-12 py-3.5 rounded-xl text-white font-sans placeholder:text-blue-200/20 cyber-input outline-none focus:ring-0 text-sm" 
            placeholder="Type search terms (e.g. 'Morning', 'reflection')..." 
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
          {query && (
            <button 
              onClick={handleClear}
              className="absolute right-4 text-blue-300/40 hover:text-white transition-colors"
            >
              <span className="material-symbols-outlined text-[20px]">close</span>
            </button>
          )}
        </div>

        {/* Filter Section */}
        <div className="space-y-4 pt-2 border-t border-slate-800/40">
          {/* Mood Selector Chips */}
          <div className="space-y-1.5">
            <span className="text-[10px] font-mono text-cyberBlue-300 uppercase tracking-widest block">Mood Filters</span>
            <div className="flex flex-wrap gap-2">
              {['all', 'happy', 'neutral', 'sad', 'angry', 'excited'].map(m => (
                <button
                  key={m}
                  onClick={() => setSelectedMood(m)}
                  className={`px-3 py-1.5 rounded-lg text-xs font-mono border transition-all capitalize
                    ${selectedMood === m 
                      ? 'bg-cyberBlue-600/35 border-cyberBlue-500 text-white' 
                      : 'bg-[#0f172a]/60 border-blue-400/10 text-blue-300/50 hover:text-white'
                    }
                  `}
                >
                  {m}
                </button>
              ))}
            </div>
          </div>

          {/* Media Filter Chips */}
          <div className="space-y-1.5">
            <span className="text-[10px] font-mono text-cyberBlue-300 uppercase tracking-widest block">Media Category</span>
            <div className="flex flex-wrap gap-2">
              {['all', 'text', 'voice', 'images'].map(cat => (
                <button
                  key={cat}
                  onClick={() => setSelectedMedia(cat)}
                  className={`px-3 py-1.5 rounded-lg text-xs font-mono border transition-all capitalize
                    ${selectedMedia === cat 
                      ? 'bg-cyberBlue-600/35 border-cyberBlue-500 text-white' 
                      : 'bg-[#0f172a]/60 border-blue-400/10 text-blue-300/50 hover:text-white'
                    }
                  `}
                >
                  {cat}
                </button>
              ))}
            </div>
          </div>
        </div>

      </div>

      {/* Results Feed */}
      <section className="mt-8 space-y-4">
        <h3 className="text-sm font-semibold text-white/80">
          Query Results ({filteredNotes.length})
        </h3>
        
        {filteredNotes.length > 0 ? (
          filteredNotes.map((note) => (
            <div 
              key={note.id}
              onClick={() => onSelectNote(note)}
              className="glass-card rounded-xl p-5 hover:border-cyberBlue-500/30 transition-all cursor-pointer group animate-fade-in"
            >
              <div className="flex justify-between items-start mb-2">
                <h4 className="text-md font-semibold text-white group-hover:text-cyberBlue-400 transition-colors">
                  {note.title}
                </h4>
                <span className="text-xs text-blue-300/40 font-mono">
                  {new Date(note.created_at).toLocaleDateString([], { month: 'short', day: 'numeric', year: 'numeric' })}
                </span>
              </div>
              <p className="text-sm text-blue-100/60 line-clamp-2 mb-3">
                {note.content}
              </p>
              <div className="flex gap-2">
                <span className="px-2.5 py-0.5 text-xs rounded-full bg-slate-950/60 text-cyberBlue-300 capitalize">
                  {note.mood || 'Calm'}
                </span>
              </div>
            </div>
          ))
        ) : (
          <div className="text-center py-16 text-blue-300/20 font-mono text-sm">
            ❌ No matching memories found in secure storage.
          </div>
        )}
      </section>
    </main>
  );
}
