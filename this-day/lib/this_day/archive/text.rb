# frozen_string_literal: true

require "cgi"
require "date"
require "open3"

module ThisDay
  module Archive
    # Plain text from an archived copy, for a writer to read and quote.
    # HTML loses scripts, styles, and tags; PDFs go through pdftotext with
    # a "=== page N ===" line before each page so passages can be cited
    # by page.
    module Text
      module_function

      def from_html(html)
        s = html.to_s.encode("UTF-8", invalid: :replace, undef: :replace)
        s = s.gsub(%r{<(script|style|noscript)[^>]*>.*?</\1>}mi, " ")
        s = s.gsub(/<!--.*?-->/m, " ")
        s = s.gsub(%r{<(br|/p|/div|/h\d|/li|/tr)[^>]*>}i, "\n")
        s = CGI.unescapeHTML(s.gsub(/<[^>]+>/, " "))
        s.gsub(/[ \t ]+/, " ").gsub(/ *\n */, "\n").gsub(/\n{3,}/, "\n\n").strip
      end

      # nil when pdftotext is missing or fails.
      def from_pdf(path)
        out, _err, status = Open3.capture3("pdftotext", "-enc", "UTF-8", path, "-")
        return nil unless status.success?

        out.split("\f").each_with_index.map { |page, i| "=== page #{i + 1} ===\n#{page.strip}" }.join("\n\n")
      rescue Errno::ENOENT
        nil
      end

      # The lines that name a calendar date, as [line number, PDF page or
      # nil, line], so a writer without a search tool can Read the passage
      # by offset. Matches "4 January", "January 4", "Jan. 4th", "4 Jan 66".
      def date_lines(text, month, day)
        names = [Date::MONTHNAMES[month], Date::ABBR_MONTHNAMES[month]]
        names << "Sept" if month == 9
        name = "(?:#{names.join('|')})\\.?"
        pattern = /(?<!\d)#{day}(?:st|nd|rd|th)?\s+#{name}\b|\b#{name}\s+#{day}(?:st|nd|rd|th)?(?!\d)/i
        page = nil
        text.to_s.each_line.with_index(1).filter_map do |line, n|
          page = Regexp.last_match(1).to_i if line =~ /\A=== page (\d+) ===/
          [n, page, line.strip] if line.match?(pattern)
        end
      end
    end
  end
end
