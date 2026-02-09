# Level of Detail and Blocks — Design Notes

Future direction: all three Indochina wars (~1945–1979), same event granularity (daily or multiple per day), with LOD and temporal blocks. This doc captures the analysis for future reference.

---

## 1. Scale and the core problem

- **1945–1979** ≈ 34 years; **daily (or sub-daily) granularity** over that span.
- At that density we can’t draw every event at once and keep it readable.
- So the system needs:
  - **LOD**: which events/shapes to show at a given “zoom” (time span).
  - **Blocks**: some ranges (e.g. “Ia Drang”) to appear as **one** unit when zoomed out and as many events when zoomed in.
  - **Navigation**: a notion of “visible time window” (and eventually pan/zoom).

---

## 2. “Zoom” as visible time span

Define zoom by **how much time is on screen**, not by pixels:

- **Zoomed out**: e.g. 1945–1979 (whole span) or 10 years.
- **Zoomed in**: e.g. one year, one month, one day.

Then:

- **Axis ticks** depend on that span (e.g. 5-year ticks when span = 34y; month ticks when span = 1y; day ticks when span = 1 month).
- **What’s drawn** (events vs blocks, and which events) depends on the same span.

So the central parameter is: **visible time range** = `[t_start, t_end]` (or center + span). Everything else (LOD, blocks, ticks) can be derived from that.

---

## 3. Level of detail (LOD)

Give each **event** a “when do I show?” rule. Two equivalent ways to say it:

- **Tier**: e.g. 0 = overview, 1 = year-level, 2 = month-level, 3 = day-level. Show event when “current visible span” is smaller than that tier’s threshold (e.g. tier 0 → span ≤ 34y, tier 3 → span ≤ 1 day).
- **Max visible span**: “Show this event only when the visible time window is at most 6 months wide.”

So when the user is “zoomed out” (e.g. 34 years), only tier-0 (and maybe tier-1) things show; when “zoomed in” to a month, tier-2 and tier-3 events appear. Same data, different visibility by span.

---

## 4. Blocks (e.g. “Ia Drang” as one box)

A **block** is:

- A **time range** `[start, end]`.
- A **label** (e.g. “Ia Drang”).
- Optionally: the set of **events** that “live inside” it (or a pointer to a source: file, section id, etc.).

**Rendering rules:**

- **Zoomed out** (visible span large): draw the **block** as one shape (e.g. one rect from `date_to_x(start)` to `date_to_x(end)` with the label). Do **not** draw the individual events inside it (or draw a much smaller subset).
- **Zoomed in** (visible span small): draw the **events** inside that range; the block can be a light background or omitted so it doesn’t duplicate the events.

So “Ia Drang” is one box when the view is 1945–1979, and becomes the familiar per-day events when the view is e.g. Nov 1965 or a few days.

---

## 5. Data shape (so we can grow into this)

**Events** (already have `date`, `label`). Add:

- Optional **`tier`** (or **`max_visible_span`**): when to show this event.
- Optional **`block_id`**: which block this event belongs to (so we know “when this block is expanded, show these events”).

**Blocks** (new):

- `id`, `start_date`, `end_date`, `label`.
- Optional: `event_source` (path to YAML or section) or inline `events[]`. So the current Ia Drang YAML could be “the events for block ia_drang”.

**Timeline config:**

- Overall **time bounds** (e.g. 1945–1979).
- Optional **default view** (e.g. start with 1965–1966 so current behaviour is unchanged).

---

## 6. Incremental steps (summary)

1. **Data only** (this step): Add `tier` to events (parser); add blocks structure and loader. No rendering changes.
2. **Next**: Draw one block (e.g. Ia Drang) as a single rect; optionally place blocks in a band so they don’t overlap events.
3. **Then**: Viewport + zoom (visible time range); axis ticks by span; filter events/blocks by LOD.

---

## 7. Reference: “data first” implementation (done)

- **Events**: In YAML, optional `tier: 0|1|2|3`; default 2 (see `DEFAULT_TIER`). Parser exposes `:tier` on each event hash. Rendering ignores tier for now.
- **Blocks**: `blocks.yaml` has top-level `blocks:` array of `{ id:, start:, end:, label: }` (start/end as YYYY-MM-DD). `Blocks.load(BLOCKS_FILE)` returns `[{ id:, start_date:, end_date:, label: }]`. Main loads blocks but does not pass them to the renderer.
- **Renderer**: Unchanged; still draws all events. Tier and blocks are available for the next step (draw blocks, then viewport + LOD filtering).
