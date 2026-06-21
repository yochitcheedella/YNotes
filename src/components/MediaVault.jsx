import React, { useState } from 'react';

const IMAGES = [
  { id: 1, name: 'Desk blueprint.jpg', size: '2.4 MB', date: 'Oct 11, 2024', url: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDXi4kKX7WJwtOxz5jl6gf8jXCV3SJBgOQdIvxP8-UjKeGiuCCzMqtfCM3zE4W5HVLrXWV7vrGNwUKLz49jgO4gumtE1VG1qcLUSyqLDJT2Sbc3qIRGLa9hme-9y6EXNoqS-TF5z0VoPNxwQPvYBTZPpz_BmxO5Oj5WxiakSre0CwYS1fO40Rd3KilH0jM1iokVJzcQ3PySxfwebtEylx1EVHqHxtd7JM48Iz_ranXXVwgrq5cgQIPIOeLr8uQOwGnPRGWB2W58wbI' },
  { id: 2, name: 'Profile cover.png', size: '1.8 MB', date: 'Oct 04, 2024', url: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBD57aUAcsTFq9z-M2IBGkYnR1Xeqa-MQ4KxIYiFidTFtma92lU2og3cMwcu8ihoYQwUpqVDSWNgmhtiRCcw-6_tIAu4OGC8qQW2dm6gVHht7dmQdJMk82YLSAjUyUAwpNZwhze-kI_6PMdQhP1MXtKRkVeRagltSp39U02OfWekA3Z05MKCorc3SUoDma9zBMpL0Y9a6pf1x7Dj9YH5x5pkZdR-WSSKvQIkYogeaxwwytSfPwqU7PPH0o_S7cvMWNwM0h-PWfYRB0' }
];

const VOICE_NOTES = [
  { id: 1, name: 'Late Night thoughts.mp3', duration: '2:15', date: 'Oct 11, 2024', size: '1.2 MB' },
  { id: 2, name: 'Nature Walk reflections.mp3', duration: '4:45', date: 'Oct 02, 2024', size: '2.6 MB' }
];

const DOCUMENTS = [
  { id: 1, name: 'Financial plan 2024.pdf.aes', date: 'Sep 28, 2024', size: '420 KB' }
];

export default function MediaVault() {
  const [activeTab, setActiveTab] = useState('images');

  const handleFileUpload = (e) => {
    e.preventDefault();
    alert('File selected! Encrypting using local derived key... Uploaded securely to Supabase Storage.');
  };

  return (
    <main className="relative z-10 pt-20 px-4 max-w-4xl mx-auto pb-24 space-y-6">
      
      {/* Header */}
      <div className="flex justify-between items-start">
        <div>
          <h2 className="text-xl font-semibold text-white tracking-wide">Encrypted Media Vault</h2>
          <p className="text-xs text-diaroAccent-300/40 mt-1">Symmetrically encrypted attachment binaries stored securely on cloud nodes.</p>
        </div>
        <span className="px-3 py-1 bg-diaroAccent-950/50 border border-diaroAccent-500/20 text-diaroAccent-400 font-mono text-[10px] uppercase tracking-widest rounded-lg flex items-center gap-1.5 shadow-[0_0_15px_rgba(184, 115, 51,0.1)]">
          <span className="material-symbols-outlined text-[12px] font-bold">encrypted</span>
          AES-256 SECURE
        </span>
      </div>

      {/* Tabs */}
      <div className="flex border-b border-slate-800/60">
        {['images', 'voice', 'documents'].map(tab => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={`px-6 py-3.5 text-xs font-mono uppercase tracking-wider border-b-2 transition-all capitalize
              ${activeTab === tab 
                ? 'border-diaroAccent-500 text-diaroAccent-400' 
                : 'border-transparent text-diaroAccent-300/40 hover:text-white'
              }
            `}
          >
            {tab}
          </button>
        ))}
      </div>

      {/* Drag & Drop Zone */}
      <div 
        onDragOver={(e) => e.preventDefault()}
        onDrop={(e) => { e.preventDefault(); alert('Files dropped! Encrypting...'); }}
        className="border-2 border-dashed border-diaroAccent-500/20 bg-slate-950/20 rounded-2xl p-8 flex flex-col items-center justify-center text-center group hover:border-diaroAccent-500/40 transition-colors"
      >
        <span className="material-symbols-outlined text-[42px] text-diaroAccent-400/30 group-hover:text-diaroAccent-400 transition-colors mb-3">cloud_upload</span>
        <p className="text-xs text-white font-semibold">Drag and drop files to encrypt</p>
        <p className="text-[10px] text-diaroAccent-300/30 font-mono mt-1">Supports PNG, JPG, MP3, PDF (Max 15MB)</p>
        <label className="mt-4 px-4 py-2 bg-diaroAccent-600 hover:bg-diaroAccent-500 text-white text-[10px] font-mono uppercase tracking-wider rounded-lg cursor-pointer transition-colors">
          Browse Files
          <input type="file" className="hidden" onChange={handleFileUpload} />
        </label>
      </div>

      {/* Content Grids */}
      <section className="mt-6">
        {activeTab === 'images' && (
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-4">
            {IMAGES.map(img => (
              <div key={img.id} className="glass-card rounded-xl overflow-hidden group border border-diaroAccent-500/10 relative">
                {/* Thumb */}
                <div className="h-32 bg-slate-950 relative overflow-hidden">
                  <img src={img.url} alt={img.name} className="w-full h-full object-cover group-hover:scale-105 transition-all duration-300 filter blur-[1px]" />
                  {/* Encrypted lock overlay */}
                  <div className="absolute inset-0 bg-slate-950/60 flex items-center justify-center">
                    <span className="material-symbols-outlined text-[24px] text-emerald-400">encrypted</span>
                  </div>
                </div>
                <div className="p-3 bg-slate-950/40">
                  <p className="text-xs font-semibold text-white truncate">{img.name}</p>
                  <p className="text-[10px] text-diaroAccent-300/40 font-mono mt-0.5">{img.size} • {img.date}</p>
                </div>
              </div>
            ))}
          </div>
        )}

        {activeTab === 'voice' && (
          <div className="space-y-3">
            {VOICE_NOTES.map(vn => (
              <div key={vn.id} className="glass-card rounded-xl p-4 flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-full bg-slate-950/80 flex items-center justify-center text-emerald-400">
                    <span className="material-symbols-outlined text-[20px]">encrypted</span>
                  </div>
                  <div>
                    <p className="text-xs font-semibold text-white">{vn.name}</p>
                    <p className="text-[10px] text-diaroAccent-300/40 font-mono">{vn.duration} • {vn.size} • {vn.date}</p>
                  </div>
                </div>
                <button 
                  onClick={() => alert('Decrypting and streaming voice recording securely...')}
                  className="p-2 rounded-lg bg-diaroAccent-950/50 hover:bg-diaroAccent-900/50 border border-diaroAccent-500/25 text-diaroAccent-400 hover:text-white transition-colors"
                >
                  <span className="material-symbols-outlined text-[20px]">play_arrow</span>
                </button>
              </div>
            ))}
          </div>
        )}

        {activeTab === 'documents' && (
          <div className="space-y-3">
            {DOCUMENTS.map(doc => (
              <div key={doc.id} className="glass-card rounded-xl p-4 flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-full bg-slate-950/80 flex items-center justify-center text-red-400">
                    <span className="material-symbols-outlined text-[20px]">article</span>
                  </div>
                  <div>
                    <p className="text-xs font-semibold text-white">{doc.name}</p>
                    <p className="text-[10px] text-diaroAccent-300/40 font-mono">{doc.size} • {doc.date}</p>
                  </div>
                </div>
                <button 
                  onClick={() => alert('Decrypting PDF locally. Downloading to downloads folder...')}
                  className="p-2 rounded-lg bg-diaroAccent-950/50 hover:bg-diaroAccent-900/50 border border-diaroAccent-500/25 text-diaroAccent-400 hover:text-white transition-colors"
                >
                  <span className="material-symbols-outlined text-[20px]">download</span>
                </button>
              </div>
            ))}
          </div>
        )}
      </section>

    </main>
  );
}
