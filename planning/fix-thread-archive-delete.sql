-- ============================================================================================
-- Mesh — fix message archive + add thread delete
-- Supabase project zsjxauwwqyyhgxzgnfoj. Run in the SQL editor.
--
-- BUG: list_my_threads was redefined in phase3c-read-tracking.sql to add unread_count, but that
-- version dropped the `muted` and `archived` columns. hide_thread still records the archive in
-- thread_hides, but the list no longer reports `archived`, so the client can't move the thread
-- out of the inbox — it stays listed. This restores muted + archived AND keeps unread_count.
--
-- Also adds delete_thread(uuid): a hard delete for the thread creator or the program owner
-- (head coach). See the note at the bottom re: witnessed conversations.
-- ============================================================================================

-- ---- list_my_threads: muted + archived + unread_count all together ----
drop function if exists list_my_threads(uuid);
create or replace function list_my_threads(p_program_id uuid)
returns table (
  id uuid, kind text, subject text, audience_roles text[], created_by uuid,
  last_content text, last_at timestamptz, last_sender text, participant_count int,
  muted boolean, archived boolean, unread_count int
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
         (tm.user_id is not null) as muted,
         -- archived if manually hidden and no newer message has arrived since (a new message un-archives)
         (th.user_id is not null and (lm.created_at is null or lm.created_at <= th.hidden_at)) as archived,
         (select count(*)::int from messages msg
            where msg.thread_id = m.id
              and coalesce(msg.sender_id, '00000000-0000-0000-0000-000000000000'::uuid) <> auth.uid()
              and msg.created_at > coalesce(r.last_read_at, 'epoch'::timestamptz)
         ) as unread_count
  from mine m
  left join reads r on r.thread_id = m.id
  left join thread_mutes tm on tm.thread_id = m.id and tm.user_id = auth.uid()
  left join thread_hides th on th.thread_id = m.id and th.user_id = auth.uid()
  left join lateral (
    select msg.content, msg.created_at, msg.sender_name
    from messages msg where msg.thread_id = m.id
    order by msg.created_at desc limit 1
  ) lm on true
  order by coalesce(lm.created_at, m.created_at) desc;
end; $$;
grant execute on function list_my_threads(uuid) to authenticated;

-- ---- delete_thread: hard-delete a conversation (creator or program owner only) ----
-- Witnessed conversations are NOT deletable — they exist to keep coach↔player messages
-- documented. Archive them instead.
create or replace function delete_thread(p_thread uuid) returns void
language plpgsql security definer set search_path=public as $$
begin
  if exists (select 1 from message_threads t where t.id = p_thread and t.kind = 'witnessed_dm') then
    raise exception 'witnessed conversations cannot be deleted';
  end if;
  if not exists (
    select 1 from message_threads t
    where t.id = p_thread
      and (
        t.created_by = auth.uid()
        or exists (select 1 from programs pr where pr.id = t.program_id and pr.owner_id = auth.uid())
      )
  ) then
    raise exception 'not allowed to delete this thread';
  end if;
  delete from thread_reads        where thread_id = p_thread;
  delete from thread_hides        where thread_id = p_thread;
  delete from thread_mutes        where thread_id = p_thread;
  delete from thread_participants where thread_id = p_thread;
  delete from messages            where thread_id = p_thread;
  delete from message_threads     where id = p_thread;
end; $$;
grant execute on function delete_thread(uuid) to authenticated;

-- SAFETY: delete_thread refuses to delete witnessed conversations (kind = 'witnessed_dm') —
-- those exist to keep a coach↔player conversation documented; archive them instead. Regular DMs,
-- groups and broadcasts can be deleted by the thread creator or the program owner (head coach).
