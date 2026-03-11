---
id: PRD-0001
product_initiative_name: This Day in Viet Nam
prd_title: "This Day in Viet Nam" Daily History Page
authors: [David Doolin]
owner: David Doolin
contributors_reviewers: []
status: Draft
version: "0.1"
created_date: 2026-03-11
last_updated: 2026-03-11
target_release_milestone:
related_documents:
  adrs: [ADR-001]
  design_docs: []
  roadmap_items: []
  tickets_epics: []
  research: []
  compliance_policy_references: []
change_log:
  - date: 2026-03-11
    version: "0.1"
    author: David Doolin
    summary: Initial draft
---

# PRD-0001: "This Day in Viet Nam" Daily History Page

## 1. Executive Summary

### 1.1 Overview

A lightweight web service running on AWS Lambda that serves a single, self-contained HTML page describing what happened on the current date during the Vietnam War. The page displays a title ("This Day in Viet Nam — November 9, 1965"), an explanatory paragraph optionally accompanied by a right-aligned photo, and one to three hyperlinked references. Event data is served from an in-memory SQLite3 database.

### 1.2 Problem Statement

There is no simple, daily-accessible web resource that surfaces Vietnam War history tied to today's date. Existing resources require users to search or browse large archives. A single-page, date-driven format makes the history approachable and shareable.

### 1.3 Proposed Solution

A single AWS Lambda function that:
- Loads event data from an in-memory SQLite3 database
- Matches events to the current date (month and day, single date)
- Selects one event at random when multiple events exist for that date
- Renders a styled, self-contained HTML page with embedded CSS
- Returns the page to the browser

### 1.4 Expected Outcome

A publicly accessible URL that, on any given day, shows a cleanly styled page with historical context for that date during the Vietnam War.

### 1.5 Decision Request

Approval to proceed with implementation of the Lambda-based service as described.

---

## 2. Background and Context

### 2.1 Current State

The vietnam-war-compendium repository contains timeline data and Kindle highlights related to the Vietnam War. There is no web-facing product serving this content.

### 2.2 Trigger for This Work

Personal initiative to make Vietnam War history more accessible through a simple, daily web page.

---

## 3. Goals and Non-Goals

### 3.1 Goals

- Serve a single, styled HTML page for today's date with a Vietnam War event
- Run on AWS Lambda with minimal infrastructure
- Self-contained page (no external CSS/JS dependencies)
- Mobile-friendly, centered layout

### 3.2 Non-Goals

- User accounts or authentication
- Search, browsing, or navigation across dates
- CMS or admin interface for editing content
- Date range display (multiple dates on one page)
- Analytics or tracking

### 3.3 Success Definition

A publicly accessible URL returns a well-styled page with a historically accurate event for today's date.

### 3.4 Future Work

- Support for date range queries or archive browsing
- Multiple events per page
- RSS feed

---

## 4. Stakeholders

Solo project. David Doolin is owner, developer, and content author.

---

## 5. Users and Personas

### 5.1 Vietnam War Veterans
- **Context:** Lived through the war; personal connection to dates and events
- **Goals:** Recall and reflect on events they experienced; share with family and peers
- **Frequency of Use:** Occasional to daily

### 5.2 Veterans' Relatives
- **Context:** Family members seeking to understand a veteran's experience
- **Goals:** Connect specific dates to what their relative may have witnessed
- **Frequency of Use:** Occasional

### 5.3 Students
- **Context:** Learning about the Vietnam War in an academic setting
- **Goals:** Discover primary-source-referenced events in a digestible format
- **Frequency of Use:** Occasional, possibly clustered around assignments

### 5.4 Military and Political Historians
- **Context:** Researchers and writers with deep subject knowledge
- **Goals:** Quick date-specific reference; verify events; follow references to primary sources
- **Frequency of Use:** Occasional

### 5.5 General Interest
- **Context:** Curious readers with no specific background
- **Goals:** Learn something new about the Vietnam War on any given day
- **Frequency of Use:** Occasional

### 5.6 Accessibility Considerations

Standard web accessibility: readable font sizes, sufficient contrast, semantic HTML, alt text on images when present.

---

## 6. User Stories, Scope, and Constraints

### 6.1 User Stories

