-- ============================================================================================
-- Mesh — persist per-player team levels (v40.73)
-- Supabase project zsjxauwwqyyhgxzgnfoj. Run in the SQL editor.
--
-- BUG: a player's team-level eligibility (Varsity / JV / Freshman …) was only ever held in
-- memory — never written to the DB and never loaded back. So after any refresh every player's
-- `teams` was undefined, and the depth-chart level filter ("show only if teams includes this
-- level, else show on all levels") fell through and put EVERY player on EVERY level. That's why
-- a Freshman-only player showed up on the Varsity depth chart.
--
-- This adds a column to store the levels (JSON array of level names, e.g. ["Freshman"]). The
-- client writes it on every player save and loads it back, falling back to a year-based default
-- only when nothing is stored.
-- ============================================================================================

alter table public.players add column if not exists team_levels text;
