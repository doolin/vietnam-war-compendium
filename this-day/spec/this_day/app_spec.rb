# frozen_string_literal: true

require "spec_helper"

# Set the test DB path before loading the app
ENV["THIS_DAY_DB_PATH"] = TestDatabaseHelper::TEST_DB_PATH

require_relative "../../lib/this_day/app"

RSpec.describe ThisDay::App do
  include Rack::Test::Methods

  SNAPSHOT = "https://web.archive.org/web/20161123144448/http://old.example.com/report.pdf"
  MOVED_REPORT = { label: "Moved report", url: "http://old.example.com/report.pdf", archive_status: "ok",
                   archived_at: "2026-10-26T01:00:00Z", snapshot_url: SNAPSHOT }.freeze

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
        { label: "Test Reference", url: "https://example.com/ref",
          archive_status: "ok", archived_at: "2026-10-25T18:02:11Z" },
        { label: "Another Reference", url: "https://example.com/ref2" },
        MOVED_REPORT
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
        { label: "Photo Source", url: "https://example.com/photo-source",
          archive_status: "ok", archived_at: "2026-10-25T18:02:11Z" },
        { label: "Dead Source", url: "https://example.com/dead", archive_status: "http-404" },
        MOVED_REPORT
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

    it "marks each reference as archived or unverified" do
      get "/"
      expect(last_response.body).to include('class="archive-status archived"')
      expect(last_response.body).to include("archived 2026-10-25")
      expect(last_response.body).to include('class="archive-status unverified"')
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

  describe "GET /this-day-in-vietnam-war with and without a trailing slash" do
    it "serves today's event on both forms" do
      ["/this-day-in-vietnam-war", "/this-day-in-vietnam-war/"].each do |path|
        get path
        expect(last_response.status).to eq(200), "#{path} returned #{last_response.status}"
        expect(last_response.body).to include("Something happened on this day").or include("Another event for the same date")
      end
    end
  end

  describe "GET /this-day-in-vietnam-war/review/:month" do
    # A month other than today's, so the "today" seeds above do not land in it.
    REVIEW_MONTH = Date.today.month == 4 ? 5 : 4
    let(:month) { REVIEW_MONTH }
    let(:days_in_month) { Date.new(2000, month, -1).day }

    before(:all) do
      month = REVIEW_MONTH
      db = SQLite3::Database.new(TestDatabaseHelper::TEST_DB_PATH)
      TestDatabaseHelper.seed_event(
        db, month: month, day: 3, year: 1966, title: "Review draft", body: "<p>Draft body.</p>",
        status: "draft", source_text: "Excerpt from the source.", source_file: "drafts.yaml",
        summarized_by: "Claude Fable 5.1", summarized_at: "2026-10-25T19:00:00Z",
        references: [
          { label: "Dead link", url: "https://example.com/404", archive_status: "http-404" },
          MOVED_REPORT
        ]
      )
      TestDatabaseHelper.seed_event(
        db, month: month, day: 3, year: 1970, title: "Review rejected", body: "<p>No.</p>", status: "rejected"
      )
      db.close
      described_class.reset_database!
    end

    it "lists every day of the month with its events and statuses" do
      get "/this-day-in-vietnam-war/review/#{month}"
      expect(last_response.status).to eq(200)
      body = last_response.body
      expect(body).to include("Review &mdash; #{Date::MONTHNAMES[month]}")
      expect(body).to include('id="day-1"')
      expect(body).to include(%(id="day-#{days_in_month}"))
      expect(body).to include("Review draft")
      expect(body).to include('class="badge draft"')
      expect(body).to include("Review rejected")
      expect(body).to include('class="badge rejected"')
      expect(body).to include("Excerpt from the source.")
      expect(body).to include("unverified (http-404)")
      expect(body).to include("drafts.yaml")
      expect(body).to include("Summary by Claude Fable 5.1, 2026-10-25")
      expect(body).to include("unattributed summary")
      expect(body.scan('class="badge missing"').size).to eq(days_in_month - 1)
      expect(body).to include("1 of #{days_in_month} days have an event")
      expect(body).to include("1 drafts awaiting review")
    end

    it "does not serve a draft on the day page" do
      get "/this-day-in-vietnam-war/#{month}/3"
      expect(last_response.body).not_to include("Draft body.")
    end

    it "links the Wayback copy of a reference archived from the Wayback Machine" do
      get "/this-day-in-vietnam-war/review/#{month}"
      expect(last_response.body).to include(%(href="#{SNAPSHOT}")).and include("Wayback copy")
      get "/"
      expect(last_response.body).to include(%(href="#{SNAPSHOT}"))
    end

    it "returns 404 for a month outside 1-12" do
      get "/this-day-in-vietnam-war/review/13"
      expect(last_response.status).to eq(404)
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
