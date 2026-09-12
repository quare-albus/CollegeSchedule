# CollegeSchedule

For management of schedules and automating with department training schedules.

## Current release

**v2.6.0 — OCR normalization and validation.**

- PDF pages are rendered locally and sent individually to OCR.space as compressed images.
- OCR.space is called through the `ocrspace-proxy` Supabase Edge Function so the API key stays server-side.
- OCR results are displayed as raw recognition output for traceability.
- OCR text is deterministically normalized into timetable candidate rows.
- Candidate rows are validated for date, time range, ordering, and recognizable timetable content.
- Rows that cannot be safely normalized are explicitly marked **Needs review** rather than silently inventing values.
- Normalized output is displayed in a human-readable timetable table with source page/line and OCR confidence.
- v2.6.0 does **not** persist OCR or normalized results to Supabase.
- Matching, AI review, reconciliation, and V1 modification remain intentionally out of scope for this migration phase.
- The previous v2.4.3 implementation remains in Git history as the fallback.

## Versioning rule

The release version should be updated consistently across user-facing pages, developer tooling, ingestion metadata, backend agents, and documentation whenever a release is changed. Do not report a release as fully version-aligned unless every safely editable location has been checked.
