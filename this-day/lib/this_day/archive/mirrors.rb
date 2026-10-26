# frozen_string_literal: true

module ThisDay
  module Archive
    # Cited URLs that are better fetched and cited at another address that
    # serves the same file. Texas Tech's www.vietnam.ttu.edu/reports/
    # images.php times out on every request; the archive's catalog host
    # serves the same PDFs at the same image path (checked 2026-10-26 with
    # the Pike "Viet Cong Strategy of Terror" PDF).
    module Mirrors
      RULES = [
        [%r{\Ahttps?://www\.vietnam\.ttu\.edu/reports/images\.php\?img=}, "https://vva.vietnam.ttu.edu/images.php?img="]
      ].freeze

      # Pike's "Viet Cong Strategy of Terror" is scanned in three files.
      # Wikipedia cites part a for its incident chronology, pp. 93-115;
      # part a ends at printed p. 51 and part c holds pp. 90-125.
      PARTS = {
        "https://vva.vietnam.ttu.edu/images.php?img=/images/231/2311404008a.pdf" =>
          "https://vva.vietnam.ttu.edu/images.php?img=/images/231/2311404008c.pdf"
      }.freeze

      module_function

      def canonical(url)
        moved = RULES.reduce(url.to_s) { |u, (pattern, replacement)| u.sub(pattern, replacement) }
        moved = PARTS.fetch(moved, moved)
        moved == url.to_s ? url : moved
      end
    end
  end
end
