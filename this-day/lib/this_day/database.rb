# frozen_string_literal: true

require "sqlite3"

module ThisDay
  class Database
    Event = Struct.new(:id, :month, :day, :year, :title, :body,
                       :photo_url, :photo_alt, :references, keyword_init: true)
    Reference = Struct.new(:label, :url, :archive_status, :archived_at, keyword_init: true) do
      def archived? = archive_status == "ok"

      # "2026-10-25T18:02:11Z" -> "2026-10-25"
      def archived_on = archived_at&.slice(0, 10)
    end

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
        'SELECT label, url, archive_status, archived_at FROM "references" WHERE event_id = ? ORDER BY position',
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
        references: refs.map do |r|
          Reference.new(label: r["label"], url: r["url"],
                        archive_status: r["archive_status"], archived_at: r["archived_at"])
        end
      )
    end

    def close
      @db.close
    end
  end
end
