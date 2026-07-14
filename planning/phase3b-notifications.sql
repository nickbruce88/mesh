-- Mesh — Phase 3b: hide/archive threads + server-side notification prefs & per-thread mute
-- Supabase project zsjxauwwqyyhgxzgnfoj. Run this whole block in the SQL editor. Idempotent.
-- RLS is already ON for messaging tables; these personal tables get own-row RLS too.

-- ---- Personal per-user tables ----
create table if not exists thread_hides (
  user_id   uuid not null,
  thread_id uuid not null references message_threads(id) on delete cascade,
  hidden_at timestamptz not null default now(),
  primary key (user_id, thread_id)
);
create table if not exists thread_mutes (
  user_id   uuid not null,
  thread_id uuid not null references message_threads(id) on delete cascade,
  primary key (user_id, thread_id)
);
create table if not exists notification_prefs (
  user_id uuid primary key,
  prefs   jsonb not null default '{}'::jsonb   -- e.g. {"messages":false,"games":true,...}
);

alter table thread_hides       enable row level security;
alter table thread_mutes       enable row level security;
alter table notification_prefs enable row level security;

drop policy if exists th_own on thread_hides;
create policy th_own on thread_hides       for all using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists tmute_own on thread_mutes;
create policy tmute_own on thread_mutes    for all using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists np_own on notification_prefs;
create policy np_own on notification_prefs for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---- RPCs (SECURITY DEFINER; act on the caller's own rows) ----
create or replace function hide_thread(p_thread uuid) returns void
language sql security definer set search_path=public as $$
  insert into thread_hides(user_id, thread_id, hidden_at)
  values (auth.uid(), p_thread, now())
  on conflict (user_id, thread_id) do update set hidden_at = now();
$$;
grant execute on function hide_thread(uuid) to authenticated;

create or replace function unhide_thread(p_thread uuid) returns void
language sql security definer set search_path=public as $$
  delete from thread_hides where user_id = auth.uid() and thread_id = p_thread;
$$;
grant execute on function unhide_thread(uuid) to authenticated;

create or replace function set_thread_mute(p_thread uuid, p_muted boolean) returns void
language plpgsql security definer set search_path=public as $$
begin
  if p_muted then
    insert into thread_mutes(user_id, thread_id) values (auth.uid(), p_thread)
    on conflict (user_id, thread_id) do nothing;
  else
    delete from thread_mutes where user_id = auth.uid() and thread_id = p_thread;
  end if;
end; $$;
grant execute on function set_thread_mute(uuid, boolean) to authenticated;

create or replace function set_notification_prefs(p_prefs jsonb) returns void
language sql security definer set search_path=public as $$
  insert into notification_prefs(user_id, prefs) values (auth.uid(), coalesce(p_prefs,'{}'::jsonb))
  on conflict (user_id) do update set prefs = excluded.prefs;
$$;
grant execute on function set_notification_prefs(jsonb) to authenticated;

create or replace function get_notification_prefs() returns jsonb
language sql security definer set search_path=public as $$
  select coalesce((select prefs from notification_prefs where user_id = auth.uid()), '{}'::jsonb);
$$;
grant execute on function get_notification_prefs() to authenticated;

-- ---- Upgrade list_my_threads to return muted + archived (drop needed: return type changes) ----
drop function if exists list_my_threads(uuid);
create function list_my_threads(p_program_id uuid)
returns table (
  id uuid, kind text, subject text, audience_roles text[], created_by uuid,
  last_content text, last_at timestamptz, last_sender text, participant_count int,
  muted boolean, archived boolean
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
         (select count(*)::int from thread_participants tp where tp.thread_id = m.id),
         (tm.user_id is not null) as muted,
         (
           -- archived if manually hidden with no newer message, OR quiet for > 6 months
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
