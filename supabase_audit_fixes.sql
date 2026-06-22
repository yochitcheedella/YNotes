-- Supplementary Security Audit Fixes
-- Run this in Supabase SQL Editor to enforce strict compliance with PRD section 4

-- 1. Ensure `audit_logs` are strictly append-only by users. (Already partially covered, but reinforcing)
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can update own audit logs" ON public.audit_logs;
DROP POLICY IF EXISTS "Users can delete own audit logs" ON public.audit_logs;
-- No UPDATE or DELETE allowed on audit logs whatsoever.

-- 2. Verify all functions are SECURITY DEFINER or INVOKER correctly.
-- handle_new_user should be SECURITY DEFINER to bypass RLS when inserting into profiles
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1))
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 3. Strict checking on Notes (Diary Entries)
-- Ensure users cannot read or modify another user's data even if UUID is guessed.
DROP POLICY IF EXISTS "Users can update own notes" ON public.notes;
CREATE POLICY "Users can update own notes" ON public.notes
  FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

SELECT 'Audit fixes applied successfully. Strict RLS enforced.' AS status;
