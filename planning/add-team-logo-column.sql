-- ============================================================================================
-- Mesh — persistence fixes (v40.50): add missing programs columns
-- Supabase project zsjxauwwqyyhgxzgnfoj. Run in the SQL editor.
--
-- Several things were held only in memory and vanished on refresh. v40.50 persists each to its
-- own JSON/text column on `programs` (same pattern as drills_data / announcements_data). This
-- migration adds those columns. Safe to run more than once (IF NOT EXISTS).
--
--   team_logo             – school/team logo (downscaled PNG data URL, <=256px)
--   groups_data           – practice group definitions (names + colors)
--   position_groups_data  – practice-grid position columns + their coaches
--   reminders_data        – practice reminders
--
-- team_primary / team_secondary already exist (appearance save/load use them).
-- ============================================================================================

alter table public.programs add column if not exists team_logo            text;
alter table public.programs add column if not exists groups_data          text;
alter table public.programs add column if not exists position_groups_data text;
alter table public.programs add column if not exists reminders_data       text;

-- Optional: confirm they're all present.
--   select column_name from information_schema.columns
--   where table_name = 'programs'
--     and column_name in ('team_logo','groups_data','position_groups_data','reminders_data',
--                         'team_primary','team_secondary');
