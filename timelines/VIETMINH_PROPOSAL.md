# Proposal: Incorporating the Vietminh Timeline

The **vietminh-timeline.yaml** has 12 events from **May 1941** (formation of Viet Minh) through **July 1954** (Geneva Accords, end of First Indochina War). The current script only draws **1965–1966**; Vietminh events would fall entirely before the visible axis. Below are three ways to incorporate them.

---

## Option A (recommended): Single long timeline 1941–1966

**Idea:** One axis from Viet Minh formation through the current Ia Drang/Starlite window. All events (Vietminh + Starlite + Ia Drang) on the same scale.

**Changes:**

1. **Constants**
   - `START_YEAR = 1941`, `END_YEAR = 1966` (or keep 1966 and set start to 1941).
   - Add `VIETMINH_FILE = File.join(__dir__, "vietminh-timeline.yaml")`.

2. **Loading**
   - In `main`, load Vietminh and merge with existing sources:
     ```ruby
     events = Events.load(VIETMINH_FILE) + Events.load(DATA_FILE) + Events.load(STARLITE_FILE)
     events = events.sort_by { |e| e[:date] }
     ```

3. **Blocks**
   - In **blocks.yaml**, add a Vietminh / First Indochina block:
     ```yaml
     - id: vietminh
       start: "1941-05-10"
       end: "1954-07-21"
       label: "First Indochina / Viet Minh"
     ```
   - Add CSS in the script for `.block-vietminh` (fill/stroke) and for `.event-group.block-vietminh .event-box` (lighter default, darker hover), same pattern as Starlite/Ia Drang.

4. **Axis**
   - Span is now ~25 years. Options:
     - **Year ticks every 5 years:** 1945, 1950, 1955, 1960, 1965, plus optional 1941 and 1966 at ends. Avoids crowding.
     - Or every 2–3 years if you want more granularity.
   - **Month ticks:** Either omit them for the long timeline, or keep them only for 1965–1966 (e.g. only if year ≥ 1965) so the right side stays readable.

5. **Output**
   - Consider renaming output to something like `indochina-timeline.svg` so it’s clearly the full story, or keep `ia-drang-timeline.svg` if that remains the primary use.

**Pros:** One narrative, one file; blocks (Vietminh, Starlite, Ia Drang) show the three phases clearly.  
**Cons:** 1965–1966 is compressed into a small right portion; event boxes may overlap unless row layout or LOD is adjusted.

---

## Option B: Two time bands in one SVG

**Idea:** Keep the main axis at 1965–1966; add a second horizontal band (e.g. above) for 1941–1954 with its own scale. Only Vietminh events go in the top band.

**Changes:**

- Introduce a second axis (different `axis_y`, shorter or same width) and a second `date_to_x` range (1941–1954).
- Draw Vietminh events in that band; Starlite/Ia Drang stay on the 1965–1966 band.
- Optionally a single “Vietminh” block bar in the top band.
- Axis labels: e.g. “1941 – 1954” and “1965 – 1966” so the two scales are obvious.

**Pros:** 1965–1966 keeps full resolution; Vietminh gets its own readable scale.  
**Cons:** Two scales to maintain; more layout and code (two `add_events`-style paths or a `band` parameter).

---

## Option C: Separate Vietminh output

**Idea:** Keep the current script focused on 1965–1966; add a second mode or script that builds **vietminh-timeline.svg** from **vietminh-timeline.yaml** with axis 1941–1954.

**Changes:**

- Either a flag (e.g. `--vietminh`) that sets data file and date range and output path, or a small wrapper script that calls the same builder with different constants.
- Reuse the same Events/Blocks pipeline and SVG builder; only constants and which YAML/block set change.

**Pros:** Minimal change to current behaviour; Vietminh gets a dedicated, readable timeline.  
**Cons:** Two SVGs; “incorporate” might mean one unified view, which this doesn’t provide.

---

## Recommendation

- **Option A** if you want a single, full narrative (1941 → 1966) and are okay with 1965–1966 taking a smaller share of the axis. Add the Vietminh block and event styling so the three phases are visually consistent.
- **Option B** if you want to keep 1965–1966 as the main focus and add Vietminh as clear “prelude” in a second band.
- **Option C** if “incorporate” means “support in the same repo” rather than “one combined SVG.”

Suggested next step: implement **Option A** (add `VIETMINH_FILE`, merge events, add `vietminh` block and CSS, then adjust axis tick logic for 1941–1966). If the right-hand density is too high, we can later introduce Option B (second band) or LOD (e.g. filter events by tier when zoomed out).
