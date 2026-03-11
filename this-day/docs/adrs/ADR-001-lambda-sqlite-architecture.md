---
id: ADR-001
title: Use Ruby/Roda on AWS Lambda with bundled SQLite3 for serving daily history pages
status: Proposed
date: 2026-03-11
authors: [David Doolin]
owner: David Doolin
reviewers: []
approvers: []
decision_type: Technical
impact_level: Medium
urgency: Low
supersedes:
superseded_by:
related_documents:
  adrs: []
  prds: [PRD-0001]
  design_docs: []
  tickets: []
  incidents: []
  runbooks: []
  policies_standards_controls: []
target_effective_date:
target_review_date:
last_reviewed_date:
version: "0.2"
change_log:
  - date: 2026-03-11
    version: "0.1"
    author: David Doolin
    summary: Stub created from PRD-0001
  - date: 2026-03-11
    version: "0.2"
    author: David Doolin
    summary: Full technical decisions drafted
---

# ADR-001: Use Ruby/Roda on AWS Lambda with bundled SQLite3 for serving daily history pages

## 1. Executive Summary

### 1.1 One-Paragraph Summary

The "This Day in Viet Nam" service will be a Ruby application using the Roda web framework, deployed to AWS Lambda via a zip package using the lamby gem as the Rack-to-Lambda bridge. Event data is stored in a SQLite3 database file built out of band and bundled with the deployment package. The application renders server-side HTML using ERB templates. Locally, the application runs via `rackup`. The project is structured as a Ruby gem where possible. CloudFront handles custom domain routing, TLS, and caching in front of the Lambda function URL.

### 1.2 Intended Reader

Engineers, future maintainers.

### 1.3 Decision Request

Approval of the runtime, framework, data, deployment, and infrastructure choices described below.

---

## 2. Context

### 2.1 Problem Statement

PRD-0001 defines a lightweight web service that serves a single HTML page for today's date during the Vietnam War. This ADR decides the specific technology stack, packaging, deployment mechanism, and infrastructure topology.

### 2.2 Current State

No implementation exists. The vietnam-war-compendium repository contains timeline YAML and Kindle highlights that will serve as source material for event data.

### 2.3 Trigger

PRD-0001 requires these technical decisions before implementation can begin.

### 2.4 Scope of Decision

This ADR covers:
- Programming language and runtime version
- Web framework and routing
- Template engine
- Database engine and data lifecycle
- Lambda packaging and deployment tooling
- Local development approach
- AWS infrastructure requirements (Lambda, CloudFront, IAM)
- Project structure

### 2.5 Out of Scope

- Event content authoring workflow
- Visual design and CSS
- CI/CD pipeline
- Monitoring and alerting configuration

### 2.6 Assumptions

- AWS Lambda Ruby runtime will continue to be supported and updated
- The SQLite3 database will remain small (< 1 MB) for the foreseeable future
- Traffic will be low enough that default Lambda concurrency is sufficient

### 2.7 Constraints

- Solo developer
- Near-zero AWS cost (free tier or minimal spend)
- Must run locally for development and testing without Lambda emulation

---

## 3. Decision Drivers

| Driver | Priority | Notes |
|--------|----------|-------|
| Simplicity | High | Solo project; minimize moving parts |
| Cost | High | Free tier or near-zero |
| Developer familiarity | High | Ruby is the preferred language |
| Cold start performance | Medium | DB < 1 MB keeps cold starts fast |
| Operability | Medium | CloudWatch defaults are sufficient initially |
| Portability | Low | Lambda-specific packaging is acceptable |

---

## 4. Decision Statement

**We will** build the service as a Ruby gem using Roda with ERB templates, deploy it to AWS Lambda as a zip package via AWS SAM, use lamby as the Rack-to-Lambda adapter, bundle a pre-built SQLite3 database file with the deployment, and place CloudFront in front of the Lambda function URL to provide the custom domain `clubstraylight.com/this-day-in-vietnam`.

---

## 5. Detailed Decision

### 5.1 Runtime and Language

- **Language:** Ruby
- **Version:** Latest available in the AWS Lambda managed runtime (currently Ruby 3.4)
- **Version management:** Track Lambda runtime updates; pin in SAM template

### 5.2 Web Framework

- **Framework:** Roda
- **Rationale:** Lightweight, Rack-based, fast, minimal overhead. Well-suited to a single-route application.
- **Roda plugins:**
  - `render` — ERB template rendering
  - `head` — proper HEAD request handling
  - `status_handler` — custom error pages (404, 500)
  - `typecast_params` — parameter handling if date overrides are added later

### 5.3 Lambda-Rack Bridge

- **Gem:** lamby (v6.x)
- **Rationale:** Actively maintained, supports Ruby 3.4, works with any Rack application. Handles API Gateway and Lambda function URL event translation to Rack env.