- As a visitor, I want to see a Vietnam War event for today's date, so that I can learn what happened on this day.
- As a visitor, I want to see hyperlinked references for the event, so that I can verify or read more about it.
- As a visitor, I want the page to be readable on my phone, so that I can share it easily.
- As a visitor, I want to see a photo when one is available, so that the event feels more immediate.
- As a visitor, I want the page to load quickly, so that I don't lose interest waiting.

### 6.2 In Scope

- Single Lambda function serving HTML over HTTPS
- In-memory SQLite3 database loaded at cold start
- Self-contained HTML response (embedded CSS/JS, no external dependencies)
- Mobile-responsive layout
- Random event selection when multiple events match the date
- 1–3 hyperlinked references per event
- Optional right-aligned photo per event

### 6.3 Out of Scope

- Date navigation, search, or archive browsing
- User accounts, authentication, or personalization
- Content management interface
- Multiple events displayed on a single page

### 6.4 Constraints

- **Technical:** Details deferred to ADR-001 (Lambda runtime, data format, deployment approach)
- **Budget:** Stay within AWS free tier or near-zero cost
- **Staffing:** Solo developer

---

## 7. Functional Requirements

- **FR-001:** The service shall return an HTML page for the current date.
- **FR-002:** The page shall display a title in the format "This Day in Viet Nam — {Month} {Day}, {Year}".
- **FR-003:** When multiple events exist for a date, one shall be selected at random. The selected event's year determines the year displayed in the heading (FR-002).
- **FR-004:** Each event shall include 1–3 hyperlinked references.
- **FR-005:** When a photo is available for an event, it shall be displayed right-aligned beside the text.
- **FR-006:** The HTML response shall be self-contained with no external CSS, JavaScript, or font dependencies.
- **FR-007:** The layout shall be mobile-responsive and centered.
- **FR-008:** When no event exists for the current date, the service shall display a fallback message indicating no event is recorded for this date.

---

## 8. Non-Functional Requirements

### 8.1 Performance

- Warm response time under 500ms
- Cold start response time under 3 seconds

### 8.2 Security

- HTTPS only (enforced by API Gateway / Lambda function URL)
- No user data collected or stored
- No cookies, sessions, or tracking

### 8.3 Accessibility

- Semantic HTML (heading hierarchy, landmark elements)
- Sufficient color contrast (WCAG AA)
- Alt text on all images
- Readable without JavaScript enabled

### 8.4 Reliability

- Availability determined by AWS Lambda SLA
- No custom uptime target required

---

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Sparse date coverage — many dates have no event | High | Medium | Seed database with broad coverage; use fallback message (FR-008) |
| Cold start latency makes page feel slow | Medium | Low | Keep Lambda package small; in-memory SQLite avoids network calls |
| Reference links rot over time | Medium | Low | Prefer stable sources (books, archives); periodic link review |
| Historical accuracy challenged by visitors | Low | Medium | Cite references for every event; correct promptly when notified |
| AWS costs exceed expectations under traffic spike | Low | Low | Lambda + function URL has no baseline cost; set billing alarm |

---

## 10. Rollout Plan

### 10.1 Release Strategy

Phased, starting with local development and manual testing.

### 10.2 Stages

| Stage | Description | Entry Criteria | Exit Criteria |
|-------|-------------|----------------|---------------|
| 1. Local dev | Lambda function runs locally, serves test pages | ADR-001 decisions finalized | All FRs pass locally |
| 2. Staging deploy | Deploy to AWS, test with real Lambda function URL | Stage 1 complete | Page loads correctly from public URL |
| 3. Content seeding | Populate database with initial set of events | Stage 2 complete | Reasonable date coverage across the calendar |
| 4. Public launch | Share URL | Stage 3 complete | Page serves reliably for one week |

### 10.3 Rollback Plan

Disable or delete the Lambda function. No persistent user state to preserve.

---

## 11. Detailed Requirements by Surface

### 11.1 User Interface

Single page served at the root URL.

- **Purpose:** Display a Vietnam War event for today's date
- **Entry point:** Direct URL (no navigation from another page)
- **Visible data:** Title, event paragraph, optional right-aligned photo, 1–3 hyperlinked references
- **Empty state:** Fallback message when no event exists for today's date (FR-008)
- **Error state:** Generic error page if the Lambda encounters an unrecoverable error
- **Loading state:** N/A — page is server-rendered, no client-side loading
- **Accessibility:** Semantic HTML, heading hierarchy, alt text on images, sufficient contrast

### 11.2 API Requirements

N/A — the service serves HTML directly to browsers; there is no separate API.

