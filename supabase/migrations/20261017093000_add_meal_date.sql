-- Keep meal date separate from the time a record is entered.
-- This allows a meal entered shortly after midnight to be assigned to the prior day.
alter table public.meals
  add column if not exists meal_date date;

alter table public.meals
  alter column meal_date
  set default ((now() at time zone 'Asia/Kolkata')::date);

update public.meals
set meal_date = (logged_at at time zone 'Asia/Kolkata')::date
where meal_date is null;

-- Record 29 was entered just after midnight but represents the previous day's dinner.
update public.meals
set meal_date = date '2026-10-16'
where id = 29
  and meal ilike 'Dinner:%';

alter table public.meals
  alter column meal_date set not null;

create index if not exists meals_meal_date_idx
  on public.meals (meal_date, logged_at desc);
