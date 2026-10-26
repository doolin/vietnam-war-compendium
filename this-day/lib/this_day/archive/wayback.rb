# frozen_string_literal: true

require "uri"
require_relative "fetcher"

module ThisDay
  module Archive
    # Finds the most recent Wayback Machine capture of a URL that the
    # Wayback Machine itself recorded as a 200, through the CDX API.
    #
    # The availability API (archive.org/wayback/available) rate-limits
    # hard and returns the closest capture whatever its status, so a dead
    # page's recent 404 capture comes back. CDX filters on status.
    #
    # Capture#raw_url serves the original bytes (the `id_` flag strips the
    # Wayback toolbar); Capture#view_url is the page a reader should open.
    class Wayback
      CDX = "https://web.archive.org/cdx/search/cdx"

      Capture = Struct.new(:timestamp, :original, keyword_init: true) do
        def raw_url = "https://web.archive.org/web/#{timestamp}id_/#{original}"
        def view_url = "https://web.archive.org/web/#{timestamp}/#{original}"

        # "20161123144448" -> "2016-11-23T14:44:48Z"
        def captured_at
          t = timestamp
          "#{t[0, 4]}-#{t[4, 2]}-#{t[6, 2]}T#{t[8, 2]}:#{t[10, 2]}:#{t[12, 2]}Z"
        end
      end

      def initialize(fetcher: Fetcher.new)
        @fetcher = fetcher
      end

      # The latest 200 capture, or nil when there is none or CDX fails.
      def latest_capture(url)
        query = URI.encode_www_form(url: url, filter: "statuscode:200", limit: -1, fl: "timestamp,original")
        result = @fetcher.fetch("#{CDX}?#{query}")
        return nil unless result.ok?

        timestamp, original = result.body.to_s.lines.last&.split
        return nil unless timestamp&.match?(/\A\d{14}\z/) && original

        Capture.new(timestamp: timestamp, original: original)
      end
    end
  end
end
