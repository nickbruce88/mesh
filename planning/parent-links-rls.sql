-- ============================================================
-- Mesh — enable RLS on parent_links (pre-launch hardening)
-- Run this whole file in the Supabase SQL editor. Safe to re-run.
-- ============================================================
--
-- parent_links = {id, program_id, parent_uid, player_id, created_at} — the
-- guardian↔player junction. It was the only public table with RLS OFF, which
-- means anyone with the anon key (embedded in the public page) could read the
-- whole table: which parent is linked to which child, across every program.
--
-- All real access already goes through SECURITY DEFINER RPCs that BYPASS RLS:
--   * register_parent()  writes the row
--   * get_my_player()    reads it (joined to players)
-- The client never queries parent_links directly (verified in index.html), so
-- enabling RLS does not break any existing path.
--
-- Policy below is defense-in-depth: if anything ever reads parent_links from
-- the client, a parent can see ONLY their own links. There is intentionally NO
-- insert/update/delete policy — writes must go through register_parent.

alter table parent_links enable row level security;

drop policy if exists parent_links_select_own on parent_links;
create policy parent_links_select_own
  on parent_links for select
  using (parent_uid = auth.uid());

-- Verify:
--   select tablename, rowsecurity from pg_tables
--   where schemaname='public' and tablename='parent_links';   -- rowsecurity = true
-- And confirm the parent app still works: sign in as a parent →
-- More → My Player should still load (get_my_player bypasses RLS).
