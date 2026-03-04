#!/usr/bin/env ruby

# Standalone Tet chronology SVG from "The Big Story"
# Uses the shared SVG builder from indochina_timeline.rb

require_relative "indochina_timeline"

TET_FILE   = File.join(__dir__, "tet-bigstory.yaml")
TET_OUTPUT = File.join(__dir__, "tet-bigstory-timeline.svg")

events = Events.load(TET_FILE).sort_by { |e| e[:date] }
start_date = Date.new(1967, 11, 1)
end_date   = Date.new(1968, 4, 30)

doc = build_svg(events, start_date, end_date, [])
File.write(TET_OUTPUT, doc.to_xml(indent: 2))
puts "Wrote #{TET_OUTPUT} (#{events.size} events)"
