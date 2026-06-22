import React from 'react';

export default class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }

  componentDidCatch(error, errorInfo) {
    console.error("UI Render Crash Caught:", error, errorInfo);
    // If online, we could log this to Supabase audit_logs via window global
    if (window.logCrashToSupabase) {
      window.logCrashToSupabase(error.message, error.stack);
    }
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="min-h-screen bg-bgDark flex items-center justify-center p-4">
          <div className="glass-card rounded-2xl p-6 shadow-xl max-w-sm w-full text-center space-y-4 border border-red-500/30">
            <span className="material-symbols-outlined text-4xl text-red-500">warning</span>
            <h1 className="text-xl font-bold text-white tracking-widest uppercase">Vault Crash Detected</h1>
            <p className="text-xs text-diaroAccent-300/60 font-mono">
              A severe UI thread error occurred. To protect your data, the vault interface has halted.
            </p>
            <div className="p-3 bg-red-950/20 rounded-lg text-left overflow-x-auto">
              <pre className="text-[10px] text-red-400 font-mono">
                {this.state.error?.message}
              </pre>
            </div>
            <button
              onClick={() => window.location.reload()}
              className="w-full py-3 bg-red-600 hover:bg-red-500 text-white font-semibold text-xs uppercase tracking-wider rounded-xl transition-all"
            >
              Reboot Vault Terminal
            </button>
          </div>
        </div>
      );
    }

    return this.props.children; 
  }
}
