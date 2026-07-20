-- Mesh — Phase 3c: server-side message read tracking (unread flags across devices)
-- Supabase project zsjxauwwqyyhgxzgnfoj. Run in the SQL editor. Idempotent; safe to re-run.
--
-- Adds a per-user "last read" timestamp per thread so unread state lives on the server:
--   * shows the moment you log in, on any device (no localStorage)
--   * list_my_threads now returns unread_count per thread
--   * mark_thread_read() is called by the client when a thread is opened
--
-- Depends on phase3-messaging.sql (message_threads, thread_participants, messages.sender_id,
-- and the helpers is_thread_participant(), my_role()).
-- ===========================================================================================

-- ---- Read state: one row per (thread, user); last_read_at = when they last opened it ----
create table if not exists thread_reads (
  thread_id    uuid not null references message_threads(id) on delete cascade,
  user_id      uuid not null,
  last_read_at timestamptz not null default now(),
  primary key (thread_id, user_id)
);
create index if not exists idx_thread_reads_user on thread_reads(user_id);

-- ---- Mark a thread read for the caller (upsert now()). Caller must be able to see the thread. ----
create or replace function mark_thread_read(p_thread uuid)
returns void language plpgsql security definer set search_path=public as $$
begin
  if not (
    is_thread_participant(p_thread)
    or exists(select 1 from message_threads t
              where t.id = p_thread and t.kind = 'broadcast' and my_role() = any(t.audience_roles))
  ) then
    raise exception 'Not authorized';
  end if;
  insert into thread_reads(thread_id, user_id, last_read_at)
  values (p_thread, auth.uid(), now())
  on conflict (thread_id, user_id) do update set last_read_at = excluded.last_read_at;
end; $$;
grant execute on function mark_thread_read(uuid) to authenticated;

-- ---- list_my_threads: add unread_count. Return type changes, so drop then recreate. ----
drop function if exists list_my_threads(uuid);
create or replace function list_my_threads(p_program_id uuid)
returns table (
  id uuid, kind text, subject text, audience_roles text[], created_by uuid,
  last_content text, last_at timestamptz, last_sender text, participant_count int,
  unread_count int
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
  ),
  reads as (
    select tr.thread_id, tr.last_read_at from thread_reads tr where tr.user_id = auth.uid()
  )
  select m.id, m.kind, m.subject, m.audience_roles, m.created_by,
         lm.content, lm.created_at, lm.sender_name,
         (select count(*)::int from thread_participants tp where tp.thread_id = m.id),
         (select count(*)::int from messages msg
            where msg.thread_id = m.id
              -- messages I didn't send, newer than my last read of this thread
              and coalesce(msg.sender_id, '00000000-0000-0000-0000-000000000000'::uuid) <> auth.uid()
              and msg.created_at > coalesce(r.last_read_at, 'epoch'::timestamptz)
         ) as unread_count
  from mine m
  left join reads r on r.thread_id = m.id
  left join lateral (
    select msg.content, msg.created_at, msg.sender_name
    from messages msg where msg.thread_id = m.id
    order by msg.created_at desc limit 1
  ) lm on true
  order by coalesce(lm.created_at, m.created_at) desc;
end; $$;
grant execute on function list_my_threads(uuid) to authenticated;

-- ---- RLS: only the definer functions above touch thread_reads; lock direct access to self ----
alter table thread_reads enable row level security;
drop policy if exists thread_reads_self on thread_reads;
create policy thread_reads_self on thread_reads
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ===========================================================================================
-- Verify (optional):
--   select id, subject, unread_count from list_my_threads('<your-program-id>');
--   select mark_thread_read('<a-thread-id>');   -- then re-run the select; that row → 0
-- ===========================================================================================
