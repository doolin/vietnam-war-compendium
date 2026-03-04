#!/usr/bin/env ruby

# =============================================================================
# INDOCHINA TIMELINE — SVG timeline driver (Vietnam War / Ia Drang, 1965–1966)
# =============================================================================
#
# PURPOSE
#   Reads event YAML, builds a single SVG file: horizontal time axis at the
#   bottom, events above it in boxed labels. Interactive in browser: hover
#   brings that event to the front (z-order) and highlights it grey; focus
#   leave or hover another event clears the highlight.
#
# STRATEGY (pipeline)
#   1. Load events: Events.load(path) parses YAML (the_war_years or timeline
#      key), normalizes dates (e.g. "Oct. 15/16, 1965" → first day), returns
#      [{ date: Date, label: String }, ...].
#   2. Layout: svg_layout returns a hash (axis_x_min/max/len, axis_y,
#      row_height, max_rows, events_above). All positioning uses this so we
#      can change one place.
#   3. Build SVG with Nokogiri::XML::Builder: root <svg>, then title + <style>,
#      then timeline axis (in a group with pointer-events: none so it doesn’t
#      steal hover), then event groups (each a <g class="event-group"> with
#      rect, line, circle, text), then a <script> for hover behaviour.
#   4. Write doc.to_xml to OUTPUT_FILE.
#
# COORDINATE SYSTEM
#   SVG y increases downward. "Above" the axis means smaller y. The axis is
#   at the bottom of the canvas (axis_y = HEIGHT - margin_bottom) so event
#   boxes sit in the upper area and stay inside the viewBox. Time runs left
#   to right: date_to_x maps a date to [0,1] over [start_date, end_date];
#   x = axis_x_min + t * axis_len.
#
# TIME AXIS (2 years only)
#   We deliberately span exactly 2 years (START_YEAR..END_YEAR = 1965–1966)
#   so each year gets equal visual weight. axis_start = Jan 1 1965,
#   axis_end = Dec 31 1966. Year ticks at Jan 1 of 1965 and 1966 (so 1966
#   is at the midpoint); right-end tick at Dec 31 1966 labeled "1967"
#   (traditional end-of-year label). Month ticks: April, July, October for
#   each of 1965 and 1966, positioned by date_to_x for true elapsed time.
#
# EVENT BOXES
#   Fixed width (EVENT_BOX_WIDTH), variable height from wrapped text. First
#   line is "Date Label..." (date bold via .event-date tspan), rest wrapped
#   at word boundaries (EVENT_CHARS_PER_LINE). Left-aligned text, ragged
#   right. Box is a rect behind the connector line and dot so the line/dot
#   stay visible.
#
# HOVER INTERACTION (script)
#   SVG paint order = DOM order; z-index is unreliable in many viewers. So we
#   don’t use z-index for “bring to front”. Instead: on mouseenter we
#   remove class "hovered" from every .event-group, add "hovered" to the
#   current group, and appendChild(this) so this group becomes the last child
#   of the SVG and is painted on top. CSS: .event-group.hovered .event-box
#   (and :hover) get light grey fill; .event-group .event-box is explicit
#   default (white) so when "hovered" is removed the box returns to white.
#   Clearing "hovered" from all groups on each mouseenter ensures the
#   previously hovered box goes back to white when you move to another event;
#   mouseleave clears the current group when focus leaves to empty space.
#   The timeline axis is wrapped in a group with pointer-events: none so
#   the axis doesn’t capture the mouse and event boxes receive hover.
#
# RUN
#   ruby indochina_timeline.rb  → writes ia-drang-timeline.svg. Open in a
#   browser (not as a static image) for hover/script to work.
#
# =============================================================================

require "yaml"
require "date"
require "nokogiri"