### 11.3 Data Model Requirements

The core entity is an **Event** with the following conceptual attributes:

- **month** and **day** — used to match the current date
- **year** — the specific year the event occurred
- **title** — short description used as the HTML document title and for internal identification; the visible page heading is constructed from the date fields per FR-002
- **body** — one or more paragraphs of explanatory text
- **photo_url** — optional; path or URL to an image
- **photo_alt** — alt text for the image
- **references** — 1–3 entries, each with a display label and hyperlink URL

Schema details and storage format deferred to ADR-001.

### 11.4 Batch / Background Processing

N/A

### 11.5 Integration Requirements

N/A

---

## 12. Experience Requirements

### 12.1 UX Principles

- Clarity — the event and its context should be immediately understandable
- Low friction — no clicks, logins, or navigation required
- No training burden — the page is self-explanatory
- Consistency — every date's page follows the same layout and structure

### 12.2 Design Requirements

TBD — visual style, typography, and color palette to be determined during implementation.

### 12.3 Content Requirements

- **Tone:** Conversational and inviting, non-polarizing
- **Style guide:** Standard English following the Chicago Manual of Style (CMS)
- **Terminology:** "Viet Nam" or "Vietnam" used depending on context and original reference sources, as both are in active use
- **Fallback message:** TBD — wording for dates with no recorded event
- **References:** Displayed as numbered hyperlinks with descriptive labels

### 12.4 Onboarding / Training

N/A

---

## 13. Data Requirements

### 13.1 Data Inputs

- Manually authored event entries
- Derived from existing timeline YAML and Kindle highlights in the vietnam-war-compendium repository

### 13.2 Data Outputs

- Server-rendered HTML page (the only output)

### 13.3 Data Quality Requirements

- Every event must include body text and 1–3 references
- Photo and photo alt text are optional but must appear together when present
- Month, day, and year must be valid calendar values
- References must include both a display label and a working URL

### 13.4 Retention and Deletion

Event data is bundled with the Lambda deployment as an in-memory SQLite database. No user data is collected. Data persists as long as the deployment exists; updates require redeployment.

### 13.5 Data Migration

N/A for initial version. Existing timeline and highlights data will be used as source material for authoring events, but there is no automated migration pipeline at this stage.

---

## 14. Analytics and Measurement

No custom analytics or user tracking for the initial release. Operational visibility via standard AWS CloudWatch metrics:

- Lambda invocation count
- Error count and error rate
- Duration (p50, p95, p99)
- Throttles

---

## 15. Dependencies

### 15.1 Internal Dependencies

- Existing timeline YAML and Kindle highlights data in the vietnam-war-compendium repository (source material for event authoring)

### 15.2 External Dependencies

- AWS Lambda (compute)
- AWS CloudWatch (monitoring)

### 15.3 Sequencing Dependencies

- ADR-001 must be finalized before implementation begins (runtime, data format, deployment approach)

---

## 16. Testing and Validation

### 16.1 Test Strategy

- Unit tests for date matching, random selection, and HTML rendering logic
- End-to-end tests using Playwright to verify the served page in a browser
- Acceptance criteria written in Gherkin for use with Cucumber or equivalent

### 16.2 Required Test Types

- Unit
- End-to-end (Playwright)
- Accessibility (automated checks via axe-core or similar)

### 16.3 Acceptance Criteria

#### FR-001: Page for current date

```gherkin
Feature: Serve a page for the current date

  Scenario: Visitor requests the root URL
    Given the service is running
    And an event exists for today's date
    When a visitor requests the root URL
    Then the response status is 200
    And the response content type is text/html
```

#### FR-002: Title format

```gherkin
Feature: Display title in the correct format

  Scenario: Page title matches the event date
    Given an event exists for November 9, 1965
    And today's date is November 9
    When a visitor requests the root URL
    Then the page displays the heading "This Day in Viet Nam — November 9, 1965"
```

#### FR-003: Random selection from multiple events

```gherkin
Feature: Random event selection

  Scenario: Multiple events exist for a date
    Given 3 events exist for today's date
    When a visitor requests the root URL multiple times
    Then different events may be returned across requests
    And each response contains exactly one event
```

#### FR-004: Hyperlinked references

