# frozen_string_literal: true

# Rake-invoked script to build the SQLite3 database from YAML source data.
#
# Usage:
#   rake db:build
#
# The YAML source files are expected in data/events/*.yaml relative to the
# project root. Each file contains an array of event hashes.

require "sqlite3"
require "yaml"
require "fileutils"

DB_DIR = File.expand_path(__dir__)
DB_PATH = File.join(DB_DIR, "this_day.sqlite3")
SCHEMA_PATH = File.join(DB_DIR, "schema.sql")
DATA_DIR = File.expand_path("../data/events", __dir__)

REQUIRED_EVENT_FIELDS = %w[month day year title body].freeze

def validate_event(evt, file, index)
  errors = []

  REQUIRED_EVENT_FIELDS.each do |field|
    errors << "missing '#{field}'" if evt[field].nil?
  end

  month = evt["month"]
  day = evt["day"]
  year = evt["year"]

  if month.is_a?(Integer)
    errors << "month #{month} out of range (1-12)" unless (1..12).include?(month)
  elsif !month.nil?
    errors << "month must be an integer, got #{month.class}"
  end

  if day.is_a?(Integer)
    errors << "day #{day} out of range (1-31)" unless (1..31).include?(day)
  elsif !day.nil?
    errors << "day must be an integer, got #{day.class}"
  end

  if year.is_a?(Integer)
    errors << "year #{year} out of range (1940-1980)" unless (1940..1980).include?(year)
  elsif !year.nil?
    errors << "year must be an integer, got #{year.class}"
  end

  Array(evt["references"]).each_with_index do |ref, i|
    errors << "reference #{i + 1} missing 'label'" if ref["label"].nil? || ref["label"].to_s.empty?
    errors << "reference #{i + 1} missing 'url'" if ref["url"].nil? || ref["url"].to_s.empty?
  end

  unless errors.empty?
    location = "#{File.basename(file)} event ##{index + 1}"
    title = evt["title"] || "(no title)"
    errors.each { |e| warn "Validation error in #{location} (#{title}): #{e}" }
  end

  errors
end

def build_database
  FileUtils.rm_f(DB_PATH)

  db = SQLite3::Database.new(DB_PATH)
  db.execute_batch(File.read(SCHEMA_PATH))

  event_files = Dir.glob(File.join(DATA_DIR, "*.yaml")).sort
  if event_files.empty?
    warn "Warning: No YAML event files found in #{DATA_DIR}"
    db.close
    return
  end

  total_errors = 0

  db.transaction do
    event_files.each do |file|
      events = YAML.safe_load_file(file, permitted_classes: [Date])
      next unless events.is_a?(Array)

      events.each_with_index do |evt, index|
        errors = validate_event(evt, file, index)
        total_errors += errors.size
        next unless errors.empty?

        db.execute(
          "INSERT INTO events (month, day, year, title, body, photo_url, photo_alt) VALUES (?, ?, ?, ?, ?, ?, ?)",
          [evt["month"], evt["day"], evt["year"], evt["title"], evt["body"], evt["photo_url"], evt["photo_alt"]]
        )
        event_id = db.last_insert_row_id

        Array(evt["references"]).each_with_index do |ref, i|
          db.execute(
            'INSERT INTO "references" (event_id, position, label, url) VALUES (?, ?, ?, ?)',
            [event_id, i + 1, ref["label"], ref["url"]]
          )
        end
      end
    end
  end

  db.close

  if total_errors > 0
    abort "Build failed: #{total_errors} validation error(s) found"
  end

  puts "Built #{DB_PATH}"
end

build_database if __FILE__ == $PROGRAM_NAME
