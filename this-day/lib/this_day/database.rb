# frozen_string_literal: true

require "sqlite3"

module ThisDay
  class Database
    Event = Struct.new(:id, :month, :day, :year, :title, :body,
                       :photo_url, :photo_alt, :references, keyword_init: true)
    Reference = Struct.new(:label, :url, keyword_init: true)

    def initialize(db_path)
      @db = SQLite3::Database.new(db_path, readonly: true)
      @db.results_as_hash = true
    end

    def event_for_date(month, day)
      rows = @db.execute(
        "SELECT id, month, day, year, title, body, photo_url, photo_alt FROM events WHERE month = ? AND day = ?",
        [month, day]
      )
      return nil if rows.empty?

      row = rows.sample
      refs = @db.execute(
        'SELECT label, url FROM "references" WHERE event_id = ? ORDER BY position',
        [row["id"]]
      )

      Event.new(
        id: row["id"],
        month: row["month"],
        day: row["day"],
        year: row["year"],
        title: row["title"],
        body: row["body"],
        photo_url: row["photo_url"],
        photo_alt: row["photo_alt"],
        references: refs.map { |r| Reference.new(label: r["label"], url: r["url"]) }
      )
    end

    def close
      @db.close
    end
  end
end
