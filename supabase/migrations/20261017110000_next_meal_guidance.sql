-- Store the latest expected intake for the next meal so the public dashboard
-- can display the same guidance that the Telegram bot calculates.
create table if not exists public.next_meal_guidance (
  id smallint primary key default 1 check (id = 1),
  meal_date date not null default ((now() at time zone 'Asia/Kolkata')::date),
  updated_at timestamptz not null default now(),
  logged_meal text not null,
  next_meal text not null,
  message text not null,
  calories_consumed numeric not null default 0,
  protein_consumed numeric not null default 0,
  carbs_consumed numeric not null default 0,
  fat_consumed numeric not null default 0,
  fiber_consumed numeric not null default 0,
  calories_target numeric not null default 4440,
  protein_target numeric not null default 140,
  carbs_target numeric not null default 632,
  fat_target numeric not null default 150,
  fiber_target numeric not null default 30,
  next_calories numeric not null default 0,
  next_protein numeric not null default 0,
  next_carbs numeric not null default 0,
  next_fat numeric not null default 0,
  next_fiber numeric not null default 0
);

alter table public.next_meal_guidance enable row level security;
drop policy if exists "Public can read next meal guidance" on public.next_meal_guidance;
create policy "Public can read next meal guidance"
  on public.next_meal_guidance for select to anon, authenticated using (true);
grant select on public.next_meal_guidance to anon, authenticated;
