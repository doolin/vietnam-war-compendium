# frozen_string_literal: true

require "yaml"
require_relative "index"

module ThisDay
  module Archive
    # Compares the references in the event YAML files against the archive
    # index and reports what is unverified.
    #
    # Findings, each a Hash with :kind, :file, :title, :label, :url, :detail:
    #   :missing   — URL has no index entry (never fetched)
    #   :failed    — index entry exists but status is not ok
    #   :mismatch  — fetched page title shares no significant word with the label
    class Audit
      STOPWORDS = %w[the a an of and or in on at by to for with from vietnam viet nam war history
                     national archives citation medal honor recipient recipients].freeze

      Finding = Struct.new(:kind, :file, :title, :label, :url, :detail, keyword_init: true)

      attr_reader :index, :events_dir

      def initialize(index:, events_dir:)
        @index = index
        @events_dir = events_dir
      end

      # Every (file, event title, reference) triple in the event files.
      def references
        Dir.glob(File.join(events_dir, "*.yaml")).sort.flat_map do |file|
          events = YAML.safe_load_file(file, permitted_classes: [Date]) || []
          events.flat_map do |evt|
            Array(evt["references"]).map do |ref|
              { file: File.basename(file), title: evt["title"], label: ref["label"], url: ref["url"] }
            end
          end
        end
      end

      def urls
        references.map { |r| r[:url] }.compact.uniq
      end

      def unarchived_urls
        urls.reject { |u| index.archived?(u) }
      end

      def findings
        references.filter_map do |ref|
          entry = index[ref[:url]]
          if entry.nil?
            Finding.new(kind: :missing, detail: "never fetched", **ref)
          elsif entry["status"] != "ok"
            Finding.new(kind: :failed, detail: "#{entry['status']} #{entry['note']}".strip, **ref)
          elsif entry["title"] && !label_matches_title?(ref[:label], entry["title"])
            Finding.new(kind: :mismatch, detail: "page title: #{entry['title']}", **ref)
          end
        end
      end

      def summary
        all = references
        by_kind = findings.group_by(&:kind).transform_values(&:size)
        {
          references: all.size,
          unique_urls: urls.size,
          archived: urls.count { |u| index.archived?(u) },
          missing: by_kind[:missing] || 0,
          failed: by_kind[:failed] || 0,
          mismatch: by_kind[:mismatch] || 0
        }
      end

      def label_matches_title?(label, title)
        l = significant_words(label)
        t = significant_words(title)
        return true if l.empty? || t.empty?

        (l & t).any?
      end

      private

      def significant_words(text)
        text.to_s.downcase.scan(/[a-z0-9]{3,}/) - STOPWORDS
      end
    end
  end
end
