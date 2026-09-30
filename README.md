# Orchestrate keynote demo

An AI assistant that notices things for you, drafts the busywork, and keeps you in control.
It surfaces the right moment from business data (a life event, a renewal, a risk), drafts the action, and a human approves it.

- **Frontend:** Next.js (App Router) with IBM Carbon Design System (`@carbon/react`), White theme.
- **API:** Node.js 18+ (`node:http` and built-in `fetch`). The only dependency is `pg`.
- **Database:** PostgreSQL 16. All data lives there: industries, branding, users, records, signals, flows, prompt templates, knowledge base, offline responses and activity.
- **LLM:** OpenRouter, proxied through the API and streamed to the browser over SSE. The key never reaches the browser.

The presenter walkthrough is in [KEYNOTE.md](KEYNOTE.md).

## Setup

You need Docker, and Node.js 18 or newer.

The quickest way is one command, which installs and builds on the first run, opens the browser, and stops everything with Ctrl+C:

```bash
./run.sh              # add --rebuild after changing frontend code
```

It asks which ports to use for the web app and the API; press Enter to keep 3000 and 3001.
A port that is taken is rejected and asked for again.
To skip the questions (or when there is no terminal), set them up front: `WEB_PORT=4000 API_PORT=4001 ./run.sh`.
Changing the API port rebuilds the web app once, because Next.js bakes the `/api` proxy target into the build.

Or step by step:

```bash
# 1. Database (loads schema.sql and seed.sql on first start)
docker compose up -d

# 2. API server (port 3001)
cp .env.example .env          # add OPENROUTER_API_KEY, or leave it empty for offline mode
npm install
node server.js

# 3. Frontend (port 3000), in a second terminal
cd web
npm install
npm run build
npm start                     # or: npm run dev
```

Open http://localhost:3000.
From the repo root you can also run `npm run web:install`, `npm run web:build` and `npm run web`.

To start over with a fresh database, run `docker compose down -v` and then `docker compose up -d`.

### Before you go on stage

- Run everything once on the venue laptop while you have internet.
The Carbon styles and IBM Plex fonts are in `web/public/carbon`, so the UI needs no CDN.
- Use `npm run build` and `npm start` rather than `npm run dev`, so pages don't compile while you present.
- The browser window should be 1920x1080.
Chat text switches to the larger projector size at 1584px and wider.
- If the venue Wi-Fi is unreliable, press `Shift+O` before you start.
Offline responses stream word by word and look exactly like live ones.

## Presenter controls

These are hidden from the audience and only work when the cursor is not in a text field.
Click an empty area first if you have just typed something.

| Key | Action |
|---|---|
| `Shift+I` | Industry switcher (then `1`-`7`). Changes company name, logo text, persona, data, signals and flows. |
| `Shift+O` | Toggle offline mode. |
| `Shift+R` | Reset the demo: deletes the activity, tasks and chats created during the session and returns to the home screen. Seeded history is kept. |

The reset is also available from the reset icon in the header, which asks for confirmation first.

The small dot at the far right of the header shows the mode: green means the live model, gray means offline.
Hover over it to see the model or the reason.

## How it works

```
Browser (Next.js + Carbon)  --/api/*-->  Next.js rewrite  -->  server.js (node:http)  -->  PostgreSQL
                                                                       |
                                                                       +--> OpenRouter (streamed, temperature 0.3)
```

### Screens

1. **Today's signals** (home): the persona is greeted by name, and 3-5 signals are shown with counts computed live from the database, plus 3 suggested actions and the chat input.
2. **Side nav:** new chat, the active chat and recent chats (stored in `chats` and `chat_messages`), and the assistants (flows).
3. **Guided flows**, as cards inside the chat:
   1. Agent steps with checkmarks. Their numbers are the real query results.
   2. Records table (Carbon DataTable) with search, selection and pagination.
   3. Review card: product dropdown, follow-up days, locked database values and the editable prompt pre-filled from the template.
   4. Draft card: to, cc, subject, content type and a streamed, editable body, plus the fact check.
   5. Approve: writes to `activity_log`, creates a follow-up row in `tasks` and shows a confirmation.
   Every flow can be cancelled at any step, and nothing is ever actually sent.
4. **Free-text chat:** a message that matches a flow's keywords starts that flow.
Anything else is answered by the LLM, with this industry's records, events, products, signals, recent activity and knowledge base as context.
5. **Q&A:** questions that match a `qa` flow are answered only from the top matching `knowledge_base` sections (PostgreSQL full-text search), with inline citations and a sources list.
6. **Activity panel** (header icon): recent `activity_log` entries and open `tasks`, with new ones highlighted.