# --- Dimensions and data paths -----------------------------------------------
# Letter landscape: 11" x 8.5"; viewBox 1100×850.
WIDTH  = 1100
HEIGHT = 850
START_YEAR = 1941
END_YEAR   = 1972  # full span: Viet Minh formation through SOG deactivation
VIETMINH_FILE = File.join(__dir__, "vietminh-timeline.yaml")
DATA_FILE    = File.join(__dir__, "ia-drang-pimlott.yaml")
STARLITE_FILE = File.join(__dir__, "starlite-pimlott.yaml")
KINDLE_TIMELINE_FILE = File.join(__dir__, "kindle-highlights-timeline.yaml")
BLOCKS_FILE  = File.join(__dir__, "blocks.yaml")
OUTPUT_FILE  = File.join(__dir__, "indochina-timeline.svg")
DEFAULT_TIER = 2  # LOD: show at month/day zoom; 0=overview, 1=year, 2=month, 3=day

# LOD: show event only when visible time span is at most this many days (zoomed out = large span).
# Tier 0 = overview (show when span ≤ 30y); tier 1 = year (≤5y); tier 2 = month (≤1y); tier 3 = day (≤1 month).
# So at 25y span only tier-0 events appear; zooming in reveals more.
TIER_MAX_SPAN_DAYS = {
  0 => 30 * 365,
  1 => 5 * 365,
  2 => 365,
  3 => 30
}.freeze

# --- Events: YAML → array of { date:, label: } -------------------------------
# Supports YAML with top-level key "the_war_years" or "timeline" (array of
# { "date" => "...", "event" => "..." }). Normalizes date strings like
# "Oct. 15/16, 1965" to the first day; skips entries that don’t parse.
class Events
  EVENT_KEYS = %w[the_war_years timeline].freeze

  def self.load(path)
    new(path).events
  end

  def initialize(path)
    @path = path
  end

  def events
    @events ||= raw_entries
      .map { |e| entry_to_event(e) }
      .compact
  end

  private

  def raw_entries
    data = YAML.load_file(@path)
    key = EVENT_KEYS.find { |k| data.is_a?(Hash) && data.key?(k) }
    key ? data[key].to_a : []
  end

  def entry_to_event(entry)
    date = parse_date(entry["date"])
    return nil unless date

    tier = (entry["tier"] || DEFAULT_TIER).to_i
    { date: date, label: entry["event"].to_s, tier: tier }
  end

  def parse_date(str)
    # Normalize "Month day/day, year" to "Month day, year" (use first day)
    normalized = str.to_s.gsub(%r{/\d+\s*,?\s*}, ", ")
    Date.parse(normalized)
  rescue ArgumentError
    nil
  end
end

# --- Blocks: time ranges for LOD (e.g. "Ia Drang" as one unit when zoomed out) ---
# YAML: top-level key "blocks", array of { id:, start:, end:, label: }. start/end
# are date strings (YYYY-MM-DD or parseable). Optional event_source for later.
# Returns [{ id:, start_date:, end_date:, label: }, ...]. Not used by renderer yet.
class Blocks
  def self.load(path)
    return [] unless path && File.file?(path)

    new(path).blocks
  end

  def initialize(path)
    @path = path
  end

  def blocks
    @blocks ||= raw_entries.map { |e| entry_to_block(e) }.compact
  end

  private

  def raw_entries
    data = YAML.load_file(@path)
    return [] unless data.is_a?(Hash) && data["blocks"].is_a?(Array)

    data["blocks"]
  end

  def entry_to_block(entry)
    start_date = parse_date(entry["start"])
    end_date   = parse_date(entry["end"])
    return nil unless start_date && end_date

    {
      id:         entry["id"].to_s,
      start_date: start_date,
      end_date:   end_date,
      label:      entry["label"].to_s,
    }
  end

  def parse_date(str)
    Date.parse(str.to_s)
  rescue ArgumentError
    nil
  end
end

# --- Time → x position --------------------------------------------------------
# Maps a date to [0, 1] over [start_date, end_date]; used for axis ticks and
# event x positions so the scale is true elapsed time.
def date_to_x(date, start_date, end_date)
  start_ord = start_date.to_time.to_f
  end_ord   = end_date.to_time.to_f
  t         = date.to_time.to_f
  (t - start_ord) / (end_ord - start_ord)
end

