-- ══════════════════════════════════════════════════════════════
-- Muslim Leveling v6 — Supabase RLS untuk backup progress
-- Jalankan di SQL Editor Supabase project lo.
-- Pastikan tabel user_data SUDAH ADA (branch ini upsert manual).
-- ══════════════════════════════════════════════════════════════

-- 1. Enable RLS (baris gak bisa dibaca/diubah tanpa policy)
ALTER TABLE user_data ENABLE ROW LEVEL SECURITY;

-- 2. User cuma bisa baca/bikin/edit baris miliknya sendiri.
--    device_id = auth.uid() setelah login Google (app never writes as guest).
--    Guest random device_id cannot satisfy RLS — app gates sync on canSync.

DROP POLICY IF EXISTS "own row read"   ON user_data;
DROP POLICY IF EXISTS "own row insert" ON user_data;
DROP POLICY IF EXISTS "own row update" ON user_data;

CREATE POLICY "own row read"
  ON user_data FOR SELECT
  USING (auth.uid()::text = device_id);

CREATE POLICY "own row insert"
  ON user_data FOR INSERT
  WITH CHECK (auth.uid()::text = device_id);

CREATE POLICY "own row update"
  ON user_data FOR UPDATE
  USING (auth.uid()::text = device_id)
  WITH CHECK (auth.uid()::text = device_id);

-- 3. (Optional) Index biar lookup by device_id cepat
CREATE INDEX IF NOT EXISTS user_data_device_id_idx ON user_data (device_id);
