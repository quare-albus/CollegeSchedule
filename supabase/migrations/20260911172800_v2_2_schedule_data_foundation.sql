-- CollegeSchedule V2.2: Supabase data foundation
-- Applied to Supabase project: igdzpwckufwctxixqpjj

create table public.departments (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  code text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (name)
);

create table public.department_schedules (
  id uuid primary key default gen_random_uuid(),
  department_id uuid not null references public.departments(id) on delete cascade,
  academic_program text not null,
  academic_term text not null,
  batch text,
  week_start date,
  week_end date,
  source_file text not null,
  source_type text not null check (source_type in ('pdf','image','spreadsheet','document','other')),
  uploaded_at timestamptz not null default now(),
  status text not null default 'UPLOADED' check (status in ('UPLOADED','PROCESSING','EXTRACTED','FAILED','ARCHIVED')),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.department_classes (
  id uuid primary key default gen_random_uuid(),
  schedule_id uuid not null references public.department_schedules(id) on delete cascade,
  department_id uuid not null references public.departments(id) on delete cascade,
  class_date date,
  day text,
  start_time time,
  end_time time,
  session_type text,
  subject text,
  topic text,
  faculty text,
  venue text,
  batch text,
  raw_text text,
  confidence numeric(5,4) check (confidence is null or (confidence >= 0 and confidence <= 1)),
  extraction_status text not null default 'EXTRACTED' check (extraction_status in ('EXTRACTED','NEEDS_REVIEW','REJECTED')),
  extraction_metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (end_time is null or start_time is null or end_time > start_time)
);

create table public.v1_classes (
  id uuid primary key default gen_random_uuid(),
  academic_program text not null,
  academic_term text not null,
  class_date date,
  day text,
  start_time time not null,
  end_time time not null,
  session_type text,
  subject text,
  batch text,
  occurrence_rule text,
  source_reference text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (end_time > start_time)
);

create table public.schedule_matches (
  id uuid primary key default gen_random_uuid(),
  v1_class_id uuid not null references public.v1_classes(id) on delete cascade,
  department_class_id uuid references public.department_classes(id) on delete set null,
  match_status text not null default 'PENDING_REVIEW' check (match_status in ('MATCHED','MISMATCH','NO_MATCH','AMBIGUOUS','PENDING_REVIEW')),
  match_score numeric(5,4) check (match_score is null or (match_score >= 0 and match_score <= 1)),
  match_method text check (match_method is null or match_method in ('DETERMINISTIC','AI','HUMAN')),
  review_required boolean not null default false,
  reviewer_note text,
  evidence jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (v1_class_id, department_class_id)
);

create table public.schedule_ingestion_runs (
  id uuid primary key default gen_random_uuid(),
  schedule_id uuid not null references public.department_schedules(id) on delete cascade,
  status text not null default 'PENDING' check (status in ('PENDING','RUNNING','COMPLETED','FAILED')),
  extractor_version text,
  files_count integer not null default 1 check (files_count > 0),
  classes_extracted integer not null default 0 check (classes_extracted >= 0),
  error_message text,
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

create index department_schedules_department_idx on public.department_schedules(department_id);
create index department_schedules_term_idx on public.department_schedules(academic_program, academic_term);
create index department_classes_schedule_idx on public.department_classes(schedule_id);
create index department_classes_date_time_idx on public.department_classes(class_date, start_time, end_time);
create index department_classes_subject_idx on public.department_classes(subject);
create index department_classes_batch_idx on public.department_classes(batch);
create index v1_classes_date_time_idx on public.v1_classes(class_date, start_time, end_time);
create index v1_classes_program_term_idx on public.v1_classes(academic_program, academic_term);
create index schedule_matches_status_idx on public.schedule_matches(match_status, review_required);
create index schedule_ingestion_runs_schedule_idx on public.schedule_ingestion_runs(schedule_id);

alter table public.departments enable row level security;
alter table public.department_schedules enable row level security;
alter table public.department_classes enable row level security;
alter table public.v1_classes enable row level security;
alter table public.schedule_matches enable row level security;
alter table public.schedule_ingestion_runs enable row level security;

comment on table public.departments is 'Department registry for CollegeSchedule department-issued schedules.';
comment on table public.department_schedules is 'Uploaded department schedule sources and academic context. Source evidence is retained; it does not replace V1.';
comment on table public.department_classes is 'Structured classes extracted from department schedules, including topic, faculty/teacher, and venue when present.';
comment on table public.v1_classes is 'Authoritative V1 timetable skeleton used as the expected schedule for reconciliation.';
comment on table public.schedule_matches is 'Audit trail linking extracted department classes to authoritative V1 classes.';
comment on table public.schedule_ingestion_runs is 'Processing history for schedule extraction runs.';
