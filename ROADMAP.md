# Vietnam War Compendium — Roadmap

## Structural Issues

### ~~1. File extension inconsistency~~
Resolved. All YAML files now use `.yaml`.

### 2. Timeline top-level key naming
- Three files use `the_war_years:`, two use `timeline:`. The Ruby driver has to handle both. Pick one and enforce it.

### 3. Empty URL strings in dereliction-of-duty.yaml
- All 31 events have `url: ""` instead of null. These render as `<a href="">` — broken links that reload the current page.

### 4. starlite.yaml is a stub
- Contains only `Starlite:\n  - 1965-08-18:0630 launched`. The real data is in `starlite-pimlott.yaml`. Likely an abandoned draft.

### 5. No seed validation
- `db/seed.rb` silently accepts invalid months/days, missing required fields, and empty reference URLs.

### 6. sample.yaml naming is ambiguous
- Contains real, curated events (Tet, Ia Drang, Khe Sanh, etc.) — not sample/test data. The name undersells it and may cause confusion about whether it's safe to delete.

## Redundancy

### 7. Two parallel data paths
- **Timelines pipeline**: `kindle-highlights/*.yaml` → `extract_timeline.rb` → `timelines/kindle-highlights-timeline.yaml` → SVG
- **This-day pipeline**: `kindle-highlights/*.yaml` → manual/skill extraction → `this-day/data/events/*.yaml` → SQLite

Both consume the same highlights but produce different formats with no shared intermediate step. Fine for now but worth noting.

### 8. Highlight metadata unused downstream
- `quality`, `tags`, and `status` fields in kindle-highlights are only used during processing — the event pipeline discards them entirely.

## Priorities

1. Fix the empty URLs — either null them out or remove the `url` field from references that lack one
2. Rename `sample.yaml` to something descriptive (e.g., by source)
3. Delete `starlite.yaml` stub
4. Pick one timeline key (`timeline:` vs `the_war_years:`)
5. Add basic validation to `seed.rb` (required fields, valid date ranges)

## Scraper Infrastructure

A polite web scraper (`scraper/`) is in place for acquiring events from public domain government sources:

- **`scraper/lib/polite_fetcher.rb`** — per-domain rate limiting, parallel across domains, local HTML cache
- **`scraper/fetch.rb`** — CLI entry point for fetching and caching pages
- **`scraper/parsers/moh_army_mil.rb`** — parser for army.mil Medal of Honor citation pages (A-L and M-Z cached)
- **`scraper/parsers/moh_navy.rb`** — parser stub for Navy History site (blocked by SSL cert issue)
- **`scraper/cache/`** — gitignored; raw HTML cached locally to avoid re-fetching

### Active sources
- army.mil MOH citations: ~260 Vietnam War recipients with exact dates, units, locations, and full citation narratives. Two Marine events created as proof of concept; remainder available for bulk extraction.

### Future sources
- Navy History MOH pages (needs SSL workaround)
- VVMF Wall of Faces
- FRUS document collections
- Pentagon Papers

## Two Goals the Data Supports

### Timelines
SVG timeline visualizations generated from YAML data in `timelines/`. Supports level-of-detail tiers (0-3) and time-range blocks for zoom-based rendering.

### This Day in Viet Nam
Daily history page served by a Roda app on AWS Lambda with bundled SQLite3. Events sourced from `this-day/data/events/*.yaml`, built into the database via `rake db:build`, deployed via `rake deploy:all`.
