# CCM Menu

A public, single-page browser for the complete CCM weekly mess menu.

## Current release

**v3.0.1 — Self-contained menu data fix**

- The homepage lists all 371 records from the HealthOS `public."CCM_MENU"` table snapshot.
- Browse Monday through Sunday, with breakfast, lunch, and dinner grouped into the source's VEG and NON-VEG categories.
- Search by dish, day, meal, category, or menu note.
- Filter by day, meal, and category; reset filters or print the page.
- No Google authentication is required to open the homepage.
- The page is static and read-only. It does not call Supabase at runtime or write to any database.
- v3.0.1 embeds the same 371-entry snapshot inside the homepage HTML, so the page does not depend on a second network request to load menu data.
- Menu records are stored in `data/ccm_menu.json`. This is a snapshot taken on 2026-10-16; refreshing the Supabase table does not automatically update the website data.

## Legacy files

The previous timetable, authentication, OCR, and scheduler files are retained in the repository for now, but are not linked from the CCM menu homepage. They have not been deleted or modified as part of this repurpose.

## Versioning rule

Increment the visible version tag with every user-facing release. Keep the homepage version and this release note aligned. Current homepage version: **v3.0.0**.
