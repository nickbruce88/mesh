-- ============================================================================================
-- Mesh — admin_transfer_ownership (operator tool, v40.68+)
-- Supabase project zsjxauwwqyyhgxzgnfoj. Run in the SQL editor.
--
-- For the ABRUPT-DEPARTURE case: a head coach leaves without minting a transfer code, so no one
-- in the app can reassign the program (only the current owner can generate a code). You, as the
-- operator, reassign it here by NEW OWNER'S EMAIL — no UUID digging.
--
-- SECURITY: execute is REVOKED FROM PUBLIC, so no signed-in app user can ever call this. Only the
-- SQL editor / service_role (i.e. you) can run it. It is intentionally NOT granted to authenticated
-- — that would let anyone steal any program. It reads auth.users, which only works with elevated
-- privileges (the SQL editor has them).
-- ============================================================================================

create or replace function admin_transfer_ownership(p_program_ref text, p_new_owner_email text)
returns text
language plpgsql
as $$
declare
  v_pid uuid;
  v_new_uid uuid;
  v_old uuid;
  v_name text;
begin
  -- Resolve the program: accept its UUID, or its exact team_name.
  if p_program_ref ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
    v_pid := p_program_ref::uuid;
  else
    if (select count(*) from programs where team_name = p_program_ref) = 0 then
      raise exception 'no program named "%" — pass the program id instead', p_program_ref;
    elsif (select count(*) from programs where team_name = p_program_ref) > 1 then
      raise exception 'more than one program named "%" — pass the program id instead', p_program_ref;
    end if;
    select id into v_pid from programs where team_name = p_program_ref;
  end if;
  if not exists (select 1 from programs where id = v_pid) then
    raise exception 'no program with id %', v_pid;
  end if;

  -- Resolve the new owner by email — they must have signed up already.
  select id into v_new_uid from auth.users where lower(email) = lower(trim(p_new_owner_email));
  if v_new_uid is null then
    raise exception 'no account for "%" — have them sign up (and confirm their email) first, then re-run', p_new_owner_email;
  end if;

  select owner_id into v_old from programs where id = v_pid;
  if v_old = v_new_uid then
    return format('%s is already the owner — nothing to do', p_new_owner_email);
  end if;

  -- Hand over ownership, clear any pending transfer code, and drop the new owner's assistant row.
  update programs set owner_id = v_new_uid, owner_claim_code = null where id = v_pid;
  delete from profiles where id = v_new_uid and program_id = v_pid;

  -- Best-effort: point programs.coach_name at the new owner's known name.
  select name into v_name from players  where auth_uid = v_new_uid and program_id = v_pid limit 1;
  if v_name is null then select name into v_name from profiles where id = v_new_uid limit 1; end if;
  if v_name is not null then update programs set coach_name = v_name where id = v_pid; end if;

  return format('Ownership of "%s" (%s) transferred to %s (%s)',
    (select team_name from programs where id = v_pid), v_pid, p_new_owner_email, v_new_uid);
end; $$;

revoke execute on function admin_transfer_ownership(text, text) from public;

-- ============================================================================================
-- USAGE
--
--   select admin_transfer_ownership('Northgate Prep Hawks', 'newcoach@email.com');
--   -- or, if the team name is ambiguous / you have the id:
--   select admin_transfer_ownership('00000000-0000-0000-0000-000000000000', 'newcoach@email.com');
--
-- HELPER LOOKUPS (run these first if you need to find things):
--
--   -- every program + who currently owns it:
--   select p.team_name, p.id, u.email as owner_email
--     from programs p left join auth.users u on u.id = p.owner_id
--    order by p.team_name;
--
--   -- confirm the new coach has an account (and confirmed their email):
--   select id, email, email_confirmed_at from auth.users
--    where lower(email) = lower('newcoach@email.com');
-- ============================================================================================
