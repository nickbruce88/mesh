-- Mesh — Phase 3f: per-user "guides seen" tracking (feature walkthroughs)
-- Supabase project zsjxauwwqyyhgxzgnfoj. Run in the SQL editor. Idempotent; safe to re-run.
--
-- Each major tab has a first-run spotlight guide that should auto-launch ONCE, then never
-- again — and that "seen" state should follow the user across devices (not localStorage).
-- Stored as a jsonb array of guide keys on the profile.
--
-- Depends on: profiles(id).
-- ===========================================================================================

alter table profiles add column if not exists guides_seen jsonb default '[]'::jsonb;

-- Read the caller's seen-guide keys.
create or replace function get_my_guides_seen()
returns jsonb language sql security definer set search_path=public as $$
  select coalesce(guides_seen, '[]'::jsonb) from profiles where id = auth.uid();
$$;
grant execute on function get_my_guides_seen() to authenticated;

-- Mark one guide key as seen for the caller (dedup, order-independent).
create or replace function mark_guide_seen(p_key text)
returns void language plpgsql security definer set search_path=public as $$
begin
  update profiles
     set guides_seen = (
       select jsonb_agg(distinct e)
       from jsonb_array_elements_text(coalesce(guides_seen, '[]'::jsonb) || jsonb_build_array(p_key)) e
     )
   where id = auth.uid();
end; $$;
grant execute on function mark_guide_seen(text) to authenticated;

-- Optional: let a user replay everything fresh (clears their seen list).
create or replace function reset_my_guides_seen()
returns void language sql security definer set search_path=public as $$
  update profiles set guides_seen = '[]'::jsonb where id = auth.uid();
$$;
grant execute on function reset_my_guides_seen() to authenticated;

-- ===========================================================================================
-- Verify (optional):
--   select mark_guide_seen('practice');
--   select get_my_guides_seen();      -- → ["practice"]
--   select reset_my_guides_seen();
-- ===========================================================================================
