# CCM Menu

A public, single-page browser for the complete CCM weekly mess menu.

## Current release

**v3.1.1 — Live serving selectors**

- The homepage loads all 371 current records from the HealthOS `public."CCM_MENU"` table.
- Browse Monday through Sunday, with breakfast, lunch, and dinner grouped into the source's VEG and NON-VEG categories.
- Search by dish, day, meal, category, or menu note.
- Filter by day, meal, and category; reset filters or print the page.
- No Google authentication is required to open the homepage.
- The homepage loads the current 371 menu records from Supabase and displays a serving selector beside every dish.
- Each serving selector offers Cup, Small bowl, Large bowl, or 1 standard rice scoop (kharandi); changes are saved immediately to the `serving` column in `public."CCM_MENU"`.
- Initial serving values are heuristic guesses and should be corrected from the page where needed.
- The embedded 371-entry snapshot is a read-only fallback if Supabase is unavailable; serving controls are disabled in fallback mode.
- Row-level security allows public menu reads and updates to the `serving` column only; other menu columns are not granted to public update access.
- `data/ccm_menu.json` and the embedded JSON are read-only fallback snapshots from 2026-10-16; the live page uses Supabase whenever the backend is reachable.

## Legacy files

The previous timetable, authentication, OCR, and scheduler files are retained in the repository for now, but are not linked from the CCM menu homepage. They have not been deleted or modified as part of this repurpose.

## Versioning rule

Increment the visible version tag with every user-facing release. Keep the homepage version and this release note aligned. Current homepage version: **v3.1.1**.
