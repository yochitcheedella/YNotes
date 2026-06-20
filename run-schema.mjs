// run-schema.mjs - Executes YNotes database schema on Supabase
import { readFileSync } from 'fs';

const PROJECT_REF = 'ojzctwtvocuabudmvqlt';
const SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9qemN0d3R2b2N1YWJ1ZG12cWx0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MTk0MjE1MiwiZXhwIjoyMDk3NTE4MTUyfQ.sJi6oLkecOVwPvEI90mjWrhlnnoSU2HYHZgU9NtSPpU';

const sql = readFileSync('./supabase_schema.sql', 'utf-8');

console.log('🔄 Running YNotes schema via Supabase pg endpoint...\n');

// Try the pg query endpoint (available in newer Supabase projects)
const res = await fetch(`https://${PROJECT_REF}.supabase.co/pg/query`, {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${SERVICE_ROLE_KEY}`,
    'Content-Type': 'application/json',
    'apikey': SERVICE_ROLE_KEY,
  },
  body: JSON.stringify({ query: sql }),
});

const text = await res.text();
console.log('Status:', res.status);
console.log('Response:', text.slice(0, 500));
