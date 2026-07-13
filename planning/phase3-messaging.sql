-- Mesh — Phase 3: Messaging schema + threads/participants + RLS
-- Supabase project zsjxauwwqyyhgxzgnfoj. Run in the SQL editor.
-- THREE PARTS — run in order, at the steps below:
--   PART 1  (now)     : schema + helper fns + RPCs. Safe/idempotent. RLS still OFF.
--   PART 2  (later)   : migrate legacy group_name messages onto threads. Run AFTER the client is verified.
--   PART 3  (last)    : enable RLS + policies. Run AFTER migration, then re-verify.
-- ===========================================================================================


-- =====================  PART 1 — SCHEMA + FUNCTIONS (run now)  ==============================

create table if not exists message_threads (
  id uuid primary key default gen_random_uuid(),
  program_id uuid not null references programs(id) on delete cascade,
  created_by uuid,                              -- auth.uid() of creator (null for migrated legacy)
  kind text not null default 'dm',              -- 'broadcast' | 'dm' | 'witnessed_dm'
  subject text,                                 -- thread name / title
  audience_roles text[] not null default '{}',  -- broadcast only: roles allowed to read (coach/player/parent)
  created_at timestamptz not null default now()
);

create table if not exists thread_participants (
  thread_id uuid not null references message_threads(id) on delete cascade,
  user_id   uuid not null,
  role      text,
  is_witness boolean not null default false,
  added_at  timestamptz not null default now(),
  primary key (thread_id, user_id)
);

alter table messages add column if not exists thread_id uuid references message_threads(id) on delete set null;
alter table messages add column if not exists sender_id uuid;

create index if not exists idx_messages_thread on messages(thread_id);
create index if not exists idx_tp_user         on thread_participants(user_id);
create index if not exists idx_threads_program on message_threads(program_id);

-- ---- Identity helpers (SECURITY DEFINER so they work under RLS without recursion) ----
-- Caller's program: coaches/parents via profiles, players via players.auth_uid.
create or replace function my_program_id() returns uuid
language sql security definer stable set search_path=public as $$
  select coalesce(
    (select program_id from profiles where id = auth.uid() limit 1),
    (select program_id from players  where auth_uid = auth.uid() limit 1)
  );
$$;

-- Caller's normalized role: head_coach -> 'coach'; players -> 'player'.
create or replace function my_role() returns text
language sql security definer stable set search_path=public as $$
  select coalesce(
    (select case when role = 'head_coach' then 'coach' else role end from profiles where id = auth.uid() limit 1),
    (select 'player' from players where auth_uid = auth.uid() limit 1)
  );
$$;

create or replace function is_thread_participant(p_thread uuid) returns boolean
language sql security definer stable set search_path=public as $$
  select exists(select 1 from thread_participants where thread_id = p_thread and user_id = auth.uid());
$$;

-- ---- Program member directory (powers all recipient/witness pickers) ----
create or replace function list_program_directory(p_program_id uuid)
returns table (user_id uuid, name text, role text)
language plpgsql security definer set search_path=public as $$
begin
  if my_program_id() is distinct from p_program_id then raise exception 'Not a member of this program'; end if;
  return query
    select pr.id, pr.name, case when pr.role = 'head_coach' then 'coach' else pr.role end
      from profiles pr where pr.program_id = p_program_id
    union all
    select pl.auth_uid, pl.name, 'player'
      from players pl where pl.program_id = p_program_id and pl.auth_uid is not null and pl.role = 'player';
end; $$;
grant execute on function list_program_directory(uuid) to authenticated;

-- ---- Ensure a standing broadcast thread exists (All Coaches / All Players / All Parents / custom) ----
create or replace function ensure_broadcast_thread(p_program_id uuid, p_subject text, p_audience text[])
returns uuid language plpgsql security definer set search_path=public as $$
declare v_id uuid;
begin
  if my_program_id() is distinct from p_program_id then raise exception 'Not a member of this program'; end if;
  select id into v_id from message_threads
    where program_id = p_program_id and kind = 'broadcast' and subject = p_subject limit 1;
  if v_id is null then
    insert into message_threads(program_id, created_by, kind, subject, audience_roles)
      values (p_program_id, auth.uid(), 'broadcast', p_subject, coalesce(p_audience,'{}')) returning id into v_id;
  end if;
  return v_id;
end; $$;
grant execute on function ensure_broadcast_thread(uuid, text, text[]) to authenticated;

-- ---- Create a private/witnessed thread with participants atomically (creator auto-added) ----
create or replace function create_thread(
  p_program_id uuid, p_kind text, p_subject text,
  p_participant_uids uuid[], p_witness_uids uuid[]
) returns uuid language plpgsql security definer set search_path=public as $$
declare v_thread uuid; v_uid uuid;
begin
  if p_program_id is null or my_program_id() is distinct from p_program_id then
    raise exception 'Not a member of this program';
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

