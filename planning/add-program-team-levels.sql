-- ============================================================================================
-- Mesh — configurable team levels per program (v40.74)
-- Supabase project zsjxauwwqyyhgxzgnfoj. Run in the SQL editor.
--
-- Stores each program's ordered team-level list (JSON array of names, e.g.
-- ["Varsity","JV","Freshman"]). Defaults to Varsity/JV/Freshman in the client when null.
-- The depth-chart level selector and the player team-level chips both read from this list,
-- so a program can rename/add/remove/reorder levels (youth 8U/10U/12U, MS 7th/8th, Frosh, etc.).
-- ============================================================================================

alter table public.programs add column if not exists team_levels text;