### 5.4 Template Engine

- **Engine:** ERB (stdlib)
- **Rationale:** No additional dependencies. Sufficient for a single-page application with embedded CSS.

### 5.5 Database

- **Engine:** SQLite3 via the `sqlite3` gem
- **Database file:** Built out of band (Rake task or script processing YAML source data) and committed to the repository or built as a deployment artifact
- **Loading:** Opened read-only at application boot; persists in memory for the lifetime of the Lambda execution environment
- **Schema:** Single `events` table with columns mapping to the PRD-0001 data model (month, day, year, title, body, photo_url, photo_alt); references stored in a separate `references` table with a foreign key to events
- **Native extensions:** The `sqlite3` gem requires compilation against Amazon Linux. AWS SAM handles this via `sam build` which builds in a Lambda-compatible Docker container.

### 5.6 Project Structure

The project follows Ruby gem conventions where possible. Deviations are noted.

```
this-day/
├── Gemfile
├── Gemfile.lock
├── Rakefile
├── config.ru                    # Rack entry point (local + Lambda)
├── template.yaml                # SAM template (deviation: not standard gem structure)
├── lib/
│   └── this_day/
│       ├── app.rb               # Roda application class
│       ├── database.rb          # SQLite3 connection and query logic
│       └── version.rb
├── views/
│   ├── layout.erb               # HTML shell with embedded CSS
│   ├── event.erb                # Event display template
│   └── fallback.erb             # No-event-for-today template
├── db/
│   ├── schema.sql               # SQLite3 schema definition
│   ├── seed.rb                  # Rake-invoked script to build the DB from YAML
│   └── this_day.sqlite3         # Built artifact (may be .gitignored)
├── spec/                        # RSpec tests
│   ├── spec_helper.rb
│   ├── this_day/
│   │   ├── app_spec.rb
│   │   └── database_spec.rb
│   └── features/                # Cucumber/Gherkin acceptance tests
├── bin/
│   └── handler.rb               # Lambda entry point (deviation: lamby handler)
└── this_day.gemspec             # (optional) gem specification
```

**Deviations from standard gem structure:**
- `template.yaml` — SAM deployment descriptor, not part of a gem
- `bin/handler.rb` — Lambda-specific entry point required by lamby
- `db/` — database build artifacts, not standard gem convention
- `views/` — ERB templates at project root rather than under `lib/`

### 5.7 Deployment

- **Tooling:** AWS SAM CLI
- **Package type:** Zip
- **Build process:** `sam build` compiles native extensions (sqlite3) in a Lambda-compatible Docker container, bundles the application and the pre-built SQLite3 database file
- **Deploy process:** `sam deploy` uploads the zip to S3 and updates the Lambda function
- **Future:** If SAM proves too difficult with native gems or Ruby 4 changes the landscape, migrate to a Docker container image deployed via ECR

### 5.8 Local Development

- **Server:** `rackup` (Puma or WEBrick via Gemfile)
- **Database:** Same SQLite3 file used in production, opened read-only
- **No Lambda emulation required** — the Roda app is a standard Rack application; lamby is only invoked in the Lambda handler path

### 5.9 AWS Infrastructure Requirements

The following AWS resources are required. Configuration and provisioning are handled outside this codebase (SAM template, CloudFront console, or separate IaC).

#### Lambda Function
- **Runtime:** Ruby 3.4 (managed runtime)
- **Handler:** `bin/handler.handler` (lamby convention)
- **Memory:** 128 MB (sufficient for < 1 MB database + Roda)
- **Timeout:** 10 seconds
- **Provisioned concurrency:** None (accept default cold start behavior)
- **Function URL:** Enabled, used as CloudFront origin

#### CloudFront
- **Distribution:** Serves `clubstraylight.com` with the Lambda function URL as origin
- **Path pattern:** `/this-day-in-vietnam` routed to the Lambda origin
- **TLS:** ACM certificate for `clubstraylight.com`
- **Caching:** TTL appropriate for daily content (e.g., cache until midnight UTC, or short TTL with manual invalidation on deploy)

#### IAM
- **Lambda execution role:** Minimal permissions — CloudWatch Logs only
- **No S3, DynamoDB, or other service access required initially**

#### IP Restriction and Throttling
- **Not implemented in application code**
- **Handled at AWS level:** CloudFront geographic restrictions if needed, Lambda reserved concurrency as a throttle backstop, AWS WAF if abuse occurs

#### Monitoring
- **CloudWatch Logs:** Lambda function logs (automatic)
- **CloudWatch Metrics:** Invocation count, error count, duration (automatic)
- **Billing alarm:** Set at a low threshold to catch unexpected traffic spikes

### 5.10 Data Refresh Cycle

