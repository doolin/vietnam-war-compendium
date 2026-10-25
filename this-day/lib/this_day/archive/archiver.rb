# frozen_string_literal: true

require "digest"
require "fileutils"
require "time"
require_relative "fetcher"
require_relative "index"

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

      attr_reader :index, :fetcher, :cache_dir, :bucket, :prefix, :s3_client

      def initialize(index:, fetcher: Fetcher.new, cache_dir: DEFAULT_CACHE_DIR,
                     bucket: nil, prefix: "this-day/references", s3_client: nil, clock: -> { Time.now.utc })
        @index = index
        @fetcher = fetcher
        @cache_dir = cache_dir
        @bucket = bucket
        @prefix = prefix
        @s3_client = s3_client
        @clock = clock
      end

      # Archive one URL. Returns the index entry written.
      def archive(url)
        result = fetcher.fetch(url)
        entry = base_entry(url, result)

        if result.ok? && result.body && !result.body.empty?
          ext = extension_for(result.content_type, result.final_url)
          sha = Digest::SHA256.hexdigest(result.body)
          cache_path = write_cache(url, ext, result.body)
          entry.merge!(
            "status" => "ok",
            "sha256" => sha,
            "bytes" => result.body.bytesize,
            "title" => extract_title(result.body, result.content_type),
            "cache_path" => cache_path,
            "s3_key" => upload(url, sha, ext, result.body, result.content_type)
          )
        end

        index.upsert(entry)
        entry
      end

      private

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
