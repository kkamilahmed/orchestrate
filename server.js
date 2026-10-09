'use strict';

// Orchestrate keynote demo: API server.
// Node 18+, node:http + built-in fetch. The only dependency is `pg`.
// The Next.js frontend in web/ proxies /api/* here, so the LLM API key never reaches the browser.

const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const { Pool, types } = require('pg');

// ---------------------------------------------------------------------------
// Configuration (.env is parsed by hand: KEY=value, # comments, optional quotes)
// ---------------------------------------------------------------------------

function loadEnvFile(file) {
  if (!fs.existsSync(file)) return;
  for (const line of fs.readFileSync(file, 'utf8').split(/\r?\n/)) {
    const m = line.match(/^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)?\s*$/);
    if (!m) continue;
    let value = (m[2] || '').trim();
    if (/^(['"]).*\1$/.test(value)) value = value.slice(1, -1);
    else value = value.replace(/\s+#.*$/, '');
    if (process.env[m[1]] === undefined) process.env[m[1]] = value;
  }
}
loadEnvFile(path.join(__dirname, '.env'));

const PORT = Number(process.env.API_PORT) || 3001;
const env = (name, fallback = '') => (process.env[name] || '').trim() || fallback;

// Both providers speak the OpenAI Chat Completions protocol; they differ in defaults,
// headers and how output length is capped.
const PROVIDERS = {
  openrouter: {
    name: 'OpenRouter',
    keyVar: 'OPENROUTER_API_KEY',
    apiKey: env('OPENROUTER_API_KEY'),
    model: env('OPENROUTER_MODEL', 'google/gemini-3.1-flash-lite'),
    baseUrl: env('OPENROUTER_BASE_URL', 'https://openrouter.ai/api/v1').replace(/\/+$/, ''),
    headers: { 'HTTP-Referer': 'http://localhost', 'X-Title': 'Orchestrate keynote demo' },
    params: ({ temperature, maxTokens }) => ({ temperature, max_tokens: maxTokens }),
  },
  openai: {
    name: 'OpenAI',
    keyVar: 'OPENAI_API_KEY',
    apiKey: env('OPENAI_API_KEY'),
    model: env('OPENAI_MODEL', 'gpt-4.1-mini'),
    baseUrl: env('OPENAI_BASE_URL', 'https://api.openai.com/v1').replace(/\/+$/, ''),
    headers: {},
    params: openAIParams,
  },
};

// Reasoning models (o1, o3, o4-mini, gpt-5, ...) reject a custom temperature and count
// their hidden reasoning against the output cap, so they get headroom on top of the
// visible-text budget. The gpt-5 "-chat" variants are regular chat models.
const OPENAI_REASONING_EFFORT = env('OPENAI_REASONING_EFFORT', 'low');
const REASONING_TOKEN_HEADROOM = 4000;
function isOpenAIReasoningModel(model) {
  return /^(o\d|gpt-5)/.test(model) && !/-chat/.test(model);
}
function openAIParams({ temperature, maxTokens }) {
  if (!isOpenAIReasoningModel(PROVIDERS.openai.model)) return { temperature, max_completion_tokens: maxTokens };
  return { reasoning_effort: OPENAI_REASONING_EFFORT, max_completion_tokens: maxTokens + REASONING_TOKEN_HEADROOM };
}

// LLM_PROVIDER picks one explicitly. Left empty, the provider whose key is set wins,
// with OpenRouter first when both are.
function resolveProvider() {
  const choice = env('LLM_PROVIDER').toLowerCase();
  if (choice) {
    if (PROVIDERS[choice]) return PROVIDERS[choice];
    console.error(`\nUnknown LLM_PROVIDER "${choice}" in .env. Use one of: ${Object.keys(PROVIDERS).join(', ')}.\n`);
    process.exit(1);
  }
  return Object.values(PROVIDERS).find((p) => p.apiKey) || PROVIDERS.openrouter;
}
const LLM = resolveProvider();
const DATABASE_URL = process.env.DATABASE_URL || 'postgres://orchestrate_app:orchestrate_app@localhost:5432/orchestrate';
const FIRST_TOKEN_TIMEOUT_MS = Number(process.env.FIRST_TOKEN_TIMEOUT_MS) || 12000;
const DRAFT_TEMPERATURE = 0.3;
const TIME_ZONE = process.env.TZ || Intl.DateTimeFormat().resolvedOptions().timeZone || 'UTC';

// Keep DATE columns as 'YYYY-MM-DD' strings so no timezone shifting happens in JS.
types.setTypeParser(1082, (v) => v);
// NUMERIC -> number (prices, discounts; all small enough for doubles).
types.setTypeParser(1700, (v) => (v === null ? null : Number(v)));

const pool = new Pool({
  connectionString: DATABASE_URL,
  max: 10,
  // CURRENT_DATE should be the presenter's local date, not the container's UTC date.
  options: `-c TimeZone=${TIME_ZONE}`,
});

const q = async (sql, params = []) => (await pool.query(sql, params)).rows;
const q1 = async (sql, params = []) => (await pool.query(sql, params)).rows[0] || null;

// ---------------------------------------------------------------------------
// Formatting helpers
// ---------------------------------------------------------------------------

const MONTHS = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
const WEEKDAYS = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

function parseISODate(s) {
  const [y, m, d] = s.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, d));
}
function toISODate(dt) {
  return dt.toISOString().slice(0, 10);
}
function addDays(iso, n) {
  const dt = parseISODate(iso);
  dt.setUTCDate(dt.getUTCDate() + n);
  return toISODate(dt);
}
function daysBetween(fromIso, toIso) {
  return Math.round((parseISODate(toIso) - parseISODate(fromIso)) / 86400000);
}
function formatDateLong(iso) {
  const dt = parseISODate(iso);
  return `${WEEKDAYS[dt.getUTCDay()]}, ${MONTHS[dt.getUTCMonth()]} ${dt.getUTCDate()}`;
}
function formatDateShort(iso) {
  const dt = parseISODate(iso);
  return `${MONTHS[dt.getUTCMonth()].slice(0, 3)} ${dt.getUTCDate()}`;
}
function formatMoney(n) {
  const num = Number(n);
  const cents = Math.round(num * 100) % 100 !== 0;
  return '$' + num.toLocaleString('en-US', { minimumFractionDigits: cents ? 2 : 0, maximumFractionDigits: 2 });
}
function formatNumber(n) {
  return Number(n).toLocaleString('en-US', { maximumFractionDigits: 3 });
}
function round2(n) {
  return Math.round(n * 100) / 100;
}

// ---------------------------------------------------------------------------
// Templates: {{var}}, {{#var}}...{{/var}} (truthy), {{^var}}...{{/var}} (falsy)
// ---------------------------------------------------------------------------

function renderTemplate(text, vars) {
  if (!text) return '';
  let out = String(text);
  // Sections (innermost first; no nesting of the same name is needed).
  const section = /\{\{([#^])\s*([\w.]+)\s*\}\}([\s\S]*?)\{\{\/\s*\2\s*\}\}/;
  let guard = 0;
  while (section.test(out) && guard++ < 100) {
    out = out.replace(section, (_, kind, key, body) => {
      const v = vars[key];
      const truthy = Array.isArray(v) ? v.length > 0 : Boolean(v) && v !== '0';
      return (kind === '#') === truthy ? body : '';
    });
  }
  return out.replace(/\{\{\s*([\w.]+)\s*\}\}/g, (_, key) => {
    const v = vars[key];
    return v === undefined || v === null ? '' : String(v);
  });
}

function pluralVars(count) {
  return { count, s: count === 1 ? '' : 's', ies: count === 1 ? 'y' : 'ies' };
}

// ---------------------------------------------------------------------------
// Presenter state (active industry + offline toggle), persisted in app_state
// ---------------------------------------------------------------------------

const state = { industrySlug: 'insurance', forcedOffline: false };

async function loadState() {
  for (const row of await q('SELECT key, value FROM app_state')) {
    if (row.key === 'active_industry') state.industrySlug = row.value;
    if (row.key === 'offline_mode') state.forcedOffline = row.value === 'true';
  }
}
async function saveState(key, value) {
  await pool.query(
    'INSERT INTO app_state (key, value) VALUES ($1, $2) ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value',
    [key, value]
  );
}
function isOffline() {
  return state.forcedOffline || !LLM.apiKey;
}
function modeInfo() {
  return {
    offline: isOffline(),
    forced: state.forcedOffline,
    hasKey: Boolean(LLM.apiKey),
    provider: LLM.name,
    model: LLM.model,
  };
}

// ---------------------------------------------------------------------------
// Data access
// ---------------------------------------------------------------------------

async function getIndustry() {
  let ind = await q1('SELECT * FROM industries WHERE slug = $1 AND is_active', [state.industrySlug]);
  if (!ind) ind = await q1('SELECT * FROM industries WHERE is_active ORDER BY sort_order LIMIT 1');
  if (!ind) throw new HttpError(500, 'No active industries in the database. Did the seed load?');
  return ind;
}
async function getUser(industryId) {
  return q1('SELECT * FROM app_users WHERE industry_id = $1 ORDER BY id LIMIT 1', [industryId]);
}
async function getToday() {
  return (await q1('SELECT CURRENT_DATE::text AS today')).today;
}

// The one fixed, parameterized record query. Signals and flows pass a query key; the
// window and event types come from query_definitions, never from the client.
async function runNamedQuery(industryId, key) {
  const def = await q1('SELECT * FROM query_definitions WHERE key = $1 AND industry_id = $2', [key, industryId]);
  if (!def) throw new HttpError(400, `Unknown query "${key}"`);
  const rows = await q(
    `SELECT t.id, t.name, t.email, t.phone, t.record_type, t.attributes, t.event_type, t.event,
            t.event_date::text AS event_date
       FROM (
       SELECT DISTINCT ON (r.id)
              r.id, r.name, r.email, r.phone, r.record_type, r.attributes,
              e.event_type, e.description AS event, e.event_date
         FROM records r
         JOIN life_events e ON e.record_id = r.id
        WHERE r.industry_id = $1
          AND e.event_type = ANY($2::text[])
          AND e.event_date BETWEEN CURRENT_DATE + $3::int AND CURRENT_DATE + $4::int
        ORDER BY r.id, e.event_date DESC
     ) t
     ORDER BY abs(t.event_date - CURRENT_DATE), t.name`,
    [industryId, def.event_types, def.days_from, def.days_to]
  );
  return { def, rows };
}

async function getFlow(industryId, slug) {
  const flow = await q1('SELECT * FROM flows WHERE industry_id = $1 AND slug = $2', [industryId, slug]);
  if (!flow) throw new HttpError(404, `Unknown flow "${slug}"`);
  return flow;
}

async function getProduct(industryId, productId) {
  if (!productId) return null;
  return q1('SELECT * FROM products WHERE id = $1 AND industry_id = $2', [productId, industryId]);
}

async function actionedRecordIds(industryId, flowId) {
  const rows = await q(
    `SELECT DISTINCT record_id FROM activity_log
      WHERE industry_id = $1 AND flow_id = $2 AND NOT is_seed AND record_id IS NOT NULL
        AND action_type NOT IN ('task_created', 'ticket_opened')`,
    [industryId, flowId]
  );
  return new Set(rows.map((r) => r.record_id));
}

// ---------------------------------------------------------------------------
// Eligibility, follow-up dates, template variables and fixed facts
// ---------------------------------------------------------------------------

const OPS = {
  '>=': (a, b) => a >= b,
  '>': (a, b) => a > b,
  '<=': (a, b) => a <= b,
  '<': (a, b) => a < b,
  '=': (a, b) => a === b,
  '==': (a, b) => a === b,
  '!=': (a, b) => a !== b,
};

function evaluateEligibility(product, attributes) {
  if (!product) return { eligible: false, failed: [] };
  const rules = (product.eligibility_rules && product.eligibility_rules.all) || [];
  const failed = rules.filter((rule) => {
    const op = OPS[rule.op];
    const actual = attributes[rule.attr];
    if (!op || actual === undefined || actual === null) return true;
    const numeric = typeof rule.value === 'number';
    return !op(numeric ? Number(actual) : String(actual), rule.value);
  });
  return { eligible: failed.length === 0, failed };
}

function computeFollowUp(rule, today) {
  let due = addDays(today, 3);
  if (rule && rule.weekday) {
    // ISO weekday: 1 = Monday ... 7 = Sunday. Always strictly after today.
    const target = Number(rule.weekday) % 7; // JS: 0 = Sunday
    let d = addDays(today, 1);
    while (parseISODate(d).getUTCDay() !== target) d = addDays(d, 1);
    due = d;
  } else if (rule && rule.business_days) {
    let d = today;
    let left = Number(rule.business_days);
    while (left > 0) {
      d = addDays(d, 1);
      const wd = parseISODate(d).getUTCDay();
      if (wd !== 0 && wd !== 6) left--;
    }
    due = d;
  } else if (rule && rule.days) {
    due = addDays(today, Number(rule.days));
  }
  const diff = daysBetween(today, due);
  const dayLabel = diff === 1 ? 'tomorrow' : diff <= 6 ? WEEKDAYS[parseISODate(due).getUTCDay()] : formatDateLong(due);
  return { due, dueLong: formatDateLong(due), dayLabel, days: diff };
}

// All events of the given records, as { recordId: { event_type: 'YYYY-MM-DD' } }.
async function eventDatesFor(recordIds) {
  const rows = await q(
    `SELECT record_id, event_type, event_date::text AS event_date
       FROM life_events WHERE record_id = ANY($1::int[]) ORDER BY event_date`,
    [recordIds]
  );
  const map = {};
  for (const r of rows) (map[r.record_id] ||= {})[r.event_type] = r.event_date;
  return map;
}

function baseVars({ industry, user, today, flow, followUp }) {
  return {
    company: industry.company_name,
    company_short: industry.logo_text,
    record_noun: industry.record_noun,
    sender: user.name,
    sender_first: user.name.split(' ')[0],
    sender_role: user.role,
    sender_email: user.email,
    today: formatDateLong(today),
    follow_up_date: followUp ? followUp.dueLong : '',
    follow_up_day: followUp ? followUp.dayLabel : '',
    flow_title: flow ? flow.title : '',
  };
}

function productVars(product, attributes, edits = {}) {
  if (!product) {
    return { product: '', product_description: '', price: '', price_unit: '', discount_pct: 0, discounted_price: '', savings: '', eligible: false, eligibility_note: '' };
  }
  const { eligible, failed } = evaluateEligibility(product, attributes || {});
  const discount = eligible ? ('discount_pct' in edits ? edits.discount_pct : Number(product.discount_pct)) : 0;
  const price = 'price' in edits ? edits.price : Number(product.price);
  const discounted = round2(price * (1 - discount / 100));
  return {
    product: product.name,
    product_description: product.description,
    price: formatMoney(price),
    price_unit: product.price_unit,
    discount_pct: discount,
    discounted_price: formatMoney(discounted),
    savings: formatMoney(round2(price - discounted)),
    eligible,
    eligibility_note: failed.map((f) => `requires ${f.label || `${f.attr} ${f.op} ${f.value}`}`).join('; '),
  };
}

// Reviewer edits of fact values arrive as { recordId: { key: value } }. Dates are
// YYYY-MM-DD, everything else a non-negative number. Invalid values are ignored.
function parseOverrides(raw) {
  const out = {};
  if (!raw || typeof raw !== 'object') return out;
  for (const [id, values] of Object.entries(raw)) {
    if (Number.isInteger(Number(id)) && values && typeof values === 'object') out[Number(id)] = values;
  }
  return out;
}

function overrideValue(kind, v) {
  if (kind === 'date') {
    return typeof v === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(v) && toISODate(parseISODate(v)) === v ? v : null;
  }
  const n = typeof v === 'number' ? v : typeof v === 'string' && v.trim() ? Number(v) : NaN;
  return Number.isFinite(n) && n >= 0 ? n : null;
}

function formatFactVar(kind, v) {
  if (kind === 'date') return formatDateLong(v);
  if (kind === 'money') return formatMoney(v);
  if (kind === 'quantity') return formatNumber(v);
  return v;
}

// Facts calculated from other values, with how the review screen explains them. They are
// never edited directly, so the price, discount and result always agree.
const DERIVED_FACTS = {
  discounted_price: 'Price minus the discount',
  savings: 'Price times the discount',
  follow_up_date: 'Set by Follow-up in (days)',
};

// The raw value a reviewer edits for a fact (ISO date or plain number), or null when
// the fact is derived from other values.
function factInput(fact, vars, record, eventDates) {
  if (fact.key in DERIVED_FACTS) return null;
  if (fact.kind === 'date') {
    if (fact.key === 'event_date') return record.event_date || null;
    const events = eventDates[record.id] || {};
    return fact.key.startsWith('date_') ? events[fact.key.slice(5)] || null : null;
  }
  const v = vars[fact.key];
  if (typeof v === 'number') return v;
  if (typeof v !== 'string' || !v) return null;
  const n = numberFrom(v.replace(/^\$/, ''));
  return Number.isFinite(n) ? n : null;
}

// Variables for one record, with the reviewer's fact edits applied. Attributes named by
// money/quantity facts are formatted. Also returns the editable raw value of each fact.
function recordVars({ base, record, eventDates, product, facts, today, overrides = {} }) {
  const attrs = record.attributes || {};
  const edits = {};
  for (const fact of facts || []) {
    if (!(fact.key in overrides) || fact.key in DERIVED_FACTS) continue;
    const v = overrideValue(fact.kind, overrides[fact.key]);
    if (v !== null) edits[fact.key] = v;
  }
  const vars = { ...base };
  for (const [k, v] of Object.entries(attrs)) {
    if (v !== null && typeof v !== 'object') vars[k] = v;
  }
  const factKinds = Object.fromEntries((facts || []).map((f) => [f.key, f.kind]));
  for (const [k, kind] of Object.entries(factKinds)) {
    if (!(k in attrs) || typeof attrs[k] !== 'number') continue;
    if (kind === 'money') vars[k] = formatMoney(attrs[k]);
    if (kind === 'quantity') vars[k] = formatNumber(attrs[k]);
  }
  const eventDate = edits.event_date || record.event_date;
  const parts = record.name.trim().split(/\s+/);
  Object.assign(vars, {
    record_id: record.id,
    name: record.name,
    first_name: attrs.first_name || parts[0],
    last_name: parts.length > 1 ? parts[parts.length - 1] : '',
    email: record.email || '',
    phone: record.phone || '',
    record_type: record.record_type,
    event: record.event || '',
    event_type: record.event_type || '',
    event_date: eventDate ? formatDateLong(eventDate) : '',
    days_since: eventDate ? Math.max(0, daysBetween(eventDate, today)) : '',
    days_until: eventDate ? Math.max(0, daysBetween(today, eventDate)) : '',
  });
  for (const [type, iso] of Object.entries(eventDates[record.id] || {})) vars[`date_${type}`] = formatDateLong(iso);
  Object.assign(vars, productVars(product, attrs, edits));

  const inputs = {};
  for (const fact of facts || []) {
    const input = factInput(fact, vars, record, eventDates);
    if (input === null) continue;
    if (fact.key in edits) {
      inputs[fact.key] = edits[fact.key];
      vars[fact.key] = formatFactVar(fact.kind, edits[fact.key]);
    } else {
      inputs[fact.key] = input;
    }
  }
  return { vars, inputs };
}

function factDisplay(fact, value) {
  if (value === undefined || value === null || value === '') return null;
  switch (fact.kind) {
    case 'percent':
      return Number(value) ? `${value}%` : null;
    case 'money':
    case 'date':
      return String(value);
    case 'age':
      return String(value);
    case 'quantity':
      return `${value} ${fact.unit || ''}`.trim();
    default:
      return String(value);
  }
}

// The facts shown for review and passed to the model. Each carries the value before the
// reviewer's edits (original) so the edit can be shown and logged; duplicates are
// dropped by their database value so a fact never disappears while it is being edited.
function buildFacts(facts, { vars, inputs, originalVars, recordId }, labelSuffix = '') {
  const out = [];
  const seen = new Set();
  for (const fact of facts || []) {
    const display = factDisplay(fact, vars[fact.key]);
    const original = factDisplay(fact, originalVars[fact.key]);
    if (!display || !original) continue;
    const id = `${fact.kind}:${original}`;
    if (seen.has(id)) continue;
    seen.add(id);
    out.push({
      key: fact.key,
      record_id: recordId,
      label: fact.label + labelSuffix,
      kind: fact.kind,
      unit: fact.unit || '',
      value: display,
      input: fact.key in inputs ? inputs[fact.key] : null,
      derived: DERIVED_FACTS[fact.key] || null,
      original: display === original ? null : original,
    });
  }
  return out;
}

// Everything a flow step needs for a set of selected records: variables, rendered
// prompt, recipients and the fixed facts. Used by review, draft, check and approve so
// the server (not the browser) is always the source of truth.
async function buildFlowContext(industry, flow, recordIds, productId, followUpDays, overrides = {}) {
  const steps = flow.steps || {};
  const ids = [...new Set((recordIds || []).map(Number).filter(Number.isInteger))].slice(0, 50);
  if (!ids.length) throw new HttpError(400, 'Select at least one record.');

  const { rows } = await runNamedQueryForFlow(industry, flow, ids);
  if (rows.length !== ids.length) throw new HttpError(400, 'One or more selected records are not available for this flow.');
  const byId = new Map(rows.map((r) => [r.id, r]));
  const records = ids.map((id) => byId.get(id));

  const user = await getUser(industry.id);
  const today = await getToday();
  const product = productId === null ? null : await getProduct(industry.id, productId === undefined ? flow.product_id : productId);
  const days = Number(followUpDays);
  const followUpRule = Number.isInteger(days) && days >= 1 && days <= 60 ? { days } : steps.approve && steps.approve.follow_up;
  const followUp = computeFollowUp(followUpRule, today);
  const template = await q1('SELECT template_text FROM prompt_templates WHERE flow_id = $1 ORDER BY id LIMIT 1', [flow.id]);
  const offline = await q1(`SELECT response_text FROM offline_responses WHERE flow_id = $1 AND kind = 'draft' ORDER BY id LIMIT 1`, [flow.id]);
  const eventDates = await eventDatesFor(ids);
  const base = baseVars({ industry, user, today, flow, followUp });
  const perRecord = records.map((record) => {
    const args = { base, record, eventDates, product, facts: steps.facts, today };
    const { vars, inputs } = recordVars({ ...args, overrides: overrides[record.id] || {} });
    const originalVars = overrides[record.id] ? recordVars(args).vars : vars;
    return { vars, inputs, originalVars, recordId: record.id };
  });

  const makeItem = (vars, facts, itemRecords) => {
    const prompt = renderTemplate(template ? template.template_text : '', vars);
    return {
      record_ids: itemRecords.map((r) => r.id),
      names: itemRecords.map((r) => r.name),
      title: itemRecords.length === 1 ? itemRecords[0].name : `${itemRecords.length} ${industry.record_noun}`,
      vars,
      prompt,
      offline_text: renderTemplate(offline ? offline.response_text : '', vars),
      to: renderTemplate(steps.to || '', vars),
      cc: renderTemplate(steps.cc || '', vars),
      subject: renderTemplate(steps.subject || '', vars),
      facts,
      // Text the draft is allowed to take numbers from: the DB-rendered prompt (not the
      // presenter-edited one), product description and the fixed facts.
      grounding: [prompt, vars.product_description || '', facts.map((f) => f.value).join(' ')].join('\n'),
    };
  };

  let items;
  if (steps.draft_mode === 'combined') {
    const listTemplate = steps.list_template || '- {{name}}: {{event}} ({{event_date}})';
    const vars = {
      ...perRecord[0].vars,
      ...pluralVars(records.length),
      records_list: perRecord.map((r) => renderTemplate(listTemplate, r.vars)).join('\n'),
      names: joinNames(records.map((r) => r.name)),
    };
    const facts = perRecord.flatMap((r, i) => buildFacts(steps.facts, r, records.length > 1 ? ` (${records[i].name})` : ''));
    items = [makeItem(vars, facts, records)];
  } else {
    items = perRecord.map((r, i) => makeItem({ ...r.vars, ...pluralVars(1), names: records[i].name, records_list: '' }, buildFacts(steps.facts, r), [records[i]]));
  }

  const ineligible = product && Object.keys(product.eligibility_rules || {}).length
    ? perRecord.filter((r) => !r.vars.eligible).map((r) => ({ name: r.vars.name, note: r.vars.eligibility_note }))
    : [];

  return { steps, product, followUp, items, ineligible, today };
}

// Records selected in a flow must come from one of that flow's own named queries (its
// default or one of its signals), so the client cannot pull arbitrary records.
async function runNamedQueryForFlow(industry, flow, ids) {
  const keys = new Set([flow.steps && flow.steps.query].filter(Boolean));
  for (const s of await q('SELECT count_query FROM signals WHERE flow_id = $1', [flow.id])) keys.add(s.count_query);
  const all = new Map();
  for (const key of keys) {
    const { rows } = await runNamedQuery(industry.id, key);
    for (const r of rows) if (!all.has(r.id)) all.set(r.id, r);
  }
  return { rows: ids.map((id) => all.get(id)).filter(Boolean) };
}

function joinNames(names) {
  if (names.length <= 1) return names.join('');
  return `${names.slice(0, -1).join(', ')} and ${names[names.length - 1]}`;
}

// ---------------------------------------------------------------------------
// Accuracy guard: every %, $, date, age and fact quantity in the draft must appear in
// the grounded text (DB facts + DB-rendered prompt). Anything else is flagged.
// ---------------------------------------------------------------------------

const MONTH_RE = '(Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|June?|July?|Aug(?:ust)?|Sep(?:t(?:ember)?)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)';

function numberFrom(s) {
  return Number(String(s).replace(/,/g, ''));
}

function extractValues(text, units) {
  const found = { percent: [], money: [], date: [], age: [], quantity: [] };
  const t = String(text || '');
  for (const m of t.matchAll(/(\d+(?:\.\d+)?)\s?(?:%|percent\b)/gi)) found.percent.push({ raw: m[0], num: Number(m[1]) });
  for (const m of t.matchAll(/\$\s?(\d{1,3}(?:,\d{3})+|\d+)(\.\d{1,2})?(?:\s?(k|K|thousand|million|M)\b)?/g)) {
    let num = numberFrom(m[1] + (m[2] || ''));
    const scale = m[3] ? (/^(k|thousand)$/i.test(m[3]) ? 1000 : 1000000) : 1;
    num *= scale;
    found.money.push({ raw: m[0].trim(), num: round2(num) });
  }
  for (const m of t.matchAll(new RegExp(`\\b${MONTH_RE}\\.?\\s+(\\d{1,2})(?:st|nd|rd|th)?\\b`, 'g'))) {
    const month = MONTHS.findIndex((mm) => mm.toLowerCase().startsWith(m[1].toLowerCase().slice(0, 3)));
    found.date.push({ raw: m[0], num: `${month + 1}-${Number(m[2])}` });
  }
  const ageRe = /\b(?:turn(?:s|ed|ing)?|aged?|age of)\s+(\d{1,3})\b|\b(\d{1,3})(?:st|nd|rd|th)\s+birthday\b|\b(\d{1,3})[-\s]years?[-\s]old\b/gi;
  for (const m of t.matchAll(ageRe)) found.age.push({ raw: m[0], num: Number(m[1] || m[2] || m[3]) });
  for (const unit of units) {
    const esc = unit.replace(/[.*+?^${}()|[\]\\]/g, '\\$&').replace(/s$/, '');
    const notOld = /^year/i.test(unit) ? '(?![-\\s]+old)' : '';
    const re = new RegExp(`(\\d{1,3}(?:,\\d{3})+|\\d+(?:\\.\\d+)?)[-\\s]*${esc}s?\\b${notOld}`, 'gi');
    for (const m of t.matchAll(re)) found.quantity.push({ raw: m[0], num: numberFrom(m[1]), unit: unit.toLowerCase() });
  }
  return found;
}

// The fact of the same kind whose value is numerically closest to what the draft says,
// so "$330" is compared with the $350.20 offer price rather than the list price.
function closestFact(facts, kind, found) {
  let best = null;
  for (const f of facts) {
    if (f.kind !== kind || (kind === 'quantity' && f.unit.toLowerCase() !== found.unit)) continue;
    const v = extractValues(f.value, f.unit ? [f.unit] : [])[kind][0];
    const dist = v && typeof v.num === 'number' && typeof found.num === 'number' ? Math.abs(v.num - found.num) : 0;
    if (!best || dist < best.dist) best = { fact: f, dist };
  }
  return best ? best.fact : null;
}

function checkDraft(text, item) {
  const units = [...new Set(item.facts.filter((f) => f.kind === 'quantity' && f.unit).map((f) => f.unit))];
  const allowed = extractValues(item.grounding, units);
  const draft = extractValues(text, units);
  const issues = [];
  const kindLabel = { percent: 'percentage', money: 'amount', date: 'date', age: 'age', quantity: 'quantity' };
  for (const kind of Object.keys(draft)) {
    const allowedNums = new Set(allowed[kind].map((v) => `${v.unit || ''}|${v.num}`));
    const reported = new Set();
    for (const v of draft[kind]) {
      if (allowedNums.has(`${v.unit || ''}|${v.num}`) || reported.has(v.raw)) continue;
      reported.add(v.raw);
      const expected = closestFact(item.facts, kind, v);
      issues.push({
        kind,
        found: v.raw,
        expected: expected ? expected.value : null,
        label: expected ? expected.label : kindLabel[kind],
        message: expected
          ? `Draft says ${v.raw}, ${expected.original ? 'your review says' : 'database says'} ${expected.value} (${expected.label.toLowerCase()})`
          : `${v.raw} doesn't come from the database`,
      });
    }
  }
  const draftNums = new Set(Object.values(draft).flat().map((v) => `${v.num}`));
  const verified = item.facts.filter((f) => {
    const vals = extractValues(f.value, f.unit ? [f.unit] : []);
    return Object.values(vals).flat().some((v) => draftNums.has(`${v.num}`));
  });
  return { ok: issues.length === 0, issues, verified: verified.map((f) => ({ label: f.label, value: f.value })) };
}

// ---------------------------------------------------------------------------
// Flow routing (typed message -> flow) and knowledge base search
// ---------------------------------------------------------------------------

function normalizeText(s) {
  return ` ${String(s).toLowerCase().replace(/[-_/]+/g, ' ').replace(/[^a-z0-9%$' ]+/g, ' ').replace(/\s+/g, ' ').trim()} `;
}

async function matchFlow(industryId, text) {
  const flows = await q('SELECT * FROM flows WHERE industry_id = $1 ORDER BY sort_order, id', [industryId]);
  const norm = normalizeText(text);
  let best = null;
  for (const flow of flows) {
    let score = 0;
    for (const kw of flow.keywords || []) {
      const k = normalizeText(kw);
      if (k.trim() && norm.includes(k)) score += k.trim().split(' ').length;
    }
    if (score > 0 && (!best || score > best.score)) best = { flow, score };
  }
  return best ? best.flow : null;
}

const STOPWORDS = new Set('a an and are as at be by can do does for from has have how i if in is it its me my of on or our should so that the their them there these they this to us was we what when where which who why will with would you your about tell please much many'.split(' '));

async function searchKnowledge(industryId, text, limit = 3) {
  const words = [...new Set(String(text).toLowerCase().match(/[a-z0-9]{2,}/g) || [])].filter((w) => !STOPWORDS.has(w)).slice(0, 12);
  if (!words.length) return [];
  // Words are reduced to [a-z0-9] above, so the tsquery text cannot inject operators.
  const tsquery = words.map((w) => `${w}:*`).join(' | ');
  return q(
    `SELECT id, source, section_title, content, ts_rank(search_vector, query) AS rank
       FROM knowledge_base, to_tsquery('english', $2) AS query
      WHERE industry_id = $1 AND search_vector @@ query
      ORDER BY rank DESC, id
      LIMIT $3`,
    [industryId, tsquery, limit]
  );
}

// ---------------------------------------------------------------------------
// LLM streaming (OpenRouter or OpenAI) with an offline safety net
// ---------------------------------------------------------------------------

async function* llmStream(messages, { temperature, maxTokens, signal }) {
  const res = await fetch(`${LLM.baseUrl}/chat/completions`, {
    method: 'POST',
    signal,
    headers: {
      Authorization: `Bearer ${LLM.apiKey}`,
      'Content-Type': 'application/json',
      ...LLM.headers,
    },
    body: JSON.stringify({ model: LLM.model, messages, ...LLM.params({ temperature, maxTokens }), stream: true }),
  });
  if (!res.ok) {
    const body = await res.text().catch(() => '');
    throw new Error(`${LLM.name} returned ${res.status}: ${body.slice(0, 300)}`);
  }
  const decoder = new TextDecoder();
  let buffer = '';
  for await (const chunk of res.body) {
    buffer += decoder.decode(chunk, { stream: true });
    let idx;
    while ((idx = buffer.indexOf('\n')) >= 0) {
      const line = buffer.slice(0, idx).trim();
      buffer = buffer.slice(idx + 1);
      if (!line.startsWith('data:')) continue; // ": OPENROUTER PROCESSING" keep-alives
      const data = line.slice(5).trim();
      if (data === '[DONE]') return;
      let json;
      try {
        json = JSON.parse(data);
      } catch {
        continue;
      }
      if (json.error) throw new Error(json.error.message || `${LLM.name} stream error`);
      const delta = json.choices && json.choices[0] && json.choices[0].delta && json.choices[0].delta.content;
      if (delta) yield delta;
    }
  }
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

// Stream pre-written text word by word so offline looks like live generation.
async function streamOffline(text, send, isClosed) {
  await sleep(450 + Math.random() * 350);
  const tokens = String(text).match(/\S+\s*|\s+/g) || [];
  for (const tok of tokens) {
    if (isClosed()) return;
    send('token', { t: tok });
    const pause = /[.!?:]\s*$/.test(tok) ? 70 : /\n/.test(tok) ? 90 : 22;
    await sleep(pause + Math.random() * 26);
  }
}

// Generates text live (or offline) and streams it as SSE `token` events. Returns the
// full text. Live failures before the first token fall back to the offline text.
async function generate({ messages, temperature, maxTokens, offlineText, send, isClosed, signal }) {
  if (isOffline()) {
    send('meta', { source: 'offline' });
    await streamOffline(offlineText, send, isClosed);
    return { text: offlineText, source: 'offline' };
  }
  const controller = new AbortController();
  const abortOnClose = () => controller.abort();
  signal.addEventListener('abort', abortOnClose);
  const timer = setTimeout(() => controller.abort(), FIRST_TOKEN_TIMEOUT_MS);
  let text = '';
  try {
    send('meta', { source: 'live', model: LLM.model });
    for await (const delta of llmStream(messages, { temperature, maxTokens, signal: controller.signal })) {
      clearTimeout(timer);
      text += delta;
      send('token', { t: delta });
    }
    clearTimeout(timer);
    if (!text.trim()) throw new Error('The model returned an empty response');
    return { text, source: 'live' };
  } catch (err) {
    clearTimeout(timer);
    if (isClosed()) return { text, source: 'live' };
    console.warn(`[llm] ${err.message}`);
    if (text) {
      send('warning', { message: 'The live model stopped mid-response.' });
      return { text, source: 'live' };
    }
    send('meta', { source: 'offline', fallback: true, reason: err.name === 'AbortError' ? 'timeout' : 'error' });
    await streamOffline(offlineText, send, isClosed);
    return { text: offlineText, source: 'offline' };
  } finally {
    signal.removeEventListener('abort', abortOnClose);
  }
}

// ---------------------------------------------------------------------------
// HTTP plumbing
// ---------------------------------------------------------------------------

class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

function sendJson(res, status, body) {
  const data = JSON.stringify(body);
  res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store' });
  res.end(data);
}

async function readJson(req) {
  let size = 0;
  const chunks = [];
  for await (const chunk of req) {
    size += chunk.length;
    if (size > 1_000_000) throw new HttpError(413, 'Request body too large');
    chunks.push(chunk);
  }
  if (!chunks.length) return {};
  try {
    return JSON.parse(Buffer.concat(chunks).toString('utf8'));
  } catch {
    throw new HttpError(400, 'Invalid JSON');
  }
}

function openSse(req, res) {
  res.writeHead(200, {
    'Content-Type': 'text/event-stream; charset=utf-8',
    'Cache-Control': 'no-cache, no-transform',
    Connection: 'keep-alive',
    'X-Accel-Buffering': 'no',
  });
  res.flushHeaders();
  const controller = new AbortController();
  let closed = false;
  res.on('close', () => {
    closed = true;
    controller.abort();
  });
  return {
    send(event, data) {
      if (!closed) res.write(`event: ${event}\ndata: ${JSON.stringify(data)}\n\n`);
    },
    end() {
      if (!closed) res.end();
    },
    isClosed: () => closed,
    signal: controller.signal,
  };
}

// ---------------------------------------------------------------------------
// Chats
// ---------------------------------------------------------------------------

async function ensureChat(industryId, chatId, title) {
  if (chatId) {
    const chat = await q1('SELECT id, title FROM chats WHERE id = $1 AND industry_id = $2', [chatId, industryId]);
    if (chat) return chat;
  }
  const clean = String(title || 'New chat').replace(/\s+/g, ' ').trim();
  const short = clean.length > 60 ? `${clean.slice(0, 57).trimEnd()}...` : clean;
  return q1('INSERT INTO chats (industry_id, title) VALUES ($1, $2) RETURNING id, title', [industryId, short || 'New chat']);
}

async function addMessage(chatId, role, content, kind = 'text', payload = {}) {
  await pool.query('INSERT INTO chat_messages (chat_id, role, kind, content, payload) VALUES ($1, $2, $3, $4, $5)', [chatId, role, kind, content, payload]);
  await pool.query('UPDATE chats SET updated_at = now() WHERE id = $1', [chatId]);
}

// ---------------------------------------------------------------------------
// Route handlers
// ---------------------------------------------------------------------------

async function signalsFor(industry) {
  const signals = await q(
    `SELECT s.*, f.slug AS flow_slug FROM signals s JOIN flows f ON f.id = s.flow_id
      WHERE s.industry_id = $1 ORDER BY s.sort_order, s.id`,
    [industry.id]
  );
  const out = [];
  for (const s of signals) {
    const { rows } = await runNamedQuery(industry.id, s.count_query);
    const done = await actionedRecordIds(industry.id, s.flow_id);
    out.push({
      id: s.id,
      title: renderTemplate(s.title, pluralVars(rows.length)),
      description: s.description,
      severity: s.severity,
      count: rows.length,
      actioned: rows.filter((r) => done.has(r.id)).length,
      flow_slug: s.flow_slug,
    });
  }
  return out;
}

async function handleState(req, res) {
  const industry = await getIndustry();
  const user = await getUser(industry.id);
  const [industries, signals, suggestions, flows, chats, stats] = await Promise.all([
    q('SELECT slug, name, company_name, logo_text FROM industries WHERE is_active ORDER BY sort_order, id'),
    signalsFor(industry),
    q('SELECT id, title, prompt, icon FROM suggestions WHERE industry_id = $1 ORDER BY sort_order, id', [industry.id]),
    q('SELECT slug, title, description, flow_type, icon FROM flows WHERE industry_id = $1 ORDER BY sort_order, id', [industry.id]),
    q('SELECT id, title, updated_at FROM chats WHERE industry_id = $1 ORDER BY updated_at DESC, id DESC LIMIT 12', [industry.id]),
    q1('SELECT count(*)::int AS records FROM records WHERE industry_id = $1', [industry.id]),
  ]);
  sendJson(res, 200, {
    industry: { slug: industry.slug, name: industry.name, company_name: industry.company_name, logo_text: industry.logo_text, record_noun: industry.record_noun },
    industries,
    user: user && { name: user.name, first_name: user.name.split(' ')[0], role: user.role, email: user.email },
    mode: modeInfo(),
    signals,
    suggestions,
    assistants: flows,
    chats,
    stats,
  });
}

async function handleSetIndustry(req, res) {
  const { slug } = await readJson(req);
  const ind = await q1('SELECT slug FROM industries WHERE slug = $1 AND is_active', [String(slug || '')]);
  if (!ind) throw new HttpError(400, 'Unknown industry');
  state.industrySlug = ind.slug;
  await saveState('active_industry', ind.slug);
  sendJson(res, 200, { ok: true });
}

async function handleSetOffline(req, res) {
  const { enabled } = await readJson(req);
  state.forcedOffline = Boolean(enabled);
  await saveState('offline_mode', String(state.forcedOffline));
  sendJson(res, 200, modeInfo());
}

async function handleReset(req, res) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const a = await client.query('DELETE FROM activity_log WHERE NOT is_seed');
    const t = await client.query('DELETE FROM tasks WHERE NOT is_seed');
    const c = await client.query('DELETE FROM chats WHERE NOT is_seed');
    await client.query('COMMIT');
    sendJson(res, 200, { ok: true, deleted: { activity: a.rowCount, tasks: t.rowCount, chats: c.rowCount } });
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

async function handleGetChat(req, res, chatId) {
  const industry = await getIndustry();
  const chat = await q1('SELECT id, title FROM chats WHERE id = $1 AND industry_id = $2', [chatId, industry.id]);
  if (!chat) throw new HttpError(404, 'Chat not found');
  const messages = await q('SELECT id, role, kind, content, payload, created_at FROM chat_messages WHERE chat_id = $1 ORDER BY id', [chatId]);
  sendJson(res, 200, { chat, messages });
}

async function flowStartData(industry, flow, queryKey) {
  const steps = flow.steps || {};
  const key = queryKey || steps.query;
  const { rows } = await runNamedQuery(industry.id, key);
  const product = await getProduct(industry.id, flow.product_id);
  const done = await actionedRecordIds(industry.id, flow.id);
  const records = rows.map((r) => {
    const elig = product && Object.keys(product.eligibility_rules || {}).length ? evaluateEligibility(product, r.attributes || {}) : null;
    return {
      id: r.id,
      name: r.name,
      email: r.email,
      phone: r.phone,
      contact: steps.contact_field === 'phone' ? r.phone : r.email,
      change: r.event,
      event_date: formatDateShort(r.event_date),
      eligible: elig ? elig.eligible : null,
      actioned: done.has(r.id),
    };
  });
  const eligibleCount = records.filter((r) => r.eligible !== false).length;
  const pv = productVars(product, {});
  // Agent steps may also quote the attributes of the first matching record (useful when a
  // signal points at one thing, such as a single held shipment). Numbers are formatted.
  const firstAttrs = {};
  for (const [k, v] of Object.entries((rows[0] && rows[0].attributes) || {})) {
    if (v !== null && typeof v !== 'object') firstAttrs[k] = typeof v === 'number' ? formatNumber(v) : v;
  }
  const stepVars = {
    ...firstAttrs,
    ...pluralVars(records.length),
    record_noun: industry.record_noun,
    eligible_count: eligibleCount,
    product: pv.product,
    discount_pct: product ? Number(product.discount_pct) : 0,
  };
  const products = await q('SELECT id, name, price, price_unit, discount_pct FROM products WHERE industry_id = $1 ORDER BY id', [industry.id]);
  return {
    flow: {
      slug: flow.slug,
      title: flow.title,
      description: flow.description,
      flow_type: flow.flow_type,
      icon: flow.icon,
      draft_mode: steps.draft_mode || 'per_record',
      content_type: steps.content_type || 'Email',
      has_subject: Boolean(steps.subject),
      approve_label: (steps.approve && steps.approve.label) || 'Approve',
    },
    agent_steps: (steps.agent_steps || []).map((s) => renderTemplate(s, stepVars)),
    table: {
      title: steps.table_title || flow.title,
      hint: steps.select_hint || 'Select the records to include.',
      change_label: steps.change_label || 'Recent change',
      contact_label: steps.contact_field === 'phone' ? 'Phone' : 'Email',
      show_eligibility: Boolean(product && Object.keys(product.eligibility_rules || {}).length),
    },
    records,
    products: products.map((p) => ({ id: p.id, name: p.name, label: `${p.name} (${formatMoney(p.price)}${p.price_unit}${Number(p.discount_pct) ? `, ${Number(p.discount_pct)}% off` : ''})` })),
    default_product_id: flow.product_id,
  };
}

async function handleFlowStart(req, res, slug) {
  const industry = await getIndustry();
  const flow = await getFlow(industry.id, slug);
  const body = await readJson(req);
  let queryKey = null;
  if (body.signal_id) {
    const signal = await q1('SELECT count_query FROM signals WHERE id = $1 AND flow_id = $2', [Number(body.signal_id), flow.id]);
    if (signal) queryKey = signal.count_query;
  }
  const chat = await ensureChat(industry.id, body.chat_id, body.title || flow.title);
  if (body.user_text) await addMessage(chat.id, 'user', String(body.user_text).slice(0, 2000));
  const data = await flowStartData(industry, flow, queryKey);
  await addMessage(chat.id, 'assistant', `${flow.title}: found ${data.records.length} ${industry.record_noun}.`, 'flow', { flow_slug: flow.slug, stage: 'started', count: data.records.length });
  sendJson(res, 200, { chat, ...data });
}

// The review settings (product, follow-up and fact edits) every flow step is called with.
function flowContextFor(industry, flow, body, recordIds) {
  const productId = body.product_id === null ? null : body.product_id === undefined ? undefined : Number(body.product_id);
  return buildFlowContext(industry, flow, recordIds, productId, body.follow_up_days, parseOverrides(body.overrides));
}

function publicItem(item) {
  return {
    record_ids: item.record_ids,
    names: item.names,
    title: item.title,
    prompt: item.prompt,
    to: item.to,
    cc: item.cc,
    subject: item.subject,
    facts: item.facts,
  };
}

async function handleFlowReview(req, res, slug) {
  const industry = await getIndustry();
  const flow = await getFlow(industry.id, slug);
  const body = await readJson(req);
  const ctx = await flowContextFor(industry, flow, body, body.record_ids);
  sendJson(res, 200, {
    product: ctx.product && { id: ctx.product.id, name: ctx.product.name, description: ctx.product.description },
    items: ctx.items.map(publicItem),
    ineligible: ctx.ineligible,
    follow_up: { label: ctx.followUp.dayLabel, date: ctx.followUp.dueLong, days: ctx.followUp.days },
  });
}

function draftMessages(industry, flow, item, promptText) {
  const steps = flow.steps || {};
  const contentType = steps.content_type || 'Email';
  const factsBlock = item.facts.length
    ? item.facts.map((f) => `- ${f.label}: ${f.value}`).join('\n')
    : '- (none for this message)';
  const system = [
    `You draft ${contentType.toLowerCase()} messages for ${item.vars.sender}, ${item.vars.sender_role} at ${industry.company_name}.`,
    'FIXED FACTS from the company database. Use these values exactly as written. Never change, round, estimate or invent any number, price, percentage, date, age or quantity. If a value is not listed here or in the request, do not state it.',
    factsBlock,
    'Rules:',
    '- Output only the message body. No subject line, no preamble, no notes to the user, no markdown headings.',
    '- Never use placeholders like [Name] or [Phone]; write the finished message.',
    contentType === 'SMS'
      ? '- This is a text message: under 320 characters, no sign-off block, never ask for passwords, PINs or full card numbers.'
      : `- Sign off as ${item.vars.sender}, ${item.vars.sender_role}, ${industry.company_name}.`,
    '- Do not use em dashes.',
  ].join('\n');
  return [
    { role: 'system', content: system },
    { role: 'user', content: String(promptText || item.prompt).slice(0, 6000) },
  ];
}

async function handleFlowDraft(req, res, slug) {
  const industry = await getIndustry();
  const flow = await getFlow(industry.id, slug);
  const body = await readJson(req);
  const ctx = await flowContextFor(industry, flow, body, body.record_ids);
  const item = ctx.items[0];
  const sse = openSse(req, res);
  try {
    const result = await generate({
      messages: draftMessages(industry, flow, item, body.prompt),
      temperature: DRAFT_TEMPERATURE,
      maxTokens: 700,
      offlineText: item.offline_text,
      send: sse.send,
      isClosed: sse.isClosed,
      signal: sse.signal,
    });
    const text = result.text.trim();
    sse.send('done', { text, source: result.source, check: checkDraft(text, item) });
  } catch (err) {
    console.error(err);
    sse.send('error', { message: 'Drafting failed. Please try again.' });
  }
  sse.end();
}

async function handleFlowCheck(req, res, slug) {
  const industry = await getIndustry();
  const flow = await getFlow(industry.id, slug);
  const body = await readJson(req);
  const ctx = await flowContextFor(industry, flow, body, body.record_ids);
  sendJson(res, 200, checkDraft(String(body.text || ''), ctx.items[0]));
}

async function handleFlowApprove(req, res, slug) {
  const industry = await getIndustry();
  const flow = await getFlow(industry.id, slug);
  const body = await readJson(req);
  const steps = flow.steps || {};
  const approve = steps.approve || {};
  const items = Array.isArray(body.items) ? body.items.slice(0, 50) : [];
  if (!items.length) throw new HttpError(400, 'Nothing to approve');

  const chat = await ensureChat(industry.id, body.chat_id, flow.title);
  const results = [];
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    for (const sent of items) {
      const ctx = await flowContextFor(industry, flow, body, sent.record_ids);
      const item = ctx.items[0];
      const text = String(sent.body || '').slice(0, 20000);
      if (!text.trim()) throw new HttpError(400, 'The draft is empty.');
      const check = checkDraft(text, item);
      const primaryRecord = item.record_ids[0];
      const payload = {
        to: String(sent.to || '').slice(0, 500),
        cc: String(sent.cc || '').slice(0, 500),
        subject: String(sent.subject || '').slice(0, 500),
        body: text,
        content_type: steps.content_type || 'Email',
        product: ctx.product ? ctx.product.name : null,
        records: item.names,
        facts_verified: check.ok,
        edited_facts: item.facts.filter((f) => f.original).map((f) => `${f.label}: ${f.original} changed to ${f.value}`),
        fact_issues: check.issues.map((i) => i.message),
        source: sent.source === 'live' ? 'live' : 'offline',
        approved_by: item.vars.sender,
      };
      const main = await client.query(
        'INSERT INTO activity_log (industry_id, record_id, flow_id, action_type, payload) VALUES ($1, $2, $3, $4, $5) RETURNING id',
        [industry.id, primaryRecord, flow.id, approve.action_type || 'email_sent', payload]
      );

      const vars = { ...item.vars, activity_id: main.rows[0].id };
      if (approve.ticket) {
        const ticketTitle = renderTemplate(approve.ticket.title, vars);
        const ticket = await client.query(
          'INSERT INTO activity_log (industry_id, record_id, flow_id, action_type, payload) VALUES ($1, $2, $3, $4, $5) RETURNING id',
          [industry.id, primaryRecord, flow.id, 'ticket_opened', { title: ticketTitle, queue: approve.ticket.queue || 'Operations' }]
        );
        vars.ticket_id = ticket.rows[0].id;
      }

      const taskTitle = renderTemplate(approve.task_title || `Follow up with {{name}}`, vars);
      const task = await client.query('INSERT INTO tasks (record_id, title, due_date) VALUES ($1, $2, $3) RETURNING id', [primaryRecord, taskTitle, ctx.followUp.due]);
      await client.query(
        'INSERT INTO activity_log (industry_id, record_id, flow_id, action_type, payload) VALUES ($1, $2, $3, $4, $5)',
        [industry.id, primaryRecord, flow.id, 'task_created', { title: taskTitle, task_id: task.rows[0].id, due_date: ctx.followUp.due, due_label: ctx.followUp.dueLong }]
      );

      results.push({
        record_ids: item.record_ids,
        names: item.names,
        confirmation: renderTemplate(approve.confirmation || '{{flow_title}} completed for {{name}}.', vars),
        activity_id: main.rows[0].id,
        ticket_id: vars.ticket_id || null,
        task: { id: task.rows[0].id, title: taskTitle, due: ctx.followUp.dueLong },
        log_label: approve.log_label || 'Logged',
        facts_verified: check.ok,
      });
    }
    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
  await addMessage(chat.id, 'assistant', results.map((r) => r.confirmation).join('\n'), 'flow', { flow_slug: flow.slug, stage: 'completed', results });
  sendJson(res, 200, { chat, results });
}

async function handleActivity(req, res) {
  const industry = await getIndustry();
  const entries = await q(
    `SELECT a.id, a.action_type, a.payload, a.is_seed, a.created_at, r.name AS record_name, f.title AS flow_title
       FROM activity_log a
       LEFT JOIN records r ON r.id = a.record_id
       LEFT JOIN flows f ON f.id = a.flow_id
      WHERE a.industry_id = $1
      ORDER BY a.created_at DESC, a.id DESC
      LIMIT 50`,
    [industry.id]
  );
  const tasks = await q(
    `SELECT t.id, t.title, t.due_date::text AS due_date, t.status, t.is_seed, r.name AS record_name
       FROM tasks t JOIN records r ON r.id = t.record_id
      WHERE r.industry_id = $1 AND t.status = 'open'
      ORDER BY t.due_date, t.id DESC LIMIT 20`,
    [industry.id]
  );
  sendJson(res, 200, {
    entries,
    tasks: tasks.map((t) => ({ ...t, due_label: formatDateLong(t.due_date) })),
  });
}

// --- Free-text chat and Q&A --------------------------------------------------

async function industryContext(industry) {
  const [records, events, products, kb, activity] = await Promise.all([
    q('SELECT id, name, email, record_type, attributes FROM records WHERE industry_id = $1 ORDER BY id', [industry.id]),
    q(
      `SELECT e.record_id, e.event_type, e.description, e.event_date::text AS event_date, e.event_date - CURRENT_DATE AS days_from_today
         FROM life_events e JOIN records r ON r.id = e.record_id WHERE r.industry_id = $1 ORDER BY e.event_date`,
      [industry.id]
    ),
    q('SELECT name, description, price, price_unit, discount_pct, eligibility_rules FROM products WHERE industry_id = $1 ORDER BY id', [industry.id]),
    q('SELECT source, section_title, content FROM knowledge_base WHERE industry_id = $1 ORDER BY id', [industry.id]),
    q(
      `SELECT a.action_type, a.payload->>'subject' AS subject, a.payload->>'title' AS title, r.name, a.created_at
         FROM activity_log a LEFT JOIN records r ON r.id = a.record_id
        WHERE a.industry_id = $1 ORDER BY a.created_at DESC LIMIT 15`,
      [industry.id]
    ),
  ]);
  const byRecord = {};
  for (const e of events) (byRecord[e.record_id] ||= []).push(e);
  const rel = (d) => (d === 0 ? 'today' : d < 0 ? `${-d} day${d === -1 ? '' : 's'} ago` : `in ${d} day${d === 1 ? '' : 's'}`);
  const recordLines = records.map((r) => {
    const evs = (byRecord[r.id] || []).map((e) => `${e.description} (${formatDateLong(e.event_date)}, ${rel(e.days_from_today)})`).join('; ');
    return `- ${r.name} <${r.email || 'no email'}> [${r.record_type}] attributes: ${JSON.stringify(r.attributes)}${evs ? ` | events: ${evs}` : ''}`;
  });
  const productLines = products.map((p) => {
    const rules = (p.eligibility_rules.all || []).map((x) => x.label || `${x.attr} ${x.op} ${x.value}`).join(', ');
    return `- ${p.name}: ${p.description} Price ${formatMoney(p.price)}${p.price_unit}; discount ${Number(p.discount_pct)}%${rules ? ` (eligibility: ${rules})` : ''}.`;
  });
  const kbLines = kb.map((k) => `### [${k.section_title}] (${k.source})\n${k.content}`);
  const activityLines = activity.map((a) => `- ${new Date(a.created_at).toISOString().slice(0, 10)} ${a.action_type}: ${a.name || ''} ${a.subject || a.title || ''}`.trim());
  return { recordLines, productLines, kbLines, activityLines };
}

async function signalsSummary(industry) {
  const signals = await signalsFor(industry);
  return signals.map((s) => `- **${s.title}**: ${s.description}`).join('\n');
}

async function pickOfflineChat(industry, text, user) {
  const rows = await q(`SELECT match_keywords, response_text FROM offline_responses WHERE industry_id = $1 AND kind = 'chat' ORDER BY id`, [industry.id]);
  const norm = normalizeText(text);
  let best = null;
  let fallback = null;
  for (const r of rows) {
    if (!r.match_keywords.length) {
      fallback ||= r;
      continue;
    }
    const score = r.match_keywords.reduce((acc, kw) => (norm.includes(normalizeText(kw)) ? acc + normalizeText(kw).trim().split(' ').length : acc), 0);
    if (score && (!best || score > best.score)) best = { ...r, score };
  }
  const chosen = best || fallback;
  const vars = { user_first: user.name.split(' ')[0], signals_summary: await signalsSummary(industry), company: industry.company_name };
  return chosen ? renderTemplate(chosen.response_text, vars) : "I'm offline right now, but I can still run any of the guided flows from the home screen.";
}

async function handleChatMessage(industry, user, chat, text, sse) {
  const today = await getToday();
  const ctx = await industryContext(industry);
  const history = await q(
    `SELECT role, content FROM chat_messages WHERE chat_id = $1 AND kind = 'text' ORDER BY id DESC LIMIT 11`,
    [chat.id]
  );
  history.reverse();
  history.pop(); // the user message we just stored is appended below
  const signals = await signalsSummary(industry);
  const system = [
    `You are the AI assistant inside ${industry.company_name}'s work platform, helping ${user.name} (${user.role}). Today is ${formatDateLong(today)}.`,
    'Answer using ONLY the business data below. Every name, number, price, percentage and date you mention must appear in this data exactly; never invent or estimate. If the data does not contain the answer, say so briefly.',
    'When you use a knowledge base section, cite it inline as [Section title].',
    'Be concise and practical: at most about 150 words, short numbered or dashed lists, **bold** names. Recommend a concrete next step (for example, offer to draft the outreach). No headings, no tables, no em dashes.',
    '',
    `## Signals right now\n${signals}`,
    `## ${industry.record_noun[0].toUpperCase()}${industry.record_noun.slice(1)} and events\n${ctx.recordLines.join('\n')}`,
    `## Products\n${ctx.productLines.join('\n')}`,
    `## Recent activity (most recent first)\n${ctx.activityLines.join('\n') || '- none'}`,
    `## Knowledge base\n${ctx.kbLines.join('\n\n')}`,
  ].join('\n');
  const messages = [{ role: 'system', content: system }, ...history.map((m) => ({ role: m.role, content: m.content })), { role: 'user', content: text }];
  const result = await generate({
    messages,
    temperature: DRAFT_TEMPERATURE,
    maxTokens: 600,
    offlineText: await pickOfflineChat(industry, text, user),
    send: sse.send,
    isClosed: sse.isClosed,
    signal: sse.signal,
  });
  const kbTitles = (await q('SELECT section_title, source FROM knowledge_base WHERE industry_id = $1', [industry.id]));
  const citations = kbTitles.filter((k) => result.text.includes(`[${k.section_title}]`)).map((k) => ({ title: k.section_title, source: k.source }));
  await addMessage(chat.id, 'assistant', result.text, 'text', { source: result.source, citations });
  sse.send('done', { text: result.text, source: result.source, citations });
}

async function handleQa(industry, user, chat, flow, text, sse) {
  const sections = await searchKnowledge(industry.id, text, 3);
  const stepVars = { ...pluralVars(sections.length), top_section: sections[0] ? sections[0].section_title : 'the knowledge base' };
  sse.send('qa', {
    flow: { slug: flow.slug, title: flow.title, icon: flow.icon },
    agent_steps: ((flow.steps && flow.steps.agent_steps) || []).map((s) => renderTemplate(s, stepVars)),
    sections: sections.map((s) => ({ id: s.id, title: s.section_title, source: s.source })),
  });
  let offlineText;
  if (sections.length) {
    const top = sections[0];
    offlineText = `Here's what the ${top.source} says:\n\n${top.content} [${top.section_title}]`;
    if (sections[1]) offlineText += `\n\nRelated: see [${sections[1].section_title}].`;
  } else {
    offlineText = "I couldn't find that in the knowledge base. Try rephrasing, or ask me about one of your signals instead.";
  }
  const system = [
    `You answer questions for ${user.name} (${user.role}) at ${industry.company_name} using ONLY the knowledge base sections below.`,
    'Cite the section each statement comes from inline, exactly as [Section title]. Quote numbers exactly as written. If the sections do not answer the question, say that you could not find it in the knowledge base. Keep it under 120 words. No headings, no em dashes.',
    '',
    sections.map((s) => `### [${s.section_title}] (${s.source})\n${s.content}`).join('\n\n') || '(no matching sections)',
  ].join('\n');
  const result = await generate({
    messages: [{ role: 'system', content: system }, { role: 'user', content: text }],
    temperature: DRAFT_TEMPERATURE,
    maxTokens: 450,
    offlineText,
    send: sse.send,
    isClosed: sse.isClosed,
    signal: sse.signal,
  });
  let cited = sections.filter((s) => result.text.includes(`[${s.section_title}]`));
  if (!cited.length && sections.length) cited = [sections[0]];
  const citations = cited.map((s) => ({ title: s.section_title, source: s.source, excerpt: s.content }));
  await addMessage(chat.id, 'assistant', result.text, 'text', { source: result.source, citations, flow_slug: flow.slug });
  sse.send('done', { text: result.text, source: result.source, citations });
}

async function handleMessage(req, res) {
  const body = await readJson(req);
  const text = String(body.text || '').trim().slice(0, 2000);
  if (!text) throw new HttpError(400, 'Message is empty');
  const industry = await getIndustry();
  const user = await getUser(industry.id);
  const flow = await matchFlow(industry.id, text);

  // Guided flows are started by the client with /api/flows/:slug/start.
  if (flow && flow.flow_type !== 'qa') {
    sendJson(res, 200, { type: 'flow', flow_slug: flow.slug });
    return;
  }

  const chat = await ensureChat(industry.id, body.chat_id, text);
  await addMessage(chat.id, 'user', text);
  const sse = openSse(req, res);
  sse.send('chat', chat);
  try {
    if (flow) await handleQa(industry, user, chat, flow, text, sse);
    else await handleChatMessage(industry, user, chat, text, sse);
  } catch (err) {
    console.error(err);
    sse.send('error', { message: 'Something went wrong while answering. Please try again.' });
  }
  sse.end();
}

// ---------------------------------------------------------------------------
// Router
// ---------------------------------------------------------------------------

const routes = [
  ['GET', /^\/api\/state$/, handleState],
  ['POST', /^\/api\/state\/industry$/, handleSetIndustry],
  ['POST', /^\/api\/state\/offline$/, handleSetOffline],
  ['POST', /^\/api\/reset$/, handleReset],
  ['GET', /^\/api\/chats\/(\d+)$/, (req, res, id) => handleGetChat(req, res, Number(id))],
  ['POST', /^\/api\/message$/, handleMessage],
  ['POST', /^\/api\/flows\/([\w-]+)\/start$/, handleFlowStart],
  ['POST', /^\/api\/flows\/([\w-]+)\/review$/, handleFlowReview],
  ['POST', /^\/api\/flows\/([\w-]+)\/draft$/, handleFlowDraft],
  ['POST', /^\/api\/flows\/([\w-]+)\/check$/, handleFlowCheck],
  ['POST', /^\/api\/flows\/([\w-]+)\/approve$/, handleFlowApprove],
  ['GET', /^\/api\/activity$/, handleActivity],
];

const server = http.createServer(async (req, res) => {
  const { pathname } = new URL(req.url, 'http://localhost');
  try {
    for (const [method, re, handler] of routes) {
      const m = pathname.match(re);
      if (m && req.method === method) {
        await handler(req, res, ...m.slice(1));
        return;
      }
    }
    throw new HttpError(404, 'Not found');
  } catch (err) {
    const status = err.status || 500;
    if (status === 500) console.error(err);
    if (!res.headersSent) sendJson(res, status, { error: status === 500 ? 'Internal server error' : err.message });
    else res.end();
  }
});

async function main() {
  try {
    const shifted = (await q1('SELECT refresh_demo_dates() AS shifted')).shifted;
    if (shifted) console.log(`Moved demo dates forward by ${shifted} day(s) so signals stay current.`);
    await loadState();
  } catch (err) {
    console.error(`\nCannot reach the database at ${DATABASE_URL.replace(/:[^:@/]+@/, ':****@')}`);
    console.error(`  ${err.message}`);
    console.error('  Start it with "docker compose up -d" and check DATABASE_URL in .env.\n');
    process.exit(1);
  }
  server.listen(PORT, () => {
    console.log(`Orchestrate API listening on http://localhost:${PORT} (open the Next.js app at http://localhost:${process.env.WEB_PORT || 3000})`);
    console.log(`  LLM: ${LLM.apiKey ? `live via ${LLM.name} (${LLM.model})` : `no ${LLM.keyVar}, serving offline responses`}`);
    console.log(`  Presenter keys: Shift+I industry, Shift+O offline toggle, Shift+R reset`);
  });
}

main();
