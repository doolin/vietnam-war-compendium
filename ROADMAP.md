# Vietnam War Compendium — Roadmap

## Current State (March 2026)

- **88 events** across 7 event files, spanning 1945–1975
- **5 Kindle highlight files** (4 fully processed into events, 1 unprocessed)
- **Scraper** operational with army.mil MOH citations cached
- **App** deployed on Lambda with date-based routing and prev/next navigation

## Structural Issues

### ~~1. File extension inconsistency~~
Resolved. All YAML files now use `.yaml`.

### 2. Timeline top-level key naming
Four different conventions across timeline files:
- `the_war_years:` — ia-drang-pimlott.yaml, starlite-pimlott.yaml
- `timeline:` — kindle-highlights-timeline.yaml, vietminh-timeline.yaml
- `Starlite:` — starlite.yaml (stub, see #4)
- `blocks:` — blocks.yaml
- bare array — tet-bigstory.yaml

Pick one and enforce it.

### ~~3. Empty URL strings in book-sourced events~~
Resolved. All book-sourced events now have Goodreads URLs. The process-highlights skill has been updated to use Goodreads as the default book URL.

### 4. starlite.yaml is a stub
`timelines/starlite.yaml` contains only `Starlite:\n  - 1965-08-18:0630 launched`. The real data is in `starlite-pimlott.yaml`. Likely an abandoned draft.

### 5. No seed validation
`db/seed.rb` silently accepts invalid months/days, missing required fields, and empty reference URLs. Only `YAML.safe_load_file` provides basic safety.

### 6. sample.yaml naming is ambiguous
Contains real, curated events (Tet, Ia Drang, Khe Sanh, Rolling Thunder, Fall of Saigon, etc.) — not sample/test data. The name undersells it and may cause confusion about whether it's safe to delete.

## Redundancy

### 7. Two parallel data paths
- **Timelines pipeline**: `kindle-highlights/*.yaml` → `extract_timeline.rb` → `timelines/kindle-highlights-timeline.yaml` → SVG
- **This-day pipeline**: `kindle-highlights/*.yaml` → manual/skill extraction → `this-day/data/events/*.yaml` → SQLite

Both consume the same highlights but produce different formats with no shared intermediate step. Fine for now but worth noting.

### 8. Highlight metadata unused downstream
`quality`, `tags`, and `status` fields in kindle-highlights are only used during processing — the event pipeline discards them entirely.

## Content Pipeline

### Unprocessed highlights
- `kindle-highlights/war-for-ho-chi-minh-trail.yaml` — 12 highlights, no dates/tags/quality scored yet. Mostly analytical/background passages about the Trail network.

### MOH bulk extraction
- army.mil A-L and M-Z pages cached in `scraper/cache/`. Parser extracts ~260 recipients with dates, units, locations, citations. Two Marine events created as proof of concept. Remainder available for bulk extraction.

## Priorities

1. ~~Fix empty URLs~~ — resolved, all events now have Goodreads or source URLs
2. Rename `sample.yaml` to something descriptive (e.g., `landmark-events.yaml`)
3. Delete `starlite.yaml` stub
4. Pick one timeline key and enforce it
5. Add basic validation to `seed.rb` (required fields, valid date ranges)
6. Process remaining MOH citations into events (bulk extraction)
7. Process `war-for-ho-chi-minh-trail.yaml` highlights

## Scraper Infrastructure

A polite web scraper (`scraper/`) is in place for acquiring events from public domain government sources:

- **`scraper/lib/polite_fetcher.rb`** — per-domain rate limiting, parallel across domains, local HTML cache
- **`scraper/fetch.rb`** — CLI entry point for fetching and caching pages
- **`scraper/parsers/moh_army_mil.rb`** — parser for army.mil Medal of Honor citation pages (A-L and M-Z cached)
- **`scraper/parsers/moh_navy.rb`** — parser stub for Navy History site (blocked by SSL cert issue)
- **`scraper/cache/`** — gitignored; raw HTML cached locally to avoid re-fetching

### Active sources
- army.mil MOH citations: ~260 Vietnam War recipients with exact dates, units, locations, and full citation narratives.

### Future sources
- Navy History MOH pages (needs SSL workaround or curl-based fetch)
- VVMF Wall of Faces
- FRUS document collections
- Pentagon Papers

## Two Goals the Data Supports

### Timelines
SVG timeline visualizations generated from YAML data in `timelines/`. Supports level-of-detail tiers (0-3) and time-range blocks for zoom-based rendering.

### This Day in Viet Nam
Daily history page served by a Roda app on AWS Lambda with bundled SQLite3. Events sourced from `this-day/data/events/*.yaml`, built into the database via `rake db:build`, deployed via `rake deploy:all`. Date-based routing at `/this-day-in-vietnam-war/:month/:day` with prev/next day navigation.
