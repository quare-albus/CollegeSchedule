-- CollegeSchedule V2.2: RLS policies
-- Read/write access is restricted to authenticated users.

create policy "authenticated_read_departments" on public.departments for select to authenticated using (true);
create policy "authenticated_read_department_schedules" on public.department_schedules for select to authenticated using (true);
create policy "authenticated_read_department_classes" on public.department_classes for select to authenticated using (true);
create policy "authenticated_read_v1_classes" on public.v1_classes for select to authenticated using (true);
create policy "authenticated_read_schedule_matches" on public.schedule_matches for select to authenticated using (true);
create policy "authenticated_read_ingestion_runs" on public.schedule_ingestion_runs for select to authenticated using (true);

create policy "authenticated_write_departments" on public.departments for all to authenticated using (true) with check (true);
create policy "authenticated_write_department_schedules" on public.department_schedules for all to authenticated using (true) with check (true);
create policy "authenticated_write_department_classes" on public.department_classes for all to authenticated using (true) with check (true);
create policy "authenticated_write_v1_classes" on public.v1_classes for all to authenticated using (true) with check (true);
create policy "authenticated_write_schedule_matches" on public.schedule_matches for all to authenticated using (true) with check (true);
create policy "authenticated_write_ingestion_runs" on public.schedule_ingestion_runs for all to authenticated using (true) with check (true);
