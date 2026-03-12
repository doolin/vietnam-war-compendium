# frozen_string_literal: true

require "rack/test"
require "sqlite3"
require "fileutils"

# Build a test database in memory or tempfile for specs
module TestDatabaseHelper
  TEST_DB_PATH = File.expand_path("../db/test.sqlite3", __dir__)
  SCHEMA_PATH = File.expand_path("../db/schema.sql", __dir__)

  def self.build_test_db
    FileUtils.rm_f(TEST_DB_PATH)
    db = SQLite3::Database.new(TEST_DB_PATH)
    db.execute_batch(File.read(SCHEMA_PATH))
    db
  end

  def self.seed_event(db, month:, day:, year:, title:, body:, photo_url: nil, photo_alt: nil, references: [])
    db.execute(
      "INSERT INTO events (month, day, year, title, body, photo_url, photo_alt) VALUES (?, ?, ?, ?, ?, ?, ?)",
      [month, day, year, title, body, photo_url, photo_alt]
    )
    event_id = db.last_insert_row_id

    references.each_with_index do |ref, i|
      db.execute(
        'INSERT INTO "references" (event_id, position, label, url) VALUES (?, ?, ?, ?)',
        [event_id, i + 1, ref[:label], ref[:url]]
      )
    end

    event_id
  end
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed
end