### Accuracy guard

Prices, discounts, dates, ages and quantities come from the database.
The server puts them in the prompt as a `FIXED FACTS` block and tells the model to use them exactly and never invent numbers.
After drafting, and again after every edit, the server checks every %, $ amount, date ("October 6"), age ("turned 25") and fact quantity ("400 units") in the draft.
Each one must appear in the text the database produced: the facts, the template rendered from the database (not the edited prompt) and the product description.
Anything else shows a red Carbon tag, for example "Draft says 20%, database says 15% (loyalty discount)".
The approval payload records whether the facts were verified.

### Offline mode and fallbacks

The app serves pre-written responses from `offline_responses` when there is no `OPENROUTER_API_KEY` or offline mode is toggled on.
They are rendered with the same template variables as the live prompt and streamed word by word.
If a live call fails before the first token (network error, bad key, or no token within `FIRST_TOKEN_TIMEOUT_MS`), the same offline text is streamed instead and the status dot turns gray.
Offline Q&A answers are built from the best matching knowledge base section.

### Least privilege

`schema.sql` creates the `orchestrate_app` role that the API connects as.
It can read the business tables and write only to `activity_log`, `tasks`, `chats`, `chat_messages` and `app_state`.
All queries are parameterized.
Signals and flows refer to named queries in `query_definitions`, which one fixed SQL statement executes, so no SQL is stored or accepted from the client.
Records selected in a flow must come from that flow's own queries.

The seed writes dates relative to the day the database is created.
On startup the API calls `refresh_demo_dates()`, a `SECURITY DEFINER` function the app role may only execute.
It slides every seeded date forward if the keynote happens days later, so "turned 25 this week" stays true.

## Configuration

`.env` in the repo root (parsed by `server.js`, see `.env.example`):

| Variable | Default | Notes |
|---|---|---|
| `OPENROUTER_API_KEY` | empty | Empty means offline mode. |
| `OPENROUTER_MODEL` | `google/gemini-3.1-flash-lite` | Any OpenRouter model id. |
| `DATABASE_URL` | `postgres://orchestrate_app:orchestrate_app@localhost:5432/orchestrate` | |
| `API_PORT` | `3001` | |
| `FIRST_TOKEN_TIMEOUT_MS` | `12000` | Falls back to offline after this long with no token. |
| `OPENROUTER_BASE_URL` | `https://openrouter.ai/api/v1` | For a proxy or gateway. |

`web/.env` (optional, see `web/.env.example`): `API_URL`, default `http://localhost:3001`.

## Project structure

```
schema.sql            tables, least-privilege role, refresh_demo_dates()
seed.sql              7 industries of demo data
docker-compose.yml    Postgres 16, loads schema.sql + seed.sql on first start
server.js             API: state, signals, flows, drafting, fact check, chat, Q&A, activity
web/
  app/                layout, page, app.css (Carbon tokens, type scale, motion)
  components/         App shell, Home, AgentSteps, RecordsTable, ReviewCard, DraftsCard, GuidedFlow, ActivityPanel, IndustryModal
  lib/                API client (SSE), types, markdown, icon map
  public/carbon/      Carbon v11 compiled CSS + IBM Plex fonts (offline-safe)
KEYNOTE.md            5-minute insurance walkthrough
```

## Data model

`seed.sql` is the reference for everything below.
Insurance (industry 1) is the most complete example.

### Industries, users, records, events

- `industries` holds the branding (`company_name`, `logo_text`) and `record_noun` ("clients", "patients"...).
`is_active` controls whether it appears in the switcher.
- `app_users` holds the presenter persona that the app greets and signs drafts as.
- `records` are the industry's people or things (`record_type`: client, patient, employee, tenant, supplier, asset...), with industry-specific fields in `attributes` JSONB.
Store money as plain numbers; facts format them.
- `life_events` are dated things that happened or will happen to a record ("child turned 25", "policy renews", "sensor anomaly").
Signals and flows are driven by them.
When a record needs a second date (for example a revised ETA), add another event.
Every event is exposed to templates as `{{date_<event_type>}}`.
- Seed dates are always relative (`CURRENT_DATE - 2`), never absolute.

### Named queries and signals

- `query_definitions`: `event_types[]` plus a window of `days_from` to `days_to` relative to today.
It returns one row per record (the latest matching event).
- `signals`: a `title` with `{{count}}` and the plural helpers `{{s}}` and `{{ies}}`, a `severity` (high, medium or low), a `count_query` and the `flow_id` it opens.
Clicking a signal runs its flow with the signal's query, so the table always matches the count.