# --- Layout constants --------------------------------------------------------
# Single place for margins, axis position, event row spacing. SVG y increases
# downward; "above" the axis means smaller y. Axis at bottom so events fit.
def svg_layout
  margin_left   = 100   # enough room for leftmost event box (Vietminh) so it isn’t clipped
  margin_right  = 80
  margin_bottom = 50   # space below axis (ticks + year labels)
  axis_y        = HEIGHT - margin_bottom
  axis_x_min    = margin_left
  axis_x_max    = WIDTH - margin_right
  {
    axis_x_min:  axis_x_min,
    axis_x_max:  axis_x_max,
    axis_len:    axis_x_max - axis_x_min,
    axis_y:      axis_y,
    row_height:  42,
    max_rows:    12,
    events_above: true,  # events drawn above axis (smaller y)
  }
end

# --- SVG: title and CSS -------------------------------------------------------
# Styles for axis, ticks, event box (default + hover/hovered), text. Timeline
# axis group gets pointer-events: none later so it doesn’t steal hover.
def add_title_and_style(xml)
  xml.title { xml.text "Indochina Timeline (1941–1966) — Viet Minh, Starlite, Ia Drang" }
  xml.style do
    xml.cdata <<~CSS
      .axis { stroke: #333; stroke-width: 1; fill: none; }
      .tick { stroke: #333; stroke-width: 1; }
      .tick-month { stroke: #555; stroke-width: 0.75; }
      .event-line { stroke: #666; stroke-width: 0.5; stroke-dasharray: 2,2; }
      .event-dot { fill: #c00; }
      .event-box { fill: #fff; stroke: #999; stroke-width: 0.75; }
      .event-group .event-box { fill: #fff; stroke: #999; stroke-width: 0.75; }
      .event-group:hover .event-box,
      .event-group.hovered .event-box { fill: #e0e0e0; stroke: #666; stroke-width: 1; }
      .event-group.block-starlite .event-box { fill: #eaf0f7; stroke: #6a9fb5; }
      .event-group.block-starlite:hover .event-box,
      .event-group.block-starlite.hovered .event-box { fill: #b8d4e8; stroke: #4a7f95; stroke-width: 1; }
      .event-group.block-ia_drang .event-box { fill: #f3ece5; stroke: #8a7566; }
      .event-group.block-ia_drang:hover .event-box,
      .event-group.block-ia_drang.hovered .event-box { fill: #d8c8b8; stroke: #6a5544; stroke-width: 1; }
      .event-text { font-family: Georgia, serif; font-size: 12px; fill: #1a1a1a; }
      .event-date { font-weight: bold; }
      .event-group { isolation: isolate; z-index: 0; cursor: pointer; }
      .event-group:hover { z-index: 1; }
      .year-label { font-family: Georgia, serif; font-size: 16px; font-weight: bold; fill: #1a1a1a; }
      .month-label { font-family: Georgia, serif; font-size: 11px; fill: #444; }
      .block-rect { fill: #d4e4f0; stroke: #6a9fb5; stroke-width: 0.75; }
      .block-starlite { fill: #d4e4f0; stroke: #6a9fb5; }
      .block-ia_drang { fill: #e8ddd0; stroke: #8a7566; }
      .block-vietminh { fill: #d8e6d8; stroke: #5a7a5a; }
      .block-label { font-family: Georgia, serif; font-size: 11px; fill: #2a4a5a; font-weight: bold; }
      .event-group.block-vietminh .event-box { fill: #e8f0e8; stroke: #5a7a5a; }
      .event-group.block-vietminh:hover .event-box,
      .event-group.block-vietminh.hovered .event-box { fill: #b8d0b8; stroke: #3a5a3a; stroke-width: 1; }
      .event-group.hidden { display: none; }
      .zoom-controls { font-family: Arial, sans-serif; font-size: 12px; }
      .zoom-btn { cursor: pointer; fill: #666; }
      .zoom-btn:hover { fill: #333; }
    CSS
  end
end

MONTH_TICKS = { 4 => "April", 7 => "July", 10 => "October" }.freeze

# Event box dimensions and text wrap (chars per line ≈ 12px font in box width).
EVENT_BOX_WIDTH   = 180
EVENT_BOX_PADDING = 6
EVENT_LINE_HEIGHT = 14
EVENT_CHARS_PER_LINE = 28

# Block band: strip just above the axis for time-range blocks (e.g. Ia Drang).
BLOCK_BAND_HEIGHT = 24

# Word-wrap to max_chars per line (word boundaries). Used for "Date Label..."
# so the first line can start with the bold date and continue with label text.
def wrap_text(text, max_chars: EVENT_CHARS_PER_LINE)
  words = text.to_s.split
  lines = []
  current = []
  current_len = 0
  words.each do |w|
    need = current_len.zero? ? w.length : current_len + 1 + w.length
    if need > max_chars && current.any?
      lines << current.join(" ")
      current = [w]
      current_len = w.length
    else
      current << w
      current_len = need
    end
  end
  lines << current.join(" ") if current.any?
  lines
end

# --- SVG: timeline axis -------------------------------------------------------
# Horizontal axis at layout[:axis_y], ticks and labels by date. Wrapped in
# <g class="timeline-axis" pointer-events="none"> so the axis doesn’t capture
# hover; event boxes (drawn after this) receive mouse events.
def add_timeline_axis(xml, layout, start_date, end_date)
  axis_x_min = layout[:axis_x_min]
  axis_len   = layout[:axis_len]
  axis_y     = layout[:axis_y]
  axis_start = Date.new(START_YEAR, 1, 1)
  axis_end   = Date.new(END_YEAR, 12, 31)

  xml.g("class" => "timeline-axis", "style" => "pointer-events: none;") do
  xml.line(
    "class" => "axis",
    "x1" => layout[:axis_x_min], "y1" => axis_y,
    "x2" => layout[:axis_x_max], "y2" => axis_y
  )

  # Year ticks: when span > 10 years, use every 5 years to avoid crowding
  span_years = END_YEAR - START_YEAR + 1
  year_ticks = if span_years > 10
    (START_YEAR..END_YEAR).select { |y| (y - START_YEAR) % 5 == 0 }
  else
    (START_YEAR..END_YEAR).to_a
  end
  year_ticks.each do |year|
    d = Date.new(year, 1, 1)
    t = date_to_x(d, axis_start, axis_end)
    x = axis_x_min + t * axis_len
    xml.line(
      "class" => "tick",
      "x1" => x, "y1" => axis_y,
      "x2" => x, "y2" => axis_y + 8
    )
    xml.text_("class" => "year-label", "x" => x, "y" => axis_y + 28, "text-anchor" => "middle") { xml.text year }
  end
  # Right-end tick: end of last year, labeled next year (traditional)
  t_end = date_to_x(axis_end, axis_start, axis_end)
  x_end = axis_x_min + t_end * axis_len
  xml.line("class" => "tick", "x1" => x_end, "y1" => axis_y, "x2" => x_end, "y2" => axis_y + 8)
  xml.text_("class" => "year-label", "x" => x_end, "y" => axis_y + 28, "text-anchor" => "middle") { xml.text END_YEAR + 1 }

  # Month ticks (short): only for recent years when span is long, to keep right side readable
  month_tick_years = if span_years > 10
    [END_YEAR - 2, END_YEAR - 1, END_YEAR].select { |y| y >= START_YEAR }.uniq
  else
    (START_YEAR..END_YEAR).to_a
  end
  month_tick_years.each do |year|
    MONTH_TICKS.each do |month, label|
      d = Date.new(year, month, 1)
      t = date_to_x(d, axis_start, axis_end)
      x = axis_x_min + t * axis_len
      xml.line(
        "class" => "tick-month",
        "x1" => x, "y1" => axis_y,
        "x2" => x, "y2" => axis_y + 4
      )
      xml.text_("class" => "month-label", "x" => x, "y" => axis_y + 12, "text-anchor" => "middle") { xml.text label }
    end
  end
  end
end

# --- SVG: event groups --------------------------------------------------------
# Each event: one <g class="event-group"> containing rect (box), line (axis →
# dot), circle (dot), then text lines. Box width fixed; height from wrapped
# "Date Label..." lines. Date on first line in bold (.event-date tspan), rest
# left-aligned. box_top_y places the box above the dot when events_above.
# If blocks are provided, events whose date falls in a block get class block-<id>
# so their box fill matches that block (lighter default, darker on hover).
# All events are included in the SVG; JavaScript handles LOD filtering based on visible viewBox.
def add_events(xml, events, layout, start_date, end_date, blocks = [])
  axis_x_min   = layout[:axis_x_min]
  axis_len     = layout[:axis_len]
  axis_y       = layout[:axis_y]
  row_height   = layout[:row_height]
  max_rows     = layout[:max_rows]
  events_above = layout[:events_above]

  base_offset = 50
  row_offset  = ->(row) { base_offset + row * row_height }
  dot_y       = ->(row) { events_above ? axis_y - row_offset.call(row) : axis_y + row_offset.call(row) }

  events.each_with_index do |ev, i|
    block_id = blocks.find { |b| ev[:date] >= b[:start_date] && ev[:date] <= b[:end_date] }&.dig(:id)
    t    = date_to_x(ev[:date], start_date, end_date)
    x    = axis_x_min + t * axis_len
    row  = i % max_rows
    y    = dot_y.call(row)

    date_str = ev[:date].strftime("%b %-d, %Y")
    # First line starts with date then label; wrap gives ragged-right (left-aligned) lines
    content_lines = wrap_text("#{date_str} #{ev[:label]}")
    box_w = EVENT_BOX_WIDTH
    half  = box_w / 2.0
    text_left_x = x - half + EVENT_BOX_PADDING
    # Box height = padding + lines only (date on first line saves space)
    box_h = EVENT_BOX_PADDING + (content_lines.size * EVENT_LINE_HEIGHT) + EVENT_BOX_PADDING

    box_top_y = if events_above
      box_bottom_y = y - 2
      box_bottom_y - box_h
    else
      y + 2
    end

    group_class = "event-group" + (block_id ? " block-#{block_id}" : "")
    tier = [[ev[:tier].to_i, 0].max, 3].min
    xml.g("class" => group_class, "data-date" => ev[:date].iso8601, "data-tier" => tier.to_s) do
      xml.rect(
        "class" => "event-box",
        "x" => x - half, "y" => box_top_y,
        "width" => box_w, "height" => box_h
      )
      xml.line(
        "class" => "event-line",
        "x1" => x, "y1" => axis_y,
        "x2" => x, "y2" => y
      )
      xml.circle("class" => "event-dot", "cx" => x, "cy" => y, "r" => 3)

      content_lines.each_with_index do |line, i|
        line_y = box_top_y + EVENT_BOX_PADDING + 11 + i * EVENT_LINE_HEIGHT
        if i == 0 && (line.start_with?(date_str) || line.include?(date_str))
          rest = line.sub(/\A#{Regexp.escape(date_str)}\s*/, "")
          xml.text_("class" => "event-text", "x" => text_left_x, "y" => line_y, "text-anchor" => "start") do
            xml.tspan("class" => "event-date") { xml.text "#{date_str} " }
            xml.tspan { xml.text rest } if rest != ""
          end
        else
          xml.text_("class" => "event-text", "x" => text_left_x, "y" => line_y, "text-anchor" => "start") { xml.text line }
        end
      end
    end
  end
end

# --- SVG: time-range blocks ---------------------------------------------------
# Draw each block that overlaps [start_date, end_date] as one rect in a band
# just above the axis, with label. Band uses same time scale (date_to_x).
# Group has pointer-events: none so event boxes still get hover.
def add_blocks(xml, blocks, layout, start_date, end_date)
  return if blocks.nil? || blocks.empty?

  axis_x_min = layout[:axis_x_min]
  axis_len   = layout[:axis_len]
  axis_y     = layout[:axis_y]
  band_top   = axis_y - BLOCK_BAND_HEIGHT
  rect_height = BLOCK_BAND_HEIGHT - 2  # small gap above axis

  xml.g("class" => "timeline-blocks", "style" => "pointer-events: none;") do
    blocks.each do |block|
      next if block[:end_date] < start_date || block[:start_date] > end_date

      t1 = date_to_x(block[:start_date], start_date, end_date)
      t2 = date_to_x(block[:end_date], start_date, end_date)
      t1 = 0.0 if t1 < 0
      t2 = 1.0 if t2 > 1
      next if t2 <= t1

      x      = axis_x_min + t1 * axis_len
      width  = (t2 - t1) * axis_len
      mid_x  = x + width / 2.0
      label_y = band_top + rect_height / 2.0 + 3

      block_class = "block-rect block-#{block[:id]}"
      xml.rect(
        "class" => block_class,
        "x" => x, "y" => band_top,
        "width" => width, "height" => rect_height
      )
      xml.text_("class" => "block-label", "x" => mid_x, "y" => label_y, "text-anchor" => "middle") { xml.text block[:label] }
    end
  end
end

# --- SVG: zoom controls ------------------------------------------------------
# Buttons for zoom in, zoom out, reset to full view
def add_zoom_controls(xml)
  xml.g("class" => "zoom-controls") do
    # Zoom in button
    xml.rect("class" => "zoom-btn", "id" => "zoom-in", "x" => 10, "y" => 10, "width" => 60, "height" => 24, "rx" => 4, "fill" => "#e0e0e0", "stroke" => "#999")
    xml.text("x" => 40, "y" => 26, "text-anchor" => "middle", "fill" => "#333", "font-size" => "12px") { xml.text "Zoom In" }
    # Zoom out button
    xml.rect("class" => "zoom-btn", "id" => "zoom-out", "x" => 80, "y" => 10, "width" => 60, "height" => 24, "rx" => 4, "fill" => "#e0e0e0", "stroke" => "#999")
    xml.text("x" => 110, "y" => 26, "text-anchor" => "middle", "fill" => "#333", "font-size" => "12px") { xml.text "Zoom Out" }
    # Reset button
    xml.rect("class" => "zoom-btn", "id" => "zoom-reset", "x" => 150, "y" => 10, "width" => 60, "height" => 24, "rx" => 4, "fill" => "#e0e0e0", "stroke" => "#999")
    xml.text("x" => 180, "y" => 26, "text-anchor" => "middle", "fill" => "#333", "font-size" => "12px") { xml.text "Reset" }
  end
end

# --- SVG: zoom and LOD script -------------------------------------------------
# Interactive zoom/pan: mouse wheel zooms, drag pans. LOD: show/hide events based on visible time span.
def add_zoom_and_lod_script(xml, start_date, end_date)
  xml.script do
    xml.cdata <<~JS
      (function() {
        var svg = document.querySelector('svg');
        var viewBox = { x: 0, y: 0, width: #{WIDTH}, height: #{HEIGHT} };
        var isDragging = false;
        var dragStart = { x: 0, y: 0 };
        var dragViewBox = { x: 0, y: 0, width: 0, height: 0 };
        var timelineStart = new Date('#{start_date.iso8601}');
        var timelineEnd = new Date('#{end_date.iso8601}');
        var timelineDays = (timelineEnd - timelineStart) / (1000 * 60 * 60 * 24);
        var axisXMin = #{svg_layout[:axis_x_min]};
        var axisLen = #{svg_layout[:axis_len]};
        
        // Tier max spans (days): 0=30y, 1=5y, 2=1y, 3=30d
        var tierMaxSpanDays = {
          0: 30 * 365,
          1: 5 * 365,
          2: 365,
          3: 30
        };
        
        function updateViewBox() {
          svg.setAttribute('viewBox', viewBox.x + ' ' + viewBox.y + ' ' + viewBox.width + ' ' + viewBox.height);
          updateLOD();
        }
        
        function updateLOD() {
          // Calculate visible time span from viewBox
          // Map viewBox x range to timeline x range
          var viewBoxXMin = viewBox.x;
          var viewBoxXMax = viewBox.x + viewBox.width;
          var viewBoxWidth = viewBox.width;
          
          // Convert viewBox x to timeline x (accounting for margins)
          var timelineXMin = Math.max(0, viewBoxXMin - axisXMin);
          var timelineXMax = Math.min(axisLen, viewBoxXMax - axisXMin);
          var visibleTimelineLen = timelineXMax - timelineXMin;
          
          // Convert timeline x to date
          var t1 = timelineXMin / axisLen;
          var t2 = timelineXMax / axisLen;
          var visibleStart = new Date(timelineStart.getTime() + t1 * timelineDays * 24 * 60 * 60 * 1000);
          var visibleEnd = new Date(timelineStart.getTime() + t2 * timelineDays * 24 * 60 * 60 * 1000);
          var visibleSpanDays = (visibleEnd - visibleStart) / (1000 * 60 * 60 * 24);
          
          // Show/hide events based on tier and visible span
          var events = document.querySelectorAll('.event-group');
          events.forEach(function(ev) {
            var tier = parseInt(ev.getAttribute('data-tier') || '2');
            var maxSpan = tierMaxSpanDays[tier] || tierMaxSpanDays[2];
            var eventDate = new Date(ev.getAttribute('data-date'));
            
            // Show if: event is in visible range AND visible span <= tier's max span
            var inRange = eventDate >= visibleStart && eventDate <= visibleEnd;
            var spanOK = visibleSpanDays <= maxSpan;
            
            if (inRange && spanOK) {
              ev.classList.remove('hidden');
            } else {
              ev.classList.add('hidden');
            }
          });
        }
        
        // Zoom functions
        function zoom(factor, centerX, centerY) {
          var newWidth = viewBox.width * factor;
          var newHeight = viewBox.height * factor;
          var newX = centerX - (centerX - viewBox.x) * factor;
          var newY = centerY - (centerY - viewBox.y) * factor;
          
          // Clamp to bounds
          newWidth = Math.max(100, Math.min(#{WIDTH}, newWidth));
          newHeight = Math.max(100, Math.min(#{HEIGHT}, newHeight));
          newX = Math.max(0, Math.min(#{WIDTH} - newWidth, newX));
          newY = Math.max(0, Math.min(#{HEIGHT} - newHeight, newY));
          
          viewBox.width = newWidth;
          viewBox.height = newHeight;
          viewBox.x = newX;
          viewBox.y = newY;
          updateViewBox();
        }
        
        function zoomToRange(startDate, endDate) {
          var t1 = (startDate - timelineStart) / (timelineDays * 24 * 60 * 60 * 1000);
          var t2 = (endDate - timelineStart) / (timelineDays * 24 * 60 * 60 * 1000);
          var x1 = axisXMin + t1 * axisLen;
          var x2 = axisXMin + t2 * axisLen;
          
          // Add padding
          var padding = 50;
          viewBox.x = Math.max(0, x1 - padding);
          viewBox.width = Math.min(#{WIDTH}, x2 - x1 + 2 * padding);
          viewBox.y = 0;
          viewBox.height = #{HEIGHT};
          updateViewBox();
        }
        
        // Mouse wheel zoom
        svg.addEventListener('wheel', function(e) {
          e.preventDefault();
          var rect = svg.getBoundingClientRect();
          var x = (e.clientX - rect.left) * (#{WIDTH} / rect.width);
          var y = (e.clientY - rect.top) * (#{HEIGHT} / rect.height);
          var factor = e.deltaY > 0 ? 1.2 : 1/1.2;
          zoom(factor, x, y);
        });
        
        // Drag to pan
        svg.addEventListener('mousedown', function(e) {
          if (e.target.closest('.zoom-btn')) return;
          isDragging = true;
          dragStart.x = e.clientX;
          dragStart.y = e.clientY;
          dragViewBox.x = viewBox.x;
          dragViewBox.y = viewBox.y;
        });
        
        svg.addEventListener('mousemove', function(e) {
          if (!isDragging) return;
          var dx = (e.clientX - dragStart.x) * (viewBox.width / svg.getBoundingClientRect().width);
          var dy = (e.clientY - dragStart.y) * (viewBox.height / svg.getBoundingClientRect().height);
          viewBox.x = Math.max(0, Math.min(#{WIDTH} - viewBox.width, dragViewBox.x - dx));
          viewBox.y = Math.max(0, Math.min(#{HEIGHT} - viewBox.height, dragViewBox.y - dy));
          updateViewBox();
        });
        
        svg.addEventListener('mouseup', function() { isDragging = false; });
        svg.addEventListener('mouseleave', function() { isDragging = false; });
        
        // Button controls
        document.getElementById('zoom-in').addEventListener('click', function() {
          zoom(0.7, #{WIDTH/2}, #{HEIGHT/2});
        });
        
        document.getElementById('zoom-out').addEventListener('click', function() {
          zoom(1/0.7, #{WIDTH/2}, #{HEIGHT/2});
        });
        
        document.getElementById('zoom-reset').addEventListener('click', function() {
          viewBox = { x: 0, y: 0, width: #{WIDTH}, height: #{HEIGHT} };
          updateViewBox();
        });
        
        // Initial LOD update
        updateLOD();
      })();
    JS
  end
end

# --- SVG: hover script --------------------------------------------------------
# Bring hovered event to front: appendChild(this) so this group is last in the
# SVG and paints on top. Class "hovered" drives grey highlight; we clear it
# from all groups on every mouseenter so only one is highlighted and the
# previous one returns to white; mouseleave clears when focus leaves to empty.
def add_event_hover_script(xml)
  xml.script do
    xml.cdata <<~JS
      var groups = document.querySelectorAll('.event-group');
      groups.forEach(function(g) {
        g.addEventListener('mouseenter', function() {
          groups.forEach(function(other) { other.classList.remove('hovered'); });
          this.classList.add('hovered');
          this.parentNode.appendChild(this);
        });
        g.addEventListener('mouseleave', function() { this.classList.remove('hovered'); });
      });
    JS
  end
end

# --- Build full SVG document -------------------------------------------------
# Order: title + style, timeline axis (pointer-events none), blocks band,
# event groups, then script. Events are drawn after blocks so they sit on top.
def build_svg(events, start_date, end_date, blocks = [])
  layout = svg_layout

  Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
    xml.svg(
      "xmlns" => "http://www.w3.org/2000/svg",
      "viewBox" => "0 0 #{WIDTH} #{HEIGHT}",
      "width" => "11in",
      "height" => "8.5in",
      "overflow" => "visible",
      "data-timeline-start" => start_date.iso8601,
      "data-timeline-end" => end_date.iso8601
    ) do
      add_title_and_style(xml)
      add_zoom_controls(xml)
      add_timeline_axis(xml, layout, start_date, end_date)
      add_blocks(xml, blocks, layout, start_date, end_date)
      add_events(xml, events, layout, start_date, end_date, blocks)
      add_zoom_and_lod_script(xml, start_date, end_date)
      add_event_hover_script(xml)
    end
  end
end

# --- Entry point --------------------------------------------------------------
# Load events from DATA_FILE and STARLITE_FILE, merge and sort by date, build
# SVG for [START_YEAR, END_YEAR], write to OUTPUT_FILE.
def main
  # Merge: load all event sources, concatenate, then sort by date (single chronological list).
  kindle_events = File.exist?(KINDLE_TIMELINE_FILE) ? Events.load(KINDLE_TIMELINE_FILE) : []
  events = Events.load(VIETMINH_FILE) + Events.load(DATA_FILE) + Events.load(STARLITE_FILE) + kindle_events
  events = events.sort_by { |e| e[:date] }
  blocks = Blocks.load(BLOCKS_FILE)
  start_date = Date.new(START_YEAR, 1, 1)
  end_date   = Date.new(END_YEAR, 12, 31)

  doc = build_svg(events, start_date, end_date, blocks)
  svg = doc.to_xml(indent: 2)

  File.write(OUTPUT_FILE, svg)
  puts "Wrote #{OUTPUT_FILE} (#{events.size} events total, #{blocks.size} blocks, interactive zoom enabled)"
end

main if __FILE__ == $PROGRAM_NAME
