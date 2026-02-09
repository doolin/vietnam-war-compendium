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
START_YEAR     = 1965
END_YEAR       = 1966
AXIS_END_YEAR  = 1967  # right-end tick year
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

def svg_layout
  margin_left  = 80
  margin_right = 80
  axis_y      = 120
  axis_x_min  = margin_left
  axis_x_max  = WIDTH - margin_right
  {
    axis_x_min: axis_x_min,
    axis_x_max: axis_x_max,
    axis_len:   axis_x_max - axis_x_min,
    axis_y:     axis_y,
    row_height: 42,
    max_rows:   12
  }
end

def add_title_and_style(xml)
  xml.title { xml.text "Vietnam War Timeline — Ia Drang (1965–1966)" }
  xml.style do
    xml.cdata <<~CSS
      .axis { stroke: #333; stroke-width: 1; fill: none; }
      .tick { stroke: #333; stroke-width: 1; }
      .event-line { stroke: #666; stroke-width: 0.5; stroke-dasharray: 2,2; }
      .event-dot { fill: #c00; }
      .event-text { font-family: Georgia, serif; font-size: 12px; fill: #1a1a1a; }
      .year-label { font-family: Georgia, serif; font-size: 16px; font-weight: bold; fill: #1a1a1a; }
    CSS
  end
end

def add_timeline_axis(xml, layout, start_date, end_date)
  axis_x_min = layout[:axis_x_min]
  axis_len   = layout[:axis_len]
  axis_y     = layout[:axis_y]
  year_span  = AXIS_END_YEAR - START_YEAR

  xml.line(
    "class" => "axis",
    "x1" => layout[:axis_x_min], "y1" => axis_y,
    "x2" => layout[:axis_x_max], "y2" => axis_y
  )

  (START_YEAR..AXIS_END_YEAR).each do |year|
    t = year_span.zero? ? 0 : (year - START_YEAR).to_f / year_span
    x = axis_x_min + t * axis_len
    xml.line(
      "class" => "tick",
      "x1" => x, "y1" => axis_y,
      "x2" => x, "y2" => axis_y + 8
    )
    xml.text_("class" => "year-label", "x" => x, "y" => axis_y + 28, "text-anchor" => "middle") { xml.text year }
  end
end

def add_events(xml, events, layout, start_date, end_date)
  axis_x_min = layout[:axis_x_min]
  axis_len   = layout[:axis_len]
  axis_y     = layout[:axis_y]
  row_height = layout[:row_height]
  max_rows   = layout[:max_rows]

  events.each_with_index do |ev, i|
    t   = date_to_x(ev[:date], start_date, end_date)
    x   = axis_x_min + t * axis_len
    row = i % max_rows
    y   = axis_y + 50 + row * row_height

    xml.line(
      "class" => "event-line",
      "x1" => x, "y1" => axis_y,
      "x2" => x, "y2" => y
    )
    xml.circle("class" => "event-dot", "cx" => x, "cy" => y, "r" => 3)

    label_y  = y + 4
    date_str = ev[:date].strftime("%b %-d, %Y")
    xml.text_("class" => "event-text", "x" => x, "y" => label_y, "text-anchor" => "middle") { xml.text date_str }

    text = ev[:label].length > 65 ? ev[:label][0..61] + "..." : ev[:label]
    xml.text_("class" => "event-text", "x" => x, "y" => label_y + 14, "text-anchor" => "middle") { xml.text text }
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
      # add_events(xml, events, layout, start_date, end_date)
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
