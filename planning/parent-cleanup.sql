-- ============================================================
-- Mesh — Parent role cleanup (v39.59)
-- Run this whole file in the Supabase SQL editor.
-- Safe to re-run (create or replace).
-- ============================================================
--
-- WHY: the parent "My Player" section was static demo HTML (#22, GPA 3.8,
-- "Coach Reed"). To render the parent's REAL linked player we must read
-- parent_links -> players from the client. parent_links is guardian data and
-- players holds PRIVATE COACH NOTES, so the client must NOT select either
-- table directly. This RPC is the only read path: it resolves the caller via
-- auth.uid() and returns a strict WHITELIST of parent-appropriate columns.
--
-- DELIBERATELY NOT RETURNED (do not add these without a product decision):
--   notes_data      -- private coach notes about the player
--   discipline_data -- individual incident log w/ coach commentary
--   academic_data   -- academic note log
--   parent_phone / parent_email — contact PII, not needed by this view
-- The disciplinary *status* badge IS returned; the incident *log* is not.
--
-- Column types on `players` have drifted historically (num/gpa have been both
-- text and numeric in different envs), so every scalar is cast to text. This
-- keeps the function from throwing "structure of query does not match function
-- result type" if a column type differs from what we expect.

create or replace function get_my_player()
returns table (
  id                  uuid,
  name                text,
  num                 text,
  pos                 text,
  year                text,
  height              text,
  weight              text,
  gpa                 text,
  status              text,
  disciplinary_status text
)
language sql
security definer
set search_path = public
as $$
  select
    p.id,
    p.name::text,
    p.num::text,
    p.pos::text,
    p.year::text,
    p.height::text,
    p.weight::text,
    p.gpa::text,
    p.status::text,
    coalesce(p.disciplinary_status, 'green')::text
  from parent_links pl
  join players p on p.id = pl.player_id
  where pl.parent_uid = auth.uid()
  order by p.name;
$$;

grant execute on function get_my_player() to authenticated;

-- Verify (run as a signed-in parent via the app, or impersonate in the editor):
--   select * from get_my_player();
-- Expect: one row per linked player. Zero rows = that parent has no
-- parent_links row (they joined before register_parent shipped — re-join fixes).
