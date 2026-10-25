# frozen_string_literal: true

require "yaml"
require "digest"
require "fileutils"

module ThisDay
  module Archive
    # The committed record of every reference URL that has been archived.
    #
    # One entry per URL, keyed by the URL string. Stored as a YAML array
    # sorted by URL so diffs stay readable. Fields:
    #
    #   url, final_url, status (ok | http-<code> | error), code, sha256,
    #   bytes, content_type, title, fetched_at, cache_path, s3_key, note
    class Index
      DEFAULT_PATH = File.expand_path("../../../data/archive/index.yaml", __dir__)

      attr_reader :path

      def initialize(path = DEFAULT_PATH)
        @path = path
        @entries = load
      end

      def [](url)
        @entries[url]
      end

      def include?(url)
        @entries.key?(url)
      end

      def archived?(url)
        entry = @entries[url]
        !entry.nil? && entry["status"] == "ok"
      end

      def upsert(entry)
        url = entry.fetch("url")
        @entries[url] = (@entries[url] || {}).merge(entry)
        self
      end

      def entries
        @entries.values.sort_by { |e| e["url"] }
      end

      def size = @entries.size

      def save
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, entries.to_yaml)
        self
      end

      def self.url_key(url)
        Digest::SHA256.hexdigest(url)[0, 16]
      end

      private

      def load
        return {} unless File.exist?(path)

        data = YAML.safe_load_file(path, permitted_classes: [Time, Date]) || []
        data.each_with_object({}) { |e, h| h[e["url"]] = e }
      end
    end
  end
end
