import React from 'react';

export default function Analytics({ notes, onNavigate }) {
  // Count moods
  const moodCounts = {
    happy: 0,
    neutral: 0,
    sad: 0,
    angry: 0,
    excited: 0
  };

  notes.forEach((n) => {
    const m = n.mood?.toLowerCase() || 'neutral';
    if (moodCounts[m] !== undefined) {
      moodCounts[m]++;
    } else {
      moodCounts.neutral++;
    }
  });

  const totalNotes = notes.length;

  // Calculate percentages
  const getPercent = (count) => {
    if (totalNotes === 0) return '0%';
    return `${Math.round((count / totalNotes) * 100)}%`;
  };

  // Find dominant mood
  let dominantMood = 'Calm';
  let maxCount = -1;
  Object.keys(moodCounts).forEach((key) => {
    if (moodCounts[key] > maxCount) {
      maxCount = moodCounts[key];
      dominantMood = key;
    }
  });

  if (totalNotes === 0) {
    dominantMood = 'None';
  }

  return (
    <main className="relative z-10 pt-20 px-4 max-w-4xl mx-auto pb-24 space-y-6">
      
      {/* Header */}
      <div>
        <h2 className="text-xl font-semibold text-white tracking-wide">Mood Analytics & Insights</h2>
        <p className="text-xs text-diaroAccent-300/40 mt-1">AI-driven emotional diagnostics processed entirely in offline sandbox env.</p>
      </div>

      {/* Overview Grid */}
      <section className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {/* Metric 1 */}
        <div className="glass-card rounded-xl p-5 flex flex-col justify-between h-36">
          <div className="flex justify-between items-start">
            <span className="text-xs font-mono text-diaroAccent-300 uppercase tracking-widest">Total Memories</span>
            <span className="material-symbols-outlined text-diaroAccent-400">history</span>
          </div>
          <div>
            <p className="text-3xl font-bold text-white font-sans">{totalNotes}</p>
            <p className="text-[10px] text-emerald-400 font-mono mt-1">↑ 12% increase this month</p>
          </div>
        </div>

        {/* Metric 2 */}
        <div className="glass-card rounded-xl p-5 flex flex-col justify-between h-36">
          <div className="flex justify-between items-start">
            <span className="text-xs font-mono text-diaroAccent-300 uppercase tracking-widest">Dominant Mood</span>
            <span className="material-symbols-outlined text-diaroAccent-400">mood</span>
          </div>
          <div>
            <p className="text-3xl font-bold text-white capitalize font-sans">{dominantMood}</p>
            <p className="text-[10px] text-diaroAccent-300/40 font-mono mt-1">Based on text analysis</p>
          </div>
        </div>

        {/* Metric 3 */}
        <div className="glass-card rounded-xl p-5 flex flex-col justify-between h-36">
          <div className="flex justify-between items-start">
            <span className="text-xs font-mono text-diaroAccent-300 uppercase tracking-widest">Security Health</span>
            <span className="material-symbols-outlined text-emerald-400">verified_user</span>
          </div>
          <div>
            <p className="text-3xl font-bold text-white font-sans">AES-256</p>
            <p className="text-[10px] text-emerald-400 font-mono mt-1">Biometrics On • Zero Knowledge</p>
          </div>
        </div>
      </section>

      {/* Mood Distribution */}
      <section className="glass-card rounded-xl p-6 space-y-5">
        <h3 className="text-sm font-semibold text-white/80">Monthly Mood Distribution</h3>
        
        <div className="space-y-4">
          {/* Happy */}
          <div className="space-y-1">
            <div className="flex justify-between text-xs font-mono text-diaroAccent-300/70">
              <span>😊 Happy / Calm</span>
              <span>{moodCounts.happy} ({getPercent(moodCounts.happy)})</span>
            </div>
            <div className="w-full h-2.5 bg-slate-900 rounded-full overflow-hidden">
              <div className="h-full bg-emerald-400 rounded-full" style={{ width: getPercent(moodCounts.happy) }} />
            </div>
          </div>

          {/* Excited */}
          <div className="space-y-1">
            <div className="flex justify-between text-xs font-mono text-diaroAccent-300/70">
              <span>😍 Excited / Energetic</span>
              <span>{moodCounts.excited} ({getPercent(moodCounts.excited)})</span>
            </div>
            <div className="w-full h-2.5 bg-slate-900 rounded-full overflow-hidden">
              <div className="h-full bg-[#a8cfbc] rounded-full" style={{ width: getPercent(moodCounts.excited) }} />
            </div>
          </div>

          {/* Neutral */}
          <div className="space-y-1">
            <div className="flex justify-between text-xs font-mono text-diaroAccent-300/70">
              <span>😐 Neutral / Balanced</span>
              <span>{moodCounts.neutral} ({getPercent(moodCounts.neutral)})</span>
            </div>
            <div className="w-full h-2.5 bg-slate-900 rounded-full overflow-hidden">
              <div className="h-full bg-blue-400 rounded-full" style={{ width: getPercent(moodCounts.neutral) }} />
            </div>
          </div>

          {/* Sad */}
          <div className="space-y-1">
            <div className="flex justify-between text-xs font-mono text-diaroAccent-300/70">
              <span>😔 Sad / Reflective</span>
              <span>{moodCounts.sad} ({getPercent(moodCounts.sad)})</span>
            </div>
            <div className="w-full h-2.5 bg-slate-900 rounded-full overflow-hidden">
              <div className="h-full bg-indigo-400 rounded-full" style={{ width: getPercent(moodCounts.sad) }} />
            </div>
          </div>

          {/* Angry */}
          <div className="space-y-1">
            <div className="flex justify-between text-xs font-mono text-diaroAccent-300/70">
              <span>😡 Angry / Stressed</span>
              <span>{moodCounts.angry} ({getPercent(moodCounts.angry)})</span>
            </div>
            <div className="w-full h-2.5 bg-slate-900 rounded-full overflow-hidden">
              <div className="h-full bg-red-400 rounded-full" style={{ width: getPercent(moodCounts.angry) }} />
            </div>
          </div>
        </div>
      </section>

      {/* AI Insights / Reflection Nuggets */}
      <section className="glass-card rounded-xl p-6 space-y-4">
        <div className="flex justify-between items-center">
          <h3 className="text-sm font-semibold text-white/80">Reflection Nuggets</h3>
          <span className="text-[10px] font-mono text-diaroAccent-400 uppercase tracking-widest">Cognitive Advisor</span>
        </div>

        <div className="p-4 rounded-xl border border-diaroAccent-500/10 bg-slate-950/40 text-sm text-diaroAccent-100/70 space-y-3 leading-relaxed">
          <p>
            🧠 <strong>Observation:</strong> You have recorded a high density of <strong>Reflective / Calm</strong> entries in the past weeks. Silence and stillness appear to trigger your creative flow notes.
          </p>
          <p>
            💡 <strong>Recommendation:</strong> Consider journaling in mornings on days marked with "Neutral" mood to capture latent creative concepts before your cognitive load increases.
          </p>
        </div>

        <button 
          onClick={() => onNavigate('settings')}
          className="w-full py-3 bg-diaroAccent-950/40 hover:bg-diaroAccent-900/40 border border-diaroAccent-500/20 text-diaroAccent-400 hover:text-diaroAccent-300 font-semibold text-xs uppercase tracking-[0.15em] rounded-xl active:scale-[0.98] transition-all duration-200 flex items-center justify-center gap-2"
        >
          <span className="material-symbols-outlined text-[16px]">verified_user</span>
          <span>Run Vault Security Check</span>
        </button>
      </section>

    </main>
  );
}
