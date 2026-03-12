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
      today = Date.today
      view("fallback", locals: { date_string: format_date(today),
                                 prev_date: today - 1, next_date: today + 1 })
    end

    status_handler(500) do
      "<h1>Something went wrong</h1><p>Please try again later.</p>"
    end

    route do |r|
      r.root do
        serve_date(Date.today)
      end

      r.on "this-day-in-vietnam-war" do
        r.get String, String do |month, day|
          date = Date.new(Date.today.year, month.to_i, day.to_i)
          serve_date(date)
        rescue ArgumentError
          response.status = 404
          view("fallback", locals: { date_string: "Invalid date" })
        end

        r.get true do
          serve_date(Date.today)
        end
      end
    end

    private

    def serve_date(date)
      event = self.class.database.event_for_date(date.month, date.day)
      prev_date = date - 1
      next_date = date + 1

      if event
        date_string = format_date_with_year(event.month, event.day, event.year)
        view("event", locals: { event: event, date_string: date_string,
                                prev_date: prev_date, next_date: next_date })
      else
        date_string = format_date(date)
        view("fallback", locals: { date_string: date_string,
                                   prev_date: prev_date, next_date: next_date })
      end
    end

    def date_path(date)
      "/this-day-in-vietnam-war/#{date.month}/#{date.day}"
    end

    def format_date(date)
      date.strftime("%B %-d")
    end

    def format_date_with_year(month, day, year)
      Date.new(year, month, day).strftime("%B %-d, %Y")
    end
  end
end
