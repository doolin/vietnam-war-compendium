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
end
