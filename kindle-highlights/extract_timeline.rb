#!/usr/bin/env ruby

# =============================================================================
# extract_timeline.rb — Extract dates from highlight YAML → timeline YAML
# =============================================================================
#
# Usage:
#   ruby extract_timeline.rb sog-kontum.yaml
#   ruby extract_timeline.rb --all
#   ruby extract_timeline.rb --all --include-suggested
#
# Reads enriched highlight YAML files, collects date entries, and writes
# a timeline YAML file compatible with Events.load in indochina_timeline.rb.
#
# By default, only exports dates with status: confirmed.
# Use --include-suggested to also include unreviewed suggestions.

require "yaml"

OUTPUT_FILE = File.join(File.dirname(__FILE__), "..", "timelines", "kindle-highlights-timeline.yaml")

def extract_events(yaml_path, include_suggested: false)
  data = YAML.load_file(yaml_path)
  book_slug = File.basename(yaml_path, ".yaml")
  events = []

  (data["highlights"] || []).each do |h|
    (h["dates"] || []).each do |d|
      next if d["status"] == "suggested" && !include_suggested
      events << {
        "date" => d["date"],
        "event" => d["event"],
        "tier" => d["tier"] || 2
      }
    end
  end

  events
end

def main
  include_suggested = ARGV.delete("--include-suggested")
  files = []

  if ARGV.delete("--all")
    dir = File.dirname(__FILE__)
    files = Dir.glob(File.join(dir, "*.yaml")).reject { |f| f.end_with?(".yaml.new") }
  else
    files = ARGV.dup
  end

  if files.empty?
    warn "Usage: ruby extract_timeline.rb <file.yaml> [...]"
    warn "       ruby extract_timeline.rb --all [--include-suggested]"
    exit 1
  end

  all_events = []
  files.each do |yaml_path|
    unless File.exist?(yaml_path)
      alt = File.join(File.dirname(__FILE__), yaml_path)
      yaml_path = alt if File.exist?(alt)
    end

    unless File.exist?(yaml_path)
      warn "File not found: #{yaml_path}"
      next
    end

    events = extract_events(yaml_path, include_suggested: !!include_suggested)
    puts "#{File.basename(yaml_path)}: #{events.size} events"
    all_events.concat(events)
  end

  # Deduplicate by date + event text
  all_events.uniq! { |e| [e["date"], e["event"]] }

  output = { "timeline" => all_events }

  header = <<~HEADER
    # Generated from Kindle highlights — do not edit directly.
    # Re-generate with: ruby kindle-highlights/extract_timeline.rb --all
    #
  HEADER

  File.write(OUTPUT_FILE, header + output.to_yaml)
  puts "\nWrote #{all_events.size} events to #{OUTPUT_FILE}"
end

main
