#!/usr/bin/env ruby

# This is the driver file for a Vietnam War timeline
# rendered in SVG format. The timeline will initially
# start in 1965, and end in 1966. The initial physical
# size will be letter/landscape.
#
# The first set of events will be Ia Drang from Pimlott.

require "yaml"
require "date"
require "nokogiri"

# Letter landscape: 11" x 8.5"
WIDTH  = 1100
HEIGHT = 850
START_YEAR = 1965
END_YEAR   = 1966  # timeline spans exactly 2 years (1965–1966)
DATA_FILE   = File.join(__dir__, "ia-drang-pimlott.yaml")
OUTPUT_FILE = File.join(__dir__, "ia-drang-timeline.svg")

# Parses timeline YAML files (the_war_years or timeline key) into events with :date and :label.
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

def date_to_x(date, start_date, end_date)
  start_ord = start_date.to_time.to_f
  end_ord   = end_date.to_time.to_f
  t         = date.to_time.to_f
  (t - start_ord) / (end_ord - start_ord)
end

# SVG y increases downward; "above" the axis means smaller y.
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

def add_title_and_style(xml)
  xml.title { xml.text "Vietnam War Timeline — Ia Drang (1965–1966)" }
  xml.style do
    xml.cdata <<~CSS
      .axis { stroke: #333; stroke-width: 1; fill: none; }
      .tick { stroke: #333; stroke-width: 1; }
      .tick-month { stroke: #555; stroke-width: 0.75; }
      .event-line { stroke: #666; stroke-width: 0.5; stroke-dasharray: 2,2; }
      .event-dot { fill: #c00; }
      .event-text { font-family: Georgia, serif; font-size: 12px; fill: #1a1a1a; }
      .year-label { font-family: Georgia, serif; font-size: 16px; font-weight: bold; fill: #1a1a1a; }
      .month-label { font-family: Georgia, serif; font-size: 11px; fill: #444; }
    CSS
  end
end

MONTH_TICKS = { 4 => "April", 7 => "July", 10 => "October" }.freeze

def add_timeline_axis(xml, layout, start_date, end_date)
  axis_x_min = layout[:axis_x_min]
  axis_len   = layout[:axis_len]
  axis_y     = layout[:axis_y]
  # Axis = elapsed time from start of START_YEAR to end of END_YEAR (2 years)
  axis_start = Date.new(START_YEAR, 1, 1)
  axis_end   = Date.new(END_YEAR, 12, 31)

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

def add_events(xml, events, layout, start_date, end_date)
  axis_x_min   = layout[:axis_x_min]
  axis_len     = layout[:axis_len]
  axis_y       = layout[:axis_y]
  row_height   = layout[:row_height]
  max_rows     = layout[:max_rows]
  events_above = layout[:events_above]

  # Offset from axis to first event row; above = negative (smaller y)
  base_offset = 50
  row_offset  = ->(row) { base_offset + row * row_height }
  dot_y       = ->(row) { events_above ? axis_y - row_offset.call(row) : axis_y + row_offset.call(row) }

  events.each_with_index do |ev, i|
    t    = date_to_x(ev[:date], start_date, end_date)
    x    = axis_x_min + t * axis_len
    row  = i % max_rows
    y    = dot_y.call(row)

    # Line from axis to event dot (same y order in both cases: axis_y then y)
    xml.line(
      "class" => "event-line",
      "x1" => x, "y1" => axis_y,
      "x2" => x, "y2" => y
    )
    xml.circle("class" => "event-dot", "cx" => x, "cy" => y, "r" => 3)

    # Text: above axis = date and label above the dot (smaller y)
    date_str = ev[:date].strftime("%b %-d, %Y")
    label_text = ev[:label].length > 65 ? ev[:label][0..61] + "..." : ev[:label]
    if events_above
      date_y  = y - 4
      label_y = y - 18
      xml.text_("class" => "event-text", "x" => x, "y" => label_y, "text-anchor" => "middle") { xml.text label_text }
      xml.text_("class" => "event-text", "x" => x, "y" => date_y, "text-anchor" => "middle") { xml.text date_str }
    else
      date_y  = y + 4
      label_y = date_y + 14
      xml.text_("class" => "event-text", "x" => x, "y" => date_y, "text-anchor" => "middle") { xml.text date_str }
      xml.text_("class" => "event-text", "x" => x, "y" => label_y, "text-anchor" => "middle") { xml.text label_text }
    end
  end
end

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
    end
  end
end

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
