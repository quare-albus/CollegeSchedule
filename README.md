# CollegeSchedule

For management of schedules and automating with department training schedules.

## Current release

**v2.5.0 — OCR migration (PDF recognition only).**

- PDF input is automatically split into OCR.space-compatible chunks.
- OCR.space is called through the `ocrspace-proxy` Supabase Edge Function so the API key stays server-side.
- OCR results are recombined and displayed on GitHub Pages.
- v2.5.0 does **not** persist OCR results to Supabase.
- Matching, AI review, reconciliation, and V1 modification are intentionally out of scope.
- The previous v2.4.3 implementation remains in Git history as the fallback.

## Versioning rule

The release version should be updated consistently across user-facing pages, developer tooling, ingestion metadata, backend agents, and documentation whenever a release is changed. Do not report a release as fully version-aligned unless every safely editable location has been checked.
