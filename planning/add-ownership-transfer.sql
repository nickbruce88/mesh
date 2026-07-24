-- ============================================================================================
-- Mesh — program ownership transfer / claim (v40.68)
-- Supabase project zsjxauwwqyyhgxzgnfoj. Run in the SQL editor.
--
-- Lets the current program owner mint a one-time "transfer code" that another account can
-- redeem to become the owner. Powers two things:
--   1. Concierge onboarding — an agency builds the program under its own account, then hands
--      ownership to the coach without ever sharing a password.
--   2. Coaching turnover — a departing head coach hands the program to the incoming one.
--
-- The transfer code is prefixed "OWN-" so the client can tell it apart from the player/parent/
-- assistant join codes. It is single-use (cleared the moment it's claimed). Treat it like a
-- password: whoever redeems it becomes the owner.
-- ============================================================================================

alter table public.programs add column if not exists owner_claim_code text;

-- ---- generate_owner_claim_code: current owner mints a fresh transfer code ----
create or replace function generate_owner_claim_code(p_program_id uuid) returns text
language plpgsql security definer set search_path = public as $$
declare v_code text;
begin
  if not exists (select 1 from programs where id = p_program_id and owner_id = auth.uid()) then
    raise exception 'only the current owner can create a transfer code';
  end if;
  v_code := 'OWN-' || upper(substr(md5(random()::text || clock_timestamp()::text), 1, 6));
  update programs set owner_claim_code = v_code where id = p_program_id;
  return v_code;
end; $$;
grant execute on function generate_owner_claim_code(uuid) to authenticated;

-- ---- claim_program_ownership: a signed-in account redeems the code to become owner ----
create or replace function claim_program_ownership(p_code text) returns uuid
language plpgsql security definer set search_path = public as $$
declare v_pid uuid; v_old uuid;
begin
  p_code := upper(trim(coalesce(p_code, '')));
  if p_code = '' then raise exception 'code required'; end if;

  select id, owner_id into v_pid, v_old from programs where owner_claim_code = p_code;
  if v_pid is null then raise exception 'invalid or already-used transfer code'; end if;

  -- Caller already owns it → just consume the code.
  if v_old = auth.uid() then
    update programs set owner_claim_code = null where id = v_pid;
    return v_pid;
  end if;

  -- Hand ownership to the caller and burn the code.
  update programs set owner_id = auth.uid(), owner_claim_code = null where id = v_pid;

  -- If the new owner had been an assistant on this program, drop that row — they're the head coach now.
  delete from profiles where id = auth.uid() and program_id = v_pid;

  return v_pid;
end; $$;
grant execute on function claim_program_ownership(text) to authenticated;

-- NOTE: SECURITY DEFINER is required (it rewrites owner_id, which RLS would block). Authorization
-- is the code itself — generate_owner_claim_code only lets the real owner mint one, and the code
-- is single-use. The previous owner is NOT auto-removed; if they should stay on as an assistant
-- they re-join with the Assistant Coach code, and if they were a throwaway build account they can
-- simply be ignored (they no longer resolve to this program).
