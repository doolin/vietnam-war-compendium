# This Day in Viet Nam

A lightweight web service that serves a single HTML page describing what happened
on the current date during the Vietnam War. Built with Ruby, Roda, and SQLite3;
deployed to AWS Lambda via SAM.

See [PRD-0001](docs/prds/PRD-0001-this-day-in-vietnam.md) and
[ADR-001](docs/adrs/ADR-001-lambda-sqlite-architecture.md) for full requirements
and architecture decisions.

## Prerequisites

- Ruby (>= 3.2; development uses whatever is current, Lambda uses 3.4)
- Bundler
- SQLite3

## Setup

```sh
bundle install
```

## Build the database

Event data lives in YAML files under `data/events/`. Build the SQLite3 database:

```sh
bundle exec rake db:build
```

For a quick test database with sample data:

```sh
bundle exec rake db:build_test
```

## Run locally

```sh
bundle exec rackup
```

The app serves at `http://localhost:9292`.

To use the test database instead of the production one:

```sh
THIS_DAY_DB_PATH=db/test.sqlite3 bundle exec rackup
```

## Run tests

```sh
bundle exec rspec
```

## Adding events

Create or edit YAML files in `data/events/`. Each file contains an array of
event hashes:

```yaml
- month: 3
  day: 8
  year: 1965
  title: "U.S. Marines land at Da Nang"
  body: "<p>The 9th Marine Expeditionary Brigade waded ashore...</p>"
  photo_url:
  photo_alt:
  references:
    - label: "Source title"
      url: "https://example.com"
```

After editing, rebuild the database with `rake db:build`.

## Deploy to AWS

Requires AWS SAM CLI and Docker (for building native extensions):

```sh
sam build --use-container
sam deploy --guided   # first time
sam deploy            # subsequent deploys
```

## Project structure

```
this-day/
├── lib/this_day/
│   ├── app.rb          # Roda application
│   ├── database.rb     # SQLite3 queries
│   └── version.rb
├── views/              # ERB templates
├── db/                 # Schema and seed script
├── data/events/        # YAML event source files
├── spec/               # RSpec tests
├── bin/handler.rb      # Lambda entry point (lamby)
├── config.ru           # Rack entry point
└── template.yaml       # SAM template
```
