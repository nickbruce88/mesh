-- ============================================================================================
-- Mesh — update_my_name RPC (v40.67)
-- Supabase project zsjxauwwqyyhgxzgnfoj. Run in the SQL editor.
--
-- Lets any signed-in user rename themselves from Edit Profile and have it persist + sync
-- across devices. A player's name lives on players.name (matched by auth_uid), a parent's on
-- profiles.name, and a coach's on programs.coach_name — this SECURITY DEFINER function updates
-- whichever row(s) belong to the caller (auth.uid()), so it works for every role and never
-- touches anyone else's data.
--
-- Before this, the client wrote programs.coach_name for everyone, which RLS rejected for
-- players/parents — their rename only lived in localStorage and never synced.
-- ============================================================================================

create or replace function update_my_name(p_name text) returns void
language plpgsql security definer set search_path = public as $$
begin
  p_name := trim(coalesce(p_name, ''));
  if p_name = '' then raise exception 'name required'; end if;

  update players  set name       = p_name where auth_uid = auth.uid();
  update profiles set name       = p_name where id       = auth.uid();
  update programs set coach_name = p_name where owner_id = auth.uid();
end; $$;

grant execute on function update_my_name(text) to authenticated;

-- Note: SECURITY DEFINER is safe here — every UPDATE is scoped to auth.uid(), so a caller can
-- only ever change their own name. No row belonging to another user is reachable.
