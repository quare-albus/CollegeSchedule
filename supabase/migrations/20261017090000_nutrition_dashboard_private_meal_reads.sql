-- Private read access for the CollegeSchedule nutrition dashboard.
-- Telegram-originated records remain hidden until a verified account-linking flow
-- maps the Telegram user ID to the signed-in Supabase Auth user.
create index if not exists meals_user_id_logged_at_idx
  on public.meals (user_id, logged_at desc);

drop policy if exists "Users can read their own nutrition logs" on public.meals;
create policy "Users can read their own nutrition logs"
  on public.meals
  for select
  to authenticated
  using ((select auth.uid())::text = user_id);
