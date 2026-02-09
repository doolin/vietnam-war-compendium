# Commit: Add interactive zoom and LOD to Indochina timeline

(THIS IS NOT WORKING AS INTENDED.)

## Summary

Added interactive zoom/pan functionality and dynamic level-of-detail (LOD) filtering to the Indochina timeline SVG. The timeline now includes all events (32 total) and uses JavaScript to show/hide events based on the visible time span as the user zooms in/out.

## Changes

### Timeline expansion (1941–1966)
- **Expanded date range**: Changed `START_YEAR` from 1965 to 1941, `END_YEAR` remains 1966
- **Added Vietminh timeline**: Integrated `vietminh-timeline.yaml` (12 events, 1941–1954)
- **Merge strategy**: All three sources (Vietminh, Starlite, Ia Drang) are loaded, concatenated, and sorted chronologically
- **Output file**: Changed from `ia-drang-timeline.svg` to `indochina-timeline.svg`

### Blocks system
- **Added Vietminh block**: `blocks.yaml` now includes "First Indochina / Viet Minh" block (1941-05-10 to 1954-07-21)
- **Block styling**: Added green color scheme for Vietminh block (`.block-vietminh`, `.event-group.block-vietminh`)
- **Three blocks total**: Vietminh (left), Starlite (right), Ia Drang (right)

### Level of Detail (LOD) implementation
- **Tier system**: Events have `tier` attribute (0=overview, 1=year, 2=month, 3=day)
- **Tier thresholds**: `TIER_MAX_SPAN_DAYS` defines when each tier appears:
  - Tier 0: visible when span ≤ 30 years (overview)
  - Tier 1: visible when span ≤ 5 years
  - Tier 2: visible when span ≤ 1 year
  - Tier 3: visible when span ≤ 30 days
- **Tier assignments**: Key milestones marked as tier 0:
  - Vietminh: formation (1941), independence (1945), Dien Bien Phu (1954), Geneva (1954)
  - Starlite: Marines at Da Nang (Mar 1965)
  - Ia Drang: LZ X-Ray (Nov 1965)

### Interactive zoom/pan
- **All events included**: Removed LOD filtering at generation time; all 32 events are in the SVG
- **Data attributes**: Each event group has `data-date` (ISO8601) and `data-tier` attributes
- **Timeline metadata**: SVG root has `data-timeline-start` and `data-timeline-end` for date calculations
- **JavaScript zoom/pan**:
  - Mouse wheel: zoom in/out at cursor position
  - Click-drag: pan the view
  - Zoom buttons: "Zoom In", "Zoom Out", "Reset" (top-left corner)
- **Dynamic LOD filtering**: JavaScript calculates visible time span from `viewBox` and shows/hides events accordingly

### Axis improvements
- **Smart year ticks**: When span > 10 years, shows ticks every 5 years (1941, 1946, 1951, 1956, 1961, 1966)
- **Month ticks**: Only shown for recent years (last 3 years) when span is long
- **Layout**: Increased left margin from 80 to 100 to prevent clipping of leftmost events

### Styling
- **CSS classes**: Added `.event-group.hidden` for LOD filtering
- **Zoom controls**: Added `.zoom-controls` and `.zoom-btn` styles
- **Title**: Updated to "Indochina Timeline (1941–1966) — Viet Minh, Starlite, Ia Drang"

## Current state

### What works
- ✅ Timeline generates successfully with all 32 events
- ✅ All three blocks render correctly (Vietminh, Starlite, Ia Drang)
- ✅ Zoom controls UI is present
- ✅ JavaScript is included in SVG

### Known issues
- ⚠️ **Interactive zoom not working as expected**: The zoom/pan functionality and LOD filtering need debugging
  - ViewBox manipulation may not be calculating visible time span correctly
  - Event visibility logic may have bugs in date range calculations
  - Mouse event handling may need refinement
- ⚠️ **LOD filtering**: Events may not be showing/hiding correctly based on zoom level
- ⚠️ **User experience**: The zoom interaction may not feel smooth or intuitive

## Technical details

### Files modified
- `indochina_timeline.rb`: Main driver script
- `blocks.yaml`: Added Vietminh block
- `vietminh-timeline.yaml`: Added tier 0 to key events
- `starlite-pimlott.yaml`: Added tier 0 to first event
- `ia-drang-pimlott.yaml`: Added tier 0 to LZ X-Ray event

### Key functions added
- `add_zoom_controls()`: Creates zoom button UI
- `add_zoom_and_lod_script()`: JavaScript for zoom/pan and LOD filtering
- Modified `add_events()`: Removed LOD filtering, added data attributes
- Modified `build_svg()`: Removed `visible_span_days` parameter, added zoom controls

### JavaScript approach
- Uses SVG `viewBox` attribute for zoom/pan
- Calculates visible time span from viewBox coordinates
- Maps viewBox x-coordinates to timeline dates using axis position and length
- Filters events by comparing visible span to tier thresholds

## Next steps

1. **Debug zoom/pan**:
   - Verify viewBox calculations are correct
   - Test mouse wheel zoom at cursor position
   - Test click-drag panning
   - Ensure bounds checking works correctly

2. **Fix LOD filtering**:
   - Verify date range calculations (viewBox → visible dates)
   - Test that events show/hide correctly at different zoom levels
   - Ensure tier thresholds are being applied correctly
   - Add console logging for debugging

3. **Improve UX**:
   - Smooth zoom transitions (if desired)
   - Better visual feedback during pan
   - Consider zoom limits (min/max zoom levels)
   - Test on different browsers

4. **Testing**:
   - Test zooming into 1965–1966 to see all Starlite/Ia Drang events
   - Test zooming out to full span to see only tier-0 events
   - Verify blocks remain visible at all zoom levels
   - Test panning across the timeline

5. **Documentation**:
   - Update README with zoom/pan instructions
   - Document LOD tier system
   - Add examples of expected behavior

## Notes

- The timeline now spans 25 years (1941–1966), which is a significant increase from the original 2-year span
- At full zoom, only 6 tier-0 events are visible (by design), but all events are in the DOM
- The JavaScript approach allows for future enhancements like preset zoom levels, animation, or URL-based view state
