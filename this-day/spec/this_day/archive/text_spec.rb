# frozen_string_literal: true

require "spec_helper"
require_relative "../../../lib/this_day/archive/text"

RSpec.describe ThisDay::Archive::Text do
  it "drops scripts, styles, and tags and keeps paragraph breaks" do
    html = "<html><head><style>p{}</style><script>var x=1;</script></head>" \
           "<body><h1>Title</h1><p>First &amp; second.</p><p>Third</p></body></html>"
    expect(described_class.from_html(html)).to eq("Title\nFirst & second.\nThird")
  end

  it "returns nil for a PDF it cannot read" do
    expect(described_class.from_pdf("/nonexistent/file.pdf")).to be_nil
  end

  describe ".date_lines" do
    let(:text) do
      "=== page 1 ===\nOn 4 January the battalion moved.\nJanuary 14 was quiet.\n" \
        "=== page 2 ===\nBy Jan. 4th it had arrived.\nThe 14 Jan 66 report.\nOn 4 Feb nothing.\n"
    end

    it "finds day-month and month-day forms, with line number and page" do
      expect(described_class.date_lines(text, 1, 4)).to eq(
        [[2, 1, "On 4 January the battalion moved."], [5, 2, "By Jan. 4th it had arrived."]]
      )
    end

    it "does not match a day that is a prefix or suffix of another" do
      expect(described_class.date_lines(text, 1, 14).map(&:first)).to eq([3, 6])
      expect(described_class.date_lines(text, 1, 1)).to be_empty
    end
  end
end
