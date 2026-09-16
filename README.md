# CollegeSchedule

For management of schedules and automating with department training schedules.

## Student authentication

- `auth.html` is the student sign-in and onboarding page.
- Students sign in with Google through Supabase Auth.
- A matching `public.users` row is created automatically by the Supabase Auth trigger.
- The student then saves exactly one CollegeSchedule-specific field: `roll_no`.
- The browser uses the Supabase publishable key only. No service-role or secret key is exposed.

## Current release

**v2.9.2 — OCR table-header reconstruction fix.**

- PDF pages are rendered locally and sent individually to OCR.space as compressed images.
- Generated page JPEGs are kept below the OCR.space Free Plan 1.5 MB file-size limit.
- OCR.space is called through the `ocrspace-proxy` Supabase Edge Function so the API key stays server-side.
- OCR results are displayed as raw recognition output for traceability.
- OCR.space word-level overlay coordinates are used to reconstruct the source table's visual columns.
- The source visual `Topic` column is mapped to class type (`Theory`, `SDL`, `Tutorials`, `Clinics`), while `SLO` is mapped to the actual topic.
- Instructor values are taken only from the source `Instructor` column; wrapped lines inherit their visual column.
- v2.9.2 fixes a reconstruction failure caused by requiring all seven table headers to occur on one OCR line. Headers are now located independently in the upper page region and their x-coordinates are used to recover column boundaries.
- Candidate rows are validated for date, time range, ordering, and recognizable timetable content.
- Rows that cannot be safely normalized are explicitly marked **Needs review** rather than silently inventing values.
- Normalized output is displayed in a human-readable timetable table with source page/line and OCR confidence.
- v2.9.2 does **not** persist OCR or normalized results to Supabase.
- Matching, AI review, reconciliation, and V1 modification remain intentionally out of scope for this migration phase.
- The previous implementations remain in Git history as fallbacks.

## Versioning rule

The release version should be updated consistently across user-facing pages, developer tooling, ingestion metadata, backend agents, and documentation whenever a release is changed. Do not report a release as fully version-aligned unless every safely editable location has been checked.
