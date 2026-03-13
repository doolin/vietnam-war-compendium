#!/usr/bin/env ruby

# =============================================================================
# convert_html.rb — Kindle Notebook Export HTML → structured YAML
# =============================================================================
#
# Usage:
#   ruby convert_html.rb sog-kontum.html
#   ruby convert_html.rb sog-kontum.html --asin B07N79GTTQ
#   ruby convert_html.rb --all
#
# Parses a Kindle Notebook Export HTML file and generates a structured YAML
# file with the same basename. Existing YAML files are NOT overwritten —
# writes to <slug>.yaml.new instead, with a warning.

require "nokogiri"
require "yaml"
require "date"

# ---------------------------------------------------------------------------
# Date extraction
# ---------------------------------------------------------------------------

# Month abbreviations used in the existing timeline YAML convention
MONTH_ABBREV = {
  "January" => "Jan.", "February" => "Feb.", "March" => "Mar.",
  "April" => "Apr.", "May" => "May", "June" => "June",
  "July" => "July", "August" => "Aug.", "September" => "Sept.",
  "October" => "Oct.", "November" => "Nov.", "December" => "Dec."
}.freeze

SHORT_MONTH = {
  "Jan" => "Jan.", "Feb" => "Feb.", "Mar" => "Mar.", "Apr" => "Apr.",
  "May" => "May", "Jun" => "June", "Jul" => "July", "Aug" => "Aug.",
  "Sep" => "Sept.", "Oct" => "Oct.", "Nov" => "Nov.", "Dec" => "Dec."
}.freeze

FULL_MONTH_RE = "(?:January|February|March|April|May|June|July|August|September|October|November|December)"
SHORT_MONTH_RE = "(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)"

