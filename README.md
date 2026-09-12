# CollegeSchedule

For management of schedules and automating with department training schedules.

## Current release

**v2.4.3** — page-chunked structured schedule ingestion with parser fallback.

- V1 remains authoritative.
- Structured ingestion is separate from V1 reconciliation.
- PDFs are processed page-by-page to reduce parser-size failures.
- Image files use structured image extraction.
- CSV files are parsed locally without an LLM.
- Ambiguous reconciliation remains downstream of structured extraction.

## Versioning rule

The release version should be updated consistently across user-facing pages, developer tooling, ingestion metadata, backend agents, and documentation whenever a release is changed. Do not report a release as fully version-aligned unless every safely editable location has been checked.
