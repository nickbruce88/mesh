-- Mesh — Phase 3e: server-side per-day practice plans
-- Supabase project zsjxauwwqyyhgxzgnfoj. Run in the SQL editor. Idempotent; safe to re-run.
--
-- Until now a day's practice plan lived only in memory (DAY_GRIDS) and was lost on reload.
-- v40.11 reworked it into a structured JSON model (serializePracticeDay/renderPracticeDay);
-- this migration persists that model per program + calendar date so it survives reloads and
-- is shared across the staff.
--
-- Keyed by the ABSOLUTE practice_date (not the app's relative week offset), so "Tuesday" this
-- week and next week are distinct rows.
--
-- The plan jsonb carries BOTH practice modes in one row: detailed = {version,start,periods:[…]},
-- simple = {version,mode:'simple',blocks:[…]}. A plan with neither periods nor blocks deletes
-- the row. (v40.13 added simple-mode support — re-run this file to update save_practice_day.)
--
-- Depends on: programs(id, owner_id), profiles(id, program_id, role).
-- ===========================================================================================

create table if not exists practice_days (
  program_id    uuid not null references programs(id) on delete cascade,
  practice_date date not null,
  plan          jsonb not null,
  updated_at    timestamptz not null default now(),
  updated_by    uuid,
  primary key (program_id, practice_date)
);
create index if not exists idx_practice_days_program on practice_days(program_id);

alter table practice_days enable row level security;
-- Only the SECURITY DEFINER functions below touch this table; block direct client access.
drop policy if exists practice_days_none on practice_days;
create policy practice_days_none on practice_days for all using (false) with check (false);

-- ---- Is the caller a coach (head or assistant) on this program? ----
-- Fine-grained per-feature practice-edit access stays a client-side gate (canEdit('practice'));
-- the server boundary that matters is coach-vs-player/parent.
create or replace function _is_program_coach(p_program_id uuid)
returns boolean language sql security definer set search_path=public as $$
  select
    exists(select 1 from programs   pr where pr.id = p_program_id and pr.owner_id = auth.uid())
    or exists(select 1 from profiles p  where p.id = auth.uid() and p.program_id = p_program_id and p.role = 'coach');
$$;

-- ---- Is the caller any member of this program (coach / player / parent)? ----
create or replace function _is_program_member(p_program_id uuid)
returns boolean language sql security definer set search_path=public as $$
  select
    exists(select 1 from programs   pr where pr.id = p_program_id and pr.owner_id = auth.uid())
    or exists(select 1 from profiles p  where p.id = auth.uid() and p.program_id = p_program_id);
$$;

-- ---- Save (upsert) one day's plan. Empty plan (no periods) deletes the row. ----
create or replace function save_practice_day(p_program_id uuid, p_date date, p_plan jsonb)
returns void language plpgsql security definer set search_path=public as $$
begin
  if not _is_program_coach(p_program_id) then
    raise exception 'Only coaches can edit the practice plan';
  end if;

  -- Empty plan = no detailed periods AND no simple blocks → remove the row.
  if p_plan is null
     or (coalesce(jsonb_array_length(p_plan->'periods'), 0) = 0
         and coalesce(jsonb_array_length(p_plan->'blocks'), 0) = 0) then
    delete from practice_days where program_id = p_program_id and practice_date = p_date;
    return;
  end if;

  insert into practice_days(program_id, practice_date, plan, updated_at, updated_by)
  values (p_program_id, p_date, p_plan, now(), auth.uid())
  on conflict (program_id, practice_date)
  do update set plan = excluded.plan, updated_at = now(), updated_by = auth.uid();
end; $$;
grant execute on function save_practice_day(uuid, date, jsonb) to authenticated;

-- ---- Fetch a date range of days (a week) for hydration. Any program member may read. ----
create or replace function get_practice_days(p_program_id uuid, p_from date, p_to date)
returns table (practice_date date, plan jsonb)
language plpgsql security definer set search_path=public as $$
begin
  if not _is_program_member(p_program_id) then
    raise exception 'Not authorized';
  end if;
  return query
    select pd.practice_date, pd.plan
    from practice_days pd
    where pd.program_id = p_program_id
      and pd.practice_date between p_from and p_to;
end; $$;
grant execute on function get_practice_days(uuid, date, date) to authenticated;

-- ===========================================================================================
-- Verify (optional):
--   select save_practice_day('<program-id>', current_date, '{"version":1,"periods":[{"id":"P1"}]}'::jsonb);
--   select * from get_practice_days('<program-id>', current_date - 7, current_date + 7);
--   select save_practice_day('<program-id>', current_date, '{"version":1,"periods":[]}'::jsonb);  -- deletes it
-- ===========================================================================================
