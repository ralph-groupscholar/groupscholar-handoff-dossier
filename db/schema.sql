CREATE SCHEMA IF NOT EXISTS gs_handoff;

CREATE TABLE IF NOT EXISTS gs_handoff.handoff_notes (
  id BIGSERIAL PRIMARY KEY,
  scholar_name TEXT NOT NULL,
  cohort TEXT NOT NULL,
  priority TEXT NOT NULL CHECK (priority IN ('Low', 'Medium', 'High', 'Critical')),
  summary TEXT NOT NULL,
  owner TEXT NOT NULL,
  due_date DATE,
  status TEXT NOT NULL DEFAULT 'Open' CHECK (status IN ('Open', 'In Progress', 'Blocked', 'Closed')),
  tags TEXT[] NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS handoff_notes_status_idx
  ON gs_handoff.handoff_notes (status);

CREATE INDEX IF NOT EXISTS handoff_notes_due_idx
  ON gs_handoff.handoff_notes (due_date);

CREATE OR REPLACE FUNCTION gs_handoff.touch_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS handoff_notes_touch_updated_at ON gs_handoff.handoff_notes;

CREATE TRIGGER handoff_notes_touch_updated_at
BEFORE UPDATE ON gs_handoff.handoff_notes
FOR EACH ROW EXECUTE FUNCTION gs_handoff.touch_updated_at();
