# frozen_string_literal: true

# Rake-invoked script to build the SQLite3 database from YAML source data.
#
# Usage:
#   rake db:build
#
# The YAML source files are expected in data/events/*.yml relative to the
# project root. Each file contains an array of event hashes.

require "sqlite3"
require "yaml"
require "fileutils"

DB_DIR = File.expand_path(__dir__)
DB_PATH = File.join(DB_DIR, "this_day.sqlite3")
SCHEMA_PATH = File.join(DB_DIR, "schema.sql")
DATA_DIR = File.expand_path("../data/events", __dir__)

def build_database
  FileUtils.rm_f(DB_PATH)

  db = SQLite3::Database.new(DB_PATH)
  db.execute_batch(File.read(SCHEMA_PATH))

  event_files = Dir.glob(File.join(DATA_DIR, "*.yml")).sort
  if event_files.empty?
    warn "Warning: No YAML event files found in #{DATA_DIR}"
    db.close
    return
  end

  db.transaction do
    event_files.each do |file|
      events = YAML.safe_load_file(file, permitted_classes: [Date])
      next unless events.is_a?(Array)

      events.each do |evt|
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
  puts "Built #{DB_PATH}"
end

build_database if __FILE__ == $PROGRAM_NAME
