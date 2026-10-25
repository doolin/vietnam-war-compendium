# frozen_string_literal: true

require "net/http"
require "uri"
require "openssl"

module ThisDay
  module Archive
    # Polite HTTP fetcher for reference archiving.
    #
    # One request at a time per host, with a configurable delay between
    # requests to the same host. Follows redirects. Returns a Result with
    # the final URL, status code, body bytes, and content type. Never
    # raises on HTTP errors: a 404 or 503 is a Result with that code, so
    # the archiver can record the failure.
    #
    # The HTTP call is injectable (`http:`) so specs never touch the network.
    class Fetcher
      USER_AGENT = "VietnamWarCompendium/1.0 (historical research; reference archiving)"
      MAX_REDIRECTS = 5

      Result = Struct.new(:url, :final_url, :code, :body, :content_type, :error, keyword_init: true) do
        def ok? = code.to_i.between?(200, 299) && error.nil?
      end

      attr_reader :delay

      def initialize(delay: 3, http: nil, sleeper: nil)
        @delay = delay
        @http = http || method(:net_http_get)
        @sleeper = sleeper || ->(seconds) { sleep(seconds) }
        @last_request_at = {}
      end

      def fetch(url)
        wait_for_host(url)
        follow(url, url, MAX_REDIRECTS)
      rescue StandardError => e
        Result.new(url: url, final_url: url, code: 0, body: nil, content_type: nil, error: "#{e.class}: #{e.message}")
      end

      private

      def follow(original, url, redirects_left)
        return Result.new(url: original, final_url: url, code: 0, body: nil, content_type: nil, error: "too many redirects") if redirects_left.zero?

        code, headers, body = @http.call(url)
        if code.to_i.between?(300, 399) && headers["location"]
          location = URI.join(url, headers["location"]).to_s
          wait_for_host(location)
          return follow(original, location, redirects_left - 1)
        end

        Result.new(url: original, final_url: url, code: code.to_i, body: body,
                   content_type: (headers["content-type"] || "").split(";").first&.strip, error: nil)
      end

      def wait_for_host(url)
        host = URI.parse(url).host
        last = @last_request_at[host]
        if last
          elapsed = Time.now - last
          @sleeper.call(delay - elapsed) if elapsed < delay
        end
        @last_request_at[host] = Time.now
      end

      def net_http_get(url)
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER if http.use_ssl?
        http.open_timeout = 15
        http.read_timeout = 60

        request = Net::HTTP::Get.new(uri.request_uri)
        request["User-Agent"] = USER_AGENT
        request["Accept"] = "text/html,application/pdf,*/*;q=0.8"
        response = http.request(request)
        headers = { "location" => response["location"], "content-type" => response["content-type"] }
        [response.code, headers, response.body]
      end
    end
  end
end
