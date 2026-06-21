-- YNote Supabase Migration v5
-- Run this in your Supabase SQL Editor to support the Idempotency Protocol.

-- Add sync_id column with unique constraint to prevent duplicate syncs during network retries
ALTER TABLE public.journal_entries 
ADD COLUMN IF NOT EXISTS sync_id TEXT UNIQUE;

-- Create an index to speed up idempotency lookups
CREATE INDEX IF NOT EXISTS idx_journal_entries_sync_id 
ON public.journal_entries(sync_id);

-- Optional: Update any existing rows to have a pseudo-unique sync_id based on their current hash to avoid nulls
UPDATE public.journal_entries
SET sync_id = id::text || '_' || COALESCE(sync_hash, extract(epoch from updated_at)::text)
WHERE sync_id IS NULL;