```gherkin
Feature: Display hyperlinked references

  Scenario: Event with references
    Given an event exists for today's date
    And the event has 2 references
    When a visitor requests the root URL
    Then the page displays 2 reference links
    And each reference is a hyperlink with a descriptive label

  Scenario: Minimum references
    Given an event exists for today's date
    And the event has 1 reference
    When a visitor requests the root URL
    Then the page displays 1 reference link

  Scenario: Maximum references
    Given an event exists for today's date
    And the event has 3 references
    When a visitor requests the root URL
    Then the page displays 3 reference links
```

#### FR-005: Right-aligned photo

```gherkin
Feature: Display optional photo

  Scenario: Event with a photo
    Given an event exists for today's date
    And the event has a photo
    When a visitor requests the root URL
    Then the page displays the photo aligned to the right of the text
    And the photo has alt text

  Scenario: Event without a photo
    Given an event exists for today's date
    And the event has no photo
    When a visitor requests the root URL
    Then no photo element is rendered
```

#### FR-006: Self-contained HTML

```gherkin
Feature: Self-contained page

  Scenario: No external dependencies
    When a visitor requests the root URL
    Then the HTML contains no external stylesheet links
    And the HTML contains no external script sources
    And the HTML contains no external font references
```

#### FR-007: Mobile-responsive centered layout

```gherkin
Feature: Mobile-responsive layout

  Scenario: Viewport at mobile width
    Given a browser viewport of 375 pixels wide
    When a visitor requests the root URL
    Then the page content is readable without horizontal scrolling
    And the main content is centered

  Scenario: Viewport at desktop width
    Given a browser viewport of 1280 pixels wide
    When a visitor requests the root URL
    Then the main content is centered with appropriate margins
```

#### FR-008: Fallback for missing date

```gherkin
Feature: Fallback when no event exists

  Scenario: No event for today's date
    Given no events exist for today's date
    When a visitor requests the root URL
    Then the response status is 200
    And the page displays a fallback message indicating no event is recorded for this date
```

### 16.4 UAT Requirements

Manual verification by the project owner across rollout stages.

### 16.5 Launch Readiness Criteria

- All acceptance criteria pass locally
- Page loads from the deployed Lambda function URL
- Initial event content is seeded
- CloudWatch metrics are visible

---

## 17. Legal, Policy, and Compliance Review

No compliance, legal, or policy requirements apply to this project. All content (text, photos, references) will be either public domain or used under fair use.

---

## 18. Open Questions

| ID | Question | Resolution |
|----|----------|------------|
| OQ-001 | What Lambda runtime and language? | Deferred to ADR-001 |
| OQ-002 | How is the SQLite database built and bundled with the Lambda package? | Deferred to ADR-001 |
| OQ-003 | What is the initial date coverage target (e.g., percentage of calendar days)? | TBD |
| OQ-004 | Should the page include a "reload for another event" button for dates with multiple events? | TBD — defer to future work |
| OQ-005 | Custom domain or Lambda function URL only for initial launch? | TBD |
| OQ-006 | Where are photos sourced and how are licensing/public domain rights verified? | TBD |

---

## Appendix D: Requirements Traceability Matrix

| Requirement ID | Section | Related Story | Test Coverage | Status |
|----------------|---------|---------------|---------------|--------|
| FR-001 | 7 | Visitor sees event for today | 16.3 — FR-001 | Draft |
| FR-002 | 7 | Visitor sees correctly formatted title | 16.3 — FR-002 | Draft |
| FR-003 | 7 | Visitor sees a different event on reload | 16.3 — FR-003 | Draft |
| FR-004 | 7 | Visitor sees hyperlinked references | 16.3 — FR-004 | Draft |
| FR-005 | 7 | Visitor sees photo when available | 16.3 — FR-005 | Draft |
| FR-006 | 7 | Page is self-contained with no external dependencies | 16.3 — FR-006 | Draft |
| FR-007 | 7 | Page readable on phone | 16.3 — FR-007 | Draft |
| FR-008 | 7 | Visitor sees fallback when no event exists | 16.3 — FR-008 | Draft |

---

## Appendix H: Launch Checklist

- [ ] PRD approved
- [ ] ADR-001 finalized
- [ ] All acceptance criteria pass locally
- [ ] Lambda deployed and serving pages
- [ ] Initial event content seeded
- [ ] CloudWatch metrics visible
- [ ] Page tested on mobile and desktop viewports
- [ ] Accessibility check passed (axe-core or equivalent)
- [ ] Rollback verified (Lambda can be disabled/deleted)
- [ ] Public URL shared

---
