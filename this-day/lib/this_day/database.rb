# frozen_string_literal: true

require "sqlite3"

module ThisDay
  class Database
    Event = Struct.new(:id, :month, :day, :year, :title, :body,
                       :photo_url, :photo_alt, :references, :status, :source_text, :source_file,
                       :summarized_by, :summarized_at,
                       keyword_init: true) do
      def draft? = status == "draft"

      # "Summary by Claude Fable 5.1, 2026-10-25" or nil when unattributed (legacy).
      def credit
        return nil if summarized_by.nil? || summarized_by.empty?

        date = summarized_at&.slice(0, 10)
        date ? "Summary by #{summarized_by}, #{date}" : "Summary by #{summarized_by}"
      end
    end

    # snapshot_url is set when the archived copy came from the Wayback
    # Machine because the cited URL no longer serves the document.
    Reference = Struct.new(:label, :url, :archive_status, :archived_at, :snapshot_url, keyword_init: true) do
      def archived? = archive_status == "ok"

      # "2026-10-25T18:02:11Z" -> "2026-10-25"
      def archived_on = archived_at&.slice(0, 10)
    end

    EVENT_COLUMNS = "id, month, day, year, title, body, photo_url, photo_alt, status, source_text, source_file, " \
                    "summarized_by, summarized_at"

    def initialize(db_path)
      @db = SQLite3::Database.new(db_path, readonly: true)
      @db.results_as_hash = true
    end

    # One reviewed event for the date, chosen at random when several
    # exist. Drafts and rejected events are never served; drafts appear
    # only on the month review page.
    def event_for_date(month, day)
      rows = @db.execute(
        "SELECT #{EVENT_COLUMNS} FROM events WHERE month = ? AND day = ? AND status = 'approved'",
        [month, day]
      )
      return nil if rows.empty?

      build_event(rows.sample)
    end

    # Every event in the month, including rejected ones, ordered by day then year.
    def events_for_month(month)
      rows = @db.execute(
        "SELECT #{EVENT_COLUMNS} FROM events WHERE month = ? ORDER BY day, year",
        [month]
      )
      rows.map { |row| build_event(row) }
    end

    def close
      @db.close
    end

    private

    def build_event(row)
      refs = @db.execute(
        'SELECT label, url, archive_status, archived_at, snapshot_url FROM "references" ' \
        "WHERE event_id = ? ORDER BY position",
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
        status: row["status"],
        source_text: row["source_text"],
        source_file: row["source_file"],
        summarized_by: row["summarized_by"],
        summarized_at: row["summarized_at"],
        references: refs.map do |r|
          Reference.new(label: r["label"], url: r["url"],
                        archive_status: r["archive_status"], archived_at: r["archived_at"],
                        snapshot_url: r["snapshot_url"])
        end
      )
    end
  end
end