DATE_PATTERNS = [
  # "January 28, 1969" / "November 10, 1968" / "March 3, 1969"
  /(#{FULL_MONTH_RE})\s+(\d{1,2}),?\s+(\d{4})/,
  # "24 January, 1964" / "2 September 1970" / "13 January 1971"
  /(\d{1,2})\s+(#{FULL_MONTH_RE}),?\s+(\d{4})/,
  # Military: "09 Jan 69" / "30 July 68"
  /(\d{1,2})\s+(#{SHORT_MONTH_RE})\s+(\d{2,4})/,
].freeze

def normalize_date(month_str, day, year_str)
  # Expand 2-digit years (all dates in this project are 1941-1975)
  year = year_str.to_i
  year += 1900 if year < 100

  # Normalize month name to project convention
  abbrev = MONTH_ABBREV[month_str] || SHORT_MONTH[month_str] || month_str

  "#{abbrev} #{day.to_i}, #{year}"
end

def extract_date_suggestions(text)
  dates = []

  # Pattern 1: "Month DD, YYYY"
  text.scan(/(#{FULL_MONTH_RE})\s+(\d{1,2}),?\s+(\d{4})/) do |month, day, year|
    dates << build_date_entry(normalize_date(month, day, year), text)
  end

  # Pattern 2: "DD Month, YYYY"
  text.scan(/(\d{1,2})\s+(#{FULL_MONTH_RE}),?\s+(\d{4})/) do |day, month, year|
    dates << build_date_entry(normalize_date(month, day, year), text)
  end

  # Pattern 3: Military "DD Mon YY"
  text.scan(/(\d{1,2})\s+(#{SHORT_MONTH_RE})\s+(\d{2,4})/) do |day, month, year|
    dates << build_date_entry(normalize_date(month, day, year), text)
  end

  dates.uniq { |d| d["date"] }
end

def build_date_entry(date_str, text)
  # Truncate highlight text to ~120 chars for the event description
  event = text.length > 120 ? text[0, 117] + "..." : text
  {
    "date" => date_str,
    "event" => event.gsub(/\s+/, " ").strip,
    "tier" => 2,
    "status" => "suggested"
  }
end

# ---------------------------------------------------------------------------
# HTML parsing
# ---------------------------------------------------------------------------

def parse_page_location(heading_text)
  page = heading_text[/Page\s+(\d+)/, 1]&.to_i
  location = heading_text[/Location\s+(\d+)/, 1]&.to_i
  [page, location]
end

def parse_html(html_path)
  doc = Nokogiri::HTML(File.read(html_path))

  title = doc.at_css(".bookTitle")&.text&.strip || ""
  authors = doc.at_css(".authors")&.text&.strip || ""
  citation = doc.at_css(".citation")&.text&.strip || ""
  citation = citation.sub(/\ACitation.*?:\s*/i, "").strip if citation.length > 0

  body = doc.at_css(".bodyContainer")
  elements = body.children.select do |n|
    n.element? && %w[div].include?(n.name) &&
      (n["class"]&.match?(/sectionHeading|noteHeading|noteText|notebookFor|bookTitle|authors|citation/) || false)
  end

  current_section = ""
  highlights = []
  id_counter = 0
  i = 0

  while i < elements.size
    node = elements[i]
    css_class = node["class"] || ""

    # Skip metadata divs at the top
    if css_class.match?(/notebookFor|bookTitle|authors|citation/)
      i += 1
      next
    end

    if css_class.include?("sectionHeading")
      current_section = node.text.strip
      i += 1
      next
    end

    if css_class.include?("noteHeading")
      heading_text = node.text.strip
      # Next element should be noteText
      note_node = elements[i + 1]
      if note_node && note_node["class"]&.include?("noteText")
        note_text = note_node.text.strip
        i += 2
      else
        note_text = ""
        i += 1
      end

      if heading_text.match?(/\AHighlight/)
        id_counter += 1
        color = node.at_css("span")&.text&.strip || "yellow"
        page, location = parse_page_location(heading_text)

        highlights << {
          "id" => id_counter,
          "type" => "highlight",
          "section" => current_section,
          "page" => page,
          "location" => location,
          "color" => color,
          "text" => note_text,
          "kindle_url" => "",
          "note" => "",
          "context" => "",
          "tags" => [],
          "cross_refs" => [],
          "dates" => extract_date_suggestions(note_text)
        }
      elsif heading_text.match?(/\ANote/)
        # Merge note into previous highlight
        if highlights.any?
          highlights.last["note"] = note_text
        end
      end
    else
      i += 1
    end
  end

  {
    "book" => {
      "title" => title,
      "authors" => authors,
      "asin" => "",
      "citation" => citation.empty? ? "" : citation,
      "url" => "",
      "source_file" => File.basename(html_path)
    },
    "highlights" => highlights
  }
end

# ---------------------------------------------------------------------------
# YAML output
# ---------------------------------------------------------------------------

def write_yaml(data, yaml_path)
  if File.exist?(yaml_path)
    alt_path = yaml_path + ".new"
    warn "WARNING: #{yaml_path} already exists. Writing to #{alt_path} instead."
    warn "  Diff with: diff #{yaml_path} #{alt_path}"
    yaml_path = alt_path
  end

  File.write(yaml_path, data.to_yaml)
  puts "Wrote #{data['highlights'].size} highlights to #{yaml_path}"

  # Summary of date suggestions
  date_count = data["highlights"].sum { |h| h["dates"].size }
  puts "  Auto-extracted #{date_count} date suggestions (status: suggested)"
end

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main
  if ARGV.empty?
    warn "Usage: ruby convert_html.rb <file.html> [--asin ASIN]"
    warn "       ruby convert_html.rb --all [--asin ASIN]"
    exit 1
  end

  asin = ""
  files = []

  i = 0
  while i < ARGV.size
    if ARGV[i] == "--asin"
      asin = ARGV[i + 1] || ""
      i += 2
    elsif ARGV[i] == "--all"
      dir = File.dirname(__FILE__)
      files = Dir.glob(File.join(dir, "*.html"))
      i += 1
    else
      files << ARGV[i]
      i += 1
    end
  end

  files.each do |html_path|
    unless File.exist?(html_path)
      # Try relative to script directory
      alt = File.join(File.dirname(__FILE__), html_path)
      html_path = alt if File.exist?(alt)
    end

    unless File.exist?(html_path)
      warn "File not found: #{html_path}"
      next
    end

    puts "Processing #{html_path}..."
    data = parse_html(html_path)
    data["book"]["asin"] = asin unless asin.empty?

    yaml_path = html_path.sub(/\.html$/, ".yaml")
    write_yaml(data, yaml_path)
    puts
  end
end

main
