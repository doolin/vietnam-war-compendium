CREATE TABLE IF NOT EXISTS events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  month INTEGER NOT NULL,
  day INTEGER NOT NULL,
  year INTEGER NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  photo_url TEXT,
  photo_alt TEXT
);

CREATE TABLE IF NOT EXISTS "references" (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  event_id INTEGER NOT NULL,
  position INTEGER NOT NULL,
  label TEXT NOT NULL,
  url TEXT NOT NULL,
  FOREIGN KEY (event_id) REFERENCES events(id)
);

CREATE INDEX IF NOT EXISTS idx_events_month_day ON events(month, day);
CREATE INDEX IF NOT EXISTS idx_references_event_id ON "references"(event_id);
