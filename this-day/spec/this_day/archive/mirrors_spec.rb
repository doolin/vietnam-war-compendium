# frozen_string_literal: true

require "spec_helper"
require_relative "../../../lib/this_day/archive/mirrors"

RSpec.describe ThisDay::Archive::Mirrors do
  it "moves Texas Tech report PDFs to the catalog host, keeping the image path" do
    old = "https://www.vietnam.ttu.edu/reports/images.php?img=/images/1683/168300010683.pdf"
    expect(described_class.canonical(old)).to eq("https://vva.vietnam.ttu.edu/images.php?img=/images/1683/168300010683.pdf")
    expect(described_class.canonical(old.sub("https", "http"))).to eq(described_class.canonical(old))
  end

  it "sends Pike's chronology citations to the part of the scan that holds the cited pages" do
    old = "https://www.vietnam.ttu.edu/reports/images.php?img=/images/231/2311404008a.pdf"
    expect(described_class.canonical(old)).to eq("https://vva.vietnam.ttu.edu/images.php?img=/images/231/2311404008c.pdf")
  end

  it "leaves every other URL alone" do
    url = "https://www.vietnam.ttu.edu/virtualarchive/items.php?item=15120105018"
    expect(described_class.canonical(url)).to eq(url)
    expect(described_class.canonical("https://history.state.gov/x")).to eq("https://history.state.gov/x")
  end
end
