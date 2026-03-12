# frozen_string_literal: true

require "spec_helper"

# Set the test DB path before loading the app
ENV["THIS_DAY_DB_PATH"] = TestDatabaseHelper::TEST_DB_PATH

require_relative "../../lib/this_day/app"

RSpec.describe ThisDay::App do
  include Rack::Test::Methods

  def app
    described_class.app
  end

  before(:all) do
    db = TestDatabaseHelper.build_test_db

    today = Date.today
    TestDatabaseHelper.seed_event(
      db,
      month: today.month, day: today.day, year: 1968,
      title: "Test event for today",
      body: "<p>Something happened on this day during the Vietnam War.</p>",
      references: [
        { label: "Test Reference", url: "https://example.com/ref" },
        { label: "Another Reference", url: "https://example.com/ref2" }
      ]
    )

    TestDatabaseHelper.seed_event(
      db,
      month: today.month, day: today.day, year: 1965,
      title: "Second event for today",
      body: "<p>Another event for the same date.</p>",
      photo_url: "https://example.com/photo.jpg",
      photo_alt: "A historical photograph",
      references: [
        { label: "Photo Source", url: "https://example.com/photo-source" }
      ]
    )

    db.close
    described_class.reset_database!
  end

  after(:all) do
    described_class.reset_database!
  end

  describe "GET /" do
    it "returns 200" do
      get "/"
      expect(last_response.status).to eq(200)
    end

    it "returns HTML content type" do
      get "/"
      expect(last_response.content_type).to include("text/html")
    end

    it "displays the heading in the correct format" do
      get "/"
      today = Date.today
      expect(last_response.body).to include("This Day in Viet Nam")
      expect(last_response.body).to include(today.strftime("%B %-d"))
    end

    it "contains no external stylesheet links" do
      get "/"
      expect(last_response.body).not_to match(/<link[^>]+rel=["']stylesheet["'][^>]+href=["']http/)
    end

    it "contains no external script sources" do
      get "/"
      expect(last_response.body).not_to match(/<script[^>]+src=["']http/)
    end

    it "contains no external font references" do
      get "/"
      expect(last_response.body).not_to match(/fonts\.googleapis\.com/)
    end

    it "includes reference links" do
      get "/"
      expect(last_response.body).to include("<a href=")
      expect(last_response.body).to include("References")
    end

    it "uses semantic HTML with a main element" do
      get "/"
      expect(last_response.body).to include("<main>")
      expect(last_response.body).to include("</main>")
    end

    it "includes a viewport meta tag for mobile responsiveness" do
      get "/"
      expect(last_response.body).to include('name="viewport"')
    end

    it "has a proper heading hierarchy" do
      get "/"
      expect(last_response.body).to include("<h1>")
    end
  end

  describe "HEAD /" do
    it "returns 200 with no body" do
      head "/"
      expect(last_response.status).to eq(200)
      expect(last_response.body).to be_empty
    end
  end
end
