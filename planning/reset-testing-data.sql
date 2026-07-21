-- ============================================================================================
-- Mesh — RESET TESTING DATA (clean slate for a fresh program)
-- Supabase project zsjxauwwqyyhgxzgnfoj. Run in the SQL editor.
--
-- ⚠️  DESTRUCTIVE + IRREVERSIBLE. Deletes ALL coach-entered / user data:
--     programs (with their drills, practice plans, schedule, announcements),
--     rosters, parent links, stats, performance, attendance, inventory,
--     practice_days, every message + thread, notification tokens/prefs, avatars,
--     and TOS acceptances.
--
-- ✅  KEEPS the app itself intact: all tables, RLS, functions, plus the two config
--     tables `beta_codes` (your signup gate) and `stat_categories` (stat-type list).
--     Storage FILES (uploaded avatar images / documents) are left as-is — they're
--     orphaned + harmless; clear them from Storage in the dashboard if you want.
--
-- Only run this because you're the sole tester and want a full clean sweep.
-- ============================================================================================

-- STEP 1 — wipe all app data (skips any table that doesn't exist; ordered child → parent).
do $$
declare t text;
begin
  foreach t in array array[
    -- messaging (children first)
    'thread_reads','thread_hides','thread_mutes','thread_participants','messages','message_threads',
    -- notifications
    'notification_prefs','notification_tokens',
    -- per-program data
    'game_stats','performance','attendance','inventory','practice_days','parent_links',
    'avatars','tos_acceptances',
    -- roster + accounts profile rows
    'players','profiles',
    -- root
    'programs'
  ] loop
    if to_regclass('public.'||t) is not null then
      execute 'delete from public.'||quote_ident(t);
      raise notice 'cleared %', t;
    end if;
  end loop;
end $$;

-- Verify STEP 1 (each should be 0; beta_codes / stat_categories should still have rows):
--   select 'programs', count(*) from programs
--   union all select 'profiles', count(*) from profiles
--   union all select 'players',  count(*) from players
--   union all select 'beta_codes(keep)', count(*) from beta_codes
--   union all select 'stat_categories(keep)', count(*) from stat_categories;

-- ============================================================================================
-- STEP 2 — remove the login accounts so you can re-register the roles fresh.
--
-- ⚠️  This deletes EVERY auth user, INCLUDING your own dev/coach login. You'll create new
--     accounts when you onboard the new program. Skip this whole step if you'd rather reuse
--     your existing logins.
--
-- If the SQL below is blocked in your project, do it in the dashboard instead:
--   Authentication → Users → select all → Delete user(s).
-- ============================================================================================

-- delete from auth.users;   -- ← uncomment to run

-- ============================================================================================
-- STEP 3 (in the browser, not here) — clear the app's cached session so it forgets the old
-- program. Open the app, then in the browser console (or just fully sign out) run:
--
--   Object.keys(localStorage).filter(k=>k.startsWith('mesh_')).forEach(k=>localStorage.removeItem(k)); location.reload();
--
-- Then create your new program and start testing top to bottom.
-- ============================================================================================
