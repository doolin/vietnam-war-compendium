# frozen_string_literal: true

require "digest"
require "fileutils"
require "time"
require_relative "fetcher"
require_relative "index"
require_relative "wayback"

module ThisDay
  module Archive
    # Fetches a reference URL, stores the bytes locally, uploads them to S3,
    # and records the outcome in the Index. One call per URL.
    #
    # Local cache: <cache_dir>/<url_key>.<ext>  (gitignored)
    # S3 key:      <prefix>/<url_key>/<sha256>.<ext>
    #
    # The S3 client is injectable and may be nil, in which case the upload
    # is skipped and the entry records s3_key: nil. That keeps local audits
    # possible without credentials.
    class Archiver
      DEFAULT_CACHE_DIR = File.expand_path("../../../archive/cache", __dir__)

      attr_reader :index, :fetcher, :wayback, :cache_dir, :bucket, :prefix, :s3_client

      def initialize(index:, fetcher: Fetcher.new, wayback: nil, cache_dir: DEFAULT_CACHE_DIR,
                     bucket: nil, prefix: "this-day/references", s3_client: nil, clock: -> { Time.now.utc })
        @index = index
        @fetcher = fetcher
        @wayback = wayback
        @cache_dir = cache_dir
        @bucket = bucket
        @prefix = prefix
        @s3_client = s3_client
        @clock = clock
      end

      # Archive one URL. Returns the index entry written.
      #
      # When the live fetch fails and a Wayback client is given, the latest
      # 200 capture is archived instead. The entry keeps the original URL as
      # its key, records `via: wayback`, the snapshot URL a reader can open,
      # the capture time, and the live failure as `live_status`.
      def archive(url)
        result = fetcher.fetch(url)
        entry = store(url, result, base_entry(url, result))
        entry = from_wayback(url, entry) if entry["status"] != "ok" && wayback

        index.upsert(entry)
        entry
      end

      # Page titles that mean "a 200 was served to a robot, not the document".
      BOT_WALL_TITLES = /human verification|robot check|access denied|just a moment|are you a human|captcha|\AAmazon\.com\z/i

      private

      # Fill entry from a fetch result: ok (cached and uploaded), bot-wall,
      # or left as the failure base_entry recorded.
      def store(url, result, entry)
        return entry unless result.ok? && result.body && !result.body.empty?

        title = extract_title(result.body, result.content_type)
        return entry.merge("status" => "bot-wall", "title" => title) if bot_wall?(title)

        ext = extension_for(result.content_type, result.final_url)
        sha = Digest::SHA256.hexdigest(result.body)
        entry.merge(
          "status" => "ok",
          "sha256" => sha,
          "bytes" => result.body.bytesize,
          "title" => title,
          "cache_path" => write_cache(url, ext, result.body),
          "s3_key" => upload(url, sha, ext, result.body, result.content_type)
        )
      end

      def from_wayback(url, live_entry)
        capture = wayback.latest_capture(url)
        return live_entry unless capture

        result = fetcher.fetch(capture.raw_url)
        entry = store(url, result, base_entry(url, result))
        return live_entry unless entry["status"] == "ok"

        entry.merge("via" => "wayback", "snapshot_url" => capture.view_url,
                    "captured_at" => capture.captured_at, "live_status" => live_entry["status"])
      end

      def bot_wall?(title)
        !title.nil? && title.match?(BOT_WALL_TITLES)
      end

      def base_entry(url, result)
        status = if result.error then "error"
                 elsif result.ok? then "ok"
                 else "http-#{result.code}"
                 end
        {
          "url" => url,
          "final_url" => result.final_url,
          "status" => status,
          "code" => result.code,
          "content_type" => result.content_type,
          "fetched_at" => @clock.call.iso8601,
          "note" => result.error
        }.compact
      end

      def extension_for(content_type, url)
        case content_type
        when %r{text/html}, %r{application/xhtml} then "html"
        when %r{application/pdf} then "pdf"
        when %r{text/plain} then "txt"
        else
          ext = File.extname(URI.parse(url).path.to_s).delete(".")
          ext.empty? ? "bin" : ext
        end
      end

      def write_cache(url, ext, body)
        FileUtils.mkdir_p(cache_dir)
        path = File.join(cache_dir, "#{Index.url_key(url)}.#{ext}")
        File.binwrite(path, body)
        File.write("#{path}.url", url)
        path
      end

      def upload(url, sha, ext, body, content_type)
        return nil if s3_client.nil? || bucket.nil?

        key = "#{prefix}/#{Index.url_key(url)}/#{sha}.#{ext}"
        s3_client.put_object(bucket: bucket, key: key, body: body,
                             content_type: content_type || "application/octet-stream",
                             metadata: { "source-url" => url })
        key
      end

      def extract_title(body, content_type)
        return nil unless content_type.to_s.include?("html")

        m = body.match(%r{<title[^>]*>(.*?)</title>}mi)
        return nil unless m

        m[1].gsub(/\s+/, " ").strip.encode("UTF-8", invalid: :replace, undef: :replace)[0, 200]
      end
    end
  end
end
