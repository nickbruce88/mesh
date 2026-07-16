-- ============================================================
-- Mesh — players: add the position columns the app already uses (v39.65)
-- Run this whole file in the Supabase SQL editor.
-- Safe to re-run (add column if not exists).
-- ============================================================
--
-- WHY: the client has ALWAYS had posOff/posDef/posST on its player objects:
--   * the depth chart builds its position groups from them (buildDCFromPlayers)
--   * the CSV importer maps off_position/def_position/st_position headers
--   * the manual "+ Player" form and the coach's player editor collect them
-- ...but NO column ever existed for any of them, and no write path sent them.
-- So they lived only in memory: a coach filled them in, the depth chart looked
-- right, and on the next reload the data was gone and the chart silently fell
-- back to the single `pos` field.
--
-- Verified against information_schema on 2026-07-15. The real columns are
-- num / pos / nickname / unit — there is NO `number`, `position`,
-- `position_off`, `position_def` or `position_st`. The coach's player editor
-- was writing those five nonexistent names, which made PostgREST reject the
-- WHOLE update, so editing a player saved nothing at all (not even the name).
-- That half of the fix is client-side; this file only adds the columns.
--
-- Naming: DB uses snake_case position_off; the client object uses posOff.
-- The mapping lives in the client (loadRosterFromSupabase / the write paths).

alter table players add column if not exists position_off text;
alter table players add column if not exists position_def text;
alter table players add column if not exists position_st  text;

-- Verify:
--   select column_name, data_type from information_schema.columns
--   where table_name = 'players' and column_name like 'position%'
--   order by column_name;
-- Expect exactly three rows: position_def, position_off, position_st.
--
-- NOTE: `unit` already exists on players but nothing reads or writes it —
-- it is an orphan column. Left alone here; delete it only after confirming
-- nothing external depends on it.
