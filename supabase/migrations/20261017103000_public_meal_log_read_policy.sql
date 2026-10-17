-- The public CollegeSchedule nutrition dashboard reads today's logged meals without sign-in.
-- This intentionally makes every row in public.meals readable to website visitors.
create policy "Public can read nutrition logs"
  on public.meals
  for select
  to anon, authenticated
  using (true);
