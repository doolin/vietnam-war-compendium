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
START_YEAR = 1965
END_YEAR   = 1966  # timeline spans exactly 2 years (1965–1966)
DATA_FILE   = File.join(__dir__, "ia-drang-pimlott.yaml")
OUTPUT_FILE = File.join(__dir__, "ia-drang-timeline.svg")

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

    { date: date, label: entry["event"].to_s }
  end

  def parse_date(str)
    # Normalize "Month day/day, year" to "Month day, year" (use first day)
    normalized = str.to_s.gsub(%r{/\d+\s*,?\s*}, ", ")
    Date.parse(normalized)
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
  margin_left   = 80
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
  xml.title { xml.text "Vietnam War Timeline — Ia Drang (1965–1966)" }
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
      .event-text { font-family: Georgia, serif; font-size: 12px; fill: #1a1a1a; }
      .event-date { font-weight: bold; }
      .event-group { isolation: isolate; z-index: 0; cursor: pointer; }
      .event-group:hover { z-index: 1; }
      .year-label { font-family: Georgia, serif; font-size: 16px; font-weight: bold; fill: #1a1a1a; }
      .month-label { font-family: Georgia, serif; font-size: 11px; fill: #444; }
    CSS
  end
end

MONTH_TICKS = { 4 => "April", 7 => "July", 10 => "October" }.freeze

# Event box dimensions and text wrap (chars per line ≈ 12px font in box width).
EVENT_BOX_WIDTH   = 180
EVENT_BOX_PADDING = 6
EVENT_LINE_HEIGHT = 14
EVENT_CHARS_PER_LINE = 28

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

  # Year ticks (long) and labels — at start of each year so each year gets equal visual span
  # Axis runs Jan 1 1965 .. Dec 31 1966 (2 years); 1965 and 1966 at Jan 1 so right half = 1966, end = Dec 31 1966
  (START_YEAR..END_YEAR).each do |year|
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
  # Right-end tick: end of 1966, labeled 1967 (traditional: end of year shows next year)
  t_end = date_to_x(axis_end, axis_start, axis_end)
  x_end = axis_x_min + t_end * axis_len
  xml.line("class" => "tick", "x1" => x_end, "y1" => axis_y, "x2" => x_end, "y2" => axis_y + 8)
  xml.text_("class" => "year-label", "x" => x_end, "y" => axis_y + 28, "text-anchor" => "middle") { xml.text END_YEAR + 1 }

  # Month ticks (short) and labels — April, July, October for 1965 and 1966 only
  (START_YEAR..END_YEAR).each do |year|
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
def add_events(xml, events, layout, start_date, end_date)
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

    xml.g("class" => "event-group") do
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
# Order: title + style, timeline axis (pointer-events none), event groups,
# then script. Events are drawn after the axis so they sit on top; axis doesn’t
# capture hover.
def build_svg(events, start_date, end_date)
  layout = svg_layout

  Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
    xml.svg(
      "xmlns" => "http://www.w3.org/2000/svg",
      "viewBox" => "0 0 #{WIDTH} #{HEIGHT}",
      "width" => "11in",
      "height" => "8.5in"
    ) do
      add_title_and_style(xml)
      add_timeline_axis(xml, layout, start_date, end_date)
      add_events(xml, events, layout, start_date, end_date)
      add_event_hover_script(xml)
    end
  end
end

# --- Entry point --------------------------------------------------------------
# Load events from DATA_FILE, build SVG for [START_YEAR, END_YEAR], write to
# OUTPUT_FILE.
def main
  events = Events.load(DATA_FILE)
  start_date = Date.new(START_YEAR, 1, 1)
  end_date   = Date.new(END_YEAR, 12, 31)

  doc = build_svg(events, start_date, end_date)
  svg = doc.to_xml(indent: 2)

  File.write(OUTPUT_FILE, svg)
  puts "Wrote #{OUTPUT_FILE} (#{events.size} events)"
end

main if __FILE__ == $PROGRAM_NAME
