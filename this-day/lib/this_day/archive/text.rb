# frozen_string_literal: true

require "cgi"
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
    end
  end
end
