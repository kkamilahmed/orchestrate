-- Orchestrate keynote demo: database schema
-- Loaded automatically by docker-compose on first start (runs as the admin/owner role).
--
-- Two roles:
--   * the owner (POSTGRES_USER from docker-compose) owns every table and loads the seed
--   * orchestrate_app is what server.js connects as: it can READ business data and can
--     WRITE only to activity tables (activity_log, tasks, chats, chat_messages, app_state).

-- ---------------------------------------------------------------------------
-- Business data (read-only for the app)
-- ---------------------------------------------------------------------------

CREATE TABLE industries (
  id            SERIAL PRIMARY KEY,
  slug          TEXT NOT NULL UNIQUE,
  name          TEXT NOT NULL,              -- "Insurance"
  company_name  TEXT NOT NULL,              -- "Harborline Mutual Insurance"
  logo_text     TEXT NOT NULL,              -- "Harborline" (shown in the header)
  record_noun   TEXT NOT NULL DEFAULT 'records', -- "clients", "patients", ... used in copy
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,   -- available in the presenter switcher
  sort_order    INT NOT NULL DEFAULT 0
);

CREATE TABLE app_users (
  id           SERIAL PRIMARY KEY,
  industry_id  INT NOT NULL REFERENCES industries(id),
  name         TEXT NOT NULL,
  role         TEXT NOT NULL,
  email        TEXT NOT NULL
);

