import React, { useState } from 'react';

export default function Dashboard({ notes, onNavigate, onSelectNote, onNewNote }) {
  const [selectedDate, setSelectedDate] = useState(new Date());

  // Generate calendar days for October 2024 (matching mockups defaults)
  const currentYear = 2024;
  const currentMonth = 9; // October (0-indexed)
  
  const getDaysInMonth = (year, month) => {
    return new Date(year, month + 1, 0).getDate();
  };

  const getFirstDayOfMonth = (year, month) => {
    return new Date(year, month, 1).getDay();
  };

  const daysCount = getDaysInMonth(currentYear, currentMonth);
  const firstDayIndex = getFirstDayOfMonth(currentYear, currentMonth);

  const daysArray = [];
  // Fill previous month padding
  for (let i = 29; i < 29 + firstDayIndex; i++) {
    daysArray.push({ dayNum: i, currentMonth: false });
  }
  // Fill October days
  for (let i = 1; i <= daysCount; i++) {
    daysArray.push({ dayNum: i, currentMonth: true });
  }

  // Helper to map mood string to color
  const getMoodColor = (mood) => {
    switch (mood?.toLowerCase()) {
      case 'happy': case 'calm': case 'excited': return 'bg-[#a8cfbc]'; // Tertiary/Green
      case 'sad': case 'deep': return 'bg-[#c3c0ff]'; // Primary/Blue
      case 'angry': return 'bg-red-400';
      default: return 'bg-gray-400';
    }
  };

  const hasNoteOnDay = (dayNum) => {
    return notes.some(note => {
      const noteDate = new Date(note.created_at);
      return noteDate.getDate() === dayNum && noteDate.getMonth() === currentMonth && noteDate.getFullYear() === currentYear;
    });
  };

  const getDayNoteMood = (dayNum) => {
    const dayNotes = notes.filter(note => {
      const noteDate = new Date(note.created_at);
      return noteDate.getDate() === dayNum && noteDate.getMonth() === currentMonth && noteDate.getFullYear() === currentYear;
    });
    return dayNotes[0]?.mood || 'calm';
  };

  const filteredNotes = notes.filter(note => {
    const noteDate = new Date(note.created_at);
    return noteDate.getDate() === selectedDate.getDate() && 
           noteDate.getMonth() === selectedDate.getMonth() && 
           noteDate.getFullYear() === selectedDate.getFullYear();
  });

  return (
    <main className="relative z-10 pt-20 px-4 max-w-4xl mx-auto pb-24">
      {/* Calendar Section */}
      <section className="mb-8">
        <div className="glass-card rounded-xl p-6 shadow-lg">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-xl font-semibold text-white">October 2024</h2>
            <div className="flex gap-2">
              <button className="p-2 rounded-full hover:bg-white/10 transition-colors">
                <span className="material-symbols-outlined text-white">chevron_left</span>
              </button>
              <button className="p-2 rounded-full hover:bg-white/10 transition-colors">
                <span className="material-symbols-outlined text-white">chevron_right</span>
              </button>
            </div>
          </div>
          <div className="grid grid-cols-7 text-center mb-2 text-xs font-mono text-purple-300/40 uppercase tracking-widest">
            <div>Su</div><div>Mo</div><div>Tu</div><div>We</div><div>Th</div><div>Fr</div><div>Sa</div>
          </div>
          <div className="grid grid-cols-7 gap-y-2 text-sm">
            {daysArray.map((item, index) => {
              const isSelected = item.currentMonth && selectedDate.getDate() === item.dayNum;
              const hasNote = item.currentMonth && hasNoteOnDay(item.dayNum);
              
              return (
                <div 
                  key={index} 
                  onClick={() => {
                    if (item.currentMonth) {
                      setSelectedDate(new Date(currentYear, currentMonth, item.dayNum));
                    }
                  }}
                  className={`p-2 flex flex-col items-center justify-center rounded-lg cursor-pointer transition-all duration-150
                    ${!item.currentMonth ? 'text-purple-100/10 cursor-default' : 'text-purple-100 hover:bg-white/10'}
                    ${isSelected ? 'bg-ynoteAccent-600/30 text-ynoteAccent-400 border border-ynoteAccent-500/40' : ''}
                  `}
                >
                  <span>{item.dayNum}</span>
                  {hasNote && (
                    <div className={`w-1 h-1 rounded-full mt-1 ${getMoodColor(getDayNoteMood(item.dayNum))}`} />
                  )}
                </div>
              );
            })}
          </div>
        </div>
      </section>

      {/* Entries List Section */}
      <section className="space-y-6 relative pl-8 border-l border-slate-800/60">
        <div className="flex items-center justify-between pl-4">
          <h3 className="text-lg font-semibold text-white">Selected Day Memories</h3>
          <span className="text-xs font-mono text-purple-300/60">
            {selectedDate.toLocaleDateString('en-US', { weekday: 'long', month: 'short', day: 'numeric' })}
          </span>
        </div>

        {filteredNotes.length > 0 ? (
          filteredNotes.map((note) => (
            <div key={note.id} className="relative flex gap-4 animate-fade-in">
              <div className="absolute -left-12 w-8 h-8 rounded-full bg-slate-900 border-2 border-ynoteAccent-500 flex items-center justify-center shrink-0 mt-1 z-10 text-sm">
                {note.mood === 'happy' ? '😊' : note.mood === 'sad' ? '😔' : '🌿'}
              </div>
              <div 
                className="glass-card flex-1 rounded-xl p-5 hover:border-ynoteAccent-500/30 transition-all cursor-pointer group"
                onClick={() => onSelectNote(note)}
              >
                <div className="flex justify-between items-start mb-2">
                  <h4 className="text-md font-semibold text-white group-hover:text-ynoteAccent-400 transition-colors">
                    {note.title}
                  </h4>
                  <span className="text-xs text-purple-300/40 font-mono">
                    {new Date(note.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                  </span>
                </div>
                <p className="text-sm text-purple-100/60 line-clamp-2 mb-4">
                  {note.content}
                </p>
                <div className="flex gap-2">
                  <span className={`px-2.5 py-0.5 text-xs rounded-full bg-slate-950/60 text-ynoteAccent-300 capitalize`}>
                    {note.mood || 'Calm'}
                  </span>
                </div>
              </div>
            </div>
          ))
        ) : (
          <div className="text-center py-12 text-purple-300/30 font-mono text-sm">
            🔒 No records found for this date. Click the button below to add one.
          </div>
        )}
      </section>

      {/* Floating Action Button */}
      <button 
        onClick={onNewNote}
        className="fixed bottom-24 right-6 w-16 h-16 bg-ynoteAccent-600 text-white rounded-full shadow-2xl flex items-center justify-center hover:scale-110 active:scale-95 transition-all z-50 group hover:shadow-[0_0_20px_rgba(59,130,246,0.5)]"
      >
        <span className="material-symbols-outlined text-3xl" style={{ fontVariationSettings: "'FILL' 1" }}>add</span>
      </button>
    </main>
  );
}
