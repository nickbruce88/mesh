-- Mesh — Phase 2b: Staff Access (per-coach, per-feature edit permissions)
-- Run this whole block in the Supabase SQL editor (project zsjxauwwqyyhgxzgnfoj).
-- Safe to re-run (idempotent). No data is dropped.

-- 1) Store a coach's per-feature edit permissions as JSON on their profile.
--    null  = "use assistant-coach role defaults" (computed client-side).
--    object= explicit overrides, e.g. {"roster":true,"practice":false,...}
alter table profiles add column if not exists permissions jsonb;

-- 2) Head coach sets ANOTHER coach's permissions.
--    SECURITY DEFINER so it works under RLS; guarded so ONLY the program owner can call it.
create or replace function set_coach_permissions(
  p_coach_uid  uuid,
  p_program_id uuid,
  p_perms      jsonb
) returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from programs
    where id = p_program_id and owner_id = auth.uid()
  ) then
    raise exception 'Only the head coach can set staff access';
  end if;

  update profiles
     set permissions = p_perms
   where id = p_coach_uid
     and program_id = p_program_id
     and role = 'coach';   -- never touch the head coach / non-coach rows
end;
$$;
grant execute on function set_coach_permissions(uuid, uuid, jsonb) to authenticated;

-- 3) Head coach lists the assistant coaches on their program (with current permissions).
--    profiles has RLS (each user reads only their own row), so the owner needs a definer RPC.
create or replace function list_program_coaches(p_program_id uuid)
returns table (id uuid, name text, role text, permissions jsonb)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from programs
    where id = p_program_id and owner_id = auth.uid()
  ) then
    raise exception 'Not authorized';
  end if;

  return query
    select p.id, p.name, p.role, p.permissions
    from profiles p
    where p.program_id = p_program_id
      and p.role = 'coach';
end;
$$;
grant execute on function list_program_coaches(uuid) to authenticated;

-- 4) A coach reads their OWN permissions at login (get_my_profile may predate this column).
create or replace function get_my_permissions()
returns jsonb
language sql
security definer
set search_path = public
as $$
  select permissions from profiles where id = auth.uid();
$$;
grant execute on function get_my_permissions() to authenticated;
