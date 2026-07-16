-- ============================================================
-- Mesh — messaging security fixes (v39.68)
-- Run this whole file in the Supabase SQL editor.
-- Safe to re-run (create or replace / drop-if-exists).
-- ============================================================
--
-- Fixes three SECURITY DEFINER gaps found in the 2026-07-15 audit:
--   A. list_my_threads leaked broadcasts across programs (caller-supplied program id)
--   B. thread_members / thread_participant_ids had the same cross-program gap
--   C. create_thread had NO server-side witness/two-adult rule (child-safety guardrail
--      was client-only) — a coach could devtools their way into a private 1:1 with a minor
--
-- After running this, redeploy the send-notification edge function (finding D, separate).


-- ============================================================
-- A. list_my_threads — reject a caller-supplied program that isn't the caller's own.
--    The `mine` CTE filters on p_program_id, but the broadcast branch only checked
--    role membership, never that p_program_id is actually the caller's program.
--    SECURITY DEFINER bypasses RLS, so a player of Program A could pass Program B's
--    uuid (easily obtained — loadProgramByCode returns it from a join code) and read
--    the last message + sender of every broadcast in Program B.
--    Fix: the same up-front guard create_thread already has. (Re-declares the full
--    v39.66 body — muted/archived columns — with the guard added.)
-- ============================================================
drop function if exists list_my_threads(uuid);
create function list_my_threads(p_program_id uuid)
returns table (
  id uuid, kind text, subject text, audience_roles text[], created_by uuid,
  last_content text, last_at timestamptz, last_sender text, participant_count int,
  muted boolean, archived boolean
) language plpgsql security definer set search_path=public as $$
begin
  -- GUARD: callers may only list their own program's threads.
  if p_program_id is null or my_program_id() is distinct from p_program_id then
    raise exception 'Not a member of this program';
  end if;
  return query
  with mine as (
    select t.* from message_threads t
    where t.program_id = p_program_id
      and (
        exists(select 1 from thread_participants tp where tp.thread_id = t.id and tp.user_id = auth.uid())
        or (t.kind = 'broadcast' and my_role() = any(t.audience_roles))
      )
  )
  select m.id, m.kind, m.subject, m.audience_roles, m.created_by,
         lm.content, lm.created_at, lm.sender_name,
         (select count(*)::int from thread_participants tp where tp.thread_id = m.id),
         (tm.user_id is not null) as muted,
         (
           (th.user_id is not null and (lm.created_at is null or lm.created_at <= th.hidden_at))
           or (lm.created_at is not null and lm.created_at < now() - interval '6 months')
         ) as archived
  from mine m
  left join lateral (
    select msg.content, msg.created_at, msg.sender_name
    from messages msg where msg.thread_id = m.id
    order by msg.created_at desc limit 1
  ) lm on true
  left join thread_mutes tm on tm.thread_id = m.id and tm.user_id = auth.uid()
  left join thread_hides th on th.thread_id = m.id and th.user_id = auth.uid()
  order by coalesce(lm.created_at, m.created_at) desc;
end; $$;
grant execute on function list_my_threads(uuid) to authenticated;


-- ============================================================
-- B. thread_members / thread_participant_ids — the broadcast fallback in the authz
--    check never verified the thread is in the caller's program. Add that clause.
--    (is_thread_participant() already scopes the participant branch correctly;
--    only the broadcast branch was open.)
-- ============================================================
create or replace function thread_members(p_thread uuid)
returns table (user_id uuid, name text, role text, is_witness boolean)
language plpgsql security definer set search_path=public as $$
begin
  if not (
    is_thread_participant(p_thread)
    or exists(select 1 from message_threads t
              where t.id = p_thread and t.kind='broadcast'
                and t.program_id = my_program_id()          -- ADDED
                and my_role() = any(t.audience_roles))
  ) then
    raise exception 'Not authorized';
  end if;
  return query
    select tp.user_id,
           coalesce(pr.name, pl.name, 'Member') as name,
           coalesce(case when pr.role='head_coach' then 'coach' else pr.role end, 'player') as role,
           tp.is_witness
    from thread_participants tp
    left join profiles pr on pr.id = tp.user_id
    left join players  pl on pl.auth_uid = tp.user_id
    where tp.thread_id = p_thread;
end; $$;
grant execute on function thread_members(uuid) to authenticated;

