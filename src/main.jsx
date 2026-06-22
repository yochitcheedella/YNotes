import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.jsx'
import ErrorBoundary from './components/ErrorBoundary.jsx'
import { supabase } from './supabaseClient.js'

window.logCrashToSupabase = async (message, stack) => {
  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (user && navigator.onLine) {
      await supabase.from('audit_logs').insert({
        user_id: user.id,
        action: 'CRITICAL_UI_CRASH',
        details: { message, stack }
      });
    }
  } catch (e) {
    console.error('Failed to log crash:', e);
  }
};

window.addEventListener('unhandledrejection', (event) => {
  console.error("Unhandled Promise Rejection:", event.reason);
  if (window.logCrashToSupabase) {
    window.logCrashToSupabase(event.reason?.message || 'Unknown Promise Rejection', event.reason?.stack);
  }
});

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <ErrorBoundary>
      <App />
    </ErrorBoundary>
  </StrictMode>,
)