CREATE TABLE records (
  id           SERIAL PRIMARY KEY,
  industry_id  INT NOT NULL REFERENCES industries(id),
  name         TEXT NOT NULL,
  email        TEXT,
  phone        TEXT,
  record_type  TEXT NOT NULL,              -- client, patient, employee, tenant, supplier, asset...
  attributes   JSONB NOT NULL DEFAULT '{}', -- industry-specific fields
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX records_industry_idx ON records(industry_id);

-- Dated things that happened (or will happen) to a record. Signals and flows are
-- driven by these: "child turned 25", "policy renews", "sensor anomaly", ...
CREATE TABLE life_events (
  id           SERIAL PRIMARY KEY,
  record_id    INT NOT NULL REFERENCES records(id) ON DELETE CASCADE,
  event_type   TEXT NOT NULL,
  description  TEXT NOT NULL,
  event_date   DATE NOT NULL
);
CREATE INDEX life_events_record_idx ON life_events(record_id);
CREATE INDEX life_events_type_date_idx ON life_events(event_type, event_date);

CREATE TABLE products (
  id                 SERIAL PRIMARY KEY,
  industry_id        INT NOT NULL REFERENCES industries(id),
  name               TEXT NOT NULL,
  description        TEXT NOT NULL,
  price              NUMERIC(12,2) NOT NULL DEFAULT 0,
  price_unit         TEXT NOT NULL DEFAULT '',     -- "/month", "" ...
  discount_pct       NUMERIC(5,2) NOT NULL DEFAULT 0,
  -- {"all":[{"attr":"tenure_years","op":">=","value":3,"label":"3+ years as a client"}]}
  eligibility_rules  JSONB NOT NULL DEFAULT '{}'
);

-- Named, parameterized record queries. Signals and flows refer to these by key; the
-- server runs one fixed parameterized SQL statement with these values. No SQL text is
-- ever stored or accepted from the client.
CREATE TABLE query_definitions (
  key          TEXT PRIMARY KEY,
  industry_id  INT NOT NULL REFERENCES industries(id),
  description  TEXT NOT NULL,
  event_types  TEXT[] NOT NULL,
  days_from    INT NOT NULL,   -- event_date >= CURRENT_DATE + days_from
  days_to      INT NOT NULL    -- event_date <= CURRENT_DATE + days_to
);

CREATE TABLE flows (
  id           SERIAL PRIMARY KEY,
  industry_id  INT NOT NULL REFERENCES industries(id),
  slug         TEXT NOT NULL,
  title        TEXT NOT NULL,
  description  TEXT NOT NULL,
  flow_type    TEXT NOT NULL CHECK (flow_type IN ('outreach', 'qa', 'insight')),
  keywords     TEXT[] NOT NULL DEFAULT '{}',
  icon         TEXT NOT NULL DEFAULT 'bot',
  product_id   INT REFERENCES products(id),
  steps        JSONB NOT NULL DEFAULT '{}',
  sort_order   INT NOT NULL DEFAULT 0,
  UNIQUE (industry_id, slug)
);

CREATE TABLE signals (
  id           SERIAL PRIMARY KEY,
  industry_id  INT NOT NULL REFERENCES industries(id),
  title        TEXT NOT NULL,          -- "{{count}} client{{s}} had life events this week"
  description  TEXT NOT NULL,
  flow_id      INT NOT NULL REFERENCES flows(id),
  severity     TEXT NOT NULL CHECK (severity IN ('high', 'medium', 'low')),
  count_query  TEXT NOT NULL REFERENCES query_definitions(key),
  sort_order   INT NOT NULL DEFAULT 0
);

CREATE TABLE prompt_templates (
  id             SERIAL PRIMARY KEY,
  flow_id        INT NOT NULL REFERENCES flows(id),
  template_text  TEXT NOT NULL
);

CREATE TABLE knowledge_base (
  id             SERIAL PRIMARY KEY,
  industry_id    INT NOT NULL REFERENCES industries(id),
  source         TEXT NOT NULL,        -- "Harborline Underwriting Handbook"
  section_title  TEXT NOT NULL,
  content        TEXT NOT NULL,
  search_vector  TSVECTOR GENERATED ALWAYS AS (
    setweight(to_tsvector('english', section_title), 'A') ||
    setweight(to_tsvector('english', content), 'B')
  ) STORED
);
CREATE INDEX knowledge_base_search_idx ON knowledge_base USING GIN (search_vector);

-- Pre-written responses for offline mode.
--   kind = 'draft' : flow_id set, rendered with the same variables as the prompt template
--   kind = 'chat'  : free-text answer, chosen by match_keywords (empty = industry fallback)
CREATE TABLE offline_responses (
  id              SERIAL PRIMARY KEY,
  industry_id     INT NOT NULL REFERENCES industries(id),
  flow_id         INT REFERENCES flows(id),
  kind            TEXT NOT NULL CHECK (kind IN ('draft', 'chat')),
  match_keywords  TEXT[] NOT NULL DEFAULT '{}',
  response_text   TEXT NOT NULL
);

-- Suggested action tiles on the home screen.
CREATE TABLE suggestions (
  id           SERIAL PRIMARY KEY,
  industry_id  INT NOT NULL REFERENCES industries(id),
  title        TEXT NOT NULL,
  prompt       TEXT NOT NULL,
  icon         TEXT NOT NULL DEFAULT 'idea',
  sort_order   INT NOT NULL DEFAULT 0
);

-- ---------------------------------------------------------------------------
-- Activity data (the app can write here)
-- ---------------------------------------------------------------------------

CREATE TABLE activity_log (
  id           SERIAL PRIMARY KEY,
  industry_id  INT NOT NULL REFERENCES industries(id),
  record_id    INT REFERENCES records(id),
  flow_id      INT REFERENCES flows(id),
  action_type  TEXT NOT NULL,          -- email_sent, sms_sent, task_created, ticket_opened, ...
  payload      JSONB NOT NULL DEFAULT '{}',
  is_seed      BOOLEAN NOT NULL DEFAULT FALSE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX activity_log_industry_idx ON activity_log(industry_id, created_at DESC);

CREATE TABLE tasks (
  id           SERIAL PRIMARY KEY,
  record_id    INT NOT NULL REFERENCES records(id),
  title        TEXT NOT NULL,
  due_date     DATE NOT NULL,
  status       TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'done')),
  is_seed      BOOLEAN NOT NULL DEFAULT FALSE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE chats (
  id           SERIAL PRIMARY KEY,
  industry_id  INT NOT NULL REFERENCES industries(id),
  title        TEXT NOT NULL,
  is_seed      BOOLEAN NOT NULL DEFAULT FALSE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX chats_industry_idx ON chats(industry_id, updated_at DESC);

CREATE TABLE chat_messages (
  id           SERIAL PRIMARY KEY,
  chat_id      INT NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
  role         TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
  kind         TEXT NOT NULL DEFAULT 'text' CHECK (kind IN ('text', 'flow')),
  content      TEXT NOT NULL,
  payload      JSONB NOT NULL DEFAULT '{}',
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX chat_messages_chat_idx ON chat_messages(chat_id, id);

-- Presenter state (active industry, offline toggle) so it survives a server restart.
CREATE TABLE app_state (
  key    TEXT PRIMARY KEY,
  value  TEXT NOT NULL
);

-- Demo metadata: the date the seed's relative dates are anchored to.
CREATE TABLE demo_meta (
  id          INT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  anchor_date DATE NOT NULL DEFAULT CURRENT_DATE
);
INSERT INTO demo_meta DEFAULT VALUES;

-- ---------------------------------------------------------------------------
-- Keep the demo "fresh": the seed writes dates relative to the day it was loaded
-- ("turned 25 two days ago", "renews in 9 days"). If the keynote happens a week later,
-- this function slides every seeded date forward so the signals still read true.
-- It runs as the owner (SECURITY DEFINER) so the app role never needs UPDATE rights
-- on business tables; the app may only EXECUTE it.
-- ---------------------------------------------------------------------------
CREATE FUNCTION refresh_demo_dates() RETURNS INT
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  shift INT;
BEGIN
  SELECT CURRENT_DATE - anchor_date INTO shift FROM demo_meta WHERE id = 1 FOR UPDATE;
  IF shift IS NULL OR shift = 0 THEN
    RETURN 0;
  END IF;
  UPDATE life_events SET event_date = event_date + shift;
  UPDATE tasks SET due_date = due_date + shift WHERE is_seed;
  UPDATE activity_log SET created_at = created_at + make_interval(days => shift) WHERE is_seed;
  UPDATE chats SET created_at = created_at + make_interval(days => shift),
                   updated_at = updated_at + make_interval(days => shift) WHERE is_seed;
  UPDATE chat_messages m SET created_at = m.created_at + make_interval(days => shift)
    FROM chats c WHERE c.id = m.chat_id AND c.is_seed;
  UPDATE demo_meta SET anchor_date = CURRENT_DATE WHERE id = 1;
  RETURN shift;
END;
$$;

-- ---------------------------------------------------------------------------
-- Least-privilege application role
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'orchestrate_app') THEN
    CREATE ROLE orchestrate_app LOGIN PASSWORD 'orchestrate_app';
  END IF;
END
$$;

REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON FUNCTION refresh_demo_dates() FROM PUBLIC;

GRANT USAGE ON SCHEMA public TO orchestrate_app;

GRANT SELECT ON
  industries, app_users, records, life_events, products, query_definitions,
  flows, signals, prompt_templates, knowledge_base, offline_responses, suggestions, demo_meta
TO orchestrate_app;

GRANT SELECT, INSERT, UPDATE, DELETE ON activity_log, tasks, chats, chat_messages, app_state TO orchestrate_app;
GRANT USAGE, SELECT ON SEQUENCE activity_log_id_seq, tasks_id_seq, chats_id_seq, chat_messages_id_seq TO orchestrate_app;

GRANT EXECUTE ON FUNCTION refresh_demo_dates() TO orchestrate_app;