create or replace function thread_participant_ids(p_thread uuid)
returns setof uuid language plpgsql security definer set search_path=public as $$
begin
  if not (
    is_thread_participant(p_thread)
    or exists(select 1 from message_threads t
              where t.id = p_thread and t.kind='broadcast'
                and t.program_id = my_program_id()          -- ADDED
                and my_role() = any(t.audience_roles))
  ) then
    raise exception 'Not authorized';
  end if;
  return query select tp.user_id from thread_participants tp where tp.thread_id = p_thread;
end; $$;
grant execute on function thread_participant_ids(uuid) to authenticated;


-- ============================================================
-- C. create_thread — enforce the two-adult / witness rule server-side.
--    Mirrors the client rule in validateNG() EXACTLY:
--      if the thread includes any player, it must have either
--        (>= 2 coaches) OR (>= 1 coach AND >= 1 parent).
--    The rule is evaluated over the FULL participant set: creator + participants +
--    witnesses. Broadcast threads (no participant list) trivially pass — no players.
--    A coach's devtools attempt to open a bare [coach, player] dm now raises.
-- ============================================================
create or replace function create_thread(
  p_program_id uuid, p_kind text, p_subject text,
  p_participant_uids uuid[], p_witness_uids uuid[]
) returns uuid language plpgsql security definer set search_path=public as $$
declare
  v_thread uuid;
  v_uid uuid;
  v_all uuid[];
  v_role text;
  n_coach int := 0;
  n_parent int := 0;
  n_player int := 0;
begin
  if p_program_id is null or my_program_id() is distinct from p_program_id then
    raise exception 'Not a member of this program';
  end if;

  -- Build the full, de-duplicated participant set: creator + participants + witnesses.
  v_all := array(
    select distinct u from unnest(
      array[auth.uid()]
      || coalesce(p_participant_uids, '{}')
      || coalesce(p_witness_uids, '{}')
    ) as u
    where u is not null
  );

  -- Classify each participant and count adults vs players.
  foreach v_uid in array v_all loop
    select case
      when exists(select 1 from profiles pr where pr.id = v_uid and pr.role in ('coach','head_coach')) then 'coach'
      when exists(select 1 from profiles pr where pr.id = v_uid and pr.role = 'parent') then 'parent'
      when exists(select 1 from players pl where pl.auth_uid = v_uid) then 'player'
      else 'unknown'
    end into v_role;
    if    v_role = 'coach'  then n_coach  := n_coach  + 1;
    elsif v_role = 'parent' then n_parent := n_parent + 1;
    elsif v_role = 'player' then n_player := n_player + 1;
    end if;
  end loop;

  -- The child-safety guardrail. Never let a player be in a thread that isn't
  -- witnessed by a second adult.
  if n_player > 0 and not (n_coach >= 2 or (n_coach >= 1 and n_parent >= 1)) then
    raise exception 'A thread that includes a player must also include a second coach or a parent';
  end if;

  insert into message_threads(program_id, created_by, kind, subject)
    values (p_program_id, auth.uid(), coalesce(p_kind,'dm'), p_subject)
    returning id into v_thread;

  insert into thread_participants(thread_id, user_id, role)
    values (v_thread, auth.uid(), my_role()) on conflict do nothing;

  if p_participant_uids is not null then
    foreach v_uid in array p_participant_uids loop
      if v_uid is not null then
        insert into thread_participants(thread_id, user_id) values (v_thread, v_uid) on conflict do nothing;
      end if;
    end loop;
  end if;

  if p_witness_uids is not null then
    foreach v_uid in array p_witness_uids loop
      if v_uid is not null then
        insert into thread_participants(thread_id, user_id, is_witness)
          values (v_thread, v_uid, true)
          on conflict (thread_id, user_id) do update set is_witness = true;
      end if;
    end loop;
  end if;

  return v_thread;
end; $$;
grant execute on function create_thread(uuid, text, text, uuid[], uuid[]) to authenticated;


-- ============================================================
-- VERIFY (run as a signed-in user via the app console, NOT the SQL editor —
-- auth.uid() is NULL in the editor):
--   -- own program: returns rows
--   await db.rpc('list_my_threads', { p_program_id: '<your program uuid>' })
--   -- other program: should error "Not a member of this program"
--   await db.rpc('list_my_threads', { p_program_id: '<some other program uuid>' })
--   -- bare coach+player dm: should error (child-safety)
--   await db.rpc('create_thread', { p_program_id:'<yours>', p_kind:'dm', p_subject:null,
--                                   p_participant_uids:['<a player uid>'], p_witness_uids:[] })
-- ============================================================