- **Initial approach:** Rebuild the SQLite3 database locally (Rake task), redeploy via `sam deploy`
- **Future consideration:** Load the database file from S3 at Lambda cold start instead of bundling it in the zip. This would allow data updates without redeployment. The application should be designed with this in mind — isolate database loading behind an interface that can switch from filesystem to S3 later.

---

## 6. Options Considered

### 6.1 Option A: Ruby/Roda + Lambda zip (chosen)

#### Benefits
- Minimal framework overhead; Roda is fast and small
- Zip deployment is simpler than container management
- lamby handles Rack-to-Lambda translation cleanly
- SQLite3 bundled in the package eliminates network database calls
- Runs locally as a plain Rack app

#### Drawbacks
- Native gem compilation requires SAM build (Docker dependency for builds)
- Zip package size limit (250 MB uncompressed) could matter if the database grows significantly

#### Why Chosen
Best fit for a solo project: minimal moving parts, familiar language, near-zero runtime cost, fast cold starts with a small database.

### 6.2 Option B: Ruby/Roda + Lambda container image

#### Benefits
- Full control over Ruby version and native extensions
- No SAM build dependency for native compilation
- Larger package size limit (10 GB)

#### Drawbacks
- Requires ECR repository management
- Container build adds complexity to the deployment pipeline
- Slower cold starts than zip (typically)

#### Why Not Chosen
Unnecessary for a < 1 MB database and a handful of gems. Reserved as a fallback if zip deployment proves problematic or when Ruby 4 is adopted.

### 6.3 Option C: Static site generator (no Lambda)

#### Benefits
- Zero runtime cost; serve from S3 + CloudFront
- No cold starts

#### Drawbacks
- Cannot select a random event per request (FR-003)
- Requires a build step to generate 366 HTML files
- Less flexible for future dynamic features

#### Why Not Chosen
Random event selection requires server-side logic. A static site cannot satisfy FR-003.

### 6.4 Option D: Do Nothing

#### Why Rejected
PRD-0001 cannot be implemented without these technical decisions.

---

## 7. Consequences

### 7.1 Positive
- Single deployable artifact (zip) with no external runtime dependencies
- Local development requires only `bundle install` and `rackup`
- Database is a simple file that can be versioned, inspected, and rebuilt trivially
- CloudFront provides TLS, caching, and custom domain without application code changes

### 7.2 Negative
- SAM build requires Docker to compile native extensions for Amazon Linux
- Database updates require redeployment (until S3-based loading is implemented)
- lamby adds a dependency and an abstraction layer over the Lambda event format

### 7.3 Follow-On Work
- Rake task to build the SQLite3 database from YAML source data
- SAM template (`template.yaml`) for Lambda function definition
- CloudFront distribution configuration
- RSpec test suite and Cucumber acceptance tests
- Database loading interface designed for future S3 migration

---

## 8. Testing

- **Unit tests:** RSpec for database queries, date matching, random selection, HTML rendering
- **Acceptance tests:** Cucumber with Gherkin scenarios from PRD-0001 section 16.3
- **End-to-end tests:** Playwright against the locally running Rack application
- **Accessibility tests:** axe-core or similar automated checks
- **Local testing:** `rackup` serves the application identically to Lambda (minus the lamby handler path)

---

## 9. Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| SAM build fails with sqlite3 native extension | Medium | Medium | Fall back to container image deployment |
| lamby gem becomes unmaintained | Low | Medium | lamby is thin; could be replaced with a custom Rack handler (~50 lines) |
| Lambda Ruby runtime deprecated | Low | High | Migrate to container image with any Ruby version |
| Database file grows beyond zip size limits | Very Low | Medium | Switch to container image or S3-based loading |

---

## 10. Open Questions

| ID | Question | Resolution |
|----|----------|------------|
| OQ-001 | Exact CloudFront caching strategy (TTL, invalidation on deploy) | TBD |
| OQ-002 | Should the SQLite3 database file be committed to the repository or built as a CI artifact? | TBD |
| OQ-003 | SAM template region and stack naming conventions | TBD |

---

## 11. Future Evolution

- **S3-based database loading:** Replace bundled database file with S3 fetch at cold start, allowing data updates without redeployment
- **Container image deployment:** Migrate from zip to ECR container if native extension builds become problematic or Ruby 4 requires it
- **Additional routes:** Roda's routing tree makes it straightforward to add date-specific URLs (e.g., `/march-11`) for future archive browsing (PRD-0001 section 3.4)

---

## 12. Tags and Classification

- **Domain Tags:** web, history, vietnam-war
- **System Tags:** lambda, serverless
- **Technology Tags:** ruby, roda, sqlite3, lamby, sam, cloudfront, erb
- **Confidentiality:** Public
- **Search Keywords:** ruby, roda, lambda, sqlite3, lamby, sam, cloudfront, serverless, rack
