# This Day in Viet Nam

A lightweight web service that serves a single HTML page describing what happened
on the current date during the Vietnam War. Built with Ruby, Roda, and SQLite3;
deployed to AWS Lambda behind CloudFront.

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

Infrastructure is managed by Terraform (separate repo). Deployment uses Docker
to bundle gems for Lambda's x86_64 Linux environment, then uploads to S3 and
updates the Lambda function.

### Prerequisites

- Docker (for cross-compiling native gems)
- AWS CLI configured with appropriate credentials
- The build directory uses `/tmp/this-day-build` because Docker Desktop's
  file sharing doesn't include home directories by default on macOS

### Full deploy (recommended)

```sh
bundle exec rake deploy:all
```

This runs all four steps in order: build database, build zip, push to Lambda,
invalidate CloudFront.

### Manual step-by-step

1. **Build the database** from YAML event files:
   ```sh
   bundle exec rake db:build
   ```

2. **Build the deployment zip** (bundles gems via Docker, packages app + db):
   ```sh
   bundle exec rake deploy:build
   ```
   This copies the app to `/tmp/this-day-build`, runs `bundle install` inside
   a Docker container matching Lambda's runtime, and creates `/tmp/this-day-deploy.zip`.

3. **Push to Lambda** (upload zip to S3, update function code):
   ```sh
   bundle exec rake deploy:push
   ```

4. **Invalidate CloudFront cache**:
   ```sh
   bundle exec rake deploy:invalidate
   ```

### Manual AWS CLI commands (no Rake)

```sh
# Upload zip to S3
aws s3 cp /tmp/this-day-deploy.zip \
  s3://this-day-in-vietnam-war-deployments/this-day-deploy.zip \
  --region us-west-1

# Update Lambda function code
aws lambda update-function-code \
  --function-name this-day-in-vietnam-war \
  --s3-bucket this-day-in-vietnam-war-deployments \
  --s3-key this-day-deploy.zip \
  --region us-west-1

# Wait for update to complete
aws lambda wait function-updated \
  --function-name this-day-in-vietnam-war \
  --region us-west-1

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id ERIW60YQ29CKU \
  --paths '/this-day-in-vietnam*'
```

### Deployment constants

| Resource             | Value                                    |
|----------------------|------------------------------------------|
| Lambda function      | `this-day-in-vietnam-war`                |
| S3 bucket            | `this-day-in-vietnam-war-deployments`    |
| S3 key               | `this-day-deploy.zip`                    |
| AWS region           | `us-west-1`                              |
| CloudFront dist ID   | `ERIW60YQ29CKU`                          |
| CloudFront path      | `/this-day-in-vietnam*`                  |
| Docker image         | `public.ecr.aws/sam/build-ruby3.3:latest-x86_64` |
| Build directory      | `/tmp/this-day-build`                    |

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
├── app.rb              # Lambda entry point (lamby)
├── config.ru           # Rack entry point
└── template.yaml       # SAM template (build-only)
```
