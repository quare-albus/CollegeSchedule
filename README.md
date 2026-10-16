# CCM Menu

A public, single-page browser for the complete CCM weekly mess menu.

## Current release

**v3.1.6 — Shared unique-dish serving defaults**

- The homepage loads all 371 schedule entries from `public."CCM_MENU"`.
- Each schedule entry links to one reusable row in `public."CCM_DISHES"` through `dish_id`.
- The dish library currently contains 99 unique dishes linked to the 371 menu entries.
- Serving choices are Cup, Small bowl, Large bowl, 1 standard rice scoop (kharandi), or Number. Number supports quantities such as 2 bread or 2 eggs.
- Serving defaults are stored once per dish in `CCM_DISHES.default_serving` and `CCM_DISHES.default_quantity`. Editing any occurrence updates the shared dish default and therefore every occurrence on the menu.
- Butter and Jam are excluded from serving tracking.
- The existing `CCM_MENU.serving` column is retained as legacy data for now; the homepage no longer reads or writes it.
- The unique-dish table has nutrition fields ready for future use: `calories`, `protein`, `carbs`, `fat`, `fiber`, and `nutrition_basis`. Values remain blank until entered or verified.
- The embedded 371-entry snapshot is a read-only fallback if Supabase is unavailable; serving controls are disabled in fallback mode.
- Public access can read both tables. Public updates are limited to serving defaults and nutrition fields on `CCM_DISHES`; public menu schedule fields are not writable.
- No Google authentication is required to open the homepage.
- The embedded JSON and `data/ccm_menu.json` are fallback snapshots dated 2026-10-16; the live page uses Supabase whenever the backend is reachable.

## Data model

`CCM_MENU` stores schedule-specific information: weekday, meal, diet category, menu notes, ordering, and `dish_id`.

`CCM_DISHES` stores one row per unique dish, with shared serving defaults and nutrition data. The migration is documented in `supabase/migrations/20261016_normalize_ccm_dishes.sql`.

## Legacy files

The previous timetable, authentication, OCR, and scheduler files are retained in the repository for now, but are not linked from the CCM menu homepage. They have not been deleted or modified as part of this repurpose.

## Versioning rule

Increment the visible version tag with every user-facing release. Keep the homepage version and this release note aligned. Current homepage version: **v3.1.6**.
