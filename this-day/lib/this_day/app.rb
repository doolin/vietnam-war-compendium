# frozen_string_literal: true

require "roda"
require_relative "database"

module ThisDay
  class App < Roda
    plugin :render, engine: "erb", views: File.expand_path("../../views", __dir__),
                    template_opts: { default_encoding: "UTF-8" }
    plugin :head
    plugin :status_handler
    plugin :typecast_params

    def self.db_path
      ENV.fetch("THIS_DAY_DB_PATH") {
        File.expand_path("../../db/this_day.sqlite3", __dir__)
      }
    end

    def self.database
      @database ||= Database.new(db_path)
    end

    def self.reset_database!
      @database&.close
      @database = nil
    end

    status_handler(404) do
      view("fallback", locals: { date_string: format_date(Date.today) })
    end

    status_handler(500) do
      "<h1>Something went wrong</h1><p>Please try again later.</p>"
    end

    route do |r|
      r.root do
        today = Date.today
        event = self.class.database.event_for_date(today.month, today.day)

        if event
          date_string = format_date_with_year(event.month, event.day, event.year)
          view("event", locals: { event: event, date_string: date_string })
        else
          date_string = format_date(today)
          view("fallback", locals: { date_string: date_string })
        end
      end
    end

    private

    def format_date(date)
      date.strftime("%B %-d")
    end

    def format_date_with_year(month, day, year)
      Date.new(year, month, day).strftime("%B %-d, %Y")
    end
  end
end
