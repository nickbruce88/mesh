-- Mesh — Phase 3d: let a parent join before their player is on the roster
-- Supabase project zsjxauwwqyyhgxzgnfoj. Run in the SQL editor. Idempotent; safe to re-run.
--
-- Problem: the parent join step requires picking their child from the existing roster. If the
-- player hasn't joined / hasn't been added yet, the dropdown is empty and the parent is stuck.
--
-- Fix: find_or_create_player() creates a placeholder player row (no account) for the named child
-- so the parent can link to it now. When the real player later signs up with that name, the
-- existing case-insensitive claim/merge in submitPlayerProfile absorbs the placeholder.
--
-- SECURITY DEFINER so it works before the parent has a profile row (they're mid-join). Gated to
-- authenticated callers; the program_id comes from a valid (non-guessable) join code.
-- ===========================================================================================

create or replace function find_or_create_player(p_program_id uuid, p_player_name text)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_id uuid;
begin
  if p_program_id is null or coalesce(trim(p_player_name), '') = '' then
    raise exception 'program and player name are required';
  end if;
  -- Program must exist (the caller got this id from a real join code).
  if not exists (select 1 from programs where id = p_program_id) then
    raise exception 'Unknown program';
  end if;

  -- Reuse an existing UNCLAIMED roster entry with the same name (case-insensitive) if present,
  -- so a parent typing "Dan Smith" links to the coach's "dan smith" instead of duplicating.
  select id into v_id
    from players
   where program_id = p_program_id
     and lower(name) = lower(trim(p_player_name))
     and auth_uid is null
   limit 1;

  if v_id is null then
    insert into players (program_id, name, role)
    values (p_program_id, trim(p_player_name), 'player')
    returning id into v_id;
  end if;

  return v_id;
end; $$;
grant execute on function find_or_create_player(uuid, text) to authenticated;

-- Verify (optional):
--   select find_or_create_player('<program-id>', 'Test Player');   -- returns a players.id
-- ===========================================================================================