-- ---- List the caller's threads (participant threads + broadcasts to their role) with last message ----
create or replace function list_my_threads(p_program_id uuid)
returns table (
  id uuid, kind text, subject text, audience_roles text[], created_by uuid,
  last_content text, last_at timestamptz, last_sender text, participant_count int
) language plpgsql security definer set search_path=public as $$
begin
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
         (select count(*)::int from thread_participants tp where tp.thread_id = m.id)
  from mine m
  left join lateral (
    select msg.content, msg.created_at, msg.sender_name
    from messages msg where msg.thread_id = m.id
    order by msg.created_at desc limit 1
  ) lm on true
  order by coalesce(lm.created_at, m.created_at) desc;
end; $$;
grant execute on function list_my_threads(uuid) to authenticated;

-- ---- Members of a thread (for titles + witness display); caller must be able to see the thread ----
create or replace function thread_members(p_thread uuid)
returns table (user_id uuid, name text, role text, is_witness boolean)
language plpgsql security definer set search_path=public as $$
begin
  if not (
    is_thread_participant(p_thread)
    or exists(select 1 from message_threads t
              where t.id = p_thread and t.kind='broadcast' and my_role() = any(t.audience_roles))
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

-- ---- Participant uids of a thread (for targeted push); caller must see the thread ----
create or replace function thread_participant_ids(p_thread uuid)
returns setof uuid language plpgsql security definer set search_path=public as $$
begin
  if not (
    is_thread_participant(p_thread)
    or exists(select 1 from message_threads t
              where t.id = p_thread and t.kind='broadcast' and my_role() = any(t.audience_roles))
  ) then
    raise exception 'Not authorized';
  end if;
  return query select tp.user_id from thread_participants tp where tp.thread_id = p_thread;
end; $$;
grant execute on function thread_participant_ids(uuid) to authenticated;

-- =====================  END PART 1  ========================================================


-- =====================  PART 1b — ENABLE REALTIME (run now)  ================================
-- Realtime (postgres_changes) only fires for tables in the supabase_realtime publication.
-- Without this, new messages never push to open clients (you must refresh to see them).
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and tablename='messages') then
    alter publication supabase_realtime add table messages;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and tablename='message_threads') then
    alter publication supabase_realtime add table message_threads;
  end if;
end $$;
-- =====================  END PART 1b  =======================================================


-- =====================  PART 2 — MIGRATE LEGACY MESSAGES (run later, after client verified) ==
-- Creates one broadcast thread per distinct (program_id, group_name) and backfills messages.thread_id.
/*
do $$
declare r record; v_thread uuid; v_aud text[]; v_subj text;
begin
  for r in
    select distinct program_id, group_name from messages
    where thread_id is null and group_name is not null and group_name <> ''
  loop
    v_subj := case r.group_name
                when 'staff'   then 'All Coaches & Staff'
                when 'players' then 'All Players'
                when 'parents' then 'All Parents'
                else r.group_name end;
    v_aud  := case r.group_name
                when 'staff'   then array['coach']
                when 'players' then array['player','coach']
                when 'parents' then array['parent','coach']
                else array['coach','player','parent'] end;   -- legacy custom groups: keep everyone's access
    select id into v_thread from message_threads
      where program_id = r.program_id and kind='broadcast' and subject = v_subj limit 1;
    if v_thread is null then
      insert into message_threads(program_id, created_by, kind, subject, audience_roles)
        values (r.program_id, null, 'broadcast', v_subj, v_aud) returning id into v_thread;
    end if;
    update messages set thread_id = v_thread
      where program_id = r.program_id and group_name = r.group_name and thread_id is null;
  end loop;
end $$;
*/
-- =====================  END PART 2  ========================================================


-- =====================  PART 3 — ENABLE RLS + POLICIES (run last, after migration) ==========
/*
alter table message_threads    enable row level security;
alter table thread_participants enable row level security;
alter table messages           enable row level security;

drop policy if exists threads_read on message_threads;
create policy threads_read on message_threads for select using (
  is_thread_participant(id)
  or (kind='broadcast' and program_id = my_program_id() and my_role() = any(audience_roles))
  or created_by = auth.uid()
);

drop policy if exists tp_read on thread_participants;
create policy tp_read on thread_participants for select using ( is_thread_participant(thread_id) );

drop policy if exists messages_read on messages;
create policy messages_read on messages for select using (
  thread_id is not null and exists(
    select 1 from message_threads t where t.id = messages.thread_id and (
      is_thread_participant(t.id)
      or (t.kind='broadcast' and t.program_id = my_program_id() and my_role() = any(t.audience_roles))
    )
  )
);

drop policy if exists messages_write on messages;
create policy messages_write on messages for insert with check (
  sender_id = auth.uid() and thread_id is not null and exists(
    select 1 from message_threads t where t.id = messages.thread_id and (
      is_thread_participant(t.id)
      or (t.kind='broadcast' and t.program_id = my_program_id() and my_role() = any(t.audience_roles))
    )
  )
);
*/
-- =====================  END PART 3  ========================================================
