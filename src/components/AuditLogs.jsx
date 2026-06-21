import React, { useEffect, useState } from 'react';
import { supabase } from '../supabaseClient';

export default function AuditLogs({ onCancel }) {
  const [logs, setLogs] = useState([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    async function fetchLogs() {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        setIsLoading(false);
        return;
      }

      // Fetch the most recent 20 security audit logs for this user
      const { data, error } = await supabase
        .from('audit_logs')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', { ascending: false })
        .limit(20);

      if (!error && data) {
        setLogs(data);
      }
      setIsLoading(false);
    }
    fetchLogs();
  }, []);

  return (
    <main className="relative z-10 pt-20 px-4 max-w-3xl mx-auto pb-24">
      <div className="glass-card rounded-2xl p-6 shadow-xl space-y-6">
        <div className="flex justify-between items-center">
          <button 
            onClick={onCancel}
            className="flex items-center gap-1.5 text-diaroAccent-300/60 hover:text-white transition-colors"
          >
            <span className="material-symbols-outlined text-[20px]">arrow_back</span>
            <span className="text-xs uppercase font-mono tracking-wider">Back</span>
          </button>
          
          <h2 className="text-lg font-semibold text-white flex items-center gap-2">
            <span className="material-symbols-outlined text-diaroAccent-400">security</span>
            Security Audit Logs
          </h2>
          <div className="w-16" />
        </div>

        <div className="bg-[#050505] rounded-xl border border-diaroAccent-900/30 overflow-hidden">
          {isLoading ? (
            <div className="p-8 text-center text-diaroAccent-400/50 font-mono text-sm animate-pulse">Scanning security logs...</div>
          ) : logs.length === 0 ? (
            <div className="p-8 text-center text-gray-500 font-mono text-sm">No security events found.</div>
          ) : (
            <ul className="divide-y divide-blue-900/20">
              {logs.map((log) => (
                <li key={log.id} className="p-4 hover:bg-white/5 transition-colors flex items-start justify-between">
                  <div className="space-y-1">
                    <p className="text-white text-sm font-semibold capitalize">{log.action.replace(/_/g, ' ')}</p>
                    <p className="text-xs text-diaroAccent-300/60 font-mono">{log.device_info}</p>
                    {log.ip_address && <p className="text-[10px] text-gray-500 font-mono">IP: {log.ip_address}</p>}
                  </div>
                  <div className="text-right">
                    <p className="text-xs text-diaroAccent-400 font-mono">
                      {new Date(log.created_at).toLocaleDateString()}
                    </p>
                    <p className="text-[10px] text-gray-500 font-mono">
                      {new Date(log.created_at).toLocaleTimeString()}
                    </p>
                  </div>
                </li>
              ))}
            </ul>
          )}
        </div>
      </div>
    </main>
  );
}
