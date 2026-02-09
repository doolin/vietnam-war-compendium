# Timelines — Indochina / Vietnam War

SVG timelines for the Indochina conflicts. Events come from YAML; the driver renders a horizontal time axis and event labels.

## What’s here

- **`indochina_timeline.rb`** — Main driver. Reads YAML (e.g. `ia-drang-pimlott.yaml`), builds one SVG (letter landscape, 1965–1966). See the big comment block at the top of the file for strategy, coordinate system, axis rules, event boxes, and hover behaviour.
- **`ia-drang-pimlott.yaml`** — Events keyed under `the_war_years` (date + event text). Optional per-event `tier` (0–3) for future LOD; see `LOD_AND_BLOCKS.md`.
- **`blocks.yaml`** — Time-range blocks (id, start, end, label) for future LOD; loaded but not yet rendered. See `LOD_AND_BLOCKS.md`.
- **`LOD_AND_BLOCKS.md`** — Design notes for level-of-detail and blocks (zoom, tiers, block-as-one-box).
- **`ia-drang-timeline.svg`** — Output. Open in a **browser** (not as a static image) for hover: bring event to front and grey highlight.

## Run

```bash
ruby indochina_timeline.rb
```

Writes `ia-drang-timeline.svg` in this directory.

## Format (YAML)

Top-level key: `the_war_years` or `timeline`. Value: list of entries:

```yaml
the_war_years:
  - date: "Nov. 14, 1965"
    event: "1/7th Cavalry assault LZ X-Ray, Ia Drang valley."
```

Dates like `"Oct. 15/16, 1965"` are normalized to the first day. Unparseable entries are skipped. Optional `tier: 0|1|2|3` per event (default 2) for future LOD.

**Blocks** (`blocks.yaml`): top-level `blocks:` array of `id`, `start`, `end` (YYYY-MM-DD), `label`. Loaded by the driver; not yet drawn.