### Flows

`flow_type` is one of:

- `outreach`: one message per selected record.
- `insight`: a summary document, often `draft_mode: combined`.
- `qa`: an answer from the knowledge base.

`keywords` are phrases matched on word boundaries against typed messages.
`product_id` is the default product on the review card.
`steps` JSONB configures the whole flow:

```json
{
  "query": "ins_life_events",
  "agent_steps": ["Querying CRM...", "Found {{count}} {{record_noun}} with recent life events", "..."],
  "table_title": "Clients with recent life events",
  "select_hint": "Select the clients you want to reach out to.",
  "change_label": "Recent change",
  "contact_field": "email",
  "draft_mode": "per_record",
  "list_template": "- {{name}}: {{event}} ({{event_date}})",
  "content_type": "Email",
  "to": "{{email}}",
  "cc": "{{sender_email}}",
  "subject": "Coverage for {{recommended_for}}: an option worth a quick look",
  "facts": [{ "key": "discount_pct", "label": "Loyalty discount", "kind": "percent" }],
  "approve": {
    "label": "Send email",
    "action_type": "email_sent",
    "log_label": "Logged to CRM",
    "task_title": "Follow up with {{name}} about the {{product}}",
    "follow_up": { "weekday": 5 },
    "confirmation": "Email sent to {{name}}. Logged to CRM. Follow-up task created for {{follow_up_day}}.",
    "ticket": { "title": "...", "queue": "Store Operations" }
  }
}
```

- `contact_field` is `email` or `phone`.
- `draft_mode` is `per_record` or `combined`.
In `combined` mode, `list_template` is rendered once per selected record into `{{records_list}}`.
- `content_type` is Email, SMS, Work order, Portal message or Handover summary.
- `facts[].kind` is `percent`, `money`, `date`, `age`, or `quantity` (which needs a `unit`, such as "units" or "mg").
- `approve.follow_up` is `{"weekday": 1-7}`, `{"business_days": n}` or `{"days": n}`.
The presenter can override it on the review card.
- `approve.ticket` is optional.
It also logs a `ticket_opened` entry and exposes `{{ticket_id}}`.
- For `qa` flows, `steps` only needs `agent_steps`, which can use `{{count}}` and `{{top_section}}`.

### Template variables

The following are available in prompt templates, offline drafts and the subject, to, cc, task and confirmation fields:

- Record: `name`, `first_name` (from `attributes.first_name`, or the first word of the name), `email`, `phone`, `record_type`, and every attribute.
- Event: `event`, `event_type`, `event_date`, `days_since`, `days_until`, and `date_<event_type>`.
- Product: `product`, `product_description`, `price`, `price_unit`, `discount_pct` (0 when not eligible), `discounted_price`, `savings`, `eligible`, `eligibility_note`.
Money values already include the `$`.
- Sender and other: `sender`, `sender_first`, `sender_role`, `sender_email`, `company`, `company_short`, `today`, `follow_up_date`, `follow_up_day`, `record_noun`, `count`, `records_list`, `names`.
- Sections: `{{#eligible}}...{{/eligible}}` renders when the value is truthy, and `{{^eligible}}...{{/eligible}}` when it is falsy.

Eligibility rules live on the product (`eligibility_rules`), for example `{"all":[{"attr":"tenure_years","op":">=","value":3,"label":"3+ years as a client"}]}`.
The supported operators are `>=`, `>`, `<=`, `<`, `=` and `!=`.

### Knowledge base, offline responses, suggestions

- `knowledge_base`: `source`, `section_title` and `content`, with a generated full-text `search_vector`.
- `offline_responses`: `kind='draft'` (one per non-qa flow, rendered with the template variables), or `kind='chat'`, picked by `match_keywords`.
An empty keyword list is the industry fallback.
Chat text may use `{{user_first}}` and `{{signals_summary}}` (live signal titles).
- `suggestions`: the three action tiles on the home screen.
Each tile sends its `prompt` as a chat message.

### Activity

- `activity_log`, `tasks`, `chats` and `chat_messages` are written by the app.
- Seeded rows have `is_seed = true` and survive a reset.
- `app_state` stores the active industry and the offline toggle across restarts.

### Adding an industry

1. Insert the industry, persona, records and life events.
2. Add the query definitions, products, flows (with `steps`), prompt templates, signals, offline responses, knowledge base sections and suggestions.
3. Recreate the database with `docker compose down -v && docker compose up -d`.

No code changes are needed.
Any offline draft must only use $ amounts, percentages and dates that appear in its rendered template or product description, or the fact check will flag it.
